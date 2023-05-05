CREATE OR REPLACE VIEW movd.gc_ad_bati AS
 SELECT eb.numero_maison AS textstring,
    eb.regbl_egid AS egid,
    eb.regbl_edid AS edid,
    nl.texte AS rue_off,
    nl.texte_abrege AS rue_abr,
    g.idthingbuilding AS id_go,
    d.datasetname::integer AS numcom,
    eb.pos AS geom
   FROM movd.entree_batiment eb
     JOIN movd.localisation l ON l.fid = eb.entree_batiment_de
     JOIN movd.nom_localisation nl ON l.fid = nl.nom_localisation_de
     JOIN movd.posnumero_maison pm ON eb.fid = pm.posnumero_batiment_de
     LEFT JOIN goeland.thi_street_building_address g ON eb.regbl_egid = g.egid AND eb.numero_maison::text = concat(g.number::text, g.extention)
     JOIN movd.t_ili2db_basket b ON l.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT eb.numero_maison AS textstring,
    eb.regbl_egid AS egid,
    eb.regbl_edid AS edid,
    nl.texte AS rue_off,
    nl.texte_abrege AS rue_abr,
    g.idthingbuilding AS id_go,
    d.datasetname::integer AS numcom,
    eb.pos AS geom
   FROM npcsvd.entree_batiment eb
     JOIN npcsvd.localisation l ON l.fid = eb.entree_batiment_de
     JOIN npcsvd.nom_localisation nl ON l.fid = nl.nom_localisation_de
     JOIN npcsvd.posnumero_maison pm ON eb.fid = pm.posnumero_batiment_de
     LEFT JOIN goeland.thi_street_building_address g ON eb.regbl_egid = g.egid AND eb.numero_maison::text = concat(g.number::text, g.extention)
     JOIN npcsvd.t_ili2db_basket b ON l.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
