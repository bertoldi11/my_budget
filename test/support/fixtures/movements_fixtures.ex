defmodule MyBudget.MovementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MyBudget.Movements` context.
  """

  @doc """
  Generate a category.
  """
  def category_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        total_budget: 42,
        total_expend: 42
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
  Generate a sub_category.
  """
  def sub_category_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name"
      })

    {:ok, sub_category} = MyBudget.Movements.create_sub_category(scope, attrs)
    sub_category
  end

  @doc """
  Generate a movement.
  """
  def movement_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        amount: 42,
        counter_party: "some counter_party",
        description: "some description",
        type: "some type"
      })

    {:ok, movement} = MyBudget.Movements.create_movement(scope, attrs)
    movement
  end
end
