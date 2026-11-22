defmodule MyBudgetWeb.Api.MovementControllerTest do
  use MyBudgetWeb.ConnCase, async: true

  import MyBudget.AccountsFixtures
  import MyBudget.MovementsFixtures

  alias MyBudget.Accounts
  alias MyBudget.Accounts.Scope
  alias MyBudget.Movements

  setup %{conn: conn} do
    user = user_fixture()
    scope = Scope.for_user(user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer " <> Accounts.generate_user_api_token(user))

    %{conn: conn, user: user, scope: scope}
  end

  defp valid_attrs(scope) do
    %{
      "category_id" => category_fixture(scope).id,
      "payment_method_id" => payment_method_fixture(scope).id,
      "expend_date" => "2026-11-22",
      "type" => "debit",
      "amount_reais" => "1.234,56",
      "installments" => 1,
      "description" => "Mercado",
      "counter_party" => "Supermercado"
    }
  end

  describe "GET /api/movement" do
    test "lists the movements of the page, newest first", %{conn: conn, scope: scope} do
      category = category_fixture(scope, %{name: "Mercado"})
      payment_method = payment_method_fixture(scope, %{name: "Conta"})

      older =
        movement_fixture(scope, %{
          expend_date: ~D[2026-01-10],
          category_id: category.id,
          payment_method_id: payment_method.id
        })

      newer =
        movement_fixture(scope, %{
          expend_date: ~D[2026-03-20],
          amount: 5000,
          description: "Feira",
          counter_party: "Hortifruti",
          type: "credit",
          category_id: category.id,
          payment_method_id: payment_method.id
        })

      conn = get(conn, ~p"/api/movement")

      assert %{"data" => [first, second], "meta" => meta} = json_response(conn, 200)

      assert first["id"] == newer.id
      assert second["id"] == older.id

      assert first["amount"] == 5000
      assert first["description"] == "Feira"
      assert first["counter_party"] == "Hortifruti"
      assert first["type"] == "credit"
      assert first["expend_date"] == "2026-03-20"
      assert first["category"]["name"] == "Mercado"
      assert first["category"]["section"]["name"] == "some section"
      assert first["payment_method"]["name"] == "Conta"

      assert meta == %{
               "page" => 1,
               "per_page" => 25,
               "total_count" => 2,
               "total_pages" => 1
             }
    end

    test "paginates without repeating or skipping movements", %{conn: conn, scope: scope} do
      # Todas na mesma data: sem um desempate estável, a paginação por offset
      # devolveria a mesma movimentação em páginas diferentes.
      ids =
        for _ <- 1..5 do
          movement_fixture(scope, %{expend_date: ~D[2026-05-05]}).id
        end

      page_one = get(conn, ~p"/api/movement?page=1&per_page=2") |> json_response(200)
      page_two = get(conn, ~p"/api/movement?page=2&per_page=2") |> json_response(200)
      page_three = get(conn, ~p"/api/movement?page=3&per_page=2") |> json_response(200)

      paged =
        Enum.flat_map(
          [page_one, page_two, page_three],
          &Enum.map(&1["data"], fn m -> m["id"] end)
        )

      assert length(paged) == 5
      assert Enum.sort(paged) == Enum.sort(ids)

      assert page_one["meta"] == %{
               "page" => 1,
               "per_page" => 2,
               "total_count" => 5,
               "total_pages" => 3
             }
    end

    test "returns an empty page past the end", %{conn: conn, scope: scope} do
      movement_fixture(scope)

      conn = get(conn, ~p"/api/movement?page=9")

      assert %{"data" => [], "meta" => meta} = json_response(conn, 200)
      assert meta["page"] == 9
      assert meta["total_count"] == 1
    end

    test "answers with an empty list when there is nothing yet", %{conn: conn} do
      conn = get(conn, ~p"/api/movement")

      assert %{"data" => [], "meta" => meta} = json_response(conn, 200)
      assert meta["total_count"] == 0
      assert meta["total_pages"] == 0
    end

    test "falls back to the defaults for malformed pagination params", %{conn: conn, scope: scope} do
      movement_fixture(scope)

      conn = get(conn, ~p"/api/movement?page=abc&per_page=-3")

      assert %{"data" => [_movement], "meta" => meta} = json_response(conn, 200)
      assert meta["page"] == 1
      assert meta["per_page"] == 25
    end

    test "caps per_page so a client cannot ask for everything", %{conn: conn} do
      conn = get(conn, ~p"/api/movement?per_page=5000")

      assert json_response(conn, 200)["meta"]["per_page"] == 100
    end

    test "does not list another user's movements", %{conn: conn, scope: scope} do
      mine = movement_fixture(scope)
      other = movement_fixture(Scope.for_user(user_fixture()))

      conn = get(conn, ~p"/api/movement")

      ids = json_response(conn, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [mine.id]
      refute other.id in ids
      assert json_response(conn, 200)["meta"]["total_count"] == 1
    end

    test "returns 401 without a token" do
      conn = build_conn() |> put_req_header("accept", "application/json")

      assert json_response(get(conn, ~p"/api/movement"), 401)
    end
  end

  describe "GET /api/movement/new" do
    test "returns the options of the form selects", %{conn: conn, scope: scope} do
      section = section_fixture(scope, %{name: "Casa"})
      category = category_fixture(scope, %{name: "Mercado", section_id: section.id})
      payment_method = payment_method_fixture(scope, %{name: "Conta", type: "conta_corrente"})

      conn = get(conn, ~p"/api/movement/new")

      assert %{"data" => data} = json_response(conn, 200)

      assert data["categories"] == [
               %{
                 "id" => category.id,
                 "name" => "Mercado",
                 "section" => %{"id" => section.id, "name" => "Casa"}
               }
             ]

      assert data["payment_methods"] == [
               %{"id" => payment_method.id, "name" => "Conta", "type" => "conta_corrente"}
             ]

      assert data["types"] == [
               %{"value" => "debit", "label" => "Saída"},
               %{"value" => "credit", "label" => "Entrada"}
             ]
    end

    test "leaves out deactivated categories and sections", %{conn: conn, scope: scope} do
      active = category_fixture(scope, %{name: "Ativa"})
      inactive = category_fixture(scope, %{name: "Inativa", active: false})

      inactive_section = section_fixture(scope, %{name: "Seção inativa", active: false})
      in_inactive_section = category_fixture(scope, %{section_id: inactive_section.id})

      conn = get(conn, ~p"/api/movement/new")

      ids = json_response(conn, 200)["data"]["categories"] |> Enum.map(& &1["id"])

      assert ids == [active.id]
      refute inactive.id in ids
      refute in_inactive_section.id in ids
    end

    test "does not leak another user's options", %{conn: conn, scope: scope} do
      other_scope = Scope.for_user(user_fixture())
      other_category = category_fixture(other_scope)
      other_payment_method = payment_method_fixture(other_scope)

      mine = category_fixture(scope)

      conn = get(conn, ~p"/api/movement/new")
      data = json_response(conn, 200)["data"]

      assert Enum.map(data["categories"], & &1["id"]) == [mine.id]
      refute other_category.id in Enum.map(data["categories"], & &1["id"])
      refute other_payment_method.id in Enum.map(data["payment_methods"], & &1["id"])
    end

    test "returns 401 without a token", %{scope: _scope} do
      conn = build_conn() |> put_req_header("accept", "application/json")

      assert json_response(get(conn, ~p"/api/movement/new"), 401)
    end
  end

  describe "POST /api/movement" do
    test "creates the movement for the logged in user", %{conn: conn, scope: scope, user: user} do
      attrs = valid_attrs(scope)

      conn = post(conn, ~p"/api/movement", %{"movement" => attrs})

      assert %{"data" => data} = json_response(conn, 201)
      # "1.234,56" em reais vira centavos no servidor, como no formulário do web.
      assert data["amount"] == 123_456
      assert data["description"] == "Mercado"
      assert data["counter_party"] == "Supermercado"
      assert data["type"] == "debit"
      assert data["expend_date"] == "2026-11-22"
      assert data["installments"] == 1
      assert data["category_id"] == attrs["category_id"]
      assert data["payment_method_id"] == attrs["payment_method_id"]

      assert [movement] = Movements.list_movement(scope)
      assert movement.id == data["id"]
      assert movement.user_id == user.id
    end

    test "splits the amount when more than one installment is sent", %{conn: conn, scope: scope} do
      attrs = %{valid_attrs(scope) | "amount_reais" => "100,00", "installments" => 3}

      conn = post(conn, ~p"/api/movement", %{"movement" => attrs})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["installments"] == 3

      amounts = scope |> Movements.list_movement() |> Enum.map(& &1.amount) |> Enum.sort()
      assert amounts == [3333, 3333, 3334]
    end

    test "returns 422 with the errors per field", %{conn: conn, scope: scope} do
      attrs = %{valid_attrs(scope) | "description" => "", "amount_reais" => "abc"}

      conn = post(conn, ~p"/api/movement", %{"movement" => attrs})

      assert %{"errors" => %{"detail" => detail, "fields" => fields}} = json_response(conn, 422)
      assert is_binary(detail)
      assert fields["description"] == ["can't be blank"]
      assert fields["amount_reais"] == ["valor inválido"]
      assert Movements.list_movement(scope) == []
    end

    test "refuses a category from another user", %{conn: conn, scope: scope} do
      other_category = category_fixture(Scope.for_user(user_fixture()))
      attrs = %{valid_attrs(scope) | "category_id" => other_category.id}

      conn = post(conn, ~p"/api/movement", %{"movement" => attrs})

      assert %{"errors" => %{"fields" => fields}} = json_response(conn, 422)
      assert fields["category_id"] == ["categoria desativada"]
      assert Movements.list_movement(scope) == []
    end

    test "ignores a user_id sent by the client", %{conn: conn, scope: scope, user: user} do
      other_user = user_fixture()
      attrs = Map.put(valid_attrs(scope), "user_id", other_user.id)

      conn = post(conn, ~p"/api/movement", %{"movement" => attrs})

      assert json_response(conn, 201)
      assert [movement] = Movements.list_movement(scope)
      assert movement.user_id == user.id
    end

    test "returns 400 without the movement wrapper", %{conn: conn} do
      conn = post(conn, ~p"/api/movement", %{"description" => "sem wrapper"})

      assert %{"errors" => %{"detail" => detail}} = json_response(conn, 400)
      assert detail =~ "movement"
    end

    test "returns 401 without a token", %{scope: scope} do
      attrs = valid_attrs(scope)
      conn = build_conn() |> put_req_header("accept", "application/json")

      assert json_response(post(conn, ~p"/api/movement", %{"movement" => attrs}), 401)
      assert Movements.list_movement(scope) == []
    end
  end
end
