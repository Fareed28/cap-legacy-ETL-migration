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

### SP entitlements (common 403)

If Actions fails with *“API is disabled for users without the databricks-sql-access or workspace-access or workspace-consume entitlements”*:

1. Admin enables **Workspace access** (and preferably SQL access) on the existing service principal.
2. Confirm the SP is assigned to this workspace.
3. Re-run the workflow — **do not** rotate the client secret unless the SP itself was recreated.

### UC grants (pipeline PERMISSION_DENIED)

If refresh fails with *User does not have USE SCHEMA on Schema 'rud_2026.rud_fahamed'*, admin runs (use SP application id or display name):

```sql
GRANT USE CATALOG ON CATALOG rud_2026 TO `<sp-id-or-name>`;
GRANT USE SCHEMA ON SCHEMA rud_2026.rud_fahamed TO `<sp-id-or-name>`;
GRANT CREATE TABLE ON SCHEMA rud_2026.rud_fahamed TO `<sp-id-or-name>`;
GRANT MODIFY ON SCHEMA rud_2026.rud_fahamed TO `<sp-id-or-name>`;
GRANT SELECT ON SCHEMA rud_2026.reference TO `<sp-id-or-name>`;
GRANT USE SCHEMA ON SCHEMA rud_2026.reference TO `<sp-id-or-name>`;
```

CI deploys under `/Workspace/Users/<sp>/.bundle/...` (not Shared) so the folder stays restricted to the run-as identity.

## Parity results

`rud_2026.rud_fahamed.parity_results`
