
  drop table concept_stage;
  create table concept_stage as (select distinct * from concept_stage_no_RxE)
;
drop table concept_relationship_stage ;
create table concept_relationship_stage as (select distinct * from concept_rel_stage_no_RxE)
;
drop table drug_strength_stage purge;
create table drug_strength_stage as (select distinct * from drug_strength_st_no_RxE)
;
commit
;/*
 drop table concept_stage_no_RxE;
   create table concept_stage_no_RxE as (select distinct *from concept_stage)
   ;
     drop table concept_rel_stage_no_RxE;
   create table concept_rel_stage_no_RxE as (select * from concept_relationship_stage)
   ;
   create table drug_strength_st_no_RxE as (select * from drug_strength_stage);
commit;
*/
CREATE INDEX idx_cs_concept_code ON concept_stage (concept_code);
CREATE INDEX idx_cs_concept_id ON concept_stage (concept_id);
CREATE INDEX idx_concept_code_1 ON concept_relationship_stage (concept_code_1);
CREATE INDEX idx_concept_code_2 ON concept_relationship_stage (concept_code_2);
  CREATE INDEX idx_drug_concept_code ON drug_strength_stage (drug_concept_code );
  CREATE INDEX idx_ingred_concept_code ON drug_strength_stage (ingredient_concept_code);
  ;
  delete  from concept_relationship_stage where concept_code_2 like 'XXX%'
  ;
  commit
  ;
