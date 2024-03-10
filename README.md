# Netfix API

This repository contains the source code for netflix-api.

## Installation and running

-   To run the project, clone the repository first.
-   As it is cloned, create `.env` (make sure it follows the same structure as `.env.dist`).
-   Make sure you have Docker installed. Run `docker-compose up --build` to build the project initially.
-   The docker script will create a database structure and fill the database with basic data.
-   To run the project after the initial installation, use `docker-compose up`.

## Backup and Restore

In order to successfully create a backup of the database, you would have to have Postgres command line tools installed and accessible through the command line (in the _PATH_) of any choice.

Here is a bit of information on the tools we propose to use for the backups.

### `pg_dump`

`pg_dump` extracts a Postgres database into a script file.

#### Configurable options:

-   `-h host`

Specifies the hostname of the machine on which the database is running.

-   `-p port`

Specifies the port the database is listening for connections on. The port number defaults to 5432, or the value of the PGPORT environment variable (if set).

-   `-f file_name`

The name of (the path to) the backup file. Can contain directories (for example, `backups/2024-01-01.dump`) or be a full path (`C:\backups\2024-01-01.dump`). **The directories should be created before executing the commands.**

### `pg_restore`

`pg_restore` is a utility for restoring a Postgres database from an archive created by `pg_dump`.

#### Configurable options:

-   `-h hostname`

Specifies the host name of the machine on which the server is running. If the value begins with a slash, it is used as the directory for the Unix-domain socket.

-   `-p port`

Specifies the port the database is listening for connections on. The port number defaults to 5432, or the value of the PGPORT environment variable (if set).

### Create backup

Both commands will require you to enter the password for _postgres_ user. It is set in the `.env`. Here is an example of how to create a backup and then restore it.

_Please note, this will create a backup in the directory named 'backups' (it has to be created first). You can always apply configurable options of your choice._

```
pg_dump netflix_api -h localhost -U postgres --clean -F c -f backups/2024-01-01.dump
```

### Restore from backup

To restore the database from an existing backup file, run the following command:

```
pg_restore backups/2024-01-01.dump -d netflix_api --disable-triggers --clean --single-transaction -h localhost -U postgres
```

### Advice

The group advises to create backups every day and keep the old backups for 1 month.
