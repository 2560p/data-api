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
