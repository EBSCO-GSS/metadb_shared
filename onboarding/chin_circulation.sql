--metadb:function chin_circulation

DROP FUNCTION IF EXISTS chin_circulation;

CREATE FUNCTION chin_circulation(
 
)
RETURNS TABLE(
    _year integer,
    count_loan integer,
    count_return integer)
AS $$


SELECT EXTRACT(YEAR FROM loan_date) _year, count(loan_date) count_loan, count(return_date) count_return 
FROM folio_circulation.loan__t__
GROUP BY _year
order by _year desc;

$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
