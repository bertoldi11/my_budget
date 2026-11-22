defmodule MyBudget.Movements.DeactivationTest do
  use MyBudget.DataCase

  import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
  import MyBudget.MovementsFixtures

  alias MyBudget.Movements

  setup do
    scope = user_scope_fixture()
    section = section_fixture(scope, %{name: "Casa"})
    inactive_section = section_fixture(scope, %{name: "Antiga", active: false})

    %{
      scope: scope,
      active: category_fixture(scope, %{name: "Aluguel", section_id: section.id}),
      inactive: category_fixture(scope, %{name: "Gás", section_id: section.id, active: false}),
      in_inactive_section:
        category_fixture(scope, %{name: "Velha", section_id: inactive_section.id})
    }
  end

  test "sections and categories are active by default", %{scope: scope, active: active} do
    assert active.active
    assert Movements.get_section!(scope, active.section_id).active
  end

  test "list_available_category/1 only returns active categories in active sections",
       %{scope: scope, active: active} do
    assert Enum.map(Movements.list_available_category(scope), & &1.id) == [active.id]
  end

  test "create_movement/2 rejects a deactivated category or one in a deactivated section",
       %{scope: scope, inactive: inactive, in_inactive_section: in_inactive_section} do
    for category <- [inactive, in_inactive_section] do
      attrs = movement_attrs(scope, category)

      assert {:error, changeset} = Movements.create_movement(scope, attrs)
      assert %{category_id: ["categoria desativada"]} = errors_on(changeset)
    end
  end

  test "create_movement/2 rejects a category from another user", %{active: active} do
    other_scope = user_scope_fixture()

    assert {:error, changeset} =
             Movements.create_movement(other_scope, movement_attrs(other_scope, active))

    assert %{category_id: ["categoria desativada"]} = errors_on(changeset)
  end

  test "a movement keeps its category after the category is deactivated",
       %{scope: scope, active: active} do
    movement = movement_fixture(scope, %{category_id: active.id})
    {:ok, _} = Movements.update_category(scope, active, %{active: false})

    assert {:ok, updated} =
             Movements.update_movement(scope, movement, %{description: "outra descrição"})

    assert updated.category_id == active.id
  end

  test "update_movement/3 does not move a movement to a deactivated category",
       %{scope: scope, active: active, inactive: inactive} do
    movement = movement_fixture(scope, %{category_id: active.id})

    assert {:error, changeset} =
             Movements.update_movement(scope, movement, %{category_id: inactive.id})

    assert %{category_id: ["categoria desativada"]} = errors_on(changeset)
  end

  defp movement_attrs(scope, category) do
    %{
      type: "debit",
      description: "Compra",
      amount: 1_000,
      counter_party: "Loja",
      expend_date: ~D[2026-11-14],
      category_id: category.id,
      payment_method_id: payment_method_fixture(scope).id
    }
  end
end
