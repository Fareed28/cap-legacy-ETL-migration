-- hotel_dw_etl.agg_channel_share
-- Legacy: dw.usp_load_agg_channel_share
-- Depends on: fact_stay | share_pct uses integer division

CREATE OR REFRESH MATERIALIZED VIEW agg_channel_share
COMMENT 'Channel share — migrated from dw.usp_load_agg_channel_share'
AS
WITH tot AS (
  SELECT hotel_code, COUNT(*) AS total_stays
  FROM fact_stay
  GROUP BY hotel_code
)
SELECT
  f.hotel_code,
  f.channel_cd,
  COUNT(*) AS stays,
  (100 * COUNT(*)) DIV MAX(t.total_stays) AS share_pct
FROM fact_stay f
JOIN tot t ON t.hotel_code = f.hotel_code
GROUP BY f.hotel_code, f.channel_cd;
