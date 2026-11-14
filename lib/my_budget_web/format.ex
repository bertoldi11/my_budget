defmodule MyBudgetWeb.Format do
  @moduledoc """
  Formatação compartilhada de valores monetários e datas usada pelas views.
  """

  alias MyBudgetWeb.Cldr

  @month_names %{
    1 => "Janeiro",
    2 => "Fevereiro",
    3 => "Março",
    4 => "Abril",
    5 => "Maio",
    6 => "Junho",
    7 => "Julho",
    8 => "Agosto",
    9 => "Setembro",
    10 => "Outubro",
    11 => "Novembro",
    12 => "Dezembro"
  }

  @doc """
  Formats an amount in cents as BRL currency.
  """
  def amount(cents) do
    {:ok, formatted} = Cldr.Number.to_string(cents / 100, locale: "pt", currency: "BRL")
    formatted
  end

  @doc """
  Formats a date as `dd/mm/yyyy`.
  """
  def date(%Date{} = date), do: Calendar.strftime(date, "%d/%m/%Y")

  @doc """
  Formats a date as `dd/mm`, for compact period ranges.
  """
  def short_date(%Date{} = date), do: Calendar.strftime(date, "%d/%m")

  @doc """
  Month name in Portuguese for a month number.
  """
  def month_name(month), do: Map.get(@month_names, month, "Mês inválido")

  @doc """
  Human label for a movement type.
  """
  def movement_type_label("credit"), do: "Entrada"
  def movement_type_label("debit"), do: "Saída"
  def movement_type_label(other), do: other

  @doc """
  Color class for a movement type: green for income, red for expense.
  """
  def movement_type_class("credit"), do: "text-success font-semibold"
  def movement_type_class("debit"), do: "text-error font-semibold"
  def movement_type_class(_other), do: ""
end
