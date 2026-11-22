defmodule MyBudget.Movements.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias MyBudget.Movements.Section

  schema "category" do
    field :name, :string
    field :budget_active, :boolean, default: false
    # Desativada, não aparece no cadastro de movimentações nem entra em novos
    # orçamentos. O histórico (movimentações e orçamentos antigos) é mantido.
    field :active, :boolean, default: true
    field :user_id, :id

    belongs_to :section, Section

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sub_category, attrs, user_scope) do
    sub_category
    |> cast(attrs, [:name, :section_id, :budget_active, :active])
    |> validate_required([:name, :section_id])
    |> put_change(:user_id, user_scope.user.id)
  end
end
