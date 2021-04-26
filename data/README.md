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


## Database samples
For development purpose, data samples are provided and can be loaded on startup by setting WITH_SAMPLE=yes
The samples are generated from a database that has been fed with data in the regular way, and running the following commands

### From your machine, with container port 5432 open to host 5432 
* **mgbstandard and assimilated data**: 16-days samples for all minibasins (assuming you've run the scheduler this day, else you should adjust the period)
+ all-time samples for only the stations
```
# data_assimilated
psql -h localhost -p 5432 -U postgres -d mgb_hyfaa \
    -c "COPY (SELECT * from hyfaa.data_assimilated \
              WHERE (\"date\" > now() - '16 days'::interval \
	            	AND cell_id in (SELECT mini FROM geospatial.drainage_mgb_niger_acap WHERE ordem >=10)) \
                OR (\"date\" > now() - '2 years'::interval \
                    AND cell_id in (SELECT minibasin FROM geospatial.stations))) \
        to stdout DELIMITER ',' CSV HEADER " \
    | gzip > docker-entrypoint-initdb.d/data/data_assimilated_sample.csv.gz

# data_mgbstandard
psql -h localhost -p 5432 -U postgres -d mgb_hyfaa \
     -c "COPY (SELECT * from hyfaa.data_mgbstandard \
              WHERE (\"date\" > now() - '16 days'::interval \
	            	AND cell_id in (SELECT mini FROM geospatial.drainage_mgb_niger_acap WHERE ordem >=10)) \
                OR (\"date\" > now() - '2 years'::interval \
                    AND cell_id in (SELECT minibasin FROM geospatial.stations))) \
        to stdout DELIMITER ',' CSV HEADER " \
     | gzip > docker-entrypoint-initdb.d/data/data_mgbstandard_stations_sample.csv.gz
```
* **forecast**: all-time samples for only the stations

```
# data_forecast
psql -h localhost -p 5432 -U postgres -d mgb_hyfaa \
     -c "COPY (SELECT * from hyfaa.data_forecast \
                WHERE cell_id in (SELECT minibasin FROM geospatial.stations) \
                AND "date" in (SELECT DISTINCT "date" from hyfaa.data_forecast \
                                ORDER BY "date" DESC LIMIT 10) \
        ) to stdout DELIMITER ',' CSV HEADER " \
     | gzip > docker-entrypoint-initdb.d/data/data_forecast_stations_sample.csv.gz
```