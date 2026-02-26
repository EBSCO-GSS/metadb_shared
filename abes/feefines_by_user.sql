--metadb:function feefines_by_user 

DROP FUNCTION IF EXISTS feefines_by_user;

CREATE FUNCTION feefines_by_user()
RETURNS TABLE(
  utilizateur text,
  code_barres_utilisateur text,
  groupe_utilisateur text,
  amend_total numeric,
  proprietaire_amende text)
AS $$
select
  jsonb_extract_path_text(users."jsonb",'personal','lastName') || ' , ' || jsonb_extract_path_text(users."jsonb",'personal','firstName') as utilizateur,
  jsonb_extract_path_text(users."jsonb",'barcode') as code_barres_utilisateur,
  gt.group as groupe_utilisateur,
  sum(jsonb_extract_path_text(feeacct."jsonb",'amount')::numeric) as amend_total,
  jsonb_extract_path_text(feeacct."jsonb",'feeFineOwner') as proprietaire_amende
from folio_feesfines.accounts as feeacct
	left join folio_users.users as users on jsonb_extract_path_text(users."jsonb",'id')::uuid = jsonb_extract_path_text(feeacct."jsonb",'userId')::uuid 
	left join folio_users.groups__t as gt on gt.id = jsonb_extract_path_text(users."jsonb",'patronGroup')::uuid
where jsonb_extract_path_text(feeacct."jsonb",'status','name') = 'Open'
group by jsonb_extract_path_text(users."jsonb",'barcode'),
	jsonb_extract_path_text(users."jsonb",'personal','lastName') || ' , ' || jsonb_extract_path_text(users."jsonb",'personal','firstName'),
	jsonb_extract_path_text(feeacct."jsonb",'feeFineOwner'),
	gt.group
order by utilizateur
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
