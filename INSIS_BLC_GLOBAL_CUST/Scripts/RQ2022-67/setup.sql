-- LOOKUPS
--TRANSACTION_TYPES
  INSERT INTO insis_gen_blc_v10.blc_lookups (org_id,lookup_set,lookup_code,from_date,to_date,meaning,description,enabled,code_type,tag_0,tag_1,tag_2,tag_3,tag_4,tag_5,tag_6,tag_7,tag_8,tag_9) 
  VALUES (0,'TRANSACTION_TYPES','MANUAL_PREMIUM_ADJ',to_date('01-01-1900','DD-MM-RRRR'),null,'Manual Premium Adjustment','Manual Premium Adjustment','Y','S','B','FIXING','Y','PREMIUM','GWP',null,null,'PROFORMA','N',null);
-- DOC_OPEN_REASONS
  INSERT INTO insis_gen_blc_v10.blc_lookups (ORG_ID,LOOKUP_SET,LOOKUP_CODE,FROM_DATE,TO_DATE,MEANING,DESCRIPTION,ENABLED,CODE_TYPE,TAG_0,TAG_1,TAG_2,TAG_3,TAG_4,TAG_5,TAG_6,TAG_7,TAG_8,TAG_9) 
  VALUES (0,'DOC_OPEN_REASONS','CHANGE_DUE_DATE',to_date('01-01-1900','DD-MM-RRRR'),null,'Change document due date',null,'Y','S','V','DUE_DATE',null,null,'N','PROFORMA',null,null,null,null);
  INSERT INTO insis_gen_blc_v10.blc_lookups (ORG_ID,LOOKUP_SET,LOOKUP_CODE,FROM_DATE,TO_DATE,MEANING,DESCRIPTION,ENABLED,CODE_TYPE,TAG_0,TAG_1,TAG_2,TAG_3,TAG_4,TAG_5,TAG_6,TAG_7,TAG_8,TAG_9)
  VALUES (0,'DOC_OPEN_REASONS','OPEN_DOCUMENT',to_date('01-01-1900','DD-MM-RRRR'),null,'Open document',null,'Y','S','V',null,null,null,'Y','PROFORMA',null,null,null,null);

-- Accounting rule
UPDATE blc_sla_acc_rules SET where_clause = 'bt_transaction_type IN ( ''PREMIUM'', ''MANUAL_PREMIUM_ADJ'' )'
WHERE acc_rule_id = 1000;

-- Setting
  INSERT INTO insis_gen_blc_v10.blc_settings (SETTING,DESCRIPTION,DATA_TYPE_ID,DEFAULT_NUMBER,DEFAULT_DATE,DEFAULT_TEXT,LOOKUP_VALUE_ID,SYSTEM,FOR_BILLING,FOR_COLLECTION,FOR_PAYMENT)
  VALUES ('CustManualTrxMaxAmount','Custom setting for maximum value when the user registers a new transaction',2,0,null,null,null,'C','Y','N','N');

-- Values
  INSERT INTO insis_gen_blc_v10.blc_values (setting,org_id,from_date,to_date,number_value,date_value,text_value,lookup_id,private,notes) 
  VALUES ('CustManualTrxMaxAmount',0,to_date('01-01-1900','DD-MM-RRRR'),null,0.05,null,null,null,'N',null);
  
COMMIT;