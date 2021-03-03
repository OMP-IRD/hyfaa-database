FROM postgis/postgis:10-3.1

LABEL maintainer="Jean Pommier jean.pommier@pi-geosolutions.fr"

COPY ./docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY ./update-postgis.sh /usr/local/bin