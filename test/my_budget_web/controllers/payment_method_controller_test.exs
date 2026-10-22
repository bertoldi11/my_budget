defmodule MyBudgetWeb.PaymentMethodControllerTest do
  use MyBudgetWeb.ConnCase

  import MyBudget.MovementsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all payment_method", %{conn: conn, scope: scope} do
      payment_method = payment_method_fixture(scope)
      conn = get(conn, ~p"/payment_method")
      response = html_response(conn, 200)
      assert response =~ "Métodos de Pagamento"
      assert response =~ payment_method.name
    end
  end

  describe "new payment_method" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/payment_method/new")
      assert html_response(conn, 200) =~ "Novo Método de Pagamento"
    end
  end

  describe "create payment_method" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/payment_method", payment_method: @create_attrs)
      assert redirected_to(conn) == ~p"/payment_method"

      conn = get(conn, ~p"/payment_method")
      assert html_response(conn, 200) =~ "some name"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/payment_method", payment_method: @invalid_attrs)
      response = html_response(conn, 200)
      assert response =~ "Novo Método de Pagamento"
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "show payment_method" do
    setup [:create_payment_method]

    test "displays payment_method", %{conn: conn, payment_method: payment_method} do
      conn = get(conn, ~p"/payment_method/#{payment_method}")
      assert html_response(conn, 200) =~ "Método de Pagamento: #{payment_method.id}"
    end
  end

  describe "edit payment_method" do
    setup [:create_payment_method]

    test "renders form for editing chosen payment_method", %{
      conn: conn,
      payment_method: payment_method
    } do
      conn = get(conn, ~p"/payment_method/#{payment_method}/edit")
      assert html_response(conn, 200) =~ "Editar Método de Pagamento"
    end
  end

  describe "update payment_method" do
    setup [:create_payment_method]

    test "redirects to index when data is valid", %{conn: conn, payment_method: payment_method} do
      conn = put(conn, ~p"/payment_method/#{payment_method}", payment_method: @update_attrs)
      assert redirected_to(conn) == ~p"/payment_method"

      conn = get(conn, ~p"/payment_method/#{payment_method}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "redirects to show when return_to is show", %{conn: conn, payment_method: payment_method} do
      conn =
        put(conn, ~p"/payment_method/#{payment_method}",
          payment_method: @update_attrs,
          return_to: "show"
        )

      assert redirected_to(conn) == ~p"/payment_method/#{payment_method}"
    end

    test "renders errors when data is invalid", %{conn: conn, payment_method: payment_method} do
      conn = put(conn, ~p"/payment_method/#{payment_method}", payment_method: @invalid_attrs)
      assert html_response(conn, 200) =~ "Editar Método de Pagamento"
    end
  end

  describe "delete payment_method" do
    setup [:create_payment_method]

    test "deletes chosen payment_method", %{conn: conn, payment_method: payment_method} do
      conn = delete(conn, ~p"/payment_method/#{payment_method}")
      assert redirected_to(conn) == ~p"/payment_method"

      assert_error_sent 404, fn ->
        get(conn, ~p"/payment_method/#{payment_method}")
      end
    end
  end

  defp create_payment_method(%{scope: scope}) do
    %{payment_method: payment_method_fixture(scope)}
  end
end
