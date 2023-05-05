CREATE OR REPLACE VIEW movd.gc_cs_pts_fiab AS
 SELECT p.identification AS numero,
    p.identdn,
    d.datasetname::integer AS numcom,
    '6'::character varying(20) AS signe,
    p.defini_exactement::character varying(8) AS def_exact,
    p.precplan / 100::numeric AS prec_plan,
    p.fiabplan::character varying(8) AS fiab_plan,
    st_y(p.geometrie) AS x,
    st_x(p.geometrie) AS y,
    p.geometrie AS geom
   FROM movd.point_particulier p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE p.defini_exactement::text = 'oui'::text AND p.precplan < 4.6 AND p.fiabplan::text = 'oui'::text
UNION ALL
 SELECT p.identification AS numero,
    p.identdn,
    d.datasetname::integer AS numcom,
    '6'::character varying(20) AS signe,
    p.defini_exactement::character varying(8) AS def_exact,
    p.precplan / 100::numeric AS prec_plan,
    p.fiabplan::character varying(8) AS fiab_plan,
    st_y(p.geometrie) AS x,
    st_x(p.geometrie) AS y,
    p.geometrie AS geom
   FROM npcsvd.point_particulier p
     JOIN npcsvd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE p.defini_exactement::text = 'oui'::text AND p.precplan < 4.6 AND p.fiabplan::text = 'oui'::text
