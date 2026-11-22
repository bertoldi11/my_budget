defmodule MyBudgetWeb.SectionController do
  use MyBudgetWeb, :controller

  action_fallback MyBudgetWeb.FallbackController

  alias MyBudget.Accounts.Scope
  alias MyBudget.Budget
  alias MyBudget.Movements
  alias MyBudget.Movements.Section

  def index(conn, _params) do
    scope = conn.assigns.current_scope

    {active_sections, inactive_sections} =
      scope
      |> Movements.list_section()
      |> Enum.sort_by(&String.downcase(&1.name))
      |> Enum.split_with(& &1.active)

    section_ids_with_categories =
      scope |> Movements.list_category() |> MapSet.new(& &1.section_id)

    render(conn, :index,
      page_title: "Sessões",
      active_sections: active_sections,
      inactive_sections: inactive_sections,
      section_ids_with_categories: section_ids_with_categories
    )
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Movements.change_section(scope, %Section{user_id: scope.user.id})

    render(conn, :new,
      page_title: "Nova sessão",
      form: to_form(changeset),
      show_budget_toggle: Scope.budget_enabled?(scope)
    )
  end

  def create(conn, %{"section" => section_params}) do
    scope = conn.assigns.current_scope

    conn =
      conn
      |> assign(:page_title, "Nova sessão")
      |> assign(:show_budget_toggle, Scope.budget_enabled?(scope))

    with {:ok, section} <- Movements.create_section(scope, section_params) do
      if Scope.budget_enabled?(scope) and section.budget_active and section.active do
        redirect(conn, to: ~p"/section/#{section}/budget_confirm")
      else
        conn
        |> put_flash(:info, "Sessão cadastrada com sucesso!")
        |> redirect(to: ~p"/section")
      end
    else
      error -> {conn, error}
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
      form: to_form(Movements.change_section(scope, section)),
      show_budget_toggle: Scope.budget_enabled?(scope)
    )
  end

  def update(conn, %{"id" => id, "section" => section_params} = params) do
    scope = conn.assigns.current_scope
    section = Movements.get_section!(scope, id)
    return_to = return_to(params["return_to"])

    conn =
      conn
      |> assign(:page_title, "Editar sessão")
      |> assign(:section, section)
      |> assign(:return_to, return_to)
      |> assign(:show_budget_toggle, Scope.budget_enabled?(scope))

    with {:ok, updated_section} <- Movements.update_section(scope, section, section_params) do
      conn
      |> put_flash(:info, "Sessão atualizada com sucesso!")
      |> redirect(to: return_path(return_to, updated_section))
    else
      error -> {conn, error}
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    section = Movements.get_section!(scope, id)

    case Movements.delete_section(scope, section) do
      {:ok, _section} ->
        conn
        |> put_flash(:info, "Sessão apagada com sucesso!")
        |> redirect(to: ~p"/section")

      {:error, :has_categories} ->
        conn
        |> put_flash(
          :error,
          "A sessão possui categorias e não pode ser apagada. Desative-a ou apague as categorias antes."
        )
        |> redirect(to: ~p"/section")
    end
  end

  def budget_confirm(conn, %{"id" => id}) do
    section = Movements.get_section!(conn.assigns.current_scope, id)

    render(conn, :budget_confirm, page_title: "Incluir no orçamento?", section: section)
  end

  def budget_activate(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    section = scope |> Movements.get_section!(id) |> MyBudget.Repo.preload(:categories)
    today = Date.utc_today()

    {:ok, budget} = Budget.get_or_create_monthly_budget(scope, today.year, today.month)

    # Uma sessão desativada não entra no orçamento; das ativas, só as
    # categorias ativas.
    section.categories
    |> Enum.filter(&(section.active and &1.active and &1.budget_active))
    |> Enum.each(fn category ->
      Budget.upsert_allocation(scope, budget, category.id, 0)
    end)

    conn
    |> put_flash(:info, "Sessão adicionada ao orçamento de #{format_month(today)}!")
    |> redirect(to: ~p"/budget/#{today.year}/#{today.month}")
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp return_path("index", _section), do: ~p"/section"
  defp return_path("show", section), do: ~p"/section/#{section}"

  defp format_month(date) do
    months =
      ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)

    "#{Enum.at(months, date.month - 1)}/#{date.year}"
  end
end
