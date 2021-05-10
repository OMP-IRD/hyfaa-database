
-----------------------------------------------------
-- Add a comment and some indexes on the drainage geodata
-- the indexes will improve the performance on the following view
-----------------------------------------------------

CREATE UNIQUE INDEX mini_idx ON geospatial.drainage_mgb_niger_acap (mini);
CREATE INDEX ordem ON geospatial.drainage_mgb_niger_acap (ordem DESC);
COMMENT ON TABLE geospatial.drainage_mgb_niger_acap IS 'Drainage minibasins on Niger Watershed Basin, as defined by MGB model.';


-----------------------------------------------------
-- Apply the mask (area to exclude) over the drainage table
-- Using the opportunity also to optimize/clean the content
-----------------------------------------------------

CREATE OR REPLACE VIEW  geospatial.drainage_mgb_niger_masked AS
 SELECT dr.mini::smallint AS mini,
    dr.ordem::smallint AS ordem,
    dr.width::real AS width,
    dr.depth::real AS depth,
    ST_Transform(dr.wkb_geometry, 4326)::geometry(Geometry,4326) AS wkb_geometry
   FROM geospatial.drainage_mgb_niger_acap dr,
    geospatial.mask mask
  WHERE ordem >= 10  AND NOT st_intersects(dr.wkb_geometry, mask.wkb_geometry);


COMMENT ON  VIEW geospatial.drainage_mgb_niger_masked IS 'Drainage minibasins on Niger Watershed Basin, as defined by MGB model. With a geographical mask applied to remove out-of-scope area.';


-----------------------------------------------------
-- Join the hyfaa *_aggregate_json views with the geo data.
-- Make them a Materialized View, in order to reduce load
-----------------------------------------------------

-- on assimilated data
CREATE MATERIALIZED VIEW hyfaa.data_with_assim_aggregate_geo
AS
 SELECT data.*,
        geo.ordem,
        ROUND(geo.width::numeric) AS width,
        ROUND(geo.depth::numeric, 2) AS depth,
        ST_Transform(geo.wkb_geometry, 4326)::geometry(Geometry,4326) AS wkb_geometry
  FROM hyfaa.data_assimilated_aggregate_json AS data,
       geospatial.drainage_mgb_niger_masked AS geo
  WHERE geo.mini = data.cell_id
  ORDER BY cell_id
WITH DATA;
CREATE UNIQUE INDEX ON hyfaa.data_with_assim_aggregate_geo (cell_id);

ALTER TABLE hyfaa.data_with_assim_aggregate_geo
    OWNER TO postgres;

COMMENT ON MATERIALIZED VIEW hyfaa.data_with_assim_aggregate_geo
    IS 'Combine the geometries for the minibasins with the most recent values (n last days, stored in a json object)';


-- on mgbstandard data
CREATE MATERIALIZED VIEW hyfaa.data_with_mgbstandard_aggregate_geo
AS
 SELECT data.*,
        geo.ordem,
        ROUND(geo.width::numeric) AS width,
        ROUND(geo.depth::numeric, 2) AS depth,
        ST_Transform(geo.wkb_geometry, 4326)::geometry(Geometry,4326) AS wkb_geometry
  FROM hyfaa.data_mgbstandard_aggregate_json AS data,
       geospatial.drainage_mgb_niger_masked AS geo
  WHERE geo.mini = data.cell_id
  ORDER BY cell_id
WITH DATA;
CREATE UNIQUE INDEX ON hyfaa.data_with_mgbstandard_aggregate_geo (cell_id);

ALTER TABLE hyfaa.data_with_mgbstandard_aggregate_geo
    OWNER TO postgres;

COMMENT ON MATERIALIZED VIEW hyfaa.data_with_mgbstandard_aggregate_geo
    IS 'Combine the geometries for the minibasins with the most recent values (n last days, stored in a json object)';


-----------------------------------------------------
-- Create a simple view that abstracts which data source
-- we will use for the visualization. For now, we will
-- use mgbstandard
-----------------------------------------------------
CREATE OR REPLACE VIEW  hyfaa.data_aggregated_geo AS
    SELECT * FROM hyfaa.data_with_mgbstandard_aggregate_geo;
