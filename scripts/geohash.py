#!/usr/bin/env python3
"""
Build a geohash-bucket index from your GeoNames-style JSON list.

Input:  JSON array of records like:
  {
    "postal_code": "60601" | null,
    "latitude": 41.88531 | null,
    "longitude": -87.62191 | null,
    ...
  }

Output: JSON object mapping geohash-prefix -> list of [postal_code, lat, lng]
  {
    "dp3wj": [["60601", 41.88531, -87.62191], ...],
    ...
  }

Usage:
  pip install geohash2
  python build_zip_geohash_index.py geonames.json zip_geohash_index.json --precision 6
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

import geohash2  # pip install geohash2


def is_number(x: Any) -> bool:
    return isinstance(x, (int, float)) and not (isinstance(x, float) and math.isnan(x))


def extract_zip_lat_lng(rec: Dict[str, Any]) -> Optional[Tuple[str, float, float]]:
    """
    Extract ONLY postal-code points.

    We intentionally *do not* fall back to city_latitude/city_longitude because that
    changes semantics (city centroid != zip centroid).
    """
    zipc = rec.get("postal_code")
    lat = rec.get("latitude")
    lng = rec.get("longitude")

    if zipc is None:
        return None
    if not is_number(lat) or not is_number(lng):
        return None

    return str(zipc), float(lat), float(lng)


def build_index(records: Iterable[Dict[str, Any]], precision: int) -> Dict[str, List[List[Any]]]:
    buckets: Dict[str, List[List[Any]]] = defaultdict(list)

    kept = 0
    skipped = 0

    for rec in records:
        got = extract_zip_lat_lng(rec)
        if got is None:
            skipped += 1
            continue

        zipc, lat, lng = got
        key = geohash2.encode(lat, lng, precision=precision)
        buckets[key].append([zipc, lat, lng])
        kept += 1

    # print stats to stderr (so it doesn't pollute redirected output)
    print(f"kept={kept} skipped={skipped} buckets={len(buckets)} precision={precision}", file=sys.stderr)

    # deterministic ordering (useful for diffs)
    return {k: buckets[k] for k in sorted(buckets.keys())}


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("input_json", type=Path, help="Input JSON file (array of records)")
    ap.add_argument("output_json", type=Path, help="Output index JSON file (object of buckets)")
    ap.add_argument("--precision", type=int, default=6, help="Geohash prefix length (default: 6)")
    ap.add_argument("--compact", action="store_true", help="Compact JSON output (no pretty formatting)")
    return ap.parse_args()


def main() -> None:
    args = parse_args()

    raw = args.input_json.read_text(encoding="utf-8")
    data = json.loads(raw)

    if not isinstance(data, list):
        raise SystemExit("ERROR: expected top-level JSON array (list of records).")

    index = build_index(data, precision=args.precision)

    if args.compact:
        out_text = json.dumps(index, ensure_ascii=False, separators=(",", ":"))
    else:
        out_text = json.dumps(index, ensure_ascii=False, indent=2)

    args.output_json.write_text(out_text, encoding="utf-8")
    print(f"Wrote: {args.output_json}", file=sys.stderr)


if __name__ == "__main__":
    main()
