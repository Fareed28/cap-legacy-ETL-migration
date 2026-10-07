# hotel_dw_etl

Production Databricks Asset Bundle for the HotelDW nightly ETL migration (Lakeflow Declarative Pipelines).

| | |
|--|--|
| Catalog / schema | `rud_2026.rud_fahamed` |
| Sources | `rud_2026.reference.legacy_stg_*` (read-only) |
| Golden | `rud_2026.reference.legacy_dw_*` (read-only) |

## Layout

```text
hotel_dw_etl/
├── databricks.yml
├── resources/                         # bundle resource definitions
│   ├── hotel_dw_etl.pipeline.yml
│   └── hotel_dw_parity.job.yml
├── src/hotel_dw_etl/transformations/  # Lakeflow SQL (MVs)
├── tests/integration/parity/          # checksum / EXCEPT harness
├── scripts/                           # one-time ops SQL
├── docs/                              # architecture & runbooks
└── .github/workflows/ci.yml
```

## Commands

```bash
cd hotel_dw_etl

databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle run -t dev hotel_dw_etl --refresh-all
databricks bundle run -t dev hotel_dw_parity
```

First-time workspace setup: run `scripts/bootstrap_schema.sql`, then `scripts/inspect_sources.sql`.

## Targets

| Target | Mode | Parity |
|--------|------|--------|
| `dev` | development | `strict_parity=false` |
| `staging` / `ci` | production | `strict_parity=true` |

## Docs

- [Dependency map](docs/dependency_map.md)
- [Migration notes](docs/migration_notes.md)
- [Runbook](docs/runbook.md)
- [Ownership](docs/ownership.md)

<!-- CI smoke: merge to main should trigger hotel_dw_etl CI -->
