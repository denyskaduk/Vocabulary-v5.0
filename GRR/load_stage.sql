﻿/**************************************************************************
* Copyright 2016 Observational Health Data Sciences and Informatics (OHDSI)
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
* 
* Authors: Anna Ostropolets
* Date: 2017
**************************************************************************/ 
--creating table with nfc with old fcc
CREATE TABLE grr_new_3_for_form 
AS
(SELECT d.*,
       NFC_123_CD
FROM grr_pack a
  JOIN grr_pack_clas b ON b.PACK_ID = a.PACK_ID
  JOIN grr_class c ON c.clas_id = b.clas_id
  RIGHT JOIN grr_new_2 d ON a.fcc = d.fcc);

--adjusting date in GRR to source data date format
--create GRR table with  fcc||'_'||PRODUCT_LAUNCH_DATE as fcc
CREATE TABLE grr_new_3 
AS
(SELECT DISTINCT fcc|| '_' ||to_char(TO_DATE(PACK_LNCH_DT,'mm/dd/yyyy'),'mmddyyyy') AS FCC,
       PZN,INTL_PACK_FORM_DESC,INTL_PACK_STRNT_DESC,INTL_PACK_SIZE_DESC,PACK_DESC,PACK_SUBSTN_CNT,MOLECULE,WGT_QTY,WGT_UOM_CD, PACK_ADDL_STRNT_DESC,PACK_WGT_QTY,PACK_WGT_UOM_CD,PACK_VOL_QTY,PACK_VOL_UOM_CD,PACK_SIZE_CNT,
       ABS_STRNT_QTY,ABS_STRNT_UOM_CD,RLTV_STRNT_QTY,HMO_DILUTION_CD,FORM_DESC,BRAND_NAME1,BRAND_NAME,PROD_LNCH_DT, PACK_LNCH_DT,PACK_OUT_OF_TRADE_DT,PRI_ORG_LNG_NM,PRI_ORG_CD,NFC_123_CD
FROM grr_new_3_for_form);

UPDATE grr_new_3
   SET pzn = pzn|| '-' ||to_char(TO_DATE(PACK_OUT_OF_TRADE_DT,'mm/dd/yyyy'),'mm/dd/yyyy')
WHERE pzn IN (SELECT pzn
              FROM (SELECT DISTINCT fcc, pzn FROM grr_new_3)
              GROUP BY pzn
              HAVING COUNT(1) > 1)
AND   PACK_OUT_OF_TRADE_DT IS NOT NULL;

--create source table with  fcc||'_'||PRODUCT_LAUNCH_DATE as fcc
CREATE TABLE source_data_1 
AS
(SELECT CASE
         WHEN product_launch_date IS NULL THEN fcc
         ELSE fcc||'_'||to_char(to_date(product_launch_date,'dd.mm.yyyy'),'mmddyyyy')
         END AS fcc,
       LTRIM(pzn,'0') AS pzn,therapy_name_code,therapy_name, product_no,product_launch_date,product_form,product_form_name,strength,strength_unit,volume,volume_unit,packsize,form_launch_date,out_of_trade_date, manufacturer,manufacturer_name, manufacturer_short_name,who_atc5_code, who_atc5_text, who_atc4_code, who_atc4_text,who_atc3_code,who_atc3_text,who_atc2_code, who_atc2_text, who_atc1_code,who_atc1_text, substance, no_of_substances,nfc_no,nfc,nfc_description
FROM source_data_v2);

--non_drug
CREATE TABLE grr_non_drug 
AS
SELECT DISTINCT FCC,
       BRAND_NAME||INTL_PACK_FORM_DESC AS BRAND_NAME
FROM grr_new_3
WHERE REGEXP_LIKE (molecule,'ANTACIDS|BRAIN|\sTEST|\sTESTS|HOMOEOPATHIC MEDICINES|IOTROXIC ACID|BRANDY|AMIDOTRIZOATE|BONE|COUGH\sAND\sCOLD\sPREPARATIONS|REPELLENT|DIABETIC\sFOOD|BANDAGE|ELECTROLYTE\sSOLUTIONS|UREA\s13C|TOPICAL\sANALGESICS|APPLIANCES|INCONTINENCE|DRESSING|DISINFECTANT|KOMPRESS|BLOOD|DIALYSIS|DEVICE')
OR    REGEXP_LIKE (brand_name,'\.VET|TEST$|VET\.|TEST\s|KOMKPRESS|PLAST$|PLAST\s')
AND   molecule NOT LIKE '%TESTOSTER%'
OR    INTL_PACK_FORM_DESC LIKE '%WO SUB%';

INSERT INTO grr_non_drug(FCC,BRAND_NAME)
SELECT DISTINCT FCC,BRAND_NAME||INTL_PACK_FORM_DESC AS BRAND_NAME
FROM grr_new_3
WHERE REGEXP_LIKE (molecule,'WOUND|\sDIET\s|URINARY PREPARATION|MULTIVITAMINS AND MINERALS|NON\s|TECHNETIUM|IOTALAMIC ACID|TRADITIONAL\sINDIAN\sAYURVEDIC\sMEDICINE|WASHES|\sLENS\s|THROAT\sLOZENGES|SUN\sTAN\sLOTIONS/CREAMS')
OR    NFC_123_CD LIKE 'V%';

INSERT INTO grr_non_drug( FCC,BRAND_NAME)
SELECT DISTINCT fcc,IMS_PROD_LNG_NM||FORM_DESC
FROM grr_class a
  JOIN grr_pack_clas b USING (clas_id)
  JOIN grr_pack USING (pack_id)
WHERE WHO_ATC_4_CD LIKE 'V09%'
OR    WHO_ATC_4_CD LIKE 'V08%'
OR    WHO_ATC_4_CD LIKE 'V04%'
OR    WHO_ATC_4_CD LIKE 'B05ZB%'
OR    WHO_ATC_4_CD LIKE 'B05AX'
OR    WHO_ATC_4_CD LIKE 'D03AX32%'
OR    WHO_ATC_4_CD LIKE 'V03AX%'
OR    WHO_ATC_4_CD LIKE 'V10%'
OR    WHO_ATC_4_CD LIKE 'V06%'
OR    WHO_ATC_4_CD LIKE 'T2%'
AND   fcc NOT IN (SELECT fcc FROM grr_non_drug);

INSERT INTO grr_non_drug(FCC,BRAND_NAME)
SELECT FCC,BRAND_NAME||INTL_PACK_FORM_DESC
FROM grr_new_3
WHERE REGEXP_LIKE (brand_name,'WUND|KOMPRESS|VET\.|\.VET$|\sVET$')
OR    INTL_PACK_FORM_DESC LIKE '%FOOD%';

--insert source_data_1 
INSERT INTO grr_non_drug ( FCC,BRAND_NAME)
SELECT fcc, therapy_name
FROM source_data_1
WHERE REGEXP_LIKE (substance,'HAIR |ELECTROLYTE SOLUTION|ANTACIDS|ANTI-PSORIASIS|TOPICAL ANALGESICS|NASAL DECONGESTANTS|EMOLLIENT|MEDICAL|MEDICINE|SHAMPOOS|INFANT|INCONTINENCE|REPELLENT|^NON |MULTIVITAMINS AND MINERALS|DRESSING|WIRE|BRANDY|PROTECTAN|PROMOTIONAL|MOUTH|OTHER|CONDOM|LUBRICANTS|CARE |PARASITIC|COMBINATION')
OR    REGEXP_LIKE (substance,'DEVICE|CLEANS|DISINFECTANT|TEST| LENS|URINARY PREPARATION|DEODORANT|CREAM|BANDAGE|MOUTH |KATHETER|NUTRI|LOZENGE|WOUND|LOTION|PROTECT|ARTIFICIAL|MULTI SUBSTANZ|DENTAL| FOOT|^FOOT|^BLOOD| FOOD| DIET|BLOOD|PREPARATION|DIABETIC|UNDECYLENAMIDOPROPYL|DIALYSIS|DISPOSABLE|DRUG')
OR    substance IN ('EYE','ANTIDIARRHOEALS','BATH OIL','TONICS','ENZYME (UNSPECIFIED)','GADOBENIC ACID','SWABS','EYE BATHS','POLYHEXAMETHYLBIGUANIDE','AMBAZONE','TOOTHPASTES','GADOPENTETIC ACID','GADOTERIC ACID','KEINE ZUORDNUNG')
--or WHO_ATC5_TEXT='Keine Zuordnung'
OR    WHO_ATC4_CODE = 'V07A0'
OR    WHO_ATC5_CODE LIKE 'B05AX03%'
OR    WHO_ATC5_CODE LIKE 'B05AX02%'
OR    WHO_ATC5_CODE LIKE 'B05AX01%'
OR    WHO_ATC5_CODE LIKE 'V09%'
OR    WHO_ATC5_CODE LIKE 'V08%'
OR    WHO_ATC5_CODE LIKE 'V04%'
OR    WHO_ATC5_CODE LIKE 'B05AX04%'
OR    WHO_ATC5_CODE LIKE 'B05ZB%'
OR    WHO_ATC5_CODE LIKE '%B05AX %'
OR    WHO_ATC5_CODE LIKE '%D03AX32%'
OR    WHO_ATC5_CODE LIKE '%V03AX%'
OR    WHO_ATC5_CODE LIKE 'V10%'
OR    WHO_ATC5_CODE LIKE 'V %'
OR    WHO_ATC4_CODE LIKE 'X10%'
OR    WHO_ATC2_TEXT LIKE '%DIAGNOSTIC%'
OR    WHO_ATC1_TEXT LIKE '%DIAGNOSTIC%'
OR    NFC IN ('MQS','DYH')
OR    NFC LIKE 'V%';


INSERT INTO grr_non_drug ( FCC, BRAND_NAME)
SELECT FCC,BRAND_NAME||INTL_PACK_FORM_DESC
FROM grr_new_3
WHERE INITCAP(molecule) IN ('Anti-Dandruff Shampoo','Kidney Stones','Acrylic Resin','Anti-Acne Soap','Antifungal','Antioxidants','Arachnoidae','Articulation','Bath Oil','Breath Freshners','Catheters','Clay','Combination Products','Corn Remover','Creams (Basis)','Cresol Sulfonic Acid Phenolsulfonic Acid Urea-Formaldehyde Complex','Decongestant Rubs','Electrolytes/Replacers','Eye Make-Up Removers','Fish','Formaldehyde And Phenol Condensation Product','Formosulfathiazole,Herbal','Hydrocolloid','Infant Food Modified','Iocarmic Acid','Ioglicic Acid','Iopronic Acid','Iopydol','Iosarcol','Ioxitalamic Acid','Iud-Cu Wire & Au Core','Lipides','Lipids','Low Calorie Food','Massage Oil','Medicinal Mud','Minerals','Misc.Allergens (Patient Requirement)','Mumio','Musculi','Nasal Decongestants','Non-Allergenic Soaps','Nutritional Supplements','Oligo Elements','Other Oral Hygiene Preparations','Paraformaldehyde-Sucrose Complex','Polymethyl Methacrylate','Polypeptides','Purgative/Laxative','Quaternary Ammonium Compounds','Rock','Saponine','Shower Gel','Skin Lotion','Sleep Aid','Slug','Suxibuzone','Systemic Analgesics','Tonics','Varroa Destructor','Vasa','Vegetables Extracts')
UNION
SELECT fcc, therapy_name
FROM source_data_1
WHERE INITCAP(substance) IN ('Anti-Dandruff Shampoo','Kidney Stones','Acrylic Resin','Anti-Acne Soap','Antifungal','Antioxidants','Arachnoidae','Articulation','Bath Oil','Breath Freshners','Catheters','Clay','Combination Products','Corn Remover','Creams (Basis)','Cresol Sulfonic Acid Phenolsulfonic Acid Urea-Formaldehyde Complex','Decongestant Rubs','Electrolytes/Replacers','Eye Make-Up Removers','Fish','Formaldehyde And Phenol Condensation Product','Formosulfathiazole,Herbal','Hydrocolloid','Infant Food Modified','Iocarmic Acid','Ioglicic Acid','Iopronic Acid','Iopydol','Iosarcol','Ioxitalamic Acid','Iud-Cu Wire & Au Core','Lipides','Lipids','Low Calorie Food','Massage Oil','Medicinal Mud','Minerals','Misc.Allergens (Patient Requirement)','Mumio','Musculi','Nasal Decongestants','Non-Allergenic Soaps','Nutritional Supplements','Oligo Elements','Other Oral Hygiene Preparations','Paraformaldehyde-Sucrose Complex','Polymethyl Methacrylate','Polypeptides','Purgative/Laxative','Quaternary Ammonium Compounds','Rock','Saponine','Shower Gel','Skin Lotion','Sleep Aid','Slug','Suxibuzone','Systemic Analgesics','Tonics','Varroa Destructor','Vasa','Vegetables Extracts');

--drugs without ingredients
--insert into grr_non_drug (fcc,brand_name)
--select FCC,BRAND_NAME||INTL_PACK_FORM_DESC from grr_new_3 where molecule is null;

--deleting non-drugs from working tables
DELETE grr_new_3
WHERE fcc IN (SELECT fcc FROM grr_non_drug);
DELETE source_data_1
WHERE fcc IN (SELECT fcc FROM grr_non_drug);


--creating table with packs
CREATE TABLE grr_pack_0 
AS
SELECT DISTINCT a.*, INTL_PACK_STRNT_DESC, FORM_DESC,REGEXP_REPLACE(brand_name,'\s\s+.*') AS brand_name
FROM grr_ds a
  JOIN grr_new_3 b ON a.fcc = b.fcc
WHERE a.fcc IN (SELECT fcc
                FROM grr_ds
                GROUP BY fcc,molecule
                HAVING COUNT(1) > 1 --and regexp_like (FORM_DESC,'/|KOMBI PCKG|TAB.R.CHRONO')
);

DELETE grr_pack_0
WHERE NOT REGEXP_LIKE (FORM_DESC,'/|TAB.R.CHRONO|CHRONOS');

--choose not to take KOMBI PCKG
CREATE TABLE grr_pack_1 AS
  WITH lng AS
       (SELECT fcc, MIN(LENGTH(brand_name)) AS lng FROM grr_pack_0 GROUP BY fcc)
SELECT b.*
FROM grr_pack_0 b
  JOIN lng
    ON b.fcc = lng.fcc AND lng.lng = (LENGTH (b.brand_name))
ORDER BY b.fcc;


CREATE TABLE grr_pack_2 AS
SELECT fcc, box_size,  molecule, DENOMINATOR_VALUE, DENOMINATOR_UNIT, AMOUNT_VALUE,AMOUNT_UNIT,brand_name, case when box_size is not null then molecule|| ' ' ||AMOUNT_VALUE||' '||AMOUNT_UNIT|| ' ' ||' box of '||box_size|| '[' ||brand_name|| ']' else molecule|| ' ' ||AMOUNT_VALUE||' '||AMOUNT_UNIT|| ' [' ||brand_name|| ']'  end AS drug_name
FROM grr_pack_1;

--fix existing bias from original data
DELETE
FROM GRR_NEW_3
WHERE FCC = '635693_09012008'
AND   MOLECULE = 'BENZOYL PEROXIDE';

--brand names
CREATE TABLE grr_bn  AS
SELECT DISTINCT fcc, REGEXP_REPLACE(brand_name,'(\s\s+.*)|>>') AS bn,brand_name AS old_name
FROM grr_new_3;

INSERT INTO grr_bn (fcc,bn,old_name)
SELECT fcc,
       CASE
         WHEN therapy_name LIKE '%  %' THEN REGEXP_REPLACE(therapy_name,'\s\s.*')
         ELSE REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(therapy_name,'\d+\.?\d+(%|C|CM|D|G|GR|IM|VIP|TABL|IU|K|K.|KG|L|LM|M|MG|ML|MO|NR|O|TU|Y|Y/H)+'),'\d+\.?\d?(%|C|CM|D|G|GR|IU|K|K.|KG|L|LM|M|MG|ML|MO|NR|O|TU|Y|Y/H)+'),'\(.*\)'),REGEXP_REPLACE(PRODUCT_FORM_NAME|| '.*','\s\s','\s')) END,
       therapy_name
FROM source_data_1;

--start from source data patterns
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(REGEXP_REPLACE(TRIM(REGEXP_REPLACE(bn,'(\S)+(\.)+(\S)*(\s\S)*(\s\S)*')),'(TABL|>>|ALPHA|--)*'),'(\d)*(\s)*(\.)+(\S)*(\s\S)*(\s)*(\d)*')
WHERE bn LIKE '%.%';

UPDATE grr_bn
   SET bn = REGEXP_REPLACE(TRIM(REGEXP_REPLACE(bn,'(\S)*\+(\S|\d)*')),'(\d|D3|B12|IM|FT|AMP|INF| INJ|ALT$)*')
WHERE bn LIKE '%+%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'\s\s.*')
WHERE bn LIKE '%  %';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'(\S)+(>>).*')
WHERE bn LIKE '%>>%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'(\S)+(/).*')
WHERE bn LIKE '%/%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'\(.*')
WHERE bn LIKE '%(%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'(INJ).*')
WHERE bn LIKE '% INJ %'
OR    REGEXP_LIKE (bn,'INJ^');

UPDATE grr_bn
   SET bn = REGEXP_REPLACE(RTRIM(REGEXP_REPLACE(bn,'(\s)+(\S-\S)+'),'-'),'(TABL|ALT|AAA|ACC |CAPS|LOTION| SUPP)')
WHERE bn NOT LIKE 'ALT%';

--make suppliers to a standard
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'RATIOPH\.|RAT\.|RATIO\.|RATIO |\sRAT$','RATIOPHARM');
UPDATE grr_bn
   SET bn = TRIM(REGEXP_REPLACE(bn,'SUBLINGU\.|SUPPOSITOR\.|INJ\.'));
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'HEUM\.|HEU\.','HEUMANN');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'SAND\.','SANDOZ');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'NEURAXPH\.','NEURAXPHARM');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'RATIOP$|RATIOP\s','RATIOPHARM');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'WINTHR\.','WINTHROP');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'1A PH\.','1A PHARMA');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'INJEKTOP\.','INJEKTOPAS');
UPDATE grr_bn
   SET BN = REGEXP_REPLACE(bn,'(HEUMANN HEU)|(HEUMAN HEU)| HEU$','HEUMANN');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'KHP$','KOHLPHARMA')
WHERE bn LIKE '%KHP';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'E-M$','EURIM-PHARM')
WHERE bn LIKE '%E-M';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'MSD$','MERCK')
WHERE bn LIKE '%MSD';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'ZEN$','ZENTIVA')
WHERE bn LIKE '%ZEN';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'WTH$','WESTEN PHARMA')
WHERE bn LIKE '%WTH';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'ORI$','ORIFARM')
WHERE bn LIKE '%ORI';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'RDX$','REMEDIX')
WHERE bn LIKE '%RDX';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'PBA$','PB PHARMA')
WHERE bn LIKE '%PBA';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'ACCORD\s.*')
WHERE bn LIKE '% ACCORD%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'ROTEXM','ROTEXMEDICA')
WHERE bn LIKE '%ROTEXM%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'LICH','LICHTENSTEIN')
WHERE bn LIKE '% LICH'
OR    bn LIKE '% LICH %';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'WINTHR','WINTHROP')
WHERE bn LIKE '%WINTHR'
OR    bn LIKE '%WINTHR %';

--same with BN
UPDATE grr_bn
   SET bn = 'ABILIFY MAINTENA'
WHERE bn LIKE '%ABILIFY MAIN%';
UPDATE grr_bn
   SET bn = 'INFANRIX'
WHERE REGEXP_LIKE (bn,'^INFA');
UPDATE grr_bn
   SET bn = 'MYDOCALM'
WHERE REGEXP_LIKE (bn,'MYDOCALM');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'SPIRONOL.','SPIRONOLACTONE ')
WHERE bn LIKE '%SPIRONOL.%';
UPDATE grr_bn
   SET bn = 'OVYSMEN'
WHERE REGEXP_LIKE (bn,'OVYSM');
UPDATE grr_bn
   SET bn = 'ORTHO-NOVUM'
WHERE REGEXP_LIKE (bn,'ORTHO-N');
UPDATE grr_bn
   SET bn = 'CYKLOKAPRON'
WHERE REGEXP_LIKE (bn,'^CYKLOK');
UPDATE grr_bn
   SET bn = 'ZADITEN'
WHERE REGEXP_LIKE (bn,'ZADITEN');
UPDATE grr_bn
   SET bn = 'VOLTAREN'
WHERE REGEXP_LIKE (bn,'VOLTAREN');
UPDATE grr_bn
   SET bn = 'ALLEVYN'
WHERE REGEXP_LIKE (bn,'ALLEVY');
UPDATE grr_bn
   SET bn = 'OTRIVEN'
WHERE REGEXP_LIKE (bn,'OTRIVEN')
AND   bn != 'OTRIVEN DUO';
UPDATE grr_bn
   SET bn = 'SEEBRI'
WHERE bn LIKE '%SEEBRI%';
UPDATE grr_bn
   SET bn = 'DIDRONEL'
WHERE bn LIKE '%DIDRONEL%';
UPDATE grr_bn
   SET bn = 'ISCADOR'
WHERE REGEXP_LIKE (bn,'ISCADOR');
UPDATE grr_bn
   SET bn = 'NOVIRELL'
WHERE REGEXP_LIKE (bn,'NOVIRELL');
UPDATE grr_bn
   SET bn = 'QUINALICH'
WHERE bn LIKE '%QUINALICH%';
UPDATE grr_bn
   SET bn = 'TENSOBON'
WHERE bn LIKE '%TENSOBON%';
UPDATE grr_bn
   SET bn = 'PRESOMEN'
WHERE bn LIKE '%PRESOMEN%';
UPDATE grr_bn
   SET bn = 'BLOPRESID'
WHERE bn LIKE '%BLOPRESID%';
UPDATE grr_bn
   SET bn = 'NEO STEDIRIL'
WHERE bn LIKE '%NEO STEDIRIL%';
UPDATE grr_bn
   SET bn = 'TETESEPT'
WHERE bn LIKE '%TETESEPT%';
UPDATE grr_bn
   SET bn = 'ALKA SELTZER'
WHERE bn LIKE '%ALKA SELTZER%';
UPDATE grr_bn
   SET bn = 'BISOPROLOL VITABALANS'
WHERE bn LIKE '%BISOPROLOL VITABALANS%';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'(\.)?\sCOMP\.',' ')
WHERE REGEXP_LIKE (bn,'(\sCOMP$)|(\.COMP$)|COMP\.|RATIOPHARMCOMP');
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,' COMP')
WHERE bn LIKE '% COMP'
OR    bn LIKE '% COMP %';
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'ML/$|CB/$|KL/$|\(SA/|\(OR/|\.IV|INHALAT|INHAL| INH|VAGINALE|SAFT|TONIKUM|TROPF| SALB| NO&| (NO$)');
UPDATE grr_bn
   SET bn = TRIM(REGEXP_REPLACE(bn,'TABL$|SCHMERZTABL| KAPS|SCHM.TABL.| SCHM.$|TABLETTEN|BET\.M|RETARDTABL|\sTABL.'));
UPDATE grr_bn
   SET bn = TRIM(REGEXP_REPLACE(bn,'\(.*'));
UPDATE grr_bn
   SET bn = TRIM(REGEXP_REPLACE(bn,'(\d+\.)?\d+\%.*'))
WHERE REGEXP_LIKE (bn,'\d+\%');

--delete 5%;
UPDATE grr_bn
   SET bn = REGEXP_REPLACE(bn,'SUP|(\d$)| PW|( DRAG.*)|( ORAL.*)')
WHERE bn NOT LIKE 'SUP%';
UPDATE GRR_BN
   SET BN = 'DEXAMONOZON'
WHERE BN = 'DEXAMONOZON SUPP.';
UPDATE grr_bn
   SET BN = REGEXP_REPLACE(bn,'-',' ');
UPDATE grr_bn
   SET bn = TRIM(REGEXP_REPLACE(bn,'  ',' '));
   
CREATE TABLE grr_bn_2  AS
WITH lng AS (SELECT fcc,MAX(LENGTH(bn)) AS lng 
		FROM grr_bn GROUP BY fcc)
SELECT DISTINCT b.*
FROM grr_bn b
  JOIN lng
    ON b.fcc = lng.fcc   AND lng.lng = (LENGTH (b.bn))
ORDER BY b.fcc;

DELETE grr_bn_2
WHERE INITCAP(bn) IN ('Pantoprazol','Parenteral','Nifedipin','Neostigmin','Naloxon','Metoclopramid','Metronidazol','Miconazol','Methotrexat','Mesalazin','Loperamid','Lidocain','Laxative','Hydrocortison','Histamin','Ginko','Ephedrin','Doxycyclin','Dimenhydrinat','Diclofen','Cyclopentolat','Complex','Benzocain','Atropin','Amiodaron','Aconit','Pamidronat','Pilocarpin','Prednisolon','Progesteron','Promethazin','Cetirizin','Felodipin','Glibenclamid','Indapamid','Cefuroxim','Rabies','Spironolacton','Symphytum','Sandoz Schmerzgel','Testosteron','Theophyllin','Urtica','Valproat','Vincristin','Vitis','Omeprazol','Paroxetin','Ranitidin');

DELETE grr_bn_2
WHERE INITCAP(bn) IN ('Oestradiol','Nalorphin','Oestriol','Cholesterin','Cephazolin','Aspen','Aristo','Bausch & Lomb','Lily');

DELETE grr_bn_2
WHERE REGEXP_LIKE (bn,'BLAEHUNGSTABLETTEN|KOMPLEX|GALGANTTABL|PREDNISOL\.|LOESG|ALBUMIN|BABY|ANDERE|--|/|ACID.*\.|SCHLAFTABL\.|VIT.B12\+|RINGER|M8V|F4T|\. DHU|TABACUM|A8X|CA2|GALLE|BT5|KOCHSALZ|V3P|D4F|AC9|B9G|BC4|GALLE-DR\.|\+|SCHUESSL BIOCHEMIE|^BIO\.|BLAS\.|SILIC\.|KPK|CHAMOMILLA|ELEKTROLYT|AQUA|KNOBLAUCH|FOLSAEURE|VITAMINE|/|AQUA A|LOESUNG')
AND   NOT REGEXP_LIKE (bn,'PHARM|ABTEI|HEEL|INJEE|HEUMANN|MERCK|BLUESFISH|WESTERN|PHARMA|ZENTIVA|PFIZER|PHARMA|MEDE|MEDAC|FAIR|HAMELN|ACCORD|RATIO|AXCOUNT|STADA|SANDOZ|SOLVAY|GLENMARK|APOTHEKE|HEXAL|TEVA|AUROBINDO|ORION|SYXYL|NEURAX|KOHNE|ACTAVIS|CLARIS|NOVUM|ABZ|AXCOUNT|MYLAN|ARISTO|KABI|BENE|HORMOSAN|ZENTIVA|PUREN|BIOMO|ACIS|RATIOPH|SYNOMED|ALPHA|ROTEXMEDICA|BERCO|DURA|DAGO|GASTREU|FORTE|VITAL|VERLA|ONKOVIS|ONCOTRADE|NEOCORP');

 DELETE grr_bn_2 WHERE REGEXP_LIKE (bn,'TROPFEN|TETANUS|FAKTOR| KAPSELN|RNV|COMPOSITUM| SC | CARBON|COMPLEX|SLR| PUR|OLEUM|FERRUM|ROSMARIN|SYND|NATRIUM|BIOCHEMIE|URTICA|VALERIANA|DULCAMARA|SALZ| LH| DHU|HERBA|SULFUR|TINKTUR|PRUNUS|ZEMENT|KALIUM|ALUMIN|SOLUM| AKH| A1X| SAL| DHU|B\d|FLOR| ANTIDOT|ARNICA|KAMILLEN')
AND   NOT REGEXP_LIKE (bn,'PHARM|ABTEI|HEEL|INJEE|HEUMANN|MERCK|BLUESFISH|WESTERN|PHARMA|ZENTIVA|PFIZER|PHARMA|MEDE|MEDAC|FAIR|HAMELN|ACCORD|RATIO|AXCOUNT|STADA|SANDOZ|SOLVAY|GLENMARK|APOTHEKE|HEXAL|TEVA|AUROBINDO|ORION|SYXYL|NEURAX|KOHNE|ACTAVIS|CLARIS|NOVUM|ABZ|AXCOUNT|MYLAN|ARISTO|KABI|BENE|HORMOSAN|ZENTIVA|PUREN|BIOMO|ACIS|RATIOPH|SYNOMED|ALPHA|ROTEXMEDICA|BERCO|DURA|DAGO|GASTREU|FORTE|VITAL|VERLA|ONKOVIS|ONCOTRADE|NEOCORP|( AWD$)')
;

DELETE grr_bn_2
WHERE REGEXP_LIKE (BN,'SILICEA|STANNUM|SAURE|CAUSTICUM|CASCARA|FOLINATE|FOLATE|COLOCYNTHIS|CUPRUM|CALCIUM|SODIUM|BLUETEN|ACETYL|CHLORID|ACIDIDUM|ACIDUM|LIDOCAIN|ESTRADIOL|NACHTKERZENOE|NEOSTIGMIN|METALLICUM|SPAGYRISCHE|ARCANA|SULFURICUM|BERBERIS|BALDRIAN|TILIDIN| VIT ')
AND   NOT REGEXP_LIKE (bn,'PHARM|ABTEI|HEEL|INJEE|HEUMANN|MERCK|BLUESFISH|WESTERN|PHARMA|ZENTIVA|PFIZER|PHARMA|MEDE|MEDAC|FAIR|HAMELN|ACCORD|RATIO|AXCOUNT|STADA|SANDOZ|SOLVAY|GLENMARK|APOTHEKE|HEXAL|TEVA|AUROBINDO|ORION|SYXYL|NEURAX|KOHNE|ACTAVIS|CLARIS|NOVUM|ABZ|AXCOUNT|MYLAN|ARISTO|KABI|BENE|HORMOSAN|ZENTIVA|PUREN|BIOMO|ACIS|RATIOPH|SYNOMED|ALPHA|ROTEXMEDICA|BERCO|DURA|DAGO|GASTREU|FORTE|VITAL|VERLA|ONKOVIS|ONCOTRADE|NEOCORP')
;

DELETE grr_bn_2
WHERE REGEXP_LIKE (old_name,' DIM | LH| DHU | SOH|LHRH')
AND   NOT REGEXP_LIKE (bn,'CO TRIMOXAZOL|APO GO|EFEU');

DELETE grr_bn_2
WHERE bn LIKE '%)%'
OR    bn LIKE '% SAND';

DELETE grr_bn
WHERE bn IN ('GAMMA','ADENOSIN','AGNUS','MORPHIN','MYCOPHENOLATMOFETIL','MYRTILLUSNASENSPRAY','NASENOEL','TETRACAIN','TETRACYCLIN','TILIDIN','TOLTERODIN','ZOPICLON','ZONISAMID','ZINCUM','TRIMIPRAMIN','TOPIRAMAT','TOLTERODIN','TILIDIN','TICLOPIDIN','TERBINAFIN','SULPIRID','SULFUR JODATUM ARC','SULFUR DERMATOPLEX','SPIRONOTHIAZID','SPIRONOLACTON IUN>','SPIRONOLACTON AWD','RISPERIDON','RHEUMA LOGES N','RABEPRAZOL','QUETIAPIN','PETROSELINUM','PENTOXIFYLLIN','PASSIFLORA','PANKREATIN','PACLITAXEL GRY BBF','PACLITAXEL GRY','OXCARBAZEPIN','OXAZEPAM TAD','OXAZEPAM K KPH','OXAZEPAM AL','MYCOPHENOLATMOFETIL','MORPHIN','MOCLOBEMID','LEVISTICUM','LEFLUNOMID','LEDUM PALUSTRE S3G','LEDUM PALUSTRE S','LEDUM ARCANA','LEDUM AMP','LEDUM','LANSOPRAZOL','LAMOTRIGIN AWD','LAMOTRIGIN','LAMIVUDIN','L TYROSINE','L TYROSIN','L TRYPTOPHAN','L THYROXIN NA','L THYROXIN JOD BET','L THYROSIN','L THREONIN','L TAURIN','L SERIN','L PROLIN','L PHENYLALANIN VBN','L PHENYLALANIN NUT','L PHENYLALANIN','L ORNITHIN','L METHIONIN','L LYSINE','L LYSIN HCL','L LYSIN','L LEUCIN','L ISOLEUCIN','L INSULIN','L HISTIDIN','L GLUTATHION','L GLUTAMINE','HEPARIN GEL','HEPARIN AL','HAEMONINE','GLIMEPIRID','GINKGO','GELONIDA','FUROSEMID','FLUCONAZOL','CACTUS ARCANA','CACTUS','BROMOCRIPTIN','BISOPROLOL KSK','BICALUTAMID','BEZAFIBRAT','BETAMETHASON','BENAZEPRIL HCT KWZ','BENAZEPRIL HCT AWD','BARIUM MURIATICUM ARC','BALDRIAN','B INSULIN S','B INSULIN','B 12 L 9','B 12 AS','AURUM VALERIANA','AURUM SULFURATUM ARC','AURUM RC','AURUM PHOSPHORICUM ARC','AURUM MURIATICUM NATRONATUM GUD','AURUM MURIATICUM GUD','AURUM JODATUM PENTARKAN','AURUM JODATUM ARCANA','AURUM','AUREOMYCIN N','AUREOMYCIN CA','AUREOMYCIN','ATROPINUM','ATRACURIUM CRM','ANASTROZOL','AMPICILLIN USP CKC','AMPICILLIN UND SULBACTAM IBISQUS','AMPICILLIN PLUS SULBACTAM EBERTH','AMPICILLIN NJ','AMOROLFIN','AMLODIPIN','AMITRIPTYLIN','AMANTADIN','AMANTA SULFAT','AMANTA HCL','AMANTA','ALOE VERA MEP','ALOE VERA I','ALOE VERA AMS','ALOE VERA A','ALOE SOCOTRINA GUD','ALOE GRANULAT SCHUCK','ALENDRONSAEURE AL','ALENDRONSAEURE ACCORD','ACEROLA CHIPS','MULTIVITAMIN','ACEROLA C');

DELETE grr_bn_2
WHERE LENGTH(bn) < 4
OR    bn IS NULL;

DELETE grr_bn_2
WHERE LENGTH(bn) = 4
AND   REGEXP_SUBSTR(bn,'\w') != REGEXP_SUBSTR(old_name,'\w');

DELETE
FROM grr_bn_2
WHERE (LENGTH(bn) < 6
AND   bn LIKE '% %'
AND   bn NOT IN ('OME Q','O PUR','IUP T','GO ON','AZA Q'));

--deleting all sorts of ingredients
DELETE grr_bn_2
WHERE UPPER(bn) IN (SELECT UPPER(molecule) FROM grr_new_3);
DELETE grr_bn_2
WHERE UPPER(bn) IN (SELECT UPPER(SUBSTANCE) FROM source_data_1);
DELETE grr_bn_2
WHERE UPPER(bn) IN (SELECT UPPER(concept_name)
                    FROM concept
                    WHERE concept_class_id IN ('Ingredient','AU Substance','ATC 5th','Chemical Structure','Substance','Pharma/Biol Product','Pharma Preparation','Clinical Drug Form','Dose Form','Precise Ingredient'));

DELETE grr_bn_2
WHERE bn IN (SELECT BN FROM bn_to_del);

--deleting repeating BN
DELETE grr_bn_2
WHERE ROWID NOT IN (SELECT MIN(ROWID) FROM grr_bn_2 GROUP BY fcc);

--deleting BN that has already been cleaned up

delete grr_bn_2 where lower(bn) in
(select lower(concept_name) from concept where vocabulary_id = 'RxNorm Extension' and concept_class_id = 'Brand Name' and invalid_reason = 'D'); 

--manufacturers
CREATE TABLE grr_manuf_0 
AS
SELECT DISTINCT a.fcc, EFF_FR_DT, EFF_TO_DT, PRI_ORG_CD, TRIM(REGEXP_REPLACE(PRI_ORG_LNG_NM,'>>')) AS PRI_ORG_LNG_NM, CUR_REC_IND
FROM GRR_PACK a
  JOIN GRR_PACK_CLAS b ON a.pack_id = b.pack_id
  JOIN grr_new_3 c ON c.fcc = a.fcc
WHERE CUR_REC_IND = '1';

--inserting suppliers from source data
INSERT INTO grr_manuf_0 (fcc,PRI_ORG_LNG_NM)
SELECT DISTINCT fcc,manufacturer_name
FROM source_data_1;

CREATE TABLE grr_manuf  AS
SELECT DISTINCT fcc,REGEXP_REPLACE(PRI_ORG_LNG_NM,'\s\s+>>') AS PRI_ORG_LNG_NM
FROM grr_manuf_0;

--take 
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'TAKEDA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%TAKEDA%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'BAYER'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%BAYER%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ABBOTT'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%ABBOTT%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'PFIZER'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%PFIZER%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'BOEHRINGER'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%BEHR%'
              OR    PRI_ORG_LNG_NM LIKE '%BOEH%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'MERCK DURA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%MERCK%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'RATIOPHARM'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%RATIO%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'MERCK DURA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%MERCK%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'GEDEON RICHTER'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%RICHT%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'SANOFI'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%SANOFI%'
              OR    PRI_ORG_LNG_NM LIKE '%SYNTHELABO%'
              OR    PRI_ORG_LNG_NM LIKE '%AVENTIS%'
              OR    PRI_ORG_LNG_NM LIKE '%ZENTIVA%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'NOVARTIS'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%NOVART%'
              OR    PRI_ORG_LNG_NM LIKE '%SANDOZ%'
              OR    PRI_ORG_LNG_NM LIKE '%HEXAL%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ACTAVIS'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%ACTAVIS%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ASTRA ZENECA'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%ASTRA%'
              OR    PRI_ORG_LNG_NM LIKE '%ZENECA%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'GLAXOSMITHKLINE'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%SMITHKL%'
              OR    PRI_ORG_LNG_NM LIKE '%GLAXO%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'WESTEN PHARMA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%WESTEN%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ASTELLAS'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%ASTELLAS%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ASTA PHARMA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%ASTA%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ABZ PHARMA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%ABZ%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'HORMOSAN PHARMA'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%HORMOSAN%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'LUNDBECK'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%LUNDBECK%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'EU RHO ARZNEI'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%EU RHO%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'B.BRAUN'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%.BRAUN%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'BIOGLAN'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%BIOGLAN%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'MEPHA-PHARMA'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%MEPHA%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'PIERRE FABRE'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%PIERRE%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'FOURNIER PHARMA'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%FOURNIER%');
UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'JOHNSON&JOHNSON'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%JOHNSON%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'AASTON HEALTH'
WHERE fcc IN (SELECT fcc FROM grr_manuf WHERE PRI_ORG_LNG_NM LIKE '%AASTON%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'HAEMATO PHARM'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%HAEMATO PHARM%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'STRATHMANN'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%STRATHMANN%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = 'ACA MUELLER'
WHERE fcc IN (SELECT fcc
              FROM grr_manuf
              WHERE PRI_ORG_LNG_NM LIKE '%MUELLER%');

UPDATE grr_manuf
   SET PRI_ORG_LNG_NM = REGEXP_REPLACE(PRI_ORG_LNG_NM,'>');


update grr_manuf
set PRI_ORG_LNG_NM = regexp_replace (PRI_ORG_LNG_NM, ' Pharma| Health')
where regexp_like (PRI_ORG_LNG_NM, '( Pharma| Health)$');

UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Aslan' where PRI_ORG_LNG_NM = 'ASLAN ARZNEIMITTEL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Aurelia' where PRI_ORG_LNG_NM = 'AURELIA MEDICAL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Bano' where PRI_ORG_LNG_NM = 'BANO HEALTHCARE';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Bioline' where PRI_ORG_LNG_NM = 'BIOLINE KATWIJK';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Bioline' where PRI_ORG_LNG_NM = 'BIOLINE PRODUCTS';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Bsn' where PRI_ORG_LNG_NM = 'BSN MEDICAL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Eer Handels' where PRI_ORG_LNG_NM = 'EER HANDELS GMBH';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Emu' where PRI_ORG_LNG_NM = 'EMU EUROPE';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Europe' where PRI_ORG_LNG_NM = 'DEB-STOKO EUROPE';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Gms' where PRI_ORG_LNG_NM = 'GMS GERMAN MEDICAL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Grana' where PRI_ORG_LNG_NM = 'GRANA MEDICAL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Cicoare' where PRI_ORG_LNG_NM = 'CICOARE HANDEL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'IMP' where PRI_ORG_LNG_NM = 'IMP NEUSS';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Jacobs' where PRI_ORG_LNG_NM = 'JACOBS MEDICAL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'K&M' where PRI_ORG_LNG_NM = 'K&M BIO';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'K&M' where PRI_ORG_LNG_NM = 'K&M HANDEL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Mdm' where PRI_ORG_LNG_NM = 'MDM HEALTHCARE';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Mic' where PRI_ORG_LNG_NM = 'MIC MEDICAL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Nawa' where PRI_ORG_LNG_NM = 'NAWA HEILMITTEL';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Sm' where PRI_ORG_LNG_NM = 'SM GMBH';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Synofit' where PRI_ORG_LNG_NM = 'SYNOFIT EUROPE';
UPDATE grr_manuf    SET PRI_ORG_LNG_NM = 'Wtm' where PRI_ORG_LNG_NM = 'WTM TRADING';


--ingredient
DELETE grr_manuf
WHERE PRI_ORG_LNG_NM IN ('OLIBANUM','EIGENHERSTELLUNG');

DELETE grr_manuf
WHERE LOWER(PRI_ORG_LNG_NM) IN (SELECT LOWER(concept_name)
                                FROM concept
                                WHERE concept_class_id = 'Ingredient');

--delete strange manufacturers
DELETE grr_manuf
WHERE PRI_ORG_LNG_NM LIKE '%/%'
OR    PRI_ORG_LNG_NM LIKE '%.%'
OR    PRI_ORG_LNG_NM LIKE '%APOTHEKE%'
OR    PRI_ORG_LNG_NM LIKE '%IMPORTE AUS%'
OR    initcap (PRI_ORG_LNG_NM) IN ('Freie Handelsvertr','Biopraep','Ce Medizinprodukte','Kraeuter-Meyer','Manufaktur Apothek','Medical','Pharma Biologica','Pharma Brutscher','Pharma Dynamics','Pharma K Medical','Pharma Labor','Pharma Planet','Pharma Reha Care','Pharma Solutions','Pharma Winter','Pharma Wittmann','Pharmacy Consult','Pc Pharm Commerce');



DELETE grr_manuf
WHERE LENGTH(PRI_ORG_LNG_NM) < 4;


--deleting BNs that looks like suppliers
DELETE grr_bn_2
WHERE UPPER(bn) IN (SELECT UPPER(PRI_ORG_LNG_NM) FROM grr_manuf);

--dose form
CREATE TABLE grr_form 
AS
SELECT fcc,INTL_PACK_FORM_DESC,NFC_123_CD
FROM grr_new_3
UNION
SELECT fcc,PRODUCT_FORM_NAME,
       CASE
         WHEN NFC = 'ZZZ' THEN NULL
         ELSE nfc END 
FROM source_data_1;

UPDATE grr_form   SET NFC_123_CD = 'BAA' WHERE REGEXP_LIKE (INTL_PACK_FORM_DESC,'(CT TAB)|(EC TAB)|(FC TAB)|(RT TAB)');
UPDATE grr_form   SET NFC_123_CD = 'BCA' WHERE REGEXP_LIKE (INTL_PACK_FORM_DESC,'(RT CAP)|(EC CAP)');
UPDATE grr_form   SET NFC_123_CD = 'ACA' WHERE INTL_PACK_FORM_DESC = 'CAP';
UPDATE grr_form   SET NFC_123_CD = 'AAA' WHERE INTL_PACK_FORM_DESC = '%LOZ';
UPDATE grr_form   SET NFC_123_CD = 'DEP' WHERE INTL_PACK_FORM_DESC IN (' ORL UD PWD',' ORL SLB PWD',' ORL PWD');
UPDATE grr_form   SET NFC_123_CD = 'DGB' WHERE INTL_PACK_FORM_DESC IN (' ORL DRP',' ORAL LIQ',' ORL MD LIQ',' ORL RT LIQ',' ORL UD LIQ',' ORL SYR',' ORL SUSP',' ORL SPIRIT','','','');
UPDATE grr_form   SET NFC_123_CD = 'TAA' WHERE INTL_PACK_FORM_DESC IN ('VAG COMB TAB','VAG TAB');
UPDATE grr_form   SET NFC_123_CD = 'TGA' WHERE INTL_PACK_FORM_DESC IN ('VAG UD LIQ','VAG LIQ','VAG IUD');
UPDATE grr_form   SET NFC_123_CD = 'MSA' WHERE INTL_PACK_FORM_DESC IN ('TOP OINT','TOP OIL');
UPDATE grr_form   SET NFC_123_CD = 'MGW' WHERE INTL_PACK_FORM_DESC = 'TOP LIQ';
UPDATE grr_form   SET NFC_123_CD = 'FMA' WHERE INTL_PACK_FORM_DESC LIKE '%AMP%';
UPDATE grr_form   SET NFC_123_CD = 'MWA' WHERE INTL_PACK_FORM_DESC LIKE '%PLAST%';
UPDATE grr_form   SET NFC_123_CD = 'FNA' WHERE INTL_PACK_FORM_DESC LIKE '%PF %SG%' OR    INTL_PACK_FORM_DESC LIKE '%PF %PEN%';
UPDATE grr_form   SET NFC_123_CD = 'FPA' WHERE INTL_PACK_FORM_DESC LIKE '%VIAL%';
UPDATE grr_form   SET NFC_123_CD = 'FQE' WHERE INTL_PACK_FORM_DESC LIKE '%INF BAG%';
UPDATE grr_form   SET NFC_123_CD = 'RHP' WHERE INTL_PACK_FORM_DESC LIKE '%LUNG%';
UPDATE grr_form   SET NFC_123_CD = 'MHA' WHERE INTL_PACK_FORM_DESC LIKE '%SPRAY%';
UPDATE grr_form   SET NFC_123_CD = 'MJY' WHERE INTL_PACK_FORM_DESC = 'BAD';
UPDATE grr_form   SET NFC_123_CD = 'MJH' WHERE INTL_PACK_FORM_DESC = 'BAD OEL';
UPDATE grr_form   SET NFC_123_CD = 'MJY' WHERE INTL_PACK_FORM_DESC = 'BATH';
UPDATE grr_form   SET NFC_123_CD = 'MJL' WHERE INTL_PACK_FORM_DESC = 'BATH EMUL';
UPDATE grr_form   SET NFC_123_CD = 'MJT' WHERE INTL_PACK_FORM_DESC = 'BATH FOAM';
UPDATE grr_form   SET NFC_123_CD = 'MJH' WHERE INTL_PACK_FORM_DESC = 'BATH OIL';
UPDATE grr_form   SET NFC_123_CD = 'MJY' WHERE INTL_PACK_FORM_DESC = 'BATH OTH';
UPDATE grr_form   SET NFC_123_CD = 'MJB' WHERE INTL_PACK_FORM_DESC = 'BATH SOLID';
UPDATE grr_form   SET NFC_123_CD = 'ADQ' WHERE INTL_PACK_FORM_DESC = 'BISCUIT';
UPDATE grr_form   SET NFC_123_CD = 'ACF' WHERE INTL_PACK_FORM_DESC = 'BITE CAP';
UPDATE grr_form   SET NFC_123_CD = 'MYP' WHERE INTL_PACK_FORM_DESC = 'BONE CMT W SUB';
UPDATE grr_form   SET NFC_123_CD = 'AAE' WHERE INTL_PACK_FORM_DESC = 'BUC TAB';
UPDATE grr_form   SET NFC_123_CD = 'FRA' WHERE INTL_PACK_FORM_DESC = 'CART';
UPDATE grr_form   SET NFC_123_CD = 'ACG' WHERE INTL_PACK_FORM_DESC = 'CHEW CAP';
UPDATE grr_form   SET NFC_123_CD = 'AAG' WHERE INTL_PACK_FORM_DESC = 'CHEW TAB';
UPDATE grr_form   SET NFC_123_CD = 'ACZ' WHERE INTL_PACK_FORM_DESC = 'COMB CAP';
UPDATE grr_form   SET NFC_123_CD = 'ADZ' WHERE INTL_PACK_FORM_DESC = 'COMB SPC SLD';
UPDATE grr_form   SET NFC_123_CD = 'AAZ' WHERE INTL_PACK_FORM_DESC = 'COMB TAB';
UPDATE grr_form   SET NFC_123_CD = 'FQD' WHERE INTL_PACK_FORM_DESC = 'DRY INF BTL';
UPDATE grr_form   SET NFC_123_CD = 'MEC' WHERE INTL_PACK_FORM_DESC = 'DUST PWD';
UPDATE grr_form   SET NFC_123_CD = 'AAH' WHERE INTL_PACK_FORM_DESC = 'EFF TAB';
UPDATE grr_form   SET NFC_123_CD = 'DGA' WHERE INTL_PACK_FORM_DESC = 'FLUESSIG';
UPDATE grr_form   SET NFC_123_CD = 'MYT' WHERE INTL_PACK_FORM_DESC = 'FOAM';
UPDATE grr_form   SET NFC_123_CD = 'DGR' WHERE INTL_PACK_FORM_DESC = 'FRANZBR.WEIN';
UPDATE grr_form   SET NFC_123_CD = 'MWB' WHERE INTL_PACK_FORM_DESC = 'GAUZE W SUB';
UPDATE grr_form   SET NFC_123_CD = 'MZK' WHERE INTL_PACK_FORM_DESC = 'GEL DRESS';
UPDATE grr_form   SET NFC_123_CD = 'ADR' WHERE INTL_PACK_FORM_DESC = 'GLOBULE';
UPDATE grr_form   SET NFC_123_CD = 'AEB' WHERE INTL_PACK_FORM_DESC = 'GRAN';
UPDATE grr_form   SET NFC_123_CD = 'KDF' WHERE INTL_PACK_FORM_DESC = 'GUM';
UPDATE grr_form   SET NFC_123_CD = 'GYV' WHERE INTL_PACK_FORM_DESC = 'IMPLANT';
UPDATE grr_form   SET NFC_123_CD = 'FQC' WHERE INTL_PACK_FORM_DESC = 'INF BTL';
UPDATE grr_form   SET NFC_123_CD = 'FQF' WHERE INTL_PACK_FORM_DESC = 'INF CART';
UPDATE grr_form   SET NFC_123_CD = 'RCT' WHERE INTL_PACK_FORM_DESC = 'INH CAP';
UPDATE grr_form   SET NFC_123_CD = 'FNH' WHERE INTL_PACK_FORM_DESC = 'INJEKTOR NA';
UPDATE grr_form   SET NFC_123_CD = 'DKJ' WHERE INTL_PACK_FORM_DESC = 'INSTANT TEA';
UPDATE grr_form   SET NFC_123_CD = 'MQS' WHERE INTL_PACK_FORM_DESC = 'IRRIGAT FLUID';
UPDATE grr_form   SET NFC_123_CD = 'ACA' WHERE INTL_PACK_FORM_DESC = 'KAPS';
UPDATE grr_form   SET NFC_123_CD = 'AAJ' WHERE INTL_PACK_FORM_DESC = 'LAYER TAB';
UPDATE grr_form   SET NFC_123_CD = 'MGW' WHERE INTL_PACK_FORM_DESC = 'LIQ SOAP';
UPDATE grr_form   SET NFC_123_CD = 'DGA' WHERE INTL_PACK_FORM_DESC = 'LIQU';
UPDATE grr_form   SET NFC_123_CD = 'DGA' WHERE INTL_PACK_FORM_DESC = 'LOESG N';
UPDATE grr_form   SET NFC_123_CD = 'DGA' WHERE INTL_PACK_FORM_DESC = 'LOESUNG';
UPDATE grr_form   SET NFC_123_CD = 'ADE' WHERE INTL_PACK_FORM_DESC = 'LOZ';
UPDATE grr_form   SET NFC_123_CD = 'TYQ' WHERE INTL_PACK_FORM_DESC = 'MCH PES W SUB';
UPDATE grr_form   SET NFC_123_CD = 'DKA' WHERE INTL_PACK_FORM_DESC = 'MED TEA';
UPDATE grr_form   SET NFC_123_CD = 'QGC' WHERE INTL_PACK_FORM_DESC = 'NH AERO';
UPDATE grr_form   SET NFC_123_CD = 'DGA' WHERE INTL_PACK_FORM_DESC = 'NH LIQ';
UPDATE grr_form   SET NFC_123_CD = 'DEK' WHERE INTL_PACK_FORM_DESC = 'NH SLB PWD';
UPDATE grr_form   SET NFC_123_CD = 'AAH' WHERE INTL_PACK_FORM_DESC = 'NH SLB TAB';
UPDATE grr_form   SET NFC_123_CD = 'DEK' WHERE INTL_PACK_FORM_DESC = 'NH SLD SUB';
UPDATE grr_form   SET NFC_123_CD = 'FPA' WHERE INTL_PACK_FORM_DESC = 'NH TST X STK';
UPDATE grr_form   SET NFC_123_CD = 'MGN' WHERE INTL_PACK_FORM_DESC = 'NH UD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'RHQ' WHERE INTL_PACK_FORM_DESC = 'NON CFC MDI';
UPDATE grr_form   SET NFC_123_CD = 'IGP' WHERE INTL_PACK_FORM_DESC = 'NS MD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'IGN' WHERE INTL_PACK_FORM_DESC = 'NS UD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'QTA' WHERE INTL_PACK_FORM_DESC = 'NT CRM';
UPDATE grr_form   SET NFC_123_CD = 'QGB' WHERE INTL_PACK_FORM_DESC = 'NT DRP';
UPDATE grr_form   SET NFC_123_CD = 'QGP' WHERE INTL_PACK_FORM_DESC = 'NT MD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'QGH' WHERE INTL_PACK_FORM_DESC = 'NT OIL';
UPDATE grr_form   SET NFC_123_CD = 'QYM' WHERE INTL_PACK_FORM_DESC = 'NT STICK';
UPDATE grr_form   SET NFC_123_CD = 'QGN' WHERE INTL_PACK_FORM_DESC = 'NT UD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'NDN' WHERE INTL_PACK_FORM_DESC = 'OCULAR SYS';
UPDATE grr_form   SET NFC_123_CD = 'MGH' WHERE INTL_PACK_FORM_DESC = 'OEL';
UPDATE grr_form   SET NFC_123_CD = 'PGB' WHERE INTL_PACK_FORM_DESC = 'OHRENTROPFEN';
UPDATE grr_form   SET NFC_123_CD = 'NGZ' WHERE INTL_PACK_FORM_DESC = 'OPH COMB LIQ';
UPDATE grr_form   SET NFC_123_CD = 'NTA' WHERE INTL_PACK_FORM_DESC = 'OPH CRM';
UPDATE grr_form   SET NFC_123_CD = 'NGB' WHERE INTL_PACK_FORM_DESC = 'OPH DRP';
UPDATE grr_form   SET NFC_123_CD = 'NVB' WHERE INTL_PACK_FORM_DESC = 'OPH GEL DRP';
UPDATE grr_form   SET NFC_123_CD = 'NSA' WHERE INTL_PACK_FORM_DESC = 'OPH OINT';
UPDATE grr_form   SET NFC_123_CD = 'MZY' WHERE INTL_PACK_FORM_DESC = 'OPH OTH M.AID';
UPDATE grr_form   SET NFC_123_CD = 'NGQ' WHERE INTL_PACK_FORM_DESC = 'OPH PRSV-F MU-D LIQ';
UPDATE grr_form   SET NFC_123_CD = 'NGA' WHERE INTL_PACK_FORM_DESC = 'OPH SOL';
UPDATE grr_form   SET NFC_123_CD = 'NGK' WHERE INTL_PACK_FORM_DESC = 'OPH SUSP';
UPDATE grr_form   SET NFC_123_CD = 'NGN' WHERE INTL_PACK_FORM_DESC = 'OPH UD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'AAB' WHERE INTL_PACK_FORM_DESC = ' ORAL SLD ODT';
UPDATE grr_form   SET NFC_123_CD = 'DGZ' WHERE INTL_PACK_FORM_DESC = ' ORL COMB LIQ';
UPDATE grr_form   SET NFC_123_CD = 'DGJ' WHERE INTL_PACK_FORM_DESC = ' ORL DRY SUSP';
UPDATE grr_form   SET NFC_123_CD = 'DGJ' WHERE INTL_PACK_FORM_DESC = ' ORL DRY SYR';
UPDATE grr_form   SET NFC_123_CD = 'DGL' WHERE INTL_PACK_FORM_DESC = ' ORL EMUL';
UPDATE grr_form   SET NFC_123_CD = 'AEB' WHERE INTL_PACK_FORM_DESC = ' ORL GRAN';
UPDATE grr_form   SET NFC_123_CD = 'KSA' WHERE INTL_PACK_FORM_DESC = ' ORL OIL';
UPDATE grr_form   SET NFC_123_CD = 'DDY' WHERE INTL_PACK_FORM_DESC = ' ORL SPC FORM';
UPDATE grr_form   SET NFC_123_CD = 'AEB' WHERE INTL_PACK_FORM_DESC = ' ORL UD GRAN';
UPDATE grr_form   SET NFC_123_CD = 'JGB' WHERE INTL_PACK_FORM_DESC = 'OS DRP';
UPDATE grr_form   SET NFC_123_CD = 'JVA' WHERE INTL_PACK_FORM_DESC = 'OS GEL';
UPDATE grr_form   SET NFC_123_CD = 'JFA' WHERE INTL_PACK_FORM_DESC = 'OS INH GAS';
UPDATE grr_form   SET NFC_123_CD = 'JGE' WHERE INTL_PACK_FORM_DESC = 'OS INH LIQ';
UPDATE grr_form   SET NFC_123_CD = 'JSA' WHERE INTL_PACK_FORM_DESC = 'OS OINT';
UPDATE grr_form   SET NFC_123_CD = 'JEY' WHERE INTL_PACK_FORM_DESC = 'OS OTH PWD';
UPDATE grr_form   SET NFC_123_CD = 'JWN' WHERE INTL_PACK_FORM_DESC = 'OS TD SYS';
UPDATE grr_form   SET NFC_123_CD = 'JCV' WHERE INTL_PACK_FORM_DESC = 'OS TOP CAP';
UPDATE grr_form   SET NFC_123_CD = 'JVN' WHERE INTL_PACK_FORM_DESC = 'OS UD GEL';
UPDATE grr_form   SET NFC_123_CD = 'KAE' WHERE INTL_PACK_FORM_DESC = 'OT BUC TAB';
UPDATE grr_form   SET NFC_123_CD = 'KGD' WHERE INTL_PACK_FORM_DESC = 'OT COLLODION';
UPDATE grr_form   SET NFC_123_CD = 'KGB' WHERE INTL_PACK_FORM_DESC = 'OT DRP';
UPDATE grr_form   SET NFC_123_CD = 'KVA' WHERE INTL_PACK_FORM_DESC = 'OT GEL';
UPDATE grr_form   SET NFC_123_CD = 'KGD' WHERE INTL_PACK_FORM_DESC = 'OT LACQUER';
UPDATE grr_form   SET NFC_123_CD = 'KGA' WHERE INTL_PACK_FORM_DESC = 'OT LIQ';
UPDATE grr_form   SET NFC_123_CD = 'KDE' WHERE INTL_PACK_FORM_DESC = 'OT LOZ';
UPDATE grr_form   SET NFC_123_CD = 'KSA' WHERE INTL_PACK_FORM_DESC = 'OT OINT';
UPDATE grr_form   SET NFC_123_CD = 'KHA' WHERE INTL_PACK_FORM_DESC = 'OT P.AERO';
UPDATE grr_form   SET NFC_123_CD = 'KSB' WHERE INTL_PACK_FORM_DESC = 'OT PASTE';
UPDATE grr_form   SET NFC_123_CD = 'KEK' WHERE INTL_PACK_FORM_DESC = 'OT SLB PWD';
UPDATE grr_form   SET NFC_123_CD = 'ACA' WHERE INTL_PACK_FORM_DESC = 'OT SPC FORM';
UPDATE grr_form   SET NFC_123_CD = 'KYK' WHERE INTL_PACK_FORM_DESC = 'OT STYLI';
UPDATE grr_form   SET NFC_123_CD = 'KDG' WHERE INTL_PACK_FORM_DESC = 'OT SWEET';
UPDATE grr_form   SET NFC_123_CD = 'KVN' WHERE INTL_PACK_FORM_DESC = 'OT UD GEL';
UPDATE grr_form   SET NFC_123_CD = 'KGN' WHERE INTL_PACK_FORM_DESC = 'OT UD LIQ';
UPDATE grr_form   SET NFC_123_CD = 'ACA' WHERE INTL_PACK_FORM_DESC = 'OTH CAP';
UPDATE grr_form   SET NFC_123_CD = 'PGB' WHERE INTL_PACK_FORM_DESC = 'OTIC DRP';
UPDATE grr_form   SET NFC_123_CD = 'PSA' WHERE INTL_PACK_FORM_DESC = 'OTIC OINT';
UPDATE grr_form   SET NFC_123_CD = 'MWD' WHERE INTL_PACK_FORM_DESC = 'PAD W SUB';
UPDATE grr_form   SET NFC_123_CD = 'FNH' WHERE INTL_PACK_FORM_DESC = 'PARENT ORD PF AUTINJ';
UPDATE grr_form   SET NFC_123_CD = 'ADD' WHERE INTL_PACK_FORM_DESC = 'PELLET';
UPDATE grr_form   SET NFC_123_CD = 'AAA' WHERE INTL_PACK_FORM_DESC = 'PILLEN N';
UPDATE grr_form   SET NFC_123_CD = 'MWS' WHERE INTL_PACK_FORM_DESC = 'POULTICE';
UPDATE grr_form   SET NFC_123_CD = 'AEA' WHERE INTL_PACK_FORM_DESC = 'PULVER';
UPDATE grr_form   SET NFC_123_CD = 'MEA' WHERE INTL_PACK_FORM_DESC = 'PULVER T';
UPDATE grr_form   SET NFC_123_CD = 'HCA' WHERE INTL_PACK_FORM_DESC = 'RS CAP';
UPDATE grr_form   SET NFC_123_CD = 'HGX' WHERE INTL_PACK_FORM_DESC = 'RS ENEMA LIQ';
UPDATE grr_form   SET NFC_123_CD = 'HHP' WHERE INTL_PACK_FORM_DESC = 'RS MD AERO';
UPDATE grr_form   SET NFC_123_CD = 'HLX' WHERE INTL_PACK_FORM_DESC = 'RS MICRO ENEMA';
UPDATE grr_form   SET NFC_123_CD = 'HLA' WHERE INTL_PACK_FORM_DESC = 'RS SUP';
UPDATE grr_form   SET NFC_123_CD = 'HLA' WHERE INTL_PACK_FORM_DESC = 'RS SUP ADLT';
UPDATE grr_form   SET NFC_123_CD = 'HLA' WHERE INTL_PACK_FORM_DESC = 'RS SUP PAED';
UPDATE grr_form   SET NFC_123_CD = 'FRA' WHERE INTL_PACK_FORM_DESC = 'RT CART';
UPDATE grr_form   SET NFC_123_CD = 'ACD' WHERE INTL_PACK_FORM_DESC = 'RT UD PWD';
UPDATE grr_form   SET NFC_123_CD = 'MSA' WHERE INTL_PACK_FORM_DESC = 'SALBE WEISS';
UPDATE grr_form   SET NFC_123_CD = 'MYT' WHERE INTL_PACK_FORM_DESC = 'SCHAUM';
UPDATE grr_form   SET NFC_123_CD = 'MGT' WHERE INTL_PACK_FORM_DESC = 'SHAKING MIX';
UPDATE grr_form   SET NFC_123_CD = 'AAK' WHERE INTL_PACK_FORM_DESC = 'SLB TAB';
UPDATE grr_form   SET NFC_123_CD = 'DGF' WHERE INTL_PACK_FORM_DESC = 'SUBL LIQ';
UPDATE grr_form   SET NFC_123_CD = 'AAF' WHERE INTL_PACK_FORM_DESC = 'SUBL TAB';
UPDATE grr_form   SET NFC_123_CD = 'MSA' WHERE INTL_PACK_FORM_DESC = 'SUBSTANZ';
UPDATE grr_form   SET NFC_123_CD = 'DGK' WHERE INTL_PACK_FORM_DESC = 'SUSP';
UPDATE grr_form   SET NFC_123_CD = 'DGK' WHERE INTL_PACK_FORM_DESC = 'SUSP PALMIT.';
UPDATE grr_form   SET NFC_123_CD = 'ADG' WHERE INTL_PACK_FORM_DESC = 'SWEET';
UPDATE grr_form   SET NFC_123_CD = 'AAA' WHERE INTL_PACK_FORM_DESC = 'TAB';
UPDATE grr_form   SET NFC_123_CD = 'AAA' WHERE INTL_PACK_FORM_DESC = 'TABL';
UPDATE grr_form   SET NFC_123_CD = 'AAA' WHERE INTL_PACK_FORM_DESC = 'TABL VIT+MIN';
UPDATE grr_form   SET NFC_123_CD = 'JWN' WHERE INTL_PACK_FORM_DESC = 'TD PATCH';
UPDATE grr_form   SET NFC_123_CD = 'DKP' WHERE INTL_PACK_FORM_DESC = 'TEA BAG';
UPDATE grr_form   SET NFC_123_CD = 'DGK' WHERE INTL_PACK_FORM_DESC = 'TINKT';
UPDATE grr_form   SET NFC_123_CD = 'HLA' WHERE INTL_PACK_FORM_DESC = 'TMP W SUB';
UPDATE grr_form   SET NFC_123_CD = 'DGA' WHERE INTL_PACK_FORM_DESC = 'TONIKUM';
UPDATE grr_form   SET NFC_123_CD = 'MSZ' WHERE INTL_PACK_FORM_DESC = 'TOP COMB OINT';
UPDATE grr_form   SET NFC_123_CD = 'MHZ' WHERE INTL_PACK_FORM_DESC = 'TOP COMB P.AERO';
UPDATE grr_form   SET NFC_123_CD = 'MTA' WHERE INTL_PACK_FORM_DESC = 'TOP CRM';
UPDATE grr_form   SET NFC_123_CD = 'MGB' WHERE INTL_PACK_FORM_DESC = 'TOP DRP';
UPDATE grr_form   SET NFC_123_CD = 'MGJ' WHERE INTL_PACK_FORM_DESC = 'TOP DRY SUSP';
UPDATE grr_form   SET NFC_123_CD = 'MGL' WHERE INTL_PACK_FORM_DESC = 'TOP EMUL';
UPDATE grr_form   SET NFC_123_CD = 'MVL' WHERE INTL_PACK_FORM_DESC = 'TOP EMUL GEL';
UPDATE grr_form   SET NFC_123_CD = 'MVA' WHERE INTL_PACK_FORM_DESC = 'TOP GEL';
UPDATE grr_form   SET NFC_123_CD = 'MGS' WHERE INTL_PACK_FORM_DESC = 'TOP LOT';
UPDATE grr_form   SET NFC_123_CD = 'MHP' WHERE INTL_PACK_FORM_DESC = 'TOP MD AERO';
UPDATE grr_form   SET NFC_123_CD = 'MLX' WHERE INTL_PACK_FORM_DESC = 'TOP MICRO ENEMA';
UPDATE grr_form   SET NFC_123_CD = 'MTY' WHERE INTL_PACK_FORM_DESC = 'TOP OTH CRM';
UPDATE grr_form   SET NFC_123_CD = 'MVY' WHERE INTL_PACK_FORM_DESC = 'TOP OTH GEL';
UPDATE grr_form   SET NFC_123_CD = 'MHA' WHERE INTL_PACK_FORM_DESC = 'TOP P.AERO';
UPDATE grr_form   SET NFC_123_CD = 'MHT' WHERE INTL_PACK_FORM_DESC = 'TOP P.FOAM';
UPDATE grr_form   SET NFC_123_CD = 'MHS' WHERE INTL_PACK_FORM_DESC = 'TOP P.OINT';
UPDATE grr_form   SET NFC_123_CD = 'MHC' WHERE INTL_PACK_FORM_DESC = 'TOP P.PWD';
UPDATE grr_form   SET NFC_123_CD = 'MSB' WHERE INTL_PACK_FORM_DESC = 'TOP PASTE';
UPDATE grr_form   SET NFC_123_CD = 'MEA' WHERE INTL_PACK_FORM_DESC = 'TOP PWD';
UPDATE grr_form   SET NFC_123_CD = 'MEK' WHERE INTL_PACK_FORM_DESC = 'TOP SLB PWD';
UPDATE grr_form   SET NFC_123_CD = 'MYK' WHERE INTL_PACK_FORM_DESC = 'TOP STK';
UPDATE grr_form   SET NFC_123_CD = 'MYK' WHERE INTL_PACK_FORM_DESC = 'TOP STYLI';
UPDATE grr_form   SET NFC_123_CD = 'MLA' WHERE INTL_PACK_FORM_DESC = 'TOP SUP ADULT';
UPDATE grr_form   SET NFC_123_CD = 'MGK' WHERE INTL_PACK_FORM_DESC = 'TOP SUSP';
UPDATE grr_form   SET NFC_123_CD = 'DGB' WHERE INTL_PACK_FORM_DESC = 'TROPF';
UPDATE grr_form   SET NFC_123_CD = 'JRP' WHERE INTL_PACK_FORM_DESC = 'UD CART';
UPDATE grr_form   SET NFC_123_CD = 'AEB' WHERE INTL_PACK_FORM_DESC = 'UD GRAN';
UPDATE grr_form   SET NFC_123_CD = 'DEP' WHERE INTL_PACK_FORM_DESC = 'UD PWD';
UPDATE grr_form   SET NFC_123_CD = 'TCA' WHERE INTL_PACK_FORM_DESC = 'VAG CAP';
UPDATE grr_form   SET NFC_123_CD = 'TTZ' WHERE INTL_PACK_FORM_DESC = 'VAG COMB CRM';
UPDATE grr_form   SET NFC_123_CD = 'TLZ' WHERE INTL_PACK_FORM_DESC = 'VAG COMB SUP';
UPDATE grr_form   SET NFC_123_CD = 'TTA' WHERE INTL_PACK_FORM_DESC = 'VAG CRM';
UPDATE grr_form   SET NFC_123_CD = 'TVA' WHERE INTL_PACK_FORM_DESC = 'VAG FOAM';
UPDATE grr_form   SET NFC_123_CD = 'TVA' WHERE INTL_PACK_FORM_DESC = 'VAG GEL';
UPDATE grr_form   SET NFC_123_CD = 'TVA' WHERE INTL_PACK_FORM_DESC = 'VAG P.FOAM';
UPDATE grr_form   SET NFC_123_CD = 'TLS' WHERE INTL_PACK_FORM_DESC = 'VAG SUP';
UPDATE grr_form   SET NFC_123_CD = 'TWE' WHERE INTL_PACK_FORM_DESC = 'VAG TMP W SUB';
UPDATE grr_form   SET NFC_123_CD = 'TTN' WHERE INTL_PACK_FORM_DESC = 'VAG UD CRM';
UPDATE grr_form   SET NFC_123_CD = 'TVN' WHERE INTL_PACK_FORM_DESC = 'VAG UD GEL';
UPDATE grr_form   SET NFC_123_CD = 'MTA' WHERE INTL_PACK_FORM_DESC = 'VASELINE';

--introducing manual matching
update grr_form g
set g.NFC_123_CD = (select m.concept_code  from manual_form_add m where m.dose_form = INTL_PACK_FORM_DESC)
where  g.NFC_123_CD is null ;

CREATE TABLE grr_form_2 
AS
SELECT DISTINCT fcc, concept_code,concept_name,INTL_PACK_FORM_DESC
FROM grr_form a
JOIN concept b ON NFC_123_CD = concept_code
WHERE vocabulary_id = 'NFC';


--delete grr_form_2 where concept_code like 'V%' or concept_code in ('ZZZ','MQS','JGH') and fcc in (select fcc from grr_new_3);

DELETE grr_form_2
WHERE ROWID NOT IN (SELECT MIN(ROWID) FROM grr_form_2 GROUP BY fcc);

CREATE TABLE grr_ing 
AS
(
--just created this
SELECT ingredient, fcc
FROM (SELECT DISTINCT TRIM(REGEXP_SUBSTR(t.substance,'[^\+]+',1,levels.column_value)) AS ingredient,fcc
      FROM source_data_1 t,
           TABLE (CAST(multiset (SELECT LEVEL
                                 FROM dual
                                 CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(t.substance,'[^\+]+')) + 1)
                                 AS
                                 sys.OdciNumberList)) levels)
WHERE ingredient NOT IN ('MULTI SUBSTANZ','ENZYME (UNSPECIFIED)','NASAL DECONGESTANTS','ANTACIDS','ELECTROLYTE SOLUTIONS','ANTI-PSORIASIS','TOPICAL ANALGESICS'));

INSERT INTO grr_ing (fcc, ingredient)
SELECT fcc,molecule
FROM grr_new_3;

--introduced parsed ingredients
CREATE TABLE grr_ing_2_0 
AS
(SELECT fcc,
       CASE
         WHEN ingredient = ingr THEN ingr_2
         ELSE ingredient  END AS ingredient
FROM grr_ing a
  LEFT JOIN ingr_parsing ON ingredient = ingr);

--delete vague ingredients
delete grr_ing_2_0 
where initcap(ingredient) in ('Articulation','Arachnoidae','Minerals','Mumio','Oligo Elements','Aminoacids','Lipids','Medicinal Mud','Polypeptides','Clay','Alkylarylsulfonates','Chalcedony','Endolysin','Fish','Glucids','Hydrocolloid','Metroxylon','Paraformaldehyde-Sucrose Complex','Polypeptides','Saponine','Tenside');

CREATE TABLE grr_ing_2 AS
SELECT DISTINCT *
FROM grr_ing_2_0;

CREATE SEQUENCE new_vocab MINVALUE 3000000 MAXVALUE 90000000
START WITH 3000000 INCREMENT BY 1 CACHE 100;

--put OMOP||numbers
--creating table with all concepts that need to have OMOP
CREATE TABLE list 
AS
SELECT DISTINCT bn AS concept_name,'Brand Name' AS concept_class_id FROM grr_bn_2
UNION
SELECT DISTINCT PRI_ORG_LNG_NM,'Supplier' FROM grr_manuf
UNION
SELECT DISTINCT ingredient,'Ingredient' FROM grr_ing_2 WHERE ingredient IS NOT NULL
UNION
SELECT DISTINCT drug_name,'Drug Product' FROM grr_pack_2;

ALTER TABLE list ADD concept_Code VARCHAR (255);

UPDATE list
   SET concept_code = 'OMOP' ||new_vocab.nextval;

CREATE TABLE dcs_drugs 
AS
SELECT INITCAP(brand_name|| ' ' ||form_desc) AS concept_name,fcc
FROM grr_new_3
UNION
SELECT INITCAP(therapy_name),
       fcc
FROM source_data_1;

DELETE dcs_drugs
WHERE ROWID NOT IN 
(SELECT MIN(ROWID) FROM dcs_drugs GROUP BY fcc);

CREATE TABLE dcs_unit 
AS
(SELECT DISTINCT REPLACE(WGT_UOM_CD,'.') AS concept_code, 'Unit' AS concept_class_id, REPLACE(WGT_UOM_CD,'.') AS concept_name
FROM (
	SELECT WGT_UOM_CD FROM grr_new_3
UNION
      SELECT PACK_VOL_UOM_CD FROM grr_new_3
UNION
      SELECT STRENGTH_UNIT FROM source_data_1
UNION
      SELECT VOLUME_UNIT FROM source_data_1
UNION
      SELECT 'ACTUAT' FROM dual
UNION
      SELECT 'HOUR' FROM dual)
WHERE WGT_UOM_CD IS NOT NULL
AND   WGT_UOM_CD NOT IN ('--','Y/H'));


TRUNCATE TABLE DRUG_CONCEPT_STAGE; 
insert into DRUG_CONCEPT_STAGE 
(CONCEPT_NAME,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,POSSIBLE_EXCIPIENT,domain_id,VALID_START_DATE,VALID_END_DATE,INVALID_REASON, SOURCE_CONCEPT_CLASS_ID)
select distinct concept_name, 'GRR', concept_class_id, '', concept_code, '',domain_id, TO_DATE('2017/07/18', 'yyyy/mm/dd') as valid_start_date,
TO_DATE('2099/12/31', 'yyyy/mm/dd') as valid_end_date, '',''
 from 
(
select concept_name, concept_class_id, concept_code, 'Drug' as domain_id from dcs_unit
union
select initcap(concept_name), concept_class_id, concept_code, 'Drug' from list
union
select concept_name, 'Drug Product', fcc, 'Drug' from dcs_drugs--drugs with pack drugs
union
select brand_name, 'Device', fcc, 'Device' from grr_non_drug 
where rowid in ( select min(rowid) from grr_non_drug group by fcc)
union
select concept_name,'Dose Form',concept_code, 'Drug' from grr_form_2
);

UPDATE drug_concept_stage
   SET standard_concept = 'S'
WHERE concept_class_id in ('Ingredient','Device');

--assigning concepts codes from previous releases
merge into drug_concept_stage dcs
using (select * from concept where vocabulary_id = 'GRR' and invalid_reason is null) n
on (dcs.concept_name = n.concept_name and dcs.concept_class_id = n.concept_class_id and dcs.concept_class_id in ('Brand Name','Ingredient','Supplier'))
when matched then update 
set dcs.concept_code = n.concept_code
;

--rename attributes, need to perform after code assignment
update drug_concept_stage
set concept_name = 'Pharma Labor'
where concept_name = 'Pharma Labor Arnsb';

CREATE TABLE grr_new_3_for_ds  AS
SELECT DISTINCT FCC, INTL_PACK_FORM_DESC, INTL_PACK_STRNT_DESC, INTL_PACK_SIZE_DESC, PACK_DESC, PACK_SUBSTN_CNT,
       MOLECULE,
       CASE
         WHEN WGT_UOM_CD = 'NG' THEN WGT_QTY / 1000000
         WHEN WGT_UOM_CD = 'MCG' THEN WGT_QTY / 1000
         WHEN WGT_UOM_CD = 'G' THEN WGT_QTY*1000
         ELSE CAST(WGT_QTY AS NUMBER)
       END AS WGT_QTY,
       CASE
         WHEN WGT_UOM_CD IN ('NG','MCG','G') THEN 'MG'
         ELSE WGT_UOM_CD
       END AS WGT_UOM_CD,
       PACK_ADDL_STRNT_DESC,
       CASE
         WHEN PACK_WGT_UOM_CD = 'G' THEN CAST(PACK_WGT_QTY AS NUMBER)*1000
         ELSE CAST(PACK_WGT_QTY AS NUMBER)
       END AS PACK_WGT_QTY,
       CASE
         WHEN PACK_WGT_UOM_CD = 'G' THEN 'MG'
         ELSE PACK_WGT_UOM_CD
       END AS PACK_WGT_UOM_CD,
       CASE
         WHEN PACK_VOL_UOM_CD = 'G' THEN CAST(PACK_VOL_QTY AS NUMBER)*1000
         ELSE CAST(PACK_VOL_QTY AS NUMBER)
       END AS PACK_VOL_QTY,
       CASE
         WHEN PACK_VOL_UOM_CD = 'G' THEN 'MG'
         ELSE PACK_VOL_UOM_CD
       END AS PACK_VOL_UOM_CD,
       PACK_SIZE_CNT,
       CAST(ABS_STRNT_QTY AS NUMBER) AS ABS_STRNT_QTY,
       ABS_STRNT_UOM_CD,
       RLTV_STRNT_QTY
FROM grr_new_3
WHERE FCC NOT IN (SELECT FCC FROM grr_new_3 WHERE WGT_QTY LIKE '-%');

-- exclude dosages<0
--inteferon 1.5/0.5 ml
DELETE grr_new_3_for_ds
WHERE MOLECULE IN ('INTERFERON BETA-1A','ETANERCEPT','COLECALCIFEROL','DALTEPARIN SODIUM','DROPERIDOL','ENOXAPARIN SODIUM','EPOETIN ALFA','FOLLITROPIN ALFA','FULVESTRANT','SALBUTAMOL','TRAMADOL')
AND   WGT_QTY / PACK_VOL_QTY != ABS_STRNT_QTY
AND   FCC IN (SELECT a.fcc
              FROM grr_new_3_for_ds a
                JOIN grr_new_3_for_ds b
                  ON a.fcc = b.fcc
                 AND (a.PACK_VOL_QTY != b.PACK_VOL_QTY
                  OR a.PACK_VOL_UOM_CD != b.PACK_VOL_UOM_CD));

--delete 3-leg dogs          
DELETE grr_new_3_for_ds
WHERE fcc IN (
	SELECT fcc
              FROM grr_new_3_for_ds
              WHERE WGT_QTY = 0
UNION
        SELECT fcc
              FROM grr_new_3_for_ds
              WHERE WGT_QTY IS NULL);

--octreotide
UPDATE grr_new_3_for_ds
   SET wgt_qty = CASE
                   WHEN wgt_qty = '44.1' THEN 30
                   WHEN wgt_qty = '11.76' THEN 10
                   WHEN wgt_qty IN ('29.4','23.52') THEN 20
                   ELSE wgt_qty END ,
       pack_vol_qty = CASE
                        WHEN pack_vol_qty IN ('2','2.5') THEN 2
                        ELSE pack_vol_qty END 
WHERE molecule = 'OCTREOTIDE';

UPDATE GRR_NEW_3_FOR_DS
   SET WGT_QTY = 500, PACK_WGT_QTY = NULL, PACK_WGT_UOM_CD = ''
WHERE FCC = '875055_06152015';

--DEXRAZOXANE INJECTION
UPDATE GRR_NEW_3_FOR_DS
   SET WGT_QTY = 30
WHERE FCC = '904091_04152016' AND   MOLECULE = 'BETAMETHASONE' AND   WGT_QTY = 38.568 AND   PACK_VOL_QTY IS NULL;

UPDATE GRR_NEW_3_FOR_DS
   SET PACK_WGT_QTY = NULL,
       PACK_WGT_UOM_CD = NULL
WHERE FCC IN ('769391_10012008','769392_10012008','769393_09012009','769394_09012009','769395_09012009');

--CITRAFLEET, PULVER
DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '904091_04152016' AND   MOLECULE = 'BETAMETHASONE' AND   WGT_QTY = 38.568 AND   PACK_VOL_QTY IS NULL;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '728203_03152011' AND   MOLECULE = 'CALCIUM' AND   WGT_QTY = 4.4 AND   PACK_VOL_QTY = 5000;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '728203_03152011' AND   MOLECULE = '2-OXOGLUTARIC ACID' AND   WGT_QTY = 368 AND   PACK_VOL_QTY = 5000;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '742103_08012011'
AND   PACK_VOL_QTY = 0.4;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '908278_05152016' AND   PACK_VOL_QTY = 2.399;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '518889_04012005' AND   PACK_VOL_QTY = 0.3;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '671753_08152009' AND   PACK_VOL_QTY = 16.7;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC LIKE '80771%_05152013' AND   PACK_VOL_QTY = 5;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC LIKE '65821%_04012009' AND   PACK_VOL_QTY IN (5,0.5);

--vaccine hepatitis b
DELETE
FROM GRR_NEW_3_FOR_DS 
WHERE FCC = '879735_08152015' AND   PACK_VOL_QTY = 15;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '728203_03152011' AND   PACK_VOL_QTY = 5000;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '860022_12152014' AND   PACK_WGT_QTY = 250000;

DELETE
FROM GRR_NEW_3_FOR_DS
WHERE FCC = '904091_04152016' AND   PACK_WGT_QTY = 120000;

--deleting drugs with cm
DELETE grr_new_3_for_ds
WHERE 'CM' IN (WGT_UOM_CD,PACK_VOL_UOM_CD,PACK_WGT_UOM_CD);

--delete duplicate ingredients one of which =0
DELETE grr_new_3_for_ds
WHERE fcc IN (SELECT a.fcc
              FROM grr_new_3_for_ds a
                JOIN grr_new_3_for_ds b
                  ON a.fcc = b.fcc AND a.MOLECULE = b.MOLECULE AND a.WGT_QTY = 0 AND b.WGT_QTY != 0)
AND   WGT_QTY = 0;

--create table to use right dosages from ABS_STRNT_QTY
CREATE TABLE grr_ds_abstr_qnt  AS
SELECT *
FROM grr_new_3_for_ds
WHERE fcc IN (SELECT a.fcc
              FROM grr_new_3_for_ds a
                JOIN grr_new_3_for_ds b ON a.fcc = b.fcc  AND a.molecule = b.molecule
              WHERE a.WGT_QTY != b.WGT_QTY AND   a.ABS_STRNT_QTY = b.ABS_STRNT_QTY AND   a.ABS_STRNT_UOM_CD NOT IN ('G','%'));

INSERT INTO grr_ds_abstr_qnt
SELECT *
FROM grr_new_3_for_ds
WHERE fcc IN (SELECT fcc
              FROM grr_new_3_for_ds
              WHERE WGT_QTY != ABS_STRNT_QTY  AND   REGEXP_SUBSTR(INTL_PACK_STRNT_DESC,'\d+') = ABS_STRNT_QTY AND   NOT REGEXP_LIKE (INTL_PACK_STRNT_DESC,'%|/|\+') AND   NOT REGEXP_LIKE (INTL_PACK_STRNT_DESC,'%') AND   ABS_STRNT_UOM_CD NOT IN ('M','K'));

UPDATE grr_ds_abstr_qnt
   SET WGT_QTY = ABS_STRNT_QTY,
       WGT_UOM_CD = CASE
                      WHEN ABS_STRNT_UOM_CD = 'Y' THEN 'MCG'
                      ELSE ABS_STRNT_UOM_CD END 
WHERE PACK_WGT_QTY IS NULL AND   PACK_VOL_QTY IS NULL;

DELETE grr_ds_abstr_qnt
WHERE fcc IN ('772057_01011988','243285');

--100%
CREATE TABLE grr_ds_abstr_qnt_2 
AS
SELECT *
FROM grr_ds_abstr_qnt
WHERE fcc IN (SELECT a.fcc
              FROM grr_ds_abstr_qnt a
                JOIN grr_ds_abstr_qnt b ON a.fcc = b.fcc  AND a.molecule = b.molecule
              WHERE a.WGT_QTY != b.WGT_QTY);

UPDATE grr_ds_abstr_qnt_2
--remove %
   SET WGT_QTY = ABS_STRNT_QTY*10 *PACK_WGT_QTY
WHERE ABS_STRNT_UOM_CD = '%' AND   PACK_WGT_QTY IS NOT NULL;

UPDATE grr_ds_abstr_qnt_2
   SET WGT_QTY = ABS_STRNT_QTY*10 *PACK_VOL_QTY
WHERE ABS_STRNT_UOM_CD = '%' AND   PACK_VOL_QTY IS NOT NULL;

UPDATE grr_ds_abstr_qnt_2
   SET WGT_QTY = ABS_STRNT_QTY / RLTV_STRNT_QTY*PACK_VOL_QTY
WHERE RLTV_STRNT_QTY IS NOT NULL;

UPDATE grr_ds_abstr_qnt_2
   SET WGT_QTY = ABS_STRNT_QTY,
       WGT_UOM_CD = CASE
                      WHEN ABS_STRNT_UOM_CD = 'Y' THEN 'MCG'
                      ELSE ABS_STRNT_UOM_CD END 
WHERE ABS_STRNT_UOM_CD != '%'
AND   fcc IN (SELECT DISTINCT a.fcc
              FROM grr_ds_abstr_qnt_2 a
                JOIN grr_ds_abstr_qnt_2 b
                  ON a.fcc = b.fcc  AND a.molecule = b.molecule
              WHERE a.WGT_QTY != b.WGT_QTY);

DELETE grr_ds_abstr_qnt
WHERE fcc IN (SELECT fcc FROM grr_ds_abstr_qnt_2);

INSERT INTO grr_ds_abstr_qnt
SELECT *
FROM grr_ds_abstr_qnt_2;

CREATE TABLE grr_ds_abstr_qnt_3  AS
SELECT DISTINCT FCC,INTL_PACK_FORM_DESC,INTL_PACK_STRNT_DESC,INTL_PACK_SIZE_DESC AS BOX_SIZE,PACK_DESC,PACK_SUBSTN_CNT AS INGREDIENTS_CNT,MOLECULE,PACK_ADDL_STRNT_DESC, WGT_QTY AS AMOUNT_VALUE, WGT_UOM_CD AS AMOUNT_UNIT,NVL(PACK_WGT_QTY,PACK_VOL_QTY) AS DENOMINATOR_VALUE, NVL(PACK_WGT_UOM_CD,PACK_VOL_UOM_CD) AS DENOMINATOR_UNIT,PACK_SIZE_CNT
FROM grr_ds_abstr_qnt;

CREATE TABLE grr_ds_abstr_rel  AS
SELECT FCC,INTL_PACK_FORM_DESC,INTL_PACK_STRNT_DESC,
case when INTL_PACK_SIZE_DESC = '24' then null else INTL_PACK_SIZE_DESC end AS BOX_SIZE, -- 24 seems to be 24 hours
PACK_DESC,PACK_SUBSTN_CNT AS ingredients_cnt, MOLECULE,PACK_ADDL_STRNT_DESC,ABS_STRNT_QTY AS AMOUNT_VALUE,
       CASE
         WHEN ABS_STRNT_UOM_CD = 'Y' THEN 'MCG'
         ELSE ABS_STRNT_UOM_CD END AS AMOUNT_UNIT,
       CAST(RLTV_STRNT_QTY AS NUMBER) AS DENOMINATOR_VALUE,
       'HOUR' AS DENOMINATOR_UNIT,
       PACK_SIZE_CNT
FROM grr_new_3_for_ds
WHERE RLTV_STRNT_QTY IS NOT NULL AND   INTL_PACK_STRNT_DESC LIKE '%HR%';

CREATE TABLE grr_new_3_1 
AS
SELECT DISTINCT FCC,INTL_PACK_FORM_DESC,INTL_PACK_STRNT_DESC,INTL_PACK_SIZE_DESC AS BOX_SIZE,PACK_DESC,PACK_SUBSTN_CNT AS INGREDIENTS_CNT,MOLECULE,PACK_ADDL_STRNT_DESC, WGT_QTY AS AMOUNT_VALUE, WGT_UOM_CD AS AMOUNT_UNIT,NVL(PACK_WGT_QTY,PACK_VOL_QTY) AS DENOMINATOR_VALUE, NVL(PACK_WGT_UOM_CD,PACK_VOL_UOM_CD) AS DENOMINATOR_UNIT,PACK_SIZE_CNT
FROM grr_new_3_for_ds;

DELETE grr_new_3_1
WHERE fcc IN (
	SELECT fcc FROM grr_ds_abstr_qnt_3
UNION
        SELECT fcc FROM grr_ds_abstr_rel);

INSERT INTO grr_new_3_1
SELECT * FROM grr_ds_abstr_qnt_3
UNION
SELECT * FROM grr_ds_abstr_rel;

--add more dosage from source data
CREATE TABLE grr_new_3_2 
AS
SELECT DISTINCT a.fcc,a.BOX_SIZE,a.MOLECULE,a.DENOMINATOR_VALUE,a.DENOMINATOR_unit,a.AMOUNT_VALUE,a.AMOUNT_UNIT, a.INGREDIENTS_CNT
FROM grr_new_3_1 a
  JOIN grr_new_3_1 b ON a.fcc = b.fcc
  JOIN source_data_1 c ON a.fcc = c.fcc
WHERE a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE AND   a.DENOMINATOR_VALUE = CAST(VOLUME AS NUMBER);

CREATE TABLE grr_new_3_3 AS
SELECT DISTINCT a.fcc, BOX_SIZE, MOLECULE,
       CASE
         WHEN VOLUME = '0.0' THEN NULL
         ELSE CAST(VOLUME AS NUMBER) END AS DENOMINATOR_VALUE,
       VOLUME_UNIT AS DENOMINATOR_UNIT,
       CAST(STRENGTH AS NUMBER) AS AMOUNT_VALUE,
       STRENGTH_UNIT AS AMOUNT_UNIT,
       INGREDIENTS_CNT
FROM grr_new_3_1 a
  JOIN source_data b ON a.fcc = b.fcc
WHERE (AMOUNT_VALUE IS NULL OR AMOUNT_VALUE = '0.000') AND   STRENGTH != '0.0' AND   INGREDIENTS_CNT = '1';

--ABS_STRNT_QTY 
CREATE TABLE grr_new_3_4  AS
SELECT DISTINCT FCC,INTL_PACK_FORM_DESC,INTL_PACK_STRNT_DESC,INTL_PACK_SIZE_DESC AS BOX_SIZE,PACK_DESC,PACK_SUBSTN_CNT AS INGREDIENTS_CNT,MOLECULE,PACK_ADDL_STRNT_DESC, WGT_QTY AS AMOUNT_VALUE, WGT_UOM_CD AS AMOUNT_UNIT,NVL(PACK_WGT_QTY,PACK_VOL_QTY) AS DENOMINATOR_VALUE, NVL(PACK_WGT_UOM_CD,PACK_VOL_UOM_CD) AS DENOMINATOR_UNIT,PACK_SIZE_CNT
FROM grr_new_3_for_ds
WHERE WGT_QTY IS NULL AND   ABS_STRNT_QTY IS NOT NULL;

UPDATE GRR_NEW_3_4
   SET AMOUNT_VALUE = '10', AMOUNT_UNIT = 'MG'
WHERE fcc = '196057_01151993' AND   MOLECULE = 'SILICON DIOXIDE';

--googled
UPDATE GRR_NEW_3_4
   SET AMOUNT_VALUE = '10', AMOUNT_UNIT = 'MG'
WHERE fcc = '196057_01151993' AND   MOLECULE = 'IRON FERROUS';

UPDATE GRR_NEW_3_4
   SET AMOUNT_VALUE = '6310', AMOUNT_UNIT = 'G'
WHERE fcc = '601177_10012007' AND   MOLECULE = '2-PROPANOL';

CREATE TABLE grr_ds AS
SELECT DISTINCT *
FROM (SELECT DISTINCT FCC,BOX_SIZE,MOLECULE,DENOMINATOR_VALUE,DENOMINATOR_UNIT,AMOUNT_VALUE,AMOUNT_UNIT,INGREDIENTS_CNT  FROM grr_new_3_1
      WHERE fcc NOT IN (SELECT fcc FROM grr_new_3_2
                        UNION
                        SELECT fcc FROM grr_new_3_3
                        UNION
                        SELECT fcc FROM grr_new_3_4)
      UNION
      SELECT DISTINCT FCC,BOX_SIZE,MOLECULE,DENOMINATOR_VALUE,DENOMINATOR_UNIT,AMOUNT_VALUE,AMOUNT_UNIT,INGREDIENTS_CNT FROM grr_new_3_2
      WHERE fcc NOT IN (SELECT fcc FROM grr_new_3_3 UNION SELECT fcc FROM grr_new_3_4)
      UNION
      SELECT DISTINCT FCC,BOX_SIZE,MOLECULE,DENOMINATOR_VALUE,DENOMINATOR_UNIT,AMOUNT_VALUE,AMOUNT_UNIT,INGREDIENTS_CNT FROM grr_new_3_3 WHERE fcc NOT IN (SELECT fcc FROM grr_new_3_4)
      UNION
      SELECT DISTINCT FCC,BOX_SIZE,MOLECULE,DENOMINATOR_VALUE,DENOMINATOR_UNIT,AMOUNT_VALUE,AMOUNT_UNIT,INGREDIENTS_CNT FROM grr_new_3_4);

DELETE grr_ds
WHERE fcc IN (SELECT a.fcc
              FROM grr_ds a
                JOIN grr_ds b ON a.fcc = b.fcc
              WHERE a.DENOMINATOR_VALUE != b.DENOMINATOR_VALUE OR    a.DENOMINATOR_VALUE IS NULL AND   b.DENOMINATOR_VALUE IS NOT NULL)
AND   DENOMINATOR_VALUE IS NULL;

UPDATE grr_ds
--water
   SET AMOUNT_UNIT = 'G', AMOUNT_VALUE = DENOMINATOR_VALUE
WHERE molecule LIKE '%WATER%' AND   (AMOUNT_VALUE IS NULL OR AMOUNT_VALUE = '0.000');

UPDATE grr_ds
   SET BOX_SIZE = NULL,AMOUNT_VALUE = NULL,AMOUNT_UNIT = NULL,DENOMINATOR_VALUE = NULL,DENOMINATOR_UNIT = NULL
WHERE fcc IN (SELECT fcc
              FROM grr_ds a
              WHERE AMOUNT_VALUE = '0.000' OR DENOMINATOR_VALUE = '0.000' OR a.AMOUNT_VALUE IS NULL OR AMOUNT_UNIT = '--');

UPDATE grr_ds
   SET box_size = NULL-- remove different box sizes
       WHERE fcc IN (SELECT a.fcc
                     FROM grr_ds a
                       JOIN grr_ds b ON a.fcc = b.fcc
                     WHERE a.box_size != b.box_size OR    (a.box_size IS NULL AND b.box_size IS NOT NULL));

UPDATE grr_ds
--remove solid forms with denominator
   SET DENOMINATOR_VALUE = NULL, DENOMINATOR_UNIT = NULL
WHERE fcc IN (SELECT a.fcc
              FROM grr_ds a
                JOIN grr_new_3 b ON a.fcc = b.fcc
              WHERE DENOMINATOR_UNIT IS NOT NULL AND   REGEXP_LIKE (INTL_PACK_FORM_DESC,'TAB|CAP'));

UPDATE grr_ds
   SET AMOUNT_UNIT = 'MCG'
WHERE AMOUNT_UNIT = 'Y';

UPDATE grr_ds
   SET AMOUNT_UNIT = 'IU'
WHERE AMOUNT_UNIT = 'K';

UPDATE grr_ds
-- big part of sprays and aerosols + update box sizes like '%X%'
   SET amount_value = amount_value*REGEXP_REPLACE(BOX_SIZE,'X\d+'), DENOMINATOR_VALUE = REGEXP_REPLACE(BOX_SIZE,'X\d+'), DENOMINATOR_UNIT = 'ACTUAT', box_size = NULL
WHERE box_size LIKE '%X%'
AND   denominator_unit IS NULL;

UPDATE grr_ds
   SET amount_value = amount_value*REGEXP_REPLACE(BOX_SIZE,'X\d+'), box_size = NULL
WHERE box_size LIKE '%X%' AND   denominator_unit = 'ML' AND   (amount_unit NOT IN ('MG','G') OR (amount_unit = 'MG' AND amount_value < 1.1));

UPDATE grr_ds
   SET amount_value = amount_value*REGEXP_REPLACE(BOX_SIZE,'X\d+'), box_size = NULL
WHERE box_size LIKE '%X%' AND   molecule != 'HYDROCORTISONE' AND   (amount_unit != 'MG' OR (amount_unit = 'MG' AND amount_value < 1.1));

UPDATE grr_ds
   SET box_size = '200'
WHERE fcc IN ('02.01.1988-112349','02.01.1988-121916','02.01.1988-237066');

UPDATE grr_ds
--updating inhalers
   SET amount_value = amount_value*BOX_SIZE, DENOMINATOR_VALUE = BOX_SIZE, DENOMINATOR_UNIT = 'ACTUAT', BOX_SIZE = NULL
WHERE fcc IN (SELECT DISTINCT a.fcc
              FROM grr_ds a
                JOIN grr_new_3 b ON a.fcc = b.fcc
              WHERE PACK_DESC LIKE '%AER%' AND   denominator_unit IS NULL)
AND   box_size IS NOT NULL;

UPDATE grr_ds
   SET box_size = NULL 
WHERE box_size LIKE '%X%';

update grr_ds 
set box_size = null,denominator_value = null, denominator_unit = null where fcc in ( '359892_11152000', '420004_07152002');

UPDATE GRR_DS
   SET DENOMINATOR_VALUE = NULL,  DENOMINATOR_UNIT = '', AMOUNT_VALUE = 11
WHERE FCC = '420006_07152002';
UPDATE GRR_DS
   SET DENOMINATOR_VALUE = NULL, DENOMINATOR_UNIT = '', AMOUNT_VALUE = 9.85
WHERE FCC = '420011_07152002';
UPDATE GRR_DS
   SET DENOMINATOR_VALUE = 200, AMOUNT_VALUE = 20
WHERE FCC = '300167_08011998';
UPDATE GRR_DS
   SET DENOMINATOR_VALUE = 200
WHERE FCC = '237066_02011988';
UPDATE GRR_DS
   SET DENOMINATOR_VALUE = 400
WHERE FCC in ('237067_04151991', '170219_04151991') ;
UPDATE GRR_DS
   SET DENOMINATOR_VALUE = 300
WHERE FCC = '172794_06011991';

merge into grr_ds d
using (select distinct g.fcc, g.molecule, abs_strnt_qty,abs_strnt_uom_cd
from grr_ds g join grr_new_3 g2 on g.fcc = g2.fcc and g.molecule = g2.molecule
 where  denominator_value<30 and denominator_unit = 'ACTUAT') a
 on (d.fcc = a.fcc and d.molecule = a.molecule)
 when matched then update
 set box_size = null, amount_value = case when abs_strnt_uom_cd = 'Y' then  cast (abs_strnt_qty as number)/1000
  when abs_strnt_uom_cd = 'MG'
 then cast (abs_strnt_qty as number) else amount_value end, denominator_value = null;

UPDATE grr_ds
--update unit od duplicated ingredeints in order to sum them up
   SET amount_value = amount_value*1000, amount_unit = 'MG'
WHERE fcc IN (SELECT a.fcc
              FROM grr_ds a
                JOIN grr_ds b
                  ON a.fcc = b.fcc AND a.molecule = b.molecule AND (a.AMOUNT_UNIT != b.AMOUNT_UNIT) AND a.fcc IN (SELECT fcc FROM grr_ds GROUP BY fcc, molecule HAVING COUNT(1) > 1) AND a.AMOUNT_UNIT = 'G')
AND   AMOUNT_UNIT = 'G';

UPDATE grr_ds
   SET amount_value = amount_value / 1000,
       amount_unit = 'MG'
WHERE fcc IN (SELECT a.fcc
              FROM grr_ds a
                JOIN grr_ds b  ON a.fcc = b.fcc AND a.molecule = b.molecule AND (a.AMOUNT_UNIT != b.AMOUNT_UNIT) AND a.fcc IN (SELECT fcc FROM grr_ds GROUP BY fcc, molecule HAVING COUNT(1) > 1) AND a.AMOUNT_UNIT = 'MCG')
AND   AMOUNT_UNIT = 'MCG';

UPDATE grr_ds
   SET amount_value = AMOUNT_VALUE*DENOMINATOR_VALUE*10,amount_unit = 'MG'--update %
       WHERE AMOUNT_UNIT = '%' AND   DENOMINATOR_UNIT = 'ML';

UPDATE grr_ds
   SET amount_value = DENOMINATOR_VALUE,amount_unit = 'G'
WHERE AMOUNT_UNIT = '%' AND   DENOMINATOR_UNIT = 'G';

UPDATE grr_ds
   SET amount_value = AMOUNT_VALUE*10,amount_unit = 'MG', DENOMINATOR_UNIT = 'ML'
WHERE AMOUNT_UNIT = '%' AND   DENOMINATOR_UNIT IS NULL;

--updating bias in original data
UPDATE GRR_DS
   SET AMOUNT_VALUE = '500.000', AMOUNT_UNIT = 'MG'
WHERE fcc = '08.15.2015-879797' AND   MOLECULE = 'DEXPANTHENOL';

UPDATE GRR_DS
   SET AMOUNT_VALUE = '10.000',AMOUNT_UNIT = 'MG'
WHERE fcc = '08.15.2015-879797' AND   MOLECULE = 'XYLOMETAZOLINE';

UPDATE GRR_DS
   SET AMOUNT_VALUE = '500.000', AMOUNT_UNIT = 'MG'
WHERE fcc = '08.15.2015-879798' AND   MOLECULE = 'DEXPANTHENOL';

UPDATE GRR_DS
   SET AMOUNT_VALUE = '10.000', AMOUNT_UNIT = 'MG'
WHERE fcc = '08.15.2015-879798' AND   MOLECULE = 'XYLOMETAZOLINE';

UPDATE GRR_DS
   SET DENOMINATOR_UNIT = 'ML'
WHERE fcc = '12.15.2013-825791' AND   MOLECULE = 'XYLOMETAZOLINE';

UPDATE GRR_DS
   SET DENOMINATOR_UNIT = 'ML', AMOUNT_VALUE = '10.000',AMOUNT_UNIT = 'MG'
WHERE fcc = '10.15.2006-567057' AND   MOLECULE = 'XYLOMETAZOLINE';

UPDATE GRR_DS
   SET DENOMINATOR_UNIT = 'ML',AMOUNT_VALUE = '50.000',AMOUNT_UNIT = 'MG'
WHERE fcc = '01.01.2007-572166' AND   MOLECULE = 'DEXPANTHENOL';

UPDATE GRR_DS
   SET DENOMINATOR_UNIT = 'ML',AMOUNT_VALUE = '1.000', AMOUNT_UNIT = 'MG'
WHERE fcc = '01.01.2007-572166' AND   MOLECULE = 'XYLOMETAZOLINE';

UPDATE GRR_DS
   SET AMOUNT_UNIT = NULL,AMOUNT_VALUE = NULL, DENOMINATOR_VALUE = NULL,DENOMINATOR_UNIT = NULL,box_size = NULL
WHERE fcc IN ('09.01.2006-563583','12.01.2004-508584','01.01.1111-284413');

UPDATE GRR_DS
   SET amount_value = '500'
WHERE fcc = '11.15.1997-282894';

UPDATE GRR_DS
   SET AMOUNT_UNIT = 'MG'
WHERE fcc = '05.15.2005-520745' AND   MOLECULE = 'SODIUM' AND   DENOMINATOR_UNIT = 'ML';

DELETE
FROM GRR_DS
WHERE fcc = '12.15.2014-860022' AND   MOLECULE = 'IMIQUIMOD' AND   DENOMINATOR_UNIT = 'G';

DELETE
FROM GRR_DS
WHERE fcc = '05.15.2005-520745' AND   MOLECULE = 'SODIUM' AND   DENOMINATOR_UNIT = 'G';

--delete molecules with weird dosages
DELETE
FROM GRR_DS
WHERE fcc LIKE '12.15.2003-47697%' AND   MOLECULE = 'POTASSIUM' AND   AMOUNT_VALUE = '100.000';

DELETE
FROM GRR_DS
WHERE fcc LIKE '12.15.2003-47697%' AND   MOLECULE = 'MYRISTICA FRAGANS' AND   AMOUNT_VALUE = '100.000';

DELETE
FROM GRR_DS
WHERE fcc LIKE '12.15.2003-47697%' AND   MOLECULE = 'IGNATIA AMARA' AND   AMOUNT_VALUE = '100.000';

DELETE
FROM GRR_DS
WHERE fcc LIKE '12.15.2003-47697%'
AND   MOLECULE = 'FERULA ASSA FOETIDA'
AND   AMOUNT_VALUE = '100.000';

DELETE
FROM GRR_DS
WHERE fcc = '12.15.2003-476978' AND   MOLECULE = 'VALERIANA OFFICINALIS' AND   AMOUNT_VALUE = '100.000';

DELETE
FROM GRR_DS
WHERE fcc IN ('06.01.1995-236293','06.01.1995-896478');

--deleting ingerdients because 1 pzn represents 2 fcc thus we do not need to do it anymore
DELETE
FROM GRR_DS
WHERE fcc = '02.01.1988-112492' AND   MOLECULE = 'ORNITHINE';

--update empty ingredients 
DELETE grr_ds
WHERE fcc IN (SELECT a.fcc
              FROM grr_ds a
                JOIN grr_ds b ON a.fcc = b.fcc
              WHERE a.molecule IS NULL AND   b.molecule IS NOT NULL)
AND   molecule IS NULL;

INSERT INTO grr_ds (FCC,BOX_SIZE,  MOLECULE,  DENOMINATOR_VALUE,  DENOMINATOR_UNIT,  AMOUNT_VALUE,  AMOUNT_UNIT)
SELECT DISTINCT CONCEPT_CODE,  BOX_SIZE,MOLECULE, DENOMINATOR_VALUE,DENOMINATOR_UNIT,AMOUNT_VALUE,AMOUNT_UNIT
FROM grr_pack_2 a
  JOIN drug_concept_stage b ON UPPER (drug_name) = UPPER (concept_name);

CREATE TABLE grr_ds_1 AS
SELECT DISTINCT a.FCC,
       BOX_SIZE,
       DENOMINATOR_VALUE,
       DENOMINATOR_UNIT,
       AMOUNT_VALUE,
       AMOUNT_UNIT,
       CASE
         WHEN molecule IS NULL AND NOT REGEXP_LIKE (SUBSTANCE,'HEALING|KEINE|\+|DIET|MEDICATED|MULTI') THEN substance
         ELSE molecule
       END AS molecule
FROM source_data_1 b
  RIGHT JOIN GRR_DS a ON a.fcc = b.fcc;

CREATE TABLE ds_stage_sum AS
SELECT FCC, MOLECULE, BOX_SIZE, SUM(AMOUNT_VALUE) AS amount_value, AMOUNT_UNIT, DENOMINATOR_VALUE,DENOMINATOR_UNIT
FROM grr_ds_1
GROUP BY fcc, molecule,BOX_SIZE, AMOUNT_UNIT, DENOMINATOR_VALUE,DENOMINATOR_UNIT;

UPDATE DS_STAGE_SUM
   SET BOX_SIZE = NULL, DENOMINATOR_VALUE = NULL,DENOMINATOR_UNIT = NULL, AMOUNT_VALUE = NULL,AMOUNT_UNIT = NULL
WHERE fcc IN (SELECT fcc
              FROM grr_ds
              WHERE REGEXP_LIKE (DENOMINATOR_UNIT,'KG') OR    REGEXP_LIKE (AMOUNT_UNIT,'KG'));

CREATE TABLE ds_stage_0  AS
SELECT DISTINCT fcc AS drug_concept_code, b.concept_Code AS ingredient_concept_code,molecule,
 CASE
         WHEN DENOMINATOR_UNIT IS NULL AND AMOUNT_UNIT NOT IN ('DH','C','CH','D','TM','X','XMK') THEN AMOUNT_VALUE
         ELSE NULL
       END AS AMOUNT_VALUE,
       -- put homeopathy into numerator
 CASE
         WHEN DENOMINATOR_UNIT IS NULL AND AMOUNT_UNIT NOT IN ('DH','C','CH','D','TM','X','XMK') THEN AMOUNT_UNIT
         ELSE NULL
       END AS AMOUNT_UNIT,
 CASE
         WHEN DENOMINATOR_UNIT IS NOT NULL OR AMOUNT_UNIT IN ('DH','C','CH','D','TM','X','XMK') THEN AMOUNT_VALUE
         ELSE NULL
       END AS NUMERATOR_VALUE,
 CASE
         WHEN DENOMINATOR_UNIT IS NOT NULL OR AMOUNT_UNIT IN ('DH','C','CH','D','TM','X','XMK') THEN AMOUNT_UNIT
         ELSE NULL
       END AS NUMERATOR_UNIT,
       DENOMINATOR_VALUE, DENOMINATOR_UNIT,BOX_SIZE
FROM DS_STAGE_SUM a
     JOIN drug_concept_stage b ON UPPER (molecule) = UPPER (concept_name) AND concept_class_id = 'Ingredient';

INSERT INTO ds_stage (DRUG_CONCEPT_CODE,  INGREDIENT_CONCEPT_CODE,  AMOUNT_VALUE,  AMOUNT_UNIT,  NUMERATOR_VALUE,  NUMERATOR_UNIT,  DENOMINATOR_VALUE,  DENOMINATOR_UNIT,  BOX_SIZE)
SELECT DISTINCT DRUG_CONCEPT_CODE, INGREDIENT_CONCEPT_CODE, AMOUNT_VALUE,AMOUNT_UNIT, NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT, CAST(BOX_SIZE AS NUMBER)
FROM ds_stage_0
WHERE drug_concept_code NOT IN (SELECT fcc FROM grr_pack_2);

--ds_stage for source_data
CREATE TABLE ds_0_sd AS
SELECT DISTINCT a.fcc,substance,
 CASE
         WHEN STRENGTH = '0' THEN NULL
         ELSE STRENGTH
       END AS STRENGTH,
 CASE
         WHEN STRENGTH_UNIT = 'Y/H' THEN 'MCG'
         WHEN STRENGTH_UNIT = 'K.' THEN 'K'
         ELSE STRENGTH_UNIT
       END AS STRENGTH_UNIT,
 CASE
         WHEN VOLUME = '0' THEN NULL
         ELSE VOLUME
       END AS VOLUME,
 CASE
         WHEN STRENGTH_UNIT = 'Y/H' THEN 'HOUR'
         WHEN VOLUME_UNIT = 'K.' THEN 'K'
         ELSE VOLUME_UNIT
       END AS VOLUME_UNIT,
       b.concept_name, CAST(PACKSIZE AS NUMBER) AS box_size,PRODUCT_FORM_NAME
FROM source_data_1 a
  LEFT JOIN grr_form_2 b ON a.fcc = b.fcc
WHERE NO_OF_SUBSTANCES = '1'
OR    (NO_OF_SUBSTANCES != '1' AND STRENGTH != '0.0');

UPDATE ds_0_sd
   SET volume = NULL,
       VOLUME_UNIT = NULL
WHERE (volume IS NOT NULL AND strength IS NULL) OR (volume IS NOT NULL AND REGEXP_LIKE (concept_name,'Globule|Pellet|Tablet|Suppos'));

UPDATE ds_0_sd
   SET STRENGTH = STRENGTH*10,
       VOLUME_UNIT = CASE
                       WHEN VOLUME_UNIT IS NULL THEN 'ML'
                       ELSE VOLUME_UNIT END,
       STRENGTH_UNIT = 'MG'
WHERE STRENGTH_UNIT = '%'
;

--sprays with wrong dosages
UPDATE ds_0_sd
   SET STRENGTH = REGEXP_SUBSTR(PRODUCT_FORM_NAME,'\d+')*STRENGTH
WHERE fcc IN (SELECT fcc 
	      FROM source_data_1
              WHERE THERAPY_NAME LIKE '%DOS.%'  AND   STRENGTH_UNIT IN ('MG','Y') AND   VOLUME IS NOT NULL AND   VOLUME != '0.0')
AND   REGEXP_SUBSTR(PRODUCT_FORM_NAME,'\d+') IS NOT NULL;

--delete all the drugs that do not have dosages
DELETE ds_0_sd
WHERE substance LIKE '%+%';

DELETE ds_0_sd
WHERE fcc IN (SELECT fcc FROM ds_0_sd WHERE strength = '0');

UPDATE ds_0_sd --there are '0' as denominator_value 
SET volume = null WHERE volume = '0';

INSERT INTO ds_stage (DRUG_CONCEPT_CODE,  INGREDIENT_CONCEPT_CODE,  BOX_SIZE,  AMOUNT_VALUE,  AMOUNT_UNIT,  NUMERATOR_VALUE,  NUMERATOR_UNIT,  DENOMINATOR_VALUE,  DENOMINATOR_UNIT)
SELECT FCC, CONCEPT_CODE,a.BOX_SIZE, STRENGTH,STRENGTH_UNIT, NULL, NULL, NULL,NULL
FROM ds_0_sd a
  JOIN drug_concept_stage b ON UPPER (b.concept_name) = UPPER (substance)AND concept_class_id = 'Ingredient'
WHERE (volume_unit IS NULL AND strength_unit NOT IN ('DH','C','CH','D','TM','X','XMK'))
AND   fcc NOT IN (SELECT drug_concept_code FROM ds_stage)
UNION
SELECT FCC,CONCEPT_CODE,a.BOX_SIZE,NULL, NULL, STRENGTH, STRENGTH_UNIT, VOLUME, VOLUME_UNIT
FROM ds_0_sd a
  JOIN drug_concept_stage b
    ON UPPER (b.concept_name) = UPPER (substance)
   AND concept_class_id = 'Ingredient'
WHERE (volume_unit IS NOT NULL OR strength_unit IN ('DH','C','CH','D','TM','X','XMK'))
AND   fcc NOT IN (SELECT drug_concept_code FROM ds_stage);

--work with ds_stage, strarting with grr pattern
UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 500
WHERE DRUG_CONCEPT_CODE IN ('235152_05151995','307287_05151995') AND   NUMERATOR_VALUE = 576 AND   NUMERATOR_UNIT = 'MG';

UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 950
WHERE DRUG_CONCEPT_CODE = '280104_09151997' AND   NUMERATOR_VALUE = 9500000 AND   NUMERATOR_UNIT = 'MG';

UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 100
WHERE DRUG_CONCEPT_CODE = '274138_07011997' AND   NUMERATOR_VALUE = 100000 AND   NUMERATOR_UNIT = 'MG';

UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 5
WHERE DRUG_CONCEPT_CODE = '871469_05152015' AND   NUMERATOR_VALUE = 500 AND   NUMERATOR_UNIT = 'MG';

UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 1900
WHERE DRUG_CONCEPT_CODE = '280105_09151997' AND   NUMERATOR_VALUE = 19000000 AND   NUMERATOR_UNIT = 'MG';

UPDATE DS_STAGE
   SET amount_unit = 'G'
WHERE amount_unit = 'GR';

UPDATE DS_STAGE
   SET amount_unit = 'MG'
WHERE amount_unit = 'O';

UPDATE DS_STAGE
   SET NUMERATOR_UNIT = 'MG'
WHERE NUMERATOR_UNIT = 'O';

UPDATE DS_STAGE
   SET BOX_SIZE = NULL,NUMERATOR_VALUE = 15
WHERE DRUG_CONCEPT_CODE = '601236_10012007';

UPDATE DS_STAGE
   SET BOX_SIZE = NULL,NUMERATOR_VALUE = 250
WHERE DRUG_CONCEPT_CODE = '19576_01011972';

UPDATE DS_STAGE
   SET BOX_SIZE = NULL, NUMERATOR_VALUE = 0.2
WHERE DRUG_CONCEPT_CODE = '758494_01012012';

UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 0.01
WHERE DRUG_CONCEPT_CODE = '561280_08012006';

UPDATE DS_STAGE
   SET NUMERATOR_VALUE = 500
WHERE DRUG_CONCEPT_CODE = '307287_05151995';

UPDATE ds_stage
--remove tablet's denominators 
   SET denominator_unit = NULL, denominator_value = NULL,AMOUNT_UNIT = NUMERATOR_UNIT,AMOUNT_VALUE = NUMERATOR_VALUE, NUMERATOR_VALUE = NULL,NUMERATOR_UNIT = NULL
WHERE drug_concept_code IN (SELECT fcc
                            FROM grr_new_3 a
                              JOIN DS_STAGE b ON drug_concept_code = fcc
                            WHERE (PACK_DESC LIKE '%KAPS%' OR PACK_DESC LIKE '%TABL%' OR PACK_DESC LIKE '%PELLET%') AND   denominator_unit IS NOT NULL AND numerator_unit NOT IN ('DH','C','CH','D','TM','X','XMK'));

--creating table to improve dosages in inhalers
CREATE TABLE spray_upd AS
SELECT a.*, b.INTL_PACK_FORM_DESC,INTL_PACK_STRNT_DESC
FROM ds_stage a
  JOIN grr_new_3 b ON DRUG_CONCEPT_CODE = fcc
WHERE DRUG_CONCEPT_CODE IN (SELECT DRUG_CONCEPT_CODE
                            FROM ds_stage
                            WHERE numerator_unit = 'MCG' AND   box_size IS NOT NULL)
AND   INTL_PACK_STRNT_DESC LIKE '%DOSE%';

UPDATE spray_upd
   SET NUMERATOR_VALUE = NUMERATOR_VALUE*box_size,box_size = NULL
WHERE DRUG_CONCEPT_CODE IN (SELECT DRUG_CONCEPT_CODE
                            FROM spray_upd
                            WHERE REGEXP_SUBSTR(INTL_PACK_STRNT_DESC,'\d+') = NUMERATOR_VALUE);

UPDATE spray_upd
   SET box_size = NULL
WHERE DENOMINATOR_UNIT = 'ACTUAT';

DELETE ds_stage
WHERE DRUG_CONCEPT_CODE IN (SELECT DRUG_CONCEPT_CODE FROM spray_upd);

INSERT INTO ds_stage (DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE, BOX_SIZE,  AMOUNT_VALUE,  AMOUNT_UNIT,  NUMERATOR_VALUE,  NUMERATOR_UNIT,  DENOMINATOR_VALUE,  DENOMINATOR_UNIT)
SELECT DISTINCT DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE, BOX_SIZE, AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT, DENOMINATOR_VALUE,DENOMINATOR_UNIT
FROM spray_upd;

CREATE TABLE ds_vol_upd AS
SELECT DISTINCT a.*, INTL_PACK_STRNT_DESC,ABS_STRNT_QTY, ABS_STRNT_UOM_CD, RLTV_STRNT_QTY
FROM ds_stage a
  JOIN grr_new_3 ON drug_concept_code = fcc
  JOIN drug_concept_stage d ON a.ingredient_concept_code = d.concept_code AND UPPER (d.concept_name) = UPPER (molecule)
WHERE AMOUNT_VALUE IS NOT NULL
AND   RLTV_STRNT_QTY IS NOT NULL
AND   ABS_STRNT_QTY != '%';

UPDATE ds_vol_upd
   SET amount_unit = NULL, amount_value = NULL,
       NUMERATOR_VALUE = CASE
                           WHEN ABS_STRNT_UOM_CD = 'Y' THEN '1.75'
                           ELSE ABS_STRNT_QTY END,
       NUMERATOR_UNIT = CASE
                          WHEN ABS_STRNT_UOM_CD = 'Y' THEN 'MCG'
                          WHEN ABS_STRNT_UOM_CD = 'K' THEN 'IU'
                          ELSE ABS_STRNT_UOM_CD END ,
       DENOMINATOR_UNIT = 'ML';

DELETE ds_stage
WHERE drug_concept_code IN (SELECT drug_concept_code FROM ds_vol_upd);

INSERT INTO ds_stage (DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,  BOX_SIZE,  AMOUNT_VALUE,  AMOUNT_UNIT,  NUMERATOR_VALUE,  NUMERATOR_UNIT,  DENOMINATOR_VALUE,  DENOMINATOR_UNIT)
SELECT DISTINCT DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,BOX_SIZE, AMOUNT_VALUE, AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE, DENOMINATOR_UNIT
FROM ds_vol_upd;

UPDATE ds_stage
   SET numerator_unit = 'MG',
       numerator_value = CASE
                           WHEN UPPER(denominator_unit) = 'MG' THEN (numerator_value / 100)*NVL(denominator_value,1)
                           WHEN UPPER(denominator_unit) = 'ML' THEN numerator_value*10*NVL(denominator_value,1)
                           ELSE numerator_value  END 
WHERE numerator_unit = '%';

DELETE
FROM DS_STAGE
WHERE DRUG_CONCEPT_CODE = '797966_02152012' AND   DENOMINATOR_VALUE = 0.5;

DELETE
FROM DS_STAGE 
WHERE DRUG_CONCEPT_CODE = '762378_02152012' AND   DENOMINATOR_VALUE = 1.5;

DELETE
FROM DS_STAGE 
WHERE DRUG_CONCEPT_CODE = '797968_02152012' AND   DENOMINATOR_VALUE = 1.5;

DELETE
FROM DS_STAGE
WHERE DRUG_CONCEPT_CODE = '52184_03011974' AND   NUMERATOR_VALUE = 350 AND   NUMERATOR_UNIT = 'MG';

--coal tar
--delete drugs with impossible dosages
DELETE ds_stage
WHERE drug_concept_code IN (SELECT drug_concept_code
                            FROM ds_stage
                            WHERE (LOWER(numerator_unit) IN ('g') AND LOWER(denominator_unit) IN ('ml') AND numerator_value / NVL(denominator_value,1) > 1));

DELETE ds_stage
WHERE drug_concept_code IN (SELECT drug_concept_code
                            FROM ds_stage
                            WHERE (LOWER(numerator_unit) IN ('mg') AND LOWER(denominator_unit) IN ('ml','g') OR LOWER(numerator_unit) IN ('g') AND LOWER(denominator_unit) IN ('l')) AND   numerator_value / NVL(denominator_value,1) > 1000);

DELETE ds_stage
WHERE drug_concept_code IN (SELECT drug_concept_code
                            FROM ds_stage
                            WHERE amount_unit IS NULL AND   numerator_unit IS NULL);

--delete drugs with wrong units
DELETE ds_stage
WHERE drug_concept_code IN (SELECT drug_concept_code
                            FROM ds_stage
                            WHERE amount_unit IN ('--','LM','NR') OR    numerator_unit IN ('--','LM','NR') OR    denominator_unit IN ('--','LM','NR'));

commit;

--can't calculate dosages in parsed drugs
DELETE ds_stage
WHERE drug_concept_code IN (SELECT fcc 
                            FROM grr_new_3
                            WHERE molecule IN (SELECT ingr FROM ingr_parsing));

DELETE ds_stage
WHERE drug_concept_code IN ('804437_01042013','63186_01051969','240215_10151995','476978_12152003');

DELETE ds_stage
WHERE drug_concept_code = '769391_10012008' AND   denominator_value = '15100';

--due to liquid->solid update
DELETE DS_STAGE
WHERE ROWID NOT IN (SELECT MIN(ROWID)
                    FROM DS_STAGE
                    GROUP BY DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE, BOX_SIZE,AMOUNT_VALUE, AMOUNT_UNIT, NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT);

--inserting 2 missing ingredients that occured in source_data

insert into ds_stage (drug_concept_code,ingredient_concept_code,box_size,amount_value,amount_unit)
(select '697873_05012010',concept_code, '20','50','MG'
from drug_concept_stage where concept_name = 'Caffeine');

insert into ds_stage (drug_concept_code,ingredient_concept_code,box_size,amount_value,amount_unit)
(select '697873_05012010',concept_code, '20','200','MG'
from drug_concept_stage where concept_name = 'Paracetamol');

--wrong dosages in grr_new_3
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 100 WHERE DRUG_CONCEPT_CODE = '102109_10011986';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 300 WHERE DRUG_CONCEPT_CODE = '107389_05011987';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 300 WHERE DRUG_CONCEPT_CODE = '107389_05011987';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 72000 WHERE DRUG_CONCEPT_CODE = '108769_07011987';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '108770_07011987';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 72000 WHERE DRUG_CONCEPT_CODE = '108771_07011987';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '108772_07011987';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 30000 WHERE DRUG_CONCEPT_CODE = '120010_08011988';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 200 WHERE DRUG_CONCEPT_CODE = '122788_10011988';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 1000 WHERE DRUG_CONCEPT_CODE = '122789_10011988';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 10660 WHERE DRUG_CONCEPT_CODE = '148013_12011989';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '165930_12151990';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 360000 WHERE DRUG_CONCEPT_CODE = '167830_02151991';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 100 WHERE DRUG_CONCEPT_CODE = '177828_09011991';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 100 WHERE DRUG_CONCEPT_CODE = '177829_09011991';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 10000 WHERE DRUG_CONCEPT_CODE = '184008_02011992';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '184777_02151992';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 225000 WHERE DRUG_CONCEPT_CODE = '184778_02151992';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 20000 WHERE DRUG_CONCEPT_CODE = '187599_05011992';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 497500 WHERE DRUG_CONCEPT_CODE = '197354_01011111';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 30000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '198777_03011993';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 100 WHERE DRUG_CONCEPT_CODE = '205456_09011993';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '212199_01011994';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 25000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '225554_10151994';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 270000 WHERE DRUG_CONCEPT_CODE = '228694_01011995';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 135000 WHERE DRUG_CONCEPT_CODE = '228740_01011995';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 270000 WHERE DRUG_CONCEPT_CODE = '228741_01011995';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '237297_08011995';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 4000 WHERE DRUG_CONCEPT_CODE = '241345_11151995';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 250000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '246952_05151996';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 500000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '246953_05151996';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 100000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '246954_05151996';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '293742_04011998';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '297016_06011998';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 270000 WHERE DRUG_CONCEPT_CODE = '297017_06011998';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '298630_07151998';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 400 WHERE DRUG_CONCEPT_CODE = '307936_01011971';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 400 WHERE DRUG_CONCEPT_CODE = '362968_01012001';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 1700 WHERE DRUG_CONCEPT_CODE = '363765_01012001';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 300 WHERE DRUG_CONCEPT_CODE = '366910_02012001';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '370514_07151998';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '385158_04011998';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 3000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '404661_03011993';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 10000,       NUMERATOR_UNIT = 'IU' WHERE DRUG_CONCEPT_CODE = '404788_04011994';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '433993_11012002';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 11250 WHERE DRUG_CONCEPT_CODE = '453371_03012001';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 72000 WHERE DRUG_CONCEPT_CODE = '477194_12152003';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '477195_12152003';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 72000 WHERE DRUG_CONCEPT_CODE = '477205_12152003';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 180000 WHERE DRUG_CONCEPT_CODE = '477206_12152003';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 200 WHERE DRUG_CONCEPT_CODE = '544642_01152006';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '573326_01011994';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '691519_03012010';
UPDATE DS_STAGE   SET NUMERATOR_VALUE = 150000 WHERE DRUG_CONCEPT_CODE = '691524_03012010';


delete ds_stage
where ingredient_concept_code = (select concept_code from drug_concept_stage where concept_name = 'Aminoacids');


COMMIT;

TRUNCATE TABLE internal_relationship_stage;
INSERT INTO internal_relationship_stage(  CONCEPT_CODE_1,  CONCEPT_CODE_2)
--drug to form
SELECT fcc, concept_code FROM grr_form_2 
WHERE fcc NOT IN (SELECT fcc FROM grr_pack_2)
UNION
--pack drug to form
SELECT c.concept_code,  a.concept_code FROM grr_form_2 a
JOIN grr_pack_2 b ON a.fcc = b.fcc
JOIN drug_concept_stage c ON UPPER (drug_name) = UPPER (c.concept_name)
UNION
--drug to bn
SELECT fcc, concept_code FROM grr_bn_2
JOIN drug_concept_stage ON UPPER (bn) = UPPER (concept_name) 
WHERE concept_class_id = 'Brand Name'
UNION
--pack_drug to bn
SELECT c.concept_code, d.concept_code FROM grr_bn_2 a
JOIN grr_pack_2 b ON a.fcc = b.fcc
JOIN drug_concept_stage c ON UPPER (drug_name) = UPPER (c.concept_name)
JOIN drug_concept_stage d ON UPPER (bn) = UPPER (d.concept_name)
WHERE d.concept_class_id = 'Brand Name'
UNION
--drug to supp
SELECT fcc, concept_code FROM grr_manuf
JOIN drug_concept_stage ON UPPER (PRI_ORG_LNG_NM) = UPPER (concept_name)
WHERE concept_class_id = 'Supplier'
UNION
--pack_drug to supp
SELECT DISTINCT c.concept_code, d.concept_code FROM grr_manuf a
JOIN grr_pack_2 b ON a.fcc = b.fcc
JOIN drug_concept_stage c ON UPPER (drug_name) = UPPER (c.concept_name)
JOIN drug_concept_stage d ON UPPER (PRI_ORG_LNG_NM) = UPPER (d.concept_name)
--where d.concept_class_id='Supplier'
UNION
--drug to ingr
SELECT fcc,concept_code FROM grr_ing_2
JOIN drug_concept_stage b ON UPPER (ingredient) = UPPER (concept_name) AND concept_class_id = 'Ingredient'
UNION
--pack to ing
SELECT DISTINCT c.concept_code, d.concept_code FROM grr_pack_2 b
JOIN drug_concept_stage c ON UPPER (drug_name) = UPPER (c.concept_name)
JOIN drug_concept_stage d ON UPPER (molecule) = UPPER (d.concept_name);

--delete relationship to supplier from Drug Comp or Drug Forms
DELETE internal_relationship_stage
WHERE (concept_code_1,concept_code_2) IN (SELECT concept_code_1,concept_code_2
                                          FROM internal_relationship_stage
                                            JOIN drug_concept_stage ON concept_code_2 = concept_code AND concept_class_id = 'Supplier')
AND   concept_code_1 NOT IN (SELECT concept_code_1
                             FROM internal_relationship_stage
                               JOIN drug_concept_stage ON concept_code_2 = concept_code AND concept_class_id = 'Dose Form');

DELETE internal_relationship_stage
WHERE (concept_code_1,concept_code_2) IN (SELECT concept_code_1, concept_code_2
                                          FROM internal_relationship_stage
                                            JOIN drug_concept_stage ON concept_code_2 = concept_code AND concept_class_id = 'Supplier')
AND   concept_code_1 NOT IN (SELECT drug_concept_code FROM ds_stage);

DELETE internal_relationship_stage
WHERE concept_code_1 = '52184_03011974'
AND   concept_code_2 IN (SELECT concept_code
                         FROM drug_concept_stage  WHERE concept_name = 'Coal Tar');

DELETE internal_relationship_stage
WHERE concept_code_1 = '912928_07152016'
AND   concepT_code_2 IN (SELECT concept_code
                         FROM drug_concept_stage
                         WHERE concept_name = 'Methyl-5-Aminolevulinic Acid');

--delete internal_relationship_stage 
--where concept_code_2 = (select concept_code from drug_concept_stage where concept_name = 'Aminoacids');

--delete drugs that don't have ingredients
delete drug_concept_stage
WHERE concept_code NOT IN (SELECT concept_code_1
                                 FROM internal_relationship_stage
                                   JOIN drug_concept_stage ON concept_code_2 = concept_code  AND concept_class_id = 'Ingredient')
AND   concept_code NOT IN (SELECT pack_concept_code FROM pc_stage)
AND   concept_class_id = 'Drug Product';

--delete drug comp boxes
delete
ds_stage where box_size is not null
AND   drug_concept_code NOT IN (SELECT concept_code_1
                             FROM internal_relationship_stage
                               JOIN drug_concept_stage ON concept_code_2 = concept_code AND concept_class_id = 'Dose Form');

--place homeopathy into amount where it belongs to solid form
update ds_stage
set amount_value = numerator_value, amount_unit = numerator_unit, numerator_value = null, numerator_unit= null
where drug_concept_code in (
      SELECT drug_concept_code
      FROM concept c
 	 JOIN relationship_to_concept rc2 ON concept_id_2 = concept_id
         JOIN internal_relationship_stage irs ON rc2.concept_code_1 = irs.concept_code_2
         JOIN ds_stage ds ON ds.drug_concept_code = irs.concept_code_1
         JOIN relationship_to_concept rtc    ON numerator_unit = rtc.concept_code_1   AND rtc.concept_id_2 IN (9324, 9325)
     WHERE REGEXP_LIKE (concept_name,'Tablet|Capsule|Lozenge')
     AND   concept_class_id = 'Dose Form' AND   vocabulary_id LIKE 'Rx%');

COMMIT;

TRUNCATE TABLE pc_stage;
INSERT INTO pc_stage (PACK_CONCEPT_CODE,  DRUG_CONCEPT_CODE,  AMOUNT,  BOX_SIZE)
SELECT DISTINCT fcc, concept_code,NULL, box_size
FROM grr_pack_2 a
  JOIN drug_concept_stage b ON upper(a.DRUG_NAME) = UPPER (b.concept_name);

TRUNCATE TABLE RELATIONSHIP_TO_CONCEPT;
INSERT INTO RELATIONSHIP_TO_CONCEPT (concept_code_1,  vocabulary_id_1,  concept_id_2,  precedence,  CONVERSION_FACTOR)
SELECT DISTINCT concept_code, 'GRR', CONCEPT_id,precedence, NULL
FROM RELATIONSHIP_TO_CONCEPT_OLD r
  JOIN drug_concept_stage d ON UPPER (d.concept_name) = UPPER (r.concept_name)
UNION
SELECT concept_code,'GRR', CONCEPT_id_2, precedence, conversion_factor FROM aut_unit_all_mapped
UNION
SELECT concept_code, 'GRR', concept_id, precedence,NULL FROM aut_form_1;

--delete invalid mappings
DELETE RELATIONSHIP_TO_CONCEPT
WHERE concept_id_2 IN (SELECT concept_id FROM devv5.concept WHERE invalid_reason = 'D');

INSERT INTO relationship_to_concept (concept_code_1,  vocabulary_id_1,  concept_id_2,precedence)
SELECT DISTINCT dcs.concept_code, 'GRR',cc.concept_id, 1
FROM drug_concept_stage dcs
  JOIN concept cc ON LOWER (cc.concept_name) = LOWER (dcs.concept_name) AND cc.concept_class_id = dcs.concept_class_id AND cc.vocabulary_id LIKE 'RxNorm%'
  LEFT JOIN relationship_to_concept cr ON dcs.concept_code = cr.concept_code_1
WHERE concept_code_1 IS NULL
AND  ( cc.invalid_reason IS NULL or  cc.invalid_reason = 'U')
AND   dcs.concept_class_id IN ('Ingredient','Brand Name','Dose Form','Supplier');

--precise ingredients
update relationship_to_concept
set concept_id_2 = 43012256 --aluminum silicate
where concept_id_2 = 43531906;
update relationship_to_concept
set concept_id_2 = 1592180 --cerivastatin
where concept_id_2 = 1586226;
update relationship_to_concept
set concept_id_2 =1592178  --metaclazepam
where concept_id_2 = 19072052;


--insert relationships to ATC
INSERT INTO RELATIONSHIP_TO_CONCEPT (concept_code_1,vocabulary_id_1, concept_id_2,precedence)
SELECT fcc, 'GRR', c.concept_id, RANK() OVER (PARTITION BY fcc ORDER BY who_atc1_code DESC)
FROM (SELECT fcc, who_atc1_code FROM source_data_1
      UNION
      SELECT fcc,who_atc2_code FROM source_data_1
      UNION
      SELECT fcc,who_atc3_code FROM source_data_1
      UNION
      SELECT fcc,who_atc4_code  FROM source_data_1
      UNION
      SELECT fcc, who_atc5_code FROM source_data_1) a
  JOIN concept c ON c.concept_code = a.who_atc1_code AND vocabulary_id = 'ATC' AND invalid_reason IS NULL;

CREATE TABLE rtc_upd AS
SELECT CONCEPT_CODE_1,VOCABULARY_ID_1, PRECEDENCE,CONVERSION_FACTOR,C.CONCEPT_ID_2
FROM relationship_to_concept a
  JOIN devv5.concept b ON concept_id = a.concept_id_2
  JOIN devv5.concept_relationship c ON concept_id = concept_id_1
WHERE b.invalid_reason IS NOT NULL
AND   RELATIONSHIP_ID = 'Concept replaced by';

DELETE relationship_to_concept
WHERE concept_code_1 IN (SELECT concept_code_1 FROM rtc_upd);

INSERT INTO relationship_to_concept (CONCEPT_CODE_1,VOCABULARY_ID_1, CONCEPT_ID_2,PRECEDENCE,CONVERSION_FACTOR)
SELECT CONCEPT_CODE_1, VOCABULARY_ID_1, CONCEPT_ID_2, PRECEDENCE, CONVERSION_FACTOR
FROM rtc_upd;

--manual mapping
INSERT INTO relationship_to_concept (CONCEPT_CODE_1,VOCABULARY_ID_1, CONCEPT_ID_2,PRECEDENCE)
SELECT concept_code, 'GRR', concept_id_2,precedence
FROM drug_concept_stage join rtc_manual usnig (concept_name);

--updating ingredients that create duplicates after mapping to RxNorm
CREATE TABLE ds_sum_2  AS
WITH a AS
(SELECT DISTINCT ds.drug_concept_code,ds.ingredient_concept_code,ds.box_size,ds.AMOUNT_VALUE,ds.AMOUNT_UNIT,ds.NUMERATOR_VALUE,ds.NUMERATOR_UNIT,ds.DENOMINATOR_VALUE,ds.DENOMINATOR_UNIT,rc.concept_id_2
FROM ds_stage ds
  JOIN ds_stage ds2 ON ds.drug_concept_code = ds2.drug_concept_code AND ds.ingredient_concept_code != ds2.ingredient_concept_code
  JOIN relationship_to_concept rc ON ds.ingredient_concept_code = rc.concept_code_1
  JOIN relationship_to_concept rc2 ON ds2.ingredient_concept_code = rc2.concept_code_1
WHERE rc.concept_id_2 = rc2.concept_id_2) SELECT DISTINCT DRUG_CONCEPT_CODE,MAX(INGREDIENT_CONCEPT_CODE) OVER (PARTITION BY DRUG_CONCEPT_CODE,concept_id_2) AS ingredient_concept_code,box_size,SUM(AMOUNT_VALUE) OVER (PARTITION BY DRUG_CONCEPT_CODE) AS AMOUNT_VALUE,AMOUNT_UNIT,SUM(NUMERATOR_VALUE) OVER (PARTITION BY DRUG_CONCEPT_CODE,concept_id_2) AS NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT FROM a
UNION
SELECT DRUG_CONCEPT_CODE, INGREDIENT_CONCEPT_CODE,box_size,NULL AS AMOUNT_VALUE, '' AS AMOUNT_UNIT, NULL AS NUMERATOR_VALUE, '' AS NUMERATOR_UNIT,NULL AS DENOMINATOR_VALUE,'' AS DENOMINATOR_UNIT
FROM a
WHERE (drug_concept_code,ingredient_concept_code) NOT IN (SELECT drug_concept_code, MAX(ingredient_concept_code)
                                                          FROM a
                                                          GROUP BY drug_concept_code);

DELETE
FROM ds_stage
WHERE (drug_concept_code,ingredient_concept_code) IN (SELECT drug_concept_code, ingredient_concept_code
                                                      FROM ds_sum_2);

INSERT INTO DS_STAGE (DRUG_CONCEPT_CODE,  INGREDIENT_CONCEPT_CODE,  BOX_SIZE,  AMOUNT_VALUE,  AMOUNT_UNIT,  NUMERATOR_VALUE,  NUMERATOR_UNIT,  DENOMINATOR_VALUE,  DENOMINATOR_UNIT)
SELECT DISTINCT DRUG_CONCEPT_CODE,INGREDIENT_CONCEPT_CODE,BOX_SIZE,AMOUNT_VALUE,AMOUNT_UNIT,NUMERATOR_VALUE,NUMERATOR_UNIT,DENOMINATOR_VALUE,DENOMINATOR_UNIT
FROM DS_SUM_2
WHERE NVL(AMOUNT_VALUE,NUMERATOR_VALUE) IS NOT NULL;

--delete relationship to ingredients that we removed
DELETE internal_relationship_stage
WHERE (concept_code_1,concept_code_2) IN (SELECT drug_concept_code,
                                                 ingredient_concept_code
                                          FROM ds_sum_2
                                          WHERE NVL(AMOUNT_VALUE,NUMERATOR_VALUE) IS NULL);

UPDATE drug_concept_stage
   SET concept_name = REGEXP_REPLACE(REGEXP_REPLACE(concept_name,'  ',' '),'(>)')
WHERE concept_code NOT IN (SELECT drug_concept_code FROM ds_stage)
AND   concept_class_id = 'Drug Product';

CREATE TABLE ds_stage_cnc AS
SELECT denominator_value|| ' ' || denominator_unit AS quant,
       drug_concept_code,
       i.concept_name || ' ' || NVL(amount_value, 
        round(numerator_value / NVL(denominator_value,1), 3-floor(log(10, (numerator_value / NVL(denominator_value,1)))-1))) 
        || ' ' ||nvl(amount_unit,numerator_unit) AS dosage_name
FROM ds_stage
  JOIN drug_concept_stage i ON i.concept_code = ingredient_concept_code;

CREATE TABLE ds_stage_cnc2 AS
SELECT QUANT,DRUG_CONCEPT_CODE,
       LISTAGG(DOSAGE_NAME,' / ') within group(ORDER BY DOSAGE_NAME ASC) AS dos_name_cnc
FROM ds_stage_cnc
GROUP BY QUANT, DRUG_CONCEPT_CODE;

CREATE TABLE ds_stage_cnc3 AS
SELECT QUANT, DRUG_CONCEPT_CODE,
       CASE
         WHEN REGEXP_LIKE (QUANT,'^\d.*') THEN QUANT|| ' ' ||dos_name_cnc
         ELSE dos_name_cnc END AS strength_name
FROM ds_stage_cnc2;

CREATE TABLE rel_to_name AS
SELECT ri.*, d.concept_name, d.concept_class_id
FROM internal_relationship_stage ri
  JOIN drug_concept_stage d ON concept_code = concept_code_2;

CREATE TABLE new_name 
AS
SELECT DISTINCT c.DRUG_CONCEPT_CODE,
       STRENGTH_NAME || CASE
         WHEN f.concept_name IS NOT NULL THEN ' ' ||f.concept_name
         ELSE NULL
       END 
|| CASE
         WHEN b.concept_name IS NOT NULL THEN ' [' ||b.concept_name || ']'
         ELSE NULL
       END 
|| CASE
         WHEN s.concept_name IS NOT NULL THEN ' by ' ||s.concept_name
         ELSE NULL
       END 
|| CASE
         WHEN ds.box_size IS NOT NULL THEN ' Box of ' ||ds.box_size
         ELSE NULL
       END AS concept_name
FROM ds_stage_cnc3 c
  LEFT JOIN rel_to_name f
         ON c.drug_concept_code = f.concept_code_1 AND f.concept_class_id = 'Dose Form'
  LEFT JOIN rel_to_name b
         ON c.drug_concept_code = b.concept_code_1 AND b.concept_class_id = 'Brand Name'
  LEFT JOIN rel_to_name s
         ON c.drug_concept_code = s.concept_code_1 AND s.concept_class_id = 'Supplier'
  LEFT JOIN ds_stage ds ON c.drug_concept_code = ds.drug_concept_code;

MERGE INTO drug_concept_stage a
USING
(SELECT * FROM new_name) n ON (n.drug_concept_code = a.concept_code)
WHEN MATCHED THEN UPDATE
  SET a.concept_name = SUBSTR(n.CONCEPT_NAME,1,255);

COMMIT;

--up to rxfix
DELETE drug_concept_stage
WHERE concept_code IN (SELECT pack_concept_code FROM pc_stage);

DELETE drug_concept_stage
WHERE concept_code IN (SELECT drug_concept_code FROM pc_stage);

DELETE internal_relationship_stage
WHERE concept_code_1 IN (SELECT pack_concept_code FROM pc_stage);

DELETE internal_relationship_stage
WHERE concept_code_1 IN (SELECT drug_concept_code FROM pc_stage);

DELETE ds_stage
WHERE drug_concept_code IN (SELECT drug_concept_code FROM pc_stage);
COMMIT;

TRUNCATE TABLE pc_stage;

DELETE drug_concept_stage
WHERE concept_code IN (SELECT drug_concept_code
                       FROM ds_stage WHERE numerator_unit IN ('DH','C','CH','D','TM','X','XMK') AND denominator_value IS NOT NULL);

DELETE internal_relationship_stage
WHERE concept_code_1 IN (SELECT drug_concept_code
                         FROM ds_stage WHERE numerator_unit IN ('DH','C','CH','D','TM','X','XMK') AND denominator_value IS NOT NULL);

DELETE ds_stage
WHERE numerator_unit IN ('DH','C','CH','D','TM','X','XMK')
AND   denominator_value IS NOT NULL;

COMMIT;


--fixes due to new RxE version
update relationship_to_concept
set concept_id_2 = 19020153
where concept_id_2 = 43563645
;
update relationship_to_concept
set concept_id_2 = 19012555
where concept_id_2 = 40799676;

delete drug_concept_stage where concept_code not in (select concept_code_1 from relationship_to_concept) and concept_class_id = 'Brand Name';
