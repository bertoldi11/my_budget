defmodule MyBudget.Repo.Migrations.CreateMonthlyBudgets do
  use Ecto.Migration

  def change do
    create table(:monthly_budgets) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :reference_date, :date, null: false
      add :status, :string, null: false, default: "draft"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:monthly_budgets, [:user_id, :reference_date])
    create index(:monthly_budgets, [:user_id])
  end
end
