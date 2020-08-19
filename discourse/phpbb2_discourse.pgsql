-- Purge

delete from categories where id>10;
delete from topics where id> 10;
delete from posts where id > 20;
delete from users where id > 1;
delete from user_emails where id > 1;
delete from user_options where id > 1;
delete from user_profiles where id > 1;
delete from user_stats where id > 1;

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

-- Insert categories as categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower)
select cat_id+10, cat_title, cat_order, now(), now(), -1, 'todo-' || cat_id, lower(cat_title) from database.busobj_categories c;

-- Insert forums as sub-categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id)
select forum_id+100, forum_name, forum_order, now(), now(), -1, 'todo-' || forum_id+100, lower(forum_name), cat_id+10
from "database".busobj_forums
where parent_forum_id=0;

-- Insert sub-forums as sub-sub-categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id)
select forum_id+100, forum_name, forum_order, now(), now(), -1, 'todo-' || forum_id+100, lower(forum_name), parent_forum_id+100
from "database".busobj_forums
where parent_forum_id!=0;

-- Insert topics

insert into topics (id, title, category_id, created_at, updated_at, last_post_user_id, bumped_at)
select topic_id+10, topic_title, forum_id+100, to_timestamp(topic_time), to_timestamp(topic_time), -1, now() 
from database.busobj_topics;

-- Insert posts

insert into posts (id, user_id, topic_id, post_number, raw, cooked, created_at, updated_at, last_version_at, sort_order)
select p.post_id+20, p.poster_id, p.topic_id+10, p.post_id, t.post_text, t.post_text, to_timestamp(p.post_time), 
case when p.post_edit_time is null then to_timestamp(p.post_time) else to_timestamp(p.post_edit_time) end, 
case when p.post_edit_time is null then to_timestamp(p.post_time) else to_timestamp(p.post_edit_time) end, 
1 from database.busobj_posts p
join database.busobj_posts_text t on p.post_id=t.post_id and p.post_edit_count=t.post_version;

-- Update stats

update topics t set posts_count = (select count(id) from posts p where p.topic_id=t.id) where t.id>10;
update topics t set last_posted_at = (select max(updated_at) from posts p where p.topic_id=t.id) where t.id>10;
