# Ownership (CAP-8 pair demo)

Pedagogical split for demo day — **not** reflected in directory layout (production uses domain layers).

| Owner | Scope |
|-------|--------|
| Fareed (A) | `dim_hotel`, `dim_date`, `fact_stay`, parity harness |
| Hariharasudhan (B) | `agg_monthly`, `agg_channel_share`, bundle + CI |

Code lives under:

```text
src/hotel_dw_etl/transformations/
tests/integration/parity/
resources/
```
