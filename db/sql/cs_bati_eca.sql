CREATE OR REPLACE VIEW movd.gc_cs_bati_eca AS
 SELECT n.numero::character varying(15) AS textstring,
    mod(450::numeric - 0.9 * p.ori, 360::numeric) AS text_angle,
    d.datasetname::integer AS numcom,
    p.pos AS geom
   FROM movd.numero_de_batiment n
     JOIN movd.posnumero_de_batiment p ON n.fid = p.posnumero_de_batiment_de
     JOIN movd.t_ili2db_basket b ON n.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT n.numero::character varying(15) AS textstring,
    mod(450::numeric - 0.9 * p.ori, 360::numeric) AS text_angle,
    d.datasetname::integer AS numcom,
    p.pos AS geom
   FROM movd.numero_objet n
     JOIN movd.posnumero_objet p ON n.fid = p.posnumero_objet_de
     JOIN movd.t_ili2db_basket b ON n.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT n.numero::character varying(15) AS textstring,
    mod(450::numeric - 0.9 * p.ori, 360::numeric) AS text_angle,
    d.datasetname::integer AS numcom,
    p.pos AS geom
   FROM npcsvd.numero_de_batiment n
     JOIN npcsvd.posnumero_de_batiment p ON n.fid = p.posnumero_de_batiment_de
     JOIN npcsvd.t_ili2db_basket b ON n.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT n.numero::character varying(15) AS textstring,
    mod(450::numeric - 0.9 * p.ori, 360::numeric) AS text_angle,
    d.datasetname::integer AS numcom,
    p.pos AS geom
   FROM npcsvd.numero_objet n
     JOIN npcsvd.posnumero_objet p ON n.fid = p.posnumero_objet_de
     JOIN npcsvd.t_ili2db_basket b ON n.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
