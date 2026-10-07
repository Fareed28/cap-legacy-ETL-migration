-- hotel_dw_etl.dim_date
-- Legacy: dw.usp_load_dim_date (@from/@to default 2025-01-01..2025-12-31)
-- Fiscal: Apr–Mar, year named by end year; April = fiscal_month 1
-- Weekend: BOOLEAN (SQL Server BIT) — Spark DAYOFWEEK 1=Sun … 7=Sat

CREATE OR REFRESH MATERIALIZED VIEW dim_date
COMMENT 'Date dimension — migrated from dw.usp_load_dim_date'
AS
SELECT
  CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
  d AS full_date,
  CASE
    WHEN MONTH(d) >= 4 THEN YEAR(d) + 1
    ELSE YEAR(d)
  END AS fiscal_year,
  ((MONTH(d) + 8) % 12) + 1 AS fiscal_month,
  CASE
    WHEN DAYOFWEEK(d) IN (1, 7) THEN TRUE
    ELSE FALSE
  END AS is_weekend
FROM (
  SELECT EXPLODE(
    SEQUENCE(TO_DATE('2025-01-01'), TO_DATE('2025-12-31'), INTERVAL 1 DAY)
  ) AS d
);
