defmodule MyBudgetWeb.Api.UserSessionController do
  @moduledoc """
  Session endpoints for the mobile app (`my_budget_mobile`).

  Log in exchanges e-mail and password for a bearer token; log out revokes the
  token used in the request.
  """

  use MyBudgetWeb, :controller

  alias MyBudget.Accounts

  # POST /api/users/log-in
  def create(conn, %{"user" => %{"email" => email, "password" => password}})
      when is_binary(email) and is_binary(password) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_api_token(user)

      conn
      |> put_status(:created)
      |> render(:create, token: token, user: user)
    else
      # Deliberately vague: do not disclose whether the e-mail is registered.
      conn
      |> put_status(:unauthorized)
      |> render(:error, message: "E-mail ou senha inválidos")
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: ~s(Envie "user" com "email" e "password".))
  end

  # DELETE /api/users/log-out
  def delete(conn, _params) do
    :ok = Accounts.delete_user_api_token(conn.assigns.api_token)

    send_resp(conn, :no_content, "")
  end
end
