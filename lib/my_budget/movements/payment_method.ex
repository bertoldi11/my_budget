defmodule MyBudget.Movements.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "payment_method" do
    field :name, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment_method, attrs, user_scope) do
    payment_method
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
