CREATE OR REPLACE VIEW movd.gc_pf_pfp AS
 SELECT pfp.numero_point::integer AS no_pt,
    pfp.type::character varying(8) AS pftype,
    pfp.x AS y,
    pfp.y AS x,
    pfp.z,
    pfp.precision_planimetrique AS prec_pl,
    pfp.precision_altimetrique AS prec_al,
        CASE
            WHEN pfp.fiabilite_planimetrique = 1 THEN 'fiable'::text
            WHEN pfp.fiabilite_planimetrique = 0 THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN pfp.fiabilite_altimetrique = 1 THEN 'fiable'::text
            WHEN pfp.fiabilite_altimetrique = 0 THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
        CASE
            WHEN pfp.accessible = 1 THEN 'accessible'::text
            WHEN pfp.accessible = 0 THEN 'inaccessible'::text
            ELSE NULL::text
        END::character varying(20) AS accessible,
    pfp.signe::character varying(20) AS signe,
    pfp.situation1 AS sit1,
    pfp.situation2 AS sit2,
    pfp.visible_gnss::character varying(100) AS vis_gnss,
    pfp.id_goeland AS idgo_thing,
    pfp.numcom::integer AS numcom,
    pfp.id_goeland AS id_go,
        CASE
            WHEN pfp.type::text ~~ '%1'::text OR pfp.type::text ~~ '%2'::text THEN (('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || pfp.numero_point::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text)::character varying
            ELSE NULL::character varying(254)
        END::character varying(254) AS lien_vd,
    pfp.geometrie AS geom
   FROM specificite_lausanne.pfp
  WHERE (pfp.type::text <> ALL (ARRAY['PFP4 cadastre souterrain'::text, 'PFP4'::text, 'PFP technique'::text])) AND (pfp.id_etat IS NULL OR (pfp.id_etat <> ALL (ARRAY[20006, 20011]))) AND pfp.numero_point::text <> 'new'::text
UNION ALL
 SELECT p.numero::integer AS no_pt,
    'PFP1'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
        CASE
            WHEN p.fiabplan::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabplan::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN p.fiabalt::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabalt::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    p.accessibilite::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    ('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text AS lien_vd,
    p.geometrie AS geom
   FROM movd.pfp1 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.numero::integer AS no_pt,
    'PFP2'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
        CASE
            WHEN p.fiabplan::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabplan::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN p.fiabalt::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabalt::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    p.accessibilite::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    ('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text AS lien_vd,
    p.geometrie AS geom
   FROM movd.pfp2 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.numero::integer AS no_pt,
    'PFP3'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
        CASE
            WHEN p.fiabplan::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabplan::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN p.fiabalt::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabalt::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    NULL::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    NULL::character varying(254) AS lien_vd,
    p.geometrie AS geom
   FROM movd.pfp3 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE d.datasetname::text <> '132'::text
UNION ALL
 SELECT p.numero::integer AS no_pt,
    'PFP1'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
        CASE
            WHEN p.fiabplan::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabplan::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN p.fiabalt::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabalt::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    p.accessibilite::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    ('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text AS lien_vd,
    p.geometrie AS geom
   FROM npcsvd.pfp1 p
     JOIN npcsvd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.numero::integer AS no_pt,
    'PFP2'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
        CASE
            WHEN p.fiabplan::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabplan::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN p.fiabalt::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabalt::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    p.accessibilite::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    ('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text AS lien_vd,
    p.geometrie AS geom
   FROM npcsvd.pfp2 p
     JOIN npcsvd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.numero::integer AS no_pt,
    'PFP3'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
        CASE
            WHEN p.fiabplan::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabplan::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN p.fiabalt::text = 'oui'::text THEN 'fiable'::text
            WHEN p.fiabalt::text = 'non'::text THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    NULL::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    NULL::character varying(254) AS lien_vd,
    p.geometrie AS geom
   FROM npcsvd.pfp3 p
     JOIN npcsvd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN npcsvd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE d.datasetname::text <> '132'::text
