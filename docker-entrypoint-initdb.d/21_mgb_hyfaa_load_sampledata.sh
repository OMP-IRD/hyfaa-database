#!/bin/bash
# Load sample data
set -e

if [[ "$WITH_SAMPLE_DATA" == "yes" ]]; then
  echo ... Load sample data ...
  psql -d $POSTGRES_DB -U $POSTGRES_USER -c "COPY hyfaa.data_with_assim FROM PROGRAM 'gunzip -c /docker-entrypoint-initdb.d/data/data_with_assim_sample.sql.gz';"
fi