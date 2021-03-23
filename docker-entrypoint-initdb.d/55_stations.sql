
-----------------------------------------------------
-- Create table
-----------------------------------------------------

-- SEQUENCE: geospatial.stations_id_seq

-- DROP SEQUENCE geospatial.stations_id_seq;

CREATE SEQUENCE geospatial.stations_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 32767
    CACHE 1;

ALTER SEQUENCE geospatial.stations_id_seq
    OWNER TO postgres;

-- Table: geospatial.stations

-- DROP TABLE geospatial.stations;

CREATE TABLE geospatial.stations
(
    id smallint NOT NULL DEFAULT nextval('geospatial.stations_id_seq'::regclass),
    minibasin smallint NOT NULL,
    city character varying(50) COLLATE pg_catalog."default",
    CONSTRAINT stations_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE geospatial.stations
    OWNER to postgres;

-----------------------------------------------------
-- Load data
-----------------------------------------------------

COPY geospatial.stations(id, minibasin, city)
FROM '/docker-entrypoint-initdb.d/data/stations.csv'
DELIMITER ','
CSV HEADER;

-----------------------------------------------------
-- Create a view of the stations, with location extracted from the drainage geometries
-----------------------------------------------------
-- DROP VIEW geospatial.stations_geo;

CREATE OR REPLACE VIEW geospatial.stations_geo
 AS
 SELECT stations.id,
    stations.minibasin,
    stations.city,
    st_closestpoint(geo.wkb_geometry, st_centroid(geo.wkb_geometry)) AS wkb_geometry,
    geo.wkb_geometry AS poly
   FROM geospatial.stations stations
     JOIN geospatial.drainage_mgb_niger_acap geo ON stations.minibasin::numeric = geo.mini
  ORDER BY stations.id;

ALTER TABLE geospatial.stations_geo
    OWNER TO postgres;
