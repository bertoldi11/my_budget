defmodule MyBudgetWeb.UserRegistrationController do
  use MyBudgetWeb, :controller

  alias MyBudget.Accounts
  alias MyBudget.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)
    render(conn, :new, form: to_form(changeset, as: "user"))
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        conn
        |> put_flash(
          :info,
          "Um e-mail foi enviado para #{user.email}, acesse-o para confirmar sua conta."
        )
        |> redirect(to: ~p"/users/log-in")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, form: to_form(changeset, as: "user"))
    end
  end
end
