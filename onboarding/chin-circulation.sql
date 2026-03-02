--metadb:function chin-circulation

DROP FUNCTION IF EXISTS chin-circulation;

CREATE FUNCTION chin-circulation(
 
)
RETURNS TABLE(
    year number,
    count_loan number,
    count_return number)
AS $$


SELECT EXTRACT(YEAR FROM loan_date) as year, count(loan_date) count_loan, count(return_date) count_return 
FROM folio_circulation.loan__t__
GROUP BY year
order by year desc;

$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
