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
commit
;