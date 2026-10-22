defmodule MyBudgetWeb.MovementHTML do
  use MyBudgetWeb, :html

  alias MyBudgetWeb.Cldr

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
  attr :cancel_path, :string, required: true

  def movement_form(assigns)

  @doc """
  Formats an amount in cents as BRL currency.
  """
  def format_amount(amount) do
    {:ok, formatted_amount} = Cldr.Number.to_string(amount / 100, locale: "pt", currency: "BRL")
    formatted_amount
  end

  @doc """
  Formats a date as day/month/year.
  """
  def format_date(%Date{} = date), do: "#{date.day}/#{date.month}/#{date.year}"

  @doc """
  Human label for a movement type.
  """
  def movement_type_label("credit"), do: "Entrada"
  def movement_type_label("debit"), do: "Saída"
  def movement_type_label(other), do: other

  @doc """
  Color class for a movement type: green for income, red for expense.
  """
  def movement_type_class("credit"), do: "text-success font-semibold"
  def movement_type_class("debit"), do: "text-error font-semibold"
  def movement_type_class(_other), do: ""
end
