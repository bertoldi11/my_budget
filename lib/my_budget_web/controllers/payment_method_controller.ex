defmodule MyBudgetWeb.PaymentMethodController do
  use MyBudgetWeb, :controller

  action_fallback MyBudgetWeb.FallbackController

  alias MyBudget.Movements
  alias MyBudget.Movements.PaymentMethod
  alias MyBudgetWeb.Format

  def index(conn, _params) do
    payment_method_collection = Movements.list_payment_method(conn.assigns.current_scope)

    render(conn, :index,
      page_title: "Métodos de Pagamento",
      payment_method_collection: payment_method_collection
    )
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Movements.change_payment_method(scope, %PaymentMethod{user_id: scope.user.id})

    render(conn, :new, page_title: "Novo Método de Pagamento", form: to_form(changeset))
  end

  def create(conn, %{"payment_method" => payment_method_params}) do
    scope = conn.assigns.current_scope

    conn = assign(conn, :page_title, "Novo Método de Pagamento")

    with {:ok, _payment_method} <- Movements.create_payment_method(scope, payment_method_params) do
      conn
      |> put_flash(:info, "Método de pagamento cadastrado com sucesso!")
      |> redirect(to: ~p"/payment_method")
    else
      error -> {conn, error}
    end
  end

  def show(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)
    {month, year} = reference_month(params)
    period = PaymentMethod.period(payment_method, year, month)

    movements =
      Movements.list_movements_by_payment_method(
        scope,
        payment_method.id,
        period.start_date,
        period.end_date
      )

    render(conn, :show,
      page_title: payment_method.name,
      payment_method: payment_method,
      period: period,
      movements: movements,
      totals: totals(movements),
      current_period: reference(month, year),
      previous_period: shift_reference(month, year, -1),
      next_period: shift_reference(month, year, 1)
    )
  end

  def edit(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)

    render(conn, :edit,
      page_title: "Editar Método de Pagamento",
      payment_method: payment_method,
      return_to: return_to(params["return_to"]),
      form: to_form(Movements.change_payment_method(scope, payment_method))
    )
  end

  def update(conn, %{"id" => id, "payment_method" => payment_method_params} = params) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)
    return_to = return_to(params["return_to"])

    conn =
      conn
      |> assign(:page_title, "Editar Método de Pagamento")
      |> assign(:payment_method, payment_method)
      |> assign(:return_to, return_to)

    with {:ok, updated_payment_method} <-
           Movements.update_payment_method(scope, payment_method, payment_method_params) do
      conn
      |> put_flash(:info, "Método de pagamento atualizado com sucesso!")
      |> redirect(to: return_path(return_to, updated_payment_method))
    else
      error -> {conn, error}
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)

    with {:ok, _payment_method} <- Movements.delete_payment_method(scope, payment_method) do
      conn
      |> put_flash(:info, "Método de pagamento apagado com sucesso!")
      |> redirect(to: ~p"/payment_method")
    else
      error -> {conn, error}
    end
  end

  # O mês de referência vem da URL (`?m=11&y=2026`), como na home. Entradas
  # inválidas caem no mês atual em vez de derrubar a página.
  defp reference_month(%{"m" => month, "y" => year}) do
    with {month, ""} <- Integer.parse(month),
         {year, ""} <- Integer.parse(year),
         true <- month in 1..12 and year in 1900..2999 do
      {month, year}
    else
      _ -> current_reference_month()
    end
  end

  defp reference_month(_params), do: current_reference_month()

  defp current_reference_month do
    today = Date.utc_today()
    {today.month, today.year}
  end

  defp reference(month, year),
    do: %{month: month, year: year, month_name: Format.month_name(month)}

  defp shift_reference(month, year, months) do
    date = year |> Date.new!(month, 1) |> Date.shift(month: months)
    reference(date.month, date.year)
  end

  defp totals(movements) do
    credit = sum_by_type(movements, "credit")
    debit = sum_by_type(movements, "debit")

    %{credit: credit, debit: debit, balance: credit - debit, invoice: debit - credit}
  end

  defp sum_by_type(movements, type) do
    movements
    |> Enum.filter(&(&1.type == type))
    |> Enum.map(& &1.amount)
    |> Enum.sum()
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path("index", _payment_method), do: ~p"/payment_method"
  defp return_path("show", payment_method), do: ~p"/payment_method/#{payment_method}"
end
