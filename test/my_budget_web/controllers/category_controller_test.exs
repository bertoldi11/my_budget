defmodule MyBudgetWeb.CategoryControllerTest do
  use MyBudgetWeb.ConnCase

  import MyBudget.MovementsFixtures

  @invalid_attrs %{name: nil, section_id: nil}

  setup :register_and_log_in_user

  setup %{scope: scope} do
    %{section: section_fixture(scope, %{name: "Moradia"})}
  end

  describe "index" do
    test "lists all category grouped by section", %{conn: conn, scope: scope, section: section} do
      category = category_fixture(scope, %{name: "Aluguel", section_id: section.id})
      conn = get(conn, ~p"/category")
      response = html_response(conn, 200)
      assert response =~ "Categorias"
      assert response =~ "Moradia"
      assert response =~ category.name
    end
  end

  describe "new category" do
    test "renders form with section options", %{conn: conn} do
      conn = get(conn, ~p"/category/new")
      response = html_response(conn, 200)
      assert response =~ "Nova Categoria"
      assert response =~ "Moradia"
    end
  end

  describe "create category" do
    test "redirects to index when data is valid", %{conn: conn, section: section} do
      conn = post(conn, ~p"/category", category: %{name: "Luz", section_id: section.id})
      assert redirected_to(conn) == ~p"/category"

      conn = get(conn, ~p"/category")
      assert html_response(conn, 200) =~ "Luz"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/category", category: @invalid_attrs)
      response = html_response(conn, 200)
      assert response =~ "Nova Categoria"
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "show category" do
    setup [:create_category]

    test "displays category", %{conn: conn, category: category} do
      conn = get(conn, ~p"/category/#{category}")
      assert html_response(conn, 200) =~ "Categoria #{category.id}"
    end
  end

  describe "edit category" do
    setup [:create_category]

    test "renders form for editing chosen category", %{conn: conn, category: category} do
      conn = get(conn, ~p"/category/#{category}/edit")
      assert html_response(conn, 200) =~ "Editar Categoria"
    end
  end

  describe "update category" do
    setup [:create_category]

    test "redirects to index when data is valid", %{conn: conn, category: category} do
      conn = put(conn, ~p"/category/#{category}", category: %{name: "some updated name"})
      assert redirected_to(conn) == ~p"/category"

      conn = get(conn, ~p"/category/#{category}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "redirects to show when return_to is show", %{conn: conn, category: category} do
      conn =
        put(conn, ~p"/category/#{category}",
          category: %{name: "some updated name"},
          return_to: "show"
        )

      assert redirected_to(conn) == ~p"/category/#{category}"
    end

    test "renders errors when data is invalid", %{conn: conn, category: category} do
      conn = put(conn, ~p"/category/#{category}", category: @invalid_attrs)
      assert html_response(conn, 200) =~ "Editar Categoria"
    end
  end

  describe "delete category" do
    setup [:create_category]

    test "deletes chosen category", %{conn: conn, category: category} do
      conn = delete(conn, ~p"/category/#{category}")
      assert redirected_to(conn) == ~p"/category"

      assert_error_sent 404, fn ->
        get(conn, ~p"/category/#{category}")
      end
    end
  end

  defp create_category(%{scope: scope, section: section}) do
    %{category: category_fixture(scope, %{section_id: section.id})}
  end
end
