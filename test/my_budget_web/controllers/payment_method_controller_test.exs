defmodule MyBudgetWeb.PaymentMethodControllerTest do
  use MyBudgetWeb.ConnCase

  import MyBudget.MovementsFixtures

  @create_attrs %{name: "some name", type: "conta_corrente"}
  @update_attrs %{name: "some updated name", type: "conta_corrente"}
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
      response = html_response(conn, 200)
      assert response =~ payment_method.name
      assert response =~ "Conta Corrente"
    end

    test "links to the new movement form with this payment method and period", %{
      conn: conn,
      payment_method: payment_method
    } do
      conn = get(conn, ~p"/payment_method/#{payment_method}?m=11&y=2026")
      response = html_response(conn, 200)

      expected =
        ~p"/movement/new?payment_method_id=#{payment_method.id}&return_to=payment_method&m=11&y=2026"

      assert attr(response, "#new-movement", "href") == expected
      assert attr(response, "#new-movement-empty", "href") == expected
    end

    test "shows an empty state when the period has no movements", %{
      conn: conn,
      payment_method: payment_method
    } do
      conn = get(conn, ~p"/payment_method/#{payment_method}?m=11&y=2026")

      assert conn
             |> html_response(200)
             |> element?("#payment-method-movements-empty")
    end

    test "lists the movements of the requested month", %{
      conn: conn,
      scope: scope,
      payment_method: payment_method
    } do
      inside =
        movement_fixture(scope, %{
          payment_method_id: payment_method.id,
          expend_date: ~D[2026-11-10],
          description: "compra de novembro"
        })

      outside =
        movement_fixture(scope, %{
          payment_method_id: payment_method.id,
          expend_date: ~D[2026-10-10],
          description: "compra de outubro"
        })

      conn = get(conn, ~p"/payment_method/#{payment_method}?m=11&y=2026")
      response = html_response(conn, 200)

      assert element?(response, "#payment-method-movement-#{inside.id}")
      refute element?(response, "#payment-method-movement-#{outside.id}")
      refute element?(response, "#payment-method-movements-empty")
      assert response =~ "Novembro"
    end

    test "excludes movements of other payment methods", %{
      conn: conn,
      scope: scope,
      payment_method: payment_method
    } do
      other_payment_method = payment_method_fixture(scope, %{name: "outro método"})

      other_movement =
        movement_fixture(scope, %{
          payment_method_id: other_payment_method.id,
          expend_date: ~D[2026-11-10]
        })

      conn = get(conn, ~p"/payment_method/#{payment_method}?m=11&y=2026")

      refute conn
             |> html_response(200)
             |> element?("#payment-method-movement-#{other_movement.id}")
    end

    test "groups a credit card by its invoice cycle instead of the calendar month", %{
      conn: conn,
      scope: scope
    } do
      card =
        payment_method_fixture(scope, %{
          name: "cartão",
          type: "cartao_credito",
          closing_day: 3,
          due_day: 10
        })

      # A fatura que vence em 10/11/2026 fecha em 03/11 e abre em 04/10.
      in_invoice =
        movement_fixture(scope, %{payment_method_id: card.id, expend_date: ~D[2026-10-20]})

      after_closing =
        movement_fixture(scope, %{payment_method_id: card.id, expend_date: ~D[2026-11-04]})

      before_opening =
        movement_fixture(scope, %{payment_method_id: card.id, expend_date: ~D[2026-10-03]})

      conn = get(conn, ~p"/payment_method/#{card}?m=11&y=2026")
      response = html_response(conn, 200)

      assert element?(response, "#payment-method-movement-#{in_invoice.id}")
      refute element?(response, "#payment-method-movement-#{after_closing.id}")
      refute element?(response, "#payment-method-movement-#{before_opening.id}")
      assert response =~ "Fatura de Novembro de 2026"
      assert response =~ "Total da fatura"
    end

    test "navigates between periods", %{conn: conn, payment_method: payment_method} do
      conn = get(conn, ~p"/payment_method/#{payment_method}?m=1&y=2026")
      response = html_response(conn, 200)

      assert attr(response, "#previous-period", "href") ==
               ~p"/payment_method/#{payment_method}?m=12&y=2025"

      assert attr(response, "#next-period", "href") ==
               ~p"/payment_method/#{payment_method}?m=2&y=2026"
    end

    test "falls back to the current month on invalid period params", %{
      conn: conn,
      payment_method: payment_method
    } do
      today = Date.utc_today()

      conn = get(conn, ~p"/payment_method/#{payment_method}?m=abc&y=0")

      assert html_response(conn, 200) =~
               "#{MyBudgetWeb.Format.month_name(today.month)} de #{today.year}"
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

  defp element?(html, selector) do
    html |> LazyHTML.from_document() |> LazyHTML.query(selector) |> Enum.any?()
  end

  defp attr(html, selector, name) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(name)
    |> List.first()
  end
end
