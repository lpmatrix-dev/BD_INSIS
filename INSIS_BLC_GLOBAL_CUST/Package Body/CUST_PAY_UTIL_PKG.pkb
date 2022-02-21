CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_PAY_UTIL_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during payment process
--------------------------------------------------------------------------------

--==============================================================================
--               *********** Local Trace Routine **********
--==============================================================================
C_LEVEL_STATEMENT     CONSTANT NUMBER := 1;
C_LEVEL_PROCEDURE     CONSTANT NUMBER := 2;
C_LEVEL_EVENT         CONSTANT NUMBER := 3;
C_LEVEL_EXCEPTION     CONSTANT NUMBER := 4;
C_LEVEL_ERROR         CONSTANT NUMBER := 5;
C_LEVEL_UNEXPECTED    CONSTANT NUMBER := 6;

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_pay_util_pkg';
--==============================================================================

--------------------------------------------------------------------------------
-- Name: cust_pmnt_util_pkg.Validate_Pmnt_Appl
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.01.2017  creation
--
-- Purpose:  Execute procedure of validation of payment application details
-- and return doc_id if payment have to be applied on particular document
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_remittance_ids      VARCHAR2     List of remittance id
--     pi_unapply             VARCHAR2     Unapply mode - set to 'Y' for
--                                         validataion of unapply
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_doc_id              NUMBER       Document Identifier
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In pre-validate and pre-apply payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Pmnt_Appl
   (pi_payment_id        IN     NUMBER,
    pi_remittance_ids    IN     VARCHAR2,
    pi_unapply           IN     VARCHAR2 DEFAULT 'N',
    po_doc_id            OUT    NUMBER,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_payment             blc_payments_type;
    l_remittance_ids      BLC_SELECTED_OBJECTS_TABLE;
    l_count_rm            PLS_INTEGER := 0;
    l_doc                 blc_documents_type;
    l_doc_open_balance    NUMBER;
    --
    l_payment_class       VARCHAR2(30);
    l_acc_class           VARCHAR2(30);
    l_run_list            VARCHAR2(2000);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Validate_Pmnt_Appl';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Validate_Pmnt_Appl');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_remittance_ids = '||pi_remittance_ids);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_unapply = '|| pi_unapply);

    l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
    END IF;

    SELECT bl.tag_0, bld.tag_8
    INTO l_payment_class, l_acc_class
    FROM blc_bacc_usages bu,
         blc_lookups bl,
         blc_lookups bld
    WHERE bu.usage_id = l_payment.usage_id
    AND bu.pay_method = bl.lookup_id
    AND bu.document_type = bld.lookup_id (+);

    /*
    IF pi_remittance_ids IS NOT NULL
    THEN
       l_remittance_ids := blc_common_pkg.convert_list(pi_remittance_ids);
    ELSE
       l_remittance_ids := NULL;
    END IF;
    */
    l_remittance_ids := NULL; -- check all remittances because of form bug which wrongly create remittances list

    --IF l_payment_class = 'IW' and l_acc_class = 'PREMIUM' --16.11.2017
    IF l_payment_class IN ('IW','OW') and l_acc_class IN ('PREMIUM','CO','RI')
    THEN
      FOR c_rmtn IN (SELECT nvl(br.matching_class, bp.matching_class) matching_class,
                            nvl(br.billing_reference, bp.billing_reference) billing_reference,
                            br.remittance_id,
                            nvl(br.activity_id, bp.activity_id) activity_id,
                            nvl(br.withheld_amount, 0) withheld_amount
                     FROM blc_payments bp,
                          blc_remittances br
                     WHERE bp.payment_id = pi_payment_id
                     AND bp.payment_id = br.payment_id (+)
                     AND ( l_remittance_ids IS NULL OR br.remittance_id IN ( SELECT * FROM TABLE(l_remittance_ids) ) )
                     AND nvl(br.status,'A') = 'A'
                     AND blc_common_pkg.Get_Lookup_Code(nvl(br.matching_class, bp.matching_class)) = 'ON_TRX_B')
      LOOP
         l_count_rm := l_count_rm + 1;

         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_STATEMENT,
                                    'c_rmtn.remittance_id = '||c_rmtn.remittance_id);

         IF c_rmtn.billing_reference IS NULL
         THEN
            IF c_rmtn.remittance_id IS NOT NULL
            THEN
               srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Not_Rem_Reference', c_rmtn.remittance_id );
               srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
            ELSE
               srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Not_Pmnt_Reference');
               srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
            END IF;
         ELSE
            l_doc := blc_documents_type(to_number(c_rmtn.billing_reference));

            IF blc_common_pkg.get_lookup_code(l_doc.doc_type_id) IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE)
            THEN
               IF pi_unapply = 'Y'
               THEN
                  /* --no need to delete AD number when reverse
                  IF l_doc.doc_suffix IS NOT NULL
                  THEN
                     srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.InvADnumber' );
                     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                  END IF;
                  */
                  po_doc_id := l_doc.doc_id;
               ELSIF l_doc.doc_suffix IS NULL
               THEN
                  srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.NoADnumber' );
                  srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
               END IF;
            END IF;

            IF nvl(pi_unapply,'N') = 'N'
            THEN
              IF l_doc.status NOT IN ('A','F')
              THEN
                 srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'blc_refund_util_pkg.CPD.Invalid_Status' );
                 srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                 /*
                 blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                            'l_doc.doc_id = '||l_doc.doc_id||' - '||
                                            'Document status is not proper for pay!');
                 */
              END IF;

              l_run_list := blc_appl_util_pkg.Get_Pmnt_Run_Agr_Doc
                               (pi_agreement      => NULL,
                                pi_doc_id         => l_doc.doc_id);

              IF l_run_list IS NOT NULL
              THEN
                 srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'appl_util_pkg.ACM.InitPmntRunDoc', l_doc.doc_id||'|'||l_run_list );
                 srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                 /*
                 blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                          'l_doc.doc_id = '||l_doc.doc_id||' - '||
                                          'There are transactions for the document which are selected in payment run(s) '||l_run_list);
                 */
              END IF;

              IF l_doc.currency <> l_payment.currency
              THEN
                 srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Diff_Doc_Currency', l_doc.currency );
                 srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              END IF;

              --l_doc_open_balance := blc_doc_util_pkg.Get_Doc_Open_Balance(l_doc.doc_id, l_doc.currency);
              l_doc_open_balance := blc_doc_util_pkg.Get_Doc_Open_Balance_2(l_doc.doc_id, l_payment.currency, nvl(nvl(l_payment.rate_date,l_payment.value_date), l_payment.payment_date), nvl(l_payment.rate_type,'FIXING'));

              IF l_doc.doc_class = 'B' AND abs(l_doc_open_balance) <> l_payment.amount OR l_doc.doc_class = 'L' AND l_doc_open_balance*(-1) <> l_payment.amount
              THEN
                 srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Diff_Doc_Balance', l_doc_open_balance );
                 srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              END IF;
            END IF;
         END IF;
      END LOOP;

      IF l_count_rm = 0
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Not_Pmnt_Reference');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      END IF;

      IF l_count_rm > 1
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Many_Pmnt_Reference');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      END IF;

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         RETURN;
      ELSE
         po_doc_id := l_doc.doc_id;
      END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Validate_Pmnt_Appl');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Validate_Pmnt_Appl;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Pre_Validate_Payment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.01.2017  creation
--
-- Purpose: Execute procedure of custom validation of payment
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pio_action_notes       VARCHAR2     Action notes
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_action_notes       VARCHAR2     Action notes
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In validate payment before standard payment validation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Validate_Payment
   (pi_payment_id        IN     NUMBER,
    pio_action_notes     IN OUT VARCHAR2,
    pio_procedure_result IN OUT VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_payment             BLC_PAYMENTS_TYPE;
    l_payment_class       VARCHAR2(30);
    l_acc_class           VARCHAR2(30);
    l_pay_method          VARCHAR2(30);
    l_party_name          VARCHAR2(500);
    l_SrvErr              SrvErr;
    l_doc_id              NUMBER;
    l_count_bsl           PLS_INTEGER;
    l_holder_party        VARCHAR2(30);
    --
    CURSOR c_doc_party ( x_doc_id IN NUMBER ) IS
    SELECT ba.party
    FROM blc_transactions bt,
         blc_accounts ba
    WHERE bt.doc_id = x_doc_id
    AND bt.status NOT IN ('D','R','C')
    AND bt.account_id = ba.account_id;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Pre_Validate_Payment';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Pre_Validate_Payment');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_action_notes = '||pio_action_notes);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_procedure_result = '||pio_procedure_result);

    l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'l_payment_status = '||l_payment.status);

    SELECT bl.tag_0, bld.tag_8, bl.lookup_code
    INTO l_payment_class, l_acc_class, l_pay_method
    FROM blc_bacc_usages bu,
         blc_lookups bl,
         blc_lookups bld
    WHERE bu.usage_id = l_payment.usage_id
    AND bu.pay_method = bl.lookup_id
    AND bu.document_type = bld.lookup_id (+);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'l_payment_class = '||l_payment_class);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'l_acc_class = '||l_acc_class);
    --
    IF l_payment.status = 'I' AND (pio_procedure_result IS NULL OR pio_procedure_result = blc_gvar_process.flg_ok) AND l_payment_class IN ('IW','OW') AND l_acc_class = 'PREMIUM'
    THEN
       --validate applications
       Validate_Pmnt_Appl
                      (pi_payment_id        => pi_payment_id,
                       pi_remittance_ids    => NULL,
                       po_doc_id            => l_doc_id,
                       pio_Err              => l_SrvErr);

       SELECT count(*)
       INTO l_count_bsl
       FROM blc_bank_statement_lines
       WHERE payment_id = pi_payment_id
       AND operation_type = 'CREDIT_TRANSFER';

       IF l_count_bsl > 0
       THEN
          OPEN c_doc_party(l_doc_id);
            FETCH c_doc_party
            INTO l_holder_party;
          CLOSE c_doc_party;
          --
          IF l_holder_party IS NOT NULL AND l_holder_party <> l_payment.party
          THEN
              l_payment.party := l_holder_party;

              IF NOT l_payment.update_blc_payments( l_SrvErr )
              THEN
                 NULL;
              END IF;
          ELSIF l_holder_party = l_payment.party
          THEN
              l_payment.payment_address := NULL;

              IF NOT l_payment.update_blc_payments( l_SrvErr )
              THEN
                 NULL;
              END IF;
          END IF;
       END IF;

       IF NOT srv_error.rqStatus( l_SrvErr )
       THEN
          blc_pmnt_process_pkg.Add_Err_Note(pio_action_notes, l_SrvErr);

          FOR i IN 1..l_SrvErr.COUNT
          LOOP
             blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_payment_id = '||pi_payment_id||' - '||l_SrvErr(i).errtype||' - '||l_SrvErr(i).errmessage);
          END LOOP;

          pio_procedure_result := blc_gvar_process.flg_err;
       END IF;

    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pio_action_notes = '||pio_action_notes);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Pre_Validate_Payment');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pre_Validate_Payment', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Pre_Validate_Payment;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Check_Receipt
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.05.2013  creation
--              11.05.2015  RQ1000009807 Add refresh payment variable after
--                          validate_payment (move from apply_receipt because
--                          add Check_Receipt in Apply_remittances (bug) ),
--                          and check status after validate
--                          change parameter pi_payment - In/Out
--              07.07.2015  RQ1000009921 Check status of payment to not be
--                          Deleted or Reversed
--              07.05.2017  Copy from core
--
-- Purpose: In the begining on apply procedures important init global parameters
--          Ledger, Org_id, Receipt currency
--
--
-- Input parameters:
--     pi_payment                          Related payment record (required)
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In procedures Apply_Receipts and Apply_Remittances
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Check_Receipt
    ( pio_payment      IN OUT BLC_PAYMENTS_TYPE,
      pio_Err          IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Check_Receipt';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Check_Receipt');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'payment_id = '||pio_payment.payment_id);
    --
    IF SUBSTR(pio_payment.payment_class,1,1) <> 'I' AND pio_payment.payment_class <> 'OW' --28.02.2018
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Check_Receipt','blc_pay_util_pkg.CR.ErrClass', pio_payment.payment_class );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,
            'payment_id = '||pio_payment.payment_id||' - '|| 'Invalid payment class - '||pio_payment.payment_class||'. The payment class must be "Incoming".');
        RETURN;
    END IF;
    --
    IF pio_payment.status = 'I'
    THEN
        blc_appl_util_pkg.Validate_Payment
            ( pi_payment_id  => pio_payment.payment_id,
              pio_Err        => pio_Err );
        IF NOT srv_error.rqStatus( pio_Err )
        THEN RETURN;
        END IF;
    END IF;
    -- Begin RQ1000009807
    -- Refresh payment variable if something change in check receipt procedure
    pio_payment := NEW blc_payments_type(pio_payment.payment_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    IF pio_payment.status = 'I'
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Check_Receipt','blc_pay_util_pkg.CR.ErrSt' );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION, 'payment_id = '||pio_payment.payment_id||' - '|| 'Can not apply receipt with status "Initial".');
        RETURN;
    END IF;
    --End RQ1000009807

    -- Begin RQ1000009921
    IF pio_payment.status = 'D'
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Check_Receipt','blc_pay_util_pkg.CR.Is_Deleted' );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION, 'payment_id = '||pio_payment.payment_id||' - '|| 'Can not apply receipt in status "Deleted".');
        RETURN;
    END IF;

    IF pio_payment.status = 'R'
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Check_Receipt','blc_pay_util_pkg.CR.Is_Reversed' );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION, 'payment_id = '||pio_payment.payment_id||' - '|| 'Can not apply receipt in status "Reversed".');
        RETURN;
    END IF;
    -- End RQ1000009921
    --
    IF pio_payment.open_balance <= 0
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Check_Receipt','blc_pay_util_pkg.CR.ErrOB', pio_payment.open_balance );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,
            'payment_id = '||pio_payment.payment_id||' - '|| 'Open balance on the receipt is '||pio_payment.open_balance);
        RETURN;
    END IF;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Check_Receipt');
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_pay_util_pkg.Check_Receipt', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_payment_id = '||pio_payment.payment_id||' - '||SQLERRM);
END Check_Receipt;

--------------------------------------------------------------------------------
-- Name: blc_pay_util_pkg.Init_Receipt_Global_Params
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.05.2017  creation - copy from core
--
-- Purpose: In the begining on apply procedures important init global parameters
--          Ledger, Org_id, Receipt currency
--
--
-- Input parameters:
--     pi_payment                          Related payment record (required)
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In procedures Apply_Receipts and Apply_Remittances
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Init_Receipt_Global_Params
    ( pi_payment       IN     BLC_PAYMENTS_TYPE,
      pio_Err          IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Init_Receipt_Global_Params';
    --
    IF pi_payment.legal_entity IS NULL
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Init_Receipt_Global_Params',
                                           'blc_pay_util_pkg.AR.No_LE' );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,'Legal Entity is not specified');
        RETURN;
    END IF;
    --
    -- Init Legal Entity
    blc_appl_cache_pkg.Init_Le( pi_payment.legal_entity, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    -- Init Org ID
    blc_appl_cache_pkg.Init_Org( pi_payment.org_id );
    --
    -- Init receipt currency
    blc_appl_cache_pkg.Init_Rec_Currency( pi_payment.currency );
END;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Apply_Receipt_On_Doc
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.15.2017  creation
--     Fadata   15.02.2018  changed - call custom Accumulate_Reminders
--
-- Purpose: Execute procedure of receipt application on billing reference
-- document if given or standard apply receipt/remittances if not given
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment Id (required);
--     pi_remittance_ids      VARCHAR2     List of remittance id;
--     pi_doc_id              NUMBER       Document Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns: N/A
--
-- Usage: In UI when need to apply receipt (button Apply Receipt).
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Apply_Receipt_On_Doc
    ( pi_payment_id        IN     NUMBER,
      pi_remittance_ids    IN     VARCHAR2,
      pi_doc_id            IN     NUMBER,
      pio_Err              IN OUT SrvErr)
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_payment             BLC_PAYMENTS_TYPE;
    l_payment_end         BLC_PAYMENTS_TYPE;
    l_doc_balance         NUMBER;
    l_unappl_amount       NUMBER;
    l_fc_unappl_amount    NUMBER;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    l_log_module := C_DEFAULT_MODULE||'.Apply_Receipt_On_Doc';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Apply_Receipt_On_Doc');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_remittance_ids = '||pi_remittance_ids);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_doc_id = '||pi_doc_id);
    --
    IF pi_payment_id IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Receipt_On_Doc', 'blc_pmnt_util_pkg.APON.No_PaymentId');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'Payment Id is not specified');
       RETURN;
    END IF;

    IF pi_doc_id IS NOT NULL
    THEN
      l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                          'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          RETURN;
      END IF;

      -- Check receipt class, opan_balance, status
      Check_Receipt( l_payment, pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN RETURN;
      END IF;

      -- Init LE, Org_ID and Rec_Currency
      Init_Receipt_Global_Params( l_payment, pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN RETURN;
      END IF;

      BLC_APPL_UTIL_PKG.Lock_Transactions
      (  PI_SOURCE => NULL,
         PI_AGREEMENT => NULL,
         PI_COMPONENT => NULL,
         PI_DETAIL => NULL,
         PI_ITEM_ID => NULL,
         PI_DOC_ID => PI_DOC_ID,
         PI_TRX_ID => NULL,
         PI_PARTY => NULL,
         PI_ACCOUNT_ID => NULL,
         PIO_ERR => PIO_ERR);

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                      'pi_doc_id = '||pi_doc_id||' - '||
                                       pio_Err(pio_Err.FIRST).errmessage);
         RETURN;
      END IF;

      BLC_APPL_UTIL_PKG.Select_Trx_For_Apply
         (  PI_SOURCE => NULL,
            PI_AGREEMENT => NULL,
            PI_COMPONENT => NULL,
            PI_DETAIL => NULL,
            PI_ITEM_ID => NULL,
            PI_DUE_DATE => NULL,
            PI_DOC_ID => pi_doc_id,
            PI_TRX_ID => NULL,
            PI_PARTY => NULL,
            PI_ACCOUNT_ID => NULL,
            PI_PROCESS => 'PAY_DOC',
            PIO_ERR => PIO_ERR) ;

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                     'pi_doc_id = '||pi_doc_id||' - '||
                                      pio_Err(pio_Err.FIRST).errmessage);
         RETURN;
      END IF;

      --this check is not needed because it is done in pre validate using payment currency and rate
      /*
      SELECT nvl(sum(bt.balance),0)
      INTO l_doc_balance
      FROM TABLE(blc_appl_cache_pkg.g_trx_table) bt;

      IF l_doc_balance = 0 OR abs(l_doc_balance) <> l_payment.open_balance
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Appl', 'cust_pay_util_pkg.VPA.Diff_Doc_Balance', l_doc_balance );
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         RETURN;
      END IF;
      */

      l_unappl_amount := l_payment.open_balance;
      l_fc_unappl_amount := round(l_payment.open_balance*l_payment.rate, blc_appl_cache_pkg.g_fc_precision);

      /* Apply transactions to payment */
      --blc_appl_util_pkg.Accumulate_Reminders  --15.02.2018 - replace with custom Accumulate_Reminders
      Accumulate_Reminders
                 ( pi_payment_id,
                   l_payment.rate,
                   l_payment.rate_date,
                   l_payment.rate_type,
                   blc_appl_cache_pkg.g_to_date,
                   l_payment.rate_date,
                   NULL,
                   NULL, --pi_limit_amount,
                   pi_doc_id,
                   NULL,
                   l_unappl_amount,
                   l_fc_unappl_amount,
                   pio_Err);
       --
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                     'pi_doc_id = '||pi_doc_id||' - '||
                                      pio_Err(pio_Err.FIRST).errmessage);
          RETURN;
       END IF;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_unappl_amount = '||l_unappl_amount);
     ELSE
        IF pi_remittance_ids IS NULL
        THEN
           blc_pay_util_pkg.Apply_Receipt(pi_payment_id,
                                          pio_Err);
        ELSE
           blc_pay_util_pkg.Apply_Remittances
                      ( pi_payment_id,
                        pi_remittance_ids,
                        pio_Err);
        END IF;
     END IF;

     blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Apply_Receipt_On_Doc');
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'blc_pay_util_pkg.Apply_Receipt_On_Doc', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                    'pi_payment_id = '||pi_payment_id||' - '|| SQLERRM);
END Apply_Receipt_On_Doc;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Check_SYSADMIN_User
--
-- Type: PROCEDURE
--
-- Subtype: DATA_SET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.07.2017  creation
--
-- Purpose: Check if context user is defined in the lookup set BLC_SYSADMINS
--
-- Input parameters:
--     pi_org_id       NUMBER     Organization Id
--     pi_to_date      VARCHAR2   To date
--     pio_Err         SrvErr     Specifies structure for passing back
--                                the error code, error TYPE and
--                                corresponding message.
--
-- Output parameters:
--     pio_Err         SrvErr     Specifies structure for passing back
--                                the error code, error TYPE and
--                                corresponding message.
--
-- Usage: In validation of reverse reason and cancel preliminary mark
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Check_SYSADMIN_User
   (pi_org_id         IN     NUMBER,
    pi_to_date        IN     DATE,
    pio_Err           IN OUT SrvErr)
IS
    l_log_module     VARCHAR2(240);
    l_user_name      VARCHAR2(100);
    l_user_lookup_id NUMBER;
    l_SrvErr         SrvErr;
    l_SrvErrMsg      SrvErrMsg;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Check_SYSADMIN_User';
    l_user_name := insis_context.get_user;

    l_user_lookup_id := blc_common_pkg.Get_Lookup_Value_Id
                            ( pi_lookup_name => 'BLC_SYSADMINS',
                              pi_lookup_code => l_user_name,
                              pio_ErrMsg     => l_SrvErr,
                              pi_org_id      => pi_org_id,
                              pi_to_date     => pi_to_date);
     IF l_user_lookup_id IS NULL
     THEN
        srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pmnt_util_pkg.Is_SYSADMIN_User', 'cust_pmnt_util_pkg.VRR.No_SYS_User',l_user_name);
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     END IF;

END Check_SYSADMIN_User;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Validate_Reverse_Reason
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.07.2017  creation
--
-- Purpose: Validate if reason is proper for reverse for given payment_id.
--
-- Input parameters:
--     pi_payment_id          NUMBER     Document identifier (required)
--     pi_reason_id           NUMBER     Reason for reverse
--                                       lookup id for lookup_set
--                                       PMNT_REVERSE_REASON
--     pi_manual_flag         VARCHAR2   Manual flag M/A
--     pi_log_messages        VARCHAR2   Log error mesages Y/N
--                                       empty means Y
--     pio_Err                SrvErr     Specifies structure for passing back
--                                       the error code, error TYPE and
--                                       corresponding message.
--
-- Output parameters:
--     po_new_status         VARCHAR2    Change to the new status instead of
--                                       Reverse
--     pio_Err               SrvErr      Specifies structure for passing back
--                                       the error code, error TYPE and
--                                       corresponding message.
--
-- Usage: In UI when need to reverse a payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
-------------------------------------------------------------------------------
PROCEDURE Validate_Reverse_Reason
   (pi_payment_id     IN     NUMBER,
    pi_reason_id      IN     NUMBER,
    pi_manual_flag    IN     VARCHAR2,
    pi_log_messages   IN     VARCHAR2 DEFAULT 'Y',
    po_new_status     OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr)
IS
    l_log_module     VARCHAR2(240);
    l_SrvErrMsg      SrvErrMsg;
    l_payment        BLC_PAYMENTS_TYPE;
    l_lookup         BLC_LOOKUPS_TYPE;
    l_log_messages   VARCHAR2(30);
    l_pay_method_ids BLC_SELECTED_OBJECTS_TABLE;
    l_usage_ids      BLC_SELECTED_OBJECTS_TABLE;
    l_count          PLS_INTEGER;
    l_SrvErr         SrvErr;
    l_status_list    VARCHAR2(100);
    l_manual_flag    VARCHAR2(1);
    --
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Validate_Reverse_Reason';

    l_log_messages := nvl(pi_log_messages,'Y');

    l_manual_flag := pi_manual_flag;

    IF l_log_messages = 'Y'
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Validate_Reverse_Reason');
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_payment_id = '||pi_payment_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_reason_id = '||pi_reason_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_manual_flag = '||pi_manual_flag);
    END IF;

    IF pi_payment_id IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_Open', 'blc_pmnt_util_pkg.VPO.No_PaymentId');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       RETURN;
    END IF;

    IF pi_reason_id IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.No_Reason');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       RETURN;
    END IF;

    l_payment := blc_payments_type(pi_payment_id, pio_Err);

    l_lookup := blc_lookups_type(pi_reason_id, pio_Err);

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    IF l_lookup.attrib_1 = 'SYS'
    THEN
       Check_SYSADMIN_User
           (pi_org_id         => l_payment.org_id,
            pi_to_date        => nvl(l_payment.voucher_date,trunc(sysdate)),
            pio_Err           => pio_Err);
    END IF;
    --
    IF l_lookup.attrib_3 = 'R'
    THEN
       SELECT bl.attrib_5
       INTO l_status_list
       FROM blc_bacc_usages bu,
            blc_lookups bl
       WHERE bu.usage_id = l_payment.usage_id
       AND bu.pay_method = bl.lookup_id;

       IF l_status_list IS NOT NULL AND instr(l_status_list, l_payment.status) = 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Not_Proper_Status',l_payment.status||'|'||l_status_list);
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
    END IF;

    IF l_lookup.attrib_4 IS NOT NULL AND instr(l_lookup.attrib_4, l_payment.payment_class) = 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Not_Proper_Class',l_payment.payment_class||'|'||l_lookup.attrib_4);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_lookup.attrib_5 IS NOT NULL
    THEN
       l_pay_method_ids := blc_common_pkg.convert_list(l_lookup.attrib_5);

       SELECT count(*)
       INTO l_count
       FROM blc_bacc_usages bau
       WHERE bau.usage_id = l_payment.usage_id
       AND bau.pay_method IN (SELECT * FROM TABLE(l_pay_method_ids));

       IF l_count = 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Not_Proper_Method' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
    END IF;

    IF l_lookup.attrib_6 IS NOT NULL AND substr(l_lookup.attrib_6,1,1) <>'-'
    THEN
       l_usage_ids := blc_common_pkg.convert_list(l_lookup.attrib_6);

       SELECT count(*)
       INTO l_count
       FROM blc_bacc_usages bau
       WHERE bau.usage_id = l_payment.usage_id
       AND bau.usage_id IN (SELECT * FROM TABLE(l_usage_ids));

       IF l_count = 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Not_Proper_Usage' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
    END IF;

    IF l_lookup.attrib_6 IS NOT NULL AND substr(l_lookup.attrib_6,1,1) = '-'
    THEN
       l_usage_ids := blc_common_pkg.convert_list(l_lookup.attrib_6);

       SELECT count(*)
       INTO l_count
       FROM blc_bacc_usages bau
       WHERE bau.usage_id = l_payment.usage_id
       AND (-1*bau.usage_id) IN (SELECT * FROM TABLE(l_usage_ids));
       IF l_count >0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Not_Proper_Usage' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
    END IF;

    IF l_lookup.attrib_7 IS NOT NULL AND l_manual_flag IS NOT NULL
    THEN
       IF l_lookup.attrib_7 <> l_manual_flag AND l_lookup.attrib_7 = 'M'
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_paying_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Only_Manual' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
       IF l_lookup.attrib_7 <> l_manual_flag AND l_lookup.attrib_7 = 'A'
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Only_Automatic' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
    END IF;

    IF l_lookup.attrib_8 IS NOT NULL AND instr(l_lookup.attrib_8, l_payment.status) = 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Reverse_Reason', 'cust_paying_pkg.VRR.Not_Proper_Status',l_payment.status||'|'||l_status_list);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF nvl(l_lookup.attrib_9,'R') <> 'R'
    THEN
       po_new_status := l_lookup.attrib_9;
    END IF;

    IF l_log_messages = 'Y'
    THEN
       IF pio_Err IS NOT NULL
       THEN
          FOR i IN 1..pio_Err.COUNT
          LOOP
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_EXCEPTION,
                                        'pi_payment_id = '||pi_payment_id||' - '||
                                        'pi_reason_id = '||pi_reason_id||' - '||pio_Err(i).errtype||' - '||pio_Err(i).errmessage);
          END LOOP;
       END IF;
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'po_new_status = '||po_new_status);
       blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_PROCEDURE,
                                 'END of procedure Validate_Reverse_Reason');
   END IF;
END Validate_Reverse_Reason;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Is_Allowed_Reverse_Reason
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.07.2017  Creation
--
-- Purpose: Calculate if given reverse reason is allowed for given payment
--
-- Input parameters:
--     pi_reason_id           NUMBER     Reason for reverse (required)
--                                       lookup id for lookup_set
--                                       PMNT_REVERSE_REASON
--     pi_payment_id          NUMBER     Payment identifier (required)
--
-- Returns:
--     TRUE - if allowed
--     FALSE - if not allowed
--
-- Usage: In UI to select proper reverse reasons for a payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
-------------------------------------------------------------------------------
FUNCTION Is_Allowed_Reverse_Reason
   (pi_reason_id      IN     NUMBER,
    pi_payment_id     IN     NUMBER)
RETURN BOOLEAN
IS
    l_log_module    VARCHAR2(240);
    l_SrvErr        SrvErr;
    l_new_status    VARCHAR2(1);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Is_Allowed_Reverse_Reason';

    Validate_Reverse_Reason
       (pi_payment_id     => pi_payment_id,
        pi_reason_id      => pi_reason_id,
        pi_manual_flag    => 'M',
        pi_log_messages   => 'N',
        po_new_status   => l_new_status,
        pio_Err           => l_SrvErr);

    IF NOT srv_error.rqStatus( l_SrvErr )
    THEN
       RETURN FALSE;
    END IF;

    RETURN TRUE;

END Is_Allowed_Reverse_Reason;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Pre_Reverse_Payment
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
-- Purpose: Execute custom procedure of pre reverse payment
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_reason_id           NUMBER       Reverse reason id - lookup_id
--     pi_manual_flag         VARCHAR2     Manual flag M/A
--     pi_reason_code         VARCHAR2     Reverse reason code - lookup_code
--     pi_notes               VARCHAR2     Reverse notes
--     pi_reversed_on         DATE         Reversed date
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_new_status          VARCHAR2    Change to the new status instead of
--                                        Reverse
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In UI when need to reverse payment
--
-- Exceptions: N/A
--
-- Dependences: /N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Reverse_Payment
   (pi_payment_id      IN     NUMBER,
    pi_reason_id       IN     NUMBER,
    pi_manual_flag     IN     VARCHAR2,
    pi_reason_code     IN     VARCHAR2,
    pi_notes           IN     VARCHAR2,
    pi_reversed_on     IN     DATE,
    po_new_status      OUT    VARCHAR2,
    pio_Err            IN OUT SrvErr)
IS
    l_log_module            VARCHAR2(240);
    l_SrvErrMsg             SrvErrMsg;
    l_payment               BLC_PAYMENTS_TYPE;
    l_reason_id             NUMBER;
    l_unapply_reason_code   VARCHAR2(30);
    l_unapply_reason_descr  VARCHAR2(240 CHAR);
    l_lookup                BLC_LOOKUPS_TYPE;
    l_lookup_id             NUMBER;
    l_status                VARCHAR2(1);
    l_reason                VARCHAR2(120);
    l_notes                 VARCHAR2(4000);
    l_reason_code           VARCHAR2(30);
    l_clearing_id           NUMBER;
    l_pmnt_action           BLC_PMNT_ACTIONS_TYPE;
    l_action_id             NUMBER;
    l_doc_id                NUMBER;
    l_procedure_result      VARCHAR2(30);
    l_doc_ids               VARCHAR2(2000);
    --
     CURSOR c_notes (x_reason_id IN NUMBER) IS
      SELECT lookup_code||' - '||meaning
      FROM blc_lookups
      WHERE lookup_id = x_reason_id;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Pre_Reverse_Payment';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Pre_Reverse_Payment');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reason_id = '||pi_reason_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_manual_flag = '||pi_manual_flag);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reason_code = '||pi_reason_code);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_notes = '||pi_notes);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reversed_on = '||to_char(pi_reversed_on,'dd-mm-yyyy'));

    l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
    END IF;
    --

    IF pi_reason_id IS NOT NULL
    THEN
       l_reason_id := pi_reason_id;
    ELSE
       l_reason_code := pi_reason_code;
       --
       l_reason_id := blc_common_pkg.Get_Lookup_Value_Id
                              ( pi_lookup_name => 'PMNT_REVERSE_REASON',
                                pi_lookup_code => l_reason_code,
                                pio_ErrMsg     => pio_Err,
                                pi_org_id      => l_payment.org_id,
                                pi_to_date     => trunc(nvl(pi_reversed_on,sysdate)));
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                    'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          RETURN;
       END IF;
    END IF;

    --validate deletion of AD number
    Validate_Pmnt_Appl
                 (pi_payment_id        => pi_payment_id,
                  pi_remittance_ids    => NULL,
                  pi_unapply           => 'Y',
                  po_doc_id            => l_doc_id,
                  pio_Err              => pio_Err);

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       FOR i IN 1..pio_Err.COUNT
       LOOP
          blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_payment_id = '||pi_payment_id||' - '||pio_Err(i).errtype||' - '||pio_Err(i).errmessage);
       END LOOP;

       RETURN;
    END IF;

    Validate_Reverse_Reason
         (pi_payment_id     => pi_payment_id,
          pi_reason_id      => l_reason_id,
          pi_log_messages   => 'Y',
          pi_manual_flag    => pi_manual_flag,
          po_new_status     => po_new_status,
          pio_Err           => pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    OPEN c_notes(l_reason_id);
        FETCH c_notes
        INTO l_notes;
    CLOSE c_notes;

    IF pi_notes IS NOT NULL
    THEN
       IF l_notes IS NULL
       THEN
          l_notes := pi_notes;
       ELSE
          l_notes := pi_notes||'; '||l_notes;
       END IF;
    END IF;

    --
    IF po_new_status IN ('H','F')
    THEN
       IF l_payment.status = 'C' AND blc_clearing_util_pkg.Get_Clear_Unclear_Status(pi_payment_id) <> 0
       THEN
          blc_clearing_util_pkg.Create_Unclearing_3
                                   (pi_payment_id       => pi_payment_id,
                                    pi_unclear_date     => pi_reversed_on,
                                    pi_clearing_id      => NULL,
                                    po_unclearing_id    => l_clearing_id,
                                    pio_Err             => pio_Err);

           l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);
           --
           cust_pay_util_pkg.Create_Acc_Event_Clear_Inst
                 (pi_clearing_id  => NULL,
                  pi_uncleared    => -99999,
                  pi_payment_id   => pi_payment_id,
                  pio_Err         => pio_Err);

           IF NOT srv_error.rqStatus( pio_Err )
           THEN
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                        'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
              RETURN;
           END IF;
       END IF;

       l_status := l_payment.status;

       IF po_new_status = 'H'
       THEN
         IF l_status = 'S' AND cust_pay_util_pkg.Is_Pmnt_Adv_Claim(pi_payment_id) = 'N' --CHA93S-8 add to not lock for advance claims
         THEN
            --IP - call service for lock payment in SAP
            cust_intrf_util_pkg.Lock_Pmnt_For_Reverse
                            (pi_payment_id        => pi_payment_id,
                             po_procedure_result  => l_procedure_result,
                             pio_Err              => pio_Err);

            IF l_procedure_result = cust_gvar.FLG_ERROR
            THEN
               IF NOT srv_error.rqStatus( pio_Err )
               THEN
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_EXCEPTION,
                                            'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
               ELSE
                  srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pre_Reverse_Payment', 'cust_pay_util_pkg.PRP.IP_Error');
                  srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_EXCEPTION,
                                            'pi_payment_id = '||pi_payment_id||' - '||'Integration for lock payment in SAP return error');
               END IF;
               --
               RETURN;
            END IF;
         END IF;
         IF l_status IN ('S','F')
         THEN
            blc_pmnt_util_pkg.Change_Payments_Status
                   (pi_payment_ids    => pi_payment_id,
                    pi_target_status  => NULL,
                    pi_notes          => NULL,
                    pi_undo_flag      => 'Y',
                    pi_changed_on     => pi_reversed_on,
                    po_changed_status => l_status,
                    pio_Err           => pio_Err);
         ELSIF l_status = 'H'
         THEN
            l_payment.status := 'A';
            IF NOT l_payment.update_blc_payments( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module,
                                            C_LEVEL_EXCEPTION,
                                            'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
               RETURN;
            END IF;
            --
            l_status := l_payment.status;
         END IF;

         IF l_status = 'S'
         THEN
            blc_pmnt_util_pkg.Change_Payments_Status
                   (pi_payment_ids    => pi_payment_id,
                    pi_target_status  => NULL,
                    pi_notes          => NULL,
                    pi_undo_flag      => 'Y',
                    pi_changed_on     => pi_reversed_on,
                    po_changed_status => l_status,
                    pio_Err           => pio_Err);
         END IF;

         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_EXCEPTION,
                                      'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            RETURN;
         END IF;

         blc_pmnt_util_pkg.Change_Payments_Status
                 (pi_payment_ids    => pi_payment_id,
                  pi_target_status  => 'H',
                  pi_notes          => l_notes,
                  pi_undo_flag      => 'N',
                  pi_changed_on     => pi_reversed_on,
                  po_changed_status => l_status,
                  pio_Err           => pio_Err);

         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_EXCEPTION,
                                      'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            RETURN;
         END IF;

         IF nvl(l_status,'A') <> 'H'
         THEN
            srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_paying_pkg.Pre_Reverse_Payment', 'cust_paying_pkg.PRP.Cannot_Hold');
            srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         END IF;
       END IF;
       --
       /* no need to update the payment for now
       l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);

       IF NOT l_payment.update_blc_payments( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_EXCEPTION,
                                      'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          RETURN;
       END IF;
       */

       SELECT MAX(ba.action_id)
       INTO l_action_id
       FROM blc_pmnt_actions ba
       WHERE ba.payment_id = pi_payment_id;

       l_pmnt_action := NEW blc_pmnt_actions_type(l_action_id);

       l_pmnt_action.reason_id := l_reason_id;
       l_pmnt_action.notes := nvl(l_pmnt_action.notes,l_notes);

       IF NOT l_pmnt_action.update_blc_pmnt_actions( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_EXCEPTION,
                                      'pi_payment_id = '||pi_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          RETURN;
       END IF;

    END IF;

    --add check for RI/CI bill documents
    FOR c_doc IN ( SELECT bd.doc_id
                   FROM blc_applications ba,
                        blc_transactions bt,
                        blc_documents bd,
                        blc_lookups bl
                   WHERE ba.source_payment = pi_payment_id
                   AND ba.target_trx = bt.transaction_id
                   AND bt.doc_id = bd.doc_id
                   AND bd.status = 'F'
                   AND bd.doc_type_id = bl.lookup_id
                   AND bl.lookup_code IN (cust_gvar.DOC_RI_BILL_TYPE,cust_gvar.DOC_CO_BILL_TYPE)
                   GROUP BY bd.doc_id )
     LOOP
        IF l_doc_ids IS NULL
        THEN
           l_doc_ids := c_doc.doc_id;
        ELSE
           l_doc_ids := l_doc_ids||', '||c_doc.doc_id;
        END IF;
     END LOOP;
     IF l_doc_ids IS NOT NULL
     THEN
        srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pre_Reverse_Payment', 'blc_pmnt_wf_pkg.RP.Formal_Doc', l_doc_ids );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_new_status = '||po_new_status);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Pre_Reverse_Payment');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pre_Reverse_Payment', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Pre_Reverse_Payment;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Reverse_Payment
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
-- Purpose: Execute core procedure of reverse payment only case that
-- the new status is null
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_reason_id           NUMBER       Reverse reason id - lookup_id
--     pi_reason_code         VARCHAR2     Reverse reason code - lookup_code
--     pi_notes               VARCHAR2     Reverse notes
--     pi_reversed_on         DATE         Reversed date
--     pi_execute_unclear     VARCHAR2     Execute unclear before reverse Y/N
--     pi_new_status          VARCHAR2     Change to the new status instead of
--                                         Reverse
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In UI when need to reverse payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Reverse_Payment
   (pi_payment_id      IN     NUMBER,
    pi_reason_id       IN     NUMBER,
    pi_reason_code     IN     VARCHAR2,
    pi_notes           IN     VARCHAR2,
    pi_reversed_on     IN     DATE,
    pi_execute_unclear IN     VARCHAR2,
    pi_new_status      IN     VARCHAR2,
    pio_Err            IN OUT SrvErr)
IS
    l_log_module      VARCHAR2(240);
    l_SrvErrMsg       SrvErrMsg;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Reverse_Payment';
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'BEGIN of procedure Reverse_Payment');
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_reason_id = '||pi_reason_id);
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_reason_code = '||pi_reason_code);
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_notes = '||pi_notes);
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_reversed_on = '||to_char(pi_reversed_on,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_execute_unclear = '||pi_execute_unclear);
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_new_status = '||pi_new_status);

    IF nvl(pi_new_status,'R') = 'R'
    THEN
       blc_pmnt_util_pkg.Reverse_Payment
         (pi_payment_id      => pi_payment_id,
          pi_reason_id       => pi_reason_id,
          pi_reason_code     => pi_reason_code,
          pi_notes           => pi_notes,
          pi_reversed_on     => pi_reversed_on,
          pi_execute_unclear => pi_execute_unclear,
          pio_Err            => pio_Err);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Reverse_Payment');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Reverse_Payment', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Reverse_Payment;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Modify_Pmnt_Activities
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Modify allowed activities for given payment
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_act_list            VARCHAR2     Activity list
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_act_list            VARCHAR2     Modified Activity list
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.

-- Usage: In UI when need calculate allowed activities
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Modify_Pmnt_Activities
   (pi_payment_id     IN     NUMBER,
    pi_act_list       IN     VARCHAR2,
    po_act_list       OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr)
IS
   l_log_module          VARCHAR2(240);
   l_activities          VARCHAR2(30);
   l_SrvErr              SrvErr;
   l_payment             BLC_PAYMENTS_TYPE;
   l_doc                 BLC_DOCUMENTS_TYPE;
   l_pay_method_id       NUMBER;
   l_pmnt_statuses       VARCHAR2(30);
   l_next_status         VARCHAR2(30);
   l_real_next_status    VARCHAR2(30);
   l_notes               VARCHAR2(4000);
   l_enable_hold         VARCHAR2(1);
   l_count               PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Modify_Pmnt_Activities';
    -- add next rows when need to trace
   /*
   blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_PROCEDURE,
                                'BEGIN of function Modify_Pmnt_Activities');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pi_act_list = '||pi_act_list);
   */

   l_payment := NEW blc_payments_type(pi_payment_id, l_SrvErr);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   po_act_list := pi_act_list;

   --IF l_payment.usage_id IN (4907,4908)
   IF l_payment.payment_class IN ('OB','OC')
   THEN
      IF instr(po_act_list, 'A') > 0 AND Is_Pmnt_Sent(pi_payment_id) = 'Y'
      THEN
         po_act_list := replace(po_act_list,'A',null);
      END IF;
      --
      IF instr(po_act_list, 'C') > 0
      THEN
         po_act_list := replace(po_act_list,'C',null);
      END IF;
   END IF;

   -- add next rows when need to trace
   /*
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'po_act_list = '||po_act_list);
    blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_PROCEDURE,
                                 'END of function Get_Pmnt_Activities'||' - '||l_activities);
   */

EXCEPTION
    WHEN OTHERS THEN
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Modify_Pmnt_Activities;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Approve_Payments
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
-- Purpose: Execute steps of process BLC_APPROVE_PAYMENT for list of payments
--
-- Input parameters:
--     pi_payment_ids         NUMBER       List od payment identifiers (required)
--     pi_notes               VARCHAR2     Notes
--     pi_changed_on          DATE         Change date
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_changed_status      VARCHAR2    Changed status payment
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In UI when need to approve payments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Approve_Payments
   (pi_payment_ids    IN     VARCHAR2,
    pi_notes          IN     VARCHAR2,
    po_changed_status OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr)
IS
    l_log_module     VARCHAR2(240);
    l_SrvErrMsg      SrvErrMsg;
    l_SrvErr         SrvErr;
    l_payment_ids    BLC_SELECTED_OBJECTS_TABLE;
    l_Context        srvcontext;
    l_RetContext     srvcontext;
    l_changed_status VARCHAR2(30);
    l_count          PLS_INTEGER;
    --
    l_procedure_result VARCHAR2(30);
    l_action_notes     VARCHAR2(4000);

    CURSOR c_pmnts (x_payment_ids IN BLC_SELECTED_OBJECTS_TABLE) IS
       SELECT payment_id, status
        FROM blc_payments
        WHERE payment_id IN (SELECT * FROM TABLE(x_payment_ids))
        FOR UPDATE WAIT 10;

BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Approve_Payments';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Approve_Payments');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_ids = '||pi_payment_ids);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_notes = '||pi_notes);

    IF pi_payment_ids IS NULL THEN
       RETURN;
    ELSE
       l_payment_ids := blc_common_pkg.convert_list(pi_payment_ids);
    END IF;

    srv_prm_process.Set_Action_Notes( l_Context, pi_notes );

    l_count := 0;
    FOR c_payment IN c_pmnts( l_payment_ids)
    LOOP
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_payment_id = '||c_payment.payment_id||' - '||c_payment.status);

        srv_context.SetContextAttrNumber( l_Context, 'PAYMENT_ID', srv_context.Integers_Format, c_payment.payment_id);

        l_SrvErr := NULL;

        srv_events.sysEvent( 'VALIDATE_BLC_PMNT_REFERENCES', l_Context, l_RetContext, l_SrvErr );

        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        l_action_notes := srv_prm_process.Get_Action_Notes( l_RetContext );

        srv_prm_process.Set_Action_Notes(l_Context, l_action_notes);

        IF l_procedure_result = BLC_GVAR_PROCESS.FLG_OK
        THEN
           srv_events.sysEvent( 'APPROVE_BLC_PAYMENT', l_Context, l_RetContext, l_SrvErr );
        ELSE
           srv_events.sysEvent( 'HOLD_BLC_PAYMENT', l_Context, l_RetContext, l_SrvErr );
        END IF;

        l_changed_status := srv_prm_process.Get_Payment_Status( l_RetContext );
        --
        IF l_SrvErr IS NOT NULL
        THEN
           FOR i IN l_SrvErr.first..l_SrvErr.last
           LOOP
             IF pio_Err IS NULL
             THEN
                pio_Err := SrvErr(l_SrvErr(i));
             ELSE
                l_count := pio_Err.count;
                pio_Err.extend;
                pio_Err(l_count+1) := l_SrvErr(i);
              END IF;
           END LOOP;
        END IF;

        l_RetContext := NULL;

        --
        l_count := l_count + 1;
        --
        IF l_count = 1
        THEN
           po_changed_status := l_changed_status;
        ELSE
           IF po_changed_status IS NOT NULL AND po_changed_status <> l_changed_status
           THEN
              po_changed_status := NULL;
           END IF;
        END IF;
    END LOOP;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_changed_status = '||po_changed_status);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Approve_Payments');
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Approve_Payments', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_payment_ids = '||pi_payment_ids||' - '|| SQLERRM);
END Approve_Payments;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Is_Pmnt_Sent
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Check if payment is sent
--
-- Input parameters:
--     pi_payment_id   NUMBER     Payment identifier (required)
--
-- Returns: Y/N
--
-- Usage: when need to know if payment is sent
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Pmnt_Sent
   (pi_payment_id     IN     NUMBER)
RETURN VARCHAR2
IS
   l_log_module          VARCHAR2(240);
   l_count               PLS_INTEGER;
   l_sent                VARCHAR2(1);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Is_Pmnt_Sent';

   SELECT count(*)
   INTO l_count
   FROM blc_pmnt_actions pa,
         blc_lookups bl
   WHERE pa.payment_id = pi_payment_id
   AND pa.status = 'S'
   AND pa.action_type_id = bl.lookup_id
   AND bl.lookup_code = 'SEND';

   IF l_count = 0
   THEN
      l_sent := 'N';
   ELSE
      l_sent := 'Y';
   END IF;

   RETURN l_sent;
EXCEPTION
    WHEN OTHERS THEN
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
      RETURN NULL;
END Is_Pmnt_Sent;

--------------------------------------------------------------------------------
-- Name: cust_pmnt_util_pkg.Validate_Pmnt_UnAppl
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
-- Purpose:  Execute procedure of validation of payment unapplication
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_remittance_ids      VARCHAR2     List of remittance id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In unapply payment and remittance
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Pmnt_UnAppl
   (pi_payment_id        IN     NUMBER,
    pi_remittance_ids    IN     VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc_id              NUMBER;
    l_SrvErr              SrvErr;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Validate_Pmnt_UnAppl';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Validate_Pmnt_UnAppl');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_remittance_ids = '||pi_remittance_ids);

    Validate_Pmnt_Appl
                 (pi_payment_id        => pi_payment_id,
                  pi_remittance_ids    => NULL,
                  pi_unapply           => 'Y',
                  po_doc_id            => l_doc_id,
                  pio_Err              => l_SrvErr);

    IF l_doc_id IS NOT NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_UnAppl', 'cust_pay_util_pkg.VPUA.Not_Allow_Unapp');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'l_doc_id = '||l_doc_id||' - '||
                                  'Unapplication is not allowed');
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Validate_Pmnt_UnAppl');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Validate_Pmnt_UnAppl', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Validate_Pmnt_UnAppl;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Update_Appl_Event - not in use
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   25.09.2017  creation
--
-- Purpose: Execute procedure for set payment event id in attrib_9 of payment
-- application
--
-- Input parameters:
--     pi_application_id      NUMBER       Application identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In apply payment before transfer to PAS
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Update_Appl_Event
   (pi_application_id    IN     NUMBER,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_appl                BLC_APPLICATIONS_TYPE;
    l_event_id            NUMBER;
    l_event_date          DATE;
    --
    CURSOR c_appl(x_payment_id IN NUMBER) IS
      SELECT be.event_id, be.event_date
      FROM blc_sla_events be
      WHERE be.payment_id = x_payment_id
      UNION ALL
      SELECT be.event_id, be.event_date
      FROM blc_clearings bc,
           blc_sla_events be
      WHERE bc.payment_id = x_payment_id
      AND bc.clearing_id = be.clearing_id
      ORDER BY event_date DESC, event_id DESC;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Update_Appl_Event';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Update_Appl_Event');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_application_id = '||pi_application_id);

    l_appl := NEW blc_applications_type(pi_application_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_application_id = '||pi_application_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
    END IF;

    IF l_appl.source_payment IS NOT NULL AND l_appl.reversed_appl IS NULL
    THEN
       OPEN c_appl(l_appl.source_payment);
         FETCH c_appl
         INTO l_event_id, l_event_date;
       CLOSE c_appl;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'l_event_id = '||l_event_id);

       IF l_event_id IS NOT NULL
       THEN
          UPDATE blc_applications
          SET attrib_9 = l_event_id
          WHERE application_id = pi_application_id;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Update_Appl_Event');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Update_Appl_Event', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_application_id = '||pi_application_id||' - '||SQLERRM);
END Update_Appl_Event;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Update_trx_balance
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.08.2016  creation - as copy from blc_appl_util_pkg
--
-- Purpose: Update balance of selected transaction or delete it
-- in case that balance is equal to 0
--
-- Input parameters:
--     pi_transaction_id   NUMBER    Transaction Id
--     pi_balane           NUMBER    New balance of transaction
--     pi_fc_balance       NUMBER    New balance of transaction in func currency
--
-- Usage: When have to update balance of a selected transaction
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Update_Trx_Balance
   (pi_transaction_id    IN  NUMBER,
    pi_balance           IN  NUMBER,
    pi_fc_balance        IN  NUMBER)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
   i                   NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Update_Trx_Balance';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN procedure Update_Trx_Balance');
   i := blc_appl_cache_pkg.g_trx_table.FIRST;
   LOOP
      EXIT WHEN blc_appl_cache_pkg.g_trx_table(i).transaction_id = pi_transaction_id OR i = blc_appl_cache_pkg.g_trx_table.LAST;
      i := i + 1;
   END LOOP;
   --
   blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'transaction_id = '||blc_appl_cache_pkg.g_trx_table(i).transaction_id);
   blc_appl_cache_pkg.g_trx_table(i).balance := pi_balance;
   blc_appl_cache_pkg.g_trx_table(i).fc_balance := pi_fc_balance;
   blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'balance = '||blc_appl_cache_pkg.g_trx_table(i).balance);
   blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'fc_balance = '||blc_appl_cache_pkg.g_trx_table(i).balance);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END procedure Update_Trx_Balance');

END Update_Trx_Balance;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Get_Item_Type_Doc
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.07.2016  creation
--
-- Purpose: Return item type for given document
--
-- Input parameters:
--       pi_doc_id     NUMBER    Doc ID (required)
--
-- Output parameters: N/A
--
-- Returns: policy name
--
-- Usage: When need to know item type for document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Item_Type_Doc
    ( pi_doc_id  IN  NUMBER)
RETURN VARCHAR2
IS
   l_item_type          VARCHAR2(30);
   --
   CURSOR get_item_doc IS
     SELECT bi.item_type
     FROM blc_transactions bt,
          blc_items bi
     WHERE bt.doc_id = pi_doc_id
     AND bt.status NOT IN ('C','R','D')
     AND bt.item_id = bi.item_id;
BEGIN
    IF pi_doc_id IS NULL
    THEN
       RETURN NULL;
    END IF;
    --
    OPEN get_item_doc;
       FETCH get_item_doc
       INTO l_item_type;
    CLOSE get_item_doc;

    RETURN l_item_type;

EXCEPTION
  WHEN OTHERS THEN
     RETURN NULL;
END Get_Item_Type_Doc;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Apply_Credit_Memo
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.08.2017  creation - as copy from blc_appl_util_pkg
--                                     add custim order
--
-- Purpose: Execute procedure for apply given credit memo to a debit document or
-- debit documents for an agreement

-- Input parameters:
--     pi_cr_doc_id        NUMBER    Credit document Id
--     pi_dr_doc_id        NUMBER    Debit document Id
--     pi_agreement        VARCHAR2  Item agreement
--     pi_apply_amount     NUMBER    Maximum of amount for apply
--     pi_net_call         VARCHAR2  'Y' when call from netting document
--                                   'N' default value
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err         SrvErr        Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In UI - form for credit memo applications
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Apply_Credit_Memo
   (pi_cr_doc_id    IN     NUMBER,
    pi_dr_doc_id    IN     NUMBER,
    pi_agreement    IN     VARCHAR2,
    pi_apply_amount IN     NUMBER,
    pi_net_call     IN     VARCHAR2 DEFAULT 'N',
    pio_Err         IN OUT SrvErr)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
   l_cr_doc            BLC_DOCUMENTS_TYPE;
   l_cr_balance        NUMBER;
   l_appl_amount       NUMBER;
   l_application_id    NUMBER;
   l_dr_balance        NUMBER;
   l_fc_dr_balance     NUMBER;
   l_restrict_account  VARCHAR2(30);
   l_sum_apply_amount  NUMBER;
   l_run_list          VARCHAR2(2000);
   l_count_appl        PLS_INTEGER := 0;
   --
   l_cr_item_type      VARCHAR2(30);
   l_dr_item_type      VARCHAR2(30);
   l_cr_pol_name       VARCHAR2(50);
   l_dr_pol_name       VARCHAR2(50);
   l_cr_item_id        NUMBER;
   l_dr_item_id        NUMBER;
   l_update_flag       VARCHAR2(1) := 'N';
   l_pmnt_flag         VARCHAR2(1) := 'N';
   l_dr_open_balance   NUMBER;
   l_cr_open_balance   NUMBER;
   l_dr_prm_amount     NUMBER;
   l_cr_prm_amount     NUMBER;
   l_appl_list         VARCHAR2(2000);
   l_over_flag         VARCHAR2(1) := 'N';
   l_appl_ids          BLC_SELECTED_OBJECTS_TABLE;
   l_cr_count          PLS_INTEGER;
   l_dr_count          PLS_INTEGER;
   --
   CURSOR get_item(x_doc_id IN NUMBER) IS
     SELECT bt.item_id
     FROM blc_transactions bt
     WHERE bt.doc_id = x_doc_id
     AND bt.status NOT IN ('C','R','D');
BEGIN
   blc_log_pkg.initialize(pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   l_log_module := C_DEFAULT_MODULE||'.Apply_Credit_Memo';

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Apply_Credit_Memo');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_cr_doc_id = '||pi_cr_doc_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_dr_doc_id = '||pi_dr_doc_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_agreement = '||pi_agreement);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_apply_amount = '||pi_apply_amount);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_net_call = '||pi_net_call);

   IF pi_cr_doc_id IS NULL
   THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.No_CrDocId' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                 'Credit document Id is not specified');
       RETURN;
   END IF;

   IF pi_dr_doc_id IS NULL
   THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'cust_billing_pkg.ACM.No_DrDocId' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                 'Debit document Id is not specified');
       RETURN;
   END IF;

   l_cr_doc := NEW blc_documents_type(pi_cr_doc_id);

   IF l_cr_doc.doc_class NOT IN ('B','L')
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.InvDocClass', l_cr_doc.doc_class );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_EXCEPTION,
                                 'Invalid document class = '||l_cr_doc.doc_class);
      RETURN;
   END IF;

   IF l_cr_doc.status NOT IN ('A', 'F')
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.Is_Not_Approved_Formal' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_cr_doc_id = '||pi_cr_doc_id||' - '||
                                  'Only documents in status Approved or Formal can be applied');
      RETURN;
   END IF;

   l_run_list := blc_appl_util_pkg.Get_Pmnt_Run_Agr_Doc
                     (pi_agreement      => NULL,
                      pi_doc_id         => pi_cr_doc_id);

   IF l_run_list IS NOT NULL
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.InitPmntRunDoc', pi_cr_doc_id||'|'||l_run_list );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_cr_doc_id = '||pi_cr_doc_id||' - '||
                                  'There are transactions for the document which are selected in payment run(s) '||l_run_list);
      RETURN;
   END IF;

   l_run_list := blc_appl_util_pkg.Get_Pmnt_Run_Agr_Doc
                     (pi_agreement      => pi_agreement,
                      pi_doc_id         => pi_dr_doc_id);

   IF l_run_list IS NOT NULL
   THEN
      IF pi_dr_doc_id IS NOT NULL
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.InitPmntRunDoc', pi_dr_doc_id||'|'||l_run_list );
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_dr_doc_id = '||pi_dr_doc_id||' - '||
                                    'There are transactions for the document which are selected in payment run(s) '||l_run_list);
      ELSE
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.InitPmntRunAgr', pi_agreement||'|'||l_run_list );
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_agreement = '||pi_agreement||' - '||
                                    'There are transactions for the agreement which are selected in payment run(s) '||l_run_list);
      END IF;

      RETURN;
   END IF;

   IF blc_appl_cache_pkg.g_legal_entity_id IS NULL
        OR blc_appl_cache_pkg.g_legal_entity_id <> l_cr_doc.legal_entity_id
   THEN
      -- Init Legal Entity
      blc_appl_cache_pkg.Init_Le( l_cr_doc.legal_entity_id, pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN RETURN;
      END IF;
   END IF;

   IF pi_cr_doc_id <> pi_dr_doc_id
   THEN
      l_cr_item_type := Get_Item_Type_Doc(pi_cr_doc_id);
      l_dr_item_type := Get_Item_Type_Doc(pi_dr_doc_id);

      IF l_cr_item_type <> l_dr_item_type
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'cust_billing_pkg.ACM.DiffItemTypes');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                   'pi_cr_doc_id = '||pi_cr_doc_id||' - '||
                                   'pi_dr_doc_id = '||pi_dr_doc_id||' - '||
                                   'Cannot apply documents with different item types');
         RETURN;
      END IF;
   END IF;

   blc_appl_util_pkg.Lock_Transactions
         (NULL, --pi_source,
          NULL, --pi_agreement,
          NULL, --pi_component,
          NULL, --pi_detail,
          NULL, --pi_item_id,
          pi_cr_doc_id,
          NULL, --pi_trx_id,
          NULL, --pi_party,
          NULL, --pi_account_id,
          pio_Err);

   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   blc_appl_util_pkg.Lock_Transactions
         (NULL, --pi_source,
          pi_agreement,
          NULL, --pi_component,
          NULL, --pi_detail,
          NULL, --pi_item_id,
          pi_dr_doc_id,
          NULL, --pi_trx_id,
          NULL, --pi_party,
          NULL, --pi_account_id,
          pio_Err);

   IF NOT srv_error.rqStatus( pio_Err )
   THEN
       RETURN;
   END IF;

   blc_appl_util_pkg.Select_Trx_For_Apply
         (NULL, --pi_source,
          pi_agreement,
          NULL, --pi_component,
          NULL, --pi_detail,
          NULL,
          NULL,
          pi_dr_doc_id,
          NULL,
          NULL,
          NULL,
          NULL, --'NORM',  --rq 1000009832
          pio_Err);

   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   l_restrict_account := blc_appl_util_pkg.Get_Restr_Party_Appl;
   l_sum_apply_amount := abs(pi_apply_amount);

   SAVEPOINT APPL;

   FOR c_cr_trx IN ( SELECT bt.transaction_id,  bt.transaction_type, bt.currency,
                            bt.rate, bt.rate_type, bt.rate_date, bt.due_date,
                            --blc_appl_util_pkg.Get_Trx_LOB(bt.transaction_id) lob, --not needed here
                            blc_appl_util_pkg.TRX_Outstanding_Balance(bt.transaction_id,bt.amount,bt.paid_status,bt.open_balance) balance,
                            ba.party,
                            bt.item_id,
                            --to_char(to_date(bt.attrib_4,'dd-mm-yyyy'),'yyyymm') begin_period, not need for now
                            bi.agreement
                     FROM blc_transactions bt,
                          blc_accounts ba,
                          blc_items bi
                     WHERE bt.doc_id = pi_cr_doc_id
                     AND blc_appl_util_pkg.TRX_Outstanding_Balance(bt.transaction_id,bt.amount,bt.paid_status,bt.open_balance) < 0
                     AND bt.status NOT IN ('C','R','D')
                     AND NOT EXISTS (SELECT 'R'
                                     FROM blc_pay_run pr
                                     WHERE pr.transaction_id = bt.transaction_id
                                     AND pr.status = 'I')
                     AND bt.account_id = ba.account_id
                     AND bt.item_id = bi.item_id
                     ORDER BY --to_char(to_date(bt.attrib_4,'dd-mm-yyyy'),'yyyymm') DESC, begin_period, not need for now
                              bt.due_date DESC, abs(blc_appl_util_pkg.TRX_Outstanding_Balance(bt.transaction_id,bt.amount,bt.paid_status,bt.open_balance)) DESC, bt.transaction_id)
            LOOP
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_STATEMENT,
                                         'l_cr_transaction_id = '||c_cr_trx.transaction_id);
               l_cr_balance := c_cr_trx.balance;
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_STATEMENT,
                                         'begin l_cr_balance = '||l_cr_balance);

               FOR c_dr_trx IN ( SELECT bg.transaction_id, bg.rate, bg.rate_type,
                                        bg.balance, bg.fc_balance, bg.currency
                                 FROM TABLE(blc_appl_cache_pkg.g_trx_table) bg,
                                      blc_transactions bt
                                 WHERE bg.due_date = c_cr_trx.due_date
                                 --nvl(bg.lob,'-999') = nvl(c_cr_trx.lob,'-999')
                                 AND bg.item_id = c_cr_trx.item_id
                                 AND bg.transaction_type = c_cr_trx.transaction_type
                                 AND bg.currency = c_cr_trx.currency
                                 AND (c_cr_trx.party IS NULL OR bg.party = c_cr_trx.party)
                                 AND bg.balance > 0
                                 AND bg.transaction_id = bt.transaction_id
                                 ORDER BY --DECODE(bg.item_id,c_cr_trx.item_id,1,2),
                                          --DECODE(bg.agreement,c_cr_trx.agreement,'1','2'),
                                          --DECODE(to_char(to_date(bt.attrib_4,'dd-mm-yyyy'),'yyyymm'),c_cr_trx.begin_period,'1','2'),
                                          --DECODE(bt.transaction_type,c_cr_trx.transaction_type,1,2),
                                          --to_char(to_date(bt.attrib_4,'dd-mm-yyyy'),'yyyymm'),
                                          --bg.due_date,
                                          bg.priority,
                                          bg.balance DESC,
                                          bg.transaction_id)
                  LOOP
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_STATEMENT,
                                               'in loop transaction_id= ' ||c_dr_trx.transaction_id);
                    IF (l_sum_apply_amount IS NULL OR l_sum_apply_amount > 0) AND l_cr_balance < 0
                    THEN
                       --
                       l_appl_amount := LEAST(l_cr_balance*(-1),c_dr_trx.balance);
                       IF l_sum_apply_amount IS NOT NULL
                       THEN
                          l_appl_amount := LEAST(l_sum_apply_amount,l_appl_amount);
                       END IF;

                       blc_log_pkg.insert_message(l_log_module,
                                                  C_LEVEL_STATEMENT,
                                                 'l_dr_transaction_id = '||c_dr_trx.transaction_id);
                       blc_log_pkg.insert_message(l_log_module,
                                                  C_LEVEL_STATEMENT,
                                                 'l_appl_amount = '||l_appl_amount);

                       --insert application
                       blc_appl_util_pkg.Apply_CREDIT_ON_TRANSACTION
                          (blc_appl_cache_pkg.g_to_date,
                           NULL, --pi_value_date
                           c_cr_trx.rate_date,
                           (-1)*l_appl_amount,
                           c_cr_trx.rate,
                           c_cr_trx.rate_type,
                           l_appl_amount,
                           c_dr_trx.rate,
                           c_dr_trx.rate_type,
                           c_dr_trx.transaction_id,
                           c_cr_trx.transaction_id,
                           NULL, --pi_item_id,
                           NULL, --pi_account_id,
                           l_application_id,
                           pio_Err);

                       IF NOT srv_error.rqStatus( pio_Err )
                       THEN
                          ROLLBACK TO APPL;
                          RETURN;
                          blc_appl_cache_pkg.init_appl_transfer('Y');
                       END IF;

                       l_count_appl := l_count_appl + 1;

                       IF l_appl_list IS NULL
                       THEN
                          l_appl_list := to_char(l_application_id);
                       ELSE
                          IF length(l_appl_list||','||to_char(l_application_id)) <= 2000
                          THEN
                             l_appl_list := l_appl_list||','||to_char(l_application_id);
                          ELSE
                             l_over_flag := 'Y';
                          END IF;
                       END IF;

                       blc_log_pkg.insert_message(l_log_module,
                                                  C_LEVEL_STATEMENT,
                                                 'l_over_flag = '||l_over_flag);

                       --calculate new balance of debit transaction
                       l_dr_balance := c_dr_trx.balance - l_appl_amount;
                       IF c_dr_trx.currency = blc_appl_cache_pkg.g_fc_currency
                       THEN
                          l_fc_dr_balance := c_dr_trx.fc_balance - l_appl_amount;
                       ELSE
                          l_fc_dr_balance := c_dr_trx.fc_balance - round(l_appl_amount*c_dr_trx.rate,blc_appl_cache_pkg.g_fc_precision);
                       END IF;
                       --update selected debit transaction balance with new calculated
                       Update_Trx_Balance(c_dr_trx.transaction_id, l_dr_balance, l_fc_dr_balance);
                       --
                       --calculate new balance of credit transaction
                       l_cr_balance := l_cr_balance + l_appl_amount;

                       --begin rq 1000010880
                       --l_sum_apply_amount := l_sum_apply_amount + l_appl_amount;
                       l_sum_apply_amount := l_sum_apply_amount - l_appl_amount;

                       blc_log_pkg.insert_message(l_log_module,
                                                  C_LEVEL_STATEMENT,
                                                 'l_sum_apply_amount = '||l_sum_apply_amount);
                     END IF;
                  END LOOP;

               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_STATEMENT,
                                         'end l_cr_balance = '||l_cr_balance);
               --
            END LOOP;

     IF l_count_appl = 0 AND pi_net_call = 'N'
     THEN
        srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', 'appl_util_pkg.ACM.NoAppl');
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_cr_doc_id = '||pi_cr_doc_id||' - '||
                                  'Applications are not created, only transactions with the same currency, transaction types, line of business and party (depend on setting RestrApplyRcptByParty) can be applied');
        RETURN;
     END IF;

     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure Apply_Credit_Memo');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Apply_Credit_Memo', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_cr_doc_id = '||pi_cr_doc_id||' - '||
                                'pi_dr_doc_id = '||pi_dr_doc_id||' - '||SQLERRM);
END Apply_Credit_Memo;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Net_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.08.2017  creation
--
-- Purpose: Execute procedure for netting document, firstly between transactions
-- in a document and that with transactions from the agreement of document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err         SrvErr        Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In billing process to execute netting for a document after it
-- validation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Net_Document
   (pi_doc_id      IN     NUMBER,
    pio_Err        IN OUT SrvErr)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
BEGIN
  l_log_module := C_DEFAULT_MODULE||'.Net_Document';
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Net_Document');
  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);

  --net inside the document
  Apply_Credit_Memo
               (pi_cr_doc_id    => pi_doc_id,
                pi_dr_doc_id    => pi_doc_id,
                pi_agreement    => NULL,
                pi_apply_amount => NULL,
                pi_net_call     => 'Y',
                pio_Err         => pio_Err);

  IF NOT srv_error.rqStatus( pio_Err )
  THEN
     blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||
                                pio_Err( pio_Err.FIRST).errmessage);
     RETURN;
  END IF;

  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Net_Document');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Net_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Net_Document;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Void_Payment_for_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2013  creation
--     Fadata   05.03.2015  changed - do not check status of document to be F
--                                    add where clause to reverse only payments
--                                    with amount <> 0
--                                    replace BLC_APPL_UTIL_PKG.Reverse_Payment
--                                    with BLC_PMNT_UTIL_PKG.Reverse_Payment
--                                    to pass parameter reverse reason
--                                    rq 1000009677
--     Fadata  20.11.2017   copy from core and remove substr(bp.payment_class,1,1) = 'O'
--
-- Purpose: Execute procedure for reverse of outgoing payments with amount > 0
-- for given document
--
-- Actions:
--     1) Reverse payment
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required);
--     pi_reason              VARCHAR2     Reverse payment reason code -
--                                         lookup_code
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--     TRUE/FALSE
--
-- Usage: In UI when need to void the payment for a document
--
-- Exceptions:
--    1) In case that reversal of payment failed
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Void_Payment_for_Document
   (pi_doc_id         IN     NUMBER,
    pi_reason         IN     VARCHAR2,
    pio_Err           IN OUT SrvErr)
RETURN BOOLEAN
IS
    l_log_module       VARCHAR2(240);
    l_SrvErrMsg        SrvErrMsg;
    l_doc              BLC_DOCUMENTS_TYPE;
    l_reason           VARCHAR2(2000);
    l_pmnt_ids         VARCHAR2(2000);
    l_count            NUMBER;
    l_procedure_result VARCHAR2(30);
    l_doc_status       VARCHAR2(1);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN FALSE;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Void_Payment_for_Document';
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'BEGIN of function Void_Payment_for_Document');
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_reason = '||pi_reason);

    l_doc := NEW blc_documents_type(pi_doc_id);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_doc_status = '||l_doc.status);

    /* Init legal entity */
    blc_appl_cache_pkg.Init_LE( l_doc.legal_entity_id, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_doc_id = '||pi_doc_id||' - '||
                                  pio_Err(pio_Err.FIRST).errmessage);
       RETURN FALSE;
    END IF;

    IF l_doc.status = cust_gvar.STATUS_FORMAL
    THEN
       l_doc.status := cust_gvar.STATUS_APPROVED;

       IF NOT l_doc.update_blc_documents( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '|| pio_Err(pio_Err.FIRST).errmessage);
          RETURN FALSE;
       END IF;
    END IF;

    FOR c_pay IN (SELECT bp.payment_id
                  FROM blc_transactions bt,
                       blc_applications ba,
                       blc_payments bp
                  WHERE bt.doc_id = pi_doc_id
                  AND bt.transaction_id = ba.target_trx
                  AND ba.appl_class = 'PMNT_ON_TRANSACTION'
                  AND ba.status <> 'D'  -- RQ1000009218
                  AND ba.reversed_appl IS NULL
                  AND NOT EXISTS (SELECT 'REVERSE'
                                  FROM blc_applications ba1
                                  WHERE ba1.reversed_appl = ba.application_id
                                  AND ba1.status <> 'D'  -- RQ1000009218
                                  )
                  AND ba.source_payment = bp.payment_id
                  --AND substr(bp.payment_class,1,1) = 'O'
                  AND bp.amount > 0
                  GROUP BY bp.payment_id
                  ORDER BY bp.payment_id DESC)
    LOOP
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'c_pay.payment_id = '||c_pay.payment_id);

       SELECT count(*)
       INTO l_count
       FROM blc_transactions bt,
            blc_applications ba
       WHERE bt.doc_id <> pi_doc_id
       AND bt.transaction_id = ba.target_trx
       AND ba.appl_class = 'PMNT_ON_TRANSACTION'
       AND ba.status <> 'D'  -- RQ1000009218
       AND ba.reversed_appl IS NULL
       AND NOT EXISTS (SELECT 'REVERSE'
                       FROM blc_applications ba1
                       WHERE ba1.reversed_appl = ba.application_id
                       AND ba1.status <> 'D'  -- RQ1000009218
                       )
       AND ba.source_payment = c_pay.payment_id;

       IF l_count > 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Void_Payment_for_Document', 'blc_refund_util_pkg.VPD.Many_Doc_Appl',c_pay.payment_id );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                     'pi_doc_id = '||pi_doc_id||' - '||
                                     'There are applications on other document for payment '||c_pay.payment_id);
          RETURN FALSE;
       END IF;

       IF l_pmnt_ids IS NULL
       THEN
          l_pmnt_ids := c_pay.payment_id;
       ELSE
          c_pay.payment_id := ' ,'||c_pay.payment_id;
       END IF;

       --add next if need SAP to lock payment for reverse
       /*
       l_doc_status := NULL;
       l_procedure_result := NULL;

       BEGIN
         SELECT bd.status
         INTO l_doc_status
         FROM blc_documents bd,
              blc_lookups bl
         WHERE bd.doc_suffix = to_char(c_pay.payment_id)
         AND bd.doc_type_id = bl.lookup_id
         AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
         EXCEPTION
            WHEN OTHERS THEN
              l_doc_status := NULL;
       END;

       IF l_doc_status in (cust_gvar.STATUS_APPROVED,cust_gvar.STATUS_FORMAL)
       THEN
          --IP - call service for lock payment in SAP
          cust_intrf_util_pkg.Lock_Pmnt_For_Reverse
                              (pi_payment_id        => c_pay.payment_id,
                               po_procedure_result  => l_procedure_result,
                               pio_Err              => pio_Err);

          IF l_procedure_result = cust_gvar.FLG_ERROR
          THEN
             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'c_pay.payment_id = '||c_pay.payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             ELSE
                srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Void_Payment_for_Document', 'cust_pay_util_pkg.PRP.IP_Error');
                srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'c_pay.payment_id = '||c_pay.payment_id||' - '||'Integration for lock payment in SAP return error');
             END IF;
             --
             RETURN FALSE;
          END IF;
       END IF;
       */

       blc_pmnt_util_pkg.Reverse_Payment
           (pi_payment_id      => c_pay.payment_id,
            pi_reason_id       => NULL,
            pi_reason_code     => pi_reason,
            pi_notes           => NULL,
            pi_reversed_on     => NULL,
            pi_execute_unclear => 'N',
            pio_Err            => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_doc_id = '||pi_doc_id||' - '||
                                    'c_pay.payment_id = '||c_pay.payment_id||' - '||
                                     pio_Err(pio_Err.FIRST).errmessage);
          RETURN FALSE;
       END IF;
    END LOOP;

   blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'END of function Void_Payment_for_Document - reversed payments: '||l_pmnt_ids);
   RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Void_Payment_for_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '|| SQLERRM);
     RETURN FALSE;
END Void_Payment_for_Document;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Pay_Refund_CN_Doc
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.11.2017  creation
--
-- Purpose:  Execute procedure for pay a refund CN document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_org_id              NUMBER       Org Id
--     pi_usage_id            NUMBER       Usage Id
--     pi_amount              NUMBER       Payment amount (required)
--     pi_party               VARCHAR2     Party id
--     pi_pay_party           VARCHAR2     Payer party
--     pi_pmnt_address        VARCHAR2     Payment address
--     pi_currency            VARCHAR      Payment currency (required)
--     pi_pmnt_date           VARCHAR2     Payment date (required)
--     pi_attrib_3            VARCHAR2     AD number
--     pi_attrib_4            VARCHAR2     AD date
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_payment_id          NUMBER       Payment Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to create payment for refund CN document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pay_Refund_CN_Doc
   (pi_doc_id            IN     NUMBER,
    pi_org_id            IN     NUMBER,
    pi_usage_id          IN     NUMBER,
    pi_amount            IN     NUMBER,
    pi_party             IN     VARCHAR2,
    pi_pay_party         IN     VARCHAR2,
    pi_pmnt_address      IN     VARCHAR2,
    pi_currency          IN     VARCHAR2,
    pi_pmnt_date         IN     DATE,
    pi_attrib_3          IN     VARCHAR2,
    pi_attrib_4          IN     VARCHAR2,
    po_payment_id        OUT    NUMBER,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc                 blc_documents_type;
    l_doc_type            VARCHAR2(30);
    l_doc_balance         NUMBER;
    l_usage_id            NUMBER;
    l_acc_class           VARCHAR2(30);
    l_payment             blc_payments_type;
    l_ad_date             DATE;
    l_procedure_result    VARCHAR2(30);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Pay_Refund_CN_Doc';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Pay_Refund_CN_Doc');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_usage_id = '||pi_usage_id);

    l_doc := NEW blc_documents_type(pi_doc_id);

    l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

    IF l_doc_type = cust_gvar.DOC_RFND_CN_TYPE
    THEN
       IF blc_appl_cache_pkg.g_legal_entity_id IS NULL OR blc_appl_cache_pkg.g_legal_entity_id <> l_doc.legal_entity_id --rq 1000010841
       THEN
          blc_appl_cache_pkg.Init_LE( l_doc.legal_entity_id, pio_Err );
       END IF;

       IF pi_usage_id IS NOT NULL
       THEN
          l_usage_id := pi_usage_id;
       ELSE
          l_acc_class := BLC_COMMON_PKG.Get_Lookup_Tag_Value
                                 (PI_LOOKUP_SET => 'DOCUMENT_TYPES',
                                  PI_LOOKUP_CODE => NULL,
                                  PI_ORG_ID => nvl(pi_org_id,l_doc.org_site_id),
                                  PI_LOOKUP_ID => l_doc.doc_type_id,
                                  PI_TAG_NUMBER => 8);

          blc_pmnt_util_pkg.Calc_Usage_By_Pmnt_Attribs
               (pi_acc_class      => l_acc_class,
                pi_org_id         => nvl(pi_org_id,l_doc.org_site_id),
                pi_to_date        => pi_pmnt_date,
                pi_bank_acc_code  => NULL,
                pi_pmnt_class     => 'OW',
                pi_pmnt_currency  => NULL,
                pi_pay_method     => NULL,
                pi_usage_name     => NULL,
                po_usage_id       => l_usage_id,
                pio_Err           => pio_Err);
       END IF;

       IF l_usage_id IS NULL
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pay_Refund_CN_Doc', 'cust_pay_util_pkg.PRD.No_Usage');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          RETURN;
       END IF;

       IF pi_attrib_3 IS NOT NULL
       THEN
          IF pi_attrib_4 IS NOT NULL
          THEN
             BEGIN
                l_ad_date := TO_DATE(pi_attrib_4, 'dd-mm-yyyy');
             EXCEPTION
                WHEN OTHERS THEN
                  l_ad_date := nvl(pi_pmnt_date, blc_appl_cache_pkg.g_to_date);
             END;
          ELSE
             l_ad_date := nvl(pi_pmnt_date, blc_appl_cache_pkg.g_to_date);
          END IF;

          cust_billing_pkg.Set_Doc_AD
                       ( pi_doc_id             => pi_doc_id,
                         pi_action_type        => 'CREATE_AD',
                         pi_ad_number          => pi_attrib_3,
                         pi_ad_date            => l_ad_date,
                         pi_action_reason      => NULL,
                         po_procedure_result   => l_procedure_result,
                         pio_Err               => pio_Err);

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             RETURN;
          END IF;
       END IF;

       po_payment_id := cust_billing_pkg.Create_Payment_for_Document
                 (pi_doc_id         => pi_doc_id,
                  pi_office         => NULL,
                  pi_org_id         => nvl(pi_org_id,l_doc.org_site_id),
                  pi_usage_id       => l_usage_id,
                  pi_amount         => pi_amount,
                  pi_party          => pi_party,
                  pi_party_site     => NULL,
                  pi_pay_party      => pi_pay_party,
                  pi_pay_address    => NULL,
                  pi_bank_code      => NULL,
                  pi_bank_acc_code  => NULL,
                  pi_pmnt_address   => pi_pmnt_address,
                  pi_currency       => pi_currency,
                  pi_pmnt_date      => nvl(pi_pmnt_date, blc_appl_cache_pkg.g_to_date),
                  pi_pmnt_number    => NULL,
                  pi_pay_instr_id   => NULL,
                  pio_Err           => pio_Err);

       IF po_payment_id IS NOT NULL AND pi_attrib_3 IS NOT NULL
       THEN
          l_payment := NEW blc_payments_type(po_payment_id, pio_Err);
          l_payment.attrib_3 := pi_attrib_3;
          l_payment.attrib_4 := pi_attrib_4;

          IF NOT l_payment.update_blc_payments(pio_Err)
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_EXCEPTION,
                                       'po_payment_id = '||po_payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;
       END IF;
    ELSE
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pay_Refund_CN_Doc', 'cust_billing_pkg.MFD.Not_Allowed', l_doc_type);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||'Activity is not allowed for the document type '||l_doc_type);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'po_payment_id = '||po_payment_id);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Pre_Pay_Document');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Pay_Refund_CN_Doc', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Pay_Refund_CN_Doc;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Get_Pmnt_Doc_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.11.2017  creation
--
-- Purpose: Get document id for given payment
--
-- Input parameters:
--     pi_payment_id   NUMBER     Payment identifier (required)
--
-- Returns: Y/N
--
-- Usage: when need to know document paid with a payment
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pmnt_Doc_Id
   (pi_payment_id     IN     NUMBER)
RETURN NUMBER
IS
   l_log_module          VARCHAR2(240);
   l_doc_id              NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Pmnt_Doc_Id';

   SELECT DISTINCT bt.doc_id
   INTO l_doc_id
   FROM blc_applications ba,
        blc_transactions bt
   WHERE ba.source_payment = pi_payment_id
   AND ba.target_trx = bt.transaction_id
   AND ba.status <> 'D'
   AND ba.reversed_appl IS NULL
   AND NOT EXISTS (SELECT 'REVERSE'
                   FROM blc_applications ba1
                   WHERE ba1.reversed_appl = ba.application_id
                   AND ba1.status <> 'D');
   --
   RETURN l_doc_id;
EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END Get_Pmnt_Doc_Id;


--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Create_Acc_Event_Clear_Inst
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   18.09.2018  changed - LPV-1732 add all available types of installments
--     Fadata   15.01.2020  changed - CHA93S-8 add to not create events for advance claims
--
-- Purpose: Create accounting event for claim RI/CO installments related to
-- clearing of given payment
--
-- Input parameters:
--     pi_clearing_id      NUMBER    Clearing Id
--     pi_uncleared        NUMBER    Uncleared clearing Id
--     pi_payment_id       NUMBER    Payment Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: After creation of a clearing to create accounting event for it
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Acc_Event_Clear_Inst
   (pi_clearing_id   IN     NUMBER,
    pi_uncleared     IN     NUMBER,
    pi_payment_id    IN     NUMBER,
    pio_Err          IN OUT SrvErr)
IS
   l_log_module       VARCHAR2(240);
   l_SrvErrMsg        SrvErrMsg;
   l_event_type       VARCHAR2(30);
   l_event            BLC_SLA_EVENTS_TYPE;
   l_payment          BLC_PAYMENTS_TYPE;
   l_usage_type       VARCHAR2(30);
   --
   CURSOR get_event(x_installment_id IN NUMBER, x_event_type IN VARCHAR2) IS
     SELECT event_id
     FROM blc_sla_events
     WHERE event_class = 'I'
     AND event_type = x_event_type
     AND installment_id = x_installment_id
     AND reversal_flag = 'N'
     ORDER BY created_on DESC, event_id DESC;
   --
   CURSOR c_clearing IS
     SELECT nvl(uncleared, clearing_id), decode(uncleared,NULL,NULL,clearing_id)
     FROM blc_clearings
     WHERE payment_id = pi_payment_id
     ORDER by created_on DESC, clearing_id DESC;
   --
   l_prev_event_id    NUMBER;
   l_clearing_id      NUMBER;
   l_unclearing_id    NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Create_Acc_Event_Clear_Inst';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN procedure Create_Acc_Event_Clear_Inst');
   --
   l_payment := NEW blc_payments_type(pi_payment_id, pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_payment_id = '||pi_payment_id||' - '||
                                 pio_Err(pio_Err.FIRST).errmessage);
      RETURN;
   END IF;

   BEGIN
      SELECT attrib_0
      INTO l_usage_type
      FROM blc_bacc_usages
      WHERE usage_id = l_payment.usage_id;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_usage_type := NULL;
   END;

   IF l_usage_type = 'CLAIM' AND Is_Pmnt_Adv_Claim(pi_payment_id) = 'N' -- CHA93S-8 add and
   THEN
      l_prev_event_id := blc_clearing_util_pkg.Get_PMNT_Prev_Event(pi_payment_id);

      OPEN c_clearing;
        FETCH c_clearing
        INTO l_clearing_id, l_unclearing_id;
      CLOSE c_clearing;

      l_event := new blc_sla_events_type;
      l_event.event_type := 'RECOGN_EXP_CLEAR_PMNT';
      l_event.event_class := 'I';
      l_event.event_date := blc_appl_cache_pkg.g_to_date;
      l_event.legal_entity := blc_appl_cache_pkg.g_legal_entity_id;
      l_event.attrib_0 := l_clearing_id;
      l_event.attrib_1 := l_unclearing_id;

      FOR c_inst IN (SELECT bii.installment_id, bii.status
                     FROM blc_installments bii,
                         blc_items biri,
                         blc_items bi,
                         blc_transactions btt,
                         blc_applications ba
                     WHERE bii.item_id = biri.item_id
                     --AND bii.installment_type IN ('BCCLAIMQS','BCCLAIMSP','BCCLAIMCO') --LPV-1732
                     AND bii.installment_type IN ('BCCLAIMQS','BCCLAIMSP','BCCLAIMCO',
                                                  'BCCLAIMEXL','BCCLAIMFACNPR','BCCLAIMFACONPR',
                                                  'BCCLAIMFACOPR','BCCLAIMFACPR','BCCLAIMFR',
                                                  'BCCLAIMQSP','BCCLAIMREXL','BCCLAIMRXL',
                                                  'BCCLAIMSL') --LPV-1732
                     AND sign(bii.amount)*(-1) = sign(btt.amount)
                     AND biri.item_type IN ('RI','CO')
                     AND bii.attrib_9 = bi.detail
                     AND biri.component = bi.component
                     AND bi.item_type = 'CLAIM'
                     AND bi.item_id = btt.item_id
                     AND btt.transaction_id = ba.target_trx
                     AND ba.source_payment = pi_payment_id
                     GROUP BY bii.installment_id, bii.status)
      LOOP
        l_event.event_id := NULL;
        l_event.installment_id := c_inst.installment_id;
        l_event.object_status := c_inst.status;

        IF pi_uncleared IS NOT NULL
        THEN
           l_event.reversal_flag := 'Y';
           OPEN get_event(c_inst.installment_id,l_event.event_type);
             FETCH get_event
             INTO l_event.previous_event;
           CLOSE get_event;
        ELSE
           l_event.reversal_flag := 'N';
           l_event.previous_event := l_prev_event_id;
        END IF;

        --
        IF NOT l_event.insert_blc_sla_events( pio_Err )
        THEN
           blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                     'c_inst.installment_id = '||c_inst.installment_id||' - '||
                                      pio_Err(pio_Err.FIRST).errmessage);
        END IF;

        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                  'c_inst.installment_id = '||c_inst.installment_id||' - event_id = '||l_event.event_id);
      END LOOP;
   END IF;
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END procedure Create_Acc_Event_Clear_Inst');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Create_Acc_Event_Clear_Inst', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_payment_id = '||pi_payment_id||' - '||
                                SQLERRM);
END Create_Acc_Event_Clear_Inst;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Accumulate_Reminders
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   02.09.2013  changed - add parameter limit_amount, doc_id
--     Fadata   09.10.2013  changed - change sign of source amount depend on
--                          transaction class and payment class
--     Fadata   05.12.2014  changed - add order by application sign
--                          add parameter for update transaction balance
--                          rq 1000009392
--     Fadata   05.03.2015  changed - in case when payment is outgoing,
--                          limit amount is null and payment amount <> 0
--                          add calculation of apply amount for last
--                          transactions as difference between payment amount
--                          and sum of applied amount
--                          rq 1000009677
--     Fadata   18.12.2015  RQ1000010253 add sign in Order by
--     Fadata   09.07.2016  changed - multiply target_set amount with l_sign
--                          when calculate total applied amount
--                          rq 1000010596
--     Fadata   17.05.2017  changed - fix for rq 1000009677 - do not change
--                          sign of the balance in this case
--                          rq 1000011010
--     Fadata   15.02.2018  copy of blc_appl_util_pkg.Accumulate_Reminders
--                          and order by priority and transaction_id
--
-- Purpose: Accumulate outstanding balances of selected credit transactions
-- in the unapplied receipt amount to reach to accumulated amount if given
--
-- Input parameters:
--     pi_date              DATE      Receipt date
--     pi_rate              NUMBER    Receipt rate
--     pi_rate_type         VARCHAR   Receipt rate type
--     pi_rate_date         DATE      Receipt rate date
--     pi_appl_date         DATE      Application date
--     pi_value_date        DATE      Receipt value date
--     pi_due_date          DATE      Transacion due date
--     pi_limit_amount      NUMBER    Limit of accumulated amount
--     pi_doc_id            NUMBER    Document Id
--     pi_update_trx        VARCHAR2  Update balance of selected transaction
--     pio_source_amount    NUMBER    Unapplied receipt amount
--     pio_fc_source_amount NUMBER    Unapplied receipt amount in func curr
--     pio_Err              SrvErr    Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     pio_source_amount    NUMBER    Unapplied receipt amount
--     pio_fc_source_amount NUMBER    Unapplied receipt amount in func curr
--     pio_Err              SrvErr    Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Usage: When need to accumulate credit from a transaction to a receipt
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Accumulate_Reminders
    ( pi_source_payment     IN     NUMBER,
      pi_rate               IN     NUMBER,
      pi_rate_date          IN     DATE,
      pi_rate_type          IN     VARCHAR2,
      pi_appl_date          IN     DATE,
      pi_value_date         IN     DATE,
      pi_due_date           IN     DATE,
      pi_limit_amount       IN     NUMBER,
      pi_doc_id             IN     NUMBER,
      pi_update_trx         IN     VARCHAR2 DEFAULT 'N',
      pio_source_amount     IN OUT NUMBER,
      pio_fc_source_amount  IN OUT NUMBER,
      pio_Err               IN OUT SrvErr )
IS
    l_trx_target_set        NUMBER;
    l_trx_fc_target_set     NUMBER;
    l_trx_balance_rcpt      NUMBER;
    l_trx_fc_balance_rcpt   NUMBER;
    l_application_id        NUMBER;
    l_log_module            VARCHAR2(240);
    l_SrvErrMsg             SrvErrMsg;
    l_rate                  NUMBER;
    l_unapplied_amount      NUMBER;
    l_trx_apply_amount      NUMBER;
    l_payment               blc_payments_type;
    l_sign                  NUMBER;
    l_new_balance           NUMBER;
    l_fc_new_balance        NUMBER;
    l_count                 PLS_INTEGER;
    l_total_count           PLS_INTEGER;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Accumulate_Reminders';
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Accumulate_Reminders');
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_source_payment = '||pi_source_payment);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_rate = '||pi_rate);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_rate_type = '||pi_rate_type);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_rate_date = '||to_char(pi_rate_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_appl_date = '||to_char(pi_appl_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_value_date = '||to_char(pi_value_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_due_date = '||to_char(pi_due_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_limit_amount = '||pi_limit_amount);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_update_trx = '||pi_update_trx);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_source_amount = '||pio_source_amount);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_fc_source_amount = '||pio_fc_source_amount);

    l_payment := NEW blc_payments_type(pi_source_payment, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_trx_target_set := 0;
    l_trx_fc_target_set := 0;
    l_unapplied_amount := pi_limit_amount;
    --
    SELECT count(*)
    INTO l_total_count
    FROM TABLE(blc_appl_cache_pkg.g_trx_table) bt
    WHERE (pi_due_date IS NULL OR bt.due_date = pi_due_date)
    AND (pi_doc_id IS NULL OR bt.doc_id = pi_doc_id)
    AND bt.balance <> 0;
    --
    l_count := 1;
    --
    FOR c_trx_id IN ( SELECT bt.transaction_id, bt.currency, bt.rate, bt.rate_type,
                          bt.item_id, bt.account_id, bt.balance, bt.fc_balance,
                          bt.transaction_class
                      FROM TABLE(blc_appl_cache_pkg.g_trx_table) bt
                      WHERE (pi_due_date IS NULL OR bt.due_date = pi_due_date)
                        AND (pi_doc_id IS NULL OR bt.doc_id = pi_doc_id)
                        AND bt.balance <> 0
                      ORDER BY SIGN( blc_appl_util_pkg.Calc_Appl_Sign(bt.transaction_class, l_payment.payment_class)*bt.balance ), -- Add RQ1000010253
                               bt.priority, --15.02.2018
                               bt.due_date,
                               bt.transaction_id) --15.02.2018
                               --Calc_Appl_Sign(bt.transaction_class, l_payment.payment_class)*bt.balance, --15.02.2018 no needed after addition of transaction_id
                               --bt.currency) --15.02.2018 no needed after addition of transaction_id
    LOOP
      IF l_unapplied_amount IS NULL OR l_unapplied_amount > 0
      THEN
        l_sign := blc_appl_util_pkg.Calc_Appl_Sign(c_trx_id.transaction_class, l_payment.payment_class);

        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_current_transaction_id = '||c_trx_id.transaction_id||' sign = '||l_sign);
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_unapplied_amount = '||l_unapplied_amount);
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_trx_target_set = '||l_trx_target_set);
        blc_appl_cache_pkg.Init_Trx_Currency( c_trx_id.currency );
        --
        IF blc_appl_cache_pkg.g_rec_currency = blc_appl_cache_pkg.g_trx_currency
        THEN
           l_trx_balance_rcpt := c_trx_id.balance;
        ELSE
           l_rate := blc_common_pkg.Get_Currency_Rate(blc_appl_cache_pkg.g_trx_currency,blc_appl_cache_pkg.g_fc_currency,blc_appl_cache_pkg.g_country,pi_rate_date,pi_rate_type,pio_Err);
           IF NOT srv_error.rqStatus( pio_Err )
           THEN
              RETURN;
           END IF;
           IF blc_appl_cache_pkg.g_trx_currency = blc_appl_cache_pkg.g_fc_currency
           THEN
              l_trx_balance_rcpt := ROUND( c_trx_id.balance / NVL(pi_rate,1), blc_appl_cache_pkg.g_rec_precision );
           ELSE
              l_trx_balance_rcpt := ROUND( ROUND(c_trx_id.balance*l_rate, blc_appl_cache_pkg.g_fc_precision) / NVL(pi_rate,1), blc_appl_cache_pkg.g_rec_precision );
           END IF;
        END IF;

        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_trx_balance_rcpt = '||l_trx_balance_rcpt);
        --
        --IF l_unapplied_amount IS NOT NULL AND abs(l_trx_balance_rcpt) > l_unapplied_amount
        IF l_unapplied_amount IS NOT NULL AND abs(l_trx_balance_rcpt + l_sign*l_trx_target_set) > pi_limit_amount -- add l_sign - rq 1000010596
        THEN
           l_trx_balance_rcpt := sign(l_trx_balance_rcpt)*l_unapplied_amount;
           IF blc_appl_cache_pkg.g_trx_currency = blc_appl_cache_pkg.g_rec_currency
           THEN
              l_trx_apply_amount := l_trx_balance_rcpt;
           ELSE
              IF blc_appl_cache_pkg.g_rec_currency = blc_appl_cache_pkg.g_fc_currency
              THEN
                 l_trx_apply_amount := ROUND( l_trx_balance_rcpt/l_rate,blc_appl_cache_pkg.g_trx_precision);
              ELSE
                 l_trx_apply_amount := ROUND(ROUND( l_trx_balance_rcpt*NVL(pi_rate,1),blc_appl_cache_pkg.g_fc_precision) / l_rate,blc_appl_cache_pkg.g_trx_precision);
              END IF;
           END IF;
        ELSE
           l_trx_apply_amount := c_trx_id.balance;
        END IF;
        --
        IF l_count = l_total_count AND
           substr(l_payment.payment_class,1,1) = 'O' AND
           l_unapplied_amount IS NULL AND
           l_payment.amount > 0
        THEN
           l_trx_balance_rcpt := l_payment.amount - l_trx_target_set;
        ELSE
           l_trx_balance_rcpt := l_sign*l_trx_balance_rcpt; --rq 1000011010
        END IF;
        --
        --l_trx_balance_rcpt := l_sign*l_trx_balance_rcpt; --rq 1000011010 move into previous ELSE
        --
        IF blc_appl_cache_pkg.g_rec_currency = blc_appl_cache_pkg.g_fc_currency
        THEN
           l_trx_fc_balance_rcpt := l_trx_balance_rcpt;
        ELSE
           l_trx_fc_balance_rcpt := ROUND( l_trx_balance_rcpt * pi_rate, blc_appl_cache_pkg.g_fc_precision );
        END IF;
        --
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_trx_balance_rcpt = '||l_trx_balance_rcpt);
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_trx_apply_amount = '||l_trx_apply_amount);

        blc_appl_util_pkg.Apply_PMNT_ON_TRANSACTION
            (pi_appl_date        => pi_appl_date,
             pi_value_date       => pi_value_date,
             pi_rate_date        => pi_rate_date,
             pi_source_amount    => l_trx_balance_rcpt, --
             pi_source_rate      => pi_rate,
             pi_source_rate_type => pi_rate_type,
             pi_target_amount    => l_trx_apply_amount, --
             pi_target_rate      => c_trx_id.rate,
             pi_target_rate_type => c_trx_id.rate_type,
             pi_target_trx       => c_trx_id.transaction_id,
             pi_target_item      => c_trx_id.item_id,
             pi_account_id       => c_trx_id.account_id,
             pi_source_payment   => pi_source_payment,
             po_application_id   => l_application_id,
             pio_Err             => pio_Err);
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            RETURN;
        END IF;

        IF pi_update_trx = 'Y'
        THEN
           --calculate new balance of debit transaction
           l_new_balance := c_trx_id.balance - l_trx_apply_amount;
           IF c_trx_id.currency = blc_appl_cache_pkg.g_fc_currency
           THEN
              l_fc_new_balance := c_trx_id.fc_balance - l_trx_apply_amount;
           ELSE
              l_fc_new_balance := c_trx_id.fc_balance - round(l_trx_apply_amount*c_trx_id.rate,blc_appl_cache_pkg.g_fc_precision);
           END IF;
           --update selected transaction balance with new calculated
           Update_Trx_Balance(c_trx_id.transaction_id, l_new_balance, l_fc_new_balance);
        END IF;

        --
        l_trx_target_set := l_trx_target_set + l_trx_balance_rcpt;
        l_trx_fc_target_set := l_trx_fc_target_set + l_trx_fc_balance_rcpt;
        --l_unapplied_amount := l_unapplied_amount - abs(l_trx_balance_rcpt);
        l_unapplied_amount := pi_limit_amount - abs(l_trx_target_set);
        l_count := l_count + 1;
      END IF;
    END LOOP;
    --
    pio_source_amount := nvl(pio_source_amount,0) - l_trx_target_set;
    pio_fc_source_amount := nvl(pio_fc_source_amount,0) - l_trx_fc_target_set;
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_source_amount = '||pio_source_amount);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_fc_source_amount = '||pio_fc_source_amount);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Accumulate_Reminders');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Accumulate_Reminders', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_source_payment = '||pi_source_payment||' - '||SQLERRM);
END Accumulate_Reminders;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Is_Pmnt_Adv_Claim
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   15.01.2020  creation - CHA93S-8
--     Fadata   11.03.2020  CHA93S-27
--
-- Purpose: Check if payment is related to advance claim
--
-- Input parameters:
--     pi_payment_id   NUMBER     Payment identifier (required)
--
-- Returns: Y/N
--
-- Usage: when need to know if payment is for advance claim
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Pmnt_Adv_Claim
   (pi_payment_id     IN     NUMBER)
RETURN VARCHAR2
IS
   l_log_module          VARCHAR2(240);
   l_count               PLS_INTEGER;
   l_count_clm           SIMPLE_INTEGER := 0;
   l_adv                 VARCHAR2(1);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Is_Pmnt_Adv_Claim';

   /*
   SELECT count(*)
   INTO l_count
   FROM blc_applications ba,
        blc_items bi,
        claim_payments cp,
        claim_doclad cd
   WHERE ba.source_payment = pi_payment_id
   AND ba.target_item = bi.item_id
   AND TO_NUMBER(bi.agreement) =  cp.claim_id
   AND TO_NUMBER(bi.detail) = cp.payment_id
   AND cp.doclad_id = cd.doclad_id
   AND cd.payment_type = '1';
   */
   SELECT count(*)
   INTO l_count
   FROM blc_applications ba,
        blc_transactions bt,
        blc_lookups blp
   WHERE ba.source_payment = pi_payment_id
   AND ba.target_trx = bt.transaction_id
   AND bt.pay_way_id = blp.lookup_id
   AND blp.lookup_code = 'ADVANCE_PAYMENT';

    -- Begin CHA93S-27
    SELECT SUM(NVL2(bl.lookup_code,1,0))
    INTO l_count_clm
    FROM blc_applications ba,
        blc_items bi,
        claim_payments_details cpd,
        blc_lookups bl
    WHERE ba.source_payment = pi_payment_id
        AND ba.target_item = bi.item_id
        AND bi.item_type = 'CLAIM'
        AND cpd.claim_id = TO_NUMBER( bi.agreement )
        AND cpd.payment_id = TO_NUMBER( bi.detail )
        AND cpd.cover_type = bl.attrib_1(+)
        AND cpd.risk_type = bl.attrib_2(+)
        AND NVL(bl.lookup_set,'LPV_CLAIM_COVER_RISK') = 'LPV_CLAIM_COVER_RISK';
    -- End CHA93S-27

   IF l_count = 0
       AND l_count_clm = 0 -- CHA93S-27
   THEN
      l_adv := 'N';
   ELSE
      l_adv := 'Y';
   END IF;

   RETURN l_adv;
EXCEPTION
    WHEN OTHERS THEN
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
      RETURN 'N';
END Is_Pmnt_Adv_Claim;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Clear_Adv_Claim_Payments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.01.2020  creation - CHA93S-8
--
-- Purpose: Execute clear payment for advance claim related payments
--
-- Input parameters:
--     pi_legal_entity_id     NUMBER       Legal entity Id (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In job program to cleal advance claim payments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Clear_Adv_Claim_Payments
   (pi_legal_entity_id    IN     NUMBER,
    pio_Err               IN OUT SrvErr)
IS
    l_log_module     VARCHAR2(240);
    l_SrvErrMsg      SrvErrMsg;
    l_SrvErr         SrvErr;
    l_Context        srvcontext;
    l_RetContext     srvcontext;
    l_changed_status VARCHAR2(30);
    l_count          PLS_INTEGER;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Clear_Adv_Claim_Payments';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Clear_Adv_Claim_Payments');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_legal_entity_id = '||pi_legal_entity_id);

    srv_context.SetContextAttrChar( l_Context, 'DEFAULT_CLEAR', 'Y' );
    srv_context.SetContextAttrChar( l_Context, 'EXECUTE_CONFIRM', 'Y' );

    l_count := 0;
    FOR c_payment IN (SELECT bp.payment_id
                      FROM blc_payments bp
                      WHERE bp.status = 'S'
                      AND bp.legal_entity = pi_legal_entity_id
                      AND cust_pay_util_pkg.Is_Pmnt_Adv_Claim(payment_id) = 'Y'
                      ORDER BY 1)
    LOOP
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_payment_id = '||c_payment.payment_id);
        l_SrvErr := NULL;
        l_RetContext := NULL;

        srv_context.SetContextAttrNumber( l_Context, 'PAYMENT_ID', srv_context.Integers_Format, c_payment.payment_id);

        srv_events.sysEvent( 'CREATE_BLC_CLEARING', l_Context, l_RetContext, l_SrvErr );

        l_changed_status := srv_prm_process.Get_Payment_Status( l_RetContext );

        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'l_payment_id = '||c_payment.payment_id||' - changed_status = '||l_changed_status);
        --
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
           FOR i IN l_SrvErr.first..l_SrvErr.last
           LOOP
             IF pio_Err IS NULL
             THEN
                pio_Err := SrvErr(l_SrvErr(i));
             ELSE
                l_count := pio_Err.count;
                pio_Err.extend;
                pio_Err(l_count+1) := l_SrvErr(i);
              END IF;
           END LOOP;
           ROLLBACK;
        ELSE
           COMMIT;
        END IF;
    END LOOP;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Clear_Adv_Claim_Payments');
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pay_util_pkg.Clear_Adv_Claim_Payments', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_legal_entity_id = '||pi_legal_entity_id||' - '|| SQLERRM);
END Clear_Adv_Claim_Payments;
--
END CUST_PAY_UTIL_PKG;
/


