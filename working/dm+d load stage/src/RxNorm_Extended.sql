drop  table RxE_exclusion;
create table RxE_exclusion as
select distinct concept_code_1 from concept_relationship_stage a
join concept_stage b on a.concept_code_1 = b.concept_code
where relationship_id in  ('Maps to')
or  relationship_id in  ('Has standard ing') and concept_class_id = 'Ingredient'
or relationship_id in  ('Has standard brand') and concept_class_id = 'Brand Name'
or relationship_id in  ('Has standard form') and concept_class_id = 'Dose Form'
;
-- create table to store all future links from concrete vocab into RxE
-- fill it with natural primary keys
 --to do - for optimization create RxE exclusions table
create table rxe_replace as
select concept_code, 'OMOP'||new_vocab2.nextval as rxe_code from concept_stage 
where concept_code not like 'OMOP%' 
and concept_code not in (select concept_code_1 from  RxE_exclusion) -- concept_relationship_stage where relationship_id in  ('Maps to', 'Has standard ing', 'Has standard brand','Has standard form' )) 
/*
and concept_code not  in (select concept_code from concept_stage a left join drug_strength_stage b on a.concept_code = b.drug_concept_code where ( concept_class_id like '%Drug%' or concept_class_id like 'Marketed%')
 and b.drug_concept_code is null)
 */
and invalid_reason is null
;
-- TODO identify and add here all the concepts we have to keep in the original vocabulary
-- insert copies of RxE
insert into concept_stage(concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, valid_start_date, valid_end_date, invalid_reason, concept_code)
select concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, valid_start_date, valid_end_date, invalid_reason,
rxe_code
from concept_stage cs JOIN rxe_replace rxer ON rxer.concept_code = cs.concept_code;
/*
-- rewrite all the relationships to the newly created copies
create table rxe_rowid_update as
select crs.rowid as irowid, nvl(rxer1.rxe_code, crs.concept_code_1) as rxe_code_1 , nvl(rxer2.rxe_code, crs.concept_code_2)  as rxe_code_2 from concept_relationship_stage crs
LEFT JOIN rxe_replace rxer1 ON crs.concept_code_1=rxer1.concept_code AND crs.vocabulary_id_1 = 'dm+d'
LEFT JOIN rxe_replace rxer2 ON crs.concept_code_2=rxer2.concept_code AND crs.vocabulary_id_2 = 'dm+d'
WHERE rxer1.rowid is not null or rxer2.rowid is not null;

MERGE INTO concept_relationship_stage crs
USING   (
select * from rxe_rowid_update
) d ON (d.irowid=crs.rowid)
WHEN MATCHED THEN UPDATE
    SET crs.concept_code_1 = d.rxe_code_1, crs.concept_code_2 = d.rxe_code_2;

drop table rxe_rowid_update;
commit;

--rewrite codes in drug_strength
create table rxe_rowid_update_dss as
select DSS.rowid as irowid, nvl(rxer1.rxe_code, dss.drug_concept_code) as rxe_drug_code , nvl(rxer2.rxe_code, dss.ingredient_concept_code)  as rxe_ingr_code from drug_strength_stage dss
LEFT JOIN rxe_replace rxer1 ON dss.drug_concept_code=rxer1.concept_code AND dss.vocabulary_id_1 = 'dm+d'
LEFT JOIN rxe_replace rxer2 ON dss.ingredient_concept_code=rxer2.concept_code AND dss.vocabulary_id_2 = 'dm+d'
WHERE rxer1.rowid is not null or rxer2.rowid is not null;

MERGE INTO drug_strength_stage dss
USING   (
select * from rxe_rowid_update_dss
) d ON (d.irowid=dss.rowid)
WHEN MATCHED THEN UPDATE
    SET dss.drug_concept_code = d.rxe_drug_code, dss.ingredient_concept_code = d.rxe_ingr_code;

drop table rxe_rowid_update_dss;
;
commit;
*/
--update conept_relationship_stage
;
CREATE INDEX idx_rxe_rxe_code ON rxe_replace (rxe_code)  NOLOGGING;
CREATE INDEX idx_rxe_cnc_code ON rxe_replace (concept_code)  NOLOGGING;
;
update concept_relationship_stage a 
set concept_code_1 = (select rxe_code from rxe_replace b where a.concept_code_1 = b.concept_code and vocabulary_id_1 = 'dm+d')
where exists (select 1 from rxe_replace b where a.concept_code_1 = b.concept_code and vocabulary_id_1 = 'dm+d')
;
update concept_relationship_stage a 
set concept_code_2 = (select rxe_code from rxe_replace b where a.concept_code_2 = b.concept_code and vocabulary_id_2 = 'dm+d' )
where exists (select 1 from rxe_replace b where a.concept_code_2 = b.concept_code and vocabulary_id_2 = 'dm+d' )
;
update drug_strength_stage a 
set ingredient_concept_code = (select rxe_code from rxe_replace b where a.ingredient_concept_code = b.concept_code and vocabulary_id_2 = 'dm+d' )
where exists (select 1 from rxe_replace b where a.ingredient_concept_code = b.concept_code and vocabulary_id_2 = 'dm+d' )
;
update drug_strength_stage a 
set drug_concept_code = (select rxe_code from rxe_replace b where a.drug_concept_code = b.concept_code and vocabulary_id_1 = 'dm+d' )
where exists (select 1 from rxe_replace b where a.drug_concept_code = b.concept_code and vocabulary_id_1 = 'dm+d' )
;
-- substitute vocabulary id
update concept_stage SET vocabulary_id = 'RxNorm Extension' WHERE vocabulary_id=(select vocabulary_id from drug_concept_stage where rownum=1) 
AND concept_code not in (select concept_code from rxe_replace) and concept_code like 'OMOP%' and invalid_reason is null
 AND concept_code not in (select concept_code_1 from RxE_exclusion)
 ;
update concept_relationship_stage SET vocabulary_id_1 = 'RxNorm Extension' WHERE vocabulary_id_1=(select vocabulary_id from drug_concept_stage where rownum=1) AND concept_code_1 in (select concept_code from concept_stage where vocabulary_id = 'RxNorm Extension');
update concept_relationship_stage SET vocabulary_id_2 = 'RxNorm Extension' WHERE vocabulary_id_2=(select vocabulary_id from drug_concept_stage where rownum=1) AND concept_code_2 in (select concept_code from concept_stage where vocabulary_id = 'RxNorm Extension');
update drug_strength_stage set vocabulary_id_1 = 'RxNorm Extension' WHERE vocabulary_id_1=(select vocabulary_id from drug_concept_stage where rownum=1) AND drug_concept_code in (select concept_code from concept_stage where vocabulary_id = 'RxNorm Extension');
update drug_strength_stage set vocabulary_id_2 = 'RxNorm Extension' WHERE vocabulary_id_1=(select vocabulary_id from drug_concept_stage where rownum=1) AND ingredient_concept_code in (select concept_code from concept_stage where vocabulary_id = 'RxNorm Extension');
commit;

-- insert mappings
insert into concept_relationship_stage(concept_code_1, vocabulary_id_1, concept_code_2, vocabulary_id_2, relationship_id, valid_start_date, valid_end_date, invalid_reason)
select 
  rxer.concept_code as concept_code_1,
  (select vocabulary_id from drug_concept_stage where rownum=1) as vocabulary_id_1,
  rxer.rxe_code as concept_code_2,
  'RxNorm Extension' as vocabulary_id_2,
  'Maps to' as relationship_id,
  (select latest_update from vocabulary v where v.vocabulary_id=(select vocabulary_id from drug_concept_stage where rownum=1)) as valid_start_date,
  to_date('2099-12-31', 'yyyy-mm-dd') as valid_end_date,
  null as invalid_reason
from rxe_replace rxer;

commit;

-- since now all the concepts in the base vocab are present in RxE and have mappings, so they are not standard
update concept_stage SET standard_concept = null WHERE vocabulary_id=(select vocabulary_id from drug_concept_stage where rownum=1);

commit;

-- drop temp table
drop table rxe_replace;
--return old names of dm+d
;
update concept_stage a set concept_name = (select concept_name from drug_concept_stage b where a.concept_code = b.CONCEPT_CODE)
where exists 
(select 1 from drug_concept_stage b where a.concept_code = b.CONCEPT_CODE)
;
commit
;
--second replacement
select * from rxe_replace_2 where CONCEPT_CODE = '324234006';
drop table rxe_replace_2;
create table rxe_replace_2 as (
select concept_code_1 as CONCEPT_CODE, concept_code_2 as rxe_code, vocabulary_id_2 from concept_relationship_stage 
join concept_stage on concept_code = concept_code_1
 where vocabulary_id_1 ='dm+d' and vocabulary_id_2 like 'RxNorm%'  and (
relationship_id in  ('Maps to')
or  relationship_id in  ('Has standard ing') and concept_class_id = 'Ingredient'
or relationship_id in  ('Has standard brand') and concept_class_id = 'Brand Name'
or relationship_id in  ('Has standard form') and concept_class_id = 'Dose Form'
))
;
--RxNorm bug it has same concepts marked as standard 
delete from rxe_replace_2
where rowid not in (select MIN(rowid) from rxe_replace_2 group by CONCEPT_CODE); 

CREATE INDEX idx_rxe_rxe_code_2 ON rxe_replace_2 (rxe_code)  NOLOGGING;
CREATE INDEX idx_rxe_cnc_code_2 ON rxe_replace_2 (concept_code)  NOLOGGING;
;
update concept_relationship_stage a 
set concept_code_1 = (select rxe_code from rxe_replace_2 b where a.concept_code_1 = b.concept_code), 
vocabulary_id_1 = (select b.vocabulary_id_2 from rxe_replace_2 b where a.concept_code_1 = b.concept_code)
where exists (select 1 from rxe_replace_2 b where a.concept_code_1 = b.concept_code)
--and relationship_id not in ('Maps to', 'Has standard ing', 'Has standard brand','Has standard form' )
and a.vocabulary_id_1 = 'dm+d'
and NOT exists (select 1 from concept_relationship_stage crs JOIN concept_stage cs on cs.concept_code = crs.concept_code_1 WHERE (relationship_id in  ('Maps to')
or  relationship_id in  ('Has standard ing') and concept_class_id = 'Ingredient'
or relationship_id in  ('Has standard brand') and concept_class_id = 'Brand Name'
or relationship_id in  ('Has standard form') and concept_class_id = 'Dose Form'
) AND crs.concept_code_1 = a.concept_code_1 AND crs.concept_code_2 = a.concept_code_2 
)
;
update concept_relationship_stage a 
set concept_code_2 = (select rxe_code from rxe_replace_2 b where a.concept_code_2 = b.concept_code  ), 
vocabulary_id_2 = (select b.vocabulary_id_2 from rxe_replace_2 b where a.concept_code_2 = b.concept_code)
where exists (select 1 from rxe_replace_2 b where a.concept_code_2 = b.concept_code)
and vocabulary_id_2 = 'dm+d'
;
update drug_strength_stage a 
set ingredient_concept_code = (select rxe_code from rxe_replace_2 b where a.ingredient_concept_code = b.concept_code)
where exists (select 1 from rxe_replace_2 b where a.ingredient_concept_code = b.concept_code)
and vocabulary_id_2 = 'dm+d' 
;
update drug_strength_stage a 
set drug_concept_code = (select rxe_code from rxe_replace_2 b where a.drug_concept_code = b.concept_code ),
vocabulary_id_1 = (select b.vocabulary_id_2 from rxe_replace_2 b where a.drug_concept_code = b.concept_code )
where exists (select 1 from rxe_replace_2 b where a.drug_concept_code = b.concept_code)
 and vocabulary_id_1 = 'dm+d'
;
select * from rxe_replace_2 where vocabulary_id_2 is null;
 create table concept_relationship_stage_tmp as select * from concept_relationship_stage
    ;
    drop table concept_relationship_stage;
    create table concept_relationship_stage as select distinct * from concept_relationship_stage_tmp;
    drop table concept_relationship_stage_tmp purge;
    CREATE INDEX idx_concept_code_1 ON concept_relationship_stage (concept_code_1);
CREATE INDEX idx_concept_code_2 ON concept_relationship_stage (concept_code_2);
commit
;
delete from concept_relationship_stage where vocabulary_id_1 = 'RxNorm' and vocabulary_id_2 = 'RxNorm'
;
delete from drug_strength_stage where vocabulary_id_1 = 'RxNorm'
;
delete from drug_strength_stage where rowid not in(
select min(rowid) from drug_strength_stage
group by DRUG_CONCEPT_CODE,VOCABULARY_ID_1,INGREDIENT_CONCEPT_CODE,VOCABULARY_ID_2,AMOUNT_VALUE,AMOUNT_UNIT_CONCEPT_ID,NUMERATOR_VALUE,NUMERATOR_UNIT_CONCEPT_ID,DENOMINATOR_VALUE,DENOMINATOR_UNIT_CONCEPT_ID,VALID_START_DATE,VALID_END_DATE,INVALID_REASON
);
commit
;
