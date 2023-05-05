CREATE OR REPLACE VIEW movd.gc_cs_bati_pol AS
 SELECT g.idthibuilding AS id_go,
    n.regbl_egid AS egid,
    n.numero AS no_eca,
    n.designation::character varying(30) AS design,
    initcap(regexp_replace(db.dispname::text, '\.'::text, ' - '::text, 'g'::text)) AS design_txt,
    s.genre::character varying(30) AS type,
    no.nom AS nom_objet,
    d.datasetname::integer AS numcom,
    st_curvetoline(s.geometrie) AS geom
   FROM movd.surfacecs s
     JOIN movd.numero_de_batiment n ON s.fid = n.numero_de_batiment_de
     JOIN movd.designation_batiment db ON n.designation::text = db.ilicode::text
     LEFT JOIN movd.nom_objet no ON s.fid = no.nom_objet_de
     LEFT JOIN ( SELECT DISTINCT ON (thi_building_no_eca.numeroeca) thi_building_no_eca.idthibuilding,
            thi_building_no_eca.numeroeca
           FROM goeland.thi_building_no_eca
          ORDER BY thi_building_no_eca.numeroeca, thi_building_no_eca.idthibuilding) g ON g.numeroeca = regexp_replace(n.numero::text, '\D$'::text, ''::text, 'g'::text)
     JOIN movd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT g.idthibuilding AS id_go,
    n.regbl_egid AS egid,
    n.numero AS no_eca,
    n.designation::character varying(30) AS design,
    initcap(regexp_replace(go.dispname::text, '\.'::text, ' - '::text, 'g'::text)) AS design_txt,
    s.genre::character varying(30) AS type,
    no.nom AS nom_objet,
    d.datasetname::integer AS numcom,
    st_curvetoline(es.geometrie) AS geom
   FROM movd.objet_divers s
     JOIN movd.element_surfacique es ON s.fid = es.element_surfacique_de
     JOIN movd.numero_objet n ON s.fid = n.numero_objet_de
     JOIN movd.genre_od go ON s.genre::text = go.ilicode::text
     LEFT JOIN movd.md01mvdmn95v24objets_divers_nom_objet no ON s.fid = no.nom_objet_de
     LEFT JOIN ( SELECT DISTINCT ON (thi_building_no_eca.numeroeca) thi_building_no_eca.idthibuilding,
            thi_building_no_eca.numeroeca
           FROM goeland.thi_building_no_eca
          ORDER BY thi_building_no_eca.numeroeca, thi_building_no_eca.idthibuilding) g ON g.numeroeca = regexp_replace(n.numero::text, '\D$'::text, ''::text, 'g'::text)
     JOIN movd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT g.idthibuilding AS id_go,
    n.regbl_egid AS egid,
    n.numero AS no_eca,
    n.designation::character varying(30) AS design,
    initcap(regexp_replace(db.dispname::text, '\.'::text, ' - '::text, 'g'::text)) AS design_txt,
    s.genre::character varying(30) AS type,
    no.nom AS nom_objet,
    d.datasetname::integer AS numcom,
    st_curvetoline(s.geometrie) AS geom
   FROM npcsvd.surfacecs s
     JOIN npcsvd.numero_de_batiment n ON s.fid = n.numero_de_batiment_de
     JOIN npcsvd.designation_batiment db ON n.designation::text = db.ilicode::text
     LEFT JOIN npcsvd.nom_objet no ON s.fid = no.nom_objet_de
     LEFT JOIN ( SELECT DISTINCT ON (thi_building_no_eca.numeroeca) thi_building_no_eca.idthibuilding,
            thi_building_no_eca.numeroeca
           FROM goeland.thi_building_no_eca
          ORDER BY thi_building_no_eca.numeroeca, thi_building_no_eca.idthibuilding) g ON g.numeroeca = regexp_replace(n.numero::text, '\D$'::text, ''::text, 'g'::text)
     JOIN npcsvd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT g.idthibuilding AS id_go,
    n.regbl_egid AS egid,
    n.numero AS no_eca,
    n.designation::character varying(30) AS design,
    initcap(regexp_replace(go.dispname::text, '\.'::text, ' - '::text, 'g'::text)) AS design_txt,
    s.genre::character varying(30) AS type,
    no.nom AS nom_objet,
    d.datasetname::integer AS numcom,
    st_curvetoline(es.geometrie) AS geom
   FROM npcsvd.objet_divers s
     JOIN npcsvd.element_surfacique es ON s.fid = es.element_surfacique_de
     JOIN npcsvd.numero_objet n ON s.fid = n.numero_objet_de
     JOIN npcsvd.genre_od go ON s.genre::text = go.ilicode::text
     LEFT JOIN npcsvd.md01mvdmn95v24objets_divers_nom_objet no ON s.fid = no.nom_objet_de
     LEFT JOIN ( SELECT DISTINCT ON (thi_building_no_eca.numeroeca) thi_building_no_eca.idthibuilding,
            thi_building_no_eca.numeroeca
           FROM goeland.thi_building_no_eca
          ORDER BY thi_building_no_eca.numeroeca, thi_building_no_eca.idthibuilding) g ON g.numeroeca = regexp_replace(n.numero::text, '\D$'::text, ''::text, 'g'::text)
     JOIN npcsvd.t_ili2db_basket b ON s.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
