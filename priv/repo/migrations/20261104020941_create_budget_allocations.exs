defmodule MyBudget.Repo.Migrations.CreateBudgetAllocations do
  use Ecto.Migration

  def change do
    create table(:budget_allocations) do
      add :monthly_budget_id, references(:monthly_budgets, on_delete: :delete_all), null: false
      add :category_id, references(:category, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :planned_amount, :integer, null: false, default: 0
      add :rollover_amount, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:budget_allocations, [:monthly_budget_id, :category_id])
    create index(:budget_allocations, [:monthly_budget_id])
  end
end
