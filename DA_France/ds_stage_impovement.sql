update ds_stage ds
set numerator_value = (select 
 ds.DENOMINATOR_VALUE * ds.NUMERATOR_VALUE /a.per_volume from
(select distinct  drug_concept_code, DENOMINATOR_VALUE, per_volume from 
(
select s.*, france.*, regexp_replace (regexp_replace (regexp_substr ( regexp_substr (DESCR_PCK, '[[:digit:]\.]+(ML|G)$'),'[[:digit:]\.]+'), '^\.', '0.'), '\.$')  as real_volume, 
nvl (regexp_replace (regexp_substr (replace (regexp_substr (DESCR_PCK, '(/[[:digit:]\.]*(ML|G))| [[:digit:]\.]+(ML|G) ') , '/'), '[[:digit:]\.]+'), '^\.', '0.'), 1)
 as per_volume
 from ds_stage s
 join france on pfc = drug_concept_code
where volume !='NULL' and NUMERATOR_UNIT !='%'
and
 regexp_substr (DESCR_PCK, '[[:digit:]\.]+(ML|G)$') != replace (regexp_substr (DESCR_PCK, '/[[:digit:]\.]*(ML|G)| [[:digit:]\.]+(ML|G) ') , '/') 
)) a where a.drug_concept_code = ds.drug_concept_code)
where exists (select 
1 from
(select distinct  drug_concept_code, DENOMINATOR_VALUE, per_volume from 
(
select s.*, france.*, regexp_replace (regexp_replace (regexp_substr ( regexp_substr (DESCR_PCK, '[[:digit:]\.]+(ML|G)$'),'[[:digit:]\.]+'), '^\.', '0.'), '\.$')  as real_volume, 
nvl (regexp_replace (regexp_substr (replace (regexp_substr (DESCR_PCK, '(/[[:digit:]\.]*(ML|G))| [[:digit:]\.]+(ML|G) ') , '/'), '[[:digit:]\.]+'), '^\.', '0.'), 1)
 as per_volume
 from ds_stage s
 join france on pfc = drug_concept_code
where volume !='NULL' and NUMERATOR_UNIT !='%'
and
 regexp_substr (DESCR_PCK, '[[:digit:]\.]+(ML|G)$') != replace (regexp_substr (DESCR_PCK, '/[[:digit:]\.]*(ML|G)| [[:digit:]\.]+(ML|G) ') , '/') 
)) a where a.drug_concept_code = ds.drug_concept_code)
;

--adding lost dosage
update ds_stage 
set numerator_unit=(select STRG_MEAS from france where pfc=drug_concept_Code and STRG_MEAS!='NULL')     ,
    numerator_Value=(select  cast((STRG_UNIT) as number) from france where pfc=drug_concept_Code and STRG_UNIT!='NULL')  
where DENOMINATOR_UNIT is not null and NUMERATOR_UNIT is null
;
--removing %
update ds_stage
set numerator_value=numerator_value*10*DENOMINATOR_VALUE,
    numerator_unit='mg'
where NUMERATOR_UNIT='%';

update ds_stage 
set DENOMINATOR_VALUE=null,
    DENOMINATOR_UNIT=null
where DENOMINATOR_UNIT is not null and NUMERATOR_UNIT is null;

--updating concepts that have amount_value but no  amount_unit
update ds_stage 
set amount_value=amount_value/1000,
    amount_unit='MG'
  where ingredient_concept_code in  (
select ingredient_concept_code from   ds_stage s join france on drug_concept_Code=pfc
where AMOUNT_VALUE is not null and AMOUNT_UNIT is null
and (MOLECULE like '%NORELGESTROMIN%' or MOLECULE like '%ESTRADIOL%'  or MOLECULE like '%FLUTICASONE%'   or MOLECULE like '%BUDESONIDE%')
)
and amount_unit is null and AMOUNT_VALUE is not null
;
update ds_stage
set     amount_unit='MG'
where AMOUNT_VALUE is not null and AMOUNT_UNIT is null;

--units
INSERT INTO RELATIONSHIP_TO_CONCEPT(  CONCEPT_CODE_1,  VOCABULARY_ID_1,  CONCEPT_ID_2,  PRECEDENCE,CONVERSION_FACTOR) VALUES(  'TU',  'DA_France',  8510,  1,  1);
INSERT INTO RELATIONSHIP_TO_CONCEPT(  CONCEPT_CODE_1,  VOCABULARY_ID_1,  CONCEPT_ID_2,PRECEDENCE,  CONVERSION_FACTOR) VALUES(  'TU',  'DA_France',  8718,  2,  1);
INSERT INTO RELATIONSHIP_TO_CONCEPT(  CONCEPT_CODE_1,  VOCABULARY_ID_1, CONCEPT_ID_2,  PRECEDENCE,  CONVERSION_FACTOR)VALUES(  'CH',  'DA_France',  9324,  1,  1);
INSERT INTO RELATIONSHIP_TO_CONCEPT(  CONCEPT_CODE_1,  VOCABULARY_ID_1,  CONCEPT_ID_2, PRECEDENCE,  CONVERSION_FACTOR)VALUES(  'MO',  'DA_France',  9573,  1,  1000);

UPDATE RELATIONSHIP_TO_CONCEPT   SET CONCEPT_ID_2 = 35604680 WHERE CONCEPT_CODE_1 = 'OMOP6155' AND   CONCEPT_ID_2 = 561401 AND   PRECEDENCE = 1;
UPDATE RELATIONSHIP_TO_CONCEPT   SET CONCEPT_ID_2 = 1759842 WHERE CONCEPT_CODE_1 = 'OMOP2713' AND   CONCEPT_ID_2 = 19046939 AND   PRECEDENCE = 1;




commit
;
