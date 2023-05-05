CREATE OR REPLACE VIEW movd.gc_ad_route_txt AS
 SELECT nl.texte::character varying(100) AS textstring,
        CASE
            WHEN pnl.grandeur::text = 'petite'::text THEN 0.5
            WHEN pnl.grandeur::text = 'moyenne'::text THEN 1::numeric
            WHEN pnl.grandeur::text = 'grande'::text THEN 2::numeric
            ELSE NULL::integer::numeric
        END AS text_size,
    mod(450::numeric - 0.9 * pnl.ori, 360::numeric) AS text_angle,
        CASE
            WHEN l.genre::text = 'Rue'::text THEN 'ROUTE_TXT'::text
            WHEN l.genre::text = 'Lieu_denomme'::text THEN 'NOM_TXT'::text
            WHEN l.genre::text = 'Place'::text THEN 'PLACE_TXT'::text
            ELSE NULL::text
        END::character varying(30) AS type,
    d.datasetname::integer AS numcom,
    pnl.pos AS geom
   FROM movd.localisation l
     JOIN movd.nom_localisation nl ON l.fid = nl.nom_localisation_de
     JOIN movd.posnom_localisation pnl ON nl.fid = pnl.posnom_localisation_de
     JOIN movd.t_ili2db_basket b ON l.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT ld.nom::character varying(100) AS textstring,
        CASE
            WHEN pld.grandeur::text = 'petite'::text THEN 0.5
            WHEN pld.grandeur::text = 'moyenne'::text THEN 1::numeric
            WHEN pld.grandeur::text = 'grande'::text THEN 2::numeric
            ELSE NULL::integer::numeric
        END AS text_size,
    mod(450::numeric - 0.9 * pld.ori, 360::numeric) AS text_angle,
    'NOM_TXT'::character varying(30) AS type,
    d.datasetname::integer AS numcom,
    pld.pos AS geom
   FROM movd.lieudit ld
     JOIN movd.poslieudit pld ON ld.fid = pld.poslieudit_de
     JOIN movd.t_ili2db_basket b ON ld.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT nl.texte::character varying(100) AS textstring,
        CASE
            WHEN pnl.grandeur::text = 'petite'::text THEN 0.5
            WHEN pnl.grandeur::text = 'moyenne'::text THEN 1::numeric
            WHEN pnl.grandeur::text = 'grande'::text THEN 2::numeric
            ELSE NULL::integer::numeric
        END AS text_size,
    mod(450::numeric - 0.9 * pnl.ori, 360::numeric) AS text_angle,
        CASE
            WHEN l.genre::text = 'Rue'::text THEN 'ROUTE_TXT'::text
            WHEN l.genre::text = 'Lieu_denomme'::text THEN 'NOM_TXT'::text
            WHEN l.genre::text = 'Place'::text THEN 'PLACE_TXT'::text
            ELSE NULL::text
        END::character varying(30) AS type,
    d.datasetname::integer AS numcom,
    pnl.pos AS geom
   FROM npcsvd.localisation l
     JOIN npcsvd.nom_localisation nl ON l.fid = nl.nom_localisation_de
     JOIN npcsvd.posnom_localisation pnl ON nl.fid = pnl.posnom_localisation_de
     JOIN npcsvd.t_ili2db_basket b ON l.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT ld.nom::character varying(100) AS textstring,
        CASE
            WHEN pld.grandeur::text = 'petite'::text THEN 0.5
            WHEN pld.grandeur::text = 'moyenne'::text THEN 1::numeric
            WHEN pld.grandeur::text = 'grande'::text THEN 2::numeric
            ELSE NULL::integer::numeric
        END AS text_size,
    mod(450::numeric - 0.9 * pld.ori, 360::numeric) AS text_angle,
    'NOM_TXT'::character varying(30) AS type,
    d.datasetname::integer AS numcom,
    pld.pos AS geom
   FROM npcsvd.lieudit ld
     JOIN npcsvd.poslieudit pld ON ld.fid = pld.poslieudit_de
     JOIN npcsvd.t_ili2db_basket b ON ld.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
