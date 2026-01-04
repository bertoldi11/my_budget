defmodule MyBudget.Repo.Migrations.CreateMovement do
  use Ecto.Migration

  def change do
    create table(:movement) do
      add :amount, :integer
      add :description, :string
      add :counter_party, :string
      add :type, :string
      add :category_id, references(:category, on_delete: :nothing)
      add :payment_method_id, references(:payment_method, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:movement, [:user_id])

    create index(:movement, [:category_id])
    create index(:movement, [:payment_method_id])
  end
end
