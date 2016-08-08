--1st part --using gemscript_dmd_map
insert into concept_stage (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select '', dmd_drug_name , -- this is not quite correct, we need the original Gemscript names.
'Drug' ,
'Gemscript' ,
'Gemscript' ,
null ,
gemscript_drug_code ,
TO_DATE ('20160401', 'yyyymmdd'), -- ????? 1-Apr-2016
TO_DATE ('20991231', 'yyyymmdd') as valid_end_date,
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
insert into concept_relationship_stage  (CONCEPT_CODE_1,VOCABULARY_ID_1,CONCEPT_CODE_2, VOCABULARY_ID_2,RELATIONSHIP_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select gemscript_drug_code as concept_code_1,
'Gemscript' as vocabulary_id_1,
dmd_code as concept_code_2,
'dm+d' as vocabulary_id_2,
'Maps to' as relationship_id,
TO_DATE ('20160401', 'yyyymmdd') as valid_start_date, -- ????? 1-Apr-2016
TO_DATE ('20991231', 'yyyymmdd') as valid_end_date,
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
--calculate number of ingredients
create table ingred_cnt as 
select drug_concept_id, count (1) as ingred_cnt from drug_strength where invalid_reason is null group by drug_concept_id
;

--rebuild relationships with final 
drop table THIN_to_rx;
create table THIN_to_rx as
select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, coalesce (rd3.concept_code, rd2.concept_code, d.concept_code) as concept_code_2, coalesce (rd3.concept_name, rd2.concept_name, d.concept_name) as concept_name_2,
coalesce (rd3.vocabulary_id, rd2.vocabulary_id, d.vocabulary_id) as vocabulary_id_2
--distinct a.concept_class_id, d.concept_class_id,rd2.relationship_id, e.concept_class_id, rd3.concept_class_id
 from concept_stage a --'Gemscript THIN'
 join concept_relationship_stage rt on a.concept_code = rt.concept_code_1 
join concept_stage bt on  bt.concept_code = rt.concept_code_2 and bt.vocabulary_id = 'Gemscript' and bt.concept_class_id = 'Gemscript'

join concept_relationship_stage r on bt.concept_code = r.concept_code_1 
join concept b on  b.concept_code = r.concept_code_2 and b.vocabulary_id = 'dm+d' and b.domain_id = 'Drug' and b.invalid_reason is  null

join concept_relationship rd on rd.concept_id_1 = b.concept_id and rd.invalid_reason is null
join  concept d on  d.concept_id = rd.concept_id_2 and d.vocabulary_id like 'RxNorm%' and d.invalid_reason is null
left join (select * from concept_relationship rd2 
join  concept e on  e.concept_id = rd2.concept_id_2 and e.vocabulary_id like 'RxNorm%' where rd2.invalid_reason is null and e.invalid_reason is null) rd2 on rd2.concept_id_1 = d.concept_id and rd2.relationship_id in ('Tradename of', 'Marketed form of') 
and regexp_count (d.concept_name, ' / ') = regexp_count (rd2.concept_name, ' / ') --remain the same counts of ingredients

left join (select * from concept_relationship rd3 
join  concept f on  f.concept_id = rd3.concept_id_2 and f.vocabulary_id like 'RxNorm%' and rd3.relationship_id = 'Tradename of' where rd3.invalid_reason is null and f.invalid_reason is null) rd3 on rd3.concept_id_1 = rd2.concept_id 
and regexp_replace (rd3.concept_class_id, 'Clinical', 'Branded') = rd2.concept_class_id 
and  regexp_count (rd2.concept_name, ' / ') = regexp_count (rd3.concept_name, ' / ') 
where a.concept_class_id= 'Gemscript THIN'
;
--the same number of ingredients but incorrect
DELETE
FROM THIN_TO_RX
WHERE CONCEPT_CODE_1 = '61862979'
AND   CONCEPT_CODE_2 = 'OMOP288269';
DELETE
FROM THIN_TO_RX
WHERE CONCEPT_CODE_1 = '61862979'
AND   CONCEPT_CODE_2 = 'OMOP288129';
DELETE
FROM THIN_TO_RX
WHERE CONCEPT_CODE_1 = '85065998'
AND   CONCEPT_CODE_2 = 'OMOP288188';
DELETE
FROM THIN_TO_RX
WHERE CONCEPT_CODE_1 = '85065998'
AND   CONCEPT_CODE_2 = 'OMOP288259'
;
-- mappings from THIN Gemscript to Gemscript
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
--artifacts got downloading source tables
update concept_relationship_stage set concept_code_2=regexp_substr(concept_code_2, '[[:alpha:]]*\d*')
where concept_code_2!=regexp_substr(concept_code_2, '[[:alpha:]]*\d*') and vocabulary_id_2 !='ATC'
;

     delete from concept_relationship_stage where concept_code_1='';
     ;
     delete from concept_relationship_stage where concept_code_1 is null
;
delete from concept_relationship_stage where concept_code_1 ='69109978' ; 
commit;


--xx1 CheckReplacementMappings
BEGIN
   DEVV5.VOCABULARY_PACK.CheckReplacementMappings;
END;
COMMIT;

--xx2 Deprecate 'Maps to' mappings to deprecated and upgraded concepts
BEGIN
   DEVV5.VOCABULARY_PACK.DeprecateWrongMAPSTO;
END;
COMMIT;   

--xx3 Add mapping from deprecated to fresh concepts
  BEGIN
     DEVV5.VOCABULARY_PACK.AddFreshMAPSTO;
  END;
COMMIT;

--xx4 Delete ambiguous 'Maps to' mappings following by rules:
--1. if we have 'true' mappings to Ingredient or Clinical Drug Comp, then delete all others mappings
--2. if we don't have 'true' mappings, then leave only one fresh mapping
--3. if we have 'true' mappings to Ingredients AND Clinical Drug Comps, then delete mappings to Ingredients, which have mappings to Clinical Drug Comp
   BEGIN
       DEVV5.VOCABULARY_PACK.DeleteAmbiguousMAPSTO;
    END;
    COMMIT;

