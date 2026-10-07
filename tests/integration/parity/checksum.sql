-- CAP-8 parity harness (SQL)
-- Run in a SQL warehouse / notebook against rud_fahamed after the pipeline refresh.
-- Replace schema names if your workspace uses a different catalog.

-- ========== Per-table ordered checksum ==========
-- Pattern: row_count + sum(xxhash64 of all columns) over rows ordered by PK.

-- dim_hotel
SELECT 'dim_hotel' AS table_name, 'target' AS side, COUNT(*) AS row_cnt,
       COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0) AS checksum
FROM (
  SELECT * FROM rud_2026.rud_fahamed.dim_hotel ORDER BY hotel_code
)
UNION ALL
SELECT 'dim_hotel', 'golden', COUNT(*), COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0)
FROM (
  SELECT * FROM rud_2026.reference.legacy_dw_dim_hotel ORDER BY hotel_code
);

-- dim_date
SELECT 'dim_date' AS table_name, 'target' AS side, COUNT(*) AS row_cnt,
       COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0) AS checksum
FROM (
  SELECT * FROM rud_2026.rud_fahamed.dim_date ORDER BY date_key
)
UNION ALL
SELECT 'dim_date', 'golden', COUNT(*), COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0)
FROM (
  SELECT * FROM rud_2026.reference.legacy_dw_dim_date ORDER BY date_key
);

-- fact_stay
SELECT 'fact_stay' AS table_name, 'target' AS side, COUNT(*) AS row_cnt,
       COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0) AS checksum
FROM (
  SELECT * FROM rud_2026.rud_fahamed.fact_stay ORDER BY res_id
)
UNION ALL
SELECT 'fact_stay', 'golden', COUNT(*), COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0)
FROM (
  SELECT * FROM rud_2026.reference.legacy_dw_fact_stay ORDER BY res_id
);

-- agg_monthly
SELECT 'agg_monthly' AS table_name, 'target' AS side, COUNT(*) AS row_cnt,
       COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0) AS checksum
FROM (
  SELECT * FROM rud_2026.rud_fahamed.agg_monthly
  ORDER BY hotel_code, fiscal_year, fiscal_month
)
UNION ALL
SELECT 'agg_monthly', 'golden', COUNT(*), COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0)
FROM (
  SELECT * FROM rud_2026.reference.legacy_dw_agg_monthly
  ORDER BY hotel_code, fiscal_year, fiscal_month
);

-- agg_channel_share
SELECT 'agg_channel_share' AS table_name, 'target' AS side, COUNT(*) AS row_cnt,
       COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0) AS checksum
FROM (
  SELECT * FROM rud_2026.rud_fahamed.agg_channel_share
  ORDER BY hotel_code, channel_cd
)
UNION ALL
SELECT 'agg_channel_share', 'golden', COUNT(*), COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), 0)
FROM (
  SELECT * FROM rud_2026.reference.legacy_dw_agg_channel_share
  ORDER BY hotel_code, channel_cd
);

-- ========== Row-level diff sample (run when checksum fails) ==========
-- Example for fact_stay:
--
-- SELECT * FROM rud_2026.rud_fahamed.fact_stay
-- EXCEPT
-- SELECT * FROM rud_2026.reference.legacy_dw_fact_stay
-- LIMIT 50;
--
-- SELECT * FROM rud_2026.reference.legacy_dw_fact_stay
-- EXCEPT
-- SELECT * FROM rud_2026.rud_fahamed.fact_stay
-- LIMIT 50;
