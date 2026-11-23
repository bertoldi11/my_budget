defmodule MyBudgetWeb.Api.UserJSON do
  alias MyBudget.Accounts.User

  def show(%{user: user}) do
    %{data: data(user)}
  end

  @doc "The user representation shared by every API response."
  def data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      confirmed: not is_nil(user.confirmed_at),
      budget_enabled: user.budget_enabled
    }
  end
end
