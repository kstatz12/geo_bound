#!/usr/bin/env sh
set -e

# Ensure the volume exists (works even if user forgot to mount, but then writes in-container)
mkdir -p /data/geo /data/postal

echo "==> Step 1: Downloading GeoNames data into /data ..."
/app/download.sh

echo "==> Step 2: Processing into /data/geonames.json ..."
python /app/process.py \
  --geo /data/geo/us_geonames.txt \
  --geo /data/geo/ca_geonames.txt \
  --postal /data/postal/us_postal_codes.txt \
  --postal /data/postal/ca_postal_codes.txt \
  /data/geonames.json

echo "==> Step 3: Building GeoHash Index into /data/geohash.json ..."
python /app/geohash.py /data/geonames.json /data/geohash.json --precision 6

echo "==> Step 4: Cleanup downloaded files"
rm -rf /data/postal
rm -rf /data/geo
