defmodule MyBudget.Movements.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Movements.Section

  schema "category" do
    field :name, :string
    field :user_id, :id

    belongs_to :section, Section

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sub_category, attrs, user_scope) do
    sub_category
    |> cast(attrs, [:name, :section_id])
    |> validate_required([:name, :section_id])
    |> put_change(:user_id, user_scope.user.id)
  end
end
