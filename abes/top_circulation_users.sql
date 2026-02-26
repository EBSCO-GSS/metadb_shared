--metadb:function top_circulation_users

DROP FUNCTION IF EXISTS top_circulation_users;

CREATE FUNCTION top_circulation_users(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Utilizateur text,
    Total text)
AS $$
SELECT 
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) AS Utilizateur,
    COUNT(l.id) AS Total
FROM folio_circulation.loan__ l
LEFT JOIN folio_users.users__ u
       ON u.id = (l.jsonb->>'userId')::uuid
WHERE (l.jsonb->>'loanDate')::date  BETWEEN start_date and end_date
GROUP BY Utilizateur
ORDER BY Total DESC, Utilizateur;


$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;
