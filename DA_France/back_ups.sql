create table concept_stage_260716 as select * from concept_stage
;
create table concept_rel_stage_260716 as select * from concept_relationship_stage
;
create table concept_syn_st_260716 as select * from concept_synonym_stage
;
create table drug_strength_260716 as select  * from drug_strength_stage;
select count (1) from concept_rel_stage_260716
;
truncate table concept_relationship_stage
;
insert into concept_relationship_stage
select * from concept_rel_stage_260716
;
commit
;
select * from best_map where not exists (select 1 from concept_rel_stage_260716 b where on a.concept_code_1 = b.Q_DCODE join concept cx on cx.concept_id=b.r_did and cx.vocabulary_id like 'RxNorm%' and a.relationship_id= 'Maps to')
;
select distinct relationship_id from concept_rel_stage_260716
