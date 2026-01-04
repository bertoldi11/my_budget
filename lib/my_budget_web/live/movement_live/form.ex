defmodule MyBudgetWeb.MovementLive.Form do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudget.Movements.Movement

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
      </.header>

      <.form for={@form} id="movement-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:category_id]}
          type="select"
          label="Categoria"
          options={@categories_options}
        />
        <.input
          field={@form[:payment_method_id]}
          type="select"
          label="Pago com"
          options={@payment_method_options}
        />
        <.input field={@form[:expend_date]} type="date" label="Date" />
        <.input field={@form[:type]} type="select" label="Tipo" options={@type_options} />
        <.input field={@form[:amount]} type="number" label="Valor" />
        <.input field={@form[:description]} type="text" label="Descrição" />
        <.input field={@form[:counter_party]} type="text" label="Pago a/Recebido de" />
        <footer>
          <.button phx-disable-with="Processando..." variant="primary">Salvar</.button>
          <.button navigate={return_path(@current_scope, @return_to, @movement)}>Cancelar</.button>
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
    movement = Movements.get_movement!(socket.assigns.current_scope, id)

    categories_options =
      socket.assigns.current_scope
      |> MyBudget.Movements.list_category()
      |> map_to_options()

    payment_method_options =
      socket.assigns.current_scope
      |> MyBudget.Movements.list_payment_method()
      |> map_to_options()

    socket
    |> assign(:page_title, "Editar Movimentação")
    |> assign(:movement, movement)
    |> assign(:categories_options, categories_options)
    |> assign(:payment_method_options, payment_method_options)
    |> assign(:type_options, moviment_type_options())
    |> assign(:form, to_form(Movements.change_movement(socket.assigns.current_scope, movement)))
  end

  defp apply_action(socket, :new, _params) do
    movement = %Movement{user_id: socket.assigns.current_scope.user.id}

    categories_options =
      socket.assigns.current_scope
      |> MyBudget.Movements.list_category()
      |> map_to_options()

    payment_method_options =
      socket.assigns.current_scope
      |> MyBudget.Movements.list_payment_method()
      |> map_to_options()

    socket
    |> assign(:page_title, "Nova Movimentação")
    |> assign(:movement, movement)
    |> assign(:categories_options, categories_options)
    |> assign(:payment_method_options, payment_method_options)
    |> assign(:type_options, moviment_type_options())
    |> assign(:form, to_form(Movements.change_movement(socket.assigns.current_scope, movement)))
  end

  @impl true
  def handle_event("validate", %{"movement" => movement_params}, socket) do
    changeset =
      Movements.change_movement(
        socket.assigns.current_scope,
        socket.assigns.movement,
        movement_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"movement" => movement_params}, socket) do
    save_movement(socket, socket.assigns.live_action, movement_params)
  end

  defp save_movement(socket, :edit, movement_params) do
    case Movements.update_movement(
           socket.assigns.current_scope,
           socket.assigns.movement,
           movement_params
         ) do
      {:ok, movement} ->
        {:noreply,
         socket
         |> put_flash(:info, "Movement updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, movement)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_movement(socket, :new, movement_params) do
    case Movements.create_movement(socket.assigns.current_scope, movement_params) do
      {:ok, movement} ->
        {:noreply,
         socket
         |> put_flash(:info, "Movement created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, movement)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _movement), do: ~p"/movement"
  defp return_path(_scope, "show", movement), do: ~p"/movement/#{movement}"

  defp map_to_options(data) do
    Enum.map(data, &{&1.name, &1.id})
  end

  defp moviment_type_options do
    [
      {
        "Saída",
        "debit"
      },
      {
        "Entrada",
        "credit"
      }
    ]
  end
end
