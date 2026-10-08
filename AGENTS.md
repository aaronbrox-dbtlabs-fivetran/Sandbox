# AGENTS.md

## Purpose

This repository is a Snowflake-backed dbt sandbox built from synthetic TPC-H data. It is used for demonstrations, onboarding, and examples of production-shaped analytics engineering practices.

Treat the project as a realistic analytics codebase even though the data is synthetic. Changes should preserve clear lineage, stable grains, useful documentation, and a passing test suite.

These instructions apply to the entire repository. A more specific `AGENTS.md` in a subdirectory may override them for that subtree.

## Project map

```text
models/staging/       Raw-source interfaces and source declarations
models/intermediate/  Reusable joins and business calculations
models/marts/         Business-facing analytical outputs
analyses/              Version-controlled exploratory SQL that is not materialized
macros/                Reusable Jinja and SQL abstractions
seeds/                 Small static CSV reference datasets
snapshots/             History tracking for mutable source records
tests/                 Singular tests and reusable generic test definitions
```

Generated directories such as `target/`, `dbt_packages/`, and `logs/` are not source code. Never edit or commit files in them.

## Current DAG

The project contains five raw sources and one final mart:

```text
tpch_now.orders ───────────────┐
                               ├─> order_items ───────┐
tpch_now.lineitem ─────────────┘                      │
                                                      ├─> fct_order_items
tpch_sf001.part ───────────────┐                      │
tpch_sf001.supplier ───────────┼─> part_suppliers ────┘
tpch_sf001.partsupp ───────────┘
```

Expected grains:

- `stg_tpch_orders`: one row per `order_key`
- `stg_tpch_line_items`: one row per `(order_key, line_number)`
- `stg_tpch_parts`: one row per `part_key`
- `stg_tpch_suppliers`: one row per `supplier_key`
- `stg_tpch_part_suppliers`: one row per `(part_key, supplier_key)`
- `order_items`: one row per `(order_key, line_number)`
- `part_suppliers`: one row per `(part_key, supplier_key)`
- `fct_order_items`: one row per `order_item_key`

A join must not change its model's documented grain unless the requested change explicitly introduces a new grain and updates documentation and tests accordingly.

## Layer responsibilities

### Staging

Staging models should:

- Reference raw relations with `source()`.
- Rename source-system columns to stable business-friendly names.
- Perform only light casting or cleanup.
- Preserve the source grain and column meaning.
- Avoid joins, aggregations, and business calculations.
- Materialize as views.

Source declarations, freshness rules, and raw-column tests belong in `models/staging/_tpch__sources.yml`. Staging model descriptions and tests belong in `models/staging/_tpch__models.yml`.

### Intermediate

Intermediate models should:

- Reference staging models with `ref()`.
- Centralize reusable joins and calculations.
- State their grain in YAML.
- Resolve duplicate column names explicitly.
- Preserve base records unless an inner join is intentionally enforcing a required relationship.
- Materialize as views.

Intermediate documentation and tests belong in `models/intermediate/_tpch__models.yml`.

### Marts

Mart models should:

- Present stable, business-friendly interfaces.
- Have a tested primary key and documented grain.
- Distinguish additive measures from repeated or non-additive attributes.
- Avoid exposing intermediate implementation details without analytical value.
- Materialize as tables unless there is a documented reason to choose another strategy.

Mart documentation and tests belong in `models/marts/_tpch__marts.yml`.

## SQL conventions

- Use `{{ source() }}` for raw inputs and `{{ ref() }}` for dbt-built resources.
- Never hardcode development database or schema names in model SQL.
- Prefer readable CTEs over nested subqueries.
- Use explicit select lists for stable model interfaces.
- Keep SQL keywords lowercase to match the existing project style.
- Use descriptive aliases and qualify columns in joins.
- Preserve all existing output columns unless a requested change explicitly alters the model contract.
- Confirm upstream columns before adding or renaming fields; do not invent plausible source columns.
- Avoid `select *` in final projections. It is acceptable in a narrowly scoped input CTE when the final projection is explicit.

## Financial logic

The order-line calculations have defined meanings:

- `discount_amount = extended_price * discount_rate`
- `net_item_amount = extended_price * (1 - discount_rate)`
- `tax_amount = net_item_amount * tax_rate`
- `total_item_amount = net_item_amount + tax_amount`
- `estimated_supply_cost = quantity * supply_cost`
- `estimated_margin_amount = net_item_amount - estimated_supply_cost`

`estimated_margin_amount` is an operational estimate, not an accounting measure. It excludes overhead, freight allocations, rebates, and posted adjustments.

`order_total_price` is an order-header value repeated across lines. Do not sum it at order-line grain. Use line-level measures for additive analysis.

The current synthetic feed has zero discount and tax rates. Do not simplify away the formulas; they intentionally support future non-zero values.

## Source and data caveats

- The data is synthetic and contains no real customers or suppliers.
- Customer and nation dimensions are intentionally out of scope. Their keys remain degenerate dimensions.
- Supplier account balances may be negative and should not automatically fail positivity checks.
- Shipping priority may be zero and is excluded from the positive-orders singular test.
- Product size is an abstract TPC-H attribute without a real-world unit.
- Catalog retail price, realized line value, and supplier cost are distinct concepts.
- Comment and contact fields are retained for demonstration purposes; a production mart might omit or restrict them.
- Source freshness uses Snowflake relation metadata because the sources do not contain a reliable ingestion timestamp.
- Freshness warns after one day and errors after two days.

## Tests

Use the smallest set of high-signal tests that protects model contracts:

- `unique` and `not_null` on primary keys.
- `not_null` on required composite-key components.
- `relationships` on required foreign keys.
- `accepted_values` only for confirmed, bounded enums.
- Singular tests for business rules spanning multiple columns or models.

Do not add `not_null` to every column by default. Nullability should reflect a real business expectation.

Generic test applications belong in the YAML file beside the resource. Custom generic test definitions belong under `tests/generic/`. Singular tests belong directly under `tests/` and must return failing rows.

When adding a singular test, add its description to `tests/_tests.yml`.

## Documentation

Every model should document:

- Its purpose.
- Its grain.
- Important inclusion or exclusion rules.
- Non-obvious calculations or caveats.

Every exposed column should have a useful description. Explain business meaning, calculation, or analytical caveats rather than restating the column name.

Update `README.md` when a change affects architecture, model inventory, commands, or project-wide conventions.

## Validation

Match validation to the change:

- Documentation-only changes: `dbt parse`
- Source or model YAML tests: `dbt parse`, then `dbt build --select +<model>+`
- SQL model changes: `dbt build --select +<model>+`
- Broad macro changes: run a full `dbt build`
- Source freshness changes: `dbt source freshness`

This project is intentionally small. Prefer a full `dbt build` when a change spans multiple layers or when selection would be more complex than running the complete suite.

Before considering work complete, confirm:

- The intended grain is preserved.
- Primary and foreign keys still behave as documented.
- Model YAML matches the SQL output columns.
- `ref()` and `source()` are used correctly.
- The relevant build and tests pass without warnings.

## Git and repository safety

- Do not modify generated or vendored files.
- Keep changes scoped to the requested outcome.
- Do not remove unrelated local changes.
- Use clear, outcome-based commit messages when asked to commit.
- Treat changes to mart columns, names, or types as potential breaking changes for downstream consumers.
