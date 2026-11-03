defmodule MyBudgetWeb.HomeLive do
  use MyBudgetWeb, :live_view

  alias MyBudget.Movements
  alias MyBudget.Movements.Movement
  alias MyBudgetWeb.Cldr

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:form, nil)
     |> assign(:categories_options, [])
     |> assign(:payment_method_options, [])
     |> assign(:type_options, [])}
  end

  def handle_params(params, _uri, socket) do
    {month, year} = get_month_and_year(params)
    {:noreply, load_page(socket, month, year)}
  end

  def handle_event("open_modal", _params, socket) do
    scope = socket.assigns.current_scope
    changeset = Movements.change_movement(scope, %Movement{user_id: scope.user.id})

    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:form, to_form(changeset))
     |> assign_form_options()}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("validate", %{"movement" => params}, socket) do
    scope = socket.assigns.current_scope

    changeset =
      scope
      |> Movements.change_movement(%Movement{user_id: scope.user.id}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"movement" => params}, socket) do
    scope = socket.assigns.current_scope

    case Movements.create_movement(scope, params) do
      {:ok, _movement} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> reload_sections()
         |> put_flash(:info, "Movimentação cadastrada com sucesso!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def bar_width(_amount, total) when total in [0, nil], do: "0%"
  def bar_width(amount, total), do: "#{Float.round(amount / total * 100, 1)}%"

  defp load_page(socket, month, year) do
    scope = socket.assigns.current_scope
    sections = list_movements(scope, month, year)
    grand_total = compute_grand_total(sections)

    socket
    |> assign(:month, month)
    |> assign(:year, year)
    |> assign(:current_date, %{month: month, year: year, month_string: get_month_string(month)})
    |> assign(:next_date, shift_date(month, year, 1))
    |> assign(:previous_date, shift_date(month, year, -1))
    |> assign(:sections, sections)
    |> assign(:grand_total, grand_total)
  end

  defp reload_sections(socket) do
    %{current_scope: scope, month: month, year: year} = socket.assigns
    sections = list_movements(scope, month, year)
    grand_total = compute_grand_total(sections)

    socket
    |> assign(:sections, sections)
    |> assign(:grand_total, grand_total)
  end

  defp assign_form_options(socket) do
    scope = socket.assigns.current_scope

    categories_options =
      scope
      |> Movements.list_category()
      |> Enum.map(&{"#{&1.section.name} / #{&1.name}", &1.id})

    payment_method_options =
      scope
      |> Movements.list_payment_method()
      |> Enum.map(&{&1.name, &1.id})

    socket
    |> assign(:categories_options, categories_options)
    |> assign(:payment_method_options, payment_method_options)
    |> assign(:type_options, [{"Saída", "debit"}, {"Entrada", "credit"}])
  end

  defp list_movements(scope, month, year) do
    scope
    |> Movements.list_moviments_by_month_year(month, year)
    |> Enum.map(&Map.put(&1, :formatted_amount, format_amount(&1.amount)))
    |> group_by_section()
    |> sections_with_metadata()
  end

  defp group_by_section(movements) do
    Enum.group_by(movements, &(&1.session || "Sem seção"))
  end

  defp sections_with_metadata(grouped) do
    grouped
    |> Enum.map(fn {section_name, movs} ->
      total_amount = Enum.reduce(movs, 0, fn mov, acc -> acc + mov.amount end)

      %{
        section_name: section_name,
        count: length(movs),
        total: total_amount,
        total_amount: format_amount(total_amount),
        categories: movs
      }
    end)
    |> Enum.sort_by(& &1.section_name)
  end

  defp compute_grand_total(sections) do
    sections
    |> Enum.map(& &1.total)
    |> Enum.sum()
    |> format_amount()
  end

  defp shift_date(month, year, months) do
    date = year |> Date.new!(month, 1) |> Date.shift(month: months)
    %{month: date.month, year: date.year, month_string: get_month_string(date.month)}
  end

  defp get_month_and_year(%{"m" => month, "y" => year}) do
    {String.to_integer(month), String.to_integer(year)}
  end

  defp get_month_and_year(_) do
    date = Date.utc_today()
    {date.month, date.year}
  end

  defp get_month_string(month) do
    case month do
      1 -> "Janeiro"
      2 -> "Fevereiro"
      3 -> "Março"
      4 -> "Abril"
      5 -> "Maio"
      6 -> "Junho"
      7 -> "Julho"
      8 -> "Agosto"
      9 -> "Setembro"
      10 -> "Outubro"
      11 -> "Novembro"
      12 -> "Dezembro"
      _ -> "Mês inválido"
    end
  end

  defp format_amount(amount) do
    {:ok, formatted} = Cldr.Number.to_string(amount / 100, locale: "pt", currency: "BRL")
    formatted
  end
end
