defmodule MyBudget.Repo.Migrations.CreateSection do
  use Ecto.Migration

  def change do
    create table(:section) do
      add :name, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:section, [:user_id])
  end
end
