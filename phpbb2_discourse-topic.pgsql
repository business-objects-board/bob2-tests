-- simple script that copy phpbb2 topics/posts to discourse
-- use same id in discourse as set in phpbb2
-- warning remove all content before import !!

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

CREATE OR REPLACE FUNCTION flag("value" INT)
RETURNS TEXT AS $$
  SELECT case 
 	when value=1 then ''
	when value=2 then ':afghanistan:'
	when value=3 then ':albania:'
	when value=4 then ':algeria:'
	when value=5 then ':american_samoa:'
	when value=6 then ':andorra:'
	when value=9 then ':argentina:'
	when value=10 then ':armenia:'
	when value=11 then ':aruba:'
	when value=12 then ':australia:'
	when value=13 then ':austria:'
	when value=14 then ':azerbaijan:'
	when value=15 then ':bahamas:'
	when value=16 then ':bahrain:'
	when value=17 then ':bangladesh:'
	when value=18 then ':barbados:'
	when value=19 then ':belarus:'
	when value=20 then ':belgium:'
	when value=27 then ':botswana:'
	when value=28 then ':brazil:'
	when value=30 then ':bulgaria:'
	when value=32 then ':myanmar:'
	when value=34 then ':cambodia:'
	when value=35 then ':cameroon:'
	when value=36 then ':canada:'
	when value=40 then ':chile:'
	when value=41 then ':cn:'
	when value=42 then ':cote_divoire:'
	when value=43 then ':colombia:'
	when value=44 then ':comoros:'
	when value=46 then ':costa_rica:'
	when value=47 then ':croatia:'
	when value=48 then ':cuba:'
	when value=49 then ':cyprus:'
	when value=50 then ':czech_republic:'
	when value=52 then ':denmark:'
	when value=53 then ':djibouti:'
	when value=56 then ':timor_leste:'
	when value=57 then ':ecuador:'
	when value=58 then ':egypt:'
	when value=59 then ':el_salvador:'
	when value=62 then ':estonia:'
	when value=64 then ':faroe_islands:'
	when value=66 then ':finland:'
	when value=67 then ':fr:'
	when value=68 then ':gabon:'
	when value=71 then ':de:'
	when value=72 then ':ghana:'
	when value=73 then ':greece:'
	when value=77 then ':guatemala:'
	when value=80 then ':guyana:'
	when value=83 then ':hong_kong:'
	when value=84 then ':hungary:'
	when value=85 then ':iceland:'
	when value=86 then ':india:'
	when value=87 then ':indonesia:'
	when value=88 then ':iran:'
	when value=89 then ':iraq:'
	when value=90 then ':ireland:'
	when value=91 then ':israel:'
	when value=92 then ':it:'
	when value=93 then ':jamaica:'
	when value=94 then ':japan:'
	when value=95 then ':jordan:'
	when value=96 then ':kazakhstan:'
	when value=97 then ':kenya:'
	when value=99 then ':kuwait:'
	when value=102 then ':latvia:'
	when value=103 then ':lebanon:'
	when value=107 then ':liechtenstein:'
	when value=108 then ':lithuania:'
	when value=109 then ':luxembourg:'
	when value=110 then ':macau:'
	when value=111 then ':macedonia:'
	when value=112 then ':madagascar:'
	when value=113 then ':malawi:'
	when value=114 then ':malaysia:'
	when value=115 then ':maldives:'
	when value=117 then ':malta:'
	when value=118 then ':marshall_islands:'
	when value=120 then ':mauritius:'
	when value=121 then ':mexico:'
	when value=123 then ':moldova:'
	when value=124 then ':monaco:'
	when value=126 then ':morocco:'
	when value=130 then ':nepal:'
	when value=131 then ':caribbean_netherlands:'
	when value=132 then ':netherlands:'
	when value=133 then ':new_zealand:'
	when value=136 then ':nigeria:'
	when value=138 then ':norway:'
	when value=140 then ':pakistan:'
	when value=142 then ':panama:'
	when value=145 then ':peru:'
	when value=146 then ':philippines:'
	when value=147 then ':poland:'
	when value=148 then ':portugal:'
	when value=149 then ':puerto_rico:'
	when value=150 then ':qatar:'
	when value=151 then ':romania:'
	when value=152 then ':ru:'
	when value=156 then ':sao_tome_principe:'
	when value=157 then ':saudi_arabia:'
	when value=162 then ':singapore:'
	when value=163 then ':slovakia:'
	when value=164 then ':slovenia:'
	when value=167 then ':south_africa:'
	when value=168 then ':kr:'
	when value=169 then ':es:'
	when value=172 then ':st_lucia:'
	when value=173 then ':sudan:'
	when value=176 then ':sweden:'
	when value=177 then ':switzerland:'
	when value=178 then ':syria:'
	when value=179 then ':taiwan:'
	when value=182 then ':thailand:'
	when value=185 then ':trinidad_tobago:'
	when value=186 then ':tunisia:'
	when value=187 then ':turkey:'
	when value=190 then ':united_arab_emirates:'
	when value=191 then ':uganda:'
	when value=192 then ':uk:'
	when value=193 then ':ukraine:'
	when value=194 then ':uruguay:'
	when value=195 then ':us:'
	when value=196 then ':uzbekistan:'
	when value=197 then ':vanuatu:'
	when value=198 then ':vatican_city:'
	when value=199 then ':venezuela:'
	when value=200 then ':vietnam:'
	when value=202 then ':zambia:'
	when value=203 then ':zimbabwe:'
 	else 'bli' end;
$$ LANGUAGE SQL STRICT IMMUTABLE;


-- Purge

-- 255509 is the last topic id of the bob import
delete from topics where id <= 255509;
-- 1071383 is the last post id of the bob import
delete from posts where id <= 1071383;
delete from post_uploads;

-- Insert topics with all stats!

insert into topics (id, title, category_id, created_at, updated_at, last_post_user_id, bumped_at, user_id, last_posted_at, "views", reply_count, posts_count, pinned_at )
select t.topic_id, t.topic_title, t.forum_id+100, to_timestamp(fp.post_time), to_timestamp(lp.post_time ), 
lp.poster_id, to_timestamp(lp.post_time), fp.poster_id, to_timestamp(lp.post_time), t.topic_views, t.topic_replies, t.topic_replies+1,
case when t.topic_type=1 then now() else null end
from database.busobj_topics t
join "database".busobj_posts fp on t.topic_first_post_id = fp.post_id 
join "database".busobj_posts lp on t.topic_last_post_id = lp.post_id;

-- Insert posts

insert into posts (id, user_id, topic_id, post_number, raw, cooked, created_at, updated_at, last_version_at, sort_order)
select p.post_id, p.poster_id, p.topic_id, p.post_id, 
t.post_text  || chr(10) || chr(10) || '---' || chr(10) || chr(10) || '**' || p.post_username || '** ' ||
flag(p.flag_id)  || ' _(BOB member since ' || to_char(to_timestamp(p.user_join_date), 'YYYY-MM-DD')  || ')_',
t.post_text, to_timestamp(p.post_time), 
case when p.post_edit_time is null then to_timestamp(p.post_time) else to_timestamp(p.post_edit_time) end, 
case when p.post_edit_time is null then to_timestamp(p.post_time) else to_timestamp(p.post_edit_time) end, 
1 from database.busobj_posts p
join database.busobj_posts_text t on p.post_id=t.post_id and p.post_edit_count=t.post_version;

-- Update bbcode issues (like [quote:0681c43013="Michael"])

-- update bbcode quote (add extra line-break because discourse parser limitation https://meta.discourse.org/t/bbcode-quote-tag-and-mixed-newlines/103708/3)
-- remove bbcode color (https://meta.discourse.org/t/discourse-bbcode-color/65363 doable but plugin)
-- remove bbcode size (https://meta.discourse.org/t/discourse-bbcode/65425 doable but plugin)
update posts set raw = 
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(raw, 
    '\[quote:(\w*)="([a-zA-Z0-9_ ]*)"\]', chr(10) || '[quote="\2"]' || chr(10), 'g'), 
    '\[quote:(\w*)\]', chr(10) || '[quote]' || chr(10), 'g'), 
    '\[/quote:(\w*)\]', chr(10) || '[/quote]' || chr(10), 'g'), 
    '\[color=(\w*):(\w*)\]', '', 'g'), 
    '\[/color:(\w*)\]', '', 'g'), 
    '\[size=\d+:(\w*)\]', '', 'g'),
    '\[/size:(\w*)\]', '', 'g')
where position('[' in raw)>0;

-- update bbcode b-i-u
update posts set raw = 
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(raw, 
    '\[/u:(\w*)\]', '[/u]', 'g'), 
    '\[u:(\w*)\]', '[u]', 'g'), 
    '\[/i:(\w*)\]', '[/i]', 'g'), 
    '\[i:(\w*)\]', '[i]', 'g'), 
    '\[/b:(\w*)\]', '[/b]', 'g'), 
    '\[b:(\w*)\]', '[b]', 'g')
where position('[' in raw)>0;

-- update bbcode list-img-code
update posts set raw = 
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(
    regexp_replace(raw, 
    '\[list:(\w*)\]', '[list]', 'g'), 
    '\[/list:(\w*)\]', '[/list]', 'g'), 
    '\[/list:\w:(\w*)\]', '[/list]', 'g'), 
    '\[img:(\w*)\]', '[img]', 'g'), 
    '\[/img:(\w*)\]', '[/img]', 'g'), 
    '\[code:\d:(\w*)\]', chr(10) || '[code]' || chr(10), 'g'),
    '\[/code:\d:(\w*)\]', chr(10) || '[/code]' || chr(10), 'g')
where position('[' in raw)>0;

insert into post_uploads (id, post_id, upload_id)
select attach_id, post_id, attach_id+100 from "database".busobj_attachments;

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
		update posts set raw = replace(raw, 
            chr(10) || chr(10) || '---' || chr(10) || chr(10), 
            chr(10) /* new line */ || temprow.markdown || chr(10) || chr(10) || '---' || chr(10) || chr(10))
        where id = temprow.post_id;
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
		update posts set raw = replace(raw, 
            chr(10) || chr(10) || '---' || chr(10) || chr(10), 
            chr(10) /* new line */ || temprow.markdown || chr(10) || chr(10) || '---' || chr(10) || chr(10))
        where id = temprow.post_id;
	end loop;
end
$$;

-- Fix html encoded in topic title

update topics set title=replace(title, '&amp;','&'), fancy_title=replace(fancy_title, '&amp;','&')
where position('&amp;' in title)>0;

update topics set title=replace(title, '&quot;','"'), fancy_title=replace(fancy_title, '&quot;','"') 
where position('&quot;' in title)>0;

-- Strange unicode things

update topics set title=replace(title, U&'â\0080\0098',''''), fancy_title=replace(fancy_title, U&'â\0080\0098','''') 
where position(U&'â\0080\0098' in title)>0;

update topics set title=replace(title, U&'â\0080¦','...'), fancy_title=replace(fancy_title, U&'â\0080¦','...') 
where position(U&'â\0080¦' in title)>0;

update topics set title=replace(title, U&'â\0080\008E',''), fancy_title=replace(fancy_title, U&'â\0080\008E','') 
where position(U&'â\0080\008E' in title)>0;

update topics set title=replace(title, U&'â\0080\009C','"'), fancy_title=replace(fancy_title, U&'â\0080\009C','"') 
where position(U&'â\0080\009C' in title)>0;

update topics set title=replace(title, U&'â\0080\009D','"'), fancy_title=replace(fancy_title, U&'â\0080\009D','"') 
where position(U&'â\0080\009D' in title)>0;

update topics set title=replace(title, U&'â\0080\0099',''''), fancy_title=replace(fancy_title, U&'â\0080\0099','''') 
where position(U&'â\0080\0099' in title)>0;

update topics set title=replace(title, U&'\0080','€'), fancy_title=replace(fancy_title, U&'\0080','€') 
where position(U&'\0080' in title)>0;

-- Fix html encoded in raw [code]

UPDATE posts SET raw=replace(raw, '&#91;', '['), baked_version = null WHERE position('&#91;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&#93;', ']'), baked_version = null WHERE position('&#93;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&#40;', '('), baked_version = null WHERE position('&#40;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&#41;', ')'), baked_version = null WHERE position('&#41;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&#58;', ':'), baked_version = null WHERE position('&#58;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&#123;', '{'), baked_version = null WHERE position('&#123;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&#125;', '}'), baked_version = null WHERE position('&#125;' in raw)>0;

-- bullet
UPDATE posts SET raw=replace(raw, '&#149;', '*'), baked_version = null WHERE position('&#149;' in raw)>0;


-- html entities
UPDATE posts SET raw=replace(raw, '&lt;', '<'), baked_version = null WHERE position('&lt;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&gt;', '>'), baked_version = null WHERE position('&gt;' in raw)>0;
UPDATE posts SET raw=replace(raw, '&quot;', '"'), baked_version = null WHERE position('&quot;' in raw)>0;

-- Strange unicode things

update posts set raw=replace(raw, U&'â\0080\0098',''''), baked_version = null where position(U&'â\0080\0098' in raw)>0;
update posts set raw=replace(raw, U&'â\0080¦','...'), baked_version = null where position(U&'â\0080¦' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\009C','"'), baked_version = null where position(U&'â\0080\009C' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\009D','"'), baked_version = null where position(U&'â\0080\009D' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\009E','"'), baked_version = null where position(U&'â\0080\009E' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\0099',''''), baked_version = null where position(U&'â\0080\0099' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\008B',''), baked_version = null where position(U&'â\0080\008B' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\0093','-'), baked_version = null where position(U&'â\0080\0093' in raw)>0;
update posts set raw=replace(raw, U&'â\0080\0094',''), baked_version = null where position(U&'â\0080\0094' in raw)>0;
update posts set raw=replace(raw, U&'â\0080¢','*'), baked_version = null where position(U&'â\0080¢' in raw)>0;
update posts set raw=replace(raw, U&'\0080','€'), baked_version = null where position(U&'\0080' in raw)>0;


-- rebake all previous content
UPDATE posts SET baked_version = null where id <= 1071383;

-- Reset sequences

select setval('topics_id_seq', max(id)) from topics;
select setval('posts_id_seq', max(id)) from posts;
select setval('post_uploads_id_seq', max(id)) from post_uploads;