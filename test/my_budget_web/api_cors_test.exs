defmodule MyBudgetWeb.ApiCorsTest do
  # Mexe em configuração da aplicação, que é global: não pode rodar em paralelo.
  use MyBudgetWeb.ConnCase, async: false

  @origin "https://app.meubudget.com"

  setup do
    previous = Application.fetch_env(:my_budget, :cors_origins)
    Application.put_env(:my_budget, :cors_origins, [@origin])

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:my_budget, :cors_origins, value)
        :error -> Application.delete_env(:my_budget, :cors_origins)
      end
    end)

    :ok
  end

  defp from_origin(conn, origin) do
    conn
    |> put_req_header("origin", origin)
    |> put_req_header("accept", "application/json")
  end

  describe "preflight" do
    test "libera a origem configurada sem exigir token", %{conn: conn} do
      conn =
        conn
        |> from_origin(@origin)
        |> put_req_header("access-control-request-method", "POST")
        |> put_req_header("access-control-request-headers", "authorization, content-type")
        |> options(~p"/api/movement")

      assert response(conn, 204)
      assert get_resp_header(conn, "access-control-allow-origin") == [@origin]

      assert get_resp_header(conn, "access-control-allow-methods") == [
               "GET, POST, PUT, PATCH, DELETE, OPTIONS"
             ]

      assert get_resp_header(conn, "access-control-allow-headers") == [
               "authorization, content-type, accept"
             ]

      assert get_resp_header(conn, "access-control-max-age") == ["600"]
      assert get_resp_header(conn, "vary") == ["origin"]
    end

    test "não libera uma origem de fora da lista", %{conn: conn} do
      conn =
        conn
        |> from_origin("https://site-aleatorio.com")
        |> put_req_header("access-control-request-method", "POST")
        |> options(~p"/api/movement")

      # Responde, mas sem o cabeçalho de liberação: o navegador recusa a chamada.
      assert response(conn, 204)
      assert get_resp_header(conn, "access-control-allow-origin") == []
      assert get_resp_header(conn, "access-control-allow-methods") == []
      assert get_resp_header(conn, "vary") == ["origin"]
    end

    test "não vaza credenciais implícitas", %{conn: conn} do
      conn =
        conn
        |> from_origin(@origin)
        |> put_req_header("access-control-request-method", "GET")
        |> options(~p"/api/users/me")

      assert get_resp_header(conn, "access-control-allow-credentials") == []
    end
  end

  describe "respostas da API" do
    test "carregam o allow-origin quando a origem é liberada", %{conn: conn} do
      conn = conn |> from_origin(@origin) |> get(~p"/api/users/me")

      # Sem token, a resposta é 401 — e ainda assim o navegador precisa poder
      # lê-la para o app mostrar o erro.
      assert json_response(conn, 401)
      assert get_resp_header(conn, "access-control-allow-origin") == [@origin]
      assert get_resp_header(conn, "vary") == ["origin"]
    end

    test "não carregam allow-origin para origem não liberada", %{conn: conn} do
      conn = conn |> from_origin("https://site-aleatorio.com") |> get(~p"/api/users/me")

      assert json_response(conn, 401)
      assert get_resp_header(conn, "access-control-allow-origin") == []
    end

    test "seguem intactas quando não há cabeçalho origin", %{conn: conn} do
      conn = conn |> put_req_header("accept", "application/json") |> get(~p"/api/users/me")

      assert json_response(conn, 401)
      assert get_resp_header(conn, "access-control-allow-origin") == []
      assert get_resp_header(conn, "vary") == []
    end

    test "o login responde com allow-origin", %{conn: conn} do
      conn =
        conn
        |> from_origin(@origin)
        |> post(~p"/api/users/log-in", %{"user" => %{"email" => "a@b.c", "password" => "errada"}})

      assert json_response(conn, 401)
      assert get_resp_header(conn, "access-control-allow-origin") == [@origin]
    end
  end

  describe "fora do /api" do
    test "o app web em LiveView não recebe cabeçalhos de CORS", %{conn: conn} do
      conn = conn |> put_req_header("origin", @origin) |> get(~p"/users/log-in")

      assert html_response(conn, 200)
      assert get_resp_header(conn, "access-control-allow-origin") == []
      assert get_resp_header(conn, "vary") == []
    end
  end

  describe "configuração :all" do
    test "ecoa qualquer origem", %{conn: conn} do
      Application.put_env(:my_budget, :cors_origins, :all)

      conn = conn |> from_origin("http://localhost:8081") |> get(~p"/api/users/me")

      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:8081"]
    end
  end

  describe "allowed_origin?/1" do
    test "compara a origem exata, sem casar por prefixo" do
      assert MyBudgetWeb.ApiCors.allowed_origin?(@origin)
      refute MyBudgetWeb.ApiCors.allowed_origin?(@origin <> ".invasor.com")
      refute MyBudgetWeb.ApiCors.allowed_origin?("http://app.meubudget.com")
    end
  end
end
