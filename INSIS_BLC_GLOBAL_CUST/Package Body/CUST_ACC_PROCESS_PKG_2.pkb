CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.cust_acc_process_pkg_2 AS

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains procedures for create and validate accounting transactions
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

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_acc_process_pkg_2';
--==============================================================================

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Check_Events_Status
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Check event statuses of given event list and if exists statuses in
-- ('U','E','P') or input error_flag = 'Y' delete all accounting transactions
-- and set event statuses to 'Z' (for manual processing)
--
-- Input parameters:
--     pi_event_ids        BLC_SELECTED_OBJECTS_TABLE  List of event ids, delimited with comma
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_err_flag         VARCHAR2  Error flag
--     po_acction_error    VARCHAR2  Action error notes
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In schedule process for create accounting
--------------------------------------------------------------------------------
PROCEDURE Check_Events_Status( pi_event_ids    IN     BLC_SELECTED_OBJECTS_TABLE,
                               po_err_flag     OUT    VARCHAR2,
                               po_action_error OUT    VARCHAR2,
                               pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_err_flag  VARCHAR2(1) := cust_gvar.FLG_NO;
    l_error_msg VARCHAR2(32000);
BEGIN
    FOR evnts IN ( SELECT event_status, COUNT(*) AS lines_count,
                           DECODE( event_status, cust_gvar.ACC_UNPROCESS, 'Unprocessed', cust_gvar.ACC_ERROR , 'Error', cust_gvar.ACC_PENDING, 'Pending', cust_gvar.ACC_ACCOUNTED, 'Accounted' ) AS event_label,
                           LISTAGG(error_code, ';') WITHIN GROUP (ORDER BY error_code) AS err_msg
                       FROM BLC_SLA_EVENT_STATUS
                       WHERE event_id IN ( SELECT * FROM TABLE(pi_event_ids) )
                       GROUP BY event_status
                       ORDER BY DECODE( event_status, cust_gvar.ACC_ERROR, 2, 1 ) )
    LOOP
       IF evnts.event_status IN ( cust_gvar.ACC_UNPROCESS, cust_gvar.ACC_ERROR, cust_gvar.ACC_PENDING )
       THEN
          l_err_flag := cust_gvar.FLG_YES;
          l_error_msg := l_error_msg || '; ' || ' ' || evnts.event_label || ' lines = ' || evnts.lines_count || ' ' || evnts.err_msg;
       END IF;
    END LOOP;
    --
    po_err_flag := l_err_flag;
    po_action_error := l_error_msg;
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Check_Events_Status', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, SQLERRM);
END Check_Events_Status;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Check_Events_Status_2
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   04.01.2018  creation
--
-- Purpose: Check event statuses of event with given attrib_9 and if exists
-- statuses in ('U','E','P') or input error_flag = 'Y' delete all accounting
-- transactions and set event statuses to 'Z' (for manual processing)
--
-- Input parameters:
--     pi_attrib_9         VARCHAR2  Attrib_9 (voucher doc_id)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_err_flag         VARCHAR2  Error flag
--     po_acction_error    VARCHAR2  Action error notes
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In schedule process for create accounting
--------------------------------------------------------------------------------
PROCEDURE Check_Events_Status_2( pi_attrib_9     IN     VARCHAR2,
                                 po_err_flag     OUT    VARCHAR2,
                                 po_action_error OUT    VARCHAR2,
                                 pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_err_flag      VARCHAR2(1) := cust_gvar.FLG_NO;
    l_err_msg       VARCHAR2(2000);
    l_error_msg     VARCHAR2(32000);
BEGIN
    FOR evnts IN ( SELECT bs.event_status, COUNT(*) AS lines_count,
                          DECODE( bs.event_status, cust_gvar.ACC_UNPROCESS, 'Unprocessed', cust_gvar.ACC_ERROR , 'Error', cust_gvar.ACC_PENDING, 'Pending', cust_gvar.ACC_ACCOUNTED, 'Accounted' ) AS event_label
                   FROM blc_sla_event_status bs,
                        blc_sla_events be
                   WHERE be.attrib_9 = pi_attrib_9
                   AND be.event_id = bs.event_id
                   GROUP BY bs.event_status
                   ORDER BY DECODE( bs.event_status, cust_gvar.ACC_ERROR, 2, 1 ) )
    LOOP
       IF evnts.event_status IN ( cust_gvar.ACC_UNPROCESS, cust_gvar.ACC_ERROR, cust_gvar.ACC_PENDING )
       THEN
          l_err_flag := cust_gvar.FLG_YES;
          l_err_msg := NULL;
          FOR c_ev_status IN ( SELECT bs.error_code
                               FROM blc_sla_event_status bs,
                                    blc_sla_events be
                               WHERE be.attrib_9 = pi_attrib_9
                               AND be.event_id = bs.event_id
                               AND bs.event_status = evnts.event_status
                               GROUP BY bs.error_code)
          LOOP
             IF l_err_msg IS NULL
             THEN
                l_err_msg := c_ev_status.error_code;
             ELSIF length(l_err_msg||'; '||c_ev_status.error_code) <= 2000
             THEN
                l_err_msg := l_err_msg||'; '||c_ev_status.error_code;
             END IF;
          END LOOP;

          l_error_msg := l_error_msg || '; ' || ' ' || evnts.event_label || ' lines = ' || evnts.lines_count || ' ' || l_err_msg;
       END IF;
    END LOOP;
    --
    po_err_flag := l_err_flag;
    po_action_error := l_error_msg;
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Check_Events_Status_2', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, SQLERRM);
END Check_Events_Status_2;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Set_Events_Status_Z
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Delete all accounting transactions and set event statuses to 'Z'
-- (for manual processing)
--
-- Input parameters:
--     pi_attrib_9         VARCHAR2  Attrib_9 (voucher doc_id)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In schedule process for create accounting
--------------------------------------------------------------------------------
PROCEDURE Set_Events_Status_Z_2( pi_attrib_9     IN     VARCHAR2,
                                 pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
BEGIN
    DELETE blc_gl_insis2gl bg
    WHERE EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.attrib_9 = pi_attrib_9
                  AND be.event_id = bg.event_id);
    --
    UPDATE blc_sla_event_status bs
    SET bs.event_status = cust_gvar.ACC_MANUALPROCESS
    WHERE EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.attrib_9 = pi_attrib_9
                  AND be.event_id = bs.event_id);
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Events_Status_Z_2', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, SQLERRM);
END Set_Events_Status_Z_2;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Set_Events_Status_Z_2
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   04.01.2018  creation
--
-- Purpose: Delete all accounting transactions and set event statuses to 'Z'
-- (for manual processing)
--
-- Input parameters:
--     pi_event_ids        BLC_SELECTED_OBJECTS_TABLE  List of event ids, delimited with comma
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In schedule process for create accounting
--------------------------------------------------------------------------------
PROCEDURE Set_Events_Status_Z( pi_event_ids    IN     BLC_SELECTED_OBJECTS_TABLE,
                               pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
BEGIN
    DELETE blc_gl_insis2gl
    WHERE event_id IN ( SELECT * FROM TABLE(pi_event_ids) );
    --
    UPDATE blc_sla_event_status SET event_status = cust_gvar.ACC_MANUALPROCESS
    WHERE event_id IN ( SELECT * FROM TABLE(pi_event_ids) );
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Events_Status_Z', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, SQLERRM);
END Set_Events_Status_Z;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Proforma_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Create a document for the accounting events for given document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Proforma_Voucher( pi_doc_id       IN     NUMBER,
                                   pi_le_id        IN     NUMBER,
                                   pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                   po_acc_doc_id   OUT    NUMBER,
                                   pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_doc_number    VARCHAR2(100);
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    --
    l_doc           BLC_DOCUMENTS_TYPE;
    l_ref_doc_id    NUMBER;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Proforma_Voucher';

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Proforma_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);

    FOR c_doc IN (SELECT bt.doc_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list,
                         bt.org_id,
                         DECODE(be.reversal_flag,'N','1','2') reversal_order
                  FROM  blc_sla_events be,
                        blc_transactions bt,
                        blc_documents bd
                  WHERE pi_doc_id IS NOT NULL
                  AND bt.doc_id = pi_doc_id
                  AND be.event_type = 'TRX_APPROVED'
                  AND be.attrib_9 IS NULL
                  AND bt.transaction_id = be.transaction_id
                  AND bt.transaction_type IN ('PREMIUM','PREMIUM_SAVING','VAT')
                  AND bt.doc_id = bd.doc_id
                  AND ((bd.amount <> 0 AND bd.status <> cust_gvar.STATUS_DELETED) OR bd.status = cust_gvar.STATUS_DELETED)
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.transaction_id = bt.transaction_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.transaction_id = bt.transaction_id
                                     AND be1.reversal_flag = cust_gvar.FLG_NO
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.legal_entity, be.reversal_flag, be.event_date, bt.doc_id, bt.org_id
                  UNION ALL
                  SELECT bt.doc_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list,
                         bt.org_id,
                         DECODE(be.reversal_flag,'N','1','2') reversal_order
                  FROM  blc_sla_events be,
                        blc_transactions bt,
                        blc_documents bd
                  WHERE pi_doc_id IS NULL
                  AND be.legal_entity = pi_le_id
                  AND be.event_type = 'TRX_APPROVED'
                  AND be.attrib_9 IS NULL
                  AND bt.transaction_id = be.transaction_id
                  AND bt.transaction_type IN ('PREMIUM','PREMIUM_SAVING','VAT')
                  AND bt.doc_id = bd.doc_id
                  --AND bd.status <> cust_gvar.STATUS_DELETED --31.01.2018
                  AND ((bd.amount <> 0 AND bd.status <> cust_gvar.STATUS_DELETED) OR bd.status = cust_gvar.STATUS_DELETED) --31.01.2018
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.transaction_id = bt.transaction_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.transaction_id = bt.transaction_id
                                     AND be1.reversal_flag = cust_gvar.FLG_NO
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.legal_entity, be.reversal_flag, be.event_date, bt.doc_id, bt.org_id
                  ORDER BY doc_id, reversal_order
                  )
    LOOP
       blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'c_doc.doc_id = '||c_doc.doc_id);

       IF c_doc.reversal_flag = cust_gvar.FLG_NO
       THEN
          l_prefix := 'I001-CRE';
          l_ref_doc_id := NULL;
       ELSE
          l_prefix := 'I003-ANN';
          BEGIN
            SELECT bd.doc_id
            INTO l_ref_doc_id
            FROM blc_documents bd,
                 blc_lookups bl
            WHERE bd.doc_suffix = to_char(c_doc.doc_id)
            AND bd.doc_prefix = 'I001-CRE'
            AND bd.doc_type_id = bl.lookup_id
            AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
         EXCEPTION
            WHEN OTHERS THEN
              srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Proforma_Voucher', 'cust_acc_process_pkg_2.CPV.No_Ref_Doc', 'I001-CRE|'||c_doc.doc_id );
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                         'c_doc.doc_id = '||c_doc.doc_id||' - Cannot calculate voucher doc_id for not reversal event');
              RETURN;
          END;
       END IF;

       l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

       SAVEPOINT CREATE_DOC;

       blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.doc_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   l_ref_doc_id,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   NULL,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   po_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
       --
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       l_doc := blc_documents_type(po_acc_doc_id);

       l_doc.status := cust_gvar.STATUS_VALID;

       IF NOT l_doc.update_blc_documents(pio_Err)
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'po_acc_doc_id = '||po_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       UPDATE blc_sla_events
       SET attrib_9 = po_acc_doc_id
       WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

       IF pi_batch_flag = 'Y'
       THEN
          COMMIT;
       END IF;

    END LOOP;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'po_acc_doc_id = '||po_acc_doc_id);

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Proforma_Voucher');
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Proforma_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Create_Proforma_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Payment_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   26.11.2017  creation
--
-- Purpose: Create a document for the accounting events for given payment
--
-- Input parameters:
--     pi_payment_id       NUMBER    Payment Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Payment_Voucher( pi_payment_id   IN     NUMBER,
                                  pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  po_acc_doc_id   OUT    NUMBER,
                                  pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_doc_number    VARCHAR2(100);
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    --
    l_doc           BLC_DOCUMENTS_TYPE;
    l_ref_doc_id    NUMBER;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Payment_Voucher';

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Payment_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);

    FOR c_doc IN (SELECT bp.payment_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list,
                         bp.org_id,
                         DECODE(be.reversal_flag,'N','1','2') reversal_order
                  FROM  blc_sla_events be,
                        blc_payments bp,
                        blc_bacc_usages bu
                  WHERE pi_payment_id IS NOT NULL
                  AND bp.payment_id = pi_payment_id
                  AND be.event_type = 'PAYMENT_APPROVED'
                  AND bp.payment_id = be.payment_id
                  AND bp.usage_id = bu.usage_id
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND be.attrib_9 IS NULL
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.payment_id = bp.payment_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND bp.status    = cust_gvar.STATUS_REJECT --LPV-1151
                        AND (be.attrib_9 IS NULL OR be.attrib_9 = (SELECT be1.attrib_9
                                                                   FROM blc_sla_events be1
                                                                   WHERE be1.payment_id = bp.payment_id
                                                                   AND be1.reversal_flag = cust_gvar.FLG_NO
                                                                   AND be1.attrib_9 IS NOT NULL
                                                                   AND be1.event_id = be.previous_event))
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.payment_id = bp.payment_id
                                     AND be1.reversal_flag = cust_gvar.FLG_NO
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.legal_entity, be.reversal_flag, be.event_date, bp.payment_id, bp.org_id
                  UNION ALL
                  SELECT bp.payment_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list,
                         bp.org_id,
                         DECODE(be.reversal_flag,'N','1','2') reversal_order
                  FROM  blc_sla_events be,
                        blc_payments bp,
                        blc_bacc_usages bu
                  WHERE pi_payment_id IS NULL
                  AND be.legal_entity = pi_le_id
                  AND be.event_type = 'PAYMENT_APPROVED'
                  AND bp.payment_id = be.payment_id
                  AND bp.usage_id = bu.usage_id
                  AND bu.attrib_0 IN ('CLAIM') --(,'SURRENDER','MATURITY','PARTSRNDR','PAIDUPSRNDR')
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND be.attrib_9 IS NULL
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.payment_id = bp.payment_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND bp.status    = cust_gvar.STATUS_REJECT --LPV-1151
                        AND (be.attrib_9 IS NULL OR be.attrib_9 = (SELECT be1.attrib_9
                                                                   FROM blc_sla_events be1
                                                                   WHERE be1.payment_id = bp.payment_id
                                                                   AND be1.reversal_flag = cust_gvar.FLG_NO
                                                                   AND be1.attrib_9 IS NOT NULL
                                                                   AND be1.event_id = be.previous_event))
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.payment_id = bp.payment_id
                                     AND be1.reversal_flag = 'N'
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.legal_entity, be.reversal_flag, be.event_date, bp.payment_id, bp.org_id
                  ORDER BY payment_id, reversal_order
                  )
    LOOP
       blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'c_doc.payment_id = '||c_doc.payment_id);

       IF c_doc.reversal_flag = cust_gvar.FLG_NO
       THEN
          l_prefix := 'I009';
          l_ref_doc_id := NULL;
       ELSE
          l_prefix := 'I011-1';
          BEGIN
            SELECT bd.doc_id
            INTO l_ref_doc_id
            FROM blc_documents bd,
                 blc_lookups bl
            WHERE bd.doc_suffix = to_char(c_doc.payment_id)
            AND bd.doc_prefix = 'I009'
            AND bd.doc_type_id = bl.lookup_id
            AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
         EXCEPTION
            WHEN OTHERS THEN
              srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Payment_Voucher', 'cust_acc_process_pkg_2.CPV.No_Ref_Doc', 'I009|'||c_doc.payment_id );
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                         'c_doc.payment_id = '||c_doc.payment_id||' - Cannot calculate voucher doc_id for not reversal event');
              RETURN;
          END;
       END IF;

       l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

       SAVEPOINT CREATE_DOC;

       blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.payment_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   l_ref_doc_id,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   NULL,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   po_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
       --
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'c_doc.payment_id = '||c_doc.payment_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       l_doc := blc_documents_type(po_acc_doc_id);

       l_doc.status := cust_gvar.STATUS_VALID;

       IF NOT l_doc.update_blc_documents(pio_Err)
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'po_acc_doc_id = '||po_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       UPDATE blc_sla_events
       SET attrib_9 = po_acc_doc_id
       WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

       IF pi_batch_flag = 'Y'
       THEN
          COMMIT;
       END IF;

    END LOOP;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'po_acc_doc_id = '||po_acc_doc_id);

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Payment_Voucher');
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Payment_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Create_Payment_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Claim_Adj_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.11.2017  creation
--
-- Purpose: Create a document for the accounting events for claim adjustments
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Claim_Adj_Voucher( pi_le_id        IN     NUMBER,
                                    pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                    pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    l_acc_doc_id    NUMBER;
    l_doc_number    VARCHAR2(100);
    --
    l_doc           BLC_DOCUMENTS_TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Claim_Adj_Voucher';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Claim_Adj_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);
    --
    FOR c_doc IN ( SELECT bi.external_id,
                       bi.org_id,
                       be.legal_entity,
                       be.event_date,
                       DECODE( bi.installment_type, 'CLMDUE', '1', 'CLMDUEAC', '1', 'CLMDUERI', '2', 'CLMDUECO', '1' )  AS header_class,
                       LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                   FROM blc_sla_events be,
                        blc_installments bi,
                        blc_items i
                   WHERE be.legal_entity = pi_le_id
                       AND be.event_type = 'RECOGN_EXP'
                       AND be.attrib_9 IS NULL
                       AND bi.installment_id = be.installment_id
                       AND bi.item_id = i.item_id
                       AND i.item_type = 'CLAIM'
                       AND i.detail IS NULL
                       AND bi.installment_type IN ( 'CLMDUE', 'CLMDUEAC', 'CLMDUERI', 'CLMDUECO' )
                       AND bi.external_id IS NOT NULL  -- !!??
                   GROUP BY be.legal_entity, be.event_date, bi.external_id, bi.org_id,
                       DECODE( bi.installment_type, 'CLMDUE', '1', 'CLMDUEAC', '1', 'CLMDUERI', '2', 'CLMDUECO', '1' )
                   ORDER BY bi.external_id )
    LOOP
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'external_id = '||c_doc.external_id);
        --
        IF c_doc.header_class = '1'
        THEN
            l_prefix := 'I007-1';
        ELSE
            l_prefix := 'I007-2';
        END IF;
        --
        l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

        SAVEPOINT CREATE_DOC;

        blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.external_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   NULL,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   NULL,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   l_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'c_doc.external_id = '||c_doc.external_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        l_doc := blc_documents_type(l_acc_doc_id);

        l_doc.status := cust_gvar.STATUS_VALID;

        IF NOT l_doc.update_blc_documents(pio_Err)
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'l_acc_doc_id = '||l_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        UPDATE blc_sla_events
        SET attrib_9 = l_acc_doc_id
        WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

        IF pi_batch_flag = 'Y'
        THEN
            COMMIT;
        END IF;

        blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'l_acc_doc_id = '||l_acc_doc_id);
    END LOOP;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Claim_Adj_Voucher');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Claim_Adj_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_le_id = '||pi_le_id||' - '||SQLERRM);
END Create_Claim_Adj_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Get_Org_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   30.11.2017  creation
--
-- Purpose: Find first org_id with role BILLING for Legal Entity
--
-- Input parameters:
--     pi_le_id         NUMBER       Legal Entity Id;
--
-- Returns:
-- Org Id
--
-- Usage: In pkg, reserve
--------------------------------------------------------------------------------
FUNCTION Get_Org_Id( pi_le_id IN NUMBER )
RETURN NUMBER
IS
    CURSOR cur_orgs IS
    SELECT a.org_id
    FROM blc_org_roles a, blc_orgs b
    WHERE legal_entity_id = pi_le_id
        AND blc_common_pkg.get_lookup_code(lookup_id) = 'BILLING'
        AND a.org_id = b.org_id
        AND parent_org_id = 0
    ORDER BY a.org_id;
    --
    CURSOR cur_orgs2 IS
    SELECT org_id
    FROM blc_org_roles
    WHERE legal_entity_id = pi_le_id
        AND blc_common_pkg.get_lookup_code(lookup_id) = 'BILLING'
    ORDER BY org_id;
    --
    l_org_id   NUMBER;
BEGIN
    --
    IF pi_le_id IS NULL
    THEN RETURN NULL;
    END IF;
    --
    OPEN cur_orgs;
    FETCH cur_orgs INTO l_org_id;
    CLOSE cur_orgs;
    --
    IF l_org_id IS NULL
    THEN
        OPEN cur_orgs2;
        FETCH cur_orgs2 INTO l_org_id;
        CLOSE cur_orgs2;
    END IF;
    --
    RETURN l_org_id;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Reserve_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.11.2017  creation
--              31.05.2018  LPV-355 add event_types 07,08,09,10
--
-- Purpose: Create a document for the accounting events for reserves
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Reserve_Voucher( pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_org_id        NUMBER;
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    l_acc_doc_id    NUMBER;
    l_doc_number    VARCHAR2(100);
    --
    l_doc           BLC_DOCUMENTS_TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Reserve_Voucher';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Reserve_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);
    --
    l_prefix := 'I058';
    l_org_id := Get_Org_Id( pi_le_id );
    IF l_org_id IS NULL
    THEN
        RETURN;
    END IF;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'l_org_id = '||l_org_id);
    --
    FOR c_doc IN ( SELECT be.legal_entity,
                       be.event_date,
                       bsa.c_attrib_2  AS currency,
                       bsa.n_attrib_4  AS rate,
                       bsa.c_attrib_11 AS office,
                       DECODE( be.event_type, 'EXTAVINCR', '01',
                                              'EXTGRINCR', '02', 'EXTNRINCR', '02', 'EXTZRINCR', '02',
                                              'EXTUPRINCR', '03', --'EXTDACINCR', '03',
                                              'EXTRIUPRINCR', '05', --'EXTRIDACINCR', '05',
                                              'EXTIBNRGR', '07',
                                              'EXTIBNRCR', '08',
                                              'EXTCEXPALL', '09',
                                              'EXTCEXPUNALL', '10',
                                              NULL ) AS event_type,
                       LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                   FROM blc_sla_events be,
                        blc_staging_area bsa
                   WHERE be.legal_entity = pi_le_id
                       AND be.event_class = 'E'
                       AND be.event_type IN ( 'EXTAVINCR', 'EXTGRINCR', 'EXTNRINCR', 'EXTZRINCR', 'EXTUPRINCR', 'EXTRIUPRINCR',
                                              'EXTIBNRGR', 'EXTIBNRCR', 'EXTCEXPALL', 'EXTCEXPUNALL' ) --'EXTDACINCR', , 'EXTRIDACINCR' )  -- ???
                       AND be.attrib_9 IS NULL
                       AND be.dataset_id = bsa.dataset_id
                   GROUP BY be.legal_entity, be.event_date, bsa.c_attrib_2, bsa.n_attrib_4, bsa.c_attrib_11,
                       DECODE( be.event_type, 'EXTAVINCR', '01',
                                              'EXTGRINCR', '02', 'EXTNRINCR', '02', 'EXTZRINCR', '02',
                                              'EXTUPRINCR', '03', --'EXTDACINCR', '03',
                                              'EXTRIUPRINCR', '05', --'EXTRIDACINCR', '05',
                                              'EXTIBNRGR', '07',
                                              'EXTIBNRCR', '08',
                                              'EXTCEXPALL', '09',
                                              'EXTCEXPUNALL', '10',
                                              NULL )
                   ORDER BY be.event_date, event_type )
    LOOP
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'external_id = '||c_doc.event_type);
        --
        l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

        SAVEPOINT CREATE_DOC;

        blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   l_org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   NULL,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   NULL,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   NULL,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   l_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'c_doc.event_type = '||c_doc.event_type||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        l_doc := blc_documents_type(l_acc_doc_id);

        l_doc.status := cust_gvar.STATUS_VALID;

        IF NOT l_doc.update_blc_documents(pio_Err)
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'l_acc_doc_id = '||l_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        UPDATE blc_sla_events
        SET attrib_9 = l_acc_doc_id
        WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

        IF pi_batch_flag = 'Y'
        THEN
            COMMIT;
        END IF;

        blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'l_acc_doc_id = '||l_acc_doc_id);
    END LOOP;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Reserve_Voucher');
    --
/*
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Reserve_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_le_id = '||pi_le_id||' - '||SQLERRM);
*/
END Create_Reserve_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Claim_AC_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.12.2017  creation
--
-- Purpose: Create a document for the accounting events for AC claim
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Claim_AC_Voucher( pi_le_id        IN     NUMBER,
                                   pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                   pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    l_acc_doc_id    NUMBER;
    l_doc_number    VARCHAR2(100);
    --
    l_doc           BLC_DOCUMENTS_TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Claim_AC_Voucher';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Claim_AC_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);
    --
    FOR c_doc IN ( SELECT cust_acc_util_pkg.Get_Claim_Pmnt( bi.external_id ) claim_pmnt_id,
                          bi.postprocess,
                          bi.org_id,
                          be.legal_entity,
                          be.event_date,
                          LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                   FROM blc_sla_events be,
                        blc_installments bi,
                        blc_items i
                   WHERE be.legal_entity = pi_le_id
                       AND be.event_type = 'RECOGN_EXP'
                       AND be.attrib_9 IS NULL
                       AND bi.installment_id = be.installment_id
                       AND bi.item_id = i.item_id
                       AND i.item_type = 'AC'
                       AND bi.installment_type = 'BCCLAIMCOA'
                   GROUP BY cust_acc_util_pkg.Get_Claim_Pmnt( bi.external_id ),
                            bi.postprocess,
                            be.legal_entity,
                            be.event_date,
                            bi.org_id
                   ORDER BY cust_acc_util_pkg.Get_Claim_Pmnt( bi.external_id ) )
    LOOP
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'claim_pmnt_id = '||c_doc.claim_pmnt_id);
        --
        l_prefix := 'I008';
        --
        l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

        SAVEPOINT CREATE_DOC;

        blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.claim_pmnt_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   NULL,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   NULL,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   l_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'c_doc.claim_pmnt_id = '||c_doc.claim_pmnt_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        l_doc := blc_documents_type(l_acc_doc_id);

        l_doc.status := cust_gvar.STATUS_VALID;

        IF NOT l_doc.update_blc_documents(pio_Err)
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'l_acc_doc_id = '||l_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        UPDATE blc_sla_events
        SET attrib_9 = l_acc_doc_id
        WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

        IF pi_batch_flag = 'Y'
        THEN
            COMMIT;
        END IF;

        blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'l_acc_doc_id = '||l_acc_doc_id);
    END LOOP;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Claim_AC_Voucher');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Claim_AC_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_le_id = '||pi_le_id||' - '||SQLERRM);
END Create_Claim_AC_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Prem_AC_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.12.2017  creation
--
-- Purpose: Create a document for the accounting events for AC premium
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Prem_AC_Voucher( pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    l_acc_doc_id    NUMBER;
    l_doc_number    VARCHAR2(100);
    --
    l_doc           BLC_DOCUMENTS_TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Prem_AC_Voucher';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Prem_AC_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);
    --
    FOR c_doc IN ( SELECT i.component policy_id,
                          bi.annex,
                          bi.org_id,
                          be.legal_entity,
                          be.event_date,
                          LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                   FROM blc_sla_events be,
                        blc_installments bi,
                        blc_items i
                   WHERE be.legal_entity = pi_le_id
                       AND be.event_type = 'RECOGN_EXP'
                       AND be.attrib_9 IS NULL
                       AND bi.installment_id = be.installment_id
                       AND bi.item_id = i.item_id
                       AND i.item_type = 'AC'
                       AND bi.installment_type IN ('BCPRCOA','BCLFCOA','BCCOMMCOA')
                   GROUP BY i.component,
                            bi.annex,
                            be.legal_entity,
                            be.event_date,
                            bi.org_id
                   ORDER BY to_number(i.component) )
    LOOP
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'policy_id = '||c_doc.policy_id);
        --
        l_prefix := 'I001-CCR';
        --
        l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

        SAVEPOINT CREATE_DOC;

        blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.policy_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   NULL,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   NULL,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   l_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'c_doc.policy_id = '||c_doc.policy_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        l_doc := blc_documents_type(l_acc_doc_id);

        l_doc.status := cust_gvar.STATUS_VALID;

        IF NOT l_doc.update_blc_documents(pio_Err)
        THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'l_acc_doc_id = '||l_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            ROLLBACK TO CREATE_DOC;
            RETURN;
        END IF;

        UPDATE blc_sla_events
        SET attrib_9 = l_acc_doc_id
        WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

        IF pi_batch_flag = 'Y'
        THEN
            COMMIT;
        END IF;

        blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'l_acc_doc_id = '||l_acc_doc_id);
    END LOOP;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Prem_AC_Voucher');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Prem_AC_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_le_id = '||pi_le_id||' - '||SQLERRM);
END Create_Prem_AC_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Claim_CORI_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.12.2017  creation
--
-- Purpose: Create a document for the accounting events for given payment
-- clearing or for all clearing related events to a legal enity
--
-- Input parameters:
--     pi_clearing_id      NUMBER    Clearing Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Claim_CORI_Voucher( pi_clearing_id  IN     NUMBER,
                                     pi_le_id        IN     NUMBER,
                                     pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                     po_acc_doc_id   OUT    NUMBER,
                                     pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_doc_number    VARCHAR2(100);
    l_prefix        VARCHAR2(30);
    l_event_ids     BLC_SELECTED_OBJECTS_TABLE;
    --
    l_doc           BLC_DOCUMENTS_TYPE;
    l_ref_doc_id    NUMBER;
    --
    l_prefix_right  VARCHAR2(30);
    l_payment_id    NUMBER;
    --
    CURSOR c_pmnt (x_clearing_id IN NUMBER) IS
      SELECT payment_id
      FROM blc_clearings
      WHERE clearing_id = x_clearing_id;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_Claim_CORI_Voucher';

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Claim_CORI_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_clearing_id = '||pi_clearing_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);

    FOR c_doc IN (SELECT be.attrib_0 clearing_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list,
                         bii.org_id,
                         bi.item_type,
                         ba.party,
                         DECODE(be.reversal_flag, 'N','1','2') reversal_order
                  FROM  blc_sla_events be,
                        blc_installments bii,
                        blc_items bi,
                        blc_accounts ba
                  WHERE be.event_type = 'RECOGN_EXP_CLEAR_PMNT'
                  AND be.installment_id = bii.installment_id
                  AND (pi_clearing_id IS NULL OR pi_clearing_id IS NOT NULL AND be.attrib_0 = TO_CHAR(pi_clearing_id))
                  AND bii.item_id = bi.item_id
                  AND bii.account_id = ba.account_id
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND be.attrib_9 IS NULL
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.installment_id = bii.installment_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND (be.attrib_9 IS NULL OR be.attrib_9 = (SELECT be1.attrib_9
                                                                   FROM blc_sla_events be1
                                                                   WHERE be1.installment_id = bii.installment_id
                                                                   AND be1.reversal_flag = cust_gvar.FLG_NO
                                                                   AND be1.attrib_9 IS NOT NULL
                                                                   AND be1.event_id = be.previous_event))
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.installment_id = bii.installment_id
                                     AND be1.reversal_flag = cust_gvar.FLG_NO
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.attrib_0, be.legal_entity, be.reversal_flag, be.event_date, bii.org_id, bi.item_type, ba.party
                  ORDER BY TO_NUMBER(be.attrib_0), DECODE(be.reversal_flag, 'N','1','2')
                  )
    LOOP
       blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'c_doc.clearing_id = '||c_doc.clearing_id);

       IF c_doc.item_type = 'CO'
       THEN
          l_prefix_right := 'I012-1';
       ELSIF c_doc.item_type = 'RI'
       THEN
          l_prefix_right := 'I012-2';
       END IF;

       OPEN c_pmnt(to_number(c_doc.clearing_id));
         FETCH c_pmnt
         INTO l_payment_id;
       CLOSE c_pmnt;

       IF c_doc.reversal_flag = cust_gvar.FLG_NO
       THEN
          l_prefix := l_prefix_right;
          l_ref_doc_id := NULL;
       ELSE
          l_prefix := 'I013';
          BEGIN
            SELECT bd.doc_id
            INTO l_ref_doc_id
            FROM blc_documents bd,
                 blc_lookups bl
            WHERE bd.doc_suffix = c_doc.clearing_id
            AND bd.doc_prefix = l_prefix_right
            AND bd.attrib_2 = c_doc.party
            AND bd.doc_type_id = bl.lookup_id
            AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
         EXCEPTION
            WHEN OTHERS THEN
              srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Claim_CORI_Voucher', 'cust_acc_process_pkg_2.CPV.No_Ref_Doc', l_prefix_right||'|'||c_doc.clearing_id||' / '||c_doc.party );
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                         'c_doc.clearing_id = '||c_doc.clearing_id||' c_doc.item_type = '||c_doc.item_type||' c_doc.party = '||c_doc.party||' - Cannot calculate voucher doc_id for not reversal event');
              RETURN;
          END;
       END IF;

       l_event_ids := blc_common_pkg.convert_list(c_doc.event_list);

       SAVEPOINT CREATE_DOC;

       blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.clearing_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   l_ref_doc_id,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   c_doc.party,
                 pi_attrib_3            =>   l_payment_id,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   po_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
       --
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'c_doc.clearing_id = '||c_doc.clearing_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       l_doc := blc_documents_type(po_acc_doc_id);

       l_doc.status := cust_gvar.STATUS_VALID;

       IF NOT l_doc.update_blc_documents(pio_Err)
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'po_acc_doc_id = '||po_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       UPDATE blc_sla_events
       SET attrib_9 = po_acc_doc_id
       WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) );

       IF pi_batch_flag = 'Y'
       THEN
          COMMIT;
       END IF;

    END LOOP;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'po_acc_doc_id = '||po_acc_doc_id);

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Claim_CORI_Voucher');
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Claim_CORI_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_clearing_id = '||pi_clearing_id||' - '||SQLERRM);
END Create_Claim_CORI_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_RI_Bill_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.01.2018  creation
--
-- Purpose: Create a document for the accounting events for given document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_RI_Bill_Voucher( pi_doc_id       IN     NUMBER,
                                  pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  po_acc_doc_id   OUT    NUMBER,
                                  pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_doc_number    VARCHAR2(100);
    l_prefix        VARCHAR2(30) := 'I018';
    --
    l_doc           BLC_DOCUMENTS_TYPE;
    l_ref_doc_id    NUMBER;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Create_RI_Bill_Voucher';

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_RI_Bill_Voucher');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);

    FOR c_doc IN (SELECT bt.doc_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         bt.org_id,
                         DECODE(be.reversal_flag,'N','1','2') reversal_order,
                         nvl(pp.attr4, pp.office_id) office
                  FROM  blc_sla_events be,
                        blc_transactions bt,
                        blc_items bi,
                        policy pp
                  WHERE pi_doc_id IS NOT NULL
                  AND bt.doc_id = pi_doc_id
                  AND be.event_type = 'TRX_APPROVED'
                  AND be.attrib_9 IS NULL
                  AND bt.transaction_id = be.transaction_id
                  AND bt.transaction_type IN ('RI_PREMIUM','RI_COMMISSION','RI_TAX')
                  AND bt.item_id = bi.item_id
                  AND bi.item_type = 'RI'
                  AND to_number(bi.component) = pp.policy_id
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.transaction_id = bt.transaction_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.transaction_id = bt.transaction_id
                                     AND be1.reversal_flag = cust_gvar.FLG_NO
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.legal_entity, be.reversal_flag, be.event_date, bt.doc_id, bt.org_id, nvl(pp.attr4, pp.office_id)
                  UNION ALL
                  SELECT bt.doc_id,
                         be.legal_entity,
                         be.reversal_flag,
                         be.event_date,
                         bt.org_id,
                         DECODE(be.reversal_flag,'N','1','2') reversal_order,
                         nvl(pp.attr4, pp.office_id) office
                  FROM  blc_sla_events be,
                        blc_transactions bt,
                        blc_items bi,
                        policy pp
                  WHERE pi_doc_id IS NULL
                  AND be.legal_entity = pi_le_id
                  AND be.event_type = 'TRX_APPROVED'
                  AND be.attrib_9 IS NULL
                  AND bt.transaction_id = be.transaction_id
                  AND bt.transaction_type IN ('RI_PREMIUM','RI_COMMISSION','RI_TAX')
                  AND bt.item_id = bi.item_id
                  AND bi.item_type = 'RI'
                  AND to_number(bi.component) = pp.policy_id
                  AND ((be.reversal_flag = cust_gvar.FLG_NO
                        AND NOT EXISTS (SELECT 'REV'
                                        FROM blc_sla_events be1
                                        WHERE be1.transaction_id = bt.transaction_id
                                        AND be1.reversal_flag = cust_gvar.FLG_YES
                                        AND be1.attrib_9 IS NULL
                                        AND be1.previous_event = be.event_id))
                     OR
                       (be.reversal_flag = cust_gvar.FLG_YES
                        AND EXISTS ( SELECT 'REV'
                                     FROM blc_sla_events be1
                                     WHERE be1.transaction_id = bt.transaction_id
                                     AND be1.reversal_flag = cust_gvar.FLG_NO
                                     AND be1.attrib_9 IS NOT NULL
                                     AND be1.event_id = be.previous_event)))
                  GROUP BY be.legal_entity, be.reversal_flag, be.event_date, bt.doc_id, bt.org_id, nvl(pp.attr4, pp.office_id)
                  ORDER BY doc_id, reversal_order
                  )
    LOOP
       blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'c_doc.doc_id = '||c_doc.doc_id);

       IF c_doc.reversal_flag = cust_gvar.FLG_NO
       THEN
          l_prefix := 'I018';
          l_ref_doc_id := NULL;
       ELSE
          l_prefix := 'I018-ANN';
          BEGIN
            SELECT bd.doc_id
            INTO l_ref_doc_id
            FROM blc_documents bd,
                 blc_lookups bl
            WHERE bd.doc_suffix = to_char(c_doc.doc_id)
            AND bd.doc_prefix = 'I018'
            AND bd.attrib_2 = c_doc.office
            AND bd.doc_type_id = bl.lookup_id
            AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
         EXCEPTION
            WHEN OTHERS THEN
              srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_Claim_CORI_Voucher', 'cust_acc_process_pkg_2.CPV.No_Ref_Doc', 'I018'||'|'||c_doc.doc_id||' / '||c_doc.office );
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                         'c_doc.doc_id = '||c_doc.doc_id||' c_doc.office = '||c_doc.office||' - Cannot calculate voucher doc_id for not reversal event');
              RETURN;
          END;
       END IF;

       SAVEPOINT CREATE_DOC;

       blc_spec_doc_util_pkg.Create_Document
               ( pi_legal_entity_id     =>   c_doc.legal_entity,
                 pi_legal_entity        =>   NULL,
                 pi_org_site_id         =>   c_doc.org_id,
                 pi_office              =>   NULL,
                 pi_account_id          =>   NULL,
                 pi_party_site          =>   NULL,
                 pi_doc_type            =>   cust_gvar.DOC_ACC_TYPE,
                 pi_doc_type_id         =>   NULL,
                 pi_doc_type_setting    =>   NULL,
                 pi_issue_date          =>   c_doc.event_date,
                 pi_due_date            =>   NULL,
                 pi_currency            =>   NULL,
                 pi_amount              =>   0,
                 pi_notes               =>   NULL,
                 pi_grace               =>   NULL,
                 pi_grace_extra         =>   NULL,
                 pi_collection_level    =>   NULL,
                 pi_bank_account        =>   NULL,
                 pi_pay_method_id       =>   NULL,
                 pi_doc_prefix          =>   l_prefix,
                 pi_doc_number          =>   NULL,
                 pi_doc_suffix          =>   c_doc.doc_id,
                 pi_reference           =>   NULL,
                 pi_ref_doc_id          =>   l_ref_doc_id,
                 pi_run_id              =>   NULL,
                 pi_direction           =>   NULL,
                 pi_attrib_0            =>   NULL,
                 pi_attrib_1            =>   NULL,
                 pi_attrib_2            =>   c_doc.office,
                 pi_attrib_3            =>   NULL,
                 pi_attrib_4            =>   NULL,
                 pi_attrib_5            =>   NULL,
                 pi_attrib_6            =>   NULL,
                 pi_attrib_7            =>   NULL,
                 pi_attrib_8            =>   NULL,
                 pi_attrib_9            =>   NULL,
                 pi_pay_way             =>   NULL,
                 pi_pay_way_id          =>   NULL,
                 pi_pay_instr           =>   NULL,
                 po_doc_id              =>   po_acc_doc_id,
                 po_doc_number          =>   l_doc_number,
                 pio_Err                =>   pio_Err);
       --
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       l_doc := blc_documents_type(po_acc_doc_id);

       l_doc.status := cust_gvar.STATUS_VALID;

       IF NOT l_doc.update_blc_documents(pio_Err)
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'po_acc_doc_id = '||po_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          ROLLBACK TO CREATE_DOC;
          RETURN;
       END IF;

       FOR c_event IN ( SELECT be.event_id
                        FROM  blc_sla_events be,
                              blc_transactions bt,
                              blc_items bi,
                              policy pp
                        WHERE bt.doc_id = c_doc.doc_id
                        AND be.event_type = 'TRX_APPROVED'
                        AND be.attrib_9 IS NULL
                        AND bt.transaction_id = be.transaction_id
                        AND bt.transaction_type IN ('RI_PREMIUM','RI_COMMISSION','RI_TAX')
                        AND bt.item_id = bi.item_id
                        AND to_number(bi.component) = pp.policy_id
                        AND ((be.reversal_flag = cust_gvar.FLG_NO
                              AND NOT EXISTS (SELECT 'REV'
                                              FROM blc_sla_events be1
                                              WHERE be1.transaction_id = bt.transaction_id
                                              AND be1.reversal_flag = cust_gvar.FLG_YES
                                              AND be1.attrib_9 IS NULL
                                              AND be1.previous_event = be.event_id))
                           OR
                             (be.reversal_flag = cust_gvar.FLG_YES
                              AND EXISTS ( SELECT 'REV'
                                           FROM blc_sla_events be1
                                           WHERE be1.transaction_id = bt.transaction_id
                                           AND be1.reversal_flag = cust_gvar.FLG_NO
                                           AND be1.attrib_9 IS NOT NULL
                                           AND be1.event_id = be.previous_event)))
                        AND be.legal_entity = c_doc.legal_entity
                        AND be.reversal_flag = c_doc.reversal_flag
                        AND be.event_date = c_doc.event_date
                        AND bt.org_id = c_doc.org_id
                        AND nvl(pp.attr4, pp.office_id) = c_doc.office)
       LOOP
          UPDATE blc_sla_events
          SET attrib_9 = po_acc_doc_id
          WHERE event_id = c_event.event_id;
       END LOOP;

       IF pi_batch_flag = 'Y'
       THEN
          COMMIT;
       END IF;

    END LOOP;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'po_acc_doc_id = '||po_acc_doc_id);

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_RI_Bill_Voucher');
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Create_RI_Bill_Voucher', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Create_RI_Bill_Voucher;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Validate_Doc_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Validate created accounting transactions for given document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Doc_Acc_Trx( pi_doc_id       IN     NUMBER,
                                pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_BLC001_amount_trx NUMBER;
    l_BLC002_amount_trx NUMBER;
    l_BLC003_amount_trx NUMBER;
    l_BLC005_amount_trx NUMBER;
    --
    l_BLC001_amount_acc NUMBER;
    l_BLC002_amount_acc NUMBER;
    l_BLC003_amount_acc NUMBER;
    l_BLC005_amount_acc NUMBER;
    --
    l_total_amount      NUMBER;
    l_doc               BLC_DOCUMENTS_TYPE;
    l_count_co          PLS_INTEGER;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Validate_Doc_Acc_Trx';

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Validate_Doc_Acc_Trx');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_doc_id = '||pi_doc_id);

    l_doc := blc_documents_type(pi_doc_id);

    IF l_doc.status <> cust_gvar.STATUS_APPROVED
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Doc_Acc_Trx', 'cust_acc_process_pkg_2.VDAT.WrongStatus', pi_doc_id||'|'||l_doc.status);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'The document status is '||l_doc.status);
    END IF;

    SELECT nvl(sum(amount + vat_amount + saving_amount),0),
           nvl(sum(comm_amount),0),
           nvl(sum(co_amount),0),
           nvl(sum(saving_amount),0)
    INTO l_BLC001_amount_trx,
         l_BLC002_amount_trx,
         l_BLC003_amount_trx,
         l_BLC005_amount_trx
    FROM blc_transactions_premium
    WHERE doc_id = pi_doc_id;

    SELECT nvl(sum(amount),0)
    INTO l_total_amount
    FROM blc_transactions
    WHERE doc_id = pi_doc_id;

    SELECT nvl(sum(decode(gltrans_type,'BLC001',op_amount,0)),0),
           nvl(sum(decode(gltrans_type,'BLC002',op_amount,0)),0),
           nvl(sum(decode(gltrans_type,'BLC003',decode(attrib_18,'R',-1,1)*op_amount,0)),0),
           nvl(sum(decode(gltrans_type,'BLC005',op_amount,0)),0)
    INTO l_BLC001_amount_acc,
         l_BLC002_amount_acc,
         l_BLC003_amount_acc,
         l_BLC005_amount_acc
    FROM blc_gl_insis2gl
    WHERE doc_id = pi_doc_id
    AND reversed_gltrans_id IS NULL;

    SELECT count(*)
    INTO l_count_co
    FROM blc_transactions bt,
         blc_items bi,
         blc_items bic
    WHERE bt.doc_id = pi_doc_id
    AND bt.item_id = bi.item_id
    AND bi.item_type = 'POLICY'
    AND bi.component = bic.component
    AND bic.item_type = 'CO';

    IF l_count_co <> 0 AND l_BLC003_amount_trx = 0 AND l_doc.status = cust_gvar.STATUS_APPROVED
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Doc_Acc_Trx', 'cust_acc_process_pkg_2.VDAT.Miss_CO_Inst');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'Missing coinsurance installments');
    END IF;

    IF l_BLC001_amount_trx <> l_BLC001_amount_acc AND l_total_amount <> l_BLC001_amount_acc --maybe exclude this if VAT is alway relate to premium
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Doc_Acc_Trx', 'cust_acc_process_pkg_2.VDAT.Diff_BLC001_amount', l_BLC001_amount_trx||'/'||l_BLC001_amount_acc );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'There is a difference between BLC001 amounts  doc/acc '||l_BLC001_amount_trx||'/'||l_BLC001_amount_acc);
    END IF;

    IF l_BLC002_amount_trx <> l_BLC002_amount_acc
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Doc_Acc_Trx', 'cust_acc_process_pkg_2.VDAT.Diff_BLC002_amount', l_BLC002_amount_trx||'/'||l_BLC002_amount_acc );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'There is a difference between BLC002 amounts  doc/acc '||l_BLC002_amount_trx||'/'||l_BLC002_amount_acc);
    END IF;

    IF l_BLC003_amount_trx <> l_BLC003_amount_acc
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Doc_Acc_Trx', 'cust_acc_process_pkg_2.VDAT.Diff_BLC003_amount', l_BLC003_amount_trx||'/'||l_BLC003_amount_acc );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'There is a difference between BLC003 amounts  doc/acc '||l_BLC003_amount_trx||'/'||l_BLC003_amount_acc);
    END IF;

    IF l_BLC005_amount_trx <> l_BLC005_amount_acc
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Doc_Acc_Trx', 'cust_acc_process_pkg_2.VDAT.Diff_BLC005_amount', l_BLC005_amount_trx||'/'||l_BLC005_amount_acc );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'There is a difference between BLC005 amounts  doc/acc '||l_BLC005_amount_trx||'/'||l_BLC005_amount_acc);
    END IF;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Validate_Doc_Acc_Trx');

END Validate_Doc_Acc_Trx;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Validate_Pmnt_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Validate created accounting transactions for given payment
--
-- Input parameters:
--     pi_payment_id       NUMBER    Payment Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Pmnt_Acc_Trx( pi_payment_id   IN     NUMBER,
                                 pio_Err         IN OUT SrvErr )
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    --
    l_payment       BLC_PAYMENTS_TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Validate_Pmnt_Acc_Trx';

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Validate_Pmnt_Acc_Trx');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_payment_id = '||pi_payment_id);

    l_payment := blc_payments_type(pi_payment_id,pio_Err);

    IF l_payment.status <> cust_gvar.STATUS_APPROVED
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Validate_Pmnt_Acc_Trx', 'cust_acc_process_pkg_2.VPAT.WrongStatus', pi_payment_id||'|'||l_payment.status);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_payment_id = '||pi_payment_id||' - '||
                                  'The payment status is '||l_payment.status);
    END IF;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Validate_Pmnt_Acc_Trx');

END Validate_Pmnt_Acc_Trx;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Process_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: For given accounting voucher document validate created accounting
-- transactions and transfer data to the intreface tables. In case of some
-- accounting or validation errors delete created accounting transactions and
-- change event status to Z, add action with the error for the document. In case
-- of success approve document and update document number with created interface
-- header_id
--
-- Input parameters:
--     pi_acc_doc_id       NUMBER    Voucher doc Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_status           VARCHAR2  Document status
--     pi_ip_code          VARCHAR2  IP code (document preffix)
--     pi_imm_flag         VARCHAR2  Called for immediate bill
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In schedule process for transfer accounting transaction or for
-- immediate creation of accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_Acc_Trx( pi_acc_doc_id   IN     NUMBER,
                           pi_le_id        IN     NUMBER,
                           pi_status       IN     VARCHAR2,
                           pi_ip_code      IN     VARCHAR2,
                           pi_imm_flag     IN     VARCHAR2,
                           pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                           pio_Err         IN OUT SrvErr )
IS
    l_log_module      VARCHAR2(240);
    l_SrvErrMsg       SrvErrMsg;
    l_SrvErr          SrvErr;
    --
    l_event_ids       BLC_SELECTED_OBJECTS_TABLE;
    --
    CURSOR cur_ev_status( x_event_ids IN BLC_SELECTED_OBJECTS_TABLE ) IS
    SELECT event_status
    FROM blc_sla_event_status
    WHERE event_id IN ( SELECT * FROM TABLE(x_event_ids) )
    FOR UPDATE NOWAIT;
    --
    CURSOR cur_ev_status_2( x_attrib_9 IN VARCHAR2 ) IS
    SELECT event_status
    FROM blc_sla_event_status bs
    WHERE EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.attrib_9 = x_attrib_9
                  AND be.event_id = bs.event_id)
    FOR UPDATE NOWAIT;
    --
    l_action_notes   VARCHAR2(4000);
    l_err_flag       VARCHAR2(1) := cust_gvar.FLG_NO;
    l_acc_error      VARCHAR2(2000);
    l_doc            BLC_DOCUMENTS_TYPE;
    l_header_id      NUMBER;
    --
    l_procedure_result VARCHAR2(100);
    l_doc_status       VARCHAR2(1);
    l_break            VARCHAR2(3);
    l_run_acc_flag     VARCHAR2(1) := cust_gvar.FLG_NO;
    l_doc_ref          blc_documents_type;
    l_pmnt_status      VARCHAR2(1);
    l_count_e          PLS_INTEGER;
    l_event_list       VARCHAR2(4000);
    l_max_count        PLS_INTEGER := 200;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Process_Acc_Trx';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Process_Acc_Trx');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_acc_doc_id = '||pi_acc_doc_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_le_id = '||pi_le_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_status = '||pi_status);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_ip_code = '||pi_ip_code);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_imm_flag = '||pi_imm_flag);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_batch_flag = '||pi_batch_flag);

    l_break := '000';
    /*
    FOR c_doc IN (SELECT bd.doc_id acc_doc_id,
                         bd.legal_entity_id,
                         bd.doc_prefix,
                         bd.doc_number,
                         bd.doc_suffix,
                         bd.status,
                         bd.ref_doc_id,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                  FROM blc_documents bd,
                       blc_sla_events be
                  WHERE pi_acc_doc_id IS NOT NULL
                  AND bd.doc_id = pi_acc_doc_id
                  AND bd.status IN (cust_gvar.STATUS_VALID, cust_gvar.STATUS_REJECT)
                  AND (pi_status IS NULL OR bd.status = pi_status)
                  AND (pi_ip_code IS NULL OR bd.doc_prefix = pi_ip_code)
                  AND to_char(bd.doc_id) = be.attrib_9
                  GROUP BY bd.doc_id,
                           bd.legal_entity_id,
                           bd.doc_prefix,
                           bd.doc_number,
                           bd.doc_suffix,
                           bd.status,
                           bd.ref_doc_id
                  UNION ALL
                  SELECT bd.doc_id acc_doc_id,
                         bd.legal_entity_id,
                         bd.doc_prefix,
                         bd.doc_number,
                         bd.doc_suffix,
                         bd.status,
                         bd.ref_doc_id,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                  FROM blc_documents bd,
                       blc_lookups bl,
                       blc_sla_events be
                  WHERE pi_acc_doc_id IS NULL
                  AND pi_ip_code IS NOT NULL
                  AND bd.doc_prefix = pi_ip_code
                  AND bd.legal_entity_id = pi_le_id
                  AND bd.status IN (cust_gvar.STATUS_VALID, cust_gvar.STATUS_REJECT)
                  AND (pi_status IS NULL OR bd.status = pi_status)
                  AND bd.doc_type_id = bl.lookup_id
                  AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE
                  AND to_char(bd.doc_id) = be.attrib_9
                  GROUP BY bd.doc_id,
                           bd.legal_entity_id,
                           bd.doc_prefix,
                           bd.doc_number,
                           bd.doc_suffix,
                           bd.status,
                           bd.ref_doc_id
                  UNION ALL
                  SELECT bd.doc_id acc_doc_id,
                         bd.legal_entity_id,
                         bd.doc_prefix,
                         bd.doc_number,
                         bd.doc_suffix,
                         bd.status,
                         bd.ref_doc_id,
                         LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
                  FROM blc_documents bd,
                       blc_lookups bl,
                       blc_sla_events be
                  WHERE pi_acc_doc_id IS NULL
                  AND pi_ip_code IS NULL
                  AND pi_status IS NOT NULL
                  AND bd.status = pi_status
                  AND bd.legal_entity_id = pi_le_id
                  AND bd.doc_type_id = bl.lookup_id
                  AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE
                  AND to_char(bd.doc_id) = be.attrib_9
                  GROUP BY bd.doc_id,
                           bd.legal_entity_id,
                           bd.doc_prefix,
                           bd.doc_number,
                           bd.doc_suffix,
                           bd.status,
                           bd.ref_doc_id
                  ORDER BY acc_doc_id)
    */
       FOR c_doc IN (SELECT bd.doc_id acc_doc_id,
                         bd.legal_entity_id,
                         bd.doc_prefix,
                         bd.doc_number,
                         bd.doc_suffix,
                         bd.status,
                         bd.ref_doc_id
                  FROM blc_documents bd
                  WHERE pi_acc_doc_id IS NOT NULL
                  AND bd.doc_id = pi_acc_doc_id
                  AND bd.status IN (cust_gvar.STATUS_VALID, cust_gvar.STATUS_REJECT)
                  AND (pi_status IS NULL OR bd.status = pi_status)
                  AND (pi_ip_code IS NULL OR bd.doc_prefix = pi_ip_code)
                  UNION ALL
                  SELECT bd.doc_id acc_doc_id,
                         bd.legal_entity_id,
                         bd.doc_prefix,
                         bd.doc_number,
                         bd.doc_suffix,
                         bd.status,
                         bd.ref_doc_id
                  FROM blc_documents bd,
                       blc_lookups bl
                  WHERE pi_acc_doc_id IS NULL
                  AND pi_ip_code IS NOT NULL
                  AND bd.doc_prefix = pi_ip_code
                  AND bd.legal_entity_id = pi_le_id
                  AND bd.status IN (cust_gvar.STATUS_VALID, cust_gvar.STATUS_REJECT)
                  AND (pi_status IS NULL OR bd.status = pi_status)
                  AND bd.doc_type_id = bl.lookup_id
                  AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE
                  UNION ALL
                  SELECT bd.doc_id acc_doc_id,
                         bd.legal_entity_id,
                         bd.doc_prefix,
                         bd.doc_number,
                         bd.doc_suffix,
                         bd.status,
                         bd.ref_doc_id
                  FROM blc_documents bd,
                       blc_lookups bl
                  WHERE pi_acc_doc_id IS NULL
                  AND pi_ip_code IS NULL
                  AND pi_status IS NOT NULL
                  AND bd.status = pi_status
                  AND bd.legal_entity_id = pi_le_id
                  AND bd.doc_type_id = bl.lookup_id
                  AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE
                  ORDER BY acc_doc_id)
    LOOP
       blc_log_pkg.insert_message(l_log_module,C_LEVEL_STATEMENT,'c_doc.acc_doc_id = '||c_doc.acc_doc_id);

       l_SrvErr := NULL;
       l_action_notes := NULL;
       l_err_flag := cust_gvar.FLG_NO;
       l_run_acc_flag := cust_gvar.FLG_NO;

       SELECT count(*)
       INTO l_count_e
       FROM blc_sla_events be
       WHERE be.attrib_9 = to_char(c_doc.acc_doc_id);

       IF l_count_e = 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Process_Acc_Trx', 'cust_acc_process_pkg_2.CCDAT.No_Acc_Events' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'c_doc.acc_doc_id = '||c_doc.acc_doc_id||' - '||
                                    'No accounting events');
          RETURN;
       END IF;

       IF l_count_e <= l_max_count
       THEN
          SELECT LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id) event_list
          INTO l_event_list
          FROM blc_sla_events be
          WHERE be.attrib_9 = to_char(c_doc.acc_doc_id);

          l_event_ids := blc_common_pkg.convert_list(l_event_list);
       ELSE
          l_event_ids := NULL;
          l_event_list := NULL;
       END IF;

       SAVEPOINT PROCESS_DOC;

       l_break := '001';
       IF c_doc.ref_doc_id IS NOT NULL
       THEN
          l_doc_ref := blc_documents_type(c_doc.ref_doc_id);

          IF l_doc_ref.status = cust_gvar.STATUS_VALID
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Process_Acc_Trx', 'cust_acc_process_pkg_2.PAT.ReversedNotProcess', c_doc.ref_doc_id);
             srv_error.SetErrorMsg( l_SrvErrMsg, l_SrvErr );
             l_err_flag := cust_gvar.FLG_YES;
          ELSIF l_doc_ref.status = cust_gvar.STATUS_REJECT
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Process_Acc_Trx', 'cust_acc_process_pkg_2.PAT.ReversedReject', c_doc.ref_doc_id);
             srv_error.SetErrorMsg( l_SrvErrMsg, l_SrvErr );
             l_err_flag := cust_gvar.FLG_YES;
          END IF;
       END IF;

       l_break := '002';
       IF l_err_flag = cust_gvar.FLG_NO
       THEN
          IF c_doc.status = cust_gvar.STATUS_REJECT
          THEN
             IF l_event_ids IS NOT NULL
             THEN
                OPEN cur_ev_status(l_event_ids);
                CLOSE cur_ev_status;

                UPDATE blc_sla_event_status
                SET event_status = cust_gvar.ACC_ERROR
                WHERE event_id IN ( SELECT * FROM TABLE(l_event_ids) )
                AND event_status = cust_gvar.ACC_MANUALPROCESS;
             ELSE
                OPEN cur_ev_status_2(to_char(c_doc.acc_doc_id));
                CLOSE cur_ev_status_2;

                UPDATE blc_sla_event_status bs
                SET bs.event_status = cust_gvar.ACC_ERROR
                WHERE bs.event_status = cust_gvar.ACC_MANUALPROCESS
                AND EXISTS (SELECT 'EVENT'
                            FROM blc_sla_events be
                            WHERE be.attrib_9 = to_char(c_doc.acc_doc_id)
                            AND be.event_id = bs.event_id);
             END IF;
             --
             l_run_acc_flag := cust_gvar.FLG_YES;
          END IF;

          IF pi_imm_flag = cust_gvar.FLG_YES
          THEN
             l_run_acc_flag := cust_gvar.FLG_YES;
          END IF;
       END IF;

       l_break := '003';
       IF  l_run_acc_flag = cust_gvar.FLG_YES
       THEN
          blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN Create_Events_Accounting');
          IF l_event_list IS NOT NULL
          THEN
             blc_sla_accounting_pkg.Create_Events_Accounting( c_doc.legal_entity_id, l_event_list, NULL, NULL, l_SrvErr );
          ELSE
             FOR c_event IN (SELECT be.event_id
                             FROM blc_sla_events be
                             WHERE be.attrib_9 = to_char(c_doc.acc_doc_id)
                             ORDER BY be.event_id)
             LOOP
                blc_sla_accounting_pkg.Create_Events_Accounting( c_doc.legal_entity_id, c_event.event_id, NULL, NULL, l_SrvErr );
             END LOOP;
          END IF;

          IF NOT srv_error.rqStatus( l_SrvErr )
          THEN
             l_err_flag := cust_gvar.FLG_YES;
          END IF;
          blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END Create_Events_Accounting');
       END IF;

       l_break := '004';
       IF l_err_flag = cust_gvar.FLG_NO
       THEN
          IF l_event_ids IS NOT NULL
          THEN
             Check_Events_Status
                            (pi_event_ids    => l_event_ids,
                             po_err_flag     => l_err_flag,
                             po_action_error => l_acc_error,
                             pio_Err         => l_SrvErr);
          ELSE
             Check_Events_Status_2
                            (pi_attrib_9     => to_char(c_doc.acc_doc_id),
                             po_err_flag     => l_err_flag,
                             po_action_error => l_acc_error,
                             pio_Err         => l_SrvErr);
          END IF;
          IF l_err_flag = cust_gvar.FLG_YES
          THEN
             blc_doc_util_pkg.Add_Note(l_action_notes, l_acc_error);
          END IF;
       END IF;
       --
       IF c_doc.doc_prefix = 'I001-CRE'
       THEN
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             Validate_Doc_Acc_Trx
                        (pi_doc_id  => c_doc.doc_suffix,
                         pio_Err    => l_SrvErr);
             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
          --
          l_break := '005';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_Proforma
                   (pi_doc_id         => c_doc.doc_suffix,
                    pi_acc_doc_id     => c_doc.acc_doc_id,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
          --
          l_break := '006';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             blc_doc_process_pkg.Set_Formal_Document
                  (pi_doc_id             => c_doc.doc_suffix,
                   pi_action_notes       => srv_error.GetSrvMessage('cust_acc_process_pkg_2.PAT.IntInsert')||' '||l_header_id,
                   pio_procedure_result  => l_procedure_result,
                   po_doc_status         => l_doc_status,
                   pio_Err               => l_SrvErr);
             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
       ELSIF c_doc.doc_prefix = 'I003-ANN'
       THEN
          l_break := '007';
          cust_acc_export_pkg.Insert_SAP_Delete_Proforma
                 (pi_doc_id         => c_doc.doc_suffix,
                  pi_acc_doc_id     => c_doc.acc_doc_id,
                  pi_reversed_id    => l_doc_ref.doc_number,
                  pi_acc_doc_prefix => c_doc.doc_prefix,
                  po_header_id      => l_header_id,
                  pio_Err           => l_SrvErr);
           IF NOT srv_error.rqStatus( l_SrvErr )
           THEN
              l_err_flag := cust_gvar.FLG_YES;
           END IF;
       ELSIF c_doc.doc_prefix = 'I009'
       THEN
          l_break := '008';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             Validate_Pmnt_Acc_Trx
                        (pi_payment_id  => c_doc.doc_suffix,
                         pio_Err        => l_SrvErr);
             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;

          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_Claim_Pmnt
                   (pi_payment_id     => c_doc.doc_suffix,
                    pi_acc_doc_id     => c_doc.acc_doc_id,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
          --
          l_break := '009';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             blc_pmnt_util_pkg.Change_Payments_Status
                 (pi_payment_ids    => c_doc.doc_suffix,
                  pi_target_status  => cust_gvar.STATUS_SENT,
                  pi_notes          => srv_error.GetSrvMessage('cust_acc_process_pkg_2.PAT.IntInsert')||' '||l_header_id,
                  pi_undo_flag      => cust_gvar.FLG_NO,
                  pi_changed_on     => NULL,
                  po_changed_status => l_pmnt_status,
                  pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
       ELSIF c_doc.doc_prefix = 'I011-1'
       THEN
          l_break := '010';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_Rvrs_Claim_Pmnt
                   (pi_payment_id     => c_doc.doc_suffix,
                    pi_acc_doc_id     => c_doc.acc_doc_id,
                    pi_reversed_id    => l_doc_ref.doc_number,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
       ELSIF c_doc.doc_prefix IN ( 'I007-1', 'I007-2' )
       THEN
          l_break := '011';
          cust_acc_export_pkg.Insert_SAP_Claim_Adj
                 (pi_acc_doc_id     => c_doc.acc_doc_id,
                  po_header_id      => l_header_id,
                  pio_Err           => l_SrvErr);
           IF NOT srv_error.rqStatus( l_SrvErr )
           THEN
              l_err_flag := cust_gvar.FLG_YES;
           END IF;
       ELSIF c_doc.doc_prefix = 'I058'
       THEN
          l_break := '012';
          cust_acc_export_pkg.Insert_SAP_Account
                 (pi_acc_doc_id     => c_doc.acc_doc_id,
                  po_header_id      => l_header_id,
                  pio_Err           => l_SrvErr);
           IF NOT srv_error.rqStatus( l_SrvErr )
           THEN
              l_err_flag := cust_gvar.FLG_YES;
           END IF;
       ELSIF c_doc.doc_prefix = 'I001-CCR'
       THEN
          l_break := '013';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_Prem_AC
                   (pi_acc_doc_id     => c_doc.acc_doc_id,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
       ELSIF c_doc.doc_prefix = 'I008'
       THEN
          l_break := '014';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_Claim_AC
                   (pi_acc_doc_id     => c_doc.acc_doc_id,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
       ELSIF c_doc.doc_prefix IN ( 'I012-1', 'I012-2' )
       THEN
          l_break := '015';
          cust_acc_export_pkg.Insert_SAP_Claim_Clr_Pmnt
                 (pi_acc_doc_id     => c_doc.acc_doc_id,
                  po_header_id      => l_header_id,
                  pio_Err           => l_SrvErr);
           IF NOT srv_error.rqStatus( l_SrvErr )
           THEN
              l_err_flag := cust_gvar.FLG_YES;
           END IF;
       ELSIF c_doc.doc_prefix = 'I013'
       THEN
          l_break := '016';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_Unclear_Pmnt
                   (pi_clearing_id    => c_doc.doc_suffix,
                    pi_acc_doc_id     => c_doc.acc_doc_id,
                    pi_reversed_id    => l_doc_ref.doc_number,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
       ELSIF c_doc.doc_prefix = 'I018'
       THEN
          l_break := '017';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             cust_acc_export_pkg.Insert_SAP_RI_Bill
                   (pi_doc_id         => c_doc.doc_suffix,
                    pi_acc_doc_id     => c_doc.acc_doc_id,
                    po_header_id      => l_header_id,
                    pio_Err           => l_SrvErr);

             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
          --
          /* do not set as Formal because for ane document exist many vouchers
          l_break := '012';
          IF l_err_flag = cust_gvar.FLG_NO
          THEN
             blc_doc_process_pkg.Set_Formal_Document
                  (pi_doc_id             => c_doc.doc_suffix,
                   pi_action_notes       => srv_error.GetSrvMessage('cust_acc_process_pkg_2.PAT.IntInsert')||' '||l_header_id,
                   pio_procedure_result  => l_procedure_result,
                   po_doc_status         => l_doc_status,
                   pio_Err               => l_SrvErr);
             IF NOT srv_error.rqStatus( l_SrvErr )
             THEN
                l_err_flag := cust_gvar.FLG_YES;
             END IF;
          END IF;
          */
       ELSIF c_doc.doc_prefix = 'I018-ANN'
       THEN
          l_break := '018';
          cust_acc_export_pkg.Insert_SAP_Delete_RI_Bill
                 (pi_doc_id         => c_doc.doc_suffix,
                  pi_acc_doc_id     => c_doc.acc_doc_id,
                  pi_reversed_id    => l_doc_ref.doc_number,
                  pi_acc_doc_prefix => c_doc.doc_prefix,
                  po_header_id      => l_header_id,
                  pio_Err           => l_SrvErr);
           IF NOT srv_error.rqStatus( l_SrvErr )
           THEN
              l_err_flag := cust_gvar.FLG_YES;
           END IF;
       END IF;

       --
       l_break := '100';
       IF l_err_flag = cust_gvar.FLG_YES
       THEN
          ROLLBACK TO PROCESS_DOC;

          IF l_SrvErr IS NOT NULL
          THEN
             FOR i IN 1..l_SrvErr.COUNT
             LOOP
                blc_doc_util_pkg.Add_Note(l_action_notes,l_SrvErr(i).errmessage);
             END LOOP;
          END IF;

          IF l_event_ids IS NOT NULL
          THEN
             Set_Events_Status_Z( pi_event_ids    => l_event_ids,
                                  pio_Err         => pio_Err);
          ELSE
             Set_Events_Status_Z_2( pi_attrib_9    => to_char(c_doc.acc_doc_id),
                                    pio_Err        => pio_Err);
          END IF;

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_EXCEPTION,
                                        'c_doc.acc_doc_id = '||c_doc.acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

          l_break := '101';
          IF c_doc.status = cust_gvar.STATUS_REJECT
          THEN
              blc_doc_util_pkg.Insert_Action
               (cust_gvar.ACTIVITY_REJECT,
                l_action_notes,
                'S',
                c_doc.acc_doc_id,
                NULL,
                pio_Err);
          ELSE
              blc_doc_process_pkg.Reject_Document
                 (pi_doc_id             => c_doc.acc_doc_id,
                  pi_action_notes       => l_action_notes,
                  pio_procedure_result  => l_procedure_result,
                  po_doc_status         => l_doc_status,
                  pio_Err               => pio_Err);
          END IF;

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_EXCEPTION,
                                        'c_doc.acc_doc_id = '||c_doc.acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

       ELSE
          l_break := '102';
          l_doc := blc_documents_type(c_doc.acc_doc_id);

          IF l_doc.doc_number IS NOT NULL
          THEN
             l_action_notes := srv_error.GetSrvMessage('cust_acc_process_pkg_2.PAT.OldNumber')||' '||l_doc.doc_number||'; '||srv_error.GetSrvMessage('cust_acc_process_pkg_2.PAT.IntInsert')||' '||l_header_id;
          ELSE
             l_action_notes := srv_error.GetSrvMessage('cust_acc_process_pkg_2.PAT.IntInsert')||' '||l_header_id;
          END IF;

          l_doc.doc_number := l_header_id;
          l_doc.status := cust_gvar.STATUS_VALID;

          IF NOT l_doc.update_blc_documents(pio_Err)
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_EXCEPTION,
                                        'c_doc.acc_doc_id = '||c_doc.acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

          l_break := '103';
          blc_doc_process_pkg.Approve_Document
                 (pi_doc_id             => c_doc.acc_doc_id,
                  pi_action_notes       => l_action_notes,
                  pio_procedure_result  => l_procedure_result,
                  po_doc_status         => l_doc_status,
                  pio_Err               => pio_Err);

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_EXCEPTION,
                                        'c_doc.acc_doc_id = '||c_doc.acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

       END IF;

       IF pi_batch_flag = 'Y'
       THEN
          COMMIT;
       END IF;

    END LOOP;
    --
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Process_Acc_Trx');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Process_Acc_Trx', l_break||' - '||SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '|| l_break||' - '||SQLERRM);
END Process_Acc_Trx;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Set_Result_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Process SAP result for given accounting voucher document. In case of
-- error set status to Reject. In case of transfer write the SAP doc number into
-- voucher document and original BLC object attribute
--
-- Input parameters:
--     pi_acc_doc_id       NUMBER    Voucher doc Id (required)
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - E - Error
--                                              - S - Success
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In procedure for process SAP result
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Result_Acc_Trx( pi_acc_doc_id     IN     NUMBER,
                              pi_SAP_doc_number IN     VARCHAR2,
                              pi_status         IN     VARCHAR2,
                              pi_err_message    IN     VARCHAR2,
                              pio_Err           IN OUT SrvErr )
IS
    l_log_module       VARCHAR2(240);
    l_SrvErrMsg        SrvErrMsg;
    l_doc              BLC_DOCUMENTS_TYPE;
    l_event_ids        BLC_SELECTED_OBJECTS_TABLE;
    l_event_list       VARCHAR2(4000);
    l_procedure_result VARCHAR2(100);
    l_doc_status       VARCHAR2(1);
    l_doc_orig         BLC_DOCUMENTS_TYPE;
    l_doc_ref          BLC_DOCUMENTS_TYPE;
    l_pmnt_orig        BLC_PAYMENTS_TYPE;
    l_pmnt_status      VARCHAR2(1);
    l_pmnt_doc_id      NUMBER;
    l_count_e          PLS_INTEGER;
    l_max_count        PLS_INTEGER := 200;
    l_rev_doc_id       NUMBER;
    l_rev_status       VARCHAR2(1);
    l_rev_header       VARCHAR2(30);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Set_Result_Acc_Trx';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Set_Result_Acc_Trx');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_acc_doc_id = '||pi_acc_doc_id);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_SAP_doc_number = '||pi_SAP_doc_number);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_status = '||pi_status);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_err_message = '||pi_err_message);

    l_doc := blc_documents_type(pi_acc_doc_id);

    SAVEPOINT DOC_UPDATE;

    IF pi_status = cust_gvar.STATUS_ERROR
    THEN
       SELECT count(*)
       INTO l_count_e
       FROM blc_sla_events be
       WHERE be.attrib_9 = to_char(pi_acc_doc_id);

       IF l_count_e = 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'cust_acc_process_pkg_2.CCDAT.No_Acc_Events' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          RETURN;
       END IF;

       IF l_count_e <= l_max_count
       THEN
          SELECT LISTAGG(be.event_id, ',') WITHIN GROUP (ORDER BY be.event_id)
          INTO l_event_list
          FROM blc_sla_events be
          WHERE be.attrib_9 = to_char(pi_acc_doc_id);

          l_event_ids := blc_common_pkg.convert_list(l_event_list);

          Set_Events_Status_Z( pi_event_ids    => l_event_ids,
                               pio_Err         => pio_Err);
       ELSE
          Set_Events_Status_Z_2( pi_attrib_9     => to_char(pi_acc_doc_id),
                                 pio_Err         => pio_Err);
       END IF;

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          ROLLBACK TO DOC_UPDATE;
          RETURN;
       END IF;

       l_doc.status := cust_gvar.STATUS_VALID;

       IF NOT l_doc.update_blc_documents(pio_Err)
       THEN
          ROLLBACK TO DOC_UPDATE;
          RETURN;
       END IF;

       blc_doc_process_pkg.Reject_Document
                 (pi_doc_id             => pi_acc_doc_id,
                  pi_action_notes       => pi_err_message,
                  pio_procedure_result  => l_procedure_result,
                  po_doc_status         => l_doc_status,
                  pio_Err               => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          ROLLBACK TO DOC_UPDATE;
          RETURN;
       END IF;

       IF l_doc.doc_prefix = 'I001-CRE'
       THEN
          BEGIN
             l_doc_orig := blc_documents_type(l_doc.doc_suffix);
          EXCEPTION
             WHEN OTHERS THEN
               srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'blc_doc_util_pkg.VDO.Inv_DocId', l_doc.doc_suffix);
               srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
               ROLLBACK TO DOC_UPDATE;
               RETURN;
          END;

          IF l_doc_orig.status = cust_gvar.STATUS_FORMAL
          THEN
             blc_doc_process_pkg.Set_UnFormal_Document
                   (pi_doc_id             => l_doc.doc_suffix,
                    pi_action_notes       => pi_err_message,
                    pio_procedure_result  => l_procedure_result,
                    po_doc_status         => l_doc_status,
                    pio_Err               => pio_Err);

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                ROLLBACK TO DOC_UPDATE;
                RETURN;
             END IF;
           ELSIF l_doc_orig.status = cust_gvar.STATUS_DELETED
           THEN
              BEGIN
                SELECT bd.doc_id, bd.status, bd.doc_number
                INTO l_rev_doc_id, l_rev_status, l_rev_header
                FROM blc_documents bd,
                     blc_lookups bl
                WHERE bd.doc_suffix = l_doc.doc_suffix
                AND bd.doc_prefix = 'I003-ANN'
                AND bd.doc_type_id = bl.lookup_id
                AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
              EXCEPTION
                WHEN OTHERS THEN
                  l_rev_status := NULL;
              END;
              --
              IF l_rev_status = cust_gvar.STATUS_APPROVED
              THEN
                 srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'cust_acc_process_pkg_2.SRAT.Exist_Rev', l_doc_orig.status);
                 srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                 ROLLBACK TO DOC_UPDATE;
                 RETURN;
              END IF;
           ELSE
              srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'cust_acc_process_pkg_2.SRAT.Inv_DocStatus', l_rev_header);
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              ROLLBACK TO DOC_UPDATE;
              RETURN;
          END IF;
       ELSIF l_doc.doc_prefix = 'I009'
       THEN
          l_pmnt_orig := blc_payments_type(l_doc.doc_suffix, pio_Err);
          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;

          IF l_pmnt_orig.status <> cust_gvar.STATUS_SENT
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'cust_acc_process_pkg_2.SRAT.Inv_PmntStatus', l_pmnt_orig.status);
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;

          blc_pmnt_util_pkg.Change_Payments_Status
                   (pi_payment_ids    => l_doc.doc_suffix,
                    pi_target_status  => NULL,
                    pi_notes          => pi_err_message,
                    pi_undo_flag      => 'Y',
                    pi_changed_on     => NULL,
                    po_changed_status => l_pmnt_status,
                    pio_Err           => pio_Err);

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;
       END IF;

    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       l_doc.attrib_8 := pi_sap_doc_number;

       IF NOT l_doc.update_blc_documents(pio_Err)
       THEN
          ROLLBACK TO DOC_UPDATE;
          RETURN;
       END IF;

       blc_doc_process_pkg.Set_Formal_Document
                 (pi_doc_id             => pi_acc_doc_id,
                  pi_action_notes       => pi_sap_doc_number,
                  pio_procedure_result  => l_procedure_result,
                  po_doc_status         => l_doc_status,
                  pio_Err               => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          ROLLBACK TO DOC_UPDATE;
          RETURN;
       END IF;

       IF l_doc.doc_prefix = 'I001-CRE'
       THEN
          BEGIN
             l_doc_orig := blc_documents_type(l_doc.doc_suffix);
          EXCEPTION
             WHEN OTHERS THEN
               srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'blc_doc_util_pkg.VDO.Inv_DocId', l_doc.doc_suffix);
               srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
               ROLLBACK TO DOC_UPDATE;
               RETURN;
          END;

          l_doc_orig.attrib_8 := pi_sap_doc_number;

          IF NOT l_doc_orig.update_blc_documents(pio_Err)
          THEN
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;
       ELSIF l_doc.doc_prefix = 'I009'
       THEN
          l_pmnt_orig := blc_payments_type(l_doc.doc_suffix, pio_Err);
          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;

          l_pmnt_orig.attrib_8 := pi_sap_doc_number;

          IF NOT l_pmnt_orig.update_blc_payments(pio_Err)
          THEN
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;

          l_pmnt_doc_id := cust_pay_util_pkg.Get_Pmnt_Doc_Id(l_pmnt_orig.payment_id);
          IF l_pmnt_doc_id IS NOT NULL
          THEN
             l_doc_orig := blc_documents_type(l_pmnt_doc_id);

             l_doc_orig.attrib_8 := pi_sap_doc_number;

             IF NOT l_doc_orig.update_blc_documents(pio_Err)
             THEN
                ROLLBACK TO DOC_UPDATE;
                RETURN;
             END IF;
          END IF;
       END IF;

       IF l_doc.ref_doc_id IS NOT NULL
       THEN
          l_doc_ref := blc_documents_type(l_doc.ref_doc_id);

          l_doc_ref.attrib_9 := pi_sap_doc_number;

          IF NOT l_doc_ref.update_blc_documents(pio_Err)
          THEN
             ROLLBACK TO DOC_UPDATE;
             RETURN;
          END IF;

          IF l_doc_ref.doc_prefix = 'I001-CRE'
          THEN
             BEGIN
               l_doc_orig := blc_documents_type(l_doc_ref.doc_suffix);
             EXCEPTION
                WHEN OTHERS THEN
                  srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', 'blc_doc_util_pkg.VDO.Inv_DocId', l_doc_ref.doc_suffix);
                  srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                  ROLLBACK TO DOC_UPDATE;
                  RETURN;
             END;

             l_doc_orig.attrib_9 := pi_sap_doc_number;

             IF NOT l_doc_orig.update_blc_documents(pio_Err)
             THEN
                ROLLBACK TO DOC_UPDATE;
                RETURN;
             END IF;
          ELSIF l_doc_ref.doc_prefix = 'I009'
          THEN
             l_pmnt_orig := blc_payments_type(l_doc_ref.doc_suffix, pio_Err);
             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                ROLLBACK TO DOC_UPDATE;
                RETURN;
             END IF;

             l_pmnt_orig.attrib_9 := pi_sap_doc_number;

             IF NOT l_pmnt_orig.update_blc_payments(pio_Err)
             THEN
                ROLLBACK TO DOC_UPDATE;
                RETURN;
             END IF;

             l_pmnt_doc_id := cust_pay_util_pkg.Get_Pmnt_Doc_Id(l_pmnt_orig.payment_id);
             IF l_pmnt_doc_id IS NOT NULL
             THEN
                l_doc_orig := blc_documents_type(l_pmnt_doc_id);

                l_doc_orig.attrib_9 := pi_sap_doc_number;

                IF NOT l_doc_orig.update_blc_documents(pio_Err)
                THEN
                   ROLLBACK TO DOC_UPDATE;
                   RETURN;
                END IF;
             END IF;
          END IF;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Set_Result_Acc_Trx');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Set_Result_Acc_Trx', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '|| SQLERRM);
END Set_Result_Acc_Trx;

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Recreate_Acc_Trx
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
-- Purpose: For given accounting voucher document in status R recreate accounting
-- transactions
--
-- Input parameters:
--     pi_acc_doc_id       NUMBER    Voucher doc Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_procedure_result VARCHAR2  Procedure result
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In UI to process accounting voucher documents in status R (Rejected)
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Recreate_Acc_Trx( pi_acc_doc_id       IN     NUMBER,
                            po_procedure_result OUT    VARCHAR2,
                            pio_Err             IN OUT SrvErr )
IS
    l_log_module      VARCHAR2(240);
    l_SrvErrMsg       SrvErrMsg;
    l_SrvErr          SrvErr;
    l_doc             blc_documents_type;
    l_action_notes    VARCHAR2(4000);
    --
    CURSOR c_notes IS
      SELECT notes
      FROM blc_actions
      WHERE document_id = pi_acc_doc_id
      ORDER BY action_id DESC;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    l_log_module := C_DEFAULT_MODULE||'.Recreate_Acc_Trx';
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Recreate_Acc_Trx');
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'pi_acc_doc_id = '||pi_acc_doc_id);

    po_procedure_result := blc_gvar_process.flg_ok;

    IF pi_acc_doc_id IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Recreate_Acc_Trx', 'blc_doc_util_pkg.VDO.No_DocId' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_acc_doc_id = '||pi_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       po_procedure_result := blc_gvar_process.flg_err;
       RETURN;
    END IF;

    BEGIN
        l_doc := blc_documents_type(pi_acc_doc_id);
    EXCEPTION
       WHEN OTHERS THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Recreate_Acc_Trx', 'blc_doc_util_pkg.VDO.Inv_DocId', l_doc.doc_suffix);
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_EXCEPTION,
                                   'pi_acc_doc_id = '||pi_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
         po_procedure_result := blc_gvar_process.flg_err;
         RETURN;
    END;

    IF l_doc.status <> cust_gvar.STATUS_REJECT
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Recreate_Acc_Trx', 'cust_acc_process_pkg_2.RAT.Inv_DocStatus' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_acc_doc_id = '||pi_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       po_procedure_result := blc_gvar_process.flg_err;
       RETURN;
    END IF;

    IF blc_common_pkg.get_lookup_code(l_doc.doc_type_id) <> cust_gvar.DOC_ACC_TYPE
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Recreate_Acc_Trx', 'cust_acc_process_pkg_2.RAT.Inv_DocType' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_acc_doc_id = '||pi_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       po_procedure_result := blc_gvar_process.flg_err;
       RETURN;
    END IF;

    Process_Acc_Trx( pi_acc_doc_id   => pi_acc_doc_id,
                     pi_le_id        => NULL,
                     pi_status       => NULL,
                     pi_ip_code      => NULL,
                     pi_imm_flag     => 'N',
                     pio_Err         => pio_Err );

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_acc_doc_id = '||pi_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
       po_procedure_result := blc_gvar_process.flg_err;
       RETURN;
    END IF;

    l_doc := blc_documents_type(pi_acc_doc_id);

    IF l_doc.status = cust_gvar.STATUS_REJECT
    THEN
       OPEN c_notes;
         FETCH c_notes
         INTO l_action_notes;
       CLOSE c_notes;

       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_process_pkg_2.Recreate_Acc_Trx', 'cust_acc_process_pkg_2.RAT.Accounting_Error', l_action_notes);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'pi_acc_doc_id = '||pi_acc_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
          po_procedure_result := blc_gvar_process.flg_err;
          RETURN;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'po_procedure_result = '||po_procedure_result);
    blc_log_pkg.insert_message(l_log_module,C_LEVEL_PROCEDURE,'END of procedure Recreate_Acc_Trx');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg(l_SrvErrMsg, 'cust_acc_process_pkg_2.Recreate_Acc_Trx', SQLERRM);
    srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '||SQLERRM);
END Recreate_Acc_Trx;
--
END cust_acc_process_pkg_2;
/
