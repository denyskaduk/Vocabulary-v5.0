CREATE OR REPLACE FUNCTION vocabulary_pack.deleteambiguousmapsto (
)
RETURNS void AS
$body$
/*
 Deletes ambiguous 'Maps to' mappings following by rules:
 1. if we have 'true' mappings to Ingredient or Clinical Drug Comp, then delete all others mappings
 2. if we don't have 'true' mappings, then leave only one fresh mapping
 3. if we have 'true' mappings to Ingredients AND Clinical Drug Comps, then delete mappings to Ingredients, which have mappings to Clinical Drug Comp
*/
BEGIN
	DELETE
	FROM concept_relationship_stage
	WHERE ctid IN (
			SELECT rid
			FROM (
				SELECT rid,
					concept_code_1,
					concept_code_2,
					pseudo_class_id,
					rn,
					MIN(pseudo_class_id) OVER (
						PARTITION BY concept_code_1,
						vocabulary_id_1,
						vocabulary_id_2
						) have_true_mapping,
					has_rel_with_comp
				FROM (
					SELECT cs.ctid rid,
						concept_code_1,
						concept_code_2,
						vocabulary_id_1,
						vocabulary_id_2,
						CASE 
							WHEN c.concept_class_id IN (
									'Ingredient',
									'Clinical Drug Comp'
									)
								THEN 1
							ELSE 2
							END pseudo_class_id,
						ROW_NUMBER() OVER (
							PARTITION BY concept_code_1,
							vocabulary_id_1,
							vocabulary_id_2 ORDER BY cs.valid_start_date DESC,
								c.valid_start_date DESC,
								c.concept_id DESC
							) rn,
						--fresh mappings first
						(
							SELECT 1
							FROM concept_relationship_stage cr_int,
								concept_relationship_stage crs_int,
								concept_stage c_int
							WHERE cr_int.invalid_reason IS NULL
								AND cr_int.relationship_id = 'RxNorm ing of'
								AND cr_int.concept_code_1 = c.concept_code
								AND cr_int.vocabulary_id_1 = c.vocabulary_id
								AND c.concept_class_id = 'Ingredient'
								AND crs_int.relationship_id = 'Maps to'
								AND crs_int.invalid_reason IS NULL
								AND crs_int.concept_code_1 = cs.concept_code_1
								AND crs_int.vocabulary_id_1 = cs.vocabulary_id_1
								AND crs_int.concept_code_2 = c_int.concept_code
								AND crs_int.vocabulary_id_2 = c_int.vocabulary_id
								AND c_int.domain_id = 'Drug'
								AND c_int.concept_class_id = 'Clinical Drug Comp'
								AND cr_int.concept_code_2 = c_int.concept_code
								AND cr_int.vocabulary_id_2 = c_int.vocabulary_id
							) has_rel_with_comp
					FROM concept_relationship_stage cs,
						concept_stage c
					WHERE relationship_id = 'Maps to'
						AND cs.invalid_reason IS NULL
						AND cs.concept_code_2 = c.concept_code
						AND cs.vocabulary_id_2 = c.vocabulary_id
						AND c.domain_id = 'Drug'
					) AS s1
				) AS s2
			WHERE (
					(
						have_true_mapping = 1
						AND pseudo_class_id = 2
						)
					OR
					--if we have 'true' mappings to Ingredients or Clinical Drug Comps (pseudo_class_id=1), then delete all others mappings (pseudo_class_id=2)
					(
						have_true_mapping <> 1
						AND rn > 1
						)
					OR --if we don't have 'true' mappings, then leave only one fresh mapping
					has_rel_with_comp = 1
					--if we have 'true' mappings to Ingredients AND Clinical Drug Comps, then delete mappings to Ingredients, which have mappings to Clinical Drug Comp
					)
			);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;