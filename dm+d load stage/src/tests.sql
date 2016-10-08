select * from ingred_to_ingred where concept_code_1 in (
'372515005' , '108605008')
;
select a.*, b.* from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1
where a.concept_code_1 like '100%'
;
--when names are the same use "7", when one of the names has another one, use - shorter
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2 from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1
where a.concept_code_1 like '100%'
;
--seems we found correct relationships to ingredients looks nice
select * from clin_dr_ingred_test;
drop table clin_dr_ingred_test;
create table clin_dr_ingred_test as 
select * from (
select distinct a.concept_code_1, a.concept_name_1, coalesce (b.code_2,a.code_2) as code_2, coalesce (b.name_2,a.name_2) as name_2 , coalesce (b.ins_id_2, a.ins_id_2) as ins_id_2  from 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2 from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate', 'Sodium', 'Iron') 
--where a.concept_code_1 like '10%'
) a 
left join 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2  from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate',  'Sodium', 'Iron') 
--where a.concept_code_1 like '10%'
) b on (a.concept_code_1 = b.concept_code_1 and a.ins_id_2 > b.ins_id_2 and a.name_2 = b.name_2 
or
 a.concept_code_1 = b.concept_code_1 and lower (a.name_2) like lower ('%'||b.name_2||'%') and a.name_2 != b.name_2 )
 ) a
where not exists (select 1 from 
(
select distinct a.concept_code_1, a.concept_name_1,a.code_2  from 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2 from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate', 'Sodium', 'Iron') 
--where a.concept_code_1 like '10%'
) a 
 join 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2  from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate',  'Sodium', 'Iron') 
--where a.concept_code_1 like '10%'
) b on (a.concept_code_1 = b.concept_code_1 and a.ins_id_2 > b.ins_id_2 and a.name_2 = b.name_2 
or
 a.concept_code_1 = b.concept_code_1 and lower (a.name_2) like lower ('%'||b.name_2||'%') and a.name_2 != b.name_2 )
 ) c where c.concept_code_1 = a.concept_code_1 and c.code_2 = a.code_2 )
 ;
 select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2  from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate',  'Sodium', 'Iron') 
where a.concept_code_1 like '10%'
;
select * from ingred_to_ingred where concept_code_1 = '3589411000001109'
;
select * from drug_concept_stage where concept_name ='Magnesium chloride'
;
select * from clin_dr_ingred_test a  join (select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, a.insert_id as insert_id_1, r.relationship_id, cs.concept_code as concept_code_2, cs.concept_name as concept_name_2, cs.insert_id as insert_id_2   from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'  and a.concept_class_id ='Ingredient'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = 'Ingredient'
and a.concept_code != cs.concept_code
and r.relationship_id in ('Is a', 'Has active ing', 'Concept poss_eq from', 'Concept same_as from') 
and cs.invalid_reason is null) b on a.code_2 = b.concept_code_1
and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate',  'Sodium', 'Iron') 
 ;
 select count (1) from 
 (select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, a.insert_id as insert_id_1, r.relationship_id, cs.concept_code as concept_code_2, cs.concept_name as concept_name_2, cs.insert_id as insert_id_2   from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED'  and a.concept_class_id ='Ingredient'
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'SNOMED'
join drug_concept_stage cs on cs.concept_code  = d.concept_code and cs.concept_class_id = 'Ingredient'
and a.concept_code != cs.concept_code
and r.relationship_id in ('Is a', 'Has active ing', 'Concept poss_eq from', 'Concept same_as from') 
and cs.invalid_reason is null);
 select count (1) from ingred_to_ingred

;
--all the clinical drugs 
select * from drug_concept_stage where concept_code  like '10%' and concept_class_id  ='Clinical Drug' and concept_code not in (
select concept_code from  (
select distinct a.concept_code_1, a.concept_name_1, coalesce (b.code_2,a.code_2) as code_2, coalesce (b.name_2,a.name_2) as name_2 , coalesce (b.ins_id_2, a.ins_id_2) as ins_id_2  from 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2 from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate', 'Sodium') 
where a.concept_code_1 like '10%'
) a 
left join 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2  from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate',  'Sodium') 
where a.concept_code_1 like '10%'
) b on (a.concept_code_1 = b.concept_code_1 and a.ins_id_2 > b.ins_id_2 and a.name_2 = b.name_2 
or
 a.concept_code_1 = b.concept_code_1 and lower (a.name_2) like lower ('%'||b.name_2||'%') and a.name_2 != b.name_2 )
))
;
select * from concept where lower (concept_name) like '%acetarsol%' and vocabulary_id = 'RxNorm' and concept_class_id = 'Ingredient'
;
select * from 
(
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2 from Clinical_to_Ingred a
left join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate', 'Sodium', 'Iron') 
where a.concept_code_1 like '10%'
) a where not exists (select 1 from (
select a.CONCEPT_CODE_1,a.CODE_2 from Clinical_to_Ingred a
 join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate', 'Sodium', 'Iron') 
where a.concept_code_1 like '10%'
) c where a.concept_code_1 = c.concept_code_1 and a.code_2 = c.code_2)

;
select a.*, coalesce (b.concept_code_2,a.concept_code_2) as code_2, coalesce (b.concept_name_2,a.concept_name_2) as name_2 , coalesce (b.insert_id_2, a.insert_id) as ins_id_2 from Clinical_to_Ingred a
join ingred_to_ingred b on a.concept_code_2 = b.concept_code_1 and b.concept_name_2 not in ('Calcium', 'Zink', 'Potassium', 'Magnesium', 'Chloride', 'Bicarbonate', 'Sodium', 'Iron') 
where a.concept_code_1 like '10%'
;
select * from Dexpanthenol
;
select * from Ingr_to_Rx_existing  where concept_name_1 ='Ergocalciferol'
;
select * from concept where concept_name in ('Ergocalciferol', 'Vitamin D', 'Cholecalciferol')
and vocabulary_id = 'RxNorm' and concept_class_id = 'Ingredient'
;
select * from drug_concept_stage where concept_name like '%Ergocalciferol%'
;
select * from drug_concept_stage where concept_name like '%lecalciferol%'
;
select * from concept where regexp_like ( lower (concept_name), ' tar$' )and vocabulary_id ='RxNorm'  and concept_class_id = 'Ingredient'
-- OFFSET 0 ROWS FETCH NEXT 500 ROWS ONLY
;
select * from drug_concept_stage where  regexp_like ( lower (concept_name), ' tar$' )
;
select * from concept where regexp_like ( lower (concept_name), 'codeine' )and vocabulary_id ='RxNorm'  and concept_class_id = 'Ingredient'
;
select * from concept where vocabulary_id ='RxNorm'  and concept_class_id = 'Ingredient'
;
select * from drug_concept_stage where lower (concept_name) like '%influenzae type b%'
;
select * from ingred_to_ingred a left join  Ingr_to_Rx_existing b on a.CONCEPT_CODE_1 = b.CONCEPT_CODE_1 
left join Ingr_to_Rx_existing c on a.CONCEPT_CODE_2 = c.concept_code_1
join RxNorm_precise s on b.concept_id_2 = s.concept_id_1 and c.concept_id_2 = s.concept_id_2
where STANDARD_CONCEPT_1 is null
;
 select * from dev_amis.source_table where enr=2600003;
 ;
select distinct *
 from strength_tmp a join strength_tmp b on a.drug_code = b.drug_code 
 and (a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null  
 or a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE
 or a.DENOMINATOR_unit != b.DENOMINATOR_unit);
 
create table RxNorm_precise as 
select a.concept_id as concept_id_1, a.concept_name as concept_name_1, a.standard_concept as standard_concept_1, c.concept_id as concept_id_2, c.concept_name as concept_name_2, c.standard_concept as standard_concept_2 from devv5.concept  a 
join devv5.concept_relationship b on a.concept_id = b.concept_id_1
join devv5.concept c on c.concept_id = b.concept_id_2
where a.vocabulary_id ='RxNorm' and c.vocabulary_id ='RxNorm'-- and a.concept_class_id ='Ingredient' and c.concept_class_id ='Ingredient'
and b.relationship_id ='Form of'
;
from devv5.concept c1
join devv5.concept_relationship r on r.concept_id_1=c1.concept_id and r.invalid_reason is null and r.relationship_id='Form of'
join devv5.concept c2 on c2.concept_id=r.concept_id_2
--where c1.concept_id=46274851;
;
;
select * from devv5.concept where lower (concept_name)  like '%dergocrine%' and concept_class_id ='Ingredient'
;
select concept_code, concept_name from drug_concept_stage where lower (concept_name)  like '%mucin%'
;
select * from Clinical_to_Ingred where concept_code_2 = '3862511000001103'
;
select * from devv5.concept where lower (concept_name) like '%atenolol%' and concept_class_id ='Clinical Drug' and vocabulary_id = 'RxNorm'
;
select * from drug_concept_stage where concept_name ='Atenolol 10mg/5ml oral suspension 1 ml'
;
select * from drug_concept_stage
;
select * from devv5.concept where lower (concept_name) like '%gynest%'  and vocabulary_id = 'RxNorm'
;
select * from devv5.concept where regexp_like (concept_name, ' \d+')and vocabulary_id = 'DPD' and concept_class_id = 'Brand Name'
OFFSET 0 ROWS FETCH NEXT 500 ROWS ONLY;
select * from concept where vocabulary_id='DPD' and concept_class_id='Brand Name' and concept_name like '%200%';
;
select * from drug_concept_stage where concept_name = 'Atenolol 10mg/5ml oral suspension 1 ml'
;
select * from drug_concept_stage where concept_name = 'Lidocaine'
;
select * from devv5.concept where lower (concept_name) like '%betamethasone%' and vocabulary_id = 'RxNorm' and concept_class_id ='Clinical Drug'
;
select  * from devv5.concept a 
join ds_stage_need_manual b 
on lower ( a.concept_name) = lower ( regexp_replace (b.concept_name, '\s.*'))
where vocabulary_id = 'RxNorm' and concept_class_id ='Brand Name' and invalid_reason is null
--and concept_name like '% / %'
;
select *from ds_stage_need_manual b
join  devv5.concept a 
on lower ( regexp_replace ( regexp_substr (b.CONCEPT_NAME, 'Generic [[:alpha:]]+'),'Generic ')) = lower ( a.concept_name)
join concept_relationship r o
join concept cc on cc.
where b.concept_name like 'Generic%'
and  a.vocabulary_id = 'RxNorm' and a.concept_class_id ='Brand Name' and invalid_reason is null
;
select * from devv5.drug_strength 
OFFSET 0 ROWS FETCH NEXT 500 ROWS ONLY;
;
select count (*) from INGR_MAPPED
where CONCEPT_CODE not in (
select CONCEPT_CODE_1 from  INGREDIENT_MAP)
;
select * from  INGREDIENT_MAP   --used in Script
where CONCEPT_CODE_1 not in (
select CONCEPT_CODE from  INGR_MAPPED union select  concept_code_1 from Ingr_to_Rx_existing)
;
select * from Clinical_to_Ingred_tmp
;
select * from drug_concept_stage where concept_name ='Betamethasone'
;
select * from ingred_to_ingred_FINAL_BY_Lena where concept_name_1 = 'Fluocinolone'
;
select * from non_drug where drug_code ='3392811000001100'
;
select * from drug_concept_stage where concept_name like'%TISSEEL%'
;
select * from aut_form_mapped_noRx_pack
;
select * from drug_concept_stage where lower ( concept_name) = '%clotrimazole 500mg%'
;
select count (1) FROM DRUG_concept_stage where concept_class_id ='Clinical Drug' and invalid_reason is null and concept_code not in (select concept_code from clnical_non_drug)
;
select * from clin_dr_to_ingr_3
;
select * from dr_pack_to_Clin_dr_box_full where concept_code_1='9520911000001104'
;
select distinct concept_class_id from concept where standard_concept is not null and vocabulary_id = 'RxNorm'
;
select * from devv5.concept where vocabulary_id = 'ICD9CM'
;
select * from drug_concept_stage where concept_name like '%Buclizine%';
select * from INGRED_TO_INGRED_FINAL_BY_LENA where concept_name_1 like '%Buclizine%';

select * from drug_concept_stage where concept_class_id ='Ingredient' and concept_code not in (select concept
;
select * from devv5.concept a
join devv5.drug_strength b on a.concept_id =b.drug_concept_id
where vocabulary_id = 'RxNorm' 
and a.invalid_reason is not null
;
select distinct DRUG_CODE,DRUG_NEW_NAME,CONCEPT_CODE_2,INGREDIENT_NAME from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_2 where a.drug_code like '%OMOP%' and concept_Code_2 is not null
union
select distinct DRUG_CODE,DRUG_NEW_NAME,CONCEPT_CODE_1,INGREDIENT_NAME from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' and concept_Code_2 is null
;
select distinct CONCEPT_CODE,CONCEPT_NAME,CONCEPT_CODE_2,CONCEPT_NAME_2 from drug_to_ingr
;
select * from pack_drug_to_code_2_1
;
select * from CLIN_DR_TO_DOSE_FORM where concept_code_1 like 'OMOP%'
;
select * from internal_relationship_stage where CONCEPT_CODE_2 like 'OMOP%'
;
select * from ds_stage where drug_CONCEPT_CODE = '395439003'
;
--there are 90 concepts don't have ds_stage info
select distinct CONCEPT_CODE_2, CONCEPT_NAME_2 from drug_concept_stage a
join Branded_to_clinical b on a.CONCEPT_CODE = b.CONCEPT_CODE_1
left join ds_stage c on c.drug_concept_code = b.concept_code_2
left join non_drug_full d  on d.concept_code = b.concept_code_2
left join pack_content e on e.PACK_CONCEPT_CODE = b.concept_code_2
 where a.concept_code not in (select drug_concept_code from ds_stage) and a.concept_class_id like '%Drug%' and a.concept_class_id not like '%Pack%'
 and a.invalid_reason is null and a.domain_id = 'Drug'
 ;
 --need to go throught branded to clinical and fix Tissel
 
 select * from drug_concept_stage where concept_code ='28989911000001108'
;
select * from clinical_to_ingred_tmp where CONCEPT_CODE_1 like 'OMOP%'  
;
clinical_to_ingred_tmp
;
select distinct DRUG_CODE, INGREDIENT_NAME from PACK_DRUG_TO_CODE_2_2 
;
select distinct DRUG_CODE,DRUG_NEW_NAME,CONCEPT_CODE_2,INGREDIENT_NAME from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_2 where a.drug_code like '%OMOP%' and concept_Code_2 is not null
union
select distinct DRUG_CODE,DRUG_NEW_NAME,CONCEPT_CODE_1,INGREDIENT_NAME from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' and concept_Code_2 is null
--count  =25  
;
select distinct DRUG_CODE,DRUG_NEW_NAME,coalesce (CONCEPT_CODE_2, concept_code_1), coalesce (CONCEPT_name_2, concept_name_1) from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' 
union
select distinct DRUG_CODE,DRUG_NEW_NAME,CONCEPT_CODE_1,INGREDIENT_NAME from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' and concept_Code_2 is null
;


create table ds_omop as(
select distinct DRUG_CODE,DRUG_NEW_NAME,coalesce (CONCEPT_CODE_2, concept_code_1) as CONCEPT_CODE_2 , coalesce (CONCEPT_name_2, concept_name_1) as CONCEPT_name_2 from PACK_DRUG_TO_CODE_2_2 a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' 
) ;
update ds_omop
set DRUG_NEW_NAME = regexp_replace (DRUG_NEW_NAME, ' / ', '!')
;
--Packs present in ds_stage
select a.*, b.*, c.concept_name, d.concept_name, e.concept_name from pack_content a 
join ds_stage b on a.PACK_CONCEPT_CODE = b.DRUG_CONCEPT_CODE 
join drug_concept_stage c on a.PACK_CONCEPT_CODE = c.concept_code
join drug_concept_stage d on a.DRUG_CONCEPT_CODE = d.concept_code
join drug_concept_stage e on b.INGREDIENT_CONCEPT_CODE = e.concept_code
;
select b.*, c.concept_name, d.concept_name from
 ds_stage b 
join drug_concept_stage c on b.drug_concept_code= c.concept_code
join drug_concept_stage d on b.ingredient_concept_code = d.concept_code

where b.drug_concept_code in (select concept_code from drug_concept_stage where domain_id !='Drug') --782
;
select b.*, c.concept_name, d.concept_name from
 ds_stage b 
join drug_concept_stage c on b.drug_concept_code= c.concept_code
join drug_concept_stage d on b.ingredient_concept_code = d.concept_code

where b.drug_concept_code in (select concept_code from non_drug_full) --773
;
select b.*, c.concept_name, d.concept_name from
 ds_stage b 
join drug_concept_stage c on b.drug_concept_code= c.concept_code
join drug_concept_stage d on b.ingredient_concept_code = d.concept_code
where b.drug_concept_code in (select concept_code from drug_concept_stage where domain_id !='Drug') --782
;
select * from drug_concept_stage where domain_id !='Drug' and concept_class_id = 'Clinical Drug' 
and concept_code in (select drug_concept_code from ds_stage)
;
select * from drug_concept_stage where concept_code='30962611000001107'
;
select * from devv5.drug_strength where rownum < 10
;
select * from lost_ingr_to_rx_with_OMOP
;
select regexp_substr ('1hour', '(g|dose|ml|mg|ampoule|litre|hour(s)*|h*|square cm|microlitres)$') from dual
;
select * from drug_concept_stage where concept_code = '32518911000001103'
;
select * from concept
;
select * from devv5.drug_strength_stage
;
insert /*+ APPEND */ into drug_strength_stage
-- dedup same ingredient in product and sum up the amounts
select drug_concept_code, vocabulary_id_1, ingredient_concept_code, vocabulary_id_2,
  sum(amount_value) as amount_value,
  amount_unit_concept_id,
  sum(numerator_value) as numerator_value,
  numerator_unit_concept_id,
  sum(denominator_value) as denominator_value,
  denominator_unit_concept_id, valid_start_date, valid_end_date, invalid_reason
  ;
 select * from  devv5.concept where concept_name like '%Pack%' and vocabulary_id = 'RxNorm' and concept_class_id= 'Branded Pack' and rownum < 100
 join concept_relatinship r on r,co
 ;
 select * from  devv5.concept a
  join devv5.concept_relationship b on a.concept_id=concept_id_2 
  join devv5.concept c on concept_id_2=c.concept_id 
  where a.vocabulary_id = 'RxNorm' and a.concept_class_id= 'Branded Pack'
    and c.concept_class_id = 'Brand Name';
    
select * from drug_concept_stage where concept_name like 'Generic%' 
and concept_class_id = 'Clinical Drug' and domain_id ='Drug'
;

  select distinct a.concept_class_id
  --a.concept_code as concept_code_1, a.concept_name as concept_name_1 , d.concept_code, d.concept_name 
  from drug_concept_stage  a
join concept c on a.concept_code = c.concept_code and c.vocabulary_id = 'SNOMED' 
 join concept_relationship r on r.concept_id_1 = c.concept_id 
 join concept d on r.concept_id_2 = d.concept_id and d.vocabulary_id = 'ATC'
;

Clinical_to_Ingred_tmp -- here is one component

drop table clin_dr_to_ingr_one;
create table clin_dr_to_ingr_one as 
select distinct a.*, concept_code_2 as ingredient_concept_code, concept_name_2 as ingredient_concept_name, insert_id_2 from drug_concept_stage_tmp_0 a join Clinical_to_Ingred_tmp  b on 
 a.concept_code = b.concept_code_1
where b.concept_code_1 in 
(
select concept_code_1 from Clinical_to_Ingred_tmp group by concept_code_1 having count (1) = 1)
;
select * from clin_dr_to_ingr_one a join drug_concept_stage_tmp_0 b on a.CONCEPT_CODE = b.CONCEPT_CODE and b.INGR_CNT >1
;
select * from ingred_to_ingred_FINAL_BY_Lena where concept_code_2 = '18288009'
;
select * from Clinical_to_Ingred where CONCEPT_CODE_2 = '18288009'
;
select * from devv5.concept where concept_name  like '%Factor VIII%' and vocabulary_id = 'RxNorm'
;
select * from devv5.concept where upper (concept_name) like  '%VON WILLEBRAND FACTOR%' and vocabulary_id = 'RxNorm'
;
select regexp_substr ('1million unit/hours gsfgds' ,
 '[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)*') as dosage
from dual
;
select * from drug_concept_stage where lower ( concept_name) = 'chewable tablets'
;
select * from aut_form_mapped_noRx_pack
;
select * from 
concept_relationship crs 
RIGHT JOIN concept cs ON cs.concept_id=crs.concept_id_1
RIGHT JOIN concept cs2 ON crs.concept_id_2=cs2.concept_id
WHERE crs.concept_id_1 IS NULL AND crs.concept_id_2 IS NULL and cs2.vocabulary_id='RxNorm' and cs2.invalid_reason is null
;
select * 
from devv5.concept a join
devv5.concept_relationship b on b.concept_id_2 =  a.concept_id 
join  devv5.concept c on b.concept_id_1 = c.concept_id and c.concept_class_id like '%Drug%'
where a.concept_class_id ='Ingredient' --and b.RELATIONSHIP_ID = 'Has brand name' 
and a.vocabulary_id = 'RxNorm' and c.vocabulary_id = 'DPD'
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

select * 
from devv5.concept a join
devv5.concept_relationship b on b.concept_id_2 =  a.concept_id 
join  devv5.concept c on b.concept_id_1 = c.concept_id and c.concept_class_id like '%Drug%'
where a.concept_class_id ='Dose Form'-- and b.RELATIONSHIP_ID = 'RxNorm has ing' 
and a.vocabulary_id = 'RxNorm' and c.vocabulary_id = 'RxNorm'
and 
;

select * from Clinical_to_Ingred_tmp where concept_code_1 like '17874611000001107'
;
--Missing relationship to Dose Form
select distinct a.* from drug_concept_stage a where concept_class_id like '%Drug%' and concept_class_id not like '%Comp%' and concept_code not in(
select a.concept_code from  drug_concept_stage a 
join internal_relationship_stage s on s.concept_code_1= a.concept_code  
join drug_concept_stage b on b.concept_code = s.concept_code_2
 and  a.concept_class_id like '%Drug%'  and b.concept_class_id ='Dose Form'
)
and domain_id = 'Drug' and a.concept_class_id not like '%Pack%' and invalid_reason is null and concept_class_id = 'Clinical Drug'
;
select * from ds_all_tmp where INGREDIENT_CONCEPT_CODE is null
;
select * from nondrug_with_ingr where DRUG_CONCEPT_CODE like '%dressing%'
;
select count(*) from concept_relationship r
join concept a on a.concept_id = r.concept_id_1 and a.vocabulary_id = 'DPD'
join concept b on b.concept_id = r.concept_id_2 and b.vocabulary_id = 'RxNorm'
where a.concept_class_id != b.concept_class_id
and relationship_id ='Maps to'
;
select *  from drug_concept_stage where trim(lower(concept_name)) in (
    select trim(lower(concept_name)) as n from drug_concept_stage where concept_class_id in ('Brand Name', 'Dose Form', 'Unit', 'Ingredient') group by trim(lower(concept_name)) having count(8)>1)
    ;
    select * from concept
    ;
   --1
 select * from drug_concept_Stage a 
 join ds_stage b on a.concept_code = b.drug_concept_code 
 where regexp_like (concept_name, '\d+ ampoule')
 and box_size is  null
;
--2
 select count (*) from drug_concept_Stage a 
 join ds_stage b on a.concept_code = b.drug_concept_code 
 where regexp_like (concept_name, '\d+(ml||g|l)') and not regexp_like (concept_name, '/\d+(ml|l|g)')
 and denominator_value is null
 ;
 --2
 select *from drug_concept_Stage a 
 join ds_stage b on a.concept_code = b.drug_concept_code 
 where regexp_like (concept_name, '\d+(litre|ml)') and not regexp_like (concept_name, '/\d+(litre|ml)')
 and denominator_value is null
 ;
 select CONCEPT_CODE_1, CONCEPT_CODE_2, CONCEPT_ID_1, CONCEPT_ID_2, z.INVALID_REASON, RELATIONSHIP_ID, z.VALID_END_DATE, z.VALID_START_DATE, VOCABULARY_ID_1, VOCABULARY_ID_2, a.concept_name, b.concept_name from concept_relationship_stage z

join concept a on a.concept_code = concept_code_1 and a.vocabulary_id = 'RxNorm'
join concept b on b.concept_code = concept_code_2
where concept_code_1 ='1000126' 

-- group by CONCEPT_CODE_1, CONCEPT_CODE_2, CONCEPT_ID_1, CONCEPT_ID_2, INVALID_REASON, RELATIONSHIP_ID, VALID_END_DATE, VALID_START_DATE, VOCABULARY_ID_1, VOCABULARY_ID_2
 --having count (1) > 1
 ;
 select * from drug_concept_stage where concept_class_id = 'Clinical Drug' 
 ;
select max ( cast ( regexp_substr (concept_code, '\d+') as int))
from devv5.concept
where concept_code like 'OMOP%' and  concept_code not like 'OMOP %'
;
select * from concept_relationship_stage a 
join concept_stage  b on a.concept_code_1 = b.concept_code
join concept_stage c on a.concept_code_2 = c.concept_code
 where vocabulary_id_1 = 'Gemscript' and b.concept_class_id = 'Gemscript THIN' and vocabulary_id_2 !='RxNorm Extension'
and C.standard_CONCEPT IS NOT NULL
 ;

 ;
 select a.*, b.standard_concept from concept_relationship_stage a
join concept_stage b on a.concept_code_2 = b.concept_code
 where concept_code_1 =
 '99947994'
 ;
 select * from concept_stage where concept_code in ('48185020')
 ;
 select * from 
;
select * from concept_relationship_stage where vocabulary_id_2 ='RxNorm Extension' and vocabulary_id_1 ='dm+d'  and RELATIONSHIP_ID ='Maps to' and c
;
select * from concept_relationship_stage where concept_code_1 is null
;
 --'324727008'
 select distinct RELATIONSHIP_ID from concept_rel_stage_no_RxE where concept_code_2 =' '
 ;
select  from concept_Stage where concept_code =' '
 ;
 select max (cast (regexp_substr(concept_code, '\d+') as int)) from drug_concept_stage where concept_code like 'OMOP%'
 ;
 select * from drug_concept_stage where concept_code = 'OMOP252850'
 ;
 select count (1)/* distinct RELATIONSHIP_ID*/ from dev_amis.concept_relationship_stage where concept_code_2 =' '
 ;
  select * from concept_relationship_stage a
  join concept_Stage b on a.concept_code_1 = b.concept_code
where concept_code_2 =' '
;
  select * from concept_relationship_stage a
    join concept_Stage b on a.concept_code_1 = b.concept_code
    join concept c on a.concept_code_2 = c.concept_code
    where b.concept_class_id like '%Drug%'
    and c.concept_class_id = 'Ingredient'
    ;
      select * from dev_amis.concept_relationship_stage a
    join dev_amis.concept_Stage b on a.concept_code_1 = b.concept_code
    join dev_amis.concept c on a.concept_code_2 = c.concept_code
    where c.concept_class_id like '%Drug%'
    and b.concept_class_id = 'Ingredient'
    ;
    delete from concept_relationship_stage where concept_code_2 =''
    ;
    
    
  select dump(concept_code_2) from dev_dmd.concept_relationship_stage where concept_code_1='48185020'
union all
select dump(concept_code_1) from dev_dmd.concept_relationship_stage where concept_code_1='5680811000001101'
;
select concept_code_2 from dev_dmd.concept_relationship_stage where concept_code_1='48185020'
;
select concept_code_1 from dev_dmd.concept_relationship_stage where concept_code_1='5680811000001101'
;
select regexp_substr ('OMOP12354', '[[:alpha:]]*\d*') from dual
;
update concept_stage set concept_code = regexp_substr('concept_code', '[[:alpha:]]*\d*')
;
select concept_code,regexp_substr(concept_code, '[[:alpha:]]*\d*')  from concept_stage where concept_code!=regexp_substr(concept_code, '[[:alpha:]]*\d*')
;
select concept_code_2,regexp_substr(concept_code_2, '[[:alpha:]]*\d*')  from concept_relationship_stage 
;
/*
update concept_relationship_stage set concept_code_2=regexp_substr(concept_code_2, '[[:alpha:]]*\d*')
where concept_code_2!=regexp_substr(concept_code_2, '[[:alpha:]]*\d*') and vocabulary_id_2 !='ATC'
*/
;
select * from concept_relationship_stage a 
join concept_relationship_stage b
where a.vocabulary_id_2 like 'RxNorm%'
;
select * from drug_strength_stage  where numerator_value is not null  and DENOMINATOR_UNIT_CONCEPT_ID is null and denominator_value is null;

select * from ds_stage where numerator_value is not null and DENOMINATOR_UNIT is null and denominator_value is null;

select * from concept_stage where concept_code='OMOP274793'
;
select * from existing_ds where 
;
select * from drug_strength_stage 
;
select * from concept where concept_code ='K07.6'
;
select * from concept_relationship_stage where vocabulary_id_1 = 'Gemscript'
--delete mappings to non-standard concepts
;
--check 
select
 distinct cs.concept_class_id 
 from concept_relationship_stage a
join concept_stage b on b.concept_code = a.concept_code_1
join concept_stage cs on cs.concept_code = a.concept_code_2
 where a.vocabulary_id_1 ='dm+d'-- and a.vocabulary_id_2 like 'RxNorm%' 
and  a.relationship_id in  ('Has standard ing') --and b.concept_class_id = 'Ingredient'
;
select * from concept_stage where concept_code in (
select cs.concept_code
from concept_stage cs 
LEFT JOIN concept_relationship_stage crs ON crs.CONCEPT_CODE_1=cs.concept_code and crs.RELATIONSHIP_ID in('Marketed form of',  'Maps to', 'Concept replaced by')
WHERE cs.concept_class_id like 'Marketed%' GROUP BY cs.concept_code HAVING count(distinct crs.rowid) != 1
)
;
select distinct relationship_id from concept_relationship_stage
;
select count (*) from concept_stage a 
left join concept_relationship_stage b on a.concept_code = b.concept_code_1 and RELATIONSHIP_ID  ='Has standard form'
where a.concept_class_id like '%Form%' 
and a.vocabulary_id = 'RxNorm Extension'
and b.concept_code_1 is null 
;
select count (*) from concept_stage a 
left join concept_relationship_stage b on a.concept_code = b.concept_code_1 and RELATIONSHIP_ID  ='RxNorm has ing'
where a.concept_class_id like '%Branded%' and domain_id = 'Drug' and a.invalid_reason is null
and a.vocabulary_id = 'RxNorm Extension'
and b.concept_code_1 is not null 
;
select count (*) from concept_stage_no_rxe a 
left join concept_rel_stage_no_rxe b on a.concept_code = b.concept_code_1 and RELATIONSHIP_ID  ='RxNorm has dose form'
where a.concept_class_id like '%Form%' 
and a.vocabulary_id = 'dm+d'
and b.concept_code_1 is not null 
;
select * from concept_rel_stage_no_rxe where RELATIONSHIP_ID  ='RxNorm has dose form'
;
select * from concept_rel_stage_no_rxe where RELATIONSHIP_ID  ='RxNorm ing of' and vocabulary_id_2 = 'RxNorm'
;
select count (*) from concept_stage_no_rxe a 
left join concept_rel_stage_no_rxe b on a.concept_code = b.concept_code_1 and RELATIONSHIP_ID  ='RxNorm has ing'
where a.concept_class_id like '%Branded%'  and domain_id = 'Drug' and a.invalid_reason is null
and a.vocabulary_id = 'dm+d'
and b.concept_code_1 is  null 
;
select count (*) from concept_stage a 
left join concept_relationship_stage b on a.concept_code = b.concept_code_1 and RELATIONSHIP_ID  ='Has supplier'
where a.concept_class_id like '%Marketed%' and domain_id = 'Drug' and a.invalid_reason is null
and a.vocabulary_id = 'RxNorm Extension'
and b.concept_code_1 is  null
;
select count (*) from concept_stage a 
left join concept_relationship_stage b on a.concept_code = b.concept_code_1 and RELATIONSHIP_ID  ='Has supplier'
where a.concept_class_id like '%Marketed%' and domain_id = 'Drug' and a.invalid_reason is null
and a.vocabulary_id = 'RxNorm Extension'
and b.concept_code_1 is  null
;
select * from concept_relationship_stage where vocabulary_id_1 = 'RxNorm' and vocabulary_id_2 = 'RxNorm'
;
select *  from drug_strength_stage where vocabulary_id_1 = 'RxNorm' 
;
select *  from drug_strength_stage where concept_code_2 = '374445'
;
select * from concept_stage where concept_class_id like '%Pack%'
;
select * from drug_concept_stage where concept_code='100011000001108';
select * from ds_s
;
--proper relationship to/for units
select * from relationship_to_concept  rc where concept_code_1 not in (select concept_CODE FROM DRUG_CONCEPT_STAGE)
;
select concept_code_1 from relationship_to_concept  rc 
JOIN DRUG_CONCEPT_STAGE ON concept_code_1 = concept_code AND CONCEPT_CLASS_ID = 'Unit'
--where concept_code_1 not in (select concept_CODE FROM DRUG_CONCEPT_STAGE)
minus select AMOUNT_UNIT from UNIT_FOR_UCUM
;
select * from relationship_to_concept_2706 where concept_code_1 not in (select concept_code_1 from relationship_to_concept)
;
select * from unit_for_ucum where AMOUNT_UNIT ='c'
;
select * from unit_for_ucum where CONCEPT_ID_2 in ( '9325', '9324')
;
--
Select distinct concept_code, concept_name,ds_stage.*  from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+.*/[[:digit:]\.]+ml+') and invalid_reason is null
;

Select distinct concept_name, regexp_substr(concept_name , '(\d)+(\s)*(\%)+')  from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '(\d)+(\s)*(\%)+') and  invalid_reason is null
;
select * from ds_stage where drug_concept_code in (
Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '(\d)+(\s)*(\%)+') and  invalid_reason is null
)
;
--update ds_stage for those having incorrectly parsed dosages
select a.concept_name, a.concept_class_id, b.* from drug_concept_stage a
join ds_stage b on a.concept_code = b.drug_concept_code
where regexp_like (concept_name , '[[:digit:]\.]+.*/ml.*ml')
and not regexp_like (concept_name , '[[:digit:]\.]+.*/ml.*[[:digit:]\.]+ml')
and concept_class_id = 'Clinical Drug'
and rownum < 100
;
select * from ds_stage
join drug_concept_stage
on drug_concept_code=concept_Code  where drug_concept_code in (
Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+.*/[[:digit:]\.]+ml+') and invalid_reason is null
)
and drug_concept_code not in (Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where (numerator_value is not null or amount_value is not null) and concept_class_id='Clinical Drug')
;
select a.*, b.concept_name from ds_stage a 
join drug_concept_stage b 
on drug_concept_code=concept_Code  where drug_concept_code in (
Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+.*/[[:digit:]\.]+ml+') and invalid_reason is null
)
and drug_concept_code  in (Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where (numerator_value is not null or amount_value is not null) and concept_class_id='Clinical Drug')
;
select a.*, b.concept_name from ds_stage a 
join drug_concept_stage b 
on drug_concept_code=concept_Code  where drug_concept_code in (
Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and invalid_reason is null
)
and drug_concept_code  in (Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where (numerator_value is not null or amount_value is not null) and concept_class_id='Clinical Drug')
;
select a.*, b.concept_name from ds_stage a 
join drug_concept_stage b 
on drug_concept_code=concept_Code  where drug_concept_code in (
Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '(\d)+(\s)*(\%)+') and invalid_reason is null
)
and drug_concept_code not in (Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where (numerator_value is not null or amount_value is not null) and concept_class_id='Clinical Drug')
;
select distinct * from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and concept_name like '%Kallikrein inactivator%';
;
select * from ds_stage
join drug_concept_stage
on drug_concept_code=concept_Code  where drug_concept_code in (
Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+.*/[[:digit:]\.]+ml+') and invalid_reason is null
)
and drug_concept_code not in (Select distinct drug_concept_code from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where (numerator_value is not null or amount_value is not null) and concept_class_id='Clinical Drug')
;
select regexp_substr
('20million units', 
'[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres)*')  
from dual
;
select distinct concept_code, concept_class_id , invalid_reason,
concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id!='Clinical Drug' and concept_name like '%Bio-Biloba%' and invalid_reason is null;
;
select * from ds_all where concept_class_id = '14679411000001109'
;
select * from  
branded_to_clinical where concept_code_1  = '14679411000001109'
;
Select distinct concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id!='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+(mg)+') 
and drug_concept_code in (select drug_concept_code from ds_stage group by drug_concept_code having count(1)=1);
;
Select distinct concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id!='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+.*ml?/[[:digit:]]?(unit|litre)+');

Select distinct concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null  and regexp_like  (concept_name , '[[:digit:]\.]+.*/[[:digit:]\.]?drop+');

select distinct concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id!='Clinical Drug' and concept_name like '%Bio-Biloba%' and invalid_reason is null;
;
Select distinct concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id!='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+.*ml?/[[:digit:]]?(unit|litre)+')
;
Select distinct concept_name from ds_stage join drug_concept_stage
on drug_concept_code=concept_Code Where numerator_value is null and amount_value is null and concept_class_id!='Clinical Drug' and regexp_like (concept_name , '[[:digit:]\.]+(mg)+') and concept_class_id not like '%Pack%'
and drug_concept_code in (select drug_concept_code from ds_stage group by drug_concept_code having count(1)=1)
;
select * from drug_concept_stage where concept_name like '%actuation%'
;
select * from ds_stage where drug_concept_code = '29879711000001106'
;
select * from drug_concept_name where re
'[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm|million units| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol)/*[[:digit:]\,\.]*(actuation|application)*')
;
select * from ds_stage where drug_concept_code ='349392002'
; 
select  concept_class_id, count (1) from drug_concept_stage where source_concept_class_id is null group by concept_class_id;

select  * from drug_concept_stage_existing where concept_code like 'OMOP%'
--did I make changes???
;
select * from ingred_to_ingred_FINAL_BY_Lena where concept_code_1 like 'OMOP%'
;
select * from drug_concept_stage where concept_code like 'OMOP%' and concept_class_id = 'Ingredient'
;
select concept_code from drug_concept_stage group by concept_code having count (1) = 1
;
select distinct source_concept_class_id from drug_concept_stage;
;
select * from ds_stage a 
join drug_concept_stage b on drug_concept_code = b.concept_code
join drug_concept_stage c on ingredient_concept_code = c.concept_code
 where drug_concept_code  in ('16636811000001107', '16636911000001102', '15650711000001103', '15651111000001105' )
 ;
 slect * from drug_concept_stage
 ;
 select * from concept where concept_name like '%Rebif%'
 ;
  select * from drug_concept_stage where concept_name like '%Rebif%'
  ;
  select * from ds_stage a 
join drug_concept_stage b on drug_concept_code = b.concept_code
join drug_concept_stage c on ingredient_concept_code = c.concept_code
 where drug_concept_code  in ('16636811000001107', '16636911000001102')
 ;
 select * from PACK_DRUG_TO_CODE_2_2
 ;
 select * from pack_content where pack_concept_code in ('16636811000001107', '16636911000001102')
 ;
 select * from drug_concept_stage where concept_code ='OMOP251'
 ;
delete from ds_stage where coalesce (amount_unit, numerator_unit) is null and ingredient_concept_code = '3588811000001104'
;
select distinct DRUG_CODE,DRUG_NEW_NAME,coalesce (CONCEPT_CODE_2, concept_code_1) as CONCEPT_CODE_2 , coalesce (CONCEPT_name_2, concept_name_1) as CONCEPT_name_2
 from PACK_DRUG_TO_CODE_2_2 --!!! packs determined manually 
  a join INGRED_TO_INGRED_FINAL_BY_LENA b on a.ingredient_name=b.concept_name_1 where a.drug_code like '%OMOP%' 
  ;
  select * from PACK_DRUG_TO_CODE_2_2
  ;
  Rebif 8.8micrograms/0.1ml (2.4million units) with 22micrograms/0.25ml (6million units) solution for injection 1.5ml cartridges initiation pack (Merck Serono Ltd)
  ;
  select * from  
ds_all_tmp where INGREDIENT_CONCEPT_CODE in ('OMOP28664', 'OMOP28671')
;
  select * from  drug_to_ingr where concept_code_2 not in (Select concept_code from drug_concept_stage)
  ;
  select * from INGRED_TO_INGRED_FINAL_BY_LENA where concept_code_1 like 'OMOP%'
  ;
  select * from concept where concept_id =798336
  ;
   select distinct s.drug_concept_code, ingredient_concept_code ,a.concept_name,'ds_stage has ingredient_codes absent in drug_concept_stage' from ds_stage s 
  left join drug_concept_stage a on a.concept_code = s.drug_concept_code and a.concept_class_id like '%Drug%'
  left join drug_concept_stage b on b.concept_code = s.INGREDIENT_CONCEPT_CODE and b.concept_class_id = 'Ingredient'
  where b.concept_code is null 
  ;
  select * from ds_stage
join drug_concept_stage   on concept_code = drug_concept_code
 where numerator_unit = '%'
  ;
select * from (
  select 
    r.concept_code_1,
    nvl(ar.vocabulary_id, 'RxNorm Extension') as a_vocab,
    nvl(ar.concept_name, ad.concept_name) as a_name,
    nvl(ar.concept_class_id, ad.concept_class_id) as a_class,
    r.relationship_id,
    dd.concept_code,
    dd.concept_name as d_name,
    dd.concept_class_id as d_class
  from concept_relationship_stage r
  left join concept ar on ar.concept_code=r.concept_code_1 and ar.vocabulary_id='RxNorm' and r.vocabulary_id_1='RxNorm'
  left join concept_stage ad on ad.concept_code=r.concept_code_1 and r.vocabulary_id_1='RxNorm Extension'
  join concept_stage dd on dd.concept_code=r.concept_code_2
)
where rownum < 1000
;
select distinct A_VOCAB,A_CLASS,RELATIONSHIP_ID,D_CLASS from (
  select 
    r.concept_code_1,
    nvl(ar.vocabulary_id, 'RxNorm Extension') as a_vocab,
    nvl(ar.concept_name, ad.concept_name) as a_name,
    nvl(ar.concept_class_id, ad.concept_class_id) as a_class,
    r.relationship_id,
    dd.concept_code,
    dd.concept_name as d_name,
    dd.concept_class_id as d_class
  from concept_relationship_stage r
  left join concept ar on ar.concept_code=r.concept_code_1 and ar.vocabulary_id='RxNorm' and r.vocabulary_id_1='RxNorm'
  left join concept_stage ad on ad.concept_code=r.concept_code_1 and r.vocabulary_id_1='RxNorm Extension'
  join concept_stage dd on dd.concept_code=r.concept_code_2
)
--where rownum < 1000
;
select * from (
  select 
    r.concept_code_1,
    nvl(ar.vocabulary_id, 'RxNorm Extension') as a_vocab,
    nvl(ar.concept_name, ad.concept_name) as a_name,
    nvl(ar.concept_class_id, ad.concept_class_id) as a_class,
    r.relationship_id,
    dd.concept_code,
    dd.concept_name as d_name,
    dd.concept_class_id as d_class
  from concept_relationship_stage r
  left join concept ar on ar.concept_code=r.concept_code_1 and ar.vocabulary_id='RxNorm' and r.vocabulary_id_1='RxNorm'
  left join concept_stage ad on ad.concept_code=r.concept_code_1 and r.vocabulary_id_1='RxNorm Extension'
  join concept_stage dd on dd.concept_code=r.concept_code_2
)
where a_class is null
;
select * from drug_concept_stage where concept_code = '391873006'
;
;
select * from concept_stage where concept_code = '391873006'
;
select * from relationship_to_concept where concept_code_1  = '350576006'
;
select   count (1) from drug_concept_Stage where concept_code not in (Select concept_code from concept_stage)
;
select * from concept_stage where vocabulary_id = 'RxNorm Extension' and  concept_code  not like 'OMOP%' and  concept_code  not like 'XXX%'
;
select * from concept_stage where vocabulary_id = 'dm+d' --and  concept_code  not like 'OMOP%' and  concept_code  not like 'XXX%'
;
select * from (
  select 
    r.concept_code_1,
    nvl(ar.vocabulary_id, 'RxNorm Extension') as a_vocab,
    nvl(ar.concept_name, ad.concept_name) as a_name,
    nvl(ar.concept_class_id, ad.concept_class_id) as a_class,
    r.relationship_id,
    dd.concept_code,
    dd.concept_name as d_name,
    dd.concept_class_id as d_class
  from concept_relationship_stage r
  left join concept ar on ar.concept_code=r.concept_code_1 and ar.vocabulary_id='RxNorm' and r.vocabulary_id_1='RxNorm'
  left join concept_stage ad on ad.concept_code=r.concept_code_1 and r.vocabulary_id_1='RxNorm Extension'
  join concept_stage dd on dd.concept_code=r.concept_code_2
) a  join concept_stage  cs on cs.concept_code  = a.concept_code and  a_class = 'Dose Form' 
where cs.concept_class_id like '%Drug%' 
and rownum < 300
;

select distinct d_class from (
  select 
    r.concept_code_1,
    nvl(ar.vocabulary_id, 'RxNorm Extension') as a_vocab,
    nvl(ar.concept_name, ad.concept_name) as a_name,
    nvl(ar.concept_class_id, ad.concept_class_id) as a_class,
    r.relationship_id,
    dd.concept_code,
    dd.concept_name as d_name,
    dd.concept_class_id as d_class
  from concept_relationship_stage r
  left join concept ar on ar.concept_code=r.concept_code_1 and ar.vocabulary_id='RxNorm' and r.vocabulary_id_1='RxNorm'
  left join concept_stage ad on ad.concept_code=r.concept_code_1 and r.vocabulary_id_1='RxNorm Extension'
  join concept_stage dd on dd.concept_code=r.concept_code_2
)
;
select * from ds_stage 
join drug_concept_stage on concept_code = drug_concept_code
where drug_concept_code in (
  select drug_concept_code from (
  select drug_concept_code, ingredient_concept_code, count(*) as cnt
  from ds_stage 
  group by drug_concept_code, ingredient_concept_code having count(*)>1))
  ;
    select * from relationship_to_concept r 
  join drug_concept_stage a on a.concept_code= r.concept_code_1 
  left join devv5.concept c on c.concept_id = r.concept_id_2  
  where  c.concept_name is  null
  and a.domain_id = 'Drug'
  ;
  select * from concept where concept_name ='Implant'
  ;
   select * from concept where concept_id = '721656'
   ;
     select a.drug_concept_code, 'different dosage for the same drug-ingredient combination' 
  from ds_stage a join ds_stage b on a.drug_concept_code = b.drug_concept_code and a.INGREDIENT_CONCEPT_CODE = b.INGREDIENT_CONCEPT_CODE and (
  a.numerator_value != b.numerator_value or a.numerator_unit != b.numerator_unit or a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE or a.DENOMINATOR_unit != b.DENOMINATOR_unit
  or a.numerator_value is null and  b.numerator_value is not null or a.numerator_unit is null and  b.numerator_unit is not null or a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null or 
  a.DENOMINATOR_unit is null and b.DENOMINATOR_unit is not null
  )
  ;
      select * from ds_stage s 
  left join drug_concept_stage a on a.concept_code = s.drug_concept_code and a.concept_class_id like '%Drug%'
  left join drug_concept_stage b on b.concept_code = s.INGREDIENT_CONCEPT_CODE and b.concept_class_id = 'Ingredient'
  where b.concept_code is null
  ;
  select * from ds_stage
  join drug_concept_stage  on concept_code = drug_concept_code 
 where INGREDIENT_CONCEPT_CODE is null
 ;
 select * from ds_omop where DRUG_CODE  = '4673811000001105'
 ;
 select * from  ds_all where concept_CODE  = 4673911000001100
 ;
 select * from drug_concept_stage where lower (concept_name) = 'triprolidin' 
 ;
 select * from ds_all where ingredient_concept_code = 'OMOP11'
 ;
 select * from concept where upper (concept_name) like '%DONEPEZIL%10%' and vocabulary_id = 'RxNorm'
 ;
 select * from dev_bdpm.relationship_to_concept 
join concept on concept_id =concept_id_2
where concept_code_1= '33803'
;
select a.concept_name, b.concept_name, drug_strength.*  from drug_strength 
join concept a on ingredient_concept_id  = a.concept_id
join concept b  on drug_concept_id = b.concept_id
where drug_concept_id  = 40223770
;
select * from concept where concept_id  = 715997
; 
 select distinct * from drug_concept_stage a 
  join internal_relationship_stage s on a.concept_code = s.concept_code_1
  join drug_concept_stage b on b.concept_code =s.concept_code_2
  and b.concept_class_id = 'Dose Form'
  where a.concept_code in (
  select a.concept_code from drug_concept_stage a 
  join internal_relationship_stage s on a.concept_code = s.concept_code_1
  join drug_concept_stage b on b.concept_code =s.concept_code_2
  and b.concept_class_id = 'Dose Form'
  group by a.concept_code having count(1) >1)
  ;
    select distinct *
   from ds_stage a join ds_stage b on a.drug_concept_code = b.drug_concept_code 
   and (a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null  
   or a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE
   or a.DENOMINATOR_unit != b.DENOMINATOR_unit)
   ;
     select distinct DRUG_CONCEPT_CODE
   from ds_stage a join ds_stage b on a.drug_concept_code = b.drug_concept_code 
   join drug_concept_stage dd on dd.concept_code = a.drug_concept_code
   and (a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null  
   or a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE
   or a.DENOMINATOR_unit != b.DENOMINATOR_unit)
   ;
   select ds_stage.*, concept_name from ds_stage 
join drug_concept_stage on drug_concept_code = concept_code 
where drug_concept_code in (
   select distinct a.drug_concept_code
   from ds_stage a join ds_stage b on a.drug_concept_code = b.drug_concept_code 
   join drug_concept_stage dd on dd.concept_code = a.drug_concept_code
   and (a.DENOMINATOR_VALUE is null and b.DENOMINATOR_VALUE is not null  
   or a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE
   or a.DENOMINATOR_unit != b.DENOMINATOR_unit)
   )
;
select * from  ds_stage ds
join drug_concept_stage on drug_concept_code = concept_code
-- set amount_value = denominator_value , amount_unit = denominator_unit, denominator_value = '', denominator_unit = ''
where exists (select 1 from 
internal_relationship_stage ir  
join drug_concept_stage c on c.concept_code = ir.concept_code_2
join drug_concept_stage c1 on c1.concept_code = ir.concept_code_1 and c.concept_class_id = 'Dose Form'
join (select drug_concept_code from ds_stage group by drug_concept_code having count (1) =1) z on ir.concept_code_1 = z.drug_concept_code

 where amount_value is null and numerator_value is null and denominator_value is not null
 and c.concept_code in
 ( --all solid forms
 '3095811000001106',
'385049006',
'420358004',
'385043007',
'385045000',
'85581007',
'421079001',
'385042002',
'385054002',
'385052003',
'385087003'
)
and  ir.concept_code_1 = ds.drug_concept_code)
;
SELECT * FROM internal_relationship_stage ir  
join drug_concept_stage c on c.concept_code = ir.concept_code_2
join drug_concept_stage c1 on c1.concept_code = ir.concept_code_1 and c.concept_class_id = 'Dose Form'
WHERE C1.CONCEPT_CODE = '28048111000001100'
;
create table ingr_comb as 
select distinct c.concept_id, listagg(c2.cocnept_id, '-') as ing_combo_id within group (order by c.concept_id) as ing_code 
from concept c 
join concept_relationship r
join concept c2 on c2.concept_id = r.concept_id_2 
where c.vocabulary_id like 'RxNorm%'
and c.vocabulary_id like 'RxNorm%'
;

select c1.concept_code as c1_code, c1.concept_name as c1_name, c1.concept_class_id as c1_class,
  c2.concept_code as c2_code, c2.concept_name as c2_name, c2.vocabulary_id as c2_vocab, c2.concept_class_id as c2_class,
  r.precedence as prec, r.conversion_factor as fac
from drug_concept_stage c1
join relationship_to_concept r on r.concept_code_1=c1.concept_code 
join concept c2 on c2.concept_id=r.concept_id_2
where c1.concept_code in ('12227711000001101', '4218111000001103');

select * from devv5.concept where concept_id ='990499'
;

select concept_name from devv5.concept where vocabulary_id = 'RxNorm Extension' group by concept_name having count (1) >1
;
select * from drug_concept_stage where concept_name = 'Injectable'
;
select * from ds_stage where denominator_unit ='g' and rownum < 100
;
select * from complete_ds where drug_concept_code ='XXX121646'
;
select * from relationship_to_concept where concept_id_2 = 8576
;
select * from unique_ds where numerator_value = 1000
;
select * from complete_ds where drug_concept_code ='XXX131811'
;
select * from complete_name where concept_code = 'XXX131811'
;
select * from drug_concept_stage where lower (concept_name) like '%benzoyl%'
;
select * from ds_stage where drug_concept_code ='3738011000001100'
;
select * from devv5.concept where domain_id = 'Route'
;
select * from unique_ds where numerator_value =
;
select * from relationship_to_concept where upper( concept_code_1 )= 'G'
;
select * from ds_stage where numerator_unit ='%'
;
select * from concept where concept_id = 8554
;
select * from devv5.concept where  vocabulary_id = 'RxNorm' and concept_name like '%\%%' escape '\'; select * from devv5.drug_strength where drug_concept_id = 40003190;
;
select * from devv5.concept where concept_id = 1943955
;
select * from 
select * from devv5.vocabulary where vocabulary_id ='dm+d'
 
drug_concept_stage_existing 
;
select * from dev_dmd.drug_concept_stage where concept_name like 'Powder'
;
select * from internal_relationship_stage
join drug_concept_stage on concept_code = concept_code_1

 where concept_code_2='85581007'
 ;
 select * from relationship_to_concept 
 join concept on concept_id = concept_id_2
 where concept_code_1='85581007'
 ;
 select c1.concept_code as c1_code, c1.concept_name as c1_name, c1.concept_class_id as c1_class,
  c2.concept_code as c2_code, c2.concept_name as c2_name, c2.vocabulary_id as c2_vocab, c2.concept_class_id as c2_class,
  r.precedence as prec, r.conversion_factor as fac
from drug_concept_stage c1
join relationship_to_concept r on r.concept_code_1=c1.concept_code 
join concept c2 on c2.concept_id=r.concept_id_2
where c1.concept_code in ('litre');
 
select r.*, c.* from relationship_to_concept r
join concept c on concept_id = concept_id_2
join drug_concept_stage dc on dc.concept_code = r.concept_code_1 and dc.concept_class_id ='Unit'
; 
 --where concept_code_1 = 'litre'
;
select * from concept where lower (concept_name ) like '%kilounit%' and vocabulary_id = 'UCUM'
;
select * from ds_stage where drug_concept_code in ('19807111000001106');

select * from drug_concept_Stage where concept_code  in ('19807311000001108');

select * from branded_to_clinical where concept_code_1  in ('19807311000001108');

select * from ds_omop_0 where DRUG_CODE in ('19807111000001106')
;
select * from ds_all_tmp where CONCEPT_CODE = '19807111000001106'
;
select * from ds_all_cl_dr where CONCEPT_CODE_1
  in ('19807111000001106');
  
select * from BOX_TO_DRUG where CONCEPT_CODE_1    in ('19807111000001106');

select * from
 Box_to_Drug a 
join ds_all b on a.concept_code_2 = b.concept_code 
where a.AMOUNT_VALUE is not null
and b.AMOUNT_VALUE is null and numerator_unit !='%' and (a.amount_unit = b.denominator_unit or a.amount_unit in ('ml', 'g') and b.denominator_unit in ('ml', 'g') or b.denominator_unit is null )
;
select * from drug_concept_stage_tmp_0 where concept_code = '353186000'
;
select * from drug_concept_stage_tmp_0 where drug_comp like '%/%' and dosage not like '%/%'
;
select regexp_substr 
('Polymyxin B 10,000units/g', 
'[[:digit:]\,\.]+(mg|%|ml|mcg|hr|hours|unit(s?)|iu|g|microgram(s*)|u|mmol|c|gm|litre|million unit(s?)|nanogram(s)*|x|ppm|million units| Kallikrein inactivator units|kBq|microlitres|MBq|molar|micromol)/*[[:digit:]\,\.]*(g|dose|ml|mg|ampoule|litre|hour(s)*|h|square cm|microlitres|unit dose|drop)*') as dosage
from dual
;
--duplicate names in RxNorm Extension
select concept_name from dev_dmd.concept_stage where vocabulary_id = 'RxNorm Extension' group by concept_name having count (1) >1
;
select * from concept where concept_id = 19054265
;

SElect * from concept where lower (concept_name ) like '%renitec%' and vocabulary_id = 'RxNorm'
;
SElect * from drug_concept_stage where lower (concept_name ) like '%rantec%'-- and vocabulary_id = 'RxNorm'
;
select * from relationship_to_concept where concept_code_1 ='OMOP247684'
;
select * from concept where concept_id in (19017203, 19037558);
;
select * from concept where concept_name = 'penicillin G procaine'
;
select * from drug_strength where drug_concept_id in (19017203, 19037558)
;
select * from concept where concept_id not in (select concept_id_1 from concept_relationship where relationship_id = 'Marketed form of')
and vocabulary_id ='RxNorm Extension' and concept_class_id ='Marketed Product' and concept.invalid_reason is null and concept.standard_concept is not null
;
--duplicate names in RxNorm Extension
select concept_name, invalid_reason from concept where vocabulary_id = 'RxNorm Extension' group by concept_name, invalid_reason having count (1) >1
;
--not all Branded Products have 'Tradename of' relationship
select * from concept where concept_id not in (select concept_id_1 from concept_relationship where relationship_id = 'Tradename of')
and vocabulary_id ='RxNorm Extension' and concept_class_id like '%Branded%' and concept.invalid_reason is null and concept.standard_concept is not null
;
select * from dev_dmd.concept where lower (concept_name) like '%timolol%/%dorzolamide%'
and vocabulary_id = 'RxNorm Extension'
;
select * from dev_dmd.concept where lower (concept_name) like '%dorzolamide%/%timolol%'
and vocabulary_id like 'RxNorm%'
;
select * from concept where concept_name like '% / %' and vocabulary_id ='RxNorm' and invalid_reason is null
; 
select * from concept where concept_name like '% / %' and vocabulary_id ='RxNorm Extension' and invalid_reason is null and rownum < 100
;
select * from concept c1
 join drug_strength ds1 on c1.drug_concept_id = ds1.concept_id
 join drug_strength ds2 using (INGREDIENT_CONCEPT_ID,nvl (AMOUNT_VALUE, ' '),nvl (AMOUNT_UNIT_CONCEPT_ID, ' '), nvl (NUMERATOR_VALUE, ' '),nvl (NUMERATOR_UNIT_CONCEPT_ID, ' '),
 nvl (DENOMINATOR_VALUE, ' '),nvl (DENOMINATOR_UNIT_CONCEPT_ID, ' '),nvl (BOX_SIZE, ' '))
 join concept c2 on c2.concept_name != c1.concept_name and c2.concept_id = ds2.drug_concept_id
where c1.vocabulary_id like 'RxNorm%' and c2.vocabulary_id like 'RxNorm%'
;
create table dupl_attrib as
select distinct c1.*, c2.concept_id as concept_id_2, c2.concept_name as concept_name_2, c2.vocabulary_id as vocabulary_id_2,c2.invalid_reason as invalid_reason_2 from concept c1 
join ri_agg ri1  on ri1.CONCEPT_ID_1 = c1.CONCEPT_ID  
join ri_agg ri2 on ri1.INGRED_COMBO  = ri2.INGRED_COMBO
 join concept c2 on c2.concept_id  = ri2.concept_id_1
left join ds_agg ds1 on ds1.drug_concept_id = c1.concept_id
left join ds_agg ds2 on  ds1.INGRED_COMBo = ds2.INGRED_COMBo and
 nvl(ds1.AMOUNT_COMBO, 0) = nvl(ds2.AMOUNT_COMBO, 0) and
nvl( ds1.DOSE_COMBO, 0) = nvl( ds2.DOSE_COMBO, 0) and
nvl( ds1.DENOMINATOR_VALUE, 0) = nvl (ds2.DENOMINATOR_VALUE, 0) and
nvl( ds1.DENOMINATOR_UNIT_CONCEPT_Id, 0)=nvl (ds2.DENOMINATOR_UNIT_CONCEPT_Id, 0) and
nvl( ds1.BOX_SIZE, 0)= nvl (ds2.BOX_SIZE, 0)
left   join cnc_rel_class r1 on r1.CONCEPT_ID_1 = c1.CONCEPT_ID and r1.CONCEPT_CLASS_ID_2 = 'Dose Form'
left  join cnc_rel_class r2 on r2.CONCEPT_ID_1 = c2.CONCEPT_ID and r2.CONCEPT_CLASS_ID_2 = 'Dose Form' and nvl (r1.concept_id_2, 1)  = nvl (r2.concept_id_2, 1)

left  join cnc_rel_class rb2 on r2.CONCEPT_ID_1 = c2.CONCEPT_ID and rb2.CONCEPT_CLASS_ID_2 = 'Brand Name' and nvl ( rb1.concept_id_2, 1)  = nvl (rb2.concept_id_2, 1) 
   where c1.vocabulary_id like 'RxNorm%' and c2.vocabulary_id like 'RxNorm%' and lower (c2.concept_name) != lower (c1.concept_name)
;
select * from ds_agg
;
--Clinical Drug Form
select distinct c1.*, c2.concept_id as concept_id_2, c2.concept_name as concept_name_2, c2.vocabulary_id as vocabulary_id_2,c2.invalid_reason as invalid_reason_2 from concept c1 
join ri_agg ri1  on ri1.CONCEPT_ID_1 = c1.CONCEPT_ID  
join ri_agg ri2 on ri1.INGRED_COMBO  = ri2.INGRED_COMBO
 join concept c2 on c2.concept_id  = ri2.concept_id_1
  join cnc_rel_class r1 on r1.CONCEPT_ID_1 = c1.CONCEPT_ID and r1.CONCEPT_CLASS_ID_2 = 'Dose Form'
 join cnc_rel_class r2 on r2.CONCEPT_ID_1 = c2.CONCEPT_ID and r2.CONCEPT_CLASS_ID_2 = 'Dose Form' and nvl (r1.concept_id_2, 1)  = nvl (r2.concept_id_2, 1)
 where  c1.vocabulary_id like 'RxNorm%' and c2.vocabulary_id like 'RxNorm%' and lower (c2.concept_name) != lower (c1.concept_name) and c1.concept_class_id = c2.concept_class_id
 ;
-- EXPLAIN PLAN FOR
  create table compl_concept_stage_2 as
   select distinct ds_agg.*, r1.concept_id_2 as Ingred_id, rb1.concept_id_2 as Brand_Name_id, rm1.concept_id_2 as Supplier_id 
   from ds_agg 
    left join (select * from cnc_rel_class r1 where r1.CONCEPT_CLASS_ID_2 = 'Dose Form') r1 on r1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
    left join (select * from cnc_rel_class rb1 where  rb1.CONCEPT_CLASS_ID_2 = 'Brand Name') rb1 on rb1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
     left join ( select * from  cnc_rel_class rm1 where rm1.CONCEPT_CLASS_ID_2 = 'Supplier' ) rm1 on rm1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID  
 ;  
 SELECT * FROM TABLE (dbms_xplan.display); select count (1) from cnc_rel_class;
     ;
     drop table compl_concept_stage_2 ;
  create table compl_concept_stage_2 as
   select distinct ds_agg.*, c.concept_name, c.vocabulary_id, c.invalid_reason , nvl (r1.concept_id_2, 0) as DOse_form_id, nvl (rb1.concept_id_2, 0) as Brand_Name_id, nvl (rm1.concept_id_2, 0) as Supplier_id 
  from (select * from ds_agg where drug_concept_id not in (select drug_concept_id from ds_agg join ri_agg on concept_id_1 =  drug_concept_id
and regexp_count (  ds_agg.INGRED_COMBo, '-') <  regexp_count (  ri_agg.INGRED_COMBo, '-'))
   union select ri_agg.*, '0','0',0,0,0 from ri_agg where concept_id_1 not in (select drug_concept_id from ds_agg join ri_agg on concept_id_1 =  drug_concept_id
and regexp_count (  ds_agg.INGRED_COMBo, '-') >=  regexp_count (  ri_agg.INGRED_COMBo, '-'))

)  ds_agg
   join concept c  on ds_agg.drug_CONCEPT_ID  = c.concept_id
    left join (select * from cnc_rel_class r1 where r1.CONCEPT_CLASS_ID_2 = 'Dose Form') r1 on r1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
    left join (select * from cnc_rel_class rb1 where  rb1.CONCEPT_CLASS_ID_2 = 'Brand Name') rb1 on rb1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
     left join ( select * from  cnc_rel_class rm1 where rm1.CONCEPT_CLASS_ID_2 = 'Supplier' ) rm1 on rm1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
     where c.vocabulary_id like 'RxNorm%'
     ;
  --   select count (1) from (
     select distinct a.concept_name , 
    a.vocabulary_id, a.invalid_reason , b.concept_name  , b.vocabulary_id, b.invalid_reason from  compl_concept_stage_2 a join compl_concept_stage_2 b 
 on
  a.INGRED_COMBo = b.INGRED_COMBo and 
 nvl(a.AMOUNT_COMBO, 0) = nvl(b.AMOUNT_COMBO, 0) and
nvl( a.DOSE_COMBO, 0) = nvl( b.DOSE_COMBO, 0) and
nvl( a.DENOMINATOR_VALUE, 0) = nvl (b.DENOMINATOR_VALUE, 0) and
nvl( a.DENOMINATOR_UNIT_CONCEPT_Id, 0)=nvl (b.DENOMINATOR_UNIT_CONCEPT_Id, 0) and
nvl( a.BOX_SIZE, 0)= nvl (b.BOX_SIZE, 0) and 
a.DOSE_FORM_ID = b.DOSE_FORM_ID and
nvl (regexp_substr (a.concept_name, '\[.*\]'), ' ') =nvl ( regexp_substr (b.concept_name, '\[.*\]'), ' ')
and a.SUPPLIER_ID = b.SUPPLIER_ID
     where a.concept_name != b.concept_name
     and b.vocabulary_id = 'RxNorm Extension' and a.invalid_reason is null and b.invalid_reason is null
    -- and rownum < 1000
   --  )
;
select * from compl_concept_stage_2 where concept_name = '1 ML Viscum album preparation 1 MG/ML / copper carbonate Prefilled Syringe Box of 7'
;
select * from devv5.concept_relationship where concept_id_1 = 19039744

100 MG Anthralin 0.02 MG/MG / Salicylic Acid 0.005 MG/MG Topical Ointment by Special Order
100 MG Anthralin 0.005 MG/MG / Salicylic Acid 0.02 MG/MG Topical Ointment by Special Order
;
select * from drug_strength where DRUG_CONCEPT_ID = 21157561
;
select * from ri_agg where concept_id_1 = 21047587
;
 select distinct
    c1.concept_id as concept_id_1, 
--    c2.concept_id as concept_id_2,
    first_value(c2.concept_id) over (partition by c1.concept_id order by c2.vocabulary_id, c2.concept_id) as concept_id_2,
c1.concept_name as concept_name_1, 
first_value(c2.concept_name) over (partition by c1.concept_id order by c2.vocabulary_id, c2.concept_id) as concept_name_2
  from concept c1
  join concept c2 on c2.vocabulary_id like 'RxNorm%' 
  join cnc_rel_class r1 on r1.CONCEPT_ID_1 = c1.CONCEPT_ID and r1.CONCEPT_CLASS_ID_2 = 'Dose Form'
  join cnc_rel_class r2 on r2.CONCEPT_ID_1 = c2.CONCEPT_ID and r2.CONCEPT_CLASS_ID_2 = 'Dose Form' and r1.concept_id_2  = r2.concept_id_2
  join ds_agg  ri1 on ri1.drug_CONCEPT_ID = c1.CONCEPT_ID --For Drugs
  join cnc_rel_class ri2 on ri2.CONCEPT_ID_1 = c2.CONCEPT_ID  and  ri2.concept_class_id_1 = 'Branded Drug Form' and ri2.concept_class_id_2 = 'Clinical Drug Form'
  join ri_agg ria on ria.CONCEPT_ID_1 = ri2.CONCEPT_ID_2 and ri1.INGRED_COMBO  = ria.INGRED_COMBO --For Forms
  where c1.vocabulary_id like 'RxNorm%' and c2.concept_class_id like 'Branded Drug Form' and c1.concept_class_id like '%Branded Drug' 
    and regexp_substr( c2.concept_name, '\[.*\]' )= regexp_substr (c1.concept_name, '\[.*\]')
    and c2.invalid_reason is null and c1.invalid_reason is null
    and  regexp_count(c1.concept_name, ' / ')>0
    ;
    select 1 from dual
    ;
select * from drug_concept_stage where CONCEPT_CLASS_ID = 'Drug Product'
;
select r.concept_id_1, r.concept_id_2,c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from concept c1 
  join concept_relationship r on r.concept_id_1=c1.concept_id 
   join concept c2 on r.concept_id_2=c2.concept_id 
  where c1.vocabulary_id ='RxNorm'
  and c2.vocabulary_id  ='RxNorm'
  and c1.concept_class_id = 'Branded Drug'
  and c2.concept_class_id = 'Branded Drug Form'
  and c1.concept_name like '% / %'
  and rownum < 100
;
select r.concept_id_1, r.concept_id_2,c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from concept c1 
  join concept_relationship r on r.concept_id_1=c1.concept_id 
   join concept c2 on r.concept_id_2=c2.concept_id 
  where c1.vocabulary_id like 'RxNorm%'
  and c2.vocabulary_id  like 'RxNorm%'
  and c1.concept_class_id = 'Clinical Drug'
  and c2.concept_class_id = 'Clinical Drug Form'
  and c1.concept_name like '% / %'
  and rownum < 100
;
select r.concept_id_1, r.concept_id_2,c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from concept c1 
  join concept_relationship r on r.concept_id_1=c1.concept_id 
   join concept c2 on r.concept_id_2=c2.concept_id 
  where c1.vocabulary_id like 'RxNorm%'
  and c2.vocabulary_id  like 'RxNorm%'
  and c1.concept_class_id = 'Clinical Drug'
  and c2.concept_class_id = 'Clinical Drug Form'
  and c1.concept_name like '% / %'
  and regexp_count (c1.concept_name,  '% / %') != regexp_count (c2.concept_name,  '% / %')
  and rownum < 100
;

select r.concept_id_1, r.concept_id_2,c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from concept c1 
  join concept_relationship r on r.concept_id_1=c1.concept_id 
   join concept c2 on r.concept_id_2=c2.concept_id 
  where c1.vocabulary_id like 'RxNorm%'
  and c2.vocabulary_id  like 'RxNorm%'
and ( 
 c1.concept_class_id = 'Branded Drug'
  and c2.concept_class_id = 'Branded Drug Comp'
  or 
     c1.concept_class_id = 'Clinical Drug'
  and c2.concept_class_id = 'Clinical Drug Form'
  or 
     c1.concept_class_id = 'Branded Drug'
  and c2.concept_class_id = 'Branded Drug Form'
  )
  and c1.concept_name like '% / %'
  and regexp_count (c1.concept_name,  '% / %') != regexp_count (c2.concept_name,  '% / %')
  and rownum < 100
;
with p as (
-- by name
   select distinct

  c1.concept_id as concept_id_1, 
 c2.concept_id as concept_id_2,  c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from ( select * from concept c1 
  join cnc_rel_class r1 on r1.CONCEPT_ID_1 = c1.CONCEPT_ID and r1.CONCEPT_CLASS_ID_2 = 'Dose Form'
  join ds_agg  ri1 on ri1.drug_CONCEPT_ID = c1.CONCEPT_ID where c1.concept_class_id like '%Clinical Drug' and c1.vocabulary_id like 'RxNorm%'  and c1.invalid_reason is null) c1
  join ( select * from concept c2
  join cnc_rel_class r1 on r1.CONCEPT_ID_1 = c2.CONCEPT_ID and r1.CONCEPT_CLASS_ID_2 = 'Dose Form'
  join ri_agg  ri1 on ri1.CONCEPT_ID_1 = c2.CONCEPT_ID where c2.concept_class_id like 'Clinical Drug Form' and c2.vocabulary_id like 'RxNorm%' and c2.invalid_reason is null ) c2 on c1.CONCEPT_CLASS_ID_2 = c2.CONCEPT_CLASS_ID_2 and c1.INGRED_COMBO  =c2.INGRED_COMBO
 minus
-- in concept_relationship
  select r.concept_id_1, r.concept_id_2,c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from concept c1 
  join concept_relationship r on r.concept_id_1=c1.concept_id -- and r.invalid_reason is null
 
   join concept c2 on c2.vocabulary_id like 'RxNorm%' and r2.CONCEPT_ID_1 = c2.CONCEPT_ID and ri2.CONCEPT_ID_1 = c2.CONCEPT_ID 
  where c1.vocabulary_id like 'RxNorm%' and c2.concept_class_id like 'Clinical Drug Form' and c1.concept_class_id like '%Clinical Drug' 
and c2.invalid_reason is null and c1.invalid_reason is null
)
select 
  concept_id_1, concept_id_2, concept_name_1, concept_name_2,
  'Has Component' as relationship_id,
  '17-Aug-2016' as valid_start_date,
  '31-Dec-2099' as valid_end_date,
  null as invalid_reason
from p
union

select 
  concept_id_2
  , concept_id_1, 
  concept_name_2
  , concept_name_1,
  'Component of'  as relationship_id,
  '17-Aug-2016' as valid_start_date,
  '31-Dec-2099' as valid_end_date,
  null as invalid_reason
from p
;
select * from concept where concept_id = 40174550
;
select *
 --r.concept_id_1, r.concept_id_2,c1.concept_name as concept_name_1, c2.concept_name as concept_name_2
  from concept c1 
  join concept_relationship r on r.concept_id_1=c1.concept_id -- and r.invalid_reason is null
 
   join concept c2 on c2.vocabulary_id like 'RxNorm%' and r.CONCEPT_ID_2 = c2.CONCEPT_ID and r.CONCEPT_ID_2 = c2.CONCEPT_ID 
  where c1.vocabulary_id like 'RxNorm%' --and c2.concept_class_id like 'Clinical Drug Form' and c1.concept_class_id like '%Clinical Drug' 
and c2.invalid_reason is null and c1.invalid_reason is null
and c1.concept_id = 40174550
;
select r.* From dev_dmd.concept c1, dev_dmd.concept c2, dev_dmd.concept_relationship r
where c1.concept_id=r.concept_id_1
and c2.concept_id=r.concept_id_2
and c1.concept_id=40174550
--and c2.concept_id=19023170
;
select * From dev_rxnorm.concept c1, dev_rxnorm.concept c2, dev_rxnorm.concept_relationship r
where c1.concept_id=r.concept_id_1
and c2.concept_id=r.concept_id_2
and c1.concept_class_id = 'Branded Drug'
and c2.concept_class_id ='Brand Name' and r.invalid_reason is null and c1.concept_id=40174550
;
SELECT VOCABULARY_VERSION
FROM devv5.VOCABULARY
WHERE VOCABULARY_ID = 'None'
;
select c.concept_code, c.concept_name, c.vocabulary_id
from concept c
left join concept_relationship r on c.concept_id = concept_id_1 and r.invalid_reason is null and relationship_id ='Maps to'
left join concept c2 on c2.concept_id = concept_id_2 and c2.vocabulary_id = 'SNOMED' and c2.invalid_reason is null
where c.vocabulary_id in ('ICD10CM', 'ICD9CM') and c.invalid_reason is null
and c2.concept_id is null
order by vocabulary_id, concept_code
;
select distinct concept_relationship.valid_start_date from devv5.concept_relationship join devv5.concept on concept_id_1=concept_id where vocabulary_id in ('Gemscript', 'Gemscript THIN')
and concept_relationship.valid_start_date = to_date (yyyymmdd, '20131212')
;
select * from drug_concept_stage where concept_code in ('4418111000001104', '4418311000001102', '4418511000001108', '4435311000001100');

select * from ds_stage where drug_concept_code in ('4418111000001104', '4418311000001102', '4418511000001108', '4435311000001100')
;
select * from drug_concept_stage a
join ds_stage on drug_concept_code = a.concept_code
join drug_concept_stage b on b.concept_code = ingredient_concept_code
 where a.concept_code in
( 
 select drug_concept_code,concept_id_2 from (
select distinct drug_concept_code,concept_id_2 from ds_stage join relationship_to_concept 
on concept_code_1 = ingredient_concept_code
) group by drug_concept_code,concept_id_2  having count (1) >1

;
select a.concept_name, b.concept_name,c.concept_name, ds.*  from drug_concept_stage a
join ds_stage ds on drug_concept_code = a.concept_code
join drug_concept_stage b on b.concept_code = ingredient_concept_code
join relationship_to_concept rc
on  rc.concept_code_1 = ds.ingredient_concept_code
join concept c on c.concept_id = rc.concept_id_2
 join  (
select drug_concept_code,concept_id_2 from ds_stage join relationship_to_concept 
on concept_code_1 = ingredient_concept_code
group by drug_concept_code, concept_id_2 having count (1) >1) z on z.concept_id_2 = rc.concept_id_2 and z.drug_concept_code = ds.drug_concept_code
where a.SOURCE_CONCEPT_CLASS_ID = 'VMP'
;
select  concept_code_1, concept_id_2 from  relationship_to_concept group by concept_code_1, concept_id_2
having count (1) >1
;
select c.*, rowid from relationship_to_concept c where concept_code_1 = '412410003'
;
select * from drug_concept_stage where SOURCE_CONCEPT_CLASS_ID = 'VMP'
;
--3788711000001106 Sodium dihydrogen phosphate dihydrate 18.1% / Disodium hydrogen phosphate dodecahydrate 8% 133ml enema - Pack

select * from ds_stage where drug_concept_code in ('4418511000001108', '3764911000001104');

--  Duplicate ingredients that are different in drug_concept_stage but same after mapping to RxNorm in Products
  select distinct 
  i1.concept_code_1, d.concept_name, -- uncomment if you want to see the drugs
  r1.concept_code_1, ing1.concept_name,
  r2.concept_code_1, ing2.concept_name,
  r1.concept_id_2, c.concept_name
from r_to_c r1 
join r_to_c r2 on r1.concept_id_2=r2.concept_id_2 and r1.concept_code_1!=r2.concept_code_1
join internal_relationship_stage i1 on i1.concept_code_2=r1.concept_code_1
join internal_relationship_stage i2 on i2.concept_code_2=r2.concept_code_1 and i1.concept_code_1=i2.concept_code_1
join drug_concept_stage d on d.concept_code=i1.concept_code_1
join drug_concept_stage ing1 on ing1.concept_code=r1.concept_code_1
join drug_concept_stage ing2 on ing2.concept_code=r2.concept_code_1
join concept c on c.concept_id=r1.concept_id_2
order by r1.concept_id_2;
  

select * from ds_stage 
join 
where drug_concept_code = '2686303' 
;
--my version
select * from ds_stage ds join  (
select ds.drug_concept_code, rc1.concept_id_2 from ds_stage ds
join ds_stage ds2 on ds2.drug_concept_code = ds.drug_concept_code 
join relationship_to_concept rc1 on rc1.concept_code_1 = ds.ingredient_concept_code
join  relationship_to_concept rc2 on rc2.concept_code_1 = ds2.ingredient_concept_code and rc1.concept_code_1 != rc2.concept_code_1 and rc2.concept_id_2 = rc1.concept_id_2) z on z.drug_concept_code = ds.drug_concept_code

join drug_concept_stage dcs1 on dcs1.concept_code = ds.drug_concept_code
join drug_concept_stage dcsi on dcsi.concept_code = ds.ingredient_concept_code
join concept c on c.concept_id = concept_id_2
;
drop table ingred_dupl ;
create table ingred_dupl as 
select z.drug_concept_code, z.concept_id_2, ingredient_concept_code,

 drug_name,  ingred_name ,  RxName, 

AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT, BOX_SIZE

 from (
select drug_concept_code, concept_id_2 from ds_stage ds
join relationship_to_concept rc on ingredient_concept_CODE = CONCEPT_CODE_1 group by  drug_concept_code, concept_id_2 having count (1) >1) z 
join (
select drug_concept_code, ingredient_concept_code, concept_id_2, dc1.concept_name as drug_name, dc2.concept_name as ingred_name , c.concept_name as RxName, 

AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT, BOX_SIZE

from ds_stage ds
join relationship_to_concept rc on ingredient_concept_CODE = CONCEPT_CODE_1
join drug_concept_stage dc1 on drug_concept_code = dc1.concept_code
join drug_concept_stage dc2 on ingredient_concept_code = dc2.concept_code
join concept c on c.concept_id = concept_id_2
) x on x.drug_concept_code = z.drug_concept_code and x.concept_id_2 = z.concept_id_2
;
select id.*, i.*, drug.DRUG_DESCR from ingred_dupl id
join packaging d on id.drug_concept_code= cast (d.din_7 as varchar (250)) 
join ingredient i on i.drug_code = d.drug_code and id.ingredient_concept_code  =i.FORM_CODE
join drug on  i.drug_code = drug.drug_code 
;
--make sum
with p as 
select drug_concept_code, min (INGREDIENT_CONCEPT_CODE) as INGREDIENT_CONCEPT_CODE, sum (amount_value) amount_value, sum (NUMERATOR_VALUE) NUMERATOR_VALUE, concept_id_2 from ingred_dupl group by drug_concept_code, concept_id_2
;
drop table ds_upd;
create table ds_upd as (
select drug_concept_code, min (INGREDIENT_CONCEPT_CODE) as INGREDIENT_CONCEPT_CODE, sum (amount_value) amount_value, sum (NUMERATOR_VALUE) NUMERATOR_VALUE, concept_id_2 from ingred_dupl group by drug_concept_code, concept_id_2)
 
;
update ds_stage ds set INGREDIENT_CONCEPT_CODE = (select INGREDIENT_CONCEPT_CODE from ds_upd p where p.drug_concept_code = ds.drug_concept_code and drug_concept_code != '3651258'),
amount_value = (select amount_value from ds_upd p where p.drug_concept_code = ds.drug_concept_code and drug_concept_code != '3651258'),
NUMERATOR_VALUE = (select amount_value from ds_upd p where p.drug_concept_code = ds.drug_concept_code and drug_concept_code != '3651258' )
where exists (select 1 from ingred_dupl id where id.drug_concept_code = ds.drug_concept_code and id.ingredient_concept_code = ds.ingredient_concept_code and drug_concept_code != '3651258')
;
select drug_concept_code from ds_upd group by drug_concept_code having count (1) >1
;
select * from ds_upd where drug_concept_code = '3651258'
;
select * from ds_stage where drug_concept_code = '3651258'
;
DELETE
FROM DS_STAGE
WHERE DRUG_CONCEPT_CODE = '3651258'
AND   INGREDIENT_CONCEPT_CODE = '74786';
DELETE
FROM DS_STAGE
WHERE DRUG_CONCEPT_CODE = '3651258'
AND   INGREDIENT_CONCEPT_CODE = '58648';
UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 62500000000
WHERE DRUG_CONCEPT_CODE = '3651258'
AND   INGREDIENT_CONCEPT_CODE = '34627';
UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 62500000000
WHERE DRUG_CONCEPT_CODE = '3651258'
AND   INGREDIENT_CONCEPT_CODE = '53569';

--delete duplicates
create table ds_stage_tmp as select distinct  a.* from ds_stage a
;
drop table ds_stage;
create table ds_stage as select distinct  a.* from ds_stage_tmp a
;
drop table ds_stage_tmp;
--let's Check Christian script
select distinct 
  i1.concept_code_1, d.concept_name, -- uncomment if you want to see the drugs
  r1.concept_code_1, ing1.concept_name,
  r2.concept_code_1, ing2.concept_name,
  r1.concept_id_2, c.concept_name
from r_to_c r1 
join r_to_c r2 on r1.concept_id_2=r2.concept_id_2 and r1.concept_code_1!=r2.concept_code_1
join CODE_INGRED_TO_INGRED i1 on cast ( i1.concept_code_2 as varchar (50))=r1.concept_code_1
join CODE_INGRED_TO_INGRED i2 on cast ( i2.concept_code_2 as varchar (50))=r2.concept_code_1 and i1.concept_code_1=i2.concept_code_1
join drug_concept_stage d on d.concept_code=cast ( i1.concept_code_1 as varchar (50))
join drug_concept_stage ing1 on ing1.concept_code=r1.concept_code_1
join drug_concept_stage ing2 on ing2.concept_code=r2.concept_code_1
join concept c on c.concept_id=r1.concept_id_2
order by r1.concept_id_2;

select r1.*,ing1.concept_name, ing2.concept_name from CODE_INGRED_TO_INGRED r1

join drug_concept_stage ing1 on 'X'||ing1.concept_code='X'||r1.concept_code_1
join drug_concept_stage ing2 on 'X'||ing2.concept_code='X'||r1.concept_code_2
where concept_code_1 in (
select distinct 
  i1.concept_code_1/*, d.concept_name, -- uncomment if you want to see the drugs
  r1.concept_code_1, ing1.concept_name,
  r2.concept_code_1, ing2.concept_name,
  r1.concept_id_2, c.concept_name*/
from r_to_c r1 
join r_to_c r2 on r1.concept_id_2=r2.concept_id_2 and r1.concept_code_1!=r2.concept_code_1
join CODE_INGRED_TO_INGRED i1 on cast ( i1.concept_code_2 as varchar (50))=r1.concept_code_1
join CODE_INGRED_TO_INGRED i2 on cast ( i2.concept_code_2 as varchar (50))=r2.concept_code_1 and i1.concept_code_1=i2.concept_code_1
join drug_concept_stage d on d.concept_code=cast ( i1.concept_code_1 as varchar (50))
join drug_concept_stage ing1 on ing1.concept_code=r1.concept_code_1
join drug_concept_stage ing2 on ing2.concept_code=r2.concept_code_1
join concept c on c.concept_id=r1.concept_id_2
)
;
delete from internal_relationship_stage where exists (select 1 from ds_stage where drug_concept_code = concept_code_1 and ingredient_concept_code = concept_code_2)
;
insert into internal_relationship_stage ( concept_code_1, concept_code_2)
select distinct drug_concept_code, ingredient_concept_code from ds_stage
;
update internal_relationship_stage ds set concept_code_2 = (select INGREDIENT_CONCEPT_CODE from ds_upd p where p.drug_concept_code = ds.concept_code_1)
where exists (select 1 from ingred_dupl id where id.drug_concept_code = ds.concept_code_1 and id.ingredient_concept_code = ds.concept_code_2)
;
create table internal_relationship_tmp as select distinct  a.* from internal_relationship_stage a
;
drop table internal_relationship_stage;
create table internal_relationship_stage as select distinct  a.* from internal_relationship_tmp a
;
drop table internal_relationship_tmp;
