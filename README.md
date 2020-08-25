# ForumTopics BOB replacement project

## Context

Dave is maintaing the ForumTopics BOB since... a long time. He want to retire and shut down / save as read-only the actual BOB forum. Some members wants to keep BOB running, but it need to be updated.

## Actual BOB

- running on phpBB 2

Dave, 2019 dec
> I would not restrict the options to just phpBB3. With all of the enhancements (phpBB calls them "mods") the conversion process from phpBB2 to phpBB3 will not work. I've actually tested it...years ago, to be sure...but at the time it did not work. 

Dave, 2020, aug
> When phpBB3 came out there definitely was an upgrade path / conversion process. The problem is, for better or worse, I made a significant number of changes to the system. It would be okay if I had just added, but I actually removed some fields that I knew we were not going to use.

## BOB2 specs 

TODO

## BOB2 candidates

- `phpBB3` there is a migration path from phpBB2 but the current schema will prevent from using this migration path.
- `discourse` another forum solution. migration path available from phpBB3 but not from phpBB2
- `flarum` still in beta.

This repo is working on the `Discourse` import as it seems to be a popular and recognized forum solution today.
`flarum` seems too young, and `phpBB3` seems to not have all the common feature we are waiting for in 2020.

# Discourse import

The goal of the subproject is to import existing `bobbeta.sql` file to discourse forum server
(this file have been provided by Dave as a test file).

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

docker-compose up
```

See on http://localhost.lan:80 for a running Discourse server.

### Import data to postgresql

```
docker-compose exec -T postgresql psql -U bn_discourse bitnami_application < bobbeta.pgsql
```

Discourse data is in the `public` schema, and PhpBB2 in `database` schema.

### Migrate data from phpBB2 to Discourse

```
docker-compose exec -T postgresql psql -U bn_discourse bitnami_application < phpbb2_discourse.pgsql
```

This script will:
* Create categories from categories
* Create categories from forums
* Create categories from sub-forums
* Create topics from topics
* Create posts from posts
* Create users from users

## Push files

TODO 
```
cp emojis/* 
```

### Generate content

Recreate `cooked` from `raw` (this will handle most of BBcode !)

```
docker-compose exec discourse bash
cd /opt/bitnami/discourse
RAILS_ENV=production bundle exec rake posts:rebake
RAILS_ENV=production bundle exec rake posts:refresh_oneboxes
RAILS_ENV=production bundle exec rake posts:reorder_posts
RAILS_ENV=production bundle exec rake users:recalculate_post_counts
```

## Push to test system

There is a deployed test system here: 

https://bob-discourse.eastus.cloudapp.azure.com


- drop the phpbb2 export and migration script on the server

```
cd discourse/
scp *.pgsql bob-discourse.eastus.cloudapp.azure.com:
```

- login the server and import both

```
ssh bob-discourse.eastus.cloudapp.azure.com
sudo docker exec -i --user postgres app psql discourse < bobbeta.pgsql
sudo docker exec -i --user postgres app psql discourse < phpbb2_discourse.pgsql
```

- run post commands

```
sudo /var/discourse/launcher enter app
rake posts:rebake
...
```
### Utils

- `sudo docker exec -it --user postgres app psql discourse` login to the postgres server
- `sudo /var/discourse/launcher enter app` login to the dicsourse container 

Some postgres commands:
- `\l` list databases
- `\c dbname` select a database
- `\dt` list tables in current database
- `\dn` list schemas in current database
- `\d+ users` list columns in the users table

## TODO
- emoji
- recompute some fields in the DB