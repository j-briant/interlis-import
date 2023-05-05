CREATE OR REPLACE VIEW movd.gc_cs_rev_dur_gc AS
 SELECT foo.genre_id,
    foo.genre,
    foo.genre_txt::character varying(50) AS genre_txt,
    foo.numcom,
    (st_dump(st_union(st_makevalid(foo.geom)))).geom AS geom,
    NULL::integer AS gid_old
   FROM ( SELECT
                CASE
                    WHEN g.itfcode = 1 THEN 2
                    WHEN g.itfcode = 2 THEN 3
                    WHEN g.itfcode = 3 THEN 4
                    WHEN g.itfcode = 4 THEN 5
                    WHEN g.itfcode = 5 THEN 6
                    WHEN g.itfcode = 7 THEN 8
                    WHEN g.itfcode = 8 THEN 9
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
          WHERE s.genre::text ~~ 'revetement_dur.%'::text AND s.genre::text !~~ '%.bassin'::text
        UNION ALL
         SELECT
                CASE
                    WHEN g.itfcode = 1 THEN 2
                    WHEN g.itfcode = 2 THEN 3
                    WHEN g.itfcode = 3 THEN 4
                    WHEN g.itfcode = 4 THEN 5
                    WHEN g.itfcode = 5 THEN 6
                    WHEN g.itfcode = 7 THEN 8
                    WHEN g.itfcode = 8 THEN 9
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
          WHERE s.genre::text ~~ 'revetement_dur.%'::text AND s.genre::text !~~ '%.bassin'::text) foo
  GROUP BY foo.genre, foo.genre_id, foo.genre_txt, foo.numcom
