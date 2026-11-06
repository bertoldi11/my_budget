defmodule MyBudgetWeb.SectionHTML do
  use MyBudgetWeb, :html

  embed_templates "section_html/*"

  @doc """
  Renders a section form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: "index"
  attr :cancel_path, :string, required: true
  attr :show_budget_toggle, :boolean, default: false

  def section_form(assigns)
end
