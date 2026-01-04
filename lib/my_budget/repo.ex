defmodule MyBudget.Repo do
  use Ecto.Repo,
    otp_app: :my_budget,
    adapter: Ecto.Adapters.Postgres
end
