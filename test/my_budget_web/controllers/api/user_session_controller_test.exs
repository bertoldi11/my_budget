defmodule MyBudgetWeb.Api.UserSessionControllerTest do
  use MyBudgetWeb.ConnCase, async: true

  import MyBudget.AccountsFixtures

  alias MyBudget.Accounts
  alias MyBudget.AccountsFixtures

  setup %{conn: conn} do
    %{conn: put_req_header(conn, "accept", "application/json"), user: user_fixture()}
  end

  defp valid_password, do: AccountsFixtures.valid_user_attributes().password

  describe "POST /api/users/log-in" do
    test "returns a token and the user for valid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_password()}
        })

      assert %{"data" => %{"token" => token, "user" => rendered_user}} = json_response(conn, 201)
      assert is_binary(token)
      assert rendered_user["id"] == user.id
      assert rendered_user["email"] == user.email
      assert rendered_user["confirmed"] == true

      # the token works and belongs to this user
      assert %{id: id} = Accounts.get_user_by_api_token(token)
      assert id == user.id
    end

    test "does not leak the password hash", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_password()}
        })

      refute conn.resp_body =~ "hashed_password"
      refute conn.resp_body =~ user.hashed_password
    end

    test "returns 401 for a wrong password", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{"email" => user.email, "password" => "senha errada"}
        })

      assert json_response(conn, 401) == %{"errors" => %{"detail" => "E-mail ou senha inválidos"}}
    end

    test "returns the same 401 for an unknown e-mail, without disclosing it", %{conn: conn} do
      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{"email" => "ninguem@example.com", "password" => valid_password()}
        })

      assert json_response(conn, 401) == %{"errors" => %{"detail" => "E-mail ou senha inválidos"}}
    end

    test "returns 401 for a user without a password set", %{conn: conn} do
      # register_user/1 always requires a password in this app, so such a record
      # cannot be created through the normal flow; inserted directly to make sure
      # the endpoint answers 401 instead of crashing if one ever shows up.
      user =
        MyBudget.Repo.insert!(%MyBudget.Accounts.User{
          email: unique_user_email(),
          hashed_password: nil
        })

      refute user.hashed_password

      conn =
        post(conn, ~p"/api/users/log-in", %{
          "user" => %{"email" => user.email, "password" => ""}
        })

      assert json_response(conn, 401)
    end

    test "returns 400 when params are missing", %{conn: conn} do
      conn = post(conn, ~p"/api/users/log-in", %{"email" => "sem-wrapper@example.com"})

      assert %{"errors" => %{"detail" => detail}} = json_response(conn, 400)
      assert detail =~ "password"
    end
  end

  describe "GET /api/users/me" do
    test "returns the user behind the bearer token", %{conn: conn, user: user} do
      token = Accounts.generate_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(~p"/api/users/me")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["email"] == user.email
      assert data["budget_enabled"] == user.budget_enabled
    end

    test "returns 401 without a token", %{conn: conn} do
      conn = get(conn, ~p"/api/users/me")
      assert json_response(conn, 401) == %{"errors" => %{"detail" => "Unauthorized"}}
    end

    test "returns 401 for a malformed header", %{conn: conn, user: user} do
      token = Accounts.generate_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", token)
        |> get(~p"/api/users/me")

      assert json_response(conn, 401)
    end

    test "returns 401 for a garbage token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer nao-e-base64-valido!!")
        |> get(~p"/api/users/me")

      assert json_response(conn, 401)
    end

    test "returns 401 for an expired token", %{conn: conn, user: user} do
      token = Accounts.generate_user_api_token(user)
      hashed = :crypto.hash(:sha256, Base.url_decode64!(token, padding: false))
      offset_user_token(hashed, -61, :day)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(~p"/api/users/me")

      assert json_response(conn, 401)
    end

    test "a session token is not accepted as an API token", %{conn: conn, user: user} do
      session_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header(
          "authorization",
          "Bearer " <> Base.url_encode64(session_token, padding: false)
        )
        |> get(~p"/api/users/me")

      assert json_response(conn, 401)
    end
  end

  describe "DELETE /api/users/log-out" do
    test "revokes only the token used in the request", %{conn: conn, user: user} do
      token = Accounts.generate_user_api_token(user)
      other_token = Accounts.generate_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> delete(~p"/api/users/log-out")

      assert response(conn, 204)
      refute Accounts.get_user_by_api_token(token)
      assert Accounts.get_user_by_api_token(other_token)
    end

    test "returns 401 without a token", %{conn: conn} do
      conn = delete(conn, ~p"/api/users/log-out")
      assert json_response(conn, 401)
    end
  end

  describe "token lifecycle" do
    test "changing the password revokes API tokens", %{conn: conn, user: user} do
      token = Accounts.generate_user_api_token(user)
      {:ok, _} = Accounts.update_user_password(user, %{password: "outra senha 123456"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(~p"/api/users/me")

      assert json_response(conn, 401)
    end

    test "the raw token is not stored in the database", %{user: user} do
      token = Accounts.generate_user_api_token(user)
      decoded = Base.url_decode64!(token, padding: false)

      stored = MyBudget.Repo.get_by!(Accounts.UserToken, user_id: user.id, context: "api")

      refute stored.token == decoded
      assert stored.token == :crypto.hash(:sha256, decoded)
    end
  end
end
