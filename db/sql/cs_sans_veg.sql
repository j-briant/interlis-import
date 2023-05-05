CREATE OR REPLACE VIEW movd.gc_cs_sans_veg AS
 SELECT foo.genre_id,
    foo.genre,
    foo.genre_txt::character varying(50) AS genre_txt,
    foo.numcom,
    NULL::integer AS gid_old,
    (st_dump(st_union(st_makevalid(foo.geom)))).geom AS geom
   FROM ( SELECT
                CASE
                    WHEN g.itfcode = 22 THEN 23
                    WHEN g.itfcode = 23 THEN 24
                    WHEN g.itfcode = 24 THEN 25
                    WHEN g.itfcode = 25 THEN 26
                    WHEN g.itfcode = 26 THEN 27
                    WHEN g.itfcode = 27 THEN 28
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
          WHERE s.genre::text ~~ 'sans_vegetation.%'::text AND (d.datasetname::text <> ALL (ARRAY['129'::character varying, '143'::character varying, '145'::character varying, '183'::character varying, '188'::character varying, '298'::character varying, '328'::character varying]::text[]))
        UNION ALL
         SELECT
                CASE
                    WHEN g.itfcode = 22 THEN 23
                    WHEN g.itfcode = 23 THEN 24
                    WHEN g.itfcode = 24 THEN 25
                    WHEN g.itfcode = 25 THEN 26
                    WHEN g.itfcode = 26 THEN 27
                    WHEN g.itfcode = 27 THEN 28
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
          WHERE s.genre::text ~~ 'sans_vegetation.%'::text) foo
  GROUP BY foo.genre_id, foo.genre, foo.genre_txt, foo.numcom
