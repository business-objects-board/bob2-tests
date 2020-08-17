# Discourse import

The goal of the subproject is to import existing `bobbeta.sql` file to discourse forum server.

## A few things

- there is some docker image of discourse (https://hub.docker.com/r/bitnami/discourse/)
- discourse rely on postgresql so it is needed to convert existing mysql sql data to postgresql

## Process

### Migrate from mysql to postgresql

using https://github.com/narayandreamer/mysql2pgsql-docker to generate an equivalent pgsql import file.

```
git clone git@github.com:narayandreamer/mysql2pgsql-docker.git
rm mysql2pgsql-docker/migrations/*

cp ../*.sql mysql2pgsql-docker/migrations/

cd mysql2pgsql-docker

docker-compose up -d

docker-compose exec postgres pgloader \
 mysql://user:password@mysql:3306/database \
 postgresql://postgres:root@localhost:5432/postgres

docker-compose exec postgres pg_dump -U postgres postgres > bobbeta.pgsql
```

### Run discourse via docker

Rely on https://hub.docker.com/r/bitnami/discourse/

```
curl -sSL https://raw.githubusercontent.com/bitnami/bitnami-docker-discourse/master/docker-compose.yml > docker-compose.yml

docker-compose up -d
```

See on http://localhost.lan:80 for a running Discourse server.

### Import data to postgresql

```
docker-compose exec -T postgresql psql -U postgres bitnami_application < bobbeta.pgsql
```

Discourse data is in the `public` schema, and PhpBB2 in `database` schema.

### Migrate data from phpBB2 to Discourse

```
docker-compose exec -T postgresql psql -U postgres bitnami_application < phpbb2_discourse.pgsql
```

WORK IN PROGRESS