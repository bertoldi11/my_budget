defmodule MyBudget.Movements.Section do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Movements.Category

  schema "section" do
    field :name, :string
    field :budget_active, :boolean, default: false
    field :user_id, :id

    has_many :categories, Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(section, attrs, user_scope) do
    section
    |> cast(attrs, [:name, :budget_active])
    |> validate_required([:name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
