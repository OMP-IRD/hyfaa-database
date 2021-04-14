
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

COMMENT ON TABLE geospatial.stations IS 'Stations are virtual. They feature minibasins of interest (join them with drainage_mgb data on "mini" field)';

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

-- View: geospatial.stations_geo

-- DROP VIEW geospatial.stations_geo;

CREATE OR REPLACE VIEW geospatial.stations_geo
 AS
 SELECT stations.id,
    stations.minibasin,
    stations.city,
    ST_Transform(st_closestpoint(geo.wkb_geometry, st_centroid(geo.wkb_geometry)), 4326)::geometry(Geometry,4326) AS wkb_geometry
   FROM geospatial.stations stations
     JOIN geospatial.drainage_mgb_niger_acap geo ON stations.minibasin::numeric = geo.mini
  ORDER BY stations.id;

COMMENT ON VIEW geospatial.stations_geo IS 'Stations are virtual. They feature minibasins of interest, close to a key City.';

ALTER TABLE geospatial.stations_geo
    OWNER TO postgres;

GRANT ALL ON TABLE geospatial.stations_geo TO postgres;


GRANT USAGE
   ON SCHEMA geospatial
   TO hyfaa_backend;

GRANT SELECT
ON TABLE geospatial.stations
TO hyfaa_backend;

GRANT SELECT
ON TABLE geospatial.stations_geo
TO hyfaa_backend;