defmodule MyBudget.Movements.PaymentMethodTest do
  use ExUnit.Case, async: true

  alias MyBudget.Movements.PaymentMethod

  describe "period/3 for credit cards" do
    test "covers the cycle that closes before the due date in the same month" do
      card = %PaymentMethod{type: "cartao_credito", closing_day: 3, due_day: 10}

      assert PaymentMethod.period(card, 2026, 11) == %{
               kind: :invoice,
               start_date: ~D[2026-10-04],
               end_date: ~D[2026-11-03],
               due_date: ~D[2026-11-10]
             }
    end

    test "closes in the previous month when the closing day comes after the due day" do
      card = %PaymentMethod{type: "cartao_credito", closing_day: 20, due_day: 5}

      assert PaymentMethod.period(card, 2026, 11) == %{
               kind: :invoice,
               start_date: ~D[2026-09-21],
               end_date: ~D[2026-10-20],
               due_date: ~D[2026-11-05]
             }
    end

    test "crosses the year boundary" do
      card = %PaymentMethod{type: "cartao_credito", closing_day: 3, due_day: 10}

      assert PaymentMethod.period(card, 2026, 1) == %{
               kind: :invoice,
               start_date: ~D[2025-12-04],
               end_date: ~D[2026-01-03],
               due_date: ~D[2026-01-10]
             }
    end

    test "falls back to the calendar month when the card has no closing/due day" do
      card = %PaymentMethod{type: "cartao_credito", closing_day: nil, due_day: nil}

      assert PaymentMethod.period(card, 2026, 11) == %{
               kind: :month,
               start_date: ~D[2026-11-01],
               end_date: ~D[2026-11-30],
               due_date: nil
             }
    end
  end

  describe "period/3 for other types" do
    test "uses the calendar month" do
      for type <- ~w(conta_corrente conta_investimento cartao_debito) do
        assert PaymentMethod.period(%PaymentMethod{type: type}, 2026, 2) == %{
                 kind: :month,
                 start_date: ~D[2026-02-01],
                 end_date: ~D[2026-02-28],
                 due_date: nil
               }
      end
    end

    test "handles a leap year february" do
      assert PaymentMethod.period(%PaymentMethod{type: "conta_corrente"}, 2028, 2) == %{
               kind: :month,
               start_date: ~D[2028-02-01],
               end_date: ~D[2028-02-29],
               due_date: nil
             }
    end
  end
end
