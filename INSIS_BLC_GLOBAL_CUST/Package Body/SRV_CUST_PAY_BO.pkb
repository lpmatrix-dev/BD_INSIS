CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.SRV_CUST_PAY_BO
IS

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.PreValidatePmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.05.2017  creation
--
-- Purpose: Execute custom procedure of payment validation
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - PAYMENT_ID          NUMBER    Payment Id;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'VALIDATE_BLC_PMNT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreValidatePmnt( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_payment_id        blc_payments.payment_id%TYPE;
    l_action_notes      VARCHAR2(4000);
    l_procedure_result  VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_payment_id := srv_prm_process.Get_Payment_Id( pi_Context );
    l_action_notes := srv_prm_process.Get_Action_Notes( pi_Context );
    l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );

    cust_pay_util_pkg.Pre_Validate_Payment
                     ( pi_payment_id         => l_payment_id,
                       pio_action_notes      => l_action_notes,
                       pio_procedure_result  => l_procedure_result,
                       pio_Err               => pio_Err);
    --
    pio_OutContext := pi_Context;
    srv_prm_process.Set_Action_Notes( pio_OutContext, l_action_notes );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.PreValidatePmnt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END PreValidatePmnt;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.PreApplyReceipt
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.05.2017  creation
--
-- Purpose: Execute procedure of custom validation of apply receipt
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - PAYMENT_ID          NUMBER     Payment Id;
--      - REMITTANCE_IDS      VARCHAR2   List of remittance ids;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - DOC_ID              NUMBER     Document Id;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - DOC_ID              NUMBER     Document Id;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'APPLY_BLC_RECEIPT',
-- 'APPLY_BLC_REMITTANCES'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreApplyReceipt( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_payment_id        blc_payments.payment_id%TYPE;
    l_remt_ids          VARCHAR2(2000);
    l_doc_id            blc_documents.doc_id%TYPE;
BEGIN
    -- Getting data from context
    l_payment_id := srv_prm_process.Get_Payment_Id( pi_Context );
    l_remt_ids := srv_prm_process.Get_Remittance_Ids( pi_Context );
   
    cust_pay_util_pkg.Validate_Pmnt_Appl
                     ( pi_payment_id         => l_payment_id,
                       pi_remittance_ids     => l_remt_ids,
                       po_doc_id             => l_doc_id,
                       pio_Err               => pio_Err);
     
     pio_OutContext := pi_Context;                  
     srv_prm_process.Set_Doc_Id( pio_OutContext, l_doc_id );                  
                       
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.PreApplyReceipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END PreApplyReceipt;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.ApplyReceipt
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.05.2017  creation
--
-- Purpose: Execute procedure of custom validation of apply receipt
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - PAYMENT_ID          NUMBER     Payment Id;
--      - REMITTANCE_IDS      VARCHAR2   List of remittance ids;
--      - DOC_ID              NUMBER     Document Id;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'APPLY_BLC_RECEIPT',
-- 'APPLY_BLC_REMITTANCES'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ApplyReceipt( pi_Context     IN     SrvContext,
                        pio_OutContext IN OUT SrvContext,
                        pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_payment_id        blc_payments.payment_id%TYPE;
    l_remt_ids          VARCHAR2(2000);
    l_doc_id            blc_documents.doc_id%TYPE;
BEGIN
    -- Getting data from context
    l_payment_id := srv_prm_process.Get_Payment_Id( pi_Context );
    l_remt_ids := srv_prm_process.Get_Remittance_Ids( pi_Context );
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
   
    cust_pay_util_pkg.Apply_Receipt_On_Doc
                     ( pi_payment_id         => l_payment_id,
                       pi_remittance_ids     => l_remt_ids,
                       pi_doc_id             => l_doc_id,
                       pio_Err               => pio_Err);
                  
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.ApplyReceipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ApplyReceipt;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.PreReversePayment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.07.2017  creation
--
-- Purpose: Service executes custom validation of reverse reason
--
-- Input parameters:
--     pi_Context      SrvContext    Specifies payment data as attributes in
--                                   context;
--        - PAYMENT_ID  - payment Id (required);
--        - REASON_ID   - reverse reason Id (lookup_id);
--        - REASON_CODE - reverse reason code (lookup_code);
--        - NOTES       - reverse reason notes;
--        - REVERSED_ON - reverse date
--     pio_OutContext   SrvContext   Collection of object's attributes;
--        - NEW_STATUS - change to new status instead of reverse
--        - PROCEDURE_RESULT  VARCHAR2   Procedure result
--                                       'OK' - when activity is processed
--                                       'Err' - when some error occurs
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--        - NEW_STATUS - change to new status instead of reverse
--        - PROCEDURE_RESULT  VARCHAR2   Procedure result
--                                       'OK' - when activity is processed
--                                       'Err' - when some error occurs
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
-- Dependences: Service is associated with event 'REVERSE_BLC_PMNT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreReversePayment ( pi_Context IN SrvContext,
                              pio_OutContext IN OUT SrvContext,
                              pio_Err      IN OUT SrvErr )
IS
   --
    l_SrvErrMsg       SrvErrMsg;
    l_payment_id      blc_payments.payment_id%type;
    l_reason_id       blc_lookups.lookup_id%type;
    l_reversed_on     blc_payments.reversed_on%type;
    l_reason_code     blc_lookups.lookup_code%type;
    l_new_status      VARCHAR2(1);
    l_notes           blc_payments.notes%type;
    --
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'PAYMENT_ID', l_payment_id );
    srv_context.GetContextAttrNumber( pi_Context, 'REASON_ID', l_reason_id );
    srv_context.GetContextAttrDate( pi_Context, 'REVERSED_ON', l_reversed_on );
    srv_context.GetContextAttrChar( pi_Context, 'REASON_CODE', l_reason_code );
    srv_context.GetContextAttrChar( pi_Context, 'NOTES', l_notes );
    --
    pio_OutContext := pi_Context;
    --
    cust_pay_util_pkg.Pre_Reverse_Payment
                         (pi_payment_id      => l_payment_id,
                          pi_reason_id       => l_reason_id,
                          pi_reason_code     => l_reason_code,
                          pi_manual_flag     => NULL, --'M',
                          pi_notes           => l_notes,
                          pi_reversed_on     => l_reversed_on,
                          po_new_status      => l_new_status,
                          pio_Err            => pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'Err' );
       RETURN;
    END IF;

    srv_context.SetContextAttrChar( pio_OutContext, 'NEW_STATUS', l_new_status );
    srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'OK' );
    --
EXCEPTION
  WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.PreReversePayment', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'Err' );
END PreReversePayment;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.ReversePayment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.07.2017  creation
--
-- Purpose: Service override core reverse payment
--
-- Input parameters:
--     pi_Context      SrvContext    Specifies payment data as attributes in
--                                   context;
--        - PAYMENT_ID  - payment Id (required);
--        - REASON_ID   - reverse reason Id (lookup_id);
--        - REASON_CODE - reverse reason code (lookup_code);
--        - NOTES       - reverse reason notes;
--        - REVERSED_ON - reverse date
--        - EXECUTE_UNCLEAR - Y/N, Y - means execute unclear before reverse in
--                                  case that payment is cleared yet
--        - NEW_STATUS - change to new status instead of reverse
--     pio_OutContext   SrvContext   Collection of object's attributes;
--         - PROCEDURE_RESULT  VARCHAR2   Procedure result
--                                       'OK' - when activity is processed
--                                       'Err' - when some error occurs
--         - RETURN_STATUS     VARCHAR2   New payment status after activity
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--         - PROCEDURE_RESULT  VARCHAR2   Procedure result
--                                       'OK' - when activity is processed
--                                       'Err' - when some error occurs
--         - RETURN_STATUS     VARCHAR2   New payment status after activity
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
-- Dependences: Service is associated with event 'REVERSE_BLC_PMNT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ReversePayment ( pi_Context IN SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err      IN OUT SrvErr )
IS
   --
    l_SrvErrMsg       SrvErrMsg;
    l_payment_id      blc_payments.payment_id%type;
    l_reason_id       blc_lookups.lookup_id%type;
    l_notes           blc_payments.notes%type;
    l_reversed_on     blc_payments.reversed_on%type;
    l_reason_code     blc_lookups.lookup_code%type;
    l_execute_unclear VARCHAR2(30);
    l_new_status      VARCHAR2(1);
    --
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'PAYMENT_ID', l_payment_id );
    srv_context.GetContextAttrNumber( pi_Context, 'REASON_ID', l_reason_id );
    srv_context.GetContextAttrChar( pi_Context, 'NOTES', l_notes );
    srv_context.GetContextAttrDate( pi_Context, 'REVERSED_ON', l_reversed_on );
    srv_context.GetContextAttrChar( pi_Context, 'REASON_CODE', l_reason_code );
    srv_context.GetContextAttrChar( pi_Context, 'EXECUTE_UNCLEAR', l_execute_unclear );
    srv_context.GetContextAttrChar( pi_Context, 'NEW_STATUS', l_new_status );
    --
    pio_OutContext := pi_Context;
    --
    cust_pay_util_pkg.Reverse_Payment
                         (pi_payment_id      => l_payment_id,
                          pi_reason_id       => l_reason_id,
                          pi_reason_code     => l_reason_code,
                          pi_notes           => l_notes,
                          pi_reversed_on     => l_reversed_on,
                          pi_execute_unclear => l_execute_unclear,
                          pi_new_status      => l_new_status,
                          pio_Err            => pio_Err);

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.FLG_ERR );
    ELSE
       srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.FLG_OK );
       IF nvl(l_new_status,'R') <> 'R'
       THEN
          srv_context.SetContextAttrChar( pio_OutContext, 'RETURN_STATUS', l_new_status );
       ELSE
          srv_context.SetContextAttrChar( pio_OutContext, 'RETURN_STATUS', 'R' );
       END IF;
    END IF;

    --
EXCEPTION
  WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.ReversePayment', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.FLG_ERR );
END ReversePayment;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.ApprovePayments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Service executes steps of process BLC_APPROVE_PAYMENT for list of 
-- payments
--
-- Input parameters:
--     pi_Context      SrvContext    Specifies payment data as attributes in
--                                   context;
--        - PAYMENT_IDS      VARCHAR2   List of payment identifiers separated
--                                      with comma (required);
--        - NOTES            VARCHAR2   Approval notes;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--       - PROCEDURE_RESULT  VARCHAR2   Procedure result
--                                       'OK' - when activity is processed
--                                       'Err' - when some error occurs
--       - RETURN_STATUS     VARCHAR2   New payment status after activity
--                                      empty in case that some error occurs
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--       - PROCEDURE_RESULT  VARCHAR2   Procedure result
--                                       'OK' - when activity is processed
--                                       'Err' - when some error occurs
--       - RETURN_STATUS     VARCHAR2   New payment status after activity
--                                      empty in case that some error occurs
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
-- Dependences: Service is associated with event 'APPROVE_BLC_PMNTS'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ApprovePayments ( pi_Context IN SrvContext,
                            pio_OutContext IN OUT SrvContext,
                            pio_Err      IN OUT SrvErr )
IS
   --
    l_SrvErrMsg       SrvErrMsg;
    l_payment_ids     VARCHAR2(2000);
    l_notes           VARCHAR2(4000);
    l_changed_status  VARCHAR2(30);
    --
BEGIN
    srv_context.GetContextAttrChar( pi_Context, 'PAYMENT_IDS', l_payment_ids );
    srv_context.GetContextAttrChar( pi_Context, 'NOTES', l_notes );
    --
    pio_OutContext := pi_Context;
    --
    cust_pay_util_pkg.Approve_Payments
       (pi_payment_ids    => l_payment_ids,
        pi_notes          => l_notes,
        po_changed_status => l_changed_status,
        pio_Err           => pio_Err);
    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'Err' );
       RETURN;
    END IF;

    srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'OK' );
    srv_context.SetContextAttrChar( pio_OutContext, 'RETURN_STATUS', l_changed_status );
EXCEPTION
  WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.ApprovePayments', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'Err' );
END ApprovePayments;

--------------------------------------------------------------------------------
-- Name: srv_blc_bo.ModifyPmntActivities
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Service modify allowed activities for given payment
--
-- Input parameters:
--     pi_Context      SrvContext    Specifies payment data as attributes in
--                                   context;
--        - PAYMENT_ID    NUMBER   Payment Id (required);
--        - ACT_STRING   VARCHAR2  Activities string including some of the next
--                                 characters:
--                                  V - Validate
--                                  H - On-Hold
--                                  A - Approve
--                                  C - Clear
--                                  R - Reverse
--                                  D - Delete
--                                  N - Reinstate
--     pio_OutContext   SrvContext   Collection of object's attributes;
--        - ACT_STRING   VARCHAR2  Activities string including some of the next
--                                 characters:
--                                  V - Validate
--                                  H - On-Hold
--                                  A - Approve
--                                  C - Clear
--                                  R - Reverse
--                                  D - Delete
--                                  N - Reinstate
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--        - ACT_STRING   VARCHAR2  Activities string including some of the next
--                                 characters:
--                                  V - Validate
--                                  H - On-Hold
--                                  A - Approve
--                                  C - Clear
--                                  R - Reverse
--                                  D - Delete
--                                  N - Reinstate
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
-- Dependences: Service is associated with event 'GET_BLC_PMNT_ACTIVITIES'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ModifyPmntActivities ( pi_Context IN SrvContext,
                                 pio_OutContext IN OUT SrvContext,
                                 pio_Err      IN OUT SrvErr )
IS
   --
    l_SrvErrMsg       SrvErrMsg;
    l_payment_id      blc_payments.payment_id%type;
    l_activities      VARCHAR2(30);
    l_new_activities  VARCHAR2(30);
    --
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'PAYMENT_ID', l_payment_id );
    srv_context.GetContextAttrChar( pi_Context, 'ACT_STRING', l_activities );
    --
    cust_pay_util_pkg.Modify_Pmnt_Activities
       (pi_payment_id    => l_payment_id,
        pi_act_list      => l_activities,
        po_act_list      => l_new_activities,
        pio_Err          => pio_Err);
    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    srv_context.SetContextAttrChar( pio_OutContext, 'ACT_STRING', l_new_activities );
    --
EXCEPTION
  WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cuts_pay_bo.ModifyPmntActivities', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ModifyPmntActivities;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.UpdateApplEvent
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.05.2017  creation
--
-- Purpose: Execute procedure for set payment event id in attrib_9 of payment
-- application
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - APPLICATION_ID      NUMBER     Application Id;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'BLC_ITEM_PAID_STATUS'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE UpdateApplEvent( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_application_id    blc_applications.application_id%TYPE;
BEGIN
    -- Getting data from context
    srv_context.GetContextAttrNumber( pi_Context, 'APPLICATION_ID', l_application_id );

    cust_pay_util_pkg.Update_Appl_Event
                     ( pi_application_id     => l_application_id,
                       pio_Err               => pio_Err);
                                 
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.UpdateApplEvent', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END UpdateApplEvent;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.VoidPaymentForDocument
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.09.2013  creation
--     Fadata   05.03.2015  changed - change meaning of parameter reason
--                                    to be reverse payment reason code
--                                    rq 1000009677
--
-- Purpose:  Service reverses outgoing payments with amount > 0 for given
-- document
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies payment data as attributes
--                                  in context;
--        - DOC_ID - document Id (required);
--        - REASON - reverse payment reason code;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--        - PROCEDURE_RESULT - Procedure result
--                             'OK' - when payment is voided
--                             'Err' - when some error occurs
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--        - PROCEDURE_RESULT - Procedure result
--                             'OK' - when payment is voided
--                             'Err' - when some error occurs
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions:
--    1) In case that reversal of payment failed
--
-- Dependences: Service can be associated with event 'VOID_BLC_PMNT_FOR_DOCUMENT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE VoidPaymentForDocument ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_doc_id           NUMBER;
    l_reason           VARCHAR2(4000);
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'DOC_ID', l_doc_id );
      srv_context.GetContextAttrChar( pi_Context, 'REASON', l_reason );

      IF NOT cust_pay_util_pkg.Void_Payment_for_Document
           (PI_DOC_ID => l_doc_id,
            PI_REASON => l_reason,
            PIO_ERR => pio_Err)
      THEN
         srv_context.SetContextAttrChar( pio_outcontext, 'PROCEDURE_RESULT', 'Err');
      ELSE
         srv_context.SetContextAttrChar( pio_outcontext, 'PROCEDURE_RESULT', 'OK');
      END IF;

      srv_context.SetContextAttrChar( pio_outcontext, 'PAYMENT_ID', NULL);
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.VoidPaymentForDocument', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_context.SetContextAttrChar( pio_outcontext, 'PROCEDURE_RESULT', 'Err');
END VoidPaymentForDocument;

--------------------------------------------------------------------------------
-- Name: srv_cust_pay_bo.CreateCORIInstEvents
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   06.01.2014  creation
--
-- Purpose:  Create accounting event for claim RI/CO installments related to 
-- clearing of given payment
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies clearing data as attributes in
--                                  context;
--         - PAYMENT_ID - unique identifier of payment (required);
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
--
-- Dependences: Service is associated with event 'CREATE_BLC_CLEARING'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE CreateCORIInstEvents ( pi_Context IN SrvContext,
                                 pio_OutContext IN OUT SrvContext,
                                 pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_payment_id       NUMBER;
 
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'PAYMENT_ID', l_payment_id );
    
      pio_OutContext := pi_Context;
      --
      cust_pay_util_pkg.Create_Acc_Event_Clear_Inst
                 (pi_clearing_id  => NULL,
                  pi_uncleared    => NULL,
                  pi_payment_id   => l_payment_id,
                  pio_Err         => pio_Err);

     IF NOT srv_error.rqStatus( pio_Err )
     THEN
        srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'Err' );
        RETURN;
     END IF;

     srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'OK' );

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_pay_bo.CreateCORIInstEvents', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'Err' );
END CreateCORIInstEvents;
-- 
END srv_cust_pay_bo;
/


