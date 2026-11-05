defmodule MyBudgetWeb.BudgetLive.Show do
  use MyBudgetWeb, :live_view

  alias MyBudget.Accounts.Scope
  alias MyBudget.Budget
  alias MyBudget.Budget.BudgetIncome
  alias MyBudget.Movements
  alias MyBudget.Repo

  @impl true
  def mount(%{"year" => year, "month" => month}, _session, socket) do
    scope = socket.assigns.current_scope

    year = String.to_integer(year)
    month = String.to_integer(month)

    if not Scope.budget_enabled?(scope) do
      {:ok, push_navigate(socket, to: ~p"/")}
    else
      with {:ok, budget} <- Budget.get_or_create_monthly_budget(scope, year, month) do
        pending_rollovers = Budget.calculate_pending_rollovers(scope, budget)

        if connected?(socket), do: Movements.subscribe_movement(scope)

        socket =
          socket
          |> assign_budget_data(scope, budget)
          |> assign(:pending_rollovers, pending_rollovers)
          |> assign(:rollover_redirects, %{})
          |> assign(:income_form, build_income_form())
          |> assign(:editing_income_id, nil)
          |> assign(:show_rollover_dialog, pending_rollovers != [])

        {:ok, socket}
      end
    end
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_info({event, _movement}, socket) when event in [:created, :updated, :deleted] do
    {:noreply, reload_budget_data(socket)}
  end

  # ---------------------------------------------------------------------------
  # Rollover dialog
  # ---------------------------------------------------------------------------

  @impl true
  def handle_event(
        "rollover_redirect",
        %{"from_category" => from_id, "to_category" => to_id},
        socket
      ) do
    redirects = Map.put(socket.assigns.rollover_redirects, from_id, to_id)
    {:noreply, assign(socket, :rollover_redirects, redirects)}
  end

  def handle_event("apply_rollovers", _params, socket) do
    scope = socket.assigns.current_scope
    budget = socket.assigns.budget

    resolved =
      Enum.map(socket.assigns.pending_rollovers, fn r ->
        target_id =
          Map.get(
            socket.assigns.rollover_redirects,
            to_string(r.category_id),
            to_string(r.category_id)
          )
          |> String.to_integer()

        %{category_id: target_id, surplus: r.surplus}
      end)

    case Budget.apply_rollovers(scope, budget, resolved) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:show_rollover_dialog, false)
         |> assign(:pending_rollovers, [])
         |> reload_budget_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao aplicar rollover.")}
    end
  end

  def handle_event("dismiss_rollover", _params, socket) do
    {:noreply, assign(socket, :show_rollover_dialog, false)}
  end

  # ---------------------------------------------------------------------------
  # Income events
  # ---------------------------------------------------------------------------

  def handle_event("new_income", _params, socket) do
    {:noreply,
     socket
     |> assign(:income_form, build_income_form())
     |> assign(:editing_income_id, :new)}
  end

  def handle_event("cancel_income", _params, socket) do
    {:noreply, assign(socket, :editing_income_id, nil)}
  end

  def handle_event("edit_income", %{"id" => id}, socket) do
    income = Enum.find(socket.assigns.incomes, &(to_string(&1.id) == id))
    form = build_income_form(income)
    {:noreply, socket |> assign(:income_form, form) |> assign(:editing_income_id, income.id)}
  end

  def handle_event("save_income", %{"budget_income" => params}, socket) do
    scope = socket.assigns.current_scope
    budget = socket.assigns.budget

    result =
      case socket.assigns.editing_income_id do
        :new ->
          Budget.create_income(scope, budget, params)

        id ->
          income = Enum.find(socket.assigns.incomes, &(&1.id == id))
          Budget.update_income(scope, income, params)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:editing_income_id, nil)
         |> reload_budget_data()}

      {:error, changeset} ->
        {:noreply, assign(socket, :income_form, to_form(changeset, as: :budget_income))}
    end
  end

  def handle_event("delete_income", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    income = Enum.find(socket.assigns.incomes, &(to_string(&1.id) == id))

    case Budget.delete_income(scope, income) do
      {:ok, _} -> {:noreply, reload_budget_data(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Erro ao remover receita.")}
    end
  end

  def handle_event("validate_income", %{"budget_income" => params}, socket) do
    changeset =
      %BudgetIncome{}
      |> Budget.change_income(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :income_form, to_form(changeset, as: :budget_income))}
  end

  # ---------------------------------------------------------------------------
  # Allocation autosave
  # ---------------------------------------------------------------------------

  def handle_event("save_allocation", %{"category_id" => cat_id, "value" => amount}, socket) do
    scope = socket.assigns.current_scope
    budget = socket.assigns.budget
    category_id = String.to_integer(cat_id)

    case Budget.upsert_allocation(scope, budget, category_id, parse_reais(amount)) do
      {:ok, _} -> {:noreply, reload_budget_data(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Erro ao salvar alocação.")}
    end
  end

  # ---------------------------------------------------------------------------
  # Copy from previous month
  # ---------------------------------------------------------------------------

  def handle_event("copy_previous_month", _params, socket) do
    scope = socket.assigns.current_scope
    budget = socket.assigns.budget

    case Budget.copy_budget_from_previous_month(scope, budget) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Orçamento do mês anterior copiado.")
         |> reload_budget_data()}

      {:error, :no_previous_budget} ->
        {:noreply, put_flash(socket, :error, "Nenhum orçamento encontrado no mês anterior.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao copiar orçamento.")}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp assign_budget_data(socket, scope, budget) do
    incomes = Budget.list_incomes(scope, budget)
    sections = Budget.list_budget_active_sections(scope)
    allocations = Budget.list_allocations(scope, budget)
    spent_map = Budget.actual_spent_by_category(scope, budget)
    total_in = Budget.total_income(scope, budget)
    total_alloc = Budget.total_allocated(scope, budget)

    allocation_map = Map.new(allocations, &{&1.category_id, &1})

    socket
    |> assign(:budget, budget)
    |> assign(:incomes, incomes)
    |> assign(:sections, sections)
    |> assign(:allocation_map, allocation_map)
    |> assign(:spent_map, spent_map)
    |> assign(:total_income, total_in)
    |> assign(:total_allocated, total_alloc)
    |> assign(:remaining, total_in - total_alloc)
    |> assign(:page_title, format_month(budget.reference_date))
  end

  defp reload_budget_data(socket) do
    scope = socket.assigns.current_scope
    budget = Repo.reload!(socket.assigns.budget)
    assign_budget_data(socket, scope, budget)
  end

  defp build_income_form(income \\ %BudgetIncome{}) do
    income
    |> Budget.change_income()
    |> to_form(as: :budget_income)
  end

  defp parse_reais(value) when is_binary(value) do
    cleaned = String.replace(value, ~r/[^\d,.-]/u, "")

    normalized =
      if String.contains?(cleaned, ","),
        do: cleaned |> String.replace(".", "") |> String.replace(",", "."),
        else: cleaned

    case Decimal.parse(normalized) do
      {decimal, ""} ->
        decimal |> Decimal.mult(100) |> Decimal.round(0) |> Decimal.to_integer()

      _ ->
        0
    end
  end

  defp parse_reais(_), do: 0

  defp format_reais(nil), do: "0,00"

  defp format_reais(cents) do
    cents
    |> Decimal.new()
    |> Decimal.div(100)
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
    |> String.replace(".", ",")
  end

  defp format_month(date) do
    months =
      ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)

    "#{Enum.at(months, date.month - 1)} #{date.year}"
  end

  defp remaining_class(remaining) when remaining == 0, do: "text-success font-semibold"
  defp remaining_class(remaining) when remaining > 0, do: "text-warning font-semibold"
  defp remaining_class(_), do: "text-error font-semibold"

  defp diff_class(diff) when diff >= 0, do: "text-success"
  defp diff_class(_), do: "text-error"
end
