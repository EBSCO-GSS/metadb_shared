--metadb:function top_circulation_items

DROP FUNCTION IF EXISTS top_circulation_items;

CREATE FUNCTION top_circulation_items(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Titulo text,
    Total text)
AS $$

SELECT 
	i.title as Titulo,
    COUNT(*) AS Total
FROM folio_circulation.loan__t__ l
left join folio_inventory.instance__t__ i on i.id = l.id

WHERE (l.due_date)::date  BETWEEN start_date and end_date
GROUP BY Titulo
ORDER BY Total DESC, Titulo;


$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;