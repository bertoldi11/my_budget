defmodule MyBudget.Movements.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(conta_corrente conta_investimento cartao_credito cartao_debito)

  schema "payment_method" do
    field :name, :string
    field :type, :string
    field :due_day, :integer
    field :closing_day, :integer
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  def valid_types, do: @valid_types

  @doc false
  def changeset(payment_method, attrs, user_scope) do
    payment_method
    |> cast(attrs, [:name, :type, :due_day, :closing_day])
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, @valid_types)
    |> validate_credit_card_fields()
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_credit_card_fields(changeset) do
    if get_field(changeset, :type) == "cartao_credito" do
      changeset
      |> validate_required([:due_day, :closing_day])
      |> validate_number(:due_day, greater_than_or_equal_to: 1, less_than_or_equal_to: 28)
      |> validate_number(:closing_day, greater_than_or_equal_to: 1, less_than_or_equal_to: 28)
    else
      changeset
      |> put_change(:due_day, nil)
      |> put_change(:closing_day, nil)
    end
  end
end
