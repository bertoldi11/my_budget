defmodule MyBudget.Repo.Migrations.AddBudgetEnabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :budget_enabled, :boolean, null: false, default: false
    end
  end
end
