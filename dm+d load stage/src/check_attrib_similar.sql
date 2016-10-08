drop table cnc_rel_class; 
create table cnc_rel_class as
select ri.*, ci.concept_class_id as concept_class_id_1 , c2.concept_class_id as concept_class_id_2 
from devv5.concept_relationSHIp ri 
join devv5.concept ci on ci.concept_id = ri.concept_id_1 
join devv5.concept c2 on c2.concept_id = ri.concept_id_2 
where ci.vocabulary_id like  'RxNorm%' and ri.invalid_reason is null and ci.invalid_reason is null 
and  c2.vocabulary_id like 'RxNorm%'  and ci.invalid_reason is null 
;
drop table ds_agg;
create table ds_agg as 
select drug_concept_id, listagg (ingredient_concept_id, '-') within group (order by ingredient_concept_id) as ingred_combo,  
listagg (nvl (amount_value,0), '-') within group (order by  ingredient_concept_id) as amount_combo,
listagg (nvl (numerator_value,0)/nvl (DENOMINATOR_VALUE, 1), '-') within group (order by ingredient_concept_id) as dose_combo,
nvl (DENOMINATOR_VALUE,0) as DENOMINATOR_VALUE, nvl (DENOMINATOR_UNIT_CONCEPT_ID, 0) as DENOMINATOR_UNIT_CONCEPT_ID, nvl (box_size,0) as box_size
from drug_strength group by drug_concept_id, DENOMINATOR_VALUE, DENOMINATOR_UNIT_CONCEPT_ID, box_size
;
drop table ri_agg;
create table ri_agg as 
select concept_id_1, listagg (concept_id_2, '-') within group (order by concept_id_2) as ingred_combo
from cnc_rel_class where concept_class_id_2 = 'Ingredient' and concept_class_id_1 like '%Drug%'
group by concept_id_1
;
create index cnc_rel_class_1 on cnc_rel_class (concept_id_1); 
create index cnc_rel_class_2 on cnc_rel_class (concept_id_2);
create index ds_agg_1 on ds_agg (drug_concept_id);
create index ds_agg_2 on ds_agg (INGRED_COMBO);
create index ri_agg_1 on ri_agg (concept_id_1);
create index ri_agg_2 on ri_agg (INGRED_COMBO);
;
 drop table compl_concept_stage_2 ;
  create table compl_concept_stage_2 as
   select distinct ds_agg.*, c.concept_name, c.vocabulary_id, c.invalid_reason , nvl (r1.concept_id_2, 0) as DOse_form_id, nvl (rb1.concept_id_2, 0) as Brand_Name_id, nvl (rm1.concept_id_2, 0) as Supplier_id 
  from (select * from ds_agg union select ri_agg.*, '0','0',0,0,0 from ri_agg where concept_id_1 not in (select drug_concept_id from ds_agg) ) ds_agg
   join concept c  on ds_agg.drug_CONCEPT_ID  = c.concept_id
    left join (select * from cnc_rel_class r1 where r1.CONCEPT_CLASS_ID_2 = 'Dose Form') r1 on r1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
    left join (select * from cnc_rel_class rb1 where  rb1.CONCEPT_CLASS_ID_2 = 'Brand Name') rb1 on rb1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
     left join ( select * from  cnc_rel_class rm1 where rm1.CONCEPT_CLASS_ID_2 = 'Supplier' ) rm1 on rm1.CONCEPT_ID_1 = ds_agg.drug_CONCEPT_ID 
     where c.vocabulary_id like 'RxNorm%'
     ;
--the same attributes, both invalid reason is null
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
