DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = '33386-4'
AND   CONCEPT_ID_2 = 1326378
AND   PRECEDENCE = 2;
DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = '00758-2'
AND   CONCEPT_ID_2 = 975125
AND   PRECEDENCE = 2;
;
update drug_concept_stage 
set concept_class_id  = 'Drug Product' where concept_class_id like '%Drug%'
;
update drug_concept_stage 
set concept_class_id  = 'Supplier' where concept_class_id like 'Manufacturer'
;
commit
;
update drug_concept_stage
set standard_concept = null where concept_code in ( 
select a.concept_code_1 from internal_relationship_Stage a 
join drug_concept_stage b on a.concept_code_1 = b.concept_code 
join drug_concept_stage c on a.concept_code_2 = c.concept_code
where c.concept_class_id = 'Ingredient' and b.concept_class_id ='Ingredient')
;
update drug_concept_stage set STANDARD_CONCEPT ='S' where concept_code in (
select concept_code from drug_concept_stage 
left join internal_relationship_stage on concept_code_1 = concept_code
where concept_class_id ='Ingredient' and standard_concept is null and concept_code_2 is null
)
;
commit
;
update drug_concept_stage
set standard_concept = null where concept_class_id like 'Drug%'
;
commit
;
DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = 'microg'
AND   CONCEPT_ID_2 = 9655
AND   PRECEDENCE = 1;
DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = 'microl'
AND   CONCEPT_ID_2 = 9665
AND   PRECEDENCE = 2;
DELETE
FROM RELATIONSHIP_TO_CONCEPT
WHERE CONCEPT_CODE_1 = 'micromol'
AND   CONCEPT_ID_2 = 9667
AND   PRECEDENCE = 2;
UPDATE RELATIONSHIP_TO_CONCEPT
   SET PRECEDENCE = 1
WHERE CONCEPT_CODE_1 = 'M'
AND   CONCEPT_ID_2 = 8510
AND   PRECEDENCE = 2;
UPDATE RELATIONSHIP_TO_CONCEPT
   SET PRECEDENCE = 1
WHERE CONCEPT_CODE_1 = 'microg'
AND   CONCEPT_ID_2 = 8576
AND   PRECEDENCE = 2;
UPDATE RELATIONSHIP_TO_CONCEPT
   SET CONVERSION_FACTOR = 1000000
WHERE CONCEPT_CODE_1 = 'million cells'
AND   CONCEPT_ID_2 = 45744812
AND   PRECEDENCE = 1;
UPDATE RELATIONSHIP_TO_CONCEPT
   SET CONCEPT_ID_2 = 8576,
       CONVERSION_FACTOR = 0.000001
WHERE CONCEPT_CODE_1 = 'ng'
AND   CONCEPT_ID_2 = 9600
AND   PRECEDENCE = 1;
UPDATE RELATIONSHIP_TO_CONCEPT
   SET CONCEPT_ID_2 = 8576,
       CONVERSION_FACTOR = 1E-9
WHERE CONCEPT_CODE_1 = 'pg'
AND   CONCEPT_ID_2 = 8564
AND   PRECEDENCE = 1;

UPDATE RELATIONSHIP_TO_CONCEPT
   SET CONCEPT_ID_2 = 45744812
WHERE CONCEPT_CODE_1 = 'megmo';

commit
;


BEGIN
   DEVV5.VOCABULARY_PACK.SetLatestUpdate (pVocabularyName        => 'AMIS',
                                          pVocabularyDate        => TO_DATE ('20161029', 'yyyymmdd'),
                                          pVocabularyVersion     => 'AMIS 20161029',
                                          pVocabularyDevSchema   => 'DEV_amis');
                                          


                                        
                                          
  DEVV5.VOCABULARY_PACK.SetLatestUpdate (pVocabularyName        => 'RxNorm Extension',
                                          pVocabularyDate        => TO_DATE ('20161029', 'yyyymmdd'),
                                          pVocabularyVersion     => 'RxNorm Extension 20161029',
                                          pVocabularyDevSchema   => 'DEV_amis',
                                          pAppendVocabulary      => TRUE);

END;

COMMIT;


