defmodule MyBudget.Repo.Migrations.AddBudgetActiveToSections do
  use Ecto.Migration

  def change do
    alter table(:section) do
      add :budget_active, :boolean, null: false, default: true
    end
  end
end
