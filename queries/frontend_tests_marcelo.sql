--metadb:function frontend_tests_marcelo
--metadb:column material_type_1_value label="Valor 1 informado pelo usuário"
--metadb:column material_type_2_value label="Valor 2 informado pelo usuário"
--metadb:column item_id label="Id do tipo do material"
--metadb:column material_type_name label="Descrição do material"

--CREATE EXTENSION IF NOT EXISTS unaccent;
drop function if exists frontend_tests_marcelo;
create function frontend_tests_marcelo(
material_type_1 text default '',
material_type_2 text default ''
)
returns table (
material_type_1_value text,
material_type_2_value text,
item_id uuid,
material_type_name text
)
as 
$$
BEGIN

if trim(material_type_1)='' and trim(material_type_2)='' then
	RETURN QUERY 
	select 
	    material_type_1 as material_type_1_value,
	    material_type_2 as material_type_2_value,
		mt.id AS item_id,	
	    mt.name AS material_type_name    
	from 
	    folio_inventory.material_type__t__ AS mt
	WHERE
		mt.__current = true    
	order by
		mt.name;
	
	return;

end if;

RETURN QUERY
select 
    material_type_1 as material_type_1_value,
    material_type_2 as material_type_2_value,
	mt.id AS item_id,	
    mt.name AS material_type_name    
from 
    folio_inventory.material_type__t__ AS mt
WHERE
	mt.__current = true    
	AND (
            -- Verifica se o nome bate com o parâmetro 1
            replace(translate(LOWER(mt.name), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
 = replace(translate(LOWER(material_type_1), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')

            OR 
			-- Quebra a string removendo qualquer espaço antes ou depois da vírgula
            replace(translate(LOWER(mt.name), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
 = ANY(regexp_split_to_array(replace(translate(LOWER(material_type_2), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
, '\s*,\s*'))			
    )	
order by
	mt.name;

END;
$$
language plpgsql
stable
parallel safe; 