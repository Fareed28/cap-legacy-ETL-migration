"""Parity table registry — targets in participant schema vs golden legacy_dw_*."""

CATALOG = "rud_2026"
TARGET_SCHEMA = "rud_fahamed"
GOLDEN_SCHEMA = "reference"

# layer: dimension | fact | aggregate (used when strict_parity=false to soft-fail aggs only)
TABLES = {
    "dim_hotel": {
        "target": f"{CATALOG}.{TARGET_SCHEMA}.dim_hotel",
        "golden": f"{CATALOG}.{GOLDEN_SCHEMA}.legacy_dw_dim_hotel",
        "keys": ["hotel_code"],
        "layer": "dimension",
    },
    "dim_date": {
        "target": f"{CATALOG}.{TARGET_SCHEMA}.dim_date",
        "golden": f"{CATALOG}.{GOLDEN_SCHEMA}.legacy_dw_dim_date",
        "keys": ["date_key"],
        "layer": "dimension",
    },
    "fact_stay": {
        "target": f"{CATALOG}.{TARGET_SCHEMA}.fact_stay",
        "golden": f"{CATALOG}.{GOLDEN_SCHEMA}.legacy_dw_fact_stay",
        "keys": ["res_id"],
        "layer": "fact",
    },
    "agg_monthly": {
        "target": f"{CATALOG}.{TARGET_SCHEMA}.agg_monthly",
        "golden": f"{CATALOG}.{GOLDEN_SCHEMA}.legacy_dw_agg_monthly",
        "keys": ["hotel_code", "fiscal_year", "fiscal_month"],
        "layer": "aggregate",
    },
    "agg_channel_share": {
        "target": f"{CATALOG}.{TARGET_SCHEMA}.agg_channel_share",
        "golden": f"{CATALOG}.{GOLDEN_SCHEMA}.legacy_dw_agg_channel_share",
        "keys": ["hotel_code", "channel_cd"],
        "layer": "aggregate",
    },
}
