-- hotel_dw_etl.fact_stay
-- Legacy: dw.usp_load_fact_stay
-- Reads: legacy_stg_reservations, dim_hotel (inner), legacy_stg_fx (left)
-- Filter: status_cd <> 'X'

CREATE OR REFRESH MATERIALIZED VIEW fact_stay
COMMENT 'Stay fact — migrated from dw.usp_load_fact_stay'
AS
WITH reservations AS (
  SELECT
    r.*,
    COALESCE(
      TRY_TO_DATE(CAST(r.checkin_dt AS STRING), 'yyyyMMdd'),
      TRY_CAST(r.checkin_dt AS DATE)
    ) AS checkin_date,
    COALESCE(
      TRY_TO_DATE(CAST(r.checkout_dt AS STRING), 'yyyyMMdd'),
      TRY_CAST(r.checkout_dt AS DATE)
    ) AS checkout_date,
    COALESCE(
      TRY_CAST(r.checkin_dt AS INT),
      CAST(DATE_FORMAT(TRY_CAST(r.checkin_dt AS DATE), 'yyyyMMdd') AS INT)
    ) AS date_key_int
  FROM rud_2026.reference.legacy_stg_reservations r
),
fx AS (
  SELECT
    f.*,
    COALESCE(
      TRY_CAST(f.rate_dt AS INT),
      CAST(DATE_FORMAT(TRY_CAST(f.rate_dt AS DATE), 'yyyyMMdd') AS INT)
    ) AS rate_key
  FROM rud_2026.reference.legacy_stg_fx f
)
SELECT
  r.res_id,
  r.hotel_code,
  r.date_key_int AS date_key,
  CONCAT(r.first_name, ' ', r.last_name) AS guest_name,
  r.channel_cd,
  r.status_cd,
  DATEDIFF(r.checkout_date, r.checkin_date) AS nights,
  r.rooms,
  DATEDIFF(r.checkout_date, r.checkin_date) * r.rooms AS room_nights,
  r.amount - COALESCE(r.discount, 0) AS net_local,
  CAST(
    (r.amount - COALESCE(r.discount, 0)) / fx.per_usd
    AS DECIMAL(12, 2)
  ) AS net_usd,
  CAST(
    (r.amount - COALESCE(r.discount, 0))
      / NULLIF(DATEDIFF(r.checkout_date, r.checkin_date) * r.rooms, 0)
    AS DECIMAL(12, 2)
  ) AS adr_local
FROM reservations r
INNER JOIN dim_hotel h
  ON h.hotel_code = r.hotel_code
LEFT JOIN fx
  ON fx.rate_key = r.date_key_int
 AND fx.ccy = r.ccy
WHERE r.status_cd <> 'X';
