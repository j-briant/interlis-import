CREATE OR REPLACE VIEW movd.gc_lim_com AS
 SELECT c.noofs,
    c.numcom,
    c.nom::character varying(50) AS nom,
    st_curvetoline(lc.geometrie) AS geom
   FROM movd.commune c
     JOIN movd.limite_commune lc ON c.fid = lc.limite_commune_de
