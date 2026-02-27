--metadb: function cat_int_activity 

drop function if exists cat_int_activity;

create function cat_int_activity(
start_date date default '2010-01-01',
end_date date default NULL
)
returns table (
user_name text,
int_rec_created integer,
int_rec_updated integer
)
as 
$$
with updates as (
	select 
		jsonb_extract_path_text(int."jsonb",'metadata','updatedByUserId') as updated_by,
		count(*) as num_updated
	from folio_inventory.instance__ as int
	where jsonb_extract_path_text(int."jsonb",'metadata','updatedDate')::timestamp >= start_date
		and jsonb_extract_path_text(int."jsonb",'metadata','updatedDate')::timestamp < end_date + Interval '1 day'
		and jsonb_extract_path_text(int."jsonb",'metadata','updatedDate') != jsonb_extract_path_text(int."jsonb",'metadata','createdDate')
	group by updated_by 
),
creates as (	
	select 
		jsonb_extract_path_text(int2."jsonb",'metadata','createdByUserId') as created_by,
		count(*) as num_created
	from folio_inventory.instance as int2
	where jsonb_extract_path_text(int2."jsonb",'metadata','createdDate')::timestamp >= start_date
		and jsonb_extract_path_text(int2."jsonb",'metadata','createdDate')::timestamp < end_date + Interval '1 day'
	group by jsonb_extract_path_text(int2."jsonb",'metadata','createdByUserId')
),
combo as (
	select
		coalesce(updates.updated_by,creates.created_by) as operator_id,
		coalesce(creates.num_created,0) as int_rec_created,
		coalesce(updates.num_updated,0) as int_rec_updated
	from updates
		full outer join creates on creates.created_by = updates.updated_by 
)
select 
	coalesce(jsonb_extract_path_text(u."jsonb",'personal','lastName')|| ', '|| jsonb_extract_path_text(u."jsonb",'personal','firstName'),'Unknown') as user_name,
	c.int_rec_created,
	c.int_rec_updated 
from combo as c
	left join folio_users.users as u on c.operator_id = u.id::text
order by user_name
$$
language sql
stable
parallel safe; 
