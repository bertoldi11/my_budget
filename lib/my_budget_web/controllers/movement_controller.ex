defmodule MyBudgetWeb.MovementController do
  use MyBudgetWeb, :controller

  action_fallback MyBudgetWeb.FallbackController

  alias MyBudget.Movements
  alias MyBudget.Movements.Movement

  def index(conn, _params) do
    movement_collection = Movements.list_movement(conn.assigns.current_scope)

    render(conn, :index, page_title: "Movimentações", movement_collection: movement_collection)
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Movements.change_movement(scope, %Movement{user_id: scope.user.id})

    render_new(conn, changeset)
  end

  def create(conn, %{"movement" => movement_params}) do
    scope = conn.assigns.current_scope

    conn =
      conn
      |> assign(:page_title, "Nova Movimentação")
      |> assign_form_options()

    with {:ok, _movement} <- Movements.create_movement(scope, movement_params) do
      conn
      |> put_flash(:info, "Movimentação cadastrada com sucesso!")
      |> redirect(to: ~p"/movement")
    else
      error -> {conn, error}
    end
  end

  def show(conn, %{"id" => id}) do
    movement = Movements.get_movement_with_associations!(conn.assigns.current_scope, id)

    render(conn, :show, page_title: "Movimentação", movement: movement)
  end

  def edit(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope
    movement = Movements.get_movement!(scope, id)
    changeset = Movements.change_movement(scope, movement)

    render_edit(conn, movement, changeset, return_to(params["return_to"]))
  end

  def update(conn, %{"id" => id, "movement" => movement_params} = params) do
    scope = conn.assigns.current_scope
    movement = Movements.get_movement!(scope, id)
    return_to = return_to(params["return_to"])

    conn =
      conn
      |> assign(:page_title, "Editar Movimentação")
      |> assign(:movement, movement)
      |> assign(:return_to, return_to)
      |> assign_form_options()

    with {:ok, updated_movement} <- Movements.update_movement(scope, movement, movement_params) do
      conn
      |> put_flash(:info, "Movimentação atualizada com sucesso!")
      |> redirect(to: return_path(return_to, updated_movement))
    else
      error -> {conn, error}
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    movement = Movements.get_movement!(scope, id)

    with {:ok, _movement} <- Movements.delete_movement(scope, movement) do
      conn
      |> put_flash(:info, "Movimentação apagada com sucesso!")
      |> redirect(to: ~p"/movement")
    else
      error -> {conn, error}
    end
  end

  defp render_new(conn, changeset) do
    conn
    |> assign_form_options()
    |> render(:new, page_title: "Nova Movimentação", form: to_form(changeset))
  end

  defp render_edit(conn, movement, changeset, return_to) do
    conn
    |> assign_form_options()
    |> render(:edit,
      page_title: "Editar Movimentação",
      movement: movement,
      return_to: return_to,
      form: to_form(changeset)
    )
  end

  defp assign_form_options(conn) do
    scope = conn.assigns.current_scope

    categories_options =
      scope
      |> Movements.list_category()
      |> Enum.map(&{"#{&1.section.name} / #{&1.name}", &1.id})

    payment_method_options =
      scope
      |> Movements.list_payment_method()
      |> Enum.map(&{&1.name, &1.id})

    conn
    |> assign(:categories_options, categories_options)
    |> assign(:payment_method_options, payment_method_options)
    |> assign(:type_options, [{"Saída", "debit"}, {"Entrada", "credit"}])
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path("index", _movement), do: ~p"/movement"
  defp return_path("show", movement), do: ~p"/movement/#{movement}"
end
