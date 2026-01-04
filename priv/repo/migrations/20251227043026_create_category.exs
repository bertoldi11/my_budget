defmodule MyBudget.Repo.Migrations.CreateCategory do
  use Ecto.Migration

  def change do
    create table(:category) do
      add :name, :string
      add :section_id, references(:section, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:category, [:user_id])

    create index(:category, [:section_id])
  end
end
