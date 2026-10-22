defmodule MyBudgetWeb.HomeControllerTest do
  use MyBudgetWeb.ConnCase

  import MyBudget.MovementsFixtures

  describe "GET /" do
    setup :register_and_log_in_user

    setup %{scope: scope} do
      section = section_fixture(scope, %{name: "Moradia"})
      category = category_fixture(scope, %{name: "Aluguel", section_id: section.id})

      movement_fixture(scope, %{amount: 10_000, category_id: category.id})
      movement_fixture(scope, %{amount: 5_000, category_id: category.id})

      :ok
    end

    test "summarizes the movements of the given month by section", %{conn: conn} do
      conn = get(conn, ~p"/?m=10&y=2026")
      response = html_response(conn, 200)

      assert response =~ "Movimentações: Outubro de 2026"
      assert response =~ "Moradia"
      assert response =~ "Aluguel"
      assert response =~ "150,00"
      assert response =~ "/?m=9&amp;y=2026"
      assert response =~ "/?m=11&amp;y=2026"
    end

    test "does not list movements from other months", %{conn: conn} do
      conn = get(conn, ~p"/?m=1&y=2027")
      response = html_response(conn, 200)

      assert response =~ "Movimentações: Janeiro de 2027"
      refute response =~ "Aluguel"
      assert response =~ "/?m=12&amp;y=2026"
    end
  end

  test "redirects if user is not logged in", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log-in"
  end
end
