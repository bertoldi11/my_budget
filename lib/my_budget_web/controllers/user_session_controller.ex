defmodule MyBudgetWeb.UserSessionController do
  use MyBudgetWeb, :controller

  alias MyBudget.Accounts
  alias MyBudgetWeb.UserAuth

  def new(conn, _params) do
    email =
      Phoenix.Flash.get(conn.assigns.flash, :email) ||
        get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    render(conn, :new, form: form)
  end

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "Conta confirmada com sucesso!"
        _ -> "Bem-vindo(a) de volta!"
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        conn
        |> put_flash(:error, "O link é inválido ou expirou.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # email + password login
  def create(conn, %{"user" => %{"email" => email, "password" => password} = user_params}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Bem-vindo(a) de volta!")
      |> UserAuth.log_in_user(user, user_params)
    else
      form = to_form(%{"email" => String.slice(email, 0, 160)}, as: "user")

      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "E-mail ou senha inválidos")
      |> render(:new, form: form)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "Se o seu e-mail estiver no nosso sistema, você receberá em instantes as instruções para entrar."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log-in")
  end

  def confirm(conn, %{"token" => token}) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      conn
      |> assign(:user, user)
      |> assign(:form, form)
      |> render(:confirm)
    else
      conn
      |> put_flash(:error, "O link mágico é inválido ou expirou.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Sessão encerrada com sucesso.")
    |> UserAuth.log_out_user()
  end
end
