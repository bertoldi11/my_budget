defmodule MyBudget.Movements.Movement do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Movements.PaymentMethod
  alias MyBudget.Movements.Category

  schema "movement" do
    field :amount, :integer
    field :description, :string
    field :counter_party, :string
    field :type, :string
    field :user_id, :id
    field :expend_date, :date

    belongs_to :category, Category
    belongs_to :payment_method, PaymentMethod

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(amount description counter_party type category_id payment_method_id expend_date)a

  @doc false
  def changeset(movement, attrs, user_scope) do
    movement
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> put_change(:user_id, user_scope.user.id)
  end
end
