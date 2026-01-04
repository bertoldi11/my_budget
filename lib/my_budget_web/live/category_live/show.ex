defmodule MyBudgetWeb.CategoryLive.Show do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Categoria {@category.id}
        <:actions>
          <.button navigate={~p"/category"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/category/#{@category}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Editar
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@category.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_category(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Categoria")
     |> assign(:category, Movements.get_category!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MyBudget.Movements.Category{id: id} = category},
        %{assigns: %{category: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :category, category)}
  end

  def handle_info(
        {:deleted, %MyBudget.Movements.Category{id: id}},
        %{assigns: %{category: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current category was deleted.")
     |> push_navigate(to: ~p"/category")}
  end

  def handle_info({type, %MyBudget.Movements.Category{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
