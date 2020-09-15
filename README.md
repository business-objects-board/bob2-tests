# ForumTopics BOB replacement project

## Context

Dave is maintaing the [ForumTopics BOB forum](http://www.forumtopics.com/busobj/) since... a long time. He want to retire and shut down / save as read-only the actual BOB forum. Some members wants to keep BOB running, but it need to be updated. So there is a [BOB 2.0 project](http://www.forumtopics.com/busobj/viewtopic.php?t=254765)

## Actual BOB

- running on phpBB 2

Dave, 2019 dec
> I would not restrict the options to just phpBB3. With all of the enhancements (phpBB calls them "mods") the conversion process from phpBB2 to phpBB3 will not work. I've actually tested it...years ago, to be sure...but at the time it did not work. 

Dave, 2020, aug
> When phpBB3 came out there definitely was an upgrade path / conversion process. The problem is, for better or worse, I made a significant number of changes to the system. It would be okay if I had just added, but I actually removed some fields that I knew we were not going to use.

## BOB2 specs 

- Keep the content live
- Upgrade/Change the software because it is too old actually

## BOB2 candidates

- `phpBB3` there is a migration path from phpBB2 but the current schema will prevent from using this migration path.
- `discourse` another forum solution. migration path available from phpBB3 but not from phpBB2
- `flarum` still in beta.

This repo is working on the `Discourse` import as it seems to be a popular and recognized forum solution today.
`flarum` seems too young, and `phpBB3` seems to not have all the common feature we are waiting for a forum in 2020.

# Discourse import

The goal of the subproject is to import existing `bobbeta.sql` file to discourse forum server
(this file have been provided by Dave as a test file).

## A few things

- a docker test image (https://hub.docker.com/r/bitnami/discourse/)
- Discourse rely on postgresql so it is needed to convert existing `mysql` data to `postgresql`
- setup discourse for production usage in 30mn (https://github.com/discourse/discourse/blob/master/docs/INSTALL-cloud.md)

## Process

### Migrate from mysql to postgresql

using https://github.com/narayandreamer/mysql2pgsql-docker to generate an equivalent pgsql import file.

```
git clone https://github.com/narayandreamer/mysql2pgsql-docker.git
cp data/*.sql mysql2pgsql-docker/migrations/
cp pg.load mysql2pgsql-docker/
cd mysql2pgsql-docker
docker-compose up 
docker-compose exec postgres pgloader -v pg.load
docker-compose exec postgres pg_dump -U postgres postgres > bobbeta.pgsql
```

### Run discourse via docker using bitnami image (for development purpose only)

Rely on https://hub.docker.com/r/bitnami/discourse/

```
curl -sSL https://raw.githubusercontent.com/bitnami/bitnami-docker-discourse/master/docker-compose.yml > docker-compose.yml
docker-compose up
```

See on http://localhost.lan:80 for a running Discourse server.

### Import and migrate data to postgresql

```
docker-compose exec -T postgresql psql -U bn_discourse bitnami_application < bobbeta.pgsql
docker-compose exec -T postgresql psql -U bn_discourse bitnami_application < phpbb2_discourse-user.pgsql
docker-compose exec -T postgresql psql -U bn_discourse bitnami_application < phpbb2_discourse-content.pgsql
```

Discourse data is in the `public` schema, and PhpBB2 in `database` schema.

The `phpbb2_discourse.pgsql` script will:
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

### Refresh content

Recreate `cooked` from `raw` (this will handle most of BBcode !)

```
docker-compose exec discourse bash
cd /opt/bitnami/discourse
RAILS_ENV=production bundle exec rake posts:refresh_oneboxes
RAILS_ENV=production bundle exec rake posts:reorder_posts
RAILS_ENV=production bundle exec rake users:recalculate_post_counts
```

It is then possible to generate the postgres discours dump: (you can remove the `database` schema first)

```
docker-compose exec postgresql pg_dump -U postgres postgres > bob_discourse.pgsql
```

## Production deploy

Follow [this](https://github.com/discourse/discourse/blob/master/docs/INSTALL-cloud.md) to
setup a production ready discourse instance.
 
_There is a deployed test system [here](https://bob-discourse.eastus.cloudapp.azure.com)_

- drop files on the server

```
scp *.pgsql bob-discourse.eastus.cloudapp.azure.com:
rsync emojis/* bob-discourse.eastus.cloudapp.azure.com:/var/discourse/shared/standalone/uploads/default/original/1X
```
TODO other files !

- login the server and import data, same as on dev

```
ssh bob-discourse.eastus.cloudapp.azure.com
sudo docker exec -i --user postgres app psql discourse < bob_move.pgsql
sudo docker exec -i --user postgres app psql discourse < phpbb2_discourse.pgsql
```

### Utils

- `sudo docker exec -it --user postgres app psql discourse` login to the postgres server
- `sudo /var/discourse/launcher enter app` login to the discourse container 

Some postgres commands:
- `\l` list databases
- `\c dbname` select a database
- `\dt` list tables in current database
- `\dn` list schemas in current database
- `\d+ users` list columns in the users table

Some discourse rake commands:
- `rake --lists` list possible tasks

## TODO

- File management for uploads/
- Handle signature
- Handle flags!
