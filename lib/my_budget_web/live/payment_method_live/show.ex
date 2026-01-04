defmodule MyBudgetWeb.PaymentMethodLive.Show do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Método de Pagamento: {@payment_method.id}
        <:actions>
          <.button navigate={~p"/payment_method"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/payment_method/#{@payment_method}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Editar
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@payment_method.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_payment_method(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Payment method")
     |> assign(:payment_method, Movements.get_payment_method!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MyBudget.Movements.PaymentMethod{id: id} = payment_method},
        %{assigns: %{payment_method: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :payment_method, payment_method)}
  end

  def handle_info(
        {:deleted, %MyBudget.Movements.PaymentMethod{id: id}},
        %{assigns: %{payment_method: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "O método de pagamento foi apagado.")
     |> push_navigate(to: ~p"/payment_method")}
  end

  def handle_info({type, %MyBudget.Movements.PaymentMethod{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
