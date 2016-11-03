--update ds_stage changing % to mg/ml, mg/g, etc.
--simple, when we have denominator_unit so we can define numerator based on denominator_unit
update ds_stage 
set numerator_value =  DENOMINATOR_VALUE * NUMERATOR_VALUE * 10, 
lower (numerator_unit) = 'mg'
where numerator_unit = '%' and lower (DENOMINATOR_UNIT) in ('ml', 'gram', 'g')
;
update ds_stage 
set numerator_value =  DENOMINATOR_VALUE * NUMERATOR_VALUE * 0.01, 
lower (numerator_unit) = 'mg'
where numerator_unit = '%' and lower (DENOMINATOR_UNIT) in ('mg')
;
update ds_stage 
set numerator_value =  DENOMINATOR_VALUE * NUMERATOR_VALUE * 10, 
lower (numerator_unit) = 'g'
where numerator_unit = '%' and lower (DENOMINATOR_UNIT) in ('l')
;