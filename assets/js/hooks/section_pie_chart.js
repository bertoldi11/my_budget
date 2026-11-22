// Gráfico de pizza das saídas do mês por sessão (home).
//
// Os dados chegam em `data-slices` (JSON: [{label, value, percent, slot}]),
// com `value` em centavos. As cores vêm das variáveis CSS `--chart-series-*`
// (definidas em app.css para os temas claro e escuro), então o gráfico
// acompanha a troca de tema sem precisar re-renderizar a página.
import Chart from "../../vendor/chart.umd.js"

const brl = new Intl.NumberFormat("pt-BR", {style: "currency", currency: "BRL"})

const cssVar = (el, name) => getComputedStyle(el).getPropertyValue(name).trim()

const sliceColor = (el, slot) =>
  cssVar(el, slot === "other" ? "--chart-series-other" : `--chart-series-${slot}`)

const SectionPieChart = {
  mounted() {
    const canvas = this.el.querySelector("canvas")

    this.chart = new Chart(canvas, {
      type: "pie",
      data: {labels: [], datasets: [{data: []}]},
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {duration: 400},
        // A legenda (com valores) é renderizada em HTML ao lado do gráfico.
        plugins: {
          legend: {display: false},
          tooltip: {
            callbacks: {
              label: ctx => {
                const slice = this.slices[ctx.dataIndex]
                return ` ${brl.format(slice.value / 100)} (${slice.percent}%)`
              },
            },
          },
        },
      },
    })

    this.render()

    // Troca de tema: atributo data-theme no <html> ou preferência do sistema.
    this.themeObserver = new MutationObserver(() => this.render())
    this.themeObserver.observe(document.documentElement, {attributes: true, attributeFilter: ["data-theme"]})
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.onMediaChange = () => this.render()
    this.media.addEventListener("change", this.onMediaChange)
  },

  // Com phx-update="ignore" o conteúdo não é tocado, mas os atributos do
  // elemento (data-slices) são atualizados ao trocar de mês ou salvar.
  updated() {
    this.render()
  },

  destroyed() {
    this.themeObserver?.disconnect()
    this.media?.removeEventListener("change", this.onMediaChange)
    this.chart?.destroy()
  },

  render() {
    this.slices = JSON.parse(this.el.dataset.slices || "[]")
    const dataset = this.chart.data.datasets[0]

    this.chart.data.labels = this.slices.map(s => s.label)
    dataset.data = this.slices.map(s => s.value)
    dataset.backgroundColor = this.slices.map(s => sliceColor(this.el, s.slot))
    // Espaço de 2px na cor da superfície entre as fatias.
    dataset.borderColor = cssVar(this.el, "--color-base-100")
    dataset.borderWidth = 2
    dataset.hoverOffset = 6

    this.chart.update()
  },
}

export default SectionPieChart
