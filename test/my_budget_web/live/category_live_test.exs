defmodule MyBudgetWeb.CategoryLiveTest do
  use MyBudgetWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyBudget.MovementsFixtures

  @create_attrs %{total_budget: 42, total_expend: 42}
  @update_attrs %{total_budget: 43, total_expend: 43}
  @invalid_attrs %{total_budget: nil, total_expend: nil}

  setup :register_and_log_in_user

  defp create_category(%{scope: scope}) do
    category = category_fixture(scope)

    %{category: category}
  end

  describe "Index" do
    setup [:create_category]

    test "lists all category", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/category")

      assert html =~ "Listing Category"
    end

    test "saves new category", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/category")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Category")
               |> render_click()
               |> follow_redirect(conn, ~p"/category/new")

      assert render(form_live) =~ "New Category"

      assert form_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#category-form", category: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/category")

      html = render(index_live)
      assert html =~ "Category created successfully"
    end

    test "updates category in listing", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, ~p"/category")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#category_collection-#{category.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/category/#{category}/edit")

      assert render(form_live) =~ "Edit Category"

      assert form_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#category-form", category: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/category")

      html = render(index_live)
      assert html =~ "Category updated successfully"
    end

    test "deletes category in listing", %{conn: conn, category: category} do
      {:ok, index_live, _html} = live(conn, ~p"/category")

      assert index_live
             |> element("#category_collection-#{category.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#category-#{category.id}")
    end
  end

  describe "Show" do
    setup [:create_category]

    test "displays category", %{conn: conn, category: category} do
      {:ok, _show_live, html} = live(conn, ~p"/category/#{category}")

      assert html =~ "Show Category"
    end

    test "updates category and returns to show", %{conn: conn, category: category} do
      {:ok, show_live, _html} = live(conn, ~p"/category/#{category}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/category/#{category}/edit?return_to=show")

      assert render(form_live) =~ "Edit Category"

      assert form_live
             |> form("#category-form", category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#category-form", category: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/category/#{category}")

      html = render(show_live)
      assert html =~ "Category updated successfully"
    end
  end
end
