-- Update the materialized views using triggers

-- Post processing trigger
CREATE OR REPLACE FUNCTION hyfaa.publication_post_processing()
    RETURNS TRIGGER LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
        -- mgbstandard data
        IF NEW."tablename" = 'data_mgbstandard' THEN
            RAISE INFO 'Triggering post-processing on mgbstandard table. Please wait...';
            PERFORM hyfaa.compute_expected_and_anomaly('hyfaa.data_mgbstandard', 'flow_mean', 10);
            REFRESH  MATERIALIZED VIEW hyfaa.data_with_mgbstandard_aggregate_geo;
        END IF;

        -- assimilated data
        IF NEW."tablename" = 'data_assimilated' THEN
            RAISE INFO 'Triggering post-processing on assimilated table. Please wait...';
            PERFORM hyfaa.compute_expected_and_anomaly('hyfaa.data_assimilated', 'flow_median', 10);
            REFRESH  MATERIALIZED VIEW hyfaa.data_with_assim_aggregate_geo;
        END IF;

        RETURN null;
    END $$;


CREATE TRIGGER publication_post_processing
    AFTER INSERT OR UPDATE ON hyfaa."state"
    FOR EACH ROW
    EXECUTE PROCEDURE hyfaa.publication_post_processing();
