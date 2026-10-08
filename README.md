# TPC-H Analytics Sandbox

This dbt project is a demonstration environment for building a small, production-shaped analytics workflow on Snowflake. It uses synthetic TPC-H order, product, and supplier data to show how raw sources move through staging and intermediate transformations into a tested, business-facing fact table.

The project is intentionally compact enough for workshops and onboarding while still demonstrating practices used in a real analytics codebase: source freshness, layered modeling, explicit grains, reusable joins, data tests, documentation, and environment-specific schemas.

## Business use case

The fictional commercial operations team needs a dependable order-line dataset for sales and supplier-margin analysis. Analysts should be able to answer questions about order volume, item revenue, fulfillment timing, product mix, supplier availability, and estimated margin without rebuilding joins or financial calculations in every report.

`fct_order_items` is the primary analytical output. It combines order headers and line items with the supplier-specific product record used to fulfill each line.

## Architecture

| Layer | Directory | Purpose | Materialization |
| --- | --- | --- | --- |
| Sources | `models/staging/_tpch__sources.yml` | Declares raw Snowflake relations, freshness expectations, and source-data assumptions. | Existing raw tables |
| Staging | `models/staging/` | Renames source-system columns and exposes a stable, typed interface without changing grain. | View |
| Intermediate | `models/intermediate/` | Performs reusable joins and line-level calculations before the data is presented to analysts. | View |
| Marts | `models/marts/` | Publishes stable business-facing datasets optimized for consumption. | Table |

The main lineage is:

```text
tpch_now.orders ───────────────┐
                               ├─> order_items ───────┐
tpch_now.lineitem ─────────────┘                      │
                                                      ├─> fct_order_items
tpch_sf001.part ───────────────┐                      │
tpch_sf001.supplier ───────────┼─> part_suppliers ────┘
tpch_sf001.partsupp ───────────┘
```

## Model grains

| Model | Grain |
| --- | --- |
| `stg_tpch_orders` | One row per order |
| `stg_tpch_line_items` | One row per order and line number |
| `stg_tpch_parts` | One row per part |
| `stg_tpch_suppliers` | One row per supplier |
| `stg_tpch_part_suppliers` | One row per part and supplier pairing |
| `order_items` | One row per order and line number, enriched with order-header attributes |
| `part_suppliers` | One row per part and supplier pairing, enriched with product and supplier attributes |
| `fct_order_items` | One row per order and line number, enriched for sales and supplier analysis |

## Financial measures

The fact table exposes a small set of line-level measures:

- `extended_price`: source line value before discount and tax.
- `discount_amount`: `extended_price * discount_rate`.
- `net_item_amount`: extended price after discount and before tax.
- `tax_amount`: tax calculated on the discounted line value.
- `total_item_amount`: net item amount plus tax.
- `estimated_supply_cost`: ordered quantity multiplied by the supplier-specific unit cost.
- `estimated_margin_amount`: net item amount less estimated supply cost.

Supplier cost is an operational estimate rather than a posted accounting cost, so `estimated_margin_amount` is suitable for demonstrations and directional analysis, not financial reporting. The current synthetic feed has zero discount and tax rates, but the transformations intentionally support non-zero rates.

## Data quality

The project uses generic data tests to protect:

- Primary-key uniqueness and completeness
- Required foreign keys
- Relationships between orders, lines, parts, and suppliers
- Valid TPC-H status and priority codes
- Join completeness in intermediate models
- The final order-item grain

The singular test `assert_stg_tpch_orders_positive_values` confirms that order keys, customer keys, and order totals are positive. Shipping priority is excluded because zero is valid in TPC-H.

Source freshness warns after one day and errors after two days. Because these Snowflake sources do not contain ingestion timestamps, freshness uses Snowflake relation metadata rather than a row-level loaded-at field.

## Common commands

Build all models and run their tests:

```text
dbt build
```

Run data tests without rebuilding models:

```text
dbt test
```

Run source freshness checks:

```text
dbt source freshness
```

Build the final mart and all of its upstream dependencies:

```text
dbt build --select +fct_order_items
```

Preview a model in the active development target:

```text
dbt show --select fct_order_items --limit 10
```

## Repository conventions

- Raw relations are referenced with `source()`; dbt-built relations are referenced with `ref()`.
- Staging models use the `stg_tpch_` prefix and avoid business joins.
- Intermediate models centralize reusable joins and calculations.
- Fact models use the `fct_` prefix and declare a stable analytical grain.
- Resource descriptions and generic tests live in YAML beside the models they describe.
- Cross-model business assertions live as singular SQL tests under `tests/`.
- Generated folders such as `target/`, `dbt_packages/`, and `logs/` are not committed.

## Demo scope and limitations

The data is synthetic and should not be interpreted as real customer or supplier activity. Customer and nation dimension tables are intentionally omitted, so their keys remain degenerate dimensions in the fact table. Comments and contact fields are retained to demonstrate wide-table documentation, but production marts would normally restrict sensitive or low-value attributes based on consumer needs.
