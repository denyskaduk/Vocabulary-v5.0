--1st part --using gemscript_dmd_map
insert into concept_stage
dmd_drug_name as concept_name, -- this is not quite correct, we need the original Gemscript names.
'Drug' as domain_id,
'Gemscript' as vocabulary_id,
'Gemscript' as concept_class_id,
null as standard_concept,
gemscript_drug_code as concept_code,
latest_update as valid_start_date -- ????? 1-Apr-2016
'31-Dec-2099' as valid_end_date,
null as invalid_reason
from gemscript_dmd_map
;
--4000 they give us later
 insert into concept_Stage (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select  '', GENERICNAME,'Drug','Gemscript','Gemscript' , '', VISION_DRUGCODE,  TO_DATE ('20160401', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd') as valid_end_date, null as  INVALID_REASON from  GEMSCRIPT_DMD_MAP_2
where VISION_DRUGCODE is not null
;
--THIN Gemscript
 insert into concept_Stage (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select  '', GENERICNAME,'Drug','Gemscript','Gemscript THIN' , '', drugcode,  TO_DATE ('20160401', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd') as valid_end_date, null as  INVALID_REASON from  THIN_GEMSCRIPT_MAP
where VISION_DRUGCODE is not null
;

--1st part --using gemscript_dmd_map
insert into concept_relationship_stage
gemscript_drug_code as concept_code_1,
'Gemscript' as vocabulary_id_1,
dmd_code as concept_code_2,
'dm+d' as vocabulary_id_2,
'Maps to' as relationship_id,
latest_update as valid_start_date -- ????? 1-Apr-2016
'31-Dec-2099' as valid_end_date,
null as invalid_reason
from gemscript_dmd_map
;
--these 4760 issue they give us later
insert into concept_relationship_stage (CONCEPT_CODE_1,VOCABULARY_ID_1,CONCEPT_CODE_2, VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select VISION_DRUGCODE as concept_code_1,
'Gemscript' as vocabulary_id_1,
dmd_code as concept_code_2,
'dm+d' as vocabulary_id_2,
'Maps to' as relationship_id,
TO_DATE ('20160401', 'yyyymmdd') as valid_start_date ,-- ????? 1-Apr-2016
TO_DATE ('20991231', 'yyyymmdd') as valid_end_date,
null as invalid_reason
from GEMSCRIPT_DMD_MAP_2 
;
--THIN Gemscript to Gemscript
insert into concept_relationship_stage (CONCEPT_CODE_1,VOCABULARY_ID_1,CONCEPT_CODE_2, VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select DRUGCODE as concept_code_1,
'Gemscript' as vocabulary_id_1,
VISION_DRUGCODE as concept_code_2,
'Gemscript' as vocabulary_id_2,
'Maps to' as relationship_id,
TO_DATE ('20160401', 'yyyymmdd') as valid_start_date ,-- ????? 1-Apr-2016
TO_DATE ('20991231', 'yyyymmdd') as valid_end_date,
null as invalid_reason
from THIN_GEMSCRIPT_MAP;

commit;
;
/*
create table THIN_to_rx as
select concept_code_1, concept_name_1, concept_code_2,concept_name_2, min (lvl) from (
select a.concept_code as concept_code_1, a.concept_name as concept_name_1, nvl (e.concept_code, d.concept_code) as concept_code_2, nvl (e.concept_name, d.concept_name) as concept_name_2,
nvl (e.vocabulary_id, d.vocabulary_id) as vocabulary_id_2,
 nvl (min_level_of_separation, 0) as lvl

 from concept_stage a --'Gemscript THIN'
 join concept_relationship_stage rt on a.concept_code = rt.concept_code_1 
join concept_stage bt on  bt.concept_code = rt.concept_code_2 and vocabulary_id = 'Gemscript' and concept_class_id = 'Gemscript'

join concept_relationship_stage r on bt.concept_code = r.concept_code_1 
join concept b on  b.concept_code = r.concept_code_2 and vocabulary_id = 'dm+d'

join concept_relationship rd on rd.concept_id_1 = b.concept_id
join  concept d on  d.concept_id = r.concept_id_2 and vocabulary_id like 'RxNorm%'
join dev_dmd.concept_ancestor on ancestor_concept_id = d.concept_id
left join concept e on e.concept_id = descendant_concept_id and not regexp_like (e.concept_class_id, 'Branded|Box|Manufact') and regexp_like (d.concept_class_id, 'Branded|Box|Manufact')

where a.concept_class_id= 'Gemscript THIN'
) group by concept_code_1, concept_name_1,concept_code_2,concept_name_2, vocabulary_id_2
;
*/
;
--rebuild relationships with final 
drop table THIN_to_rx;
create table THIN_to_rx as
select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, nvl (rd3.concept_code, e.concept_code) as concept_code_2, nvl (rd3.concept_name, e.concept_name) as concept_name_2,
nvl (rd3.vocabulary_id, e.vocabulary_id) as vocabulary_id_2
--distinct a.concept_class_id, d.concept_class_id,rd2.relationship_id, e.concept_class_id, rd3.concept_class_id
 from concept_stage a --'Gemscript THIN'
 join concept_relationship_stage rt on a.concept_code = rt.concept_code_1 
join concept_stage bt on  bt.concept_code = rt.concept_code_2 and bt.vocabulary_id = 'Gemscript' and bt.concept_class_id = 'Gemscript'

join concept_relationship_stage r on bt.concept_code = r.concept_code_1 
join dev_dmd.concept b on  b.concept_code = r.concept_code_2 and b.vocabulary_id = 'dm+d' and b.domain_id = 'Drug'

join dev_dmd.concept_relationship rd on rd.concept_id_1 = b.concept_id
join  dev_dmd.concept d on  d.concept_id = rd.concept_id_2 and d.vocabulary_id like 'RxNorm%'
left join (select * from dev_dmd.concept_relationship rd2 
join  dev_dmd.concept e on  e.concept_id = rd2.concept_id_2 and e.vocabulary_id like 'RxNorm%') rd2 on rd2.concept_id_1 = d.concept_id and rd2.relationship_id in ('Tradename of', 'Marketed form of') 

left join (select * from dev_dmd.concept_relationship rd3 
join  dev_dmd.concept f on  f.concept_id = rd3.concept_id_2 and f.vocabulary_id like 'RxNorm%' and rd3.relationship_id = 'Tradename of') rd3 on rd3.concept_id_1 = rd2.concept_id and regexp_replace (rd3.concept_class_id, 'Clinical', 'Branded') = rd2.concept_class_id
where a.concept_class_id= 'Gemscript THIN'
;
delete
 from concept_relationship_stage a where exists (select 1 from concept_stage c where concept_class_id = 'Gemscript THIN' and a.concept_code_1 = concept_code)
;
commit
;
insert into concept_relationship_stage (CONCEPT_ID_1,CONCEPT_ID_2,CONCEPT_CODE_1,CONCEPT_CODE_2,VOCABULARY_ID_1,VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select '', '', CONCEPT_CODE_1,CONCEPT_CODE_2, 'Gemscript', vocabulary_id_2, 'Maps to', (select latest_update from vocabulary where vocabulary_id = 'Gemscript'),TO_DATE ('20991231', 'yyyymmdd'), '' from THIN_to_rx
;
commit
;

