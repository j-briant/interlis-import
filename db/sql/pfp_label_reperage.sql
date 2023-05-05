CREATE OR REPLACE VIEW movd.gc_pfp_label_reperage AS
 SELECT pfp_label_reperage.text_value::character varying(100) AS text_value,
    pfp_label_reperage.text_size,
    pfp_label_reperage.text_angle,
    pfp_label_reperage.text_color::character varying(20) AS text_color,
    pfp_label_reperage.type_label::character varying(100) AS type,
        CASE
            WHEN pfp_label_reperage.statut::text = 'En ordre'::text THEN 1
            ELSE 0
        END::character varying(1) AS valid,
    132 AS numcom,
    NULL::real AS idgothing,
    pfp_label_reperage.geometrie AS geom
   FROM specificite_lausanne.pfp_label_reperage
