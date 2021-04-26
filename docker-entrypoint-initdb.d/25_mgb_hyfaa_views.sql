-----------------------------------------------------
-- Aggregate the last 15d values in a json field
-----------------------------------------------------

-- on assimilated data
CREATE OR REPLACE VIEW hyfaa.data_assimilated_aggregate_json
 AS
 WITH data_15d_with_average AS (
	WITH average AS (SELECT cell_id, avg(flow_median) AS flow_median_yearly_average
						FROM hyfaa.data_assimilated
						GROUP BY cell_id),
	data_15d AS (SELECT * FROM hyfaa.data_assimilated
						WHERE date IN (SELECT date from hyfaa.data_assimilated
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
      		'flow', flow_median,
      		'flow_anomaly', CASE WHEN flow_median_yearly_average = 0 THEN null ELSE 100 * (flow_median - flow_median_yearly_average) / flow_median_yearly_average END
      		)
	        ORDER BY date DESC
        ) AS values
FROM data_15d_with_average AS v
GROUP BY cell_id, flow_median_yearly_average
ORDER BY cell_id;

ALTER TABLE hyfaa.data_assimilated_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_assimilated_aggregate_json IS 'Keep only the flow median. Compute the average for each minibasin. Use it to compute the anomaly. Aggregate the results for the n last days into a json field';


-- on mgbstandard data
CREATE OR REPLACE VIEW hyfaa.data_mgbstandard_aggregate_json
 AS
 WITH data_15d_with_average AS (
	WITH average AS (SELECT cell_id, avg(flow_mean) AS flow_mean_yearly_average
						FROM hyfaa.data_mgbstandard
						GROUP BY cell_id),
	data_15d AS (SELECT * FROM hyfaa.data_mgbstandard
						WHERE date IN (SELECT date from hyfaa.data_mgbstandard
						GROUP BY date ORDER BY date DESC LIMIT 15)
				)
	SELECT data_15d.*, average.flow_mean_yearly_average
	FROM data_15d, average
	WHERE data_15d.cell_id = average.cell_id
)
SELECT cell_id, flow_mean_yearly_average,
       json_agg(
          json_build_object(
      		'date', date,
      		'flow', flow_mean,
      		'flow_anomaly', CASE WHEN flow_mean_yearly_average = 0 THEN null ELSE 100 * (flow_mean - flow_mean_yearly_average) / flow_mean_yearly_average END
      		)
	        ORDER BY date DESC
        ) AS values
FROM data_15d_with_average AS v
GROUP BY cell_id, flow_mean_yearly_average
ORDER BY cell_id;

ALTER TABLE hyfaa.data_mgbstandard_aggregate_json
    OWNER TO postgres;

COMMENT ON  VIEW hyfaa.data_mgbstandard_aggregate_json IS 'Keep only the flow mean. Compute the average for each minibasin. Use it to compute the anomaly. Aggregate the results for the n last days into a json field';




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
					 d_with_assim.flow_median AS flow,
					 d_with_assim.flow_mad,
					 expect.expected
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
                    flow_mean AS flow
            FROM  hyfaa.data_mgbstandard
            WHERE cell_id=mini
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
					 flow_median AS flow,
					 flow_mad
            FROM  hyfaa.data_forecast
            WHERE cell_id=mini
			ORDER BY "date" DESC
        )
        SELECT array_to_json(array_agg(row_to_json(tbl))) FROM tbl INTO jsonarray;
		return jsonarray;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION hyfaa.get_forecast_values_for_minibasin(integer, character varying)
    IS 'Get forecast data as aggregated json array. ';
