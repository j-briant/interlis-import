CREATE OR REPLACE VIEW movd.gc_od_text AS
 SELECT d.datasetname::integer AS numcom,
    'OBJ_TXT'::character varying(30) AS type,
    mod(450::numeric - pno.ori, 360::numeric)::real AS text_angle,
    no.nom::character varying(50) AS textstring,
    pno.pos AS geom
   FROM movd.md01mvdmn95v24objets_divers_nom_objet no
     JOIN movd.md01mvdmn95v24objets_divers_posnom_objet pno ON no.fid = pno.posnom_objet_de
     JOIN movd.t_ili2db_basket b ON no.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT d.datasetname::integer AS numcom,
    'COUV_SOL'::character varying(30) AS type,
    mod(450::numeric - pno.ori, 360::numeric)::real AS text_angle,
    no.nom::character varying(50) AS textstring,
    pno.pos AS geom
   FROM movd.nom_objet no
     JOIN movd.posnom_objet pno ON no.fid = pno.posnom_objet_de
     JOIN movd.t_ili2db_basket b ON no.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT objet_divers_texte.numcom::integer AS numcom,
    objet_divers_texte.type::character varying(30) AS type,
    objet_divers_texte.text_angle,
    objet_divers_texte.textstring::character varying(50) AS textstring,
    objet_divers_texte.geometrie AS geom
   FROM specificite_lausanne.objet_divers_texte
  WHERE objet_divers_texte.id_type <> ALL (ARRAY[20031, 20039, 20040, 20041, 20001, 20002, 20003, 20038, 20042, 20043, 20044])
UNION ALL
 SELECT d.datasetname::integer AS numcom,
    'OBJ_TXT'::character varying(30) AS type,
    mod(450::numeric - pno.ori, 360::numeric)::real AS text_angle,
    no.nom::character varying(50) AS textstring,
    pno.pos AS geom
   FROM npcsvd.md01mvdmn95v24objets_divers_nom_objet no
     JOIN npcsvd.md01mvdmn95v24objets_divers_posnom_objet pno ON no.fid = pno.posnom_objet_de
     JOIN npcsvd.t_ili2db_basket b ON no.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT d.datasetname::integer AS numcom,
    'COUV_SOL'::character varying(30) AS type,
    mod(450::numeric - pno.ori, 360::numeric)::real AS text_angle,
    no.nom::character varying(50) AS textstring,
    pno.pos AS geom
   FROM npcsvd.nom_objet no
     JOIN npcsvd.posnom_objet pno ON no.fid = pno.posnom_objet_de
     JOIN npcsvd.t_ili2db_basket b ON no.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
