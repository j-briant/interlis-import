CREATE OR REPLACE VIEW movd.gc_cs_bati_pol_projet AS
 SELECT NULL::character varying(10) AS no_eca,
    100 AS design_id,
    'batiment_projet'::character varying(40) AS design,
    'Batiment projet'::character varying(40) AS design_txt,
        CASE
            WHEN bp.genre::text = 'vl_batiment_projet'::text THEN 'BAT_PROJET'::text
            WHEN bp.genre::text = ANY (ARRAY['vl_batiment_chantier'::character varying::text, 'vl_batiment_non_cadastre'::character varying::text]) THEN 'BAT_CHANTIER'::text
            WHEN bp.genre::text = 'vl_batiment_souterrain_chantier'::text THEN 'BAT_SOUT_CHANTIER'::text
            WHEN bp.genre::text = 'vl_batiment_souterrain_projet'::text THEN 'BAT_SOUT_PROJET'::text
            ELSE NULL::text
        END::character varying(30) AS type,
    bp.id_go,
    bp.fid::integer AS gid_old,
    132 AS numcom,
    'Lausanne'::character varying(40) AS nom_com,
    st_curvetoline(bp.geometrie) AS geom
   FROM specificite_lausanne.surface_batiment_projet bp
UNION ALL
 SELECT NULL::character varying(10) AS no_eca,
    100 AS design_id,
    'batiment_projet'::character varying(40) AS design,
    'Batiment projet'::character varying(40) AS design_txt,
    'BAT_PROJET'::character varying(30) AS type,
    NULL::integer AS id_go,
    NULL::integer AS gid_old,
    d.datasetname::integer AS numcom,
    nc.nom::character varying(40) AS nom_com,
    st_curvetoline(s.geometrie) AS geom
   FROM movd.surfacecsproj s
     JOIN movd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
     JOIN ( SELECT nc_1.nom,
            d_1.fid
           FROM movd.commune nc_1
             JOIN movd.t_ili2db_basket b_1 ON nc_1.t_basket = b_1.fid
             JOIN movd.t_ili2db_dataset d_1 ON b_1.dataset = d_1.fid) nc ON d.fid = nc.fid
  WHERE d.datasetname::text <> '132'::text
UNION ALL
 SELECT NULL::character varying(10) AS no_eca,
    100 AS design_id,
    'batiment_projet'::character varying(40) AS design,
    'Batiment projet'::character varying(40) AS design_txt,
    'BAT_PROJET'::character varying(30) AS type,
    NULL::integer AS id_go,
    NULL::integer AS gid_old,
    d.datasetname::integer AS numcom,
    nc.nom::character varying(40) AS nom_com,
    st_curvetoline(s.geometrie) AS geom
   FROM npcsvd.surfacecsproj s
     JOIN npcsvd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
     JOIN ( SELECT nc_1.nom,
            d_1.fid
           FROM npcsvd.commune nc_1
             JOIN npcsvd.t_ili2db_basket b_1 ON nc_1.t_basket = b_1.fid
             JOIN npcsvd.t_ili2db_dataset d_1 ON b_1.dataset = d_1.fid) nc ON d.fid = nc.fid
  WHERE d.datasetname::text <> '132'::text
