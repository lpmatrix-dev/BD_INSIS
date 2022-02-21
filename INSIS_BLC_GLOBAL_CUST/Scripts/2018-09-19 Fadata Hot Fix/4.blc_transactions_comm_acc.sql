CREATE OR REPLACE FORCE VIEW "INSIS_GEN_BLC_V10"."BLC_TRANSACTIONS_COMM_ACC" ("BT_TRANSACTION_ID", "BT_TRANSACTION_CLASS", "BT_TRANSACTION_TYPE", "BT_TRANSACTION_DATE", "BT_GL_DATE", "BT_CURRENCY", "BT_AMOUNT", "BT_ASSESSED_VALUE", "BT_RATE", "BT_RATE_DATE", "BT_RATE_TYPE", "BT_VARIANCE", "BT_FC_CURRENCY", "BT_FC_AMOUNT", "BT_FC_VARIANCE", "BT_ITEM_NAME", "BT_NOTES", "BT_DUE_DATE", "BT_GRACE", "BT_GRACE_EXTRA", "BT_LEGAL_ENTITY", "BT_ORG_ID", "BT_ACCOUNT_ID", "BT_ITEM_ID", "BT_DOC_ID", "BT_APPLICATION_ID", "BT_TAX_ID", "BT_PARENT_TRX_ID", "BT_BILLING_RUN_ID", "BT_STATUS", "BT_OPEN_BALANCE", "BT_PAID_STATUS", "BT_CHARGE_TO", "BT_REF_DOC_ID", "BT_CREATED_ON", "BT_CREATED_BY", "BT_UPDATED_ON", "BT_UPDATED_BY", "BT_ATTRIB_0", "BT_ATTRIB_1", "BT_ATTRIB_2", "BT_ATTRIB_3", "BT_ATTRIB_4", "BT_ATTRIB_5", "BT_ATTRIB_6", "BT_ATTRIB_7", "BT_ATTRIB_8", "BT_ATTRIB_9", "ACC_PARTY_ROLE_ID", "ACC_PROFILE", "ACC_PARTY", "ACC_BILL_TO_SITE", "ACC_REFERENCE", "ACC_NOTES", "ACC_LAST_DATE", "ACC_NEXT_DATE", "ACC_BILLING_SITE_ID", "ACC_COLLECTION_SITE_ID", "ACC_PAYMENT_SITE_ID", "ACC_BILL_METHOD_ID", "ACC_BILL_CYCLE_ID", "ACC_BILL_PERIOD", "ACC_BILL_HORIZON", "ACC_MIN_RETAIN_DAYS", "ACC_MAX_RETAIN_DAYS", "ACC_DUE_PERIOD", "ACC_GRACE_PERIOD", "ACC_MIN_BILL_AMOUNT", "ACC_MIN_REFUND_AMOUNT", "ACC_MIN_AMOUNT_ACTION_ID", "ACC_RECEIPT_METHOD_ID", "ACC_COLLECTION_SET_ID", "ACC_INTEREST_METHOD", "ACC_PAYMENT_METHOD_ID", "ACC_PAY_HORIZON", "ACC_NET_HORIZON", "ACC_PAY_GROUP_ID", "ACC_BASE_PROFILE_ID", "ACC_STATUS", "ACC_ATTRIB_0", "ACC_ATTRIB_1", "ACC_ATTRIB_2", "ACC_ATTRIB_3", "ACC_ATTRIB_4", "ACC_ATTRIB_5", "ACC_ATTRIB_6", "ACC_ATTRIB_7", "ACC_ATTRIB_8", "ACC_ATTRIB_9", "BI_LEGAL_ENTITY_ID", "BI_SOURCE", "BI_AGREEMENT", "BI_COMPONENT", "BI_DETAIL", "BI_ITEM_TYPE", "BI_PARTY", "BI_BILL_TO_SITE", "BI_INSURANCE_TYPE", "BI_AGENT", "BI_OFFICE", "BI_RETAINED", "BI_PRIORITY", "BI_BILL_CURRENCY", "BI_BILL_MODE", "BI_ITEM_NAME", "BI_STATUS", "BI_ATTRIB_0", "BI_ATTRIB_1", "BI_ATTRIB_2", "BI_ATTRIB_3", "BI_ATTRIB_4", "BI_ATTRIB_5", "BI_ATTRIB_6", "BI_ATTRIB_7", "BI_ATTRIB_8", "BI_ATTRIB_9", "DOC_TYPE", "DOC_NUMBER", "DOC_ISSUE_DATE", "DOC_AMOUNT", "TECH_BRANCH", "RI_FAC_FLAG", "DOC_START_DATE", "DOC_END_DATE", "REF_DOC_NUMBER", "POLICY_START_DATE", "POLICY_END_DATE", "POL_END_FLAG", "PAY_WAY", "OFFICE_GL_NO", "POL_END_PARTY_NAME", "POL_END_PARTY", "DOC_PREM_AMOUNT", "DOC_DUE_DATE", "PROTOCOL_NUMBER", "SALES_CHANNEL", "INTRMD_TYPE", "VAT_FLAG", "BUS_UNIT", "TECH_BR_RR", "POLICY_CLASS", "ACC_PRIORITY", "COMM_TYPE", "COMM_AMOUNT", "COMM_PERCENT", "AGENT_ID", "AGENT_PARTY", "AGENT_ACCOUNT_NUMBER", "BANK_FLAG", "POLICY_NO") AS 
  SELECT bt.transaction_id  bt_transaction_id,
    bt.transaction_class  bt_transaction_class,
    bt.transaction_type   bt_transaction_type,
    bt.transaction_date   bt_transaction_date,
    bt.gl_date            bt_gl_date,
    bt.currency           bt_currency,
    bt.amount             bt_amount,
    bt.assessed_value     bt_assessed_value,
    bt.rate               bt_rate,
    bt.rate_date          bt_rate_date,
    bt.rate_type          bt_rate_type,
    bt.variance           bt_variance,
    bt.fc_currency        bt_fc_currency,
    bt.fc_amount          bt_fc_amount,
    bt.fc_variance        bt_fc_variance,
    bt.item_name          bt_item_name,
    bt.notes              bt_notes,
    bt.due_date           bt_due_date,
    bt.grace              bt_grace,
    bt.grace_extra        bt_grace_extra,
    bt.legal_entity       bt_legal_entity, 
    bt.org_id             bt_org_id,
    bt.account_id         bt_account_id,
    bt.item_id            bt_item_id,
    bt.doc_id             bt_doc_id,
    bt.application_id     bt_application_id,
    bt.tax_id             bt_tax_id,
    bt.parent_trx_id      bt_parent_trx_id,
    bt.billing_run_id     bt_billing_run_id,
    bt.status             bt_status,
    bt.open_balance       bt_open_balance,
    bt.paid_status        bt_paid_status,
    bt.charge_to          bt_charge_to,
    bt.ref_doc_id         bt_ref_doc_id,
    bt.created_on         bt_created_on,
    bt.created_by         bt_created_by,
    bt.updated_on         bt_updated_on,
    bt.updated_by         bt_updated_by,
    bt.attrib_0           bt_attrib_0,
    bt.attrib_1           bt_attrib_1,
    bt.attrib_2           bt_attrib_2,
    bt.attrib_3           bt_attrib_3,
    bt.attrib_4           bt_attrib_4,
    bt.attrib_5           bt_attrib_5,
    bt.attrib_6           bt_attrib_6,
    bt.attrib_7           bt_attrib_7,
    bt.attrib_8           bt_attrib_8,
    bt.attrib_9           bt_attrib_9,
    ba.party_role_id      acc_party_role_id,
    ba.profile            acc_profile,
    ba.party              acc_party,
    ba.bill_to_site       acc_bill_to_site,
    ba.reference          acc_reference,
    ba.notes              acc_notes, 
    ba.last_date          acc_last_date,
    ba.next_date          acc_next_date,
    ba.billing_site_id    acc_billing_site_id,
    ba.collection_site_id acc_collection_site_id,
    ba.payment_site_id    acc_payment_site_id,
    ba.bill_method_id     acc_bill_method_id,
    ba.bill_cycle_id      acc_bill_cycle_id,
    ba.bill_period        acc_bill_period,
    ba.bill_horizon       acc_bill_horizon,
    ba.min_retain_days    acc_min_retain_days,
    ba.max_retain_days    acc_max_retain_days,
    ba.due_period         acc_due_period,
    ba.grace_period       acc_grace_period,
    ba.min_bill_amount    acc_min_bill_amount,
    ba.min_refund_amount  acc_min_refund_amount,
    ba.min_amount_action_id acc_min_amount_action_id,
    ba.receipt_method_id  acc_receipt_method_id,
    ba.collection_set_id  acc_collection_set_id,
    ba.interest_method    acc_interest_method,
    ba.payment_method_id  acc_payment_method_id,
    ba.pay_horizon        acc_pay_horizon,
    ba.net_horizon        acc_net_horizon,
    ba.pay_group_id       acc_pay_group_id,
    ba.base_profile_id    acc_base_profile_id,
    ba.status             acc_status,
    ba.ATTRIB_0           acc_attrib_0,
    ba.ATTRIB_1           acc_attrib_1,
    ba.ATTRIB_2           acc_attrib_2,
    ba.ATTRIB_3           acc_attrib_3,
    ba.ATTRIB_4           acc_attrib_4,
    ba.ATTRIB_5           acc_attrib_5,
    ba.ATTRIB_6           acc_attrib_6,
    ba.ATTRIB_7           acc_attrib_7,
    ba.ATTRIB_8           acc_attrib_8,
    ba.ATTRIB_9           acc_attrib_9,
    bi.legal_entity_id    bi_legal_entity_id,
    bi.source             bi_source,
    bi.agreement          bi_agreement,
    bi.component          bi_component,
    bi.detail             bi_detail,
    bi.item_type          bi_item_type,
    bi.party              bi_party, 
    bi.bill_to_site       bi_bill_to_site, 
    bi.insurance_type     bi_insurance_type, 
    bi.agent              bi_agent,
    bi.office             bi_office,
    bi.retained           bi_retained,   
    bi.priority           bi_priority,
    bi.bill_currency      bi_bill_currency,
    bi.bill_mode          bi_bill_mode,
    bi.item_name          bi_item_name,
    bi.status             bi_status,
    bi.attrib_0           bi_attrib_0,
    bi.attrib_1           bi_attrib_1,
    bi.attrib_2           bi_attrib_2,
    bi.attrib_3           bi_attrib_3,
    bi.attrib_4           bi_attrib_4,
    bi.attrib_5           bi_attrib_5,
    bi.attrib_6           bi_attrib_6,
    bi.attrib_7           bi_attrib_7,
    bi.attrib_8           bi_attrib_8,
    bi.attrib_9           bi_attrib_9,
    bl.lookup_code        doc_type,
    bd.doc_number         doc_number,
    bd.issue_date         doc_issue_date,
    bd.amount             doc_amount,
    pp.attr1              tech_branch,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_RI_Fac(pp.policy_id) RI_fac_flag,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_Start_Date(bd.doc_id) doc_start_date,
    (SELECT to_date(bi.attrib_4,'YYYY-MM-DD')
     FROM blc_installments bi
     WHERE bi.transaction_id = bt.transaction_id
     FETCH FIRST ROW ONLY) AS doc_start_date,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_End_Date(bd.doc_id) doc_end_date,
    (SELECT to_date(bi.attrib_5,'YYYY-MM-DD')
     FROM blc_installments bi
     WHERE bi.transaction_id = bt.transaction_id
     FETCH FIRST ROW ONLY) AS doc_end_date,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Ref_Doc_Number(bd.doc_id) ref_doc_number,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_Start_Date(bd.doc_id) policy_start_date,
    (SELECT trunc(pp.insr_begin)
     FROM blc_installments bi,
          policy pp
     WHERE bi.transaction_id = bt.transaction_id
     AND to_number(bi.policy) = pp.policy_id
     FETCH FIRST ROW ONLY) AS policy_start_date,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_End_Date(bd.doc_id) policy_end_date,
    (SELECT trunc(pp.insr_end)-1
     FROM blc_installments bi,
          policy pp
     WHERE bi.transaction_id = bt.transaction_id
     AND to_number(bi.policy) = pp.policy_id
     FETCH FIRST ROW ONLY) AS policy_end_date,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_End_Flag(pp.policy_id) pol_end_flag,
    blp.lookup_code       pay_way,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Office_Code(nvl(pp.attr4,pp.office_id)) office_gl_no,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_End_Party_Name(pp.policy_id) pol_end_party_name,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_End_Party(pp.policy_id) pol_end_party,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_Prem_Amount(bd.doc_id) doc_prem_amount,
    0                     doc_prem_amount,
    bd.due_date           doc_due_date,
    bd.doc_prefix         protocol_number,
    pp.attr3              sales_channel,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_Intrmd_Type(pp.policy_id) intrmd_type,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_VAT_Flag(bd.doc_id) vat_flag,
    'N'                   vat_flag,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Business_Unit(pp.attr3, pp.insr_type) bus_unit,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Tech_Brnch_RR(pp.attr1) tech_br_rr,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_Class(pp.policy_id) policy_class,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Prof_Priority(br.run_mode, br.bill_method_id) acc_priority,
    cc.comm_type,
    cc.comm_amount,
    cc.comm_percent,
    cc.agent_id,
    cc.agent_party,
    cc.account_number agent_account_number,
	cc.bank_flag, -- LPV-1166
    pp.policy_name    AS policy_no -- LPV-819
FROM blc_transactions bt, 
     blc_accounts ba, 
     blc_items bi,
     blc_documents bd,
     blc_lookups bl,
     blc_lookups blp,
     blc_run br,
     insis_gen_v10.policy_eng_policies pep,
     insis_gen_v10.policy pp,
     (SELECT sum(round(bc.amount,2)) comm_amount, 
             sum(bc.attrn1) comm_percent, 
             bc.recipient_id agent_id, 
             bl.attrib_0 comm_type, 
             pa.man_id agent_party,
             lpad(pa.account_number,2,'0') account_number,
             bc.policy_id,
             bc.blc_prem_id,
			       bc.attr2 bank_flag -- LPV-1166
      FROM insis_gen_v10.blc_commission bc,
           insis_people_v10.p_agents pa,
           blc_lookups bl
      WHERE bc.recipient_id = pa.agent_id
      AND bc.comm_type = bl.lookup_code
      AND bl.lookup_set = 'CUST_LPV_COMM_TYPES'
      AND bl.org_id = 0
      AND bl.attrib_0 IS NOT NULL
      AND bc.amount <> 0
      GROUP BY bc.recipient_id, bl.attrib_0, pa.man_id, pa.account_number, bc.policy_id, bc.blc_prem_id, bc.attr2) cc
WHERE bt.account_id = ba.account_id
AND bt.item_id = bi.item_id
AND bt.doc_id = bd.doc_id
AND bd.doc_type_id = bl.lookup_id
AND bd.pay_way_id = blp.lookup_id (+)
AND bi.attrib_7 = 'CLIENT_GROUP'
AND to_number(bi.component) = pep.policy_id
AND pep.master_policy_id = pp.policy_id
AND to_number(bi.component) = cc.policy_id
AND to_number(blc_appl_util_pkg.Get_Trx_External_Id(bt.transaction_id)) = cc.blc_prem_id
AND bt.billing_run_id = br.run_id
UNION ALL
SELECT bt.transaction_id  bt_transaction_id,
    bt.transaction_class  bt_transaction_class,
    bt.transaction_type   bt_transaction_type,
    bt.transaction_date   bt_transaction_date,
    bt.gl_date            bt_gl_date,
    bt.currency           bt_currency,
    bt.amount             bt_amount,
    bt.assessed_value     bt_assessed_value,
    bt.rate               bt_rate,
    bt.rate_date          bt_rate_date,
    bt.rate_type          bt_rate_type,
    bt.variance           bt_variance,
    bt.fc_currency        bt_fc_currency,
    bt.fc_amount          bt_fc_amount,
    bt.fc_variance        bt_fc_variance,
    bt.item_name          bt_item_name,
    bt.notes              bt_notes,
    bt.due_date           bt_due_date,
    bt.grace              bt_grace,
    bt.grace_extra        bt_grace_extra,
    bt.legal_entity       bt_legal_entity, 
    bt.org_id             bt_org_id,
    bt.account_id         bt_account_id,
    bt.item_id            bt_item_id,
    bt.doc_id             bt_doc_id,
    bt.application_id     bt_application_id,
    bt.tax_id             bt_tax_id,
    bt.parent_trx_id      bt_parent_trx_id,
    bt.billing_run_id     bt_billing_run_id,
    bt.status             bt_status,
    bt.open_balance       bt_open_balance,
    bt.paid_status        bt_paid_status,
    bt.charge_to          bt_charge_to,
    bt.ref_doc_id         bt_ref_doc_id,
    bt.created_on         bt_created_on,
    bt.created_by         bt_created_by,
    bt.updated_on         bt_updated_on,
    bt.updated_by         bt_updated_by,
    bt.attrib_0           bt_attrib_0,
    bt.attrib_1           bt_attrib_1,
    bt.attrib_2           bt_attrib_2,
    bt.attrib_3           bt_attrib_3,
    bt.attrib_4           bt_attrib_4,
    bt.attrib_5           bt_attrib_5,
    bt.attrib_6           bt_attrib_6,
    bt.attrib_7           bt_attrib_7,
    bt.attrib_8           bt_attrib_8,
    bt.attrib_9           bt_attrib_9,
    ba.party_role_id      acc_party_role_id,
    ba.profile            acc_profile,
    ba.party              acc_party,
    ba.bill_to_site       acc_bill_to_site,
    ba.reference          acc_reference,
    ba.notes              acc_notes, 
    ba.last_date          acc_last_date,
    ba.next_date          acc_next_date,
    ba.billing_site_id    acc_billing_site_id,
    ba.collection_site_id acc_collection_site_id,
    ba.payment_site_id    acc_payment_site_id,
    ba.bill_method_id     acc_bill_method_id,
    ba.bill_cycle_id      acc_bill_cycle_id,
    ba.bill_period        acc_bill_period,
    ba.bill_horizon       acc_bill_horizon,
    ba.min_retain_days    acc_min_retain_days,
    ba.max_retain_days    acc_max_retain_days,
    ba.due_period         acc_due_period,
    ba.grace_period       acc_grace_period,
    ba.min_bill_amount    acc_min_bill_amount,
    ba.min_refund_amount  acc_min_refund_amount,
    ba.min_amount_action_id acc_min_amount_action_id,
    ba.receipt_method_id  acc_receipt_method_id,
    ba.collection_set_id  acc_collection_set_id,
    ba.interest_method    acc_interest_method,
    ba.payment_method_id  acc_payment_method_id,
    ba.pay_horizon        acc_pay_horizon,
    ba.net_horizon        acc_net_horizon,
    ba.pay_group_id       acc_pay_group_id,
    ba.base_profile_id    acc_base_profile_id,
    ba.status             acc_status,
    ba.ATTRIB_0           acc_attrib_0,
    ba.ATTRIB_1           acc_attrib_1,
    ba.ATTRIB_2           acc_attrib_2,
    ba.ATTRIB_3           acc_attrib_3,
    ba.ATTRIB_4           acc_attrib_4,
    ba.ATTRIB_5           acc_attrib_5,
    ba.ATTRIB_6           acc_attrib_6,
    ba.ATTRIB_7           acc_attrib_7,
    ba.ATTRIB_8           acc_attrib_8,
    ba.ATTRIB_9           acc_attrib_9,
    bi.legal_entity_id    bi_legal_entity_id,
    bi.source             bi_source,
    bi.agreement          bi_agreement,
    bi.component          bi_component,
    bi.detail             bi_detail,
    bi.item_type          bi_item_type,
    bi.party              bi_party, 
    bi.bill_to_site       bi_bill_to_site, 
    bi.insurance_type     bi_insurance_type, 
    bi.agent              bi_agent,
    bi.office             bi_office,
    bi.retained           bi_retained,   
    bi.priority           bi_priority,
    bi.bill_currency      bi_bill_currency,
    bi.bill_mode          bi_bill_mode,
    bi.item_name          bi_item_name,
    bi.status             bi_status,
    bi.attrib_0           bi_attrib_0,
    bi.attrib_1           bi_attrib_1,
    bi.attrib_2           bi_attrib_2,
    bi.attrib_3           bi_attrib_3,
    bi.attrib_4           bi_attrib_4,
    bi.attrib_5           bi_attrib_5,
    bi.attrib_6           bi_attrib_6,
    bi.attrib_7           bi_attrib_7,
    bi.attrib_8           bi_attrib_8,
    bi.attrib_9           bi_attrib_9,
    bl.lookup_code        doc_type,
    bd.doc_number         doc_number,
    bd.issue_date         doc_issue_date,
    bd.amount             doc_amount,
    pp.attr1              tech_branch,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_RI_Fac(pp.policy_id) RI_fac_flag,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_Start_Date(bd.doc_id) doc_start_date,
    (SELECT to_date(bi.attrib_4,'YYYY-MM-DD')
     FROM blc_installments bi
     WHERE bi.transaction_id = bt.transaction_id
     FETCH FIRST ROW ONLY) AS doc_start_date,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_End_Date(bd.doc_id) doc_end_date,
    (SELECT to_date(bi.attrib_5,'YYYY-MM-DD')
     FROM blc_installments bi
     WHERE bi.transaction_id = bt.transaction_id
     FETCH FIRST ROW ONLY) AS doc_end_date,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Ref_Doc_Number(bd.doc_id) ref_doc_number,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_Start_Date(bd.doc_id) policy_start_date,
    (SELECT trunc(pp.insr_begin)
     FROM blc_installments bi,
          policy pp
     WHERE bi.transaction_id = bt.transaction_id
     AND to_number(bi.policy) = pp.policy_id
     FETCH FIRST ROW ONLY) AS policy_start_date,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_End_Date(bd.doc_id) policy_end_date,
    (SELECT trunc(pp.insr_end)-1
     FROM blc_installments bi,
          policy pp
     WHERE bi.transaction_id = bt.transaction_id
     AND to_number(bi.policy) = pp.policy_id
     FETCH FIRST ROW ONLY) AS policy_end_date,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_End_Flag(pp.policy_id) pol_end_flag,
    blp.lookup_code       pay_way,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Office_Code(nvl(pp.attr4,pp.office_id)) office_gl_no,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_End_Party_Name(pp.policy_id) pol_end_party_name,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_End_Party(pp.policy_id) pol_end_party,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_Prem_Amount(bd.doc_id) doc_prem_amount,
    0                     doc_prem_amount,
    bd.due_date           doc_due_date,
    bd.doc_prefix         protocol_number,
    pp.attr3              sales_channel,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Pol_Intrmd_Type(pp.policy_id) intrmd_type,
    --insis_blc_global_cust.cust_acc_util_pkg.Get_Doc_VAT_Flag(bd.doc_id) vat_flag,
    'N'                   vat_flag,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Business_Unit(pp.attr3, pp.insr_type) bus_unit,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Tech_Brnch_RR(pp.attr1) tech_br_rr,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Policy_Class(pp.policy_id) policy_class,
    insis_blc_global_cust.cust_acc_util_pkg.Get_Prof_Priority(br.run_mode, br.bill_method_id) acc_priority,
    cc.comm_type,
    cc.comm_amount,
    cc.comm_percent,
    cc.agent_id,
    cc.agent_party,
    cc.account_number agent_account_number,
	  cc.bank_flag, -- LPV-1166
    pp.policy_name    AS policy_no -- LPV-819
FROM blc_transactions bt, 
     blc_accounts ba, 
     blc_items bi,
     blc_documents bd,
     blc_lookups bl,
     blc_lookups blp,
     blc_run br,
     insis_gen_v10.policy pp,
     (SELECT sum(round(bc.amount,2)) comm_amount, 
             sum(bc.attrn1) comm_percent, 
             bc.recipient_id agent_id, 
             bl.attrib_0 comm_type, 
             pa.man_id agent_party,
             lpad(pa.account_number,2,'0') account_number,
             bc.policy_id,
             bc.blc_prem_id,
			 bc.attr2 bank_flag -- LPV-1166
      FROM insis_gen_v10.blc_commission bc,
           insis_people_v10.p_agents pa,
           blc_lookups bl
      WHERE bc.recipient_id = pa.agent_id
      AND bc.comm_type = bl.lookup_code
      AND bl.lookup_set = 'CUST_LPV_COMM_TYPES'
      AND bl.org_id = 0
      AND bl.attrib_0 IS NOT NULL
      AND bc.amount <> 0
      GROUP BY bc.recipient_id, bl.attrib_0, pa.man_id, pa.account_number, bc.policy_id, bc.blc_prem_id, bc.attr2) cc
WHERE bt.account_id = ba.account_id
AND bt.item_id = bi.item_id
AND bt.doc_id = bd.doc_id
AND bd.doc_type_id = bl.lookup_id
AND bd.pay_way_id = blp.lookup_id (+)
AND nvl(bi.attrib_7,'-999') <> 'CLIENT_GROUP'
AND to_number(bi.component) = pp.policy_id
AND to_number(bi.component) = cc.policy_id
AND to_number(blc_appl_util_pkg.Get_Trx_External_Id(bt.transaction_id)) = cc.blc_prem_id
AND bt.billing_run_id = br.run_id;
