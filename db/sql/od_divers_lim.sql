CREATE OR REPLACE VIEW movd.gc_od_divers_lim AS
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
  WHERE od.genre::text <> ALL (ARRAY['autre_corps_de_batiment.details'::character varying::text::character varying::text, 'autre_corps_de_batiment.mur_mitoyen'::character varying::text::character varying::text, 'couvert_independant'::character varying::text::character varying::text, 'escalier_important'::text, 'mur'::text, 'autre.trottoir_a_ventiler'::text, 'sentier'::text, 'autre.bord_de_chaussee_a_ventiler'::text, 'eau_canalisee_souterraine'::text, 'autre.eau_a_ventiler'::text, 'autre.berme_ilot_a_ventiler'::text, 'autre.acces_sentier_a_ventiler'::text])
UNION ALL
 SELECT objet_divers_lineaire.genre_id::integer AS genre_id,
    objet_divers_lineaire.genre,
    initcap(regexp_replace(split_part(objet_divers_lineaire.genre::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    objet_divers_lineaire.numcom::integer AS numcom,
    objet_divers_lineaire.ufid AS gid_old,
    st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE objet_divers_lineaire.genre_id = ANY (ARRAY[20, 24, 32, 45, 62, 63, 65, 66, 75, 78, 80, 45, 46])
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
  WHERE od.genre::text <> ALL (ARRAY['autre_corps_de_batiment.details'::character varying::text::character varying::text, 'autre_corps_de_batiment.mur_mitoyen'::character varying::text::character varying::text, 'couvert_independant'::character varying::text::character varying::text, 'escalier_important'::text, 'mur'::text, 'autre.trottoir_a_ventiler'::text, 'sentier'::text, 'autre.bord_de_chaussee_a_ventiler'::text, 'eau_canalisee_souterraine'::text, 'autre.eau_a_ventiler'::text, 'autre.berme_ilot_a_ventiler'::text, 'autre.acces_sentier_a_ventiler'::text])
