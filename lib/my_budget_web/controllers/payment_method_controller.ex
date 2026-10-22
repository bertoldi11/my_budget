defmodule MyBudgetWeb.PaymentMethodController do
  use MyBudgetWeb, :controller

  alias MyBudget.Movements
  alias MyBudget.Movements.PaymentMethod

  def index(conn, _params) do
    payment_method_collection = Movements.list_payment_method(conn.assigns.current_scope)

    render(conn, :index,
      page_title: "Métodos de Pagamento",
      payment_method_collection: payment_method_collection
    )
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Movements.change_payment_method(scope, %PaymentMethod{user_id: scope.user.id})

    render(conn, :new, page_title: "Novo Método de Pagamento", form: to_form(changeset))
  end

  def create(conn, %{"payment_method" => payment_method_params}) do
    case Movements.create_payment_method(conn.assigns.current_scope, payment_method_params) do
      {:ok, _payment_method} ->
        conn
        |> put_flash(:info, "Método de pagamento cadastrado com sucesso!")
        |> redirect(to: ~p"/payment_method")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, page_title: "Novo Método de Pagamento", form: to_form(changeset))
    end
  end

  def show(conn, %{"id" => id}) do
    payment_method = Movements.get_payment_method!(conn.assigns.current_scope, id)

    render(conn, :show, page_title: "Método de Pagamento", payment_method: payment_method)
  end

  def edit(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)

    render(conn, :edit,
      page_title: "Editar Método de Pagamento",
      payment_method: payment_method,
      return_to: return_to(params["return_to"]),
      form: to_form(Movements.change_payment_method(scope, payment_method))
    )
  end

  def update(conn, %{"id" => id, "payment_method" => payment_method_params} = params) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)
    return_to = return_to(params["return_to"])

    case Movements.update_payment_method(scope, payment_method, payment_method_params) do
      {:ok, payment_method} ->
        conn
        |> put_flash(:info, "Método de pagamento atualizado com sucesso!")
        |> redirect(to: return_path(return_to, payment_method))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          page_title: "Editar Método de Pagamento",
          payment_method: payment_method,
          return_to: return_to,
          form: to_form(changeset)
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    payment_method = Movements.get_payment_method!(scope, id)
    {:ok, _payment_method} = Movements.delete_payment_method(scope, payment_method)

    conn
    |> put_flash(:info, "Método de pagamento apagado com sucesso!")
    |> redirect(to: ~p"/payment_method")
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path("index", _payment_method), do: ~p"/payment_method"
  defp return_path("show", payment_method), do: ~p"/payment_method/#{payment_method}"
end
