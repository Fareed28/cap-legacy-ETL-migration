-- hotel_dw_etl.dim_hotel
-- Legacy: dw.usp_load_dim_hotel | Source: legacy_stg_hotels
-- Parity: ISNULL(star,3); UPPER(TRIM(name)); collection from star

CREATE OR REFRESH MATERIALIZED VIEW dim_hotel
COMMENT 'Hotel dimension — migrated from dw.usp_load_dim_hotel'
AS
SELECT
  hotel_code,
  UPPER(TRIM(hotel_name)) AS hotel_name,
  city,
  country,
  room_cnt,
  COALESCE(star, 3) AS star,
  CASE COALESCE(star, 3)
    WHEN 5 THEN 'LUXE'
    WHEN 4 THEN 'PREMIER'
    ELSE 'SELECT'
  END AS collection
FROM rud_2026.reference.legacy_stg_hotels;
