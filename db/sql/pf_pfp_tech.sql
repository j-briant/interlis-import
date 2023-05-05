CREATE OR REPLACE VIEW movd.gc_pf_pfp_tech AS
 SELECT pfp.fid::integer AS fid,
    pfp.numero_point::integer AS no_pt,
        CASE
            WHEN pfp.type::text ~~ 'PFP %'::text THEN 'PFP'::text
            WHEN pfp.type::text ~~ 'PFP3%'::text THEN 'PFP3'::text
            WHEN pfp.type::text ~~ 'PFP2%'::text THEN 'PFP2'::text
            WHEN pfp.type::text ~~ 'PFP1%'::text THEN 'PFP1'::text
            ELSE NULL::text
        END::character varying(8) AS pftype,
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
            WHEN pfp.type::text ~~ '%PFP1'::text OR pfp.type::text ~~ '%PFP2'::text THEN ('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || pfp.numero_point::text) || '.pdf" target="_blank">fiche</a>'::text
            ELSE NULL::text
        END::character varying(254) AS lien_vd,
    pfp.gis_ctrl1,
    pfp.gis_ctrl2,
    pfp.gis_ctrl3,
    pfp.gis_ctrl4,
    pfp.gis_ctrl5,
    pfp.gis_com1,
    pfp.gis_com2,
    pfp.gis_com3,
    pfp.gis_com4,
    pfp.gis_com5,
    pfp.alt_tech,
    pfp.id_etat,
    pfp.geometrie AS geom
   FROM specificite_lausanne.pfp
  WHERE pfp.type::text !~~ 'PFP4%'::text AND ((pfp.id_etat <> ALL (ARRAY[20002, 20006, 20010, 20011])) OR pfp.id_etat IS NULL)
UNION ALL
 SELECT pfp4.fid::integer AS fid,
    pfp4.numero AS no_pt,
    'PFP4'::character varying(8) AS pftype,
    st_x(pfp4.geom)::numeric(10,3) AS y,
    st_y(pfp4.geom)::numeric(10,3) AS x,
    st_z(pfp4.geom)::numeric(7,3) AS z,
    1 AS prec_pl,
    1 AS prec_al,
    'fiable'::character varying(10) AS fiab_pl,
    'fiable'::character varying(10) AS fiab_al,
    'inconnu'::character varying(20) AS accessible,
    s.value::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    132 AS numcom,
    NULL::integer AS id_go,
    NULL::character varying(254) AS lien_vd,
    pfp4.gis_ctrl1::real AS gis_ctrl1,
    pfp4.gis_ctrl2::real AS gis_ctrl2,
    pfp4.gis_ctrl3::real AS gis_ctrl3,
    pfp4.gis_ctrl4::real AS gis_ctrl4,
    pfp4.gis_ctrl5::real AS gis_ctrl5,
    pfp4.gis_ctrl_com1::character varying(100) AS gis_com1,
    pfp4.gis_ctrl_com2::character varying(100) AS gis_com2,
    pfp4.gis_ctrl_com3::character varying(100) AS gis_com3,
    pfp4.gis_ctrl_com4::character varying(100) AS gis_com4,
    pfp4.gis_ctrl_com5::character varying(100) AS gis_com5,
    NULL::real AS alt_tech,
    pfp4.fk_etat AS id_etat,
    pfp4.geom
   FROM qsout_public.pfp4
     JOIN qsout_public.tbd_signe_pfp4 s ON pfp4.fk_signe = s.id
  WHERE (pfp4.fk_etat <> ALL (ARRAY[20002, 20006, 20010, 20011])) OR pfp4.fk_etat IS NULL
UNION ALL
 SELECT p.fid::integer AS fid,
    p.numero::integer AS no_pt,
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
    ((('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::text))::character varying(254) AS lien_vd,
    NULL::real AS gis_ctrl1,
    NULL::real AS gis_ctrl2,
    NULL::real AS gis_ctrl3,
    NULL::real AS gis_ctrl4,
    NULL::real AS gis_ctrl5,
    NULL::character varying(100) AS gis_com1,
    NULL::character varying(100) AS gis_com2,
    NULL::character varying(100) AS gis_com3,
    NULL::character varying(100) AS gis_com4,
    NULL::character varying(100) AS gis_com5,
    NULL::real AS alt_tech,
    NULL::integer AS id_etat,
    p.geometrie AS geom
   FROM movd.pfp1 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE d.datasetname::text = ANY (ARRAY['130'::character varying::text, '135'::character varying::text, '137'::text])
UNION ALL
 SELECT p.fid::integer AS fid,
    p.numero::integer AS no_pt,
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
    ((('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::text))::character varying(254) AS lien_vd,
    NULL::real AS gis_ctrl1,
    NULL::real AS gis_ctrl2,
    NULL::real AS gis_ctrl3,
    NULL::real AS gis_ctrl4,
    NULL::real AS gis_ctrl5,
    NULL::character varying(100) AS gis_com1,
    NULL::character varying(100) AS gis_com2,
    NULL::character varying(100) AS gis_com3,
    NULL::character varying(100) AS gis_com4,
    NULL::character varying(100) AS gis_com5,
    NULL::real AS alt_tech,
    NULL::integer AS id_etat,
    p.geometrie AS geom
   FROM movd.pfp2 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE d.datasetname::text = ANY (ARRAY['130'::character varying::text, '135'::character varying::text, '137'::text])
UNION ALL
 SELECT p.fid::integer AS fid,
    p.numero::integer AS no_pt,
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
    NULL::character varying(20) AS accessible,
    p.signe::character varying(20) AS signe,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    'inconnue'::character varying(100) AS vis_gnss,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    ((('<a href="https://data.geo.admin.ch/ch.swisstopo.fixpunkte-lfp1/protokolle/LV03AV/1243/CH0300001243_1243'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::text))::character varying(254) AS lien_vd,
    NULL::real AS gis_ctrl1,
    NULL::real AS gis_ctrl2,
    NULL::real AS gis_ctrl3,
    NULL::real AS gis_ctrl4,
    NULL::real AS gis_ctrl5,
    NULL::character varying(100) AS gis_com1,
    NULL::character varying(100) AS gis_com2,
    NULL::character varying(100) AS gis_com3,
    NULL::character varying(100) AS gis_com4,
    NULL::character varying(100) AS gis_com5,
    NULL::real AS alt_tech,
    NULL::integer AS id_etat,
    p.geometrie AS geom
   FROM movd.pfp3 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE d.datasetname::text = ANY (ARRAY['130'::character varying::text, '135'::character varying::text, '137'::text])
