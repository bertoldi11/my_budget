defmodule MyBudgetWeb.SectionController do
  use MyBudgetWeb, :controller

  alias MyBudget.Movements
  alias MyBudget.Movements.Section

  def index(conn, _params) do
    section_collection = Movements.list_section(conn.assigns.current_scope)

    render(conn, :index, page_title: "Sessões", section_collection: section_collection)
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Movements.change_section(scope, %Section{user_id: scope.user.id})

    render(conn, :new, page_title: "Nova sessão", form: to_form(changeset))
  end

  def create(conn, %{"section" => section_params}) do
    case Movements.create_section(conn.assigns.current_scope, section_params) do
      {:ok, _section} ->
        conn
        |> put_flash(:info, "Sessão cadastrada com sucesso!")
        |> redirect(to: ~p"/section")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, page_title: "Nova sessão", form: to_form(changeset))
    end
  end

  def show(conn, %{"id" => id}) do
    section = Movements.get_section!(conn.assigns.current_scope, id)

    render(conn, :show, page_title: "Sessão", section: section)
  end

  def edit(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope
    section = Movements.get_section!(scope, id)

    render(conn, :edit,
      page_title: "Editar sessão",
      section: section,
      return_to: return_to(params["return_to"]),
      form: to_form(Movements.change_section(scope, section))
    )
  end

  def update(conn, %{"id" => id, "section" => section_params} = params) do
    scope = conn.assigns.current_scope
    section = Movements.get_section!(scope, id)
    return_to = return_to(params["return_to"])

    case Movements.update_section(scope, section, section_params) do
      {:ok, section} ->
        conn
        |> put_flash(:info, "Sessão atualizada com sucesso!")
        |> redirect(to: return_path(return_to, section))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          page_title: "Editar sessão",
          section: section,
          return_to: return_to,
          form: to_form(changeset)
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    section = Movements.get_section!(scope, id)
    {:ok, _section} = Movements.delete_section(scope, section)

    conn
    |> put_flash(:info, "Sessão apagada com sucesso!")
    |> redirect(to: ~p"/section")
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path("index", _section), do: ~p"/section"
  defp return_path("show", section), do: ~p"/section/#{section}"
end
