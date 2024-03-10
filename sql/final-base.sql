--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.2 (Homebrew)

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

--
-- Roles
--

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
-- Name: age; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.age AS ENUM (
    '0',
    '6',
    '9',
    '12',
    '16'
);


ALTER TYPE public.age OWNER TO postgres;

--
-- Name: content; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.content AS ENUM (
    'SERIES',
    'FILM'
);


ALTER TYPE public.content OWNER TO postgres;

--
-- Name: entity_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.entity_type AS ENUM (
    'ADMIN',
    'USER'
);


ALTER TYPE public.entity_type OWNER TO postgres;

--
-- Name: plan; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.plan AS ENUM (
    'SD',
    'HD',
    'UHD'
);


ALTER TYPE public.plan OWNER TO postgres;

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
declare
    v_admin_exists BOOLEAN;
    admin_id integer;
    ret record;
begin
    begin
        select exists (select 1 from admins where email = p_email) into v_admin_exists;

        if v_admin_exists then
            select -1, 0 into ret;
        else
            insert into admins (email, password, role)
            values (p_email, p_password, p_role) returning id into admin_id;
            select 1, admin_id into ret;
        end if;
    exception
        when others then
            raise notice 'An exception occurred in admin_register function';
            select -2, 0 into ret;
    end;
    return ret;
end;
$$;


ALTER FUNCTION public.admin_register(p_email character varying, p_password character varying, p_role public.role_type) OWNER TO postgres;

--
-- Name: admin_retrieve_password_hash(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.admin_retrieve_password_hash(p_email character varying) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare
    v_admin_exists BOOLEAN;
    ret record;
begin
    begin
        select EXISTS (select 1 from admins where email = p_email) into v_admin_exists;

        if v_admin_exists then
            select password, id
            from admins
            where email = p_email into ret;
        else
            select -1, 0 into ret;
        end if;
    exception
        when others then
            raise notice 'An exception occurred in admin_retrieve_password_hash function';
            select -2, 0 into ret;
    end;
    return ret;
end;
$$;


ALTER FUNCTION public.admin_retrieve_password_hash(p_email character varying) OWNER TO postgres;

--
-- Name: check_id_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_id_role() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if NEW.entity_type = 'ADMIN' and not exists (select 1 from admins WHERE id = NEW.entity_id) then
        raise exception 'Invalid id for the specified role';
    end if;

    if NEW.entity_type = 'USER' and not exists (select 1 from users WHERE id = NEW.entity_id) then
        raise exception 'Invalid id for the specified role';
    end if;

    return new;
end;
$$;


ALTER FUNCTION public.check_id_role() OWNER TO postgres;

--
-- Name: check_profile_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_profile_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    profile_count int;
begin
    select count(*) into profile_count
    from profiles
    where user_id = NEW.user_id;

    if profile_count >= 4 then
        raise exception 'Cannot exceed 4 profiles per user.';
    end if;

    return new;
end;
$$;


ALTER FUNCTION public.check_profile_limit() OWNER TO postgres;

--
-- Name: get_sorted_movies(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies() RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
begin
    return query
    (
        select
            m.title as name
        from
            media m
            left join liked_media on m.id = liked_media.media_id
        group by
            m.id, m.title
        order by
            count(*) DESC
        limit 3
    )
    union all
    (
        select
            m.title as name
        from
            media m
        left join liked_media on m.id = liked_media.media_id
        group by
            m.id, m.title
        order by
            count(*) desc
        limit 3
    )
    union all
    (
        select
            m.title as name
        from
            media m
        left join liked_media on m.id = liked_media.media_id
        group by
            m.id, m.title
        order by
            count(*)
        limit 3
    )
    union all
    (
        select
            m.title as name
        from
            media m
        left join liked_media on m.id = liked_media.media_id
        order by
            count(*)
        limit 3
    );
exception
    when others then
        raise notice 'An exception occurred in get_sorted_movies function';
        return;
end;
$$;


ALTER FUNCTION public.get_sorted_movies() OWNER TO postgres;

--
-- Name: get_sorted_movies_least_liked(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_least_liked() RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
begin
    return query
         select
            m.title AS name
        from
            media m
        left join liked_media on m.id = liked_media.media_id
        group by
            m.id, m.title
        order by
            count(*)
        limit 3;
exception
    when others then
        raise notice 'An exception occurred in get_sorted_movies_least_liked function';
        return;
end;
$$;


ALTER FUNCTION public.get_sorted_movies_least_liked() OWNER TO postgres;

--
-- Name: get_sorted_movies_least_viewed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_least_viewed() RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
begin
    return query
        select
            m.title as name
        from
            media m
        left join liked_media on m.id = liked_media.media_id
        group by
            m.id, m.title
        order by
            count(*)
        limit 3;
exception
when others then
    raise notice 'An exception occurred in get_sorted_movies_least_viewed function';
    return;
end;
$$;


ALTER FUNCTION public.get_sorted_movies_least_viewed() OWNER TO postgres;

--
-- Name: get_sorted_movies_most_liked(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_most_liked() RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
begin
    return query
        select
            m.title as name
        from
            media m
        left join liked_media on m.id = liked_media.media_id
        group by
            m.id, m.title
        order by
            count(*) desc
        limit 3;
exception
    when others then
        raise notice 'An exception occurred in get_sorted_movies_most_liked function';
        return;
end;
$$;


ALTER FUNCTION public.get_sorted_movies_most_liked() OWNER TO postgres;

--
-- Name: get_sorted_movies_most_viewed(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sorted_movies_most_viewed(desired_year integer, desired_month integer) RETURNS TABLE(name character varying)
    LANGUAGE plpgsql
    AS $$
begin
    return query
    select
        m.title
    from
        media m
    left join (
        select
            media_id
        from
            watch_history
        where
            extract(year from date) = desired_year
            and extract(month from date) = desired_month
    ) wh on m.id = wh.media_id
    group by
        m.id, m.title
    order by
        count(*) desc
    limit 3;
exception
    when others then
        raise notice 'An exception occurred in get_sorted_movies_most_viewed function';
        return;
end;
$$;


ALTER FUNCTION public.get_sorted_movies_most_viewed(desired_year integer, desired_month integer) OWNER TO postgres;

--
-- Name: get_watch_count_per_person(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_watch_count_per_person(p_profileid integer, p_mediaid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
    v_WatchCount int;
begin
    begin
        select count(*) into v_WatchCount
        from watch_history
        where profile_id = p_ProfileID and media_id = p_MediaID;

        return v_WatchCount;
    exception
    when others then
        raise notice 'An exception occurred in get_watch_count_per_person function';
        return -1;
    end;
end;
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
begin
    begin
        return query
        select
            m.id,
            COUNT(*)::int as view_count
        from
            watch_history wh
        join
            media m on wh.media_id = m.id
        where
            m.type = 'FILM'
        group by
            m.id
        order by
            view_count desc
        limit 3;
    exception
        when others then
            raise notice 'An exception occurred in most_viewed_movies function';
            return;
    end;
end;
$$;


ALTER FUNCTION public.most_viewed_movies() OWNER TO postgres;

--
-- Name: toggle_media_like(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.toggle_media_like(p_profileid integer, p_mediaid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
    v_AlreadyLiked BOOLEAN;
begin
    begin
        select exists (
            select 1 from liked_media
            where profile_id = p_ProfileID and media_id = p_MediaID
        ) into v_AlreadyLiked;
    
        if v_AlreadyLiked then
            delete from liked_media
            where profile_id = p_ProfileID and media_id = p_MediaID;
    
            raise notice 'Like removed for MediaID: %', p_MediaID;
        else
            insert into liked_media (profile_id, media_id)
            values (p_ProfileID, p_MediaID);
    
            raise notice 'Like added for MediaID: %', p_MediaID;
        end if;
    exception
    when others then
        raise notice 'An exception occurred in toggle_media_like function';
        return;
    end;
end;
$$;


ALTER FUNCTION public.toggle_media_like(p_profileid integer, p_mediaid integer) OWNER TO postgres;

--
-- Name: update_cost_trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_cost_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    begin
        if (NEW.has_invited is not null and OLD.has_invited is null) or
           (NEW.invited_by is not null and OLD.invited_by is null) then
            NEW.cost_per_month := NEW.cost_per_month - 2;
        end if;
    
        return new;
    exception
        when others then
            raise notice 'An exception occurred in update_cost_trigger_function';
            return null;
    end;
end;
$$;


ALTER FUNCTION public.update_cost_trigger_function() OWNER TO postgres;

--
-- Name: update_currently_watched(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_currently_watched(IN p_profileid integer, IN p_mediaid integer, IN p_progressseconds integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM currently_watched
            WHERE profile_id = p_profileid AND media_id = p_mediaid
        ) THEN
            UPDATE currently_watched
            SET progress_seconds = p_progressseconds,
                last_watched = CURRENT_TIMESTAMP
            WHERE profile_id = p_profileid AND media_id = p_mediaid;
        ELSE
            INSERT INTO currently_watched (profile_id, media_id, progress_seconds)
            VALUES (p_profileid, p_mediaid, p_progressseconds);
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE EXCEPTION 'An error occurred during the update.';
    END;
END;
$$;


ALTER PROCEDURE public.update_currently_watched(IN p_profileid integer, IN p_mediaid integer, IN p_progressseconds integer) OWNER TO postgres;

--
-- Name: user_register(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_register(p_email character varying, p_password character varying) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare
    v_user_exists BOOLEAN;
    user_id integer;
    ret record;
begin
    begin
        select EXISTS (select 1 from users where email = p_email) into v_user_exists;
    
        if v_user_exists then
            select -1, 0 into ret;
        else
            insert into users (email, password)
            values (p_email, p_password) returning id into user_id;
            select 1, user_id into ret;
        end if;
    exception
        when others then
            raise notice 'An exception occurred in user_register function';
            select -2, 0 into ret;
    end;
    return ret;
end;
$$;


ALTER FUNCTION public.user_register(p_email character varying, p_password character varying) OWNER TO postgres;

--
-- Name: user_retrieve_password_hash(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_retrieve_password_hash(p_email character varying) RETURNS record
    LANGUAGE plpgsql
    AS $$
declare
    v_user_exists BOOLEAN;
    ret record;
begin
    begin
        select exists (select 1 from users where email = p_email) into v_user_exists;

        if v_user_exists then
            select password, id
            from users
            where email = p_email into ret;
        else
            select -1, 0 into ret;
        end if;
    exception
        when others then
            raise notice 'An exception occurred in user_retrieve_password_hash function';
            SELECT -2, 0 INTO ret;
    end;
    return ret;
end;
$$;


ALTER FUNCTION public.user_retrieve_password_hash(p_email character varying) OWNER TO postgres;

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
    media_id integer NOT NULL,
    number integer NOT NULL,
    location character varying(256),
    name text,
    title text,
    duration integer
);


ALTER TABLE public.episodes OWNER TO postgres;

--
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    id integer NOT NULL,
    name character varying(256) NOT NULL,
    age public.age NOT NULL
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- Name: genre_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genre_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genre_genre_id_seq OWNER TO postgres;

--
-- Name: genre_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genre_genre_id_seq OWNED BY public.genres.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languages (
    id integer NOT NULL,
    name character varying(256) NOT NULL
);


ALTER TABLE public.languages OWNER TO postgres;

--
-- Name: language_language_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.language_language_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.language_language_id_seq OWNER TO postgres;

--
-- Name: language_language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.language_language_id_seq OWNED BY public.languages.id;


--
-- Name: liked_media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.liked_media (
    profile_id integer NOT NULL,
    media_id integer NOT NULL
);


ALTER TABLE public.liked_media OWNER TO postgres;

--
-- Name: media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.media (
    id integer NOT NULL,
    title character varying(256) NOT NULL,
    description text,
    poster character varying(256),
    duration integer,
    location character varying(256),
    rating integer,
    language_id integer,
    genre_id integer,
    type public.content NOT NULL
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
-- Name: media_watch_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.media_watch_details AS
 SELECT m.id,
    m.title,
    m.duration,
    m.rating,
    l.name AS language,
    g.name AS genre,
    m.type
   FROM ((public.media m
     JOIN public.languages l ON ((m.language_id = l.id)))
     JOIN public.genres g ON ((m.genre_id = g.id)))
  ORDER BY m.rating DESC
 LIMIT 10;


ALTER VIEW public.media_watch_details OWNER TO postgres;

--
-- Name: most_popular_genre; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.most_popular_genre AS
 SELECT g.name AS genre,
    count(*) AS media_count
   FROM (public.media m
     JOIN public.genres g ON ((m.genre_id = g.id)))
  GROUP BY g.name
  ORDER BY (count(*)) DESC;


ALTER VIEW public.most_popular_genre OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(256),
    birthdate date NOT NULL,
    photo character varying(256)
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
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refresh_tokens (
    entity_id integer NOT NULL,
    entity_type public.entity_type NOT NULL,
    token character(32) NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


ALTER TABLE public.refresh_tokens OWNER TO postgres;

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriptions (
    user_id integer,
    start_date date NOT NULL,
    end_date date NOT NULL,
    id integer NOT NULL,
    cost_per_month numeric(8,2) NOT NULL,
    has_invited integer,
    invited_by integer,
    type public.plan NOT NULL
);


ALTER TABLE public.subscriptions OWNER TO postgres;

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
-- Name: subscription_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.subscription_stats AS
 SELECT p.type AS plan,
    count(u.id) AS number_of_users,
    sum(p.cost_per_month) AS total_expected_cost_per_month
   FROM (public.subscriptions p
     JOIN public.users u ON ((p.user_id = u.id)))
  GROUP BY p.type;


ALTER VIEW public.subscription_stats OWNER TO postgres;

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

ALTER SEQUENCE public.subscriptions_subscription_id_seq OWNED BY public.subscriptions.id;


--
-- Name: subtitles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subtitles (
    media_id integer NOT NULL,
    url character varying(256) NOT NULL,
    language_id integer NOT NULL
);


ALTER TABLE public.subtitles OWNER TO postgres;

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
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN id SET DEFAULT nextval('public.genre_genre_id_seq'::regclass);


--
-- Name: languages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages ALTER COLUMN id SET DEFAULT nextval('public.language_language_id_seq'::regclass);


--
-- Name: media id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.media_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_subscription_id_seq'::regclass);


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
-- Name: episodes episodes_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_pk PRIMARY KEY (media_id, number);


--
-- Name: genres genre_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genre_pkey PRIMARY KEY (id);


--
-- Name: languages language_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: liked_media liked_media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liked_media
    ADD CONSTRAINT liked_media_pkey PRIMARY KEY (profile_id, media_id);


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
-- Name: refresh_tokens refresh_tokens_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pk PRIMARY KEY (entity_id, entity_type);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


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
-- Name: refresh_tokens_token_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX refresh_tokens_token_index ON public.refresh_tokens USING btree (token);


--
-- Name: profiles check_profile_limit_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_profile_limit_trigger BEFORE INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.check_profile_limit();


--
-- Name: refresh_tokens check_refresh_tokens; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_refresh_tokens BEFORE INSERT OR UPDATE ON public.refresh_tokens FOR EACH ROW EXECUTE FUNCTION public.check_id_role();


--
-- Name: episodes episodes_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_media_id_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media fk_media_language; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT fk_media_language FOREIGN KEY (language_id) REFERENCES public.languages(id);


--
-- Name: liked_media liked_media_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liked_media
    ADD CONSTRAINT liked_media_media_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: liked_media liked_media_profile_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.liked_media
    ADD CONSTRAINT liked_media_profile_fk FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media media_genre_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_genre_fk FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: media media_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(id);


--
-- Name: profiles profiles_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subtitles subtitles_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtitles
    ADD CONSTRAINT subtitles_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(id);


--
-- Name: subtitles subtitles_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subtitles
    ADD CONSTRAINT subtitles_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: watch_history watch_history_media_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watch_history
    ADD CONSTRAINT watch_history_media_id_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: watch_history watch_history_profiles_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watch_history
    ADD CONSTRAINT watch_history_profiles_id_fk FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: currently_watched watch_progress_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currently_watched
    ADD CONSTRAINT watch_progress_media_fk FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: currently_watched watch_progress_user_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currently_watched
    ADD CONSTRAINT watch_progress_user_fk FOREIGN KEY (profile_id) REFERENCES public.profiles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO junior;


--
-- Name: SEQUENCE admins_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE public.admins_id_seq TO senior;


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
-- Name: COLUMN episodes.media_id; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(media_id),UPDATE(media_id) ON TABLE public.episodes TO medior;
GRANT SELECT(media_id),INSERT(media_id),REFERENCES(media_id) ON TABLE public.episodes TO senior;


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
-- Name: COLUMN episodes.name; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT(name),UPDATE(name) ON TABLE public.episodes TO medior;
GRANT SELECT(name),INSERT(name),REFERENCES(name) ON TABLE public.episodes TO senior;


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
-- Name: TABLE media_watch_details; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.media_watch_details TO junior;
GRANT ALL ON TABLE public.media_watch_details TO medior;
GRANT ALL ON TABLE public.media_watch_details TO senior;


--
-- Name: TABLE most_popular_genre; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.most_popular_genre TO junior;
GRANT ALL ON TABLE public.most_popular_genre TO medior;
GRANT ALL ON TABLE public.most_popular_genre TO senior;


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
-- Name: TABLE subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.subscriptions TO senior;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.users TO senior;
GRANT ALL ON TABLE public.users TO medior;


--
-- Name: TABLE subscription_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.subscription_stats TO senior;


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

