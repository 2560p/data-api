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

## Backup and Restore

### psql
psql is a terminal-based front-end to Postgres. It enables you to type in queries interactively, issue them to Postgres, and see the query results.

#### options:
*   -f filename

--file=filename 
Read commands from the file filename, rather than standard input.

*   -h hostname

--host=hostname 
Specifies the host name of the machine on which the server is running. If the value begins with a slash, it is used as the directory for the Unix-domain socket.

*   -p port

--port=port 
Specifies the TCP port or the local Unix-domain socket file extension on which the server is listening for connections. Defaults to the value of the PGPORT environment variable or, if not set, to the port specified at compile time, usually 5432.

### pg_dump
Extract a Postgres database into a script file
pg_dump [ -h host ] [ -p port ]

#### options:
*   -h host

Specifies the hostname of the machine on which the postmaster is running. Defaults to using a local Unix domain socket rather than an IP connection..

*   -p port

Specifies the Internet TCP/IP port or local Unix domain socket file extension on which the postmaster is listening for connections. The port number defaults to 5432, or the value of the PGPORT environment variable (if set).

### Create backup 
data only and providing the schema

```
pg_dump -h localhost -p 5432 -U postgres -F c -b -v -f 
"/usr/local/backup/10.70.0.61.backup" old_db
-F c is custom format (compressed, and able to do in parallel with -j N) -b is including blobs, -v is verbose, -f is the backup file name.
```

### Restore from backup

```
psql -h localhost -p 5432 -U postgres -d old_db -v 
"/usr/local/backup/10.70.0.61.backup"
```