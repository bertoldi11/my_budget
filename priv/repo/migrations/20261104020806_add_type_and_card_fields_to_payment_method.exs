defmodule MyBudget.Repo.Migrations.AddTypeAndCardFieldsToPaymentMethod do
  use Ecto.Migration

  def change do
    alter table(:payment_method) do
      add :type, :string, null: false, default: "conta_corrente"
      add :due_day, :integer
      add :closing_day, :integer
    end
  end
end
