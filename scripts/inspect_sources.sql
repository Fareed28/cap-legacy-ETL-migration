-- Half A day-1: confirm types + golden names before chasing checksum ghosts.

SHOW TABLES IN rud_2026.reference LIKE 'legacy_*';

DESCRIBE TABLE rud_2026.reference.legacy_stg_hotels;
DESCRIBE TABLE rud_2026.reference.legacy_stg_reservations;
DESCRIBE TABLE rud_2026.reference.legacy_stg_fx;

SELECT 'hotels' AS src, COUNT(*) AS n FROM rud_2026.reference.legacy_stg_hotels
UNION ALL
SELECT 'reservations', COUNT(*) FROM rud_2026.reference.legacy_stg_reservations
UNION ALL
SELECT 'fx', COUNT(*) FROM rud_2026.reference.legacy_stg_fx;

-- Sample date-like columns (adjust if names differ)
SELECT checkin_dt, checkout_dt, typeof(checkin_dt) AS checkin_type, typeof(checkout_dt) AS checkout_type
FROM rud_2026.reference.legacy_stg_reservations
LIMIT 5;

SELECT rate_dt, typeof(rate_dt) AS rate_type, ccy, per_usd
FROM rud_2026.reference.legacy_stg_fx
LIMIT 5;
