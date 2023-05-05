CREATE OR REPLACE VIEW movd.gc_pfp_point_reperage AS
 SELECT
        CASE
            WHEN pfp_point_reperage.statut::text = 'En ordre'::text THEN 1
            ELSE 0
        END::character varying(1) AS valid,
    NULL::real AS idgothing,
    132 AS numcom,
    pfp_point_reperage.geometrie AS geom
   FROM specificite_lausanne.pfp_point_reperage
