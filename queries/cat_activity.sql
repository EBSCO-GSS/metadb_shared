--metadb:function cat_activity

drop function if exists cat_activity;

create function cat_activity(
start_date date default '2026-01-07',
end_date date default '2035-01-31'
)
returns table (
user_name text,
int_rec_created integer,
int_rec_updated integer
)
as 
$$
with updates as (
	with updated_entries as (
	select 
		jsonb_extract_path_text(int."jsonb",'metadata','updatedDate')::timestamp as updated_date,
		int.id as int_id, 
		jsonb_extract_path_text(int."jsonb",'metadata','updatedByUserId')::uuid as updated_by
	from folio_inventory.instance__ as int
	where jsonb_extract_path_text(int."jsonb",'metadata','updatedDate')::timestamp >= start_date
		and jsonb_extract_path_text(int."jsonb",'metadata','updatedDate')::timestamp < end_date + Interval '1 day'
		and jsonb_extract_path_text(int."jsonb",'metadata','updatedDate') != jsonb_extract_path_text(int."jsonb",'metadata','createdDate')
	)
	select
		updated_by,
		count(distinct("updated_date","int_id")) as num_updated
	from updated_entries
	group by updated_by
),
created as (
	with created_entries as (
	select 
		jsonb_extract_path_text(int2."jsonb",'metadata','createdDate')::timestamp as created_date,
		int2.id as int_id, 
		jsonb_extract_path_text(int2."jsonb",'metadata','createdByUserId')::uuid as created_by
	from folio_inventory.instance__ as int2
	where jsonb_extract_path_text(int2."jsonb",'metadata','createdDate')::timestamp >= start_date 
		and jsonb_extract_path_text(int2."jsonb",'metadata','createdDate')::timestamp < end_date + Interval '1 day' 
	)
	select
		created_by,
		count(distinct("created_date","int_id")) as num_created
	from created_entries
	group by created_by
)
select
  jsonb_extract_path_text(users."jsonb",'personal','lastName')|| ', '|| jsonb_extract_path_text(users."jsonb",'personal','firstName') as user_name,
  coalesce(created.num_created,'0') as int_rec_created,
  coalesce(updates.num_updated,'0') as int_rec_updated
from updates
	left join created on created.created_by = updates.updated_by
	left join folio_users.users as users on users.id = updates.updated_by
$$
language sql
stable
parallel safe; 
