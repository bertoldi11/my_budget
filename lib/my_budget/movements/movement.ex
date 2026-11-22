defmodule MyBudget.Movements.Movement do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Movements.PaymentMethod
  alias MyBudget.Movements.Category

  schema "movement" do
    field :amount, :integer
    field :description, :string
    field :counter_party, :string
    field :type, :string
    field :user_id, :id
    field :expend_date, :date

    # Valor em reais digitado no formulário (ex.: "1.234,56"); convertido para
    # centavos em `:amount` pela changeset.
    field :amount_reais, :string, virtual: true

    # Quantidade de parcelas informada no cadastro. Quando maior que 1, o valor
    # é dividido igualmente e é gerada uma movimentação por parcela (ver
    # `MyBudget.Movements.create_movement/2`).
    field :installments, :integer, virtual: true, default: 1

    belongs_to :category, Category
    belongs_to :payment_method, PaymentMethod

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(description counter_party type category_id payment_method_id expend_date)a

  @max_installments 120

  @doc false
  def changeset(movement, attrs, user_scope) do
    movement
    |> cast(attrs, [:amount, :amount_reais, :installments | @required_fields])
    |> put_amount_from_reais()
    |> validate_required(@required_fields)
    |> validate_amount()
    |> validate_installments()
    |> put_change(:user_id, user_scope.user.id)
  end

  @doc """
  Fills the virtual `:amount_reais` from the persisted `:amount` (in cents) for
  display in the form, when the user hasn't typed a value yet. Used when
  building a changeset to render the movement form.
  """
  def put_amount_reais_display(changeset) do
    with nil <- get_change(changeset, :amount_reais),
         cents when is_integer(cents) <- get_field(changeset, :amount) do
      put_change(changeset, :amount_reais, format_reais(cents))
    else
      _ -> changeset
    end
  end

  # Converte o valor em reais informado no formulário para centavos.
  defp put_amount_from_reais(changeset) do
    case get_change(changeset, :amount_reais) do
      value when is_binary(value) and value != "" ->
        case parse_amount_to_cents(value) do
          {:ok, cents} -> put_change(changeset, :amount, cents)
          :error -> add_error(changeset, :amount_reais, "valor inválido")
        end

      _ ->
        changeset
    end
  end

  # Garante que o valor foi informado, sempre reportando o erro no campo visível.
  defp validate_amount(changeset) do
    cond do
      Keyword.has_key?(changeset.errors, :amount_reais) ->
        changeset

      is_nil(get_field(changeset, :amount)) ->
        add_error(changeset, :amount_reais, "can't be blank")

      true ->
        changeset
    end
  end

  @doc """
  Splits `amount` (in cents) into `count` equal installments. When the division
  is not exact, the remaining cents are added to the last installment, so the
  sum of the installments is always equal to `amount`.

  ## Examples

      iex> split_amount(10_000, 3)
      [3_333, 3_333, 3_334]

  """
  def split_amount(amount, count) when is_integer(amount) and is_integer(count) and count > 0 do
    base = div(amount, count)
    List.duplicate(base, count - 1) ++ [amount - base * (count - 1)]
  end

  # Parcelas: entre 1 e @max_installments, e cada parcela precisa ter ao menos
  # um centavo.
  defp validate_installments(changeset) do
    changeset =
      changeset
      |> validate_required([:installments], message: "informe o número de parcelas")
      |> validate_number(:installments,
        greater_than_or_equal_to: 1,
        less_than_or_equal_to: @max_installments,
        message: "deve estar entre 1 e #{@max_installments}"
      )

    installments = get_field(changeset, :installments)
    amount = get_field(changeset, :amount)

    if is_integer(installments) and installments > 1 and is_integer(amount) and
         abs(amount) < installments do
      add_error(changeset, :installments, "valor insuficiente para essa quantidade de parcelas")
    else
      changeset
    end
  end

  defp parse_amount_to_cents(value) when is_integer(value), do: {:ok, value}

  defp parse_amount_to_cents(value) when is_binary(value) do
    cleaned = String.replace(value, ~r/[^\d,.-]/u, "")

    normalized =
      if String.contains?(cleaned, ","),
        do: cleaned |> String.replace(".", "") |> String.replace(",", "."),
        else: cleaned

    case Decimal.parse(normalized) do
      {decimal, ""} ->
        {:ok, decimal |> Decimal.mult(100) |> Decimal.round(0) |> Decimal.to_integer()}

      _ ->
        :error
    end
  end

  defp parse_amount_to_cents(_), do: :error

  defp format_reais(cents) do
    cents
    |> Decimal.new()
    |> Decimal.div(100)
    |> Decimal.round(2)
    |> Decimal.to_string(:normal)
    |> String.replace(".", ",")
  end
end
