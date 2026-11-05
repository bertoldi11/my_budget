defmodule MyBudgetWeb.BudgetLive.Index do
  use MyBudgetWeb, :live_view

  alias MyBudget.Accounts.Scope
  alias MyBudget.Budget

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    if not Scope.budget_enabled?(scope) do
      {:ok, push_navigate(socket, to: ~p"/")}
    else
      budgets = Budget.list_monthly_budgets(scope)

      {:ok,
       socket
       |> assign(:page_title, "Orçamentos")
       |> assign(:budgets, budgets)
       |> assign(:new_year, Date.utc_today().year)
       |> assign(:new_month, Date.utc_today().month)
       |> assign(:show_new_form, false)}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_new_form", _params, socket) do
    {:noreply, assign(socket, :show_new_form, !socket.assigns.show_new_form)}
  end

  def handle_event("new_month_change", %{"year" => year, "month" => month}, socket) do
    {:noreply,
     socket
     |> assign(:new_year, String.to_integer(year))
     |> assign(:new_month, String.to_integer(month))}
  end

  def handle_event("create_budget", _params, socket) do
    scope = socket.assigns.current_scope
    year = socket.assigns.new_year
    month = socket.assigns.new_month

    case Budget.get_or_create_monthly_budget(scope, year, month) do
      {:ok, _budget} ->
        {:noreply, push_navigate(socket, to: ~p"/budget/#{year}/#{month}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao criar orçamento.")}
    end
  end

  defp status_label("balanced"), do: "Equilibrado"
  defp status_label(_), do: "Rascunho"

  defp status_class("balanced"), do: "badge badge-success badge-sm"
  defp status_class(_), do: "badge badge-ghost badge-sm"

  defp format_month(date) do
    months =
      ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)

    "#{Enum.at(months, date.month - 1)} #{date.year}"
  end
end
