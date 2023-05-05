CREATE OR REPLACE VIEW movd.gc_od_route_pol AS
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(regexp_replace(split_part(od.genre::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(es.geometrie) AS geom
   FROM movd.objet_divers od
     JOIN movd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN movd.element_surfacique es ON od.fid = es.element_surfacique_de
     JOIN movd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['autre.acces_sentier_a_ventiler'::character varying::text, 'autre.bord_de_chaussee_a_ventiler'::character varying::text, 'autre.berme_ilot_a_ventiler'::character varying::text, 'sentier'::character varying::text, 'autre.trottoir_a_ventiler'::character varying::text, 'autre.acces_sentier_a_ventiler'::character varying::text])
UNION ALL
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(regexp_replace(split_part(od.genre::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(es.geometrie) AS geom
   FROM npcsvd.objet_divers od
     JOIN npcsvd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN npcsvd.element_surfacique es ON od.fid = es.element_surfacique_de
     JOIN npcsvd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['autre.acces_sentier_a_ventiler'::character varying::text, 'autre.bord_de_chaussee_a_ventiler'::character varying::text, 'autre.berme_ilot_a_ventiler'::character varying::text, 'sentier'::character varying::text, 'autre.trottoir_a_ventiler'::character varying::text, 'autre.acces_sentier_a_ventiler'::character varying::text])
