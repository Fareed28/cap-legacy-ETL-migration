-- Run once in your SQL warehouse before the first pipeline deploy.
-- Does not write to rud_2026.reference.

CREATE SCHEMA IF NOT EXISTS rud_2026.rud_fahamed
COMMENT 'CAP-8 participant schema — Fareed (rud_fahamed)';

-- Optional: peek staging types before trusting fact_stay date casts
-- DESCRIBE TABLE rud_2026.reference.legacy_stg_reservations;
-- DESCRIBE TABLE rud_2026.reference.legacy_stg_fx;
-- DESCRIBE TABLE rud_2026.reference.legacy_stg_hotels;
-- SHOW TABLES IN rud_2026.reference LIKE 'legacy_dw_*';
