CREATE OR REPLACE VIEW movd.gc_rp_plan_lim AS
 SELECT g.fid::integer AS fidc,
    p.identdn::character varying(20) AS numbernd,
    p.codeplan::character varying(20) AS plan_code,
    p.numero::character varying(20) AS plan_number,
    d.datasetname::integer AS numcom,
    st_curvetoline(g.geometrie) AS geom
   FROM movd.aplan p
     JOIN movd.geometrie_plan g ON p.fid = g.geometrie_plan_de
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION
 SELECT g.fid::integer AS fidc,
    p.identdn::character varying(20) AS numbernd,
    p.codeplan::character varying(20) AS plan_code,
    p.numero::character varying(20) AS plan_number,
    d.datasetname::integer AS numcom,
    st_curvetoline(g.geometrie) AS geom
   FROM npcsvd.aplan p
     JOIN npcsvd.geometrie_plan g ON p.fid = g.geometrie_plan_de
     JOIN npcsvd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
