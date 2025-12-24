#!/usr/bin/env sh
set -e
set +o pipefail

DATA_DIR="../data"
GEO_DIR="$DATA_DIR/geo"
POSTAL_DIR="$DATA_DIR/postal"

# URLs for US GeoNames data
US_GEODATA_URL="https://download.geonames.org/export/dump/US.zip"
US_POSTAL_GEODATA_URL="https://download.geonames.org/export/zip/US.zip"
US_GEODATA_ZIP_NAME="us_geo_data.zip"
US_GEODATA_POSTAL_ZIP_NAME="us_postal_data.zip"

# URLs for Canada GeoNames data
CA_GEODATA_URL="https://download.geonames.org/export/dump/CA.zip"
CA_POSTAL_GEODATA_URL="https://download.geonames.org/export/zip/CA.zip"
CA_GEODATA_ZIP_NAME="ca_geo_data.zip"
CA_GEODATA_POSTAL_ZIP_NAME="ca_postal_data.zip"

# File names for extracted data
US_GEODATA_FILE_NAME="us_geonames.txt"
US_POSTAL_DATA_FILE_NAME="us_postal_codes.txt"
CA_GEODATA_FILE_NAME="ca_geonames.txt"
CA_POSTAL_DATA_FILE_NAME="ca_postal_codes.txt"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

printf "${BLUE}Creating directories...${NC}\n"
mkdir -p "$DATA_DIR" "$GEO_DIR" "$POSTAL_DIR"

printf "${BLUE}Downloading US geodata...${NC}\n"
curl -sSL "$US_GEODATA_URL" -o "$US_GEODATA_ZIP_NAME"

printf "${BLUE}Downloading US postal geodata...${NC}\n"
curl -sSL "$US_POSTAL_GEODATA_URL" -o "$US_GEODATA_POSTAL_ZIP_NAME"

printf "${BLUE}Downloading Canada geodata...${NC}\n"
curl -sSL "$CA_GEODATA_URL" -o "$CA_GEODATA_ZIP_NAME"

printf "${BLUE}Downloading Canada postal geodata...${NC}\n"
curl -sSL "$CA_POSTAL_GEODATA_URL" -o "$CA_GEODATA_POSTAL_ZIP_NAME"

printf "${BLUE}Unzipping US geodata...${NC}\n"
unzip -o "$US_GEODATA_ZIP_NAME" -d "$GEO_DIR" > /dev/null

printf "${BLUE}Unzipping US postal geodata...${NC}\n"
unzip -o "$US_GEODATA_POSTAL_ZIP_NAME" -d "$POSTAL_DIR" > /dev/null

printf "${BLUE}Renaming US extracted files...${NC}\n"
mv "$GEO_DIR"/US.txt "$GEO_DIR/$US_GEODATA_FILE_NAME"
mv "$POSTAL_DIR"/US.txt "$POSTAL_DIR/$US_POSTAL_DATA_FILE_NAME"

printf "${BLUE}Unzipping Canada geodata...${NC}\n"
unzip -o "$CA_GEODATA_ZIP_NAME" -d "$GEO_DIR" > /dev/null

printf "${BLUE}Unzipping Canada postal geodata...${NC}\n"
unzip -o "$CA_GEODATA_POSTAL_ZIP_NAME" -d "$POSTAL_DIR" > /dev/null

printf "${BLUE}Renaming CA extracted files...${NC}\n"
mv "$GEO_DIR"/CA.txt "$GEO_DIR/$CA_GEODATA_FILE_NAME"
mv "$POSTAL_DIR"/CA.txt "$POSTAL_DIR/$CA_POSTAL_DATA_FILE_NAME"

printf "${GREEN}✅ All steps completed successfully.${NC}\n"

