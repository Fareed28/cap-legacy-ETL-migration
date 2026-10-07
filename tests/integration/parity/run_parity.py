# hotel_dw_etl — integration parity harness
# Compares rud_fahamed.* to rud_2026.reference.legacy_dw_*.
#
#   --strict-parity true|false   fail on aggregate mismatches when true (CI/staging)

from __future__ import annotations

import argparse

try:
    from config import TABLES
except ImportError:
    from tests.integration.parity.config import TABLES  # type: ignore


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="hotel_dw_etl parity checksums")
    parser.add_argument(
        "--strict-parity",
        default="false",
        help="true to fail when any table (including aggregates) mismatches",
    )
    # Accept legacy flag during transition
    parser.add_argument("--require-half-b", default=None, help=argparse.SUPPRESS)
    args, _unknown = parser.parse_known_args(argv)
    return args


def _as_bool(value: str) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y"}


def _fingerprint(df, keys: list[str]):
    # Sum xxhash64 as DECIMAL(38,0) — BIGINT SUM overflows under spark.sql.ansi.enabled.
    return df.sort(*keys).selectExpr(
        "COUNT(*) AS row_cnt",
        "COALESCE(SUM(CAST(xxhash64(*) AS DECIMAL(38,0))), CAST(0 AS DECIMAL(38,0))) AS checksum",
    ).collect()[0]


def _table_exists(table: str) -> bool:
    try:
        spark.sql(f"DESCRIBE TABLE {table}").limit(1).collect()
        return True
    except Exception:
        return False


def _cast_to_golden_schema(table: str, golden: str):
    """Align column order/types to golden so EXCEPT does not fail on INT vs BOOLEAN etc."""
    from pyspark.sql import functions as F

    gdf = spark.table(golden)
    tdf = spark.table(table)
    missing = [f.name for f in gdf.schema.fields if f.name not in tdf.columns]
    if missing:
        raise ValueError(f"{table} missing columns vs golden: {missing}")
    return tdf.select(
        *[F.col(f.name).cast(f.dataType).alias(f.name) for f in gdf.schema.fields]
    )


def _diff_counts(target: str, golden: str):
    gdf = spark.table(golden).select(*[f.name for f in spark.table(golden).schema.fields])
    tdf = _cast_to_golden_schema(target, golden)
    only_tgt = tdf.exceptAll(gdf).count()
    only_gld = gdf.exceptAll(tdf).count()
    return only_tgt, only_gld


def run_parity(strict_parity: bool = False) -> int:
    rows = []
    core_failed = False
    agg_failed = False

    for name, meta in TABLES.items():
        target = meta["target"]
        golden = meta["golden"]
        keys = meta["keys"]
        layer = meta.get("layer", meta.get("owner", "core"))
        is_agg = layer == "aggregate" or layer == "B"

        if not _table_exists(golden):
            status, detail = "ERROR", f"golden missing: {golden}"
            rows.append((name, layer, status, None, None, None, None, detail))
            core_failed |= not is_agg
            agg_failed |= is_agg
            continue

        if not _table_exists(target):
            status = "PENDING" if is_agg and not strict_parity else "FAIL"
            detail = f"target missing: {target}"
            rows.append((name, layer, status, None, None, None, None, detail))
            core_failed |= not is_agg
            agg_failed |= is_agg
            continue

        try:
            gdf = spark.table(golden)
            tdf = _cast_to_golden_schema(target, golden)
            t = _fingerprint(tdf, keys)
            g = _fingerprint(gdf, keys)
            only_t, only_g = _diff_counts(target, golden)
            ok = (
                t["row_cnt"] == g["row_cnt"]
                and t["checksum"] == g["checksum"]
                and only_t == 0
                and only_g == 0
            )
            status = "PASS" if ok else "FAIL"
            detail = "" if ok else f"only_in_target={only_t}, only_in_golden={only_g}"
            rows.append(
                (
                    name,
                    layer,
                    status,
                    t["row_cnt"],
                    g["row_cnt"],
                    str(t["checksum"]),
                    str(g["checksum"]),
                    detail,
                )
            )
            if not ok:
                core_failed |= not is_agg
                agg_failed |= is_agg
        except Exception as exc:  # noqa: BLE001
            status, detail = "ERROR", str(exc)[:500]
            rows.append((name, layer, status, None, None, None, None, detail))
            core_failed |= not is_agg
            agg_failed |= is_agg
            print(f"{name}: {detail}")

    result = spark.createDataFrame(
        rows,
        schema=(
            "table_name string, layer string, status string, "
            "target_rows long, golden_rows long, "
            "target_checksum string, golden_checksum string, detail string"
        ),
    )
    result.show(truncate=False)
    try:
        (
            result.write.mode("overwrite")
            .option("overwriteSchema", "true")
            .saveAsTable("rud_2026.rud_fahamed.parity_results")
        )
        print("Wrote rud_2026.rud_fahamed.parity_results")
    except Exception as exc:  # noqa: BLE001
        print(f"Could not persist parity_results: {exc}")

    if core_failed:
        print("CORE PARITY FAILED (dimensions/facts)")
        return 1
    if strict_parity and agg_failed:
        print("AGGREGATE PARITY FAILED")
        return 1
    if agg_failed:
        print("CORE PASS — aggregates pending/failing (strict_parity=false)")
    else:
        print("ALL TABLES PASS")
    return 0


if __name__ == "__main__":
    ns = _parse_args()
    strict = _as_bool(ns.strict_parity)
    if ns.require_half_b is not None:
        strict = _as_bool(ns.require_half_b)
    print(f"strict_parity={strict}")
    code = run_parity(strict_parity=strict)
    # Do not sys.exit(0): Databricks/IPython treats SystemExit as task failure.
    if code != 0:
        raise RuntimeError(f"Parity failed with code {code}")
