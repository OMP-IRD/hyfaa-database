-----------------------------------------------------
-- Aggregate the last 15d values in a json field
-----------------------------------------------------

-- on assimilated data
CREATE OR REPLACE VIEW hyfaa.data_assimilated_aggregate_json
 AS
 WITH has_average AS (
	WITH has_mean_over_ddoy AS (SELECT * FROM (
		( SELECT *, date_part('doy', "date") AS ddoy FROM hyfaa.data_assimilated WHERE "date" >= now() - '1 year'::interval ) AS d
		LEFT JOIN
		( SELECT cell_id, date_part('doy', "date") AS ddoy, avg(flow_median) AS dayly_avg_over_years
				FROM hyfaa.data_assimilated
				GROUP BY cell_id, ddoy
				ORDER BY ddoy DESC, cell_id ) AS by_ddoy
		USING (cell_id, ddoy)
		)
	)
	SELECT *,
		avg(flow_median) OVER ( PARTITION BY cell_id
							 ORDER BY "date" DESC
							 ROWS BETWEEN 15 preceding AND 15 FOLLOWING )
							 AS average
	FROM has_mean_over_ddoy
)
SELECT cell_id,
       json_agg(
          json_build_object(
      		'date', date,
      		'flow', ROUND(flow_median),
      		'flow_anomaly', CASE WHEN average = 0 THEN null ELSE ROUND((100 * (flow_median - average) / average)::numeric) END
      		)
	        ORDER BY "date" DESC
        ) AS values
FROM has_average
WHERE "date" IN (SELECT "date" from hyfaa.data_assimilated
						GROUP BY "date" ORDER BY "date" DESC LIMIT 15)
GROUP BY cell_id
ORDER BY cell_id;

ALTER TABLE hyfaa.data_assimilated_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_assimilated_aggregate_json IS
    'Keep only the flow median. Compute a floating average for each minibasin
    (average over the day +/- 15days, but spanning over the years.)
    Use it to compute the anomaly. Round the values.
    Aggregate the results for the n last days into a json field';

-- on mgbstandard data
CREATE OR REPLACE VIEW hyfaa.data_mgbstandard_aggregate_json
 AS
WITH has_average AS (
	WITH has_mean_over_ddoy AS (SELECT * FROM (
		( SELECT *, date_part('doy', "date") AS ddoy FROM hyfaa.data_mgbstandard WHERE "date" >= now() - '1 year'::interval ) AS d
		LEFT JOIN
		( SELECT cell_id, date_part('doy', "date") AS ddoy, avg(flow_mean) AS dayly_avg_over_years
				FROM hyfaa.data_mgbstandard
				GROUP BY cell_id, ddoy
				ORDER BY ddoy DESC, cell_id ) AS by_ddoy
		USING (cell_id, ddoy)
		)
	)
	SELECT *,
		avg(flow_mean) OVER ( PARTITION BY cell_id
							 ORDER BY "date" DESC
							 ROWS BETWEEN 15 preceding AND 15 FOLLOWING )
							 AS average
	FROM has_mean_over_ddoy
)
SELECT cell_id,
       json_agg(
          json_build_object(
      		'date', date,
      		'flow', ROUND(flow_mean),
      		'flow_anomaly', CASE WHEN average = 0 THEN null ELSE ROUND((100 * (flow_mean - average) / average)::numeric) END
      		)
	        ORDER BY "date" DESC
        ) AS values
FROM has_average
WHERE "date" IN (SELECT "date" from hyfaa.data_assimilated
						GROUP BY "date" ORDER BY "date" DESC LIMIT 15)
GROUP BY cell_id
ORDER BY cell_id;

ALTER TABLE hyfaa.data_mgbstandard_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_mgbstandard_aggregate_json IS
    'Keep only the flow mean. Compute a floating average for each minibasin
    (average over the day +/- 15days, but spanning over the years.)
    Use it to compute the anomaly. Round the values.
    Aggregate the results for the n last days into a json field';




-----------------------------------------------------
-- Functions for the API
-----------------------------------------------------

CREATE OR REPLACE FUNCTION hyfaa.get_assimilated_values_for_minibasin(mini integer, timeinterval varchar default '1 year')
	RETURNS json AS
$$
DECLARE jsonarray json;
BEGIN
		WITH tbl AS (WITH expect AS (SELECT cell_id, date_part('doy', "date") AS ddoy, avg(flow_median) AS expected
			FROM hyfaa.data_assimilated
			GROUP BY cell_id, date_part('doy', "date")
			),
			d_with_assim AS (
				  SELECT cell_id, "date", flow_median, flow_mad, date_part('doy', "date") AS ddoy
				  FROM hyfaa.data_assimilated
				  WHERE "date" > now()-timeinterval::interval
			)

			SELECT 	 d_with_assim."date",
					 ROUND(d_with_assim.flow_median::numeric) AS flow,
					 ROUND(d_with_assim.flow_mad::numeric,1) AS flow_mad,
					 ROUND(expect.expected::numeric) AS expected
			FROM  d_with_assim LEFT JOIN expect
								USING(ddoy, cell_id)
			WHERE cell_id=mini
			ORDER BY d_with_assim."date" DESC
		)
		SELECT array_to_json(array_agg(row_to_json(tbl))) FROM tbl INTO jsonarray;
		return jsonarray;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION hyfaa.get_assimilated_values_for_minibasin(integer, character varying)
    IS 'Get assimilated data as aggregated json array. Adds a mean value over all the value existing at the same day of the year (mean over the years), called ''expected''';


CREATE OR REPLACE FUNCTION hyfaa.get_mgbstandard_values_for_minibasin(mini integer, timeinterval varchar default '1 year')
	RETURNS json AS
$$
DECLARE jsonarray json;
        BEGIN
        WITH tbl AS (
            SELECT 	"date",
                    ROUND(flow_mean::numeric) AS flow
            FROM  hyfaa.data_mgbstandard
            WHERE cell_id=mini AND "date" > now()-timeinterval::interval
			ORDER BY "date" DESC
        )
        SELECT array_to_json(array_agg(row_to_json(tbl))) FROM tbl INTO jsonarray;
		return jsonarray;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION hyfaa.get_mgbstandard_values_for_minibasin(integer, character varying)
    IS 'Get mgbstandard data as aggregated json array (array of {date, flow_mean} values) ';


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
