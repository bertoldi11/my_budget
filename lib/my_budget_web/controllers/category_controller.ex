defmodule MyBudgetWeb.CategoryController do
  use MyBudgetWeb, :controller

  action_fallback MyBudgetWeb.FallbackController

  alias MyBudget.Accounts.Scope
  alias MyBudget.Budget
  alias MyBudget.Movements
  alias MyBudget.Movements.Category

  def index(conn, _params) do
    sections =
      conn.assigns.current_scope
      |> Movements.list_category()
      |> sections_with_categories()

    render(conn, :index, page_title: "Categorias", sections: sections)
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Movements.change_category(scope, %Category{user_id: scope.user.id})

    render_new(conn, changeset)
  end

  def create(conn, %{"category" => category_params}) do
    scope = conn.assigns.current_scope

    conn =
      conn
      |> assign(:page_title, "Nova Categoria")
      |> assign(:sections_options, sections_options(scope))
      |> assign(:show_budget_toggle, Scope.budget_enabled?(scope))

    with {:ok, category} <- Movements.create_category(scope, category_params) do
      if Scope.budget_enabled?(scope) and category.budget_active do
        redirect(conn, to: ~p"/category/#{category}/budget_confirm")
      else
        conn
        |> put_flash(:info, "Categoria cadastrada com sucesso!")
        |> redirect(to: ~p"/category")
      end
    else
      error -> {conn, error}
    end
  end

  def show(conn, %{"id" => id}) do
    category = Movements.get_category!(conn.assigns.current_scope, id)

    render(conn, :show, page_title: "Categoria", category: category)
  end

  def edit(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope
    category = Movements.get_category!(scope, id)
    changeset = Movements.change_category(scope, category)

    render_edit(conn, category, changeset, return_to(params["return_to"]))
  end

  def update(conn, %{"id" => id, "category" => category_params} = params) do
    scope = conn.assigns.current_scope
    category = Movements.get_category!(scope, id)
    return_to = return_to(params["return_to"])

    conn =
      conn
      |> assign(:page_title, "Editar Categoria")
      |> assign(:category, category)
      |> assign(:return_to, return_to)
      |> assign(:sections_options, sections_options(scope))
      |> assign(:show_budget_toggle, Scope.budget_enabled?(scope))

    with {:ok, updated_category} <- Movements.update_category(scope, category, category_params) do
      conn
      |> put_flash(:info, "Categoria atualizada com sucesso!")
      |> redirect(to: return_path(return_to, updated_category))
    else
      error -> {conn, error}
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    category = Movements.get_category!(scope, id)

    with {:ok, _category} <- Movements.delete_category(scope, category) do
      conn
      |> put_flash(:info, "Categoria apagada com sucesso!")
      |> redirect(to: ~p"/category")
    else
      error -> {conn, error}
    end
  end

  def budget_confirm(conn, %{"id" => id}) do
    category = Movements.get_category!(conn.assigns.current_scope, id)

    render(conn, :budget_confirm, page_title: "Incluir no orçamento?", category: category)
  end

  def budget_activate(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    category = Movements.get_category!(scope, id)
    today = Date.utc_today()

    {:ok, budget} = Budget.get_or_create_monthly_budget(scope, today.year, today.month)
    Budget.upsert_allocation(scope, budget, category.id, 0)

    conn
    |> put_flash(:info, "Categoria adicionada ao orçamento de #{format_month(today)}!")
    |> redirect(to: ~p"/budget/#{today.year}/#{today.month}")
  end

  defp render_new(conn, changeset) do
    scope = conn.assigns.current_scope

    render(conn, :new,
      page_title: "Nova Categoria",
      sections_options: sections_options(scope),
      show_budget_toggle: Scope.budget_enabled?(scope),
      form: to_form(changeset)
    )
  end

  defp render_edit(conn, category, changeset, return_to) do
    scope = conn.assigns.current_scope

    render(conn, :edit,
      page_title: "Editar Categoria",
      category: category,
      return_to: return_to,
      sections_options: sections_options(scope),
      show_budget_toggle: Scope.budget_enabled?(scope),
      form: to_form(changeset)
    )
  end

  defp sections_options(scope) do
    scope
    |> Movements.list_section()
    |> Enum.map(&{&1.name, &1.id})
  end

  defp sections_with_categories(categories) do
    categories
    |> Enum.group_by(& &1.section)
    |> Enum.map(fn {section, categories} -> %{section: section, categories: categories} end)
    |> Enum.sort_by(& &1.section.name)
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path("index", _category), do: ~p"/category"
  defp return_path("show", category), do: ~p"/category/#{category}"

  defp format_month(date) do
    months =
      ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)

    "#{Enum.at(months, date.month - 1)}/#{date.year}"
  end
end
