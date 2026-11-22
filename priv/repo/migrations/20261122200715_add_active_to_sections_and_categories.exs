defmodule MyBudget.Repo.Migrations.AddActiveToSectionsAndCategories do
  use Ecto.Migration

  def change do
    alter table(:section) do
      add :active, :boolean, default: true, null: false
    end

    alter table(:category) do
      add :active, :boolean, default: true, null: false
    end
  end
end
