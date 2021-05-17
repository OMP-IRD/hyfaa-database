-----------------------------------------------------
-- Aggregate the last 15d values in a json field
-----------------------------------------------------



-----------------------------------------------------
-- on assimilated data
DROP MATERIALIZED VIEW IF EXISTS hyfaa.data_assimilated_with_floating_avg_and_anomaly CASCADE;

CREATE OR REPLACE VIEW hyfaa.data_assimilated_aggregate_json
 AS
SELECT cell_id,
       json_agg(
          json_build_object(
      		'date', date,
      		'flow', ROUND(flow_median),
      		'flow_anomaly', ROUND(flow_anomaly)
      		)
	        ORDER BY "date" DESC
        ) AS values
FROM hyfaa.data_assimilated
WHERE "date" IN (SELECT "date" from hyfaa.data_assimilated
						GROUP BY "date" ORDER BY "date" DESC LIMIT 15)
GROUP BY cell_id
ORDER BY cell_id;

ALTER TABLE hyfaa.data_assimilated_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_assimilated_aggregate_json IS
    'Round the values.
    Aggregate the results for the n last days into a json field';



-----------------------------------------------------
-- on mgbstandard data
DROP MATERIALIZED VIEW IF EXISTS hyfaa.data_mgbstandard_with_floating_avg_and_anomaly CASCADE;

CREATE OR REPLACE VIEW hyfaa.data_mgbstandard_aggregate_json
 AS
SELECT cell_id,
       json_agg(
          json_build_object(
      		'date', date,
      		'flow', ROUND(flow_mean),
      		'flow_anomaly', ROUND(flow_anomaly)
      		)
	        ORDER BY "date" DESC
        ) AS values
FROM hyfaa.data_mgbstandard
WHERE "date" IN (SELECT "date" from hyfaa.data_mgbstandard
						GROUP BY "date" ORDER BY "date" DESC LIMIT 15)
GROUP BY cell_id
ORDER BY cell_id;

ALTER TABLE hyfaa.data_mgbstandard_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_mgbstandard_aggregate_json IS
    'Round the values.
    Aggregate the results for the n last days into a json field';


-----------------------------------------------------
-- Functions for the API
-----------------------------------------------------

CREATE OR REPLACE FUNCTION hyfaa.get_assimilated_values_for_minibasin(mini integer, timeinterval varchar default '1 year')
	RETURNS json AS
$$
DECLARE jsonarray json;
BEGIN
		WITH tbl AS (
		    SELECT "date",
		           ROUND(flow_median::numeric) AS flow,
		           ROUND(flow_mad::numeric) AS flow_mad,
		           ROUND(flow_expected::numeric) AS expected
		    FROM hyfaa.data_assimilated
		    WHERE cell_id=mini AND "date" > now()-timeinterval::interval
		    ORDER BY "date" DESC
		)
		SELECT array_to_json(array_agg(row_to_json(tbl))) FROM tbl INTO jsonarray;
		return jsonarray;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION hyfaa.get_assimilated_values_for_minibasin(integer, character varying)
    IS 'Get assimilated data as aggregated json array, rounding the values to closest integer';


CREATE OR REPLACE FUNCTION hyfaa.get_mgbstandard_values_for_minibasin(mini integer, timeinterval varchar default '1 year')
	RETURNS json AS
$$
DECLARE jsonarray json;
        BEGIN
        WITH tbl AS (
            SELECT 	"date",
		           ROUND(flow_mean::numeric) AS flow,
		           ROUND(flow_expected::numeric) AS expected
            FROM  hyfaa.data_mgbstandard
            WHERE cell_id=mini AND "date" > now()-timeinterval::interval
			ORDER BY "date" DESC
        )
        SELECT array_to_json(array_agg(row_to_json(tbl))) FROM tbl INTO jsonarray;
		return jsonarray;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION hyfaa.get_mgbstandard_values_for_minibasin(integer, character varying)
    IS 'Get mgbstandard data as aggregated json array (array of {date, flow_mean, floating mean as "expected"} values),
        rounding the values to closest integer';


CREATE OR REPLACE FUNCTION hyfaa.get_forecast_values_for_minibasin(mini integer, timeinterval varchar default '1 year')
	RETURNS json AS
$$
DECLARE jsonarray json;
BEGIN
		WITH tbl AS (
            SELECT 	"date",
					 ROUND(flow_median::numeric) AS flow,
					 ROUND(flow_mad::numeric,1) AS flow_mad
            FROM  hyfaa.data_forecast
            WHERE cell_id=mini AND "date" > now()-timeinterval::interval
			ORDER BY "date" DESC
        )
        SELECT array_to_json(array_agg(row_to_json(tbl))) FROM tbl INTO jsonarray;
		return jsonarray;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION hyfaa.get_forecast_values_for_minibasin(integer, character varying)
    IS 'Get forecast data as aggregated json array. ';
