defmodule MyBudgetWeb.MovementLive.Index do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudgetWeb.Cldr

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Movimentações
        <:actions>
          <.button variant="primary" navigate={~p"/movement/new"}>
            <.icon name="hero-plus" /> Nova Movimentação
          </.button>
        </:actions>
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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    movement = Movements.get_movement!(socket.assigns.current_scope, id)
    {:ok, _} = Movements.delete_movement(socket.assigns.current_scope, movement)

    {:noreply, stream_delete(socket, :movement_collection, movement)}
  end

  @impl true
  def handle_info({type, %MyBudget.Movements.Movement{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :movement_collection, list_movement(socket.assigns.current_scope),
       reset: true
     )}
  end

  defp list_movement(current_scope) do
    current_scope
    |> Movements.list_movement()
    |> format_data()
  end

  defp format_data(movements) do
    Enum.map(movements, fn movement ->
      amount = movement.amount / 100

      expend_date =
        "#{movement.expend_date.day}/#{movement.expend_date.month}/#{movement.expend_date.year}"

      {:ok, formated_value} =
        Cldr.Number.to_string(amount, locale: "pt", currency: "BRL")

      Map.put(movement, :amount, formated_value)
      Map.put(movement, :expend_date, expend_date)
    end)
  end
end
