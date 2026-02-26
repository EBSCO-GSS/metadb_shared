--metadb:function production_nouveaux_bibliographiques

DROP FUNCTION IF EXISTS production_nouveaux_bibliographiques;

CREATE FUNCTION production_nouveaux_bibliographiques(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Utilisateur text,
    Annee_Mois text,
    Total text)
AS $$
select 
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS Utilisateur,
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
    Annee_Mois,
    Utilisateur
ORDER BY Annee_Mois DESC, Utilisateur
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;


