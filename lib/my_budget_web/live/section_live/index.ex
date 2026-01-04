defmodule MyBudgetWeb.SectionLive.Index do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Sessões
        <:actions>
          <.button variant="primary" navigate={~p"/section/new"}>
            <.icon name="hero-plus" /> Nova
          </.button>
        </:actions>
      </.header>

      <.table
        id="section"
        rows={@streams.section_collection}
        row_click={fn {_id, section} -> JS.navigate(~p"/section/#{section}") end}
      >
        <:col :let={{_id, section}} label="ID">{section.id}</:col>
        <:col :let={{_id, section}} label="Nome">{section.name}</:col>
        <:action :let={{_id, section}}>
          <div class="sr-only">
            <.link navigate={~p"/section/#{section}"}>Show</.link>
          </div>
          <.link navigate={~p"/section/#{section}/edit"}>Editar</.link>
        </:action>
        <:action :let={{id, section}}>
          <.link
            phx-click={JS.push("delete", value: %{id: section.id}) |> hide("##{id}")}
            data-confirm="Tem certeza que deseja excluir essa sessão?"
          >
            Apagar
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_section(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing section")
     |> stream(:section_collection, list_section(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    section = Movements.get_section!(socket.assigns.current_scope, id)
    {:ok, _} = Movements.delete_section(socket.assigns.current_scope, section)

    {:noreply, stream_delete(socket, :section_collection, section)}
  end

  @impl true
  def handle_info({type, %MyBudget.Movements.Section{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :section_collection, list_section(socket.assigns.current_scope), reset: true)}
  end

  defp list_section(current_scope) do
    Movements.list_section(current_scope)
  end
end
