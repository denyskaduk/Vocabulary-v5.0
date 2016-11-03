--use it ONLY if input tables run was before fast recreate run
--set current sequence for OMOP codes
declare
 ex number;
begin
select max(iex)+1 into ex from (  
    select cast(substr(concept_code, 5) as integer) as iex from concept where concept_code like 'OMOP%' and concept_code not like '% %' -- Last valid value of the OMOP123-type codes
);
  begin
    execute immediate 'create sequence new_vocab increment by 1 start with ' || ex || ' nocycle cache 20 noorder';
    exception
      when others then null;
  end;
end;
-- change to procedure in the future
--drop table code_replace;
 create table code_replace as 
 select 'OMOP'||new_vocab.nextval as new_code, concept_code as old_code from (
select distinct  concept_code from drug_concept_stage where concept_code like 'OMOP%' order by (cast ( regexp_substr( concept_code, '\d+') as int))
)
;
update drug_concept_stage a set concept_code = (select new_code from code_replace b where a.concept_code = b.old_code) 
where a.concept_code like 'OMOP%'
;--select * from code_replace where old_code ='OMOP28663';
commit
;
update relationship_to_concept a  set concept_code_1 = (select new_code from code_replace b where a.concept_code_1 = b.old_code)
where a.concept_code_1 like 'OMOP%'
;
commit
;
update ds_stage a  set ingredient_concept_code = (select new_code from code_replace b where a.ingredient_concept_code = b.old_code)
where a.ingredient_concept_code like 'OMOP%'
;
commit
;
update ds_stage a  set drug_concept_code = (select new_code from code_replace b where a.drug_concept_code = b.old_code)
where a.drug_concept_code like 'OMOP%'
;commit
;
update internal_relationship_stage a  set concept_code_1 = (select new_code from code_replace b where a.concept_code_1 = b.old_code)
where a.concept_code_1 like 'OMOP%'
;commit
;
update internal_relationship_stage a  set concept_code_2 = (select new_code from code_replace b where a.concept_code_2 = b.old_code)
where a.concept_code_2 like 'OMOP%'
;
commit
;
update pc_stage a  set DRUG_CONCEPT_CODE = (select new_code from code_replace b where a.DRUG_CONCEPT_CODE = b.old_code)
where a.DRUG_CONCEPT_CODE like 'OMOP%'
;
commit;