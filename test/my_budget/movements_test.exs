defmodule MyBudget.MovementsTest do
  use MyBudget.DataCase

  alias MyBudget.Movements

  describe "category" do
    alias MyBudget.Movements.Category

    import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
    import MyBudget.MovementsFixtures

    @invalid_attrs %{total_budget: nil, total_expend: nil}

    test "list_category/1 returns all scoped category" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      category = category_fixture(scope)
      other_category = category_fixture(other_scope)
      assert Movements.list_category(scope) == [category]
      assert Movements.list_category(other_scope) == [other_category]
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
      valid_attrs = %{total_budget: 42, total_expend: 42}
      scope = user_scope_fixture()

      assert {:ok, %Category{} = category} = Movements.create_category(scope, valid_attrs)
      assert category.total_budget == 42
      assert category.total_expend == 42
      assert category.user_id == scope.user.id
    end

    test "create_category/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Movements.create_category(scope, @invalid_attrs)
    end

    test "update_category/3 with valid data updates the category" do
      scope = user_scope_fixture()
      category = category_fixture(scope)
      update_attrs = %{total_budget: 43, total_expend: 43}

      assert {:ok, %Category{} = category} =
               Movements.update_category(scope, category, update_attrs)

      assert category.total_budget == 43
      assert category.total_expend == 43
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

  describe "sub_category" do
    alias MyBudget.Movements.SubCategory

    import MyBudget.AccountsFixtures, only: [user_scope_fixture: 0]
    import MyBudget.MovementsFixtures

    @invalid_attrs %{name: nil}

    test "list_sub_category/1 returns all scoped sub_category" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)
      other_sub_category = sub_category_fixture(other_scope)
      assert Movements.list_sub_category(scope) == [sub_category]
      assert Movements.list_sub_category(other_scope) == [other_sub_category]
    end

    test "get_sub_category!/2 returns the sub_category with given id" do
      scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)
      other_scope = user_scope_fixture()
      assert Movements.get_sub_category!(scope, sub_category.id) == sub_category

      assert_raise Ecto.NoResultsError, fn ->
        Movements.get_sub_category!(other_scope, sub_category.id)
      end
    end

    test "create_sub_category/2 with valid data creates a sub_category" do
      valid_attrs = %{name: "some name"}
      scope = user_scope_fixture()

      assert {:ok, %SubCategory{} = sub_category} =
               Movements.create_sub_category(scope, valid_attrs)

      assert sub_category.name == "some name"
      assert sub_category.user_id == scope.user.id
    end

    test "create_sub_category/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Movements.create_sub_category(scope, @invalid_attrs)
    end

    test "update_sub_category/3 with valid data updates the sub_category" do
      scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %SubCategory{} = sub_category} =
               Movements.update_sub_category(scope, sub_category, update_attrs)

      assert sub_category.name == "some updated name"
    end

    test "update_sub_category/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)

      assert_raise MatchError, fn ->
        Movements.update_sub_category(other_scope, sub_category, %{})
      end
    end

    test "update_sub_category/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Movements.update_sub_category(scope, sub_category, @invalid_attrs)

      assert sub_category == Movements.get_sub_category!(scope, sub_category.id)
    end

    test "delete_sub_category/2 deletes the sub_category" do
      scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)
      assert {:ok, %SubCategory{}} = Movements.delete_sub_category(scope, sub_category)

      assert_raise Ecto.NoResultsError, fn ->
        Movements.get_sub_category!(scope, sub_category.id)
      end
    end

    test "delete_sub_category/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)
      assert_raise MatchError, fn -> Movements.delete_sub_category(other_scope, sub_category) end
    end

    test "change_sub_category/2 returns a sub_category changeset" do
      scope = user_scope_fixture()
      sub_category = sub_category_fixture(scope)
      assert %Ecto.Changeset{} = Movements.change_sub_category(scope, sub_category)
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
      assert Movements.list_movement(scope) == [movement]
      assert Movements.list_movement(other_scope) == [other_movement]
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
      valid_attrs = %{
        type: "some type",
        description: "some description",
        amount: 42,
        counter_party: "some counter_party"
      }

      scope = user_scope_fixture()

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
