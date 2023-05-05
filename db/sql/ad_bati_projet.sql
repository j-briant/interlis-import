CREATE OR REPLACE VIEW movd.gc_ad_bati_projet AS
 SELECT concat(eb.numero, eb.extension) AS textstring,
    eb.code_rue AS cd_rue,
    0 AS egid,
    0 AS edid,
    eb.nom_complet AS rue_off,
    eb.nom_court AS rue_abr,
    eb.orientation AS text_angle,
    g.idthing AS id_go,
    132 AS numcom,
    eb.geometrie AS geom
   FROM specificite_lausanne.entree_batiment_projet eb
     LEFT JOIN goeland.thi_building g ON (eb.nom_court::text = ANY (string_to_array(g.name, ' '::text))) AND (concat(eb.numero, eb.extension) = ANY (regexp_split_to_array(g.name, ',| '::text)))
  WHERE g.idcodestatus <> ALL (ARRAY[4, 5])
