defmodule MyBudgetWeb.CategoryHTML do
  use MyBudgetWeb, :html

  embed_templates "category_html/*"

  @doc """
  Renders a category form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :sections_options, :list, required: true
  attr :return_to, :string, default: "index"
  attr :cancel_path, :string, required: true

  def category_form(assigns)
end
