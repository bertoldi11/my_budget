defmodule MyBudgetWeb.CategoryLive.Index do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Categorias
        <:actions>
          <.button variant="primary" navigate={~p"/category/new"}>
            <.icon name="hero-plus" /> Nova
          </.button>
        </:actions>
      </.header>

      <.table
        id="category"
        rows={@streams.category_collection}
        row_click={fn {_id, category} -> JS.navigate(~p"/category/#{category}") end}
      >
        <:col :let={{_id, category}} label="Nome">{category.name}</:col>
        <:col :let={{_id, category}} label="Sessão">{category.section.name}</:col>
        <:action :let={{_id, category}}>
          <div class="sr-only">
            <.link navigate={~p"/category/#{category}"}>Detalhes</.link>
          </div>
          <.link navigate={~p"/category/#{category}/edit"}>Editar</.link>
        </:action>
        <:action :let={{id, category}}>
          <.link
            phx-click={JS.push("delete", value: %{id: category.id}) |> hide("##{id}")}
            data-confirm="Tem certeza que deseja apagar essa sub categoria?"
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
      Movements.subscribe_category(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Categorias")
     |> stream(:category_collection, list_category(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Movements.get_category!(socket.assigns.current_scope, id)
    {:ok, _} = Movements.delete_category(socket.assigns.current_scope, category)

    {:noreply, stream_delete(socket, :category_collection, category)}
  end

  @impl true
  def handle_info({type, %MyBudget.Movements.Category{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :category_collection, list_category(socket.assigns.current_scope),
       reset: true
     )}
  end

  defp list_category(current_scope) do
    Movements.list_category(current_scope)
  end
end
