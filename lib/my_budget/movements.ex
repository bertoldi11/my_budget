defmodule MyBudget.Movements do
  @moduledoc """
  The Movements context.
  """

  import Ecto.Query, warn: false
  alias MyBudget.Repo

  alias MyBudget.Movements.Section
  alias MyBudget.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any section changes.

  The broadcasted messages match the pattern:

    * {:created, %Section{}}
    * {:updated, %Section{}}
    * {:deleted, %Section{}}

  """
  def subscribe_section(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MyBudget.PubSub, "user:#{key}:section")
  end

  defp broadcast_section(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(MyBudget.PubSub, "user:#{key}:section", message)
  end

  @doc """
  Returns the list of section.

  ## Examples

      iex> list_section(scope)
      [%Section{}, ...]

  """
  def list_section(%Scope{} = scope) do
    Repo.all_by(Section, user_id: scope.user.id)
  end

  @doc """
  Gets a single section.

  Raises `Ecto.NoResultsError` if the Section does not exist.

  ## Examples

      iex> get_section!(scope, 123)
      %Section{}

      iex> get_section!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_section!(%Scope{} = scope, id) do
    Repo.get_by!(Section, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a section.

  ## Examples

      iex> create_section(scope, %{field: value})
      {:ok, %Section{}}

      iex> create_section(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_section(%Scope{} = scope, attrs) do
    with {:ok, section = %Section{}} <-
           %Section{}
           |> Section.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_section(scope, {:created, section})
      {:ok, section}
    end
  end

  @doc """
  Updates a section.

  ## Examples

      iex> update_section(scope, section, %{field: new_value})
      {:ok, %Section{}}

      iex> update_section(scope, section, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_section(%Scope{} = scope, %Section{} = section, attrs) do
    true = section.user_id == scope.user.id

    with {:ok, section = %Section{}} <-
           section
           |> Section.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_section(scope, {:updated, section})
      {:ok, section}
    end
  end

  @doc """
  Deletes a section.

  ## Examples

      iex> delete_section(scope, section)
      {:ok, %Section{}}

      iex> delete_section(scope, section)
      {:error, %Ecto.Changeset{}}

  """
  def delete_section(%Scope{} = scope, %Section{} = section) do
    true = section.user_id == scope.user.id

    with {:ok, section = %Section{}} <-
           Repo.delete(section) do
      broadcast_section(scope, {:deleted, section})
      {:ok, section}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking section changes.

  ## Examples

      iex> change_section(scope, section)
      %Ecto.Changeset{data: %Section{}}

  """
  def change_section(%Scope{} = scope, %Section{} = section, attrs \\ %{}) do
    true = section.user_id == scope.user.id

    Section.changeset(section, attrs, scope)
  end

  alias MyBudget.Movements.PaymentMethod
  alias MyBudget.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any payment_method changes.

  The broadcasted messages match the pattern:

    * {:created, %PaymentMethod{}}
    * {:updated, %PaymentMethod{}}
    * {:deleted, %PaymentMethod{}}

  """
  def subscribe_payment_method(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MyBudget.PubSub, "user:#{key}:payment_method")
  end

  defp broadcast_payment_method(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(MyBudget.PubSub, "user:#{key}:payment_method", message)
  end

  @doc """
  Returns the list of payment_method.

  ## Examples

      iex> list_payment_method(scope)
      [%PaymentMethod{}, ...]

  """
  def list_payment_method(%Scope{} = scope) do
    Repo.all_by(PaymentMethod, user_id: scope.user.id)
  end

  @doc """
  Gets a single payment_method.

  Raises `Ecto.NoResultsError` if the Payment method does not exist.

  ## Examples

      iex> get_payment_method!(scope, 123)
      %PaymentMethod{}

      iex> get_payment_method!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_payment_method!(%Scope{} = scope, id) do
    Repo.get_by!(PaymentMethod, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a payment_method.

  ## Examples

      iex> create_payment_method(scope, %{field: value})
      {:ok, %PaymentMethod{}}

      iex> create_payment_method(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment_method(%Scope{} = scope, attrs) do
    with {:ok, payment_method = %PaymentMethod{}} <-
           %PaymentMethod{}
           |> PaymentMethod.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_payment_method(scope, {:created, payment_method})
      {:ok, payment_method}
    end
  end

  @doc """
  Updates a payment_method.

  ## Examples

      iex> update_payment_method(scope, payment_method, %{field: new_value})
      {:ok, %PaymentMethod{}}

      iex> update_payment_method(scope, payment_method, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payment_method(%Scope{} = scope, %PaymentMethod{} = payment_method, attrs) do
    true = payment_method.user_id == scope.user.id

    with {:ok, payment_method = %PaymentMethod{}} <-
           payment_method
           |> PaymentMethod.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_payment_method(scope, {:updated, payment_method})
      {:ok, payment_method}
    end
  end

  @doc """
  Deletes a payment_method.

  ## Examples

      iex> delete_payment_method(scope, payment_method)
      {:ok, %PaymentMethod{}}

      iex> delete_payment_method(scope, payment_method)
      {:error, %Ecto.Changeset{}}

  """
  def delete_payment_method(%Scope{} = scope, %PaymentMethod{} = payment_method) do
    true = payment_method.user_id == scope.user.id

    with {:ok, payment_method = %PaymentMethod{}} <-
           Repo.delete(payment_method) do
      broadcast_payment_method(scope, {:deleted, payment_method})
      {:ok, payment_method}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payment_method changes.

  ## Examples

      iex> change_payment_method(scope, payment_method)
      %Ecto.Changeset{data: %PaymentMethod{}}

  """
  def change_payment_method(%Scope{} = scope, %PaymentMethod{} = payment_method, attrs \\ %{}) do
    true = payment_method.user_id == scope.user.id

    PaymentMethod.changeset(payment_method, attrs, scope)
  end

  alias MyBudget.Movements.Category
  alias MyBudget.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any category changes.

  The broadcasted messages match the pattern:

    * {:created, %Category{}}
    * {:updated, %Category{}}
    * {:deleted, %Category{}}

  """
  def subscribe_category(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MyBudget.PubSub, "user:#{key}:category")
  end

  defp broadcast_category(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(MyBudget.PubSub, "user:#{key}:category", message)
  end

  @doc """
  Returns the list of category.

  ## Examples

      iex> list_category(scope)
      [%Category{}, ...]

  """
  def list_category(%Scope{} = scope) do
    Category
    |> order_by(asc: :section_id)
    |> Repo.all_by(user_id: scope.user.id)
    |> Repo.preload([:section])
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Sub section does not exist.

  ## Examples

      iex> get_category!(scope, 123)
      %Category{}

      iex> get_category!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(%Scope{} = scope, id) do
    Repo.get_by!(Category, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(scope, %{field: value})
      {:ok, %Category{}}

      iex> create_category(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(%Scope{} = scope, attrs) do
    with {:ok, category = %Category{}} <-
           %Category{}
           |> Category.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_category(scope, {:created, category})
      {:ok, category}
    end
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(scope, category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(scope, category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Scope{} = scope, %Category{} = category, attrs) do
    true = category.user_id == scope.user.id

    with {:ok, category = %Category{}} <-
           category
           |> Category.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_category(scope, {:updated, category})
      {:ok, category}
    end
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(scope, category)
      {:ok, %Category{}}

      iex> delete_category(scope, category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Scope{} = scope, %Category{} = category) do
    true = category.user_id == scope.user.id

    with {:ok, category = %Category{}} <-
           Repo.delete(category) do
      broadcast_category(scope, {:deleted, category})
      {:ok, category}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(scope, category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Scope{} = scope, %Category{} = category, attrs \\ %{}) do
    true = category.user_id == scope.user.id

    Category.changeset(category, attrs, scope)
  end

  alias MyBudget.Movements.Movement
  alias MyBudget.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any movement changes.

  The broadcasted messages match the pattern:

    * {:created, %Movement{}}
    * {:updated, %Movement{}}
    * {:deleted, %Movement{}}

  """
  def subscribe_movement(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(MyBudget.PubSub, "user:#{key}:movement")
  end

  defp broadcast_movement(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(MyBudget.PubSub, "user:#{key}:movement", message)
  end

  @doc """
  Returns the list of movement.

  ## Examples

      iex> list_movement(scope)
      [%Movement{}, ...]

  """
  def list_movement(%Scope{} = scope) do
    Movement
    |> Repo.all_by(user_id: scope.user.id)
    |> Repo.preload([:category, :payment_method])
  end

  def list_current_month(%Scope{} = scope) do
    current_date = Date.utc_today()
    start_day_of_month = Date.beginning_of_month(current_date)
    end_day_of_month = Date.end_of_month(current_date)

    query =
      from m in Movement,
        where:
          m.expend_date >= ^start_day_of_month and m.expend_date <= ^end_day_of_month and
            m.user_id == ^scope.user.id

    query
    |> Repo.all()
    |> Repo.preload([:payment_method, category: :section])
  end

  @doc """
  Gets a single movement.

  Raises `Ecto.NoResultsError` if the Movement does not exist.

  ## Examples

      iex> get_movement!(scope, 123)
      %Movement{}

      iex> get_movement!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_movement!(%Scope{} = scope, id) do
    Repo.get_by!(Movement, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a movement.

  ## Examples

      iex> create_movement(scope, %{field: value})
      {:ok, %Movement{}}

      iex> create_movement(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_movement(%Scope{} = scope, attrs) do
    with {:ok, movement = %Movement{}} <-
           %Movement{}
           |> Movement.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_movement(scope, {:created, movement})
      {:ok, movement}
    end
  end

  @doc """
  Updates a movement.

  ## Examples

      iex> update_movement(scope, movement, %{field: new_value})
      {:ok, %Movement{}}

      iex> update_movement(scope, movement, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_movement(%Scope{} = scope, %Movement{} = movement, attrs) do
    true = movement.user_id == scope.user.id

    with {:ok, movement = %Movement{}} <-
           movement
           |> Movement.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_movement(scope, {:updated, movement})
      {:ok, movement}
    end
  end

  @doc """
  Deletes a movement.

  ## Examples

      iex> delete_movement(scope, movement)
      {:ok, %Movement{}}

      iex> delete_movement(scope, movement)
      {:error, %Ecto.Changeset{}}

  """
  def delete_movement(%Scope{} = scope, %Movement{} = movement) do
    true = movement.user_id == scope.user.id

    with {:ok, movement = %Movement{}} <-
           Repo.delete(movement) do
      broadcast_movement(scope, {:deleted, movement})
      {:ok, movement}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking movement changes.

  ## Examples

      iex> change_movement(scope, movement)
      %Ecto.Changeset{data: %Movement{}}

  """
  def change_movement(%Scope{} = scope, %Movement{} = movement, attrs \\ %{}) do
    true = movement.user_id == scope.user.id

    Movement.changeset(movement, attrs, scope)
  end
end
