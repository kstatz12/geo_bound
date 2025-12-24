#!/usr/bin/env sh
set -e

# Ensure the volume exists (works even if user forgot to mount, but then writes in-container)
mkdir -p /data/geo /data/postal

echo "==> Step 1: Downloading GeoNames data into /data ..."
/app/download.sh

echo "==> Step 2: Processing into /data/geonames.json ..."
exec python /app/process.py \
  --geo /data/geo/us_geonames.txt \
  --geo /data/geo/ca_geonames.txt \
  --postal /data/postal/us_postal_codes.txt \
  --postal /data/postal/ca_postal_codes.txt \
  /data/geonames.json

