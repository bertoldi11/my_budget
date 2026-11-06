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

  def payment_method_type_label("conta_corrente"), do: "Conta Corrente"
  def payment_method_type_label("conta_investimento"), do: "Conta Investimento"
  def payment_method_type_label("cartao_credito"), do: "Cartão de Crédito"
  def payment_method_type_label("cartao_debito"), do: "Cartão de Débito"
  def payment_method_type_label(_), do: "—"
end
