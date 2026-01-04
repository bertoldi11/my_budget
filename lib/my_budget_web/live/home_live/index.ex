defmodule MyBudgetWeb.HomeLive.Index do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudgetWeb.Cldr

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Budget, you gonna need one!
      </.header>

      <.table
        id="movement"
        rows={@streams.movement_collection}
        row_click={fn {_id, movement} -> JS.navigate(~p"/movement/#{movement}") end}
      >
        <:col :let={{_id, movement}} label="Categoria">{movement.category.name}</:col>
        <:col :let={{_id, movement}} label="Data">{movement.expend_date}</:col>
        <:col :let={{_id, movement}} label="Pago com">{movement.payment_method.name}</:col>
        <:col :let={{_id, movement}} label="Valor">{movement.amount}</:col>
        <:col :let={{_id, movement}} label="Descrição">{movement.description}</:col>
        <:col :let={{_id, movement}} label="Pago/Recebido de">{movement.counter_party}</:col>
        <:col :let={{_id, movement}} label="Tipo">{movement.type}</:col>
        <:action :let={{_id, movement}}>
          <div class="sr-only">
            <.link navigate={~p"/movement/#{movement}"}>Detalhes</.link>
          </div>
          <.link navigate={~p"/movement/#{movement}/edit"}>Editar</.link>
        </:action>
        <:action :let={{id, movement}}>
          <.link
            phx-click={JS.push("delete", value: %{id: movement.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_movement(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Movimentações")
     |> stream(:movement_collection, list_movement(socket.assigns.current_scope))}
  end

  defp list_movement(current_scope) do
    current_scope
    |> Movements.list_current_month()
    |> format_amount()
  end

  defp format_amount(movements) do
    Enum.map(movements, fn movement ->
      amount = movement.amount / 100

      {:ok, formated_value} =
        Cldr.Number.to_string(amount, locale: "pt", currency: "BRL")

      Map.put(movement, :amount, formated_value)
    end)
  end
end
