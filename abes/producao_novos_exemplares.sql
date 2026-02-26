--metadb:function producao_novos_exemplares

DROP FUNCTION IF EXISTS producao_novos_exemplares;

CREATE FUNCTION producao_novos_exemplares(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Usuario text,
    AnoMes text,
    Total text)
AS $$
select 
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS Usuario,
    to_char(
	    date_trunc('month', i.creation_date ),
	    'YYYY-MM'
	) AS AnoMes,
    COUNT(i.id) AS Total
FROM folio_inventory.item__ i
LEFT JOIN folio_users.users__ u
       ON u.id = i.created_by 
where (i.jsonb->'metadata'->>'createdDate')::date between start_date and end_date
and i.__current and u.__current 
GROUP BY
    AnoMes,
    Usuario
ORDER BY AnoMes DESC, Usuario
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
