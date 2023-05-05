CREATE OR REPLACE VIEW movd.gc_od_mur_esc_lim AS
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(el.geometrie) AS geom
   FROM movd.objet_divers od
     JOIN movd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN movd.element_lineaire el ON od.fid = el.element_lineaire_de
     JOIN movd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['mur'::character varying::text, 'escalier_important'::character varying::text])
UNION ALL
 SELECT objet_divers_lineaire.genre_id::integer AS genre_id,
    objet_divers_lineaire.genre,
    initcap(regexp_replace(split_part(objet_divers_lineaire.genre::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    objet_divers_lineaire.numcom::integer AS numcom,
    objet_divers_lineaire.ufid AS gid_old,
    st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE objet_divers_lineaire.genre_id = ANY (ARRAY[1, 7])
UNION ALL
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(el.geometrie) AS geom
   FROM npcsvd.objet_divers od
     JOIN npcsvd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN npcsvd.element_lineaire el ON od.fid = el.element_lineaire_de
     JOIN npcsvd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['mur'::character varying::text, 'escalier_important'::character varying::text])
UNION ALL
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(st_exteriorring(es.geometrie)) AS geom
   FROM movd.objet_divers od
     JOIN movd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN movd.element_surfacique es ON od.fid = es.element_surfacique_de
     JOIN movd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['mur'::character varying::text, 'escalier_important'::character varying::text])
UNION ALL
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(st_exteriorring(es.geometrie)) AS geom
   FROM npcsvd.objet_divers od
     JOIN npcsvd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN npcsvd.element_surfacique es ON od.fid = es.element_surfacique_de
     JOIN npcsvd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['mur'::character varying::text, 'escalier_important'::character varying::text])
