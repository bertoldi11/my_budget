defmodule MyBudgetWeb.PaymentMethodLiveTest do
  use MyBudgetWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyBudget.MovementsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  defp create_payment_method(%{scope: scope}) do
    payment_method = payment_method_fixture(scope)

    %{payment_method: payment_method}
  end

  describe "Index" do
    setup [:create_payment_method]

    test "lists all payment_method", %{conn: conn, payment_method: payment_method} do
      {:ok, _index_live, html} = live(conn, ~p"/payment_method")

      assert html =~ "Listing Payment method"
      assert html =~ payment_method.name
    end

    test "saves new payment_method", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/payment_method")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Payment method")
               |> render_click()
               |> follow_redirect(conn, ~p"/payment_method/new")

      assert render(form_live) =~ "New Payment method"

      assert form_live
             |> form("#payment_method-form", payment_method: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#payment_method-form", payment_method: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/payment_method")

      html = render(index_live)
      assert html =~ "Payment method created successfully"
      assert html =~ "some name"
    end

    test "updates payment_method in listing", %{conn: conn, payment_method: payment_method} do
      {:ok, index_live, _html} = live(conn, ~p"/payment_method")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#payment_method_collection-#{payment_method.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/payment_method/#{payment_method}/edit")

      assert render(form_live) =~ "Edit Payment method"

      assert form_live
             |> form("#payment_method-form", payment_method: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#payment_method-form", payment_method: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/payment_method")

      html = render(index_live)
      assert html =~ "Payment method updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes payment_method in listing", %{conn: conn, payment_method: payment_method} do
      {:ok, index_live, _html} = live(conn, ~p"/payment_method")

      assert index_live
             |> element("#payment_method_collection-#{payment_method.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#payment_method-#{payment_method.id}")
    end
  end

  describe "Show" do
    setup [:create_payment_method]

    test "displays payment_method", %{conn: conn, payment_method: payment_method} do
      {:ok, _show_live, html} = live(conn, ~p"/payment_method/#{payment_method}")

      assert html =~ "Show Payment method"
      assert html =~ payment_method.name
    end

    test "updates payment_method and returns to show", %{
      conn: conn,
      payment_method: payment_method
    } do
      {:ok, show_live, _html} = live(conn, ~p"/payment_method/#{payment_method}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/payment_method/#{payment_method}/edit?return_to=show")

      assert render(form_live) =~ "Edit Payment method"

      assert form_live
             |> form("#payment_method-form", payment_method: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#payment_method-form", payment_method: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/payment_method/#{payment_method}")

      html = render(show_live)
      assert html =~ "Payment method updated successfully"
      assert html =~ "some updated name"
    end
  end
end
