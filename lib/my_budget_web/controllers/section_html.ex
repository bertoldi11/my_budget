defmodule MyBudgetWeb.SectionHTML do
  use MyBudgetWeb, :html

  embed_templates "section_html/*"

  @doc """
  Renders a section form.
  """
  attr :form, Phoenix.HTML.Form, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: "index"
  attr :cancel_path, :string, required: true
  attr :show_budget_toggle, :boolean, default: false

  def section_form(assigns)

  @doc """
  Renders a block of the section listing (active or inactive sections).
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :sections, :list, required: true
  attr :section_ids_with_categories, :any, required: true
  attr :empty_message, :string, default: nil
  attr :muted, :boolean, default: false

  def section_group(assigns) do
    ~H"""
    <section id={@id} class="space-y-2">
      <h2 class="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-base-content/60">
        {@title}
        <span class="badge badge-sm badge-ghost">{length(@sections)}</span>
      </h2>

      <p
        :if={@sections == [] and @empty_message}
        class="rounded-box border border-dashed border-base-300 px-4 py-6 text-center text-sm text-base-content/50"
      >
        {@empty_message}
      </p>

      <div
        :if={@sections != []}
        class={[
          "rounded-box border border-base-300 overflow-hidden",
          if(@muted, do: "bg-base-200/40", else: "bg-base-100")
        ]}
      >
        <ul class="divide-y divide-base-200">
          <li
            :for={section <- @sections}
            id={"section-#{section.id}"}
            class="group flex items-center justify-between gap-3 px-4 py-3 transition-colors hover:bg-base-200/50"
          >
            <.link
              href={~p"/section/#{section}"}
              class={["flex-1 font-medium hover:underline", @muted && "text-base-content/50"]}
            >
              {section.name}
            </.link>

            <div class="flex items-center gap-3 text-sm">
              <.link
                href={~p"/section/#{section}/edit"}
                class="inline-flex items-center gap-1 text-base-content/70 hover:text-primary"
              >
                <.icon name="hero-pencil-square" class="size-4" /> Editar
              </.link>
              <%= if MapSet.member?(@section_ids_with_categories, section.id) do %>
                <span
                  id={"delete-section-disabled-#{section.id}"}
                  class="inline-flex cursor-not-allowed items-center gap-1 text-base-content/30"
                  title="Sessões com categorias não podem ser apagadas. Desative-a ou apague as categorias antes."
                >
                  <.icon name="hero-trash" class="size-4" /> Apagar
                </span>
              <% else %>
                <.link
                  id={"delete-section-#{section.id}"}
                  href={~p"/section/#{section}"}
                  method="delete"
                  data-confirm="Tem certeza que deseja excluir essa sessão?"
                  class="inline-flex items-center gap-1 text-base-content/70 hover:text-error"
                >
                  <.icon name="hero-trash" class="size-4" /> Apagar
                </.link>
              <% end %>
            </div>
          </li>
        </ul>
      </div>
    </section>
    """
  end
end
