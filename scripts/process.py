#!/usr/bin/env python3
"""
Process raw GeoNames feature + postal files into the JSON format used by this library.

Usage:
  python geonames_process.py \
    --geo ./data/geo/us_geonames.txt \
    --geo ./data/geo/ca_geonames.txt \
    --postal ./data/postal/us_postal_codes.txt \
    --postal ./data/postal/ca_postal_codes.txt \
    ./data/geonames.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List

import pandas as pd


ADMIN_CODE_MAP: Dict[str, str] = {
    "01": "AB",
    "02": "BC",
    "03": "MB",
    "04": "NB",
    "05": "NL",
    "07": "NS",
    "08": "ON",
    "09": "PE",
    "10": "QC",
    "11": "SK",
    "12": "YT",
    "13": "NT",
    "14": "NU",
}


GEO_COLUMNS = [
    "geonameid",
    "name",
    "asciiname",
    "alternatenames",
    "latitude",
    "longitude",
    "feature_class",
    "feature_code",
    "country_code",
    "cc2",
    "admin1_code",
    "admin2_code",
    "admin3_code",
    "admin4_code",
    "population",
    "elevation",
    "dem",
    "timezone",
    "modification date",
]

POSTAL_COLUMNS = [
    "country_code",
    "postal_code",
    "place_name",
    "admin_name1",
    "admin_code1",
    "admin_name2",
    "admin_code2",
    "admin_name3",
    "admin_code3",
    "latitude",
    "longitude",
    "accuracy",
]


def parse_args(argv: List[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Process GeoNames files into JSON.")
    p.add_argument("-g", "--geo", action="append", default=[], help="GeoNames features file (repeatable)")
    p.add_argument("-p", "--postal", action="append", default=[], help="GeoNames postal code file (repeatable)")
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Increase verbosity (-v, -vv, ...)",
    )
    p.add_argument("output_file", help="Output JSON file path")
    return p.parse_args(argv)


def vprint(verbose: int, *args) -> None:
    if verbose:
        print(*args, file=sys.stderr)


def load_tsv_no_header(path: str, dtype_overrides: Dict[int, str], verbose: int) -> pd.DataFrame:
    """
    Load tab-delimited, no header. dtype_overrides is {zero_based_col_index: dtype_string}.
    """
    vprint(verbose, f"loading file: {path}")
    dtype = {idx: dtype_str for idx, dtype_str in dtype_overrides.items()}
    return pd.read_csv(
        path,
        sep="\t",
        header=None,
        dtype=dtype,
        keep_default_na=False,  # closer to Elixir: nil/"" handling; we’ll normalize explicitly
        na_values=[],
        engine="python",
    )


def as_geo_df(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = GEO_COLUMNS[: len(df.columns)]
    return df


def only_populated_features(df: pd.DataFrame) -> pd.DataFrame:
    # feature_class == "P" and feature_code not in {"PPLQ","PPLX","PPLW"}
    return df[
        (df["feature_class"] == "P")
        & (~df["feature_code"].isin(["PPLQ", "PPLX", "PPLW"]))
    ].copy()


def as_postal_df(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = POSTAL_COLUMNS[: len(df.columns)]
    return df


_PAREN_RE = re.compile(r"\s*\(.*\)$")


def clean_parentheticals(name: str) -> str:
    return _PAREN_RE.sub("", name)


def clean_postal_name(name: str) -> str:
    name = name.replace("Saint", "St.")
    name = re.sub(r"^Mc\s", "Mc", name)
    name = name.lower()
    name = clean_parentheticals(name)
    return name


def normalize_admin_code(code: str) -> str:
    return ADMIN_CODE_MAP.get(code, code)


def transform_postal(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    # ensure strings
    place = df.get("place_name", "")
    admin = df.get("admin_code1", "")

    df["cleaned_name"] = place.astype(str).map(clean_postal_name)
    df["cleaned_state"] = admin.astype(str).fillna("").map(lambda s: s.upper())
    return df


def transform_geo(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    ascii_name = df.get("asciiname", "")
    admin1 = df.get("admin1_code", "")

    df["cleaned_name"] = ascii_name.astype(str).map(lambda s: s.lower())
    df["cleaned_state"] = admin1.astype(str).fillna("").map(lambda s: normalize_admin_code(s).upper())
    return df


def perform_join(postal_df: pd.DataFrame, geo_df: pd.DataFrame, verbose: int) -> pd.DataFrame:
    if verbose:
        print("", file=sys.stderr)
        vprint(verbose, "joining files ...", end="")

    left = transform_postal(postal_df)
    if verbose:
        print(".", end="", file=sys.stderr)

    right = transform_geo(geo_df)
    if verbose:
        print(".", end="", file=sys.stderr)

    joined = pd.merge(
        left,
        right,
        how="outer",
        on=["cleaned_state", "cleaned_name"],
        suffixes=("", "_right"),
    )

    if verbose:
        print(".", file=sys.stderr)

    return joined

def structure_joined(df: pd.DataFrame) -> pd.DataFrame:
    cols = [
        "cleaned_name",      # <-- join key (not suffixed)
        "alternatenames",
        "latitude_right",
        "longitude_right",
        "cleaned_state",     # <-- join key (not suffixed)
        "postal_code",
        "latitude",
        "longitude",
    ]
    out = df.reindex(columns=cols).copy()
    out.columns = [
        "city_name",
        "alt_name",
        "city_latitude",
        "city_longitude",
        "state_code",
        "postal_code",
        "latitude",
        "longitude",
    ]
    return out


def df_to_json_rows(df: pd.DataFrame) -> List[dict]:
    clean = df.where(pd.notnull(df), None)
    return clean.to_dict(orient="records")


def main(argv: List[str]) -> int:
    ns = parse_args(argv)

    geo_paths = ns.geo or []
    postal_paths = ns.postal or []
    output_path = ns.output_file
    verbose = int(ns.verbose or 0)

    if not geo_paths or not postal_paths or not output_path:
        raise SystemExit(
            "must provide at least one --geo, at least one --postal, and exactly one output_file"
        )

    geo_dfs = []
    vprint(verbose, f"loading geo files: {geo_paths}")
    for p in geo_paths:
        df = load_tsv_no_header(p, dtype_overrides={10: "string"}, verbose=verbose)
        df = only_populated_features(as_geo_df(df))
        geo_dfs.append(df)

    postal_dfs = []
    vprint(verbose, f"loading postal files: {postal_paths}")
    for p in postal_paths:
        df = load_tsv_no_header(p, dtype_overrides={1: "string"}, verbose=verbose)
        df = as_postal_df(df)
        postal_dfs.append(df)

    geo_df = pd.concat(geo_dfs, ignore_index=True) if len(geo_dfs) > 1 else geo_dfs[0]
    postal_df = pd.concat(postal_dfs, ignore_index=True) if len(postal_dfs) > 1 else postal_dfs[0]

    joined = perform_join(postal_df, geo_df, verbose=verbose)
    final_df = structure_joined(joined)

    rows = df_to_json_rows(final_df)

    if verbose:
        vprint(verbose, f"writing to file: {output_path}")

    Path(output_path).write_text(json.dumps(rows, ensure_ascii=False), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
