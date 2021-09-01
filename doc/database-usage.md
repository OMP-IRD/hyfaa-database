# DB usage

This database is used by
* the import script
* the backend API
* the pg_tileserv service

## Import script
The hyfaa data is, in the first step ([scheduler](https://github.com/OMP-IRD/hyfaa-scheduler)), written into netCDF files.
Those file are not that practical for geospatial data viz online, so they are
then published into this database, using an import script. For now, this
script is located in the [hyfaa-backend repo](https://github.com/OMP-IRD/hyfaa-backend/tree/main/src/scripts) (in the end, it would make sens
to move it into the scheduler repo).

The script is called hyfaa_netcdf2DB.py.

## Backend API
The [backend]((https://github.com/OMP-IRD/hyfaa-backend/) provides an API giving access to the data, at the stations
' location. Stations being, actually, a selection of highlighted minibasins
. No relation with the hydrosat virtual stations.

The API is accessible at https://hyfaa.pigeo.fr/api/v1/. There is a swagger
 documentation, it should be enough to use it.
 
## pg_tileserv service
[pg_tileserv](https://github.com/CrunchyData/pg_tileserv/) is a tool serving
 vector tiles from postgis geospatial tables. This is used to serve the tiles
for the minibasins and the stations. A list of available layers is shown at 
https://hyfaa.pigeo.fr/tiles/
  
The minibasins default layer is `hyfaa.data_aggregated_geo`. It provides a
 `values` attribute, that is a json aggregate of the flow and flow_anomaly
  values for the last 15 days.

 