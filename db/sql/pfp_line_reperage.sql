CREATE OR REPLACE VIEW movd.gc_pfp_line_reperage AS
 SELECT
        CASE
            WHEN pfp_line_reperage.statut::text = 'En ordre'::text THEN 1
            ELSE 0
        END AS valid,
    NULL::real AS idgothing,
    NULL::character varying(20) AS date_maj,
    132 AS numcom,
    st_curvetoline(pfp_line_reperage.geometrie) AS geom
   FROM specificite_lausanne.pfp_line_reperage
