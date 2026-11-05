defmodule MyBudget.Repo.Migrations.AddBudgetActiveToCategories2 do
  use Ecto.Migration

  def change do
    alter table(:category) do
      add :budget_active, :boolean, null: false, default: true
    end
  end
end
