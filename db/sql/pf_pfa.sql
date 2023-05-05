CREATE OR REPLACE VIEW movd.gc_pf_pfa AS
 SELECT pfa.numero_point::character varying(10) AS no_pt,
    regexp_replace(pfa.type::text, 'Point Fixe Altimétrique'::text, 'PFA'::text)::character varying(8) AS pftype,
    pfa.x AS y,
    pfa.y AS x,
    pfa.z,
    pfa.precision_planimetrique AS prec_pl,
    pfa.precision_altimetrique AS prec_al,
        CASE
            WHEN pfa.type::text ~~ '%1'::text THEN (('<a href="https://dav0.bgdi.admin.ch/fpds/Protokolle/LN02AV/1243/VD0200000VDE_'::text || pfa.numero_point::text) || '.pdf" target="_blank">fiche</a>'::text)::character varying
            ELSE NULL::character varying(254)
        END::character varying(254) AS lien_vd,
        CASE
            WHEN pfa.fiabilite_planimetrique = 1 THEN 'fiable'::text
            WHEN pfa.fiabilite_planimetrique = 0 THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_pl,
        CASE
            WHEN pfa.fiabilite_altimetrique = 1 THEN 'fiable'::text
            WHEN pfa.fiabilite_altimetrique = 0 THEN 'non-fiable'::text
            ELSE NULL::text
        END::character varying(10) AS fiab_al,
    pfa.situation1 AS sit1,
    pfa.situation2 AS sit2,
    pfa.id_goeland AS idgo_thing,
    pfa.numcom::integer AS numcom,
    pfa.id_goeland AS id_go,
    pfa.geometrie AS geom
   FROM specificite_lausanne.pfa
UNION ALL
 SELECT p.numero::character varying(10) AS no_pt,
    'PFA1'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
    ('<a href="https://dav0.bgdi.admin.ch/fpds/Protokolle/LN02AV/1243/VD0200000VDE_'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text AS lien_vd,
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
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    p.geometrie AS geom
   FROM movd.pfa1 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.numero::character varying(10) AS no_pt,
    'PFA2'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
    ('<a href="https://dav0.bgdi.admin.ch/fpds/Protokolle/LN02AV/1243/VD0100000001_'::text || p.numero::text) || '.pdf" target="_blank">fiche</a>'::character varying(254)::text AS lien_vd,
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
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    p.geometrie AS geom
   FROM movd.pfa2 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
UNION ALL
 SELECT p.numero::character varying(10) AS no_pt,
    'PFA3'::character varying(8) AS pftype,
    st_x(p.geometrie)::numeric(10,3) AS y,
    st_y(p.geometrie)::numeric(10,3) AS x,
    p.geomalt AS z,
    (p.precplan / 100::numeric)::real AS prec_pl,
    (p.precalt / 100::numeric)::real AS prec_al,
    NULL::character varying(254) AS lien_vd,
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
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::integer AS idgo_thing,
    d.datasetname::integer AS numcom,
    NULL::integer AS id_go,
    p.geometrie AS geom
   FROM movd.pfa3 p
     JOIN movd.t_ili2db_basket b ON p.t_basket = b.fid
     JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
  WHERE d.datasetname::text <> '132'::text
