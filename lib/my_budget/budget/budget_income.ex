defmodule MyBudget.Budget.BudgetIncome do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Budget.MonthlyBudget

  schema "budget_incomes" do
    field :description, :string
    field :amount, :integer
    field :amount_reais, :string, virtual: true
    field :user_id, :id

    belongs_to :monthly_budget, MonthlyBudget

    timestamps(type: :utc_datetime)
  end

  def changeset(income, attrs, user_scope) do
    income
    |> cast(attrs, [:description, :amount, :amount_reais])
    |> put_amount_from_reais()
    |> validate_required([:description])
    |> validate_amount()
    |> put_change(:user_id, user_scope.user.id)
  end

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
end
