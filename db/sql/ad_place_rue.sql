CREATE OR REPLACE VIEW movd.gc_ad_place_rue AS
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
   FROM ( SELECT g.idthing,
            g.longname,
            g.shortname,
            g.estrid,
            g.coderue,
            ts.description AS typestreet,
            g.datedecisionmuni AS datemuni,
            132 AS numcom,
            ((('<a href="https://golux.lausanne.ch/goeland/objet/getobjetinfo.php?idObjet='::text || g.idthing) || '" target="_blank">'::text) || g.idthing) || '</a>'::text AS lien_idgo,
            (((floor(random() * 256::double precision) || ','::text) || floor(random() * 256::double precision)) || ','::text) || floor(random() * 256::double precision) AS color,
            COALESCE(st_difference(p.geometrie, b.geom), p.geometrie) AS geom
           FROM goeland.thi_street g
             JOIN specificite_lausanne.localisation_place p ON g.coderue = p.code_rue
             JOIN goeland.type_thi_street ts ON g.idtypestreet = ts.idtypestreet
             CROSS JOIN LATERAL ( SELECT st_union(s.geometrie) AS geom
                   FROM movd.surfacecs s
                  WHERE s.genre::text = 'batiment'::text AND st_intersects(s.geometrie, p.geometrie)) b) foo
