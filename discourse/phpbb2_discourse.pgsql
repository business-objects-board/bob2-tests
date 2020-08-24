-- Purge

delete from categories;
delete from category_groups;
delete from topics;
delete from posts;
delete from uploads where id>0;
delete from post_uploads;
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

-- Insert categories as categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower)
select cat_id, cat_title, cat_order, now(), now(), -1, 'todo-' || cat_id, lower(cat_title) from database.busobj_categories c;

-- Insert forums as sub-categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id)
select forum_id+100, forum_name, forum_order, now(), now(), -1, 'todo-' || forum_id+100, lower(forum_name), cat_id
from "database".busobj_forums
where parent_forum_id=0;

-- Insert sub-forums as sub-sub-categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id)
select forum_id+100, forum_name, forum_order, now(), now(), -1, 'todo-' || forum_id+100, lower(forum_name), parent_forum_id+100
from "database".busobj_forums
where parent_forum_id!=0;

-- Insert forum security -> Staff only to be more precise after

insert into category_groups (category_id, group_id, created_at, updated_at, permission_type)
select forum_id+100, 3 /* Staff */, now(), now(), 1 from "database".busobj_forums where auth_view <> 0;

update categories set read_restricted=true where id in
(select forum_id+100 from "database".busobj_forums where auth_view <> 0);

-- Insert topics

insert into topics (id, title, category_id, created_at, updated_at, last_post_user_id, bumped_at)
select topic_id, topic_title, forum_id+100, to_timestamp(topic_time), to_timestamp(topic_time), -1, now() 
from database.busobj_topics;

-- Insert posts

insert into posts (id, user_id, topic_id, post_number, raw, cooked, created_at, updated_at, last_version_at, sort_order)
select p.post_id, p.poster_id, p.topic_id, p.post_id, t.post_text, t.post_text, to_timestamp(p.post_time), 
case when p.post_edit_time is null then to_timestamp(p.post_time) else to_timestamp(p.post_edit_time) end, 
case when p.post_edit_time is null then to_timestamp(p.post_time) else to_timestamp(p.post_edit_time) end, 
1 from database.busobj_posts p
join database.busobj_posts_text t on p.post_id=t.post_id and p.post_edit_count=t.post_version;

-- Update bbcode issues (like [quote:0681c43013="Michael"])

-- update bbcode quote (add extra line-break because discourse parser limitation https://meta.discourse.org/t/bbcode-quote-tag-and-mixed-newlines/103708/3)
update posts set raw = regexp_replace(raw, '\[quote:(\w*)="([a-zA-Z0-9_ ]*)"\]', chr(10) || '[quote="\2"]' || chr(10), 'g');
update posts set raw = regexp_replace(raw, '\[quote:(\w*)\]', chr(10) || '[quote]' || chr(10), 'g');
update posts set raw = regexp_replace(raw, '\[/quote:(\w*)\]', chr(10) || '[/quote]' || chr(10), 'g');

-- update bbcode b
update posts set raw = regexp_replace(raw, '\[b:(\w*)\]', '[b]', 'g');
update posts set raw = regexp_replace(raw, '\[/b:(\w*)\]', '[/b]', 'g');

-- update bbcode i
update posts set raw = regexp_replace(raw, '\[i:(\w*)\]', '[i]', 'g');
update posts set raw = regexp_replace(raw, '\[/i:(\w*)\]', '[/i]', 'g');

-- update bbcode u
update posts set raw = regexp_replace(raw, '\[u:(\w*)\]', '[u]', 'g');
update posts set raw = regexp_replace(raw, '\[/u:(\w*)\]', '[/u]', 'g');

-- update bbcode list
update posts set raw = regexp_replace(raw, '\[list:(\w*)\]', '[list]', 'g');
update posts set raw = regexp_replace(raw, '\[/list:(\w*)\]', '[/list]', 'g');
update posts set raw = regexp_replace(raw, '\[/list:\w:(\w*)\]', '[/list]', 'g');

-- update bbcode img
update posts set raw = regexp_replace(raw, '\[img:(\w*)\]', '[img]', 'g');
update posts set raw = regexp_replace(raw, '\[/img:(\w*)\]', '[/img]', 'g');

-- update bbcode code (add extra line-break)
update posts set raw = regexp_replace(raw, '\[code:\d:(\w*)\]', chr(10) || '[code]' || chr(10), 'g');
update posts set raw = regexp_replace(raw, '\[/code:\d:(\w*)\]', chr(10) || '[/code]' || chr(10), 'g');

-- update bbcode color (not done for the moment because rely on a plugin https://meta.discourse.org/t/discourse-bbcode-color/65363)
-- update posts set raw = regexp_replace(raw, '\[color=(#\w*):(\w*)\]', '[color=\1]', 'g');
-- update posts set raw = regexp_replace(raw, '\[/color:(\w*)\]', '[/color]', 'g');

-- remove bbcode color
update posts set raw = regexp_replace(raw, '\[color=(#\w*):(\w*)\]', '', 'g');
update posts set raw = regexp_replace(raw, '\[/color:(\w*)\]', '', 'g');

-- remove bbcode size (https://meta.discourse.org/t/discourse-bbcode/65425 doable but plugin)
update posts set raw = regexp_replace(raw, '\[size=\d+:(\w*)\]', '', 'g');
update posts set raw = regexp_replace(raw, '\[/size:(\w*)\]', '', 'g');

-- Insert uploads

insert into uploads (id, user_id, original_filename, filesize, url, created_at, updated_at, "extension")
select a.attach_id, a.user_id_1, d.real_filename, d.filesize, '/uploads/default/original/1X/' || d.physical_filename, to_timestamp(d.filetime), to_timestamp(d.filetime), d."extension" from "database".busobj_attachments a
join "database".busobj_attachments_desc d on a.attach_id=d.attach_id;


-- Add in posts the images

DO $$
declare
    temprow record;
begin
	for temprow in
		select  a.post_id post_id,
		'![' || d.real_filename || '](/uploads/default/original/1X/' || d.physical_filename || ')' markdown
		from "database".busobj_attachments a
		join "database".busobj_attachments_desc d on a.attach_id=d.attach_id
		where substring(d.mimetype,1,5)='image'
	loop
		update posts set raw = raw || chr(10) /* new line */ || temprow.markdown where id = temprow.post_id;
	end loop;
end
$$;

-- Add in posts the other files

DO $$
declare
    temprow record;
begin
	for temprow in
		select  a.post_id post_id,
		'[' || d.real_filename || '|attachment](/uploads/default/original/1X/' || d.physical_filename || ') (' || round(d.filesize/1000,1) || ' KB)' markdown
		from "database".busobj_attachments a
		join "database".busobj_attachments_desc d on a.attach_id=d.attach_id
		where substring(d.mimetype,1,5)!='image'
	loop
		update posts set raw = raw || chr(10) /* new line */ || temprow.markdown where id = temprow.post_id;
	end loop;
end
$$;

insert into post_uploads (id, post_id, upload_id)
select attach_id, post_id, attach_id from "database".busobj_attachments;

-- Reset sequences

select setval('users_id_seq', max(id)) from users;
select setval('user_emails_id_seq', max(id)) from user_emails;
select setval('categories_id_seq', max(id)) from categories;
select setval('topics_id_seq', max(id)) from topics;
select setval('posts_id_seq', max(id)) from posts;
select setval('uploads_id_seq', max(id)) from uploads;
select setval('post_uploads_id_seq', max(id)) from post_uploads;


-- Update stats

update topics t set posts_count = (select count(id) from posts p where p.topic_id=t.id);
update topics t set last_posted_at = (select max(updated_at) from posts p where p.topic_id=t.id);
