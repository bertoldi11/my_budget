defmodule MyBudget.Repo.Migrations.AddExpendDateToMovement do
  use Ecto.Migration

  def change do
    alter table("movement") do
      add :expend_date, :date
    end
  end
end
