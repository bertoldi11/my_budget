defmodule MyBudgetWeb.MovementOptions do
  @moduledoc """
  Options for the selects of the movement form, shared by the movement
  controller and the home LiveView.
  """

  alias MyBudget.Movements

  @doc """
  Category options (`{"Seção / Categoria", id}`) with only the available
  categories (active category in an active section).

  When editing a movement whose category was deactivated afterwards, pass its
  `current_category_id` so the select can still show it, marked as
  "(desativada)".
  """
  def category_options(scope, current_category_id \\ nil) do
    available = Movements.list_available_category(scope)
    options = Enum.map(available, &{"#{&1.section.name} / #{&1.name}", &1.id})

    if is_nil(current_category_id) or Enum.any?(available, &(&1.id == current_category_id)) do
      options
    else
      category =
        scope
        |> Movements.get_category!(current_category_id)
        |> MyBudget.Repo.preload(:section)

      options ++ [{"#{category.section.name} / #{category.name} (desativada)", category.id}]
    end
  end

  def payment_method_options(scope) do
    scope
    |> Movements.list_payment_method()
    |> Enum.map(&{&1.name, &1.id})
  end

  def type_options, do: [{"Saída", "debit"}, {"Entrada", "credit"}]
end
