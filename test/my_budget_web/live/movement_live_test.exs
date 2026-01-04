defmodule MyBudgetWeb.MovementLiveTest do
  use MyBudgetWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyBudget.MovementsFixtures

  @create_attrs %{
    type: "some type",
    description: "some description",
    amount: 42,
    counter_party: "some counter_party"
  }
  @update_attrs %{
    type: "some updated type",
    description: "some updated description",
    amount: 43,
    counter_party: "some updated counter_party"
  }
  @invalid_attrs %{type: nil, description: nil, amount: nil, counter_party: nil}

  setup :register_and_log_in_user

  defp create_movement(%{scope: scope}) do
    movement = movement_fixture(scope)

    %{movement: movement}
  end

  describe "Index" do
    setup [:create_movement]

    test "lists all movement", %{conn: conn, movement: movement} do
      {:ok, _index_live, html} = live(conn, ~p"/movement")

      assert html =~ "Listing Movement"
      assert html =~ movement.description
    end

    test "saves new movement", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/movement")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Movement")
               |> render_click()
               |> follow_redirect(conn, ~p"/movement/new")

      assert render(form_live) =~ "New Movement"

      assert form_live
             |> form("#movement-form", movement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#movement-form", movement: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/movement")

      html = render(index_live)
      assert html =~ "Movement created successfully"
      assert html =~ "some description"
    end

    test "updates movement in listing", %{conn: conn, movement: movement} do
      {:ok, index_live, _html} = live(conn, ~p"/movement")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#movement_collection-#{movement.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/movement/#{movement}/edit")

      assert render(form_live) =~ "Edit Movement"

      assert form_live
             |> form("#movement-form", movement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#movement-form", movement: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/movement")

      html = render(index_live)
      assert html =~ "Movement updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes movement in listing", %{conn: conn, movement: movement} do
      {:ok, index_live, _html} = live(conn, ~p"/movement")

      assert index_live
             |> element("#movement_collection-#{movement.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#movement-#{movement.id}")
    end
  end

  describe "Show" do
    setup [:create_movement]

    test "displays movement", %{conn: conn, movement: movement} do
      {:ok, _show_live, html} = live(conn, ~p"/movement/#{movement}")

      assert html =~ "Show Movement"
      assert html =~ movement.description
    end

    test "updates movement and returns to show", %{conn: conn, movement: movement} do
      {:ok, show_live, _html} = live(conn, ~p"/movement/#{movement}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/movement/#{movement}/edit?return_to=show")

      assert render(form_live) =~ "Edit Movement"

      assert form_live
             |> form("#movement-form", movement: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#movement-form", movement: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/movement/#{movement}")

      html = render(show_live)
      assert html =~ "Movement updated successfully"
      assert html =~ "some updated description"
    end
  end
end
