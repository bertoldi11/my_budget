defmodule MyBudgetWeb.Api.ChangesetJSON do
  @moduledoc """
  Erros de validação do `/api`, no formato consumido pelo app `my_budget_mobile`:

      %{
        errors: %{
          detail: "Não foi possível salvar...",
          fields: %{"amount_reais" => ["valor inválido"]}
        }
      }

  `detail` é a mensagem genérica — o mesmo campo que os erros 401/404 do Phoenix
  usam (ver `MyBudgetWeb.ErrorJSON`), então qualquer cliente sabe exibi-la sem
  conhecer o resto. `fields` é o extra que permite ao app marcar o erro no campo
  certo do formulário, com as chaves iguais aos nomes dos campos do schema.
  """

  @default_detail "Não foi possível salvar. Verifique os campos informados."

  def error(%{changeset: changeset} = assigns) do
    fields =
      Ecto.Changeset.traverse_errors(changeset, &MyBudgetWeb.CoreComponents.translate_error/1)

    %{errors: %{detail: assigns[:detail] || @default_detail, fields: fields}}
  end
end
