defmodule MyBudgetWeb.Api.FallbackController do
  @moduledoc """
  Traduz os retornos de erro dos contextos em respostas JSON do `/api`.

  É o par do `MyBudgetWeb.FallbackController`, que faz o mesmo para o HTML
  re-renderizando o formulário — aqui não há formulário para re-renderizar, só o
  corpo de erro que o app mobile lê.
  """

  use MyBudgetWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MyBudgetWeb.Api.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: MyBudgetWeb.ErrorJSON)
    |> render(:"404")
  end
end
