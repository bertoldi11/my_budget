defmodule MyBudgetWeb.HomeLiveTest do
  use MyBudgetWeb.ConnCase

  import Phoenix.LiveViewTest
  import MyBudget.MovementsFixtures

  describe "home page" do
    setup :register_and_log_in_user

    setup %{scope: scope} do
      section = section_fixture(scope, %{name: "Moradia"})
      category = category_fixture(scope, %{name: "Aluguel", section_id: section.id})

      movement_fixture(scope, %{amount: 10_000, category_id: category.id})
      movement_fixture(scope, %{amount: 5_000, category_id: category.id})

      %{section: section, category: category}
    end

    test "summarizes the movements of the given month by section", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      assert has_element?(view, "#new-movement-btn")
      assert render(view) =~ "Outubro de 2026"
      assert render(view) =~ "Moradia"
      assert render(view) =~ "Aluguel"
      assert render(view) =~ "150,00"
      assert render(view) =~ "/?m=9&amp;y=2026"
      assert render(view) =~ "/?m=11&amp;y=2026"
    end

    test "does not list movements from other months", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/?m=1&y=2027")

      assert html =~ "Janeiro de 2027"
      refute html =~ "Aluguel"
      assert html =~ "/?m=12&amp;y=2026"
    end

    test "opens new movement modal on button click", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "#modal-movement-form")

      view |> element("#new-movement-btn") |> render_click()

      assert has_element?(view, "#modal-movement-form")
      assert has_element?(view, "#close-modal-btn")
    end

    test "closes modal when cancel is clicked", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("#new-movement-btn") |> render_click()
      assert has_element?(view, "#modal-movement-form")

      view |> element("#close-modal-btn") |> render_click()
      refute has_element?(view, "#modal-movement-form")
    end

    test "creates a movement and updates the page", %{conn: conn, scope: scope} do
      payment_method = payment_method_fixture(scope)
      section = section_fixture(scope, %{name: "Transporte"})
      category = category_fixture(scope, %{name: "Combustível", section_id: section.id})

      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      view |> element("#new-movement-btn") |> render_click()

      view
      |> form("#modal-movement-form", %{
        "movement" => %{
          "category_id" => category.id,
          "payment_method_id" => payment_method.id,
          "expend_date" => "2026-10-20",
          "type" => "debit",
          "amount_reais" => "50,00",
          "description" => "Gasolina",
          "counter_party" => "Posto"
        }
      })
      |> render_submit()

      refute has_element?(view, "#modal-movement-form")
      assert render(view) =~ "Transporte"
      assert render(view) =~ "Combustível"
    end
  end

  test "redirects if user is not logged in", %{conn: conn} do
    assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/")
    assert path == ~p"/users/log-in"
  end
end
