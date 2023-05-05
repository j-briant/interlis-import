CREATE OR REPLACE VIEW movd.gc_cs_verte AS
 SELECT foo.genre_id,
    foo.genre,
    foo.genre_txt::character varying(50) AS genre_txt,
    foo.numcom,
    NULL::integer AS gid_old,
    (st_dump(st_union(st_makevalid(foo.geom)))).geom AS geom
   FROM ( SELECT
                CASE
                    WHEN g.itfcode = 9 THEN 10
                    WHEN g.itfcode = 10 THEN 11
                    WHEN g.itfcode = 11 THEN 12
                    WHEN g.itfcode = 12 THEN 13
                    WHEN g.itfcode = 13 THEN 14
                    WHEN g.itfcode = 14 THEN 15
                    ELSE NULL::integer
                END AS genre_id,
            s.genre::character varying(50) AS genre,
            initcap(split_part(g.dispname::text, '.'::text, '-1'::integer)) AS genre_txt,
            d.datasetname::integer AS numcom,
            st_curvetoline(s.geometrie) AS geom
           FROM movd.surfacecs s
             JOIN movd.genre_cs g ON s.genre::text = g.ilicode::text
             JOIN movd.t_ili2db_basket b ON s.t_basket = b.fid
             JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
          WHERE s.genre::text ~~ 'verte.%'::text
        UNION ALL
         SELECT
                CASE
                    WHEN g.itfcode = 9 THEN 10
                    WHEN g.itfcode = 10 THEN 11
                    WHEN g.itfcode = 11 THEN 12
                    WHEN g.itfcode = 12 THEN 13
                    WHEN g.itfcode = 13 THEN 14
                    WHEN g.itfcode = 14 THEN 15
                    ELSE NULL::integer
                END AS genre_id,
            s.genre::character varying(50) AS genre,
            initcap(split_part(g.dispname::text, '.'::text, '-1'::integer)) AS genre_txt,
            d.datasetname::integer AS numcom,
            st_curvetoline(s.geometrie) AS geom
           FROM npcsvd.surfacecs s
             JOIN npcsvd.genre_cs g ON s.genre::text = g.ilicode::text
             JOIN npcsvd.t_ili2db_basket b ON s.t_basket = b.fid
             JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
          WHERE s.genre::text ~~ 'verte.%'::text) foo
  GROUP BY foo.genre_id, foo.genre, foo.genre_txt, foo.numcom
