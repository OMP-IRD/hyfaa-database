
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
-- Aggregate the last 15d values in a json field
-----------------------------------------------------

CREATE OR REPLACE VIEW hyfaa.data_with_assim_aggregate_json
 AS
 WITH data_15d_with_average AS (
	WITH average AS (SELECT cell_id, avg(flow_median) AS flow_median_yearly_average
						FROM hyfaa.data_with_assim
						GROUP BY cell_id),
	data_15d AS (SELECT * FROM hyfaa.data_with_assim
						WHERE date IN (SELECT date from hyfaa.data_with_assim
						GROUP BY date ORDER BY date DESC LIMIT 15)
				)
	SELECT data_15d.*, average.flow_median_yearly_average
	FROM data_15d, average
	WHERE data_15d.cell_id = average.cell_id
)
SELECT cell_id, flow_median_yearly_average,
       json_agg(
          json_build_object(
      		'date', date,
      		'flow_median', flow_median,
      		'flow_anomaly', CASE WHEN flow_median_yearly_average = 0 THEN null ELSE 100 * (flow_median - flow_median_yearly_average) / flow_median_yearly_average END
      		)
	        ORDER BY date DESC
        ) AS values
FROM data_15d_with_average AS v
GROUP BY cell_id, flow_median_yearly_average
ORDER BY cell_id;

ALTER TABLE hyfaa.data_with_assim_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_with_assim_aggregate_json IS 'Keep only the flow median. Compute the average for each minibasin. Use it to compute the anomaly. Aggregate the results for the n last days into a json field';



-----------------------------------------------------
-- Join the preceding view with the geo data.
-- Make it a Materialized View, in order to reduce load
-----------------------------------------------------

CREATE MATERIALIZED VIEW hyfaa.data_with_assim_aggregate_geo
AS
 SELECT data.*,
        geo.ordem,
        geo.width,
        geo.depth,
        ST_Transform(geo.wkb_geometry, 4326)::geometry(Geometry,4326) AS wkb_geometry
  FROM hyfaa.data_with_assim_aggregate_json AS data,
       geospatial.drainage_mgb_niger_masked AS geo
  WHERE geo.mini = data.cell_id
  ORDER BY cell_id
WITH DATA;

ALTER TABLE hyfaa.data_with_assim_aggregate_geo
    OWNER TO postgres;

COMMENT ON MATERIALIZED VIEW hyfaa.data_with_assim_aggregate_geo
    IS 'Combine the geometries for the minibasins with the most recent values (n last days, stored in a json object)';
