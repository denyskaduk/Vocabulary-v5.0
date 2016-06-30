
--"reboot" drug_concept_stage
drop table drug_concept_stage
;
create table drug_concept_stage as select * from
drug_concept_stage_existing
;
--consider this table as manual
/*
create table ingred_to_ingred_FINAL_BY_Lena (CONCEPT_CODE_1	varchar (200),
CONCEPT_NAME_1 varchar (200),	INSERT_ID_1 int,  CONCEPT_CODE_2 varchar (200),	CONCEPT_NAME_2 varchar (200),	INSERT_ID_2 int , REL_TYPE varchar (20),	INVALID_REASON varchar (20))
;
WbImport -file=C:/mappings/DM+D/Ingred_Lena_review.txt
         -type=text
         -table=LENA_REVIEW
         -encoding="ISO-8859-15"
         -header=true
         -decode=false
         -dateFormat="yyyy-MM-dd"
         -timestampFormat="yyyy-MM-dd HH:mm:ss"
         -delimiter='\t'
         -decimal=.
         -fileColumns=CONCEPT_CODE_1,CONCEPT_NAME_1,INSERT_ID_1,CONCEPT_CODE_2,CONCEPT_NAME_2,INSERT_ID_2
         -quoteCharEscaping=none
         -ignoreIdentityColumns=false
         -deleteTarget=false
         -continueOnError=false`
         -batchSize=1000;

;
drop sequence new_seq;
 create sequence new_seq increment by 1 start with 1 nocycle cache 20 noorder;
;
--add OMOP codes to new ingredients
update ingred_to_ingred_FINAL_BY_Lena
set CONCEPT_CODE_2 ='OMOP'||new_seq.nextval where CONCEPT_CODE_2 is null and CONCEPT_name_2 is not null
;
select CONCEPT_CODE_2, CONCEPT_name_2 from ingred_to_ingred_FINAL_BY_Lena where CONCEPT_CODE_2 like 'OMOP%'
;
insert into ingred_to_ingred_FINAL_BY_Lena (CONCEPT_CODE_1, CONCEPT_name_1)
select distinct CONCEPT_CODE_2, CONCEPT_name_2 from ingred_to_ingred_FINAL_BY_Lena where CONCEPT_CODE_2 like 'OMOP%'
;
*/
--Non drug definition - several steps including different criteria for non-drug definition	
--BASED ON NAMES, AND absence of form info

 --all branded drugs to clical drugs, then use in ds_stage, because ds_stage...
drop table Branded_to_clinical;
create table Branded_to_clinical as (
  select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, cs.concept_code as concept_code_2, cs.concept_name as  concept_name_2 from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED' and a.concept_class_id like 'Branded Drug%'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id like 'Clinical Drug%')
;
--duplicates due to ONLY DEPRECATED to NON-DEPRECATED DRUGS relationship
DELETE from Branded_to_clinical a 
where exists (select 1 from 
(
SELECT A.CONCEPT_CODE_1, A.CONCEPT_CODE_2 FROM Branded_to_clinical A
JOIN DRUG_CONCEPT_STAGE C ON A.CONCEPT_CODE_1 = C.CONCEPT_CODE
JOIN DRUG_CONCEPT_STAGE B ON A.CONCEPT_CODE_2 = B.CONCEPT_CODE and b.concept_class_id like 'Clinical Drug%'
WHERE B.INVALID_REASON IS NOT NULL AND C.INVALID_REASON IS NULL
) b where a.CONCEPT_CODE_1 = b.CONCEPT_CODE_1 and a.CONCEPT_CODE_2 = b.CONCEPT_CODE_2)
;
--Packs 1 step
drop table CLIN_DR_PACK_TO_CLIN_DR_BOX;
create table CLIN_DR_PACK_TO_CLIN_DR_BOX as 
--to determine packs we can try to find specific relationship patterns
  select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1,  cs.concept_code as concept_code_2, cs.concept_name as concept_name_2 from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and a.insert_id in  (14) and cs.insert_id in  (14)   and a.concept_code != cs.concept_code and a.concept_class_id = cs.concept_class_id
--remove non-drugs except '9149411000001109' (is a drug)
join (
select concept_code_1 from (
  select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1,cs.concept_code as concept_code_2 from drug_concept_stage  a 
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and a.insert_id = 14  and cs.insert_id =14 and a.concept_code != cs.concept_code where RELATIONSHIP_ID ='Is a' and not regexp_like (a.concept_name, 'bandage|dressing'))
group by concept_code_1 having count (1) >1 union select '9149411000001109' --one who have 1 component but still is a pack
from dual ) x on x.concept_code_1 = a.concept_code
;
--but we still have to create packs for clinical Drugs, 
--another condition for pack definition
drop table DR_TO_CLIN_DR_BOX;
create table DR_TO_CLIN_DR_BOX as
  select distinct a.concept_code, a.concept_name,a.concept_class_id, a.invalid_reason, /*cs.concept_code, cs.concept_name, cs.concept_class_id, 
bc.concept_code_2, bc.concept_name_2  ,*/
b.concept_code_2, b.concept_name_2 from drug_concept_stage  a
left join branded_to_clinical bc on bc.concept_code_1 = a.concept_code 
join concept c on (a.concept_code = c.concept_code or bc.concept_code_2 = c.concept_code ) and c.vocabulary_id = 'SNOMED'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and a.insert_id in (11,12,13)  and cs.insert_id in (14,15) and a.concept_code != cs.concept_code
 join 
CLIN_DR_PACK_TO_CLIN_DR_BOX b on b.CONCEPT_CODE_1 = cs.concept_code or b.CONCEPT_CODE_1 = bc.concept_code_2
where  
regexp_count (a.concept_name, 'tablet|capsul') >1 and
not regexp_like (a.concept_name, 'bandage|dressing')   
;
--clinical and branded
drop table DR_TO_CLIN_DR_BOX_0;
create table DR_TO_CLIN_DR_BOX_0 as  
select CONCEPT_CODE,CONCEPT_NAME,CONCEPT_CODE_2,CONCEPT_NAME_2 from DR_TO_CLIN_DR_BOX
union
select CONCEPT_CODE_1,CONCEPT_NAME_1,CONCEPT_CODE_2,CONCEPT_NAME_2 from CLIN_DR_PACK_TO_CLIN_DR_BOX
;
drop table DR_pack_TO_CLIN_DR_BOX_full;
create table DR_pack_TO_CLIN_DR_BOX_full as
select distinct a.concept_code_1, a.concept_name_1, b.CONCEPT_CODE_2,b.CONCEPT_NAME_2 from branded_to_clinical a join DR_TO_CLIN_DR_BOX_0 b on a.concept_code_2 = b.concept_code
union 
select distinct CONCEPT_CODE,CONCEPT_NAME,CONCEPT_CODE_2,CONCEPT_NAME_2 from DR_TO_CLIN_DR_BOX_0
--further this Packs table will be modified using non-drugs definition
;
--manual update of Packs tables 
/*
create table PACK_DRUG_TO_CODE_2_2_SEQ as (select distinct drug_new_name from PACK_DRUG_TO_CODE_2_2 where drug_code is null);
alter table  PACK_DRUG_TO_CODE_2_2_SEQ 
add drug_code varchar(255);
update PACK_DRUG_TO_CODE_2_2_SEQ 
set drug_code='OMOP'||new_seq.nextval;
update PACK_DRUG_TO_CODE_2_2 b
set b.drug_code= case when b.drug_code is null then (select a.drug_code from PACK_DRUG_TO_CODE_2_2_SEQ a where a.drug_new_name=b.drug_new_name ) else b.drug_code end;
update PACK_DRUG_TO_CODE_2_2
set PACK_NAME=regexp_replace(PACK_NAME,'"')
*/
--for now remain PACK_DRUG_TO_CODE_2_2 as manual without rebuilding

;
--Box to drug - 1 step
drop table Box_to_Drug ;
create table Box_to_Drug as (
--select count (1) from (
  select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, a.concept_class_id as concept_class_id_1,  cs.concept_code as concept_code_2, cs.concept_name as  concept_name_2, 
cs.concept_class_id as concept_class_id_2  
 from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED' and a.concept_class_id like '%Box%'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id like '%Drug%' and cs.concept_class_id not like '%Box%'
)
;
--delete invalid concepts, they give incorrect relationships
DELETE from Box_to_Drug a 
where exists (select 1 from 
(
SELECT A.CONCEPT_CODE_1, A.CONCEPT_CODE_2 FROM Box_to_Drug A
JOIN DRUG_CONCEPT_STAGE C ON A.CONCEPT_CODE_1 = C.CONCEPT_CODE
JOIN DRUG_CONCEPT_STAGE B ON A.CONCEPT_CODE_2 = B.CONCEPT_CODE and b.concept_class_id like '%Drug%'
WHERE B.INVALID_REASON IS NOT NULL AND C.INVALID_REASON IS NULL
) b where a.CONCEPT_CODE_1 = b.CONCEPT_CODE_1 and a.CONCEPT_CODE_2 = b.CONCEPT_CODE_2)
;
--mofify table with additional fields with box size, amount
alter table Box_to_Drug
add  Box_amount varchar (250)
;
--define that by name difference
update Box_to_Drug
set Box_amount = replace (CONCEPT_NAME_1, CONCEPT_NAME_2||' ', '')
;
alter table Box_to_Drug add  Box_size integer; 
alter table Box_to_Drug add amount_unit varchar (20);
alter table Box_to_Drug add  amount_value int;
;
--fill Box_size, amount_unit, amount_value
update Box_to_Drug
set amount_value =  regexp_substr (BOX_AMOUNT, '[[:digit:]\.]+') where regexp_substr (BOX_AMOUNT, '[[:digit:]\.]+ (ml|gram|litre|m)') = BOX_AMOUNT
and CONCEPT_CODE_1 not in (select concept_code_1 from 
DR_pack_TO_CLIN_DR_BOX_full)
;
update Box_to_Drug
set amount_unit = regexp_replace (BOX_AMOUNT, '[[:digit:]\.]+ ')  where regexp_substr (BOX_AMOUNT, '[[:digit:]\.]+ (ml|gram|litre|m)') = BOX_AMOUNT
and CONCEPT_CODE_1 not in (select concept_code_1 from 
DR_pack_TO_CLIN_DR_BOX_full)
;
update Box_to_Drug
set Box_size = regexp_substr (BOX_AMOUNT, '^[[:digit:]\.]+')  where  regexp_substr (BOX_AMOUNT, '[[:digit:]\.]+ .*') = BOX_AMOUNT
and not regexp_like (BOX_AMOUNT, '(ml|gram|litre|m)')
and amount_value is null and amount_unit is null
and CONCEPT_CODE_1 not in (select concept_code_1 from 
DR_pack_TO_CLIN_DR_BOX_full)
;
update Box_to_Drug
set Box_size = regexp_substr (regexp_substr (BOX_AMOUNT, '[[:digit:]\.]+ x') , '[[:digit:]]+'),
 amount_value = regexp_substr (regexp_substr (BOX_AMOUNT, 'x [[:digit:]\.]+') , '[[:digit:]\.]+'),
 amount_unit = regexp_replace (regexp_substr  (BOX_AMOUNT, 'x [[:digit:]\.]+[[:alpha:]]+'), 'x [[:digit:]\.]+')
 where  regexp_like (BOX_AMOUNT, '[[:digit:]\.]+ x [[:digit:]\.]+[[:alpha:]]+') 
and amount_value is null and amount_unit is null and box_size is null
and CONCEPT_CODE_1 not in (select concept_code_1 from 
DR_pack_TO_CLIN_DR_BOX_full)
;
--need to comment
UPDATE BOX_TO_DRUG    SET AMOUNT_UNIT = 'ml',       AMOUNT_VALUE = 4,       BOX_SIZE = 56
WHERE CONCEPT_CODE_1 = '14791211000001106'
AND   CONCEPT_CODE_2 = '14791111000001100';
UPDATE BOX_TO_DRUG
   SET BOX_SIZE = 10
WHERE CONCEPT_CODE_1 = '31485711000001104'
AND   CONCEPT_CODE_2 = '31485411000001105';
UPDATE BOX_TO_DRUG
   SET BOX_SIZE = 60
WHERE CONCEPT_CODE_1 = '15522511000001104'
AND   CONCEPT_CODE_2 = '15522411000001103';
UPDATE BOX_TO_DRUG
   SET AMOUNT_UNIT = 'ml',
       AMOUNT_VALUE = 5,
       BOX_SIZE = 56
WHERE CONCEPT_CODE_1 = '22768811000001109'
AND   CONCEPT_CODE_2 = '22768711000001101';
UPDATE BOX_TO_DRUG
   SET BOX_SIZE = 50
WHERE CONCEPT_CODE_1 = '5987411000001103'
AND   CONCEPT_CODE_2 = '5987311000001105';
UPDATE BOX_TO_DRUG
   SET AMOUNT_UNIT = 'ml',
       AMOUNT_VALUE = 5,
       BOX_SIZE = 56
WHERE CONCEPT_CODE_1 = '4125211000001106'
AND   CONCEPT_CODE_2 = '4125111000001100';
UPDATE BOX_TO_DRUG
   SET BOX_SIZE = 7
WHERE CONCEPT_CODE_1 = '3954511000001106'
AND   CONCEPT_CODE_2 = '3954411000001107';
UPDATE BOX_TO_DRUG
   SET AMOUNT_UNIT = 'ml',
       AMOUNT_VALUE = 3,
       BOX_SIZE = 20
WHERE CONCEPT_CODE_1 = '5186211000001101'
AND   CONCEPT_CODE_2 = '5185911000001103';
UPDATE BOX_TO_DRUG
   SET AMOUNT_UNIT = 'ml',
       AMOUNT_VALUE = 3,
       BOX_SIZE = 2
WHERE CONCEPT_CODE_1 = '5186011000001106'
AND   CONCEPT_CODE_2 = '5185911000001103';

--special pattern for Drug Pack, need to add examples showing why I do this
update box_to_drug
set BOX_SIZE = regexp_substr( regexp_substr (BOX_AMOUNT, '\d+ x \('), '\d')
where concept_code_1
 in (select concept_code_1 from 
DR_pack_TO_CLIN_DR_BOX_full)
;
-- that's all for box_to_drug

-- Dose Forms
--full dose form table
drop table Drug_to_Dose_Form;
create table Drug_to_Dose_Form as 
select * from (
  select distinct bc.concept_code_1, bc.concept_name_1, cs.concept_code, cs.concept_name from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = 'Dose Form'
join Branded_to_clinical bc on concept_code_2 = a.concept_code
where a.concept_class_ID !='Dose Form'
union
select distinct a.concept_code, a.concept_name, cs.concept_code, cs.concept_name from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = 'Dose Form'
where a.concept_class_ID !='Dose Form'
)
;
--define forms only for CLinical Drugs
--duplicated active forms are choosen by length
drop table clin_dr_to_dose_form;
create table clin_dr_to_dose_form as 
select distinct a.CONCEPT_CODE_1,a.CONCEPT_NAME_1,a.CONCEPT_CODE,a.CONCEPT_NAME 
from (select CONCEPT_CODE_1,CONCEPT_NAME_1,CONCEPT_CODE,CONCEPT_NAME, length (concept_name ) as lngth from Drug_to_Dose_Form) a join 
(
select CONCEPT_CODE_1,CONCEPT_NAME_1, max(lngth) as lngth from (
select CONCEPT_CODE_1,CONCEPT_NAME_1,CONCEPT_CODE,CONCEPT_NAME, length (concept_name ) as lngth from Drug_to_Dose_Form)
group by CONCEPT_CODE_1,CONCEPT_NAME_1
) b on a.CONCEPT_CODE_1 = b.CONCEPT_CODE_1 and a.CONCEPT_NAME_1 = b.CONCEPT_NAME_1 and a.lngth = b.lngth
join drug_concept_stage c 
on a.concept_code_1 = c.concept_code and c.concept_class_id = 'Clinical Drug'
;
--several with the same length
DELETE
FROM CLIN_DR_TO_DOSE_FORM
WHERE CONCEPT_CODE_1 = '329850008'
AND   CONCEPT_CODE = '385061003';
DELETE
FROM CLIN_DR_TO_DOSE_FORM
WHERE CONCEPT_CODE_1 = '329587009'
AND   CONCEPT_CODE = '385061003';
DELETE
FROM CLIN_DR_TO_DOSE_FORM
WHERE CONCEPT_CODE_1 = '329586000'
AND   CONCEPT_CODE = '385061003';
;
--pack components with omop codes
--will work, lets remain these OMOP codes as they are
--!!! define how these drug components get there 
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP21',  'Paracetamol 500mg / Phenylephrine 6.1mg / Caffeine 25mg capsules',  '385049006',  'Capsule');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP22',  'Buclizine hydrochloride / Codeine / Paracetamol tablets',  '385055001',  'Tablet');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP23',  'Pholcodine 5mg / Pseudoephedrine 30mg / Paracetamol 500mg capsules',  '385049006',  'Capsule');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP24',  'Pholcodine 5mg / Pseudoephedrine 30mg / Paracetamol 500mg /  Diphenhydramine 12.5mg capsules',  '385049006',  'Capsule');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP25',  'Estriol 1mg / Norethisterone acetate 1mg tablets',  '385055001',  'Tablet');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP26',  'Calcium chloride / Thrombin solution',  '385219001',  'Solution for injection');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP27',  'Pyridoxine 50mg/5ml / Thiamine 250mg/5ml / Riboflavin 4mg/5ml oral solution',  '385023001',  'Oral solution');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP28',  'Codeine / Paracetamol tablets',  '385055001',  'Tablet');
INSERT INTO CLIN_DR_TO_DOSE_FORM(  CONCEPT_CODE_1,  CONCEPT_NAME_1,  CONCEPT_CODE,  CONCEPT_NAME)VALUES(  'OMOP29',  'Aprotinin / Fibrinogen / Factor XIII solution',  '385219001',  'Solution for injection');
;   
--define non-drugs, clinical part of 
drop table clnical_non_drug;
create table clnical_non_drug as
select * from drug_concept_stage where (concept_code not in (select concept_code_1 from clin_dr_to_dose_form where concept_code_1 is not null)  and invalid_reason is  null
or regexp_like (concept_name, 'peritoneal dialysis|dressing|burger|needl|soap|biscuits|wipes|cake|milk|dessert|juice|bath oil|gluten|Low protein|cannula|swabs|bandage|Artificial saliva', 'i')
or DOMAIN_ID ='Device'
) and concept_class_id = 'Clinical Drug'
;
--ADD MANUALLY DEFINED NON DRUG CONCEPTS
insert into clnical_non_drug (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON,INSERT_ID, SOURCE_CONCEPT_CLASS_ID)
select distinct  a.* from drug_concept_stage a 
join (select cast (drug_code as varchar (250)) as drug_code  from non_drug --!!!MANUAL TABLE 
 union select concept_code from non_drug_2 --!!!MANUAL TABLE
 ) n
 on n.drug_code= a.concept_code
 ;
 insert into clnical_non_drug  (CONCEPT_ID,CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON,INSERT_ID, SOURCE_CONCEPT_CLASS_ID)
 select * from drug_concept_stage where concept_code= '5015311000001107'
  ;
 DELETE FROM clnical_non_drug WHERE CONCEPT_CODE IN 
 (SELECT DRUG_CONCEPT_CODE FROM nondrug_with_ingr --!!! MANUAL TABLE 
 )
 ;
-- add manual table "aut_form_mapped_noRx" excluding non-drugs
drop table CLIN_DR_TO_DOSE_form_2;
create table CLIN_DR_TO_DOSE_form_2 as 
select * from (
select cast ( CONCEPT_CODE_1 as varchar (250)) as concept_code_1 ,CONCEPT_NAME_1,CONCEPT_CODE_2,CONCEPT_NAME_2 from aut_form_mapped_noRx --manaul forms for existing drugs; --table with manualy found forms !!!
union
select CONCEPT_CODE_1,CONCEPT_NAME_1,CONCEPT_CODE,CONCEPT_NAME from CLIN_DR_TO_DOSE_FORM --automated forms for existing drugs+ manual forms for newly created drugs
)
where concept_code_1 not in (select concept_code from clnical_non_drug)
;
-- add Boxes
drop table CLIN_DR_TO_DOSE_form_3;
create table CLIN_DR_TO_DOSE_form_3 as 
select distinct a.concept_code_1, a.concept_name_1,  b.concept_code_2, b.concept_name_2 from Box_to_Drug a 
join CLIN_DR_TO_DOSE_form_2 b on a.concept_code_2  = b.concept_code_1
union 
select * from CLIN_DR_TO_DOSE_form_2
;
--add Branded Drugs
drop table DR_TO_DOSE_form_full ;
create table DR_TO_DOSE_form_full as 
--branded drug
select distinct a.concept_code_1, a.concept_name_1,  b.concept_code_2, b.concept_name_2
 from Branded_to_clinical a 
join CLIN_DR_TO_DOSE_form_3 b on a.concept_code_2  = b.concept_code_1
union 
select * from CLIN_DR_TO_DOSE_form_3
;
--remove 'Not applicable' forms
delete from DR_TO_DOSE_form_full where concept_code_2 = '3097611000001100'
;
--???
--Manufacturer
--just take it from names long executing part, don't rerun next time
/*
drop table Drug_to_manufact_2 ;
  create table Drug_to_manufact_2 as
 select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, a.concept_class_id as concept_class_id_1, 
 b.concept_code as concept_code_2, b.concept_name as concept_name_2, b.invalid_reason 
 from drug_concept_stage a 
 join drug_concept_stage b on a.concept_name like  '%('||b.concept_name||')%'
 where b.concept_class_id ='Manufacturer'
 and a.concept_class_id like 'Branded Drug%' and a.concept_code not in (select concept_code from non_drug_full)
 ;
 */
 --CLinical Drug to ingredients using existing relationship, later this relationship will be updated with ds_stage table
 drop table Clinical_to_Ingred;
 create table Clinical_to_Ingred as
select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, cs.concept_code as concept_code_2, cs.concept_name as concept_name_2, cs.INSERT_ID 
from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'  and a.concept_class_id like '%Clinical Drug%'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = 'Ingredient'
where r.relationship_id not in ('Has excipient', 'Has basis str subst')
;
--modify relationships between drugs and ingredients using existing relationships and reviewed path from non-standard to standard ingr
drop table Clinical_to_Ingred_tmp ;
create table Clinical_to_Ingred_tmp as 
select distinct a.CONCEPT_CODE_1, a.CONCEPT_NAME_1, coalesce (b.CONCEPT_CODE_2, a.CONCEPT_CODE_2) as CONCEPT_CODE_2  , coalesce (b.CONCEPT_NAME_2, a.CONCEPT_NAME_2) as CONCEPT_NAME_2, coalesce (b.INSERT_ID_2, a.INSERT_ID) as INSERT_ID_2
from Clinical_to_Ingred a 
join ingred_to_ingred_FINAL_BY_Lena --!!!
 b on a.concept_code_2 = b.CONCEPT_CODE_1
;
--another variant with narrower definition - use only  r.relationship_id  in ('Is a')
drop table Clinical_to_Ingred_Is_a;
create table Clinical_to_Ingred_Is_a as 
select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1,r.relationship_id,  cs.concept_code as concept_code_2, cs.concept_name as concept_name_2, cs.INSERT_ID 
from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'  and a.concept_class_id like '%Clinical Drug%'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = 'Ingredient'
where r.relationship_id  in ('Is a')
;
drop table Clinical_to_Ingred_Is_a_tmp;
create table Clinical_to_Ingred_Is_a_tmp as 
select distinct a.CONCEPT_CODE_1, a.CONCEPT_NAME_1, coalesce (b.CONCEPT_CODE_2, a.CONCEPT_CODE_2) as CONCEPT_CODE_2  , coalesce (b.CONCEPT_NAME_2, a.CONCEPT_NAME_2) as CONCEPT_NAME_2, coalesce (b.INSERT_ID_2, a.INSERT_ID) as INSERT_ID_2
from Clinical_to_Ingred_Is_a a 
join ingred_to_ingred_FINAL_BY_Lena b on a.concept_code_2 = b.CONCEPT_CODE_1
;
--prepare table for parsing if drug has several ingredients
drop table drug_concept_stage_tmp;
create table drug_concept_stage_tmp as (Select CONCEPT_ID, case when regexp_like (concept_name, ' / \d') then regexp_replace (concept_name, ' / ', '/') else replace (CONCEPT_NAME, ' / ', '!') end as concept_name_chgd,
CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON,INSERT_ID from drug_concept_stage)
;
--parsing dosage and components taking from concept_name
drop table drug_concept_stage_tmp_0; 
create table drug_concept_stage_tmp_0 as 
select regexp_substr 
(a.drug_comp, 
'[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm|million units| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres|unit dose|drop)*') as dosage
, drug_comp,  a.concept_name, a.concept_code from (
select distinct
trim(regexp_substr(t.concept_name_chgd, '[^!]+', 1, levels.column_value))  as drug_comp , concept_name, concept_code 
from drug_concept_stage_tmp t,
table(cast(multiset(select level from dual connect by  level <= length (regexp_replace(t.concept_name_chgd, '[^!]+'))  + 1) as sys.OdciNumberList)) levels where concept_class_id ='Clinical Drug') a
;
update drug_concept_stage_tmp_0 set dosage = regexp_replace (dosage, 'molar', 'mmol/ml');
update drug_concept_stage_tmp_0 set dosage = regexp_replace (dosage, '/dose', '');
update drug_concept_stage_tmp_0 set dosage = regexp_replace (dosage, '/$', '') where regexp_like (dosage, '/$');
--select * from drug_concept_stage_tmp_0 where concept_code = 12296111000001106
--define number of components and ingredients
alter  table drug_concept_stage_tmp_0 add ingr_cnt int
;
update drug_concept_stage_tmp_0 b set ingr_cnt = ( select cnt from (
select concept_code, count (1) as cnt  from drug_concept_stage_tmp_0 group by concept_code) a where a.concept_code = b.concept_code);

alter  table Clinical_to_Ingred_tmp add ingr_cnt int
;
update Clinical_to_Ingred_tmp b set ingr_cnt = ( select cnt from (
select concept_code_1, count (1) as cnt  from Clinical_to_Ingred_tmp group by concept_code_1) a where a.concept_code_1 = b.concept_code_1)
;
;
--easiest part -when drug has only one ingredient
drop table clin_dr_to_ingr_one;
create table clin_dr_to_ingr_one as 
select distinct a.*, concept_code_2 as ingredient_concept_code, concept_name_2 as ingredient_concept_name, insert_id_2 from drug_concept_stage_tmp_0 a join Clinical_to_Ingred_tmp  b on 
 a.concept_code = b.concept_code_1
where b.concept_code_1 in 
(
select concept_code_1 from Clinical_to_Ingred_tmp group by concept_code_1 having count (1) = 1)
and a.ingr_cnt  = 1 
;
--count is equal and drug_component contains ingredient , exclude also concepts from previous table
--recheck in future about complicated dosages
drop table  clin_dr_to_ingr_two;
create table  clin_dr_to_ingr_two as 
select distinct a.*, concept_code_2 as ingredient_concept_code, concept_name_2 as ingredient_concept_name, insert_id_2 
from drug_concept_stage_tmp_0 a 
join Clinical_to_Ingred_tmp  b on 
 a.concept_code = b.concept_code_1 
 and lower (a.drug_comp) like lower (  '%'||b.concept_name_2||'%')  and a.ingr_cnt = b.ingr_cnt--this condition also could help with excessive ingredients number
 join 
 ( 
 select concept_code, count (1) as cnt from (
 select distinct a.*, concept_code_2 as ingredient_concept_code, concept_name_2 as ingredient_concept_name, insert_id_2 , b.ingr_cnt
from drug_concept_stage_tmp_0 a 
join Clinical_to_Ingred_tmp  b on 
 a.concept_code = b.concept_code_1 
 and lower (a.drug_comp) like lower (  '%'||b.concept_name_2||'%')  and a.ingr_cnt = b.ingr_cnt
) group by concept_code
 ) x on x.cnt = a.ingr_cnt and x.concept_code = a.concept_code
where b.concept_code_1 not in 
(
select CONCEPT_CODE from clin_dr_to_ingr_one)
;
--Clinical_to_Ingred_Is_a_tmp --another way by using narrower table for drug ingredients
drop table clin_dr_to_ingr_one_part_2;
create table clin_dr_to_ingr_one_part_2 as
select distinct a.concept_code, a.concept_name, i.concept_code_2, i.concept_name_2, a.dosage from drug_concept_stage_tmp_0 a
join drug_concept_stage z on a.concept_code = z.concept_code
join Clinical_to_Ingred_tmp b on a.concept_code = b.CONCEPT_CODE_1
join Clinical_to_Ingred_Is_a_tmp i on a.concept_code = i.concept_code_1 
JOIN 
(
SELECT concept_code FROM (
select distinct a.concept_code, a.concept_name, i.concept_code_2, i.concept_name_2, a.dosage from drug_concept_stage_tmp_0 a
join drug_concept_stage z on a.concept_code = z.concept_code
join Clinical_to_Ingred_tmp b on a.concept_code = b.CONCEPT_CODE_1
join Clinical_to_Ingred_Is_a_tmp i on a.concept_code = i.concept_code_1 
 where a.concept_code not in (select concept_code from clin_dr_to_ingr_two union select concept_code from clin_dr_to_ingr_one union select concept_code from clnical_non_drug) and z.concept_class_id = 'Clinical Drug'
and z.invalid_reason is null
and a.INGR_CNT =1 
)
GROUP BY concept_code HAVING COUNT (1) =1
) X ON X.concept_code = A.concept_code
 where a.concept_code not in (select concept_code from clin_dr_to_ingr_two union select concept_code from clin_dr_to_ingr_one union select concept_code from clnical_non_drug) and z.concept_class_id = 'Clinical Drug'
and z.invalid_reason is null
and a.INGR_CNT =1
;
drop table ds_all_tmp;
create table ds_all_tmp as 
select DOSAGE,DRUG_COMP,CONCEPT_NAME,CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,INGREDIENT_CONCEPT_NAME , cast ('' as varchar (200)) as volume  from clin_dr_to_ingr_one where concept_code not in (select concept_code from ds_by_lena_1)
union 
select DOSAGE,DRUG_COMP,CONCEPT_NAME,CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,INGREDIENT_CONCEPT_NAME, '' from clin_dr_to_ingr_two where concept_code not in (select concept_code from ds_by_lena_1)
union
select DOSAGE, '',CONCEPT_NAME,CONCEPT_CODE, CONCEPT_CODE_2,CONCEPT_NAME_2 , ''  from clin_dr_to_ingr_one_part_2 where concept_code not in (select concept_code from ds_by_lena_1)
union 
--ds_by_lena_1 table is defined analysing the things left from the above
select DOSAGE, '',CONCEPT_NAME,CONCEPT_CODE, CONCEPT_CODE_2,CONCEPT_NAME_2 , volume  from ds_by_lena_1 --!!!
union 
--ds_by_lena_1 table is defined analysing the things left from the above
select  DOSAGE, '',CONCEPT_NAME,CONCEPT_CODE, CONCEPT_CODE_2,CONCEPT_NAME_2 , '' from clin_dr_to_ingr_3    --consider as manualy created table - we lost update query -- !!!
union
-- a lot of manual work, need to write definition and delta later
select DOSAGE, '',CONCEPT_NAME, cast (CONCEPT_CODE as varchar (250)), CONCEPT_CODE_2,CONCEPT_NAME_2 , ''  from drug_to_ingr --!!! -manual table, review of part of ds_stage we can't make fully automatically
  where CONCEPT_CODE_2 is not null
union 
-- lost ingredients
select '','',drug_name, DRUG_CODE, INGR_CODE,INGR_NAME, ''  from  lost_ingr_to_rx_with_OMOP --!!!
;
DELETE
FROM DS_ALL_TMP
WHERE DOSAGE = '22micrograms/2.2ml'
AND   CONCEPT_CODE = '21142411000001108'
AND   INGREDIENT_CONCEPT_CODE = '410851000';
DELETE
FROM DS_ALL_TMP
WHERE DOSAGE = '88mg/2.2ml'
AND   CONCEPT_CODE = '21142411000001108'
AND   INGREDIENT_CONCEPT_CODE = '387362001';
;
UPDATE ds_all_tmp
   SET dosage = '10mg/1ml'
WHERE concept_code = '11360011000001101'
AND   ingredient_concept_code = 'OMOP28664'; 
--select * from lost_ingr_to_rx_with_OMOP
;
--select * from ds_all_tmp where INGREDIENT_CONCEPT_CODE is null;
--select * from drug_to_ingr a  join devv5.concept c on a.concept_code_2 = cast (c.concept_id  as varchar (250)) and c.concept_class_id ='Ingredient' and vocabulary_id = 'RxNorm'
;
update ds_all_tmp set dosage = replace (dosage, '"') 
;
update ds_all_tmp set dosage = trim (dosage) 
;
drop table ds_all;
create table ds_all as 
select 
case when regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units|unit dose|drop)') = dosage 
and not regexp_like (dosage, '%') 
then regexp_replace (regexp_substr (dosage, '[[:digit:]\,\.]+'), ',')
else  null end 
as amount_value,

case when regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units|unit dose|drop)') = dosage 
and not regexp_like (dosage, '%') 
then  regexp_replace  (dosage, '[[:digit:]\,\.]+') 
else  null end
as amount_unit,

case when 
regexp_substr (dosage,
 '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres|unit dose|drop)') = dosage
or regexp_like (dosage, '%') 
then regexp_replace (regexp_substr (dosage, '^[[:digit:]\,\.]+') , ',')
else  null end
as numerator_value,

case when regexp_substr (dosage, 
'[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres|unit dose|drop)') = dosage
or regexp_like (dosage, '%') 
then regexp_substr (dosage, 'mg|%|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres', 1,1) 
else  null end
as numerator_unit,

case when 
(
regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)|h|square cm|microlitres|unit dose|drop)') = dosage
or regexp_like (dosage, '%')
)
and volume is null
then regexp_replace( regexp_replace (regexp_substr (dosage, '/[[:digit:]\,\.]+'), ','), '/')
when  volume is not  null then  regexp_substr (volume, '[[:digit:]\,\.]+')
else  null end
as denominator_value,

case when 
(regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|microlitres|hour(s)*|h|square cm|unit dose|drop)') = dosage
or regexp_like (dosage, '%')
) and volume is null
then regexp_substr (dosage, '(g|dose|ml|mg|ampoule|litre|hour(s)*|h*|square cm|microlitres|unit dose|drop)$')
when volume is not  null then  regexp_replace (volume, '[[:digit:]\,\.]+')
else null end
as denominator_unit,
concept_code, concept_name, DOSAGE, DRUG_COMP, INGREDIENT_CONCEPT_CODE, INGREDIENT_CONCEPT_NAME
from ds_all_tmp 
;
-- update denominator with existing value for concepts having empty and non-emty denominator value/unit
update ds_all a set (a.DENOMINATOR_VALUE, a.DENOMINATOR_unit )= 
(select b.DENOMINATOR_VALUE, b.DENOMINATOR_unit  from 
 ds_all b where a.CONCEPT_CODE = b.CONCEPT_CODE 
 and a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null )
 where exists 
 (select 1 from 
 ds_all b where a.CONCEPT_CODE = b.CONCEPT_CODE 
 and a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null )
--select * from ds_all where coalesce (AMOUNT_VALUE, DENOMINATOR_VALUE, NUMERATOR_VALUE) is null
;
--need to comment
update ds_all set amount_value = null, amount_unit = null where regexp_like (concept_name, '[[:digit:]\.]+(litre|ml)') and not regexp_like (concept_name, '/[[:digit:]\.]+(litre|ml)') and amount_value is not null and AMOUNT_UNIT in ('litre', 'ml');
-- need to commeny
update ds_all set denominator_value = regexp_substr (regexp_substr(concept_name, ' [[:digit:]\.]+(litre(s?)|ml)') , '[[:digit:]\.]+'), denominator_unit = regexp_substr (regexp_substr(concept_name, ' [[:digit:]\.]+(litre(s?)|ml)') , '(litre(s?)|ml)')
where regexp_like (concept_name, '\d+(litre(s?)|ml)') and not regexp_like (concept_name, '/[[:digit:]\.]+(litre(s?)|ml)')
and denominator_value is  null
;
--recalculate ds_stage accordong to fake denominators
update ds_all a
set numerator_value =numerator_value/denominator_value, denominator_value = 
 '' 
where concept_code in (
select concept_code_2 from  
 Box_to_Drug b where b.AMOUNT_VALUE is not null)
and denominator_value is not null 
and numerator_unit!='%'
;
--!!!
--Noradrenaline (base) 320micrograms/ml solution for infusion 950ml bottles for such concepts we need to keep denominator_value as true value and 
update ds_all a
set numerator_value =numerator_value*denominator_value
where concept_code in (select concept_code from drug_concept_stage where regexp_like (concept_name , '[[:digit:]\.]+.*/ml.*[[:digit:]\.]+ml'))
and numerator_value is not null and denominator_value is not null and numerator_value !='%'
;
-- add Drug Boxes as mix of Boxes and Quant Drugs
--select * from ds_all where not regexp_like (numerator_VALUE, '[[:digit:]/.]') 
drop table ds_all_dr_box;
create table ds_all_dr_box as 
select distinct 
a.concept_code_1, b.INGREDIENT_CONCEPT_CODE,null as AMOUNT_VALUE,null as AMOUNT_UNIT ,
case when b.AMOUNT_VALUE is not null then b.AMOUNT_VALUE*a.amount_value 
when b.AMOUNT_VALUE is null and numerator_unit !='%' then b.numerator_VALUE*a.amount_value
when  b.AMOUNT_VALUE is null and numerator_unit ='%' then cast (b.numerator_VALUE as float)
else null end as NUMERATOR_VALUE,

case when b.amount_value is not null then b.amount_unit
else b.numerator_unit end as numerator_unit,

a.AMOUNT_VALUE as DENOMINATOR_VALUE,
a.AMOUNT_UNIT as denominator_unit, 
a.BOX_SIZE as BOX_SIZE  

from Box_to_Drug a 
join ds_all b on a.concept_code_2 = b.concept_code
where a.AMOUNT_VALUE is not null

union 

select distinct 
a.concept_code_1, b.INGREDIENT_CONCEPT_CODE, cast (b.AMOUNT_VALUE as varchar(250)) as AMOUNT_VALUE, b.AMOUNT_UNIT ,
cast (b.numerator_value as float) as numerator_value, b.numerator_unit,
cast (b.DENOMINATOR_VALUE as float) as DENOMINATOR_VALUE,
b.denominator_unit,   
a.BOX_SIZE as BOX_SIZE  

from Box_to_Drug a 
join ds_all b on a.concept_code_2 = b.concept_code
where a.AMOUNT_VALUE is null
--and b.amount_value is not null and b.amount_unit = '%'
;
--for all the clinical drugs (Boxes and Quant Drugs)
drop table ds_all_cl_dr;
create table ds_all_cl_dr as 
select CONCEPT_CODE_1,INGREDIENT_CONCEPT_CODE,cast (AMOUNT_VALUE as float) as AMOUNT_VALUE,AMOUNT_UNIT,cast (NUMERATOR_VALUE as float) as NUMERATOR_VALUE,NUMERATOR_UNIT,
 cast (DENOMINATOR_VALUE as float) as DENOMINATOR_VALUE,DENOMINATOR_UNIT,cast (BOX_SIZE as int) as BOX_SIZE
 from ds_all_dr_box
union 
select CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,cast (AMOUNT_VALUE as float) as AMOUNT_VALUE,AMOUNT_UNIT,cast (NUMERATOR_VALUE as float) as NUMERATOR_VALUE,NUMERATOR_UNIT,
 cast (DENOMINATOR_VALUE as float) as DENOMINATOR_VALUE,DENOMINATOR_UNIT, cast ('' as int ) as BOX_SIZE  from ds_all
  ;
truncate table DS_STAGE
;
insert into DS_STAGE (DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT, BOX_SIZE)
--Clinical Drugs
select * from ds_all_cl_dr
union 
--Branded Drugs
 select distinct a.CONCEPT_CODE_1,INGREDIENT_CONCEPT_CODE,AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT,BOX_SIZE from Branded_to_clinical a join ds_all_cl_dr b on 
 a.CONCEPT_CODE_2 = b.CONCEPT_CODE_1
;
--manually created table PACK_DRUG_TO_CODE_2_2
drop table ds_omop;
create table ds_omop as(
select distinct DRUG_CODE,DRUG_NEW_NAME,coalesce (CONCEPT_CODE_2, concept_code_1) as CONCEPT_CODE_2 , coalesce (CONCEPT_name_2, concept_name_1) as CONCEPT_name_2
 from PACK_DRUG_TO_CODE_2_2 --!!! packs determined manually 
 
 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' 
) ;
update ds_omop
set DRUG_NEW_NAME = regexp_replace (DRUG_NEW_NAME, ' / ', '!')
;
drop table ds_omop_0; 
create table ds_omop_0 as 
select regexp_substr (a.drug_comp, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol|million units)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)*') as dosage
, drug_comp,  a.DRUG_NEW_NAME, a.DRUG_CODE, a.CONCEPT_CODE_2, a.CONCEPT_name_2  from (
select distinct
trim(regexp_substr(t.DRUG_NEW_NAME, '[^!]+', 1, levels.column_value))  as drug_comp , DRUG_NEW_NAME, DRUG_CODE , CONCEPT_CODE_2, CONCEPT_name_2  
from ds_omop t,
table(cast(multiset(select level from dual connect by  level <= length (regexp_replace(t.DRUG_NEW_NAME, '[^!]+'))  + 1) as sys.OdciNumberList)) levels ) a
;
update ds_omop
set DRUG_NEW_NAME = regexp_replace (DRUG_NEW_NAME, '!', ' / ')
;

insert into ds_stage (DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT)
select DRUG_CODE, CONCEPT_CODE_2,AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT from (

select 
case when regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)') = dosage 
and not regexp_like (dosage, '%') 
then regexp_replace (regexp_substr (dosage, '[[:digit:]\,\.]+'), ',')
else  null end 
as amount_value,

case when regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)') = dosage 
and not regexp_like (dosage, '%') 
then  regexp_replace  (dosage, '[[:digit:]\,\.]+') 
else  null end
as amount_unit,

case when 
regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)') = dosage
or regexp_like (dosage, '%') 
then regexp_replace (regexp_substr (dosage, '^[[:digit:]\,\.]+') , ',')
else  null end
as numerator_value,

case when regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)') = dosage
or regexp_like (dosage, '%') 
then regexp_substr (dosage, 'mg|%|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres', 1,1) 
else  null end
as numerator_unit,

case when 
(
regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres*)') = dosage
or regexp_like (dosage, '%')
)
and volume is null
then regexp_replace( regexp_replace (regexp_substr (dosage, '/[[:digit:]\,\.]+'), ','), '/')
when  volume is not  null then  regexp_substr (volume, '[[:digit:]\,\.]+')
else  null end
as denominator_value,

case when 
(regexp_substr (dosage, '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s)*|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|MBq|molar|micromol|microlitres|million units)/[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|microlitres|hour(s)*|h*|square cm)') = dosage
or regexp_like (dosage, '%')
) and volume is null
then regexp_substr (dosage, '(g|dose|ml|mg|ampoule|litre|hour(s)*|h*|square cm|microlitres)$')
when volume is not  null then  regexp_replace (volume, '[[:digit:]\,\.]+')
else null end
as denominator_unit,
drug_code,  DOSAGE, concept_code_2 

from 
 (
select DRUG_CODE, CONCEPT_CODE_2, DOSAGE, '' as volume from ds_omop_0 where DRUG_COMP  like '%'||CONCEPT_NAME_2||'%')
)
;
-- update denominator with existing value for concepts having empty and non-emty denominator value/unit
update ds_stage a set (a.DENOMINATOR_VALUE, a.DENOMINATOR_unit )= 
(select b.DENOMINATOR_VALUE, b.DENOMINATOR_unit  from 
 ds_stage b where a.drug_concept_code = b.drug_concept_code 
 and a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null )
 where exists 
 (select 1 from 
 ds_stage b where a.drug_concept_code = b.drug_concept_code 
 and a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null )
 ;
 --need to comment with example
 update ds_stage set ingredient_concept_code = 'OMOP28664' where ingredient_concept_code =  '798336'
;
update ds_stage set ingredient_concept_code = 'OMOP28671' where ingredient_concept_code =  '902251'
;
delete from ds_stage where coalesce (amount_unit, numerator_unit) is null and ingredient_concept_code = '3588811000001104'
;
select * from drug_concept_stage where concept_code = '21203111000001102'
;
--pay an attention! we put here everything including non-drugs
;
--add branded Drugs to non_drug
drop table branded_non_drug;
create table branded_non_drug as 
select distinct a.* from drug_concept_stage a  join Branded_to_clinical b on a.concept_code = b.concept_code_1
join clnical_non_drug nd on b.concept_code_2 = nd.concept_code
;
--ADD another classes going throught the relationships
drop table cl_br_non_drug;
create table cl_br_non_drug as 
select * from branded_non_drug
union
select * from clnical_non_drug
;
drop table box_non_drug;
create table box_non_drug as 
select distinct a.* from drug_concept_stage a  
join Box_to_Drug b on a.concept_code = b.concept_code_1 
join cl_br_non_drug nd on b.concept_code_2 = nd.concept_code
;
drop table non_drug_full;
create table non_drug_full as 
select * from box_non_drug
union 
select * from cl_br_non_drug
;
  --Box fixing including existing non-drug ???
delete  from DR_pack_TO_CLIN_DR_BOX_full where CONCEPT_CODE_1 in (
select CONCEPT_CODE_1  from DR_pack_TO_CLIN_DR_BOX_full where CONCEPT_CODE_1 in (select concept_code from non_drug_full) and  CONCEPT_CODE_2 in (select concept_code from non_drug_full)
)
;
--when drug box has one of the component as drug then it's drug
delete from non_drug_full where concept_code in (select concept_code_1 from DR_pack_TO_CLIN_DR_BOX_full where CONCEPT_CODE_1 in (select concept_code from non_drug_full) AND CONCEPT_CODE NOT IN (
'17631511000001101', '7850411000001102', '7849511000001109'))
;
 DELETE FROM non_drug_full WHERE CONCEPT_CODE IN 
 (SELECT DRUG_CONCEPT_CODE FROM nondrug_with_ingr)
;

--manual packs delete
DELETE FROM DR_pack_TO_CLIN_DR_BOX_full WHERE CONCEPT_CODE_1 
IN (
'17631511000001101', '7850411000001102', '7849511000001109')
;
--since all Packs info is OK, we need to add PACK_CONTENT table as one of it's done already
drop table pack_content_1;
create table pack_content_1 as 
select  a.concept_code_1 as pack_concept_code	,a.concept_name_1 as pack_name, coalesce (b.concept_Code_2, a.concept_code_2) as drug_concept_code,
coalesce(b.concept_name_2, a.concept_name_2) as drug_concept_name,coalesce ( BOX_SIZE, 1) as amount
from  dr_pack_to_Clin_dr_box_full a left join box_to_drug b on a.CONCEPT_CODE_2 = b.CONCEPT_CODE_1 and BOX_SIZE is not null

;
--insert manual packs
insert into pack_content_1 (PACK_CONCEPT_CODE,PACK_NAME,DRUG_CONCEPT_CODE,DRUG_CONCEPT_NAME,AMOUNT)
select PACK_CODE,PACK_NAME,DRUG_CODE,DRUG_NEW_NAME,AMOUNT from PACK_DRUG_TO_CODE_2_2 --!!!
union
select PACK_CODE,PACK_NAME,DRUG_CODE,DRUG_NAME,'' from PACK_DRUG_TO_CODE_1--!!!--table with pack components joined with dmd by pack component name;
;
insert into pack_content_1 (PACK_CONCEPT_CODE,PACK_NAME,DRUG_CONCEPT_CODE,DRUG_CONCEPT_NAME,AMOUNT)
select distinct b.CONCEPT_CODE_1, b.CONCEPT_NAME_1, DRUG_CONCEPT_CODE,DRUG_CONCEPT_NAME,AMOUNT 
from pack_content_1 a join branded_to_clinical b on a.PACK_CONCEPT_CODE = b.CONCEPT_CODE_2
where b.CONCEPT_CODE_1 not in (select PACK_CONCEPT_CODE from pack_content_1)
;
insert into pack_content_1 (PACK_CONCEPT_CODE,PACK_NAME,DRUG_CONCEPT_CODE,DRUG_CONCEPT_NAME,AMOUNT)
select distinct b.CONCEPT_CODE_1, b.CONCEPT_NAME_1, DRUG_CONCEPT_CODE,DRUG_CONCEPT_NAME,AMOUNT 
from pack_content_1 a join box_to_drug b on a.PACK_CONCEPT_CODE = b.CONCEPT_CODE_2
where b.CONCEPT_CODE_1 not in (select PACK_CONCEPT_CODE from pack_content_1)
;
truncate table PACK_CONTENT;
insert into PACK_CONTENT (PACK_CONCEPT_CODE,DRUG_CONCEPT_CODE,AMOUNT)
select PACK_CONCEPT_CODE,DRUG_CONCEPT_CODE,AMOUNT from pack_content_1
;
CREATE TABLE PACK_CONTENT_TMP AS 
SELECT DISTINCT * FROM PACK_CONTENT
;
--delete duplicates
DROP TABLE PACK_CONTENT
;
CREATE TABLE PACK_CONTENT AS (SELECT * FROM PACK_CONTENT_TMP)
;
DROP TABLE PACK_CONTENT_TMP
;
-- packs are not allowed in ds_stage
delete from ds_stage where drug_concept_code in (select pack_concept_code from pack_content)
;
--non_drugs also are not allowed in ds_stage
delete from ds_stage where drug_concept_code in (select concept_code from non_drug_full ) 
;
 --deprecated to active
 --use SNOMED relationship
 drop table deprec_to_active; -- contains Ingredient, Clinical Drug, Dose Form classes
create table deprec_to_active as 
select  distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, a.concept_class_id, cs.concept_code as concept_code_2, cs.concept_name as concept_name_2
 from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = a.concept_class_id
and a.invalid_reason is not null and cs.invalid_reason is null 
and relationship_id in ('Concept same_as to', 'Concept poss_eq to', 'Concept replaced by', 'Maps to' )
--delete from Packs deprecated concepts
;
--Brand NAMES - some clinical Drugs also should considered as Branded (Generic and Co-%
--need to review
drop table branded_drug_to_brand_name;
create table branded_drug_to_brand_name as 
select distinct concept_code, concept_name,  
regexp_replace (regexp_replace ( regexp_replace(concept_name, '\s\d.*'), ' \(.*'), 
 '(\s(tablet(s?)|cream|capsule(s?)|gel|powder|ointment|suppositories|emollient|liquid|sachets.*|transdermal patches|infusion|solution for.*|lotion|oral solution|chewable.*|effervescent.*irrigation.*|caplets.*|oral drops|oral powder|soluble tablets sugar free|lozenges)$)') 
as  BRAND_NAME from drug_concept_stage
where (concept_class_id = 'Branded Drug' and  concept_name not like 'Generic %')
union
select concept_code, concept_name,  regexp_replace(concept_name, '\s.*') as  BRAND_NAME from drug_concept_stage
where concept_class_id = 'Clinical Drug' and   concept_name like 'Co-%'
union select concept_code, concept_name,
regexp_replace ( regexp_replace ( regexp_replace(concept_name, 'Generic '), '\s\d.*') ,
 '(\s(tablet(s?)|cream|capsule(s?)|gel|powder|ointment|suppositories|emollient|liquid|sachets.*|transdermal patches|infusion|solution for.*|lotion|oral solution|chewable.*|effervescent.*irrigation.*|caplets.*|oral drops|oral powder|soluble tablets sugar free|lozenges)$)')
  as BRAND_NAME
from drug_concept_stage where concept_name like 'Generic %'
;
delete from branded_drug_to_brand_name a where exists (select 1 from
drug_concept_stage b where lower (a.BRAND_NAME) = lower (b.concept_name) 
 and b.concept_class_id = 'Ingredient' and concept_name not like 'Co-%')
 ;
  delete  from branded_drug_to_brand_name a where exists (select 1 from
non_drug_full b where b.concept_code = a.concept_code)
;
--Anna's update
delete  branded_drug_to_brand_name where BRAND_NAME in 
('Zinc compound paste'	,'Yellow soft paraffin solid'	,'Wild cherry syrup'	,'White soft paraffin solid	','White liniment'	,'Vitamins A and D capsules BPC'	,'Vitamins'	,'Vitamin K2'	,'Vitamin E'	,'Vitamin D3'	,
'Vitamin C','Tri-iodothyronine'	,'Trichloroacetic acid and Salicylic acid paste'	,'Tea Tree and Witch Hazel'	,'Surgical spirit'	,'Starch maize','St. James Balm','Squill opiate linctus paediatric'	,
'Sodium DL-3-hydroxybutyrate'	,'Snake antivenin powder and solvent for'	,'SGK Glucosamine'	,'Sepia officinalis'	,'Ringer lactate'	,'Rhus toxicodendron'	,'Recombinant human hyaluronidase'	,'Pulsatilla pratensis'	,'Podophyllum'	,
'Phenylalanine'	,'Passiflora incarnata'	,'Oxygen cylinders'	,'Oily phenol'	,'Levothyroxine sodium'	,'Ignatia amara'	,'Glucosamine Chondroitin Complex'	,'Gentamycin Augensalbe'	,'Gentamicin Intrathecal'	,'Gelsemium sempervirens'	,
'Euphrasia officinalis'	,'Drosera rotundifolia','Dried Factor VIII Fraction type'	,'Carbostesin-adrenaline'	,'Calcium and Ergocalciferol'	,'Black currant syrup'	,'Avoca wart and verruca treatment set'	,'Avena sativa comp drops'	,
'Arsenicum album'	,'Arginine hydrochloride'	,'Argentum nitricum'	,'Anise water concentrated'	,'Amyl nitrite vitrellae'	,'Amaranth solution'	,'Alpha-Lipoic Acid'	,'Actaea racemosa'	,'Aconitum napellus','8-Methoxypsoralen'	,
'4-Aminopyridine'	,'3,4-Diaminopyridine')
or regexp_like(brand_name, 'Zinc sulfate|Zinc and|Water|Vitamin B compound|Thymol|Sodium|Simple linctus|Ringers|Podophyllin|Phenol|Oxygen|Morphine|Medical|Dextran|Magnesium|Macrogol|Lipofundin|Kaolin|Kalium|Ipecacuanha|Iodine|Hypurin|Hypericum|Helium cylinders|Glycerin|Glucose|Gentian|Ferric chloride|E-D3|E45|Carbon dioxide cylinders|Bacillus Calmette-Guerin|Anticoagulant Citrate|Ammonia|Air cylinders|Ammonium chloride|Emulsifying|Ferrum|Carbomer')
;
update  branded_drug_to_brand_name
set brand_name=regexp_replace(brand_name,'(sterile water inhalation solution|wort herb tincture|sugar free|oral powder|in Orabase|Intravenous|ear drops|rectal|facewash|concentrate for|suspension for injection|ear/eye/nose drops|I.V.)+');

--add sequence
drop sequence new_seq;
 create sequence new_seq increment by 1 start with 100 nocycle cache 20 noorder
 ;
 drop table br_name_list;
create table br_name_list as 
select 'OMOP'||new_seq.nextval as concept_code, Brand_name as concept_name from (
select distinct Brand_name from branded_drug_to_brand_name)
;
drop table drug_to_brand_name_full;
create table drug_to_brand_name_full as
select distinct a.CONCEPT_CODE as concept_code_1 , b.CONCEPT_CODE as concept_code_2 from  branded_drug_to_brand_name a
join br_name_list b on a.brand_name = b.concept_name
union
select distinct x.CONCEPT_CODE_1,  b.CONCEPT_CODE from  branded_drug_to_brand_name a
join br_name_list b on a.brand_name = b.concept_name
join Box_to_drug x on x.concept_code_2 = a.concept_code
;
--INTERNAL_RELATIONSHIP_STAGE
truncate table INTERNAL_RELATIONSHIP_STAGE;
--Drug to ingredient
insert into INTERNAL_RELATIONSHIP_STAGE (concept_code_1, concept_code_2)
select distinct drug_concept_code, ingredient_concept_code from ds_stage
;
--Drug to Form
insert into INTERNAL_RELATIONSHIP_STAGE (concept_code_1, concept_code_2)
select distinct concept_code_1, concept_code_2 from DR_TO_DOSE_form_full where concept_code_1 not in (select PACK_CONCEPT_CODE from  PACK_CONTENT)
;
--Drug to Brand Name 
insert into INTERNAL_RELATIONSHIP_STAGE (concept_code_1, concept_code_2)
select distinct a.CONCEPT_CODE_1, a.CONCEPT_CODE_2 from  drug_to_brand_name_full a
;
--Drug to manufacturer
insert into INTERNAL_RELATIONSHIP_STAGE (concept_code_1, concept_code_2)
select distinct concept_code_1, concept_code_2 from Drug_to_manufact_2
;
--Ingred to Ingred, for now Ingred to Ingred relationship is considered only as Maps to 
insert into INTERNAL_RELATIONSHIP_STAGE (concept_code_1, concept_code_2)
select distinct concept_code_1, concept_code_2 from ingred_to_ingred_FINAL_BY_Lena where CONCEPT_CODE_2 is not null
;
--concept replaced by
insert into INTERNAL_RELATIONSHIP_STAGE (concept_code_1, concept_code_2)
select distinct CONCEPT_CODE_1, CONCEPT_CODE_2 from deprec_to_active
;
--RELATIONSHIP_TO_CONCEPT
--mappings and insertion into standard tables
truncate table RELATIONSHIP_TO_CONCEPT;

--Ingredients mapping
drop table stand_ingr_map ;
create table stand_ingr_map as 
select distinct  b.concept_code_1, a.CONCEPT_ID_2, a.PRECEDENCE from ingred_to_ingred_FINAL_BY_Lena b --manual table
join  Ingr_to_Rx a -- !!! semi-automatically created table 
on a.CONCEPT_CODE_1 = b.CONCEPT_CODE_1 
where b.concept_code_2 is null
and a.CONCEPT_ID_2 is not null
;
--Ingredients mapping, make mapping only for standard ingrediets
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  ,PRECEDENCE)
select distinct CONCEPT_CODE_1,'dm+d', CONCEPT_ID_2,PRECEDENCE from stand_ingr_map
;
-- dose form mapping
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  ,PRECEDENCE)
select distinct CONCEPT_CODE,'dm+d',CONCEPT_ID_2,PRECEDENCE from AUT_FORM_ALL_MAPPED -- !!! fully manual 
where concept_ID_2 is not null
;
-- units mapping, --don't need to recreate now
/*
--!!!
 create table unit_for_ucum as  (
 select distinct amount_unit,concept_id_2,concept_name_2,conversion_factor,precedence,concepT_id,concept_name as ucum_concept_name from (  select distinct AMOUNT_UNIT from ds_all_cl_dr
 union 
 select distinct NUMERATOR_UNIT from ds_all_cl_dr
 union
 select distinct DENOMINATOR_UNIT from ds_all_cl_dr) a 
 left join dev_amis.AUT_UNIT_ALL_MAPPED b on lower(a.amount_unit)=lower(b.concept_code) 
 left join devv5.concept c on lower(c.concept_name)=lower(a.amount_unit) and vocabulary_id='UCUM' and invalid_reason is null);
 update  unit_for_ucum 
 set concept_id_2=concept_id where concept_id is not null;
DELETE FROM UNIT_FOR_UCUM  WHERE AMOUNT_UNIT IS NULL AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL  AND   CONVERSION_FACTOR IS NULL  AND   PRECEDENCE IS NULL  AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
DELETE FROM UNIT_FOR_UCUM  WHERE AMOUNT_UNIT = 'dose' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL  AND   CONVERSION_FACTOR IS NULL  AND   PRECEDENCE IS NULL  AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
DELETE FROM UNIT_FOR_UCUM  WHERE AMOUNT_UNIT = 'molar' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL  AND   CONVERSION_FACTOR IS NULL  AND   PRECEDENCE IS NULL  AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8510,       CONCEPT_NAME_2 = 'unit',       PRECEDENCE = 1 WHERE AMOUNT_UNIT = ' Kallikrein inactivator units' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8576,       CONCEPT_NAME_2 = 'milligram',       CONVERSION_FACTOR = 1000,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'gram' AND   CONCEPT_ID_2 = 8504 AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID = 8504 AND   UCUM_CONCEPT_NAME = 'gram';
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8505,       CONCEPT_NAME_2 = 'hour',       CONVERSION_FACTOR = 1,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'hours' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 45891008,       CONCEPT_NAME_2 = 'kilobecquerel',       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'kBq' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8519,       CONCEPT_NAME_2 = 'liter',       CONVERSION_FACTOR = 1,       PRECEDENCE = 2 WHERE AMOUNT_UNIT = 'litre' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 9655,       CONCEPT_NAME_2 = 'microgram',       CONVERSION_FACTOR = 1,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'mcg' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_NAME_2 = 'microgram',       CONVERSION_FACTOR = 1,       PRECEDENCE = 2 WHERE AMOUNT_UNIT = 'microgram' AND   CONCEPT_ID_2 = 9655 AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID = 9655 AND   UCUM_CONCEPT_NAME = 'microgram';
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 9655,       CONCEPT_NAME_2 = 'microgram',       CONVERSION_FACTOR = 1,       PRECEDENCE = 2 WHERE AMOUNT_UNIT = 'micrograms' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8587,       CONCEPT_NAME_2 = 'milliliter',       CONVERSION_FACTOR = 0.001,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'microlitres' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_NAME_2 = 'Million unit',       CONVERSION_FACTOR = 1,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'million unit' AND   CONCEPT_ID_2 = 9689 AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID = 9689 AND   UCUM_CONCEPT_NAME = 'Million unit';
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8587,       CONCEPT_NAME_2 = 'milliliter',       CONVERSION_FACTOR = 1,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'ml ' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 9573,       CONCEPT_NAME_2 = 'millimole',       CONVERSION_FACTOR = 1,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'mmol' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_NAME_2 = 'nanogram',       CONVERSION_FACTOR = 1,       PRECEDENCE = 2 WHERE AMOUNT_UNIT = 'nanogram' AND   CONCEPT_ID_2 = 9600 AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID = 9600 AND   UCUM_CONCEPT_NAME = 'nanogram';
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 9600,       CONCEPT_NAME_2 = 'nanogram',       CONVERSION_FACTOR = 1,       PRECEDENCE = 2 WHERE AMOUNT_UNIT = 'nanograms' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
UPDATE UNIT_FOR_UCUM   SET CONCEPT_NAME_2 = 'unit',       CONVERSION_FACTOR = 1,       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'unit' AND   CONCEPT_ID_2 = 8510 AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID = 8510 AND   UCUM_CONCEPT_NAME = 'unit';
UPDATE UNIT_FOR_UCUM   SET CONCEPT_ID_2 = 8510,       CONCEPT_NAME_2 = 'unit',       PRECEDENCE = 1 WHERE AMOUNT_UNIT = 'units' AND   CONCEPT_ID_2 IS NULL AND   CONCEPT_NAME_2 IS NULL AND   CONVERSION_FACTOR IS NULL AND   PRECEDENCE IS NULL AND   CONCEPT_ID IS NULL AND   UCUM_CONCEPT_NAME IS NULL;
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'litre',  8587,  'milliliter',  0.001,  1,  NULL,  NULL);
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'microgram',  8576,  'milligram',  0.001,  1,  NULL,  NULL);
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'micrograms',  8576,  'milligram',  0.001,  1,  NULL,  NULL);
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'microlitres',  9665,  'microliter',  1,  2,  NULL,  NULL);
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'million unit',  8510,  'unit',  1000000,  2,  NULL,  NULL);
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'nanogram',  8576,  'milligram',  0.000001,  1,  NULL,  NULL);
INSERT INTO UNIT_FOR_UCUM(  AMOUNT_UNIT,  CONCEPT_ID_2,  CONCEPT_NAME_2,  CONVERSION_FACTOR,  PRECEDENCE,  CONCEPT_ID,  UCUM_CONCEPT_NAME)VALUES(  'nanograms',  8576,  'milligram',  0.000001,  1,  NULL,  NULL);

create table unit_for_ucum_done--final table for internal relationship
 as (
select amount_unit as concept_name_1,amount_unit as concept_Code_1,concept_id_2,concept_name_2,conversion_factor, precedence from unit_for_ucum);
*/
--units mapping
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  ,PRECEDENCE, CONVERSION_FACTOR) 
select distinct CONCEPT_CODE_1,'dm+d'  ,CONCEPT_ID_2,PRECEDENCE,CONVERSION_FACTOR from unit_for_ucum_done -- manual table, creation is above
;
--Brand names mapping
--name full equality
drop table  brand_name_map;
create table brand_name_map as 
select a.*, c.concept_id, c.concept_name from
(select distinct BRAND_NAME from branded_drug_to_brand_name) a
left join devv5.concept c on upper (a.brand_name )= upper (c.concept_name) and c.vocabulary_id = 'RxNorm' and c.concept_class_id  ='Brand Name' and invalid_reason is null
;
/*
drop table Brands_by_Lena; --!!!
create table Brands_by_Lena 
(
BRAND_NAME	varchar (250),	CONCEPT_ID int,	CONCEPT_NAME_2 varchar (250)
)
WbImport -file=C:/mappings/DM+D/brand_names_by_Lena.txt
         -type=text
         -table=BRANDS_BY_LENA
         -encoding="ISO-8859-15"
         -header=true
         -decode=false
         -dateFormat="yyyy-MM-dd"
         -timestampFormat="yyyy-MM-dd HH:mm:ss"
         -delimiter='\t'
         -decimal=.
         -fileColumns=BRAND_NAME,CONCEPT_ID,CONCEPT_NAME_2
         -quoteCharEscaping=none
         -ignoreIdentityColumns=false
         -deleteTarget=false
         -continueOnError=false;
         */
;
drop table brand_name_map_full;
create table brand_name_map_full as 
select distinct BRAND_NAME,CONCEPT_ID, CONCEPT_NAME  from brand_name_map where CONCEPT_ID is not null
union 
select distinct * from BRANDS_BY_LENA
;
delete from brand_name_map_full where concept_ID IN (40062307, 19059723) -- deprecated concepts 
;
--brand names mapping
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2)
SELECT distinct b.concept_code,'dm+d'  , CONCEPT_ID FROM brand_name_map_full a
join br_name_list b on a.BRAND_NAME = b.CONCEPT_NAME
;
--new ingredients mapping
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  ,PRECEDENCE, CONVERSION_FACTOR) 
select distinct INGR_CODE, 'dm+d', RXNORM_ID, 1, '' from lost_ingr_to_rx_with_OMOP
;
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  ,PRECEDENCE, CONVERSION_FACTOR) 
values ( 'OMOP28664', 'dm+d', 798336, 1, '')
;
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  ,PRECEDENCE, CONVERSION_FACTOR) 
values ( 'OMOP28671', 'dm+d', 902251, 1, '')
;
create table RELATIONSHIP_TO_CONCEPT_tmp as select distinct * from RELATIONSHIP_TO_CONCEPT
;
drop table RELATIONSHIP_TO_CONCEPT
;
create  table RELATIONSHIP_TO_CONCEPT as select  * from RELATIONSHIP_TO_CONCEPT_tmp
;
drop table RELATIONSHIP_TO_CONCEPT_tmp
;
DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = '17644011000001108'
AND   CONCEPT_ID_2 = 46234468
AND   PRECEDENCE = 7;
DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = '385197005'
AND   CONCEPT_ID_2 = 19126918
AND   PRECEDENCE IS NULL;

--ATC concepts 
drop table clinical_to_atc ;
create table clinical_to_atc as 
 select --distinct a.concept_class_id
  a.concept_code as concept_code_1, a.concept_name as concept_name_1 , d.concept_id as concept_id_2, d.concept_name as concept_name_2
  from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'  
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'ATC'
 where a.concept_class_id like '%Drug%'
;
drop table clinical_to_atc_2;
create table clinical_to_atc_2 as 
select distinct a.concept_code_1, a.concept_name_1,  b.concept_id_2, b.concept_name_2 from Box_to_Drug a 
join clinical_to_atc b on a.concept_code_2  = b.concept_code_1
union 
select * from clinical_to_atc
;
drop table clinical_to_atc_full ;
create table clinical_to_atc_full as 
--branded drug
select distinct a.concept_code_1, a.concept_name_1,  b.concept_id_2, b.concept_name_2
 from Branded_to_clinical a 
join clinical_to_atc_2 b on a.concept_code_2  = b.concept_code_1
union 
select * from clinical_to_atc_2
;
insert into RELATIONSHIP_TO_CONCEPT (CONCEPT_CODE_1, VOCABULARY_ID_1 ,   CONCEPT_ID_2  )
select distinct CONCEPT_CODE_1,'dm+d',CONCEPT_ID_2 from clinical_to_atc_full
;
--drug_concept_stage, take version from back-up
drop table drug_concept_stage
;
create table drug_concept_stage as select * from
drug_concept_stage_existing
;
update drug_concept_stage set domain_id = 'Device', concept_class_id = 'Device' where concept_code in (select concept_code from non_drug_full)
;
update drug_concept_stage set domain_id = 'Device', concept_class_id = 'Device' where concept_code in ('3378311000001103','3378411000001105')
;
update drug_concept_stage set domain_id = 'Drug' where concept_code not in (select concept_code from non_drug_full)
;
--newly generated concepts 
--Brand Names
insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select                           CONCEPT_NAME,'Drug', 'dm+d', 'Brand Name', '', concept_code, TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from br_name_list
;
--NEW Ingredients
insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
select                           CONCEPT_NAME_1,'Drug', 'dm+d', 'Ingredient', 'S', concept_code_1, TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from ingred_to_ingred_FINAL_BY_Lena where concept_code_1 like 'OMOP%'
;
--NEW Forms
insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
 select distinct                          CONCEPT_NAME_2,'Drug', 'dm+d', 'Dose Form', '', concept_code_2, TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from DR_TO_DOSE_form_full where concept_code_2 like 'OMOP%'
;
--NEW Pack components 
insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
 select distinct                          DRUG_NEW_NAME,'Drug', 'dm+d', 'Clinical Drug', 'S', DRUG_CODE, TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from PACK_DRUG_TO_CODE_2_2  where DRUG_CODE like 'OMOP%'
;
--modify classes for Packs
update drug_concept_stage set concept_class_id = 'Drug Pack' where concept_code  in (select PACK_CONCEPT_CODE from PACK_CONTENT )
;
--add units 
insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
 select distinct                          CONCEPT_NAME_1,'Unit', 'dm+d', 'Unit', '', CONCEPT_CODE_1, TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from unit_for_ucum_done 
 ;
--proper 'S'
update  drug_concept_stage
set STANDARD_CONCEPT = 'S' where 
(concept_class_id like '%Drug%' or 
concept_class_id like 'Device')
and invalid_reason is null
or concept_code in (select concept_code_1 from ingred_to_ingred_FINAL_BY_Lena where concept_code_2 is null)
;
--Supplier
update drug_concept_stage 
set concept_class_id = 'Supplier' where concept_class_id = 'Manufacturer'
  ;
  --add newly created ingredients
  insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
 select distinct                  INGR_NAME        ,'Drug', 'dm+d', 'Ingredient', 'S', INGR_CODE, TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from lost_ingr_to_rx_with_OMOP 
;
  insert into  drug_concept_stage (CONCEPT_NAME,DOMAIN_ID,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,VALID_START_DATE,VALID_END_DATE,INVALID_REASON)
 select distinct                  'hypromellose'        ,'Drug', 'dm+d', 'Ingredient', 'S', 'OMOP28671', TO_DATE ('19700101', 'yyyymmdd'), TO_DATE ('20991231', 'yyyymmdd'), '' from lost_ingr_to_rx_with_OMOp 
 ;
-- select * from drug_concept_stage where concept_code = 'OMOP28663'
commit;


DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = '278910002'
AND   CONCEPT_ID_2 = 1352213
AND   PRECEDENCE IS NULL;
--1
update ds_stage b
set box_size = (select regexp_substr (regexp_substr (concept_name, '\d+ ampoule'), '\d+') from drug_concept_Stage a where a.concept_code = b.drug_concept_code and regexp_like (concept_name, '\d+ ampoule') and box_size is  null)
where exists (select 1 from drug_concept_Stage a where a.concept_code = b.drug_concept_code and regexp_like (concept_name, '\d+ ampoule') and box_size is null)
and box_size is  null
;
commit;
--delete impossible combinations from ds_stage, treat these drugs as Clinical/Branded Drug Form
--for now we make an analysis
/*
delete from ds_stage where numerator_value is null and amount_value is null
*/
;
update ds_stage a
set AMOUNT_UNIT = null, AMOUNT_VALUE = null, NUMERATOR_VALUE = AMOUNT_VALUE, NUMERATOR_UNIT = AMOUNT_UNIT
 where amount_value is not null and denominator_value is not null
 ;
 UPDATE DS_STAGE
   SET NUMERATOR_UNIT = 'ml'
WHERE DRUG_CONCEPT_CODE = '8055111000001105'
AND   INGREDIENT_CONCEPT_CODE = '10569311000001100';
UPDATE DS_STAGE
   SET NUMERATOR_UNIT = 'ml'
WHERE DRUG_CONCEPT_CODE = '14779411000001100'
AND   INGREDIENT_CONCEPT_CODE = '80582002';

--delete impossible combinations from ds_stage, treat these drugs as Clinical/Branded Drug Form
--!!! keep this for further analysis
/*
delete from ds_stage a
where numerator_UNIT is null and numerator_value is not null
*/
 ;
select count (distinct drug_concept_code) from (
select drug_concept_code from ds_stage a
where amount_value is null and numerator_value is null and DENOMINATOR_VALUE is not null
union 
select drug_concept_code from ds_stage a
where amount_value is null and numerator_value is  null and box_size is not null
union
select drug_concept_code from ds_stage a 
join internal_relationship_stage b on a.drug_concept_code = b.concept_code_1 
join drug_concept_stage c on c.concept_code = b.concept_code_2
where amount_value is null and numerator_value is null
and c.concept_class_id = 'Supplier'
)
;
/*
select distinct b.concept_name from ds_stage a
join drug_concept_stage b on a.drug_concept_code = b.concept_code
where  amount_value is null and numerator_value is null
*/
;
commit
;
/* don't need this anymore
alter table drug_concept_Stage 
add  source_concept_class_id varchar (20)
; 
--set concept_classes to values given originaly by dm+d source
update drug_concept_stage 
set source_concept_class_id = 'Form' where insert_id in (3,4)
;
update drug_concept_stage  set source_concept_class_id = 'Ingredient' where insert_id in (7,8)
;
update drug_concept_stage  set source_concept_class_id = 'VTM' where insert_id in (9,10)
;
update drug_concept_stage  set source_concept_class_id = 'VMP' where insert_id in (11,12)
;
update drug_concept_stage  set source_concept_class_id = 'AMP' where insert_id in (13)
;
update drug_concept_stage  set source_concept_class_id = 'VMPP' where insert_id in (14)
;
update drug_concept_stage  set source_concept_class_id = 'AMPP' where insert_id in (15)
;
update drug_concept_stage  set source_concept_class_id = 'Supplier' where insert_id in (16)
;
*/
--investigation
/*
--update ds_stage, some dose forms can't have denominator but should have amount
select distinct c.concept_code, c.concept_name from ds_stage ds
join internal_relationship_stage ir on ir.concept_code_1 = ds.drug_concept_code 
join drug_concept_stage c on c.concept_code = ir.concept_code_2
and c.concept_class_id = 'Dose Form'
 where amount_value is null and numerator_value is null and denominator_value is not null
 ;
 select *
 -- distinct c.concept_code, c.concept_name 
 from ds_stage ds
join internal_relationship_stage ir on ir.concept_code_1 = ds.drug_concept_code 
join drug_concept_stage c on c.concept_code = ir.concept_code_2
join drug_concept_stage c1 on c1.concept_code = ir.concept_code_1
and c.concept_class_id = 'Dose Form'
 where amount_value is null and numerator_value is null and denominator_value is not null
 and c.concept_code in
 ( --all solid forms
 '3095811000001106',
'385049006',
'420358004',
'385043007',
'7376011000001109',
'385045000',
'85581007',
'421079001',
'385042002',
'385054002',
'385052003',
'385087003'
)

;
 select *
 -- distinct c.concept_code, c.concept_name 
 from ds_stage ds
join internal_relationship_stage ir on ir.concept_code_1 = ds.drug_concept_code 
join drug_concept_stage c on c.concept_code = ir.concept_code_2
join drug_concept_stage c1 on c1.concept_code = ir.concept_code_1
and c.concept_class_id = 'Dose Form'
 where amount_value is null and numerator_value is null and denominator_value is not null
 and c.concept_code in
 (
'14945811000001105',
'7375911000001101',
'17036711000001108',
'21829711000001102'
)
*/
--change amount to denominator_value
update  ds_stage ds set amount_value = denominator_value , amount_unit = denominator_unit
where exists (select 1 from 
internal_relationship_stage ir  
join drug_concept_stage c on c.concept_code = ir.concept_code_2
join drug_concept_stage c1 on c1.concept_code = ir.concept_code_1
and c.concept_class_id = 'Dose Form'
 where amount_value is null and numerator_value is null and denominator_value is not null
 and c.concept_code in
 ( --all solid forms
 '3095811000001106',
'385049006',
'420358004',
'385043007',
'7376011000001109',
'385045000',
'85581007',
'421079001',
'385042002',
'385054002',
'385052003',
'385087003'
)
and  ir.concept_code_1 = ds.drug_concept_code )
;
create table ds_brand_update as 
select CONCEPT_CODE_1, CONCEPT_NAME_1 from branded_to_clinical 
join drug_concept_stage on CONCEPT_CODE_1 = concept_code and domain_id ='Drug' and invalid_reason is null
join (select drug_concept_code from ds_stage where amount_value is null and numerator_value is null group by drug_concept_code having count (1) = 1) ds on ds.drug_concept_code = concept_code_1
where regexp_like (concept_name_1, 
 '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol|million units)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)*')
and not  
regexp_like  (concept_name_2, 
 '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol|million units)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)*')
;
update ds_stage 
set amount_value = (select regexp_substr ( regexp_substr (concept_name_1, '[[:digit:]\,\.]+(mg|g|microgram(s)*|million unit(s*))'), '[[:digit:]\,\.]+') from ds_brand_update where concept_code_1 = drug_concept_code),
 amount_unit = (select regexp_replace ( regexp_substr (concept_name_1, '[[:digit:]\,\.]+(mg|g|microgram(s)*|million unit(s*))'), '[[:digit:]\,\.]+') from ds_brand_update where concept_code_1 = drug_concept_code)
where exists (select 1 from ds_brand_update where concept_code_1 = drug_concept_code)
and drug_concept_code not in ('16636811000001107', '16636911000001102', '15650711000001103', '15651111000001105' )--Packs and vaccines
;
commit
; 
--final update of ds_stage, sometimes Clinical Drug has no dosage, but Branded Drugs related to them do
--update could be done easily
/*
select * from ds_stage a
join drug_concept_stage b on drug_concept_code = concept_code
where regexp_like (concept_name, 
'[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm|million units| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres|unit dose|drop)*') 
and amount_value is null and numerator_value is null
;
*/
drop sequence new_vocab;
 create sequence new_vocab increment by 1 start with 245693 nocycle cache 20 noorder; -- change to procedure
drop table name_replace;
 create table name_replace as 
 select 'OMOP'||new_vocab.nextval as concept_code, concept_name from (
select distinct  concept_name from drug_concept_stage where concept_code like 'OMOP%')
;
drop  table code_replace;
create table code_replace as
select a.concept_code as old_code, b.concept_code as new_code
from drug_concept_stage a join name_replace b on a.concept_name = b.concept_name
where a.concept_code like 'OMOP%'
;
select * from code_replace where old_code like 'OMOP%'
;
update drug_concept_stage a set concept_code = (select new_code from code_replace b where a.concept_code = b.old_code) 
where a.concept_code like 'OMOP%'
;
update relationship_to_concept a  set concept_code_1 = (select new_code from code_replace b where a.concept_code_1 = b.old_code)
where a.concept_code_1 like 'OMOP%'
;
update ds_stage a  set ingredient_concept_code = (select new_code from code_replace b where a.ingredient_concept_code = b.old_code)
where a.ingredient_concept_code like 'OMOP%'
;
update ds_stage a  set drug_concept_code = (select new_code from code_replace b where a.drug_concept_code = b.old_code)
where a.drug_concept_code like 'OMOP%'
;
update internal_relationship_stage a  set concept_code_1 = (select new_code from code_replace b where a.concept_code_1 = b.old_code)
where a.concept_code_1 like 'OMOP%'
;
update internal_relationship_stage a  set concept_code_2 = (select new_code from code_replace b where a.concept_code_2 = b.old_code)
where a.concept_code_2 like 'OMOP%'
;
update pack_content a  set DRUG_CONCEPT_CODE = (select new_code from code_replace b where a.DRUG_CONCEPT_CODE = b.old_code)
where a.DRUG_CONCEPT_CODE like 'OMOP%'
;
--delete duplicates from ds_stage
create table drug_concept_stage_v0 as select distinct * from  drug_concept_stage
;
drop table drug_concept_stage
;
create table drug_concept_stage as  select distinct * from  drug_concept_stage_v0
;
drop table drug_concept_stage_v0;
commit;

create table relationship_to_concept_v0 as select distinct * from  relationship_to_concept
;
drop table relationship_to_concept
;
create table relationship_to_concept as  select distinct * from  relationship_to_concept_v0
;
drop table relationship_to_concept_v0;

commit
;
