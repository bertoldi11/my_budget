defmodule MyBudgetWeb.UserSessionHTML do
  use MyBudgetWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:my_budget, MyBudget.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
