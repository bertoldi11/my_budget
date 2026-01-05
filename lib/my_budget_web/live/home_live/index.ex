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
        <table class="table table-zebra border-spacing-1">
          <thead>
            <tr>
              <th>Categoria</th>
              <th>Data</th>
              <th>Pago Com</th>
              <th>Valor</th>
              <th>Descrição</th>
              <th>Pago/Recebido de</th>
              <th>Tipo</th>
            </tr>
          </thead>

          <tbody>
            <tr :for={movement <- section.movements}>
              <td>{movement.category.name}</td>
              <td>{movement.formatted_expend_date}</td>
              <td>{movement.payment_method.name}</td>
              <td>{movement.formatted_amount}</td>
              <td>{movement.description}</td>
              <td>{movement.counter_party}</td>
              <td>{movement.type}</td>
            </tr>
          </tbody>
        </table>
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

      expend_date =
        "#{movement.expend_date.day}/#{movement.expend_date.month}/#{movement.expend_date.year}"

      {:ok, formated_value} =
        Cldr.Number.to_string(amount, locale: "pt", currency: "BRL")

      movement
      |> Map.put(:formatted_amount, formated_value)
      |> Map.put(:formatted_expend_date, expend_date)
    end)
  end

  @doc """
  Agrupa uma lista de movimentos pelo nome da seção (`category.section.name`).
  Retorna um mapa onde a chave é o `section_name` (String) e o valor é a lista
  de movimentos daquela seção.
  Movimentos sem seção definida vão para a chave `"Sem seção"`.
  """
  @spec group_by_section([map()]) :: %{optional(String.t()) => [map()]}
  def group_by_section(movements) when is_list(movements) do
    Enum.group_by(movements, fn movement ->
      movement.category.section.name || "Sem seção"
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
        movements: movs
      }
    end)
    |> Enum.sort_by(& &1.section_name)
  end
end
