CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.SRV_CUST_BO IS

--------------------------------------------------------------------------------
-- Name: INSIS_BLC_GLOBAL_CUST.srv_cust_bo.Dummy
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.02.2012  creation
--
-- Purpose: Use to replace some event procedures when want nothing to do.
-- Return 'OK' in attribute 'PROCEDURE_RESULT'
--
--     pi_Context       SrvContext     Collection of object's attributes
--
--     pio_OutContext   SrvContext     Collection of object's attributes:
--                                     - PROCEDURE_RESULT
--     pio_Err          SrvErr         Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_OutContext   SrvContext     Collection of object's attributes:
--     pio_Err          SrvErr         Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Returns:
-- Not applicable.
--
-- Usage: /*TBD_COM*/
--
-- Exceptions:
--
-- Dependences: N/A.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Dummy
   ( pi_Context     IN     SrvContext,
     pio_OutContext IN OUT SrvContext,
     pio_ErrMsg     IN OUT SrvErr )
 IS
 BEGIN
    srv_context.SetContextAttrChar( pio_OutContext, 'PROCEDURE_RESULT', 'OK');
 END Dummy;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ReversePayment
--
-- Status: Active
--
-- Versioning:
--     Fadata   27.06.2013  creation
--
-- Purpose: Custum validations after payment reverse
--
--
-- Type:
--
-- Input parameters:
--                   pi_payment_id         - payment id (blc_payment.payment_id)
-- Output parameters:
--                   pio_err               - collection for error messages
-- Returns:
-- N/A
--
-- Usage: /*TBD-COM*/
--
-- Exceptions: /*TBD-COM*/
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
    l_payment_id      NUMBER;
    --
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'PAYMENT_ID', l_payment_id );
    --
    blc_pmnt_wf_pkg.Reverse_Payment(l_payment_id, pio_Err);
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ReversePayment', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ReversePayment;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.PreCreateAccount
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an account to
-- modify some of the parameters.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
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
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_ACCOUNT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreCreateAccount ( pi_Context IN SrvContext,
                             pio_OutContext IN OUT SrvContext,
                             pio_Err IN OUT SrvErr )
IS
BEGIN
   cust_billing_pkg.Pre_Create_Account
                          ( pi_Context,
                            pio_OutContext,
                            pio_Err);
END PreCreateAccount;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.GetItemComp
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called instead of core get item composite and do not use
-- agreement when need to get item from type POLICY
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
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
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'GET_BLC_ITEM_COMP'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE GetItemComp ( pi_Context IN SrvContext,
                        pio_OutContext IN OUT SrvContext,
                        pio_Err IN OUT SrvErr )
IS

BEGIN
   cust_billing_pkg.Get_Item_Comp
                          ( pi_Context,
                            pio_OutContext,
                            pio_Err);
END GetItemComp;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.PreCreateUpdateItem
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an item to
-- modify some of the parameters. Calculate billing organization.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
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
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_ITEM',
--              'MODIFY_BLC_ITEM'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreCreateUpdateItem ( pi_Context IN SrvContext,
                                pio_OutContext IN OUT SrvContext,
                                pio_Err IN OUT SrvErr )
IS

BEGIN
   cust_billing_pkg.Pre_Create_Update_Item
                          ( pi_Context,
                            pio_OutContext,
                            pio_Err);
END PreCreateUpdateItem;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.PreCreateInstallment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an installment to
-- modify some of the parameters. Calculate end date.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
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
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_INSTALLMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreCreateInstallment ( pi_Context IN SrvContext,
                                 pio_OutContext IN OUT SrvContext,
                                 pio_Err IN OUT SrvErr )
IS

BEGIN
   cust_billing_pkg.Pre_Create_Installment
                          ( pi_Context,
                            pio_OutContext,
                            pio_Err);
END PreCreateInstallment;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.SelectBillInstallments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   25.04.2017  creation
--
-- Purpose:  Service selects eligible installments for billing according billing
-- run parameters and elibility clause setup of billing method as updates
-- billing_run_id column in blc_installments with given run_id. If external run
-- id is given then propose that instalments are already selected
--
-- Input parameters:
--     pi_Context      SrvContext   Collection of object's attributes;
--                                  - EXTERNAL_RUN_ID - external run id
--                                  - RUN_ID - billing run id (required)
--     pio_OutContext  SrvContext   Collection of object's attributes;
--                                  - SELECTED_COUNT - count of selected
--                                    installments
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--                                  - SELECTED_COUNT - count of selected
--                                    installments
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
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
-- Dependences: Service is associated with event 'RUN_BLC_IMMEDIATE_BILLING'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE SelectBillInstallments ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_external_run_id  blc_run.run_id%type;
    l_run_id           blc_run.run_id%type;
    l_count            PLS_INTEGER;
    l_procedure_result VARCHAR2(30);
  BEGIN
      -- Getting data from context
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      IF l_procedure_result IS NULL OR l_procedure_result = blc_gvar_process.flg_ok
      THEN
         l_external_run_id := srv_prm_process.Get_External_Run_Id( pi_Context );
         l_run_id := srv_prm_process.Get_Run_Id( pi_Context );

         cust_billing_pkg.Select_Bill_Installments_2
                             (pi_external_run_id  => l_external_run_id,
                              pi_billing_run_id   => l_run_id,
                              pio_Err             => pio_Err,
                              po_count            => l_count);

         pio_OutContext := pi_Context;
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
         ELSE
            srv_prm_process.Set_Selected_Count( pio_OutContext, l_count );
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
         END IF;
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.SelectBillInstallments', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END SelectBillInstallments;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.CreateBillTransactions
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
-- Purpose:  Service creates biil transactions for selected installments for
-- given biling_run_id
--
-- Input parameters:
--     pi_Context      SrvContext   Collection of object's attributes;
--                                  - RUN_ID - billing run id (required)
--     pio_OutContext  SrvContext   Collection of object's attributes;
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
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
-- Dependences: Service is associated with event 'RUN_BLC_IMMEDIATE_BILLING'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE CreateBillTransactions ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_run_id           blc_run.run_id%type;
    l_count            PLS_INTEGER;
    l_procedure_result VARCHAR2(30);
  BEGIN
      -- Getting data from context
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      l_count := srv_prm_process.Get_Selected_Count( pi_Context );
      IF (l_procedure_result IS NULL OR l_procedure_result = blc_gvar_process.flg_ok) AND (l_count IS NULL OR l_count > 0)
      THEN
         l_run_id := srv_prm_process.Get_Run_Id( pi_Context );

         cust_billing_pkg.Create_Bill_Transactions
                             (pi_billing_run_id   => l_run_id,
                              pio_Err             => pio_Err);

         pio_OutContext := pi_Context;
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
         ELSE
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
         END IF;
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.CreateBillTransactions', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END CreateBillTransactions;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ChangeAccountsNextDate
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--
-- Purpose:  Service updates next billing date with new calculated for accounts
-- with billing site equals to given billing site and next billing date date not
-- greater than given billing run date. Use this service after successfully
-- execution of regular billing
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies billing run data as attributes in
--                                  context;
--                                  - BILLING_SITE_ID - billing organization -
--                                    owner of the run
--                                  - RUN_DATE - billing run date
--                                  - BILL_METHOD - chosen from predefined
--                                    nomenclature lookup set BILL_METHODS
--                                  - BILL_METHOD_ID - bill method id
--                                  - RUN_ID - billing run id
--     pio_OutContext  SrvContext     Collection of object's attributes;
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
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
-- Dependences: Service is associated with event 'RUN_BLC_REGULAR_BILLING_ORG'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ChangeAccountsNextDate ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_billing_site_id  blc_run.bill_site_id%type;
    l_run_date         blc_run.run_date%type;
    l_bill_method      blc_lookups.lookup_code%type;
    l_bill_method_id   blc_run.bill_method_id%type;
    l_run_id           blc_run.run_id%type;
    l_procedure_result VARCHAR2(30);
  BEGIN
      -- Getting data from context
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      IF l_procedure_result IS NULL OR l_procedure_result = blc_gvar_process.flg_ok
      THEN
         l_billing_site_id := srv_prm_process.Get_Billing_Site_Id( pi_Context );
         l_run_date := srv_prm_process.Get_Run_Date( pi_Context );
         l_bill_method := srv_prm_process.Get_Bill_Method( pi_Context );
         l_bill_method_id := srv_prm_process.Get_Bill_Method_Id( pi_Context );
         l_run_id := srv_prm_process.Get_Run_Id( pi_Context );

         cust_billing_pkg.Change_Account_Next_Date
                 (pi_org_id           => l_billing_site_id,
                  pi_run_date         => l_run_date,
                  pi_bill_method      => l_bill_method,
                  pi_bill_method_id   => l_bill_method_id,
                  pi_billing_run_id   => l_run_id,
                  pio_Err             => pio_Err);

         pio_OutContext := pi_Context;
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
         ELSE
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
         END IF;
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ChangeAccountsNextDate', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END ChangeAccountsNextDate;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ChangeItemsNextDate
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--
-- Purpose:  Service updates next billing date with new calculated for items
-- with billing site equals to given billing site and next billing date date not
-- greater than given billing run date. Use this service after successfully
-- execution of regular billing
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies billing run data as attributes in
--                                  context;
--                                  - BILLING_SITE_ID - billing organization -
--                                    owner of the run
--                                  - RUN_DATE - billing run date
--                                  - BILL_METHOD - chosen from predefined
--                                    nomenclature lookup set BILL_METHODS
--                                  - BILL_METHOD_ID - bill method id
--                                  - RUN_ID - billing run id
--     pio_OutContext  SrvContext     Collection of object's attributes;
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--                                  - PROCEDURE_RESULT - Procedure result;
--     pio_Err         SrvErr       Specifies structure for passing back the
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
-- Dependences: Service is associated with event 'RUN_BLC_REGULAR_BILLING_ORG'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ChangeItemsNextDate ( pi_Context IN SrvContext,
                                pio_OutContext IN OUT SrvContext,
                                pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_billing_site_id  blc_run.bill_site_id%type;
    l_run_date         blc_run.run_date%type;
    l_bill_method      blc_lookups.lookup_code%type;
    l_bill_method_id   blc_run.bill_method_id%type;
    l_run_id           blc_run.run_id%type;
    l_procedure_result VARCHAR2(30);
  BEGIN
      -- Getting data from context
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      IF l_procedure_result IS NULL OR l_procedure_result = blc_gvar_process.flg_ok
      THEN
         l_billing_site_id := srv_prm_process.Get_Billing_Site_Id( pi_Context );
         l_run_date := srv_prm_process.Get_Run_Date( pi_Context );
         l_bill_method := srv_prm_process.Get_Bill_Method( pi_Context );
         l_bill_method_id := srv_prm_process.Get_Bill_Method_Id( pi_Context );
         l_run_id := srv_prm_process.Get_Run_Id( pi_Context );

         cust_billing_pkg.Change_Item_Next_Date
                 (pi_org_id           => l_billing_site_id,
                  pi_run_date         => l_run_date,
                  pi_bill_method      => l_bill_method,
                  pi_bill_method_id   => l_bill_method_id,
                  pi_billing_run_id   => l_run_id,
                  pio_Err             => pio_Err);

         pio_OutContext := pi_Context;
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
         ELSE
            srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
         END IF;
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ChangeItemsNextDate', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END ChangeItemsNextDate;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.PostProcess
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--
-- Purpose:  Service executes procedure custom postprocess
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - DOC_ID             NUMBER    Document Id;
--      - DOC_POSTPROCESS    VARCHAR2  Installment postprocess;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - DOC_POSTPROCESS    VARCHAR2  Oostprocess;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--      - ACTION_NOTES       VARCHAR2  Action notes;
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
PROCEDURE PostProcess ( pi_Context IN SrvContext,
                        pio_OutContext IN OUT SrvContext,
                        pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_doc_id           blc_documents.doc_id%type;
    l_action_notes     VARCHAR2(4000);
    l_procedure_result VARCHAR2(30);
    l_doc_postprocess  blc_lookups.lookup_code%type;
  BEGIN
      -- Getting data from context
      l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      l_doc_postprocess := srv_prm_process.Get_Doc_Postprocess( pi_Context);

      cust_billing_pkg.Postprocess_Document
         (pi_doc_id             => l_doc_id,
          pio_postprocess       => l_doc_postprocess,
          pio_procedure_result  => l_procedure_result,
          po_action_notes       => l_action_notes,
          pio_Err               => pio_Err);

      pio_OutContext := pi_Context;
      srv_prm_process.Set_Action_Notes( pio_OutContext, l_action_notes );
      srv_prm_process.Set_Doc_Postprocess( pio_OutContext, l_doc_postprocess );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.PostProcess', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END PostProcess;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.PreValidatePmnt
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
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.PreValidatePmnt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END PreValidatePmnt;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.PreApplyReceipt
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
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.PreApplyReceipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END PreApplyReceipt;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ApplyReceipt
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
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ApplyReceipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ApplyReceipt;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.LoadBSLine
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.08.2017  creation
--
-- Purpose:  Service generates a record for a bank statement line in Billing module
-- (inserts a row into BLC_BANK_STATEMENT_LINES table based on data in attributes
-- of input parameter pi_Context).
-- If parameter bank_stmt_id is given then the line record is cretade for this
-- bank statement
-- else firtsly a bank statement header record is created and than line for it
-- (inserts a row into BLC_BANK_STATEMENTS table based on data in attributes
-- of input parameter pi_Context).
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies item data as attributes in
--                                  context;
--      - BANK_STMT_ID   NUMBER       - bank statement id
--                                    required for creating line in existing
--                                    bank statement
--      - BANK_STMT_NUM  NUMBER       - bank statement number (unique number)
--                                    required for creating new header
--      - ACCOUNT_NUMBER VARCHAR2(50) - our bank account code
--                                    required for creating new header
--      - BS_DATE        DATE         - efective date of operation
--      - CURRENCY       VARCHAR2(3)  - out bank account code
--                                    required for creating new header
--      - OPERATION_TYPE VARCHAR2(30) - operation_type (required)
--                                     CREDIT_TRANSFER / CLEARING / REVERSE
--      - AMOUNT         NUMBER       - operation amount (required)
--      - PAYMENT_PREFIX VARCHAR2(30) - payment prefix
--      - PAYMENT_NUMBER VARCHAR2(120)- payment number (required)
--      - PAYMENT_SUFFIX VARCHAR2(30) - payment suffix
--      - POLICY_NO      VARCHAR2(50) - policy no
--      - DOC_PREFIX     VARCHAR2(30) - document prefix
--      - DOC_NUMBER     VARCHAR2(30) - document number (required for CREDIT_TRANSFER)
--      - DOC_SUFFIX     VARCHAR2(30) - document suffix
--      - PARTY_NAME_ORD VARCHAR2(2000) - party name ordering use for incoming
--      - USAGE_ID       NUMBER       - payment usage id
--      - REV_REASON_CODE VARCHAR2(30)- reverse reason (required for REVERSE)
--      - BANK_ACCOUNT_BEN VARCHAR2(50)- bank account number of beneficiary
--                                      use only for outgoing
--      - BANK_CODE_BEN  VARCHAR2(30)  - bank code of ordering party
--                                      use only for incoming
--      - BANK_ACCOUNT_ORD VARCHAR2(50)- bank account number of ordering party
--                                      use only for incoming
--      - BANK_CODE_ORD  VARCHAR2(30)  - bank code of beneficiary
--                                      use only for outgoing
--      - ATTRIB_0     VARCHAR2(120)- additional information
--      - ATTRIB_1     VARCHAR2(120)- additional information
--      - ATTRIB_2     VARCHAR2(120)- additional information
--      - ATTRIB_3     VARCHAR2(120)- additional information
--      - ATTRIB_4     VARCHAR2(120)- additional information
--      - ATTRIB_5     VARCHAR2(120)- additional information
--      - ATTRIB_6     VARCHAR2(120)- additional information
--      - ATTRIB_7     VARCHAR2(120)- additional information
--      - ATTRIB_8     VARCHAR2(120)- additional information
--      - ATTRIB_9     VARCHAR2(120)- additional information

--     pio_OutContext   SrvContext   Collection of object's attributes;
--                                   - BANK_STMT_ID - bank statement Id
--                                   - LINE_ID - line Id
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--                                   - BANK_STMT_ID - bank statement Id
--                                   - LINE_ID - line Id
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
--    1) In case that required attributes for creation of a bank statement or
--    line are not set as attributes of input parameter pi_Context or have
--    values NULL
--
-- Dependences: Service is associated with event 'LOAD_BLC_BS_LINE'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE LoadBSLine ( pi_Context IN SrvContext,
                       pio_OutContext IN OUT SrvContext,
                       pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg         SrvErrMsg;
    l_bank_stmt_id      blc_bank_statements.bank_stmt_id%type;
    l_bank_stmt_num     blc_bank_statements.bank_stmt_num%type;
    l_account_number    blc_bank_statements.account_number%type;
    l_bs_date           blc_bank_statements.balance_date%type;
    l_currency          blc_bank_statements.currency%type;
    l_operation_type    blc_bank_statement_lines.operation_type%type;
    l_amount            blc_bank_statement_lines.amount%type;
    l_payment_prefix    blc_bank_statement_lines.payment_prefix%type;
    l_payment_number    blc_bank_statement_lines.payment_number%type;
    l_payment_suffix    blc_bank_statement_lines.payment_suffix%type;
    l_policy_no         blc_bank_statement_lines.policy_no%type;
    l_doc_prefix        blc_bank_statement_lines.doc_prefix%type;
    l_doc_number        blc_bank_statement_lines.doc_number%type;
    l_doc_suffix        blc_bank_statement_lines.doc_suffix%type;
    l_party_name_ord    blc_bank_statement_lines.party_name_ord%type;
    l_usage_id          blc_bank_statement_lines.usage_id%type;
    l_rev_reason_code   blc_bank_statement_lines.rev_reason_code%type;
    l_bank_account_ben  blc_bank_statement_lines.bank_account_ben%type;
    l_bank_code_ben     blc_bank_statement_lines.bank_code_ben%type;
    l_bank_account_ord  blc_bank_statement_lines.bank_account_ord%type;
    l_bank_code_ord     blc_bank_statement_lines.bank_code_ord%type;
    l_attrib_0          blc_bank_statement_lines.attrib_0%type;
    l_attrib_1          blc_bank_statement_lines.attrib_1%type;
    l_attrib_2          blc_bank_statement_lines.attrib_2%type;
    l_attrib_3          blc_bank_statement_lines.attrib_3%type;
    l_attrib_4          blc_bank_statement_lines.attrib_4%type;
    l_attrib_5          blc_bank_statement_lines.attrib_5%type;
    l_attrib_6          blc_bank_statement_lines.attrib_6%type;
    l_attrib_7          blc_bank_statement_lines.attrib_7%type;
    l_attrib_8          blc_bank_statement_lines.attrib_8%type;
    l_attrib_9          blc_bank_statement_lines.attrib_9%type;
    l_line_id           blc_bank_statement_lines.line_id%type;
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'BANK_STMT_ID', l_bank_stmt_id );
      srv_context.GetContextAttrNumber( pi_Context, 'BANK_STMT_NUM', l_bank_stmt_num );
      srv_context.GetContextAttrChar( pi_Context, 'ACCOUNT_NUMBER', l_account_number );
      srv_context.GetContextAttrDate( pi_Context, 'BS_DATE', l_bs_date );
      srv_context.GetContextAttrChar( pi_Context, 'CURRENCY', l_currency );
      srv_context.GetContextAttrChar( pi_Context, 'OPERATION_TYPE', l_operation_type );
      srv_context.GetContextAttrNumber( pi_Context, 'AMOUNT', l_amount );
      srv_context.GetContextAttrChar( pi_Context, 'PAYMENT_PREFIX', l_payment_prefix );
      srv_context.GetContextAttrChar( pi_Context, 'PAYMENT_NUMBER', l_payment_number );
      srv_context.GetContextAttrChar( pi_Context, 'PAYMENT_SUFFIX', l_payment_suffix );
      srv_context.GetContextAttrChar( pi_Context, 'POLICY_NO', l_policy_no );
      srv_context.GetContextAttrChar( pi_Context, 'DOC_PREFIX', l_doc_prefix );
      srv_context.GetContextAttrChar( pi_Context, 'DOC_NUMBER', l_doc_number );
      srv_context.GetContextAttrChar( pi_Context, 'DOC_SUFFIX', l_doc_suffix );
      srv_context.GetContextAttrChar( pi_Context, 'PARTY_NAME_ORD', l_party_name_ord );
      srv_context.GetContextAttrNumber( pi_Context, 'USAGE_ID', l_usage_id );
      srv_context.GetContextAttrChar( pi_Context, 'REV_REASON_CODE', l_rev_reason_code );
      srv_context.GetContextAttrChar( pi_Context, 'BANK_ACCOUNT_BEN', l_bank_account_ben );
      srv_context.GetContextAttrChar( pi_Context, 'BANK_CODE_BEN', l_bank_code_ben );
      srv_context.GetContextAttrChar( pi_Context, 'BANK_ACCOUNT_ORD', l_bank_account_ord );
      srv_context.GetContextAttrChar( pi_Context, 'BANK_CODE_ORD', l_bank_code_ord );
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

      cust_load_bs_pkg.Load_BS_Line(
                           PI_BANK_STMT_ID     => l_bank_stmt_id,
                           PI_BANK_STMT_NUM    => l_bank_stmt_num,
                           PI_BANK_ACCOUNT     => l_account_number,
                           PI_BS_DATE          => l_bs_date,
                           PI_CURRENCY         => l_currency,
                           PI_OPERATION_TYPE   => l_operation_type,
                           PI_AMOUNT           => l_amount,
                           PI_PAYMENT_PREFIX   => l_payment_prefix,
                           PI_PAYMENT_NUMBER   => l_payment_number,
                           PI_PAYMENT_SUFFIX   => l_payment_suffix,
                           PI_POLICY_NUMBER    => l_policy_no,
                           PI_DOC_PREFIX       => l_doc_prefix,
                           PI_DOC_NUMBER       => l_doc_number,
                           PI_DOC_SUFFIX       => l_doc_suffix,
                           PI_PARTY_NAME_ORD   => l_party_name_ord,
                           PI_USAGE_ID         => l_usage_id,
                           PI_REV_REASON_CODE  => l_rev_reason_code,
                           PI_BANK_ACCOUNT_BEN => l_bank_account_ben,
                           PI_BANK_CODE_BEN    => l_bank_code_ben,
                           PI_BANK_ACCOUNT_ORD => l_bank_account_ord,
                           PI_BANK_CODE_ORD    => l_bank_code_ord,
                           PI_ATTRIB_0         => l_attrib_0,
                           PI_ATTRIB_1         => l_attrib_1,
                           PI_ATTRIB_2         => l_attrib_2,
                           PI_ATTRIB_3         => l_attrib_3,
                           PI_ATTRIB_4         => l_attrib_4,
                           PI_ATTRIB_5         => l_attrib_5,
                           PI_ATTRIB_6         => l_attrib_6,
                           PI_ATTRIB_7         => l_attrib_7,
                           PI_ATTRIB_8         => l_attrib_8,
                           PI_ATTRIB_9         => l_attrib_9,
                           PO_BANK_STMT_ID     => l_bank_stmt_id,
                           PO_LINE_ID          => l_line_id,
                           PIO_ERR             => pio_Err);

      srv_context.SetContextAttrNumber( pio_OutContext, 'BANK_STMT_ID', srv_context.Integers_Format, l_bank_stmt_id );
      srv_context.SetContextAttrNumber( pio_OutContext, 'LINE_ID', srv_context.Integers_Format, l_line_id );

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.LoadBSLine', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END LoadBSLine;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ProcessBankStatement
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.03.2016  creation
--
--
-- Purpose:
--
-- Input parameters:
--     pi_Context       SrvContext      Specifies necessary input data:
--                                      LEGAL_ENTITY_ID - Legal Entity ID
--                                      ORG_ID - Organization ID
--                                      BANK_STMT_ID - Bank Statement ID (Required)
--
--     pio_OutContext   SrvContext      SrvContext Specifies structure for
--                                      passing back the parameters:
--
--
--
-- Output parameters:
--     pio_OutContext   SrvContext      SrvContext Specifies structure for
--                                      passing back the parameters:
--
--    pio_Err -         SrvErr          Specifies structure for passing back the
--                                      error code, error TYPE and corresponding
--                                      message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'PROCESS_BLC_BANK_STATEMENT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ProcessBankStatement( pi_Context     IN      SrvContext,
                                pio_OutContext IN OUT SrvContext,
                                pio_Err        IN OUT SrvErr )
IS
    l_le_id        NUMBER;
    l_org_id       NUMBER;
    l_bank_stmt_id NUMBER;
    --
    l_SrvErrMsg       SrvErrMsg;
    l_Context        srvcontext;
BEGIN
    -- Getting data from context
    l_le_id := srv_prm_process.Get_LE_Id( pi_Context );
    l_org_id := srv_prm_process.Get_Org_Id( pi_Context );
    l_bank_stmt_id := srv_prm_process.Get_Bank_Stmt_Id( pi_Context );

    cust_process_bank_stmt_pkg.Process_Bank_Stmt( pi_bank_stmt_id    => l_bank_stmt_id,
                                                  pi_legal_entity_id => l_le_id,
                                                  pi_org_id          => l_org_id,
                                                  pio_Err            => pio_Err );
    pio_OutContext := pi_Context;

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        srv_prm_process.Set_Procedure_Result( pio_OutContext, BLC_GVAR_PROCESS.FLG_ERR );
    ELSE
        srv_prm_process.Set_Procedure_Result( pio_OutContext, BLC_GVAR_PROCESS.FLG_OK );
    END IF;
EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'SRV_BLC_BS_PROCESS_BO.ProcessBankStatement', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, BLC_GVAR_PROCESS.FLG_ERR );
END ProcessBankStatement;

--------------------------------------------------------------------------------
-- Name: SRV_CUST_BO.ProcessBankStmtLine
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.03.2016  creation
--
--
-- Purpose:  Service processes the passed bank statement line
--
-- Input parameters:
--     pi_Context       SrvContext      Specifies necessary input data:
--                                      LINE_ID - Bank Statement Line (Required)
--
--     pio_OutContext   SrvContext      SrvContext Specifies structure for
--                                      passing back the parameters:
--
--
--
-- Output parameters:
--     pio_OutContext   SrvContext      SrvContext Specifies structure for
--                                      passing back the parameters:
--
--    pio_Err -         SrvErr          Specifies structure for passing back the
--                                      error code, error TYPE and corresponding
--                                      message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'EXECUTE_BLC_BANK_ST_LINE'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ProcessBankStmtLine( pi_Context     IN     SrvContext,
                               pio_OutContext IN OUT SrvContext,
                               pio_Err        IN OUT SrvErr )
IS
    l_line_id    NUMBER;
    --
    l_SrvErrMsg       SrvErrMsg;
BEGIN
    -- Getting data from context
    srv_context.GetContextAttrNumber( pi_Context, 'LINE_ID', l_line_id );
    --
    cust_process_bank_stmt_pkg.Process_Exec_Bank_St_Line ( l_line_id, pio_Err );
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ProcessBankStmtLine', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ProcessBankStmtLine;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ModifyDocNumber
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.08.2017  creation
--
-- Purpose: Execute procedure for modifying document number
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - DOC_ID              NUMBER    Document Id;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'COMPLETE_BLC_DOCUMENT',
-- 'VALIDATE_BLC_DOCUMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ModifyDocNumber( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_doc_id            blc_documents.doc_id%TYPE;
    l_action_notes      VARCHAR2(4000);
    l_procedure_result  VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
    l_action_notes := srv_prm_process.Get_Action_Notes( pi_Context );
    l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
    --
    cust_billing_pkg.Modify_Doc_Number
                     ( pi_doc_id             => l_doc_id,
                       pio_procedure_result  => l_procedure_result,
                       po_action_notes       => l_action_notes,
                       pio_Err               => pio_Err);
    --
    pio_OutContext := pi_Context;
    srv_prm_process.Set_Action_Notes( pio_OutContext, l_action_notes );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ModifyDocNumber', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END ModifyDocNumber;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.SetDocAD
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.08.2017  creation
--
-- Purpose: Execute procedure for set document suffix with given AD (autorized
-- document) number
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - DOC_ID              NUMBER    Document Id (requiered);
--      - ACTION_TYPE         VARCHAR2  Action type (requiered) possible values:
--                                      CREATE_AD, DELETE_AD;
--      - AD_NUMBER           VARCHAR2  AD number (requiered);
--      - AD_DATE             DATE      Issued or deleted date of AD (requiered);
--      - ACTION_REASON       VARCHAR2  Action reason notes;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result possible values:
--                                      SUCCESS/WARNING/ERROR;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result possible values:
--                                      SUCCESS/WARNING/ERROR;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'CUST_BLC_SET_AD'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE SetDocAD( pi_Context     IN     SrvContext,
                    pio_OutContext IN OUT SrvContext,
                    pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_doc_id            blc_documents.doc_id%TYPE;
    l_action_type       blc_lookups.lookup_code%TYPE;
    l_ad_number         blc_documents.doc_suffix%TYPE;
    l_ad_date           DATE;
    l_action_reason     VARCHAR2(4000);
    l_procedure_result  VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
    srv_context.GetContextAttrChar( pi_Context, 'ACTION_TYPE', l_action_type );
    srv_context.GetContextAttrChar( pi_Context, 'AD_NUMBER', l_ad_number );
    srv_context.GetContextAttrDate( pi_Context, 'AD_DATE', l_ad_date );
    srv_context.GetContextAttrChar( pi_Context, 'ACTION_REASON', l_action_reason );
    --
    cust_billing_pkg.Set_Doc_AD
                     ( pi_doc_id             => l_doc_id,
                       pi_action_type        => l_action_type,
                       pi_ad_number          => l_ad_number,
                       pi_ad_date            => l_ad_date,
                       pi_action_reason      => l_action_reason,
                       po_procedure_result   => l_procedure_result,
                       pio_Err               => pio_Err);
    --
    pio_OutContext := pi_Context;
    srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.SetDocAD', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, cust_gvar.flg_error );
END SetDocAD;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.PreUnApplyReceipt
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.08.2017  creation
--
-- Purpose: Execute procedure of custom validation of unapply receipt
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - PAYMENT_ID          NUMBER     Payment Id;
--      - REMITTANCE_IDS      VARCHAR2   List of remittance ids;
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
-- Dependences: Service is associated with event 'UNAPPLY_BLC_RECEIPT',
-- 'UNAPPLY_BLC_REMITTANCES'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreUnApplyReceipt( pi_Context     IN     SrvContext,
                             pio_OutContext IN OUT SrvContext,
                             pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_payment_id        blc_payments.payment_id%TYPE;
    l_remt_ids          VARCHAR2(2000);
BEGIN
    -- Getting data from context
    l_payment_id := srv_prm_process.Get_Payment_Id( pi_Context );
    l_remt_ids := srv_prm_process.Get_Remittance_Ids( pi_Context );

    cust_pay_util_pkg.Validate_Pmnt_UnAppl
                     ( pi_payment_id         => l_payment_id,
                       pi_remittance_ids     => l_remt_ids,
                       pio_Err               => pio_Err);

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.PreUnApplyReceipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END PreUnApplyReceipt;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ModifyInstAttributes
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  creation - extend core functon with update of run_id
--
-- Purpose:  Service updates records for an item in Billing module
-- (update attributes/attrib_0 .. attrib_9/ and postprocess in rows into
-- BLC_INSTALLMENTS table based on data in attributes of input parameter
-- pi_Context for given item_id and if not empty policy, annex, claim and
-- external_id as additional selection for group of installments).
-- Only set of attrubutes, run_id and postprocess will be updated.
-- In case that updated postprocess like 'FREE%' than execute procedure for
-- document FREE postprocess
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--                                  - ITEM_ID - unique identifier of billing item
--                                    (required)
--                                  - POLICY - policy Id
--                                  - ANNEX - annex Id
--                                  - CLAIM - claim_Id
--                                  - EXTERNAL_ID - insurance system reference
--                                  - INST_ATTRIB_0 - set in attrib_0
--                                  - INST_ATTRIB_1 - set in attrib_1
--                                  - INST_ATTRIB_2 - set in attrib_2
--                                  - INST_ATTRIB_3 - set in attrib_3
--                                  - INST_ATTRIB_4 - set in attrib_4
--                                  - INST_ATTRIB_5 - set in attrib_5
--                                  - INST_ATTRIB_6 - set in attrib_6
--                                  - INST_ATTRIB_7 - set in attrib_7
--                                  - INST_ATTRIB_8 - set in attrib_8
--                                  - INST_ATTRIB_9 - set in attrib_9
--                                  - RUN_ID - billing run id
--                                  - POSTPROCESS - installment postprocess
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
--    1) In case that required attribute ITEM_ID is not set as attribute of
--    input parameter pi_Context or have value NULL
--
-- Dependences: Service is associated with event 'MODIFY_BLC_INST_ATTRIBUTES'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ModifyInstAttributes ( pi_Context IN SrvContext,
                                 pio_OutContext IN OUT SrvContext,
                                 pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_item_id          blc_installments.item_id%type;
    l_policy           blc_installments.policy%type;
    l_annex            blc_installments.annex%type;
    l_claim            blc_installments.claim%type;
    l_external_id      blc_installments.external_id%type;
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'ITEM_ID', l_item_id );
      srv_context.GetContextAttrChar( pi_Context, 'POLICY', l_policy );
      srv_context.GetContextAttrChar( pi_Context, 'ANNEX', l_annex );
      srv_context.GetContextAttrChar( pi_Context, 'CLAIM', l_claim );
      srv_context.GetContextAttrChar( pi_Context, 'EXTERNAL_ID', l_external_id );

      IF NOT cust_billing_pkg.Modify_Inst_Attributes
                             (l_item_id,
                              l_policy,
                              l_annex,
                              l_claim,
                              l_external_id,
                              pi_Context,
                              pio_Err)
      THEN
          NULL;
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ModifyInstAttributes', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ModifyInstAttributes;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ValidateDocReference
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2015  creation
--
-- Purpose:  Service executes procedure for validate doc reference
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - DOC_ID             NUMBER    Document Id;
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
PROCEDURE ValidateDocReference ( pi_Context IN SrvContext,
                                 pio_OutContext IN OUT SrvContext,
                                 pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_doc_id           blc_documents.doc_id%type;
    l_procedure_result VARCHAR2(30);
    l_doc_status       blc_documents.status%type;
  BEGIN
      -- Getting data from context
      l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );

      cust_billing_pkg.Validate_Doc_Reference
                     ( pi_doc_id             => l_doc_id,
                       pio_procedure_result  => l_procedure_result,
                       po_doc_status         => l_doc_status,
                       pio_Err               => pio_Err);

      pio_OutContext := pi_Context;
      srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );
      srv_prm_process.Set_Doc_Status( pio_OutContext, l_doc_status );
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ValidateDocReference', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END ValidateDocReference;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ApprComplDocuments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.08.2017  creation - rq 1000011083
--
-- Purpose:  Service executes procedure for approve and complete documents with
-- ids from given list indepent on them status and return list of not posiible
-- to complete documents
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--     - DOC_IDS             VARCHAR2 List of document Ids;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     - PROCEDURE_RESULT    VARCHAR2 Procedure result
--     - DOCUMENT_LIST       VARCHAR2 List of incompleted documents
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     - PROCEDURE_RESULT    VARCHAR2  Procedure result
--     - DOCUMENT_LIST       VARCHAR2  Populated when PROCEDURE_RESULT = OK
--                                     List of document numbers which are
--                                     continue to stay ON-HOLD after successfully
--                                     execution of procedure
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
-- Dependences: Service is associated with event 'APPROVE_BLC_DOCUMENTS'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ApprComplDocuments ( pi_Context IN SrvContext,
                               pio_OutContext IN OUT SrvContext,
                               pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg       SrvErrMsg;
    l_doc_ids         VARCHAR2(4000);
    l_doc_list        VARCHAR2(4000);
  BEGIN
      -- Getting data from context
      l_doc_ids := srv_prm_process.Get_Doc_Ids( pi_Context );

      cust_billing_pkg.Appr_Compl_Documents
                     (l_doc_ids,
                      l_doc_list,
                      pio_Err);

      pio_OutContext := pi_Context;
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
      ELSE
         srv_prm_process.Set_Document_List( pio_OutContext, l_doc_list );
         srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ApprComplDocuments', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END ApprComplDocuments;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.MarkForDeletion
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2017  creation
--     Fadata   13.06.2018  changed - change parameter po_action_notes to
--                          pio_action_notes in call Mark_For_Deletion - LPV-1654
--
-- Purpose: Executes procedure for check availability for deletion of proforma
-- and call integration server to lock for deletion proforma in SAP
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - DOC_ID              NUMBER    Document Id;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'DELETE_BLC_DOCUMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE MarkForDeletion( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_doc_id            blc_documents.doc_id%TYPE;
    l_action_notes      VARCHAR2(4000);
    l_procedure_result  VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
    l_action_notes := srv_prm_process.Get_Action_Notes( pi_Context );
    l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
    --
    cust_billing_pkg.Mark_For_Deletion
                     ( pi_doc_id             => l_doc_id,
                       pio_procedure_result  => l_procedure_result,
                       pio_action_notes      => l_action_notes,
                       pio_Err               => pio_Err);
    --
    pio_OutContext := pi_Context;
    srv_prm_process.Set_Action_Notes( pio_OutContext, l_action_notes );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.MarkForDeletion', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END MarkForDeletion;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.PreSetFormalUnformal
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2015  creation
--
-- Purpose:  Executes procedure for validation of change status to
-- Formal/Unformal
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - DOC_ID             NUMBER    Document Id;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--      - ACTION_NOTES       VARCHAR2  Action notes;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT   VARCHAR2  Procedure result;
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
-- Dependences: Service is associated with event 'SET_FORMAL_BLC_DOCUMENT',
-- 'SET_UNFORMAL_BLC_DOCUMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PreSetFormalUnformal ( pi_Context IN SrvContext,
                                 pio_OutContext IN OUT SrvContext,
                                 pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_doc_id           blc_documents.doc_id%type;
    l_procedure_result VARCHAR2(30);
    l_action_notes     VARCHAR2(4000);
  BEGIN
      -- Getting data from context
      l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
      l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
      l_action_notes := srv_prm_process.Get_Action_Notes( pi_Context );

      cust_billing_pkg.Pre_Set_Formal_Unformal
                     ( pi_doc_id             => l_doc_id,
                       pi_action_notes       => l_action_notes,
                       pio_procedure_result  => l_procedure_result,
                       pio_Err               => pio_Err);

      pio_OutContext := pi_Context;
      srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );
  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.PreSetFormalUnformal', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END PreSetFormalUnformal;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.MassDeleteProforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2015  creation
--
-- Purpose:  Executes procedure for delete all unpaid and without AD number
-- proformas related to given policy_idl
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - POLICY_ID          NUMBER    Policy Id;
--      - ANNEX_ID           NUMBER    Annex Id;
--      - AGREEMENT          VARCHAR2  Item agreement;
--      - PROTOCOL           VARCHAR2  Protocol number;
--      - LOCK_DELETE        VARCHAR2  Flag for call integration for lock;
--      - ITEM_IDS           VARCHAR2  Item Ids;
--      - MASTER_POLICY_NO   VARCHAR2  Master policy no;
--      - DELETE_REASON      VARCHAR2  Delete reason;
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
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'CUST_MASS_DELETE_BLC_PROFORMA'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE MassDeleteProforma ( pi_Context IN SrvContext,
                               pio_OutContext IN OUT SrvContext,
                               pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_policy_id        NUMBER;
    l_annex_id         NUMBER;
    l_agreement        VARCHAR2(50);
    l_protocol         VARCHAR2(50);
    l_lock_flag        VARCHAR2(10);
    l_item_ids         VARCHAR2(2000);
    l_master_policy_no VARCHAR2(50);
    l_delete_reason    VARCHAR2(2000);
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );
      srv_context.GetContextAttrNumber( pi_Context, 'ANNEX_ID', l_annex_id );
      srv_context.GetContextAttrChar( pi_Context, 'AGREEMENT', l_agreement );
      srv_context.GetContextAttrChar( pi_Context, 'PROTOCOL', l_protocol );
      srv_context.GetContextAttrChar( pi_Context, 'LOCK_DELETE', l_lock_flag );
      srv_context.GetContextAttrChar( pi_Context, 'ITEM_IDS', l_item_ids );
      srv_context.GetContextAttrChar( pi_Context, 'MASTER_POLICY_NO', l_master_policy_no );
      srv_context.GetContextAttrChar( pi_Context, 'DELETE_REASON', l_delete_reason );

      IF l_annex_id IS NULL
      THEN
         srv_context.GetContextAttrChar( pi_Context, 'ANNEX', l_annex_id );
      END IF;

      cust_billing_pkg.Mass_Delete_Proforma
                     ( pi_policy_id             => l_policy_id,
                       pi_annex_id              => l_annex_id,
                       pi_agreement             => l_agreement,
                       pi_protocol              => l_protocol,
                       pi_lock_flag             => l_lock_flag,
                       pi_item_ids              => l_item_ids,
                       pi_master_policy_no      => l_master_policy_no,
                       pi_delete_reason         => l_delete_reason,
                       pio_Err                  => pio_Err);

      pio_OutContext := pi_Context;
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
      ELSE
         srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.MassDeleteProforma', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END MassDeleteProforma;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.RecreateAccTrx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.11.2017  creation
--
-- Purpose: Executes procedure for create accounting transactions and transfer
-- them to the intreface tables
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - DOC_ID              NUMBER    Document Id;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'CUST_RECREATE_BLC_ACC_TRX'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE RecreateAccTrx( pi_Context     IN     SrvContext,
                          pio_OutContext IN OUT SrvContext,
                          pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_doc_id            blc_documents.doc_id%TYPE;
    l_procedure_result  VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
    --
    cust_acc_process_pkg.Recreate_Acc_Trx
                     ( pi_acc_doc_id        => l_doc_id,
                       po_procedure_result  => l_procedure_result,
                       pio_Err              => pio_Err);
    --
    pio_OutContext := pi_Context;
    srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.RecreateAccTrx', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END RecreateAccTrx;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.PrePayDocument
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.11.2017  creation
--
-- Purpose: Execute procedure for validation before pay a document
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - DOC_ID              NUMBER    Document Id;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - ORG_ID              NUMBER    Organization Id;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'PAY_BLC_DOCUMENT',
-- 'PAY_IMMEDIATE'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE PrePayDocument( pi_Context     IN     SrvContext,
                          pio_OutContext IN OUT SrvContext,
                          pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_doc_id            blc_documents.doc_id%TYPE;
    l_org_id            blc_documents.org_site_id%TYPE;
    l_org_id_in         NUMBER;
    l_office            VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
    l_org_id_in := srv_prm_process.Get_Org_Id( pi_Context );
    l_office := srv_prm_process.Get_Office( pi_Context );

    cust_billing_pkg.Pre_Pay_Document
                     ( pi_doc_id             => l_doc_id,
                       po_org_id             => l_org_id,
                       pio_Err               => pio_Err);
    --
    IF l_org_id_in IS NULL AND l_office IS NULL
    THEN
       pio_OutContext := pi_Context;
       srv_prm_process.Set_Org_Id( pio_OutContext, l_org_id );
    END IF;

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.PrePayDocument', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END PrePayDocument;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.NotAllowActivity
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2017  creation
--
-- Purpose: Executes procedure for check availability for deletion of proforma
-- and call integration server to lock for deletion proforma in SAP
--
-- Input parameters:
--     pi_Context    SrvContext   Specifies value data as attributes in context;
--      - DOC_ID              NUMBER    Document Id;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - PROCEDURE_RESULT    VARCHAR2  Procedure result;
--      - ACTION_NOTES        VARCHAR2  Action notes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'HOLD_BLC_DOCUMENT','CUST_APPR_COMPL_BLC_DOCUMENT',
-- 'REJECT_BLC_DOCUMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE NotAllowActivity( pi_Context     IN     SrvContext,
                            pio_OutContext IN OUT SrvContext,
                            pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_doc_id            blc_documents.doc_id%TYPE;
    l_action_notes      VARCHAR2(4000);
    l_procedure_result  VARCHAR2(30);
BEGIN
    -- Getting data from context
    l_doc_id := srv_prm_process.Get_Doc_Id( pi_Context );
    l_action_notes := srv_prm_process.Get_Action_Notes( pi_Context );
    l_procedure_result := srv_prm_process.Get_Procedure_Result( pi_Context );
    --
    cust_billing_pkg.Not_Allow_Activity
                     ( pi_doc_id             => l_doc_id,
                       pio_procedure_result  => l_procedure_result,
                       po_action_notes       => l_action_notes,
                       pio_Err               => pio_Err);
    --
    pio_OutContext := pi_Context;
    srv_prm_process.Set_Action_Notes( pio_OutContext, l_action_notes );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, l_procedure_result );

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.NotAllowActivity(', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END NotAllowActivity;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ProcessIPResult
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   22.12.2017  creation
--
-- Purpose: Execute procedure for process IP/SAP result to the BLC interface and
-- and document tables
--
-- Input parameters:
--   pi_Context    SrvContext   Specifies value data as attributes in context;
--     - HEADER_ID           NUMBER(17,0)       Header Id  - ID in interface table (BLC_PROFORMA_GEN,..) (required)
--     - HEADER_TABLE        VARCHAR2(20)       Interface table name (BLC_PROFORMA_GEN,..) (required)
--     - LINE_NUMBER_FROM    NUMBER(5,0)        Line number from - line number in detail table (BLC_PROFORMA_ACC,..) (optional)
--                                              use when for one BLC header there many SAP documents because of max 999 lines requirement
--     - LINE_NUMBER_TO      NUMBER(5,0)        Line number to - line number in detail table (BLC_PROFORMA_ACC,..) (optional)
--                                              use when for one BLC header there many SAP documents because of max 999 lines requirement
--     - SAP_DOC_NUMBER      VARCHAR2(25 CHAR)  SAP doc number (required for status Transferred)
--     - PROCESS_START_DATE  DATE               Process start date (required)
--     - PROCESS_END_DATE    DATE               Process end date (required)
--     - STATUS              VARCHAR2(1)        Status - possible values: (required)
--                                              - T - Transferred
--                                              - E - Error
--     - ERROR_TYPE          VARCHAR2(30)       Error type - from where the error is returning (required for status Error)
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     - ERROR_MSG           VARCHAR2(4000)     Error message (required for status Error)
--   pio_OutContext   SrvContext   Collection of object's attributes;
--     - PROCEDURE_RESULT    VARCHAR2(30)       Procedure result possible values:
--                                               - SUCCESS/ERROR;
--   pio_Err                 SrvErr             Specifies structure for passing back the
--                                              error code, error TYPE and corresponding
--                                              message.
--
-- Output parameters:
--   pio_OutContext   SrvContext   Collection of object's attributes;
--     - PROCEDURE_RESULT    VARCHAR2(30)       Procedure result possible values:
--                                               - SUCCESS/ERROR;
--   pio_Err                 SrvErr             Specifies structure for passing back the
--                                              error code, error TYPE and corresponding
--                                              message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'CUST_BLC_PROCESS_IP_RESULT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ProcessIPResult( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg         SrvErrMsg;
    l_header_id         blc_proforma_gen.id%TYPE;
    l_header_table      VARCHAR2(30);
    l_line_number_from  blc_proforma_acc.line_number%TYPE;
    l_line_number_to    blc_proforma_acc.line_number%TYPE;
    l_SAP_doc_number    blc_proforma_gen.sap_doc_number%TYPE;
    l_proc_start_date   blc_proforma_gen.process_start_date%TYPE;
    l_proc_end_date     blc_proforma_gen.process_end_date%TYPE;
    l_status            blc_proforma_gen.status%TYPE;
    l_error_type        blc_proforma_gen.error_type%TYPE;
    l_error_msg         blc_proforma_gen.error_msg%TYPE;

BEGIN
    -- Getting data from context
    srv_context.GetContextAttrNumber( pi_Context, 'HEADER_ID', l_header_id );
    srv_context.GetContextAttrChar( pi_Context, 'HEADER_TABLE', l_header_table );
    srv_context.GetContextAttrNumber( pi_Context, 'LINE_NUMBER_FROM', l_line_number_from );
    srv_context.GetContextAttrNumber( pi_Context, 'LINE_NUMBER_TO', l_line_number_to );
    srv_context.GetContextAttrChar( pi_Context, 'SAP_DOC_NUMBER', l_SAP_doc_number );
    srv_context.GetContextAttrDate( pi_Context, 'PROCESS_START_DATE', l_proc_start_date );
    srv_context.GetContextAttrDate( pi_Context, 'PROCESS_END_DATE', l_proc_end_date );
    srv_context.GetContextAttrChar( pi_Context, 'STATUS', l_status );
    srv_context.GetContextAttrChar( pi_Context, 'ERROR_TYPE', l_error_type );
    srv_context.GetContextAttrChar( pi_Context, 'ERROR_MSG', l_error_msg );
    --
    cust_acc_export_pkg.Process_SAP_Result
                         (pi_header_id        =>     l_header_id,
                          pi_header_table     =>     l_header_table,
                          pi_line_number_from =>     l_line_number_from,
                          pi_line_number_to   =>     l_line_number_to,
                          pi_SAP_doc_number   =>     l_SAP_doc_number,
                          pi_SAP_start_date   =>     l_proc_start_date,
                          pi_SAP_end_date     =>     l_proc_end_date,
                          pi_status           =>     l_status,
                          pi_err_code         =>     l_error_type,
                          pi_err_message      =>     l_error_msg,
                          pio_Err             =>     pio_Err);
    --
    pio_OutContext := pi_Context;
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       srv_prm_process.Set_Procedure_Result( pio_OutContext, cust_gvar.flg_error );
    ELSE
       srv_prm_process.Set_Procedure_Result( pio_OutContext, cust_gvar.flg_success );
    END IF;

EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ProcessIPResult', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    srv_prm_process.Set_Procedure_Result( pio_OutContext, cust_gvar.flg_error);
END ProcessIPResult;

--------------------------------------------------------------------------------
-- Name: Create_Bad_Debt
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   01.02.2018  creation
--
--
-- Purpose: Event for activating create SPA documents on close day
--
-- Input parameters:
--     pi_Context       SrvContext   Specifies necessry input data:
--                                   ORDER_ID persiod_id of reserve to be posted
--     pio_RetPrm       SrvContext   SrvContext Specifies structure for
--                                   passing back the parameters: N/A
--
-- Output parameters:
--    pio_Err - collection for error messages
--
-- Dependences: Service is associated with event 'CUST_BLC_RUN_BDC'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Bad_Debt( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg       SrvErrMsg;
    --
    l_order_id        NUMBER;
    l_office          VARCHAR2(50);
    l_Context         SrvContext;
    l_OutContext      SrvContext;
    l_date            DATE;
BEGIN
    --
    srv_context.GetContextAttrNumber( pi_Context, 'ORDER_ID', l_order_id );

    l_date := sys_days.get_open_date;
    --
    srv_context.SetContextAttrDate   ( l_Context, 'TO_DATE', srv_context.Date_Format, l_date );

    -- RQ1000010355
    insis_gen_v10.srv_prm_policy.sCountryId( l_Context , insis_context.get_country);
    -- end RQ1000010355
    --
    Srv_Events.sysEvent( 'GET_DEFAULT_OFFICE', l_Context, l_OutContext, pio_Err );  -- srv_events_people.GET_DEFAULT_OFFICE
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;

    l_office := srv_people_data.gOfficeRecord.office_id;
    --
    cust_coll_util_pkg.Create_Bad_Debit( l_office, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
         RETURN;
    END IF;
    --
EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.Create_Bad_Debt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END Create_Bad_Debt;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.AddProformaNotes
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.04.2019  creation LPVS-108
--
-- Purpose: Insert action for PROFORMA document and changes in ATTRIB_2
--
-- Input parameters:
--  pi_Context    SrvContext   Specifies value data as attributes in context;
--     TABLE_NAME          VARCHAR2     table name (required)
--     PK_VALUE            NUMBER       the primary key value (required)
--     ATTRIB_2            VARCHAR2     attrib 2
--   pio_OutContext   SrvContext   Collection of object's attributes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--   pio_OutContext   SrvContext    Collection of object's attributes;
--     ATTRIB_2        VARCHAR2     SUBSTR attrib_2 to 120
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'UPDATE_BLC_ATTRIBUTES'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE AddProformaNotes( pi_Context     IN     SrvContext,
                            pio_OutContext IN OUT SrvContext,
                            pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg      SrvErrMsg;
    l_table_name     VARCHAR2(30);
    l_pk_value       NUMBER;
    l_attrib_2       VARCHAR2(4000);
    l_sbstr_attrib   VARCHAR2(120 CHAR);
BEGIN
    -- Getting data from context
    srv_context.GetContextAttrChar( pi_Context, 'TABLE_NAME', l_table_name );
    srv_context.GetContextAttrNumber( pi_Context, 'PK_VALUE', l_pk_value );
    l_attrib_2 := srv_prm_process.Get_Attrib_2( pi_Context );
    --
    cust_util_pkg.Add_Proforma_Notes( pi_table_name  => l_table_name,
                                      pi_pk_value    => l_pk_value,
                                      pi_text        => l_attrib_2,
                                      po_sbstr_text  => l_sbstr_attrib,
                                      pio_Err        => pio_Err );
    --
    IF l_sbstr_attrib IS NOT NULL
    THEN
        pio_OutContext := pi_Context;
        srv_prm_process.Set_Attrib_2( pio_OutContext,l_sbstr_attrib );
    END IF;
EXCEPTION WHEN OTHERS THEN
    pio_OutContext := NULL;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.AddProformaNotes', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END AddProformaNotes;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.MassDeleteProformaBill
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.06.2019  creation - LPVS-111
--
-- Purpose:  Executes procedure for delete all unpaid and without AD number
-- proformas related to given item and annex and override bill method with
-- CANCEL for cancellation annex
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - ITEM_IDS           VARCHAR2  Item Ids;
--      - ANNEX_ID           NUMBER    Annex Id;
--      - BILL_METHOD        VARCHAR2  Billing method;
--     pio_OutContext   SrvContext   Collection of object's attributes;
--     pio_Err          SrvErr       Specifies structure for passing back the
--                                   error code, error TYPE and corresponding
--                                   message.
--
-- Output parameters:
--     pio_OutContext   SrvContext   Collection of object's attributes;
--      - BILL_METHOD        VARCHAR2  Billing method;
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
-- Dependences: Service is associated with event 'RUN_BLC_IMMEDIATE_BILLING'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE MassDeleteProformaBill ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_annex_id         NUMBER;
    l_item_ids         VARCHAR2(2000);
    l_bill_method      VARCHAR2(30);
  BEGIN
      -- Getting data from context
      l_item_ids := srv_prm_process.Get_Item_Ids( pi_Context );
      l_annex_id := srv_prm_process.Get_Annex( pi_Context );
      l_bill_method := srv_prm_process.Get_Bill_Method( pi_Context );

      cust_billing_pkg.Mass_Delete_Proforma_Bill
                     ( pi_item_ids              => l_item_ids,
                       pi_annex_id              => l_annex_id,
                       pio_bill_method          => l_bill_method,
                       pio_Err                  => pio_Err);

      pio_OutContext := pi_Context;
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
      ELSE
         srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_ok );
         srv_prm_process.Set_Bill_Method( pio_OutContext, l_bill_method );
      END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.MassDeleteProformaBill', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      srv_prm_process.Set_Procedure_Result( pio_OutContext, blc_gvar_process.flg_err );
END MassDeleteProformaBill;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.MassUpdateProforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.08.2019  creation -LPV-2000
--
-- Purpose:  Executes procedure for update all unpaid proformas for change
-- agent annex
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - POLICY_ID          NUMBER    Policy Id;
--      - ANNEX_ID           NUMBER    Annex Id;
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
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'CONFIRM_ANNEX_CHANGE'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE MassUpdateProforma ( pi_Context IN SrvContext,
                               pio_OutContext IN OUT SrvContext,
                               pio_Err IN OUT SrvErr )
  IS
    l_SrvErrMsg        SrvErrMsg;
    l_policy_id        NUMBER;
    l_annex_id         NUMBER;
  BEGIN
      -- Getting data from context
      srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );
      srv_context.GetContextAttrNumber( pi_Context, 'ANNEX_ID', l_annex_id );

      cust_billing_pkg.Mass_Update_Proforma
                     ( pi_policy_id             => l_policy_id,
                       pi_annex_id              => l_annex_id,
                       pio_Err                  => pio_Err);

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         Srv_Context.SetContextAttr( pio_OutContext, 'PROCEDURE_RESULT', 'VARCHAR2', NULL, 'FALSE' );
      ELSE
         Srv_Context.SetContextAttr( pio_OutContext, 'PROCEDURE_RESULT', 'VARCHAR2', NULL, 'TRUE' );
      END IF;

END MassUpdateProforma;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.UpdateItemDueDate
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.08.2019  creation - CON94S-9
--
-- Purpose: Update fixed due date - blc_items.attrib_8 with new annex reason -
--          Change Payment due date (PAYDUEDATE)
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - POLICY_ID          NUMBER    Policy Id;
--      - ANNEX_ID           NUMBER    Annex Id;
--      - STAGE              VARCHAR2
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
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'APPLY_ANNEX_CHANGE'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE UpdateItemDueDate( pi_Context     IN     SrvContext,
                             pio_OutContext IN OUT SrvContext,
                             pio_Err        IN OUT SrvErr )
IS
    l_policy_id     NUMBER;
    l_annex_id      NUMBER;
    l_stage         VARCHAR2(30);
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );
    srv_context.GetContextAttrNumber( pi_Context, 'ANNEX_ID', l_annex_id );
    srv_context.GetContextAttrChar ( pi_Context, 'STAGE', l_stage );
    --
    IF NOT cust_billing_pkg.Update_Item_Due_Date( l_policy_id, l_annex_id, l_stage, pio_Err )
    THEN
        Srv_Context.SetContextAttr( pio_OutContext, 'PROCEDURE_RESULT', 'VARCHAR2', NULL, 'FALSE' );
    ELSE
        Srv_Context.SetContextAttr( pio_OutContext, 'PROCEDURE_RESULT', 'VARCHAR2', NULL, 'TRUE' );
    END IF;
END UpdateItemDueDate;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.RunBillingPayWayChange
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.12.2020  creation - CON94S-55
--
-- Purpose: Execute rum immediate billing for pay way change annex
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - POLICY_ID          NUMBER    Policy Id;
--      - ANNEX_ID           NUMBER    Annex Id;
--      - STAGE              VARCHAR2  Stage;
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
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'APPLY_ANNEX_CHANGE'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE RunBillingPayWayChange( pi_Context     IN     SrvContext,
                                  pio_OutContext IN OUT SrvContext,
                                  pio_Err        IN OUT SrvErr )
IS
    l_policy_id     NUMBER;
    l_annex_id      NUMBER;
    l_stage         VARCHAR2(30);
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );
    srv_context.GetContextAttrNumber( pi_Context, 'ANNEX_ID', l_annex_id );
    srv_context.GetContextAttrChar ( pi_Context, 'STAGE', l_stage );
    --
    cust_billing_pkg.Run_Billing_PayWay_Change
        (pi_policy_id         => l_policy_id,
         pi_annex_id          => l_annex_id,
         pi_stage             => l_stage,
         pio_Err              => pio_Err);

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        Srv_Context.SetContextAttr( pio_OutContext, 'PROCEDURE_RESULT', 'VARCHAR2', NULL, 'FALSE' );
    ELSE
        Srv_Context.SetContextAttr( pio_OutContext, 'PROCEDURE_RESULT', 'VARCHAR2', NULL, 'TRUE' );
    END IF;
END RunBillingPayWayChange;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.ValidateNewAdjTrx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.09.2021  creation - LAP85-132
--
-- Purpose: Validate amount on manual transactions
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
--      - TRANSACTION_ID    NUMBER    Transaction Id;
--      - TRANSACTION_TYPE  VARCHAR2  Transaction type;
--      - AMOUNT            NUMBER    Amount;
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
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'CREATE_BLC_TRANSACTION', 'MODIFY_BLC_TRANSACTION'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE ValidateNewAdjTrx( pi_Context     IN     SrvContext,
                             pio_OutContext IN OUT SrvContext,
                             pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg           SrvErrMsg;
    --
    l_trx_id      blc_transactions.transaction_id%TYPE;
    l_trx_type    blc_transactions.transaction_type%TYPE;
    l_amount      blc_transactions.amount%TYPE;
BEGIN
    srv_context.GetContextAttrNumber( pi_Context, 'TRANSACTION_ID', l_trx_id );
    srv_context.GetContextAttrChar( pi_Context, 'TRANSACTION_TYPE', l_trx_type );
    srv_context.GetContextAttrNumber( pi_Context, 'AMOUNT', l_amount );
    --
    cust_billing_pkg.Validate_New_Adj_Trx
        ( pi_trx_id    => l_trx_id,
          pi_trx_type  => l_trx_type,
          pi_amount    => l_amount,
          pio_Err      => pio_Err);
     --
     pio_OutContext := pi_Context;
     --
EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.ValidateNewAdjTrx', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END ValidateNewAdjTrx;

--------------------------------------------------------------------------------
-- Name: srv_cust_bo.SetModifyTrxYes
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.09.2021  creation - LAP85-132
--
-- Purpose: Set parameter MODIFY_TRANS to Y,
--          to change the due date of the transactions
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies value data as attributes in
--                                  context;
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
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with event 'MODIFY_BLC_DOCUMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE SetModifyTrxYes( pi_Context     IN     SrvContext,
                           pio_OutContext IN OUT SrvContext,
                           pio_Err        IN OUT SrvErr )
IS
    l_SrvErrMsg           SrvErrMsg;
BEGIN
    pio_OutContext := pi_Context;
    --
    srv_context.SetContextAttrChar( pio_OutContext, 'MODIFY_TRANS', blc_gvar_process.FLG_YES );
    --
EXCEPTION
    WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'srv_cust_bo.SetModifyTrxYes', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END SetModifyTrxYes;
--
END srv_cust_bo;
/