defmodule MyBudget.Movements.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(conta_corrente conta_investimento cartao_credito cartao_debito)

  schema "payment_method" do
    field :name, :string
    field :type, :string
    field :due_day, :integer
    field :closing_day, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  def valid_types, do: @valid_types

  @doc """
  Returns the period of movements that a payment method shows for the given
  reference month/year.

  For credit cards (with `closing_day` and `due_day` set) the reference
  month/year identifies the **invoice due month**: the period covers the days
  between the previous closing day (exclusive) and the closing day that
  precedes the due date (inclusive).

  For every other type the period is simply the calendar month.

  ## Examples

      # Card closing on the 3rd, due on the 10th: the invoice due on
      # 2026-11-10 covers 2026-10-04 up to 2026-11-03.
      iex> period(%PaymentMethod{type: "cartao_credito", closing_day: 3, due_day: 10}, 2026, 11)
      %{kind: :invoice, start_date: ~D[2026-10-04], end_date: ~D[2026-11-03], due_date: ~D[2026-11-10]}

      iex> period(%PaymentMethod{type: "conta_corrente"}, 2026, 11)
      %{kind: :month, start_date: ~D[2026-11-01], end_date: ~D[2026-11-30], due_date: nil}

  """
  def period(payment_method, year, month)

  def period(
        %__MODULE__{type: "cartao_credito", closing_day: closing_day, due_day: due_day},
        year,
        month
      )
      when is_integer(closing_day) and is_integer(due_day) do
    due_date = Date.new!(year, month, due_day)

    # A fatura que vence em `due_date` fecha no último `closing_day` anterior a
    # ela: no mesmo mês quando o fechamento vem antes do vencimento, senão no
    # mês anterior.
    closing_date =
      if closing_day < due_day do
        Date.new!(year, month, closing_day)
      else
        year |> Date.new!(month, closing_day) |> Date.shift(month: -1)
      end

    previous_closing_date = Date.shift(closing_date, month: -1)

    %{
      kind: :invoice,
      start_date: Date.add(previous_closing_date, 1),
      end_date: closing_date,
      due_date: due_date
    }
  end

  def period(%__MODULE__{}, year, month) do
    first_day = Date.new!(year, month, 1)

    %{
      kind: :month,
      start_date: first_day,
      end_date: Date.end_of_month(first_day),
      due_date: nil
    }
  end

  @doc false
  def changeset(payment_method, attrs, user_scope) do
    payment_method
    |> cast(attrs, [:name, :type, :due_day, :closing_day])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, @valid_types)
    |> validate_credit_card_fields()
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_credit_card_fields(changeset) do
    if get_field(changeset, :type) == "cartao_credito" do
      changeset
      |> validate_required([:due_day, :closing_day])
      |> validate_number(:due_day, greater_than_or_equal_to: 1, less_than_or_equal_to: 28)
      |> validate_number(:closing_day, greater_than_or_equal_to: 1, less_than_or_equal_to: 28)
    else
      changeset
      |> put_change(:due_day, nil)
      |> put_change(:closing_day, nil)
    end
  end
end
