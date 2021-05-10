-- Update the materialized views using triggers


--assimilated data
CREATE OR REPLACE FUNCTION hyfaa.refresh_mat_view_for_assim()
    RETURNS TRIGGER LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
        REFRESH  MATERIALIZED VIEW hyfaa.data_assimilated_with_floating_avg_and_anomaly;
        REFRESH  MATERIALIZED VIEW hyfaa.data_with_assim_aggregate_geo;
        RETURN null;
    END $$;

DROP TRIGGER IF EXISTS refresh_mat_view_for_assim ON hyfaa."state";
CREATE TRIGGER refresh_mat_view_for_assim
    AFTER INSERT OR UPDATE ON hyfaa."state"
    FOR EACH STATEMENT
    EXECUTE PROCEDURE hyfaa.refresh_mat_view_for_assim();


-- mgbstandard data

CREATE OR REPLACE FUNCTION hyfaa.refresh_mat_view_for_mgbstandard()
    RETURNS TRIGGER LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
        REFRESH  MATERIALIZED VIEW hyfaa.data_mgbstandard_with_floating_avg_and_anomaly;
        REFRESH  MATERIALIZED VIEW hyfaa.data_with_mgbstandard_aggregate_geo;
        RETURN null;
    END $$;


DROP TRIGGER IF EXISTS refresh_mat_view_for_mgbstandard ON hyfaa."state";
CREATE TRIGGER refresh_mat_view_for_mgbstandard
    AFTER INSERT OR UPDATE ON hyfaa."state"
    FOR EACH STATEMENT
    EXECUTE PROCEDURE hyfaa.refresh_mat_view_for_mgbstandard();
