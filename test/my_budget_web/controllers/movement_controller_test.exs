defmodule MyBudgetWeb.MovementControllerTest do
  use MyBudgetWeb.ConnCase

  import MyBudget.MovementsFixtures

  @invalid_attrs %{amount: nil, description: nil, counter_party: nil, type: nil}

  setup :register_and_log_in_user

  setup %{scope: scope} do
    section = section_fixture(scope, %{name: "Moradia"})

    %{
      category: category_fixture(scope, %{name: "Aluguel", section_id: section.id}),
      payment_method: payment_method_fixture(scope, %{name: "Pix"})
    }
  end

  defp create_attrs(%{category: category, payment_method: payment_method}) do
    %{
      amount: 12_345,
      description: "some description",
      counter_party: "some counter_party",
      type: "debit",
      expend_date: "2026-10-15",
      category_id: category.id,
      payment_method_id: payment_method.id
    }
  end

  describe "index" do
    setup [:create_movement]

    test "lists all movement with formatted values", %{conn: conn} do
      conn = get(conn, ~p"/movement")
      response = html_response(conn, 200)
      assert response =~ "Movimentações"
      assert response =~ "Aluguel"
      assert response =~ "Pix"
      assert response =~ "15/10/2026"
      assert response =~ "42,00"
    end
  end

  describe "new movement" do
    test "renders form with options", %{conn: conn} do
      conn = get(conn, ~p"/movement/new")
      response = html_response(conn, 200)
      assert response =~ "Nova Movimentação"
      assert response =~ "Moradia / Aluguel"
      assert response =~ "Pix"
    end
  end

  describe "create movement" do
    test "redirects to index when data is valid", %{conn: conn} = context do
      conn = post(conn, ~p"/movement", movement: create_attrs(context))
      assert redirected_to(conn) == ~p"/movement"

      conn = get(conn, ~p"/movement")
      assert html_response(conn, 200) =~ "some description"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/movement", movement: @invalid_attrs)
      response = html_response(conn, 200)
      assert response =~ "Nova Movimentação"
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "show movement" do
    setup [:create_movement]

    test "displays movement", %{conn: conn, movement: movement} do
      conn = get(conn, ~p"/movement/#{movement}")
      assert html_response(conn, 200) =~ "Movement #{movement.id}"
    end
  end

  describe "edit movement" do
    setup [:create_movement]

    test "renders form for editing chosen movement", %{conn: conn, movement: movement} do
      conn = get(conn, ~p"/movement/#{movement}/edit")
      assert html_response(conn, 200) =~ "Editar Movimentação"
    end
  end

  describe "update movement" do
    setup [:create_movement]

    test "redirects to index when data is valid", %{conn: conn, movement: movement} do
      conn = put(conn, ~p"/movement/#{movement}", movement: %{description: "updated description"})
      assert redirected_to(conn) == ~p"/movement"

      conn = get(conn, ~p"/movement/#{movement}")
      assert html_response(conn, 200) =~ "updated description"
    end

    test "redirects to show when return_to is show", %{conn: conn, movement: movement} do
      conn =
        put(conn, ~p"/movement/#{movement}",
          movement: %{description: "updated description"},
          return_to: "show"
        )

      assert redirected_to(conn) == ~p"/movement/#{movement}"
    end

    test "renders errors when data is invalid", %{conn: conn, movement: movement} do
      conn = put(conn, ~p"/movement/#{movement}", movement: @invalid_attrs)
      assert html_response(conn, 200) =~ "Editar Movimentação"
    end
  end

  describe "delete movement" do
    setup [:create_movement]

    test "deletes chosen movement", %{conn: conn, movement: movement} do
      conn = delete(conn, ~p"/movement/#{movement}")
      assert redirected_to(conn) == ~p"/movement"

      assert_error_sent 404, fn ->
        get(conn, ~p"/movement/#{movement}")
      end
    end
  end

  defp create_movement(%{scope: scope, category: category, payment_method: payment_method}) do
    movement =
      movement_fixture(scope, %{category_id: category.id, payment_method_id: payment_method.id})

    %{movement: movement}
  end
end
