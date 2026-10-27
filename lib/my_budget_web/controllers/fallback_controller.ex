defmodule MyBudgetWeb.FallbackController do
  use MyBudgetWeb, :controller

  def call(_conn, {conn, {:error, %Ecto.Changeset{} = changeset}}) do
    conn
    |> assign(:form, to_form(changeset))
    |> render_for_action(action_name(conn))
  end

  def call(_conn, {conn, {:error, _reason}}) do
    conn
    |> put_flash(:error, "Não foi possível realizar a operação.")
    |> redirect(to: ~p"/")
  end

  defp render_for_action(conn, :create), do: render(conn, :new)
  defp render_for_action(conn, :update), do: render(conn, :edit)
end
