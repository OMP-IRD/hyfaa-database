-----------------------------------------------------
-- Define custom functions
-----------------------------------------------------
-- Determines the list of Day of the year (1-366) surrounding the date provided as input
-- Inputs:
-- - c_date: the center date, to be surrounded
-- - nbdays: the number of days to retain, around the c_date
-- RETURNS: a 1-column table, listing the days (Day of the year (1-366))
CREATE OR REPLACE FUNCTION hyfaa.surrounding_days_of_year(c_date date, nbdays int default 10)
RETURNS TABLE (s_doy   int)
AS
$func$
BEGIN
   RETURN QUERY
        SELECT date_part('doy', s_days)::int AS s_doy
            FROM generate_series
                ( (c_date - nbdays * '1 day'::interval),
                  (c_date + nbdays * '1 day'::interval),
                  '1 day'::interval) AS s_days;
   END
$func$  LANGUAGE plpgsql;
COMMENT ON FUNCTION hyfaa.surrounding_days_of_year(c_date date, nbdays int)
    IS 'Determines the list of Day of the year (1-366) surrounding the date provided as input
    Inputs:
     - c_date: the center date, to be surrounded
     - nbdays: the number of days to retain, around the c_date
    RETURNS: a 1-column table, listing the days (Day of the year (1-366))';




-- Determines a list of dates respecting the following criterias:
-- - the DOY (day of year) is less than 'nbdays' far from the c_date's DOY
-- - the date is from a previous year (e.g. we don't retain the date from 2 days before)
-- Inputs:
-- - c_date: the center date, to be surrounded
-- - nbdays: the number of days to retain, around the c_date
-- RETURNS: a 1-column table, listing the days (Day of the year (1-366))
CREATE OR REPLACE FUNCTION hyfaa.surrounding_days_over_previous_years(c_date date, nbdays int default 10)
RETURNS TABLE (s_dates   date)
AS
$func$
BEGIN
   RETURN QUERY
        SELECT "date" FROM (SELECT DISTINCT "date" FROM hyfaa.data_mgbstandard) d
        WHERE "date" < (c_date - (nbdays || ' days')::interval)
        AND date_part('doy', "date") IN (
            SELECT hyfaa.surrounding_days_of_year(c_date, nbdays)
        )
        GROUP BY "date"
        ORDER BY "date" DESC;
   END
$func$  LANGUAGE plpgsql;
COMMENT ON FUNCTION hyfaa.surrounding_days_over_previous_years(c_date date, nbdays int)
    IS 'Determines a list of dates respecting the following criterias:
     - the DOY (day of year) is less than ''nbdays'' far from the c_date''s DOY
     - the date is from a previous year (e.g. we don''t retain the date from 2 days before)
    Inputs:
     - c_date: the center date, to be surrounded
     - nbdays: the number of days to retain, around the c_date
    RETURNS: a 1-column table, listing the days (Day of the year (1-366))';


-- Anomaly formula. Used to compute flow anomaly
CREATE OR REPLACE FUNCTION hyfaa.compute_anomaly(current_value float, expected_value float)
RETURNS float
AS
$$
BEGIN
    RETURN (
        CASE WHEN expected_value = 0 THEN 'Infinity' ELSE (100 * (current_value - expected_value) / expected_value) END
        );
   END
$$  LANGUAGE plpgsql;
COMMENT ON FUNCTION hyfaa.compute_anomaly(current_value float, expected_value float)
    IS 'Anomaly formula. Used to compute flow anomaly';


-- Computes and inserts values for the flow_expected and flow_anomaly columns
-- flow_expected is calculated using the floating median
-- flow_anomaly is calculated using the above function, and uses the 'expected' value
-- RETURNS the number of updated dates
CREATE OR REPLACE FUNCTION hyfaa.compute_expected_and_anomaly(
                                                    _tbl regclass,
                                                    _columnname text,
                                                    _nbdays int default 10,
                                                    lower_date date default '1950-01-01'
                                                  )
RETURNS SMALLINT
AS
$$
DECLARE
    TABLE_RECORD RECORD;
	query1 TEXT;
	query2 TEXT;
	counter SMALLINT;
BEGIN
    -- list the dates at which we have some undefined values for 'expected' or 'anomaly' columns
    query1 :='SELECT "date" AS upt_date
                            FROM %s
                            WHERE (flow_expected IS NULL OR flow_anomaly IS NULL)
                            AND "date" > $1::date
                            GROUP BY upt_date
                            ORDER BY upt_date DESC';
    -- is run inside the loop. The subquery 'subq' computes the median value on the determined field (flow_mean or
    -- flow_median, supposedly) on a subsample of dates (see hyfaa.surrounding_days_over_previous_years function for
    -- definition)
    -- The data from 'subq' is then inserted into the original table, for the given date
    -- ($1, i.e. TABLE_RECORD."upt_date")
    query2 := ' UPDATE %s
                    SET flow_expected = subq.median,
                        flow_anomaly = hyfaa.compute_anomaly(%s, subq.median)
                    FROM (SELECT cell_id AS id, median(%s)
                        FROM %s AS d
                        WHERE "date" IN (SELECT hyfaa.surrounding_days_over_previous_years($1, $2) )
                        GROUP BY cell_id) AS subq
                    WHERE "date" = $1
                        AND cell_id = subq.id';
    counter := 0;
    -- Loop over those dates
    FOR TABLE_RECORD IN EXECUTE format(query1, _tbl) USING lower_date
        LOOP
            EXECUTE format(query2, _tbl, _columnname, _columnname, _tbl) USING TABLE_RECORD."upt_date", _nbdays;
            RAISE INFO 'Computed flow_expected and flow_anomaly for date %', TABLE_RECORD."upt_date";
            counter := counter + 1;
        END LOOP;
    RETURN counter;
END
$$  LANGUAGE plpgsql;
COMMENT ON FUNCTION hyfaa.compute_expected_and_anomaly(_tbl regclass, _columnname text, _nbdays int, lower_date date)
    IS 'Computes and inserts values for the flow_expected and flow_anomaly columns.
    flow_expected is calculated using the floating median
    flow_anomaly is calculated using the above function, and uses the ''expected'' value
    RETURNS the number of updated dates';