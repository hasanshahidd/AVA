--
-- PostgreSQL database dump
--

\restrict en481eiNugfJddPMPN8fFSWgeGX2nS0Nd1LbXWcikzGhJm4lx470nenj6f8Vpd1

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
38341	1400	4778	\N	\N	1	domain	2026-06-21 09:04:07.987587
38342	1400	\N	\N	166	1	domain	2026-06-21 09:04:07.987587
38343	1400	\N	\N	5	1	domain	2026-06-21 09:04:07.987587
38344	1401	4779	\N	\N	1	domain	2026-06-21 09:04:08.053284
38345	1401	\N	\N	183	1	domain	2026-06-21 09:04:08.053284
38346	1401	\N	\N	48	1	domain	2026-06-21 09:04:08.053284
38347	1402	4780	\N	\N	1	domain	2026-06-21 09:04:08.065957
38348	1402	\N	\N	180	1	domain	2026-06-21 09:04:08.065957
38349	1402	\N	\N	137	1	domain	2026-06-21 09:04:08.065957
38350	1403	4781	\N	\N	1	domain	2026-06-21 09:04:08.075973
38351	1403	\N	\N	174	1	domain	2026-06-21 09:04:08.075973
38352	1403	\N	\N	63	1	domain	2026-06-21 09:04:08.075973
38353	1403	4782	\N	\N	1	domain	2026-06-21 09:04:08.085441
38354	1403	\N	\N	175	1	domain	2026-06-21 09:04:08.085441
38355	1403	\N	\N	78	1	domain	2026-06-21 09:04:08.085441
38356	1401	4783	\N	\N	1	domain	2026-06-21 09:04:08.093446
38357	1401	\N	\N	181	1	domain	2026-06-21 09:04:08.093446
38358	1401	\N	\N	46	1	domain	2026-06-21 09:04:08.093446
38359	1404	4784	\N	\N	1	domain	2026-06-21 09:04:08.107841
38360	1404	\N	\N	173	1	domain	2026-06-21 09:04:08.107841
38361	1404	\N	\N	37	1	domain	2026-06-21 09:04:08.107841
38362	1404	\N	\N	39	1	domain	2026-06-21 09:04:08.107841
38363	1405	4785	\N	\N	1	domain	2026-06-21 09:04:08.122535
38364	1405	\N	\N	171	1	domain	2026-06-21 09:04:08.122535
38365	1405	\N	\N	15	1	domain	2026-06-21 09:04:08.122535
38366	1406	4786	\N	\N	1	domain	2026-06-21 09:04:08.13277
38367	1406	\N	\N	86	1	domain	2026-06-21 09:04:08.13277
38368	1406	\N	\N	184	1	domain	2026-06-21 09:04:08.13277
38369	1406	4787	\N	\N	1	domain	2026-06-21 09:04:08.160595
38370	1406	\N	\N	187	1	domain	2026-06-21 09:04:08.160595
38371	1406	\N	\N	100	1	domain	2026-06-21 09:04:08.160595
38372	1407	\N	\N	1	1	standalone	2026-06-21 09:04:08.16619
38373	1407	\N	\N	2	1	standalone	2026-06-21 09:04:08.16619
38374	1407	\N	\N	3	1	standalone	2026-06-21 09:04:08.16619
38375	1408	\N	\N	4	1	standalone	2026-06-21 09:04:08.172188
38376	1404	\N	\N	124	1	standalone	2026-06-21 09:04:08.172188
38377	1400	\N	\N	6	1	standalone	2026-06-21 09:04:08.172188
38378	1400	\N	\N	7	1	standalone	2026-06-21 09:04:08.172188
38379	1407	\N	\N	8	1	standalone	2026-06-21 09:04:08.172188
38380	1404	\N	\N	22	1	standalone	2026-06-21 09:04:08.172188
38381	1403	\N	\N	9	1	standalone	2026-06-21 09:04:08.172188
37980	1322	4668	\N	\N	1	domain	2026-06-21 08:21:21.403928
38382	1403	\N	\N	10	1	standalone	2026-06-21 09:04:08.172188
38383	1403	\N	\N	11	1	standalone	2026-06-21 09:04:08.172188
38384	1407	\N	\N	12	1	standalone	2026-06-21 09:04:08.172188
38385	1405	\N	\N	13	1	standalone	2026-06-21 09:04:08.172188
38386	1405	\N	\N	14	1	standalone	2026-06-21 09:04:08.172188
38387	1405	\N	\N	16	1	standalone	2026-06-21 09:04:08.172188
38388	1408	\N	\N	17	1	standalone	2026-06-21 09:04:08.172188
38389	1407	\N	\N	18	1	standalone	2026-06-21 09:04:08.172188
38390	1404	\N	\N	19	1	standalone	2026-06-21 09:04:08.172188
38391	1404	\N	\N	20	1	standalone	2026-06-21 09:04:08.172188
38392	1405	\N	\N	21	1	standalone	2026-06-21 09:04:08.172188
38393	1409	\N	\N	23	1	standalone	2026-06-21 09:04:08.185681
38394	1404	\N	\N	24	1	standalone	2026-06-21 09:04:08.185681
38395	1405	\N	\N	25	1	standalone	2026-06-21 09:04:08.185681
38396	1404	\N	\N	26	1	standalone	2026-06-21 09:04:08.185681
38397	1404	\N	\N	27	1	standalone	2026-06-21 09:04:08.185681
38398	1401	\N	\N	28	1	standalone	2026-06-21 09:04:08.185681
38399	1401	\N	\N	29	1	standalone	2026-06-21 09:04:08.185681
38400	1405	\N	\N	30	1	standalone	2026-06-21 09:04:08.185681
38401	1403	\N	\N	31	1	standalone	2026-06-21 09:04:08.185681
38402	1404	\N	\N	32	1	standalone	2026-06-21 09:04:08.185681
38403	1401	\N	\N	33	1	standalone	2026-06-21 09:04:08.185681
38404	1410	\N	\N	34	1	standalone	2026-06-21 09:04:08.193679
38405	1405	\N	\N	35	1	standalone	2026-06-21 09:04:08.193679
38406	1404	\N	\N	36	1	standalone	2026-06-21 09:04:08.193679
38407	1404	\N	\N	38	1	standalone	2026-06-21 09:04:08.193679
38408	1404	\N	\N	40	1	standalone	2026-06-21 09:04:08.193679
38409	1404	\N	\N	41	1	standalone	2026-06-21 09:04:08.193679
38410	1404	\N	\N	42	1	standalone	2026-06-21 09:04:08.193679
38411	1401	\N	\N	52	1	standalone	2026-06-21 09:04:08.193679
38412	1401	\N	\N	43	1	standalone	2026-06-21 09:04:08.193679
38413	1411	\N	\N	44	1	standalone	2026-06-21 09:04:08.205047
38414	1401	\N	\N	45	1	standalone	2026-06-21 09:04:08.205047
38415	1401	\N	\N	47	1	standalone	2026-06-21 09:04:08.205047
38416	1401	\N	\N	49	1	standalone	2026-06-21 09:04:08.205047
38417	1401	\N	\N	50	1	standalone	2026-06-21 09:04:08.205047
38418	1401	\N	\N	51	1	standalone	2026-06-21 09:04:08.205047
38419	1401	\N	\N	53	1	standalone	2026-06-21 09:04:08.205047
38420	1400	\N	\N	54	1	standalone	2026-06-21 09:04:08.205047
38421	1401	\N	\N	55	1	standalone	2026-06-21 09:04:08.205047
38422	1401	\N	\N	56	1	standalone	2026-06-21 09:04:08.205047
38423	1412	\N	\N	57	1	standalone	2026-06-21 09:04:08.21106
38424	1401	\N	\N	58	1	standalone	2026-06-21 09:04:08.21106
38425	1401	\N	\N	59	1	standalone	2026-06-21 09:04:08.21106
38426	1401	\N	\N	60	1	standalone	2026-06-21 09:04:08.21106
38427	1401	\N	\N	61	1	standalone	2026-06-21 09:04:08.21106
38428	1413	\N	\N	71	1	standalone	2026-06-21 09:04:08.22132
38429	1401	\N	\N	62	1	standalone	2026-06-21 09:04:08.22132
38430	1403	\N	\N	64	1	standalone	2026-06-21 09:04:08.22132
38431	1403	\N	\N	65	1	standalone	2026-06-21 09:04:08.22132
38432	1403	\N	\N	66	1	standalone	2026-06-21 09:04:08.22132
38433	1403	\N	\N	67	1	standalone	2026-06-21 09:04:08.22132
38434	1403	\N	\N	68	1	standalone	2026-06-21 09:04:08.22132
38435	1403	\N	\N	69	1	standalone	2026-06-21 09:04:08.22132
38436	1403	\N	\N	70	1	standalone	2026-06-21 09:04:08.22132
38437	1405	\N	\N	72	1	standalone	2026-06-21 09:04:08.22132
38438	1403	\N	\N	73	1	standalone	2026-06-21 09:04:08.22132
38439	1403	\N	\N	74	1	standalone	2026-06-21 09:04:08.22132
38440	1403	\N	\N	75	1	standalone	2026-06-21 09:04:08.22132
38441	1412	\N	\N	76	1	standalone	2026-06-21 09:04:08.22132
38442	1403	\N	\N	77	1	standalone	2026-06-21 09:04:08.22132
38443	1403	\N	\N	79	1	standalone	2026-06-21 09:04:08.22132
38444	1403	\N	\N	80	1	standalone	2026-06-21 09:04:08.22132
38445	1412	\N	\N	81	1	standalone	2026-06-21 09:04:08.22132
38446	1404	\N	\N	82	1	standalone	2026-06-21 09:04:08.22132
38447	1408	\N	\N	83	1	standalone	2026-06-21 09:04:08.22132
38448	1406	\N	\N	84	1	standalone	2026-06-21 09:04:08.22132
38449	1408	\N	\N	85	1	standalone	2026-06-21 09:04:08.22132
38450	1406	\N	\N	87	1	standalone	2026-06-21 09:04:08.22132
38451	1403	\N	\N	88	1	standalone	2026-06-21 09:04:08.22132
38452	1403	\N	\N	89	1	standalone	2026-06-21 09:04:08.22132
38453	1405	\N	\N	90	1	standalone	2026-06-21 09:04:08.22132
38454	1414	\N	\N	91	1	standalone	2026-06-21 09:04:08.241436
38455	1412	\N	\N	92	1	standalone	2026-06-21 09:04:08.241436
38456	1412	\N	\N	93	1	standalone	2026-06-21 09:04:08.241436
38457	1404	\N	\N	94	1	standalone	2026-06-21 09:04:08.241436
38458	1404	\N	\N	95	1	standalone	2026-06-21 09:04:08.241436
38459	1413	\N	\N	96	1	standalone	2026-06-21 09:04:08.241436
38460	1413	\N	\N	97	1	standalone	2026-06-21 09:04:08.241436
38461	1413	\N	\N	98	1	standalone	2026-06-21 09:04:08.241436
38462	1405	\N	\N	99	1	standalone	2026-06-21 09:04:08.241436
38463	1404	\N	\N	101	1	standalone	2026-06-21 09:04:08.241436
38464	1410	\N	\N	102	1	standalone	2026-06-21 09:04:08.241436
38465	1404	\N	\N	103	1	standalone	2026-06-21 09:04:08.241436
38466	1408	\N	\N	104	1	standalone	2026-06-21 09:04:08.241436
38467	1408	\N	\N	105	1	standalone	2026-06-21 09:04:08.241436
38468	1404	\N	\N	106	1	standalone	2026-06-21 09:04:08.241436
38469	1408	\N	\N	123	1	standalone	2026-06-21 09:04:08.241436
38470	1408	\N	\N	107	1	standalone	2026-06-21 09:04:08.241436
38471	1404	\N	\N	108	1	standalone	2026-06-21 09:04:08.241436
38472	1400	\N	\N	109	1	standalone	2026-06-21 09:04:08.241436
38473	1401	\N	\N	110	1	standalone	2026-06-21 09:04:08.241436
38474	1404	\N	\N	111	1	standalone	2026-06-21 09:04:08.241436
38475	1404	\N	\N	112	1	standalone	2026-06-21 09:04:08.241436
38476	1404	\N	\N	113	1	standalone	2026-06-21 09:04:08.241436
38477	1404	\N	\N	114	1	standalone	2026-06-21 09:04:08.241436
38478	1404	\N	\N	115	1	standalone	2026-06-21 09:04:08.241436
38479	1412	\N	\N	116	1	standalone	2026-06-21 09:04:08.241436
38480	1404	\N	\N	117	1	standalone	2026-06-21 09:04:08.241436
38481	1403	\N	\N	118	1	standalone	2026-06-21 09:04:08.241436
38482	1412	\N	\N	119	1	standalone	2026-06-21 09:04:08.241436
38483	1412	\N	\N	120	1	standalone	2026-06-21 09:04:08.241436
38484	1412	\N	\N	121	1	standalone	2026-06-21 09:04:08.241436
38485	1412	\N	\N	122	1	standalone	2026-06-21 09:04:08.241436
38486	1409	\N	\N	125	1	standalone	2026-06-21 09:04:08.241436
38487	1409	\N	\N	126	1	standalone	2026-06-21 09:04:08.241436
38488	1409	\N	\N	127	1	standalone	2026-06-21 09:04:08.241436
38489	1406	\N	\N	128	1	standalone	2026-06-21 09:04:08.241436
38490	1414	\N	\N	129	1	standalone	2026-06-21 09:04:08.241436
38491	1414	\N	\N	130	1	standalone	2026-06-21 09:04:08.241436
38492	1400	\N	\N	131	1	standalone	2026-06-21 09:04:08.241436
38493	1404	\N	\N	132	1	standalone	2026-06-21 09:04:08.241436
38494	1404	\N	\N	133	1	standalone	2026-06-21 09:04:08.241436
38495	1404	\N	\N	134	1	standalone	2026-06-21 09:04:08.241436
38496	1404	\N	\N	135	1	standalone	2026-06-21 09:04:08.241436
38497	1411	\N	\N	136	1	standalone	2026-06-21 09:04:08.241436
38498	1406	\N	\N	138	1	standalone	2026-06-21 09:04:08.241436
38499	1404	\N	\N	139	1	standalone	2026-06-21 09:04:08.241436
38500	1403	\N	\N	140	1	standalone	2026-06-21 09:04:08.241436
38501	1409	\N	\N	141	1	standalone	2026-06-21 09:04:08.241436
38502	1409	\N	\N	142	1	standalone	2026-06-21 09:04:08.241436
38503	1409	\N	\N	143	1	standalone	2026-06-21 09:04:08.241436
38504	1409	\N	\N	144	1	standalone	2026-06-21 09:04:08.241436
38505	1409	\N	\N	145	1	standalone	2026-06-21 09:04:08.241436
38506	1409	\N	\N	146	1	standalone	2026-06-21 09:04:08.241436
38507	1409	\N	\N	147	1	standalone	2026-06-21 09:04:08.241436
38508	1409	\N	\N	148	1	standalone	2026-06-21 09:04:08.241436
38509	1415	\N	\N	149	1	standalone	2026-06-21 09:04:08.266327
38510	1415	\N	\N	150	1	standalone	2026-06-21 09:04:08.266327
38511	1415	\N	\N	151	1	standalone	2026-06-21 09:04:08.266327
38512	1415	\N	\N	152	1	standalone	2026-06-21 09:04:08.266327
38513	1415	\N	\N	153	1	standalone	2026-06-21 09:04:08.266327
38514	1415	\N	\N	154	1	standalone	2026-06-21 09:04:08.266327
38515	1415	\N	\N	155	1	standalone	2026-06-21 09:04:08.266327
38516	1400	\N	\N	156	1	standalone	2026-06-21 09:04:08.266327
38517	1415	\N	\N	157	1	standalone	2026-06-21 09:04:08.266327
38518	1415	\N	\N	158	1	standalone	2026-06-21 09:04:08.266327
38519	1416	\N	\N	159	1	standalone	2026-06-21 09:04:08.276326
38520	1416	\N	\N	160	1	standalone	2026-06-21 09:04:08.276326
38521	1416	\N	\N	161	1	standalone	2026-06-21 09:04:08.276326
38522	1416	\N	\N	162	1	standalone	2026-06-21 09:04:08.276326
38523	1408	\N	\N	165	1	standalone	2026-06-21 09:04:08.276326
38524	1408	\N	\N	167	1	standalone	2026-06-21 09:04:08.276326
38525	1408	\N	\N	168	1	standalone	2026-06-21 09:04:08.276326
38526	1408	\N	\N	169	1	standalone	2026-06-21 09:04:08.276326
38527	1409	\N	\N	170	1	standalone	2026-06-21 09:04:08.276326
38528	1404	\N	\N	172	1	standalone	2026-06-21 09:04:08.276326
38529	1403	\N	\N	176	1	standalone	2026-06-21 09:04:08.276326
38530	1403	\N	\N	177	1	standalone	2026-06-21 09:04:08.276326
38531	1403	\N	\N	178	1	standalone	2026-06-21 09:04:08.276326
38532	1402	\N	\N	179	1	standalone	2026-06-21 09:04:08.276326
38533	1401	\N	\N	182	1	standalone	2026-06-21 09:04:08.276326
38534	1412	\N	\N	185	1	standalone	2026-06-21 09:04:08.276326
38535	1410	\N	\N	186	1	standalone	2026-06-21 09:04:08.276326
38536	1413	\N	\N	188	1	standalone	2026-06-21 09:04:08.276326
38537	1412	\N	\N	189	1	standalone	2026-06-21 09:04:08.276326
38538	1404	\N	\N	190	1	standalone	2026-06-21 09:04:08.276326
38539	1406	\N	\N	191	1	standalone	2026-06-21 09:04:08.276326
38540	1415	\N	\N	192	1	standalone	2026-06-21 09:04:08.276326
38541	1415	\N	\N	193	1	standalone	2026-06-21 09:04:08.276326
38542	1415	\N	\N	194	1	standalone	2026-06-21 09:04:08.276326
38543	1415	\N	\N	195	1	standalone	2026-06-21 09:04:08.276326
38544	1415	\N	\N	196	1	standalone	2026-06-21 09:04:08.276326
38545	1408	\N	\N	197	1	standalone	2026-06-21 09:04:08.276326
38546	1408	\N	\N	163	1	standalone	2026-06-21 09:04:08.276326
38547	1408	\N	\N	164	1	standalone	2026-06-21 09:04:08.276326
37981	1322	4669	\N	\N	1	domain	2026-06-21 08:21:21.411936
37982	1322	4670	\N	\N	1	domain	2026-06-21 08:21:21.420935
37983	1322	4671	\N	\N	1	domain	2026-06-21 08:21:21.425967
37984	1322	4672	\N	\N	1	domain	2026-06-21 08:21:21.43094
37985	1322	4673	\N	\N	1	domain	2026-06-21 08:21:21.436081
37986	1322	4674	\N	\N	1	domain	2026-06-21 08:21:21.441165
37987	1322	4675	\N	\N	1	domain	2026-06-21 08:21:21.445204
37988	1322	4676	\N	\N	1	domain	2026-06-21 08:21:21.448281
37989	1322	4677	\N	\N	1	domain	2026-06-21 08:21:21.452803
37990	1322	4678	\N	\N	1	domain	2026-06-21 08:21:21.458385
37991	1324	4679	\N	\N	1	domain	2026-06-21 08:21:21.465327
35523	1323	\N	\N	1316	1	standalone	2026-06-21 05:44:33.760601
35524	1323	\N	\N	1323	1	standalone	2026-06-21 05:44:33.760601
35525	1323	\N	\N	1327	1	standalone	2026-06-21 05:44:33.760601
35526	1323	\N	\N	2310	1	standalone	2026-06-21 05:44:33.760601
35527	1323	\N	\N	2314	1	standalone	2026-06-21 05:44:33.760601
35528	1323	\N	\N	2442	1	standalone	2026-06-21 05:44:33.760601
35529	1323	\N	\N	1962	1	standalone	2026-06-21 05:44:33.760601
37992	1324	4680	\N	\N	1	domain	2026-06-21 08:21:21.470484
37993	1324	4681	\N	\N	1	domain	2026-06-21 08:21:21.475495
37994	1325	4682	\N	\N	1	domain	2026-06-21 08:21:21.478407
33875	1326	\N	\N	1726	1	domain	2026-06-21 05:44:31.661684
35534	1322	\N	\N	2627	1	standalone	2026-06-21 05:44:33.771784
35535	1322	\N	\N	2629	1	standalone	2026-06-21 05:44:33.771784
35536	1322	\N	\N	2614	1	standalone	2026-06-21 05:44:33.771784
35537	1322	\N	\N	2631	1	standalone	2026-06-21 05:44:33.771784
35538	1322	\N	\N	2632	1	standalone	2026-06-21 05:44:33.771784
37995	1326	4683	\N	\N	1	domain	2026-06-21 08:21:21.482522
33858	1326	\N	\N	2420	1	domain	2026-06-21 05:44:31.633075
37996	1326	4684	\N	\N	1	domain	2026-06-21 08:21:21.487048
37997	1326	4685	\N	\N	1	domain	2026-06-21 08:21:21.489956
35547	1322	\N	\N	2660	1	standalone	2026-06-21 05:44:33.799828
35548	1322	\N	\N	2661	1	standalone	2026-06-21 05:44:33.799828
37998	1326	4686	\N	\N	1	domain	2026-06-21 08:21:21.492956
35540	1322	\N	\N	2063	1	standalone	2026-06-21 05:44:33.789766
35541	1322	\N	\N	2071	1	standalone	2026-06-21 05:44:33.789766
35542	1322	\N	\N	2730	1	standalone	2026-06-21 05:44:33.789766
35544	1322	\N	\N	2073	1	standalone	2026-06-21 05:44:33.799828
37999	1327	4687	\N	\N	1	domain	2026-06-21 08:21:21.498059
33786	1323	\N	\N	2577	1	standalone	2026-06-21 05:44:31.512364
33787	1323	\N	\N	1258	1	standalone	2026-06-21 05:44:31.512364
38000	1327	4688	\N	\N	1	domain	2026-06-21 08:21:21.503753
38001	1327	4689	\N	\N	1	domain	2026-06-21 08:21:21.508749
38002	1327	4690	\N	\N	1	domain	2026-06-21 08:21:21.514742
33935	1327	\N	\N	3222	1	domain	2026-06-21 05:44:31.797638
38003	1327	4691	\N	\N	1	domain	2026-06-21 08:21:21.520682
38004	1327	4692	\N	\N	1	domain	2026-06-21 08:21:21.526696
33794	1323	\N	\N	1259	1	standalone	2026-06-21 05:44:31.539574
33795	1323	\N	\N	1897	1	standalone	2026-06-21 05:44:31.539574
38005	1327	4693	\N	\N	1	domain	2026-06-21 08:21:21.531704
38006	1327	4694	\N	\N	1	domain	2026-06-21 08:21:21.538006
38007	1327	4695	\N	\N	1	domain	2026-06-21 08:21:21.541095
33799	1323	\N	\N	1901	1	standalone	2026-06-21 05:44:31.539574
38008	1327	4696	\N	\N	1	domain	2026-06-21 08:21:21.546144
33801	1323	\N	\N	1903	1	standalone	2026-06-21 05:44:31.539574
33802	1323	\N	\N	1904	1	standalone	2026-06-21 05:44:31.539574
33803	1323	\N	\N	1905	1	standalone	2026-06-21 05:44:31.539574
38009	1327	4697	\N	\N	1	domain	2026-06-21 08:21:21.552788
33805	1323	\N	\N	1718	1	standalone	2026-06-21 05:44:31.539574
33806	1323	\N	\N	1720	1	standalone	2026-06-21 05:44:31.539574
33807	1323	\N	\N	1250	1	standalone	2026-06-21 05:44:31.539574
38010	1327	4698	\N	\N	1	domain	2026-06-21 08:21:21.558451
33809	1323	\N	\N	1252	1	standalone	2026-06-21 05:44:31.539574
33810	1323	\N	\N	1253	1	standalone	2026-06-21 05:44:31.539574
33811	1323	\N	\N	1254	1	standalone	2026-06-21 05:44:31.539574
33812	1323	\N	\N	1255	1	standalone	2026-06-21 05:44:31.539574
33813	1323	\N	\N	1256	1	standalone	2026-06-21 05:44:31.539574
33814	1323	\N	\N	1257	1	standalone	2026-06-21 05:44:31.539574
33815	1323	\N	\N	2440	1	standalone	2026-06-21 05:44:31.539574
33816	1323	\N	\N	2444	1	standalone	2026-06-21 05:44:31.539574
38011	1327	4699	\N	\N	1	domain	2026-06-21 08:21:21.5634
38012	1327	4700	\N	\N	1	domain	2026-06-21 08:21:21.569426
38013	1327	4701	\N	\N	1	domain	2026-06-21 08:21:21.575134
33936	1327	\N	\N	3311	1	domain	2026-06-21 05:44:31.797638
38014	1327	4702	\N	\N	1	domain	2026-06-21 08:21:21.58138
38015	1328	4703	\N	\N	1	domain	2026-06-21 08:21:21.588048
38016	1328	4704	\N	\N	1	domain	2026-06-21 08:21:21.593715
38017	1328	4705	\N	\N	1	domain	2026-06-21 08:21:21.59973
38018	1328	4706	\N	\N	1	domain	2026-06-21 08:21:21.600603
36454	1328	\N	\N	999	1	domain	2026-06-21 05:44:34.757386
38019	1328	4707	\N	\N	1	domain	2026-06-21 08:21:21.600603
36455	1328	\N	\N	1679	1	domain	2026-06-21 05:44:34.757386
38020	1328	4708	\N	\N	1	domain	2026-06-21 08:21:21.600603
38021	1329	4709	\N	\N	1	domain	2026-06-21 08:21:21.618745
38022	1329	4710	\N	\N	1	domain	2026-06-21 08:21:21.624343
33846	1325	\N	\N	362	1	standalone	2026-06-21 05:44:31.594534
33847	1325	\N	\N	2086	1	standalone	2026-06-21 05:44:31.594534
38023	1329	4711	\N	\N	1	domain	2026-06-21 08:21:21.624343
38024	1329	4712	\N	\N	1	domain	2026-06-21 08:21:21.631336
36462	1329	\N	\N	3306	1	domain	2026-06-21 05:44:34.757386
38025	1329	4713	\N	\N	1	domain	2026-06-21 08:21:21.631336
38026	1329	4714	\N	\N	1	domain	2026-06-21 08:21:21.631336
35904	1329	\N	\N	826	1	domain	2026-06-21 05:44:34.148073
33856	1326	\N	\N	2419	1	standalone	2026-06-21 05:44:31.623499
38027	1329	4715	\N	\N	1	domain	2026-06-21 08:21:21.648958
38028	1329	4716	\N	\N	1	domain	2026-06-21 08:21:21.65958
35899	1329	\N	\N	843	1	domain	2026-06-21 05:44:34.122044
35903	1329	\N	\N	38	1	domain	2026-06-21 05:44:34.148073
38029	1329	4717	\N	\N	1	domain	2026-06-21 08:21:21.663394
35334	1330	\N	\N	1018	1	domain	2026-06-21 05:44:33.515008
38030	1330	4718	\N	\N	1	domain	2026-06-21 08:21:21.663394
35048	1330	\N	\N	98	1	domain	2026-06-21 05:44:33.09558
35057	1330	\N	\N	856	1	domain	2026-06-21 05:44:33.122004
38031	1330	4719	\N	\N	1	domain	2026-06-21 08:21:21.663394
35071	1330	\N	\N	808	1	domain	2026-06-21 05:44:33.144385
38032	1330	4720	\N	\N	1	domain	2026-06-21 08:21:21.679253
35068	1330	\N	\N	2106	1	domain	2026-06-21 05:44:33.144385
33870	1326	\N	\N	1912	1	standalone	2026-06-21 05:44:31.654802
33871	1326	\N	\N	1911	1	standalone	2026-06-21 05:44:31.654802
38033	1330	4721	\N	\N	1	domain	2026-06-21 08:21:21.679253
38034	1330	4722	\N	\N	1	domain	2026-06-21 08:21:21.679253
38035	1330	4723	\N	\N	1	domain	2026-06-21 08:21:21.694909
35045	1330	\N	\N	1614	1	domain	2026-06-21 05:44:33.09558
33876	1326	\N	\N	1914	1	standalone	2026-06-21 05:44:31.661684
33877	1326	\N	\N	1917	1	standalone	2026-06-21 05:44:31.661684
33878	1326	\N	\N	1920	1	standalone	2026-06-21 05:44:31.661684
35046	1330	\N	\N	259	1	domain	2026-06-21 05:44:33.09558
38036	1330	4724	\N	\N	1	domain	2026-06-21 08:21:21.694909
38037	1331	4725	\N	\N	1	domain	2026-06-21 08:21:21.694909
38038	1331	4726	\N	\N	1	domain	2026-06-21 08:21:21.694909
38039	1331	4727	\N	\N	1	domain	2026-06-21 08:21:21.710687
38040	1331	4728	\N	\N	1	domain	2026-06-21 08:21:21.710687
33887	1326	\N	\N	281	1	standalone	2026-06-21 05:44:31.678557
33888	1326	\N	\N	282	1	standalone	2026-06-21 05:44:31.678557
33889	1326	\N	\N	838	1	standalone	2026-06-21 05:44:31.678557
33890	1326	\N	\N	1277	1	standalone	2026-06-21 05:44:31.678557
33825	1324	\N	\N	2675	1	standalone	2026-06-21 05:44:31.561354
33824	1324	\N	\N	2674	1	standalone	2026-06-21 05:44:31.561354
33827	1324	\N	\N	2677	1	standalone	2026-06-21 05:44:31.561354
33822	1324	\N	\N	2628	1	standalone	2026-06-21 05:44:31.561354
33826	1324	\N	\N	2676	1	standalone	2026-06-21 05:44:31.561354
33779	1322	\N	\N	2905	1	standalone	2026-06-21 05:44:31.489528
33780	1322	\N	\N	1135	1	standalone	2026-06-21 05:44:31.489528
33781	1322	\N	\N	1822	1	standalone	2026-06-21 05:44:31.489528
33782	1322	\N	\N	2107	1	standalone	2026-06-21 05:44:31.489528
33783	1322	\N	\N	2133	1	standalone	2026-06-21 05:44:31.489528
33784	1322	\N	\N	2138	1	standalone	2026-06-21 05:44:31.489528
33785	1322	\N	\N	2414	1	standalone	2026-06-21 05:44:31.489528
33849	1322	\N	\N	748	1	standalone	2026-06-21 05:44:31.610344
33850	1322	\N	\N	163	1	standalone	2026-06-21 05:44:31.610344
33818	1323	\N	\N	3393	1	standalone	2026-06-21 05:44:31.544848
33819	1323	\N	\N	2825	1	standalone	2026-06-21 05:44:31.544848
33820	1323	\N	\N	2826	1	standalone	2026-06-21 05:44:31.544848
33829	1325	\N	\N	1	1	standalone	2026-06-21 05:44:31.571763
33830	1325	\N	\N	3	1	standalone	2026-06-21 05:44:31.571763
33831	1325	\N	\N	1559	1	standalone	2026-06-21 05:44:31.571763
33832	1325	\N	\N	2084	1	standalone	2026-06-21 05:44:31.571763
33833	1325	\N	\N	2672	1	standalone	2026-06-21 05:44:31.571763
33834	1325	\N	\N	2673	1	standalone	2026-06-21 05:44:31.571763
33895	1326	\N	\N	2283	1	standalone	2026-06-21 05:44:31.695317
33896	1326	\N	\N	2327	1	standalone	2026-06-21 05:44:31.695317
33970	1322	\N	\N	944	1	domain	2026-06-21 05:44:31.853
33899	1326	\N	\N	697	1	domain	2026-06-21 05:44:31.705238
33904	1326	\N	\N	277	1	domain	2026-06-21 05:44:31.705238
33910	1327	\N	\N	3318	1	domain	2026-06-21 05:44:31.728048
33914	1327	\N	\N	2200	1	domain	2026-06-21 05:44:31.728048
33911	1327	\N	\N	753	1	domain	2026-06-21 05:44:31.728048
33907	1327	\N	\N	1693	1	standalone	2026-06-21 05:44:31.719259
33940	1327	\N	\N	69	1	domain	2026-06-21 05:44:31.797638
33928	1327	\N	\N	1943	1	domain	2026-06-21 05:44:31.778603
33930	1327	\N	\N	3268	1	domain	2026-06-21 05:44:31.786826
36071	1331	\N	\N	3248	1	domain	2026-06-21 05:44:34.362521
38041	1331	4729	\N	\N	1	domain	2026-06-21 08:21:21.710687
38042	1331	4730	\N	\N	1	domain	2026-06-21 08:21:21.726871
38043	1332	4731	\N	\N	1	domain	2026-06-21 08:21:21.726871
34378	1333	\N	\N	1812	1	domain	2026-06-21 05:44:32.287375
38044	1333	4732	\N	\N	1	domain	2026-06-21 08:21:21.726871
36106	1333	\N	\N	1517	1	domain	2026-06-21 05:44:34.412677
38045	1333	4733	\N	\N	1	domain	2026-06-21 08:21:21.742693
34423	1334	\N	\N	1738	1	domain	2026-06-21 05:44:32.338592
38046	1334	4734	\N	\N	1	domain	2026-06-21 08:21:21.742693
34438	1334	\N	\N	626	1	domain	2026-06-21 05:44:32.384845
38047	1334	4735	\N	\N	1	domain	2026-06-21 08:21:21.757678
34437	1334	\N	\N	625	1	domain	2026-06-21 05:44:32.384845
34441	1334	\N	\N	1589	1	domain	2026-06-21 05:44:32.384845
38048	1334	4736	\N	\N	1	domain	2026-06-21 08:21:21.758691
34752	1335	\N	\N	2409	1	domain	2026-06-21 05:44:32.800824
33937	1327	\N	\N	242	1	standalone	2026-06-21 05:44:31.797638
33938	1327	\N	\N	243	1	standalone	2026-06-21 05:44:31.797638
33939	1327	\N	\N	3366	1	standalone	2026-06-21 05:44:31.797638
38049	1335	4737	\N	\N	1	domain	2026-06-21 08:21:21.758691
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
38050	1335	4738	\N	\N	1	domain	2026-06-21 08:21:21.758691
33953	1327	\N	\N	2249	1	standalone	2026-06-21 05:44:31.797638
33954	1327	\N	\N	2262	1	standalone	2026-06-21 05:44:31.797638
33955	1327	\N	\N	2395	1	standalone	2026-06-21 05:44:31.797638
38051	1336	4739	\N	\N	1	domain	2026-06-21 08:21:21.774792
38052	1336	4740	\N	\N	1	domain	2026-06-21 08:21:21.781372
38053	1336	4741	\N	\N	1	domain	2026-06-21 08:21:21.787397
35151	1336	\N	\N	1194	1	domain	2026-06-21 05:44:33.244994
35172	1336	\N	\N	3022	1	domain	2026-06-21 05:44:33.292264
38054	1336	4742	\N	\N	1	domain	2026-06-21 08:21:21.790915
35156	1336	\N	\N	3345	1	domain	2026-06-21 05:44:33.263718
35157	1336	\N	\N	2170	1	domain	2026-06-21 05:44:33.263718
38055	1336	4743	\N	\N	1	domain	2026-06-21 08:21:21.798632
38056	1337	4744	\N	\N	1	domain	2026-06-21 08:21:21.800639
35307	1337	\N	\N	256	1	domain	2026-06-21 05:44:33.475768
38057	1337	4745	\N	\N	1	domain	2026-06-21 08:21:21.811586
38058	1338	4746	\N	\N	1	domain	2026-06-21 08:21:21.81962
38059	1338	4747	\N	\N	1	domain	2026-06-21 08:21:21.826651
36211	1338	\N	\N	1656	1	domain	2026-06-21 05:44:34.540793
38060	1338	4748	\N	\N	1	domain	2026-06-21 08:21:21.832677
35436	1338	\N	\N	875	1	domain	2026-06-21 05:44:33.679105
38061	1338	4749	\N	\N	1	domain	2026-06-21 08:21:21.838502
33971	1322	\N	\N	2579	1	standalone	2026-06-21 05:44:31.853
33972	1322	\N	\N	1818	1	standalone	2026-06-21 05:44:31.853
33973	1322	\N	\N	787	1	standalone	2026-06-21 05:44:31.853
33974	1322	\N	\N	3356	1	standalone	2026-06-21 05:44:31.853
33975	1322	\N	\N	123	1	standalone	2026-06-21 05:44:31.853
33976	1322	\N	\N	2031	1	standalone	2026-06-21 05:44:31.853
33893	1326	\N	\N	302	1	standalone	2026-06-21 05:44:31.695317
33894	1326	\N	\N	1269	1	standalone	2026-06-21 05:44:31.695317
33900	1326	\N	\N	3273	1	standalone	2026-06-21 05:44:31.705238
33905	1326	\N	\N	837	1	standalone	2026-06-21 05:44:31.705238
33918	1327	\N	\N	3196	1	standalone	2026-06-21 05:44:31.762147
33920	1327	\N	\N	566	1	standalone	2026-06-21 05:44:31.762147
33922	1327	\N	\N	694	1	standalone	2026-06-21 05:44:31.771806
33924	1327	\N	\N	444	1	standalone	2026-06-21 05:44:31.771806
33931	1327	\N	\N	2922	1	standalone	2026-06-21 05:44:31.786826
34096	1327	\N	\N	1416	1	domain	2026-06-21 05:44:32.011888
33985	1328	\N	\N	2694	1	domain	2026-06-21 05:44:31.876739
33988	1328	\N	\N	3383	1	domain	2026-06-21 05:44:31.876739
33999	1328	\N	\N	60	1	domain	2026-06-21 05:44:31.888851
34000	1328	\N	\N	61	1	domain	2026-06-21 05:44:31.888851
34003	1328	\N	\N	183	1	domain	2026-06-21 05:44:31.888851
34045	1328	\N	\N	48	1	domain	2026-06-21 05:44:31.948158
34059	1329	\N	\N	607	1	domain	2026-06-21 05:44:31.974536
34074	1329	\N	\N	1226	1	domain	2026-06-21 05:44:31.987186
35411	1338	\N	\N	2172	1	domain	2026-06-21 05:44:33.623313
38062	1338	4750	\N	\N	1	domain	2026-06-21 08:21:21.838502
36433	1338	\N	\N	1208	1	domain	2026-06-21 05:44:34.741485
36434	1338	\N	\N	2215	1	domain	2026-06-21 05:44:34.741485
38063	1338	4751	\N	\N	1	domain	2026-06-21 08:21:21.838502
34039	1328	\N	\N	110	1	standalone	2026-06-21 05:44:31.932216
34040	1328	\N	\N	2520	1	standalone	2026-06-21 05:44:31.932216
34041	1328	\N	\N	2524	1	standalone	2026-06-21 05:44:31.932216
34060	1329	\N	\N	606	1	standalone	2026-06-21 05:44:31.974536
34071	1329	\N	\N	2930	1	standalone	2026-06-21 05:44:31.987186
34072	1329	\N	\N	1224	1	standalone	2026-06-21 05:44:31.987186
34073	1329	\N	\N	1225	1	standalone	2026-06-21 05:44:31.987186
34075	1329	\N	\N	1424	1	standalone	2026-06-21 05:44:31.987186
34076	1329	\N	\N	2003	1	standalone	2026-06-21 05:44:31.987186
34088	1327	\N	\N	1859	1	standalone	2026-06-21 05:44:31.995433
34089	1327	\N	\N	1889	1	standalone	2026-06-21 05:44:31.995433
34090	1327	\N	\N	1941	1	standalone	2026-06-21 05:44:31.995433
34091	1327	\N	\N	1694	1	standalone	2026-06-21 05:44:31.995433
34092	1327	\N	\N	1592	1	standalone	2026-06-21 05:44:31.995433
34093	1327	\N	\N	689	1	standalone	2026-06-21 05:44:31.995433
34078	1327	\N	\N	3314	1	standalone	2026-06-21 05:44:31.995433
34085	1327	\N	\N	2244	1	standalone	2026-06-21 05:44:31.995433
34095	1327	\N	\N	3323	1	standalone	2026-06-21 05:44:32.011888
34097	1327	\N	\N	1410	1	standalone	2026-06-21 05:44:32.011888
34099	1327	\N	\N	2371	1	standalone	2026-06-21 05:44:32.011888
34100	1327	\N	\N	2372	1	standalone	2026-06-21 05:44:32.011888
34102	1327	\N	\N	1604	1	standalone	2026-06-21 05:44:32.024391
33986	1328	\N	\N	2620	1	standalone	2026-06-21 05:44:31.876739
33990	1328	\N	\N	713	1	standalone	2026-06-21 05:44:31.876739
33993	1328	\N	\N	2754	1	standalone	2026-06-21 05:44:31.876739
33996	1328	\N	\N	182	1	standalone	2026-06-21 05:44:31.888851
34005	1328	\N	\N	3210	1	standalone	2026-06-21 05:44:31.888851
34026	1328	\N	\N	2315	1	standalone	2026-06-21 05:44:31.917841
34028	1328	\N	\N	2699	1	standalone	2026-06-21 05:44:31.932216
34029	1328	\N	\N	2468	1	standalone	2026-06-21 05:44:31.932216
34030	1328	\N	\N	2476	1	standalone	2026-06-21 05:44:31.932216
34031	1328	\N	\N	2479	1	standalone	2026-06-21 05:44:31.932216
34033	1328	\N	\N	3197	1	standalone	2026-06-21 05:44:31.932216
34034	1328	\N	\N	3206	1	standalone	2026-06-21 05:44:31.932216
34035	1328	\N	\N	989	1	standalone	2026-06-21 05:44:31.932216
34043	1328	\N	\N	717	1	standalone	2026-06-21 05:44:31.948158
34047	1328	\N	\N	50	1	standalone	2026-06-21 05:44:31.948158
34066	1329	\N	\N	1223	1	standalone	2026-06-21 05:44:31.987186
34106	1327	\N	\N	693	1	domain	2026-06-21 05:44:32.028186
34120	1327	\N	\N	3142	1	domain	2026-06-21 05:44:32.044061
34121	1327	\N	\N	1240	1	domain	2026-06-21 05:44:32.044061
34116	1327	\N	\N	418	1	standalone	2026-06-21 05:44:32.028186
34117	1327	\N	\N	443	1	standalone	2026-06-21 05:44:32.028186
34129	1327	\N	\N	763	1	domain	2026-06-21 05:44:32.069891
34130	1327	\N	\N	70	1	domain	2026-06-21 05:44:32.069891
34122	1327	\N	\N	725	1	standalone	2026-06-21 05:44:32.044061
34131	1327	\N	\N	73	1	domain	2026-06-21 05:44:32.069891
34132	1327	\N	\N	553	1	standalone	2026-06-21 05:44:32.069891
34134	1327	\N	\N	1283	1	standalone	2026-06-21 05:44:32.069891
34138	1327	\N	\N	2447	1	standalone	2026-06-21 05:44:32.077232
34139	1327	\N	\N	2256	1	standalone	2026-06-21 05:44:32.077232
34140	1327	\N	\N	2259	1	standalone	2026-06-21 05:44:32.077232
34141	1327	\N	\N	2260	1	standalone	2026-06-21 05:44:32.077232
34145	1327	\N	\N	300	1	standalone	2026-06-21 05:44:32.091899
34150	1327	\N	\N	212	1	standalone	2026-06-21 05:44:32.100033
34151	1327	\N	\N	1628	1	standalone	2026-06-21 05:44:32.100033
34152	1327	\N	\N	75	1	standalone	2026-06-21 05:44:32.100033
34153	1327	\N	\N	1668	1	standalone	2026-06-21 05:44:32.100033
34154	1327	\N	\N	2206	1	standalone	2026-06-21 05:44:32.100033
34155	1327	\N	\N	1936	1	standalone	2026-06-21 05:44:32.100033
34156	1327	\N	\N	1264	1	standalone	2026-06-21 05:44:32.100033
34157	1327	\N	\N	118	1	standalone	2026-06-21 05:44:32.100033
34158	1327	\N	\N	420	1	standalone	2026-06-21 05:44:32.100033
34159	1327	\N	\N	424	1	standalone	2026-06-21 05:44:32.100033
34103	1327	\N	\N	67	1	standalone	2026-06-21 05:44:32.024391
34105	1327	\N	\N	691	1	standalone	2026-06-21 05:44:32.028186
34107	1327	\N	\N	723	1	standalone	2026-06-21 05:44:32.028186
34109	1327	\N	\N	1948	1	standalone	2026-06-21 05:44:32.028186
34110	1327	\N	\N	2522	1	standalone	2026-06-21 05:44:32.028186
34112	1327	\N	\N	1594	1	standalone	2026-06-21 05:44:32.028186
34113	1327	\N	\N	1595	1	standalone	2026-06-21 05:44:32.028186
34114	1327	\N	\N	1949	1	standalone	2026-06-21 05:44:32.028186
34115	1327	\N	\N	1950	1	standalone	2026-06-21 05:44:32.028186
34124	1327	\N	\N	396	1	standalone	2026-06-21 05:44:32.044061
34125	1327	\N	\N	416	1	standalone	2026-06-21 05:44:32.044061
34126	1327	\N	\N	714	1	standalone	2026-06-21 05:44:32.044061
34127	1327	\N	\N	455	1	standalone	2026-06-21 05:44:32.044061
34143	1327	\N	\N	792	1	standalone	2026-06-21 05:44:32.091899
34147	1327	\N	\N	3126	1	standalone	2026-06-21 05:44:32.100033
34148	1327	\N	\N	3129	1	standalone	2026-06-21 05:44:32.100033
34149	1327	\N	\N	549	1	standalone	2026-06-21 05:44:32.100033
34162	1327	\N	\N	3127	1	standalone	2026-06-21 05:44:32.120663
34163	1327	\N	\N	1601	1	standalone	2026-06-21 05:44:32.120663
34165	1327	\N	\N	1605	1	standalone	2026-06-21 05:44:32.120663
34166	1327	\N	\N	3266	1	standalone	2026-06-21 05:44:32.120663
34168	1327	\N	\N	419	1	standalone	2026-06-21 05:44:32.120663
34223	1329	\N	\N	3296	1	domain	2026-06-21 05:44:32.141353
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
34267	1331	\N	\N	602	1	domain	2026-06-21 05:44:32.191088
34221	1329	\N	\N	436	1	standalone	2026-06-21 05:44:32.141353
34222	1329	\N	\N	3295	1	standalone	2026-06-21 05:44:32.141353
34224	1329	\N	\N	438	1	standalone	2026-06-21 05:44:32.141353
34226	1329	\N	\N	3300	1	standalone	2026-06-21 05:44:32.141353
34227	1329	\N	\N	3301	1	standalone	2026-06-21 05:44:32.141353
34228	1329	\N	\N	3302	1	standalone	2026-06-21 05:44:32.141353
34229	1329	\N	\N	3303	1	standalone	2026-06-21 05:44:32.141353
34230	1329	\N	\N	3304	1	standalone	2026-06-21 05:44:32.141353
34231	1329	\N	\N	461	1	standalone	2026-06-21 05:44:32.141353
34232	1329	\N	\N	470	1	standalone	2026-06-21 05:44:32.141353
34233	1329	\N	\N	1530	1	standalone	2026-06-21 05:44:32.141353
34268	1331	\N	\N	922	1	domain	2026-06-21 05:44:32.191088
34235	1329	\N	\N	884	1	standalone	2026-06-21 05:44:32.141353
34236	1329	\N	\N	885	1	standalone	2026-06-21 05:44:32.141353
34289	1331	\N	\N	3144	1	domain	2026-06-21 05:44:32.191088
34290	1331	\N	\N	3145	1	domain	2026-06-21 05:44:32.191088
34239	1329	\N	\N	888	1	standalone	2026-06-21 05:44:32.141353
34240	1329	\N	\N	896	1	standalone	2026-06-21 05:44:32.141353
34241	1329	\N	\N	897	1	standalone	2026-06-21 05:44:32.141353
34242	1329	\N	\N	7009	1	standalone	2026-06-21 05:44:32.141353
34243	1329	\N	\N	7010	1	standalone	2026-06-21 05:44:32.141353
38135	1382	4775	\N	\N	1	domain	2026-06-21 08:57:51.001844
34251	1331	\N	\N	912	1	standalone	2026-06-21 05:44:32.173215
34252	1331	\N	\N	914	1	standalone	2026-06-21 05:44:32.173215
34253	1331	\N	\N	916	1	standalone	2026-06-21 05:44:32.173215
34254	1331	\N	\N	917	1	standalone	2026-06-21 05:44:32.173215
34255	1331	\N	\N	592	1	standalone	2026-06-21 05:44:32.173215
38136	1382	\N	\N	1067	1	domain	2026-06-21 08:57:51.001844
34257	1331	\N	\N	918	1	standalone	2026-06-21 05:44:32.173215
34258	1331	\N	\N	910	1	standalone	2026-06-21 05:44:32.173215
34259	1331	\N	\N	911	1	standalone	2026-06-21 05:44:32.173215
34260	1331	\N	\N	904	1	standalone	2026-06-21 05:44:32.173215
34261	1331	\N	\N	905	1	standalone	2026-06-21 05:44:32.173215
34262	1331	\N	\N	906	1	standalone	2026-06-21 05:44:32.173215
38137	1382	\N	\N	943	1	domain	2026-06-21 08:57:51.001844
34264	1331	\N	\N	908	1	standalone	2026-06-21 05:44:32.173215
38138	1383	4776	\N	\N	1	domain	2026-06-21 08:57:51.012494
38139	1383	\N	\N	1056	1	domain	2026-06-21 08:57:51.012494
34269	1331	\N	\N	923	1	standalone	2026-06-21 05:44:32.191088
34270	1331	\N	\N	924	1	standalone	2026-06-21 05:44:32.191088
38140	1383	\N	\N	980	1	domain	2026-06-21 08:57:51.012494
34272	1331	\N	\N	927	1	standalone	2026-06-21 05:44:32.191088
34273	1331	\N	\N	929	1	standalone	2026-06-21 05:44:32.191088
34274	1331	\N	\N	972	1	standalone	2026-06-21 05:44:32.191088
34275	1331	\N	\N	932	1	standalone	2026-06-21 05:44:32.191088
38141	1384	4777	\N	\N	1	domain	2026-06-21 08:57:51.035248
38142	1384	\N	\N	1055	1	domain	2026-06-21 08:57:51.035248
38143	1384	\N	\N	919	1	domain	2026-06-21 08:57:51.035248
34279	1331	\N	\N	2870	1	standalone	2026-06-21 05:44:32.191088
34280	1331	\N	\N	712	1	standalone	2026-06-21 05:44:32.191088
34281	1331	\N	\N	3278	1	standalone	2026-06-21 05:44:32.191088
38144	1385	\N	\N	912	1	standalone	2026-06-21 08:57:51.038753
34283	1331	\N	\N	937	1	standalone	2026-06-21 05:44:32.191088
34284	1331	\N	\N	938	1	standalone	2026-06-21 05:44:32.191088
34285	1331	\N	\N	939	1	standalone	2026-06-21 05:44:32.191088
34286	1331	\N	\N	940	1	standalone	2026-06-21 05:44:32.191088
34287	1331	\N	\N	941	1	standalone	2026-06-21 05:44:32.191088
38145	1385	\N	\N	913	1	standalone	2026-06-21 08:57:51.038753
34291	1331	\N	\N	3151	1	standalone	2026-06-21 05:44:32.191088
34292	1331	\N	\N	3055	1	standalone	2026-06-21 05:44:32.191088
38146	1385	\N	\N	914	1	standalone	2026-06-21 08:57:51.038753
34294	1331	\N	\N	1646	1	standalone	2026-06-21 05:44:32.191088
34295	1331	\N	\N	3244	1	standalone	2026-06-21 05:44:32.191088
38147	1385	\N	\N	915	1	standalone	2026-06-21 08:57:51.038753
34297	1331	\N	\N	3246	1	standalone	2026-06-21 05:44:32.191088
34298	1331	\N	\N	2141	1	standalone	2026-06-21 05:44:32.191088
34299	1331	\N	\N	2151	1	standalone	2026-06-21 05:44:32.191088
34300	1331	\N	\N	2144	1	standalone	2026-06-21 05:44:32.191088
34301	1331	\N	\N	2145	1	standalone	2026-06-21 05:44:32.191088
34302	1331	\N	\N	2146	1	standalone	2026-06-21 05:44:32.191088
34303	1331	\N	\N	2152	1	standalone	2026-06-21 05:44:32.191088
38148	1385	\N	\N	916	1	standalone	2026-06-21 08:57:51.038753
38149	1385	\N	\N	917	1	standalone	2026-06-21 08:57:51.038753
38150	1385	\N	\N	918	1	standalone	2026-06-21 08:57:51.038753
34245	1322	\N	\N	351	1	standalone	2026-06-21 05:44:32.159156
34246	1322	\N	\N	3354	1	standalone	2026-06-21 05:44:32.159156
34247	1322	\N	\N	2893	1	standalone	2026-06-21 05:44:32.159156
34248	1322	\N	\N	503	1	standalone	2026-06-21 05:44:32.159156
34249	1322	\N	\N	504	1	standalone	2026-06-21 05:44:32.159156
34250	1322	\N	\N	507	1	standalone	2026-06-21 05:44:32.159156
34201	1329	\N	\N	1833	1	standalone	2026-06-21 05:44:32.141353
34202	1329	\N	\N	732	1	standalone	2026-06-21 05:44:32.141353
34203	1329	\N	\N	106	1	standalone	2026-06-21 05:44:32.141353
34199	1330	\N	\N	2013	1	standalone	2026-06-21 05:44:32.132998
34209	1329	\N	\N	653	1	domain	2026-06-21 05:44:32.141353
34225	1329	\N	\N	3299	1	domain	2026-06-21 05:44:32.141353
34399	1322	\N	\N	791	1	domain	2026-06-21 05:44:32.304182
34309	1331	\N	\N	2763	1	standalone	2026-06-21 05:44:32.191088
34310	1331	\N	\N	2767	1	standalone	2026-06-21 05:44:32.191088
34347	1325	\N	\N	3189	1	domain	2026-06-21 05:44:32.246697
34349	1325	\N	\N	1691	1	domain	2026-06-21 05:44:32.254747
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
34332	1331	\N	\N	704	1	domain	2026-06-21 05:44:32.221861
34386	1333	\N	\N	1285	1	domain	2026-06-21 05:44:32.287375
38151	1386	\N	\N	920	1	standalone	2026-06-21 08:57:51.044864
38152	1385	\N	\N	910	1	standalone	2026-06-21 08:57:51.044864
38153	1385	\N	\N	911	1	standalone	2026-06-21 08:57:51.044864
38154	1385	\N	\N	904	1	standalone	2026-06-21 08:57:51.044864
38155	1385	\N	\N	905	1	standalone	2026-06-21 08:57:51.044864
38156	1385	\N	\N	906	1	standalone	2026-06-21 08:57:51.044864
38157	1385	\N	\N	907	1	standalone	2026-06-21 08:57:51.044864
38158	1385	\N	\N	908	1	standalone	2026-06-21 08:57:51.044864
34352	1325	\N	\N	2523	1	standalone	2026-06-21 05:44:32.254747
34353	1325	\N	\N	2573	1	standalone	2026-06-21 05:44:32.254747
38159	1385	\N	\N	909	1	standalone	2026-06-21 08:57:51.044864
38160	1385	\N	\N	921	1	standalone	2026-06-21 08:57:51.044864
38161	1385	\N	\N	922	1	standalone	2026-06-21 08:57:51.044864
38162	1385	\N	\N	923	1	standalone	2026-06-21 08:57:51.044864
38163	1385	\N	\N	924	1	standalone	2026-06-21 08:57:51.044864
38164	1382	\N	\N	925	1	standalone	2026-06-21 08:57:51.044864
38165	1385	\N	\N	926	1	standalone	2026-06-21 08:57:51.044864
38166	1385	\N	\N	927	1	standalone	2026-06-21 08:57:51.044864
38167	1385	\N	\N	928	1	standalone	2026-06-21 08:57:51.044864
34363	1333	\N	\N	200	1	standalone	2026-06-21 05:44:32.259261
34364	1333	\N	\N	202	1	standalone	2026-06-21 05:44:32.259261
34365	1333	\N	\N	1862	1	standalone	2026-06-21 05:44:32.259261
34366	1333	\N	\N	1863	1	standalone	2026-06-21 05:44:32.259261
38168	1385	\N	\N	929	1	standalone	2026-06-21 08:57:51.044864
38169	1385	\N	\N	930	1	standalone	2026-06-21 08:57:51.044864
38170	1387	\N	\N	931	1	standalone	2026-06-21 08:57:51.049198
38171	1385	\N	\N	932	1	standalone	2026-06-21 08:57:51.049198
34371	1333	\N	\N	206	1	standalone	2026-06-21 05:44:32.270428
34372	1333	\N	\N	236	1	standalone	2026-06-21 05:44:32.270428
38172	1385	\N	\N	933	1	standalone	2026-06-21 08:57:51.049198
38173	1385	\N	\N	934	1	standalone	2026-06-21 08:57:51.049198
38174	1385	\N	\N	935	1	standalone	2026-06-21 08:57:51.049198
34376	1333	\N	\N	25	1	standalone	2026-06-21 05:44:32.278878
38175	1385	\N	\N	936	1	standalone	2026-06-21 08:57:51.049198
38176	1385	\N	\N	937	1	standalone	2026-06-21 08:57:51.049198
38177	1385	\N	\N	938	1	standalone	2026-06-21 08:57:51.049198
34380	1333	\N	\N	1929	1	standalone	2026-06-21 05:44:32.287375
34381	1333	\N	\N	316	1	standalone	2026-06-21 05:44:32.287375
34382	1333	\N	\N	2959	1	standalone	2026-06-21 05:44:32.287375
34383	1333	\N	\N	1993	1	standalone	2026-06-21 05:44:32.287375
34384	1333	\N	\N	2225	1	standalone	2026-06-21 05:44:32.287375
34385	1333	\N	\N	2228	1	standalone	2026-06-21 05:44:32.287375
34387	1333	\N	\N	2042	1	standalone	2026-06-21 05:44:32.287375
34388	1333	\N	\N	2300	1	standalone	2026-06-21 05:44:32.287375
34389	1333	\N	\N	2340	1	standalone	2026-06-21 05:44:32.287375
38178	1385	\N	\N	939	1	standalone	2026-06-21 08:57:51.049198
38179	1385	\N	\N	940	1	standalone	2026-06-21 08:57:51.049198
38180	1385	\N	\N	941	1	standalone	2026-06-21 08:57:51.049198
38181	1385	\N	\N	942	1	standalone	2026-06-21 08:57:51.049198
38182	1382	\N	\N	944	1	standalone	2026-06-21 08:57:51.049198
38183	1382	\N	\N	945	1	standalone	2026-06-21 08:57:51.049198
38184	1388	\N	\N	946	1	standalone	2026-06-21 08:57:51.05218
38185	1382	\N	\N	947	1	standalone	2026-06-21 08:57:51.05218
38186	1382	\N	\N	948	1	standalone	2026-06-21 08:57:51.05218
38187	1382	\N	\N	949	1	standalone	2026-06-21 08:57:51.05218
38188	1389	\N	\N	950	1	standalone	2026-06-21 08:57:51.054178
38189	1390	\N	\N	951	1	standalone	2026-06-21 08:57:51.058088
34406	1322	\N	\N	1819	1	standalone	2026-06-21 05:44:32.312033
38190	1383	\N	\N	952	1	standalone	2026-06-21 08:57:51.058088
38191	1382	\N	\N	953	1	standalone	2026-06-21 08:57:51.058088
38192	1383	\N	\N	954	1	standalone	2026-06-21 08:57:51.058088
38193	1386	\N	\N	955	1	standalone	2026-06-21 08:57:51.058088
38194	1386	\N	\N	956	1	standalone	2026-06-21 08:57:51.058088
38195	1386	\N	\N	957	1	standalone	2026-06-21 08:57:51.058088
38196	1388	\N	\N	958	1	standalone	2026-06-21 08:57:51.058088
34401	1322	\N	\N	2033	1	standalone	2026-06-21 05:44:32.304182
34403	1322	\N	\N	686	1	standalone	2026-06-21 05:44:32.312033
34405	1322	\N	\N	2034	1	standalone	2026-06-21 05:44:32.312033
34342	1325	\N	\N	2	1	standalone	2026-06-21 05:44:32.246697
34345	1325	\N	\N	1124	1	standalone	2026-06-21 05:44:32.246697
34346	1325	\N	\N	2680	1	standalone	2026-06-21 05:44:32.246697
34350	1325	\N	\N	2048	1	standalone	2026-06-21 05:44:32.254747
34351	1325	\N	\N	2273	1	standalone	2026-06-21 05:44:32.254747
34330	1331	\N	\N	604	1	standalone	2026-06-21 05:44:32.221861
34333	1331	\N	\N	3338	1	standalone	2026-06-21 05:44:32.221861
34334	1331	\N	\N	3283	1	standalone	2026-06-21 05:44:32.221861
34336	1332	\N	\N	2987	1	standalone	2026-06-21 05:44:32.238548
34337	1332	\N	\N	3116	1	standalone	2026-06-21 05:44:32.238548
34338	1332	\N	\N	622	1	standalone	2026-06-21 05:44:32.238548
34339	1332	\N	\N	1587	1	standalone	2026-06-21 05:44:32.238548
34464	1322	\N	\N	1367	1	domain	2026-06-21 05:44:32.453087
34492	1322	\N	\N	682	1	domain	2026-06-21 05:44:32.491539
34448	1334	\N	\N	143	1	domain	2026-06-21 05:44:32.39342
38197	1388	\N	\N	959	1	standalone	2026-06-21 08:57:51.058088
38198	1391	\N	\N	960	1	standalone	2026-06-21 08:57:51.06209
38199	1388	\N	\N	961	1	standalone	2026-06-21 08:57:51.06209
38200	1392	\N	\N	962	1	standalone	2026-06-21 08:57:51.063088
38201	1392	\N	\N	963	1	standalone	2026-06-21 08:57:51.063088
38202	1392	\N	\N	964	1	standalone	2026-06-21 08:57:51.063088
38203	1393	\N	\N	965	1	standalone	2026-06-21 08:57:51.066087
38204	1392	\N	\N	966	1	standalone	2026-06-21 08:57:51.066087
34434	1334	\N	\N	1222	1	standalone	2026-06-21 05:44:32.376609
34435	1334	\N	\N	834	1	standalone	2026-06-21 05:44:32.376609
38205	1387	\N	\N	967	1	standalone	2026-06-21 08:57:51.066087
38206	1387	\N	\N	968	1	standalone	2026-06-21 08:57:51.066087
38207	1387	\N	\N	969	1	standalone	2026-06-21 08:57:51.066087
38208	1382	\N	\N	970	1	standalone	2026-06-21 08:57:51.066087
38209	1394	\N	\N	971	1	standalone	2026-06-21 08:57:51.068445
38210	1385	\N	\N	972	1	standalone	2026-06-21 08:57:51.068445
38211	1385	\N	\N	973	1	standalone	2026-06-21 08:57:51.068445
38212	1382	\N	\N	974	1	standalone	2026-06-21 08:57:51.068445
38213	1386	\N	\N	975	1	standalone	2026-06-21 08:57:51.068445
38214	1386	\N	\N	976	1	standalone	2026-06-21 08:57:51.068445
38215	1386	\N	\N	977	1	standalone	2026-06-21 08:57:51.068445
38216	1394	\N	\N	978	1	standalone	2026-06-21 08:57:51.068445
38217	1382	\N	\N	979	1	standalone	2026-06-21 08:57:51.068445
38218	1395	\N	\N	981	1	standalone	2026-06-21 08:57:51.072449
38219	1395	\N	\N	982	1	standalone	2026-06-21 08:57:51.072449
38220	1396	\N	\N	983	1	standalone	2026-06-21 08:57:51.076444
38221	1395	\N	\N	984	1	standalone	2026-06-21 08:57:51.076444
38222	1388	\N	\N	985	1	standalone	2026-06-21 08:57:51.076444
38223	1386	\N	\N	986	1	standalone	2026-06-21 08:57:51.076444
38224	1397	\N	\N	987	1	standalone	2026-06-21 08:57:51.078844
38225	1387	\N	\N	988	1	standalone	2026-06-21 08:57:51.078844
38226	1398	\N	\N	989	1	standalone	2026-06-21 08:57:51.082823
38227	1398	\N	\N	990	1	standalone	2026-06-21 08:57:51.082823
38228	1398	\N	\N	991	1	standalone	2026-06-21 08:57:51.082823
38229	1398	\N	\N	992	1	standalone	2026-06-21 08:57:51.082823
38230	1398	\N	\N	993	1	standalone	2026-06-21 08:57:51.082823
38231	1398	\N	\N	994	1	standalone	2026-06-21 08:57:51.082823
38232	1398	\N	\N	995	1	standalone	2026-06-21 08:57:51.082823
38233	1398	\N	\N	996	1	standalone	2026-06-21 08:57:51.082823
38234	1383	\N	\N	997	1	standalone	2026-06-21 08:57:51.082823
34471	1322	\N	\N	2638	1	standalone	2026-06-21 05:44:32.458243
34472	1322	\N	\N	2639	1	standalone	2026-06-21 05:44:32.458243
38235	1383	\N	\N	998	1	standalone	2026-06-21 08:57:51.082823
38236	1398	\N	\N	999	1	standalone	2026-06-21 08:57:51.082823
34479	1322	\N	\N	1188	1	standalone	2026-06-21 05:44:32.474886
34480	1322	\N	\N	1189	1	standalone	2026-06-21 05:44:32.474886
34481	1322	\N	\N	1190	1	standalone	2026-06-21 05:44:32.474886
34482	1322	\N	\N	2966	1	standalone	2026-06-21 05:44:32.474886
34483	1322	\N	\N	2412	1	standalone	2026-06-21 05:44:32.474886
34484	1322	\N	\N	2509	1	standalone	2026-06-21 05:44:32.474886
34485	1322	\N	\N	2526	1	standalone	2026-06-21 05:44:32.474886
34486	1322	\N	\N	2490	1	standalone	2026-06-21 05:44:32.474886
34487	1322	\N	\N	2530	1	standalone	2026-06-21 05:44:32.474886
38237	1398	\N	\N	1000	1	standalone	2026-06-21 08:57:51.082823
38238	1383	\N	\N	1001	1	standalone	2026-06-21 08:57:51.082823
38239	1386	\N	\N	1002	1	standalone	2026-06-21 08:57:51.082823
38240	1386	\N	\N	1003	1	standalone	2026-06-21 08:57:51.082823
38241	1388	\N	\N	1004	1	standalone	2026-06-21 08:57:51.082823
38242	1388	\N	\N	1005	1	standalone	2026-06-21 08:57:51.082823
38243	1388	\N	\N	1006	1	standalone	2026-06-21 08:57:51.082823
38244	1391	\N	\N	1007	1	standalone	2026-06-21 08:57:51.082823
38245	1383	\N	\N	1008	1	standalone	2026-06-21 08:57:51.082823
38246	1397	\N	\N	1009	1	standalone	2026-06-21 08:57:51.082823
38247	1389	\N	\N	1010	1	standalone	2026-06-21 08:57:51.082823
38248	1393	\N	\N	1011	1	standalone	2026-06-21 08:57:51.082823
34523	1322	\N	\N	2305	1	standalone	2026-06-21 05:44:32.524103
34524	1322	\N	\N	2356	1	standalone	2026-06-21 05:44:32.524103
34526	1322	\N	\N	2401	1	standalone	2026-06-21 05:44:32.524103
34527	1322	\N	\N	2036	1	standalone	2026-06-21 05:44:32.524103
34528	1322	\N	\N	2037	1	standalone	2026-06-21 05:44:32.524103
34532	1322	\N	\N	449	1	standalone	2026-06-21 05:44:32.541462
34533	1322	\N	\N	2405	1	standalone	2026-06-21 05:44:32.541462
34461	1322	\N	\N	2637	1	standalone	2026-06-21 05:44:32.453087
34463	1322	\N	\N	476	1	standalone	2026-06-21 05:44:32.453087
34467	1322	\N	\N	608	1	standalone	2026-06-21 05:44:32.458243
34474	1322	\N	\N	970	1	standalone	2026-06-21 05:44:32.466392
34475	1322	\N	\N	1301	1	standalone	2026-06-21 05:44:32.466392
34477	1322	\N	\N	251	1	standalone	2026-06-21 05:44:32.474886
34478	1322	\N	\N	1314	1	standalone	2026-06-21 05:44:32.474886
34493	1322	\N	\N	1546	1	standalone	2026-06-21 05:44:32.491539
34496	1322	\N	\N	2735	1	standalone	2026-06-21 05:44:32.491539
34501	1322	\N	\N	3391	1	standalone	2026-06-21 05:44:32.491539
34503	1322	\N	\N	3114	1	standalone	2026-06-21 05:44:32.504628
34504	1322	\N	\N	3115	1	standalone	2026-06-21 05:44:32.504628
34505	1322	\N	\N	1151	1	standalone	2026-06-21 05:44:32.504628
34506	1322	\N	\N	2094	1	standalone	2026-06-21 05:44:32.504628
34507	1322	\N	\N	2910	1	standalone	2026-06-21 05:44:32.504628
34508	1322	\N	\N	2911	1	standalone	2026-06-21 05:44:32.504628
34509	1322	\N	\N	2912	1	standalone	2026-06-21 05:44:32.504628
34510	1322	\N	\N	2914	1	standalone	2026-06-21 05:44:32.504628
34511	1322	\N	\N	2131	1	standalone	2026-06-21 05:44:32.504628
34512	1322	\N	\N	2132	1	standalone	2026-06-21 05:44:32.504628
34513	1322	\N	\N	2469	1	standalone	2026-06-21 05:44:32.504628
34518	1322	\N	\N	3119	1	standalone	2026-06-21 05:44:32.524103
34519	1322	\N	\N	7016	1	standalone	2026-06-21 05:44:32.524103
34521	1322	\N	\N	2482	1	standalone	2026-06-21 05:44:32.524103
34535	1322	\N	\N	1568	1	standalone	2026-06-21 05:44:32.55625
34536	1322	\N	\N	629	1	standalone	2026-06-21 05:44:32.55625
34537	1322	\N	\N	2118	1	standalone	2026-06-21 05:44:32.55625
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
34650	1324	\N	\N	2729	1	domain	2026-06-21 05:44:32.652311
34565	1322	\N	\N	2656	1	standalone	2026-06-21 05:44:32.55625
34567	1322	\N	\N	2658	1	standalone	2026-06-21 05:44:32.55625
34568	1322	\N	\N	1114	1	standalone	2026-06-21 05:44:32.55625
34569	1322	\N	\N	2659	1	standalone	2026-06-21 05:44:32.55625
34570	1322	\N	\N	2892	1	standalone	2026-06-21 05:44:32.55625
34571	1322	\N	\N	2109	1	standalone	2026-06-21 05:44:32.55625
34572	1322	\N	\N	2158	1	standalone	2026-06-21 05:44:32.55625
34588	1329	\N	\N	3240	1	domain	2026-06-21 05:44:32.572038
34574	1322	\N	\N	2538	1	standalone	2026-06-21 05:44:32.55625
34595	1329	\N	\N	101	1	domain	2026-06-21 05:44:32.588116
34613	1331	\N	\N	2607	1	domain	2026-06-21 05:44:32.605341
34577	1327	\N	\N	3122	1	standalone	2026-06-21 05:44:32.55625
38249	1386	\N	\N	1012	1	standalone	2026-06-21 08:57:51.082823
38250	1386	\N	\N	1013	1	standalone	2026-06-21 08:57:51.082823
34581	1327	\N	\N	454	1	standalone	2026-06-21 05:44:32.55625
38251	1386	\N	\N	1014	1	standalone	2026-06-21 08:57:51.082823
34583	1327	\N	\N	547	1	standalone	2026-06-21 05:44:32.55625
34584	1327	\N	\N	2561	1	standalone	2026-06-21 05:44:32.55625
38252	1386	\N	\N	1015	1	standalone	2026-06-21 08:57:51.082823
38253	1385	\N	\N	1016	1	standalone	2026-06-21 08:57:51.082823
38254	1391	\N	\N	1017	1	standalone	2026-06-21 08:57:51.082823
38255	1391	\N	\N	1018	1	standalone	2026-06-21 08:57:51.082823
34594	1329	\N	\N	205	1	standalone	2026-06-21 05:44:32.588116
38256	1384	\N	\N	1019	1	standalone	2026-06-21 08:57:51.082823
38257	1388	\N	\N	1020	1	standalone	2026-06-21 08:57:51.082823
38258	1393	\N	\N	1021	1	standalone	2026-06-21 08:57:51.082823
34603	1331	\N	\N	913	1	standalone	2026-06-21 05:44:32.605341
38259	1397	\N	\N	1022	1	standalone	2026-06-21 08:57:51.082823
34605	1331	\N	\N	921	1	standalone	2026-06-21 05:44:32.605341
38260	1397	\N	\N	1023	1	standalone	2026-06-21 08:57:51.082823
38261	1397	\N	\N	1024	1	standalone	2026-06-21 08:57:51.082823
34608	1331	\N	\N	2805	1	standalone	2026-06-21 05:44:32.605341
34609	1331	\N	\N	2806	1	standalone	2026-06-21 05:44:32.605341
34610	1331	\N	\N	705	1	standalone	2026-06-21 05:44:32.605341
34611	1331	\N	\N	707	1	standalone	2026-06-21 05:44:32.605341
34612	1331	\N	\N	930	1	standalone	2026-06-21 05:44:32.605341
38262	1388	\N	\N	1025	1	standalone	2026-06-21 08:57:51.082823
34615	1331	\N	\N	2150	1	standalone	2026-06-21 05:44:32.605341
34616	1331	\N	\N	1639	1	standalone	2026-06-21 05:44:32.605341
34617	1331	\N	\N	1643	1	standalone	2026-06-21 05:44:32.605341
38263	1399	\N	\N	1026	1	standalone	2026-06-21 08:57:51.113187
38264	1390	\N	\N	1027	1	standalone	2026-06-21 08:57:51.113187
34620	1331	\N	\N	3247	1	standalone	2026-06-21 05:44:32.605341
34621	1331	\N	\N	2142	1	standalone	2026-06-21 05:44:32.605341
38265	1390	\N	\N	1028	1	standalone	2026-06-21 08:57:51.113187
38266	1390	\N	\N	1029	1	standalone	2026-06-21 08:57:51.113187
34624	1331	\N	\N	2214	1	standalone	2026-06-21 05:44:32.605341
34625	1331	\N	\N	3038	1	standalone	2026-06-21 05:44:32.605341
38267	1390	\N	\N	1030	1	standalone	2026-06-21 08:57:51.113187
34627	1331	\N	\N	3044	1	standalone	2026-06-21 05:44:32.605341
34628	1331	\N	\N	3052	1	standalone	2026-06-21 05:44:32.605341
34629	1331	\N	\N	3056	1	standalone	2026-06-21 05:44:32.605341
34630	1331	\N	\N	3065	1	standalone	2026-06-21 05:44:32.605341
34631	1331	\N	\N	3066	1	standalone	2026-06-21 05:44:32.605341
34632	1331	\N	\N	3068	1	standalone	2026-06-21 05:44:32.605341
38268	1390	\N	\N	1031	1	standalone	2026-06-21 08:57:51.113187
34634	1331	\N	\N	3071	1	standalone	2026-06-21 05:44:32.605341
38269	1392	\N	\N	1032	1	standalone	2026-06-21 08:57:51.113187
38270	1393	\N	\N	1033	1	standalone	2026-06-21 08:57:51.113187
38271	1393	\N	\N	1034	1	standalone	2026-06-21 08:57:51.113187
38272	1390	\N	\N	1035	1	standalone	2026-06-21 08:57:51.113187
34540	1322	\N	\N	3053	1	standalone	2026-06-21 05:44:32.55625
34541	1322	\N	\N	3082	1	standalone	2026-06-21 05:44:32.55625
34542	1322	\N	\N	2403	1	standalone	2026-06-21 05:44:32.55625
34543	1322	\N	\N	2551	1	standalone	2026-06-21 05:44:32.55625
34645	1324	\N	\N	1556	1	standalone	2026-06-21 05:44:32.652311
34649	1324	\N	\N	2678	1	standalone	2026-06-21 05:44:32.652311
34579	1327	\N	\N	724	1	standalone	2026-06-21 05:44:32.55625
34589	1329	\N	\N	2093	1	standalone	2026-06-21 05:44:32.572038
34591	1329	\N	\N	3272	1	standalone	2026-06-21 05:44:32.588116
34592	1329	\N	\N	1895	1	standalone	2026-06-21 05:44:32.588116
34593	1329	\N	\N	2358	1	standalone	2026-06-21 05:44:32.588116
34597	1329	\N	\N	642	1	standalone	2026-06-21 05:44:32.605341
34599	1329	\N	\N	3297	1	standalone	2026-06-21 05:44:32.605341
34601	1329	\N	\N	891	1	standalone	2026-06-21 05:44:32.605341
34602	1329	\N	\N	892	1	standalone	2026-06-21 05:44:32.605341
34554	1322	\N	\N	2070	1	domain	2026-06-21 05:44:32.55625
34564	1322	\N	\N	1108	1	domain	2026-06-21 05:44:32.55625
34566	1322	\N	\N	1113	1	domain	2026-06-21 05:44:32.55625
34636	1324	\N	\N	166	1	domain	2026-06-21 05:44:32.621305
34638	1324	\N	\N	695	1	domain	2026-06-21 05:44:32.621305
34639	1324	\N	\N	609	1	domain	2026-06-21 05:44:32.621305
34643	1324	\N	\N	2581	1	domain	2026-06-21 05:44:32.652311
34659	1324	\N	\N	2095	1	domain	2026-06-21 05:44:32.687403
34680	1324	\N	\N	1655	1	domain	2026-06-21 05:44:32.72199
34681	1324	\N	\N	2059	1	domain	2026-06-21 05:44:32.72199
34683	1324	\N	\N	3155	1	domain	2026-06-21 05:44:32.728285
38273	1391	\N	\N	1036	1	standalone	2026-06-21 08:57:51.113187
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
38274	1384	\N	\N	1075	1	standalone	2026-06-21 08:57:51.113187
38275	1384	\N	\N	1076	1	standalone	2026-06-21 08:57:51.113187
38276	1384	\N	\N	1077	1	standalone	2026-06-21 08:57:51.113187
38277	1384	\N	\N	1085	1	standalone	2026-06-21 08:57:51.113187
38278	1384	\N	\N	1038	1	standalone	2026-06-21 08:57:51.113187
34688	1324	\N	\N	2291	1	standalone	2026-06-21 05:44:32.728285
34689	1324	\N	\N	2297	1	standalone	2026-06-21 05:44:32.728285
34690	1324	\N	\N	2382	1	standalone	2026-06-21 05:44:32.728285
34691	1324	\N	\N	6	1	standalone	2026-06-21 05:44:32.728285
34692	1324	\N	\N	2887	1	standalone	2026-06-21 05:44:32.728285
34693	1324	\N	\N	2274	1	standalone	2026-06-21 05:44:32.728285
38279	1396	\N	\N	1052	1	standalone	2026-06-21 08:57:51.113187
38280	1390	\N	\N	1086	1	standalone	2026-06-21 08:57:51.113187
38281	1390	\N	\N	1101	1	standalone	2026-06-21 08:57:51.113187
38282	1382	\N	\N	1037	1	standalone	2026-06-21 08:57:51.113187
38283	1382	\N	\N	1039	1	standalone	2026-06-21 08:57:51.113187
38284	1382	\N	\N	1040	1	standalone	2026-06-21 08:57:51.113187
38285	1382	\N	\N	1041	1	standalone	2026-06-21 08:57:51.113187
38286	1382	\N	\N	1042	1	standalone	2026-06-21 08:57:51.113187
38287	1382	\N	\N	1053	1	standalone	2026-06-21 08:57:51.113187
38288	1382	\N	\N	1043	1	standalone	2026-06-21 08:57:51.113187
38289	1382	\N	\N	1044	1	standalone	2026-06-21 08:57:51.113187
38290	1382	\N	\N	1045	1	standalone	2026-06-21 08:57:51.113187
38291	1382	\N	\N	1046	1	standalone	2026-06-21 08:57:51.113187
38292	1382	\N	\N	1054	1	standalone	2026-06-21 08:57:51.113187
38293	1382	\N	\N	1047	1	standalone	2026-06-21 08:57:51.113187
38294	1382	\N	\N	1048	1	standalone	2026-06-21 08:57:51.113187
38295	1393	\N	\N	1049	1	standalone	2026-06-21 08:57:51.113187
38296	1384	\N	\N	1050	1	standalone	2026-06-21 08:57:51.113187
38297	1396	\N	\N	1051	1	standalone	2026-06-21 08:57:51.113187
38298	1384	\N	\N	1057	1	standalone	2026-06-21 08:57:51.113187
38299	1384	\N	\N	1058	1	standalone	2026-06-21 08:57:51.113187
38300	1384	\N	\N	1059	1	standalone	2026-06-21 08:57:51.113187
38301	1384	\N	\N	1060	1	standalone	2026-06-21 08:57:51.113187
38302	1384	\N	\N	1061	1	standalone	2026-06-21 08:57:51.113187
38303	1394	\N	\N	1062	1	standalone	2026-06-21 08:57:51.113187
38304	1394	\N	\N	1063	1	standalone	2026-06-21 08:57:51.113187
38305	1394	\N	\N	1064	1	standalone	2026-06-21 08:57:51.113187
38306	1394	\N	\N	1065	1	standalone	2026-06-21 08:57:51.113187
38307	1394	\N	\N	1066	1	standalone	2026-06-21 08:57:51.113187
38308	1394	\N	\N	1068	1	standalone	2026-06-21 08:57:51.113187
38309	1382	\N	\N	1069	1	standalone	2026-06-21 08:57:51.113187
38310	1382	\N	\N	1070	1	standalone	2026-06-21 08:57:51.113187
38311	1382	\N	\N	1071	1	standalone	2026-06-21 08:57:51.113187
34727	1327	\N	\N	757	1	standalone	2026-06-21 05:44:32.760826
38312	1395	\N	\N	1072	1	standalone	2026-06-21 08:57:51.113187
38313	1382	\N	\N	1073	1	standalone	2026-06-21 08:57:51.113187
38314	1395	\N	\N	1074	1	standalone	2026-06-21 08:57:51.113187
38315	1395	\N	\N	1078	1	standalone	2026-06-21 08:57:51.113187
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
38316	1394	\N	\N	1079	1	standalone	2026-06-21 08:57:51.113187
38317	1394	\N	\N	1080	1	standalone	2026-06-21 08:57:51.113187
38318	1394	\N	\N	1081	1	standalone	2026-06-21 08:57:51.113187
38319	1394	\N	\N	1082	1	standalone	2026-06-21 08:57:51.113187
38320	1382	\N	\N	1083	1	standalone	2026-06-21 08:57:51.113187
34762	1335	\N	\N	1170	1	standalone	2026-06-21 05:44:32.811257
34763	1335	\N	\N	1171	1	standalone	2026-06-21 05:44:32.811257
34764	1335	\N	\N	332	1	standalone	2026-06-21 05:44:32.811257
34743	1322	\N	\N	2842	1	standalone	2026-06-21 05:44:32.790749
34744	1322	\N	\N	2845	1	standalone	2026-06-21 05:44:32.790749
34745	1322	\N	\N	356	1	standalone	2026-06-21 05:44:32.790749
34746	1322	\N	\N	2846	1	standalone	2026-06-21 05:44:32.790749
34747	1322	\N	\N	2862	1	standalone	2026-06-21 05:44:32.790749
34652	1324	\N	\N	1609	1	standalone	2026-06-21 05:44:32.667451
34653	1324	\N	\N	1557	1	standalone	2026-06-21 05:44:32.667451
34654	1324	\N	\N	1831	1	standalone	2026-06-21 05:44:32.667451
34655	1324	\N	\N	315	1	standalone	2026-06-21 05:44:32.667451
34657	1324	\N	\N	7	1	standalone	2026-06-21 05:44:32.687403
34658	1324	\N	\N	696	1	standalone	2026-06-21 05:44:32.687403
34660	1324	\N	\N	2096	1	standalone	2026-06-21 05:44:32.687403
34663	1324	\N	\N	1610	1	standalone	2026-06-21 05:44:32.706746
34664	1324	\N	\N	2101	1	standalone	2026-06-21 05:44:32.706746
34665	1324	\N	\N	452	1	standalone	2026-06-21 05:44:32.706746
34684	1324	\N	\N	1336	1	standalone	2026-06-21 05:44:32.728285
34765	1335	\N	\N	1027	1	standalone	2026-06-21 05:44:32.811257
34766	1336	\N	\N	1860	1	standalone	2026-06-21 05:44:32.820671
34767	1336	\N	\N	1867	1	standalone	2026-06-21 05:44:32.820671
34844	1327	\N	\N	1596	1	domain	2026-06-21 05:44:32.928014
34852	1327	\N	\N	2166	1	domain	2026-06-21 05:44:32.93927
34853	1327	\N	\N	3351	1	domain	2026-06-21 05:44:32.93927
34859	1327	\N	\N	1199	1	domain	2026-06-21 05:44:32.93927
34775	1336	\N	\N	1841	1	domain	2026-06-21 05:44:32.845197
34773	1336	\N	\N	1866	1	standalone	2026-06-21 05:44:32.829587
34803	1336	\N	\N	1275	1	domain	2026-06-21 05:44:32.878253
34777	1336	\N	\N	1877	1	standalone	2026-06-21 05:44:32.845197
34778	1336	\N	\N	1878	1	standalone	2026-06-21 05:44:32.845197
34779	1336	\N	\N	1879	1	standalone	2026-06-21 05:44:32.845197
34780	1336	\N	\N	1883	1	standalone	2026-06-21 05:44:32.845197
34781	1336	\N	\N	1664	1	standalone	2026-06-21 05:44:32.845197
34782	1336	\N	\N	1884	1	standalone	2026-06-21 05:44:32.845197
34783	1336	\N	\N	1411	1	standalone	2026-06-21 05:44:32.845197
34809	1336	\N	\N	3374	1	domain	2026-06-21 05:44:32.878253
38321	1390	\N	\N	1084	1	standalone	2026-06-21 08:57:51.113187
38322	1390	\N	\N	1087	1	standalone	2026-06-21 08:57:51.113187
34787	1336	\N	\N	224	1	standalone	2026-06-21 05:44:32.855475
34788	1336	\N	\N	225	1	standalone	2026-06-21 05:44:32.855475
34789	1336	\N	\N	379	1	standalone	2026-06-21 05:44:32.855475
38323	1384	\N	\N	1088	1	standalone	2026-06-21 08:57:51.113187
34793	1336	\N	\N	232	1	standalone	2026-06-21 05:44:32.861559
34794	1336	\N	\N	1629	1	standalone	2026-06-21 05:44:32.861559
34795	1336	\N	\N	1634	1	standalone	2026-06-21 05:44:32.861559
38324	1384	\N	\N	1089	1	standalone	2026-06-21 08:57:51.113187
38325	1384	\N	\N	1090	1	standalone	2026-06-21 08:57:51.113187
38326	1391	\N	\N	1091	1	standalone	2026-06-21 08:57:51.113187
34799	1336	\N	\N	1187	1	standalone	2026-06-21 05:44:32.864891
38327	1384	\N	\N	1092	1	standalone	2026-06-21 08:57:51.113187
38328	1384	\N	\N	1093	1	standalone	2026-06-21 08:57:51.113187
38329	1384	\N	\N	1094	1	standalone	2026-06-21 08:57:51.113187
34804	1336	\N	\N	1276	1	standalone	2026-06-21 05:44:32.878253
34805	1336	\N	\N	2362	1	standalone	2026-06-21 05:44:32.878253
34806	1336	\N	\N	2366	1	standalone	2026-06-21 05:44:32.878253
34807	1336	\N	\N	2370	1	standalone	2026-06-21 05:44:32.878253
38330	1384	\N	\N	1095	1	standalone	2026-06-21 08:57:51.113187
38331	1384	\N	\N	1096	1	standalone	2026-06-21 08:57:51.113187
38332	1384	\N	\N	1097	1	standalone	2026-06-21 08:57:51.113187
38333	1384	\N	\N	1098	1	standalone	2026-06-21 08:57:51.113187
38334	1387	\N	\N	1099	1	standalone	2026-06-21 08:57:51.113187
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
38335	1384	\N	\N	1100	1	standalone	2026-06-21 08:57:51.113187
38336	1384	\N	\N	1102	1	standalone	2026-06-21 08:57:51.113187
38337	1384	\N	\N	1103	1	standalone	2026-06-21 08:57:51.113187
38338	1384	\N	\N	1104	1	standalone	2026-06-21 08:57:51.113187
38339	1392	\N	\N	1105	1	standalone	2026-06-21 08:57:51.113187
38340	1384	\N	\N	1106	1	standalone	2026-06-21 08:57:51.113187
34854	1327	\N	\N	3353	1	standalone	2026-06-21 05:44:32.93927
34855	1327	\N	\N	3352	1	standalone	2026-06-21 05:44:32.93927
34856	1327	\N	\N	3220	1	standalone	2026-06-21 05:44:32.93927
34857	1327	\N	\N	1937	1	standalone	2026-06-21 05:44:32.93927
34858	1327	\N	\N	89	1	standalone	2026-06-21 05:44:32.93927
34848	1327	\N	\N	2245	1	standalone	2026-06-21 05:44:32.928014
34849	1327	\N	\N	2250	1	standalone	2026-06-21 05:44:32.928014
34776	1336	\N	\N	1882	1	standalone	2026-06-21 05:44:32.845197
34791	1336	\N	\N	3346	1	standalone	2026-06-21 05:44:32.861559
34792	1336	\N	\N	1033	1	standalone	2026-06-21 05:44:32.861559
34810	1336	\N	\N	3331	1	standalone	2026-06-21 05:44:32.878253
34811	1336	\N	\N	2925	1	standalone	2026-06-21 05:44:32.878253
34902	1322	\N	\N	2125	1	domain	2026-06-21 05:44:32.975306
34922	1322	\N	\N	1126	1	domain	2026-06-21 05:44:32.991288
34866	1322	\N	\N	1742	1	standalone	2026-06-21 05:44:32.958835
34868	1322	\N	\N	353	1	standalone	2026-06-21 05:44:32.958835
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
34944	1322	\N	\N	2640	1	standalone	2026-06-21 05:44:32.991288
34945	1322	\N	\N	2609	1	standalone	2026-06-21 05:44:32.991288
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
34920	1322	\N	\N	169	1	standalone	2026-06-21 05:44:32.991288
34921	1322	\N	\N	586	1	standalone	2026-06-21 05:44:32.991288
34861	1327	\N	\N	2074	1	standalone	2026-06-21 05:44:32.950479
34862	1327	\N	\N	1881	1	standalone	2026-06-21 05:44:32.950479
34876	1322	\N	\N	1129	1	domain	2026-06-21 05:44:32.975306
34871	1322	\N	\N	168	1	domain	2026-06-21 05:44:32.975306
34872	1322	\N	\N	2582	1	domain	2026-06-21 05:44:32.975306
34864	1334	\N	\N	3182	1	domain	2026-06-21 05:44:32.958835
34865	1334	\N	\N	799	1	domain	2026-06-21 05:44:32.958835
34966	1322	\N	\N	1532	1	standalone	2026-06-21 05:44:32.991288
34967	1322	\N	\N	1363	1	standalone	2026-06-21 05:44:32.991288
35038	1330	\N	\N	2927	1	domain	2026-06-21 05:44:33.08332
34969	1322	\N	\N	2044	1	standalone	2026-06-21 05:44:32.991288
34970	1322	\N	\N	2053	1	standalone	2026-06-21 05:44:32.991288
35039	1330	\N	\N	1294	1	domain	2026-06-21 05:44:33.08332
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
35060	1330	\N	\N	262	1	standalone	2026-06-21 05:44:33.122004
35061	1330	\N	\N	263	1	standalone	2026-06-21 05:44:33.122004
35062	1330	\N	\N	264	1	standalone	2026-06-21 05:44:33.122004
35063	1330	\N	\N	301	1	standalone	2026-06-21 05:44:33.122004
35016	1330	\N	\N	2369	1	standalone	2026-06-21 05:44:33.047059
35017	1330	\N	\N	2374	1	standalone	2026-06-21 05:44:33.047059
35015	1330	\N	\N	2308	1	standalone	2026-06-21 05:44:33.047059
35012	1330	\N	\N	2198	1	standalone	2026-06-21 05:44:33.047059
35011	1330	\N	\N	2307	1	standalone	2026-06-21 05:44:33.047059
34978	1327	\N	\N	3369	1	standalone	2026-06-21 05:44:33.023718
34982	1327	\N	\N	239	1	standalone	2026-06-21 05:44:33.023718
35019	1330	\N	\N	685	1	standalone	2026-06-21 05:44:33.057224
35020	1330	\N	\N	3154	1	standalone	2026-06-21 05:44:33.057224
35021	1330	\N	\N	457	1	standalone	2026-06-21 05:44:33.057224
35022	1330	\N	\N	574	1	standalone	2026-06-21 05:44:33.057224
35025	1330	\N	\N	1616	1	standalone	2026-06-21 05:44:33.070648
35026	1330	\N	\N	1617	1	standalone	2026-06-21 05:44:33.070648
35027	1330	\N	\N	1620	1	standalone	2026-06-21 05:44:33.070648
35028	1330	\N	\N	2005	1	standalone	2026-06-21 05:44:33.070648
35029	1330	\N	\N	2007	1	standalone	2026-06-21 05:44:33.070648
35030	1330	\N	\N	2302	1	standalone	2026-06-21 05:44:33.070648
35041	1330	\N	\N	1613	1	standalone	2026-06-21 05:44:33.093566
35042	1330	\N	\N	1621	1	standalone	2026-06-21 05:44:33.093566
35073	1330	\N	\N	1339	1	domain	2026-06-21 05:44:33.144385
35080	1330	\N	\N	858	1	standalone	2026-06-21 05:44:33.156534
35081	1330	\N	\N	571	1	standalone	2026-06-21 05:44:33.156534
35082	1330	\N	\N	2275	1	standalone	2026-06-21 05:44:33.156534
35074	1330	\N	\N	3081	1	domain	2026-06-21 05:44:33.144385
35129	1336	\N	\N	3327	1	domain	2026-06-21 05:44:33.211909
35130	1336	\N	\N	1195	1	domain	2026-06-21 05:44:33.211909
35119	1336	\N	\N	1861	1	standalone	2026-06-21 05:44:33.195407
35120	1336	\N	\N	1886	1	standalone	2026-06-21 05:44:33.195407
35121	1336	\N	\N	1887	1	standalone	2026-06-21 05:44:33.195407
35122	1336	\N	\N	2163	1	standalone	2026-06-21 05:44:33.195407
35126	1336	\N	\N	3325	1	standalone	2026-06-21 05:44:33.211909
35127	1336	\N	\N	3326	1	standalone	2026-06-21 05:44:33.211909
35152	1336	\N	\N	374	1	standalone	2026-06-21 05:44:33.244994
35153	1336	\N	\N	375	1	standalone	2026-06-21 05:44:33.244994
35154	1336	\N	\N	376	1	standalone	2026-06-21 05:44:33.244994
35166	1336	\N	\N	1196	1	standalone	2026-06-21 05:44:33.276232
35173	1336	\N	\N	2165	1	standalone	2026-06-21 05:44:33.292264
35174	1336	\N	\N	2489	1	standalone	2026-06-21 05:44:33.292264
35175	1336	\N	\N	2499	1	standalone	2026-06-21 05:44:33.292264
35177	1336	\N	\N	87	1	standalone	2026-06-21 05:44:33.292264
35181	1336	\N	\N	2368	1	standalone	2026-06-21 05:44:33.292264
35182	1336	\N	\N	2391	1	standalone	2026-06-21 05:44:33.292264
35183	1336	\N	\N	2392	1	standalone	2026-06-21 05:44:33.292264
35184	1336	\N	\N	2393	1	standalone	2026-06-21 05:44:33.292264
35185	1336	\N	\N	2171	1	standalone	2026-06-21 05:44:33.292264
35072	1330	\N	\N	519	1	standalone	2026-06-21 05:44:33.144385
35075	1330	\N	\N	3083	1	standalone	2026-06-21 05:44:33.144385
35077	1330	\N	\N	857	1	standalone	2026-06-21 05:44:33.156534
35078	1330	\N	\N	2258	1	standalone	2026-06-21 05:44:33.156534
35079	1330	\N	\N	2270	1	standalone	2026-06-21 05:44:33.156534
35084	1330	\N	\N	223	1	standalone	2026-06-21 05:44:33.176383
35085	1330	\N	\N	1618	1	standalone	2026-06-21 05:44:33.176383
35088	1330	\N	\N	257	1	standalone	2026-06-21 05:44:33.176383
35089	1330	\N	\N	1919	1	standalone	2026-06-21 05:44:33.176383
35090	1330	\N	\N	258	1	standalone	2026-06-21 05:44:33.176383
35092	1330	\N	\N	267	1	standalone	2026-06-21 05:44:33.176383
35094	1330	\N	\N	1017	1	standalone	2026-06-21 05:44:33.176383
35099	1330	\N	\N	1999	1	standalone	2026-06-21 05:44:33.176383
35100	1330	\N	\N	2196	1	standalone	2026-06-21 05:44:33.176383
35101	1330	\N	\N	2199	1	standalone	2026-06-21 05:44:33.176383
35111	1335	\N	\N	1179	1	standalone	2026-06-21 05:44:33.195407
35112	1335	\N	\N	1180	1	standalone	2026-06-21 05:44:33.195407
35113	1335	\N	\N	1181	1	standalone	2026-06-21 05:44:33.195407
35114	1335	\N	\N	2691	1	standalone	2026-06-21 05:44:33.195407
35115	1335	\N	\N	1174	1	standalone	2026-06-21 05:44:33.195407
35116	1335	\N	\N	1175	1	standalone	2026-06-21 05:44:33.195407
35117	1335	\N	\N	1176	1	standalone	2026-06-21 05:44:33.195407
35118	1335	\N	\N	1177	1	standalone	2026-06-21 05:44:33.195407
35135	1336	\N	\N	3330	1	standalone	2026-06-21 05:44:33.22824
35240	1327	\N	\N	690	1	domain	2026-06-21 05:44:33.37844
35244	1327	\N	\N	1692	1	domain	2026-06-21 05:44:33.37844
35248	1327	\N	\N	567	1	domain	2026-06-21 05:44:33.37844
35257	1329	\N	\N	894	1	domain	2026-06-21 05:44:33.395405
35253	1329	\N	\N	213	1	domain	2026-06-21 05:44:33.395405
35256	1329	\N	\N	1732	1	domain	2026-06-21 05:44:33.395405
35265	1337	\N	\N	3378	1	domain	2026-06-21 05:44:33.426632
35296	1337	\N	\N	1704	1	domain	2026-06-21 05:44:33.475768
35301	1337	\N	\N	2783	1	domain	2026-06-21 05:44:33.475768
35236	1325	\N	\N	3193	1	standalone	2026-06-21 05:44:33.362252
35237	1325	\N	\N	2679	1	standalone	2026-06-21 05:44:33.362252
35246	1327	\N	\N	985	1	standalone	2026-06-21 05:44:33.37844
35247	1327	\N	\N	528	1	standalone	2026-06-21 05:44:33.37844
35249	1327	\N	\N	585	1	standalone	2026-06-21 05:44:33.37844
35250	1327	\N	\N	2474	1	standalone	2026-06-21 05:44:33.37844
35263	1337	\N	\N	1838	1	standalone	2026-06-21 05:44:33.406274
35276	1337	\N	\N	1820	1	standalone	2026-06-21 05:44:33.451241
35277	1337	\N	\N	250	1	standalone	2026-06-21 05:44:33.451241
35278	1337	\N	\N	2909	1	standalone	2026-06-21 05:44:33.451241
35286	1337	\N	\N	1166	1	standalone	2026-06-21 05:44:33.459568
35288	1337	\N	\N	2945	1	standalone	2026-06-21 05:44:33.459568
35297	1337	\N	\N	324	1	standalone	2026-06-21 05:44:33.475768
35298	1337	\N	\N	325	1	standalone	2026-06-21 05:44:33.475768
35299	1337	\N	\N	2024	1	standalone	2026-06-21 05:44:33.475768
35300	1337	\N	\N	2782	1	standalone	2026-06-21 05:44:33.475768
35303	1337	\N	\N	1303	1	standalone	2026-06-21 05:44:33.475768
35304	1337	\N	\N	2341	1	standalone	2026-06-21 05:44:33.475768
35305	1337	\N	\N	2411	1	standalone	2026-06-21 05:44:33.475768
35228	1325	\N	\N	684	1	standalone	2026-06-21 05:44:33.355671
35231	1325	\N	\N	557	1	standalone	2026-06-21 05:44:33.355671
35234	1325	\N	\N	2087	1	standalone	2026-06-21 05:44:33.362252
35239	1327	\N	\N	3317	1	standalone	2026-06-21 05:44:33.37844
35241	1327	\N	\N	178	1	standalone	2026-06-21 05:44:33.37844
35242	1327	\N	\N	2681	1	standalone	2026-06-21 05:44:33.37844
35243	1327	\N	\N	1957	1	standalone	2026-06-21 05:44:33.37844
35252	1329	\N	\N	644	1	standalone	2026-06-21 05:44:33.395405
35254	1329	\N	\N	1890	1	standalone	2026-06-21 05:44:33.395405
35202	1336	\N	\N	1934	1	standalone	2026-06-21 05:44:33.328484
35221	1336	\N	\N	3021	1	standalone	2026-06-21 05:44:33.328484
35261	1337	\N	\N	3373	1	standalone	2026-06-21 05:44:33.406274
35262	1337	\N	\N	1930	1	standalone	2026-06-21 05:44:33.406274
35266	1337	\N	\N	254	1	standalone	2026-06-21 05:44:33.426632
35267	1337	\N	\N	255	1	standalone	2026-06-21 05:44:33.426632
35268	1337	\N	\N	2019	1	standalone	2026-06-21 05:44:33.426632
35269	1337	\N	\N	2020	1	standalone	2026-06-21 05:44:33.426632
35271	1337	\N	\N	1554	1	standalone	2026-06-21 05:44:33.437269
35272	1337	\N	\N	2762	1	standalone	2026-06-21 05:44:33.437269
35283	1337	\N	\N	3242	1	standalone	2026-06-21 05:44:33.459568
35290	1337	\N	\N	2947	1	standalone	2026-06-21 05:44:33.475768
35291	1337	\N	\N	2022	1	standalone	2026-06-21 05:44:33.475768
35292	1337	\N	\N	2023	1	standalone	2026-06-21 05:44:33.475768
35293	1337	\N	\N	2303	1	standalone	2026-06-21 05:44:33.475768
35294	1337	\N	\N	2408	1	standalone	2026-06-21 05:44:33.475768
35245	1327	\N	\N	3195	1	domain	2026-06-21 05:44:33.37844
35287	1337	\N	\N	102	1	domain	2026-06-21 05:44:33.459568
35302	1337	\N	\N	1302	1	domain	2026-06-21 05:44:33.475768
35229	1325	\N	\N	779	1	domain	2026-06-21 05:44:33.355671
35230	1325	\N	\N	984	1	domain	2026-06-21 05:44:33.355671
35233	1325	\N	\N	8	1	domain	2026-06-21 05:44:33.362252
35224	1334	\N	\N	3183	1	domain	2026-06-21 05:44:33.345148
35225	1334	\N	\N	832	1	domain	2026-06-21 05:44:33.345148
35189	1336	\N	\N	184	1	domain	2026-06-21 05:44:33.328484
35376	1327	\N	\N	752	1	domain	2026-06-21 05:44:33.581816
35399	1327	\N	\N	1722	1	domain	2026-06-21 05:44:33.623313
35405	1327	\N	\N	1330	1	domain	2026-06-21 05:44:33.623313
35309	1330	\N	\N	2626	1	standalone	2026-06-21 05:44:33.475768
35310	1330	\N	\N	2646	1	standalone	2026-06-21 05:44:33.475768
35311	1330	\N	\N	2671	1	standalone	2026-06-21 05:44:33.475768
35312	1330	\N	\N	2744	1	standalone	2026-06-21 05:44:33.475768
35313	1330	\N	\N	2736	1	standalone	2026-06-21 05:44:33.475768
35319	1330	\N	\N	1844	1	domain	2026-06-21 05:44:33.491735
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
35380	1327	\N	\N	754	1	standalone	2026-06-21 05:44:33.581816
35386	1327	\N	\N	237	1	standalone	2026-06-21 05:44:33.590075
35387	1327	\N	\N	1965	1	standalone	2026-06-21 05:44:33.590075
35388	1327	\N	\N	1967	1	standalone	2026-06-21 05:44:33.590075
35392	1327	\N	\N	1977	1	standalone	2026-06-21 05:44:33.590075
35396	1327	\N	\N	548	1	standalone	2026-06-21 05:44:33.606617
35397	1327	\N	\N	2264	1	standalone	2026-06-21 05:44:33.606617
35382	1327	\N	\N	3320	1	standalone	2026-06-21 05:44:33.590075
35384	1327	\N	\N	1966	1	standalone	2026-06-21 05:44:33.590075
35390	1327	\N	\N	1969	1	standalone	2026-06-21 05:44:33.590075
35391	1327	\N	\N	2265	1	standalone	2026-06-21 05:44:33.590075
35394	1327	\N	\N	1978	1	standalone	2026-06-21 05:44:33.606617
35395	1327	\N	\N	2443	1	standalone	2026-06-21 05:44:33.606617
35400	1327	\N	\N	768	1	standalone	2026-06-21 05:44:33.623313
35402	1327	\N	\N	226	1	standalone	2026-06-21 05:44:33.623313
35403	1327	\N	\N	726	1	standalone	2026-06-21 05:44:33.623313
35315	1330	\N	\N	1744	1	standalone	2026-06-21 05:44:33.491735
35316	1330	\N	\N	2648	1	standalone	2026-06-21 05:44:33.491735
35318	1330	\N	\N	1843	1	standalone	2026-06-21 05:44:33.491735
35320	1330	\N	\N	3274	1	standalone	2026-06-21 05:44:33.491735
35321	1330	\N	\N	3275	1	standalone	2026-06-21 05:44:33.491735
35323	1330	\N	\N	296	1	standalone	2026-06-21 05:44:33.491735
35324	1330	\N	\N	306	1	standalone	2026-06-21 05:44:33.491735
35326	1330	\N	\N	1847	1	standalone	2026-06-21 05:44:33.51099
35327	1330	\N	\N	2698	1	standalone	2026-06-21 05:44:33.51099
35330	1330	\N	\N	2428	1	standalone	2026-06-21 05:44:33.51099
35425	1338	\N	\N	152	1	domain	2026-06-21 05:44:33.664968
35426	1338	\N	\N	2455	1	standalone	2026-06-21 05:44:33.664968
35427	1338	\N	\N	2175	1	standalone	2026-06-21 05:44:33.664968
35428	1338	\N	\N	2207	1	standalone	2026-06-21 05:44:33.664968
35458	1338	\N	\N	1542	1	domain	2026-06-21 05:44:33.713754
35438	1338	\N	\N	3229	1	domain	2026-06-21 05:44:33.687298
35443	1338	\N	\N	153	1	domain	2026-06-21 05:44:33.687298
35455	1338	\N	\N	3228	1	domain	2026-06-21 05:44:33.713754
35456	1338	\N	\N	2903	1	domain	2026-06-21 05:44:33.713754
35442	1338	\N	\N	1205	1	standalone	2026-06-21 05:44:33.687298
35450	1338	\N	\N	2143	1	standalone	2026-06-21 05:44:33.695541
35465	1329	\N	\N	3395	1	standalone	2026-06-21 05:44:33.713754
35466	1329	\N	\N	1619	1	standalone	2026-06-21 05:44:33.713754
35469	1329	\N	\N	3285	1	standalone	2026-06-21 05:44:33.713754
35470	1329	\N	\N	3286	1	standalone	2026-06-21 05:44:33.713754
35471	1329	\N	\N	3288	1	standalone	2026-06-21 05:44:33.713754
35472	1329	\N	\N	3289	1	standalone	2026-06-21 05:44:33.713754
35473	1329	\N	\N	729	1	standalone	2026-06-21 05:44:33.713754
35474	1329	\N	\N	3363	1	standalone	2026-06-21 05:44:33.713754
35424	1338	\N	\N	2176	1	standalone	2026-06-21 05:44:33.664968
35430	1338	\N	\N	2822	1	standalone	2026-06-21 05:44:33.670594
35431	1338	\N	\N	488	1	standalone	2026-06-21 05:44:33.670594
35432	1338	\N	\N	344	1	standalone	2026-06-21 05:44:33.670594
35433	1338	\N	\N	154	1	standalone	2026-06-21 05:44:33.670594
35439	1338	\N	\N	1209	1	standalone	2026-06-21 05:44:33.687298
35440	1338	\N	\N	1210	1	standalone	2026-06-21 05:44:33.687298
35441	1338	\N	\N	155	1	standalone	2026-06-21 05:44:33.687298
35445	1338	\N	\N	337	1	standalone	2026-06-21 05:44:33.695541
35446	1338	\N	\N	340	1	standalone	2026-06-21 05:44:33.695541
35447	1338	\N	\N	341	1	standalone	2026-06-21 05:44:33.695541
35449	1338	\N	\N	151	1	standalone	2026-06-21 05:44:33.695541
35452	1338	\N	\N	3337	1	standalone	2026-06-21 05:44:33.713754
35453	1338	\N	\N	968	1	standalone	2026-06-21 05:44:33.713754
35454	1338	\N	\N	969	1	standalone	2026-06-21 05:44:33.713754
35460	1338	\N	\N	2177	1	standalone	2026-06-21 05:44:33.713754
35464	1329	\N	\N	645	1	domain	2026-06-21 05:44:33.713754
35475	1329	\N	\N	733	1	domain	2026-06-21 05:44:33.713754
35550	1322	\N	\N	2652	1	standalone	2026-06-21 05:44:33.808149
35487	1329	\N	\N	572	1	standalone	2026-06-21 05:44:33.713754
35488	1329	\N	\N	1324	1	standalone	2026-06-21 05:44:33.713754
35489	1329	\N	\N	2326	1	standalone	2026-06-21 05:44:33.713754
35490	1329	\N	\N	2396	1	standalone	2026-06-21 05:44:33.713754
35491	1329	\N	\N	2453	1	standalone	2026-06-21 05:44:33.713754
35516	1323	\N	\N	218	1	standalone	2026-06-21 05:44:33.748322
35517	1323	\N	\N	1885	1	standalone	2026-06-21 05:44:33.748322
35518	1323	\N	\N	1178	1	standalone	2026-06-21 05:44:33.748322
35519	1323	\N	\N	2222	1	standalone	2026-06-21 05:44:33.748322
35497	1323	\N	\N	220	1	standalone	2026-06-21 05:44:33.727297
35502	1323	\N	\N	2441	1	standalone	2026-06-21 05:44:33.727297
35504	1323	\N	\N	219	1	standalone	2026-06-21 05:44:33.743468
35505	1323	\N	\N	2601	1	standalone	2026-06-21 05:44:33.743468
35506	1323	\N	\N	1909	1	standalone	2026-06-21 05:44:33.743468
35509	1323	\N	\N	1717	1	standalone	2026-06-21 05:44:33.743468
35510	1323	\N	\N	2932	1	standalone	2026-06-21 05:44:33.743468
35511	1323	\N	\N	2386	1	standalone	2026-06-21 05:44:33.743468
35514	1323	\N	\N	215	1	standalone	2026-06-21 05:44:33.748322
35515	1323	\N	\N	1262	1	standalone	2026-06-21 05:44:33.748322
35521	1323	\N	\N	3036	1	standalone	2026-06-21 05:44:33.760601
35553	1322	\N	\N	2657	1	standalone	2026-06-21 05:44:33.808149
35554	1322	\N	\N	2665	1	standalone	2026-06-21 05:44:33.808149
35555	1322	\N	\N	2664	1	standalone	2026-06-21 05:44:33.808149
35556	1322	\N	\N	2666	1	standalone	2026-06-21 05:44:33.808149
35557	1322	\N	\N	2643	1	standalone	2026-06-21 05:44:33.808149
35558	1322	\N	\N	2645	1	standalone	2026-06-21 05:44:33.808149
35559	1322	\N	\N	2633	1	standalone	2026-06-21 05:44:33.808149
35569	1322	\N	\N	2748	1	domain	2026-06-21 05:44:33.808149
35561	1322	\N	\N	2906	1	standalone	2026-06-21 05:44:33.808149
35562	1322	\N	\N	2933	1	standalone	2026-06-21 05:44:33.808149
35563	1322	\N	\N	2902	1	standalone	2026-06-21 05:44:33.808149
35564	1322	\N	\N	2738	1	standalone	2026-06-21 05:44:33.808149
35565	1322	\N	\N	2739	1	standalone	2026-06-21 05:44:33.808149
35566	1322	\N	\N	2741	1	standalone	2026-06-21 05:44:33.808149
35567	1322	\N	\N	2746	1	standalone	2026-06-21 05:44:33.808149
35568	1322	\N	\N	2747	1	standalone	2026-06-21 05:44:33.808149
35570	1322	\N	\N	2495	1	standalone	2026-06-21 05:44:33.808149
35571	1322	\N	\N	2496	1	standalone	2026-06-21 05:44:33.808149
35578	1322	\N	\N	2889	1	domain	2026-06-21 05:44:33.824865
35619	1329	\N	\N	901	1	domain	2026-06-21 05:44:33.824865
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
35620	1329	\N	\N	902	1	standalone	2026-06-21 05:44:33.824865
35621	1329	\N	\N	903	1	standalone	2026-06-21 05:44:33.824865
35622	1329	\N	\N	1516	1	standalone	2026-06-21 05:44:33.824865
35623	1329	\N	\N	2293	1	standalone	2026-06-21 05:44:33.824865
35624	1329	\N	\N	2390	1	standalone	2026-06-21 05:44:33.824865
35628	1329	\N	\N	7005	1	standalone	2026-06-21 05:44:33.853972
35629	1329	\N	\N	7007	1	standalone	2026-06-21 05:44:33.853972
35630	1329	\N	\N	7008	1	standalone	2026-06-21 05:44:33.853972
35631	1329	\N	\N	7015	1	standalone	2026-06-21 05:44:33.853972
35633	1329	\N	\N	674	1	standalone	2026-06-21 05:44:33.853972
35634	1329	\N	\N	677	1	standalone	2026-06-21 05:44:33.853972
35636	1329	\N	\N	673	1	standalone	2026-06-21 05:44:33.853972
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
35551	1322	\N	\N	2654	1	standalone	2026-06-21 05:44:33.808149
35552	1322	\N	\N	1685	1	standalone	2026-06-21 05:44:33.808149
35573	1322	\N	\N	368	1	standalone	2026-06-21 05:44:33.824865
35575	1322	\N	\N	164	1	standalone	2026-06-21 05:44:33.824865
35576	1322	\N	\N	2653	1	standalone	2026-06-21 05:44:33.824865
35577	1322	\N	\N	2655	1	standalone	2026-06-21 05:44:33.824865
35626	1329	\N	\N	7004	1	standalone	2026-06-21 05:44:33.853972
35627	1329	\N	\N	675	1	standalone	2026-06-21 05:44:33.853972
35640	1337	\N	\N	2140	1	standalone	2026-06-21 05:44:33.871348
35641	1337	\N	\N	2952	1	standalone	2026-06-21 05:44:33.871348
35642	1337	\N	\N	2776	1	standalone	2026-06-21 05:44:33.871348
35645	1337	\N	\N	2953	1	standalone	2026-06-21 05:44:33.886497
35646	1337	\N	\N	2954	1	standalone	2026-06-21 05:44:33.886497
35647	1337	\N	\N	1291	1	standalone	2026-06-21 05:44:33.886497
35661	1327	\N	\N	1954	1	standalone	2026-06-21 05:44:33.886497
35662	1327	\N	\N	1956	1	standalone	2026-06-21 05:44:33.886497
35664	1327	\N	\N	1959	1	standalone	2026-06-21 05:44:33.886497
35665	1327	\N	\N	1976	1	standalone	2026-06-21 05:44:33.886497
35666	1327	\N	\N	518	1	standalone	2026-06-21 05:44:33.886497
35667	1327	\N	\N	520	1	standalone	2026-06-21 05:44:33.886497
35678	1327	\N	\N	9	1	domain	2026-06-21 05:44:33.886497
35670	1327	\N	\N	550	1	standalone	2026-06-21 05:44:33.886497
35671	1327	\N	\N	551	1	standalone	2026-06-21 05:44:33.886497
35672	1327	\N	\N	2255	1	standalone	2026-06-21 05:44:33.886497
35673	1327	\N	\N	2269	1	standalone	2026-06-21 05:44:33.886497
35674	1327	\N	\N	687	1	standalone	2026-06-21 05:44:33.886497
35663	1327	\N	\N	1958	1	domain	2026-06-21 05:44:33.886497
35677	1327	\N	\N	3188	1	standalone	2026-06-21 05:44:33.886497
35735	1335	\N	\N	323	1	domain	2026-06-21 05:44:33.92599
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
35693	1330	\N	\N	2516	1	standalone	2026-06-21 05:44:33.896754
35709	1333	\N	\N	1839	1	standalone	2026-06-21 05:44:33.92599
35668	1327	\N	\N	1239	1	domain	2026-06-21 05:44:33.886497
35675	1327	\N	\N	688	1	domain	2026-06-21 05:44:33.886497
35691	1330	\N	\N	1333	1	domain	2026-06-21 05:44:33.896754
35692	1330	\N	\N	2513	1	domain	2026-06-21 05:44:33.896754
35710	1333	\N	\N	824	1	domain	2026-06-21 05:44:33.92599
35711	1333	\N	\N	1001	1	domain	2026-06-21 05:44:33.92599
35834	1322	\N	\N	3176	1	domain	2026-06-21 05:44:34.063154
35878	1329	\N	\N	36	1	domain	2026-06-21 05:44:34.115046
35879	1329	\N	\N	719	1	domain	2026-06-21 05:44:34.115046
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
35820	1328	\N	\N	1982	1	standalone	2026-06-21 05:44:34.017539
35821	1328	\N	\N	1983	1	standalone	2026-06-21 05:44:34.017539
35822	1328	\N	\N	1984	1	standalone	2026-06-21 05:44:34.017539
35840	1333	\N	\N	594	1	standalone	2026-06-21 05:44:34.063154
35844	1333	\N	\N	13	1	standalone	2026-06-21 05:44:34.06894
35845	1333	\N	\N	14	1	standalone	2026-06-21 05:44:34.06894
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
35828	1322	\N	\N	17	1	standalone	2026-06-21 05:44:34.047416
35830	1322	\N	\N	1683	1	standalone	2026-06-21 05:44:34.047416
35831	1322	\N	\N	2288	1	standalone	2026-06-21 05:44:34.047416
35833	1322	\N	\N	3256	1	standalone	2026-06-21 05:44:34.063154
35835	1322	\N	\N	2147	1	standalone	2026-06-21 05:44:34.063154
35836	1322	\N	\N	104	1	standalone	2026-06-21 05:44:34.063154
35837	1322	\N	\N	105	1	standalone	2026-06-21 05:44:34.063154
35838	1322	\N	\N	107	1	standalone	2026-06-21 05:44:34.063154
35799	1328	\N	\N	2473	1	standalone	2026-06-21 05:44:33.985238
35802	1328	\N	\N	711	1	standalone	2026-06-21 05:44:33.992205
35803	1328	\N	\N	1981	1	standalone	2026-06-21 05:44:33.992205
35810	1328	\N	\N	1985	1	standalone	2026-06-21 05:44:34.007397
35812	1328	\N	\N	1677	1	standalone	2026-06-21 05:44:34.017539
35813	1328	\N	\N	1986	1	standalone	2026-06-21 05:44:34.017539
35814	1328	\N	\N	1987	1	standalone	2026-06-21 05:44:34.017539
35815	1328	\N	\N	1988	1	standalone	2026-06-21 05:44:34.017539
35772	1329	\N	\N	3186	1	standalone	2026-06-21 05:44:33.969237
35773	1329	\N	\N	172	1	standalone	2026-06-21 05:44:33.969237
35776	1329	\N	\N	813	1	standalone	2026-06-21 05:44:33.969237
35793	1329	\N	\N	216	1	standalone	2026-06-21 05:44:33.97833
35794	1329	\N	\N	20	1	standalone	2026-06-21 05:44:33.97833
35795	1329	\N	\N	1990	1	standalone	2026-06-21 05:44:33.97833
35877	1329	\N	\N	214	1	standalone	2026-06-21 05:44:34.115046
35880	1329	\N	\N	3291	1	standalone	2026-06-21 05:44:34.115046
35985	1322	\N	\N	2992	1	domain	2026-06-21 05:44:34.209524
35987	1322	\N	\N	2119	1	domain	2026-06-21 05:44:34.209524
35919	1326	\N	\N	1603	1	domain	2026-06-21 05:44:34.16924
35977	1326	\N	\N	1022	1	domain	2026-06-21 05:44:34.193438
35885	1329	\N	\N	2755	1	domain	2026-06-21 05:44:34.115046
35909	1329	\N	\N	1002	1	domain	2026-06-21 05:44:34.148073
35910	1329	\N	\N	1012	1	standalone	2026-06-21 05:44:34.148073
35915	1326	\N	\N	3377	1	standalone	2026-06-21 05:44:34.16924
35916	1326	\N	\N	1868	1	standalone	2026-06-21 05:44:34.16924
35917	1326	\N	\N	1869	1	standalone	2026-06-21 05:44:34.16924
35918	1326	\N	\N	1870	1	standalone	2026-06-21 05:44:34.16924
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
35988	1322	\N	\N	317	1	standalone	2026-06-21 05:44:34.209524
35989	1322	\N	\N	318	1	standalone	2026-06-21 05:44:34.209524
35990	1322	\N	\N	319	1	standalone	2026-06-21 05:44:34.209524
35991	1322	\N	\N	320	1	standalone	2026-06-21 05:44:34.209524
35992	1322	\N	\N	2989	1	standalone	2026-06-21 05:44:34.209524
35993	1322	\N	\N	2990	1	standalone	2026-06-21 05:44:34.209524
35994	1322	\N	\N	2991	1	standalone	2026-06-21 05:44:34.209524
35980	1322	\N	\N	1553	1	standalone	2026-06-21 05:44:34.201483
35981	1322	\N	\N	1709	1	standalone	2026-06-21 05:44:34.201483
35982	1322	\N	\N	1737	1	standalone	2026-06-21 05:44:34.201483
35984	1322	\N	\N	371	1	standalone	2026-06-21 05:44:34.209524
35986	1322	\N	\N	2993	1	standalone	2026-06-21 05:44:34.209524
35927	1326	\N	\N	189	1	standalone	2026-06-21 05:44:34.16924
35976	1326	\N	\N	2828	1	standalone	2026-06-21 05:44:34.193438
35978	1326	\N	\N	1023	1	standalone	2026-06-21 05:44:34.193438
35884	1329	\N	\N	2709	1	standalone	2026-06-21 05:44:34.115046
35891	1329	\N	\N	720	1	standalone	2026-06-21 05:44:34.122044
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
36049	1324	\N	\N	2540	1	domain	2026-06-21 05:44:34.32304
36051	1324	\N	\N	2567	1	domain	2026-06-21 05:44:34.32304
36053	1331	\N	\N	1219	1	domain	2026-06-21 05:44:34.338931
36055	1331	\N	\N	2807	1	domain	2026-06-21 05:44:34.338931
36056	1331	\N	\N	706	1	domain	2026-06-21 05:44:34.338931
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
36088	1331	\N	\N	2182	1	standalone	2026-06-21 05:44:34.371983
36044	1324	\N	\N	3259	1	standalone	2026-06-21 05:44:34.32304
36045	1324	\N	\N	2508	1	standalone	2026-06-21 05:44:34.32304
36046	1324	\N	\N	2525	1	standalone	2026-06-21 05:44:34.32304
36047	1324	\N	\N	2536	1	standalone	2026-06-21 05:44:34.32304
36048	1324	\N	\N	2537	1	standalone	2026-06-21 05:44:34.32304
36050	1324	\N	\N	2553	1	standalone	2026-06-21 05:44:34.32304
36015	1326	\N	\N	2280	1	standalone	2026-06-21 05:44:34.225412
36101	1326	\N	\N	573	1	standalone	2026-06-21 05:44:34.405374
36009	1329	\N	\N	369	1	standalone	2026-06-21 05:44:34.225412
36010	1329	\N	\N	3305	1	standalone	2026-06-21 05:44:34.225412
36037	1329	\N	\N	956	1	standalone	2026-06-21 05:44:34.266242
36038	1329	\N	\N	814	1	standalone	2026-06-21 05:44:34.266242
36054	1331	\N	\N	1220	1	standalone	2026-06-21 05:44:34.338931
36122	1327	\N	\N	959	1	domain	2026-06-21 05:44:34.442906
36123	1327	\N	\N	1825	1	domain	2026-06-21 05:44:34.442906
36170	1330	\N	\N	3121	1	domain	2026-06-21 05:44:34.486965
36189	1330	\N	\N	1325	1	domain	2026-06-21 05:44:34.508492
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
36179	1330	\N	\N	3150	1	standalone	2026-06-21 05:44:34.499906
36183	1330	\N	\N	1648	1	standalone	2026-06-21 05:44:34.508492
36184	1330	\N	\N	1653	1	standalone	2026-06-21 05:44:34.508492
36185	1330	\N	\N	1649	1	standalone	2026-06-21 05:44:34.508492
36186	1330	\N	\N	1651	1	standalone	2026-06-21 05:44:34.508492
36188	1330	\N	\N	2263	1	standalone	2026-06-21 05:44:34.508492
36190	1330	\N	\N	1326	1	standalone	2026-06-21 05:44:34.508492
36191	1330	\N	\N	1329	1	standalone	2026-06-21 05:44:34.508492
36192	1330	\N	\N	2544	1	standalone	2026-06-21 05:44:34.508492
36193	1330	\N	\N	2554	1	standalone	2026-06-21 05:44:34.508492
36194	1330	\N	\N	2559	1	standalone	2026-06-21 05:44:34.508492
36195	1330	\N	\N	2545	1	standalone	2026-06-21 05:44:34.508492
36218	1338	\N	\N	1660	1	standalone	2026-06-21 05:44:34.548301
36219	1338	\N	\N	2058	1	standalone	2026-06-21 05:44:34.548301
36220	1338	\N	\N	2060	1	standalone	2026-06-21 05:44:34.548301
36221	1338	\N	\N	2061	1	standalone	2026-06-21 05:44:34.548301
36222	1338	\N	\N	2426	1	standalone	2026-06-21 05:44:34.548301
36223	1338	\N	\N	2430	1	standalone	2026-06-21 05:44:34.548301
36224	1338	\N	\N	2014	1	standalone	2026-06-21 05:44:34.548301
36136	1322	\N	\N	2069	1	standalone	2026-06-21 05:44:34.459896
36115	1326	\N	\N	761	1	standalone	2026-06-21 05:44:34.426831
36116	1326	\N	\N	304	1	standalone	2026-06-21 05:44:34.426831
36118	1326	\N	\N	1270	1	standalone	2026-06-21 05:44:34.426831
36119	1326	\N	\N	2251	1	standalone	2026-06-21 05:44:34.426831
36159	1330	\N	\N	244	1	standalone	2026-06-21 05:44:34.475881
36160	1330	\N	\N	245	1	standalone	2026-06-21 05:44:34.475881
36161	1330	\N	\N	246	1	standalone	2026-06-21 05:44:34.475881
36163	1330	\N	\N	2261	1	standalone	2026-06-21 05:44:34.475881
36164	1330	\N	\N	1322	1	standalone	2026-06-21 05:44:34.475881
36165	1330	\N	\N	2348	1	standalone	2026-06-21 05:44:34.475881
36166	1330	\N	\N	2543	1	standalone	2026-06-21 05:44:34.475881
36167	1330	\N	\N	2562	1	standalone	2026-06-21 05:44:34.475881
36169	1330	\N	\N	764	1	standalone	2026-06-21 05:44:34.486965
36171	1330	\N	\N	3123	1	standalone	2026-06-21 05:44:34.486965
36173	1330	\N	\N	731	1	standalone	2026-06-21 05:44:34.486965
36264	1331	\N	\N	722	1	domain	2026-06-21 05:44:34.620015
36265	1331	\N	\N	1645	1	domain	2026-06-21 05:44:34.620015
36271	1338	\N	\N	613	1	domain	2026-06-21 05:44:34.620015
36284	1338	\N	\N	876	1	domain	2026-06-21 05:44:34.620015
36240	1336	\N	\N	252	1	standalone	2026-06-21 05:44:34.573818
36241	1336	\N	\N	253	1	standalone	2026-06-21 05:44:34.573818
36245	1336	\N	\N	2189	1	standalone	2026-06-21 05:44:34.580196
36246	1336	\N	\N	2192	1	standalone	2026-06-21 05:44:34.580196
36270	1338	\N	\N	1567	1	standalone	2026-06-21 05:44:34.620015
36272	1338	\N	\N	614	1	standalone	2026-06-21 05:44:34.620015
36276	1338	\N	\N	3226	1	standalone	2026-06-21 05:44:34.620015
36280	1338	\N	\N	2943	1	standalone	2026-06-21 05:44:34.620015
36283	1338	\N	\N	2181	1	standalone	2026-06-21 05:44:34.620015
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
36339	1328	\N	\N	1600	1	standalone	2026-06-21 05:44:34.661431
36307	1329	\N	\N	661	1	standalone	2026-06-21 05:44:34.637151
36308	1329	\N	\N	415	1	standalone	2026-06-21 05:44:34.637151
36309	1329	\N	\N	1013	1	standalone	2026-06-21 05:44:34.637151
36226	1330	\N	\N	698	1	standalone	2026-06-21 05:44:34.548301
36261	1331	\N	\N	3335	1	standalone	2026-06-21 05:44:34.620015
36266	1331	\N	\N	283	1	standalone	2026-06-21 05:44:34.620015
36267	1331	\N	\N	286	1	standalone	2026-06-21 05:44:34.620015
36311	1333	\N	\N	373	1	standalone	2026-06-21 05:44:34.644599
36314	1333	\N	\N	2974	1	standalone	2026-06-21 05:44:34.644599
36315	1333	\N	\N	2976	1	standalone	2026-06-21 05:44:34.644599
36319	1333	\N	\N	3282	1	standalone	2026-06-21 05:44:34.652893
36231	1336	\N	\N	1588	1	standalone	2026-06-21 05:44:34.566037
36238	1336	\N	\N	2188	1	standalone	2026-06-21 05:44:34.573818
36239	1336	\N	\N	2376	1	standalone	2026-06-21 05:44:34.573818
36243	1336	\N	\N	1192	1	standalone	2026-06-21 05:44:34.580196
36244	1336	\N	\N	2190	1	standalone	2026-06-21 05:44:34.580196
36249	1336	\N	\N	1725	1	standalone	2026-06-21 05:44:34.588411
36253	1338	\N	\N	1300	1	standalone	2026-06-21 05:44:34.594443
36254	1338	\N	\N	2431	1	standalone	2026-06-21 05:44:34.594443
36256	1338	\N	\N	605	1	standalone	2026-06-21 05:44:34.606516
36258	1338	\N	\N	2153	1	standalone	2026-06-21 05:44:34.606516
36259	1338	\N	\N	2359	1	standalone	2026-06-21 05:44:34.606516
36300	1338	\N	\N	1565	1	standalone	2026-06-21 05:44:34.637151
36397	1322	\N	\N	789	1	domain	2026-06-21 05:44:34.710134
36398	1322	\N	\N	790	1	domain	2026-06-21 05:44:34.710134
36367	1329	\N	\N	222	1	domain	2026-06-21 05:44:34.694773
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
36371	1329	\N	\N	1260	1	domain	2026-06-21 05:44:34.694773
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
36440	1329	\N	\N	638	1	standalone	2026-06-21 05:44:34.741485
36441	1329	\N	\N	639	1	standalone	2026-06-21 05:44:34.741485
36445	1329	\N	\N	2185	1	standalone	2026-06-21 05:44:34.741485
36446	1329	\N	\N	2360	1	standalone	2026-06-21 05:44:34.741485
36362	1322	\N	\N	1139	1	standalone	2026-06-21 05:44:34.677276
36363	1322	\N	\N	1140	1	standalone	2026-06-21 05:44:34.677276
36365	1322	\N	\N	2984	1	standalone	2026-06-21 05:44:34.677276
36396	1322	\N	\N	2078	1	standalone	2026-06-21 05:44:34.710134
36400	1322	\N	\N	1534	1	standalone	2026-06-21 05:44:34.710134
36375	1323	\N	\N	3204	1	standalone	2026-06-21 05:44:34.694773
36376	1323	\N	\N	1719	1	standalone	2026-06-21 05:44:34.694773
36356	1326	\N	\N	2603	1	standalone	2026-06-21 05:44:34.677276
36358	1326	\N	\N	274	1	standalone	2026-06-21 05:44:34.677276
36359	1326	\N	\N	2416	1	standalone	2026-06-21 05:44:34.677276
36360	1326	\N	\N	2422	1	standalone	2026-06-21 05:44:34.677276
36342	1328	\N	\N	718	1	standalone	2026-06-21 05:44:34.661431
36373	1329	\N	\N	2388	1	standalone	2026-06-21 05:44:34.694773
36391	1335	\N	\N	1318	1	standalone	2026-06-21 05:44:34.710134
36392	1335	\N	\N	1321	1	standalone	2026-06-21 05:44:34.710134
36393	1335	\N	\N	2398	1	standalone	2026-06-21 05:44:34.710134
36444	1329	\N	\N	108	1	domain	2026-06-21 05:44:34.741485
36518	1322	\N	\N	1293	1	domain	2026-06-21 05:44:34.899853
36500	1326	\N	\N	76	1	domain	2026-06-21 05:44:34.861503
36501	1326	\N	\N	122	1	domain	2026-06-21 05:44:34.861503
36526	1328	\N	\N	755	1	domain	2026-06-21 05:44:35.261598
36453	1328	\N	\N	3212	1	domain	2026-06-21 05:44:34.757386
36522	1328	\N	\N	2471	1	domain	2026-06-21 05:44:35.261598
36490	1338	\N	\N	482	1	standalone	2026-06-21 05:44:34.805749
36491	1338	\N	\N	558	1	standalone	2026-06-21 05:44:34.805749
36492	1338	\N	\N	483	1	standalone	2026-06-21 05:44:34.805749
36493	1338	\N	\N	485	1	standalone	2026-06-21 05:44:34.805749
36494	1338	\N	\N	486	1	standalone	2026-06-21 05:44:34.805749
36498	1338	\N	\N	1528	1	standalone	2026-06-21 05:44:34.853365
36519	1339	\N	\N	1480	1	standalone	2026-06-21 05:44:35.261598
36520	1322	\N	\N	2843	1	standalone	2026-06-21 05:44:35.261598
36521	1329	\N	\N	411	1	standalone	2026-06-21 05:44:35.261598
36525	1335	\N	\N	1147	1	standalone	2026-06-21 05:44:35.261598
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
36513	1322	\N	\N	2197	1	standalone	2026-06-21 05:44:34.899853
36514	1322	\N	\N	2757	1	standalone	2026-06-21 05:44:34.899853
36515	1322	\N	\N	2758	1	standalone	2026-06-21 05:44:34.899853
36516	1322	\N	\N	2761	1	standalone	2026-06-21 05:44:34.899853
36517	1322	\N	\N	2769	1	standalone	2026-06-21 05:44:34.899853
36464	1326	\N	\N	2829	1	standalone	2026-06-21 05:44:34.773529
36465	1326	\N	\N	1274	1	standalone	2026-06-21 05:44:34.773529
36502	1326	\N	\N	2337	1	standalone	2026-06-21 05:44:34.861503
36503	1326	\N	\N	2338	1	standalone	2026-06-21 05:44:34.861503
36504	1326	\N	\N	2339	1	standalone	2026-06-21 05:44:34.861503
36594	1322	\N	\N	949	1	domain	2026-06-21 05:44:35.269741
36567	1322	\N	\N	3251	1	standalone	2026-06-21 05:44:35.261598
36568	1329	\N	\N	692	1	standalone	2026-06-21 05:44:35.261598
36569	1329	\N	\N	7000	1	standalone	2026-06-21 05:44:35.261598
36570	1326	\N	\N	596	1	standalone	2026-06-21 05:44:35.261598
36571	1322	\N	\N	1571	1	standalone	2026-06-21 05:44:35.261598
36572	1329	\N	\N	648	1	standalone	2026-06-21 05:44:35.269741
36573	1338	\N	\N	1850	1	standalone	2026-06-21 05:44:35.269741
36574	1326	\N	\N	3371	1	standalone	2026-06-21 05:44:35.269741
36575	1339	\N	\N	3344	1	standalone	2026-06-21 05:44:35.269741
36586	1327	\N	\N	759	1	domain	2026-06-21 05:44:35.269741
36578	1338	\N	\N	196	1	standalone	2026-06-21 05:44:35.269741
36579	1329	\N	\N	1345	1	standalone	2026-06-21 05:44:35.269741
36580	1322	\N	\N	2847	1	standalone	2026-06-21 05:44:35.269741
36581	1322	\N	\N	391	1	standalone	2026-06-21 05:44:35.269741
36582	1326	\N	\N	2454	1	standalone	2026-06-21 05:44:35.269741
36583	1339	\N	\N	1076	1	standalone	2026-06-21 05:44:35.269741
36584	1322	\N	\N	1745	1	standalone	2026-06-21 05:44:35.269741
36585	1327	\N	\N	1183	1	standalone	2026-06-21 05:44:35.269741
36587	1325	\N	\N	18	1	standalone	2026-06-21 05:44:35.269741
36588	1336	\N	\N	1665	1	standalone	2026-06-21 05:44:35.269741
36589	1322	\N	\N	2636	1	standalone	2026-06-21 05:44:35.269741
36590	1334	\N	\N	2786	1	standalone	2026-06-21 05:44:35.269741
36591	1335	\N	\N	208	1	standalone	2026-06-21 05:44:35.269741
36592	1326	\N	\N	1865	1	standalone	2026-06-21 05:44:35.269741
36593	1322	\N	\N	355	1	standalone	2026-06-21 05:44:35.269741
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
36680	1322	\N	\N	3255	1	standalone	2026-06-21 05:44:35.269741
36681	1322	\N	\N	710	1	standalone	2026-06-21 05:44:35.269741
36682	1329	\N	\N	7006	1	standalone	2026-06-21 05:44:35.269741
36683	1338	\N	\N	617	1	standalone	2026-06-21 05:44:35.269741
36684	1322	\N	\N	1580	1	standalone	2026-06-21 05:44:35.269741
36685	1329	\N	\N	672	1	standalone	2026-06-21 05:44:35.269741
36686	1334	\N	\N	1816	1	standalone	2026-06-21 05:44:35.269741
36731	1322	\N	\N	3174	1	domain	2026-06-21 05:44:35.269741
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
36740	1322	\N	\N	2080	1	domain	2026-06-21 05:44:35.269741
36699	1334	\N	\N	2650	1	standalone	2026-06-21 05:44:35.269741
36700	1334	\N	\N	2789	1	standalone	2026-06-21 05:44:35.269741
36701	1327	\N	\N	230	1	standalone	2026-06-21 05:44:35.269741
36702	1329	\N	\N	1938	1	standalone	2026-06-21 05:44:35.269741
36703	1322	\N	\N	360	1	standalone	2026-06-21 05:44:35.269741
36679	1322	\N	\N	3170	1	domain	2026-06-21 05:44:35.269741
36705	1327	\N	\N	3135	1	standalone	2026-06-21 05:44:35.269741
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
36706	1322	\N	\N	3173	1	domain	2026-06-21 05:44:35.269741
36722	1328	\N	\N	33	1	standalone	2026-06-21 05:44:35.269741
36723	1324	\N	\N	1641	1	standalone	2026-06-21 05:44:35.269741
36724	1322	\N	\N	2651	1	standalone	2026-06-21 05:44:35.269741
36725	1334	\N	\N	2790	1	standalone	2026-06-21 05:44:35.269741
36726	1337	\N	\N	231	1	standalone	2026-06-21 05:44:35.269741
36727	1329	\N	\N	1991	1	standalone	2026-06-21 05:44:35.269741
36728	1322	\N	\N	361	1	standalone	2026-06-21 05:44:35.269741
36729	1334	\N	\N	966	1	standalone	2026-06-21 05:44:35.269741
36730	1330	\N	\N	3137	1	standalone	2026-06-21 05:44:35.269741
36732	1322	\N	\N	3257	1	standalone	2026-06-21 05:44:35.269741
36733	1327	\N	\N	716	1	standalone	2026-06-21 05:44:35.269741
36734	1329	\N	\N	7013	1	standalone	2026-06-21 05:44:35.269741
36735	1331	\N	\N	619	1	standalone	2026-06-21 05:44:35.269741
36736	1322	\N	\N	1582	1	standalone	2026-06-21 05:44:35.269741
36737	1324	\N	\N	1377	1	standalone	2026-06-21 05:44:35.269741
36738	1322	\N	\N	2858	1	standalone	2026-06-21 05:44:35.269741
36739	1322	\N	\N	398	1	standalone	2026-06-21 05:44:35.269741
36741	1335	\N	\N	1101	1	standalone	2026-06-21 05:44:35.269741
36742	1322	\N	\N	1751	1	standalone	2026-06-21 05:44:35.269741
36743	1334	\N	\N	1142	1	standalone	2026-06-21 05:44:35.269741
36678	1333	\N	\N	3112	1	domain	2026-06-21 05:44:35.269741
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
36877	1324	\N	\N	3162	1	domain	2026-06-21 05:44:35.269741
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
36885	1334	\N	\N	1757	1	domain	2026-06-21 05:44:35.269741
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
36879	1329	\N	\N	3290	1	standalone	2026-06-21 05:44:35.269741
36880	1322	\N	\N	1418	1	standalone	2026-06-21 05:44:35.269741
36881	1322	\N	\N	2868	1	standalone	2026-06-21 05:44:35.269741
36882	1329	\N	\N	405	1	standalone	2026-06-21 05:44:35.269741
36883	1325	\N	\N	2246	1	standalone	2026-06-21 05:44:35.269741
36884	1322	\N	\N	1043	1	standalone	2026-06-21 05:44:35.269741
36886	1339	\N	\N	1328	1	standalone	2026-06-21 05:44:35.269741
36842	1322	\N	\N	1413	1	domain	2026-06-21 05:44:35.269741
36887	1332	\N	\N	807	1	standalone	2026-06-21 05:44:35.269741
36888	1329	\N	\N	95	1	standalone	2026-06-21 05:44:35.269741
36889	1328	\N	\N	1673	1	standalone	2026-06-21 05:44:35.269741
36890	1326	\N	\N	2693	1	standalone	2026-06-21 05:44:35.269741
36891	1334	\N	\N	2798	1	standalone	2026-06-21 05:44:35.269741
36892	1337	\N	\N	278	1	standalone	2026-06-21 05:44:35.269741
36893	1337	\N	\N	2012	1	standalone	2026-06-21 05:44:35.269741
36982	1335	\N	\N	1035	1	domain	2026-06-21 05:44:35.269741
36895	1329	\N	\N	1003	1	standalone	2026-06-21 05:44:35.269741
36989	1335	\N	\N	1159	1	domain	2026-06-21 05:44:35.269741
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
36983	1339	\N	\N	1436	1	standalone	2026-06-21 05:44:35.269741
36984	1322	\N	\N	2882	1	standalone	2026-06-21 05:44:35.269741
36985	1329	\N	\N	421	1	standalone	2026-06-21 05:44:35.269741
36986	1339	\N	\N	2169	1	standalone	2026-06-21 05:44:35.269741
36987	1322	\N	\N	1048	1	standalone	2026-06-21 05:44:35.269741
36988	1335	\N	\N	1764	1	standalone	2026-06-21 05:44:35.269741
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
37111	1322	\N	\N	1774	1	standalone	2026-06-21 05:44:35.269741
37112	1331	\N	\N	1230	1	standalone	2026-06-21 05:44:35.269741
37113	1329	\N	\N	893	1	standalone	2026-06-21 05:44:35.269741
37114	1324	\N	\N	156	1	standalone	2026-06-21 05:44:35.269741
37115	1334	\N	\N	1739	1	standalone	2026-06-21 05:44:35.269741
37116	1337	\N	\N	2780	1	standalone	2026-06-21 05:44:35.269741
37191	1327	\N	\N	2254	1	domain	2026-06-21 05:44:35.269741
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
37110	1332	\N	\N	1064	1	domain	2026-06-21 05:44:35.269741
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
37215	1330	\N	\N	1297	1	domain	2026-06-21 05:44:35.269741
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
37359	1322	\N	\N	1541	1	domain	2026-06-21 05:44:35.269741
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
37407	1332	\N	\N	3088	1	domain	2026-06-21 05:44:35.269741
37356	1339	\N	\N	3039	1	standalone	2026-06-21 05:44:35.269741
37357	1322	\N	\N	532	1	standalone	2026-06-21 05:44:35.269741
37358	1327	\N	\N	2494	1	standalone	2026-06-21 05:44:35.269741
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
34172	1327	\N	\N	1633	1	domain	2026-06-21 05:44:32.120663
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
34489	1322	\N	\N	2613	1	domain	2026-06-21 05:44:32.483293
34008	1328	\N	\N	55	1	standalone	2026-06-21 05:44:31.888851
34009	1328	\N	\N	2432	1	standalone	2026-06-21 05:44:31.888851
34494	1322	\N	\N	1545	1	domain	2026-06-21 05:44:32.491539
34016	1328	\N	\N	2435	1	standalone	2026-06-21 05:44:31.903226
34018	1328	\N	\N	2090	1	standalone	2026-06-21 05:44:31.916829
34711	1324	\N	\N	307	1	domain	2026-06-21 05:44:32.746953
34714	1324	\N	\N	2184	1	domain	2026-06-21 05:44:32.746953
34022	1328	\N	\N	47	1	standalone	2026-06-21 05:44:31.916829
34019	1328	\N	\N	52	1	standalone	2026-06-21 05:44:31.916829
34046	1328	\N	\N	49	1	standalone	2026-06-21 05:44:31.948158
35379	1327	\N	\N	3217	1	domain	2026-06-21 05:44:33.581816
34050	1328	\N	\N	821	1	standalone	2026-06-21 05:44:31.948158
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
34051	1328	\N	\N	825	1	domain	2026-06-21 05:44:31.948158
34415	1334	\N	\N	2751	1	standalone	2026-06-21 05:44:32.338592
34416	1334	\N	\N	2778	1	standalone	2026-06-21 05:44:32.338592
34454	1334	\N	\N	1120	1	standalone	2026-06-21 05:44:32.409573
34453	1334	\N	\N	2799	1	standalone	2026-06-21 05:44:32.409573
36399	1322	\N	\N	1535	1	standalone	2026-06-21 05:44:34.710134
35070	1330	\N	\N	2114	1	standalone	2026-06-21 05:44:33.144385
34468	1322	\N	\N	1856	1	standalone	2026-06-21 05:44:32.458243
35420	1338	\N	\N	1201	1	domain	2026-06-21 05:44:33.654506
35054	1330	\N	\N	3025	1	standalone	2026-06-21 05:44:33.105449
35052	1330	\N	\N	1615	1	standalone	2026-06-21 05:44:33.105449
35574	1322	\N	\N	2644	1	standalone	2026-06-21 05:44:33.824865
35579	1322	\N	\N	2683	1	standalone	2026-06-21 05:44:33.824865
34490	1322	\N	\N	1810	1	standalone	2026-06-21 05:44:32.483293
34516	1322	\N	\N	2402	1	standalone	2026-06-21 05:44:32.524103
34531	1322	\N	\N	3054	1	standalone	2026-06-21 05:44:32.541462
34637	1324	\N	\N	1607	1	standalone	2026-06-21 05:44:32.621305
34600	1329	\N	\N	468	1	standalone	2026-06-21 05:44:32.605341
34598	1329	\N	\N	2827	1	standalone	2026-06-21 05:44:32.605341
34661	1324	\N	\N	2102	1	standalone	2026-06-21 05:44:32.687403
34666	1324	\N	\N	2046	1	standalone	2026-06-21 05:44:32.706746
34712	1324	\N	\N	313	1	standalone	2026-06-21 05:44:32.746953
34703	1324	\N	\N	434	1	standalone	2026-06-21 05:44:32.746953
34717	1324	\N	\N	1349	1	standalone	2026-06-21 05:44:32.746953
34702	1324	\N	\N	2097	1	standalone	2026-06-21 05:44:32.746953
34706	1324	\N	\N	2103	1	standalone	2026-06-21 05:44:32.746953
34713	1324	\N	\N	2180	1	standalone	2026-06-21 05:44:32.746953
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
35255	1329	\N	\N	1425	1	domain	2026-06-21 05:44:33.395405
34263	1331	\N	\N	907	1	domain	2026-06-21 05:44:32.173215
35196	1336	\N	\N	3362	1	standalone	2026-06-21 05:44:33.328484
35198	1336	\N	\N	3153	1	standalone	2026-06-21 05:44:33.328484
35199	1336	\N	\N	3364	1	standalone	2026-06-21 05:44:33.328484
35200	1336	\N	\N	3365	1	standalone	2026-06-21 05:44:33.328484
35203	1336	\N	\N	1935	1	standalone	2026-06-21 05:44:33.328484
35197	1336	\N	\N	1635	1	domain	2026-06-21 05:44:33.328484
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
34867	1322	\N	\N	683	1	standalone	2026-06-21 05:44:32.958835
34265	1331	\N	\N	909	1	standalone	2026-06-21 05:44:32.173215
36920	1322	\N	\N	1045	1	domain	2026-06-21 05:44:35.269741
36922	1322	\N	\N	1116	1	domain	2026-06-21 05:44:35.269741
34515	1322	\N	\N	1131	1	domain	2026-06-21 05:44:32.524103
34563	1322	\N	\N	1107	1	domain	2026-06-21 05:44:32.55625
34573	1322	\N	\N	2480	1	domain	2026-06-21 05:44:32.55625
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
37698	1350	\N	\N	190	0.8	ai	2026-06-21 08:00:37.577784
37699	1350	\N	\N	94	0.8	ai	2026-06-21 08:00:37.577784
37700	1350	\N	\N	95	0.8	ai	2026-06-21 08:00:37.577784
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
34687	1324	\N	\N	2539	1	domain	2026-06-21 05:44:32.728285
35545	1322	\N	\N	2667	1	standalone	2026-06-21 05:44:33.799828
35546	1322	\N	\N	2733	1	standalone	2026-06-21 05:44:33.799828
34538	1322	\N	\N	2130	1	standalone	2026-06-21 05:44:32.55625
34539	1322	\N	\N	1690	1	standalone	2026-06-21 05:44:32.55625
35532	1323	\N	\N	1892	1	standalone	2026-06-21 05:44:33.771784
35533	1323	\N	\N	727	1	standalone	2026-06-21 05:44:33.771784
35522	1323	\N	\N	2350	1	standalone	2026-06-21 05:44:33.760601
34685	1324	\N	\N	1337	1	standalone	2026-06-21 05:44:32.728285
34686	1324	\N	\N	2417	1	standalone	2026-06-21 05:44:32.728285
34699	1324	\N	\N	3138	1	standalone	2026-06-21 05:44:32.746953
34701	1324	\N	\N	431	1	standalone	2026-06-21 05:44:32.746953
34704	1324	\N	\N	2099	1	standalone	2026-06-21 05:44:32.746953
34705	1324	\N	\N	2100	1	standalone	2026-06-21 05:44:32.746953
34707	1324	\N	\N	54	1	standalone	2026-06-21 05:44:32.746953
34708	1324	\N	\N	2898	1	standalone	2026-06-21 05:44:32.746953
34709	1324	\N	\N	746	1	standalone	2026-06-21 05:44:32.746953
34715	1324	\N	\N	2745	1	standalone	2026-06-21 05:44:32.746953
34716	1324	\N	\N	2766	1	standalone	2026-06-21 05:44:32.746953
34718	1324	\N	\N	2047	1	standalone	2026-06-21 05:44:32.746953
33836	1325	\N	\N	3191	1	standalone	2026-06-21 05:44:31.57815
33837	1325	\N	\N	2085	1	standalone	2026-06-21 05:44:31.57815
33839	1325	\N	\N	2866	1	standalone	2026-06-21 05:44:31.594534
33840	1325	\N	\N	1123	1	standalone	2026-06-21 05:44:31.594534
33842	1325	\N	\N	2895	1	standalone	2026-06-21 05:44:31.594534
33843	1325	\N	\N	2896	1	standalone	2026-06-21 05:44:31.594534
37837	1329	4525	\N	\N	1	domain	2026-06-21 08:17:38.321365
33844	1325	\N	\N	2897	1	standalone	2026-06-21 05:44:31.594534
33854	1326	\N	\N	279	1	standalone	2026-06-21 05:44:31.623499
33855	1326	\N	\N	2421	1	standalone	2026-06-21 05:44:31.623499
33859	1326	\N	\N	1916	1	standalone	2026-06-21 05:44:31.633075
33860	1326	\N	\N	1278	1	standalone	2026-06-21 05:44:31.633075
33862	1326	\N	\N	1846	1	standalone	2026-06-21 05:44:31.643175
33863	1326	\N	\N	2690	1	standalone	2026-06-21 05:44:31.643175
33868	1326	\N	\N	92	1	standalone	2026-06-21 05:44:31.654802
33869	1326	\N	\N	93	1	standalone	2026-06-21 05:44:31.654802
33873	1326	\N	\N	1913	1	standalone	2026-06-21 05:44:31.661684
33874	1326	\N	\N	276	1	standalone	2026-06-21 05:44:31.661684
33880	1326	\N	\N	1921	1	standalone	2026-06-21 05:44:31.671704
33881	1326	\N	\N	1320	1	standalone	2026-06-21 05:44:31.671704
33883	1326	\N	\N	275	1	standalone	2026-06-21 05:44:31.678557
33884	1326	\N	\N	2296	1	standalone	2026-06-21 05:44:31.678557
33885	1326	\N	\N	2332	1	standalone	2026-06-21 05:44:31.678557
33886	1326	\N	\N	2336	1	standalone	2026-06-21 05:44:31.678557
33932	1327	\N	\N	1944	1	standalone	2026-06-21 05:44:31.786826
33959	1327	\N	\N	2091	1	standalone	2026-06-21 05:44:31.838377
33960	1327	\N	\N	445	1	standalone	2026-06-21 05:44:31.838377
33965	1327	\N	\N	1945	1	standalone	2026-06-21 05:44:31.838377
34169	1327	\N	\N	422	1	standalone	2026-06-21 05:44:32.120663
34170	1327	\N	\N	423	1	standalone	2026-06-21 05:44:32.120663
34171	1327	\N	\N	427	1	standalone	2026-06-21 05:44:32.120663
34173	1327	\N	\N	248	1	standalone	2026-06-21 05:44:32.120663
34174	1327	\N	\N	249	1	standalone	2026-06-21 05:44:32.120663
34184	1327	\N	\N	1375	1	standalone	2026-06-21 05:44:32.120663
34185	1327	\N	\N	1233	1	standalone	2026-06-21 05:44:32.120663
34722	1327	\N	\N	1961	1	standalone	2026-06-21 05:44:32.760826
34723	1327	\N	\N	1972	1	standalone	2026-06-21 05:44:32.760826
34724	1327	\N	\N	1973	1	standalone	2026-06-21 05:44:32.760826
34725	1327	\N	\N	1974	1	standalone	2026-06-21 05:44:32.760826
34731	1327	\N	\N	568	1	standalone	2026-06-21 05:44:32.779055
36456	1328	\N	\N	1680	1	standalone	2026-06-21 05:44:34.757386
36467	1328	\N	\N	992	1	standalone	2026-06-21 05:44:34.773529
36468	1328	\N	\N	2695	1	standalone	2026-06-21 05:44:34.773529
36469	1328	\N	\N	2696	1	standalone	2026-06-21 05:44:34.773529
36470	1328	\N	\N	2478	1	standalone	2026-06-21 05:44:34.773529
34068	1329	\N	\N	284	1	standalone	2026-06-21 05:44:31.987186
34069	1329	\N	\N	839	1	standalone	2026-06-21 05:44:31.987186
35881	1329	\N	\N	3298	1	standalone	2026-06-21 05:44:34.115046
35895	1329	\N	\N	1672	1	standalone	2026-06-21 05:44:34.122044
35905	1329	\N	\N	2463	1	standalone	2026-06-21 05:44:34.148073
35906	1329	\N	\N	2464	1	standalone	2026-06-21 05:44:34.148073
35907	1329	\N	\N	2465	1	standalone	2026-06-21 05:44:34.148073
35908	1329	\N	\N	2466	1	standalone	2026-06-21 05:44:34.148073
35912	1329	\N	\N	3270	1	standalone	2026-06-21 05:44:34.16924
35913	1329	\N	\N	2711	1	standalone	2026-06-21 05:44:34.16924
34197	1330	\N	\N	3387	1	standalone	2026-06-21 05:44:32.132998
34198	1330	\N	\N	612	1	standalone	2026-06-21 05:44:32.132998
35043	1330	\N	\N	2000	1	standalone	2026-06-21 05:44:33.093566
35047	1330	\N	\N	266	1	standalone	2026-06-21 05:44:33.09558
35049	1330	\N	\N	2002	1	standalone	2026-06-21 05:44:33.09558
35050	1330	\N	\N	2008	1	standalone	2026-06-21 05:44:33.09558
35058	1330	\N	\N	2001	1	standalone	2026-06-21 05:44:33.122004
35065	1330	\N	\N	265	1	standalone	2026-06-21 05:44:33.122004
35066	1330	\N	\N	2202	1	standalone	2026-06-21 05:44:33.122004
35069	1330	\N	\N	2113	1	standalone	2026-06-21 05:44:33.144385
35332	1330	\N	\N	599	1	standalone	2026-06-21 05:44:33.515008
35333	1330	\N	\N	600	1	standalone	2026-06-21 05:44:33.515008
35335	1330	\N	\N	1204	1	standalone	2026-06-21 05:44:33.515008
35338	1330	\N	\N	3336	1	standalone	2026-06-21 05:44:33.525251
35341	1330	\N	\N	2438	1	standalone	2026-06-21 05:44:33.525251
35343	1330	\N	\N	2713	1	standalone	2026-06-21 05:44:33.540797
35344	1330	\N	\N	2492	1	standalone	2026-06-21 05:44:33.540797
35345	1330	\N	\N	2506	1	standalone	2026-06-21 05:44:33.540797
35359	1330	\N	\N	2670	1	standalone	2026-06-21 05:44:33.548909
35360	1330	\N	\N	2956	1	standalone	2026-06-21 05:44:33.548909
35361	1330	\N	\N	2732	1	standalone	2026-06-21 05:44:33.548909
35363	1330	\N	\N	2938	1	standalone	2026-06-21 05:44:33.557295
35371	1330	\N	\N	2770	1	standalone	2026-06-21 05:44:33.570978
35372	1330	\N	\N	2771	1	standalone	2026-06-21 05:44:33.570978
35373	1330	\N	\N	2773	1	standalone	2026-06-21 05:44:33.570978
35374	1330	\N	\N	2774	1	standalone	2026-06-21 05:44:33.570978
36174	1330	\N	\N	71	1	standalone	2026-06-21 05:44:34.486965
36176	1330	\N	\N	1598	1	standalone	2026-06-21 05:44:34.499906
36177	1330	\N	\N	3125	1	standalone	2026-06-21 05:44:34.499906
36178	1330	\N	\N	2267	1	standalone	2026-06-21 05:44:34.499906
36181	1330	\N	\N	1647	1	standalone	2026-06-21 05:44:34.508492
36182	1330	\N	\N	1968	1	standalone	2026-06-21 05:44:34.508492
36057	1331	\N	\N	1584	1	standalone	2026-06-21 05:44:34.338931
36058	1331	\N	\N	882	1	standalone	2026-06-21 05:44:34.338931
36059	1331	\N	\N	162	1	standalone	2026-06-21 05:44:34.338931
36062	1331	\N	\N	1221	1	standalone	2026-06-21 05:44:34.338931
36063	1331	\N	\N	621	1	standalone	2026-06-21 05:44:34.338931
36064	1331	\N	\N	2148	1	standalone	2026-06-21 05:44:34.338931
36065	1331	\N	\N	2149	1	standalone	2026-06-21 05:44:34.338931
36066	1331	\N	\N	2946	1	standalone	2026-06-21 05:44:34.338931
36067	1331	\N	\N	3074	1	standalone	2026-06-21 05:44:34.338931
36070	1331	\N	\N	935	1	standalone	2026-06-21 05:44:34.362521
36072	1331	\N	\N	3058	1	standalone	2026-06-21 05:44:34.362521
36073	1331	\N	\N	3059	1	standalone	2026-06-21 05:44:34.362521
36074	1331	\N	\N	3061	1	standalone	2026-06-21 05:44:34.362521
36075	1331	\N	\N	3062	1	standalone	2026-06-21 05:44:34.362521
36076	1331	\N	\N	3064	1	standalone	2026-06-21 05:44:34.362521
36077	1331	\N	\N	3077	1	standalone	2026-06-21 05:44:34.362521
36078	1331	\N	\N	3073	1	standalone	2026-06-21 05:44:34.362521
36079	1331	\N	\N	3076	1	standalone	2026-06-21 05:44:34.362521
36081	1331	\N	\N	936	1	standalone	2026-06-21 05:44:34.371983
36082	1331	\N	\N	942	1	standalone	2026-06-21 05:44:34.371983
36083	1331	\N	\N	2223	1	standalone	2026-06-21 05:44:34.371983
36085	1331	\N	\N	3078	1	standalone	2026-06-21 05:44:34.371983
36086	1331	\N	\N	3079	1	standalone	2026-06-21 05:44:34.371983
36087	1331	\N	\N	3080	1	standalone	2026-06-21 05:44:34.371983
36090	1331	\N	\N	934	1	standalone	2026-06-21 05:44:34.386706
36091	1331	\N	\N	1217	1	standalone	2026-06-21 05:44:34.386706
36109	1332	\N	\N	3261	1	standalone	2026-06-21 05:44:34.426831
36110	1332	\N	\N	3262	1	standalone	2026-06-21 05:44:34.426831
36111	1332	\N	\N	1623	1	standalone	2026-06-21 05:44:34.426831
36112	1332	\N	\N	3177	1	standalone	2026-06-21 05:44:34.426831
36113	1332	\N	\N	3358	1	standalone	2026-06-21 05:44:34.426831
36130	1332	\N	\N	366	1	standalone	2026-06-21 05:44:34.442906
36131	1332	\N	\N	1162	1	standalone	2026-06-21 05:44:34.442906
36132	1332	\N	\N	2948	1	standalone	2026-06-21 05:44:34.442906
36133	1332	\N	\N	2986	1	standalone	2026-06-21 05:44:34.442906
36134	1332	\N	\N	2982	1	standalone	2026-06-21 05:44:34.442906
34355	1333	\N	\N	198	1	standalone	2026-06-21 05:44:32.259261
34358	1333	\N	\N	952	1	standalone	2026-06-21 05:44:32.259261
34368	1333	\N	\N	203	1	standalone	2026-06-21 05:44:32.270428
34369	1333	\N	\N	1813	1	standalone	2026-06-21 05:44:32.270428
34379	1333	\N	\N	72	1	standalone	2026-06-21 05:44:32.287375
34391	1333	\N	\N	201	1	standalone	2026-06-21 05:44:32.29521
34393	1333	\N	\N	1636	1	standalone	2026-06-21 05:44:32.29521
34394	1333	\N	\N	2128	1	standalone	2026-06-21 05:44:32.29521
34395	1333	\N	\N	2129	1	standalone	2026-06-21 05:44:32.29521
35847	1333	\N	\N	16	1	standalone	2026-06-21 05:44:34.06894
35848	1333	\N	\N	811	1	standalone	2026-06-21 05:44:34.06894
36103	1333	\N	\N	211	1	standalone	2026-06-21 05:44:34.412677
36104	1333	\N	\N	1523	1	standalone	2026-06-21 05:44:34.412677
36105	1333	\N	\N	1385	1	standalone	2026-06-21 05:44:34.412677
34408	1334	\N	\N	3181	1	standalone	2026-06-21 05:44:32.329275
34409	1334	\N	\N	797	1	standalone	2026-06-21 05:44:32.329275
34418	1334	\N	\N	3118	1	standalone	2026-06-21 05:44:32.338592
34419	1334	\N	\N	2869	1	standalone	2026-06-21 05:44:32.338592
34421	1334	\N	\N	3281	1	standalone	2026-06-21 05:44:32.338592
34422	1334	\N	\N	2120	1	standalone	2026-06-21 05:44:32.338592
34428	1334	\N	\N	2809	1	standalone	2026-06-21 05:44:32.368217
34429	1334	\N	\N	2121	1	standalone	2026-06-21 05:44:32.368217
34430	1334	\N	\N	2122	1	standalone	2026-06-21 05:44:32.368217
34432	1334	\N	\N	2123	1	standalone	2026-06-21 05:44:32.376609
34433	1334	\N	\N	2835	1	standalone	2026-06-21 05:44:32.376609
34439	1334	\N	\N	627	1	standalone	2026-06-21 05:44:32.384845
34440	1334	\N	\N	630	1	standalone	2026-06-21 05:44:32.384845
34446	1334	\N	\N	2779	1	standalone	2026-06-21 05:44:32.39342
34447	1334	\N	\N	1695	1	standalone	2026-06-21 05:44:32.39342
34451	1334	\N	\N	3117	1	standalone	2026-06-21 05:44:32.39342
34456	1334	\N	\N	2810	1	standalone	2026-06-21 05:44:32.409573
34753	1335	\N	\N	2446	1	standalone	2026-06-21 05:44:32.800824
34755	1335	\N	\N	1164	1	standalone	2026-06-21 05:44:32.804632
34758	1335	\N	\N	1925	1	standalone	2026-06-21 05:44:32.811257
34759	1335	\N	\N	1167	1	standalone	2026-06-21 05:44:32.811257
34760	1335	\N	\N	331	1	standalone	2026-06-21 05:44:32.811257
36448	1335	\N	\N	623	1	standalone	2026-06-21 05:44:34.741485
36449	1335	\N	\N	1155	1	standalone	2026-06-21 05:44:34.741485
36451	1335	\N	\N	2021	1	standalone	2026-06-21 05:44:34.741485
36472	1335	\N	\N	1148	1	standalone	2026-06-21 05:44:34.789622
36474	1335	\N	\N	1150	1	standalone	2026-06-21 05:44:34.789622
36479	1335	\N	\N	2451	1	standalone	2026-06-21 05:44:34.789622
34812	1336	\N	\N	2926	1	standalone	2026-06-21 05:44:32.878253
35136	1336	\N	\N	3001	1	standalone	2026-06-21 05:44:33.22824
35137	1336	\N	\N	3023	1	standalone	2026-06-21 05:44:33.22824
35139	1336	\N	\N	2634	1	standalone	2026-06-21 05:44:33.22824
35140	1336	\N	\N	3011	1	standalone	2026-06-21 05:44:33.22824
35142	1336	\N	\N	965	1	standalone	2026-06-21 05:44:33.244994
35143	1336	\N	\N	128	1	standalone	2026-06-21 05:44:33.244994
35150	1336	\N	\N	1632	1	standalone	2026-06-21 05:44:33.244994
35160	1336	\N	\N	2819	1	standalone	2026-06-21 05:44:33.263718
35161	1336	\N	\N	2029	1	standalone	2026-06-21 05:44:33.263718
35162	1336	\N	\N	2030	1	standalone	2026-06-21 05:44:33.263718
35164	1336	\N	\N	2820	1	standalone	2026-06-21 05:44:33.276232
35165	1336	\N	\N	3002	1	standalone	2026-06-21 05:44:33.276232
35169	1336	\N	\N	3024	1	standalone	2026-06-21 05:44:33.276232
35171	1336	\N	\N	2212	1	standalone	2026-06-21 05:44:33.292264
35180	1336	\N	\N	3020	1	standalone	2026-06-21 05:44:33.292264
35187	1336	\N	\N	598	1	standalone	2026-06-21 05:44:33.328484
35408	1338	\N	\N	700	1	standalone	2026-06-21 05:44:33.623313
35409	1338	\N	\N	967	1	standalone	2026-06-21 05:44:33.623313
35410	1338	\N	\N	611	1	standalone	2026-06-21 05:44:33.623313
35412	1338	\N	\N	2385	1	standalone	2026-06-21 05:44:33.623313
35417	1338	\N	\N	2173	1	standalone	2026-06-21 05:44:33.639104
36200	1338	\N	\N	1849	1	standalone	2026-06-21 05:44:34.521835
36201	1338	\N	\N	701	1	standalone	2026-06-21 05:44:34.521835
36207	1338	\N	\N	931	1	standalone	2026-06-21 05:44:34.532633
36212	1338	\N	\N	2057	1	standalone	2026-06-21 05:44:34.540793
36215	1338	\N	\N	2775	1	standalone	2026-06-21 05:44:34.548301
36217	1338	\N	\N	2062	1	standalone	2026-06-21 05:44:34.548301
36302	1338	\N	\N	2605	1	standalone	2026-06-21 05:44:34.637151
36304	1338	\N	\N	616	1	standalone	2026-06-21 05:44:34.637151
36305	1338	\N	\N	529	1	standalone	2026-06-21 05:44:34.637151
36432	1338	\N	\N	383	1	standalone	2026-06-21 05:44:34.741485
36435	1338	\N	\N	2216	1	standalone	2026-06-21 05:44:34.741485
36436	1338	\N	\N	2218	1	standalone	2026-06-21 05:44:34.741485
36481	1338	\N	\N	3310	1	standalone	2026-06-21 05:44:34.798519
36482	1338	\N	\N	1811	1	standalone	2026-06-21 05:44:34.798519
36483	1338	\N	\N	1206	1	standalone	2026-06-21 05:44:34.798519
36484	1338	\N	\N	1207	1	standalone	2026-06-21 05:44:34.798519
36485	1338	\N	\N	2179	1	standalone	2026-06-21 05:44:34.798519
36488	1338	\N	\N	481	1	standalone	2026-06-21 05:44:34.805749
36489	1338	\N	\N	484	1	standalone	2026-06-21 05:44:34.805749
36497	1338	\N	\N	487	1	standalone	2026-06-21 05:44:34.853365
34525	1322	\N	\N	2365	1	domain	2026-06-21 05:44:32.524103
37793	1322	4481	\N	\N	1	domain	2026-06-21 08:17:38.068169
37794	1322	4482	\N	\N	1	domain	2026-06-21 08:17:38.075533
35560	1322	\N	\N	2934	1	domain	2026-06-21 05:44:33.808149
37795	1322	4483	\N	\N	1	domain	2026-06-21 08:17:38.082004
34869	1322	\N	\N	1743	1	domain	2026-06-21 05:44:32.958835
37363	1322	\N	\N	1543	1	domain	2026-06-21 05:44:35.269741
37796	1322	4484	\N	\N	1	domain	2026-06-21 08:17:38.087005
37797	1322	4485	\N	\N	1	domain	2026-06-21 08:17:38.094386
37798	1322	4486	\N	\N	1	domain	2026-06-21 08:17:38.098437
37799	1322	4487	\N	\N	1	domain	2026-06-21 08:17:38.102793
37800	1322	4488	\N	\N	1	domain	2026-06-21 08:17:38.107801
34968	1322	\N	\N	806	1	domain	2026-06-21 05:44:32.991288
37801	1322	4489	\N	\N	1	domain	2026-06-21 08:17:38.112275
36524	1322	\N	\N	1740	1	domain	2026-06-21 05:44:35.261598
37802	1322	4490	\N	\N	1	domain	2026-06-21 08:17:38.117275
36564	1322	\N	\N	948	1	domain	2026-06-21 05:44:35.261598
37803	1322	4491	\N	\N	1	domain	2026-06-21 08:17:38.123788
37804	1322	4492	\N	\N	1	domain	2026-06-21 08:17:38.127709
37805	1322	4493	\N	\N	1	domain	2026-06-21 08:17:38.13211
33796	1323	\N	\N	1898	1	domain	2026-06-21 05:44:31.539574
33797	1323	\N	\N	1899	1	domain	2026-06-21 05:44:31.539574
33798	1323	\N	\N	1900	1	domain	2026-06-21 05:44:31.539574
33800	1323	\N	\N	1902	1	domain	2026-06-21 05:44:31.539574
33808	1323	\N	\N	1251	1	domain	2026-06-21 05:44:31.539574
37806	1323	4494	\N	\N	1	domain	2026-06-21 08:17:38.139118
37807	1325	4495	\N	\N	1	domain	2026-06-21 08:17:38.143526
35914	1326	\N	\N	1842	1	domain	2026-06-21 05:44:34.16924
35930	1326	\N	\N	3132	1	domain	2026-06-21 05:44:34.16924
35941	1326	\N	\N	3236	1	domain	2026-06-21 05:44:34.16924
35947	1326	\N	\N	840	1	domain	2026-06-21 05:44:34.16924
35953	1326	\N	\N	119	1	domain	2026-06-21 05:44:34.16924
37808	1326	4496	\N	\N	1	domain	2026-06-21 08:17:38.149519
35929	1326	\N	\N	771	1	domain	2026-06-21 05:44:34.16924
37809	1326	4497	\N	\N	1	domain	2026-06-21 08:17:38.152756
35942	1326	\N	\N	3237	1	domain	2026-06-21 05:44:34.16924
35948	1326	\N	\N	841	1	domain	2026-06-21 05:44:34.16924
35954	1326	\N	\N	120	1	domain	2026-06-21 05:44:34.16924
37810	1326	4498	\N	\N	1	domain	2026-06-21 08:17:38.160275
33908	1327	\N	\N	2589	1	domain	2026-06-21 05:44:31.719259
37811	1327	4499	\N	\N	1	domain	2026-06-21 08:17:38.163753
33915	1327	\N	\N	10	1	domain	2026-06-21 05:44:31.728048
37812	1327	4500	\N	\N	1	domain	2026-06-21 08:17:38.167773
33952	1327	\N	\N	1426	1	domain	2026-06-21 05:44:31.797638
37813	1327	4501	\N	\N	1	domain	2026-06-21 08:17:38.175101
34133	1327	\N	\N	3224	1	domain	2026-06-21 05:44:32.069891
34985	1327	\N	\N	79	1	domain	2026-06-21 05:44:33.023718
37814	1327	4502	\N	\N	1	domain	2026-06-21 08:17:38.179101
34160	1327	\N	\N	1687	1	domain	2026-06-21 05:44:32.100033
37815	1327	4503	\N	\N	1	domain	2026-06-21 08:17:38.182612
37816	1327	4504	\N	\N	1	domain	2026-06-21 08:17:38.189519
37817	1327	4505	\N	\N	1	domain	2026-06-21 08:17:38.193898
37818	1327	4506	\N	\N	1	domain	2026-06-21 08:17:38.197899
37819	1327	4507	\N	\N	1	domain	2026-06-21 08:17:38.2009
34038	1328	\N	\N	62	1	domain	2026-06-21 05:44:31.932216
37820	1328	4508	\N	\N	1	domain	2026-06-21 08:17:38.207293
35823	1328	\N	\N	3211	1	domain	2026-06-21 05:44:34.017539
37821	1328	4509	\N	\N	1	domain	2026-06-21 08:17:38.211294
37822	1328	4510	\N	\N	1	domain	2026-06-21 08:17:38.227038
37823	1328	4511	\N	\N	1	domain	2026-06-21 08:17:38.231051
37824	1329	4512	\N	\N	1	domain	2026-06-21 08:17:38.234402
37825	1329	4513	\N	\N	1	domain	2026-06-21 08:17:38.241397
35615	1329	\N	\N	1700	1	domain	2026-06-21 05:44:33.824865
37343	1329	\N	\N	1529	1	domain	2026-06-21 05:44:35.269741
37826	1329	4514	\N	\N	1	domain	2026-06-21 08:17:38.245863
34923	1329	\N	\N	643	1	domain	2026-06-21 05:44:32.991288
35486	1329	\N	\N	895	1	domain	2026-06-21 05:44:33.713754
37827	1329	4515	\N	\N	1	domain	2026-06-21 08:17:38.249918
37828	1329	4516	\N	\N	1	domain	2026-06-21 08:17:38.25543
35467	1329	\N	\N	976	1	domain	2026-06-21 05:44:33.713754
35600	1329	\N	\N	802	1	domain	2026-06-21 05:44:33.824865
37829	1329	4517	\N	\N	1	domain	2026-06-21 08:17:38.260971
35468	1329	\N	\N	3350	1	domain	2026-06-21 05:44:33.713754
35477	1329	\N	\N	861	1	domain	2026-06-21 05:44:33.713754
35481	1329	\N	\N	132	1	domain	2026-06-21 05:44:33.713754
35485	1329	\N	\N	1730	1	domain	2026-06-21 05:44:33.713754
37830	1329	4518	\N	\N	1	domain	2026-06-21 08:17:38.266527
35476	1329	\N	\N	853	1	domain	2026-06-21 05:44:33.713754
36991	1329	\N	\N	115	1	domain	2026-06-21 05:44:35.269741
37831	1329	4519	\N	\N	1	domain	2026-06-21 08:17:38.271418
35478	1329	\N	\N	862	1	domain	2026-06-21 05:44:33.713754
35482	1329	\N	\N	133	1	domain	2026-06-21 05:44:33.713754
37832	1329	4520	\N	\N	1	domain	2026-06-21 08:17:38.275718
35479	1329	\N	\N	863	1	domain	2026-06-21 05:44:33.713754
35483	1329	\N	\N	134	1	domain	2026-06-21 05:44:33.713754
37833	1329	4521	\N	\N	1	domain	2026-06-21 08:17:38.279718
35480	1329	\N	\N	864	1	domain	2026-06-21 05:44:33.713754
35484	1329	\N	\N	135	1	domain	2026-06-21 05:44:33.713754
37834	1329	4522	\N	\N	1	domain	2026-06-21 08:17:38.284102
35596	1329	\N	\N	1586	1	domain	2026-06-21 05:44:33.824865
35601	1329	\N	\N	803	1	domain	2026-06-21 05:44:33.824865
37835	1329	4523	\N	\N	1	domain	2026-06-21 08:17:38.290109
35617	1329	\N	\N	899	1	domain	2026-06-21 05:44:33.824865
36631	1329	\N	\N	668	1	domain	2026-06-21 05:44:35.269741
37836	1329	4524	\N	\N	1	domain	2026-06-21 08:17:38.294435
35632	1329	\N	\N	957	1	domain	2026-06-21 05:44:33.853972
35635	1329	\N	\N	3339	1	domain	2026-06-21 05:44:33.853972
36438	1329	\N	\N	1624	1	domain	2026-06-21 05:44:34.741485
36442	1329	\N	\N	846	1	domain	2026-06-21 05:44:34.741485
36443	1329	\N	\N	847	1	domain	2026-06-21 05:44:34.741485
37838	1329	4526	\N	\N	1	domain	2026-06-21 08:17:38.350549
36439	1329	\N	\N	637	1	domain	2026-06-21 05:44:34.741485
37117	1329	\N	\N	1453	1	domain	2026-06-21 05:44:35.269741
37839	1329	4527	\N	\N	1	domain	2026-06-21 08:17:38.355805
36536	1329	\N	\N	3223	1	domain	2026-06-21 05:44:35.261598
36547	1329	\N	\N	2585	1	domain	2026-06-21 05:44:35.261598
36643	1329	\N	\N	26	1	domain	2026-06-21 05:44:35.269741
36990	1329	\N	\N	844	1	domain	2026-06-21 05:44:35.269741
37840	1329	4528	\N	\N	1	domain	2026-06-21 08:17:38.360612
36721	1329	\N	\N	793	1	domain	2026-06-21 05:44:35.269741
36838	1329	\N	\N	986	1	domain	2026-06-21 05:44:35.269741
37841	1329	4529	\N	\N	1	domain	2026-06-21 08:17:38.364203
36878	1329	\N	\N	3239	1	domain	2026-06-21 05:44:35.269741
37055	1329	\N	\N	868	1	domain	2026-06-21 05:44:35.269741
37068	1329	\N	\N	139	1	domain	2026-06-21 05:44:35.269741
37842	1329	4530	\N	\N	1	domain	2026-06-21 08:17:38.36824
36924	1329	\N	\N	111	1	domain	2026-06-21 05:44:35.269741
37043	1329	\N	\N	849	1	domain	2026-06-21 05:44:35.269741
37843	1329	4531	\N	\N	1	domain	2026-06-21 08:17:38.374578
36941	1329	\N	\N	112	1	domain	2026-06-21 05:44:35.269741
37844	1329	4532	\N	\N	1	domain	2026-06-21 08:17:38.377575
35055	1330	\N	\N	3234	1	domain	2026-06-21 05:44:33.105449
35059	1330	\N	\N	261	1	domain	2026-06-21 05:44:33.122004
37845	1330	4533	\N	\N	1	domain	2026-06-21 08:17:38.381996
36155	1330	\N	\N	960	1	domain	2026-06-21 05:44:34.459896
36187	1330	\N	\N	1652	1	domain	2026-06-21 05:44:34.508492
37846	1330	4534	\N	\N	1	domain	2026-06-21 08:17:38.384994
37847	1331	4535	\N	\N	1	domain	2026-06-21 08:17:38.392466
37848	1331	4536	\N	\N	1	domain	2026-06-21 08:17:38.395471
37849	1331	4537	\N	\N	1	domain	2026-06-21 08:17:38.39949
37850	1331	4538	\N	\N	1	domain	2026-06-21 08:17:38.402684
37851	1331	4539	\N	\N	1	domain	2026-06-21 08:17:38.40768
37852	1331	4540	\N	\N	1	domain	2026-06-21 08:17:38.41068
37853	1331	4541	\N	\N	1	domain	2026-06-21 08:17:38.413998
37854	1331	4542	\N	\N	1	domain	2026-06-21 08:17:38.416999
34308	1331	\N	\N	880	1	domain	2026-06-21 05:44:32.191088
34311	1331	\N	\N	160	1	domain	2026-06-21 05:44:32.191088
34312	1331	\N	\N	161	1	domain	2026-06-21 05:44:32.191088
37855	1331	4543	\N	\N	1	domain	2026-06-21 08:17:38.423319
37856	1331	4544	\N	\N	1	domain	2026-06-21 08:17:38.427318
37857	1331	4545	\N	\N	1	domain	2026-06-21 08:17:38.430315
37858	1331	4546	\N	\N	1	domain	2026-06-21 08:17:38.433534
37859	1332	4547	\N	\N	1	domain	2026-06-21 08:17:38.438537
35857	1333	\N	\N	2908	1	domain	2026-06-21 05:44:34.080816
37860	1333	4548	\N	\N	1	domain	2026-06-21 08:17:38.442903
36329	1333	\N	\N	1138	1	domain	2026-06-21 05:44:34.652893
36334	1333	\N	\N	3014	1	domain	2026-06-21 05:44:34.652893
37861	1333	4549	\N	\N	1	domain	2026-06-21 08:17:38.446867
36330	1333	\N	\N	1056	1	domain	2026-06-21 05:44:34.652893
36331	1333	\N	\N	980	1	domain	2026-06-21 05:44:34.652893
37862	1333	4550	\N	\N	1	domain	2026-06-21 08:17:38.450976
35860	1334	\N	\N	1551	1	domain	2026-06-21 05:44:34.080816
35862	1334	\N	\N	1824	1	domain	2026-06-21 05:44:34.080816
35865	1334	\N	\N	1735	1	domain	2026-06-21 05:44:34.080816
35866	1334	\N	\N	145	1	domain	2026-06-21 05:44:34.080816
35867	1334	\N	\N	1736	1	domain	2026-06-21 05:44:34.080816
36704	1334	\N	\N	964	1	domain	2026-06-21 05:44:35.269741
37863	1334	4551	\N	\N	1	domain	2026-06-21 08:17:38.460881
36965	1334	\N	\N	1032	1	domain	2026-06-21 05:44:35.269741
37080	1334	\N	\N	141	1	domain	2026-06-21 05:44:35.269741
37864	1334	4552	\N	\N	1	domain	2026-06-21 08:17:38.465256
37295	1334	\N	\N	1807	1	domain	2026-06-21 05:44:35.269741
34414	1334	\N	\N	1122	1	domain	2026-06-21 05:44:32.338592
37865	1334	4553	\N	\N	1	domain	2026-06-21 08:17:38.471257
34761	1335	\N	\N	3343	1	domain	2026-06-21 05:44:32.811257
35731	1335	\N	\N	1031	1	domain	2026-06-21 05:44:33.92599
37355	1335	\N	\N	1536	1	domain	2026-06-21 05:44:35.269741
37866	1335	4554	\N	\N	1	domain	2026-06-21 08:17:38.477921
35715	1335	\N	\N	3390	1	domain	2026-06-21 05:44:33.92599
35717	1335	\N	\N	3152	1	domain	2026-06-21 05:44:33.92599
35718	1335	\N	\N	2832	1	domain	2026-06-21 05:44:33.92599
35740	1335	\N	\N	335	1	domain	2026-06-21 05:44:33.92599
35752	1335	\N	\N	1304	1	domain	2026-06-21 05:44:33.92599
37867	1335	4555	\N	\N	1	domain	2026-06-21 08:17:38.485291
35732	1335	\N	\N	91	1	domain	2026-06-21 05:44:33.92599
36974	1335	\N	\N	836	1	domain	2026-06-21 05:44:35.269741
37868	1335	4556	\N	\N	1	domain	2026-06-21 08:17:38.491371
35743	1335	\N	\N	347	1	domain	2026-06-21 05:44:33.92599
35746	1335	\N	\N	350	1	domain	2026-06-21 05:44:33.92599
35748	1335	\N	\N	2025	1	domain	2026-06-21 05:44:33.92599
37869	1335	4557	\N	\N	1	domain	2026-06-21 08:17:38.496623
35756	1335	\N	\N	1317	1	domain	2026-06-21 05:44:33.92599
35759	1335	\N	\N	2406	1	domain	2026-06-21 05:44:33.92599
37870	1335	4558	\N	\N	1	domain	2026-06-21 08:17:38.500619
36687	1335	\N	\N	3397	1	domain	2026-06-21 05:44:35.269741
37069	1335	\N	\N	1729	1	domain	2026-06-21 05:44:35.269741
37871	1335	4559	\N	\N	1	domain	2026-06-21 08:17:38.508
34772	1336	\N	\N	1836	1	domain	2026-06-21 05:44:32.829587
35158	1336	\N	\N	3279	1	domain	2026-06-21 05:44:33.263718
35194	1336	\N	\N	1631	1	domain	2026-06-21 05:44:33.328484
37872	1336	4560	\N	\N	1	domain	2026-06-21 08:17:38.51254
36234	1336	\N	\N	2187	1	domain	2026-06-21 05:44:34.566037
36233	1336	\N	\N	2973	1	domain	2026-06-21 05:44:34.566037
37873	1336	4561	\N	\N	1	domain	2026-06-21 08:17:38.516536
37874	1337	4562	\N	\N	1	domain	2026-06-21 08:17:38.521935
36269	1338	\N	\N	1564	1	domain	2026-06-21 05:44:34.620015
36274	1338	\N	\N	195	1	domain	2026-06-21 05:44:34.620015
36279	1338	\N	\N	1659	1	domain	2026-06-21 05:44:34.620015
37875	1338	4563	\N	\N	1	domain	2026-06-21 08:17:38.53926
36273	1338	\N	\N	615	1	domain	2026-06-21 05:44:34.620015
36298	1338	\N	\N	2840	1	domain	2026-06-21 05:44:34.620015
37876	1338	4564	\N	\N	1	domain	2026-06-21 08:17:38.543576
36275	1338	\N	\N	988	1	domain	2026-06-21 05:44:34.620015
36278	1338	\N	\N	3163	1	domain	2026-06-21 05:44:34.620015
37877	1338	4565	\N	\N	1	domain	2026-06-21 08:17:38.546572
36277	1338	\N	\N	3227	1	domain	2026-06-21 05:44:34.620015
36282	1338	\N	\N	874	1	domain	2026-06-21 05:44:34.620015
37878	1338	4566	\N	\N	1	domain	2026-06-21 08:17:38.550571
36281	1338	\N	\N	873	1	domain	2026-06-21 05:44:34.620015
36289	1338	\N	\N	157	1	domain	2026-06-21 05:44:34.620015
37879	1338	4567	\N	\N	1	domain	2026-06-21 08:17:38.554896
36523	1339	\N	\N	1055	1	domain	2026-06-21 05:44:35.261598
36576	1339	\N	\N	919	1	domain	2026-06-21 05:44:35.269741
37880	1339	4568	\N	\N	1	domain	2026-06-21 08:17:38.559472
34397	1322	\N	\N	945	1	domain	2026-06-21 05:44:32.304182
34398	1322	\N	\N	2580	1	domain	2026-06-21 05:44:32.304182
34400	1322	\N	\N	2740	1	domain	2026-06-21 05:44:32.304182
34404	1322	\N	\N	774	1	domain	2026-06-21 05:44:32.312033
37881	1322	4569	\N	\N	1	domain	2026-06-21 08:17:38.563778
34460	1322	\N	\N	1067	1	domain	2026-06-21 05:44:32.453087
34462	1322	\N	\N	943	1	domain	2026-06-21 05:44:32.453087
37882	1322	4570	\N	\N	1	domain	2026-06-21 08:17:38.567776
34466	1322	\N	\N	1854	1	domain	2026-06-21 05:44:32.458243
34469	1322	\N	\N	197	1	domain	2026-06-21 05:44:32.458243
34470	1322	\N	\N	2183	1	domain	2026-06-21 05:44:32.458243
37883	1322	4571	\N	\N	1	domain	2026-06-21 08:17:38.573152
34495	1322	\N	\N	925	1	domain	2026-06-21 05:44:32.491539
34497	1322	\N	\N	1703	1	domain	2026-06-21 05:44:32.491539
34498	1322	\N	\N	3355	1	domain	2026-06-21 05:44:32.491539
34499	1322	\N	\N	3171	1	domain	2026-06-21 05:44:32.491539
34500	1322	\N	\N	3110	1	domain	2026-06-21 05:44:32.491539
37884	1322	4572	\N	\N	1	domain	2026-06-21 08:17:38.580134
35826	1322	\N	\N	3187	1	domain	2026-06-21 05:44:34.047416
35827	1322	\N	\N	953	1	domain	2026-06-21 05:44:34.047416
35829	1322	\N	\N	812	1	domain	2026-06-21 05:44:34.047416
37885	1322	4573	\N	\N	1	domain	2026-06-21 08:17:38.584444
36137	1322	\N	\N	3179	1	domain	2026-06-21 05:44:34.459896
36138	1322	\N	\N	788	1	domain	2026-06-21 05:44:34.459896
37886	1322	4574	\N	\N	1	domain	2026-06-21 08:17:38.599928
35531	1323	\N	\N	3136	1	domain	2026-06-21 05:44:33.771784
35496	1323	\N	\N	179	1	domain	2026-06-21 05:44:33.727297
35508	1323	\N	\N	734	1	domain	2026-06-21 05:44:33.743468
37887	1323	4575	\N	\N	1	domain	2026-06-21 08:17:38.607245
33789	1323	\N	\N	2591	1	domain	2026-06-21 05:44:31.539574
33790	1323	\N	\N	180	1	domain	2026-06-21 05:44:31.539574
33791	1323	\N	\N	3205	1	domain	2026-06-21 05:44:31.539574
33792	1323	\N	\N	866	1	domain	2026-06-21 05:44:31.539574
33793	1323	\N	\N	137	1	domain	2026-06-21 05:44:31.539574
37888	1323	4576	\N	\N	1	domain	2026-06-21 08:17:38.612559
33804	1323	\N	\N	3307	1	domain	2026-06-21 05:44:31.539574
35500	1323	\N	\N	2375	1	domain	2026-06-21 05:44:33.727297
37889	1323	4577	\N	\N	1	domain	2026-06-21 08:17:38.616563
35498	1323	\N	\N	1832	1	domain	2026-06-21 05:44:33.727297
35501	1323	\N	\N	1723	1	domain	2026-06-21 05:44:33.727297
37890	1323	4578	\N	\N	1	domain	2026-06-21 08:17:38.622562
34644	1324	\N	\N	3192	1	domain	2026-06-21 05:44:32.652311
34646	1324	\N	\N	1830	1	domain	2026-06-21 05:44:32.652311
34647	1324	\N	\N	1125	1	domain	2026-06-21 05:44:32.652311
34648	1324	\N	\N	3357	1	domain	2026-06-21 05:44:32.652311
34695	1324	\N	\N	5	1	domain	2026-06-21 05:44:32.746953
34696	1324	\N	\N	1608	1	domain	2026-06-21 05:44:32.746953
34697	1324	\N	\N	3389	1	domain	2026-06-21 05:44:32.746953
34698	1324	\N	\N	778	1	domain	2026-06-21 05:44:32.746953
34700	1324	\N	\N	983	1	domain	2026-06-21 05:44:32.746953
34710	1324	\N	\N	1539	1	domain	2026-06-21 05:44:32.746953
37891	1324	4579	\N	\N	1	domain	2026-06-21 08:17:38.631905
34640	1324	\N	\N	2935	1	domain	2026-06-21 05:44:32.621305
34641	1324	\N	\N	2045	1	domain	2026-06-21 05:44:32.621305
37892	1324	4580	\N	\N	1	domain	2026-06-21 08:17:38.635232
34343	1325	\N	\N	775	1	domain	2026-06-21 05:44:32.246697
34344	1325	\N	\N	981	1	domain	2026-06-21 05:44:32.246697
37893	1325	4581	\N	\N	1	domain	2026-06-21 08:17:38.640867
37894	1325	4582	\N	\N	1	domain	2026-06-21 08:17:38.645259
36040	1325	\N	\N	3190	1	domain	2026-06-21 05:44:34.274388
36041	1325	\N	\N	776	1	domain	2026-06-21 05:44:34.274388
36042	1325	\N	\N	982	1	domain	2026-06-21 05:44:34.274388
37895	1325	4583	\N	\N	1	domain	2026-06-21 08:17:38.64925
33865	1326	\N	\N	2596	1	domain	2026-06-21 05:44:31.654802
33866	1326	\N	\N	185	1	domain	2026-06-21 05:44:31.654802
33867	1326	\N	\N	3396	1	domain	2026-06-21 05:44:31.654802
33903	1326	\N	\N	1009	1	domain	2026-06-21 05:44:31.705238
37896	1326	4584	\N	\N	1	domain	2026-06-21 08:17:38.65454
36014	1326	\N	\N	1602	1	domain	2026-06-21 05:44:34.225412
36017	1326	\N	\N	2602	1	domain	2026-06-21 05:44:34.242744
36018	1326	\N	\N	1243	1	domain	2026-06-21 05:44:34.242744
36020	1326	\N	\N	3130	1	domain	2026-06-21 05:44:34.255245
36021	1326	\N	\N	2931	1	domain	2026-06-21 05:44:34.255245
37897	1326	4585	\N	\N	1	domain	2026-06-21 08:17:38.661054
36093	1326	\N	\N	1845	1	domain	2026-06-21 05:44:34.394392
36094	1326	\N	\N	3148	1	domain	2026-06-21 05:44:34.394392
37898	1326	4586	\N	\N	1	domain	2026-06-21 08:17:38.664524
36096	1326	\N	\N	760	1	domain	2026-06-21 05:44:34.405374
36098	1326	\N	\N	1024	1	domain	2026-06-21 05:44:34.405374
36099	1326	\N	\N	121	1	domain	2026-06-21 05:44:34.405374
37899	1326	4587	\N	\N	1	domain	2026-06-21 08:17:38.669524
36097	1326	\N	\N	2600	1	domain	2026-06-21 05:44:34.405374
36100	1326	\N	\N	1268	1	domain	2026-06-21 05:44:34.405374
37900	1326	4588	\N	\N	1	domain	2026-06-21 08:17:38.675043
33912	1327	\N	\N	177	1	domain	2026-06-21 05:44:31.728048
33913	1327	\N	\N	1238	1	domain	2026-06-21 05:44:31.728048
37901	1327	4589	\N	\N	1	domain	2026-06-21 08:17:38.678044
33917	1327	\N	\N	11	1	domain	2026-06-21 05:44:31.762147
33919	1327	\N	\N	782	1	domain	2026-06-21 05:44:31.762147
33923	1327	\N	\N	961	1	domain	2026-06-21 05:44:31.771806
33934	1327	\N	\N	3128	1	domain	2026-06-21 05:44:31.797638
37902	1327	4590	\N	\N	1	domain	2026-06-21 08:17:38.682379
33926	1327	\N	\N	1597	1	domain	2026-06-21 05:44:31.778603
33927	1327	\N	\N	1828	1	domain	2026-06-21 05:44:31.778603
37903	1327	4591	\N	\N	1	domain	2026-06-21 08:17:38.68838
34079	1327	\N	\N	749	1	domain	2026-06-21 05:44:31.995433
34080	1327	\N	\N	174	1	domain	2026-06-21 05:44:31.995433
34081	1327	\N	\N	2586	1	domain	2026-06-21 05:44:31.995433
34082	1327	\N	\N	63	1	domain	2026-06-21 05:44:31.995433
34083	1327	\N	\N	3214	1	domain	2026-06-21 05:44:31.995433
34084	1327	\N	\N	2243	1	domain	2026-06-21 05:44:31.995433
34164	1327	\N	\N	958	1	domain	2026-06-21 05:44:32.120663
37904	1327	4592	\N	\N	1	domain	2026-06-21 08:17:38.69465
34108	1327	\N	\N	80	1	domain	2026-06-21 05:44:32.028186
34144	1327	\N	\N	1005	1	domain	2026-06-21 05:44:32.091899
37905	1327	4593	\N	\N	1	domain	2026-06-21 08:17:38.698649
34136	1327	\N	\N	869	1	domain	2026-06-21 05:44:32.077232
34137	1327	\N	\N	140	1	domain	2026-06-21 05:44:32.077232
37906	1327	4594	\N	\N	1	domain	2026-06-21 08:17:38.701666
34720	1327	\N	\N	2587	1	domain	2026-06-21 05:44:32.760826
34721	1327	\N	\N	175	1	domain	2026-06-21 05:44:32.760826
34729	1327	\N	\N	765	1	domain	2026-06-21 05:44:32.779055
34730	1327	\N	\N	78	1	domain	2026-06-21 05:44:32.779055
37907	1327	4595	\N	\N	1	domain	2026-06-21 08:17:38.708951
34840	1327	\N	\N	750	1	domain	2026-06-21 05:44:32.913459
34841	1327	\N	\N	64	1	domain	2026-06-21 05:44:32.913459
37908	1327	4596	\N	\N	1	domain	2026-06-21 08:17:38.712249
34843	1327	\N	\N	946	1	domain	2026-06-21 05:44:32.928014
34845	1327	\N	\N	3200	1	domain	2026-06-21 05:44:32.928014
34846	1327	\N	\N	830	1	domain	2026-06-21 05:44:32.928014
34847	1327	\N	\N	88	1	domain	2026-06-21 05:44:32.928014
34851	1327	\N	\N	3328	1	domain	2026-06-21 05:44:32.93927
37909	1327	4597	\N	\N	1	domain	2026-06-21 08:17:38.717775
34972	1327	\N	\N	2588	1	domain	2026-06-21 05:44:33.0073
34973	1327	\N	\N	176	1	domain	2026-06-21 05:44:33.0073
34974	1327	\N	\N	1560	1	domain	2026-06-21 05:44:33.0073
34977	1327	\N	\N	3319	1	domain	2026-06-21 05:44:33.023718
34979	1327	\N	\N	1004	1	domain	2026-06-21 05:44:33.023718
34983	1327	\N	\N	1241	1	domain	2026-06-21 05:44:33.023718
37910	1327	4598	\N	\N	1	domain	2026-06-21 08:17:38.725186
34976	1327	\N	\N	751	1	domain	2026-06-21 05:44:33.023718
34980	1327	\N	\N	65	1	domain	2026-06-21 05:44:33.023718
37911	1327	4599	\N	\N	1	domain	2026-06-21 08:17:38.729185
35377	1327	\N	\N	699	1	domain	2026-06-21 05:44:33.581816
35378	1327	\N	\N	766	1	domain	2026-06-21 05:44:33.581816
35383	1327	\N	\N	3384	1	domain	2026-06-21 05:44:33.590075
35385	1327	\N	\N	1236	1	domain	2026-06-21 05:44:33.590075
37912	1327	4600	\N	\N	1	domain	2026-06-21 08:17:38.754615
35401	1327	\N	\N	769	1	domain	2026-06-21 05:44:33.623313
35404	1327	\N	\N	3218	1	domain	2026-06-21 05:44:33.623313
37913	1327	4601	\N	\N	1	domain	2026-06-21 08:17:38.758124
36125	1327	\N	\N	1585	1	domain	2026-06-21 05:44:34.442906
36128	1327	\N	\N	1537	1	domain	2026-06-21 05:44:34.442906
37914	1327	4602	\N	\N	1	domain	2026-06-21 08:17:38.761134
33979	1328	\N	\N	3207	1	domain	2026-06-21 05:44:31.861214
33981	1328	\N	\N	816	1	domain	2026-06-21 05:44:31.861214
33982	1328	\N	\N	2697	1	domain	2026-06-21 05:44:31.861214
35807	1328	\N	\N	990	1	domain	2026-06-21 05:44:34.007397
37915	1328	4603	\N	\N	1	domain	2026-06-21 08:17:38.766447
33980	1328	\N	\N	2592	1	domain	2026-06-21 05:44:31.861214
35797	1328	\N	\N	3321	1	domain	2026-06-21 05:44:33.985238
35798	1328	\N	\N	1232	1	domain	2026-06-21 05:44:33.985238
35801	1328	\N	\N	3269	1	domain	2026-06-21 05:44:33.992205
35805	1328	\N	\N	1826	1	domain	2026-06-21 05:44:34.007397
35806	1328	\N	\N	3131	1	domain	2026-06-21 05:44:34.007397
35809	1328	\N	\N	1674	1	domain	2026-06-21 05:44:34.007397
35817	1328	\N	\N	1675	1	domain	2026-06-21 05:44:34.017539
37916	1328	4604	\N	\N	1	domain	2026-06-21 08:17:38.773885
33987	1328	\N	\N	819	1	domain	2026-06-21 05:44:31.876739
34006	1328	\N	\N	994	1	domain	2026-06-21 05:44:31.888851
34007	1328	\N	\N	53	1	domain	2026-06-21 05:44:31.888851
37917	1328	4605	\N	\N	1	domain	2026-06-21 08:17:38.778884
33989	1328	\N	\N	181	1	domain	2026-06-21 05:44:31.876739
34036	1328	\N	\N	46	1	domain	2026-06-21 05:44:31.932216
34037	1328	\N	\N	815	1	domain	2026-06-21 05:44:31.932216
37918	1328	4606	\N	\N	1	domain	2026-06-21 08:17:38.782703
33991	1328	\N	\N	1576	1	domain	2026-06-21 05:44:31.876739
34052	1328	\N	\N	2919	1	domain	2026-06-21 05:44:31.948158
37919	1328	4607	\N	\N	1	domain	2026-06-21 08:17:38.786706
33995	1328	\N	\N	2593	1	domain	2026-06-21 05:44:31.888851
33997	1328	\N	\N	996	1	domain	2026-06-21 05:44:31.888851
33998	1328	\N	\N	56	1	domain	2026-06-21 05:44:31.888851
37920	1328	4608	\N	\N	1	domain	2026-06-21 08:17:38.791702
34004	1328	\N	\N	3208	1	domain	2026-06-21 05:44:31.888851
34044	1328	\N	\N	991	1	domain	2026-06-21 05:44:31.948158
34049	1328	\N	\N	817	1	domain	2026-06-21 05:44:31.948158
37921	1328	4609	\N	\N	1	domain	2026-06-21 08:17:38.797061
34011	1328	\N	\N	3209	1	domain	2026-06-21 05:44:31.903226
34013	1328	\N	\N	51	1	domain	2026-06-21 05:44:31.903226
37922	1328	4610	\N	\N	1	domain	2026-06-21 08:17:38.800061
34012	1328	\N	\N	993	1	domain	2026-06-21 05:44:31.903226
34014	1328	\N	\N	818	1	domain	2026-06-21 05:44:31.903226
37923	1328	4611	\N	\N	1	domain	2026-06-21 08:17:38.804329
34024	1328	\N	\N	59	1	domain	2026-06-21 05:44:31.917841
34025	1328	\N	\N	823	1	domain	2026-06-21 05:44:31.917841
36777	1328	\N	\N	3213	1	domain	2026-06-21 05:44:35.269741
36876	1328	\N	\N	1000	1	domain	2026-06-21 05:44:35.269741
37924	1328	4612	\N	\N	1	domain	2026-06-21 08:17:38.809328
36340	1328	\N	\N	28	1	domain	2026-06-21 05:44:34.661431
36341	1328	\N	\N	29	1	domain	2026-06-21 05:44:34.661431
36343	1328	\N	\N	842	1	domain	2026-06-21 05:44:34.661431
37925	1328	4613	\N	\N	1	domain	2026-06-21 08:17:38.813624
36457	1328	\N	\N	1231	1	domain	2026-06-21 05:44:34.757386
36458	1328	\N	\N	2433	1	domain	2026-06-21 05:44:34.757386
37926	1328	4614	\N	\N	1	domain	2026-06-21 08:17:38.816624
34062	1329	\N	\N	1837	1	domain	2026-06-21 05:44:31.987186
34067	1329	\N	\N	1015	1	domain	2026-06-21 05:44:31.987186
34070	1329	\N	\N	94	1	domain	2026-06-21 05:44:31.987186
37927	1329	4615	\N	\N	1	domain	2026-06-21 08:17:38.822008
34063	1329	\N	\N	2597	1	domain	2026-06-21 05:44:31.987186
34064	1329	\N	\N	3334	1	domain	2026-06-21 05:44:31.987186
34065	1329	\N	\N	190	1	domain	2026-06-21 05:44:31.987186
37928	1329	4616	\N	\N	1	domain	2026-06-21 08:17:38.826033
34586	1329	\N	\N	1834	1	domain	2026-06-21 05:44:32.572038
34587	1329	\N	\N	1014	1	domain	2026-06-21 05:44:32.572038
37929	1329	4617	\N	\N	1	domain	2026-06-21 08:17:38.829033
35774	1329	\N	\N	2584	1	domain	2026-06-21 05:44:33.969237
35775	1329	\N	\N	19	1	domain	2026-06-21 05:44:33.969237
36036	1329	\N	\N	955	1	domain	2026-06-21 05:44:34.266242
37930	1329	4618	\N	\N	1	domain	2026-06-21 08:17:38.832413
35875	1329	\N	\N	173	1	domain	2026-06-21 05:44:34.115046
35876	1329	\N	\N	2594	1	domain	2026-06-21 05:44:34.115046
35886	1329	\N	\N	1266	1	domain	2026-06-21 05:44:34.115046
35889	1329	\N	\N	37	1	domain	2026-06-21 05:44:34.122044
35890	1329	\N	\N	39	1	domain	2026-06-21 05:44:34.122044
37931	1329	4619	\N	\N	1	domain	2026-06-21 08:17:38.839409
36460	1329	\N	\N	3292	1	domain	2026-06-21 05:44:34.757386
36461	1329	\N	\N	737	1	domain	2026-06-21 05:44:34.757386
37932	1329	4620	\N	\N	1	domain	2026-06-21 08:17:38.84375
34196	1330	\N	\N	1548	1	domain	2026-06-21 05:44:32.132998
36227	1330	\N	\N	1658	1	domain	2026-06-21 05:44:34.548301
37933	1330	4621	\N	\N	1	domain	2026-06-21 08:17:38.846756
35024	1330	\N	\N	1840	1	domain	2026-06-21 05:44:33.070648
35097	1330	\N	\N	97	1	domain	2026-06-21 05:44:33.176383
35098	1330	\N	\N	854	1	domain	2026-06-21 05:44:33.176383
37934	1330	4622	\N	\N	1	domain	2026-06-21 08:17:38.850749
35032	1330	\N	\N	1612	1	domain	2026-06-21 05:44:33.08332
35037	1330	\N	\N	3308	1	domain	2026-06-21 05:44:33.08332
37935	1330	4623	\N	\N	1	domain	2026-06-21 08:17:38.855749
35033	1330	\N	\N	3386	1	domain	2026-06-21 05:44:33.08332
35034	1330	\N	\N	2599	1	domain	2026-06-21 05:44:33.08332
35035	1330	\N	\N	188	1	domain	2026-06-21 05:44:33.08332
35036	1330	\N	\N	3360	1	domain	2026-06-21 05:44:33.08332
35322	1330	\N	\N	1575	1	domain	2026-06-21 05:44:33.491735
37936	1330	4624	\N	\N	1	domain	2026-06-21 08:17:38.861614
35328	1330	\N	\N	3235	1	domain	2026-06-21 05:44:33.51099
35329	1330	\N	\N	855	1	domain	2026-06-21 05:44:33.51099
37937	1330	4625	\N	\N	1	domain	2026-06-21 08:17:38.864616
35339	1330	\N	\N	2210	1	domain	2026-06-21 05:44:33.525251
35364	1330	\N	\N	1627	1	domain	2026-06-21 05:44:33.557295
37938	1330	4626	\N	\N	1	domain	2026-06-21 08:17:38.867615
35365	1330	\N	\N	3147	1	domain	2026-06-21 05:44:33.557295
35370	1330	\N	\N	1727	1	domain	2026-06-21 05:44:33.570978
37939	1330	4627	\N	\N	1	domain	2026-06-21 08:17:38.874015
37940	1330	4628	\N	\N	1	domain	2026-06-21 08:17:38.878015
36157	1330	\N	\N	3385	1	domain	2026-06-21 05:44:34.475881
36158	1330	\N	\N	1561	1	domain	2026-06-21 05:44:34.475881
36162	1330	\N	\N	1237	1	domain	2026-06-21 05:44:34.475881
37941	1330	4629	\N	\N	1	domain	2026-06-21 08:17:38.881015
34328	1331	\N	\N	1550	1	domain	2026-06-21 05:44:32.221861
36262	1331	\N	\N	1414	1	domain	2026-06-21 05:44:34.620015
36263	1331	\N	\N	3398	1	domain	2026-06-21 05:44:34.620015
37942	1331	4630	\N	\N	1	domain	2026-06-21 08:17:38.887308
36068	1331	\N	\N	3075	1	domain	2026-06-21 05:44:34.338931
36268	1331	\N	\N	287	1	domain	2026-06-21 05:44:34.620015
37943	1331	4631	\N	\N	1	domain	2026-06-21 08:17:38.891604
34356	1333	\N	\N	1577	1	domain	2026-06-21 05:44:32.259261
34361	1333	\N	\N	2918	1	domain	2026-06-21 05:44:32.259261
37944	1333	4632	\N	\N	1	domain	2026-06-21 08:17:38.895605
34357	1333	\N	\N	171	1	domain	2026-06-21 05:44:32.259261
34359	1333	\N	\N	2583	1	domain	2026-06-21 05:44:32.259261
34392	1333	\N	\N	15	1	domain	2026-06-21 05:44:32.29521
34370	1333	\N	\N	1119	1	domain	2026-06-21 05:44:32.270428
37945	1333	4633	\N	\N	1	domain	2026-06-21 08:17:38.900605
34360	1333	\N	\N	810	1	domain	2026-06-21 05:44:32.259261
34374	1333	\N	\N	3185	1	domain	2026-06-21 05:44:32.278878
37946	1333	4634	\N	\N	1	domain	2026-06-21 08:17:38.907074
34362	1333	\N	\N	1540	1	domain	2026-06-21 05:44:32.259261
34375	1333	\N	\N	1118	1	domain	2026-06-21 05:44:32.278878
37947	1333	4635	\N	\N	1	domain	2026-06-21 08:17:38.911073
37948	1333	4636	\N	\N	1	domain	2026-06-21 08:17:38.915485
35842	1333	\N	\N	954	1	domain	2026-06-21 05:44:34.06894
35843	1333	\N	\N	781	1	domain	2026-06-21 05:44:34.06894
37949	1333	4637	\N	\N	1	domain	2026-06-21 08:17:38.921958
36312	1333	\N	\N	835	1	domain	2026-06-21 05:44:34.644599
36313	1333	\N	\N	90	1	domain	2026-06-21 05:44:34.644599
36317	1333	\N	\N	3203	1	domain	2026-06-21 05:44:34.652893
36318	1333	\N	\N	1008	1	domain	2026-06-21 05:44:34.652893
36320	1333	\N	\N	1213	1	domain	2026-06-21 05:44:34.652893
37950	1333	4638	\N	\N	1	domain	2026-06-21 08:17:38.927975
36507	1333	\N	\N	99	1	domain	2026-06-21 05:44:34.878153
36508	1333	\N	\N	859	1	domain	2026-06-21 05:44:34.878153
37951	1333	4639	\N	\N	1	domain	2026-06-21 08:17:38.931973
34411	1334	\N	\N	3184	1	domain	2026-06-21 05:44:32.338592
34412	1334	\N	\N	833	1	domain	2026-06-21 05:44:32.338592
34413	1334	\N	\N	127	1	domain	2026-06-21 05:44:32.338592
37952	1334	4640	\N	\N	1	domain	2026-06-21 08:17:38.93727
34420	1334	\N	\N	1121	1	domain	2026-06-21 05:44:32.338592
34450	1334	\N	\N	170	1	domain	2026-06-21 05:44:32.39342
37953	1334	4641	\N	\N	1	domain	2026-06-21 08:17:38.942606
34425	1334	\N	\N	125	1	domain	2026-06-21 05:44:32.353611
34426	1334	\N	\N	1538	1	domain	2026-06-21 05:44:32.353611
37954	1334	4642	\N	\N	1	domain	2026-06-21 08:17:38.956907
34457	1334	\N	\N	3359	1	domain	2026-06-21 05:44:32.409573
34458	1334	\N	\N	126	1	domain	2026-06-21 05:44:32.409573
37955	1334	4643	\N	\N	1	domain	2026-06-21 08:17:38.961422
37956	1334	4644	\N	\N	1	domain	2026-06-21 08:17:38.964852
37957	1334	4645	\N	\N	1	domain	2026-06-21 08:17:38.967853
34750	1335	\N	\N	1163	1	domain	2026-06-21 05:44:32.800824
34751	1335	\N	\N	2749	1	domain	2026-06-21 05:44:32.800824
34756	1335	\N	\N	1030	1	domain	2026-06-21 05:44:32.804632
37958	1335	4646	\N	\N	1	domain	2026-06-21 08:17:38.974179
36405	1335	\N	\N	3342	1	domain	2026-06-21 05:44:34.725602
36406	1335	\N	\N	1152	1	domain	2026-06-21 05:44:34.725602
37959	1335	4647	\N	\N	1	domain	2026-06-21 08:17:38.978178
36475	1335	\N	\N	3231	1	domain	2026-06-21 05:44:34.789622
36476	1335	\N	\N	860	1	domain	2026-06-21 05:44:34.789622
36478	1335	\N	\N	130	1	domain	2026-06-21 05:44:34.789622
37960	1335	4648	\N	\N	1	domain	2026-06-21 08:17:38.981177
34769	1336	\N	\N	1835	1	domain	2026-06-21 05:44:32.829587
34770	1336	\N	\N	1630	1	domain	2026-06-21 05:44:32.829587
34771	1336	\N	\N	84	1	domain	2026-06-21 05:44:32.829587
37961	1336	4649	\N	\N	1	domain	2026-06-21 08:17:38.985468
34785	1336	\N	\N	191	1	domain	2026-06-21 05:44:32.855475
34786	1336	\N	\N	1574	1	domain	2026-06-21 05:44:32.855475
37962	1336	4650	\N	\N	1	domain	2026-06-21 08:17:38.991465
34797	1336	\N	\N	1011	1	domain	2026-06-21 05:44:32.864891
34798	1336	\N	\N	1186	1	domain	2026-06-21 05:44:32.864891
37963	1336	4651	\N	\N	1	domain	2026-06-21 08:17:38.994916
34801	1336	\N	\N	867	1	domain	2026-06-21 05:44:32.878253
34802	1336	\N	\N	138	1	domain	2026-06-21 05:44:32.878253
35204	1336	\N	\N	1021	1	domain	2026-06-21 05:44:33.328484
37964	1336	4652	\N	\N	1	domain	2026-06-21 08:17:38.998914
35124	1336	\N	\N	3324	1	domain	2026-06-21 05:44:33.211909
35145	1336	\N	\N	3201	1	domain	2026-06-21 05:44:33.244994
35146	1336	\N	\N	1034	1	domain	2026-06-21 05:44:33.244994
35147	1336	\N	\N	829	1	domain	2026-06-21 05:44:33.244994
35176	1336	\N	\N	86	1	domain	2026-06-21 05:44:33.292264
35179	1336	\N	\N	1193	1	domain	2026-06-21 05:44:33.292264
35188	1336	\N	\N	2595	1	domain	2026-06-21 05:44:33.328484
35195	1336	\N	\N	1591	1	domain	2026-06-21 05:44:33.328484
35201	1336	\N	\N	870	1	domain	2026-06-21 05:44:33.328484
35193	1336	\N	\N	1439	1	domain	2026-06-21 05:44:33.328484
37965	1336	4653	\N	\N	1	domain	2026-06-21 08:17:39.009234
35125	1336	\N	\N	2161	1	domain	2026-06-21 05:44:33.211909
35168	1336	\N	\N	1197	1	domain	2026-06-21 05:44:33.276232
37966	1336	4654	\N	\N	1	domain	2026-06-21 08:17:39.012553
35132	1336	\N	\N	3329	1	domain	2026-06-21 05:44:33.219966
35133	1336	\N	\N	1198	1	domain	2026-06-21 05:44:33.219966
37967	1336	4655	\N	\N	1	domain	2026-06-21 08:17:39.015554
36230	1336	\N	\N	3332	1	domain	2026-06-21 05:44:34.566037
36232	1336	\N	\N	1191	1	domain	2026-06-21 05:44:34.566037
36236	1336	\N	\N	187	1	domain	2026-06-21 05:44:34.573818
36248	1336	\N	\N	100	1	domain	2026-06-21 05:44:34.588411
37968	1336	4656	\N	\N	1	domain	2026-06-21 08:17:39.022876
35274	1337	\N	\N	2598	1	domain	2026-06-21 05:44:33.451241
35275	1337	\N	\N	186	1	domain	2026-06-21 05:44:33.451241
37969	1337	4657	\N	\N	1	domain	2026-06-21 08:17:39.026863
35280	1337	\N	\N	1928	1	domain	2026-06-21 05:44:33.453254
35281	1337	\N	\N	2781	1	domain	2026-06-21 05:44:33.453254
37970	1337	4658	\N	\N	1	domain	2026-06-21 08:17:39.029861
35284	1337	\N	\N	3243	1	domain	2026-06-21 05:44:33.459568
35285	1337	\N	\N	872	1	domain	2026-06-21 05:44:33.459568
35308	1337	\N	\N	1010	1	domain	2026-06-21 05:44:33.475768
37971	1337	4659	\N	\N	1	domain	2026-06-21 08:17:39.034199
35638	1337	\N	\N	950	1	domain	2026-06-21 05:44:33.871348
35639	1337	\N	\N	1821	1	domain	2026-06-21 05:44:33.871348
35643	1337	\N	\N	1290	1	domain	2026-06-21 05:44:33.871348
37972	1337	4660	\N	\N	1	domain	2026-06-21 08:17:39.039219
35407	1338	\N	\N	1547	1	domain	2026-06-21 05:44:33.623313
35457	1338	\N	\N	1203	1	domain	2026-06-21 05:44:33.713754
36214	1338	\N	\N	1657	1	domain	2026-06-21 05:44:34.548301
37973	1338	4661	\N	\N	1	domain	2026-06-21 08:17:39.043499
35414	1338	\N	\N	1202	1	domain	2026-06-21 05:44:33.639104
35415	1338	\N	\N	3277	1	domain	2026-06-21 05:44:33.639104
35418	1338	\N	\N	150	1	domain	2026-06-21 05:44:33.639104
37974	1338	4662	\N	\N	1	domain	2026-06-21 08:17:39.0475
36202	1338	\N	\N	2604	1	domain	2026-06-21 05:44:34.521835
36203	1338	\N	\N	192	1	domain	2026-06-21 05:44:34.521835
36204	1338	\N	\N	1661	1	domain	2026-06-21 05:44:34.521835
36205	1338	\N	\N	2056	1	domain	2026-06-21 05:44:34.521835
36216	1338	\N	\N	1299	1	domain	2026-06-21 05:44:34.548301
37975	1338	4663	\N	\N	1	domain	2026-06-21 08:17:39.053775
36208	1338	\N	\N	1590	1	domain	2026-06-21 05:44:34.532633
36209	1338	\N	\N	3388	1	domain	2026-06-21 05:44:34.532633
37976	1338	4664	\N	\N	1	domain	2026-06-21 08:17:39.060898
36251	1338	\N	\N	1851	1	domain	2026-06-21 05:44:34.594443
36252	1338	\N	\N	194	1	domain	2026-06-21 05:44:34.594443
37977	1338	4665	\N	\N	1	domain	2026-06-21 08:17:39.064339
36301	1338	\N	\N	1566	1	domain	2026-06-21 05:44:34.637151
36303	1338	\N	\N	193	1	domain	2026-06-21 05:44:34.637151
37978	1338	4666	\N	\N	1	domain	2026-06-21 08:17:39.068341
36487	1338	\N	\N	747	1	domain	2026-06-21 05:44:34.805749
36496	1338	\N	\N	1527	1	domain	2026-06-21 05:44:34.853365
37979	1338	4667	\N	\N	1	domain	2026-06-21 08:17:39.072336
\.


--
-- Data for Name: grc_common_control_groups; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_common_control_groups (id, tenant_id, code, name, description, category, domain, keywords, ai_summary, evidence_types, created_at, updated_at, created_by, run_id) FROM stdin;
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
1382	1	SDOM-22-01	Governance, Risk & Compliance	\N	Governance, Risk & Compliance	Governance, Risk & Compliance	[]	\N	[]	2026-06-21 08:57:50.956337	2026-06-21 08:57:50.956337	1	22
1383	1	SDOM-22-02	Asset Management	\N	Asset Management	Asset Management	[]	\N	[]	2026-06-21 08:57:50.999856	2026-06-21 08:57:50.999856	1	22
1384	1	SDOM-22-03	Other / Uncategorized	\N	Other / Uncategorized	Other / Uncategorized	[]	\N	[]	2026-06-21 08:57:51.011496	2026-06-21 08:57:51.011496	1	22
1385	1	SDOM-22-04	Business Continuity & Resilience	\N	Business Continuity & Resilience	Business Continuity & Resilience	[]	\N	[]	2026-06-21 08:57:51.03425	2026-06-21 08:57:51.03425	1	22
1386	1	SDOM-22-05	Data Protection & Privacy	\N	Data Protection & Privacy	Data Protection & Privacy	[]	\N	[]	2026-06-21 08:57:51.036675	2026-06-21 08:57:51.036675	1	22
1387	1	SDOM-22-06	Incident Management	\N	Incident Management	Incident Management	[]	\N	[]	2026-06-21 08:57:51.042889	2026-06-21 08:57:51.042889	1	22
1388	1	SDOM-22-07	Access Control & Identity Management	\N	Access Control & Identity Management	Access Control & Identity Management	[]	\N	[]	2026-06-21 08:57:51.0482	2026-06-21 08:57:51.0482	1	22
1389	1	SDOM-22-08	Vulnerability & Threat Management	\N	Vulnerability & Threat Management	Vulnerability & Threat Management	[]	\N	[]	2026-06-21 08:57:51.051198	2026-06-21 08:57:51.051198	1	22
1390	1	SDOM-22-09	Application & Software Security	\N	Application & Software Security	Application & Software Security	[]	\N	[]	2026-06-21 08:57:51.053179	2026-06-21 08:57:51.053179	1	22
1391	1	SDOM-22-10	Logging, Monitoring & Detection	\N	Logging, Monitoring & Detection	Logging, Monitoring & Detection	[]	\N	[]	2026-06-21 08:57:51.057087	2026-06-21 08:57:51.057087	1	22
1392	1	SDOM-22-11	Third-Party & Supply Chain Risk	\N	Third-Party & Supply Chain Risk	Third-Party & Supply Chain Risk	[]	\N	[]	2026-06-21 08:57:51.061088	2026-06-21 08:57:51.061088	1	22
1393	1	SDOM-22-12	Configuration & Change Management	\N	Configuration & Change Management	Configuration & Change Management	[]	\N	[]	2026-06-21 08:57:51.063088	2026-06-21 08:57:51.063088	1	22
1394	1	SDOM-22-13	Audit & Assurance	\N	Audit & Assurance	Audit & Assurance	[]	\N	[]	2026-06-21 08:57:51.065087	2026-06-21 08:57:51.065087	1	22
1395	1	SDOM-22-14	Human Resources Security	\N	Human Resources Security	Human Resources Security	[]	\N	[]	2026-06-21 08:57:51.068445	2026-06-21 08:57:51.068445	1	22
1396	1	SDOM-22-15	Awareness & Training	\N	Awareness & Training	Awareness & Training	[]	\N	[]	2026-06-21 08:57:51.070443	2026-06-21 08:57:51.070443	1	22
1397	1	SDOM-22-16	Network Security	\N	Network Security	Network Security	[]	\N	[]	2026-06-21 08:57:51.075444	2026-06-21 08:57:51.075444	1	22
1398	1	SDOM-22-17	Physical & Environmental Security	\N	Physical & Environmental Security	Physical & Environmental Security	[]	\N	[]	2026-06-21 08:57:51.078844	2026-06-21 08:57:51.078844	1	22
1399	1	SDOM-22-18	Cryptography & Key Management	\N	Cryptography & Key Management	Cryptography & Key Management	[]	\N	[]	2026-06-21 08:57:51.081824	2026-06-21 08:57:51.081824	1	22
1400	1	SDOM-23-01	Awareness & Training	\N	Awareness & Training	Awareness & Training	[]	\N	[]	2026-06-21 09:04:07.909187	2026-06-21 09:04:07.909187	1	23
1401	1	SDOM-23-02	Physical & Environmental Security	\N	Physical & Environmental Security	Physical & Environmental Security	[]	\N	[]	2026-06-21 09:04:07.984584	2026-06-21 09:04:07.984584	1	23
1402	1	SDOM-23-03	Cryptography & Key Management	\N	Cryptography & Key Management	Cryptography & Key Management	[]	\N	[]	2026-06-21 09:04:08.05128	2026-06-21 09:04:08.05228	1	23
1403	1	SDOM-23-04	Access Control & Identity Management	\N	Access Control & Identity Management	Access Control & Identity Management	[]	\N	[]	2026-06-21 09:04:08.062288	2026-06-21 09:04:08.062288	1	23
1404	1	SDOM-23-05	Data Protection & Privacy	\N	Data Protection & Privacy	Data Protection & Privacy	[]	\N	[]	2026-06-21 09:04:08.092446	2026-06-21 09:04:08.092446	1	23
1405	1	SDOM-23-06	Asset Management	\N	Asset Management	Asset Management	[]	\N	[]	2026-06-21 09:04:08.106842	2026-06-21 09:04:08.106842	1	23
1406	1	SDOM-23-07	Configuration & Change Management	\N	Configuration & Change Management	Configuration & Change Management	[]	\N	[]	2026-06-21 09:04:08.121527	2026-06-21 09:04:08.121527	1	23
1407	1	SDOM-23-08	Human Resources Security	\N	Human Resources Security	Human Resources Security	[]	\N	[]	2026-06-21 09:04:08.159592	2026-06-21 09:04:08.159592	1	23
1408	1	SDOM-23-09	Governance, Risk & Compliance	\N	Governance, Risk & Compliance	Governance, Risk & Compliance	[]	\N	[]	2026-06-21 09:04:08.164174	2026-06-21 09:04:08.164174	1	23
1409	1	SDOM-23-10	Third-Party & Supply Chain Risk	\N	Third-Party & Supply Chain Risk	Third-Party & Supply Chain Risk	[]	\N	[]	2026-06-21 09:04:08.171188	2026-06-21 09:04:08.171188	1	23
1410	1	SDOM-23-11	Vulnerability & Threat Management	\N	Vulnerability & Threat Management	Vulnerability & Threat Management	[]	\N	[]	2026-06-21 09:04:08.182014	2026-06-21 09:04:08.182014	1	23
1411	1	SDOM-23-12	Other / Uncategorized	\N	Other / Uncategorized	Other / Uncategorized	[]	\N	[]	2026-06-21 09:04:08.19268	2026-06-21 09:04:08.19268	1	23
1412	1	SDOM-23-13	Network Security	\N	Network Security	Network Security	[]	\N	[]	2026-06-21 09:04:08.203048	2026-06-21 09:04:08.203048	1	23
1413	1	SDOM-23-14	Logging, Monitoring & Detection	\N	Logging, Monitoring & Detection	Logging, Monitoring & Detection	[]	\N	[]	2026-06-21 09:04:08.209052	2026-06-21 09:04:08.209052	1	23
1414	1	SDOM-23-15	Application & Software Security	\N	Application & Software Security	Application & Software Security	[]	\N	[]	2026-06-21 09:04:08.219306	2026-06-21 09:04:08.219306	1	23
1415	1	SDOM-23-16	Incident Management	\N	Incident Management	Incident Management	[]	\N	[]	2026-06-21 09:04:08.238436	2026-06-21 09:04:08.238436	1	23
1416	1	SDOM-23-17	Business Continuity & Resilience	\N	Business Continuity & Resilience	Business Continuity & Resilience	[]	\N	[]	2026-06-21 09:04:08.262338	2026-06-21 09:04:08.262338	1	23
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
18	1	Fine-grained baseline (all frameworks)	full	\N	completed	t	\N	2026-06-21 05:44:28.456571	2026-06-21 06:21:34.611011	{"unified_controls": 268, "standalone": 2108, "domains": 18, "evidence_consolidated": 267, "master_list": ["Key Management", "Automatic Scanning of Removable Media", "Audit Log Content Requirements", "Access Establishment and Modification", "Appoint Chief Information Security Officer", "Mobile Device Access Control", "Access Control Policy Management", "Establish Software Inventory", "Data Protection in Transit", "Maintain Information Asset Inventory", "Ensure Compliance with Security Standards", "Legal and Compliance Risk Assessment", "Implement Cryptographic Controls", "Apply Principle of Least Functionality", "Security Role Separation", "Data Loss Prevention", "Centralized Audit Log Management", "Version Control Implementation", "Audit Logging", "Identify and Manage Security Vulnerabilities", "Data Inventory Management", "Internal Controls Effectiveness Monitoring", "Password Change Requirements", "Control Assessments", "Real-Time Fraud Monitoring", "Access Control for Service Providers", "Management Approval for Remote Access", "Network Segmentation", "Secure Log-on Procedures", "Incident Monitoring", "Implement Incident Handling Procedures", "Patch and Update Management", "Resource Monitoring and Adjustment", "System Performance Monitoring", "Audit Log Storage Management", "Network Architecture Review", "Risk Monitoring and Reporting", "Secure Key Management Practices", "Employment Security Policies", "Role Responsibilities and Access", "Anti-Malware Software Updates", "Malicious Code Detection", "Malware Protection Implementation", "Deploy Anti-Malware Solutions", "Incident Response Training", "IT Personnel Capacity Building", "Information Security Management Program", "Phishing Detection and Protection", "Email Server Anti-Malware Protections", "Technology Governance", "Periodic User Access Reviews", "Timely Access Revocation", "Removal of Access Rights", "Least Privilege Principle", "Role-Based Access Management", "Access Rights Management", "Access Rights Review", "Intrusion Prevention Systems", "Information Security Policy Management", "Physical Entry Controls", "Secure Work Areas", "Environmental Threat Protection", "Cabling Security", "Data Center Security", "Physical Security Perimeters", "Mobile Application Security", "Data Backup Execution", "Information Access Management", "Physical Security Controls", "Logical Access Policy Management", "Database Access Restrictions", "Access Control Enforcement", "Access Control for Healthcare Facilities", "Access Control for Network Services", "Access Control for Confidential Information", "Post-Incident Review Process", "Access Control for Information Assets", "Access Control for User Authentication", "Incident Detection and Monitoring", "Governance Framework Management", "Conduct Business Impact Analysis", "Data Minimization", "General Background Verification Checks", "Personnel Screening for Access Authorization", "Maintain Enterprise Asset Inventory", "Inventory of Physical Devices", "Business Continuity Management", "Security Assessment", "Asset Inventory Management", "Define Information Security Roles", "Assign Security Responsibility", "Identify Third Party Risks", "Role-Based Security Training", "Monitor Third Party Services", "Conduct Third Party Risk Assessments", "Establish Third Party Security Policies", "Evaluate Third Party Contracts", "Conduct Independent Vendor Audits", "Assess Vendor Cybersecurity Risks", "Periodic Security Awareness Campaigns", "Third Party Risk Management", "Continual Improvement Framework", "Install Security Patches", "Compliance Monitoring", "Acceptable Use of Information and Other Associated Assets", "Communication Management", "Information Security Learning", "Remediation Process Management", "Audit Log Protection Measures", "General Risk Assessment", "Logging of User Activities", "Risk Analysis", "API Security Testing", "Threat and Vulnerability Assessment", "Restrict Data Transmission", "General Security Awareness Training", "Security Awareness Program Implementation", "Data Leak Prevention Measures", "Crisis Communication Plans", "Secure Disposal Procedures", "Training Records Management", "Customer Security Awareness Programs", "Change Management Policy", "Return of Organizational Assets", "Security Awareness and Training", "Strong User Authentication", "Adopt Secure Coding Standards", "Secure Coding Practices", "Change Testing Procedures", "Emergency Change Procedures", "Production Migration Controls", "Unique User Identification", "Train Developers in Secure Coding", "Establish Baseline Configuration", "Maintain Secure Configurations", "Supplier Change Management", "Controlled Change Management", "Segregate Development and Production Environments", "Implement Configuration Management Practices", "Control Installation of Operational Software", "Data Management and Quality Compliance", "Information System Activity Review", "Configuration Management", "Change Management Segregation", "Third Party Agreement Compliance", "Regular Risk Assessment Process", "Change Planning and Impact Analysis", "Network Access Control", "Identity and Access Management", "Disaster Recovery Plan Testing", "User Registration Management", "General Segregation of Duties", "Post-Implementation Review", "Password Complexity and Length Requirements", "Quality Assurance", "Risk Management", "Allocate Privileges to Systems", "Unauthorized Change Detection", "Rollback Planning for Changes", "Change Impact Assessment", "Change Management", "Control Privileged Access Accounts", "Restrict Administrator Privileges", "Testing and Segregation Controls", "Admin Access Monitoring", "System Design Review", "Audit Trail Review", "Event Logging Procedures", "Change Management Process", "Annual Policy Review", "Sanction Policy Enforcement", "Multi-Factor Authentication Implementation", "Service Delivery", "Formal Disciplinary Process", "Timely Security Updates", "Periodic Penetration Testing", "Regular Vulnerability Scanning", "Vulnerability Handling Procedures", "System-Specific Vulnerability Management", "Technical Vulnerability Control Measures", "Unsuccessful Logon Attempts Management", "Data Retention Compliance", "Vulnerability Management", "Risk Management Process Monitoring", "Business Continuity Exercise Types", "Event Analysis and Correlation", "Incident Classification and Prioritization", "Establish Incident Response Structure", "Unauthorized Activity Monitoring", "Anomaly Detection Mechanisms", "Automated Cyber Attack Monitoring", "Identification and Authentication Policy", "Continuous Monitoring", "Password Protection Measures", "Incident Handling Procedures", "Execute Incident Response Plan", "Incident Response Resources", "Session Management", "Post-Incident Review and Analysis", "Data Encryption", "Test Incident Response Capability", "Incident Management", "Incident Trend Analysis and Learning", "Incident Management Roles and Responsibilities", "Encryption and Key Management", "Test Patches Before Production", "Encrypt Data at Rest", "Encrypt Data in Transit", "Encrypt End-User Devices", "Define Cyber Security Strategy", "Evaluate and Approve Patches", "Establish Cyber Security Function", "Share Threat Intelligence", "Maintenance Performed", "Availability and Capacity Planning", "Implement Appropriate Safeguards", "Collect Threat Intelligence", "Data Classification", "Data Center Access Control", "Physical Access Management", "Information Classification Guidelines", "Facility Access Restrictions", "Authorized Access List Management", "Equipment Protection", "Incident Investigation", "Visitor Access Management", "Implement ICT Third Party Risk Management", "Data Disposal Compliance", "Network Security", "Requirements Definition for Acquisition", "Remote Access Usage Restrictions", "Cyber Security Requirements for Staff", "Assign Asset Ownership", "Anti-Malware Controls", "Physical Security Measures", "Secure Remote Access Implementation", "Data Recovery Process", "Information Security Governance", "Periodic IT Audits", "Media Destruction Methods", "Security in Acquisition Process", "Incident Notification", "Employment Terms and Conditions", "Cyber Security Governance", "Formal Password Management Process", "Data Protection by Design and Default", "Disaster Recovery Test Scenarios", "Data Labeling and Handling", "Fraud Awareness and Training", "Business Continuity Plan Testing", "Network Monitoring", "Secure Data Disposal Policy", "Business Continuity Testing and Exercising", "Device and Media Controls", "Email Security", "Project Risk Management", "Environmental Controls", "Privacy Monitoring and Enforcement", "Breach Notification to Patients", "Breach Notification to DOH", "Time Synchronization", "Problem Management", "Testing Methodology", "Incident Communication", "Physical Security Monitoring", "Security Requirements Analysis and Specification", "Wireless Security", "Security Operations Management"]}
22	1	Session — 3 frameworks	custom	[10, 11, 12]	completed	f	1	2026-06-21 13:57:49.96487	2026-06-21 13:57:49.96487	{"unified_controls": 3, "standalone": 197, "controls_covered": 203, "from_baseline": 18, "new_frameworks_classified": []}
23	1	Session — 2 frameworks	custom	[2, 1]	completed	f	1	2026-06-21 14:04:05.99295	2026-06-21 14:04:05.99295	{"unified_controls": 10, "standalone": 176, "controls_covered": 197, "from_baseline": 18, "new_frameworks_classified": []}
\.


--
-- Data for Name: grc_normalized_control_links; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_normalized_control_links (id, normalized_control_id, parsed_control_id, framework_control_id, mapping_type, created_at) FROM stdin;
22230	4668	2125	\N	direct	2026-06-21 08:21:21.398929
22231	4668	1126	\N	direct	2026-06-21 08:21:21.398929
22232	4669	944	\N	direct	2026-06-21 08:21:21.409938
22233	4669	2748	\N	direct	2026-06-21 08:21:21.409938
22234	4670	791	\N	direct	2026-06-21 08:21:21.418847
22235	4670	3174	\N	direct	2026-06-21 08:21:21.418847
22236	4671	1367	\N	direct	2026-06-21 08:21:21.424951
22237	4671	2613	\N	direct	2026-06-21 08:21:21.424951
22238	4672	682	\N	direct	2026-06-21 08:21:21.429933
22239	4672	1545	\N	direct	2026-06-21 08:21:21.429933
22240	4673	2889	\N	direct	2026-06-21 08:21:21.435161
22241	4673	2080	\N	direct	2026-06-21 08:21:21.435161
22242	4674	3176	\N	direct	2026-06-21 08:21:21.44018
22243	4674	949	\N	direct	2026-06-21 08:21:21.44018
22244	4675	2992	\N	direct	2026-06-21 08:21:21.444324
22245	4675	2119	\N	direct	2026-06-21 08:21:21.444324
22246	4676	789	\N	direct	2026-06-21 08:21:21.447281
22247	4676	3170	\N	direct	2026-06-21 08:21:21.447281
22248	4677	790	\N	direct	2026-06-21 08:21:21.451693
22249	4677	3173	\N	direct	2026-06-21 08:21:21.451693
22250	4678	1293	\N	direct	2026-06-21 08:21:21.457285
22251	4678	1541	\N	direct	2026-06-21 08:21:21.457285
22252	4679	2729	\N	direct	2026-06-21 08:21:21.463295
22253	4679	2095	\N	direct	2026-06-21 08:21:21.463295
22254	4679	307	\N	direct	2026-06-21 08:21:21.463295
22255	4680	1655	\N	direct	2026-06-21 08:21:21.469488
22256	4680	2059	\N	direct	2026-06-21 08:21:21.469488
22257	4681	3155	\N	direct	2026-06-21 08:21:21.474492
22258	4681	2540	\N	direct	2026-06-21 08:21:21.474492
22259	4681	2567	\N	direct	2026-06-21 08:21:21.474492
22260	4681	3162	\N	direct	2026-06-21 08:21:21.474492
22261	4681	2184	\N	direct	2026-06-21 08:21:21.474492
22262	4681	2539	\N	direct	2026-06-21 08:21:21.474492
22263	4682	3189	\N	direct	2026-06-21 08:21:21.477439
22264	4682	1691	\N	direct	2026-06-21 08:21:21.477439
22265	4683	697	\N	direct	2026-06-21 08:21:21.481495
22266	4683	1726	\N	direct	2026-06-21 08:21:21.481495
22267	4684	277	\N	direct	2026-06-21 08:21:21.486039
22268	4684	2420	\N	direct	2026-06-21 08:21:21.486039
22269	4685	1603	\N	direct	2026-06-21 08:21:21.489956
22270	4685	76	\N	direct	2026-06-21 08:21:21.489956
22271	4686	1022	\N	direct	2026-06-21 08:21:21.491954
22272	4686	122	\N	direct	2026-06-21 08:21:21.491954
22273	4687	3318	\N	direct	2026-06-21 08:21:21.497059
22274	4687	2200	\N	direct	2026-06-21 08:21:21.497059
22275	4688	753	\N	direct	2026-06-21 08:21:21.50277
22276	4688	69	\N	direct	2026-06-21 08:21:21.50277
22277	4689	1943	\N	direct	2026-06-21 08:21:21.507772
22278	4689	3268	\N	direct	2026-06-21 08:21:21.507772
22279	4690	1416	\N	direct	2026-06-21 08:21:21.513656
22280	4690	2254	\N	direct	2026-06-21 08:21:21.513656
22281	4691	693	\N	direct	2026-06-21 08:21:21.519581
22282	4691	3222	\N	direct	2026-06-21 08:21:21.519581
22283	4692	3142	\N	direct	2026-06-21 08:21:21.525682
22284	4692	1240	\N	direct	2026-06-21 08:21:21.525682
22285	4693	763	\N	direct	2026-06-21 08:21:21.531704
22286	4693	70	\N	direct	2026-06-21 08:21:21.531704
22287	4694	73	\N	direct	2026-06-21 08:21:21.537012
22288	4694	759	\N	direct	2026-06-21 08:21:21.537012
22289	4695	1596	\N	direct	2026-06-21 08:21:21.541095
22290	4695	2166	\N	direct	2026-06-21 08:21:21.541095
22291	4696	3351	\N	direct	2026-06-21 08:21:21.545119
22292	4696	1199	\N	direct	2026-06-21 08:21:21.545119
22293	4697	690	\N	direct	2026-06-21 08:21:21.551697
22294	4697	1692	\N	direct	2026-06-21 08:21:21.551697
22295	4697	9	\N	direct	2026-06-21 08:21:21.551697
22296	4698	567	\N	direct	2026-06-21 08:21:21.557334
22297	4698	1958	\N	direct	2026-06-21 08:21:21.557334
22298	4699	752	\N	direct	2026-06-21 08:21:21.562428
22299	4699	3217	\N	direct	2026-06-21 08:21:21.562428
22300	4700	1722	\N	direct	2026-06-21 08:21:21.568423
22301	4700	1330	\N	direct	2026-06-21 08:21:21.568423
22302	4701	959	\N	direct	2026-06-21 08:21:21.573426
22303	4701	1825	\N	direct	2026-06-21 08:21:21.573426
22304	4702	1633	\N	direct	2026-06-21 08:21:21.580365
22305	4702	3311	\N	direct	2026-06-21 08:21:21.580365
22306	4703	2694	\N	direct	2026-06-21 08:21:21.586103
22307	4703	3383	\N	direct	2026-06-21 08:21:21.586103
22308	4704	60	\N	direct	2026-06-21 08:21:21.592089
22309	4704	825	\N	direct	2026-06-21 08:21:21.592089
22310	4705	61	\N	direct	2026-06-21 08:21:21.598813
22311	4705	755	\N	direct	2026-06-21 08:21:21.598813
22312	4706	183	\N	direct	2026-06-21 08:21:21.600603
22313	4706	48	\N	direct	2026-06-21 08:21:21.600603
22314	4707	3212	\N	direct	2026-06-21 08:21:21.600603
22315	4707	999	\N	direct	2026-06-21 08:21:21.600603
22316	4708	2471	\N	direct	2026-06-21 08:21:21.600603
22317	4708	1679	\N	direct	2026-06-21 08:21:21.600603
22318	4709	607	\N	direct	2026-06-21 08:21:21.618745
22319	4709	1226	\N	direct	2026-06-21 08:21:21.618745
22320	4710	3296	\N	direct	2026-06-21 08:21:21.624343
22321	4710	894	\N	direct	2026-06-21 08:21:21.624343
22322	4710	1425	\N	direct	2026-06-21 08:21:21.624343
22323	4711	3240	\N	direct	2026-06-21 08:21:21.624343
22324	4711	101	\N	direct	2026-06-21 08:21:21.624343
22325	4712	213	\N	direct	2026-06-21 08:21:21.631336
22326	4712	1732	\N	direct	2026-06-21 08:21:21.631336
22327	4713	901	\N	direct	2026-06-21 08:21:21.631336
22328	4713	3306	\N	direct	2026-06-21 08:21:21.631336
22329	4714	36	\N	direct	2026-06-21 08:21:21.631336
22330	4714	719	\N	direct	2026-06-21 08:21:21.631336
22331	4715	2755	\N	direct	2026-06-21 08:21:21.648958
22332	4715	1002	\N	direct	2026-06-21 08:21:21.648958
22333	4715	826	\N	direct	2026-06-21 08:21:21.648958
22334	4716	222	\N	direct	2026-06-21 08:21:21.657571
22335	4716	1260	\N	direct	2026-06-21 08:21:21.657571
22336	4717	843	\N	direct	2026-06-21 08:21:21.663394
22337	4717	38	\N	direct	2026-06-21 08:21:21.663394
22338	4718	2927	\N	direct	2026-06-21 08:21:21.663394
22339	4718	1018	\N	direct	2026-06-21 08:21:21.663394
22340	4719	1294	\N	direct	2026-06-21 08:21:21.663394
22341	4719	98	\N	direct	2026-06-21 08:21:21.663394
22342	4719	856	\N	direct	2026-06-21 08:21:21.663394
22343	4720	1339	\N	direct	2026-06-21 08:21:21.679253
22344	4720	808	\N	direct	2026-06-21 08:21:21.679253
22345	4721	3081	\N	direct	2026-06-21 08:21:21.679253
22346	4721	2106	\N	direct	2026-06-21 08:21:21.679253
22347	4722	1844	\N	direct	2026-06-21 08:21:21.679253
22348	4722	1297	\N	direct	2026-06-21 08:21:21.679253
22349	4723	3121	\N	direct	2026-06-21 08:21:21.694909
22350	4723	1325	\N	direct	2026-06-21 08:21:21.694909
22351	4724	1614	\N	direct	2026-06-21 08:21:21.694909
22352	4724	259	\N	direct	2026-06-21 08:21:21.694909
22353	4725	602	\N	direct	2026-06-21 08:21:21.694909
22354	4725	922	\N	direct	2026-06-21 08:21:21.694909
22355	4726	3144	\N	direct	2026-06-21 08:21:21.694909
22356	4726	3145	\N	direct	2026-06-21 08:21:21.694909
22357	4726	704	\N	direct	2026-06-21 08:21:21.694909
22358	4727	2607	\N	direct	2026-06-21 08:21:21.710687
22359	4727	907	\N	direct	2026-06-21 08:21:21.710687
22360	4728	1219	\N	direct	2026-06-21 08:21:21.710687
22361	4728	2807	\N	direct	2026-06-21 08:21:21.710687
22362	4729	706	\N	direct	2026-06-21 08:21:21.710687
22363	4729	3248	\N	direct	2026-06-21 08:21:21.710687
22364	4730	722	\N	direct	2026-06-21 08:21:21.726871
22365	4730	1645	\N	direct	2026-06-21 08:21:21.726871
21698	4481	2365	\N	direct	2026-06-21 08:17:38.055197
21699	4481	1129	\N	direct	2026-06-21 08:17:38.055197
21700	4481	1045	\N	direct	2026-06-21 08:17:38.055197
21701	4481	1116	\N	direct	2026-06-21 08:17:38.055197
21702	4481	1131	\N	direct	2026-06-21 08:17:38.055197
21703	4482	2070	\N	direct	2026-06-21 08:17:38.07461
21704	4482	1108	\N	direct	2026-06-21 08:17:38.07461
21705	4482	1113	\N	direct	2026-06-21 08:17:38.07461
21706	4483	1107	\N	direct	2026-06-21 08:17:38.080535
21707	4483	2480	\N	direct	2026-06-21 08:17:38.080535
21708	4483	2934	\N	direct	2026-06-21 08:17:38.080535
21709	4484	1743	\N	direct	2026-06-21 08:17:38.086014
21710	4484	1543	\N	direct	2026-06-21 08:17:38.086014
21711	4485	1130	\N	direct	2026-06-21 08:17:38.092465
21712	4485	3172	\N	direct	2026-06-21 08:17:38.092465
21713	4485	1800	\N	direct	2026-06-21 08:17:38.092465
21714	4485	2759	\N	direct	2026-06-21 08:17:38.092465
21715	4485	1046	\N	direct	2026-06-21 08:17:38.092465
21716	4486	1134	\N	direct	2026-06-21 08:17:38.097398
21717	4486	2756	\N	direct	2026-06-21 08:17:38.097398
21718	4487	1111	\N	direct	2026-06-21 08:17:38.101493
21719	4487	2134	\N	direct	2026-06-21 08:17:38.101493
21720	4488	785	\N	direct	2026-06-21 08:17:38.10687
21721	4488	2737	\N	direct	2026-06-21 08:17:38.10687
21722	4489	979	\N	direct	2026-06-21 08:17:38.110793
21723	4489	806	\N	direct	2026-06-21 08:17:38.110793
21724	4490	1740	\N	direct	2026-06-21 08:17:38.116275
21725	4490	2610	\N	direct	2026-06-21 08:17:38.116275
21726	4490	974	\N	direct	2026-06-21 08:17:38.116275
21727	4490	3164	\N	direct	2026-06-21 08:17:38.116275
21728	4491	948	\N	direct	2026-06-21 08:17:38.121703
21729	4491	794	\N	direct	2026-06-21 08:17:38.121703
21730	4492	364	\N	direct	2026-06-21 08:17:38.126708
21731	4492	1413	\N	direct	2026-06-21 08:17:38.126708
21732	4493	83	\N	direct	2026-06-21 08:17:38.13071
21733	4493	381	\N	direct	2026-06-21 08:17:38.13071
21734	4494	1898	\N	direct	2026-06-21 08:17:38.137111
21735	4494	1899	\N	direct	2026-06-21 08:17:38.137111
21736	4494	1900	\N	direct	2026-06-21 08:17:38.137111
21737	4494	1902	\N	direct	2026-06-21 08:17:38.137111
21738	4494	1251	\N	direct	2026-06-21 08:17:38.137111
21739	4495	777	\N	direct	2026-06-21 08:17:38.143526
21740	4495	1072	\N	direct	2026-06-21 08:17:38.143526
21741	4496	1842	\N	direct	2026-06-21 08:17:38.148519
21742	4496	3132	\N	direct	2026-06-21 08:17:38.148519
21743	4496	3236	\N	direct	2026-06-21 08:17:38.148519
21744	4496	840	\N	direct	2026-06-21 08:17:38.148519
21745	4496	119	\N	direct	2026-06-21 08:17:38.148519
21746	4497	771	\N	direct	2026-06-21 08:17:38.151517
21747	4497	81	\N	direct	2026-06-21 08:17:38.151517
21748	4498	3237	\N	direct	2026-06-21 08:17:38.159276
21749	4498	841	\N	direct	2026-06-21 08:17:38.159276
21750	4498	120	\N	direct	2026-06-21 08:17:38.159276
21751	4499	2589	\N	direct	2026-06-21 08:17:38.162673
21752	4499	1239	\N	direct	2026-06-21 08:17:38.162673
21753	4500	10	\N	direct	2026-06-21 08:17:38.166802
21754	4500	3195	\N	direct	2026-06-21 08:17:38.166802
21755	4501	1426	\N	direct	2026-06-21 08:17:38.173105
21756	4501	2272	\N	direct	2026-06-21 08:17:38.173105
21757	4502	3224	\N	direct	2026-06-21 08:17:38.178101
21758	4502	79	\N	direct	2026-06-21 08:17:38.178101
21759	4503	1687	\N	direct	2026-06-21 08:17:38.182612
21760	4503	688	\N	direct	2026-06-21 08:17:38.182612
21761	4503	1626	\N	direct	2026-06-21 08:17:38.182612
21762	4504	3315	\N	direct	2026-06-21 08:17:38.18752
21763	4504	3316	\N	direct	2026-06-21 08:17:38.18752
21764	4504	3267	\N	direct	2026-06-21 08:17:38.18752
21765	4504	1234	\N	direct	2026-06-21 08:17:38.18752
21766	4505	3216	\N	direct	2026-06-21 08:17:38.193898
21767	4505	1951	\N	direct	2026-06-21 08:17:38.193898
21768	4505	1952	\N	direct	2026-06-21 08:17:38.193898
21769	4506	241	\N	direct	2026-06-21 08:17:38.196898
21770	4506	1593	\N	direct	2026-06-21 08:17:38.196898
21771	4507	1242	\N	direct	2026-06-21 08:17:38.2009
21772	4507	3322	\N	direct	2026-06-21 08:17:38.2009
21773	4508	62	\N	direct	2026-06-21 08:17:38.206295
21774	4508	995	\N	direct	2026-06-21 08:17:38.206295
21775	4509	3211	\N	direct	2026-06-21 08:17:38.210293
21776	4509	820	\N	direct	2026-06-21 08:17:38.210293
21777	4510	3198	\N	direct	2026-06-21 08:17:38.226005
21778	4510	58	\N	direct	2026-06-21 08:17:38.226005
21779	4511	446	\N	direct	2026-06-21 08:17:38.230032
21780	4511	43	\N	direct	2026-06-21 08:17:38.230032
21781	4511	45	\N	direct	2026-06-21 08:17:38.230032
21782	4512	653	\N	direct	2026-06-21 08:17:38.233481
21783	4512	3299	\N	direct	2026-06-21 08:17:38.233481
21784	4513	3293	\N	direct	2026-06-21 08:17:38.240397
21785	4513	886	\N	direct	2026-06-21 08:17:38.240397
21786	4513	887	\N	direct	2026-06-21 08:17:38.240397
21787	4513	1699	\N	direct	2026-06-21 08:17:38.240397
21788	4514	883	\N	direct	2026-06-21 08:17:38.244866
21789	4514	1700	\N	direct	2026-06-21 08:17:38.244866
21790	4514	1529	\N	direct	2026-06-21 08:17:38.244866
21791	4515	643	\N	direct	2026-06-21 08:17:38.248865
21792	4515	895	\N	direct	2026-06-21 08:17:38.248865
21793	4516	645	\N	direct	2026-06-21 08:17:38.253425
21794	4516	733	\N	direct	2026-06-21 08:17:38.253425
21795	4517	976	\N	direct	2026-06-21 08:17:38.259971
21796	4517	802	\N	direct	2026-06-21 08:17:38.259971
21797	4518	3350	\N	direct	2026-06-21 08:17:38.265427
21798	4518	861	\N	direct	2026-06-21 08:17:38.265427
21799	4518	132	\N	direct	2026-06-21 08:17:38.265427
21800	4518	1730	\N	direct	2026-06-21 08:17:38.265427
21801	4519	853	\N	direct	2026-06-21 08:17:38.27042
21802	4519	115	\N	direct	2026-06-21 08:17:38.27042
21803	4520	862	\N	direct	2026-06-21 08:17:38.275718
21804	4520	133	\N	direct	2026-06-21 08:17:38.275718
21805	4521	863	\N	direct	2026-06-21 08:17:38.278718
21806	4521	134	\N	direct	2026-06-21 08:17:38.278718
21807	4522	864	\N	direct	2026-06-21 08:17:38.283105
21808	4522	135	\N	direct	2026-06-21 08:17:38.283105
21809	4523	1586	\N	direct	2026-06-21 08:17:38.289029
21810	4523	803	\N	direct	2026-06-21 08:17:38.289029
21811	4524	899	\N	direct	2026-06-21 08:17:38.294435
21812	4524	668	\N	direct	2026-06-21 08:17:38.294435
21813	4525	957	\N	direct	2026-06-21 08:17:38.319365
21814	4525	3339	\N	direct	2026-06-21 08:17:38.319365
21815	4525	108	\N	direct	2026-06-21 08:17:38.319365
21816	4526	1624	\N	direct	2026-06-21 08:17:38.349551
21817	4526	846	\N	direct	2026-06-21 08:17:38.349551
21818	4526	847	\N	direct	2026-06-21 08:17:38.349551
21819	4527	637	\N	direct	2026-06-21 08:17:38.35378
21820	4527	1453	\N	direct	2026-06-21 08:17:38.35378
21821	4528	3223	\N	direct	2026-06-21 08:17:38.359595
21822	4528	2585	\N	direct	2026-06-21 08:17:38.359595
21823	4528	26	\N	direct	2026-06-21 08:17:38.359595
21824	4528	844	\N	direct	2026-06-21 08:17:38.359595
21825	4529	793	\N	direct	2026-06-21 08:17:38.36321
21826	4529	986	\N	direct	2026-06-21 08:17:38.36321
21827	4530	3239	\N	direct	2026-06-21 08:17:38.36722
21828	4530	868	\N	direct	2026-06-21 08:17:38.36722
21829	4530	139	\N	direct	2026-06-21 08:17:38.36722
21830	4531	111	\N	direct	2026-06-21 08:17:38.372579
21831	4531	849	\N	direct	2026-06-21 08:17:38.372579
21832	4532	112	\N	direct	2026-06-21 08:17:38.377575
21833	4532	850	\N	direct	2026-06-21 08:17:38.377575
21834	4533	3234	\N	direct	2026-06-21 08:17:38.380575
21835	4533	261	\N	direct	2026-06-21 08:17:38.380575
21836	4533	728	\N	direct	2026-06-21 08:17:38.380575
21837	4534	960	\N	direct	2026-06-21 08:17:38.384994
21838	4534	1652	\N	direct	2026-06-21 08:17:38.384994
21839	4534	1007	\N	direct	2026-06-21 08:17:38.384994
21840	4535	1549	\N	direct	2026-06-21 08:17:38.391382
21841	4535	878	\N	direct	2026-06-21 08:17:38.391382
21842	4535	601	\N	direct	2026-06-21 08:17:38.391382
21843	4535	3309	\N	direct	2026-06-21 08:17:38.391382
21844	4536	1855	\N	direct	2026-06-21 08:17:38.395471
21845	4536	1216	\N	direct	2026-06-21 08:17:38.395471
21846	4536	3284	\N	direct	2026-06-21 08:17:38.395471
21847	4537	1415	\N	direct	2026-06-21 08:17:38.398477
21848	4537	2608	\N	direct	2026-06-21 08:17:38.398477
21849	4537	3143	\N	direct	2026-06-21 08:17:38.398477
21850	4538	973	\N	direct	2026-06-21 08:17:38.401473
21851	4538	603	\N	direct	2026-06-21 08:17:38.401473
21852	4539	384	\N	direct	2026-06-21 08:17:38.406679
21853	4539	1544	\N	direct	2026-06-21 08:17:38.406679
21854	4540	1644	\N	direct	2026-06-21 08:17:38.41068
21855	4540	1218	\N	direct	2026-06-21 08:17:38.41068
21856	4541	3245	\N	direct	2026-06-21 08:17:38.412999
21857	4541	879	\N	direct	2026-06-21 08:17:38.412999
21858	4542	1215	\N	direct	2026-06-21 08:17:38.415998
21859	4542	3069	\N	direct	2026-06-21 08:17:38.415998
21860	4543	880	\N	direct	2026-06-21 08:17:38.422315
21861	4543	160	\N	direct	2026-06-21 08:17:38.422315
21862	4543	161	\N	direct	2026-06-21 08:17:38.422315
21863	4544	702	\N	direct	2026-06-21 08:17:38.426315
21864	4544	1640	\N	direct	2026-06-21 08:17:38.426315
21865	4544	1642	\N	direct	2026-06-21 08:17:38.426315
21866	4545	933	\N	direct	2026-06-21 08:17:38.430315
21867	4545	3043	\N	direct	2026-06-21 08:17:38.430315
21868	4546	3168	\N	direct	2026-06-21 08:17:38.433534
21869	4546	881	\N	direct	2026-06-21 08:17:38.433534
21870	4547	796	\N	direct	2026-06-21 08:17:38.437539
21871	4547	978	\N	direct	2026-06-21 08:17:38.437539
21872	4548	2908	\N	direct	2026-06-21 08:17:38.441617
21873	4548	2127	\N	direct	2026-06-21 08:17:38.441617
21874	4549	1138	\N	direct	2026-06-21 08:17:38.445874
21875	4549	3014	\N	direct	2026-06-21 08:17:38.445874
21876	4550	1056	\N	direct	2026-06-21 08:17:38.44987
21877	4550	980	\N	direct	2026-06-21 08:17:38.44987
21878	4550	828	\N	direct	2026-06-21 08:17:38.44987
21879	4551	1551	\N	direct	2026-06-21 08:17:38.459852
21880	4551	1824	\N	direct	2026-06-21 08:17:38.459852
21881	4551	1735	\N	direct	2026-06-21 08:17:38.459852
21882	4551	145	\N	direct	2026-06-21 08:17:38.459852
21883	4551	1736	\N	direct	2026-06-21 08:17:38.459852
21884	4551	964	\N	direct	2026-06-21 08:17:38.459852
21885	4552	1032	\N	direct	2026-06-21 08:17:38.464337
21886	4552	141	\N	direct	2026-06-21 08:17:38.464337
21887	4553	1807	\N	direct	2026-06-21 08:17:38.469255
21888	4553	1122	\N	direct	2026-06-21 08:17:38.469255
21889	4554	3343	\N	direct	2026-06-21 08:17:38.47684
21890	4554	1031	\N	direct	2026-06-21 08:17:38.47684
21891	4554	1536	\N	direct	2026-06-21 08:17:38.47684
21892	4555	3390	\N	direct	2026-06-21 08:17:38.483293
21893	4555	3152	\N	direct	2026-06-21 08:17:38.483293
21894	4555	2832	\N	direct	2026-06-21 08:17:38.483293
21895	4555	335	\N	direct	2026-06-21 08:17:38.483293
21896	4555	1304	\N	direct	2026-06-21 08:17:38.483293
21897	4556	91	\N	direct	2026-06-21 08:17:38.490286
21898	4556	836	\N	direct	2026-06-21 08:17:38.490286
21899	4557	347	\N	direct	2026-06-21 08:17:38.495708
21900	4557	350	\N	direct	2026-06-21 08:17:38.495708
21901	4557	2025	\N	direct	2026-06-21 08:17:38.495708
21902	4558	1317	\N	direct	2026-06-21 08:17:38.499619
21903	4558	2406	\N	direct	2026-06-21 08:17:38.499619
21904	4559	3397	\N	direct	2026-06-21 08:17:38.507002
21905	4559	1729	\N	direct	2026-06-21 08:17:38.507002
21906	4560	1836	\N	direct	2026-06-21 08:17:38.511521
21907	4560	3279	\N	direct	2026-06-21 08:17:38.511521
21908	4560	1631	\N	direct	2026-06-21 08:17:38.511521
21909	4561	2187	\N	direct	2026-06-21 08:17:38.515537
21910	4561	2973	\N	direct	2026-06-21 08:17:38.515537
21911	4562	102	\N	direct	2026-06-21 08:17:38.520534
21912	4562	1302	\N	direct	2026-06-21 08:17:38.520534
21913	4563	1564	\N	direct	2026-06-21 08:17:38.538257
21914	4563	195	\N	direct	2026-06-21 08:17:38.538257
21915	4563	1659	\N	direct	2026-06-21 08:17:38.538257
21916	4564	615	\N	direct	2026-06-21 08:17:38.542542
21917	4564	2840	\N	direct	2026-06-21 08:17:38.542542
21918	4565	988	\N	direct	2026-06-21 08:17:38.546572
21919	4565	3163	\N	direct	2026-06-21 08:17:38.546572
21920	4566	3227	\N	direct	2026-06-21 08:17:38.549572
21921	4566	874	\N	direct	2026-06-21 08:17:38.549572
21922	4567	873	\N	direct	2026-06-21 08:17:38.552895
21923	4567	157	\N	direct	2026-06-21 08:17:38.552895
21924	4568	1055	\N	direct	2026-06-21 08:17:38.558475
21925	4568	919	\N	direct	2026-06-21 08:17:38.558475
21926	4569	945	\N	direct	2026-06-21 08:17:38.563778
21927	4569	2580	\N	direct	2026-06-21 08:17:38.563778
21928	4569	2740	\N	direct	2026-06-21 08:17:38.563778
21929	4569	774	\N	direct	2026-06-21 08:17:38.563778
21930	4570	1067	\N	direct	2026-06-21 08:17:38.566781
21931	4570	943	\N	direct	2026-06-21 08:17:38.566781
21932	4571	1854	\N	direct	2026-06-21 08:17:38.572127
21933	4571	197	\N	direct	2026-06-21 08:17:38.572127
21934	4571	2183	\N	direct	2026-06-21 08:17:38.572127
21935	4572	925	\N	direct	2026-06-21 08:17:38.579131
21936	4572	1703	\N	direct	2026-06-21 08:17:38.579131
21937	4572	3355	\N	direct	2026-06-21 08:17:38.579131
21938	4572	3171	\N	direct	2026-06-21 08:17:38.579131
21939	4572	3110	\N	direct	2026-06-21 08:17:38.579131
21940	4572	168	\N	direct	2026-06-21 08:17:38.579131
21941	4572	2582	\N	direct	2026-06-21 08:17:38.579131
21942	4573	3187	\N	direct	2026-06-21 08:17:38.583431
21943	4573	953	\N	direct	2026-06-21 08:17:38.583431
21944	4573	812	\N	direct	2026-06-21 08:17:38.583431
21945	4574	3179	\N	direct	2026-06-21 08:17:38.598923
21946	4574	788	\N	direct	2026-06-21 08:17:38.598923
21947	4575	3136	\N	direct	2026-06-21 08:17:38.606195
21948	4575	179	\N	direct	2026-06-21 08:17:38.606195
21949	4575	734	\N	direct	2026-06-21 08:17:38.606195
21950	4576	2591	\N	direct	2026-06-21 08:17:38.611558
21951	4576	180	\N	direct	2026-06-21 08:17:38.611558
21952	4576	3205	\N	direct	2026-06-21 08:17:38.611558
21953	4576	866	\N	direct	2026-06-21 08:17:38.611558
21954	4576	137	\N	direct	2026-06-21 08:17:38.611558
21955	4577	3307	\N	direct	2026-06-21 08:17:38.615563
21956	4577	2375	\N	direct	2026-06-21 08:17:38.615563
21957	4578	1832	\N	direct	2026-06-21 08:17:38.62056
21958	4578	1723	\N	direct	2026-06-21 08:17:38.62056
21959	4579	166	\N	direct	2026-06-21 08:17:38.629943
21960	4579	695	\N	direct	2026-06-21 08:17:38.629943
21961	4579	609	\N	direct	2026-06-21 08:17:38.629943
21962	4579	2581	\N	direct	2026-06-21 08:17:38.629943
21963	4579	3192	\N	direct	2026-06-21 08:17:38.629943
21964	4579	1830	\N	direct	2026-06-21 08:17:38.629943
21965	4579	1125	\N	direct	2026-06-21 08:17:38.629943
21966	4579	3357	\N	direct	2026-06-21 08:17:38.629943
21967	4579	5	\N	direct	2026-06-21 08:17:38.629943
21968	4579	1608	\N	direct	2026-06-21 08:17:38.629943
21969	4579	3389	\N	direct	2026-06-21 08:17:38.629943
21970	4579	778	\N	direct	2026-06-21 08:17:38.629943
21971	4579	983	\N	direct	2026-06-21 08:17:38.629943
21972	4579	1539	\N	direct	2026-06-21 08:17:38.629943
21973	4580	2935	\N	direct	2026-06-21 08:17:38.634229
21974	4580	2045	\N	direct	2026-06-21 08:17:38.634229
21975	4581	775	\N	direct	2026-06-21 08:17:38.640867
21976	4581	981	\N	direct	2026-06-21 08:17:38.640867
21977	4582	779	\N	direct	2026-06-21 08:17:38.644268
21978	4582	984	\N	direct	2026-06-21 08:17:38.644268
21979	4582	8	\N	direct	2026-06-21 08:17:38.644268
21980	4583	3190	\N	direct	2026-06-21 08:17:38.648267
21981	4583	776	\N	direct	2026-06-21 08:17:38.648267
21982	4583	982	\N	direct	2026-06-21 08:17:38.648267
21983	4584	2596	\N	direct	2026-06-21 08:17:38.653542
21984	4584	185	\N	direct	2026-06-21 08:17:38.653542
21985	4584	3396	\N	direct	2026-06-21 08:17:38.653542
21986	4584	1009	\N	direct	2026-06-21 08:17:38.653542
21987	4585	1602	\N	direct	2026-06-21 08:17:38.660054
21988	4585	2602	\N	direct	2026-06-21 08:17:38.660054
21989	4585	1243	\N	direct	2026-06-21 08:17:38.660054
21990	4585	3130	\N	direct	2026-06-21 08:17:38.660054
21991	4585	2931	\N	direct	2026-06-21 08:17:38.660054
21992	4586	1845	\N	direct	2026-06-21 08:17:38.664524
21993	4586	3148	\N	direct	2026-06-21 08:17:38.664524
21994	4587	760	\N	direct	2026-06-21 08:17:38.667526
21995	4587	1024	\N	direct	2026-06-21 08:17:38.667526
21996	4587	121	\N	direct	2026-06-21 08:17:38.667526
21997	4588	2600	\N	direct	2026-06-21 08:17:38.674043
21998	4588	1268	\N	direct	2026-06-21 08:17:38.674043
21999	4589	177	\N	direct	2026-06-21 08:17:38.678044
22000	4589	1238	\N	direct	2026-06-21 08:17:38.678044
22001	4590	11	\N	direct	2026-06-21 08:17:38.682379
22002	4590	782	\N	direct	2026-06-21 08:17:38.682379
22003	4590	961	\N	direct	2026-06-21 08:17:38.682379
22004	4590	3128	\N	direct	2026-06-21 08:17:38.682379
22005	4591	1597	\N	direct	2026-06-21 08:17:38.68638
22006	4591	1828	\N	direct	2026-06-21 08:17:38.68638
22007	4592	749	\N	direct	2026-06-21 08:17:38.693647
22008	4592	174	\N	direct	2026-06-21 08:17:38.693647
22009	4592	2586	\N	direct	2026-06-21 08:17:38.693647
22010	4592	63	\N	direct	2026-06-21 08:17:38.693647
22011	4592	3214	\N	direct	2026-06-21 08:17:38.693647
22012	4592	2243	\N	direct	2026-06-21 08:17:38.693647
22013	4592	958	\N	direct	2026-06-21 08:17:38.693647
22014	4593	80	\N	direct	2026-06-21 08:17:38.697647
22015	4593	1005	\N	direct	2026-06-21 08:17:38.697647
22016	4594	869	\N	direct	2026-06-21 08:17:38.701666
22017	4594	140	\N	direct	2026-06-21 08:17:38.701666
22018	4595	2587	\N	direct	2026-06-21 08:17:38.707951
22019	4595	175	\N	direct	2026-06-21 08:17:38.707951
22020	4595	765	\N	direct	2026-06-21 08:17:38.707951
22021	4595	78	\N	direct	2026-06-21 08:17:38.707951
22022	4596	750	\N	direct	2026-06-21 08:17:38.710971
22023	4596	64	\N	direct	2026-06-21 08:17:38.710971
22024	4597	946	\N	direct	2026-06-21 08:17:38.715797
22025	4597	3200	\N	direct	2026-06-21 08:17:38.715797
22026	4597	830	\N	direct	2026-06-21 08:17:38.715797
22027	4597	88	\N	direct	2026-06-21 08:17:38.715797
22028	4597	3328	\N	direct	2026-06-21 08:17:38.715797
22029	4598	2588	\N	direct	2026-06-21 08:17:38.724186
22030	4598	176	\N	direct	2026-06-21 08:17:38.724186
22031	4598	1560	\N	direct	2026-06-21 08:17:38.724186
22032	4598	3319	\N	direct	2026-06-21 08:17:38.724186
22033	4598	1004	\N	direct	2026-06-21 08:17:38.724186
22034	4598	1241	\N	direct	2026-06-21 08:17:38.724186
22035	4599	751	\N	direct	2026-06-21 08:17:38.728186
22036	4599	65	\N	direct	2026-06-21 08:17:38.728186
22037	4600	699	\N	direct	2026-06-21 08:17:38.753615
22038	4600	766	\N	direct	2026-06-21 08:17:38.753615
22039	4600	3384	\N	direct	2026-06-21 08:17:38.753615
22040	4600	1236	\N	direct	2026-06-21 08:17:38.753615
22041	4601	769	\N	direct	2026-06-21 08:17:38.758124
22042	4601	3218	\N	direct	2026-06-21 08:17:38.758124
22043	4602	1585	\N	direct	2026-06-21 08:17:38.761134
22044	4602	1537	\N	direct	2026-06-21 08:17:38.761134
22045	4603	3207	\N	direct	2026-06-21 08:17:38.765447
22046	4603	816	\N	direct	2026-06-21 08:17:38.765447
22047	4603	2697	\N	direct	2026-06-21 08:17:38.765447
22048	4603	990	\N	direct	2026-06-21 08:17:38.765447
22049	4604	2592	\N	direct	2026-06-21 08:17:38.772885
22050	4604	3321	\N	direct	2026-06-21 08:17:38.772885
22051	4604	1232	\N	direct	2026-06-21 08:17:38.772885
22052	4604	3269	\N	direct	2026-06-21 08:17:38.772885
22053	4604	1826	\N	direct	2026-06-21 08:17:38.772885
22054	4604	3131	\N	direct	2026-06-21 08:17:38.772885
22055	4604	1674	\N	direct	2026-06-21 08:17:38.772885
22056	4604	1675	\N	direct	2026-06-21 08:17:38.772885
22057	4605	819	\N	direct	2026-06-21 08:17:38.777884
22058	4605	994	\N	direct	2026-06-21 08:17:38.777884
22059	4605	53	\N	direct	2026-06-21 08:17:38.777884
22060	4606	181	\N	direct	2026-06-21 08:17:38.781392
22061	4606	46	\N	direct	2026-06-21 08:17:38.781392
22062	4606	815	\N	direct	2026-06-21 08:17:38.781392
22063	4607	1576	\N	direct	2026-06-21 08:17:38.785702
22064	4607	2919	\N	direct	2026-06-21 08:17:38.785702
22065	4608	2593	\N	direct	2026-06-21 08:17:38.791702
22066	4608	996	\N	direct	2026-06-21 08:17:38.791702
22067	4608	56	\N	direct	2026-06-21 08:17:38.791702
22068	4609	3208	\N	direct	2026-06-21 08:17:38.796062
22069	4609	991	\N	direct	2026-06-21 08:17:38.796062
22070	4609	817	\N	direct	2026-06-21 08:17:38.796062
22071	4610	3209	\N	direct	2026-06-21 08:17:38.799062
22072	4610	51	\N	direct	2026-06-21 08:17:38.799062
22073	4611	993	\N	direct	2026-06-21 08:17:38.802326
22074	4611	818	\N	direct	2026-06-21 08:17:38.802326
22075	4612	59	\N	direct	2026-06-21 08:17:38.809328
22076	4612	823	\N	direct	2026-06-21 08:17:38.809328
22077	4612	3213	\N	direct	2026-06-21 08:17:38.809328
22078	4612	1000	\N	direct	2026-06-21 08:17:38.809328
22079	4613	28	\N	direct	2026-06-21 08:17:38.812635
22080	4613	29	\N	direct	2026-06-21 08:17:38.812635
22081	4613	842	\N	direct	2026-06-21 08:17:38.812635
22082	4614	1231	\N	direct	2026-06-21 08:17:38.815623
22083	4614	2433	\N	direct	2026-06-21 08:17:38.815623
22084	4615	1837	\N	direct	2026-06-21 08:17:38.820607
22085	4615	1015	\N	direct	2026-06-21 08:17:38.820607
22086	4615	94	\N	direct	2026-06-21 08:17:38.820607
22087	4616	2597	\N	direct	2026-06-21 08:17:38.825006
22088	4616	3334	\N	direct	2026-06-21 08:17:38.825006
22089	4616	190	\N	direct	2026-06-21 08:17:38.825006
22090	4617	1834	\N	direct	2026-06-21 08:17:38.829033
22091	4617	1014	\N	direct	2026-06-21 08:17:38.829033
22092	4618	2584	\N	direct	2026-06-21 08:17:38.832413
22093	4618	19	\N	direct	2026-06-21 08:17:38.832413
22094	4618	955	\N	direct	2026-06-21 08:17:38.832413
22095	4619	173	\N	direct	2026-06-21 08:17:38.83841
22096	4619	2594	\N	direct	2026-06-21 08:17:38.83841
22097	4619	1266	\N	direct	2026-06-21 08:17:38.83841
22098	4619	37	\N	direct	2026-06-21 08:17:38.83841
22099	4619	39	\N	direct	2026-06-21 08:17:38.83841
22100	4620	3292	\N	direct	2026-06-21 08:17:38.842749
22101	4620	737	\N	direct	2026-06-21 08:17:38.842749
22102	4621	1548	\N	direct	2026-06-21 08:17:38.845749
22103	4621	1658	\N	direct	2026-06-21 08:17:38.845749
22104	4622	1840	\N	direct	2026-06-21 08:17:38.849747
22105	4622	97	\N	direct	2026-06-21 08:17:38.849747
22106	4622	854	\N	direct	2026-06-21 08:17:38.849747
22107	4623	1612	\N	direct	2026-06-21 08:17:38.854747
22108	4623	3308	\N	direct	2026-06-21 08:17:38.854747
22109	4624	3386	\N	direct	2026-06-21 08:17:38.860253
22110	4624	2599	\N	direct	2026-06-21 08:17:38.860253
22111	4624	188	\N	direct	2026-06-21 08:17:38.860253
22112	4624	3360	\N	direct	2026-06-21 08:17:38.860253
22113	4624	1575	\N	direct	2026-06-21 08:17:38.860253
22114	4625	3235	\N	direct	2026-06-21 08:17:38.863615
22115	4625	855	\N	direct	2026-06-21 08:17:38.863615
22116	4626	2210	\N	direct	2026-06-21 08:17:38.867615
22117	4626	1627	\N	direct	2026-06-21 08:17:38.867615
22118	4627	3147	\N	direct	2026-06-21 08:17:38.873021
22119	4627	1727	\N	direct	2026-06-21 08:17:38.873021
22120	4628	1333	\N	direct	2026-06-21 08:17:38.877016
22121	4628	2513	\N	direct	2026-06-21 08:17:38.877016
22122	4629	3385	\N	direct	2026-06-21 08:17:38.881015
22123	4629	1561	\N	direct	2026-06-21 08:17:38.881015
22124	4629	1237	\N	direct	2026-06-21 08:17:38.881015
22125	4630	1550	\N	direct	2026-06-21 08:17:38.885305
22126	4630	1414	\N	direct	2026-06-21 08:17:38.885305
22127	4630	3398	\N	direct	2026-06-21 08:17:38.885305
22128	4631	3075	\N	direct	2026-06-21 08:17:38.891604
22129	4631	287	\N	direct	2026-06-21 08:17:38.891604
22130	4632	1577	\N	direct	2026-06-21 08:17:38.894605
22131	4632	2918	\N	direct	2026-06-21 08:17:38.894605
22132	4633	171	\N	direct	2026-06-21 08:17:38.899605
22133	4633	2583	\N	direct	2026-06-21 08:17:38.899605
22134	4633	15	\N	direct	2026-06-21 08:17:38.899605
22135	4633	1119	\N	direct	2026-06-21 08:17:38.899605
22136	4634	810	\N	direct	2026-06-21 08:17:38.906075
22137	4634	3185	\N	direct	2026-06-21 08:17:38.906075
22138	4635	1540	\N	direct	2026-06-21 08:17:38.911073
22139	4635	1118	\N	direct	2026-06-21 08:17:38.911073
22140	4636	824	\N	direct	2026-06-21 08:17:38.914485
22141	4636	1001	\N	direct	2026-06-21 08:17:38.914485
22142	4637	954	\N	direct	2026-06-21 08:17:38.920486
22143	4637	781	\N	direct	2026-06-21 08:17:38.920486
22144	4638	835	\N	direct	2026-06-21 08:17:38.926982
22145	4638	90	\N	direct	2026-06-21 08:17:38.926982
22146	4638	3203	\N	direct	2026-06-21 08:17:38.926982
22147	4638	1008	\N	direct	2026-06-21 08:17:38.926982
22148	4638	1213	\N	direct	2026-06-21 08:17:38.926982
22149	4639	99	\N	direct	2026-06-21 08:17:38.930971
22150	4639	859	\N	direct	2026-06-21 08:17:38.930971
22151	4640	3184	\N	direct	2026-06-21 08:17:38.936271
22152	4640	833	\N	direct	2026-06-21 08:17:38.936271
22153	4640	127	\N	direct	2026-06-21 08:17:38.936271
22154	4641	1121	\N	direct	2026-06-21 08:17:38.941579
22155	4641	170	\N	direct	2026-06-21 08:17:38.941579
22156	4642	125	\N	direct	2026-06-21 08:17:38.955909
22157	4642	1538	\N	direct	2026-06-21 08:17:38.955909
22158	4643	3359	\N	direct	2026-06-21 08:17:38.960421
22159	4643	126	\N	direct	2026-06-21 08:17:38.960421
22160	4644	3182	\N	direct	2026-06-21 08:17:38.963853
22161	4644	799	\N	direct	2026-06-21 08:17:38.963853
22162	4645	3183	\N	direct	2026-06-21 08:17:38.967853
22163	4645	832	\N	direct	2026-06-21 08:17:38.967853
22164	4646	1163	\N	direct	2026-06-21 08:17:38.973181
22165	4646	2749	\N	direct	2026-06-21 08:17:38.973181
22166	4646	1030	\N	direct	2026-06-21 08:17:38.973181
22167	4647	3342	\N	direct	2026-06-21 08:17:38.977177
22168	4647	1152	\N	direct	2026-06-21 08:17:38.977177
22169	4648	3231	\N	direct	2026-06-21 08:17:38.981177
22170	4648	860	\N	direct	2026-06-21 08:17:38.981177
22171	4648	130	\N	direct	2026-06-21 08:17:38.981177
22172	4649	1835	\N	direct	2026-06-21 08:17:38.984471
22173	4649	1630	\N	direct	2026-06-21 08:17:38.984471
22174	4649	84	\N	direct	2026-06-21 08:17:38.984471
22175	4650	191	\N	direct	2026-06-21 08:17:38.990466
22176	4650	1574	\N	direct	2026-06-21 08:17:38.990466
22177	4651	1011	\N	direct	2026-06-21 08:17:38.994916
22178	4651	1186	\N	direct	2026-06-21 08:17:38.994916
22179	4652	867	\N	direct	2026-06-21 08:17:38.997913
22180	4652	138	\N	direct	2026-06-21 08:17:38.997913
22181	4652	1021	\N	direct	2026-06-21 08:17:38.997913
22182	4653	3324	\N	direct	2026-06-21 08:17:39.007234
22183	4653	3201	\N	direct	2026-06-21 08:17:39.007234
22184	4653	1034	\N	direct	2026-06-21 08:17:39.007234
22185	4653	829	\N	direct	2026-06-21 08:17:39.007234
22186	4653	86	\N	direct	2026-06-21 08:17:39.007234
22187	4653	1193	\N	direct	2026-06-21 08:17:39.007234
22188	4653	2595	\N	direct	2026-06-21 08:17:39.007234
22189	4653	184	\N	direct	2026-06-21 08:17:39.007234
22190	4653	1591	\N	direct	2026-06-21 08:17:39.007234
22191	4653	870	\N	direct	2026-06-21 08:17:39.007234
22192	4653	1439	\N	direct	2026-06-21 08:17:39.007234
22193	4654	2161	\N	direct	2026-06-21 08:17:39.011546
22194	4654	1197	\N	direct	2026-06-21 08:17:39.011546
22195	4655	3329	\N	direct	2026-06-21 08:17:39.015554
22196	4655	1198	\N	direct	2026-06-21 08:17:39.015554
22197	4656	3332	\N	direct	2026-06-21 08:17:39.021549
22198	4656	1191	\N	direct	2026-06-21 08:17:39.021549
22199	4656	187	\N	direct	2026-06-21 08:17:39.021549
22200	4656	100	\N	direct	2026-06-21 08:17:39.021549
22201	4657	2598	\N	direct	2026-06-21 08:17:39.025863
22202	4657	186	\N	direct	2026-06-21 08:17:39.025863
22203	4658	1928	\N	direct	2026-06-21 08:17:39.029861
22204	4658	2781	\N	direct	2026-06-21 08:17:39.029861
22205	4659	3243	\N	direct	2026-06-21 08:17:39.0332
22206	4659	872	\N	direct	2026-06-21 08:17:39.0332
22207	4659	1010	\N	direct	2026-06-21 08:17:39.0332
22208	4660	950	\N	direct	2026-06-21 08:17:39.038199
22209	4660	1821	\N	direct	2026-06-21 08:17:39.038199
22210	4660	1290	\N	direct	2026-06-21 08:17:39.038199
22211	4661	1547	\N	direct	2026-06-21 08:17:39.042496
22212	4661	1203	\N	direct	2026-06-21 08:17:39.042496
22213	4661	1657	\N	direct	2026-06-21 08:17:39.042496
22214	4662	1202	\N	direct	2026-06-21 08:17:39.046497
22215	4662	3277	\N	direct	2026-06-21 08:17:39.046497
22216	4662	150	\N	direct	2026-06-21 08:17:39.046497
22217	4663	2604	\N	direct	2026-06-21 08:17:39.051497
22218	4663	192	\N	direct	2026-06-21 08:17:39.051497
22219	4663	1661	\N	direct	2026-06-21 08:17:39.051497
22220	4663	2056	\N	direct	2026-06-21 08:17:39.051497
22221	4663	1299	\N	direct	2026-06-21 08:17:39.051497
22222	4664	1590	\N	direct	2026-06-21 08:17:39.059896
22223	4664	3388	\N	direct	2026-06-21 08:17:39.059896
22224	4665	1851	\N	direct	2026-06-21 08:17:39.063341
22225	4665	194	\N	direct	2026-06-21 08:17:39.063341
22226	4666	1566	\N	direct	2026-06-21 08:17:39.067341
22227	4666	193	\N	direct	2026-06-21 08:17:39.067341
22228	4667	747	\N	direct	2026-06-21 08:17:39.070339
22229	4667	1527	\N	direct	2026-06-21 08:17:39.070339
22366	4731	1064	\N	direct	2026-06-21 08:21:21.726871
22367	4731	3088	\N	direct	2026-06-21 08:21:21.726871
22368	4732	1285	\N	direct	2026-06-21 08:21:21.726871
22369	4732	1812	\N	direct	2026-06-21 08:21:21.726871
22370	4733	3112	\N	direct	2026-06-21 08:21:21.742693
22371	4733	1517	\N	direct	2026-06-21 08:21:21.742693
22372	4734	143	\N	direct	2026-06-21 08:21:21.742693
22373	4734	1738	\N	direct	2026-06-21 08:21:21.742693
22374	4735	1757	\N	direct	2026-06-21 08:21:21.742693
22375	4735	626	\N	direct	2026-06-21 08:21:21.742693
22376	4736	625	\N	direct	2026-06-21 08:21:21.758691
22377	4736	1589	\N	direct	2026-06-21 08:21:21.758691
22378	4737	323	\N	direct	2026-06-21 08:21:21.758691
22379	4737	2409	\N	direct	2026-06-21 08:21:21.758691
22380	4738	1035	\N	direct	2026-06-21 08:21:21.758691
22381	4738	1159	\N	direct	2026-06-21 08:21:21.758691
22382	4739	1841	\N	direct	2026-06-21 08:21:21.774792
22383	4739	1635	\N	direct	2026-06-21 08:21:21.774792
22384	4740	1275	\N	direct	2026-06-21 08:21:21.781372
22385	4740	3374	\N	direct	2026-06-21 08:21:21.781372
22386	4741	3327	\N	direct	2026-06-21 08:21:21.785387
22387	4741	1195	\N	direct	2026-06-21 08:21:21.785387
22388	4742	1194	\N	direct	2026-06-21 08:21:21.790915
22389	4742	3022	\N	direct	2026-06-21 08:21:21.790915
22390	4743	3345	\N	direct	2026-06-21 08:21:21.798632
22391	4743	2170	\N	direct	2026-06-21 08:21:21.798632
22392	4744	3378	\N	direct	2026-06-21 08:21:21.800639
22393	4744	1704	\N	direct	2026-06-21 08:21:21.800639
22394	4745	2783	\N	direct	2026-06-21 08:21:21.811586
22395	4745	256	\N	direct	2026-06-21 08:21:21.811586
22396	4746	152	\N	direct	2026-06-21 08:21:21.817611
22397	4746	1542	\N	direct	2026-06-21 08:21:21.817611
22398	4746	613	\N	direct	2026-06-21 08:21:21.817611
22399	4747	3229	\N	direct	2026-06-21 08:21:21.824645
22400	4747	876	\N	direct	2026-06-21 08:21:21.824645
22401	4748	153	\N	direct	2026-06-21 08:21:21.832677
22402	4748	1656	\N	direct	2026-06-21 08:21:21.832677
22403	4749	3228	\N	direct	2026-06-21 08:21:21.836752
22404	4749	875	\N	direct	2026-06-21 08:21:21.836752
22405	4750	2903	\N	direct	2026-06-21 08:21:21.838502
22406	4750	1201	\N	direct	2026-06-21 08:21:21.838502
22407	4750	2172	\N	direct	2026-06-21 08:21:21.838502
22408	4751	1208	\N	direct	2026-06-21 08:21:21.838502
22409	4751	2215	\N	direct	2026-06-21 08:21:21.838502
22458	4775	1067	\N	direct	2026-06-21 08:57:50.99729
22459	4775	943	\N	direct	2026-06-21 08:57:50.99729
22460	4776	1056	\N	direct	2026-06-21 08:57:51.009519
22461	4776	980	\N	direct	2026-06-21 08:57:51.009519
22462	4777	1055	\N	direct	2026-06-21 08:57:51.033226
22463	4777	919	\N	direct	2026-06-21 08:57:51.033226
22464	4778	166	\N	direct	2026-06-21 09:04:07.977011
22465	4778	5	\N	direct	2026-06-21 09:04:07.977011
22466	4779	183	\N	direct	2026-06-21 09:04:08.049141
22467	4779	48	\N	direct	2026-06-21 09:04:08.049141
22468	4780	180	\N	direct	2026-06-21 09:04:08.060282
22469	4780	137	\N	direct	2026-06-21 09:04:08.060282
22470	4781	174	\N	direct	2026-06-21 09:04:08.073975
22471	4781	63	\N	direct	2026-06-21 09:04:08.073975
22472	4782	175	\N	direct	2026-06-21 09:04:08.083447
22473	4782	78	\N	direct	2026-06-21 09:04:08.083447
22474	4783	181	\N	direct	2026-06-21 09:04:08.091447
22475	4783	46	\N	direct	2026-06-21 09:04:08.091447
22476	4784	173	\N	direct	2026-06-21 09:04:08.104841
22477	4784	37	\N	direct	2026-06-21 09:04:08.104841
22478	4784	39	\N	direct	2026-06-21 09:04:08.104841
22479	4785	171	\N	direct	2026-06-21 09:04:08.11954
22480	4785	15	\N	direct	2026-06-21 09:04:08.11954
22481	4786	86	\N	direct	2026-06-21 09:04:08.129049
22482	4786	184	\N	direct	2026-06-21 09:04:08.129049
22483	4787	187	\N	direct	2026-06-21 09:04:08.157595
22484	4787	100	\N	direct	2026-06-21 09:04:08.157595
\.


--
-- Data for Name: grc_normalized_controls; Type: TABLE DATA; Schema: public; Owner: grc_app
--

COPY public.grc_normalized_controls (id, code, name, statement, objective, control_owner, implementation_guidance, testing_guidance, maturity_level, created_at, domain, source, common_group_id, recommended_evidence, run_id, review_status, reviewed_by, reviewed_at) FROM stdin;
4673	NCF0193	Head of Information Security/CISO responsibilities	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.428938	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "CISO Job Description and KPIs", "frameworks": [{"code": "1.5.3.b", "framework": "SBP ETGRMF"}, {"code": "1.2.11", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Formal CISO job description and defined KPIs covering enterprise-wide security risk management and mitigation effectiveness.", "framework_count": 2}]	18	pending	\N	\N
4678	NCF0198	Security Operations Centre	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.450686	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Information Security Operations Management Documentation", "frameworks": [{"code": "12.2.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "DS.8", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Comprehensive documentation of SOC operational roles, responsibilities, and compliance with NCA regulations.", "framework_count": 2}]	18	pending	\N	\N
4679	NCF0199	Establish a cyber security awareness program	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.455779	Awareness & Training	ai_normalized	\N	[{"name": "Security Awareness Program Documentation", "frameworks": [{"code": "2.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "CIS Control 14 - Safeguard 14.1", "framework": "CIS Critical Security Controls v8"}], "description": "Comprehensive documentation of the security awareness program, including charter, budget approval, training content, and program review records.", "framework_count": 2}]	18	pending	\N	\N
4684	NCF0204	Configure Automatic Anti-Malware Signature Updates	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.480483	Network Security	ai_normalized	\N	[{"name": "Anti-malware update compliance reports", "frameworks": [{"code": "CIS Control 10 - Safeguard 10.2", "framework": "CIS Critical Security Controls v8"}, {"code": "9.4.5.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Reports verifying compliance with anti-malware update requirements.", "framework_count": 2}]	18	pending	\N	\N
4689	NCF0209	Assign Access Based on Job Classification and Least Privilege	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.501683	Access Control & Identity Management	ai_normalized	\N	[{"name": "Role Definition and Access Control Documentation", "frameworks": [{"code": "7.2.2", "framework": "PCI Data Security Standard"}, {"code": "CC6.3", "framework": "SOC 2 Type II"}], "description": "Documented role definitions and access control matrices mapping job classifications to system permissions.", "framework_count": 2}]	18	pending	\N	\N
4695	NCF0215	Separation of Duties	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.536004	Access Control & Identity Management	ai_normalized	\N	[{"name": "Separation of Duties Documentation", "frameworks": [{"code": "AC-5", "framework": "NIST SP 800-53 Rev 5"}, {"code": "8.1.6", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation outlining the separation of duties, including a matrix and change workflow.", "framework_count": 2}, {"name": "Role Definitions and Access Records", "frameworks": [{"code": "AC-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records detailing role definitions with incompatible duties and system access authorizations.", "framework_count": 1}, {"name": "Competency Records", "frameworks": [{"code": "8.1.6", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Records of the competencies of individuals responsible for implementing controls.", "framework_count": 1}]	18	pending	\N	\N
4698	NCF0218	ADHIE — Disable Inactive Accounts After 60 Days	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.550549	Access Control & Identity Management	ai_normalized	\N	[{"name": "Account Inactivity Management", "frameworks": [{"code": "6.1.3.8", "framework": "DOH Policy on the Abu Dhabi Health Information Exchange (ADHIE)"}, {"code": "8.2.6", "framework": "PCI Data Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of account inactivity detection, disablement automation, and related audit logs.", "framework_count": 2}]	18	pending	\N	\N
4703	NCF0223	Implement physical security process	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.579442	Physical & Environmental Security	ai_normalized	\N	[{"name": "Access Control Records", "frameworks": [{"code": "3.1", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Records related to physical access control, including visitor management logs and data center access logs.", "framework_count": 1}, {"name": "Security Camera Evidence", "frameworks": [{"code": "3.1", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Evidence captured by security cameras monitoring physical access points.", "framework_count": 1}]	18	pending	\N	\N
4708	NCF0228	Fire protection and suppression systems	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.600603	Physical & Environmental Security	ai_normalized	\N	[{"name": "Fire Detection and Suppression System Documentation", "frameworks": [{"code": "9.9.1.4", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "PE-13", "framework": "NIST SP 800-53 Rev 5"}], "description": "Comprehensive documentation covering specifications, inspection reports, and drill records for fire detection and suppression systems.", "framework_count": 2}]	18	pending	\N	\N
4714	NCF0234	Information Asset Disposal	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.631336	Data Protection & Privacy	ai_normalized	\N	[{"name": "Asset Disposal Policy and Criteria", "frameworks": [{"code": "AM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "§164.310(d)(2)(i)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Document outlining asset disposal triggers, criteria, and related policies, including approval records and legal references.", "framework_count": 2}]	18	pending	\N	\N
4719	NCF0239	System Log Management	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.663394	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Log Management Policy and Procedures", "frameworks": [{"code": "12.2.2", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "09.ac", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented policy and procedures addressing log management, retention, and protection.", "framework_count": 2}, {"name": "SIEM Access Control Records", "frameworks": [{"code": "OM 6.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.ac", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating access control activities within the SIEM, including relevant dates and performers.", "framework_count": 2}, {"name": "Centralized Log Management Evidence", "frameworks": [{"code": "OM 6.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of centralized log management/SIEM deployment, including retention and protection details.", "framework_count": 1}, {"name": "SIEM Operator Independence Evidence", "frameworks": [{"code": "OM 6.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the independence of SIEM operators, including dates and ownership.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "09.ac", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Matrix mapping roles to permissions for relevant systems, identifying owners and responsibilities.", "framework_count": 1}, {"name": "User Access Records", "frameworks": [{"code": "09.ac", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of user access provisioning, modification, and review activities.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.ac", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating personnel awareness of log management requirements.", "framework_count": 1}]	18	pending	\N	\N
4668	NCF0188	Technology risk management framework	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.391837	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Technology Risk Management Framework", "frameworks": [{"code": "5.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "4.1.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Document outlining the approved technology risk management framework and its implementation across the organization.", "framework_count": 2}, {"name": "Roles & Responsibilities Matrix", "frameworks": [{"code": "5.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Document detailing the roles and responsibilities related to technology risk management.", "framework_count": 1}, {"name": "Plan Update History", "frameworks": [{"code": "5.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Record of updates made to the technology risk management plan.", "framework_count": 1}, {"name": "Evidence of Framework Implementation", "frameworks": [{"code": "4.1.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation demonstrating how the technology risk management framework has been implemented within the organization.", "framework_count": 1}]	18	pending	\N	\N
4669	NCF0189	Policies for Information Security	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.396925	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Information Security Policy Documentation", "frameworks": [{"code": "A.5.1", "framework": "ISO/IEC 27001:2022"}], "description": "Master ISMS policy document signed by top management, including approval records, acknowledgment logs, and communication evidence.", "framework_count": 1}, {"name": "Topic-Specific Policies Register", "frameworks": [{"code": "A.5.1", "framework": "ISO/IEC 27001:2022"}], "description": "Index of all subordinate policies with details such as owners, version numbers, and review dates.", "framework_count": 1}, {"name": "Annual Policy Review Records", "frameworks": [{"code": "A.5.1", "framework": "ISO/IEC 27001:2022"}], "description": "Minutes of the scheduled policy review showing changes considered, approval, and next review date.", "framework_count": 1}]	18	pending	\N	\N
4720	NCF0240	IT Audit Function	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.663394	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "IT Audit Documentation", "frameworks": [{"code": "15.1.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "06.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive documentation including IT audit charter, reports, and procedures addressing Information Systems Audit Controls.", "framework_count": 2}]	18	pending	\N	\N
4727	NCF0247	Business Continuity Management System	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.694909	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Business Continuity Plan and Documentation", "frameworks": [{"code": "9.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.4", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Comprehensive documentation of the business continuity plan, including recovery procedures and integration with the organizational management system.", "framework_count": 2}]	18	pending	\N	\N
4728	NCF0248	DR Plan Testing	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.710687	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Contingency Test Reports", "frameworks": [{"code": "8.3.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "I.6", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Comprehensive reports and records from contingency tests, including results, scenarios, and deficiencies identified.", "framework_count": 2}]	18	pending	\N	\N
4732	NCF0252	IoT Device Inventory	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.726871	Asset Management	ai_normalized	\N	[{"name": "IoT Device and Hardware Asset Inventory", "frameworks": [{"code": "11.5.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "ID.AM-1", "framework": "NIST Cybersecurity Framework"}], "description": "A comprehensive inventory register and mapping documentation for IoT devices and hardware assets.", "framework_count": 2}, {"name": "Discovery Scan Results", "frameworks": [{"code": "ID.AM-1", "framework": "NIST Cybersecurity Framework"}], "description": "Results from discovery scans that identify hardware assets within the network.", "framework_count": 1}]	18	pending	\N	\N
4738	NCF0258	Test Information	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.758691	Application & Software Security	ai_normalized	\N	[{"name": "Test Data Management Policy and Controls", "frameworks": [{"code": "A.8.33", "framework": "ISO/IEC 27001:2022"}], "description": "Policy and controls governing the sourcing, protection, access, and deletion of test data.", "framework_count": 1}]	18	pending	\N	\N
4740	NCF0260	System Hardening Standards	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.774792	Configuration & Change Management	ai_normalized	\N	[{"name": "System Hardening Standards Documentation", "frameworks": [{"code": "11.3.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "2.3", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Documentation outlining the standards and benchmarks for system hardening and configuration baselines.", "framework_count": 2}]	18	pending	\N	\N
4745	NCF0265	Remediate vulnerabilities	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.800639	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Vulnerability Remediation Documentation", "frameworks": [{"code": "CIS Control 7 - Safeguard 7.7", "framework": "CIS Critical Security Controls v8"}], "description": "Records and reports related to the remediation of vulnerabilities, including timelines and risk acceptance for unresolved issues.", "framework_count": 1}]	18	pending	\N	\N
4749	NCF0269	Responsibilities and Procedures	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.830668	Incident Management	ai_normalized	\N	[{"name": "Incident Response Plan", "frameworks": [{"code": "12.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "11.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "A comprehensive plan detailing the incident response procedures, roles, and contact information.", "framework_count": 2}, {"name": "Response Team Roles and Responsibilities", "frameworks": [{"code": "12.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "11.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented roles and responsibilities for the incident response team, including escalation procedures.", "framework_count": 2}, {"name": "Response Procedures", "frameworks": [{"code": "12.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "11.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedures for responding to incidents, including control points and exceptions.", "framework_count": 2}, {"name": "Incident Register", "frameworks": [{"code": "11.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "A record of incidents including case records, root cause analysis, and lessons learned.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "11.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications to personnel informing them of incident response requirements, including attendee lists and content references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "11.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer details, observations, and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4560	NCF0080	Configuration Change Control	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.504992	Configuration & Change Management	ai_normalized	\N	[{"name": "Change Management Policy", "frameworks": [{"code": "PR.IP-3", "framework": "NIST Cybersecurity Framework"}, {"code": "CC8.1", "framework": "SOC 2 Type II"}, {"code": "CM-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Document outlining the policies and procedures for managing changes within the organization.", "framework_count": 3}, {"name": "Change Records", "frameworks": [{"code": "PR.IP-3", "framework": "NIST Cybersecurity Framework"}, {"code": "CC8.1", "framework": "SOC 2 Type II"}, {"code": "CM-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of all change requests, approvals, and related records.", "framework_count": 3}, {"name": "Approval Documentation", "frameworks": [{"code": "PR.IP-3", "framework": "NIST Cybersecurity Framework"}, {"code": "CC8.1", "framework": "SOC 2 Type II"}, {"code": "CM-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of approvals for changes, including meeting minutes and other relevant documentation.", "framework_count": 3}, {"name": "Change Testing and Validation Documentation", "frameworks": [{"code": "CC8.1", "framework": "SOC 2 Type II"}], "description": "Records demonstrating that changes have been tested and validated before implementation.", "framework_count": 1}, {"name": "Emergency Change Procedures", "frameworks": [{"code": "CC8.1", "framework": "SOC 2 Type II"}], "description": "Documentation outlining procedures for handling emergency changes and post-implementation reviews.", "framework_count": 1}, {"name": "Security Impact Analysis Documentation", "frameworks": [{"code": "CM-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Analysis documentation assessing the security impact of proposed changes.", "framework_count": 1}]	18	pending	\N	\N
4486	NCF0006	Technology Risk Register	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.092465	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Technology Risk Register", "frameworks": [{"code": "4.5.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "A comprehensive register documenting identified technology risks and their management.", "framework_count": 1}, {"name": "Risk Reports to Management", "frameworks": [{"code": "4.5.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Reports detailing risk assessments and management strategies submitted to the board and senior management.", "framework_count": 1}]	18	pending	\N	\N
4496	NCF0016	IT Network Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.142517	Network Security	ai_normalized	\N	[{"name": "Network Baseline and Architecture Documentation", "frameworks": [{"code": "DE.AE-1", "framework": "NIST Cybersecurity Framework"}, {"code": "2.2.2(e)", "framework": "SBP Internet Banking Framework"}, {"code": "13.6", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "09.m", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "CM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive documentation including network baselines, security architecture, and topology diagrams.", "framework_count": 5}, {"name": "Network Control Inventory", "frameworks": [{"code": "2.2.2(e)", "framework": "SBP Internet Banking Framework"}, {"code": "CM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of network controls including firewalls, IDS/IPS, and other security measures.", "framework_count": 2}, {"name": "Network Security Validation Reports", "frameworks": [{"code": "2.2.2(e)", "framework": "SBP Internet Banking Framework"}, {"code": "CM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Periodic reports validating the effectiveness of network security controls.", "framework_count": 2}, {"name": "Network Security Policies and Procedures", "frameworks": [{"code": "13.6", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "09.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policies and documented procedures addressing network controls and access.", "framework_count": 2}, {"name": "Network Access Controls", "frameworks": [{"code": "13.6", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "CM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of network access controls implemented to secure network access.", "framework_count": 2}, {"name": "Network Segmentation Evidence", "frameworks": [{"code": "2.2.2(e)", "framework": "SBP Internet Banking Framework"}], "description": "Configuration evidence demonstrating network segmentation between different zones.", "framework_count": 1}, {"name": "Firewall Configurations", "frameworks": [{"code": "13.6", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation of firewall configurations as part of network security measures.", "framework_count": 1}, {"name": "Network Threat/Vulnerability Assessment", "frameworks": [{"code": "CM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Assessment reports detailing network threats and vulnerabilities with recommendations.", "framework_count": 1}, {"name": "Centralized Network Management Evidence", "frameworks": [{"code": "CM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence supporting the implementation of centralized network management controls.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating personnel awareness of network security requirements.", "framework_count": 1}, {"name": "Network Device Configuration Baselines", "frameworks": [{"code": "09.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of network device configuration baselines and ruleset reviews.", "framework_count": 1}]	18	pending	\N	\N
4499	NCF0019	Access Revocation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.158277	Access Control & Identity Management	ai_normalized	\N	[{"name": "Access Revocation Procedures", "frameworks": [{"code": "3.4", "framework": "SABIC CyberTrust Guidelines"}, {"code": "9.1.7", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documented procedures and records for revoking access upon termination of employment.", "framework_count": 2}]	18	pending	\N	\N
4508	NCF0028	Clear Desk & Clear Screen Policy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.1999	Physical & Environmental Security	ai_normalized	\N	[{"name": "Clear Desk and Clear Screen Policy", "frameworks": [{"code": "PE 3.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "A.7.7", "framework": "ISO/IEC 27001:2022"}], "description": "Board/management-approved policy document outlining requirements, scope, applicability, roles, and responsibilities for clear desk and screen practices.", "framework_count": 2}, {"name": "Clear Desk Audit Records", "frameworks": [{"code": "PE 3.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "A.7.7", "framework": "ISO/IEC 27001:2022"}], "description": "Records demonstrating the occurrence of clear desk audits, including dates, performers, and approvers where applicable.", "framework_count": 2}, {"name": "Screen Lock Configuration Evidence", "frameworks": [{"code": "PE 3.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "A.7.7", "framework": "ISO/IEC 27001:2022"}], "description": "Extracts or screenshots showing the configuration of screen lock settings in effect, including date and system identifiers.", "framework_count": 2}, {"name": "Signed Policy Acknowledgements", "frameworks": [{"code": "PE 3.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of signed acknowledgements from staff confirming understanding and acceptance of the clear desk and screen policy.", "framework_count": 1}, {"name": "Lockable Storage Provision Evidence", "frameworks": [{"code": "A.7.7", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence confirming that all staff have access to lockable storage options for confidential materials.", "framework_count": 1}, {"name": "Secure Disposal Bin Placement Map", "frameworks": [{"code": "A.7.7", "framework": "ISO/IEC 27001:2022"}], "description": "Map indicating the locations of confidential waste bins throughout the facilities.", "framework_count": 1}, {"name": "Awareness Material - Clear Desk", "frameworks": [{"code": "A.7.7", "framework": "ISO/IEC 27001:2022"}], "description": "Training materials, posters, and signage promoting clear desk and screen rules to staff.", "framework_count": 1}]	18	pending	\N	\N
4515	NCF0035	Accuracy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.244866	Data Protection & Privacy	ai_normalized	\N	[{"name": "Data Quality and Accuracy Policy", "frameworks": [{"code": "Article 5(1)(d)", "framework": "General Data Protection Regulation"}, {"code": "13.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing data quality and accuracy, including procedures for updates and rectification.", "framework_count": 2}]	18	pending	\N	\N
4520	NCF0040	Control of Internal Processing	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.269419	Data Protection & Privacy	ai_normalized	\N	[{"name": "Approved Policy and Standards for Control of Internal Processing", "frameworks": [{"code": "10.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Control of Internal Processing, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Documented Procedures for Control of Internal Processing", "frameworks": [{"code": "10.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Control of Internal Processing, including step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Awareness Communications for Personnel", "frameworks": [{"code": "10.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements, including attendee list, delivery dates, and content/module references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions to demonstrate that the activity occurred.", "framework_count": 1}, {"name": "Internal Processing Validation Requirements", "frameworks": [{"code": "SA 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of internal processing validation requirements, with date, owner, and reference to related policy.", "framework_count": 1}, {"name": "Developer Compliance Evidence", "frameworks": [{"code": "SA 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating developer compliance with implementation of the control, with date, owner, and reference to related policy or procedure.", "framework_count": 1}, {"name": "Validation Check Effectiveness Reviews", "frameworks": [{"code": "SA 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating effectiveness reviews of validation checks, with date, owner, and reference to related policy.", "framework_count": 1}]	18	pending	\N	\N
4526	NCF0046	Information Exchange	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.318452	Data Protection & Privacy	ai_normalized	\N	[{"name": "Interconnection Security Agreements and Policies", "frameworks": [{"code": "CA-3", "framework": "NIST SP 800-53 Rev 5"}, {"code": "09.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policies and standards addressing Information Exchange Policies and interconnection security agreements, including procedures and documentation.", "framework_count": 2}, {"name": "Information Exchange Agreements", "frameworks": [{"code": "09.s", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "09.t", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Information exchange agreements and secure transfer mechanism configurations, including security clauses and obligations.", "framework_count": 2}, {"name": "Awareness Communications", "frameworks": [{"code": "09.s", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "09.t", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements, including attendee lists and delivery details.", "framework_count": 2}, {"name": "Exchange Agreements Procedures", "frameworks": [{"code": "09.t", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Exchange Agreements, including security clauses and obligations.", "framework_count": 1}, {"name": "Third-party Risk Assessment Records", "frameworks": [{"code": "09.t", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of third-party risk assessments and ongoing monitoring, demonstrating the activity occurred with relevant details.", "framework_count": 1}]	18	pending	\N	\N
4539	NCF0059	Managed Continuity	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.401473	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Business Continuity Documentation", "frameworks": [{"code": "DSS04", "framework": "COBIT 2019"}, {"code": "DS.11", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Comprehensive documentation including policies, plans, and procedures for business continuity and disaster recovery.", "framework_count": 2}]	18	pending	\N	\N
4542	NCF0062	Recovery Objectives (RTO/RPO)	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.412999	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Recovery Objectives Documentation", "frameworks": [{"code": "8.2.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "5.3.1.e", "framework": "SBP ETGRMF"}], "description": "Comprehensive documentation of RTO/RPO requirements, business impact analysis, and recovery priorities for IT systems and applications.", "framework_count": 2}]	18	pending	\N	\N
4549	NCF0069	Project Documentation Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.441617	Asset Management	ai_normalized	\N	[{"name": "Project Documentation Repository", "frameworks": [{"code": "5.1.3", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "4.2.5.b", "framework": "SBP ETGRMF"}], "description": "A comprehensive repository containing all project documentation with approval records and checklists for each project phase.", "framework_count": 2}, {"name": "Business Case and Feasibility Analysis", "frameworks": [{"code": "5.1.3", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Examples of business cases and feasibility analyses conducted for projects.", "framework_count": 1}]	18	pending	\N	\N
4553	NCF0073	Monitoring Third-Party Risks and Benefits	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.463351	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third-Party Risk Monitoring Evidence", "frameworks": [{"code": "MANAGE 3.1", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}, {"code": "3.4.3", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documented evidence demonstrating the outcome of monitoring third-party risks, including assessments and ongoing reviews.", "framework_count": 2}]	18	pending	\N	\N
4558	NCF0078	Web Application Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.494709	Application & Software Security	ai_normalized	\N	[{"name": "Web Application Firewall (WAF) Documentation", "frameworks": [{"code": "9.4.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation and evidence related to the deployment, tuning, and rule set of the Web Application Firewall.", "framework_count": 1}]	18	pending	\N	\N
4562	NCF0082	Technical Vulnerability Assessment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.515537	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Vulnerability Assessment Reports", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "13.1.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Reports detailing vulnerability assessments including scope, methodology, findings, evidence references, risk ratings, recommendations, and management responses.", "framework_count": 2}, {"name": "Annual Security Assessment Schedule", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive schedule for annual security assessments including scope, criteria, methodology, findings, risk ratings, recommendations, and acceptance/treatment decisions.", "framework_count": 1}, {"name": "Penetration Test Reports", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Detailed reports of penetration tests including scope, methodology, findings, evidence references, risk ratings, recommendations, and management responses.", "framework_count": 1}, {"name": "Web Application Security Assessment Reports", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports on web application security assessments including scope, methodology, findings, evidence references, risk ratings, recommendations, and management responses.", "framework_count": 1}, {"name": "Mitigation Tracking Records", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating mitigation activities, including date, performer, approver where applicable, and references to relevant assessments.", "framework_count": 1}, {"name": "Mitigation Effectiveness Verification Records", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records verifying the effectiveness of mitigation activities, including date, performer, approver where applicable, and references.", "framework_count": 1}, {"name": "Reports Shared with DOH", "frameworks": [{"code": "OM 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports shared with the Department of Health including scope, methodology, findings, evidence references, risk ratings, recommendations, and management responses.", "framework_count": 1}]	18	pending	\N	\N
4566	NCF0086	Reporting Security Weaknesses	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.545573	Incident Management	ai_normalized	\N	[{"name": "Weakness Reporting Procedure and Awareness Materials", "frameworks": [{"code": "12.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "11.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of the procedure for reporting weaknesses along with awareness materials to inform personnel about the reporting process.", "framework_count": 2}]	18	pending	\N	\N
4570	NCF0090	Continual Improvement	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.562776	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Continual Improvement Documentation", "frameworks": [{"code": "10.1", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "10.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Comprehensive documentation of continual improvement initiatives, including registers, reports, and action trackers.", "framework_count": 2}]	18	pending	\N	\N
4577	NCF0097	Encryption Key Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.611196	Cryptography & Key Management	ai_normalized	\N	[{"name": "Encryption Key Management Policy and Procedures", "frameworks": [{"code": "CC6.9", "framework": "SOC 2 Type II"}, {"code": "9.1.14.6", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Comprehensive documentation outlining the management, rotation, and access control of encryption keys.", "framework_count": 2}, {"name": "Database Encryption Configuration", "frameworks": [{"code": "9.1.14.6", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Configuration details for database encryption methods such as TDE and column-level encryption.", "framework_count": 1}]	18	pending	\N	\N
4579	NCF0099	Security Awareness and Training	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.619558	Awareness & Training	ai_normalized	\N	[{"name": "Training Completion Records", "frameworks": [{"code": "1.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "§164.308(a)(5)(i)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "1.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PR.AT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "3.6.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "ELC-04", "framework": "SOX IT General Controls"}, {"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "AT-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "02.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating completion of training by all workforce members, including dates and participant details.", "framework_count": 11}, {"name": "Training Program Documentation", "frameworks": [{"code": "1.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "1.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PR.AT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "3.6.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "ELC-04", "framework": "SOX IT General Controls"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Comprehensive documentation of the training program including objectives, content, and delivery methods.", "framework_count": 8}, {"name": "Awareness Materials", "frameworks": [{"code": "1.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "§164.308(a)(5)(i)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PR.AT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "02.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Materials used to promote security awareness, including campaigns and educational content.", "framework_count": 7}, {"name": "Training Effectiveness Assessments", "frameworks": [{"code": "Article 14(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "3.6.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Evaluations measuring the effectiveness of training programs, including results and recommendations.", "framework_count": 6}, {"name": "Training Attendance Records", "frameworks": [{"code": "Article 14(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "02.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "DS.6", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records showing attendance at training sessions, including details of participants and session dates.", "framework_count": 4}, {"name": "Phishing Simulation Results", "frameworks": [{"code": "AT-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Results from phishing simulations used to assess and improve security awareness among employees.", "framework_count": 2}, {"name": "Annual Training Calendar", "frameworks": [{"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "AT-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "A calendar outlining the schedule for security training sessions throughout the year.", "framework_count": 2}, {"name": "Senior Management Training Evidence", "frameworks": [{"code": "Article 14(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation evidencing training provided to senior management on security awareness.", "framework_count": 1}, {"name": "Role-Based Training Records", "frameworks": [{"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Records of specialized training tailored for specific roles within the organization.", "framework_count": 1}, {"name": "Documented Information Security Training", "frameworks": [{"code": "DS.6", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documentation of information security training and awareness programs as per regulatory requirements.", "framework_count": 1}, {"name": "NCA Assessment/Compliance Records", "frameworks": [{"code": "DS.6", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of assessments conducted by the NCA to ensure compliance with information security training requirements.", "framework_count": 1}]	18	pending	\N	\N
4585	NCF0105	Remote Access	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.652543	Network Security	ai_normalized	\N	[{"name": "Remote Access Policy", "frameworks": [{"code": "AC-17", "framework": "NIST SP 800-53 Rev 5"}, {"code": "7.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "2.2.2(c)", "framework": "SBP Internet Banking Framework"}, {"code": "2.4.7", "framework": "SBP ETGRMF"}], "description": "Approved policy detailing requirements for remote access, including authentication and encryption.", "framework_count": 4}, {"name": "Remote Access Authorization Records", "frameworks": [{"code": "AC-17", "framework": "NIST SP 800-53 Rev 5"}, {"code": "2.2.2(c)", "framework": "SBP Internet Banking Framework"}, {"code": "2.4.7", "framework": "SBP ETGRMF"}], "description": "Records of approvals for remote access to high-risk IT assets.", "framework_count": 3}, {"name": "Remote Session Monitoring Logs", "frameworks": [{"code": "AC-17", "framework": "NIST SP 800-53 Rev 5"}, {"code": "2.2.2(c)", "framework": "SBP Internet Banking Framework"}, {"code": "2.4.7", "framework": "SBP ETGRMF"}], "description": "Logs capturing details of remote access sessions for monitoring purposes.", "framework_count": 3}, {"name": "MFA Configuration Evidence", "frameworks": [{"code": "7.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "2.2.2(c)", "framework": "SBP Internet Banking Framework"}, {"code": "2.4.7", "framework": "SBP ETGRMF"}], "description": "Configuration evidence demonstrating the implementation of Multi-Factor Authentication for remote access.", "framework_count": 3}, {"name": "Remote Access Encryption Evidence", "frameworks": [{"code": "9.3.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "2.2.2(c)", "framework": "SBP Internet Banking Framework"}, {"code": "2.4.7", "framework": "SBP ETGRMF"}], "description": "Evidence of encryption protocols used for securing remote access sessions.", "framework_count": 3}, {"name": "VPN Configuration Documentation", "frameworks": [{"code": "AC-17", "framework": "NIST SP 800-53 Rev 5"}, {"code": "7.3", "framework": "SABIC CyberTrust Guidelines"}], "description": "Documentation outlining the configuration settings for VPN access.", "framework_count": 2}]	18	pending	\N	\N
4598	NCF0118	Privileged Access Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.714772	Access Control & Identity Management	ai_normalized	\N	[{"name": "Privileged Account Inventory", "frameworks": [{"code": "3.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "APD-06", "framework": "SOX IT General Controls"}, {"code": "A.8.2", "framework": "ISO/IEC 27001:2022"}], "description": "Comprehensive inventory of all privileged accounts including ownership and purpose.", "framework_count": 5}, {"name": "Activity Logs", "frameworks": [{"code": "3.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "APD-06", "framework": "SOX IT General Controls"}, {"code": "9.2.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Logs capturing activities related to privileged accounts.", "framework_count": 5}, {"name": "Privileged Access Management Policy", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "A.8.2", "framework": "ISO/IEC 27001:2022"}, {"code": "9.2.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Policy outlining the management of privileged access, including definitions and procedures.", "framework_count": 3}, {"name": "Privileged Access Review Records", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "APD-06", "framework": "SOX IT General Controls"}, {"code": "A.8.2", "framework": "ISO/IEC 27001:2022"}], "description": "Records of quarterly reviews of privileged accounts with sign-off by system owners.", "framework_count": 3}, {"name": "PAM Solution Documentation", "frameworks": [{"code": "3.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation detailing the Privileged Access Management solution in use.", "framework_count": 2}, {"name": "Privileged Access Request Log", "frameworks": [{"code": "A.8.2", "framework": "ISO/IEC 27001:2022"}], "description": "Log of Just-In-Time (JIT) requests for privileged access with approvers and durations.", "framework_count": 1}, {"name": "Privileged Session Recordings", "frameworks": [{"code": "A.8.2", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of session recordings for privileged sessions.", "framework_count": 1}, {"name": "Break-Glass Account Procedure", "frameworks": [{"code": "A.8.2", "framework": "ISO/IEC 27001:2022"}], "description": "Documented procedure for emergency access with monitoring of usage.", "framework_count": 1}]	18	pending	\N	\N
4602	NCF0122	Identity and Access Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.757614	Access Control & Identity Management	ai_normalized	\N	[{"name": "Identity and Access Management Documentation", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "DS.4", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Comprehensive documentation of IAM policies, procedures, and compliance artifacts as per regulatory requirements.", "framework_count": 2}]	18	pending	\N	\N
4610	NCF0130	Protection from External and Environmental Threats	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.795062	Physical & Environmental Security	ai_normalized	\N	[{"name": "Disaster Protection Documentation", "frameworks": [{"code": "8.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PE 2.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation outlining measures for disaster protection including fire suppression and flood detection.", "framework_count": 2}, {"name": "Environmental Protection Measures", "frameworks": [{"code": "8.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Measures implemented to protect the environment as per security standards.", "framework_count": 1}, {"name": "Fire Protection Systems", "frameworks": [{"code": "8.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Systems in place to protect against fire hazards as per security standards.", "framework_count": 1}, {"name": "Flood Protection Measures", "frameworks": [{"code": "8.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Measures implemented to protect against flooding as per security standards.", "framework_count": 1}, {"name": "Off-site Backup Location Records", "frameworks": [{"code": "PE 2.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating off-site backup activities including dates and approvals.", "framework_count": 1}, {"name": "UPS and Battery Backup Configuration", "frameworks": [{"code": "PE 2.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration details of UPS and battery backup systems showing operational status.", "framework_count": 1}, {"name": "Generator/Backup Power Testing Records", "frameworks": [{"code": "PE 2.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of testing for generator and backup power systems including dates and approvals.", "framework_count": 1}]	18	pending	\N	\N
4614	NCF0134	DC Environmental Monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.812635	Physical & Environmental Security	ai_normalized	\N	[{"name": "Data Center Monitoring System Documentation", "frameworks": [{"code": "8.5.5", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "9.5.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation related to the monitoring systems in place for data centers, including environmental factors.", "framework_count": 2}, {"name": "Data Center Incident Response Plans", "frameworks": [{"code": "8.5.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Plans and procedures for responding to incidents occurring in the data center.", "framework_count": 1}]	18	pending	\N	\N
4620	NCF0140	Privacy Notice	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.837411	Data Protection & Privacy	ai_normalized	\N	[{"name": "Privacy Notice/Policy Documentation", "frameworks": [{"code": "P1.1", "framework": "SOC 2 Type II"}, {"code": "§164.520", "framework": "HIPAA Security & Privacy Rule"}], "description": "Comprehensive documentation of the privacy notice including its publication, updates, and accessibility reviews.", "framework_count": 2}, {"name": "Notice Communication Records", "frameworks": [{"code": "P1.1", "framework": "SOC 2 Type II"}, {"code": "§164.520", "framework": "HIPAA Security & Privacy Rule"}], "description": "Records evidencing the communication of the privacy notice to data subjects and acknowledgment of receipt.", "framework_count": 2}]	18	pending	\N	\N
4626	NCF0146	Continuous performance monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.863615	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Performance Monitoring and Reporting", "frameworks": [{"code": "8.5.2", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "CA-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Includes performance targets, monitoring dashboards, and ongoing assessment reports.", "framework_count": 2}]	18	pending	\N	\N
4628	NCF0148	Real-Time Fraud Monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.872015	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Fraud Monitoring Documentation", "frameworks": [{"code": "14.3.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "10.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation related to the deployment and configuration of fraud monitoring systems and rules.", "framework_count": 2}]	18	pending	\N	\N
4635	NCF0155	Information Asset Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.905079	Asset Management	ai_normalized	\N	[{"name": "Documented Information Asset Management Policy", "frameworks": [{"code": "DS.7", "framework": "KSA National Data Management and Personal Data Protection Standards"}, {"code": "3.3.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "A documented policy outlining the management of information assets, including compliance with NCA regulations and asset classification.", "framework_count": 2}]	18	pending	\N	\N
4641	NCF0161	Third Party Risk Assessment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.935267	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third Party Risk Assessments and Requirements", "frameworks": [{"code": "3.4.2", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "2.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation related to the assessment and requirements for third party service providers and subcontractors.", "framework_count": 2}]	18	pending	\N	\N
4670	NCF0190	Allocation of Information Security Responsibilities	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.408929	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Approved Information Security Policy", "frameworks": [{"code": "05.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing allocation of information security responsibilities, including scope.", "framework_count": 1}, {"name": "Documented Procedures for Information Security", "frameworks": [{"code": "05.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing allocation of information security responsibilities with step-by-step instructions.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "05.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that personnel are informed of security requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "05.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions to demonstrate compliance activities.", "framework_count": 1}, {"name": "Security Roles and Responsibilities Documentation", "frameworks": [{"code": "1.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Matrix of security roles and responsibilities along with job descriptions that include security duties.", "framework_count": 1}, {"name": "Signed Non-Disclosure Agreements", "frameworks": [{"code": "1.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records of signed NDAs to ensure confidentiality and security compliance.", "framework_count": 1}, {"name": "Responsibility Assignment Records", "frameworks": [{"code": "1.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records that document the assignment of responsibilities related to information security.", "framework_count": 1}]	18	pending	\N	\N
4671	NCF0191	Continuous Improvement	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.417931	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Documented Compliance Evidence", "frameworks": [{"code": "DG.7.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Supporting artifacts demonstrating implementation of specification DG.7.2, including performance metrics and review records.", "framework_count": 1}, {"name": "Documented Procedures and Workflows", "frameworks": [{"code": "DG.7.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Step-by-step instructions and workflows implementing continuous processes, including responsible roles and control points.", "framework_count": 1}, {"name": "Organizational Artifacts", "frameworks": [{"code": "DG.7.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Role mandates, RACI, job descriptions, and committee charters identifying owners and responsibilities.", "framework_count": 1}, {"name": "Improvement and Enhancement Records", "frameworks": [{"code": "10.5", "framework": "SABIC CyberTrust Guidelines"}], "description": "Records of improvement tracking, lessons learned, and implementation of enhancements.", "framework_count": 1}]	18	pending	\N	\N
4676	NCF0196	Management Commitment to Information Security	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.443287	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Approved Information Security Policy", "frameworks": [{"code": "05.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "1.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Board/management-approved policy document addressing Management Commitment to Information Security, including scope and applicability.", "framework_count": 2}, {"name": "Documented Procedures for Management Commitment", "frameworks": [{"code": "05.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Management Commitment to Information Security, including step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "05.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that personnel are informed of the information security requirements, including attendee lists, delivery dates, and content references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "05.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer details, dates, observations, and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4649	NCF0169	Baseline Configuration	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.980178	Configuration & Change Management	ai_normalized	\N	[{"name": "Configuration Baselines and Management", "frameworks": [{"code": "PR.IP-1", "framework": "NIST Cybersecurity Framework"}, {"code": "CM-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "OM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation and records related to system baseline configurations, including configuration management practices and hardening standards.", "framework_count": 3}]	18	pending	\N	\N
4654	NCF0174	Change Management Policy and rollback	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.007234	Configuration & Change Management	ai_normalized	\N	[{"name": "Change Management Policy and Records", "frameworks": [{"code": "8.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "7.5.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of change management policies, including change records and rollback plans.", "framework_count": 2}, {"name": "Business Impact Assessment Templates", "frameworks": [{"code": "8.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Templates used for conducting business impact assessments.", "framework_count": 1}, {"name": "Pre-change Backup Records", "frameworks": [{"code": "7.5.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records of backups taken prior to changes.", "framework_count": 1}]	18	pending	\N	\N
4662	NCF0182	Security Incident Response	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.042496	Incident Management	ai_normalized	\N	[{"name": "Incident Response Team Roster", "frameworks": [{"code": "7.7.2", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "CC7.4", "framework": "SOC 2 Type II"}], "description": "A comprehensive list of the incident response team members along with their contact information.", "framework_count": 2}, {"name": "Incident Response Plan", "frameworks": [{"code": "CC7.4", "framework": "SOC 2 Type II"}, {"code": "IM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A documented plan outlining defined roles, escalation procedures, and incident response protocols.", "framework_count": 2}, {"name": "Incident Communication Plan", "frameworks": [{"code": "CC7.4", "framework": "SOC 2 Type II"}, {"code": "IM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A plan detailing the scope, objectives, roles, and communication protocols for incident notifications.", "framework_count": 2}, {"name": "External Incident Response Agreements", "frameworks": [{"code": "7.7.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Agreements with external service providers for incident response support.", "framework_count": 1}, {"name": "Incident Response Tabletop Exercise Records", "frameworks": [{"code": "CC7.4", "framework": "SOC 2 Type II"}], "description": "Documentation of tabletop exercises conducted to test the incident response plan.", "framework_count": 1}, {"name": "Management Approval Records for Incident Plans", "frameworks": [{"code": "IM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating management approval of incident response plans, including dates and approvers.", "framework_count": 1}]	18	pending	\N	\N
4666	NCF0186	Incident Notification (72 Hours)	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.063341	Incident Management	ai_normalized	\N	[{"name": "Incident Notification Procedures", "frameworks": [{"code": "Article 23(4)(b)", "framework": "NIS2 Directive"}, {"code": "8.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation outlining the procedures for notifying relevant parties of incidents, including templates and submission records.", "framework_count": 2}]	18	pending	\N	\N
4672	NCF0192	Risk Analysis	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.423935	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Risk Analysis Documentation", "frameworks": [{"code": "§164.308(a)(1)(ii)(A)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Comprehensive documentation of risk analysis, including reports, updates, and assessments related to ePHI systems.", "framework_count": 1}, {"name": "Asset Inventory of ePHI Systems", "frameworks": [{"code": "§164.308(a)(1)(ii)(A)", "framework": "HIPAA Security & Privacy Rule"}], "description": "A detailed inventory listing all systems that contain electronic Protected Health Information (ePHI).", "framework_count": 1}, {"name": "Information Security Policy", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}], "description": "An approved information security policy that outlines the organization's approach to managing security risks.", "framework_count": 1}, {"name": "Risk Assessment Methodology", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}], "description": "Documentation outlining the methodology used for conducting risk assessments.", "framework_count": 1}, {"name": "Risk Treatment Plan", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}], "description": "A plan detailing prioritized actions for treating identified risks.", "framework_count": 1}, {"name": "Annual Risk Assessment Review Records", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}], "description": "Records of reviews conducted annually to assess and update risk assessments.", "framework_count": 1}]	18	pending	\N	\N
4674	NCF0194	Communication with Special Interest Groups	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.433844	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Membership and Participation Records", "frameworks": [{"code": "1.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.6", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of memberships in security groups, forums, and industry collaborations.", "framework_count": 2}, {"name": "Threat Intelligence Sharing Agreements", "frameworks": [{"code": "1.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.6", "framework": "ISO/IEC 27001:2022"}], "description": "Formal agreements for sharing threat intelligence with partners.", "framework_count": 2}, {"name": "Threat Advisory Distribution Log", "frameworks": [{"code": "A.5.6", "framework": "ISO/IEC 27001:2022"}], "description": "Records of dissemination of threat advisories received from special interest groups.", "framework_count": 1}, {"name": "Conference and Forum Attendance Records", "frameworks": [{"code": "A.5.6", "framework": "ISO/IEC 27001:2022"}], "description": "Certificates or logs documenting attendance at security conferences and forums.", "framework_count": 1}]	18	pending	\N	\N
4675	NCF0195	Include vendor and asset selection criteria in procurement policy	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.44018	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Comprehensive Procurement Policy", "frameworks": [{"code": "4.2.2.b", "framework": "SBP ETGRMF"}, {"code": "4.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "A procurement policy covering asset types, vendor types, selection criteria, acquisition process, payment/monitoring, delivery assurance, and technical vetting.", "framework_count": 2}, {"name": "Vendor Selection Criteria Matrix", "frameworks": [{"code": "4.2.2.b", "framework": "SBP ETGRMF"}, {"code": "4.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Matrix of vendor selection criteria with scoring methodology.", "framework_count": 2}, {"name": "Vendor Approval Register", "frameworks": [{"code": "4.2.2.b", "framework": "SBP ETGRMF"}], "description": "Register of approved vendors categorized by asset type.", "framework_count": 1}, {"name": "Delivery Verification Checklist", "frameworks": [{"code": "4.2.2.b", "framework": "SBP ETGRMF"}], "description": "Checklist for delivery assurance and verification.", "framework_count": 1}]	18	pending	\N	\N
4537	NCF0057	Disaster Recovery	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.394468	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Documented Disaster Recovery Plan", "frameworks": [{"code": "DO.4.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}, {"code": "9.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "2.2.3(d)", "framework": "SBP Internet Banking Framework"}], "description": "A comprehensive documented disaster recovery plan demonstrating compliance with specified standards, including details on implementation and ownership.", "framework_count": 3}, {"name": "Data Management and Personal Data Protection Strategy/Plan", "frameworks": [{"code": "DO.4.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "An approved strategy or plan outlining data management and personal data protection objectives, roadmap, and budget.", "framework_count": 1}, {"name": "Organizational Artifacts", "frameworks": [{"code": "DO.4.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documentation including role mandates, RACI charts, job descriptions, and committee charters that define ownership and responsibilities.", "framework_count": 1}, {"name": "Disaster Recovery Test Results", "frameworks": [{"code": "9.2", "framework": "SABIC CyberTrust Guidelines"}], "description": "Results from tests conducted on the disaster recovery plan to validate its effectiveness and readiness.", "framework_count": 1}, {"name": "RTO/RPO Definitions", "frameworks": [{"code": "9.2", "framework": "SABIC CyberTrust Guidelines"}], "description": "Definitions of Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO) relevant to disaster recovery planning.", "framework_count": 1}, {"name": "SP Disaster Recovery Site Inventory", "frameworks": [{"code": "2.2.3(d)", "framework": "SBP Internet Banking Framework"}], "description": "An inventory detailing service provider disaster recovery sites, including type, capacity, location, and activation procedures.", "framework_count": 1}, {"name": "SP IT Assets Lifecycle Documentation", "frameworks": [{"code": "2.2.3(d)", "framework": "SBP Internet Banking Framework"}], "description": "Documentation provided by the service provider covering the lifecycle of IT assets from acquisition to disposal.", "framework_count": 1}, {"name": "DR Plan Alignment Memo", "frameworks": [{"code": "2.2.3(d)", "framework": "SBP Internet Banking Framework"}], "description": "A memo or matrix demonstrating the alignment of the service provider's disaster recovery plan with the bank's business requirements.", "framework_count": 1}]	18	pending	\N	\N
4538	NCF0058	ICT Readiness for Business Continuity	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.398477	Business Continuity & Resilience	ai_normalized	\N	[{"name": "ICT Continuity Plan and Testing", "frameworks": [{"code": "A.5.30", "framework": "ISO/IEC 27001:2022"}, {"code": "Article 11(3)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Comprehensive documentation of ICT continuity plans, including testing results and review records.", "framework_count": 2}]	18	pending	\N	\N
4540	NCF0060	Alternate Processing Site	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.406679	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Alternate Processing Site Documentation", "frameworks": [{"code": "CP-7", "framework": "NIST SP 800-53 Rev 5"}, {"code": "8.2.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation related to agreements, assessments, and readiness for alternate processing sites.", "framework_count": 2}, {"name": "Failover Test Results", "frameworks": [{"code": "CP-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Results from tests conducted to ensure failover capabilities are effective.", "framework_count": 1}, {"name": "Recovery Time Documentation", "frameworks": [{"code": "CP-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation detailing the expected recovery times for systems and processes.", "framework_count": 1}]	18	pending	\N	\N
4677	NCF0197	Information Security Coordination	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.447281	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Information Security Coordination Policy", "frameworks": [{"code": "05.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Information Security Coordination, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Information Security Coordination Procedures", "frameworks": [{"code": "05.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Information Security Coordination with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "05.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that personnel are informed of the requirements, including attendee lists, delivery dates, and content references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "05.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer details, date, observations, and corrective actions.", "framework_count": 1}, {"name": "Security Committee Documentation", "frameworks": [{"code": "1.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Includes security committee charter, member qualifications, meeting minutes, and coordination procedures.", "framework_count": 1}]	18	pending	\N	\N
4680	NCF0200	Incident Response Training	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.462384	Awareness & Training	ai_normalized	\N	[{"name": "Incident Response Training Materials", "frameworks": [{"code": "IR-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "12.10.4", "framework": "PCI Data Security Standard"}], "description": "Comprehensive training materials and curriculum for incident response personnel, including completion records.", "framework_count": 2}, {"name": "Incident Response Exercise Documentation", "frameworks": [{"code": "IR-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "12.10.4", "framework": "PCI Data Security Standard"}], "description": "Documentation of tabletop exercises and drills/simulations related to incident response training.", "framework_count": 2}]	18	pending	\N	\N
4681	NCF0201	Customer Awareness	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.468439	Awareness & Training	ai_normalized	\N	[{"name": "Multi-channel Customer Awareness Campaigns", "frameworks": [{"code": "10.9.3", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "10.13.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Evidence of multi-channel campaigns for customer awareness.", "framework_count": 2}, {"name": "Customer Awareness Program", "frameworks": [{"code": "3", "framework": "SBP Internet Banking Framework"}], "description": "Documented and approved program covering IB threats and safeguards to minimize fraud and identity theft, including implementation evidence.", "framework_count": 1}, {"name": "Awareness Channel Inventory", "frameworks": [{"code": "3", "framework": "SBP Internet Banking Framework"}], "description": "Inventory of channels used for customer awareness.", "framework_count": 1}, {"name": "Awareness Content Library", "frameworks": [{"code": "3", "framework": "SBP Internet Banking Framework"}], "description": "Library of customer-facing content covering various threats and safeguards.", "framework_count": 1}, {"name": "Management Review Documentation", "frameworks": [{"code": "3(g)", "framework": "SBP Internet Banking Framework"}], "description": "Minutes of management review meetings and effectiveness reports evaluating the Customer Awareness Program.", "framework_count": 1}, {"name": "Customer Notifications Archive", "frameworks": [{"code": "8.2.13", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Archive of customer notifications and press releases related to awareness.", "framework_count": 1}, {"name": "Customer Cyber Awareness Publications", "frameworks": [{"code": "10.9.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Publications aimed at educating customers about cyber threats.", "framework_count": 1}, {"name": "Phishing Report Handling SOP", "frameworks": [{"code": "10.9.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Standard Operating Procedure for handling phishing reports.", "framework_count": 1}]	18	pending	\N	\N
4682	NCF0202	Security Screening	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.473489	Human Resources Security	ai_normalized	\N	[{"name": "Background Check Policy and Documentation", "frameworks": [{"code": "5.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PS-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documents outlining the background check policy, screening procedures, and related records.", "framework_count": 2}]	18	pending	\N	\N
4683	NCF0203	Protection from Malicious Software	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.477439	Network Security	ai_normalized	\N	[{"name": "Malware Incident Reporting and Records", "frameworks": [{"code": "§164.308(a)(5)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "SI-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Procedures and records related to malware incidents, including reporting procedures and incident records.", "framework_count": 2}, {"name": "Anti-malware Training and Documentation", "frameworks": [{"code": "§164.308(a)(5)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Materials and records related to anti-malware training and awareness, including training materials and training records.", "framework_count": 1}, {"name": "Malware Management Documentation", "frameworks": [{"code": "SI-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation related to the management of malware, including solution documentation, definition updates, and scan reports.", "framework_count": 1}]	18	pending	\N	\N
4685	NCF0205	Wireless Access	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.484957	Network Security	ai_normalized	\N	[{"name": "Wireless Access Policy", "frameworks": [{"code": "AC-18", "framework": "NIST SP 800-53 Rev 5"}, {"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A board/management-approved policy detailing the scope, applicability, roles, responsibilities, and control objectives for wireless access.", "framework_count": 2}, {"name": "Wireless Network Configuration Standards", "frameworks": [{"code": "AC-18", "framework": "NIST SP 800-53 Rev 5"}], "description": "Standards outlining the configuration requirements for wireless networks.", "framework_count": 1}, {"name": "Wireless Access Point Inventory", "frameworks": [{"code": "AC-18", "framework": "NIST SP 800-53 Rev 5"}], "description": "An inventory listing all wireless access points in the organization.", "framework_count": 1}, {"name": "Wireless Security Assessment Results", "frameworks": [{"code": "AC-18", "framework": "NIST SP 800-53 Rev 5"}], "description": "Results from assessments evaluating the security of wireless networks.", "framework_count": 1}, {"name": "Wireless Authorization Records", "frameworks": [{"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating authorization activities for wireless access, including dates and approvers.", "framework_count": 1}, {"name": "Guest Network Segregation Configuration", "frameworks": [{"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration evidence showing the segregation of guest networks, including system identifiers and dates.", "framework_count": 1}, {"name": "Wireless SSID Broadcasting Settings", "frameworks": [{"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of the settings for wireless SSID broadcasting, including dates and references to related policies.", "framework_count": 1}, {"name": "WPA2/WPA3 Encryption Configuration", "frameworks": [{"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration evidence demonstrating the implementation of WPA2/WPA3 encryption, including system identifiers and dates.", "framework_count": 1}, {"name": "Wireless Administrative Restriction Evidence", "frameworks": [{"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of administrative restrictions on wireless access, including dates and references.", "framework_count": 1}, {"name": "Medical Device Wireless Restrictions", "frameworks": [{"code": "AC 5.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence showing restrictions on wireless access for medical devices, including dates and references to related policies.", "framework_count": 1}]	18	pending	\N	\N
4693	NCF0213	Policy on the Use of Network Services	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.524674	Access Control & Identity Management	ai_normalized	\N	[{"name": "User Access Provisioning Records", "frameworks": [{"code": "01.i", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of user access provisioning, modification, and review demonstrating activity occurrence.", "framework_count": 2}, {"name": "Approved Policy on the Use of Network Services", "frameworks": [{"code": "01.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved Policy document with management sign-off, scope, and version history.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Access control matrix with role-to-permission mapping for relevant systems.", "framework_count": 1}, {"name": "Network Architecture Diagram", "frameworks": [{"code": "01.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Current network architecture diagram showing segmentation, firewalls, and trust zones.", "framework_count": 1}, {"name": "Network Device Configuration Records", "frameworks": [{"code": "01.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of network device configuration baselines and ruleset reviews demonstrating activity occurrence.", "framework_count": 1}, {"name": "Network Service Inventory", "frameworks": [{"code": "AC 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of network services containing entity/item name, owner, classification, and review details.", "framework_count": 1}, {"name": "Authorization-Based Access Configuration", "frameworks": [{"code": "AC 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Live configuration extract showing authorization-based access control is in effect.", "framework_count": 1}]	18	pending	\N	\N
4686	NCF0206	Networks Security	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.489047	Network Security	ai_normalized	\N	[{"name": "Network Security Policy and Architecture", "frameworks": [{"code": "A.8.20", "framework": "ISO/IEC 27001:2022"}], "description": "Policy covering network security architecture, controls, operations, and current network architecture diagram including security zones and controls.", "framework_count": 1}, {"name": "Firewall Rules Documentation", "frameworks": [{"code": "A.8.20", "framework": "ISO/IEC 27001:2022"}], "description": "Export of firewall rules and periodic review records with justification and cleanup actions.", "framework_count": 1}, {"name": "Network Device Hardening Standards", "frameworks": [{"code": "A.8.20", "framework": "ISO/IEC 27001:2022"}], "description": "Hardening standards applied to routers, switches, firewalls, and wireless access points.", "framework_count": 1}, {"name": "Intrusion Detection and Prevention System Evidence", "frameworks": [{"code": "A.8.20", "framework": "ISO/IEC 27001:2022"}], "description": "IDS/IPS rule configuration and sample alerts investigated.", "framework_count": 1}, {"name": "Wireless Network Security Configuration", "frameworks": [{"code": "A.8.20", "framework": "ISO/IEC 27001:2022"}], "description": "WPA3/Enterprise configuration, rogue AP detection, and guest network isolation.", "framework_count": 1}, {"name": "Wireless Site Survey Reports", "frameworks": [{"code": "CM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports including scope, methodology, findings, evidence references, risk ratings, recommendations, and management responses.", "framework_count": 1}, {"name": "WPA2/WPA3 Enterprise Authentication Configuration", "frameworks": [{"code": "CM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Extract, screenshot, or export of the live configuration showing WPA2/WPA3 enterprise authentication control in effect.", "framework_count": 1}, {"name": "Trusted Device Wireless Access Evidence", "frameworks": [{"code": "CM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of trusted device wireless access control, with date, owner, and policy reference.", "framework_count": 1}, {"name": "Guest Network Isolation Architecture", "frameworks": [{"code": "CM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Current, version-controlled architecture showing components, interconnections, trust zones, and data flows; dated and approved.", "framework_count": 1}, {"name": "Guest Wireless Access Monitoring Logs", "frameworks": [{"code": "CM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs preserved for the required retention period, protected from tampering, with timestamp, actor identity, and action performed.", "framework_count": 1}]	18	pending	\N	\N
4687	NCF0207	Periodic User Access Reviews	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.491954	Access Control & Identity Management	ai_normalized	\N	[{"name": "Access Review Documentation", "frameworks": [{"code": "APD-05", "framework": "SOX IT General Controls"}], "description": "Completed access review listings with sign-off and reviewer acknowledgment of responsibility.", "framework_count": 1}, {"name": "Access Review Schedule", "frameworks": [{"code": "APD-05", "framework": "SOX IT General Controls"}], "description": "Documentation outlining the schedule for access reviews.", "framework_count": 1}, {"name": "Access Review Reports", "frameworks": [{"code": "8.4.8", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Semi-annual reports detailing the results of access reviews.", "framework_count": 1}, {"name": "Exception Remediation Evidence", "frameworks": [{"code": "APD-05", "framework": "SOX IT General Controls"}], "description": "Evidence of remediation actions taken for exceptions identified during access reviews.", "framework_count": 1}, {"name": "Account Disablement Evidence", "frameworks": [{"code": "8.4.8", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation showing evidence of account disablement or removal.", "framework_count": 1}]	18	pending	\N	\N
4688	NCF0208	Review of User Access Rights	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.496043	Access Control & Identity Management	ai_normalized	\N	[{"name": "User Access Review Procedure", "frameworks": [{"code": "01.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented procedure implementing the review of user access rights with step-by-step instructions and responsible roles.", "framework_count": 2}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Matrix mapping roles to permissions for relevant systems, identifying owners and responsibilities.", "framework_count": 2}, {"name": "User Access Review Records", "frameworks": [{"code": "01.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating user access provisioning, modification, and review activities, including dates and approvers.", "framework_count": 2}, {"name": "Approved User Access Review Policy", "frameworks": [{"code": "01.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy addressing the review of user access rights, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Annual Access Review Reports", "frameworks": [{"code": "AC 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports detailing the scope, methodology, findings, and recommendations from annual access reviews.", "framework_count": 1}, {"name": "Inactivity-Based Revocation Configuration", "frameworks": [{"code": "AC 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration evidence showing inactivity-based revocation controls in effect, including system identification.", "framework_count": 1}]	18	pending	\N	\N
4690	NCF0210	Production Data Access Control	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.507772	Access Control & Identity Management	ai_normalized	\N	[{"name": "Documented Production Data Access Control", "frameworks": [{"code": "DO.4.3", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Supporting artifact demonstrating compliance with production data access control specifications, including procedures and security controls.", "framework_count": 1}]	18	pending	\N	\N
4691	NCF0211	Access Authorization	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.512743	Access Control & Identity Management	ai_normalized	\N	[{"name": "Access Authorization Policy and Procedures", "frameworks": [{"code": "§164.308(a)(4)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "11.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documented policies and procedures for granting access to sensitive information.", "framework_count": 2}, {"name": "Access Request and Approval Documentation", "frameworks": [{"code": "§164.308(a)(4)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "11.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Forms and records related to access requests and their approvals.", "framework_count": 2}, {"name": "Minimum Necessary Determination Records", "frameworks": [{"code": "§164.308(a)(4)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "11.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records that demonstrate the minimum necessary access determinations for information access.", "framework_count": 2}]	18	pending	\N	\N
4692	NCF0212	Controlled and Monitored Service Provider Access to Customer Information	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.518581	Access Control & Identity Management	ai_normalized	\N	[{"name": "Service Provider Access Control Procedures", "frameworks": [{"code": "2.2.3(c)", "framework": "SBP Internet Banking Framework"}, {"code": "9.1.8", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documented procedures and records governing request-based access for service providers to customer information.", "framework_count": 2}, {"name": "Service Provider Access Monitoring", "frameworks": [{"code": "2.2.3(c)", "framework": "SBP Internet Banking Framework"}, {"code": "9.1.8", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Configuration and records of monitoring controls applied to service provider access to customer information.", "framework_count": 2}, {"name": "Service Provider Access Logs", "frameworks": [{"code": "2.2.3(c)", "framework": "SBP Internet Banking Framework"}], "description": "Sample logs detailing service provider access activities, including user actions and timestamps.", "framework_count": 1}, {"name": "Periodic Service Provider Access Audits", "frameworks": [{"code": "2.2.3(c)", "framework": "SBP Internet Banking Framework"}], "description": "Audit reports on service provider access to customer information, including anomaly investigations.", "framework_count": 1}, {"name": "Unauthorized Storage Prevention Controls", "frameworks": [{"code": "2.2.3(c)", "framework": "SBP Internet Banking Framework"}], "description": "Controls in place to prevent the transfer of customer information to unauthorized storage or media.", "framework_count": 1}]	18	pending	\N	\N
4694	NCF0214	Remote Diagnostic and Configuration Protection	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.530585	Access Control & Identity Management	ai_normalized	\N	[{"name": "Diagnostic/Configuration Port Whitelist", "frameworks": [{"code": "AC 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "01.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Extract, screenshot, or export of the live configuration showing the control is in effect, with date and system identifier.", "framework_count": 2}, {"name": "Disabled Services/Utilities Documentation", "frameworks": [{"code": "AC 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of the control, with date, owner, and reference to the related policy.", "framework_count": 1}, {"name": "Authorized Workstation List for Remote Diagnostics", "frameworks": [{"code": "AC 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of the control, with date, owner, and reference to the related policy.", "framework_count": 1}, {"name": "Remote Diagnostic Access Logs", "frameworks": [{"code": "AC 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Preserved logs for the required retention period, protected from tampering, with timestamp, actor identity, and action performed.", "framework_count": 1}, {"name": "Documented Procedure for Remote Diagnostic and Configuration", "frameworks": [{"code": "01.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step instructions and responsibilities for implementing Remote Diagnostic and Configuration Port Protection.", "framework_count": 1}, {"name": "Network Architecture Diagram", "frameworks": [{"code": "01.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Current, version-controlled diagram showing segmentation, firewalls, and trust zones.", "framework_count": 1}, {"name": "Network Device Configuration Baselines and Ruleset Review Records", "frameworks": [{"code": "01.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that configuration review activity occurred, including date, performer, and approver.", "framework_count": 1}, {"name": "Physical Access Logs and Visitor Register", "frameworks": [{"code": "01.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Logs preserved for the required retention period, protected from tampering, with timestamp and actor identity.", "framework_count": 1}, {"name": "CCTV Deployment Evidence and Footage Retention Records", "frameworks": [{"code": "01.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating CCTV deployment and retention of footage, including date and performer.", "framework_count": 1}]	18	pending	\N	\N
4696	NCF0216	IT Segregation of Duties Framework	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.540043	Access Control & Identity Management	ai_normalized	\N	[{"name": "Segregation of Duties Documentation", "frameworks": [{"code": "SOD-01", "framework": "SOX IT General Controls"}], "description": "Documentation including SoD conflict matrix, policy, and exception controls.", "framework_count": 1}, {"name": "Technical Enforcement Evidence", "frameworks": [{"code": "SOD-01", "framework": "SOX IT General Controls"}], "description": "Evidence of technical configurations enforcing segregation of duties.", "framework_count": 1}, {"name": "Software Release Process", "frameworks": [{"code": "7.6.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of the software release process ensuring segregation of duties.", "framework_count": 1}, {"name": "Release Authorization Records", "frameworks": [{"code": "7.6.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records that authorize software releases as part of the segregation of duties process.", "framework_count": 1}]	18	pending	\N	\N
4697	NCF0217	Termination Procedures	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.544132	Access Control & Identity Management	ai_normalized	\N	[{"name": "Termination Procedures and Documentation", "frameworks": [{"code": "§164.308(a)(3)(ii)(C)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "PS-4", "framework": "NIST SP 800-53 Rev 5"}, {"code": "HR 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive documentation of termination procedures, including checklists, access revocation, and equipment return.", "framework_count": 3}, {"name": "Exit Interview Documentation", "frameworks": [{"code": "PS-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of exit interviews conducted with departing employees.", "framework_count": 1}, {"name": "Communication Protocol for Employment Exit", "frameworks": [{"code": "HR 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of the communication protocol followed during employee exits.", "framework_count": 1}, {"name": "Knowledge Transfer Checklists and Records", "frameworks": [{"code": "HR 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating knowledge transfer activities during employee exits.", "framework_count": 1}, {"name": "Handover Documentation Templates", "frameworks": [{"code": "HR 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Templates used for documenting handover processes during employee exits.", "framework_count": 1}]	18	pending	\N	\N
4699	NCF0219	User Password Management	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.555793	Access Control & Identity Management	ai_normalized	\N	[{"name": "Approved Password Management Policy", "frameworks": [{"code": "01.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "9.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Board/management-approved policy and standard addressing User Password Management, including scope, applicability, and roles.", "framework_count": 2}, {"name": "Password Configuration Export", "frameworks": [{"code": "01.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "9.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Export demonstrating password complexity, lifetime, history, and lockout settings from the live configuration.", "framework_count": 2}, {"name": "User Password Management Procedure", "frameworks": [{"code": "01.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing User Password Management with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of password management requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "01.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions.", "framework_count": 1}, {"name": "Password Change Logs", "frameworks": [{"code": "9.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Logs documenting changes made to passwords, including timestamps and user details.", "framework_count": 1}]	18	pending	\N	\N
4700	NCF0220	Session Authenticity	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.561431	Access Control & Identity Management	ai_normalized	\N	[{"name": "Session Management Configuration", "frameworks": [{"code": "SC-23", "framework": "NIST SP 800-53 Rev 5"}, {"code": "14.2.9", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation detailing session management configuration settings and practices.", "framework_count": 2}, {"name": "Anti-CSRF Token Implementation", "frameworks": [{"code": "SC-23", "framework": "NIST SP 800-53 Rev 5"}], "description": "Implementation details for anti-CSRF tokens to protect against cross-site request forgery.", "framework_count": 1}, {"name": "Secure Cookie Configuration", "frameworks": [{"code": "SC-23", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation on the configuration of secure cookies to enhance session security.", "framework_count": 1}, {"name": "Session Timeout and Hijack Detection Settings", "frameworks": [{"code": "14.2.9", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Settings related to session timeout and mechanisms for detecting session hijacking.", "framework_count": 1}]	18	pending	\N	\N
4722	NCF0242	Event Data Correlation	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.679253	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "SIEM Configuration and Event Correlation", "frameworks": [{"code": "DE.AE-3", "framework": "NIST Cybersecurity Framework"}, {"code": "12.2.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of SIEM configuration, log aggregation, and event correlation rules.", "framework_count": 2}]	18	pending	\N	\N
4650	NCF0170	Secure Configuration	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.98347	Configuration & Change Management	ai_normalized	\N	[{"name": "Configuration Baselines and Hardening Standards", "frameworks": [{"code": "7.8", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "Article 21(2)(e)", "framework": "NIS2 Directive"}], "description": "Documentation of security baseline and hardening standards for system configurations.", "framework_count": 2}]	18	pending	\N	\N
4701	NCF0221	Identity Management	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.567241	Access Control & Identity Management	ai_normalized	\N	[{"name": "Identity Lifecycle Management Procedures", "frameworks": [{"code": "A.5.16", "framework": "ISO/IEC 27001:2022"}, {"code": "PR.AC-1", "framework": "NIST Cybersecurity Framework"}], "description": "Comprehensive procedures for managing identities throughout their lifecycle, including joiner-mover-leaver processes.", "framework_count": 2}, {"name": "User Provisioning and Deprovisioning Evidence", "frameworks": [{"code": "A.5.16", "framework": "ISO/IEC 27001:2022"}, {"code": "PR.AC-1", "framework": "NIST Cybersecurity Framework"}], "description": "Documentation and logs evidencing the provisioning and deprovisioning of user accounts, including approval and closure.", "framework_count": 2}, {"name": "Identity and Access Management System Configuration", "frameworks": [{"code": "A.5.16", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration settings and policies from the IAM system that govern identity management.", "framework_count": 1}, {"name": "Shared Account Management", "frameworks": [{"code": "A.5.16", "framework": "ISO/IEC 27001:2022"}], "description": "Register of shared or service accounts, including justification and ownership details.", "framework_count": 1}, {"name": "Dormant Account Management", "frameworks": [{"code": "A.5.16", "framework": "ISO/IEC 27001:2022"}], "description": "Reports identifying inactive accounts and the actions taken for remediation.", "framework_count": 1}]	18	pending	\N	\N
4702	NCF0222	Access Restrictions for Change	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.572426	Access Control & Identity Management	ai_normalized	\N	[{"name": "Access Control Procedures and Lists", "frameworks": [{"code": "CM-5", "framework": "NIST SP 800-53 Rev 5"}, {"code": "C1.3", "framework": "SOC 2 Type II"}], "description": "Documentation of access control procedures and authorized personnel for managing access to confidential data repositories.", "framework_count": 2}, {"name": "Access Audit Logs", "frameworks": [{"code": "CM-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Logs that record changes to access controls and access attempts to confidential data.", "framework_count": 1}, {"name": "Periodic Access Review Results", "frameworks": [{"code": "C1.3", "framework": "SOC 2 Type II"}], "description": "Results from periodic reviews of access to confidential information to ensure compliance and appropriateness.", "framework_count": 1}, {"name": "Role-Based Access Configurations", "frameworks": [{"code": "C1.3", "framework": "SOC 2 Type II"}], "description": "Configurations that define access rights based on user roles for confidential systems.", "framework_count": 1}, {"name": "Access Request and Approval Records", "frameworks": [{"code": "C1.3", "framework": "SOC 2 Type II"}], "description": "Records of requests for access to confidential information and their corresponding approvals.", "framework_count": 1}]	18	pending	\N	\N
4704	NCF0224	Security of Equipment Off Site	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.585123	Physical & Environmental Security	ai_normalized	\N	[{"name": "Off-site Equipment Procedures", "frameworks": [{"code": "PE 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "08.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures including step-by-step instructions, responsible roles, control points, and exception handling for off-site equipment.", "framework_count": 2}, {"name": "Chain of Custody Logs for Off-site Equipment", "frameworks": [{"code": "PE 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs preserved for the required retention period, protected from tampering, with timestamp, actor identity, and actions recorded.", "framework_count": 1}, {"name": "Off-site Protection Measures Documentation", "frameworks": [{"code": "PE 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of off-site protection measures, including date, owner, and reference to related policies.", "framework_count": 1}, {"name": "Verification Records for Off-site Assets", "frameworks": [{"code": "PE 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating that verification activities occurred, including date, performer, approver where applicable, and references.", "framework_count": 1}, {"name": "Approved Policy for Security of Equipment Off-Premises", "frameworks": [{"code": "08.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy addressing the security of equipment off-premises, including scope and applicability.", "framework_count": 1}, {"name": "Physical Access Logs and Visitor Register", "frameworks": [{"code": "08.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Logs preserved for the required retention period, protected from tampering, with timestamp and actor identity.", "framework_count": 1}, {"name": "CCTV Deployment Evidence and Footage Retention Records", "frameworks": [{"code": "08.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating CCTV deployment and retention of footage, including date, performer, and approver where applicable.", "framework_count": 1}, {"name": "Awareness Communications for Personnel", "frameworks": [{"code": "08.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of security requirements, including attendee list and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4705	NCF0225	Unattended User Equipment	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.591013	Physical & Environmental Security	ai_normalized	\N	[{"name": "User Responsibilities Documentation for Unattended Equipment", "frameworks": [{"code": "PE 3.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "01.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Supporting artifact demonstrating implementation of user responsibilities for unattended equipment, including date, owner, and reference.", "framework_count": 2}, {"name": "Auto-lock/Screen-saver Configuration Evidence", "frameworks": [{"code": "PE 3.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Extract, screenshot, or export of the live configuration showing the auto-lock/screen-saver control is in effect, with date and system ID.", "framework_count": 1}, {"name": "Workstation Locking Enforcement Records", "frameworks": [{"code": "PE 3.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating that workstation locking enforcement activity occurred, including date, performer, approver where applicable, and reference.", "framework_count": 1}, {"name": "Documented Procedure for Unattended User Equipment", "frameworks": [{"code": "01.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step instructions and responsible roles for implementing unattended user equipment controls.", "framework_count": 1}, {"name": "Physical Access Logs and Visitor Register", "frameworks": [{"code": "01.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Preserved logs and registers for physical access, protected from tampering, with timestamp and actor identification.", "framework_count": 1}, {"name": "CCTV Deployment Evidence and Footage Retention Records", "frameworks": [{"code": "01.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating CCTV deployment and retention of footage, including date, performer, and approver where applicable.", "framework_count": 1}, {"name": "Awareness Communications for Personnel", "frameworks": [{"code": "01.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of requirements, including attendee list, delivery dates, and content references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "01.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including date, observations, and corrective actions taken, demonstrating that the review activity occurred.", "framework_count": 1}]	18	pending	\N	\N
4706	NCF0226	Secure Work Areas	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.597838	Physical & Environmental Security	ai_normalized	\N	[{"name": "Work Area Security Procedures", "frameworks": [{"code": "6.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation outlining procedures for maintaining security in work areas, including clean desk policies and privacy screen deployment.", "framework_count": 1}, {"name": "Authorized Personnel List", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive list of authorized personnel for secure areas, including details such as entity/item name, owner, classification, and review date.", "framework_count": 1}, {"name": "Access Authentication Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of access authentication, including badge logs and biometric logs, preserved for the required retention period.", "framework_count": 1}, {"name": "Secure Area Access Logs", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs documenting access to secure areas, including timestamps, actor identity, actions performed, and outcomes.", "framework_count": 1}, {"name": "ID Badge Issuance Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the issuance of ID badges, including dates, performers, and approvers.", "framework_count": 1}, {"name": "Door Alarm and Locking Configuration", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration details of door alarms and locking mechanisms, including extracts or screenshots showing the control is in effect.", "framework_count": 1}, {"name": "Contractor Escort Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the escorting of contractors, including dates, performers, and approvers.", "framework_count": 1}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of CCTV controls, including dates and ownership.", "framework_count": 1}, {"name": "CCTV Retention Policy and Footage Storage Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the retention policy for CCTV footage and its storage, including dates and approvers.", "framework_count": 1}]	18	pending	\N	\N
4775	NCS22-0001	Continual Improvement	\N	\N	\N	\N	\N	0	2026-06-21 08:57:50.963646	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Continual Improvement Documentation", "frameworks": [{"code": "10.1", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "10.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Comprehensive documentation of continual improvement initiatives, including registers, reports, and action trackers.", "framework_count": 2}]	22	pending	\N	\N
4707	NCF0227	Utilities	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.600603	Physical & Environmental Security	ai_normalized	\N	[{"name": "Power Protection and Maintenance Records", "frameworks": [{"code": "8.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.11", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of UPS specifications, maintenance, and power protection testing.", "framework_count": 2}, {"name": "Generator Maintenance and Testing Records", "frameworks": [{"code": "8.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.11", "framework": "ISO/IEC 27001:2022"}], "description": "Records of generator maintenance, test runs, and fuel management.", "framework_count": 2}, {"name": "Utility Redundancy and Support Documentation", "frameworks": [{"code": "8.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.11", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of utility redundancy, service level agreements, and risk assessments.", "framework_count": 2}, {"name": "HVAC and Environmental Controls Records", "frameworks": [{"code": "A.7.11", "framework": "ISO/IEC 27001:2022"}], "description": "Records of HVAC maintenance and environmental monitoring.", "framework_count": 1}]	18	pending	\N	\N
4709	NCF0229	Backup System Separation	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.600603	Data Protection & Privacy	ai_normalized	\N	[{"name": "Backup Documentation", "frameworks": [{"code": "Article 12(2)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation related to network segregation, integrity verification, and access control for backup systems.", "framework_count": 1}, {"name": "Physical Separation Evidence", "frameworks": [{"code": "Article 12(2)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Evidence of physical separation for backup systems.", "framework_count": 1}, {"name": "Backup Encryption Verification", "frameworks": [{"code": "8.4.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records verifying the encryption of backups.", "framework_count": 1}, {"name": "Offsite Backup Storage Documentation", "frameworks": [{"code": "8.4.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation regarding the storage of backups at offsite locations.", "framework_count": 1}]	18	pending	\N	\N
4710	NCF0230	Retention and Disposal	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.615527	Data Protection & Privacy	ai_normalized	\N	[{"name": "Retention and Disposal Policy", "frameworks": [{"code": "P4.1", "framework": "SOC 2 Type II"}, {"code": "13.l", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "DCM.4.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Approved policy and standard addressing retention and disposal of personal information, including scope, applicability, and roles.", "framework_count": 3}, {"name": "Retention and Disposal Procedures", "frameworks": [{"code": "P4.1", "framework": "SOC 2 Type II"}, {"code": "13.l", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "DCM.4.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented procedures and work instructions implementing retention and disposal, including step-by-step instructions and responsible roles.", "framework_count": 3}, {"name": "Data Lifecycle Records", "frameworks": [{"code": "P4.1", "framework": "SOC 2 Type II"}, {"code": "DCM.4.2", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records covering retention schedules, archival, and secure disposal demonstrating compliance with data lifecycle management.", "framework_count": 2}, {"name": "Data Use Monitoring and Audit Reports", "frameworks": [{"code": "P4.1", "framework": "SOC 2 Type II"}], "description": "Reports documenting the monitoring and auditing of data use to ensure compliance with retention and disposal policies.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "13.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of retention and disposal requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "13.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of retention and disposal practices, including observations and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4711	NCF0231	Information Leakage	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.624343	Data Protection & Privacy	ai_normalized	\N	[{"name": "DLP Policy and Configuration", "frameworks": [{"code": "13.10", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "OM 6.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation and configuration evidence demonstrating the implementation of the Data Loss Prevention policy.", "framework_count": 2}, {"name": "DLP Incident Records", "frameworks": [{"code": "13.10", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "OM 6.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of incidents related to data leakage, including alerts and actions taken.", "framework_count": 2}, {"name": "Information Leakage Prevention Reports", "frameworks": [{"code": "OM 6.6", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive reports detailing the findings and recommendations related to information leakage prevention.", "framework_count": 1}, {"name": "DLP Monitoring Configuration", "frameworks": [{"code": "13.10", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Configuration evidence showing the monitoring setup for Data Loss Prevention controls.", "framework_count": 1}, {"name": "DLP Leakage Prevention Controls", "frameworks": [{"code": "13.10", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Evidence of implemented controls specifically aimed at preventing data leakage.", "framework_count": 1}]	18	pending	\N	\N
4712	NCF0232	Enforce Data Retention	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.624343	Data Protection & Privacy	ai_normalized	\N	[{"name": "Data Retention Policy", "frameworks": [{"code": "CIS Control 3 - Safeguard 3.4", "framework": "CIS Critical Security Controls v8"}, {"code": "SI-12", "framework": "NIST SP 800-53 Rev 5"}], "description": "A documented policy outlining the procedures for data retention and disposal.", "framework_count": 2}, {"name": "Retention Compliance Audit Results", "frameworks": [{"code": "CIS Control 3 - Safeguard 3.4", "framework": "CIS Critical Security Controls v8"}, {"code": "SI-12", "framework": "NIST SP 800-53 Rev 5"}], "description": "Results from audits verifying compliance with data retention policies.", "framework_count": 2}, {"name": "Automated Retention Controls", "frameworks": [{"code": "CIS Control 3 - Safeguard 3.4", "framework": "CIS Critical Security Controls v8"}], "description": "Systems and processes in place to automate data retention according to policy.", "framework_count": 1}, {"name": "Record Retention Schedule", "frameworks": [{"code": "SI-12", "framework": "NIST SP 800-53 Rev 5"}], "description": "A schedule detailing the duration for which different types of records must be retained.", "framework_count": 1}, {"name": "Data Disposal Procedures", "frameworks": [{"code": "SI-12", "framework": "NIST SP 800-53 Rev 5"}], "description": "Procedures for the secure disposal of data that is no longer needed.", "framework_count": 1}]	18	pending	\N	\N
4778	NCS23-0001	Security Awareness and Training	\N	\N	\N	\N	\N	0	2026-06-21 09:04:07.927192	Awareness & Training	ai_normalized	\N	[{"name": "Training Completion Records", "frameworks": [{"code": "1.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "§164.308(a)(5)(i)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "1.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PR.AT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "3.6.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "ELC-04", "framework": "SOX IT General Controls"}, {"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "AT-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "02.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating completion of training by all workforce members, including dates and participant details.", "framework_count": 11}, {"name": "Training Program Documentation", "frameworks": [{"code": "1.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "1.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PR.AT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "3.6.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "ELC-04", "framework": "SOX IT General Controls"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Comprehensive documentation of the training program including objectives, content, and delivery methods.", "framework_count": 8}, {"name": "Awareness Materials", "frameworks": [{"code": "1.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "§164.308(a)(5)(i)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PR.AT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "02.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Materials used to promote security awareness, including campaigns and educational content.", "framework_count": 7}, {"name": "Training Effectiveness Assessments", "frameworks": [{"code": "Article 14(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "5.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "3.6.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "5.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Evaluations measuring the effectiveness of training programs, including results and recommendations.", "framework_count": 6}, {"name": "Training Attendance Records", "frameworks": [{"code": "Article 14(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "02.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "DS.6", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records showing attendance at training sessions, including details of participants and session dates.", "framework_count": 4}, {"name": "Phishing Simulation Results", "frameworks": [{"code": "AT-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Results from phishing simulations used to assess and improve security awareness among employees.", "framework_count": 2}, {"name": "Annual Training Calendar", "frameworks": [{"code": "HR 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "AT-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "A calendar outlining the schedule for security training sessions throughout the year.", "framework_count": 2}, {"name": "Senior Management Training Evidence", "frameworks": [{"code": "Article 14(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation evidencing training provided to senior management on security awareness.", "framework_count": 1}, {"name": "Role-Based Training Records", "frameworks": [{"code": "A.6.3", "framework": "ISO/IEC 27001:2022"}], "description": "Records of specialized training tailored for specific roles within the organization.", "framework_count": 1}, {"name": "Documented Information Security Training", "frameworks": [{"code": "DS.6", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documentation of information security training and awareness programs as per regulatory requirements.", "framework_count": 1}, {"name": "NCA Assessment/Compliance Records", "frameworks": [{"code": "DS.6", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of assessments conducted by the NCA to ensure compliance with information security training requirements.", "framework_count": 1}]	23	pending	\N	\N
4713	NCF0233	Privacy Monitoring and Auditing	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.631336	Data Protection & Privacy	ai_normalized	\N	[{"name": "Approved Privacy Monitoring and Auditing Policy", "frameworks": [{"code": "13.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Privacy Monitoring and Auditing, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Documented Privacy Monitoring and Auditing Procedure", "frameworks": [{"code": "13.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure or work instruction implementing Privacy Monitoring and Auditing, detailing responsible roles and control points.", "framework_count": 1}, {"name": "Audit Logging Configuration Evidence", "frameworks": [{"code": "13.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of audit logging configuration, including events captured, retention, and tamper protection, preserved for the required retention period.", "framework_count": 1}, {"name": "Log Review Records", "frameworks": [{"code": "13.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of log reviews and follow-up case documentation, including timestamps, actor identity, and actions taken, preserved for the required retention period.", "framework_count": 1}, {"name": "Audit Plan and Reports", "frameworks": [{"code": "13.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Audit plan and reports detailing scope, findings, and remediation tracking, including methodology and management responses.", "framework_count": 1}, {"name": "Published Privacy Notice/Statement", "frameworks": [{"code": "13.s", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Privacy notice/statement published to data subjects with version history, demonstrating implementation of the control.", "framework_count": 1}, {"name": "Privacy Complaint Tracking System", "frameworks": [{"code": "P8.1", "framework": "SOC 2 Type II"}], "description": "System for tracking privacy complaints and inquiries.", "framework_count": 1}, {"name": "Complaint Resolution Documentation", "frameworks": [{"code": "P8.1", "framework": "SOC 2 Type II"}], "description": "Documentation and records of responses to privacy complaints and inquiries.", "framework_count": 1}, {"name": "Privacy Compliance Monitoring Reports", "frameworks": [{"code": "P8.1", "framework": "SOC 2 Type II"}], "description": "Reports on privacy compliance monitoring and audit results.", "framework_count": 1}, {"name": "Privacy Noncompliance Incident Reports", "frameworks": [{"code": "P8.1", "framework": "SOC 2 Type II"}], "description": "Reports of privacy noncompliance incidents and associated corrective action plans.", "framework_count": 1}]	18	pending	\N	\N
4715	NCF0235	Secure Disposal or Re-Use of Equipment	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.631336	Data Protection & Privacy	ai_normalized	\N	[{"name": "Equipment Disposal Procedure", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}, {"code": "08.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Procedure for secure disposal, reuse, and destruction of equipment with storage, including step-by-step instructions and responsible roles.", "framework_count": 2}, {"name": "Data Sanitisation Records", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}], "description": "Records showing method used (overwrite/degauss/destroy) per device to ensure data is securely erased.", "framework_count": 1}, {"name": "Certificates of Destruction", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}], "description": "Certificates from disposal vendors confirming secure destruction of equipment.", "framework_count": 1}, {"name": "Disposal Vendor Due Diligence", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}], "description": "Assessment of disposal vendor's certifications (e.g., NAID AAA, R2) to ensure compliance with security standards.", "framework_count": 1}, {"name": "Asset Retirement Workflow Screenshot", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}], "description": "Screenshot of IT asset management workflow showing retirement steps and approvals.", "framework_count": 1}, {"name": "Reuse Approval Records", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}], "description": "Records approving internal reuse of equipment after data wipe with verification.", "framework_count": 1}, {"name": "Software License Reclamation Log", "frameworks": [{"code": "A.7.14", "framework": "ISO/IEC 27001:2022"}], "description": "Log of software licenses reclaimed from decommissioned equipment.", "framework_count": 1}, {"name": "Physical Access Logs", "frameworks": [{"code": "08.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Logs of physical access (badge/biometric) and visitor register preserved for the required retention period.", "framework_count": 1}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "08.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of CCTV deployment and footage retention records demonstrating activity occurrence.", "framework_count": 1}, {"name": "Data Loss Prevention (DLP) Deployment", "frameworks": [{"code": "08.l", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Deployment of Data Loss Prevention (DLP) with policies and event records demonstrating activity occurrence.", "framework_count": 1}]	18	pending	\N	\N
4716	NCF0236	Deploy a Data Loss Prevention Solution	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.648958	Data Protection & Privacy	ai_normalized	\N	[{"name": "DLP Policy and Configuration", "frameworks": [{"code": "CIS Control 3 - Safeguard 3.13", "framework": "CIS Critical Security Controls v8"}, {"code": "11.1.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation and configuration records for Data Loss Prevention solutions and policies.", "framework_count": 2}, {"name": "DLP Incident Reports", "frameworks": [{"code": "CIS Control 3 - Safeguard 3.13", "framework": "CIS Critical Security Controls v8"}], "description": "Reports detailing alerts and incidents related to Data Loss Prevention.", "framework_count": 1}]	18	pending	\N	\N
4717	NCF0237	Disposal of Media	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.657571	Data Protection & Privacy	ai_normalized	\N	[{"name": "Approved Disposal of Media Policy", "frameworks": [{"code": "09.p", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing the disposal of media, including scope, applicability, roles, and responsibilities.", "framework_count": 1}, {"name": "Documented Disposal of Media Procedure", "frameworks": [{"code": "09.p", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing disposal of media, including step-by-step instructions, responsible roles, and control points.", "framework_count": 1}, {"name": "Awareness Communications for Media Disposal", "frameworks": [{"code": "09.p", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the media disposal requirements, including attendee list and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "09.p", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews with reviewer details, date, observations, and corrective actions demonstrating that the review activity occurred.", "framework_count": 1}, {"name": "Media Destruction Logs", "frameworks": [{"code": "AM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of media destruction (digital and physical) preserved for the required retention period, protected from tampering, with timestamps and actor identity.", "framework_count": 1}, {"name": "Shredding/Wiping Evidence", "frameworks": [{"code": "AM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating implementation of shredding or wiping control, including date, owner, and reference to related policy or procedure.", "framework_count": 1}, {"name": "Witness Records for Destruction", "frameworks": [{"code": "AM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating that destruction activities occurred, including date, performer, approver, and reference to related policy.", "framework_count": 1}, {"name": "Destruction Certificates from Authorized Vendors", "frameworks": [{"code": "AM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Certificates from authorized vendors confirming destruction, including issuance date, scope, expiry/validity period, and authorized signatory.", "framework_count": 1}]	18	pending	\N	\N
4718	NCF0238	Implement logging and monitoring of system activities	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.66159	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Logging & Monitoring Policy", "frameworks": [{"code": "2.4.5.f", "framework": "SBP ETGRMF"}], "description": "Policy defining logging requirements, retention, and log-integrity protections.", "framework_count": 1}, {"name": "SIEM Architecture Diagram", "frameworks": [{"code": "2.4.5.f", "framework": "SBP ETGRMF"}], "description": "Architecture of logging/SIEM infrastructure showing log collection and storage.", "framework_count": 1}, {"name": "Sample System & User Activity Logs", "frameworks": [{"code": "2.4.5.f", "framework": "SBP ETGRMF"}], "description": "Representative logs showing system and user activity capture.", "framework_count": 1}, {"name": "Monitoring Alert Response Records", "frameworks": [{"code": "2.4.5.f", "framework": "SBP ETGRMF"}], "description": "Records of alerts triggered from log monitoring and response actions.", "framework_count": 1}, {"name": "Security Monitoring Strategy", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Strategy document defining SOC scope, coverage, and detection goals.", "framework_count": 1}, {"name": "SIEM Use-Case Library", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Catalogue of detection use cases mapped to MITRE ATT&CK.", "framework_count": 1}, {"name": "SOC Runbook/Playbooks", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Playbooks for responding to specific alert types.", "framework_count": 1}, {"name": "Detection Alert Tuning Log", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Log of detection rule changes and tuning actions over time.", "framework_count": 1}, {"name": "Monitoring Coverage Report", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Report showing monitoring coverage across environments and assets.", "framework_count": 1}, {"name": "SOC Shift Handover Records", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Shift handover documentation showing continuous monitoring.", "framework_count": 1}, {"name": "Threat Hunting Reports", "frameworks": [{"code": "A.8.16", "framework": "ISO/IEC 27001:2022"}], "description": "Proactive threat hunting engagement reports with findings.", "framework_count": 1}]	18	pending	\N	\N
4721	NCF0241	Develop annual IT audit plan	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.679253	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Annual IT Audit Plan", "frameworks": [{"code": "6.1.a", "framework": "SBP ETGRMF"}], "description": "Documented annual IT audit plan covering goals, schedules, staffing needs, budget and reporting requirements, including budget documentation.", "framework_count": 1}, {"name": "Audit Committee Approval", "frameworks": [{"code": "6.1.a", "framework": "SBP ETGRMF"}], "description": "Audit Committee/Board approval of the annual IT audit plan.", "framework_count": 1}, {"name": "Audit Plan Execution Records", "frameworks": [{"code": "6.1.a", "framework": "SBP ETGRMF"}], "description": "Evidence of audit activities executed per the annual plan.", "framework_count": 1}, {"name": "Annual Audit Reports", "frameworks": [{"code": "3.1.3", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Reports summarizing the findings and outcomes of the annual audits.", "framework_count": 1}, {"name": "Non-conformance Tracker", "frameworks": [{"code": "3.1.3", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Tracker documenting non-conformances with remediation timelines.", "framework_count": 1}, {"name": "Audit Scope Documentation", "frameworks": [{"code": "3.1.3", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation outlining the scope of the audits conducted.", "framework_count": 1}]	18	pending	\N	\N
4723	NCF0243	Authentication Controls	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.679253	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Customer Authentication Policy and Documentation", "frameworks": [{"code": "2.2.1", "framework": "SBP Internet Banking Framework"}, {"code": "14.2.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Approved authentication policy and supporting documentation for Internet Banking customers, covering enrollment, 2FA, layered security, and adaptive authentication systems.", "framework_count": 2}, {"name": "Authentication Architecture and Controls", "frameworks": [{"code": "2.2.1", "framework": "SBP Internet Banking Framework"}, {"code": "14.2.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documented architecture and implementation matrix for customer authentication, including identity provider, MFA broker, and risk-based authentication rules.", "framework_count": 2}]	18	pending	\N	\N
4724	NCF0244	Audit Log Storage Capacity	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.694909	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Audit and Storage Capacity Planning", "frameworks": [{"code": "AU-4", "framework": "NIST SP 800-53 Rev 5"}, {"code": "CIS Control 8 - Safeguard 8.3", "framework": "CIS Critical Security Controls v8"}], "description": "Procedures for planning and monitoring audit log storage capacity and utilization.", "framework_count": 2}, {"name": "Log Storage Utilization Monitoring", "frameworks": [{"code": "AU-4", "framework": "NIST SP 800-53 Rev 5"}, {"code": "CIS Control 8 - Safeguard 8.3", "framework": "CIS Critical Security Controls v8"}], "description": "Monitoring procedures for the utilization of log storage resources.", "framework_count": 2}, {"name": "Log Rotation and Archival Procedures", "frameworks": [{"code": "AU-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Procedures for log rotation and archival to manage log data effectively.", "framework_count": 1}, {"name": "Storage Expansion Procedures", "frameworks": [{"code": "CIS Control 8 - Safeguard 8.3", "framework": "CIS Critical Security Controls v8"}], "description": "Procedures for expanding storage capacity for logs as needed.", "framework_count": 1}]	18	pending	\N	\N
4725	NCF0245	Business Impact Analysis of ICT Disruptions	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.694909	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Business Impact Analysis (BIA) Report", "frameworks": [{"code": "Article 11(2)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "8.2.1", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "A comprehensive report detailing the business impact analysis, including critical function identification and recovery priority classification.", "framework_count": 2}, {"name": "ICT Disruption Impact Assessment", "frameworks": [{"code": "Article 11(2)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "An assessment focused on the impact of ICT disruptions on business operations.", "framework_count": 1}]	18	pending	\N	\N
4726	NCF0246	Service Provider Disaster Recovery Plan	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.694909	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Disaster Recovery Plan Document", "frameworks": [{"code": "2.2.3(d)(i)", "framework": "SBP Internet Banking Framework"}, {"code": "§164.308(a)(7)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Approved Disaster Recovery Plan from the Service Provider covering IB-supporting services.", "framework_count": 2}, {"name": "DR Test Reports", "frameworks": [{"code": "2.2.3(d)(i)", "framework": "SBP Internet Banking Framework"}, {"code": "§164.308(a)(7)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Periodic DR test reports from the SP with results, gaps, and corrective actions.", "framework_count": 2}, {"name": "DR Plan Alignment Evidence", "frameworks": [{"code": "2.2.3(d)(i)", "framework": "SBP Internet Banking Framework"}], "description": "Side-by-side comparison evidencing alignment of SP DR objectives (RTO/RPO) with the bank's documented business requirements.", "framework_count": 1}, {"name": "Joint DR Walkthrough Records", "frameworks": [{"code": "2.2.3(d)(i)", "framework": "SBP Internet Banking Framework"}], "description": "Records of joint DR walkthroughs or table-top exercises between bank and SP.", "framework_count": 1}, {"name": "DR Site Type Documentation", "frameworks": [{"code": "2.2.3(d)(ii)", "framework": "SBP Internet Banking Framework"}], "description": "SP documentation describing the type and configuration of each DR site (Cold / Warm / Hot / Satellite).", "framework_count": 1}, {"name": "DR Site Operational Evidence", "frameworks": [{"code": "2.2.3(d)(ii)", "framework": "SBP Internet Banking Framework"}], "description": "Operational evidence (site visit reports, photographs, infrastructure inventory) of each DR site.", "framework_count": 1}, {"name": "Site Activation Procedures", "frameworks": [{"code": "2.2.3(d)(ii)", "framework": "SBP Internet Banking Framework"}], "description": "SP procedures for activating each DR site type with timelines.", "framework_count": 1}, {"name": "DR Site Geographic Risk Map", "frameworks": [{"code": "2.2.3(d)(ii)", "framework": "SBP Internet Banking Framework"}], "description": "Geographic risk map showing DR site separation against single-event risks (earthquake, flood, power grid).", "framework_count": 1}, {"name": "RTO and RPO Definitions", "frameworks": [{"code": "§164.308(a)(7)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Definitions of Recovery Time Objective (RTO) and Recovery Point Objective (RPO).", "framework_count": 1}, {"name": "Recovery Procedures for Critical Systems", "frameworks": [{"code": "§164.308(a)(7)(ii)(B)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Procedures for recovering critical systems as part of the disaster recovery plan.", "framework_count": 1}]	18	pending	\N	\N
4729	NCF0249	Testing and Revision Procedures	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.710687	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Contingency Plan Test Documentation", "frameworks": [{"code": "§164.308(a)(7)(ii)(D)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "14.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Includes test schedules, results, findings, and revision records based on outcomes.", "framework_count": 2}]	18	pending	\N	\N
4730	NCF0250	Data Backup and Storage	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.710687	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Backup Procedures and Verification", "frameworks": [{"code": "§164.310(d)(2)(iv)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "CP-9", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of backup procedures, verification processes, and integrity checks before equipment moves.", "framework_count": 2}]	18	pending	\N	\N
4731	NCF0251	Management Review — General	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.726871	Audit & Assurance	ai_normalized	\N	[{"name": "Management Review Documentation", "frameworks": [{"code": "9.3.1", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Includes both the calendar and procedure for planned top-management reviews of the AI Management System.", "framework_count": 1}, {"name": "General Controls Audit Documentation", "frameworks": [{"code": "6.2.b", "framework": "SBP ETGRMF"}], "description": "Comprises audit reports, coverage matrix, remediation records, and annual coverage dashboard related to general controls.", "framework_count": 1}]	18	pending	\N	\N
4733	NCF0253	Identification of Information and Information Systems to be Protected	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.726871	Asset Management	ai_normalized	\N	[{"name": "Information Asset Inventory", "frameworks": [{"code": "2.1(b)", "framework": "SBP Internet Banking Framework"}, {"code": "DC.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Comprehensive inventory of all information assets in scope, including ownership, classification, and protection requirements.", "framework_count": 2}, {"name": "Information Systems Inventory", "frameworks": [{"code": "2.1(b)", "framework": "SBP Internet Banking Framework"}], "description": "Extract from the Configuration Management Database (CMDB) listing all information systems supporting Internet Banking.", "framework_count": 1}, {"name": "Asset-to-Service Mapping", "frameworks": [{"code": "2.1(b)", "framework": "SBP Internet Banking Framework"}], "description": "Mapping of each Internet Banking service/product to its underlying information assets and systems.", "framework_count": 1}, {"name": "Documented Data Identification Procedures", "frameworks": [{"code": "DC.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented procedures and workflows for implementing Data Identification, including roles and control points.", "framework_count": 1}, {"name": "Organizational Artifacts", "frameworks": [{"code": "DC.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Artifacts such as role mandates, RACI, job descriptions, and committee charters that define responsibilities and coverage.", "framework_count": 1}, {"name": "Data Classification Scheme", "frameworks": [{"code": "DC.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Data classification scheme and labeled dataset register according to classification levels, including item details.", "framework_count": 1}, {"name": "Metadata Repository", "frameworks": [{"code": "DC.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Export of the metadata repository or data catalog, including business glossary and data dictionary.", "framework_count": 1}]	18	pending	\N	\N
4734	NCF0254	Supplier Reviews	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.742693	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Supplier Evaluation and Compliance Documentation", "frameworks": [{"code": "SA 7.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive documentation of the supplier evaluation process, including pre-contract reviews, compliance reviews, and verification of government compliance.", "framework_count": 1}, {"name": "Supplier Risk Assessment and Monitoring", "frameworks": [{"code": "SR-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Reports and documentation related to supplier risk assessments, vendor reviews, and compliance monitoring.", "framework_count": 1}, {"name": "Third-Party Audit Reports", "frameworks": [{"code": "SR-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of third-party audits conducted on suppliers to ensure compliance with relevant standards.", "framework_count": 1}]	18	pending	\N	\N
4735	NCF0255	Third-Party Risk Policies	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.742693	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third-Party Risk Policies", "frameworks": [{"code": "GOVERN 6.1", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}, {"code": "Article 28(2)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Board/management-approved policies and procedures for managing third-party risks, including assessments and strategies.", "framework_count": 2}]	18	pending	\N	\N
4736	NCF0256	ICT Third-Party Risk General Principles	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.742693	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third-party risk management policy", "frameworks": [{"code": "Article 28(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}], "description": "A documented policy outlining the management of risks associated with third-party vendors.", "framework_count": 2}, {"name": "Integration with ICT risk framework documentation", "frameworks": [{"code": "Article 28(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation that integrates third-party risk management with the ICT risk framework.", "framework_count": 1}, {"name": "Responsibility assignment for third-party oversight", "frameworks": [{"code": "Article 28(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation detailing the assignment of responsibilities for overseeing third-party relationships.", "framework_count": 1}, {"name": "Regulatory compliance obligations mapping", "frameworks": [{"code": "Article 28(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "A mapping of compliance obligations related to third-party risk management.", "framework_count": 1}, {"name": "Vendor due diligence assessment records", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}], "description": "Records of assessments conducted to evaluate the risks associated with vendors.", "framework_count": 1}, {"name": "Security requirements in contracts and SLAs", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}], "description": "Documentation of security requirements included in contracts and service level agreements with third parties.", "framework_count": 1}, {"name": "Third-party compliance monitoring records", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}], "description": "Records of monitoring activities to ensure third-party compliance with security requirements.", "framework_count": 1}]	18	pending	\N	\N
4737	NCF0257	Establish and Maintain a Secure Application Development Process	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.758691	Application & Software Security	ai_normalized	\N	[{"name": "Secure SDLC Documentation", "frameworks": [{"code": "CIS Control 16 - Safeguard 16.1", "framework": "CIS Critical Security Controls v8"}, {"code": "9.4.2.4", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation outlining secure software development lifecycle practices, including secure coding standards referencing OWASP/CERT/CWE.", "framework_count": 2}, {"name": "Security Gate Definitions", "frameworks": [{"code": "CIS Control 16 - Safeguard 16.1", "framework": "CIS Critical Security Controls v8"}], "description": "Defined criteria and checkpoints within the secure software development lifecycle to ensure security measures are met.", "framework_count": 1}, {"name": "Process Review Records", "frameworks": [{"code": "CIS Control 16 - Safeguard 16.1", "framework": "CIS Critical Security Controls v8"}], "description": "Records of reviews conducted on the software development process to ensure compliance with security standards.", "framework_count": 1}]	18	pending	\N	\N
4739	NCF0259	Least Functionality	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.758691	Configuration & Change Management	ai_normalized	\N	[{"name": "System Hardening Documentation", "frameworks": [{"code": "PR.PT-3", "framework": "NIST Cybersecurity Framework"}, {"code": "CM-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation detailing the hardening measures applied to systems.", "framework_count": 2}, {"name": "Service Inventory", "frameworks": [{"code": "PR.PT-3", "framework": "NIST Cybersecurity Framework"}], "description": "A comprehensive list of services running on the system.", "framework_count": 1}, {"name": "Functionality Review", "frameworks": [{"code": "PR.PT-3", "framework": "NIST Cybersecurity Framework"}], "description": "Assessment of system functionalities to ensure compliance with security requirements.", "framework_count": 1}, {"name": "Approved Software/Service List", "frameworks": [{"code": "CM-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "A list of approved software and services that are permitted to run on the system.", "framework_count": 1}, {"name": "Port and Protocol Restrictions", "frameworks": [{"code": "CM-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of the restrictions applied to network ports and protocols.", "framework_count": 1}, {"name": "Unnecessary Service Removal Records", "frameworks": [{"code": "CM-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records indicating the removal of unnecessary services from the system.", "framework_count": 1}]	18	pending	\N	\N
4741	NCF0261	Change Testing and Quality Assurance	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.774792	Configuration & Change Management	ai_normalized	\N	[{"name": "Change Test Plans and Results", "frameworks": [{"code": "CM-04", "framework": "SOX IT General Controls"}, {"code": "7.5.3", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of change test plans, execution results, and management approval.", "framework_count": 2}, {"name": "UAT Approval Documentation", "frameworks": [{"code": "CM-04", "framework": "SOX IT General Controls"}], "description": "Documentation of User Acceptance Testing approval.", "framework_count": 1}, {"name": "Non-Production Environment Configuration", "frameworks": [{"code": "CM-04", "framework": "SOX IT General Controls"}], "description": "Documentation of the configuration of non-production environments.", "framework_count": 1}]	18	pending	\N	\N
4742	NCF0262	Change Impact Analysis	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.783379	Configuration & Change Management	ai_normalized	\N	[{"name": "Change Risk and Impact Analysis Documentation", "frameworks": [{"code": "7.5.2", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "4.2.6.c", "framework": "SBP ETGRMF"}], "description": "Comprehensive documentation of risk and impact analyses for change requests, including management approvals and assessments of upstream/downstream systems.", "framework_count": 2}]	18	pending	\N	\N
4743	NCF0263	Post-Implementation Review	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.790915	Configuration & Change Management	ai_normalized	\N	[{"name": "Post-Implementation Review Documentation", "frameworks": [{"code": "PD-06", "framework": "SOX IT General Controls"}, {"code": "8.1.10", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation detailing the review and assessment of a system after its implementation.", "framework_count": 2}, {"name": "Requirements Fulfillment Validation", "frameworks": [{"code": "PD-06", "framework": "SOX IT General Controls"}], "description": "Evidence confirming that all specified requirements have been met.", "framework_count": 1}, {"name": "Control Effectiveness Verification", "frameworks": [{"code": "PD-06", "framework": "SOX IT General Controls"}], "description": "Evidence demonstrating that controls are functioning as intended.", "framework_count": 1}, {"name": "Lessons Learned Documentation", "frameworks": [{"code": "PD-06", "framework": "SOX IT General Controls"}], "description": "Records capturing insights and experiences gained from the project.", "framework_count": 1}, {"name": "Side-Effect Monitoring Evidence", "frameworks": [{"code": "8.1.10", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documentation related to monitoring unintended consequences of the implemented system.", "framework_count": 1}]	18	pending	\N	\N
4744	NCF0264	Vulnerability Scanning	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.796621	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Vulnerability Scan Reports", "frameworks": [{"code": "2.7", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "RA-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Reports detailing the results of vulnerability scans conducted on systems.", "framework_count": 2}, {"name": "Remediation Tracking Records", "frameworks": [{"code": "2.7", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "RA-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records that track the remediation efforts for identified vulnerabilities.", "framework_count": 2}, {"name": "Scan Schedule Documentation", "frameworks": [{"code": "2.7", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "RA-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation outlining the schedule for conducting vulnerability scans.", "framework_count": 2}, {"name": "Risk Acceptance Records", "frameworks": [{"code": "2.7", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Records that document the acceptance of risks associated with vulnerabilities.", "framework_count": 1}, {"name": "Scanning Tool Configuration", "frameworks": [{"code": "RA-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Configuration settings for the tools used to perform vulnerability scans.", "framework_count": 1}]	18	pending	\N	\N
4746	NCF0266	Information Security Incident Management	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.806766	Incident Management	ai_normalized	\N	[{"name": "Incident Classification and Handling Documentation", "frameworks": [{"code": "IM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "Article 18(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation including incident classification scheme, handling workflows, and severity definitions aligned with relevant standards.", "framework_count": 2}, {"name": "Documented Incident Management Artifacts", "frameworks": [{"code": "DS.9", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Preserved artifacts demonstrating compliance with incident management regulations and methodologies.", "framework_count": 1}, {"name": "NCA Assessment and Compliance Records", "frameworks": [{"code": "DS.9", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of assessments and compliance conducted by NCA, including details of the activity.", "framework_count": 1}]	18	pending	\N	\N
4747	NCF0267	Learning from Information Security Incidents	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.817611	Incident Management	ai_normalized	\N	[{"name": "Incident Metrics and Improvement Recommendations", "frameworks": [{"code": "12.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation of incident metrics, lessons learned, and recommendations for improvement.", "framework_count": 1}, {"name": "Learning from Information Security Incidents Policy", "frameworks": [{"code": "11.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing learning from information security incidents.", "framework_count": 1}, {"name": "Documented Procedure for Learning from Incidents", "frameworks": [{"code": "11.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure or work instruction for implementing learning from information security incidents.", "framework_count": 1}, {"name": "Audit Logging Configuration Evidence", "frameworks": [{"code": "11.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of audit logging configuration including events captured, retention, and tamper protection.", "framework_count": 1}, {"name": "Log Review Records and Follow-up Documentation", "frameworks": [{"code": "11.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of log reviews and follow-up case documentation, including timestamps and actor identity.", "framework_count": 1}, {"name": "Incident Response Plan", "frameworks": [{"code": "11.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Incident response plan detailing classification, escalation, and notification timelines.", "framework_count": 1}, {"name": "Incident Register with Case Records", "frameworks": [{"code": "11.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Incident register containing case records, root cause analysis, and lessons learned.", "framework_count": 1}]	18	pending	\N	\N
4748	NCF0268	Incident Response Testing	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.824645	Incident Management	ai_normalized	\N	[{"name": "Tabletop Exercise Records", "frameworks": [{"code": "IM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "IR-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of tabletop exercises demonstrating the activity, including date, performer, and approver where applicable.", "framework_count": 2}, {"name": "Incident Response Test Procedures", "frameworks": [{"code": "IM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive documentation of incident response test procedures, including step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Gap Analysis Reports", "frameworks": [{"code": "IM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports detailing the findings and recommendations from incident response tests, including scope and methodology.", "framework_count": 1}, {"name": "Lessons Learned Documentation", "frameworks": [{"code": "IR-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation capturing lessons learned from incident response activities to improve future responses.", "framework_count": 1}]	18	pending	\N	\N
4750	NCF0270	Incident Management Framework	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.836752	Incident Management	ai_normalized	\N	[{"name": "Incident Response Procedure", "frameworks": [{"code": "2.1.e", "framework": "SBP ETGRMF"}, {"code": "7.7.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "8.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documented incident response procedure covering identification, classification, escalation, reporting, and closure.", "framework_count": 3}, {"name": "Incident Response Playbooks", "frameworks": [{"code": "7.7.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "8.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Incident playbooks covering all listed steps for effective incident management.", "framework_count": 2}, {"name": "Incident Log", "frameworks": [{"code": "2.1.e", "framework": "SBP ETGRMF"}], "description": "Incident log with details (severity, impact, response, RCA, closure) for all reported incidents.", "framework_count": 1}, {"name": "Incident Reporting Template", "frameworks": [{"code": "2.1.e", "framework": "SBP ETGRMF"}], "description": "Template aligned with SBP BPRD incident reporting format used for 48-hour regulatory reports.", "framework_count": 1}, {"name": "Incident Management Information System (MIS)", "frameworks": [{"code": "2.1.e", "framework": "SBP ETGRMF"}], "description": "Periodic incident MIS submitted to senior management and ITSC.", "framework_count": 1}, {"name": "IDS/IPS Alert Configuration", "frameworks": [{"code": "8.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Configuration settings for Intrusion Detection System/Intrusion Prevention System alerts.", "framework_count": 1}]	18	pending	\N	\N
4751	NCF0271	Problem Management Process	\N	\N	\N	\N	\N	0	2026-06-21 08:21:21.838502	Incident Management	ai_normalized	\N	[{"name": "Problem Management Procedures", "frameworks": [{"code": "7.8.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "8.6.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documented procedures for managing problems and incidents, including root cause analysis.", "framework_count": 2}, {"name": "Root Cause Analysis Reports", "frameworks": [{"code": "7.8.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "8.6.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Records of root cause analysis conducted for incidents and problems.", "framework_count": 2}, {"name": "Known Error Database", "frameworks": [{"code": "8.6.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "A database containing known errors and their workarounds.", "framework_count": 1}, {"name": "Trend Analysis Reports", "frameworks": [{"code": "8.6.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Reports analyzing trends in incidents and problems over time.", "framework_count": 1}]	18	pending	\N	\N
4481	NCF0001	Risk Assessment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.038564	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Technology Risk Assessment Documentation", "frameworks": [{"code": "9.1.13.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "4.3.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "6.1.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "4.4.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Comprehensive documentation of technology risk assessments including reports, methodologies, and approvals.", "framework_count": 4}, {"name": "AI Risk Assessment Documentation", "frameworks": [{"code": "6.1.2", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Documented methodologies and reports for AI risk assessments, including risk registers and validation records.", "framework_count": 1}, {"name": "Deviation Risk Management Records", "frameworks": [{"code": "3.2.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records of risk assessment reports and approvals related to policy deviations.", "framework_count": 1}, {"name": "Risk Acceptance Documentation", "frameworks": [{"code": "4.4.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of residual risk assessments and management approvals for risk acceptance.", "framework_count": 1}]	18	pending	\N	\N
4482	NCF0002	Board Technology Risk Knowledge	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.05219	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Technology Risk Committee Documentation", "frameworks": [{"code": "1.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "3.1.7", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Charters and minutes related to the Technology Risk committee's activities.", "framework_count": 2}, {"name": "IT Policy and Procedure Register", "frameworks": [{"code": "1.2.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "A comprehensive register of IT policies, standards, and procedures.", "framework_count": 1}, {"name": "Board Member Competency and Training Records", "frameworks": [{"code": "3.1.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Profiles and training records demonstrating board members' knowledge of technology risk.", "framework_count": 1}, {"name": "Board Risk Oversight Documentation", "frameworks": [{"code": "3.1.7", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Risk appetite statement and terms of reference for technology risk oversight approved by the board.", "framework_count": 1}]	18	pending	\N	\N
4483	NCF0003	Board and senior management governance of outsourced processes	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.073533	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Board Oversight Documentation", "frameworks": [{"code": "3.1.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "9.10.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "2.5.a", "framework": "SBP ETGRMF"}], "description": "Evidence of board oversight including approved frameworks and meeting minutes related to IT controls and risk management practices.", "framework_count": 3}, {"name": "Cyber Governance Framework", "frameworks": [{"code": "2.5.a", "framework": "SBP ETGRMF"}], "description": "Documents establishing the governance structure and accountability for cyber security actions.", "framework_count": 1}, {"name": "Executive Cyber Engagement Records", "frameworks": [{"code": "2.5.a", "framework": "SBP ETGRMF"}], "description": "Records of executive-level briefings and drills related to cyber security.", "framework_count": 1}, {"name": "Outsourcing Governance Framework", "frameworks": [{"code": "9.10.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Framework governing outsourcing practices related to technology risks.", "framework_count": 1}]	18	pending	\N	\N
4491	NCF0011	Contact with Authorities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.115277	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Authorities Contact Register and Communication Records", "frameworks": [{"code": "A.5.5", "framework": "ISO/IEC 27001:2022"}], "description": "Register of relevant authorities with contact details and evidence of past communications with them, including incident reports.", "framework_count": 1}, {"name": "Authority Escalation Procedure", "frameworks": [{"code": "A.5.5", "framework": "ISO/IEC 27001:2022"}], "description": "Procedure outlining triggers, timings, and approvers for contacting relevant authorities.", "framework_count": 1}, {"name": "Regulatory Breach Notification Template", "frameworks": [{"code": "A.5.5", "framework": "ISO/IEC 27001:2022"}], "description": "Pre-drafted notification template aligned with statutory reporting requirements.", "framework_count": 1}, {"name": "Annual Contact Verification Record", "frameworks": [{"code": "A.5.5", "framework": "ISO/IEC 27001:2022"}], "description": "Annual confirmation log that verifies the accuracy of authority contact details.", "framework_count": 1}, {"name": "Approved Policy and Standard for Contact with Authorities", "frameworks": [{"code": "05.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board-approved policy addressing contact with authorities, including scope and roles.", "framework_count": 1}, {"name": "Documented Procedure for Contact with Authorities", "frameworks": [{"code": "05.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure for implementing contact with authorities, including responsible roles.", "framework_count": 1}, {"name": "Awareness Communications for Personnel", "frameworks": [{"code": "05.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications ensuring personnel are informed about the requirements for contacting authorities.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "05.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating periodic reviews of the contact procedures with authorities, including observations and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4484	NCF0004	Risk Management Process and Outcomes	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.079528	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Risk Management Process Documentation", "frameworks": [{"code": "GOVERN 1.4", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}], "description": "Documented evidence demonstrating the outcome of the Risk Management Process, including policies, procedures, and periodic review records.", "framework_count": 1}, {"name": "Organizational AI Risk Tolerance Statement", "frameworks": [{"code": "GOVERN 1.4", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}], "description": "Documented organizational AI risk tolerance statement with approval records, demonstrating the activity occurred.", "framework_count": 1}, {"name": "Information Security Risk Management Artifacts", "frameworks": [{"code": "DS.10", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented Information Security Risk Management artifacts addressed under NCA regulations, preserved for the required retention period.", "framework_count": 1}, {"name": "Compliance Evidence with NCA Requirements", "frameworks": [{"code": "DS.10", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Evidence of compliance with NCA requirements for Information Security Risk Management, demonstrating implementation of the specification.", "framework_count": 1}, {"name": "NCA Assessment/Compliance Records", "frameworks": [{"code": "DS.10", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "NCA assessment/compliance records conducted by NCA, demonstrating the activity occurred.", "framework_count": 1}]	18	pending	\N	\N
4485	NCF0005	Information Security Risk Treatment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.085006	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Risk Treatment Plan", "frameworks": [{"code": "4.4.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "1.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "MANAGE 1.2", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}, {"code": "6.1.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Comprehensive documentation of the risk treatment plan including decisions and rationale.", "framework_count": 4}, {"name": "Control Implementation Records", "frameworks": [{"code": "1.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "6.1.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Records demonstrating the implementation of controls as part of the risk treatment process.", "framework_count": 2}, {"name": "Residual Risk Acceptance Records", "frameworks": [{"code": "1.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "6.1.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Documentation of management approval for acceptance of residual risks.", "framework_count": 2}, {"name": "AI Impact Assessment", "frameworks": [{"code": "MANAGE 1.2", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}], "description": "Assessment documenting the likelihood and magnitude of impacts related to AI risks.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "MANAGE 1.2", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}], "description": "Records demonstrating the periodic review of risk treatment outcomes over time.", "framework_count": 1}, {"name": "Statement of Applicability (SoA)", "frameworks": [{"code": "6.1.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Document listing all necessary controls with justifications for inclusion and exclusion.", "framework_count": 1}]	18	pending	\N	\N
4487	NCF0007	IT Decisions and Risk Appetite	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.096423	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Risk Appetite Statement", "frameworks": [{"code": "3.1.5", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "5.2.5", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "A formal statement outlining the organization's risk appetite regarding technology risks.", "framework_count": 2}, {"name": "Records of IT Decisions Against Risk Appetite", "frameworks": [{"code": "3.1.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of IT decisions that have been reviewed in the context of the established risk appetite.", "framework_count": 1}]	18	pending	\N	\N
4488	NCF0008	Risk Mitigation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.100407	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Risk Mitigation Policy and Procedure", "frameworks": [{"code": "03.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedure addressing Risk Mitigation, including scope, applicability, roles, and step-by-step instructions.", "framework_count": 1}]	18	pending	\N	\N
4489	NCF0009	Compliance with Policies, Rules, and Standards for Information Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.105794	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Compliance Review Documentation", "frameworks": [{"code": "A.5.36", "framework": "ISO/IEC 27001:2022"}, {"code": "06.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Schedule and records of compliance reviews, including self-assessments and periodic reviews.", "framework_count": 2}, {"name": "Non-Compliance Management", "frameworks": [{"code": "A.5.36", "framework": "ISO/IEC 27001:2022"}], "description": "Log of non-compliances detected, including root causes, corrective actions, and evidence of actions taken.", "framework_count": 1}, {"name": "Compliance Monitoring Tools", "frameworks": [{"code": "A.5.36", "framework": "ISO/IEC 27001:2022"}], "description": "Dashboard and automated scan results showing compliance status and trends against internal standards.", "framework_count": 1}, {"name": "Compliance Policies and Procedures", "frameworks": [{"code": "06.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policies and documented procedures addressing compliance with security policies and standards.", "framework_count": 1}, {"name": "Awareness and Training Records", "frameworks": [{"code": "06.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications and records demonstrating personnel awareness of compliance requirements.", "framework_count": 1}]	18	pending	\N	\N
4490	NCF0010	Legal and Regulatory Requirements	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.110793	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Legal and Regulatory Requirements Register", "frameworks": [{"code": "GOVERN 1.1", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}, {"code": "A.5.31", "framework": "ISO/IEC 27001:2022"}, {"code": "5", "framework": "SBP Internet Banking Framework"}], "description": "A comprehensive register mapping all applicable laws, regulations, and contractual obligations with requirements mapped to controls, including ownership and review dates.", "framework_count": 3}, {"name": "Compliance Monitoring and Assessment Records", "frameworks": [{"code": "10.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "A.5.31", "framework": "ISO/IEC 27001:2022"}, {"code": "5", "framework": "SBP Internet Banking Framework"}], "description": "Records and reports confirming compliance with legal and regulatory obligations, including assessments and periodic monitoring reports.", "framework_count": 3}, {"name": "Legal Review and Advisory Records", "frameworks": [{"code": "10.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "A.5.31", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of legal reviews and advisory notes from counsel regarding new or changed legal requirements.", "framework_count": 2}, {"name": "Elicited System Requirements and Design Decisions", "frameworks": [{"code": "GOVERN 1.1", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}], "description": "Records of elicited system requirements along with socio-technical design decision documentation, including dates and responsible parties.", "framework_count": 1}, {"name": "Implementation Records and Artifacts", "frameworks": [{"code": "GOVERN 1.1", "framework": "NIST Artificial Intelligence Risk Management Framework (AI RMF 1.0)"}], "description": "Records and artifacts evidencing the implementation of compliance outcomes within the AI lifecycle, including dates and responsible parties.", "framework_count": 1}, {"name": "Regulatory Change Management Log", "frameworks": [{"code": "5", "framework": "SBP Internet Banking Framework"}], "description": "Log of regulatory changes received and the bank's impact assessment, action plan, and closure evidence.", "framework_count": 1}]	18	pending	\N	\N
4492	NCF0012	Managed Service Agreements	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.120283	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Service Level Agreements (SLAs) and Operational Level Agreements (OLAs)", "frameworks": [{"code": "APO09", "framework": "COBIT 2019"}, {"code": "DO.3.5", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented agreements outlining the scope, obligations, and performance metrics for services provided.", "framework_count": 2}, {"name": "Service Level Performance Monitoring Reports", "frameworks": [{"code": "APO09", "framework": "COBIT 2019"}, {"code": "DO.3.5", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Reports that monitor and evaluate the performance against established service level agreements.", "framework_count": 2}, {"name": "Service Agreement Review Records", "frameworks": [{"code": "APO09", "framework": "COBIT 2019"}, {"code": "DO.3.5", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of reviews conducted on service agreements, including improvement actions taken.", "framework_count": 2}]	18	pending	\N	\N
4493	NCF0013	Operations Management Policy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.126708	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Approved Operations Management Policy", "frameworks": [{"code": "OM 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved, current version of the Operations Management Policy including scope, applicability, roles and responsibilities, and control objectives.", "framework_count": 1}, {"name": "Coverage of Management Demand Areas", "frameworks": [{"code": "OM 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of the control across all specified management demand areas, including date, owner, and reference.", "framework_count": 1}, {"name": "Policy Review Records", "frameworks": [{"code": "OM 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating that policy review activity occurred, including date, performer, approver, and reference to relevant controls.", "framework_count": 1}, {"name": "Standard Operating Procedures (SOPs) for IT Operations", "frameworks": [{"code": "DSS01", "framework": "COBIT 2019"}], "description": "Documented standard operating procedures for IT operations.", "framework_count": 1}, {"name": "Operations Monitoring Logs and Infrastructure Event Records", "frameworks": [{"code": "DSS01", "framework": "COBIT 2019"}], "description": "Logs and records related to operations monitoring and infrastructure events.", "framework_count": 1}, {"name": "Facilities and Environmental Management Records", "frameworks": [{"code": "DSS01", "framework": "COBIT 2019"}], "description": "Records related to the management of facilities and environmental controls.", "framework_count": 1}, {"name": "Outsourced Service Management Reports", "frameworks": [{"code": "DSS01", "framework": "COBIT 2019"}], "description": "Reports and compliance evidence related to outsourced service management.", "framework_count": 1}]	18	pending	\N	\N
4494	NCF0014	Implement Key Management for Cryptographic Key Generation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.129709	Cryptography & Key Management	ai_normalized	\N	[{"name": "Key Generation Procedure", "frameworks": [{"code": "3.7.1", "framework": "PCI Data Security Standard"}, {"code": "10.2.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Procedure for generating strong cryptographic keys including approved algorithms, key lengths, and entropy sources.", "framework_count": 2}, {"name": "Key Generation Ceremony Records", "frameworks": [{"code": "3.7.1", "framework": "PCI Data Security Standard"}], "description": "Signed key generation ceremony records (under dual control where applicable) for master/key encrypting keys.", "framework_count": 1}, {"name": "HSM/KMS Key Generation Logs", "frameworks": [{"code": "3.7.1", "framework": "PCI Data Security Standard"}], "description": "HSM / KMS audit logs evidencing key generation with operator and timestamp.", "framework_count": 1}, {"name": "Key Distribution Procedure", "frameworks": [{"code": "3.7.2", "framework": "PCI Data Security Standard"}], "description": "Procedure for secure key distribution covering encrypted distribution, split-knowledge mechanisms, and integrity verification.", "framework_count": 1}, {"name": "Key Distribution Records", "frameworks": [{"code": "3.7.2", "framework": "PCI Data Security Standard"}], "description": "Records of key distribution events with method, recipients, dates, and integrity verification.", "framework_count": 1}, {"name": "Key Wrapping / Transport Configuration", "frameworks": [{"code": "3.7.2", "framework": "PCI Data Security Standard"}], "description": "Configuration of key wrapping / transport mechanisms (KEKs, encrypted key blobs) used during distribution.", "framework_count": 1}, {"name": "Key Storage Procedure", "frameworks": [{"code": "3.7.3", "framework": "PCI Data Security Standard"}], "description": "Procedure for secure key storage including HSM placement, KEK protection, and storage in fewest possible locations.", "framework_count": 1}, {"name": "HSM/KMS Configuration Evidence", "frameworks": [{"code": "3.7.3", "framework": "PCI Data Security Standard"}], "description": "HSM / KMS configuration evidence (FIPS 140-2/3 Level 2 or 3 compliance, tamper response).", "framework_count": 1}, {"name": "Key Storage Access Control", "frameworks": [{"code": "3.7.3", "framework": "PCI Data Security Standard"}], "description": "Access control configuration on key storage limiting administrative access to designated custodians.", "framework_count": 1}, {"name": "Key Retirement / Destruction Procedure", "frameworks": [{"code": "3.7.5", "framework": "PCI Data Security Standard"}], "description": "Procedure for retirement, replacement, or destruction of keys triggered by end of cryptoperiod, integrity weakened, or known/suspected compromise.", "framework_count": 1}, {"name": "Key Destruction Records", "frameworks": [{"code": "3.7.5", "framework": "PCI Data Security Standard"}], "description": "Records of retired/destroyed keys with method (cryptographic erase, HSM zeroize) and witness sign-off.", "framework_count": 1}, {"name": "Retired-Key Archival Evidence", "frameworks": [{"code": "3.7.5", "framework": "PCI Data Security Standard"}], "description": "Archival evidence of retired keys retained only where necessary for decryption of legacy data.", "framework_count": 1}, {"name": "Key Generation Security Controls Verification", "frameworks": [{"code": "10.2.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Verification of security controls related to key generation.", "framework_count": 1}]	18	pending	\N	\N
4495	NCF0015	Management Responsibilities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.136113	Human Resources Security	ai_normalized	\N	[{"name": "Management Responsibilities Policy and Procedures", "frameworks": [{"code": "02.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedures addressing Management Responsibilities, including roles, responsibilities, and implementation steps.", "framework_count": 1}, {"name": "Third-party Agreements and Risk Assessments", "frameworks": [{"code": "02.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Third-party agreements with security clauses and ongoing risk assessment records demonstrating compliance and monitoring.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "02.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of requirements, including attendee lists and delivery details.", "framework_count": 1}, {"name": "AI Roles and Responsibilities Documentation", "frameworks": [{"code": "A.3.2", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Charter and communications defining AI roles, responsibilities, and accountability across various functions.", "framework_count": 1}]	18	pending	\N	\N
4497	NCF0017	Sensitive System Isolation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.147516	Network Security	ai_normalized	\N	[{"name": "Sensitive System Isolation Policy and Procedure", "frameworks": [{"code": "01.w", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedure addressing Sensitive System Isolation, including implementation details and periodic review records.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.w", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements, including attendee lists and delivery details.", "framework_count": 1}, {"name": "Sensitive System Inventory", "frameworks": [{"code": "AC 7.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of sensitive systems containing details such as entity name, owner, classification, and review status.", "framework_count": 1}, {"name": "Network Segregation Documentation", "frameworks": [{"code": "AC 7.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation demonstrating the segregation of networks/environments for sensitive systems, including implementation details.", "framework_count": 1}, {"name": "Dedicated Infrastructure Evidence", "frameworks": [{"code": "AC 7.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of dedicated infrastructure for sensitive systems, including implementation details and references to related policies.", "framework_count": 1}]	18	pending	\N	\N
4498	NCF0018	Security of Network Services	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.151517	Network Security	ai_normalized	\N	[{"name": "Network Service Agreements", "frameworks": [{"code": "13.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "CM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Contracts and agreements that outline security requirements and service levels for network services.", "framework_count": 2}, {"name": "Service Level Agreements", "frameworks": [{"code": "13.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "CM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documents defining service level expectations and metrics for network services.", "framework_count": 2}, {"name": "Security Feature Documentation", "frameworks": [{"code": "13.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "09.n", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation detailing the security features implemented for network services.", "framework_count": 2}, {"name": "Documented Procedures for Network Security", "frameworks": [{"code": "09.n", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step instructions and responsibilities for implementing network security measures.", "framework_count": 1}, {"name": "Network Architecture Diagram", "frameworks": [{"code": "09.n", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Diagram illustrating the network's segmentation, firewalls, and trust zones.", "framework_count": 1}, {"name": "Network Device Configuration Records", "frameworks": [{"code": "09.n", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of configuration baselines and ruleset reviews for network devices.", "framework_count": 1}, {"name": "Third-Party Agreements with Security Clauses", "frameworks": [{"code": "09.n", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Agreements with third parties that include security clauses, SLAs, and audit rights.", "framework_count": 1}, {"name": "Third-Party Risk Assessment Records", "frameworks": [{"code": "09.n", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating the assessment and ongoing monitoring of third-party risks.", "framework_count": 1}, {"name": "Service Provider Compliance Reports", "frameworks": [{"code": "CM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports detailing compliance of service providers with security requirements.", "framework_count": 1}, {"name": "Deviation Reports to Authorities", "frameworks": [{"code": "CM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports submitted to authorities detailing deviations from expected security practices.", "framework_count": 1}]	18	pending	\N	\N
4500	NCF0020	Return of Assets	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.162673	Access Control & Identity Management	ai_normalized	\N	[{"name": "Asset Recovery Documentation", "frameworks": [{"code": "HR 4.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "5.8", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Comprehensive documentation related to the recovery of assets, including checklists, clearance forms, and acknowledgements from departing personnel.", "framework_count": 2}]	18	pending	\N	\N
4501	NCF0021	Document and Content Access Approval	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.165753	Access Control & Identity Management	ai_normalized	\N	[{"name": "Document and Content Access Approval Policy", "frameworks": [{"code": "DCM.4.3", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Approved policy/standard covering Document and Content Access Approval with version history and management sign-off.", "framework_count": 1}, {"name": "Documented Procedures for Access Approval", "frameworks": [{"code": "DCM.4.3", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented procedures and process workflows implementing Document and Content Access Approval, including step-by-step instructions.", "framework_count": 1}, {"name": "Organizational Artifacts for Access Approval", "frameworks": [{"code": "DCM.4.3", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Organizational artifacts such as role mandates, RACI, job descriptions, and committee charters that identify owners and responsibilities.", "framework_count": 1}, {"name": "Formal Approval Records", "frameworks": [{"code": "DCM.4.3", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of formal approvals and socialization activities, including committee minutes and sign-offs.", "framework_count": 1}, {"name": "Access Request and Approval Workflow", "frameworks": [{"code": "8.10.3.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Workflow detailing the process for access requests and approvals.", "framework_count": 1}, {"name": "Approver Matrix", "frameworks": [{"code": "8.10.3.2", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Matrix identifying approvers for access requests.", "framework_count": 1}]	18	pending	\N	\N
4502	NCF0022	Use of System Utilities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.170677	Access Control & Identity Management	ai_normalized	\N	[{"name": "Utility Access Policy and Configuration", "frameworks": [{"code": "11.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "AC 6.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented policy and configuration settings governing access to utilities, including restrictions and authorized lists.", "framework_count": 2}, {"name": "Utility Usage Logs", "frameworks": [{"code": "11.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "AC 6.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs detailing the usage of utilities, including monitoring and authorization records.", "framework_count": 2}]	18	pending	\N	\N
4503	NCF0023	Authorization Process	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.177101	Access Control & Identity Management	ai_normalized	\N	[{"name": "Authorization Process Documentation", "frameworks": [{"code": "PM-10", "framework": "NIST SP 800-53 Rev 5"}, {"code": "§164.308(a)(3)(ii)(A)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Documentation outlining the authorization process, including procedures and approvals.", "framework_count": 2}, {"name": "Authorization to Operate (ATO) Documentation", "frameworks": [{"code": "PM-10", "framework": "NIST SP 800-53 Rev 5"}, {"code": "CA-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records related to the Authorization to Operate, including tracking and decision documentation.", "framework_count": 2}, {"name": "Risk-Based Decision Documentation", "frameworks": [{"code": "PM-10", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation that outlines risk-based decisions made during the authorization process.", "framework_count": 1}, {"name": "Authorizing Official Designation", "frameworks": [{"code": "CA-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records that designate the official responsible for authorizing the system.", "framework_count": 1}]	18	pending	\N	\N
4504	NCF0024	User Access Provisioning	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.181519	Access Control & Identity Management	ai_normalized	\N	[{"name": "Access Request and Approval Records", "frameworks": [{"code": "APD-02", "framework": "SOX IT General Controls"}, {"code": "CC6.2", "framework": "SOC 2 Type II"}, {"code": "9.1.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of access request forms with approvals and related records.", "framework_count": 3}, {"name": "User Provisioning Workflow Documentation", "frameworks": [{"code": "APD-02", "framework": "SOX IT General Controls"}, {"code": "9.1.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation outlining the process for user provisioning.", "framework_count": 2}, {"name": "Role-Based Access Matrix", "frameworks": [{"code": "APD-02", "framework": "SOX IT General Controls"}], "description": "Matrix defining roles and associated access levels.", "framework_count": 1}, {"name": "Access Modification Request Forms", "frameworks": [{"code": "APD-03", "framework": "SOX IT General Controls"}], "description": "Forms used to request modifications to user access.", "framework_count": 1}, {"name": "Manager Approval Documentation", "frameworks": [{"code": "APD-03", "framework": "SOX IT General Controls"}], "description": "Records of manager approvals for access modifications.", "framework_count": 1}, {"name": "Before/After Access Comparison", "frameworks": [{"code": "APD-03", "framework": "SOX IT General Controls"}], "description": "Comparison documentation showing access changes before and after modifications.", "framework_count": 1}, {"name": "HR Transfer Notification Process", "frameworks": [{"code": "APD-03", "framework": "SOX IT General Controls"}], "description": "Process documentation for notifying HR of user transfers affecting access.", "framework_count": 1}, {"name": "User Access De-Provisioning Procedures", "frameworks": [{"code": "CC6.2", "framework": "SOC 2 Type II"}], "description": "Procedures and evidence for user access de-provisioning and termination.", "framework_count": 1}, {"name": "Periodic User Access Reviews", "frameworks": [{"code": "CC6.2", "framework": "SOC 2 Type II"}], "description": "Records of periodic reviews of user access, conducted at least quarterly.", "framework_count": 1}, {"name": "Privileged Access Management Procedures", "frameworks": [{"code": "CC6.2", "framework": "SOC 2 Type II"}], "description": "Procedures governing the management of privileged access.", "framework_count": 1}]	18	pending	\N	\N
4505	NCF0025	User Identification and Authentication	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.186521	Access Control & Identity Management	ai_normalized	\N	[{"name": "User Authentication Management Documentation", "frameworks": [{"code": "9.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "8.1.1", "framework": "PCI Data Security Standard"}], "description": "Comprehensive documentation covering user ID management procedures, authentication standards, and configuration.", "framework_count": 2}, {"name": "Account Lifecycle Management Records", "frameworks": [{"code": "9.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "8.1.1", "framework": "PCI Data Security Standard"}], "description": "Records detailing the lifecycle of user accounts, including creation, modification, and deletion.", "framework_count": 2}, {"name": "Authentication Roles and Responsibilities", "frameworks": [{"code": "8.1.2", "framework": "PCI Data Security Standard"}], "description": "Documented roles, responsibilities, and acknowledgment records related to authentication management.", "framework_count": 1}, {"name": "Policy Review and Distribution Evidence", "frameworks": [{"code": "8.1.1", "framework": "PCI Data Security Standard"}], "description": "Records of annual reviews and dissemination of authentication policies.", "framework_count": 1}]	18	pending	\N	\N
4506	NCF0026	Centralize Account Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.192898	Access Control & Identity Management	ai_normalized	\N	[{"name": "Identity Management Documentation", "frameworks": [{"code": "CIS Control 5 - Safeguard 5.6", "framework": "CIS Critical Security Controls v8"}, {"code": "AC-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation related to centralized identity management and account management procedures.", "framework_count": 2}, {"name": "Account Review Documentation", "frameworks": [{"code": "CIS Control 5 - Safeguard 5.6", "framework": "CIS Critical Security Controls v8"}, {"code": "AC-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation related to account reviews and integration coverage.", "framework_count": 2}, {"name": "User Access Records", "frameworks": [{"code": "AC-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records related to user access authorization and terminated user accounts.", "framework_count": 1}, {"name": "Directory Service Configuration", "frameworks": [{"code": "CIS Control 5 - Safeguard 5.6", "framework": "CIS Critical Security Controls v8"}], "description": "Configuration details of the directory service used for identity management.", "framework_count": 1}]	18	pending	\N	\N
4507	NCF0027	System and Service Account Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.196898	Access Control & Identity Management	ai_normalized	\N	[{"name": "Service Account Inventory", "frameworks": [{"code": "9.2.2", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "APD-09", "framework": "SOX IT General Controls"}], "description": "Comprehensive inventory of service accounts including ownership details.", "framework_count": 2}, {"name": "Service Account Monitoring and Review", "frameworks": [{"code": "9.2.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records of monitoring and reviewing service accounts for compliance.", "framework_count": 1}, {"name": "Password Management Procedures for Service Accounts", "frameworks": [{"code": "APD-09", "framework": "SOX IT General Controls"}], "description": "Documented procedures for managing passwords of service accounts.", "framework_count": 1}, {"name": "Interactive Login Restriction Evidence", "frameworks": [{"code": "APD-09", "framework": "SOX IT General Controls"}], "description": "Evidence demonstrating restrictions on interactive logins for service accounts.", "framework_count": 1}, {"name": "Compensating Controls Documentation for Shared Accounts", "frameworks": [{"code": "APD-09", "framework": "SOX IT General Controls"}], "description": "Documentation outlining compensating controls for shared accounts.", "framework_count": 1}]	18	pending	\N	\N
4509	NCF0029	Public Access, Delivery and Loading Areas	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.205294	Physical & Environmental Security	ai_normalized	\N	[{"name": "Public Access and Delivery Area Procedures", "frameworks": [{"code": "8.6", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "08.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedures addressing Public Access, Delivery, and Loading Areas, including isolation control documentation.", "framework_count": 2}]	18	pending	\N	\N
4510	NCF0030	Equipment Maintenance	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.209293	Physical & Environmental Security	ai_normalized	\N	[{"name": "Maintenance Documentation", "frameworks": [{"code": "6.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "PE 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive documentation related to maintenance schedules, agreements, records, and service reports.", "framework_count": 2}, {"name": "Commissioning and Maintenance Procedures", "frameworks": [{"code": "PE 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Detailed procedures for commissioning, maintenance, and decommissioning, including roles and responsibilities.", "framework_count": 1}]	18	pending	\N	\N
4511	NCF0031	Physical and Environmental Security Policy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.225037	Physical & Environmental Security	ai_normalized	\N	[{"name": "Approved Physical and Environmental Security Policy", "frameworks": [{"code": "4.3.10.7", "framework": "DOH Policy on the Abu Dhabi Health Information Exchange (ADHIE)"}, {"code": "PE 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved, current version of the physical and environmental security policy, including scope, applicability, roles, and responsibilities.", "framework_count": 2}, {"name": "Data Center Access Control Records", "frameworks": [{"code": "4.3.10.7", "framework": "DOH Policy on the Abu Dhabi Health Information Exchange (ADHIE)"}, {"code": "PE 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating data center access activities, including date, performer, approver where applicable, and reference to the relevant control.", "framework_count": 2}, {"name": "Sensitive Systems Physical Isolation Evidence", "frameworks": [{"code": "4.3.10.7", "framework": "DOH Policy on the Abu Dhabi Health Information Exchange (ADHIE)"}], "description": "Supporting artifact demonstrating the implementation of sensitive systems physical isolation controls, with date, owner, and reference to related policies.", "framework_count": 1}, {"name": "Tamper and Theft Prevention Controls Evidence", "frameworks": [{"code": "4.3.10.7", "framework": "DOH Policy on the Abu Dhabi Health Information Exchange (ADHIE)"}], "description": "Supporting artifact demonstrating the implementation of tamper and theft prevention controls (CCTV, locks, badges), with date, owner, and reference to related policies.", "framework_count": 1}, {"name": "Roles and Responsibilities Matrix", "frameworks": [{"code": "PE 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Matrix clearly identifying owners, responsibilities, coverage of all relevant items, and conflicts of interest where applicable.", "framework_count": 1}, {"name": "User Acknowledgement Records", "frameworks": [{"code": "PE 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating user acknowledgment of policies and procedures, including date, performer, approver where applicable, and reference to relevant controls.", "framework_count": 1}, {"name": "Top Management Approval Evidence", "frameworks": [{"code": "PE 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating top management approval of policies or procedures, with date, owner, and reference to related documents.", "framework_count": 1}, {"name": "Manufacturer Environmental Recommendation Compliance Records", "frameworks": [{"code": "PE 1.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating compliance with manufacturer environmental recommendations, including date, performer, and approver where applicable.", "framework_count": 1}, {"name": "Equipment/Medical Device Placement Plans", "frameworks": [{"code": "PE 1.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Plans covering scope, objectives, roles, activation criteria, stakeholder responsibilities, and communication paths for equipment/medical device placement.", "framework_count": 1}, {"name": "Physical Access Controls for Equipment Evidence", "frameworks": [{"code": "PE 1.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating the implementation of physical access controls for equipment, with date, owner, and reference to related policies.", "framework_count": 1}, {"name": "Data Protection Procedures During Maintenance/Off-Site Movement", "frameworks": [{"code": "PE 1.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Procedures including step-by-step instructions, responsible roles, control points, and exception handling for data protection during maintenance or off-site movement.", "framework_count": 1}]	18	pending	\N	\N
4519	NCF0039	Publicly Available Information	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.264528	Data Protection & Privacy	ai_normalized	\N	[{"name": "Approved Policy on Publicly Available Information", "frameworks": [{"code": "09.z", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "CM 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved policy and standard addressing Publicly Available Information, including scope, applicability, and roles.", "framework_count": 2}, {"name": "Documented Procedure for Publicly Available Information", "frameworks": [{"code": "09.z", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure or work instruction implementing Publicly Available Information, including responsible roles and control points.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "09.z", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Access control matrix with role-to-permission mapping for relevant systems, clearly identifying owners and responsibilities.", "framework_count": 1}, {"name": "User Access Records", "frameworks": [{"code": "09.z", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of user access provisioning, modification, and review demonstrating the activity occurred, including date, performer, and approver.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.z", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements, including attendee list, delivery dates, and content references.", "framework_count": 1}, {"name": "Publication and Approval Workflow", "frameworks": [{"code": "CM 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating the publication and approval workflow implementation, with date, owner, and reference to related policy.", "framework_count": 1}, {"name": "Content Sanitization Records", "frameworks": [{"code": "CM 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating content sanitization activities occurred, including date, performer, approver, and reference to relevant policies.", "framework_count": 1}, {"name": "Public System Integrity Monitoring", "frameworks": [{"code": "CM 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of public system integrity monitoring controls, with date, owner, and reference to related policies.", "framework_count": 1}]	18	pending	\N	\N
4512	NCF0032	Right of Access by the Data Subject	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.229005	Data Protection & Privacy	ai_normalized	\N	[{"name": "Subject Access Request Procedures", "frameworks": [{"code": "Article 15", "framework": "General Data Protection Regulation"}, {"code": "P5.1", "framework": "SOC 2 Type II"}], "description": "Documented procedures for handling subject access requests in compliance with GDPR and SOC 2 standards.", "framework_count": 2}, {"name": "Response Templates", "frameworks": [{"code": "Article 15", "framework": "General Data Protection Regulation"}], "description": "Templates used for responding to subject access requests, ensuring consistency and compliance.", "framework_count": 1}, {"name": "Fulfilment Records", "frameworks": [{"code": "Article 15", "framework": "General Data Protection Regulation"}], "description": "Records of completed subject access requests to demonstrate compliance and tracking.", "framework_count": 1}, {"name": "Identity Verification Process", "frameworks": [{"code": "P5.1", "framework": "SOC 2 Type II"}], "description": "Process for verifying the identity of data subjects making access requests.", "framework_count": 1}, {"name": "DSAR Tracking and Response Metrics", "frameworks": [{"code": "P5.1", "framework": "SOC 2 Type II"}], "description": "Metrics used to track the status and response times of data subject access requests.", "framework_count": 1}, {"name": "Sample DSAR Responses", "frameworks": [{"code": "P5.1", "framework": "SOC 2 Type II"}], "description": "Examples of completed subject access request responses to demonstrate compliance and thoroughness.", "framework_count": 1}]	18	pending	\N	\N
4513	NCF0033	Choice and Consent	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.2324	Data Protection & Privacy	ai_normalized	\N	[{"name": "Consent Management Documentation", "frameworks": [{"code": "P2.1", "framework": "SOC 2 Type II"}, {"code": "PT-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of consent management platform, including mechanisms for consent collection and revocation.", "framework_count": 2}, {"name": "Documented Consent Procedures", "frameworks": [{"code": "13.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "13.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedures or work instructions for implementing consent management.", "framework_count": 2}, {"name": "Privacy Notice/Statement", "frameworks": [{"code": "13.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "13.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Published privacy notice or statement provided to data subjects, including version history.", "framework_count": 2}, {"name": "Consent Records and Logs", "frameworks": [{"code": "13.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "13.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of consent, opt-out tracking, and data subject requests, preserved and protected.", "framework_count": 2}, {"name": "Awareness Communications", "frameworks": [{"code": "13.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "13.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of consent requirements.", "framework_count": 2}, {"name": "Periodic Review Records", "frameworks": [{"code": "13.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "13.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer details, observations, and corrective actions.", "framework_count": 2}, {"name": "Approved Consent Policy", "frameworks": [{"code": "13.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy addressing consent, including scope, applicability, and responsibilities.", "framework_count": 1}]	18	pending	\N	\N
4514	NCF0034	Privacy Notice	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.240397	Data Protection & Privacy	ai_normalized	\N	[{"name": "Approved Privacy Notice Policy", "frameworks": [{"code": "13.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "PT-5", "framework": "NIST SP 800-53 Rev 5"}, {"code": "PDP.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Board/management-approved policy and standard addressing Privacy Notice, including scope, applicability, roles, and responsibilities.", "framework_count": 3}, {"name": "Documented Procedures for Privacy Notice", "frameworks": [{"code": "13.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "PDP.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented procedures and work instructions implementing Privacy Notice, including step-by-step instructions and responsible roles.", "framework_count": 2}, {"name": "Published Privacy Notice", "frameworks": [{"code": "13.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "PT-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Privacy notice/statement published to data subjects with version history, demonstrating implementation with date and owner.", "framework_count": 2}, {"name": "Periodic Review Records", "frameworks": [{"code": "13.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "PDP.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of periodic reviews with reviewer, date, observations, and corrective actions demonstrating that the activity occurred.", "framework_count": 2}, {"name": "Consent and Data Subject Records", "frameworks": [{"code": "13.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of consent, opt-out tracking, and data subject requests, preserved for the required retention period and protected from tampering.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "13.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the Privacy Notice requirement, including attendee list and delivery dates.", "framework_count": 1}, {"name": "Organizational Artifacts", "frameworks": [{"code": "PDP.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Artifacts such as role mandates, RACI, job descriptions, and committee charters that clearly identify owners and responsibilities.", "framework_count": 1}, {"name": "Data Lifecycle Records", "frameworks": [{"code": "PDP.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records covering data retention schedules, archival, and secure disposal, demonstrating the activity occurred.", "framework_count": 1}]	18	pending	\N	\N
4516	NCF0036	Integrity and Confidentiality	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.248865	Data Protection & Privacy	ai_normalized	\N	[{"name": "Security Measures Documentation", "frameworks": [{"code": "Article 5(1)(f)", "framework": "General Data Protection Regulation"}], "description": "Documentation of security measures including access controls and encryption implementations.", "framework_count": 1}, {"name": "Transmission Integrity Controls Documentation", "frameworks": [{"code": "§164.312(e)(2)(i)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Documentation of controls ensuring the integrity of transmitted data, including message authentication and TLS configuration.", "framework_count": 1}]	18	pending	\N	\N
4517	NCF0037	Protection of Records	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.252426	Data Protection & Privacy	ai_normalized	\N	[{"name": "Records Management Policy and Procedures", "frameworks": [{"code": "A.5.33", "framework": "ISO/IEC 27001:2022"}, {"code": "06.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive policy and documented procedures addressing the creation, storage, protection, retention, and disposal of organizational records.", "framework_count": 2}, {"name": "Records Retention Schedule", "frameworks": [{"code": "A.5.33", "framework": "ISO/IEC 27001:2022"}, {"code": "06.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Schedule listing record types, retention periods, legal basis, and disposal methods.", "framework_count": 2}, {"name": "Records Protection Controls Documentation", "frameworks": [{"code": "A.5.33", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation detailing storage, encryption, and access controls for protected records.", "framework_count": 1}, {"name": "Records Destruction Log", "frameworks": [{"code": "A.5.33", "framework": "ISO/IEC 27001:2022"}], "description": "Log of records destroyed at the end of retention, including method and witness.", "framework_count": 1}, {"name": "Archive Access Logs", "frameworks": [{"code": "A.5.33", "framework": "ISO/IEC 27001:2022"}], "description": "Logs of access to archived records for audit traceability.", "framework_count": 1}, {"name": "Retention Automation Configuration", "frameworks": [{"code": "A.5.33", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration of retention policies in electronic content management systems or email.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "06.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of records protection requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "06.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4518	NCF0038	Input Data Validation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.258972	Data Protection & Privacy	ai_normalized	\N	[{"name": "Input Validation Configuration and Documentation", "frameworks": [{"code": "EUC-04", "framework": "SOX IT General Controls"}, {"code": "SA 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "SI-10", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation and configuration records for input validation rules and criteria, including evidence of implementation.", "framework_count": 3}, {"name": "Input Validation Procedures and Testing", "frameworks": [{"code": "10.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "SI-10", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documented procedures and testing results for input validation, including methodologies and outcomes.", "framework_count": 3}, {"name": "Source Data Reconciliation Evidence", "frameworks": [{"code": "EUC-04", "framework": "SOX IT General Controls"}], "description": "Evidence of reconciliation between source data and processed data.", "framework_count": 1}, {"name": "Data Feed Documentation and Verification", "frameworks": [{"code": "EUC-04", "framework": "SOX IT General Controls"}], "description": "Documentation and verification records for data feeds used in input validation.", "framework_count": 1}, {"name": "Secure SDLC Documentation", "frameworks": [{"code": "10.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of secure software development lifecycle processes with security checkpoints.", "framework_count": 1}, {"name": "Code Review and Security Testing Records", "frameworks": [{"code": "10.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of code reviews and security testing results demonstrating compliance with input validation controls.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of input validation requirements.", "framework_count": 1}, {"name": "Application Code/Configuration for Input Validation", "frameworks": [{"code": "SA 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Extracts or screenshots of application code or configuration demonstrating input validation controls.", "framework_count": 1}]	18	pending	\N	\N
4521	NCF0041	Message Integrity	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.274718	Data Protection & Privacy	ai_normalized	\N	[{"name": "Message Integrity Policy and Standards", "frameworks": [{"code": "10.d", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Approved policy and standard addressing Message Integrity, including scope, applicability, roles, and responsibilities.", "framework_count": 2}, {"name": "Message Integrity Implementation Procedures", "frameworks": [{"code": "10.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Message Integrity with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the Message Integrity requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews demonstrating the activity occurred, including date, performer, observations, and corrective actions.", "framework_count": 1}, {"name": "Digital Signature/HMAC Configuration Evidence", "frameworks": [{"code": "SA 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of digital signature or HMAC configuration showing the control is in effect, including date and system identification.", "framework_count": 1}, {"name": "Message Integrity Verification Logs", "frameworks": [{"code": "SA 3.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of message integrity verification preserved for the required retention period, protected from tampering, with timestamps and actor identity.", "framework_count": 1}]	18	pending	\N	\N
4522	NCF0042	Output Data Validation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.278718	Data Protection & Privacy	ai_normalized	\N	[{"name": "Output Data Validation Policy and Procedures", "frameworks": [{"code": "10.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Approved policy and documented procedures addressing Output Data Validation, including scope, roles, and responsibilities.", "framework_count": 2}, {"name": "Secure SDLC Documentation", "frameworks": [{"code": "10.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of the Secure Software Development Life Cycle (SDLC) with security checkpoints, including design, code review, and testing.", "framework_count": 1}, {"name": "Code Review and Security Testing Records", "frameworks": [{"code": "10.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of code reviews and security testing results demonstrating that activities occurred, including dates and responsible parties.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of Output Data Validation requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Application Output Validation Configuration", "frameworks": [{"code": "SA 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation or screenshots of application output validation configurations showing the control is in effect.", "framework_count": 1}, {"name": "Output Testing Records", "frameworks": [{"code": "SA 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating that output testing activities occurred, including dates and responsible parties.", "framework_count": 1}]	18	pending	\N	\N
4523	NCF0043	Data Protection and Privacy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.283105	Data Protection & Privacy	ai_normalized	\N	[{"name": "Data Loss Prevention Documentation", "frameworks": [{"code": "Article 21(2)(h)", "framework": "NIS2 Directive"}, {"code": "06.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of Data Loss Prevention (DLP) deployment, including policies and event records.", "framework_count": 2}, {"name": "Data Protection and Privacy Policy", "frameworks": [{"code": "06.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Data Protection and Privacy of Covered Information, including scope and current version.", "framework_count": 1}, {"name": "Data Protection Procedures", "frameworks": [{"code": "06.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Data Protection and Privacy of Covered Information, including step-by-step instructions.", "framework_count": 1}, {"name": "Privacy Notice/Statement", "frameworks": [{"code": "06.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Published privacy notice/statement to data subjects with version history, demonstrating implementation of the control.", "framework_count": 1}, {"name": "Consent and Data Subject Records", "frameworks": [{"code": "06.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of consent, opt-out tracking, and data subject requests, preserved for the required retention period.", "framework_count": 1}, {"name": "Executed Security Agreements", "frameworks": [{"code": "06.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Executed agreements with required security clauses and signature records, demonstrating the activity occurred.", "framework_count": 1}]	18	pending	\N	\N
4524	NCF0044	Privacy and Impact Assessment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.288022	Data Protection & Privacy	ai_normalized	\N	[{"name": "Approved Privacy and Impact Assessment Policy", "frameworks": [{"code": "13.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Privacy and Impact Assessment, including scope, criteria, methodology, findings, risk ratings, and recommendations.", "framework_count": 1}, {"name": "Documented Procedure for Privacy and Impact Assessment", "frameworks": [{"code": "13.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing Privacy and Impact Assessment, detailing scope, criteria, methodology, findings, and risk ratings.", "framework_count": 1}, {"name": "Published Privacy Notice/Statement", "frameworks": [{"code": "13.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Privacy notice/statement published to data subjects with version history, demonstrating implementation of the control.", "framework_count": 1}, {"name": "Consent and Data Subject Request Records", "frameworks": [{"code": "13.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of consent, opt-out tracking, and data subject requests, preserved for the required retention period and protected from tampering.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "13.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements, including attendee list, delivery dates, and content references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "13.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions demonstrating that the activity occurred.", "framework_count": 1}, {"name": "DPIA Methodology", "frameworks": [{"code": "Article 35", "framework": "General Data Protection Regulation"}], "description": "Documented methodology for conducting Data Protection Impact Assessments (DPIAs).", "framework_count": 1}, {"name": "Completed DPIAs", "frameworks": [{"code": "Article 35", "framework": "General Data Protection Regulation"}], "description": "Records of completed Data Protection Impact Assessments (DPIAs) demonstrating compliance with privacy requirements.", "framework_count": 1}, {"name": "Risk Mitigation Measures", "frameworks": [{"code": "Article 35", "framework": "General Data Protection Regulation"}], "description": "Documented risk mitigation measures identified and implemented as a result of DPIAs.", "framework_count": 1}]	18	pending	\N	\N
4525	NCF0045	Information Transfer	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.293431	Data Protection & Privacy	ai_normalized	\N	[{"name": "Data Transfer Agreement Templates", "frameworks": [{"code": "A.5.14", "framework": "ISO/IEC 27001:2022"}, {"code": "CM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Standard templates for transfer agreements and information exchange agreements with security clauses.", "framework_count": 2}, {"name": "Information Transfer Policy and Procedures", "frameworks": [{"code": "A.5.14", "framework": "ISO/IEC 27001:2022"}], "description": "Policy and procedures defining authorized transfer methods, encryption requirements, and specific secure transfer methods.", "framework_count": 1}, {"name": "Signed Information Exchange Agreements and NDAs", "frameworks": [{"code": "CM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Signed agreements and NDAs with external parties including security clauses and confidentiality obligations.", "framework_count": 1}, {"name": "Agreement Registers", "frameworks": [{"code": "CM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Registers containing details of agreements including renewal dates and traceability.", "framework_count": 1}, {"name": "Right-to-Audit Clauses", "frameworks": [{"code": "CM 2.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Clauses in agreements detailing audit scope, methodology, and remediation tracking.", "framework_count": 1}, {"name": "Interface Documentation and Logs", "frameworks": [{"code": "CO-07", "framework": "SOX IT General Controls"}], "description": "Documentation and logs related to interface inventory, monitoring, and reconciliation of transferred data.", "framework_count": 1}, {"name": "Transfer Logs and Encryption Configurations", "frameworks": [{"code": "A.5.14", "framework": "ISO/IEC 27001:2022"}], "description": "Logs from managed file transfer platforms and configurations for email encryption enforcing secure transfers.", "framework_count": 1}, {"name": "Courier Chain-of-Custody Receipts", "frameworks": [{"code": "A.5.14", "framework": "ISO/IEC 27001:2022"}], "description": "Signed receipts for physical media transfers via approved couriers.", "framework_count": 1}]	18	pending	\N	\N
4527	NCF0047	Information Sharing Arrangements	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.348545	Data Protection & Privacy	ai_normalized	\N	[{"name": "Information Sharing Agreements and Documentation", "frameworks": [{"code": "Article 45(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Documentation of information sharing agreements, trusted community memberships, and data protection measures for shared information.", "framework_count": 1}, {"name": "Documented Data Sharing Process", "frameworks": [{"code": "DSI.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "A documented process demonstrating compliance with data sharing specifications, including step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Organizational Artifacts", "frameworks": [{"code": "DSI.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Artifacts that include role mandates, RACI, job descriptions, and committee charters clearly identifying owners and responsibilities.", "framework_count": 1}, {"name": "Compliance Audit Reports", "frameworks": [{"code": "DSI.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Reports and records of compliance audits and assessments with findings and remediation tracking.", "framework_count": 1}, {"name": "Data Classification Scheme", "frameworks": [{"code": "DSI.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "A data classification scheme and labeled dataset register that includes item names, owners, classifications, and review dates.", "framework_count": 1}, {"name": "Data Architecture Artifacts", "frameworks": [{"code": "DSI.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Current, version-controlled data architecture artifacts including data models, ERDs, and design documentation traceable to relevant datasets.", "framework_count": 1}]	18	pending	\N	\N
4541	NCF0061	Business Continuity and Risk Assessment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.409679	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Business Impact Analysis and Recovery Objectives", "frameworks": [{"code": "14.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation of business impact analysis and recovery time objectives.", "framework_count": 1}, {"name": "Business Continuity and Risk Assessment Policy", "frameworks": [{"code": "12.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Business Continuity and Risk Assessment, including scope, criteria, methodology, findings, and risk ratings.", "framework_count": 1}, {"name": "Business Continuity and Risk Assessment Procedures", "frameworks": [{"code": "12.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Business Continuity and Risk Assessment.", "framework_count": 1}, {"name": "Risk Register", "frameworks": [{"code": "12.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive risk register with entries, owners, ratings, and treatment plans.", "framework_count": 1}, {"name": "Risk Assessment Methodology Documentation", "frameworks": [{"code": "12.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation and approval records for the risk assessment methodology.", "framework_count": 1}, {"name": "Business Continuity Plan", "frameworks": [{"code": "12.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Business Continuity Plan with RTO/RPO targets and recovery procedures.", "framework_count": 1}, {"name": "BCP Test Exercise Records", "frameworks": [{"code": "12.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of BCP test exercises and post-test review documentation.", "framework_count": 1}]	18	pending	\N	\N
4528	NCF0048	Media Handling	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.352784	Data Protection & Privacy	ai_normalized	\N	[{"name": "Media Handling and Disposal Procedures", "frameworks": [{"code": "11.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "2.3", "framework": "SABIC CyberTrust Guidelines"}], "description": "Documented procedures for handling and disposing of media, including tracking and disposal records.", "framework_count": 2}, {"name": "Documented Information Handling Procedures", "frameworks": [{"code": "AM 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedures for handling information by classification level, including roles and control points.", "framework_count": 2}, {"name": "Access Control and User Management Records", "frameworks": [{"code": "09.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating user access provisioning, modification, and review, along with an access control matrix.", "framework_count": 1}, {"name": "Handling Procedure Training Records", "frameworks": [{"code": "AM 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating training on handling procedures, including dates and responsible parties.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications that inform personnel of handling requirements, including attendee lists and delivery dates.", "framework_count": 1}]	18	pending	\N	\N
4529	NCF0049	Confidentiality Agreements	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.359595	Data Protection & Privacy	ai_normalized	\N	[{"name": "Confidentiality Agreements Policy and Procedures", "frameworks": [{"code": "05.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedures addressing Confidentiality Agreements, including security clauses and obligations.", "framework_count": 1}, {"name": "Executed Confidentiality Agreements", "frameworks": [{"code": "05.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Executed agreements with required security clauses and signature records demonstrating compliance.", "framework_count": 1}, {"name": "Awareness Communications on Confidentiality Agreements", "frameworks": [{"code": "05.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements regarding Confidentiality Agreements.", "framework_count": 1}, {"name": "Periodic Review Records for Confidentiality Agreements", "frameworks": [{"code": "05.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer details, observations, and corrective actions related to Confidentiality Agreements.", "framework_count": 1}, {"name": "NDA Master Template", "frameworks": [{"code": "A.6.6", "framework": "ISO/IEC 27001:2022"}], "description": "Standard NDA template covering duration, scope, and breach consequences.", "framework_count": 1}, {"name": "Signed Employee NDAs Repository", "frameworks": [{"code": "A.6.6", "framework": "ISO/IEC 27001:2022"}], "description": "Repository of signed NDAs from all personnel to ensure compliance.", "framework_count": 1}, {"name": "Third-Party NDA Register", "frameworks": [{"code": "A.6.6", "framework": "ISO/IEC 27001:2022"}], "description": "Register of NDAs signed with contractors, consultants, and business partners.", "framework_count": 1}, {"name": "NDA Legal Review Record", "frameworks": [{"code": "A.6.6", "framework": "ISO/IEC 27001:2022"}], "description": "Annual legal review confirming NDA templates remain enforceable and compliant.", "framework_count": 1}, {"name": "NDA Renewal/Reissue Log", "frameworks": [{"code": "A.6.6", "framework": "ISO/IEC 27001:2022"}], "description": "Log showing NDAs that have been renewed or reissued as scopes or terms change.", "framework_count": 1}, {"name": "NDA Variant Library", "frameworks": [{"code": "A.6.6", "framework": "ISO/IEC 27001:2022"}], "description": "Collection of NDA variants for specific contexts such as mutual, one-way, or project-specific agreements.", "framework_count": 1}]	18	pending	\N	\N
4530	NCF0050	Protection of System Test Data	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.36321	Data Protection & Privacy	ai_normalized	\N	[{"name": "Test Data Management Policy", "frameworks": [{"code": "13.9", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "10.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "A documented policy addressing the management and protection of test data, including data masking and access controls.", "framework_count": 2}, {"name": "Test Data Procedures", "frameworks": [{"code": "10.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions for implementing protection measures for test data, including step-by-step instructions.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications that inform personnel about the requirements for test data protection.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating periodic reviews of test data protection measures, including observations and corrective actions.", "framework_count": 1}, {"name": "Sample Test Data Sets", "frameworks": [{"code": "SA 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of test data protection controls, including ownership and references.", "framework_count": 1}, {"name": "Production Data Usage Authorization Records", "frameworks": [{"code": "SA 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records authorizing the use of production data, demonstrating compliance with protection measures.", "framework_count": 1}, {"name": "Test Data Lifecycle Records", "frameworks": [{"code": "SA 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records documenting the lifecycle of test data, including creation, usage, and erasure.", "framework_count": 1}, {"name": "PII Anonymization Evidence", "frameworks": [{"code": "SA 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the anonymization of personally identifiable information in test data.", "framework_count": 1}, {"name": "Post-Test Data Erasure Confirmation", "frameworks": [{"code": "SA 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Confirmation records demonstrating the erasure of test data after use.", "framework_count": 1}]	18	pending	\N	\N
4531	NCF0051	Electronic Messaging	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.3662	Data Protection & Privacy	ai_normalized	\N	[{"name": "Electronic Messaging Inventory and Control Requirements", "frameworks": [{"code": "CM 2.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive inventory and control requirements for electronic messaging, including entity details and implementation evidence.", "framework_count": 1}, {"name": "Email/Messaging Configuration Evidence", "frameworks": [{"code": "CM 2.7", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration evidence for email/messaging signatures and encrypted messaging, demonstrating controls are in effect.", "framework_count": 1}, {"name": "Approved Electronic Messaging Policy", "frameworks": [{"code": "09.v", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board-approved policy and standard addressing electronic messaging, including scope and responsibilities.", "framework_count": 1}, {"name": "Documented Procedures for Electronic Messaging", "frameworks": [{"code": "09.v", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedures or work instructions for implementing electronic messaging.", "framework_count": 1}, {"name": "Information Exchange Agreements", "frameworks": [{"code": "09.v", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Agreements and configurations for secure information exchange, including security clauses and obligations.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "09.v", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications that inform personnel about electronic messaging requirements, including attendee lists.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "09.v", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating periodic reviews of electronic messaging controls, including observations and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4532	NCF0052	Business Information System	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.371568	Data Protection & Privacy	ai_normalized	\N	[{"name": "Business Information Systems Policy", "frameworks": [{"code": "CM 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.w", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Interconnected Business Information Systems, including scope and applicability.", "framework_count": 2}, {"name": "Interconnection Security Architecture Documentation", "frameworks": [{"code": "CM 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Current, version-controlled documentation showing components, interconnections, trust zones, and data flows.", "framework_count": 1}, {"name": "Inter-System Data Flow Security Measures", "frameworks": [{"code": "CM 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of security measures for inter-system data flows, including date and owner.", "framework_count": 1}, {"name": "Documented Procedures for Interconnected Business Information Systems", "frameworks": [{"code": "09.w", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedures or work instructions for implementing interconnected business information systems.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "09.w", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that personnel are informed of the requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "09.w", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4561	NCF0081	Patch management process	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.510999	Configuration & Change Management	ai_normalized	\N	[{"name": "Patch Management Policy", "frameworks": [{"code": "8.3.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "3.4", "framework": "SBP ETGRMF"}], "description": "A comprehensive policy outlining the processes for patch management, including identification, categorization, prioritization, and testing of security patches.", "framework_count": 2}, {"name": "Patch Source Validation Procedures", "frameworks": [{"code": "8.3.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Procedures for validating the sources of patches before deployment to ensure security and integrity.", "framework_count": 1}, {"name": "Rollback/Redepployment Playbooks", "frameworks": [{"code": "8.3.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Playbooks detailing the steps for rolling back or redeploying patches in case of issues post-deployment.", "framework_count": 1}, {"name": "Segregated Patch Testing Evidence", "frameworks": [{"code": "3.4", "framework": "SBP ETGRMF"}], "description": "Evidence demonstrating that patches have been tested in a segregated environment prior to production deployment.", "framework_count": 1}, {"name": "Patch Management Tool Reports", "frameworks": [{"code": "3.4", "framework": "SBP ETGRMF"}], "description": "Reports generated by patch management tools showing details of deployed patches and compliance status.", "framework_count": 1}, {"name": "Patch Categorisation Matrix", "frameworks": [{"code": "3.4", "framework": "SBP ETGRMF"}], "description": "A matrix used for the categorization and prioritization of security patches.", "framework_count": 1}, {"name": "Patch Change Records", "frameworks": [{"code": "3.4", "framework": "SBP ETGRMF"}], "description": "Records documenting the changes made during patch deployments, including an approval workflow.", "framework_count": 1}]	18	pending	\N	\N
4533	NCF0053	Audit Logs	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.376575	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Audit Logging Policy and Procedures", "frameworks": [{"code": "13.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "CIS Control 8 - Safeguard 8.5", "framework": "CIS Critical Security Controls v8"}, {"code": "§164.312(b)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Documentation outlining the audit logging policy, log retention procedures, and log review processes.", "framework_count": 3}, {"name": "Log Samples and Content Verification", "frameworks": [{"code": "13.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "CIS Control 8 - Safeguard 8.5", "framework": "CIS Critical Security Controls v8"}, {"code": "§164.312(b)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Samples of audit logs and verification of log content for compliance and accuracy.", "framework_count": 3}, {"name": "Sensitive Asset Logging Coverage", "frameworks": [{"code": "CIS Control 8 - Safeguard 8.5", "framework": "CIS Critical Security Controls v8"}], "description": "Documentation detailing the logging coverage for sensitive assets.", "framework_count": 1}]	18	pending	\N	\N
4534	NCF0054	Authentication Information	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.380575	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Authentication and Password Policy", "frameworks": [{"code": "A.5.17", "framework": "ISO/IEC 27001:2022"}, {"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "Policy specifying password complexity, length, rotation, MFA scope, and storage rules.", "framework_count": 2}, {"name": "MFA Enrolment and Coverage Reports", "frameworks": [{"code": "A.5.17", "framework": "ISO/IEC 27001:2022"}, {"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "Reports detailing MFA enrolment coverage across users and enforcement across applications.", "framework_count": 2}, {"name": "Password Policy Configuration Export", "frameworks": [{"code": "A.5.17", "framework": "ISO/IEC 27001:2022"}], "description": "GPO / Entra ID / Okta export showing enforced password and lockout settings.", "framework_count": 1}, {"name": "Temporary Credentials Issuance Log", "frameworks": [{"code": "A.5.17", "framework": "ISO/IEC 27001:2022"}], "description": "Log of temporary/initial credentials issued, delivered securely and forced-changed on first use.", "framework_count": 1}, {"name": "Default Credentials Change Evidence", "frameworks": [{"code": "A.5.17", "framework": "ISO/IEC 27001:2022"}], "description": "Checklist and sign-off confirming vendor defaults changed on new systems.", "framework_count": 1}, {"name": "Password Vault Configuration", "frameworks": [{"code": "A.5.17", "framework": "ISO/IEC 27001:2022"}], "description": "Screenshot of password manager / PAM vault configuration and access controls.", "framework_count": 1}, {"name": "Authentication Feedback and Masking Configuration", "frameworks": [{"code": "IA-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Evidence of authentication feedback configuration and password masking verification.", "framework_count": 1}, {"name": "Conditional Access Policy Export", "frameworks": [{"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "Export of conditional/step-up access policies from IdP.", "framework_count": 1}, {"name": "Authentication Protocol Configuration", "frameworks": [{"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of secure protocols (SAML, OIDC, FIDO2) and deprecated protocols disabled.", "framework_count": 1}, {"name": "Failed Authentication Monitoring", "frameworks": [{"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "SIEM dashboard or report showing failed authentication anomaly alerts.", "framework_count": 1}, {"name": "Biometric/Passwordless Rollout Evidence", "frameworks": [{"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "Rollout metrics for FIDO2/WebAuthn/biometric authentication where applicable.", "framework_count": 1}, {"name": "Authentication Mechanism Review Report", "frameworks": [{"code": "A.8.5", "framework": "ISO/IEC 27001:2022"}], "description": "Periodic review of authentication strength vs. threat landscape.", "framework_count": 1}]	18	pending	\N	\N
4535	NCF0055	Business Continuity and Crisis Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.383994	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Business Continuity Plan", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}, {"code": "12.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "Article 11(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "CC9.3", "framework": "SOC 2 Type II"}], "description": "Comprehensive documentation of the business continuity plan including RTO/RPO targets and recovery procedures.", "framework_count": 4}, {"name": "Disaster Recovery Plan", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}, {"code": "CC9.3", "framework": "SOC 2 Type II"}], "description": "Documented disaster recovery plan with defined recovery time objectives (RTO) and recovery point objectives (RPO).", "framework_count": 2}, {"name": "Business Continuity Policy", "frameworks": [{"code": "12.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "Article 11(1)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "Approved policy addressing business continuity management including information security.", "framework_count": 2}, {"name": "BCP Testing Records", "frameworks": [{"code": "12.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "CC9.3", "framework": "SOC 2 Type II"}], "description": "Records of business continuity plan testing exercises and post-test reviews.", "framework_count": 2}, {"name": "Policy Review Records", "frameworks": [{"code": "Article 11(1)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "CC9.3", "framework": "SOC 2 Type II"}], "description": "Records of policy reviews and updates for business continuity management.", "framework_count": 2}, {"name": "Backup Management Policy", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}], "description": "Policy and records related to backup management and testing.", "framework_count": 1}, {"name": "Crisis Management Framework", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}], "description": "Framework and communication plan for crisis management.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "12.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of business continuity requirements.", "framework_count": 1}]	18	pending	\N	\N
4536	NCF0056	Recovery Plan Execution	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.390085	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Recovery Plan Documentation", "frameworks": [{"code": "RC.RP-1", "framework": "NIST Cybersecurity Framework"}, {"code": "8.2.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Comprehensive documentation of the recovery plan including procedures and execution records.", "framework_count": 2}, {"name": "BCP/DR Test Documentation", "frameworks": [{"code": "A1.3", "framework": "SOC 2 Type II"}], "description": "Documentation of business continuity and disaster recovery test plans, execution results, and improvement actions.", "framework_count": 1}]	18	pending	\N	\N
4543	NCF0063	Developing Information System and Application Continuity Plans	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.415998	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Continuity Plans Documentation", "frameworks": [{"code": "12.c", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "SC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Approved policy and documented procedures addressing the development and implementation of continuity plans, including scope, objectives, roles, and activation criteria.", "framework_count": 3}, {"name": "Periodic Review Records", "frameworks": [{"code": "12.c", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of periodic reviews with details on the reviewer, date, observations, and corrective actions taken.", "framework_count": 2}, {"name": "Awareness Communications", "frameworks": [{"code": "12.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of continuity requirements, including attendee lists, delivery dates, and content references.", "framework_count": 1}, {"name": "Critical Business Services Inventory", "frameworks": [{"code": "SC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of critical business services and processes, including entity/item name, owner, classification, status, and last review date.", "framework_count": 1}, {"name": "Roles and Contact Information Register", "frameworks": [{"code": "SC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Register containing roles and contact information, including entity/item name, owner, classification, status, and traceability.", "framework_count": 1}, {"name": "Call Tree and Escalation Matrix", "frameworks": [{"code": "SC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of call tree and escalation matrix identifying owners, responsibilities, and coverage of relevant items.", "framework_count": 1}, {"name": "Continuity Infrastructure Readiness Records", "frameworks": [{"code": "SC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the readiness of continuity infrastructure, including date, performer, and approver details.", "framework_count": 1}, {"name": "Plan Activation Rehearsal Records", "frameworks": [{"code": "SC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of plan activation rehearsals demonstrating the activity occurred, including date, performer, and approver details.", "framework_count": 1}]	18	pending	\N	\N
4544	NCF0064	Contingency Plan	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.421998	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Contingency Plan Document", "frameworks": [{"code": "§164.308(a)(7)(i)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "CP-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "A documented plan outlining procedures for responding to emergencies and disasters.", "framework_count": 2}, {"name": "Emergency Response Procedures", "frameworks": [{"code": "§164.308(a)(7)(i)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Procedures established to respond to emergencies effectively.", "framework_count": 1}, {"name": "Disaster Recovery Procedures", "frameworks": [{"code": "§164.308(a)(7)(i)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Procedures for recovering from disasters to ensure business continuity.", "framework_count": 1}, {"name": "Recovery Time/Point Objectives (RTO/RPO)", "frameworks": [{"code": "CP-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Defined objectives for recovery time and data point recovery in contingency planning.", "framework_count": 1}, {"name": "Plan Distribution Records", "frameworks": [{"code": "CP-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records documenting the distribution of the contingency plan to relevant stakeholders.", "framework_count": 1}, {"name": "Plan Review and Approval Records", "frameworks": [{"code": "CP-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records showing the review and approval process of the contingency plan.", "framework_count": 1}, {"name": "Contingency Plan Test Results", "frameworks": [{"code": "CP-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Results from testing the contingency plan to evaluate its effectiveness.", "framework_count": 1}, {"name": "After-Action Reports", "frameworks": [{"code": "CP-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Reports generated after testing or actual events to assess the response and identify improvements.", "framework_count": 1}, {"name": "Plan Updates Based on Test Findings", "frameworks": [{"code": "CP-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Updates made to the contingency plan as a result of findings from tests.", "framework_count": 1}, {"name": "Test Schedule and Scenarios", "frameworks": [{"code": "CP-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of the schedule and scenarios used for testing the contingency plan.", "framework_count": 1}]	18	pending	\N	\N
4586	NCF0106	Network Monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.659054	Network Security	ai_normalized	\N	[{"name": "Network Monitoring and SIEM Architecture", "frameworks": [{"code": "DE.CM-1", "framework": "NIST Cybersecurity Framework"}, {"code": "2.3(a)", "framework": "SBP Internet Banking Framework"}], "description": "Documentation and tools for network monitoring and SIEM architecture, including alert configurations and monitoring procedures.", "framework_count": 2}]	18	pending	\N	\N
4545	NCF0065	Business Continuity Plan Content	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.426315	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Comprehensive Business Continuity Plan", "frameworks": [{"code": "8.5.4", "framework": "ISO 22301:2019 Business Continuity Management System"}, {"code": "5.1.a", "framework": "SBP ETGRMF"}], "description": "Full BCP document covering all required elements including governance, BIA, risk assessment, invocation conditions, recovery strategies, roles and communication.", "framework_count": 2}, {"name": "BCP Approval and Review Records", "frameworks": [{"code": "5.1.a", "framework": "SBP ETGRMF"}], "description": "Records of board approval and annual reviews of the BCP.", "framework_count": 1}, {"name": "BCP Development Methodology", "frameworks": [{"code": "5.1.a", "framework": "SBP ETGRMF"}], "description": "Documented methodology used to develop the comprehensive BCP.", "framework_count": 1}, {"name": "Recovery Procedures Documentation", "frameworks": [{"code": "8.5.4", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Documentation outlining recovery procedures for business continuity.", "framework_count": 1}, {"name": "Contact Lists and Call Trees", "frameworks": [{"code": "8.5.4", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Lists of contacts and call trees for communication during a business continuity event.", "framework_count": 1}]	18	pending	\N	\N
4546	NCF0066	Compliance with Business Continuity Planning Guidelines	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.429315	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Business Continuity Plan Documentation", "frameworks": [{"code": "5(d)", "framework": "SBP Internet Banking Framework"}, {"code": "12.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive documentation including the Business Continuity Plan, Business Impact Analysis, and Board approval evidence.", "framework_count": 2}, {"name": "BCP Test Reports", "frameworks": [{"code": "5(d)", "framework": "SBP Internet Banking Framework"}, {"code": "12.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Periodic reports on BCP tests including specific scenarios, results, and corrective actions.", "framework_count": 2}, {"name": "Awareness Communications", "frameworks": [{"code": "12.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation demonstrating that personnel are informed of Business Continuity Planning requirements.", "framework_count": 1}]	18	pending	\N	\N
4547	NCF0067	Independent Review of Information Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.432534	Audit & Assurance	ai_normalized	\N	[{"name": "Independent Review Policy and Procedure", "frameworks": [{"code": "05.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedure addressing Independent Review of Information Security, including scope and implementation instructions.", "framework_count": 1}, {"name": "Change Management Procedure and Records", "frameworks": [{"code": "05.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Change management procedure with CAB approvals, back-out plans, and change records demonstrating risk classification and post-implementation review.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "05.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirements, including attendee lists and delivery details.", "framework_count": 1}, {"name": "Internal Audit Programme and Reports", "frameworks": [{"code": "A.5.35", "framework": "ISO/IEC 27001:2022"}], "description": "Multi-year internal audit plan and completed reports with findings, evidence, and recommendations.", "framework_count": 1}, {"name": "Auditor Independence and Competence Evidence", "frameworks": [{"code": "A.5.35", "framework": "ISO/IEC 27001:2022"}], "description": "Qualifications and independence declaration for internal auditors to ensure impartiality.", "framework_count": 1}, {"name": "Management Review of Audit Findings", "frameworks": [{"code": "A.5.35", "framework": "ISO/IEC 27001:2022"}], "description": "Minutes from management reviews of audit results directing corrective actions based on findings.", "framework_count": 1}, {"name": "Corrective Action Register", "frameworks": [{"code": "A.5.35", "framework": "ISO/IEC 27001:2022"}], "description": "Register of audit-driven corrective actions with assigned owners, due dates, and current status.", "framework_count": 1}, {"name": "External Review Reports", "frameworks": [{"code": "A.5.35", "framework": "ISO/IEC 27001:2022"}], "description": "Reports from external advisors or previous audits used for independent review of the ISMS.", "framework_count": 1}]	18	pending	\N	\N
4548	NCF0068	Formulate information system asset protection policy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.436535	Asset Management	ai_normalized	\N	[{"name": "Information System Asset Protection Policy", "frameworks": [{"code": "2.2.b", "framework": "SBP ETGRMF"}, {"code": "5.1.3", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Formal policy specifying criticality assessment methodology and protection planning, including differentiated protection plans mapped to each criticality tier.", "framework_count": 2}, {"name": "Asset Criticality Assessment Methodology", "frameworks": [{"code": "2.2.b", "framework": "SBP ETGRMF"}, {"code": "5.1.3", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Documented methodology for assessing and classifying asset criticality, along with criteria for asset criticality.", "framework_count": 2}, {"name": "Criticality Register", "frameworks": [{"code": "2.2.b", "framework": "SBP ETGRMF"}], "description": "Register of information system assets with criticality ratings (High/Medium/Low) and justifications.", "framework_count": 1}]	18	pending	\N	\N
4550	NCF0070	Control of Documented Information	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.444909	Asset Management	ai_normalized	\N	[{"name": "Operating Procedures Library", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}, {"code": "09.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Central library of operating procedures (SOPs) for IT operations activities, including version control.", "framework_count": 2}, {"name": "Procedure Review Records", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}, {"code": "09.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of periodic review and update of operating procedures, including reviewer details and observations.", "framework_count": 2}, {"name": "Document Control Policy", "frameworks": [{"code": "7.5.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Policy and procedure for control of documented information covering availability, protection, distribution, version control, retention, and disposition.", "framework_count": 1}, {"name": "Access Control Records", "frameworks": [{"code": "7.5.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Document management system access control settings and audit logs.", "framework_count": 1}, {"name": "Runbook Examples", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}], "description": "Operational runbooks for routine activities such as backup, patching, and restart.", "framework_count": 1}, {"name": "On-Call Handover Procedure", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}], "description": "Procedure for shift handover and on-call rotation.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the documented operations procedures requirement.", "framework_count": 1}, {"name": "External-Origin Document Register", "frameworks": [{"code": "7.5.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Register identifying and controlling external-origin documents necessary for AIMS planning and operation.", "framework_count": 1}]	18	pending	\N	\N
4559	NCF0079	Software Integrity	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.499619	Application & Software Security	ai_normalized	\N	[{"name": "File Integrity Monitoring", "frameworks": [{"code": "7.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "SI-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records and configurations related to monitoring and verifying the integrity of files.", "framework_count": 2}, {"name": "Software Integrity Verification", "frameworks": [{"code": "7.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "SI-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records related to the verification of software integrity through hash/signature methods.", "framework_count": 2}, {"name": "Change Control Documentation", "frameworks": [{"code": "7.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "SI-7", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation related to the control and management of changes in the system.", "framework_count": 2}]	18	pending	\N	\N
4551	NCF0071	Supply Chain Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.44987	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Supplier Risk Assessment Records", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}, {"code": "ID.SC-1", "framework": "NIST Cybersecurity Framework"}, {"code": "SR-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "SA 7.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of risk assessments conducted for suppliers to evaluate their security posture.", "framework_count": 4}, {"name": "Supply Chain Security Policy", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}, {"code": "ID.SC-1", "framework": "NIST Cybersecurity Framework"}, {"code": "A.5.21", "framework": "ISO/IEC 27001:2022"}], "description": "A documented policy addressing risks and security requirements for the supply chain.", "framework_count": 3}, {"name": "Contractual Security Requirements for Suppliers", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}, {"code": "SA 7.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of security clauses and requirements included in supplier contracts.", "framework_count": 2}, {"name": "Supplier Security Monitoring and Audit Reports", "frameworks": [{"code": "Article 21(2)(d)", "framework": "NIS2 Directive"}, {"code": "A.5.21", "framework": "ISO/IEC 27001:2022"}], "description": "Reports detailing the results of security audits and monitoring activities for suppliers.", "framework_count": 2}, {"name": "Third-Party Management Procedures", "frameworks": [{"code": "ID.SC-1", "framework": "NIST Cybersecurity Framework"}, {"code": "SR-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Procedures outlining the management and oversight of third-party vendors.", "framework_count": 2}, {"name": "Supply Chain Risk Evaluation Reports", "frameworks": [{"code": "SA 7.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports evaluating risks associated with the supply chain, including findings and recommendations.", "framework_count": 1}, {"name": "Supplier-Agreed Control Measures Documentation", "frameworks": [{"code": "SA 7.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation demonstrating the implementation of agreed-upon security controls by suppliers.", "framework_count": 1}, {"name": "Supply Chain Risk Register", "frameworks": [{"code": "A.5.21", "framework": "ISO/IEC 27001:2022"}], "description": "A register tracking identified risks within the supply chain, including various risk factors.", "framework_count": 1}, {"name": "Vendor Due Diligence Reports", "frameworks": [{"code": "A.5.21", "framework": "ISO/IEC 27001:2022"}], "description": "Reports detailing the due diligence assessments performed on ICT vendors.", "framework_count": 1}, {"name": "SBOM Request and Review Records", "frameworks": [{"code": "A.5.21", "framework": "ISO/IEC 27001:2022"}], "description": "Records of Software Bill of Materials received from vendors and their analysis.", "framework_count": 1}, {"name": "Critical Vendor Contingency Plan", "frameworks": [{"code": "A.5.21", "framework": "ISO/IEC 27001:2022"}], "description": "Plans outlining strategies for replacing or mitigating the loss of critical ICT suppliers.", "framework_count": 1}]	18	pending	\N	\N
4552	NCF0072	Outsourced Development	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.458915	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Outsourced Development Agreement", "frameworks": [{"code": "A.8.30", "framework": "ISO/IEC 27001:2022"}, {"code": "SA 6.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Contracts with development suppliers including security, IP, confidentiality, and testing obligations.", "framework_count": 2}, {"name": "Code Review of Vendor Deliverables", "frameworks": [{"code": "A.8.30", "framework": "ISO/IEC 27001:2022"}, {"code": "SA 6.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of organisation-side code review of vendor-delivered code.", "framework_count": 2}, {"name": "Vendor Secure SDLC Assessment", "frameworks": [{"code": "A.8.30", "framework": "ISO/IEC 27001:2022"}], "description": "Assessment of supplier's SDLC maturity and security practices.", "framework_count": 1}, {"name": "Vendor Security Test Results", "frameworks": [{"code": "A.8.30", "framework": "ISO/IEC 27001:2022"}], "description": "Security test results from vendor deliverables (SAST, DAST, penetration).", "framework_count": 1}, {"name": "Source Code Escrow Agreement", "frameworks": [{"code": "A.8.30", "framework": "ISO/IEC 27001:2022"}], "description": "Source code escrow arrangement for critical outsourced software.", "framework_count": 1}, {"name": "Vendor Quality Reports", "frameworks": [{"code": "A.8.30", "framework": "ISO/IEC 27001:2022"}], "description": "Periodic quality and security reports from development vendors.", "framework_count": 1}, {"name": "Secure Coding Policy", "frameworks": [{"code": "SA 6.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved secure coding policy including scope, applicability, roles, and responsibilities.", "framework_count": 1}, {"name": "Quality Assurance Process Documentation", "frameworks": [{"code": "SA 6.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation including step-by-step instructions, responsible roles, and control points for quality assurance.", "framework_count": 1}, {"name": "Right-to-Audit Clauses in Agreements", "frameworks": [{"code": "SA 6.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Clauses in agreements detailing audit scope, methodology, and remediation tracking.", "framework_count": 1}, {"name": "Staff Rotation/Tenure Records for Outsourced Work", "frameworks": [{"code": "SA 6.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating staff rotation or termination for outsourced work, including dates and approvers.", "framework_count": 1}]	18	pending	\N	\N
4554	NCF0074	Development and Testing Standards	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.46826	Application & Software Security	ai_normalized	\N	[{"name": "Testing Documentation", "frameworks": [{"code": "PD-04", "framework": "SOX IT General Controls"}, {"code": "A.8.29", "framework": "ISO/IEC 27001:2022"}], "description": "Comprehensive documentation of testing strategies, plans, execution results, and acceptance sign-offs.", "framework_count": 2}, {"name": "Bug Bounty Reports", "frameworks": [{"code": "A.8.29", "framework": "ISO/IEC 27001:2022"}], "description": "Reports from bug bounty platforms detailing valid security findings.", "framework_count": 1}, {"name": "Information Systems Compliance Records", "frameworks": [{"code": "DS.3", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented evidence of compliance with NCA regulations for Information Systems Design, Development, and Testing.", "framework_count": 1}]	18	pending	\N	\N
4555	NCF0075	Penetration Testing	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.47584	Application & Software Security	ai_normalized	\N	[{"name": "Penetration Test Reports", "frameworks": [{"code": "5.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "2.3(e)", "framework": "SBP Internet Banking Framework"}, {"code": "CIS Control 16 - Safeguard 16.13", "framework": "CIS Critical Security Controls v8"}, {"code": "13.2.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Latest penetration test reports for systems and applications, including findings and remediation status.", "framework_count": 4}, {"name": "Testing Scope Documentation", "frameworks": [{"code": "5.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "2.3(e)", "framework": "SBP Internet Banking Framework"}, {"code": "T.2", "framework": "SBP Cloud Outsourcing Framework"}, {"code": "13.2.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation outlining the scope and methodology of testing activities.", "framework_count": 4}, {"name": "Remediation Tracking", "frameworks": [{"code": "5.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "2.3(e)", "framework": "SBP Internet Banking Framework"}, {"code": "CIS Control 16 - Safeguard 16.13", "framework": "CIS Critical Security Controls v8"}], "description": "Tracker of findings from all testing activities with severity, owner, and closure status.", "framework_count": 3}, {"name": "Retesting Evidence", "frameworks": [{"code": "5.3", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Evidence of retesting activities conducted after initial findings.", "framework_count": 1}, {"name": "Annual Security Testing Plan", "frameworks": [{"code": "2.3(e)", "framework": "SBP Internet Banking Framework"}], "description": "Plan listing self-assessments, penetration tests, and independent audits with scope and timing.", "framework_count": 1}, {"name": "Self-Assessment Reports", "frameworks": [{"code": "2.3(e)", "framework": "SBP Internet Banking Framework"}], "description": "Latest self-assessment reports for systems with control coverage.", "framework_count": 1}, {"name": "Independent Security Audit Report", "frameworks": [{"code": "2.3(e)", "framework": "SBP Internet Banking Framework"}], "description": "Latest independent security audit report covering systems.", "framework_count": 1}, {"name": "CSP VA/PT Reports", "frameworks": [{"code": "T.2", "framework": "SBP Cloud Outsourcing Framework"}], "description": "CSP-provided vulnerability assessment and penetration testing reports for their infrastructure and applications.", "framework_count": 1}, {"name": "CSP Assessment Reliance Register", "frameworks": [{"code": "T.2", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Register of CSP-provided assessments relied upon with scope, date, and reviewer sign-off.", "framework_count": 1}, {"name": "Findings Review Notes", "frameworks": [{"code": "T.2", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Review notes on CSP findings including required actions.", "framework_count": 1}]	18	pending	\N	\N
4556	NCF0076	System Acceptance and Testing	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.482286	Application & Software Security	ai_normalized	\N	[{"name": "System Acceptance Documentation", "frameworks": [{"code": "OM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating system acceptance criteria, sign-off, and related policies, including approvals and responsibilities.", "framework_count": 2}, {"name": "Test Cases and Results", "frameworks": [{"code": "OM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of test cases and results, including methodology, outcomes, and defects.", "framework_count": 2}, {"name": "Production Environment Testing Policy", "frameworks": [{"code": "OM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board-approved policy prohibiting testing in the production environment, detailing scope and responsibilities.", "framework_count": 1}, {"name": "Test User Account Inventory", "frameworks": [{"code": "OM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of test user accounts including details such as owner, classification, and review status.", "framework_count": 1}, {"name": "Production System Software Inventory", "frameworks": [{"code": "OM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of production system software excluding development tools, detailing ownership and classification.", "framework_count": 1}, {"name": "Secure SDLC Documentation", "frameworks": [{"code": "09.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of secure software development lifecycle with security checkpoints, demonstrating implementation.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications informing personnel about system acceptance requirements, including attendee lists and content references.", "framework_count": 1}]	18	pending	\N	\N
4557	NCF0077	Perform Periodic External Penetration Tests	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.489289	Application & Software Security	ai_normalized	\N	[{"name": "Penetration Test Reports", "frameworks": [{"code": "CIS Control 18 - Safeguard 18.2", "framework": "CIS Critical Security Controls v8"}, {"code": "CIS Control 18 - Safeguard 18.5", "framework": "CIS Critical Security Controls v8"}, {"code": "11.4.5", "framework": "PCI Data Security Standard"}], "description": "Reports from both external and internal penetration tests, including segmentation testing results.", "framework_count": 3}, {"name": "Remediation Tracking Records", "frameworks": [{"code": "CIS Control 18 - Safeguard 18.2", "framework": "CIS Critical Security Controls v8"}, {"code": "CIS Control 18 - Safeguard 18.5", "framework": "CIS Critical Security Controls v8"}, {"code": "11.4.5", "framework": "PCI Data Security Standard"}], "description": "Records tracking remediation efforts for identified vulnerabilities and deficiencies.", "framework_count": 3}, {"name": "Segmentation Testing Evidence", "frameworks": [{"code": "CIS Control 18 - Safeguard 18.5", "framework": "CIS Critical Security Controls v8"}, {"code": "11.4.5", "framework": "PCI Data Security Standard"}], "description": "Evidence confirming the effectiveness of segmentation controls and isolation of out-of-scope networks.", "framework_count": 2}]	18	pending	\N	\N
4563	NCF0083	Incident Reporting	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.519535	Incident Management	ai_normalized	\N	[{"name": "Incident Reporting Procedures", "frameworks": [{"code": "Article 23(1)", "framework": "NIS2 Directive"}, {"code": "IR-6", "framework": "NIST SP 800-53 Rev 5"}, {"code": "8.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation outlining the process for reporting incidents, including templates and workflows.", "framework_count": 3}, {"name": "Incident Classification and Criteria", "frameworks": [{"code": "Article 23(1)", "framework": "NIS2 Directive"}], "description": "Criteria and procedures for classifying significant incidents.", "framework_count": 1}, {"name": "CSIRT Contact Information", "frameworks": [{"code": "Article 23(1)", "framework": "NIS2 Directive"}], "description": "Contact details and communication channels for the CSIRT or competent authority.", "framework_count": 1}, {"name": "Incident Report Records", "frameworks": [{"code": "8.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records of submitted incident reports and corrective actions taken.", "framework_count": 1}, {"name": "External Reporting Documentation", "frameworks": [{"code": "IR-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation related to external reporting of incidents, such as to US-CERT.", "framework_count": 1}, {"name": "Incident Report Examples", "frameworks": [{"code": "IR-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Examples of completed incident reports for reference.", "framework_count": 1}]	18	pending	\N	\N
4564	NCF0084	Incident Reporting Timelines	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.536256	Incident Management	ai_normalized	\N	[{"name": "Incident Reporting Templates and Procedures", "frameworks": [{"code": "Article 19(4)", "framework": "Digital Operational Resilience Act (DORA)"}, {"code": "V.3", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Templates and procedures for initial notifications, intermediate reports, and final reports related to incident reporting.", "framework_count": 2}, {"name": "Incident Notification Communications", "frameworks": [{"code": "V.3", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Sample communications demonstrating timely submission and completeness of incident notifications.", "framework_count": 1}, {"name": "Root Cause Analysis and Responsibility Records", "frameworks": [{"code": "V.3", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Reports and records detailing root cause analyses, corrective actions, and responsibility fixing outcomes for reported incidents.", "framework_count": 1}, {"name": "Recurrence Prevention Tracker", "frameworks": [{"code": "V.3", "framework": "SBP Cloud Outsourcing Framework"}], "description": "Tracker of actions from incident reviews aimed at preventing recurrence, including ownership and status.", "framework_count": 1}, {"name": "Reporting Deadline Tracking System", "frameworks": [{"code": "Article 19(4)", "framework": "Digital Operational Resilience Act (DORA)"}], "description": "System for tracking reporting deadlines related to incident reporting.", "framework_count": 1}]	18	pending	\N	\N
4565	NCF0085	Information Security Event Reporting	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.542542	Incident Management	ai_normalized	\N	[{"name": "Security Event Reporting Procedure", "frameworks": [{"code": "A.6.8", "framework": "ISO/IEC 27001:2022"}, {"code": "4", "framework": "SBP Internet Banking Framework"}], "description": "Procedure detailing how staff should report security events, including what to report and to whom.", "framework_count": 2}, {"name": "Reporting Channel Documentation", "frameworks": [{"code": "A.6.8", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation outlining the various channels available for reporting security events.", "framework_count": 1}, {"name": "Event Reporting Awareness Material", "frameworks": [{"code": "A.6.8", "framework": "ISO/IEC 27001:2022"}], "description": "Materials designed to raise awareness and encourage staff to report security events.", "framework_count": 1}, {"name": "Event Report Log", "frameworks": [{"code": "A.6.8", "framework": "ISO/IEC 27001:2022"}], "description": "Log that records events reported by staff, including triage outcomes and metrics.", "framework_count": 1}, {"name": "Whistleblower / Anonymous Reporting Channel", "frameworks": [{"code": "A.6.8", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration of an anonymous reporting channel with metrics on its usage.", "framework_count": 1}, {"name": "Quarterly Submission Records", "frameworks": [{"code": "4", "framework": "SBP Internet Banking Framework"}], "description": "Copies of quarterly security breach reports submitted to SBP Payment Systems Department.", "framework_count": 1}, {"name": "Breach Impact Analysis Reports", "frameworks": [{"code": "4", "framework": "SBP Internet Banking Framework"}], "description": "Reports analyzing the impact of security breaches on the institution's operations and customers.", "framework_count": 1}, {"name": "Established-Breach Identification Criteria", "frameworks": [{"code": "4", "framework": "SBP Internet Banking Framework"}], "description": "Criteria for distinguishing established breaches from suspected or unconfirmed events.", "framework_count": 1}, {"name": "SBP Acknowledgment Correspondence", "frameworks": [{"code": "4", "framework": "SBP Internet Banking Framework"}], "description": "Correspondence from SBP confirming receipt of quarterly submissions.", "framework_count": 1}]	18	pending	\N	\N
4567	NCF0087	Reporting Information Security Events	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.54857	Incident Management	ai_normalized	\N	[{"name": "Incident Reporting Policy and Procedures", "frameworks": [{"code": "11.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "IM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Approved policy and documented procedures addressing incident reporting, including scope, methodology, and responsible roles.", "framework_count": 2}, {"name": "Incident Response Plan", "frameworks": [{"code": "11.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Incident response plan detailing classification, escalation, and notification timelines, including objectives and roles.", "framework_count": 1}, {"name": "Incident Register", "frameworks": [{"code": "11.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Incident register documenting case records, root cause analysis, and lessons learned, demonstrating incident management activities.", "framework_count": 1}, {"name": "Third-Party Agreements", "frameworks": [{"code": "11.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Third-party agreements containing security clauses, SLAs, and right-to-audit provisions, including audit scope and findings.", "framework_count": 1}, {"name": "Third-Party Risk Assessment Records", "frameworks": [{"code": "11.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of third-party risk assessments and ongoing monitoring, demonstrating completion of activities.", "framework_count": 1}, {"name": "Designated Point of Contact Records", "frameworks": [{"code": "IM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of designated points of contact for incident reporting, including dates and approvers.", "framework_count": 1}, {"name": "Stakeholder Communication Protocols", "frameworks": [{"code": "IM 3.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Protocols for communication with stakeholders and authorities regarding incidents, including implementation details.", "framework_count": 1}]	18	pending	\N	\N
4568	NCF0088	Creating and Updating Documented Information	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.551893	Other / Uncategorized	ai_normalized	\N	[{"name": "Document Control Procedure", "frameworks": [{"code": "7.5.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "7.5.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Procedure governing creation and updating of documented information including identification, format and review/approval requirements.", "framework_count": 2}, {"name": "Document Template Library", "frameworks": [{"code": "7.5.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "7.5.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Approved template library enforcing identification, format and review fields.", "framework_count": 2}, {"name": "Review & Approval Records", "frameworks": [{"code": "7.5.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "7.5.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Review and approval records for documents including workflow logs and signatures.", "framework_count": 2}]	18	pending	\N	\N
4569	NCF0089	Information Security Roles and Responsibilities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.557443	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Security Roles and Responsibilities Documentation", "frameworks": [{"code": "A.5.2", "framework": "ISO/IEC 27001:2022"}, {"code": "1.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "02.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive documentation including RACI matrix, job descriptions, appointment letters, and organizational charts that define security roles and responsibilities.", "framework_count": 3}, {"name": "Residual Risk Acceptance Records", "frameworks": [{"code": "A.5.2", "framework": "ISO/IEC 27001:2022"}], "description": "Signed acceptance forms showing named risk owners have formally accepted residual risks.", "framework_count": 1}, {"name": "Third-party Security Agreements and Assessments", "frameworks": [{"code": "02.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of third-party agreements with security clauses and records of risk assessments and ongoing monitoring.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "02.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of security requirements, including attendee lists and delivery dates.", "framework_count": 1}]	18	pending	\N	\N
4571	NCF0091	Lessons Learned	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.565776	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Post-Incident Review Documentation", "frameworks": [{"code": "RS.IM-1", "framework": "NIST Cybersecurity Framework"}, {"code": "8.6", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "8.2.12", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Records and documentation related to post-incident reviews and lessons learned.", "framework_count": 3}, {"name": "Plan and Process Improvement Updates", "frameworks": [{"code": "RS.IM-1", "framework": "NIST Cybersecurity Framework"}, {"code": "8.6", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "8.2.12", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Updates to plans and processes based on lessons learned and improvement actions.", "framework_count": 3}, {"name": "Incident Documentation Repository", "frameworks": [{"code": "8.2.12", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "A repository containing documentation related to incidents.", "framework_count": 1}]	18	pending	\N	\N
4572	NCF0092	Risk Assessment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.571781	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Risk Register", "frameworks": [{"code": "8.3.1", "framework": "ISO 22301:2019 Business Continuity Management System"}, {"code": "ELC-02", "framework": "SOX IT General Controls"}, {"code": "1.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "2.1", "framework": "SBP Internet Banking Framework"}, {"code": "2.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "1.4", "framework": "SABIC CyberTrust Guidelines"}], "description": "Document listing identified risks along with their ratings and mitigation plans.", "framework_count": 6}, {"name": "Risk Assessment Reports", "frameworks": [{"code": "RA-3", "framework": "NIST SP 800-53 Rev 5"}, {"code": "ELC-02", "framework": "SOX IT General Controls"}, {"code": "1.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "2.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "1.4", "framework": "SABIC CyberTrust Guidelines"}], "description": "Comprehensive reports detailing the findings of risk assessments.", "framework_count": 5}, {"name": "Risk Assessment Methodology", "frameworks": [{"code": "8.3.1", "framework": "ISO 22301:2019 Business Continuity Management System"}, {"code": "RA-3", "framework": "NIST SP 800-53 Rev 5"}, {"code": "ELC-02", "framework": "SOX IT General Controls"}, {"code": "1.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Document outlining the methodology for conducting risk assessments.", "framework_count": 4}, {"name": "Management Review Records", "frameworks": [{"code": "ELC-02", "framework": "SOX IT General Controls"}, {"code": "1.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "2.1", "framework": "SBP Internet Banking Framework"}], "description": "Records of management's review and approval of risk assessments.", "framework_count": 3}, {"name": "Risk Treatment Plans", "frameworks": [{"code": "2.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "1.4", "framework": "SABIC CyberTrust Guidelines"}], "description": "Plans outlining how identified risks will be treated or mitigated.", "framework_count": 2}, {"name": "Risk Evaluation Criteria", "frameworks": [{"code": "8.3.1", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Criteria used to evaluate risks during the assessment process.", "framework_count": 1}, {"name": "Threat and Vulnerability Analysis", "frameworks": [{"code": "RA-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Analysis identifying potential threats and vulnerabilities to the organization.", "framework_count": 1}, {"name": "Risk Assessment Update Records", "frameworks": [{"code": "RA-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records documenting updates made to the risk assessment over time.", "framework_count": 1}, {"name": "Annual Review Schedule and Records", "frameworks": [{"code": "2.1", "framework": "SBP Internet Banking Framework"}], "description": "Schedule and records evidencing the annual review cycle of risk assessments.", "framework_count": 1}, {"name": "Ad-Hoc Review Trigger Log", "frameworks": [{"code": "2.1", "framework": "SBP Internet Banking Framework"}], "description": "Log documenting ad-hoc risk assessment reviews triggered by significant events.", "framework_count": 1}, {"name": "Post-Breach Root Cause Analysis Report", "frameworks": [{"code": "2.1", "framework": "SBP Internet Banking Framework"}], "description": "Report analyzing the root causes of security breaches and subsequent risk assessments.", "framework_count": 1}]	18	pending	\N	\N
4573	NCF0093	Acceptable Use of Information Assets	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.578132	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Acceptable Use Policy", "frameworks": [{"code": "4.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.10", "framework": "ISO/IEC 27001:2022"}, {"code": "07.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "A board/management-approved policy defining permitted and prohibited uses of IT resources, email, internet, and data.", "framework_count": 3}, {"name": "User Acknowledgment Records", "frameworks": [{"code": "4.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.10", "framework": "ISO/IEC 27001:2022"}], "description": "Signed or e-acknowledged records from employees and contractors confirming understanding of the Acceptable Use Policy.", "framework_count": 2}, {"name": "Violation Handling Procedures", "frameworks": [{"code": "4.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.10", "framework": "ISO/IEC 27001:2022"}], "description": "Documented procedures for handling violations of the Acceptable Use Policy, including records of detected violations and actions taken.", "framework_count": 2}, {"name": "Policy Review Records", "frameworks": [{"code": "4.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "07.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating periodic reviews of the Acceptable Use Policy, including reviewer details and corrective actions.", "framework_count": 2}, {"name": "AUP Training Module Completion Report", "frameworks": [{"code": "A.5.10", "framework": "ISO/IEC 27001:2022"}], "description": "Report showing completion of the Acceptable Use Policy training module by staff.", "framework_count": 1}, {"name": "System Login Banner Screenshot", "frameworks": [{"code": "A.5.10", "framework": "ISO/IEC 27001:2022"}], "description": "Screenshot of the login banner reminding users of their acceptable use obligations.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "07.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the Acceptable Use Policy requirements.", "framework_count": 1}]	18	pending	\N	\N
4574	NCF0094	Policy Review	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.582411	Governance, Risk & Compliance	ai_normalized	\N	[{"name": "Policy Review and Change Management Records", "frameworks": [{"code": "2.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation of policy review schedules, meeting minutes, version history, and change management records.", "framework_count": 1}, {"name": "Approved Information Security Policy Document", "frameworks": [{"code": "04.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Formal authorization of the Information Security Policy document with management sign-off, scope, and version history.", "framework_count": 1}, {"name": "Annual Review Records of Information Security Policy", "frameworks": [{"code": "04.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating the annual review of the Information Security Policy, including reviewer, date, and changes captured.", "framework_count": 1}, {"name": "Change Management Procedure", "frameworks": [{"code": "04.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented change management procedure with CAB approvals and back-out plans, covering scope, objectives, and responsibilities.", "framework_count": 1}, {"name": "Change Records with Risk Classification", "frameworks": [{"code": "04.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of change requests (RFC) including risk classification, approvals, and post-implementation review.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "04.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of security requirements, including attendee lists and delivery dates.", "framework_count": 1}]	18	pending	\N	\N
4575	NCF0095	Encryption	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.598923	Cryptography & Key Management	ai_normalized	\N	[{"name": "Data-in-Transit Encryption Configuration", "frameworks": [{"code": "2.2.2(i)", "framework": "SBP Internet Banking Framework"}, {"code": "5.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "§164.312(e)(2)(ii)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Configuration of TLS for all data-in-transit with cipher suite hardening.", "framework_count": 3}, {"name": "Cryptographic Standards and Algorithms", "frameworks": [{"code": "2.2.2(i)", "framework": "SBP Internet Banking Framework"}, {"code": "5.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Approved cryptographic standard listing reliable algorithms and prohibiting obsolete ones.", "framework_count": 2}, {"name": "Access Encryption Evidence", "frameworks": [{"code": "2.2.2(i)", "framework": "SBP Internet Banking Framework"}], "description": "Configuration evidence that all access channels use encrypted protocols.", "framework_count": 1}, {"name": "Storage Encryption Configuration", "frameworks": [{"code": "2.2.2(i)", "framework": "SBP Internet Banking Framework"}], "description": "Configuration export showing encryption-at-rest enabled on databases, file stores, backups, and removable media.", "framework_count": 1}, {"name": "Sensitive Payment Data Encryption Evidence", "frameworks": [{"code": "2.2.2(i)", "framework": "SBP Internet Banking Framework"}], "description": "Specific evidence of encryption applied to sensitive payment data including tokenisation.", "framework_count": 1}, {"name": "Key Management Procedure", "frameworks": [{"code": "2.2.2(i)", "framework": "SBP Internet Banking Framework"}], "description": "Procedure covering generation, distribution, storage, rotation, and destruction of cryptographic keys.", "framework_count": 1}, {"name": "Email Encryption Implementation Evidence", "frameworks": [{"code": "§164.312(e)(2)(ii)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Evidence of implementation of encryption for email communications.", "framework_count": 1}, {"name": "VPN Configuration Documentation", "frameworks": [{"code": "§164.312(e)(2)(ii)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Documentation of VPN configuration for secure communications.", "framework_count": 1}, {"name": "TLS/SSL Certificate Inventory", "frameworks": [{"code": "§164.312(e)(2)(ii)", "framework": "HIPAA Security & Privacy Rule"}], "description": "Inventory of TLS/SSL certificates used for secure communications.", "framework_count": 1}]	18	pending	\N	\N
4576	NCF0096	Key Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.604191	Cryptography & Key Management	ai_normalized	\N	[{"name": "Key Management Procedures", "frameworks": [{"code": "4.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented procedures for managing cryptographic keys, including generation, rotation, and destruction.", "framework_count": 4}, {"name": "Key Rotation Schedules", "frameworks": [{"code": "4.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records detailing the schedules for key rotation to ensure security and compliance.", "framework_count": 3}, {"name": "Key Custodian Documentation", "frameworks": [{"code": "4.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation identifying key custodians and their responsibilities in key management.", "framework_count": 2}, {"name": "Cryptographic Standards Documentation", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of approved cryptographic standards, including algorithms and key strengths.", "framework_count": 2}, {"name": "Key Management Policy", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "An approved policy outlining the key management framework and responsibilities.", "framework_count": 2}, {"name": "Key Destruction Records", "frameworks": [{"code": "5.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records that demonstrate the proper destruction of cryptographic keys.", "framework_count": 1}, {"name": "Key Lifecycle Procedures", "frameworks": [{"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Procedures outlining the lifecycle of cryptographic keys from creation to destruction.", "framework_count": 1}, {"name": "Key Generation/Revocation/Repair Records", "frameworks": [{"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the generation, revocation, or repair of cryptographic keys.", "framework_count": 1}, {"name": "Key Protection Mechanisms", "frameworks": [{"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of mechanisms used to protect cryptographic keys, such as hardware security modules.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications to personnel regarding key management requirements and responsibilities.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of key management practices, including observations and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4578	NCF0098	Data-at-Rest Protection	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.615563	Cryptography & Key Management	ai_normalized	\N	[{"name": "Encryption Configuration", "frameworks": [{"code": "PR.DS-1", "framework": "NIST Cybersecurity Framework"}, {"code": "SC-28", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of encryption settings and configurations for data protection.", "framework_count": 2}, {"name": "Access Controls", "frameworks": [{"code": "PR.DS-1", "framework": "NIST Cybersecurity Framework"}], "description": "Documentation outlining the access control measures in place to protect data.", "framework_count": 1}, {"name": "Data Protection Policy", "frameworks": [{"code": "PR.DS-1", "framework": "NIST Cybersecurity Framework"}], "description": "A formal policy that outlines the organization's approach to data protection.", "framework_count": 1}]	18	pending	\N	\N
4580	NCF0100	Develop and implement cyber security awareness program	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.629943	Awareness & Training	ai_normalized	\N	[{"name": "Cyber Security Awareness Program", "frameworks": [{"code": "2.5.b", "framework": "SBP ETGRMF"}, {"code": "12.6.1", "framework": "PCI Data Security Standard"}], "description": "Comprehensive program plan and materials for annual cyber security awareness training, including audience segmentation and effectiveness metrics.", "framework_count": 2}, {"name": "Phishing Simulation Reports", "frameworks": [{"code": "2.5.b", "framework": "SBP ETGRMF"}], "description": "Reports detailing the results of periodic phishing simulations, including click and report rates.", "framework_count": 1}]	18	pending	\N	\N
4581	NCF0101	Screening	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.634229	Human Resources Security	ai_normalized	\N	[{"name": "Approved Screening Policy", "frameworks": [{"code": "02.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.1", "framework": "ISO/IEC 27001:2022"}], "description": "Board/management-approved policy and standard addressing screening, including scope, applicability, roles, and responsibilities.", "framework_count": 2}, {"name": "Background Verification Records", "frameworks": [{"code": "02.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.1", "framework": "ISO/IEC 27001:2022"}], "description": "Records of background verification for personnel based on role sensitivity, including dates and approvers.", "framework_count": 2}, {"name": "Documented Screening Procedure", "frameworks": [{"code": "02.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing screening with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Data Classification Scheme", "frameworks": [{"code": "02.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Data classification scheme with labeling and handling rules per class, demonstrating implementation.", "framework_count": 1}, {"name": "Third-Party Agreements with Security Clauses", "frameworks": [{"code": "02.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Third-party agreements that include security clauses, SLAs, and right-to-audit provisions.", "framework_count": 1}, {"name": "Third-Party Risk Assessment Records", "frameworks": [{"code": "02.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating third-party risk assessments and ongoing monitoring activities.", "framework_count": 1}, {"name": "Screening Vendor Agreement", "frameworks": [{"code": "A.6.1", "framework": "ISO/IEC 27001:2022"}], "description": "Agreement with background check provider that includes data protection clauses.", "framework_count": 1}, {"name": "Screening Tracker", "frameworks": [{"code": "A.6.1", "framework": "ISO/IEC 27001:2022"}], "description": "Tracker of screening status for all hires, including completion dates and sign-offs.", "framework_count": 1}, {"name": "Role-Based Screening Matrix", "frameworks": [{"code": "A.6.1", "framework": "ISO/IEC 27001:2022"}], "description": "Matrix specifying required checks for different role tiers (standard, elevated, privileged).", "framework_count": 1}]	18	pending	\N	\N
4582	NCF0102	Disciplinary Process	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.639869	Human Resources Security	ai_normalized	\N	[{"name": "Documented Disciplinary Process Procedure", "frameworks": [{"code": "02.f", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.4", "framework": "ISO/IEC 27001:2022"}, {"code": "HR 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Procedure or work instruction implementing the Disciplinary Process with step-by-step instructions and responsible roles.", "framework_count": 3}, {"name": "Disciplinary Awareness Communications", "frameworks": [{"code": "02.f", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.4", "framework": "ISO/IEC 27001:2022"}, {"code": "HR 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Communications demonstrating that personnel are informed of the disciplinary process and its consequences.", "framework_count": 3}, {"name": "Approved Disciplinary Policy", "frameworks": [{"code": "02.f", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.4", "framework": "ISO/IEC 27001:2022"}], "description": "Formal disciplinary policy including security violations, fair process, and sanctions.", "framework_count": 2}, {"name": "Periodic Review Records", "frameworks": [{"code": "02.f", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "HR 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating periodic reviews of the disciplinary process, including date, reviewer, and observations.", "framework_count": 2}, {"name": "Disciplinary Process Flowchart", "frameworks": [{"code": "A.6.4", "framework": "ISO/IEC 27001:2022"}], "description": "Flowchart showing stages from investigation to hearing to outcome.", "framework_count": 1}, {"name": "Redacted Disciplinary Case Records", "frameworks": [{"code": "A.6.4", "framework": "ISO/IEC 27001:2022"}], "description": "Redacted case records showing application of the disciplinary process for security breaches.", "framework_count": 1}, {"name": "Employee Handbook Extract on Disciplinary Process", "frameworks": [{"code": "A.6.4", "framework": "ISO/IEC 27001:2022"}], "description": "Extract from the employee handbook covering the disciplinary process and acknowledgment records.", "framework_count": 1}, {"name": "Incident-to-Action Linkage Records", "frameworks": [{"code": "HR 3.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the linkage between incidents and disciplinary actions taken.", "framework_count": 1}]	18	pending	\N	\N
4583	NCF0103	Terms and Conditions of Employment	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.644268	Human Resources Security	ai_normalized	\N	[{"name": "Employment Contract Documentation", "frameworks": [{"code": "5.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "02.c", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.2", "framework": "ISO/IEC 27001:2022"}], "description": "Templates and signed agreements that include security clauses and terms of employment.", "framework_count": 3}, {"name": "Security Clause Samples", "frameworks": [{"code": "5.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "02.c", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.2", "framework": "ISO/IEC 27001:2022"}], "description": "Examples of security clauses that can be included in employment contracts.", "framework_count": 3}, {"name": "Policy Acknowledgment Forms", "frameworks": [{"code": "5.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "02.c", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.2", "framework": "ISO/IEC 27001:2022"}], "description": "Forms signed by employees acknowledging understanding of security policies.", "framework_count": 3}, {"name": "Third-Party Agreements", "frameworks": [{"code": "02.c", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.6.2", "framework": "ISO/IEC 27001:2022"}], "description": "Agreements with third parties that include security clauses and obligations.", "framework_count": 2}, {"name": "Third-Party Risk Assessment Records", "frameworks": [{"code": "02.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating ongoing monitoring and assessment of third-party risks.", "framework_count": 1}]	18	pending	\N	\N
4584	NCF0104	Malware Protection	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.647248	Network Security	ai_normalized	\N	[{"name": "Anti-malware Deployment Evidence", "frameworks": [{"code": "6.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "7.2", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Documentation showing the deployment of anti-malware solutions across systems.", "framework_count": 3}, {"name": "Scan Reports", "frameworks": [{"code": "6.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "7.2", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Reports detailing the results of malware scans conducted on systems.", "framework_count": 3}, {"name": "Update Configuration Evidence", "frameworks": [{"code": "6.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records of configuration updates related to anti-malware systems.", "framework_count": 2}, {"name": "Malware Incident Records", "frameworks": [{"code": "7.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of incidents involving malware detection and response.", "framework_count": 2}, {"name": "Malware Protection Policy", "frameworks": [{"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Policy outlining the anti-malware controls implemented across various platforms.", "framework_count": 1}, {"name": "Anti-Malware Coverage Report", "frameworks": [{"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Report indicating the installation status of anti-malware agents on managed devices.", "framework_count": 1}, {"name": "Signature/Definition Update Status", "frameworks": [{"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Status report showing that all endpoints have current malware definitions and engine versions.", "framework_count": 1}, {"name": "Email Anti-Malware Scanning Report", "frameworks": [{"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Report from the email security gateway detailing malware blocked from entering the network.", "framework_count": 1}, {"name": "User Awareness Training - Malware Module", "frameworks": [{"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Records of training provided to users on recognizing and avoiding malware threats.", "framework_count": 1}, {"name": "Removable Media AV Scan Configuration", "frameworks": [{"code": "A.8.7", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration settings that enforce antivirus scanning on removable media.", "framework_count": 1}]	18	pending	\N	\N
4587	NCF0107	Segregation in Networks	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.663528	Network Security	ai_normalized	\N	[{"name": "Network Architecture Diagram", "frameworks": [{"code": "01.m", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "CM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Current, version-controlled diagram showing network segmentation, firewalls, and trust zones.", "framework_count": 2}, {"name": "Approved Segregation Policy", "frameworks": [{"code": "01.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Segregation in Networks, including scope, applicability, roles, and responsibilities.", "framework_count": 1}, {"name": "Segregation Implementation Procedure", "frameworks": [{"code": "01.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing Segregation in Networks with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Network Device Configuration Records", "frameworks": [{"code": "01.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating review of network device configuration baselines and rulesets, including dates and approvers.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of network segregation requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Network Segmentation Design Document", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Segmentation design document detailing VLANs, subnets, zones, and trust levels.", "framework_count": 1}, {"name": "VLAN and Subnet Register", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Register of VLANs and subnets with their purposes, owners, and allowed traffic.", "framework_count": 1}, {"name": "Inter-Zone Firewall Rules", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Firewall rules governing traffic between different network zones.", "framework_count": 1}, {"name": "Segmentation Test Results", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Results of penetration tests verifying the effectiveness of network segmentation.", "framework_count": 1}, {"name": "Microsegmentation Configuration", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration details for microsegmentation technologies such as NSX or Illumio.", "framework_count": 1}, {"name": "Wireless Segregation Evidence", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence demonstrating the segregation of guest and corporate wireless networks.", "framework_count": 1}, {"name": "OT/IT Segmentation Documentation", "frameworks": [{"code": "A.8.22", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation detailing segmentation between operational technology and corporate networks.", "framework_count": 1}, {"name": "Network Segregation Criteria and Strategy", "frameworks": [{"code": "CM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating the implementation of network segregation criteria and strategy.", "framework_count": 1}, {"name": "Security Requirements per Zone", "frameworks": [{"code": "CM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact detailing security requirements for each network zone.", "framework_count": 1}, {"name": "Periodic Segregation Adequacy Reviews", "frameworks": [{"code": "CM 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of periodic reviews assessing the adequacy of network segregation.", "framework_count": 1}]	18	pending	\N	\N
4588	NCF0108	Network Segmentation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.667526	Network Security	ai_normalized	\N	[{"name": "Network Segmentation Documentation", "frameworks": [{"code": "7.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "11.2.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Comprehensive documentation detailing network diagrams and segmentation configurations.", "framework_count": 2}]	18	pending	\N	\N
4589	NCF0109	Access Review	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.673047	Access Control & Identity Management	ai_normalized	\N	[{"name": "Access Review Records", "frameworks": [{"code": "4.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "9.1.6", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation of periodic access reviews and associated remediation actions.", "framework_count": 2}, {"name": "Revocation Evidence", "frameworks": [{"code": "4.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records demonstrating the revocation of access rights when necessary.", "framework_count": 1}, {"name": "Review Schedule", "frameworks": [{"code": "4.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "A documented schedule outlining the frequency and process for access reviews.", "framework_count": 1}]	18	pending	\N	\N
4590	NCF0110	Removal of Access Rights	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.677045	Access Control & Identity Management	ai_normalized	\N	[{"name": "User Access Records", "frameworks": [{"code": "02.i", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.5.18", "framework": "ISO/IEC 27001:2022"}, {"code": "2.2.2(a)", "framework": "SBP Internet Banking Framework"}], "description": "Records of user access provisioning, modification, and review, including dates and approvers.", "framework_count": 3}, {"name": "Access Revocation Procedure and Logs", "frameworks": [{"code": "HR 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "02.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive documentation including step-by-step access revocation procedures and logs for terminated personnel.", "framework_count": 2}, {"name": "Access Control Matrix", "frameworks": [{"code": "02.i", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "2.2.2(a)", "framework": "SBP Internet Banking Framework"}], "description": "Matrix mapping roles to permissions for relevant systems, identifying owners and responsibilities.", "framework_count": 2}, {"name": "Communication Records with Regulator", "frameworks": [{"code": "HR 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating communication with health sector regulators, including dates and responsible parties.", "framework_count": 1}, {"name": "Audit Trail of Disabled Accounts", "frameworks": [{"code": "HR 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Detailed audit trail for disabled accounts, including methodology and findings.", "framework_count": 1}, {"name": "Third-Party Agreements and Risk Assessments", "frameworks": [{"code": "02.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Agreements with security clauses and records of third-party risk assessments and monitoring.", "framework_count": 1}, {"name": "Access Provisioning Workflow and Metrics", "frameworks": [{"code": "A.5.18", "framework": "ISO/IEC 27001:2022"}], "description": "Screenshots of access provisioning workflows and metrics on access removal within target SLAs.", "framework_count": 1}, {"name": "Exception Register for Access", "frameworks": [{"code": "A.5.18", "framework": "ISO/IEC 27001:2022"}], "description": "Register of approved access exceptions with expiry dates and compensating controls.", "framework_count": 1}, {"name": "Segregation of Duties Conflict Analysis", "frameworks": [{"code": "2.2.2(a)", "framework": "SBP Internet Banking Framework"}], "description": "Analysis report identifying SoD conflicts for access rights with mitigation actions.", "framework_count": 1}, {"name": "Risk-Ranked Review Schedule", "frameworks": [{"code": "2.2.2(a)", "framework": "SBP Internet Banking Framework"}], "description": "Schedule outlining the cadence for periodic access reviews based on risk assessment classifications.", "framework_count": 1}]	18	pending	\N	\N
4591	NCF0111	Least Privilege	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.681378	Access Control & Identity Management	ai_normalized	\N	[{"name": "Least Privilege Access Policy", "frameworks": [{"code": "AC-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "A documented policy that outlines the principles of least privilege access for users and accounts.", "framework_count": 1}, {"name": "Privileged Account Management", "frameworks": [{"code": "AC-6", "framework": "NIST SP 800-53 Rev 5"}], "description": "Inventory and management of privileged accounts, including periodic reviews and just-in-time access records.", "framework_count": 1}, {"name": "Access Control Documentation", "frameworks": [{"code": "PR.AC-4", "framework": "NIST Cybersecurity Framework"}], "description": "Documentation that includes access control matrix, role definitions, and separation of duties.", "framework_count": 1}]	18	pending	\N	\N
4592	NCF0112	Access Control Policy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.685379	Access Control & Identity Management	ai_normalized	\N	[{"name": "Approved Access Control Policy", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "4.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "3.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "9.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "8.10.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "A.5.15", "framework": "ISO/IEC 27001:2022"}], "description": "Board/management-approved access control policy document, including scope, applicability, roles, responsibilities, and control objectives.", "framework_count": 7}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "4.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "9.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.15", "framework": "ISO/IEC 27001:2022"}], "description": "Matrix mapping roles to permissions for relevant systems, clearly identifying owners and responsibilities.", "framework_count": 4}, {"name": "Access Control Policy Review Records", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "9.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records demonstrating the annual review of the access control policy, including date, performer, and changes captured.", "framework_count": 3}, {"name": "User Access Provisioning and Review Records", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "3.1", "framework": "SABIC CyberTrust Guidelines"}], "description": "Records of user access provisioning, modification, and review, demonstrating the activity occurred with relevant details.", "framework_count": 2}, {"name": "Awareness Communications", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of access control requirements, including attendee list and delivery dates.", "framework_count": 1}, {"name": "Top Management Approval Evidence", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating top management approval of the access control policy, including date and owner.", "framework_count": 1}, {"name": "Stakeholder Policy Acknowledgement Records", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating stakeholder acknowledgment of the access control policy, including date and performer.", "framework_count": 1}, {"name": "Role-Based Access Criteria Documentation", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation outlining role-based access criteria, including date and owner.", "framework_count": 1}, {"name": "Password Management Policy", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved password management policy, including scope and control objectives.", "framework_count": 1}, {"name": "Identification/Authentication/Authorization Procedures", "frameworks": [{"code": "8.10.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Procedures outlining identification, authentication, and authorization processes.", "framework_count": 1}, {"name": "Access Review Evidence", "frameworks": [{"code": "A.5.15", "framework": "ISO/IEC 27001:2022"}], "description": "Quarterly access review results signed off by data/system owners.", "framework_count": 1}]	18	pending	\N	\N
4593	NCF0113	Information Access Restriction	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.693647	Access Control & Identity Management	ai_normalized	\N	[{"name": "Role-Based Access Control (RBAC) Configuration", "frameworks": [{"code": "AC 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Extract, screenshot, or export of the live RBAC configuration showing the control is in effect, with date and system ID.", "framework_count": 1}, {"name": "Access Justification Records", "frameworks": [{"code": "AC 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating that access activity occurred, including date, performer, approver where applicable.", "framework_count": 1}, {"name": "Need-to-Know Enforcement Evidence", "frameworks": [{"code": "AC 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of the need-to-know control, with date, owner, and reference to related policy.", "framework_count": 1}, {"name": "Restricted Access List for Support Staff", "frameworks": [{"code": "AC 7.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of restricted access for support staff, with date, owner, and reference to related policy.", "framework_count": 1}, {"name": "Application Access Control Matrix", "frameworks": [{"code": "A.8.3", "framework": "ISO/IEC 27001:2022"}], "description": "Matrix of permissions per role in each business application.", "framework_count": 1}, {"name": "Data Access Restriction Configuration", "frameworks": [{"code": "A.8.3", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of row/column-level security in databases or data platforms.", "framework_count": 1}, {"name": "Least Privilege Assessment", "frameworks": [{"code": "A.8.3", "framework": "ISO/IEC 27001:2022"}], "description": "Periodic assessment identifying over-privileged accounts with remediation actions.", "framework_count": 1}, {"name": "Application Access Review Records", "frameworks": [{"code": "A.8.3", "framework": "ISO/IEC 27001:2022"}], "description": "User access review outputs per application signed off by business owners.", "framework_count": 1}, {"name": "Access Decision Audit Log", "frameworks": [{"code": "A.8.3", "framework": "ISO/IEC 27001:2022"}], "description": "Log from access management system showing granted/denied decisions.", "framework_count": 1}, {"name": "Attribute-Based Access Control (ABAC) Configuration", "frameworks": [{"code": "A.8.3", "framework": "ISO/IEC 27001:2022"}], "description": "ABAC policy configuration with attributes and rules.", "framework_count": 1}]	18	pending	\N	\N
4594	NCF0114	Access Control to Program Source Code	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.697647	Access Control & Identity Management	ai_normalized	\N	[{"name": "User Access Records", "frameworks": [{"code": "10.j", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of user access provisioning, modification, and review demonstrating activity occurrence with relevant details.", "framework_count": 2}, {"name": "Access Control Policy and Standards", "frameworks": [{"code": "10.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Access Control to Program and Source Code, including scope and applicability.", "framework_count": 1}, {"name": "Access Control Implementation Procedures", "frameworks": [{"code": "10.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Access Control to Program and Source Code with step-by-step instructions.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "10.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Access control matrix with role-to-permission mapping for relevant systems, identifying owners and responsibilities.", "framework_count": 1}, {"name": "Secure SDLC Documentation", "frameworks": [{"code": "10.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of Secure SDLC with security checkpoints demonstrating implementation of the control.", "framework_count": 1}, {"name": "Code Review and Security Testing Records", "frameworks": [{"code": "10.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of code review and security testing results demonstrating activity occurrence with relevant details.", "framework_count": 1}, {"name": "Source Code Repository Access Control List", "frameworks": [{"code": "SA 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Access control list for source code repository demonstrating implementation of the control.", "framework_count": 1}, {"name": "Access Logs to Source Code Repositories", "frameworks": [{"code": "SA 5.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Access logs to source code repositories preserved for retention, protected from tampering, with timestamps and actor identity.", "framework_count": 1}]	18	pending	\N	\N
4595	NCF0115	User Authentication	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.700663	Access Control & Identity Management	ai_normalized	\N	[{"name": "Authentication Configuration", "frameworks": [{"code": "3.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Configuration settings for user authentication mechanisms.", "framework_count": 2}, {"name": "MFA Deployment Records", "frameworks": [{"code": "3.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records demonstrating the implementation of Multi-Factor Authentication.", "framework_count": 2}, {"name": "Password Policy", "frameworks": [{"code": "3.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documented policy outlining the requirements for password creation and management.", "framework_count": 2}, {"name": "User Access Records", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of user access provisioning, modification, and review activities.", "framework_count": 2}, {"name": "User Identification and Authentication Policy", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board-approved policy addressing user identification and authentication requirements.", "framework_count": 1}, {"name": "User Identification and Authentication Procedures", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures for implementing user identification and authentication.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Matrix mapping roles to permissions for relevant systems.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating personnel awareness of security requirements.", "framework_count": 1}, {"name": "User Activity Logs", "frameworks": [{"code": "AC 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of user activities linked to unique identifiers, preserved for retention.", "framework_count": 1}, {"name": "Account Naming Convention Documentation", "frameworks": [{"code": "AC 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation supporting the implementation of account naming conventions.", "framework_count": 1}]	18	pending	\N	\N
4596	NCF0116	User Registration	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.706953	Access Control & Identity Management	ai_normalized	\N	[{"name": "User Registration Policy and Procedures", "frameworks": [{"code": "01.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Approved policy and documented procedures addressing User Registration, including roles, responsibilities, and step-by-step instructions.", "framework_count": 2}, {"name": "User Account Creation and Approval Records", "frameworks": [{"code": "AC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Forms and records demonstrating the request and approval process for user account creation, including dates and responsible parties.", "framework_count": 1}, {"name": "Account Inventory Records", "frameworks": [{"code": "AC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive inventory of user accounts detailing ownership, classification, and review status.", "framework_count": 1}, {"name": "Account Revocation Records", "frameworks": [{"code": "AC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of account revocation for exits, including dates and responsible approvers.", "framework_count": 1}, {"name": "Temporary and Third-Party Account Procedures", "frameworks": [{"code": "AC 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Procedures for managing temporary and third-party accounts, including step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications informing personnel about user registration requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "01.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of user registration processes, including observations and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4597	NCF0117	Segregation of Duties	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.710971	Access Control & Identity Management	ai_normalized	\N	[{"name": "Compensating Controls Documentation", "frameworks": [{"code": "A.5.3", "framework": "ISO/IEC 27001:2022"}, {"code": "6.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "OM 2.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "CM-05", "framework": "SOX IT General Controls"}], "description": "Documented compensating controls where full SoD is not feasible, including supporting artifacts.", "framework_count": 4}, {"name": "Segregation of Duties Matrix", "frameworks": [{"code": "A.5.3", "framework": "ISO/IEC 27001:2022"}, {"code": "6.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "OM 2.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Matrix of conflicting activities with enforcement approach per system, including role conflict analysis.", "framework_count": 3}, {"name": "SoD Ruleset Configuration Export", "frameworks": [{"code": "A.5.3", "framework": "ISO/IEC 27001:2022"}], "description": "Export from ERP/IAM showing configured SoD rules and violations.", "framework_count": 1}, {"name": "SoD Violation and Remediation Report", "frameworks": [{"code": "A.5.3", "framework": "ISO/IEC 27001:2022"}], "description": "Periodic report listing detected SoD conflicts, owners, mitigation status and sign-off.", "framework_count": 1}, {"name": "Privileged Action Review Log", "frameworks": [{"code": "A.5.3", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of dual-control or four-eyes approval for high-risk operational changes.", "framework_count": 1}, {"name": "Approved Policy and Standard for SoD", "frameworks": [{"code": "09.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Segregation of Duties.", "framework_count": 1}, {"name": "Documented Procedure for SoD Implementation", "frameworks": [{"code": "09.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing Segregation of Duties.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "09.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Access control matrix with role-to-permission mapping for relevant systems.", "framework_count": 1}, {"name": "User Access Records", "frameworks": [{"code": "09.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "User access provisioning, modification, and review records demonstrating activity occurrence.", "framework_count": 1}, {"name": "Network Architecture Diagram", "frameworks": [{"code": "09.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Current network architecture diagram showing segmentation, firewalls, and trust zones.", "framework_count": 1}, {"name": "Network Device Configuration Records", "frameworks": [{"code": "09.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Network device configuration baselines and ruleset review records demonstrating activity occurrence.", "framework_count": 1}, {"name": "Developer vs. Migrator Access Privilege Reports", "frameworks": [{"code": "CM-05", "framework": "SOX IT General Controls"}], "description": "Reports detailing access privileges between developers and migrators.", "framework_count": 1}, {"name": "Production Access Restriction Evidence", "frameworks": [{"code": "CM-05", "framework": "SOX IT General Controls"}], "description": "Evidence demonstrating restrictions on production access.", "framework_count": 1}, {"name": "Migration Log Review for SoD Compliance", "frameworks": [{"code": "CM-05", "framework": "SOX IT General Controls"}], "description": "Review logs for migration activities to ensure SoD compliance.", "framework_count": 1}]	18	pending	\N	\N
4606	NCF0126	Physical Security Perimeter	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.776883	Physical & Environmental Security	ai_normalized	\N	[{"name": "Physical Access Controls Documentation", "frameworks": [{"code": "6.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "PE 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of physical access controls, including secure area identification, perimeter documentation, and security countermeasures.", "framework_count": 2}, {"name": "Access Logs", "frameworks": [{"code": "6.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of physical access including badge/biometric logs and visitor registers, preserved for the required retention period.", "framework_count": 2}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating the deployment of CCTV systems and retention of footage, including dates and responsible parties.", "framework_count": 1}, {"name": "Physical Security Policy and Procedures", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policies and documented procedures addressing physical security perimeters, including scope, roles, and implementation instructions.", "framework_count": 1}, {"name": "Risk-Based Perimeter Assessment Records", "frameworks": [{"code": "PE 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation demonstrating risk-based assessments of security perimeters, including dates and responsible parties.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications informing personnel about physical security requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of physical security controls, including dates, observations, and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4599	NCF0119	Privilege Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.723191	Access Control & Identity Management	ai_normalized	\N	[{"name": "Approved Privilege Management Policy", "frameworks": [{"code": "01.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Privilege Management, including scope, applicability, roles, and responsibilities.", "framework_count": 1}, {"name": "Documented Privilege Management Procedure", "frameworks": [{"code": "01.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure or work instruction implementing Privilege Management, detailing responsible roles and control points.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Access control matrix with role-to-permission mapping for relevant systems, clearly identifying owners and responsibilities.", "framework_count": 1}, {"name": "User Access Records", "frameworks": [{"code": "01.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating user access provisioning, modification, and review, including dates, performers, and approvers.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the Privilege Management requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Privileged Account Inventory", "frameworks": [{"code": "AC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of privileged accounts containing entity/item name, owner, classification, status, and date of last review.", "framework_count": 1}, {"name": "Separation of Accounts Evidence", "frameworks": [{"code": "AC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating the separation of normal vs. privileged accounts, including date, owner, and reference.", "framework_count": 1}, {"name": "Service Account Inventory", "frameworks": [{"code": "AC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Inventory of service accounts and controls, including entity/item name, owner, classification, status, and date of last review.", "framework_count": 1}, {"name": "MFA Configuration for Admin Access", "frameworks": [{"code": "AC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Extract or screenshot of the live configuration showing MFA control for admin access, including date and system identifier.", "framework_count": 1}, {"name": "Privileged Access Logs", "frameworks": [{"code": "AC 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs and audit reports of privileged access, preserved for the required retention period and protected from tampering.", "framework_count": 1}]	18	pending	\N	\N
4600	NCF0120	Password Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.727185	Access Control & Identity Management	ai_normalized	\N	[{"name": "Password Management Policy", "frameworks": [{"code": "§164.308(a)(5)(ii)(D)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "01.r", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "3.2", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "9.1.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "A documented policy outlining the requirements and standards for password management, including scope and roles.", "framework_count": 4}, {"name": "Password Complexity Configuration Evidence", "frameworks": [{"code": "§164.308(a)(5)(ii)(D)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "01.r", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "3.2", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Evidence demonstrating the configuration settings for password complexity, including lifetime, history, and lockout settings.", "framework_count": 3}, {"name": "Training Records on Password Management", "frameworks": [{"code": "§164.308(a)(5)(ii)(D)", "framework": "HIPAA Security & Privacy Rule"}, {"code": "01.r", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of training sessions conducted to inform personnel about password management practices and policies.", "framework_count": 2}, {"name": "Documented Procedures for Password Management", "frameworks": [{"code": "01.r", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step procedures or work instructions for implementing the password management system, detailing responsible roles and control points.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "01.r", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of the password management system, including observations and corrective actions taken.", "framework_count": 1}, {"name": "Password Compliance Reports", "frameworks": [{"code": "3.2", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Reports demonstrating compliance with password management policies and standards.", "framework_count": 1}, {"name": "Password Control Enforcement Evidence", "frameworks": [{"code": "9.1.4", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Evidence showing enforcement of password controls within the organization.", "framework_count": 1}]	18	pending	\N	\N
4601	NCF0121	Limitation of Connection Time	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.751611	Access Control & Identity Management	ai_normalized	\N	[{"name": "Approved Limitation of Connection Time Policy", "frameworks": [{"code": "01.u", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "9.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Board/management-approved policy and standard addressing Limitation of Connection Time, including scope, applicability, and roles.", "framework_count": 2}, {"name": "Documented Limitation of Connection Procedure", "frameworks": [{"code": "01.u", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing Limitation of Connection Time with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Risk Register", "frameworks": [{"code": "01.u", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Risk register with entries, owners, ratings, and treatment plans, including entity/item name, owner, classification, and status.", "framework_count": 1}, {"name": "Risk Assessment Methodology Documentation", "frameworks": [{"code": "01.u", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation and approval records for risk assessment methodology, demonstrating the activity occurred with relevant dates and approvers.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "01.u", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the requirement, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "01.u", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions demonstrating that the activity occurred.", "framework_count": 1}, {"name": "Session Management Configuration", "frameworks": [{"code": "9.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Timeout configuration records and system configuration documentation related to session management.", "framework_count": 1}, {"name": "Session Management Logs", "frameworks": [{"code": "9.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Logs related to session management activities.", "framework_count": 1}]	18	pending	\N	\N
4603	NCF0123	Physical Entry Controls	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.760134	Physical & Environmental Security	ai_normalized	\N	[{"name": "Entry Control Procedures", "frameworks": [{"code": "8.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "08.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.7.2", "framework": "ISO/IEC 27001:2022"}], "description": "Documented procedures and audit reports for managing physical entry controls.", "framework_count": 3}, {"name": "Access Card System Records", "frameworks": [{"code": "8.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "08.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.7.2", "framework": "ISO/IEC 27001:2022"}], "description": "Records of access card usage, including logs and configuration.", "framework_count": 3}, {"name": "Visitor Management Records", "frameworks": [{"code": "8.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.2", "framework": "ISO/IEC 27001:2022"}], "description": "Logs and records related to visitor management, including registration and escort assignments.", "framework_count": 2}, {"name": "User Access Provisioning Records", "frameworks": [{"code": "08.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.7.2", "framework": "ISO/IEC 27001:2022"}], "description": "Records demonstrating user access provisioning, modification, and review activities.", "framework_count": 2}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "08.b", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of CCTV deployment and retention of footage.", "framework_count": 1}, {"name": "Tailgating Awareness Evidence", "frameworks": [{"code": "A.7.2", "framework": "ISO/IEC 27001:2022"}], "description": "Materials promoting awareness of tailgating and piggybacking risks.", "framework_count": 1}, {"name": "Lost/Stolen Badge Report", "frameworks": [{"code": "A.7.2", "framework": "ISO/IEC 27001:2022"}], "description": "Log of lost or stolen badges with deactivation timestamps.", "framework_count": 1}]	18	pending	\N	\N
4604	NCF0124	Physical Access Controls	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.764446	Physical & Environmental Security	ai_normalized	\N	[{"name": "Access Logs", "frameworks": [{"code": "5.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "PR.AC-2", "framework": "NIST Cybersecurity Framework"}, {"code": "CC6.4", "framework": "SOC 2 Type II"}, {"code": "2.2.2(d)", "framework": "SBP Internet Banking Framework"}, {"code": "PE-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of access events including badge swipes and biometric data.", "framework_count": 5}, {"name": "Access Control Systems", "frameworks": [{"code": "5.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "PR.AC-2", "framework": "NIST Cybersecurity Framework"}, {"code": "CC6.4", "framework": "SOC 2 Type II"}, {"code": "PE-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of systems used to control physical access.", "framework_count": 4}, {"name": "Physical Access Policy", "frameworks": [{"code": "5.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "PR.AC-2", "framework": "NIST Cybersecurity Framework"}, {"code": "2.2.2(d)", "framework": "SBP Internet Banking Framework"}], "description": "Approved policy governing physical access to sensitive areas.", "framework_count": 3}, {"name": "Authorized Access List", "frameworks": [{"code": "APD-08", "framework": "SOX IT General Controls"}, {"code": "2.2.2(d)", "framework": "SBP Internet Banking Framework"}, {"code": "PE-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "List of personnel authorized for physical access with approvals.", "framework_count": 3}, {"name": "Visitor Logs", "frameworks": [{"code": "APD-08", "framework": "SOX IT General Controls"}, {"code": "CC6.4", "framework": "SOC 2 Type II"}, {"code": "2.2.2(d)", "framework": "SBP Internet Banking Framework"}], "description": "Records of visitors including purpose and time of access.", "framework_count": 3}, {"name": "Periodic Physical Access Review Documentation", "frameworks": [{"code": "APD-08", "framework": "SOX IT General Controls"}, {"code": "2.2.2(d)", "framework": "SBP Internet Banking Framework"}, {"code": "PE-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of periodic reviews of physical access controls.", "framework_count": 3}, {"name": "CCTV Coverage Evidence", "frameworks": [{"code": "2.2.2(d)", "framework": "SBP Internet Banking Framework"}], "description": "Evidence of CCTV coverage and retention for sensitive areas.", "framework_count": 1}, {"name": "Access Badge/Credential Records", "frameworks": [{"code": "PE-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of access badges and credentials issued to personnel.", "framework_count": 1}, {"name": "Guard Procedures", "frameworks": [{"code": "PE-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Procedures followed by guards for monitoring physical access.", "framework_count": 1}, {"name": "Access Control System Audit Logs", "frameworks": [{"code": "PE-3", "framework": "NIST SP 800-53 Rev 5"}], "description": "Audit logs for access control systems documenting access events.", "framework_count": 1}]	18	pending	\N	\N
4605	NCF0125	Working in Secure Areas	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.771442	Physical & Environmental Security	ai_normalized	\N	[{"name": "Approved Secure Area Policy", "frameworks": [{"code": "08.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.7.6", "framework": "ISO/IEC 27001:2022"}, {"code": "PE 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved policy and standard addressing working in secure areas, including scope, applicability, and roles.", "framework_count": 3}, {"name": "Secure Area Working Procedures", "frameworks": [{"code": "08.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "PE 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented procedures or work instructions implementing secure area protocols, including step-by-step instructions and responsible roles.", "framework_count": 2}, {"name": "Physical Access Logs", "frameworks": [{"code": "08.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "PE 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of physical access (badge/biometric) and visitor registers, preserved for retention, protected from tampering, with timestamps.", "framework_count": 2}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.e", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.7.6", "framework": "ISO/IEC 27001:2022"}], "description": "Records of periodic reviews with reviewers, dates, observations, and corrective actions.", "framework_count": 2}, {"name": "CCTV Evidence and Retention Records", "frameworks": [{"code": "08.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating CCTV deployment and footage retention, including dates and performers.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "08.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating personnel awareness of secure area requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Secure Area Access Register", "frameworks": [{"code": "A.7.6", "framework": "ISO/IEC 27001:2022"}], "description": "Register of personnel authorized to access secure areas, including expiry dates.", "framework_count": 1}, {"name": "Secure Area Entry/Exit Log", "frameworks": [{"code": "A.7.6", "framework": "ISO/IEC 27001:2022"}], "description": "Log entries showing supervised and time-bound access to secure areas.", "framework_count": 1}, {"name": "Visitor Escort Records", "frameworks": [{"code": "A.7.6", "framework": "ISO/IEC 27001:2022"}], "description": "Records of escorts assigned for visits into secure areas.", "framework_count": 1}, {"name": "Camera/Photography Prohibition Signage", "frameworks": [{"code": "A.7.6", "framework": "ISO/IEC 27001:2022"}], "description": "Photos of signage prohibiting photography and recording in secure areas.", "framework_count": 1}, {"name": "Supervision Records for Secure Area Activities", "frameworks": [{"code": "PE 2.8", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating supervision of activities in secure areas, including dates and performers.", "framework_count": 1}]	18	pending	\N	\N
4607	NCF0127	Physical and Environmental Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.781392	Physical & Environmental Security	ai_normalized	\N	[{"name": "Physical Security Policy and Procedures", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}, {"code": "2.4.2", "framework": "SBP ETGRMF"}], "description": "Policy covering physical access controls, environmental monitoring, and power protection for IT facilities.", "framework_count": 2}, {"name": "Data Center Access Control Logs", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}, {"code": "2.4.2", "framework": "SBP ETGRMF"}], "description": "Access register for data centres and network equipment rooms with authorised-personnel list and review records.", "framework_count": 2}, {"name": "Environmental Monitoring Records", "frameworks": [{"code": "Article 21(2)(a)", "framework": "NIS2 Directive"}, {"code": "2.4.2", "framework": "SBP ETGRMF"}], "description": "Logs from environmental monitoring systems (temperature, humidity, water, smoke) from data centre.", "framework_count": 2}, {"name": "UPS/Generator Maintenance Records", "frameworks": [{"code": "2.4.2", "framework": "SBP ETGRMF"}], "description": "Records of UPS, generator and electrical stabiliser maintenance and testing.", "framework_count": 1}, {"name": "Data Centre Site Risk Assessment", "frameworks": [{"code": "2.4.2", "framework": "SBP ETGRMF"}], "description": "Site risk assessment addressing environmental threats considered in data centre location selection.", "framework_count": 1}, {"name": "Data Centre Walkthrough Photos", "frameworks": [{"code": "2.4.2", "framework": "SBP ETGRMF"}], "description": "Photographs evidencing physical security barriers, CCTV, biometric entry and environmental controls.", "framework_count": 1}]	18	pending	\N	\N
4608	NCF0128	Equipment Siting and Protection	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.784705	Physical & Environmental Security	ai_normalized	\N	[{"name": "Environmental Controls Documentation", "frameworks": [{"code": "5.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "A.7.8", "framework": "ISO/IEC 27001:2022"}, {"code": "PE 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation detailing environmental controls for equipment, including siting standards and risk assessments.", "framework_count": 3}, {"name": "Physical Security Measures", "frameworks": [{"code": "5.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "A.7.8", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of physical security measures implemented to protect critical equipment.", "framework_count": 2}, {"name": "Protection Assessments", "frameworks": [{"code": "5.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "A.7.8", "framework": "ISO/IEC 27001:2022"}], "description": "Risk assessments and evaluations driving protection choices for specific equipment locations.", "framework_count": 2}, {"name": "Equipment Placement Plans/Diagrams", "frameworks": [{"code": "PE 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Plans and diagrams detailing the placement of equipment, including roles and responsibilities.", "framework_count": 1}]	18	pending	\N	\N
4609	NCF0129	Securing Offices, Rooms and Facilities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.790702	Physical & Environmental Security	ai_normalized	\N	[{"name": "Facility Security Design Documents", "frameworks": [{"code": "8.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.3", "framework": "ISO/IEC 27001:2022"}], "description": "Comprehensive documentation detailing the design and specifications for secure facilities and rooms.", "framework_count": 2}, {"name": "Room Security Classifications and Assessments", "frameworks": [{"code": "8.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.3", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of room security classifications and assessments related to privacy and security risks.", "framework_count": 2}, {"name": "Lock and Key Management Records", "frameworks": [{"code": "8.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.3", "framework": "ISO/IEC 27001:2022"}], "description": "Records detailing the management of physical keys and combinations for secure areas.", "framework_count": 2}, {"name": "Internal Access Restrictions", "frameworks": [{"code": "A.7.3", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence that internal directories and signage do not expose sensitive locations.", "framework_count": 1}, {"name": "Secure Area Inspection Reports", "frameworks": [{"code": "A.7.3", "framework": "ISO/IEC 27001:2022"}], "description": "Reports detailing inspections of secure areas for identifying security weaknesses.", "framework_count": 1}, {"name": "Approved Security Policies and Procedures", "frameworks": [{"code": "08.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board-approved policies and documented procedures for securing offices, rooms, and facilities.", "framework_count": 1}, {"name": "Physical Access Logs and Visitor Registers", "frameworks": [{"code": "08.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Logs and registers documenting physical access to secure areas, including timestamps and identities.", "framework_count": 1}, {"name": "CCTV Deployment and Footage Records", "frameworks": [{"code": "08.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of CCTV deployment and retention of footage demonstrating security monitoring activities.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "08.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications evidencing personnel awareness of security requirements, including attendee lists and content references.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.c", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of security measures, including observations and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4611	NCF0131	Protecting Against Physical and Environmental Threats	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.799062	Physical & Environmental Security	ai_normalized	\N	[{"name": "Environmental Threat Risk Assessment", "frameworks": [{"code": "A.7.5", "framework": "ISO/IEC 27001:2022"}], "description": "Assessment covering fire, flood, earthquake, power, civil unrest relevant to sites.", "framework_count": 1}, {"name": "Fire Safety Documentation", "frameworks": [{"code": "A.7.5", "framework": "ISO/IEC 27001:2022"}], "description": "Includes fire detection and suppression certificates, fire drill records, and flood protection measures documentation.", "framework_count": 1}, {"name": "Environmental Monitoring and Incident Documentation", "frameworks": [{"code": "A.7.5", "framework": "ISO/IEC 27001:2022"}], "description": "Includes environmental monitoring configuration and incident log for environmental events.", "framework_count": 1}, {"name": "Insurance Coverage Evidence", "frameworks": [{"code": "A.7.5", "framework": "ISO/IEC 27001:2022"}], "description": "Certificates of insurance covering environmental risks.", "framework_count": 1}, {"name": "Approved Policy and Procedures for Environmental Threats", "frameworks": [{"code": "08.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and documented procedures addressing protection against external and environmental threats.", "framework_count": 1}, {"name": "Access Control and Surveillance Records", "frameworks": [{"code": "08.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Includes physical access logs, visitor registers, CCTV deployment evidence, and footage retention records.", "framework_count": 1}, {"name": "Awareness and Training Records", "frameworks": [{"code": "08.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of environmental threat requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.d", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews with reviewer, date, observations, and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4612	NCF0132	Cabling Security	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.802326	Physical & Environmental Security	ai_normalized	\N	[{"name": "Cabling Architecture Documentation", "frameworks": [{"code": "PE 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "8.8", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.12", "framework": "ISO/IEC 27001:2022"}], "description": "Current, version-controlled cabling architecture diagrams showing components, interconnections, trust zones, and data flows.", "framework_count": 3}, {"name": "Cable Protection Measures", "frameworks": [{"code": "PE 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "8.8", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.12", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of cable protection measures (conduits, trays) demonstrating implementation of the control.", "framework_count": 3}, {"name": "Cable Inspection Records", "frameworks": [{"code": "PE 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "8.8", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.7.12", "framework": "ISO/IEC 27001:2022"}], "description": "Records demonstrating cable inspection activities, including date, performer, and approver where applicable.", "framework_count": 3}, {"name": "Cable Segregation Documentation", "frameworks": [{"code": "PE 3.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating cable segregation implementation with date, owner, and reference to related policy.", "framework_count": 1}, {"name": "Cabling Security Policy", "frameworks": [{"code": "08.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing cabling security, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Cabling Security Procedures", "frameworks": [{"code": "08.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing cabling security with step-by-step instructions.", "framework_count": 1}, {"name": "Physical Access Logs", "frameworks": [{"code": "08.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Logs of physical access (badge/biometric) and visitor registers preserved for the required retention period.", "framework_count": 1}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "08.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of CCTV deployment and retention records demonstrating activity occurrence.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "08.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating personnel awareness of cabling security requirements, including attendee lists.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.i", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including date, observations, and corrective actions taken.", "framework_count": 1}, {"name": "Structured Cabling Certification", "frameworks": [{"code": "A.7.12", "framework": "ISO/IEC 27001:2022"}], "description": "Certification of structured cabling installation and testing by the installer.", "framework_count": 1}, {"name": "Cable Labelling Evidence", "frameworks": [{"code": "A.7.12", "framework": "ISO/IEC 27001:2022"}], "description": "Photos showing proper cable labelling and documentation at patch panels.", "framework_count": 1}, {"name": "Cable Access Point Security", "frameworks": [{"code": "A.7.12", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence that cable access points are secured and monitored.", "framework_count": 1}]	18	pending	\N	\N
4613	NCF0133	Management of Removable Media	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.808327	Physical & Environmental Security	ai_normalized	\N	[{"name": "Removable Media Management Procedures", "frameworks": [{"code": "AM 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.o", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step instructions, responsible roles, control points, exception handling, and references for managing removable media.", "framework_count": 2}, {"name": "Removable Media Inventory/Register", "frameworks": [{"code": "AM 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive inventory of removable media including entity/item name, owner, classification, status, and traceability.", "framework_count": 1}, {"name": "Media Lifecycle Records", "frameworks": [{"code": "AM 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the lifecycle of media including setup, distribution, utilization, and disposal with relevant details.", "framework_count": 1}, {"name": "Media Movement Tracking Logs", "frameworks": [{"code": "AM 4.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs that track the movement of media, preserved for retention, protected from tampering, and include timestamps and actions.", "framework_count": 1}, {"name": "Removable Media Authorization Records", "frameworks": [{"code": "AM 4.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating authorization activities related to removable media, including dates, performers, and approvers.", "framework_count": 1}, {"name": "Management Risk Acceptance Records", "frameworks": [{"code": "AM 4.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating management's acceptance of risks associated with removable media, including dates and approvers.", "framework_count": 1}, {"name": "USB/Removable Media Control Configuration Evidence", "frameworks": [{"code": "AM 4.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of the configuration of controls for USB/removable media, including extracts or screenshots with relevant details.", "framework_count": 1}, {"name": "User Request and Approval Workflows", "frameworks": [{"code": "AM 4.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of user request and approval workflows for removable media.", "framework_count": 1}, {"name": "Approved Policy and Standard for Removable Media Management", "frameworks": [{"code": "09.o", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board-approved policy and standard addressing the management of removable media, including scope and roles.", "framework_count": 1}, {"name": "Media Handling Procedure", "frameworks": [{"code": "09.o", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures for handling, transporting, and disposing of media, including certificates of destruction.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.o", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of removable media management requirements.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "09.o", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer details, dates, observations, and corrective actions.", "framework_count": 1}]	18	pending	\N	\N
4615	NCF0135	Data Backup	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.815623	Data Protection & Privacy	ai_normalized	\N	[{"name": "Backup Logs and Reports", "frameworks": [{"code": "PR.IP-4", "framework": "NIST Cybersecurity Framework"}, {"code": "A.8.13", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Periodic reports and logs showing backup job status, success/failure, and remediation actions.", "framework_count": 3}, {"name": "Recovery Test Results", "frameworks": [{"code": "PR.IP-4", "framework": "NIST Cybersecurity Framework"}, {"code": "A.8.13", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of periodic restore tests with success criteria and outcomes.", "framework_count": 3}, {"name": "Backup Policy and Procedures", "frameworks": [{"code": "A.8.13", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive policy defining the scope, frequency, retention, encryption, and testing for backups, including step-by-step instructions and responsible roles.", "framework_count": 2}, {"name": "Backup Inventory and Data Ownership", "frameworks": [{"code": "A.8.13", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Catalogue of backup sets and media, including verification hashes and ownership records.", "framework_count": 2}, {"name": "Backup Schedule and Configuration", "frameworks": [{"code": "A.8.13", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration from backup tools showing jobs, retention, and encryption settings.", "framework_count": 1}, {"name": "RPO/RTO Requirements Documentation", "frameworks": [{"code": "OM 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation demonstrating the implementation of Recovery Point Objective (RPO) and Recovery Time Objective (RTO) requirements.", "framework_count": 1}, {"name": "Offsite/Immutable Backup Evidence", "frameworks": [{"code": "A.8.13", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of offsite replication or immutable/object-lock backup copies following the 3-2-1 rule.", "framework_count": 1}]	18	pending	\N	\N
4616	NCF0136	Backup and Recovery	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.819608	Data Protection & Privacy	ai_normalized	\N	[{"name": "Backup Procedures", "frameworks": [{"code": "6.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "CO-02", "framework": "SOX IT General Controls"}, {"code": "7.7", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation outlining the procedures for performing backups.", "framework_count": 3}, {"name": "Backup Logs", "frameworks": [{"code": "6.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "CO-02", "framework": "SOX IT General Controls"}, {"code": "7.7", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records of backup activities and their statuses.", "framework_count": 3}, {"name": "Recovery Test Results", "frameworks": [{"code": "6.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.7", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Results from tests conducted to verify the recovery process.", "framework_count": 2}, {"name": "Backup Failure Investigation Records", "frameworks": [{"code": "CO-02", "framework": "SOX IT General Controls"}], "description": "Documentation of investigations conducted for backup failures.", "framework_count": 1}, {"name": "Off-site Backup Storage Evidence", "frameworks": [{"code": "CO-02", "framework": "SOX IT General Controls"}], "description": "Proof of backup data stored off-site or remotely.", "framework_count": 1}]	18	pending	\N	\N
4617	NCF0137	Data Leakage Prevention	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.825006	Data Protection & Privacy	ai_normalized	\N	[{"name": "Data Leakage Prevention (DLP) Policy", "frameworks": [{"code": "PR.DS-5", "framework": "NIST Cybersecurity Framework"}, {"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Policy defining the scope, detection strategy, and response for DLP implementation.", "framework_count": 2}, {"name": "DLP Tool Ruleset", "frameworks": [{"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Export of DLP rules covering various channels such as email, endpoint, web, and cloud.", "framework_count": 1}, {"name": "DLP Alert and Investigation Log", "frameworks": [{"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Log of DLP alerts triggered, triaged, and investigated.", "framework_count": 1}, {"name": "DLP Dashboard", "frameworks": [{"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Screenshot of the DLP platform dashboard showing coverage and effectiveness.", "framework_count": 1}, {"name": "USB/Removable Media Control Configuration", "frameworks": [{"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Endpoint control preventing or monitoring data transfers to removable media.", "framework_count": 1}, {"name": "Cloud DLP Configuration", "frameworks": [{"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration of DLP for cloud storage services like Google Drive and OneDrive.", "framework_count": 1}, {"name": "DLP Incident Response Playbook", "frameworks": [{"code": "A.8.12", "framework": "ISO/IEC 27001:2022"}], "description": "Playbook outlining response steps for confirmed data leakage events.", "framework_count": 1}]	18	pending	\N	\N
4618	NCF0138	Information Classification	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.828033	Data Protection & Privacy	ai_normalized	\N	[{"name": "Classification Policy and Guidelines", "frameworks": [{"code": "2.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "A.5.12", "framework": "ISO/IEC 27001:2022"}], "description": "Document outlining the classification levels, handling rules, and guidelines for information classification.", "framework_count": 3}, {"name": "Classified Asset Inventory", "frameworks": [{"code": "AM 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "A.5.12", "framework": "ISO/IEC 27001:2022"}], "description": "Inventory listing classified assets with details such as owner, classification, and status.", "framework_count": 2}, {"name": "Labeling Procedures", "frameworks": [{"code": "2.2", "framework": "SABIC CyberTrust Guidelines"}], "description": "Procedures for labeling classified information according to established classification levels.", "framework_count": 1}, {"name": "Handling Guidelines", "frameworks": [{"code": "2.2", "framework": "SABIC CyberTrust Guidelines"}], "description": "Guidelines detailing how to handle classified information based on its classification level.", "framework_count": 1}, {"name": "Classification Training Materials", "frameworks": [{"code": "A.5.12", "framework": "ISO/IEC 27001:2022"}], "description": "Training materials used to educate staff on proper information classification practices.", "framework_count": 1}, {"name": "Reclassification Review Log", "frameworks": [{"code": "A.5.12", "framework": "ISO/IEC 27001:2022"}], "description": "Log documenting periodic reviews and adjustments of information classifications.", "framework_count": 1}, {"name": "Classification Scheme and Handling Matrix", "frameworks": [{"code": "A.5.12", "framework": "ISO/IEC 27001:2022"}], "description": "Matrix that maps classification levels to specific handling, storage, and disposal rules.", "framework_count": 1}]	18	pending	\N	\N
4619	NCF0139	Secure Data Disposal	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.831408	Data Protection & Privacy	ai_normalized	\N	[{"name": "Disposal Procedures", "frameworks": [{"code": "3.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "5.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "11.1.7", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented procedures for the disposal of data, including step-by-step instructions and responsible roles.", "framework_count": 4}, {"name": "Disposal Verification", "frameworks": [{"code": "3.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "5.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the verification of data disposal, including dates and responsible parties.", "framework_count": 4}, {"name": "Destruction Certificates", "frameworks": [{"code": "3.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "5.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Certificates that verify the destruction of data, including issuance date, scope, and authorized signatory.", "framework_count": 3}, {"name": "Data Sanitization Tool Configuration", "frameworks": [{"code": "AM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration details of data sanitization tools, including screenshots or exports showing the control in effect.", "framework_count": 1}, {"name": "Data Sanitization Checklists", "frameworks": [{"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Completed and signed-off checklists for data sanitization, including evidence references and performers.", "framework_count": 1}, {"name": "Software License Deactivation Records", "frameworks": [{"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the deactivation of software licenses, including dates and responsible parties.", "framework_count": 1}]	18	pending	\N	\N
4621	NCF0141	Incident Detection and Monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.842407	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Incident Management Procedures", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}, {"code": "IR-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Procedures for alert triage, escalation, and incident tracking.", "framework_count": 2}, {"name": "Security Monitoring Documentation", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}], "description": "Comprehensive documentation of security monitoring architecture and detection capability assessments.", "framework_count": 1}, {"name": "SIEM/IDS Configuration Records", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}], "description": "Records detailing the deployment and configuration of SIEM and IDS systems.", "framework_count": 1}, {"name": "Incident Reporting and Analysis", "frameworks": [{"code": "IR-5", "framework": "NIST SP 800-53 Rev 5"}], "description": "Reports on incident logs and trend analysis for incidents.", "framework_count": 1}]	18	pending	\N	\N
4622	NCF0142	Audit Logging	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.845749	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Logging Policy and Configuration", "frameworks": [{"code": "PR.PT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "OM 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.aa", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive documentation of logging policies, configurations, and standards for audit logging.", "framework_count": 3}, {"name": "Log Review Procedures and Records", "frameworks": [{"code": "PR.PT-1", "framework": "NIST Cybersecurity Framework"}, {"code": "OM 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.aa", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures and records for log review, including schedules and follow-up actions.", "framework_count": 3}, {"name": "Log Tamper Protection Evidence", "frameworks": [{"code": "OM 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Evidence of mechanisms in place to protect logs from tampering, including hashing and WORM.", "framework_count": 1}]	18	pending	\N	\N
4623	NCF0143	Event Logging	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.849747	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Auditable Events and Logging Policy", "frameworks": [{"code": "AU-2", "framework": "NIST SP 800-53 Rev 5"}, {"code": "CC7.6", "framework": "SOC 2 Type II"}], "description": "A comprehensive document outlining auditable events and the logging policy, including defined security events to capture.", "framework_count": 2}, {"name": "Audit Logging Configuration", "frameworks": [{"code": "AU-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Configuration settings for audit logging to ensure proper logging of events.", "framework_count": 1}, {"name": "Event Logging Rationale Documentation", "frameworks": [{"code": "AU-2", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation explaining the rationale behind event logging practices.", "framework_count": 1}, {"name": "Log Integrity Protection Mechanisms", "frameworks": [{"code": "CC7.6", "framework": "SOC 2 Type II"}], "description": "Mechanisms in place to protect log integrity, such as write-once storage and checksums.", "framework_count": 1}, {"name": "Log Retention Configuration", "frameworks": [{"code": "CC7.6", "framework": "SOC 2 Type II"}], "description": "Configuration for log retention along with compliance evidence for retention policies.", "framework_count": 1}, {"name": "Log Review Procedures", "frameworks": [{"code": "CC7.6", "framework": "SOC 2 Type II"}], "description": "Procedures for reviewing logs along with sample records of log reviews.", "framework_count": 1}]	18	pending	\N	\N
4624	NCF0144	Logging and Monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.85375	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Log Retention Policy", "frameworks": [{"code": "4.1", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "6.5", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.5", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "ELC-07", "framework": "SOX IT General Controls"}, {"code": "Article 21(2)(b)(f)", "framework": "NIS2 Directive"}], "description": "Policies and settings governing the retention of logs.", "framework_count": 5}, {"name": "Logging Configuration", "frameworks": [{"code": "4.1", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "6.5", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.5", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "ELC-07", "framework": "SOX IT General Controls"}], "description": "Documentation of logging configuration settings for systems.", "framework_count": 4}, {"name": "Monitoring Procedures", "frameworks": [{"code": "6.5", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.5", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "Article 21(2)(b)(f)", "framework": "NIS2 Directive"}], "description": "Documentation of procedures for monitoring logs and alerts.", "framework_count": 3}, {"name": "SIEM Integration Evidence", "frameworks": [{"code": "4.1", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "ELC-07", "framework": "SOX IT General Controls"}], "description": "Evidence of integration with a Security Information and Event Management system.", "framework_count": 2}, {"name": "Log Review Records", "frameworks": [{"code": "4.1", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "Article 21(2)(b)(f)", "framework": "NIS2 Directive"}], "description": "Records of log reviews conducted to ensure compliance and security.", "framework_count": 2}]	18	pending	\N	\N
4625	NCF0145	Monitoring System Use	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.860253	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Monitoring Procedures and Reports", "frameworks": [{"code": "13.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation of monitoring procedures and associated reports to ensure compliance and effectiveness.", "framework_count": 1}, {"name": "Monitoring System Use Policy", "frameworks": [{"code": "09.ab", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and standard addressing Monitoring System Use, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Monitoring System Use Procedures", "frameworks": [{"code": "09.ab", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions for implementing Monitoring System Use with detailed steps and responsibilities.", "framework_count": 1}, {"name": "Audit Logging Configuration Evidence", "frameworks": [{"code": "09.ab", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of audit logging configuration, including events captured, retention, and tamper protection measures.", "framework_count": 1}, {"name": "Log Review Records", "frameworks": [{"code": "09.ab", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of log reviews and follow-up case documentation, including timestamps and actor identities.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.ab", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of monitoring requirements, including attendee lists and delivery dates.", "framework_count": 1}]	18	pending	\N	\N
4627	NCF0147	Security Controls Monitoring	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.866615	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "Security Controls Monitoring Mechanism", "frameworks": [{"code": "2.3", "framework": "SBP Internet Banking Framework"}], "description": "Formally approved document detailing the monitoring mechanism for security controls, including scope, methods, roles, and reporting.", "framework_count": 1}, {"name": "Monitoring Method Effectiveness Analysis", "frameworks": [{"code": "2.3", "framework": "SBP Internet Banking Framework"}], "description": "Analysis report evaluating the effectiveness of existing or proposed security controls monitoring methods.", "framework_count": 1}, {"name": "Monitoring Coverage Map", "frameworks": [{"code": "2.3", "framework": "SBP Internet Banking Framework"}], "description": "Map illustrating the coverage of monitoring methods against each baseline security control area.", "framework_count": 1}, {"name": "System Monitoring Strategy", "frameworks": [{"code": "SI-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Document outlining the strategy for system monitoring as per NIST guidelines.", "framework_count": 1}, {"name": "IDS/IPS Configuration", "frameworks": [{"code": "SI-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation of the configuration settings for Intrusion Detection and Prevention Systems.", "framework_count": 1}, {"name": "SIEM Deployment Documentation", "frameworks": [{"code": "SI-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation detailing the deployment of Security Information and Event Management systems.", "framework_count": 1}, {"name": "Monitoring Alert Review Records", "frameworks": [{"code": "SI-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of reviews conducted on alerts generated by monitoring systems.", "framework_count": 1}]	18	pending	\N	\N
4629	NCF0149	Multi-factor Authentication	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.877016	Logging, Monitoring & Detection	ai_normalized	\N	[{"name": "MFA Configuration and Implementation Documentation", "frameworks": [{"code": "3.3", "framework": "SWIFT Customer Security Controls Framework"}, {"code": "Article 21(2)(j)", "framework": "NIS2 Directive"}, {"code": "9.1.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation detailing the configuration, implementation, and enrollment of Multi-Factor Authentication (MFA) systems.", "framework_count": 3}, {"name": "MFA Coverage Assessment", "frameworks": [{"code": "Article 21(2)(j)", "framework": "NIS2 Directive"}, {"code": "9.1.5", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Assessment records evaluating the coverage of MFA for critical and sensitive systems.", "framework_count": 2}, {"name": "Token/Device Inventory", "frameworks": [{"code": "3.3", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Inventory records of tokens or devices used for MFA.", "framework_count": 1}, {"name": "Authentication Logs", "frameworks": [{"code": "3.3", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Logs documenting authentication attempts and activities.", "framework_count": 1}, {"name": "Secured Communications Solution Documentation", "frameworks": [{"code": "Article 21(2)(j)", "framework": "NIS2 Directive"}], "description": "Documentation for secured communication solutions related to MFA.", "framework_count": 1}, {"name": "Emergency Communication System Testing Records", "frameworks": [{"code": "Article 21(2)(j)", "framework": "NIS2 Directive"}], "description": "Records of tests conducted on emergency communication systems.", "framework_count": 1}]	18	pending	\N	\N
4630	NCF0150	Backup Management and Data Recovery	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.880014	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Backup Policy and Procedures", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}, {"code": "DO.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}, {"code": "7.4", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Comprehensive documentation of backup policies, procedures, and schedules including retention periods.", "framework_count": 3}, {"name": "Backup Testing and Verification", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}, {"code": "7.4", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Results and logs from backup restoration tests and verification processes.", "framework_count": 2}, {"name": "Offsite Backup Storage Documentation", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}], "description": "Documentation detailing offsite or offline backup storage practices.", "framework_count": 1}, {"name": "Backup Recovery Point Objective (RPO) Verification", "frameworks": [{"code": "Article 21(2)(c)", "framework": "NIS2 Directive"}], "description": "Records verifying alignment with Recovery Point Objectives.", "framework_count": 1}, {"name": "Backup Access Controls", "frameworks": [{"code": "7.4", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Documentation of access controls related to backup systems.", "framework_count": 1}, {"name": "Implementation Evidence for Data Backup Recovery", "frameworks": [{"code": "DO.4.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records demonstrating the implementation and outcomes of data backup recovery processes.", "framework_count": 1}]	18	pending	\N	\N
4631	NCF0151	Test recovery dependencies between systems	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.884305	Business Continuity & Resilience	ai_normalized	\N	[{"name": "Dependency Test Records and Results", "frameworks": [{"code": "5.3.2.d", "framework": "SBP ETGRMF"}], "description": "Records and results of recovery dependency tests between systems, including evidence of successful interdependent recovery and updated system dependency maps.", "framework_count": 1}, {"name": "Backup Recovery Test Results", "frameworks": [{"code": "CIS Control 11 - Safeguard 11.5", "framework": "CIS Critical Security Controls v8"}], "description": "Results and documentation related to backup recovery tests, including test schedules and recovery time verification records.", "framework_count": 1}]	18	pending	\N	\N
4632	NCF0152	Asset Management and Classification	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.890304	Asset Management	ai_normalized	\N	[{"name": "Asset Inventory and Classification", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "2.4.1", "framework": "SBP ETGRMF"}], "description": "Comprehensive inventory of all information assets with ownership, classification, and retention schedule.", "framework_count": 2}, {"name": "Information Classification Policy", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}, {"code": "2.4.1", "framework": "SBP ETGRMF"}], "description": "Policy defining classification levels and handling guidelines for information assets.", "framework_count": 2}, {"name": "Asset Discovery and Reconciliation Records", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}], "description": "Records documenting the discovery and reconciliation of information assets.", "framework_count": 1}, {"name": "End-of-Life and Decommissioning Procedures", "frameworks": [{"code": "Article 21(2)(i)", "framework": "NIS2 Directive"}], "description": "Procedures for the end-of-life and decommissioning of information assets.", "framework_count": 1}, {"name": "Data Owner Register", "frameworks": [{"code": "2.4.1", "framework": "SBP ETGRMF"}], "description": "Register of information owners responsible for the confidentiality, integrity, and availability of assigned assets.", "framework_count": 1}, {"name": "Secure Disposal and Destruction Procedures", "frameworks": [{"code": "2.4.1", "framework": "SBP ETGRMF"}], "description": "Standard Operating Procedures for the secure disposal and destruction of information assets.", "framework_count": 1}, {"name": "Disposal Certificates", "frameworks": [{"code": "2.4.1", "framework": "SBP ETGRMF"}], "description": "Certificates documenting the secure disposal or destruction of information assets.", "framework_count": 1}]	18	pending	\N	\N
4633	NCF0153	Asset Inventory	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.894605	Asset Management	ai_normalized	\N	[{"name": "Asset Inventory", "frameworks": [{"code": "3.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "2.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "3.3.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "A comprehensive list of information assets including details such as entity/item name, owner, classification, and status.", "framework_count": 4}, {"name": "Asset Ownership Records", "frameworks": [{"code": "3.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "2.1", "framework": "SABIC CyberTrust Guidelines"}], "description": "Documentation that identifies the ownership of each asset within the inventory.", "framework_count": 2}, {"name": "Periodic Inventory Reconciliation Reports", "frameworks": [{"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "3.3.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Reports generated periodically to reconcile the asset inventory, ensuring accuracy and completeness.", "framework_count": 2}, {"name": "Classification Assignments", "frameworks": [{"code": "3.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records detailing the classification of each asset based on its sensitivity and importance.", "framework_count": 1}, {"name": "Inventory Update Procedures", "frameworks": [{"code": "2.1", "framework": "SABIC CyberTrust Guidelines"}], "description": "Procedures outlining how the asset inventory is updated and maintained.", "framework_count": 1}, {"name": "Asset Inventory Update Logs", "frameworks": [{"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs that track changes made to the asset inventory, including timestamps and actions performed.", "framework_count": 1}, {"name": "Asset-to-Service Mapping/Relationship Diagrams", "frameworks": [{"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Diagrams that illustrate the relationships between assets and services, including interconnections and data flows.", "framework_count": 1}]	18	pending	\N	\N
4634	NCF0154	Inventory of Assets	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.898605	Asset Management	ai_normalized	\N	[{"name": "Asset Inventory Register", "frameworks": [{"code": "07.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "4.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "A comprehensive asset inventory register that includes classification, ownership, location, and lifecycle status of assets.", "framework_count": 2}, {"name": "Approved Asset Inventory Policy", "frameworks": [{"code": "07.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "A documented policy and standard addressing the inventory of assets, including details such as entity/item name, owner, classification, status, and review date.", "framework_count": 1}, {"name": "Asset Classification Records", "frameworks": [{"code": "4.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records detailing the classification of assets to ensure proper handling and security measures.", "framework_count": 1}, {"name": "Asset Ownership Assignments", "frameworks": [{"code": "4.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation of ownership assignments for assets to clarify responsibility and accountability.", "framework_count": 1}, {"name": "Asset Tracking Procedures", "frameworks": [{"code": "4.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documented procedures for tracking assets throughout their lifecycle to maintain accurate inventory.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "07.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications that inform personnel of asset inventory requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "07.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of the asset inventory, including reviewer details, observations, and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4636	NCF0156	Equipment Maintenance	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.910074	Asset Management	ai_normalized	\N	[{"name": "Approved Equipment Maintenance Policy", "frameworks": [{"code": "08.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Equipment Maintenance, including scope, applicability, roles, and responsibilities.", "framework_count": 1}, {"name": "Documented Equipment Maintenance Procedure", "frameworks": [{"code": "08.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedure or work instruction implementing Equipment Maintenance with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Physical Access Logs", "frameworks": [{"code": "08.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Logs of physical access (badge/biometric) and visitor register preserved for retention, protected from tampering.", "framework_count": 1}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "08.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of CCTV deployment and footage retention records demonstrating activity occurrence with relevant details.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "08.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating personnel awareness of requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.j", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions.", "framework_count": 1}, {"name": "Equipment Maintenance Schedule", "frameworks": [{"code": "A.7.13", "framework": "ISO/IEC 27001:2022"}], "description": "Planned maintenance schedule covering all critical equipment with specified intervals.", "framework_count": 1}, {"name": "Maintenance Work Order History", "frameworks": [{"code": "A.7.13", "framework": "ISO/IEC 27001:2022"}], "description": "History of work orders showing preventive and corrective maintenance performed.", "framework_count": 1}, {"name": "Authorized Maintenance Personnel List", "frameworks": [{"code": "A.7.13", "framework": "ISO/IEC 27001:2022"}], "description": "List of approved internal and vendor engineers permitted to maintain equipment.", "framework_count": 1}, {"name": "Maintenance Supervision Records", "frameworks": [{"code": "A.7.13", "framework": "ISO/IEC 27001:2022"}], "description": "Records showing vendor engineers supervised while on site.", "framework_count": 1}, {"name": "Warranty and Support Contracts", "frameworks": [{"code": "A.7.13", "framework": "ISO/IEC 27001:2022"}], "description": "Active support agreements with OEMs for critical equipment.", "framework_count": 1}, {"name": "Data Sanitization Before Maintenance Records", "frameworks": [{"code": "A.7.13", "framework": "ISO/IEC 27001:2022"}], "description": "Records showing sensitive data removed or protected before equipment leaves for repair.", "framework_count": 1}]	18	pending	\N	\N
4637	NCF0157	Return of Assets	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.913488	Asset Management	ai_normalized	\N	[{"name": "Asset Return Documentation", "frameworks": [{"code": "A.5.11", "framework": "ISO/IEC 27001:2022"}], "description": "Comprehensive documentation related to the return of assets from leavers, including checklists, forms, and reconciliation reports.", "framework_count": 1}, {"name": "Return of Assets Policy and Procedures", "frameworks": [{"code": "02.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policy and documented procedures addressing the return of assets, including roles and responsibilities.", "framework_count": 1}, {"name": "Third-party Security Agreements", "frameworks": [{"code": "02.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Agreements with third parties that include security clauses, SLAs, and rights to audit.", "framework_count": 1}, {"name": "Third-party Risk Assessment Records", "frameworks": [{"code": "02.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of third-party risk assessments and ongoing monitoring activities.", "framework_count": 1}, {"name": "Access Termination Workflow Records", "frameworks": [{"code": "02.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating the access termination process with timing metrics against SLAs.", "framework_count": 1}, {"name": "Session Configuration Evidence", "frameworks": [{"code": "02.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of session timeout, idle lockout, and re-authentication configurations.", "framework_count": 1}, {"name": "BYOD Data Wipe Certificate", "frameworks": [{"code": "A.5.11", "framework": "ISO/IEC 27001:2022"}], "description": "Certificate issued for the selective wipe of personal devices used for work.", "framework_count": 1}]	18	pending	\N	\N
4638	NCF0158	Capacity Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.918485	Asset Management	ai_normalized	\N	[{"name": "Capacity Monitoring Reports", "frameworks": [{"code": "OM 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "6.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "8.1.3", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Reports that include scope, methodology, findings, and recommendations related to capacity monitoring.", "framework_count": 3}, {"name": "Capacity Planning Documentation", "frameworks": [{"code": "09.h", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "6.7", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.6", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation covering current and forecast capacity for critical resources, including planning and monitoring records.", "framework_count": 3}, {"name": "Approved Capacity Management Policy", "frameworks": [{"code": "09.h", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "OM 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved policy and standard addressing Capacity Management, including scope, applicability, and roles.", "framework_count": 2}, {"name": "Documented Capacity Management Procedures", "frameworks": [{"code": "09.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures or work instructions implementing Capacity Management with step-by-step instructions and responsible roles.", "framework_count": 1}, {"name": "Risk Register", "frameworks": [{"code": "09.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Risk register with entries, owners, ratings, and treatment plans, including entity/item name and status.", "framework_count": 1}, {"name": "Capacity Threshold and Escalation Matrix", "frameworks": [{"code": "OM 3.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Matrix identifying owners, responsibilities, and escalation paths for capacity thresholds.", "framework_count": 1}, {"name": "Capacity Trend Report", "frameworks": [{"code": "A.8.6", "framework": "ISO/IEC 27001:2022"}], "description": "Trend report showing utilization over time and projected breach points.", "framework_count": 1}, {"name": "Capacity Incident Log", "frameworks": [{"code": "A.8.6", "framework": "ISO/IEC 27001:2022"}], "description": "Log of capacity-related incidents and mitigation actions taken.", "framework_count": 1}, {"name": "Scaling Test Results", "frameworks": [{"code": "A.8.6", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of load/scaling tests demonstrating the ability to meet forecast demand.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of capacity management requirements.", "framework_count": 1}]	18	pending	\N	\N
4639	NCF0159	Clock Synchronization	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.925958	Asset Management	ai_normalized	\N	[{"name": "NTP Server Configuration and Policy", "frameworks": [{"code": "OM 6.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "09.af", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Extract or screenshot of the live NTP server configuration along with an approved policy addressing clock synchronization, including security clauses and scope.", "framework_count": 2}, {"name": "Time Synchronization Status Reports", "frameworks": [{"code": "OM 6.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive reports detailing the time synchronization status, including methodology, findings, and management responses.", "framework_count": 1}, {"name": "Medical Device Clock Synchronization Records", "frameworks": [{"code": "OM 6.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating clock synchronization activities for medical devices, including dates and responsible personnel.", "framework_count": 1}, {"name": "Documented Procedure for Clock Synchronization", "frameworks": [{"code": "09.af", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure or work instruction for implementing clock synchronization, including responsible roles and control points.", "framework_count": 1}, {"name": "Awareness Communications for Clock Synchronization", "frameworks": [{"code": "09.af", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications that inform personnel about clock synchronization requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "09.af", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews related to clock synchronization, including observations and corrective actions taken.", "framework_count": 1}]	18	pending	\N	\N
4640	NCF0160	Monitoring and Review of Third Party Services	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.930971	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third Party Audit Reports", "frameworks": [{"code": "3.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "TP 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports from third-party audits including scope, methodology, findings, and management responses.", "framework_count": 2}, {"name": "Service Review and Performance Monitoring Records", "frameworks": [{"code": "3.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "TP 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the review and performance monitoring of third-party services, including findings and recommendations.", "framework_count": 2}, {"name": "Compliance Verification Records", "frameworks": [{"code": "3.4", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records verifying compliance with established standards and policies.", "framework_count": 1}, {"name": "Approved Policies and Procedures for Monitoring and Review", "frameworks": [{"code": "09.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policies and documented procedures for monitoring and reviewing third-party services.", "framework_count": 1}, {"name": "Audit Logging and Review Records", "frameworks": [{"code": "09.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of audit logging configuration and log review records, including retention and tamper protection.", "framework_count": 1}, {"name": "Audit Plans and Reports", "frameworks": [{"code": "09.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Audit plans and reports detailing scope, findings, and remediation tracking.", "framework_count": 1}, {"name": "Third-Party Agreements", "frameworks": [{"code": "09.f", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Agreements with third parties that include security clauses, SLAs, and rights to audit.", "framework_count": 1}, {"name": "Third Party Compliance Monitoring Records", "frameworks": [{"code": "TP 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating compliance monitoring activities for third parties.", "framework_count": 1}, {"name": "Incident Records Related to Third Parties", "frameworks": [{"code": "TP 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of incidents involving third parties, including details of the activity.", "framework_count": 1}, {"name": "Third Party Risk Assessments", "frameworks": [{"code": "TP 2.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Assessments of risks associated with third parties, including findings and treatment decisions.", "framework_count": 1}]	18	pending	\N	\N
4648	NCF0168	Security Requirements Analysis and Specification	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.976175	Application & Software Security	ai_normalized	\N	[{"name": "Security Requirements Documentation", "frameworks": [{"code": "13.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "SA 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Comprehensive documentation outlining security requirements for systems and projects.", "framework_count": 2}, {"name": "Business Requirements with Security", "frameworks": [{"code": "13.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "SA 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation that includes business requirements alongside security considerations.", "framework_count": 2}, {"name": "Requirements Review Records", "frameworks": [{"code": "13.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "10.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating the review of security and business requirements.", "framework_count": 2}, {"name": "Security Specifications", "frameworks": [{"code": "13.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "10.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Detailed specifications that outline security measures and controls.", "framework_count": 2}, {"name": "Documented Procedures for Security Requirements Analysis", "frameworks": [{"code": "10.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step procedures for conducting security requirements analysis.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications that inform personnel about security requirements.", "framework_count": 1}, {"name": "Risk Assessment Outputs Linked to Security Requirements", "frameworks": [{"code": "SA 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Outputs from risk assessments that are directly linked to security requirements.", "framework_count": 1}, {"name": "System Acceptance Criteria Documentation", "frameworks": [{"code": "SA 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation outlining the criteria for system acceptance related to security.", "framework_count": 1}]	18	pending	\N	\N
4642	NCF0162	Third Party Security Policy	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.941579	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Approved Third Party Security Policy", "frameworks": [{"code": "TP 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved, current version of the Third Party Security Policy, including scope, applicability, roles and responsibilities.", "framework_count": 1}, {"name": "Third Party Security Framework Documentation", "frameworks": [{"code": "TP 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating implementation of the third party security control, with date, owner, and reference to related policies.", "framework_count": 1}, {"name": "Documented Third Party Supplier Security Artifacts", "frameworks": [{"code": "DS.5", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented artifacts addressing Third Party Supplier Security under NCA regulations, preserved for the required retention period.", "framework_count": 1}, {"name": "NCA Assessment/Compliance Records", "frameworks": [{"code": "DS.5", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records of assessments/compliance conducted by NCA, demonstrating the activity occurred, including date, performer, and approver where applicable.", "framework_count": 1}]	18	pending	\N	\N
4643	NCF0163	Third-Party and Service Organization Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.954909	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third-party service provider inventory and agreements", "frameworks": [{"code": "ELC-06", "framework": "SOX IT General Controls"}, {"code": "TP 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of third-party service provider inventory, including agreements with security clauses and audit rights.", "framework_count": 2}, {"name": "Vendor risk assessment and service-specific requirements", "frameworks": [{"code": "ELC-06", "framework": "SOX IT General Controls"}, {"code": "TP 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of vendor risk assessments and service-specific security requirements documentation demonstrating control implementation.", "framework_count": 2}, {"name": "SLA monitoring reports", "frameworks": [{"code": "TP 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports detailing SLA monitoring, including scope, methodology, findings, and management responses.", "framework_count": 1}, {"name": "Third party relationship management roles", "frameworks": [{"code": "TP 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation demonstrating the implementation of third party relationship management roles, including date, owner, and related policy references.", "framework_count": 1}, {"name": "Information access type documentation", "frameworks": [{"code": "TP 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records detailing information access types per third party, including implementation details such as date and owner.", "framework_count": 1}]	18	pending	\N	\N
4644	NCF0164	Addressing Security in Third Party Agreements	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.959422	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Third Party Agreements and Contracts", "frameworks": [{"code": "3.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "05.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Includes third party contract templates, signed vendor agreements, security clauses in agreements, and NDA records.", "framework_count": 2}, {"name": "Third Party Risk Assessment Records", "frameworks": [{"code": "05.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of third-party risk assessments and ongoing monitoring activities.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "05.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that personnel are informed of third-party security requirements.", "framework_count": 1}]	18	pending	\N	\N
4645	NCF0165	Service Delivery	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.963853	Third-Party & Supply Chain Risk	ai_normalized	\N	[{"name": "Service Level Agreements and Security Requirements", "frameworks": [{"code": "3.3", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "09.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of service level agreements that include security requirements and performance monitoring.", "framework_count": 2}, {"name": "Approved Service Delivery Policy", "frameworks": [{"code": "09.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing service delivery, including scope and roles.", "framework_count": 1}, {"name": "Documented Procedures for Service Delivery", "frameworks": [{"code": "09.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedures or work instructions for implementing service delivery.", "framework_count": 1}, {"name": "Third-party Risk Assessment and Monitoring", "frameworks": [{"code": "09.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of third-party risk assessments and ongoing monitoring activities.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.e", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of service delivery requirements.", "framework_count": 1}]	18	pending	\N	\N
4646	NCF0166	Secure Coding Standards	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.966853	Application & Software Security	ai_normalized	\N	[{"name": "Secure Coding Standards Document", "frameworks": [{"code": "6.1.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Document outlining secure coding standards and guidelines for developers.", "framework_count": 2}, {"name": "Code Review Procedures", "frameworks": [{"code": "6.1.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Procedures and checklists used for conducting code reviews with a focus on security.", "framework_count": 2}, {"name": "Static Application Security Testing Reports", "frameworks": [{"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Reports from static application security testing conducted per release.", "framework_count": 1}, {"name": "Dynamic Application Security Testing Reports", "frameworks": [{"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Reports from dynamic application security testing for web applications.", "framework_count": 1}, {"name": "Software Composition Analysis Reports", "frameworks": [{"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Reports showing vulnerable dependencies identified through software composition analysis.", "framework_count": 1}, {"name": "Secure Coding Training Records", "frameworks": [{"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Records of developer training completion for secure coding practices.", "framework_count": 1}, {"name": "Build Pipeline Security Gates", "frameworks": [{"code": "A.8.28", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration of build pipelines that enforce security checks and break builds on critical findings.", "framework_count": 1}]	18	pending	\N	\N
4647	NCF0167	System Design and Architecture Review	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.973181	Application & Software Security	ai_normalized	\N	[{"name": "Design Specification Documents", "frameworks": [{"code": "PD-03", "framework": "SOX IT General Controls"}, {"code": "5.6.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documents outlining the design specifications for IT controls.", "framework_count": 2}, {"name": "Design Review Meeting Minutes", "frameworks": [{"code": "PD-03", "framework": "SOX IT General Controls"}, {"code": "5.6.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Minutes from meetings held to review the design of IT controls.", "framework_count": 2}, {"name": "Security Review Checklist Completion", "frameworks": [{"code": "PD-03", "framework": "SOX IT General Controls"}], "description": "Records of completed security review checklists for IT controls.", "framework_count": 1}, {"name": "Issue Tracking and Resolution Records", "frameworks": [{"code": "PD-03", "framework": "SOX IT General Controls"}], "description": "Records tracking issues identified during the design and their resolutions.", "framework_count": 1}]	18	pending	\N	\N
4651	NCF0171	Configuration Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.989468	Configuration & Change Management	ai_normalized	\N	[{"name": "Configuration Management Policy and Procedures", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}, {"code": "7.2.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Policy and procedures defining configuration standards, baselines, and change controls.", "framework_count": 2}, {"name": "Configuration Baseline Documentation", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}], "description": "Baseline configurations (CIS, STIG, internal) for each platform in use.", "framework_count": 1}, {"name": "Configuration Compliance Scan Report", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}], "description": "Compliance scan results vs. baselines (e.g., Tenable.sc, Chef InSpec, AWS Config).", "framework_count": 1}, {"name": "Infrastructure-as-Code Repositories", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of IaC repos (Terraform, Ansible) enforcing configuration consistency.", "framework_count": 1}, {"name": "Configuration Drift Alerts", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}], "description": "Alert configuration and examples of drift detected and remediated.", "framework_count": 1}, {"name": "Hardening Sign-off Records", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}], "description": "Sign-off records for systems before production deployment confirming baseline applied.", "framework_count": 1}, {"name": "Golden Image Documentation", "frameworks": [{"code": "A.8.9", "framework": "ISO/IEC 27001:2022"}], "description": "Documentation of approved golden images for servers and workstations.", "framework_count": 1}, {"name": "Configuration Management Database (CMDB)", "frameworks": [{"code": "7.2.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Database containing configuration items and their relationships.", "framework_count": 1}]	18	pending	\N	\N
4652	NCF0172	Control of Operational Software	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.993916	Configuration & Change Management	ai_normalized	\N	[{"name": "Approved Policy and Standard for Operational Software", "frameworks": [{"code": "10.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board/management-approved policy and standard addressing Control of Operational Software, including scope, applicability, and roles.", "framework_count": 1}, {"name": "Documented Procedure for Operational Software Control", "frameworks": [{"code": "10.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Step-by-step documented procedure or work instruction implementing Control of Operational Software, including responsible roles.", "framework_count": 1}, {"name": "Configuration Baseline Documentation", "frameworks": [{"code": "10.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documentation of configuration baseline with hardening standards, including extracts or screenshots of live configurations.", "framework_count": 1}, {"name": "Awareness Communications Records", "frameworks": [{"code": "10.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating that personnel are informed of the requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.h", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews including reviewer, date, observations, and corrective actions.", "framework_count": 1}, {"name": "Authorized Software Installer List", "frameworks": [{"code": "SA 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "List of authorized software installers demonstrating implementation of the control, with date and owner.", "framework_count": 1}, {"name": "Software Repository with Version History", "frameworks": [{"code": "SA 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Repository demonstrating implementation of the control with version history, date, and owner.", "framework_count": 1}, {"name": "Production Software Change Records", "frameworks": [{"code": "SA 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating production software changes, including date, performer, and approver.", "framework_count": 1}, {"name": "Software Installation Approval Logs", "frameworks": [{"code": "SA 5.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of software installation approvals preserved for retention, protected from tampering, with timestamps and actor identity.", "framework_count": 1}, {"name": "Software Installation Policy", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Policy outlining permitted software, installation rights, and approval processes.", "framework_count": 1}, {"name": "Approved Software Catalogue", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Catalogue of approved software available via self-service or deployment tools.", "framework_count": 1}, {"name": "Software Deployment Tool Configuration", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Configuration of tools controlling software distribution, such as SCCM or Intune.", "framework_count": 1}, {"name": "Non-Admin User Configuration Evidence", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence showing that standard users lack rights to install arbitrary software.", "framework_count": 1}, {"name": "Installed Software Inventory", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Report comparing installed software against the approved catalogue.", "framework_count": 1}, {"name": "Software Installation Approval Records", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Records of approvals for non-standard software installation requests.", "framework_count": 1}, {"name": "Shadow IT Discovery Report", "frameworks": [{"code": "A.8.19", "framework": "ISO/IEC 27001:2022"}], "description": "Report identifying unauthorized applications from CASB or discovery tools.", "framework_count": 1}]	18	pending	\N	\N
4653	NCF0173	Change Management Policy and Procedures	\N	\N	\N	\N	\N	0	2026-06-21 08:17:38.997913	Configuration & Change Management	ai_normalized	\N	[{"name": "Change Management Policy", "frameworks": [{"code": "CM-01", "framework": "SOX IT General Controls"}, {"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "7.5.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "6.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Approved policy document outlining change management processes and responsibilities.", "framework_count": 7}, {"name": "Change Management Procedures", "frameworks": [{"code": "CM-01", "framework": "SOX IT General Controls"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "7.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures detailing how changes are requested, assessed, approved, implemented, and reviewed.", "framework_count": 6}, {"name": "Change Request Records", "frameworks": [{"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "7.5.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Records of change requests including approvals and impact assessments.", "framework_count": 5}, {"name": "Change Approval Records", "frameworks": [{"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Documentation of approvals for changes, including CAB meeting minutes.", "framework_count": 4}, {"name": "Post-Implementation Review Records", "frameworks": [{"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Records demonstrating the review of changes after implementation.", "framework_count": 4}, {"name": "Rollback/Back-out Plans", "frameworks": [{"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented plans for rolling back changes if necessary.", "framework_count": 3}, {"name": "Change Records", "frameworks": [{"code": "6.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive records of changes made, including risk classifications.", "framework_count": 3}, {"name": "Awareness Communications", "frameworks": [{"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of change management requirements.", "framework_count": 2}, {"name": "Compliance Audit Reports", "frameworks": [{"code": "DAM.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Reports and records demonstrating compliance with change management standards.", "framework_count": 1}, {"name": "Data Architecture Artifacts", "frameworks": [{"code": "DAM.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documentation of data architecture relevant to change management.", "framework_count": 1}]	18	pending	\N	\N
4655	NCF0175	Emergency Change Procedures	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.011546	Configuration & Change Management	ai_normalized	\N	[{"name": "Emergency Change Management Documentation", "frameworks": [{"code": "CM-06", "framework": "SOX IT General Controls"}, {"code": "7.5.6", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documentation outlining procedures and records for managing emergency changes.", "framework_count": 2}, {"name": "Emergency Change Tickets and Approvals", "frameworks": [{"code": "CM-06", "framework": "SOX IT General Controls"}, {"code": "7.5.6", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records of emergency change tickets along with any retroactive approvals.", "framework_count": 2}, {"name": "Post-Implementation Review Records", "frameworks": [{"code": "CM-06", "framework": "SOX IT General Controls"}], "description": "Records documenting the review process following the implementation of emergency changes.", "framework_count": 1}, {"name": "Emergency Change Frequency Analysis", "frameworks": [{"code": "CM-06", "framework": "SOX IT General Controls"}], "description": "Analysis of the frequency of emergency changes made over a specified period.", "framework_count": 1}]	18	pending	\N	\N
4656	NCF0176	Patch Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.014553	Configuration & Change Management	ai_normalized	\N	[{"name": "Patch Management Policy", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}, {"code": "7.4.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "7.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive policy outlining patch management procedures, including roles, responsibilities, and exception handling.", "framework_count": 4}, {"name": "Patch Deployment Reports", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}, {"code": "7.4.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of patch deployment activities, including compliance with SLAs and timelines.", "framework_count": 3}, {"name": "Patch Assessment and Testing Records", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of patch assessment and testing activities, including dates, performers, and approvers.", "framework_count": 2}, {"name": "Patch Compliance Reports", "frameworks": [{"code": "7.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports detailing compliance status of patches, including findings and recommendations.", "framework_count": 2}, {"name": "Missing Patch Exception Documentation", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}], "description": "Documentation for any exceptions to patching requirements, including justification and approval.", "framework_count": 1}, {"name": "Patching Records", "frameworks": [{"code": "7.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Comprehensive logs of patching activities, including timestamps and actions performed.", "framework_count": 1}, {"name": "Critical Patch SLA Tracking", "frameworks": [{"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Tracking documentation for critical patches, including security clauses and obligations.", "framework_count": 1}, {"name": "Firmware Update Logs", "frameworks": [{"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of firmware updates, preserved with timestamps and action details.", "framework_count": 1}]	18	pending	\N	\N
4657	NCF0177	Vulnerability Management	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.01955	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Vulnerability Scan Reports", "frameworks": [{"code": "6.4", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Reports detailing the results of vulnerability scans conducted on systems and networks.", "framework_count": 2}, {"name": "Remediation Tracking", "frameworks": [{"code": "6.4", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation tracking the remediation efforts for identified vulnerabilities.", "framework_count": 2}, {"name": "Patching Records", "frameworks": [{"code": "6.4", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records of patches applied to systems to address vulnerabilities.", "framework_count": 2}]	18	pending	\N	\N
4658	NCF0178	Identify and Manage Security Vulnerabilities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.025863	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Vulnerability Management Documentation", "frameworks": [{"code": "6.3.1", "framework": "PCI Data Security Standard"}], "description": "Comprehensive documentation covering vulnerability management procedures, risk ranking methodologies, and intelligence sources.", "framework_count": 1}, {"name": "Vulnerability Tracking Records", "frameworks": [{"code": "6.3.1", "framework": "PCI Data Security Standard"}], "description": "Sample records from the vulnerability tracking system detailing identification sources, severity, owner, and status.", "framework_count": 1}]	18	pending	\N	\N
4659	NCF0179	Control of Technical Vulnerabilities	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.02886	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Vulnerability Management Policy", "frameworks": [{"code": "10.m", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Policy covering scanning cadence, SLAs, prioritisation and exception handling.", "framework_count": 2}, {"name": "Vulnerability Remediation Procedures", "frameworks": [{"code": "13.13", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "10.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Procedures for identifying and addressing vulnerabilities.", "framework_count": 2}, {"name": "Vulnerability Scanning Reports", "frameworks": [{"code": "10.m", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Periodic scan reports covering internal and external assets with remediation tracking.", "framework_count": 2}, {"name": "Patch Management Records", "frameworks": [{"code": "10.m", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Records of patches deployed per system with success/failure and rollback evidence.", "framework_count": 2}, {"name": "Vulnerability Remediation Tracker", "frameworks": [{"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Tracker showing open vulnerabilities, owners, SLAs and closure status.", "framework_count": 1}, {"name": "Penetration Test Reports", "frameworks": [{"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Annual penetration test reports with findings and remediation evidence.", "framework_count": 1}, {"name": "Vulnerability SLA Compliance Report", "frameworks": [{"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Metrics showing remediation performance against SLA by severity.", "framework_count": 1}, {"name": "Risk Acceptance Records", "frameworks": [{"code": "A.8.8", "framework": "ISO/IEC 27001:2022"}], "description": "Documented acceptance of vulnerabilities that cannot be remediated immediately.", "framework_count": 1}, {"name": "Compliance Verification Reports", "frameworks": [{"code": "13.13", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Reports verifying compliance with vulnerability management controls.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating periodic reviews of vulnerability management processes.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.m", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of vulnerability management requirements.", "framework_count": 1}, {"name": "Hardening Standards", "frameworks": [{"code": "13.13", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Standards for hardening systems against vulnerabilities.", "framework_count": 1}]	18	pending	\N	\N
4660	NCF0180	Threat Intelligence	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.032197	Vulnerability & Threat Management	ai_normalized	\N	[{"name": "Threat Intelligence Procedure and Documentation", "frameworks": [{"code": "A.5.7", "framework": "ISO/IEC 27001:2022"}, {"code": "12.1.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Documented processes and reports related to threat intelligence collection, analysis, and dissemination.", "framework_count": 2}, {"name": "Threat Intelligence Sources Inventory", "frameworks": [{"code": "A.5.7", "framework": "ISO/IEC 27001:2022"}, {"code": "ID.RA-2", "framework": "NIST Cybersecurity Framework"}], "description": "Register of threat intelligence feeds including coverage, frequency, and cost.", "framework_count": 2}, {"name": "Threat Reports", "frameworks": [{"code": "A.5.7", "framework": "ISO/IEC 27001:2022"}, {"code": "ID.RA-2", "framework": "NIST Cybersecurity Framework"}], "description": "Periodic reports on threats relevant to the organization's sector and assets.", "framework_count": 2}, {"name": "Threat Brief Distribution Record", "frameworks": [{"code": "A.5.7", "framework": "ISO/IEC 27001:2022"}], "description": "Evidence of regular threat briefings delivered to leadership and SOC teams.", "framework_count": 1}, {"name": "TI Platform Dashboard and IOC Logs", "frameworks": [{"code": "A.5.7", "framework": "ISO/IEC 27001:2022"}], "description": "Screenshots and logs from threat intelligence platforms showing active indicators and ingestion results.", "framework_count": 1}]	18	pending	\N	\N
4661	NCF0181	Incident Handling	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.037201	Incident Management	ai_normalized	\N	[{"name": "Incident Response Plan", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}, {"code": "7.7.3", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "IR-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "A comprehensive plan detailing incident response roles, escalation procedures, and handling protocols.", "framework_count": 3}, {"name": "Incident Log and Review Records", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}, {"code": "IR-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records of incidents and post-incident reviews to analyze and improve response efforts.", "framework_count": 2}, {"name": "Incident Classification and Severity Framework", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}], "description": "A framework for classifying incidents based on their severity and impact.", "framework_count": 1}, {"name": "Incident Handling Playbooks", "frameworks": [{"code": "Article 21(2)(b)", "framework": "NIS2 Directive"}], "description": "Playbooks outlining procedures for handling common incident scenarios.", "framework_count": 1}, {"name": "Incident Tracking System Records", "frameworks": [{"code": "IR-4", "framework": "NIST SP 800-53 Rev 5"}], "description": "Records maintained in an incident tracking system to monitor and manage incidents.", "framework_count": 1}, {"name": "Evidence Preservation Guidelines", "frameworks": [{"code": "7.7.3", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Guidelines for preserving evidence during incident investigations.", "framework_count": 1}]	18	pending	\N	\N
4663	NCF0183	Incident Response Plan	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.046497	Incident Management	ai_normalized	\N	[{"name": "Incident Response Plan", "frameworks": [{"code": "8.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "8.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "IR-8", "framework": "NIST SP 800-53 Rev 5"}, {"code": "12.10.1", "framework": "PCI Data Security Standard"}, {"code": "12.3.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "A documented plan outlining the procedures for responding to cybersecurity incidents.", "framework_count": 5}, {"name": "Contact Information", "frameworks": [{"code": "8.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "8.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "12.10.1", "framework": "PCI Data Security Standard"}], "description": "Details of contacts necessary for incident response, including procedures for reaching them.", "framework_count": 3}, {"name": "Response Team Roster", "frameworks": [{"code": "8.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "8.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "A list of individuals designated to respond to cybersecurity incidents.", "framework_count": 2}, {"name": "Plan Review and Approval Records", "frameworks": [{"code": "IR-8", "framework": "NIST SP 800-53 Rev 5"}], "description": "Documentation showing that the incident response plan has been reviewed and approved.", "framework_count": 1}, {"name": "Distribution List for Incident Response Plan", "frameworks": [{"code": "IR-8", "framework": "NIST SP 800-53 Rev 5"}], "description": "A list of individuals or teams who receive the incident response plan.", "framework_count": 1}, {"name": "IRP Roles & Responsibilities", "frameworks": [{"code": "12.10.1", "framework": "PCI Data Security Standard"}], "description": "Documented roles and responsibilities for the incident response team.", "framework_count": 1}, {"name": "Legal & Regulatory Reporting Map", "frameworks": [{"code": "12.10.1", "framework": "PCI Data Security Standard"}], "description": "Mapping of legal and regulatory reporting obligations applicable to compromises.", "framework_count": 1}, {"name": "Response Plan Testing and Exercise Records", "frameworks": [{"code": "12.3.1", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Records of tests and exercises conducted to validate the incident response plan.", "framework_count": 1}]	18	pending	\N	\N
4664	NCF0184	Incident Response Planning and Procedures	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.050496	Incident Management	ai_normalized	\N	[{"name": "Incident Response Plan", "frameworks": [{"code": "Article 23", "framework": "NIS2 Directive"}, {"code": "5.1", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Comprehensive incident response plan aligned with NIS2 and SWIFT requirements, including testing and update records.", "framework_count": 2}, {"name": "Escalation and Communication Procedures", "frameworks": [{"code": "Article 23", "framework": "NIS2 Directive"}, {"code": "5.1", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Escalation matrix and communication procedures for incident response.", "framework_count": 2}, {"name": "Incident Response Team Details", "frameworks": [{"code": "Article 23", "framework": "NIS2 Directive"}], "description": "Composition and contact details of the incident response team.", "framework_count": 1}, {"name": "Tabletop Exercise Records", "frameworks": [{"code": "5.1", "framework": "SWIFT Customer Security Controls Framework"}], "description": "Records of tabletop exercises conducted to test the incident response plan.", "framework_count": 1}]	18	pending	\N	\N
4665	NCF0185	Incident Investigation	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.058903	Incident Management	ai_normalized	\N	[{"name": "Investigation Procedures", "frameworks": [{"code": "RS.AN-1", "framework": "NIST Cybersecurity Framework"}, {"code": "8.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documented procedures for conducting investigations related to cybersecurity incidents.", "framework_count": 2}, {"name": "Analysis Records and Findings Documentation", "frameworks": [{"code": "RS.AN-1", "framework": "NIST Cybersecurity Framework"}, {"code": "8.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records of analysis and documentation of findings from investigations.", "framework_count": 2}, {"name": "Root Cause Analysis", "frameworks": [{"code": "8.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation of the root cause analysis conducted after incidents.", "framework_count": 1}]	18	pending	\N	\N
4667	NCF0187	Breach Notification Rule	\N	\N	\N	\N	\N	0	2026-06-21 08:17:39.066339	Incident Management	ai_normalized	\N	[{"name": "Breach Notification Policy and Procedures", "frameworks": [{"code": "§164.400-414", "framework": "HIPAA Security & Privacy Rule"}, {"code": "PDP.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documented policies and procedures for breach notification, including templates and tracking systems.", "framework_count": 2}, {"name": "Breach Risk Assessment Methodology", "frameworks": [{"code": "§164.400-414", "framework": "HIPAA Security & Privacy Rule"}], "description": "Documented methodology for assessing breach risks.", "framework_count": 1}, {"name": "HHS Breach Reporting Records", "frameworks": [{"code": "§164.400-414", "framework": "HIPAA Security & Privacy Rule"}], "description": "Records of breach reports submitted to HHS.", "framework_count": 1}, {"name": "Organizational Artifacts for Data Breach Notification", "frameworks": [{"code": "PDP.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documentation of roles, responsibilities, and workflows related to data breach notification.", "framework_count": 1}, {"name": "Privacy Artifacts", "frameworks": [{"code": "PDP.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Records related to privacy, including consent records and breach response logs.", "framework_count": 1}, {"name": "Data Security Control Evidence", "frameworks": [{"code": "PDP.3.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Evidence of data security controls such as access controls and encryption.", "framework_count": 1}]	18	pending	\N	\N
4784	NCS23-0007	Secure Data Disposal	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.099393	Data Protection & Privacy	ai_normalized	\N	[{"name": "Disposal Procedures", "frameworks": [{"code": "3.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "5.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "11.1.7", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented procedures for the disposal of data, including step-by-step instructions and responsible roles.", "framework_count": 4}, {"name": "Disposal Verification", "frameworks": [{"code": "3.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "5.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the verification of data disposal, including dates and responsible parties.", "framework_count": 4}, {"name": "Destruction Certificates", "frameworks": [{"code": "3.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "5.3", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Certificates that verify the destruction of data, including issuance date, scope, and authorized signatory.", "framework_count": 3}, {"name": "Data Sanitization Tool Configuration", "frameworks": [{"code": "AM 5.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration details of data sanitization tools, including screenshots or exports showing the control in effect.", "framework_count": 1}, {"name": "Data Sanitization Checklists", "frameworks": [{"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Completed and signed-off checklists for data sanitization, including evidence references and performers.", "framework_count": 1}, {"name": "Software License Deactivation Records", "frameworks": [{"code": "AM 5.4", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the deactivation of software licenses, including dates and responsible parties.", "framework_count": 1}]	23	pending	\N	\N
4785	NCS23-0008	Asset Inventory	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.109855	Asset Management	ai_normalized	\N	[{"name": "Asset Inventory", "frameworks": [{"code": "3.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "2.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "3.3.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "A comprehensive list of information assets including details such as entity/item name, owner, classification, and status.", "framework_count": 4}, {"name": "Asset Ownership Records", "frameworks": [{"code": "3.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "2.1", "framework": "SABIC CyberTrust Guidelines"}], "description": "Documentation that identifies the ownership of each asset within the inventory.", "framework_count": 2}, {"name": "Periodic Inventory Reconciliation Reports", "frameworks": [{"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "3.3.2", "framework": "MAS Technology Risk Management Guidelines"}], "description": "Reports generated periodically to reconcile the asset inventory, ensuring accuracy and completeness.", "framework_count": 2}, {"name": "Classification Assignments", "frameworks": [{"code": "3.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records detailing the classification of each asset based on its sensitivity and importance.", "framework_count": 1}, {"name": "Inventory Update Procedures", "frameworks": [{"code": "2.1", "framework": "SABIC CyberTrust Guidelines"}], "description": "Procedures outlining how the asset inventory is updated and maintained.", "framework_count": 1}, {"name": "Asset Inventory Update Logs", "frameworks": [{"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs that track changes made to the asset inventory, including timestamps and actions performed.", "framework_count": 1}, {"name": "Asset-to-Service Mapping/Relationship Diagrams", "frameworks": [{"code": "AM 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Diagrams that illustrate the relationships between assets and services, including interconnections and data flows.", "framework_count": 1}]	23	pending	\N	\N
4786	NCS23-0009	Change Management Policy and Procedures	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.124534	Configuration & Change Management	ai_normalized	\N	[{"name": "Change Management Policy", "frameworks": [{"code": "CM-01", "framework": "SOX IT General Controls"}, {"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "7.5.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "6.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Approved policy document outlining change management processes and responsibilities.", "framework_count": 7}, {"name": "Change Management Procedures", "frameworks": [{"code": "CM-01", "framework": "SOX IT General Controls"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "7.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures detailing how changes are requested, assessed, approved, implemented, and reviewed.", "framework_count": 6}, {"name": "Change Request Records", "frameworks": [{"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "7.5.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Records of change requests including approvals and impact assessments.", "framework_count": 5}, {"name": "Change Approval Records", "frameworks": [{"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Documentation of approvals for changes, including CAB meeting minutes.", "framework_count": 4}, {"name": "Post-Implementation Review Records", "frameworks": [{"code": "6.5", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "Article 21(2)(a)(b)", "framework": "NIS2 Directive"}], "description": "Records demonstrating the review of changes after implementation.", "framework_count": 4}, {"name": "Rollback/Back-out Plans", "frameworks": [{"code": "A.8.32", "framework": "ISO/IEC 27001:2022"}, {"code": "OM 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented plans for rolling back changes if necessary.", "framework_count": 3}, {"name": "Change Records", "frameworks": [{"code": "6.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Comprehensive records of changes made, including risk classifications.", "framework_count": 3}, {"name": "Awareness Communications", "frameworks": [{"code": "09.b", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "10.k", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of change management requirements.", "framework_count": 2}, {"name": "Compliance Audit Reports", "frameworks": [{"code": "DAM.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Reports and records demonstrating compliance with change management standards.", "framework_count": 1}, {"name": "Data Architecture Artifacts", "frameworks": [{"code": "DAM.5.1", "framework": "KSA National Data Management and Personal Data Protection Standards"}], "description": "Documentation of data architecture relevant to change management.", "framework_count": 1}]	23	pending	\N	\N
4787	NCS23-0010	Patch Management	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.127536	Configuration & Change Management	ai_normalized	\N	[{"name": "Patch Management Policy", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}, {"code": "7.4.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "7.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive policy outlining patch management procedures, including roles, responsibilities, and exception handling.", "framework_count": 4}, {"name": "Patch Deployment Reports", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}, {"code": "7.4.1", "framework": "MAS Technology Risk Management Guidelines"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of patch deployment activities, including compliance with SLAs and timelines.", "framework_count": 3}, {"name": "Patch Assessment and Testing Records", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of patch assessment and testing activities, including dates, performers, and approvers.", "framework_count": 2}, {"name": "Patch Compliance Reports", "frameworks": [{"code": "7.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Reports detailing compliance status of patches, including findings and recommendations.", "framework_count": 2}, {"name": "Missing Patch Exception Documentation", "frameworks": [{"code": "CM-09", "framework": "SOX IT General Controls"}], "description": "Documentation for any exceptions to patching requirements, including justification and approval.", "framework_count": 1}, {"name": "Patching Records", "frameworks": [{"code": "7.4", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Comprehensive logs of patching activities, including timestamps and actions performed.", "framework_count": 1}, {"name": "Critical Patch SLA Tracking", "frameworks": [{"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Tracking documentation for critical patches, including security clauses and obligations.", "framework_count": 1}, {"name": "Firmware Update Logs", "frameworks": [{"code": "OM 6.5", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of firmware updates, preserved with timestamps and action details.", "framework_count": 1}]	23	pending	\N	\N
4776	NCS22-0002	Control of Documented Information	\N	\N	\N	\N	\N	0	2026-06-21 08:57:51.00483	Asset Management	ai_normalized	\N	[{"name": "Operating Procedures Library", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}, {"code": "09.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Central library of operating procedures (SOPs) for IT operations activities, including version control.", "framework_count": 2}, {"name": "Procedure Review Records", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}, {"code": "09.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Evidence of periodic review and update of operating procedures, including reviewer details and observations.", "framework_count": 2}, {"name": "Document Control Policy", "frameworks": [{"code": "7.5.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Policy and procedure for control of documented information covering availability, protection, distribution, version control, retention, and disposition.", "framework_count": 1}, {"name": "Access Control Records", "frameworks": [{"code": "7.5.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Document management system access control settings and audit logs.", "framework_count": 1}, {"name": "Runbook Examples", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}], "description": "Operational runbooks for routine activities such as backup, patching, and restart.", "framework_count": 1}, {"name": "On-Call Handover Procedure", "frameworks": [{"code": "A.5.37", "framework": "ISO/IEC 27001:2022"}], "description": "Procedure for shift handover and on-call rotation.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "09.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of the documented operations procedures requirement.", "framework_count": 1}, {"name": "External-Origin Document Register", "frameworks": [{"code": "7.5.3", "framework": "ISO/IEC 42001:2023 AI Management System"}], "description": "Register identifying and controlling external-origin documents necessary for AIMS planning and operation.", "framework_count": 1}]	22	pending	\N	\N
4777	NCS22-0003	Creating and Updating Documented Information	\N	\N	\N	\N	\N	0	2026-06-21 08:57:51.013519	Other / Uncategorized	ai_normalized	\N	[{"name": "Document Control Procedure", "frameworks": [{"code": "7.5.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "7.5.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Procedure governing creation and updating of documented information including identification, format and review/approval requirements.", "framework_count": 2}, {"name": "Document Template Library", "frameworks": [{"code": "7.5.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "7.5.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Approved template library enforcing identification, format and review fields.", "framework_count": 2}, {"name": "Review & Approval Records", "frameworks": [{"code": "7.5.2", "framework": "ISO/IEC 42001:2023 AI Management System"}, {"code": "7.5.2", "framework": "ISO 22301:2019 Business Continuity Management System"}], "description": "Review and approval records for documents including workflow logs and signatures.", "framework_count": 2}]	22	pending	\N	\N
4779	NCS23-0002	Secure Work Areas	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.018728	Physical & Environmental Security	ai_normalized	\N	[{"name": "Work Area Security Procedures", "frameworks": [{"code": "6.3", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documentation outlining procedures for maintaining security in work areas, including clean desk policies and privacy screen deployment.", "framework_count": 1}, {"name": "Authorized Personnel List", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "A comprehensive list of authorized personnel for secure areas, including details such as entity/item name, owner, classification, and review date.", "framework_count": 1}, {"name": "Access Authentication Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of access authentication, including badge logs and biometric logs, preserved for the required retention period.", "framework_count": 1}, {"name": "Secure Area Access Logs", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs documenting access to secure areas, including timestamps, actor identity, actions performed, and outcomes.", "framework_count": 1}, {"name": "ID Badge Issuance Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the issuance of ID badges, including dates, performers, and approvers.", "framework_count": 1}, {"name": "Door Alarm and Locking Configuration", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Configuration details of door alarms and locking mechanisms, including extracts or screenshots showing the control is in effect.", "framework_count": 1}, {"name": "Contractor Escort Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the escorting of contractors, including dates, performers, and approvers.", "framework_count": 1}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of CCTV controls, including dates and ownership.", "framework_count": 1}, {"name": "CCTV Retention Policy and Footage Storage Records", "frameworks": [{"code": "PE 2.3", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the retention policy for CCTV footage and its storage, including dates and approvers.", "framework_count": 1}]	23	pending	\N	\N
4780	NCS23-0003	Key Management	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.056286	Cryptography & Key Management	ai_normalized	\N	[{"name": "Key Management Procedures", "frameworks": [{"code": "4.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documented procedures for managing cryptographic keys, including generation, rotation, and destruction.", "framework_count": 4}, {"name": "Key Rotation Schedules", "frameworks": [{"code": "4.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "5.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records detailing the schedules for key rotation to ensure security and compliance.", "framework_count": 3}, {"name": "Key Custodian Documentation", "frameworks": [{"code": "4.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Documentation identifying key custodians and their responsibilities in key management.", "framework_count": 2}, {"name": "Cryptographic Standards Documentation", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of approved cryptographic standards, including algorithms and key strengths.", "framework_count": 2}, {"name": "Key Management Policy", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "An approved policy outlining the key management framework and responsibilities.", "framework_count": 2}, {"name": "Key Destruction Records", "frameworks": [{"code": "5.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records that demonstrate the proper destruction of cryptographic keys.", "framework_count": 1}, {"name": "Key Lifecycle Procedures", "frameworks": [{"code": "7.2", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Procedures outlining the lifecycle of cryptographic keys from creation to destruction.", "framework_count": 1}, {"name": "Key Generation/Revocation/Repair Records", "frameworks": [{"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating the generation, revocation, or repair of cryptographic keys.", "framework_count": 1}, {"name": "Key Protection Mechanisms", "frameworks": [{"code": "SA 4.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation of mechanisms used to protect cryptographic keys, such as hardware security modules.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications to personnel regarding key management requirements and responsibilities.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "10.g", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of key management practices, including observations and corrective actions.", "framework_count": 1}]	23	pending	\N	\N
4781	NCS23-0004	Access Control Policy	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.069974	Access Control & Identity Management	ai_normalized	\N	[{"name": "Approved Access Control Policy", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "4.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "3.1", "framework": "SABIC CyberTrust Guidelines"}, {"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "9.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "8.10.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}, {"code": "A.5.15", "framework": "ISO/IEC 27001:2022"}], "description": "Board/management-approved access control policy document, including scope, applicability, roles, responsibilities, and control objectives.", "framework_count": 7}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "4.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "9.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}, {"code": "A.5.15", "framework": "ISO/IEC 27001:2022"}], "description": "Matrix mapping roles to permissions for relevant systems, clearly identifying owners and responsibilities.", "framework_count": 4}, {"name": "Access Control Policy Review Records", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}, {"code": "9.1", "framework": "Sri Lanka Baseline Security Standard (BSS)"}], "description": "Records demonstrating the annual review of the access control policy, including date, performer, and changes captured.", "framework_count": 3}, {"name": "User Access Provisioning and Review Records", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "3.1", "framework": "SABIC CyberTrust Guidelines"}], "description": "Records of user access provisioning, modification, and review, demonstrating the activity occurred with relevant details.", "framework_count": 2}, {"name": "Awareness Communications", "frameworks": [{"code": "01.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating that personnel are informed of access control requirements, including attendee list and delivery dates.", "framework_count": 1}, {"name": "Top Management Approval Evidence", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifact demonstrating top management approval of the access control policy, including date and owner.", "framework_count": 1}, {"name": "Stakeholder Policy Acknowledgement Records", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records demonstrating stakeholder acknowledgment of the access control policy, including date and performer.", "framework_count": 1}, {"name": "Role-Based Access Criteria Documentation", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation outlining role-based access criteria, including date and owner.", "framework_count": 1}, {"name": "Password Management Policy", "frameworks": [{"code": "AC 1.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Board/management-approved password management policy, including scope and control objectives.", "framework_count": 1}, {"name": "Identification/Authentication/Authorization Procedures", "frameworks": [{"code": "8.10.1.1", "framework": "Qatar Central Bank Technology Risks Circular"}], "description": "Procedures outlining identification, authentication, and authorization processes.", "framework_count": 1}, {"name": "Access Review Evidence", "frameworks": [{"code": "A.5.15", "framework": "ISO/IEC 27001:2022"}], "description": "Quarterly access review results signed off by data/system owners.", "framework_count": 1}]	23	pending	\N	\N
4782	NCS23-0005	User Authentication	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.072975	Access Control & Identity Management	ai_normalized	\N	[{"name": "Authentication Configuration", "frameworks": [{"code": "3.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Configuration settings for user authentication mechanisms.", "framework_count": 2}, {"name": "MFA Deployment Records", "frameworks": [{"code": "3.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Records demonstrating the implementation of Multi-Factor Authentication.", "framework_count": 2}, {"name": "Password Policy", "frameworks": [{"code": "3.2", "framework": "SABIC CyberTrust Guidelines"}, {"code": "4.2", "framework": "ARAMCO Cybersecurity Compliance Certification"}], "description": "Documented policy outlining the requirements for password creation and management.", "framework_count": 2}, {"name": "User Access Records", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}, {"code": "AC 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Records of user access provisioning, modification, and review activities.", "framework_count": 2}, {"name": "User Identification and Authentication Policy", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Board-approved policy addressing user identification and authentication requirements.", "framework_count": 1}, {"name": "User Identification and Authentication Procedures", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Documented procedures for implementing user identification and authentication.", "framework_count": 1}, {"name": "Access Control Matrix", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Matrix mapping roles to permissions for relevant systems.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "01.q", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Communications demonstrating personnel awareness of security requirements.", "framework_count": 1}, {"name": "User Activity Logs", "frameworks": [{"code": "AC 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Logs of user activities linked to unique identifiers, preserved for retention.", "framework_count": 1}, {"name": "Account Naming Convention Documentation", "frameworks": [{"code": "AC 6.2", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation supporting the implementation of account naming conventions.", "framework_count": 1}]	23	pending	\N	\N
4783	NCS23-0006	Physical Security Perimeter	\N	\N	\N	\N	\N	0	2026-06-21 09:04:08.08083	Physical & Environmental Security	ai_normalized	\N	[{"name": "Physical Access Controls Documentation", "frameworks": [{"code": "6.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "PE 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Supporting artifacts demonstrating the implementation of physical access controls, including secure area identification, perimeter documentation, and security countermeasures.", "framework_count": 2}, {"name": "Access Logs", "frameworks": [{"code": "6.1", "framework": "ARAMCO Cybersecurity Compliance Certification"}, {"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of physical access including badge/biometric logs and visitor registers, preserved for the required retention period.", "framework_count": 2}, {"name": "CCTV Deployment Evidence", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records demonstrating the deployment of CCTV systems and retention of footage, including dates and responsible parties.", "framework_count": 1}, {"name": "Physical Security Policy and Procedures", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Approved policies and documented procedures addressing physical security perimeters, including scope, roles, and implementation instructions.", "framework_count": 1}, {"name": "Risk-Based Perimeter Assessment Records", "frameworks": [{"code": "PE 2.1", "framework": "Abu Dhabi Healthcare Information and Cyber Security Standard"}], "description": "Documentation demonstrating risk-based assessments of security perimeters, including dates and responsible parties.", "framework_count": 1}, {"name": "Awareness Communications", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of communications informing personnel about physical security requirements, including attendee lists and delivery dates.", "framework_count": 1}, {"name": "Periodic Review Records", "frameworks": [{"code": "08.a", "framework": "HITRUST Common Security Framework (CSF)"}], "description": "Records of periodic reviews of physical security controls, including dates, observations, and corrective actions.", "framework_count": 1}]	23	pending	\N	\N
\.


--
-- Name: grc_ai_evidence_recommendations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_ai_evidence_recommendations_id_seq', 25, true);


--
-- Name: grc_common_control_group_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_common_control_group_mappings_id_seq', 38547, true);


--
-- Name: grc_common_control_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_common_control_groups_id_seq', 1416, true);


--
-- Name: grc_evidence_control_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_evidence_control_mappings_id_seq', 54, true);


--
-- Name: grc_normalization_runs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_normalization_runs_id_seq', 23, true);


--
-- Name: grc_normalized_control_links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_normalized_control_links_id_seq', 22484, true);


--
-- Name: grc_normalized_controls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: grc_app
--

SELECT pg_catalog.setval('public.grc_normalized_controls_id_seq', 4787, true);


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

\unrestrict en481eiNugfJddPMPN8fFSWgeGX2nS0Nd1LbXWcikzGhJm4lx470nenj6f8Vpd1

