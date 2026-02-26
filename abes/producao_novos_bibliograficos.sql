--metadb:function producao_novos_bibliograficos

DROP FUNCTION IF EXISTS producao_novos_bibliograficos;

CREATE FUNCTION producao_novos_bibliograficos(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Usuario text,
    Ano_Mes text,
    Total text)
AS $$
select 
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS Usuario,
    to_char(
	    date_trunc('month', (i.jsonb->'metadata'->>'createdDate')::date),
	    'YYYY-MM'
	) AS Ano_Mes,
    COUNT(*) AS Total
FROM folio_inventory.instance__ i
LEFT JOIN folio_users.users__ u
       ON u.id = (i.jsonb->'metadata'->>'createdByUserId')::uuid
where (i.jsonb->'metadata'->>'createdDate')::date between start_date and end_date
and i.__current 
and u.__current 
GROUP BY
    Ano_Mes,
    Usuario
ORDER BY Ano_Mes DESC, Usuario
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;


