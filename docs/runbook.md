# Runbook — hotel_dw_etl

## Prerequisites

- Databricks CLI authenticated (`databricks auth login --host <url>`)
- Access to `rud_2026.reference` (read) and `rud_2026.rud_fahamed` (write)
- Compute tagged `rud_participant`

## Deploy (dev)

```bash
cd hotel_dw_etl
databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle run -t dev hotel_dw_etl --refresh-all
databricks bundle run -t dev hotel_dw_parity
```

## First-time setup

1. Run `scripts/bootstrap_schema.sql`
2. Run `scripts/inspect_sources.sql` — confirm staging types / golden names

## CI

GitHub Actions (`.github/workflows/ci.yml`) needs:

- `DATABRICKS_HOST`
- `DATABRICKS_CLIENT_ID` + `DATABRICKS_CLIENT_SECRET` (or `DATABRICKS_TOKEN`)

Target `ci` runs with `strict_parity=true`.

## Parity results

`rud_2026.rud_fahamed.parity_results`
