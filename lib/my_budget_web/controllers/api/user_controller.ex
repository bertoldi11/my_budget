defmodule MyBudgetWeb.Api.UserController do
  @moduledoc """
  Exposes the user behind the bearer token, so the mobile app can validate a
  stored token on start up and show who is logged in.
  """

  use MyBudgetWeb, :controller

  # GET /api/users/me
  def show(conn, _params) do
    render(conn, :show, user: conn.assigns.current_scope.user)
  end
end
