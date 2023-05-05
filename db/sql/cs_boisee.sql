CREATE OR REPLACE VIEW movd.gc_cs_boisee AS
 SELECT s.genre::character varying(50) AS genre,
        CASE
            WHEN g.itfcode = 18 THEN 19
            WHEN g.itfcode = 19 THEN 20
            WHEN g.itfcode = 20 THEN 21
            WHEN g.itfcode = 21 THEN 22
            ELSE NULL::integer
        END AS genre_id,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    st_curvetoline(s.geometrie) AS geom,
    NULL::integer AS gid_old
   FROM movd.surfacecs s
     JOIN movd.genre_cs g ON s.genre::text = g.ilicode::text
     JOIN movd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE s.genre::text ~~ 'boisee.%'::text
UNION ALL
 SELECT s.genre::character varying(50) AS genre,
        CASE
            WHEN g.itfcode = 18 THEN 19
            WHEN g.itfcode = 19 THEN 20
            WHEN g.itfcode = 20 THEN 21
            WHEN g.itfcode = 21 THEN 22
            ELSE NULL::integer
        END AS genre_id,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    st_curvetoline(s.geometrie) AS geom,
    NULL::integer AS gid_old
   FROM npcsvd.surfacecs s
     JOIN npcsvd.genre_cs g ON s.genre::text = g.ilicode::text
     JOIN npcsvd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE s.genre::text ~~ 'boisee.%'::text
