defmodule MyBudgetWeb.Api.MovementJSON do
  alias MyBudget.Movements.Category
  alias MyBudget.Movements.Movement
  alias MyBudget.Movements.PaymentMethod

  @doc """
  Opções dos selects do formulário de nova movimentação.

  As categorias já vêm com a seção porque o app monta o rótulo
  "Seção / Categoria", como no web.
  """
  def new(%{categories: categories, payment_methods: payment_methods, types: types}) do
    %{
      data: %{
        categories: Enum.map(categories, &category/1),
        payment_methods: Enum.map(payment_methods, &payment_method/1),
        types: Enum.map(types, fn {label, value} -> %{value: value, label: label} end)
      }
    }
  end

  @doc """
  Uma página de movimentações, com os dados de paginação em `meta`.

  Cada item traz categoria e método de pagamento aninhados: a lista mostra os
  nomes, e sem eles o app teria de cruzar com as opções do formulário.
  """
  def index(%{
        movements: movements,
        page: page,
        per_page: per_page,
        total_count: total_count
      }) do
    %{
      data: Enum.map(movements, &list_item/1),
      meta: %{
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages(total_count, per_page)
      }
    }
  end

  def show(%{movement: movement}) do
    %{data: data(movement)}
  end

  def error(%{message: message}) do
    %{errors: %{detail: message}}
  end

  @doc """
  A movimentação como o app a recebe.

  Sem as associações aninhadas: o app acabou de escolher categoria e método de
  pagamento, então os ids bastam e a resposta não precisa de preload.
  """
  def data(%Movement{} = movement) do
    %{
      id: movement.id,
      amount: movement.amount,
      description: movement.description,
      counter_party: movement.counter_party,
      type: movement.type,
      expend_date: Date.to_iso8601(movement.expend_date),
      # Quantas movimentações o cadastro gerou (1 quando não é parcelado).
      installments: movement.installments || 1,
      category_id: movement.category_id,
      payment_method_id: movement.payment_method_id
    }
  end

  # A movimentação como a listagem a mostra. Sem `installments`: ele é virtual e
  # só tem sentido na resposta do cadastro, onde diz quantas parcelas foram
  # criadas; num registro lido do banco seria sempre 1.
  defp list_item(%Movement{} = movement) do
    %{
      id: movement.id,
      amount: movement.amount,
      description: movement.description,
      counter_party: movement.counter_party,
      type: movement.type,
      expend_date: Date.to_iso8601(movement.expend_date),
      category: category(movement.category),
      payment_method: payment_method(movement.payment_method)
    }
  end

  defp total_pages(total_count, per_page) when total_count > 0 and per_page > 0 do
    div(total_count + per_page - 1, per_page)
  end

  defp total_pages(_total_count, _per_page), do: 0

  defp category(%Category{} = category) do
    %{
      id: category.id,
      name: category.name,
      section: %{id: category.section.id, name: category.section.name}
    }
  end

  defp payment_method(%PaymentMethod{} = payment_method) do
    %{id: payment_method.id, name: payment_method.name, type: payment_method.type}
  end
end
