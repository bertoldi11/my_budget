defmodule MyBudgetWeb.SectionLive.Form do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudget.Movements.Section

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
      </.header>

      <.form for={@form} id="section-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Nome" />
        <footer>
          <.button phx-disable-with="Processando..." variant="primary">Salvar sessão</.button>
          <.button navigate={return_path(@current_scope, @return_to, @section)}>Cancelar</.button>
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
    section = Movements.get_section!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Editar sessão")
    |> assign(:section, section)
    |> assign(:form, to_form(Movements.change_section(socket.assigns.current_scope, section)))
  end

  defp apply_action(socket, :new, _params) do
    section = %Section{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "Nova sessão")
    |> assign(:section, section)
    |> assign(:form, to_form(Movements.change_section(socket.assigns.current_scope, section)))
  end

  @impl true
  def handle_event("validate", %{"section" => section_params}, socket) do
    changeset =
      Movements.change_section(
        socket.assigns.current_scope,
        socket.assigns.section,
        section_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"section" => section_params}, socket) do
    save_section(socket, socket.assigns.live_action, section_params)
  end

  defp save_section(socket, :edit, section_params) do
    case Movements.update_section(
           socket.assigns.current_scope,
           socket.assigns.section,
           section_params
         ) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sessão atualizada com sucesso!")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, section)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_section(socket, :new, section_params) do
    case Movements.create_section(socket.assigns.current_scope, section_params) do
      {:ok, section} ->
        {:noreply,
         socket
         |> put_flash(:info, "Sessão cadastrada com sucesso!")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, section)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _section), do: ~p"/section"
  defp return_path(_scope, "show", section), do: ~p"/section/#{section}"
end
