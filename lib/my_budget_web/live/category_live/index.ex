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

      <%= for {_, section} <- @streams.category_collection do %>
        <h3 class="font-semibold">{section.section_name}</h3>
        <.table
          id="category"
          rows={section.categories}
          row_click={fn {_id, category} -> JS.navigate(~p"/category/#{category}") end}
        >
          <:col :let={{_id, category}} label="">{category.name}</:col>
          <:action :let={{_id, category}}>
            <div class="sr-only">
              <.link navigate={~p"/category/#{category}"}>Detalhes</.link>
            </div>
            <.link navigate={~p"/category/#{category}/edit"}>Editar</.link>
          </:action>
          <:action :let={{id, category}}>
            <.link
              phx-click={JS.push("delete", value: %{id: category.id}) |> hide("##{id}")}
              data-confirm="Tem certeza que deseja apagar essa categoria?"
            >
              Apagar
            </.link>
          </:action>
        </.table>
      <% end %>
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
    current_scope
    |> Movements.list_category()
    |> sections_with_metadata()
  end

  defp group_by_section(categories) do
    Enum.group_by(categories, fn category ->
      category.section.name
    end)
  end

  defp sections_with_metadata(categories) when is_list(categories) do
    categories
    |> group_by_section()
    |> Enum.map(fn {section_name, categories} ->
      %{
        section_name: section_name,
        id: section_name,
        count: length(categories),
        categories: add_dom_id(categories)
      }
    end)
    |> Enum.sort_by(& &1.section_name)
  end

  defp add_dom_id(categories) do
    Enum.map(categories, fn category ->
      category_id = "cat_#{category.id}"
      {category_id, category}
    end)
  end
end
