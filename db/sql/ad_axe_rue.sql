CREATE OR REPLACE VIEW movd.gc_ad_axe_rue AS
 SELECT foo.idthing,
    foo.longname::character varying(150) AS longname,
    foo.shortname::character varying(100) AS shortname,
    foo.estrid,
    foo.coderue,
    foo.typestreet::character varying(150) AS typestreet,
    foo.datemuni::character varying(20) AS datemuni,
    foo.numcom,
    foo.lien_idgo::character varying(254) AS lien_idgo,
    foo.color::character varying(50) AS color,
    (((('#'::text || lpad(to_hex(split_part(foo.color, ','::text, 1)::integer), 2, '0'::text)) || lpad(to_hex(split_part(foo.color, ','::text, 2)::integer), 2, '0'::text)) || lpad(to_hex(split_part(foo.color, ','::text, 3)::integer), 2, '0'::text)))::character varying(50)::text AS color_html,
    foo.geom
   FROM ( SELECT s.idthing,
            nl.texte AS longname,
            nl.texte_abrege AS shortname,
            s.estrid,
            s.coderue,
            ts.description AS typestreet,
            s.datedecisionmuni AS datemuni,
            d.datasetname::integer AS numcom,
            ((('<a href="https://golux.lausanne.ch/goeland/objet/getobjetinfo.php?idObjet='::text || s.idthing) || '" target="_blank">'::text) || s.idthing) || '</a>'::text AS lien_idgo,
            (((floor(random() * 256::double precision) || ','::text) || floor(random() * 256::double precision)) || ','::text) || floor(random() * 256::double precision) AS color,
            st_union(tr.geometrie) AS geom
           FROM movd.localisation l
             JOIN movd.nom_localisation nl ON l.fid = nl.nom_localisation_de
             JOIN movd.troncon_rue tr ON l.fid = tr.troncon_rue_de
             LEFT JOIN goeland.thi_street s ON nl.texte::text = s.longname
             LEFT JOIN goeland.type_thi_street ts ON s.idtypestreet = ts.idtypestreet
             JOIN movd.t_ili2db_basket b ON l.t_basket = b.fid
             JOIN movd.t_ili2db_dataset d ON b.dataset = d.fid
          WHERE (ts.description <> ALL (ARRAY['Place'::text, 'Placette'::text, 'Esplanade'::text, 'Parc'::text, 'Terrasse'::text, 'Square'::text, 'Quartier'::text])) AND d.datasetname::text = '132'::text
          GROUP BY s.idthing, nl.texte, nl.texte_abrege, s.estrid, s.coderue, ts.description, s.datedecisionmuni, (d.datasetname::integer)
        UNION ALL
         SELECT s.idthing,
            r.longname,
            r.shortname,
            s.estrid,
            s.coderue,
            split_part(r.longname::text, ' '::text, 1) AS typestreet,
            s.datedecisionmuni AS datemuni,
            r.numcom::integer AS numcom,
            ((('<a href="https://golux.lausanne.ch/goeland/objet/getobjetinfo.php?idObjet='::text || s.idthing) || '" target="_blank">'::text) || s.idthing) || '</a>'::text AS lien_idgo,
            (((floor(random() * 256::double precision) || ','::text) || floor(random() * 256::double precision)) || ','::text) || floor(random() * 256::double precision) AS color,
            r.geometrie AS geom
           FROM specificite_lausanne.localisation_rue r
             LEFT JOIN goeland.thi_street s ON r.coderue = s.coderue
             LEFT JOIN goeland.type_thi_street ts ON s.idtypestreet = ts.idtypestreet
          WHERE split_part(r.longname::text, ' '::text, 1) <> 'Parc'::text) foo
