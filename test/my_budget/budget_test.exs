defmodule MyBudget.BudgetTest do
  use MyBudget.DataCase

  import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
  import MyBudget.MovementsFixtures

  alias MyBudget.Budget
  alias MyBudget.Movements

  setup do
    scope = user_scope_fixture()
    section = section_fixture(scope, %{name: "Casa", budget_active: true})
    other_section = section_fixture(scope, %{name: "Lazer", budget_active: true})

    category =
      category_fixture(scope, %{name: "Aluguel", section_id: section.id, budget_active: true})

    to_deactivate =
      category_fixture(scope, %{name: "Gás", section_id: section.id, budget_active: true})

    in_other_section =
      category_fixture(scope, %{name: "Cinema", section_id: other_section.id, budget_active: true})

    {:ok, previous} = Budget.get_or_create_monthly_budget(scope, 2026, 10)

    for cat <- [category, to_deactivate, in_other_section] do
      {:ok, _} = Budget.upsert_allocation(scope, previous, cat.id, 10_000)
    end

    %{
      scope: scope,
      previous: previous,
      other_section: other_section,
      category: category,
      to_deactivate: to_deactivate,
      in_other_section: in_other_section
    }
  end

  test "copy from previous month skips deactivated categories and sections", ctx do
    %{scope: scope} = ctx
    {:ok, _} = Movements.update_category(scope, ctx.to_deactivate, %{active: false})
    {:ok, _} = Movements.update_section(scope, ctx.other_section, %{active: false})

    {:ok, budget} = Budget.get_or_create_monthly_budget(scope, 2026, 11)
    assert {:ok, _} = Budget.copy_budget_from_previous_month(scope, budget)

    assert scope |> Budget.list_allocations(budget) |> Enum.map(& &1.category_id) ==
             [ctx.category.id]
  end

  test "new budgets don't list deactivated categories, old budgets keep them", ctx do
    %{scope: scope} = ctx
    {:ok, _} = Movements.update_category(scope, ctx.to_deactivate, %{active: false})
    {:ok, _} = Movements.update_section(scope, ctx.other_section, %{active: false})

    {:ok, budget} = Budget.get_or_create_monthly_budget(scope, 2026, 11)

    assert category_ids(Budget.list_budget_sections(scope, budget)) == [ctx.category.id]

    assert category_ids(Budget.list_budget_active_sections(scope)) == [ctx.category.id]

    assert ctx.previous
           |> then(&Budget.list_budget_sections(scope, &1))
           |> category_ids()
           |> Enum.sort() ==
             Enum.sort([ctx.category.id, ctx.to_deactivate.id, ctx.in_other_section.id])
  end

  test "rollovers flag deactivated categories and never allocate to them", ctx do
    %{scope: scope} = ctx
    {:ok, _} = Movements.update_category(scope, ctx.to_deactivate, %{active: false})

    {:ok, budget} = Budget.get_or_create_monthly_budget(scope, 2026, 11)

    rollovers = Budget.calculate_pending_rollovers(scope, budget)
    assert Enum.find(rollovers, &(&1.category_id == ctx.to_deactivate.id)).deactivated
    refute Enum.find(rollovers, &(&1.category_id == ctx.category.id)).deactivated

    redirects = Enum.map(rollovers, &%{category_id: &1.category_id, surplus: &1.surplus})
    assert {:ok, _} = Budget.apply_rollovers(scope, budget, redirects)

    allocated = scope |> Budget.list_allocations(budget) |> Enum.map(& &1.category_id)
    refute ctx.to_deactivate.id in allocated
    assert ctx.category.id in allocated
  end

  test "deleting a category without movements removes it from every budget", ctx do
    %{scope: scope, previous: previous} = ctx
    {:ok, budget} = Budget.get_or_create_monthly_budget(scope, 2026, 11)
    {:ok, _} = Budget.upsert_allocation(scope, budget, ctx.to_deactivate.id, 5_000)

    # Receita igual ao total alocado: o orçamento fica equilibrado.
    {:ok, _} = Budget.create_income(scope, previous, %{description: "Salário", amount: 30_000})
    assert Repo.reload!(previous).status == "balanced"

    assert {:ok, _} = Movements.delete_category(scope, ctx.to_deactivate)

    for b <- [previous, budget] do
      refute ctx.to_deactivate.id in Enum.map(Budget.list_allocations(scope, b), & &1.category_id)
    end

    assert Enum.map(Budget.list_allocations(scope, previous), & &1.category_id) |> Enum.sort() ==
             Enum.sort([ctx.category.id, ctx.in_other_section.id])

    # Sem a alocação apagada, o total alocado deixa de bater com a receita.
    assert Repo.reload!(previous).status == "draft"
  end

  test "a category with movements can't be deleted and keeps its allocations", ctx do
    %{scope: scope, previous: previous, category: category} = ctx
    movement_fixture(scope, %{category_id: category.id})

    assert {:error, :has_movements} = Movements.delete_category(scope, category)
    assert Movements.get_category!(scope, category.id)
    assert category.id in Enum.map(Budget.list_allocations(scope, previous), & &1.category_id)
  end

  test "a section can only be deleted without categories", ctx do
    %{scope: scope, other_section: other_section, in_other_section: in_other_section} = ctx

    assert {:error, :has_categories} = Movements.delete_section(scope, other_section)

    assert {:ok, _} = Movements.delete_category(scope, in_other_section)
    assert {:ok, _} = Movements.delete_section(scope, other_section)

    assert_raise Ecto.NoResultsError, fn -> Movements.get_section!(scope, other_section.id) end
  end

  defp category_ids(sections),
    do: Enum.flat_map(sections, fn section -> Enum.map(section.categories, & &1.id) end)
end
