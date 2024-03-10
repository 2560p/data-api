--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1 (Debian 16.1-1.pgdg120+1)
-- Dumped by pg_dump version 16.1

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

\connect netflix_api

--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.admins (id, role, email, password) VALUES (1, 'senior', 'hello', '$2a$10$zpXLS1.cu//d8opVLArte.Yv0VAsl/JfQXDCITtv5IBYYEjQ0Emla');
INSERT INTO public.admins (id, role, email, password) VALUES (2, 'senior', 'another', '$2a$10$rwlugM3eMklk45TO9KctAeDKPAB8raRsJGtDKDLbJZVHUViANaGJu');
INSERT INTO public.admins (id, role, email, password) VALUES (3, 'senior', 'someother', '$2a$10$uMMF.Eg6q8O6G6JuCnH2P./PcxOt941uV23vZ.GBmrbs4MvT6ofGK');


--
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.genres (id, name, age) VALUES (6, 'ANIMATION', '0');
INSERT INTO public.genres (id, name, age) VALUES (7, 'ADVENTURE', '6');
INSERT INTO public.genres (id, name, age) VALUES (8, 'ACTION', '9');
INSERT INTO public.genres (id, name, age) VALUES (9, 'ROMANCE', '12');
INSERT INTO public.genres (id, name, age) VALUES (10, 'HORROR', '16');


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.languages (id, name) VALUES (1, 'EN');
INSERT INTO public.languages (id, name) VALUES (2, 'NL');
INSERT INTO public.languages (id, name) VALUES (3, 'ES');
INSERT INTO public.languages (id, name) VALUES (4, 'GER');


--
-- Data for Name: media; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (2, 'gossip boys', 'hello', 'hello', 3600, 'Netherlands', 7, 1, 6, 'FILM');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (3, 'Breaking bad', 'hello', 'hello', 3600, 'Macedonia', 7, 1, 10, 'SERIES');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (4, 'smth', 'jfhdjk', 'jhjkhjh', 384, 'jdhjfdhgjf', 7, 1, 10, 'FILM');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (5, 'hrekgrhgkr', 'dufghfdjghjdh', 'hfgkhfdghfdj', 2837, 'djhkgkdfhgkfd', 9, 1, 10, 'FILM');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (6, 'Regular Show', 'fdadawuiqdnwd', 'diqwnqwidnqwid', 2332, 'qwdqdqdsa', 8, 1, 8, 'SERIES');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (7, 'Gossip Girls', 'qdknqdnqkdnq', 'diqniqwndiqwnd', 1321, 'awdadawdad', 7, 1, 7, 'SERIES');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (8, 'Howl''s Moving Castle', 'wdiqnindqdq', 'dqwnqiwndq', 3424, 'qeqwewqdq', 8, 1, 6, 'FILM');
INSERT INTO public.media (id, title, description, poster, duration, location, rating, language_id, genre_id, type) VALUES (9, 'Keep up with the Kardashians', 'qwdinqwdqwdnqi', 'iqwndiqwndqwid', 3223, 'qwfqfqfqf', 7, 1, 7, 'SERIES');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (id, email, password, status) VALUES (1, 'hellooooooooo', 'hellooooooooo', 'RESTRICTED');
INSERT INTO public.users (id, email, password, status) VALUES (2, 'hdfjhdgh', 'bdmdfjghfjhg', 'RESTRICTED');
INSERT INTO public.users (id, email, password, status) VALUES (3, 'ejhkjerhtjkreht', 'jkhfjdhgjfhgj', 'RESTRICTED');
INSERT INTO public.users (id, email, password, status) VALUES (5, 'yes', 'yes123', 'ACTIVE');
INSERT INTO public.users (id, email, password, status) VALUES (6, 'yes2', 'yes123', 'ACTIVE');
INSERT INTO public.users (id, email, password, status) VALUES (7, 'yes3', 'yes123', 'ACTIVE');


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (1, 1, 'hehe', '2008-01-01', 'example.jpeg');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (2, 1, 'haha', '2008-01-01', 'dkgjkdfg');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (3, 1, 'gfdnjkgkd', '2009-12-12', 'fkjgkfdjgkd');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (4, 2, 'ghdfjghjfd', '2010-01-01', 'dgjkfdjkfjgkf');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (5, 3, 'fjdhgfdhk', '2001-10-10', 'dsgjkfdgjkfd');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (6, 5, 'hoho', '2010-10-10', 'najdnasjdnajd');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (7, 5, 'huhu', '2009-09-09', 'wqindqndqwjkdnq');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (8, 6, 'yes1', '2004-03-03', 'adkasadkan');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (9, 6, 'yes2', '2003-02-02', 'akndakndaskd');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (10, 7, 'yes3', '2002-01-01', 'dasndaksndask');
INSERT INTO public.profiles (id, user_id, name, birthdate, photo) VALUES (11, 7, 'yes4', '2000-04-05', 'sdandkasnd');


--
-- Data for Name: currently_watched; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: episodes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: liked_media; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.liked_media (profile_id, media_id) VALUES (2, 5);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (2, 4);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (4, 3);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (3, 5);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (1, 4);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (3, 4);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (5, 6);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (5, 7);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (6, 3);
INSERT INTO public.liked_media (profile_id, media_id) VALUES (8, 9);


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.refresh_tokens (entity_id, entity_type, token, expires_at) VALUES (2, 'ADMIN', 'f9dbe824ee65b948b10409aa6363eead', '2024-03-13 15:03:39.893');
INSERT INTO public.refresh_tokens (entity_id, entity_type, token, expires_at) VALUES (3, 'ADMIN', '00f2b0e59b09a44db43fbbc353891094', '2024-03-13 15:04:20.66');
INSERT INTO public.refresh_tokens (entity_id, entity_type, token, expires_at) VALUES (1, 'ADMIN', 'ec673ea03663e649cd7f53e90ef1991c', '2024-03-13 19:33:41.613');


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: subtitles; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: watch_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (5, 6, '2010-01-01');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (4, 7, '2010-02-02');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (6, 9, '2010-03-03');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (9, 9, '2010-04-04');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (7, 8, '2010-05-05');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (7, 2, '2010-05-05');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (8, 3, '2010-05-05');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (8, 4, '2010-05-05');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (9, 5, '2010-04-04');
INSERT INTO public.watch_history (profile_id, media_id, date) VALUES (9, 9, '2010-04-04');


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_id_seq', 3, true);


--
-- Name: genre_genre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genre_genre_id_seq', 10, true);


--
-- Name: language_language_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.language_language_id_seq', 4, true);


--
-- Name: media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.media_id_seq', 9, true);


--
-- Name: profiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profiles_id_seq', 11, true);


--
-- Name: subscriptions_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscriptions_subscription_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 7, true);


--
-- PostgreSQL database dump complete
--

