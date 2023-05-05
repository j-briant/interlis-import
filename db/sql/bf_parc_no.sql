CREATE OR REPLACE VIEW movd.gc_bf_parc_no AS
 SELECT i.numero::character varying(20) AS no_parc,
        CASE
            WHEN i.genre::text ~~ 'DDP.%'::text THEN 'DDP'::text
            WHEN i.genre::text ~~ '%.parcelle_prive'::text THEN 'PAR'::text
            WHEN i.genre::text ~~ '%.DP_%'::text THEN 'DP'::text
            ELSE NULL::text
        END::character varying(30) AS type,
    mod(450::numeric - 0.9 * pi.ori, 360::numeric)::real AS or_text,
    d.datasetname::integer AS numcom,
    pi.pos AS geom
   FROM movd.immeuble i
     JOIN movd.posimmeuble pi ON i.fid = pi.posimmeuble_de
     JOIN movd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT i.numero::character varying(20) AS no_parc,
        CASE
            WHEN i.genre::text ~~ 'DDP.%'::text THEN 'DDP'::text
            WHEN i.genre::text ~~ '%.parcelle_prive'::text THEN 'PAR'::text
            WHEN i.genre::text ~~ '%.DP_%'::text THEN 'DP'::text
            ELSE NULL::text
        END::character varying(30) AS type,
    mod(450::numeric - 0.9 * pi.ori, 360::numeric)::real AS or_text,
    d.datasetname::integer AS numcom,
    pi.pos AS geom
   FROM npcsvd.immeuble i
     JOIN npcsvd.posimmeuble pi ON i.fid = pi.posimmeuble_de
     JOIN npcsvd.t_ili2db_basket b ON i.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
