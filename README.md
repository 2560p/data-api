# Netfix API

This repository contains the source code for netflix-api.

Please note: the repository's structure (with the contents) and

## Requests specifications

| Endpoint    | Request Type | Body / Query parameters                | Response                                |
| ----------- | ------------ | -------------------------------------- | --------------------------------------- |
| /register   | POST         | `{ "email": "...", "password":"..." }` | `{ "success": true, "message": "..." }` |
| /login      | POST         | `{ "email": "...", "password":"..." }` | `{ "success": true, "token": "..." }`   |
| /movies     | GET          |                                        | `[object movie, object movie...]`       |
| /movies/:id | GET          | :id                                    | `{object movie}`                        |


# Stored Procedures & Triggers
<h2>admin_register:</h2>
<li> Worked on by Paul Demenko

<h2>admin_retrieve_password_hash:</h2>
<li> Worked on by Paul Demenko

<h2>apply_discount:</h2>
<li> Worked on by Marijn Veenstra & Anastasia Lukanova

<h2>check_profile_limit:</h2>
<li> Worked on by Gabriel Guevara

<h2>get_sorted_movies:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>get_sorted_movies_least_liked:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>get_sorted_movies_least_viewed:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>get_sorted_movies_most_liked:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>get_sorted_movies_most_viewed:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>get_watch_count_per_person:</h2>
<li> Worked on by Gabriel Guevara

<h2>invite_user_discount:</h2>
<li> Worked on by Marijn Veenstra & Anastasia Lukanova

<h2>most_viewed_movies:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>toggle_media_like:</h2>
<li> Worked on by Gabriel Guevara

<h2>update_cost_trigger_function:</h2>
<li> Worked on by Marijn Veenstra & Anastasia Lukanova

<h2>update_currently_watched:</h2>
<li> Worked on by Gabriel Guevara & Marijn Veenstra

<h2>user_login:</h2>
<li> Worked on by Gabriel Guevara

<h2>user_register:</h2>
<li> Worked on by Gabriel Guevara