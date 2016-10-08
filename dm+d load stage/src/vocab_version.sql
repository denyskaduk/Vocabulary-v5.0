BEGIN
   DEVV5.VOCABULARY_PACK.SetLatestUpdate (pVocabularyName        => 'dm+d',
                                          pVocabularyDate        => TO_DATE ('20160622', 'yyyymmdd'),
                                          pVocabularyVersion     => 'dm+d 20160622',
                                          pVocabularyDevSchema   => 'DEV_dmd');
                                          


                                        
                                          
  DEVV5.VOCABULARY_PACK.SetLatestUpdate (pVocabularyName        => 'RxNorm Extension',
                                          pVocabularyDate        => TO_DATE ('20160622', 'yyyymmdd'),
                                          pVocabularyVersion     => 'RxNorm Extension 20160622',
                                          pVocabularyDevSchema   => 'DEV_dmd',
                                          pAppendVocabulary      => TRUE);

END;
COMMIT;

update vocabulary set latest_update=to_date('20160622', 'yyyymmdd'), vocabulary_version='Gemscript 20160622', DEV_SCHEMA_NAME ='DEV_dmd'  where vocabulary_id='Gemscript'; commit;

