CREATE OR REPLACE FUNCTION slugify("value" TEXT)
RETURNS TEXT AS $$
  -- lowercases the string
  WITH "lowercase" AS (
    SELECT lower("value") AS "value"
  ),
  -- replaces anything that's not a letter, number, hyphen('-'), or underscore('_') with a hyphen('-')
  "hyphenated" AS (
    SELECT regexp_replace("value", '[^a-z0-9\\-_]+', '-', 'gi') AS "value"
    FROM "lowercase"
  ),
  -- trims hyphens('-') if they exist on the head or tail of the string
  "trimmed" AS (
    SELECT regexp_replace(regexp_replace("value", '\\-+$', ''), '^\\-', '') AS "value"
    FROM "hyphenated"
  )
  SELECT "value" FROM "trimmed";
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION create_topics(forum_oldid int, forum_newid int) RETURNS VOID AS
$$
	DECLARE
		topic_row record;
		post_row record;
		upload_row record;
		topic_newid int;
		post_newid int;
		upload_newid int;
	BEGIN
		-- raise notice 'Create topics for forum: %', forum_oldid;
		for topic_row in
			select t.topic_id, t.topic_title, to_timestamp(fp.post_time) time_first, to_timestamp(lp.post_time) time_last, 
			lp.poster_id last_poster, fp.poster_id first_poster, t.topic_views,
			t.topic_replies, case when t.topic_type=1 then now() else null end pinned_at
			from database.busobj_topics t 
			join database.busobj_posts fp on t.topic_first_post_id = fp.post_id 
			join database.busobj_posts lp on t.topic_last_post_id = lp.post_id
			where t.forum_id=forum_oldid
		loop
			-- Insert topics with all stats!
			insert into topics (title, category_id, created_at, updated_at, last_post_user_id, bumped_at, 
			user_id, last_posted_at, "views", reply_count, posts_count, pinned_at)
			values (topic_row.topic_title, forum_newid, topic_row.time_first, topic_row.time_last, topic_row.last_poster, 
			topic_row.time_last, topic_row.first_poster, topic_row.time_last, topic_row.topic_views, topic_row.topic_replies, 
			topic_row.topic_replies+1, topic_row.pinned_at)
			returning id into topic_newid;

			for post_row in 
				select p.post_id, p.poster_id, t.post_text, p.post_time, p.post_edit_time, p.post_username /* TODO flag and join date*/ 
				from database.busobj_posts p
				join database.busobj_posts_text t on p.post_id=t.post_id and p.post_edit_count=t.post_version
				where p.topic_id=topic_row.topic_id
			loop
				-- Insert posts
				insert into posts (user_id, topic_id, post_number, raw, cooked, created_at, updated_at, last_version_at, sort_order)
				values (post_row.poster_id, topic_newid, post_row.post_id, 
				post_row.post_text || chr(10) || chr(10) || '---' || chr(10) || chr(10) || '_' || post_row.post_username || chr(10) || 
						'From TODO FLAG HERE' || chr(10) || 'Member since xxxx/xx/xx' || '_', 
				post_row.post_text, 
				to_timestamp(post_row.post_time), 
				case when post_row.post_edit_time is null then to_timestamp(post_row.post_time) else to_timestamp(post_row.post_edit_time) end, 
				case when post_row.post_edit_time is null then to_timestamp(post_row.post_time) else to_timestamp(post_row.post_edit_time) end, 1)
				returning id into post_newid;

				-- for each upload of the post
				for upload_row in
					select a.user_id_1, d.real_filename, d.filesize, d.physical_filename, d.filetime, d."extension" 
					from "database".busobj_attachments a
					join "database".busobj_attachments_desc d on a.attach_id=d.attach_id
					where a.post_id=post_row.post_id
				loop
					-- insert into uploads first
					insert into uploads (user_id, original_filename, filesize, url, created_at, updated_at, "extension")
						values (upload_row.user_id_1, upload_row.real_filename, upload_row.filesize, 
						'/uploads/default/original/1X/' || upload_row.physical_filename, to_timestamp(upload_row.filetime), 
						to_timestamp(upload_row.filetime), upload_row."extension")
						returning id into upload_newid;

					-- insert into post_uploads
					insert into post_uploads (post_id, upload_id)
						values (post_newid, upload_newid);

				end loop;
			end loop;
		end loop;
	END;
$$ LANGUAGE plpgsql;

-- Delete content previously imported

DO $$
declare
    id_cat integer;
begin
	for id_cat in
		select id from categories where color='9EB83B'
	loop
		delete from uploads u
			using post_uploads pu, posts p, topics t
			where u.id=pu.upload_id
			and pu.post_id=p.id
			and p.topic_id=t.id
			and t.category_id=id_cat;
		delete from post_uploads pu
			using posts p, topics t
			where pu.post_id=p.id
			and p.topic_id=t.id
			and t.category_id=id_cat;
		delete from posts p
			using topics t
			where p.topic_id=t.id
			and t.category_id=id_cat;
		delete from topics where category_id=id_cat;
		delete from category_groups where category_id=id_cat;
		delete from categories where id=id_cat;
	end loop;
end
$$;

-- Insert categories topics posts uploads

DO $$
declare
    cat_row record;
	cat_newid integer;
	for_row record;
	for_newid integer;
	subfor_row record;
	subfor_newid integer;
begin
	-- loop in phpbb categories
	for cat_row in
		select cat_id, cat_title, cat_order from database.busobj_categories
	loop
		raise notice 'Open cat: %', cat_row.cat_id;
		insert into categories (name, sort_order, created_at, updated_at, user_id, slug, name_lower, color)
			values (cat_row.cat_title, cat_row.cat_order, now(), now(), -1, slugify(cat_row.cat_title) , lower(cat_row.cat_title), '9EB83B')
			returning id into cat_newid;

		-- loop in phpbb forums
		for for_row in
			select * from database.busobj_forums where cat_id=cat_row.cat_id and parent_forum_id=0
		loop
			raise notice 'Open forum: %', for_row.forum_id;
			insert into categories (name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id, 
				color, topic_count, read_restricted)
				values (for_row.forum_name, for_row.forum_order, now(), now(), -1, slugify(for_row.forum_name), 
				lower(for_row.forum_name), cat_newid, '9EB83B', for_row.forum_topics,
				case when for_row.auth_view<>0 then true else false end)
				returning id into for_newid;
			
			PERFORM create_topics(for_row.forum_id, for_newid);

			-- loop in phpbb sub-forums
			for subfor_row in
				select * from database.busobj_forums where parent_forum_id=for_row.forum_id
			loop
				raise notice 'Open sub-forum: %', subfor_row.forum_id;
				insert into categories (name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id, 
					color, topic_count, read_restricted)
					values (subfor_row.forum_name, subfor_row.forum_order, now(), now(), -1, slugify(subfor_row.forum_name),
					lower(subfor_row.forum_name), for_newid, '9EB83B', subfor_row.forum_topics,
					case when subfor_row.auth_view<>0 then true else false end)
					returning id into subfor_newid;
				
				PERFORM create_topics(subfor_row.forum_id, subfor_newid);
			end loop;
		end loop;
		

	end loop;
end
$$;

-- Insert forum security -> Admin only to be more precise after

insert into category_groups (category_id, group_id, created_at, updated_at, permission_type)
select id, 1 /* Adm */, now(), now(), 1 from categories where read_restricted=true;


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

-- Insert emoji !
-- we must put the gif in /uploads/default/original/1X/ folder

delete from uploads u using custom_emojis ce
where ce.upload_id = u.id;

delete from custom_emojis;

insert into custom_emojis (name, upload_id, created_at, updated_at)
select replace(code,':',''),  smilies_id, now(), now() 
from "database".busobj_smilies where code like ':%:';

insert into uploads (user_id, original_filename, url, created_at, updated_at, extension, filesize)
select 1, smile_url, '/uploads/default/original/1X/' || smile_url, now(), now(), 'gif', 300
from "database".busobj_smilies where code like ':%:';


-- Add in posts the images

DO $$
declare
    temprow record;
begin
	for temprow in
		select p.id, u.original_filename, u.url
		from posts p
		join post_uploads pu on p.id = pu.post_id 
		join uploads u on u.id = pu.upload_id 
		where u."extension" in ('png', 'jpg', 'gif')
	loop
		update posts set raw = raw || chr(10) /* new line */ || '![' || temprow.original_filename || '](' || temprow.url || ')'
			where id = temprow.id;
	end loop;
end
$$;

-- Add in posts the other files

DO $$
declare
    temprow record;
begin
	for temprow in
		select p.id, u.original_filename, u.url, u.filesize
		from posts p
		join post_uploads pu on p.id = pu.post_id 
		join uploads u on u.id = pu.upload_id 
		where u."extension" not in ('png', 'jpg', 'gif')
	loop
		update posts set raw = raw || chr(10) /* new line */ || '[' || temprow.original_filename || '|attachment](' || temprow.url || ') (' || round(temprow.filesize/1000,1) || ' KB)'
			where id = temprow.id;

	end loop;
end
$$;

-- Reset sequences

select setval('categories_id_seq', max(id)) from categories;
select setval('topics_id_seq', max(id)) from topics;
select setval('posts_id_seq', max(id)) from posts;
select setval('uploads_id_seq', max(id)) from uploads;
select setval('post_uploads_id_seq', max(id)) from post_uploads;
select setval('custom_emojis_id_seq', max(id)) from custom_emojis;