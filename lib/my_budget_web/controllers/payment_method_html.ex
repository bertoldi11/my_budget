defmodule MyBudgetWeb.PaymentMethodHTML do
  use MyBudgetWeb, :html

  embed_templates "payment_method_html/*"

  @doc """
  Renders a payment method form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: "index"
  attr :cancel_path, :string, required: true

  def payment_method_form(assigns)
end
