defmodule MyBudgetWeb.SectionLive.Show do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Sessão {@section.id}
        <:actions>
          <.button navigate={~p"/section"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/section/#{@section}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Editar Sessão
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Nome">{@section.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_section(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Section")
     |> assign(:section, Movements.get_section!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MyBudget.Movements.Section{id: id} = section},
        %{assigns: %{section: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :section, section)}
  end

  def handle_info(
        {:deleted, %MyBudget.Movements.Section{id: id}},
        %{assigns: %{section: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current section was deleted.")
     |> push_navigate(to: ~p"/section")}
  end

  def handle_info({type, %MyBudget.Movements.Section{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
