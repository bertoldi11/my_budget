defmodule MyBudget.Budget do
  import Ecto.Query

  alias MyBudget.Accounts.Scope
  alias MyBudget.Budget.{BudgetAllocation, BudgetIncome, MonthlyBudget}
  alias MyBudget.Movements.{Category, Section}
  alias MyBudget.Repo

  # ---------------------------------------------------------------------------
  # Monthly Budgets
  # ---------------------------------------------------------------------------

  def list_monthly_budgets(%Scope{} = scope) do
    MonthlyBudget
    |> where(user_id: ^scope.user.id)
    |> order_by(desc: :reference_date)
    |> Repo.all()
  end

  def get_or_create_monthly_budget(%Scope{} = scope, year, month) do
    reference_date = Date.new!(year, month, 1)

    case Repo.get_by(MonthlyBudget, user_id: scope.user.id, reference_date: reference_date) do
      nil -> create_monthly_budget(scope, reference_date)
      budget -> {:ok, budget}
    end
  end

  defp create_monthly_budget(%Scope{} = scope, reference_date) do
    %MonthlyBudget{}
    |> MonthlyBudget.changeset(%{reference_date: reference_date}, scope)
    |> Repo.insert()
  end

  def update_budget_status(%Scope{} = scope, %MonthlyBudget{} = budget) do
    total_in = total_income(scope, budget)
    total_alloc = total_allocated(scope, budget)

    status = if total_in > 0 and total_in == total_alloc, do: "balanced", else: "draft"

    budget
    |> MonthlyBudget.changeset(%{status: status}, scope)
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Incomes
  # ---------------------------------------------------------------------------

  def list_incomes(%Scope{} = scope, %MonthlyBudget{} = budget) do
    BudgetIncome
    |> where(user_id: ^scope.user.id, monthly_budget_id: ^budget.id)
    |> order_by(:inserted_at)
    |> Repo.all()
  end

  def create_income(%Scope{} = scope, %MonthlyBudget{} = budget, attrs) do
    %BudgetIncome{monthly_budget_id: budget.id}
    |> BudgetIncome.changeset(attrs, scope)
    |> Repo.insert()
    |> tap_update_status(scope, budget)
  end

  def update_income(%Scope{} = scope, %BudgetIncome{} = income, attrs) do
    budget = Repo.get!(MonthlyBudget, income.monthly_budget_id)

    income
    |> BudgetIncome.changeset(attrs, scope)
    |> Repo.update()
    |> tap_update_status(scope, budget)
  end

  def delete_income(%Scope{} = scope, %BudgetIncome{} = income) do
    budget = Repo.get!(MonthlyBudget, income.monthly_budget_id)

    Repo.delete(income)
    |> tap_update_status(scope, budget)
  end

  def total_income(%Scope{} = scope, %MonthlyBudget{} = budget) do
    BudgetIncome
    |> where(user_id: ^scope.user.id, monthly_budget_id: ^budget.id)
    |> select([i], coalesce(sum(i.amount), 0))
    |> Repo.one()
  end

  def change_income(%BudgetIncome{} = income, attrs \\ %{}) do
    BudgetIncome.changeset(income, attrs, %Scope{user: %{id: income.user_id}})
  end

  # ---------------------------------------------------------------------------
  # Allocations
  # ---------------------------------------------------------------------------

  def list_allocations(%Scope{} = scope, %MonthlyBudget{} = budget) do
    BudgetAllocation
    |> where(user_id: ^scope.user.id, monthly_budget_id: ^budget.id)
    |> preload(category: :section)
    |> Repo.all()
  end

  def upsert_allocation(%Scope{} = scope, %MonthlyBudget{} = budget, category_id, planned_amount) do
    case Repo.get_by(BudgetAllocation,
           monthly_budget_id: budget.id,
           category_id: category_id,
           user_id: scope.user.id
         ) do
      nil ->
        %BudgetAllocation{monthly_budget_id: budget.id, category_id: category_id}
        |> BudgetAllocation.changeset(%{planned_amount: planned_amount}, scope)
        |> Repo.insert()

      allocation ->
        allocation
        |> BudgetAllocation.changeset(%{planned_amount: planned_amount}, scope)
        |> Repo.update()
    end
    |> tap_update_status(scope, budget)
  end

  @doc """
  Deletes the allocations of the category in every budget of the scope and
  recalculates the status of the affected budgets.
  """
  def delete_category_allocations(%Scope{} = scope, %Category{} = category) do
    query = where(BudgetAllocation, user_id: ^scope.user.id, category_id: ^category.id)

    budget_ids = query |> select([a], a.monthly_budget_id) |> Repo.all()
    {count, _} = Repo.delete_all(query)

    MonthlyBudget
    |> where([b], b.id in ^budget_ids)
    |> Repo.all()
    |> Enum.each(&update_budget_status(scope, &1))

    count
  end

  def total_allocated(%Scope{} = scope, %MonthlyBudget{} = budget) do
    BudgetAllocation
    |> where(user_id: ^scope.user.id, monthly_budget_id: ^budget.id)
    |> select([a], coalesce(sum(a.planned_amount + a.rollover_amount), 0))
    |> Repo.one()
  end

  def remaining(%Scope{} = scope, %MonthlyBudget{} = budget) do
    total_income(scope, budget) - total_allocated(scope, budget)
  end

  # ---------------------------------------------------------------------------
  # Sections and categories (budget_active toggle)
  # Modifies Movements schemas; queries delegated here for convenience.
  # ---------------------------------------------------------------------------

  @doc """
  Sections and categories that can be used in a budget: marked as active in
  the budget (`budget_active`) and not deactivated (`active`).
  """
  def list_budget_active_sections(%Scope{} = scope) do
    Section
    |> where(user_id: ^scope.user.id, budget_active: true, active: true)
    |> order_by(:name)
    |> preload(categories: ^from(c in Category, order_by: c.name))
    |> Repo.all()
    |> Enum.map(fn section ->
      %{section | categories: Enum.filter(section.categories, &budget_eligible?(section, &1))}
    end)
  end

  @doc """
  Sections and categories shown in the given budget: the ones that can be used
  in a budget plus any category that already has an allocation in it, even if
  it was deactivated afterwards (so old budgets keep their history).
  """
  def list_budget_sections(%Scope{} = scope, %MonthlyBudget{} = budget) do
    allocated_ids =
      BudgetAllocation
      |> where(user_id: ^scope.user.id, monthly_budget_id: ^budget.id)
      |> select([a], a.category_id)
      |> Repo.all()
      |> MapSet.new()

    Section
    |> where(user_id: ^scope.user.id)
    |> order_by(:name)
    |> preload(categories: ^from(c in Category, order_by: c.name))
    |> Repo.all()
    |> Enum.map(fn section ->
      categories =
        Enum.filter(section.categories, fn category ->
          budget_eligible?(section, category) or MapSet.member?(allocated_ids, category.id)
        end)

      %{section | categories: categories}
    end)
    |> Enum.reject(&(&1.categories == []))
  end

  @doc """
  Whether the category (in the given section) is deactivated, either directly
  or because its section was deactivated.
  """
  def deactivated?(%Section{} = section, %Category{} = category),
    do: not (section.active and category.active)

  defp budget_eligible?(section, category) do
    section.budget_active and category.budget_active and not deactivated?(section, category)
  end

  # Ids das categorias ativas (categoria e seção ativas) entre as informadas.
  defp active_category_ids(%Scope{} = scope, category_ids) do
    Category
    |> join(:inner, [c], s in assoc(c, :section))
    |> where([c, s], c.user_id == ^scope.user.id and c.id in ^category_ids)
    |> where([c, s], c.active and s.active)
    |> select([c], c.id)
    |> Repo.all()
    |> MapSet.new()
  end

  def toggle_section_budget_active(%Scope{} = scope, %Section{} = section) do
    new_value = !section.budget_active

    Repo.transaction(fn ->
      section
      |> Ecto.Changeset.change(budget_active: new_value)
      |> Repo.update!()

      Category
      |> where(user_id: ^scope.user.id, section_id: ^section.id)
      |> Repo.update_all(set: [budget_active: new_value])
    end)
  end

  def toggle_category_budget_active(%Scope{} = _scope, %Category{} = category) do
    category
    |> Ecto.Changeset.change(budget_active: !category.budget_active)
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Actual spending (from movements)
  # ---------------------------------------------------------------------------

  def actual_spent_by_category(%Scope{} = scope, %MonthlyBudget{} = budget) do
    start_date = budget.reference_date
    end_date = Date.end_of_month(start_date)

    MyBudget.Movements.Movement
    |> where(user_id: ^scope.user.id)
    |> where([m], m.expend_date >= ^start_date and m.expend_date <= ^end_date)
    |> where([m], m.type == "debit")
    |> group_by([m], m.category_id)
    |> select([m], {m.category_id, sum(m.amount)})
    |> Repo.all()
    |> Map.new()
  end

  # ---------------------------------------------------------------------------
  # Copy from previous month
  # ---------------------------------------------------------------------------

  def copy_budget_from_previous_month(%Scope{} = scope, %MonthlyBudget{} = budget) do
    prev_date = budget.reference_date |> Date.add(-1) |> Date.beginning_of_month()

    case Repo.get_by(MonthlyBudget, user_id: scope.user.id, reference_date: prev_date) do
      nil ->
        {:error, :no_previous_budget}

      prev_budget ->
        Repo.transaction(fn ->
          copy_incomes(scope, prev_budget, budget)
          copy_allocations(scope, prev_budget, budget)
        end)
        |> tap_update_status(scope, budget)
    end
  end

  defp copy_incomes(scope, prev_budget, budget) do
    existing_descriptions =
      BudgetIncome
      |> where(monthly_budget_id: ^budget.id)
      |> select([i], i.description)
      |> Repo.all()
      |> MapSet.new()

    list_incomes(scope, prev_budget)
    |> Enum.reject(&MapSet.member?(existing_descriptions, &1.description))
    |> Enum.each(fn income ->
      %BudgetIncome{monthly_budget_id: budget.id}
      |> BudgetIncome.changeset(%{description: income.description, amount: income.amount}, scope)
      |> Repo.insert!()
    end)
  end

  defp copy_allocations(scope, prev_budget, budget) do
    existing_category_ids =
      BudgetAllocation
      |> where(monthly_budget_id: ^budget.id)
      |> select([a], a.category_id)
      |> Repo.all()
      |> MapSet.new()

    # Categorias (ou seções) desativadas não entram no novo orçamento, mesmo
    # que façam parte do orçamento anterior.
    previous =
      BudgetAllocation
      |> where(monthly_budget_id: ^prev_budget.id, user_id: ^scope.user.id)
      |> Repo.all()

    active_ids = active_category_ids(scope, Enum.map(previous, & &1.category_id))

    previous
    |> Enum.filter(&MapSet.member?(active_ids, &1.category_id))
    |> Enum.reject(&MapSet.member?(existing_category_ids, &1.category_id))
    |> Enum.each(fn alloc ->
      %BudgetAllocation{monthly_budget_id: budget.id, category_id: alloc.category_id}
      |> BudgetAllocation.changeset(%{planned_amount: alloc.planned_amount}, scope)
      |> Repo.insert!()
    end)
  end

  # ---------------------------------------------------------------------------
  # Rollover
  # ---------------------------------------------------------------------------

  def calculate_pending_rollovers(%Scope{} = scope, %MonthlyBudget{} = budget) do
    prev_date = budget.reference_date |> Date.add(-1) |> Date.beginning_of_month()

    case Repo.get_by(MonthlyBudget, user_id: scope.user.id, reference_date: prev_date) do
      nil ->
        []

      prev_budget ->
        spent_map = actual_spent_by_category(scope, prev_budget)
        allocations = list_allocations(scope, prev_budget)

        for alloc <- allocations,
            surplus =
              alloc.planned_amount + alloc.rollover_amount -
                Map.get(spent_map, alloc.category_id, 0),
            surplus > 0 do
          %{
            category_id: alloc.category_id,
            category: alloc.category,
            surplus: surplus,
            deactivated: deactivated?(alloc.category.section, alloc.category)
          }
        end
    end
  end

  def apply_rollovers(%Scope{} = scope, %MonthlyBudget{} = budget, redirects) do
    # redirects: list of %{category_id: target_id, surplus: amount}
    # Saldos cujo destino é uma categoria desativada são descartados: ela não
    # pode entrar no novo orçamento.
    active_ids = active_category_ids(scope, Enum.map(redirects, & &1.category_id))

    Repo.transaction(fn ->
      redirects
      |> Enum.filter(&MapSet.member?(active_ids, &1.category_id))
      |> Enum.group_by(& &1.category_id, & &1.surplus)
      |> Enum.each(fn {category_id, surpluses} ->
        total_rollover = Enum.sum(surpluses)

        case Repo.get_by(BudgetAllocation,
               monthly_budget_id: budget.id,
               category_id: category_id,
               user_id: scope.user.id
             ) do
          nil ->
            %BudgetAllocation{monthly_budget_id: budget.id, category_id: category_id}
            |> BudgetAllocation.changeset(
              %{planned_amount: 0, rollover_amount: total_rollover},
              scope
            )
            |> Repo.insert!()

          allocation ->
            allocation
            |> Ecto.Changeset.change(rollover_amount: allocation.rollover_amount + total_rollover)
            |> Repo.update!()
        end
      end)
    end)
    |> tap_update_status(scope, budget)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp tap_update_status({:ok, result}, scope, budget) do
    update_budget_status(scope, budget)
    {:ok, result}
  end

  defp tap_update_status({:error, _} = error, _scope, _budget), do: error
end
