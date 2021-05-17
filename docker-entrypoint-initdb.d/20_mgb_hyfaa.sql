-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- pgModeler  version: 0.9.1
-- PostgreSQL version: 10.0
-- Project Site: pgmodeler.io
-- Model Author: Jean Pommier -- jp@pi-geosolutions.fr

-- object: hyfaa_backend | type: ROLE --
-- DROP ROLE IF EXISTS hyfaa_backend;
CREATE ROLE hyfaa_backend WITH
	LOGIN
	ENCRYPTED PASSWORD 'hyfaa_backend'
	CONNECTION LIMIT 20;
-- ddl-end --
COMMENT ON ROLE hyfaa_backend IS 'Role used by backend application. Can only perform select queries';
-- ddl-end --

-- object: hyfaa_publisher | type: ROLE --
-- DROP ROLE IF EXISTS hyfaa_publisher;
CREATE ROLE hyfaa_publisher WITH
	LOGIN
	ENCRYPTED PASSWORD 'hyfaa_publisher'
	CONNECTION LIMIT 1;
-- ddl-end --
COMMENT ON ROLE hyfaa_publisher IS 'Role used by HYFAA publisher script.
Can update/insert into data_with tables';
-- ddl-end --


-- Database creation must be done outside a multicommand file.
-- These commands were put in this file only as a convenience.
-- -- object: mgb_hyfaa | type: DATABASE --
-- -- DROP DATABASE IF EXISTS mgb_hyfaa;
-- CREATE DATABASE mgb_hyfaa
-- 	ENCODING = 'UTF8'
-- 	OWNER = postgres;
-- -- ddl-end --
-- COMMENT ON DATABASE mgb_hyfaa IS 'MGB - HYFAA database. Stores data computed using MGB model with HYFAA sequencer.';
-- -- ddl-end --
--

-- object: hyfaa | type: SCHEMA --
-- DROP SCHEMA IF EXISTS hyfaa CASCADE;
CREATE SCHEMA hyfaa;
-- ddl-end --
ALTER SCHEMA hyfaa OWNER TO postgres;
-- ddl-end --
COMMENT ON SCHEMA hyfaa IS 'HYFAA-generated data';
-- ddl-end --

SET search_path TO pg_catalog,public,hyfaa;
-- ddl-end --

-- object: hyfaa.state | type: TABLE --
-- DROP TABLE IF EXISTS hyfaa.state CASCADE;
CREATE TABLE hyfaa.state(
	tablename varchar(20) NOT NULL,
	last_updated timestamp with time zone DEFAULT '1950-01-01T00:00:00.000Z00',
	last_updated_jd double precision DEFAULT 0,
	update_errors smallint NOT NULL DEFAULT 0,
	last_updated_without_errors timestamptz DEFAULT '1950-01-01T00:00:00.000Z00',
	last_updated_without_errors_jd smallint DEFAULT 0,
	CONSTRAINT state_pk PRIMARY KEY (tablename)
);
-- ddl-end --
COMMENT ON TABLE hyfaa.state IS 'Information about the current state of the DB';
-- ddl-end --
COMMENT ON COLUMN hyfaa.state.last_updated IS 'Datetime of last update from the netcdf data file. ';
-- ddl-end --
COMMENT ON COLUMN hyfaa.state.last_updated_jd IS 'Datetime of last update from the netcdf data file. In CNES Julian days (0 is 01/01/1950)';
-- ddl-end --
COMMENT ON COLUMN hyfaa.state.update_errors IS 'Nb of errors during update';
-- ddl-end --
COMMENT ON COLUMN hyfaa.state.last_updated_without_errors IS 'Last time the update did not trigger any error';
-- ddl-end --
COMMENT ON COLUMN hyfaa.state.last_updated_without_errors_jd IS 'Last time the update did not trigger any error. In CNES Julian days';
-- ddl-end --
ALTER TABLE hyfaa.state OWNER TO postgres;
-- ddl-end --

-- object: hyfaa.data_assimilated | type: TABLE --
-- DROP TABLE IF EXISTS hyfaa.data_assimilated CASCADE;
CREATE TABLE hyfaa.data_assimilated(
	cell_id smallint NOT NULL,
	date date NOT NULL,
	elevation_mean float,
	elevation_median float,
	elevation_stddev float,
	elevation_mad float,
	flow_mean float,
	flow_median float,
	flow_stddev float,
	flow_mad float,
	update_time timestamptz,
	is_analysis boolean,
	flow_expected float,
	flow_anomaly float,
	CONSTRAINT data_assimilated_pk PRIMARY KEY (cell_id,date)
);
-- ddl-end --
COMMENT ON TABLE hyfaa.data_assimilated IS 'MGB hydrological data, calculated using HYFAA scheduler, with assimilation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.cell_id IS 'Cell identifier. Called ''cell'' in HYFAA netcdf file, field ''MINI'' in geospatial file';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.date IS 'Date for the values';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.elevation_mean IS 'Water elevation in m. Mean value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.elevation_median IS 'Water elevation in m. Median value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.elevation_stddev IS 'Water elevation in m. Standard deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.elevation_mad IS 'Water elevation in m. Median absolute deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_mean IS 'Stream flow. Mean value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_median IS 'Stream flow. Median value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_stddev IS 'Stream flow. Standard deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_mad IS 'Stream flow. Median absolute  deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_expected IS 'Expected value. Calculated using a floating median, over the flow_median values taken on the day surrounding the current day (+ or - 10 days around), during the previous years';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_anomaly IS 'Represents the anomaly compared to expected data. Formula is 100 * (anomaly - expected) / expected';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.update_time IS 'Time of last update';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.is_analysis IS 'Boolean. Whether the value comes from analysis or control series';
-- ddl-end --
ALTER TABLE hyfaa.data_assimilated OWNER TO postgres;
-- ddl-end --

CREATE INDEX ON hyfaa.data_assimilated (cell_id);
CREATE INDEX ON hyfaa.data_assimilated ("date");

-- object: hyfaa.data_mgbstandard | type: TABLE --
-- DROP TABLE IF EXISTS hyfaa.data_mgbstandard CASCADE;
CREATE TABLE hyfaa.data_mgbstandard(
	cell_id smallint NOT NULL,
	date date NOT NULL,
	elevation_mean float,
	flow_mean float,
	update_time timestamptz,
	is_analysis boolean,
	flow_expected float,
	flow_anomaly float,
	CONSTRAINT data_mgbstandard_pk PRIMARY KEY (cell_id,date)
);
-- ddl-end --
COMMENT ON TABLE hyfaa.data_mgbstandard IS 'MGB hydrological data, calculated using HYFAA scheduler.
Data computed without assimilation.';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_mgbstandard.cell_id IS 'Cell identifier. Called ''cell'' in HYFAA netcdf file, field ''MINI'' in geospatial file';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_mgbstandard.date IS 'Date for the values';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_mgbstandard.elevation_mean IS 'Water elevation in m. Mean value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_mgbstandard.flow_mean IS 'Stream flow. Mean value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_expected IS 'Expected value. Calculated using a floating median, over the flow_mean values taken on the day surrounding the current day (+ or - 10 days around), during the previous years';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_assimilated.flow_anomaly IS 'Represents the anomaly compared to expected data. Formula is 100 * (anomaly - expected) / expected';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_mgbstandard.update_time IS 'Time of last update';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_mgbstandard.is_analysis IS 'Boolean. Whether the value comes from analysis or control series';
-- ddl-end --
ALTER TABLE hyfaa.data_mgbstandard OWNER TO postgres;
-- ddl-end --

CREATE INDEX ON hyfaa.data_mgbstandard (cell_id);
CREATE INDEX ON hyfaa.data_mgbstandard ("date");

-- object: hyfaa.data_forecast | type: TABLE --
-- DROP TABLE IF EXISTS hyfaa.data_forecast CASCADE;
CREATE TABLE hyfaa.data_forecast(
	cell_id smallint NOT NULL,
	date date NOT NULL,
	elevation_mean float,
	elevation_median float,
	elevation_stddev float,
	elevation_mad float,
	flow_mean float,
	flow_median float,
	flow_stddev float,
	flow_mad float,
	update_time timestamptz,
	is_analysis boolean,
	CONSTRAINT data_forecast_pk PRIMARY KEY (cell_id,date)
);


-- ddl-end --
COMMENT ON TABLE hyfaa.data_forecast IS 'MGB hydrological data, calculated using HYFAA scheduler, with assimilation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.cell_id IS 'Cell identifier. Called ''cell'' in HYFAA netcdf file, field ''MINI'' in geospatial file';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.date IS 'Date for the values';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.elevation_mean IS 'Water elevation in m. Mean value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.elevation_median IS 'Water elevation in m. Median value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.elevation_stddev IS 'Water elevation in m. Standard deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.elevation_mad IS 'Water elevation in m. Median absolute deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.flow_mean IS 'Stream flow. Mean value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.flow_median IS 'Stream flow. Median value';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.flow_stddev IS 'Stream flow. Standard deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.flow_mad IS 'Stream flow. Median absolute  deviation';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.update_time IS 'Time of last update';
-- ddl-end --
COMMENT ON COLUMN hyfaa.data_forecast.is_analysis IS 'Boolean. Whether the value comes from analysis or control series';
-- ddl-end --
ALTER TABLE hyfaa.data_forecast OWNER TO postgres;
-- ddl-end --

GRANT USAGE
   ON SCHEMA hyfaa
   TO hyfaa_publisher, hyfaa_backend;

-- object: grant_aa6f65b0de | type: PERMISSION --
GRANT SELECT
   ON TABLE hyfaa.data_assimilated
   TO hyfaa_backend;
-- ddl-end --

-- object: grant_87d6c72a48 | type: PERMISSION --
GRANT SELECT,INSERT,UPDATE,DELETE
   ON TABLE hyfaa.data_assimilated
   TO hyfaa_publisher;
-- ddl-end --

-- object: grant_1ed53ebf44 | type: PERMISSION --
GRANT SELECT
   ON TABLE hyfaa.data_mgbstandard
   TO hyfaa_backend;
-- ddl-end --

-- object: grant_64b914c16f | type: PERMISSION --
GRANT SELECT,INSERT,UPDATE,DELETE
   ON TABLE hyfaa.data_mgbstandard
   TO hyfaa_publisher;
-- ddl-end --

-- object: grant_1ed53ebf44 | type: PERMISSION --
GRANT SELECT
   ON TABLE hyfaa.data_forecast
   TO hyfaa_backend;
-- ddl-end --

-- object: grant_64b914c16f | type: PERMISSION --
GRANT SELECT,INSERT,UPDATE,DELETE
   ON TABLE hyfaa.data_forecast
   TO hyfaa_publisher;
-- ddl-end --

-- object: grant_bd10ef1483 | type: PERMISSION --
GRANT SELECT,INSERT,UPDATE
   ON TABLE hyfaa.state
   TO hyfaa_publisher;

GRANT SELECT
   ON TABLE hyfaa.state
   TO hyfaa_backend;
-- ddl-end --
