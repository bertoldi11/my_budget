defmodule MyBudgetWeb.MovementLive.Show do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Movement {@movement.id}
        <:subtitle>This is a movement record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/movement"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/movement/#{@movement}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit movement
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Amount">{@movement.amount}</:item>
        <:item title="Description">{@movement.description}</:item>
        <:item title="Counter party">{@movement.counter_party}</:item>
        <:item title="Type">{@movement.type}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_movement(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Movement")
     |> assign(:movement, Movements.get_movement!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MyBudget.Movements.Movement{id: id} = movement},
        %{assigns: %{movement: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :movement, movement)}
  end

  def handle_info(
        {:deleted, %MyBudget.Movements.Movement{id: id}},
        %{assigns: %{movement: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current movement was deleted.")
     |> push_navigate(to: ~p"/movement")}
  end

  def handle_info({type, %MyBudget.Movements.Movement{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
