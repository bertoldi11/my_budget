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

  def section_form(assigns)
end
