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

  describe "category accordion" do
    setup :register_and_log_in_user

    setup %{scope: scope} do
      section = section_fixture(scope, %{name: "Moradia"})
      category = category_fixture(scope, %{name: "Aluguel", section_id: section.id})
      other_category = category_fixture(scope, %{name: "Luz", section_id: section.id})

      oldest =
        movement_fixture(scope, %{
          amount: 10_000,
          category_id: category.id,
          description: "Aluguel outubro",
          expend_date: ~D[2026-10-05]
        })

      newest =
        movement_fixture(scope, %{
          amount: 5_000,
          category_id: category.id,
          description: "Taxa de condominio",
          expend_date: ~D[2026-10-25]
        })

      other =
        movement_fixture(scope, %{
          amount: 7_000,
          category_id: other_category.id,
          description: "Conta de luz",
          expend_date: ~D[2026-10-10]
        })

      %{
        category: category,
        other_category: other_category,
        oldest: oldest,
        newest: newest,
        other: other
      }
    end

    test "starts collapsed", %{conn: conn, category: category, newest: newest} do
      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      assert has_element?(view, "#category-toggle-#{category.id}")
      refute has_element?(view, "#category-movements-#{category.id}")
      refute has_element?(view, "#movement-#{newest.id}")
    end

    test "expands only the clicked category", %{
      conn: conn,
      category: category,
      other_category: other_category,
      newest: newest,
      oldest: oldest,
      other: other
    } do
      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      view |> element("#category-toggle-#{category.id}") |> render_click()

      assert has_element?(view, "#category-movements-#{category.id}")
      assert has_element?(view, "#movement-#{newest.id}")
      assert has_element?(view, "#movement-#{oldest.id}")

      refute has_element?(view, "#category-movements-#{other_category.id}")
      refute has_element?(view, "#movement-#{other.id}")
    end

    test "collapses again when clicked twice", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      view |> element("#category-toggle-#{category.id}") |> render_click()
      assert has_element?(view, "#category-movements-#{category.id}")

      view |> element("#category-toggle-#{category.id}") |> render_click()
      refute has_element?(view, "#category-movements-#{category.id}")
    end

    test "lists movements from the most recent to the oldest", %{
      conn: conn,
      category: category,
      newest: newest,
      oldest: oldest
    } do
      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      html = view |> element("#category-toggle-#{category.id}") |> render_click()

      ids =
        html
        |> LazyHTML.from_fragment()
        |> LazyHTML.query("#category-movements-#{category.id} li[id^='movement-']")
        |> LazyHTML.attribute("id")

      assert ids == ["movement-#{newest.id}", "movement-#{oldest.id}"]
    end

    test "shows the date and amount of each movement", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/?m=10&y=2026")

      view |> element("#category-toggle-#{category.id}") |> render_click()

      html = render(view)
      assert html =~ "25/10/2026"
      assert html =~ "05/10/2026"
      assert html =~ "Taxa de condominio"
      assert html =~ "Aluguel outubro"
    end
  end

  test "redirects if user is not logged in", %{conn: conn} do
    assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/")
    assert path == ~p"/users/log-in"
  end
end
