defmodule MyBudgetWeb.CategoryHTML do
  use MyBudgetWeb, :html

  embed_templates "category_html/*"

  @doc """
  Renders a category form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :sections_options, :list, required: true
  attr :return_to, :string, default: "index"
  attr :cancel_path, :string, required: true
  attr :show_budget_toggle, :boolean, default: false

  def category_form(assigns)

  @doc """
  Renders a block of the category listing (active or inactive categories),
  grouped by section.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :groups, :list, required: true, doc: "list of `%{section: section, categories: [...]}`"
  attr :category_ids_with_movements, :any, required: true
  attr :empty_message, :string, default: nil
  attr :muted, :boolean, default: false

  def category_groups(assigns) do
    ~H"""
    <section id={@id} class="space-y-2">
      <h2 class="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-base-content/60">
        {@title}
        <span class="badge badge-sm badge-ghost">
          {@groups |> Enum.map(&length(&1.categories)) |> Enum.sum()}
        </span>
      </h2>

      <p
        :if={@groups == [] and @empty_message}
        class="rounded-box border border-dashed border-base-300 px-4 py-6 text-center text-sm text-base-content/50"
      >
        {@empty_message}
      </p>

      <div class="space-y-4">
        <%= for section <- @groups do %>
          <section class={[
            "rounded-box border border-base-300 overflow-hidden",
            if(@muted, do: "bg-base-200/40", else: "bg-base-100")
          ]}>
            <header class="flex items-center justify-between gap-3 bg-base-200 px-4 py-3">
              <div class="flex items-center gap-2">
                <h3 class={["font-semibold", !section.section.active && "text-base-content/50"]}>
                  {section.section.name}
                </h3>
                <span
                  :if={!section.section.active}
                  id={"section-inactive-#{section.section.id}"}
                  class="badge badge-sm badge-ghost text-base-content/60"
                >
                  Sessão desativada
                </span>
                <span class="badge badge-sm badge-ghost">{length(section.categories)}</span>
              </div>
            </header>

            <ul class="divide-y divide-base-200">
              <li
                :for={category <- section.categories}
                id={"category-#{category.id}"}
                class="group flex items-center justify-between gap-3 px-4 py-3 transition-colors hover:bg-base-200/50"
              >
                <div class="flex flex-1 items-center gap-2">
                  <.link
                    href={~p"/category/#{category}"}
                    class={[
                      "font-medium hover:underline",
                      @muted && "text-base-content/50"
                    ]}
                  >
                    {category.name}
                  </.link>
                  <span
                    :if={!category.active}
                    id={"category-inactive-#{category.id}"}
                    class="badge badge-sm badge-ghost text-base-content/60"
                  >
                    Desativada
                  </span>
                </div>

                <div class="flex items-center gap-3 text-sm">
                  <.link
                    href={~p"/category/#{category}/edit"}
                    class="inline-flex items-center gap-1 text-base-content/70 hover:text-primary"
                  >
                    <.icon name="hero-pencil-square" class="size-4" /> Editar
                  </.link>
                  <%= if MapSet.member?(@category_ids_with_movements, category.id) do %>
                    <span
                      id={"delete-category-disabled-#{category.id}"}
                      class="inline-flex cursor-not-allowed items-center gap-1 text-base-content/30"
                      title="Categorias com movimentações não podem ser apagadas. Desative-a para escondê-la."
                    >
                      <.icon name="hero-trash" class="size-4" /> Apagar
                    </span>
                  <% else %>
                    <.link
                      id={"delete-category-#{category.id}"}
                      href={~p"/category/#{category}"}
                      method="delete"
                      data-confirm="Tem certeza que deseja apagar essa categoria? Ela também será removida dos orçamentos em que estiver."
                      class="inline-flex items-center gap-1 text-base-content/70 hover:text-error"
                    >
                      <.icon name="hero-trash" class="size-4" /> Apagar
                    </.link>
                  <% end %>
                </div>
              </li>
            </ul>
          </section>
        <% end %>
      </div>
    </section>
    """
  end
end
