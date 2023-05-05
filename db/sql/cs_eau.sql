CREATE OR REPLACE VIEW movd.gc_cs_eau AS
 SELECT
        CASE
            WHEN g.itfcode = 6 THEN 7
            WHEN g.itfcode = 15 THEN 16
            WHEN g.itfcode = 16 THEN 17
            WHEN g.itfcode = 17 THEN 18
            ELSE NULL::integer
        END AS genre_id,
    s.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    st_curvetoline(s.geometrie) AS geom,
    NULL::integer AS gid_old
   FROM movd.surfacecs s
     JOIN movd.genre_cs g ON s.genre::text = g.ilicode::text
     JOIN movd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE s.genre::text ~~ 'eau.%'::text OR s.genre::text ~~ '%.bassin'::text
UNION ALL
 SELECT
        CASE
            WHEN g.itfcode = 6 THEN 7
            WHEN g.itfcode = 15 THEN 16
            WHEN g.itfcode = 16 THEN 17
            WHEN g.itfcode = 17 THEN 18
            ELSE NULL::integer
        END AS genre_id,
    s.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    st_curvetoline(s.geometrie) AS geom,
    NULL::integer AS gid_old
   FROM npcsvd.surfacecs s
     JOIN npcsvd.genre_cs g ON s.genre::text = g.ilicode::text
     JOIN npcsvd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE s.genre::text ~~ 'eau.%'::text OR s.genre::text ~~ '%.bassin'::text
