CREATE OR REPLACE VIEW movd.gc_pf_pfp4 AS
 SELECT pfp.numero_point::integer AS no_pt,
    split_part(pfp.type::text, ' '::text, 1)::character varying(8) AS pftype,
    pfp.x AS y,
    pfp.y AS x,
    pfp.z,
    pfp.precision_planimetrique AS prec_pl,
    pfp.precision_altimetrique AS prec_al,
        CASE
            WHEN pfp.fiabilite_planimetrique = 1 THEN 'fiable'::text
            WHEN pfp.fiabilite_planimetrique = 0 OR pfp.fiabilite_planimetrique IS NULL THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN pfp.fiabilite_altimetrique = 1 THEN 'fiable'::text
            WHEN pfp.fiabilite_altimetrique = 0 OR pfp.fiabilite_altimetrique IS NULL THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
        CASE
            WHEN pfp.accessible = 1 THEN 'accessible'::text
            WHEN pfp.accessible = 0 THEN 'inaccessible'::text
            ELSE NULL::text
        END::character varying(20) AS accessible,
    pfp.signe::character varying(20) AS signe,
    pfp.situation1 AS sit1,
    pfp.situation2 AS sit2,
        CASE
            WHEN pfp.visible_gnss IS NULL THEN 'inconnue'::character varying
            ELSE pfp.visible_gnss
        END::character varying(100) AS vis_gnss,
    pfp.id_goeland AS idgo_thing,
    pfp.numcom::integer AS numcom,
    pfp.id_goeland AS id_go,
    NULL::character varying(254) AS lien_vd,
    pfp.geometrie AS geom
   FROM specificite_lausanne.pfp
  WHERE (pfp.type::text = ANY (ARRAY['PFP'::text, 'PFP4 cadastre souterrain'::text])) AND ((pfp.id_etat <> ALL (ARRAY[20002, 20006, 20010, 20011])) OR pfp.id_etat IS NULL)
