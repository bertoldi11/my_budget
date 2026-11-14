defmodule MyBudgetWeb.MovementController do
  use MyBudgetWeb, :controller

  action_fallback MyBudgetWeb.FallbackController

  alias MyBudget.Movements
  alias MyBudget.Movements.Movement

  def index(conn, _params) do
    movement_collection = Movements.list_movement(conn.assigns.current_scope)

    render(conn, :index, page_title: "Movimentações", movement_collection: movement_collection)
  end

  def new(conn, params) do
    scope = conn.assigns.current_scope

    movement = %Movement{
      user_id: scope.user.id,
      payment_method_id: prefilled_payment_method_id(scope, params)
    }

    conn
    |> assign_new_context(params)
    |> render(:new, form: to_form(Movements.change_movement(scope, movement)))
  end

  def create(conn, %{"movement" => movement_params} = params) do
    scope = conn.assigns.current_scope

    conn = assign_new_context(conn, params)

    with {:ok, movement} <- Movements.create_movement(scope, movement_params) do
      conn
      |> put_flash(:info, "Movimentação cadastrada com sucesso!")
      |> redirect(to: return_path(conn.assigns.return_to, movement, params))
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
      |> redirect(to: return_path(return_to, updated_movement, params))
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

  # O formulário de nova movimentação pode ser aberto da listagem ou da tela de
  # um método de pagamento. A origem viaja em campos escondidos (`return_to`,
  # `m` e `y`) para que, ao salvar ou cancelar, o usuário volte de onde saiu —
  # no caso do método de pagamento, inclusive no mesmo mês de referência.
  defp assign_new_context(conn, params) do
    return_to = return_to(params["return_to"])

    conn
    |> assign(:page_title, "Nova Movimentação")
    |> assign(:return_to, return_to)
    |> assign(:return_params, return_params(params))
    |> assign(:cancel_path, cancel_path(return_to, params))
    |> assign_form_options()
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

  # O método de pagamento vem pré-selecionado quando o formulário é aberto da
  # tela de um método de pagamento. A busca pelo escopo garante que ele é do
  # próprio usuário.
  defp prefilled_payment_method_id(scope, %{"payment_method_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} -> Movements.get_payment_method!(scope, id).id
      _ -> nil
    end
  end

  defp prefilled_payment_method_id(_scope, _params), do: nil

  defp return_to("show"), do: "show"
  defp return_to("payment_method"), do: "payment_method"
  defp return_to(_), do: "index"

  defp return_path("show", movement, _params), do: ~p"/movement/#{movement}"

  defp return_path("payment_method", movement, params),
    do: payment_method_path(movement.payment_method_id, params)

  defp return_path(_return_to, _movement, _params), do: ~p"/movement"

  defp cancel_path("payment_method", params) do
    movement_params = Map.get(params, "movement", %{})
    payment_method_id = movement_params["payment_method_id"] || params["payment_method_id"]

    payment_method_path(payment_method_id, params)
  end

  defp cancel_path(_return_to, _params), do: ~p"/movement"

  # Campos escondidos que o formulário reenvia no POST para preservar a origem.
  defp return_params(params) do
    case reference(params) do
      {month, year} -> %{"m" => month, "y" => year}
      nil -> %{}
    end
  end

  defp payment_method_path(payment_method_id, _params)
       when payment_method_id in [nil, ""],
       do: ~p"/payment_method"

  defp payment_method_path(payment_method_id, params) do
    case reference(params) do
      {month, year} -> ~p"/payment_method/#{payment_method_id}?m=#{month}&y=#{year}"
      nil -> ~p"/payment_method/#{payment_method_id}"
    end
  end

  # Mês de referência que estava sendo visto na tela do método de pagamento.
  # Valores inválidos são ignorados e levam de volta ao mês corrente.
  defp reference(%{"m" => month, "y" => year}) do
    with {month, ""} <- month |> to_string() |> Integer.parse(),
         {year, ""} <- year |> to_string() |> Integer.parse(),
         true <- month in 1..12 and year in 1900..2999 do
      {month, year}
    else
      _ -> nil
    end
  end

  defp reference(_params), do: nil
end
