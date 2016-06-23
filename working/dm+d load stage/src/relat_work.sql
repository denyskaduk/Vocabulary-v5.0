--xx1 CheckReplacementMappings
BEGIN
   DEVV5.VOCABULARY_PACK.CheckReplacementMappings;
END;
COMMIT;

--xx2 Deprecate 'Maps to' mappings to deprecated and upgraded concepts
BEGIN
   DEVV5.VOCABULARY_PACK.DeprecateWrongMAPSTO;
END;
COMMIT;

--xx3 Add mapping from deprecated to fresh concepts
  BEGIN
     DEVV5.VOCABULARY_PACK.AddFreshMAPSTO;
  END;
COMMIT;

--xx4 Delete ambiguous 'Maps to' mappings following by rules:
--1. if we have 'true' mappings to Ingredient or Clinical Drug Comp, then delete all others mappings
--2. if we don't have 'true' mappings, then leave only one fresh mapping
--3. if we have 'true' mappings to Ingredients AND Clinical Drug Comps, then delete mappings to Ingredients, which have mappings to Clinical Drug Comp
   BEGIN
       DEVV5.VOCABULARY_PACK.DeleteAmbiguousMAPSTO;
    END;
    COMMIT;
    


