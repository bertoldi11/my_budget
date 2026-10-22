defmodule MyBudget.MovementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MyBudget.Movements` context.
  """

  @doc """
  Generate a section.
  """
  def section_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some section"
      })

    {:ok, section} = MyBudget.Movements.create_section(scope, attrs)
    section
  end

  @doc """
  Generate a category.
  """
  def category_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some category",
        section_id: Map.get_lazy(attrs, :section_id, fn -> section_fixture(scope).id end)
      })

    {:ok, category} = MyBudget.Movements.create_category(scope, attrs)
    category
  end

  @doc """
  Generate a payment_method.
  """
  def payment_method_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name"
      })

    {:ok, payment_method} = MyBudget.Movements.create_payment_method(scope, attrs)
    payment_method
  end

  @doc """
  Generate a movement.
  """
  def movement_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        amount: 4200,
        counter_party: "some counter_party",
        description: "some description",
        type: "debit",
        expend_date: ~D[2026-10-15],
        category_id: Map.get_lazy(attrs, :category_id, fn -> category_fixture(scope).id end),
        payment_method_id:
          Map.get_lazy(attrs, :payment_method_id, fn -> payment_method_fixture(scope).id end)
      })

    {:ok, movement} = MyBudget.Movements.create_movement(scope, attrs)
    movement
  end
end
