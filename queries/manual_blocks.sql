--metadb:function manual_blocks 

DROP FUNCTION IF EXISTS manual_blocks;

CREATE FUNCTION manual_blocks()
RETURNS TABLE(
	patron_name text,
	patron_barcode text,
	patron_username text,
	patron_status text,
	patron_exp_date text,
	block_status text,
	block_exp_date text,
	block_template text,
	block_type text,
	patron_message text
	)
AS $$
select
jsonb_extract_path_text(u."jsonb",'personal','lastName') || ', ' || jsonb_extract_path_text(u."jsonb",'personal','firstName') as patron_name,
jsonb_extract_path_text(u."jsonb",'barcode') as patron_barcode,
jsonb_extract_path_text(u."jsonb",'username') as patron_username,
case 
	when jsonb_extract_path_text(u."jsonb",'active') = 'true' then 'Active'
	else 'Inactive'
end as patron_status,
to_char(jsonb_extract_path_text(u."jsonb",'expirationDate')::date,'YYYY-MM-DD') as patron_exp_date,
case
	when jsonb_extract_path_text(m."jsonb",'expirationDate')::date < Current_date then 'Expired'
	when jsonb_extract_path_text(m."jsonb",'expirationDate') is null then 'No Expiration Date'
	else 'Open'
end as block_status,
to_char(jsonb_extract_path_text(m."jsonb",'expirationDate')::date,'YYYY-MM-DD') as block_exp_date,
mbtt."name" as block_template,
jsonb_extract_path_text(m."jsonb",'type') as block_type,
jsonb_extract_path_text(m."jsonb",'patronMessage') as patron_message
from folio_feesfines.manualblocks as m
	left join folio_feesfines.manual_block_templates__t as mbtt on mbtt.code = jsonb_extract_path_text(m."jsonb",'code')
	left join folio_users.users as u on u.id = jsonb_extract_path_text(m."jsonb",'userId')::uuid
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
