-- hotel_dw_etl.agg_monthly
-- Legacy: dw.usp_load_agg_monthly
-- Depends on: fact_stay, dim_date, dim_hotel

CREATE OR REFRESH MATERIALIZED VIEW agg_monthly
COMMENT 'Monthly hotel aggregates — migrated from dw.usp_load_agg_monthly'
AS
SELECT
  f.hotel_code,
  d.fiscal_year,
  d.fiscal_month,
  COUNT(*) AS stays,
  SUM(f.room_nights) AS room_nights,
  SUM(f.net_usd) AS revenue_usd,
  CAST(SUM(f.room_nights) AS DOUBLE)
    / (MAX(h.room_cnt) * DAY(LAST_DAY(MIN(d.full_date))))
    * 100 AS occupancy_pct
FROM fact_stay f
JOIN dim_date d  ON d.date_key = f.date_key
JOIN dim_hotel h ON h.hotel_code = f.hotel_code
GROUP BY f.hotel_code, d.fiscal_year, d.fiscal_month;
