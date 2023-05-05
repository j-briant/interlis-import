CREATE OR REPLACE VIEW movd.gc_od_arbre_sym AS
 SELECT objet_divers_ponctuel.genre_id::integer AS genre_id,
    objet_divers_ponctuel.genre,
    initcap(regexp_replace(objet_divers_ponctuel.genre::text, '_'::text, ' '::text, 'g'::text))::character varying(50) AS genre_txt,
    objet_divers_ponctuel.numcom::integer AS numcom,
    objet_divers_ponctuel.geometrie AS geom,
    objet_divers_ponctuel.ufid AS gid_old
   FROM specificite_lausanne.objet_divers_ponctuel
  WHERE objet_divers_ponctuel.genre_id = 40
