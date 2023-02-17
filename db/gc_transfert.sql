--
-- PostgreSQL database dump
--

-- Dumped from database version 14.6 (Ubuntu 14.6-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.6 (Ubuntu 14.6-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: db_monitoring; Type: SCHEMA; Schema: -; Owner: gc_transfert_dbo
--

CREATE SCHEMA db_monitoring;


ALTER SCHEMA db_monitoring OWNER TO gc_transfert_dbo;

--
-- Name: goeland; Type: SCHEMA; Schema: -; Owner: goeland
--

CREATE SCHEMA goeland;


ALTER SCHEMA goeland OWNER TO goeland;

--
-- Name: movd; Type: SCHEMA; Schema: -; Owner: gc_transfert_dbo
--

CREATE SCHEMA movd;


ALTER SCHEMA movd OWNER TO gc_transfert_dbo;

--
-- Name: specificite_lausanne; Type: SCHEMA; Schema: -; Owner: gc_transfert_dbo
--

CREATE SCHEMA specificite_lausanne;


ALTER SCHEMA specificite_lausanne OWNER TO gc_transfert_dbo;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: count_gc_view_object(character varying); Type: FUNCTION; Schema: db_monitoring; Owner: postgres
--

CREATE FUNCTION db_monitoring.count_gc_view_object(my_schema character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare r record;
begin
for r in (select table_name
	  from information_schema.views
	  where table_schema = my_schema and table_name like 'gc_%')
loop
	EXECUTE FORMAT('INSERT INTO db_monitoring.view_count(schemaname, viewname, datasetname, n)
			SELECT ''%1$I'', ''%2$I'', numcom, COUNT(*) FROM %1$I.%2$I GROUP BY numcom;', my_schema, r.table_name);
end loop;
end;
$_$;


ALTER FUNCTION db_monitoring.count_gc_view_object(my_schema character varying) OWNER TO postgres;

--
-- Name: count_object(character varying); Type: FUNCTION; Schema: db_monitoring; Owner: gc_transfert_dbo
--

CREATE FUNCTION db_monitoring.count_object(my_schema character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare r record;
begin
for r in (select table_name
	  from information_schema.tables
	  where table_schema = my_schema and table_type = 'BASE TABLE')
loop
	EXECUTE FORMAT('INSERT INTO db_monitoring.table_count(schemaname, tablename, n)
			SELECT ''%1$I'', ''%2$I'', COUNT(*) FROM %1$I.%2$I;', my_schema, r.table_name);
end loop;
end;
$_$;


ALTER FUNCTION db_monitoring.count_object(my_schema character varying) OWNER TO gc_transfert_dbo;

--
-- Name: count_table_object(character varying); Type: FUNCTION; Schema: db_monitoring; Owner: postgres
--

CREATE FUNCTION db_monitoring.count_table_object(my_schema character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
declare r record;
begin
for r in (select table_name
	  from information_schema.tables
	  where table_schema = my_schema and table_type = 'BASE TABLE')
loop
	EXECUTE FORMAT('INSERT INTO db_monitoring.table_count(schemaname, tablename, n)
			SELECT ''%1$I'', ''%2$I'', COUNT(*) FROM %1$I.%2$I;', my_schema, r.table_name);
end loop;
end;
$_$;


ALTER FUNCTION db_monitoring.count_table_object(my_schema character varying) OWNER TO postgres;

--
-- Name: go_count_object(); Type: FUNCTION; Schema: db_monitoring; Owner: gc_transfert_dbo
--

CREATE FUNCTION db_monitoring.go_count_object() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
        BEGIN
                EXECUTE FORMAT('INSERT INTO db_monitoring.object_count(schemaname, tablename, object_count)
                                SELECT ''%1$I'', ''%2$I'', COUNT(*)
                                FROM %1$I.%2$I;', TG_TABLE_SCHEMA, TG_TABLE_NAME);
                RETURN NULL;
        END;
$_$;


ALTER FUNCTION db_monitoring.go_count_object() OWNER TO gc_transfert_dbo;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: table_count; Type: TABLE; Schema: db_monitoring; Owner: gc_transfert_dbo
--

CREATE TABLE db_monitoring.table_count (
    fid integer NOT NULL,
    schemaname character varying(100) NOT NULL,
    tablename character varying(100) NOT NULL,
    n integer NOT NULL,
    insert_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE db_monitoring.table_count OWNER TO gc_transfert_dbo;

--
-- Name: object_count_fid_seq; Type: SEQUENCE; Schema: db_monitoring; Owner: gc_transfert_dbo
--

ALTER TABLE db_monitoring.table_count ALTER COLUMN fid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME db_monitoring.object_count_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: table_last_update_difference; Type: VIEW; Schema: db_monitoring; Owner: gc_transfert_dbo
--

CREATE VIEW db_monitoring.table_last_update_difference AS
 WITH ranked AS (
         SELECT table_count.schemaname,
            table_count.tablename,
            table_count.n,
            table_count.insert_date,
            dense_rank() OVER (PARTITION BY table_count.schemaname, table_count.tablename ORDER BY table_count.insert_date DESC) AS rnk
           FROM db_monitoring.table_count
          ORDER BY table_count.insert_date DESC
        )
 SELECT r1.schemaname,
    r1.tablename,
    r1.n AS new_count,
    r1.insert_date AS new_date,
    r2.n AS old_count,
    r2.insert_date AS old_date,
    (r1.n - r2.n) AS difference
   FROM (ranked r1
     FULL JOIN ( SELECT ranked.schemaname,
            ranked.tablename,
            ranked.n,
            ranked.insert_date,
            ranked.rnk
           FROM ranked
          WHERE (ranked.rnk = 2)) r2 ON ((((r1.schemaname)::text || (r1.tablename)::text) = ((r2.schemaname)::text || (r2.tablename)::text))))
  WHERE (r1.rnk = 1)
  ORDER BY r1.schemaname, r1.tablename;


ALTER TABLE db_monitoring.table_last_update_difference OWNER TO gc_transfert_dbo;

--
-- Name: view_count; Type: TABLE; Schema: db_monitoring; Owner: gc_transfert_dbo
--

CREATE TABLE db_monitoring.view_count (
    fid integer NOT NULL,
    schemaname character varying(100) NOT NULL,
    viewname character varying(100) NOT NULL,
    datasetname character varying(4) NOT NULL,
    n integer NOT NULL,
    insert_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE db_monitoring.view_count OWNER TO gc_transfert_dbo;

--
-- Name: view_count_fid_seq; Type: SEQUENCE; Schema: db_monitoring; Owner: gc_transfert_dbo
--

ALTER TABLE db_monitoring.view_count ALTER COLUMN fid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME db_monitoring.view_count_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: view_last_update_difference; Type: VIEW; Schema: db_monitoring; Owner: gc_transfert_dbo
--

CREATE VIEW db_monitoring.view_last_update_difference AS
 WITH ranked AS (
         SELECT view_count.schemaname,
            view_count.viewname,
            view_count.datasetname,
            view_count.n,
            view_count.insert_date,
            dense_rank() OVER (PARTITION BY view_count.schemaname, view_count.viewname, view_count.datasetname ORDER BY view_count.insert_date DESC) AS rnk
           FROM db_monitoring.view_count
          ORDER BY view_count.insert_date DESC
        )
 SELECT r1.schemaname,
    r1.viewname,
    r1.datasetname,
    r1.n AS new_count,
    r1.insert_date AS new_date,
    r2.n AS old_count,
    r2.insert_date AS old_date,
    (r1.n - r2.n) AS difference
   FROM (ranked r1
     FULL JOIN ( SELECT ranked.schemaname,
            ranked.viewname,
            ranked.datasetname,
            ranked.n,
            ranked.insert_date,
            ranked.rnk
           FROM ranked
          WHERE (ranked.rnk = 2)) r2 ON (((((r1.schemaname)::text || (r1.viewname)::text) || (r1.datasetname)::text) = (((r2.schemaname)::text || (r2.viewname)::text) || (r2.datasetname)::text))))
  WHERE (r1.rnk = 1)
  ORDER BY r1.datasetname, r1.schemaname, r1.viewname;


ALTER TABLE db_monitoring.view_last_update_difference OWNER TO gc_transfert_dbo;

--
-- Name: ch_histo_nbr_habi_par_adr; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.ch_histo_nbr_habi_par_adr (
    idadresse integer NOT NULL,
    nbrhabitants integer NOT NULL,
    dateextraction timestamp without time zone NOT NULL,
    datehistorisation timestamp without time zone,
    code character(1) NOT NULL
);


ALTER TABLE goeland.ch_histo_nbr_habi_par_adr OWNER TO goeland;

--
-- Name: dico_cprue_ls; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.dico_cprue_ls (
    idaddress integer NOT NULL,
    codepostal integer,
    extentioncp integer,
    communepostale text,
    idrue integer
);


ALTER TABLE goeland.dico_cprue_ls OWNER TO goeland;

--
-- Name: lien_arbre_espece_cultivar; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.lien_arbre_espece_cultivar (
    idespece integer NOT NULL,
    idcultivar integer NOT NULL
);


ALTER TABLE goeland.lien_arbre_espece_cultivar OWNER TO goeland;

--
-- Name: lien_arbre_genre_espece; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.lien_arbre_genre_espece (
    idgenre integer NOT NULL,
    idespece integer NOT NULL
);


ALTER TABLE goeland.lien_arbre_genre_espece OWNER TO goeland;

--
-- Name: parcelle; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.parcelle (
    idthing integer NOT NULL,
    egrid text,
    idcommune integer NOT NULL,
    numparcelle text NOT NULL,
    nversion integer NOT NULL,
    idetat integer NOT NULL,
    idtype integer NOT NULL,
    idsecteur integer,
    surface bigint,
    surfacepermeable bigint,
    surfaceimpertaxerete bigint,
    surfaceimpertaxeretesansrabais bigint,
    datevaliditesurfperm timestamp without time zone,
    estimfisc bigint,
    rouleau text,
    planp text,
    txtintitule text,
    resumeproprietaire text
);


ALTER TABLE goeland.parcelle OWNER TO goeland;

--
-- Name: parcelle_dico_type; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.parcelle_dico_type (
    idtypep integer NOT NULL,
    typeparcelle text,
    typecode text,
    codeorder text NOT NULL,
    isactive boolean NOT NULL
);


ALTER TABLE goeland.parcelle_dico_type OWNER TO goeland;

--
-- Name: thi_arbre; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre (
    idthing integer NOT NULL,
    idvalidation integer NOT NULL,
    idgenre integer,
    idespece integer,
    idcultivar integer,
    idcirconference integer,
    circonference integer,
    iddiamcouronne integer,
    idhauteur integer,
    idenvracinaire integer,
    idchkenvracinaire integer,
    envracinairerem text,
    idsubstrat integer,
    idchksubstrat integer,
    substratrem text,
    identourage integer,
    idchkentourage integer,
    entouragerem text,
    idrevsurface integer,
    idchkrevsurface integer,
    revsurfacerem text,
    idprotection integer,
    idchkprotection integer,
    protectionrem text,
    idetatsanitairepied integer,
    idetatsanitairetronc integer,
    idetatsanitairecouronne integer,
    etatsanitairerem text,
    datereleve timestamp without time zone,
    anneeplantation character(4),
    isincada boolean,
    tobecontrolled boolean,
    idtobechecked integer,
    idnote integer,
    ispublic boolean,
    ismajestic boolean,
    isinbestof boolean,
    isfruittree boolean,
    ispositionprecise boolean,
    compensation integer,
    isstreettree boolean
);


ALTER TABLE goeland.thi_arbre OWNER TO goeland;

--
-- Name: thi_arbre_cultivar; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre_cultivar (
    id integer NOT NULL,
    cultivar text NOT NULL
);


ALTER TABLE goeland.thi_arbre_cultivar OWNER TO goeland;

--
-- Name: thi_arbre_diam_couronne; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre_diam_couronne (
    id integer NOT NULL,
    diamcouronne text NOT NULL,
    diam_cm integer
);


ALTER TABLE goeland.thi_arbre_diam_couronne OWNER TO goeland;

--
-- Name: thi_arbre_espece; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre_espece (
    id integer NOT NULL,
    espece text NOT NULL
);


ALTER TABLE goeland.thi_arbre_espece OWNER TO goeland;

--
-- Name: thi_arbre_genre; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre_genre (
    id integer NOT NULL,
    genre text NOT NULL
);


ALTER TABLE goeland.thi_arbre_genre OWNER TO goeland;

--
-- Name: thi_arbre_hauteur; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre_hauteur (
    id integer NOT NULL,
    hauteur text NOT NULL,
    hauteur_cm integer
);


ALTER TABLE goeland.thi_arbre_hauteur OWNER TO goeland;

--
-- Name: thi_arbre_validation; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_arbre_validation (
    id integer NOT NULL,
    validation text NOT NULL,
    sortorder integer,
    isactive boolean
);


ALTER TABLE goeland.thi_arbre_validation OWNER TO goeland;

--
-- Name: thi_building; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_building (
    idthing integer NOT NULL,
    name text,
    idville integer,
    idcamac text,
    idcorrespondant integer,
    idthibuildingmaster integer,
    idthistreet integer,
    idtypeconstr integer NOT NULL,
    idcodestatus integer NOT NULL,
    idcodeouvrage integer,
    nbrniveau integer,
    isondp boolean NOT NULL,
    iscontigu boolean NOT NULL
);


ALTER TABLE goeland.thi_building OWNER TO goeland;

--
-- Name: thi_building_bat_principal; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_building_bat_principal (
    idthing integer NOT NULL,
    idthingbatprincipal integer NOT NULL
);


ALTER TABLE goeland.thi_building_bat_principal OWNER TO goeland;

--
-- Name: thi_building_egid; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_building_egid (
    idthing integer NOT NULL,
    egid integer NOT NULL
);


ALTER TABLE goeland.thi_building_egid OWNER TO goeland;

--
-- Name: thi_building_no_eca; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_building_no_eca (
    idthibuilding integer NOT NULL,
    numeroeca text NOT NULL,
    volumeeca integer,
    affectationeca text,
    commentaire text
);


ALTER TABLE goeland.thi_building_no_eca OWNER TO goeland;

--
-- Name: thi_sondage_geo_therm; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_sondage_geo_therm (
    idthing integer NOT NULL,
    idcanton integer,
    idetat integer,
    profondeur integer,
    isprofondeurfiable boolean,
    dateleve timestamp without time zone,
    altitude numeric(6,2)
);


ALTER TABLE goeland.thi_sondage_geo_therm OWNER TO goeland;

--
-- Name: thi_street; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_street (
    idthing integer NOT NULL,
    idville integer NOT NULL,
    article text,
    firstname text,
    lastname text NOT NULL,
    estrid integer,
    coderue integer,
    idtypestreet integer NOT NULL,
    longname text NOT NULL,
    shortname text,
    ispublic boolean NOT NULL,
    idlieudit integer,
    idthingbegin integer,
    idthingend integer,
    datedecisionmuni timestamp without time zone,
    idcategname integer NOT NULL,
    commentaire text
);


ALTER TABLE goeland.thi_street OWNER TO goeland;

--
-- Name: thi_street_building_address; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thi_street_building_address (
    idaddress integer NOT NULL,
    idthingbuilding integer,
    idthingstreet integer NOT NULL,
    number integer NOT NULL,
    extention text,
    isactive boolean NOT NULL,
    coordeo integer,
    coordsn integer,
    idplan integer,
    datecreation timestamp without time zone,
    ispublic boolean NOT NULL,
    egid integer,
    edid integer,
    idthingiloturb integer,
    nbrniveauxbatrcb integer,
    nbrlogementrcb integer,
    sommesurfacelogementrcb integer,
    sommenbrpieceslogementrcb integer
);


ALTER TABLE goeland.thi_street_building_address OWNER TO goeland;

--
-- Name: thing; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thing (
    idthing integer NOT NULL,
    idtypething integer NOT NULL,
    name text NOT NULL,
    description text,
    idcontainer integer,
    idcreator integer,
    idmodificator integer,
    datecreated timestamp without time zone NOT NULL,
    datelastmodif timestamp without time zone,
    dateinactivation timestamp without time zone,
    dateconstruction timestamp without time zone,
    isactive boolean NOT NULL,
    ishavingstory boolean NOT NULL,
    formatdateconstr character(1) NOT NULL,
    iconeurl text,
    infourl text,
    isvalidated boolean,
    datevalidation timestamp without time zone,
    codeordre text
);


ALTER TABLE goeland.thing OWNER TO goeland;

--
-- Name: thing_position; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.thing_position (
    idthing integer NOT NULL,
    mineo integer,
    maxsn integer,
    maxeo integer,
    minsn integer,
    idplan integer
);


ALTER TABLE goeland.thing_position OWNER TO goeland;

--
-- Name: type_thi_street; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.type_thi_street (
    idtypestreet integer NOT NULL,
    label text,
    description text,
    isactive boolean NOT NULL
);


ALTER TABLE goeland.type_thi_street OWNER TO goeland;

--
-- Name: type_thing; Type: TABLE; Schema: goeland; Owner: goeland
--

CREATE TABLE goeland.type_thing (
    idtypething integer NOT NULL,
    name text NOT NULL,
    description text,
    datecreated timestamp without time zone NOT NULL,
    idcreator integer NOT NULL,
    tablename text,
    idmanagerthing integer,
    thedefault text,
    maxidentity integer,
    isactive boolean NOT NULL,
    flag integer NOT NULL,
    b4internet boolean NOT NULL,
    iconeurl text,
    infotypeurl text,
    typegeometrie text
);


ALTER TABLE goeland.type_thing OWNER TO goeland;

--
-- Name: abreviation_cantonale; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.abreviation_cantonale (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.abreviation_cantonale OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_seq; Type: SEQUENCE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE SEQUENCE movd.t_ili2db_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE movd.t_ili2db_seq OWNER TO gc_transfert_dbo;

--
-- Name: aplan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.aplan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    dossiertech character varying(12),
    en_vigueur date,
    approbation_dm date,
    codeplan character varying(9),
    ufid bigint,
    origine bigint,
    CONSTRAINT aplan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.aplan OWNER TO gc_transfert_dbo;

--
-- Name: arete; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.arete (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurveZ,2056),
    qualite character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT arete_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.arete OWNER TO gc_transfert_dbo;

--
-- Name: arete_genre; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.arete_genre (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.arete_genre OWNER TO gc_transfert_dbo;

--
-- Name: asignal; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.asignal (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    numero character varying(12),
    exploitant character varying(30),
    geometrie public.geometry(Point,2056),
    qualite character varying(255),
    genre character varying(255),
    genre_point character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT asignal_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.asignal OWNER TO gc_transfert_dbo;

--
-- Name: bien_fonds; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.bien_fonds (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    partienumeroimmeuble character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    superficie integer,
    superficierf integer,
    ufid bigint,
    bien_fonds_de bigint,
    CONSTRAINT bien_fonds_superficie_check CHECK (((superficie >= 1) AND (superficie <= 999999999))),
    CONSTRAINT bien_fonds_superficierf_check CHECK (((superficierf >= 1) AND (superficierf <= 999999999))),
    CONSTRAINT bien_fonds_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.bien_fonds OWNER TO gc_transfert_dbo;

--
-- Name: bien_fondsproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.bien_fondsproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    partienumeroimmeuble character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    superficie integer,
    superficierf integer,
    ufid bigint,
    bien_fondsproj_de bigint,
    CONSTRAINT bien_fondsproj_superficie_check CHECK (((superficie >= 1) AND (superficie <= 999999999))),
    CONSTRAINT bien_fondsproj_superficierf_check CHECK (((superficierf >= 1) AND (superficierf <= 999999999))),
    CONSTRAINT bien_fondsproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.bien_fondsproj OWNER TO gc_transfert_dbo;

--
-- Name: bord_de_plan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.bord_de_plan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(32),
    type_bord_de_plan character varying(20),
    numero_du_plan character varying(12),
    nom_commune character varying(30),
    nom_geometre character varying(30),
    date_etablissement date,
    nom_geometre_conservateur character varying(30),
    date_maj date,
    nombre_echelle integer,
    origine_plan public.geometry(Point,2056),
    e_azimut numeric(4,1),
    nombre_echelle_plan_synoptique integer,
    origine_plan_synoptique public.geometry(Point,2056),
    avec_reseau_coord character varying(255),
    format_plan character varying(255),
    ufid bigint,
    CONSTRAINT bord_de_plan_e_azimut_check CHECK (((e_azimut >= 0.0) AND (e_azimut <= 399.9))),
    CONSTRAINT bord_de_plan_nombre_echelle_check CHECK (((nombre_echelle >= 1) AND (nombre_echelle <= 1000000))),
    CONSTRAINT bord_de_plan_nombre_echll_pln_synptque_check CHECK (((nombre_echelle_plan_synoptique >= 1) AND (nombre_echelle_plan_synoptique <= 1000000))),
    CONSTRAINT bord_de_plan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.bord_de_plan OWNER TO gc_transfert_dbo;

--
-- Name: bord_de_plan_avec_reseau_coord; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.bord_de_plan_avec_reseau_coord (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.bord_de_plan_avec_reseau_coord OWNER TO gc_transfert_dbo;

--
-- Name: commune; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.commune (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(30),
    noofs integer,
    numcom integer,
    ufid bigint,
    CONSTRAINT commune_noofs_check CHECK (((noofs >= 1) AND (noofs <= 9999))),
    CONSTRAINT commune_numcom_check CHECK (((numcom >= 1) AND (numcom <= 388))),
    CONSTRAINT commune_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.commune OWNER TO gc_transfert_dbo;

--
-- Name: croix_filet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.croix_filet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    genre character varying(255),
    ufid bigint,
    croix_filet_de bigint,
    CONSTRAINT croix_filet_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT croix_filet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.croix_filet OWNER TO gc_transfert_dbo;

--
-- Name: ddp; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.ddp (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    partienumeroimmeuble character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    superficie integer,
    superficierf integer,
    ufid bigint,
    ddp_de bigint,
    CONSTRAINT ddp_superficie_check CHECK (((superficie >= 1) AND (superficie <= 999999999))),
    CONSTRAINT ddp_superficierf_check CHECK (((superficierf >= 1) AND (superficierf <= 999999999))),
    CONSTRAINT ddp_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.ddp OWNER TO gc_transfert_dbo;

--
-- Name: ddpproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.ddpproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    partienumeroimmeuble character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    superficie integer,
    superficierf integer,
    ufid bigint,
    ddpproj_de bigint,
    CONSTRAINT ddpproj_superficie_check CHECK (((superficie >= 1) AND (superficie <= 999999999))),
    CONSTRAINT ddpproj_superficierf_check CHECK (((superficierf >= 1) AND (superficierf <= 999999999))),
    CONSTRAINT ddpproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.ddpproj OWNER TO gc_transfert_dbo;

--
-- Name: description_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.description_batiment (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    texte character varying(100),
    langue character varying(255),
    ufid bigint,
    description_batiment_de bigint,
    CONSTRAINT description_batiment_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.description_batiment OWNER TO gc_transfert_dbo;

--
-- Name: description_plan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.description_plan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    adescription character varying(30),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT description_plan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.description_plan OWNER TO gc_transfert_dbo;

--
-- Name: designation_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.designation_batiment (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.designation_batiment OWNER TO gc_transfert_dbo;

--
-- Name: domaine_numerotation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.domaine_numerotation (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    ct character varying(255),
    numerodn character varying(10),
    dossiertech character varying(12),
    en_vigueur date,
    ufid bigint,
    CONSTRAINT domaine_numerotation_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.domaine_numerotation OWNER TO gc_transfert_dbo;

--
-- Name: element_conduite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.element_conduite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    exploitant character varying(30),
    qualite character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT element_conduite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.element_conduite OWNER TO gc_transfert_dbo;

--
-- Name: element_lineaire; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.element_lineaire (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    ufid bigint,
    element_lineaire_de bigint,
    CONSTRAINT element_lineaire_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.element_lineaire OWNER TO gc_transfert_dbo;

--
-- Name: element_lineaire_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.element_lineaire_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.element_lineaire_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: element_ponctuel; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.element_ponctuel (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(Point,2056),
    ori numeric(4,1),
    ufid bigint,
    element_ponctuel_de bigint,
    CONSTRAINT element_ponctuel_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT element_ponctuel_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.element_ponctuel OWNER TO gc_transfert_dbo;

--
-- Name: element_surfacique; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.element_surfacique (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    element_surfacique_de bigint,
    CONSTRAINT element_surfacique_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.element_surfacique OWNER TO gc_transfert_dbo;

--
-- Name: entree_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.entree_batiment (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    validite character varying(255),
    en_cours_modification character varying(255),
    attributs_provisoires character varying(255),
    est_designation_officielle character varying(255),
    pos public.geometry(Point,2056),
    niveau integer,
    numero_maison character varying(12),
    dans_batiment character varying(255),
    regbl_egid integer,
    regbl_edid integer,
    ufid bigint,
    entree_batiment_de bigint,
    origine bigint,
    CONSTRAINT entree_batiment_niveau_check CHECK (((niveau >= '-99'::integer) AND (niveau <= 99))),
    CONSTRAINT entree_batiment_regbl_edid_check CHECK (((regbl_edid >= 0) AND (regbl_edid <= 99))),
    CONSTRAINT entree_batiment_regbl_egid_check CHECK (((regbl_egid >= 1) AND (regbl_egid <= 999999999))),
    CONSTRAINT entree_batiment_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.entree_batiment OWNER TO gc_transfert_dbo;

--
-- Name: entree_batiment_attributs_provisoires; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.entree_batiment_attributs_provisoires (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.entree_batiment_attributs_provisoires OWNER TO gc_transfert_dbo;

--
-- Name: entree_batiment_dans_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.entree_batiment_dans_batiment (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.entree_batiment_dans_batiment OWNER TO gc_transfert_dbo;

--
-- Name: entree_batiment_en_cours_modification; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.entree_batiment_en_cours_modification (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.entree_batiment_en_cours_modification OWNER TO gc_transfert_dbo;

--
-- Name: entree_batiment_est_designation_officielle; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.entree_batiment_est_designation_officielle (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.entree_batiment_est_designation_officielle OWNER TO gc_transfert_dbo;

--
-- Name: fiabilite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.fiabilite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.fiabilite OWNER TO gc_transfert_dbo;

--
-- Name: localisation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localisation (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    principe_numerotation character varying(255),
    numero_localisation character varying(12),
    attributs_provisoires character varying(255),
    est_designation_officielle character varying(255),
    validite character varying(255),
    en_cours_modification character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT localisation_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.localisation OWNER TO gc_transfert_dbo;

--
-- Name: nom_localisation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nom_localisation (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    texte character varying(60),
    texte_abrege character varying(24),
    texte_index character varying(16),
    langue character varying(255),
    ufid bigint,
    nom_localisation_de bigint,
    CONSTRAINT nom_localisation_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nom_localisation OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_basket; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_basket (
    fid bigint NOT NULL,
    dataset bigint,
    topic character varying(200) NOT NULL,
    t_ili_tid character varying(200),
    attachmentkey character varying(200) NOT NULL,
    domains character varying(1024)
);


ALTER TABLE movd.t_ili2db_basket OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_dataset; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_dataset (
    fid bigint NOT NULL,
    datasetname character varying(200)
);


ALTER TABLE movd.t_ili2db_dataset OWNER TO gc_transfert_dbo;

--
-- Name: troncon_rue; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.troncon_rue (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    point_depart public.geometry(Point,2056),
    ordre integer,
    est_axe character varying(255),
    ufid bigint,
    troncon_rue_de bigint,
    CONSTRAINT troncon_rue_ordre_check CHECK (((ordre >= 1) AND (ordre <= 999))),
    CONSTRAINT troncon_rue_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.troncon_rue OWNER TO gc_transfert_dbo;

--
-- Name: localisation_rue; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.localisation_rue (
    fid integer NOT NULL,
    longname character varying(60),
    shortname character varying(24),
    coderue integer,
    numcom character varying(3),
    geometrie public.geometry(Geometry,2056)
);


ALTER TABLE specificite_lausanne.localisation_rue OWNER TO gc_transfert_dbo;

--
-- Name: gc_ad_axe_rue; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_ad_axe_rue AS
 SELECT s.idthing AS id_thing,
    nl.texte AS longname,
    nl.texte_abrege AS shortname,
    s.estrid,
    s.coderue,
    ts.description AS typestreet,
    s.datedecisionmuni AS datemuni,
    (d.datasetname)::integer AS numcom,
    public.st_union(tr.geometrie) AS geom
   FROM ((((((movd.localisation l
     JOIN movd.nom_localisation nl ON ((l.fid = nl.nom_localisation_de)))
     JOIN movd.troncon_rue tr ON ((l.fid = tr.troncon_rue_de)))
     LEFT JOIN goeland.thi_street s ON (((nl.texte)::text = s.longname)))
     LEFT JOIN goeland.type_thi_street ts ON ((s.idtypestreet = ts.idtypestreet)))
     JOIN movd.t_ili2db_basket b ON ((l.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE (ts.description <> ALL (ARRAY['Place'::text, 'Placette'::text, 'Esplanade'::text, 'Parc'::text, 'Terrasse'::text, 'Square'::text, 'Quartier'::text]))
  GROUP BY s.idthing, nl.texte, nl.texte_abrege, s.estrid, s.coderue, ts.description, s.datedecisionmuni, (d.datasetname)::integer
UNION ALL
 SELECT s.idthing AS id_thing,
    r.longname,
    r.shortname,
    s.estrid,
    s.coderue,
    split_part((r.longname)::text, ' '::text, 1) AS typestreet,
    s.datedecisionmuni AS datemuni,
    (r.numcom)::integer AS numcom,
    r.geometrie AS geom
   FROM ((specificite_lausanne.localisation_rue r
     LEFT JOIN goeland.thi_street s ON ((r.coderue = s.coderue)))
     LEFT JOIN goeland.type_thi_street ts ON ((s.idtypestreet = ts.idtypestreet)))
  WHERE (split_part((r.longname)::text, ' '::text, 1) <> 'Parc'::text);


ALTER TABLE movd.gc_ad_axe_rue OWNER TO gc_transfert_dbo;

--
-- Name: posnumero_maison; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnumero_maison (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnumero_batiment_de bigint,
    CONSTRAINT posnumero_maison_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnumero_maison_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnumero_maison OWNER TO gc_transfert_dbo;

--
-- Name: gc_ad_bati; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_ad_bati AS
 SELECT eb.numero_maison AS textstring,
    eb.regbl_egid AS egid,
    eb.regbl_edid AS edid,
    nl.texte AS rue_off,
    nl.texte_abrege AS rue_abr,
    g.idthingbuilding AS id_go,
    (d.datasetname)::integer AS numcom,
    eb.pos AS geom
   FROM ((((((movd.entree_batiment eb
     JOIN movd.localisation l ON ((l.fid = eb.entree_batiment_de)))
     JOIN movd.nom_localisation nl ON ((l.fid = nl.nom_localisation_de)))
     JOIN movd.posnumero_maison pm ON ((eb.fid = pm.posnumero_batiment_de)))
     LEFT JOIN goeland.thi_street_building_address g ON (((eb.regbl_egid = g.egid) AND ((eb.numero_maison)::text = concat((g.number)::text, g.extention)))))
     JOIN movd.t_ili2db_basket b ON ((l.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_ad_bati OWNER TO gc_transfert_dbo;

--
-- Name: entree_batiment_projet; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.entree_batiment_projet (
    fid bigint NOT NULL,
    numero character varying(5),
    extension character varying(5),
    nom_complet character varying(200),
    nom_court character varying(100),
    coordonnee_e real,
    coordonnee_n real,
    geometrie public.geometry(Point,2056),
    code_rue integer,
    orientation numeric(7,3)
);


ALTER TABLE specificite_lausanne.entree_batiment_projet OWNER TO gc_transfert_dbo;

--
-- Name: gc_ad_bati_projet; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_ad_bati_projet AS
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
   FROM (specificite_lausanne.entree_batiment_projet eb
     LEFT JOIN goeland.thi_building g ON ((((eb.nom_court)::text = ANY (string_to_array(g.name, ' '::text))) AND (concat(eb.numero, eb.extension) = ANY (regexp_split_to_array(g.name, ',| '::text))))))
  WHERE (g.idcodestatus <> ALL (ARRAY[4, 5]));


ALTER TABLE movd.gc_ad_bati_projet OWNER TO gc_transfert_dbo;

--
-- Name: posnom_localisation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnom_localisation (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    indice_deb integer,
    indice_fin integer,
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ligne_auxiliaire public.geometry(CompoundCurve,2056),
    ufid bigint,
    posnom_localisation_de bigint,
    CONSTRAINT posnom_localisation_indice_deb_check CHECK (((indice_deb >= 1) AND (indice_deb <= 60))),
    CONSTRAINT posnom_localisation_indice_fin_check CHECK (((indice_fin >= 1) AND (indice_fin <= 60))),
    CONSTRAINT posnom_localisation_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnom_localisation_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnom_localisation OWNER TO gc_transfert_dbo;

--
-- Name: gc_ad_route_txt; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_ad_route_txt AS
 SELECT nl.texte AS textstring,
        CASE
            WHEN ((pnl.grandeur)::text = 'petite'::text) THEN 0.5
            WHEN ((pnl.grandeur)::text = 'moyenne'::text) THEN (1)::numeric
            WHEN ((pnl.grandeur)::text = 'grande'::text) THEN (2)::numeric
            ELSE (NULL::integer)::numeric
        END AS text_size,
    mod(((450)::numeric - (0.9 * pnl.ori)), (360)::numeric) AS text_angle,
        CASE
            WHEN ((l.genre)::text = 'Rue'::text) THEN 'ROUTE_TXT'::text
            WHEN ((l.genre)::text = 'Lieu_denomme'::text) THEN 'NOM_TXT'::text
            WHEN ((l.genre)::text = 'Place'::text) THEN 'PLACE_TXT'::text
            ELSE NULL::text
        END AS type,
    (d.datasetname)::integer AS numcom,
    pnl.pos AS geom
   FROM ((((movd.localisation l
     JOIN movd.nom_localisation nl ON ((l.fid = nl.nom_localisation_de)))
     JOIN movd.posnom_localisation pnl ON ((nl.fid = pnl.posnom_localisation_de)))
     JOIN movd.t_ili2db_basket b ON ((l.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_ad_route_txt OWNER TO gc_transfert_dbo;

--
-- Name: immeuble; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.immeuble (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    egris_egrid character varying(14),
    validite character varying(255),
    integralite character varying(255),
    genre character varying(255),
    superficie_totale integer,
    ufid bigint,
    origine bigint,
    CONSTRAINT immeuble_superficie_totale_check CHECK (((superficie_totale >= 1) AND (superficie_totale <= 999999999))),
    CONSTRAINT immeuble_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.immeuble OWNER TO gc_transfert_dbo;

--
-- Name: posimmeuble; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posimmeuble (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ligne_auxiliaire public.geometry(CompoundCurve,2056),
    ufid bigint,
    posimmeuble_de bigint,
    CONSTRAINT posimmeuble_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posimmeuble_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posimmeuble OWNER TO gc_transfert_dbo;

--
-- Name: gc_bf_parc_no; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_bf_parc_no AS
 SELECT i.numero AS no_parc,
    (
        CASE
            WHEN ((i.genre)::text ~~ 'DDP.%'::text) THEN 'DDP'::text
            WHEN ((i.genre)::text ~~ '%.parcelle_prive'::text) THEN 'PAR'::text
            WHEN ((i.genre)::text ~~ '%.DP_%'::text) THEN 'DP'::text
            ELSE NULL::text
        END)::character varying(10) AS type,
    mod(((450)::numeric - (0.9 * pi.ori)), (360)::numeric) AS or_text,
    (d.datasetname)::integer AS numcom,
    pi.pos AS geom
   FROM (((movd.immeuble i
     JOIN movd.posimmeuble pi ON ((i.fid = pi.posimmeuble_de)))
     JOIN movd.t_ili2db_basket b ON ((i.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_bf_parc_no OWNER TO gc_transfert_dbo;

--
-- Name: mine; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mine (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    partienumeroimmeuble character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    superficie integer,
    ufid bigint,
    mine_de bigint,
    CONSTRAINT mine_superficie_check CHECK (((superficie >= 1) AND (superficie <= 999999999))),
    CONSTRAINT mine_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mine OWNER TO gc_transfert_dbo;

--
-- Name: gc_bf_parc_pol; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_bf_parc_pol AS
 SELECT i.numero AS no_parc,
        CASE
            WHEN ((i.genre)::text = 'bien_fonds.DP_communal'::text) THEN 'DP_COM'::character varying
            WHEN ((i.genre)::text = 'bien_fonds.DP_cantonal'::text) THEN 'DP_CANT'::character varying
            WHEN (((i.genre)::text ~~ 'DDP%'::text) AND (p.resumeproprietaire = 'Commune de Lausanne'::text)) THEN 'DDPCOM'::character varying
            WHEN (((i.genre)::text ~~ 'DDP%'::text) AND (p.resumeproprietaire <> 'Commune de Lausanne'::text)) THEN 'DDP'::character varying
            WHEN (((i.genre)::text = 'bien_fonds.parcelle_prive'::text) AND (p.resumeproprietaire = 'Commune de Lausanne'::text)) THEN 'PARCOM'::character varying(10)
            WHEN (((i.genre)::text = 'bien_fonds.parcelle_prive'::text) AND (p.resumeproprietaire <> 'Commune de Lausanne'::text)) THEN 'PAR'::character varying
            ELSE NULL::character varying(10)
        END AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(bf.geometrie) AS geom
   FROM ((((movd.immeuble i
     JOIN movd.bien_fonds bf ON ((i.fid = bf.bien_fonds_de)))
     LEFT JOIN goeland.parcelle p ON (((i.egris_egrid)::text = p.egrid)))
     JOIN movd.t_ili2db_basket b ON ((i.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
UNION
 SELECT i.numero AS no_parc,
    (
        CASE
            WHEN ((i.genre)::text = 'bien_fonds.DP_communal'::text) THEN 'DP_COM'::text
            WHEN ((i.genre)::text = 'bien_fonds.DP_cantonal'::text) THEN 'DP_CANT'::text
            WHEN (((i.genre)::text ~~ 'DDP%'::text) AND (p.resumeproprietaire = 'Commune de Lausanne'::text)) THEN 'DDPCOM'::text
            WHEN (((i.genre)::text ~~ 'DDP%'::text) AND (p.resumeproprietaire <> 'Commune de Lausanne'::text)) THEN 'DDP'::text
            WHEN (((i.genre)::text = 'bien_fonds.parcelle_prive'::text) AND (p.resumeproprietaire = 'Commune de Lausanne'::text)) THEN 'PARCOM'::text
            WHEN (((i.genre)::text = 'bien_fonds.parcelle_prive'::text) AND (p.resumeproprietaire <> 'Commune de Lausanne'::text)) THEN 'PAR'::text
            ELSE NULL::text
        END)::character varying(10) AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(ddp.geometrie) AS geom
   FROM ((((movd.immeuble i
     JOIN movd.ddp ON ((i.fid = ddp.ddp_de)))
     LEFT JOIN goeland.parcelle p ON (((i.egris_egrid)::text = p.egrid)))
     JOIN movd.t_ili2db_basket b ON ((i.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
UNION
 SELECT i.numero AS no_parc,
    (
        CASE
            WHEN ((i.genre)::text = 'bien_fonds.DP_communal'::text) THEN 'DP_COM'::text
            WHEN ((i.genre)::text = 'bien_fonds.DP_cantonal'::text) THEN 'DP_CANT'::text
            WHEN (((i.genre)::text ~~ 'DDP%'::text) AND (p.resumeproprietaire = 'Commune de Lausanne'::text)) THEN 'DDPCOM'::text
            WHEN (((i.genre)::text ~~ 'DDP%'::text) AND (p.resumeproprietaire <> 'Commune de Lausanne'::text)) THEN 'DDP'::text
            WHEN (((i.genre)::text = 'bien_fonds.parcelle_prive'::text) AND (p.resumeproprietaire = 'Commune de Lausanne'::text)) THEN 'PARCOM'::text
            WHEN (((i.genre)::text = 'bien_fonds.parcelle_prive'::text) AND (p.resumeproprietaire <> 'Commune de Lausanne'::text)) THEN 'PAR'::text
            ELSE NULL::text
        END)::character varying(10) AS type,
    i.egris_egrid AS egrid,
    p.idthing AS id_go,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(m.geometrie) AS geom
   FROM ((((movd.immeuble i
     JOIN movd.mine m ON ((i.fid = m.mine_de)))
     LEFT JOIN goeland.parcelle p ON (((i.egris_egrid)::text = p.egrid)))
     JOIN movd.t_ili2db_basket b ON ((i.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_bf_parc_pol OWNER TO gc_transfert_dbo;

--
-- Name: point_limite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_limite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    geometrie public.geometry(Point,2056),
    precplan numeric(4,1),
    fiabplan character varying(255),
    signe character varying(255),
    defini_exactement character varying(255),
    anc_borne_speciale character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT point_limite_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT point_limite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.point_limite OWNER TO gc_transfert_dbo;

--
-- Name: point_limite_ter; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_limite_ter (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identification character varying(12),
    geometrie public.geometry(Point,2056),
    precplan numeric(4,1),
    fiabplan character varying(255),
    signe character varying(255),
    borne_territoriale character varying(255),
    defini_exactement character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT point_limite_ter_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT point_limite_ter_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.point_limite_ter OWNER TO gc_transfert_dbo;

--
-- Name: gc_bf_point; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_bf_point AS
 SELECT p.identification AS numero,
    (d.datasetname)::integer AS numcom,
    p.identdn,
    (p.signe)::character varying(20) AS signe,
    (p.defini_exactement)::character varying(8) AS def_exact,
    (p.precplan)::numeric(5,1) AS prec_plan,
    (p.fiabplan)::character varying(8) AS fiab_plan,
    NULL::character varying(4) AS codea,
    (public.st_y(p.geometrie))::numeric(10,3) AS y,
    (public.st_x(p.geometrie))::numeric(10,3) AS x,
    p.geometrie AS geom
   FROM ((movd.point_limite p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
UNION ALL
 SELECT t.identification AS numero,
    (d.datasetname)::integer AS numcom,
    NULL::character varying(12) AS identdn,
    (t.signe)::character varying(20) AS signe,
    (t.defini_exactement)::character varying(8) AS def_exact,
    (t.precplan)::numeric(5,1) AS prec_plan,
    (t.fiabplan)::character varying(8) AS fiab_plan,
    NULL::character varying(4) AS codea,
    (public.st_y(t.geometrie))::numeric(10,3) AS y,
    (public.st_x(t.geometrie))::numeric(10,3) AS x,
    t.geometrie AS geom
   FROM ((movd.point_limite_ter t
     JOIN movd.t_ili2db_basket b ON ((t.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_bf_point OWNER TO gc_transfert_dbo;

--
-- Name: numero_de_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.numero_de_batiment (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    numero character varying(12),
    regbl_egid integer,
    designation character varying(255),
    ufid bigint,
    numero_de_batiment_de bigint,
    CONSTRAINT numero_de_batiment_regbl_egid_check CHECK (((regbl_egid >= 1) AND (regbl_egid <= 999999999))),
    CONSTRAINT numero_de_batiment_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.numero_de_batiment OWNER TO gc_transfert_dbo;

--
-- Name: numero_objet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.numero_objet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    numero character varying(12),
    regbl_egid integer,
    designation character varying(255),
    ufid bigint,
    numero_objet_de bigint,
    CONSTRAINT numero_objet_regbl_egid_check CHECK (((regbl_egid >= 1) AND (regbl_egid <= 999999999))),
    CONSTRAINT numero_objet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.numero_objet OWNER TO gc_transfert_dbo;

--
-- Name: posnumero_de_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnumero_de_batiment (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnumero_de_batiment_de bigint,
    CONSTRAINT posnumero_de_batiment_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnumero_de_batiment_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnumero_de_batiment OWNER TO gc_transfert_dbo;

--
-- Name: posnumero_objet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnumero_objet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnumero_objet_de bigint,
    CONSTRAINT posnumero_objet_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnumero_objet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnumero_objet OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_bati_eca; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_bati_eca AS
 SELECT n.numero AS textstring,
    n.regbl_egid AS egid,
    mod(((450)::numeric - (0.9 * p.ori)), (360)::numeric) AS text_angle,
    (d.datasetname)::integer AS numcom,
    p.pos AS geom
   FROM (((movd.numero_de_batiment n
     JOIN movd.posnumero_de_batiment p ON ((n.fid = p.posnumero_de_batiment_de)))
     JOIN movd.t_ili2db_basket b ON ((n.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
UNION ALL
 SELECT n.numero AS textstring,
    n.regbl_egid AS egid,
    mod(((450)::numeric - (0.9 * p.ori)), (360)::numeric) AS text_angle,
    (d.datasetname)::integer AS numcom,
    p.pos AS geom
   FROM (((movd.numero_objet n
     JOIN movd.posnumero_objet p ON ((n.fid = p.posnumero_objet_de)))
     JOIN movd.t_ili2db_basket b ON ((n.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_cs_bati_eca OWNER TO gc_transfert_dbo;

--
-- Name: genre_od; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_od (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_od OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24objets_divers_nom_objet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24objets_divers_nom_objet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(30),
    ufid bigint,
    nom_objet_de bigint,
    CONSTRAINT md01mvdmn95v_dvrs_nm_bjet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24objets_divers_nom_objet OWNER TO gc_transfert_dbo;

--
-- Name: nom_objet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nom_objet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(30),
    ufid bigint,
    nom_objet_de bigint,
    CONSTRAINT nom_objet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nom_objet OWNER TO gc_transfert_dbo;

--
-- Name: objet_divers; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.objet_divers (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    qualite character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT objet_divers_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.objet_divers OWNER TO gc_transfert_dbo;

--
-- Name: surfacecs; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.surfacecs (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    qualite character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT surfacecs_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.surfacecs OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_bati_pol; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_bati_pol AS
 SELECT g.idthibuilding AS id_go,
    n.regbl_egid AS egid,
    n.numero AS no_eca,
    (n.designation)::character varying(30) AS design,
    initcap(regexp_replace((db.dispname)::text, '\.'::text, ' - '::text, 'g'::text)) AS design_txt,
    (s.genre)::character varying(30) AS type,
    no.nom AS nom_objet,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM ((((((movd.surfacecs s
     JOIN movd.numero_de_batiment n ON ((s.fid = n.numero_de_batiment_de)))
     JOIN movd.designation_batiment db ON (((n.designation)::text = (db.ilicode)::text)))
     LEFT JOIN movd.nom_objet no ON ((s.fid = no.nom_objet_de)))
     LEFT JOIN ( SELECT DISTINCT ON (thi_building_no_eca.numeroeca) thi_building_no_eca.idthibuilding,
            thi_building_no_eca.numeroeca
           FROM goeland.thi_building_no_eca
          ORDER BY thi_building_no_eca.numeroeca, thi_building_no_eca.idthibuilding) g ON ((g.numeroeca = regexp_replace((n.numero)::text, '\D$'::text, ''::text, 'g'::text))))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
UNION ALL
 SELECT g.idthibuilding AS id_go,
    n.regbl_egid AS egid,
    n.numero AS no_eca,
    (n.designation)::character varying(30) AS design,
    initcap(regexp_replace((go.dispname)::text, '\.'::text, ' - '::text, 'g'::text)) AS design_txt,
    (s.genre)::character varying(30) AS type,
    no.nom AS nom_objet,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(es.geometrie) AS geom
   FROM (((((((movd.objet_divers s
     JOIN movd.element_surfacique es ON ((s.fid = es.element_surfacique_de)))
     JOIN movd.numero_objet n ON ((s.fid = n.numero_objet_de)))
     JOIN movd.genre_od go ON (((s.genre)::text = (go.ilicode)::text)))
     LEFT JOIN movd.md01mvdmn95v24objets_divers_nom_objet no ON ((s.fid = no.nom_objet_de)))
     LEFT JOIN ( SELECT DISTINCT ON (thi_building_no_eca.numeroeca) thi_building_no_eca.idthibuilding,
            thi_building_no_eca.numeroeca
           FROM goeland.thi_building_no_eca
          ORDER BY thi_building_no_eca.numeroeca, thi_building_no_eca.idthibuilding) g ON ((g.numeroeca = regexp_replace((n.numero)::text, '\D$'::text, ''::text, 'g'::text))))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_cs_bati_pol OWNER TO gc_transfert_dbo;

--
-- Name: surfacecsproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.surfacecsproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    qualite character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT surfacecsproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.surfacecsproj OWNER TO gc_transfert_dbo;

--
-- Name: surface_batiment_projet; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.surface_batiment_projet (
    fid bigint NOT NULL,
    genre character varying(50),
    geometrie public.geometry(Geometry,2056),
    id_go integer
);


ALTER TABLE specificite_lausanne.surface_batiment_projet OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_bati_pol_projet; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_bati_pol_projet AS
 SELECT NULL::text AS no_eca,
    NULL::text AS design_id,
    'batiment_projet'::text AS design,
    'Batiment projet'::text AS design_txt,
    bp.genre AS type,
    bp.id_go,
    132 AS numcom,
    public.st_curvetoline(bp.geometrie) AS geom
   FROM specificite_lausanne.surface_batiment_projet bp
UNION ALL
 SELECT NULL::text AS no_eca,
    NULL::text AS design_id,
    'batiment_projet'::text AS design,
    'Batiment projet'::text AS design_txt,
    (s.genre)::character varying(50) AS type,
    NULL::integer AS id_go,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM ((movd.surfacecsproj s
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text);


ALTER TABLE movd.gc_cs_bati_pol_projet OWNER TO gc_transfert_dbo;

--
-- Name: genre_cs; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_cs (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_cs OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_boise; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_boise AS
 SELECT (s.genre)::character varying(50) AS genre,
        CASE
            WHEN (g.itfcode = 18) THEN 19
            WHEN (g.itfcode = 19) THEN 20
            WHEN (g.itfcode = 20) THEN 21
            WHEN (g.itfcode = 21) THEN 22
            ELSE NULL::integer
        END AS genre_id,
    (initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)))::character varying(50) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM (((movd.surfacecs s
     JOIN movd.genre_cs g ON (((s.genre)::text = (g.ilicode)::text)))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((s.genre)::text ~~ 'boisee.%'::text);


ALTER TABLE movd.gc_cs_boise OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_eau; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_eau AS
 SELECT
        CASE
            WHEN (g.itfcode = 6) THEN 7
            WHEN (g.itfcode = 15) THEN 16
            WHEN (g.itfcode = 16) THEN 17
            WHEN (g.itfcode = 17) THEN 18
            ELSE NULL::integer
        END AS genre_id,
    (s.genre)::character varying(50) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM (((movd.surfacecs s
     JOIN movd.genre_cs g ON (((s.genre)::text = (g.ilicode)::text)))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE (((s.genre)::text ~~ 'eau.%'::text) OR ((s.genre)::text ~~ '%.bassin'::text));


ALTER TABLE movd.gc_cs_eau OWNER TO gc_transfert_dbo;

--
-- Name: point_particulier; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_particulier (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    geometrie public.geometry(Point,2056),
    precplan numeric(4,1),
    fiabplan character varying(255),
    defini_exactement character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT point_particulier_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT point_particulier_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.point_particulier OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_pts_fiab; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_pts_fiab AS
 SELECT p.identification AS numero,
    p.identdn,
    (d.datasetname)::integer AS numcom,
    6 AS signe,
    (p.defini_exactement)::character varying(8) AS def_exact,
    p.precplan AS prec_plan,
    (p.fiabplan)::character varying(8) AS fiab_plan,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geometrie AS geom
   FROM ((movd.point_particulier p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE (((p.defini_exactement)::text = 'oui'::text) AND (p.precplan < 4.6) AND ((p.fiabplan)::text = 'oui'::text));


ALTER TABLE movd.gc_cs_pts_fiab OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_rev_dur; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_rev_dur AS
 SELECT
        CASE
            WHEN (g.itfcode = 1) THEN 2
            WHEN (g.itfcode = 2) THEN 3
            WHEN (g.itfcode = 3) THEN 4
            WHEN (g.itfcode = 4) THEN 5
            WHEN (g.itfcode = 5) THEN 6
            WHEN (g.itfcode = 7) THEN 8
            WHEN (g.itfcode = 8) THEN 9
            ELSE NULL::integer
        END AS genre_id,
    (s.genre)::character varying(50) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM (((movd.surfacecs s
     JOIN movd.genre_cs g ON (((s.genre)::text = (g.ilicode)::text)))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE (((s.genre)::text ~~ 'revetement_dur.%'::text) AND ((s.genre)::text !~~ '%.bassin'::text));


ALTER TABLE movd.gc_cs_rev_dur OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_sans_veg; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_sans_veg AS
 SELECT
        CASE
            WHEN (g.itfcode = 22) THEN 23
            WHEN (g.itfcode = 23) THEN 24
            WHEN (g.itfcode = 24) THEN 25
            WHEN (g.itfcode = 25) THEN 26
            WHEN (g.itfcode = 26) THEN 27
            WHEN (g.itfcode = 27) THEN 28
            ELSE NULL::integer
        END AS genre_id,
    (s.genre)::character varying(50) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM (((movd.surfacecs s
     JOIN movd.genre_cs g ON (((s.genre)::text = (g.ilicode)::text)))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((s.genre)::text ~~ 'sans_vegetation.%'::text);


ALTER TABLE movd.gc_cs_sans_veg OWNER TO gc_transfert_dbo;

--
-- Name: gc_cs_verte; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_cs_verte AS
 SELECT
        CASE
            WHEN (g.itfcode = 9) THEN 10
            WHEN (g.itfcode = 10) THEN 11
            WHEN (g.itfcode = 11) THEN 12
            WHEN (g.itfcode = 12) THEN 13
            WHEN (g.itfcode = 13) THEN 14
            WHEN (g.itfcode = 14) THEN 15
            ELSE NULL::integer
        END AS genre_id,
    (s.genre)::character varying(50) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(s.geometrie) AS geom
   FROM (((movd.surfacecs s
     JOIN movd.genre_cs g ON (((s.genre)::text = (g.ilicode)::text)))
     JOIN movd.t_ili2db_basket b ON ((s.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((s.genre)::text ~~ 'verte.%'::text);


ALTER TABLE movd.gc_cs_verte OWNER TO gc_transfert_dbo;

--
-- Name: limite_commune; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.limite_commune (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    limite_commune_de bigint,
    origine bigint,
    CONSTRAINT limite_commune_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.limite_commune OWNER TO gc_transfert_dbo;

--
-- Name: gc_lim_com; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_lim_com AS
 SELECT c.noofs,
    c.numcom,
    c.nom,
    public.st_curvetoline(lc.geometrie) AS geom
   FROM (movd.commune c
     JOIN movd.limite_commune lc ON ((c.fid = lc.limite_commune_de)));


ALTER TABLE movd.gc_lim_com OWNER TO gc_transfert_dbo;

--
-- Name: objet_divers_ponctuel; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.objet_divers_ponctuel (
    ufid integer NOT NULL,
    genre character varying(50),
    numcom smallint,
    geometrie public.geometry(Geometry,2056),
    genre_id smallint
);


ALTER TABLE specificite_lausanne.objet_divers_ponctuel OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_arbre; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_arbre AS
 SELECT objet_divers_ponctuel.genre_id,
    objet_divers_ponctuel.genre,
    initcap(regexp_replace((objet_divers_ponctuel.genre)::text, '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_ponctuel.numcom)::integer AS numcom,
    objet_divers_ponctuel.geometrie AS geom
   FROM specificite_lausanne.objet_divers_ponctuel
  WHERE (objet_divers_ponctuel.genre_id = 40);


ALTER TABLE movd.gc_od_arbre OWNER TO gc_transfert_dbo;

--
-- Name: objet_divers_lineaire; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.objet_divers_lineaire (
    ufid integer NOT NULL,
    genre character varying(50),
    numcom character varying(10),
    geometrie public.geometry(Geometry,2056),
    genre_id smallint
);


ALTER TABLE specificite_lausanne.objet_divers_lineaire OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_bati_lim; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_bati_lim AS
 SELECT (g.itfcode + 1) AS genre_id,
    od.genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(el.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_lineaire el ON ((od.fid = el.element_lineaire_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('autre_corps_de_batiment.details'::character varying)::text, ('autre_corps_de_batiment.mur_mitoyen'::character varying)::text, ('couvert_independant'::character varying)::text]))
UNION
 SELECT objet_divers_lineaire.genre_id,
    objet_divers_lineaire.genre,
    initcap(regexp_replace(split_part((objet_divers_lineaire.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_lineaire.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE (objet_divers_lineaire.genre_id = ANY (ARRAY[77, 20001, 20002, 20003, 20023, 20038]));


ALTER TABLE movd.gc_od_bati_lim OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_bati_lim_projet; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_bati_lim_projet AS
 SELECT objet_divers_lineaire.genre_id,
    objet_divers_lineaire.genre,
    initcap(regexp_replace(split_part((objet_divers_lineaire.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_lineaire.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE (objet_divers_lineaire.genre_id = ANY (ARRAY[77, 57, 58, 59, 94]));


ALTER TABLE movd.gc_od_bati_lim_projet OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_divers_lim; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_divers_lim AS
 SELECT (g.itfcode + 1) AS genre_id,
    od.genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(el.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_lineaire el ON ((od.fid = el.element_lineaire_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text <> ALL (ARRAY[((('autre_corps_de_batiment.details'::character varying)::text)::character varying)::text, ((('autre_corps_de_batiment.mur_mitoyen'::character varying)::text)::character varying)::text, ((('couvert_independant'::character varying)::text)::character varying)::text, 'escalier_important'::text, 'mur'::text, 'autre.trottoir_a_ventiler'::text, 'sentier'::text, 'autre.bord_de_chaussee_a_ventiler'::text, 'eau_canalisee_souterraine'::text]))
UNION
 SELECT objet_divers_lineaire.genre_id,
    objet_divers_lineaire.genre,
    initcap(regexp_replace(split_part((objet_divers_lineaire.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_lineaire.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE (objet_divers_lineaire.genre_id = ANY (ARRAY[20, 24, 32, 45, 62, 63, 65, 66, 75, 78, 80, 45, 46, 88]));


ALTER TABLE movd.gc_od_divers_lim OWNER TO gc_transfert_dbo;

--
-- Name: objet_divers_surfacique; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.objet_divers_surfacique (
    ufid integer NOT NULL,
    genre_id smallint,
    genre character varying(50),
    numcom character varying(10),
    geometrie public.geometry(Geometry,2056)
);


ALTER TABLE specificite_lausanne.objet_divers_surfacique OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_divers_pol; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_divers_pol AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(100) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(es.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_surfacique es ON ((od.fid = es.element_surfacique_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('tunnel_passage_inferieur_galerie'::character varying)::text, ('pont_passerelle'::character varying)::text, ('autre.terrain_de_sport'::character varying)::text, 'monument'::text, 'ruine_objet_archeologique'::text, 'ouvrage_de_protection_des_rives'::text, 'debarcadere'::text, 'quai'::text, 'ru'::text, 'silo_tour_gazometre'::text, 'tour_panoramique'::text, 'reservoir'::text, 'autre.autre'::text]))
UNION ALL
 SELECT objet_divers_surfacique.genre_id,
    (objet_divers_surfacique.genre)::character varying(100) AS genre,
    initcap(regexp_replace(split_part((objet_divers_surfacique.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_surfacique.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_surfacique.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_surfacique
  WHERE (objet_divers_surfacique.genre_id = 77);


ALTER TABLE movd.gc_od_divers_pol OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_eau_lim; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_eau_lim AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(100) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(el.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_lineaire el ON ((od.fid = el.element_lineaire_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('conduite_forcee'::character varying)::text, ('autre.eau_a_ventiler'::character varying)::text, ('eau_canalisee_souterraine'::character varying)::text, ('source'::character varying)::text, 'ru'::text]))
UNION ALL
 SELECT objet_divers_lineaire.genre_id,
    (objet_divers_lineaire.genre)::character varying(100) AS genre,
    initcap(regexp_replace(split_part((objet_divers_lineaire.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_lineaire.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE (objet_divers_lineaire.genre_id = ANY (ARRAY[6, 48, 61, 64, 82, 93]));


ALTER TABLE movd.gc_od_eau_lim OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_eau_pol; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_eau_pol AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(100) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(es.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_surfacique es ON ((od.fid = es.element_surfacique_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('eau_canalisee_souterraine'::character varying)::text, ('autre.piscine'::character varying)::text, ('fontaine'::character varying)::text]))
UNION ALL
 SELECT objet_divers_surfacique.genre_id,
    (objet_divers_surfacique.genre)::character varying(100) AS genre,
    initcap(regexp_replace(split_part((objet_divers_surfacique.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_surfacique.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_surfacique.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_surfacique
  WHERE ((objet_divers_surfacique.genre)::text = ANY (ARRAY[('vl.eau_rive_a_ventiler'::character varying)::text, ('vl.bassin_a_ventiler'::character varying)::text]));


ALTER TABLE movd.gc_od_eau_pol OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_mur_esc_lim; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_mur_esc_lim AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(30) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(el.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_lineaire el ON ((od.fid = el.element_lineaire_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('mur'::character varying)::text, ('escalier_important'::character varying)::text]));


ALTER TABLE movd.gc_od_mur_esc_lim OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_mur_esc_pol; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_mur_esc_pol AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(30) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(es.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_surfacique es ON ((od.fid = es.element_surfacique_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('mur'::character varying)::text, ('escalier_important'::character varying)::text]));


ALTER TABLE movd.gc_od_mur_esc_pol OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_route_lim; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_route_lim AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(50) AS genre,
    initcap(split_part((g.dispname)::text, '.'::text, '-1'::integer)) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(el.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_lineaire el ON ((od.fid = el.element_lineaire_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('autre.bord_de_chaussee_a_ventiler'::character varying)::text, ('autre.berme_ilot_a_ventiler'::character varying)::text, ('sentier'::character varying)::text, ('autre.trottoir_a_ventiler'::character varying)::text]))
UNION ALL
 SELECT objet_divers_lineaire.genre_id,
    (objet_divers_lineaire.genre)::character varying(100) AS genre,
    initcap(regexp_replace(split_part((objet_divers_lineaire.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)) AS genre_txt,
    (objet_divers_lineaire.numcom)::integer AS numcom,
    public.st_curvetoline(objet_divers_lineaire.geometrie) AS geom
   FROM specificite_lausanne.objet_divers_lineaire
  WHERE (objet_divers_lineaire.genre_id = ANY (ARRAY[67, 68, 69, 70, 71, 72, 84, 85, 86]));


ALTER TABLE movd.gc_od_route_lim OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_route_pol; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_route_pol AS
 SELECT (g.itfcode + 1) AS genre_id,
    (od.genre)::character varying(50) AS genre,
    (initcap(regexp_replace(split_part((od.genre)::text, '.'::text, '-1'::integer), '_'::text, ' '::text, 'g'::text)))::character varying(50) AS genre_txt,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(es.geometrie) AS geom
   FROM ((((movd.objet_divers od
     JOIN movd.genre_od g ON (((od.genre)::text = (g.ilicode)::text)))
     JOIN movd.element_surfacique es ON ((od.fid = es.element_surfacique_de)))
     JOIN movd.t_ili2db_basket b ON ((od.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((od.genre)::text = ANY (ARRAY[('autre.acces_sentier_a_ventiler'::character varying)::text, ('autre.bord_de_chaussee_a_ventiler'::character varying)::text, ('autre.berme_ilot_a_ventiler'::character varying)::text, ('sentier'::character varying)::text, ('autre.trottoir_a_ventiler'::character varying)::text, ('autre.acces_sentier_a_ventiler'::character varying)::text]));


ALTER TABLE movd.gc_od_route_pol OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24objets_divers_posnom_objet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24objets_divers_posnom_objet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnom_objet_de bigint,
    CONSTRAINT md01mvdmn95vvrs_psnm_bjet_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT md01mvdmn95vvrs_psnm_bjet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24objets_divers_posnom_objet OWNER TO gc_transfert_dbo;

--
-- Name: posnom_objet; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnom_objet (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnom_objet_de bigint,
    CONSTRAINT posnom_objet_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnom_objet_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnom_objet OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_text; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_text AS
 SELECT no.nom AS textstring,
    'OBJ_TXT'::character varying(15) AS type,
    mod(((450)::numeric - pno.ori), (360)::numeric) AS text_angle,
    (d.datasetname)::integer AS numcom,
    pno.pos AS geom
   FROM (((movd.md01mvdmn95v24objets_divers_nom_objet no
     JOIN movd.md01mvdmn95v24objets_divers_posnom_objet pno ON ((no.fid = pno.posnom_objet_de)))
     JOIN movd.t_ili2db_basket b ON ((no.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
UNION ALL
 SELECT no.nom AS textstring,
    'COUV_SOL'::character varying(15) AS type,
    mod(((450)::numeric - pno.ori), (360)::numeric) AS text_angle,
    (d.datasetname)::integer AS numcom,
    pno.pos AS geom
   FROM (((movd.nom_objet no
     JOIN movd.posnom_objet pno ON ((no.fid = pno.posnom_objet_de)))
     JOIN movd.t_ili2db_basket b ON ((no.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_od_text OWNER TO gc_transfert_dbo;

--
-- Name: objet_divers_texte; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.objet_divers_texte (
    ufid bigint NOT NULL,
    numcom character varying(3),
    type character varying(50),
    text_angle real,
    textstring character varying(100),
    geometrie public.geometry(Point,2056)
);


ALTER TABLE specificite_lausanne.objet_divers_texte OWNER TO gc_transfert_dbo;

--
-- Name: gc_od_text_projet; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_od_text_projet AS
 SELECT (objet_divers_texte.textstring)::character varying(30) AS textstring,
    (objet_divers_texte.type)::character varying(15) AS type,
    (objet_divers_texte.text_angle)::numeric AS text_angle,
    (objet_divers_texte.numcom)::integer AS numcom,
    objet_divers_texte.geometrie AS geom
   FROM specificite_lausanne.objet_divers_texte
  WHERE ((objet_divers_texte.type)::text = ANY ((ARRAY['PROJET'::character varying, 'CHANTIER'::character varying, 'DEMOLI'::character varying])::text[]));


ALTER TABLE movd.gc_od_text_projet OWNER TO gc_transfert_dbo;

--
-- Name: pfa1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfa1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    precplan numeric(4,1),
    fiabplan character varying(255),
    precalt numeric(4,1),
    fiabalt character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT pfa1_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT pfa1_precalt_check CHECK (((precalt >= 0.0) AND (precalt <= 700.0))),
    CONSTRAINT pfa1_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT pfa1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pfa1 OWNER TO gc_transfert_dbo;

--
-- Name: pfa2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfa2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    precplan numeric(4,1),
    fiabplan character varying(255),
    precalt numeric(4,1),
    fiabalt character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT pfa2_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT pfa2_precalt_check CHECK (((precalt >= 0.0) AND (precalt <= 700.0))),
    CONSTRAINT pfa2_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT pfa2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pfa2 OWNER TO gc_transfert_dbo;

--
-- Name: pfa3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfa3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    precplan numeric(4,1),
    fiabplan character varying(255),
    precalt numeric(4,1),
    fiabalt character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT pfa3_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT pfa3_precalt_check CHECK (((precalt >= 0.0) AND (precalt <= 700.0))),
    CONSTRAINT pfa3_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT pfa3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pfa3 OWNER TO gc_transfert_dbo;

--
-- Name: pfa; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.pfa (
    fid numeric(10,0) NOT NULL,
    numero_point character varying(64),
    type character varying(255),
    x numeric(10,3),
    y numeric(10,3),
    z numeric(7,3),
    precision_planimetrique real,
    precision_altimetrique real,
    fiabilite_planimetrique smallint,
    fiabilite_altimetrique smallint,
    situation1 character varying(100),
    situation2 character varying(100),
    id_goeland integer,
    numcom smallint,
    geometrie public.geometry(Point,2056)
);


ALTER TABLE specificite_lausanne.pfa OWNER TO gc_transfert_dbo;

--
-- Name: gc_pf_pfa; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pf_pfa AS
 SELECT pfa.numero_point AS no_pt,
    (regexp_replace((pfa.type)::text, 'Point Fixe Altimétrique'::text, 'PFA'::text))::character varying AS pftype,
    pfa.x,
    pfa.y,
    pfa.z,
    pfa.precision_planimetrique AS prec_pl,
    pfa.precision_altimetrique AS prec_al,
        CASE
            WHEN (pfa.fiabilite_planimetrique = 1) THEN 'fiable'::text
            WHEN (pfa.fiabilite_planimetrique = 0) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_pl,
        CASE
            WHEN (pfa.fiabilite_altimetrique = 1) THEN 'fiable'::text
            WHEN (pfa.fiabilite_altimetrique = 0) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_al,
    pfa.situation1 AS sit1,
    pfa.situation2 AS sit2,
    pfa.id_goeland AS idgo_thing,
    (pfa.numcom)::integer AS numcom,
    pfa.geometrie AS geom
   FROM specificite_lausanne.pfa
UNION ALL
 SELECT p.numero AS no_pt,
    'PFA1'::character varying AS pftype,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geomalt AS z,
    p.precplan AS prec_pl,
    p.precalt AS prec_al,
        CASE
            WHEN ((p.fiabplan)::text = 'oui'::text) THEN 'fiable'::text
            WHEN ((p.fiabplan)::text = 'non'::text) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_pl,
        CASE
            WHEN ((p.fiabalt)::text = 'oui'::text) THEN 'fiable'::text
            WHEN ((p.fiabalt)::text = 'non'::text) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_al,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::integer AS idgo_thing,
    (d.datasetname)::integer AS numcom,
    p.geometrie AS geom
   FROM ((movd.pfa1 p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text)
UNION ALL
 SELECT p.numero AS no_pt,
    'PFA2'::character varying AS pftype,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geomalt AS z,
    p.precplan AS prec_pl,
    p.precalt AS prec_al,
        CASE
            WHEN ((p.fiabplan)::text = 'oui'::text) THEN 'fiable'::text
            WHEN ((p.fiabplan)::text = 'non'::text) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_pl,
        CASE
            WHEN ((p.fiabalt)::text = 'oui'::text) THEN 'fiable'::text
            WHEN ((p.fiabalt)::text = 'non'::text) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_al,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::integer AS idgo_thing,
    (d.datasetname)::integer AS numcom,
    p.geometrie AS geom
   FROM ((movd.pfa2 p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text)
UNION ALL
 SELECT p.numero AS no_pt,
    'PFA3'::character varying AS pftype,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geomalt AS z,
    p.precplan AS prec_pl,
    p.precalt AS prec_al,
        CASE
            WHEN ((p.fiabplan)::text = 'oui'::text) THEN 'fiable'::text
            WHEN ((p.fiabplan)::text = 'non'::text) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_pl,
        CASE
            WHEN ((p.fiabalt)::text = 'oui'::text) THEN 'fiable'::text
            WHEN ((p.fiabalt)::text = 'non'::text) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_al,
    NULL::character varying(100) AS sit1,
    NULL::character varying(100) AS sit2,
    NULL::integer AS idgo_thing,
    (d.datasetname)::integer AS numcom,
    p.geometrie AS geom
   FROM ((movd.pfa3 p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text);


ALTER TABLE movd.gc_pf_pfa OWNER TO gc_transfert_dbo;

--
-- Name: pfp1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfp1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    precplan numeric(4,1),
    fiabplan character varying(255),
    precalt numeric(4,1),
    fiabalt character varying(255),
    accessibilite character varying(255),
    signe character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT pfp1_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT pfp1_precalt_check CHECK (((precalt >= 0.0) AND (precalt <= 700.0))),
    CONSTRAINT pfp1_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT pfp1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pfp1 OWNER TO gc_transfert_dbo;

--
-- Name: pfp2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfp2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    precplan numeric(4,1),
    fiabplan character varying(255),
    precalt numeric(4,1),
    fiabalt character varying(255),
    accessibilite character varying(255),
    signe character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT pfp2_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT pfp2_precalt_check CHECK (((precalt >= 0.0) AND (precalt <= 700.0))),
    CONSTRAINT pfp2_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT pfp2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pfp2 OWNER TO gc_transfert_dbo;

--
-- Name: pfp3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfp3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    precplan numeric(4,1),
    fiabplan character varying(255),
    precalt numeric(4,1),
    fiabalt character varying(255),
    signe character varying(255),
    fiche character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT pfp3_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT pfp3_precalt_check CHECK (((precalt >= 0.0) AND (precalt <= 700.0))),
    CONSTRAINT pfp3_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT pfp3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pfp3 OWNER TO gc_transfert_dbo;

--
-- Name: pfp; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.pfp (
    fid numeric(10,0) NOT NULL,
    numero_point character varying(64),
    type character varying(255),
    x numeric(10,3),
    y numeric(10,3),
    z numeric(7,3),
    precision_planimetrique real,
    precision_altimetrique real,
    fiabilite_planimetrique smallint,
    fiabilite_altimetrique smallint,
    accessible smallint,
    signe character varying(255),
    id_etat integer,
    situation1 character varying(100),
    situation2 character varying(100),
    visible_gnss character varying(50),
    id_goeland integer,
    numcom smallint,
    gis_ctrl1 real,
    gis_ctrl2 real,
    gis_ctrl3 real,
    gis_ctrl4 real,
    gis_ctrl5 real,
    gis_com1 character varying(100),
    gis_com2 character varying(100),
    gis_com3 character varying(100),
    gis_com4 character varying(100),
    gis_com5 character varying(100),
    alt_tech real,
    geometrie public.geometry(Point,2056)
);


ALTER TABLE specificite_lausanne.pfp OWNER TO gc_transfert_dbo;

--
-- Name: gc_pf_pfp; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pf_pfp AS
 SELECT pfp.numero_point AS no_pt,
    (pfp.type)::character varying(10) AS pftype,
    pfp.x,
    pfp.y,
    pfp.z,
    pfp.precision_planimetrique AS prec_pl,
    pfp.precision_altimetrique AS prec_al,
        CASE
            WHEN (pfp.fiabilite_planimetrique = 1) THEN 'fiable'::text
            WHEN (pfp.fiabilite_planimetrique = 0) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_pl,
        CASE
            WHEN (pfp.fiabilite_altimetrique = 1) THEN 'fiable'::text
            WHEN (pfp.fiabilite_altimetrique = 0) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_al,
        CASE
            WHEN (pfp.accessible = 1) THEN 'accessible'::text
            WHEN (pfp.accessible = 0) THEN 'inaccessible'::text
            ELSE NULL::text
        END AS accessible,
    (pfp.signe)::character varying(10) AS signe,
    pfp.situation1 AS sit1,
    pfp.situation2 AS sit2,
    pfp.visible_gnss AS vis_gnss,
    pfp.id_goeland AS idgo_thing,
    (pfp.numcom)::integer AS numcom,
    pfp.geometrie AS geom
   FROM specificite_lausanne.pfp
  WHERE (((pfp.type)::text <> ALL (ARRAY['PFP4 cadastre souterrain'::text, 'PFP4'::text, 'PFP technique'::text])) AND ((pfp.id_etat IS NULL) OR (pfp.id_etat <> ALL (ARRAY[20006, 20011]))) AND ((pfp.numero_point)::text <> 'new'::text))
UNION ALL
 SELECT (p.numero)::character varying(64) AS no_pt,
    'PFP1'::character varying(10) AS pftype,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geomalt AS z,
    p.precplan AS prec_pl,
    p.precalt AS prec_al,
    p.fiabplan AS fiab_pl,
    p.fiabalt AS fiab_al,
    NULL::text AS accessible,
    (p.signe)::character varying(10) AS signe,
    NULL::character varying AS sit1,
    NULL::character varying AS sit2,
    NULL::character varying AS vis_gnss,
    NULL::integer AS idgo_thing,
    (d.datasetname)::integer AS numcom,
    p.geometrie AS geom
   FROM ((movd.pfp1 p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text)
UNION ALL
 SELECT (p.numero)::character varying(64) AS no_pt,
    'PFP2'::character varying(10) AS pftype,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geomalt AS z,
    p.precplan AS prec_pl,
    p.precalt AS prec_al,
    p.fiabplan AS fiab_pl,
    p.fiabalt AS fiab_al,
    NULL::text AS accessible,
    p.signe,
    NULL::character varying AS sit1,
    NULL::character varying AS sit2,
    NULL::character varying AS vis_gnss,
    NULL::integer AS idgo_thing,
    (d.datasetname)::integer AS numcom,
    p.geometrie AS geom
   FROM ((movd.pfp2 p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text)
UNION ALL
 SELECT (p.numero)::character varying(64) AS no_pt,
    'PFP3'::character varying(10) AS pftype,
    public.st_x(p.geometrie) AS x,
    public.st_y(p.geometrie) AS y,
    p.geomalt AS z,
    p.precplan AS prec_pl,
    p.precalt AS prec_al,
    p.fiabplan AS fiab_pl,
    p.fiabalt AS fiab_al,
    NULL::text AS accessible,
    p.signe,
    NULL::character varying AS sit1,
    NULL::character varying AS sit2,
    NULL::character varying AS vis_gnss,
    NULL::integer AS idgo_thing,
    (d.datasetname)::integer AS numcom,
    p.geometrie AS geom
   FROM ((movd.pfp3 p
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
  WHERE ((d.datasetname)::text <> '132'::text);


ALTER TABLE movd.gc_pf_pfp OWNER TO gc_transfert_dbo;

--
-- Name: gc_pf_pfp4; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pf_pfp4 AS
 SELECT pfp.numero_point AS no_pt,
    (pfp.type)::character varying(20) AS pftype,
    pfp.x,
    pfp.y,
    pfp.z,
    pfp.precision_planimetrique AS prec_pl,
    pfp.precision_altimetrique AS prec_al,
        CASE
            WHEN (pfp.fiabilite_planimetrique = 1) THEN 'fiable'::text
            WHEN ((pfp.fiabilite_planimetrique = 0) OR (pfp.fiabilite_planimetrique IS NULL)) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_pl,
        CASE
            WHEN (pfp.fiabilite_altimetrique = 1) THEN 'fiable'::text
            WHEN ((pfp.fiabilite_altimetrique = 0) OR (pfp.fiabilite_altimetrique IS NULL)) THEN 'non-fiable'::text
            ELSE NULL::text
        END AS fiab_al,
        CASE
            WHEN (pfp.accessible = 1) THEN 'accessible'::text
            WHEN (pfp.accessible = 0) THEN 'inaccessible'::text
            ELSE NULL::text
        END AS accessible,
    pfp.signe,
    pfp.situation1 AS sit1,
    pfp.situation2 AS sit2,
    pfp.visible_gnss AS vis_gnss,
    pfp.id_goeland AS idgo_thing,
    (pfp.numcom)::integer AS numcom,
    pfp.geometrie AS geom
   FROM specificite_lausanne.pfp
  WHERE (((pfp.type)::text = ANY (ARRAY['PFP'::text, 'PFP4 cadastre souterrain'::text])) AND ((pfp.id_etat <> ALL (ARRAY[20002, 20006, 20010, 20011])) OR (pfp.id_etat IS NULL)));


ALTER TABLE movd.gc_pf_pfp4 OWNER TO gc_transfert_dbo;

--
-- Name: gc_pf_pfp_tech; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pf_pfp_tech AS
 SELECT (pfp.fid)::integer AS fid,
    pfp.numero_point AS no_pt,
    (
        CASE
            WHEN ((pfp.type)::text ~~ 'PFP %'::text) THEN 'PFP'::text
            WHEN ((pfp.type)::text ~~ 'PFP3%'::text) THEN 'PFP3'::text
            WHEN ((pfp.type)::text ~~ 'PFP4%'::text) THEN 'PFP4'::text
            ELSE NULL::text
        END)::character varying(10) AS pftype,
    pfp.x,
    pfp.y,
    pfp.z,
    pfp.precision_planimetrique AS prec_pl,
    pfp.precision_altimetrique AS prec_al,
    (
        CASE
            WHEN (pfp.fiabilite_planimetrique = 1) THEN 'fiable'::text
            WHEN (pfp.fiabilite_planimetrique = 0) THEN 'non-fiable'::text
            ELSE NULL::text
        END)::character varying(10) AS fiab_pl,
    (
        CASE
            WHEN (pfp.fiabilite_altimetrique = 1) THEN 'fiable'::text
            WHEN (pfp.fiabilite_altimetrique = 0) THEN 'non-fiable'::text
            ELSE NULL::text
        END)::character varying(10) AS fiab_al,
    (
        CASE
            WHEN (pfp.accessible = 1) THEN 'accessible'::text
            WHEN (pfp.accessible = 0) THEN 'inaccessible'::text
            ELSE NULL::text
        END)::character varying(12) AS "varchar",
    (pfp.signe)::character varying(10) AS signe,
    pfp.situation1,
    pfp.situation2,
    pfp.visible_gnss,
    pfp.id_goeland,
    (pfp.numcom)::integer AS numcom,
    pfp.geometrie AS geom,
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
    pfp.id_etat
   FROM specificite_lausanne.pfp
  WHERE ((pfp.id_etat <> ALL (ARRAY[20002, 20006, 20010, 20011])) OR (pfp.id_etat IS NULL));


ALTER TABLE movd.gc_pf_pfp_tech OWNER TO gc_transfert_dbo;

--
-- Name: pfp_label_reperage; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.pfp_label_reperage (
    fid integer NOT NULL,
    fid_pfp integer,
    text_value character varying(50),
    text_size real,
    text_angle real,
    statut character varying(50),
    geometrie public.geometry(Point,2056)
);


ALTER TABLE specificite_lausanne.pfp_label_reperage OWNER TO gc_transfert_dbo;

--
-- Name: gc_pfp_label_reperage; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pfp_label_reperage AS
 SELECT pfp_label_reperage.fid,
    pfp_label_reperage.fid_pfp,
    pfp_label_reperage.text_value,
    pfp_label_reperage.text_size,
    pfp_label_reperage.text_angle,
    pfp_label_reperage.statut,
    132 AS numcom,
    pfp_label_reperage.geometrie AS geom
   FROM specificite_lausanne.pfp_label_reperage;


ALTER TABLE movd.gc_pfp_label_reperage OWNER TO gc_transfert_dbo;

--
-- Name: pfp_line_reperage; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.pfp_line_reperage (
    fid integer NOT NULL,
    fid_pfp integer,
    statut character varying(50),
    geometrie public.geometry(Geometry,2056)
);


ALTER TABLE specificite_lausanne.pfp_line_reperage OWNER TO gc_transfert_dbo;

--
-- Name: gc_pfp_line_reperage; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pfp_line_reperage AS
 SELECT 132 AS numcom,
    pfp_line_reperage.fid,
    pfp_line_reperage.fid_pfp,
    pfp_line_reperage.statut,
    public.st_curvetoline(pfp_line_reperage.geometrie) AS geom
   FROM specificite_lausanne.pfp_line_reperage;


ALTER TABLE movd.gc_pfp_line_reperage OWNER TO gc_transfert_dbo;

--
-- Name: pfp_point_reperage; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.pfp_point_reperage (
    fid integer NOT NULL,
    fid_pfp integer,
    statut character varying(50),
    geometrie public.geometry(Point,2056)
);


ALTER TABLE specificite_lausanne.pfp_point_reperage OWNER TO gc_transfert_dbo;

--
-- Name: gc_pfp_point_reperage; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pfp_point_reperage AS
 SELECT pfp_point_reperage.fid,
    pfp_point_reperage.fid_pfp,
    pfp_point_reperage.statut,
    132 AS numcom,
    pfp_point_reperage.geometrie AS geom
   FROM specificite_lausanne.pfp_point_reperage;


ALTER TABLE movd.gc_pfp_point_reperage OWNER TO gc_transfert_dbo;

--
-- Name: geometrie_plan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.geometrie_plan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    geometrie_plan_de bigint,
    CONSTRAINT geometrie_plan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.geometrie_plan OWNER TO gc_transfert_dbo;

--
-- Name: gc_pl_plan_lim; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_pl_plan_lim AS
 SELECT NULL::text AS fidc,
    p.identdn AS numbernd,
    p.codeplan AS plan_code,
    p.numero AS plan_number,
    (d.datasetname)::integer AS numcom,
    public.st_curvetoline(g.geometrie) AS geom
   FROM (((movd.aplan p
     JOIN movd.geometrie_plan g ON ((p.fid = g.geometrie_plan_de)))
     JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
     JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)));


ALTER TABLE movd.gc_pl_plan_lim OWNER TO gc_transfert_dbo;

--
-- Name: localisation_place; Type: TABLE; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE TABLE specificite_lausanne.localisation_place (
    fid integer,
    location_number character varying(25),
    ufid integer,
    code_rue smallint,
    id_rue integer,
    geometrie public.geometry(Geometry,2056)
);


ALTER TABLE specificite_lausanne.localisation_place OWNER TO gc_transfert_dbo;

--
-- Name: gc_place_rue; Type: VIEW; Schema: movd; Owner: gc_transfert_dbo
--

CREATE VIEW movd.gc_place_rue AS
 SELECT g.idthing,
    g.longname,
    g.shortname,
    g.estrid,
    g.coderue,
    ts.description AS typestreet,
    g.datedecisionmuni AS datemuni,
    132 AS numcom,
    concat('#', lpad(to_hex((round((random() * ((2)::double precision ^ (24)::double precision))))::integer), 6)) AS color_html,
    COALESCE(public.st_difference(p.geometrie, b.geom), p.geometrie) AS geom
   FROM (((goeland.thi_street g
     JOIN specificite_lausanne.localisation_place p ON ((g.coderue = p.code_rue)))
     JOIN goeland.type_thi_street ts ON ((g.idtypestreet = ts.idtypestreet)))
     CROSS JOIN LATERAL ( SELECT public.st_union(s.geometrie) AS geom
           FROM movd.surfacecs s
          WHERE (((s.genre)::text = 'batiment'::text) AND public.st_intersects(s.geometrie, p.geometrie))) b);


ALTER TABLE movd.gc_place_rue OWNER TO gc_transfert_dbo;

--
-- Name: genre_croix; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_croix (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_croix OWNER TO gc_transfert_dbo;

--
-- Name: genre_description; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_description (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_description OWNER TO gc_transfert_dbo;

--
-- Name: genre_format; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_format (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_format OWNER TO gc_transfert_dbo;

--
-- Name: genre_immeuble; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_immeuble (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_immeuble OWNER TO gc_transfert_dbo;

--
-- Name: genre_symbole; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.genre_symbole (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.genre_symbole OWNER TO gc_transfert_dbo;

--
-- Name: geometriedn; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.geometriedn (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    geometriedn_de bigint,
    CONSTRAINT geometriedn_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.geometriedn OWNER TO gc_transfert_dbo;

--
-- Name: glissement; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.glissement (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    nom character varying(30),
    geometrie public.geometry(CurvePolygon,2056),
    en_vigueur date,
    ufid bigint,
    CONSTRAINT glissement_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.glissement OWNER TO gc_transfert_dbo;

--
-- Name: grandeurecriture; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.grandeurecriture (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.grandeurecriture OWNER TO gc_transfert_dbo;

--
-- Name: groupement_de_localite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.groupement_de_localite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    vide character varying(1),
    ufid bigint,
    CONSTRAINT groupement_de_localite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.groupement_de_localite OWNER TO gc_transfert_dbo;

--
-- Name: halignment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.halignment (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.halignment OWNER TO gc_transfert_dbo;

--
-- Name: immeuble_integralite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.immeuble_integralite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.immeuble_integralite OWNER TO gc_transfert_dbo;

--
-- Name: immeuble_validite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.immeuble_validite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.immeuble_validite OWNER TO gc_transfert_dbo;

--
-- Name: immeubleproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.immeubleproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    numero character varying(12),
    egris_egrid character varying(14),
    validite character varying(255),
    integralite character varying(255),
    genre character varying(255),
    superficie_totale integer,
    ufid bigint,
    origine bigint,
    CONSTRAINT immeubleproj_superficie_totale_check CHECK (((superficie_totale >= 1) AND (superficie_totale <= 999999999))),
    CONSTRAINT immeubleproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.immeubleproj OWNER TO gc_transfert_dbo;

--
-- Name: immeubleproj_integralite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.immeubleproj_integralite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.immeubleproj_integralite OWNER TO gc_transfert_dbo;

--
-- Name: immeubleproj_validite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.immeubleproj_validite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.immeubleproj_validite OWNER TO gc_transfert_dbo;

--
-- Name: indication_coordonnees; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.indication_coordonnees (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    adescription character varying(12),
    ufid bigint,
    indication_coordonnees_de bigint,
    CONSTRAINT indication_coordonnees_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.indication_coordonnees OWNER TO gc_transfert_dbo;

--
-- Name: lieu_denomme; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lieu_denomme (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    lieu_denomme_de bigint,
    CONSTRAINT lieu_denomme_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.lieu_denomme OWNER TO gc_transfert_dbo;

--
-- Name: lieudit; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lieudit (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(40),
    ufid bigint,
    origine bigint,
    CONSTRAINT lieudit_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.lieudit OWNER TO gc_transfert_dbo;

--
-- Name: ligne_coordonnees; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.ligne_coordonnees (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    ufid bigint,
    ligne_coordonnees_de bigint,
    CONSTRAINT ligne_coordonnees_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.ligne_coordonnees OWNER TO gc_transfert_dbo;

--
-- Name: limite_communeproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.limite_communeproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    ufid bigint,
    limite_communeproj_de bigint,
    origine bigint,
    CONSTRAINT limite_communeproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.limite_communeproj OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib10_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib10_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib10_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib3_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib3_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib3_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib4_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib4_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib4_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib5_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib5_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib5_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib6_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib6_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib6_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib7_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib7_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib7_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib8_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib8_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib8_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: lineattrib9_genre_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.lineattrib9_genre_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.lineattrib9_genre_ligne OWNER TO gc_transfert_dbo;

--
-- Name: localisation_attributs_provisoires; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localisation_attributs_provisoires (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.localisation_attributs_provisoires OWNER TO gc_transfert_dbo;

--
-- Name: localisation_en_cours_modification; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localisation_en_cours_modification (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.localisation_en_cours_modification OWNER TO gc_transfert_dbo;

--
-- Name: localisation_est_designation_officielle; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localisation_est_designation_officielle (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.localisation_est_designation_officielle OWNER TO gc_transfert_dbo;

--
-- Name: localisation_genre; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localisation_genre (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.localisation_genre OWNER TO gc_transfert_dbo;

--
-- Name: localisation_principe_numerotation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localisation_principe_numerotation (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.localisation_principe_numerotation OWNER TO gc_transfert_dbo;

--
-- Name: localite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    validite character varying(255),
    en_cours_modification character varying(255),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    localite_de bigint,
    origine bigint,
    CONSTRAINT localite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.localite OWNER TO gc_transfert_dbo;

--
-- Name: localite_en_cours_modification; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.localite_en_cours_modification (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.localite_en_cours_modification OWNER TO gc_transfert_dbo;

--
-- Name: materiel; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.materiel (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.materiel OWNER TO gc_transfert_dbo;

--
-- Name: matiere; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.matiere (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.matiere OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24bords_de_plan_element_lineaire; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24bords_de_plan_element_lineaire (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    genre character varying(255),
    ufid bigint,
    element_lineaire_de bigint,
    CONSTRAINT md01mvdmn95vln_lmnt_lnire_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24bords_de_plan_element_lineaire OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24conduites_element_lineaire; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24conduites_element_lineaire (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    genre_ligne character varying(255),
    ufid bigint,
    element_lineaire_de bigint,
    CONSTRAINT md01mvdmn95vts_lmnt_lnire_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24conduites_element_lineaire OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24conduites_element_ponctuel; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24conduites_element_ponctuel (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(Point,2056),
    geomalt numeric(7,3),
    ori numeric(4,1),
    ufid bigint,
    element_ponctuel_de bigint,
    CONSTRAINT md01mvdmn95v_lmnt_pnctuel_geomalt_check CHECK (((geomalt >= '-200.0'::numeric) AND (geomalt <= 5000.0))),
    CONSTRAINT md01mvdmn95v_lmnt_pnctuel_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT md01mvdmn95v_lmnt_pnctuel_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24conduites_element_ponctuel OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24conduites_element_surfacique; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24conduites_element_surfacique (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    element_surfacique_de bigint,
    CONSTRAINT md01mvdmn95v_lmnt_srfcque_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24conduites_element_surfacique OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24conduites_point_particulier; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24conduites_point_particulier (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identification character varying(12),
    geometrie public.geometry(Point,2056),
    precplan numeric(4,1),
    fiabplan character varying(255),
    defini_exactement character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT md01mvdmn95v_pnt_prtclier_precplan_check1 CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT md01mvdmn95v_pnt_prtclier_ufid_check1 CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24conduites_point_particulier OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24conduites_pospoint_particulier; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24conduites_pospoint_particulier (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospoint_particulier_de bigint,
    CONSTRAINT md01mvdmn95vspnt_prtclier_ori_check1 CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT md01mvdmn95vspnt_prtclier_ufid_check1 CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24conduites_pospoint_particulier OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24objets_divers_point_particulier; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24objets_divers_point_particulier (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    geometrie public.geometry(Point,2056),
    precplan numeric(4,1),
    fiabplan character varying(255),
    defini_exactement character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT md01mvdmn95v_pnt_prtclier_precplan_check CHECK (((precplan >= 0.0) AND (precplan <= 700.0))),
    CONSTRAINT md01mvdmn95v_pnt_prtclier_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24objets_divers_point_particulier OWNER TO gc_transfert_dbo;

--
-- Name: md01mvdmn95v24objets_divers_pospoint_particulier; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvdmn95v24objets_divers_pospoint_particulier (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospoint_particulier_de bigint,
    CONSTRAINT md01mvdmn95vspnt_prtclier_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT md01mvdmn95vspnt_prtclier_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.md01mvdmn95v24objets_divers_pospoint_particulier OWNER TO gc_transfert_dbo;

--
-- Name: md01mvn95v24conduites_point_particulier_defini_exactement; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvn95v24conduites_point_particulier_defini_exactement (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.md01mvn95v24conduites_point_particulier_defini_exactement OWNER TO gc_transfert_dbo;

--
-- Name: md01mvn95v24couvertur_d_sol_point_particulier_defini_xctment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvn95v24couvertur_d_sol_point_particulier_defini_xctment (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.md01mvn95v24couvertur_d_sol_point_particulier_defini_xctment OWNER TO gc_transfert_dbo;

--
-- Name: md01mvn95v24objets_divers_point_particulier_defini_exactment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.md01mvn95v24objets_divers_point_particulier_defini_exactment (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.md01mvn95v24objets_divers_point_particulier_defini_exactment OWNER TO gc_transfert_dbo;

--
-- Name: mineproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mineproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    partienumeroimmeuble character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    superficie integer,
    ufid bigint,
    mineproj_de bigint,
    CONSTRAINT mineproj_superficie_check CHECK (((superficie >= 1) AND (superficie <= 999999999))),
    CONSTRAINT mineproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mineproj OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_joural; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_joural (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_joural_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_joural OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourbat; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourbat (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    ufid bigint,
    CONSTRAINT mise_a_jourbat_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourbat OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourbf; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourbf (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    enregistrement_rf date,
    date1 date,
    date2 date,
    ufid bigint,
    CONSTRAINT mise_a_jourbf_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourbf OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourco; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourco (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourco_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourco OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourcom; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourcom (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourcom_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourcom OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourcs; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourcs (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourcs_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourcs OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourloc; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourloc (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    ufid bigint,
    CONSTRAINT mise_a_jourloc_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourloc OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_journo; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_journo (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_journo_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_journo OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_journpa6; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_journpa6 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    ufid bigint,
    CONSTRAINT mise_a_journpa6_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_journpa6 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourod; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourod (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourod_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourod OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourpfa1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourpfa1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourpfa1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourpfa1 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourpfa2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourpfa2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourpfa2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourpfa2 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourpfa3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourpfa3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourpfa3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourpfa3 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourpfp1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourpfp1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourpfp1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourpfp1 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourpfp2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourpfp2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourpfp2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourpfp2 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourpfp3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourpfp3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourpfp3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourpfp3 OWNER TO gc_transfert_dbo;

--
-- Name: mise_a_jourrp; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.mise_a_jourrp (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    adescription character varying(30),
    perimetre public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_vigueur date,
    date1 date,
    ufid bigint,
    CONSTRAINT mise_a_jourrp_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.mise_a_jourrp OWNER TO gc_transfert_dbo;

--
-- Name: niveau_tolerance; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.niveau_tolerance (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    identdn character varying(12),
    identification character varying(12),
    geometrie public.geometry(CurvePolygon,2056),
    en_vigueur date,
    genre character varying(255),
    ufid bigint,
    CONSTRAINT niveau_tolerance_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.niveau_tolerance OWNER TO gc_transfert_dbo;

--
-- Name: niveau_tolerance_genre; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.niveau_tolerance_genre (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.niveau_tolerance_genre OWNER TO gc_transfert_dbo;

--
-- Name: nom_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nom_batiment (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    texte character varying(40),
    texte_abrege character varying(24),
    texte_index character varying(16),
    langue character varying(255),
    ufid bigint,
    nom_batiment_de bigint,
    CONSTRAINT nom_batiment_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nom_batiment OWNER TO gc_transfert_dbo;

--
-- Name: nom_de_lieu; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nom_de_lieu (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(40),
    geometrie public.geometry(CurvePolygon,2056),
    atype character varying(30),
    ufid bigint,
    origine bigint,
    CONSTRAINT nom_de_lieu_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nom_de_lieu OWNER TO gc_transfert_dbo;

--
-- Name: nom_local; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nom_local (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(40),
    geometrie public.geometry(CurvePolygon,2056),
    ufid bigint,
    origine bigint,
    CONSTRAINT nom_local_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nom_local OWNER TO gc_transfert_dbo;

--
-- Name: nom_localite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nom_localite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    texte character varying(40),
    texte_abrege character varying(18),
    texte_index character varying(16),
    langue character varying(255),
    ufid bigint,
    nom_localite_de bigint,
    CONSTRAINT nom_localite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nom_localite OWNER TO gc_transfert_dbo;

--
-- Name: nomobjetproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.nomobjetproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    nom character varying(30),
    ufid bigint,
    nomobjetproj_de bigint,
    CONSTRAINT nomobjetproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.nomobjetproj OWNER TO gc_transfert_dbo;

--
-- Name: npa6; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.npa6 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    validite character varying(255),
    en_cours_modification character varying(255),
    npa integer,
    chiffres_supplementaires integer,
    ufid bigint,
    npa6_de bigint,
    origine bigint,
    CONSTRAINT npa6_chiffres_supplementaires_check CHECK (((chiffres_supplementaires >= 0) AND (chiffres_supplementaires <= 99))),
    CONSTRAINT npa6_npa_check CHECK (((npa >= 1000) AND (npa <= 9999))),
    CONSTRAINT npa6_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.npa6 OWNER TO gc_transfert_dbo;

--
-- Name: npa6_en_cours_modification; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.npa6_en_cours_modification (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.npa6_en_cours_modification OWNER TO gc_transfert_dbo;

--
-- Name: numerobatimentproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.numerobatimentproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    numero character varying(12),
    regbl_egid integer,
    designation character varying(255),
    ufid bigint,
    numerobatimentproj_de bigint,
    CONSTRAINT numerobatimentproj_regbl_egid_check CHECK (((regbl_egid >= 1) AND (regbl_egid <= 999999999))),
    CONSTRAINT numerobatimentproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.numerobatimentproj OWNER TO gc_transfert_dbo;

--
-- Name: partie_limite_canton; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.partie_limite_canton (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    validite character varying(255),
    ufid bigint,
    CONSTRAINT partie_limite_canton_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.partie_limite_canton OWNER TO gc_transfert_dbo;

--
-- Name: partie_limite_canton_validite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.partie_limite_canton_validite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.partie_limite_canton_validite OWNER TO gc_transfert_dbo;

--
-- Name: partie_limite_district; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.partie_limite_district (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    validite character varying(255),
    ufid bigint,
    CONSTRAINT partie_limite_district_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.partie_limite_district OWNER TO gc_transfert_dbo;

--
-- Name: partie_limite_district_validite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.partie_limite_district_validite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.partie_limite_district_validite OWNER TO gc_transfert_dbo;

--
-- Name: partie_limite_nationale; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.partie_limite_nationale (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CompoundCurve,2056),
    validite character varying(255),
    ufid bigint,
    CONSTRAINT partie_limite_nationale_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.partie_limite_nationale OWNER TO gc_transfert_dbo;

--
-- Name: partie_limite_nationale_validite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.partie_limite_nationale_validite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.partie_limite_nationale_validite OWNER TO gc_transfert_dbo;

--
-- Name: pfp1_accessibilite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfp1_accessibilite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.pfp1_accessibilite OWNER TO gc_transfert_dbo;

--
-- Name: pfp2_accessibilite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfp2_accessibilite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.pfp2_accessibilite OWNER TO gc_transfert_dbo;

--
-- Name: pfp3_fiche; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pfp3_fiche (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.pfp3_fiche OWNER TO gc_transfert_dbo;

--
-- Name: point_cote; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_cote (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(PointZ,2056),
    qualite character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT point_cote_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.point_cote OWNER TO gc_transfert_dbo;

--
-- Name: point_limite_anc_borne_speciale; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_limite_anc_borne_speciale (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.point_limite_anc_borne_speciale OWNER TO gc_transfert_dbo;

--
-- Name: point_limite_defini_exactement; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_limite_defini_exactement (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.point_limite_defini_exactement OWNER TO gc_transfert_dbo;

--
-- Name: point_limite_ter_borne_territoriale; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_limite_ter_borne_territoriale (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.point_limite_ter_borne_territoriale OWNER TO gc_transfert_dbo;

--
-- Name: point_limite_ter_defini_exactement; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_limite_ter_defini_exactement (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.point_limite_ter_defini_exactement OWNER TO gc_transfert_dbo;

--
-- Name: point_particulier_defini_exactement; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.point_particulier_defini_exactement (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.point_particulier_defini_exactement OWNER TO gc_transfert_dbo;

--
-- Name: posdescription_plan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posdescription_plan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posdescription_plan_de bigint,
    CONSTRAINT posdescription_plan_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posdescription_plan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posdescription_plan OWNER TO gc_transfert_dbo;

--
-- Name: posdomaine_numerotation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posdomaine_numerotation (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posdomaine_numerotation_de bigint,
    CONSTRAINT posdomaine_numerotation_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posdomaine_numerotation_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posdomaine_numerotation OWNER TO gc_transfert_dbo;

--
-- Name: poselement_conduite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.poselement_conduite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    poselement_conduite_de bigint,
    CONSTRAINT poselement_conduite_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT poselement_conduite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.poselement_conduite OWNER TO gc_transfert_dbo;

--
-- Name: posglissement; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posglissement (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posglissement_de bigint,
    CONSTRAINT posglissement_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posglissement_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posglissement OWNER TO gc_transfert_dbo;

--
-- Name: posimmeubleproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posimmeubleproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ligne_auxiliaire public.geometry(CompoundCurve,2056),
    ufid bigint,
    posimmeubleproj_de bigint,
    CONSTRAINT posimmeubleproj_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posimmeubleproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posimmeubleproj OWNER TO gc_transfert_dbo;

--
-- Name: posindication_coord; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posindication_coord (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posindication_coord_de bigint,
    CONSTRAINT posindication_coord_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posindication_coord_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posindication_coord OWNER TO gc_transfert_dbo;

--
-- Name: poslieudit; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.poslieudit (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    astyle character varying(255),
    ufid bigint,
    poslieudit_de bigint,
    CONSTRAINT poslieudit_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT poslieudit_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.poslieudit OWNER TO gc_transfert_dbo;

--
-- Name: posniveau_tolerance; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posniveau_tolerance (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posniveau_tolerance_de bigint,
    CONSTRAINT posniveau_tolerance_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posniveau_tolerance_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posniveau_tolerance OWNER TO gc_transfert_dbo;

--
-- Name: posnom_batiment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnom_batiment (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ligne_auxiliaire public.geometry(CompoundCurve,2056),
    ufid bigint,
    posnom_batiment_de bigint,
    CONSTRAINT posnom_batiment_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnom_batiment_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnom_batiment OWNER TO gc_transfert_dbo;

--
-- Name: posnom_de_lieu; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnom_de_lieu (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    astyle character varying(255),
    ufid bigint,
    posnom_de_lieu_de bigint,
    CONSTRAINT posnom_de_lieu_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnom_de_lieu_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnom_de_lieu OWNER TO gc_transfert_dbo;

--
-- Name: posnom_local; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnom_local (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    astyle character varying(255),
    ufid bigint,
    posnom_local_de bigint,
    CONSTRAINT posnom_local_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnom_local_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnom_local OWNER TO gc_transfert_dbo;

--
-- Name: posnom_localite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnom_localite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnom_localite_de bigint,
    CONSTRAINT posnom_localite_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnom_localite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnom_localite OWNER TO gc_transfert_dbo;

--
-- Name: posnomobjetproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnomobjetproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnomobjetproj_de bigint,
    CONSTRAINT posnomobjetproj_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnomobjetproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnomobjetproj OWNER TO gc_transfert_dbo;

--
-- Name: posnumerobatimentproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posnumerobatimentproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posnumerobatimentproj_de bigint,
    CONSTRAINT posnumerobatimentproj_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posnumerobatimentproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posnumerobatimentproj OWNER TO gc_transfert_dbo;

--
-- Name: pospfa1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospfa1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospfa1_de bigint,
    CONSTRAINT pospfa1_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospfa1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospfa1 OWNER TO gc_transfert_dbo;

--
-- Name: pospfa2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospfa2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospfa2_de bigint,
    CONSTRAINT pospfa2_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospfa2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospfa2 OWNER TO gc_transfert_dbo;

--
-- Name: pospfa3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospfa3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospfa3_de bigint,
    CONSTRAINT pospfa3_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospfa3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospfa3 OWNER TO gc_transfert_dbo;

--
-- Name: pospfp1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospfp1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospfp1_de bigint,
    CONSTRAINT pospfp1_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospfp1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospfp1 OWNER TO gc_transfert_dbo;

--
-- Name: pospfp2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospfp2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospfp2_de bigint,
    CONSTRAINT pospfp2_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospfp2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospfp2 OWNER TO gc_transfert_dbo;

--
-- Name: pospfp3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospfp3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospfp3_de bigint,
    CONSTRAINT pospfp3_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospfp3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospfp3 OWNER TO gc_transfert_dbo;

--
-- Name: posplan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.posplan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    grandeur character varying(255),
    ufid bigint,
    posplan_de bigint,
    CONSTRAINT posplan_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT posplan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.posplan OWNER TO gc_transfert_dbo;

--
-- Name: pospoint_cote; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospoint_cote (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospoint_cote_de bigint,
    CONSTRAINT pospoint_cote_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospoint_cote_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospoint_cote OWNER TO gc_transfert_dbo;

--
-- Name: pospoint_limite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospoint_limite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospoint_limite_de bigint,
    CONSTRAINT pospoint_limite_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospoint_limite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospoint_limite OWNER TO gc_transfert_dbo;

--
-- Name: pospoint_limite_ter; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospoint_limite_ter (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospoint_limite_ter_de bigint,
    CONSTRAINT pospoint_limite_ter_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospoint_limite_ter_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospoint_limite_ter OWNER TO gc_transfert_dbo;

--
-- Name: pospoint_particulier; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.pospoint_particulier (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    pospoint_particulier_de bigint,
    CONSTRAINT pospoint_particulier_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT pospoint_particulier_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.pospoint_particulier OWNER TO gc_transfert_dbo;

--
-- Name: possignal; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.possignal (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    hali character varying(255),
    vali character varying(255),
    ufid bigint,
    possignal_de bigint,
    CONSTRAINT possignal_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT possignal_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.possignal OWNER TO gc_transfert_dbo;

--
-- Name: signal_genre_point; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.signal_genre_point (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.signal_genre_point OWNER TO gc_transfert_dbo;

--
-- Name: standardqualite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.standardqualite (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.standardqualite OWNER TO gc_transfert_dbo;

--
-- Name: statut; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.statut (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.statut OWNER TO gc_transfert_dbo;

--
-- Name: statut_mise_a_jour_ab; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.statut_mise_a_jour_ab (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.statut_mise_a_jour_ab OWNER TO gc_transfert_dbo;

--
-- Name: styleecriture; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.styleecriture (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.styleecriture OWNER TO gc_transfert_dbo;

--
-- Name: surface_representation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.surface_representation (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    choix_representation character varying(255),
    ufid bigint,
    surface_representation_de bigint,
    CONSTRAINT surface_representation_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.surface_representation OWNER TO gc_transfert_dbo;

--
-- Name: surface_representation_choix_representation; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.surface_representation_choix_representation (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.surface_representation_choix_representation OWNER TO gc_transfert_dbo;

--
-- Name: surface_vide; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.surface_vide (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    geometrie public.geometry(CurvePolygon,2056),
    qualite character varying(255),
    genre character varying(255),
    ufid bigint,
    origine bigint,
    CONSTRAINT surface_vide_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.surface_vide OWNER TO gc_transfert_dbo;

--
-- Name: surface_vide_genre; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.surface_vide_genre (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.surface_vide_genre OWNER TO gc_transfert_dbo;

--
-- Name: symbolebord_de_plan; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolebord_de_plan (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    genre character varying(255),
    ufid bigint,
    symbolebord_de_plan_de bigint,
    CONSTRAINT symbolebord_de_plan_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolebord_de_plan_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolebord_de_plan OWNER TO gc_transfert_dbo;

--
-- Name: symboleelement_lineaire; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symboleelement_lineaire (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    ufid bigint,
    symboleelement_lineaire_de bigint,
    CONSTRAINT symboleelement_lineaire_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symboleelement_lineaire_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symboleelement_lineaire OWNER TO gc_transfert_dbo;

--
-- Name: symboleelement_surf; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symboleelement_surf (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    ufid bigint,
    symboleelement_surf_de bigint,
    CONSTRAINT symboleelement_surf_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symboleelement_surf_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symboleelement_surf OWNER TO gc_transfert_dbo;

--
-- Name: symbolepfp1; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolepfp1 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    ori numeric(4,1),
    ufid bigint,
    symbolepfp1_de bigint,
    CONSTRAINT symbolepfp1_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolepfp1_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolepfp1 OWNER TO gc_transfert_dbo;

--
-- Name: symbolepfp2; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolepfp2 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    ori numeric(4,1),
    ufid bigint,
    symbolepfp2_de bigint,
    CONSTRAINT symbolepfp2_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolepfp2_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolepfp2 OWNER TO gc_transfert_dbo;

--
-- Name: symbolepfp3; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolepfp3 (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    ori numeric(4,1),
    ufid bigint,
    symbolepfp3_de bigint,
    CONSTRAINT symbolepfp3_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolepfp3_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolepfp3 OWNER TO gc_transfert_dbo;

--
-- Name: symbolepoint_limite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolepoint_limite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    ori numeric(4,1),
    ufid bigint,
    symbolepoint_limite_de bigint,
    CONSTRAINT symbolepoint_limite_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolepoint_limite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolepoint_limite OWNER TO gc_transfert_dbo;

--
-- Name: symbolepoint_limite_ter; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolepoint_limite_ter (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    ori numeric(4,1),
    ufid bigint,
    symbolepoint_limite_ter_de bigint,
    CONSTRAINT symbolepoint_limite_ter_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolepoint_limite_ter_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolepoint_limite_ter OWNER TO gc_transfert_dbo;

--
-- Name: symbolesurfacecs; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolesurfacecs (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    ufid bigint,
    symbolesurfacecs_de bigint,
    CONSTRAINT symbolesurfacecs_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolesurfacecs_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolesurfacecs OWNER TO gc_transfert_dbo;

--
-- Name: symbolesurfacecsproj; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.symbolesurfacecsproj (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    pos public.geometry(Point,2056),
    ori numeric(4,1),
    ufid bigint,
    symbolesurfcsproj_de bigint,
    CONSTRAINT symbolesurfacecsproj_ori_check CHECK (((ori >= 0.0) AND (ori <= 399.9))),
    CONSTRAINT symbolesurfacecsproj_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.symbolesurfacecsproj OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_attrname; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_attrname (
    iliname character varying(1024) NOT NULL,
    sqlname character varying(1024) NOT NULL,
    colowner character varying(1024) NOT NULL,
    target character varying(1024)
);


ALTER TABLE movd.t_ili2db_attrname OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_classname; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_classname (
    iliname character varying(1024) NOT NULL,
    sqlname character varying(1024) NOT NULL
);


ALTER TABLE movd.t_ili2db_classname OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_column_prop; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_column_prop (
    tablename character varying(255) NOT NULL,
    subtype character varying(255),
    columnname character varying(255) NOT NULL,
    tag character varying(1024) NOT NULL,
    setting character varying(8000) NOT NULL
);


ALTER TABLE movd.t_ili2db_column_prop OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_inheritance; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_inheritance (
    thisclass character varying(1024) NOT NULL,
    baseclass character varying(1024)
);


ALTER TABLE movd.t_ili2db_inheritance OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_meta_attrs; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_meta_attrs (
    ilielement character varying(255) NOT NULL,
    attr_name character varying(1024) NOT NULL,
    attr_value character varying(8000) NOT NULL
);


ALTER TABLE movd.t_ili2db_meta_attrs OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_model; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_model (
    filename character varying(250) NOT NULL,
    iliversion character varying(3) NOT NULL,
    modelname text NOT NULL,
    content text NOT NULL,
    importdate timestamp without time zone NOT NULL
);


ALTER TABLE movd.t_ili2db_model OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_settings; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_settings (
    tag character varying(60) NOT NULL,
    setting character varying(8000)
);


ALTER TABLE movd.t_ili2db_settings OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_table_prop; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_table_prop (
    tablename character varying(255) NOT NULL,
    tag character varying(1024) NOT NULL,
    setting character varying(8000) NOT NULL
);


ALTER TABLE movd.t_ili2db_table_prop OWNER TO gc_transfert_dbo;

--
-- Name: t_ili2db_trafo; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.t_ili2db_trafo (
    iliname character varying(1024) NOT NULL,
    tag character varying(1024) NOT NULL,
    setting character varying(1024) NOT NULL
);


ALTER TABLE movd.t_ili2db_trafo OWNER TO gc_transfert_dbo;

--
-- Name: texte_groupement_de_localite; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.texte_groupement_de_localite (
    fid bigint DEFAULT nextval('movd.t_ili2db_seq'::regclass) NOT NULL,
    t_basket bigint NOT NULL,
    t_ili_tid character varying(200),
    texte character varying(200),
    langue character varying(255),
    ufid bigint,
    texte_groupement_de_localite_de bigint,
    CONSTRAINT texte_groupement_d_lclite_ufid_check CHECK (((ufid >= 0) AND (ufid <= '9999999999'::bigint)))
);


ALTER TABLE movd.texte_groupement_de_localite OWNER TO gc_transfert_dbo;

--
-- Name: troncon_rue_est_axe; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.troncon_rue_est_axe (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.troncon_rue_est_axe OWNER TO gc_transfert_dbo;

--
-- Name: type_ligne; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.type_ligne (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.type_ligne OWNER TO gc_transfert_dbo;

--
-- Name: typelangue; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.typelangue (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.typelangue OWNER TO gc_transfert_dbo;

--
-- Name: valignment; Type: TABLE; Schema: movd; Owner: gc_transfert_dbo
--

CREATE TABLE movd.valignment (
    itfcode integer NOT NULL,
    ilicode character varying(1024) NOT NULL,
    seq integer,
    inactive boolean NOT NULL,
    dispname character varying(250) NOT NULL,
    description text
);


ALTER TABLE movd.valignment OWNER TO gc_transfert_dbo;

--
-- Name: control_pfp; Type: VIEW; Schema: specificite_lausanne; Owner: postgres
--

CREATE VIEW specificite_lausanne.control_pfp AS
 SELECT (concat(pl.fid, pc.fid))::bigint AS uid,
    pl.fid AS fid_l,
    pl.numero_point,
    pl.id_etat,
    pc.fid AS fid_c,
    pc.identdn,
    pc.numero,
    pl.numcom AS numcom_l,
    pc.numcom AS numcom_c,
        CASE
            WHEN ((pl.id_etat <> ALL (ARRAY[20006, 20011])) AND (pc.fid IS NULL)) THEN 'dans_lausanne_pas_canton'::text
            WHEN ((pl.id_etat IS NULL) AND (pc.fid IS NULL)) THEN 'dans_lausanne_pas_canton_etat_null'::text
            WHEN ((pl.id_etat = ANY (ARRAY[20006, 20011])) AND (pc.fid IS NULL)) THEN 'ok_donnees_archivees'::text
            WHEN ((pl.id_etat = ANY (ARRAY[20006, 20011])) AND (pc.fid IS NOT NULL)) THEN 'a_supprimer_au_canton'::text
            WHEN (pl.fid IS NULL) THEN 'dans_canton_pas_lausanne'::text
            ELSE 'ok'::text
        END AS comparison,
    public.st_collect(pl.geometrie, pc.geometrie) AS geom
   FROM (specificite_lausanne.pfp pl
     FULL JOIN ( SELECT p.fid,
            (d.datasetname)::integer AS numcom,
            p.identdn,
            p.numero,
            p.geometrie
           FROM ((movd.pfp3 p
             JOIN movd.t_ili2db_basket b ON ((p.t_basket = b.fid)))
             JOIN movd.t_ili2db_dataset d ON ((b.dataset = d.fid)))
          WHERE (((d.datasetname)::text = '132'::text) AND ((p.identdn)::text ~~ 'VD0132%'::text))) pc ON (((pl.numero_point)::text = (pc.numero)::text)))
  WHERE ((pl.numcom = 132) AND ((((pl.type)::text = 'PFP3'::text) AND ((pl.numero_point)::text <> 'new'::text)) OR (pl.fid IS NULL)));


ALTER TABLE specificite_lausanne.control_pfp OWNER TO postgres;

--
-- Name: dico_cprue_ls pk_dico_cprue_ls; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.dico_cprue_ls
    ADD CONSTRAINT pk_dico_cprue_ls PRIMARY KEY (idaddress);


--
-- Name: lien_arbre_espece_cultivar pk_lien_arbre_espece_cultivar; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.lien_arbre_espece_cultivar
    ADD CONSTRAINT pk_lien_arbre_espece_cultivar PRIMARY KEY (idespece, idcultivar);


--
-- Name: lien_arbre_genre_espece pk_lien_arbre_genre_espece; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.lien_arbre_genre_espece
    ADD CONSTRAINT pk_lien_arbre_genre_espece PRIMARY KEY (idgenre, idespece);


--
-- Name: parcelle pk_parcelle; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.parcelle
    ADD CONSTRAINT pk_parcelle PRIMARY KEY (idthing);


--
-- Name: parcelle_dico_type pk_parcelle_dico_type; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.parcelle_dico_type
    ADD CONSTRAINT pk_parcelle_dico_type PRIMARY KEY (idtypep);


--
-- Name: thi_arbre pk_thi_arbre; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre
    ADD CONSTRAINT pk_thi_arbre PRIMARY KEY (idthing);


--
-- Name: thi_arbre_cultivar pk_thi_arbre_cultivar; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre_cultivar
    ADD CONSTRAINT pk_thi_arbre_cultivar PRIMARY KEY (id);


--
-- Name: thi_arbre_diam_couronne pk_thi_arbre_diam_couronne; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre_diam_couronne
    ADD CONSTRAINT pk_thi_arbre_diam_couronne PRIMARY KEY (id);


--
-- Name: thi_arbre_espece pk_thi_arbre_espece; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre_espece
    ADD CONSTRAINT pk_thi_arbre_espece PRIMARY KEY (id);


--
-- Name: thi_arbre_genre pk_thi_arbre_genre; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre_genre
    ADD CONSTRAINT pk_thi_arbre_genre PRIMARY KEY (id);


--
-- Name: thi_arbre_hauteur pk_thi_arbre_hauteur; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre_hauteur
    ADD CONSTRAINT pk_thi_arbre_hauteur PRIMARY KEY (id);


--
-- Name: thi_arbre_validation pk_thi_arbre_validation; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_arbre_validation
    ADD CONSTRAINT pk_thi_arbre_validation PRIMARY KEY (id);


--
-- Name: thi_building pk_thi_building; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_building
    ADD CONSTRAINT pk_thi_building PRIMARY KEY (idthing);


--
-- Name: thi_building_bat_principal pk_thi_building_bat_principal; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_building_bat_principal
    ADD CONSTRAINT pk_thi_building_bat_principal PRIMARY KEY (idthing, idthingbatprincipal);


--
-- Name: thi_building_egid pk_thi_building_egid; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_building_egid
    ADD CONSTRAINT pk_thi_building_egid PRIMARY KEY (idthing, egid);


--
-- Name: thi_building_no_eca pk_thi_building_no_eca; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_building_no_eca
    ADD CONSTRAINT pk_thi_building_no_eca PRIMARY KEY (idthibuilding, numeroeca);


--
-- Name: thi_sondage_geo_therm pk_thi_sondage_geo_therm; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_sondage_geo_therm
    ADD CONSTRAINT pk_thi_sondage_geo_therm PRIMARY KEY (idthing);


--
-- Name: thi_street pk_thi_street; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_street
    ADD CONSTRAINT pk_thi_street PRIMARY KEY (idthing);


--
-- Name: thi_street_building_address pk_thi_street_building_address; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thi_street_building_address
    ADD CONSTRAINT pk_thi_street_building_address PRIMARY KEY (idaddress);


--
-- Name: thing pk_thing; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thing
    ADD CONSTRAINT pk_thing PRIMARY KEY (idthing);


--
-- Name: thing_position pk_thing_position; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.thing_position
    ADD CONSTRAINT pk_thing_position PRIMARY KEY (idthing);


--
-- Name: type_thi_street pk_type_thi_street; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.type_thi_street
    ADD CONSTRAINT pk_type_thi_street PRIMARY KEY (idtypestreet);


--
-- Name: type_thing pk_type_thing; Type: CONSTRAINT; Schema: goeland; Owner: goeland
--

ALTER TABLE ONLY goeland.type_thing
    ADD CONSTRAINT pk_type_thing PRIMARY KEY (idtypething);


--
-- Name: abreviation_cantonale abreviation_cantonale_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.abreviation_cantonale
    ADD CONSTRAINT abreviation_cantonale_pkey PRIMARY KEY (itfcode);


--
-- Name: aplan aplan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.aplan
    ADD CONSTRAINT aplan_pkey PRIMARY KEY (fid);


--
-- Name: arete_genre arete_genre_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.arete_genre
    ADD CONSTRAINT arete_genre_pkey PRIMARY KEY (itfcode);


--
-- Name: arete arete_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.arete
    ADD CONSTRAINT arete_pkey PRIMARY KEY (fid);


--
-- Name: asignal asignal_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.asignal
    ADD CONSTRAINT asignal_pkey PRIMARY KEY (fid);


--
-- Name: bien_fonds bien_fonds_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bien_fonds
    ADD CONSTRAINT bien_fonds_pkey PRIMARY KEY (fid);


--
-- Name: bien_fondsproj bien_fondsproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bien_fondsproj
    ADD CONSTRAINT bien_fondsproj_pkey PRIMARY KEY (fid);


--
-- Name: bord_de_plan_avec_reseau_coord bord_de_plan_avec_reseau_coord_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bord_de_plan_avec_reseau_coord
    ADD CONSTRAINT bord_de_plan_avec_reseau_coord_pkey PRIMARY KEY (itfcode);


--
-- Name: bord_de_plan bord_de_plan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bord_de_plan
    ADD CONSTRAINT bord_de_plan_pkey PRIMARY KEY (fid);


--
-- Name: commune commune_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.commune
    ADD CONSTRAINT commune_pkey PRIMARY KEY (fid);


--
-- Name: croix_filet croix_filet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.croix_filet
    ADD CONSTRAINT croix_filet_pkey PRIMARY KEY (fid);


--
-- Name: ddp ddp_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ddp
    ADD CONSTRAINT ddp_pkey PRIMARY KEY (fid);


--
-- Name: ddpproj ddpproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ddpproj
    ADD CONSTRAINT ddpproj_pkey PRIMARY KEY (fid);


--
-- Name: description_batiment description_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.description_batiment
    ADD CONSTRAINT description_batiment_pkey PRIMARY KEY (fid);


--
-- Name: description_plan description_plan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.description_plan
    ADD CONSTRAINT description_plan_pkey PRIMARY KEY (fid);


--
-- Name: designation_batiment designation_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.designation_batiment
    ADD CONSTRAINT designation_batiment_pkey PRIMARY KEY (itfcode);


--
-- Name: domaine_numerotation domaine_numerotation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.domaine_numerotation
    ADD CONSTRAINT domaine_numerotation_pkey PRIMARY KEY (fid);


--
-- Name: element_conduite element_conduite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_conduite
    ADD CONSTRAINT element_conduite_pkey PRIMARY KEY (fid);


--
-- Name: element_lineaire_genre_ligne element_lineaire_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_lineaire_genre_ligne
    ADD CONSTRAINT element_lineaire_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: element_lineaire element_lineaire_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_lineaire
    ADD CONSTRAINT element_lineaire_pkey PRIMARY KEY (fid);


--
-- Name: element_ponctuel element_ponctuel_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_ponctuel
    ADD CONSTRAINT element_ponctuel_pkey PRIMARY KEY (fid);


--
-- Name: element_surfacique element_surfacique_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_surfacique
    ADD CONSTRAINT element_surfacique_pkey PRIMARY KEY (fid);


--
-- Name: entree_batiment_attributs_provisoires entree_batiment_attributs_provisoires_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment_attributs_provisoires
    ADD CONSTRAINT entree_batiment_attributs_provisoires_pkey PRIMARY KEY (itfcode);


--
-- Name: entree_batiment_dans_batiment entree_batiment_dans_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment_dans_batiment
    ADD CONSTRAINT entree_batiment_dans_batiment_pkey PRIMARY KEY (itfcode);


--
-- Name: entree_batiment_en_cours_modification entree_batiment_en_cours_modification_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment_en_cours_modification
    ADD CONSTRAINT entree_batiment_en_cours_modification_pkey PRIMARY KEY (itfcode);


--
-- Name: entree_batiment_est_designation_officielle entree_batiment_est_designation_officielle_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment_est_designation_officielle
    ADD CONSTRAINT entree_batiment_est_designation_officielle_pkey PRIMARY KEY (itfcode);


--
-- Name: entree_batiment entree_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment
    ADD CONSTRAINT entree_batiment_pkey PRIMARY KEY (fid);


--
-- Name: fiabilite fiabilite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.fiabilite
    ADD CONSTRAINT fiabilite_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_croix genre_croix_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_croix
    ADD CONSTRAINT genre_croix_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_cs genre_cs_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_cs
    ADD CONSTRAINT genre_cs_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_description genre_description_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_description
    ADD CONSTRAINT genre_description_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_format genre_format_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_format
    ADD CONSTRAINT genre_format_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_immeuble genre_immeuble_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_immeuble
    ADD CONSTRAINT genre_immeuble_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_od genre_od_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_od
    ADD CONSTRAINT genre_od_pkey PRIMARY KEY (itfcode);


--
-- Name: genre_symbole genre_symbole_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.genre_symbole
    ADD CONSTRAINT genre_symbole_pkey PRIMARY KEY (itfcode);


--
-- Name: geometrie_plan geometrie_plan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.geometrie_plan
    ADD CONSTRAINT geometrie_plan_pkey PRIMARY KEY (fid);


--
-- Name: geometriedn geometriedn_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.geometriedn
    ADD CONSTRAINT geometriedn_pkey PRIMARY KEY (fid);


--
-- Name: glissement glissement_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.glissement
    ADD CONSTRAINT glissement_pkey PRIMARY KEY (fid);


--
-- Name: grandeurecriture grandeurecriture_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.grandeurecriture
    ADD CONSTRAINT grandeurecriture_pkey PRIMARY KEY (itfcode);


--
-- Name: groupement_de_localite groupement_de_localite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.groupement_de_localite
    ADD CONSTRAINT groupement_de_localite_pkey PRIMARY KEY (fid);


--
-- Name: halignment halignment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.halignment
    ADD CONSTRAINT halignment_pkey PRIMARY KEY (itfcode);


--
-- Name: immeuble_integralite immeuble_integralite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeuble_integralite
    ADD CONSTRAINT immeuble_integralite_pkey PRIMARY KEY (itfcode);


--
-- Name: immeuble immeuble_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeuble
    ADD CONSTRAINT immeuble_pkey PRIMARY KEY (fid);


--
-- Name: immeuble_validite immeuble_validite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeuble_validite
    ADD CONSTRAINT immeuble_validite_pkey PRIMARY KEY (itfcode);


--
-- Name: immeubleproj_integralite immeubleproj_integralite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeubleproj_integralite
    ADD CONSTRAINT immeubleproj_integralite_pkey PRIMARY KEY (itfcode);


--
-- Name: immeubleproj immeubleproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeubleproj
    ADD CONSTRAINT immeubleproj_pkey PRIMARY KEY (fid);


--
-- Name: immeubleproj_validite immeubleproj_validite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeubleproj_validite
    ADD CONSTRAINT immeubleproj_validite_pkey PRIMARY KEY (itfcode);


--
-- Name: indication_coordonnees indication_coordonnees_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.indication_coordonnees
    ADD CONSTRAINT indication_coordonnees_pkey PRIMARY KEY (fid);


--
-- Name: lieu_denomme lieu_denomme_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lieu_denomme
    ADD CONSTRAINT lieu_denomme_pkey PRIMARY KEY (fid);


--
-- Name: lieudit lieudit_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lieudit
    ADD CONSTRAINT lieudit_pkey PRIMARY KEY (fid);


--
-- Name: ligne_coordonnees ligne_coordonnees_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ligne_coordonnees
    ADD CONSTRAINT ligne_coordonnees_pkey PRIMARY KEY (fid);


--
-- Name: limite_commune limite_commune_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_commune
    ADD CONSTRAINT limite_commune_pkey PRIMARY KEY (fid);


--
-- Name: limite_communeproj limite_communeproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_communeproj
    ADD CONSTRAINT limite_communeproj_pkey PRIMARY KEY (fid);


--
-- Name: lineattrib10_genre_ligne lineattrib10_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib10_genre_ligne
    ADD CONSTRAINT lineattrib10_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib3_genre_ligne lineattrib3_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib3_genre_ligne
    ADD CONSTRAINT lineattrib3_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib4_genre_ligne lineattrib4_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib4_genre_ligne
    ADD CONSTRAINT lineattrib4_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib5_genre_ligne lineattrib5_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib5_genre_ligne
    ADD CONSTRAINT lineattrib5_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib6_genre_ligne lineattrib6_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib6_genre_ligne
    ADD CONSTRAINT lineattrib6_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib7_genre_ligne lineattrib7_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib7_genre_ligne
    ADD CONSTRAINT lineattrib7_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib8_genre_ligne lineattrib8_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib8_genre_ligne
    ADD CONSTRAINT lineattrib8_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: lineattrib9_genre_ligne lineattrib9_genre_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lineattrib9_genre_ligne
    ADD CONSTRAINT lineattrib9_genre_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: localisation_attributs_provisoires localisation_attributs_provisoires_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation_attributs_provisoires
    ADD CONSTRAINT localisation_attributs_provisoires_pkey PRIMARY KEY (itfcode);


--
-- Name: localisation_en_cours_modification localisation_en_cours_modification_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation_en_cours_modification
    ADD CONSTRAINT localisation_en_cours_modification_pkey PRIMARY KEY (itfcode);


--
-- Name: localisation_est_designation_officielle localisation_est_designation_officielle_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation_est_designation_officielle
    ADD CONSTRAINT localisation_est_designation_officielle_pkey PRIMARY KEY (itfcode);


--
-- Name: localisation_genre localisation_genre_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation_genre
    ADD CONSTRAINT localisation_genre_pkey PRIMARY KEY (itfcode);


--
-- Name: localisation localisation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation
    ADD CONSTRAINT localisation_pkey PRIMARY KEY (fid);


--
-- Name: localisation_principe_numerotation localisation_principe_numerotation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation_principe_numerotation
    ADD CONSTRAINT localisation_principe_numerotation_pkey PRIMARY KEY (itfcode);


--
-- Name: localite_en_cours_modification localite_en_cours_modification_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localite_en_cours_modification
    ADD CONSTRAINT localite_en_cours_modification_pkey PRIMARY KEY (itfcode);


--
-- Name: localite localite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localite
    ADD CONSTRAINT localite_pkey PRIMARY KEY (fid);


--
-- Name: materiel materiel_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.materiel
    ADD CONSTRAINT materiel_pkey PRIMARY KEY (itfcode);


--
-- Name: matiere matiere_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.matiere
    ADD CONSTRAINT matiere_pkey PRIMARY KEY (itfcode);


--
-- Name: md01mvdmn95v24bords_de_plan_element_lineaire md01mvdmn95v24bords_de_plan_element_lineaire_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24bords_de_plan_element_lineaire
    ADD CONSTRAINT md01mvdmn95v24bords_de_plan_element_lineaire_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24conduites_element_lineaire md01mvdmn95v24conduites_element_lineaire_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_lineaire
    ADD CONSTRAINT md01mvdmn95v24conduites_element_lineaire_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24conduites_element_ponctuel md01mvdmn95v24conduites_element_ponctuel_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_ponctuel
    ADD CONSTRAINT md01mvdmn95v24conduites_element_ponctuel_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24conduites_element_surfacique md01mvdmn95v24conduites_element_surfacique_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_surfacique
    ADD CONSTRAINT md01mvdmn95v24conduites_element_surfacique_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24conduites_point_particulier md01mvdmn95v24conduites_point_particulier_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_point_particulier
    ADD CONSTRAINT md01mvdmn95v24conduites_point_particulier_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24conduites_pospoint_particulier md01mvdmn95v24conduites_pospoint_particulier_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_pospoint_particulier
    ADD CONSTRAINT md01mvdmn95v24conduites_pospoint_particulier_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24objets_divers_nom_objet md01mvdmn95v24objets_divers_nom_objet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_nom_objet
    ADD CONSTRAINT md01mvdmn95v24objets_divers_nom_objet_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24objets_divers_point_particulier md01mvdmn95v24objets_divers_point_particulier_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_point_particulier
    ADD CONSTRAINT md01mvdmn95v24objets_divers_point_particulier_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24objets_divers_posnom_objet md01mvdmn95v24objets_divers_posnom_objet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_posnom_objet
    ADD CONSTRAINT md01mvdmn95v24objets_divers_posnom_objet_pkey PRIMARY KEY (fid);


--
-- Name: md01mvdmn95v24objets_divers_pospoint_particulier md01mvdmn95v24objets_divers_pospoint_particulier_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_pospoint_particulier
    ADD CONSTRAINT md01mvdmn95v24objets_divers_pospoint_particulier_pkey PRIMARY KEY (fid);


--
-- Name: md01mvn95v24conduites_point_particulier_defini_exactement md01mvn95v24conduites_point_particulier_defini_exactement_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvn95v24conduites_point_particulier_defini_exactement
    ADD CONSTRAINT md01mvn95v24conduites_point_particulier_defini_exactement_pkey PRIMARY KEY (itfcode);


--
-- Name: md01mvn95v24couvertur_d_sol_point_particulier_defini_xctment md01mvn95v24couvertur_d_sol_point_particulier_defini_xctme_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvn95v24couvertur_d_sol_point_particulier_defini_xctment
    ADD CONSTRAINT md01mvn95v24couvertur_d_sol_point_particulier_defini_xctme_pkey PRIMARY KEY (itfcode);


--
-- Name: md01mvn95v24objets_divers_point_particulier_defini_exactment md01mvn95v24objets_divers_point_particulier_defini_exactme_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvn95v24objets_divers_point_particulier_defini_exactment
    ADD CONSTRAINT md01mvn95v24objets_divers_point_particulier_defini_exactme_pkey PRIMARY KEY (itfcode);


--
-- Name: mine mine_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mine
    ADD CONSTRAINT mine_pkey PRIMARY KEY (fid);


--
-- Name: mineproj mineproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mineproj
    ADD CONSTRAINT mineproj_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_joural mise_a_joural_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_joural
    ADD CONSTRAINT mise_a_joural_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourbat mise_a_jourbat_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourbat
    ADD CONSTRAINT mise_a_jourbat_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourbf mise_a_jourbf_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourbf
    ADD CONSTRAINT mise_a_jourbf_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourco mise_a_jourco_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourco
    ADD CONSTRAINT mise_a_jourco_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourcom mise_a_jourcom_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourcom
    ADD CONSTRAINT mise_a_jourcom_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourcs mise_a_jourcs_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourcs
    ADD CONSTRAINT mise_a_jourcs_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourloc mise_a_jourloc_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourloc
    ADD CONSTRAINT mise_a_jourloc_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_journo mise_a_journo_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_journo
    ADD CONSTRAINT mise_a_journo_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_journpa6 mise_a_journpa6_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_journpa6
    ADD CONSTRAINT mise_a_journpa6_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourod mise_a_jourod_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourod
    ADD CONSTRAINT mise_a_jourod_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourpfa1 mise_a_jourpfa1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfa1
    ADD CONSTRAINT mise_a_jourpfa1_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourpfa2 mise_a_jourpfa2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfa2
    ADD CONSTRAINT mise_a_jourpfa2_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourpfa3 mise_a_jourpfa3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfa3
    ADD CONSTRAINT mise_a_jourpfa3_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourpfp1 mise_a_jourpfp1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfp1
    ADD CONSTRAINT mise_a_jourpfp1_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourpfp2 mise_a_jourpfp2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfp2
    ADD CONSTRAINT mise_a_jourpfp2_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourpfp3 mise_a_jourpfp3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfp3
    ADD CONSTRAINT mise_a_jourpfp3_pkey PRIMARY KEY (fid);


--
-- Name: mise_a_jourrp mise_a_jourrp_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourrp
    ADD CONSTRAINT mise_a_jourrp_pkey PRIMARY KEY (fid);


--
-- Name: niveau_tolerance_genre niveau_tolerance_genre_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.niveau_tolerance_genre
    ADD CONSTRAINT niveau_tolerance_genre_pkey PRIMARY KEY (itfcode);


--
-- Name: niveau_tolerance niveau_tolerance_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.niveau_tolerance
    ADD CONSTRAINT niveau_tolerance_pkey PRIMARY KEY (fid);


--
-- Name: nom_batiment nom_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_batiment
    ADD CONSTRAINT nom_batiment_pkey PRIMARY KEY (fid);


--
-- Name: nom_de_lieu nom_de_lieu_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_de_lieu
    ADD CONSTRAINT nom_de_lieu_pkey PRIMARY KEY (fid);


--
-- Name: nom_local nom_local_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_local
    ADD CONSTRAINT nom_local_pkey PRIMARY KEY (fid);


--
-- Name: nom_localisation nom_localisation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_localisation
    ADD CONSTRAINT nom_localisation_pkey PRIMARY KEY (fid);


--
-- Name: nom_localite nom_localite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_localite
    ADD CONSTRAINT nom_localite_pkey PRIMARY KEY (fid);


--
-- Name: nom_objet nom_objet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_objet
    ADD CONSTRAINT nom_objet_pkey PRIMARY KEY (fid);


--
-- Name: nomobjetproj nomobjetproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nomobjetproj
    ADD CONSTRAINT nomobjetproj_pkey PRIMARY KEY (fid);


--
-- Name: npa6_en_cours_modification npa6_en_cours_modification_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.npa6_en_cours_modification
    ADD CONSTRAINT npa6_en_cours_modification_pkey PRIMARY KEY (itfcode);


--
-- Name: npa6 npa6_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.npa6
    ADD CONSTRAINT npa6_pkey PRIMARY KEY (fid);


--
-- Name: numero_de_batiment numero_de_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numero_de_batiment
    ADD CONSTRAINT numero_de_batiment_pkey PRIMARY KEY (fid);


--
-- Name: numero_objet numero_objet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numero_objet
    ADD CONSTRAINT numero_objet_pkey PRIMARY KEY (fid);


--
-- Name: numerobatimentproj numerobatimentproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numerobatimentproj
    ADD CONSTRAINT numerobatimentproj_pkey PRIMARY KEY (fid);


--
-- Name: objet_divers objet_divers_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.objet_divers
    ADD CONSTRAINT objet_divers_pkey PRIMARY KEY (fid);


--
-- Name: partie_limite_canton partie_limite_canton_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_canton
    ADD CONSTRAINT partie_limite_canton_pkey PRIMARY KEY (fid);


--
-- Name: partie_limite_canton_validite partie_limite_canton_validite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_canton_validite
    ADD CONSTRAINT partie_limite_canton_validite_pkey PRIMARY KEY (itfcode);


--
-- Name: partie_limite_district partie_limite_district_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_district
    ADD CONSTRAINT partie_limite_district_pkey PRIMARY KEY (fid);


--
-- Name: partie_limite_district_validite partie_limite_district_validite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_district_validite
    ADD CONSTRAINT partie_limite_district_validite_pkey PRIMARY KEY (itfcode);


--
-- Name: partie_limite_nationale partie_limite_nationale_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_nationale
    ADD CONSTRAINT partie_limite_nationale_pkey PRIMARY KEY (fid);


--
-- Name: partie_limite_nationale_validite partie_limite_nationale_validite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_nationale_validite
    ADD CONSTRAINT partie_limite_nationale_validite_pkey PRIMARY KEY (itfcode);


--
-- Name: pfa1 pfa1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa1
    ADD CONSTRAINT pfa1_pkey PRIMARY KEY (fid);


--
-- Name: pfa2 pfa2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa2
    ADD CONSTRAINT pfa2_pkey PRIMARY KEY (fid);


--
-- Name: pfa3 pfa3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa3
    ADD CONSTRAINT pfa3_pkey PRIMARY KEY (fid);


--
-- Name: pfp1_accessibilite pfp1_accessibilite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp1_accessibilite
    ADD CONSTRAINT pfp1_accessibilite_pkey PRIMARY KEY (itfcode);


--
-- Name: pfp1 pfp1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp1
    ADD CONSTRAINT pfp1_pkey PRIMARY KEY (fid);


--
-- Name: pfp2_accessibilite pfp2_accessibilite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp2_accessibilite
    ADD CONSTRAINT pfp2_accessibilite_pkey PRIMARY KEY (itfcode);


--
-- Name: pfp2 pfp2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp2
    ADD CONSTRAINT pfp2_pkey PRIMARY KEY (fid);


--
-- Name: pfp3_fiche pfp3_fiche_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp3_fiche
    ADD CONSTRAINT pfp3_fiche_pkey PRIMARY KEY (itfcode);


--
-- Name: pfp3 pfp3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp3
    ADD CONSTRAINT pfp3_pkey PRIMARY KEY (fid);


--
-- Name: point_cote point_cote_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_cote
    ADD CONSTRAINT point_cote_pkey PRIMARY KEY (fid);


--
-- Name: point_limite_anc_borne_speciale point_limite_anc_borne_speciale_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_anc_borne_speciale
    ADD CONSTRAINT point_limite_anc_borne_speciale_pkey PRIMARY KEY (itfcode);


--
-- Name: point_limite_defini_exactement point_limite_defini_exactement_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_defini_exactement
    ADD CONSTRAINT point_limite_defini_exactement_pkey PRIMARY KEY (itfcode);


--
-- Name: point_limite point_limite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite
    ADD CONSTRAINT point_limite_pkey PRIMARY KEY (fid);


--
-- Name: point_limite_ter_borne_territoriale point_limite_ter_borne_territoriale_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_ter_borne_territoriale
    ADD CONSTRAINT point_limite_ter_borne_territoriale_pkey PRIMARY KEY (itfcode);


--
-- Name: point_limite_ter_defini_exactement point_limite_ter_defini_exactement_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_ter_defini_exactement
    ADD CONSTRAINT point_limite_ter_defini_exactement_pkey PRIMARY KEY (itfcode);


--
-- Name: point_limite_ter point_limite_ter_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_ter
    ADD CONSTRAINT point_limite_ter_pkey PRIMARY KEY (fid);


--
-- Name: point_particulier_defini_exactement point_particulier_defini_exactement_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_particulier_defini_exactement
    ADD CONSTRAINT point_particulier_defini_exactement_pkey PRIMARY KEY (itfcode);


--
-- Name: point_particulier point_particulier_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_particulier
    ADD CONSTRAINT point_particulier_pkey PRIMARY KEY (fid);


--
-- Name: posdescription_plan posdescription_plan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posdescription_plan
    ADD CONSTRAINT posdescription_plan_pkey PRIMARY KEY (fid);


--
-- Name: posdomaine_numerotation posdomaine_numerotation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posdomaine_numerotation
    ADD CONSTRAINT posdomaine_numerotation_pkey PRIMARY KEY (fid);


--
-- Name: poselement_conduite poselement_conduite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.poselement_conduite
    ADD CONSTRAINT poselement_conduite_pkey PRIMARY KEY (fid);


--
-- Name: posglissement posglissement_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posglissement
    ADD CONSTRAINT posglissement_pkey PRIMARY KEY (fid);


--
-- Name: posimmeuble posimmeuble_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posimmeuble
    ADD CONSTRAINT posimmeuble_pkey PRIMARY KEY (fid);


--
-- Name: posimmeubleproj posimmeubleproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posimmeubleproj
    ADD CONSTRAINT posimmeubleproj_pkey PRIMARY KEY (fid);


--
-- Name: posindication_coord posindication_coord_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posindication_coord
    ADD CONSTRAINT posindication_coord_pkey PRIMARY KEY (fid);


--
-- Name: poslieudit poslieudit_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.poslieudit
    ADD CONSTRAINT poslieudit_pkey PRIMARY KEY (fid);


--
-- Name: posniveau_tolerance posniveau_tolerance_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posniveau_tolerance
    ADD CONSTRAINT posniveau_tolerance_pkey PRIMARY KEY (fid);


--
-- Name: posnom_batiment posnom_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_batiment
    ADD CONSTRAINT posnom_batiment_pkey PRIMARY KEY (fid);


--
-- Name: posnom_de_lieu posnom_de_lieu_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_de_lieu
    ADD CONSTRAINT posnom_de_lieu_pkey PRIMARY KEY (fid);


--
-- Name: posnom_local posnom_local_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_local
    ADD CONSTRAINT posnom_local_pkey PRIMARY KEY (fid);


--
-- Name: posnom_localisation posnom_localisation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_localisation
    ADD CONSTRAINT posnom_localisation_pkey PRIMARY KEY (fid);


--
-- Name: posnom_localite posnom_localite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_localite
    ADD CONSTRAINT posnom_localite_pkey PRIMARY KEY (fid);


--
-- Name: posnom_objet posnom_objet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_objet
    ADD CONSTRAINT posnom_objet_pkey PRIMARY KEY (fid);


--
-- Name: posnomobjetproj posnomobjetproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnomobjetproj
    ADD CONSTRAINT posnomobjetproj_pkey PRIMARY KEY (fid);


--
-- Name: posnumero_de_batiment posnumero_de_batiment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_de_batiment
    ADD CONSTRAINT posnumero_de_batiment_pkey PRIMARY KEY (fid);


--
-- Name: posnumero_maison posnumero_maison_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_maison
    ADD CONSTRAINT posnumero_maison_pkey PRIMARY KEY (fid);


--
-- Name: posnumero_objet posnumero_objet_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_objet
    ADD CONSTRAINT posnumero_objet_pkey PRIMARY KEY (fid);


--
-- Name: posnumerobatimentproj posnumerobatimentproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumerobatimentproj
    ADD CONSTRAINT posnumerobatimentproj_pkey PRIMARY KEY (fid);


--
-- Name: pospfa1 pospfa1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa1
    ADD CONSTRAINT pospfa1_pkey PRIMARY KEY (fid);


--
-- Name: pospfa2 pospfa2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa2
    ADD CONSTRAINT pospfa2_pkey PRIMARY KEY (fid);


--
-- Name: pospfa3 pospfa3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa3
    ADD CONSTRAINT pospfa3_pkey PRIMARY KEY (fid);


--
-- Name: pospfp1 pospfp1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp1
    ADD CONSTRAINT pospfp1_pkey PRIMARY KEY (fid);


--
-- Name: pospfp2 pospfp2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp2
    ADD CONSTRAINT pospfp2_pkey PRIMARY KEY (fid);


--
-- Name: pospfp3 pospfp3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp3
    ADD CONSTRAINT pospfp3_pkey PRIMARY KEY (fid);


--
-- Name: posplan posplan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posplan
    ADD CONSTRAINT posplan_pkey PRIMARY KEY (fid);


--
-- Name: pospoint_cote pospoint_cote_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_cote
    ADD CONSTRAINT pospoint_cote_pkey PRIMARY KEY (fid);


--
-- Name: pospoint_limite pospoint_limite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_limite
    ADD CONSTRAINT pospoint_limite_pkey PRIMARY KEY (fid);


--
-- Name: pospoint_limite_ter pospoint_limite_ter_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_limite_ter
    ADD CONSTRAINT pospoint_limite_ter_pkey PRIMARY KEY (fid);


--
-- Name: pospoint_particulier pospoint_particulier_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_particulier
    ADD CONSTRAINT pospoint_particulier_pkey PRIMARY KEY (fid);


--
-- Name: possignal possignal_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.possignal
    ADD CONSTRAINT possignal_pkey PRIMARY KEY (fid);


--
-- Name: signal_genre_point signal_genre_point_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.signal_genre_point
    ADD CONSTRAINT signal_genre_point_pkey PRIMARY KEY (itfcode);


--
-- Name: standardqualite standardqualite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.standardqualite
    ADD CONSTRAINT standardqualite_pkey PRIMARY KEY (itfcode);


--
-- Name: statut_mise_a_jour_ab statut_mise_a_jour_ab_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.statut_mise_a_jour_ab
    ADD CONSTRAINT statut_mise_a_jour_ab_pkey PRIMARY KEY (itfcode);


--
-- Name: statut statut_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.statut
    ADD CONSTRAINT statut_pkey PRIMARY KEY (itfcode);


--
-- Name: styleecriture styleecriture_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.styleecriture
    ADD CONSTRAINT styleecriture_pkey PRIMARY KEY (itfcode);


--
-- Name: surface_representation_choix_representation surface_representation_choix_representation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_representation_choix_representation
    ADD CONSTRAINT surface_representation_choix_representation_pkey PRIMARY KEY (itfcode);


--
-- Name: surface_representation surface_representation_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_representation
    ADD CONSTRAINT surface_representation_pkey PRIMARY KEY (fid);


--
-- Name: surface_vide_genre surface_vide_genre_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_vide_genre
    ADD CONSTRAINT surface_vide_genre_pkey PRIMARY KEY (itfcode);


--
-- Name: surface_vide surface_vide_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_vide
    ADD CONSTRAINT surface_vide_pkey PRIMARY KEY (fid);


--
-- Name: surfacecs surfacecs_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surfacecs
    ADD CONSTRAINT surfacecs_pkey PRIMARY KEY (fid);


--
-- Name: surfacecsproj surfacecsproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surfacecsproj
    ADD CONSTRAINT surfacecsproj_pkey PRIMARY KEY (fid);


--
-- Name: symbolebord_de_plan symbolebord_de_plan_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolebord_de_plan
    ADD CONSTRAINT symbolebord_de_plan_pkey PRIMARY KEY (fid);


--
-- Name: symboleelement_lineaire symboleelement_lineaire_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symboleelement_lineaire
    ADD CONSTRAINT symboleelement_lineaire_pkey PRIMARY KEY (fid);


--
-- Name: symboleelement_surf symboleelement_surf_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symboleelement_surf
    ADD CONSTRAINT symboleelement_surf_pkey PRIMARY KEY (fid);


--
-- Name: symbolepfp1 symbolepfp1_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp1
    ADD CONSTRAINT symbolepfp1_pkey PRIMARY KEY (fid);


--
-- Name: symbolepfp2 symbolepfp2_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp2
    ADD CONSTRAINT symbolepfp2_pkey PRIMARY KEY (fid);


--
-- Name: symbolepfp3 symbolepfp3_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp3
    ADD CONSTRAINT symbolepfp3_pkey PRIMARY KEY (fid);


--
-- Name: symbolepoint_limite symbolepoint_limite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepoint_limite
    ADD CONSTRAINT symbolepoint_limite_pkey PRIMARY KEY (fid);


--
-- Name: symbolepoint_limite_ter symbolepoint_limite_ter_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepoint_limite_ter
    ADD CONSTRAINT symbolepoint_limite_ter_pkey PRIMARY KEY (fid);


--
-- Name: symbolesurfacecs symbolesurfacecs_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolesurfacecs
    ADD CONSTRAINT symbolesurfacecs_pkey PRIMARY KEY (fid);


--
-- Name: symbolesurfacecsproj symbolesurfacecsproj_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolesurfacecsproj
    ADD CONSTRAINT symbolesurfacecsproj_pkey PRIMARY KEY (fid);


--
-- Name: t_ili2db_attrname t_ili2db_attrname_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_attrname
    ADD CONSTRAINT t_ili2db_attrname_pkey PRIMARY KEY (sqlname, colowner);


--
-- Name: t_ili2db_basket t_ili2db_basket_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_basket
    ADD CONSTRAINT t_ili2db_basket_pkey PRIMARY KEY (fid);


--
-- Name: t_ili2db_classname t_ili2db_classname_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_classname
    ADD CONSTRAINT t_ili2db_classname_pkey PRIMARY KEY (iliname);


--
-- Name: t_ili2db_dataset t_ili2db_dataset_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_dataset
    ADD CONSTRAINT t_ili2db_dataset_pkey PRIMARY KEY (fid);


--
-- Name: t_ili2db_inheritance t_ili2db_inheritance_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_inheritance
    ADD CONSTRAINT t_ili2db_inheritance_pkey PRIMARY KEY (thisclass);


--
-- Name: t_ili2db_model t_ili2db_model_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_model
    ADD CONSTRAINT t_ili2db_model_pkey PRIMARY KEY (modelname, iliversion);


--
-- Name: t_ili2db_settings t_ili2db_settings_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_settings
    ADD CONSTRAINT t_ili2db_settings_pkey PRIMARY KEY (tag);


--
-- Name: texte_groupement_de_localite texte_groupement_de_localite_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.texte_groupement_de_localite
    ADD CONSTRAINT texte_groupement_de_localite_pkey PRIMARY KEY (fid);


--
-- Name: troncon_rue_est_axe troncon_rue_est_axe_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.troncon_rue_est_axe
    ADD CONSTRAINT troncon_rue_est_axe_pkey PRIMARY KEY (itfcode);


--
-- Name: troncon_rue troncon_rue_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.troncon_rue
    ADD CONSTRAINT troncon_rue_pkey PRIMARY KEY (fid);


--
-- Name: type_ligne type_ligne_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.type_ligne
    ADD CONSTRAINT type_ligne_pkey PRIMARY KEY (itfcode);


--
-- Name: typelangue typelangue_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.typelangue
    ADD CONSTRAINT typelangue_pkey PRIMARY KEY (itfcode);


--
-- Name: valignment valignment_pkey; Type: CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.valignment
    ADD CONSTRAINT valignment_pkey PRIMARY KEY (itfcode);


--
-- Name: surface_batiment_projet batiment_chantier_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.surface_batiment_projet
    ADD CONSTRAINT batiment_chantier_pkey PRIMARY KEY (fid);


--
-- Name: entree_batiment_projet entree_batiment_projet_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.entree_batiment_projet
    ADD CONSTRAINT entree_batiment_projet_pkey PRIMARY KEY (fid);


--
-- Name: localisation_rue localisation_rue_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.localisation_rue
    ADD CONSTRAINT localisation_rue_pkey PRIMARY KEY (fid);


--
-- Name: objet_divers_ponctuel objet_divers_arbre_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.objet_divers_ponctuel
    ADD CONSTRAINT objet_divers_arbre_pkey PRIMARY KEY (ufid);


--
-- Name: objet_divers_lineaire objet_divers_lineaire_autre_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.objet_divers_lineaire
    ADD CONSTRAINT objet_divers_lineaire_autre_pkey PRIMARY KEY (ufid);


--
-- Name: objet_divers_surfacique objet_divers_polygon_autre_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.objet_divers_surfacique
    ADD CONSTRAINT objet_divers_polygon_autre_pkey PRIMARY KEY (ufid);


--
-- Name: pfa pfa_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.pfa
    ADD CONSTRAINT pfa_pkey PRIMARY KEY (fid);


--
-- Name: pfp_label_reperage pfp_label_reperage_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.pfp_label_reperage
    ADD CONSTRAINT pfp_label_reperage_pkey PRIMARY KEY (fid);


--
-- Name: pfp_line_reperage pfp_line_reperage_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.pfp_line_reperage
    ADD CONSTRAINT pfp_line_reperage_pkey PRIMARY KEY (fid);


--
-- Name: pfp pfp_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.pfp
    ADD CONSTRAINT pfp_pkey PRIMARY KEY (fid);


--
-- Name: pfp_point_reperage pfp_point_reperage_pkey; Type: CONSTRAINT; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY specificite_lausanne.pfp_point_reperage
    ADD CONSTRAINT pfp_point_reperage_pkey PRIMARY KEY (fid);


--
-- Name: aplan_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX aplan_origine_idx ON movd.aplan USING btree (origine);


--
-- Name: aplan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX aplan_t_basket_idx ON movd.aplan USING btree (t_basket);


--
-- Name: arete_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX arete_geometrie_idx ON movd.arete USING gist (geometrie);


--
-- Name: arete_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX arete_origine_idx ON movd.arete USING btree (origine);


--
-- Name: arete_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX arete_t_basket_idx ON movd.arete USING btree (t_basket);


--
-- Name: asignal_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX asignal_geometrie_idx ON movd.asignal USING gist (geometrie);


--
-- Name: asignal_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX asignal_origine_idx ON movd.asignal USING btree (origine);


--
-- Name: asignal_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX asignal_t_basket_idx ON movd.asignal USING btree (t_basket);


--
-- Name: bien_fonds_bien_fonds_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bien_fonds_bien_fonds_de_idx ON movd.bien_fonds USING btree (bien_fonds_de);


--
-- Name: bien_fonds_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bien_fonds_geometrie_idx ON movd.bien_fonds USING gist (geometrie);


--
-- Name: bien_fonds_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bien_fonds_t_basket_idx ON movd.bien_fonds USING btree (t_basket);


--
-- Name: bien_fondsproj_bien_fondsproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bien_fondsproj_bien_fondsproj_de_idx ON movd.bien_fondsproj USING btree (bien_fondsproj_de);


--
-- Name: bien_fondsproj_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bien_fondsproj_geometrie_idx ON movd.bien_fondsproj USING gist (geometrie);


--
-- Name: bien_fondsproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bien_fondsproj_t_basket_idx ON movd.bien_fondsproj USING btree (t_basket);


--
-- Name: bord_de_plan_origine_plan_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bord_de_plan_origine_plan_idx ON movd.bord_de_plan USING gist (origine_plan);


--
-- Name: bord_de_plan_origine_plan_synoptique_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bord_de_plan_origine_plan_synoptique_idx ON movd.bord_de_plan USING gist (origine_plan_synoptique);


--
-- Name: bord_de_plan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX bord_de_plan_t_basket_idx ON movd.bord_de_plan USING btree (t_basket);


--
-- Name: commune_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX commune_t_basket_idx ON movd.commune USING btree (t_basket);


--
-- Name: croix_filet_croix_filet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX croix_filet_croix_filet_de_idx ON movd.croix_filet USING btree (croix_filet_de);


--
-- Name: croix_filet_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX croix_filet_pos_idx ON movd.croix_filet USING gist (pos);


--
-- Name: croix_filet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX croix_filet_t_basket_idx ON movd.croix_filet USING btree (t_basket);


--
-- Name: ddp_ddp_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ddp_ddp_de_idx ON movd.ddp USING btree (ddp_de);


--
-- Name: ddp_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ddp_geometrie_idx ON movd.ddp USING gist (geometrie);


--
-- Name: ddp_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ddp_t_basket_idx ON movd.ddp USING btree (t_basket);


--
-- Name: ddpproj_ddpproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ddpproj_ddpproj_de_idx ON movd.ddpproj USING btree (ddpproj_de);


--
-- Name: ddpproj_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ddpproj_geometrie_idx ON movd.ddpproj USING gist (geometrie);


--
-- Name: ddpproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ddpproj_t_basket_idx ON movd.ddpproj USING btree (t_basket);


--
-- Name: description_batiment_description_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX description_batiment_description_batiment_de_idx ON movd.description_batiment USING btree (description_batiment_de);


--
-- Name: description_batiment_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX description_batiment_t_basket_idx ON movd.description_batiment USING btree (t_basket);


--
-- Name: description_plan_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX description_plan_origine_idx ON movd.description_plan USING btree (origine);


--
-- Name: description_plan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX description_plan_t_basket_idx ON movd.description_plan USING btree (t_basket);


--
-- Name: domaine_numerotation_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX domaine_numerotation_t_basket_idx ON movd.domaine_numerotation USING btree (t_basket);


--
-- Name: element_conduite_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_conduite_origine_idx ON movd.element_conduite USING btree (origine);


--
-- Name: element_conduite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_conduite_t_basket_idx ON movd.element_conduite USING btree (t_basket);


--
-- Name: element_lineaire_element_lineaire_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_lineaire_element_lineaire_de_idx ON movd.element_lineaire USING btree (element_lineaire_de);


--
-- Name: element_lineaire_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_lineaire_geometrie_idx ON movd.element_lineaire USING gist (geometrie);


--
-- Name: element_lineaire_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_lineaire_t_basket_idx ON movd.element_lineaire USING btree (t_basket);


--
-- Name: element_ponctuel_element_ponctuel_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_ponctuel_element_ponctuel_de_idx ON movd.element_ponctuel USING btree (element_ponctuel_de);


--
-- Name: element_ponctuel_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_ponctuel_geometrie_idx ON movd.element_ponctuel USING gist (geometrie);


--
-- Name: element_ponctuel_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_ponctuel_t_basket_idx ON movd.element_ponctuel USING btree (t_basket);


--
-- Name: element_surfacique_element_surfacique_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_surfacique_element_surfacique_de_idx ON movd.element_surfacique USING btree (element_surfacique_de);


--
-- Name: element_surfacique_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_surfacique_geometrie_idx ON movd.element_surfacique USING gist (geometrie);


--
-- Name: element_surfacique_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX element_surfacique_t_basket_idx ON movd.element_surfacique USING btree (t_basket);


--
-- Name: entree_batiment_entree_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX entree_batiment_entree_batiment_de_idx ON movd.entree_batiment USING btree (entree_batiment_de);


--
-- Name: entree_batiment_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX entree_batiment_origine_idx ON movd.entree_batiment USING btree (origine);


--
-- Name: entree_batiment_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX entree_batiment_pos_idx ON movd.entree_batiment USING gist (pos);


--
-- Name: entree_batiment_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX entree_batiment_t_basket_idx ON movd.entree_batiment USING btree (t_basket);


--
-- Name: geometrie_plan_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX geometrie_plan_geometrie_idx ON movd.geometrie_plan USING gist (geometrie);


--
-- Name: geometrie_plan_geometrie_plan_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX geometrie_plan_geometrie_plan_de_idx ON movd.geometrie_plan USING btree (geometrie_plan_de);


--
-- Name: geometrie_plan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX geometrie_plan_t_basket_idx ON movd.geometrie_plan USING btree (t_basket);


--
-- Name: geometriedn_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX geometriedn_geometrie_idx ON movd.geometriedn USING gist (geometrie);


--
-- Name: geometriedn_geometriedn_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX geometriedn_geometriedn_de_idx ON movd.geometriedn USING btree (geometriedn_de);


--
-- Name: geometriedn_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX geometriedn_t_basket_idx ON movd.geometriedn USING btree (t_basket);


--
-- Name: glissement_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX glissement_geometrie_idx ON movd.glissement USING gist (geometrie);


--
-- Name: glissement_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX glissement_t_basket_idx ON movd.glissement USING btree (t_basket);


--
-- Name: groupement_de_localite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX groupement_de_localite_t_basket_idx ON movd.groupement_de_localite USING btree (t_basket);


--
-- Name: immeuble_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX immeuble_origine_idx ON movd.immeuble USING btree (origine);


--
-- Name: immeuble_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX immeuble_t_basket_idx ON movd.immeuble USING btree (t_basket);


--
-- Name: immeubleproj_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX immeubleproj_origine_idx ON movd.immeubleproj USING btree (origine);


--
-- Name: immeubleproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX immeubleproj_t_basket_idx ON movd.immeubleproj USING btree (t_basket);


--
-- Name: indication_coordonnees_indication_coordonnees_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX indication_coordonnees_indication_coordonnees_de_idx ON movd.indication_coordonnees USING btree (indication_coordonnees_de);


--
-- Name: indication_coordonnees_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX indication_coordonnees_t_basket_idx ON movd.indication_coordonnees USING btree (t_basket);


--
-- Name: lieu_denomme_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX lieu_denomme_geometrie_idx ON movd.lieu_denomme USING gist (geometrie);


--
-- Name: lieu_denomme_lieu_denomme_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX lieu_denomme_lieu_denomme_de_idx ON movd.lieu_denomme USING btree (lieu_denomme_de);


--
-- Name: lieu_denomme_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX lieu_denomme_t_basket_idx ON movd.lieu_denomme USING btree (t_basket);


--
-- Name: lieudit_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX lieudit_origine_idx ON movd.lieudit USING btree (origine);


--
-- Name: lieudit_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX lieudit_t_basket_idx ON movd.lieudit USING btree (t_basket);


--
-- Name: ligne_coordonnees_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ligne_coordonnees_geometrie_idx ON movd.ligne_coordonnees USING gist (geometrie);


--
-- Name: ligne_coordonnees_ligne_coordonnees_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ligne_coordonnees_ligne_coordonnees_de_idx ON movd.ligne_coordonnees USING btree (ligne_coordonnees_de);


--
-- Name: ligne_coordonnees_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX ligne_coordonnees_t_basket_idx ON movd.ligne_coordonnees USING btree (t_basket);


--
-- Name: limite_commune_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_commune_geometrie_idx ON movd.limite_commune USING gist (geometrie);


--
-- Name: limite_commune_limite_commune_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_commune_limite_commune_de_idx ON movd.limite_commune USING btree (limite_commune_de);


--
-- Name: limite_commune_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_commune_origine_idx ON movd.limite_commune USING btree (origine);


--
-- Name: limite_commune_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_commune_t_basket_idx ON movd.limite_commune USING btree (t_basket);


--
-- Name: limite_communeproj_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_communeproj_geometrie_idx ON movd.limite_communeproj USING gist (geometrie);


--
-- Name: limite_communeproj_limite_communeproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_communeproj_limite_communeproj_de_idx ON movd.limite_communeproj USING btree (limite_communeproj_de);


--
-- Name: limite_communeproj_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_communeproj_origine_idx ON movd.limite_communeproj USING btree (origine);


--
-- Name: limite_communeproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX limite_communeproj_t_basket_idx ON movd.limite_communeproj USING btree (t_basket);


--
-- Name: localisation_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX localisation_origine_idx ON movd.localisation USING btree (origine);


--
-- Name: localisation_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX localisation_t_basket_idx ON movd.localisation USING btree (t_basket);


--
-- Name: localite_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX localite_geometrie_idx ON movd.localite USING gist (geometrie);


--
-- Name: localite_localite_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX localite_localite_de_idx ON movd.localite USING btree (localite_de);


--
-- Name: localite_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX localite_origine_idx ON movd.localite USING btree (origine);


--
-- Name: localite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX localite_t_basket_idx ON movd.localite USING btree (t_basket);


--
-- Name: md01mvdmn95v2_dvrs_nm_bjet_nom_objet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_dvrs_nm_bjet_nom_objet_de_idx ON movd.md01mvdmn95v24objets_divers_nom_objet USING btree (nom_objet_de);


--
-- Name: md01mvdmn95v2_dvrs_nm_bjet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_dvrs_nm_bjet_t_basket_idx ON movd.md01mvdmn95v24objets_divers_nom_objet USING btree (t_basket);


--
-- Name: md01mvdmn95v2_lmnt_pnctuel_element_ponctuel_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_lmnt_pnctuel_element_ponctuel_de_idx ON movd.md01mvdmn95v24conduites_element_ponctuel USING btree (element_ponctuel_de);


--
-- Name: md01mvdmn95v2_lmnt_pnctuel_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_lmnt_pnctuel_geometrie_idx ON movd.md01mvdmn95v24conduites_element_ponctuel USING gist (geometrie);


--
-- Name: md01mvdmn95v2_lmnt_pnctuel_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_lmnt_pnctuel_t_basket_idx ON movd.md01mvdmn95v24conduites_element_ponctuel USING btree (t_basket);


--
-- Name: md01mvdmn95v2_lmnt_srfcque_element_surfacique_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_lmnt_srfcque_element_surfacique_de_idx ON movd.md01mvdmn95v24conduites_element_surfacique USING btree (element_surfacique_de);


--
-- Name: md01mvdmn95v2_lmnt_srfcque_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_lmnt_srfcque_geometrie_idx ON movd.md01mvdmn95v24conduites_element_surfacique USING gist (geometrie);


--
-- Name: md01mvdmn95v2_lmnt_srfcque_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_lmnt_srfcque_t_basket_idx ON movd.md01mvdmn95v24conduites_element_surfacique USING btree (t_basket);


--
-- Name: md01mvdmn95v2_pnt_prtclier_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_pnt_prtclier_geometrie_idx ON movd.md01mvdmn95v24objets_divers_point_particulier USING gist (geometrie);


--
-- Name: md01mvdmn95v2_pnt_prtclier_geometrie_idx1; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_pnt_prtclier_geometrie_idx1 ON movd.md01mvdmn95v24conduites_point_particulier USING gist (geometrie);


--
-- Name: md01mvdmn95v2_pnt_prtclier_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_pnt_prtclier_origine_idx ON movd.md01mvdmn95v24objets_divers_point_particulier USING btree (origine);


--
-- Name: md01mvdmn95v2_pnt_prtclier_origine_idx1; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_pnt_prtclier_origine_idx1 ON movd.md01mvdmn95v24conduites_point_particulier USING btree (origine);


--
-- Name: md01mvdmn95v2_pnt_prtclier_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_pnt_prtclier_t_basket_idx ON movd.md01mvdmn95v24objets_divers_point_particulier USING btree (t_basket);


--
-- Name: md01mvdmn95v2_pnt_prtclier_t_basket_idx1; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2_pnt_prtclier_t_basket_idx1 ON movd.md01mvdmn95v24conduites_point_particulier USING btree (t_basket);


--
-- Name: md01mvdmn95v2ln_lmnt_lnire_element_lineaire_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2ln_lmnt_lnire_element_lineaire_de_idx ON movd.md01mvdmn95v24bords_de_plan_element_lineaire USING btree (element_lineaire_de);


--
-- Name: md01mvdmn95v2ln_lmnt_lnire_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2ln_lmnt_lnire_geometrie_idx ON movd.md01mvdmn95v24bords_de_plan_element_lineaire USING gist (geometrie);


--
-- Name: md01mvdmn95v2ln_lmnt_lnire_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2ln_lmnt_lnire_t_basket_idx ON movd.md01mvdmn95v24bords_de_plan_element_lineaire USING btree (t_basket);


--
-- Name: md01mvdmn95v2spnt_prtclier_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2spnt_prtclier_pos_idx ON movd.md01mvdmn95v24objets_divers_pospoint_particulier USING gist (pos);


--
-- Name: md01mvdmn95v2spnt_prtclier_pos_idx1; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2spnt_prtclier_pos_idx1 ON movd.md01mvdmn95v24conduites_pospoint_particulier USING gist (pos);


--
-- Name: md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_idx ON movd.md01mvdmn95v24objets_divers_pospoint_particulier USING btree (pospoint_particulier_de);


--
-- Name: md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_idx1; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_idx1 ON movd.md01mvdmn95v24conduites_pospoint_particulier USING btree (pospoint_particulier_de);


--
-- Name: md01mvdmn95v2spnt_prtclier_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2spnt_prtclier_t_basket_idx ON movd.md01mvdmn95v24objets_divers_pospoint_particulier USING btree (t_basket);


--
-- Name: md01mvdmn95v2spnt_prtclier_t_basket_idx1; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2spnt_prtclier_t_basket_idx1 ON movd.md01mvdmn95v24conduites_pospoint_particulier USING btree (t_basket);


--
-- Name: md01mvdmn95v2ts_lmnt_lnire_element_lineaire_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2ts_lmnt_lnire_element_lineaire_de_idx ON movd.md01mvdmn95v24conduites_element_lineaire USING btree (element_lineaire_de);


--
-- Name: md01mvdmn95v2ts_lmnt_lnire_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2ts_lmnt_lnire_geometrie_idx ON movd.md01mvdmn95v24conduites_element_lineaire USING gist (geometrie);


--
-- Name: md01mvdmn95v2ts_lmnt_lnire_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2ts_lmnt_lnire_t_basket_idx ON movd.md01mvdmn95v24conduites_element_lineaire USING btree (t_basket);


--
-- Name: md01mvdmn95v2vrs_psnm_bjet_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2vrs_psnm_bjet_pos_idx ON movd.md01mvdmn95v24objets_divers_posnom_objet USING gist (pos);


--
-- Name: md01mvdmn95v2vrs_psnm_bjet_posnom_objet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2vrs_psnm_bjet_posnom_objet_de_idx ON movd.md01mvdmn95v24objets_divers_posnom_objet USING btree (posnom_objet_de);


--
-- Name: md01mvdmn95v2vrs_psnm_bjet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX md01mvdmn95v2vrs_psnm_bjet_t_basket_idx ON movd.md01mvdmn95v24objets_divers_posnom_objet USING btree (t_basket);


--
-- Name: mine_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mine_geometrie_idx ON movd.mine USING gist (geometrie);


--
-- Name: mine_mine_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mine_mine_de_idx ON movd.mine USING btree (mine_de);


--
-- Name: mine_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mine_t_basket_idx ON movd.mine USING btree (t_basket);


--
-- Name: mineproj_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mineproj_geometrie_idx ON movd.mineproj USING gist (geometrie);


--
-- Name: mineproj_mineproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mineproj_mineproj_de_idx ON movd.mineproj USING btree (mineproj_de);


--
-- Name: mineproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mineproj_t_basket_idx ON movd.mineproj USING btree (t_basket);


--
-- Name: mise_a_joural_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_joural_perimetre_idx ON movd.mise_a_joural USING gist (perimetre);


--
-- Name: mise_a_joural_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_joural_t_basket_idx ON movd.mise_a_joural USING btree (t_basket);


--
-- Name: mise_a_jourbat_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourbat_perimetre_idx ON movd.mise_a_jourbat USING gist (perimetre);


--
-- Name: mise_a_jourbat_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourbat_t_basket_idx ON movd.mise_a_jourbat USING btree (t_basket);


--
-- Name: mise_a_jourbf_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourbf_perimetre_idx ON movd.mise_a_jourbf USING gist (perimetre);


--
-- Name: mise_a_jourbf_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourbf_t_basket_idx ON movd.mise_a_jourbf USING btree (t_basket);


--
-- Name: mise_a_jourco_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourco_perimetre_idx ON movd.mise_a_jourco USING gist (perimetre);


--
-- Name: mise_a_jourco_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourco_t_basket_idx ON movd.mise_a_jourco USING btree (t_basket);


--
-- Name: mise_a_jourcom_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourcom_perimetre_idx ON movd.mise_a_jourcom USING gist (perimetre);


--
-- Name: mise_a_jourcom_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourcom_t_basket_idx ON movd.mise_a_jourcom USING btree (t_basket);


--
-- Name: mise_a_jourcs_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourcs_perimetre_idx ON movd.mise_a_jourcs USING gist (perimetre);


--
-- Name: mise_a_jourcs_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourcs_t_basket_idx ON movd.mise_a_jourcs USING btree (t_basket);


--
-- Name: mise_a_jourloc_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourloc_perimetre_idx ON movd.mise_a_jourloc USING gist (perimetre);


--
-- Name: mise_a_jourloc_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourloc_t_basket_idx ON movd.mise_a_jourloc USING btree (t_basket);


--
-- Name: mise_a_journo_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_journo_perimetre_idx ON movd.mise_a_journo USING gist (perimetre);


--
-- Name: mise_a_journo_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_journo_t_basket_idx ON movd.mise_a_journo USING btree (t_basket);


--
-- Name: mise_a_journpa6_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_journpa6_perimetre_idx ON movd.mise_a_journpa6 USING gist (perimetre);


--
-- Name: mise_a_journpa6_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_journpa6_t_basket_idx ON movd.mise_a_journpa6 USING btree (t_basket);


--
-- Name: mise_a_jourod_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourod_perimetre_idx ON movd.mise_a_jourod USING gist (perimetre);


--
-- Name: mise_a_jourod_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourod_t_basket_idx ON movd.mise_a_jourod USING btree (t_basket);


--
-- Name: mise_a_jourpfa1_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfa1_perimetre_idx ON movd.mise_a_jourpfa1 USING gist (perimetre);


--
-- Name: mise_a_jourpfa1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfa1_t_basket_idx ON movd.mise_a_jourpfa1 USING btree (t_basket);


--
-- Name: mise_a_jourpfa2_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfa2_perimetre_idx ON movd.mise_a_jourpfa2 USING gist (perimetre);


--
-- Name: mise_a_jourpfa2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfa2_t_basket_idx ON movd.mise_a_jourpfa2 USING btree (t_basket);


--
-- Name: mise_a_jourpfa3_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfa3_perimetre_idx ON movd.mise_a_jourpfa3 USING gist (perimetre);


--
-- Name: mise_a_jourpfa3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfa3_t_basket_idx ON movd.mise_a_jourpfa3 USING btree (t_basket);


--
-- Name: mise_a_jourpfp1_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfp1_perimetre_idx ON movd.mise_a_jourpfp1 USING gist (perimetre);


--
-- Name: mise_a_jourpfp1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfp1_t_basket_idx ON movd.mise_a_jourpfp1 USING btree (t_basket);


--
-- Name: mise_a_jourpfp2_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfp2_perimetre_idx ON movd.mise_a_jourpfp2 USING gist (perimetre);


--
-- Name: mise_a_jourpfp2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfp2_t_basket_idx ON movd.mise_a_jourpfp2 USING btree (t_basket);


--
-- Name: mise_a_jourpfp3_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfp3_perimetre_idx ON movd.mise_a_jourpfp3 USING gist (perimetre);


--
-- Name: mise_a_jourpfp3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourpfp3_t_basket_idx ON movd.mise_a_jourpfp3 USING btree (t_basket);


--
-- Name: mise_a_jourrp_perimetre_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourrp_perimetre_idx ON movd.mise_a_jourrp USING gist (perimetre);


--
-- Name: mise_a_jourrp_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX mise_a_jourrp_t_basket_idx ON movd.mise_a_jourrp USING btree (t_basket);


--
-- Name: niveau_tolerance_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX niveau_tolerance_geometrie_idx ON movd.niveau_tolerance USING gist (geometrie);


--
-- Name: niveau_tolerance_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX niveau_tolerance_t_basket_idx ON movd.niveau_tolerance USING btree (t_basket);


--
-- Name: nom_batiment_nom_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_batiment_nom_batiment_de_idx ON movd.nom_batiment USING btree (nom_batiment_de);


--
-- Name: nom_batiment_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_batiment_t_basket_idx ON movd.nom_batiment USING btree (t_basket);


--
-- Name: nom_de_lieu_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_de_lieu_geometrie_idx ON movd.nom_de_lieu USING gist (geometrie);


--
-- Name: nom_de_lieu_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_de_lieu_origine_idx ON movd.nom_de_lieu USING btree (origine);


--
-- Name: nom_de_lieu_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_de_lieu_t_basket_idx ON movd.nom_de_lieu USING btree (t_basket);


--
-- Name: nom_local_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_local_geometrie_idx ON movd.nom_local USING gist (geometrie);


--
-- Name: nom_local_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_local_origine_idx ON movd.nom_local USING btree (origine);


--
-- Name: nom_local_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_local_t_basket_idx ON movd.nom_local USING btree (t_basket);


--
-- Name: nom_localisation_nom_localisation_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_localisation_nom_localisation_de_idx ON movd.nom_localisation USING btree (nom_localisation_de);


--
-- Name: nom_localisation_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_localisation_t_basket_idx ON movd.nom_localisation USING btree (t_basket);


--
-- Name: nom_localite_nom_localite_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_localite_nom_localite_de_idx ON movd.nom_localite USING btree (nom_localite_de);


--
-- Name: nom_localite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_localite_t_basket_idx ON movd.nom_localite USING btree (t_basket);


--
-- Name: nom_objet_nom_objet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_objet_nom_objet_de_idx ON movd.nom_objet USING btree (nom_objet_de);


--
-- Name: nom_objet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nom_objet_t_basket_idx ON movd.nom_objet USING btree (t_basket);


--
-- Name: nomobjetproj_nomobjetproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nomobjetproj_nomobjetproj_de_idx ON movd.nomobjetproj USING btree (nomobjetproj_de);


--
-- Name: nomobjetproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX nomobjetproj_t_basket_idx ON movd.nomobjetproj USING btree (t_basket);


--
-- Name: npa6_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX npa6_geometrie_idx ON movd.npa6 USING gist (geometrie);


--
-- Name: npa6_npa6_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX npa6_npa6_de_idx ON movd.npa6 USING btree (npa6_de);


--
-- Name: npa6_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX npa6_origine_idx ON movd.npa6 USING btree (origine);


--
-- Name: npa6_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX npa6_t_basket_idx ON movd.npa6 USING btree (t_basket);


--
-- Name: numero_de_batiment_numero_de_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX numero_de_batiment_numero_de_batiment_de_idx ON movd.numero_de_batiment USING btree (numero_de_batiment_de);


--
-- Name: numero_de_batiment_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX numero_de_batiment_t_basket_idx ON movd.numero_de_batiment USING btree (t_basket);


--
-- Name: numero_objet_numero_objet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX numero_objet_numero_objet_de_idx ON movd.numero_objet USING btree (numero_objet_de);


--
-- Name: numero_objet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX numero_objet_t_basket_idx ON movd.numero_objet USING btree (t_basket);


--
-- Name: numerobatimentproj_numerobatimentproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX numerobatimentproj_numerobatimentproj_de_idx ON movd.numerobatimentproj USING btree (numerobatimentproj_de);


--
-- Name: numerobatimentproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX numerobatimentproj_t_basket_idx ON movd.numerobatimentproj USING btree (t_basket);


--
-- Name: objet_divers_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX objet_divers_origine_idx ON movd.objet_divers USING btree (origine);


--
-- Name: objet_divers_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX objet_divers_t_basket_idx ON movd.objet_divers USING btree (t_basket);


--
-- Name: partie_limite_canton_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX partie_limite_canton_geometrie_idx ON movd.partie_limite_canton USING gist (geometrie);


--
-- Name: partie_limite_canton_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX partie_limite_canton_t_basket_idx ON movd.partie_limite_canton USING btree (t_basket);


--
-- Name: partie_limite_district_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX partie_limite_district_geometrie_idx ON movd.partie_limite_district USING gist (geometrie);


--
-- Name: partie_limite_district_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX partie_limite_district_t_basket_idx ON movd.partie_limite_district USING btree (t_basket);


--
-- Name: partie_limite_nationale_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX partie_limite_nationale_geometrie_idx ON movd.partie_limite_nationale USING gist (geometrie);


--
-- Name: partie_limite_nationale_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX partie_limite_nationale_t_basket_idx ON movd.partie_limite_nationale USING btree (t_basket);


--
-- Name: pfa1_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa1_geometrie_idx ON movd.pfa1 USING gist (geometrie);


--
-- Name: pfa1_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa1_origine_idx ON movd.pfa1 USING btree (origine);


--
-- Name: pfa1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa1_t_basket_idx ON movd.pfa1 USING btree (t_basket);


--
-- Name: pfa2_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa2_geometrie_idx ON movd.pfa2 USING gist (geometrie);


--
-- Name: pfa2_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa2_origine_idx ON movd.pfa2 USING btree (origine);


--
-- Name: pfa2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa2_t_basket_idx ON movd.pfa2 USING btree (t_basket);


--
-- Name: pfa3_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa3_geometrie_idx ON movd.pfa3 USING gist (geometrie);


--
-- Name: pfa3_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa3_origine_idx ON movd.pfa3 USING btree (origine);


--
-- Name: pfa3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfa3_t_basket_idx ON movd.pfa3 USING btree (t_basket);


--
-- Name: pfp1_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp1_geometrie_idx ON movd.pfp1 USING gist (geometrie);


--
-- Name: pfp1_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp1_origine_idx ON movd.pfp1 USING btree (origine);


--
-- Name: pfp1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp1_t_basket_idx ON movd.pfp1 USING btree (t_basket);


--
-- Name: pfp2_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp2_geometrie_idx ON movd.pfp2 USING gist (geometrie);


--
-- Name: pfp2_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp2_origine_idx ON movd.pfp2 USING btree (origine);


--
-- Name: pfp2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp2_t_basket_idx ON movd.pfp2 USING btree (t_basket);


--
-- Name: pfp3_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp3_geometrie_idx ON movd.pfp3 USING gist (geometrie);


--
-- Name: pfp3_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp3_origine_idx ON movd.pfp3 USING btree (origine);


--
-- Name: pfp3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pfp3_t_basket_idx ON movd.pfp3 USING btree (t_basket);


--
-- Name: point_cote_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_cote_geometrie_idx ON movd.point_cote USING gist (geometrie);


--
-- Name: point_cote_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_cote_origine_idx ON movd.point_cote USING btree (origine);


--
-- Name: point_cote_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_cote_t_basket_idx ON movd.point_cote USING btree (t_basket);


--
-- Name: point_limite_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_limite_geometrie_idx ON movd.point_limite USING gist (geometrie);


--
-- Name: point_limite_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_limite_origine_idx ON movd.point_limite USING btree (origine);


--
-- Name: point_limite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_limite_t_basket_idx ON movd.point_limite USING btree (t_basket);


--
-- Name: point_limite_ter_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_limite_ter_geometrie_idx ON movd.point_limite_ter USING gist (geometrie);


--
-- Name: point_limite_ter_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_limite_ter_origine_idx ON movd.point_limite_ter USING btree (origine);


--
-- Name: point_limite_ter_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_limite_ter_t_basket_idx ON movd.point_limite_ter USING btree (t_basket);


--
-- Name: point_particulier_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_particulier_geometrie_idx ON movd.point_particulier USING gist (geometrie);


--
-- Name: point_particulier_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_particulier_origine_idx ON movd.point_particulier USING btree (origine);


--
-- Name: point_particulier_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX point_particulier_t_basket_idx ON movd.point_particulier USING btree (t_basket);


--
-- Name: posdescription_plan_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posdescription_plan_pos_idx ON movd.posdescription_plan USING gist (pos);


--
-- Name: posdescription_plan_posdescription_plan_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posdescription_plan_posdescription_plan_de_idx ON movd.posdescription_plan USING btree (posdescription_plan_de);


--
-- Name: posdescription_plan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posdescription_plan_t_basket_idx ON movd.posdescription_plan USING btree (t_basket);


--
-- Name: posdomaine_numerotation_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posdomaine_numerotation_pos_idx ON movd.posdomaine_numerotation USING gist (pos);


--
-- Name: posdomaine_numerotation_posdomaine_numerotation_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posdomaine_numerotation_posdomaine_numerotation_de_idx ON movd.posdomaine_numerotation USING btree (posdomaine_numerotation_de);


--
-- Name: posdomaine_numerotation_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posdomaine_numerotation_t_basket_idx ON movd.posdomaine_numerotation USING btree (t_basket);


--
-- Name: poselement_conduite_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX poselement_conduite_pos_idx ON movd.poselement_conduite USING gist (pos);


--
-- Name: poselement_conduite_poselement_conduite_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX poselement_conduite_poselement_conduite_de_idx ON movd.poselement_conduite USING btree (poselement_conduite_de);


--
-- Name: poselement_conduite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX poselement_conduite_t_basket_idx ON movd.poselement_conduite USING btree (t_basket);


--
-- Name: posglissement_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posglissement_pos_idx ON movd.posglissement USING gist (pos);


--
-- Name: posglissement_posglissement_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posglissement_posglissement_de_idx ON movd.posglissement USING btree (posglissement_de);


--
-- Name: posglissement_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posglissement_t_basket_idx ON movd.posglissement USING btree (t_basket);


--
-- Name: posimmeuble_ligne_auxiliaire_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeuble_ligne_auxiliaire_idx ON movd.posimmeuble USING gist (ligne_auxiliaire);


--
-- Name: posimmeuble_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeuble_pos_idx ON movd.posimmeuble USING gist (pos);


--
-- Name: posimmeuble_posimmeuble_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeuble_posimmeuble_de_idx ON movd.posimmeuble USING btree (posimmeuble_de);


--
-- Name: posimmeuble_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeuble_t_basket_idx ON movd.posimmeuble USING btree (t_basket);


--
-- Name: posimmeubleproj_ligne_auxiliaire_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeubleproj_ligne_auxiliaire_idx ON movd.posimmeubleproj USING gist (ligne_auxiliaire);


--
-- Name: posimmeubleproj_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeubleproj_pos_idx ON movd.posimmeubleproj USING gist (pos);


--
-- Name: posimmeubleproj_posimmeubleproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeubleproj_posimmeubleproj_de_idx ON movd.posimmeubleproj USING btree (posimmeubleproj_de);


--
-- Name: posimmeubleproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posimmeubleproj_t_basket_idx ON movd.posimmeubleproj USING btree (t_basket);


--
-- Name: posindication_coord_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posindication_coord_pos_idx ON movd.posindication_coord USING gist (pos);


--
-- Name: posindication_coord_posindication_coord_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posindication_coord_posindication_coord_de_idx ON movd.posindication_coord USING btree (posindication_coord_de);


--
-- Name: posindication_coord_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posindication_coord_t_basket_idx ON movd.posindication_coord USING btree (t_basket);


--
-- Name: poslieudit_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX poslieudit_pos_idx ON movd.poslieudit USING gist (pos);


--
-- Name: poslieudit_poslieudit_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX poslieudit_poslieudit_de_idx ON movd.poslieudit USING btree (poslieudit_de);


--
-- Name: poslieudit_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX poslieudit_t_basket_idx ON movd.poslieudit USING btree (t_basket);


--
-- Name: posniveau_tolerance_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posniveau_tolerance_pos_idx ON movd.posniveau_tolerance USING gist (pos);


--
-- Name: posniveau_tolerance_posniveau_tolerance_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posniveau_tolerance_posniveau_tolerance_de_idx ON movd.posniveau_tolerance USING btree (posniveau_tolerance_de);


--
-- Name: posniveau_tolerance_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posniveau_tolerance_t_basket_idx ON movd.posniveau_tolerance USING btree (t_basket);


--
-- Name: posnom_batiment_ligne_auxiliaire_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_batiment_ligne_auxiliaire_idx ON movd.posnom_batiment USING gist (ligne_auxiliaire);


--
-- Name: posnom_batiment_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_batiment_pos_idx ON movd.posnom_batiment USING gist (pos);


--
-- Name: posnom_batiment_posnom_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_batiment_posnom_batiment_de_idx ON movd.posnom_batiment USING btree (posnom_batiment_de);


--
-- Name: posnom_batiment_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_batiment_t_basket_idx ON movd.posnom_batiment USING btree (t_basket);


--
-- Name: posnom_de_lieu_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_de_lieu_pos_idx ON movd.posnom_de_lieu USING gist (pos);


--
-- Name: posnom_de_lieu_posnom_de_lieu_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_de_lieu_posnom_de_lieu_de_idx ON movd.posnom_de_lieu USING btree (posnom_de_lieu_de);


--
-- Name: posnom_de_lieu_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_de_lieu_t_basket_idx ON movd.posnom_de_lieu USING btree (t_basket);


--
-- Name: posnom_local_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_local_pos_idx ON movd.posnom_local USING gist (pos);


--
-- Name: posnom_local_posnom_local_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_local_posnom_local_de_idx ON movd.posnom_local USING btree (posnom_local_de);


--
-- Name: posnom_local_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_local_t_basket_idx ON movd.posnom_local USING btree (t_basket);


--
-- Name: posnom_localisation_ligne_auxiliaire_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localisation_ligne_auxiliaire_idx ON movd.posnom_localisation USING gist (ligne_auxiliaire);


--
-- Name: posnom_localisation_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localisation_pos_idx ON movd.posnom_localisation USING gist (pos);


--
-- Name: posnom_localisation_posnom_localisation_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localisation_posnom_localisation_de_idx ON movd.posnom_localisation USING btree (posnom_localisation_de);


--
-- Name: posnom_localisation_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localisation_t_basket_idx ON movd.posnom_localisation USING btree (t_basket);


--
-- Name: posnom_localite_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localite_pos_idx ON movd.posnom_localite USING gist (pos);


--
-- Name: posnom_localite_posnom_localite_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localite_posnom_localite_de_idx ON movd.posnom_localite USING btree (posnom_localite_de);


--
-- Name: posnom_localite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_localite_t_basket_idx ON movd.posnom_localite USING btree (t_basket);


--
-- Name: posnom_objet_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_objet_pos_idx ON movd.posnom_objet USING gist (pos);


--
-- Name: posnom_objet_posnom_objet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_objet_posnom_objet_de_idx ON movd.posnom_objet USING btree (posnom_objet_de);


--
-- Name: posnom_objet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnom_objet_t_basket_idx ON movd.posnom_objet USING btree (t_basket);


--
-- Name: posnomobjetproj_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnomobjetproj_pos_idx ON movd.posnomobjetproj USING gist (pos);


--
-- Name: posnomobjetproj_posnomobjetproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnomobjetproj_posnomobjetproj_de_idx ON movd.posnomobjetproj USING btree (posnomobjetproj_de);


--
-- Name: posnomobjetproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnomobjetproj_t_basket_idx ON movd.posnomobjetproj USING btree (t_basket);


--
-- Name: posnumero_de_batiment_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_de_batiment_pos_idx ON movd.posnumero_de_batiment USING gist (pos);


--
-- Name: posnumero_de_batiment_posnumero_de_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_de_batiment_posnumero_de_batiment_de_idx ON movd.posnumero_de_batiment USING btree (posnumero_de_batiment_de);


--
-- Name: posnumero_de_batiment_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_de_batiment_t_basket_idx ON movd.posnumero_de_batiment USING btree (t_basket);


--
-- Name: posnumero_maison_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_maison_pos_idx ON movd.posnumero_maison USING gist (pos);


--
-- Name: posnumero_maison_posnumero_batiment_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_maison_posnumero_batiment_de_idx ON movd.posnumero_maison USING btree (posnumero_batiment_de);


--
-- Name: posnumero_maison_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_maison_t_basket_idx ON movd.posnumero_maison USING btree (t_basket);


--
-- Name: posnumero_objet_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_objet_pos_idx ON movd.posnumero_objet USING gist (pos);


--
-- Name: posnumero_objet_posnumero_objet_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_objet_posnumero_objet_de_idx ON movd.posnumero_objet USING btree (posnumero_objet_de);


--
-- Name: posnumero_objet_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumero_objet_t_basket_idx ON movd.posnumero_objet USING btree (t_basket);


--
-- Name: posnumerobatimentproj_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumerobatimentproj_pos_idx ON movd.posnumerobatimentproj USING gist (pos);


--
-- Name: posnumerobatimentproj_posnumerobatimentproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumerobatimentproj_posnumerobatimentproj_de_idx ON movd.posnumerobatimentproj USING btree (posnumerobatimentproj_de);


--
-- Name: posnumerobatimentproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posnumerobatimentproj_t_basket_idx ON movd.posnumerobatimentproj USING btree (t_basket);


--
-- Name: pospfa1_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa1_pos_idx ON movd.pospfa1 USING gist (pos);


--
-- Name: pospfa1_pospfa1_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa1_pospfa1_de_idx ON movd.pospfa1 USING btree (pospfa1_de);


--
-- Name: pospfa1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa1_t_basket_idx ON movd.pospfa1 USING btree (t_basket);


--
-- Name: pospfa2_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa2_pos_idx ON movd.pospfa2 USING gist (pos);


--
-- Name: pospfa2_pospfa2_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa2_pospfa2_de_idx ON movd.pospfa2 USING btree (pospfa2_de);


--
-- Name: pospfa2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa2_t_basket_idx ON movd.pospfa2 USING btree (t_basket);


--
-- Name: pospfa3_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa3_pos_idx ON movd.pospfa3 USING gist (pos);


--
-- Name: pospfa3_pospfa3_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa3_pospfa3_de_idx ON movd.pospfa3 USING btree (pospfa3_de);


--
-- Name: pospfa3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfa3_t_basket_idx ON movd.pospfa3 USING btree (t_basket);


--
-- Name: pospfp1_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp1_pos_idx ON movd.pospfp1 USING gist (pos);


--
-- Name: pospfp1_pospfp1_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp1_pospfp1_de_idx ON movd.pospfp1 USING btree (pospfp1_de);


--
-- Name: pospfp1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp1_t_basket_idx ON movd.pospfp1 USING btree (t_basket);


--
-- Name: pospfp2_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp2_pos_idx ON movd.pospfp2 USING gist (pos);


--
-- Name: pospfp2_pospfp2_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp2_pospfp2_de_idx ON movd.pospfp2 USING btree (pospfp2_de);


--
-- Name: pospfp2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp2_t_basket_idx ON movd.pospfp2 USING btree (t_basket);


--
-- Name: pospfp3_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp3_pos_idx ON movd.pospfp3 USING gist (pos);


--
-- Name: pospfp3_pospfp3_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp3_pospfp3_de_idx ON movd.pospfp3 USING btree (pospfp3_de);


--
-- Name: pospfp3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospfp3_t_basket_idx ON movd.pospfp3 USING btree (t_basket);


--
-- Name: posplan_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posplan_pos_idx ON movd.posplan USING gist (pos);


--
-- Name: posplan_posplan_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posplan_posplan_de_idx ON movd.posplan USING btree (posplan_de);


--
-- Name: posplan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX posplan_t_basket_idx ON movd.posplan USING btree (t_basket);


--
-- Name: pospoint_cote_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_cote_pos_idx ON movd.pospoint_cote USING gist (pos);


--
-- Name: pospoint_cote_pospoint_cote_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_cote_pospoint_cote_de_idx ON movd.pospoint_cote USING btree (pospoint_cote_de);


--
-- Name: pospoint_cote_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_cote_t_basket_idx ON movd.pospoint_cote USING btree (t_basket);


--
-- Name: pospoint_limite_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_limite_pos_idx ON movd.pospoint_limite USING gist (pos);


--
-- Name: pospoint_limite_pospoint_limite_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_limite_pospoint_limite_de_idx ON movd.pospoint_limite USING btree (pospoint_limite_de);


--
-- Name: pospoint_limite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_limite_t_basket_idx ON movd.pospoint_limite USING btree (t_basket);


--
-- Name: pospoint_limite_ter_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_limite_ter_pos_idx ON movd.pospoint_limite_ter USING gist (pos);


--
-- Name: pospoint_limite_ter_pospoint_limite_ter_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_limite_ter_pospoint_limite_ter_de_idx ON movd.pospoint_limite_ter USING btree (pospoint_limite_ter_de);


--
-- Name: pospoint_limite_ter_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_limite_ter_t_basket_idx ON movd.pospoint_limite_ter USING btree (t_basket);


--
-- Name: pospoint_particulier_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_particulier_pos_idx ON movd.pospoint_particulier USING gist (pos);


--
-- Name: pospoint_particulier_pospoint_particulier_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_particulier_pospoint_particulier_de_idx ON movd.pospoint_particulier USING btree (pospoint_particulier_de);


--
-- Name: pospoint_particulier_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX pospoint_particulier_t_basket_idx ON movd.pospoint_particulier USING btree (t_basket);


--
-- Name: possignal_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX possignal_pos_idx ON movd.possignal USING gist (pos);


--
-- Name: possignal_possignal_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX possignal_possignal_de_idx ON movd.possignal USING btree (possignal_de);


--
-- Name: possignal_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX possignal_t_basket_idx ON movd.possignal USING btree (t_basket);


--
-- Name: surface_representation_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surface_representation_geometrie_idx ON movd.surface_representation USING gist (geometrie);


--
-- Name: surface_representation_surface_representation_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surface_representation_surface_representation_de_idx ON movd.surface_representation USING btree (surface_representation_de);


--
-- Name: surface_representation_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surface_representation_t_basket_idx ON movd.surface_representation USING btree (t_basket);


--
-- Name: surface_vide_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surface_vide_geometrie_idx ON movd.surface_vide USING gist (geometrie);


--
-- Name: surface_vide_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surface_vide_origine_idx ON movd.surface_vide USING btree (origine);


--
-- Name: surface_vide_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surface_vide_t_basket_idx ON movd.surface_vide USING btree (t_basket);


--
-- Name: surfacecs_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surfacecs_geometrie_idx ON movd.surfacecs USING gist (geometrie);


--
-- Name: surfacecs_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surfacecs_origine_idx ON movd.surfacecs USING btree (origine);


--
-- Name: surfacecs_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surfacecs_t_basket_idx ON movd.surfacecs USING btree (t_basket);


--
-- Name: surfacecsproj_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surfacecsproj_geometrie_idx ON movd.surfacecsproj USING gist (geometrie);


--
-- Name: surfacecsproj_origine_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surfacecsproj_origine_idx ON movd.surfacecsproj USING btree (origine);


--
-- Name: surfacecsproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX surfacecsproj_t_basket_idx ON movd.surfacecsproj USING btree (t_basket);


--
-- Name: symbolebord_de_plan_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolebord_de_plan_pos_idx ON movd.symbolebord_de_plan USING gist (pos);


--
-- Name: symbolebord_de_plan_symbolebord_de_plan_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolebord_de_plan_symbolebord_de_plan_de_idx ON movd.symbolebord_de_plan USING btree (symbolebord_de_plan_de);


--
-- Name: symbolebord_de_plan_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolebord_de_plan_t_basket_idx ON movd.symbolebord_de_plan USING btree (t_basket);


--
-- Name: symboleelement_lineaire_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symboleelement_lineaire_pos_idx ON movd.symboleelement_lineaire USING gist (pos);


--
-- Name: symboleelement_lineaire_symboleelement_lineaire_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symboleelement_lineaire_symboleelement_lineaire_de_idx ON movd.symboleelement_lineaire USING btree (symboleelement_lineaire_de);


--
-- Name: symboleelement_lineaire_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symboleelement_lineaire_t_basket_idx ON movd.symboleelement_lineaire USING btree (t_basket);


--
-- Name: symboleelement_surf_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symboleelement_surf_pos_idx ON movd.symboleelement_surf USING gist (pos);


--
-- Name: symboleelement_surf_symboleelement_surf_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symboleelement_surf_symboleelement_surf_de_idx ON movd.symboleelement_surf USING btree (symboleelement_surf_de);


--
-- Name: symboleelement_surf_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symboleelement_surf_t_basket_idx ON movd.symboleelement_surf USING btree (t_basket);


--
-- Name: symbolepfp1_symbolepfp1_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepfp1_symbolepfp1_de_idx ON movd.symbolepfp1 USING btree (symbolepfp1_de);


--
-- Name: symbolepfp1_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepfp1_t_basket_idx ON movd.symbolepfp1 USING btree (t_basket);


--
-- Name: symbolepfp2_symbolepfp2_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepfp2_symbolepfp2_de_idx ON movd.symbolepfp2 USING btree (symbolepfp2_de);


--
-- Name: symbolepfp2_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepfp2_t_basket_idx ON movd.symbolepfp2 USING btree (t_basket);


--
-- Name: symbolepfp3_symbolepfp3_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepfp3_symbolepfp3_de_idx ON movd.symbolepfp3 USING btree (symbolepfp3_de);


--
-- Name: symbolepfp3_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepfp3_t_basket_idx ON movd.symbolepfp3 USING btree (t_basket);


--
-- Name: symbolepoint_limite_symbolepoint_limite_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepoint_limite_symbolepoint_limite_de_idx ON movd.symbolepoint_limite USING btree (symbolepoint_limite_de);


--
-- Name: symbolepoint_limite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepoint_limite_t_basket_idx ON movd.symbolepoint_limite USING btree (t_basket);


--
-- Name: symbolepoint_limite_ter_symbolepoint_limite_ter_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepoint_limite_ter_symbolepoint_limite_ter_de_idx ON movd.symbolepoint_limite_ter USING btree (symbolepoint_limite_ter_de);


--
-- Name: symbolepoint_limite_ter_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolepoint_limite_ter_t_basket_idx ON movd.symbolepoint_limite_ter USING btree (t_basket);


--
-- Name: symbolesurfacecs_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolesurfacecs_pos_idx ON movd.symbolesurfacecs USING gist (pos);


--
-- Name: symbolesurfacecs_symbolesurfacecs_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolesurfacecs_symbolesurfacecs_de_idx ON movd.symbolesurfacecs USING btree (symbolesurfacecs_de);


--
-- Name: symbolesurfacecs_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolesurfacecs_t_basket_idx ON movd.symbolesurfacecs USING btree (t_basket);


--
-- Name: symbolesurfacecsproj_pos_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolesurfacecsproj_pos_idx ON movd.symbolesurfacecsproj USING gist (pos);


--
-- Name: symbolesurfacecsproj_symbolesurfcsproj_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolesurfacecsproj_symbolesurfcsproj_de_idx ON movd.symbolesurfacecsproj USING btree (symbolesurfcsproj_de);


--
-- Name: symbolesurfacecsproj_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX symbolesurfacecsproj_t_basket_idx ON movd.symbolesurfacecsproj USING btree (t_basket);


--
-- Name: t_ili2db_attrname_sqlname_colowner_key; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE UNIQUE INDEX t_ili2db_attrname_sqlname_colowner_key ON movd.t_ili2db_attrname USING btree (sqlname, colowner);


--
-- Name: t_ili2db_basket_dataset_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX t_ili2db_basket_dataset_idx ON movd.t_ili2db_basket USING btree (dataset);


--
-- Name: t_ili2db_dataset_datasetname_key; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE UNIQUE INDEX t_ili2db_dataset_datasetname_key ON movd.t_ili2db_dataset USING btree (datasetname);


--
-- Name: t_ili2db_model_modelname_iliversion_key; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE UNIQUE INDEX t_ili2db_model_modelname_iliversion_key ON movd.t_ili2db_model USING btree (modelname, iliversion);


--
-- Name: texte_groupement_de_lclite_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX texte_groupement_de_lclite_t_basket_idx ON movd.texte_groupement_de_localite USING btree (t_basket);


--
-- Name: texte_groupement_de_lclite_texte_groupement_d_lclt_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX texte_groupement_de_lclite_texte_groupement_d_lclt_de_idx ON movd.texte_groupement_de_localite USING btree (texte_groupement_de_localite_de);


--
-- Name: troncon_rue_geometrie_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX troncon_rue_geometrie_idx ON movd.troncon_rue USING gist (geometrie);


--
-- Name: troncon_rue_point_depart_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX troncon_rue_point_depart_idx ON movd.troncon_rue USING gist (point_depart);


--
-- Name: troncon_rue_t_basket_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX troncon_rue_t_basket_idx ON movd.troncon_rue USING btree (t_basket);


--
-- Name: troncon_rue_troncon_rue_de_idx; Type: INDEX; Schema: movd; Owner: gc_transfert_dbo
--

CREATE INDEX troncon_rue_troncon_rue_de_idx ON movd.troncon_rue USING btree (troncon_rue_de);


--
-- Name: entree_batiment_projet_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX entree_batiment_projet_geometrie_idx ON specificite_lausanne.entree_batiment_projet USING gist (geometrie);


--
-- Name: localisation_place_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX localisation_place_geometrie_idx ON specificite_lausanne.localisation_place USING gist (geometrie);


--
-- Name: objet_divers_arbre_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX objet_divers_arbre_geometrie_idx ON specificite_lausanne.objet_divers_ponctuel USING gist (geometrie);


--
-- Name: pfa_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX pfa_geometrie_idx ON specificite_lausanne.pfa USING gist (geometrie);


--
-- Name: pfp_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX pfp_geometrie_idx ON specificite_lausanne.pfp USING gist (geometrie);


--
-- Name: pfp_label_reperage_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX pfp_label_reperage_geometrie_idx ON specificite_lausanne.pfp_label_reperage USING gist (geometrie);


--
-- Name: pfp_line_reperage_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX pfp_line_reperage_geometrie_idx ON specificite_lausanne.pfp_line_reperage USING gist (geometrie);


--
-- Name: pfp_point_reperage_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX pfp_point_reperage_geometrie_idx ON specificite_lausanne.pfp_point_reperage USING gist (geometrie);


--
-- Name: surface_batiment_projet_geometrie_idx; Type: INDEX; Schema: specificite_lausanne; Owner: gc_transfert_dbo
--

CREATE INDEX surface_batiment_projet_geometrie_idx ON specificite_lausanne.surface_batiment_projet USING gist (geometrie);


--
-- Name: aplan aplan_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.aplan
    ADD CONSTRAINT aplan_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourrp(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: aplan aplan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.aplan
    ADD CONSTRAINT aplan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: arete arete_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.arete
    ADD CONSTRAINT arete_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_joural(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: arete arete_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.arete
    ADD CONSTRAINT arete_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: asignal asignal_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.asignal
    ADD CONSTRAINT asignal_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourco(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: asignal asignal_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.asignal
    ADD CONSTRAINT asignal_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: bien_fonds bien_fonds_bien_fonds_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bien_fonds
    ADD CONSTRAINT bien_fonds_bien_fonds_de_fkey FOREIGN KEY (bien_fonds_de) REFERENCES movd.immeuble(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: bien_fonds bien_fonds_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bien_fonds
    ADD CONSTRAINT bien_fonds_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: bien_fondsproj bien_fondsproj_bien_fondsproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bien_fondsproj
    ADD CONSTRAINT bien_fondsproj_bien_fondsproj_de_fkey FOREIGN KEY (bien_fondsproj_de) REFERENCES movd.immeubleproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: bien_fondsproj bien_fondsproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bien_fondsproj
    ADD CONSTRAINT bien_fondsproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: bord_de_plan bord_de_plan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.bord_de_plan
    ADD CONSTRAINT bord_de_plan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: commune commune_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.commune
    ADD CONSTRAINT commune_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: croix_filet croix_filet_croix_filet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.croix_filet
    ADD CONSTRAINT croix_filet_croix_filet_de_fkey FOREIGN KEY (croix_filet_de) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: croix_filet croix_filet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.croix_filet
    ADD CONSTRAINT croix_filet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ddp ddp_ddp_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ddp
    ADD CONSTRAINT ddp_ddp_de_fkey FOREIGN KEY (ddp_de) REFERENCES movd.immeuble(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ddp ddp_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ddp
    ADD CONSTRAINT ddp_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ddpproj ddpproj_ddpproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ddpproj
    ADD CONSTRAINT ddpproj_ddpproj_de_fkey FOREIGN KEY (ddpproj_de) REFERENCES movd.immeubleproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ddpproj ddpproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ddpproj
    ADD CONSTRAINT ddpproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: description_batiment description_batiment_description_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.description_batiment
    ADD CONSTRAINT description_batiment_description_batiment_de_fkey FOREIGN KEY (description_batiment_de) REFERENCES movd.entree_batiment(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: description_batiment description_batiment_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.description_batiment
    ADD CONSTRAINT description_batiment_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: description_plan description_plan_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.description_plan
    ADD CONSTRAINT description_plan_origine_fkey FOREIGN KEY (origine) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: description_plan description_plan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.description_plan
    ADD CONSTRAINT description_plan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: domaine_numerotation domaine_numerotation_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.domaine_numerotation
    ADD CONSTRAINT domaine_numerotation_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_conduite element_conduite_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_conduite
    ADD CONSTRAINT element_conduite_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourco(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_conduite element_conduite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_conduite
    ADD CONSTRAINT element_conduite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_lineaire element_lineaire_element_lineaire_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_lineaire
    ADD CONSTRAINT element_lineaire_element_lineaire_de_fkey FOREIGN KEY (element_lineaire_de) REFERENCES movd.objet_divers(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_lineaire element_lineaire_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_lineaire
    ADD CONSTRAINT element_lineaire_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_ponctuel element_ponctuel_element_ponctuel_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_ponctuel
    ADD CONSTRAINT element_ponctuel_element_ponctuel_de_fkey FOREIGN KEY (element_ponctuel_de) REFERENCES movd.objet_divers(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_ponctuel element_ponctuel_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_ponctuel
    ADD CONSTRAINT element_ponctuel_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_surfacique element_surfacique_element_surfacique_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_surfacique
    ADD CONSTRAINT element_surfacique_element_surfacique_de_fkey FOREIGN KEY (element_surfacique_de) REFERENCES movd.objet_divers(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: element_surfacique element_surfacique_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.element_surfacique
    ADD CONSTRAINT element_surfacique_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: entree_batiment entree_batiment_entree_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment
    ADD CONSTRAINT entree_batiment_entree_batiment_de_fkey FOREIGN KEY (entree_batiment_de) REFERENCES movd.localisation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: entree_batiment entree_batiment_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment
    ADD CONSTRAINT entree_batiment_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourbat(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: entree_batiment entree_batiment_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.entree_batiment
    ADD CONSTRAINT entree_batiment_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: geometrie_plan geometrie_plan_geometrie_plan_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.geometrie_plan
    ADD CONSTRAINT geometrie_plan_geometrie_plan_de_fkey FOREIGN KEY (geometrie_plan_de) REFERENCES movd.aplan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: geometrie_plan geometrie_plan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.geometrie_plan
    ADD CONSTRAINT geometrie_plan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: geometriedn geometriedn_geometriedn_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.geometriedn
    ADD CONSTRAINT geometriedn_geometriedn_de_fkey FOREIGN KEY (geometriedn_de) REFERENCES movd.domaine_numerotation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: geometriedn geometriedn_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.geometriedn
    ADD CONSTRAINT geometriedn_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: glissement glissement_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.glissement
    ADD CONSTRAINT glissement_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: groupement_de_localite groupement_de_localite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.groupement_de_localite
    ADD CONSTRAINT groupement_de_localite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: immeuble immeuble_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeuble
    ADD CONSTRAINT immeuble_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourbf(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: immeuble immeuble_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeuble
    ADD CONSTRAINT immeuble_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: immeubleproj immeubleproj_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeubleproj
    ADD CONSTRAINT immeubleproj_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourbf(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: immeubleproj immeubleproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.immeubleproj
    ADD CONSTRAINT immeubleproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: indication_coordonnees indication_coordonnees_indication_coordonnees_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.indication_coordonnees
    ADD CONSTRAINT indication_coordonnees_indication_coordonnees_de_fkey FOREIGN KEY (indication_coordonnees_de) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: indication_coordonnees indication_coordonnees_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.indication_coordonnees
    ADD CONSTRAINT indication_coordonnees_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: lieu_denomme lieu_denomme_lieu_denomme_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lieu_denomme
    ADD CONSTRAINT lieu_denomme_lieu_denomme_de_fkey FOREIGN KEY (lieu_denomme_de) REFERENCES movd.localisation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: lieu_denomme lieu_denomme_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lieu_denomme
    ADD CONSTRAINT lieu_denomme_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: lieudit lieudit_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lieudit
    ADD CONSTRAINT lieudit_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_journo(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: lieudit lieudit_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.lieudit
    ADD CONSTRAINT lieudit_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ligne_coordonnees ligne_coordonnees_ligne_coordonnees_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ligne_coordonnees
    ADD CONSTRAINT ligne_coordonnees_ligne_coordonnees_de_fkey FOREIGN KEY (ligne_coordonnees_de) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ligne_coordonnees ligne_coordonnees_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.ligne_coordonnees
    ADD CONSTRAINT ligne_coordonnees_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: limite_commune limite_commune_limite_commune_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_commune
    ADD CONSTRAINT limite_commune_limite_commune_de_fkey FOREIGN KEY (limite_commune_de) REFERENCES movd.commune(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: limite_commune limite_commune_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_commune
    ADD CONSTRAINT limite_commune_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourcom(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: limite_commune limite_commune_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_commune
    ADD CONSTRAINT limite_commune_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: limite_communeproj limite_communeproj_limite_communeproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_communeproj
    ADD CONSTRAINT limite_communeproj_limite_communeproj_de_fkey FOREIGN KEY (limite_communeproj_de) REFERENCES movd.commune(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: limite_communeproj limite_communeproj_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_communeproj
    ADD CONSTRAINT limite_communeproj_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourcom(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: limite_communeproj limite_communeproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.limite_communeproj
    ADD CONSTRAINT limite_communeproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: localisation localisation_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation
    ADD CONSTRAINT localisation_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourbat(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: localisation localisation_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localisation
    ADD CONSTRAINT localisation_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: localite localite_localite_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localite
    ADD CONSTRAINT localite_localite_de_fkey FOREIGN KEY (localite_de) REFERENCES movd.groupement_de_localite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: localite localite_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localite
    ADD CONSTRAINT localite_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourloc(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: localite localite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.localite
    ADD CONSTRAINT localite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_nom_objet md01mvdmn95v2_dvrs_nm_bjet_nom_objet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_nom_objet
    ADD CONSTRAINT md01mvdmn95v2_dvrs_nm_bjet_nom_objet_de_fkey FOREIGN KEY (nom_objet_de) REFERENCES movd.objet_divers(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_nom_objet md01mvdmn95v2_dvrs_nm_bjet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_nom_objet
    ADD CONSTRAINT md01mvdmn95v2_dvrs_nm_bjet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_element_ponctuel md01mvdmn95v2_lmnt_pnctuel_element_ponctuel_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_ponctuel
    ADD CONSTRAINT md01mvdmn95v2_lmnt_pnctuel_element_ponctuel_de_fkey FOREIGN KEY (element_ponctuel_de) REFERENCES movd.element_conduite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_element_ponctuel md01mvdmn95v2_lmnt_pnctuel_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_ponctuel
    ADD CONSTRAINT md01mvdmn95v2_lmnt_pnctuel_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_element_surfacique md01mvdmn95v2_lmnt_srfcque_element_surfacique_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_surfacique
    ADD CONSTRAINT md01mvdmn95v2_lmnt_srfcque_element_surfacique_de_fkey FOREIGN KEY (element_surfacique_de) REFERENCES movd.element_conduite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_element_surfacique md01mvdmn95v2_lmnt_srfcque_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_surfacique
    ADD CONSTRAINT md01mvdmn95v2_lmnt_srfcque_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_point_particulier md01mvdmn95v2_pnt_prtclier_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_point_particulier
    ADD CONSTRAINT md01mvdmn95v2_pnt_prtclier_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourod(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_point_particulier md01mvdmn95v2_pnt_prtclier_origine_fkey1; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_point_particulier
    ADD CONSTRAINT md01mvdmn95v2_pnt_prtclier_origine_fkey1 FOREIGN KEY (origine) REFERENCES movd.mise_a_jourco(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_point_particulier md01mvdmn95v2_pnt_prtclier_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_point_particulier
    ADD CONSTRAINT md01mvdmn95v2_pnt_prtclier_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_point_particulier md01mvdmn95v2_pnt_prtclier_t_basket_fkey1; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_point_particulier
    ADD CONSTRAINT md01mvdmn95v2_pnt_prtclier_t_basket_fkey1 FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24bords_de_plan_element_lineaire md01mvdmn95v2ln_lmnt_lnire_element_lineaire_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24bords_de_plan_element_lineaire
    ADD CONSTRAINT md01mvdmn95v2ln_lmnt_lnire_element_lineaire_de_fkey FOREIGN KEY (element_lineaire_de) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24bords_de_plan_element_lineaire md01mvdmn95v2ln_lmnt_lnire_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24bords_de_plan_element_lineaire
    ADD CONSTRAINT md01mvdmn95v2ln_lmnt_lnire_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_pospoint_particulier md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_pospoint_particulier
    ADD CONSTRAINT md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_fkey FOREIGN KEY (pospoint_particulier_de) REFERENCES movd.md01mvdmn95v24objets_divers_point_particulier(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_pospoint_particulier md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_fkey1; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_pospoint_particulier
    ADD CONSTRAINT md01mvdmn95v2spnt_prtclier_pospoint_particulier_de_fkey1 FOREIGN KEY (pospoint_particulier_de) REFERENCES movd.md01mvdmn95v24conduites_point_particulier(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_pospoint_particulier md01mvdmn95v2spnt_prtclier_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_pospoint_particulier
    ADD CONSTRAINT md01mvdmn95v2spnt_prtclier_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_pospoint_particulier md01mvdmn95v2spnt_prtclier_t_basket_fkey1; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_pospoint_particulier
    ADD CONSTRAINT md01mvdmn95v2spnt_prtclier_t_basket_fkey1 FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_element_lineaire md01mvdmn95v2ts_lmnt_lnire_element_lineaire_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_lineaire
    ADD CONSTRAINT md01mvdmn95v2ts_lmnt_lnire_element_lineaire_de_fkey FOREIGN KEY (element_lineaire_de) REFERENCES movd.element_conduite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24conduites_element_lineaire md01mvdmn95v2ts_lmnt_lnire_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24conduites_element_lineaire
    ADD CONSTRAINT md01mvdmn95v2ts_lmnt_lnire_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_posnom_objet md01mvdmn95v2vrs_psnm_bjet_posnom_objet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_posnom_objet
    ADD CONSTRAINT md01mvdmn95v2vrs_psnm_bjet_posnom_objet_de_fkey FOREIGN KEY (posnom_objet_de) REFERENCES movd.md01mvdmn95v24objets_divers_nom_objet(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: md01mvdmn95v24objets_divers_posnom_objet md01mvdmn95v2vrs_psnm_bjet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.md01mvdmn95v24objets_divers_posnom_objet
    ADD CONSTRAINT md01mvdmn95v2vrs_psnm_bjet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mine mine_mine_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mine
    ADD CONSTRAINT mine_mine_de_fkey FOREIGN KEY (mine_de) REFERENCES movd.immeuble(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mine mine_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mine
    ADD CONSTRAINT mine_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mineproj mineproj_mineproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mineproj
    ADD CONSTRAINT mineproj_mineproj_de_fkey FOREIGN KEY (mineproj_de) REFERENCES movd.immeubleproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mineproj mineproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mineproj
    ADD CONSTRAINT mineproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_joural mise_a_joural_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_joural
    ADD CONSTRAINT mise_a_joural_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourbat mise_a_jourbat_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourbat
    ADD CONSTRAINT mise_a_jourbat_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourbf mise_a_jourbf_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourbf
    ADD CONSTRAINT mise_a_jourbf_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourco mise_a_jourco_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourco
    ADD CONSTRAINT mise_a_jourco_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourcom mise_a_jourcom_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourcom
    ADD CONSTRAINT mise_a_jourcom_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourcs mise_a_jourcs_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourcs
    ADD CONSTRAINT mise_a_jourcs_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourloc mise_a_jourloc_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourloc
    ADD CONSTRAINT mise_a_jourloc_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_journo mise_a_journo_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_journo
    ADD CONSTRAINT mise_a_journo_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_journpa6 mise_a_journpa6_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_journpa6
    ADD CONSTRAINT mise_a_journpa6_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourod mise_a_jourod_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourod
    ADD CONSTRAINT mise_a_jourod_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourpfa1 mise_a_jourpfa1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfa1
    ADD CONSTRAINT mise_a_jourpfa1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourpfa2 mise_a_jourpfa2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfa2
    ADD CONSTRAINT mise_a_jourpfa2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourpfa3 mise_a_jourpfa3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfa3
    ADD CONSTRAINT mise_a_jourpfa3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourpfp1 mise_a_jourpfp1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfp1
    ADD CONSTRAINT mise_a_jourpfp1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourpfp2 mise_a_jourpfp2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfp2
    ADD CONSTRAINT mise_a_jourpfp2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourpfp3 mise_a_jourpfp3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourpfp3
    ADD CONSTRAINT mise_a_jourpfp3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: mise_a_jourrp mise_a_jourrp_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.mise_a_jourrp
    ADD CONSTRAINT mise_a_jourrp_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: niveau_tolerance niveau_tolerance_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.niveau_tolerance
    ADD CONSTRAINT niveau_tolerance_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_batiment nom_batiment_nom_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_batiment
    ADD CONSTRAINT nom_batiment_nom_batiment_de_fkey FOREIGN KEY (nom_batiment_de) REFERENCES movd.entree_batiment(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_batiment nom_batiment_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_batiment
    ADD CONSTRAINT nom_batiment_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_de_lieu nom_de_lieu_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_de_lieu
    ADD CONSTRAINT nom_de_lieu_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_journo(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_de_lieu nom_de_lieu_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_de_lieu
    ADD CONSTRAINT nom_de_lieu_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_local nom_local_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_local
    ADD CONSTRAINT nom_local_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_journo(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_local nom_local_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_local
    ADD CONSTRAINT nom_local_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_localisation nom_localisation_nom_localisation_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_localisation
    ADD CONSTRAINT nom_localisation_nom_localisation_de_fkey FOREIGN KEY (nom_localisation_de) REFERENCES movd.localisation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_localisation nom_localisation_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_localisation
    ADD CONSTRAINT nom_localisation_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_localite nom_localite_nom_localite_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_localite
    ADD CONSTRAINT nom_localite_nom_localite_de_fkey FOREIGN KEY (nom_localite_de) REFERENCES movd.localite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_localite nom_localite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_localite
    ADD CONSTRAINT nom_localite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_objet nom_objet_nom_objet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_objet
    ADD CONSTRAINT nom_objet_nom_objet_de_fkey FOREIGN KEY (nom_objet_de) REFERENCES movd.surfacecs(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nom_objet nom_objet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nom_objet
    ADD CONSTRAINT nom_objet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nomobjetproj nomobjetproj_nomobjetproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nomobjetproj
    ADD CONSTRAINT nomobjetproj_nomobjetproj_de_fkey FOREIGN KEY (nomobjetproj_de) REFERENCES movd.surfacecsproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: nomobjetproj nomobjetproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.nomobjetproj
    ADD CONSTRAINT nomobjetproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: npa6 npa6_npa6_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.npa6
    ADD CONSTRAINT npa6_npa6_de_fkey FOREIGN KEY (npa6_de) REFERENCES movd.localite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: npa6 npa6_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.npa6
    ADD CONSTRAINT npa6_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_journpa6(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: npa6 npa6_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.npa6
    ADD CONSTRAINT npa6_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: numero_de_batiment numero_de_batiment_numero_de_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numero_de_batiment
    ADD CONSTRAINT numero_de_batiment_numero_de_batiment_de_fkey FOREIGN KEY (numero_de_batiment_de) REFERENCES movd.surfacecs(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: numero_de_batiment numero_de_batiment_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numero_de_batiment
    ADD CONSTRAINT numero_de_batiment_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: numero_objet numero_objet_numero_objet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numero_objet
    ADD CONSTRAINT numero_objet_numero_objet_de_fkey FOREIGN KEY (numero_objet_de) REFERENCES movd.objet_divers(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: numero_objet numero_objet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numero_objet
    ADD CONSTRAINT numero_objet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: numerobatimentproj numerobatimentproj_numerobatimentproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numerobatimentproj
    ADD CONSTRAINT numerobatimentproj_numerobatimentproj_de_fkey FOREIGN KEY (numerobatimentproj_de) REFERENCES movd.surfacecsproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: numerobatimentproj numerobatimentproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.numerobatimentproj
    ADD CONSTRAINT numerobatimentproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: objet_divers objet_divers_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.objet_divers
    ADD CONSTRAINT objet_divers_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourod(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: objet_divers objet_divers_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.objet_divers
    ADD CONSTRAINT objet_divers_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: partie_limite_canton partie_limite_canton_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_canton
    ADD CONSTRAINT partie_limite_canton_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: partie_limite_district partie_limite_district_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_district
    ADD CONSTRAINT partie_limite_district_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: partie_limite_nationale partie_limite_nationale_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.partie_limite_nationale
    ADD CONSTRAINT partie_limite_nationale_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfa1 pfa1_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa1
    ADD CONSTRAINT pfa1_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourpfa1(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfa1 pfa1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa1
    ADD CONSTRAINT pfa1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfa2 pfa2_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa2
    ADD CONSTRAINT pfa2_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourpfa2(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfa2 pfa2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa2
    ADD CONSTRAINT pfa2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfa3 pfa3_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa3
    ADD CONSTRAINT pfa3_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourpfa3(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfa3 pfa3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfa3
    ADD CONSTRAINT pfa3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfp1 pfp1_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp1
    ADD CONSTRAINT pfp1_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourpfp1(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfp1 pfp1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp1
    ADD CONSTRAINT pfp1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfp2 pfp2_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp2
    ADD CONSTRAINT pfp2_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourpfp2(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfp2 pfp2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp2
    ADD CONSTRAINT pfp2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfp3 pfp3_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp3
    ADD CONSTRAINT pfp3_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourpfp3(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pfp3 pfp3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pfp3
    ADD CONSTRAINT pfp3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_cote point_cote_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_cote
    ADD CONSTRAINT point_cote_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_joural(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_cote point_cote_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_cote
    ADD CONSTRAINT point_cote_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_limite point_limite_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite
    ADD CONSTRAINT point_limite_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourbf(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_limite point_limite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite
    ADD CONSTRAINT point_limite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_limite_ter point_limite_ter_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_ter
    ADD CONSTRAINT point_limite_ter_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourcom(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_limite_ter point_limite_ter_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_limite_ter
    ADD CONSTRAINT point_limite_ter_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_particulier point_particulier_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_particulier
    ADD CONSTRAINT point_particulier_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourcs(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: point_particulier point_particulier_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.point_particulier
    ADD CONSTRAINT point_particulier_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posdescription_plan posdescription_plan_posdescription_plan_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posdescription_plan
    ADD CONSTRAINT posdescription_plan_posdescription_plan_de_fkey FOREIGN KEY (posdescription_plan_de) REFERENCES movd.description_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posdescription_plan posdescription_plan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posdescription_plan
    ADD CONSTRAINT posdescription_plan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posdomaine_numerotation posdomaine_numerotation_posdomaine_numerotation_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posdomaine_numerotation
    ADD CONSTRAINT posdomaine_numerotation_posdomaine_numerotation_de_fkey FOREIGN KEY (posdomaine_numerotation_de) REFERENCES movd.domaine_numerotation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posdomaine_numerotation posdomaine_numerotation_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posdomaine_numerotation
    ADD CONSTRAINT posdomaine_numerotation_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: poselement_conduite poselement_conduite_poselement_conduite_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.poselement_conduite
    ADD CONSTRAINT poselement_conduite_poselement_conduite_de_fkey FOREIGN KEY (poselement_conduite_de) REFERENCES movd.element_conduite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: poselement_conduite poselement_conduite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.poselement_conduite
    ADD CONSTRAINT poselement_conduite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posglissement posglissement_posglissement_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posglissement
    ADD CONSTRAINT posglissement_posglissement_de_fkey FOREIGN KEY (posglissement_de) REFERENCES movd.glissement(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posglissement posglissement_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posglissement
    ADD CONSTRAINT posglissement_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posimmeuble posimmeuble_posimmeuble_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posimmeuble
    ADD CONSTRAINT posimmeuble_posimmeuble_de_fkey FOREIGN KEY (posimmeuble_de) REFERENCES movd.immeuble(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posimmeuble posimmeuble_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posimmeuble
    ADD CONSTRAINT posimmeuble_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posimmeubleproj posimmeubleproj_posimmeubleproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posimmeubleproj
    ADD CONSTRAINT posimmeubleproj_posimmeubleproj_de_fkey FOREIGN KEY (posimmeubleproj_de) REFERENCES movd.immeubleproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posimmeubleproj posimmeubleproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posimmeubleproj
    ADD CONSTRAINT posimmeubleproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posindication_coord posindication_coord_posindication_coord_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posindication_coord
    ADD CONSTRAINT posindication_coord_posindication_coord_de_fkey FOREIGN KEY (posindication_coord_de) REFERENCES movd.indication_coordonnees(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posindication_coord posindication_coord_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posindication_coord
    ADD CONSTRAINT posindication_coord_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: poslieudit poslieudit_poslieudit_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.poslieudit
    ADD CONSTRAINT poslieudit_poslieudit_de_fkey FOREIGN KEY (poslieudit_de) REFERENCES movd.lieudit(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: poslieudit poslieudit_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.poslieudit
    ADD CONSTRAINT poslieudit_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posniveau_tolerance posniveau_tolerance_posniveau_tolerance_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posniveau_tolerance
    ADD CONSTRAINT posniveau_tolerance_posniveau_tolerance_de_fkey FOREIGN KEY (posniveau_tolerance_de) REFERENCES movd.niveau_tolerance(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posniveau_tolerance posniveau_tolerance_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posniveau_tolerance
    ADD CONSTRAINT posniveau_tolerance_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_batiment posnom_batiment_posnom_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_batiment
    ADD CONSTRAINT posnom_batiment_posnom_batiment_de_fkey FOREIGN KEY (posnom_batiment_de) REFERENCES movd.nom_batiment(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_batiment posnom_batiment_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_batiment
    ADD CONSTRAINT posnom_batiment_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_de_lieu posnom_de_lieu_posnom_de_lieu_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_de_lieu
    ADD CONSTRAINT posnom_de_lieu_posnom_de_lieu_de_fkey FOREIGN KEY (posnom_de_lieu_de) REFERENCES movd.nom_de_lieu(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_de_lieu posnom_de_lieu_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_de_lieu
    ADD CONSTRAINT posnom_de_lieu_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_local posnom_local_posnom_local_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_local
    ADD CONSTRAINT posnom_local_posnom_local_de_fkey FOREIGN KEY (posnom_local_de) REFERENCES movd.nom_local(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_local posnom_local_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_local
    ADD CONSTRAINT posnom_local_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_localisation posnom_localisation_posnom_localisation_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_localisation
    ADD CONSTRAINT posnom_localisation_posnom_localisation_de_fkey FOREIGN KEY (posnom_localisation_de) REFERENCES movd.nom_localisation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_localisation posnom_localisation_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_localisation
    ADD CONSTRAINT posnom_localisation_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_localite posnom_localite_posnom_localite_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_localite
    ADD CONSTRAINT posnom_localite_posnom_localite_de_fkey FOREIGN KEY (posnom_localite_de) REFERENCES movd.nom_localite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_localite posnom_localite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_localite
    ADD CONSTRAINT posnom_localite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_objet posnom_objet_posnom_objet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_objet
    ADD CONSTRAINT posnom_objet_posnom_objet_de_fkey FOREIGN KEY (posnom_objet_de) REFERENCES movd.nom_objet(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnom_objet posnom_objet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnom_objet
    ADD CONSTRAINT posnom_objet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnomobjetproj posnomobjetproj_posnomobjetproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnomobjetproj
    ADD CONSTRAINT posnomobjetproj_posnomobjetproj_de_fkey FOREIGN KEY (posnomobjetproj_de) REFERENCES movd.nomobjetproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnomobjetproj posnomobjetproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnomobjetproj
    ADD CONSTRAINT posnomobjetproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumero_de_batiment posnumero_de_batiment_posnumero_de_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_de_batiment
    ADD CONSTRAINT posnumero_de_batiment_posnumero_de_batiment_de_fkey FOREIGN KEY (posnumero_de_batiment_de) REFERENCES movd.numero_de_batiment(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumero_de_batiment posnumero_de_batiment_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_de_batiment
    ADD CONSTRAINT posnumero_de_batiment_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumero_maison posnumero_maison_posnumero_batiment_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_maison
    ADD CONSTRAINT posnumero_maison_posnumero_batiment_de_fkey FOREIGN KEY (posnumero_batiment_de) REFERENCES movd.entree_batiment(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumero_maison posnumero_maison_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_maison
    ADD CONSTRAINT posnumero_maison_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumero_objet posnumero_objet_posnumero_objet_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_objet
    ADD CONSTRAINT posnumero_objet_posnumero_objet_de_fkey FOREIGN KEY (posnumero_objet_de) REFERENCES movd.numero_objet(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumero_objet posnumero_objet_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumero_objet
    ADD CONSTRAINT posnumero_objet_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumerobatimentproj posnumerobatimentproj_posnumerobatimentproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumerobatimentproj
    ADD CONSTRAINT posnumerobatimentproj_posnumerobatimentproj_de_fkey FOREIGN KEY (posnumerobatimentproj_de) REFERENCES movd.numerobatimentproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posnumerobatimentproj posnumerobatimentproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posnumerobatimentproj
    ADD CONSTRAINT posnumerobatimentproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfa1 pospfa1_pospfa1_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa1
    ADD CONSTRAINT pospfa1_pospfa1_de_fkey FOREIGN KEY (pospfa1_de) REFERENCES movd.pfa1(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfa1 pospfa1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa1
    ADD CONSTRAINT pospfa1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfa2 pospfa2_pospfa2_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa2
    ADD CONSTRAINT pospfa2_pospfa2_de_fkey FOREIGN KEY (pospfa2_de) REFERENCES movd.pfa2(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfa2 pospfa2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa2
    ADD CONSTRAINT pospfa2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfa3 pospfa3_pospfa3_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa3
    ADD CONSTRAINT pospfa3_pospfa3_de_fkey FOREIGN KEY (pospfa3_de) REFERENCES movd.pfa3(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfa3 pospfa3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfa3
    ADD CONSTRAINT pospfa3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfp1 pospfp1_pospfp1_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp1
    ADD CONSTRAINT pospfp1_pospfp1_de_fkey FOREIGN KEY (pospfp1_de) REFERENCES movd.pfp1(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfp1 pospfp1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp1
    ADD CONSTRAINT pospfp1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfp2 pospfp2_pospfp2_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp2
    ADD CONSTRAINT pospfp2_pospfp2_de_fkey FOREIGN KEY (pospfp2_de) REFERENCES movd.pfp2(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfp2 pospfp2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp2
    ADD CONSTRAINT pospfp2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfp3 pospfp3_pospfp3_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp3
    ADD CONSTRAINT pospfp3_pospfp3_de_fkey FOREIGN KEY (pospfp3_de) REFERENCES movd.pfp3(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospfp3 pospfp3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospfp3
    ADD CONSTRAINT pospfp3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posplan posplan_posplan_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posplan
    ADD CONSTRAINT posplan_posplan_de_fkey FOREIGN KEY (posplan_de) REFERENCES movd.aplan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: posplan posplan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.posplan
    ADD CONSTRAINT posplan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_cote pospoint_cote_pospoint_cote_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_cote
    ADD CONSTRAINT pospoint_cote_pospoint_cote_de_fkey FOREIGN KEY (pospoint_cote_de) REFERENCES movd.point_cote(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_cote pospoint_cote_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_cote
    ADD CONSTRAINT pospoint_cote_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_limite pospoint_limite_pospoint_limite_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_limite
    ADD CONSTRAINT pospoint_limite_pospoint_limite_de_fkey FOREIGN KEY (pospoint_limite_de) REFERENCES movd.point_limite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_limite pospoint_limite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_limite
    ADD CONSTRAINT pospoint_limite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_limite_ter pospoint_limite_ter_pospoint_limite_ter_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_limite_ter
    ADD CONSTRAINT pospoint_limite_ter_pospoint_limite_ter_de_fkey FOREIGN KEY (pospoint_limite_ter_de) REFERENCES movd.point_limite_ter(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_limite_ter pospoint_limite_ter_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_limite_ter
    ADD CONSTRAINT pospoint_limite_ter_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_particulier pospoint_particulier_pospoint_particulier_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_particulier
    ADD CONSTRAINT pospoint_particulier_pospoint_particulier_de_fkey FOREIGN KEY (pospoint_particulier_de) REFERENCES movd.point_particulier(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pospoint_particulier pospoint_particulier_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.pospoint_particulier
    ADD CONSTRAINT pospoint_particulier_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: possignal possignal_possignal_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.possignal
    ADD CONSTRAINT possignal_possignal_de_fkey FOREIGN KEY (possignal_de) REFERENCES movd.asignal(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: possignal possignal_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.possignal
    ADD CONSTRAINT possignal_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surface_representation surface_representation_surface_representation_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_representation
    ADD CONSTRAINT surface_representation_surface_representation_de_fkey FOREIGN KEY (surface_representation_de) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surface_representation surface_representation_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_representation
    ADD CONSTRAINT surface_representation_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surface_vide surface_vide_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_vide
    ADD CONSTRAINT surface_vide_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_joural(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surface_vide surface_vide_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surface_vide
    ADD CONSTRAINT surface_vide_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surfacecs surfacecs_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surfacecs
    ADD CONSTRAINT surfacecs_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourcs(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surfacecs surfacecs_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surfacecs
    ADD CONSTRAINT surfacecs_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surfacecsproj surfacecsproj_origine_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surfacecsproj
    ADD CONSTRAINT surfacecsproj_origine_fkey FOREIGN KEY (origine) REFERENCES movd.mise_a_jourcs(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: surfacecsproj surfacecsproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.surfacecsproj
    ADD CONSTRAINT surfacecsproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolebord_de_plan symbolebord_de_plan_symbolebord_de_plan_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolebord_de_plan
    ADD CONSTRAINT symbolebord_de_plan_symbolebord_de_plan_de_fkey FOREIGN KEY (symbolebord_de_plan_de) REFERENCES movd.bord_de_plan(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolebord_de_plan symbolebord_de_plan_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolebord_de_plan
    ADD CONSTRAINT symbolebord_de_plan_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symboleelement_lineaire symboleelement_lineaire_symboleelement_lineaire_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symboleelement_lineaire
    ADD CONSTRAINT symboleelement_lineaire_symboleelement_lineaire_de_fkey FOREIGN KEY (symboleelement_lineaire_de) REFERENCES movd.element_lineaire(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symboleelement_lineaire symboleelement_lineaire_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symboleelement_lineaire
    ADD CONSTRAINT symboleelement_lineaire_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symboleelement_surf symboleelement_surf_symboleelement_surf_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symboleelement_surf
    ADD CONSTRAINT symboleelement_surf_symboleelement_surf_de_fkey FOREIGN KEY (symboleelement_surf_de) REFERENCES movd.element_surfacique(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symboleelement_surf symboleelement_surf_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symboleelement_surf
    ADD CONSTRAINT symboleelement_surf_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepfp1 symbolepfp1_symbolepfp1_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp1
    ADD CONSTRAINT symbolepfp1_symbolepfp1_de_fkey FOREIGN KEY (symbolepfp1_de) REFERENCES movd.pfp1(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepfp1 symbolepfp1_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp1
    ADD CONSTRAINT symbolepfp1_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepfp2 symbolepfp2_symbolepfp2_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp2
    ADD CONSTRAINT symbolepfp2_symbolepfp2_de_fkey FOREIGN KEY (symbolepfp2_de) REFERENCES movd.pfp2(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepfp2 symbolepfp2_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp2
    ADD CONSTRAINT symbolepfp2_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepfp3 symbolepfp3_symbolepfp3_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp3
    ADD CONSTRAINT symbolepfp3_symbolepfp3_de_fkey FOREIGN KEY (symbolepfp3_de) REFERENCES movd.pfp3(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepfp3 symbolepfp3_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepfp3
    ADD CONSTRAINT symbolepfp3_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepoint_limite symbolepoint_limite_symbolepoint_limite_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepoint_limite
    ADD CONSTRAINT symbolepoint_limite_symbolepoint_limite_de_fkey FOREIGN KEY (symbolepoint_limite_de) REFERENCES movd.point_limite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepoint_limite symbolepoint_limite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepoint_limite
    ADD CONSTRAINT symbolepoint_limite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepoint_limite_ter symbolepoint_limite_ter_symbolepoint_limite_ter_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepoint_limite_ter
    ADD CONSTRAINT symbolepoint_limite_ter_symbolepoint_limite_ter_de_fkey FOREIGN KEY (symbolepoint_limite_ter_de) REFERENCES movd.point_limite_ter(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolepoint_limite_ter symbolepoint_limite_ter_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolepoint_limite_ter
    ADD CONSTRAINT symbolepoint_limite_ter_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolesurfacecs symbolesurfacecs_symbolesurfacecs_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolesurfacecs
    ADD CONSTRAINT symbolesurfacecs_symbolesurfacecs_de_fkey FOREIGN KEY (symbolesurfacecs_de) REFERENCES movd.surfacecs(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolesurfacecs symbolesurfacecs_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolesurfacecs
    ADD CONSTRAINT symbolesurfacecs_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolesurfacecsproj symbolesurfacecsproj_symbolesurfcsproj_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolesurfacecsproj
    ADD CONSTRAINT symbolesurfacecsproj_symbolesurfcsproj_de_fkey FOREIGN KEY (symbolesurfcsproj_de) REFERENCES movd.surfacecsproj(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: symbolesurfacecsproj symbolesurfacecsproj_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.symbolesurfacecsproj
    ADD CONSTRAINT symbolesurfacecsproj_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: t_ili2db_basket t_ili2db_basket_dataset_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.t_ili2db_basket
    ADD CONSTRAINT t_ili2db_basket_dataset_fkey FOREIGN KEY (dataset) REFERENCES movd.t_ili2db_dataset(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: texte_groupement_de_localite texte_groupement_de_lclite_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.texte_groupement_de_localite
    ADD CONSTRAINT texte_groupement_de_lclite_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: texte_groupement_de_localite texte_groupement_de_lclite_texte_groupement_d_lclt_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.texte_groupement_de_localite
    ADD CONSTRAINT texte_groupement_de_lclite_texte_groupement_d_lclt_de_fkey FOREIGN KEY (texte_groupement_de_localite_de) REFERENCES movd.groupement_de_localite(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: troncon_rue troncon_rue_t_basket_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.troncon_rue
    ADD CONSTRAINT troncon_rue_t_basket_fkey FOREIGN KEY (t_basket) REFERENCES movd.t_ili2db_basket(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: troncon_rue troncon_rue_troncon_rue_de_fkey; Type: FK CONSTRAINT; Schema: movd; Owner: gc_transfert_dbo
--

ALTER TABLE ONLY movd.troncon_rue
    ADD CONSTRAINT troncon_rue_troncon_rue_de_fkey FOREIGN KEY (troncon_rue_de) REFERENCES movd.localisation(fid) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: TABLE ch_histo_nbr_habi_par_adr; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.ch_histo_nbr_habi_par_adr TO readers;


--
-- Name: TABLE dico_cprue_ls; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.dico_cprue_ls TO readers;


--
-- Name: TABLE lien_arbre_espece_cultivar; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.lien_arbre_espece_cultivar TO readers;


--
-- Name: TABLE lien_arbre_genre_espece; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.lien_arbre_genre_espece TO readers;


--
-- Name: TABLE parcelle; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.parcelle TO readers;


--
-- Name: TABLE parcelle_dico_type; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.parcelle_dico_type TO readers;


--
-- Name: TABLE thi_arbre; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre TO readers;


--
-- Name: TABLE thi_arbre_cultivar; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre_cultivar TO readers;


--
-- Name: TABLE thi_arbre_diam_couronne; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre_diam_couronne TO readers;


--
-- Name: TABLE thi_arbre_espece; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre_espece TO readers;


--
-- Name: TABLE thi_arbre_genre; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre_genre TO readers;


--
-- Name: TABLE thi_arbre_hauteur; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre_hauteur TO readers;


--
-- Name: TABLE thi_arbre_validation; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_arbre_validation TO readers;


--
-- Name: TABLE thi_building; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_building TO readers;


--
-- Name: TABLE thi_building_bat_principal; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_building_bat_principal TO readers;


--
-- Name: TABLE thi_building_egid; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_building_egid TO readers;


--
-- Name: TABLE thi_building_no_eca; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_building_no_eca TO readers;


--
-- Name: TABLE thi_sondage_geo_therm; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_sondage_geo_therm TO readers;


--
-- Name: TABLE thi_street; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_street TO readers;


--
-- Name: TABLE thi_street_building_address; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thi_street_building_address TO readers;


--
-- Name: TABLE thing; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thing TO readers;


--
-- Name: TABLE thing_position; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.thing_position TO readers;


--
-- Name: TABLE type_thi_street; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.type_thi_street TO readers;


--
-- Name: TABLE type_thing; Type: ACL; Schema: goeland; Owner: goeland
--

GRANT SELECT ON TABLE goeland.type_thing TO readers;


--
-- PostgreSQL database dump complete
--

