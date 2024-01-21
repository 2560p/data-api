--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.1

-- So you are really looking through .sql files
-- Wow, impressive

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
-- Name: netflix_api; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE netflix_api WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE netflix_api OWNER TO postgres;

\connect netflix_api

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

CREATE ROLE junior;
ALTER ROLE junior WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;

CREATE ROLE medior;
ALTER ROLE medior WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;

CREATE ROLE senior;
ALTER ROLE senior WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;

CREATE ROLE junior_user;
ALTER ROLE junior_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'junior_password';

CREATE ROLE medior_user;
ALTER ROLE medior_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'medior_password';

CREATE ROLE senior_user;
ALTER ROLE senior_user WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'senior_password';


--
-- Name: age_classification_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.age_classification_enum AS ENUM (
    '6',
    '9',
    '12',
    '16'
);


ALTER TYPE public.age_classification_enum OWNER TO postgres;

--
-- Name: new_media_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.new_media_type_enum AS ENUM (
    'FILM',
    'SERIES'
);


ALTER TYPE public.new_media_type_enum OWNER TO postgres;

--
-- Name: role_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.role_type AS ENUM (
    'junior',
    'medior',
    'senior'
);


ALTER TYPE public.role_type OWNER TO postgres;

--
-- Name: subscription_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.subscription_type_enum AS ENUM (
    'SD',
    'HD',
    'UHD'
);


ALTER TYPE public.subscription_type_enum OWNER TO postgres;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_status AS ENUM (
    'ACTIVE',
    'RESTRICTED',
    'BLOCKED'
);


ALTER TYPE public.user_status OWNER TO postgres;

--
-- Name: admin_register(character varying, character varying, public.role_type); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.admin_register(p_email character varying, p_password character varying, p_role public.role_type) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_admin_exists BOOLEAN;
    admin_id integer;
    ret record;
BEGIN
    SELECT EXISTS (SELECT 1 FROM admins WHERE email = p_email) INTO v_admin_exists;

    IF v_admin_exists THEN
        select -1, 0 into ret;
    ELSE
        INSERT INTO admins (email, password, role)
        VALUES (p_email, p_password, p_role) returning id into admin_id;
        select 1, admin_id into ret;
    END IF;
    return ret;
END;
$$;


ALTER FUNCTION public.admin_register(p_email character varying, p_password character varying, p_role public.role_type) OWNER TO postgres;

--
-- Name: admin_retrieve_password_hash(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.admin_retrieve_password_hash(p_email character varying) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_admin_exists BOOLEAN;
    ret record;
BEGIN
    SELECT EXISTS (SELECT 1 FROM admins WHERE email = p_email) INTO v_admin_exists;

    IF v_admin_exists THEN
        select password, id
        from admins
        where email = p_email into ret;
    ELSE
        select -1, 0 into ret;
    END IF;
    return ret;
END;
$$;


ALTER FUNCTION public.admin_retrieve_password_hash(p_email character varying) OWNER TO postgres;

--
-- Name: apply_discount(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.apply_discount() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.discount_received = true AND OLD.discount_received = false THEN
        IF NOT EXISTS (
            SELECT 1
            FROM subscriptions
            WHERE user_id IN (NEW.inviter_user_id, NEW.invitee_user_id)
              AND discount_received = true
        ) THEN
            UPDATE subscriptions
            SET cost_per_month = cost_per_month - 2
            WHERE user_id IN (NEW.inviter_user_id, NEW.invitee_user_id);
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.apply_discount() OWNER TO postgres;

--
-- Name: check_profile_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_profile_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    profile_count INT;
BEGIN
    SELECT COUNT(*) INTO profile_count
    FROM profiles
    WHERE user_id = NEW.user_id;

    IF profile_count >= 4 THEN
        RAISE EXCEPTION 'Cannot exceed 4 profiles per user.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_profile_limit() OWNER TO postgres;

--
-- Name: get_sorted_movies(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies(desired_year integer, desired_month integer) RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    (
        SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            COUNT(*) DESC
        LIMIT 3
    )
    UNION ALL
    (
        SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            m.likes DESC
        LIMIT 3
    )
    UNION ALL
    (
        SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            COUNT(*) ASC
        LIMIT 3
    )
    UNION ALL
    (
        SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            m.likes ASC
        LIMIT 3
    );
END;
$$;


ALTER FUNCTION public.get_sorted_movies(desired_year integer, desired_month integer) OWNER TO postgres;

--
-- Name: get_sorted_movies_least_liked(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_least_liked(desired_year integer, desired_month integer) RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
         SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            m.likes
        LIMIT 3;
END;
$$;


ALTER FUNCTION public.get_sorted_movies_least_liked(desired_year integer, desired_month integer) OWNER TO postgres;

--
-- Name: get_sorted_movies_least_viewed(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_least_viewed(desired_year integer, desired_month integer) RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            COUNT(*) ASC
        LIMIT 3;
END;
$$;


ALTER FUNCTION public.get_sorted_movies_least_viewed(desired_year integer, desired_month integer) OWNER TO postgres;

--
-- Name: get_sorted_movies_most_liked(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_most_liked(desired_year integer, desired_month integer) RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            m.title AS name
        FROM
            media m
        LEFT JOIN (
            SELECT
                media_id,
                date
            FROM
                watch_history
            WHERE
                EXTRACT(YEAR FROM date) = desired_year
                AND EXTRACT(MONTH FROM date) = desired_month
        ) wh ON m.id = wh.media_id
        GROUP BY
            m.id, m.title, m.likes
        ORDER BY
            m.likes DESC
        LIMIT 3;
END;
$$;


ALTER FUNCTION public.get_sorted_movies_most_liked(desired_year integer, desired_month integer) OWNER TO postgres;

--
-- Name: get_sorted_movies_most_viewed(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_most_viewed(desired_year integer, desired_month integer) RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.title
    FROM
        media m
    LEFT JOIN (
        SELECT
            media_id,
            date
        FROM
            watch_history
        WHERE
            EXTRACT(YEAR FROM date) = desired_year
            AND EXTRACT(MONTH FROM date) = desired_month
    ) wh ON m.id = wh.media_id
    GROUP BY
        m.id, m.title, m.likes
    ORDER BY
        COUNT(*) DESC
    LIMIT 3;
END;
$$;


ALTER FUNCTION public.get_sorted_movies_most_viewed(desired_year integer, desired_month integer) OWNER TO postgres;

--
-- Name: get_watch_count_per_person(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_watch_count_per_person(p_profileid integer, p_mediaid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_WatchCount INT;
BEGIN
    SELECT COUNT(*) INTO v_WatchCount
    FROM watch_history
    WHERE profile_id = p_ProfileID AND media_id = p_MediaID;

    RETURN v_WatchCount;
END;
$$;


ALTER FUNCTION public.get_watch_count_per_person(p_profileid integer, p_mediaid integer) OWNER TO postgres;

--
-- Name: invite_user_discount(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.invite_user_discount(IN p_inviter_id integer, IN p_invitee_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT has_invited FROM subscriptions WHERE user_id = p_inviter_id) IS NOT NULL THEN
        RAISE EXCEPTION 'The inviter has already invited someone else';
    END IF;

    IF (SELECT invited_by FROM subscriptions WHERE user_id = p_invitee_id) IS NOT NULL THEN
        RAISE EXCEPTION 'The invitee has already been invited by someone else';
    END IF;

    UPDATE subscriptions
    SET has_invited = p_invitee_id
    WHERE user_id = p_inviter_id;

    UPDATE subscriptions
    SET invited_by = p_inviter_id
    WHERE user_id = p_invitee_id;
END;
$$;


ALTER PROCEDURE public.invite_user_discount(IN p_inviter_id integer, IN p_invitee_id integer) OWNER TO postgres;

--
-- Name: most_viewed_movies(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.most_viewed_movies() RETURNS TABLE(media_id integer, view_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        COUNT(*)::INT AS view_count
    FROM
        watch_history wh
    JOIN
        media m ON wh.media_id = m.id
    WHERE
        m.media_type = 'FILM'
    GROUP BY
        m.id
    ORDER BY
        view_count DESC
    LIMIT 3;
END;
$$;


ALTER FUNCTION public.most_viewed_movies() OWNER TO postgres;

--
-- Name: toggle_media_like(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.toggle_media_like(p_userid integer, p_mediaid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_AlreadyLiked BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM liked_media
        WHERE user_id = p_UserID AND media_id = p_MediaID
    ) INTO v_AlreadyLiked;

    IF v_AlreadyLiked THEN
        DELETE FROM liked_media
        WHERE user_id = p_UserID AND media_id = p_MediaID;

        RAISE NOTICE 'Like removed for MediaID: %', p_MediaID;
    ELSE
        INSERT INTO liked_media (user_id, media_id)
        VALUES (p_UserID, p_MediaID);

        RAISE NOTICE 'Like added for MediaID: %', p_MediaID;
    END IF;
END;
$$;


ALTER FUNCTION public.toggle_media_like(p_userid integer, p_mediaid integer) OWNER TO postgres;

--
-- Name: update_cost_trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_cost_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.has_invited IS NOT NULL AND OLD.has_invited IS NULL) OR
       (NEW.invited_by IS NOT NULL AND OLD.invited_by IS NULL) THEN
        NEW.cost_per_month := NEW.cost_per_month - 2;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_cost_trigger_function() OWNER TO postgres;

--
-- Name: update_currently_watched(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_currently_watched(IN p_profileid integer, IN p_mediaid integer, IN p_progressseconds integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM currently_watched
        WHERE profile_id = p_ProfileID AND media_id = p_MediaID
    ) THEN
        UPDATE currently_watched
        SET progress_seconds = p_ProgressSeconds,
            last_watched = CURRENT_TIMESTAMP
        WHERE profile_id = p_ProfileID AND media_id = p_MediaID;
    ELSE
        INSERT INTO currently_watched (profile_id, media_id, progress_seconds)
        VALUES (p_ProfileID, p_MediaID, p_ProgressSeconds);
    END IF;
END;
$$;


ALTER PROCEDURE public.update_currently_watched(IN p_profileid integer, IN p_mediaid integer, IN p_progressseconds integer) OWNER TO postgres;

--
-- Name: user_login(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_login(p_email character varying, p_password character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
    DECLARE
        v_user_id INT;
    BEGIN
        SELECT id INTO v_user_id
        FROM users
        WHERE email = p_email
        AND password = p_password
        AND status = 'ACTIVE'::user_status;
             
        IF v_user_id IS NOT NULL THEN
            RETURN 'Login successful. UserID: ' || v_user_id;
        ELSE
            RETURN 'Login failed. Invalid email, password, or user status.';
        END IF;
    END;
$$;


ALTER FUNCTION public.user_login(p_email character varying, p_password character varying) OWNER TO postgres;

--
-- Name: user_register(character varying, character varying, public.user_status); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.user_register(IN p_email character varying, IN p_password character varying, IN p_status public.user_status)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM users WHERE email = p_email) INTO v_user_exists;

    IF v_user_exists THEN
        RAISE EXCEPTION 'Email already exists. Please use a different email.';
    ELSE
        INSERT INTO users (email, password, status)
        VALUES (p_email, p_password, p_status);
        RAISE NOTICE 'User added successfully.';
    END IF;
END;
$$;


ALTER PROCEDURE public.user_register(IN p_email character varying, IN p_password character varying, IN p_status public.user_status) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    role public.role_type NOT NULL,
    email character varying(256) NOT NULL,
    password character varying(256) NOT NULL
);


ALTER TABLE public.admins OWNER TO postgres;

--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admins_id_seq OWNER TO postgres;

--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: age_restriction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.age_restriction (
    id integer NOT NULL,
    age_classification public.age_classification_enum
);


ALTER TABLE public.age_restriction OWNER TO postgres;

--
-- Name: age_restriction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.age_restriction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.age_restriction_id_seq OWNER TO postgres;

--
-- Name: age_restriction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.age_restriction_id_seq OWNED BY public.age_restriction.id;


--
-- Name: currently_watched; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.currently_watched (
    profile_id integer NOT NULL,
    media_id integer NOT NULL,
    progress_seconds integer DEFAULT 0 NOT NULL,
    last_watched timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.currently_watched OWNER TO postgres;

--
-- Name: episodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.episodes (
    series_id integer NOT NULL,
    number integer NOT NULL,
    location character varying(256),
    episodes_name text,
    title text,
    duration integer
);


ALTER TABLE public.episodes OWNER TO postgres;

--
-- Name: liked_media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.liked_media (
    user_id integer NOT NULL,
    media_id integer NOT NULL
);


ALTER TABLE public.liked_media OWNER TO postgres;

--
-- Name: media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.media (
    id integer NOT NULL,
    title character varying(256) NOT NULL,
    genre character varying(50),
    language character varying(256),
    media_type public.new_media_type_enum,
    description text,
    poster character varying(256),
    duration integer,
    location character varying(256),
    rating integer,
    age public.age_classification_enum NOT NULL,
    likes integer
);


ALTER TABLE public.media OWNER TO postgres;

--
-- Name: media_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.media_id_seq OWNER TO postgres;

--
-- Name: media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.media_id_seq OWNED BY public.media.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    profile_name character varying(256),
    birthdate date NOT NULL,
    profile_photo character varying(256)
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profiles_id_seq OWNER TO postgres;

--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: series; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.series (
    id integer NOT NULL,
    series_title character varying(256) NOT NULL,
    description text,
    poster character varying(256),
    seasons integer DEFAULT 1 NOT NULL,
    genre character varying(256),
    rating integer NOT NULL,
    media_id integer,
    age public.age_classification_enum NOT NULL
);


ALTER TABLE public.series OWNER TO postgres;

--
-- Name: series_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.series_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.series_id_seq OWNER TO postgres;

--
-- Name: series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.series_id_seq OWNED BY public.series.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriptions (
    user_id integer,
    start_date date NOT NULL,
    end_date date NOT NULL,
    subscription_id integer NOT NULL,
    cost_per_month numeric(8,2) NOT NULL,
    subscription_type public.subscription_type_enum NOT NULL,
    has_invited integer,
    invited_by integer
);


ALTER TABLE public.subscriptions OWNER TO postgres;

--
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscriptions_subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNER TO postgres;

--
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNED BY public.subscriptions.subscription_id;


--
-- Name: subtitles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subtitles (
    media_id integer NOT NULL,
    url character varying(256) NOT NULL,
    language character varying(256) NOT NULL
);


ALTER TABLE public.subtitles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(256) NOT NULL,
    password character varying(256) NOT NULL,
    status public.user_status DEFAULT 'RESTRICTED'::public.user_status NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: watch_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.watch_history (
    profile_id integer NOT NULL,
    media_id integer NOT NULL,
    date date NOT NULL
);


ALTER TABLE public.watch_history OWNER TO postgres;

--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: age_restriction id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.age_restriction ALTER COLUMN id SET DEFAULT nextval('public.age_restriction_id_seq'::regclass);


--
-- Name: media id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: subscriptions subscription_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN subscription_id SET DEFAULT nextval('public.subscriptions_subscription_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: admins admins_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pk PRIMARY KEY (id);


--
-- Name: age_restriction age_restriction_classification_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.age_restriction
    ADD CONSTRAINT age_restriction_classification_unique UNIQUE (age_classification);


--
-- Name: age_restriction age_restriction_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.age_restriction
    ADD CONSTRAINT age_restriction_pk PRIMARY KEY (id);


--
-- Name: episodes episodes_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_pk PRIMARY KEY (series_id, number);


--
-- Name: liked_media liked_media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liked_media
    ADD CONSTRAINT liked_media_pkey PRIMARY KEY (user_id, media_id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pk PRIMARY KEY (id);


--
-- Name: series series_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_pk PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (subscription_id);


--
-- Name: users users_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk PRIMARY KEY (id);


--
-- Name: users users_pk2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pk2 UNIQUE (email);


--
-- Name: currently_watched watch_progress_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currently_watched
    ADD CONSTRAINT watch_progress_pk PRIMARY KEY (profile_id, media_id);


--
-- Name: profiles check_profile_limit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_profile_limit_trigger BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.check_profile_limit();


--
-- Name: episodes episodes_series_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_series_id_fk FOREIGN KEY (series_id) REFERENCES public.series(id);


--
-- Name: liked_media liked_media_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liked_media
    ADD CONSTRAINT liked_media_media_fk FOREIGN KEY (media_id) REFERENCES public.media(id);


--
-- Name: liked_media liked_media_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liked_media
    ADD CONSTRAINT liked_media_user_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: profiles profiles_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: series series_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_media_id_fk FOREIGN KEY (media_id) REFERENCES public.media(id);


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subtitles subtitles_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtitles
    ADD CONSTRAINT subtitles_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media(id);


--
-- Name: watch_history watch_history_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watch_history
    ADD CONSTRAINT watch_history_media_id_fk FOREIGN KEY (media_id) REFERENCES public.media(id);


--
-- Name: watch_history watch_history_profiles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watch_history
    ADD CONSTRAINT watch_history_profiles_id_fk FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: currently_watched watch_progress_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currently_watched
    ADD CONSTRAINT watch_progress_media_fk FOREIGN KEY (media_id) REFERENCES public.media(id);


--
-- Name: currently_watched watch_progress_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currently_watched
    ADD CONSTRAINT watch_progress_user_fk FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO junior;


--
-- Name: SEQUENCE admins_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.admins_id_seq TO senior;


--
-- Name: TABLE age_restriction; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.age_restriction TO senior;
GRANT ALL ON TABLE public.age_restriction TO medior;


--
-- Name: COLUMN age_restriction.id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(id),UPDATE(id) ON TABLE public.age_restriction TO medior;


--
-- Name: COLUMN age_restriction.age_classification; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(age_classification),UPDATE(age_classification) ON TABLE public.age_restriction TO medior;


--
-- Name: SEQUENCE age_restriction_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.age_restriction_id_seq TO senior;


--
-- Name: TABLE currently_watched; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.currently_watched TO junior;
GRANT ALL ON TABLE public.currently_watched TO medior;
GRANT ALL ON TABLE public.currently_watched TO senior;


--
-- Name: TABLE episodes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.episodes TO senior;
GRANT ALL ON TABLE public.episodes TO medior;
GRANT SELECT ON TABLE public.episodes TO junior;


--
-- Name: COLUMN episodes.series_id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(series_id),UPDATE(series_id) ON TABLE public.episodes TO medior;
GRANT SELECT(series_id),INSERT(series_id),REFERENCES(series_id) ON TABLE public.episodes TO senior;


--
-- Name: COLUMN episodes.number; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(number),UPDATE(number) ON TABLE public.episodes TO medior;
GRANT SELECT(number),INSERT(number),REFERENCES(number) ON TABLE public.episodes TO senior;


--
-- Name: COLUMN episodes.location; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(location),UPDATE(location) ON TABLE public.episodes TO medior;
GRANT SELECT(location),INSERT(location),REFERENCES(location) ON TABLE public.episodes TO senior;


--
-- Name: COLUMN episodes.episodes_name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(episodes_name),UPDATE(episodes_name) ON TABLE public.episodes TO medior;
GRANT SELECT(episodes_name),INSERT(episodes_name),REFERENCES(episodes_name) ON TABLE public.episodes TO senior;


--
-- Name: COLUMN episodes.title; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(title),UPDATE(title) ON TABLE public.episodes TO medior;
GRANT SELECT(title),INSERT(title),REFERENCES(title) ON TABLE public.episodes TO senior;


--
-- Name: COLUMN episodes.duration; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(duration),UPDATE(duration) ON TABLE public.episodes TO medior;
GRANT SELECT(duration),INSERT(duration),REFERENCES(duration) ON TABLE public.episodes TO senior;


--
-- Name: TABLE liked_media; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.liked_media TO junior;
GRANT ALL ON TABLE public.liked_media TO medior;
GRANT ALL ON TABLE public.liked_media TO senior;


--
-- Name: TABLE media; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.media TO junior;
GRANT ALL ON TABLE public.media TO medior;
GRANT ALL ON TABLE public.media TO senior;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO senior;
GRANT ALL ON TABLE public.profiles TO medior;


--
-- Name: SEQUENCE profiles_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.profiles_id_seq TO senior;
GRANT SELECT,USAGE ON SEQUENCE public.profiles_id_seq TO junior;


--
-- Name: TABLE series; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.series TO senior;
GRANT ALL ON TABLE public.series TO medior;
GRANT SELECT ON TABLE public.series TO junior;


--
-- Name: SEQUENCE series_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.series_id_seq TO senior;


--
-- Name: TABLE subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.subscriptions TO senior;


--
-- Name: TABLE subtitles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.subtitles TO junior;
GRANT ALL ON TABLE public.subtitles TO medior;
GRANT ALL ON TABLE public.subtitles TO senior;


--
-- Name: COLUMN subtitles.media_id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(media_id) ON TABLE public.subtitles TO junior;


--
-- Name: COLUMN subtitles.url; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(url) ON TABLE public.subtitles TO junior;


--
-- Name: COLUMN subtitles.language; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(language) ON TABLE public.subtitles TO junior;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO senior;
GRANT ALL ON TABLE public.users TO medior;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.users_id_seq TO senior;


--
-- Name: TABLE watch_history; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.watch_history TO senior;
GRANT ALL ON TABLE public.watch_history TO medior;
GRANT ALL ON TABLE public.watch_history TO junior;


--
-- Name: COLUMN watch_history.profile_id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(profile_id) ON TABLE public.watch_history TO junior;
GRANT SELECT(profile_id),UPDATE(profile_id) ON TABLE public.watch_history TO medior;
GRANT ALL(profile_id) ON TABLE public.watch_history TO senior;


--
-- Name: COLUMN watch_history.media_id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(media_id) ON TABLE public.watch_history TO junior;
GRANT SELECT(media_id),UPDATE(media_id) ON TABLE public.watch_history TO medior;
GRANT ALL(media_id) ON TABLE public.watch_history TO senior;


--
-- Name: COLUMN watch_history.date; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(date) ON TABLE public.watch_history TO junior;
GRANT SELECT(date),UPDATE(date) ON TABLE public.watch_history TO medior;
GRANT ALL(date) ON TABLE public.watch_history TO senior;


--
-- PostgreSQL database dump complete
--

--
-- Data time
--

--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admins (id, role, email, password) FROM stdin;
\.


--
-- Data for Name: age_restriction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.age_restriction (id, age_classification) FROM stdin;
1	6
2	9
3	12
4	16
\.


--
-- Data for Name: media; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.media (id, title, genre, language, media_type, description, poster, duration, location, rating, age, likes) FROM stdin;
3	Pulp Fiction	action	en	FILM	The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.\n	https://m.media-amazon.com/images/M/MV5BNGNhMDIzZTUtNTBlZi00MTRlLWFjM2ItYzViMjE3YzI5MjljXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_FMjpg_UX1000_.jpg	121	America	8	16	0
2	Hacksaw Ridge	war	en	FILM	One of the greatest hero's in American history never fired a bullet	https://m.media-amazon.com/images/M/MV5BMjQ1NjM3MTUxNV5BMl5BanBnXkFtZTgwMDc5MTY5OTE@._V1_FMjpg_UX1000_.jpg	137	America	7	16	1
4	Breaking Bad	crime	en	SERIES	Breaking Bad follows Walter White, a struggling, frustrated high school chemistry teacher who transforms into a ruthless kingpin in the local methamphetamine drug trade, driven to provide for his family financially after being diagnosed with inoperable lung cancer.	https://fhm.nl/wp-content/uploads/2017/03/FHM-BreakingBad.jpg	251	America	10	16	1
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password, status) FROM stdin;
4	marijn.veenstra1@student.nhlstenden.com	03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4	ACTIVE
5	anastasia.lukanova@student.nhlstenden.com	5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8	RESTRICTED
6	paul.demenko@student.nhlstenden.com	b9c950640e1b3740e98acb93e669c65766f6670dd1609ba91ff41052ba48c6f3	ACTIVE
7	gabriel.guevara.lopez@student.nhlstenden.com	13004d8331d779808a2336d46b3553d1594229e2bb696a8e9e14554d82a648da	BLOCKED
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profiles (id, user_id, profile_name, birthdate, profile_photo) FROM stdin;
4	4	Marijn	2003-03-27	\N
5	4	Bob	1993-01-07	\N
6	4	Hank	1983-01-08	\N
7	5	Amy	2000-06-21	\N
\.


--
-- Data for Name: currently_watched; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.currently_watched (profile_id, media_id, progress_seconds, last_watched) FROM stdin;
4	2	531	2024-01-21 22:27:20.11078
\.


--
-- Data for Name: series; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.series (id, series_title, description, poster, seasons, genre, rating, media_id, age) FROM stdin;
1	Breaking Bad	Breaking Bad follows Walter White, a struggling, frustrated high school chemistry teacher who transforms into a ruthless kingpin in the local methamphetamine drug trade, driven to provide for his family financially after being diagnosed with inoperable lung cancer.\n	https://fhm.nl/wp-content/uploads/2017/03/FHM-BreakingBad.jpg	6	crime	10	4	16
\.


--
-- Data for Name: episodes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.episodes (series_id, number, location, episodes_name, title, duration) FROM stdin;
1	1	America	Pilot	Breaking Bad	93
1	2	America	Cat's in the Bag...	Breaking Bad	48
1	3	America	...And the Bag's in the River	Breaking Bad	43
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genres (id, name) FROM stdin;
1	history
2	fantasy
3	sci-fi
4	war
5	crime
6	horror
7	comedy
8	action
\.


--
-- Data for Name: liked_media; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.liked_media (user_id, media_id) FROM stdin;
4	2
4	4
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscriptions (user_id, start_date, end_date, subscription_id, cost_per_month, subscription_type, has_invited, invited_by) FROM stdin;
4	2024-01-05	2024-02-05	1	13.99	UHD	\N	\N
5	2024-01-11	2024-02-11	2	10.99	HD	\N	\N
6	2024-01-15	2024-02-15	3	7.99	SD	\N	\N
7	2024-01-06	2024-02-06	4	10.99	HD	\N	\N
\.


--
-- Data for Name: subtitles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subtitles (media_id, url, language) FROM stdin;
2	https://www.subtitles.com/hacksawridge	en
3	https://www.subtitles.com/pulpfiction	en
4	https://www.subtitles.com/breakingbad	en
\.


--
-- Data for Name: watch_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.watch_history (profile_id, media_id, date) FROM stdin;
4	2	2024-01-03
\.


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_id_seq', 1, false);


--
-- Name: age_restriction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.age_restriction_id_seq', 4, true);


--
-- Name: media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.media_id_seq', 4, true);


--
-- Name: profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profiles_id_seq', 7, true);


--
-- Name: series_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.series_id_seq', 1, false);


--
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscriptions_subscription_id_seq', 4, true);


--
-- Name: table_name_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.table_name_id_seq', 8, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


--
-- PostgreSQL database dump complete
--

