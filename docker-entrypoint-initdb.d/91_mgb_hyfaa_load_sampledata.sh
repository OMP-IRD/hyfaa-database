#!/bin/bash
# Load sample data
set -e

if [[ "$WITH_SAMPLE_DATA" == "yes" ]]; then
  echo ... Load sample data ...
  psql -d $POSTGRES_DB -U $POSTGRES_USER -c "COPY hyfaa.data_assimilated FROM PROGRAM 'gunzip -c /docker-entrypoint-initdb.d/data/data_assimilated_sample.csv.gz' delimiter ',' CSV HEADER;"
  psql -d $POSTGRES_DB -U $POSTGRES_USER -c "COPY hyfaa.data_mgbstandard FROM PROGRAM 'gunzip -c /docker-entrypoint-initdb.d/data/data_mgbstandard_stations_sample.csv.gz' delimiter ',' CSV HEADER;"
  psql -d $POSTGRES_DB -U $POSTGRES_USER -c "COPY hyfaa.data_forecast FROM PROGRAM 'gunzip -c /docker-entrypoint-initdb.d/data/data_forecast_stations_sample.csv.gz' delimiter ',' CSV HEADER;"
fi