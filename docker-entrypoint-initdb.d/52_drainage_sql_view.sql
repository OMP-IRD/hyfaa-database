-----------------------------------------------------
-- Apply the mask (area to exclude) over the drainage table
-- The output is a materialized view, in order to
-- minimize the load on production time
-- Using the opportunity also to optimize the content
-----------------------------------------------------

CREATE MATERIALIZED VIEW  geospatial.drainage_mgb_niger_masked AS
 SELECT dr.mini::smallint AS mini,
    dr.ordem::smallint AS ordem,
    dr.width::real AS width,
    dr.depth::real AS depth,
    dr.wkb_geometry
   FROM geospatial.drainage_mgb_niger_acap dr,
    geospatial.mask mask
  WHERE ordem >= 10  AND NOT st_intersects(dr.wkb_geometry, mask.wkb_geometry);

REFRESH MATERIALIZED VIEW geospatial.drainage_mgb_niger_masked;
CREATE INDEX idx_drainage_mgb_niger_masked_id ON geospatial.drainage_mgb_niger_masked(mini);
--CREATE INDEX idx_drainage_mgb_niger_masked_ordem ON drainage_mgb_niger_masked(ordem);
