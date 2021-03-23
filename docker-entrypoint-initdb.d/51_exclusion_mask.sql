SET standard_conforming_strings = OFF;
--CREATE SCHEMA "geospatial";
DROP TABLE IF EXISTS "geospatial"."mask" CASCADE;
DELETE FROM geometry_columns WHERE f_table_name = 'mask' AND f_table_schema = 'geospatial';
BEGIN;
CREATE TABLE "geospatial"."mask" ( "ogc_fid" SERIAL, CONSTRAINT "mask_pk" PRIMARY KEY ("ogc_fid") );
SELECT AddGeometryColumn('geospatial','mask','wkb_geometry',4326,'POLYGON',2);
CREATE INDEX "mask_wkb_geometry_geom_idx" ON "geospatial"."mask" USING GIST ("wkb_geometry");
COMMENT ON TABLE "geospatial"."mask" IS NULL;
ALTER TABLE "geospatial"."mask" ADD COLUMN "id" NUMERIC(10,0);
INSERT INTO "geospatial"."mask" ("wkb_geometry" , "id") VALUES ('0103000020E6100000010000001500000000A3A4CE96BCA5BF9B5F47F46B063440F4C0B17775E30740231D98B4A2A634404E4086E1CADE1D4011C8B9700C853840D1375E7C95A620402445CCD1A5A6364060E7F573674E2240962023F6EA6835407990810BFF0B24406438820DD3CD30407F799E85F43E2140ADBCDDE53C282F402A799D343D571F40C57A7A9C57503040D2DE399C74591B409D30ED9F1E0D30404E062E97085611405F28C3ECCAA12E40640F3C45A7540E40E29CD1A9453B2D4024942C63B0590D406611E066C0D42B40ACC7B29CF1440A40EA85EE233B6E2A403C25DED36111064046096F36F99E2B401822B6C9DAD9FD3FBD385ED0E542304080F49C1475EEB03F228DEC8FFE3E3040A04775CAC4EED5BF52485D3177033140D83CD4CCE7FFE2BFBF723A414D053140681CB956F512F1BFF81ADEDFA9173140683AB91CA9E2F2BF7227E8261F78314000A3A4CE96BCA5BF9B5F47F46B063440', 1);
COMMIT;
