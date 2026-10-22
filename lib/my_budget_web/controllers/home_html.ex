defmodule MyBudgetWeb.HomeHTML do
  use MyBudgetWeb, :html

  embed_templates "home_html/*"

  @doc """
  Width (as a CSS percentage) of a category's share of its section total.
  """
  def bar_width(_amount, total) when total in [0, nil], do: "0%"
  def bar_width(amount, total), do: "#{Float.round(amount / total * 100, 1)}%"
end
