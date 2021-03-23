# Transform the data into a suitable format for the DB

The source format is shapefile. In order to ease the import on DB creation, we dump it into a SQL format suitable for PostGIS

ogr2ogr tool provides such facility (ogr2ogr is part of the GDAL suite and is available on all platforms)

`ogr2ogr -f PGDump ../docker-entrypoint-initdb.d/50_data_drainage.sql
    Drainage_MGB_Niger_ACAP/Drainage_MGB_Niger_ACAP.shp
    -lco SCHEMA=geospatial -nlt MULTILINESTRING`

 Or even better, we compress it on the go:

```
ogr2ogr -f PGDump /vsistdout/ Drainage_MGB_Niger_ACAP/Drainage_MGB_Niger_ACAP.shp \
    -lco SCHEMA=geospatial -nlt MULTILINESTRING | gzip -9 \
    > ../docker-entrypoint-initdb.d/50_data_drainage.sql.gz
```
And we even get a big compression gain.

Then you need to re-build the docker image. It will include the SQL dump and load it into the DB


## exclusion_mask
For the exclusion mask:
```
ogr2ogr -f PGDump /vsistdout/ exclusion_mask/mask.shp      -lco SCHEMA=geospatial -nlt POLYGON  | gzip -9     > ../docker-entrypoint-initdb.d/51_exclusion_mask.sql.gz
```
