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
      <%= for {_, section} <- @streams.movement_collection do %>
        <div class="flex justify-between font-semibold">
          <h3>{section.section_name}</h3>
          <p>{section.total_amount}</p>
        </div>
        <%= for {_, category} <- section.categories do %>
        <div class="flex justify-between ml-8">
            <p>{category.category}</p>
            <p>{category.formatted_amount}</p>
          </div>
        <% end %>
      <% end %>
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
    |> format_data()
    |> sections_with_metadata()
  end

  defp format_data(movements) do
    Enum.map(movements, fn movement ->
      amount = movement.amount / 100

      {:ok, formated_value} =
        Cldr.Number.to_string(amount, locale: "pt", currency: "BRL")

      Map.put(movement, :formatted_amount, formated_value)
    end)
  end

  @doc """
  Agrupa uma lista de movimentos pelo nome da seção (`category.section.name`).
  Retorna um mapa onde a chave é o `section_name` (String) e o valor é a lista
  de movimentos daquela seção.
  Movimentos sem seção definida vão para a chave `"Sem seção"`.
  """
  @spec group_by_section([map()]) :: %{optional(String.t()) => [map()]}
  def group_by_section(data) when is_list(data) do
    Enum.group_by(data, fn entry ->
      entry.session || "Sem seção"
    end)
  end

  @doc """
  Retorna uma lista de seções com metadados:

  [
    %{
      section_name: "Moradia",
      count: 3,
      total_amount: "R$ 1.000,00",
      movements: [...]
    },
    ...
  ]

  A lista é ordenada por `section_name`.
  """
  @spec sections_with_metadata([map()]) :: [
          %{section_name: String.t(), count: non_neg_integer(), movements: [map()]}
        ]
  def sections_with_metadata(movements) when is_list(movements) do
    movements
    |> group_by_section()
    |> Enum.map(fn {section_name, movs} ->
      total_amount =
        Enum.reduce(movs, 0, fn mov, acc ->
          acc + mov.amount 
        end)

      {:ok, formatted_total_amount} =
        Cldr.Number.to_string(total_amount / 100, locale: "pt", currency: "BRL")

      %{
        section_name: section_name,
        id: section_name,
        count: length(movs),
        total_amount: formatted_total_amount,
        categories: add_dom_id(movs)
      }
    end)
    |> Enum.sort_by(& &1.section_name)
  end

  defp add_dom_id(categories) do
    Enum.map(categories, fn category ->
      category_id = "category_#{category.category}"
      {category_id, category}
    end)
  end
end
