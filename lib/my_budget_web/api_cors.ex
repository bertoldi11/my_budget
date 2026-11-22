defmodule MyBudgetWeb.ApiCors do
  @moduledoc """
  CORS para as rotas `/api`, consumidas pelo app `my_budget_mobile`.

  Só o build **web** do app precisa disto: CORS é política de navegador, então
  as versões iOS e Android não passam por aqui. O app web é servido de outro
  domínio, e sem estes cabeçalhos o navegador bloqueia as chamadas à API.

  Está montado no endpoint, antes do router, e não num pipeline: a requisição
  de preflight do navegador é um `OPTIONS` que nenhuma rota do router casa, e
  pipelines só rodam para rotas que casam. Age apenas em `/api` — o app em
  LiveView é servido do mesmo domínio e não precisa de CORS.

  Não emite `access-control-allow-credentials`: a API autentica por
  `Authorization: Bearer` (ver `MyBudgetWeb.UserAuth.fetch_api_user/2`), não por
  cookie de sessão, logo nenhuma credencial implícita atravessa a origem.

  As origens liberadas vêm de `config :my_budget, :cors_origins`, lidas a cada
  requisição: em produção o `config/runtime.exs` preenche a partir da variável
  de ambiente `CORS_ORIGINS`. O padrão é não liberar nenhuma.
  """

  @behaviour Plug

  import Plug.Conn

  # O app envia `Authorization` e `Content-Type`, e aceita JSON.
  @allow_headers "authorization, content-type, accept"
  @allow_methods "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  # 10 minutos: o navegador reaproveita o preflight em vez de repeti-lo a cada
  # chamada.
  @max_age "600"

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{path_info: ["api" | _]} = conn, _opts) do
    case get_req_header(conn, "origin") do
      [origin] -> cross_origin(conn, origin)
      # Sem `origin` não é uma chamada de origem cruzada de navegador: segue
      # como qualquer outra requisição.
      _ -> conn
    end
  end

  @impl Plug
  def call(conn, _opts), do: conn

  defp cross_origin(conn, origin) do
    allowed? = allowed_origin?(origin)

    conn =
      conn
      # A resposta depende da origem que pediu, então sem `vary` um cache
      # compartilhado poderia servir a resposta de uma origem para outra.
      |> put_resp_header("vary", "origin")
      |> allow_origin(origin, allowed?)

    if conn.method == "OPTIONS" do
      # Preflight: responde aqui e não deixa chegar ao router. Sem os
      # cabeçalhos de liberação, o navegador recusa a chamada que viria depois.
      conn
      |> preflight_headers(allowed?)
      |> send_resp(:no_content, "")
      |> halt()
    else
      conn
    end
  end

  defp allow_origin(conn, _origin, false), do: conn

  defp allow_origin(conn, origin, true),
    do: put_resp_header(conn, "access-control-allow-origin", origin)

  defp preflight_headers(conn, false), do: conn

  defp preflight_headers(conn, true) do
    conn
    |> put_resp_header("access-control-allow-headers", @allow_headers)
    |> put_resp_header("access-control-allow-methods", @allow_methods)
    |> put_resp_header("access-control-max-age", @max_age)
  end

  @doc """
  Diz se a origem está liberada por `config :my_budget, :cors_origins`.

  O valor é uma lista de origens exatas (`["https://app.exemplo.com"]`) ou
  `:all`, que ecoa qualquer origem — usado só em desenvolvimento, onde o
  endereço do servidor do Expo varia entre máquina, emulador e aparelho.
  """
  def allowed_origin?(origin) when is_binary(origin) do
    case Application.get_env(:my_budget, :cors_origins, []) do
      :all -> true
      origins when is_list(origins) -> origin in origins
    end
  end
end
