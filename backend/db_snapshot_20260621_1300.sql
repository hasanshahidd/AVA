--
-- PostgreSQL database dump
--

\restrict Jr683SeL7g4HpH12qooIzSA39cjwarLyCuWUn1KpW6qAHflkwFgslHYvH269eqG

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: grc_ai_evidence_recommendations; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_ai_evidence_recommendations (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    group_id integer,
    normalized_control_id integer,
    framework_control_id integer,
    parsed_control_id integer,
    evidence_type character varying(100) NOT NULL,
    evidence_description text,
    priority character varying(20) NOT NULL,
    ai_confidence double precision,
    ai_reasoning text,
    sample_evidence_names json,
    created_at timestamp without time zone
);


ALTER TABLE public.grc_ai_evidence_recommendations OWNER TO grc_app;

--
-- Name: grc_ai_evidence_recommendations_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_ai_evidence_recommendations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_ai_evidence_recommendations_id_seq OWNER TO grc_app;

--
-- Name: grc_ai_evidence_recommendations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_ai_evidence_recommendations_id_seq OWNED BY public.grc_ai_evidence_recommendations.id;


--
-- Name: grc_common_control_group_mappings; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_common_control_group_mappings (
    id integer NOT NULL,
    group_id integer NOT NULL,
    normalized_control_id integer,
    framework_control_id integer,
    parsed_control_id integer,
    mapping_confidence double precision,
    mapping_source character varying(50) NOT NULL,
    created_at timestamp without time zone
);


ALTER TABLE public.grc_common_control_group_mappings OWNER TO grc_app;

--
-- Name: grc_common_control_group_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_common_control_group_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_common_control_group_mappings_id_seq OWNER TO grc_app;

--
-- Name: grc_common_control_group_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_common_control_group_mappings_id_seq OWNED BY public.grc_common_control_group_mappings.id;


--
-- Name: grc_common_control_groups; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_common_control_groups (
    id integer NOT NULL,
    tenant_id integer,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    category character varying(100),
    domain character varying(100),
    keywords json,
    ai_summary text,
    evidence_types json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_by integer,
    run_id integer
);


ALTER TABLE public.grc_common_control_groups OWNER TO grc_app;

--
-- Name: grc_common_control_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_common_control_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_common_control_groups_id_seq OWNER TO grc_app;

--
-- Name: grc_common_control_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_common_control_groups_id_seq OWNED BY public.grc_common_control_groups.id;


--
-- Name: grc_evidence_control_mappings; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_evidence_control_mappings (
    id integer NOT NULL,
    evidence_id integer NOT NULL,
    normalized_control_id integer,
    framework_control_id integer,
    parsed_control_id integer,
    uploaded_framework_id integer,
    framework_name character varying(255),
    control_code character varying(100),
    clause_reference character varying(255),
    control_title character varying(500),
    matching_rationale text,
    confidence_score double precision,
    coverage_type character varying(50),
    matched_text_snippets json,
    matched_control_language text,
    similarity_score double precision,
    rule_based_validation boolean,
    is_locked boolean,
    locked_at timestamp without time zone,
    locked_by integer,
    created_at timestamp without time zone,
    created_by_ai boolean,
    assessment_id integer
);


ALTER TABLE public.grc_evidence_control_mappings OWNER TO grc_app;

--
-- Name: grc_evidence_control_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_evidence_control_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_evidence_control_mappings_id_seq OWNER TO grc_app;

--
-- Name: grc_evidence_control_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_evidence_control_mappings_id_seq OWNED BY public.grc_evidence_control_mappings.id;


--
-- Name: grc_normalization_runs; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_normalization_runs (
    id integer NOT NULL,
    tenant_id integer NOT NULL,
    label character varying(255),
    scope character varying(20),
    framework_ids json,
    status character varying(20),
    is_baseline boolean,
    created_by integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    summary json
);


ALTER TABLE public.grc_normalization_runs OWNER TO grc_app;

--
-- Name: grc_normalization_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_normalization_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_normalization_runs_id_seq OWNER TO grc_app;

--
-- Name: grc_normalization_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_normalization_runs_id_seq OWNED BY public.grc_normalization_runs.id;


--
-- Name: grc_normalized_control_links; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_normalized_control_links (
    id integer NOT NULL,
    normalized_control_id integer NOT NULL,
    parsed_control_id integer,
    framework_control_id integer,
    mapping_type character varying(20),
    created_at timestamp without time zone
);


ALTER TABLE public.grc_normalized_control_links OWNER TO grc_app;

--
-- Name: grc_normalized_control_links_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_normalized_control_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_normalized_control_links_id_seq OWNER TO grc_app;

--
-- Name: grc_normalized_control_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_normalized_control_links_id_seq OWNED BY public.grc_normalized_control_links.id;


--
-- Name: grc_normalized_controls; Type: TABLE; Schema: public; Owner: grc_app
--

CREATE TABLE public.grc_normalized_controls (
    id integer NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    statement text,
    objective text,
    control_owner character varying(255),
    implementation_guidance text,
    testing_guidance text,
    maturity_level integer,
    created_at timestamp without time zone,
    domain character varying(255),
    source character varying(50),
    common_group_id integer,
    recommended_evidence jsonb,
    run_id integer,
    review_status character varying(20),
    reviewed_by integer,
    reviewed_at timestamp without time zone
);


ALTER TABLE public.grc_normalized_controls OWNER TO grc_app;

--
-- Name: grc_normalized_controls_id_seq; Type: SEQUENCE; Schema: public; Owner: grc_app
--

CREATE SEQUENCE public.grc_normalized_controls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grc_normalized_controls_id_seq OWNER TO grc_app;

--
-- Name: grc_normalized_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: grc_app
--

ALTER SEQUENCE public.grc_normalized_controls_id_seq OWNED BY public.grc_normalized_controls.id;


--
-- Name: grc_ai_evidence_recommendations id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations ALTER COLUMN id SET DEFAULT nextval('public.grc_ai_evidence_recommendations_id_seq'::regclass);


--
-- Name: grc_common_control_group_mappings id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings ALTER COLUMN id SET DEFAULT nextval('public.grc_common_control_group_mappings_id_seq'::regclass);


--
-- Name: grc_common_control_groups id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_groups ALTER COLUMN id SET DEFAULT nextval('public.grc_common_control_groups_id_seq'::regclass);


--
-- Name: grc_evidence_control_mappings id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings ALTER COLUMN id SET DEFAULT nextval('public.grc_evidence_control_mappings_id_seq'::regclass);


--
-- Name: grc_normalization_runs id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalization_runs ALTER COLUMN id SET DEFAULT nextval('public.grc_normalization_runs_id_seq'::regclass);


--
-- Name: grc_normalized_control_links id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_control_links ALTER COLUMN id SET DEFAULT nextval('public.grc_normalized_control_links_id_seq'::regclass);


--
-- Name: grc_normalized_controls id; Type: DEFAULT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_controls ALTER COLUMN id SET DEFAULT nextval('public.grc_normalized_controls_id_seq'::regclass);


--
-- Data for Name: grc_ai_evidence_recommendations; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_ai_evidence_recommendations (id, tenant_id, group_id, normalized_control_id, framework_control_id, parsed_control_id, evidence_type, evidence_description, priority, ai_confidence, ai_reasoning, sample_evidence_names, created_at) FROM stdin;
\.


--
-- Data for Name: grc_common_control_group_mappings; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_common_control_group_mappings (id, group_id, normalized_control_id, framework_control_id, parsed_control_id, mapping_confidence, mapping_source, created_at) FROM stdin;
32815	1320	\N	\N	1480	1	standalone	2026-06-20 19:55:00.727524
32816	1304	\N	\N	2843	1	standalone	2026-06-20 19:55:00.727524
32817	1303	\N	\N	411	1	standalone	2026-06-20 19:55:00.727524
32818	1313	\N	\N	2471	1	standalone	2026-06-20 19:55:00.727524
32819	1320	\N	\N	1055	1	standalone	2026-06-20 19:55:00.727524
32820	1304	\N	\N	1740	1	standalone	2026-06-20 19:55:00.727524
32821	1309	\N	\N	1147	1	standalone	2026-06-20 19:55:00.727524
32822	1313	\N	\N	755	1	standalone	2026-06-20 19:55:00.727524
32823	1304	\N	\N	4	1	standalone	2026-06-20 19:55:00.727524
32824	1305	\N	\N	1606	1	standalone	2026-06-20 19:55:00.727524
32825	1312	\N	\N	2630	1	standalone	2026-06-20 19:55:00.727524
32826	1320	\N	\N	2784	1	standalone	2026-06-20 19:55:00.727524
32827	1308	\N	\N	199	1	standalone	2026-06-20 19:55:00.727524
32828	1307	\N	\N	1858	1	standalone	2026-06-20 19:55:00.727524
32829	1304	\N	\N	352	1	standalone	2026-06-20 19:55:00.727524
32830	1304	\N	\N	947	1	standalone	2026-06-20 19:55:00.727524
32831	1307	\N	\N	3104	1	standalone	2026-06-20 19:55:00.727524
32832	1303	\N	\N	3223	1	standalone	2026-06-20 19:55:00.727524
32833	1304	\N	\N	3249	1	standalone	2026-06-20 19:55:00.727524
32834	1306	\N	\N	681	1	standalone	2026-06-20 19:55:00.727524
32835	1303	\N	\N	6999	1	standalone	2026-06-20 19:55:00.727524
32836	1304	\N	\N	595	1	standalone	2026-06-20 19:55:00.727524
32837	1304	\N	\N	1569	1	standalone	2026-06-20 19:55:00.727524
32838	1303	\N	\N	647	1	standalone	2026-06-20 19:55:00.727524
32839	1310	\N	\N	1848	1	standalone	2026-06-20 19:55:00.727524
32840	1307	\N	\N	3370	1	standalone	2026-06-20 19:55:00.727524
32841	1320	\N	\N	3333	1	standalone	2026-06-20 19:55:00.727524
32842	1311	\N	\N	915	1	standalone	2026-06-20 19:55:00.727524
32843	1303	\N	\N	2585	1	standalone	2026-06-20 19:55:00.727524
32844	1304	\N	\N	165	1	standalone	2026-06-20 19:55:00.727524
32845	1303	\N	\N	1343	1	standalone	2026-06-20 19:55:00.727524
32846	1304	\N	\N	2844	1	standalone	2026-06-20 19:55:00.727524
32847	1304	\N	\N	417	1	standalone	2026-06-20 19:55:00.727524
32848	1318	\N	\N	2345	1	standalone	2026-06-20 19:55:00.727524
32849	1320	\N	\N	1075	1	standalone	2026-06-20 19:55:00.727524
32850	1304	\N	\N	1741	1	standalone	2026-06-20 19:55:00.727524
32851	1305	\N	\N	1182	1	standalone	2026-06-20 19:55:00.727524
32852	1305	\N	\N	758	1	standalone	2026-06-20 19:55:00.727524
32853	1314	\N	\N	12	1	standalone	2026-06-20 19:55:00.727524
32854	1318	\N	\N	1663	1	standalone	2026-06-20 19:55:00.727524
32855	1304	\N	\N	2635	1	standalone	2026-06-20 19:55:00.727524
32856	1312	\N	\N	2785	1	standalone	2026-06-20 19:55:00.727524
32857	1309	\N	\N	204	1	standalone	2026-06-20 19:55:00.727524
32858	1305	\N	\N	1864	1	standalone	2026-06-20 19:55:00.727524
32859	1304	\N	\N	354	1	standalone	2026-06-20 19:55:00.727524
32860	1304	\N	\N	948	1	standalone	2026-06-20 19:55:00.727524
32861	1307	\N	\N	3105	1	standalone	2026-06-20 19:55:00.727524
32862	1313	\N	\N	3198	1	standalone	2026-06-20 19:55:00.727524
32863	1304	\N	\N	3251	1	standalone	2026-06-20 19:55:00.727524
32864	1303	\N	\N	692	1	standalone	2026-06-20 19:55:00.727524
32865	1303	\N	\N	7000	1	standalone	2026-06-20 19:55:00.727524
32866	1307	\N	\N	596	1	standalone	2026-06-20 19:55:00.727524
32867	1304	\N	\N	1571	1	standalone	2026-06-20 19:55:00.727524
32868	1303	\N	\N	648	1	standalone	2026-06-20 19:55:00.727524
32869	1306	\N	\N	1850	1	standalone	2026-06-20 19:55:00.727524
32870	1307	\N	\N	3371	1	standalone	2026-06-20 19:55:00.727524
32871	1320	\N	\N	3344	1	standalone	2026-06-20 19:55:00.727524
32872	1320	\N	\N	919	1	standalone	2026-06-20 19:55:00.727524
32873	1304	\N	\N	2610	1	standalone	2026-06-20 19:55:00.727524
32874	1306	\N	\N	196	1	standalone	2026-06-20 19:55:00.727524
32875	1303	\N	\N	1345	1	standalone	2026-06-20 19:55:00.727524
32876	1304	\N	\N	2847	1	standalone	2026-06-20 19:55:00.727524
32877	1304	\N	\N	391	1	standalone	2026-06-20 19:55:00.727524
32878	1307	\N	\N	2454	1	standalone	2026-06-20 19:55:00.727524
32879	1320	\N	\N	1076	1	standalone	2026-06-20 19:55:00.727524
32880	1304	\N	\N	1745	1	standalone	2026-06-20 19:55:00.727524
32881	1305	\N	\N	1183	1	standalone	2026-06-20 19:55:00.727524
32882	1305	\N	\N	759	1	standalone	2026-06-20 19:55:00.727524
32883	1314	\N	\N	18	1	standalone	2026-06-20 19:55:00.727524
32884	1318	\N	\N	1665	1	standalone	2026-06-20 19:55:00.727524
32885	1304	\N	\N	2636	1	standalone	2026-06-20 19:55:00.727524
32886	1312	\N	\N	2786	1	standalone	2026-06-20 19:55:00.727524
32887	1309	\N	\N	208	1	standalone	2026-06-20 19:55:00.727524
32888	1307	\N	\N	1865	1	standalone	2026-06-20 19:55:00.727524
32889	1304	\N	\N	355	1	standalone	2026-06-20 19:55:00.727524
32890	1304	\N	\N	949	1	standalone	2026-06-20 19:55:00.727524
32891	1307	\N	\N	3107	1	standalone	2026-06-20 19:55:00.727524
32892	1320	\N	\N	3199	1	standalone	2026-06-20 19:55:00.727524
32893	1304	\N	\N	3252	1	standalone	2026-06-20 19:55:00.727524
32894	1303	\N	\N	703	1	standalone	2026-06-20 19:55:00.727524
32895	1303	\N	\N	7001	1	standalone	2026-06-20 19:55:00.727524
32896	1320	\N	\N	593	1	standalone	2026-06-20 19:55:00.727524
32897	1320	\N	\N	1572	1	standalone	2026-06-20 19:55:00.727524
32898	1303	\N	\N	649	1	standalone	2026-06-20 19:55:00.727524
32899	1306	\N	\N	1852	1	standalone	2026-06-20 19:55:00.727524
32900	1307	\N	\N	3368	1	standalone	2026-06-20 19:55:00.727524
32901	1308	\N	\N	3347	1	standalone	2026-06-20 19:55:00.727524
32902	1311	\N	\N	928	1	standalone	2026-06-20 19:55:00.727524
32903	1312	\N	\N	2612	1	standalone	2026-06-20 19:55:00.727524
32904	1303	\N	\N	1347	1	standalone	2026-06-20 19:55:00.727524
32905	1304	\N	\N	2848	1	standalone	2026-06-20 19:55:00.727524
32906	1304	\N	\N	392	1	standalone	2026-06-20 19:55:00.727524
32907	1314	\N	\N	2088	1	standalone	2026-06-20 19:55:00.727524
32908	1320	\N	\N	1077	1	standalone	2026-06-20 19:55:00.727524
32909	1320	\N	\N	1746	1	standalone	2026-06-20 19:55:00.727524
32910	1320	\N	\N	1132	1	standalone	2026-06-20 19:55:00.727524
32911	1309	\N	\N	767	1	standalone	2026-06-20 19:55:00.727524
32912	1312	\N	\N	23	1	standalone	2026-06-20 19:55:00.727524
32913	1305	\N	\N	1626	1	standalone	2026-06-20 19:55:00.727524
32914	1304	\N	\N	2641	1	standalone	2026-06-20 19:55:00.727524
32915	1312	\N	\N	2787	1	standalone	2026-06-20 19:55:00.727524
32916	1309	\N	\N	209	1	standalone	2026-06-20 19:55:00.727524
32917	1303	\N	\N	1888	1	standalone	2026-06-20 19:55:00.727524
32918	1304	\N	\N	357	1	standalone	2026-06-20 19:55:00.727524
32919	1309	\N	\N	951	1	standalone	2026-06-20 19:55:00.727524
32920	1305	\N	\N	3108	1	standalone	2026-06-20 19:55:00.727524
32921	1313	\N	\N	3202	1	standalone	2026-06-20 19:55:00.727524
32922	1315	\N	\N	3253	1	standalone	2026-06-20 19:55:00.727524
32923	1320	\N	\N	708	1	standalone	2026-06-20 19:55:00.727524
32924	1303	\N	\N	7002	1	standalone	2026-06-20 19:55:00.727524
32925	1304	\N	\N	587	1	standalone	2026-06-20 19:55:00.727524
32926	1312	\N	\N	1578	1	standalone	2026-06-20 19:55:00.727524
32927	1303	\N	\N	668	1	standalone	2026-06-20 19:55:00.727524
32928	1306	\N	\N	1853	1	standalone	2026-06-20 19:55:00.727524
32929	1307	\N	\N	3375	1	standalone	2026-06-20 19:55:00.727524
32930	1308	\N	\N	3349	1	standalone	2026-06-20 19:55:00.727524
32931	1303	\N	\N	1365	1	standalone	2026-06-20 19:55:00.727524
32932	1304	\N	\N	2849	1	standalone	2026-06-20 19:55:00.727524
32933	1304	\N	\N	393	1	standalone	2026-06-20 19:55:00.727524
32934	1304	\N	\N	2072	1	standalone	2026-06-20 19:55:00.727524
32935	1320	\N	\N	1085	1	standalone	2026-06-20 19:55:00.727524
32936	1320	\N	\N	1747	1	standalone	2026-06-20 19:55:00.727524
32937	1315	\N	\N	1133	1	standalone	2026-06-20 19:55:00.727524
32938	1314	\N	\N	773	1	standalone	2026-06-20 19:55:00.727524
32939	1303	\N	\N	26	1	standalone	2026-06-20 19:55:00.727524
32940	1309	\N	\N	1637	1	standalone	2026-06-20 19:55:00.727524
32941	1304	\N	\N	2642	1	standalone	2026-06-20 19:55:00.727524
32942	1305	\N	\N	2802	1	standalone	2026-06-20 19:55:00.727524
32943	1303	\N	\N	217	1	standalone	2026-06-20 19:55:00.727524
32944	1303	\N	\N	1922	1	standalone	2026-06-20 19:55:00.727524
32945	1304	\N	\N	358	1	standalone	2026-06-20 19:55:00.727524
32946	1312	\N	\N	962	1	standalone	2026-06-20 19:55:00.727524
32947	1304	\N	\N	3111	1	standalone	2026-06-20 19:55:00.727524
32948	1320	\N	\N	3180	1	standalone	2026-06-20 19:55:00.727524
32949	1315	\N	\N	3254	1	standalone	2026-06-20 19:55:00.727524
32950	1303	\N	\N	709	1	standalone	2026-06-20 19:55:00.727524
32951	1303	\N	\N	7003	1	standalone	2026-06-20 19:55:00.727524
32952	1304	\N	\N	588	1	standalone	2026-06-20 19:55:00.727524
32953	1306	\N	\N	1579	1	standalone	2026-06-20 19:55:00.727524
32954	1303	\N	\N	671	1	standalone	2026-06-20 19:55:00.727524
32955	1303	\N	\N	1814	1	standalone	2026-06-20 19:55:00.727524
32956	1312	\N	\N	3379	1	standalone	2026-06-20 19:55:00.727524
32957	1320	\N	\N	3361	1	standalone	2026-06-20 19:55:00.727524
32958	1303	\N	\N	1366	1	standalone	2026-06-20 19:55:00.727524
32959	1304	\N	\N	2850	1	standalone	2026-06-20 19:55:00.727524
32960	1304	\N	\N	394	1	standalone	2026-06-20 19:55:00.727524
32961	1304	\N	\N	2075	1	standalone	2026-06-20 19:55:00.727524
32962	1320	\N	\N	1038	1	standalone	2026-06-20 19:55:00.727524
32963	1317	\N	\N	1748	1	standalone	2026-06-20 19:55:00.727524
32964	1304	\N	\N	1136	1	standalone	2026-06-20 19:55:00.727524
32965	1314	\N	\N	777	1	standalone	2026-06-20 19:55:00.727524
32966	1303	\N	\N	27	1	standalone	2026-06-20 19:55:00.727524
32967	1309	\N	\N	1638	1	standalone	2026-06-20 19:55:00.727524
32968	1304	\N	\N	2647	1	standalone	2026-06-20 19:55:00.727524
32969	1312	\N	\N	2788	1	standalone	2026-06-20 19:55:00.727524
32970	1303	\N	\N	221	1	standalone	2026-06-20 19:55:00.727524
32971	1309	\N	\N	1923	1	standalone	2026-06-20 19:55:00.727524
32972	1304	\N	\N	359	1	standalone	2026-06-20 19:55:00.727524
32973	1312	\N	\N	963	1	standalone	2026-06-20 19:55:00.727524
32974	1308	\N	\N	3112	1	standalone	2026-06-20 19:55:00.727524
32975	1304	\N	\N	3170	1	standalone	2026-06-20 19:55:00.727524
32976	1304	\N	\N	3255	1	standalone	2026-06-20 19:55:00.727524
32977	1304	\N	\N	710	1	standalone	2026-06-20 19:55:00.727524
32978	1303	\N	\N	7006	1	standalone	2026-06-20 19:55:00.727524
32979	1306	\N	\N	617	1	standalone	2026-06-20 19:55:00.727524
32980	1304	\N	\N	1580	1	standalone	2026-06-20 19:55:00.727524
32981	1303	\N	\N	672	1	standalone	2026-06-20 19:55:00.727524
32982	1312	\N	\N	1816	1	standalone	2026-06-20 19:55:00.727524
32983	1309	\N	\N	3397	1	standalone	2026-06-20 19:55:00.727524
32984	1315	\N	\N	3367	1	standalone	2026-06-20 19:55:00.727524
32985	1303	\N	\N	1371	1	standalone	2026-06-20 19:55:00.727524
32986	1304	\N	\N	2854	1	standalone	2026-06-20 19:55:00.727524
32987	1304	\N	\N	395	1	standalone	2026-06-20 19:55:00.727524
32988	1304	\N	\N	2076	1	standalone	2026-06-20 19:55:00.727524
32989	1317	\N	\N	1052	1	standalone	2026-06-20 19:55:00.727524
32990	1304	\N	\N	1749	1	standalone	2026-06-20 19:55:00.727524
32991	1318	\N	\N	1137	1	standalone	2026-06-20 19:55:00.727524
32992	1314	\N	\N	780	1	standalone	2026-06-20 19:55:00.727524
32993	1308	\N	\N	30	1	standalone	2026-06-20 19:55:00.727524
32994	1311	\N	\N	1640	1	standalone	2026-06-20 19:55:00.727524
32995	1312	\N	\N	2650	1	standalone	2026-06-20 19:55:00.727524
32996	1312	\N	\N	2789	1	standalone	2026-06-20 19:55:00.727524
32997	1305	\N	\N	230	1	standalone	2026-06-20 19:55:00.727524
32998	1303	\N	\N	1938	1	standalone	2026-06-20 19:55:00.727524
32999	1304	\N	\N	360	1	standalone	2026-06-20 19:55:00.727524
33000	1312	\N	\N	964	1	standalone	2026-06-20 19:55:00.727524
33001	1305	\N	\N	3135	1	standalone	2026-06-20 19:55:00.727524
33002	1304	\N	\N	3173	1	standalone	2026-06-20 19:55:00.727524
33003	1310	\N	\N	3287	1	standalone	2026-06-20 19:55:00.727524
33004	1313	\N	\N	715	1	standalone	2026-06-20 19:55:00.727524
33005	1303	\N	\N	7012	1	standalone	2026-06-20 19:55:00.727524
33006	1311	\N	\N	618	1	standalone	2026-06-20 19:55:00.727524
33007	1304	\N	\N	1581	1	standalone	2026-06-20 19:55:00.727524
33008	1304	\N	\N	680	1	standalone	2026-06-20 19:55:00.727524
33009	1304	\N	\N	1817	1	standalone	2026-06-20 19:55:00.727524
33010	1317	\N	\N	1376	1	standalone	2026-06-20 19:55:00.727524
33011	1315	\N	\N	2857	1	standalone	2026-06-20 19:55:00.727524
33012	1304	\N	\N	397	1	standalone	2026-06-20 19:55:00.727524
33013	1304	\N	\N	2079	1	standalone	2026-06-20 19:55:00.727524
33014	1309	\N	\N	1086	1	standalone	2026-06-20 19:55:00.727524
33015	1304	\N	\N	1750	1	standalone	2026-06-20 19:55:00.727524
33016	1306	\N	\N	1141	1	standalone	2026-06-20 19:55:00.727524
33017	1303	\N	\N	793	1	standalone	2026-06-20 19:55:00.727524
33018	1313	\N	\N	33	1	standalone	2026-06-20 19:55:00.727524
33019	1317	\N	\N	1641	1	standalone	2026-06-20 19:55:00.727524
33020	1304	\N	\N	2651	1	standalone	2026-06-20 19:55:00.727524
33021	1312	\N	\N	2790	1	standalone	2026-06-20 19:55:00.727524
33022	1319	\N	\N	231	1	standalone	2026-06-20 19:55:00.727524
33023	1303	\N	\N	1991	1	standalone	2026-06-20 19:55:00.727524
33024	1304	\N	\N	361	1	standalone	2026-06-20 19:55:00.727524
33025	1312	\N	\N	966	1	standalone	2026-06-20 19:55:00.727524
33026	1310	\N	\N	3137	1	standalone	2026-06-20 19:55:00.727524
33027	1304	\N	\N	3174	1	standalone	2026-06-20 19:55:00.727524
33028	1304	\N	\N	3257	1	standalone	2026-06-20 19:55:00.727524
33029	1305	\N	\N	716	1	standalone	2026-06-20 19:55:00.727524
33030	1303	\N	\N	7013	1	standalone	2026-06-20 19:55:00.727524
33031	1311	\N	\N	619	1	standalone	2026-06-20 19:55:00.727524
33032	1304	\N	\N	1582	1	standalone	2026-06-20 19:55:00.727524
33033	1317	\N	\N	1377	1	standalone	2026-06-20 19:55:00.727524
33034	1304	\N	\N	2858	1	standalone	2026-06-20 19:55:00.727524
33035	1304	\N	\N	398	1	standalone	2026-06-20 19:55:00.727524
33036	1304	\N	\N	2080	1	standalone	2026-06-20 19:55:00.727524
33037	1309	\N	\N	1101	1	standalone	2026-06-20 19:55:00.727524
33038	1304	\N	\N	1751	1	standalone	2026-06-20 19:55:00.727524
33039	1312	\N	\N	1142	1	standalone	2026-06-20 19:55:00.727524
33040	1304	\N	\N	794	1	standalone	2026-06-20 19:55:00.727524
33041	1319	\N	\N	34	1	standalone	2026-06-20 19:55:00.727524
33042	1311	\N	\N	1642	1	standalone	2026-06-20 19:55:00.727524
33043	1305	\N	\N	2668	1	standalone	2026-06-20 19:55:00.727524
33044	1312	\N	\N	2791	1	standalone	2026-06-20 19:55:00.727524
33045	1305	\N	\N	235	1	standalone	2026-06-20 19:55:00.727524
33046	1303	\N	\N	1992	1	standalone	2026-06-20 19:55:00.727524
33047	1304	\N	\N	363	1	standalone	2026-06-20 19:55:00.727524
33048	1315	\N	\N	971	1	standalone	2026-06-20 19:55:00.727524
33049	1312	\N	\N	3139	1	standalone	2026-06-20 19:55:00.727524
33050	1304	\N	\N	3175	1	standalone	2026-06-20 19:55:00.727524
33051	1304	\N	\N	3260	1	standalone	2026-06-20 19:55:00.727524
33052	1313	\N	\N	721	1	standalone	2026-06-20 19:55:00.727524
33053	1303	\N	\N	7014	1	standalone	2026-06-20 19:55:00.727524
33054	1319	\N	\N	620	1	standalone	2026-06-20 19:55:00.727524
33055	1320	\N	\N	1583	1	standalone	2026-06-20 19:55:00.727524
33056	1303	\N	\N	1379	1	standalone	2026-06-20 19:55:00.727524
33057	1304	\N	\N	2859	1	standalone	2026-06-20 19:55:00.727524
33058	1320	\N	\N	399	1	standalone	2026-06-20 19:55:00.727524
33059	1315	\N	\N	2082	1	standalone	2026-06-20 19:55:00.727524
33060	1304	\N	\N	1037	1	standalone	2026-06-20 19:55:00.727524
33061	1317	\N	\N	1752	1	standalone	2026-06-20 19:55:00.727524
33062	1312	\N	\N	1143	1	standalone	2026-06-20 19:55:00.727524
33063	1320	\N	\N	795	1	standalone	2026-06-20 19:55:00.727524
33064	1320	\N	\N	44	1	standalone	2026-06-20 19:55:00.727524
33065	1305	\N	\N	1650	1	standalone	2026-06-20 19:55:00.727524
33066	1307	\N	\N	2669	1	standalone	2026-06-20 19:55:00.727524
33067	1312	\N	\N	2792	1	standalone	2026-06-20 19:55:00.727524
33068	1318	\N	\N	260	1	standalone	2026-06-20 19:55:00.727524
30234	1303	\N	\N	7004	1	domain	2026-06-20 19:40:05.720723
30235	1303	\N	\N	7005	1	domain	2026-06-20 19:40:05.720723
30236	1303	\N	\N	7007	1	domain	2026-06-20 19:40:05.720723
30237	1303	\N	\N	7008	1	domain	2026-06-20 19:40:05.720723
30238	1303	\N	\N	957	1	domain	2026-06-20 19:40:05.720723
30239	1303	\N	\N	7015	1	domain	2026-06-20 19:40:05.720723
30240	1303	\N	\N	3339	1	domain	2026-06-20 19:40:05.720723
30241	1303	\N	\N	673	1	domain	2026-06-20 19:40:05.720723
30242	1303	\N	\N	674	1	domain	2026-06-20 19:40:05.720723
30243	1303	\N	\N	675	1	domain	2026-06-20 19:40:05.720723
30244	1303	\N	\N	677	1	domain	2026-06-20 19:40:05.720723
30246	1303	\N	\N	1834	1	domain	2026-06-20 19:40:05.72824
30247	1303	\N	\N	205	1	domain	2026-06-20 19:40:05.72824
30248	1303	\N	\N	3272	1	domain	2026-06-20 19:40:05.72824
30249	1303	\N	\N	1895	1	domain	2026-06-20 19:40:05.72824
30250	1303	\N	\N	2093	1	domain	2026-06-20 19:40:05.72824
30251	1303	\N	\N	1014	1	domain	2026-06-20 19:40:05.72824
30252	1303	\N	\N	3240	1	domain	2026-06-20 19:40:05.72824
30253	1303	\N	\N	101	1	domain	2026-06-20 19:40:05.72824
30254	1303	\N	\N	2358	1	domain	2026-06-20 19:40:05.72824
30256	1303	\N	\N	607	1	domain	2026-06-20 19:40:05.72824
30257	1303	\N	\N	606	1	domain	2026-06-20 19:40:05.72824
30258	1303	\N	\N	1837	1	domain	2026-06-20 19:40:05.72824
30259	1303	\N	\N	2597	1	domain	2026-06-20 19:40:05.72824
30260	1303	\N	\N	3334	1	domain	2026-06-20 19:40:05.72824
30261	1303	\N	\N	190	1	domain	2026-06-20 19:40:05.72824
30262	1303	\N	\N	1223	1	domain	2026-06-20 19:40:05.72824
30263	1303	\N	\N	1015	1	domain	2026-06-20 19:40:05.72824
30264	1303	\N	\N	284	1	domain	2026-06-20 19:40:05.72824
30265	1303	\N	\N	2930	1	domain	2026-06-20 19:40:05.72824
30266	1303	\N	\N	839	1	domain	2026-06-20 19:40:05.72824
30267	1303	\N	\N	94	1	domain	2026-06-20 19:40:05.72824
30268	1303	\N	\N	1224	1	domain	2026-06-20 19:40:05.72824
30269	1303	\N	\N	1225	1	domain	2026-06-20 19:40:05.72824
30270	1303	\N	\N	1226	1	domain	2026-06-20 19:40:05.72824
30271	1303	\N	\N	1424	1	domain	2026-06-20 19:40:05.72824
30272	1303	\N	\N	2003	1	domain	2026-06-20 19:40:05.72824
30274	1303	\N	\N	642	1	domain	2026-06-20 19:40:05.72824
30275	1303	\N	\N	2827	1	domain	2026-06-20 19:40:05.72824
30276	1303	\N	\N	3297	1	domain	2026-06-20 19:40:05.72824
30277	1303	\N	\N	468	1	domain	2026-06-20 19:40:05.72824
30278	1303	\N	\N	891	1	domain	2026-06-20 19:40:05.72824
30279	1303	\N	\N	892	1	domain	2026-06-20 19:40:05.72824
30281	1303	\N	\N	654	1	domain	2026-06-20 19:40:05.736794
30282	1303	\N	\N	679	1	domain	2026-06-20 19:40:05.736794
30283	1303	\N	\N	650	1	domain	2026-06-20 19:40:05.736794
30284	1303	\N	\N	7009	1	domain	2026-06-20 19:40:05.736794
30285	1303	\N	\N	651	1	domain	2026-06-20 19:40:05.736794
30286	1303	\N	\N	7010	1	domain	2026-06-20 19:40:05.736794
30287	1303	\N	\N	652	1	domain	2026-06-20 19:40:05.736794
30288	1303	\N	\N	653	1	domain	2026-06-20 19:40:05.736794
30289	1303	\N	\N	655	1	domain	2026-06-20 19:40:05.736794
30290	1303	\N	\N	656	1	domain	2026-06-20 19:40:05.736794
30291	1303	\N	\N	657	1	domain	2026-06-20 19:40:05.736794
30292	1303	\N	\N	658	1	domain	2026-06-20 19:40:05.736794
30293	1303	\N	\N	659	1	domain	2026-06-20 19:40:05.736794
30294	1303	\N	\N	412	1	domain	2026-06-20 19:40:05.736794
30295	1303	\N	\N	414	1	domain	2026-06-20 19:40:05.736794
30296	1303	\N	\N	666	1	domain	2026-06-20 19:40:05.736794
30297	1303	\N	\N	667	1	domain	2026-06-20 19:40:05.736794
30298	1303	\N	\N	678	1	domain	2026-06-20 19:40:05.736794
30299	1303	\N	\N	3293	1	domain	2026-06-20 19:40:05.736794
30300	1303	\N	\N	436	1	domain	2026-06-20 19:40:05.736794
30301	1303	\N	\N	3295	1	domain	2026-06-20 19:40:05.736794
30302	1303	\N	\N	3296	1	domain	2026-06-20 19:40:05.736794
30303	1303	\N	\N	438	1	domain	2026-06-20 19:40:05.736794
30304	1303	\N	\N	3299	1	domain	2026-06-20 19:40:05.736794
30305	1303	\N	\N	3300	1	domain	2026-06-20 19:40:05.736794
30306	1303	\N	\N	3301	1	domain	2026-06-20 19:40:05.736794
30307	1303	\N	\N	3302	1	domain	2026-06-20 19:40:05.736794
30308	1303	\N	\N	3303	1	domain	2026-06-20 19:40:05.736794
30309	1303	\N	\N	3304	1	domain	2026-06-20 19:40:05.736794
30310	1303	\N	\N	461	1	domain	2026-06-20 19:40:05.736794
30311	1303	\N	\N	470	1	domain	2026-06-20 19:40:05.736794
30312	1303	\N	\N	1530	1	domain	2026-06-20 19:40:05.736794
30313	1303	\N	\N	883	1	domain	2026-06-20 19:40:05.736794
30314	1303	\N	\N	884	1	domain	2026-06-20 19:40:05.736794
30315	1303	\N	\N	885	1	domain	2026-06-20 19:40:05.736794
30316	1303	\N	\N	886	1	domain	2026-06-20 19:40:05.736794
30317	1303	\N	\N	887	1	domain	2026-06-20 19:40:05.736794
30318	1303	\N	\N	888	1	domain	2026-06-20 19:40:05.736794
30319	1303	\N	\N	896	1	domain	2026-06-20 19:40:05.736794
30320	1303	\N	\N	897	1	domain	2026-06-20 19:40:05.736794
30322	1303	\N	\N	1833	1	domain	2026-06-20 19:40:05.744708
30323	1303	\N	\N	732	1	domain	2026-06-20 19:40:05.744708
30324	1303	\N	\N	106	1	domain	2026-06-20 19:40:05.744708
30326	1303	\N	\N	460	1	domain	2026-06-20 19:40:05.753288
30327	1303	\N	\N	1361	1	domain	2026-06-20 19:40:05.753288
30328	1303	\N	\N	210	1	domain	2026-06-20 19:40:05.753288
30329	1303	\N	\N	664	1	domain	2026-06-20 19:40:05.753288
30330	1303	\N	\N	1451	1	domain	2026-06-20 19:40:05.753288
30331	1303	\N	\N	1350	1	domain	2026-06-20 19:40:05.753288
30332	1303	\N	\N	1265	1	domain	2026-06-20 19:40:05.753288
30333	1303	\N	\N	3003	1	domain	2026-06-20 19:40:05.753288
30334	1303	\N	\N	2380	1	domain	2026-06-20 19:40:05.753288
30336	1303	\N	\N	643	1	domain	2026-06-20 19:40:05.761852
30337	1303	\N	\N	1390	1	domain	2026-06-20 19:40:05.761852
30338	1303	\N	\N	1392	1	domain	2026-06-20 19:40:05.761852
30339	1303	\N	\N	1393	1	domain	2026-06-20 19:40:05.761852
30340	1303	\N	\N	1394	1	domain	2026-06-20 19:40:05.761852
30341	1303	\N	\N	1395	1	domain	2026-06-20 19:40:05.761852
30342	1303	\N	\N	1396	1	domain	2026-06-20 19:40:05.761852
30343	1303	\N	\N	1397	1	domain	2026-06-20 19:40:05.761852
30344	1303	\N	\N	1398	1	domain	2026-06-20 19:40:05.761852
30345	1303	\N	\N	1399	1	domain	2026-06-20 19:40:05.761852
30346	1303	\N	\N	1400	1	domain	2026-06-20 19:40:05.761852
30347	1303	\N	\N	1401	1	domain	2026-06-20 19:40:05.761852
30348	1303	\N	\N	498	1	domain	2026-06-20 19:40:05.761852
30349	1303	\N	\N	499	1	domain	2026-06-20 19:40:05.761852
30350	1303	\N	\N	1391	1	domain	2026-06-20 19:40:05.761852
30351	1303	\N	\N	1402	1	domain	2026-06-20 19:40:05.761852
30352	1303	\N	\N	1403	1	domain	2026-06-20 19:40:05.761852
30354	1303	\N	\N	3372	1	domain	2026-06-20 19:40:05.769933
30355	1303	\N	\N	3106	1	domain	2026-06-20 19:40:05.769933
30356	1303	\N	\N	124	1	domain	2026-06-20 19:40:05.769933
30357	1303	\N	\N	1874	1	domain	2026-06-20 19:40:05.769933
30358	1303	\N	\N	32	1	domain	2026-06-20 19:40:05.769933
30359	1303	\N	\N	2823	1	domain	2026-06-20 19:40:05.769933
30360	1303	\N	\N	2824	1	domain	2026-06-20 19:40:05.769933
30361	1303	\N	\N	2907	1	domain	2026-06-20 19:40:05.769933
30362	1303	\N	\N	1332	1	domain	2026-06-20 19:40:05.769933
30363	1303	\N	\N	2383	1	domain	2026-06-20 19:40:05.769933
30364	1303	\N	\N	2541	1	domain	2026-06-20 19:40:05.769933
30365	1303	\N	\N	2552	1	domain	2026-06-20 19:40:05.769933
30366	1303	\N	\N	2557	1	domain	2026-06-20 19:40:05.769933
30367	1303	\N	\N	2558	1	domain	2026-06-20 19:40:05.769933
30368	1303	\N	\N	2560	1	domain	2026-06-20 19:40:05.769933
30369	1303	\N	\N	2568	1	domain	2026-06-20 19:40:05.769933
30370	1303	\N	\N	2569	1	domain	2026-06-20 19:40:05.769933
30371	1303	\N	\N	2570	1	domain	2026-06-20 19:40:05.769933
30372	1303	\N	\N	2571	1	domain	2026-06-20 19:40:05.769933
30374	1303	\N	\N	644	1	domain	2026-06-20 19:40:05.769933
30375	1303	\N	\N	213	1	domain	2026-06-20 19:40:05.769933
30376	1303	\N	\N	1890	1	domain	2026-06-20 19:40:05.769933
30377	1303	\N	\N	1425	1	domain	2026-06-20 19:40:05.769933
30378	1303	\N	\N	1732	1	domain	2026-06-20 19:40:05.769933
30379	1303	\N	\N	894	1	domain	2026-06-20 19:40:05.769933
30380	1303	\N	\N	1408	1	domain	2026-06-20 19:40:05.769933
30381	1303	\N	\N	2397	1	domain	2026-06-20 19:40:05.769933
30383	1303	\N	\N	645	1	domain	2026-06-20 19:40:05.777756
30384	1303	\N	\N	3395	1	domain	2026-06-20 19:40:05.777756
30385	1303	\N	\N	1619	1	domain	2026-06-20 19:40:05.777756
30386	1303	\N	\N	976	1	domain	2026-06-20 19:40:05.777756
30387	1303	\N	\N	3350	1	domain	2026-06-20 19:40:05.777756
30388	1303	\N	\N	3285	1	domain	2026-06-20 19:40:05.777756
30389	1303	\N	\N	3286	1	domain	2026-06-20 19:40:05.777756
30390	1303	\N	\N	3288	1	domain	2026-06-20 19:40:05.777756
30391	1303	\N	\N	3289	1	domain	2026-06-20 19:40:05.777756
30392	1303	\N	\N	729	1	domain	2026-06-20 19:40:05.777756
30393	1303	\N	\N	3363	1	domain	2026-06-20 19:40:05.777756
30394	1303	\N	\N	733	1	domain	2026-06-20 19:40:05.777756
30395	1303	\N	\N	853	1	domain	2026-06-20 19:40:05.777756
30396	1303	\N	\N	861	1	domain	2026-06-20 19:40:05.777756
30397	1303	\N	\N	862	1	domain	2026-06-20 19:40:05.777756
30398	1303	\N	\N	863	1	domain	2026-06-20 19:40:05.777756
30399	1303	\N	\N	864	1	domain	2026-06-20 19:40:05.777756
30400	1303	\N	\N	132	1	domain	2026-06-20 19:40:05.777756
30401	1303	\N	\N	133	1	domain	2026-06-20 19:40:05.777756
30402	1303	\N	\N	134	1	domain	2026-06-20 19:40:05.777756
30403	1303	\N	\N	135	1	domain	2026-06-20 19:40:05.777756
30404	1303	\N	\N	1730	1	domain	2026-06-20 19:40:05.777756
33069	1303	\N	\N	1994	1	standalone	2026-06-20 19:55:00.727524
33070	1304	\N	\N	364	1	standalone	2026-06-20 19:55:00.727524
33071	1304	\N	\N	974	1	standalone	2026-06-20 19:55:00.727524
33072	1317	\N	\N	3156	1	standalone	2026-06-20 19:55:00.727524
33073	1313	\N	\N	3213	1	standalone	2026-06-20 19:55:00.727524
33074	1304	\N	\N	3263	1	standalone	2026-06-20 19:55:00.727524
33075	1303	\N	\N	735	1	standalone	2026-06-20 19:55:00.727524
33076	1303	\N	\N	7017	1	standalone	2026-06-20 19:55:00.727524
33077	1303	\N	\N	1389	1	standalone	2026-06-20 19:55:00.727524
33078	1304	\N	\N	2860	1	standalone	2026-06-20 19:55:00.727524
30405	1303	\N	\N	895	1	domain	2026-06-20 19:40:05.777756
30406	1303	\N	\N	572	1	domain	2026-06-20 19:40:05.777756
30407	1303	\N	\N	1324	1	domain	2026-06-20 19:40:05.777756
30408	1303	\N	\N	2326	1	domain	2026-06-20 19:40:05.777756
30409	1303	\N	\N	2396	1	domain	2026-06-20 19:40:05.777756
30410	1303	\N	\N	2453	1	domain	2026-06-20 19:40:05.777756
30412	1303	\N	\N	646	1	domain	2026-06-20 19:40:05.786203
30413	1303	\N	\N	3376	1	domain	2026-06-20 19:40:05.786203
30414	1303	\N	\N	7011	1	domain	2026-06-20 19:40:05.786203
30415	1303	\N	\N	3294	1	domain	2026-06-20 19:40:05.786203
33079	1304	\N	\N	404	1	standalone	2026-06-20 19:55:00.727524
33080	1304	\N	\N	2104	1	standalone	2026-06-20 19:55:00.727524
33081	1304	\N	\N	1039	1	standalone	2026-06-20 19:55:00.727524
33082	1304	\N	\N	1753	1	standalone	2026-06-20 19:55:00.727524
33083	1319	\N	\N	1144	1	standalone	2026-06-20 19:55:00.727524
33084	1315	\N	\N	796	1	standalone	2026-06-20 19:55:00.727524
33085	1307	\N	\N	57	1	standalone	2026-06-20 19:55:00.727524
33086	1318	\N	\N	1662	1	standalone	2026-06-20 19:55:00.727524
33087	1305	\N	\N	2682	1	standalone	2026-06-20 19:55:00.727524
33088	1312	\N	\N	2793	1	standalone	2026-06-20 19:55:00.727524
33089	1307	\N	\N	269	1	standalone	2026-06-20 19:55:00.727524
33090	1303	\N	\N	1995	1	standalone	2026-06-20 19:55:00.727524
33091	1312	\N	\N	365	1	standalone	2026-06-20 19:55:00.727524
33092	1303	\N	\N	975	1	standalone	2026-06-20 19:55:00.727524
33093	1317	\N	\N	3158	1	standalone	2026-06-20 19:55:00.727524
33094	1320	\N	\N	3221	1	standalone	2026-06-20 19:55:00.727524
33095	1304	\N	\N	3264	1	standalone	2026-06-20 19:55:00.727524
33096	1303	\N	\N	736	1	standalone	2026-06-20 19:55:00.727524
33097	1304	\N	\N	7018	1	standalone	2026-06-20 19:55:00.727524
33098	1303	\N	\N	1405	1	standalone	2026-06-20 19:55:00.727524
33099	1304	\N	\N	2861	1	standalone	2026-06-20 19:55:00.727524
33100	1320	\N	\N	400	1	standalone	2026-06-20 19:55:00.727524
33101	1304	\N	\N	2105	1	standalone	2026-06-20 19:55:00.727524
33102	1304	\N	\N	1040	1	standalone	2026-06-20 19:55:00.727524
33103	1306	\N	\N	1754	1	standalone	2026-06-20 19:55:00.727524
33104	1312	\N	\N	1145	1	standalone	2026-06-20 19:55:00.727524
33105	1305	\N	\N	798	1	standalone	2026-06-20 19:55:00.727524
33106	1307	\N	\N	81	1	standalone	2026-06-20 19:55:00.727524
33107	1318	\N	\N	1667	1	standalone	2026-06-20 19:55:00.727524
33108	1307	\N	\N	2685	1	standalone	2026-06-20 19:55:00.727524
33109	1312	\N	\N	2795	1	standalone	2026-06-20 19:55:00.727524
33110	1307	\N	\N	270	1	standalone	2026-06-20 19:55:00.727524
33111	1318	\N	\N	2010	1	standalone	2026-06-20 19:55:00.727524
33112	1304	\N	\N	370	1	standalone	2026-06-20 19:55:00.727524
33113	1315	\N	\N	978	1	standalone	2026-06-20 19:55:00.727524
33114	1317	\N	\N	3159	1	standalone	2026-06-20 19:55:00.727524
33115	1314	\N	\N	3225	1	standalone	2026-06-20 19:55:00.727524
33116	1304	\N	\N	3265	1	standalone	2026-06-20 19:55:00.727524
33117	1303	\N	\N	745	1	standalone	2026-06-20 19:55:00.727524
33118	1320	\N	\N	7019	1	standalone	2026-06-20 19:55:00.727524
33119	1312	\N	\N	1407	1	standalone	2026-06-20 19:55:00.727524
33120	1304	\N	\N	2863	1	standalone	2026-06-20 19:55:00.727524
33121	1320	\N	\N	401	1	standalone	2026-06-20 19:55:00.727524
33122	1315	\N	\N	2115	1	standalone	2026-06-20 19:55:00.727524
33123	1304	\N	\N	1041	1	standalone	2026-06-20 19:55:00.727524
33124	1304	\N	\N	1796	1	standalone	2026-06-20 19:55:00.727524
33125	1309	\N	\N	1146	1	standalone	2026-06-20 19:55:00.727524
33126	1304	\N	\N	800	1	standalone	2026-06-20 19:55:00.727524
33127	1303	\N	\N	82	1	standalone	2026-06-20 19:55:00.727524
33128	1320	\N	\N	1669	1	standalone	2026-06-20 19:55:00.727524
33129	1307	\N	\N	2688	1	standalone	2026-06-20 19:55:00.727524
33130	1312	\N	\N	2796	1	standalone	2026-06-20 19:55:00.727524
33131	1307	\N	\N	271	1	standalone	2026-06-20 19:55:00.727524
33132	1318	\N	\N	2009	1	standalone	2026-06-20 19:55:00.727524
33133	1304	\N	\N	372	1	standalone	2026-06-20 19:55:00.727524
33134	1303	\N	\N	986	1	standalone	2026-06-20 19:55:00.727524
33135	1317	\N	\N	3160	1	standalone	2026-06-20 19:55:00.727524
33136	1309	\N	\N	3232	1	standalone	2026-06-20 19:55:00.727524
33137	1306	\N	\N	3276	1	standalone	2026-06-20 19:55:00.727524
33138	1304	\N	\N	1413	1	standalone	2026-06-20 19:55:00.727524
33139	1304	\N	\N	2864	1	standalone	2026-06-20 19:55:00.727524
33140	1303	\N	\N	402	1	standalone	2026-06-20 19:55:00.727524
33141	1304	\N	\N	2116	1	standalone	2026-06-20 19:55:00.727524
33142	1304	\N	\N	1042	1	standalone	2026-06-20 19:55:00.727524
33143	1304	\N	\N	1755	1	standalone	2026-06-20 19:55:00.727524
33144	1304	\N	\N	1109	1	standalone	2026-06-20 19:55:00.727524
33145	1304	\N	\N	801	1	standalone	2026-06-20 19:55:00.727524
33146	1304	\N	\N	83	1	standalone	2026-06-20 19:55:00.727524
33147	1313	\N	\N	1670	1	standalone	2026-06-20 19:55:00.727524
33148	1309	\N	\N	2689	1	standalone	2026-06-20 19:55:00.727524
33149	1315	\N	\N	2803	1	standalone	2026-06-20 19:55:00.727524
33150	1319	\N	\N	272	1	standalone	2026-06-20 19:55:00.727524
33151	1308	\N	\N	2018	1	standalone	2026-06-20 19:55:00.727524
33152	1304	\N	\N	377	1	standalone	2026-06-20 19:55:00.727524
33153	1313	\N	\N	995	1	standalone	2026-06-20 19:55:00.727524
33154	1317	\N	\N	3161	1	standalone	2026-06-20 19:55:00.727524
33155	1318	\N	\N	3233	1	standalone	2026-06-20 19:55:00.727524
33156	1311	\N	\N	3284	1	standalone	2026-06-20 19:55:00.727524
33157	1304	\N	\N	1417	1	standalone	2026-06-20 19:55:00.727524
33158	1304	\N	\N	2867	1	standalone	2026-06-20 19:55:00.727524
33159	1303	\N	\N	403	1	standalone	2026-06-20 19:55:00.727524
33160	1319	\N	\N	2124	1	standalone	2026-06-20 19:55:00.727524
33161	1304	\N	\N	1053	1	standalone	2026-06-20 19:55:00.727524
33162	1304	\N	\N	1756	1	standalone	2026-06-20 19:55:00.727524
33163	1304	\N	\N	1112	1	standalone	2026-06-20 19:55:00.727524
33164	1303	\N	\N	804	1	standalone	2026-06-20 19:55:00.727524
33165	1304	\N	\N	85	1	standalone	2026-06-20 19:55:00.727524
33166	1313	\N	\N	1671	1	standalone	2026-06-20 19:55:00.727524
33167	1309	\N	\N	2692	1	standalone	2026-06-20 19:55:00.727524
33168	1312	\N	\N	2797	1	standalone	2026-06-20 19:55:00.727524
33169	1319	\N	\N	273	1	standalone	2026-06-20 19:55:00.727524
33170	1320	\N	\N	2011	1	standalone	2026-06-20 19:55:00.727524
33171	1304	\N	\N	380	1	standalone	2026-06-20 19:55:00.727524
33172	1313	\N	\N	1000	1	standalone	2026-06-20 19:55:00.727524
33173	1317	\N	\N	3162	1	standalone	2026-06-20 19:55:00.727524
33174	1303	\N	\N	3239	1	standalone	2026-06-20 19:55:00.727524
33175	1303	\N	\N	3290	1	standalone	2026-06-20 19:55:00.727524
33176	1304	\N	\N	1418	1	standalone	2026-06-20 19:55:00.727524
33177	1304	\N	\N	2868	1	standalone	2026-06-20 19:55:00.727524
33178	1303	\N	\N	405	1	standalone	2026-06-20 19:55:00.727524
33179	1314	\N	\N	2246	1	standalone	2026-06-20 19:55:00.727524
33180	1304	\N	\N	1043	1	standalone	2026-06-20 19:55:00.727524
33181	1312	\N	\N	1757	1	standalone	2026-06-20 19:55:00.727524
33182	1320	\N	\N	1328	1	standalone	2026-06-20 19:55:00.727524
33183	1315	\N	\N	807	1	standalone	2026-06-20 19:55:00.727524
33184	1303	\N	\N	95	1	standalone	2026-06-20 19:55:00.727524
33185	1313	\N	\N	1673	1	standalone	2026-06-20 19:55:00.727524
33186	1307	\N	\N	2693	1	standalone	2026-06-20 19:55:00.727524
33187	1312	\N	\N	2798	1	standalone	2026-06-20 19:55:00.727524
33188	1319	\N	\N	278	1	standalone	2026-06-20 19:55:00.727524
33189	1319	\N	\N	2012	1	standalone	2026-06-20 19:55:00.727524
33190	1304	\N	\N	381	1	standalone	2026-06-20 19:55:00.727524
33191	1303	\N	\N	1003	1	standalone	2026-06-20 19:55:00.727524
33192	1304	\N	\N	3164	1	standalone	2026-06-20 19:55:00.727524
33193	1320	\N	\N	3241	1	standalone	2026-06-20 19:55:00.727524
33194	1303	\N	\N	3313	1	standalone	2026-06-20 19:55:00.727524
33195	1304	\N	\N	1419	1	standalone	2026-06-20 19:55:00.727524
33196	1304	\N	\N	2871	1	standalone	2026-06-20 19:55:00.727524
33197	1303	\N	\N	406	1	standalone	2026-06-20 19:55:00.727524
33198	1308	\N	\N	2127	1	standalone	2026-06-20 19:55:00.727524
33199	1304	\N	\N	1044	1	standalone	2026-06-20 19:55:00.727524
33200	1304	\N	\N	1759	1	standalone	2026-06-20 19:55:00.727524
33201	1304	\N	\N	1115	1	standalone	2026-06-20 19:55:00.727524
33202	1305	\N	\N	809	1	standalone	2026-06-20 19:55:00.727524
33203	1303	\N	\N	103	1	standalone	2026-06-20 19:55:00.727524
33204	1320	\N	\N	1678	1	standalone	2026-06-20 19:55:00.727524
33205	1307	\N	\N	2700	1	standalone	2026-06-20 19:55:00.727524
33206	1312	\N	\N	2800	1	standalone	2026-06-20 19:55:00.727524
33207	1319	\N	\N	280	1	standalone	2026-06-20 19:55:00.727524
33208	1305	\N	\N	2035	1	standalone	2026-06-20 19:55:00.727524
33209	1306	\N	\N	382	1	standalone	2026-06-20 19:55:00.727524
33210	1311	\N	\N	1016	1	standalone	2026-06-20 19:55:00.727524
33211	1304	\N	\N	3165	1	standalone	2026-06-20 19:55:00.727524
33212	1304	\N	\N	1420	1	standalone	2026-06-20 19:55:00.727524
33213	1304	\N	\N	2878	1	standalone	2026-06-20 19:55:00.727524
33214	1304	\N	\N	408	1	standalone	2026-06-20 19:55:00.727524
33215	1304	\N	\N	2137	1	standalone	2026-06-20 19:55:00.727524
33216	1304	\N	\N	1045	1	standalone	2026-06-20 19:55:00.727524
33217	1320	\N	\N	1760	1	standalone	2026-06-20 19:55:00.727524
33218	1304	\N	\N	1116	1	standalone	2026-06-20 19:55:00.727524
33219	1311	\N	\N	822	1	standalone	2026-06-20 19:55:00.727524
33220	1303	\N	\N	111	1	standalone	2026-06-20 19:55:00.727524
33221	1304	\N	\N	1688	1	standalone	2026-06-20 19:55:00.727524
33222	1312	\N	\N	2702	1	standalone	2026-06-20 19:55:00.727524
33223	1312	\N	\N	2801	1	standalone	2026-06-20 19:55:00.727524
33224	1303	\N	\N	285	1	standalone	2026-06-20 19:55:00.727524
33225	1315	\N	\N	2039	1	standalone	2026-06-20 19:55:00.727524
33226	1320	\N	\N	385	1	standalone	2026-06-20 19:55:00.727524
33227	1320	\N	\N	1019	1	standalone	2026-06-20 19:55:00.727524
33228	1320	\N	\N	3166	1	standalone	2026-06-20 19:55:00.727524
33229	1303	\N	\N	1430	1	standalone	2026-06-20 19:55:00.727524
33230	1320	\N	\N	2879	1	standalone	2026-06-20 19:55:00.727524
33231	1303	\N	\N	409	1	standalone	2026-06-20 19:55:00.727524
33232	1305	\N	\N	2156	1	standalone	2026-06-20 19:55:00.727524
33233	1304	\N	\N	1046	1	standalone	2026-06-20 19:55:00.727524
33234	1304	\N	\N	1761	1	standalone	2026-06-20 19:55:00.727524
33235	1309	\N	\N	1153	1	standalone	2026-06-20 19:55:00.727524
33236	1313	\N	\N	827	1	standalone	2026-06-20 19:55:00.727524
33237	1303	\N	\N	112	1	standalone	2026-06-20 19:55:00.727524
33238	1303	\N	\N	1697	1	standalone	2026-06-20 19:55:00.727524
33239	1312	\N	\N	2703	1	standalone	2026-06-20 19:55:00.727524
33240	1312	\N	\N	2804	1	standalone	2026-06-20 19:55:00.727524
33241	1312	\N	\N	321	1	standalone	2026-06-20 19:55:00.727524
33242	1305	\N	\N	2040	1	standalone	2026-06-20 19:55:00.727524
33243	1304	\N	\N	386	1	standalone	2026-06-20 19:55:00.727524
33244	1305	\N	\N	1025	1	standalone	2026-06-20 19:55:00.727524
33245	1320	\N	\N	3167	1	standalone	2026-06-20 19:55:00.727524
33246	1320	\N	\N	1432	1	standalone	2026-06-20 19:55:00.727524
33247	1304	\N	\N	2880	1	standalone	2026-06-20 19:55:00.727524
33248	1303	\N	\N	410	1	standalone	2026-06-20 19:55:00.727524
33249	1315	\N	\N	2159	1	standalone	2026-06-20 19:55:00.727524
33250	1304	\N	\N	1054	1	standalone	2026-06-20 19:55:00.727524
33251	1304	\N	\N	1762	1	standalone	2026-06-20 19:55:00.727524
33252	1309	\N	\N	1156	1	standalone	2026-06-20 19:55:00.727524
33253	1309	\N	\N	831	1	standalone	2026-06-20 19:55:00.727524
33254	1303	\N	\N	113	1	standalone	2026-06-20 19:55:00.727524
33255	1303	\N	\N	1698	1	standalone	2026-06-20 19:55:00.727524
33256	1312	\N	\N	2704	1	standalone	2026-06-20 19:55:00.727524
33257	1312	\N	\N	2811	1	standalone	2026-06-20 19:55:00.727524
33258	1312	\N	\N	322	1	standalone	2026-06-20 19:55:00.727524
33259	1312	\N	\N	2049	1	standalone	2026-06-20 19:55:00.727524
33260	1304	\N	\N	387	1	standalone	2026-06-20 19:55:00.727524
33261	1312	\N	\N	1032	1	standalone	2026-06-20 19:55:00.727524
33262	1306	\N	\N	3169	1	standalone	2026-06-20 19:55:00.727524
33263	1320	\N	\N	1433	1	standalone	2026-06-20 19:55:00.727524
33264	1304	\N	\N	2881	1	standalone	2026-06-20 19:55:00.727524
33265	1303	\N	\N	413	1	standalone	2026-06-20 19:55:00.727524
33266	1304	\N	\N	2160	1	standalone	2026-06-20 19:55:00.727524
33267	1304	\N	\N	1047	1	standalone	2026-06-20 19:55:00.727524
33268	1304	\N	\N	1797	1	standalone	2026-06-20 19:55:00.727524
33269	1309	\N	\N	1157	1	standalone	2026-06-20 19:55:00.727524
33270	1309	\N	\N	836	1	standalone	2026-06-20 19:55:00.727524
33271	1303	\N	\N	114	1	standalone	2026-06-20 19:55:00.727524
33272	1320	\N	\N	1702	1	standalone	2026-06-20 19:55:00.727524
33273	1307	\N	\N	2712	1	standalone	2026-06-20 19:55:00.727524
33274	1311	\N	\N	2812	1	standalone	2026-06-20 19:55:00.727524
33275	1312	\N	\N	326	1	standalone	2026-06-20 19:55:00.727524
33276	1312	\N	\N	2050	1	standalone	2026-06-20 19:55:00.727524
33277	1315	\N	\N	388	1	standalone	2026-06-20 19:55:00.727524
33278	1309	\N	\N	1035	1	standalone	2026-06-20 19:55:00.727524
33279	1320	\N	\N	1436	1	standalone	2026-06-20 19:55:00.727524
33280	1304	\N	\N	2882	1	standalone	2026-06-20 19:55:00.727524
33281	1303	\N	\N	421	1	standalone	2026-06-20 19:55:00.727524
33282	1320	\N	\N	2169	1	standalone	2026-06-20 19:55:00.727524
33283	1304	\N	\N	1048	1	standalone	2026-06-20 19:55:00.727524
33284	1309	\N	\N	1764	1	standalone	2026-06-20 19:55:00.727524
33285	1309	\N	\N	1159	1	standalone	2026-06-20 19:55:00.727524
33286	1303	\N	\N	844	1	standalone	2026-06-20 19:55:00.727524
33287	1303	\N	\N	115	1	standalone	2026-06-20 19:55:00.727524
33288	1307	\N	\N	1721	1	standalone	2026-06-20 19:55:00.727524
33289	1307	\N	\N	2714	1	standalone	2026-06-20 19:55:00.727524
33290	1312	\N	\N	2815	1	standalone	2026-06-20 19:55:00.727524
33291	1309	\N	\N	327	1	standalone	2026-06-20 19:55:00.727524
33292	1312	\N	\N	2054	1	standalone	2026-06-20 19:55:00.727524
33293	1315	\N	\N	390	1	standalone	2026-06-20 19:55:00.727524
33294	1320	\N	\N	1438	1	standalone	2026-06-20 19:55:00.727524
33295	1304	\N	\N	2883	1	standalone	2026-06-20 19:55:00.727524
33296	1305	\N	\N	425	1	standalone	2026-06-20 19:55:00.727524
33297	1306	\N	\N	2178	1	standalone	2026-06-20 19:55:00.727524
33298	1320	\N	\N	1050	1	standalone	2026-06-20 19:55:00.727524
33299	1320	\N	\N	1765	1	standalone	2026-06-20 19:55:00.727524
33300	1320	\N	\N	1160	1	standalone	2026-06-20 19:55:00.727524
33301	1303	\N	\N	850	1	standalone	2026-06-20 19:55:00.727524
33302	1307	\N	\N	116	1	standalone	2026-06-20 19:55:00.727524
33303	1312	\N	\N	1711	1	standalone	2026-06-20 19:55:00.727524
33304	1312	\N	\N	2716	1	standalone	2026-06-20 19:55:00.727524
33305	1312	\N	\N	2816	1	standalone	2026-06-20 19:55:00.727524
33306	1320	\N	\N	330	1	standalone	2026-06-20 19:55:00.727524
33307	1303	\N	\N	2055	1	standalone	2026-06-20 19:55:00.727524
33308	1303	\N	\N	1440	1	standalone	2026-06-20 19:55:00.727524
33309	1304	\N	\N	2884	1	standalone	2026-06-20 19:55:00.727524
33310	1317	\N	\N	435	1	standalone	2026-06-20 19:55:00.727524
33311	1306	\N	\N	2186	1	standalone	2026-06-20 19:55:00.727524
33312	1317	\N	\N	1051	1	standalone	2026-06-20 19:55:00.727524
33313	1320	\N	\N	1766	1	standalone	2026-06-20 19:55:00.727524
33314	1320	\N	\N	1161	1	standalone	2026-06-20 19:55:00.727524
33315	1303	\N	\N	845	1	standalone	2026-06-20 19:55:00.727524
33316	1303	\N	\N	117	1	standalone	2026-06-20 19:55:00.727524
33317	1319	\N	\N	1713	1	standalone	2026-06-20 19:55:00.727524
33318	1312	\N	\N	2717	1	standalone	2026-06-20 19:55:00.727524
33319	1319	\N	\N	2831	1	standalone	2026-06-20 19:55:00.727524
33320	1303	\N	\N	1443	1	standalone	2026-06-20 19:55:00.727524
33321	1312	\N	\N	2885	1	standalone	2026-06-20 19:55:00.727524
33322	1303	\N	\N	437	1	standalone	2026-06-20 19:55:00.727524
33323	1319	\N	\N	2191	1	standalone	2026-06-20 19:55:00.727524
33324	1320	\N	\N	1057	1	standalone	2026-06-20 19:55:00.727524
33325	1320	\N	\N	1767	1	standalone	2026-06-20 19:55:00.727524
33326	1320	\N	\N	1172	1	standalone	2026-06-20 19:55:00.727524
33327	1303	\N	\N	848	1	standalone	2026-06-20 19:55:00.727524
33328	1309	\N	\N	129	1	standalone	2026-06-20 19:55:00.727524
33329	1304	\N	\N	1714	1	standalone	2026-06-20 19:55:00.727524
33330	1312	\N	\N	2718	1	standalone	2026-06-20 19:55:00.727524
33331	1310	\N	\N	2836	1	standalone	2026-06-20 19:55:00.727524
33332	1320	\N	\N	1445	1	standalone	2026-06-20 19:55:00.727524
33333	1304	\N	\N	2886	1	standalone	2026-06-20 19:55:00.727524
33334	1320	\N	\N	439	1	standalone	2026-06-20 19:55:00.727524
33335	1320	\N	\N	2224	1	standalone	2026-06-20 19:55:00.727524
33336	1320	\N	\N	1058	1	standalone	2026-06-20 19:55:00.727524
33337	1320	\N	\N	1768	1	standalone	2026-06-20 19:55:00.727524
33338	1309	\N	\N	1173	1	standalone	2026-06-20 19:55:00.727524
33339	1303	\N	\N	849	1	standalone	2026-06-20 19:55:00.727524
33340	1317	\N	\N	131	1	standalone	2026-06-20 19:55:00.727524
33341	1307	\N	\N	1715	1	standalone	2026-06-20 19:55:00.727524
33342	1312	\N	\N	2720	1	standalone	2026-06-20 19:55:00.727524
33343	1310	\N	\N	2837	1	standalone	2026-06-20 19:55:00.727524
33344	1317	\N	\N	1446	1	standalone	2026-06-20 19:55:00.727524
33345	1304	\N	\N	2888	1	standalone	2026-06-20 19:55:00.727524
33346	1303	\N	\N	458	1	standalone	2026-06-20 19:55:00.727524
33347	1320	\N	\N	2226	1	standalone	2026-06-20 19:55:00.727524
33348	1320	\N	\N	1059	1	standalone	2026-06-20 19:55:00.727524
33349	1320	\N	\N	1769	1	standalone	2026-06-20 19:55:00.727524
33350	1320	\N	\N	1185	1	standalone	2026-06-20 19:55:00.727524
33351	1303	\N	\N	868	1	standalone	2026-06-20 19:55:00.727524
33352	1320	\N	\N	136	1	standalone	2026-06-20 19:55:00.727524
33353	1310	\N	\N	1728	1	standalone	2026-06-20 19:55:00.727524
33354	1311	\N	\N	2722	1	standalone	2026-06-20 19:55:00.727524
33355	1310	\N	\N	2838	1	standalone	2026-06-20 19:55:00.727524
33356	1320	\N	\N	1447	1	standalone	2026-06-20 19:55:00.727524
33357	1304	\N	\N	2890	1	standalone	2026-06-20 19:55:00.727524
33358	1303	\N	\N	459	1	standalone	2026-06-20 19:55:00.727524
33359	1319	\N	\N	2227	1	standalone	2026-06-20 19:55:00.727524
33360	1320	\N	\N	1060	1	standalone	2026-06-20 19:55:00.727524
33361	1320	\N	\N	1770	1	standalone	2026-06-20 19:55:00.727524
33362	1320	\N	\N	1214	1	standalone	2026-06-20 19:55:00.727524
33363	1309	\N	\N	871	1	standalone	2026-06-20 19:55:00.727524
33364	1303	\N	\N	139	1	standalone	2026-06-20 19:55:00.727524
33365	1309	\N	\N	1729	1	standalone	2026-06-20 19:55:00.727524
33366	1312	\N	\N	2723	1	standalone	2026-06-20 19:55:00.727524
33367	1320	\N	\N	2839	1	standalone	2026-06-20 19:55:00.727524
33368	1320	\N	\N	1448	1	standalone	2026-06-20 19:55:00.727524
33369	1305	\N	\N	2937	1	standalone	2026-06-20 19:55:00.727524
33370	1303	\N	\N	462	1	standalone	2026-06-20 19:55:00.727524
33371	1304	\N	\N	2229	1	standalone	2026-06-20 19:55:00.727524
33372	1320	\N	\N	1061	1	standalone	2026-06-20 19:55:00.727524
33373	1317	\N	\N	1771	1	standalone	2026-06-20 19:55:00.727524
33374	1319	\N	\N	1227	1	standalone	2026-06-20 19:55:00.727524
33375	1320	\N	\N	877	1	standalone	2026-06-20 19:55:00.727524
33376	1312	\N	\N	141	1	standalone	2026-06-20 19:55:00.727524
33377	1309	\N	\N	1731	1	standalone	2026-06-20 19:55:00.727524
33378	1305	\N	\N	2734	1	standalone	2026-06-20 19:55:00.727524
33379	1312	\N	\N	2841	1	standalone	2026-06-20 19:55:00.727524
33380	1309	\N	\N	1449	1	standalone	2026-06-20 19:55:00.727524
33381	1304	\N	\N	2899	1	standalone	2026-06-20 19:55:00.727524
33382	1304	\N	\N	465	1	standalone	2026-06-20 19:55:00.727524
33383	1312	\N	\N	2230	1	standalone	2026-06-20 19:55:00.727524
33384	1315	\N	\N	1062	1	standalone	2026-06-20 19:55:00.727524
33385	1304	\N	\N	1772	1	standalone	2026-06-20 19:55:00.727524
33386	1311	\N	\N	1228	1	standalone	2026-06-20 19:55:00.727524
33387	1303	\N	\N	889	1	standalone	2026-06-20 19:55:00.727524
33388	1312	\N	\N	146	1	standalone	2026-06-20 19:55:00.727524
33389	1309	\N	\N	1733	1	standalone	2026-06-20 19:55:00.727524
33390	1312	\N	\N	2753	1	standalone	2026-06-20 19:55:00.727524
33391	1320	\N	\N	1450	1	standalone	2026-06-20 19:55:00.727524
33392	1304	\N	\N	2900	1	standalone	2026-06-20 19:55:00.727524
33393	1303	\N	\N	467	1	standalone	2026-06-20 19:55:00.729529
33394	1304	\N	\N	2231	1	standalone	2026-06-20 19:55:00.729529
33395	1315	\N	\N	1063	1	standalone	2026-06-20 19:55:00.729529
33396	1304	\N	\N	1773	1	standalone	2026-06-20 19:55:00.729529
33397	1313	\N	\N	1229	1	standalone	2026-06-20 19:55:00.729529
33398	1303	\N	\N	890	1	standalone	2026-06-20 19:55:00.729529
33399	1312	\N	\N	148	1	standalone	2026-06-20 19:55:00.729529
33400	1304	\N	\N	1734	1	standalone	2026-06-20 19:55:00.729529
33401	1319	\N	\N	2760	1	standalone	2026-06-20 19:55:00.729529
33402	1303	\N	\N	1452	1	standalone	2026-06-20 19:55:00.729529
33403	1304	\N	\N	2901	1	standalone	2026-06-20 19:55:00.729529
33404	1305	\N	\N	471	1	standalone	2026-06-20 19:55:00.729529
33405	1315	\N	\N	2233	1	standalone	2026-06-20 19:55:00.729529
33406	1315	\N	\N	1064	1	standalone	2026-06-20 19:55:00.729529
33407	1304	\N	\N	1774	1	standalone	2026-06-20 19:55:00.729529
33408	1311	\N	\N	1230	1	standalone	2026-06-20 19:55:00.729529
33409	1303	\N	\N	893	1	standalone	2026-06-20 19:55:00.729529
33410	1317	\N	\N	156	1	standalone	2026-06-20 19:55:00.729529
33411	1312	\N	\N	1739	1	standalone	2026-06-20 19:55:00.729529
33412	1319	\N	\N	2780	1	standalone	2026-06-20 19:55:00.729529
33413	1303	\N	\N	1453	1	standalone	2026-06-20 19:55:00.729529
33414	1304	\N	\N	2904	1	standalone	2026-06-20 19:55:00.729529
33415	1305	\N	\N	472	1	standalone	2026-06-20 19:55:00.729529
33416	1305	\N	\N	2257	1	standalone	2026-06-20 19:55:00.729529
33417	1315	\N	\N	1065	1	standalone	2026-06-20 19:55:00.729529
33418	1304	\N	\N	1775	1	standalone	2026-06-20 19:55:00.729529
33419	1305	\N	\N	1244	1	standalone	2026-06-20 19:55:00.729529
33420	1304	\N	\N	898	1	standalone	2026-06-20 19:55:00.729529
33421	1303	\N	\N	1456	1	standalone	2026-06-20 19:55:00.729529
33422	1304	\N	\N	2915	1	standalone	2026-06-20 19:55:00.729529
33423	1303	\N	\N	473	1	standalone	2026-06-20 19:55:00.729529
33424	1304	\N	\N	2234	1	standalone	2026-06-20 19:55:00.729529
33425	1315	\N	\N	1066	1	standalone	2026-06-20 19:55:00.729529
33426	1304	\N	\N	1776	1	standalone	2026-06-20 19:55:00.729529
33427	1305	\N	\N	1263	1	standalone	2026-06-20 19:55:00.729529
33428	1303	\N	\N	1458	1	standalone	2026-06-20 19:55:00.729529
33429	1304	\N	\N	2916	1	standalone	2026-06-20 19:55:00.729529
33430	1304	\N	\N	474	1	standalone	2026-06-20 19:55:00.729529
33431	1312	\N	\N	2235	1	standalone	2026-06-20 19:55:00.729529
33432	1315	\N	\N	1068	1	standalone	2026-06-20 19:55:00.729529
33433	1304	\N	\N	1777	1	standalone	2026-06-20 19:55:00.729529
33434	1319	\N	\N	1273	1	standalone	2026-06-20 19:55:00.729529
33435	1303	\N	\N	1459	1	standalone	2026-06-20 19:55:00.729529
33436	1304	\N	\N	2917	1	standalone	2026-06-20 19:55:00.729529
33437	1304	\N	\N	477	1	standalone	2026-06-20 19:55:00.729529
33438	1304	\N	\N	2236	1	standalone	2026-06-20 19:55:00.729529
33439	1304	\N	\N	1069	1	standalone	2026-06-20 19:55:00.729529
33440	1304	\N	\N	1778	1	standalone	2026-06-20 19:55:00.729529
33441	1305	\N	\N	1281	1	standalone	2026-06-20 19:55:00.729529
33442	1303	\N	\N	1460	1	standalone	2026-06-20 19:55:00.729529
33443	1309	\N	\N	2923	1	standalone	2026-06-20 19:55:00.729529
33444	1304	\N	\N	478	1	standalone	2026-06-20 19:55:00.729529
33445	1312	\N	\N	2237	1	standalone	2026-06-20 19:55:00.729529
33446	1304	\N	\N	1070	1	standalone	2026-06-20 19:55:00.729529
33447	1304	\N	\N	1779	1	standalone	2026-06-20 19:55:00.729529
33448	1309	\N	\N	1282	1	standalone	2026-06-20 19:55:00.729529
33449	1303	\N	\N	1463	1	standalone	2026-06-20 19:55:00.729529
33450	1304	\N	\N	2939	1	standalone	2026-06-20 19:55:00.729529
33451	1317	\N	\N	479	1	standalone	2026-06-20 19:55:00.729529
33452	1312	\N	\N	2238	1	standalone	2026-06-20 19:55:00.729529
33453	1304	\N	\N	1071	1	standalone	2026-06-20 19:55:00.729529
33454	1304	\N	\N	1780	1	standalone	2026-06-20 19:55:00.729529
33455	1320	\N	\N	1284	1	standalone	2026-06-20 19:55:00.729529
33456	1303	\N	\N	1465	1	standalone	2026-06-20 19:55:00.729529
33457	1315	\N	\N	2940	1	standalone	2026-06-20 19:55:00.729529
33458	1303	\N	\N	480	1	standalone	2026-06-20 19:55:00.729529
33459	1319	\N	\N	2239	1	standalone	2026-06-20 19:55:00.729529
33460	1314	\N	\N	1072	1	standalone	2026-06-20 19:55:00.729529
33461	1303	\N	\N	1781	1	standalone	2026-06-20 19:55:00.729529
33462	1319	\N	\N	1286	1	standalone	2026-06-20 19:55:00.729529
33463	1303	\N	\N	1466	1	standalone	2026-06-20 19:55:00.729529
33464	1306	\N	\N	2942	1	standalone	2026-06-20 19:55:00.729529
33465	1303	\N	\N	489	1	standalone	2026-06-20 19:55:00.729529
33466	1319	\N	\N	2241	1	standalone	2026-06-20 19:55:00.729529
33467	1304	\N	\N	1073	1	standalone	2026-06-20 19:55:00.729529
33468	1315	\N	\N	1782	1	standalone	2026-06-20 19:55:00.729529
33469	1307	\N	\N	1287	1	standalone	2026-06-20 19:55:00.729529
33470	1303	\N	\N	1467	1	standalone	2026-06-20 19:55:00.729529
33471	1315	\N	\N	2944	1	standalone	2026-06-20 19:55:00.729529
33472	1303	\N	\N	490	1	standalone	2026-06-20 19:55:00.729529
33473	1311	\N	\N	2242	1	standalone	2026-06-20 19:55:00.729529
33474	1314	\N	\N	1074	1	standalone	2026-06-20 19:55:00.729529
33475	1310	\N	\N	1783	1	standalone	2026-06-20 19:55:00.729529
33476	1305	\N	\N	1288	1	standalone	2026-06-20 19:55:00.729529
33477	1317	\N	\N	1468	1	standalone	2026-06-20 19:55:00.729529
33478	1306	\N	\N	2955	1	standalone	2026-06-20 19:55:00.729529
33479	1303	\N	\N	491	1	standalone	2026-06-20 19:55:00.729529
33480	1305	\N	\N	2247	1	standalone	2026-06-20 19:55:00.729529
33481	1314	\N	\N	1078	1	standalone	2026-06-20 19:55:00.729529
33482	1315	\N	\N	1784	1	standalone	2026-06-20 19:55:00.729529
33483	1310	\N	\N	1289	1	standalone	2026-06-20 19:55:00.729529
33484	1303	\N	\N	1477	1	standalone	2026-06-20 19:55:00.729529
33485	1304	\N	\N	2957	1	standalone	2026-06-20 19:55:00.729529
33486	1309	\N	\N	492	1	standalone	2026-06-20 19:55:00.729529
33487	1305	\N	\N	2254	1	standalone	2026-06-20 19:55:00.729529
33488	1315	\N	\N	1079	1	standalone	2026-06-20 19:55:00.729529
33489	1319	\N	\N	1785	1	standalone	2026-06-20 19:55:00.729529
33490	1306	\N	\N	1292	1	standalone	2026-06-20 19:55:00.729529
33491	1303	\N	\N	1479	1	standalone	2026-06-20 19:55:00.729529
33492	1304	\N	\N	2958	1	standalone	2026-06-20 19:55:00.729529
33493	1309	\N	\N	493	1	standalone	2026-06-20 19:55:00.729529
33494	1318	\N	\N	2266	1	standalone	2026-06-20 19:55:00.729529
33495	1315	\N	\N	1080	1	standalone	2026-06-20 19:55:00.729529
33496	1315	\N	\N	1786	1	standalone	2026-06-20 19:55:00.729529
33497	1310	\N	\N	1295	1	standalone	2026-06-20 19:55:00.729529
33498	1303	\N	\N	1483	1	standalone	2026-06-20 19:55:00.729529
33499	1304	\N	\N	2961	1	standalone	2026-06-20 19:55:00.729529
33500	1307	\N	\N	494	1	standalone	2026-06-20 19:55:00.729529
33501	1305	\N	\N	2286	1	standalone	2026-06-20 19:55:00.729529
33502	1315	\N	\N	1081	1	standalone	2026-06-20 19:55:00.729529
33503	1315	\N	\N	1787	1	standalone	2026-06-20 19:55:00.729529
33504	1310	\N	\N	1296	1	standalone	2026-06-20 19:55:00.729529
33505	1303	\N	\N	1485	1	standalone	2026-06-20 19:55:00.729529
33506	1304	\N	\N	2962	1	standalone	2026-06-20 19:55:00.729529
33507	1320	\N	\N	500	1	standalone	2026-06-20 19:55:00.729529
33508	1317	\N	\N	2287	1	standalone	2026-06-20 19:55:00.729529
33509	1315	\N	\N	1082	1	standalone	2026-06-20 19:55:00.729529
33510	1315	\N	\N	1788	1	standalone	2026-06-20 19:55:00.729529
33511	1310	\N	\N	1297	1	standalone	2026-06-20 19:55:00.729529
33512	1303	\N	\N	1487	1	standalone	2026-06-20 19:55:00.729529
33513	1304	\N	\N	2963	1	standalone	2026-06-20 19:55:00.729529
33514	1309	\N	\N	496	1	standalone	2026-06-20 19:55:00.729529
33515	1307	\N	\N	2292	1	standalone	2026-06-20 19:55:00.729529
33516	1304	\N	\N	1083	1	standalone	2026-06-20 19:55:00.729529
33517	1315	\N	\N	1789	1	standalone	2026-06-20 19:55:00.729529
33518	1306	\N	\N	1298	1	standalone	2026-06-20 19:55:00.729529
33519	1303	\N	\N	1488	1	standalone	2026-06-20 19:55:00.729529
33520	1306	\N	\N	2964	1	standalone	2026-06-20 19:55:00.729529
33521	1309	\N	\N	497	1	standalone	2026-06-20 19:55:00.729529
33522	1305	\N	\N	2298	1	standalone	2026-06-20 19:55:00.729529
33523	1309	\N	\N	1084	1	standalone	2026-06-20 19:55:00.729529
33524	1315	\N	\N	1790	1	standalone	2026-06-20 19:55:00.729529
33525	1306	\N	\N	1308	1	standalone	2026-06-20 19:55:00.729529
33526	1303	\N	\N	1490	1	standalone	2026-06-20 19:55:00.729529
33527	1304	\N	\N	2967	1	standalone	2026-06-20 19:55:00.729529
33528	1304	\N	\N	511	1	standalone	2026-06-20 19:55:00.729529
33529	1307	\N	\N	2311	1	standalone	2026-06-20 19:55:00.729529
33530	1309	\N	\N	1087	1	standalone	2026-06-20 19:55:00.729529
33531	1320	\N	\N	1791	1	standalone	2026-06-20 19:55:00.729529
33532	1306	\N	\N	1309	1	standalone	2026-06-20 19:55:00.729529
33533	1303	\N	\N	1491	1	standalone	2026-06-20 19:55:00.729529
33534	1304	\N	\N	2968	1	standalone	2026-06-20 19:55:00.729529
33535	1320	\N	\N	501	1	standalone	2026-06-20 19:55:00.729529
33536	1308	\N	\N	2312	1	standalone	2026-06-20 19:55:00.729529
33537	1320	\N	\N	1088	1	standalone	2026-06-20 19:55:00.729529
33538	1320	\N	\N	1798	1	standalone	2026-06-20 19:55:00.729529
33539	1319	\N	\N	1310	1	standalone	2026-06-20 19:55:00.729529
33540	1303	\N	\N	1492	1	standalone	2026-06-20 19:55:00.729529
33541	1320	\N	\N	2969	1	standalone	2026-06-20 19:55:00.729529
33542	1304	\N	\N	502	1	standalone	2026-06-20 19:55:00.729529
33543	1313	\N	\N	2317	1	standalone	2026-06-20 19:55:00.729529
33544	1320	\N	\N	1089	1	standalone	2026-06-20 19:55:00.729529
33545	1320	\N	\N	1792	1	standalone	2026-06-20 19:55:00.729529
33546	1320	\N	\N	1311	1	standalone	2026-06-20 19:55:00.729529
33547	1303	\N	\N	1493	1	standalone	2026-06-20 19:55:00.729529
33548	1311	\N	\N	2970	1	standalone	2026-06-20 19:55:00.729529
33549	1304	\N	\N	505	1	standalone	2026-06-20 19:55:00.729529
33550	1317	\N	\N	2322	1	standalone	2026-06-20 19:55:00.729529
33551	1320	\N	\N	1090	1	standalone	2026-06-20 19:55:00.729529
33552	1320	\N	\N	1801	1	standalone	2026-06-20 19:55:00.729529
33553	1319	\N	\N	1312	1	standalone	2026-06-20 19:55:00.729529
33554	1303	\N	\N	1494	1	standalone	2026-06-20 19:55:00.729529
33555	1320	\N	\N	2971	1	standalone	2026-06-20 19:55:00.729529
33556	1303	\N	\N	506	1	standalone	2026-06-20 19:55:00.729529
33557	1309	\N	\N	2325	1	standalone	2026-06-20 19:55:00.729529
33558	1310	\N	\N	1091	1	standalone	2026-06-20 19:55:00.729529
33559	1320	\N	\N	1802	1	standalone	2026-06-20 19:55:00.729529
33560	1319	\N	\N	1313	1	standalone	2026-06-20 19:55:00.729529
33561	1317	\N	\N	1496	1	standalone	2026-06-20 19:55:00.729529
33562	1320	\N	\N	2972	1	standalone	2026-06-20 19:55:00.729529
33563	1303	\N	\N	508	1	standalone	2026-06-20 19:55:00.729529
33564	1320	\N	\N	2333	1	standalone	2026-06-20 19:55:00.729529
33565	1320	\N	\N	1092	1	standalone	2026-06-20 19:55:00.729529
33566	1320	\N	\N	1803	1	standalone	2026-06-20 19:55:00.729529
33567	1309	\N	\N	1315	1	standalone	2026-06-20 19:55:00.729529
33568	1320	\N	\N	1498	1	standalone	2026-06-20 19:55:00.729529
33569	1320	\N	\N	2977	1	standalone	2026-06-20 19:55:00.729529
33570	1304	\N	\N	509	1	standalone	2026-06-20 19:55:00.729529
33571	1320	\N	\N	2334	1	standalone	2026-06-20 19:55:00.729529
33572	1320	\N	\N	1093	1	standalone	2026-06-20 19:55:00.729529
33573	1320	\N	\N	1804	1	standalone	2026-06-20 19:55:00.729529
33574	1320	\N	\N	1501	1	standalone	2026-06-20 19:55:00.729529
33575	1320	\N	\N	2978	1	standalone	2026-06-20 19:55:00.729529
33576	1304	\N	\N	510	1	standalone	2026-06-20 19:55:00.729529
33577	1309	\N	\N	2335	1	standalone	2026-06-20 19:55:00.729529
33578	1320	\N	\N	1094	1	standalone	2026-06-20 19:55:00.729529
33579	1306	\N	\N	1805	1	standalone	2026-06-20 19:55:00.729529
33580	1320	\N	\N	1502	1	standalone	2026-06-20 19:55:00.729529
33581	1320	\N	\N	2979	1	standalone	2026-06-20 19:55:00.729529
33582	1304	\N	\N	512	1	standalone	2026-06-20 19:55:00.729529
33583	1309	\N	\N	2344	1	standalone	2026-06-20 19:55:00.729529
33584	1320	\N	\N	1095	1	standalone	2026-06-20 19:55:00.729529
33585	1320	\N	\N	1806	1	standalone	2026-06-20 19:55:00.729529
33586	1320	\N	\N	1503	1	standalone	2026-06-20 19:55:00.729529
33587	1309	\N	\N	2985	1	standalone	2026-06-20 19:55:00.729529
33588	1304	\N	\N	513	1	standalone	2026-06-20 19:55:00.729529
33589	1307	\N	\N	2346	1	standalone	2026-06-20 19:55:00.729529
33590	1320	\N	\N	1096	1	standalone	2026-06-20 19:55:00.729529
33591	1312	\N	\N	1807	1	standalone	2026-06-20 19:55:00.729529
33592	1320	\N	\N	1505	1	standalone	2026-06-20 19:55:00.729529
33593	1320	\N	\N	2988	1	standalone	2026-06-20 19:55:00.729529
33594	1304	\N	\N	514	1	standalone	2026-06-20 19:55:00.729529
33595	1307	\N	\N	2351	1	standalone	2026-06-20 19:55:00.729529
33596	1320	\N	\N	1097	1	standalone	2026-06-20 19:55:00.729529
33597	1320	\N	\N	1808	1	standalone	2026-06-20 19:55:00.729529
33598	1317	\N	\N	1506	1	standalone	2026-06-20 19:55:00.729529
33599	1320	\N	\N	3009	1	standalone	2026-06-20 19:55:00.729529
33600	1304	\N	\N	515	1	standalone	2026-06-20 19:55:00.729529
33601	1310	\N	\N	2353	1	standalone	2026-06-20 19:55:00.729529
33602	1320	\N	\N	1098	1	standalone	2026-06-20 19:55:00.729529
33603	1320	\N	\N	1809	1	standalone	2026-06-20 19:55:00.729529
33604	1320	\N	\N	1508	1	standalone	2026-06-20 19:55:00.729529
33605	1320	\N	\N	3012	1	standalone	2026-06-20 19:55:00.729529
33606	1304	\N	\N	516	1	standalone	2026-06-20 19:55:00.729529
33607	1305	\N	\N	2399	1	standalone	2026-06-20 19:55:00.729529
33608	1306	\N	\N	1099	1	standalone	2026-06-20 19:55:00.729529
33609	1320	\N	\N	1509	1	standalone	2026-06-20 19:55:00.729529
33610	1320	\N	\N	3026	1	standalone	2026-06-20 19:55:00.729529
33611	1304	\N	\N	517	1	standalone	2026-06-20 19:55:00.729529
33612	1305	\N	\N	2400	1	standalone	2026-06-20 19:55:00.729529
33613	1320	\N	\N	1100	1	standalone	2026-06-20 19:55:00.729529
33614	1320	\N	\N	1510	1	standalone	2026-06-20 19:55:00.729529
33615	1320	\N	\N	3027	1	standalone	2026-06-20 19:55:00.729529
33616	1304	\N	\N	521	1	standalone	2026-06-20 19:55:00.729529
33617	1316	\N	\N	2445	1	standalone	2026-06-20 19:55:00.729529
33618	1320	\N	\N	1102	1	standalone	2026-06-20 19:55:00.729529
33619	1303	\N	\N	1513	1	standalone	2026-06-20 19:55:00.729529
33620	1320	\N	\N	3028	1	standalone	2026-06-20 19:55:00.729529
33621	1304	\N	\N	522	1	standalone	2026-06-20 19:55:00.729529
33622	1309	\N	\N	2450	1	standalone	2026-06-20 19:55:00.729529
33623	1320	\N	\N	1103	1	standalone	2026-06-20 19:55:00.729529
33624	1320	\N	\N	1519	1	standalone	2026-06-20 19:55:00.729529
33625	1320	\N	\N	3029	1	standalone	2026-06-20 19:55:00.729529
33626	1306	\N	\N	523	1	standalone	2026-06-20 19:55:00.729529
33627	1309	\N	\N	2456	1	standalone	2026-06-20 19:55:00.729529
33628	1320	\N	\N	1104	1	standalone	2026-06-20 19:55:00.729529
33629	1303	\N	\N	1524	1	standalone	2026-06-20 19:55:00.729529
33630	1312	\N	\N	3030	1	standalone	2026-06-20 19:55:00.729529
33631	1304	\N	\N	524	1	standalone	2026-06-20 19:55:00.729529
33632	1309	\N	\N	2457	1	standalone	2026-06-20 19:55:00.729529
33633	1312	\N	\N	1105	1	standalone	2026-06-20 19:55:00.729529
33634	1303	\N	\N	1525	1	standalone	2026-06-20 19:55:00.729529
33635	1312	\N	\N	3031	1	standalone	2026-06-20 19:55:00.729529
33636	1304	\N	\N	525	1	standalone	2026-06-20 19:55:00.729529
33637	1313	\N	\N	2461	1	standalone	2026-06-20 19:55:00.729529
33638	1320	\N	\N	1106	1	standalone	2026-06-20 19:55:00.729529
33639	1303	\N	\N	1529	1	standalone	2026-06-20 19:55:00.729529
33640	1312	\N	\N	3032	1	standalone	2026-06-20 19:55:00.729529
33641	1304	\N	\N	526	1	standalone	2026-06-20 19:55:00.729529
33642	1312	\N	\N	2467	1	standalone	2026-06-20 19:55:00.729529
33643	1303	\N	\N	1531	1	standalone	2026-06-20 19:55:00.729529
33644	1303	\N	\N	3033	1	standalone	2026-06-20 19:55:00.729529
33645	1304	\N	\N	530	1	standalone	2026-06-20 19:55:00.729529
33646	1305	\N	\N	2475	1	standalone	2026-06-20 19:55:00.729529
33647	1320	\N	\N	1469	1	standalone	2026-06-20 19:55:00.729529
33648	1312	\N	\N	3037	1	standalone	2026-06-20 19:55:00.729529
33649	1304	\N	\N	531	1	standalone	2026-06-20 19:55:00.729529
33650	1309	\N	\N	2491	1	standalone	2026-06-20 19:55:00.729529
33651	1309	\N	\N	1536	1	standalone	2026-06-20 19:55:00.729529
33652	1320	\N	\N	3039	1	standalone	2026-06-20 19:55:00.729529
33653	1304	\N	\N	532	1	standalone	2026-06-20 19:55:00.729529
33654	1305	\N	\N	2494	1	standalone	2026-06-20 19:55:00.729529
33655	1304	\N	\N	1541	1	standalone	2026-06-20 19:55:00.729529
33656	1320	\N	\N	3040	1	standalone	2026-06-20 19:55:00.729529
33657	1304	\N	\N	533	1	standalone	2026-06-20 19:55:00.729529
33658	1312	\N	\N	2497	1	standalone	2026-06-20 19:55:00.729529
33659	1304	\N	\N	1543	1	standalone	2026-06-20 19:55:00.729529
33660	1313	\N	\N	3041	1	standalone	2026-06-20 19:55:00.729529
33661	1304	\N	\N	534	1	standalone	2026-06-20 19:55:00.729529
33662	1313	\N	\N	2498	1	standalone	2026-06-20 19:55:00.729529
33663	1303	\N	\N	1344	1	standalone	2026-06-20 19:55:00.729529
33664	1320	\N	\N	3042	1	standalone	2026-06-20 19:55:00.729529
33665	1304	\N	\N	535	1	standalone	2026-06-20 19:55:00.729529
33666	1315	\N	\N	2501	1	standalone	2026-06-20 19:55:00.729529
33667	1304	\N	\N	1346	1	standalone	2026-06-20 19:55:00.729529
33668	1311	\N	\N	3046	1	standalone	2026-06-20 19:55:00.729529
33669	1304	\N	\N	536	1	standalone	2026-06-20 19:55:00.729529
33670	1304	\N	\N	2510	1	standalone	2026-06-20 19:55:00.729529
33671	1304	\N	\N	1348	1	standalone	2026-06-20 19:55:00.729529
33672	1311	\N	\N	3047	1	standalone	2026-06-20 19:55:00.729529
33673	1305	\N	\N	537	1	standalone	2026-06-20 19:55:00.729529
33674	1309	\N	\N	2521	1	standalone	2026-06-20 19:55:00.729529
33675	1304	\N	\N	1352	1	standalone	2026-06-20 19:55:00.729529
33676	1315	\N	\N	3063	1	standalone	2026-06-20 19:55:00.729529
33677	1305	\N	\N	554	1	standalone	2026-06-20 19:55:00.729529
33678	1304	\N	\N	1353	1	standalone	2026-06-20 19:55:00.729529
33679	1311	\N	\N	3048	1	standalone	2026-06-20 19:55:00.729529
33680	1304	\N	\N	555	1	standalone	2026-06-20 19:55:00.729529
33681	1304	\N	\N	1354	1	standalone	2026-06-20 19:55:00.729529
33682	1311	\N	\N	3049	1	standalone	2026-06-20 19:55:00.729529
33683	1304	\N	\N	556	1	standalone	2026-06-20 19:55:00.729529
33684	1304	\N	\N	1355	1	standalone	2026-06-20 19:55:00.729529
33685	1304	\N	\N	3050	1	standalone	2026-06-20 19:55:00.729529
33686	1304	\N	\N	559	1	standalone	2026-06-20 19:55:00.729529
33687	1304	\N	\N	1356	1	standalone	2026-06-20 19:55:00.729529
33688	1311	\N	\N	3051	1	standalone	2026-06-20 19:55:00.729529
33689	1304	\N	\N	560	1	standalone	2026-06-20 19:55:00.729529
33690	1304	\N	\N	1357	1	standalone	2026-06-20 19:55:00.729529
33691	1315	\N	\N	3084	1	standalone	2026-06-20 19:55:00.729529
33692	1304	\N	\N	561	1	standalone	2026-06-20 19:55:00.729529
33693	1304	\N	\N	1358	1	standalone	2026-06-20 19:55:00.729529
33694	1315	\N	\N	3085	1	standalone	2026-06-20 19:55:00.729529
33695	1304	\N	\N	562	1	standalone	2026-06-20 19:55:00.729529
33696	1303	\N	\N	1359	1	standalone	2026-06-20 19:55:00.729529
33697	1315	\N	\N	3086	1	standalone	2026-06-20 19:55:00.729529
33698	1304	\N	\N	563	1	standalone	2026-06-20 19:55:00.729529
33699	1303	\N	\N	1360	1	standalone	2026-06-20 19:55:00.729529
33700	1315	\N	\N	3087	1	standalone	2026-06-20 19:55:00.729529
33701	1303	\N	\N	564	1	standalone	2026-06-20 19:55:00.729529
33702	1303	\N	\N	1364	1	standalone	2026-06-20 19:55:00.729529
33703	1315	\N	\N	3088	1	standalone	2026-06-20 19:55:00.729529
33704	1304	\N	\N	565	1	standalone	2026-06-20 19:55:00.729529
33705	1320	\N	\N	1370	1	standalone	2026-06-20 19:55:00.729529
33706	1315	\N	\N	3089	1	standalone	2026-06-20 19:55:00.729529
33707	1309	\N	\N	569	1	standalone	2026-06-20 19:55:00.729529
33708	1303	\N	\N	1378	1	standalone	2026-06-20 19:55:00.729529
33709	1315	\N	\N	3092	1	standalone	2026-06-20 19:55:00.729529
33710	1320	\N	\N	570	1	standalone	2026-06-20 19:55:00.729529
33711	1320	\N	\N	1380	1	standalone	2026-06-20 19:55:00.729529
33712	1315	\N	\N	3093	1	standalone	2026-06-20 19:55:00.729529
33713	1305	\N	\N	575	1	standalone	2026-06-20 19:55:00.729529
33714	1303	\N	\N	1381	1	standalone	2026-06-20 19:55:00.729529
33715	1315	\N	\N	3094	1	standalone	2026-06-20 19:55:00.729529
33716	1315	\N	\N	576	1	standalone	2026-06-20 19:55:00.729529
33717	1303	\N	\N	1382	1	standalone	2026-06-20 19:55:00.729529
33718	1315	\N	\N	3095	1	standalone	2026-06-20 19:55:00.729529
33719	1320	\N	\N	577	1	standalone	2026-06-20 19:55:00.729529
33720	1320	\N	\N	1383	1	standalone	2026-06-20 19:55:00.729529
33721	1315	\N	\N	3096	1	standalone	2026-06-20 19:55:00.729529
33722	1305	\N	\N	578	1	standalone	2026-06-20 19:55:00.729529
33723	1320	\N	\N	1384	1	standalone	2026-06-20 19:55:00.729529
33724	1315	\N	\N	3097	1	standalone	2026-06-20 19:55:00.729529
33725	1305	\N	\N	579	1	standalone	2026-06-20 19:55:00.729529
33726	1320	\N	\N	1387	1	standalone	2026-06-20 19:55:00.729529
33727	1315	\N	\N	3098	1	standalone	2026-06-20 19:55:00.729529
33728	1305	\N	\N	580	1	standalone	2026-06-20 19:55:00.729529
33729	1320	\N	\N	1388	1	standalone	2026-06-20 19:55:00.729529
33730	1315	\N	\N	3099	1	standalone	2026-06-20 19:55:00.729529
33731	1305	\N	\N	581	1	standalone	2026-06-20 19:55:00.729529
33732	1320	\N	\N	1406	1	standalone	2026-06-20 19:55:00.729529
33733	1315	\N	\N	3101	1	standalone	2026-06-20 19:55:00.729529
33734	1305	\N	\N	582	1	standalone	2026-06-20 19:55:00.729529
33735	1320	\N	\N	1412	1	standalone	2026-06-20 19:55:00.729529
33736	1315	\N	\N	3102	1	standalone	2026-06-20 19:55:00.729529
33737	1305	\N	\N	583	1	standalone	2026-06-20 19:55:00.729529
33738	1320	\N	\N	1421	1	standalone	2026-06-20 19:55:00.729529
33739	1315	\N	\N	3103	1	standalone	2026-06-20 19:55:00.729529
33740	1320	\N	\N	1427	1	standalone	2026-06-20 19:55:00.729529
33741	1320	\N	\N	1434	1	standalone	2026-06-20 19:55:00.729529
33742	1320	\N	\N	1435	1	standalone	2026-06-20 19:55:00.729529
33743	1320	\N	\N	1437	1	standalone	2026-06-20 19:55:00.729529
33744	1320	\N	\N	1441	1	standalone	2026-06-20 19:55:00.729529
33745	1320	\N	\N	1442	1	standalone	2026-06-20 19:55:00.729529
33746	1320	\N	\N	1454	1	standalone	2026-06-20 19:55:00.729529
33747	1320	\N	\N	1455	1	standalone	2026-06-20 19:55:00.729529
33748	1320	\N	\N	1457	1	standalone	2026-06-20 19:55:00.729529
33749	1320	\N	\N	1461	1	standalone	2026-06-20 19:55:00.729529
33750	1320	\N	\N	1462	1	standalone	2026-06-20 19:55:00.729529
33751	1320	\N	\N	1471	1	standalone	2026-06-20 19:55:00.729529
33752	1320	\N	\N	1472	1	standalone	2026-06-20 19:55:00.729529
33753	1320	\N	\N	1473	1	standalone	2026-06-20 19:55:00.729529
33754	1320	\N	\N	1476	1	standalone	2026-06-20 19:55:00.729529
33755	1320	\N	\N	1484	1	standalone	2026-06-20 19:55:00.729529
33756	1320	\N	\N	1486	1	standalone	2026-06-20 19:55:00.729529
33757	1320	\N	\N	1489	1	standalone	2026-06-20 19:55:00.729529
33758	1320	\N	\N	1499	1	standalone	2026-06-20 19:55:00.729529
33759	1320	\N	\N	1504	1	standalone	2026-06-20 19:55:00.729529
33760	1320	\N	\N	1507	1	standalone	2026-06-20 19:55:00.729529
33761	1320	\N	\N	1511	1	standalone	2026-06-20 19:55:00.729529
33762	1303	\N	\N	1533	1	standalone	2026-06-20 19:55:00.729529
33763	1320	\N	\N	1500	1	standalone	2026-06-20 19:55:00.729529
33764	1320	\N	\N	1368	1	standalone	2026-06-20 19:55:00.729529
33765	1320	\N	\N	1429	1	standalone	2026-06-20 19:55:00.729529
33766	1320	\N	\N	1431	1	standalone	2026-06-20 19:55:00.729529
33767	1320	\N	\N	1373	1	standalone	2026-06-20 19:55:00.729529
33768	1320	\N	\N	1497	1	standalone	2026-06-20 19:55:00.729529
33769	1304	\N	\N	1351	1	standalone	2026-06-20 19:55:00.729529
33770	1320	\N	\N	1369	1	standalone	2026-06-20 19:55:00.729529
33771	1320	\N	\N	1386	1	standalone	2026-06-20 19:55:00.729529
33772	1320	\N	\N	1404	1	standalone	2026-06-20 19:55:00.729529
33773	1320	\N	\N	1474	1	standalone	2026-06-20 19:55:00.729529
33774	1320	\N	\N	1478	1	standalone	2026-06-20 19:55:00.729529
33775	1317	\N	\N	1481	1	standalone	2026-06-20 19:55:00.729529
30416	1303	\N	\N	640	1	domain	2026-06-20 19:40:05.786203
30417	1303	\N	\N	641	1	domain	2026-06-20 19:40:05.786203
33776	1317	\N	\N	1482	1	standalone	2026-06-20 19:55:00.729529
30418	1303	\N	\N	660	1	domain	2026-06-20 19:40:05.786203
30419	1303	\N	\N	662	1	domain	2026-06-20 19:40:05.786203
33777	1303	\N	\N	1495	1	standalone	2026-06-20 19:55:00.729529
30420	1303	\N	\N	2089	1	domain	2026-06-20 19:40:05.786203
30421	1303	\N	\N	665	1	domain	2026-06-20 19:40:05.786203
30422	1303	\N	\N	669	1	domain	2026-06-20 19:40:05.786203
30423	1303	\N	\N	670	1	domain	2026-06-20 19:40:05.786203
35523	1323	\N	\N	1316	1	standalone	2026-06-21 05:44:33.760601
30424	1303	\N	\N	977	1	domain	2026-06-20 19:40:05.786203
30425	1303	\N	\N	1894	1	domain	2026-06-20 19:40:05.786203
30426	1303	\N	\N	3141	1	domain	2026-06-20 19:40:05.786203
30427	1303	\N	\N	676	1	domain	2026-06-20 19:40:05.786203
30428	1303	\N	\N	1586	1	domain	2026-06-20 19:40:05.786203
30429	1303	\N	\N	440	1	domain	2026-06-20 19:40:05.786203
30430	1303	\N	\N	441	1	domain	2026-06-20 19:40:05.786203
30431	1303	\N	\N	442	1	domain	2026-06-20 19:40:05.786203
30432	1303	\N	\N	802	1	domain	2026-06-20 19:40:05.786203
30433	1303	\N	\N	803	1	domain	2026-06-20 19:40:05.786203
35524	1323	\N	\N	1323	1	standalone	2026-06-21 05:44:33.760601
30434	1303	\N	\N	742	1	domain	2026-06-20 19:40:05.786203
30435	1303	\N	\N	743	1	domain	2026-06-20 19:40:05.786203
30436	1303	\N	\N	744	1	domain	2026-06-20 19:40:05.786203
30437	1303	\N	\N	3312	1	domain	2026-06-20 19:40:05.786203
30438	1303	\N	\N	456	1	domain	2026-06-20 19:40:05.786203
30439	1303	\N	\N	463	1	domain	2026-06-20 19:40:05.786203
35525	1323	\N	\N	1327	1	standalone	2026-06-21 05:44:33.760601
35526	1323	\N	\N	2310	1	standalone	2026-06-21 05:44:33.760601
35527	1323	\N	\N	2314	1	standalone	2026-06-21 05:44:33.760601
35528	1323	\N	\N	2442	1	standalone	2026-06-21 05:44:33.760601
35529	1323	\N	\N	1962	1	standalone	2026-06-21 05:44:33.760601
35531	1323	\N	\N	3136	1	domain	2026-06-21 05:44:33.771784
35532	1323	\N	\N	1892	1	domain	2026-06-21 05:44:33.771784
35533	1323	\N	\N	727	1	domain	2026-06-21 05:44:33.771784
35534	1322	\N	\N	2627	1	standalone	2026-06-21 05:44:33.771784
35535	1322	\N	\N	2629	1	standalone	2026-06-21 05:44:33.771784
35536	1322	\N	\N	2614	1	standalone	2026-06-21 05:44:33.771784
35537	1322	\N	\N	2631	1	standalone	2026-06-21 05:44:33.771784
35538	1322	\N	\N	2632	1	standalone	2026-06-21 05:44:33.771784
35540	1322	\N	\N	2063	1	domain	2026-06-21 05:44:33.789766
35541	1322	\N	\N	2071	1	domain	2026-06-21 05:44:33.789766
35542	1322	\N	\N	2730	1	domain	2026-06-21 05:44:33.789766
35544	1322	\N	\N	2073	1	domain	2026-06-21 05:44:33.799828
35545	1322	\N	\N	2667	1	domain	2026-06-21 05:44:33.799828
35546	1322	\N	\N	2733	1	domain	2026-06-21 05:44:33.799828
35547	1322	\N	\N	2660	1	standalone	2026-06-21 05:44:33.799828
35548	1322	\N	\N	2661	1	standalone	2026-06-21 05:44:33.799828
30440	1303	\N	\N	464	1	domain	2026-06-20 19:40:05.786203
30441	1303	\N	\N	466	1	domain	2026-06-20 19:40:05.786203
30442	1303	\N	\N	469	1	domain	2026-06-20 19:40:05.786203
33779	1322	\N	\N	2905	1	domain	2026-06-21 05:44:31.489528
33780	1322	\N	\N	1135	1	domain	2026-06-21 05:44:31.489528
33781	1322	\N	\N	1822	1	domain	2026-06-21 05:44:31.489528
33782	1322	\N	\N	2107	1	domain	2026-06-21 05:44:31.489528
33783	1322	\N	\N	2133	1	domain	2026-06-21 05:44:31.489528
33784	1322	\N	\N	2138	1	domain	2026-06-21 05:44:31.489528
33785	1322	\N	\N	2414	1	domain	2026-06-21 05:44:31.489528
33786	1323	\N	\N	2577	1	standalone	2026-06-21 05:44:31.512364
33787	1323	\N	\N	1258	1	standalone	2026-06-21 05:44:31.512364
33789	1323	\N	\N	2591	1	domain	2026-06-21 05:44:31.539574
33790	1323	\N	\N	180	1	domain	2026-06-21 05:44:31.539574
33791	1323	\N	\N	3205	1	domain	2026-06-21 05:44:31.539574
33792	1323	\N	\N	866	1	domain	2026-06-21 05:44:31.539574
33793	1323	\N	\N	137	1	domain	2026-06-21 05:44:31.539574
33794	1323	\N	\N	1259	1	standalone	2026-06-21 05:44:31.539574
33795	1323	\N	\N	1897	1	standalone	2026-06-21 05:44:31.539574
33799	1323	\N	\N	1901	1	standalone	2026-06-21 05:44:31.539574
33801	1323	\N	\N	1903	1	standalone	2026-06-21 05:44:31.539574
33802	1323	\N	\N	1904	1	standalone	2026-06-21 05:44:31.539574
33803	1323	\N	\N	1905	1	standalone	2026-06-21 05:44:31.539574
33805	1323	\N	\N	1718	1	standalone	2026-06-21 05:44:31.539574
33806	1323	\N	\N	1720	1	standalone	2026-06-21 05:44:31.539574
33807	1323	\N	\N	1250	1	standalone	2026-06-21 05:44:31.539574
33809	1323	\N	\N	1252	1	standalone	2026-06-21 05:44:31.539574
33810	1323	\N	\N	1253	1	standalone	2026-06-21 05:44:31.539574
33811	1323	\N	\N	1254	1	standalone	2026-06-21 05:44:31.539574
33812	1323	\N	\N	1255	1	standalone	2026-06-21 05:44:31.539574
33813	1323	\N	\N	1256	1	standalone	2026-06-21 05:44:31.539574
33814	1323	\N	\N	1257	1	standalone	2026-06-21 05:44:31.539574
33815	1323	\N	\N	2440	1	standalone	2026-06-21 05:44:31.539574
33816	1323	\N	\N	2444	1	standalone	2026-06-21 05:44:31.539574
33818	1323	\N	\N	3393	1	domain	2026-06-21 05:44:31.544848
33819	1323	\N	\N	2825	1	domain	2026-06-21 05:44:31.544848
33820	1323	\N	\N	2826	1	domain	2026-06-21 05:44:31.544848
33829	1325	\N	\N	1	1	domain	2026-06-21 05:44:31.571763
33830	1325	\N	\N	3	1	domain	2026-06-21 05:44:31.571763
33831	1325	\N	\N	1559	1	domain	2026-06-21 05:44:31.571763
33832	1325	\N	\N	2084	1	domain	2026-06-21 05:44:31.571763
33833	1325	\N	\N	2672	1	domain	2026-06-21 05:44:31.571763
33834	1325	\N	\N	2673	1	domain	2026-06-21 05:44:31.571763
33836	1325	\N	\N	3191	1	domain	2026-06-21 05:44:31.57815
33837	1325	\N	\N	2085	1	domain	2026-06-21 05:44:31.57815
33839	1325	\N	\N	2866	1	domain	2026-06-21 05:44:31.594534
33840	1325	\N	\N	1123	1	domain	2026-06-21 05:44:31.594534
33842	1325	\N	\N	2895	1	domain	2026-06-21 05:44:31.594534
33843	1325	\N	\N	2896	1	domain	2026-06-21 05:44:31.594534
33844	1325	\N	\N	2897	1	domain	2026-06-21 05:44:31.594534
33846	1325	\N	\N	362	1	standalone	2026-06-21 05:44:31.594534
33847	1325	\N	\N	2086	1	standalone	2026-06-21 05:44:31.594534
33849	1322	\N	\N	748	1	domain	2026-06-21 05:44:31.610344
33850	1322	\N	\N	163	1	domain	2026-06-21 05:44:31.610344
33854	1326	\N	\N	279	1	domain	2026-06-21 05:44:31.623499
33855	1326	\N	\N	2421	1	domain	2026-06-21 05:44:31.623499
33856	1326	\N	\N	2419	1	standalone	2026-06-21 05:44:31.623499
33858	1326	\N	\N	2420	1	domain	2026-06-21 05:44:31.633075
33859	1326	\N	\N	1916	1	domain	2026-06-21 05:44:31.633075
33860	1326	\N	\N	1278	1	domain	2026-06-21 05:44:31.633075
33862	1326	\N	\N	1846	1	domain	2026-06-21 05:44:31.643175
33863	1326	\N	\N	2690	1	domain	2026-06-21 05:44:31.643175
33865	1326	\N	\N	2596	1	domain	2026-06-21 05:44:31.654802
33866	1326	\N	\N	185	1	domain	2026-06-21 05:44:31.654802
33867	1326	\N	\N	3396	1	domain	2026-06-21 05:44:31.654802
33868	1326	\N	\N	92	1	domain	2026-06-21 05:44:31.654802
33869	1326	\N	\N	93	1	domain	2026-06-21 05:44:31.654802
33870	1326	\N	\N	1912	1	standalone	2026-06-21 05:44:31.654802
33871	1326	\N	\N	1911	1	standalone	2026-06-21 05:44:31.654802
33873	1326	\N	\N	1913	1	domain	2026-06-21 05:44:31.661684
33874	1326	\N	\N	276	1	domain	2026-06-21 05:44:31.661684
33875	1326	\N	\N	1726	1	domain	2026-06-21 05:44:31.661684
33876	1326	\N	\N	1914	1	standalone	2026-06-21 05:44:31.661684
33877	1326	\N	\N	1917	1	standalone	2026-06-21 05:44:31.661684
33878	1326	\N	\N	1920	1	standalone	2026-06-21 05:44:31.661684
33880	1326	\N	\N	1921	1	domain	2026-06-21 05:44:31.671704
33881	1326	\N	\N	1320	1	domain	2026-06-21 05:44:31.671704
33883	1326	\N	\N	275	1	domain	2026-06-21 05:44:31.678557
33884	1326	\N	\N	2296	1	domain	2026-06-21 05:44:31.678557
33885	1326	\N	\N	2332	1	domain	2026-06-21 05:44:31.678557
33886	1326	\N	\N	2336	1	domain	2026-06-21 05:44:31.678557
33887	1326	\N	\N	281	1	standalone	2026-06-21 05:44:31.678557
33888	1326	\N	\N	282	1	standalone	2026-06-21 05:44:31.678557
33889	1326	\N	\N	838	1	standalone	2026-06-21 05:44:31.678557
33890	1326	\N	\N	1277	1	standalone	2026-06-21 05:44:31.678557
33825	1324	\N	\N	2675	1	standalone	2026-06-21 05:44:31.561354
33824	1324	\N	\N	2674	1	standalone	2026-06-21 05:44:31.561354
33827	1324	\N	\N	2677	1	standalone	2026-06-21 05:44:31.561354
33822	1324	\N	\N	2628	1	standalone	2026-06-21 05:44:31.561354
33826	1324	\N	\N	2676	1	standalone	2026-06-21 05:44:31.561354
33804	1323	\N	\N	3307	1	domain	2026-06-21 05:44:31.539574
33796	1323	\N	\N	1898	1	domain	2026-06-21 05:44:31.539574
33797	1323	\N	\N	1899	1	domain	2026-06-21 05:44:31.539574
33798	1323	\N	\N	1900	1	domain	2026-06-21 05:44:31.539574
33800	1323	\N	\N	1902	1	domain	2026-06-21 05:44:31.539574
33808	1323	\N	\N	1251	1	domain	2026-06-21 05:44:31.539574
33893	1326	\N	\N	302	1	domain	2026-06-21 05:44:31.695317
33894	1326	\N	\N	1269	1	domain	2026-06-21 05:44:31.695317
33895	1326	\N	\N	2283	1	standalone	2026-06-21 05:44:31.695317
33896	1326	\N	\N	2327	1	standalone	2026-06-21 05:44:31.695317
33899	1326	\N	\N	697	1	domain	2026-06-21 05:44:31.705238
33900	1326	\N	\N	3273	1	domain	2026-06-21 05:44:31.705238
33903	1326	\N	\N	1009	1	domain	2026-06-21 05:44:31.705238
33904	1326	\N	\N	277	1	domain	2026-06-21 05:44:31.705238
33905	1326	\N	\N	837	1	domain	2026-06-21 05:44:31.705238
33907	1327	\N	\N	1693	1	standalone	2026-06-21 05:44:31.719259
33910	1327	\N	\N	3318	1	domain	2026-06-21 05:44:31.728048
33911	1327	\N	\N	753	1	domain	2026-06-21 05:44:31.728048
33912	1327	\N	\N	177	1	domain	2026-06-21 05:44:31.728048
33913	1327	\N	\N	1238	1	domain	2026-06-21 05:44:31.728048
33914	1327	\N	\N	2200	1	domain	2026-06-21 05:44:31.728048
33917	1327	\N	\N	11	1	domain	2026-06-21 05:44:31.762147
33918	1327	\N	\N	3196	1	domain	2026-06-21 05:44:31.762147
33919	1327	\N	\N	782	1	domain	2026-06-21 05:44:31.762147
33920	1327	\N	\N	566	1	domain	2026-06-21 05:44:31.762147
33922	1327	\N	\N	694	1	domain	2026-06-21 05:44:31.771806
33923	1327	\N	\N	961	1	domain	2026-06-21 05:44:31.771806
33924	1327	\N	\N	444	1	domain	2026-06-21 05:44:31.771806
33926	1327	\N	\N	1597	1	domain	2026-06-21 05:44:31.778603
33927	1327	\N	\N	1828	1	domain	2026-06-21 05:44:31.778603
33928	1327	\N	\N	1943	1	domain	2026-06-21 05:44:31.778603
33930	1327	\N	\N	3268	1	domain	2026-06-21 05:44:31.786826
33931	1327	\N	\N	2922	1	domain	2026-06-21 05:44:31.786826
33932	1327	\N	\N	1944	1	domain	2026-06-21 05:44:31.786826
33934	1327	\N	\N	3128	1	domain	2026-06-21 05:44:31.797638
30443	1303	\N	\N	1526	1	domain	2026-06-20 19:40:05.786203
33935	1327	\N	\N	3222	1	domain	2026-06-21 05:44:31.797638
33936	1327	\N	\N	3311	1	domain	2026-06-21 05:44:31.797638
33937	1327	\N	\N	242	1	standalone	2026-06-21 05:44:31.797638
33938	1327	\N	\N	243	1	standalone	2026-06-21 05:44:31.797638
30444	1303	\N	\N	2719	1	domain	2026-06-20 19:40:05.786203
33939	1327	\N	\N	3366	1	standalone	2026-06-21 05:44:31.797638
30445	1303	\N	\N	2721	1	domain	2026-06-20 19:40:05.786203
30446	1303	\N	\N	1699	1	domain	2026-06-20 19:40:05.786203
30447	1303	\N	\N	1700	1	domain	2026-06-20 19:40:05.786203
30448	1303	\N	\N	2204	1	domain	2026-06-20 19:40:05.786203
30449	1303	\N	\N	899	1	domain	2026-06-20 19:40:05.786203
30450	1303	\N	\N	900	1	domain	2026-06-20 19:40:05.786203
30451	1303	\N	\N	901	1	domain	2026-06-20 19:40:05.786203
30452	1303	\N	\N	902	1	domain	2026-06-20 19:40:05.786203
30453	1303	\N	\N	903	1	domain	2026-06-20 19:40:05.786203
30454	1303	\N	\N	1516	1	domain	2026-06-20 19:40:05.786203
30455	1303	\N	\N	2293	1	domain	2026-06-20 19:40:05.786203
30456	1303	\N	\N	2390	1	domain	2026-06-20 19:40:05.786203
30458	1303	\N	\N	3186	1	domain	2026-06-20 19:40:05.794344
30459	1303	\N	\N	172	1	domain	2026-06-20 19:40:05.794344
30460	1303	\N	\N	22	1	domain	2026-06-20 19:40:05.794344
30461	1303	\N	\N	2584	1	domain	2026-06-20 19:40:05.794344
30462	1303	\N	\N	216	1	domain	2026-06-20 19:40:05.794344
30463	1303	\N	\N	19	1	domain	2026-06-20 19:40:05.794344
30464	1303	\N	\N	20	1	domain	2026-06-20 19:40:05.794344
33940	1327	\N	\N	69	1	standalone	2026-06-21 05:44:31.797638
33941	1327	\N	\N	538	1	standalone	2026-06-21 05:44:31.797638
33942	1327	\N	\N	539	1	standalone	2026-06-21 05:44:31.797638
33943	1327	\N	\N	540	1	standalone	2026-06-21 05:44:31.797638
33944	1327	\N	\N	541	1	standalone	2026-06-21 05:44:31.797638
33945	1327	\N	\N	542	1	standalone	2026-06-21 05:44:31.797638
33946	1327	\N	\N	543	1	standalone	2026-06-21 05:44:31.797638
33947	1327	\N	\N	544	1	standalone	2026-06-21 05:44:31.797638
33948	1327	\N	\N	545	1	standalone	2026-06-21 05:44:31.797638
33949	1327	\N	\N	546	1	standalone	2026-06-21 05:44:31.797638
33950	1327	\N	\N	1271	1	standalone	2026-06-21 05:44:31.797638
33951	1327	\N	\N	3034	1	standalone	2026-06-21 05:44:31.797638
33953	1327	\N	\N	2249	1	standalone	2026-06-21 05:44:31.797638
33954	1327	\N	\N	2262	1	standalone	2026-06-21 05:44:31.797638
33955	1327	\N	\N	2395	1	standalone	2026-06-21 05:44:31.797638
33959	1327	\N	\N	2091	1	domain	2026-06-21 05:44:31.838377
33960	1327	\N	\N	445	1	domain	2026-06-21 05:44:31.838377
33965	1327	\N	\N	1945	1	domain	2026-06-21 05:44:31.838377
33970	1322	\N	\N	944	1	domain	2026-06-21 05:44:31.853
33971	1322	\N	\N	2579	1	domain	2026-06-21 05:44:31.853
33972	1322	\N	\N	1818	1	domain	2026-06-21 05:44:31.853
33973	1322	\N	\N	787	1	domain	2026-06-21 05:44:31.853
33974	1322	\N	\N	3356	1	domain	2026-06-21 05:44:31.853
33975	1322	\N	\N	123	1	domain	2026-06-21 05:44:31.853
33976	1322	\N	\N	2031	1	domain	2026-06-21 05:44:31.853
30465	1303	\N	\N	24	1	domain	2026-06-20 19:40:05.794344
30466	1303	\N	\N	813	1	domain	2026-06-20 19:40:05.794344
30467	1303	\N	\N	1514	1	domain	2026-06-20 19:40:05.794344
33979	1328	\N	\N	3207	1	domain	2026-06-21 05:44:31.861214
33980	1328	\N	\N	2592	1	domain	2026-06-21 05:44:31.861214
33981	1328	\N	\N	816	1	domain	2026-06-21 05:44:31.861214
33982	1328	\N	\N	2697	1	domain	2026-06-21 05:44:31.861214
33908	1327	\N	\N	2589	1	domain	2026-06-21 05:44:31.719259
33915	1327	\N	\N	10	1	domain	2026-06-21 05:44:31.728048
33952	1327	\N	\N	1426	1	domain	2026-06-21 05:44:31.797638
33985	1328	\N	\N	2694	1	domain	2026-06-21 05:44:31.876739
33986	1328	\N	\N	2620	1	domain	2026-06-21 05:44:31.876739
33987	1328	\N	\N	819	1	domain	2026-06-21 05:44:31.876739
33988	1328	\N	\N	3383	1	domain	2026-06-21 05:44:31.876739
33989	1328	\N	\N	181	1	domain	2026-06-21 05:44:31.876739
33990	1328	\N	\N	713	1	domain	2026-06-21 05:44:31.876739
33991	1328	\N	\N	1576	1	domain	2026-06-21 05:44:31.876739
33993	1328	\N	\N	2754	1	domain	2026-06-21 05:44:31.876739
33995	1328	\N	\N	2593	1	domain	2026-06-21 05:44:31.888851
33996	1328	\N	\N	182	1	domain	2026-06-21 05:44:31.888851
33997	1328	\N	\N	996	1	domain	2026-06-21 05:44:31.888851
33998	1328	\N	\N	56	1	domain	2026-06-21 05:44:31.888851
33999	1328	\N	\N	60	1	domain	2026-06-21 05:44:31.888851
34000	1328	\N	\N	61	1	domain	2026-06-21 05:44:31.888851
34003	1328	\N	\N	183	1	domain	2026-06-21 05:44:31.888851
34004	1328	\N	\N	3208	1	domain	2026-06-21 05:44:31.888851
34005	1328	\N	\N	3210	1	domain	2026-06-21 05:44:31.888851
34006	1328	\N	\N	994	1	domain	2026-06-21 05:44:31.888851
34007	1328	\N	\N	53	1	domain	2026-06-21 05:44:31.888851
34011	1328	\N	\N	3209	1	domain	2026-06-21 05:44:31.903226
34012	1328	\N	\N	993	1	domain	2026-06-21 05:44:31.903226
34013	1328	\N	\N	51	1	domain	2026-06-21 05:44:31.903226
34014	1328	\N	\N	818	1	domain	2026-06-21 05:44:31.903226
34024	1328	\N	\N	59	1	domain	2026-06-21 05:44:31.917841
34025	1328	\N	\N	823	1	domain	2026-06-21 05:44:31.917841
34026	1328	\N	\N	2315	1	domain	2026-06-21 05:44:31.917841
34028	1328	\N	\N	2699	1	domain	2026-06-21 05:44:31.932216
34029	1328	\N	\N	2468	1	domain	2026-06-21 05:44:31.932216
34030	1328	\N	\N	2476	1	domain	2026-06-21 05:44:31.932216
34031	1328	\N	\N	2479	1	domain	2026-06-21 05:44:31.932216
34033	1328	\N	\N	3197	1	domain	2026-06-21 05:44:31.932216
34034	1328	\N	\N	3206	1	domain	2026-06-21 05:44:31.932216
34035	1328	\N	\N	989	1	domain	2026-06-21 05:44:31.932216
34036	1328	\N	\N	46	1	domain	2026-06-21 05:44:31.932216
34037	1328	\N	\N	815	1	domain	2026-06-21 05:44:31.932216
34039	1328	\N	\N	110	1	standalone	2026-06-21 05:44:31.932216
34040	1328	\N	\N	2520	1	standalone	2026-06-21 05:44:31.932216
34041	1328	\N	\N	2524	1	standalone	2026-06-21 05:44:31.932216
34043	1328	\N	\N	717	1	domain	2026-06-21 05:44:31.948158
34044	1328	\N	\N	991	1	domain	2026-06-21 05:44:31.948158
34045	1328	\N	\N	48	1	domain	2026-06-21 05:44:31.948158
34047	1328	\N	\N	50	1	domain	2026-06-21 05:44:31.948158
34049	1328	\N	\N	817	1	domain	2026-06-21 05:44:31.948158
34052	1328	\N	\N	2919	1	domain	2026-06-21 05:44:31.948158
34059	1329	\N	\N	607	1	standalone	2026-06-21 05:44:31.974536
34060	1329	\N	\N	606	1	standalone	2026-06-21 05:44:31.974536
34062	1329	\N	\N	1837	1	domain	2026-06-21 05:44:31.987186
34063	1329	\N	\N	2597	1	domain	2026-06-21 05:44:31.987186
34064	1329	\N	\N	3334	1	domain	2026-06-21 05:44:31.987186
34065	1329	\N	\N	190	1	domain	2026-06-21 05:44:31.987186
34066	1329	\N	\N	1223	1	domain	2026-06-21 05:44:31.987186
34067	1329	\N	\N	1015	1	domain	2026-06-21 05:44:31.987186
34068	1329	\N	\N	284	1	domain	2026-06-21 05:44:31.987186
34069	1329	\N	\N	839	1	domain	2026-06-21 05:44:31.987186
34070	1329	\N	\N	94	1	domain	2026-06-21 05:44:31.987186
34071	1329	\N	\N	2930	1	standalone	2026-06-21 05:44:31.987186
34072	1329	\N	\N	1224	1	standalone	2026-06-21 05:44:31.987186
34073	1329	\N	\N	1225	1	standalone	2026-06-21 05:44:31.987186
34074	1329	\N	\N	1226	1	standalone	2026-06-21 05:44:31.987186
34075	1329	\N	\N	1424	1	standalone	2026-06-21 05:44:31.987186
34076	1329	\N	\N	2003	1	standalone	2026-06-21 05:44:31.987186
34078	1327	\N	\N	3314	1	domain	2026-06-21 05:44:31.995433
34079	1327	\N	\N	749	1	domain	2026-06-21 05:44:31.995433
34080	1327	\N	\N	174	1	domain	2026-06-21 05:44:31.995433
34081	1327	\N	\N	2586	1	domain	2026-06-21 05:44:31.995433
34082	1327	\N	\N	63	1	domain	2026-06-21 05:44:31.995433
34083	1327	\N	\N	3214	1	domain	2026-06-21 05:44:31.995433
34084	1327	\N	\N	2243	1	domain	2026-06-21 05:44:31.995433
34085	1327	\N	\N	2244	1	domain	2026-06-21 05:44:31.995433
34088	1327	\N	\N	1859	1	standalone	2026-06-21 05:44:31.995433
34089	1327	\N	\N	1889	1	standalone	2026-06-21 05:44:31.995433
34090	1327	\N	\N	1941	1	standalone	2026-06-21 05:44:31.995433
34091	1327	\N	\N	1694	1	standalone	2026-06-21 05:44:31.995433
34092	1327	\N	\N	1592	1	standalone	2026-06-21 05:44:31.995433
34093	1327	\N	\N	689	1	standalone	2026-06-21 05:44:31.995433
34095	1327	\N	\N	3323	1	domain	2026-06-21 05:44:32.011888
34096	1327	\N	\N	1416	1	domain	2026-06-21 05:44:32.011888
34097	1327	\N	\N	1410	1	domain	2026-06-21 05:44:32.011888
34099	1327	\N	\N	2371	1	domain	2026-06-21 05:44:32.011888
34100	1327	\N	\N	2372	1	domain	2026-06-21 05:44:32.011888
34102	1327	\N	\N	1604	1	domain	2026-06-21 05:44:32.024391
34038	1328	\N	\N	62	1	domain	2026-06-21 05:44:31.932216
34103	1327	\N	\N	67	1	domain	2026-06-21 05:44:32.024391
34105	1327	\N	\N	691	1	domain	2026-06-21 05:44:32.028186
34106	1327	\N	\N	693	1	domain	2026-06-21 05:44:32.028186
34107	1327	\N	\N	723	1	domain	2026-06-21 05:44:32.028186
34108	1327	\N	\N	80	1	domain	2026-06-21 05:44:32.028186
34109	1327	\N	\N	1948	1	domain	2026-06-21 05:44:32.028186
34110	1327	\N	\N	2522	1	domain	2026-06-21 05:44:32.028186
34112	1327	\N	\N	1594	1	domain	2026-06-21 05:44:32.028186
34113	1327	\N	\N	1595	1	domain	2026-06-21 05:44:32.028186
34114	1327	\N	\N	1949	1	domain	2026-06-21 05:44:32.028186
34115	1327	\N	\N	1950	1	domain	2026-06-21 05:44:32.028186
34116	1327	\N	\N	418	1	standalone	2026-06-21 05:44:32.028186
34117	1327	\N	\N	443	1	standalone	2026-06-21 05:44:32.028186
34120	1327	\N	\N	3142	1	domain	2026-06-21 05:44:32.044061
34121	1327	\N	\N	1240	1	domain	2026-06-21 05:44:32.044061
34122	1327	\N	\N	725	1	standalone	2026-06-21 05:44:32.044061
34124	1327	\N	\N	396	1	domain	2026-06-21 05:44:32.044061
34125	1327	\N	\N	416	1	domain	2026-06-21 05:44:32.044061
34126	1327	\N	\N	714	1	domain	2026-06-21 05:44:32.044061
34127	1327	\N	\N	455	1	domain	2026-06-21 05:44:32.044061
34129	1327	\N	\N	763	1	domain	2026-06-21 05:44:32.069891
34130	1327	\N	\N	70	1	domain	2026-06-21 05:44:32.069891
34131	1327	\N	\N	73	1	domain	2026-06-21 05:44:32.069891
34132	1327	\N	\N	553	1	standalone	2026-06-21 05:44:32.069891
34134	1327	\N	\N	1283	1	standalone	2026-06-21 05:44:32.069891
34136	1327	\N	\N	869	1	domain	2026-06-21 05:44:32.077232
34137	1327	\N	\N	140	1	domain	2026-06-21 05:44:32.077232
34138	1327	\N	\N	2447	1	standalone	2026-06-21 05:44:32.077232
34139	1327	\N	\N	2256	1	standalone	2026-06-21 05:44:32.077232
34140	1327	\N	\N	2259	1	standalone	2026-06-21 05:44:32.077232
34141	1327	\N	\N	2260	1	standalone	2026-06-21 05:44:32.077232
34143	1327	\N	\N	792	1	domain	2026-06-21 05:44:32.091899
34144	1327	\N	\N	1005	1	domain	2026-06-21 05:44:32.091899
34145	1327	\N	\N	300	1	standalone	2026-06-21 05:44:32.091899
34147	1327	\N	\N	3126	1	domain	2026-06-21 05:44:32.100033
34148	1327	\N	\N	3129	1	domain	2026-06-21 05:44:32.100033
34149	1327	\N	\N	549	1	domain	2026-06-21 05:44:32.100033
34150	1327	\N	\N	212	1	standalone	2026-06-21 05:44:32.100033
34151	1327	\N	\N	1628	1	standalone	2026-06-21 05:44:32.100033
34152	1327	\N	\N	75	1	standalone	2026-06-21 05:44:32.100033
34153	1327	\N	\N	1668	1	standalone	2026-06-21 05:44:32.100033
34154	1327	\N	\N	2206	1	standalone	2026-06-21 05:44:32.100033
34155	1327	\N	\N	1936	1	standalone	2026-06-21 05:44:32.100033
34156	1327	\N	\N	1264	1	standalone	2026-06-21 05:44:32.100033
30468	1303	\N	\N	1522	1	domain	2026-06-20 19:40:05.794344
30469	1303	\N	\N	1990	1	domain	2026-06-20 19:40:05.794344
30470	1303	\N	\N	2750	1	domain	2026-06-20 19:40:05.794344
30471	1303	\N	\N	1515	1	domain	2026-06-20 19:40:05.794344
30472	1303	\N	\N	1521	1	domain	2026-06-20 19:40:05.794344
30473	1303	\N	\N	1520	1	domain	2026-06-20 19:40:05.794344
30474	1303	\N	\N	2377	1	domain	2026-06-20 19:40:05.794344
30475	1303	\N	\N	2378	1	domain	2026-06-20 19:40:05.794344
30476	1303	\N	\N	2379	1	domain	2026-06-20 19:40:05.794344
30477	1303	\N	\N	2381	1	domain	2026-06-20 19:40:05.794344
30478	1303	\N	\N	2448	1	domain	2026-06-20 19:40:05.794344
30479	1303	\N	\N	2458	1	domain	2026-06-20 19:40:05.794344
30480	1303	\N	\N	2459	1	domain	2026-06-20 19:40:05.794344
30482	1303	\N	\N	920	1	domain	2026-06-20 19:40:05.799582
30483	1303	\N	\N	1422	1	domain	2026-06-20 19:40:05.799582
30484	1303	\N	\N	1423	1	domain	2026-06-20 19:40:05.799582
30485	1303	\N	\N	1428	1	domain	2026-06-20 19:40:05.799582
34157	1327	\N	\N	118	1	standalone	2026-06-21 05:44:32.100033
34158	1327	\N	\N	420	1	standalone	2026-06-21 05:44:32.100033
34159	1327	\N	\N	424	1	standalone	2026-06-21 05:44:32.100033
34162	1327	\N	\N	3127	1	domain	2026-06-21 05:44:32.120663
34163	1327	\N	\N	1601	1	domain	2026-06-21 05:44:32.120663
34164	1327	\N	\N	958	1	domain	2026-06-21 05:44:32.120663
34165	1327	\N	\N	1605	1	domain	2026-06-21 05:44:32.120663
34166	1327	\N	\N	3266	1	domain	2026-06-21 05:44:32.120663
34168	1327	\N	\N	419	1	domain	2026-06-21 05:44:32.120663
34169	1327	\N	\N	422	1	domain	2026-06-21 05:44:32.120663
34170	1327	\N	\N	423	1	domain	2026-06-21 05:44:32.120663
34171	1327	\N	\N	427	1	domain	2026-06-21 05:44:32.120663
34173	1327	\N	\N	248	1	domain	2026-06-21 05:44:32.120663
34174	1327	\N	\N	249	1	domain	2026-06-21 05:44:32.120663
34184	1327	\N	\N	1375	1	domain	2026-06-21 05:44:32.120663
34185	1327	\N	\N	1233	1	domain	2026-06-21 05:44:32.120663
30487	1303	\N	\N	173	1	domain	2026-06-20 19:40:05.806753
30488	1303	\N	\N	2594	1	domain	2026-06-20 19:40:05.806753
34196	1330	\N	\N	1548	1	domain	2026-06-21 05:44:32.132998
34197	1330	\N	\N	3387	1	domain	2026-06-21 05:44:32.132998
34198	1330	\N	\N	612	1	domain	2026-06-21 05:44:32.132998
34133	1327	\N	\N	3224	1	domain	2026-06-21 05:44:32.069891
34160	1327	\N	\N	1687	1	domain	2026-06-21 05:44:32.100033
34199	1330	\N	\N	2013	1	domain	2026-06-21 05:44:32.132998
34201	1329	\N	\N	1833	1	domain	2026-06-21 05:44:32.141353
34202	1329	\N	\N	732	1	domain	2026-06-21 05:44:32.141353
34203	1329	\N	\N	106	1	domain	2026-06-21 05:44:32.141353
34204	1329	\N	\N	654	1	standalone	2026-06-21 05:44:32.141353
34205	1329	\N	\N	679	1	standalone	2026-06-21 05:44:32.141353
34206	1329	\N	\N	650	1	standalone	2026-06-21 05:44:32.141353
34207	1329	\N	\N	651	1	standalone	2026-06-21 05:44:32.141353
34208	1329	\N	\N	652	1	standalone	2026-06-21 05:44:32.141353
34210	1329	\N	\N	655	1	standalone	2026-06-21 05:44:32.141353
34211	1329	\N	\N	656	1	standalone	2026-06-21 05:44:32.141353
34212	1329	\N	\N	657	1	standalone	2026-06-21 05:44:32.141353
34213	1329	\N	\N	658	1	standalone	2026-06-21 05:44:32.141353
34214	1329	\N	\N	659	1	standalone	2026-06-21 05:44:32.141353
34215	1329	\N	\N	412	1	standalone	2026-06-21 05:44:32.141353
34216	1329	\N	\N	414	1	standalone	2026-06-21 05:44:32.141353
34217	1329	\N	\N	666	1	standalone	2026-06-21 05:44:32.141353
34218	1329	\N	\N	667	1	standalone	2026-06-21 05:44:32.141353
34219	1329	\N	\N	678	1	standalone	2026-06-21 05:44:32.141353
34221	1329	\N	\N	436	1	standalone	2026-06-21 05:44:32.141353
34222	1329	\N	\N	3295	1	standalone	2026-06-21 05:44:32.141353
34223	1329	\N	\N	3296	1	standalone	2026-06-21 05:44:32.141353
34224	1329	\N	\N	438	1	standalone	2026-06-21 05:44:32.141353
34226	1329	\N	\N	3300	1	standalone	2026-06-21 05:44:32.141353
34227	1329	\N	\N	3301	1	standalone	2026-06-21 05:44:32.141353
34228	1329	\N	\N	3302	1	standalone	2026-06-21 05:44:32.141353
34229	1329	\N	\N	3303	1	standalone	2026-06-21 05:44:32.141353
34230	1329	\N	\N	3304	1	standalone	2026-06-21 05:44:32.141353
34231	1329	\N	\N	461	1	standalone	2026-06-21 05:44:32.141353
34232	1329	\N	\N	470	1	standalone	2026-06-21 05:44:32.141353
34233	1329	\N	\N	1530	1	standalone	2026-06-21 05:44:32.141353
34235	1329	\N	\N	884	1	standalone	2026-06-21 05:44:32.141353
34236	1329	\N	\N	885	1	standalone	2026-06-21 05:44:32.141353
34239	1329	\N	\N	888	1	standalone	2026-06-21 05:44:32.141353
34240	1329	\N	\N	896	1	standalone	2026-06-21 05:44:32.141353
34241	1329	\N	\N	897	1	standalone	2026-06-21 05:44:32.141353
34242	1329	\N	\N	7009	1	standalone	2026-06-21 05:44:32.141353
34243	1329	\N	\N	7010	1	standalone	2026-06-21 05:44:32.141353
34245	1322	\N	\N	351	1	domain	2026-06-21 05:44:32.159156
34246	1322	\N	\N	3354	1	domain	2026-06-21 05:44:32.159156
34247	1322	\N	\N	2893	1	domain	2026-06-21 05:44:32.159156
34248	1322	\N	\N	503	1	domain	2026-06-21 05:44:32.159156
34249	1322	\N	\N	504	1	domain	2026-06-21 05:44:32.159156
34250	1322	\N	\N	507	1	domain	2026-06-21 05:44:32.159156
34251	1331	\N	\N	912	1	standalone	2026-06-21 05:44:32.173215
34252	1331	\N	\N	914	1	standalone	2026-06-21 05:44:32.173215
34253	1331	\N	\N	916	1	standalone	2026-06-21 05:44:32.173215
34254	1331	\N	\N	917	1	standalone	2026-06-21 05:44:32.173215
34255	1331	\N	\N	592	1	standalone	2026-06-21 05:44:32.173215
34257	1331	\N	\N	918	1	standalone	2026-06-21 05:44:32.173215
34258	1331	\N	\N	910	1	standalone	2026-06-21 05:44:32.173215
34259	1331	\N	\N	911	1	standalone	2026-06-21 05:44:32.173215
34260	1331	\N	\N	904	1	standalone	2026-06-21 05:44:32.173215
34261	1331	\N	\N	905	1	standalone	2026-06-21 05:44:32.173215
34262	1331	\N	\N	906	1	standalone	2026-06-21 05:44:32.173215
34264	1331	\N	\N	908	1	standalone	2026-06-21 05:44:32.173215
34267	1331	\N	\N	602	1	domain	2026-06-21 05:44:32.191088
34268	1331	\N	\N	922	1	domain	2026-06-21 05:44:32.191088
34269	1331	\N	\N	923	1	standalone	2026-06-21 05:44:32.191088
34270	1331	\N	\N	924	1	standalone	2026-06-21 05:44:32.191088
34272	1331	\N	\N	927	1	standalone	2026-06-21 05:44:32.191088
34273	1331	\N	\N	929	1	standalone	2026-06-21 05:44:32.191088
34274	1331	\N	\N	972	1	standalone	2026-06-21 05:44:32.191088
34275	1331	\N	\N	932	1	standalone	2026-06-21 05:44:32.191088
34279	1331	\N	\N	2870	1	standalone	2026-06-21 05:44:32.191088
34280	1331	\N	\N	712	1	standalone	2026-06-21 05:44:32.191088
34281	1331	\N	\N	3278	1	standalone	2026-06-21 05:44:32.191088
34283	1331	\N	\N	937	1	standalone	2026-06-21 05:44:32.191088
34284	1331	\N	\N	938	1	standalone	2026-06-21 05:44:32.191088
34285	1331	\N	\N	939	1	standalone	2026-06-21 05:44:32.191088
34286	1331	\N	\N	940	1	standalone	2026-06-21 05:44:32.191088
34287	1331	\N	\N	941	1	standalone	2026-06-21 05:44:32.191088
34289	1331	\N	\N	3144	1	standalone	2026-06-21 05:44:32.191088
34290	1331	\N	\N	3145	1	standalone	2026-06-21 05:44:32.191088
34291	1331	\N	\N	3151	1	standalone	2026-06-21 05:44:32.191088
34292	1331	\N	\N	3055	1	standalone	2026-06-21 05:44:32.191088
34294	1331	\N	\N	1646	1	standalone	2026-06-21 05:44:32.191088
34295	1331	\N	\N	3244	1	standalone	2026-06-21 05:44:32.191088
34297	1331	\N	\N	3246	1	standalone	2026-06-21 05:44:32.191088
34298	1331	\N	\N	2141	1	standalone	2026-06-21 05:44:32.191088
34299	1331	\N	\N	2151	1	standalone	2026-06-21 05:44:32.191088
34300	1331	\N	\N	2144	1	standalone	2026-06-21 05:44:32.191088
34301	1331	\N	\N	2145	1	standalone	2026-06-21 05:44:32.191088
34302	1331	\N	\N	2146	1	standalone	2026-06-21 05:44:32.191088
34303	1331	\N	\N	2152	1	standalone	2026-06-21 05:44:32.191088
34209	1329	\N	\N	653	1	domain	2026-06-21 05:44:32.141353
34225	1329	\N	\N	3299	1	domain	2026-06-21 05:44:32.141353
34309	1331	\N	\N	2763	1	standalone	2026-06-21 05:44:32.191088
34310	1331	\N	\N	2767	1	standalone	2026-06-21 05:44:32.191088
34313	1331	\N	\N	2220	1	standalone	2026-06-21 05:44:32.191088
34314	1331	\N	\N	2221	1	standalone	2026-06-21 05:44:32.191088
34315	1331	\N	\N	3045	1	standalone	2026-06-21 05:44:32.191088
34316	1331	\N	\N	3057	1	standalone	2026-06-21 05:44:32.191088
34317	1331	\N	\N	3067	1	standalone	2026-06-21 05:44:32.191088
34318	1331	\N	\N	3070	1	standalone	2026-06-21 05:44:32.191088
34319	1331	\N	\N	3072	1	standalone	2026-06-21 05:44:32.191088
34320	1331	\N	\N	3100	1	standalone	2026-06-21 05:44:32.191088
34321	1331	\N	\N	2316	1	standalone	2026-06-21 05:44:32.191088
34322	1331	\N	\N	2434	1	standalone	2026-06-21 05:44:32.191088
34323	1331	\N	\N	2493	1	standalone	2026-06-21 05:44:32.191088
34324	1331	\N	\N	2504	1	standalone	2026-06-21 05:44:32.191088
34325	1331	\N	\N	2574	1	standalone	2026-06-21 05:44:32.191088
34326	1331	\N	\N	2578	1	standalone	2026-06-21 05:44:32.191088
34328	1331	\N	\N	1550	1	domain	2026-06-21 05:44:32.221861
34330	1331	\N	\N	604	1	domain	2026-06-21 05:44:32.221861
34332	1331	\N	\N	704	1	domain	2026-06-21 05:44:32.221861
34333	1331	\N	\N	3338	1	domain	2026-06-21 05:44:32.221861
34334	1331	\N	\N	3283	1	domain	2026-06-21 05:44:32.221861
34336	1332	\N	\N	2987	1	domain	2026-06-21 05:44:32.238548
34337	1332	\N	\N	3116	1	domain	2026-06-21 05:44:32.238548
34338	1332	\N	\N	622	1	domain	2026-06-21 05:44:32.238548
34339	1332	\N	\N	1587	1	domain	2026-06-21 05:44:32.238548
34342	1325	\N	\N	2	1	domain	2026-06-21 05:44:32.246697
34343	1325	\N	\N	775	1	domain	2026-06-21 05:44:32.246697
34344	1325	\N	\N	981	1	domain	2026-06-21 05:44:32.246697
34345	1325	\N	\N	1124	1	domain	2026-06-21 05:44:32.246697
34346	1325	\N	\N	2680	1	domain	2026-06-21 05:44:32.246697
34347	1325	\N	\N	3189	1	standalone	2026-06-21 05:44:32.246697
34349	1325	\N	\N	1691	1	domain	2026-06-21 05:44:32.254747
34350	1325	\N	\N	2048	1	domain	2026-06-21 05:44:32.254747
34351	1325	\N	\N	2273	1	domain	2026-06-21 05:44:32.254747
34352	1325	\N	\N	2523	1	standalone	2026-06-21 05:44:32.254747
34353	1325	\N	\N	2573	1	standalone	2026-06-21 05:44:32.254747
34355	1333	\N	\N	198	1	domain	2026-06-21 05:44:32.259261
34356	1333	\N	\N	1577	1	domain	2026-06-21 05:44:32.259261
34357	1333	\N	\N	171	1	domain	2026-06-21 05:44:32.259261
34358	1333	\N	\N	952	1	domain	2026-06-21 05:44:32.259261
34359	1333	\N	\N	2583	1	domain	2026-06-21 05:44:32.259261
34360	1333	\N	\N	810	1	domain	2026-06-21 05:44:32.259261
34361	1333	\N	\N	2918	1	domain	2026-06-21 05:44:32.259261
34362	1333	\N	\N	1540	1	domain	2026-06-21 05:44:32.259261
34363	1333	\N	\N	200	1	standalone	2026-06-21 05:44:32.259261
34364	1333	\N	\N	202	1	standalone	2026-06-21 05:44:32.259261
34365	1333	\N	\N	1862	1	standalone	2026-06-21 05:44:32.259261
34366	1333	\N	\N	1863	1	standalone	2026-06-21 05:44:32.259261
34368	1333	\N	\N	203	1	domain	2026-06-21 05:44:32.270428
34369	1333	\N	\N	1813	1	domain	2026-06-21 05:44:32.270428
34371	1333	\N	\N	206	1	standalone	2026-06-21 05:44:32.270428
34372	1333	\N	\N	236	1	standalone	2026-06-21 05:44:32.270428
34374	1333	\N	\N	3185	1	domain	2026-06-21 05:44:32.278878
34375	1333	\N	\N	1118	1	domain	2026-06-21 05:44:32.278878
34376	1333	\N	\N	25	1	standalone	2026-06-21 05:44:32.278878
34378	1333	\N	\N	1812	1	domain	2026-06-21 05:44:32.287375
34379	1333	\N	\N	72	1	domain	2026-06-21 05:44:32.287375
34380	1333	\N	\N	1929	1	standalone	2026-06-21 05:44:32.287375
34381	1333	\N	\N	316	1	standalone	2026-06-21 05:44:32.287375
34382	1333	\N	\N	2959	1	standalone	2026-06-21 05:44:32.287375
34383	1333	\N	\N	1993	1	standalone	2026-06-21 05:44:32.287375
34384	1333	\N	\N	2225	1	standalone	2026-06-21 05:44:32.287375
34385	1333	\N	\N	2228	1	standalone	2026-06-21 05:44:32.287375
34386	1333	\N	\N	1285	1	standalone	2026-06-21 05:44:32.287375
34387	1333	\N	\N	2042	1	standalone	2026-06-21 05:44:32.287375
34388	1333	\N	\N	2300	1	standalone	2026-06-21 05:44:32.287375
34389	1333	\N	\N	2340	1	standalone	2026-06-21 05:44:32.287375
34391	1333	\N	\N	201	1	domain	2026-06-21 05:44:32.29521
34392	1333	\N	\N	15	1	domain	2026-06-21 05:44:32.29521
34393	1333	\N	\N	1636	1	domain	2026-06-21 05:44:32.29521
34394	1333	\N	\N	2128	1	domain	2026-06-21 05:44:32.29521
34395	1333	\N	\N	2129	1	domain	2026-06-21 05:44:32.29521
34397	1322	\N	\N	945	1	domain	2026-06-21 05:44:32.304182
34398	1322	\N	\N	2580	1	domain	2026-06-21 05:44:32.304182
34399	1322	\N	\N	791	1	domain	2026-06-21 05:44:32.304182
34400	1322	\N	\N	2740	1	domain	2026-06-21 05:44:32.304182
34401	1322	\N	\N	2033	1	domain	2026-06-21 05:44:32.304182
34403	1322	\N	\N	686	1	domain	2026-06-21 05:44:32.312033
34404	1322	\N	\N	774	1	domain	2026-06-21 05:44:32.312033
34405	1322	\N	\N	2034	1	domain	2026-06-21 05:44:32.312033
34406	1322	\N	\N	1819	1	standalone	2026-06-21 05:44:32.312033
34408	1334	\N	\N	3181	1	domain	2026-06-21 05:44:32.329275
34409	1334	\N	\N	797	1	domain	2026-06-21 05:44:32.329275
34411	1334	\N	\N	3184	1	domain	2026-06-21 05:44:32.338592
34412	1334	\N	\N	833	1	domain	2026-06-21 05:44:32.338592
34413	1334	\N	\N	127	1	domain	2026-06-21 05:44:32.338592
34418	1334	\N	\N	3118	1	domain	2026-06-21 05:44:32.338592
34419	1334	\N	\N	2869	1	domain	2026-06-21 05:44:32.338592
34420	1334	\N	\N	1121	1	domain	2026-06-21 05:44:32.338592
34421	1334	\N	\N	3281	1	domain	2026-06-21 05:44:32.338592
34422	1334	\N	\N	2120	1	domain	2026-06-21 05:44:32.338592
34308	1331	\N	\N	880	1	domain	2026-06-21 05:44:32.191088
34311	1331	\N	\N	160	1	domain	2026-06-21 05:44:32.191088
34312	1331	\N	\N	161	1	domain	2026-06-21 05:44:32.191088
34423	1334	\N	\N	1738	1	domain	2026-06-21 05:44:32.338592
34425	1334	\N	\N	125	1	domain	2026-06-21 05:44:32.353611
34426	1334	\N	\N	1538	1	domain	2026-06-21 05:44:32.353611
34428	1334	\N	\N	2809	1	domain	2026-06-21 05:44:32.368217
34429	1334	\N	\N	2121	1	domain	2026-06-21 05:44:32.368217
34430	1334	\N	\N	2122	1	domain	2026-06-21 05:44:32.368217
34432	1334	\N	\N	2123	1	domain	2026-06-21 05:44:32.376609
34433	1334	\N	\N	2835	1	domain	2026-06-21 05:44:32.376609
34434	1334	\N	\N	1222	1	standalone	2026-06-21 05:44:32.376609
34435	1334	\N	\N	834	1	standalone	2026-06-21 05:44:32.376609
34437	1334	\N	\N	625	1	domain	2026-06-21 05:44:32.384845
34438	1334	\N	\N	626	1	domain	2026-06-21 05:44:32.384845
34439	1334	\N	\N	627	1	domain	2026-06-21 05:44:32.384845
34440	1334	\N	\N	630	1	domain	2026-06-21 05:44:32.384845
34441	1334	\N	\N	1589	1	domain	2026-06-21 05:44:32.384845
34446	1334	\N	\N	2779	1	domain	2026-06-21 05:44:32.39342
34447	1334	\N	\N	1695	1	domain	2026-06-21 05:44:32.39342
34448	1334	\N	\N	143	1	standalone	2026-06-21 05:44:32.39342
34450	1334	\N	\N	170	1	domain	2026-06-21 05:44:32.39342
34451	1334	\N	\N	3117	1	domain	2026-06-21 05:44:32.39342
34456	1334	\N	\N	2810	1	domain	2026-06-21 05:44:32.409573
34457	1334	\N	\N	3359	1	domain	2026-06-21 05:44:32.409573
34458	1334	\N	\N	126	1	domain	2026-06-21 05:44:32.409573
34460	1322	\N	\N	1067	1	domain	2026-06-21 05:44:32.453087
34461	1322	\N	\N	2637	1	domain	2026-06-21 05:44:32.453087
34462	1322	\N	\N	943	1	domain	2026-06-21 05:44:32.453087
34463	1322	\N	\N	476	1	domain	2026-06-21 05:44:32.453087
34464	1322	\N	\N	1367	1	domain	2026-06-21 05:44:32.453087
34466	1322	\N	\N	1854	1	domain	2026-06-21 05:44:32.458243
34467	1322	\N	\N	608	1	domain	2026-06-21 05:44:32.458243
34469	1322	\N	\N	197	1	domain	2026-06-21 05:44:32.458243
34470	1322	\N	\N	2183	1	domain	2026-06-21 05:44:32.458243
34471	1322	\N	\N	2638	1	standalone	2026-06-21 05:44:32.458243
34472	1322	\N	\N	2639	1	standalone	2026-06-21 05:44:32.458243
34474	1322	\N	\N	970	1	domain	2026-06-21 05:44:32.466392
34475	1322	\N	\N	1301	1	domain	2026-06-21 05:44:32.466392
34477	1322	\N	\N	251	1	domain	2026-06-21 05:44:32.474886
34478	1322	\N	\N	1314	1	domain	2026-06-21 05:44:32.474886
34479	1322	\N	\N	1188	1	standalone	2026-06-21 05:44:32.474886
34480	1322	\N	\N	1189	1	standalone	2026-06-21 05:44:32.474886
34481	1322	\N	\N	1190	1	standalone	2026-06-21 05:44:32.474886
34482	1322	\N	\N	2966	1	standalone	2026-06-21 05:44:32.474886
34483	1322	\N	\N	2412	1	standalone	2026-06-21 05:44:32.474886
34484	1322	\N	\N	2509	1	standalone	2026-06-21 05:44:32.474886
34485	1322	\N	\N	2526	1	standalone	2026-06-21 05:44:32.474886
34486	1322	\N	\N	2490	1	standalone	2026-06-21 05:44:32.474886
34487	1322	\N	\N	2530	1	standalone	2026-06-21 05:44:32.474886
34492	1322	\N	\N	682	1	domain	2026-06-21 05:44:32.491539
34493	1322	\N	\N	1546	1	domain	2026-06-21 05:44:32.491539
34495	1322	\N	\N	925	1	domain	2026-06-21 05:44:32.491539
34496	1322	\N	\N	2735	1	domain	2026-06-21 05:44:32.491539
34497	1322	\N	\N	1703	1	domain	2026-06-21 05:44:32.491539
34498	1322	\N	\N	3355	1	domain	2026-06-21 05:44:32.491539
34499	1322	\N	\N	3171	1	domain	2026-06-21 05:44:32.491539
34500	1322	\N	\N	3110	1	domain	2026-06-21 05:44:32.491539
34501	1322	\N	\N	3391	1	domain	2026-06-21 05:44:32.491539
34503	1322	\N	\N	3114	1	domain	2026-06-21 05:44:32.504628
34504	1322	\N	\N	3115	1	domain	2026-06-21 05:44:32.504628
34505	1322	\N	\N	1151	1	domain	2026-06-21 05:44:32.504628
34506	1322	\N	\N	2094	1	domain	2026-06-21 05:44:32.504628
34507	1322	\N	\N	2910	1	domain	2026-06-21 05:44:32.504628
34508	1322	\N	\N	2911	1	domain	2026-06-21 05:44:32.504628
34509	1322	\N	\N	2912	1	domain	2026-06-21 05:44:32.504628
34510	1322	\N	\N	2914	1	domain	2026-06-21 05:44:32.504628
34511	1322	\N	\N	2131	1	domain	2026-06-21 05:44:32.504628
34512	1322	\N	\N	2132	1	domain	2026-06-21 05:44:32.504628
34513	1322	\N	\N	2469	1	domain	2026-06-21 05:44:32.504628
34518	1322	\N	\N	3119	1	domain	2026-06-21 05:44:32.524103
34519	1322	\N	\N	7016	1	domain	2026-06-21 05:44:32.524103
34521	1322	\N	\N	2482	1	domain	2026-06-21 05:44:32.524103
34523	1322	\N	\N	2305	1	standalone	2026-06-21 05:44:32.524103
34524	1322	\N	\N	2356	1	standalone	2026-06-21 05:44:32.524103
34526	1322	\N	\N	2401	1	standalone	2026-06-21 05:44:32.524103
34527	1322	\N	\N	2036	1	standalone	2026-06-21 05:44:32.524103
34528	1322	\N	\N	2037	1	standalone	2026-06-21 05:44:32.524103
34532	1322	\N	\N	449	1	standalone	2026-06-21 05:44:32.541462
34533	1322	\N	\N	2405	1	standalone	2026-06-21 05:44:32.541462
34535	1322	\N	\N	1568	1	domain	2026-06-21 05:44:32.55625
34536	1322	\N	\N	629	1	domain	2026-06-21 05:44:32.55625
34537	1322	\N	\N	2118	1	domain	2026-06-21 05:44:32.55625
34538	1322	\N	\N	2130	1	domain	2026-06-21 05:44:32.55625
34539	1322	\N	\N	1690	1	domain	2026-06-21 05:44:32.55625
34525	1322	\N	\N	2365	1	domain	2026-06-21 05:44:32.524103
34540	1322	\N	\N	3053	1	domain	2026-06-21 05:44:32.55625
34541	1322	\N	\N	3082	1	domain	2026-06-21 05:44:32.55625
34542	1322	\N	\N	2403	1	domain	2026-06-21 05:44:32.55625
34543	1322	\N	\N	2551	1	domain	2026-06-21 05:44:32.55625
34544	1322	\N	\N	3250	1	standalone	2026-06-21 05:44:32.55625
34545	1322	\N	\N	2064	1	standalone	2026-06-21 05:44:32.55625
34546	1322	\N	\N	2851	1	standalone	2026-06-21 05:44:32.55625
34547	1322	\N	\N	2065	1	standalone	2026-06-21 05:44:32.55625
34548	1322	\N	\N	2852	1	standalone	2026-06-21 05:44:32.55625
34549	1322	\N	\N	2066	1	standalone	2026-06-21 05:44:32.55625
34550	1322	\N	\N	2853	1	standalone	2026-06-21 05:44:32.55625
34551	1322	\N	\N	2067	1	standalone	2026-06-21 05:44:32.55625
34552	1322	\N	\N	2068	1	standalone	2026-06-21 05:44:32.55625
34553	1322	\N	\N	2856	1	standalone	2026-06-21 05:44:32.55625
34555	1322	\N	\N	1562	1	standalone	2026-06-21 05:44:32.55625
34556	1322	\N	\N	2077	1	standalone	2026-06-21 05:44:32.55625
34557	1322	\N	\N	2083	1	standalone	2026-06-21 05:44:32.55625
34558	1322	\N	\N	2872	1	standalone	2026-06-21 05:44:32.55625
34559	1322	\N	\N	2873	1	standalone	2026-06-21 05:44:32.55625
34560	1322	\N	\N	2874	1	standalone	2026-06-21 05:44:32.55625
34561	1322	\N	\N	2875	1	standalone	2026-06-21 05:44:32.55625
34562	1322	\N	\N	2877	1	standalone	2026-06-21 05:44:32.55625
34565	1322	\N	\N	2656	1	standalone	2026-06-21 05:44:32.55625
34567	1322	\N	\N	2658	1	standalone	2026-06-21 05:44:32.55625
34568	1322	\N	\N	1114	1	standalone	2026-06-21 05:44:32.55625
34569	1322	\N	\N	2659	1	standalone	2026-06-21 05:44:32.55625
34570	1322	\N	\N	2892	1	standalone	2026-06-21 05:44:32.55625
34571	1322	\N	\N	2109	1	standalone	2026-06-21 05:44:32.55625
34572	1322	\N	\N	2158	1	standalone	2026-06-21 05:44:32.55625
34574	1322	\N	\N	2538	1	standalone	2026-06-21 05:44:32.55625
34577	1327	\N	\N	3122	1	standalone	2026-06-21 05:44:32.55625
34581	1327	\N	\N	454	1	standalone	2026-06-21 05:44:32.55625
34583	1327	\N	\N	547	1	standalone	2026-06-21 05:44:32.55625
34584	1327	\N	\N	2561	1	standalone	2026-06-21 05:44:32.55625
34586	1329	\N	\N	1834	1	domain	2026-06-21 05:44:32.572038
34587	1329	\N	\N	1014	1	domain	2026-06-21 05:44:32.572038
34588	1329	\N	\N	3240	1	domain	2026-06-21 05:44:32.572038
34589	1329	\N	\N	2093	1	domain	2026-06-21 05:44:32.572038
34591	1329	\N	\N	3272	1	domain	2026-06-21 05:44:32.588116
34592	1329	\N	\N	1895	1	domain	2026-06-21 05:44:32.588116
34593	1329	\N	\N	2358	1	domain	2026-06-21 05:44:32.588116
34594	1329	\N	\N	205	1	standalone	2026-06-21 05:44:32.588116
34595	1329	\N	\N	101	1	standalone	2026-06-21 05:44:32.588116
34597	1329	\N	\N	642	1	domain	2026-06-21 05:44:32.605341
34599	1329	\N	\N	3297	1	domain	2026-06-21 05:44:32.605341
34601	1329	\N	\N	891	1	domain	2026-06-21 05:44:32.605341
34602	1329	\N	\N	892	1	domain	2026-06-21 05:44:32.605341
34603	1331	\N	\N	913	1	standalone	2026-06-21 05:44:32.605341
34605	1331	\N	\N	921	1	standalone	2026-06-21 05:44:32.605341
34608	1331	\N	\N	2805	1	standalone	2026-06-21 05:44:32.605341
34609	1331	\N	\N	2806	1	standalone	2026-06-21 05:44:32.605341
34610	1331	\N	\N	705	1	standalone	2026-06-21 05:44:32.605341
34611	1331	\N	\N	707	1	standalone	2026-06-21 05:44:32.605341
34612	1331	\N	\N	930	1	standalone	2026-06-21 05:44:32.605341
34613	1331	\N	\N	2607	1	standalone	2026-06-21 05:44:32.605341
34615	1331	\N	\N	2150	1	standalone	2026-06-21 05:44:32.605341
34616	1331	\N	\N	1639	1	standalone	2026-06-21 05:44:32.605341
34617	1331	\N	\N	1643	1	standalone	2026-06-21 05:44:32.605341
34620	1331	\N	\N	3247	1	standalone	2026-06-21 05:44:32.605341
34621	1331	\N	\N	2142	1	standalone	2026-06-21 05:44:32.605341
34624	1331	\N	\N	2214	1	standalone	2026-06-21 05:44:32.605341
34625	1331	\N	\N	3038	1	standalone	2026-06-21 05:44:32.605341
34627	1331	\N	\N	3044	1	standalone	2026-06-21 05:44:32.605341
34628	1331	\N	\N	3052	1	standalone	2026-06-21 05:44:32.605341
34629	1331	\N	\N	3056	1	standalone	2026-06-21 05:44:32.605341
34630	1331	\N	\N	3065	1	standalone	2026-06-21 05:44:32.605341
34631	1331	\N	\N	3066	1	standalone	2026-06-21 05:44:32.605341
34632	1331	\N	\N	3068	1	standalone	2026-06-21 05:44:32.605341
34634	1331	\N	\N	3071	1	standalone	2026-06-21 05:44:32.605341
34636	1324	\N	\N	166	1	domain	2026-06-21 05:44:32.621305
34638	1324	\N	\N	695	1	domain	2026-06-21 05:44:32.621305
34639	1324	\N	\N	609	1	domain	2026-06-21 05:44:32.621305
34640	1324	\N	\N	2935	1	domain	2026-06-21 05:44:32.621305
34641	1324	\N	\N	2045	1	domain	2026-06-21 05:44:32.621305
34643	1324	\N	\N	2581	1	domain	2026-06-21 05:44:32.652311
34644	1324	\N	\N	3192	1	domain	2026-06-21 05:44:32.652311
34645	1324	\N	\N	1556	1	domain	2026-06-21 05:44:32.652311
34646	1324	\N	\N	1830	1	domain	2026-06-21 05:44:32.652311
34647	1324	\N	\N	1125	1	domain	2026-06-21 05:44:32.652311
34648	1324	\N	\N	3357	1	domain	2026-06-21 05:44:32.652311
34649	1324	\N	\N	2678	1	domain	2026-06-21 05:44:32.652311
34650	1324	\N	\N	2729	1	domain	2026-06-21 05:44:32.652311
34579	1327	\N	\N	724	1	domain	2026-06-21 05:44:32.55625
34554	1322	\N	\N	2070	1	domain	2026-06-21 05:44:32.55625
34564	1322	\N	\N	1108	1	domain	2026-06-21 05:44:32.55625
34566	1322	\N	\N	1113	1	domain	2026-06-21 05:44:32.55625
34652	1324	\N	\N	1609	1	domain	2026-06-21 05:44:32.667451
34653	1324	\N	\N	1557	1	domain	2026-06-21 05:44:32.667451
34654	1324	\N	\N	1831	1	domain	2026-06-21 05:44:32.667451
34655	1324	\N	\N	315	1	domain	2026-06-21 05:44:32.667451
34657	1324	\N	\N	7	1	domain	2026-06-21 05:44:32.687403
34658	1324	\N	\N	696	1	domain	2026-06-21 05:44:32.687403
34659	1324	\N	\N	2095	1	domain	2026-06-21 05:44:32.687403
34660	1324	\N	\N	2096	1	domain	2026-06-21 05:44:32.687403
34663	1324	\N	\N	1610	1	domain	2026-06-21 05:44:32.706746
34664	1324	\N	\N	2101	1	domain	2026-06-21 05:44:32.706746
34665	1324	\N	\N	452	1	domain	2026-06-21 05:44:32.706746
34667	1324	\N	\N	429	1	standalone	2026-06-21 05:44:32.706746
34668	1324	\N	\N	430	1	standalone	2026-06-21 05:44:32.706746
34669	1324	\N	\N	432	1	standalone	2026-06-21 05:44:32.706746
34670	1324	\N	\N	451	1	standalone	2026-06-21 05:44:32.706746
34671	1324	\N	\N	453	1	standalone	2026-06-21 05:44:32.706746
34672	1324	\N	\N	109	1	standalone	2026-06-21 05:44:32.706746
34673	1324	\N	\N	308	1	standalone	2026-06-21 05:44:32.706746
34674	1324	\N	\N	310	1	standalone	2026-06-21 05:44:32.706746
34675	1324	\N	\N	311	1	standalone	2026-06-21 05:44:32.706746
34676	1324	\N	\N	312	1	standalone	2026-06-21 05:44:32.706746
34677	1324	\N	\N	314	1	standalone	2026-06-21 05:44:32.706746
34678	1324	\N	\N	309	1	standalone	2026-06-21 05:44:32.706746
34680	1324	\N	\N	1655	1	domain	2026-06-21 05:44:32.72199
34681	1324	\N	\N	2059	1	domain	2026-06-21 05:44:32.72199
34683	1324	\N	\N	3155	1	domain	2026-06-21 05:44:32.728285
34684	1324	\N	\N	1336	1	domain	2026-06-21 05:44:32.728285
34685	1324	\N	\N	1337	1	domain	2026-06-21 05:44:32.728285
34686	1324	\N	\N	2417	1	domain	2026-06-21 05:44:32.728285
34687	1324	\N	\N	2539	1	domain	2026-06-21 05:44:32.728285
34688	1324	\N	\N	2291	1	standalone	2026-06-21 05:44:32.728285
34689	1324	\N	\N	2297	1	standalone	2026-06-21 05:44:32.728285
34690	1324	\N	\N	2382	1	standalone	2026-06-21 05:44:32.728285
34691	1324	\N	\N	6	1	standalone	2026-06-21 05:44:32.728285
34692	1324	\N	\N	2887	1	standalone	2026-06-21 05:44:32.728285
34693	1324	\N	\N	2274	1	standalone	2026-06-21 05:44:32.728285
34695	1324	\N	\N	5	1	domain	2026-06-21 05:44:32.746953
34696	1324	\N	\N	1608	1	domain	2026-06-21 05:44:32.746953
34697	1324	\N	\N	3389	1	domain	2026-06-21 05:44:32.746953
34698	1324	\N	\N	778	1	domain	2026-06-21 05:44:32.746953
34699	1324	\N	\N	3138	1	domain	2026-06-21 05:44:32.746953
34700	1324	\N	\N	983	1	domain	2026-06-21 05:44:32.746953
34701	1324	\N	\N	431	1	domain	2026-06-21 05:44:32.746953
34704	1324	\N	\N	2099	1	domain	2026-06-21 05:44:32.746953
34705	1324	\N	\N	2100	1	domain	2026-06-21 05:44:32.746953
34707	1324	\N	\N	54	1	domain	2026-06-21 05:44:32.746953
34708	1324	\N	\N	2898	1	domain	2026-06-21 05:44:32.746953
34709	1324	\N	\N	746	1	domain	2026-06-21 05:44:32.746953
34710	1324	\N	\N	1539	1	domain	2026-06-21 05:44:32.746953
34715	1324	\N	\N	2745	1	domain	2026-06-21 05:44:32.746953
34716	1324	\N	\N	2766	1	domain	2026-06-21 05:44:32.746953
34718	1324	\N	\N	2047	1	domain	2026-06-21 05:44:32.746953
34720	1327	\N	\N	2587	1	domain	2026-06-21 05:44:32.760826
34721	1327	\N	\N	175	1	domain	2026-06-21 05:44:32.760826
34722	1327	\N	\N	1961	1	domain	2026-06-21 05:44:32.760826
34723	1327	\N	\N	1972	1	domain	2026-06-21 05:44:32.760826
34724	1327	\N	\N	1973	1	domain	2026-06-21 05:44:32.760826
34725	1327	\N	\N	1974	1	domain	2026-06-21 05:44:32.760826
34727	1327	\N	\N	757	1	standalone	2026-06-21 05:44:32.760826
34729	1327	\N	\N	765	1	domain	2026-06-21 05:44:32.779055
34730	1327	\N	\N	78	1	domain	2026-06-21 05:44:32.779055
34731	1327	\N	\N	568	1	domain	2026-06-21 05:44:32.779055
34732	1327	\N	\N	3394	1	standalone	2026-06-21 05:44:32.779055
34733	1327	\N	\N	233	1	standalone	2026-06-21 05:44:32.779055
34734	1327	\N	\N	77	1	standalone	2026-06-21 05:44:32.779055
34735	1327	\N	\N	1960	1	standalone	2026-06-21 05:44:32.779055
34736	1327	\N	\N	1963	1	standalone	2026-06-21 05:44:32.779055
34737	1327	\N	\N	1964	1	standalone	2026-06-21 05:44:32.779055
34738	1327	\N	\N	1970	1	standalone	2026-06-21 05:44:32.779055
34739	1327	\N	\N	1971	1	standalone	2026-06-21 05:44:32.779055
34740	1327	\N	\N	2323	1	standalone	2026-06-21 05:44:32.779055
34741	1327	\N	\N	428	1	standalone	2026-06-21 05:44:32.779055
34743	1322	\N	\N	2842	1	domain	2026-06-21 05:44:32.790749
34744	1322	\N	\N	2845	1	domain	2026-06-21 05:44:32.790749
34745	1322	\N	\N	356	1	domain	2026-06-21 05:44:32.790749
34746	1322	\N	\N	2846	1	domain	2026-06-21 05:44:32.790749
34747	1322	\N	\N	2862	1	domain	2026-06-21 05:44:32.790749
34750	1335	\N	\N	1163	1	domain	2026-06-21 05:44:32.800824
34751	1335	\N	\N	2749	1	domain	2026-06-21 05:44:32.800824
34752	1335	\N	\N	2409	1	domain	2026-06-21 05:44:32.800824
34753	1335	\N	\N	2446	1	domain	2026-06-21 05:44:32.800824
34755	1335	\N	\N	1164	1	domain	2026-06-21 05:44:32.804632
30489	1303	\N	\N	214	1	domain	2026-06-20 19:40:05.806753
30490	1303	\N	\N	3270	1	domain	2026-06-20 19:40:05.806753
34756	1335	\N	\N	1030	1	domain	2026-06-21 05:44:32.804632
34758	1335	\N	\N	1925	1	domain	2026-06-21 05:44:32.811257
34759	1335	\N	\N	1167	1	domain	2026-06-21 05:44:32.811257
34760	1335	\N	\N	331	1	domain	2026-06-21 05:44:32.811257
34762	1335	\N	\N	1170	1	standalone	2026-06-21 05:44:32.811257
34763	1335	\N	\N	1171	1	standalone	2026-06-21 05:44:32.811257
34764	1335	\N	\N	332	1	standalone	2026-06-21 05:44:32.811257
34761	1335	\N	\N	3343	1	domain	2026-06-21 05:44:32.811257
30491	1303	\N	\N	2813	1	domain	2026-06-20 19:40:05.806753
30492	1303	\N	\N	36	1	domain	2026-06-20 19:40:05.806753
30493	1303	\N	\N	37	1	domain	2026-06-20 19:40:05.806753
30494	1303	\N	\N	38	1	domain	2026-06-20 19:40:05.806753
30495	1303	\N	\N	719	1	domain	2026-06-20 19:40:05.806753
30496	1303	\N	\N	39	1	domain	2026-06-20 19:40:05.806753
34765	1335	\N	\N	1027	1	standalone	2026-06-21 05:44:32.811257
30497	1303	\N	\N	720	1	domain	2026-06-20 19:40:05.806753
34766	1336	\N	\N	1860	1	standalone	2026-06-21 05:44:32.820671
30498	1303	\N	\N	40	1	domain	2026-06-20 19:40:05.806753
30499	1303	\N	\N	41	1	domain	2026-06-20 19:40:05.806753
30500	1303	\N	\N	42	1	domain	2026-06-20 19:40:05.806753
30501	1303	\N	\N	3291	1	domain	2026-06-20 19:40:05.806753
34767	1336	\N	\N	1867	1	standalone	2026-06-21 05:44:32.820671
30502	1303	\N	\N	3298	1	domain	2026-06-20 19:40:05.806753
30503	1303	\N	\N	1002	1	domain	2026-06-20 19:40:05.806753
30504	1303	\N	\N	1012	1	domain	2026-06-20 19:40:05.806753
30505	1303	\N	\N	826	1	domain	2026-06-20 19:40:05.806753
30506	1303	\N	\N	1672	1	domain	2026-06-20 19:40:05.806753
34769	1336	\N	\N	1835	1	domain	2026-06-21 05:44:32.829587
34770	1336	\N	\N	1630	1	domain	2026-06-21 05:44:32.829587
34771	1336	\N	\N	84	1	domain	2026-06-21 05:44:32.829587
34773	1336	\N	\N	1866	1	standalone	2026-06-21 05:44:32.829587
34775	1336	\N	\N	1841	1	domain	2026-06-21 05:44:32.845197
34776	1336	\N	\N	1882	1	domain	2026-06-21 05:44:32.845197
34777	1336	\N	\N	1877	1	standalone	2026-06-21 05:44:32.845197
34778	1336	\N	\N	1878	1	standalone	2026-06-21 05:44:32.845197
34779	1336	\N	\N	1879	1	standalone	2026-06-21 05:44:32.845197
34780	1336	\N	\N	1883	1	standalone	2026-06-21 05:44:32.845197
34781	1336	\N	\N	1664	1	standalone	2026-06-21 05:44:32.845197
34782	1336	\N	\N	1884	1	standalone	2026-06-21 05:44:32.845197
34783	1336	\N	\N	1411	1	standalone	2026-06-21 05:44:32.845197
34785	1336	\N	\N	191	1	domain	2026-06-21 05:44:32.855475
34786	1336	\N	\N	1574	1	domain	2026-06-21 05:44:32.855475
34787	1336	\N	\N	224	1	standalone	2026-06-21 05:44:32.855475
34788	1336	\N	\N	225	1	standalone	2026-06-21 05:44:32.855475
34789	1336	\N	\N	379	1	standalone	2026-06-21 05:44:32.855475
34791	1336	\N	\N	3346	1	domain	2026-06-21 05:44:32.861559
34792	1336	\N	\N	1033	1	domain	2026-06-21 05:44:32.861559
34793	1336	\N	\N	232	1	standalone	2026-06-21 05:44:32.861559
34794	1336	\N	\N	1629	1	standalone	2026-06-21 05:44:32.861559
34795	1336	\N	\N	1634	1	standalone	2026-06-21 05:44:32.861559
34797	1336	\N	\N	1011	1	domain	2026-06-21 05:44:32.864891
34798	1336	\N	\N	1186	1	domain	2026-06-21 05:44:32.864891
34799	1336	\N	\N	1187	1	standalone	2026-06-21 05:44:32.864891
34801	1336	\N	\N	867	1	domain	2026-06-21 05:44:32.878253
34802	1336	\N	\N	138	1	domain	2026-06-21 05:44:32.878253
34803	1336	\N	\N	1275	1	standalone	2026-06-21 05:44:32.878253
34804	1336	\N	\N	1276	1	standalone	2026-06-21 05:44:32.878253
34805	1336	\N	\N	2362	1	standalone	2026-06-21 05:44:32.878253
34806	1336	\N	\N	2366	1	standalone	2026-06-21 05:44:32.878253
34807	1336	\N	\N	2370	1	standalone	2026-06-21 05:44:32.878253
34809	1336	\N	\N	3374	1	domain	2026-06-21 05:44:32.878253
34810	1336	\N	\N	3331	1	domain	2026-06-21 05:44:32.878253
34811	1336	\N	\N	2925	1	domain	2026-06-21 05:44:32.878253
34812	1336	\N	\N	2926	1	domain	2026-06-21 05:44:32.878253
34816	1329	\N	\N	210	1	standalone	2026-06-21 05:44:32.894078
34817	1329	\N	\N	664	1	standalone	2026-06-21 05:44:32.894078
34818	1329	\N	\N	1451	1	standalone	2026-06-21 05:44:32.894078
34819	1329	\N	\N	1350	1	standalone	2026-06-21 05:44:32.894078
34820	1329	\N	\N	1265	1	standalone	2026-06-21 05:44:32.894078
34821	1329	\N	\N	3003	1	standalone	2026-06-21 05:44:32.894078
34822	1329	\N	\N	2380	1	standalone	2026-06-21 05:44:32.894078
34823	1326	\N	\N	2624	1	standalone	2026-06-21 05:44:32.894078
34824	1326	\N	\N	2625	1	standalone	2026-06-21 05:44:32.894078
34825	1326	\N	\N	2616	1	standalone	2026-06-21 05:44:32.894078
34826	1326	\N	\N	2617	1	standalone	2026-06-21 05:44:32.894078
34827	1326	\N	\N	2618	1	standalone	2026-06-21 05:44:32.894078
34828	1326	\N	\N	2619	1	standalone	2026-06-21 05:44:32.894078
34829	1326	\N	\N	2621	1	standalone	2026-06-21 05:44:32.894078
34830	1326	\N	\N	597	1	standalone	2026-06-21 05:44:32.894078
34831	1326	\N	\N	2622	1	standalone	2026-06-21 05:44:32.894078
34832	1326	\N	\N	2623	1	standalone	2026-06-21 05:44:32.894078
34833	1326	\N	\N	3120	1	standalone	2026-06-21 05:44:32.894078
34834	1326	\N	\N	2941	1	standalone	2026-06-21 05:44:32.894078
34835	1326	\N	\N	851	1	standalone	2026-06-21 05:44:32.894078
34836	1326	\N	\N	852	1	standalone	2026-06-21 05:44:32.894078
34837	1326	\N	\N	2289	1	standalone	2026-06-21 05:44:32.894078
34838	1326	\N	\N	2532	1	standalone	2026-06-21 05:44:32.894078
34840	1327	\N	\N	750	1	domain	2026-06-21 05:44:32.913459
34841	1327	\N	\N	64	1	domain	2026-06-21 05:44:32.913459
34843	1327	\N	\N	946	1	domain	2026-06-21 05:44:32.928014
34844	1327	\N	\N	1596	1	domain	2026-06-21 05:44:32.928014
34845	1327	\N	\N	3200	1	domain	2026-06-21 05:44:32.928014
34846	1327	\N	\N	830	1	domain	2026-06-21 05:44:32.928014
34847	1327	\N	\N	88	1	domain	2026-06-21 05:44:32.928014
34848	1327	\N	\N	2245	1	domain	2026-06-21 05:44:32.928014
34849	1327	\N	\N	2250	1	domain	2026-06-21 05:44:32.928014
34851	1327	\N	\N	3328	1	domain	2026-06-21 05:44:32.93927
34852	1327	\N	\N	2166	1	domain	2026-06-21 05:44:32.93927
34853	1327	\N	\N	3351	1	standalone	2026-06-21 05:44:32.93927
34854	1327	\N	\N	3353	1	standalone	2026-06-21 05:44:32.93927
34855	1327	\N	\N	3352	1	standalone	2026-06-21 05:44:32.93927
30507	1303	\N	\N	2705	1	domain	2026-06-20 19:40:05.806753
30508	1303	\N	\N	2706	1	domain	2026-06-20 19:40:05.806753
34856	1327	\N	\N	3220	1	standalone	2026-06-21 05:44:32.93927
34857	1327	\N	\N	1937	1	standalone	2026-06-21 05:44:32.93927
34858	1327	\N	\N	89	1	standalone	2026-06-21 05:44:32.93927
34859	1327	\N	\N	1199	1	standalone	2026-06-21 05:44:32.93927
34772	1336	\N	\N	1836	1	domain	2026-06-21 05:44:32.829587
34861	1327	\N	\N	2074	1	domain	2026-06-21 05:44:32.950479
34862	1327	\N	\N	1881	1	domain	2026-06-21 05:44:32.950479
34864	1334	\N	\N	3182	1	domain	2026-06-21 05:44:32.958835
34865	1334	\N	\N	799	1	domain	2026-06-21 05:44:32.958835
34866	1322	\N	\N	1742	1	standalone	2026-06-21 05:44:32.958835
34868	1322	\N	\N	353	1	standalone	2026-06-21 05:44:32.958835
34871	1322	\N	\N	168	1	domain	2026-06-21 05:44:32.975306
34872	1322	\N	\N	2582	1	domain	2026-06-21 05:44:32.975306
34873	1322	\N	\N	590	1	standalone	2026-06-21 05:44:32.975306
34874	1322	\N	\N	591	1	standalone	2026-06-21 05:44:32.975306
34875	1322	\N	\N	1128	1	standalone	2026-06-21 05:44:32.975306
34877	1322	\N	\N	3113	1	standalone	2026-06-21 05:44:32.975306
34878	1322	\N	\N	3258	1	standalone	2026-06-21 05:44:32.975306
34879	1322	\N	\N	589	1	standalone	2026-06-21 05:44:32.975306
34880	1322	\N	\N	1555	1	standalone	2026-06-21 05:44:32.975306
34882	1322	\N	\N	2855	1	standalone	2026-06-21 05:44:32.975306
34883	1322	\N	\N	367	1	standalone	2026-06-21 05:44:32.975306
34885	1322	\N	\N	610	1	standalone	2026-06-21 05:44:32.975306
34886	1322	\N	\N	1763	1	standalone	2026-06-21 05:44:32.975306
34888	1322	\N	\N	3280	1	standalone	2026-06-21 05:44:32.975306
34889	1322	\N	\N	1815	1	standalone	2026-06-21 05:44:32.975306
34890	1322	\N	\N	2876	1	standalone	2026-06-21 05:44:32.975306
34892	1322	\N	\N	783	1	standalone	2026-06-21 05:44:32.975306
34893	1322	\N	\N	784	1	standalone	2026-06-21 05:44:32.975306
34895	1322	\N	\N	786	1	standalone	2026-06-21 05:44:32.975306
34896	1322	\N	\N	1127	1	standalone	2026-06-21 05:44:32.975306
34897	1322	\N	\N	1823	1	standalone	2026-06-21 05:44:32.975306
34898	1322	\N	\N	1793	1	standalone	2026-06-21 05:44:32.975306
34899	1322	\N	\N	1794	1	standalone	2026-06-21 05:44:32.975306
34900	1322	\N	\N	1799	1	standalone	2026-06-21 05:44:32.975306
34902	1322	\N	\N	2125	1	standalone	2026-06-21 05:44:32.975306
34903	1322	\N	\N	2126	1	standalone	2026-06-21 05:44:32.975306
34904	1322	\N	\N	2913	1	standalone	2026-06-21 05:44:32.975306
34905	1322	\N	\N	2135	1	standalone	2026-06-21 05:44:32.975306
34906	1322	\N	\N	2136	1	standalone	2026-06-21 05:44:32.975306
34907	1322	\N	\N	2139	1	standalone	2026-06-21 05:44:32.975306
34908	1322	\N	\N	1686	1	standalone	2026-06-21 05:44:32.975306
34909	1322	\N	\N	2949	1	standalone	2026-06-21 05:44:32.975306
34910	1322	\N	\N	2950	1	standalone	2026-06-21 05:44:32.975306
34911	1322	\N	\N	2752	1	standalone	2026-06-21 05:44:32.975306
34912	1322	\N	\N	2951	1	standalone	2026-06-21 05:44:32.975306
34913	1322	\N	\N	1705	1	standalone	2026-06-21 05:44:32.975306
34917	1322	\N	\N	2764	1	standalone	2026-06-21 05:44:32.975306
34918	1322	\N	\N	2404	1	standalone	2026-06-21 05:44:32.975306
34920	1322	\N	\N	169	1	domain	2026-06-21 05:44:32.991288
34921	1322	\N	\N	586	1	domain	2026-06-21 05:44:32.991288
34922	1322	\N	\N	1126	1	domain	2026-06-21 05:44:32.991288
34924	1329	\N	\N	1390	1	standalone	2026-06-21 05:44:32.991288
34925	1329	\N	\N	1392	1	standalone	2026-06-21 05:44:32.991288
34926	1329	\N	\N	1393	1	standalone	2026-06-21 05:44:32.991288
34927	1329	\N	\N	1394	1	standalone	2026-06-21 05:44:32.991288
34928	1329	\N	\N	1395	1	standalone	2026-06-21 05:44:32.991288
34929	1329	\N	\N	1396	1	standalone	2026-06-21 05:44:32.991288
34930	1329	\N	\N	1397	1	standalone	2026-06-21 05:44:32.991288
34931	1329	\N	\N	1398	1	standalone	2026-06-21 05:44:32.991288
34932	1329	\N	\N	1399	1	standalone	2026-06-21 05:44:32.991288
34933	1329	\N	\N	1400	1	standalone	2026-06-21 05:44:32.991288
34934	1329	\N	\N	1401	1	standalone	2026-06-21 05:44:32.991288
34935	1329	\N	\N	498	1	standalone	2026-06-21 05:44:32.991288
34936	1329	\N	\N	499	1	standalone	2026-06-21 05:44:32.991288
34937	1329	\N	\N	1391	1	standalone	2026-06-21 05:44:32.991288
34938	1329	\N	\N	1402	1	standalone	2026-06-21 05:44:32.991288
34939	1329	\N	\N	1403	1	standalone	2026-06-21 05:44:32.991288
34940	1322	\N	\N	167	1	standalone	2026-06-21 05:44:32.991288
34941	1322	\N	\N	2794	1	standalone	2026-06-21 05:44:32.991288
34942	1322	\N	\N	407	1	standalone	2026-06-21 05:44:32.991288
34943	1322	\N	\N	1570	1	standalone	2026-06-21 05:44:32.991288
30509	1303	\N	\N	2707	1	domain	2026-06-20 19:40:05.806753
34944	1322	\N	\N	2640	1	standalone	2026-06-21 05:44:32.991288
34945	1322	\N	\N	2609	1	standalone	2026-06-21 05:44:32.991288
30510	1303	\N	\N	2708	1	domain	2026-06-20 19:40:05.806753
30511	1303	\N	\N	2709	1	domain	2026-06-20 19:40:05.806753
34947	1322	\N	\N	389	1	standalone	2026-06-21 05:44:32.991288
34948	1322	\N	\N	628	1	standalone	2026-06-21 05:44:32.991288
34949	1322	\N	\N	1117	1	standalone	2026-06-21 05:44:32.991288
34950	1322	\N	\N	3157	1	standalone	2026-06-21 05:44:32.991288
34951	1322	\N	\N	2110	1	standalone	2026-06-21 05:44:32.991288
34952	1322	\N	\N	2111	1	standalone	2026-06-21 05:44:32.991288
34953	1322	\N	\N	2112	1	standalone	2026-06-21 05:44:32.991288
34954	1322	\N	\N	2157	1	standalone	2026-06-21 05:44:32.991288
34955	1322	\N	\N	1512	1	standalone	2026-06-21 05:44:32.991288
34956	1322	\N	\N	2232	1	standalone	2026-06-21 05:44:32.991288
34957	1322	\N	\N	1362	1	standalone	2026-06-21 05:44:32.991288
34958	1322	\N	\N	3035	1	standalone	2026-06-21 05:44:32.991288
34959	1322	\N	\N	2052	1	standalone	2026-06-21 05:44:32.991288
34960	1322	\N	\N	2043	1	standalone	2026-06-21 05:44:32.991288
34961	1322	\N	\N	2041	1	standalone	2026-06-21 05:44:32.991288
34962	1322	\N	\N	2485	1	standalone	2026-06-21 05:44:32.991288
34963	1322	\N	\N	2486	1	standalone	2026-06-21 05:44:32.991288
34964	1322	\N	\N	2555	1	standalone	2026-06-21 05:44:32.991288
34965	1322	\N	\N	2556	1	standalone	2026-06-21 05:44:32.991288
34876	1322	\N	\N	1129	1	domain	2026-06-21 05:44:32.975306
34966	1322	\N	\N	1532	1	standalone	2026-06-21 05:44:32.991288
34967	1322	\N	\N	1363	1	standalone	2026-06-21 05:44:32.991288
34969	1322	\N	\N	2044	1	standalone	2026-06-21 05:44:32.991288
34970	1322	\N	\N	2053	1	standalone	2026-06-21 05:44:32.991288
34972	1327	\N	\N	2588	1	domain	2026-06-21 05:44:33.0073
34973	1327	\N	\N	176	1	domain	2026-06-21 05:44:33.0073
34974	1327	\N	\N	1560	1	domain	2026-06-21 05:44:33.0073
34976	1327	\N	\N	751	1	domain	2026-06-21 05:44:33.023718
34977	1327	\N	\N	3319	1	domain	2026-06-21 05:44:33.023718
34978	1327	\N	\N	3369	1	domain	2026-06-21 05:44:33.023718
34979	1327	\N	\N	1004	1	domain	2026-06-21 05:44:33.023718
34980	1327	\N	\N	65	1	domain	2026-06-21 05:44:33.023718
34982	1327	\N	\N	239	1	domain	2026-06-21 05:44:33.023718
34983	1327	\N	\N	1241	1	domain	2026-06-21 05:44:33.023718
34984	1327	\N	\N	66	1	standalone	2026-06-21 05:44:33.023718
34986	1327	\N	\N	1020	1	standalone	2026-06-21 05:44:33.023718
34987	1327	\N	\N	2276	1	standalone	2026-06-21 05:44:33.023718
34988	1327	\N	\N	2277	1	standalone	2026-06-21 05:44:33.023718
34989	1327	\N	\N	2278	1	standalone	2026-06-21 05:44:33.023718
34990	1327	\N	\N	2279	1	standalone	2026-06-21 05:44:33.023718
34991	1329	\N	\N	3372	1	standalone	2026-06-21 05:44:33.023718
34992	1329	\N	\N	3106	1	standalone	2026-06-21 05:44:33.023718
34993	1329	\N	\N	124	1	standalone	2026-06-21 05:44:33.023718
34994	1329	\N	\N	1874	1	standalone	2026-06-21 05:44:33.023718
34995	1329	\N	\N	32	1	standalone	2026-06-21 05:44:33.023718
34996	1329	\N	\N	2823	1	standalone	2026-06-21 05:44:33.023718
34997	1329	\N	\N	2824	1	standalone	2026-06-21 05:44:33.023718
34998	1329	\N	\N	2907	1	standalone	2026-06-21 05:44:33.023718
34999	1329	\N	\N	1332	1	standalone	2026-06-21 05:44:33.023718
35000	1329	\N	\N	2383	1	standalone	2026-06-21 05:44:33.023718
35001	1329	\N	\N	2541	1	standalone	2026-06-21 05:44:33.023718
35002	1329	\N	\N	2552	1	standalone	2026-06-21 05:44:33.023718
35003	1329	\N	\N	2557	1	standalone	2026-06-21 05:44:33.023718
35004	1329	\N	\N	2558	1	standalone	2026-06-21 05:44:33.023718
35005	1329	\N	\N	2560	1	standalone	2026-06-21 05:44:33.023718
35006	1329	\N	\N	2568	1	standalone	2026-06-21 05:44:33.023718
35007	1329	\N	\N	2569	1	standalone	2026-06-21 05:44:33.023718
35008	1329	\N	\N	2570	1	standalone	2026-06-21 05:44:33.023718
35009	1329	\N	\N	2571	1	standalone	2026-06-21 05:44:33.023718
35019	1330	\N	\N	685	1	domain	2026-06-21 05:44:33.057224
35020	1330	\N	\N	3154	1	domain	2026-06-21 05:44:33.057224
35021	1330	\N	\N	457	1	domain	2026-06-21 05:44:33.057224
35022	1330	\N	\N	574	1	domain	2026-06-21 05:44:33.057224
35024	1330	\N	\N	1840	1	domain	2026-06-21 05:44:33.070648
35025	1330	\N	\N	1616	1	domain	2026-06-21 05:44:33.070648
35026	1330	\N	\N	1617	1	domain	2026-06-21 05:44:33.070648
35027	1330	\N	\N	1620	1	domain	2026-06-21 05:44:33.070648
35028	1330	\N	\N	2005	1	domain	2026-06-21 05:44:33.070648
35029	1330	\N	\N	2007	1	domain	2026-06-21 05:44:33.070648
35030	1330	\N	\N	2302	1	domain	2026-06-21 05:44:33.070648
35032	1330	\N	\N	1612	1	domain	2026-06-21 05:44:33.08332
35033	1330	\N	\N	3386	1	domain	2026-06-21 05:44:33.08332
35034	1330	\N	\N	2599	1	domain	2026-06-21 05:44:33.08332
35035	1330	\N	\N	188	1	domain	2026-06-21 05:44:33.08332
35036	1330	\N	\N	3360	1	domain	2026-06-21 05:44:33.08332
35037	1330	\N	\N	3308	1	domain	2026-06-21 05:44:33.08332
35038	1330	\N	\N	2927	1	domain	2026-06-21 05:44:33.08332
35039	1330	\N	\N	1294	1	domain	2026-06-21 05:44:33.08332
35041	1330	\N	\N	1613	1	domain	2026-06-21 05:44:33.093566
30512	1303	\N	\N	2710	1	domain	2026-06-20 19:40:05.806753
35042	1330	\N	\N	1621	1	domain	2026-06-21 05:44:33.093566
35043	1330	\N	\N	2000	1	domain	2026-06-21 05:44:33.093566
30513	1303	\N	\N	843	1	domain	2026-06-20 19:40:05.806753
30514	1303	\N	\N	2711	1	domain	2026-06-20 19:40:05.806753
30515	1303	\N	\N	2755	1	domain	2026-06-20 19:40:05.806753
30516	1303	\N	\N	1266	1	domain	2026-06-20 19:40:05.806753
30517	1303	\N	\N	2460	1	domain	2026-06-20 19:40:05.806753
30518	1303	\N	\N	2462	1	domain	2026-06-20 19:40:05.806753
30519	1303	\N	\N	2463	1	domain	2026-06-20 19:40:05.806753
35045	1330	\N	\N	1614	1	domain	2026-06-21 05:44:33.09558
35046	1330	\N	\N	259	1	domain	2026-06-21 05:44:33.09558
35047	1330	\N	\N	266	1	domain	2026-06-21 05:44:33.09558
35048	1330	\N	\N	98	1	domain	2026-06-21 05:44:33.09558
35049	1330	\N	\N	2002	1	domain	2026-06-21 05:44:33.09558
35050	1330	\N	\N	2008	1	domain	2026-06-21 05:44:33.09558
35057	1330	\N	\N	856	1	domain	2026-06-21 05:44:33.122004
35058	1330	\N	\N	2001	1	domain	2026-06-21 05:44:33.122004
35060	1330	\N	\N	262	1	standalone	2026-06-21 05:44:33.122004
35061	1330	\N	\N	263	1	standalone	2026-06-21 05:44:33.122004
35062	1330	\N	\N	264	1	standalone	2026-06-21 05:44:33.122004
35063	1330	\N	\N	301	1	standalone	2026-06-21 05:44:33.122004
30520	1303	\N	\N	2464	1	domain	2026-06-20 19:40:05.806753
35065	1330	\N	\N	265	1	domain	2026-06-21 05:44:33.122004
35066	1330	\N	\N	2202	1	domain	2026-06-21 05:44:33.122004
35068	1330	\N	\N	2106	1	domain	2026-06-21 05:44:33.144385
35069	1330	\N	\N	2113	1	domain	2026-06-21 05:44:33.144385
35071	1330	\N	\N	808	1	domain	2026-06-21 05:44:33.144385
35016	1330	\N	\N	2369	1	standalone	2026-06-21 05:44:33.047059
35017	1330	\N	\N	2374	1	standalone	2026-06-21 05:44:33.047059
35015	1330	\N	\N	2308	1	standalone	2026-06-21 05:44:33.047059
35012	1330	\N	\N	2198	1	standalone	2026-06-21 05:44:33.047059
35011	1330	\N	\N	2307	1	standalone	2026-06-21 05:44:33.047059
34968	1322	\N	\N	806	1	domain	2026-06-21 05:44:32.991288
34985	1327	\N	\N	79	1	domain	2026-06-21 05:44:33.023718
35055	1330	\N	\N	3234	1	domain	2026-06-21 05:44:33.105449
35059	1330	\N	\N	261	1	domain	2026-06-21 05:44:33.122004
35072	1330	\N	\N	519	1	domain	2026-06-21 05:44:33.144385
35073	1330	\N	\N	1339	1	domain	2026-06-21 05:44:33.144385
35074	1330	\N	\N	3081	1	domain	2026-06-21 05:44:33.144385
35075	1330	\N	\N	3083	1	domain	2026-06-21 05:44:33.144385
35077	1330	\N	\N	857	1	domain	2026-06-21 05:44:33.156534
35078	1330	\N	\N	2258	1	domain	2026-06-21 05:44:33.156534
35079	1330	\N	\N	2270	1	domain	2026-06-21 05:44:33.156534
35080	1330	\N	\N	858	1	standalone	2026-06-21 05:44:33.156534
35081	1330	\N	\N	571	1	standalone	2026-06-21 05:44:33.156534
35082	1330	\N	\N	2275	1	standalone	2026-06-21 05:44:33.156534
35084	1330	\N	\N	223	1	domain	2026-06-21 05:44:33.176383
35085	1330	\N	\N	1618	1	domain	2026-06-21 05:44:33.176383
35088	1330	\N	\N	257	1	domain	2026-06-21 05:44:33.176383
35089	1330	\N	\N	1919	1	domain	2026-06-21 05:44:33.176383
35090	1330	\N	\N	258	1	domain	2026-06-21 05:44:33.176383
35092	1330	\N	\N	267	1	domain	2026-06-21 05:44:33.176383
35094	1330	\N	\N	1017	1	domain	2026-06-21 05:44:33.176383
35097	1330	\N	\N	97	1	domain	2026-06-21 05:44:33.176383
35098	1330	\N	\N	854	1	domain	2026-06-21 05:44:33.176383
35099	1330	\N	\N	1999	1	domain	2026-06-21 05:44:33.176383
35100	1330	\N	\N	2196	1	domain	2026-06-21 05:44:33.176383
35101	1330	\N	\N	2199	1	domain	2026-06-21 05:44:33.176383
35111	1335	\N	\N	1179	1	domain	2026-06-21 05:44:33.195407
35112	1335	\N	\N	1180	1	domain	2026-06-21 05:44:33.195407
35113	1335	\N	\N	1181	1	domain	2026-06-21 05:44:33.195407
35114	1335	\N	\N	2691	1	domain	2026-06-21 05:44:33.195407
35115	1335	\N	\N	1174	1	domain	2026-06-21 05:44:33.195407
35116	1335	\N	\N	1175	1	domain	2026-06-21 05:44:33.195407
35117	1335	\N	\N	1176	1	domain	2026-06-21 05:44:33.195407
35118	1335	\N	\N	1177	1	domain	2026-06-21 05:44:33.195407
35119	1336	\N	\N	1861	1	standalone	2026-06-21 05:44:33.195407
35120	1336	\N	\N	1886	1	standalone	2026-06-21 05:44:33.195407
35121	1336	\N	\N	1887	1	standalone	2026-06-21 05:44:33.195407
35122	1336	\N	\N	2163	1	standalone	2026-06-21 05:44:33.195407
35124	1336	\N	\N	3324	1	domain	2026-06-21 05:44:33.211909
35125	1336	\N	\N	2161	1	domain	2026-06-21 05:44:33.211909
35126	1336	\N	\N	3325	1	standalone	2026-06-21 05:44:33.211909
35127	1336	\N	\N	3326	1	standalone	2026-06-21 05:44:33.211909
35129	1336	\N	\N	3327	1	domain	2026-06-21 05:44:33.211909
35130	1336	\N	\N	1195	1	domain	2026-06-21 05:44:33.211909
35132	1336	\N	\N	3329	1	domain	2026-06-21 05:44:33.219966
35133	1336	\N	\N	1198	1	domain	2026-06-21 05:44:33.219966
35135	1336	\N	\N	3330	1	domain	2026-06-21 05:44:33.22824
35136	1336	\N	\N	3001	1	domain	2026-06-21 05:44:33.22824
35137	1336	\N	\N	3023	1	domain	2026-06-21 05:44:33.22824
35139	1336	\N	\N	2634	1	domain	2026-06-21 05:44:33.22824
35140	1336	\N	\N	3011	1	domain	2026-06-21 05:44:33.22824
35142	1336	\N	\N	965	1	domain	2026-06-21 05:44:33.244994
35143	1336	\N	\N	128	1	domain	2026-06-21 05:44:33.244994
35145	1336	\N	\N	3201	1	domain	2026-06-21 05:44:33.244994
35146	1336	\N	\N	1034	1	domain	2026-06-21 05:44:33.244994
35147	1336	\N	\N	829	1	domain	2026-06-21 05:44:33.244994
35150	1336	\N	\N	1632	1	domain	2026-06-21 05:44:33.244994
35151	1336	\N	\N	1194	1	domain	2026-06-21 05:44:33.244994
35152	1336	\N	\N	374	1	standalone	2026-06-21 05:44:33.244994
35153	1336	\N	\N	375	1	standalone	2026-06-21 05:44:33.244994
35154	1336	\N	\N	376	1	standalone	2026-06-21 05:44:33.244994
35156	1336	\N	\N	3345	1	domain	2026-06-21 05:44:33.263718
35157	1336	\N	\N	2170	1	domain	2026-06-21 05:44:33.263718
35160	1336	\N	\N	2819	1	domain	2026-06-21 05:44:33.263718
35161	1336	\N	\N	2029	1	domain	2026-06-21 05:44:33.263718
35162	1336	\N	\N	2030	1	domain	2026-06-21 05:44:33.263718
35164	1336	\N	\N	2820	1	domain	2026-06-21 05:44:33.276232
35165	1336	\N	\N	3002	1	domain	2026-06-21 05:44:33.276232
35166	1336	\N	\N	1196	1	standalone	2026-06-21 05:44:33.276232
35168	1336	\N	\N	1197	1	domain	2026-06-21 05:44:33.276232
35169	1336	\N	\N	3024	1	domain	2026-06-21 05:44:33.276232
35171	1336	\N	\N	2212	1	domain	2026-06-21 05:44:33.292264
35172	1336	\N	\N	3022	1	domain	2026-06-21 05:44:33.292264
35173	1336	\N	\N	2165	1	standalone	2026-06-21 05:44:33.292264
35174	1336	\N	\N	2489	1	standalone	2026-06-21 05:44:33.292264
35175	1336	\N	\N	2499	1	standalone	2026-06-21 05:44:33.292264
35177	1336	\N	\N	87	1	standalone	2026-06-21 05:44:33.292264
35179	1336	\N	\N	1193	1	domain	2026-06-21 05:44:33.292264
35180	1336	\N	\N	3020	1	domain	2026-06-21 05:44:33.292264
35181	1336	\N	\N	2368	1	standalone	2026-06-21 05:44:33.292264
35182	1336	\N	\N	2391	1	standalone	2026-06-21 05:44:33.292264
35183	1336	\N	\N	2392	1	standalone	2026-06-21 05:44:33.292264
35184	1336	\N	\N	2393	1	standalone	2026-06-21 05:44:33.292264
35185	1336	\N	\N	2171	1	standalone	2026-06-21 05:44:33.292264
35187	1336	\N	\N	598	1	domain	2026-06-21 05:44:33.328484
35188	1336	\N	\N	2595	1	domain	2026-06-21 05:44:33.328484
35176	1336	\N	\N	86	1	domain	2026-06-21 05:44:33.292264
35158	1336	\N	\N	3279	1	domain	2026-06-21 05:44:33.263718
35189	1336	\N	\N	184	1	domain	2026-06-21 05:44:33.328484
35195	1336	\N	\N	1591	1	domain	2026-06-21 05:44:33.328484
35201	1336	\N	\N	870	1	domain	2026-06-21 05:44:33.328484
35202	1336	\N	\N	1934	1	domain	2026-06-21 05:44:33.328484
35221	1336	\N	\N	3021	1	domain	2026-06-21 05:44:33.328484
35224	1334	\N	\N	3183	1	domain	2026-06-21 05:44:33.345148
35225	1334	\N	\N	832	1	domain	2026-06-21 05:44:33.345148
35228	1325	\N	\N	684	1	domain	2026-06-21 05:44:33.355671
35229	1325	\N	\N	779	1	domain	2026-06-21 05:44:33.355671
35230	1325	\N	\N	984	1	domain	2026-06-21 05:44:33.355671
35231	1325	\N	\N	557	1	domain	2026-06-21 05:44:33.355671
35233	1325	\N	\N	8	1	domain	2026-06-21 05:44:33.362252
35234	1325	\N	\N	2087	1	domain	2026-06-21 05:44:33.362252
35236	1325	\N	\N	3193	1	standalone	2026-06-21 05:44:33.362252
35237	1325	\N	\N	2679	1	standalone	2026-06-21 05:44:33.362252
35239	1327	\N	\N	3317	1	domain	2026-06-21 05:44:33.37844
35240	1327	\N	\N	690	1	domain	2026-06-21 05:44:33.37844
35241	1327	\N	\N	178	1	domain	2026-06-21 05:44:33.37844
35242	1327	\N	\N	2681	1	domain	2026-06-21 05:44:33.37844
35243	1327	\N	\N	1957	1	domain	2026-06-21 05:44:33.37844
35244	1327	\N	\N	1692	1	domain	2026-06-21 05:44:33.37844
35246	1327	\N	\N	985	1	standalone	2026-06-21 05:44:33.37844
35247	1327	\N	\N	528	1	standalone	2026-06-21 05:44:33.37844
35248	1327	\N	\N	567	1	standalone	2026-06-21 05:44:33.37844
35249	1327	\N	\N	585	1	standalone	2026-06-21 05:44:33.37844
35250	1327	\N	\N	2474	1	standalone	2026-06-21 05:44:33.37844
35252	1329	\N	\N	644	1	domain	2026-06-21 05:44:33.395405
35253	1329	\N	\N	213	1	domain	2026-06-21 05:44:33.395405
35254	1329	\N	\N	1890	1	domain	2026-06-21 05:44:33.395405
35256	1329	\N	\N	1732	1	domain	2026-06-21 05:44:33.395405
35257	1329	\N	\N	894	1	domain	2026-06-21 05:44:33.395405
35261	1337	\N	\N	3373	1	domain	2026-06-21 05:44:33.406274
35262	1337	\N	\N	1930	1	domain	2026-06-21 05:44:33.406274
35263	1337	\N	\N	1838	1	standalone	2026-06-21 05:44:33.406274
35265	1337	\N	\N	3378	1	domain	2026-06-21 05:44:33.426632
35266	1337	\N	\N	254	1	domain	2026-06-21 05:44:33.426632
35267	1337	\N	\N	255	1	domain	2026-06-21 05:44:33.426632
35268	1337	\N	\N	2019	1	domain	2026-06-21 05:44:33.426632
35269	1337	\N	\N	2020	1	domain	2026-06-21 05:44:33.426632
35271	1337	\N	\N	1554	1	domain	2026-06-21 05:44:33.437269
35272	1337	\N	\N	2762	1	domain	2026-06-21 05:44:33.437269
35274	1337	\N	\N	2598	1	domain	2026-06-21 05:44:33.451241
35275	1337	\N	\N	186	1	domain	2026-06-21 05:44:33.451241
35276	1337	\N	\N	1820	1	standalone	2026-06-21 05:44:33.451241
35277	1337	\N	\N	250	1	standalone	2026-06-21 05:44:33.451241
35278	1337	\N	\N	2909	1	standalone	2026-06-21 05:44:33.451241
35280	1337	\N	\N	1928	1	domain	2026-06-21 05:44:33.453254
35281	1337	\N	\N	2781	1	domain	2026-06-21 05:44:33.453254
35283	1337	\N	\N	3242	1	domain	2026-06-21 05:44:33.459568
35284	1337	\N	\N	3243	1	domain	2026-06-21 05:44:33.459568
35285	1337	\N	\N	872	1	domain	2026-06-21 05:44:33.459568
35286	1337	\N	\N	1166	1	standalone	2026-06-21 05:44:33.459568
35288	1337	\N	\N	2945	1	standalone	2026-06-21 05:44:33.459568
35290	1337	\N	\N	2947	1	domain	2026-06-21 05:44:33.475768
35291	1337	\N	\N	2022	1	domain	2026-06-21 05:44:33.475768
35292	1337	\N	\N	2023	1	domain	2026-06-21 05:44:33.475768
35293	1337	\N	\N	2303	1	domain	2026-06-21 05:44:33.475768
35294	1337	\N	\N	2408	1	domain	2026-06-21 05:44:33.475768
35296	1337	\N	\N	1704	1	standalone	2026-06-21 05:44:33.475768
35297	1337	\N	\N	324	1	standalone	2026-06-21 05:44:33.475768
35298	1337	\N	\N	325	1	standalone	2026-06-21 05:44:33.475768
35299	1337	\N	\N	2024	1	standalone	2026-06-21 05:44:33.475768
35300	1337	\N	\N	2782	1	standalone	2026-06-21 05:44:33.475768
35301	1337	\N	\N	2783	1	standalone	2026-06-21 05:44:33.475768
35303	1337	\N	\N	1303	1	standalone	2026-06-21 05:44:33.475768
35304	1337	\N	\N	2341	1	standalone	2026-06-21 05:44:33.475768
35305	1337	\N	\N	2411	1	standalone	2026-06-21 05:44:33.475768
35245	1327	\N	\N	3195	1	domain	2026-06-21 05:44:33.37844
35287	1337	\N	\N	102	1	domain	2026-06-21 05:44:33.459568
35302	1337	\N	\N	1302	1	domain	2026-06-21 05:44:33.475768
35307	1337	\N	\N	256	1	domain	2026-06-21 05:44:33.475768
35308	1337	\N	\N	1010	1	domain	2026-06-21 05:44:33.475768
35309	1330	\N	\N	2626	1	standalone	2026-06-21 05:44:33.475768
35310	1330	\N	\N	2646	1	standalone	2026-06-21 05:44:33.475768
35311	1330	\N	\N	2671	1	standalone	2026-06-21 05:44:33.475768
35312	1330	\N	\N	2744	1	standalone	2026-06-21 05:44:33.475768
35313	1330	\N	\N	2736	1	standalone	2026-06-21 05:44:33.475768
35315	1330	\N	\N	1744	1	domain	2026-06-21 05:44:33.491735
35316	1330	\N	\N	2648	1	domain	2026-06-21 05:44:33.491735
35318	1330	\N	\N	1843	1	domain	2026-06-21 05:44:33.491735
35319	1330	\N	\N	1844	1	domain	2026-06-21 05:44:33.491735
35320	1330	\N	\N	3274	1	domain	2026-06-21 05:44:33.491735
35321	1330	\N	\N	3275	1	domain	2026-06-21 05:44:33.491735
35322	1330	\N	\N	1575	1	domain	2026-06-21 05:44:33.491735
35323	1330	\N	\N	296	1	domain	2026-06-21 05:44:33.491735
35324	1330	\N	\N	306	1	domain	2026-06-21 05:44:33.491735
35326	1330	\N	\N	1847	1	domain	2026-06-21 05:44:33.51099
35327	1330	\N	\N	2698	1	domain	2026-06-21 05:44:33.51099
35328	1330	\N	\N	3235	1	domain	2026-06-21 05:44:33.51099
35329	1330	\N	\N	855	1	domain	2026-06-21 05:44:33.51099
35330	1330	\N	\N	2428	1	domain	2026-06-21 05:44:33.51099
35332	1330	\N	\N	599	1	domain	2026-06-21 05:44:33.515008
35333	1330	\N	\N	600	1	domain	2026-06-21 05:44:33.515008
35334	1330	\N	\N	1018	1	domain	2026-06-21 05:44:33.515008
35335	1330	\N	\N	1204	1	domain	2026-06-21 05:44:33.515008
35338	1330	\N	\N	3336	1	domain	2026-06-21 05:44:33.525251
35339	1330	\N	\N	2210	1	domain	2026-06-21 05:44:33.525251
35341	1330	\N	\N	2438	1	domain	2026-06-21 05:44:33.525251
35343	1330	\N	\N	2713	1	domain	2026-06-21 05:44:33.540797
35344	1330	\N	\N	2492	1	domain	2026-06-21 05:44:33.540797
35345	1330	\N	\N	2506	1	domain	2026-06-21 05:44:33.540797
35346	1330	\N	\N	2193	1	standalone	2026-06-21 05:44:33.540797
35347	1330	\N	\N	2194	1	standalone	2026-06-21 05:44:33.540797
35348	1330	\N	\N	2195	1	standalone	2026-06-21 05:44:33.540797
35349	1330	\N	\N	2201	1	standalone	2026-06-21 05:44:33.540797
35350	1330	\N	\N	2205	1	standalone	2026-06-21 05:44:33.540797
35351	1330	\N	\N	2487	1	standalone	2026-06-21 05:44:33.540797
35352	1330	\N	\N	2331	1	standalone	2026-06-21 05:44:33.540797
35353	1330	\N	\N	2363	1	standalone	2026-06-21 05:44:33.540797
35354	1330	\N	\N	2387	1	standalone	2026-06-21 05:44:33.540797
35355	1330	\N	\N	2423	1	standalone	2026-06-21 05:44:33.540797
35356	1330	\N	\N	2429	1	standalone	2026-06-21 05:44:33.540797
35357	1330	\N	\N	2547	1	standalone	2026-06-21 05:44:33.540797
35359	1330	\N	\N	2670	1	domain	2026-06-21 05:44:33.548909
35360	1330	\N	\N	2956	1	domain	2026-06-21 05:44:33.548909
35361	1330	\N	\N	2732	1	domain	2026-06-21 05:44:33.548909
35363	1330	\N	\N	2938	1	domain	2026-06-21 05:44:33.557295
35364	1330	\N	\N	1627	1	domain	2026-06-21 05:44:33.557295
35365	1330	\N	\N	3147	1	domain	2026-06-21 05:44:33.557295
35370	1330	\N	\N	1727	1	domain	2026-06-21 05:44:33.570978
35371	1330	\N	\N	2770	1	domain	2026-06-21 05:44:33.570978
35372	1330	\N	\N	2771	1	domain	2026-06-21 05:44:33.570978
35373	1330	\N	\N	2773	1	domain	2026-06-21 05:44:33.570978
35374	1330	\N	\N	2774	1	domain	2026-06-21 05:44:33.570978
35376	1327	\N	\N	752	1	domain	2026-06-21 05:44:33.581816
35377	1327	\N	\N	699	1	domain	2026-06-21 05:44:33.581816
35378	1327	\N	\N	766	1	domain	2026-06-21 05:44:33.581816
35380	1327	\N	\N	754	1	standalone	2026-06-21 05:44:33.581816
35382	1327	\N	\N	3320	1	domain	2026-06-21 05:44:33.590075
35383	1327	\N	\N	3384	1	domain	2026-06-21 05:44:33.590075
35384	1327	\N	\N	1966	1	domain	2026-06-21 05:44:33.590075
35385	1327	\N	\N	1236	1	domain	2026-06-21 05:44:33.590075
35386	1327	\N	\N	237	1	standalone	2026-06-21 05:44:33.590075
35387	1327	\N	\N	1965	1	standalone	2026-06-21 05:44:33.590075
35388	1327	\N	\N	1967	1	standalone	2026-06-21 05:44:33.590075
35390	1327	\N	\N	1969	1	domain	2026-06-21 05:44:33.590075
35391	1327	\N	\N	2265	1	domain	2026-06-21 05:44:33.590075
35392	1327	\N	\N	1977	1	standalone	2026-06-21 05:44:33.590075
35394	1327	\N	\N	1978	1	domain	2026-06-21 05:44:33.606617
35395	1327	\N	\N	2443	1	domain	2026-06-21 05:44:33.606617
35396	1327	\N	\N	548	1	standalone	2026-06-21 05:44:33.606617
35397	1327	\N	\N	2264	1	standalone	2026-06-21 05:44:33.606617
35399	1327	\N	\N	1722	1	domain	2026-06-21 05:44:33.623313
35400	1327	\N	\N	768	1	domain	2026-06-21 05:44:33.623313
35401	1327	\N	\N	769	1	domain	2026-06-21 05:44:33.623313
35402	1327	\N	\N	226	1	domain	2026-06-21 05:44:33.623313
35403	1327	\N	\N	726	1	domain	2026-06-21 05:44:33.623313
35404	1327	\N	\N	3218	1	domain	2026-06-21 05:44:33.623313
35405	1327	\N	\N	1330	1	domain	2026-06-21 05:44:33.623313
35407	1338	\N	\N	1547	1	domain	2026-06-21 05:44:33.623313
35408	1338	\N	\N	700	1	domain	2026-06-21 05:44:33.623313
35409	1338	\N	\N	967	1	domain	2026-06-21 05:44:33.623313
35410	1338	\N	\N	611	1	domain	2026-06-21 05:44:33.623313
35411	1338	\N	\N	2172	1	domain	2026-06-21 05:44:33.623313
35412	1338	\N	\N	2385	1	domain	2026-06-21 05:44:33.623313
35414	1338	\N	\N	1202	1	domain	2026-06-21 05:44:33.639104
35415	1338	\N	\N	3277	1	domain	2026-06-21 05:44:33.639104
35417	1338	\N	\N	2173	1	domain	2026-06-21 05:44:33.639104
35418	1338	\N	\N	150	1	domain	2026-06-21 05:44:33.639104
35424	1338	\N	\N	2176	1	domain	2026-06-21 05:44:33.664968
35425	1338	\N	\N	152	1	domain	2026-06-21 05:44:33.664968
35426	1338	\N	\N	2455	1	standalone	2026-06-21 05:44:33.664968
35427	1338	\N	\N	2175	1	standalone	2026-06-21 05:44:33.664968
35428	1338	\N	\N	2207	1	standalone	2026-06-21 05:44:33.664968
35430	1338	\N	\N	2822	1	domain	2026-06-21 05:44:33.670594
35431	1338	\N	\N	488	1	domain	2026-06-21 05:44:33.670594
35432	1338	\N	\N	344	1	domain	2026-06-21 05:44:33.670594
35433	1338	\N	\N	154	1	domain	2026-06-21 05:44:33.670594
35438	1338	\N	\N	3229	1	domain	2026-06-21 05:44:33.687298
35439	1338	\N	\N	1209	1	domain	2026-06-21 05:44:33.687298
35440	1338	\N	\N	1210	1	domain	2026-06-21 05:44:33.687298
35441	1338	\N	\N	155	1	domain	2026-06-21 05:44:33.687298
35442	1338	\N	\N	1205	1	standalone	2026-06-21 05:44:33.687298
35443	1338	\N	\N	153	1	standalone	2026-06-21 05:44:33.687298
35445	1338	\N	\N	337	1	domain	2026-06-21 05:44:33.695541
35446	1338	\N	\N	340	1	domain	2026-06-21 05:44:33.695541
35447	1338	\N	\N	341	1	domain	2026-06-21 05:44:33.695541
35449	1338	\N	\N	151	1	domain	2026-06-21 05:44:33.695541
35450	1338	\N	\N	2143	1	standalone	2026-06-21 05:44:33.695541
35452	1338	\N	\N	3337	1	domain	2026-06-21 05:44:33.713754
35453	1338	\N	\N	968	1	domain	2026-06-21 05:44:33.713754
35454	1338	\N	\N	969	1	domain	2026-06-21 05:44:33.713754
35455	1338	\N	\N	3228	1	domain	2026-06-21 05:44:33.713754
35456	1338	\N	\N	2903	1	domain	2026-06-21 05:44:33.713754
35457	1338	\N	\N	1203	1	domain	2026-06-21 05:44:33.713754
35458	1338	\N	\N	1542	1	domain	2026-06-21 05:44:33.713754
35460	1338	\N	\N	2177	1	domain	2026-06-21 05:44:33.713754
35465	1329	\N	\N	3395	1	standalone	2026-06-21 05:44:33.713754
35466	1329	\N	\N	1619	1	standalone	2026-06-21 05:44:33.713754
35469	1329	\N	\N	3285	1	standalone	2026-06-21 05:44:33.713754
35470	1329	\N	\N	3286	1	standalone	2026-06-21 05:44:33.713754
35471	1329	\N	\N	3288	1	standalone	2026-06-21 05:44:33.713754
35472	1329	\N	\N	3289	1	standalone	2026-06-21 05:44:33.713754
35473	1329	\N	\N	729	1	standalone	2026-06-21 05:44:33.713754
35474	1329	\N	\N	3363	1	standalone	2026-06-21 05:44:33.713754
30521	1303	\N	\N	2465	1	domain	2026-06-20 19:40:05.806753
30522	1303	\N	\N	2466	1	domain	2026-06-20 19:40:05.806753
30524	1303	\N	\N	369	1	domain	2026-06-20 19:40:05.81158
30525	1303	\N	\N	3305	1	domain	2026-06-20 19:40:05.81158
30526	1303	\N	\N	1444	1	domain	2026-06-20 19:40:05.81158
30527	1303	\N	\N	1470	1	domain	2026-06-20 19:40:05.81158
30529	1303	\N	\N	955	1	domain	2026-06-20 19:40:05.81158
30530	1303	\N	\N	956	1	domain	2026-06-20 19:40:05.81158
30531	1303	\N	\N	814	1	domain	2026-06-20 19:40:05.81158
30533	1303	\N	\N	661	1	domain	2026-06-20 19:40:05.81158
30534	1303	\N	\N	415	1	domain	2026-06-20 19:40:05.81158
30535	1303	\N	\N	1013	1	domain	2026-06-20 19:40:05.81158
30537	1303	\N	\N	222	1	domain	2026-06-20 19:40:05.819728
30538	1303	\N	\N	1891	1	domain	2026-06-20 19:40:05.819728
30539	1303	\N	\N	1893	1	domain	2026-06-20 19:40:05.819728
30540	1303	\N	\N	234	1	domain	2026-06-20 19:40:05.819728
30541	1303	\N	\N	1260	1	domain	2026-06-20 19:40:05.819728
30542	1303	\N	\N	1261	1	domain	2026-06-20 19:40:05.819728
30543	1303	\N	\N	2388	1	domain	2026-06-20 19:40:05.819728
30545	1303	\N	\N	1624	1	domain	2026-06-20 19:40:05.819728
30546	1303	\N	\N	637	1	domain	2026-06-20 19:40:05.819728
30547	1303	\N	\N	638	1	domain	2026-06-20 19:40:05.819728
30548	1303	\N	\N	639	1	domain	2026-06-20 19:40:05.819728
30549	1303	\N	\N	846	1	domain	2026-06-20 19:40:05.819728
30550	1303	\N	\N	847	1	domain	2026-06-20 19:40:05.819728
30551	1303	\N	\N	108	1	domain	2026-06-20 19:40:05.819728
30552	1303	\N	\N	2185	1	domain	2026-06-20 19:40:05.819728
30553	1303	\N	\N	2360	1	domain	2026-06-20 19:40:05.819728
30555	1303	\N	\N	3292	1	domain	2026-06-20 19:40:05.819728
30556	1303	\N	\N	737	1	domain	2026-06-20 19:40:05.819728
30557	1303	\N	\N	3306	1	domain	2026-06-20 19:40:05.819728
30559	1304	\N	\N	945	1	domain	2026-06-20 19:40:05.827954
30560	1304	\N	\N	686	1	domain	2026-06-20 19:40:05.827954
30561	1304	\N	\N	2580	1	domain	2026-06-20 19:40:05.827954
30562	1304	\N	\N	791	1	domain	2026-06-20 19:40:05.827954
30563	1304	\N	\N	774	1	domain	2026-06-20 19:40:05.827954
30564	1304	\N	\N	1819	1	domain	2026-06-20 19:40:05.827954
30565	1304	\N	\N	2740	1	domain	2026-06-20 19:40:05.827954
30566	1304	\N	\N	2033	1	domain	2026-06-20 19:40:05.827954
30567	1304	\N	\N	2034	1	domain	2026-06-20 19:40:05.827954
30569	1304	\N	\N	1067	1	domain	2026-06-20 19:40:05.827954
30570	1304	\N	\N	1854	1	domain	2026-06-20 19:40:05.827954
30571	1304	\N	\N	608	1	domain	2026-06-20 19:40:05.827954
30572	1304	\N	\N	1856	1	domain	2026-06-20 19:40:05.827954
30573	1304	\N	\N	2637	1	domain	2026-06-20 19:40:05.827954
30574	1304	\N	\N	2638	1	domain	2026-06-20 19:40:05.827954
30575	1304	\N	\N	2639	1	domain	2026-06-20 19:40:05.827954
30576	1304	\N	\N	970	1	domain	2026-06-20 19:40:05.827954
35464	1329	\N	\N	645	1	domain	2026-06-21 05:44:33.713754
35475	1329	\N	\N	733	1	domain	2026-06-21 05:44:33.713754
35467	1329	\N	\N	976	1	domain	2026-06-21 05:44:33.713754
35468	1329	\N	\N	3350	1	domain	2026-06-21 05:44:33.713754
35477	1329	\N	\N	861	1	domain	2026-06-21 05:44:33.713754
35481	1329	\N	\N	132	1	domain	2026-06-21 05:44:33.713754
35476	1329	\N	\N	853	1	domain	2026-06-21 05:44:33.713754
30577	1304	\N	\N	197	1	domain	2026-06-20 19:40:05.827954
30578	1304	\N	\N	2613	1	domain	2026-06-20 19:40:05.827954
30579	1304	\N	\N	943	1	domain	2026-06-20 19:40:05.827954
30580	1304	\N	\N	251	1	domain	2026-06-20 19:40:05.827954
30581	1304	\N	\N	1810	1	domain	2026-06-20 19:40:05.827954
30582	1304	\N	\N	476	1	domain	2026-06-20 19:40:05.827954
30583	1304	\N	\N	1188	1	domain	2026-06-20 19:40:05.827954
30584	1304	\N	\N	1189	1	domain	2026-06-20 19:40:05.827954
30585	1304	\N	\N	1190	1	domain	2026-06-20 19:40:05.827954
30586	1304	\N	\N	1367	1	domain	2026-06-20 19:40:05.827954
30587	1304	\N	\N	2966	1	domain	2026-06-20 19:40:05.827954
30588	1304	\N	\N	2183	1	domain	2026-06-20 19:40:05.827954
30589	1304	\N	\N	1301	1	domain	2026-06-20 19:40:05.827954
30590	1304	\N	\N	1314	1	domain	2026-06-20 19:40:05.827954
30591	1304	\N	\N	2412	1	domain	2026-06-20 19:40:05.827954
30592	1304	\N	\N	2490	1	domain	2026-06-20 19:40:05.827954
30593	1304	\N	\N	2509	1	domain	2026-06-20 19:40:05.827954
30594	1304	\N	\N	2526	1	domain	2026-06-20 19:40:05.827954
30595	1304	\N	\N	2530	1	domain	2026-06-20 19:40:05.827954
30597	1304	\N	\N	2905	1	domain	2026-06-20 19:40:05.837772
30598	1304	\N	\N	1135	1	domain	2026-06-20 19:40:05.837772
30599	1304	\N	\N	1822	1	domain	2026-06-20 19:40:05.837772
30600	1304	\N	\N	2107	1	domain	2026-06-20 19:40:05.837772
30601	1304	\N	\N	2133	1	domain	2026-06-20 19:40:05.837772
30602	1304	\N	\N	2138	1	domain	2026-06-20 19:40:05.837772
30603	1304	\N	\N	2414	1	domain	2026-06-20 19:40:05.837772
30605	1304	\N	\N	748	1	domain	2026-06-20 19:40:05.837772
30606	1304	\N	\N	163	1	domain	2026-06-20 19:40:05.837772
30607	1304	\N	\N	1682	1	domain	2026-06-20 19:40:05.837772
30608	1304	\N	\N	1684	1	domain	2026-06-20 19:40:05.837772
30610	1304	\N	\N	944	1	domain	2026-06-20 19:40:05.844259
30611	1304	\N	\N	2579	1	domain	2026-06-20 19:40:05.844259
30612	1304	\N	\N	1818	1	domain	2026-06-20 19:40:05.844259
30613	1304	\N	\N	787	1	domain	2026-06-20 19:40:05.844259
30614	1304	\N	\N	3356	1	domain	2026-06-20 19:40:05.844259
30615	1304	\N	\N	123	1	domain	2026-06-20 19:40:05.844259
30616	1304	\N	\N	2031	1	domain	2026-06-20 19:40:05.844259
30617	1304	\N	\N	2032	1	domain	2026-06-20 19:40:05.844259
30619	1304	\N	\N	351	1	domain	2026-06-20 19:40:05.844259
30620	1304	\N	\N	3354	1	domain	2026-06-20 19:40:05.844259
30621	1304	\N	\N	2893	1	domain	2026-06-20 19:40:05.844259
30622	1304	\N	\N	503	1	domain	2026-06-20 19:40:05.844259
30623	1304	\N	\N	504	1	domain	2026-06-20 19:40:05.844259
30624	1304	\N	\N	507	1	domain	2026-06-20 19:40:05.844259
30626	1304	\N	\N	682	1	domain	2026-06-20 19:40:05.85286
30627	1304	\N	\N	1546	1	domain	2026-06-20 19:40:05.85286
30628	1304	\N	\N	1545	1	domain	2026-06-20 19:40:05.85286
30629	1304	\N	\N	3110	1	domain	2026-06-20 19:40:05.85286
30630	1304	\N	\N	3114	1	domain	2026-06-20 19:40:05.85286
30631	1304	\N	\N	3115	1	domain	2026-06-20 19:40:05.85286
30632	1304	\N	\N	1131	1	domain	2026-06-20 19:40:05.85286
30633	1304	\N	\N	3119	1	domain	2026-06-20 19:40:05.85286
30634	1304	\N	\N	7016	1	domain	2026-06-20 19:40:05.85286
30635	1304	\N	\N	925	1	domain	2026-06-20 19:40:05.85286
30636	1304	\N	\N	3391	1	domain	2026-06-20 19:40:05.85286
30637	1304	\N	\N	1568	1	domain	2026-06-20 19:40:05.85286
30638	1304	\N	\N	3171	1	domain	2026-06-20 19:40:05.85286
30639	1304	\N	\N	2094	1	domain	2026-06-20 19:40:05.85286
30640	1304	\N	\N	3355	1	domain	2026-06-20 19:40:05.85286
30641	1304	\N	\N	629	1	domain	2026-06-20 19:40:05.85286
30642	1304	\N	\N	449	1	domain	2026-06-20 19:40:05.85286
30643	1304	\N	\N	1151	1	domain	2026-06-20 19:40:05.85286
30644	1304	\N	\N	2118	1	domain	2026-06-20 19:40:05.85286
30645	1304	\N	\N	2910	1	domain	2026-06-20 19:40:05.85286
30646	1304	\N	\N	2911	1	domain	2026-06-20 19:40:05.85286
30647	1304	\N	\N	2912	1	domain	2026-06-20 19:40:05.85286
30648	1304	\N	\N	2914	1	domain	2026-06-20 19:40:05.85286
30649	1304	\N	\N	2130	1	domain	2026-06-20 19:40:05.85286
30650	1304	\N	\N	2131	1	domain	2026-06-20 19:40:05.85286
30651	1304	\N	\N	2132	1	domain	2026-06-20 19:40:05.85286
30652	1304	\N	\N	2134	1	domain	2026-06-20 19:40:05.85286
30653	1304	\N	\N	1518	1	domain	2026-06-20 19:40:05.85286
30654	1304	\N	\N	1690	1	domain	2026-06-20 19:40:05.85286
30655	1304	\N	\N	1703	1	domain	2026-06-20 19:40:05.85286
30656	1304	\N	\N	2735	1	domain	2026-06-20 19:40:05.85286
30657	1304	\N	\N	2036	1	domain	2026-06-20 19:40:05.85286
30658	1304	\N	\N	2037	1	domain	2026-06-20 19:40:05.85286
30659	1304	\N	\N	3053	1	domain	2026-06-20 19:40:05.85286
30660	1304	\N	\N	3054	1	domain	2026-06-20 19:40:05.85286
30661	1304	\N	\N	3082	1	domain	2026-06-20 19:40:05.85286
30662	1304	\N	\N	2305	1	domain	2026-06-20 19:40:05.85286
30663	1304	\N	\N	2356	1	domain	2026-06-20 19:40:05.85286
30664	1304	\N	\N	2365	1	domain	2026-06-20 19:40:05.85286
30665	1304	\N	\N	2401	1	domain	2026-06-20 19:40:05.85286
30666	1304	\N	\N	2402	1	domain	2026-06-20 19:40:05.85286
30667	1304	\N	\N	2403	1	domain	2026-06-20 19:40:05.85286
30668	1304	\N	\N	2405	1	domain	2026-06-20 19:40:05.85286
30669	1304	\N	\N	2469	1	domain	2026-06-20 19:40:05.85286
30670	1304	\N	\N	2482	1	domain	2026-06-20 19:40:05.85286
30671	1304	\N	\N	2500	1	domain	2026-06-20 19:40:05.85286
30672	1304	\N	\N	2551	1	domain	2026-06-20 19:40:05.85286
30674	1304	\N	\N	3250	1	domain	2026-06-20 19:40:05.860444
30675	1304	\N	\N	2064	1	domain	2026-06-20 19:40:05.860444
30676	1304	\N	\N	2851	1	domain	2026-06-20 19:40:05.860444
30677	1304	\N	\N	2065	1	domain	2026-06-20 19:40:05.860444
30678	1304	\N	\N	2852	1	domain	2026-06-20 19:40:05.860444
30679	1304	\N	\N	2066	1	domain	2026-06-20 19:40:05.860444
30680	1304	\N	\N	2853	1	domain	2026-06-20 19:40:05.860444
30681	1304	\N	\N	2067	1	domain	2026-06-20 19:40:05.860444
30682	1304	\N	\N	2068	1	domain	2026-06-20 19:40:05.860444
30683	1304	\N	\N	2856	1	domain	2026-06-20 19:40:05.860444
30684	1304	\N	\N	2070	1	domain	2026-06-20 19:40:05.860444
30685	1304	\N	\N	1562	1	domain	2026-06-20 19:40:05.860444
30686	1304	\N	\N	2077	1	domain	2026-06-20 19:40:05.860444
30687	1304	\N	\N	2083	1	domain	2026-06-20 19:40:05.860444
30688	1304	\N	\N	2872	1	domain	2026-06-20 19:40:05.860444
30689	1304	\N	\N	2873	1	domain	2026-06-20 19:40:05.860444
30690	1304	\N	\N	2874	1	domain	2026-06-20 19:40:05.860444
30691	1304	\N	\N	2875	1	domain	2026-06-20 19:40:05.860444
30692	1304	\N	\N	2877	1	domain	2026-06-20 19:40:05.860444
30693	1304	\N	\N	1107	1	domain	2026-06-20 19:40:05.860444
30694	1304	\N	\N	1108	1	domain	2026-06-20 19:40:05.860444
30695	1304	\N	\N	2656	1	domain	2026-06-20 19:40:05.860444
30696	1304	\N	\N	1113	1	domain	2026-06-20 19:40:05.860444
30697	1304	\N	\N	2658	1	domain	2026-06-20 19:40:05.860444
30698	1304	\N	\N	1114	1	domain	2026-06-20 19:40:05.860444
30699	1304	\N	\N	2659	1	domain	2026-06-20 19:40:05.860444
30700	1304	\N	\N	2892	1	domain	2026-06-20 19:40:05.860444
30701	1304	\N	\N	2109	1	domain	2026-06-20 19:40:05.860444
30702	1304	\N	\N	2158	1	domain	2026-06-20 19:40:05.860444
30703	1304	\N	\N	2480	1	domain	2026-06-20 19:40:05.860444
30704	1304	\N	\N	2538	1	domain	2026-06-20 19:40:05.860444
30706	1304	\N	\N	2842	1	domain	2026-06-20 19:40:05.860444
30707	1304	\N	\N	2845	1	domain	2026-06-20 19:40:05.860444
30708	1304	\N	\N	356	1	domain	2026-06-20 19:40:05.860444
30709	1304	\N	\N	2846	1	domain	2026-06-20 19:40:05.860444
30710	1304	\N	\N	2862	1	domain	2026-06-20 19:40:05.860444
30711	1304	\N	\N	1110	1	domain	2026-06-20 19:40:05.860444
30713	1304	\N	\N	2627	1	domain	2026-06-20 19:40:05.869013
30714	1304	\N	\N	2614	1	domain	2026-06-20 19:40:05.869013
30715	1304	\N	\N	2063	1	domain	2026-06-20 19:40:05.869013
30716	1304	\N	\N	2629	1	domain	2026-06-20 19:40:05.869013
30717	1304	\N	\N	368	1	domain	2026-06-20 19:40:05.869013
30718	1304	\N	\N	2631	1	domain	2026-06-20 19:40:05.869013
30719	1304	\N	\N	2071	1	domain	2026-06-20 19:40:05.869013
30720	1304	\N	\N	2632	1	domain	2026-06-20 19:40:05.869013
30721	1304	\N	\N	2633	1	domain	2026-06-20 19:40:05.869013
30722	1304	\N	\N	2073	1	domain	2026-06-20 19:40:05.869013
30723	1304	\N	\N	2643	1	domain	2026-06-20 19:40:05.869013
30724	1304	\N	\N	2644	1	domain	2026-06-20 19:40:05.869013
30725	1304	\N	\N	2645	1	domain	2026-06-20 19:40:05.869013
30726	1304	\N	\N	164	1	domain	2026-06-20 19:40:05.869013
30727	1304	\N	\N	2652	1	domain	2026-06-20 19:40:05.869013
30728	1304	\N	\N	2653	1	domain	2026-06-20 19:40:05.869013
30729	1304	\N	\N	2654	1	domain	2026-06-20 19:40:05.869013
30730	1304	\N	\N	2906	1	domain	2026-06-20 19:40:05.869013
30731	1304	\N	\N	2655	1	domain	2026-06-20 19:40:05.869013
30732	1304	\N	\N	2657	1	domain	2026-06-20 19:40:05.869013
30733	1304	\N	\N	2660	1	domain	2026-06-20 19:40:05.869013
30734	1304	\N	\N	2661	1	domain	2026-06-20 19:40:05.869013
30735	1304	\N	\N	2889	1	domain	2026-06-20 19:40:05.869013
30736	1304	\N	\N	2664	1	domain	2026-06-20 19:40:05.869013
30737	1304	\N	\N	2665	1	domain	2026-06-20 19:40:05.869013
30738	1304	\N	\N	2666	1	domain	2026-06-20 19:40:05.869013
30739	1304	\N	\N	2667	1	domain	2026-06-20 19:40:05.869013
30740	1304	\N	\N	2902	1	domain	2026-06-20 19:40:05.869013
30741	1304	\N	\N	2683	1	domain	2026-06-20 19:40:05.869013
30742	1304	\N	\N	2933	1	domain	2026-06-20 19:40:05.869013
30743	1304	\N	\N	2934	1	domain	2026-06-20 19:40:05.869013
30744	1304	\N	\N	1685	1	domain	2026-06-20 19:40:05.869013
30745	1304	\N	\N	2730	1	domain	2026-06-20 19:40:05.869013
30746	1304	\N	\N	2733	1	domain	2026-06-20 19:40:05.869013
30747	1304	\N	\N	2738	1	domain	2026-06-20 19:40:05.869013
30748	1304	\N	\N	2739	1	domain	2026-06-20 19:40:05.869013
30749	1304	\N	\N	2741	1	domain	2026-06-20 19:40:05.869013
30750	1304	\N	\N	2746	1	domain	2026-06-20 19:40:05.869013
30751	1304	\N	\N	2747	1	domain	2026-06-20 19:40:05.869013
30752	1304	\N	\N	2748	1	domain	2026-06-20 19:40:05.869013
30753	1304	\N	\N	2495	1	domain	2026-06-20 19:40:05.869013
30754	1304	\N	\N	2496	1	domain	2026-06-20 19:40:05.869013
30756	1304	\N	\N	3256	1	domain	2026-06-20 19:40:05.876878
30757	1304	\N	\N	3176	1	domain	2026-06-20 19:40:05.876878
30758	1304	\N	\N	2147	1	domain	2026-06-20 19:40:05.876878
30759	1304	\N	\N	104	1	domain	2026-06-20 19:40:05.876878
30760	1304	\N	\N	105	1	domain	2026-06-20 19:40:05.876878
30761	1304	\N	\N	107	1	domain	2026-06-20 19:40:05.876878
30762	1304	\N	\N	2772	1	domain	2026-06-20 19:40:05.876878
30764	1304	\N	\N	2069	1	domain	2026-06-20 19:40:05.876878
30765	1304	\N	\N	2865	1	domain	2026-06-20 19:40:05.876878
30766	1304	\N	\N	1622	1	domain	2026-06-20 19:40:05.876878
30767	1304	\N	\N	3178	1	domain	2026-06-20 19:40:05.876878
30768	1304	\N	\N	3179	1	domain	2026-06-20 19:40:05.876878
30769	1304	\N	\N	788	1	domain	2026-06-20 19:40:05.876878
30770	1304	\N	\N	2098	1	domain	2026-06-20 19:40:05.876878
30771	1304	\N	\N	1907	1	domain	2026-06-20 19:40:05.876878
30772	1304	\N	\N	1908	1	domain	2026-06-20 19:40:05.876878
30773	1304	\N	\N	2891	1	domain	2026-06-20 19:40:05.876878
30774	1304	\N	\N	1681	1	domain	2026-06-20 19:40:05.876878
30775	1304	\N	\N	1689	1	domain	2026-06-20 19:40:05.876878
30776	1304	\N	\N	1696	1	domain	2026-06-20 19:40:05.876878
30777	1304	\N	\N	1701	1	domain	2026-06-20 19:40:05.876878
30778	1304	\N	\N	1706	1	domain	2026-06-20 19:40:05.876878
30779	1304	\N	\N	1724	1	domain	2026-06-20 19:40:05.876878
30780	1304	\N	\N	1997	1	domain	2026-06-20 19:40:05.876878
30781	1304	\N	\N	1998	1	domain	2026-06-20 19:40:05.876878
30782	1304	\N	\N	2290	1	domain	2026-06-20 19:40:05.876878
30784	1304	\N	\N	1139	1	domain	2026-06-20 19:40:05.876878
30785	1304	\N	\N	1140	1	domain	2026-06-20 19:40:05.876878
30786	1304	\N	\N	2980	1	domain	2026-06-20 19:40:05.876878
30787	1304	\N	\N	2984	1	domain	2026-06-20 19:40:05.876878
30789	1304	\N	\N	2078	1	domain	2026-06-20 19:40:05.88517
30790	1304	\N	\N	789	1	domain	2026-06-20 19:40:05.88517
30791	1304	\N	\N	790	1	domain	2026-06-20 19:40:05.88517
30792	1304	\N	\N	1535	1	domain	2026-06-20 19:40:05.88517
30793	1304	\N	\N	1534	1	domain	2026-06-20 19:40:05.88517
30795	1304	\N	\N	2081	1	domain	2026-06-20 19:40:05.890992
30796	1304	\N	\N	2662	1	domain	2026-06-20 19:40:05.890992
30797	1304	\N	\N	2663	1	domain	2026-06-20 19:40:05.890992
30798	1304	\N	\N	2684	1	domain	2026-06-20 19:40:05.890992
30799	1304	\N	\N	2686	1	domain	2026-06-20 19:40:05.890992
30800	1304	\N	\N	2687	1	domain	2026-06-20 19:40:05.890992
30801	1304	\N	\N	2936	1	domain	2026-06-20 19:40:05.890992
30802	1304	\N	\N	2715	1	domain	2026-06-20 19:40:05.890992
30803	1304	\N	\N	2154	1	domain	2026-06-20 19:40:05.890992
30804	1304	\N	\N	2155	1	domain	2026-06-20 19:40:05.890992
30805	1304	\N	\N	2724	1	domain	2026-06-20 19:40:05.890992
30806	1304	\N	\N	2725	1	domain	2026-06-20 19:40:05.890992
30807	1304	\N	\N	2731	1	domain	2026-06-20 19:40:05.890992
30808	1304	\N	\N	2742	1	domain	2026-06-20 19:40:05.890992
30809	1304	\N	\N	2743	1	domain	2026-06-20 19:40:05.890992
30810	1304	\N	\N	2364	1	domain	2026-06-20 19:40:05.890992
30811	1304	\N	\N	2415	1	domain	2026-06-20 19:40:05.890992
30813	1304	\N	\N	1742	1	domain	2026-06-20 19:40:05.895005
30814	1304	\N	\N	683	1	domain	2026-06-20 19:40:05.895005
30815	1304	\N	\N	353	1	domain	2026-06-20 19:40:05.895005
30816	1304	\N	\N	1743	1	domain	2026-06-20 19:40:05.895005
30817	1304	\N	\N	168	1	domain	2026-06-20 19:40:05.895005
30818	1304	\N	\N	590	1	domain	2026-06-20 19:40:05.895005
30819	1304	\N	\N	169	1	domain	2026-06-20 19:40:05.895005
30820	1304	\N	\N	591	1	domain	2026-06-20 19:40:05.895005
30821	1304	\N	\N	2582	1	domain	2026-06-20 19:40:05.895005
30822	1304	\N	\N	1128	1	domain	2026-06-20 19:40:05.895005
30823	1304	\N	\N	586	1	domain	2026-06-20 19:40:05.895005
30824	1304	\N	\N	1129	1	domain	2026-06-20 19:40:05.895005
30825	1304	\N	\N	3113	1	domain	2026-06-20 19:40:05.895005
30826	1304	\N	\N	3258	1	domain	2026-06-20 19:40:05.895005
30827	1304	\N	\N	589	1	domain	2026-06-20 19:40:05.895005
30828	1304	\N	\N	1555	1	domain	2026-06-20 19:40:05.895005
30829	1304	\N	\N	1130	1	domain	2026-06-20 19:40:05.895005
30830	1304	\N	\N	2855	1	domain	2026-06-20 19:40:05.895005
30831	1304	\N	\N	367	1	domain	2026-06-20 19:40:05.895005
30832	1304	\N	\N	1134	1	domain	2026-06-20 19:40:05.895005
30833	1304	\N	\N	610	1	domain	2026-06-20 19:40:05.895005
30834	1304	\N	\N	1763	1	domain	2026-06-20 19:40:05.895005
30835	1304	\N	\N	3172	1	domain	2026-06-20 19:40:05.895005
30836	1304	\N	\N	3280	1	domain	2026-06-20 19:40:05.895005
30837	1304	\N	\N	1815	1	domain	2026-06-20 19:40:05.895005
30838	1304	\N	\N	2876	1	domain	2026-06-20 19:40:05.895005
30839	1304	\N	\N	1111	1	domain	2026-06-20 19:40:05.895005
30840	1304	\N	\N	783	1	domain	2026-06-20 19:40:05.895005
30841	1304	\N	\N	784	1	domain	2026-06-20 19:40:05.895005
30842	1304	\N	\N	785	1	domain	2026-06-20 19:40:05.895005
30843	1304	\N	\N	1126	1	domain	2026-06-20 19:40:05.895005
30844	1304	\N	\N	786	1	domain	2026-06-20 19:40:05.895005
30845	1304	\N	\N	1127	1	domain	2026-06-20 19:40:05.895005
30846	1304	\N	\N	1823	1	domain	2026-06-20 19:40:05.895005
30847	1304	\N	\N	1793	1	domain	2026-06-20 19:40:05.895005
30848	1304	\N	\N	1794	1	domain	2026-06-20 19:40:05.895005
30849	1304	\N	\N	1799	1	domain	2026-06-20 19:40:05.895005
30850	1304	\N	\N	1800	1	domain	2026-06-20 19:40:05.895005
30851	1304	\N	\N	2125	1	domain	2026-06-20 19:40:05.895005
30852	1304	\N	\N	2126	1	domain	2026-06-20 19:40:05.895005
30853	1304	\N	\N	2913	1	domain	2026-06-20 19:40:05.895005
30854	1304	\N	\N	2135	1	domain	2026-06-20 19:40:05.895005
30855	1304	\N	\N	2136	1	domain	2026-06-20 19:40:05.895005
30856	1304	\N	\N	2139	1	domain	2026-06-20 19:40:05.895005
30857	1304	\N	\N	1686	1	domain	2026-06-20 19:40:05.895005
30858	1304	\N	\N	2949	1	domain	2026-06-20 19:40:05.895005
30859	1304	\N	\N	2950	1	domain	2026-06-20 19:40:05.895005
30860	1304	\N	\N	2752	1	domain	2026-06-20 19:40:05.895005
30861	1304	\N	\N	2951	1	domain	2026-06-20 19:40:05.895005
30862	1304	\N	\N	1705	1	domain	2026-06-20 19:40:05.895005
30863	1304	\N	\N	2737	1	domain	2026-06-20 19:40:05.895005
30864	1304	\N	\N	2756	1	domain	2026-06-20 19:40:05.895005
30865	1304	\N	\N	2759	1	domain	2026-06-20 19:40:05.895005
30866	1304	\N	\N	2764	1	domain	2026-06-20 19:40:05.895005
30867	1304	\N	\N	2404	1	domain	2026-06-20 19:40:05.895005
30869	1304	\N	\N	167	1	domain	2026-06-20 19:40:05.902377
30870	1304	\N	\N	2794	1	domain	2026-06-20 19:40:05.902377
30871	1304	\N	\N	407	1	domain	2026-06-20 19:40:05.902377
30872	1304	\N	\N	1570	1	domain	2026-06-20 19:40:05.902377
30873	1304	\N	\N	2640	1	domain	2026-06-20 19:40:05.902377
30874	1304	\N	\N	2609	1	domain	2026-06-20 19:40:05.902377
30875	1304	\N	\N	979	1	domain	2026-06-20 19:40:05.902377
30876	1304	\N	\N	389	1	domain	2026-06-20 19:40:05.902377
30877	1304	\N	\N	628	1	domain	2026-06-20 19:40:05.902377
30878	1304	\N	\N	1117	1	domain	2026-06-20 19:40:05.902377
30879	1304	\N	\N	3157	1	domain	2026-06-20 19:40:05.902377
30880	1304	\N	\N	2110	1	domain	2026-06-20 19:40:05.902377
30881	1304	\N	\N	2111	1	domain	2026-06-20 19:40:05.902377
30882	1304	\N	\N	2112	1	domain	2026-06-20 19:40:05.902377
30883	1304	\N	\N	806	1	domain	2026-06-20 19:40:05.902377
30884	1304	\N	\N	2157	1	domain	2026-06-20 19:40:05.902377
30885	1304	\N	\N	1512	1	domain	2026-06-20 19:40:05.902377
30886	1304	\N	\N	2232	1	domain	2026-06-20 19:40:05.902377
30887	1304	\N	\N	1363	1	domain	2026-06-20 19:40:05.902377
30888	1304	\N	\N	2041	1	domain	2026-06-20 19:40:05.902377
30889	1304	\N	\N	2043	1	domain	2026-06-20 19:40:05.902377
30890	1304	\N	\N	2044	1	domain	2026-06-20 19:40:05.902377
30891	1304	\N	\N	1362	1	domain	2026-06-20 19:40:05.902377
30892	1304	\N	\N	3035	1	domain	2026-06-20 19:40:05.902377
30893	1304	\N	\N	2052	1	domain	2026-06-20 19:40:05.902377
30894	1304	\N	\N	2053	1	domain	2026-06-20 19:40:05.902377
30895	1304	\N	\N	1532	1	domain	2026-06-20 19:40:05.902377
30896	1304	\N	\N	2485	1	domain	2026-06-20 19:40:05.902377
30897	1304	\N	\N	2486	1	domain	2026-06-20 19:40:05.902377
30898	1304	\N	\N	2555	1	domain	2026-06-20 19:40:05.902377
30899	1304	\N	\N	2556	1	domain	2026-06-20 19:40:05.902377
30901	1304	\N	\N	2197	1	domain	2026-06-20 19:40:05.902377
30902	1304	\N	\N	2757	1	domain	2026-06-20 19:40:05.902377
30903	1304	\N	\N	2758	1	domain	2026-06-20 19:40:05.902377
30904	1304	\N	\N	2761	1	domain	2026-06-20 19:40:05.902377
30905	1304	\N	\N	2769	1	domain	2026-06-20 19:40:05.902377
30906	1304	\N	\N	1293	1	domain	2026-06-20 19:40:05.902377
30908	1304	\N	\N	756	1	domain	2026-06-20 19:40:05.909364
30909	1304	\N	\N	3187	1	domain	2026-06-20 19:40:05.909364
30910	1304	\N	\N	953	1	domain	2026-06-20 19:40:05.909364
30911	1304	\N	\N	17	1	domain	2026-06-20 19:40:05.909364
30912	1304	\N	\N	812	1	domain	2026-06-20 19:40:05.909364
30913	1304	\N	\N	1683	1	domain	2026-06-20 19:40:05.909364
30914	1304	\N	\N	2288	1	domain	2026-06-20 19:40:05.909364
30916	1304	\N	\N	1553	1	domain	2026-06-20 19:40:05.909364
30917	1304	\N	\N	371	1	domain	2026-06-20 19:40:05.909364
30918	1304	\N	\N	2119	1	domain	2026-06-20 19:40:05.909364
30919	1304	\N	\N	317	1	domain	2026-06-20 19:40:05.909364
30920	1304	\N	\N	1709	1	domain	2026-06-20 19:40:05.909364
30921	1304	\N	\N	318	1	domain	2026-06-20 19:40:05.909364
30922	1304	\N	\N	319	1	domain	2026-06-20 19:40:05.909364
30923	1304	\N	\N	320	1	domain	2026-06-20 19:40:05.909364
30924	1304	\N	\N	1737	1	domain	2026-06-20 19:40:05.909364
30925	1304	\N	\N	2989	1	domain	2026-06-20 19:40:05.909364
30926	1304	\N	\N	2990	1	domain	2026-06-20 19:40:05.909364
30927	1304	\N	\N	2991	1	domain	2026-06-20 19:40:05.909364
30928	1304	\N	\N	2992	1	domain	2026-06-20 19:40:05.909364
30929	1304	\N	\N	2993	1	domain	2026-06-20 19:40:05.909364
30930	1304	\N	\N	2994	1	domain	2026-06-20 19:40:05.909364
30931	1304	\N	\N	2995	1	domain	2026-06-20 19:40:05.909364
30932	1304	\N	\N	2996	1	domain	2026-06-20 19:40:05.909364
30933	1304	\N	\N	2997	1	domain	2026-06-20 19:40:05.909364
30934	1304	\N	\N	2998	1	domain	2026-06-20 19:40:05.909364
30935	1304	\N	\N	2999	1	domain	2026-06-20 19:40:05.909364
30936	1304	\N	\N	2051	1	domain	2026-06-20 19:40:05.909364
30937	1304	\N	\N	2481	1	domain	2026-06-20 19:40:05.909364
30938	1304	\N	\N	2483	1	domain	2026-06-20 19:40:05.909364
30939	1304	\N	\N	2484	1	domain	2026-06-20 19:40:05.909364
30940	1304	\N	\N	2502	1	domain	2026-06-20 19:40:05.909364
30941	1304	\N	\N	2503	1	domain	2026-06-20 19:40:05.909364
30942	1304	\N	\N	2507	1	domain	2026-06-20 19:40:05.909364
30944	1305	\N	\N	750	1	domain	2026-06-20 19:40:05.917766
30945	1305	\N	\N	64	1	domain	2026-06-20 19:40:05.917766
30947	1305	\N	\N	3315	1	domain	2026-06-20 19:40:05.917766
30948	1305	\N	\N	3316	1	domain	2026-06-20 19:40:05.917766
30949	1305	\N	\N	3122	1	domain	2026-06-20 19:40:05.917766
30950	1305	\N	\N	3267	1	domain	2026-06-20 19:40:05.917766
30951	1305	\N	\N	724	1	domain	2026-06-20 19:40:05.917766
30952	1305	\N	\N	3216	1	domain	2026-06-20 19:40:05.917766
30953	1305	\N	\N	454	1	domain	2026-06-20 19:40:05.917766
30954	1305	\N	\N	1234	1	domain	2026-06-20 19:40:05.917766
30955	1305	\N	\N	547	1	domain	2026-06-20 19:40:05.917766
30956	1305	\N	\N	2561	1	domain	2026-06-20 19:40:05.917766
30958	1305	\N	\N	1693	1	domain	2026-06-20 19:40:05.925671
30959	1305	\N	\N	2589	1	domain	2026-06-20 19:40:05.925671
30960	1305	\N	\N	3318	1	domain	2026-06-20 19:40:05.925671
35550	1322	\N	\N	2652	1	domain	2026-06-21 05:44:33.808149
30961	1305	\N	\N	753	1	domain	2026-06-20 19:40:05.925671
30962	1305	\N	\N	10	1	domain	2026-06-20 19:40:05.925671
30963	1305	\N	\N	11	1	domain	2026-06-20 19:40:05.925671
30964	1305	\N	\N	177	1	domain	2026-06-20 19:40:05.925671
30965	1305	\N	\N	694	1	domain	2026-06-20 19:40:05.925671
30966	1305	\N	\N	961	1	domain	2026-06-20 19:40:05.925671
30967	1305	\N	\N	3196	1	domain	2026-06-20 19:40:05.925671
30968	1305	\N	\N	1597	1	domain	2026-06-20 19:40:05.925671
30969	1305	\N	\N	3268	1	domain	2026-06-20 19:40:05.925671
30970	1305	\N	\N	770	1	domain	2026-06-20 19:40:05.925671
30971	1305	\N	\N	3128	1	domain	2026-06-20 19:40:05.925671
30972	1305	\N	\N	1828	1	domain	2026-06-20 19:40:05.925671
30973	1305	\N	\N	31	1	domain	2026-06-20 19:40:05.925671
30974	1305	\N	\N	782	1	domain	2026-06-20 19:40:05.925671
30975	1305	\N	\N	2091	1	domain	2026-06-20 19:40:05.925671
30976	1305	\N	\N	242	1	domain	2026-06-20 19:40:05.925671
30977	1305	\N	\N	243	1	domain	2026-06-20 19:40:05.925671
30978	1305	\N	\N	3366	1	domain	2026-06-20 19:40:05.925671
30979	1305	\N	\N	3222	1	domain	2026-06-20 19:40:05.925671
30980	1305	\N	\N	444	1	domain	2026-06-20 19:40:05.925671
30981	1305	\N	\N	445	1	domain	2026-06-20 19:40:05.925671
30982	1305	\N	\N	738	1	domain	2026-06-20 19:40:05.925671
30983	1305	\N	\N	739	1	domain	2026-06-20 19:40:05.925671
30984	1305	\N	\N	740	1	domain	2026-06-20 19:40:05.925671
30985	1305	\N	\N	741	1	domain	2026-06-20 19:40:05.925671
30986	1305	\N	\N	3311	1	domain	2026-06-20 19:40:05.925671
30987	1305	\N	\N	69	1	domain	2026-06-20 19:40:05.925671
30988	1305	\N	\N	2922	1	domain	2026-06-20 19:40:05.925671
30989	1305	\N	\N	1943	1	domain	2026-06-20 19:40:05.925671
30990	1305	\N	\N	1944	1	domain	2026-06-20 19:40:05.925671
30991	1305	\N	\N	1945	1	domain	2026-06-20 19:40:05.925671
30992	1305	\N	\N	1946	1	domain	2026-06-20 19:40:05.925671
30993	1305	\N	\N	1374	1	domain	2026-06-20 19:40:05.925671
30994	1305	\N	\N	1235	1	domain	2026-06-20 19:40:05.925671
30995	1305	\N	\N	1238	1	domain	2026-06-20 19:40:05.925671
30996	1305	\N	\N	2200	1	domain	2026-06-20 19:40:05.925671
30997	1305	\N	\N	538	1	domain	2026-06-20 19:40:05.925671
30998	1305	\N	\N	539	1	domain	2026-06-20 19:40:05.925671
30999	1305	\N	\N	540	1	domain	2026-06-20 19:40:05.925671
31000	1305	\N	\N	541	1	domain	2026-06-20 19:40:05.925671
31001	1305	\N	\N	542	1	domain	2026-06-20 19:40:05.925671
31002	1305	\N	\N	543	1	domain	2026-06-20 19:40:05.925671
31003	1305	\N	\N	544	1	domain	2026-06-20 19:40:05.925671
31004	1305	\N	\N	545	1	domain	2026-06-20 19:40:05.925671
31005	1305	\N	\N	546	1	domain	2026-06-20 19:40:05.925671
31006	1305	\N	\N	1271	1	domain	2026-06-20 19:40:05.925671
31007	1305	\N	\N	566	1	domain	2026-06-20 19:40:05.925671
31008	1305	\N	\N	3034	1	domain	2026-06-20 19:40:05.925671
31009	1305	\N	\N	1426	1	domain	2026-06-20 19:40:05.925671
31010	1305	\N	\N	2249	1	domain	2026-06-20 19:40:05.925671
31011	1305	\N	\N	2262	1	domain	2026-06-20 19:40:05.925671
31012	1305	\N	\N	2395	1	domain	2026-06-20 19:40:05.925671
31014	1305	\N	\N	2587	1	domain	2026-06-20 19:40:05.925671
31015	1305	\N	\N	757	1	domain	2026-06-20 19:40:05.925671
31016	1305	\N	\N	175	1	domain	2026-06-20 19:40:05.925671
31017	1305	\N	\N	765	1	domain	2026-06-20 19:40:05.925671
31018	1305	\N	\N	3394	1	domain	2026-06-20 19:40:05.925671
31019	1305	\N	\N	233	1	domain	2026-06-20 19:40:05.925671
31020	1305	\N	\N	428	1	domain	2026-06-20 19:40:05.925671
31021	1305	\N	\N	77	1	domain	2026-06-20 19:40:05.925671
31022	1305	\N	\N	78	1	domain	2026-06-20 19:40:05.925671
31023	1305	\N	\N	1960	1	domain	2026-06-20 19:40:05.925671
31024	1305	\N	\N	1961	1	domain	2026-06-20 19:40:05.925671
31025	1305	\N	\N	1963	1	domain	2026-06-20 19:40:05.925671
31026	1305	\N	\N	1964	1	domain	2026-06-20 19:40:05.925671
31027	1305	\N	\N	1970	1	domain	2026-06-20 19:40:05.925671
31028	1305	\N	\N	1971	1	domain	2026-06-20 19:40:05.925671
31029	1305	\N	\N	1972	1	domain	2026-06-20 19:40:05.925671
31030	1305	\N	\N	1973	1	domain	2026-06-20 19:40:05.925671
31031	1305	\N	\N	1974	1	domain	2026-06-20 19:40:05.925671
31032	1305	\N	\N	1975	1	domain	2026-06-20 19:40:05.925671
31033	1305	\N	\N	568	1	domain	2026-06-20 19:40:05.925671
31034	1305	\N	\N	2323	1	domain	2026-06-20 19:40:05.925671
31036	1305	\N	\N	3314	1	domain	2026-06-20 19:40:05.942545
31037	1305	\N	\N	1859	1	domain	2026-06-20 19:40:05.942545
31038	1305	\N	\N	749	1	domain	2026-06-20 19:40:05.942545
31039	1305	\N	\N	3127	1	domain	2026-06-20 19:40:05.942545
31040	1305	\N	\N	1694	1	domain	2026-06-20 19:40:05.942545
31041	1305	\N	\N	396	1	domain	2026-06-20 19:40:05.942545
31042	1305	\N	\N	689	1	domain	2026-06-20 19:40:05.942545
31043	1305	\N	\N	3323	1	domain	2026-06-20 19:40:05.942545
31044	1305	\N	\N	174	1	domain	2026-06-20 19:40:05.942545
31045	1305	\N	\N	1601	1	domain	2026-06-20 19:40:05.942545
31046	1305	\N	\N	691	1	domain	2026-06-20 19:40:05.942545
31047	1305	\N	\N	693	1	domain	2026-06-20 19:40:05.942545
31048	1305	\N	\N	2586	1	domain	2026-06-20 19:40:05.942545
31049	1305	\N	\N	1604	1	domain	2026-06-20 19:40:05.942545
31050	1305	\N	\N	958	1	domain	2026-06-20 19:40:05.942545
31051	1305	\N	\N	3382	1	domain	2026-06-20 19:40:05.942545
31052	1305	\N	\N	212	1	domain	2026-06-20 19:40:05.942545
31053	1305	\N	\N	1605	1	domain	2026-06-20 19:40:05.942545
31054	1305	\N	\N	1592	1	domain	2026-06-20 19:40:05.942545
31055	1305	\N	\N	763	1	domain	2026-06-20 19:40:05.942545
31056	1305	\N	\N	1594	1	domain	2026-06-20 19:40:05.942545
31057	1305	\N	\N	1595	1	domain	2026-06-20 19:40:05.942545
31058	1305	\N	\N	3266	1	domain	2026-06-20 19:40:05.942545
31059	1305	\N	\N	1599	1	domain	2026-06-20 19:40:05.942545
31060	1305	\N	\N	3126	1	domain	2026-06-20 19:40:05.942545
31061	1305	\N	\N	3129	1	domain	2026-06-20 19:40:05.942545
31062	1305	\N	\N	416	1	domain	2026-06-20 19:40:05.942545
31063	1305	\N	\N	418	1	domain	2026-06-20 19:40:05.942545
31064	1305	\N	\N	419	1	domain	2026-06-20 19:40:05.942545
31065	1305	\N	\N	1416	1	domain	2026-06-20 19:40:05.942545
31066	1305	\N	\N	420	1	domain	2026-06-20 19:40:05.942545
31067	1305	\N	\N	1889	1	domain	2026-06-20 19:40:05.942545
31068	1305	\N	\N	422	1	domain	2026-06-20 19:40:05.942545
31069	1305	\N	\N	423	1	domain	2026-06-20 19:40:05.942545
31070	1305	\N	\N	714	1	domain	2026-06-20 19:40:05.942545
31071	1305	\N	\N	424	1	domain	2026-06-20 19:40:05.942545
31072	1305	\N	\N	427	1	domain	2026-06-20 19:40:05.942545
31073	1305	\N	\N	3142	1	domain	2026-06-20 19:40:05.942545
31074	1305	\N	\N	1628	1	domain	2026-06-20 19:40:05.942545
31075	1305	\N	\N	723	1	domain	2026-06-20 19:40:05.942545
31076	1305	\N	\N	725	1	domain	2026-06-20 19:40:05.942545
31077	1305	\N	\N	792	1	domain	2026-06-20 19:40:05.942545
31078	1305	\N	\N	3214	1	domain	2026-06-20 19:40:05.942545
31079	1305	\N	\N	1633	1	domain	2026-06-20 19:40:05.942545
31080	1305	\N	\N	248	1	domain	2026-06-20 19:40:05.942545
31081	1305	\N	\N	249	1	domain	2026-06-20 19:40:05.942545
31082	1305	\N	\N	443	1	domain	2026-06-20 19:40:05.942545
31083	1305	\N	\N	3224	1	domain	2026-06-20 19:40:05.942545
31084	1305	\N	\N	447	1	domain	2026-06-20 19:40:05.942545
31085	1305	\N	\N	1005	1	domain	2026-06-20 19:40:05.942545
31086	1305	\N	\N	1006	1	domain	2026-06-20 19:40:05.942545
31087	1305	\N	\N	63	1	domain	2026-06-20 19:40:05.942545
31088	1305	\N	\N	455	1	domain	2026-06-20 19:40:05.942545
31089	1305	\N	\N	67	1	domain	2026-06-20 19:40:05.942545
31090	1305	\N	\N	68	1	domain	2026-06-20 19:40:05.942545
31091	1305	\N	\N	70	1	domain	2026-06-20 19:40:05.942545
31092	1305	\N	\N	73	1	domain	2026-06-20 19:40:05.942545
31093	1305	\N	\N	74	1	domain	2026-06-20 19:40:05.942545
31094	1305	\N	\N	75	1	domain	2026-06-20 19:40:05.942545
31095	1305	\N	\N	1666	1	domain	2026-06-20 19:40:05.942545
31096	1305	\N	\N	1936	1	domain	2026-06-20 19:40:05.942545
31097	1305	\N	\N	1668	1	domain	2026-06-20 19:40:05.942545
31098	1305	\N	\N	80	1	domain	2026-06-20 19:40:05.942545
31099	1305	\N	\N	1940	1	domain	2026-06-20 19:40:05.942545
31100	1305	\N	\N	1941	1	domain	2026-06-20 19:40:05.942545
31101	1305	\N	\N	1942	1	domain	2026-06-20 19:40:05.942545
31102	1305	\N	\N	1947	1	domain	2026-06-20 19:40:05.942545
31103	1305	\N	\N	1948	1	domain	2026-06-20 19:40:05.942545
31104	1305	\N	\N	1949	1	domain	2026-06-20 19:40:05.942545
31105	1305	\N	\N	1950	1	domain	2026-06-20 19:40:05.942545
31106	1305	\N	\N	292	1	domain	2026-06-20 19:40:05.942545
31107	1305	\N	\N	295	1	domain	2026-06-20 19:40:05.942545
31108	1305	\N	\N	1687	1	domain	2026-06-20 19:40:05.942545
31109	1305	\N	\N	300	1	domain	2026-06-20 19:40:05.942545
31110	1305	\N	\N	118	1	domain	2026-06-20 19:40:05.942545
31111	1305	\N	\N	869	1	domain	2026-06-20 19:40:05.942545
31112	1305	\N	\N	1375	1	domain	2026-06-20 19:40:05.942545
31113	1305	\N	\N	1233	1	domain	2026-06-20 19:40:05.942545
31114	1305	\N	\N	1240	1	domain	2026-06-20 19:40:05.942545
31115	1305	\N	\N	140	1	domain	2026-06-20 19:40:05.942545
31116	1305	\N	\N	1410	1	domain	2026-06-20 19:40:05.942545
31117	1305	\N	\N	2206	1	domain	2026-06-20 19:40:05.942545
31118	1305	\N	\N	1264	1	domain	2026-06-20 19:40:05.942545
31119	1305	\N	\N	549	1	domain	2026-06-20 19:40:05.942545
31120	1305	\N	\N	553	1	domain	2026-06-20 19:40:05.942545
31121	1305	\N	\N	3008	1	domain	2026-06-20 19:40:05.942545
31122	1305	\N	\N	3018	1	domain	2026-06-20 19:40:05.942545
31123	1305	\N	\N	1283	1	domain	2026-06-20 19:40:05.942545
31124	1305	\N	\N	2243	1	domain	2026-06-20 19:40:05.942545
31125	1305	\N	\N	2244	1	domain	2026-06-20 19:40:05.942545
31126	1305	\N	\N	2252	1	domain	2026-06-20 19:40:05.942545
31127	1305	\N	\N	2253	1	domain	2026-06-20 19:40:05.942545
31128	1305	\N	\N	2256	1	domain	2026-06-20 19:40:05.942545
31129	1305	\N	\N	2259	1	domain	2026-06-20 19:40:05.942545
31130	1305	\N	\N	2260	1	domain	2026-06-20 19:40:05.942545
31131	1305	\N	\N	2271	1	domain	2026-06-20 19:40:05.942545
31132	1305	\N	\N	2272	1	domain	2026-06-20 19:40:05.942545
31133	1305	\N	\N	2294	1	domain	2026-06-20 19:40:05.942545
31134	1305	\N	\N	2361	1	domain	2026-06-20 19:40:05.942545
31135	1305	\N	\N	2371	1	domain	2026-06-20 19:40:05.942545
31136	1305	\N	\N	2372	1	domain	2026-06-20 19:40:05.942545
31137	1305	\N	\N	2384	1	domain	2026-06-20 19:40:05.942545
31138	1305	\N	\N	2436	1	domain	2026-06-20 19:40:05.942545
31139	1305	\N	\N	2447	1	domain	2026-06-20 19:40:05.942545
31140	1305	\N	\N	2522	1	domain	2026-06-20 19:40:05.942545
31141	1305	\N	\N	2546	1	domain	2026-06-20 19:40:05.942545
31143	1305	\N	\N	946	1	domain	2026-06-20 19:40:05.954552
31144	1305	\N	\N	3328	1	domain	2026-06-20 19:40:05.954552
31145	1305	\N	\N	1596	1	domain	2026-06-20 19:40:05.954552
31146	1305	\N	\N	3200	1	domain	2026-06-20 19:40:05.954552
31147	1305	\N	\N	2074	1	domain	2026-06-20 19:40:05.954552
31148	1305	\N	\N	1881	1	domain	2026-06-20 19:40:05.954552
31149	1305	\N	\N	3351	1	domain	2026-06-20 19:40:05.954552
31150	1305	\N	\N	3352	1	domain	2026-06-20 19:40:05.954552
31151	1305	\N	\N	3353	1	domain	2026-06-20 19:40:05.954552
31152	1305	\N	\N	3220	1	domain	2026-06-20 19:40:05.954552
31153	1305	\N	\N	1937	1	domain	2026-06-20 19:40:05.954552
31154	1305	\N	\N	830	1	domain	2026-06-20 19:40:05.954552
31155	1305	\N	\N	88	1	domain	2026-06-20 19:40:05.954552
31156	1305	\N	\N	89	1	domain	2026-06-20 19:40:05.954552
31157	1305	\N	\N	1199	1	domain	2026-06-20 19:40:05.954552
31158	1305	\N	\N	2166	1	domain	2026-06-20 19:40:05.954552
31159	1305	\N	\N	2245	1	domain	2026-06-20 19:40:05.954552
31160	1305	\N	\N	2250	1	domain	2026-06-20 19:40:05.954552
31162	1305	\N	\N	2588	1	domain	2026-06-20 19:40:05.959021
31163	1305	\N	\N	751	1	domain	2026-06-20 19:40:05.959021
31164	1305	\N	\N	3319	1	domain	2026-06-20 19:40:05.959021
31165	1305	\N	\N	3369	1	domain	2026-06-20 19:40:05.959021
31166	1305	\N	\N	176	1	domain	2026-06-20 19:40:05.959021
31167	1305	\N	\N	1560	1	domain	2026-06-20 19:40:05.959021
31168	1305	\N	\N	239	1	domain	2026-06-20 19:40:05.959021
31169	1305	\N	\N	1004	1	domain	2026-06-20 19:40:05.959021
31170	1305	\N	\N	65	1	domain	2026-06-20 19:40:05.959021
31171	1305	\N	\N	66	1	domain	2026-06-20 19:40:05.959021
31172	1305	\N	\N	1020	1	domain	2026-06-20 19:40:05.959021
31173	1305	\N	\N	79	1	domain	2026-06-20 19:40:05.959021
31174	1305	\N	\N	1241	1	domain	2026-06-20 19:40:05.959021
31175	1305	\N	\N	2276	1	domain	2026-06-20 19:40:05.959021
31176	1305	\N	\N	2277	1	domain	2026-06-20 19:40:05.959021
31177	1305	\N	\N	2278	1	domain	2026-06-20 19:40:05.959021
31178	1305	\N	\N	2279	1	domain	2026-06-20 19:40:05.959021
31180	1305	\N	\N	3317	1	domain	2026-06-20 19:40:05.959021
31181	1305	\N	\N	690	1	domain	2026-06-20 19:40:05.959021
31182	1305	\N	\N	178	1	domain	2026-06-20 19:40:05.959021
31183	1305	\N	\N	3195	1	domain	2026-06-20 19:40:05.959021
31184	1305	\N	\N	985	1	domain	2026-06-20 19:40:05.959021
31185	1305	\N	\N	2681	1	domain	2026-06-20 19:40:05.959021
31186	1305	\N	\N	1957	1	domain	2026-06-20 19:40:05.959021
31187	1305	\N	\N	1692	1	domain	2026-06-20 19:40:05.959021
31188	1305	\N	\N	528	1	domain	2026-06-20 19:40:05.959021
31189	1305	\N	\N	567	1	domain	2026-06-20 19:40:05.959021
31190	1305	\N	\N	585	1	domain	2026-06-20 19:40:05.959021
31191	1305	\N	\N	2474	1	domain	2026-06-20 19:40:05.959021
31193	1305	\N	\N	752	1	domain	2026-06-20 19:40:05.971455
31194	1305	\N	\N	754	1	domain	2026-06-20 19:40:05.971455
31195	1305	\N	\N	3320	1	domain	2026-06-20 19:40:05.971455
31196	1305	\N	\N	3384	1	domain	2026-06-20 19:40:05.971455
31197	1305	\N	\N	699	1	domain	2026-06-20 19:40:05.971455
31198	1305	\N	\N	766	1	domain	2026-06-20 19:40:05.971455
31199	1305	\N	\N	237	1	domain	2026-06-20 19:40:05.971455
31200	1305	\N	\N	3217	1	domain	2026-06-20 19:40:05.971455
31201	1305	\N	\N	1965	1	domain	2026-06-20 19:40:05.971455
31202	1305	\N	\N	1966	1	domain	2026-06-20 19:40:05.971455
31203	1305	\N	\N	1967	1	domain	2026-06-20 19:40:05.971455
31204	1305	\N	\N	1969	1	domain	2026-06-20 19:40:05.971455
31205	1305	\N	\N	1977	1	domain	2026-06-20 19:40:05.971455
31206	1305	\N	\N	1978	1	domain	2026-06-20 19:40:05.971455
31207	1305	\N	\N	1236	1	domain	2026-06-20 19:40:05.971455
31208	1305	\N	\N	548	1	domain	2026-06-20 19:40:05.971455
31209	1305	\N	\N	2264	1	domain	2026-06-20 19:40:05.971455
31210	1305	\N	\N	2265	1	domain	2026-06-20 19:40:05.971455
31211	1305	\N	\N	2443	1	domain	2026-06-20 19:40:05.971455
31213	1305	\N	\N	1722	1	domain	2026-06-20 19:40:05.975483
31214	1305	\N	\N	768	1	domain	2026-06-20 19:40:05.975483
31215	1305	\N	\N	769	1	domain	2026-06-20 19:40:05.975483
31216	1305	\N	\N	226	1	domain	2026-06-20 19:40:05.975483
31217	1305	\N	\N	726	1	domain	2026-06-20 19:40:05.975483
31218	1305	\N	\N	3218	1	domain	2026-06-20 19:40:05.975483
31219	1305	\N	\N	1330	1	domain	2026-06-20 19:40:05.975483
31221	1305	\N	\N	2092	1	domain	2026-06-20 19:40:05.975483
31222	1305	\N	\N	238	1	domain	2026-06-20 19:40:05.975483
31223	1305	\N	\N	433	1	domain	2026-06-20 19:40:05.975483
31224	1305	\N	\N	240	1	domain	2026-06-20 19:40:05.975483
31225	1305	\N	\N	241	1	domain	2026-06-20 19:40:05.975483
31226	1305	\N	\N	3215	1	domain	2026-06-20 19:40:05.975483
31227	1305	\N	\N	1795	1	domain	2026-06-20 19:40:05.975483
31228	1305	\N	\N	2920	1	domain	2026-06-20 19:40:05.975483
31229	1305	\N	\N	1951	1	domain	2026-06-20 19:40:05.975483
31230	1305	\N	\N	1952	1	domain	2026-06-20 19:40:05.975483
31231	1305	\N	\N	1953	1	domain	2026-06-20 19:40:05.975483
31232	1305	\N	\N	1954	1	domain	2026-06-20 19:40:05.975483
31233	1305	\N	\N	1956	1	domain	2026-06-20 19:40:05.975483
31234	1305	\N	\N	1958	1	domain	2026-06-20 19:40:05.975483
31235	1305	\N	\N	1959	1	domain	2026-06-20 19:40:05.975483
31236	1305	\N	\N	1976	1	domain	2026-06-20 19:40:05.975483
31237	1305	\N	\N	518	1	domain	2026-06-20 19:40:05.975483
31238	1305	\N	\N	520	1	domain	2026-06-20 19:40:05.975483
31239	1305	\N	\N	1239	1	domain	2026-06-20 19:40:05.975483
31240	1305	\N	\N	1242	1	domain	2026-06-20 19:40:05.975483
31241	1305	\N	\N	550	1	domain	2026-06-20 19:40:05.975483
31242	1305	\N	\N	551	1	domain	2026-06-20 19:40:05.975483
31243	1305	\N	\N	2255	1	domain	2026-06-20 19:40:05.975483
31244	1305	\N	\N	2268	1	domain	2026-06-20 19:40:05.975483
31245	1305	\N	\N	2269	1	domain	2026-06-20 19:40:05.975483
31246	1305	\N	\N	687	1	domain	2026-06-20 19:40:05.975483
31247	1305	\N	\N	688	1	domain	2026-06-20 19:40:05.975483
31248	1305	\N	\N	3322	1	domain	2026-06-20 19:40:05.975483
31249	1305	\N	\N	3188	1	domain	2026-06-20 19:40:05.975483
31250	1305	\N	\N	9	1	domain	2026-06-20 19:40:05.975483
31251	1305	\N	\N	1593	1	domain	2026-06-20 19:40:05.975483
31252	1305	\N	\N	1880	1	domain	2026-06-20 19:40:05.975483
31253	1305	\N	\N	2817	1	domain	2026-06-20 19:40:05.975483
31254	1305	\N	\N	2818	1	domain	2026-06-20 19:40:05.975483
31255	1305	\N	\N	3348	1	domain	2026-06-20 19:40:05.975483
31256	1305	\N	\N	1331	1	domain	2026-06-20 19:40:05.975483
31257	1305	\N	\N	2304	1	domain	2026-06-20 19:40:05.975483
31258	1305	\N	\N	2373	1	domain	2026-06-20 19:40:05.975483
31260	1305	\N	\N	959	1	domain	2026-06-20 19:40:05.983272
31261	1305	\N	\N	1825	1	domain	2026-06-20 19:40:05.983272
31262	1305	\N	\N	426	1	domain	2026-06-20 19:40:05.983272
31263	1305	\N	\N	1585	1	domain	2026-06-20 19:40:05.983272
31264	1305	\N	\N	247	1	domain	2026-06-20 19:40:05.983272
31265	1305	\N	\N	2921	1	domain	2026-06-20 19:40:05.983272
31266	1305	\N	\N	1537	1	domain	2026-06-20 19:40:05.983272
31268	1306	\N	\N	1547	1	domain	2026-06-20 19:40:05.990272
31269	1306	\N	\N	2455	1	domain	2026-06-20 19:40:05.990272
31270	1306	\N	\N	1201	1	domain	2026-06-20 19:40:05.990272
31271	1306	\N	\N	1202	1	domain	2026-06-20 19:40:05.990272
31272	1306	\N	\N	700	1	domain	2026-06-20 19:40:05.990272
31273	1306	\N	\N	967	1	domain	2026-06-20 19:40:05.990272
31274	1306	\N	\N	3337	1	domain	2026-06-20 19:40:05.990272
31275	1306	\N	\N	968	1	domain	2026-06-20 19:40:05.990272
31276	1306	\N	\N	969	1	domain	2026-06-20 19:40:05.990272
31277	1306	\N	\N	611	1	domain	2026-06-20 19:40:05.990272
31278	1306	\N	\N	3277	1	domain	2026-06-20 19:40:05.990272
31279	1306	\N	\N	2821	1	domain	2026-06-20 19:40:05.990272
31280	1306	\N	\N	2822	1	domain	2026-06-20 19:40:05.990272
31281	1306	\N	\N	3228	1	domain	2026-06-20 19:40:05.990272
31282	1306	\N	\N	3229	1	domain	2026-06-20 19:40:05.990272
31283	1306	\N	\N	3230	1	domain	2026-06-20 19:40:05.990272
31284	1306	\N	\N	2903	1	domain	2026-06-20 19:40:05.990272
31285	1306	\N	\N	1654	1	domain	2026-06-20 19:40:05.990272
31286	1306	\N	\N	2143	1	domain	2026-06-20 19:40:05.990272
31287	1306	\N	\N	488	1	domain	2026-06-20 19:40:05.990272
31288	1306	\N	\N	1203	1	domain	2026-06-20 19:40:05.990272
31289	1306	\N	\N	1205	1	domain	2026-06-20 19:40:05.990272
31290	1306	\N	\N	1542	1	domain	2026-06-20 19:40:05.990272
31291	1306	\N	\N	1209	1	domain	2026-06-20 19:40:05.990272
31292	1306	\N	\N	1210	1	domain	2026-06-20 19:40:05.990272
31293	1306	\N	\N	2172	1	domain	2026-06-20 19:40:05.990272
31294	1306	\N	\N	2173	1	domain	2026-06-20 19:40:05.990272
31295	1306	\N	\N	2174	1	domain	2026-06-20 19:40:05.990272
31296	1306	\N	\N	2175	1	domain	2026-06-20 19:40:05.990272
31297	1306	\N	\N	2176	1	domain	2026-06-20 19:40:05.990272
31298	1306	\N	\N	2177	1	domain	2026-06-20 19:40:05.990272
31299	1306	\N	\N	2965	1	domain	2026-06-20 19:40:05.990272
31300	1306	\N	\N	875	1	domain	2026-06-20 19:40:05.990272
31301	1306	\N	\N	337	1	domain	2026-06-20 19:40:05.990272
31302	1306	\N	\N	340	1	domain	2026-06-20 19:40:05.990272
31303	1306	\N	\N	341	1	domain	2026-06-20 19:40:05.990272
31304	1306	\N	\N	343	1	domain	2026-06-20 19:40:05.990272
31305	1306	\N	\N	344	1	domain	2026-06-20 19:40:05.990272
31306	1306	\N	\N	345	1	domain	2026-06-20 19:40:05.990272
31307	1306	\N	\N	149	1	domain	2026-06-20 19:40:05.990272
31308	1306	\N	\N	2203	1	domain	2026-06-20 19:40:05.990272
31309	1306	\N	\N	150	1	domain	2026-06-20 19:40:05.990272
31310	1306	\N	\N	151	1	domain	2026-06-20 19:40:05.990272
31311	1306	\N	\N	152	1	domain	2026-06-20 19:40:05.990272
31312	1306	\N	\N	153	1	domain	2026-06-20 19:40:05.990272
31313	1306	\N	\N	2207	1	domain	2026-06-20 19:40:05.990272
31314	1306	\N	\N	154	1	domain	2026-06-20 19:40:05.990272
31315	1306	\N	\N	155	1	domain	2026-06-20 19:40:05.990272
31316	1306	\N	\N	2385	1	domain	2026-06-20 19:40:05.990272
31318	1306	\N	\N	2606	1	domain	2026-06-20 19:40:05.991895
31319	1306	\N	\N	2418	1	domain	2026-06-20 19:40:05.991895
31321	1306	\N	\N	1849	1	domain	2026-06-20 19:40:05.991895
31322	1306	\N	\N	701	1	domain	2026-06-20 19:40:05.991895
31323	1306	\N	\N	3388	1	domain	2026-06-20 19:40:05.991895
31324	1306	\N	\N	2604	1	domain	2026-06-20 19:40:05.991895
31325	1306	\N	\N	931	1	domain	2026-06-20 19:40:05.991895
31326	1306	\N	\N	192	1	domain	2026-06-20 19:40:05.991895
31327	1306	\N	\N	1590	1	domain	2026-06-20 19:40:05.991895
31328	1306	\N	\N	1656	1	domain	2026-06-20 19:40:05.991895
31329	1306	\N	\N	1657	1	domain	2026-06-20 19:40:05.991895
31330	1306	\N	\N	1660	1	domain	2026-06-20 19:40:05.991895
31331	1306	\N	\N	1661	1	domain	2026-06-20 19:40:05.991895
31332	1306	\N	\N	2014	1	domain	2026-06-20 19:40:05.991895
31333	1306	\N	\N	2775	1	domain	2026-06-20 19:40:05.991895
31334	1306	\N	\N	1299	1	domain	2026-06-20 19:40:05.991895
31335	1306	\N	\N	2056	1	domain	2026-06-20 19:40:05.991895
31336	1306	\N	\N	2057	1	domain	2026-06-20 19:40:05.991895
31337	1306	\N	\N	2058	1	domain	2026-06-20 19:40:05.991895
31338	1306	\N	\N	2060	1	domain	2026-06-20 19:40:05.991895
31339	1306	\N	\N	2061	1	domain	2026-06-20 19:40:05.991895
31340	1306	\N	\N	2062	1	domain	2026-06-20 19:40:05.991895
31341	1306	\N	\N	2426	1	domain	2026-06-20 19:40:05.991895
31342	1306	\N	\N	2430	1	domain	2026-06-20 19:40:05.991895
31344	1306	\N	\N	1851	1	domain	2026-06-20 19:40:06.000593
31345	1306	\N	\N	194	1	domain	2026-06-20 19:40:06.000593
31346	1306	\N	\N	1300	1	domain	2026-06-20 19:40:06.000593
31347	1306	\N	\N	2431	1	domain	2026-06-20 19:40:06.000593
31349	1306	\N	\N	605	1	domain	2026-06-20 19:40:06.000593
31350	1306	\N	\N	1857	1	domain	2026-06-20 19:40:06.000593
31351	1306	\N	\N	2153	1	domain	2026-06-20 19:40:06.000593
31352	1306	\N	\N	2359	1	domain	2026-06-20 19:40:06.000593
31354	1306	\N	\N	1564	1	domain	2026-06-20 19:40:06.008243
31355	1306	\N	\N	1567	1	domain	2026-06-20 19:40:06.008243
31356	1306	\N	\N	613	1	domain	2026-06-20 19:40:06.008243
31357	1306	\N	\N	614	1	domain	2026-06-20 19:40:06.008243
31358	1306	\N	\N	615	1	domain	2026-06-20 19:40:06.008243
31359	1306	\N	\N	195	1	domain	2026-06-20 19:40:06.008243
31360	1306	\N	\N	988	1	domain	2026-06-20 19:40:06.008243
31361	1306	\N	\N	3226	1	domain	2026-06-20 19:40:06.008243
31362	1306	\N	\N	2840	1	domain	2026-06-20 19:40:06.008243
31363	1306	\N	\N	3227	1	domain	2026-06-20 19:40:06.008243
31364	1306	\N	\N	3163	1	domain	2026-06-20 19:40:06.008243
31365	1306	\N	\N	1659	1	domain	2026-06-20 19:40:06.008243
31366	1306	\N	\N	2943	1	domain	2026-06-20 19:40:06.008243
31367	1306	\N	\N	873	1	domain	2026-06-20 19:40:06.008243
31368	1306	\N	\N	874	1	domain	2026-06-20 19:40:06.008243
31369	1306	\N	\N	2181	1	domain	2026-06-20 19:40:06.008243
31370	1306	\N	\N	876	1	domain	2026-06-20 19:40:06.008243
31371	1306	\N	\N	527	1	domain	2026-06-20 19:40:06.008243
31372	1306	\N	\N	338	1	domain	2026-06-20 19:40:06.008243
31373	1306	\N	\N	339	1	domain	2026-06-20 19:40:06.008243
31374	1306	\N	\N	342	1	domain	2026-06-20 19:40:06.008243
31375	1306	\N	\N	157	1	domain	2026-06-20 19:40:06.008243
31376	1306	\N	\N	158	1	domain	2026-06-20 19:40:06.008243
31377	1306	\N	\N	2527	1	domain	2026-06-20 19:40:06.008243
31378	1306	\N	\N	2528	1	domain	2026-06-20 19:40:06.008243
31379	1306	\N	\N	2529	1	domain	2026-06-20 19:40:06.008243
31380	1306	\N	\N	2531	1	domain	2026-06-20 19:40:06.008243
31381	1306	\N	\N	2533	1	domain	2026-06-20 19:40:06.008243
31382	1306	\N	\N	2534	1	domain	2026-06-20 19:40:06.008243
31383	1306	\N	\N	2535	1	domain	2026-06-20 19:40:06.008243
31385	1306	\N	\N	1565	1	domain	2026-06-20 19:40:06.012374
31386	1306	\N	\N	1566	1	domain	2026-06-20 19:40:06.012374
31387	1306	\N	\N	2605	1	domain	2026-06-20 19:40:06.012374
31388	1306	\N	\N	193	1	domain	2026-06-20 19:40:06.012374
31389	1306	\N	\N	616	1	domain	2026-06-20 19:40:06.012374
31390	1306	\N	\N	529	1	domain	2026-06-20 19:40:06.012374
31392	1306	\N	\N	383	1	domain	2026-06-20 19:40:06.014381
31393	1306	\N	\N	1208	1	domain	2026-06-20 19:40:06.014381
31394	1306	\N	\N	2215	1	domain	2026-06-20 19:40:06.014381
31395	1306	\N	\N	2216	1	domain	2026-06-20 19:40:06.014381
31396	1306	\N	\N	2218	1	domain	2026-06-20 19:40:06.014381
31397	1306	\N	\N	2219	1	domain	2026-06-20 19:40:06.014381
31399	1306	\N	\N	3310	1	domain	2026-06-20 19:40:06.016722
31400	1306	\N	\N	1811	1	domain	2026-06-20 19:40:06.016722
31401	1306	\N	\N	1206	1	domain	2026-06-20 19:40:06.016722
31402	1306	\N	\N	1207	1	domain	2026-06-20 19:40:06.016722
31403	1306	\N	\N	2179	1	domain	2026-06-20 19:40:06.016722
31405	1306	\N	\N	747	1	domain	2026-06-20 19:40:06.0227
31406	1306	\N	\N	481	1	domain	2026-06-20 19:40:06.0227
31407	1306	\N	\N	482	1	domain	2026-06-20 19:40:06.0227
31408	1306	\N	\N	483	1	domain	2026-06-20 19:40:06.0227
31409	1306	\N	\N	484	1	domain	2026-06-20 19:40:06.0227
31410	1306	\N	\N	485	1	domain	2026-06-20 19:40:06.0227
31411	1306	\N	\N	1527	1	domain	2026-06-20 19:40:06.0227
31412	1306	\N	\N	486	1	domain	2026-06-20 19:40:06.0227
31413	1306	\N	\N	487	1	domain	2026-06-20 19:40:06.0227
31414	1306	\N	\N	558	1	domain	2026-06-20 19:40:06.0227
31415	1306	\N	\N	1528	1	domain	2026-06-20 19:40:06.0227
31417	1307	\N	\N	760	1	domain	2026-06-20 19:40:06.024434
31418	1307	\N	\N	2600	1	domain	2026-06-20 19:40:06.024434
31419	1307	\N	\N	1024	1	domain	2026-06-20 19:40:06.024434
31420	1307	\N	\N	121	1	domain	2026-06-20 19:40:06.024434
31421	1307	\N	\N	1268	1	domain	2026-06-20 19:40:06.024434
31422	1307	\N	\N	573	1	domain	2026-06-20 19:40:06.024434
31424	1307	\N	\N	2624	1	domain	2026-06-20 19:40:06.030515
31425	1307	\N	\N	2625	1	domain	2026-06-20 19:40:06.030515
31426	1307	\N	\N	2616	1	domain	2026-06-20 19:40:06.030515
31427	1307	\N	\N	2617	1	domain	2026-06-20 19:40:06.030515
31428	1307	\N	\N	2618	1	domain	2026-06-20 19:40:06.030515
31429	1307	\N	\N	2619	1	domain	2026-06-20 19:40:06.030515
31430	1307	\N	\N	2621	1	domain	2026-06-20 19:40:06.030515
31431	1307	\N	\N	597	1	domain	2026-06-20 19:40:06.030515
31432	1307	\N	\N	2622	1	domain	2026-06-20 19:40:06.030515
31433	1307	\N	\N	2623	1	domain	2026-06-20 19:40:06.030515
31434	1307	\N	\N	3120	1	domain	2026-06-20 19:40:06.030515
31435	1307	\N	\N	2941	1	domain	2026-06-20 19:40:06.030515
31436	1307	\N	\N	851	1	domain	2026-06-20 19:40:06.030515
31437	1307	\N	\N	852	1	domain	2026-06-20 19:40:06.030515
31438	1307	\N	\N	2289	1	domain	2026-06-20 19:40:06.030515
31439	1307	\N	\N	2532	1	domain	2026-06-20 19:40:06.030515
31441	1307	\N	\N	1842	1	domain	2026-06-20 19:40:06.034483
31442	1307	\N	\N	3377	1	domain	2026-06-20 19:40:06.034483
31443	1307	\N	\N	1868	1	domain	2026-06-20 19:40:06.034483
31444	1307	\N	\N	1869	1	domain	2026-06-20 19:40:06.034483
31445	1307	\N	\N	1870	1	domain	2026-06-20 19:40:06.034483
31446	1307	\N	\N	1603	1	domain	2026-06-20 19:40:06.034483
31447	1307	\N	\N	1871	1	domain	2026-06-20 19:40:06.034483
31448	1307	\N	\N	1872	1	domain	2026-06-20 19:40:06.034483
31449	1307	\N	\N	762	1	domain	2026-06-20 19:40:06.034483
31450	1307	\N	\N	1875	1	domain	2026-06-20 19:40:06.034483
31451	1307	\N	\N	1876	1	domain	2026-06-20 19:40:06.034483
31452	1307	\N	\N	3124	1	domain	2026-06-20 19:40:06.034483
31453	1307	\N	\N	3271	1	domain	2026-06-20 19:40:06.034483
31454	1307	\N	\N	189	1	domain	2026-06-20 19:40:06.034483
31455	1307	\N	\N	3392	1	domain	2026-06-20 19:40:06.034483
31456	1307	\N	\N	771	1	domain	2026-06-20 19:40:06.034483
31457	1307	\N	\N	3132	1	domain	2026-06-20 19:40:06.034483
31458	1307	\N	\N	3133	1	domain	2026-06-20 19:40:06.034483
31459	1307	\N	\N	1573	1	domain	2026-06-20 19:40:06.034483
31460	1307	\N	\N	1829	1	domain	2026-06-20 19:40:06.034483
31461	1307	\N	\N	227	1	domain	2026-06-20 19:40:06.034483
31462	1307	\N	\N	3134	1	domain	2026-06-20 19:40:06.034483
31463	1307	\N	\N	228	1	domain	2026-06-20 19:40:06.034483
31464	1307	\N	\N	2828	1	domain	2026-06-20 19:40:06.034483
31465	1307	\N	\N	3149	1	domain	2026-06-20 19:40:06.034483
31466	1307	\N	\N	2830	1	domain	2026-06-20 19:40:06.034483
31467	1307	\N	\N	448	1	domain	2026-06-20 19:40:06.034483
31468	1307	\N	\N	450	1	domain	2026-06-20 19:40:06.034483
31469	1307	\N	\N	3236	1	domain	2026-06-20 19:40:06.034483
31470	1307	\N	\N	3237	1	domain	2026-06-20 19:40:06.034483
31471	1307	\N	\N	1022	1	domain	2026-06-20 19:40:06.034483
31472	1307	\N	\N	1023	1	domain	2026-06-20 19:40:06.034483
31473	1307	\N	\N	2928	1	domain	2026-06-20 19:40:06.034483
31474	1307	\N	\N	2929	1	domain	2026-06-20 19:40:06.034483
31475	1307	\N	\N	288	1	domain	2026-06-20 19:40:06.034483
31476	1307	\N	\N	290	1	domain	2026-06-20 19:40:06.034483
31477	1307	\N	\N	840	1	domain	2026-06-20 19:40:06.034483
31478	1307	\N	\N	841	1	domain	2026-06-20 19:40:06.034483
31479	1307	\N	\N	293	1	domain	2026-06-20 19:40:06.034483
31480	1307	\N	\N	298	1	domain	2026-06-20 19:40:06.034483
31481	1307	\N	\N	299	1	domain	2026-06-20 19:40:06.034483
31482	1307	\N	\N	303	1	domain	2026-06-20 19:40:06.034483
31483	1307	\N	\N	119	1	domain	2026-06-20 19:40:06.034483
31484	1307	\N	\N	120	1	domain	2026-06-20 19:40:06.034483
31485	1307	\N	\N	1716	1	domain	2026-06-20 19:40:06.034483
31486	1307	\N	\N	2208	1	domain	2026-06-20 19:40:06.034483
31487	1307	\N	\N	2768	1	domain	2026-06-20 19:40:06.034483
31488	1307	\N	\N	1267	1	domain	2026-06-20 19:40:06.034483
31489	1307	\N	\N	1272	1	domain	2026-06-20 19:40:06.034483
31490	1307	\N	\N	2028	1	domain	2026-06-20 19:40:06.034483
31491	1307	\N	\N	2295	1	domain	2026-06-20 19:40:06.034483
31492	1307	\N	\N	2301	1	domain	2026-06-20 19:40:06.034483
31493	1307	\N	\N	2306	1	domain	2026-06-20 19:40:06.034483
31494	1307	\N	\N	2319	1	domain	2026-06-20 19:40:06.034483
31495	1307	\N	\N	2320	1	domain	2026-06-20 19:40:06.034483
31496	1307	\N	\N	2321	1	domain	2026-06-20 19:40:06.034483
31497	1307	\N	\N	2328	1	domain	2026-06-20 19:40:06.034483
31498	1307	\N	\N	2329	1	domain	2026-06-20 19:40:06.034483
31499	1307	\N	\N	2330	1	domain	2026-06-20 19:40:06.034483
31500	1307	\N	\N	2343	1	domain	2026-06-20 19:40:06.034483
31501	1307	\N	\N	2355	1	domain	2026-06-20 19:40:06.034483
31502	1307	\N	\N	2424	1	domain	2026-06-20 19:40:06.034483
31503	1307	\N	\N	2425	1	domain	2026-06-20 19:40:06.034483
31504	1307	\N	\N	2427	1	domain	2026-06-20 19:40:06.034483
31506	1307	\N	\N	1602	1	domain	2026-06-20 19:40:06.040845
31507	1307	\N	\N	2602	1	domain	2026-06-20 19:40:06.040845
31508	1307	\N	\N	3130	1	domain	2026-06-20 19:40:06.040845
31509	1307	\N	\N	1827	1	domain	2026-06-20 19:40:06.040845
31510	1307	\N	\N	987	1	domain	2026-06-20 19:40:06.040845
31511	1307	\N	\N	2931	1	domain	2026-06-20 19:40:06.040845
31512	1307	\N	\N	294	1	domain	2026-06-20 19:40:06.040845
31513	1307	\N	\N	1243	1	domain	2026-06-20 19:40:06.040845
31514	1307	\N	\N	2280	1	domain	2026-06-20 19:40:06.040845
31515	1307	\N	\N	2281	1	domain	2026-06-20 19:40:06.040845
31516	1307	\N	\N	2282	1	domain	2026-06-20 19:40:06.040845
31517	1307	\N	\N	2284	1	domain	2026-06-20 19:40:06.040845
31518	1307	\N	\N	2285	1	domain	2026-06-20 19:40:06.040845
31519	1307	\N	\N	2313	1	domain	2026-06-20 19:40:06.040845
31520	1307	\N	\N	2347	1	domain	2026-06-20 19:40:06.040845
31521	1307	\N	\N	2349	1	domain	2026-06-20 19:40:06.040845
31522	1307	\N	\N	2352	1	domain	2026-06-20 19:40:06.040845
31523	1307	\N	\N	2354	1	domain	2026-06-20 19:40:06.040845
31524	1307	\N	\N	2488	1	domain	2026-06-20 19:40:06.040845
31526	1307	\N	\N	761	1	domain	2026-06-20 19:40:06.044639
31527	1307	\N	\N	304	1	domain	2026-06-20 19:40:06.044639
31528	1307	\N	\N	2017	1	domain	2026-06-20 19:40:06.044639
31529	1307	\N	\N	1270	1	domain	2026-06-20 19:40:06.044639
31530	1307	\N	\N	2251	1	domain	2026-06-20 19:40:06.044639
31531	1307	\N	\N	2318	1	domain	2026-06-20 19:40:06.044639
31533	1307	\N	\N	2603	1	domain	2026-06-20 19:40:06.049038
31534	1307	\N	\N	3219	1	domain	2026-06-20 19:40:06.049038
31535	1307	\N	\N	274	1	domain	2026-06-20 19:40:06.049038
31536	1307	\N	\N	2416	1	domain	2026-06-20 19:40:06.049038
31537	1307	\N	\N	2422	1	domain	2026-06-20 19:40:06.049038
31539	1307	\N	\N	279	1	domain	2026-06-20 19:40:06.049038
31540	1307	\N	\N	2419	1	domain	2026-06-20 19:40:06.049038
31541	1307	\N	\N	2420	1	domain	2026-06-20 19:40:06.049038
31542	1307	\N	\N	1846	1	domain	2026-06-20 19:40:06.049038
31543	1307	\N	\N	1873	1	domain	2026-06-20 19:40:06.049038
31544	1307	\N	\N	697	1	domain	2026-06-20 19:40:06.049038
31545	1307	\N	\N	2596	1	domain	2026-06-20 19:40:06.049038
31546	1307	\N	\N	185	1	domain	2026-06-20 19:40:06.049038
31547	1307	\N	\N	3273	1	domain	2026-06-20 19:40:06.049038
31548	1307	\N	\N	3396	1	domain	2026-06-20 19:40:06.049038
31549	1307	\N	\N	1912	1	domain	2026-06-20 19:40:06.049038
31550	1307	\N	\N	1911	1	domain	2026-06-20 19:40:06.049038
31551	1307	\N	\N	1913	1	domain	2026-06-20 19:40:06.049038
31552	1307	\N	\N	1914	1	domain	2026-06-20 19:40:06.049038
31553	1307	\N	\N	1915	1	domain	2026-06-20 19:40:06.049038
31554	1307	\N	\N	1916	1	domain	2026-06-20 19:40:06.049038
31555	1307	\N	\N	1917	1	domain	2026-06-20 19:40:06.049038
31556	1307	\N	\N	1918	1	domain	2026-06-20 19:40:06.049038
31557	1307	\N	\N	1920	1	domain	2026-06-20 19:40:06.049038
31558	1307	\N	\N	1921	1	domain	2026-06-20 19:40:06.049038
31559	1307	\N	\N	1009	1	domain	2026-06-20 19:40:06.049038
31560	1307	\N	\N	2690	1	domain	2026-06-20 19:40:06.049038
31561	1307	\N	\N	275	1	domain	2026-06-20 19:40:06.049038
31562	1307	\N	\N	276	1	domain	2026-06-20 19:40:06.049038
31563	1307	\N	\N	277	1	domain	2026-06-20 19:40:06.049038
31564	1307	\N	\N	281	1	domain	2026-06-20 19:40:06.049038
31565	1307	\N	\N	282	1	domain	2026-06-20 19:40:06.049038
31566	1307	\N	\N	837	1	domain	2026-06-20 19:40:06.049038
31567	1307	\N	\N	838	1	domain	2026-06-20 19:40:06.049038
31568	1307	\N	\N	92	1	domain	2026-06-20 19:40:06.049038
31569	1307	\N	\N	93	1	domain	2026-06-20 19:40:06.049038
31570	1307	\N	\N	297	1	domain	2026-06-20 19:40:06.049038
31571	1307	\N	\N	495	1	domain	2026-06-20 19:40:06.049038
31572	1307	\N	\N	302	1	domain	2026-06-20 19:40:06.049038
31573	1307	\N	\N	1726	1	domain	2026-06-20 19:40:06.049038
31574	1307	\N	\N	1269	1	domain	2026-06-20 19:40:06.049038
31575	1307	\N	\N	1277	1	domain	2026-06-20 19:40:06.049038
31576	1307	\N	\N	1278	1	domain	2026-06-20 19:40:06.049038
31577	1307	\N	\N	1320	1	domain	2026-06-20 19:40:06.049038
31578	1307	\N	\N	2283	1	domain	2026-06-20 19:40:06.049038
31579	1307	\N	\N	2296	1	domain	2026-06-20 19:40:06.049038
31580	1307	\N	\N	2327	1	domain	2026-06-20 19:40:06.049038
31581	1307	\N	\N	2332	1	domain	2026-06-20 19:40:06.049038
31582	1307	\N	\N	2336	1	domain	2026-06-20 19:40:06.049038
31583	1307	\N	\N	2421	1	domain	2026-06-20 19:40:06.049038
31585	1307	\N	\N	2829	1	domain	2026-06-20 19:40:06.05772
31586	1307	\N	\N	1274	1	domain	2026-06-20 19:40:06.05772
31588	1307	\N	\N	76	1	domain	2026-06-20 19:40:06.05772
31589	1307	\N	\N	122	1	domain	2026-06-20 19:40:06.05772
31590	1307	\N	\N	2337	1	domain	2026-06-20 19:40:06.05772
31591	1307	\N	\N	2338	1	domain	2026-06-20 19:40:06.05772
31592	1307	\N	\N	2339	1	domain	2026-06-20 19:40:06.05772
31593	1307	\N	\N	2342	1	domain	2026-06-20 19:40:06.05772
31595	1307	\N	\N	1845	1	domain	2026-06-20 19:40:06.05772
31596	1307	\N	\N	3148	1	domain	2026-06-20 19:40:06.05772
31598	1308	\N	\N	198	1	domain	2026-06-20 19:40:06.066717
31599	1308	\N	\N	1577	1	domain	2026-06-20 19:40:06.066717
31600	1308	\N	\N	200	1	domain	2026-06-20 19:40:06.066717
31601	1308	\N	\N	1862	1	domain	2026-06-20 19:40:06.066717
31602	1308	\N	\N	201	1	domain	2026-06-20 19:40:06.066717
31603	1308	\N	\N	1863	1	domain	2026-06-20 19:40:06.066717
31604	1308	\N	\N	202	1	domain	2026-06-20 19:40:06.066717
31605	1308	\N	\N	203	1	domain	2026-06-20 19:40:06.066717
31606	1308	\N	\N	3185	1	domain	2026-06-20 19:40:06.066717
31607	1308	\N	\N	171	1	domain	2026-06-20 19:40:06.066717
31608	1308	\N	\N	952	1	domain	2026-06-20 19:40:06.066717
31609	1308	\N	\N	206	1	domain	2026-06-20 19:40:06.066717
31610	1308	\N	\N	2583	1	domain	2026-06-20 19:40:06.066717
31611	1308	\N	\N	15	1	domain	2026-06-20 19:40:06.066717
31612	1308	\N	\N	25	1	domain	2026-06-20 19:40:06.066717
31613	1308	\N	\N	1812	1	domain	2026-06-20 19:40:06.066717
31614	1308	\N	\N	1813	1	domain	2026-06-20 19:40:06.066717
31615	1308	\N	\N	236	1	domain	2026-06-20 19:40:06.066717
31616	1308	\N	\N	1118	1	domain	2026-06-20 19:40:06.066717
31617	1308	\N	\N	1636	1	domain	2026-06-20 19:40:06.066717
31618	1308	\N	\N	1119	1	domain	2026-06-20 19:40:06.066717
31619	1308	\N	\N	810	1	domain	2026-06-20 19:40:06.066717
31620	1308	\N	\N	1929	1	domain	2026-06-20 19:40:06.066717
31621	1308	\N	\N	72	1	domain	2026-06-20 19:40:06.066717
31622	1308	\N	\N	2128	1	domain	2026-06-20 19:40:06.066717
31623	1308	\N	\N	2129	1	domain	2026-06-20 19:40:06.066717
31624	1308	\N	\N	2918	1	domain	2026-06-20 19:40:06.066717
31625	1308	\N	\N	1540	1	domain	2026-06-20 19:40:06.066717
31626	1308	\N	\N	316	1	domain	2026-06-20 19:40:06.066717
31627	1308	\N	\N	2959	1	domain	2026-06-20 19:40:06.066717
31628	1308	\N	\N	1993	1	domain	2026-06-20 19:40:06.066717
31629	1308	\N	\N	2225	1	domain	2026-06-20 19:40:06.066717
31630	1308	\N	\N	2228	1	domain	2026-06-20 19:40:06.066717
31631	1308	\N	\N	1285	1	domain	2026-06-20 19:40:06.066717
31632	1308	\N	\N	2042	1	domain	2026-06-20 19:40:06.066717
31633	1308	\N	\N	2300	1	domain	2026-06-20 19:40:06.066717
31634	1308	\N	\N	2340	1	domain	2026-06-20 19:40:06.066717
31636	1308	\N	\N	1839	1	domain	2026-06-20 19:40:06.066717
31637	1308	\N	\N	824	1	domain	2026-06-20 19:40:06.066717
31638	1308	\N	\N	1001	1	domain	2026-06-20 19:40:06.066717
31640	1308	\N	\N	594	1	domain	2026-06-20 19:40:06.073828
31641	1308	\N	\N	954	1	domain	2026-06-20 19:40:06.073828
31642	1308	\N	\N	13	1	domain	2026-06-20 19:40:06.073828
31643	1308	\N	\N	14	1	domain	2026-06-20 19:40:06.073828
31644	1308	\N	\N	16	1	domain	2026-06-20 19:40:06.073828
31645	1308	\N	\N	21	1	domain	2026-06-20 19:40:06.073828
31646	1308	\N	\N	378	1	domain	2026-06-20 19:40:06.073828
31647	1308	\N	\N	229	1	domain	2026-06-20 19:40:06.073828
31648	1308	\N	\N	35	1	domain	2026-06-20 19:40:06.073828
31649	1308	\N	\N	781	1	domain	2026-06-20 19:40:06.073828
31650	1308	\N	\N	3146	1	domain	2026-06-20 19:40:06.073828
31651	1308	\N	\N	997	1	domain	2026-06-20 19:40:06.073828
31652	1308	\N	\N	998	1	domain	2026-06-20 19:40:06.073828
31653	1308	\N	\N	811	1	domain	2026-06-20 19:40:06.073828
31654	1308	\N	\N	2908	1	domain	2026-06-20 19:40:06.073828
31655	1308	\N	\N	2960	1	domain	2026-06-20 19:40:06.073828
31656	1308	\N	\N	2357	1	domain	2026-06-20 19:40:06.073828
31658	1308	\N	\N	211	1	domain	2026-06-20 19:40:06.073828
31659	1308	\N	\N	1523	1	domain	2026-06-20 19:40:06.073828
31660	1308	\N	\N	1385	1	domain	2026-06-20 19:40:06.073828
31661	1308	\N	\N	1517	1	domain	2026-06-20 19:40:06.073828
31662	1308	\N	\N	1372	1	domain	2026-06-20 19:40:06.073828
31664	1308	\N	\N	373	1	domain	2026-06-20 19:40:06.073828
31665	1308	\N	\N	3203	1	domain	2026-06-20 19:40:06.073828
31666	1308	\N	\N	3282	1	domain	2026-06-20 19:40:06.073828
31667	1308	\N	\N	1008	1	domain	2026-06-20 19:40:06.073828
31668	1308	\N	\N	835	1	domain	2026-06-20 19:40:06.073828
31669	1308	\N	\N	90	1	domain	2026-06-20 19:40:06.073828
31670	1308	\N	\N	1211	1	domain	2026-06-20 19:40:06.073828
31671	1308	\N	\N	1213	1	domain	2026-06-20 19:40:06.073828
31672	1308	\N	\N	1707	1	domain	2026-06-20 19:40:06.073828
31673	1308	\N	\N	2974	1	domain	2026-06-20 19:40:06.073828
31674	1308	\N	\N	2975	1	domain	2026-06-20 19:40:06.073828
31675	1308	\N	\N	2976	1	domain	2026-06-20 19:40:06.073828
31676	1308	\N	\N	2209	1	domain	2026-06-20 19:40:06.073828
31677	1308	\N	\N	2211	1	domain	2026-06-20 19:40:06.073828
31678	1308	\N	\N	2470	1	domain	2026-06-20 19:40:06.073828
31679	1308	\N	\N	2472	1	domain	2026-06-20 19:40:06.073828
31680	1308	\N	\N	2549	1	domain	2026-06-20 19:40:06.073828
31682	1308	\N	\N	1138	1	domain	2026-06-20 19:40:06.082566
31683	1308	\N	\N	1056	1	domain	2026-06-20 19:40:06.082566
31684	1308	\N	\N	980	1	domain	2026-06-20 19:40:06.082566
31685	1308	\N	\N	828	1	domain	2026-06-20 19:40:06.082566
31686	1308	\N	\N	3013	1	domain	2026-06-20 19:40:06.082566
31687	1308	\N	\N	3014	1	domain	2026-06-20 19:40:06.082566
31688	1308	\N	\N	3015	1	domain	2026-06-20 19:40:06.082566
31689	1308	\N	\N	3016	1	domain	2026-06-20 19:40:06.082566
31690	1308	\N	\N	3019	1	domain	2026-06-20 19:40:06.082566
31692	1308	\N	\N	99	1	domain	2026-06-20 19:40:06.090323
31693	1308	\N	\N	859	1	domain	2026-06-20 19:40:06.090323
31695	1309	\N	\N	1163	1	domain	2026-06-20 19:40:06.090323
31696	1309	\N	\N	3343	1	domain	2026-06-20 19:40:06.090323
31697	1309	\N	\N	1925	1	domain	2026-06-20 19:40:06.090323
31698	1309	\N	\N	1164	1	domain	2026-06-20 19:40:06.090323
31699	1309	\N	\N	1167	1	domain	2026-06-20 19:40:06.090323
31700	1309	\N	\N	1170	1	domain	2026-06-20 19:40:06.090323
31701	1309	\N	\N	1171	1	domain	2026-06-20 19:40:06.090323
31702	1309	\N	\N	1027	1	domain	2026-06-20 19:40:06.090323
31703	1309	\N	\N	1030	1	domain	2026-06-20 19:40:06.090323
31704	1309	\N	\N	331	1	domain	2026-06-20 19:40:06.090323
31705	1309	\N	\N	332	1	domain	2026-06-20 19:40:06.090323
31706	1309	\N	\N	2749	1	domain	2026-06-20 19:40:06.090323
31707	1309	\N	\N	2409	1	domain	2026-06-20 19:40:06.090323
31708	1309	\N	\N	2446	1	domain	2026-06-20 19:40:06.090323
31710	1309	\N	\N	1179	1	domain	2026-06-20 19:40:06.098753
31711	1309	\N	\N	1180	1	domain	2026-06-20 19:40:06.098753
31712	1309	\N	\N	1181	1	domain	2026-06-20 19:40:06.098753
31713	1309	\N	\N	2691	1	domain	2026-06-20 19:40:06.098753
31714	1309	\N	\N	1174	1	domain	2026-06-20 19:40:06.098753
31715	1309	\N	\N	1175	1	domain	2026-06-20 19:40:06.098753
31716	1309	\N	\N	1176	1	domain	2026-06-20 19:40:06.098753
31717	1309	\N	\N	1177	1	domain	2026-06-20 19:40:06.098753
31719	1309	\N	\N	2615	1	domain	2026-06-20 19:40:06.099104
31720	1309	\N	\N	207	1	domain	2026-06-20 19:40:06.099104
31721	1309	\N	\N	3381	1	domain	2026-06-20 19:40:06.099104
31722	1309	\N	\N	3390	1	domain	2026-06-20 19:40:06.099104
31723	1309	\N	\N	624	1	domain	2026-06-20 19:40:06.099104
31724	1309	\N	\N	3152	1	domain	2026-06-20 19:40:06.099104
31725	1309	\N	\N	2832	1	domain	2026-06-20 19:40:06.099104
31726	1309	\N	\N	2833	1	domain	2026-06-20 19:40:06.099104
31727	1309	\N	\N	2834	1	domain	2026-06-20 19:40:06.099104
31728	1309	\N	\N	1924	1	domain	2026-06-20 19:40:06.099104
31729	1309	\N	\N	1926	1	domain	2026-06-20 19:40:06.099104
31730	1309	\N	\N	3238	1	domain	2026-06-20 19:40:06.099104
31731	1309	\N	\N	1933	1	domain	2026-06-20 19:40:06.099104
31732	1309	\N	\N	1927	1	domain	2026-06-20 19:40:06.099104
31733	1309	\N	\N	1165	1	domain	2026-06-20 19:40:06.099104
31734	1309	\N	\N	1931	1	domain	2026-06-20 19:40:06.099104
31735	1309	\N	\N	1932	1	domain	2026-06-20 19:40:06.099104
31736	1309	\N	\N	1168	1	domain	2026-06-20 19:40:06.099104
31737	1309	\N	\N	1169	1	domain	2026-06-20 19:40:06.099104
31738	1309	\N	\N	1028	1	domain	2026-06-20 19:40:06.099104
31739	1309	\N	\N	1184	1	domain	2026-06-20 19:40:06.099104
31740	1309	\N	\N	1031	1	domain	2026-06-20 19:40:06.099104
31741	1309	\N	\N	91	1	domain	2026-06-20 19:40:06.099104
31742	1309	\N	\N	305	1	domain	2026-06-20 19:40:06.099104
31743	1309	\N	\N	1712	1	domain	2026-06-20 19:40:06.099104
31744	1309	\N	\N	323	1	domain	2026-06-20 19:40:06.099104
31745	1309	\N	\N	328	1	domain	2026-06-20 19:40:06.099104
31746	1309	\N	\N	329	1	domain	2026-06-20 19:40:06.099104
31747	1309	\N	\N	333	1	domain	2026-06-20 19:40:06.099104
31748	1309	\N	\N	334	1	domain	2026-06-20 19:40:06.099104
31749	1309	\N	\N	335	1	domain	2026-06-20 19:40:06.099104
31750	1309	\N	\N	336	1	domain	2026-06-20 19:40:06.099104
31751	1309	\N	\N	346	1	domain	2026-06-20 19:40:06.099104
31752	1309	\N	\N	347	1	domain	2026-06-20 19:40:06.099104
31753	1309	\N	\N	348	1	domain	2026-06-20 19:40:06.099104
31754	1309	\N	\N	2765	1	domain	2026-06-20 19:40:06.099104
31755	1309	\N	\N	349	1	domain	2026-06-20 19:40:06.099104
31756	1309	\N	\N	350	1	domain	2026-06-20 19:40:06.099104
31757	1309	\N	\N	2015	1	domain	2026-06-20 19:40:06.099104
31758	1309	\N	\N	2025	1	domain	2026-06-20 19:40:06.099104
31759	1309	\N	\N	2026	1	domain	2026-06-20 19:40:06.099104
31760	1309	\N	\N	2027	1	domain	2026-06-20 19:40:06.099104
31761	1309	\N	\N	1280	1	domain	2026-06-20 19:40:06.099104
31762	1309	\N	\N	1304	1	domain	2026-06-20 19:40:06.099104
31763	1309	\N	\N	1305	1	domain	2026-06-20 19:40:06.099104
31764	1309	\N	\N	1306	1	domain	2026-06-20 19:40:06.099104
31765	1309	\N	\N	1307	1	domain	2026-06-20 19:40:06.099104
31766	1309	\N	\N	1317	1	domain	2026-06-20 19:40:06.099104
31767	1309	\N	\N	1319	1	domain	2026-06-20 19:40:06.099104
31768	1309	\N	\N	3090	1	domain	2026-06-20 19:40:06.099104
31769	1309	\N	\N	2406	1	domain	2026-06-20 19:40:06.099104
31770	1309	\N	\N	2407	1	domain	2026-06-20 19:40:06.099104
31771	1309	\N	\N	2449	1	domain	2026-06-20 19:40:06.099104
31772	1309	\N	\N	2452	1	domain	2026-06-20 19:40:06.099104
31773	1309	\N	\N	2542	1	domain	2026-06-20 19:40:06.099104
31774	1309	\N	\N	2548	1	domain	2026-06-20 19:40:06.099104
31775	1309	\N	\N	2575	1	domain	2026-06-20 19:40:06.099104
31776	1309	\N	\N	2576	1	domain	2026-06-20 19:40:06.099104
31778	1309	\N	\N	772	1	domain	2026-06-20 19:40:06.10706
31779	1309	\N	\N	1318	1	domain	2026-06-20 19:40:06.10706
31780	1309	\N	\N	1321	1	domain	2026-06-20 19:40:06.10706
31781	1309	\N	\N	2398	1	domain	2026-06-20 19:40:06.10706
31782	1309	\N	\N	2550	1	domain	2026-06-20 19:40:06.10706
31784	1309	\N	\N	3342	1	domain	2026-06-20 19:40:06.10706
31785	1309	\N	\N	1152	1	domain	2026-06-20 19:40:06.10706
31786	1309	\N	\N	1154	1	domain	2026-06-20 19:40:06.10706
31787	1309	\N	\N	1029	1	domain	2026-06-20 19:40:06.10706
31788	1309	\N	\N	289	1	domain	2026-06-20 19:40:06.10706
31789	1309	\N	\N	291	1	domain	2026-06-20 19:40:06.10706
31790	1309	\N	\N	1212	1	domain	2026-06-20 19:40:06.10706
31791	1309	\N	\N	1464	1	domain	2026-06-20 19:40:06.10706
31792	1309	\N	\N	2299	1	domain	2026-06-20 19:40:06.10706
31794	1309	\N	\N	623	1	domain	2026-06-20 19:40:06.115398
31795	1309	\N	\N	1155	1	domain	2026-06-20 19:40:06.115398
31796	1309	\N	\N	1158	1	domain	2026-06-20 19:40:06.115398
31797	1309	\N	\N	2021	1	domain	2026-06-20 19:40:06.115398
31799	1309	\N	\N	1148	1	domain	2026-06-20 19:40:06.115398
31800	1309	\N	\N	1149	1	domain	2026-06-20 19:40:06.115398
31801	1309	\N	\N	1150	1	domain	2026-06-20 19:40:06.115398
31802	1309	\N	\N	3231	1	domain	2026-06-20 19:40:06.115398
31803	1309	\N	\N	860	1	domain	2026-06-20 19:40:06.115398
31804	1309	\N	\N	1710	1	domain	2026-06-20 19:40:06.115398
31805	1309	\N	\N	130	1	domain	2026-06-20 19:40:06.115398
31806	1309	\N	\N	2451	1	domain	2026-06-20 19:40:06.115398
31808	1310	\N	\N	2307	1	domain	2026-06-20 19:40:06.123597
31809	1310	\N	\N	685	1	domain	2026-06-20 19:40:06.123597
31810	1310	\N	\N	2198	1	domain	2026-06-20 19:40:06.123597
31811	1310	\N	\N	1840	1	domain	2026-06-20 19:40:06.123597
31812	1310	\N	\N	1611	1	domain	2026-06-20 19:40:06.123597
31813	1310	\N	\N	1612	1	domain	2026-06-20 19:40:06.123597
31814	1310	\N	\N	3386	1	domain	2026-06-20 19:40:06.123597
31815	1310	\N	\N	2599	1	domain	2026-06-20 19:40:06.123597
31816	1310	\N	\N	188	1	domain	2026-06-20 19:40:06.123597
31817	1310	\N	\N	2808	1	domain	2026-06-20 19:40:06.123597
31818	1310	\N	\N	223	1	domain	2026-06-20 19:40:06.123597
31819	1310	\N	\N	1613	1	domain	2026-06-20 19:40:06.123597
31820	1310	\N	\N	1614	1	domain	2026-06-20 19:40:06.123597
31821	1310	\N	\N	1615	1	domain	2026-06-20 19:40:06.123597
31822	1310	\N	\N	1616	1	domain	2026-06-20 19:40:06.123597
31823	1310	\N	\N	1617	1	domain	2026-06-20 19:40:06.123597
31824	1310	\N	\N	1618	1	domain	2026-06-20 19:40:06.123597
31825	1310	\N	\N	2611	1	domain	2026-06-20 19:40:06.123597
31826	1310	\N	\N	1620	1	domain	2026-06-20 19:40:06.123597
31827	1310	\N	\N	1621	1	domain	2026-06-20 19:40:06.123597
31828	1310	\N	\N	3360	1	domain	2026-06-20 19:40:06.123597
31829	1310	\N	\N	728	1	domain	2026-06-20 19:40:06.123597
31830	1310	\N	\N	3154	1	domain	2026-06-20 19:40:06.123597
31831	1310	\N	\N	2106	1	domain	2026-06-20 19:40:06.123597
31832	1310	\N	\N	2108	1	domain	2026-06-20 19:40:06.123597
31833	1310	\N	\N	3308	1	domain	2026-06-20 19:40:06.123597
31834	1310	\N	\N	257	1	domain	2026-06-20 19:40:06.123597
31835	1310	\N	\N	2113	1	domain	2026-06-20 19:40:06.123597
31836	1310	\N	\N	1919	1	domain	2026-06-20 19:40:06.123597
31837	1310	\N	\N	258	1	domain	2026-06-20 19:40:06.123597
31838	1310	\N	\N	2114	1	domain	2026-06-20 19:40:06.123597
31839	1310	\N	\N	808	1	domain	2026-06-20 19:40:06.123597
31840	1310	\N	\N	259	1	domain	2026-06-20 19:40:06.123597
31841	1310	\N	\N	261	1	domain	2026-06-20 19:40:06.123597
31842	1310	\N	\N	3234	1	domain	2026-06-20 19:40:06.123597
31843	1310	\N	\N	2117	1	domain	2026-06-20 19:40:06.123597
31844	1310	\N	\N	262	1	domain	2026-06-20 19:40:06.123597
31845	1310	\N	\N	263	1	domain	2026-06-20 19:40:06.123597
31846	1310	\N	\N	457	1	domain	2026-06-20 19:40:06.123597
31847	1310	\N	\N	264	1	domain	2026-06-20 19:40:06.123597
31848	1310	\N	\N	265	1	domain	2026-06-20 19:40:06.123597
31849	1310	\N	\N	266	1	domain	2026-06-20 19:40:06.123597
31850	1310	\N	\N	267	1	domain	2026-06-20 19:40:06.123597
31851	1310	\N	\N	268	1	domain	2026-06-20 19:40:06.123597
31852	1310	\N	\N	1017	1	domain	2026-06-20 19:40:06.123597
31853	1310	\N	\N	475	1	domain	2026-06-20 19:40:06.123597
31854	1310	\N	\N	2927	1	domain	2026-06-20 19:40:06.123597
31855	1310	\N	\N	1036	1	domain	2026-06-20 19:40:06.123597
31856	1310	\N	\N	97	1	domain	2026-06-20 19:40:06.123597
31857	1310	\N	\N	98	1	domain	2026-06-20 19:40:06.123597
31858	1310	\N	\N	301	1	domain	2026-06-20 19:40:06.123597
31859	1310	\N	\N	854	1	domain	2026-06-20 19:40:06.123597
31860	1310	\N	\N	856	1	domain	2026-06-20 19:40:06.123597
31861	1310	\N	\N	857	1	domain	2026-06-20 19:40:06.123597
31862	1310	\N	\N	858	1	domain	2026-06-20 19:40:06.123597
31863	1310	\N	\N	519	1	domain	2026-06-20 19:40:06.123597
31864	1310	\N	\N	1999	1	domain	2026-06-20 19:40:06.123597
31865	1310	\N	\N	2000	1	domain	2026-06-20 19:40:06.123597
31866	1310	\N	\N	2001	1	domain	2026-06-20 19:40:06.123597
31867	1310	\N	\N	2196	1	domain	2026-06-20 19:40:06.123597
31868	1310	\N	\N	2002	1	domain	2026-06-20 19:40:06.123597
31869	1310	\N	\N	2199	1	domain	2026-06-20 19:40:06.123597
31870	1310	\N	\N	2004	1	domain	2026-06-20 19:40:06.123597
31871	1310	\N	\N	2202	1	domain	2026-06-20 19:40:06.123597
31872	1310	\N	\N	2005	1	domain	2026-06-20 19:40:06.123597
31873	1310	\N	\N	2006	1	domain	2026-06-20 19:40:06.123597
31874	1310	\N	\N	2007	1	domain	2026-06-20 19:40:06.123597
31875	1310	\N	\N	2008	1	domain	2026-06-20 19:40:06.123597
31876	1310	\N	\N	571	1	domain	2026-06-20 19:40:06.123597
31877	1310	\N	\N	574	1	domain	2026-06-20 19:40:06.123597
31878	1310	\N	\N	3025	1	domain	2026-06-20 19:40:06.123597
31879	1310	\N	\N	1294	1	domain	2026-06-20 19:40:06.123597
31880	1310	\N	\N	2248	1	domain	2026-06-20 19:40:06.123597
31881	1310	\N	\N	584	1	domain	2026-06-20 19:40:06.123597
31882	1310	\N	\N	2258	1	domain	2026-06-20 19:40:06.123597
31883	1310	\N	\N	2270	1	domain	2026-06-20 19:40:06.123597
31884	1310	\N	\N	2275	1	domain	2026-06-20 19:40:06.123597
31885	1310	\N	\N	1339	1	domain	2026-06-20 19:40:06.123597
31886	1310	\N	\N	1340	1	domain	2026-06-20 19:40:06.123597
31887	1310	\N	\N	1341	1	domain	2026-06-20 19:40:06.123597
31888	1310	\N	\N	3081	1	domain	2026-06-20 19:40:06.123597
31889	1310	\N	\N	3083	1	domain	2026-06-20 19:40:06.123597
31890	1310	\N	\N	2302	1	domain	2026-06-20 19:40:06.123597
31891	1310	\N	\N	3091	1	domain	2026-06-20 19:40:06.123597
31892	1310	\N	\N	2308	1	domain	2026-06-20 19:40:06.123597
31893	1310	\N	\N	2369	1	domain	2026-06-20 19:40:06.123597
31894	1310	\N	\N	2374	1	domain	2026-06-20 19:40:06.123597
31895	1310	\N	\N	2394	1	domain	2026-06-20 19:40:06.123597
31897	1310	\N	\N	1548	1	domain	2026-06-20 19:40:06.131669
31898	1310	\N	\N	3387	1	domain	2026-06-20 19:40:06.131669
31899	1310	\N	\N	612	1	domain	2026-06-20 19:40:06.131669
31900	1310	\N	\N	2013	1	domain	2026-06-20 19:40:06.131669
31902	1310	\N	\N	2626	1	domain	2026-06-20 19:40:06.131669
31903	1310	\N	\N	1744	1	domain	2026-06-20 19:40:06.131669
31904	1310	\N	\N	1843	1	domain	2026-06-20 19:40:06.131669
31905	1310	\N	\N	1844	1	domain	2026-06-20 19:40:06.131669
31906	1310	\N	\N	1847	1	domain	2026-06-20 19:40:06.131669
31907	1310	\N	\N	599	1	domain	2026-06-20 19:40:06.131669
31908	1310	\N	\N	600	1	domain	2026-06-20 19:40:06.131669
31909	1310	\N	\N	3336	1	domain	2026-06-20 19:40:06.131669
31910	1310	\N	\N	1409	1	domain	2026-06-20 19:40:06.131669
31911	1310	\N	\N	3274	1	domain	2026-06-20 19:40:06.131669
31912	1310	\N	\N	3275	1	domain	2026-06-20 19:40:06.131669
31913	1310	\N	\N	1575	1	domain	2026-06-20 19:40:06.131669
31914	1310	\N	\N	2646	1	domain	2026-06-20 19:40:06.131669
31915	1310	\N	\N	2648	1	domain	2026-06-20 19:40:06.131669
31916	1310	\N	\N	2649	1	domain	2026-06-20 19:40:06.131669
31917	1310	\N	\N	1627	1	domain	2026-06-20 19:40:06.131669
31918	1310	\N	\N	3147	1	domain	2026-06-20 19:40:06.131669
31919	1310	\N	\N	2210	1	domain	2026-06-20 19:40:06.131669
31920	1310	\N	\N	2670	1	domain	2026-06-20 19:40:06.131669
31921	1310	\N	\N	2671	1	domain	2026-06-20 19:40:06.131669
31922	1310	\N	\N	3235	1	domain	2026-06-20 19:40:06.131669
31923	1310	\N	\N	1018	1	domain	2026-06-20 19:40:06.131669
31924	1310	\N	\N	2698	1	domain	2026-06-20 19:40:06.131669
31925	1310	\N	\N	2701	1	domain	2026-06-20 19:40:06.131669
31926	1310	\N	\N	96	1	domain	2026-06-20 19:40:06.131669
31927	1310	\N	\N	2938	1	domain	2026-06-20 19:40:06.131669
31928	1310	\N	\N	296	1	domain	2026-06-20 19:40:06.131669
31929	1310	\N	\N	2713	1	domain	2026-06-20 19:40:06.131669
31930	1310	\N	\N	1204	1	domain	2026-06-20 19:40:06.131669
31931	1310	\N	\N	855	1	domain	2026-06-20 19:40:06.131669
31932	1310	\N	\N	306	1	domain	2026-06-20 19:40:06.131669
31933	1310	\N	\N	2956	1	domain	2026-06-20 19:40:06.131669
31934	1310	\N	\N	2732	1	domain	2026-06-20 19:40:06.131669
31935	1310	\N	\N	2736	1	domain	2026-06-20 19:40:06.131669
31936	1310	\N	\N	2744	1	domain	2026-06-20 19:40:06.131669
31937	1310	\N	\N	1727	1	domain	2026-06-20 19:40:06.131669
31938	1310	\N	\N	2193	1	domain	2026-06-20 19:40:06.131669
31939	1310	\N	\N	2194	1	domain	2026-06-20 19:40:06.131669
31940	1310	\N	\N	2195	1	domain	2026-06-20 19:40:06.131669
31941	1310	\N	\N	2201	1	domain	2026-06-20 19:40:06.131669
31942	1310	\N	\N	2205	1	domain	2026-06-20 19:40:06.131669
31943	1310	\N	\N	2770	1	domain	2026-06-20 19:40:06.131669
31944	1310	\N	\N	2771	1	domain	2026-06-20 19:40:06.131669
31945	1310	\N	\N	2213	1	domain	2026-06-20 19:40:06.131669
31946	1310	\N	\N	2773	1	domain	2026-06-20 19:40:06.131669
31947	1310	\N	\N	2774	1	domain	2026-06-20 19:40:06.131669
31948	1310	\N	\N	2331	1	domain	2026-06-20 19:40:06.131669
31949	1310	\N	\N	2363	1	domain	2026-06-20 19:40:06.131669
31950	1310	\N	\N	2387	1	domain	2026-06-20 19:40:06.131669
31951	1310	\N	\N	2423	1	domain	2026-06-20 19:40:06.131669
31952	1310	\N	\N	2428	1	domain	2026-06-20 19:40:06.131669
31953	1310	\N	\N	2429	1	domain	2026-06-20 19:40:06.131669
31954	1310	\N	\N	2438	1	domain	2026-06-20 19:40:06.131669
31955	1310	\N	\N	2487	1	domain	2026-06-20 19:40:06.131669
31956	1310	\N	\N	2492	1	domain	2026-06-20 19:40:06.131669
31957	1310	\N	\N	2506	1	domain	2026-06-20 19:40:06.131669
31958	1310	\N	\N	2547	1	domain	2026-06-20 19:40:06.131669
31960	1310	\N	\N	3109	1	domain	2026-06-20 19:40:06.140205
31961	1310	\N	\N	3380	1	domain	2026-06-20 19:40:06.140205
31962	1310	\N	\N	1333	1	domain	2026-06-20 19:40:06.140205
31963	1310	\N	\N	1334	1	domain	2026-06-20 19:40:06.140205
31964	1310	\N	\N	1335	1	domain	2026-06-20 19:40:06.140205
31965	1310	\N	\N	1338	1	domain	2026-06-20 19:40:06.140205
31966	1310	\N	\N	2511	1	domain	2026-06-20 19:40:06.140205
31967	1310	\N	\N	2512	1	domain	2026-06-20 19:40:06.140205
31968	1310	\N	\N	2513	1	domain	2026-06-20 19:40:06.140205
31969	1310	\N	\N	2514	1	domain	2026-06-20 19:40:06.140205
31970	1310	\N	\N	2515	1	domain	2026-06-20 19:40:06.140205
31971	1310	\N	\N	2516	1	domain	2026-06-20 19:40:06.140205
31972	1310	\N	\N	2517	1	domain	2026-06-20 19:40:06.140205
31973	1310	\N	\N	2518	1	domain	2026-06-20 19:40:06.140205
31974	1310	\N	\N	2519	1	domain	2026-06-20 19:40:06.140205
31975	1310	\N	\N	2563	1	domain	2026-06-20 19:40:06.140205
31976	1310	\N	\N	2564	1	domain	2026-06-20 19:40:06.140205
31977	1310	\N	\N	2565	1	domain	2026-06-20 19:40:06.140205
31978	1310	\N	\N	2566	1	domain	2026-06-20 19:40:06.140205
31980	1310	\N	\N	960	1	domain	2026-06-20 19:40:06.148306
31981	1310	\N	\N	3385	1	domain	2026-06-20 19:40:06.148306
31982	1310	\N	\N	764	1	domain	2026-06-20 19:40:06.148306
31983	1310	\N	\N	3121	1	domain	2026-06-20 19:40:06.148306
31984	1310	\N	\N	1561	1	domain	2026-06-20 19:40:06.148306
31985	1310	\N	\N	3123	1	domain	2026-06-20 19:40:06.148306
31986	1310	\N	\N	1598	1	domain	2026-06-20 19:40:06.148306
31987	1310	\N	\N	3125	1	domain	2026-06-20 19:40:06.148306
31988	1310	\N	\N	3150	1	domain	2026-06-20 19:40:06.148306
31989	1310	\N	\N	244	1	domain	2026-06-20 19:40:06.148306
31990	1310	\N	\N	245	1	domain	2026-06-20 19:40:06.148306
31991	1310	\N	\N	246	1	domain	2026-06-20 19:40:06.148306
31992	1310	\N	\N	730	1	domain	2026-06-20 19:40:06.148306
31993	1310	\N	\N	731	1	domain	2026-06-20 19:40:06.148306
31994	1310	\N	\N	1647	1	domain	2026-06-20 19:40:06.148306
31995	1310	\N	\N	71	1	domain	2026-06-20 19:40:06.148306
31996	1310	\N	\N	1648	1	domain	2026-06-20 19:40:06.148306
31997	1310	\N	\N	1649	1	domain	2026-06-20 19:40:06.148306
31998	1310	\N	\N	1007	1	domain	2026-06-20 19:40:06.148306
31999	1310	\N	\N	1651	1	domain	2026-06-20 19:40:06.148306
32000	1310	\N	\N	1652	1	domain	2026-06-20 19:40:06.148306
32001	1310	\N	\N	1653	1	domain	2026-06-20 19:40:06.148306
32002	1310	\N	\N	1955	1	domain	2026-06-20 19:40:06.148306
32003	1310	\N	\N	1968	1	domain	2026-06-20 19:40:06.148306
32004	1310	\N	\N	1237	1	domain	2026-06-20 19:40:06.148306
32005	1310	\N	\N	2261	1	domain	2026-06-20 19:40:06.148306
32006	1310	\N	\N	2263	1	domain	2026-06-20 19:40:06.148306
32007	1310	\N	\N	2267	1	domain	2026-06-20 19:40:06.148306
32008	1310	\N	\N	1322	1	domain	2026-06-20 19:40:06.148306
32009	1310	\N	\N	1325	1	domain	2026-06-20 19:40:06.148306
32010	1310	\N	\N	1326	1	domain	2026-06-20 19:40:06.148306
32011	1310	\N	\N	1329	1	domain	2026-06-20 19:40:06.148306
32012	1310	\N	\N	2348	1	domain	2026-06-20 19:40:06.148306
32013	1310	\N	\N	2543	1	domain	2026-06-20 19:40:06.148306
32014	1310	\N	\N	2544	1	domain	2026-06-20 19:40:06.148306
32015	1310	\N	\N	2545	1	domain	2026-06-20 19:40:06.148306
32016	1310	\N	\N	2554	1	domain	2026-06-20 19:40:06.148306
32017	1310	\N	\N	2559	1	domain	2026-06-20 19:40:06.148306
32018	1310	\N	\N	2562	1	domain	2026-06-20 19:40:06.148306
32020	1310	\N	\N	698	1	domain	2026-06-20 19:40:06.153845
32021	1310	\N	\N	1658	1	domain	2026-06-20 19:40:06.153845
32022	1310	\N	\N	1676	1	domain	2026-06-20 19:40:06.153845
32024	1311	\N	\N	1219	1	domain	2026-06-20 19:40:06.159457
32025	1311	\N	\N	1220	1	domain	2026-06-20 19:40:06.159457
32026	1311	\N	\N	1221	1	domain	2026-06-20 19:40:06.159457
32027	1311	\N	\N	2807	1	domain	2026-06-20 19:40:06.159457
32028	1311	\N	\N	706	1	domain	2026-06-20 19:40:06.159457
32029	1311	\N	\N	934	1	domain	2026-06-20 19:40:06.159457
32030	1311	\N	\N	935	1	domain	2026-06-20 19:40:06.159457
32031	1311	\N	\N	936	1	domain	2026-06-20 19:40:06.159457
32032	1311	\N	\N	621	1	domain	2026-06-20 19:40:06.159457
32033	1311	\N	\N	942	1	domain	2026-06-20 19:40:06.159457
32034	1311	\N	\N	1584	1	domain	2026-06-20 19:40:06.159457
32035	1311	\N	\N	3248	1	domain	2026-06-20 19:40:06.159457
32036	1311	\N	\N	2148	1	domain	2026-06-20 19:40:06.159457
32037	1311	\N	\N	2149	1	domain	2026-06-20 19:40:06.159457
32038	1311	\N	\N	2946	1	domain	2026-06-20 19:40:06.159457
32039	1311	\N	\N	1217	1	domain	2026-06-20 19:40:06.159457
32040	1311	\N	\N	2182	1	domain	2026-06-20 19:40:06.159457
32041	1311	\N	\N	882	1	domain	2026-06-20 19:40:06.159457
32042	1311	\N	\N	162	1	domain	2026-06-20 19:40:06.159457
32043	1311	\N	\N	2223	1	domain	2026-06-20 19:40:06.159457
32044	1311	\N	\N	3058	1	domain	2026-06-20 19:40:06.159457
32045	1311	\N	\N	3059	1	domain	2026-06-20 19:40:06.159457
32046	1311	\N	\N	3060	1	domain	2026-06-20 19:40:06.159457
32047	1311	\N	\N	3061	1	domain	2026-06-20 19:40:06.159457
32048	1311	\N	\N	3062	1	domain	2026-06-20 19:40:06.159457
32049	1311	\N	\N	3064	1	domain	2026-06-20 19:40:06.159457
32050	1311	\N	\N	3077	1	domain	2026-06-20 19:40:06.159457
32051	1311	\N	\N	3073	1	domain	2026-06-20 19:40:06.159457
32052	1311	\N	\N	3074	1	domain	2026-06-20 19:40:06.159457
32053	1311	\N	\N	3075	1	domain	2026-06-20 19:40:06.159457
32054	1311	\N	\N	3076	1	domain	2026-06-20 19:40:06.159457
32055	1311	\N	\N	3078	1	domain	2026-06-20 19:40:06.159457
32056	1311	\N	\N	3079	1	domain	2026-06-20 19:40:06.159457
32057	1311	\N	\N	3080	1	domain	2026-06-20 19:40:06.159457
32058	1311	\N	\N	2505	1	domain	2026-06-20 19:40:06.159457
32060	1311	\N	\N	1544	1	domain	2026-06-20 19:40:06.163468
32061	1311	\N	\N	159	1	domain	2026-06-20 19:40:06.163468
32063	1311	\N	\N	913	1	domain	2026-06-20 19:40:06.169044
32064	1311	\N	\N	601	1	domain	2026-06-20 19:40:06.169044
32065	1311	\N	\N	921	1	domain	2026-06-20 19:40:06.169044
32066	1311	\N	\N	603	1	domain	2026-06-20 19:40:06.169044
32067	1311	\N	\N	702	1	domain	2026-06-20 19:40:06.169044
32068	1311	\N	\N	2805	1	domain	2026-06-20 19:40:06.169044
32069	1311	\N	\N	2806	1	domain	2026-06-20 19:40:06.169044
32070	1311	\N	\N	705	1	domain	2026-06-20 19:40:06.169044
32071	1311	\N	\N	707	1	domain	2026-06-20 19:40:06.169044
32072	1311	\N	\N	930	1	domain	2026-06-20 19:40:06.169044
32073	1311	\N	\N	2607	1	domain	2026-06-20 19:40:06.169044
32074	1311	\N	\N	933	1	domain	2026-06-20 19:40:06.169044
32075	1311	\N	\N	2150	1	domain	2026-06-20 19:40:06.169044
32076	1311	\N	\N	1639	1	domain	2026-06-20 19:40:06.169044
32077	1311	\N	\N	1643	1	domain	2026-06-20 19:40:06.169044
32078	1311	\N	\N	3168	1	domain	2026-06-20 19:40:06.169044
32079	1311	\N	\N	3309	1	domain	2026-06-20 19:40:06.169044
32080	1311	\N	\N	3247	1	domain	2026-06-20 19:40:06.169044
32081	1311	\N	\N	2142	1	domain	2026-06-20 19:40:06.169044
32082	1311	\N	\N	1216	1	domain	2026-06-20 19:40:06.169044
32083	1311	\N	\N	881	1	domain	2026-06-20 19:40:06.169044
32084	1311	\N	\N	2214	1	domain	2026-06-20 19:40:06.169044
32085	1311	\N	\N	3038	1	domain	2026-06-20 19:40:06.169044
32086	1311	\N	\N	3043	1	domain	2026-06-20 19:40:06.169044
32087	1311	\N	\N	3044	1	domain	2026-06-20 19:40:06.169044
32088	1311	\N	\N	3052	1	domain	2026-06-20 19:40:06.169044
32089	1311	\N	\N	3056	1	domain	2026-06-20 19:40:06.169044
32090	1311	\N	\N	3065	1	domain	2026-06-20 19:40:06.169044
32091	1311	\N	\N	3066	1	domain	2026-06-20 19:40:06.169044
32092	1311	\N	\N	3068	1	domain	2026-06-20 19:40:06.169044
32093	1311	\N	\N	3069	1	domain	2026-06-20 19:40:06.169044
32094	1311	\N	\N	3071	1	domain	2026-06-20 19:40:06.169044
32096	1311	\N	\N	912	1	domain	2026-06-20 19:40:06.180267
32097	1311	\N	\N	914	1	domain	2026-06-20 19:40:06.180267
32098	1311	\N	\N	916	1	domain	2026-06-20 19:40:06.180267
32099	1311	\N	\N	917	1	domain	2026-06-20 19:40:06.180267
32100	1311	\N	\N	592	1	domain	2026-06-20 19:40:06.180267
32101	1311	\N	\N	1549	1	domain	2026-06-20 19:40:06.180267
32102	1311	\N	\N	918	1	domain	2026-06-20 19:40:06.180267
32103	1311	\N	\N	1550	1	domain	2026-06-20 19:40:06.180267
32104	1311	\N	\N	910	1	domain	2026-06-20 19:40:06.180267
32105	1311	\N	\N	911	1	domain	2026-06-20 19:40:06.180267
32106	1311	\N	\N	904	1	domain	2026-06-20 19:40:06.180267
32107	1311	\N	\N	905	1	domain	2026-06-20 19:40:06.180267
32108	1311	\N	\N	906	1	domain	2026-06-20 19:40:06.180267
32109	1311	\N	\N	907	1	domain	2026-06-20 19:40:06.180267
32110	1311	\N	\N	908	1	domain	2026-06-20 19:40:06.180267
32111	1311	\N	\N	909	1	domain	2026-06-20 19:40:06.180267
32112	1311	\N	\N	602	1	domain	2026-06-20 19:40:06.180267
32113	1311	\N	\N	922	1	domain	2026-06-20 19:40:06.180267
32114	1311	\N	\N	1758	1	domain	2026-06-20 19:40:06.180267
32115	1311	\N	\N	923	1	domain	2026-06-20 19:40:06.180267
32116	1311	\N	\N	604	1	domain	2026-06-20 19:40:06.180267
32117	1311	\N	\N	924	1	domain	2026-06-20 19:40:06.180267
32118	1311	\N	\N	1855	1	domain	2026-06-20 19:40:06.180267
32119	1311	\N	\N	926	1	domain	2026-06-20 19:40:06.180267
32120	1311	\N	\N	704	1	domain	2026-06-20 19:40:06.180267
32121	1311	\N	\N	927	1	domain	2026-06-20 19:40:06.180267
32122	1311	\N	\N	3338	1	domain	2026-06-20 19:40:06.180267
32123	1311	\N	\N	929	1	domain	2026-06-20 19:40:06.180267
32124	1311	\N	\N	972	1	domain	2026-06-20 19:40:06.180267
32125	1311	\N	\N	932	1	domain	2026-06-20 19:40:06.180267
32126	1311	\N	\N	1415	1	domain	2026-06-20 19:40:06.180267
32127	1311	\N	\N	973	1	domain	2026-06-20 19:40:06.180267
32128	1311	\N	\N	2608	1	domain	2026-06-20 19:40:06.180267
32129	1311	\N	\N	2870	1	domain	2026-06-20 19:40:06.180267
32130	1311	\N	\N	712	1	domain	2026-06-20 19:40:06.180267
32131	1311	\N	\N	3278	1	domain	2026-06-20 19:40:06.180267
32132	1311	\N	\N	384	1	domain	2026-06-20 19:40:06.180267
32133	1311	\N	\N	937	1	domain	2026-06-20 19:40:06.180267
32134	1311	\N	\N	938	1	domain	2026-06-20 19:40:06.180267
32135	1311	\N	\N	939	1	domain	2026-06-20 19:40:06.180267
32136	1311	\N	\N	3283	1	domain	2026-06-20 19:40:06.180267
32137	1311	\N	\N	940	1	domain	2026-06-20 19:40:06.180267
32138	1311	\N	\N	941	1	domain	2026-06-20 19:40:06.180267
32139	1311	\N	\N	3143	1	domain	2026-06-20 19:40:06.180267
32140	1311	\N	\N	3144	1	domain	2026-06-20 19:40:06.180267
32141	1311	\N	\N	3145	1	domain	2026-06-20 19:40:06.180267
32142	1311	\N	\N	3151	1	domain	2026-06-20 19:40:06.180267
32143	1311	\N	\N	3055	1	domain	2026-06-20 19:40:06.180267
32144	1311	\N	\N	1644	1	domain	2026-06-20 19:40:06.180267
32145	1311	\N	\N	1646	1	domain	2026-06-20 19:40:06.180267
32146	1311	\N	\N	3244	1	domain	2026-06-20 19:40:06.180267
32147	1311	\N	\N	3245	1	domain	2026-06-20 19:40:06.180267
32148	1311	\N	\N	3246	1	domain	2026-06-20 19:40:06.180267
32149	1311	\N	\N	2141	1	domain	2026-06-20 19:40:06.180267
32150	1311	\N	\N	2151	1	domain	2026-06-20 19:40:06.180267
32151	1311	\N	\N	2144	1	domain	2026-06-20 19:40:06.180267
32152	1311	\N	\N	2145	1	domain	2026-06-20 19:40:06.180267
32153	1311	\N	\N	2146	1	domain	2026-06-20 19:40:06.180267
32154	1311	\N	\N	2152	1	domain	2026-06-20 19:40:06.180267
32155	1311	\N	\N	1215	1	domain	2026-06-20 19:40:06.180267
32156	1311	\N	\N	1218	1	domain	2026-06-20 19:40:06.180267
32157	1311	\N	\N	878	1	domain	2026-06-20 19:40:06.180267
32158	1311	\N	\N	879	1	domain	2026-06-20 19:40:06.180267
32159	1311	\N	\N	880	1	domain	2026-06-20 19:40:06.180267
32160	1311	\N	\N	2763	1	domain	2026-06-20 19:40:06.180267
32161	1311	\N	\N	2767	1	domain	2026-06-20 19:40:06.180267
32162	1311	\N	\N	160	1	domain	2026-06-20 19:40:06.180267
32163	1311	\N	\N	161	1	domain	2026-06-20 19:40:06.180267
32164	1311	\N	\N	2220	1	domain	2026-06-20 19:40:06.180267
32165	1311	\N	\N	2221	1	domain	2026-06-20 19:40:06.180267
32166	1311	\N	\N	3045	1	domain	2026-06-20 19:40:06.180267
32167	1311	\N	\N	3057	1	domain	2026-06-20 19:40:06.180267
32168	1311	\N	\N	3067	1	domain	2026-06-20 19:40:06.180267
32169	1311	\N	\N	3070	1	domain	2026-06-20 19:40:06.180267
32170	1311	\N	\N	3072	1	domain	2026-06-20 19:40:06.180267
32171	1311	\N	\N	3100	1	domain	2026-06-20 19:40:06.180267
32172	1311	\N	\N	2316	1	domain	2026-06-20 19:40:06.180267
32173	1311	\N	\N	2434	1	domain	2026-06-20 19:40:06.180267
32174	1311	\N	\N	2493	1	domain	2026-06-20 19:40:06.180267
32175	1311	\N	\N	2504	1	domain	2026-06-20 19:40:06.180267
32176	1311	\N	\N	2574	1	domain	2026-06-20 19:40:06.180267
32177	1311	\N	\N	2578	1	domain	2026-06-20 19:40:06.180267
32179	1311	\N	\N	3335	1	domain	2026-06-20 19:40:06.189583
32180	1311	\N	\N	1414	1	domain	2026-06-20 19:40:06.189583
32181	1311	\N	\N	3398	1	domain	2026-06-20 19:40:06.189583
32182	1311	\N	\N	722	1	domain	2026-06-20 19:40:06.189583
32183	1311	\N	\N	1645	1	domain	2026-06-20 19:40:06.189583
32184	1311	\N	\N	283	1	domain	2026-06-20 19:40:06.189583
32185	1311	\N	\N	286	1	domain	2026-06-20 19:40:06.189583
32186	1311	\N	\N	287	1	domain	2026-06-20 19:40:06.189583
32188	1312	\N	\N	3181	1	domain	2026-06-20 19:40:06.196508
32189	1312	\N	\N	3184	1	domain	2026-06-20 19:40:06.196508
32190	1312	\N	\N	170	1	domain	2026-06-20 19:40:06.196508
32191	1312	\N	\N	3117	1	domain	2026-06-20 19:40:06.196508
32192	1312	\N	\N	3118	1	domain	2026-06-20 19:40:06.196508
32193	1312	\N	\N	2799	1	domain	2026-06-20 19:40:06.196508
32194	1312	\N	\N	1222	1	domain	2026-06-20 19:40:06.196508
32195	1312	\N	\N	2809	1	domain	2026-06-20 19:40:06.196508
32196	1312	\N	\N	2810	1	domain	2026-06-20 19:40:06.196508
32197	1312	\N	\N	2869	1	domain	2026-06-20 19:40:06.196508
32198	1312	\N	\N	3281	1	domain	2026-06-20 19:40:06.196508
32199	1312	\N	\N	625	1	domain	2026-06-20 19:40:06.196508
32200	1312	\N	\N	626	1	domain	2026-06-20 19:40:06.196508
32201	1312	\N	\N	627	1	domain	2026-06-20 19:40:06.196508
32202	1312	\N	\N	630	1	domain	2026-06-20 19:40:06.196508
32203	1312	\N	\N	1589	1	domain	2026-06-20 19:40:06.196508
32204	1312	\N	\N	3359	1	domain	2026-06-20 19:40:06.196508
32205	1312	\N	\N	634	1	domain	2026-06-20 19:40:06.196508
32206	1312	\N	\N	635	1	domain	2026-06-20 19:40:06.196508
32207	1312	\N	\N	636	1	domain	2026-06-20 19:40:06.196508
32208	1312	\N	\N	797	1	domain	2026-06-20 19:40:06.196508
32209	1312	\N	\N	2835	1	domain	2026-06-20 19:40:06.196508
32210	1312	\N	\N	1120	1	domain	2026-06-20 19:40:06.196508
32211	1312	\N	\N	1121	1	domain	2026-06-20 19:40:06.196508
32212	1312	\N	\N	1122	1	domain	2026-06-20 19:40:06.196508
32213	1312	\N	\N	2120	1	domain	2026-06-20 19:40:06.196508
32214	1312	\N	\N	2121	1	domain	2026-06-20 19:40:06.196508
32215	1312	\N	\N	2122	1	domain	2026-06-20 19:40:06.196508
32216	1312	\N	\N	2123	1	domain	2026-06-20 19:40:06.196508
32217	1312	\N	\N	834	1	domain	2026-06-20 19:40:06.196508
32218	1312	\N	\N	833	1	domain	2026-06-20 19:40:06.196508
32219	1312	\N	\N	1538	1	domain	2026-06-20 19:40:06.196508
32220	1312	\N	\N	1695	1	domain	2026-06-20 19:40:06.196508
32221	1312	\N	\N	125	1	domain	2026-06-20 19:40:06.196508
32222	1312	\N	\N	126	1	domain	2026-06-20 19:40:06.196508
32223	1312	\N	\N	127	1	domain	2026-06-20 19:40:06.196508
32224	1312	\N	\N	2751	1	domain	2026-06-20 19:40:06.196508
32225	1312	\N	\N	143	1	domain	2026-06-20 19:40:06.196508
32226	1312	\N	\N	1738	1	domain	2026-06-20 19:40:06.196508
32227	1312	\N	\N	2778	1	domain	2026-06-20 19:40:06.196508
32228	1312	\N	\N	2779	1	domain	2026-06-20 19:40:06.196508
32230	1312	\N	\N	3182	1	domain	2026-06-20 19:40:06.2025
32231	1312	\N	\N	799	1	domain	2026-06-20 19:40:06.2025
32233	1312	\N	\N	3183	1	domain	2026-06-20 19:40:06.205214
32234	1312	\N	\N	832	1	domain	2026-06-20 19:40:06.205214
32235	1312	\N	\N	2217	1	domain	2026-06-20 19:40:06.205214
32237	1312	\N	\N	1551	1	domain	2026-06-20 19:40:06.205214
32238	1312	\N	\N	1552	1	domain	2026-06-20 19:40:06.205214
32239	1312	\N	\N	1824	1	domain	2026-06-20 19:40:06.205214
32240	1312	\N	\N	142	1	domain	2026-06-20 19:40:06.205214
32241	1312	\N	\N	144	1	domain	2026-06-20 19:40:06.205214
32242	1312	\N	\N	1735	1	domain	2026-06-20 19:40:06.205214
32243	1312	\N	\N	145	1	domain	2026-06-20 19:40:06.205214
32244	1312	\N	\N	1736	1	domain	2026-06-20 19:40:06.205214
32245	1312	\N	\N	147	1	domain	2026-06-20 19:40:06.205214
32247	1312	\N	\N	663	1	domain	2026-06-20 19:40:06.213055
32248	1312	\N	\N	2814	1	domain	2026-06-20 19:40:06.213055
32249	1312	\N	\N	3140	1	domain	2026-06-20 19:40:06.213055
32250	1312	\N	\N	631	1	domain	2026-06-20 19:40:06.213055
32251	1312	\N	\N	632	1	domain	2026-06-20 19:40:06.213055
32252	1312	\N	\N	633	1	domain	2026-06-20 19:40:06.213055
32253	1312	\N	\N	2726	1	domain	2026-06-20 19:40:06.213055
32254	1312	\N	\N	2727	1	domain	2026-06-20 19:40:06.213055
32255	1312	\N	\N	2728	1	domain	2026-06-20 19:40:06.213055
32256	1312	\N	\N	3000	1	domain	2026-06-20 19:40:06.213055
32257	1312	\N	\N	2240	1	domain	2026-06-20 19:40:06.213055
32259	1313	\N	\N	3207	1	domain	2026-06-20 19:40:06.221102
32260	1313	\N	\N	2694	1	domain	2026-06-20 19:40:06.221102
32261	1313	\N	\N	2620	1	domain	2026-06-20 19:40:06.221102
32262	1313	\N	\N	2592	1	domain	2026-06-20 19:40:06.221102
32263	1313	\N	\N	819	1	domain	2026-06-20 19:40:06.221102
32264	1313	\N	\N	2593	1	domain	2026-06-20 19:40:06.221102
32265	1313	\N	\N	3383	1	domain	2026-06-20 19:40:06.221102
32266	1313	\N	\N	181	1	domain	2026-06-20 19:40:06.221102
32267	1313	\N	\N	182	1	domain	2026-06-20 19:40:06.221102
32268	1313	\N	\N	3197	1	domain	2026-06-20 19:40:06.221102
32269	1313	\N	\N	183	1	domain	2026-06-20 19:40:06.221102
32270	1313	\N	\N	3206	1	domain	2026-06-20 19:40:06.221102
32271	1313	\N	\N	713	1	domain	2026-06-20 19:40:06.221102
32272	1313	\N	\N	1576	1	domain	2026-06-20 19:40:06.221102
32273	1313	\N	\N	2090	1	domain	2026-06-20 19:40:06.221102
32274	1313	\N	\N	717	1	domain	2026-06-20 19:40:06.221102
32275	1313	\N	\N	3208	1	domain	2026-06-20 19:40:06.221102
32276	1313	\N	\N	3209	1	domain	2026-06-20 19:40:06.221102
32277	1313	\N	\N	3210	1	domain	2026-06-20 19:40:06.221102
32278	1313	\N	\N	52	1	domain	2026-06-20 19:40:06.221102
32279	1313	\N	\N	43	1	domain	2026-06-20 19:40:06.221102
32280	1313	\N	\N	989	1	domain	2026-06-20 19:40:06.221102
32281	1313	\N	\N	45	1	domain	2026-06-20 19:40:06.221102
32282	1313	\N	\N	46	1	domain	2026-06-20 19:40:06.221102
32283	1313	\N	\N	991	1	domain	2026-06-20 19:40:06.221102
32284	1313	\N	\N	47	1	domain	2026-06-20 19:40:06.221102
32285	1313	\N	\N	48	1	domain	2026-06-20 19:40:06.221102
32286	1313	\N	\N	993	1	domain	2026-06-20 19:40:06.221102
32287	1313	\N	\N	49	1	domain	2026-06-20 19:40:06.221102
32288	1313	\N	\N	994	1	domain	2026-06-20 19:40:06.221102
32289	1313	\N	\N	50	1	domain	2026-06-20 19:40:06.221102
32290	1313	\N	\N	51	1	domain	2026-06-20 19:40:06.221102
32291	1313	\N	\N	996	1	domain	2026-06-20 19:40:06.221102
32292	1313	\N	\N	53	1	domain	2026-06-20 19:40:06.221102
32293	1313	\N	\N	55	1	domain	2026-06-20 19:40:06.221102
32294	1313	\N	\N	446	1	domain	2026-06-20 19:40:06.221102
32295	1313	\N	\N	56	1	domain	2026-06-20 19:40:06.221102
32296	1313	\N	\N	58	1	domain	2026-06-20 19:40:06.221102
32297	1313	\N	\N	59	1	domain	2026-06-20 19:40:06.221102
32298	1313	\N	\N	60	1	domain	2026-06-20 19:40:06.221102
32299	1313	\N	\N	61	1	domain	2026-06-20 19:40:06.221102
32300	1313	\N	\N	62	1	domain	2026-06-20 19:40:06.221102
32301	1313	\N	\N	815	1	domain	2026-06-20 19:40:06.221102
32302	1313	\N	\N	816	1	domain	2026-06-20 19:40:06.221102
32303	1313	\N	\N	817	1	domain	2026-06-20 19:40:06.221102
32304	1313	\N	\N	818	1	domain	2026-06-20 19:40:06.221102
32305	1313	\N	\N	820	1	domain	2026-06-20 19:40:06.221102
32306	1313	\N	\N	821	1	domain	2026-06-20 19:40:06.221102
32307	1313	\N	\N	823	1	domain	2026-06-20 19:40:06.221102
32308	1313	\N	\N	825	1	domain	2026-06-20 19:40:06.221102
32309	1313	\N	\N	2919	1	domain	2026-06-20 19:40:06.221102
32310	1313	\N	\N	2697	1	domain	2026-06-20 19:40:06.221102
32311	1313	\N	\N	2699	1	domain	2026-06-20 19:40:06.221102
32312	1313	\N	\N	110	1	domain	2026-06-20 19:40:06.221102
32313	1313	\N	\N	1989	1	domain	2026-06-20 19:40:06.221102
32314	1313	\N	\N	1996	1	domain	2026-06-20 19:40:06.221102
32315	1313	\N	\N	2754	1	domain	2026-06-20 19:40:06.221102
32316	1313	\N	\N	552	1	domain	2026-06-20 19:40:06.221102
32317	1313	\N	\N	2315	1	domain	2026-06-20 19:40:06.221102
32318	1313	\N	\N	2324	1	domain	2026-06-20 19:40:06.221102
32319	1313	\N	\N	2367	1	domain	2026-06-20 19:40:06.221102
32320	1313	\N	\N	2389	1	domain	2026-06-20 19:40:06.221102
32321	1313	\N	\N	2432	1	domain	2026-06-20 19:40:06.221102
32322	1313	\N	\N	2435	1	domain	2026-06-20 19:40:06.221102
32323	1313	\N	\N	2437	1	domain	2026-06-20 19:40:06.221102
32324	1313	\N	\N	2468	1	domain	2026-06-20 19:40:06.221102
32325	1313	\N	\N	2476	1	domain	2026-06-20 19:40:06.221102
32326	1313	\N	\N	2477	1	domain	2026-06-20 19:40:06.221102
32327	1313	\N	\N	2479	1	domain	2026-06-20 19:40:06.221102
32328	1313	\N	\N	2520	1	domain	2026-06-20 19:40:06.221102
32329	1313	\N	\N	2524	1	domain	2026-06-20 19:40:06.221102
32331	1313	\N	\N	3321	1	domain	2026-06-20 19:40:06.221102
32332	1313	\N	\N	3269	1	domain	2026-06-20 19:40:06.221102
32333	1313	\N	\N	1826	1	domain	2026-06-20 19:40:06.221102
32334	1313	\N	\N	3131	1	domain	2026-06-20 19:40:06.221102
32335	1313	\N	\N	711	1	domain	2026-06-20 19:40:06.221102
32336	1313	\N	\N	3211	1	domain	2026-06-20 19:40:06.221102
32337	1313	\N	\N	990	1	domain	2026-06-20 19:40:06.221102
32338	1313	\N	\N	1674	1	domain	2026-06-20 19:40:06.221102
32339	1313	\N	\N	1675	1	domain	2026-06-20 19:40:06.221102
32340	1313	\N	\N	1677	1	domain	2026-06-20 19:40:06.221102
32341	1313	\N	\N	1979	1	domain	2026-06-20 19:40:06.221102
32342	1313	\N	\N	1980	1	domain	2026-06-20 19:40:06.221102
32343	1313	\N	\N	1981	1	domain	2026-06-20 19:40:06.221102
32344	1313	\N	\N	1982	1	domain	2026-06-20 19:40:06.221102
32345	1313	\N	\N	1983	1	domain	2026-06-20 19:40:06.221102
32346	1313	\N	\N	1984	1	domain	2026-06-20 19:40:06.221102
32347	1313	\N	\N	1985	1	domain	2026-06-20 19:40:06.221102
32348	1313	\N	\N	1232	1	domain	2026-06-20 19:40:06.221102
32349	1313	\N	\N	1986	1	domain	2026-06-20 19:40:06.221102
32350	1313	\N	\N	1987	1	domain	2026-06-20 19:40:06.221102
32351	1313	\N	\N	1988	1	domain	2026-06-20 19:40:06.221102
32352	1313	\N	\N	2473	1	domain	2026-06-20 19:40:06.221102
32354	1313	\N	\N	1600	1	domain	2026-06-20 19:40:06.228962
32355	1313	\N	\N	28	1	domain	2026-06-20 19:40:06.228962
32356	1313	\N	\N	29	1	domain	2026-06-20 19:40:06.228962
32357	1313	\N	\N	718	1	domain	2026-06-20 19:40:06.228962
32358	1313	\N	\N	842	1	domain	2026-06-20 19:40:06.228962
32360	1313	\N	\N	3212	1	domain	2026-06-20 19:40:06.228962
32361	1313	\N	\N	999	1	domain	2026-06-20 19:40:06.228962
32362	1313	\N	\N	1679	1	domain	2026-06-20 19:40:06.228962
32363	1313	\N	\N	1680	1	domain	2026-06-20 19:40:06.228962
32364	1313	\N	\N	1231	1	domain	2026-06-20 19:40:06.228962
32365	1313	\N	\N	2433	1	domain	2026-06-20 19:40:06.228962
32367	1313	\N	\N	992	1	domain	2026-06-20 19:40:06.228962
32368	1313	\N	\N	2695	1	domain	2026-06-20 19:40:06.228962
32369	1313	\N	\N	2696	1	domain	2026-06-20 19:40:06.228962
32370	1313	\N	\N	2478	1	domain	2026-06-20 19:40:06.228962
32372	1314	\N	\N	2	1	domain	2026-06-20 19:40:06.24574
32373	1314	\N	\N	3189	1	domain	2026-06-20 19:40:06.24574
32374	1314	\N	\N	775	1	domain	2026-06-20 19:40:06.24574
32375	1314	\N	\N	981	1	domain	2026-06-20 19:40:06.24574
32376	1314	\N	\N	1124	1	domain	2026-06-20 19:40:06.24574
32377	1314	\N	\N	2680	1	domain	2026-06-20 19:40:06.24574
32378	1314	\N	\N	1691	1	domain	2026-06-20 19:40:06.24574
32379	1314	\N	\N	2048	1	domain	2026-06-20 19:40:06.24574
32380	1314	\N	\N	2273	1	domain	2026-06-20 19:40:06.24574
32381	1314	\N	\N	2523	1	domain	2026-06-20 19:40:06.24574
32382	1314	\N	\N	2573	1	domain	2026-06-20 19:40:06.24574
32384	1314	\N	\N	1	1	domain	2026-06-20 19:40:06.254305
32385	1314	\N	\N	3	1	domain	2026-06-20 19:40:06.254305
32386	1314	\N	\N	362	1	domain	2026-06-20 19:40:06.254305
32387	1314	\N	\N	3191	1	domain	2026-06-20 19:40:06.254305
32388	1314	\N	\N	1559	1	domain	2026-06-20 19:40:06.254305
32389	1314	\N	\N	2866	1	domain	2026-06-20 19:40:06.254305
32390	1314	\N	\N	2084	1	domain	2026-06-20 19:40:06.254305
32391	1314	\N	\N	2085	1	domain	2026-06-20 19:40:06.254305
32392	1314	\N	\N	2086	1	domain	2026-06-20 19:40:06.254305
32393	1314	\N	\N	1123	1	domain	2026-06-20 19:40:06.254305
32394	1314	\N	\N	2894	1	domain	2026-06-20 19:40:06.254305
32395	1314	\N	\N	2895	1	domain	2026-06-20 19:40:06.254305
32396	1314	\N	\N	2896	1	domain	2026-06-20 19:40:06.254305
32397	1314	\N	\N	2672	1	domain	2026-06-20 19:40:06.254305
32398	1314	\N	\N	2897	1	domain	2026-06-20 19:40:06.254305
32399	1314	\N	\N	2673	1	domain	2026-06-20 19:40:06.254305
32400	1314	\N	\N	1342	1	domain	2026-06-20 19:40:06.254305
32402	1314	\N	\N	684	1	domain	2026-06-20 19:40:06.262573
32403	1314	\N	\N	8	1	domain	2026-06-20 19:40:06.262573
32404	1314	\N	\N	2087	1	domain	2026-06-20 19:40:06.262573
32405	1314	\N	\N	3193	1	domain	2026-06-20 19:40:06.262573
32406	1314	\N	\N	3194	1	domain	2026-06-20 19:40:06.262573
32407	1314	\N	\N	779	1	domain	2026-06-20 19:40:06.262573
32408	1314	\N	\N	984	1	domain	2026-06-20 19:40:06.262573
32409	1314	\N	\N	2679	1	domain	2026-06-20 19:40:06.262573
32410	1314	\N	\N	557	1	domain	2026-06-20 19:40:06.262573
32412	1314	\N	\N	3190	1	domain	2026-06-20 19:40:06.263036
32413	1314	\N	\N	776	1	domain	2026-06-20 19:40:06.263036
32414	1314	\N	\N	982	1	domain	2026-06-20 19:40:06.263036
32416	1315	\N	\N	2987	1	domain	2026-06-20 19:40:06.271781
32417	1315	\N	\N	3116	1	domain	2026-06-20 19:40:06.271781
32418	1315	\N	\N	622	1	domain	2026-06-20 19:40:06.271781
32419	1315	\N	\N	1587	1	domain	2026-06-20 19:40:06.271781
32420	1315	\N	\N	2016	1	domain	2026-06-20 19:40:06.271781
32422	1315	\N	\N	3261	1	domain	2026-06-20 19:40:06.279091
32423	1315	\N	\N	3262	1	domain	2026-06-20 19:40:06.279091
32424	1315	\N	\N	1623	1	domain	2026-06-20 19:40:06.279091
32425	1315	\N	\N	3177	1	domain	2026-06-20 19:40:06.279091
32426	1315	\N	\N	3358	1	domain	2026-06-20 19:40:06.279091
32428	1315	\N	\N	366	1	domain	2026-06-20 19:40:06.287161
32429	1315	\N	\N	1162	1	domain	2026-06-20 19:40:06.287161
32430	1315	\N	\N	2948	1	domain	2026-06-20 19:40:06.287161
32431	1315	\N	\N	2986	1	domain	2026-06-20 19:40:06.287161
32432	1315	\N	\N	2982	1	domain	2026-06-20 19:40:06.287161
32434	1316	\N	\N	2577	1	domain	2026-06-20 19:40:06.29537
32435	1316	\N	\N	1258	1	domain	2026-06-20 19:40:06.29537
32436	1316	\N	\N	2591	1	domain	2026-06-20 19:40:06.29537
32437	1316	\N	\N	180	1	domain	2026-06-20 19:40:06.29537
32438	1316	\N	\N	3393	1	domain	2026-06-20 19:40:06.29537
32439	1316	\N	\N	3205	1	domain	2026-06-20 19:40:06.29537
32440	1316	\N	\N	1259	1	domain	2026-06-20 19:40:06.29537
32441	1316	\N	\N	1897	1	domain	2026-06-20 19:40:06.29537
32442	1316	\N	\N	1898	1	domain	2026-06-20 19:40:06.29537
32443	1316	\N	\N	2825	1	domain	2026-06-20 19:40:06.29537
32444	1316	\N	\N	1899	1	domain	2026-06-20 19:40:06.29537
32445	1316	\N	\N	2826	1	domain	2026-06-20 19:40:06.29537
32446	1316	\N	\N	1900	1	domain	2026-06-20 19:40:06.29537
32447	1316	\N	\N	1901	1	domain	2026-06-20 19:40:06.29537
32448	1316	\N	\N	1902	1	domain	2026-06-20 19:40:06.29537
32449	1316	\N	\N	1903	1	domain	2026-06-20 19:40:06.29537
32450	1316	\N	\N	1904	1	domain	2026-06-20 19:40:06.29537
32451	1316	\N	\N	1905	1	domain	2026-06-20 19:40:06.29537
32452	1316	\N	\N	3307	1	domain	2026-06-20 19:40:06.29537
32453	1316	\N	\N	866	1	domain	2026-06-20 19:40:06.29537
32454	1316	\N	\N	1718	1	domain	2026-06-20 19:40:06.29537
32455	1316	\N	\N	1720	1	domain	2026-06-20 19:40:06.29537
32456	1316	\N	\N	137	1	domain	2026-06-20 19:40:06.29537
32457	1316	\N	\N	1250	1	domain	2026-06-20 19:40:06.29537
32458	1316	\N	\N	1251	1	domain	2026-06-20 19:40:06.29537
32459	1316	\N	\N	1252	1	domain	2026-06-20 19:40:06.29537
32460	1316	\N	\N	1253	1	domain	2026-06-20 19:40:06.29537
32461	1316	\N	\N	1254	1	domain	2026-06-20 19:40:06.29537
32462	1316	\N	\N	1255	1	domain	2026-06-20 19:40:06.29537
32463	1316	\N	\N	1256	1	domain	2026-06-20 19:40:06.29537
32464	1316	\N	\N	1257	1	domain	2026-06-20 19:40:06.29537
32465	1316	\N	\N	2440	1	domain	2026-06-20 19:40:06.29537
32466	1316	\N	\N	2444	1	domain	2026-06-20 19:40:06.29537
32468	1316	\N	\N	2590	1	domain	2026-06-20 19:40:06.312652
32469	1316	\N	\N	179	1	domain	2026-06-20 19:40:06.312652
32470	1316	\N	\N	1558	1	domain	2026-06-20 19:40:06.312652
32471	1316	\N	\N	215	1	domain	2026-06-20 19:40:06.312652
32472	1316	\N	\N	218	1	domain	2026-06-20 19:40:06.312652
32473	1316	\N	\N	219	1	domain	2026-06-20 19:40:06.312652
32474	1316	\N	\N	2601	1	domain	2026-06-20 19:40:06.312652
32475	1316	\N	\N	220	1	domain	2026-06-20 19:40:06.312652
32476	1316	\N	\N	1885	1	domain	2026-06-20 19:40:06.312652
32477	1316	\N	\N	3136	1	domain	2026-06-20 19:40:06.312652
32478	1316	\N	\N	1892	1	domain	2026-06-20 19:40:06.312652
32479	1316	\N	\N	1896	1	domain	2026-06-20 19:40:06.312652
32480	1316	\N	\N	1832	1	domain	2026-06-20 19:40:06.312652
32481	1316	\N	\N	727	1	domain	2026-06-20 19:40:06.312652
32482	1316	\N	\N	1909	1	domain	2026-06-20 19:40:06.312652
32483	1316	\N	\N	1910	1	domain	2026-06-20 19:40:06.312652
32484	1316	\N	\N	734	1	domain	2026-06-20 19:40:06.312652
32485	1316	\N	\N	1178	1	domain	2026-06-20 19:40:06.312652
32486	1316	\N	\N	2932	1	domain	2026-06-20 19:40:06.312652
32487	1316	\N	\N	1962	1	domain	2026-06-20 19:40:06.312652
32488	1316	\N	\N	1717	1	domain	2026-06-20 19:40:06.312652
32489	1316	\N	\N	1723	1	domain	2026-06-20 19:40:06.312652
32490	1316	\N	\N	1262	1	domain	2026-06-20 19:40:06.312652
32491	1316	\N	\N	2222	1	domain	2026-06-20 19:40:06.312652
32492	1316	\N	\N	3036	1	domain	2026-06-20 19:40:06.312652
32493	1316	\N	\N	1316	1	domain	2026-06-20 19:40:06.312652
32494	1316	\N	\N	1323	1	domain	2026-06-20 19:40:06.312652
32495	1316	\N	\N	1327	1	domain	2026-06-20 19:40:06.312652
32496	1316	\N	\N	2310	1	domain	2026-06-20 19:40:06.312652
32497	1316	\N	\N	2314	1	domain	2026-06-20 19:40:06.312652
32498	1316	\N	\N	2350	1	domain	2026-06-20 19:40:06.312652
32499	1316	\N	\N	2375	1	domain	2026-06-20 19:40:06.312652
32500	1316	\N	\N	2386	1	domain	2026-06-20 19:40:06.312652
32501	1316	\N	\N	2410	1	domain	2026-06-20 19:40:06.312652
32502	1316	\N	\N	2441	1	domain	2026-06-20 19:40:06.312652
32503	1316	\N	\N	2442	1	domain	2026-06-20 19:40:06.312652
32505	1316	\N	\N	3204	1	domain	2026-06-20 19:40:06.320412
32506	1316	\N	\N	1906	1	domain	2026-06-20 19:40:06.320412
32507	1316	\N	\N	805	1	domain	2026-06-20 19:40:06.320412
32508	1316	\N	\N	1026	1	domain	2026-06-20 19:40:06.320412
32509	1316	\N	\N	865	1	domain	2026-06-20 19:40:06.320412
32510	1316	\N	\N	1719	1	domain	2026-06-20 19:40:06.320412
32511	1316	\N	\N	1245	1	domain	2026-06-20 19:40:06.320412
32512	1316	\N	\N	1246	1	domain	2026-06-20 19:40:06.320412
32513	1316	\N	\N	1247	1	domain	2026-06-20 19:40:06.320412
32514	1316	\N	\N	1248	1	domain	2026-06-20 19:40:06.320412
32515	1316	\N	\N	1249	1	domain	2026-06-20 19:40:06.320412
32516	1316	\N	\N	2038	1	domain	2026-06-20 19:40:06.320412
32517	1316	\N	\N	2439	1	domain	2026-06-20 19:40:06.320412
32518	1316	\N	\N	2572	1	domain	2026-06-20 19:40:06.320412
32520	1317	\N	\N	2628	1	domain	2026-06-20 19:40:06.337165
32521	1317	\N	\N	1563	1	domain	2026-06-20 19:40:06.337165
32522	1317	\N	\N	2674	1	domain	2026-06-20 19:40:06.337165
32523	1317	\N	\N	2675	1	domain	2026-06-20 19:40:06.337165
32524	1317	\N	\N	2676	1	domain	2026-06-20 19:40:06.337165
32525	1317	\N	\N	2677	1	domain	2026-06-20 19:40:06.337165
32527	1317	\N	\N	166	1	domain	2026-06-20 19:40:06.354443
32528	1317	\N	\N	1607	1	domain	2026-06-20 19:40:06.354443
32529	1317	\N	\N	5	1	domain	2026-06-20 19:40:06.354443
32530	1317	\N	\N	1608	1	domain	2026-06-20 19:40:06.354443
32531	1317	\N	\N	6	1	domain	2026-06-20 19:40:06.354443
32532	1317	\N	\N	1609	1	domain	2026-06-20 19:40:06.354443
32533	1317	\N	\N	7	1	domain	2026-06-20 19:40:06.354443
32534	1317	\N	\N	1610	1	domain	2026-06-20 19:40:06.354443
32535	1317	\N	\N	2581	1	domain	2026-06-20 19:40:06.354443
32536	1317	\N	\N	3192	1	domain	2026-06-20 19:40:06.354443
32537	1317	\N	\N	1556	1	domain	2026-06-20 19:40:06.354443
32538	1317	\N	\N	695	1	domain	2026-06-20 19:40:06.354443
32539	1317	\N	\N	1557	1	domain	2026-06-20 19:40:06.354443
32540	1317	\N	\N	696	1	domain	2026-06-20 19:40:06.354443
32541	1317	\N	\N	3389	1	domain	2026-06-20 19:40:06.354443
32542	1317	\N	\N	609	1	domain	2026-06-20 19:40:06.354443
32543	1317	\N	\N	1830	1	domain	2026-06-20 19:40:06.354443
32544	1317	\N	\N	1831	1	domain	2026-06-20 19:40:06.354443
32545	1317	\N	\N	778	1	domain	2026-06-20 19:40:06.354443
32546	1317	\N	\N	3138	1	domain	2026-06-20 19:40:06.354443
32547	1317	\N	\N	1125	1	domain	2026-06-20 19:40:06.354443
32548	1317	\N	\N	429	1	domain	2026-06-20 19:40:06.354443
32549	1317	\N	\N	983	1	domain	2026-06-20 19:40:06.354443
32550	1317	\N	\N	430	1	domain	2026-06-20 19:40:06.354443
32551	1317	\N	\N	2095	1	domain	2026-06-20 19:40:06.354443
32552	1317	\N	\N	431	1	domain	2026-06-20 19:40:06.354443
32553	1317	\N	\N	2096	1	domain	2026-06-20 19:40:06.354443
32554	1317	\N	\N	432	1	domain	2026-06-20 19:40:06.354443
32555	1317	\N	\N	2097	1	domain	2026-06-20 19:40:06.354443
32556	1317	\N	\N	3357	1	domain	2026-06-20 19:40:06.354443
32557	1317	\N	\N	434	1	domain	2026-06-20 19:40:06.354443
32558	1317	\N	\N	2099	1	domain	2026-06-20 19:40:06.354443
32559	1317	\N	\N	2100	1	domain	2026-06-20 19:40:06.354443
32560	1317	\N	\N	2101	1	domain	2026-06-20 19:40:06.354443
32561	1317	\N	\N	2887	1	domain	2026-06-20 19:40:06.354443
32562	1317	\N	\N	2102	1	domain	2026-06-20 19:40:06.354443
32563	1317	\N	\N	2103	1	domain	2026-06-20 19:40:06.354443
32564	1317	\N	\N	3155	1	domain	2026-06-20 19:40:06.354443
32565	1317	\N	\N	54	1	domain	2026-06-20 19:40:06.354443
32566	1317	\N	\N	2898	1	domain	2026-06-20 19:40:06.354443
32567	1317	\N	\N	451	1	domain	2026-06-20 19:40:06.354443
32568	1317	\N	\N	452	1	domain	2026-06-20 19:40:06.354443
32569	1317	\N	\N	453	1	domain	2026-06-20 19:40:06.354443
32570	1317	\N	\N	2678	1	domain	2026-06-20 19:40:06.354443
32571	1317	\N	\N	746	1	domain	2026-06-20 19:40:06.354443
32572	1317	\N	\N	1655	1	domain	2026-06-20 19:40:06.354443
32573	1317	\N	\N	2935	1	domain	2026-06-20 19:40:06.354443
32574	1317	\N	\N	1539	1	domain	2026-06-20 19:40:06.354443
32575	1317	\N	\N	307	1	domain	2026-06-20 19:40:06.354443
32576	1317	\N	\N	109	1	domain	2026-06-20 19:40:06.354443
32577	1317	\N	\N	308	1	domain	2026-06-20 19:40:06.354443
32578	1317	\N	\N	309	1	domain	2026-06-20 19:40:06.354443
32579	1317	\N	\N	310	1	domain	2026-06-20 19:40:06.354443
32580	1317	\N	\N	311	1	domain	2026-06-20 19:40:06.354443
32581	1317	\N	\N	312	1	domain	2026-06-20 19:40:06.354443
32582	1317	\N	\N	313	1	domain	2026-06-20 19:40:06.354443
32583	1317	\N	\N	2729	1	domain	2026-06-20 19:40:06.354443
32584	1317	\N	\N	314	1	domain	2026-06-20 19:40:06.354443
32585	1317	\N	\N	315	1	domain	2026-06-20 19:40:06.354443
32586	1317	\N	\N	2180	1	domain	2026-06-20 19:40:06.354443
32587	1317	\N	\N	2184	1	domain	2026-06-20 19:40:06.354443
32588	1317	\N	\N	2745	1	domain	2026-06-20 19:40:06.354443
32589	1317	\N	\N	2766	1	domain	2026-06-20 19:40:06.354443
32590	1317	\N	\N	2046	1	domain	2026-06-20 19:40:06.354443
32591	1317	\N	\N	1349	1	domain	2026-06-20 19:40:06.354443
32592	1317	\N	\N	2045	1	domain	2026-06-20 19:40:06.354443
32593	1317	\N	\N	2047	1	domain	2026-06-20 19:40:06.354443
32594	1317	\N	\N	2059	1	domain	2026-06-20 19:40:06.354443
32595	1317	\N	\N	2274	1	domain	2026-06-20 19:40:06.354443
32596	1317	\N	\N	1336	1	domain	2026-06-20 19:40:06.354443
32597	1317	\N	\N	1337	1	domain	2026-06-20 19:40:06.354443
32598	1317	\N	\N	2291	1	domain	2026-06-20 19:40:06.354443
32599	1317	\N	\N	2297	1	domain	2026-06-20 19:40:06.354443
32600	1317	\N	\N	2382	1	domain	2026-06-20 19:40:06.354443
32601	1317	\N	\N	2417	1	domain	2026-06-20 19:40:06.354443
32602	1317	\N	\N	2539	1	domain	2026-06-20 19:40:06.354443
32604	1317	\N	\N	3259	1	domain	2026-06-20 19:40:06.370304
32605	1317	\N	\N	2508	1	domain	2026-06-20 19:40:06.370304
32606	1317	\N	\N	2525	1	domain	2026-06-20 19:40:06.370304
32607	1317	\N	\N	2536	1	domain	2026-06-20 19:40:06.370304
32608	1317	\N	\N	2537	1	domain	2026-06-20 19:40:06.370304
32609	1317	\N	\N	2540	1	domain	2026-06-20 19:40:06.370304
32610	1317	\N	\N	2553	1	domain	2026-06-20 19:40:06.370304
32611	1317	\N	\N	2567	1	domain	2026-06-20 19:40:06.370304
32613	1318	\N	\N	1860	1	domain	2026-06-20 19:40:06.384449
32614	1318	\N	\N	1835	1	domain	2026-06-20 19:40:06.384449
32615	1318	\N	\N	1836	1	domain	2026-06-20 19:40:06.384449
32616	1318	\N	\N	3374	1	domain	2026-06-20 19:40:06.384449
32617	1318	\N	\N	1866	1	domain	2026-06-20 19:40:06.384449
32618	1318	\N	\N	1841	1	domain	2026-06-20 19:40:06.384449
32619	1318	\N	\N	1867	1	domain	2026-06-20 19:40:06.384449
32620	1318	\N	\N	3331	1	domain	2026-06-20 19:40:06.384449
32621	1318	\N	\N	1877	1	domain	2026-06-20 19:40:06.384449
32622	1318	\N	\N	1878	1	domain	2026-06-20 19:40:06.384449
32623	1318	\N	\N	1879	1	domain	2026-06-20 19:40:06.384449
32624	1318	\N	\N	1882	1	domain	2026-06-20 19:40:06.384449
32625	1318	\N	\N	1883	1	domain	2026-06-20 19:40:06.384449
32626	1318	\N	\N	1664	1	domain	2026-06-20 19:40:06.384449
32627	1318	\N	\N	1884	1	domain	2026-06-20 19:40:06.384449
32628	1318	\N	\N	1411	1	domain	2026-06-20 19:40:06.384449
32629	1318	\N	\N	191	1	domain	2026-06-20 19:40:06.384449
32630	1318	\N	\N	224	1	domain	2026-06-20 19:40:06.384449
32631	1318	\N	\N	225	1	domain	2026-06-20 19:40:06.384449
32632	1318	\N	\N	379	1	domain	2026-06-20 19:40:06.384449
32633	1318	\N	\N	1574	1	domain	2026-06-20 19:40:06.384449
32634	1318	\N	\N	3346	1	domain	2026-06-20 19:40:06.384449
32635	1318	\N	\N	232	1	domain	2026-06-20 19:40:06.384449
32636	1318	\N	\N	1629	1	domain	2026-06-20 19:40:06.384449
32637	1318	\N	\N	1630	1	domain	2026-06-20 19:40:06.384449
32638	1318	\N	\N	1634	1	domain	2026-06-20 19:40:06.384449
32639	1318	\N	\N	1011	1	domain	2026-06-20 19:40:06.384449
32640	1318	\N	\N	84	1	domain	2026-06-20 19:40:06.384449
32641	1318	\N	\N	2925	1	domain	2026-06-20 19:40:06.384449
32642	1318	\N	\N	2926	1	domain	2026-06-20 19:40:06.384449
32643	1318	\N	\N	1186	1	domain	2026-06-20 19:40:06.384449
32644	1318	\N	\N	1033	1	domain	2026-06-20 19:40:06.384449
32645	1318	\N	\N	1187	1	domain	2026-06-20 19:40:06.384449
32646	1318	\N	\N	867	1	domain	2026-06-20 19:40:06.384449
32647	1318	\N	\N	138	1	domain	2026-06-20 19:40:06.384449
32648	1318	\N	\N	1275	1	domain	2026-06-20 19:40:06.384449
32649	1318	\N	\N	1276	1	domain	2026-06-20 19:40:06.384449
32650	1318	\N	\N	2362	1	domain	2026-06-20 19:40:06.384449
32651	1318	\N	\N	2366	1	domain	2026-06-20 19:40:06.384449
32652	1318	\N	\N	2370	1	domain	2026-06-20 19:40:06.384449
32654	1318	\N	\N	1861	1	domain	2026-06-20 19:40:06.402802
32655	1318	\N	\N	2163	1	domain	2026-06-20 19:40:06.402802
32656	1318	\N	\N	3324	1	domain	2026-06-20 19:40:06.402802
32657	1318	\N	\N	3325	1	domain	2026-06-20 19:40:06.402802
32658	1318	\N	\N	3326	1	domain	2026-06-20 19:40:06.402802
32659	1318	\N	\N	3327	1	domain	2026-06-20 19:40:06.402802
32660	1318	\N	\N	598	1	domain	2026-06-20 19:40:06.402802
32661	1318	\N	\N	3329	1	domain	2026-06-20 19:40:06.402802
32662	1318	\N	\N	3330	1	domain	2026-06-20 19:40:06.402802
32663	1318	\N	\N	2595	1	domain	2026-06-20 19:40:06.402802
32664	1318	\N	\N	184	1	domain	2026-06-20 19:40:06.402802
32665	1318	\N	\N	2634	1	domain	2026-06-20 19:40:06.402802
32666	1318	\N	\N	965	1	domain	2026-06-20 19:40:06.402802
32667	1318	\N	\N	3201	1	domain	2026-06-20 19:40:06.402802
32668	1318	\N	\N	1049	1	domain	2026-06-20 19:40:06.402802
32669	1318	\N	\N	374	1	domain	2026-06-20 19:40:06.402802
32670	1318	\N	\N	375	1	domain	2026-06-20 19:40:06.402802
32671	1318	\N	\N	376	1	domain	2026-06-20 19:40:06.402802
32672	1318	\N	\N	3340	1	domain	2026-06-20 19:40:06.402802
32673	1318	\N	\N	3341	1	domain	2026-06-20 19:40:06.402802
32674	1318	\N	\N	1886	1	domain	2026-06-20 19:40:06.402802
32675	1318	\N	\N	1887	1	domain	2026-06-20 19:40:06.402802
32676	1318	\N	\N	3345	1	domain	2026-06-20 19:40:06.402802
32677	1318	\N	\N	3279	1	domain	2026-06-20 19:40:06.402802
32678	1318	\N	\N	2819	1	domain	2026-06-20 19:40:06.402802
32679	1318	\N	\N	2820	1	domain	2026-06-20 19:40:06.402802
32680	1318	\N	\N	1625	1	domain	2026-06-20 19:40:06.402802
32681	1318	\N	\N	1439	1	domain	2026-06-20 19:40:06.402802
32682	1318	\N	\N	1631	1	domain	2026-06-20 19:40:06.402802
32683	1318	\N	\N	1632	1	domain	2026-06-20 19:40:06.402802
32684	1318	\N	\N	1591	1	domain	2026-06-20 19:40:06.402802
32685	1318	\N	\N	3362	1	domain	2026-06-20 19:40:06.402802
32686	1318	\N	\N	1635	1	domain	2026-06-20 19:40:06.402802
32687	1318	\N	\N	3153	1	domain	2026-06-20 19:40:06.402802
32688	1318	\N	\N	3364	1	domain	2026-06-20 19:40:06.402802
32689	1318	\N	\N	3365	1	domain	2026-06-20 19:40:06.402802
32690	1318	\N	\N	870	1	domain	2026-06-20 19:40:06.402802
32691	1318	\N	\N	1934	1	domain	2026-06-20 19:40:06.402802
32692	1318	\N	\N	1935	1	domain	2026-06-20 19:40:06.402802
32693	1318	\N	\N	1021	1	domain	2026-06-20 19:40:06.402802
32694	1318	\N	\N	1939	1	domain	2026-06-20 19:40:06.402802
32695	1318	\N	\N	829	1	domain	2026-06-20 19:40:06.402802
32696	1318	\N	\N	2164	1	domain	2026-06-20 19:40:06.402802
32697	1318	\N	\N	86	1	domain	2026-06-20 19:40:06.402802
32698	1318	\N	\N	87	1	domain	2026-06-20 19:40:06.402802
32699	1318	\N	\N	1034	1	domain	2026-06-20 19:40:06.402802
32700	1318	\N	\N	1193	1	domain	2026-06-20 19:40:06.402802
32701	1318	\N	\N	1194	1	domain	2026-06-20 19:40:06.402802
32702	1318	\N	\N	1195	1	domain	2026-06-20 19:40:06.402802
32703	1318	\N	\N	1196	1	domain	2026-06-20 19:40:06.402802
32704	1318	\N	\N	1197	1	domain	2026-06-20 19:40:06.402802
32705	1318	\N	\N	1198	1	domain	2026-06-20 19:40:06.402802
32706	1318	\N	\N	1200	1	domain	2026-06-20 19:40:06.402802
32707	1318	\N	\N	2161	1	domain	2026-06-20 19:40:06.402802
32708	1318	\N	\N	2162	1	domain	2026-06-20 19:40:06.402802
32709	1318	\N	\N	2165	1	domain	2026-06-20 19:40:06.402802
32710	1318	\N	\N	2167	1	domain	2026-06-20 19:40:06.402802
32711	1318	\N	\N	2168	1	domain	2026-06-20 19:40:06.402802
32712	1318	\N	\N	2170	1	domain	2026-06-20 19:40:06.402802
32713	1318	\N	\N	2171	1	domain	2026-06-20 19:40:06.402802
32714	1318	\N	\N	1708	1	domain	2026-06-20 19:40:06.402802
32715	1318	\N	\N	128	1	domain	2026-06-20 19:40:06.402802
32716	1318	\N	\N	2981	1	domain	2026-06-20 19:40:06.402802
32717	1318	\N	\N	2983	1	domain	2026-06-20 19:40:06.402802
32718	1318	\N	\N	2212	1	domain	2026-06-20 19:40:06.402802
32719	1318	\N	\N	3001	1	domain	2026-06-20 19:40:06.402802
32720	1318	\N	\N	1475	1	domain	2026-06-20 19:40:06.402802
32721	1318	\N	\N	3002	1	domain	2026-06-20 19:40:06.402802
32722	1318	\N	\N	3004	1	domain	2026-06-20 19:40:06.402802
32723	1318	\N	\N	3005	1	domain	2026-06-20 19:40:06.402802
32724	1318	\N	\N	3006	1	domain	2026-06-20 19:40:06.402802
32725	1318	\N	\N	3007	1	domain	2026-06-20 19:40:06.402802
32726	1318	\N	\N	3010	1	domain	2026-06-20 19:40:06.402802
32727	1318	\N	\N	3011	1	domain	2026-06-20 19:40:06.402802
32728	1318	\N	\N	2029	1	domain	2026-06-20 19:40:06.402802
32729	1318	\N	\N	2030	1	domain	2026-06-20 19:40:06.402802
32730	1318	\N	\N	3017	1	domain	2026-06-20 19:40:06.402802
32731	1318	\N	\N	3020	1	domain	2026-06-20 19:40:06.402802
32732	1318	\N	\N	3021	1	domain	2026-06-20 19:40:06.402802
32733	1318	\N	\N	3022	1	domain	2026-06-20 19:40:06.402802
32734	1318	\N	\N	3023	1	domain	2026-06-20 19:40:06.402802
32735	1318	\N	\N	3024	1	domain	2026-06-20 19:40:06.402802
32736	1318	\N	\N	2309	1	domain	2026-06-20 19:40:06.402802
32737	1318	\N	\N	2368	1	domain	2026-06-20 19:40:06.402802
32738	1318	\N	\N	2391	1	domain	2026-06-20 19:40:06.402802
32739	1318	\N	\N	2392	1	domain	2026-06-20 19:40:06.402802
32740	1318	\N	\N	2393	1	domain	2026-06-20 19:40:06.402802
32741	1318	\N	\N	2489	1	domain	2026-06-20 19:40:06.402802
32742	1318	\N	\N	2499	1	domain	2026-06-20 19:40:06.402802
32744	1318	\N	\N	3332	1	domain	2026-06-20 19:40:06.422736
32745	1318	\N	\N	187	1	domain	2026-06-20 19:40:06.422736
32746	1318	\N	\N	1588	1	domain	2026-06-20 19:40:06.422736
32747	1318	\N	\N	2924	1	domain	2026-06-20 19:40:06.422736
32748	1318	\N	\N	252	1	domain	2026-06-20 19:40:06.422736
32749	1318	\N	\N	253	1	domain	2026-06-20 19:40:06.422736
32750	1318	\N	\N	1191	1	domain	2026-06-20 19:40:06.422736
32751	1318	\N	\N	1192	1	domain	2026-06-20 19:40:06.422736
32752	1318	\N	\N	100	1	domain	2026-06-20 19:40:06.422736
32753	1318	\N	\N	2973	1	domain	2026-06-20 19:40:06.422736
32754	1318	\N	\N	1725	1	domain	2026-06-20 19:40:06.422736
32755	1318	\N	\N	2187	1	domain	2026-06-20 19:40:06.422736
32756	1318	\N	\N	2188	1	domain	2026-06-20 19:40:06.422736
32757	1318	\N	\N	2189	1	domain	2026-06-20 19:40:06.422736
32758	1318	\N	\N	2190	1	domain	2026-06-20 19:40:06.422736
32759	1318	\N	\N	2192	1	domain	2026-06-20 19:40:06.422736
32760	1318	\N	\N	2376	1	domain	2026-06-20 19:40:06.422736
32762	1319	\N	\N	3373	1	domain	2026-06-20 19:40:06.435738
32763	1319	\N	\N	1838	1	domain	2026-06-20 19:40:06.435738
32764	1319	\N	\N	3378	1	domain	2026-06-20 19:40:06.435738
32765	1319	\N	\N	1554	1	domain	2026-06-20 19:40:06.435738
32766	1319	\N	\N	2598	1	domain	2026-06-20 19:40:06.435738
32767	1319	\N	\N	186	1	domain	2026-06-20 19:40:06.435738
32768	1319	\N	\N	1820	1	domain	2026-06-20 19:40:06.435738
32769	1319	\N	\N	250	1	domain	2026-06-20 19:40:06.435738
32770	1319	\N	\N	254	1	domain	2026-06-20 19:40:06.435738
32771	1319	\N	\N	255	1	domain	2026-06-20 19:40:06.435738
32772	1319	\N	\N	256	1	domain	2026-06-20 19:40:06.435738
32773	1319	\N	\N	1010	1	domain	2026-06-20 19:40:06.435738
32774	1319	\N	\N	2909	1	domain	2026-06-20 19:40:06.435738
32775	1319	\N	\N	1928	1	domain	2026-06-20 19:40:06.435738
32776	1319	\N	\N	3242	1	domain	2026-06-20 19:40:06.435738
32777	1319	\N	\N	1930	1	domain	2026-06-20 19:40:06.435738
32778	1319	\N	\N	3243	1	domain	2026-06-20 19:40:06.435738
32779	1319	\N	\N	1166	1	domain	2026-06-20 19:40:06.435738
32780	1319	\N	\N	102	1	domain	2026-06-20 19:40:06.435738
32781	1319	\N	\N	2945	1	domain	2026-06-20 19:40:06.435738
32782	1319	\N	\N	2947	1	domain	2026-06-20 19:40:06.435738
32783	1319	\N	\N	1704	1	domain	2026-06-20 19:40:06.435738
32784	1319	\N	\N	872	1	domain	2026-06-20 19:40:06.435738
32785	1319	\N	\N	324	1	domain	2026-06-20 19:40:06.435738
32786	1319	\N	\N	325	1	domain	2026-06-20 19:40:06.435738
32787	1319	\N	\N	2762	1	domain	2026-06-20 19:40:06.435738
32788	1319	\N	\N	2019	1	domain	2026-06-20 19:40:06.435738
32789	1319	\N	\N	2020	1	domain	2026-06-20 19:40:06.435738
32790	1319	\N	\N	2022	1	domain	2026-06-20 19:40:06.435738
32791	1319	\N	\N	2023	1	domain	2026-06-20 19:40:06.435738
32792	1319	\N	\N	2024	1	domain	2026-06-20 19:40:06.435738
32793	1319	\N	\N	2781	1	domain	2026-06-20 19:40:06.435738
32794	1319	\N	\N	2782	1	domain	2026-06-20 19:40:06.435738
32795	1319	\N	\N	2783	1	domain	2026-06-20 19:40:06.435738
32796	1319	\N	\N	1302	1	domain	2026-06-20 19:40:06.435738
32797	1319	\N	\N	1303	1	domain	2026-06-20 19:40:06.435738
32798	1319	\N	\N	2303	1	domain	2026-06-20 19:40:06.435738
32799	1319	\N	\N	2341	1	domain	2026-06-20 19:40:06.435738
32800	1319	\N	\N	2408	1	domain	2026-06-20 19:40:06.435738
32801	1319	\N	\N	2411	1	domain	2026-06-20 19:40:06.435738
32802	1319	\N	\N	2413	1	domain	2026-06-20 19:40:06.435738
32804	1319	\N	\N	950	1	domain	2026-06-20 19:40:06.452586
32805	1319	\N	\N	1821	1	domain	2026-06-20 19:40:06.452586
32806	1319	\N	\N	2140	1	domain	2026-06-20 19:40:06.452586
32807	1319	\N	\N	2952	1	domain	2026-06-20 19:40:06.452586
32808	1319	\N	\N	2953	1	domain	2026-06-20 19:40:06.452586
32809	1319	\N	\N	2954	1	domain	2026-06-20 19:40:06.452586
32810	1319	\N	\N	2776	1	domain	2026-06-20 19:40:06.452586
32811	1319	\N	\N	2777	1	domain	2026-06-20 19:40:06.452586
32812	1319	\N	\N	1279	1	domain	2026-06-20 19:40:06.452586
32813	1319	\N	\N	1290	1	domain	2026-06-20 19:40:06.452586
32814	1319	\N	\N	1291	1	domain	2026-06-20 19:40:06.452586
35487	1329	\N	\N	572	1	standalone	2026-06-21 05:44:33.713754
35488	1329	\N	\N	1324	1	standalone	2026-06-21 05:44:33.713754
35489	1329	\N	\N	2326	1	standalone	2026-06-21 05:44:33.713754
35490	1329	\N	\N	2396	1	standalone	2026-06-21 05:44:33.713754
35491	1329	\N	\N	2453	1	standalone	2026-06-21 05:44:33.713754
35496	1323	\N	\N	179	1	domain	2026-06-21 05:44:33.727297
35497	1323	\N	\N	220	1	domain	2026-06-21 05:44:33.727297
35498	1323	\N	\N	1832	1	domain	2026-06-21 05:44:33.727297
35500	1323	\N	\N	2375	1	domain	2026-06-21 05:44:33.727297
35501	1323	\N	\N	1723	1	domain	2026-06-21 05:44:33.727297
35502	1323	\N	\N	2441	1	domain	2026-06-21 05:44:33.727297
35504	1323	\N	\N	219	1	domain	2026-06-21 05:44:33.743468
35505	1323	\N	\N	2601	1	domain	2026-06-21 05:44:33.743468
35506	1323	\N	\N	1909	1	domain	2026-06-21 05:44:33.743468
35508	1323	\N	\N	734	1	domain	2026-06-21 05:44:33.743468
35509	1323	\N	\N	1717	1	domain	2026-06-21 05:44:33.743468
35510	1323	\N	\N	2932	1	domain	2026-06-21 05:44:33.743468
35511	1323	\N	\N	2386	1	domain	2026-06-21 05:44:33.743468
35514	1323	\N	\N	215	1	domain	2026-06-21 05:44:33.748322
35515	1323	\N	\N	1262	1	domain	2026-06-21 05:44:33.748322
35516	1323	\N	\N	218	1	standalone	2026-06-21 05:44:33.748322
35517	1323	\N	\N	1885	1	standalone	2026-06-21 05:44:33.748322
35518	1323	\N	\N	1178	1	standalone	2026-06-21 05:44:33.748322
35519	1323	\N	\N	2222	1	standalone	2026-06-21 05:44:33.748322
35521	1323	\N	\N	3036	1	domain	2026-06-21 05:44:33.760601
35522	1323	\N	\N	2350	1	domain	2026-06-21 05:44:33.760601
35486	1329	\N	\N	895	1	domain	2026-06-21 05:44:33.713754
35485	1329	\N	\N	1730	1	domain	2026-06-21 05:44:33.713754
35484	1329	\N	\N	135	1	domain	2026-06-21 05:44:33.713754
35551	1322	\N	\N	2654	1	domain	2026-06-21 05:44:33.808149
35552	1322	\N	\N	1685	1	domain	2026-06-21 05:44:33.808149
35553	1322	\N	\N	2657	1	standalone	2026-06-21 05:44:33.808149
35554	1322	\N	\N	2665	1	standalone	2026-06-21 05:44:33.808149
35555	1322	\N	\N	2664	1	standalone	2026-06-21 05:44:33.808149
35556	1322	\N	\N	2666	1	standalone	2026-06-21 05:44:33.808149
35557	1322	\N	\N	2643	1	standalone	2026-06-21 05:44:33.808149
35558	1322	\N	\N	2645	1	standalone	2026-06-21 05:44:33.808149
35559	1322	\N	\N	2633	1	standalone	2026-06-21 05:44:33.808149
35561	1322	\N	\N	2906	1	standalone	2026-06-21 05:44:33.808149
35562	1322	\N	\N	2933	1	standalone	2026-06-21 05:44:33.808149
35563	1322	\N	\N	2902	1	standalone	2026-06-21 05:44:33.808149
35564	1322	\N	\N	2738	1	standalone	2026-06-21 05:44:33.808149
35565	1322	\N	\N	2739	1	standalone	2026-06-21 05:44:33.808149
35566	1322	\N	\N	2741	1	standalone	2026-06-21 05:44:33.808149
35567	1322	\N	\N	2746	1	standalone	2026-06-21 05:44:33.808149
35568	1322	\N	\N	2747	1	standalone	2026-06-21 05:44:33.808149
35569	1322	\N	\N	2748	1	standalone	2026-06-21 05:44:33.808149
35570	1322	\N	\N	2495	1	standalone	2026-06-21 05:44:33.808149
35571	1322	\N	\N	2496	1	standalone	2026-06-21 05:44:33.808149
35573	1322	\N	\N	368	1	domain	2026-06-21 05:44:33.824865
35575	1322	\N	\N	164	1	domain	2026-06-21 05:44:33.824865
35576	1322	\N	\N	2653	1	domain	2026-06-21 05:44:33.824865
35577	1322	\N	\N	2655	1	domain	2026-06-21 05:44:33.824865
35578	1322	\N	\N	2889	1	domain	2026-06-21 05:44:33.824865
35580	1329	\N	\N	646	1	standalone	2026-06-21 05:44:33.824865
35581	1329	\N	\N	660	1	standalone	2026-06-21 05:44:33.824865
35582	1329	\N	\N	3376	1	standalone	2026-06-21 05:44:33.824865
35583	1329	\N	\N	7011	1	standalone	2026-06-21 05:44:33.824865
35584	1329	\N	\N	3294	1	standalone	2026-06-21 05:44:33.824865
35585	1329	\N	\N	640	1	standalone	2026-06-21 05:44:33.824865
35586	1329	\N	\N	641	1	standalone	2026-06-21 05:44:33.824865
35587	1329	\N	\N	662	1	standalone	2026-06-21 05:44:33.824865
35588	1329	\N	\N	2089	1	standalone	2026-06-21 05:44:33.824865
35589	1329	\N	\N	665	1	standalone	2026-06-21 05:44:33.824865
35590	1329	\N	\N	669	1	standalone	2026-06-21 05:44:33.824865
35591	1329	\N	\N	670	1	standalone	2026-06-21 05:44:33.824865
35592	1329	\N	\N	977	1	standalone	2026-06-21 05:44:33.824865
35593	1329	\N	\N	1894	1	standalone	2026-06-21 05:44:33.824865
35594	1329	\N	\N	3141	1	standalone	2026-06-21 05:44:33.824865
35595	1329	\N	\N	676	1	standalone	2026-06-21 05:44:33.824865
35597	1329	\N	\N	440	1	standalone	2026-06-21 05:44:33.824865
35598	1329	\N	\N	441	1	standalone	2026-06-21 05:44:33.824865
35599	1329	\N	\N	442	1	standalone	2026-06-21 05:44:33.824865
35602	1329	\N	\N	742	1	standalone	2026-06-21 05:44:33.824865
35603	1329	\N	\N	743	1	standalone	2026-06-21 05:44:33.824865
35604	1329	\N	\N	744	1	standalone	2026-06-21 05:44:33.824865
35605	1329	\N	\N	3312	1	standalone	2026-06-21 05:44:33.824865
35606	1329	\N	\N	456	1	standalone	2026-06-21 05:44:33.824865
35607	1329	\N	\N	463	1	standalone	2026-06-21 05:44:33.824865
35608	1329	\N	\N	464	1	standalone	2026-06-21 05:44:33.824865
35609	1329	\N	\N	466	1	standalone	2026-06-21 05:44:33.824865
35610	1329	\N	\N	469	1	standalone	2026-06-21 05:44:33.824865
35611	1329	\N	\N	1526	1	standalone	2026-06-21 05:44:33.824865
35612	1329	\N	\N	2719	1	standalone	2026-06-21 05:44:33.824865
35613	1329	\N	\N	2721	1	standalone	2026-06-21 05:44:33.824865
35616	1329	\N	\N	2204	1	standalone	2026-06-21 05:44:33.824865
35618	1329	\N	\N	900	1	standalone	2026-06-21 05:44:33.824865
35619	1329	\N	\N	901	1	standalone	2026-06-21 05:44:33.824865
35620	1329	\N	\N	902	1	standalone	2026-06-21 05:44:33.824865
35621	1329	\N	\N	903	1	standalone	2026-06-21 05:44:33.824865
35622	1329	\N	\N	1516	1	standalone	2026-06-21 05:44:33.824865
35623	1329	\N	\N	2293	1	standalone	2026-06-21 05:44:33.824865
35624	1329	\N	\N	2390	1	standalone	2026-06-21 05:44:33.824865
35626	1329	\N	\N	7004	1	domain	2026-06-21 05:44:33.853972
35627	1329	\N	\N	675	1	domain	2026-06-21 05:44:33.853972
35628	1329	\N	\N	7005	1	standalone	2026-06-21 05:44:33.853972
35629	1329	\N	\N	7007	1	standalone	2026-06-21 05:44:33.853972
35630	1329	\N	\N	7008	1	standalone	2026-06-21 05:44:33.853972
35631	1329	\N	\N	7015	1	standalone	2026-06-21 05:44:33.853972
35633	1329	\N	\N	674	1	standalone	2026-06-21 05:44:33.853972
35634	1329	\N	\N	677	1	standalone	2026-06-21 05:44:33.853972
35636	1329	\N	\N	673	1	standalone	2026-06-21 05:44:33.853972
35638	1337	\N	\N	950	1	domain	2026-06-21 05:44:33.871348
35639	1337	\N	\N	1821	1	domain	2026-06-21 05:44:33.871348
35640	1337	\N	\N	2140	1	domain	2026-06-21 05:44:33.871348
35641	1337	\N	\N	2952	1	domain	2026-06-21 05:44:33.871348
35642	1337	\N	\N	2776	1	domain	2026-06-21 05:44:33.871348
35643	1337	\N	\N	1290	1	domain	2026-06-21 05:44:33.871348
35645	1337	\N	\N	2953	1	domain	2026-06-21 05:44:33.886497
35646	1337	\N	\N	2954	1	domain	2026-06-21 05:44:33.886497
35647	1337	\N	\N	1291	1	domain	2026-06-21 05:44:33.886497
35648	1337	\N	\N	2777	1	standalone	2026-06-21 05:44:33.886497
35649	1337	\N	\N	1279	1	standalone	2026-06-21 05:44:33.886497
35650	1327	\N	\N	2092	1	standalone	2026-06-21 05:44:33.886497
35651	1327	\N	\N	238	1	standalone	2026-06-21 05:44:33.886497
35652	1327	\N	\N	433	1	standalone	2026-06-21 05:44:33.886497
35653	1327	\N	\N	240	1	standalone	2026-06-21 05:44:33.886497
35655	1327	\N	\N	3215	1	standalone	2026-06-21 05:44:33.886497
35656	1327	\N	\N	1795	1	standalone	2026-06-21 05:44:33.886497
35657	1327	\N	\N	2920	1	standalone	2026-06-21 05:44:33.886497
35660	1327	\N	\N	1953	1	standalone	2026-06-21 05:44:33.886497
35560	1322	\N	\N	2934	1	domain	2026-06-21 05:44:33.808149
35661	1327	\N	\N	1954	1	standalone	2026-06-21 05:44:33.886497
35662	1327	\N	\N	1956	1	standalone	2026-06-21 05:44:33.886497
35663	1327	\N	\N	1958	1	standalone	2026-06-21 05:44:33.886497
35664	1327	\N	\N	1959	1	standalone	2026-06-21 05:44:33.886497
35665	1327	\N	\N	1976	1	standalone	2026-06-21 05:44:33.886497
35666	1327	\N	\N	518	1	standalone	2026-06-21 05:44:33.886497
35667	1327	\N	\N	520	1	standalone	2026-06-21 05:44:33.886497
35670	1327	\N	\N	550	1	standalone	2026-06-21 05:44:33.886497
35671	1327	\N	\N	551	1	standalone	2026-06-21 05:44:33.886497
35672	1327	\N	\N	2255	1	standalone	2026-06-21 05:44:33.886497
35673	1327	\N	\N	2269	1	standalone	2026-06-21 05:44:33.886497
35674	1327	\N	\N	687	1	standalone	2026-06-21 05:44:33.886497
35677	1327	\N	\N	3188	1	standalone	2026-06-21 05:44:33.886497
35678	1327	\N	\N	9	1	standalone	2026-06-21 05:44:33.886497
35680	1327	\N	\N	1880	1	standalone	2026-06-21 05:44:33.886497
35681	1327	\N	\N	2817	1	standalone	2026-06-21 05:44:33.886497
35682	1327	\N	\N	2818	1	standalone	2026-06-21 05:44:33.886497
35683	1327	\N	\N	3348	1	standalone	2026-06-21 05:44:33.886497
35684	1327	\N	\N	1331	1	standalone	2026-06-21 05:44:33.886497
35685	1327	\N	\N	2304	1	standalone	2026-06-21 05:44:33.886497
35686	1327	\N	\N	2373	1	standalone	2026-06-21 05:44:33.886497
35687	1327	\N	\N	2268	1	standalone	2026-06-21 05:44:33.886497
35688	1330	\N	\N	3109	1	standalone	2026-06-21 05:44:33.886497
35689	1330	\N	\N	3380	1	standalone	2026-06-21 05:44:33.886497
35691	1330	\N	\N	1333	1	domain	2026-06-21 05:44:33.896754
35692	1330	\N	\N	2513	1	domain	2026-06-21 05:44:33.896754
35693	1330	\N	\N	2516	1	domain	2026-06-21 05:44:33.896754
35694	1330	\N	\N	1334	1	standalone	2026-06-21 05:44:33.896754
35695	1330	\N	\N	1335	1	standalone	2026-06-21 05:44:33.896754
35696	1330	\N	\N	1338	1	standalone	2026-06-21 05:44:33.896754
35697	1330	\N	\N	2511	1	standalone	2026-06-21 05:44:33.896754
35698	1330	\N	\N	2512	1	standalone	2026-06-21 05:44:33.896754
35699	1330	\N	\N	2514	1	standalone	2026-06-21 05:44:33.896754
35700	1330	\N	\N	2515	1	standalone	2026-06-21 05:44:33.896754
35701	1330	\N	\N	2517	1	standalone	2026-06-21 05:44:33.896754
35702	1330	\N	\N	2518	1	standalone	2026-06-21 05:44:33.896754
35703	1330	\N	\N	2519	1	standalone	2026-06-21 05:44:33.896754
35704	1330	\N	\N	2563	1	standalone	2026-06-21 05:44:33.896754
35705	1330	\N	\N	2564	1	standalone	2026-06-21 05:44:33.896754
35706	1330	\N	\N	2565	1	standalone	2026-06-21 05:44:33.896754
35707	1330	\N	\N	2566	1	standalone	2026-06-21 05:44:33.896754
35709	1333	\N	\N	1839	1	domain	2026-06-21 05:44:33.92599
35710	1333	\N	\N	824	1	domain	2026-06-21 05:44:33.92599
35711	1333	\N	\N	1001	1	domain	2026-06-21 05:44:33.92599
35712	1335	\N	\N	2615	1	standalone	2026-06-21 05:44:33.92599
35713	1335	\N	\N	207	1	standalone	2026-06-21 05:44:33.92599
35714	1335	\N	\N	3381	1	standalone	2026-06-21 05:44:33.92599
35716	1335	\N	\N	624	1	standalone	2026-06-21 05:44:33.92599
35719	1335	\N	\N	2833	1	standalone	2026-06-21 05:44:33.92599
35720	1335	\N	\N	2834	1	standalone	2026-06-21 05:44:33.92599
35721	1335	\N	\N	1924	1	standalone	2026-06-21 05:44:33.92599
35722	1335	\N	\N	1926	1	standalone	2026-06-21 05:44:33.92599
35723	1335	\N	\N	3238	1	standalone	2026-06-21 05:44:33.92599
35724	1335	\N	\N	1933	1	standalone	2026-06-21 05:44:33.92599
35725	1335	\N	\N	1927	1	standalone	2026-06-21 05:44:33.92599
35726	1335	\N	\N	1931	1	standalone	2026-06-21 05:44:33.92599
35727	1335	\N	\N	1932	1	standalone	2026-06-21 05:44:33.92599
35728	1335	\N	\N	1168	1	standalone	2026-06-21 05:44:33.92599
35729	1335	\N	\N	1169	1	standalone	2026-06-21 05:44:33.92599
35730	1335	\N	\N	1028	1	standalone	2026-06-21 05:44:33.92599
35733	1335	\N	\N	305	1	standalone	2026-06-21 05:44:33.92599
35734	1335	\N	\N	1712	1	standalone	2026-06-21 05:44:33.92599
35735	1335	\N	\N	323	1	standalone	2026-06-21 05:44:33.92599
35736	1335	\N	\N	328	1	standalone	2026-06-21 05:44:33.92599
35737	1335	\N	\N	329	1	standalone	2026-06-21 05:44:33.92599
35738	1335	\N	\N	333	1	standalone	2026-06-21 05:44:33.92599
35739	1335	\N	\N	334	1	standalone	2026-06-21 05:44:33.92599
35741	1335	\N	\N	336	1	standalone	2026-06-21 05:44:33.92599
35742	1335	\N	\N	346	1	standalone	2026-06-21 05:44:33.92599
35744	1335	\N	\N	348	1	standalone	2026-06-21 05:44:33.92599
35745	1335	\N	\N	349	1	standalone	2026-06-21 05:44:33.92599
35747	1335	\N	\N	2015	1	standalone	2026-06-21 05:44:33.92599
35749	1335	\N	\N	2026	1	standalone	2026-06-21 05:44:33.92599
35750	1335	\N	\N	2027	1	standalone	2026-06-21 05:44:33.92599
35751	1335	\N	\N	1280	1	standalone	2026-06-21 05:44:33.92599
35753	1335	\N	\N	1305	1	standalone	2026-06-21 05:44:33.92599
35754	1335	\N	\N	1306	1	standalone	2026-06-21 05:44:33.92599
35755	1335	\N	\N	1307	1	standalone	2026-06-21 05:44:33.92599
35757	1335	\N	\N	1319	1	standalone	2026-06-21 05:44:33.92599
35758	1335	\N	\N	3090	1	standalone	2026-06-21 05:44:33.92599
35760	1335	\N	\N	2407	1	standalone	2026-06-21 05:44:33.92599
35761	1335	\N	\N	2449	1	standalone	2026-06-21 05:44:33.92599
35762	1335	\N	\N	2452	1	standalone	2026-06-21 05:44:33.92599
35763	1335	\N	\N	2542	1	standalone	2026-06-21 05:44:33.92599
35764	1335	\N	\N	2548	1	standalone	2026-06-21 05:44:33.92599
35765	1335	\N	\N	2575	1	standalone	2026-06-21 05:44:33.92599
35766	1335	\N	\N	2576	1	standalone	2026-06-21 05:44:33.92599
35668	1327	\N	\N	1239	1	domain	2026-06-21 05:44:33.886497
35675	1327	\N	\N	688	1	domain	2026-06-21 05:44:33.886497
35772	1329	\N	\N	3186	1	domain	2026-06-21 05:44:33.969237
35773	1329	\N	\N	172	1	domain	2026-06-21 05:44:33.969237
35774	1329	\N	\N	2584	1	domain	2026-06-21 05:44:33.969237
35775	1329	\N	\N	19	1	domain	2026-06-21 05:44:33.969237
35776	1329	\N	\N	813	1	domain	2026-06-21 05:44:33.969237
35778	1329	\N	\N	22	1	standalone	2026-06-21 05:44:33.969237
35779	1329	\N	\N	24	1	standalone	2026-06-21 05:44:33.969237
35780	1329	\N	\N	1514	1	standalone	2026-06-21 05:44:33.969237
35781	1329	\N	\N	1522	1	standalone	2026-06-21 05:44:33.969237
35782	1329	\N	\N	1515	1	standalone	2026-06-21 05:44:33.969237
35783	1329	\N	\N	1521	1	standalone	2026-06-21 05:44:33.969237
35784	1329	\N	\N	1520	1	standalone	2026-06-21 05:44:33.969237
35785	1329	\N	\N	2378	1	standalone	2026-06-21 05:44:33.969237
35786	1329	\N	\N	2379	1	standalone	2026-06-21 05:44:33.969237
35787	1329	\N	\N	2381	1	standalone	2026-06-21 05:44:33.969237
35788	1329	\N	\N	2448	1	standalone	2026-06-21 05:44:33.969237
35789	1329	\N	\N	2458	1	standalone	2026-06-21 05:44:33.969237
35790	1329	\N	\N	2459	1	standalone	2026-06-21 05:44:33.969237
35791	1329	\N	\N	2750	1	standalone	2026-06-21 05:44:33.969237
35793	1329	\N	\N	216	1	domain	2026-06-21 05:44:33.97833
35794	1329	\N	\N	20	1	domain	2026-06-21 05:44:33.97833
35795	1329	\N	\N	1990	1	domain	2026-06-21 05:44:33.97833
35797	1328	\N	\N	3321	1	domain	2026-06-21 05:44:33.985238
35798	1328	\N	\N	1232	1	domain	2026-06-21 05:44:33.985238
35799	1328	\N	\N	2473	1	domain	2026-06-21 05:44:33.985238
35801	1328	\N	\N	3269	1	domain	2026-06-21 05:44:33.992205
35802	1328	\N	\N	711	1	domain	2026-06-21 05:44:33.992205
35803	1328	\N	\N	1981	1	domain	2026-06-21 05:44:33.992205
35805	1328	\N	\N	1826	1	domain	2026-06-21 05:44:34.007397
35806	1328	\N	\N	3131	1	domain	2026-06-21 05:44:34.007397
35807	1328	\N	\N	990	1	domain	2026-06-21 05:44:34.007397
35809	1328	\N	\N	1674	1	domain	2026-06-21 05:44:34.007397
35810	1328	\N	\N	1985	1	domain	2026-06-21 05:44:34.007397
35812	1328	\N	\N	1677	1	domain	2026-06-21 05:44:34.017539
35813	1328	\N	\N	1986	1	domain	2026-06-21 05:44:34.017539
35814	1328	\N	\N	1987	1	domain	2026-06-21 05:44:34.017539
35815	1328	\N	\N	1988	1	domain	2026-06-21 05:44:34.017539
35820	1328	\N	\N	1982	1	standalone	2026-06-21 05:44:34.017539
35821	1328	\N	\N	1983	1	standalone	2026-06-21 05:44:34.017539
35822	1328	\N	\N	1984	1	standalone	2026-06-21 05:44:34.017539
35826	1322	\N	\N	3187	1	domain	2026-06-21 05:44:34.047416
35827	1322	\N	\N	953	1	domain	2026-06-21 05:44:34.047416
35828	1322	\N	\N	17	1	domain	2026-06-21 05:44:34.047416
35829	1322	\N	\N	812	1	domain	2026-06-21 05:44:34.047416
35830	1322	\N	\N	1683	1	domain	2026-06-21 05:44:34.047416
35831	1322	\N	\N	2288	1	domain	2026-06-21 05:44:34.047416
35833	1322	\N	\N	3256	1	domain	2026-06-21 05:44:34.063154
35834	1322	\N	\N	3176	1	domain	2026-06-21 05:44:34.063154
35835	1322	\N	\N	2147	1	domain	2026-06-21 05:44:34.063154
35836	1322	\N	\N	104	1	domain	2026-06-21 05:44:34.063154
35837	1322	\N	\N	105	1	domain	2026-06-21 05:44:34.063154
35838	1322	\N	\N	107	1	domain	2026-06-21 05:44:34.063154
35840	1333	\N	\N	594	1	standalone	2026-06-21 05:44:34.063154
35842	1333	\N	\N	954	1	domain	2026-06-21 05:44:34.06894
35843	1333	\N	\N	781	1	domain	2026-06-21 05:44:34.06894
35844	1333	\N	\N	13	1	standalone	2026-06-21 05:44:34.06894
35845	1333	\N	\N	14	1	standalone	2026-06-21 05:44:34.06894
35847	1333	\N	\N	16	1	domain	2026-06-21 05:44:34.06894
35848	1333	\N	\N	811	1	domain	2026-06-21 05:44:34.06894
35849	1333	\N	\N	21	1	standalone	2026-06-21 05:44:34.06894
35853	1333	\N	\N	229	1	standalone	2026-06-21 05:44:34.080816
35854	1333	\N	\N	35	1	standalone	2026-06-21 05:44:34.080816
35855	1333	\N	\N	997	1	standalone	2026-06-21 05:44:34.080816
35856	1333	\N	\N	998	1	standalone	2026-06-21 05:44:34.080816
35858	1333	\N	\N	2960	1	standalone	2026-06-21 05:44:34.080816
35859	1333	\N	\N	2357	1	standalone	2026-06-21 05:44:34.080816
35861	1334	\N	\N	1552	1	standalone	2026-06-21 05:44:34.080816
35863	1334	\N	\N	142	1	standalone	2026-06-21 05:44:34.080816
35864	1334	\N	\N	144	1	standalone	2026-06-21 05:44:34.080816
35868	1334	\N	\N	147	1	standalone	2026-06-21 05:44:34.080816
35875	1329	\N	\N	173	1	domain	2026-06-21 05:44:34.115046
35876	1329	\N	\N	2594	1	domain	2026-06-21 05:44:34.115046
35877	1329	\N	\N	214	1	domain	2026-06-21 05:44:34.115046
35878	1329	\N	\N	36	1	domain	2026-06-21 05:44:34.115046
35879	1329	\N	\N	719	1	domain	2026-06-21 05:44:34.115046
35880	1329	\N	\N	3291	1	domain	2026-06-21 05:44:34.115046
35881	1329	\N	\N	3298	1	domain	2026-06-21 05:44:34.115046
35823	1328	\N	\N	3211	1	domain	2026-06-21 05:44:34.017539
35857	1333	\N	\N	2908	1	domain	2026-06-21 05:44:34.080816
35860	1334	\N	\N	1551	1	domain	2026-06-21 05:44:34.080816
35862	1334	\N	\N	1824	1	domain	2026-06-21 05:44:34.080816
35865	1334	\N	\N	1735	1	domain	2026-06-21 05:44:34.080816
35866	1334	\N	\N	145	1	domain	2026-06-21 05:44:34.080816
35867	1334	\N	\N	1736	1	domain	2026-06-21 05:44:34.080816
35884	1329	\N	\N	2709	1	domain	2026-06-21 05:44:34.115046
35885	1329	\N	\N	2755	1	domain	2026-06-21 05:44:34.115046
35886	1329	\N	\N	1266	1	domain	2026-06-21 05:44:34.115046
35889	1329	\N	\N	37	1	domain	2026-06-21 05:44:34.122044
35890	1329	\N	\N	39	1	domain	2026-06-21 05:44:34.122044
35891	1329	\N	\N	720	1	domain	2026-06-21 05:44:34.122044
35895	1329	\N	\N	1672	1	domain	2026-06-21 05:44:34.122044
35899	1329	\N	\N	843	1	domain	2026-06-21 05:44:34.122044
35903	1329	\N	\N	38	1	domain	2026-06-21 05:44:34.148073
35904	1329	\N	\N	826	1	domain	2026-06-21 05:44:34.148073
35905	1329	\N	\N	2463	1	domain	2026-06-21 05:44:34.148073
35906	1329	\N	\N	2464	1	domain	2026-06-21 05:44:34.148073
35907	1329	\N	\N	2465	1	domain	2026-06-21 05:44:34.148073
35908	1329	\N	\N	2466	1	domain	2026-06-21 05:44:34.148073
35909	1329	\N	\N	1002	1	standalone	2026-06-21 05:44:34.148073
35910	1329	\N	\N	1012	1	standalone	2026-06-21 05:44:34.148073
35912	1329	\N	\N	3270	1	domain	2026-06-21 05:44:34.16924
35913	1329	\N	\N	2711	1	domain	2026-06-21 05:44:34.16924
35915	1326	\N	\N	3377	1	standalone	2026-06-21 05:44:34.16924
35916	1326	\N	\N	1868	1	standalone	2026-06-21 05:44:34.16924
35917	1326	\N	\N	1869	1	standalone	2026-06-21 05:44:34.16924
35918	1326	\N	\N	1870	1	standalone	2026-06-21 05:44:34.16924
35919	1326	\N	\N	1603	1	standalone	2026-06-21 05:44:34.16924
35920	1326	\N	\N	1871	1	standalone	2026-06-21 05:44:34.16924
35921	1326	\N	\N	1872	1	standalone	2026-06-21 05:44:34.16924
35922	1326	\N	\N	762	1	standalone	2026-06-21 05:44:34.16924
35923	1326	\N	\N	1875	1	standalone	2026-06-21 05:44:34.16924
35924	1326	\N	\N	1876	1	standalone	2026-06-21 05:44:34.16924
35925	1326	\N	\N	3124	1	standalone	2026-06-21 05:44:34.16924
35926	1326	\N	\N	3271	1	standalone	2026-06-21 05:44:34.16924
35928	1326	\N	\N	3392	1	standalone	2026-06-21 05:44:34.16924
35931	1326	\N	\N	3133	1	standalone	2026-06-21 05:44:34.16924
35932	1326	\N	\N	1573	1	standalone	2026-06-21 05:44:34.16924
35933	1326	\N	\N	1829	1	standalone	2026-06-21 05:44:34.16924
35934	1326	\N	\N	227	1	standalone	2026-06-21 05:44:34.16924
35935	1326	\N	\N	228	1	standalone	2026-06-21 05:44:34.16924
35936	1326	\N	\N	3134	1	standalone	2026-06-21 05:44:34.16924
35937	1326	\N	\N	3149	1	standalone	2026-06-21 05:44:34.16924
35938	1326	\N	\N	2830	1	standalone	2026-06-21 05:44:34.16924
35939	1326	\N	\N	448	1	standalone	2026-06-21 05:44:34.16924
35940	1326	\N	\N	450	1	standalone	2026-06-21 05:44:34.16924
35943	1326	\N	\N	2928	1	standalone	2026-06-21 05:44:34.16924
35944	1326	\N	\N	2929	1	standalone	2026-06-21 05:44:34.16924
35945	1326	\N	\N	288	1	standalone	2026-06-21 05:44:34.16924
35946	1326	\N	\N	290	1	standalone	2026-06-21 05:44:34.16924
35949	1326	\N	\N	293	1	standalone	2026-06-21 05:44:34.16924
35950	1326	\N	\N	298	1	standalone	2026-06-21 05:44:34.16924
35951	1326	\N	\N	299	1	standalone	2026-06-21 05:44:34.16924
35952	1326	\N	\N	303	1	standalone	2026-06-21 05:44:34.16924
35955	1326	\N	\N	1716	1	standalone	2026-06-21 05:44:34.16924
35956	1326	\N	\N	2208	1	standalone	2026-06-21 05:44:34.16924
35957	1326	\N	\N	2768	1	standalone	2026-06-21 05:44:34.16924
35958	1326	\N	\N	1267	1	standalone	2026-06-21 05:44:34.16924
35959	1326	\N	\N	1272	1	standalone	2026-06-21 05:44:34.16924
35960	1326	\N	\N	2028	1	standalone	2026-06-21 05:44:34.16924
35961	1326	\N	\N	2295	1	standalone	2026-06-21 05:44:34.16924
35962	1326	\N	\N	2301	1	standalone	2026-06-21 05:44:34.16924
35963	1326	\N	\N	2306	1	standalone	2026-06-21 05:44:34.16924
35964	1326	\N	\N	2319	1	standalone	2026-06-21 05:44:34.16924
35965	1326	\N	\N	2320	1	standalone	2026-06-21 05:44:34.16924
35966	1326	\N	\N	2321	1	standalone	2026-06-21 05:44:34.16924
35967	1326	\N	\N	2328	1	standalone	2026-06-21 05:44:34.16924
35968	1326	\N	\N	2329	1	standalone	2026-06-21 05:44:34.16924
35969	1326	\N	\N	2330	1	standalone	2026-06-21 05:44:34.16924
35970	1326	\N	\N	2343	1	standalone	2026-06-21 05:44:34.16924
35971	1326	\N	\N	2355	1	standalone	2026-06-21 05:44:34.16924
35972	1326	\N	\N	2424	1	standalone	2026-06-21 05:44:34.16924
35973	1326	\N	\N	2425	1	standalone	2026-06-21 05:44:34.16924
35974	1326	\N	\N	2427	1	standalone	2026-06-21 05:44:34.16924
35976	1326	\N	\N	2828	1	domain	2026-06-21 05:44:34.193438
35977	1326	\N	\N	1022	1	domain	2026-06-21 05:44:34.193438
35978	1326	\N	\N	1023	1	domain	2026-06-21 05:44:34.193438
35980	1322	\N	\N	1553	1	domain	2026-06-21 05:44:34.201483
35981	1322	\N	\N	1709	1	domain	2026-06-21 05:44:34.201483
35982	1322	\N	\N	1737	1	domain	2026-06-21 05:44:34.201483
35984	1322	\N	\N	371	1	domain	2026-06-21 05:44:34.209524
35985	1322	\N	\N	2992	1	domain	2026-06-21 05:44:34.209524
35986	1322	\N	\N	2993	1	domain	2026-06-21 05:44:34.209524
35987	1322	\N	\N	2119	1	standalone	2026-06-21 05:44:34.209524
35988	1322	\N	\N	317	1	standalone	2026-06-21 05:44:34.209524
35989	1322	\N	\N	318	1	standalone	2026-06-21 05:44:34.209524
35990	1322	\N	\N	319	1	standalone	2026-06-21 05:44:34.209524
35991	1322	\N	\N	320	1	standalone	2026-06-21 05:44:34.209524
35992	1322	\N	\N	2989	1	standalone	2026-06-21 05:44:34.209524
35993	1322	\N	\N	2990	1	standalone	2026-06-21 05:44:34.209524
35994	1322	\N	\N	2991	1	standalone	2026-06-21 05:44:34.209524
35927	1326	\N	\N	189	1	domain	2026-06-21 05:44:34.16924
35914	1326	\N	\N	1842	1	domain	2026-06-21 05:44:34.16924
35930	1326	\N	\N	3132	1	domain	2026-06-21 05:44:34.16924
35941	1326	\N	\N	3236	1	domain	2026-06-21 05:44:34.16924
35947	1326	\N	\N	840	1	domain	2026-06-21 05:44:34.16924
35953	1326	\N	\N	119	1	domain	2026-06-21 05:44:34.16924
35929	1326	\N	\N	771	1	domain	2026-06-21 05:44:34.16924
35942	1326	\N	\N	3237	1	domain	2026-06-21 05:44:34.16924
35948	1326	\N	\N	841	1	domain	2026-06-21 05:44:34.16924
35954	1326	\N	\N	120	1	domain	2026-06-21 05:44:34.16924
35995	1322	\N	\N	2996	1	standalone	2026-06-21 05:44:34.209524
35996	1322	\N	\N	2997	1	standalone	2026-06-21 05:44:34.209524
35997	1322	\N	\N	2998	1	standalone	2026-06-21 05:44:34.209524
35998	1322	\N	\N	2999	1	standalone	2026-06-21 05:44:34.209524
35999	1322	\N	\N	2051	1	standalone	2026-06-21 05:44:34.209524
36000	1322	\N	\N	2481	1	standalone	2026-06-21 05:44:34.209524
36001	1322	\N	\N	2507	1	standalone	2026-06-21 05:44:34.209524
36002	1322	\N	\N	2483	1	standalone	2026-06-21 05:44:34.209524
36003	1322	\N	\N	2484	1	standalone	2026-06-21 05:44:34.209524
36004	1322	\N	\N	2502	1	standalone	2026-06-21 05:44:34.209524
36005	1322	\N	\N	2503	1	standalone	2026-06-21 05:44:34.209524
36006	1322	\N	\N	2994	1	standalone	2026-06-21 05:44:34.209524
36007	1322	\N	\N	2995	1	standalone	2026-06-21 05:44:34.209524
36009	1329	\N	\N	369	1	domain	2026-06-21 05:44:34.225412
36010	1329	\N	\N	3305	1	domain	2026-06-21 05:44:34.225412
36014	1326	\N	\N	1602	1	domain	2026-06-21 05:44:34.225412
36015	1326	\N	\N	2280	1	domain	2026-06-21 05:44:34.225412
36017	1326	\N	\N	2602	1	domain	2026-06-21 05:44:34.242744
36018	1326	\N	\N	1243	1	domain	2026-06-21 05:44:34.242744
36020	1326	\N	\N	3130	1	domain	2026-06-21 05:44:34.255245
36021	1326	\N	\N	2931	1	domain	2026-06-21 05:44:34.255245
36022	1326	\N	\N	1827	1	standalone	2026-06-21 05:44:34.255245
36023	1326	\N	\N	987	1	standalone	2026-06-21 05:44:34.255245
36024	1326	\N	\N	294	1	standalone	2026-06-21 05:44:34.255245
36025	1326	\N	\N	2281	1	standalone	2026-06-21 05:44:34.255245
36026	1326	\N	\N	2282	1	standalone	2026-06-21 05:44:34.255245
36027	1326	\N	\N	2284	1	standalone	2026-06-21 05:44:34.255245
36028	1326	\N	\N	2285	1	standalone	2026-06-21 05:44:34.255245
36029	1326	\N	\N	2349	1	standalone	2026-06-21 05:44:34.255245
36030	1326	\N	\N	2313	1	standalone	2026-06-21 05:44:34.255245
36031	1326	\N	\N	2347	1	standalone	2026-06-21 05:44:34.255245
36032	1326	\N	\N	2352	1	standalone	2026-06-21 05:44:34.255245
36033	1326	\N	\N	2354	1	standalone	2026-06-21 05:44:34.255245
36034	1326	\N	\N	2488	1	standalone	2026-06-21 05:44:34.255245
36036	1329	\N	\N	955	1	domain	2026-06-21 05:44:34.266242
36037	1329	\N	\N	956	1	domain	2026-06-21 05:44:34.266242
36038	1329	\N	\N	814	1	domain	2026-06-21 05:44:34.266242
36040	1325	\N	\N	3190	1	domain	2026-06-21 05:44:34.274388
36041	1325	\N	\N	776	1	domain	2026-06-21 05:44:34.274388
36042	1325	\N	\N	982	1	domain	2026-06-21 05:44:34.274388
36044	1324	\N	\N	3259	1	domain	2026-06-21 05:44:34.32304
36045	1324	\N	\N	2508	1	domain	2026-06-21 05:44:34.32304
36046	1324	\N	\N	2525	1	domain	2026-06-21 05:44:34.32304
36047	1324	\N	\N	2536	1	domain	2026-06-21 05:44:34.32304
36048	1324	\N	\N	2537	1	domain	2026-06-21 05:44:34.32304
36049	1324	\N	\N	2540	1	domain	2026-06-21 05:44:34.32304
36050	1324	\N	\N	2553	1	domain	2026-06-21 05:44:34.32304
36051	1324	\N	\N	2567	1	domain	2026-06-21 05:44:34.32304
36053	1331	\N	\N	1219	1	domain	2026-06-21 05:44:34.338931
36054	1331	\N	\N	1220	1	domain	2026-06-21 05:44:34.338931
36055	1331	\N	\N	2807	1	domain	2026-06-21 05:44:34.338931
36056	1331	\N	\N	706	1	domain	2026-06-21 05:44:34.338931
36057	1331	\N	\N	1584	1	domain	2026-06-21 05:44:34.338931
36058	1331	\N	\N	882	1	domain	2026-06-21 05:44:34.338931
36059	1331	\N	\N	162	1	domain	2026-06-21 05:44:34.338931
36062	1331	\N	\N	1221	1	domain	2026-06-21 05:44:34.338931
36063	1331	\N	\N	621	1	domain	2026-06-21 05:44:34.338931
36064	1331	\N	\N	2148	1	domain	2026-06-21 05:44:34.338931
36065	1331	\N	\N	2149	1	domain	2026-06-21 05:44:34.338931
36066	1331	\N	\N	2946	1	domain	2026-06-21 05:44:34.338931
36067	1331	\N	\N	3074	1	domain	2026-06-21 05:44:34.338931
36068	1331	\N	\N	3075	1	domain	2026-06-21 05:44:34.338931
36070	1331	\N	\N	935	1	domain	2026-06-21 05:44:34.362521
36071	1331	\N	\N	3248	1	domain	2026-06-21 05:44:34.362521
36072	1331	\N	\N	3058	1	domain	2026-06-21 05:44:34.362521
36073	1331	\N	\N	3059	1	domain	2026-06-21 05:44:34.362521
36074	1331	\N	\N	3061	1	domain	2026-06-21 05:44:34.362521
36075	1331	\N	\N	3062	1	domain	2026-06-21 05:44:34.362521
36076	1331	\N	\N	3064	1	domain	2026-06-21 05:44:34.362521
36077	1331	\N	\N	3077	1	domain	2026-06-21 05:44:34.362521
36078	1331	\N	\N	3073	1	domain	2026-06-21 05:44:34.362521
36079	1331	\N	\N	3076	1	domain	2026-06-21 05:44:34.362521
36081	1331	\N	\N	936	1	domain	2026-06-21 05:44:34.371983
36082	1331	\N	\N	942	1	domain	2026-06-21 05:44:34.371983
36083	1331	\N	\N	2223	1	domain	2026-06-21 05:44:34.371983
36085	1331	\N	\N	3078	1	domain	2026-06-21 05:44:34.371983
36086	1331	\N	\N	3079	1	domain	2026-06-21 05:44:34.371983
36087	1331	\N	\N	3080	1	domain	2026-06-21 05:44:34.371983
36088	1331	\N	\N	2182	1	standalone	2026-06-21 05:44:34.371983
36090	1331	\N	\N	934	1	domain	2026-06-21 05:44:34.386706
36091	1331	\N	\N	1217	1	domain	2026-06-21 05:44:34.386706
36093	1326	\N	\N	1845	1	domain	2026-06-21 05:44:34.394392
36094	1326	\N	\N	3148	1	domain	2026-06-21 05:44:34.394392
36096	1326	\N	\N	760	1	domain	2026-06-21 05:44:34.405374
36097	1326	\N	\N	2600	1	domain	2026-06-21 05:44:34.405374
36098	1326	\N	\N	1024	1	domain	2026-06-21 05:44:34.405374
36099	1326	\N	\N	121	1	domain	2026-06-21 05:44:34.405374
36100	1326	\N	\N	1268	1	domain	2026-06-21 05:44:34.405374
36101	1326	\N	\N	573	1	domain	2026-06-21 05:44:34.405374
36103	1333	\N	\N	211	1	domain	2026-06-21 05:44:34.412677
36104	1333	\N	\N	1523	1	domain	2026-06-21 05:44:34.412677
36105	1333	\N	\N	1385	1	domain	2026-06-21 05:44:34.412677
36106	1333	\N	\N	1517	1	domain	2026-06-21 05:44:34.412677
36109	1332	\N	\N	3261	1	domain	2026-06-21 05:44:34.426831
36110	1332	\N	\N	3262	1	domain	2026-06-21 05:44:34.426831
36111	1332	\N	\N	1623	1	domain	2026-06-21 05:44:34.426831
36112	1332	\N	\N	3177	1	domain	2026-06-21 05:44:34.426831
36113	1332	\N	\N	3358	1	domain	2026-06-21 05:44:34.426831
36115	1326	\N	\N	761	1	domain	2026-06-21 05:44:34.426831
36116	1326	\N	\N	304	1	domain	2026-06-21 05:44:34.426831
36118	1326	\N	\N	1270	1	domain	2026-06-21 05:44:34.426831
36119	1326	\N	\N	2251	1	domain	2026-06-21 05:44:34.426831
36122	1327	\N	\N	959	1	domain	2026-06-21 05:44:34.442906
36123	1327	\N	\N	1825	1	domain	2026-06-21 05:44:34.442906
36125	1327	\N	\N	1585	1	domain	2026-06-21 05:44:34.442906
36128	1327	\N	\N	1537	1	domain	2026-06-21 05:44:34.442906
36130	1332	\N	\N	366	1	domain	2026-06-21 05:44:34.442906
36131	1332	\N	\N	1162	1	domain	2026-06-21 05:44:34.442906
36132	1332	\N	\N	2948	1	domain	2026-06-21 05:44:34.442906
36133	1332	\N	\N	2986	1	domain	2026-06-21 05:44:34.442906
36134	1332	\N	\N	2982	1	domain	2026-06-21 05:44:34.442906
36136	1322	\N	\N	2069	1	domain	2026-06-21 05:44:34.459896
36137	1322	\N	\N	3179	1	domain	2026-06-21 05:44:34.459896
36138	1322	\N	\N	788	1	domain	2026-06-21 05:44:34.459896
36139	1322	\N	\N	2865	1	standalone	2026-06-21 05:44:34.459896
36140	1322	\N	\N	3178	1	standalone	2026-06-21 05:44:34.459896
36141	1322	\N	\N	2098	1	standalone	2026-06-21 05:44:34.459896
36142	1322	\N	\N	1907	1	standalone	2026-06-21 05:44:34.459896
36143	1322	\N	\N	1908	1	standalone	2026-06-21 05:44:34.459896
36144	1322	\N	\N	2891	1	standalone	2026-06-21 05:44:34.459896
36145	1322	\N	\N	1681	1	standalone	2026-06-21 05:44:34.459896
36146	1322	\N	\N	1689	1	standalone	2026-06-21 05:44:34.459896
36147	1322	\N	\N	1696	1	standalone	2026-06-21 05:44:34.459896
36148	1322	\N	\N	1701	1	standalone	2026-06-21 05:44:34.459896
36149	1322	\N	\N	1706	1	standalone	2026-06-21 05:44:34.459896
36150	1322	\N	\N	1724	1	standalone	2026-06-21 05:44:34.459896
36151	1322	\N	\N	1997	1	standalone	2026-06-21 05:44:34.459896
36152	1322	\N	\N	1998	1	standalone	2026-06-21 05:44:34.459896
36153	1322	\N	\N	2290	1	standalone	2026-06-21 05:44:34.459896
36154	1322	\N	\N	1622	1	standalone	2026-06-21 05:44:34.459896
36157	1330	\N	\N	3385	1	domain	2026-06-21 05:44:34.475881
36158	1330	\N	\N	1561	1	domain	2026-06-21 05:44:34.475881
36159	1330	\N	\N	244	1	domain	2026-06-21 05:44:34.475881
36160	1330	\N	\N	245	1	domain	2026-06-21 05:44:34.475881
36161	1330	\N	\N	246	1	domain	2026-06-21 05:44:34.475881
36162	1330	\N	\N	1237	1	domain	2026-06-21 05:44:34.475881
36163	1330	\N	\N	2261	1	domain	2026-06-21 05:44:34.475881
36164	1330	\N	\N	1322	1	domain	2026-06-21 05:44:34.475881
36165	1330	\N	\N	2348	1	domain	2026-06-21 05:44:34.475881
36166	1330	\N	\N	2543	1	domain	2026-06-21 05:44:34.475881
36167	1330	\N	\N	2562	1	domain	2026-06-21 05:44:34.475881
36169	1330	\N	\N	764	1	domain	2026-06-21 05:44:34.486965
36170	1330	\N	\N	3121	1	domain	2026-06-21 05:44:34.486965
36171	1330	\N	\N	3123	1	domain	2026-06-21 05:44:34.486965
36173	1330	\N	\N	731	1	domain	2026-06-21 05:44:34.486965
36174	1330	\N	\N	71	1	domain	2026-06-21 05:44:34.486965
36176	1330	\N	\N	1598	1	domain	2026-06-21 05:44:34.499906
36177	1330	\N	\N	3125	1	domain	2026-06-21 05:44:34.499906
36178	1330	\N	\N	2267	1	domain	2026-06-21 05:44:34.499906
36179	1330	\N	\N	3150	1	standalone	2026-06-21 05:44:34.499906
36181	1330	\N	\N	1647	1	domain	2026-06-21 05:44:34.508492
36182	1330	\N	\N	1968	1	domain	2026-06-21 05:44:34.508492
36183	1330	\N	\N	1648	1	standalone	2026-06-21 05:44:34.508492
36184	1330	\N	\N	1653	1	standalone	2026-06-21 05:44:34.508492
36185	1330	\N	\N	1649	1	standalone	2026-06-21 05:44:34.508492
36186	1330	\N	\N	1651	1	standalone	2026-06-21 05:44:34.508492
36188	1330	\N	\N	2263	1	standalone	2026-06-21 05:44:34.508492
36189	1330	\N	\N	1325	1	standalone	2026-06-21 05:44:34.508492
36190	1330	\N	\N	1326	1	standalone	2026-06-21 05:44:34.508492
36191	1330	\N	\N	1329	1	standalone	2026-06-21 05:44:34.508492
36192	1330	\N	\N	2544	1	standalone	2026-06-21 05:44:34.508492
36193	1330	\N	\N	2554	1	standalone	2026-06-21 05:44:34.508492
36194	1330	\N	\N	2559	1	standalone	2026-06-21 05:44:34.508492
36195	1330	\N	\N	2545	1	standalone	2026-06-21 05:44:34.508492
36200	1338	\N	\N	1849	1	domain	2026-06-21 05:44:34.521835
36201	1338	\N	\N	701	1	domain	2026-06-21 05:44:34.521835
36202	1338	\N	\N	2604	1	domain	2026-06-21 05:44:34.521835
36203	1338	\N	\N	192	1	domain	2026-06-21 05:44:34.521835
36204	1338	\N	\N	1661	1	domain	2026-06-21 05:44:34.521835
36205	1338	\N	\N	2056	1	domain	2026-06-21 05:44:34.521835
36207	1338	\N	\N	931	1	domain	2026-06-21 05:44:34.532633
36208	1338	\N	\N	1590	1	domain	2026-06-21 05:44:34.532633
36209	1338	\N	\N	3388	1	domain	2026-06-21 05:44:34.532633
36211	1338	\N	\N	1656	1	domain	2026-06-21 05:44:34.540793
36212	1338	\N	\N	2057	1	domain	2026-06-21 05:44:34.540793
36214	1338	\N	\N	1657	1	domain	2026-06-21 05:44:34.548301
36215	1338	\N	\N	2775	1	domain	2026-06-21 05:44:34.548301
36216	1338	\N	\N	1299	1	domain	2026-06-21 05:44:34.548301
36217	1338	\N	\N	2062	1	domain	2026-06-21 05:44:34.548301
36218	1338	\N	\N	1660	1	standalone	2026-06-21 05:44:34.548301
36219	1338	\N	\N	2058	1	standalone	2026-06-21 05:44:34.548301
36220	1338	\N	\N	2060	1	standalone	2026-06-21 05:44:34.548301
36221	1338	\N	\N	2061	1	standalone	2026-06-21 05:44:34.548301
36222	1338	\N	\N	2426	1	standalone	2026-06-21 05:44:34.548301
36223	1338	\N	\N	2430	1	standalone	2026-06-21 05:44:34.548301
36224	1338	\N	\N	2014	1	standalone	2026-06-21 05:44:34.548301
36155	1330	\N	\N	960	1	domain	2026-06-21 05:44:34.459896
36187	1330	\N	\N	1652	1	domain	2026-06-21 05:44:34.508492
36226	1330	\N	\N	698	1	domain	2026-06-21 05:44:34.548301
36227	1330	\N	\N	1658	1	domain	2026-06-21 05:44:34.548301
36230	1336	\N	\N	3332	1	domain	2026-06-21 05:44:34.566037
36231	1336	\N	\N	1588	1	domain	2026-06-21 05:44:34.566037
36232	1336	\N	\N	1191	1	domain	2026-06-21 05:44:34.566037
36236	1336	\N	\N	187	1	domain	2026-06-21 05:44:34.573818
36238	1336	\N	\N	2188	1	domain	2026-06-21 05:44:34.573818
36239	1336	\N	\N	2376	1	domain	2026-06-21 05:44:34.573818
36240	1336	\N	\N	252	1	standalone	2026-06-21 05:44:34.573818
36241	1336	\N	\N	253	1	standalone	2026-06-21 05:44:34.573818
36243	1336	\N	\N	1192	1	domain	2026-06-21 05:44:34.580196
36244	1336	\N	\N	2190	1	domain	2026-06-21 05:44:34.580196
36245	1336	\N	\N	2189	1	standalone	2026-06-21 05:44:34.580196
36246	1336	\N	\N	2192	1	standalone	2026-06-21 05:44:34.580196
36248	1336	\N	\N	100	1	domain	2026-06-21 05:44:34.588411
36249	1336	\N	\N	1725	1	domain	2026-06-21 05:44:34.588411
36251	1338	\N	\N	1851	1	domain	2026-06-21 05:44:34.594443
36252	1338	\N	\N	194	1	domain	2026-06-21 05:44:34.594443
36253	1338	\N	\N	1300	1	domain	2026-06-21 05:44:34.594443
36254	1338	\N	\N	2431	1	domain	2026-06-21 05:44:34.594443
36256	1338	\N	\N	605	1	domain	2026-06-21 05:44:34.606516
36258	1338	\N	\N	2153	1	domain	2026-06-21 05:44:34.606516
36259	1338	\N	\N	2359	1	domain	2026-06-21 05:44:34.606516
36261	1331	\N	\N	3335	1	domain	2026-06-21 05:44:34.620015
36262	1331	\N	\N	1414	1	domain	2026-06-21 05:44:34.620015
36263	1331	\N	\N	3398	1	domain	2026-06-21 05:44:34.620015
36264	1331	\N	\N	722	1	domain	2026-06-21 05:44:34.620015
36265	1331	\N	\N	1645	1	domain	2026-06-21 05:44:34.620015
36266	1331	\N	\N	283	1	domain	2026-06-21 05:44:34.620015
36267	1331	\N	\N	286	1	domain	2026-06-21 05:44:34.620015
36268	1331	\N	\N	287	1	domain	2026-06-21 05:44:34.620015
36270	1338	\N	\N	1567	1	standalone	2026-06-21 05:44:34.620015
36271	1338	\N	\N	613	1	standalone	2026-06-21 05:44:34.620015
36272	1338	\N	\N	614	1	standalone	2026-06-21 05:44:34.620015
36276	1338	\N	\N	3226	1	standalone	2026-06-21 05:44:34.620015
36280	1338	\N	\N	2943	1	standalone	2026-06-21 05:44:34.620015
36283	1338	\N	\N	2181	1	standalone	2026-06-21 05:44:34.620015
36284	1338	\N	\N	876	1	standalone	2026-06-21 05:44:34.620015
36285	1338	\N	\N	527	1	standalone	2026-06-21 05:44:34.620015
36286	1338	\N	\N	338	1	standalone	2026-06-21 05:44:34.620015
36287	1338	\N	\N	339	1	standalone	2026-06-21 05:44:34.620015
36288	1338	\N	\N	342	1	standalone	2026-06-21 05:44:34.620015
36290	1338	\N	\N	158	1	standalone	2026-06-21 05:44:34.620015
36291	1338	\N	\N	2527	1	standalone	2026-06-21 05:44:34.620015
36292	1338	\N	\N	2528	1	standalone	2026-06-21 05:44:34.620015
36293	1338	\N	\N	2529	1	standalone	2026-06-21 05:44:34.620015
36294	1338	\N	\N	2531	1	standalone	2026-06-21 05:44:34.620015
36295	1338	\N	\N	2533	1	standalone	2026-06-21 05:44:34.620015
36296	1338	\N	\N	2534	1	standalone	2026-06-21 05:44:34.620015
36297	1338	\N	\N	2535	1	standalone	2026-06-21 05:44:34.620015
36300	1338	\N	\N	1565	1	domain	2026-06-21 05:44:34.637151
36301	1338	\N	\N	1566	1	domain	2026-06-21 05:44:34.637151
36302	1338	\N	\N	2605	1	domain	2026-06-21 05:44:34.637151
36303	1338	\N	\N	193	1	domain	2026-06-21 05:44:34.637151
36304	1338	\N	\N	616	1	domain	2026-06-21 05:44:34.637151
36305	1338	\N	\N	529	1	domain	2026-06-21 05:44:34.637151
36307	1329	\N	\N	661	1	domain	2026-06-21 05:44:34.637151
36308	1329	\N	\N	415	1	domain	2026-06-21 05:44:34.637151
36309	1329	\N	\N	1013	1	domain	2026-06-21 05:44:34.637151
36311	1333	\N	\N	373	1	domain	2026-06-21 05:44:34.644599
36312	1333	\N	\N	835	1	domain	2026-06-21 05:44:34.644599
36313	1333	\N	\N	90	1	domain	2026-06-21 05:44:34.644599
36314	1333	\N	\N	2974	1	domain	2026-06-21 05:44:34.644599
36315	1333	\N	\N	2976	1	domain	2026-06-21 05:44:34.644599
36317	1333	\N	\N	3203	1	domain	2026-06-21 05:44:34.652893
36318	1333	\N	\N	1008	1	domain	2026-06-21 05:44:34.652893
36319	1333	\N	\N	3282	1	domain	2026-06-21 05:44:34.652893
36320	1333	\N	\N	1213	1	domain	2026-06-21 05:44:34.652893
36321	1333	\N	\N	1211	1	standalone	2026-06-21 05:44:34.652893
36322	1333	\N	\N	2211	1	standalone	2026-06-21 05:44:34.652893
36323	1333	\N	\N	2470	1	standalone	2026-06-21 05:44:34.652893
36324	1333	\N	\N	2472	1	standalone	2026-06-21 05:44:34.652893
36325	1333	\N	\N	2549	1	standalone	2026-06-21 05:44:34.652893
36326	1333	\N	\N	2209	1	standalone	2026-06-21 05:44:34.652893
36327	1333	\N	\N	2975	1	standalone	2026-06-21 05:44:34.652893
36328	1333	\N	\N	1707	1	standalone	2026-06-21 05:44:34.652893
36333	1333	\N	\N	3013	1	standalone	2026-06-21 05:44:34.652893
36335	1333	\N	\N	3015	1	standalone	2026-06-21 05:44:34.652893
36336	1333	\N	\N	3016	1	standalone	2026-06-21 05:44:34.652893
36337	1333	\N	\N	3019	1	standalone	2026-06-21 05:44:34.652893
36339	1328	\N	\N	1600	1	domain	2026-06-21 05:44:34.661431
36329	1333	\N	\N	1138	1	domain	2026-06-21 05:44:34.652893
36334	1333	\N	\N	3014	1	domain	2026-06-21 05:44:34.652893
36330	1333	\N	\N	1056	1	domain	2026-06-21 05:44:34.652893
36331	1333	\N	\N	980	1	domain	2026-06-21 05:44:34.652893
36340	1328	\N	\N	28	1	domain	2026-06-21 05:44:34.661431
36341	1328	\N	\N	29	1	domain	2026-06-21 05:44:34.661431
36342	1328	\N	\N	718	1	domain	2026-06-21 05:44:34.661431
36343	1328	\N	\N	842	1	domain	2026-06-21 05:44:34.661431
36344	1334	\N	\N	663	1	standalone	2026-06-21 05:44:34.661431
36345	1334	\N	\N	2814	1	standalone	2026-06-21 05:44:34.661431
36346	1334	\N	\N	3140	1	standalone	2026-06-21 05:44:34.661431
36347	1334	\N	\N	631	1	standalone	2026-06-21 05:44:34.661431
36348	1334	\N	\N	632	1	standalone	2026-06-21 05:44:34.661431
36349	1334	\N	\N	633	1	standalone	2026-06-21 05:44:34.661431
36350	1334	\N	\N	2726	1	standalone	2026-06-21 05:44:34.661431
36351	1334	\N	\N	2727	1	standalone	2026-06-21 05:44:34.661431
36352	1334	\N	\N	2728	1	standalone	2026-06-21 05:44:34.661431
36353	1334	\N	\N	3000	1	standalone	2026-06-21 05:44:34.661431
36354	1334	\N	\N	2240	1	standalone	2026-06-21 05:44:34.661431
36356	1326	\N	\N	2603	1	domain	2026-06-21 05:44:34.677276
36358	1326	\N	\N	274	1	domain	2026-06-21 05:44:34.677276
36359	1326	\N	\N	2416	1	domain	2026-06-21 05:44:34.677276
36360	1326	\N	\N	2422	1	domain	2026-06-21 05:44:34.677276
36362	1322	\N	\N	1139	1	domain	2026-06-21 05:44:34.677276
36363	1322	\N	\N	1140	1	domain	2026-06-21 05:44:34.677276
36365	1322	\N	\N	2984	1	domain	2026-06-21 05:44:34.677276
36367	1329	\N	\N	222	1	domain	2026-06-21 05:44:34.694773
36371	1329	\N	\N	1260	1	domain	2026-06-21 05:44:34.694773
36373	1329	\N	\N	2388	1	domain	2026-06-21 05:44:34.694773
36375	1323	\N	\N	3204	1	domain	2026-06-21 05:44:34.694773
36376	1323	\N	\N	1719	1	domain	2026-06-21 05:44:34.694773
36377	1323	\N	\N	1906	1	standalone	2026-06-21 05:44:34.694773
36378	1323	\N	\N	805	1	standalone	2026-06-21 05:44:34.694773
36379	1323	\N	\N	1026	1	standalone	2026-06-21 05:44:34.694773
36380	1323	\N	\N	865	1	standalone	2026-06-21 05:44:34.694773
36381	1323	\N	\N	1245	1	standalone	2026-06-21 05:44:34.694773
36382	1323	\N	\N	1246	1	standalone	2026-06-21 05:44:34.694773
36383	1323	\N	\N	1247	1	standalone	2026-06-21 05:44:34.694773
36384	1323	\N	\N	1248	1	standalone	2026-06-21 05:44:34.694773
36385	1323	\N	\N	1249	1	standalone	2026-06-21 05:44:34.694773
36386	1323	\N	\N	2038	1	standalone	2026-06-21 05:44:34.694773
36387	1323	\N	\N	2439	1	standalone	2026-06-21 05:44:34.694773
36388	1323	\N	\N	2572	1	standalone	2026-06-21 05:44:34.694773
36391	1335	\N	\N	1318	1	domain	2026-06-21 05:44:34.710134
36392	1335	\N	\N	1321	1	domain	2026-06-21 05:44:34.710134
36393	1335	\N	\N	2398	1	domain	2026-06-21 05:44:34.710134
36396	1322	\N	\N	2078	1	domain	2026-06-21 05:44:34.710134
36397	1322	\N	\N	789	1	domain	2026-06-21 05:44:34.710134
36398	1322	\N	\N	790	1	domain	2026-06-21 05:44:34.710134
36400	1322	\N	\N	1534	1	domain	2026-06-21 05:44:34.710134
36405	1335	\N	\N	3342	1	domain	2026-06-21 05:44:34.725602
36406	1335	\N	\N	1152	1	domain	2026-06-21 05:44:34.725602
36407	1335	\N	\N	1154	1	standalone	2026-06-21 05:44:34.725602
36408	1335	\N	\N	1029	1	standalone	2026-06-21 05:44:34.725602
36409	1335	\N	\N	289	1	standalone	2026-06-21 05:44:34.725602
36410	1335	\N	\N	291	1	standalone	2026-06-21 05:44:34.725602
36411	1335	\N	\N	1212	1	standalone	2026-06-21 05:44:34.725602
36412	1335	\N	\N	1464	1	standalone	2026-06-21 05:44:34.725602
36413	1335	\N	\N	2299	1	standalone	2026-06-21 05:44:34.725602
36414	1322	\N	\N	2081	1	standalone	2026-06-21 05:44:34.725602
36415	1322	\N	\N	2662	1	standalone	2026-06-21 05:44:34.725602
36416	1322	\N	\N	2663	1	standalone	2026-06-21 05:44:34.725602
36417	1322	\N	\N	2684	1	standalone	2026-06-21 05:44:34.725602
36418	1322	\N	\N	2686	1	standalone	2026-06-21 05:44:34.725602
36419	1322	\N	\N	2687	1	standalone	2026-06-21 05:44:34.725602
36420	1322	\N	\N	2936	1	standalone	2026-06-21 05:44:34.725602
36421	1322	\N	\N	2715	1	standalone	2026-06-21 05:44:34.725602
36422	1322	\N	\N	2154	1	standalone	2026-06-21 05:44:34.725602
36423	1322	\N	\N	2155	1	standalone	2026-06-21 05:44:34.725602
36424	1322	\N	\N	2724	1	standalone	2026-06-21 05:44:34.725602
36425	1322	\N	\N	2725	1	standalone	2026-06-21 05:44:34.725602
36426	1322	\N	\N	2731	1	standalone	2026-06-21 05:44:34.725602
36427	1322	\N	\N	2742	1	standalone	2026-06-21 05:44:34.725602
36428	1322	\N	\N	2743	1	standalone	2026-06-21 05:44:34.725602
36429	1322	\N	\N	2364	1	standalone	2026-06-21 05:44:34.725602
36430	1322	\N	\N	2415	1	standalone	2026-06-21 05:44:34.725602
36432	1338	\N	\N	383	1	domain	2026-06-21 05:44:34.741485
36433	1338	\N	\N	1208	1	domain	2026-06-21 05:44:34.741485
36434	1338	\N	\N	2215	1	domain	2026-06-21 05:44:34.741485
36435	1338	\N	\N	2216	1	domain	2026-06-21 05:44:34.741485
36436	1338	\N	\N	2218	1	domain	2026-06-21 05:44:34.741485
36440	1329	\N	\N	638	1	standalone	2026-06-21 05:44:34.741485
36441	1329	\N	\N	639	1	standalone	2026-06-21 05:44:34.741485
36445	1329	\N	\N	2185	1	standalone	2026-06-21 05:44:34.741485
36446	1329	\N	\N	2360	1	standalone	2026-06-21 05:44:34.741485
36448	1335	\N	\N	623	1	domain	2026-06-21 05:44:34.741485
36449	1335	\N	\N	1155	1	domain	2026-06-21 05:44:34.741485
36451	1335	\N	\N	2021	1	domain	2026-06-21 05:44:34.741485
36444	1329	\N	\N	108	1	domain	2026-06-21 05:44:34.741485
36438	1329	\N	\N	1624	1	domain	2026-06-21 05:44:34.741485
36442	1329	\N	\N	846	1	domain	2026-06-21 05:44:34.741485
36443	1329	\N	\N	847	1	domain	2026-06-21 05:44:34.741485
36439	1329	\N	\N	637	1	domain	2026-06-21 05:44:34.741485
36453	1328	\N	\N	3212	1	domain	2026-06-21 05:44:34.757386
36454	1328	\N	\N	999	1	domain	2026-06-21 05:44:34.757386
36455	1328	\N	\N	1679	1	domain	2026-06-21 05:44:34.757386
36456	1328	\N	\N	1680	1	domain	2026-06-21 05:44:34.757386
36457	1328	\N	\N	1231	1	domain	2026-06-21 05:44:34.757386
36458	1328	\N	\N	2433	1	domain	2026-06-21 05:44:34.757386
36460	1329	\N	\N	3292	1	domain	2026-06-21 05:44:34.757386
36461	1329	\N	\N	737	1	domain	2026-06-21 05:44:34.757386
36462	1329	\N	\N	3306	1	domain	2026-06-21 05:44:34.757386
36464	1326	\N	\N	2829	1	domain	2026-06-21 05:44:34.773529
36465	1326	\N	\N	1274	1	domain	2026-06-21 05:44:34.773529
36467	1328	\N	\N	992	1	domain	2026-06-21 05:44:34.773529
36468	1328	\N	\N	2695	1	domain	2026-06-21 05:44:34.773529
36469	1328	\N	\N	2696	1	domain	2026-06-21 05:44:34.773529
36470	1328	\N	\N	2478	1	domain	2026-06-21 05:44:34.773529
36472	1335	\N	\N	1148	1	domain	2026-06-21 05:44:34.789622
36474	1335	\N	\N	1150	1	domain	2026-06-21 05:44:34.789622
36475	1335	\N	\N	3231	1	domain	2026-06-21 05:44:34.789622
36476	1335	\N	\N	860	1	domain	2026-06-21 05:44:34.789622
36478	1335	\N	\N	130	1	domain	2026-06-21 05:44:34.789622
36479	1335	\N	\N	2451	1	domain	2026-06-21 05:44:34.789622
36481	1338	\N	\N	3310	1	domain	2026-06-21 05:44:34.798519
36482	1338	\N	\N	1811	1	domain	2026-06-21 05:44:34.798519
36483	1338	\N	\N	1206	1	domain	2026-06-21 05:44:34.798519
36484	1338	\N	\N	1207	1	domain	2026-06-21 05:44:34.798519
36485	1338	\N	\N	2179	1	domain	2026-06-21 05:44:34.798519
36487	1338	\N	\N	747	1	domain	2026-06-21 05:44:34.805749
36488	1338	\N	\N	481	1	domain	2026-06-21 05:44:34.805749
36489	1338	\N	\N	484	1	domain	2026-06-21 05:44:34.805749
36490	1338	\N	\N	482	1	standalone	2026-06-21 05:44:34.805749
36491	1338	\N	\N	558	1	standalone	2026-06-21 05:44:34.805749
36492	1338	\N	\N	483	1	standalone	2026-06-21 05:44:34.805749
36493	1338	\N	\N	485	1	standalone	2026-06-21 05:44:34.805749
36494	1338	\N	\N	486	1	standalone	2026-06-21 05:44:34.805749
36496	1338	\N	\N	1527	1	domain	2026-06-21 05:44:34.853365
36497	1338	\N	\N	487	1	domain	2026-06-21 05:44:34.853365
36498	1338	\N	\N	1528	1	standalone	2026-06-21 05:44:34.853365
36500	1326	\N	\N	76	1	domain	2026-06-21 05:44:34.861503
36501	1326	\N	\N	122	1	domain	2026-06-21 05:44:34.861503
36502	1326	\N	\N	2337	1	domain	2026-06-21 05:44:34.861503
36503	1326	\N	\N	2338	1	domain	2026-06-21 05:44:34.861503
36504	1326	\N	\N	2339	1	domain	2026-06-21 05:44:34.861503
36507	1333	\N	\N	99	1	domain	2026-06-21 05:44:34.878153
36508	1333	\N	\N	859	1	domain	2026-06-21 05:44:34.878153
36513	1322	\N	\N	2197	1	domain	2026-06-21 05:44:34.899853
36514	1322	\N	\N	2757	1	domain	2026-06-21 05:44:34.899853
36515	1322	\N	\N	2758	1	domain	2026-06-21 05:44:34.899853
36516	1322	\N	\N	2761	1	domain	2026-06-21 05:44:34.899853
36517	1322	\N	\N	2769	1	domain	2026-06-21 05:44:34.899853
36518	1322	\N	\N	1293	1	domain	2026-06-21 05:44:34.899853
36519	1339	\N	\N	1480	1	standalone	2026-06-21 05:44:35.261598
36520	1322	\N	\N	2843	1	standalone	2026-06-21 05:44:35.261598
36521	1329	\N	\N	411	1	standalone	2026-06-21 05:44:35.261598
36522	1328	\N	\N	2471	1	standalone	2026-06-21 05:44:35.261598
36525	1335	\N	\N	1147	1	standalone	2026-06-21 05:44:35.261598
36526	1328	\N	\N	755	1	standalone	2026-06-21 05:44:35.261598
36527	1322	\N	\N	4	1	standalone	2026-06-21 05:44:35.261598
36528	1327	\N	\N	1606	1	standalone	2026-06-21 05:44:35.261598
36529	1334	\N	\N	2630	1	standalone	2026-06-21 05:44:35.261598
36530	1339	\N	\N	2784	1	standalone	2026-06-21 05:44:35.261598
36531	1333	\N	\N	199	1	standalone	2026-06-21 05:44:35.261598
36532	1326	\N	\N	1858	1	standalone	2026-06-21 05:44:35.261598
36533	1322	\N	\N	352	1	standalone	2026-06-21 05:44:35.261598
36534	1322	\N	\N	947	1	standalone	2026-06-21 05:44:35.261598
36535	1326	\N	\N	3104	1	standalone	2026-06-21 05:44:35.261598
36537	1322	\N	\N	3249	1	standalone	2026-06-21 05:44:35.261598
36538	1338	\N	\N	681	1	standalone	2026-06-21 05:44:35.261598
36539	1329	\N	\N	6999	1	standalone	2026-06-21 05:44:35.261598
36540	1322	\N	\N	595	1	standalone	2026-06-21 05:44:35.261598
36541	1322	\N	\N	1569	1	standalone	2026-06-21 05:44:35.261598
36542	1329	\N	\N	647	1	standalone	2026-06-21 05:44:35.261598
36543	1330	\N	\N	1848	1	standalone	2026-06-21 05:44:35.261598
36544	1326	\N	\N	3370	1	standalone	2026-06-21 05:44:35.261598
36545	1339	\N	\N	3333	1	standalone	2026-06-21 05:44:35.261598
36546	1331	\N	\N	915	1	standalone	2026-06-21 05:44:35.261598
36548	1322	\N	\N	165	1	standalone	2026-06-21 05:44:35.261598
36549	1329	\N	\N	1343	1	standalone	2026-06-21 05:44:35.261598
36550	1322	\N	\N	2844	1	standalone	2026-06-21 05:44:35.261598
36551	1322	\N	\N	417	1	standalone	2026-06-21 05:44:35.261598
36552	1336	\N	\N	2345	1	standalone	2026-06-21 05:44:35.261598
36553	1339	\N	\N	1075	1	standalone	2026-06-21 05:44:35.261598
36554	1322	\N	\N	1741	1	standalone	2026-06-21 05:44:35.261598
36555	1327	\N	\N	1182	1	standalone	2026-06-21 05:44:35.261598
36556	1327	\N	\N	758	1	standalone	2026-06-21 05:44:35.261598
36557	1325	\N	\N	12	1	standalone	2026-06-21 05:44:35.261598
36558	1336	\N	\N	1663	1	standalone	2026-06-21 05:44:35.261598
36559	1322	\N	\N	2635	1	standalone	2026-06-21 05:44:35.261598
36560	1334	\N	\N	2785	1	standalone	2026-06-21 05:44:35.261598
36561	1335	\N	\N	204	1	standalone	2026-06-21 05:44:35.261598
36562	1327	\N	\N	1864	1	standalone	2026-06-21 05:44:35.261598
36563	1322	\N	\N	354	1	standalone	2026-06-21 05:44:35.261598
36565	1326	\N	\N	3105	1	standalone	2026-06-21 05:44:35.261598
36524	1322	\N	\N	1740	1	domain	2026-06-21 05:44:35.261598
36564	1322	\N	\N	948	1	domain	2026-06-21 05:44:35.261598
36536	1329	\N	\N	3223	1	domain	2026-06-21 05:44:35.261598
36547	1329	\N	\N	2585	1	domain	2026-06-21 05:44:35.261598
36523	1339	\N	\N	1055	1	domain	2026-06-21 05:44:35.261598
36567	1322	\N	\N	3251	1	standalone	2026-06-21 05:44:35.261598
36568	1329	\N	\N	692	1	standalone	2026-06-21 05:44:35.261598
36569	1329	\N	\N	7000	1	standalone	2026-06-21 05:44:35.261598
36570	1326	\N	\N	596	1	standalone	2026-06-21 05:44:35.261598
36571	1322	\N	\N	1571	1	standalone	2026-06-21 05:44:35.261598
36572	1329	\N	\N	648	1	standalone	2026-06-21 05:44:35.269741
36573	1338	\N	\N	1850	1	standalone	2026-06-21 05:44:35.269741
36574	1326	\N	\N	3371	1	standalone	2026-06-21 05:44:35.269741
36575	1339	\N	\N	3344	1	standalone	2026-06-21 05:44:35.269741
36578	1338	\N	\N	196	1	standalone	2026-06-21 05:44:35.269741
36579	1329	\N	\N	1345	1	standalone	2026-06-21 05:44:35.269741
36580	1322	\N	\N	2847	1	standalone	2026-06-21 05:44:35.269741
36581	1322	\N	\N	391	1	standalone	2026-06-21 05:44:35.269741
36582	1326	\N	\N	2454	1	standalone	2026-06-21 05:44:35.269741
36583	1339	\N	\N	1076	1	standalone	2026-06-21 05:44:35.269741
36584	1322	\N	\N	1745	1	standalone	2026-06-21 05:44:35.269741
36585	1327	\N	\N	1183	1	standalone	2026-06-21 05:44:35.269741
36586	1327	\N	\N	759	1	standalone	2026-06-21 05:44:35.269741
36587	1325	\N	\N	18	1	standalone	2026-06-21 05:44:35.269741
36588	1336	\N	\N	1665	1	standalone	2026-06-21 05:44:35.269741
36589	1322	\N	\N	2636	1	standalone	2026-06-21 05:44:35.269741
36590	1334	\N	\N	2786	1	standalone	2026-06-21 05:44:35.269741
36591	1335	\N	\N	208	1	standalone	2026-06-21 05:44:35.269741
36592	1326	\N	\N	1865	1	standalone	2026-06-21 05:44:35.269741
36593	1322	\N	\N	355	1	standalone	2026-06-21 05:44:35.269741
36594	1322	\N	\N	949	1	standalone	2026-06-21 05:44:35.269741
36595	1326	\N	\N	3107	1	standalone	2026-06-21 05:44:35.269741
36596	1339	\N	\N	3199	1	standalone	2026-06-21 05:44:35.269741
36597	1322	\N	\N	3252	1	standalone	2026-06-21 05:44:35.269741
36598	1329	\N	\N	703	1	standalone	2026-06-21 05:44:35.269741
36599	1329	\N	\N	7001	1	standalone	2026-06-21 05:44:35.269741
36600	1339	\N	\N	593	1	standalone	2026-06-21 05:44:35.269741
36601	1339	\N	\N	1572	1	standalone	2026-06-21 05:44:35.269741
36602	1329	\N	\N	649	1	standalone	2026-06-21 05:44:35.269741
36603	1338	\N	\N	1852	1	standalone	2026-06-21 05:44:35.269741
36604	1326	\N	\N	3368	1	standalone	2026-06-21 05:44:35.269741
36605	1333	\N	\N	3347	1	standalone	2026-06-21 05:44:35.269741
36606	1331	\N	\N	928	1	standalone	2026-06-21 05:44:35.269741
36607	1334	\N	\N	2612	1	standalone	2026-06-21 05:44:35.269741
36608	1329	\N	\N	1347	1	standalone	2026-06-21 05:44:35.269741
36609	1322	\N	\N	2848	1	standalone	2026-06-21 05:44:35.269741
36610	1322	\N	\N	392	1	standalone	2026-06-21 05:44:35.269741
36611	1325	\N	\N	2088	1	standalone	2026-06-21 05:44:35.269741
36612	1339	\N	\N	1077	1	standalone	2026-06-21 05:44:35.269741
36613	1339	\N	\N	1746	1	standalone	2026-06-21 05:44:35.269741
36614	1339	\N	\N	1132	1	standalone	2026-06-21 05:44:35.269741
36615	1335	\N	\N	767	1	standalone	2026-06-21 05:44:35.269741
36616	1334	\N	\N	23	1	standalone	2026-06-21 05:44:35.269741
36618	1322	\N	\N	2641	1	standalone	2026-06-21 05:44:35.269741
36619	1334	\N	\N	2787	1	standalone	2026-06-21 05:44:35.269741
36620	1335	\N	\N	209	1	standalone	2026-06-21 05:44:35.269741
36621	1329	\N	\N	1888	1	standalone	2026-06-21 05:44:35.269741
36622	1322	\N	\N	357	1	standalone	2026-06-21 05:44:35.269741
36623	1335	\N	\N	951	1	standalone	2026-06-21 05:44:35.269741
36624	1327	\N	\N	3108	1	standalone	2026-06-21 05:44:35.269741
36625	1328	\N	\N	3202	1	standalone	2026-06-21 05:44:35.269741
36626	1332	\N	\N	3253	1	standalone	2026-06-21 05:44:35.269741
36627	1339	\N	\N	708	1	standalone	2026-06-21 05:44:35.269741
36628	1329	\N	\N	7002	1	standalone	2026-06-21 05:44:35.269741
36629	1322	\N	\N	587	1	standalone	2026-06-21 05:44:35.269741
36630	1334	\N	\N	1578	1	standalone	2026-06-21 05:44:35.269741
36632	1338	\N	\N	1853	1	standalone	2026-06-21 05:44:35.269741
36633	1326	\N	\N	3375	1	standalone	2026-06-21 05:44:35.269741
36634	1333	\N	\N	3349	1	standalone	2026-06-21 05:44:35.269741
36635	1329	\N	\N	1365	1	standalone	2026-06-21 05:44:35.269741
36636	1322	\N	\N	2849	1	standalone	2026-06-21 05:44:35.269741
36637	1322	\N	\N	393	1	standalone	2026-06-21 05:44:35.269741
36638	1322	\N	\N	2072	1	standalone	2026-06-21 05:44:35.269741
36639	1339	\N	\N	1085	1	standalone	2026-06-21 05:44:35.269741
36640	1339	\N	\N	1747	1	standalone	2026-06-21 05:44:35.269741
36641	1332	\N	\N	1133	1	standalone	2026-06-21 05:44:35.269741
36642	1325	\N	\N	773	1	standalone	2026-06-21 05:44:35.269741
36644	1335	\N	\N	1637	1	standalone	2026-06-21 05:44:35.269741
36645	1322	\N	\N	2642	1	standalone	2026-06-21 05:44:35.269741
36646	1327	\N	\N	2802	1	standalone	2026-06-21 05:44:35.269741
36647	1329	\N	\N	217	1	standalone	2026-06-21 05:44:35.269741
36648	1329	\N	\N	1922	1	standalone	2026-06-21 05:44:35.269741
36649	1322	\N	\N	358	1	standalone	2026-06-21 05:44:35.269741
36650	1334	\N	\N	962	1	standalone	2026-06-21 05:44:35.269741
36651	1322	\N	\N	3111	1	standalone	2026-06-21 05:44:35.269741
36652	1339	\N	\N	3180	1	standalone	2026-06-21 05:44:35.269741
36653	1332	\N	\N	3254	1	standalone	2026-06-21 05:44:35.269741
36654	1329	\N	\N	709	1	standalone	2026-06-21 05:44:35.269741
36655	1329	\N	\N	7003	1	standalone	2026-06-21 05:44:35.269741
36656	1322	\N	\N	588	1	standalone	2026-06-21 05:44:35.269741
36657	1338	\N	\N	1579	1	standalone	2026-06-21 05:44:35.269741
36658	1329	\N	\N	671	1	standalone	2026-06-21 05:44:35.269741
36659	1329	\N	\N	1814	1	standalone	2026-06-21 05:44:35.269741
36660	1334	\N	\N	3379	1	standalone	2026-06-21 05:44:35.269741
36661	1339	\N	\N	3361	1	standalone	2026-06-21 05:44:35.269741
36662	1329	\N	\N	1366	1	standalone	2026-06-21 05:44:35.269741
36663	1322	\N	\N	2850	1	standalone	2026-06-21 05:44:35.269741
36664	1322	\N	\N	394	1	standalone	2026-06-21 05:44:35.269741
36665	1322	\N	\N	2075	1	standalone	2026-06-21 05:44:35.269741
36666	1339	\N	\N	1038	1	standalone	2026-06-21 05:44:35.269741
36667	1324	\N	\N	1748	1	standalone	2026-06-21 05:44:35.269741
36668	1322	\N	\N	1136	1	standalone	2026-06-21 05:44:35.269741
36670	1329	\N	\N	27	1	standalone	2026-06-21 05:44:35.269741
36671	1335	\N	\N	1638	1	standalone	2026-06-21 05:44:35.269741
36672	1322	\N	\N	2647	1	standalone	2026-06-21 05:44:35.269741
36673	1334	\N	\N	2788	1	standalone	2026-06-21 05:44:35.269741
36674	1329	\N	\N	221	1	standalone	2026-06-21 05:44:35.269741
36675	1335	\N	\N	1923	1	standalone	2026-06-21 05:44:35.269741
36676	1322	\N	\N	359	1	standalone	2026-06-21 05:44:35.269741
36677	1334	\N	\N	963	1	standalone	2026-06-21 05:44:35.269741
36678	1333	\N	\N	3112	1	standalone	2026-06-21 05:44:35.269741
36679	1322	\N	\N	3170	1	standalone	2026-06-21 05:44:35.269741
36680	1322	\N	\N	3255	1	standalone	2026-06-21 05:44:35.269741
36681	1322	\N	\N	710	1	standalone	2026-06-21 05:44:35.269741
36682	1329	\N	\N	7006	1	standalone	2026-06-21 05:44:35.269741
36683	1338	\N	\N	617	1	standalone	2026-06-21 05:44:35.269741
36684	1322	\N	\N	1580	1	standalone	2026-06-21 05:44:35.269741
36685	1329	\N	\N	672	1	standalone	2026-06-21 05:44:35.269741
36686	1334	\N	\N	1816	1	standalone	2026-06-21 05:44:35.269741
36688	1332	\N	\N	3367	1	standalone	2026-06-21 05:44:35.269741
36689	1329	\N	\N	1371	1	standalone	2026-06-21 05:44:35.269741
36690	1322	\N	\N	2854	1	standalone	2026-06-21 05:44:35.269741
36691	1322	\N	\N	395	1	standalone	2026-06-21 05:44:35.269741
36692	1322	\N	\N	2076	1	standalone	2026-06-21 05:44:35.269741
36693	1324	\N	\N	1052	1	standalone	2026-06-21 05:44:35.269741
36694	1322	\N	\N	1749	1	standalone	2026-06-21 05:44:35.269741
36695	1336	\N	\N	1137	1	standalone	2026-06-21 05:44:35.269741
36696	1325	\N	\N	780	1	standalone	2026-06-21 05:44:35.269741
36697	1333	\N	\N	30	1	standalone	2026-06-21 05:44:35.269741
36699	1334	\N	\N	2650	1	standalone	2026-06-21 05:44:35.269741
36700	1334	\N	\N	2789	1	standalone	2026-06-21 05:44:35.269741
36701	1327	\N	\N	230	1	standalone	2026-06-21 05:44:35.269741
36702	1329	\N	\N	1938	1	standalone	2026-06-21 05:44:35.269741
36703	1322	\N	\N	360	1	standalone	2026-06-21 05:44:35.269741
36705	1327	\N	\N	3135	1	standalone	2026-06-21 05:44:35.269741
36706	1322	\N	\N	3173	1	standalone	2026-06-21 05:44:35.269741
36707	1330	\N	\N	3287	1	standalone	2026-06-21 05:44:35.269741
36708	1328	\N	\N	715	1	standalone	2026-06-21 05:44:35.269741
36709	1329	\N	\N	7012	1	standalone	2026-06-21 05:44:35.269741
36710	1331	\N	\N	618	1	standalone	2026-06-21 05:44:35.269741
36711	1322	\N	\N	1581	1	standalone	2026-06-21 05:44:35.269741
36712	1322	\N	\N	680	1	standalone	2026-06-21 05:44:35.269741
36713	1322	\N	\N	1817	1	standalone	2026-06-21 05:44:35.269741
36714	1324	\N	\N	1376	1	standalone	2026-06-21 05:44:35.269741
36715	1332	\N	\N	2857	1	standalone	2026-06-21 05:44:35.269741
36716	1322	\N	\N	397	1	standalone	2026-06-21 05:44:35.269741
36717	1322	\N	\N	2079	1	standalone	2026-06-21 05:44:35.269741
36718	1335	\N	\N	1086	1	standalone	2026-06-21 05:44:35.269741
36719	1322	\N	\N	1750	1	standalone	2026-06-21 05:44:35.269741
36720	1338	\N	\N	1141	1	standalone	2026-06-21 05:44:35.269741
36722	1328	\N	\N	33	1	standalone	2026-06-21 05:44:35.269741
36723	1324	\N	\N	1641	1	standalone	2026-06-21 05:44:35.269741
36724	1322	\N	\N	2651	1	standalone	2026-06-21 05:44:35.269741
36725	1334	\N	\N	2790	1	standalone	2026-06-21 05:44:35.269741
36726	1337	\N	\N	231	1	standalone	2026-06-21 05:44:35.269741
36727	1329	\N	\N	1991	1	standalone	2026-06-21 05:44:35.269741
36728	1322	\N	\N	361	1	standalone	2026-06-21 05:44:35.269741
36729	1334	\N	\N	966	1	standalone	2026-06-21 05:44:35.269741
36730	1330	\N	\N	3137	1	standalone	2026-06-21 05:44:35.269741
36731	1322	\N	\N	3174	1	standalone	2026-06-21 05:44:35.269741
36732	1322	\N	\N	3257	1	standalone	2026-06-21 05:44:35.269741
36733	1327	\N	\N	716	1	standalone	2026-06-21 05:44:35.269741
36734	1329	\N	\N	7013	1	standalone	2026-06-21 05:44:35.269741
36735	1331	\N	\N	619	1	standalone	2026-06-21 05:44:35.269741
36736	1322	\N	\N	1582	1	standalone	2026-06-21 05:44:35.269741
36737	1324	\N	\N	1377	1	standalone	2026-06-21 05:44:35.269741
36738	1322	\N	\N	2858	1	standalone	2026-06-21 05:44:35.269741
36739	1322	\N	\N	398	1	standalone	2026-06-21 05:44:35.269741
36740	1322	\N	\N	2080	1	standalone	2026-06-21 05:44:35.269741
36741	1335	\N	\N	1101	1	standalone	2026-06-21 05:44:35.269741
36742	1322	\N	\N	1751	1	standalone	2026-06-21 05:44:35.269741
36743	1334	\N	\N	1142	1	standalone	2026-06-21 05:44:35.269741
36745	1337	\N	\N	34	1	standalone	2026-06-21 05:44:35.269741
36747	1327	\N	\N	2668	1	standalone	2026-06-21 05:44:35.269741
36748	1334	\N	\N	2791	1	standalone	2026-06-21 05:44:35.269741
36749	1327	\N	\N	235	1	standalone	2026-06-21 05:44:35.269741
36750	1329	\N	\N	1992	1	standalone	2026-06-21 05:44:35.269741
36751	1322	\N	\N	363	1	standalone	2026-06-21 05:44:35.269741
36752	1332	\N	\N	971	1	standalone	2026-06-21 05:44:35.269741
36753	1334	\N	\N	3139	1	standalone	2026-06-21 05:44:35.269741
36754	1322	\N	\N	3175	1	standalone	2026-06-21 05:44:35.269741
36755	1322	\N	\N	3260	1	standalone	2026-06-21 05:44:35.269741
36756	1328	\N	\N	721	1	standalone	2026-06-21 05:44:35.269741
36757	1329	\N	\N	7014	1	standalone	2026-06-21 05:44:35.269741
36758	1337	\N	\N	620	1	standalone	2026-06-21 05:44:35.269741
36759	1339	\N	\N	1583	1	standalone	2026-06-21 05:44:35.269741
36760	1329	\N	\N	1379	1	standalone	2026-06-21 05:44:35.269741
36761	1322	\N	\N	2859	1	standalone	2026-06-21 05:44:35.269741
36762	1339	\N	\N	399	1	standalone	2026-06-21 05:44:35.269741
36763	1332	\N	\N	2082	1	standalone	2026-06-21 05:44:35.269741
36764	1322	\N	\N	1037	1	standalone	2026-06-21 05:44:35.269741
36765	1324	\N	\N	1752	1	standalone	2026-06-21 05:44:35.269741
36766	1334	\N	\N	1143	1	standalone	2026-06-21 05:44:35.269741
36767	1339	\N	\N	795	1	standalone	2026-06-21 05:44:35.269741
36768	1339	\N	\N	44	1	standalone	2026-06-21 05:44:35.269741
36769	1327	\N	\N	1650	1	standalone	2026-06-21 05:44:35.269741
36770	1326	\N	\N	2669	1	standalone	2026-06-21 05:44:35.269741
36771	1334	\N	\N	2792	1	standalone	2026-06-21 05:44:35.269741
36772	1336	\N	\N	260	1	standalone	2026-06-21 05:44:35.269741
36773	1329	\N	\N	1994	1	standalone	2026-06-21 05:44:35.269741
36776	1324	\N	\N	3156	1	standalone	2026-06-21 05:44:35.269741
36778	1322	\N	\N	3263	1	standalone	2026-06-21 05:44:35.269741
36779	1329	\N	\N	735	1	standalone	2026-06-21 05:44:35.269741
36775	1322	\N	\N	974	1	domain	2026-06-21 05:44:35.269741
36780	1329	\N	\N	7017	1	standalone	2026-06-21 05:44:35.269741
36781	1329	\N	\N	1389	1	standalone	2026-06-21 05:44:35.269741
36782	1322	\N	\N	2860	1	standalone	2026-06-21 05:44:35.269741
36783	1322	\N	\N	404	1	standalone	2026-06-21 05:44:35.269741
36784	1322	\N	\N	2104	1	standalone	2026-06-21 05:44:35.269741
36785	1322	\N	\N	1039	1	standalone	2026-06-21 05:44:35.269741
36786	1322	\N	\N	1753	1	standalone	2026-06-21 05:44:35.269741
36787	1337	\N	\N	1144	1	standalone	2026-06-21 05:44:35.269741
36789	1326	\N	\N	57	1	standalone	2026-06-21 05:44:35.269741
36790	1336	\N	\N	1662	1	standalone	2026-06-21 05:44:35.269741
36791	1327	\N	\N	2682	1	standalone	2026-06-21 05:44:35.269741
36792	1334	\N	\N	2793	1	standalone	2026-06-21 05:44:35.269741
36793	1326	\N	\N	269	1	standalone	2026-06-21 05:44:35.269741
36794	1329	\N	\N	1995	1	standalone	2026-06-21 05:44:35.269741
36795	1334	\N	\N	365	1	standalone	2026-06-21 05:44:35.269741
36796	1329	\N	\N	975	1	standalone	2026-06-21 05:44:35.269741
36797	1324	\N	\N	3158	1	standalone	2026-06-21 05:44:35.269741
36798	1339	\N	\N	3221	1	standalone	2026-06-21 05:44:35.269741
36799	1322	\N	\N	3264	1	standalone	2026-06-21 05:44:35.269741
36800	1329	\N	\N	736	1	standalone	2026-06-21 05:44:35.269741
36801	1322	\N	\N	7018	1	standalone	2026-06-21 05:44:35.269741
36802	1329	\N	\N	1405	1	standalone	2026-06-21 05:44:35.269741
36803	1322	\N	\N	2861	1	standalone	2026-06-21 05:44:35.269741
36804	1339	\N	\N	400	1	standalone	2026-06-21 05:44:35.269741
36805	1322	\N	\N	2105	1	standalone	2026-06-21 05:44:35.269741
36806	1322	\N	\N	1040	1	standalone	2026-06-21 05:44:35.269741
36807	1338	\N	\N	1754	1	standalone	2026-06-21 05:44:35.269741
36808	1334	\N	\N	1145	1	standalone	2026-06-21 05:44:35.269741
36809	1327	\N	\N	798	1	standalone	2026-06-21 05:44:35.269741
36811	1336	\N	\N	1667	1	standalone	2026-06-21 05:44:35.269741
36812	1326	\N	\N	2685	1	standalone	2026-06-21 05:44:35.269741
36813	1334	\N	\N	2795	1	standalone	2026-06-21 05:44:35.269741
36814	1326	\N	\N	270	1	standalone	2026-06-21 05:44:35.269741
36815	1336	\N	\N	2010	1	standalone	2026-06-21 05:44:35.269741
36816	1322	\N	\N	370	1	standalone	2026-06-21 05:44:35.269741
36818	1324	\N	\N	3159	1	standalone	2026-06-21 05:44:35.269741
36819	1325	\N	\N	3225	1	standalone	2026-06-21 05:44:35.269741
36820	1322	\N	\N	3265	1	standalone	2026-06-21 05:44:35.269741
36821	1329	\N	\N	745	1	standalone	2026-06-21 05:44:35.269741
36822	1339	\N	\N	7019	1	standalone	2026-06-21 05:44:35.269741
36823	1334	\N	\N	1407	1	standalone	2026-06-21 05:44:35.269741
36824	1322	\N	\N	2863	1	standalone	2026-06-21 05:44:35.269741
36825	1339	\N	\N	401	1	standalone	2026-06-21 05:44:35.269741
36826	1332	\N	\N	2115	1	standalone	2026-06-21 05:44:35.269741
36827	1322	\N	\N	1041	1	standalone	2026-06-21 05:44:35.269741
36828	1322	\N	\N	1796	1	standalone	2026-06-21 05:44:35.269741
36829	1335	\N	\N	1146	1	standalone	2026-06-21 05:44:35.269741
36830	1322	\N	\N	800	1	standalone	2026-06-21 05:44:35.269741
36831	1329	\N	\N	82	1	standalone	2026-06-21 05:44:35.269741
36832	1339	\N	\N	1669	1	standalone	2026-06-21 05:44:35.269741
36833	1326	\N	\N	2688	1	standalone	2026-06-21 05:44:35.269741
36834	1334	\N	\N	2796	1	standalone	2026-06-21 05:44:35.269741
36835	1326	\N	\N	271	1	standalone	2026-06-21 05:44:35.269741
36836	1336	\N	\N	2009	1	standalone	2026-06-21 05:44:35.269741
36837	1322	\N	\N	372	1	standalone	2026-06-21 05:44:35.269741
36839	1324	\N	\N	3160	1	standalone	2026-06-21 05:44:35.269741
36840	1335	\N	\N	3232	1	standalone	2026-06-21 05:44:35.269741
36841	1338	\N	\N	3276	1	standalone	2026-06-21 05:44:35.269741
36843	1322	\N	\N	2864	1	standalone	2026-06-21 05:44:35.269741
36844	1329	\N	\N	402	1	standalone	2026-06-21 05:44:35.269741
36845	1322	\N	\N	2116	1	standalone	2026-06-21 05:44:35.269741
36846	1322	\N	\N	1042	1	standalone	2026-06-21 05:44:35.269741
36847	1322	\N	\N	1755	1	standalone	2026-06-21 05:44:35.269741
36848	1322	\N	\N	1109	1	standalone	2026-06-21 05:44:35.269741
36849	1322	\N	\N	801	1	standalone	2026-06-21 05:44:35.269741
36851	1328	\N	\N	1670	1	standalone	2026-06-21 05:44:35.269741
36852	1335	\N	\N	2689	1	standalone	2026-06-21 05:44:35.269741
36853	1332	\N	\N	2803	1	standalone	2026-06-21 05:44:35.269741
36854	1337	\N	\N	272	1	standalone	2026-06-21 05:44:35.269741
36855	1333	\N	\N	2018	1	standalone	2026-06-21 05:44:35.269741
36856	1322	\N	\N	377	1	standalone	2026-06-21 05:44:35.269741
36858	1324	\N	\N	3161	1	standalone	2026-06-21 05:44:35.269741
36859	1336	\N	\N	3233	1	standalone	2026-06-21 05:44:35.269741
36861	1322	\N	\N	1417	1	standalone	2026-06-21 05:44:35.269741
36862	1322	\N	\N	2867	1	standalone	2026-06-21 05:44:35.269741
36863	1329	\N	\N	403	1	standalone	2026-06-21 05:44:35.269741
36864	1337	\N	\N	2124	1	standalone	2026-06-21 05:44:35.269741
36865	1322	\N	\N	1053	1	standalone	2026-06-21 05:44:35.269741
36866	1322	\N	\N	1756	1	standalone	2026-06-21 05:44:35.269741
36867	1322	\N	\N	1112	1	standalone	2026-06-21 05:44:35.269741
36868	1329	\N	\N	804	1	standalone	2026-06-21 05:44:35.269741
36869	1322	\N	\N	85	1	standalone	2026-06-21 05:44:35.269741
36870	1328	\N	\N	1671	1	standalone	2026-06-21 05:44:35.269741
36871	1335	\N	\N	2692	1	standalone	2026-06-21 05:44:35.269741
36872	1334	\N	\N	2797	1	standalone	2026-06-21 05:44:35.269741
36873	1337	\N	\N	273	1	standalone	2026-06-21 05:44:35.269741
36874	1339	\N	\N	2011	1	standalone	2026-06-21 05:44:35.269741
36875	1322	\N	\N	380	1	standalone	2026-06-21 05:44:35.269741
36877	1324	\N	\N	3162	1	standalone	2026-06-21 05:44:35.269741
36879	1329	\N	\N	3290	1	standalone	2026-06-21 05:44:35.269741
36880	1322	\N	\N	1418	1	standalone	2026-06-21 05:44:35.269741
36881	1322	\N	\N	2868	1	standalone	2026-06-21 05:44:35.269741
36882	1329	\N	\N	405	1	standalone	2026-06-21 05:44:35.269741
36883	1325	\N	\N	2246	1	standalone	2026-06-21 05:44:35.269741
36884	1322	\N	\N	1043	1	standalone	2026-06-21 05:44:35.269741
36885	1334	\N	\N	1757	1	standalone	2026-06-21 05:44:35.269741
36886	1339	\N	\N	1328	1	standalone	2026-06-21 05:44:35.269741
36842	1322	\N	\N	1413	1	domain	2026-06-21 05:44:35.269741
36887	1332	\N	\N	807	1	standalone	2026-06-21 05:44:35.269741
36888	1329	\N	\N	95	1	standalone	2026-06-21 05:44:35.269741
36889	1328	\N	\N	1673	1	standalone	2026-06-21 05:44:35.269741
36890	1326	\N	\N	2693	1	standalone	2026-06-21 05:44:35.269741
36891	1334	\N	\N	2798	1	standalone	2026-06-21 05:44:35.269741
36892	1337	\N	\N	278	1	standalone	2026-06-21 05:44:35.269741
36893	1337	\N	\N	2012	1	standalone	2026-06-21 05:44:35.269741
36895	1329	\N	\N	1003	1	standalone	2026-06-21 05:44:35.269741
36897	1339	\N	\N	3241	1	standalone	2026-06-21 05:44:35.269741
36898	1329	\N	\N	3313	1	standalone	2026-06-21 05:44:35.269741
36899	1322	\N	\N	1419	1	standalone	2026-06-21 05:44:35.269741
36900	1322	\N	\N	2871	1	standalone	2026-06-21 05:44:35.269741
36901	1329	\N	\N	406	1	standalone	2026-06-21 05:44:35.269741
36903	1322	\N	\N	1044	1	standalone	2026-06-21 05:44:35.269741
36904	1322	\N	\N	1759	1	standalone	2026-06-21 05:44:35.269741
36905	1322	\N	\N	1115	1	standalone	2026-06-21 05:44:35.269741
36906	1327	\N	\N	809	1	standalone	2026-06-21 05:44:35.269741
36907	1329	\N	\N	103	1	standalone	2026-06-21 05:44:35.269741
36908	1339	\N	\N	1678	1	standalone	2026-06-21 05:44:35.269741
36909	1326	\N	\N	2700	1	standalone	2026-06-21 05:44:35.269741
36910	1334	\N	\N	2800	1	standalone	2026-06-21 05:44:35.269741
36911	1337	\N	\N	280	1	standalone	2026-06-21 05:44:35.269741
36912	1327	\N	\N	2035	1	standalone	2026-06-21 05:44:35.269741
36913	1338	\N	\N	382	1	standalone	2026-06-21 05:44:35.269741
36914	1331	\N	\N	1016	1	standalone	2026-06-21 05:44:35.269741
36915	1322	\N	\N	3165	1	standalone	2026-06-21 05:44:35.269741
36916	1322	\N	\N	1420	1	standalone	2026-06-21 05:44:35.269741
36917	1322	\N	\N	2878	1	standalone	2026-06-21 05:44:35.269741
36918	1322	\N	\N	408	1	standalone	2026-06-21 05:44:35.269741
36919	1322	\N	\N	2137	1	standalone	2026-06-21 05:44:35.269741
36921	1339	\N	\N	1760	1	standalone	2026-06-21 05:44:35.269741
36923	1331	\N	\N	822	1	standalone	2026-06-21 05:44:35.269741
36925	1322	\N	\N	1688	1	standalone	2026-06-21 05:44:35.269741
36926	1334	\N	\N	2702	1	standalone	2026-06-21 05:44:35.269741
36927	1334	\N	\N	2801	1	standalone	2026-06-21 05:44:35.269741
36928	1329	\N	\N	285	1	standalone	2026-06-21 05:44:35.269741
36929	1332	\N	\N	2039	1	standalone	2026-06-21 05:44:35.269741
36930	1339	\N	\N	385	1	standalone	2026-06-21 05:44:35.269741
36931	1339	\N	\N	1019	1	standalone	2026-06-21 05:44:35.269741
36932	1339	\N	\N	3166	1	standalone	2026-06-21 05:44:35.269741
36933	1329	\N	\N	1430	1	standalone	2026-06-21 05:44:35.269741
36934	1339	\N	\N	2879	1	standalone	2026-06-21 05:44:35.269741
36935	1329	\N	\N	409	1	standalone	2026-06-21 05:44:35.269741
36936	1327	\N	\N	2156	1	standalone	2026-06-21 05:44:35.269741
36938	1322	\N	\N	1761	1	standalone	2026-06-21 05:44:35.269741
36939	1335	\N	\N	1153	1	standalone	2026-06-21 05:44:35.269741
36940	1328	\N	\N	827	1	standalone	2026-06-21 05:44:35.269741
36942	1329	\N	\N	1697	1	standalone	2026-06-21 05:44:35.269741
36943	1334	\N	\N	2703	1	standalone	2026-06-21 05:44:35.269741
36944	1334	\N	\N	2804	1	standalone	2026-06-21 05:44:35.269741
36945	1334	\N	\N	321	1	standalone	2026-06-21 05:44:35.269741
36946	1327	\N	\N	2040	1	standalone	2026-06-21 05:44:35.269741
36947	1322	\N	\N	386	1	standalone	2026-06-21 05:44:35.269741
36948	1327	\N	\N	1025	1	standalone	2026-06-21 05:44:35.269741
36949	1339	\N	\N	3167	1	standalone	2026-06-21 05:44:35.269741
36950	1339	\N	\N	1432	1	standalone	2026-06-21 05:44:35.269741
36951	1322	\N	\N	2880	1	standalone	2026-06-21 05:44:35.269741
36952	1329	\N	\N	410	1	standalone	2026-06-21 05:44:35.269741
36953	1332	\N	\N	2159	1	standalone	2026-06-21 05:44:35.269741
36954	1322	\N	\N	1054	1	standalone	2026-06-21 05:44:35.269741
36955	1322	\N	\N	1762	1	standalone	2026-06-21 05:44:35.269741
36956	1335	\N	\N	1156	1	standalone	2026-06-21 05:44:35.269741
36957	1335	\N	\N	831	1	standalone	2026-06-21 05:44:35.269741
36958	1329	\N	\N	113	1	standalone	2026-06-21 05:44:35.269741
36959	1329	\N	\N	1698	1	standalone	2026-06-21 05:44:35.269741
36960	1334	\N	\N	2704	1	standalone	2026-06-21 05:44:35.269741
36961	1334	\N	\N	2811	1	standalone	2026-06-21 05:44:35.269741
36962	1334	\N	\N	322	1	standalone	2026-06-21 05:44:35.269741
36963	1334	\N	\N	2049	1	standalone	2026-06-21 05:44:35.269741
36964	1322	\N	\N	387	1	standalone	2026-06-21 05:44:35.269741
36966	1338	\N	\N	3169	1	standalone	2026-06-21 05:44:35.269741
36967	1339	\N	\N	1433	1	standalone	2026-06-21 05:44:35.269741
36968	1322	\N	\N	2881	1	standalone	2026-06-21 05:44:35.269741
36969	1329	\N	\N	413	1	standalone	2026-06-21 05:44:35.269741
36970	1322	\N	\N	2160	1	standalone	2026-06-21 05:44:35.269741
36971	1322	\N	\N	1047	1	standalone	2026-06-21 05:44:35.269741
36972	1322	\N	\N	1797	1	standalone	2026-06-21 05:44:35.269741
36973	1335	\N	\N	1157	1	standalone	2026-06-21 05:44:35.269741
36975	1329	\N	\N	114	1	standalone	2026-06-21 05:44:35.269741
36976	1339	\N	\N	1702	1	standalone	2026-06-21 05:44:35.269741
36977	1326	\N	\N	2712	1	standalone	2026-06-21 05:44:35.269741
36978	1331	\N	\N	2812	1	standalone	2026-06-21 05:44:35.269741
36979	1334	\N	\N	326	1	standalone	2026-06-21 05:44:35.269741
36980	1334	\N	\N	2050	1	standalone	2026-06-21 05:44:35.269741
36981	1332	\N	\N	388	1	standalone	2026-06-21 05:44:35.269741
36982	1335	\N	\N	1035	1	standalone	2026-06-21 05:44:35.269741
36983	1339	\N	\N	1436	1	standalone	2026-06-21 05:44:35.269741
36984	1322	\N	\N	2882	1	standalone	2026-06-21 05:44:35.269741
36985	1329	\N	\N	421	1	standalone	2026-06-21 05:44:35.269741
36986	1339	\N	\N	2169	1	standalone	2026-06-21 05:44:35.269741
36987	1322	\N	\N	1048	1	standalone	2026-06-21 05:44:35.269741
36988	1335	\N	\N	1764	1	standalone	2026-06-21 05:44:35.269741
36989	1335	\N	\N	1159	1	standalone	2026-06-21 05:44:35.269741
36992	1326	\N	\N	1721	1	standalone	2026-06-21 05:44:35.269741
36993	1326	\N	\N	2714	1	standalone	2026-06-21 05:44:35.269741
36994	1334	\N	\N	2815	1	standalone	2026-06-21 05:44:35.269741
36995	1335	\N	\N	327	1	standalone	2026-06-21 05:44:35.269741
36996	1334	\N	\N	2054	1	standalone	2026-06-21 05:44:35.269741
36997	1332	\N	\N	390	1	standalone	2026-06-21 05:44:35.269741
36998	1339	\N	\N	1438	1	standalone	2026-06-21 05:44:35.269741
36999	1322	\N	\N	2883	1	standalone	2026-06-21 05:44:35.269741
37000	1327	\N	\N	425	1	standalone	2026-06-21 05:44:35.269741
37001	1338	\N	\N	2178	1	standalone	2026-06-21 05:44:35.269741
37002	1339	\N	\N	1050	1	standalone	2026-06-21 05:44:35.269741
37003	1339	\N	\N	1765	1	standalone	2026-06-21 05:44:35.269741
37004	1339	\N	\N	1160	1	standalone	2026-06-21 05:44:35.269741
37006	1326	\N	\N	116	1	standalone	2026-06-21 05:44:35.269741
37007	1334	\N	\N	1711	1	standalone	2026-06-21 05:44:35.269741
37008	1334	\N	\N	2716	1	standalone	2026-06-21 05:44:35.269741
37009	1334	\N	\N	2816	1	standalone	2026-06-21 05:44:35.269741
37010	1339	\N	\N	330	1	standalone	2026-06-21 05:44:35.269741
37011	1329	\N	\N	2055	1	standalone	2026-06-21 05:44:35.269741
37012	1329	\N	\N	1440	1	standalone	2026-06-21 05:44:35.269741
37013	1322	\N	\N	2884	1	standalone	2026-06-21 05:44:35.269741
37014	1324	\N	\N	435	1	standalone	2026-06-21 05:44:35.269741
37015	1338	\N	\N	2186	1	standalone	2026-06-21 05:44:35.269741
37016	1324	\N	\N	1051	1	standalone	2026-06-21 05:44:35.269741
37017	1339	\N	\N	1766	1	standalone	2026-06-21 05:44:35.269741
37018	1339	\N	\N	1161	1	standalone	2026-06-21 05:44:35.269741
37019	1329	\N	\N	845	1	standalone	2026-06-21 05:44:35.269741
37020	1329	\N	\N	117	1	standalone	2026-06-21 05:44:35.269741
37021	1337	\N	\N	1713	1	standalone	2026-06-21 05:44:35.269741
37022	1334	\N	\N	2717	1	standalone	2026-06-21 05:44:35.269741
37023	1337	\N	\N	2831	1	standalone	2026-06-21 05:44:35.269741
37024	1329	\N	\N	1443	1	standalone	2026-06-21 05:44:35.269741
37025	1334	\N	\N	2885	1	standalone	2026-06-21 05:44:35.269741
37026	1329	\N	\N	437	1	standalone	2026-06-21 05:44:35.269741
37027	1337	\N	\N	2191	1	standalone	2026-06-21 05:44:35.269741
37028	1339	\N	\N	1057	1	standalone	2026-06-21 05:44:35.269741
37029	1339	\N	\N	1767	1	standalone	2026-06-21 05:44:35.269741
37030	1339	\N	\N	1172	1	standalone	2026-06-21 05:44:35.269741
37031	1329	\N	\N	848	1	standalone	2026-06-21 05:44:35.269741
37032	1335	\N	\N	129	1	standalone	2026-06-21 05:44:35.269741
37033	1322	\N	\N	1714	1	standalone	2026-06-21 05:44:35.269741
37034	1334	\N	\N	2718	1	standalone	2026-06-21 05:44:35.269741
37035	1330	\N	\N	2836	1	standalone	2026-06-21 05:44:35.269741
37036	1339	\N	\N	1445	1	standalone	2026-06-21 05:44:35.269741
37037	1322	\N	\N	2886	1	standalone	2026-06-21 05:44:35.269741
37038	1339	\N	\N	439	1	standalone	2026-06-21 05:44:35.269741
37039	1339	\N	\N	2224	1	standalone	2026-06-21 05:44:35.269741
37040	1339	\N	\N	1058	1	standalone	2026-06-21 05:44:35.269741
37041	1339	\N	\N	1768	1	standalone	2026-06-21 05:44:35.269741
37042	1335	\N	\N	1173	1	standalone	2026-06-21 05:44:35.269741
37044	1324	\N	\N	131	1	standalone	2026-06-21 05:44:35.269741
37045	1326	\N	\N	1715	1	standalone	2026-06-21 05:44:35.269741
37046	1334	\N	\N	2720	1	standalone	2026-06-21 05:44:35.269741
37047	1330	\N	\N	2837	1	standalone	2026-06-21 05:44:35.269741
37048	1324	\N	\N	1446	1	standalone	2026-06-21 05:44:35.269741
37049	1322	\N	\N	2888	1	standalone	2026-06-21 05:44:35.269741
37050	1329	\N	\N	458	1	standalone	2026-06-21 05:44:35.269741
37051	1339	\N	\N	2226	1	standalone	2026-06-21 05:44:35.269741
37052	1339	\N	\N	1059	1	standalone	2026-06-21 05:44:35.269741
37053	1339	\N	\N	1769	1	standalone	2026-06-21 05:44:35.269741
37054	1339	\N	\N	1185	1	standalone	2026-06-21 05:44:35.269741
37056	1339	\N	\N	136	1	standalone	2026-06-21 05:44:35.269741
37057	1330	\N	\N	1728	1	standalone	2026-06-21 05:44:35.269741
37058	1331	\N	\N	2722	1	standalone	2026-06-21 05:44:35.269741
37059	1330	\N	\N	2838	1	standalone	2026-06-21 05:44:35.269741
37060	1339	\N	\N	1447	1	standalone	2026-06-21 05:44:35.269741
37061	1322	\N	\N	2890	1	standalone	2026-06-21 05:44:35.269741
37062	1329	\N	\N	459	1	standalone	2026-06-21 05:44:35.269741
37063	1337	\N	\N	2227	1	standalone	2026-06-21 05:44:35.269741
37064	1339	\N	\N	1060	1	standalone	2026-06-21 05:44:35.269741
37065	1339	\N	\N	1770	1	standalone	2026-06-21 05:44:35.269741
37066	1339	\N	\N	1214	1	standalone	2026-06-21 05:44:35.269741
37067	1335	\N	\N	871	1	standalone	2026-06-21 05:44:35.269741
37070	1334	\N	\N	2723	1	standalone	2026-06-21 05:44:35.269741
37071	1339	\N	\N	2839	1	standalone	2026-06-21 05:44:35.269741
37072	1339	\N	\N	1448	1	standalone	2026-06-21 05:44:35.269741
37073	1327	\N	\N	2937	1	standalone	2026-06-21 05:44:35.269741
37074	1329	\N	\N	462	1	standalone	2026-06-21 05:44:35.269741
37075	1322	\N	\N	2229	1	standalone	2026-06-21 05:44:35.269741
37076	1339	\N	\N	1061	1	standalone	2026-06-21 05:44:35.269741
37077	1324	\N	\N	1771	1	standalone	2026-06-21 05:44:35.269741
37078	1337	\N	\N	1227	1	standalone	2026-06-21 05:44:35.269741
37079	1339	\N	\N	877	1	standalone	2026-06-21 05:44:35.269741
37081	1335	\N	\N	1731	1	standalone	2026-06-21 05:44:35.269741
37082	1327	\N	\N	2734	1	standalone	2026-06-21 05:44:35.269741
37083	1334	\N	\N	2841	1	standalone	2026-06-21 05:44:35.269741
37084	1335	\N	\N	1449	1	standalone	2026-06-21 05:44:35.269741
37085	1322	\N	\N	2899	1	standalone	2026-06-21 05:44:35.269741
37086	1322	\N	\N	465	1	standalone	2026-06-21 05:44:35.269741
37087	1334	\N	\N	2230	1	standalone	2026-06-21 05:44:35.269741
37088	1332	\N	\N	1062	1	standalone	2026-06-21 05:44:35.269741
37089	1322	\N	\N	1772	1	standalone	2026-06-21 05:44:35.269741
37090	1331	\N	\N	1228	1	standalone	2026-06-21 05:44:35.269741
37091	1329	\N	\N	889	1	standalone	2026-06-21 05:44:35.269741
37092	1334	\N	\N	146	1	standalone	2026-06-21 05:44:35.269741
37093	1335	\N	\N	1733	1	standalone	2026-06-21 05:44:35.269741
37094	1334	\N	\N	2753	1	standalone	2026-06-21 05:44:35.269741
37095	1339	\N	\N	1450	1	standalone	2026-06-21 05:44:35.269741
37096	1322	\N	\N	2900	1	standalone	2026-06-21 05:44:35.269741
37097	1329	\N	\N	467	1	standalone	2026-06-21 05:44:35.269741
37098	1322	\N	\N	2231	1	standalone	2026-06-21 05:44:35.269741
37099	1332	\N	\N	1063	1	standalone	2026-06-21 05:44:35.269741
37100	1322	\N	\N	1773	1	standalone	2026-06-21 05:44:35.269741
37101	1328	\N	\N	1229	1	standalone	2026-06-21 05:44:35.269741
37102	1329	\N	\N	890	1	standalone	2026-06-21 05:44:35.269741
37103	1334	\N	\N	148	1	standalone	2026-06-21 05:44:35.269741
37104	1322	\N	\N	1734	1	standalone	2026-06-21 05:44:35.269741
37105	1337	\N	\N	2760	1	standalone	2026-06-21 05:44:35.269741
37106	1329	\N	\N	1452	1	standalone	2026-06-21 05:44:35.269741
37107	1322	\N	\N	2901	1	standalone	2026-06-21 05:44:35.269741
37108	1327	\N	\N	471	1	standalone	2026-06-21 05:44:35.269741
37109	1332	\N	\N	2233	1	standalone	2026-06-21 05:44:35.269741
37110	1332	\N	\N	1064	1	standalone	2026-06-21 05:44:35.269741
37111	1322	\N	\N	1774	1	standalone	2026-06-21 05:44:35.269741
37112	1331	\N	\N	1230	1	standalone	2026-06-21 05:44:35.269741
37113	1329	\N	\N	893	1	standalone	2026-06-21 05:44:35.269741
37114	1324	\N	\N	156	1	standalone	2026-06-21 05:44:35.269741
37115	1334	\N	\N	1739	1	standalone	2026-06-21 05:44:35.269741
37116	1337	\N	\N	2780	1	standalone	2026-06-21 05:44:35.269741
37118	1322	\N	\N	2904	1	standalone	2026-06-21 05:44:35.269741
37119	1327	\N	\N	472	1	standalone	2026-06-21 05:44:35.269741
37120	1327	\N	\N	2257	1	standalone	2026-06-21 05:44:35.269741
37121	1332	\N	\N	1065	1	standalone	2026-06-21 05:44:35.269741
37122	1322	\N	\N	1775	1	standalone	2026-06-21 05:44:35.269741
37123	1327	\N	\N	1244	1	standalone	2026-06-21 05:44:35.269741
37124	1322	\N	\N	898	1	standalone	2026-06-21 05:44:35.269741
37125	1329	\N	\N	1456	1	standalone	2026-06-21 05:44:35.269741
37126	1322	\N	\N	2915	1	standalone	2026-06-21 05:44:35.269741
37127	1329	\N	\N	473	1	standalone	2026-06-21 05:44:35.269741
37128	1322	\N	\N	2234	1	standalone	2026-06-21 05:44:35.269741
37129	1332	\N	\N	1066	1	standalone	2026-06-21 05:44:35.269741
37130	1322	\N	\N	1776	1	standalone	2026-06-21 05:44:35.269741
37131	1327	\N	\N	1263	1	standalone	2026-06-21 05:44:35.269741
37132	1329	\N	\N	1458	1	standalone	2026-06-21 05:44:35.269741
37133	1322	\N	\N	2916	1	standalone	2026-06-21 05:44:35.269741
37134	1322	\N	\N	474	1	standalone	2026-06-21 05:44:35.269741
37135	1334	\N	\N	2235	1	standalone	2026-06-21 05:44:35.269741
37136	1332	\N	\N	1068	1	standalone	2026-06-21 05:44:35.269741
37137	1322	\N	\N	1777	1	standalone	2026-06-21 05:44:35.269741
37138	1337	\N	\N	1273	1	standalone	2026-06-21 05:44:35.269741
37139	1329	\N	\N	1459	1	standalone	2026-06-21 05:44:35.269741
37140	1322	\N	\N	2917	1	standalone	2026-06-21 05:44:35.269741
37141	1322	\N	\N	477	1	standalone	2026-06-21 05:44:35.269741
37142	1322	\N	\N	2236	1	standalone	2026-06-21 05:44:35.269741
37143	1322	\N	\N	1069	1	standalone	2026-06-21 05:44:35.269741
37144	1322	\N	\N	1778	1	standalone	2026-06-21 05:44:35.269741
37145	1327	\N	\N	1281	1	standalone	2026-06-21 05:44:35.269741
37146	1329	\N	\N	1460	1	standalone	2026-06-21 05:44:35.269741
37147	1335	\N	\N	2923	1	standalone	2026-06-21 05:44:35.269741
37148	1322	\N	\N	478	1	standalone	2026-06-21 05:44:35.269741
37149	1334	\N	\N	2237	1	standalone	2026-06-21 05:44:35.269741
37150	1322	\N	\N	1070	1	standalone	2026-06-21 05:44:35.269741
37151	1322	\N	\N	1779	1	standalone	2026-06-21 05:44:35.269741
37152	1335	\N	\N	1282	1	standalone	2026-06-21 05:44:35.269741
37153	1329	\N	\N	1463	1	standalone	2026-06-21 05:44:35.269741
37154	1322	\N	\N	2939	1	standalone	2026-06-21 05:44:35.269741
37155	1324	\N	\N	479	1	standalone	2026-06-21 05:44:35.269741
37156	1334	\N	\N	2238	1	standalone	2026-06-21 05:44:35.269741
37157	1322	\N	\N	1071	1	standalone	2026-06-21 05:44:35.269741
37158	1322	\N	\N	1780	1	standalone	2026-06-21 05:44:35.269741
37159	1339	\N	\N	1284	1	standalone	2026-06-21 05:44:35.269741
37160	1329	\N	\N	1465	1	standalone	2026-06-21 05:44:35.269741
37161	1332	\N	\N	2940	1	standalone	2026-06-21 05:44:35.269741
37162	1329	\N	\N	480	1	standalone	2026-06-21 05:44:35.269741
37163	1337	\N	\N	2239	1	standalone	2026-06-21 05:44:35.269741
37165	1329	\N	\N	1781	1	standalone	2026-06-21 05:44:35.269741
37166	1337	\N	\N	1286	1	standalone	2026-06-21 05:44:35.269741
37167	1329	\N	\N	1466	1	standalone	2026-06-21 05:44:35.269741
37168	1338	\N	\N	2942	1	standalone	2026-06-21 05:44:35.269741
37169	1329	\N	\N	489	1	standalone	2026-06-21 05:44:35.269741
37170	1337	\N	\N	2241	1	standalone	2026-06-21 05:44:35.269741
37171	1322	\N	\N	1073	1	standalone	2026-06-21 05:44:35.269741
37172	1332	\N	\N	1782	1	standalone	2026-06-21 05:44:35.269741
37173	1326	\N	\N	1287	1	standalone	2026-06-21 05:44:35.269741
37174	1329	\N	\N	1467	1	standalone	2026-06-21 05:44:35.269741
37175	1332	\N	\N	2944	1	standalone	2026-06-21 05:44:35.269741
37176	1329	\N	\N	490	1	standalone	2026-06-21 05:44:35.269741
37177	1331	\N	\N	2242	1	standalone	2026-06-21 05:44:35.269741
37178	1325	\N	\N	1074	1	standalone	2026-06-21 05:44:35.269741
37179	1330	\N	\N	1783	1	standalone	2026-06-21 05:44:35.269741
37180	1327	\N	\N	1288	1	standalone	2026-06-21 05:44:35.269741
37181	1324	\N	\N	1468	1	standalone	2026-06-21 05:44:35.269741
37182	1338	\N	\N	2955	1	standalone	2026-06-21 05:44:35.269741
37183	1329	\N	\N	491	1	standalone	2026-06-21 05:44:35.269741
37184	1327	\N	\N	2247	1	standalone	2026-06-21 05:44:35.269741
37185	1325	\N	\N	1078	1	standalone	2026-06-21 05:44:35.269741
37186	1332	\N	\N	1784	1	standalone	2026-06-21 05:44:35.269741
37187	1330	\N	\N	1289	1	standalone	2026-06-21 05:44:35.269741
37188	1329	\N	\N	1477	1	standalone	2026-06-21 05:44:35.269741
37189	1322	\N	\N	2957	1	standalone	2026-06-21 05:44:35.269741
37190	1335	\N	\N	492	1	standalone	2026-06-21 05:44:35.269741
37191	1327	\N	\N	2254	1	standalone	2026-06-21 05:44:35.269741
37192	1332	\N	\N	1079	1	standalone	2026-06-21 05:44:35.269741
37193	1337	\N	\N	1785	1	standalone	2026-06-21 05:44:35.269741
37194	1338	\N	\N	1292	1	standalone	2026-06-21 05:44:35.269741
37195	1329	\N	\N	1479	1	standalone	2026-06-21 05:44:35.269741
37196	1322	\N	\N	2958	1	standalone	2026-06-21 05:44:35.269741
37197	1335	\N	\N	493	1	standalone	2026-06-21 05:44:35.269741
37198	1336	\N	\N	2266	1	standalone	2026-06-21 05:44:35.269741
37199	1332	\N	\N	1080	1	standalone	2026-06-21 05:44:35.269741
37200	1332	\N	\N	1786	1	standalone	2026-06-21 05:44:35.269741
37201	1330	\N	\N	1295	1	standalone	2026-06-21 05:44:35.269741
37202	1329	\N	\N	1483	1	standalone	2026-06-21 05:44:35.269741
37203	1322	\N	\N	2961	1	standalone	2026-06-21 05:44:35.269741
37204	1326	\N	\N	494	1	standalone	2026-06-21 05:44:35.269741
37205	1327	\N	\N	2286	1	standalone	2026-06-21 05:44:35.269741
37206	1332	\N	\N	1081	1	standalone	2026-06-21 05:44:35.269741
37207	1332	\N	\N	1787	1	standalone	2026-06-21 05:44:35.269741
37208	1330	\N	\N	1296	1	standalone	2026-06-21 05:44:35.269741
37209	1329	\N	\N	1485	1	standalone	2026-06-21 05:44:35.269741
37210	1322	\N	\N	2962	1	standalone	2026-06-21 05:44:35.269741
37211	1339	\N	\N	500	1	standalone	2026-06-21 05:44:35.269741
37212	1324	\N	\N	2287	1	standalone	2026-06-21 05:44:35.269741
37213	1332	\N	\N	1082	1	standalone	2026-06-21 05:44:35.269741
37214	1332	\N	\N	1788	1	standalone	2026-06-21 05:44:35.269741
37215	1330	\N	\N	1297	1	standalone	2026-06-21 05:44:35.269741
37216	1329	\N	\N	1487	1	standalone	2026-06-21 05:44:35.269741
37217	1322	\N	\N	2963	1	standalone	2026-06-21 05:44:35.269741
37218	1335	\N	\N	496	1	standalone	2026-06-21 05:44:35.269741
37219	1326	\N	\N	2292	1	standalone	2026-06-21 05:44:35.269741
37220	1322	\N	\N	1083	1	standalone	2026-06-21 05:44:35.269741
37221	1332	\N	\N	1789	1	standalone	2026-06-21 05:44:35.269741
37222	1338	\N	\N	1298	1	standalone	2026-06-21 05:44:35.269741
37223	1329	\N	\N	1488	1	standalone	2026-06-21 05:44:35.269741
37224	1338	\N	\N	2964	1	standalone	2026-06-21 05:44:35.269741
37225	1335	\N	\N	497	1	standalone	2026-06-21 05:44:35.269741
37226	1327	\N	\N	2298	1	standalone	2026-06-21 05:44:35.269741
37227	1335	\N	\N	1084	1	standalone	2026-06-21 05:44:35.269741
37228	1332	\N	\N	1790	1	standalone	2026-06-21 05:44:35.269741
37229	1338	\N	\N	1308	1	standalone	2026-06-21 05:44:35.269741
37230	1329	\N	\N	1490	1	standalone	2026-06-21 05:44:35.269741
37231	1322	\N	\N	2967	1	standalone	2026-06-21 05:44:35.269741
37232	1322	\N	\N	511	1	standalone	2026-06-21 05:44:35.269741
37233	1326	\N	\N	2311	1	standalone	2026-06-21 05:44:35.269741
37234	1335	\N	\N	1087	1	standalone	2026-06-21 05:44:35.269741
37235	1339	\N	\N	1791	1	standalone	2026-06-21 05:44:35.269741
37236	1338	\N	\N	1309	1	standalone	2026-06-21 05:44:35.269741
37237	1329	\N	\N	1491	1	standalone	2026-06-21 05:44:35.269741
37238	1322	\N	\N	2968	1	standalone	2026-06-21 05:44:35.269741
37239	1339	\N	\N	501	1	standalone	2026-06-21 05:44:35.269741
37240	1333	\N	\N	2312	1	standalone	2026-06-21 05:44:35.269741
37241	1339	\N	\N	1088	1	standalone	2026-06-21 05:44:35.269741
37242	1339	\N	\N	1798	1	standalone	2026-06-21 05:44:35.269741
37243	1337	\N	\N	1310	1	standalone	2026-06-21 05:44:35.269741
37244	1329	\N	\N	1492	1	standalone	2026-06-21 05:44:35.269741
37245	1339	\N	\N	2969	1	standalone	2026-06-21 05:44:35.269741
37246	1322	\N	\N	502	1	standalone	2026-06-21 05:44:35.269741
37247	1328	\N	\N	2317	1	standalone	2026-06-21 05:44:35.269741
37248	1339	\N	\N	1089	1	standalone	2026-06-21 05:44:35.269741
37249	1339	\N	\N	1792	1	standalone	2026-06-21 05:44:35.269741
37250	1339	\N	\N	1311	1	standalone	2026-06-21 05:44:35.269741
37251	1329	\N	\N	1493	1	standalone	2026-06-21 05:44:35.269741
37252	1331	\N	\N	2970	1	standalone	2026-06-21 05:44:35.269741
37253	1322	\N	\N	505	1	standalone	2026-06-21 05:44:35.269741
37254	1324	\N	\N	2322	1	standalone	2026-06-21 05:44:35.269741
37255	1339	\N	\N	1090	1	standalone	2026-06-21 05:44:35.269741
37256	1339	\N	\N	1801	1	standalone	2026-06-21 05:44:35.269741
37257	1337	\N	\N	1312	1	standalone	2026-06-21 05:44:35.269741
37258	1329	\N	\N	1494	1	standalone	2026-06-21 05:44:35.269741
37259	1339	\N	\N	2971	1	standalone	2026-06-21 05:44:35.269741
37260	1329	\N	\N	506	1	standalone	2026-06-21 05:44:35.269741
37261	1335	\N	\N	2325	1	standalone	2026-06-21 05:44:35.269741
37262	1330	\N	\N	1091	1	standalone	2026-06-21 05:44:35.269741
37263	1339	\N	\N	1802	1	standalone	2026-06-21 05:44:35.269741
37264	1337	\N	\N	1313	1	standalone	2026-06-21 05:44:35.269741
37265	1324	\N	\N	1496	1	standalone	2026-06-21 05:44:35.269741
37266	1339	\N	\N	2972	1	standalone	2026-06-21 05:44:35.269741
37267	1329	\N	\N	508	1	standalone	2026-06-21 05:44:35.269741
37268	1339	\N	\N	2333	1	standalone	2026-06-21 05:44:35.269741
37269	1339	\N	\N	1092	1	standalone	2026-06-21 05:44:35.269741
37270	1339	\N	\N	1803	1	standalone	2026-06-21 05:44:35.269741
37271	1335	\N	\N	1315	1	standalone	2026-06-21 05:44:35.269741
37272	1339	\N	\N	1498	1	standalone	2026-06-21 05:44:35.269741
37273	1339	\N	\N	2977	1	standalone	2026-06-21 05:44:35.269741
37274	1322	\N	\N	509	1	standalone	2026-06-21 05:44:35.269741
37275	1339	\N	\N	2334	1	standalone	2026-06-21 05:44:35.269741
37276	1339	\N	\N	1093	1	standalone	2026-06-21 05:44:35.269741
37277	1339	\N	\N	1804	1	standalone	2026-06-21 05:44:35.269741
37278	1339	\N	\N	1501	1	standalone	2026-06-21 05:44:35.269741
37279	1339	\N	\N	2978	1	standalone	2026-06-21 05:44:35.269741
37280	1322	\N	\N	510	1	standalone	2026-06-21 05:44:35.269741
37281	1335	\N	\N	2335	1	standalone	2026-06-21 05:44:35.269741
37282	1339	\N	\N	1094	1	standalone	2026-06-21 05:44:35.269741
37283	1338	\N	\N	1805	1	standalone	2026-06-21 05:44:35.269741
37284	1339	\N	\N	1502	1	standalone	2026-06-21 05:44:35.269741
37285	1339	\N	\N	2979	1	standalone	2026-06-21 05:44:35.269741
37286	1322	\N	\N	512	1	standalone	2026-06-21 05:44:35.269741
37287	1335	\N	\N	2344	1	standalone	2026-06-21 05:44:35.269741
37288	1339	\N	\N	1095	1	standalone	2026-06-21 05:44:35.269741
37289	1339	\N	\N	1806	1	standalone	2026-06-21 05:44:35.269741
37290	1339	\N	\N	1503	1	standalone	2026-06-21 05:44:35.269741
37291	1335	\N	\N	2985	1	standalone	2026-06-21 05:44:35.269741
37292	1322	\N	\N	513	1	standalone	2026-06-21 05:44:35.269741
37293	1326	\N	\N	2346	1	standalone	2026-06-21 05:44:35.269741
37294	1339	\N	\N	1096	1	standalone	2026-06-21 05:44:35.269741
37296	1339	\N	\N	1505	1	standalone	2026-06-21 05:44:35.269741
37297	1339	\N	\N	2988	1	standalone	2026-06-21 05:44:35.269741
37298	1322	\N	\N	514	1	standalone	2026-06-21 05:44:35.269741
37299	1326	\N	\N	2351	1	standalone	2026-06-21 05:44:35.269741
37300	1339	\N	\N	1097	1	standalone	2026-06-21 05:44:35.269741
37301	1339	\N	\N	1808	1	standalone	2026-06-21 05:44:35.269741
37302	1324	\N	\N	1506	1	standalone	2026-06-21 05:44:35.269741
37303	1339	\N	\N	3009	1	standalone	2026-06-21 05:44:35.269741
37304	1322	\N	\N	515	1	standalone	2026-06-21 05:44:35.269741
37305	1330	\N	\N	2353	1	standalone	2026-06-21 05:44:35.269741
37306	1339	\N	\N	1098	1	standalone	2026-06-21 05:44:35.269741
37307	1339	\N	\N	1809	1	standalone	2026-06-21 05:44:35.269741
37308	1339	\N	\N	1508	1	standalone	2026-06-21 05:44:35.269741
37309	1339	\N	\N	3012	1	standalone	2026-06-21 05:44:35.269741
37310	1322	\N	\N	516	1	standalone	2026-06-21 05:44:35.269741
37311	1327	\N	\N	2399	1	standalone	2026-06-21 05:44:35.269741
37312	1338	\N	\N	1099	1	standalone	2026-06-21 05:44:35.269741
37313	1339	\N	\N	1509	1	standalone	2026-06-21 05:44:35.269741
37314	1339	\N	\N	3026	1	standalone	2026-06-21 05:44:35.269741
37315	1322	\N	\N	517	1	standalone	2026-06-21 05:44:35.269741
37316	1327	\N	\N	2400	1	standalone	2026-06-21 05:44:35.269741
37317	1339	\N	\N	1100	1	standalone	2026-06-21 05:44:35.269741
37318	1339	\N	\N	1510	1	standalone	2026-06-21 05:44:35.269741
37319	1339	\N	\N	3027	1	standalone	2026-06-21 05:44:35.269741
37320	1322	\N	\N	521	1	standalone	2026-06-21 05:44:35.269741
37321	1323	\N	\N	2445	1	standalone	2026-06-21 05:44:35.269741
37322	1339	\N	\N	1102	1	standalone	2026-06-21 05:44:35.269741
37323	1329	\N	\N	1513	1	standalone	2026-06-21 05:44:35.269741
37324	1339	\N	\N	3028	1	standalone	2026-06-21 05:44:35.269741
37325	1322	\N	\N	522	1	standalone	2026-06-21 05:44:35.269741
37326	1335	\N	\N	2450	1	standalone	2026-06-21 05:44:35.269741
37327	1339	\N	\N	1103	1	standalone	2026-06-21 05:44:35.269741
37328	1339	\N	\N	1519	1	standalone	2026-06-21 05:44:35.269741
37329	1339	\N	\N	3029	1	standalone	2026-06-21 05:44:35.269741
37330	1338	\N	\N	523	1	standalone	2026-06-21 05:44:35.269741
37331	1335	\N	\N	2456	1	standalone	2026-06-21 05:44:35.269741
37332	1339	\N	\N	1104	1	standalone	2026-06-21 05:44:35.269741
37333	1329	\N	\N	1524	1	standalone	2026-06-21 05:44:35.269741
37334	1334	\N	\N	3030	1	standalone	2026-06-21 05:44:35.269741
37335	1322	\N	\N	524	1	standalone	2026-06-21 05:44:35.269741
37336	1335	\N	\N	2457	1	standalone	2026-06-21 05:44:35.269741
37337	1334	\N	\N	1105	1	standalone	2026-06-21 05:44:35.269741
37338	1329	\N	\N	1525	1	standalone	2026-06-21 05:44:35.269741
37339	1334	\N	\N	3031	1	standalone	2026-06-21 05:44:35.269741
37340	1322	\N	\N	525	1	standalone	2026-06-21 05:44:35.269741
37341	1328	\N	\N	2461	1	standalone	2026-06-21 05:44:35.269741
37342	1339	\N	\N	1106	1	standalone	2026-06-21 05:44:35.269741
37344	1334	\N	\N	3032	1	standalone	2026-06-21 05:44:35.269741
37345	1322	\N	\N	526	1	standalone	2026-06-21 05:44:35.269741
37346	1334	\N	\N	2467	1	standalone	2026-06-21 05:44:35.269741
37347	1329	\N	\N	1531	1	standalone	2026-06-21 05:44:35.269741
37348	1329	\N	\N	3033	1	standalone	2026-06-21 05:44:35.269741
37349	1322	\N	\N	530	1	standalone	2026-06-21 05:44:35.269741
37350	1327	\N	\N	2475	1	standalone	2026-06-21 05:44:35.269741
37351	1339	\N	\N	1469	1	standalone	2026-06-21 05:44:35.269741
37352	1334	\N	\N	3037	1	standalone	2026-06-21 05:44:35.269741
37353	1322	\N	\N	531	1	standalone	2026-06-21 05:44:35.269741
37354	1335	\N	\N	2491	1	standalone	2026-06-21 05:44:35.269741
37356	1339	\N	\N	3039	1	standalone	2026-06-21 05:44:35.269741
37357	1322	\N	\N	532	1	standalone	2026-06-21 05:44:35.269741
37358	1327	\N	\N	2494	1	standalone	2026-06-21 05:44:35.269741
37359	1322	\N	\N	1541	1	standalone	2026-06-21 05:44:35.269741
37360	1339	\N	\N	3040	1	standalone	2026-06-21 05:44:35.269741
37361	1322	\N	\N	533	1	standalone	2026-06-21 05:44:35.269741
37362	1334	\N	\N	2497	1	standalone	2026-06-21 05:44:35.269741
37364	1328	\N	\N	3041	1	standalone	2026-06-21 05:44:35.269741
37365	1322	\N	\N	534	1	standalone	2026-06-21 05:44:35.269741
37366	1328	\N	\N	2498	1	standalone	2026-06-21 05:44:35.269741
37367	1329	\N	\N	1344	1	standalone	2026-06-21 05:44:35.269741
37368	1339	\N	\N	3042	1	standalone	2026-06-21 05:44:35.269741
37369	1322	\N	\N	535	1	standalone	2026-06-21 05:44:35.269741
37370	1332	\N	\N	2501	1	standalone	2026-06-21 05:44:35.269741
37371	1322	\N	\N	1346	1	standalone	2026-06-21 05:44:35.269741
37372	1331	\N	\N	3046	1	standalone	2026-06-21 05:44:35.269741
37373	1322	\N	\N	536	1	standalone	2026-06-21 05:44:35.269741
37374	1322	\N	\N	2510	1	standalone	2026-06-21 05:44:35.269741
37375	1322	\N	\N	1348	1	standalone	2026-06-21 05:44:35.269741
37376	1331	\N	\N	3047	1	standalone	2026-06-21 05:44:35.269741
37377	1327	\N	\N	537	1	standalone	2026-06-21 05:44:35.269741
37378	1335	\N	\N	2521	1	standalone	2026-06-21 05:44:35.269741
37379	1322	\N	\N	1352	1	standalone	2026-06-21 05:44:35.269741
37380	1332	\N	\N	3063	1	standalone	2026-06-21 05:44:35.269741
37381	1327	\N	\N	554	1	standalone	2026-06-21 05:44:35.269741
37382	1322	\N	\N	1353	1	standalone	2026-06-21 05:44:35.269741
37383	1331	\N	\N	3048	1	standalone	2026-06-21 05:44:35.269741
37384	1322	\N	\N	555	1	standalone	2026-06-21 05:44:35.269741
37385	1322	\N	\N	1354	1	standalone	2026-06-21 05:44:35.269741
37386	1331	\N	\N	3049	1	standalone	2026-06-21 05:44:35.269741
37387	1322	\N	\N	556	1	standalone	2026-06-21 05:44:35.269741
37388	1322	\N	\N	1355	1	standalone	2026-06-21 05:44:35.269741
37389	1322	\N	\N	3050	1	standalone	2026-06-21 05:44:35.269741
37390	1322	\N	\N	559	1	standalone	2026-06-21 05:44:35.269741
37391	1322	\N	\N	1356	1	standalone	2026-06-21 05:44:35.269741
37392	1331	\N	\N	3051	1	standalone	2026-06-21 05:44:35.269741
37393	1322	\N	\N	560	1	standalone	2026-06-21 05:44:35.269741
37394	1322	\N	\N	1357	1	standalone	2026-06-21 05:44:35.269741
37395	1332	\N	\N	3084	1	standalone	2026-06-21 05:44:35.269741
37396	1322	\N	\N	561	1	standalone	2026-06-21 05:44:35.269741
37397	1322	\N	\N	1358	1	standalone	2026-06-21 05:44:35.269741
37398	1332	\N	\N	3085	1	standalone	2026-06-21 05:44:35.269741
37399	1322	\N	\N	562	1	standalone	2026-06-21 05:44:35.269741
37400	1329	\N	\N	1359	1	standalone	2026-06-21 05:44:35.269741
37401	1332	\N	\N	3086	1	standalone	2026-06-21 05:44:35.269741
37402	1322	\N	\N	563	1	standalone	2026-06-21 05:44:35.269741
37403	1329	\N	\N	1360	1	standalone	2026-06-21 05:44:35.269741
37404	1332	\N	\N	3087	1	standalone	2026-06-21 05:44:35.269741
37405	1329	\N	\N	564	1	standalone	2026-06-21 05:44:35.269741
37406	1329	\N	\N	1364	1	standalone	2026-06-21 05:44:35.269741
37407	1332	\N	\N	3088	1	standalone	2026-06-21 05:44:35.269741
37408	1322	\N	\N	565	1	standalone	2026-06-21 05:44:35.269741
37409	1339	\N	\N	1370	1	standalone	2026-06-21 05:44:35.269741
37410	1332	\N	\N	3089	1	standalone	2026-06-21 05:44:35.269741
37411	1335	\N	\N	569	1	standalone	2026-06-21 05:44:35.269741
37412	1329	\N	\N	1378	1	standalone	2026-06-21 05:44:35.269741
37413	1332	\N	\N	3092	1	standalone	2026-06-21 05:44:35.269741
37414	1339	\N	\N	570	1	standalone	2026-06-21 05:44:35.269741
37415	1339	\N	\N	1380	1	standalone	2026-06-21 05:44:35.269741
37416	1332	\N	\N	3093	1	standalone	2026-06-21 05:44:35.269741
37417	1327	\N	\N	575	1	standalone	2026-06-21 05:44:35.269741
37418	1329	\N	\N	1381	1	standalone	2026-06-21 05:44:35.269741
37419	1332	\N	\N	3094	1	standalone	2026-06-21 05:44:35.269741
37420	1332	\N	\N	576	1	standalone	2026-06-21 05:44:35.269741
37421	1329	\N	\N	1382	1	standalone	2026-06-21 05:44:35.269741
37422	1332	\N	\N	3095	1	standalone	2026-06-21 05:44:35.269741
37423	1339	\N	\N	577	1	standalone	2026-06-21 05:44:35.269741
37424	1339	\N	\N	1383	1	standalone	2026-06-21 05:44:35.269741
37425	1332	\N	\N	3096	1	standalone	2026-06-21 05:44:35.269741
37426	1327	\N	\N	578	1	standalone	2026-06-21 05:44:35.269741
37427	1339	\N	\N	1384	1	standalone	2026-06-21 05:44:35.269741
37428	1332	\N	\N	3097	1	standalone	2026-06-21 05:44:35.269741
37429	1327	\N	\N	579	1	standalone	2026-06-21 05:44:35.269741
37430	1339	\N	\N	1387	1	standalone	2026-06-21 05:44:35.269741
37431	1332	\N	\N	3098	1	standalone	2026-06-21 05:44:35.269741
37432	1327	\N	\N	580	1	standalone	2026-06-21 05:44:35.269741
37433	1339	\N	\N	1388	1	standalone	2026-06-21 05:44:35.269741
37434	1332	\N	\N	3099	1	standalone	2026-06-21 05:44:35.269741
37435	1327	\N	\N	581	1	standalone	2026-06-21 05:44:35.269741
37436	1339	\N	\N	1406	1	standalone	2026-06-21 05:44:35.269741
37437	1332	\N	\N	3101	1	standalone	2026-06-21 05:44:35.269741
37438	1327	\N	\N	582	1	standalone	2026-06-21 05:44:35.269741
37439	1339	\N	\N	1412	1	standalone	2026-06-21 05:44:35.269741
37440	1332	\N	\N	3102	1	standalone	2026-06-21 05:44:35.269741
37441	1327	\N	\N	583	1	standalone	2026-06-21 05:44:35.269741
37442	1339	\N	\N	1421	1	standalone	2026-06-21 05:44:35.269741
37443	1332	\N	\N	3103	1	standalone	2026-06-21 05:44:35.269741
37444	1339	\N	\N	1427	1	standalone	2026-06-21 05:44:35.269741
37445	1339	\N	\N	1434	1	standalone	2026-06-21 05:44:35.269741
37446	1339	\N	\N	1435	1	standalone	2026-06-21 05:44:35.269741
37447	1339	\N	\N	1437	1	standalone	2026-06-21 05:44:35.269741
37448	1339	\N	\N	1441	1	standalone	2026-06-21 05:44:35.269741
37449	1339	\N	\N	1442	1	standalone	2026-06-21 05:44:35.269741
37450	1339	\N	\N	1454	1	standalone	2026-06-21 05:44:35.269741
37451	1339	\N	\N	1455	1	standalone	2026-06-21 05:44:35.269741
37452	1339	\N	\N	1457	1	standalone	2026-06-21 05:44:35.269741
37453	1339	\N	\N	1461	1	standalone	2026-06-21 05:44:35.269741
37454	1339	\N	\N	1462	1	standalone	2026-06-21 05:44:35.269741
37455	1339	\N	\N	1471	1	standalone	2026-06-21 05:44:35.269741
37456	1339	\N	\N	1472	1	standalone	2026-06-21 05:44:35.269741
37457	1339	\N	\N	1473	1	standalone	2026-06-21 05:44:35.269741
37458	1339	\N	\N	1476	1	standalone	2026-06-21 05:44:35.269741
37459	1339	\N	\N	1484	1	standalone	2026-06-21 05:44:35.269741
37460	1339	\N	\N	1486	1	standalone	2026-06-21 05:44:35.269741
37461	1339	\N	\N	1489	1	standalone	2026-06-21 05:44:35.269741
37462	1339	\N	\N	1499	1	standalone	2026-06-21 05:44:35.269741
37463	1339	\N	\N	1504	1	standalone	2026-06-21 05:44:35.269741
37464	1339	\N	\N	1507	1	standalone	2026-06-21 05:44:35.269741
37465	1339	\N	\N	1511	1	standalone	2026-06-21 05:44:35.269741
37466	1329	\N	\N	1533	1	standalone	2026-06-21 05:44:35.269741
37467	1339	\N	\N	1500	1	standalone	2026-06-21 05:44:35.269741
37468	1339	\N	\N	1368	1	standalone	2026-06-21 05:44:35.269741
37469	1339	\N	\N	1429	1	standalone	2026-06-21 05:44:35.269741
37470	1339	\N	\N	1431	1	standalone	2026-06-21 05:44:35.269741
37471	1339	\N	\N	1373	1	standalone	2026-06-21 05:44:35.269741
37472	1339	\N	\N	1497	1	standalone	2026-06-21 05:44:35.269741
37473	1322	\N	\N	1351	1	standalone	2026-06-21 05:44:35.269741
37474	1339	\N	\N	1369	1	standalone	2026-06-21 05:44:35.269741
37475	1339	\N	\N	1386	1	standalone	2026-06-21 05:44:35.269741
37476	1339	\N	\N	1404	1	standalone	2026-06-21 05:44:35.269741
37477	1339	\N	\N	1474	1	standalone	2026-06-21 05:44:35.269741
37478	1339	\N	\N	1478	1	standalone	2026-06-21 05:44:35.269741
37479	1324	\N	\N	1481	1	standalone	2026-06-21 05:44:35.269741
37480	1324	\N	\N	1482	1	standalone	2026-06-21 05:44:35.269741
37481	1329	\N	\N	1495	1	standalone	2026-06-21 05:44:35.269741
34001	1328	\N	\N	1989	1	standalone	2026-06-21 05:44:31.888851
34167	1327	\N	\N	1599	1	standalone	2026-06-21 05:44:32.120663
34172	1327	\N	\N	1633	1	standalone	2026-06-21 05:44:32.120663
34175	1327	\N	\N	447	1	standalone	2026-06-21 05:44:32.120663
34176	1327	\N	\N	1006	1	standalone	2026-06-21 05:44:32.120663
34177	1327	\N	\N	68	1	standalone	2026-06-21 05:44:32.120663
34178	1327	\N	\N	74	1	standalone	2026-06-21 05:44:32.120663
34179	1327	\N	\N	1666	1	standalone	2026-06-21 05:44:32.120663
34180	1327	\N	\N	1940	1	standalone	2026-06-21 05:44:32.120663
34181	1327	\N	\N	1942	1	standalone	2026-06-21 05:44:32.120663
34182	1327	\N	\N	292	1	standalone	2026-06-21 05:44:32.120663
34183	1327	\N	\N	295	1	standalone	2026-06-21 05:44:32.120663
34186	1327	\N	\N	3008	1	standalone	2026-06-21 05:44:32.120663
34187	1327	\N	\N	3018	1	standalone	2026-06-21 05:44:32.120663
34188	1327	\N	\N	2271	1	standalone	2026-06-21 05:44:32.120663
34190	1327	\N	\N	2294	1	standalone	2026-06-21 05:44:32.120663
34191	1327	\N	\N	2361	1	standalone	2026-06-21 05:44:32.120663
34192	1327	\N	\N	2384	1	standalone	2026-06-21 05:44:32.120663
34193	1327	\N	\N	2436	1	standalone	2026-06-21 05:44:32.120663
34194	1327	\N	\N	2546	1	standalone	2026-06-21 05:44:32.120663
35436	1338	\N	\N	875	1	standalone	2026-06-21 05:44:33.679105
35435	1338	\N	\N	3230	1	standalone	2026-06-21 05:44:33.679105
34442	1334	\N	\N	634	1	standalone	2026-06-21 05:44:32.384845
34443	1334	\N	\N	635	1	standalone	2026-06-21 05:44:32.384845
34444	1334	\N	\N	636	1	standalone	2026-06-21 05:44:32.384845
34520	1322	\N	\N	1518	1	standalone	2026-06-21 05:44:32.524103
34522	1322	\N	\N	2500	1	standalone	2026-06-21 05:44:32.524103
36370	1329	\N	\N	234	1	standalone	2026-06-21 05:44:34.694773
36372	1329	\N	\N	1261	1	standalone	2026-06-21 05:44:34.694773
36368	1329	\N	\N	1891	1	standalone	2026-06-21 05:44:34.694773
36369	1329	\N	\N	1893	1	standalone	2026-06-21 05:44:34.694773
34748	1322	\N	\N	1110	1	standalone	2026-06-21 05:44:32.790749
35086	1330	\N	\N	2611	1	standalone	2026-06-21 05:44:33.176383
35087	1330	\N	\N	2108	1	standalone	2026-06-21 05:44:33.176383
35091	1330	\N	\N	2117	1	standalone	2026-06-21 05:44:33.176383
35093	1330	\N	\N	268	1	standalone	2026-06-21 05:44:33.176383
35095	1330	\N	\N	475	1	standalone	2026-06-21 05:44:33.176383
35096	1330	\N	\N	1036	1	standalone	2026-06-21 05:44:33.176383
35102	1330	\N	\N	2004	1	standalone	2026-06-21 05:44:33.176383
35103	1330	\N	\N	2006	1	standalone	2026-06-21 05:44:33.176383
35104	1330	\N	\N	2248	1	standalone	2026-06-21 05:44:33.176383
35105	1330	\N	\N	584	1	standalone	2026-06-21 05:44:33.176383
35106	1330	\N	\N	1340	1	standalone	2026-06-21 05:44:33.176383
35107	1330	\N	\N	1341	1	standalone	2026-06-21 05:44:33.176383
35108	1330	\N	\N	3091	1	standalone	2026-06-21 05:44:33.176383
34189	1327	\N	\N	2272	1	domain	2026-06-21 05:44:32.120663
35109	1330	\N	\N	2394	1	standalone	2026-06-21 05:44:33.176383
36107	1333	\N	\N	1372	1	standalone	2026-06-21 05:44:34.412677
35420	1338	\N	\N	1201	1	standalone	2026-06-21 05:44:33.654506
35422	1338	\N	\N	149	1	standalone	2026-06-21 05:44:33.654506
35421	1338	\N	\N	1654	1	standalone	2026-06-21 05:44:33.654506
35769	1335	\N	\N	1184	1	standalone	2026-06-21 05:44:33.953016
35770	1335	\N	\N	2765	1	standalone	2026-06-21 05:44:33.953016
35768	1335	\N	\N	1165	1	standalone	2026-06-21 05:44:33.953016
36172	1330	\N	\N	730	1	standalone	2026-06-21 05:44:34.486965
36228	1330	\N	\N	1676	1	standalone	2026-06-21 05:44:34.548301
33823	1324	\N	\N	1563	1	standalone	2026-06-21 05:44:31.561354
33845	1325	\N	\N	1342	1	standalone	2026-06-21 05:44:31.594534
33841	1325	\N	\N	2894	1	standalone	2026-06-21 05:44:31.594534
33851	1322	\N	\N	1682	1	standalone	2026-06-21 05:44:31.610344
33852	1322	\N	\N	1684	1	standalone	2026-06-21 05:44:31.610344
33892	1326	\N	\N	297	1	standalone	2026-06-21 05:44:31.695317
33906	1326	\N	\N	495	1	standalone	2026-06-21 05:44:31.705238
33898	1326	\N	\N	1873	1	standalone	2026-06-21 05:44:31.705238
33901	1326	\N	\N	1915	1	standalone	2026-06-21 05:44:31.705238
33902	1326	\N	\N	1918	1	standalone	2026-06-21 05:44:31.705238
33958	1327	\N	\N	31	1	standalone	2026-06-21 05:44:31.838377
33961	1327	\N	\N	738	1	standalone	2026-06-21 05:44:31.838377
33962	1327	\N	\N	739	1	standalone	2026-06-21 05:44:31.838377
33963	1327	\N	\N	740	1	standalone	2026-06-21 05:44:31.838377
33964	1327	\N	\N	741	1	standalone	2026-06-21 05:44:31.838377
33957	1327	\N	\N	770	1	standalone	2026-06-21 05:44:31.838377
33968	1327	\N	\N	1235	1	standalone	2026-06-21 05:44:31.838377
33967	1327	\N	\N	1374	1	standalone	2026-06-21 05:44:31.838377
33966	1327	\N	\N	1946	1	standalone	2026-06-21 05:44:31.838377
33977	1322	\N	\N	2032	1	standalone	2026-06-21 05:44:31.853
33983	1328	\N	\N	552	1	standalone	2026-06-21 05:44:31.861214
34008	1328	\N	\N	55	1	standalone	2026-06-21 05:44:31.888851
34009	1328	\N	\N	2432	1	standalone	2026-06-21 05:44:31.888851
34016	1328	\N	\N	2435	1	standalone	2026-06-21 05:44:31.903226
34018	1328	\N	\N	2090	1	standalone	2026-06-21 05:44:31.916829
34022	1328	\N	\N	47	1	standalone	2026-06-21 05:44:31.916829
34019	1328	\N	\N	52	1	standalone	2026-06-21 05:44:31.916829
34046	1328	\N	\N	49	1	standalone	2026-06-21 05:44:31.948158
34050	1328	\N	\N	821	1	standalone	2026-06-21 05:44:31.948158
34051	1328	\N	\N	825	1	standalone	2026-06-21 05:44:31.948158
34053	1328	\N	\N	1996	1	standalone	2026-06-21 05:44:31.948158
34054	1328	\N	\N	2324	1	standalone	2026-06-21 05:44:31.948158
34055	1328	\N	\N	2367	1	standalone	2026-06-21 05:44:31.948158
34056	1328	\N	\N	2389	1	standalone	2026-06-21 05:44:31.948158
34057	1328	\N	\N	2437	1	standalone	2026-06-21 05:44:31.948158
34058	1328	\N	\N	2477	1	standalone	2026-06-21 05:44:31.948158
34086	1327	\N	\N	2252	1	standalone	2026-06-21 05:44:31.995433
34087	1327	\N	\N	2253	1	standalone	2026-06-21 05:44:31.995433
34098	1327	\N	\N	1947	1	standalone	2026-06-21 05:44:32.011888
34119	1327	\N	\N	3382	1	standalone	2026-06-21 05:44:32.044061
36390	1335	\N	\N	772	1	standalone	2026-06-21 05:44:34.710134
36394	1335	\N	\N	2550	1	standalone	2026-06-21 05:44:34.710134
34331	1331	\N	\N	926	1	standalone	2026-06-21 05:44:32.221861
34329	1331	\N	\N	1758	1	standalone	2026-06-21 05:44:32.221861
34340	1332	\N	\N	2016	1	standalone	2026-06-21 05:44:32.238548
34415	1334	\N	\N	2751	1	standalone	2026-06-21 05:44:32.338592
34416	1334	\N	\N	2778	1	standalone	2026-06-21 05:44:32.338592
34454	1334	\N	\N	1120	1	standalone	2026-06-21 05:44:32.409573
34453	1334	\N	\N	2799	1	standalone	2026-06-21 05:44:32.409573
36399	1322	\N	\N	1535	1	standalone	2026-06-21 05:44:34.710134
35070	1330	\N	\N	2114	1	standalone	2026-06-21 05:44:33.144385
34468	1322	\N	\N	1856	1	standalone	2026-06-21 05:44:32.458243
35054	1330	\N	\N	3025	1	standalone	2026-06-21 05:44:33.105449
35052	1330	\N	\N	1615	1	standalone	2026-06-21 05:44:33.105449
35574	1322	\N	\N	2644	1	standalone	2026-06-21 05:44:33.824865
35579	1322	\N	\N	2683	1	standalone	2026-06-21 05:44:33.824865
34490	1322	\N	\N	1810	1	standalone	2026-06-21 05:44:32.483293
34489	1322	\N	\N	2613	1	standalone	2026-06-21 05:44:32.483293
34494	1322	\N	\N	1545	1	standalone	2026-06-21 05:44:32.491539
34516	1322	\N	\N	2402	1	standalone	2026-06-21 05:44:32.524103
34531	1322	\N	\N	3054	1	standalone	2026-06-21 05:44:32.541462
34637	1324	\N	\N	1607	1	standalone	2026-06-21 05:44:32.621305
35379	1327	\N	\N	3217	1	standalone	2026-06-21 05:44:33.581816
34600	1329	\N	\N	468	1	standalone	2026-06-21 05:44:32.605341
34598	1329	\N	\N	2827	1	standalone	2026-06-21 05:44:32.605341
34661	1324	\N	\N	2102	1	standalone	2026-06-21 05:44:32.687403
34666	1324	\N	\N	2046	1	standalone	2026-06-21 05:44:32.706746
34711	1324	\N	\N	307	1	standalone	2026-06-21 05:44:32.746953
34712	1324	\N	\N	313	1	standalone	2026-06-21 05:44:32.746953
34703	1324	\N	\N	434	1	standalone	2026-06-21 05:44:32.746953
34717	1324	\N	\N	1349	1	standalone	2026-06-21 05:44:32.746953
34702	1324	\N	\N	2097	1	standalone	2026-06-21 05:44:32.746953
34706	1324	\N	\N	2103	1	standalone	2026-06-21 05:44:32.746953
34713	1324	\N	\N	2180	1	standalone	2026-06-21 05:44:32.746953
34714	1324	\N	\N	2184	1	standalone	2026-06-21 05:44:32.746953
34726	1327	\N	\N	1975	1	standalone	2026-06-21 05:44:32.760826
36011	1329	\N	\N	1444	1	standalone	2026-06-21 05:44:34.225412
36012	1329	\N	\N	1470	1	standalone	2026-06-21 05:44:34.225412
35149	1336	\N	\N	1049	1	standalone	2026-06-21 05:44:33.244994
36117	1326	\N	\N	2017	1	standalone	2026-06-21 05:44:34.426831
36120	1326	\N	\N	2318	1	standalone	2026-06-21 05:44:34.426831
34815	1329	\N	\N	1361	1	standalone	2026-06-21 05:44:32.894078
34814	1329	\N	\N	460	1	standalone	2026-06-21 05:44:32.894078
36126	1327	\N	\N	247	1	standalone	2026-06-21 05:44:34.442906
36124	1327	\N	\N	426	1	standalone	2026-06-21 05:44:34.442906
36127	1327	\N	\N	2921	1	standalone	2026-06-21 05:44:34.442906
35190	1336	\N	\N	3340	1	standalone	2026-06-21 05:44:33.328484
35191	1336	\N	\N	3341	1	standalone	2026-06-21 05:44:33.328484
35192	1336	\N	\N	1625	1	standalone	2026-06-21 05:44:33.328484
35196	1336	\N	\N	3362	1	standalone	2026-06-21 05:44:33.328484
35197	1336	\N	\N	1635	1	standalone	2026-06-21 05:44:33.328484
35198	1336	\N	\N	3153	1	standalone	2026-06-21 05:44:33.328484
35199	1336	\N	\N	3364	1	standalone	2026-06-21 05:44:33.328484
35200	1336	\N	\N	3365	1	standalone	2026-06-21 05:44:33.328484
35203	1336	\N	\N	1935	1	standalone	2026-06-21 05:44:33.328484
35205	1336	\N	\N	1939	1	standalone	2026-06-21 05:44:33.328484
35206	1336	\N	\N	2164	1	standalone	2026-06-21 05:44:33.328484
35207	1336	\N	\N	1200	1	standalone	2026-06-21 05:44:33.328484
35208	1336	\N	\N	2162	1	standalone	2026-06-21 05:44:33.328484
35209	1336	\N	\N	2167	1	standalone	2026-06-21 05:44:33.328484
35210	1336	\N	\N	2168	1	standalone	2026-06-21 05:44:33.328484
35211	1336	\N	\N	1708	1	standalone	2026-06-21 05:44:33.328484
35212	1336	\N	\N	2981	1	standalone	2026-06-21 05:44:33.328484
35213	1336	\N	\N	2983	1	standalone	2026-06-21 05:44:33.328484
35214	1336	\N	\N	1475	1	standalone	2026-06-21 05:44:33.328484
35215	1336	\N	\N	3004	1	standalone	2026-06-21 05:44:33.328484
35216	1336	\N	\N	3005	1	standalone	2026-06-21 05:44:33.328484
35217	1336	\N	\N	3006	1	standalone	2026-06-21 05:44:33.328484
35218	1336	\N	\N	3007	1	standalone	2026-06-21 05:44:33.328484
35219	1336	\N	\N	3010	1	standalone	2026-06-21 05:44:33.328484
35220	1336	\N	\N	3017	1	standalone	2026-06-21 05:44:33.328484
35222	1336	\N	\N	2309	1	standalone	2026-06-21 05:44:33.328484
35013	1330	\N	\N	1611	1	standalone	2026-06-21 05:44:33.047059
35014	1330	\N	\N	2808	1	standalone	2026-06-21 05:44:33.047059
35226	1334	\N	\N	2217	1	standalone	2026-06-21 05:44:33.345148
35235	1325	\N	\N	3194	1	standalone	2026-06-21 05:44:33.362252
35295	1337	\N	\N	2413	1	standalone	2026-06-21 05:44:33.475768
35258	1329	\N	\N	1408	1	standalone	2026-06-21 05:44:33.395405
35255	1329	\N	\N	1425	1	standalone	2026-06-21 05:44:33.395405
35259	1329	\N	\N	2397	1	standalone	2026-06-21 05:44:33.395405
36198	1330	\N	\N	1955	1	standalone	2026-06-21 05:44:34.51667
35336	1330	\N	\N	2213	1	standalone	2026-06-21 05:44:33.515008
35340	1330	\N	\N	2701	1	standalone	2026-06-21 05:44:33.525251
35369	1330	\N	\N	96	1	standalone	2026-06-21 05:44:33.570978
35367	1330	\N	\N	1409	1	standalone	2026-06-21 05:44:33.570978
35368	1330	\N	\N	2649	1	standalone	2026-06-21 05:44:33.570978
35416	1338	\N	\N	2821	1	standalone	2026-06-21 05:44:33.639104
35462	1338	\N	\N	345	1	standalone	2026-06-21 05:44:33.713754
35459	1338	\N	\N	2174	1	standalone	2026-06-21 05:44:33.713754
35463	1338	\N	\N	2203	1	standalone	2026-06-21 05:44:33.713754
35461	1338	\N	\N	2965	1	standalone	2026-06-21 05:44:33.713754
35448	1338	\N	\N	343	1	standalone	2026-06-21 05:44:33.695541
35493	1323	\N	\N	2590	1	standalone	2026-06-21 05:44:33.727297
35494	1323	\N	\N	1558	1	standalone	2026-06-21 05:44:33.727297
35499	1323	\N	\N	1896	1	standalone	2026-06-21 05:44:33.727297
35507	1323	\N	\N	1910	1	standalone	2026-06-21 05:44:33.743468
35512	1323	\N	\N	2410	1	standalone	2026-06-21 05:44:33.743468
36237	1336	\N	\N	2924	1	standalone	2026-06-21 05:44:34.573818
35777	1329	\N	\N	2377	1	standalone	2026-06-21 05:44:33.969237
36511	1331	\N	\N	159	1	standalone	2026-06-21 05:44:34.88656
35819	1328	\N	\N	1980	1	standalone	2026-06-21 05:44:34.017539
35818	1328	\N	\N	1979	1	standalone	2026-06-21 05:44:34.017539
35825	1322	\N	\N	756	1	standalone	2026-06-21 05:44:34.047416
35839	1322	\N	\N	2772	1	standalone	2026-06-21 05:44:34.063154
35870	1329	\N	\N	920	1	standalone	2026-06-21 05:44:34.096818
35873	1329	\N	\N	1428	1	standalone	2026-06-21 05:44:34.096818
35871	1329	\N	\N	1422	1	standalone	2026-06-21 05:44:34.096818
35872	1329	\N	\N	1423	1	standalone	2026-06-21 05:44:34.096818
35851	1333	\N	\N	378	1	standalone	2026-06-21 05:44:34.080816
35852	1333	\N	\N	3146	1	standalone	2026-06-21 05:44:34.080816
36257	1338	\N	\N	1857	1	standalone	2026-06-21 05:44:34.606516
35882	1329	\N	\N	2705	1	standalone	2026-06-21 05:44:34.115046
35883	1329	\N	\N	2708	1	standalone	2026-06-21 05:44:34.115046
35892	1329	\N	\N	40	1	standalone	2026-06-21 05:44:34.122044
35893	1329	\N	\N	41	1	standalone	2026-06-21 05:44:34.122044
35894	1329	\N	\N	42	1	standalone	2026-06-21 05:44:34.122044
35900	1329	\N	\N	2460	1	standalone	2026-06-21 05:44:34.122044
35901	1329	\N	\N	2462	1	standalone	2026-06-21 05:44:34.122044
35896	1329	\N	\N	2706	1	standalone	2026-06-21 05:44:34.122044
35897	1329	\N	\N	2707	1	standalone	2026-06-21 05:44:34.122044
35898	1329	\N	\N	2710	1	standalone	2026-06-21 05:44:34.122044
35888	1329	\N	\N	2813	1	standalone	2026-06-21 05:44:34.122044
36060	1331	\N	\N	2505	1	standalone	2026-06-21 05:44:34.338931
36084	1331	\N	\N	3060	1	standalone	2026-06-21 05:44:34.371983
36357	1326	\N	\N	3219	1	standalone	2026-06-21 05:44:34.677276
36364	1322	\N	\N	2980	1	standalone	2026-06-21 05:44:34.677276
36403	1338	\N	\N	2418	1	standalone	2026-06-21 05:44:34.725602
36402	1338	\N	\N	2606	1	standalone	2026-06-21 05:44:34.725602
36437	1338	\N	\N	2219	1	standalone	2026-06-21 05:44:34.741485
36450	1335	\N	\N	1158	1	standalone	2026-06-21 05:44:34.741485
36473	1335	\N	\N	1149	1	standalone	2026-06-21 05:44:34.789622
36477	1335	\N	\N	1710	1	standalone	2026-06-21 05:44:34.789622
36505	1326	\N	\N	2342	1	standalone	2026-06-21 05:44:34.861503
34867	1322	\N	\N	683	1	domain	2026-06-21 05:44:32.958835
36777	1328	\N	\N	3213	1	domain	2026-06-21 05:44:35.269741
36876	1328	\N	\N	1000	1	domain	2026-06-21 05:44:35.269741
35817	1328	\N	\N	1675	1	domain	2026-06-21 05:44:34.017539
34263	1331	\N	\N	907	1	domain	2026-06-21 05:44:32.173215
34265	1331	\N	\N	909	1	domain	2026-06-21 05:44:32.173215
34370	1333	\N	\N	1119	1	domain	2026-06-21 05:44:32.270428
35193	1336	\N	\N	1439	1	domain	2026-06-21 05:44:33.328484
35204	1336	\N	\N	1021	1	domain	2026-06-21 05:44:33.328484
36920	1322	\N	\N	1045	1	domain	2026-06-21 05:44:35.269741
36922	1322	\N	\N	1116	1	domain	2026-06-21 05:44:35.269741
34515	1322	\N	\N	1131	1	domain	2026-06-21 05:44:32.524103
34563	1322	\N	\N	1107	1	domain	2026-06-21 05:44:32.55625
34573	1322	\N	\N	2480	1	domain	2026-06-21 05:44:32.55625
34869	1322	\N	\N	1743	1	domain	2026-06-21 05:44:32.958835
37363	1322	\N	\N	1543	1	domain	2026-06-21 05:44:35.269741
34881	1322	\N	\N	1130	1	domain	2026-06-21 05:44:32.975306
34887	1322	\N	\N	3172	1	domain	2026-06-21 05:44:32.975306
34901	1322	\N	\N	1800	1	domain	2026-06-21 05:44:32.975306
34916	1322	\N	\N	2759	1	domain	2026-06-21 05:44:32.975306
36937	1322	\N	\N	1046	1	domain	2026-06-21 05:44:35.269741
34884	1322	\N	\N	1134	1	domain	2026-06-21 05:44:32.975306
34915	1322	\N	\N	2756	1	domain	2026-06-21 05:44:32.975306
34891	1322	\N	\N	1111	1	domain	2026-06-21 05:44:32.975306
34530	1322	\N	\N	2134	1	domain	2026-06-21 05:44:32.541462
34894	1322	\N	\N	785	1	domain	2026-06-21 05:44:32.975306
34914	1322	\N	\N	2737	1	domain	2026-06-21 05:44:32.975306
34946	1322	\N	\N	979	1	domain	2026-06-21 05:44:32.991288
36577	1322	\N	\N	2610	1	domain	2026-06-21 05:44:35.269741
36896	1322	\N	\N	3164	1	domain	2026-06-21 05:44:35.269741
36744	1322	\N	\N	794	1	domain	2026-06-21 05:44:35.269741
36774	1322	\N	\N	364	1	domain	2026-06-21 05:44:35.269741
36850	1322	\N	\N	83	1	domain	2026-06-21 05:44:35.269741
36894	1322	\N	\N	381	1	domain	2026-06-21 05:44:35.269741
36669	1325	\N	\N	777	1	domain	2026-06-21 05:44:35.269741
37164	1325	\N	\N	1072	1	domain	2026-06-21 05:44:35.269741
36810	1326	\N	\N	81	1	domain	2026-06-21 05:44:35.269741
36617	1327	\N	\N	1626	1	domain	2026-06-21 05:44:35.269741
34575	1327	\N	\N	3315	1	domain	2026-06-21 05:44:32.55625
34576	1327	\N	\N	3316	1	domain	2026-06-21 05:44:32.55625
34578	1327	\N	\N	3267	1	domain	2026-06-21 05:44:32.55625
34582	1327	\N	\N	1234	1	domain	2026-06-21 05:44:32.55625
34580	1327	\N	\N	3216	1	domain	2026-06-21 05:44:32.55625
35658	1327	\N	\N	1951	1	domain	2026-06-21 05:44:33.886497
35659	1327	\N	\N	1952	1	domain	2026-06-21 05:44:33.886497
35654	1327	\N	\N	241	1	domain	2026-06-21 05:44:33.886497
35679	1327	\N	\N	1593	1	domain	2026-06-21 05:44:33.886497
35669	1327	\N	\N	1242	1	domain	2026-06-21 05:44:33.886497
35676	1327	\N	\N	3322	1	domain	2026-06-21 05:44:33.886497
36857	1328	\N	\N	995	1	domain	2026-06-21 05:44:35.269741
34015	1328	\N	\N	820	1	domain	2026-06-21 05:44:31.903226
36566	1328	\N	\N	3198	1	domain	2026-06-21 05:44:35.261598
34048	1328	\N	\N	58	1	domain	2026-06-21 05:44:31.948158
33992	1328	\N	\N	446	1	domain	2026-06-21 05:44:31.876739
34020	1328	\N	\N	43	1	domain	2026-06-21 05:44:31.916829
34021	1328	\N	\N	45	1	domain	2026-06-21 05:44:31.916829
34220	1329	\N	\N	3293	1	domain	2026-06-21 05:44:32.141353
34237	1329	\N	\N	886	1	domain	2026-06-21 05:44:32.141353
34238	1329	\N	\N	887	1	domain	2026-06-21 05:44:32.141353
35614	1329	\N	\N	1699	1	domain	2026-06-21 05:44:33.824865
34234	1329	\N	\N	883	1	domain	2026-06-21 05:44:32.141353
35615	1329	\N	\N	1700	1	domain	2026-06-21 05:44:33.824865
37343	1329	\N	\N	1529	1	domain	2026-06-21 05:44:35.269741
34923	1329	\N	\N	643	1	domain	2026-06-21 05:44:32.991288
35600	1329	\N	\N	802	1	domain	2026-06-21 05:44:33.824865
36991	1329	\N	\N	115	1	domain	2026-06-21 05:44:35.269741
35478	1329	\N	\N	862	1	domain	2026-06-21 05:44:33.713754
35482	1329	\N	\N	133	1	domain	2026-06-21 05:44:33.713754
35479	1329	\N	\N	863	1	domain	2026-06-21 05:44:33.713754
35483	1329	\N	\N	134	1	domain	2026-06-21 05:44:33.713754
35480	1329	\N	\N	864	1	domain	2026-06-21 05:44:33.713754
35596	1329	\N	\N	1586	1	domain	2026-06-21 05:44:33.824865
35601	1329	\N	\N	803	1	domain	2026-06-21 05:44:33.824865
35617	1329	\N	\N	899	1	domain	2026-06-21 05:44:33.824865
36631	1329	\N	\N	668	1	domain	2026-06-21 05:44:35.269741
35632	1329	\N	\N	957	1	domain	2026-06-21 05:44:33.853972
35635	1329	\N	\N	3339	1	domain	2026-06-21 05:44:33.853972
37117	1329	\N	\N	1453	1	domain	2026-06-21 05:44:35.269741
36643	1329	\N	\N	26	1	domain	2026-06-21 05:44:35.269741
36990	1329	\N	\N	844	1	domain	2026-06-21 05:44:35.269741
36721	1329	\N	\N	793	1	domain	2026-06-21 05:44:35.269741
36838	1329	\N	\N	986	1	domain	2026-06-21 05:44:35.269741
36878	1329	\N	\N	3239	1	domain	2026-06-21 05:44:35.269741
37055	1329	\N	\N	868	1	domain	2026-06-21 05:44:35.269741
37068	1329	\N	\N	139	1	domain	2026-06-21 05:44:35.269741
36924	1329	\N	\N	111	1	domain	2026-06-21 05:44:35.269741
37043	1329	\N	\N	849	1	domain	2026-06-21 05:44:35.269741
36941	1329	\N	\N	112	1	domain	2026-06-21 05:44:35.269741
37005	1329	\N	\N	850	1	domain	2026-06-21 05:44:35.269741
35053	1330	\N	\N	728	1	domain	2026-06-21 05:44:33.105449
36197	1330	\N	\N	1007	1	domain	2026-06-21 05:44:34.51667
34256	1331	\N	\N	1549	1	domain	2026-06-21 05:44:32.173215
34306	1331	\N	\N	878	1	domain	2026-06-21 05:44:32.191088
34604	1331	\N	\N	601	1	domain	2026-06-21 05:44:32.605341
34619	1331	\N	\N	3309	1	domain	2026-06-21 05:44:32.605341
34271	1331	\N	\N	1855	1	domain	2026-06-21 05:44:32.191088
34622	1331	\N	\N	1216	1	domain	2026-06-21 05:44:32.605341
36860	1331	\N	\N	3284	1	domain	2026-06-21 05:44:35.269741
34276	1331	\N	\N	1415	1	domain	2026-06-21 05:44:32.191088
34278	1331	\N	\N	2608	1	domain	2026-06-21 05:44:32.191088
34288	1331	\N	\N	3143	1	domain	2026-06-21 05:44:32.191088
34277	1331	\N	\N	973	1	domain	2026-06-21 05:44:32.191088
34606	1331	\N	\N	603	1	domain	2026-06-21 05:44:32.605341
34282	1331	\N	\N	384	1	domain	2026-06-21 05:44:32.191088
36510	1331	\N	\N	1544	1	domain	2026-06-21 05:44:34.88656
34293	1331	\N	\N	1644	1	domain	2026-06-21 05:44:32.191088
34305	1331	\N	\N	1218	1	domain	2026-06-21 05:44:32.191088
34296	1331	\N	\N	3245	1	domain	2026-06-21 05:44:32.191088
34307	1331	\N	\N	879	1	domain	2026-06-21 05:44:32.191088
34304	1331	\N	\N	1215	1	domain	2026-06-21 05:44:32.191088
34633	1331	\N	\N	3069	1	domain	2026-06-21 05:44:32.605341
34607	1331	\N	\N	702	1	domain	2026-06-21 05:44:32.605341
36698	1331	\N	\N	1640	1	domain	2026-06-21 05:44:35.269741
36746	1331	\N	\N	1642	1	domain	2026-06-21 05:44:35.269741
34614	1331	\N	\N	933	1	domain	2026-06-21 05:44:32.605341
34626	1331	\N	\N	3043	1	domain	2026-06-21 05:44:32.605341
34618	1331	\N	\N	3168	1	domain	2026-06-21 05:44:32.605341
34623	1331	\N	\N	881	1	domain	2026-06-21 05:44:32.605341
36788	1332	\N	\N	796	1	domain	2026-06-21 05:44:35.269741
36817	1332	\N	\N	978	1	domain	2026-06-21 05:44:35.269741
36902	1333	\N	\N	2127	1	domain	2026-06-21 05:44:35.269741
36332	1333	\N	\N	828	1	domain	2026-06-21 05:44:34.652893
36704	1334	\N	\N	964	1	domain	2026-06-21 05:44:35.269741
36965	1334	\N	\N	1032	1	domain	2026-06-21 05:44:35.269741
37080	1334	\N	\N	141	1	domain	2026-06-21 05:44:35.269741
37295	1334	\N	\N	1807	1	domain	2026-06-21 05:44:35.269741
34414	1334	\N	\N	1122	1	domain	2026-06-21 05:44:32.338592
35731	1335	\N	\N	1031	1	domain	2026-06-21 05:44:33.92599
37355	1335	\N	\N	1536	1	domain	2026-06-21 05:44:35.269741
35715	1335	\N	\N	3390	1	domain	2026-06-21 05:44:33.92599
35717	1335	\N	\N	3152	1	domain	2026-06-21 05:44:33.92599
35718	1335	\N	\N	2832	1	domain	2026-06-21 05:44:33.92599
35740	1335	\N	\N	335	1	domain	2026-06-21 05:44:33.92599
35752	1335	\N	\N	1304	1	domain	2026-06-21 05:44:33.92599
35732	1335	\N	\N	91	1	domain	2026-06-21 05:44:33.92599
36974	1335	\N	\N	836	1	domain	2026-06-21 05:44:35.269741
35743	1335	\N	\N	347	1	domain	2026-06-21 05:44:33.92599
35746	1335	\N	\N	350	1	domain	2026-06-21 05:44:33.92599
35748	1335	\N	\N	2025	1	domain	2026-06-21 05:44:33.92599
35756	1335	\N	\N	1317	1	domain	2026-06-21 05:44:33.92599
35759	1335	\N	\N	2406	1	domain	2026-06-21 05:44:33.92599
36687	1335	\N	\N	3397	1	domain	2026-06-21 05:44:35.269741
37069	1335	\N	\N	1729	1	domain	2026-06-21 05:44:35.269741
35194	1336	\N	\N	1631	1	domain	2026-06-21 05:44:33.328484
36234	1336	\N	\N	2187	1	domain	2026-06-21 05:44:34.566037
36233	1336	\N	\N	2973	1	domain	2026-06-21 05:44:34.566037
36269	1338	\N	\N	1564	1	domain	2026-06-21 05:44:34.620015
36274	1338	\N	\N	195	1	domain	2026-06-21 05:44:34.620015
36279	1338	\N	\N	1659	1	domain	2026-06-21 05:44:34.620015
36273	1338	\N	\N	615	1	domain	2026-06-21 05:44:34.620015
36298	1338	\N	\N	2840	1	domain	2026-06-21 05:44:34.620015
36275	1338	\N	\N	988	1	domain	2026-06-21 05:44:34.620015
36278	1338	\N	\N	3163	1	domain	2026-06-21 05:44:34.620015
36277	1338	\N	\N	3227	1	domain	2026-06-21 05:44:34.620015
36282	1338	\N	\N	874	1	domain	2026-06-21 05:44:34.620015
36281	1338	\N	\N	873	1	domain	2026-06-21 05:44:34.620015
36289	1338	\N	\N	157	1	domain	2026-06-21 05:44:34.620015
36576	1339	\N	\N	919	1	domain	2026-06-21 05:44:35.269741
37570	1340	\N	\N	1	0.8	ai	2026-06-21 08:00:36.815933
37571	1340	\N	\N	2	0.8	ai	2026-06-21 08:00:36.815933
37572	1340	\N	\N	3	0.8	ai	2026-06-21 08:00:36.815933
37573	1340	\N	\N	4	0.8	ai	2026-06-21 08:00:36.815933
37574	1340	\N	\N	5	0.8	ai	2026-06-21 08:00:36.815933
37575	1340	\N	\N	6	0.8	ai	2026-06-21 08:00:36.815933
37576	1340	\N	\N	167	0.8	ai	2026-06-21 08:00:36.815933
37577	1340	\N	\N	163	0.8	ai	2026-06-21 08:00:36.815933
37578	1340	\N	\N	164	0.8	ai	2026-06-21 08:00:36.815933
37579	1341	\N	\N	168	0.8	ai	2026-06-21 08:00:36.840664
37580	1341	\N	\N	169	0.8	ai	2026-06-21 08:00:36.840664
37581	1341	\N	\N	170	0.8	ai	2026-06-21 08:00:36.840664
37582	1342	\N	\N	174	0.8	ai	2026-06-21 08:00:36.935169
37583	1342	\N	\N	175	0.8	ai	2026-06-21 08:00:36.935169
37584	1342	\N	\N	176	0.8	ai	2026-06-21 08:00:36.935169
37585	1342	\N	\N	177	0.8	ai	2026-06-21 08:00:36.935169
37586	1342	\N	\N	178	0.8	ai	2026-06-21 08:00:36.935169
37587	1342	\N	\N	11	0.8	ai	2026-06-21 08:00:36.935169
37588	1342	\N	\N	12	0.8	ai	2026-06-21 08:00:36.935169
37589	1342	\N	\N	63	0.8	ai	2026-06-21 08:00:36.935169
37590	1342	\N	\N	64	0.8	ai	2026-06-21 08:00:36.935169
37591	1342	\N	\N	65	0.8	ai	2026-06-21 08:00:36.935169
37592	1342	\N	\N	66	0.8	ai	2026-06-21 08:00:36.935169
37593	1342	\N	\N	67	0.8	ai	2026-06-21 08:00:36.935169
37594	1342	\N	\N	68	0.8	ai	2026-06-21 08:00:36.935169
37595	1342	\N	\N	69	0.8	ai	2026-06-21 08:00:36.935169
37596	1342	\N	\N	70	0.8	ai	2026-06-21 08:00:36.935169
37597	1342	\N	\N	71	0.8	ai	2026-06-21 08:00:36.935169
37598	1342	\N	\N	72	0.8	ai	2026-06-21 08:00:36.935169
37599	1342	\N	\N	73	0.8	ai	2026-06-21 08:00:36.935169
37600	1342	\N	\N	74	0.8	ai	2026-06-21 08:00:36.935169
37601	1342	\N	\N	75	0.8	ai	2026-06-21 08:00:36.935169
37602	1342	\N	\N	76	0.8	ai	2026-06-21 08:00:36.935169
37603	1342	\N	\N	77	0.8	ai	2026-06-21 08:00:36.935169
37604	1342	\N	\N	78	0.8	ai	2026-06-21 08:00:36.935169
37605	1342	\N	\N	79	0.8	ai	2026-06-21 08:00:36.935169
37606	1342	\N	\N	80	0.8	ai	2026-06-21 08:00:36.935169
37607	1342	\N	\N	81	0.8	ai	2026-06-21 08:00:36.935169
37608	1342	\N	\N	82	0.8	ai	2026-06-21 08:00:36.935169
37609	1342	\N	\N	118	0.8	ai	2026-06-21 08:00:36.935169
37610	1342	\N	\N	120	0.8	ai	2026-06-21 08:00:36.935169
37611	1342	\N	\N	125	0.8	ai	2026-06-21 08:00:36.935169
37612	1342	\N	\N	126	0.8	ai	2026-06-21 08:00:36.935169
37613	1342	\N	\N	130	0.8	ai	2026-06-21 08:00:36.935169
37614	1342	\N	\N	135	0.8	ai	2026-06-21 08:00:36.935169
37615	1343	\N	\N	4	0.8	ai	2026-06-21 08:00:37.083169
37616	1343	\N	\N	5	0.8	ai	2026-06-21 08:00:37.083169
37617	1343	\N	\N	6	0.8	ai	2026-06-21 08:00:37.083169
37618	1343	\N	\N	7	0.8	ai	2026-06-21 08:00:37.083169
37619	1344	\N	\N	9	0.8	ai	2026-06-21 08:00:37.285843
37620	1344	\N	\N	172	0.8	ai	2026-06-21 08:00:37.285843
37621	1344	\N	\N	173	0.8	ai	2026-06-21 08:00:37.285843
37622	1344	\N	\N	179	0.8	ai	2026-06-21 08:00:37.285843
37623	1344	\N	\N	19	0.8	ai	2026-06-21 08:00:37.285843
37624	1344	\N	\N	20	0.8	ai	2026-06-21 08:00:37.285843
37625	1344	\N	\N	21	0.8	ai	2026-06-21 08:00:37.285843
37626	1344	\N	\N	23	0.8	ai	2026-06-21 08:00:37.285843
37627	1344	\N	\N	24	0.8	ai	2026-06-21 08:00:37.285843
37628	1344	\N	\N	25	0.8	ai	2026-06-21 08:00:37.285843
37629	1344	\N	\N	36	0.8	ai	2026-06-21 08:00:37.285843
37630	1344	\N	\N	37	0.8	ai	2026-06-21 08:00:37.285843
37631	1344	\N	\N	38	0.8	ai	2026-06-21 08:00:37.285843
37632	1344	\N	\N	39	0.8	ai	2026-06-21 08:00:37.285843
37633	1344	\N	\N	40	0.8	ai	2026-06-21 08:00:37.285843
37634	1344	\N	\N	41	0.8	ai	2026-06-21 08:00:37.285843
37635	1344	\N	\N	42	0.8	ai	2026-06-21 08:00:37.285843
37636	1344	\N	\N	104	0.8	ai	2026-06-21 08:00:37.285843
37637	1344	\N	\N	105	0.8	ai	2026-06-21 08:00:37.285843
37638	1344	\N	\N	106	0.8	ai	2026-06-21 08:00:37.285843
37639	1344	\N	\N	107	0.8	ai	2026-06-21 08:00:37.285843
37640	1344	\N	\N	108	0.8	ai	2026-06-21 08:00:37.285843
37641	1344	\N	\N	109	0.8	ai	2026-06-21 08:00:37.285843
37642	1344	\N	\N	110	0.8	ai	2026-06-21 08:00:37.285843
37643	1344	\N	\N	111	0.8	ai	2026-06-21 08:00:37.285843
37644	1344	\N	\N	112	0.8	ai	2026-06-21 08:00:37.285843
37645	1344	\N	\N	113	0.8	ai	2026-06-21 08:00:37.285843
37646	1344	\N	\N	114	0.8	ai	2026-06-21 08:00:37.285843
37647	1344	\N	\N	115	0.8	ai	2026-06-21 08:00:37.285843
37648	1344	\N	\N	116	0.8	ai	2026-06-21 08:00:37.285843
37649	1344	\N	\N	117	0.8	ai	2026-06-21 08:00:37.285843
37650	1308	\N	\N	19	0.8	ai	2026-06-21 08:00:37.285843
37651	1308	\N	\N	17	0.8	ai	2026-06-21 08:00:37.285843
37652	1308	\N	\N	31	0.8	ai	2026-06-21 08:00:37.285843
37653	1308	\N	\N	32	0.8	ai	2026-06-21 08:00:37.285843
37654	1308	\N	\N	33	0.8	ai	2026-06-21 08:00:37.285843
37655	1308	\N	\N	34	0.8	ai	2026-06-21 08:00:37.285843
37656	1314	\N	\N	9	0.8	ai	2026-06-21 08:00:37.285843
37657	1314	\N	\N	10	0.8	ai	2026-06-21 08:00:37.285843
37658	1345	\N	\N	181	0.8	ai	2026-06-21 08:00:37.383692
37659	1345	\N	\N	182	0.8	ai	2026-06-21 08:00:37.383692
37660	1345	\N	\N	183	0.8	ai	2026-06-21 08:00:37.383692
37661	1345	\N	\N	43	0.8	ai	2026-06-21 08:00:37.383692
37662	1345	\N	\N	44	0.8	ai	2026-06-21 08:00:37.383692
37663	1345	\N	\N	45	0.8	ai	2026-06-21 08:00:37.383692
37664	1345	\N	\N	46	0.8	ai	2026-06-21 08:00:37.383692
37665	1345	\N	\N	47	0.8	ai	2026-06-21 08:00:37.383692
37666	1345	\N	\N	48	0.8	ai	2026-06-21 08:00:37.383692
37667	1345	\N	\N	49	0.8	ai	2026-06-21 08:00:37.383692
37668	1345	\N	\N	50	0.8	ai	2026-06-21 08:00:37.383692
37669	1345	\N	\N	51	0.8	ai	2026-06-21 08:00:37.383692
37670	1345	\N	\N	52	0.8	ai	2026-06-21 08:00:37.383692
37671	1345	\N	\N	53	0.8	ai	2026-06-21 08:00:37.383692
37672	1345	\N	\N	54	0.8	ai	2026-06-21 08:00:37.383692
37673	1345	\N	\N	55	0.8	ai	2026-06-21 08:00:37.383692
37674	1345	\N	\N	56	0.8	ai	2026-06-21 08:00:37.383692
37675	1345	\N	\N	57	0.8	ai	2026-06-21 08:00:37.383692
37676	1345	\N	\N	58	0.8	ai	2026-06-21 08:00:37.383692
37677	1345	\N	\N	59	0.8	ai	2026-06-21 08:00:37.383692
37678	1345	\N	\N	60	0.8	ai	2026-06-21 08:00:37.383692
37679	1345	\N	\N	61	0.8	ai	2026-06-21 08:00:37.383692
37680	1345	\N	\N	62	0.8	ai	2026-06-21 08:00:37.383692
37681	1346	\N	\N	180	0.8	ai	2026-06-21 08:00:37.426194
37682	1346	\N	\N	137	0.8	ai	2026-06-21 08:00:37.426194
37683	1347	\N	\N	184	0.8	ai	2026-06-21 08:00:37.447173
37684	1347	\N	\N	187	0.8	ai	2026-06-21 08:00:37.447173
37685	1347	\N	\N	100	0.8	ai	2026-06-21 08:00:37.447173
37686	1348	\N	\N	185	0.8	ai	2026-06-21 08:00:37.474625
37687	1348	\N	\N	186	0.8	ai	2026-06-21 08:00:37.474625
37688	1348	\N	\N	92	0.8	ai	2026-06-21 08:00:37.474625
37689	1348	\N	\N	93	0.8	ai	2026-06-21 08:00:37.474625
37690	1348	\N	\N	102	0.8	ai	2026-06-21 08:00:37.474625
37691	1348	\N	\N	103	0.8	ai	2026-06-21 08:00:37.474625
37692	1349	\N	\N	188	0.8	ai	2026-06-21 08:00:37.51585
37693	1349	\N	\N	96	0.8	ai	2026-06-21 08:00:37.51585
37694	1349	\N	\N	97	0.8	ai	2026-06-21 08:00:37.51585
37695	1349	\N	\N	98	0.8	ai	2026-06-21 08:00:37.51585
37696	1349	\N	\N	99	0.8	ai	2026-06-21 08:00:37.51585
37697	1307	\N	\N	123	0.8	ai	2026-06-21 08:00:37.51585
37698	1350	\N	\N	190	0.8	ai	2026-06-21 08:00:37.577784
37699	1350	\N	\N	94	0.8	ai	2026-06-21 08:00:37.577784
37700	1350	\N	\N	95	0.8	ai	2026-06-21 08:00:37.577784
37701	1306	\N	\N	197	0.8	ai	2026-06-21 08:00:37.577784
37702	1306	\N	\N	156	0.8	ai	2026-06-21 08:00:37.577784
37703	1351	\N	\N	28	0.8	ai	2026-06-21 08:00:37.595979
37704	1351	\N	\N	29	0.8	ai	2026-06-21 08:00:37.595979
37705	1352	\N	\N	83	0.8	ai	2026-06-21 08:00:37.630334
37706	1352	\N	\N	84	0.8	ai	2026-06-21 08:00:37.630334
37707	1352	\N	\N	85	0.8	ai	2026-06-21 08:00:37.630334
37708	1352	\N	\N	86	0.8	ai	2026-06-21 08:00:37.630334
37709	1352	\N	\N	87	0.8	ai	2026-06-21 08:00:37.630334
37710	1352	\N	\N	88	0.8	ai	2026-06-21 08:00:37.630334
37711	1352	\N	\N	89	0.8	ai	2026-06-21 08:00:37.630334
37712	1352	\N	\N	90	0.8	ai	2026-06-21 08:00:37.630334
37713	1352	\N	\N	91	0.8	ai	2026-06-21 08:00:37.630334
37714	1353	\N	\N	123	0.8	ai	2026-06-21 08:00:37.64713
37715	1354	\N	\N	127	0.8	ai	2026-06-21 08:00:37.665773
37716	1354	\N	\N	128	0.8	ai	2026-06-21 08:00:37.665773
37717	1354	\N	\N	129	0.8	ai	2026-06-21 08:00:37.665773
37718	1355	\N	\N	129	0.8	ai	2026-06-21 08:00:37.702353
37719	1355	\N	\N	131	0.8	ai	2026-06-21 08:00:37.702353
37720	1355	\N	\N	132	0.8	ai	2026-06-21 08:00:37.702353
37721	1355	\N	\N	133	0.8	ai	2026-06-21 08:00:37.702353
37722	1355	\N	\N	134	0.8	ai	2026-06-21 08:00:37.702353
37723	1355	\N	\N	136	0.8	ai	2026-06-21 08:00:37.702353
37724	1356	\N	\N	142	0.8	ai	2026-06-21 08:00:37.7332
37725	1356	\N	\N	143	0.8	ai	2026-06-21 08:00:37.7332
37726	1356	\N	\N	144	0.8	ai	2026-06-21 08:00:37.7332
37727	1356	\N	\N	145	0.8	ai	2026-06-21 08:00:37.7332
37728	1356	\N	\N	146	0.8	ai	2026-06-21 08:00:37.7332
37729	1356	\N	\N	147	0.8	ai	2026-06-21 08:00:37.7332
37730	1356	\N	\N	148	0.8	ai	2026-06-21 08:00:37.7332
37731	1357	\N	\N	159	0.8	ai	2026-06-21 08:00:37.752759
37732	1357	\N	\N	160	0.8	ai	2026-06-21 08:00:37.752759
37733	1357	\N	\N	161	0.8	ai	2026-06-21 08:00:37.752759
37734	1357	\N	\N	162	0.8	ai	2026-06-21 08:00:37.752759
37735	1358	\N	\N	157	0.8	ai	2026-06-21 08:00:37.770836
37736	1358	\N	\N	158	0.8	ai	2026-06-21 08:00:37.770836
37737	1324	4425	\N	\N	\N	ai_normalized	2026-06-21 08:08:54.172882
37738	1330	4426	\N	\N	\N	ai_normalized	2026-06-21 08:08:57.109499
37739	1334	4427	\N	\N	\N	ai_normalized	2026-06-21 08:08:59.519852
37740	1322	4428	\N	\N	\N	ai_normalized	2026-06-21 08:09:02.201974
37741	1336	4429	\N	\N	\N	ai_normalized	2026-06-21 08:09:04.838401
37742	1327	4430	\N	\N	\N	ai_normalized	2026-06-21 08:09:12.875457
37743	1305	4431	\N	\N	\N	ai_normalized	2026-06-21 08:09:12.878532
37744	1307	4432	\N	\N	\N	ai_normalized	2026-06-21 08:09:12.879542
37745	1305	4433	\N	\N	\N	ai_normalized	2026-06-21 08:09:12.901734
37746	1331	4434	\N	\N	\N	ai_normalized	2026-06-21 08:09:19.12666
37747	1331	4435	\N	\N	\N	ai_normalized	2026-06-21 08:09:19.13131
37748	1311	4436	\N	\N	\N	ai_normalized	2026-06-21 08:09:19.135356
37749	1327	4437	\N	\N	\N	ai_normalized	2026-06-21 08:09:25.603533
37750	1327	4438	\N	\N	\N	ai_normalized	2026-06-21 08:09:25.610552
37751	1327	4439	\N	\N	\N	ai_normalized	2026-06-21 08:09:25.616627
37752	1330	4440	\N	\N	\N	ai_normalized	2026-06-21 08:09:25.620145
37753	1333	4441	\N	\N	\N	ai_normalized	2026-06-21 08:09:30.983253
37754	1303	4442	\N	\N	\N	ai_normalized	2026-06-21 08:09:30.988499
37755	1303	4443	\N	\N	\N	ai_normalized	2026-06-21 08:09:37.13354
37756	1303	4444	\N	\N	\N	ai_normalized	2026-06-21 08:09:37.13755
37757	1303	4445	\N	\N	\N	ai_normalized	2026-06-21 08:09:37.143069
37758	1303	4446	\N	\N	\N	ai_normalized	2026-06-21 08:09:37.146587
37759	1307	4447	\N	\N	\N	ai_normalized	2026-06-21 08:09:39.969593
37760	1328	4448	\N	\N	\N	ai_normalized	2026-06-21 08:09:43.106825
37761	1316	4449	\N	\N	\N	ai_normalized	2026-06-21 08:09:45.684917
37762	1303	4450	\N	\N	\N	ai_normalized	2026-06-21 08:09:50.943677
37763	1303	4451	\N	\N	\N	ai_normalized	2026-06-21 08:09:50.958041
37764	1326	4452	\N	\N	\N	ai_normalized	2026-06-21 08:09:55.122991
37765	1326	4453	\N	\N	\N	ai_normalized	2026-06-21 08:09:55.125008
37766	1327	4454	\N	\N	\N	ai_normalized	2026-06-21 08:09:58.418031
37767	1310	4455	\N	\N	\N	ai_normalized	2026-06-21 08:09:58.421546
37768	1336	4456	\N	\N	\N	ai_normalized	2026-06-21 08:10:04.035086
37769	1336	4457	\N	\N	\N	ai_normalized	2026-06-21 08:10:04.038288
37770	1336	4458	\N	\N	\N	ai_normalized	2026-06-21 08:10:04.042383
37771	1336	4459	\N	\N	\N	ai_normalized	2026-06-21 08:10:04.045538
37772	1322	4460	\N	\N	\N	ai_normalized	2026-06-21 08:10:06.510606
37773	1306	4461	\N	\N	\N	ai_normalized	2026-06-21 08:10:12.272703
37774	1338	4462	\N	\N	\N	ai_normalized	2026-06-21 08:10:12.27666
37775	1306	4463	\N	\N	\N	ai_normalized	2026-06-21 08:10:12.2797
37776	1306	4464	\N	\N	\N	ai_normalized	2026-06-21 08:10:12.280747
37777	1303	4465	\N	\N	\N	ai_normalized	2026-06-21 08:10:16.717824
37778	1303	4466	\N	\N	\N	ai_normalized	2026-06-21 08:10:16.719827
37779	1303	4467	\N	\N	\N	ai_normalized	2026-06-21 08:10:20.736805
37780	1303	4468	\N	\N	\N	ai_normalized	2026-06-21 08:10:20.739808
37781	1327	4469	\N	\N	\N	ai_normalized	2026-06-21 08:10:24.41479
37782	1305	4470	\N	\N	\N	ai_normalized	2026-06-21 08:10:24.41879
37783	1330	4471	\N	\N	\N	ai_normalized	2026-06-21 08:10:28.63042
37784	1330	4472	\N	\N	\N	ai_normalized	2026-06-21 08:10:28.631847
37785	1337	4473	\N	\N	\N	ai_normalized	2026-06-21 08:10:31.51987
37786	1323	4474	\N	\N	\N	ai_normalized	2026-06-21 08:10:37.495681
37787	1325	4475	\N	\N	\N	ai_normalized	2026-06-21 08:10:37.50068
37788	1330	4476	\N	\N	\N	ai_normalized	2026-06-21 08:10:42.472226
37789	1306	4477	\N	\N	\N	ai_normalized	2026-06-21 08:10:42.475513
37790	1326	4478	\N	\N	\N	ai_normalized	2026-06-21 08:10:48.756727
37791	1322	4479	\N	\N	\N	ai_normalized	2026-06-21 08:10:48.758856
37792	1304	4480	\N	\N	\N	ai_normalized	2026-06-21 08:10:48.759953
\.


--
-- Data for Name: grc_common_control_groups; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_common_control_groups (id, tenant_id, code, name, description, category, domain, keywords, ai_summary, evidence_types, created_at, updated_at, created_by, run_id) FROM stdin;
1303	1	DOM-01	Data Protection & Privacy	\N	Data Protection & Privacy	Data Protection & Privacy	[]	\N	[]	2026-06-20 19:40:05.678851	2026-06-20 19:40:05.678851	\N	15
1304	1	DOM-02	Governance, Risk & Compliance	\N	Governance, Risk & Compliance	Governance, Risk & Compliance	[]	\N	[]	2026-06-20 19:40:05.819728	2026-06-20 19:40:05.819728	\N	15
1305	1	DOM-03	Access Control & Identity Management	\N	Access Control & Identity Management	Access Control & Identity Management	[]	\N	[]	2026-06-20 19:40:05.909364	2026-06-20 19:40:05.909364	\N	15
1306	1	DOM-04	Incident Management	\N	Incident Management	Incident Management	[]	\N	[]	2026-06-20 19:40:05.983272	2026-06-20 19:40:05.983272	\N	15
1307	1	DOM-05	Network Security	\N	Network Security	Network Security	[]	\N	[]	2026-06-20 19:40:06.020228	2026-06-20 19:40:06.020228	\N	15
1308	1	DOM-06	Asset Management	\N	Asset Management	Asset Management	[]	\N	[]	2026-06-20 19:40:06.05772	2026-06-20 19:40:06.05772	\N	15
1309	1	DOM-07	Application & Software Security	\N	Application & Software Security	Application & Software Security	[]	\N	[]	2026-06-20 19:40:06.090323	2026-06-20 19:40:06.090323	\N	15
1310	1	DOM-08	Logging, Monitoring & Detection	\N	Logging, Monitoring & Detection	Logging, Monitoring & Detection	[]	\N	[]	2026-06-20 19:40:06.115398	2026-06-20 19:40:06.115398	\N	15
1311	1	DOM-09	Business Continuity & Resilience	\N	Business Continuity & Resilience	Business Continuity & Resilience	[]	\N	[]	2026-06-20 19:40:06.153845	2026-06-20 19:40:06.153845	\N	15
1312	1	DOM-10	Third-Party & Supply Chain Risk	\N	Third-Party & Supply Chain Risk	Third-Party & Supply Chain Risk	[]	\N	[]	2026-06-20 19:40:06.188625	2026-06-20 19:40:06.188625	\N	15
1313	1	DOM-11	Physical & Environmental Security	\N	Physical & Environmental Security	Physical & Environmental Security	[]	\N	[]	2026-06-20 19:40:06.205214	2026-06-20 19:40:06.205214	\N	15
1314	1	DOM-12	Human Resources Security	\N	Human Resources Security	Human Resources Security	[]	\N	[]	2026-06-20 19:40:06.228962	2026-06-20 19:40:06.228962	\N	15
1315	1	DOM-13	Audit & Assurance	\N	Audit & Assurance	Audit & Assurance	[]	\N	[]	2026-06-20 19:40:06.263036	2026-06-20 19:40:06.263036	\N	15
1316	1	DOM-14	Cryptography & Key Management	\N	Cryptography & Key Management	Cryptography & Key Management	[]	\N	[]	2026-06-20 19:40:06.287161	2026-06-20 19:40:06.287161	\N	15
1317	1	DOM-15	Awareness & Training	\N	Awareness & Training	Awareness & Training	[]	\N	[]	2026-06-20 19:40:06.320412	2026-06-20 19:40:06.320412	\N	15
1318	1	DOM-16	Configuration & Change Management	\N	Configuration & Change Management	Configuration & Change Management	[]	\N	[]	2026-06-20 19:40:06.368567	2026-06-20 19:40:06.368567	\N	15
1319	1	DOM-17	Vulnerability & Threat Management	\N	Vulnerability & Threat Management	Vulnerability & Threat Management	[]	\N	[]	2026-06-20 19:40:06.422736	2026-06-20 19:40:06.422736	\N	15
1320	1	DOM-99	Other / Uncategorized	\N	Other / Uncategorized	Other / Uncategorized	[]	\N	[]	2026-06-20 19:55:00.249855	2026-06-20 19:55:00.249855	\N	15
1322	1	FDOM-01	Governance, Risk & Compliance	\N	Governance, Risk & Compliance	Governance, Risk & Compliance	[]	\N	[]	2026-06-21 05:44:31.405077	2026-06-21 05:44:31.405077	\N	18
1323	1	FDOM-02	Cryptography & Key Management	\N	Cryptography & Key Management	Cryptography & Key Management	[]	\N	[]	2026-06-21 05:44:31.485335	2026-06-21 05:44:31.485335	\N	18
1324	1	FDOM-03	Awareness & Training	\N	Awareness & Training	Awareness & Training	[]	\N	[]	2026-06-21 05:44:31.544848	2026-06-21 05:44:31.544848	\N	18
1325	1	FDOM-04	Human Resources Security	\N	Human Resources Security	Human Resources Security	[]	\N	[]	2026-06-21 05:44:31.555145	2026-06-21 05:44:31.555145	\N	18
1326	1	FDOM-05	Network Security	\N	Network Security	Network Security	[]	\N	[]	2026-06-21 05:44:31.610344	2026-06-21 05:44:31.610344	\N	18
1327	1	FDOM-06	Access Control & Identity Management	\N	Access Control & Identity Management	Access Control & Identity Management	[]	\N	[]	2026-06-21 05:44:31.705238	2026-06-21 05:44:31.705238	\N	18
1328	1	FDOM-07	Physical & Environmental Security	\N	Physical & Environmental Security	Physical & Environmental Security	[]	\N	[]	2026-06-21 05:44:31.844858	2026-06-21 05:44:31.844858	\N	18
1329	1	FDOM-08	Data Protection & Privacy	\N	Data Protection & Privacy	Data Protection & Privacy	[]	\N	[]	2026-06-21 05:44:31.948158	2026-06-21 05:44:31.948158	\N	18
1330	1	FDOM-09	Logging, Monitoring & Detection	\N	Logging, Monitoring & Detection	Logging, Monitoring & Detection	[]	\N	[]	2026-06-21 05:44:32.120663	2026-06-21 05:44:32.120663	\N	18
1331	1	FDOM-10	Business Continuity & Resilience	\N	Business Continuity & Resilience	Business Continuity & Resilience	[]	\N	[]	2026-06-21 05:44:32.159156	2026-06-21 05:44:32.159156	\N	18
1332	1	FDOM-11	Audit & Assurance	\N	Audit & Assurance	Audit & Assurance	[]	\N	[]	2026-06-21 05:44:32.221861	2026-06-21 05:44:32.221861	\N	18
1333	1	FDOM-12	Asset Management	\N	Asset Management	Asset Management	[]	\N	[]	2026-06-21 05:44:32.246697	2026-06-21 05:44:32.246697	\N	18
1334	1	FDOM-13	Third-Party & Supply Chain Risk	\N	Third-Party & Supply Chain Risk	Third-Party & Supply Chain Risk	[]	\N	[]	2026-06-21 05:44:32.312033	2026-06-21 05:44:32.312033	\N	18
1335	1	FDOM-14	Application & Software Security	\N	Application & Software Security	Application & Software Security	[]	\N	[]	2026-06-21 05:44:32.787015	2026-06-21 05:44:32.787015	\N	18
1336	1	FDOM-15	Configuration & Change Management	\N	Configuration & Change Management	Configuration & Change Management	[]	\N	[]	2026-06-21 05:44:32.811257	2026-06-21 05:44:32.811257	\N	18
1337	1	FDOM-16	Vulnerability & Threat Management	\N	Vulnerability & Threat Management	Vulnerability & Threat Management	[]	\N	[]	2026-06-21 05:44:33.395405	2026-06-21 05:44:33.395405	\N	18
1338	1	FDOM-17	Incident Management	\N	Incident Management	Incident Management	[]	\N	[]	2026-06-21 05:44:33.622296	2026-06-21 05:44:33.622296	\N	18
1339	1	FDOM-18	Other / Uncategorized	\N	Other / Uncategorized	Other / Uncategorized	[]	\N	[]	2026-06-21 05:44:34.896809	2026-06-21 05:44:34.896809	\N	18
1340	1	CCG-001	Security Policies and Compliance	Controls related to the development, maintenance, and enforcement of security policies and compliance with organizational and third-party requirements.	Governance	Security	["policy", "compliance", "procedures", "governance"]	\N	[]	2026-06-21 08:00:36.755068	2026-06-21 08:00:36.755068	1	\N
1341	1	CCG-002	Risk Management	Controls focused on identifying, assessing, and managing risks to information systems and data.	Risk Management	Security	["risk assessment", "risk treatment", "risk management"]	\N	[]	2026-06-21 08:00:36.809986	2026-06-21 08:00:36.809986	1	\N
1342	1	CCG-003	Access Control	Controls related to managing access to systems and data, including authentication, authorization, and access reviews.	Access Control	Security	["access control", "authentication", "privileged access", "access", "authorization", "control"]	\N	[]	2026-06-21 08:00:36.83965	2026-06-21 08:00:36.83965	1	\N
1343	1	CCG-004	Awareness and Training	Controls aimed at enhancing security awareness and providing training to personnel to ensure compliance with security policies.	Training and Awareness	Security	["awareness", "training", "education"]	\N	[]	2026-06-21 08:00:36.930425	2026-06-21 08:00:36.930425	1	\N
1344	1	CCG-005	Data Protection and Classification	Controls related to the protection, classification, and secure disposal of data.	Data Protection	Security	["data protection", "classification", "encryption", "information", "data", "protection", "disposal", "information exchange", "security"]	\N	[]	2026-06-21 08:00:37.078086	2026-06-21 08:00:37.078086	1	\N
1345	1	CCG-003-1	Physical and Environmental Security	Controls ensuring physical security and protection of equipment.	Physical Security	Security	["physical security", "equipment", "environmental", "physical", "security"]	\N	[]	2026-06-21 08:00:37.281172	2026-06-21 08:00:37.281172	1	\N
1346	1	CCG-004-1	Cryptography and Key Management	Controls related to the management of cryptographic keys.	Cryptography	Security	["cryptography", "key management", "encryption"]	\N	[]	2026-06-21 08:00:37.377134	2026-06-21 08:00:37.377134	1	\N
1347	1	CCG-005-1	Change and Patch Management	Controls for managing changes and applying patches to systems.	Change Management	Security	["change management", "patch management", "patching", "updates"]	\N	[]	2026-06-21 08:00:37.423655	2026-06-21 08:00:37.423655	1	\N
1348	1	CCG-006	Vulnerability and Malware Management	Controls for managing vulnerabilities and protecting against malware.	Vulnerability Management	Security	["vulnerability", "malware", "protection"]	\N	[]	2026-06-21 08:00:37.444342	2026-06-21 08:00:37.444342	1	\N
1349	1	CCG-007	Logging and Monitoring	Controls related to the logging and monitoring of security events.	Logging & Monitoring	Security	["logging", "monitoring", "audit"]	\N	[]	2026-06-21 08:00:37.464866	2026-06-21 08:00:37.464866	1	\N
1350	1	CCG-009	Backup and Recovery	Controls for ensuring data backup and recovery procedures.	Data Protection	Security	["backup", "recovery", "archival"]	\N	[]	2026-06-21 08:00:37.512621	2026-06-21 08:00:37.512621	1	\N
1351	1	CCG-011	Removable Media Management	Controls for managing the use and handling of removable media.	Media Management	Security	["removable media", "handling procedures"]	\N	[]	2026-06-21 08:00:37.576212	2026-06-21 08:00:37.576212	1	\N
1352	1	CCG-003-2	Operations Management	Controls related to the management and maintenance of IT operations.	Operations Management	Security	["operations", "management", "maintenance", "change management", "procedures"]	\N	[]	2026-06-21 08:00:37.583752	2026-06-21 08:00:37.583752	1	\N
1353	1	CCG-007-1	Health Information Protection	Controls ensuring the protection of healthcare information and management's commitment to data security.	Data Protection	Privacy	["health information", "data protection", "policy"]	\N	[]	2026-06-21 08:00:37.627976	2026-06-21 08:00:37.627976	1	\N
1354	1	CCG-003-3	Third-Party Management	Controls for managing security risks associated with third-party services.	Third-Party Management	Security	["third-party", "vendor", "service"]	\N	[]	2026-06-21 08:00:37.643694	2026-06-21 08:00:37.643694	1	\N
1355	1	CCG-005-2	Software Development and Maintenance	Controls related to secure software development and maintenance practices.	Software Development	Security	["development", "software", "maintenance"]	\N	[]	2026-06-21 08:00:37.661792	2026-06-21 08:00:37.661792	1	\N
1356	1	CCG-006-1	Supply Chain Security	Controls to protect information systems and operations from supply chain threats.	Supply Chain Security	Security	["supply chain", "vendor", "security", "reliability", "components"]	\N	[]	2026-06-21 08:00:37.697067	2026-06-21 08:00:37.697067	1	\N
1357	1	CCG-003-4	Information Systems Continuity	Controls related to the continuity and availability of information systems and applications.	Backup and Recovery	Security	["continuity", "availability", "business continuity"]	\N	[]	2026-06-21 08:00:37.729007	2026-06-21 08:00:37.729007	1	\N
1358	1	CCG-004-2	Situational Awareness and Reporting	Controls focused on maintaining situational awareness and reporting security events and weaknesses.	Logging and Monitoring	Security	["situational awareness", "reporting", "security events"]	\N	[]	2026-06-21 08:00:37.752759	2026-06-21 08:00:37.752759	1	\N
\.


--
-- Data for Name: grc_evidence_control_mappings; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_evidence_control_mappings (id, evidence_id, normalized_control_id, framework_control_id, parsed_control_id, uploaded_framework_id, framework_name, control_code, clause_reference, control_title, matching_rationale, confidence_score, coverage_type, matched_text_snippets, matched_control_language, similarity_score, rule_based_validation, is_locked, locked_at, locked_by, created_at, created_by_ai, assessment_id) FROM stdin;
35	9	\N	\N	1	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
36	9	\N	\N	3	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
37	9	\N	\N	4	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
38	9	\N	\N	8	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
39	9	\N	\N	9	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
40	9	\N	\N	10	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
41	9	\N	\N	11	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
42	9	\N	\N	12	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:24:09.956695	t	\N
47	11	\N	\N	1	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
48	11	\N	\N	3	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
49	11	\N	\N	4	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
50	11	\N	\N	8	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
51	11	\N	\N	9	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
52	11	\N	\N	10	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
53	11	\N	\N	11	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
54	11	\N	\N	12	\N	NC-0150	\N	\N	\N	\N	\N	supporting	[]	\N	\N	f	f	\N	\N	2026-06-18 08:32:30.081766	t	\N
\.


--
-- Data for Name: grc_normalization_runs; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_normalization_runs (id, tenant_id, label, scope, framework_ids, status, is_baseline, created_by, started_at, completed_at, summary) FROM stdin;
15	1	Baseline (recall-fixed, all frameworks)	full	\N	completed	f	\N	2026-06-20 17:48:09.956776	2026-06-20 18:14:05.139675	{"unified_controls": 129, "controls_covered": 2737, "evidence_consolidated": 129, "master_list": ["AI Governance", "API Security Testing", "Acceptable Use of Information and Other Associated Assets", "Access Control Policy Management", "Access Rights Review", "Acquisition Process", "Anti-Malware Controls", "Application Security Testing", "Architecture Design Review", "Asset Inventory Management", "Asset Management", "Audit Logging", "Authentication Controls Monitoring and Reporting", "Background Verification Checks", "Backup System Security", "Benefits Delivery Optimization", "Board Oversight", "Business Continuity Management", "Business Continuity Planning", "Business Continuity Testing and Exercising", "Capacity Management", "Change Management", "Cloud Outsourcing Compliance", "Communication Management", "Compliance Reporting", "Configuration Management", "Content Management", "Contingency Plan Testing", "Contingency Planning", "Contingency Training", "Continuous Improvement", "Continuous Monitoring", "Contractual Termination Rights", "Control Assessments", "Crisis Communication Plans", "Critical Infrastructure Role", "Cryptographic Protection", "Cyber Security Controls", "Cyber Security Governance", "Cyber Security Requirements for Information Assets", "Cyber Security Requirements for Staff", "Cyber Security Requirements for Third Parties", "Cyber Security Risk Management", "Data Breach Management Process", "Data Centre Risk Assessment", "Data Classification", "Data Disposal Compliance", "Data Encryption", "Data Integrity", "Data Inventory Management", "Data Labeling and Handling", "Data Leakage Prevention", "Data Loss Prevention", "Data Management Compliance", "Data Management and Analytics", "Data Management and Personal Data Protection Compliance", "Data Management and Personal Data Protection Plan", "Data Management and Personal Data Protection Strategy", "Data Management and Quality Compliance", "Data Minimization", "Data Processing Compliance", "Data Protection Compliance", "Data Protection by Design and Default", "Data Protection in Transit", "Data Quality Management", "Data Recovery Process", "Data Resource Management", "Data Retention Compliance", "Data Security", "Data Sharing Process", "Data Subject Rights", "Data Transfer Compliance", "Data and System Integrity", "Device and Media Controls", "Disciplinary Process", "Document Management", "Documentation Management", "Email Security", "Employment Terms and Conditions", "Environmental Controls", "External System Services", "Fire Protection and Suppression", "Fraud Awareness and Training", "Fraud Detection", "Governance Framework Management", "Human Resources Security", "ICT Risk Assessment", "ICT Security Policies and Procedures", "IT Control Effectiveness Monitoring", "Identity Theft Prevention Program", "Identity and Access Management", "Implementation Verification", "Incident Communication", "Incident Cooperation", "Incident Detection and Monitoring", "Incident Documentation", "Incident Investigation", "Incident Management", "Incident Monitoring", "Incident Notification", "Incident Reporting", "Incident Response Plan", "Information Exchange", "Information Security Governance", "Information Security Management Program", "Information Security Operations Management", "Information Security Policy Management", "Information Security Risk Management", "Information Security Roles and Responsibilities", "Information Systems Continuity Management", "Integrity and Ethical Values", "Internet Access Control", "Internet Banking Security Controls", "Internet Banking Security Framework", "IoT Access Control", "IoT Monitoring", "IoT Risk Controls", "IoT Security", "Key Management", "Knowledge Management", "Legal and Regulatory Compliance", "Maintenance Performed", "Malware Protection", "Managed Assurance", "Managed Operations", "Managed Performance and Conformance Monitoring", "Managed System of Internal Control", "Management Structure and Authority", "Media Protection Compliance", "Mobile Application Security", "Network Access Control", "Network Architecture Review", "Network Monitoring", "Network Security", "Network Segmentation", "Password Management Systems", "Patch and Update Management", "Patient Rights Compliance", "Physical Access Control", "Physical Security Controls", "Physical Security Monitoring", "Policy Management", "Privacy Monitoring and Enforcement", "Privileged Access Management", "Problem Management", "Project Risk Management", "Quality Assurance", "Recovery Plan Testing", "Remote Access Security", "Remote Device Security", "Resource Requirements for Strategies", "Risk Analysis", "Risk Management", "Risk Monitoring and Reporting", "Secure Coding Standards", "Security Assessment", "Security Awareness and Training", "Security Management Process", "Security Operations Management", "Security Policy Management", "Security Requirements Analysis and Specification", "Security by Design", "Segregation of Duties", "Service Delivery", "Session Management", "Shadow IT Management", "Software Integrity", "Standards Compliance", "Supply Chain Risk Management", "Technology Governance", "Teleworking", "Testing Methodology", "Third Party Agreement Compliance", "Third Party Risk Management", "Threat Intelligence", "Time Synchronization", "Traceability", "User Access Management", "User Access Provisioning", "User Access Review", "User Access Termination / De-provisioning", "User Agreement Compliance", "User Authentication", "User Behavioural Analytics", "User Registration Management", "Vendor Evaluation Standards", "Virtualization Security", "Vulnerability Management", "Wireless Security", "Workstation Security"]}
18	1	Fine-grained baseline (all frameworks)	full	\N	completed	t	\N	2026-06-21 05:44:28.456571	2026-06-21 06:21:34.611011	{"unified_controls": 268, "standalone": 2108, "domains": 18, "evidence_consolidated": 267, "master_list": ["Key Management", "Automatic Scanning of Removable Media", "Audit Log Content Requirements", "Access Establishment and Modification", "Appoint Chief Information Security Officer", "Mobile Device Access Control", "Access Control Policy Management", "Establish Software Inventory", "Data Protection in Transit", "Maintain Information Asset Inventory", "Ensure Compliance with Security Standards", "Legal and Compliance Risk Assessment", "Implement Cryptographic Controls", "Apply Principle of Least Functionality", "Security Role Separation", "Data Loss Prevention", "Centralized Audit Log Management", "Version Control Implementation", "Audit Logging", "Identify and Manage Security Vulnerabilities", "Data Inventory Management", "Internal Controls Effectiveness Monitoring", "Password Change Requirements", "Control Assessments", "Real-Time Fraud Monitoring", "Access Control for Service Providers", "Management Approval for Remote Access", "Network Segmentation", "Secure Log-on Procedures", "Incident Monitoring", "Implement Incident Handling Procedures", "Patch and Update Management", "Resource Monitoring and Adjustment", "System Performance Monitoring", "Audit Log Storage Management", "Network Architecture Review", "Risk Monitoring and Reporting", "Secure Key Management Practices", "Employment Security Policies", "Role Responsibilities and Access", "Anti-Malware Software Updates", "Malicious Code Detection", "Malware Protection Implementation", "Deploy Anti-Malware Solutions", "Incident Response Training", "IT Personnel Capacity Building", "Information Security Management Program", "Phishing Detection and Protection", "Email Server Anti-Malware Protections", "Technology Governance", "Periodic User Access Reviews", "Timely Access Revocation", "Removal of Access Rights", "Least Privilege Principle", "Role-Based Access Management", "Access Rights Management", "Access Rights Review", "Intrusion Prevention Systems", "Information Security Policy Management", "Physical Entry Controls", "Secure Work Areas", "Environmental Threat Protection", "Cabling Security", "Data Center Security", "Physical Security Perimeters", "Mobile Application Security", "Data Backup Execution", "Information Access Management", "Physical Security Controls", "Logical Access Policy Management", "Database Access Restrictions", "Access Control Enforcement", "Access Control for Healthcare Facilities", "Access Control for Network Services", "Access Control for Confidential Information", "Post-Incident Review Process", "Access Control for Information Assets", "Access Control for User Authentication", "Incident Detection and Monitoring", "Governance Framework Management", "Conduct Business Impact Analysis", "Data Minimization", "General Background Verification Checks", "Personnel Screening for Access Authorization", "Maintain Enterprise Asset Inventory", "Inventory of Physical Devices", "Business Continuity Management", "Security Assessment", "Asset Inventory Management", "Define Information Security Roles", "Assign Security Responsibility", "Identify Third Party Risks", "Role-Based Security Training", "Monitor Third Party Services", "Conduct Third Party Risk Assessments", "Establish Third Party Security Policies", "Evaluate Third Party Contracts", "Conduct Independent Vendor Audits", "Assess Vendor Cybersecurity Risks", "Periodic Security Awareness Campaigns", "Third Party Risk Management", "Continual Improvement Framework", "Install Security Patches", "Compliance Monitoring", "Acceptable Use of Information and Other Associated Assets", "Communication Management", "Information Security Learning", "Remediation Process Management", "Audit Log Protection Measures", "General Risk Assessment", "Logging of User Activities", "Risk Analysis", "API Security Testing", "Threat and Vulnerability Assessment", "Restrict Data Transmission", "General Security Awareness Training", "Security Awareness Program Implementation", "Data Leak Prevention Measures", "Crisis Communication Plans", "Secure Disposal Procedures", "Training Records Management", "Customer Security Awareness Programs", "Change Management Policy", "Return of Organizational Assets", "Security Awareness and Training", "Strong User Authentication", "Adopt Secure Coding Standards", "Secure Coding Practices", "Change Testing Procedures", "Emergency Change Procedures", "Production Migration Controls", "Unique User Identification", "Train Developers in Secure Coding", "Establish Baseline Configuration", "Maintain Secure Configurations", "Supplier Change Management", "Controlled Change Management", "Segregate Development and Production Environments", "Implement Configuration Management Practices", "Control Installation of Operational Software", "Data Management and Quality Compliance", "Information System Activity Review", "Configuration Management", "Change Management Segregation", "Third Party Agreement Compliance", "Regular Risk Assessment Process", "Change Planning and Impact Analysis", "Network Access Control", "Identity and Access Management", "Disaster Recovery Plan Testing", "User Registration Management", "General Segregation of Duties", "Post-Implementation Review", "Password Complexity and Length Requirements", "Quality Assurance", "Risk Management", "Allocate Privileges to Systems", "Unauthorized Change Detection", "Rollback Planning for Changes", "Change Impact Assessment", "Change Management", "Control Privileged Access Accounts", "Restrict Administrator Privileges", "Testing and Segregation Controls", "Admin Access Monitoring", "System Design Review", "Audit Trail Review", "Event Logging Procedures", "Change Management Process", "Annual Policy Review", "Sanction Policy Enforcement", "Multi-Factor Authentication Implementation", "Service Delivery", "Formal Disciplinary Process", "Timely Security Updates", "Periodic Penetration Testing", "Regular Vulnerability Scanning", "Vulnerability Handling Procedures", "System-Specific Vulnerability Management", "Technical Vulnerability Control Measures", "Unsuccessful Logon Attempts Management", "Data Retention Compliance", "Vulnerability Management", "Risk Management Process Monitoring", "Business Continuity Exercise Types", "Event Analysis and Correlation", "Incident Classification and Prioritization", "Establish Incident Response Structure", "Unauthorized Activity Monitoring", "Anomaly Detection Mechanisms", "Automated Cyber Attack Monitoring", "Identification and Authentication Policy", "Continuous Monitoring", "Password Protection Measures", "Incident Handling Procedures", "Execute Incident Response Plan", "Incident Response Resources", "Session Management", "Post-Incident Review and Analysis", "Data Encryption", "Test Incident Response Capability", "Incident Management", "Incident Trend Analysis and Learning", "Incident Management Roles and Responsibilities", "Encryption and Key Management", "Test Patches Before Production", "Encrypt Data at Rest", "Encrypt Data in Transit", "Encrypt End-User Devices", "Define Cyber Security Strategy", "Evaluate and Approve Patches", "Establish Cyber Security Function", "Share Threat Intelligence", "Maintenance Performed", "Availability and Capacity Planning", "Implement Appropriate Safeguards", "Collect Threat Intelligence", "Data Classification", "Data Center Access Control", "Physical Access Management", "Information Classification Guidelines", "Facility Access Restrictions", "Authorized Access List Management", "Equipment Protection", "Incident Investigation", "Visitor Access Management", "Implement ICT Third Party Risk Management", "Data Disposal Compliance", "Network Security", "Requirements Definition for Acquisition", "Remote Access Usage Restrictions", "Cyber Security Requirements for Staff", "Assign Asset Ownership", "Anti-Malware Controls", "Physical Security Measures", "Secure Remote Access Implementation", "Data Recovery Process", "Information Security Governance", "Periodic IT Audits", "Media Destruction Methods", "Security in Acquisition Process", "Incident Notification", "Employment Terms and Conditions", "Cyber Security Governance", "Formal Password Management Process", "Data Protection by Design and Default", "Disaster Recovery Test Scenarios", "Data Labeling and Handling", "Fraud Awareness and Training", "Business Continuity Plan Testing", "Network Monitoring", "Secure Data Disposal Policy", "Business Continuity Testing and Exercising", "Device and Media Controls", "Email Security", "Project Risk Management", "Environmental Controls", "Privacy Monitoring and Enforcement", "Breach Notification to Patients", "Breach Notification to DOH", "Time Synchronization", "Problem Management", "Testing Methodology", "Incident Communication", "Physical Security Monitoring", "Security Requirements Analysis and Specification", "Wireless Security", "Security Operations Management"]}
\.


--
-- Data for Name: grc_normalized_control_links; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_normalized_control_links (id, normalized_control_id, parsed_control_id, framework_control_id, mapping_type, created_at) FROM stdin;
21578	4450	606	\N	direct	2026-06-21 08:09:50.938154
21579	4450	1550	\N	direct	2026-06-21 08:09:50.938154
21580	4450	3334	\N	direct	2026-06-21 08:09:50.938154
21581	4450	1414	\N	direct	2026-06-21 08:09:50.938154
21582	4450	2223	\N	direct	2026-06-21 08:09:50.938154
21583	4451	1834	\N	direct	2026-06-21 08:09:50.956525
21584	4451	3106	\N	direct	2026-06-21 08:09:50.956525
21585	4451	645	\N	direct	2026-06-21 08:09:50.956525
21586	4451	1014	\N	direct	2026-06-21 08:09:50.956525
21587	4451	1260	\N	direct	2026-06-21 08:09:50.956525
21588	4452	279	\N	direct	2026-06-21 08:09:55.12099
21589	4452	2419	\N	direct	2026-06-21 08:09:55.12099
21590	4452	697	\N	direct	2026-06-21 08:09:55.12099
21591	4452	2596	\N	direct	2026-06-21 08:09:55.12099
21592	4452	185	\N	direct	2026-06-21 08:09:55.12099
21593	4452	3396	\N	direct	2026-06-21 08:09:55.12099
21594	4452	837	\N	direct	2026-06-21 08:09:55.12099
21595	4452	92	\N	direct	2026-06-21 08:09:55.12099
21596	4452	1726	\N	direct	2026-06-21 08:09:55.12099
21597	4453	1913	\N	direct	2026-06-21 08:09:55.12399
21598	4453	276	\N	direct	2026-06-21 08:09:55.12399
21599	4454	2587	\N	direct	2026-06-21 08:09:58.416028
21600	4454	752	\N	direct	2026-06-21 08:09:58.416028
21601	4454	3320	\N	direct	2026-06-21 08:09:58.416028
21602	4454	699	\N	direct	2026-06-21 08:09:58.416028
21603	4454	1961	\N	direct	2026-06-21 08:09:58.416028
21604	4455	3385	\N	direct	2026-06-21 08:09:58.419538
21605	4455	1561	\N	direct	2026-06-21 08:09:58.419538
21606	4455	3123	\N	direct	2026-06-21 08:09:58.419538
21607	4455	244	\N	direct	2026-06-21 08:09:58.419538
21608	4455	1972	\N	direct	2026-06-21 08:09:58.419538
21609	4456	1835	\N	direct	2026-06-21 08:10:04.034084
21610	4456	1630	\N	direct	2026-06-21 08:10:04.034084
21611	4456	84	\N	direct	2026-06-21 08:10:04.034084
21612	4457	1836	\N	direct	2026-06-21 08:10:04.037082
21613	4457	1574	\N	direct	2026-06-21 08:10:04.037082
21614	4458	3374	\N	direct	2026-06-21 08:10:04.040983
21615	4458	2925	\N	direct	2026-06-21 08:10:04.040983
21616	4458	1275	\N	direct	2026-06-21 08:10:04.040983
21617	4459	2926	\N	direct	2026-06-21 08:10:04.043435
21618	4459	1011	\N	direct	2026-06-21 08:10:04.043435
21619	4460	351	\N	direct	2026-06-21 08:10:06.509604
21620	4460	2843	\N	direct	2026-06-21 08:10:06.509604
21621	4460	3354	\N	direct	2026-06-21 08:10:06.509604
21622	4460	898	\N	direct	2026-06-21 08:10:06.509604
21623	4461	988	\N	direct	2026-06-21 08:10:12.272703
21624	4461	3226	\N	direct	2026-06-21 08:10:12.272703
21625	4461	873	\N	direct	2026-06-21 08:10:12.272703
21626	4462	2822	\N	direct	2026-06-21 08:10:12.275645
21627	4462	2182	\N	direct	2026-06-21 08:10:12.275645
21628	4463	3230	\N	direct	2026-06-21 08:10:12.278743
21629	4463	877	\N	direct	2026-06-21 08:10:12.278743
21630	4463	2178	\N	direct	2026-06-21 08:10:12.278743
21631	4464	3310	\N	direct	2026-06-21 08:10:12.2797
21632	4464	1206	\N	direct	2026-06-21 08:10:12.2797
21633	4464	2179	\N	direct	2026-06-21 08:10:12.2797
21634	4465	2824	\N	direct	2026-06-21 08:10:16.717824
21635	4465	1226	\N	direct	2026-06-21 08:10:16.717824
21636	4466	3239	\N	direct	2026-06-21 08:10:16.718825
21637	4466	139	\N	direct	2026-06-21 08:10:16.718825
21638	4467	1586	\N	direct	2026-06-21 08:10:20.735804
21639	4467	803	\N	direct	2026-06-21 08:10:20.735804
21640	4468	3293	\N	direct	2026-06-21 08:10:20.737806
21641	4468	1699	\N	direct	2026-06-21 08:10:20.737806
21642	4469	2588	\N	direct	2026-06-21 08:10:24.412792
21643	4469	751	\N	direct	2026-06-21 08:10:24.412792
21644	4469	3319	\N	direct	2026-06-21 08:10:24.412792
21645	4469	3369	\N	direct	2026-06-21 08:10:24.412792
21646	4469	1560	\N	direct	2026-06-21 08:10:24.412792
21647	4469	1004	\N	direct	2026-06-21 08:10:24.412792
21648	4470	1585	\N	direct	2026-06-21 08:10:24.416792
21649	4470	241	\N	direct	2026-06-21 08:10:24.416792
21650	4470	3215	\N	direct	2026-06-21 08:10:24.416792
21651	4470	71	\N	direct	2026-06-21 08:10:24.416792
21652	4470	547	\N	direct	2026-06-21 08:10:24.416792
21653	4471	1627	\N	direct	2026-06-21 08:10:28.62942
21654	4471	2736	\N	direct	2026-06-21 08:10:28.62942
21655	4472	2836	\N	direct	2026-06-21 08:10:28.63142
21656	4472	296	\N	direct	2026-06-21 08:10:28.63142
21657	4472	2201	\N	direct	2026-06-21 08:10:28.63142
21658	4472	2774	\N	direct	2026-06-21 08:10:28.63142
21659	4473	1587	\N	direct	2026-06-21 08:10:31.518871
21660	4473	2831	\N	direct	2026-06-21 08:10:31.518871
21661	4473	2945	\N	direct	2026-06-21 08:10:31.518871
21662	4473	1302	\N	direct	2026-06-21 08:10:31.518871
21663	4473	2303	\N	direct	2026-06-21 08:10:31.518871
21664	4474	2591	\N	direct	2026-06-21 08:10:37.493681
21665	4474	180	\N	direct	2026-06-21 08:10:37.493681
21666	4474	3205	\N	direct	2026-06-21 08:10:37.493681
21667	4474	1897	\N	direct	2026-06-21 08:10:37.493681
21668	4474	2825	\N	direct	2026-06-21 08:10:37.493681
21669	4474	866	\N	direct	2026-06-21 08:10:37.493681
21670	4474	1718	\N	direct	2026-06-21 08:10:37.493681
21671	4474	137	\N	direct	2026-06-21 08:10:37.493681
21672	4474	1250	\N	direct	2026-06-21 08:10:37.493681
21673	4475	1	\N	direct	2026-06-21 08:10:37.49868
21674	4475	3252	\N	direct	2026-06-21 08:10:37.49868
21675	4475	1559	\N	direct	2026-06-21 08:10:37.49868
21676	4475	2084	\N	direct	2026-06-21 08:10:37.49868
21677	4475	780	\N	direct	2026-06-21 08:10:37.49868
21678	4475	2894	\N	direct	2026-06-21 08:10:37.49868
21679	4475	2672	\N	direct	2026-06-21 08:10:37.49868
21680	4476	1548	\N	direct	2026-06-21 08:10:42.469917
21681	4476	1845	\N	direct	2026-06-21 08:10:42.469917
21682	4476	599	\N	direct	2026-06-21 08:10:42.469917
21683	4476	3274	\N	direct	2026-06-21 08:10:42.469917
21684	4476	1727	\N	direct	2026-06-21 08:10:42.469917
21685	4477	1547	\N	direct	2026-06-21 08:10:42.474595
21686	4477	1201	\N	direct	2026-06-21 08:10:42.474595
21687	4477	1849	\N	direct	2026-06-21 08:10:42.474595
21688	4477	3388	\N	direct	2026-06-21 08:10:42.474595
21689	4477	608	\N	direct	2026-06-21 08:10:42.474595
21690	4477	2604	\N	direct	2026-06-21 08:10:42.474595
21691	4477	969	\N	direct	2026-06-21 08:10:42.474595
21692	4478	2624	\N	direct	2026-06-21 08:10:48.755727
21693	4478	3120	\N	direct	2026-06-21 08:10:48.755727
21694	4479	2614	\N	direct	2026-06-21 08:10:48.757728
21695	4479	2063	\N	direct	2026-06-21 08:10:48.757728
21696	4480	1553	\N	direct	2026-06-21 08:10:48.759953
21697	4480	186	\N	direct	2026-06-21 08:10:48.759953
21479	4425	166	\N	direct	2026-06-21 08:08:54.160432
21480	4425	1608	\N	direct	2026-06-21 08:08:54.160432
21481	4425	2581	\N	direct	2026-06-21 08:08:54.160432
21482	4425	695	\N	direct	2026-06-21 08:08:54.160432
21483	4425	1830	\N	direct	2026-06-21 08:08:54.160432
21484	4425	778	\N	direct	2026-06-21 08:08:54.160432
21485	4425	1125	\N	direct	2026-06-21 08:08:54.160432
21486	4425	2678	\N	direct	2026-06-21 08:08:54.160432
21487	4426	1840	\N	direct	2026-06-21 08:08:57.107989
21488	4426	3386	\N	direct	2026-06-21 08:08:57.107989
21489	4426	2599	\N	direct	2026-06-21 08:08:57.107989
21490	4426	3360	\N	direct	2026-06-21 08:08:57.107989
21491	4426	3308	\N	direct	2026-06-21 08:08:57.107989
21492	4426	1017	\N	direct	2026-06-21 08:08:57.107989
21493	4426	1999	\N	direct	2026-06-21 08:08:57.107989
21494	4427	3181	\N	direct	2026-06-21 08:08:59.514842
21495	4427	170	\N	direct	2026-06-21 08:08:59.514842
21496	4427	1552	\N	direct	2026-06-21 08:08:59.514842
21497	4427	3281	\N	direct	2026-06-21 08:08:59.514842
21498	4428	683	\N	direct	2026-06-21 08:09:02.201974
21499	4428	353	\N	direct	2026-06-21 08:09:02.201974
21500	4428	1743	\N	direct	2026-06-21 08:09:02.201974
21501	4428	168	\N	direct	2026-06-21 08:09:02.201974
21502	4428	586	\N	direct	2026-06-21 08:09:02.201974
21503	4429	1861	\N	direct	2026-06-21 08:09:04.836893
21504	4429	3324	\N	direct	2026-06-21 08:09:04.836893
21505	4429	598	\N	direct	2026-06-21 08:09:04.836893
21506	4429	184	\N	direct	2026-06-21 08:09:04.836893
21507	4429	375	\N	direct	2026-06-21 08:09:04.836893
21508	4429	1193	\N	direct	2026-06-21 08:09:04.836893
21509	4429	3020	\N	direct	2026-06-21 08:09:04.836893
21510	4430	749	\N	direct	2026-06-21 08:09:12.873451
21511	4430	174	\N	direct	2026-06-21 08:09:12.873451
21512	4430	2586	\N	direct	2026-06-21 08:09:12.873451
21513	4430	958	\N	direct	2026-06-21 08:09:12.873451
21514	4430	63	\N	direct	2026-06-21 08:09:12.873451
21515	4431	688	\N	direct	2026-06-21 08:09:12.875457
21516	4431	553	\N	direct	2026-06-21 08:09:12.875457
21517	4432	761	\N	direct	2026-06-21 08:09:12.879542
21518	4432	70	\N	direct	2026-06-21 08:09:12.879542
21519	4433	1953	\N	direct	2026-06-21 08:09:12.899724
21520	4433	2255	\N	direct	2026-06-21 08:09:12.899724
21521	4434	912	\N	direct	2026-06-21 08:09:19.124653
21522	4434	1549	\N	direct	2026-06-21 08:09:19.124653
21523	4435	602	\N	direct	2026-06-21 08:09:19.129697
21524	4435	922	\N	direct	2026-06-21 08:09:19.129697
21525	4436	1219	\N	direct	2026-06-21 08:09:19.134358
21526	4436	1584	\N	direct	2026-06-21 08:09:19.134358
21527	4436	2148	\N	direct	2026-06-21 08:09:19.134358
21528	4437	3318	\N	direct	2026-06-21 08:09:25.600527
21529	4437	753	\N	direct	2026-06-21 08:09:25.600527
21530	4437	177	\N	direct	2026-06-21 08:09:25.600527
21531	4437	1238	\N	direct	2026-06-21 08:09:25.600527
21532	4437	2200	\N	direct	2026-06-21 08:09:25.600527
21533	4438	2589	\N	direct	2026-06-21 08:09:25.607535
21534	4438	11	\N	direct	2026-06-21 08:09:25.607535
21535	4438	3196	\N	direct	2026-06-21 08:09:25.607535
21536	4438	782	\N	direct	2026-06-21 08:09:25.607535
21537	4438	1239	\N	direct	2026-06-21 08:09:25.607535
21538	4438	566	\N	direct	2026-06-21 08:09:25.607535
21539	4439	1828	\N	direct	2026-06-21 08:09:25.614628
21540	4439	1233	\N	direct	2026-06-21 08:09:25.614628
21541	4440	2307	\N	direct	2026-06-21 08:09:25.618635
21542	4440	685	\N	direct	2026-06-21 08:09:25.618635
21543	4441	198	\N	direct	2026-06-21 08:09:30.979561
21544	4441	1577	\N	direct	2026-06-21 08:09:30.979561
21545	4441	952	\N	direct	2026-06-21 08:09:30.979561
21546	4441	15	\N	direct	2026-06-21 08:09:30.979561
21547	4441	1118	\N	direct	2026-06-21 08:09:30.979561
21548	4441	810	\N	direct	2026-06-21 08:09:30.979561
21549	4441	1540	\N	direct	2026-06-21 08:09:30.979561
21550	4442	3186	\N	direct	2026-06-21 08:09:30.985498
21551	4442	16	\N	direct	2026-06-21 08:09:30.985498
21552	4442	2918	\N	direct	2026-06-21 08:09:30.985498
21553	4443	460	\N	direct	2026-06-21 08:09:37.131447
21554	4443	1392	\N	direct	2026-06-21 08:09:37.131447
21555	4444	2584	\N	direct	2026-06-21 08:09:37.136545
21556	4444	955	\N	direct	2026-06-21 08:09:37.136545
21557	4445	1863	\N	direct	2026-06-21 08:09:37.141062
21558	4445	217	\N	direct	2026-06-21 08:09:37.141062
21559	4445	1814	\N	direct	2026-06-21 08:09:37.141062
21560	4446	173	\N	direct	2026-06-21 08:09:37.144069
21561	4446	210	\N	direct	2026-06-21 08:09:37.144069
21562	4447	189	\N	direct	2026-06-21 08:09:39.967989
21563	4447	3132	\N	direct	2026-06-21 08:09:39.967989
21564	4447	1573	\N	direct	2026-06-21 08:09:39.967989
21565	4447	2828	\N	direct	2026-06-21 08:09:39.967989
21566	4447	1022	\N	direct	2026-06-21 08:09:39.967989
21567	4447	840	\N	direct	2026-06-21 08:09:39.967989
21568	4448	2694	\N	direct	2026-06-21 08:09:43.104812
21569	4448	2592	\N	direct	2026-06-21 08:09:43.104812
21570	4448	3383	\N	direct	2026-06-21 08:09:43.104812
21571	4448	1826	\N	direct	2026-06-21 08:09:43.104812
21572	4448	1576	\N	direct	2026-06-21 08:09:43.104812
21573	4448	989	\N	direct	2026-06-21 08:09:43.104812
21574	4449	179	\N	direct	2026-06-21 08:09:45.683808
21575	4449	219	\N	direct	2026-06-21 08:09:45.683808
21576	4449	3136	\N	direct	2026-06-21 08:09:45.683808
21577	4449	734	\N	direct	2026-06-21 08:09:45.683808
\.


--
-- Data for Name: grc_normalized_controls; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_normalized_controls (id, code, name, statement, objective, control_owner, implementation_guidance, testing_guidance, maturity_level, created_at, domain, source, common_group_id, recommended_evidence, run_id, review_status, reviewed_by, reviewed_at) FROM stdin;
4450	NC-0026	Data Backup and Recovery	Establish and implement backup policies and procedures to ensure data availability and integrity, including regular testing of backup restoration procedures.	To maintain the recoverability of critical data and systems in the event of a disruption or failure.	\N	\N	\N	0	2026-06-21 08:09:50.932047	Data Backup and Recovery	ai_normalized	1303	\N	\N	\N	\N	\N
4451	NC-0027	Data Leakage Prevention	Implement measures to prevent unauthorized disclosure, modification, or loss of sensitive information during processing, storage, and transmission.	To protect the confidentiality and integrity of sensitive data across all platforms and channels.	\N	\N	\N	0	2026-06-21 08:09:50.937142	Data Leakage Prevention	ai_normalized	1303	\N	\N	\N	\N	\N
4452	NC-0028	Malware Protection and Detection	Implement and maintain malware protection mechanisms across all systems, including automatic scanning of removable media and regular updates of anti-malware signatures.	To safeguard systems from malware threats through proactive detection and protection measures.	\N	\N	\N	0	2026-06-21 08:09:55.118428	Malware Protection and Detection	ai_normalized	1326	\N	\N	\N	\N	\N
4453	NC-0029	Anti-Malware Software Deployment	Deploy and maintain anti-malware software on all applicable system components to ensure comprehensive protection against malicious code.	To ensure that all systems are equipped with effective anti-malware solutions to prevent infections.	\N	\N	\N	0	2026-06-21 08:09:55.119983	Anti-Malware Software Deployment	ai_normalized	1326	\N	\N	\N	\N	\N
4454	NC-0030	User Authentication and Password Management	Implement strong user authentication and manage passwords through formal processes to ensure secure access to systems.	To enhance security by enforcing robust authentication mechanisms and effective password management practices.	\N	\N	\N	0	2026-06-21 08:09:58.414029	User Authentication and Password Management	ai_normalized	1327	\N	\N	\N	\N	\N
4455	NC-0031	Multi-Factor Authentication	Implement multi-factor authentication for all user access to enhance security against unauthorized access.	To provide an additional layer of security by requiring multiple forms of verification for user access.	\N	\N	\N	0	2026-06-21 08:09:58.415029	Multi-Factor Authentication	ai_normalized	1310	\N	\N	\N	\N	\N
4456	NC-0032	Baseline Configuration Management	A baseline configuration of IT systems is created, maintained, and reviewed regularly to ensure security and compliance.	To establish a secure and consistent configuration for IT systems that mitigates risks and vulnerabilities.	\N	\N	\N	0	2026-06-21 08:10:04.028565	Baseline Configuration Management	ai_normalized	1336	\N	\N	\N	\N	\N
4457	NC-0033	Configuration Change Control	Configuration change control processes are established and maintained to manage changes to system configurations effectively.	To ensure that all changes to system configurations are documented, assessed, and approved to maintain security and operational integrity.	\N	\N	\N	0	2026-06-21 08:10:04.032086	Configuration Change Control	ai_normalized	1336	\N	\N	\N	\N	\N
4458	NC-0034	System Hardening Standards	Security standards for hardware and software configurations are established and implemented to reduce vulnerabilities.	To minimize the attack surface of systems by ensuring that only necessary services and configurations are enabled.	\N	\N	\N	0	2026-06-21 08:10:04.037082	System Hardening Standards	ai_normalized	1336	\N	\N	\N	\N	\N
4459	NC-0035	Configuration Documentation	All configurations and settings of operating systems, software, databases, and servers are documented and maintained.	To ensure that there is a clear and comprehensive record of system configurations for auditing and compliance purposes.	\N	\N	\N	0	2026-06-21 08:10:04.040089	Configuration Documentation	ai_normalized	1336	\N	\N	\N	\N	\N
4460	NC-0036	Governance Framework and Oversight	Establish and maintain a governance framework that aligns technology usage with business goals and ensures compliance with relevant policies and regulations.	To ensure effective governance and oversight of information technology and its alignment with organizational objectives.	\N	\N	\N	0	2026-06-21 08:10:06.5086	Governance Framework and Oversight	ai_normalized	1322	\N	\N	\N	\N	\N
4461	NC-0037	Incident Reporting Mechanism	A mechanism shall be provided for personnel to report observed or suspected information security events and weaknesses through appropriate channels in a timely manner.	To facilitate prompt reporting of security incidents and weaknesses to enable timely response and mitigation.	\N	\N	\N	0	2026-06-21 08:10:12.27039	Incident Reporting Mechanism	ai_normalized	1306	\N	\N	\N	\N	\N
4462	NC-0038	Post-Incident Review and Testing	Organizations shall conduct formal post-incident reviews and test their incident response plans at least annually to ensure effectiveness and continuous improvement.	To evaluate the response to incidents and enhance the incident management process through lessons learned and testing.	\N	\N	\N	0	2026-06-21 08:10:12.271637	Post-Incident Review and Testing	ai_normalized	1338	\N	\N	\N	\N	\N
4463	NC-0039	Evidence Collection and Preservation	Procedures shall be established for the collection, retention, and preservation of evidence related to information security incidents to support potential legal actions.	To ensure that evidence is properly handled and preserved for investigations and legal proceedings following security incidents.	\N	\N	\N	0	2026-06-21 08:10:12.274775	Evidence Collection and Preservation	ai_normalized	1306	\N	\N	\N	\N	\N
4464	NC-0040	Incident Communication Plan	A communication plan shall be defined to ensure timely updates to internal and external stakeholders regarding incident management progress and system availability.	To maintain transparency and manage expectations during incident response and recovery efforts.	\N	\N	\N	0	2026-06-21 08:10:12.278743	Incident Communication Plan	ai_normalized	1306	\N	\N	\N	\N	\N
4465	NC-0041	Backup and Data Deletion Controls	Organizations shall implement regular backup and restoration testing, prevent unauthorized data exfiltration, and ensure complete data deletion from all service provider locations upon exit.	To ensure data availability and integrity while protecting against unauthorized access and ensuring proper data disposal.	\N	\N	\N	0	2026-06-21 08:10:16.714832	Backup and Data Deletion Controls	ai_normalized	1303	\N	\N	\N	\N	\N
4466	NC-0042	Protection of Test and Assessment Data	Organizations shall protect test data and assessment data from unauthorized access and ensure it is handled according to established security policies.	To maintain the integrity and confidentiality of sensitive data used in testing and assessments.	\N	\N	\N	0	2026-06-21 08:10:16.716825	Protection of Test and Assessment Data	ai_normalized	1303	\N	\N	\N	\N	\N
4467	NC-0043	Data Protection and Privacy Measures	Entities shall implement data protection measures including data classification, handling procedures, data loss prevention, and alignment with relevant privacy regulations.	To ensure the confidentiality, integrity, and availability of personal information in compliance with applicable laws and regulations.	\N	\N	\N	0	2026-06-21 08:10:20.733804	Data Protection and Privacy Measures	ai_normalized	1303	\N	\N	\N	\N	\N
4468	NC-0044	Consent Management for Personal Information	The entity shall establish mechanisms to obtain and manage consent for the collection, use, and disclosure of personal information, ensuring that individuals are informed of their choices.	To uphold individuals' rights regarding their personal information and ensure compliance with privacy regulations.	\N	\N	\N	0	2026-06-21 08:10:20.735804	Consent Management for Personal Information	ai_normalized	1303	\N	\N	\N	\N	\N
4469	NC-0045	Privileged Access Management	Implement controls to restrict, monitor, and manage privileged access accounts across information systems and services.	To ensure that privileged access is granted only to authorized users and is subject to regular review and monitoring.	\N	\N	\N	0	2026-06-21 08:10:24.408789	Privileged Access Management	ai_normalized	1327	\N	\N	\N	\N	\N
4470	NC-0046	Identity and Access Management	Establish and maintain comprehensive identity and access management processes including user provisioning, authentication, authorization, and access reviews.	To ensure that user access is managed effectively and securely throughout the user lifecycle.	\N	\N	\N	0	2026-06-21 08:10:24.41179	Identity and Access Management	ai_normalized	1305	\N	\N	\N	\N	\N
4471	NC-0047	Continuous Monitoring	Develop and implement a continuous monitoring strategy and program that includes metrics, monitoring frequency, and ongoing assessments of security controls.	To ensure the effectiveness and compliance of security controls through regular monitoring and assessment.	\N	\N	\N	0	2026-06-21 08:10:28.62742	Continuous Monitoring	ai_normalized	1330	\N	\N	\N	\N	\N
4472	NC-0048	Security Event Monitoring	Implement mechanisms for monitoring security events across systems, including integration with SIEM solutions for log correlation and analysis.	To detect and respond to security incidents in real-time by analyzing security events and alerts.	\N	\N	\N	0	2026-06-21 08:10:28.62842	Security Event Monitoring	ai_normalized	1330	\N	\N	\N	\N	\N
4473	NC-0049	Vulnerability Assessment and Penetration Testing	Entities shall conduct regular vulnerability assessments and penetration testing, including scenario-based security testing, to identify and remediate security vulnerabilities in their systems.	To ensure the security posture of the organization by identifying and addressing vulnerabilities in a timely manner.	\N	\N	\N	0	2026-06-21 08:10:31.516871	Vulnerability Assessment and Penetration Testing	ai_normalized	1337	\N	\N	\N	\N	\N
4474	NC-0050	Cryptographic Key Management	Establish and implement policies and procedures for the secure management of cryptographic keys throughout their lifecycle, including generation, distribution, storage, and retirement.	To ensure the confidentiality, integrity, and availability of cryptographic keys used to protect sensitive data.	\N	\N	\N	0	2026-06-21 08:10:37.488269	Cryptographic Key Management	ai_normalized	1323	\N	\N	\N	\N	\N
4475	NC-0051	Human Resources Security Policy	Develop, enforce, and maintain a human resources security policy that addresses security aspects of employment, including hiring, training, and termination processes.	To ensure that human resources practices align with information security requirements and promote a secure working environment.	\N	\N	\N	0	2026-06-21 08:10:37.492682	Human Resources Security Policy	ai_normalized	1325	\N	\N	\N	\N	\N
4476	NC-0052	Incident Detection and Monitoring	Entities shall deploy appropriate monitoring and detection capabilities to identify security incidents affecting network and information systems in a timely manner.	To ensure timely identification of security incidents to mitigate potential impacts.	\N	\N	\N	0	2026-06-21 08:10:42.465502	Incident Detection and Monitoring	ai_normalized	1330	\N	\N	\N	\N	\N
4477	NC-0053	Incident Handling Procedures	Entities shall implement comprehensive incident handling procedures for prevention, detection, analysis, containment, response, and recovery from security incidents.	To establish a structured approach for managing security incidents effectively.	\N	\N	\N	0	2026-06-21 08:10:42.468504	Incident Handling Procedures	ai_normalized	1306	\N	\N	\N	\N	\N
4478	NC-0054	Establish and Maintain Cyber Security Controls	Organizations must establish, maintain, and continuously monitor cyber security controls to protect against cyber threats and ensure operational effectiveness.	To ensure that cyber security measures are effective and responsive to evolving threats.	\N	\N	\N	0	2026-06-21 08:10:48.752729	Establish and Maintain Cyber Security Controls	ai_normalized	1326	\N	\N	\N	\N	\N
4479	NC-0055	Cyber Security Framework Adoption and Governance	Organizations must formally adopt a cyber security framework and establish a governance structure to oversee its implementation and effectiveness.	To ensure a structured approach to managing cyber security risks and compliance with established standards.	\N	\N	\N	0	2026-06-21 08:10:48.754729	Cyber Security Framework Adoption and Governance	ai_normalized	1322	\N	\N	\N	\N	\N
4480	NC-0056	Vulnerability Management and Risk Assessment	Organizations must establish procedures for identifying, assessing, and remediating vulnerabilities in their network and information systems.	To proactively manage vulnerabilities and enhance the security posture of the organization.	\N	\N	\N	0	2026-06-21 08:10:48.757728	Vulnerability Management and Risk Assessment	ai_normalized	1304	\N	\N	\N	\N	\N
4425	NC-0001	Security Awareness and Training	Implement security awareness and training programs to ensure all personnel are informed about security policies and practices.	To enhance the security posture of the organization by educating employees and stakeholders on security risks and responsibilities.	\N	\N	\N	0	2026-06-21 08:08:54.14632	Security Awareness and Training	ai_normalized	1324	\N	\N	\N	\N	\N
4426	NC-0002	Audit Logging and Monitoring	Establish and maintain a comprehensive audit logging and monitoring process that includes the identification, collection, and analysis of audit logs to support security event detection and compliance assessment.	To ensure that all relevant activities are logged and monitored for security incidents and compliance verification.	\N	\N	\N	0	2026-06-21 08:08:57.104448	Audit Logging and Monitoring	ai_normalized	1330	\N	\N	\N	\N	\N
4427	NC-0003	Third-Party Risk Management	Organizations shall identify, assess, and manage cybersecurity risks associated with third-party service providers and subcontractors.	To ensure that third-party relationships do not compromise the organization's information security posture.	\N	\N	\N	0	2026-06-21 08:08:59.514842	Third-Party Risk Management	ai_normalized	1334	\N	\N	\N	\N	\N
4428	NC-0004	Risk Management Framework	Establish and maintain a comprehensive risk management framework that includes policies, procedures, and controls to identify, assess, and mitigate risks to an acceptable level.	To ensure that risks are effectively managed and aligned with the organization's risk appetite and business objectives.	\N	\N	\N	0	2026-06-21 08:09:02.199661	Risk Management Framework	ai_normalized	1322	\N	\N	\N	\N	\N
4429	NC-0005	Change Management Process	Establish and maintain a formal change management process that governs all changes to systems and infrastructure, ensuring they are assessed, approved, documented, and tested before implementation.	To ensure that all changes are managed in a controlled manner to minimize risks and maintain system integrity.	\N	\N	\N	0	2026-06-21 08:09:04.834893	Change Management Process	ai_normalized	1336	\N	\N	\N	\N	\N
4430	NC-0006	Access Control Policy	Establish, document, and review access control policies based on business and security requirements to ensure appropriate access to sensitive information.	To prevent unauthorized access and ensure that access is granted based on defined business needs and security requirements.	\N	\N	\N	0	2026-06-21 08:09:12.869385	Access Control Policy	ai_normalized	1327	\N	\N	\N	\N	\N
4431	NC-0007	Access Authorization Procedures	Implement procedures for authorizing access to sensitive information and systems, ensuring that only authorized individuals can access specific resources.	To maintain the confidentiality and integrity of sensitive information by controlling who can access it and under what circumstances.	\N	\N	\N	0	2026-06-21 08:09:12.871445	Access Authorization Procedures	ai_normalized	1305	\N	\N	\N	\N	\N
4432	NC-0008	Network Access Control	Establish and enforce restrictions on network access to ensure that only authorized users can connect to shared and isolated networks.	To protect the organization's network and sensitive data from unauthorized access and potential breaches.	\N	\N	\N	0	2026-06-21 08:09:12.875457	Network Access Control	ai_normalized	1307	\N	\N	\N	\N	\N
4433	NC-0009	User Identification and Authentication	Assign unique identifiers to users and implement secure authentication procedures to control access to systems and sensitive information.	To ensure accountability and traceability of user actions within the organization's systems.	\N	\N	\N	0	2026-06-21 08:09:12.879542	User Identification and Authentication	ai_normalized	1305	\N	\N	\N	\N	\N
4434	NC-0010	Business Continuity Objectives and Plans	The organization shall establish measurable business continuity objectives that are consistent with the business continuity policy and monitored for effectiveness.	To ensure that the organization can achieve its intended outcomes and maintain essential services during disruptions.	\N	\N	\N	0	2026-06-21 08:09:19.12064	Business Continuity Objectives and Plans	ai_normalized	1331	\N	\N	\N	\N	\N
4435	NC-0011	Business Impact Analysis	The organization shall implement a process for business impact analysis to identify critical activities, assess impacts, and prioritize recovery requirements.	To understand the potential impacts of disruptions and establish recovery priorities for critical business functions.	\N	\N	\N	0	2026-06-21 08:09:19.122647	Business Impact Analysis	ai_normalized	1331	\N	\N	\N	\N	\N
4436	NC-0012	Business Continuity Testing and Exercising	The organization shall regularly test and exercise its business continuity and disaster recovery plans to ensure their effectiveness and currency.	To validate the effectiveness of business continuity plans and ensure preparedness for potential disruptions.	\N	\N	\N	0	2026-06-21 08:09:19.128685	Business Continuity Testing and Exercising	ai_normalized	1311	\N	\N	\N	\N	\N
4437	NC-0013	User Access Review and Management	Regularly review and manage user access rights to ensure they are appropriate and aligned with job responsibilities.	To maintain the principle of least privilege and ensure that access rights are current and justified.	\N	\N	\N	0	2026-06-21 08:09:25.595542	User Access Review and Management	ai_normalized	1327	\N	\N	\N	\N	\N
4438	NC-0014	Access Revocation Procedures	Promptly revoke access rights when no longer required due to termination or change in job responsibilities.	To prevent unauthorized access by ensuring that access rights are immediately removed when they are no longer needed.	\N	\N	\N	0	2026-06-21 08:09:25.598508	Access Revocation Procedures	ai_normalized	1327	\N	\N	\N	\N	\N
4439	NC-0015	Access Control Principles	Implement access control principles including least privilege, segregation of duties, and role-based access.	To ensure that access to information and systems is restricted based on user roles and responsibilities.	\N	\N	\N	0	2026-06-21 08:09:25.606535	Access Control Principles	ai_normalized	1327	\N	\N	\N	\N	\N
4440	NC-0016	Audit and Monitoring of Access	Conduct regular audits and monitoring of access to information systems to ensure compliance with access control policies.	To detect and respond to unauthorized access attempts and ensure adherence to security policies.	\N	\N	\N	0	2026-06-21 08:09:25.612629	Audit and Monitoring of Access	ai_normalized	1330	\N	\N	\N	\N	\N
4441	NC-0017	Asset Inventory Management	Establish and maintain an accurate and detailed inventory of all enterprise assets, including hardware and software, and classify them based on criticality and sensitivity.	To ensure comprehensive visibility and management of all assets within the organization to support security and compliance efforts.	\N	\N	\N	0	2026-06-21 08:09:30.974278	Asset Inventory Management	ai_normalized	1333	\N	\N	\N	\N	\N
4442	NC-0018	Asset Classification and Ownership	Establish and maintain processes for classifying assets based on sensitivity and assigning ownership for each identified asset.	To ensure that all assets are properly classified and managed according to their sensitivity and ownership responsibilities.	\N	\N	\N	0	2026-06-21 08:09:30.97755	Asset Classification and Ownership	ai_normalized	1303	\N	\N	\N	\N	\N
4443	NC-0019	Data Management and Quality Compliance	Organizations shall comply with relevant data management and quality requirements to ensure the integrity and reliability of data.	To maintain high standards of data quality and management across the organization.	\N	\N	\N	0	2026-06-21 08:09:37.127604	Data Management and Quality Compliance	ai_normalized	1303	\N	\N	\N	\N	\N
4446	NC-0022	Data Retention and Disposal	Data retention and disposal processes shall be established and followed to manage data lifecycle effectively.	To ensure data is retained only as long as necessary and disposed of securely when no longer needed.	\N	\N	\N	0	2026-06-21 08:09:37.140054	Data Retention and Disposal	ai_normalized	1303	\N	\N	\N	\N	\N
4444	NC-0020	Data Classification and Handling	Data shall be classified according to sensitivity and handled securely throughout its lifecycle.	To protect sensitive information from unauthorized access and ensure proper handling procedures are followed.	\N	\N	\N	0	2026-06-21 08:09:37.13011	Data Classification and Handling	ai_normalized	1303	\N	\N	\N	\N	\N
4447	NC-0023	Network Security Controls	Implement multiple layers of network security controls including firewalls, intrusion detection/prevention systems, and secure network architecture design to protect against unauthorized access and threats.	To ensure the integrity, confidentiality, and availability of networked systems and data.	\N	\N	\N	0	2026-06-21 08:09:39.965901	Network Security Controls	ai_normalized	1307	\N	\N	\N	\N	\N
4448	NC-0024	Physical Security Management	Implement physical security measures to protect facilities, equipment, and sensitive areas from unauthorized access, damage, and environmental threats.	To ensure the safety and integrity of physical assets and sensitive information by restricting access and mitigating risks.	\N	\N	\N	0	2026-06-21 08:09:43.102822	Physical Security Management	ai_normalized	1328	\N	\N	\N	\N	\N
4449	NC-0025	Data Encryption	Implement encryption mechanisms to protect sensitive data at rest and in transit across various systems and devices.	To ensure the confidentiality, integrity, and authenticity of sensitive information through effective encryption practices.	\N	\N	\N	0	2026-06-21 08:09:45.682904	Data Encryption	ai_normalized	1316	\N	\N	\N	\N	\N
4445	NC-0021	Data Flow Documentation	Organizations shall maintain accurate documentation of data flows and data management processes.	To ensure transparency and accountability in data handling and processing activities.	\N	\N	\N	0	2026-06-21 08:09:37.135545	Data Flow Documentation	ai_normalized	1303	\N	\N	\N	\N	\N
\.


--
-- Name: grc_ai_evidence_recommendations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_ai_evidence_recommendations_id_seq', 25, true);


--
-- Name: grc_common_control_group_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_common_control_group_mappings_id_seq', 37792, true);


--
-- Name: grc_common_control_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_common_control_groups_id_seq', 1358, true);


--
-- Name: grc_evidence_control_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_evidence_control_mappings_id_seq', 54, true);


--
-- Name: grc_normalization_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_normalization_runs_id_seq', 18, true);


--
-- Name: grc_normalized_control_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_normalized_control_links_id_seq', 21697, true);


--
-- Name: grc_normalized_controls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_normalized_controls_id_seq', 4480, true);


--
-- Name: grc_ai_evidence_recommendations grc_ai_evidence_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations
    ADD CONSTRAINT grc_ai_evidence_recommendations_pkey PRIMARY KEY (id);


--
-- Name: grc_common_control_group_mappings grc_common_control_group_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT grc_common_control_group_mappings_pkey PRIMARY KEY (id);


--
-- Name: grc_common_control_groups grc_common_control_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_groups
    ADD CONSTRAINT grc_common_control_groups_pkey PRIMARY KEY (id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_pkey PRIMARY KEY (id);


--
-- Name: grc_normalization_runs grc_normalization_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalization_runs
    ADD CONSTRAINT grc_normalization_runs_pkey PRIMARY KEY (id);


--
-- Name: grc_normalized_control_links grc_normalized_control_links_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_control_links
    ADD CONSTRAINT grc_normalized_control_links_pkey PRIMARY KEY (id);


--
-- Name: grc_normalized_controls grc_normalized_controls_pkey; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_controls
    ADD CONSTRAINT grc_normalized_controls_pkey PRIMARY KEY (id);


--
-- Name: grc_common_control_groups uq_common_control_group_tenant_code; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_groups
    ADD CONSTRAINT uq_common_control_group_tenant_code UNIQUE (tenant_id, code);


--
-- Name: grc_common_control_group_mappings uq_group_framework_control; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT uq_group_framework_control UNIQUE (group_id, framework_control_id);


--
-- Name: grc_common_control_group_mappings uq_group_normalized_control; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT uq_group_normalized_control UNIQUE (group_id, normalized_control_id);


--
-- Name: grc_common_control_group_mappings uq_group_parsed_control; Type: CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT uq_group_parsed_control UNIQUE (group_id, parsed_control_id);


--
-- Name: ix_ai_evidence_rec_group; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_ai_evidence_rec_group ON public.grc_ai_evidence_recommendations USING btree (group_id);


--
-- Name: ix_ai_evidence_rec_priority; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_ai_evidence_rec_priority ON public.grc_ai_evidence_recommendations USING btree (tenant_id, priority);


--
-- Name: ix_ai_evidence_rec_tenant; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_ai_evidence_rec_tenant ON public.grc_ai_evidence_recommendations USING btree (tenant_id);


--
-- Name: ix_common_control_group_category; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_control_group_category ON public.grc_common_control_groups USING btree (category);


--
-- Name: ix_common_control_group_domain; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_control_group_domain ON public.grc_common_control_groups USING btree (domain);


--
-- Name: ix_common_control_group_tenant_code; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_control_group_tenant_code ON public.grc_common_control_groups USING btree (tenant_id, code);


--
-- Name: ix_common_group_mapping_framework; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_group_mapping_framework ON public.grc_common_control_group_mappings USING btree (group_id, framework_control_id);


--
-- Name: ix_common_group_mapping_group; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_group_mapping_group ON public.grc_common_control_group_mappings USING btree (group_id);


--
-- Name: ix_common_group_mapping_normalized; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_group_mapping_normalized ON public.grc_common_control_group_mappings USING btree (group_id, normalized_control_id);


--
-- Name: ix_common_group_mapping_parsed; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_group_mapping_parsed ON public.grc_common_control_group_mappings USING btree (group_id, parsed_control_id);


--
-- Name: ix_common_group_run; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_common_group_run ON public.grc_common_control_groups USING btree (run_id);


--
-- Name: ix_evidence_control_locked; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_evidence_control_locked ON public.grc_evidence_control_mappings USING btree (evidence_id, is_locked);


--
-- Name: ix_evidence_control_mapping; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_evidence_control_mapping ON public.grc_evidence_control_mappings USING btree (evidence_id, normalized_control_id);


--
-- Name: ix_evidence_parsed_control; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_evidence_parsed_control ON public.grc_evidence_control_mappings USING btree (evidence_id, parsed_control_id);


--
-- Name: ix_grc_ai_evidence_recommendations_framework_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_ai_evidence_recommendations_framework_control_id ON public.grc_ai_evidence_recommendations USING btree (framework_control_id);


--
-- Name: ix_grc_ai_evidence_recommendations_group_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_ai_evidence_recommendations_group_id ON public.grc_ai_evidence_recommendations USING btree (group_id);


--
-- Name: ix_grc_ai_evidence_recommendations_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_ai_evidence_recommendations_id ON public.grc_ai_evidence_recommendations USING btree (id);


--
-- Name: ix_grc_ai_evidence_recommendations_normalized_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_ai_evidence_recommendations_normalized_control_id ON public.grc_ai_evidence_recommendations USING btree (normalized_control_id);


--
-- Name: ix_grc_ai_evidence_recommendations_parsed_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_ai_evidence_recommendations_parsed_control_id ON public.grc_ai_evidence_recommendations USING btree (parsed_control_id);


--
-- Name: ix_grc_ai_evidence_recommendations_tenant_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_ai_evidence_recommendations_tenant_id ON public.grc_ai_evidence_recommendations USING btree (tenant_id);


--
-- Name: ix_grc_common_control_group_mappings_framework_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_group_mappings_framework_control_id ON public.grc_common_control_group_mappings USING btree (framework_control_id);


--
-- Name: ix_grc_common_control_group_mappings_group_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_group_mappings_group_id ON public.grc_common_control_group_mappings USING btree (group_id);


--
-- Name: ix_grc_common_control_group_mappings_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_group_mappings_id ON public.grc_common_control_group_mappings USING btree (id);


--
-- Name: ix_grc_common_control_group_mappings_normalized_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_group_mappings_normalized_control_id ON public.grc_common_control_group_mappings USING btree (normalized_control_id);


--
-- Name: ix_grc_common_control_group_mappings_parsed_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_group_mappings_parsed_control_id ON public.grc_common_control_group_mappings USING btree (parsed_control_id);


--
-- Name: ix_grc_common_control_groups_created_by; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_groups_created_by ON public.grc_common_control_groups USING btree (created_by);


--
-- Name: ix_grc_common_control_groups_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_groups_id ON public.grc_common_control_groups USING btree (id);


--
-- Name: ix_grc_common_control_groups_tenant_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_common_control_groups_tenant_id ON public.grc_common_control_groups USING btree (tenant_id);


--
-- Name: ix_grc_evidence_control_mappings_evidence_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_evidence_control_mappings_evidence_id ON public.grc_evidence_control_mappings USING btree (evidence_id);


--
-- Name: ix_grc_evidence_control_mappings_framework_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_evidence_control_mappings_framework_control_id ON public.grc_evidence_control_mappings USING btree (framework_control_id);


--
-- Name: ix_grc_evidence_control_mappings_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_evidence_control_mappings_id ON public.grc_evidence_control_mappings USING btree (id);


--
-- Name: ix_grc_evidence_control_mappings_normalized_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_evidence_control_mappings_normalized_control_id ON public.grc_evidence_control_mappings USING btree (normalized_control_id);


--
-- Name: ix_grc_evidence_control_mappings_parsed_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_evidence_control_mappings_parsed_control_id ON public.grc_evidence_control_mappings USING btree (parsed_control_id);


--
-- Name: ix_grc_evidence_control_mappings_uploaded_framework_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_evidence_control_mappings_uploaded_framework_id ON public.grc_evidence_control_mappings USING btree (uploaded_framework_id);


--
-- Name: ix_grc_normalization_runs_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalization_runs_id ON public.grc_normalization_runs USING btree (id);


--
-- Name: ix_grc_normalization_runs_tenant_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalization_runs_tenant_id ON public.grc_normalization_runs USING btree (tenant_id);


--
-- Name: ix_grc_normalized_control_links_framework_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalized_control_links_framework_control_id ON public.grc_normalized_control_links USING btree (framework_control_id);


--
-- Name: ix_grc_normalized_control_links_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalized_control_links_id ON public.grc_normalized_control_links USING btree (id);


--
-- Name: ix_grc_normalized_control_links_normalized_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalized_control_links_normalized_control_id ON public.grc_normalized_control_links USING btree (normalized_control_id);


--
-- Name: ix_grc_normalized_control_links_parsed_control_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalized_control_links_parsed_control_id ON public.grc_normalized_control_links USING btree (parsed_control_id);


--
-- Name: ix_grc_normalized_controls_code; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE UNIQUE INDEX ix_grc_normalized_controls_code ON public.grc_normalized_controls USING btree (code);


--
-- Name: ix_grc_normalized_controls_id; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_grc_normalized_controls_id ON public.grc_normalized_controls USING btree (id);


--
-- Name: ix_nc_link_framework; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_nc_link_framework ON public.grc_normalized_control_links USING btree (framework_control_id);


--
-- Name: ix_nc_link_nc; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_nc_link_nc ON public.grc_normalized_control_links USING btree (normalized_control_id);


--
-- Name: ix_nc_link_parsed; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_nc_link_parsed ON public.grc_normalized_control_links USING btree (parsed_control_id);


--
-- Name: ix_normalized_control_domain; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_normalized_control_domain ON public.grc_normalized_controls USING btree (domain);


--
-- Name: ix_normalized_control_group; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_normalized_control_group ON public.grc_normalized_controls USING btree (common_group_id);


--
-- Name: ix_normalized_control_review; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_normalized_control_review ON public.grc_normalized_controls USING btree (review_status);


--
-- Name: ix_normalized_control_run; Type: INDEX; Schema: public; Owner: grc_app
--

CREATE INDEX ix_normalized_control_run ON public.grc_normalized_controls USING btree (run_id);


--
-- Name: grc_ai_evidence_recommendations grc_ai_evidence_recommendations_framework_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations
    ADD CONSTRAINT grc_ai_evidence_recommendations_framework_control_id_fkey FOREIGN KEY (framework_control_id) REFERENCES public.grc_framework_controls(id);


--
-- Name: grc_ai_evidence_recommendations grc_ai_evidence_recommendations_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations
    ADD CONSTRAINT grc_ai_evidence_recommendations_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.grc_common_control_groups(id);


--
-- Name: grc_ai_evidence_recommendations grc_ai_evidence_recommendations_normalized_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations
    ADD CONSTRAINT grc_ai_evidence_recommendations_normalized_control_id_fkey FOREIGN KEY (normalized_control_id) REFERENCES public.grc_normalized_controls(id);


--
-- Name: grc_ai_evidence_recommendations grc_ai_evidence_recommendations_parsed_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations
    ADD CONSTRAINT grc_ai_evidence_recommendations_parsed_control_id_fkey FOREIGN KEY (parsed_control_id) REFERENCES public.grc_parsed_framework_controls(id);


--
-- Name: grc_ai_evidence_recommendations grc_ai_evidence_recommendations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_ai_evidence_recommendations
    ADD CONSTRAINT grc_ai_evidence_recommendations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.grc_tenants(id);


--
-- Name: grc_common_control_group_mappings grc_common_control_group_mappings_framework_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT grc_common_control_group_mappings_framework_control_id_fkey FOREIGN KEY (framework_control_id) REFERENCES public.grc_framework_controls(id);


--
-- Name: grc_common_control_group_mappings grc_common_control_group_mappings_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT grc_common_control_group_mappings_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.grc_common_control_groups(id);


--
-- Name: grc_common_control_group_mappings grc_common_control_group_mappings_normalized_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT grc_common_control_group_mappings_normalized_control_id_fkey FOREIGN KEY (normalized_control_id) REFERENCES public.grc_normalized_controls(id);


--
-- Name: grc_common_control_group_mappings grc_common_control_group_mappings_parsed_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_group_mappings
    ADD CONSTRAINT grc_common_control_group_mappings_parsed_control_id_fkey FOREIGN KEY (parsed_control_id) REFERENCES public.grc_parsed_framework_controls(id);


--
-- Name: grc_common_control_groups grc_common_control_groups_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_groups
    ADD CONSTRAINT grc_common_control_groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.grc_users(id);


--
-- Name: grc_common_control_groups grc_common_control_groups_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_common_control_groups
    ADD CONSTRAINT grc_common_control_groups_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.grc_tenants(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.grc_evidence_ai_assessments(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_evidence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_evidence_id_fkey FOREIGN KEY (evidence_id) REFERENCES public.grc_evidence(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_framework_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_framework_control_id_fkey FOREIGN KEY (framework_control_id) REFERENCES public.grc_framework_controls(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_locked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_locked_by_fkey FOREIGN KEY (locked_by) REFERENCES public.grc_users(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_normalized_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_normalized_control_id_fkey FOREIGN KEY (normalized_control_id) REFERENCES public.grc_normalized_controls(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_parsed_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_parsed_control_id_fkey FOREIGN KEY (parsed_control_id) REFERENCES public.grc_parsed_framework_controls(id);


--
-- Name: grc_evidence_control_mappings grc_evidence_control_mappings_uploaded_framework_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_evidence_control_mappings
    ADD CONSTRAINT grc_evidence_control_mappings_uploaded_framework_id_fkey FOREIGN KEY (uploaded_framework_id) REFERENCES public.grc_uploaded_frameworks(id);


--
-- Name: grc_normalized_control_links grc_normalized_control_links_framework_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_control_links
    ADD CONSTRAINT grc_normalized_control_links_framework_control_id_fkey FOREIGN KEY (framework_control_id) REFERENCES public.grc_framework_controls(id);


--
-- Name: grc_normalized_control_links grc_normalized_control_links_normalized_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_control_links
    ADD CONSTRAINT grc_normalized_control_links_normalized_control_id_fkey FOREIGN KEY (normalized_control_id) REFERENCES public.grc_normalized_controls(id) ON DELETE CASCADE;


--
-- Name: grc_normalized_control_links grc_normalized_control_links_parsed_control_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: grc_app
--

ALTER TABLE ONLY public.grc_normalized_control_links
    ADD CONSTRAINT grc_normalized_control_links_parsed_control_id_fkey FOREIGN KEY (parsed_control_id) REFERENCES public.grc_parsed_framework_controls(id);


--
-- PostgreSQL database dump complete
--

\unrestrict Jr683SeL7g4HpH12qooIzSA39cjwarLyCuWUn1KpW6qAHflkwFgslHYvH269eqG

