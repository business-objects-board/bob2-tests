-- simple script that copy phpbb2 uploaded files to discourse
-- use same id in discourse as set in phpbb2
-- warning remove all content before import !!

-- Purge

delete from custom_emojis;
delete from uploads where id>0;

-- Insert emoji !
-- we must put the gif in /uploads/default/original/1X/ folder

insert into custom_emojis (id, name, upload_id, created_at, updated_at)
select smilies_id, replace(code,':',''),  smilies_id, now(), now() 
from "database".busobj_smilies
where code like ':%:';

insert into uploads (id, user_id, original_filename, url, created_at, updated_at, extension, filesize)
select smilies_id, 1, smile_url, '/uploads/default/original/1X/' || smile_url, now(), now(), 'gif', 300
from "database".busobj_smilies
where code like ':%:';

-- Insert uploads (add 100 to let 100 emoji max before)
-- we must put the files in /uploads/default/original/1X/ folder

insert into uploads (id, user_id, original_filename, filesize, url, created_at, updated_at, "extension")
select a.attach_id+100, a.user_id_1, d.real_filename, d.filesize, '/uploads/default/original/1X/' || d.physical_filename, to_timestamp(d.filetime), to_timestamp(d.filetime), d."extension" from "database".busobj_attachments a
join "database".busobj_attachments_desc d on a.attach_id=d.attach_id;

-- Reset sequences

select setval('uploads_id_seq', max(id)) from uploads;
select setval('custom_emojis_id_seq', max(id)) from custom_emojis;