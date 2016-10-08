/*
insert into concept (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select * from devv5.concept where concept_name ='Gemscript THIN'
*/
;
insert into concept_stage
select * from dev_gemscript.concept_stage
;
insert into concept_relationship_stage (CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON from dev_gemscript.concept_relationship_stage
;
--SELECT * FROM VOCABULARY

update concept_relationship_stage set concept_code_2=regexp_substr(concept_code_2, '[[:alpha:]]*\d*')
where concept_code_2!=regexp_substr(concept_code_2, '[[:alpha:]]*\d*') and vocabulary_id_2 !='ATC'
;
     delete from concept_relationship_stage where concept_code_2 =''
     
commit;
