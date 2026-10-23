defmodule MyBudget.MovementsTest do
  use MyBudget.DataCase

  alias MyBudget.Movements

  describe "category" do
    alias MyBudget.Movements.Category

    import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
    import MyBudget.MovementsFixtures

    @invalid_attrs %{name: nil, section_id: nil}

    test "list_category/1 returns all scoped category" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      category = category_fixture(scope)
      other_category = category_fixture(other_scope)
      assert Enum.map(Movements.list_category(scope), & &1.id) == [category.id]
      assert Enum.map(Movements.list_category(other_scope), & &1.id) == [other_category.id]
    end

    test "get_category!/2 returns the category with given id" do
      scope = user_scope_fixture()
      category = category_fixture(scope)
      other_scope = user_scope_fixture()
      assert Movements.get_category!(scope, category.id) == category

      assert_raise Ecto.NoResultsError, fn ->
        Movements.get_category!(other_scope, category.id)
      end
    end

    test "create_category/2 with valid data creates a category" do
      scope = user_scope_fixture()
      section = section_fixture(scope)
      valid_attrs = %{name: "some name", section_id: section.id}

      assert {:ok, %Category{} = category} = Movements.create_category(scope, valid_attrs)
      assert category.name == "some name"
      assert category.section_id == section.id
      assert category.user_id == scope.user.id
    end

    test "create_category/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Movements.create_category(scope, @invalid_attrs)
    end

    test "update_category/3 with valid data updates the category" do
      scope = user_scope_fixture()
      category = category_fixture(scope)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Category{} = category} =
               Movements.update_category(scope, category, update_attrs)

      assert category.name == "some updated name"
    end

    test "update_category/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      category = category_fixture(scope)

      assert_raise MatchError, fn ->
        Movements.update_category(other_scope, category, %{})
      end
    end

    test "update_category/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      category = category_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Movements.update_category(scope, category, @invalid_attrs)

      assert category == Movements.get_category!(scope, category.id)
    end

    test "delete_category/2 deletes the category" do
      scope = user_scope_fixture()
      category = category_fixture(scope)
      assert {:ok, %Category{}} = Movements.delete_category(scope, category)
      assert_raise Ecto.NoResultsError, fn -> Movements.get_category!(scope, category.id) end
    end

    test "delete_category/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      category = category_fixture(scope)
      assert_raise MatchError, fn -> Movements.delete_category(other_scope, category) end
    end

    test "change_category/2 returns a category changeset" do
      scope = user_scope_fixture()
      category = category_fixture(scope)
      assert %Ecto.Changeset{} = Movements.change_category(scope, category)
    end
  end

  describe "payment_method" do
    alias MyBudget.Movements.PaymentMethod

    import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
    import MyBudget.MovementsFixtures

    @invalid_attrs %{name: nil}

    test "list_payment_method/1 returns all scoped payment_method" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      other_payment_method = payment_method_fixture(other_scope)
      assert Movements.list_payment_method(scope) == [payment_method]
      assert Movements.list_payment_method(other_scope) == [other_payment_method]
    end

    test "get_payment_method!/2 returns the payment_method with given id" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      other_scope = user_scope_fixture()
      assert Movements.get_payment_method!(scope, payment_method.id) == payment_method

      assert_raise Ecto.NoResultsError, fn ->
        Movements.get_payment_method!(other_scope, payment_method.id)
      end
    end

    test "create_payment_method/2 with valid data creates a payment_method" do
      valid_attrs = %{name: "some name"}
      scope = user_scope_fixture()

      assert {:ok, %PaymentMethod{} = payment_method} =
               Movements.create_payment_method(scope, valid_attrs)

      assert payment_method.name == "some name"
      assert payment_method.user_id == scope.user.id
    end

    test "create_payment_method/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Movements.create_payment_method(scope, @invalid_attrs)
    end

    test "update_payment_method/3 with valid data updates the payment_method" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %PaymentMethod{} = payment_method} =
               Movements.update_payment_method(scope, payment_method, update_attrs)

      assert payment_method.name == "some updated name"
    end

    test "update_payment_method/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      assert_raise MatchError, fn ->
        Movements.update_payment_method(other_scope, payment_method, %{})
      end
    end

    test "update_payment_method/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Movements.update_payment_method(scope, payment_method, @invalid_attrs)

      assert payment_method == Movements.get_payment_method!(scope, payment_method.id)
    end

    test "delete_payment_method/2 deletes the payment_method" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      assert {:ok, %PaymentMethod{}} = Movements.delete_payment_method(scope, payment_method)

      assert_raise Ecto.NoResultsError, fn ->
        Movements.get_payment_method!(scope, payment_method.id)
      end
    end

    test "delete_payment_method/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      assert_raise MatchError, fn ->
        Movements.delete_payment_method(other_scope, payment_method)
      end
    end

    test "change_payment_method/2 returns a payment_method changeset" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      assert %Ecto.Changeset{} = Movements.change_payment_method(scope, payment_method)
    end
  end

  describe "movement" do
    alias MyBudget.Movements.Movement

    import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
    import MyBudget.MovementsFixtures

    @invalid_attrs %{type: nil, description: nil, amount: nil, counter_party: nil}

    test "list_movement/1 returns all scoped movement" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      movement = movement_fixture(scope)
      other_movement = movement_fixture(other_scope)
      assert Enum.map(Movements.list_movement(scope), & &1.id) == [movement.id]
      assert Enum.map(Movements.list_movement(other_scope), & &1.id) == [other_movement.id]
    end

    test "get_movement!/2 returns the movement with given id" do
      scope = user_scope_fixture()
      movement = movement_fixture(scope)
      other_scope = user_scope_fixture()
      assert Movements.get_movement!(scope, movement.id) == movement

      assert_raise Ecto.NoResultsError, fn ->
        Movements.get_movement!(other_scope, movement.id)
      end
    end

    test "create_movement/2 with valid data creates a movement" do
      scope = user_scope_fixture()

      valid_attrs = %{
        type: "some type",
        description: "some description",
        amount: 42,
        counter_party: "some counter_party",
        expend_date: ~D[2026-10-15],
        category_id: category_fixture(scope).id,
        payment_method_id: payment_method_fixture(scope).id
      }

      assert {:ok, %Movement{} = movement} = Movements.create_movement(scope, valid_attrs)
      assert movement.type == "some type"
      assert movement.description == "some description"
      assert movement.amount == 42
      assert movement.counter_party == "some counter_party"
      assert movement.user_id == scope.user.id
    end

    test "create_movement/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Movements.create_movement(scope, @invalid_attrs)
    end

    test "create_movement/2 converts the amount in reais to cents" do
      scope = user_scope_fixture()

      attrs = %{
        type: "debit",
        description: "some description",
        amount_reais: "1.234,56",
        counter_party: "some counter_party",
        expend_date: ~D[2026-10-15],
        category_id: category_fixture(scope).id,
        payment_method_id: payment_method_fixture(scope).id
      }

      assert {:ok, %Movement{} = movement} = Movements.create_movement(scope, attrs)
      assert movement.amount == 123_456
    end

    test "create_movement/2 with a blank amount returns error on amount_reais" do
      scope = user_scope_fixture()

      attrs = %{
        type: "debit",
        description: "some description",
        amount_reais: "",
        counter_party: "some counter_party",
        expend_date: ~D[2026-10-15],
        category_id: category_fixture(scope).id,
        payment_method_id: payment_method_fixture(scope).id
      }

      assert {:error, changeset} = Movements.create_movement(scope, attrs)
      assert %{amount_reais: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_movement/3 with valid data updates the movement" do
      scope = user_scope_fixture()
      movement = movement_fixture(scope)

      update_attrs = %{
        type: "some updated type",
        description: "some updated description",
        amount: 43,
        counter_party: "some updated counter_party"
      }

      assert {:ok, %Movement{} = movement} =
               Movements.update_movement(scope, movement, update_attrs)

      assert movement.type == "some updated type"
      assert movement.description == "some updated description"
      assert movement.amount == 43
      assert movement.counter_party == "some updated counter_party"
    end

    test "update_movement/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      movement = movement_fixture(scope)

      assert_raise MatchError, fn ->
        Movements.update_movement(other_scope, movement, %{})
      end
    end

    test "update_movement/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      movement = movement_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Movements.update_movement(scope, movement, @invalid_attrs)

      assert movement == Movements.get_movement!(scope, movement.id)
    end

    test "delete_movement/2 deletes the movement" do
      scope = user_scope_fixture()
      movement = movement_fixture(scope)
      assert {:ok, %Movement{}} = Movements.delete_movement(scope, movement)
      assert_raise Ecto.NoResultsError, fn -> Movements.get_movement!(scope, movement.id) end
    end

    test "delete_movement/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      movement = movement_fixture(scope)
      assert_raise MatchError, fn -> Movements.delete_movement(other_scope, movement) end
    end

    test "change_movement/2 returns a movement changeset" do
      scope = user_scope_fixture()
      movement = movement_fixture(scope)
      assert %Ecto.Changeset{} = Movements.change_movement(scope, movement)
    end
  end
end
