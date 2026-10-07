# CAP-8 dependency map

Legacy entrypoint: `dw.usp_run_nightly` → five procs in fixed order.

## Graph

```text
legacy_stg_hotels ──────────────────────► dim_hotel ──┐
                                                      │
(calendar generator, no staging) ───────► dim_date ───┤
                                                      ├──► fact_stay ──► agg_monthly
legacy_stg_reservations ──────────────────────────────┤            └──► agg_channel_share
legacy_stg_fx (LEFT JOIN on checkin + ccy) ───────────┘
```

## Procedure inventory

| Seq | Legacy proc | Target table | Reads | Write pattern | Layer |
|-----|-------------|--------------|-------|---------------|-------|
| 1 | `usp_load_dim_hotel` | `dim_hotel` | `stg.hotels` | MERGE upsert | dimension |
| 2 | `usp_load_dim_date` | `dim_date` | (generated 2025-01-01..2025-12-31) | DELETE range + INSERT loop | dimension |
| 3 | `usp_load_fact_stay` | `fact_stay` | `stg.reservations`, `dim_hotel`, `stg.fx` | TRUNCATE + INSERT | fact |
| 4 | `usp_load_agg_monthly` | `agg_monthly` | `fact_stay`, `dim_date`, `dim_hotel` | TRUNCATE + INSERT | aggregate |
| 5 | `usp_load_agg_channel_share` | `agg_channel_share` | `fact_stay` | TRUNCATE + INSERT | aggregate |
| — | `usp_run_nightly` | `etl_log` | (orchestrates 1–5) | log + THROW on error | pipeline DAG |

## Databricks table mapping

| SQL Server | Databricks |
|------------|------------|
| `stg.hotels` | `rud_2026.reference.legacy_stg_hotels` |
| `stg.reservations` | `rud_2026.reference.legacy_stg_reservations` |
| `stg.fx` | `rud_2026.reference.legacy_stg_fx` |
| `dw.dim_hotel` | golden: `…legacy_dw_dim_hotel` → migrate to `rud_fahamed.dim_hotel` |
| `dw.dim_date` | golden: `…legacy_dw_dim_date` → `rud_fahamed.dim_date` |
| `dw.fact_stay` | golden: `…legacy_dw_fact_stay` → `rud_fahamed.fact_stay` |
| `dw.agg_monthly` | golden: `…legacy_dw_agg_monthly` → `rud_fahamed.agg_monthly` |
| `dw.agg_channel_share` | golden: `…legacy_dw_agg_channel_share` → `rud_fahamed.agg_channel_share` |

## Pipeline refresh order (Lakeflow)

Lakeflow infers the DAG from table references in `src/hotel_dw_etl/transformations/`:

`dim_hotel` / `dim_date` → `fact_stay` → `agg_monthly` / `agg_channel_share`

Pair ownership for demo is documented in [ownership.md](ownership.md); it does not affect folder layout.