defmodule MyBudget.Movements do
  @moduledoc """
  The Movements context.
  """

  import Ecto.Query, warn: false
  alias MyBudget.Repo

  alias MyBudget.Movements.Section
  alias MyBudget.Movements.Category
  alias MyBudget.Movements.Movement
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

    if section_has_categories?(scope, section) do
      {:error, :has_categories}
    else
      # A sessão só se liga a orçamentos pelas categorias; sem categorias não há
      # alocações a apagar. A constraint cobre uma categoria criada no meio-tempo.
      result =
        section
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.foreign_key_constraint(:id,
          name: :category_section_id_fkey,
          message: "possui categorias"
        )
        |> Repo.delete()

      case result do
        {:ok, section} ->
          broadcast_section(scope, {:deleted, section})
          {:ok, section}

        {:error, _changeset} ->
          {:error, :has_categories}
      end
    end
  end

  @doc """
  Returns true when the section has at least one category.
  """
  def section_has_categories?(%Scope{} = scope, %Section{} = section) do
    Category
    |> where(user_id: ^scope.user.id, section_id: ^section.id)
    |> Repo.exists?()
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
  Returns the categories that can receive new movements: the category and its
  section must both be active. Ordered by section name and then category name,
  with `:section` preloaded.

  ## Examples

      iex> list_available_category(scope)
      [%Category{active: true, section: %Section{active: true}}, ...]

  """
  def list_available_category(%Scope{} = scope) do
    Category
    |> join(:inner, [c], s in assoc(c, :section))
    |> where([c, s], c.user_id == ^scope.user.id and c.active and s.active)
    |> order_by([c, s], asc: s.name, asc: c.name)
    |> preload([_c, s], section: s)
    |> Repo.all()
  end

  @doc """
  Returns true when the category belongs to the scope and both the category
  and its section are active.
  """
  def category_available?(%Scope{} = scope, category_id) do
    Category
    |> join(:inner, [c], s in assoc(c, :section))
    |> where([c, s], c.id == ^category_id and c.user_id == ^scope.user.id)
    |> where([c, s], c.active and s.active)
    |> Repo.exists?()
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

    if category_has_movements?(scope, category) do
      {:error, :has_movements}
    else
      Repo.transaction(fn ->
        # Remove a categoria dos orçamentos em que ela estava alocada e
        # recalcula o status (equilibrado/rascunho) desses orçamentos.
        MyBudget.Budget.delete_category_allocations(scope, category)

        category
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.foreign_key_constraint(:id,
          name: :movement_category_id_fkey,
          message: "possui movimentações"
        )
        |> Repo.delete()
        |> case do
          {:ok, category} -> category
          {:error, _changeset} -> Repo.rollback(:has_movements)
        end
      end)
      |> case do
        {:ok, category} ->
          broadcast_category(scope, {:deleted, category})
          {:ok, category}

        error ->
          error
      end
    end
  end

  @doc """
  Returns true when the category has at least one movement.
  """
  def category_has_movements?(%Scope{} = scope, %Category{} = category) do
    Movement
    |> where(user_id: ^scope.user.id, category_id: ^category.id)
    |> Repo.exists?()
  end

  @doc """
  Returns the set of category ids of the scope that have movements.
  """
  def category_ids_with_movements(%Scope{} = scope) do
    Movement
    |> where(user_id: ^scope.user.id)
    |> distinct(true)
    |> select([m], m.category_id)
    |> Repo.all()
    |> MapSet.new()
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
    |> order_by([m], desc: m.expend_date)
    |> Repo.all_by(user_id: scope.user.id)
    |> Repo.preload([:category, :payment_method])
  end

  @doc """
  Returns one page of movements, newest first, with `:category` (and its
  `:section`) and `:payment_method` preloaded.

  `page` is 1-based. The order falls back to the id so that movements sharing an
  `expend_date` keep a stable position between pages — without it, a row could
  show up twice or be skipped as the client pages through.

  ## Examples

      iex> list_movement_page(scope, 1, 25)
      [%Movement{}, ...]

  """
  def list_movement_page(%Scope{} = scope, page, per_page)
      when is_integer(page) and page >= 1 and is_integer(per_page) and per_page >= 1 do
    Movement
    |> where([m], m.user_id == ^scope.user.id)
    |> order_by([m], desc: m.expend_date, desc: m.id)
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
    |> Repo.all()
    |> Repo.preload([[category: :section], :payment_method])
  end

  @doc """
  Counts the movements of the scope, for the pagination metadata.

  ## Examples

      iex> count_movement(scope)
      137

  """
  def count_movement(%Scope{} = scope) do
    Movement
    |> where([m], m.user_id == ^scope.user.id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns all movements of the given month/year for the scope, already joined
  with their category and section, ordered by section name, category name and
  then by `expend_date` from the most recent to the oldest.

  Used by the home page to render the section > category > movements accordion.
  """
  def list_movements_details_by_month_year(%Scope{} = scope, month, year) do
    current_date = Date.new!(year, month, 1)
    start_day_of_month = Date.beginning_of_month(current_date)
    end_day_of_month = Date.end_of_month(current_date)

    Movement
    |> join(:inner, [m], c in Category, on: m.category_id == c.id)
    |> join(:inner, [_, c], s in Section, on: c.section_id == s.id)
    |> join(:left, [m, _, _], p in PaymentMethod, on: m.payment_method_id == p.id)
    |> where([m, _, _, _], m.expend_date >= ^start_day_of_month)
    |> where([m, _, _, _], m.expend_date <= ^end_day_of_month)
    |> where([m, _, _, _], m.user_id == ^scope.user.id)
    |> order_by([m, c, s, _], asc: s.name, asc: c.name, desc: m.expend_date, desc: m.id)
    |> select([m, c, s, p], %{
      id: m.id,
      session: s.name,
      category: c.name,
      category_id: c.id,
      amount: m.amount,
      type: m.type,
      description: m.description,
      counter_party: m.counter_party,
      expend_date: m.expend_date,
      payment_method: p.name
    })
    |> Repo.all()
  end

  @doc """
  Returns the movements of a given payment method whose `expend_date` falls
  within `start_date` and `end_date` (both inclusive), most recent first, with
  `:category` (and its `:section`) preloaded.

  Used by the payment method page to list the movements of the current period.

  ## Examples

      iex> list_movements_by_payment_method(scope, 1, ~D[2026-11-01], ~D[2026-11-30])
      [%Movement{}, ...]

  """
  def list_movements_by_payment_method(
        %Scope{} = scope,
        payment_method_id,
        %Date{} = start_date,
        %Date{} = end_date
      ) do
    Movement
    |> where([m], m.user_id == ^scope.user.id)
    |> where([m], m.payment_method_id == ^payment_method_id)
    |> where([m], m.expend_date >= ^start_date and m.expend_date <= ^end_date)
    |> order_by([m], desc: m.expend_date, desc: m.id)
    |> Repo.all()
    |> Repo.preload(category: :section)
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
  Gets a single movement with its `:category` and `:payment_method`
  associations preloaded.

  Raises `Ecto.NoResultsError` if the Movement does not exist.
  """
  def get_movement_with_associations!(%Scope{} = scope, id) do
    scope
    |> get_movement!(id)
    |> Repo.preload([:category, :payment_method])
  end

  @doc """
  Creates a movement.

  When `installments` is greater than 1, the amount is split into equal
  installments (any remaining cents go to the last one) and one movement is
  created per installment, all inside a single transaction. Each installment
  keeps the same category, payment method, type and counter party, is dated
  one month after the previous one and has its number appended to the
  description, e.g. `"TV (1/3)"`. The first installment is returned, with
  `:installments` set to the number of installments created.

  ## Examples

      iex> create_movement(scope, %{field: value})
      {:ok, %Movement{}}

      iex> create_movement(scope, %{field: value, installments: 3})
      {:ok, %Movement{installments: 3}}

      iex> create_movement(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_movement(%Scope{} = scope, attrs) do
    changeset =
      %Movement{}
      |> Movement.changeset(attrs, scope)
      |> validate_category_available(scope)

    case Ecto.Changeset.get_field(changeset, :installments) do
      count when changeset.valid? and is_integer(count) and count > 1 ->
        create_installments(scope, changeset, count)

      _ ->
        with {:ok, movement = %Movement{}} <- Repo.insert(changeset) do
          broadcast_movement(scope, {:created, movement})
          {:ok, movement}
        end
    end
  end

  defp create_installments(scope, changeset, count) do
    base = Ecto.Changeset.apply_changes(changeset)

    {:ok, movements} =
      Repo.transaction(fn ->
        base.amount
        |> Movement.split_amount(count)
        |> Enum.with_index(1)
        |> Enum.map(fn {amount, number} ->
          Repo.insert!(%{
            base
            | amount: amount,
              expend_date: Date.shift(base.expend_date, month: number - 1),
              description: "#{base.description} (#{number}/#{count})"
          })
        end)
      end)

    Enum.each(movements, &broadcast_movement(scope, {:created, &1}))

    {:ok, hd(movements)}
  end

  # Só aceita categorias ativas (em seção ativa) quando a categoria muda. Uma
  # movimentação antiga pode continuar numa categoria que foi desativada depois.
  defp validate_category_available(changeset, scope) do
    case Ecto.Changeset.get_change(changeset, :category_id) do
      nil ->
        changeset

      category_id ->
        if category_available?(scope, category_id),
          do: changeset,
          else: Ecto.Changeset.add_error(changeset, :category_id, "categoria desativada")
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
           |> validate_category_available(scope)
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

    movement
    |> Movement.changeset(attrs, scope)
    |> Movement.put_amount_reais_display()
  end
end
