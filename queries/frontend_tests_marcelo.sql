--metadb:function frontend_tests_marcelo
--metadb:column material_types_value label="Valor informado pelo usuário"
--metadb:column item_id label="Id do tipo do material"
--metadb:column material_type_name label="Descrição do material"

drop function if exists frontend_tests_marcelo;

create function frontend_tests_marcelo(
material_type_1 text,
material_type_2 text,
material_type_3 text
)
returns table (
material_type_1_value text,
material_type_2_value text,
material_type_3_value text,
item_id uuid,
material_type_name text
)
as 
$$
select 
    material_type_1 as material_type_1_value,
    material_type_2 as material_type_2_value,
    material_type_3 as material_type_3_value,	
	mt.id AS item_id,	
    mt.name AS material_type_name    
from 
    folio_inventory.material_type__t__ AS mt
WHERE
	mt.__current = true    
order by
	mt.name
$$
language sql
stable
parallel safe; 