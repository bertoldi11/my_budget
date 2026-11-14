defmodule MyBudgetWeb.MovementHTML do
  use MyBudgetWeb, :html

  alias MyBudgetWeb.Format

  embed_templates "movement_html/*"

  @doc """
  Renders a movement form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :categories_options, :list, required: true
  attr :payment_method_options, :list, required: true
  attr :type_options, :list, required: true
  attr :return_to, :string, default: "index"
  attr :return_params, :map, default: %{}
  attr :cancel_path, :string, required: true

  def movement_form(assigns)

  @doc """
  Formats an amount in cents as BRL currency.
  """
  defdelegate format_amount(cents), to: Format, as: :amount

  @doc """
  Formats a date as day/month/year.
  """
  defdelegate format_date(date), to: Format, as: :date

  @doc """
  Human label for a movement type.
  """
  defdelegate movement_type_label(type), to: Format

  @doc """
  Color class for a movement type: green for income, red for expense.
  """
  defdelegate movement_type_class(type), to: Format
end
