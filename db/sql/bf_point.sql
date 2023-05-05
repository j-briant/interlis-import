CREATE OR REPLACE VIEW movd.gc_bf_point AS
 SELECT p.identification AS numero,
    d.datasetname::integer AS numcom,
    p.identdn,
    p.signe::character varying(20) AS signe,
    p.defini_exactement::character varying(8) AS def_exact,
    (p.precplan / 100::numeric)::numeric(5,3) AS prec_plan,
    p.fiabplan::character varying(8) AS fiab_plan,
    NULL::character varying(4) AS codea,
    st_y(p.geometrie)::numeric(10,3) AS y,
    st_x(p.geometrie)::numeric(10,3) AS x,
    p.geometrie AS geom
   FROM movd.point_limite p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT t.identification AS numero,
    d.datasetname::integer AS numcom,
    NULL::character varying(12) AS identdn,
    t.signe::character varying(20) AS signe,
    t.defini_exactement::character varying(8) AS def_exact,
    (t.precplan / 100::numeric)::numeric(5,3) AS prec_plan,
    t.fiabplan::character varying(8) AS fiab_plan,
    NULL::character varying(4) AS codea,
    st_y(t.geometrie)::numeric(10,3) AS y,
    st_x(t.geometrie)::numeric(10,3) AS x,
    t.geometrie AS geom
   FROM movd.point_limite_ter t
     JOIN movd.t_ili2db_basket b ON t.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.identification AS numero,
    d.datasetname::integer AS numcom,
    p.identdn,
    p.signe::character varying(20) AS signe,
    p.defini_exactement::character varying(8) AS def_exact,
    (p.precplan / 100::numeric)::numeric(5,3) AS prec_plan,
    p.fiabplan::character varying(8) AS fiab_plan,
    NULL::character varying(4) AS codea,
    st_y(p.geometrie)::numeric(10,3) AS y,
    st_x(p.geometrie)::numeric(10,3) AS x,
    p.geometrie AS geom
   FROM npcsvd.point_limite p
     JOIN npcsvd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT t.identification AS numero,
    d.datasetname::integer AS numcom,
    NULL::character varying(12) AS identdn,
    t.signe::character varying(20) AS signe,
    t.defini_exactement::character varying(8) AS def_exact,
    (t.precplan / 100::numeric)::numeric(5,3) AS prec_plan,
    t.fiabplan::character varying(8) AS fiab_plan,
    NULL::character varying(4) AS codea,
    st_y(t.geometrie)::numeric(10,3) AS y,
    st_x(t.geometrie)::numeric(10,3) AS x,
    t.geometrie AS geom
   FROM npcsvd.point_limite_ter t
     JOIN npcsvd.t_ili2db_basket b ON t.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
