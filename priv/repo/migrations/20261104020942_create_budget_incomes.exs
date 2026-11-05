defmodule MyBudget.Repo.Migrations.CreateBudgetIncomes do
  use Ecto.Migration

  def change do
    create table(:budget_incomes) do
      add :monthly_budget_id, references(:monthly_budgets, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :description, :string, null: false
      add :amount, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:budget_incomes, [:monthly_budget_id])
  end
end
