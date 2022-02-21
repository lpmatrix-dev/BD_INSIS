CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.SRV_CUST_PAS_BO IS

--------------------------------------------------------------------------------
-- Name: srv_cust_pas_bo.PreProcessItem
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  16.08.2018  creation
--
-- Purpose: Populate item attrubutes before process item parameters passed
-- during policy payment plan transfer
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes
--                                  in context(if needed)
--
-- Output parameters:
--     pio_OutContext  SrvContext   Specifies structure for
--                                  passing back the parameters(if needed);
--     pio_Err          SrvErr      Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'TRANSFER_GROUP_INSTALLMENTS'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreProcessItem( pi_Context     IN     SrvContext,
                          pio_OutContext IN OUT SrvContext,
                          pio_Err        IN OUT srvErr)
IS
    l_SrvErrMsg SrvErrMsg;
BEGIN
    cust_pas_transfer_pkg.Pre_Process_Item( pio_Err => pio_Err );
EXCEPTION
  WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pas_bo.PreProcessItem', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END PreProcessItem;

--------------------------------------------------------------------------------
-- Name: srv_cust_pas_bo.PreProcessInstallments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  16.08.2018  creation
--
-- Purpose: Populate installments attributes before process installments
-- collection passed during policy payment plan transfer
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes
--                                  in context(if needed)
--
-- Output parameters:
--     pio_OutContext  SrvContext   Specifies structure for
--                                  passing back the parameters(if needed);
--     pio_Err          SrvErr      Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'TRANSFER_GROUP_INSTALLMENTS'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreProcessInstallments( pi_Context     IN     SrvContext,
                                  pio_OutContext IN OUT SrvContext,
                                  pio_Err        IN OUT srvErr)
IS
    l_SrvErrMsg SrvErrMsg;
BEGIN
    cust_pas_transfer_pkg.Pre_Process_Installments( pio_Err => pio_Err );
EXCEPTION
  WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pas_bo.PreProcessInstallments', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END PreProcessInstallments;

--------------------------------------------------------------------------------
-- Name: srv_cust_pas_bo.CompensateInstallments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  05.04.2017  creation - RQ1000010702
--
-- Purpose: Process installments' compensations by given item
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in context(if needed)
--
-- Output parameters:
--     pio_OutContext  SrvContext   Specifies structure for
--                                  passing back the parameters(if needed);
--     pio_Err          SrvErr      Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'TRANSFER_GROUP_INSTALLMENTS'.
--
-- Note: N/A
-------------------------------------------------------------------------------
PROCEDURE CompensateInstallments( pi_Context     IN     SrvContext,
                                  pio_OutContext IN OUT SrvContext,
                                  pio_Err        IN OUT srvErr)
IS
    l_SrvErrMsg SrvErrMsg;
BEGIN
    cust_pas_transfer_pkg.Compensate_Item_Installments( pio_Err => pio_Err );
EXCEPTION
  WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pas_bo.CompensateInstallments', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END CompensateInstallments;

--------------------------------------------------------------------------------
-- Name: srv_cust_pas_bo.AutoApproveDocument
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.04.2015  creation - rq 1000009721
--
-- Purpose:  Service executes procedure auto approve document for given doc_id
-- depend on rule result as step of compelete document event. Document status
-- have to be Validated
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - DOC_ID             NUMBER    Document Id;
--      - ACTION_NOTES       VARCHAR2  Action notes;
--      - DOC_CLASS          VARCHAR2  Document class;
--      - DOC_TYPE           VARCHAR2  Document stype;
--      - TRX_TYPE           VARCHAR2  Transaction type;
--      - DOC_POSTPROCESS    VARCHAR2  Installment postprocess;
--      - DOC_RUN_ID         NUMBER    Billing run id;
--      - NORM_INTERPRET     VARCHAR2  Norm interpretation setting;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--      - DOC_STATUS         VARCHAR2  Document status;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--      - DOC_STATUS         VARCHAR2  Document status;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'COMPLETE_BLC_DOCUMENT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE AutoApproveDocument ( pi_Context IN SrvContext,
                                pio_OutContext IN OUT SrvContext,
                                pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_doc_id           blc_documents.doc_id%type;
    l_action_notes     VARCHAR2(4000);
    l_procedure_result VARCHAR2(30);
    l_doc_status       blc_documents.status%type;
    l_doc_class        blc_documents.doc_class%type;
    l_doc_type         blc_lookups.lookup_code%type;
    l_trx_type         blc_lookups.lookup_code%type;
    l_doc_postprocess  blc_lookups.lookup_code%type;
    l_doc_run_id       blc_documents.run_id%type;
    l_norm_interpret   blc_lookups.lookup_code%type;
  BEGIN
      -- Getting data from context
      l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
      l_action_notes := srv_prm_process.Get_Action_Notes( pi_Context );
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      l_doc_status := srv_prm_process.Get_Doc_Status( pi_Context );
      l_doc_class := srv_prm_process.Get_Doc_Class( pi_Context);
      l_doc_type := srv_prm_process.Get_Doc_Type( pi_Context);
      l_trx_type := srv_prm_process.Get_Trx_Type( pi_Context);
      l_doc_postprocess := srv_prm_process.Get_Doc_Postprocess( pi_Context);
      l_doc_run_id := srv_prm_process.Get_Doc_Run_Id( pi_Context);
      l_norm_interpret := srv_prm_process.Get_Norm_Interpret( pi_Context);

      cust_billing_pkg.Auto_Approve_Document
                     ( pi_doc_id             => l_doc_id,
                       pi_action_notes       => l_action_notes,
                       pi_doc_class          => l_doc_class,
                       pi_doc_type           => l_doc_type,
                       pi_trx_type           => l_trx_type,
                       pi_postprocess        => l_doc_postprocess,
                       pi_run_id             => l_doc_run_id,
                       pi_norm_interpret     => l_norm_interpret,
                       pio_procedure_result  => l_procedure_result,
                       pio_doc_status        => l_doc_status,
                       pio_Err               => pio_Err);

      pio_OutContext := pi_Context;
      srv_prm_process.Set_Action_Notes( pio_OutContext, NULL );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );
      srv_prm_process.Set_Doc_Status( pio_OutContext, l_doc_status );
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pas_bo.AutoApproveDocument', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END AutoApproveDocument;

--------------------------------------------------------------------------------
-- Name: srv_cust_pas_bo.CreateInstallment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  12.01.2020 - copy from core and add check to not create
--                          installment with zero amount
--                          LPV-2514
--
-- Purpose:  Service generates a record for an installment in Billing module
-- (inserts a row into BLC_INSTALLMENTS table based on data in attributes of input
-- parameter pi_Context)
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--                                  - ITEM_ID - unique identifier of billing item
--                                    (required)
--                                  - ACCOUNT_ID - unique identifier of account
--                                    (required)
--                                  - DATE - installment date (due date)
--                                     (required)
--                                  - CURRENCY - installment currency
--                                    chosen from predefined nomenclature
--                                     (required)
--                                  - AMOUNT - installment amount
--                                     (required)
--                                  - ANNIVERSARY - consequtive year number of
--                                    the agreement lifecycle
--                                  - POSTPROCESS - postprocess speciality
--                                    'NORM' - normal
--                                    'FREE' - full amount has to be written-off
--                                    immediatelly after transaction is created
--                                  - REC_RATE_DATE - date of the revenue/expense
--                                    defaulted with DATE if empty
--                                  - POLICY_OFFICE - office Id when the policy
--                                    is issued
--                                    defaulted with ACTIVITY_OFFICE if empty
--                                  - ACTIVITY_OFFICE - office Id when the
--                                    activity is done (required)
--                                  - INSURANCE_TYPE - insurance type
--                                  - POLICY - policy Id
--                                  - ANNEX - annex Id
--                                  - LOB - line of business
--                                  - FRACTION_TYPE - fraction type
--                                  - AGENT - agent Id
--                                  - CLAIM - claim_Id
--                                  - CLAIM_REQUEST - claim request Id
--                                  - TREATY - treaty Id
--                                  - ADJUSTMENT - adjustment Id
--                                  - TYPE - installment type
--                                    chosen from predefined nomenclature
--                                    (required)
--                                  - COMMAND - procedure for installment
--                                    distribution
--                                    'STD' -  non distributed
--                                    'UNPAID' - should be distributed between
--                                     non paid installments
--                                    'ONTIME' - should be distributed by time
--                                    'UNIFORM' - should be distributed on
--                                     pieces specified in parameter pieces
--                                     between isnatllment date and end date
--                                     specified in parameter end date
--                                  - PIECES - count of installments for
--                                    'UNIFORM' ditribution
--                                  - END_DATE - end date for distribution
--                                    procedure
--                                  - RUN_ID  - mark installment with already
--                                    created incomplete billing_run
--                                  - ATTRIB_0 - additional information
--                                  - ATTRIB_1 - additional information
--                                  - ATTRIB_2 - additional information
--                                  - ATTRIB_3 - additional information
--                                  - ATTRIB_4 - additional information
--                                  - ATTRIB_5 - additional information
--                                  - ATTRIB_6 - additional information
--                                  - ATTRIB_7 - additional information
--                                  - ATTRIB_8 - additional information
--                                  - ATTRIB_9 - additional information
--                                  - EXTERNAL_ID - insurance system reference
--                                  - BATCH - claims batch
--                                  - SPLIT_FLAG - split flag Y/N
--                                  - NOTES - notes
--                                  - SEQUENCE_ORDER - sequence order
--                                    allowed values are, default is 'S'
--                                    'F' - First
--                                    'I' - Intermediate
--                                    'L' - Last
--                                    'S' - Single
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions:
--    1) In case that required attributes for creation of an installment are
--    not set as attributes of input parameter pi_Context or have values NULL
--    2) In case that installment type (TYPE) is not found as value from
--    predefined nomenclature (lookup set INSTALLMENT_TYPES)
--    3) In case that currency (CURRENCY) is not found as value from
--    predefined nomenclature (lookup set CURRENCIES)
--
-- Dependences: Service is associated with event 'CREATE_BLC_INSTALLMENT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE CreateInstallment ( pi_Context IN SrvContext,
                              pio_OutContext IN OUT SrvContext,
                              pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_item_id          blc_installments.item_id%type;
    l_account_id       blc_installments.account_id%type;
    l_date             blc_installments.installment_date%type;
    l_currency         blc_installments.currency%type;
    l_amount           blc_installments.amount%type;
    l_anniversary      blc_installments.anniversary%type;
    l_postprocess      blc_installments.postprocess%type;
    l_rec_rate_date    blc_installments.rec_rate_date%type;
    l_policy_office    blc_installments.policy_office%type;
    l_activity_office  blc_installments.activity_office%type;
    l_insurance_type   blc_installments.insurance_type%type;
    l_policy           blc_installments.policy%type;
    l_annex            blc_installments.annex%type;
    l_lob              blc_installments.lob%type;
    l_fraction_type    blc_installments.fraction_type%type;
    l_agent            blc_installments.agent%type;
    l_claim            blc_installments.claim%type;
    l_claim_request    blc_installments.claim_request%type;
    l_treaty           blc_installments.treaty%type;
    l_adjustment       blc_installments.adjustment%type;
    l_type             blc_installments.installment_type%type;
    l_command          blc_installments.command%type;
    l_pieces           NUMBER;
    l_end_date         DATE;
    l_run_id           blc_installments.billing_run_id%type;
    l_attrib_0         blc_installments.attrib_0%type;
    l_attrib_1         blc_installments.attrib_1%type;
    l_attrib_2         blc_installments.attrib_2%type;
    l_attrib_3         blc_installments.attrib_3%type;
    l_attrib_4         blc_installments.attrib_4%type;
    l_attrib_5         blc_installments.attrib_5%type;
    l_attrib_6         blc_installments.attrib_6%type;
    l_attrib_7         blc_installments.attrib_7%type;
    l_attrib_8         blc_installments.attrib_8%type;
    l_attrib_9         blc_installments.attrib_9%type;
    l_external_id      blc_installments.external_id%type;
    l_batch            blc_installments.batch%type;
    l_split_flag       blc_installments.split_flag%type;
    l_notes            blc_installments.notes%type;
    l_sequence_order   blc_installments.sequence_order%type;
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'ITEM_ID', l_item_id );
      srv_context.GetContextAttrNumber( pi_Context, 'ACCOUNT_ID', l_account_id );
      srv_context.GetContextAttrDate( pi_Context, 'DATE', l_date );
      srv_context.GetContextAttrChar( pi_Context, 'CURRENCY', l_currency );
      srv_context.GetContextAttrNumber( pi_Context, 'AMOUNT', l_amount );
      srv_context.GetContextAttrNumber( pi_Context, 'ANNIVERSARY', l_anniversary );
      srv_context.GetContextAttrChar( pi_Context, 'POSTPROCESS', l_postprocess );
      srv_context.GetContextAttrDate( pi_Context, 'REC_RATE_DATE', l_rec_rate_date );
      srv_context.GetContextAttrChar( pi_Context, 'POLICY_OFFICE', l_policy_office);
      srv_context.GetContextAttrChar( pi_Context, 'ACTIVITY_OFFICE', l_activity_office);
      srv_context.GetContextAttrChar( pi_Context, 'INSURANCE_TYPE', l_insurance_type);
      srv_context.GetContextAttrChar( pi_Context, 'POLICY', l_policy );
      srv_context.GetContextAttrChar( pi_Context, 'ANNEX', l_annex );
      srv_context.GetContextAttrChar( pi_Context, 'LOB', l_lob );
      srv_context.GetContextAttrChar( pi_Context, 'FRACTION_TYPE', l_fraction_type );
      srv_context.GetContextAttrChar( pi_Context, 'AGENT', l_agent );
      srv_context.GetContextAttrChar( pi_Context, 'CLAIM', l_claim );
      srv_context.GetContextAttrChar( pi_Context, 'CLAIM_REQUEST', l_claim_request );
      srv_context.GetContextAttrChar( pi_Context, 'TREATY', l_treaty );
      srv_context.GetContextAttrChar( pi_Context, 'ADJUSTMENT', l_adjustment );
      srv_context.GetContextAttrChar( pi_Context, 'TYPE', l_type );
      srv_context.GetContextAttrChar( pi_Context, 'COMMAND', l_command );
      srv_context.GetContextAttrNumber( pi_Context, 'PIECES', l_pieces );
      srv_context.GetContextAttrDate( pi_Context, 'END_DATE', l_end_date );
      srv_context.GetContextAttrNumber( pi_Context, 'RUN_ID', l_run_id );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_0', l_attrib_0 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_1', l_attrib_1 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_2', l_attrib_2 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_3', l_attrib_3 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_4', l_attrib_4 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_5', l_attrib_5 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_6', l_attrib_6 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_7', l_attrib_7 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_8', l_attrib_8 );
      srv_context.GetContextAttrChar( pi_Context, 'ATTRIB_9', l_attrib_9 );
      srv_context.GetContextAttrChar( pi_Context, 'EXTERNAL_ID', l_external_id );
      srv_context.GetContextAttrChar( pi_Context, 'BATCH', l_batch );
      srv_context.GetContextAttrChar( pi_Context, 'NOTES', l_notes );
      srv_context.GetContextAttrChar( pi_Context, 'SEQUENCE_ORDER', l_sequence_order );

      IF pio_OutContext IS NOT NULL
      THEN
         FOR i IN pio_OutContext.first..pio_OutContext.last
         LOOP
            CASE pio_OutContext(i).AttrCode
            WHEN 'INST_ATTRIB_0' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_0', l_attrib_0);
            WHEN 'INST_ATTRIB_1' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_1', l_attrib_1);
            WHEN 'INST_ATTRIB_2' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_2', l_attrib_2);
            WHEN 'INST_ATTRIB_3' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_3', l_attrib_3);
            WHEN 'INST_ATTRIB_4' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_4', l_attrib_4);
            WHEN 'INST_ATTRIB_5' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_5', l_attrib_5);
            WHEN 'INST_ATTRIB_6' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_6', l_attrib_6);
            WHEN 'INST_ATTRIB_7' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_7', l_attrib_7);
            WHEN 'INST_ATTRIB_8' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_8', l_attrib_8);
            WHEN 'INST_ATTRIB_9' THEN srv_context.GetContextAttrChar (pio_OutContext, 'INST_ATTRIB_9', l_attrib_9);
            ELSE NULL;
            END CASE;
         END LOOP;
      END IF;

      IF NOT cust_pas_transfer_pkg.Create_Installment
                             (l_item_id,
                              l_account_id,
                              l_date,
                              l_currency,
                              l_amount,
                              l_anniversary,
                              l_postprocess,
                              l_rec_rate_date,
                              l_policy_office,
                              l_activity_office,
                              l_insurance_type,
                              l_policy,
                              l_annex,
                              l_lob,
                              l_fraction_type,
                              l_agent,
                              l_claim,
                              l_claim_request,
                              l_treaty,
                              l_adjustment,
                              l_type,
                              l_command,
                              l_pieces,
                              l_end_date,
                              l_run_id,
                              l_attrib_0,
                              l_attrib_1,
                              l_attrib_2,
                              l_attrib_3,
                              l_attrib_4,
                              l_attrib_5,
                              l_attrib_6,
                              l_attrib_7,
                              l_attrib_8,
                              l_attrib_9,
                              l_external_id,
                              l_batch,
                              l_split_flag,
                              l_notes,
                              l_sequence_order,
                              pio_Err)
      THEN
          NULL;
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pas_bo.CreateInstallment', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END CreateInstallment;
--
END srv_cust_pas_bo;
/


