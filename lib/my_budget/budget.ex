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

  def get_monthly_budget!(scope, id) do
    MonthlyBudget
    |> where(user_id: ^scope.user.id, id: ^id)
    |> Repo.one!()
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

  def list_budget_active_sections(%Scope{} = scope) do
    Section
    |> where(user_id: ^scope.user.id, budget_active: true)
    |> preload(:categories)
    |> Repo.all()
    |> Enum.map(fn section ->
      active_cats = Enum.filter(section.categories, & &1.budget_active)
      %{section | categories: active_cats}
    end)
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

    BudgetAllocation
    |> where(monthly_budget_id: ^prev_budget.id, user_id: ^scope.user.id)
    |> Repo.all()
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
            surplus: surplus
          }
        end
    end
  end

  def apply_rollovers(%Scope{} = scope, %MonthlyBudget{} = budget, redirects) do
    # redirects: list of %{category_id: target_id, surplus: amount}
    Repo.transaction(fn ->
      Enum.group_by(redirects, & &1.category_id, & &1.surplus)
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
