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



commit
;
