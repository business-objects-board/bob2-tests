-- simple script that copy phpbb2 categories to discourse
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

-- Purge

delete from categories;
delete from category_groups;

-- Insert categories as categories (3 categories)

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower)
select cat_id, cat_title, cat_order, now(), now(), -1, slugify(cat_title), lower(cat_title) from database.busobj_categories c;

-- Insert forums as sub-categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id)
select forum_id+100, forum_name, forum_order, now(), now(), -1, slugify(forum_name), lower(forum_name), cat_id
from "database".busobj_forums
where parent_forum_id=0;

-- Insert sub-forums as sub-sub-categories

insert into categories (id, name, sort_order, created_at, updated_at, user_id, slug, name_lower, parent_category_id)
select forum_id+100, substring(forum_name,1,50), forum_order, now(), now(), -1, substring(slugify(forum_name),1,50), substring(lower(forum_name),1,50), parent_forum_id+100
from "database".busobj_forums
where parent_forum_id!=0;

-- Insert forum security -> Adm only to be more precise after

insert into category_groups (category_id, group_id, created_at, updated_at, permission_type)
select forum_id+100, 1 /* Adm */, now(), now(), 1 from "database".busobj_forums where auth_view <> 0;

update categories set read_restricted=true where id in
(select forum_id+100 from "database".busobj_forums where auth_view <> 0);

select setval('categories_id_seq', max(id)) from categories;
