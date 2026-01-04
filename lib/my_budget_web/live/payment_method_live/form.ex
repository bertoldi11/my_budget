defmodule MyBudgetWeb.PaymentMethodLive.Form do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudget.Movements.PaymentMethod

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Preencha os dados abaixo para cadastrar um novo método de pagamento.</:subtitle>
      </.header>

      <.form for={@form} id="payment_method-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Nome" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Salvar</.button>
          <.button navigate={return_path(@current_scope, @return_to, @payment_method)}>
            Cancelar
          </.button>
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
    payment_method = Movements.get_payment_method!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Editar Método de Pagamento")
    |> assign(:payment_method, payment_method)
    |> assign(
      :form,
      to_form(Movements.change_payment_method(socket.assigns.current_scope, payment_method))
    )
  end

  defp apply_action(socket, :new, _params) do
    payment_method = %PaymentMethod{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "Novo Método de Pagamento")
    |> assign(:payment_method, payment_method)
    |> assign(
      :form,
      to_form(Movements.change_payment_method(socket.assigns.current_scope, payment_method))
    )
  end

  @impl true
  def handle_event("validate", %{"payment_method" => payment_method_params}, socket) do
    changeset =
      Movements.change_payment_method(
        socket.assigns.current_scope,
        socket.assigns.payment_method,
        payment_method_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"payment_method" => payment_method_params}, socket) do
    save_payment_method(socket, socket.assigns.live_action, payment_method_params)
  end

  defp save_payment_method(socket, :edit, payment_method_params) do
    case Movements.update_payment_method(
           socket.assigns.current_scope,
           socket.assigns.payment_method,
           payment_method_params
         ) do
      {:ok, payment_method} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payment method updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, payment_method)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_payment_method(socket, :new, payment_method_params) do
    case Movements.create_payment_method(socket.assigns.current_scope, payment_method_params) do
      {:ok, payment_method} ->
        {:noreply,
         socket
         |> put_flash(:info, "Payment method created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, payment_method)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _payment_method), do: ~p"/payment_method"
  defp return_path(_scope, "show", payment_method), do: ~p"/payment_method/#{payment_method}"
end
