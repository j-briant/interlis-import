CREATE OR REPLACE VIEW movd.gc_od_text_projet AS
 SELECT objet_divers_texte.numcom::integer AS numcom,
    objet_divers_texte.type::character varying(10) AS type,
    objet_divers_texte.text_angle::numeric AS text_angle,
    objet_divers_texte.textstring::character varying(50) AS textstring,
    objet_divers_texte.geometrie AS geom
   FROM specificite_lausanne.objet_divers_texte
  WHERE objet_divers_texte.type::text = ANY (ARRAY['PROJET'::character varying::text, 'CHANTIER'::character varying::text, 'DEMOLI'::character varying::text])
