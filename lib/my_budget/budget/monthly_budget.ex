defmodule MyBudget.Budget.MonthlyBudget do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Budget.BudgetIncome
  alias MyBudget.Budget.BudgetAllocation

  @valid_statuses ~w(draft balanced)

  schema "monthly_budgets" do
    field :reference_date, :date
    field :status, :string, default: "draft"
    field :user_id, :id

    has_many :incomes, BudgetIncome, foreign_key: :monthly_budget_id
    has_many :allocations, BudgetAllocation, foreign_key: :monthly_budget_id

    timestamps(type: :utc_datetime)
  end

  def changeset(budget, attrs, user_scope) do
    budget
    |> cast(attrs, [:reference_date, :status])
    |> validate_required([:reference_date])
    |> validate_inclusion(:status, @valid_statuses)
    |> put_change(:user_id, user_scope.user.id)
  end
end
