defmodule MyBudgetWeb.Api.UserSessionJSON do
  alias MyBudgetWeb.Api.UserJSON

  @doc "Renders a freshly created API token along with its user."
  def create(%{token: token, user: user}) do
    %{data: %{token: token, user: UserJSON.data(user)}}
  end

  def error(%{message: message}) do
    %{errors: %{detail: message}}
  end
end
