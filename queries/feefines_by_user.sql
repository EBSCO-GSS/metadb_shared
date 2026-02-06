--metadb: function fee/fines_by_user 

DROP FUNCTION IF EXISTS feefines_by_user;

CREATE FUNCTION feefines_by_user
RETURNS TABLE (
  user_name text,
  user_barcode text,
  user_patron_group text,
  fee_fine_total numeric,
  fee_fine_owner text
)
AS $$
select
  jsonb_extract_path_text(users."jsonb",'personal','lastName') || ' , ' || jsonb_extract_path_text(users."jsonb",'personal','firstName') as user_name,
  jsonb_extract_path_text(users."jsonb",'barcode') as user_barcode,
  gt.group as user_patron_group,
  sum(jsonb_extract_path_text(feeacct."jsonb",'amount')::numeric) as fee_fine_total,
  jsonb_extract_path_text(feeacct."jsonb",'feeFineOwner') as fee_fine_owner
from folio_feesfines.accounts as feeacct
	left join folio_users.users as users on jsonb_extract_path_text(users."jsonb",'id')::uuid = jsonb_extract_path_text(feeacct."jsonb",'userId')::uuid 
	left join folio_users.groups__t as gt on gt.id = jsonb_extract_path_text(users."jsonb",'patronGroup')::uuid
where jsonb_extract_path_text(feeacct."jsonb",'status','name') = 'Open'
group by jsonb_extract_path_text(users."jsonb",'barcode'),
	jsonb_extract_path_text(users."jsonb",'personal','lastName') || ' , ' || jsonb_extract_path_text(users."jsonb",'personal','firstName'),
	jsonb_extract_path_text(feeacct."jsonb",'feeFineOwner'),
	gt.group
order by user_name
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
