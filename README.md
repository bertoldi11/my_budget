# MyBudget 💰

Aplicação web para **controle de finanças pessoais** — registre suas movimentações, organize por categorias e acompanhe o quanto gastou em cada área ao longo de cada mês.

---

## Funcionalidades

### Dashboard mensal

A tela inicial exibe um resumo do mês atual com navegação para meses anteriores e futuros. O total geral aparece em destaque, e abaixo as movimentações são agrupadas por **seção** (ex.: Moradia, Alimentação). Dentro de cada seção, as categorias listam o valor gasto e uma barra de progresso proporcional ao total da seção.

> 📸 **[Imagem sugerida: screenshot da tela inicial com o resumo mensal e as seções expandidas]**

---

### Movimentações

Cadastro, edição e exclusão de lançamentos financeiros. Cada movimentação contém:

| Campo | Descrição |
|---|---|
| Descrição | Texto livre sobre o gasto |
| Contraparte | Estabelecimento, pessoa ou empresa |
| Tipo | Tipo da movimentação (ex.: débito, crédito) |
| Valor | Inserido em reais (R$ 1.234,56) e armazenado em centavos |
| Data | Data em que o gasto ocorreu |
| Categoria | Classificação do gasto (vinculada a uma seção) |
| Forma de pagamento | Cartão, dinheiro, pix etc. |

> 📸 **[Imagem sugerida: formulário de nova movimentação preenchido]**

---

### Seções

Agrupamentos de alto nível para organizar categorias — funcionam como "gavetas" que aparecem no resumo mensal (ex.: Moradia, Saúde, Transporte).

> 📸 **[Imagem sugerida: listagem de seções com botões de editar/excluir]**

---

### Categorias

Subdivisões de uma seção usadas na classificação de cada movimentação (ex.: Aluguel dentro de Moradia, Mercado dentro de Alimentação). Cada categoria pertence a exatamente uma seção.

> 📸 **[Imagem sugerida: listagem de categorias mostrando a coluna "Seção"]**

---

### Formas de pagamento

Cadastro das formas de pagamento disponíveis (ex.: Cartão Nubank, Dinheiro, Pix). Vinculadas a cada movimentação para facilitar a análise posterior.

---

### Autenticação

Registro e login de usuários com e-mail e senha. Todos os dados (movimentações, categorias, seções e formas de pagamento) são **isolados por usuário** — cada pessoa enxerga apenas os seus próprios registros.

> 📸 **[Imagem sugerida: telas de login e cadastro]**

---

## Stack tecnológica

| Camada | Tecnologia |
|---|---|
| Linguagem | [Elixir](https://elixir-lang.org/) |
| Framework web | [Phoenix 1.8](https://www.phoenixframework.org/) |
| Banco de dados | PostgreSQL via Ecto |
| Frontend | Phoenix LiveView + Tailwind CSS v4 |
| Ícones | Heroicons v2 |
| Formatação de moeda | ex_cldr / ex_cldr_numbers (pt-BR / BRL) |

---

## Configuração do ambiente

### Pré-requisitos

- Elixir ≥ 1.15
- PostgreSQL rodando localmente

### Instalação

```bash
# instala dependências e cria/migra o banco
mix setup

# inicia o servidor
mix phx.server
```

Acesse [http://localhost:4000](http://localhost:4000).

### Variáveis de ambiente

Crie um arquivo `.env` ou configure diretamente as variáveis abaixo (usadas em `config/dev.exs` e `config/prod.exs`):

| Variável | Padrão dev |
|---|---|
| `DATABASE_URL` | `postgres://postgres:postgres@localhost/my_budget_dev` |
| `SECRET_KEY_BASE` | gerada automaticamente em dev |

---

## Estrutura do projeto

```
lib/
├── my_budget/                  # lógica de negócio
│   ├── movements/              # contexto de movimentações
│   │   ├── movement.ex         # schema + changeset (conversão reais→centavos)
│   │   ├── category.ex
│   │   ├── section.ex
│   │   └── payment_method.ex
│   └── accounts/               # autenticação de usuários
└── my_budget_web/              # camada web (Phoenix)
    ├── controllers/
    │   ├── home_controller.ex  # resumo mensal
    │   ├── movement_controller.ex
    │   ├── category_controller.ex
    │   ├── section_controller.ex
    │   └── payment_method_controller.ex
    └── router.ex
```

---

## Comandos úteis

```bash
# executa todos os testes
mix test

# verifica formatação, compila com warnings como erros e roda os testes
mix precommit

# recria o banco do zero
mix ecto.reset

# gera uma nova migration
mix ecto.gen.migration nome_da_migration
```

---

## Modelo de dados

```
Section (seção)
  └── Category (categoria)  ←── Movement (movimentação)
                                        └── PaymentMethod (forma de pagamento)
```

Valores monetários são armazenados **em centavos** (`integer`) para evitar imprecisão de ponto flutuante. A conversão para exibição (`R$ 1.234,56`) é feita via `ex_cldr_numbers` com locale `pt` e moeda `BRL`.
