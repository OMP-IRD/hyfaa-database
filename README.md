# pigeosolutions/hyfaa-postgis

This is a copy of the config from the [postgis/postgis](https://github.com/postgis/docker-postgis) config, excluding the tiger extension, which will be of no use for our use-case

It also initializes the DB (structure mostly) for the HYFAA-MGB data.

TODO:
- add SQL views (materialized ?): last 10 days
- parametrize mat. view to get n last days ?
- secure passwords (get them as secrets)
- add pg_tileserv