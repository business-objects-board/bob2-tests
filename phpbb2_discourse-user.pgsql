-- simple script that copy phpbb2 users to discourse
-- use same id in discourse as set in phpbb2
-- warning remove all content before import !!

-- don't delete users
delete from users where id > 1;
delete from user_emails where user_id > 1;
delete from user_options where user_id > 1;
delete from user_profiles where user_id > 1;
delete from user_stats where user_id > 1;

-- Insert users

insert into users (id, username, name, active, created_at, updated_at, previous_visit_at, username_lower, trust_level, approved)
select user_id, username, username, user_active, to_timestamp(user_regdate), to_timestamp(user_regdate), to_timestamp(user_lastvisit), lower(username), 1, true
from "database".busobj_users
where user_id > 1;

insert into user_emails (id, user_id, email, "primary", created_at, updated_at)
select user_id, user_id, user_email, true, to_timestamp(user_regdate), to_timestamp(user_regdate)
from "database".busobj_users
where user_id > 1;

insert into user_options (user_id)
select user_id
from "database".busobj_users
where user_id > 1;

insert into user_profiles (user_id)
select user_id
from "database".busobj_users
where user_id > 1;

insert into user_stats (user_id, new_since)
select user_id, to_timestamp(user_regdate)
from "database".busobj_users
where user_id > 1;


-- Reset sequences

select setval('users_id_seq', max(id)) from users;
select setval('user_emails_id_seq', max(id)) from user_emails;
