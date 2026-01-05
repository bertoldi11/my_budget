defmodule MyBudgetWeb.CategoryLive.Form do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudget.Movements.Category

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
      </.header>

      <.form for={@form} id="_category-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:section_id]} type="select" label="Sessão" options={@sections_option} />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Salvar</.button>
          <.button navigate={return_path(@current_scope, @return_to, @category)}>Cancelar</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    category = Movements.get_category!(socket.assigns.current_scope, id)

    sections_option =
      socket.assigns.current_scope
      |> MyBudget.Movements.list_section()
      |> map_to_options()

    socket
    |> assign(:page_title, "Editar  Categoria")
    |> assign(:category, category)
    |> assign(:sections_option, sections_option)
    |> assign(:form, to_form(Movements.change_category(socket.assigns.current_scope, category)))
  end

  defp apply_action(socket, :new, _params) do
    category = %Category{user_id: socket.assigns.current_scope.user.id}

    sections_option =
      socket.assigns.current_scope
      |> MyBudget.Movements.list_section()
      |> map_to_options()

    socket
    |> assign(:page_title, "Nova  Categoria")
    |> assign(:category, category)
    |> assign(:sections_option, sections_option)
    |> assign(:form, to_form(Movements.change_category(socket.assigns.current_scope, category)))
  end

  @impl true
  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset =
      Movements.change_category(
        socket.assigns.current_scope,
        socket.assigns.category,
        category_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.live_action, category_params)
  end

  defp save_category(socket, :edit, category_params) do
    case Movements.update_category(
           socket.assigns.current_scope,
           socket.assigns.category,
           category_params
         ) do
      {:ok, category} ->
        {:noreply,
         socket
         |> put_flash(:info, " category updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, category)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category(socket, :new, category_params) do
    case Movements.create_category(socket.assigns.current_scope, category_params) do
      {:ok, category} ->
        {:noreply,
         socket
         |> put_flash(:info, " category created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, category)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _category), do: ~p"/category"
  defp return_path(_scope, "show", category), do: ~p"/category/#{category}"

  defp map_to_options(data) do
    Enum.map(data, &{&1.name, &1.id})
  end
end
