defmodule MyBudgetWeb.Api.MovementController do
  @moduledoc """
  Cadastro de movimentações pelo app mobile (`my_budget_mobile`).

  `new` devolve só as opções dos selects do formulário — as mesmas do cadastro
  no web, via `MyBudgetWeb.MovementOptions` — e `create` grava pelo mesmo
  `MyBudget.Movements.create_movement/2`, inclusive o parcelamento.
  """

  use MyBudgetWeb, :controller

  alias MyBudget.Movements
  alias MyBudgetWeb.MovementOptions

  action_fallback MyBudgetWeb.Api.FallbackController

  @default_per_page 25
  @max_per_page 100

  # GET /api/movement
  def index(conn, params) do
    scope = conn.assigns.current_scope

    page = page_param(params["page"], 1)
    per_page = params["per_page"] |> page_param(@default_per_page) |> min(@max_per_page)

    render(conn, :index,
      movements: Movements.list_movement_page(scope, page, per_page),
      page: page,
      per_page: per_page,
      total_count: Movements.count_movement(scope)
    )
  end

  # GET /api/movement/new
  def new(conn, _params) do
    scope = conn.assigns.current_scope

    render(conn, :new,
      categories: Movements.list_available_category(scope),
      payment_methods: Movements.list_payment_method(scope),
      types: MovementOptions.type_options()
    )
  end

  # POST /api/movement
  def create(conn, %{"movement" => movement_params}) when is_map(movement_params) do
    scope = conn.assigns.current_scope

    with {:ok, movement} <- Movements.create_movement(scope, movement_params) do
      conn
      |> put_status(:created)
      |> render(:show, movement: movement)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: ~s(Envie "movement" com os campos da movimentação.))
  end

  # Um `page` ou `per_page` ausente, malformado ou fora de faixa cai no padrão em
  # vez de responder 400: o app não deve ficar sem a lista por causa disso. Vem
  # como string na query string, ou como número se o cliente mandar JSON.
  defp page_param(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed >= 1 -> parsed
      _ -> default
    end
  end

  defp page_param(value, _default) when is_integer(value) and value >= 1, do: value
  defp page_param(_value, default), do: default
end
