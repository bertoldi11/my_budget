defmodule MyBudgetWeb.PaymentMethodHTML do
  use MyBudgetWeb, :html

  alias MyBudgetWeb.Format

  embed_templates "payment_method_html/*"

  @doc """
  Renders a payment method form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: "index"
  attr :cancel_path, :string, required: true

  def payment_method_form(assigns)

  defdelegate format_amount(cents), to: Format, as: :amount
  defdelegate format_date(date), to: Format, as: :date
  defdelegate short_date(date), to: Format, as: :short_date
  defdelegate movement_type_label(type), to: Format
  defdelegate movement_type_class(type), to: Format

  @doc """
  Title of the current period shown on the payment method page: the invoice due
  month for credit cards, the calendar month for every other type.
  """
  def period_title(%{kind: :invoice}, reference),
    do: "Fatura de #{reference.month_name} de #{reference.year}"

  def period_title(_period, reference),
    do: "#{reference.month_name} de #{reference.year}"

  @doc """
  Compact description of the days covered by the period, plus the due date when
  the period is a credit card invoice.
  """
  def period_subtitle(%{kind: :invoice} = period) do
    "#{short_date(period.start_date)} a #{short_date(period.end_date)} · vence #{format_date(period.due_date)}"
  end

  def period_subtitle(period) do
    "#{short_date(period.start_date)} a #{short_date(period.end_date)}"
  end

  @doc """
  Label and value of the period's bottom line: what is owed on a credit card
  invoice, the net balance for every other type.
  """
  def period_result(%{kind: :invoice}, totals), do: {"Total da fatura", totals.invoice}
  def period_result(_period, totals), do: {"Saldo", totals.balance}

  @doc """
  Path to the new movement form with this payment method already selected. The
  reference month travels along so that saving or cancelling brings the user
  back to this same period.
  """
  def new_movement_path(payment_method, reference) do
    ~p"/movement/new?payment_method_id=#{payment_method.id}&return_to=payment_method&m=#{reference.month}&y=#{reference.year}"
  end

  def payment_method_type_label("conta_corrente"), do: "Conta Corrente"
  def payment_method_type_label("conta_investimento"), do: "Conta Investimento"
  def payment_method_type_label("cartao_credito"), do: "Cartão de Crédito"
  def payment_method_type_label("cartao_debito"), do: "Cartão de Débito"
  def payment_method_type_label(_), do: "—"
end
