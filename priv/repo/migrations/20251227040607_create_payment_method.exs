defmodule MyBudget.Repo.Migrations.CreatePaymentMethod do
  use Ecto.Migration

  def change do
    create table(:payment_method) do
      add :name, :string
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:payment_method, [:user_id])
  end
end
