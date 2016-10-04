--1 step - all that easy to match
select distinct a.*, c.* from allergy a join devv5.concept_synonym s on upper (s.CONCEPT_SYNONYM_NAME)  = upper (allergy_name ||' allergy')
join devv5.concept c on c.concept_id = s.CONCEPT_ID 
where c.vocabulary_id = 'SNOMED'
and c.invalid_reason is null --447
;
--2 step - it;s better
select distinct a.*, c.* from allergy a join devv5.concept_synonym s on upper (s.CONCEPT_SYNONYM_NAME)  = upper (allergy_name ||' allergy') or upper (s.CONCEPT_SYNONYM_NAME)  = upper ('allergy to '||allergy_name)
join devv5.concept c on c.concept_id = s.CONCEPT_ID 
where c.vocabulary_id = 'SNOMED'
and c.invalid_reason is null --509
;
--find a way how to use 246075003 causative agent relationship
create table all_utl_m_1 as (
select c.concept_code, c.concept_name, a.* , UTL_MATCH.EDIT_DISTANCE (upper (allergy_name) , upper (c2.concept_name)) as match
 from devv5.concept c
 join devv5.concept_relationship r  on c.concept_id = concept_id_1 and r.invalid_reason is null  and r.RELATIONSHIP_ID = 'Has causative agent'
 join devv5.concept c2 on c2.concept_id = concept_id_2 and c2.vocabulary_id = 'SNOMED' and c2.invalid_reason is null
 join allergy a on UTL_MATCH.EDIT_DISTANCE (upper (allergy_name) , upper (c2.concept_name)) < 3 
where c.vocabulary_id = 'SNOMED' and c.invalid_reason is null and c.concept_class_id in ('Substance')
and c2.concept_id is null 
and c.concept_name like '%allergy%'
);
--need to find a way to improve the results of this review
;
