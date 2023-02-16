-- MOVD_LSPROD."entree_batiment_projet" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."entree_batiment_projet" ("fid", "numero", "extension", "nom_complet", "nom_court", "code_rue", "orientation", "coordonnee_e", "coordonnee_n", "geometrie") AS 
  SELECT 
        e.FID "fid",
        REGEXP_REPLACE(HOUSE_NUMBER, '[^0-9]+', '') "numero",
        REGEXP_REPLACE(HOUSE_NUMBER, '[^A-Za-z]+', '') "extension",
        n.LOCATION_NAME "nom_complet",
        n.SHORT_NAME "nom_court",
        l.LS_CODE_RUE "code_rue",
        MOD(450 - 0.9*t.ORIENTATION, 360) "orientation",
        e.GEOM.sdo_point.x "coordonnee_e",
        e.GEOM.sdo_point.y "coordonnee_n",
        e.GEOM.get_wkt() "geometrie"
    FROM LM_LO_LOCATION l
    JOIN LM_BU_HOUSE_ENTRANCE e ON l.FID = e.FID_LO_LOCATION 
    JOIN LM_BU_HOUSE_ENTRANCE_TBL t ON t.FID_PARENT=e.FID
    JOIN LM_LO_LOCATION_NAME n ON l.FID = n.FID_LO_LOCATION 
    WHERE HOUSE_NUMBER LIKE '(%)';


-- MOVD_LSPROD."localisation_place" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."localisation_place" ("fid", "location_number", "ufid", "code_rue", "id_rue", "geometrie") AS 
  SELECT 
    l.FID "fid",
    l.LOCATION_NUMBER "location_number",
    l.UFID "ufid",
    l.LS_CODE_RUE "code_rue",
    l.LS_ID_RUE "id_rue",
    p.geom.get_wkt() "geometrie"
FROM LM_LO_LOCATION l 
JOIN LM_LO_LOCATION_NAME n ON l.FID = n.FID_LO_LOCATION
JOIN LS_PLACE p ON l.FID = p.FID_LO_LOCATION ;


-- MOVD_LSPROD."localisation_rue" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."localisation_rue" ("fid", "longname", "shortname", "coderue", "numcom", "geometrie") AS 
  SELECT l.FID AS "fid",
    n.LOCATION_NAME AS "longname",
    n.SHORT_NAME AS "shortname",
    l.LS_CODE_RUE AS "coderue",
    132 AS "numcom",
    SDO_AGGR_CONCAT_LINES(t.geom).get_wkt() AS "geometrie"
FROM LM_LO_LOCATION l
JOIN LM_LO_LOCATION_NAME n ON l.fid = n.FID_LO_LOCATION  
JOIN LM_LO_ROAD_SECTION t ON l.fid = t.FID_LO_LOCATION 
WHERE l.ID_TYPE = 10000
GROUP BY l.FID,  n.LOCATION_NAME, n.SHORT_NAME, l.LS_CODE_RUE;


-- MOVD_LSPROD."objet_divers_lineaire" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."objet_divers_lineaire" ("ufid", "genre_id", "genre", "numcom", "geometrie") AS 
  SELECT 
        l.FID AS "ufid", 
        CASE 
            WHEN o.ID_TYPE = 5 THEN 6
            WHEN o.ID_TYPE = 6 THEN 7
            WHEN o.ID_TYPE = 18 THEN 20
            WHEN o.ID_TYPE = 22 THEN 24
            WHEN o.ID_TYPE = 32 THEN 32
            WHEN o.ID_TYPE = 77 THEN 77
            WHEN o.ID_TYPE = 81 THEN 45
            WHEN o.ID_TYPE = 86 THEN 48
            WHEN o.ID_TYPE = 101 THEN 1
            WHEN o.ID_TYPE = 10000 THEN 46
            WHEN o.ID_TYPE = 20001 THEN 57
            WHEN o.ID_TYPE = 20002 THEN 58
            WHEN o.ID_TYPE = 20003 THEN 59
            WHEN o.ID_TYPE = 20005 THEN 61
            WHEN o.ID_TYPE = 20006 THEN 62
            WHEN o.ID_TYPE = 20007 THEN 63
            WHEN o.ID_TYPE = 20008 THEN 64
            WHEN o.ID_TYPE = 20009 THEN 65
            WHEN o.ID_TYPE = 20010 THEN 66
            WHEN o.ID_TYPE = 20011 THEN 67
            WHEN o.ID_TYPE = 20012 THEN 68
            WHEN o.ID_TYPE = 20013 THEN 69
            WHEN o.ID_TYPE = 20014 THEN 70
            WHEN o.ID_TYPE = 20015 THEN 71
            WHEN o.ID_TYPE = 20016 THEN 72
            WHEN o.ID_TYPE = 20019 THEN 75
            WHEN o.ID_TYPE = 20022 THEN 78            
            WHEN o.ID_TYPE = 20023 THEN 79
            WHEN o.ID_TYPE = 20024 THEN 80
            WHEN o.ID_TYPE = 20025 THEN 46
            WHEN o.ID_TYPE = 20026 THEN 82
            WHEN o.ID_TYPE = 20028 THEN 84
            WHEN o.ID_TYPE = 20029 THEN 85
            WHEN o.ID_TYPE = 20030 THEN 86
            WHEN o.ID_TYPE = 20032 THEN 88
            WHEN o.ID_TYPE = 20037 THEN 93
            WHEN o.ID_TYPE = 20038 THEN 94
        END AS "genre_id",
        CAST(CASE 
            WHEN o.ID_TYPE = 5 THEN 'vl.eau_canalisee_souterraine'
            WHEN o.ID_TYPE = 6 THEN 'vl.escalier_important'
            WHEN o.ID_TYPE = 18 THEN 'vl.ouvrage_de_protection_des_rives'
            WHEN o.ID_TYPE = 22 THEN 'vl.ruine_objet_archeologique'
            WHEN o.ID_TYPE = 32 THEN 'vl.voie_ferree'
            WHEN o.ID_TYPE = 77 THEN 'vl.autre_corps_de_batiment.detail'
            WHEN o.ID_TYPE = 81 THEN 'vl.autre.terrain_de_sport'
            WHEN o.ID_TYPE = 86 THEN 'vl.autre.eau_a_ventiler'
            WHEN o.ID_TYPE = 101 THEN 'vl.mur'
            WHEN o.ID_TYPE = 101 THEN 'vl.autre_autre'
            WHEN o.ID_TYPE = 20001 THEN 'vl.batiment_chantier'
            WHEN o.ID_TYPE = 20002 THEN 'vl.batiment_demoli'
            WHEN o.ID_TYPE = 20003 THEN 'vl.batiment_projet'
            WHEN o.ID_TYPE = 20005 THEN 'vl.eau_rive_a_ventiler'
            WHEN o.ID_TYPE = 20006 THEN 'vl.nature_a_ventiler'
            WHEN o.ID_TYPE = 20007 THEN 'vl.abri_tl'
            WHEN o.ID_TYPE = 20008 THEN 'vl.bassin_a_ventiler'
            WHEN o.ID_TYPE = 20009 THEN 'vl.divers_a_ventiler'
            WHEN o.ID_TYPE = 20010 THEN 'vl.divers_souterrain_a_ventiler'
            WHEN o.ID_TYPE = 20011 THEN 'vl.revetement_dur_a_ventiler'
            WHEN o.ID_TYPE = 20012 THEN 'vl.acces_sentier_a_ventiler'
            WHEN o.ID_TYPE = 20013 THEN 'vl.berme_ilot_a_ventiler'
            WHEN o.ID_TYPE = 20014 THEN 'vl.bord_de_chaussee_a_ventiler'
            WHEN o.ID_TYPE = 20015 THEN 'vl.route_s_pont_a_ventiler'
            WHEN o.ID_TYPE = 20016 THEN 'vl.trottoir_a_ventiler'
            WHEN o.ID_TYPE = 20019 THEN 'vl.galerie_technique_a_ventiler'
            WHEN o.ID_TYPE = 20022 THEN 'vl.nature_foret_a_ventiler'
            WHEN o.ID_TYPE = 20023 THEN 'vl.autre_corps_de_batiment.mur_mitoyen'
            WHEN o.ID_TYPE = 20024 THEN 'vl.objet_divers_souterrain_200'
            WHEN o.ID_TYPE = 20025 THEN 'vl.objet_divers_200'
            WHEN o.ID_TYPE = 20026 THEN 'vl.eau_souterraine'
            WHEN o.ID_TYPE = 20028 THEN 'vl.trottoir_bas'
            WHEN o.ID_TYPE = 20029 THEN 'vl.bordure_definie'
            WHEN o.ID_TYPE = 20030 THEN 'vl.bordure_indefinie'
            WHEN o.ID_TYPE = 20032 THEN 'vl.limite_projetee'
            WHEN o.ID_TYPE = 20037 THEN 'vl.detail_eau'
            WHEN o.ID_TYPE = 20038 THEN 'vl.batiment_non_cadastre'
            ELSE c.VALUE
        END AS varchar(50)) AS "genre",
        132 AS "numcom",
        l.GEOM.get_wkt() AS "geometrie"
    FROM LS_SO_SINGLE_OBJECT o 
    JOIN LS_SO_LINE_ELEMENT l ON o.FID=l.FID_SO_SINGLE_OBJECT
    JOIN LM_SO_OBJECT_CATEGORY_TBD c ON o.ID_TYPE = c.ID
    WHERE o.ID_TYPE IN (5, 6, 18, 22, 32, 77, 81, 86, 101, 10000, 20001, 20002, 20003, 20005, 20006, 20007, 20008, 20009, 20010, 20011, 20012, 20013, 20014, 20015, 20016, 20019, 20022, 20023, 20024, 20025, 20026, 20028, 20029, 20030, 20032, 20037, 20038);


-- MOVD_LSPROD."objet_divers_ponctuel" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."objet_divers_ponctuel" ("ufid", "genre_id", "genre", "numcom", "geometrie") AS 
  SELECT s.FID "ufid", ID_TYPE "genre_id", c.VALUE "genre", 132 "numcom", s.GEOM.get_wkt() "geometrie" 
FROM LS_SO_SINGLE_OBJECT o
JOIN LS_SO_POINT_ELEMENT s ON o.FID=s.FID_SO_SINGLE_OBJECT
JOIN LM_SO_OBJECT_CATEGORY_TBD c ON o.ID_TYPE = c.ID
WHERE id_type = 40;


-- MOVD_LSPROD."objet_divers_surfacique" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."objet_divers_surfacique" ("ufid", "genre_id", "genre", "numcom", "geometrie") AS 
  SELECT 
        p.FID AS "ufid", 
        CASE 
            WHEN o.ID_TYPE = 20005 THEN 61
            WHEN o.ID_TYPE = 20008 THEN 64
            WHEN o.ID_TYPE = 20021 THEN 77
        END AS "genre_id",
        CASE 
            WHEN o.ID_TYPE = 20005 THEN 'vl.eau_rive_a_ventiler'
            WHEN o.ID_TYPE = 20008 THEN 'vl.bassin_a_ventiler'
            WHEN o.ID_TYPE = 20021 THEN 'vl.nature_bois_a_ventiler'
        END AS "genre",
        132 AS "numcom",
        p.GEOM.get_wkt() AS "geometrie"
    FROM LS_SO_SINGLE_OBJECT o 
    JOIN LS_SO_SURFACE_ELEMENT p ON o.FID=p.FID_SO_SINGLE_OBJECT
    JOIN LM_SO_OBJECT_CATEGORY_TBD c ON o.ID_TYPE = c.ID
    WHERE o.ID_TYPE IN (20005, 20008, 20021);


-- MOVD_LSPROD."objet_divers_texte" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."objet_divers_texte" ("ufid", "numcom", "type", "text_angle", "textstring", "geometrie") AS 
  select o.FID as "ufid",
    132 AS "numcom",
    CAST(CASE 
        WHEN g.value IN ('vl_batiment_projet', 'vl_batiment_souterrain_projet') THEN 'PROJET'
        WHEN g.value IN ('vl_batiment_chantier', 'vl_batiment_non_cadastre') THEN 'CHANTIER'
        WHEN g.value IN ('vl_batiment_demoli') THEN 'DEMOLI'
        WHEN g.value IN ('vl_nom_a_ventiler', 'vl_od_divers_a_ventiler', 'vl_bassin_a_ventiler', 'vl_galerie_technique_a_ventiler' ,'vl_od_div_200') THEN 'OBJ_TXT'
    END AS varchar(50)) AS "type",
    MOD(450-0.9*t.ORIENTATION, 360) AS "text_angle",
    CAST(t.LABEL_TEXT AS varchar(100)) "textstring", 
    t.GEOM.get_wkt() AS "geometrie"
from LS_SO_SINGLE_OBJECT o
JOIN LS_SO_OBJECT_NAME s ON o.FID = s.FID_SO_SINGLE_OBJECT 
JOIN LM_SO_OBJECT_CATEGORY_TBD g ON o.ID_TYPE = g.ID 
JOIN LS_SO_OBJECT_NAME_TBL t ON t.FID_PARENT = s.fid
;


-- MOVD_LSPROD."pfa" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."pfa" ("fid", "numero_point", "type", "x", "y", "z", "precision_planimetrique", "precision_altimetrique", "fiabilite_planimetrique", "fiabilite_altimetrique", "situation1", "situation2", "id_goeland", "numcom", "geometrie") AS 
  SELECT 
        p.FID "fid",
        p.TB_POINTNUMBER "numero_point",
        c.VALUE "type", 
        p.GEOM.sdo_point.x "x", 
        p.GEOM.sdo_point.y "y", 
        p.Z "z",
        p.TB_ACCURACY_POSITION "precision_planimetrique",
        p.TB_ACCURACY_HEIGHT "precision_altimetrique",
        p.TB_POSITION_RELIABLE "fiabilite_planimetrique",
        p.TB_HEIGHT_RELIABLE "fiabilite_altimetrique",
        g.SITUATION_1 "situation1",
        g.SITUATION_2 "situation2",
        g.ID_GOTHING "id_goeland",
        SUBSTR(nd.NUMBERND, 2, 3) "numcom",
        p.GEOM.get_wkt() "geometrie"
    FROM LM_CP_ACP p 
    JOIN LS_PFA_GESTION g ON p.FID = g.FID_PFA 
    JOIN LM_CP_ACP_CATEGORY_TBD c ON p.ID_CATEGORY = c.ID 
    LEFT JOIN LM_ND_NUMBER_DOMAIN nd ON p.FID_IDENTND = nd.FID ;


-- MOVD_LSPROD."pfp" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."pfp" ("fid", "numero_point", "type", "x", "y", "z", "precision_planimetrique", "precision_altimetrique", "fiabilite_planimetrique", "fiabilite_altimetrique", "accessible", "signe", "id_etat", "situation1", "situation2", "visible_gnss", "id_goeland", "numcom", "gis_ctrl1", "gis_ctrl2", "gis_ctrl3", "gis_ctrl4", "gis_ctrl5", "gis_com1", "gis_com2", "gis_com3", "gis_com4", "gis_com5", "alt_tech", "geometrie") AS 
  SELECT 
        p.FID "fid",
        p.TB_POINTNUMBER "numero_point",
        c.VALUE "type", 
        p.GEOM.sdo_point.x "x", 
        p.GEOM.sdo_point.y "y", 
        CASE 
            WHEN p.Z IS NOT NULL THEN p.Z 
            WHEN p.Z IS NULL AND g.ALT_TECH IS NOT NULL THEN g.ALT_TECH
            ELSE p.GEOM.sdo_point.z
        END "z",
        p.TB_ACCURACY_POSITION "precision_planimetrique",
        p.TB_ACCURACY_HEIGHT "precision_altimetrique",
        p.TB_POSITION_RELIABLE "fiabilite_planimetrique",
        CASE 
            WHEN p.TB_HEIGHT_RELIABLE IS NULL THEN 0
            ELSE p.TB_HEIGHT_RELIABLE 
        END "fiabilite_altimetrique",
        CASE 
            WHEN p.ID_ACCESSIBILITY = 3 THEN 0
            ELSE 1
        END "accesible",
        m.VALUE "signe", 
        g.ID_ETAT "id_etat",
        g.SITUATION_1 "situation1",
        g.SITUATION_2 "situation2",
        v.VALUE "visible_gnss",
        g.ID_GOTHING "id_goeland",
        SUBSTR(nd.NUMBERND, 2, 3) "numcom",
        g.GIS_CTRL1 "gis_ctrl1",
        g.GIS_CTRL2 "gis_ctrl2",
        g.GIS_CTRL3 "gis_ctrl3",
        g.GIS_CTRL4 "gis_ctrl4",
        g.GIS_CTRL5 "gis_ctrl5",
        g.GIS_CTRL_COM1 "gis_com1",
        g.GIS_CTRL_COM2 "gis_com2",
        g.GIS_CTRL_COM3 "gis_com3",
        g.GIS_CTRL_COM4 "gis_com4",
        g.GIS_CTRL_COM5 "gis_com5",
        g.ALT_TECH "alt_tech",
        p.GEOM.get_wkt() "geometrie"
    FROM LM_CP_PCP p 
    LEFT JOIN LS_PFP_GESTION g ON p.FID = g.FID_PFP 
    LEFT JOIN LM_CP_PCP_CATEGORY_TBD c ON p.ID_CATEGORY = c.ID 
    LEFT JOIN LM_CP_PCP_MARK_TBD m ON p.ID_POINT_MARK = m.ID  
    LEFT JOIN LS_PFP_VIS_GNSS_TBD v ON g.ID_VISIBLE_GNSS = v.ID
    LEFT JOIN LM_ND_NUMBER_DOMAIN nd ON p.FID_IDENTND = nd.FID 
    UNION ALL 
    SELECT 
        p.FID "fid",
        p.TB_POINTNUMBER "numero_point",
        c.VALUE "type", 
        p.GEOM.sdo_point.x "x", 
        p.GEOM.sdo_point.y "y", 
        CASE 
            WHEN p.Z IS NOT NULL THEN p.Z 
            WHEN p.Z IS NULL AND g.ALT_TECH IS NOT NULL THEN g.ALT_TECH
            ELSE p.GEOM.sdo_point.z
        END "z",
        p.TB_ACCURACY_POSITION "precision_planimetrique",
        p.TB_ACCURACY_HEIGHT "precision_altimetrique",
        p.TB_POSITION_RELIABLE "fiabilite_planimetrique",
        CASE 
            WHEN p.TB_HEIGHT_RELIABLE IS NULL THEN 0
            ELSE p.TB_HEIGHT_RELIABLE 
        END "fiabilite_altimetrique",
        CASE 
            WHEN p.ID_ACCESSIBILITY = 3 THEN 0
            ELSE 1
        END "accesible",
        m.VALUE "signe",
        g.ID_ETAT "id_etat",
        g.SITUATION_1 "situation1",
        g.SITUATION_2 "situation2",
        v.VALUE "visible_gnss",
        g.ID_GOTHING "id_goeland",
        SUBSTR(nd.NUMBERND, 2, 3) "numcom",
        g.GIS_CTRL1 "gis_ctrl1",
        g.GIS_CTRL2 "gis_ctrl2",
        g.GIS_CTRL3 "gis_ctrl3",
        g.GIS_CTRL4 "gis_ctrl4",
        g.GIS_CTRL5 "gis_ctrl5",
        g.GIS_CTRL_COM1 "gis_com1",
        g.GIS_CTRL_COM2 "gis_com2",
        g.GIS_CTRL_COM3 "gis_com3",
        g.GIS_CTRL_COM4 "gis_com4",
        g.GIS_CTRL_COM5 "gis_com5",
        g.ALT_TECH "alt_tech",
        p.GEOM.get_wkt() "geometrie"
    FROM LS_CP_PCP p 
    LEFT JOIN LS_PFP_GESTION g ON p.FID = g.FID_PFP_LS
    LEFT JOIN LM_CP_PCP_CATEGORY_TBD c ON p.ID_CATEGORY = c.ID 
    LEFT JOIN LM_CP_PCP_MARK_TBD m ON p.ID_POINT_MARK = m.ID  
    LEFT JOIN LS_PFP_VIS_GNSS_TBD v ON g.ID_VISIBLE_GNSS = v.ID
    LEFT JOIN LM_ND_NUMBER_DOMAIN nd ON p.FID_IDENTND = nd.FID 
    ;


-- MOVD_LSPROD."pfp_label_reperage" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."pfp_label_reperage" ("fid", "fid_pfp", "text_value", "text_size", "text_angle", "statut", "geometrie") AS 
  SELECT 
    l.FID "fid", 
    t.FID_PFP "fid_pfp", 
    l.LABEL_TEXT "text_value", 
    0.8 "text_size", 
    MOD(450-l.ORIENTATION, 360) "text_angle",
    s.VALUE "statut",
    l.GEOM.get_wkt() "geometrie"
FROM LS_PFP_REPER_TXT t 
LEFT JOIN LS_PFP_REPER_TXT_TBL l ON t.FID = l.FID_PARENT 
LEFT JOIN LS_PFP_REP_STATUT_TBD s ON t.ID_STATUT = s.ID 
WHERE l.GEOM IS NOT NULL;


-- MOVD_LSPROD."pfp_line_reperage" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."pfp_line_reperage" ("fid", "fid_pfp", "statut", "geometrie") AS 
  SELECT 
    l.FID "fid", 
    l.FID_PFP "fid_pfp",
    s.VALUE "statut",
    l.GEOM.get_wkt() "geometrie" 
FROM LS_PFP_REPER_LINE l
LEFT JOIN LS_PFP_REP_STATUT_TBD s ON l.ID_STATUT = s.ID ;


-- MOVD_LSPROD."pfp_point_reperage" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."pfp_point_reperage" ("fid", "fid_pfp", "statut", "geometrie") AS 
  SELECT 
    p.FID "fid", 
    p.FID_PFP "fid_pfp",
    s.VALUE "statut",
    p.GEOM.get_wkt() "geometrie" 
FROM LS_PFP_REPER_POINT p
LEFT JOIN LS_PFP_REP_STATUT_TBD s ON p.ID_STATUT = s.ID ;


-- MOVD_LSPROD."surface_batiment_projet" source

CREATE OR REPLACE FORCE EDITIONABLE VIEW "MOVD_LSPROD"."surface_batiment_projet" ("fid", "genre", "id_go", "geometrie") AS 
  SELECT s.FID "fid", c.VALUE "genre", so.LS_IDGOTHING "id_go", s.geom.get_wkt() "geometrie"
FROM LS_SO_SINGLE_OBJECT so 
JOIN LS_SO_SURFACE_ELEMENT s ON s.FID_SO_SINGLE_OBJECT = so.FID 
JOIN LM_SO_OBJECT_CATEGORY_TBD c ON c.ID = so.ID_TYPE 
WHERE so.ID_TYPE IN (20001, 20003, 20038, 20042, 20043, 20044) AND s.GEOM IS NOT NULL ;