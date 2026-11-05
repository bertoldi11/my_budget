defmodule MyBudget.Budget.BudgetAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Budget.MonthlyBudget
  alias MyBudget.Movements.Category

  schema "budget_allocations" do
    field :planned_amount, :integer, default: 0
    field :rollover_amount, :integer, default: 0
    field :planned_amount_reais, :string, virtual: true
    field :user_id, :id

    belongs_to :monthly_budget, MonthlyBudget
    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  def changeset(allocation, attrs, user_scope) do
    allocation
    |> cast(attrs, [:planned_amount, :planned_amount_reais, :rollover_amount, :category_id])
    |> put_amount_from_reais()
    |> validate_required([:category_id])
    |> validate_number(:planned_amount, greater_than_or_equal_to: 0)
    |> validate_number(:rollover_amount, greater_than_or_equal_to: 0)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp put_amount_from_reais(changeset) do
    case get_change(changeset, :planned_amount_reais) do
      value when is_binary(value) and value != "" ->
        case parse_amount_to_cents(value) do
          {:ok, cents} -> put_change(changeset, :planned_amount, cents)
          :error -> add_error(changeset, :planned_amount_reais, "valor inválido")
        end

      _ ->
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
