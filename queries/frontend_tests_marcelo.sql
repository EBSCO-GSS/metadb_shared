--metadb:function frontend_tests_marcelo
--metadb:column material_types_value label="Valor informado pelo usuário"
--metadb:column item_id label="Id do tipo do material"
--metadb:column material_type_name label="Descrição do material"

drop function if exists frontend_tests_marcelo;

create function frontend_tests_marcelo(
material_types text
)
returns table (
material_types_value text,
item_id uuid,
material_type_name text
)
as 
$$
select 
    material_types as material_types_value,
	mt.id AS item_id,	
    mt.name AS material_type_name    
from 
    folio_inventory.material_type__t__ AS mt
WHERE
	mt.__current = true    
$$
language sql
stable
parallel safe; 
