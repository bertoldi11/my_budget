defmodule MyBudgetWeb.PaymentMethodLive.Index do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Métodos de Pagamento
        <:actions>
          <.button variant="primary" navigate={~p"/payment_method/new"}>
            <.icon name="hero-plus" /> Novo
          </.button>
        </:actions>
      </.header>

      <.table
        id="payment_method"
        rows={@streams.payment_method_collection}
        row_click={fn {_id, payment_method} -> JS.navigate(~p"/payment_method/#{payment_method}") end}
      >
        <:col :let={{_id, payment_method}} label="Nome">{payment_method.name}</:col>
        <:action :let={{_id, payment_method}}>
          <div class="sr-only">
            <.link navigate={~p"/payment_method/#{payment_method}"}>Detalhes</.link>
          </div>
          <.link navigate={~p"/payment_method/#{payment_method}/edit"}>Editar</.link>
        </:action>
        <:action :let={{id, payment_method}}>
          <.link
            phx-click={JS.push("delete", value: %{id: payment_method.id}) |> hide("##{id}")}
            data-confirm="Tem certeza que quer apagar esse méthodo de pagamento?"
          >
            Apagar
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Movements.subscribe_payment_method(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Payment method")
     |> stream(:payment_method_collection, list_payment_method(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    payment_method = Movements.get_payment_method!(socket.assigns.current_scope, id)
    {:ok, _} = Movements.delete_payment_method(socket.assigns.current_scope, payment_method)

    {:noreply, stream_delete(socket, :payment_method_collection, payment_method)}
  end

  @impl true
  def handle_info({type, %MyBudget.Movements.PaymentMethod{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :payment_method_collection, list_payment_method(socket.assigns.current_scope),
       reset: true
     )}
  end

  defp list_payment_method(current_scope) do
    Movements.list_payment_method(current_scope)
  end
end
