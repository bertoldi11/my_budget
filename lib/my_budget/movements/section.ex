defmodule MyBudget.Movements.Section do
  use Ecto.Schema
  import Ecto.Changeset

  schema "section" do
    field :name, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(section, attrs, user_scope) do
    section
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
