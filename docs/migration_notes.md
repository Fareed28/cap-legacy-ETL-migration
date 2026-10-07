# Migration notes — behavioural differences

Reproduce legacy behaviour for parity first; document quirks here (CAP-8 done-when).

## Half A (confirmed in code; validate against golden)

| Area | Legacy (T-SQL) | Databricks choice | Risk |
|------|----------------|-------------------|------|
| Null star | `ISNULL(star, 3)` then derive `collection` | `COALESCE(star, 3)` | Low — must default before CASE |
| Hotel name | `UPPER(LTRIM(RTRIM(...)))` | `UPPER(TRIM(...))` | Low — TRIM removes both ends |
| MERGE vs MV | `MERGE` never deletes missing hotels | Full-refresh MV = staging snapshot | OK if golden came from same staging; if orphans existed in `dw.dim_hotel`, checksum fails |
| Fiscal year | Apr–Mar, named by **end** year | Same `CASE WHEN MONTH >= 4` | Low |
| Fiscal month | `((MONTH+8)%12)+1` | Same | Low |
| Weekend | `DATEFIRST 7`, weekday in (1,7); `BIT` | `DAYOFWEEK` + **BOOLEAN** (golden is BOOL, not INT) | High if left as 0/1 INT — EXCEPT fails with INCOMPATIBLE_COLUMN_TYPE |
| Guest name | `a + ' ' + b`, null yields null | `CONCAT(a,' ',b)` null-safe same way | Medium — do **not** use `concat_ws` (skips nulls) |
| Cancel filter | `status_cd <> 'X'` | Same — SQL three-valued logic: `NULL <> 'X'` is unknown → row dropped | Medium — if staging has null status, both drop |
| Discount | `ISNULL(discount,0)` | `COALESCE(discount,0)` | Low |
| FX miss | `LEFT JOIN` → `net_usd` null | Same | Low |
| `net_usd` / `adr_local` | `CAST(... AS DECIMAL(12,2))` | Same cast | Medium — banker’s rounding vs SQL Server round-half-up can differ on .xx5 |
| Date keys | `CONVERT(INT, checkin_dt)` + style 112 dates | `CAST(checkin_dt AS INT)` + `to_date(cast as string, 'yyyyMMdd')` | **High** if staging types are `DATE`/`TIMESTAMP` not `INT`/`STRING` yyyymmdd — inspect `DESCRIBE` and adjust |
| Dim date range | Default 2025-01-01..2025-12-31 | Hard-coded same range | Low — if nightly used other params, golden won’t match |

## Half B (for partner — already encoded in stubs)

| Area | Legacy | Databricks trap |
|------|--------|-----------------|
| `share_pct` | Integer division | Use `DIV` / cast ints — not float `/` |
| Occupancy | All room nights in **check-in** month; denom = `room_cnt * DAY(EOMONTH(min date))` | `LAST_DAY` + `DAY(...)`; FLOAT/DOUBLE semantics |

## etl_log

Not migrated. Orchestration + logging → Lakeflow run history / CI logs. Call out in demo if asked.

## Open items (need workspace)

- [ ] Confirm staging column types for `checkin_dt`, `checkout_dt`, `rate_dt`
- [ ] Confirm golden table names (`legacy_dw_dim_hotel` vs variants)
- [ ] Confirm target catalog is `rud_2026` and schema `rud_fahamed`
- [ ] First failed checksum → paste EXCEPT sample into report §6
- [ ] CI service principal + GitHub secrets
- [ ] Flip evidence checkboxes in `CAP-8-report.md` after green run
