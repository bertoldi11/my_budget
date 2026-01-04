defmodule MyBudgetWeb.SubCategoryLiveTest do
  use MyBudgetWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyBudget.MovementsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  defp create_sub_category(%{scope: scope}) do
    sub_category = sub_category_fixture(scope)

    %{sub_category: sub_category}
  end

  describe "Index" do
    setup [:create_sub_category]

    test "lists all sub_category", %{conn: conn, sub_category: sub_category} do
      {:ok, _index_live, html} = live(conn, ~p"/sub_category")

      assert html =~ "Listing Sub category"
      assert html =~ sub_category.name
    end

    test "saves new sub_category", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/sub_category")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Sub category")
               |> render_click()
               |> follow_redirect(conn, ~p"/sub_category/new")

      assert render(form_live) =~ "New Sub category"

      assert form_live
             |> form("#sub_category-form", sub_category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#sub_category-form", sub_category: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/sub_category")

      html = render(index_live)
      assert html =~ "Sub category created successfully"
      assert html =~ "some name"
    end

    test "updates sub_category in listing", %{conn: conn, sub_category: sub_category} do
      {:ok, index_live, _html} = live(conn, ~p"/sub_category")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#sub_category_collection-#{sub_category.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/sub_category/#{sub_category}/edit")

      assert render(form_live) =~ "Edit Sub category"

      assert form_live
             |> form("#sub_category-form", sub_category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#sub_category-form", sub_category: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/sub_category")

      html = render(index_live)
      assert html =~ "Sub category updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes sub_category in listing", %{conn: conn, sub_category: sub_category} do
      {:ok, index_live, _html} = live(conn, ~p"/sub_category")

      assert index_live
             |> element("#sub_category_collection-#{sub_category.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#sub_category-#{sub_category.id}")
    end
  end

  describe "Show" do
    setup [:create_sub_category]

    test "displays sub_category", %{conn: conn, sub_category: sub_category} do
      {:ok, _show_live, html} = live(conn, ~p"/sub_category/#{sub_category}")

      assert html =~ "Show Sub category"
      assert html =~ sub_category.name
    end

    test "updates sub_category and returns to show", %{conn: conn, sub_category: sub_category} do
      {:ok, show_live, _html} = live(conn, ~p"/sub_category/#{sub_category}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/sub_category/#{sub_category}/edit?return_to=show")

      assert render(form_live) =~ "Edit Sub category"

      assert form_live
             |> form("#sub_category-form", sub_category: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#sub_category-form", sub_category: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/sub_category/#{sub_category}")

      html = render(show_live)
      assert html =~ "Sub category updated successfully"
      assert html =~ "some updated name"
    end
  end
end
