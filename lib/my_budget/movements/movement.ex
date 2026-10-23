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

    field :formatted_expend_date, :string, virtual: true
    field :formatted_amount, :string, virtual: true
    # Valor em reais digitado no formulário (ex.: "1.234,56"); convertido para
    # centavos em `:amount` pela changeset.
    field :amount_reais, :string, virtual: true

    belongs_to :category, Category
    belongs_to :payment_method, PaymentMethod

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(description counter_party type category_id payment_method_id expend_date)a

  @doc false
  def changeset(movement, attrs, user_scope) do
    movement
    |> cast(attrs, [:amount, :amount_reais | @required_fields])
    |> put_amount_from_reais()
    |> validate_required(@required_fields)
    |> validate_amount()
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
