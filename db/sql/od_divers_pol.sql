CREATE OR REPLACE VIEW movd.gc_od_divers_pol AS
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(es.geometrie) AS geom
   FROM movd.objet_divers od
     JOIN movd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN movd.element_surfacique es ON od.fid = es.element_surfacique_de
     JOIN movd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['tunnel_passage_inferieur_galerie'::character varying::text, 'pont_passerelle'::character varying::text, 'autre.terrain_de_sport'::character varying::text, 'monument'::text, 'ruine_objet_archeologique'::text, 'ouvrage_de_protection_des_rives'::text, 'debarcadere'::text, 'quai'::text, 'ru'::text, 'silo_tour_gazometre'::text, 'tour_panoramique'::text, 'reservoir'::text, 'autre.autre'::text])
UNION ALL
 SELECT objet_divers_surfacique.genre_id::integer AS genre_id,
    objet_divers_surfacique.genre,
    initcap(regexp_replace(split_part(objet_divers_surfacique.genre::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    objet_divers_surfacique.numcom::integer AS numcom,
    objet_divers_surfacique.ufid AS gid_old,
    st_curvetoline(objet_divers_surfacique.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_surfacique
  WHERE objet_divers_surfacique.genre_id = 77
UNION ALL
 SELECT g.itfcode + 1 AS genre_id,
    od.genre::character varying(50) AS genre,
    initcap(split_part(g.dispname::text, '.'::text, '-1'::integer))::character varying(50) AS genre_txt,
    d.datasetname::integer AS numcom,
    NULL::integer AS gid_old,
    st_curvetoline(es.geometrie) AS geom
   FROM npcsvd.objet_divers od
     JOIN npcsvd.genre_od g ON od.genre::text = g.ilicode::text
     JOIN npcsvd.element_surfacique es ON od.fid = es.element_surfacique_de
     JOIN npcsvd.t_ili2db_basket b ON od.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE od.genre::text = ANY (ARRAY['tunnel_passage_inferieur_galerie'::character varying::text, 'pont_passerelle'::character varying::text, 'autre.terrain_de_sport'::character varying::text, 'monument'::text, 'ruine_objet_archeologique'::text, 'ouvrage_de_protection_des_rives'::text, 'debarcadere'::text, 'quai'::text, 'ru'::text, 'silo_tour_gazometre'::text, 'tour_panoramique'::text, 'reservoir'::text, 'autre.autre'::text])
