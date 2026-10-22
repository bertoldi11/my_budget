defmodule MyBudgetWeb.CategoryController do
  use MyBudgetWeb, :controller

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
    case Movements.create_category(conn.assigns.current_scope, category_params) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Categoria cadastrada com sucesso!")
        |> redirect(to: ~p"/category")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_new(conn, changeset)
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

    case Movements.update_category(scope, category, category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Categoria atualizada com sucesso!")
        |> redirect(to: return_path(return_to, category))

      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit(conn, category, changeset, return_to)
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    category = Movements.get_category!(scope, id)
    {:ok, _category} = Movements.delete_category(scope, category)

    conn
    |> put_flash(:info, "Categoria apagada com sucesso!")
    |> redirect(to: ~p"/category")
  end

  defp render_new(conn, changeset) do
    render(conn, :new,
      page_title: "Nova Categoria",
      sections_options: sections_options(conn.assigns.current_scope),
      form: to_form(changeset)
    )
  end

  defp render_edit(conn, category, changeset, return_to) do
    render(conn, :edit,
      page_title: "Editar Categoria",
      category: category,
      return_to: return_to,
      sections_options: sections_options(conn.assigns.current_scope),
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
end
