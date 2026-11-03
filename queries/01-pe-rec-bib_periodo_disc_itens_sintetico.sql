--metadb:function rel_planoensino_01
DROP FUNCTION IF EXISTS rel_planoensino_01;
CREATE OR REPLACE FUNCTION rel_planoensino_01(
    p_library_code_1 text default '',
    p_library_code_2 text default '',
    p_items_material_type_1 text default '',
    p_items_material_type_2 text default '',
    p_instance_status_1 text default '',
    p_instance_status_2 text default '',
    p_items_status_1 text default '',
    p_items_status_2 text default '',
    p_instances_initial_acquisition_date text default '',
    p_instances_final_acquisition_date text default '',
    p_department_code text default '',
    p_course_code text default '',
	p_year text default '',
 	p_period text default '',	
 	p_semester text default ''
)
RETURNS TABLE (
    avaliacao_mec text,
    agrupamento text,
    codigo_biblioteca text,	
    nome_biblioteca text,	
	codigo_curso text,
    nome_curso text,
	ano integer,
	semestre integer,
	periodo integer,
	descricao_periodo text,
    codigo_disciplina text,	
    nome_disciplina text,	
    tipo_bibliografia text,	
	id_instancia uuid,	
	hrid_instancia text,
	status_instancia text,	
	titulo_da_obra text,
	tipo_de_material text,
	--id_item uuid,
	--item_outro_barcode text,
	--tipo_de_acervo_mec text, 
    total_itens_na_bib integer,
    total_itens_por_plano_de_ensino integer,	
    total_emprestimos_itens_na_bib integer,
	data_de_aquisicao date,
	payment_status text,
	--title_na_aquisicao text,
	referencia_abnt text,
	URL_PDF_link text,
	isbn text,
	issn text,	
	possui_outras_edicoes text,	
	item_barcode text,	
	status_item text
) 
AS $$
/*
243 - Relatórios - Levantamentos bibliográficos - Plano de ensino

- Campos adicionais para o Cabeçalho:
	Instituicao_Nome
	EBSCO FOLIO – Plataforma de Serviços de Biblioteca
	Relatório_Nome
	Tipo_Agrupamento_Relatorio
	Filtros_Utilizados
	Tipo_Avaliacao_Desc
	DisplayName no FOLIO (json)	
	Data_hora_geração_das_consultas

- Tipo de Avaliação:
	p_tipo_instrumento: 
		1 - Autorização
		2 - Reconhecimento
- Agrupado por:
	p_agrupado_por: 
		1 - Biblioteca, Programa de Ensino e Disciplina (Exemplares e Empréstimos) - Sintético	
		2 - Conceitos por Biblioteca e Progama de Ensino
		3 - Conceitos do MEC - Norma 2015
		4 - Biblioteca, Programa de Ensino e Disciplina (Exemplares e Empréstimos) - Analítico
		5 - Bibliografias por Disciplina e Biblioteca
		6 - Bibliografias por Biblioteca e Programa de Ensino

Filtros:
- Curso:
	p_department_code - Código texto do Curso
- Disciplina:
	p_course_code - Text com o Código da Disciplina
- Periodo Letivo Cursos/Disciplinas
	p_year text default '',
 	p_semester text default '',
 	p_period text default '',
- Biblioteca:
	p_library_code_1 - Text, contendo um Código da Biblioteca - No front end displaySpec: '{{name}} ({{code}})', queryField: code
	p_library_code_2 - Text, contendo uma lista de Códigos das Biblioteca(s) separados por vírgula (,) - queryField: code
- Item Tipo de Material:
	p_items_material_type_1 - Text, Um item do Combo Box
	p_items_material_type_2 - Text, Lista de Descrições separados por vírgula, do Textfield
- Item Status:
	p_items_status_1 - text contendo uma Descrição do Status do Item (Ex. Available, Intellectual item, etc...)	
	p_items_status_2 - text contendo uma lista de Descrições dos Status do Item separados por virgula , (Ex. Available, Intellectual item, etc...)	
- Instance Status:
	p_instance_status_1 - text contedo um Status das Instancias
	p_instance_status_2 - text contedo uma lista de Status das Instancias separados por vírgula ,
- Data inicial de aquisição:
	p_instances_initial_acquisition_date - text, data do pagamento do novo item na aquisição
- Data final de aquisição:
	p_instances_final_acquisition_date - text, data do pagamento do novo item na aquisição
*/

    --------------------------------------------------------------------------------
	-- AGRUPAMENTO 01
	-- 01 - Biblioteca, Programa de Ensino e Disciplina (Exemplares e Empréstimos) - Sintético
	-- 2 - Reconhecimento
	-- Filtros: 
	--     Data de Aquisição + Ano
	--     Data de Aquisição + Ano + Semestre
    --------------------------------------------------------------------------------
WITH department_temp AS ( --Filtro Curso
    SELECT id, name, description
    FROM folio_courses.coursereserves_departments__t__ 
    WHERE __current = true
    AND (
          p_department_code IS NULL OR trim(p_department_code) = ''
          OR replace(translate(LOWER(split_part(description, '-', 1)), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = replace(translate(LOWER(p_department_code), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
     )
),
total_itens_temp AS ( --Total de Itens/Exemplares por Biblioteca
	SELECT holdingsrecordid,effectivelocationid,materialtypeid,COUNT(*) AS total
	FROM folio_inventory.item
	WHERE __current = true
	GROUP BY holdingsrecordid,effectivelocationid,materialtypeid
),
total_emprestimos_itens_bib_temp AS ( --Total de Empréstimos dos Itens da Biblioteca do Plano de Ensino indicado, total absoluto sem parametro filtro data inicial e final
	SELECT li.current_item_effective_location_id,
		li.holdings_record_id,
	    li.item_id,
		li.material_type_id,
	    COUNT(li.loan_id) AS total_emprestimos_itens_bib_temp
	FROM  folio_derived.loans_items AS li
	WHERE li.current_item_effective_location_id is not null
	AND li.loan_date is not null
--	AND li.loan_date BETWEEN (COALESCE(NULLIF(trim(p_instances_initial_acquisition_date),''),'2000-01-01')||' 00:00:00')::timestamp AND (COALESCE(NULLIF(trim(p_instances_final_acquisition_date),''),'2090-01-01')||' 23:59:59')::timestamp
	GROUP BY li.current_item_effective_location_id,
		li.holdings_record_id,
	    li.item_id,
		li.material_type_id
),
data_aquisicao_temp AS ( --Consulta a data de Aquisição e Status PAGO se existirem
	SELECT distinct jsonb_extract_path_text(inv.jsonb,'paymentDate')::date AS data_de_aquisicao,
		jsonb_extract_path_text(inv.jsonb,'status') as payment_status, 
		ie.title,
		iext.item_id,
		iext.barcode,
		iext.holdings_record_id,
		iext.material_type_id,
		iext.effective_location_id,
		iext.status_name
	FROM 
		folio_derived.finance_transaction_invoices AS inv_fund
		LEFT JOIN folio_invoice.invoices AS inv ON inv_fund.invoice_id = inv.id
		LEFT JOIN folio_derived.po_lines_details_subscription AS pol ON inv_fund.po_line_id::uuid = pol.pol_id
		LEFT JOIN folio_derived.po_instance AS ie ON pol.pol_id = ie.po_line_id
		LEFT JOIN folio_inventory.holdings_record__t__ AS ho_pol ON ho_pol.instance_id=ie.pol_instance_id
		LEFT JOIN folio_derived.item_ext AS iext ON iext.holdings_record_id=ho_pol.id
	WHERE 
		inv.__current=true
		AND ho_pol.__current=true
		AND translate(LOWER(trim(jsonb_extract_path_text(inv.jsonb,'status'))), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou') = 'paid'
		AND jsonb_extract_path_text(inv.jsonb,'paymentDate')::date is not null
		AND jsonb_extract_path_text(inv.jsonb,'paymentDate')::date BETWEEN COALESCE(NULLIF(trim(p_instances_initial_acquisition_date),''),'2000-01-01')::date AND COALESCE(NULLIF(trim(p_instances_final_acquisition_date),''),'2090-01-01')::date
		AND ie.pol_instance_id is not null
		AND	iext.item_id is not null
		AND iext.barcode is not null
),
titulos_duplicados AS ( -- Identifica os títulos que aparecem mais de uma vez no acervo
    SELECT 
        jsonb_extract_path_text(jsonb,'title') as title,
        COUNT(*) as total_edicoes
    FROM 
        folio_inventory.instance
    WHERE 
		__current=true
        AND jsonb_extract_path_text(jsonb,'title') IS NOT NULL
		AND jsonb_extract_path_text(jsonb,'title') != ''
    GROUP BY 
        title
    HAVING 
        COUNT(*) > 1
)
			SELECT 
            'Reconhecimento'::text as avaliacao_mec,
            'Biblioteca, Programa de Ensino e Disciplina (Exemplares e Empréstimos) - Sintético'::text as agrupamento,
            lib.code::text AS codigo_biblioteca,			
            lib.name::text AS nome_biblioteca,
			trim(split_part(dept.description::text, '-', 1)) AS codigo_curso,			
			dept.description::text AS nome_curso,
			((regexp_match(ter.name, 'Letivo:\s*(\d{4})', 'i'))[1])::INTEGER AS ano,
			((regexp_match(ter.name, 'Semestre:\s*(\d+)', 'i'))[1])::INTEGER AS semestre,
			((regexp_match(ter.name, 'p[eéêí]ríodo:\s*(\d+)', 'i'))[1])::INTEGER AS periodo,
			ter.name::text AS descricao_periodo,
			c.course_number::text AS codigo_disciplina,			
            c.name::text AS nome_disciplina,	
			trim(split_part(loant.name::text, '-', 2)) as tipo_bibliografia,
			inst.id::uuid AS id_instancia,
			jsonb_extract_path_text(inst.jsonb,'hrid') AS hrid_instancia,
            status_inst.name AS status_instancia,			
            jsonb_extract_path_text(inst.jsonb::jsonb,'title')::text AS titulo_da_obra,
    		jsonb_extract_path_text(mt.jsonb,'name') AS tipo_de_material,
		--	jsonb_extract_path_text(item2.jsonb::jsonb,'id')::uuid AS id_item,
--			jsonb_extract_path_text(item2.jsonb::jsonb,'barcode')::text AS item_outro_barcode,
		/*	CASE 
				WHEN LOWER(trim(jsonb_extract_path_text(item.jsonb, 'status', 'name'))) = 'intellectual item' THEN 'Digital'
				ELSE 'Físico'
			END AS tipo_de_acervo_mec,	*/
			CASE 
				WHEN LOWER(trim(jsonb_extract_path_text(item.jsonb, 'status', 'name'))) = 'intellectual item' THEN total_itens.total
				ELSE COALESCE(total_itens.total, 0)
			END AS total_itens_na_bib,
			--total_itens_por_plano_de_ensino é o mesmo valor de total_itens_bib_ou_licencas_ebook
			CASE 
				WHEN LOWER(trim(jsonb_extract_path_text(item.jsonb, 'status', 'name'))) = 'intellectual item' THEN total_itens.total
				ELSE COALESCE(total_itens.total, 0)
			END AS total_itens_por_plano_de_ensino,			
		
			CASE 
				WHEN LOWER(trim(jsonb_extract_path_text(item.jsonb, 'status', 'name'))) = 'intellectual item' THEN total_emprestimos_todos_itens_bib.total_emprestimos
				ELSE COALESCE(total_emprestimos_todos_itens_bib.total_emprestimos, 0)
			END AS total_emprestimos_itens_na_bib,
			acq.data_de_aquisicao,
			acq.payment_status,
			-- acq.title::text AS title_na_aquisicao,
			-- Iniico monta: referencia_abnt
			( 
				-- (ON-LINE)
				CASE 
					WHEN TRIM(jsonb_extract_path_text(res.jsonb::jsonb,'copiedItem','uri')) IS NOT NULL 
					AND LOWER(trim(jsonb_extract_path_text(item.jsonb, 'status', 'name'))) = 'intellectual item' THEN
						'(ON-LINE) '
					ELSE ''
				END ||
				-- Autor
				CASE 
					WHEN con.contributor_name LIKE '%, %' THEN UPPER(SPLIT_PART(con.contributor_name, ', ', 1)) || ', ' || SPLIT_PART(con.contributor_name, ', ', 2)
					WHEN con.contributor_name IS NOT NULL THEN UPPER(SUBSTRING(con.contributor_name FROM '[^ ]+$')) || ', ' || REGEXP_REPLACE(con.contributor_name, ' [^ ]+$', '')
					ELSE ''
				END || '. ' ||
				-- Título (com marcação de negrito para fins de exibição)
				'<b>' || TRIM(jsonb_extract_path_text(inst.jsonb::jsonb,'title')) || '</b>' || 
				-- Edição (Se houver, adiciona ex: " . 3. ed.")
				CASE 
					WHEN NULLIF(REPLACE(REPLACE(REPLACE(jsonb_extract_path_text(inst.jsonb::jsonb,'editions'), '[', ''), ']', ''), '"', ''), '') IS NOT NULL 
					THEN '. ' || TRIM(REPLACE(REPLACE(REPLACE(jsonb_extract_path_text(inst.jsonb::jsonb,'editions'), '[', ''), ']', ''), '"', ''))
					ELSE ''
				END || '. ' ||
				-- Local de Publicação
				COALESCE(TRIM(p.publication_place), '[S.l.]') || ': ' ||
				-- Editora
				COALESCE(TRIM(p.publisher), '[s.n.]') || ', ' ||
				-- Ano
				COALESCE(SUBSTRING(p.date_of_publication FROM '\d{4}'), '[daqui para frente]') || '.' || 
				-- ISBN
				CASE 
					WHEN TRIM(isbn_temp.value) IS NOT NULL THEN
						' ISBN ' || TRIM(isbn_temp.value) || '.'
					ELSE ''
				END ||
				-- ISSN
				CASE 
					WHEN TRIM(issn_temp.value) IS NOT NULL THEN
						' ISSN ' || TRIM(issn_temp.value) || '.'
					ELSE ''
				END ||				
				-- Disponível em
				CASE 
					WHEN TRIM(jsonb_extract_path_text(res.jsonb::jsonb,'copiedItem','uri')) IS NOT NULL THEN
						' Disponível em: ' || TRIM(jsonb_extract_path_text(res.jsonb::jsonb,'copiedItem','uri')) || '.'
					ELSE ''
				END ||
				-- Possui outras edições
				CASE 
					WHEN obs.possui_outras_edicoes IS NOT NULL THEN obs.possui_outras_edicoes ELSE ''
				END ||	
				-- Código de barras do item / exemplar
				' Cód.' || jsonb_extract_path_text(item.jsonb::jsonb,'barcode')::text
			)::text AS referencia_abnt,
			TRIM(jsonb_extract_path_text(res.jsonb,'copiedItem','uri')) AS URL_PDF_link,
			isbn_temp.value AS isbn,
			issn_temp.value AS issn,
			obs.possui_outras_edicoes,			
			jsonb_extract_path_text(item.jsonb::jsonb,'barcode')::text AS item_barcode,
			jsonb_extract_path_text(item.jsonb, 'status', 'name') AS status_item
        FROM
			folio_courses.coursereserves_courses__t__ c --Disciplinas
        INNER JOIN department_temp dept ON c.department_id = dept.id --Cursos
 		LEFT JOIN folio_courses.coursereserves_courselistings__t__ cl ON c.course_listing_id = cl.id --Relacionando o Periodo Letivo + CNPQ + Localização	 
 		LEFT JOIN folio_inventory.location__t__ loc on cl.location_id = loc.id --Localiação na Biblioteca
 		LEFT JOIN folio_inventory.loclibrary__t__ lib on loc.library_id = lib.id --Biblioteca
		LEFT JOIN folio_courses.coursereserves_terms__t__ ter on cl.term_id = ter.id --Periodo Letivo / Programa
        LEFT JOIN folio_courses.coursereserves_reserves res ON cl.id = res.courselistingid --Itens/Exemplares vinculados na Reserva
        LEFT JOIN folio_inventory.item item ON jsonb_extract_path_text(res.jsonb::jsonb,'itemId')::uuid = jsonb_extract_path_text(item.jsonb::jsonb,'id')::uuid --Itens
		LEFT JOIN folio_inventory.material_type mt ON item.materialtypeid = mt.id
		LEFT JOIN folio_inventory.holdings_record__t__ ho on jsonb_extract_path_text(item.jsonb::jsonb,'holdingsRecordId')::uuid = ho.id --Coleção do Item
		LEFT JOIN folio_inventory.instance inst ON ho.instance_id = inst.id  --Titulo/Obra bibliografica
        LEFT JOIN folio_inventory.loan_type__t__ loant ON jsonb_extract_path_text(res.jsonb::jsonb,'temporaryLoanTypeId')::uuid = loant.id --Tipo de Bibliografica
		LEFT JOIN folio_derived.instance_contributors con ON inst.id = con.instance_id 
		LEFT JOIN folio_derived.instance_publication p ON inst.id = p.instance_id	
		LEFT JOIN folio_inventory.instance_status__t__ status_inst ON jsonb_extract_path_text(inst.jsonb::jsonb,'statusId')::uuid=status_inst.id
		LEFT JOIN data_aquisicao_temp acq ON item.id = acq.item_id		
		LEFT JOIN folio_inventory.holdings_record__t__ ho2 ON inst.id = ho2.instance_id
		--LEFT JOIN folio_inventory.item item2 ON ho2.id = item2.holdingsrecordid
		LEFT JOIN LATERAL ( --Recupera o ISBN
		    SELECT item_temp ->> 'value' AS value
		    FROM jsonb_array_elements(inst.jsonb::jsonb -> 'identifiers') AS item_temp
		    WHERE item_temp ->> 'identifierTypeId' = (
		        SELECT id::text 
		        FROM folio_inventory.identifier_type__t__
		        WHERE __current = true
		          AND UPPER(TRIM(name)) = 'ISBN'
		    )
		    LIMIT 1
		) AS isbn_temp ON true
		LEFT JOIN LATERAL ( --Recupera o ISSN
		    SELECT item_temp2 ->> 'value' AS value
		    FROM jsonb_array_elements(inst.jsonb::jsonb -> 'identifiers') AS item_temp2
		    WHERE item_temp2 ->> 'identifierTypeId' = (
		        SELECT id::text 
		        FROM folio_inventory.identifier_type__t__
		        WHERE __current = true
		          AND UPPER(TRIM(name)) = 'ISSN'
		    )
		    LIMIT 1
		) AS issn_temp ON true		
		LEFT JOIN LATERAL ( --Se existir, insere na Referencia ABNT a inforamção que possui outras edições no acervo
			SELECT 
				' (*) Observação: Esse título possui outras edições no acervo.' as possui_outras_edicoes
			FROM 
			    titulos_duplicados AS obs
			WHERE
				obs.title = jsonb_extract_path_text(inst.jsonb::jsonb,'title')
		) AS obs ON true		
		LEFT JOIN LATERAL ( --Recupera o total de itens existentes da mesma Biblioteca vinculada ao Plano de Ensino
		    SELECT total
		    FROM total_itens_temp AS total_itens
		    WHERE total_itens.holdingsrecordid = ho2.id
			AND total_itens.effectivelocationid = cl.location_id
			AND ho2.effective_location_id = total_itens.effectivelocationid
			AND total_itens.materialtypeid = item.materialtypeid
		) AS total_itens ON true
		LEFT JOIN LATERAL ( --Recupera o total de emprestimos por itens da mesma Biblioteca vinculada ao Plano de Ensino
		    SELECT holdings_record_id, current_item_effective_location_id, material_type_id, SUM(total_emprestimos_itens_bib_temp) AS total_emprestimos
		    FROM total_emprestimos_itens_bib_temp AS total_empr_itens_bib
		    WHERE total_empr_itens_bib.holdings_record_id = ho2.id
			AND total_empr_itens_bib.current_item_effective_location_id = cl.location_id
			AND ho2.effective_location_id = total_empr_itens_bib.current_item_effective_location_id
			AND total_empr_itens_bib.material_type_id = item.materialtypeid
			GROUP BY holdings_record_id, current_item_effective_location_id, material_type_id
		) AS total_emprestimos_todos_itens_bib ON true
        WHERE
			c.__current=true
			AND cl.__current=true
			AND loc.__current=true
			AND lib.__current=true
			AND ter.__current=true
			AND res.__current=true
			AND item.__current=true
			AND mt.__current=true			
			--AND item2.__current=true
			AND ho.__current=true
			AND ho2.__current=true
			AND inst.__current=true
			AND loant.__current=true
			and status_inst.__current=true
			and jsonb_extract_path_text(inst.jsonb::jsonb,'title') IS NOT NULL
			AND con.contributor_is_primary = true
			AND p.publication_ordinality=1
		    AND (
		        (COALESCE(trim(p_year), '') = '')
		        OR
		        (
					((regexp_match(ter.name, 'Letivo:\s*(\d{4})', 'i'))[1])::INTEGER = trim(p_year)::INTEGER
		        )
		    )
		    AND (
		        (COALESCE(trim(p_semester), '') = '')
		        OR
		        (
					((regexp_match(ter.name, 'Semestre:\s*(\d+)', 'i'))[1])::INTEGER = trim(p_semester)::INTEGER
		        )
		    )
		    AND (
		        (COALESCE(trim(p_period), '') = '')
		        OR
		        (
					((regexp_match(ter.name, 'p[eéêí]ríodo:\s*(\d+)', 'i'))[1])::INTEGER = trim(p_period)::INTEGER
		        )
		    )			
		    --AND COALESCE(jsonb_extract_path_text(item.jsonb, 'discoverySuppress')::boolean, false) = false
			AND (p_instances_initial_acquisition_date IS NULL OR trim(p_instances_initial_acquisition_date) = '' OR acq.data_de_aquisicao is not null)
			AND (p_instances_final_acquisition_date IS NULL OR trim(p_instances_final_acquisition_date) = '' OR acq.data_de_aquisicao is not null)
			AND (p_course_code IS NULL OR trim(p_course_code) = '' OR replace(translate(LOWER(c.course_number), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = replace(translate(LOWER(p_course_code), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', ''))
		    AND (
		        -- CONDIÇÃO 1: Se ambos os parâmetros forem vazios (ou nulos), traz TUDO
		        (COALESCE(trim(p_items_material_type_1), '') = '' AND COALESCE(trim(p_items_material_type_2), '') = '')
		        OR
		        -- CONDIÇÃO 2: Se houver valores, aplica os filtros com trim e quebra de vírgula
		        (
		            replace(translate(LOWER(jsonb_extract_path_text(mt.jsonb,'name')), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = replace(translate(LOWER(p_items_material_type_1), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
		            OR
		            replace(translate(LOWER(jsonb_extract_path_text(mt.jsonb,'name')), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')= ANY(regexp_split_to_array(replace(translate(LOWER(p_items_material_type_2), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', ''), '\s*,\s*'))
		        )
		    )
			AND (
		        (COALESCE(trim(p_instance_status_1), '') = '' AND COALESCE(trim(p_instance_status_2), '') = '')
		        OR
		        (
		            replace(translate(LOWER(status_inst.name), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = replace(translate(LOWER(p_instance_status_1), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
		            OR
		            replace(translate(LOWER(status_inst.name), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = ANY(regexp_split_to_array(replace(translate(LOWER(p_instance_status_2), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', ''), '\s*,\s*'))
		        )
		    )
			AND (
		        (COALESCE(trim(p_items_status_1), '') = '' AND COALESCE(trim(p_items_status_2), '') = '')
		        OR
		        (
		            replace(translate(LOWER(jsonb_extract_path_text(item.jsonb, 'status', 'name')), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = replace(translate(LOWER(p_items_status_1), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
		            OR
		            replace(translate(LOWER(jsonb_extract_path_text(item.jsonb, 'status', 'name')), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = ANY(regexp_split_to_array(replace(translate(LOWER(p_items_status_2), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', ''), '\s*,\s*'))
		        )
		    )
			AND (
		        (COALESCE(trim(p_library_code_1), '') = '' AND COALESCE(trim(p_library_code_2), '') = '')
		        OR
		        (
		            replace(translate(LOWER(lib.code), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = replace(translate(LOWER(p_library_code_1), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '')
		            OR
		            replace(translate(LOWER(lib.code), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', '') = ANY(regexp_split_to_array(replace(translate(LOWER(p_library_code_2), 'áéíóúâêîôûãõçàèìòùäëïöü', 'aeiouaeiouaocaeeiouaeiou'), ' ', ''), '\s*,\s*'))
		        )
		    )
			AND ((regexp_match(ter.name, 'Letivo:\s*(\d{4})', 'i'))[1]) is not null --Ano
        order BY 
			nome_biblioteca,
			nome_curso,
			descricao_periodo,
			nome_disciplina,
			tipo_bibliografia,
			titulo_da_obra,
			item_barcode;
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;