drop table THIN_to_rx_tst;
create table THIN_to_rx_tst as
select distinct a.concept_code as concept_code_1, a.concept_name as concept_name_1, coalesce (rd3.concept_id, rd2.concept_id, d.concept_id) as concept_id_2,coalesce (rd3.concept_code, rd2.concept_code, d.concept_code) as concept_code_2, coalesce (rd3.concept_name, rd2.concept_name, d.concept_name) as concept_name_2,
coalesce (rd3.vocabulary_id, rd2.vocabulary_id, d.vocabulary_id) as vocabulary_id_2, coalesce (rd3.concept_class_id, rd2.concept_class_id, d.concept_class_id) as concept_class_id_2 
--distinct a.concept_class_id, d.concept_class_id,rd2.relationship_id, e.concept_class_id, rd3.concept_class_id
 from concept_stage a --'Gemscript THIN'
 join concept_relationship_stage rt on a.concept_code = rt.concept_code_1 
join concept_stage bt on  bt.concept_code = rt.concept_code_2 and bt.vocabulary_id = 'Gemscript' and bt.concept_class_id = 'Gemscript'

join concept_relationship_stage r on bt.concept_code = r.concept_code_1 
join devv5.concept b on  b.concept_code = r.concept_code_2 and b.vocabulary_id = 'dm+d' and b.domain_id = 'Drug' --and b.invalid_reason is  null

join devv5.concept_relationship rd on rd.concept_id_1 = b.concept_id and rd.invalid_reason is null
join  devv5.concept d on  d.concept_id = rd.concept_id_2 and d.vocabulary_id like 'RxNorm%' and d.invalid_reason is null
left join (select * from devv5.concept_relationship rd2 
join  devv5.concept e on  e.concept_id = rd2.concept_id_2 and e.vocabulary_id like 'RxNorm%' where rd2.invalid_reason is null and e.invalid_reason is null  and rd2.relationship_id in ('Tradename of', 'Marketed form of') ) rd2
 on rd2.concept_id_1 = d.concept_id
and regexp_count (d.concept_name, ' / ') = regexp_count (rd2.concept_name, ' / ') --remain the same counts of ingredients

left join (select * from devv5.concept_relationship rd3 
join  devv5.concept f on  f.concept_id = rd3.concept_id_2 and f.vocabulary_id like 'RxNorm%' and rd3.relationship_id = 'Tradename of' where rd3.invalid_reason is null and f.invalid_reason is null) rd3 on rd3.concept_id_1 = rd2.concept_id 
and regexp_replace (rd3.concept_class_id, 'Clinical', 'Branded') = rd2.concept_class_id-- and rd3.concept_class_id like '%Clinical%'
and  regexp_count (rd2.concept_name, ' / ') = regexp_count (rd3.concept_name, ' / ') 
where a.concept_class_id= 'Gemscript THIN'
;
DELETE
FROM THIN_TO_RX_TST
WHERE CONCEPT_CODE_1 = '85065998'
AND   CONCEPT_CODE_2 = 'OMOP288259';
DELETE
FROM THIN_TO_RX_TST
WHERE CONCEPT_CODE_1 = '85065998'
AND   CONCEPT_CODE_2 = 'OMOP288188';
DELETE
FROM THIN_TO_RX_TST
WHERE CONCEPT_CODE_1 = '61862979'
AND   CONCEPT_CODE_2 = 'OMOP288129';
DELETE
FROM THIN_TO_RX_TST
WHERE CONCEPT_CODE_1 = '61862979'
AND   CONCEPT_CODE_2 = 'OMOP288269';

delete from THIN_to_rx_tst where concept_class_id_2 like '%Branded%' or  concept_class_id_2 like '%Marketed%'
;
commit
;
drop table THIN_to_Rx_0811
; 
create table THIN_to_Rx_0811
as 
select c.concept_id, 'Maps to' as relationship_id, t.concept_id_2 from devv5.concept c join  THIN_to_rx_tst t on t.concept_code_1 = c.concept_code
where c.vocabulary_id = 'Gemscript'
;
commit
;