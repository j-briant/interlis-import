CREATE OR REPLACE VIEW movd.gc_bf_parc_pol AS
 SELECT i.numero AS no_parc,
        CASE
            WHEN i.genre::text = 'bien_fonds.DP_communal'::text THEN 'DP_COM'::character varying
            WHEN i.genre::text = 'bien_fonds.DP_cantonal'::text THEN 'DP_CANT'::character varying
            WHEN i.genre::text ~~ 'DDP%'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'DDPCOM'::character varying
            WHEN i.genre::text ~~ 'DDP%'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'DDP'::character varying
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'PARCOM'::character varying(10)
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'PAR'::character varying
            ELSE NULL::character varying(10)
        END AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    d.datasetname::integer AS numcom,
    st_curvetoline(bf.geometrie) AS geom
   FROM movd.immeuble i
     JOIN movd.bien_fonds bf ON i.fid = bf.bien_fonds_de
     LEFT JOIN goeland.parcelle p ON i.egris_egrid::text = p.egrid
     JOIN movd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT i.numero AS no_parc,
        CASE
            WHEN i.genre::text = 'bien_fonds.DP_communal'::text THEN 'DP_COM'::text
            WHEN i.genre::text = 'bien_fonds.DP_cantonal'::text THEN 'DP_CANT'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'DDPCOM'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'DDP'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'PARCOM'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'PAR'::text
            ELSE NULL::text
        END::character varying(10) AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    d.datasetname::integer AS numcom,
    st_curvetoline(ddp.geometrie) AS geom
   FROM movd.immeuble i
     JOIN movd.ddp ON i.fid = ddp.ddp_de
     LEFT JOIN goeland.parcelle p ON i.egris_egrid::text = p.egrid
     JOIN movd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT i.numero AS no_parc,
        CASE
            WHEN i.genre::text = 'bien_fonds.DP_communal'::text THEN 'DP_COM'::text
            WHEN i.genre::text = 'bien_fonds.DP_cantonal'::text THEN 'DP_CANT'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'DDPCOM'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'DDP'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'PARCOM'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'PAR'::text
            ELSE NULL::text
        END::character varying(10) AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    d.datasetname::integer AS numcom,
    st_curvetoline(m.geometrie) AS geom
   FROM movd.immeuble i
     JOIN movd.mine m ON i.fid = m.mine_de
     LEFT JOIN goeland.parcelle p ON i.egris_egrid::text = p.egrid
     JOIN movd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT i.numero AS no_parc,
        CASE
            WHEN i.genre::text = 'bien_fonds.DP_communal'::text THEN 'DP_COM'::character varying
            WHEN i.genre::text = 'bien_fonds.DP_cantonal'::text THEN 'DP_CANT'::character varying
            WHEN i.genre::text ~~ 'DDP%'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'DDPCOM'::character varying
            WHEN i.genre::text ~~ 'DDP%'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'DDP'::character varying
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'PARCOM'::character varying(10)
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'PAR'::character varying
            ELSE NULL::character varying(10)
        END AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    d.datasetname::integer AS numcom,
    st_curvetoline(bf.geometrie) AS geom
   FROM npcsvd.immeuble i
     JOIN npcsvd.bien_fonds bf ON i.fid = bf.bien_fonds_de
     LEFT JOIN goeland.parcelle p ON i.egris_egrid::text = p.egrid
     JOIN npcsvd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT i.numero AS no_parc,
        CASE
            WHEN i.genre::text = 'bien_fonds.DP_communal'::text THEN 'DP_COM'::text
            WHEN i.genre::text = 'bien_fonds.DP_cantonal'::text THEN 'DP_CANT'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'DDPCOM'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'DDP'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'PARCOM'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'PAR'::text
            ELSE NULL::text
        END::character varying(10) AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    d.datasetname::integer AS numcom,
    st_curvetoline(ddp.geometrie) AS geom
   FROM npcsvd.immeuble i
     JOIN npcsvd.ddp ON i.fid = ddp.ddp_de
     LEFT JOIN goeland.parcelle p ON i.egris_egrid::text = p.egrid
     JOIN npcsvd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT i.numero AS no_parc,
        CASE
            WHEN i.genre::text = 'bien_fonds.DP_communal'::text THEN 'DP_COM'::text
            WHEN i.genre::text = 'bien_fonds.DP_cantonal'::text THEN 'DP_CANT'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'DDPCOM'::text
            WHEN i.genre::text ~~ 'DDP%'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'DDP'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND p.resumeproprietaire = 'Commune de Lausanne'::text THEN 'PARCOM'::text
            WHEN i.genre::text = 'bien_fonds.parcelle_prive'::text AND (p.resumeproprietaire <> 'Commune de Lausanne'::text OR p.resumeproprietaire IS NULL) THEN 'PAR'::text
            ELSE NULL::text
        END::character varying(10) AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    d.datasetname::integer AS numcom,
    st_curvetoline(m.geometrie) AS geom
   FROM npcsvd.immeuble i
     JOIN npcsvd.mine m ON i.fid = m.mine_de
     LEFT JOIN goeland.parcelle p ON i.egris_egrid::text = p.egrid
     JOIN npcsvd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
