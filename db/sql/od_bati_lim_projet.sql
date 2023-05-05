CREATE OR REPLACE VIEW movd.gc_od_bati_lim_projet AS
 SELECT objet_divers_lineaire.genre_id::integer AS genre_id,
    objet_divers_lineaire.genre,
    initcap(regexp_replace(split_part(objet_divers_lineaire.genre::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    objet_divers_lineaire.numcom::integer AS numcom,
    objet_divers_lineaire.ufid AS gid_old,
    st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE objet_divers_lineaire.genre_id = ANY (ARRAY[77, 57, 58, 59, 94])
