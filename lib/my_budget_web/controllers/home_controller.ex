defmodule MyBudgetWeb.HomeController do
  use MyBudgetWeb, :controller

  alias MyBudget.Movements
  alias MyBudgetWeb.Cldr

  def index(conn, params) do
    {month, year} = get_month_and_year(params)
    sections = list_movement(conn.assigns.current_scope, month, year)
    grand_total = Enum.sum(Enum.map(sections, & &1.total))

    render(conn, :index,
      page_title: "Movimentações",
      current_date: %{month: month, year: year, month_string: get_month_string(month)},
      next_date: shift_date(month, year, 1),
      previous_date: shift_date(month, year, -1),
      sections: sections,
      grand_total: format_amount(grand_total)
    )
  end

  defp shift_date(month, year, months) do
    date = year |> Date.new!(month, 1) |> Date.shift(month: months)
    %{month: date.month, year: date.year, month_string: get_month_string(date.month)}
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

  defp get_month_and_year(%{"m" => month, "y" => y}) do
    {String.to_integer(month), String.to_integer(y)}
  end

  defp get_month_and_year(_) do
    date = Date.utc_today()
    {date.month, date.year}
  end

  defp list_movement(current_scope, month, year) do
    current_scope
    |> Movements.list_moviments_by_month_year(month, year)
    |> format_data()
    |> sections_with_metadata()
  end

  defp format_data(movements) do
    Enum.map(movements, fn movement ->
      Map.put(movement, :formatted_amount, format_amount(movement.amount))
    end)
  end

  # Agrupa os movimentos pelo nome da seção. Movimentos sem seção definida
  # vão para a chave `"Sem seção"`.
  defp group_by_section(data) do
    Enum.group_by(data, fn entry ->
      entry.session || "Sem seção"
    end)
  end

  # Retorna a lista de seções, ordenada por `section_name`, com o total
  # formatado e as categorias de cada seção.
  defp sections_with_metadata(movements) do
    movements
    |> group_by_section()
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

  defp format_amount(amount) do
    {:ok, formatted_amount} = Cldr.Number.to_string(amount / 100, locale: "pt", currency: "BRL")
    formatted_amount
  end
end
