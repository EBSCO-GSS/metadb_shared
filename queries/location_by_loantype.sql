--metadb:function location_by_loantype 

DROP FUNCTION IF EXISTS location_by_loantype;

CREATE FUNCTION location_by_loantype()
RETURNS TABLE(
  location_name text,
  loan_type text,
  record_counts numeric)
AS $$
select
lt."name" as location_name,
ltt."name" as loan_type,
count(*) as record_counts
from folio_inventory.item__t as it
	left join folio_inventory.loan_type__t as ltt on it.permanent_loan_type_id = ltt.id 
	left join folio_inventory.location__t as lt on it.effective_location_id = lt.id
group by lt."name",ltt."name" 
order by lt."name"
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
