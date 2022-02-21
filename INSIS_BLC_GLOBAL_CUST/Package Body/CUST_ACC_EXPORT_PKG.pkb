CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_ACC_EXPORT_PKG AS

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains procedures preparing data for export for the purposes of
-- accounting transaction posting
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

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_acc_export';
--==============================================================================

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Process_SAP_Result_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      12.11.2017  Creation;
--
-- Purpose:
--    Process SAP result proforma to the interface and BLC tables
--
-- Input parameters:
--     pi_header_id        NUMBER(17,0)       Header Id  - ID in BLC_PROFORMA_GEN
--     pi_line_number_from NUMBER(5,0)        Line number from
--     pi_line_number_to   NUMBER             Line number to
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number contains 3 concatenated parts:
--                                             - SAP Document ID
--                                             - SAP Company
--                                             - SAP Year
--     pi_SAP_start_date   DATE               SAP execution start date
--     pi_SAP_end_date     DATE               SAP execution end date
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - E - Error
--                                              - T - Transferred
--     pi_err_code         VARCHAR2(30)       Error type
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr             Specifies structure for passing back
--                                            the error code, error TYPE and
--                                            corresponding message.
--
-- Output parameters:
--     po_set_header       VARCHAR2          Y/N - all lines in header are set
--     pio_Err             SrvErr            Specifies structure for passing back
--                                           the error code, error TYPE and
--                                           corresponding message.
--
-- Usage: In integration to return some result from SAP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_SAP_Result_Proforma
   (pi_header_id        IN     NUMBER,
    pi_line_number_from IN     NUMBER,
    pi_line_number_to   IN     NUMBER,
    pi_SAP_doc_number   IN     VARCHAR2,
    pi_SAP_start_date   IN     DATE,
    pi_SAP_end_date     IN     DATE,
    pi_status           IN     VARCHAR2,
    pi_err_code         IN     VARCHAR2 DEFAULT NULL,
    pi_err_message      IN     VARCHAR2,
    po_set_header       OUT    VARCHAR2,
    pio_Err             IN OUT SrvErr)
IS
    l_log_module           VARCHAR2(240);
    l_SrvErrMsg            SrvErrMsg;
    l_count_n              PLS_INTEGER;
    l_count_p              PLS_INTEGER;
    l_count_d              PLS_INTEGER;
    l_count_s              PLS_INTEGER;
    l_header_status        VARCHAR2(1);
    l_reversed_id          NUMBER;
    l_break                VARCHAR2(3);
    l_action_type          VARCHAR2(30); --LPVS-117
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Process_SAP_Result_Proforma';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Process_SAP_Result_Proforma');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_header_id = '||pi_header_id);
    l_break := '000';

    BEGIN
       SELECT reversed_id, status, action_type
       INTO l_reversed_id, l_header_status, l_action_type --LPVS-117
       FROM blc_proforma_gen
       WHERE id = pi_header_id;
    EXCEPTION
       WHEN OTHERS THEN
          l_header_status := NULL;
          l_reversed_id := NULL;
    END;

    IF l_header_status IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', 'cust_acc_export_pkg.PSR.Inv_Header_Id',cust_gvar.TABLE_PROFORMA_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    l_break := '001';
    IF l_reversed_id IS NULL
    THEN
       SELECT count(*)
       INTO l_count_n
       FROM blc_proforma_acc
       WHERE id = pi_header_id
       AND status = cust_gvar.STATUS_NEW;

       SELECT count(*)
       INTO l_count_p
       FROM blc_proforma_acc
       WHERE id = pi_header_id
       AND status = cust_gvar.STATUS_PROCESSING;

       SELECT count(*)
       INTO l_count_d
       FROM blc_proforma_acc
       WHERE id = pi_header_id
       AND status = decode(pi_status, cust_gvar.STATUS_ERROR, cust_gvar.STATUS_TRANSFER, cust_gvar.STATUS_ERROR);

       SELECT count(*)
       INTO l_count_s
       FROM blc_proforma_acc
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number)
       AND status = pi_status;
    ELSE
       IF l_header_status = cust_gvar.STATUS_NEW
       THEN
          l_count_n := 1;
       ELSIF l_header_status = cust_gvar.STATUS_PROCESSING
       THEN
          l_count_p := 1;
       ELSIF l_header_status <> pi_status
       THEN
          l_count_d := 1;
       ELSIF l_header_status = pi_status
       THEN
          l_count_s := 1;
       END IF;
    END IF;

    IF l_count_n > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', 'cust_acc_export_pkg.PSR.New_Status',cust_gvar.TABLE_PROFORMA_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_p > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', 'cust_acc_export_pkg.PSR.Processing_Status',cust_gvar.TABLE_PROFORMA_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_d > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', 'cust_acc_export_pkg.PSR.Diff_Status',cust_gvar.TABLE_PROFORMA_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_s > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', 'cust_acc_export_pkg.PSR.Same_Status',cust_gvar.TABLE_PROFORMA_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    --
    l_break := '002';
    IF l_reversed_id IS NULL
    THEN
       UPDATE blc_gl_insis2gl gl
       SET gl.cr_segment29 = pi_sap_doc_number
       WHERE gl.operation_num = pi_header_id
       AND to_number(gl.cr_segment28) BETWEEN nvl(pi_line_number_from, to_number(gl.cr_segment28)) AND nvl(pi_line_number_to, to_number(gl.cr_segment28));
       --
       UPDATE blc_proforma_acc
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);

       SELECT count(*)
       INTO l_count_d
       FROM blc_proforma_acc
       WHERE id = pi_header_id
       AND status <> cust_gvar.STATUS_TRANSFER;
    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       UPDATE blc_proforma_acc
       SET reversal_sap_doc_number = pi_sap_doc_number
       WHERE id = l_reversed_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);
    END IF;

    IF sql%rowcount = 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', 'cust_acc_export_pkg.PSR.No_Lines',cust_gvar.TABLE_PROFORMA_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       RETURN;
    END IF;

    --
    l_break := '003';
    IF l_reversed_id IS NULL
    THEN
       SELECT count(*)
       INTO l_count_d
       FROM blc_proforma_acc
       WHERE id = pi_header_id
       AND status <> pi_status;
    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       SELECT count(*)
       INTO l_count_d
       FROM blc_proforma_acc
       WHERE id = l_reversed_id
       AND reversal_sap_doc_number IS NULL;
    ELSE
       l_count_d := 0;
    END IF;

    l_break := '004';
    IF l_count_d = 0
    THEN
       UPDATE blc_proforma_gen
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date,
           error_type = pi_err_code,
           error_msg = pi_err_message
       WHERE id = pi_header_id;

       IF l_reversed_id IS NOT NULL AND pi_status = cust_gvar.STATUS_TRANSFER
       THEN
          UPDATE blc_proforma_gen
          SET reversal_sap_doc_number = pi_sap_doc_number
          WHERE id = l_reversed_id;
       END IF;

       IF l_action_type = 'POL' --LPVS-117 add check of action type
       THEN
          po_set_header := 'N';
       ELSE
          po_set_header := 'Y';
       END IF;
    ELSE
       po_set_header := 'N';
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_set_header = '||po_set_header);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Process_SAP_Result_Proforma');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Proforma', l_break||' - '||SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_header_id = '||pi_header_id||' - '|| l_break||' - '||SQLERRM);
END Process_SAP_Result_Proforma;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Process_SAP_Result_Claim
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      12.11.2017  Creation;
--
-- Purpose:
--    Process SAP result claim to the interface and BLC tables
--
-- Input parameters:
--     pi_header_id        NUMBER(17,0)       Header Id  - ID in BLC_CLAIM_GEN
--     pi_line_number_from NUMBER(5,0)        Line number from
--     pi_line_number_to   NUMBER             Line number to
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number contains 3 concatenated parts:
--                                             - SAP Document ID
--                                             - SAP Company
--                                             - SAP Year
--     pi_SAP_start_date   DATE               SAP execution start date
--     pi_SAP_end_date     DATE               SAP execution end date
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - E - Error
--                                              - S - Success
--     pi_err_code         VARCHAR2(30)       Error type
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr             Specifies structure for passing back
--                                            the error code, error TYPE and
--                                            corresponding message.
--
-- Output parameters:
--     po_set_header       VARCHAR2          Y/N - all lines in header are set
--     pio_Err             SrvErr            Specifies structure for passing back
--                                           the error code, error TYPE and
--                                           corresponding message.
--
-- Usage: In integration to return some result from SAP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_SAP_Result_Claim
   (pi_header_id        IN     NUMBER,
    pi_line_number_from IN     NUMBER,
    pi_line_number_to   IN     NUMBER,
    pi_SAP_doc_number   IN     VARCHAR2,
    pi_SAP_start_date   IN     DATE,
    pi_SAP_end_date     IN     DATE,
    pi_status           IN     VARCHAR2,
    pi_err_code         IN     VARCHAR2 DEFAULT NULL,
    pi_err_message      IN     VARCHAR2,
    po_set_header       OUT    VARCHAR2,
    pio_Err             IN OUT SrvErr)
IS
    l_log_module           VARCHAR2(240);
    l_SrvErrMsg            SrvErrMsg;
    l_count_n              PLS_INTEGER;
    l_count_p              PLS_INTEGER;
    l_count_d              PLS_INTEGER;
    l_count_s              PLS_INTEGER;
    l_header_status        VARCHAR2(1);
    l_reversed_id          NUMBER;
    l_break                VARCHAR2(3);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Process_SAP_Result_Claim';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Process_SAP_Result_Claim');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_header_id = '||pi_header_id);
    l_break := '000';

    BEGIN
       SELECT reversed_id, status
       INTO l_reversed_id, l_header_status
       FROM blc_claim_gen
       WHERE id = pi_header_id;
    EXCEPTION
       WHEN OTHERS THEN
          l_header_status := NULL;
          l_reversed_id := NULL;
    END;

    IF l_header_status IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.Inv_Header_Id',cust_gvar.TABLE_CLAIM_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    l_break := '001';
    IF l_reversed_id IS NULL
    THEN
       SELECT count(*)
       INTO l_count_n
       FROM blc_claim_acc
       WHERE id = pi_header_id
       AND status = cust_gvar.STATUS_NEW;

       SELECT count(*)
       INTO l_count_p
       FROM blc_claim_acc
       WHERE id = pi_header_id
       AND status = cust_gvar.STATUS_PROCESSING;

       SELECT count(*)
       INTO l_count_d
       FROM blc_claim_acc
       WHERE id = pi_header_id
       AND status = decode(pi_status, cust_gvar.STATUS_ERROR, cust_gvar.STATUS_TRANSFER, cust_gvar.STATUS_ERROR);

       SELECT count(*)
       INTO l_count_s
       FROM blc_claim_acc
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number)
       AND status = pi_status;
    ELSE
       IF l_header_status = cust_gvar.STATUS_NEW
       THEN
          l_count_n := 1;
       ELSIF l_header_status = cust_gvar.STATUS_PROCESSING
       THEN
          l_count_p := 1;
       ELSIF l_header_status <> pi_status
       THEN
          l_count_d := 1;
       ELSIF l_header_status = pi_status
       THEN
          l_count_s := 1;
       END IF;
    END IF;

    IF l_count_n > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.New_Status',cust_gvar.TABLE_CLAIM_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_p > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.Processing_Status',cust_gvar.TABLE_CLAIM_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_d > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.Diff_Status',cust_gvar.TABLE_CLAIM_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_s > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.Same_Status',cust_gvar.TABLE_CLAIM_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    --
    l_break := '002';
    IF l_reversed_id IS NULL
    THEN
       UPDATE blc_gl_insis2gl gl
       SET gl.cr_segment29 = pi_sap_doc_number
       WHERE gl.operation_num = pi_header_id
       AND to_number(gl.cr_segment28) BETWEEN nvl(pi_line_number_from, to_number(gl.cr_segment28)) AND nvl(pi_line_number_to, to_number(gl.cr_segment28));
       --
       UPDATE blc_claim_acc
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);

       SELECT count(*)
       INTO l_count_d
       FROM blc_claim_acc
       WHERE id = pi_header_id
       AND status <> cust_gvar.STATUS_TRANSFER;
    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       UPDATE blc_claim_acc
       SET reversal_sap_doc_number = pi_sap_doc_number
       WHERE id = l_reversed_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);
    END IF;

    IF sql%rowcount = 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.No_Lines',cust_gvar.TABLE_CLAIM_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       RETURN;
    END IF;

    --
    l_break := '003';
    IF l_reversed_id IS NULL
    THEN
       SELECT count(*)
       INTO l_count_d
       FROM blc_claim_acc
       WHERE id = pi_header_id
       AND status <> pi_status;
    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       SELECT count(*)
       INTO l_count_d
       FROM blc_claim_acc
       WHERE id = l_reversed_id
       AND reversal_sap_doc_number IS NULL;
    ELSE
       l_count_d := 0;
    END IF;

    l_break := '004';
    IF l_count_d = 0
    THEN
       UPDATE blc_claim_gen
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date,
           error_type = pi_err_code,
           error_msg = pi_err_message
       WHERE id = pi_header_id;

       IF l_reversed_id IS NOT NULL AND pi_status = cust_gvar.STATUS_TRANSFER
       THEN
          UPDATE blc_claim_gen
          SET reversal_sap_doc_number = pi_sap_doc_number
          WHERE id = l_reversed_id;
       END IF;

       po_set_header := 'Y';
    ELSE
       po_set_header := 'N';
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_set_header = '||po_set_header);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Process_SAP_Result_Claim');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', l_break||' - '||SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_header_id = '||pi_header_id||' - '|| l_break||' - '||SQLERRM);
END Process_SAP_Result_Claim;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Process_SAP_Result_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      12.11.2017  Creation;
--
-- Purpose:
--    Process SAP result claim to the interface and BLC tables
--
-- Input parameters:
--     pi_header_id        NUMBER(17,0)       Header Id  - ID in BLC_ACCOUNT_GEN
--     pi_line_number_from NUMBER(5,0)        Line number from
--     pi_line_number_to   NUMBER             Line number to
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number contains 3 concatenated parts:
--                                             - SAP Document ID
--                                             - SAP Company
--                                             - SAP Year
--     pi_SAP_start_date   DATE               SAP execution start date
--     pi_SAP_end_date     DATE               SAP execution end date
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - E - Error
--                                              - S - Success
--     pi_err_code         VARCHAR2(30)       Error type
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr             Specifies structure for passing back
--                                            the error code, error TYPE and
--                                            corresponding message.
--
-- Output parameters:
--     po_set_header       VARCHAR2          Y/N - all lines in header are set
--     pio_Err             SrvErr            Specifies structure for passing back
--                                           the error code, error TYPE and
--                                           corresponding message.
--
-- Usage: In integration to return some result from SAP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_SAP_Result_Account
   (pi_header_id        IN     NUMBER,
    pi_line_number_from IN     NUMBER,
    pi_line_number_to   IN     NUMBER,
    pi_SAP_doc_number   IN     VARCHAR2,
    pi_SAP_start_date   IN     DATE,
    pi_SAP_end_date     IN     DATE,
    pi_status           IN     VARCHAR2,
    pi_err_code         IN     VARCHAR2 DEFAULT NULL,
    pi_err_message      IN     VARCHAR2,
    po_set_header       OUT    VARCHAR2,
    pio_Err             IN OUT SrvErr)
IS
    l_log_module           VARCHAR2(240);
    l_SrvErrMsg            SrvErrMsg;
    l_count_n              PLS_INTEGER;
    l_count_p              PLS_INTEGER;
    l_count_d              PLS_INTEGER;
    l_count_s              PLS_INTEGER;
    l_header_status        VARCHAR2(1);
    l_break                VARCHAR2(3);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Process_SAP_Result_Account';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Process_SAP_Result_Account');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_header_id = '||pi_header_id);
    l_break := '000';

    BEGIN
       SELECT status
       INTO l_header_status
       FROM blc_account_gen
       WHERE id = pi_header_id;
    EXCEPTION
       WHEN OTHERS THEN
          l_header_status := NULL;
    END;

    IF l_header_status IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Account', 'cust_acc_export_pkg.PSR.Inv_Header_Id',cust_gvar.TABLE_ACCOUNT_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    l_break := '001';

    SELECT count(*)
    INTO l_count_n
    FROM blc_account_acc
    WHERE id = pi_header_id
    AND status = cust_gvar.STATUS_NEW;

    SELECT count(*)
    INTO l_count_p
    FROM blc_account_acc
    WHERE id = pi_header_id
    AND status = cust_gvar.STATUS_PROCESSING;

    SELECT count(*)
    INTO l_count_d
    FROM blc_account_acc
    WHERE id = pi_header_id
    AND status = decode(pi_status, cust_gvar.STATUS_ERROR, cust_gvar.STATUS_TRANSFER, cust_gvar.STATUS_ERROR);

    SELECT count(*)
    INTO l_count_s
    FROM blc_account_acc
    WHERE id = pi_header_id
    AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number)
    AND status = pi_status;

    IF l_count_n > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Account', 'cust_acc_export_pkg.PSR.New_Status',cust_gvar.TABLE_ACCOUNT_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_p > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.Processing_Status',cust_gvar.TABLE_ACCOUNT_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_d > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Account', 'cust_acc_export_pkg.PSR.Diff_Status',cust_gvar.TABLE_ACCOUNT_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_s > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Claim', 'cust_acc_export_pkg.PSR.Same_Status',cust_gvar.TABLE_ACCOUNT_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    --
    l_break := '002';
       UPDATE blc_gl_insis2gl gl
       SET gl.cr_segment29 = pi_sap_doc_number
       WHERE gl.operation_num = pi_header_id
       AND to_number(gl.cr_segment28) BETWEEN nvl(pi_line_number_from, to_number(gl.cr_segment28)) AND nvl(pi_line_number_to, to_number(gl.cr_segment28));
       --
       UPDATE blc_account_acc
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);

       SELECT count(*)
       INTO l_count_d
       FROM blc_account_acc
       WHERE id = pi_header_id
       AND status <> cust_gvar.STATUS_TRANSFER;

    IF sql%rowcount = 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Account', 'cust_acc_export_pkg.PSR.No_Lines',cust_gvar.TABLE_ACCOUNT_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       RETURN;
    END IF;

    --
    l_break := '003';
       SELECT count(*)
       INTO l_count_d
       FROM blc_account_acc
       WHERE id = pi_header_id
       AND status <> pi_status;

    l_break := '004';
    IF l_count_d = 0
    THEN
       UPDATE blc_account_gen
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date,
           error_type = pi_err_code,
           error_msg = pi_err_message
       WHERE id = pi_header_id;

       po_set_header := 'Y';
    ELSE
       po_set_header := 'N';
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_set_header = '||po_set_header);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Process_SAP_Result_Account');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Account', l_break||' - '||SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_header_id = '||pi_header_id||' - '|| l_break||' - '||SQLERRM);
END Process_SAP_Result_Account;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Process_SAP_Result_Rei
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      02.01.2018  Creation;
--
-- Purpose:
--    Process SAP result reinsurance to the interface and BLC tables
--
-- Input parameters:
--     pi_header_id        NUMBER(17,0)       Header Id  - ID in BLC_REI_GEN
--     pi_line_number_from NUMBER(5,0)        Line number from
--     pi_line_number_to   NUMBER             Line number to
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number contains 3 concatenated parts:
--                                             - SAP Document ID
--                                             - SAP Company
--                                             - SAP Year
--     pi_SAP_start_date   DATE               SAP execution start date
--     pi_SAP_end_date     DATE               SAP execution end date
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - E - Error
--                                              - T - Transferred
--     pi_err_code         VARCHAR2(30)       Error type
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr             Specifies structure for passing back
--                                            the error code, error TYPE and
--                                            corresponding message.
--
-- Output parameters:
--     po_set_header       VARCHAR2          Y/N - all lines in header are set
--     pio_Err             SrvErr            Specifies structure for passing back
--                                           the error code, error TYPE and
--                                           corresponding message.
--
-- Usage: In integration to return some result from SAP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_SAP_Result_Rei
   (pi_header_id        IN     NUMBER,
    pi_line_number_from IN     NUMBER,
    pi_line_number_to   IN     NUMBER,
    pi_SAP_doc_number   IN     VARCHAR2,
    pi_SAP_start_date   IN     DATE,
    pi_SAP_end_date     IN     DATE,
    pi_status           IN     VARCHAR2,
    pi_err_code         IN     VARCHAR2 DEFAULT NULL,
    pi_err_message      IN     VARCHAR2,
    po_set_header       OUT    VARCHAR2,
    pio_Err             IN OUT SrvErr)
IS
    l_log_module           VARCHAR2(240);
    l_SrvErrMsg            SrvErrMsg;
    l_count_n              PLS_INTEGER;
    l_count_p              PLS_INTEGER;
    l_count_d              PLS_INTEGER;
    l_count_s              PLS_INTEGER;
    l_header_status        VARCHAR2(1);
    l_reversed_id          NUMBER;
    l_break                VARCHAR2(3);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Process_SAP_Result_Rei';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Process_SAP_Result_Rei');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_header_id = '||pi_header_id);
    l_break := '000';

    BEGIN
       SELECT reversed_id, status
       INTO l_reversed_id, l_header_status
       FROM blc_rei_gen
       WHERE id = pi_header_id;
    EXCEPTION
       WHEN OTHERS THEN
          l_header_status := NULL;
          l_reversed_id := NULL;
    END;

    IF l_header_status IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', 'cust_acc_export_pkg.PSR.Inv_Header_Id',cust_gvar.TABLE_REI_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    l_break := '001';
    IF l_reversed_id IS NULL
    THEN
       SELECT count(*)
       INTO l_count_n
       FROM blc_rei_acc
       WHERE id = pi_header_id
       AND status = cust_gvar.STATUS_NEW;

       SELECT count(*)
       INTO l_count_p
       FROM blc_rei_acc
       WHERE id = pi_header_id
       AND status = cust_gvar.STATUS_PROCESSING;

       SELECT count(*)
       INTO l_count_d
       FROM blc_rei_acc
       WHERE id = pi_header_id
       AND status = decode(pi_status, cust_gvar.STATUS_ERROR, cust_gvar.STATUS_TRANSFER, cust_gvar.STATUS_ERROR);

       SELECT count(*)
       INTO l_count_s
       FROM blc_rei_acc
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number)
       AND status = pi_status;
    ELSE
       IF l_header_status = cust_gvar.STATUS_NEW
       THEN
          l_count_n := 1;
       ELSIF l_header_status = cust_gvar.STATUS_PROCESSING
       THEN
          l_count_p := 1;
       ELSIF l_header_status <> pi_status
       THEN
          l_count_d := 1;
       ELSIF l_header_status = pi_status
       THEN
          l_count_s := 1;
       END IF;
    END IF;

    IF l_count_n > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', 'cust_acc_export_pkg.PSR.New_Status',cust_gvar.TABLE_REI_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_p > 0 AND nvl(pi_err_code, 'SAP_ERROR') = 'SAP_ERROR'
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', 'cust_acc_export_pkg.PSR.Processing_Status',cust_gvar.TABLE_REI_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_d > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', 'cust_acc_export_pkg.PSR.Diff_Status',cust_gvar.TABLE_REI_GEN||'/'||pi_header_id );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF l_count_s > 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', 'cust_acc_export_pkg.PSR.Same_Status',cust_gvar.TABLE_REI_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    --
    l_break := '002';
    IF l_reversed_id IS NULL
    THEN
       UPDATE blc_gl_insis2gl gl
       SET gl.cr_segment29 = pi_sap_doc_number
       WHERE gl.operation_num = pi_header_id
       AND to_number(gl.cr_segment28) BETWEEN nvl(pi_line_number_from, to_number(gl.cr_segment28)) AND nvl(pi_line_number_to, to_number(gl.cr_segment28));
       --
       UPDATE blc_rei_acc
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date
       WHERE id = pi_header_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);

       SELECT count(*)
       INTO l_count_d
       FROM blc_rei_acc
       WHERE id = pi_header_id
       AND status <> cust_gvar.STATUS_TRANSFER;
    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       UPDATE blc_rei_acc
       SET reversal_sap_doc_number = pi_sap_doc_number
       WHERE id = l_reversed_id
       AND line_number BETWEEN nvl(pi_line_number_from,line_number) AND nvl(pi_line_number_to,line_number);
    END IF;

    IF sql%rowcount = 0
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', 'cust_acc_export_pkg.PSR.No_Lines',cust_gvar.TABLE_REI_GEN||'/'||pi_header_id||'/'||pi_line_number_from||'-'||pi_line_number_to );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       RETURN;
    END IF;

    --
    l_break := '003';
    IF l_reversed_id IS NULL
    THEN
       SELECT count(*)
       INTO l_count_d
       FROM blc_rei_acc
       WHERE id = pi_header_id
       AND status <> pi_status;
    ELSIF pi_status = cust_gvar.STATUS_TRANSFER
    THEN
       SELECT count(*)
       INTO l_count_d
       FROM blc_rei_acc
       WHERE id = l_reversed_id
       AND reversal_sap_doc_number IS NULL;
    ELSE
       l_count_d := 0;
    END IF;

    l_break := '004';
    IF l_count_d = 0
    THEN
       UPDATE blc_rei_gen
       SET status = pi_status,
           sap_doc_number = pi_sap_doc_number,
           process_start_date = pi_sap_start_date,
           process_end_date = pi_sap_end_date,
           error_type = pi_err_code,
           error_msg = pi_err_message
       WHERE id = pi_header_id;

       IF l_reversed_id IS NOT NULL AND pi_status = cust_gvar.STATUS_TRANSFER
       THEN
          UPDATE blc_rei_gen
          SET reversal_sap_doc_number = pi_sap_doc_number
          WHERE id = l_reversed_id;
       END IF;

       po_set_header := 'Y';
    ELSE
       po_set_header := 'N';
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_set_header = '||po_set_header);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Process_SAP_Result_Rei');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result_Rei', l_break||' - '||SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_header_id = '||pi_header_id||' - '|| l_break||' - '||SQLERRM);
END Process_SAP_Result_Rei;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Process_SAP_Result
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      12.10.2017  Creation;
--
-- Purpose:
--    Process SAP result to the interface and BLC tables
--
-- Input parameters:
--     pi_header_id        NUMBER(17,0)       Header Id  - ID in interface table
--     pi_header_table     VARCHAR2(30)       Interface table name (BLC_PROFORMA_GEN,..)
--     pi_line_number_from NUMBER(5,0)        Line number from
--     pi_line_number_to   NUMBER(5,0)        Line number to
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number contains 3 concatenated parts:
--                                             - SAP Document ID
--                                             - SAP Company
--                                             - SAP Year
--     pi_SAP_start_date   DATE               SAP execution start date
--     pi_SAP_end_date     DATE               SAP execution end date
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - T - Transferred
--                                              - E - Error
--     pi_err_code         VARCHAR2(30)       Error type
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr             Specifies structure for passing back
--                                            the error code, error TYPE and
--                                            corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration to return some result from SAP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_SAP_Result
   (pi_header_id        IN     NUMBER,
    pi_header_table     IN     VARCHAR2,
    pi_line_number_from IN     NUMBER,
    pi_line_number_to   IN     NUMBER,
    pi_SAP_doc_number   IN     VARCHAR2,
    pi_SAP_start_date   IN     DATE,
    pi_SAP_end_date     IN     DATE,
    pi_status           IN     VARCHAR2,
    pi_err_code         IN     VARCHAR2 DEFAULT NULL,
    pi_err_message      IN     VARCHAR2,
    pio_Err             IN OUT SrvErr)
IS
    l_log_module           VARCHAR2(240);
    l_SrvErrMsg            SrvErrMsg;
    l_set_header           VARCHAR2(1);
    l_acc_doc_id           NUMBER;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Process_SAP_Result';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Process_SAP_Result');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_header_id = '||pi_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_header_table = '||pi_header_table);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_line_number_from = '||pi_line_number_from);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_line_number_to = '||pi_line_number_to);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_SAP_doc_number = '||pi_SAP_doc_number);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_SAP_start_date = '||to_char(pi_SAP_start_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_SAP_end_date = '||to_char(pi_SAP_end_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_status = '||pi_status);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_err_code = '||pi_err_code);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_err_message = '||pi_err_message);

    IF pi_header_id IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.No_Header_Id' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_header_table IS NULL OR pi_header_table NOT IN (cust_gvar.TABLE_PROFORMA_GEN, cust_gvar.TABLE_CLAIM_GEN, cust_gvar.TABLE_ACCOUNT_GEN,
                                                          cust_gvar.TABLE_REI_GEN, cust_gvar.TABLE_LOAND_GEN, cust_gvar.TABLE_LOAN_GEN )
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.Inv_Header_Table', pi_header_table );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_status = 'T' AND pi_SAP_doc_number IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.No_SAP_doc_number' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_SAP_start_date IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.No_SAP_start_date' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_SAP_end_date IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.No_SAP_end_date' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_status IS NULL OR pi_status NOT IN (cust_gvar.STATUS_ERROR,cust_gvar.STATUS_TRANSFER)
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.Inv_Status', pi_status );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       FOR i IN 1..pio_Err.COUNT
       LOOP
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'pi_header_id = '||pi_header_id||' - '||pio_Err(i).errmessage);
       END LOOP;
       RETURN;
    END IF;

    --
    IF pi_header_table = cust_gvar.TABLE_PROFORMA_GEN
    THEN
       Process_SAP_Result_Proforma
           (pi_header_id        =>  pi_header_id,
            pi_line_number_from =>  pi_line_number_from,
            pi_line_number_to   =>  pi_line_number_to,
            pi_SAP_doc_number   =>  pi_SAP_doc_number,
            pi_SAP_start_date   =>  pi_SAP_start_date,
            pi_SAP_end_date     =>  pi_SAP_end_date,
            pi_status           =>  pi_status,
            pi_err_code         =>  pi_err_code,
            pi_err_message      =>  pi_err_message,
            po_set_header       =>  l_set_header,
            pio_Err             =>  pio_Err);
    ELSIF pi_header_table = cust_gvar.TABLE_CLAIM_GEN
    THEN
       Process_SAP_Result_Claim
           (pi_header_id        =>  pi_header_id,
            pi_line_number_from =>  pi_line_number_from,
            pi_line_number_to   =>  pi_line_number_to,
            pi_SAP_doc_number   =>  pi_SAP_doc_number,
            pi_SAP_start_date   =>  pi_SAP_start_date,
            pi_SAP_end_date     =>  pi_SAP_end_date,
            pi_status           =>  pi_status,
            pi_err_code         =>  pi_err_code,
            pi_err_message      =>  pi_err_message,
            po_set_header       =>  l_set_header,
            pio_Err             =>  pio_Err);
    ELSIF pi_header_table = cust_gvar.TABLE_ACCOUNT_GEN
    THEN
       Process_SAP_Result_Account
           (pi_header_id        =>  pi_header_id,
            pi_line_number_from =>  pi_line_number_from,
            pi_line_number_to   =>  pi_line_number_to,
            pi_SAP_doc_number   =>  pi_SAP_doc_number,
            pi_SAP_start_date   =>  pi_SAP_start_date,
            pi_SAP_end_date     =>  pi_SAP_end_date,
            pi_status           =>  pi_status,
            pi_err_code         =>  pi_err_code,
            pi_err_message      =>  pi_err_message,
            po_set_header       =>  l_set_header,
            pio_Err             =>  pio_Err);
    ELSIF pi_header_table = cust_gvar.TABLE_REI_GEN
    THEN
       Process_SAP_Result_Rei
           (pi_header_id        =>  pi_header_id,
            pi_line_number_from =>  pi_line_number_from,
            pi_line_number_to   =>  pi_line_number_to,
            pi_SAP_doc_number   =>  pi_SAP_doc_number,
            pi_SAP_start_date   =>  pi_SAP_start_date,
            pi_SAP_end_date     =>  pi_SAP_end_date,
            pi_status           =>  pi_status,
            pi_err_code         =>  pi_err_code,
            pi_err_message      =>  pi_err_message,
            po_set_header       =>  l_set_header,
            pio_Err             =>  pio_Err);
    ELSIF pi_header_table = cust_gvar.TABLE_LOAND_GEN
    THEN
       cust_acc_export_2_pkg.Process_SAP_Result_LoanD
           (pi_header_id        =>  pi_header_id,
            pi_line_number_from =>  pi_line_number_from,
            pi_line_number_to   =>  pi_line_number_to,
            pi_SAP_doc_number   =>  pi_SAP_doc_number,
            pi_SAP_start_date   =>  pi_SAP_start_date,
            pi_SAP_end_date     =>  pi_SAP_end_date,
            pi_status           =>  pi_status,
            pi_err_code         =>  pi_err_code,
            pi_err_message      =>  pi_err_message,
            po_set_header       =>  l_set_header,
            pio_Err             =>  pio_Err);
    ELSIF pi_header_table = cust_gvar.TABLE_LOAN_GEN
    THEN
       cust_acc_export_2_pkg.Process_SAP_Result_Loan
           (pi_header_id        =>  pi_header_id,
            pi_line_number_from =>  pi_line_number_from,
            pi_line_number_to   =>  pi_line_number_to,
            pi_SAP_doc_number   =>  pi_SAP_doc_number,
            pi_SAP_start_date   =>  pi_SAP_start_date,
            pi_SAP_end_date     =>  pi_SAP_end_date,
            pi_status           =>  pi_status,
            pi_err_code         =>  pi_err_code,
            pi_err_message      =>  pi_err_message,
            po_set_header       =>  l_set_header,
            pio_Err             =>  pio_Err);
    END IF;

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       FOR i IN 1..pio_Err.COUNT
       LOOP
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'pi_header_id = '||pi_header_id||' - '||pio_Err(i).errmessage);
       END LOOP;
       RETURN;
    END IF;

    --
    IF l_set_header = 'Y'
    THEN
       BEGIN
         SELECT bd.doc_id
         INTO l_acc_doc_id
         FROM blc_documents bd,
              blc_lookups bl
         WHERE bd.doc_number = to_char(pi_header_id)
         AND bd.doc_type_id = bl.lookup_id
         AND bl.lookup_code = cust_gvar.DOC_ACC_TYPE;
         EXCEPTION
            WHEN OTHERS THEN
              srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', 'cust_acc_export_pkg.PSR.No_Acc_Doc', pi_header_table||'/'||pi_header_id );
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                         'pi_header_id = '||pi_header_id||' - Cannot calculate voucher doc_id for given header id');
              RETURN;
       END;

       --
       cust_acc_process_pkg.Set_Result_Acc_Trx
                         ( pi_acc_doc_id     => l_acc_doc_id,
                           pi_SAP_doc_number => pi_SAP_doc_number,
                           pi_status         => pi_status,
                           pi_err_message    => pi_err_message,
                           pio_Err           => pio_Err );

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_EXCEPTION,
                                    'pi_header_id = '||pi_header_id||' - '||pio_Err(pio_Err.LAST).errmessage);
          RETURN;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Process_SAP_Result');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Process_SAP_Result', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_header_id = '||pi_header_id||' - '||SQLERRM);
END Process_SAP_Result;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      27.10.2017  Creation;
-- Fadata      19.09.2018  Changed - calculate values for columns on document level;
-- Fadata      20.11.2020  Changed - LAP85-68 - add grouping by attrib_2 where store
--                                   commission type to split transactions for
--                                   MARKETER commissions;
-- Fadata      18.04.2021  Changed - LPV-2924 - exclude insertion of line with
--                                   zero amount;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given doc_id
--    are selected, grouped and summed into tables BLC_PROFORMA_GEN - as
--    master table and into BLC_PROFORMA_ACC - as detailed.
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Proforma
   (pi_doc_id        IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_proforma_gen_type   blc_proforma_gen%ROWTYPE;
    l_blc_proforma_acc_type   blc_proforma_acc%ROWTYPE;
    l_count                   PLS_INTEGER := 1;
    l_dr_segment10            VARCHAR2(25 CHAR);
    l_cr_segment10            VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Proforma';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Proforma');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);

    -- prepare header data for document
    BEGIN
      SELECT  gl.legal_entity,
              gl.dr_segment11,
              gl.dr_segment14,
              gl.dr_segment15,
              gl.effective_date,
              gl.op_currency,
              gl.dr_segment16,
              gl.attrib_0,
              to_date(gl.dr_segment17,'dd-mm-yyyy'),
              to_date(gl.dr_segment18,'dd-mm-yyyy'),
              gl.dr_segment19,
              gl.dr_segment20,
              gl.dr_segment21,
              to_date(gl.dr_segment22,'dd-mm-yyyy'),
              to_date(gl.dr_segment23,'dd-mm-yyyy'),
              gl.dr_segment24,
              gl.dr_segment25,
              gl.insr_type,
              gl.dr_segment26,
              gl.attrib_1,
              gl.dr_segment27,
              to_number(gl.dr_segment28),
              to_number(gl.dr_segment29),
              to_date(gl.dr_segment30,'dd-mm-yyyy'),
              gl.cr_segment11,
              gl.cr_segment12,
              gl.cr_segment13,
              gl.cr_segment14,
              gl.cr_segment15,
              gl.dr_segment12,
              gl.dr_segment13,
              gl.doc_id,
              gl.cr_segment16,
              gl.cr_segment17
      INTO  l_blc_proforma_gen_type.legal_entity,
            l_blc_proforma_gen_type.doc_type,
            l_blc_proforma_gen_type.doc_number,
            l_blc_proforma_gen_type.action_type,
            l_blc_proforma_gen_type.doc_issue_date,
            l_blc_proforma_gen_type.currency,
            l_blc_proforma_gen_type.tech_branch,
            l_blc_proforma_gen_type.policy_no,
            l_blc_proforma_gen_type.doc_start_date,
            l_blc_proforma_gen_type.doc_end_date,
            l_blc_proforma_gen_type.doc_party,
            l_blc_proforma_gen_type.ri_fac_flag,
            l_blc_proforma_gen_type.ref_doc_number,
            l_blc_proforma_gen_type.policy_start_date,
            l_blc_proforma_gen_type.policy_end_date,
            l_blc_proforma_gen_type.end_pol_flag,
            l_blc_proforma_gen_type.office_gl_no,
            l_blc_proforma_gen_type.insr_type,
            l_blc_proforma_gen_type.pay_way,
            l_blc_proforma_gen_type.pol_end_party_name,
            l_blc_proforma_gen_type.pol_end_party,
            l_blc_proforma_gen_type.doc_prem_amount,
            l_blc_proforma_gen_type.doc_amount,
            l_blc_proforma_gen_type.doc_due_date,
            l_blc_proforma_gen_type.protocol_number,
            l_blc_proforma_gen_type.sales_channel,
            l_blc_proforma_gen_type.intermed_type,
            l_blc_proforma_gen_type.vat_flag,
            l_blc_proforma_gen_type.business_unit,
            l_blc_proforma_gen_type.policy_class,
            l_blc_proforma_gen_type.header_class,
            l_blc_proforma_gen_type.doc_id,
            l_blc_proforma_gen_type.ip_code,
            l_blc_proforma_gen_type.priority
      FROM blc_gl_insis2gl gl
      WHERE gl.status = cust_gvar.STATUS_INITIAL
      AND gl.doc_id = pi_doc_id
      AND gl.event_code IN ( 'BLC001.PREM', 'BLC008.SIP' ) -- add SIP event 24.01.2020 phase 2 LPV-2163
      --AND gl.reversed_gltrans_id IS NULL
      AND EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.event_id = gl.event_id
                  AND be.attrib_9 = to_char(pi_acc_doc_id))
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          SELECT  gl.legal_entity,
                  gl.dr_segment11,
                  gl.dr_segment14,
                  gl.dr_segment15,
                  gl.effective_date,
                  gl.op_currency,
                  gl.dr_segment16,
                  gl.attrib_0,
                  to_date(gl.dr_segment17,'dd-mm-yyyy'),
                  to_date(gl.dr_segment18,'dd-mm-yyyy'),
                  gl.dr_segment19,
                  gl.dr_segment20,
                  gl.dr_segment21,
                  to_date(gl.dr_segment22,'dd-mm-yyyy'),
                  to_date(gl.dr_segment23,'dd-mm-yyyy'),
                  gl.dr_segment24,
                  gl.dr_segment25,
                  gl.insr_type,
                  gl.dr_segment26,
                  gl.attrib_1,
                  gl.dr_segment27,
                  to_number(gl.dr_segment28),
                  to_number(gl.dr_segment29),
                  to_date(gl.dr_segment30,'dd-mm-yyyy'),
                  gl.cr_segment11,
                  gl.cr_segment12,
                  gl.cr_segment13,
                  gl.cr_segment14,
                  gl.cr_segment15,
                  gl.dr_segment12,
                  gl.dr_segment13,
                  gl.doc_id,
                  gl.cr_segment16,
                  gl.cr_segment17
          INTO  l_blc_proforma_gen_type.legal_entity,
                l_blc_proforma_gen_type.doc_type,
                l_blc_proforma_gen_type.doc_number,
                l_blc_proforma_gen_type.action_type,
                l_blc_proforma_gen_type.doc_issue_date,
                l_blc_proforma_gen_type.currency,
                l_blc_proforma_gen_type.tech_branch,
                l_blc_proforma_gen_type.policy_no,
                l_blc_proforma_gen_type.doc_start_date,
                l_blc_proforma_gen_type.doc_end_date,
                l_blc_proforma_gen_type.doc_party,
                l_blc_proforma_gen_type.ri_fac_flag,
                l_blc_proforma_gen_type.ref_doc_number,
                l_blc_proforma_gen_type.policy_start_date,
                l_blc_proforma_gen_type.policy_end_date,
                l_blc_proforma_gen_type.end_pol_flag,
                l_blc_proforma_gen_type.office_gl_no,
                l_blc_proforma_gen_type.insr_type,
                l_blc_proforma_gen_type.pay_way,
                l_blc_proforma_gen_type.pol_end_party_name,
                l_blc_proforma_gen_type.pol_end_party,
                l_blc_proforma_gen_type.doc_prem_amount,
                l_blc_proforma_gen_type.doc_amount,
                l_blc_proforma_gen_type.doc_due_date,
                l_blc_proforma_gen_type.protocol_number,
                l_blc_proforma_gen_type.sales_channel,
                l_blc_proforma_gen_type.intermed_type,
                l_blc_proforma_gen_type.vat_flag,
                l_blc_proforma_gen_type.business_unit,
                l_blc_proforma_gen_type.policy_class,
                l_blc_proforma_gen_type.header_class,
                l_blc_proforma_gen_type.doc_id,
                l_blc_proforma_gen_type.ip_code,
                l_blc_proforma_gen_type.priority
          FROM blc_gl_insis2gl gl
          WHERE gl.status = cust_gvar.STATUS_INITIAL
          AND gl.doc_id = pi_doc_id
          --AND gl.reversed_gltrans_id IS NULL
          AND EXISTS (SELECT 'EVENT'
                      FROM blc_sla_events be
                      WHERE be.event_id = gl.event_id
                      AND be.attrib_9 = to_char(pi_acc_doc_id))
          AND ROWNUM = 1;
    END;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_proforma_gen_type.id
    FROM dual;

    l_blc_proforma_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_proforma_gen_type.created_on := SYSDATE;
    l_blc_proforma_gen_type.updated_on := SYSDATE;
    l_blc_proforma_gen_type.created_by := insis_context.get_user;
    l_blc_proforma_gen_type.updated_by := insis_context.get_user;
    l_blc_proforma_gen_type.status := cust_gvar.STATUS_NEW;

    --19.09.2018
    SELECT MIN(to_date(gl.dr_segment17,'dd-mm-yyyy')),
           MAX(to_date(gl.dr_segment18,'dd-mm-yyyy')),
           MIN(to_date(gl.dr_segment22,'dd-mm-yyyy')),
           MAX(to_date(gl.dr_segment23,'dd-mm-yyyy')),
           SUM(to_number(gl.dr_segment28)),
           MAX(gl.cr_segment14)
      INTO  l_blc_proforma_gen_type.doc_start_date,
            l_blc_proforma_gen_type.doc_end_date,
            l_blc_proforma_gen_type.policy_start_date,
            l_blc_proforma_gen_type.policy_end_date,
            l_blc_proforma_gen_type.doc_prem_amount,
            l_blc_proforma_gen_type.vat_flag
      FROM blc_gl_insis2gl gl
      WHERE gl.status = cust_gvar.STATUS_INITIAL
      AND gl.doc_id = pi_doc_id
      --AND gl.reversed_gltrans_id IS NULL
      AND EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.event_id = gl.event_id
                  AND be.attrib_9 = to_char(pi_acc_doc_id));
    --19.09.2018

    INSERT INTO blc_proforma_gen VALUES l_blc_proforma_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN (SELECT SUM(gl.op_amount) sum_amount,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 dr_acc_number,
                              gl.dr_segment6,
                              gl.dr_segment7,
                              gl.dr_segment8,
                              gl.dr_segment9,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 cr_acc_number,
                              gl.event_code,
                              gl.dt_account,
                              gl.ct_account,
                              MAX(gl.gltrans_id) gltrans_id,
                              gl.attrib_2 --LAP85-68
                        FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                        WHERE gl.status = cust_gvar.STATUS_INITIAL
                        AND gl.doc_id = pi_doc_id
                        --AND gl.reversed_gltrans_id IS NULL
                        AND EXISTS (SELECT 'EVENT'
                                    FROM blc_sla_events be
                                    WHERE be.event_id = gl.event_id
                                    AND be.attrib_9 = to_char(pi_acc_doc_id))
                        GROUP BY gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                                 gl.dr_segment6,
                                 gl.dr_segment7,
                                 gl.dr_segment8,
                                 gl.dr_segment9,
                                 gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                                 gl.event_code,
                                 gl.dt_account,
                                 gl.ct_account,
                                 gl.attrib_2 --LAP85-68
                         ORDER BY MAX(gl.gltrans_id))
       LOOP
          l_blc_proforma_acc_type.id := l_blc_proforma_gen_type.id;
          l_blc_proforma_acc_type.amount := abs(gl_detail.sum_amount);
          l_blc_proforma_acc_type.acc_temp_code := gl_detail.event_code;
          l_blc_proforma_acc_type.gltrans_id := gl_detail.gltrans_id;
          l_blc_proforma_acc_type.line_party := gl_detail.dr_segment6;
          l_blc_proforma_acc_type.tax_code := gl_detail.dr_segment7;
          l_blc_proforma_acc_type.inter_type := gl_detail.dr_segment8;
          l_blc_proforma_acc_type.comm_ci_percent := to_number(gl_detail.dr_segment9);
          --
          l_blc_proforma_acc_type.created_on := SYSDATE;
          l_blc_proforma_acc_type.updated_on := SYSDATE;
          l_blc_proforma_acc_type.created_by := insis_context.get_user;
          l_blc_proforma_acc_type.updated_by := insis_context.get_user;
          l_blc_proforma_acc_type.status := cust_gvar.STATUS_NEW;
          --
          l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
          l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
          --
          l_blc_proforma_acc_type.account := gl_detail.dr_acc_number;
          l_blc_proforma_acc_type.account_attribs := l_dr_segment10;

          IF gl_detail.sum_amount > 0
          THEN
             l_blc_proforma_acc_type.line_number := l_count;
             l_blc_proforma_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
          ELSE
             l_blc_proforma_acc_type.line_number := l_count + 1;
             l_blc_proforma_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
          END IF;

          --LPV-2924
          IF gl_detail.sum_amount <> 0
          THEN
             INSERT INTO blc_proforma_acc VALUES l_blc_proforma_acc_type;
          END IF;
          --
          l_blc_proforma_acc_type.account := gl_detail.cr_acc_number;
          l_blc_proforma_acc_type.account_attribs := l_cr_segment10;

          IF gl_detail.sum_amount > 0
          THEN
             l_blc_proforma_acc_type.line_number := l_count + 1;
             l_blc_proforma_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
          ELSE
             l_blc_proforma_acc_type.line_number := l_count;
             l_blc_proforma_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
          END IF;

          --LPV-2924
          IF gl_detail.sum_amount <> 0
          THEN
             INSERT INTO blc_proforma_acc VALUES l_blc_proforma_acc_type;
          END IF;

          UPDATE blc_gl_insis2gl gl
          SET gl.status = cust_gvar.STATUS_TRANSFER,
              gl.operation_num = l_blc_proforma_gen_type.id,
              --gl.cr_segment28 = l_count, --LPV-2924
              gl.cr_segment28 = (CASE WHEN gl_detail.sum_amount = 0
                                      THEN 0
                                      ELSE l_count
                                 END),
              gl.dr_segment10 = l_dr_segment10,
              gl.cr_segment10 = l_cr_segment10,
              gl.cr_segment18 = pi_acc_doc_id
          WHERE gl.status = cust_gvar.STATUS_INITIAL
          AND gl.doc_id = pi_doc_id
          --AND gl.reversed_gltrans_id IS NULL
          AND EXISTS (SELECT 'EVENT'
                      FROM blc_sla_events be
                      WHERE be.event_id = gl.event_id
                      AND be.attrib_9 = to_char(pi_acc_doc_id))
          AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
          AND nvl(gl.dr_segment6,'-999') = nvl(gl_detail.dr_segment6,'-999')
          AND nvl(gl.dr_segment7,'-999') = nvl(gl_detail.dr_segment7,'-999')
          AND nvl(gl.dr_segment8,'-999') = nvl(gl_detail.dr_segment8,'-999')
          AND nvl(gl.dr_segment9,'-999') = nvl(gl_detail.dr_segment9,'-999')
          AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
          AND gl.event_code = gl_detail.event_code
          AND nvl(gl.attrib_2,'-999') = nvl(gl_detail.attrib_2,'-999'); --LAP85-68

          --LPV-2924
          IF gl_detail.sum_amount <> 0
          THEN
             l_count := l_count + 2;
          END IF;
       END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_proforma_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Proforma');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Proforma', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Insert_SAP_Proforma;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Delete_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      25.11.2017  Creation;
--
-- Purpose:
--    Insert record for deletion of proforma into BLC_PROFORMA_GEN
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pi_acc_doc_prefix      VARCHAR2     Voucher doc prefix
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Delete_Proforma
   (pi_doc_id         IN     NUMBER,
    pi_acc_doc_id     IN     NUMBER,
    pi_reversed_id    IN     NUMBER,
    pi_acc_doc_prefix IN     VARCHAR2,
    po_header_id      OUT    NUMBER,
    pio_Err           IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_proforma_gen_type   blc_proforma_gen%ROWTYPE;
    l_doc                     blc_documents_type;
    --
    CURSOR c_act IS
      SELECT ba.action_date, substr(nvl(ba.attrib_0,ba.notes),1,400)
      FROM blc_actions ba,
           blc_lookups bl
      WHERE ba.document_id = pi_doc_id
      AND ba.action_type_id = bl.lookup_id
      AND bl.lookup_code = cust_gvar.ACTIVITY_DELETE
      ORDER BY ba.action_id DESC;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Delete_Proforma';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Delete_Proforma');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reversed_id = '||pi_reversed_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_prefix = '||pi_acc_doc_prefix);

    l_doc := blc_documents_type(pi_doc_id);

    -- prepare header data for document
    l_blc_proforma_gen_type.legal_entity := l_doc.legal_entity_id;
    l_blc_proforma_gen_type.doc_number := l_doc.doc_number;
    l_blc_proforma_gen_type.action_type := substr(pi_acc_doc_prefix,instr(pi_acc_doc_prefix,'-')+1);
    l_blc_proforma_gen_type.doc_id := l_doc.doc_id;
    l_blc_proforma_gen_type.ip_code := substr(pi_acc_doc_prefix,1,instr(pi_acc_doc_prefix,'-')-1);
    l_blc_proforma_gen_type.reversed_id := pi_reversed_id;

    --
    OPEN c_act;
       FETCH c_act
       INTO l_blc_proforma_gen_type.doc_reverse_date,
            l_blc_proforma_gen_type.reverse_reason;
    CLOSE c_act;

    l_blc_proforma_gen_type.reverse_reason := nvl(l_blc_proforma_gen_type.reverse_reason,'4');

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_proforma_gen_type.id
    FROM dual;

    l_blc_proforma_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_proforma_gen_type.created_on := SYSDATE;
    l_blc_proforma_gen_type.updated_on := SYSDATE;
    l_blc_proforma_gen_type.created_by := insis_context.get_user;
    l_blc_proforma_gen_type.updated_by := insis_context.get_user;
    l_blc_proforma_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_proforma_gen VALUES l_blc_proforma_gen_type;

    UPDATE blc_gl_insis2gl gl
    SET gl.status = cust_gvar.STATUS_TRANSFER,
        gl.operation_num = l_blc_proforma_gen_type.id,
        gl.dr_segment15 = l_blc_proforma_gen_type.action_type,
        gl.cr_segment16 = l_blc_proforma_gen_type.ip_code,
        gl.effective_date = l_blc_proforma_gen_type.doc_reverse_date,
        gl.cr_segment18 = pi_acc_doc_id
    WHERE gl.status = cust_gvar.STATUS_INITIAL
    AND gl.doc_id = pi_doc_id
    --AND gl.reversed_gltrans_id IS NOT NULL;
    AND EXISTS (SELECT 'EVENT'
                FROM blc_sla_events be
                WHERE be.event_id = gl.event_id
                AND be.attrib_9 = to_char(pi_acc_doc_id));

    po_header_id := l_blc_proforma_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Delete_Proforma');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Delete_Proforma', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Insert_SAP_Delete_Proforma;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      26.11.2017  Creation;
--             22.02.2018  add currency on insert lines (LPV-936)
--             01.06.2020  add group by event code to not mix OUT001 with OUT017
--                         and OUT018(LPV-2945)
--             01.11.2021  LAP85-190 - remove '/' from claim_no
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given payment_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_Pmnt
   (pi_payment_id    IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_claim_gen_type      blc_claim_gen%ROWTYPE;
    l_blc_claim_acc_type      blc_claim_acc%ROWTYPE;
    l_count                   PLS_INTEGER := 1;
    l_dr_segment10            VARCHAR2(25 CHAR);
    l_cr_segment10            VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Claim_Pmnt';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Claim_Pmnt');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);

    -- prepare header data for document
    BEGIN
      SELECT  gl.legal_entity,
              --gl.dr_segment14, --LAP85-190
              DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190
              gl.dr_segment15,
              gl.effective_date,
              gl.op_currency,
              gl.dr_segment16,
              gl.attrib_0,
              gl.attrib_2,
              to_date(gl.dr_segment18,'dd-mm-yyyy'),
              gl.dr_segment19,
              gl.attrib_1,
              gl.dr_segment22,
              gl.dr_segment23,
              gl.dr_segment24,
              gl.dr_segment25,
              gl.dr_segment26,
              gl.dr_segment27,
              to_number(gl.dr_segment28),
              gl.cr_segment15,
              gl.dr_segment12,
              gl.dr_segment13,
              gl.payment_id,
              gl.cr_segment16,
              gl.dr_segment11,
              --LPV-2078 add provider specific columns
              gl.attrib_3,
              gl.attrib_4,
              gl.attrib_5,
              gl.attrib_6,
              gl.attrib_7
      INTO  l_blc_claim_gen_type.legal_entity,
            l_blc_claim_gen_type.claim_no,
            l_blc_claim_gen_type.action_type,
            l_blc_claim_gen_type.issue_date,
            l_blc_claim_gen_type.currency,
            l_blc_claim_gen_type.tech_branch,
            l_blc_claim_gen_type.policy_no,
            l_blc_claim_gen_type.depend_policy_no,
            l_blc_claim_gen_type.claim_event_date,
            l_blc_claim_gen_type.benef_party,
            l_blc_claim_gen_type.benef_party_name,
            l_blc_claim_gen_type.bank_code,
            l_blc_claim_gen_type.bank_account_code,
            l_blc_claim_gen_type.bank_account_currency,
            l_blc_claim_gen_type.office_gl_no,
            l_blc_claim_gen_type.pay_way,
            l_blc_claim_gen_type.bank_account_type,
            l_blc_claim_gen_type.pay_amount,
            l_blc_claim_gen_type.business_unit,
            l_blc_claim_gen_type.policy_class,
            l_blc_claim_gen_type.header_class,
            l_blc_claim_gen_type.payment_id,
            l_blc_claim_gen_type.ip_code,
            l_blc_claim_gen_type.doc_type,
            --LPV-2078 add provider specific columns
            l_blc_claim_gen_type.inv_doc_type,
            l_blc_claim_gen_type.inv_serial_number,
            l_blc_claim_gen_type.inv_number,
            l_blc_claim_gen_type.insured_obj,
            l_blc_claim_gen_type.type_code_wt
      FROM blc_gl_insis2gl gl
      WHERE gl.status = cust_gvar.STATUS_INITIAL
      AND gl.payment_id = pi_payment_id
      AND gl.event_code IN ('OUT001.CLM', 'OUT005.UNPP', 'OUT006.SURR', 'OUT007.UNPP',
                            'OUT008.MAT', 'OUT009.UNPP', 'OUT010.VSUR', 'OUT013.SURR',
                            'OUT014.CLM', 'OUT015.CLM', 'OUT019.CLM')
      AND EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.event_id = gl.event_id
                  AND be.attrib_9 = to_char(pi_acc_doc_id))
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          SELECT  gl.legal_entity,
                  --gl.dr_segment14, --LAP85-190
                  DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190
                  gl.dr_segment15,
                  gl.effective_date,
                  gl.op_currency,
                  gl.dr_segment16,
                  gl.attrib_0,
                  gl.attrib_2,
                  to_date(gl.dr_segment18,'dd-mm-yyyy'),
                  gl.dr_segment19,
                  gl.attrib_1,
                  gl.dr_segment22,
                  gl.dr_segment23,
                  gl.dr_segment24,
                  gl.dr_segment25,
                  gl.dr_segment26,
                  gl.dr_segment27,
                  to_number(gl.dr_segment28),
                  gl.cr_segment15,
                  gl.dr_segment12,
                  gl.dr_segment13,
                  gl.payment_id,
                  gl.cr_segment16,
                  gl.dr_segment11,
                  --LPV-2078 add provider specific columns
                  gl.attrib_3,
                  gl.attrib_4,
                  gl.attrib_5,
                  gl.attrib_6,
                  gl.attrib_7
          INTO  l_blc_claim_gen_type.legal_entity,
                l_blc_claim_gen_type.claim_no,
                l_blc_claim_gen_type.action_type,
                l_blc_claim_gen_type.issue_date,
                l_blc_claim_gen_type.currency,
                l_blc_claim_gen_type.tech_branch,
                l_blc_claim_gen_type.policy_no,
                l_blc_claim_gen_type.depend_policy_no,
                l_blc_claim_gen_type.claim_event_date,
                l_blc_claim_gen_type.benef_party,
                l_blc_claim_gen_type.benef_party_name,
                l_blc_claim_gen_type.bank_code,
                l_blc_claim_gen_type.bank_account_code,
                l_blc_claim_gen_type.bank_account_currency,
                l_blc_claim_gen_type.office_gl_no,
                l_blc_claim_gen_type.pay_way,
                l_blc_claim_gen_type.bank_account_type,
                l_blc_claim_gen_type.pay_amount,
                l_blc_claim_gen_type.business_unit,
                l_blc_claim_gen_type.policy_class,
                l_blc_claim_gen_type.header_class,
                l_blc_claim_gen_type.payment_id,
                l_blc_claim_gen_type.ip_code,
                l_blc_claim_gen_type.doc_type,
                --LPV-2078 add provider specific columns
                l_blc_claim_gen_type.inv_doc_type,
                l_blc_claim_gen_type.inv_serial_number,
                l_blc_claim_gen_type.inv_number,
                l_blc_claim_gen_type.insured_obj,
                l_blc_claim_gen_type.type_code_wt
          FROM blc_gl_insis2gl gl
          WHERE gl.status = cust_gvar.STATUS_INITIAL
          AND gl.payment_id = pi_payment_id
          AND EXISTS (SELECT 'EVENT'
                      FROM blc_sla_events be
                      WHERE be.event_id = gl.event_id
                      AND be.attrib_9 = to_char(pi_acc_doc_id))
          AND ROWNUM = 1;
    END;

    SELECT MIN(gl.dr_segment15)
    INTO l_blc_claim_gen_type.action_type
    FROM blc_gl_insis2gl gl
    WHERE gl.status = cust_gvar.STATUS_INITIAL
    AND gl.payment_id = pi_payment_id
    AND EXISTS (SELECT 'EVENT'
                FROM blc_sla_events be
                WHERE be.event_id = gl.event_id
                AND be.attrib_9 = to_char(pi_acc_doc_id));

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_claim_gen_type.id
    FROM dual;

    l_blc_claim_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_claim_gen_type.created_on := SYSDATE;
    l_blc_claim_gen_type.updated_on := SYSDATE;
    l_blc_claim_gen_type.created_by := insis_context.get_user;
    l_blc_claim_gen_type.updated_by := insis_context.get_user;
    l_blc_claim_gen_type.status := cust_gvar.STATUS_NEW;

    --calculate spayway, because there is contrsaint
    IF l_blc_claim_gen_type.pay_way = 'BANK'
    THEN
       l_blc_claim_gen_type.spayway := 'T';
    ELSIF l_blc_claim_gen_type.pay_way = 'CHECK'
    THEN
       l_blc_claim_gen_type.spayway := 'C';
    ELSE
       l_blc_claim_gen_type.spayway := 'M';
    END IF;

    INSERT INTO blc_claim_gen VALUES l_blc_claim_gen_type;
    -- End:  Insert header data

    --
    l_blc_claim_acc_type.created_on := SYSDATE;
    l_blc_claim_acc_type.updated_on := SYSDATE;
    l_blc_claim_acc_type.created_by := insis_context.get_user;
    l_blc_claim_acc_type.updated_by := insis_context.get_user;
    l_blc_claim_acc_type.status := cust_gvar.STATUS_NEW;
    --
    FOR gl_detail IN (SELECT SUM(DECODE(dr_cr_flag,'DR',amount,0)) dr_amount,
                             SUM(DECODE(dr_cr_flag,'CR',amount,0)) cr_amount,
                             currency,
                             acc_number,
                             acc_code,
                             loan_annex,
                             loan_seq,
                             MIN(gltrans_id) gltrans_id,
                             MIN(event_code) event_code
                      FROM (
                      SELECT gl.op_amount amount,
                             gl.op_currency currency,
                             gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 acc_number,
                             gl.dt_account acc_code,
                             gl.dr_segment17 loan_annex,
                             gl.dr_segment20 loan_seq,
                             gl.gltrans_id,
                             gl.event_code,
                             'DR' dr_cr_flag
                      FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                      WHERE gl.status = cust_gvar.STATUS_INITIAL
                      AND gl.payment_id = pi_payment_id
                      AND EXISTS (SELECT 'EVENT'
                                  FROM blc_sla_events be
                                  WHERE be.event_id = gl.event_id
                                  AND be.attrib_9 = to_char(pi_acc_doc_id))
                      AND gl.attrib_18 IS NULL
                      UNION ALL
                      SELECT gl.op_amount amount,
                             gl.op_currency currency,
                             gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 acc_number,
                             gl.ct_account acc_code,
                             gl.dr_segment17 loan_annex,
                             gl.dr_segment20 loan_seq,
                             gl.gltrans_id,
                             gl.event_code,
                             'CR' dr_cr_flag
                      FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                      WHERE gl.status = cust_gvar.STATUS_INITIAL
                      AND gl.payment_id = pi_payment_id
                      AND EXISTS (SELECT 'EVENT'
                                  FROM blc_sla_events be
                                  WHERE be.event_id = gl.event_id
                                  AND be.attrib_9 = to_char(pi_acc_doc_id))
                      AND gl.attrib_18 = 'R'
                      UNION ALL
                      SELECT gl.op_amount amount,
                             gl.op_currency currency,
                             gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 acc_number,
                             gl.ct_account acc_code,
                             NULL loan_annex,
                             NULL loan_seq,
                             gl.gltrans_id,
                             gl.event_code,
                             'CR' dr_cr_flag
                      FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                      WHERE gl.status = cust_gvar.STATUS_INITIAL
                      AND gl.payment_id = pi_payment_id
                      AND EXISTS (SELECT 'EVENT'
                                  FROM blc_sla_events be
                                  WHERE be.event_id = gl.event_id
                                  AND be.attrib_9 = to_char(pi_acc_doc_id))
                      AND gl.attrib_18 IS NULL
                      UNION ALL
                      SELECT gl.op_amount amount,
                             gl.op_currency currency,
                             gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 acc_number,
                             gl.dt_account acc_code,
                             NULL loan_annex,
                             NULL loan_seq,
                             gl.gltrans_id,
                             gl.event_code,
                             'DR' dr_cr_flag
                      FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                      WHERE gl.status = cust_gvar.STATUS_INITIAL
                      AND gl.payment_id = pi_payment_id
                      AND EXISTS (SELECT 'EVENT'
                                  FROM blc_sla_events be
                                  WHERE be.event_id = gl.event_id
                                  AND be.attrib_9 = to_char(pi_acc_doc_id))
                      AND gl.attrib_18 = 'R')
                      GROUP BY currency,
                               acc_number,
                               acc_code,
                               loan_annex,
                               loan_seq,
                               DECODE(event_code,'OUT017.CLM','1','OUT018.CLM','2','0') --LPV-2945
                      ORDER BY DECODE(event_code,'OUT017.CLM','1','OUT018.CLM','2','0'), --LPV-2945
                               acc_code, TO_NUMBER(loan_seq))
    LOOP
       l_blc_claim_acc_type.id := l_blc_claim_gen_type.id;
       l_blc_claim_acc_type.currency := gl_detail.currency;
       l_blc_claim_acc_type.acc_temp_code := gl_detail.event_code;
       l_blc_claim_acc_type.gltrans_id := gl_detail.gltrans_id;
       l_blc_claim_acc_type.line_number := l_count;
       l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
       l_blc_claim_acc_type.account := gl_detail.acc_number;
       l_blc_claim_acc_type.account_attribs := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.acc_code);
       l_blc_claim_acc_type.loan_number := gl_detail.loan_annex;
       l_blc_claim_acc_type.loan_seq := gl_detail.loan_seq;

       IF gl_detail.dr_amount - gl_detail.cr_amount <> 0
       THEN
          IF gl_detail.dr_amount - gl_detail.cr_amount < 0 --add on 13.01.2020 to generate credit lines
          THEN
             l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
          END IF;

          l_blc_claim_acc_type.amount := ABS(gl_detail.dr_amount - gl_detail.cr_amount);

          INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;

          l_count := l_count + 1;
       ELSE
          IF gl_detail.dr_amount <> 0
          THEN
             --insert debit line
             l_blc_claim_acc_type.amount := gl_detail.dr_amount;

             INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;

             l_count := l_count + 1;

             --insert credit line
             l_blc_claim_acc_type.amount := gl_detail.cr_amount;
             l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
             l_blc_claim_acc_type.line_number := l_count;

             INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;

             l_count := l_count + 1;
          END IF;
       END IF;
    END LOOP;
    -- End:  Insert details

    -- Update exported gl lines
    UPDATE blc_gl_insis2gl gl
    SET gl.status = cust_gvar.STATUS_TRANSFER,
        gl.operation_num = l_blc_claim_gen_type.id,
        --the next segments cannot be populated because there is not 1-1 relation
        --between inserted lines in interface table and gl lines
        --gl.cr_segment28 = l_count,
        --gl.dr_segment10 = l_dr_segment10,
        --gl.cr_segment10 = l_cr_segment10,
        gl.cr_segment18 = pi_acc_doc_id
    WHERE gl.status = cust_gvar.STATUS_INITIAL
    AND gl.payment_id = pi_payment_id
    AND EXISTS (SELECT 'EVENT'
                FROM blc_sla_events be
                WHERE be.event_id = gl.event_id
                AND be.attrib_9 = to_char(pi_acc_doc_id));

    po_header_id := l_blc_claim_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Claim_Pmnt');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Claim_Pmnt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Insert_SAP_Claim_Pmnt;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Rvrs_Claim_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      26.11.2017  Creation;
--
-- Purpose:
--    Insert record for reversing of payment into BLC_CLAIM_GEN
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pi_acc_doc_prefix      VARCHAR2     Voucher doc prefix
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Rvrs_Claim_Pmnt
   (pi_payment_id     IN     NUMBER,
    pi_acc_doc_id     IN     NUMBER,
    pi_reversed_id    IN     NUMBER,
    pi_acc_doc_prefix IN     VARCHAR2,
    po_header_id      OUT    NUMBER,
    pio_Err           IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_claim_gen_type      blc_claim_gen%ROWTYPE;
    l_payment                 BLC_PAYMENTS_TYPE;
    l_reason_descr            VARCHAR2(400 CHAR);
    --
    CURSOR c_act IS
      SELECT ba.action_date,
             substr(ba.notes,1,400), blr.lookup_code
      FROM blc_pmnt_actions ba,
           blc_lookups bl,
           blc_lookups blr
      WHERE ba.payment_id = pi_payment_id
      AND ba.action_type_id = bl.lookup_id
      AND bl.lookup_code IN (cust_gvar.ACTIVITY_REVERSE, cust_gvar.ACTIVITY_HOLD)
      AND ba.reason_id IS NOT NULL
      AND ba.reason_id = blr.lookup_id
      ORDER BY ba.action_id;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Rvrs_Claim_Pmnt';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Rvrs_Claim_Pmnt');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_payment_id = '||pi_payment_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reversed_id = '||pi_reversed_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_prefix = '||pi_acc_doc_prefix);

    l_payment := blc_payments_type(pi_payment_id, pio_Err);

    -- prepare header data for document
    l_blc_claim_gen_type.legal_entity := l_payment.legal_entity;
    l_blc_claim_gen_type.action_type := 'ANU';
    l_blc_claim_gen_type.payment_id := l_payment.payment_id;
    l_blc_claim_gen_type.ip_code := pi_acc_doc_prefix;
    l_blc_claim_gen_type.reversed_id := pi_reversed_id;

    --
    OPEN c_act;
       FETCH c_act
       INTO l_blc_claim_gen_type.reverse_date,
            l_reason_descr,
            l_blc_claim_gen_type.reverse_reason;
    CLOSE c_act;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_claim_gen_type.id
    FROM dual;

    l_blc_claim_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_claim_gen_type.created_on := SYSDATE;
    l_blc_claim_gen_type.updated_on := SYSDATE;
    l_blc_claim_gen_type.created_by := insis_context.get_user;
    l_blc_claim_gen_type.updated_by := insis_context.get_user;
    l_blc_claim_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_claim_gen VALUES l_blc_claim_gen_type;
    -- End:  Insert header data

    UPDATE blc_gl_insis2gl gl
    SET gl.status = cust_gvar.STATUS_TRANSFER,
        gl.operation_num = l_blc_claim_gen_type.id,
        gl.dr_segment15 = l_blc_claim_gen_type.action_type,
        gl.cr_segment16 = l_blc_claim_gen_type.ip_code,
        gl.effective_date = l_blc_claim_gen_type.reverse_date,
        gl.cr_segment18 = pi_acc_doc_id
    WHERE gl.status = cust_gvar.STATUS_INITIAL
    AND gl.payment_id = pi_payment_id
    --AND gl.reversed_gltrans_id IS NOT NULL;
    AND EXISTS (SELECT 'EVENT'
                FROM blc_sla_events be
                WHERE be.event_id = gl.event_id
                AND be.attrib_9 = to_char(pi_acc_doc_id));

    po_header_id := l_blc_claim_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Rvrs_Claim_Pmnt');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Rvrs_Claim_Pmnt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_payment_id = '||pi_payment_id||' - '||SQLERRM);
END Insert_SAP_Rvrs_Claim_Pmnt;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_Adj
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      29.10.2017  Creation;
-- Fadata      23.02.2021  changed LAP85-99 add ci_percent in RI
-- Fadata      01.11.2021  LAP85-190 - remove '/' from claim_no
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_Adj
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr )
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    --
    l_blc_claim_gen_type     blc_claim_gen%ROWTYPE;
    l_blc_claim_acc_type     blc_claim_acc%ROWTYPE;
    l_count                  PLS_INTEGER := 1;
    l_dr_segment10           VARCHAR2(25 CHAR);
    l_cr_segment10           VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Claim_Adj';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Insert_SAP_Claim_Adj');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_acc_doc_id = '||pi_acc_doc_id);
    --
    -- prepare header data for document
    --CO/AC
    BEGIN
        SELECT gl.legal_entity,
            gl.effective_date,
            gl.dr_segment15,
            to_date(gl.dr_segment17,'dd-mm-yyyy'),
            --gl.dr_segment14, --LAP85-190
            DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190
            gl.dr_segment16,
            gl.attrib_0,
            gl.attrib_2,
            to_date(gl.dr_segment18,'dd-mm-yyyy'),
            gl.dr_segment19,
            gl.attrib_1,
            gl.dr_segment21,
            gl.cr_segment15,
            gl.dr_segment25,
            to_number(gl.dr_segment29),
            gl.dr_segment12,
            gl.dr_segment13,
            gl.cr_segment16,
            gl.cr_segment17
        INTO l_blc_claim_gen_type.legal_entity,
            l_blc_claim_gen_type.issue_date,
            l_blc_claim_gen_type.action_type,
            l_blc_claim_gen_type.reception_date,
            l_blc_claim_gen_type.claim_no,
            l_blc_claim_gen_type.tech_branch,
            l_blc_claim_gen_type.policy_no,
            l_blc_claim_gen_type.depend_policy_no,
            l_blc_claim_gen_type.claim_event_date,
            l_blc_claim_gen_type.benef_party,
            l_blc_claim_gen_type.benef_party_name,
            l_blc_claim_gen_type.insurer_party,
            l_blc_claim_gen_type.business_unit,
            l_blc_claim_gen_type.office_gl_no,
            l_blc_claim_gen_type.ci_percent,
            l_blc_claim_gen_type.policy_class,
            l_blc_claim_gen_type.header_class,
            l_blc_claim_gen_type.ip_code,
            l_blc_claim_gen_type.object_id
        FROM blc_gl_insis2gl gl
        WHERE gl.status = cust_gvar.STATUS_INITIAL
            AND gl.event_code IN ( 'CLA001.OLR', 'CLA002.CO', 'CLA003.ACC' )
            AND EXISTS (SELECT 'EVENT'
                        FROM blc_sla_events be
                        WHERE be.event_id = gl.event_id
                           AND be.attrib_9 = to_char(pi_acc_doc_id))
            AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;

    -- Ri
    BEGIN
        SELECT gl.legal_entity,
            gl.effective_date,
            gl.dr_segment15,
            --gl.dr_segment14, --LAP85-190
            DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190,
            gl.dr_segment16,
            gl.attrib_0,
            gl.attrib_2,
            to_date(gl.dr_segment18,'dd-mm-yyyy'),
            gl.dr_segment19,
            gl.attrib_1,
            gl.dr_segment21,
            gl.cr_segment11,
            gl.dr_segment24,
            gl.cr_segment12,
            gl.cr_segment13,
            gl.insr_type,
            gl.dr_segment25,
            to_number(gl.dr_segment29),   -- add LAP85-99
            gl.dr_segment20,
            gl.dr_segment12,
            gl.dr_segment13,
            gl.cr_segment16,
            gl.cr_segment17
        INTO l_blc_claim_gen_type.legal_entity,
            l_blc_claim_gen_type.issue_date,
            l_blc_claim_gen_type.action_type,
            l_blc_claim_gen_type.claim_no,
            l_blc_claim_gen_type.tech_branch,
            l_blc_claim_gen_type.policy_no,
            l_blc_claim_gen_type.depend_policy_no,
            l_blc_claim_gen_type.claim_event_date,
            l_blc_claim_gen_type.benef_party,
            l_blc_claim_gen_type.benef_party_name,
            l_blc_claim_gen_type.insurer_party,
            l_blc_claim_gen_type.policy_currency,
            l_blc_claim_gen_type.ri_contract_type,
            l_blc_claim_gen_type.sales_channel,
            l_blc_claim_gen_type.intermed_type,
            l_blc_claim_gen_type.insr_type,
            l_blc_claim_gen_type.office_gl_no,
            l_blc_claim_gen_type.ci_percent,  -- add LAP85-99
            l_blc_claim_gen_type.ri_fac_flag,
            l_blc_claim_gen_type.policy_class,
            l_blc_claim_gen_type.header_class,
            l_blc_claim_gen_type.ip_code,
            l_blc_claim_gen_type.object_id
        FROM blc_gl_insis2gl gl
        WHERE gl.status = cust_gvar.STATUS_INITIAL
            AND gl.event_code = 'CLA004.RI'
            AND EXISTS (SELECT 'EVENT'
                        FROM blc_sla_events be
                        WHERE be.event_id = gl.event_id
                           AND be.attrib_9 = to_char(pi_acc_doc_id))
            AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;
    --
    /*
    IF l_blc_claim_gen_type.legal_entity IS NULL -- no data found
    THEN RETURN;
    END IF;
    */
    IF l_blc_claim_gen_type.legal_entity IS NULL -- no data found
    THEN
       SELECT 1
       INTO l_blc_claim_gen_type.legal_entity
       FROM dual
       WHERE 1=2;
    END IF;
    --
    SELECT blc_sap_header_seq.nextval
    INTO l_blc_claim_gen_type.id
    FROM dual;

    l_blc_claim_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_claim_gen_type.created_on := SYSDATE;
    l_blc_claim_gen_type.updated_on := SYSDATE;
    l_blc_claim_gen_type.created_by := insis_context.get_user;
    l_blc_claim_gen_type.updated_by := insis_context.get_user;
    l_blc_claim_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_claim_gen VALUES l_blc_claim_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN ( SELECT SUM(gl.op_amount) AS sum_amount,
                              gl.op_currency,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 AS dr_acc_number,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 AS cr_acc_number,
                              gl.event_code,
                              gl.dt_account,
                              gl.ct_account,
                              MAX(gl.gltrans_id) AS gltrans_id
                       FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                       WHERE gl.status = cust_gvar.STATUS_INITIAL
                           AND EXISTS (SELECT 'EVENT'
                                       FROM blc_sla_events be
                                       WHERE be.event_id = gl.event_id
                                           AND be.attrib_9 = to_char(pi_acc_doc_id))
                       GROUP BY op_currency,
                           gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                           gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                           gl.event_code,
                           gl.dt_account,
                           gl.ct_account
                       ORDER BY MAX(gl.gltrans_id) )
    LOOP
        l_blc_claim_acc_type.id := l_blc_claim_gen_type.id;
        l_blc_claim_acc_type.currency := gl_detail.op_currency;
        l_blc_claim_acc_type.amount := ABS(gl_detail.sum_amount);
        l_blc_claim_acc_type.acc_temp_code := gl_detail.event_code;
        l_blc_claim_acc_type.gltrans_id := gl_detail.gltrans_id;
        --
        l_blc_claim_acc_type.created_on := SYSDATE;
        l_blc_claim_acc_type.updated_on := SYSDATE;
        l_blc_claim_acc_type.created_by := insis_context.get_user;
        l_blc_claim_acc_type.updated_by := insis_context.get_user;
        l_blc_claim_acc_type.status := cust_gvar.STATUS_NEW;
        --
        l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
        l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
        --
        l_blc_claim_acc_type.account := gl_detail.dr_acc_number;
        l_blc_claim_acc_type.account_attribs := l_dr_segment10;

        IF gl_detail.sum_amount > 0
        THEN
            l_blc_claim_acc_type.line_number := l_count;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
        ELSE
            l_blc_claim_acc_type.line_number := l_count + 1;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
        END IF;

        INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;
        --
        l_blc_claim_acc_type.account := gl_detail.cr_acc_number;
        l_blc_claim_acc_type.account_attribs := l_cr_segment10;

        IF gl_detail.sum_amount > 0
        THEN
            l_blc_claim_acc_type.line_number := l_count + 1;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
        ELSE
            l_blc_claim_acc_type.line_number := l_count;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
        END IF;

        INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;

        UPDATE blc_gl_insis2gl gl
        SET gl.status = cust_gvar.STATUS_TRANSFER,
            gl.operation_num = l_blc_claim_gen_type.id,
            gl.cr_segment28 = l_count, --?
            gl.dr_segment10 = l_dr_segment10,
            gl.cr_segment10 = l_cr_segment10,
            gl.cr_segment18 = pi_acc_doc_id
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND EXISTS ( SELECT 'EVENT'
                     FROM blc_sla_events be
                     WHERE be.event_id = gl.event_id
                         AND be.attrib_9 = to_char(pi_acc_doc_id) )
            AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
            AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
            AND gl.op_currency = gl_detail.op_currency
            AND gl.event_code = gl_detail.event_code;
        --
        l_count := l_count + 2;
    END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_claim_gen_type.id;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Insert_SAP_Claim_Adj');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Claim_Adj', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '||SQLERRM);
END Insert_SAP_Claim_Adj;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      29.10.2017  Creation;
-- Fadata      21.10.2020  LAP85-45 add policy_no and holder for saving EXTAVINCR
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_ACCOUNT_GEN - as
--    master table and into BLC_ACCOUNT_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Account
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr )
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    --
    l_blc_account_gen_type     blc_account_gen%ROWTYPE;
    l_blc_account_acc_type     blc_account_acc%ROWTYPE;
    l_count                    PLS_INTEGER := 1;
    l_dr_segment10             VARCHAR2(25 CHAR);
    l_cr_segment10             VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Account';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Insert_SAP_Account');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_acc_doc_id = '||pi_acc_doc_id);
    --
    -- prepare header data for document
    BEGIN
        SELECT gl.legal_entity,
            gl.effective_date,
            gl.op_currency,
            gl.currency_rate,
            gl.dr_segment25,
            gl.event_code,
            gl.cr_segment16
        INTO l_blc_account_gen_type.legal_entity,
            l_blc_account_gen_type.issue_date,
            l_blc_account_gen_type.currency,
            l_blc_account_gen_type.exchange_rate,
            l_blc_account_gen_type.office_gl_no,
            l_blc_account_gen_type.acc_temp_code,
            l_blc_account_gen_type.ip_code
        FROM blc_gl_insis2gl gl
        WHERE gl.status = cust_gvar.STATUS_INITIAL
            AND EXISTS (SELECT 'EVENT'
                        FROM blc_sla_events be
                        WHERE be.event_id = gl.event_id
                           AND be.attrib_9 = to_char(pi_acc_doc_id))
            AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN;
    END;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_account_gen_type.id
    FROM dual;

    l_blc_account_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_account_gen_type.created_on := SYSDATE;
    l_blc_account_gen_type.updated_on := SYSDATE;
    l_blc_account_gen_type.created_by := insis_context.get_user;
    l_blc_account_gen_type.updated_by := insis_context.get_user;
    l_blc_account_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_account_gen VALUES l_blc_account_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN ( SELECT SUM(gl.op_amount) AS sum_amount,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 AS dr_acc_number,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 AS cr_acc_number,
                              gl.dt_account,
                              gl.ct_account,
                              gl.dr_segment16,
                              gl.cr_segment12,
                              gl.cr_segment13,
                              gl.insr_type,
                              gl.dr_segment12,
                              gl.attrib_0, -- LAP85-45
                              gl.dr_segment11, -- LAP85-45
                              MAX(gl.gltrans_id) AS gltrans_id
                       FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                       WHERE gl.status = cust_gvar.STATUS_INITIAL
                           AND EXISTS (SELECT 'EVENT'
                                       FROM blc_sla_events be
                                       WHERE be.event_id = gl.event_id
                                           AND be.attrib_9 = to_char(pi_acc_doc_id))
                       GROUP BY gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                           gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                           gl.dt_account,
                           gl.ct_account,
                           gl.dr_segment16,
                           gl.cr_segment12,
                           gl.cr_segment13,
                           gl.insr_type,
                           gl.dr_segment12,
                           gl.attrib_0, -- LAP85-45
                           gl.dr_segment11 -- LAP85-45
                       ORDER BY MAX(gl.gltrans_id) )
    LOOP
        l_blc_account_acc_type.id := l_blc_account_gen_type.id;
        l_blc_account_acc_type.amount := ABS(gl_detail.sum_amount);
        l_blc_account_acc_type.gltrans_id := gl_detail.gltrans_id;
        --
        l_blc_account_acc_type.tech_branch := gl_detail.dr_segment16;
        l_blc_account_acc_type.sales_channel := gl_detail.cr_segment12;
        l_blc_account_acc_type.intermed_type := gl_detail.cr_segment13;
        l_blc_account_acc_type.insr_type := gl_detail.insr_type;
        l_blc_account_acc_type.policy_class := gl_detail.dr_segment12;
        --
        -- Begin LAP85-45
        l_blc_account_acc_type.policy_no := gl_detail.attrib_0;
        l_blc_account_acc_type.line_party := gl_detail.dr_segment11;
        -- End LAP85-45
        --
        l_blc_account_acc_type.created_on := SYSDATE;
        l_blc_account_acc_type.updated_on := SYSDATE;
        l_blc_account_acc_type.created_by := insis_context.get_user;
        l_blc_account_acc_type.updated_by := insis_context.get_user;
        l_blc_account_acc_type.status := cust_gvar.STATUS_NEW;
        --
        l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
        l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
        --
        l_blc_account_acc_type.account := gl_detail.dr_acc_number;
        l_blc_account_acc_type.account_attribs := l_dr_segment10;

        IF gl_detail.sum_amount > 0
        THEN
            l_blc_account_acc_type.line_number := l_count;
            l_blc_account_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
        ELSE
            l_blc_account_acc_type.line_number := l_count + 1;
            l_blc_account_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
        END IF;

        INSERT INTO blc_account_acc VALUES l_blc_account_acc_type;
        --
        l_blc_account_acc_type.account := gl_detail.cr_acc_number;
        l_blc_account_acc_type.account_attribs := l_cr_segment10;

        IF gl_detail.sum_amount > 0
        THEN
            l_blc_account_acc_type.line_number := l_count + 1;
            l_blc_account_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
        ELSE
            l_blc_account_acc_type.line_number := l_count;
            l_blc_account_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
        END IF;

        INSERT INTO blc_account_acc VALUES l_blc_account_acc_type;

        UPDATE blc_gl_insis2gl gl
        SET gl.status = cust_gvar.STATUS_TRANSFER,
            gl.operation_num = l_blc_account_gen_type.id,
            gl.cr_segment28 = l_count, --?
            gl.dr_segment10 = l_dr_segment10,
            gl.cr_segment10 = l_cr_segment10,
            gl.cr_segment18 = pi_acc_doc_id
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND EXISTS ( SELECT 'EVENT'
                     FROM blc_sla_events be
                     WHERE be.event_id = gl.event_id
                         AND be.attrib_9 = to_char(pi_acc_doc_id) )
            AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
            AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
            AND nvl(gl.dr_segment16,'-999') = nvl(gl_detail.dr_segment16,'-999')
            AND nvl(gl.cr_segment12,'-999') = nvl(gl_detail.cr_segment12,'-999')
            AND nvl(gl.cr_segment13,'-999') = nvl(gl_detail.cr_segment13,'-999')
            AND nvl(gl.insr_type,'-999') = nvl(gl_detail.insr_type,'-999')
            AND nvl(gl.dr_segment12,'-999') = nvl(gl_detail.dr_segment12,'-999')
            AND nvl(gl.attrib_0,'-999') = nvl(gl_detail.attrib_0,'-999')  -- LAP85-45
            AND nvl(gl.dr_segment11,'-999') = nvl(gl_detail.dr_segment11,'-999');  -- LAP85-45
        --
        l_count := l_count + 2;
    END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_account_gen_type.id;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Insert_SAP_Account');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Account', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '||SQLERRM);
END Insert_SAP_Account;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Prem_AC
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      27.10.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given doc_id
--    are selected, grouped and summed into tables BLC_PROFORMA_GEN - as
--    master table and into BLC_PROFORMA_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Prem_AC
   (pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_proforma_gen_type   blc_proforma_gen%ROWTYPE;
    l_blc_proforma_acc_type   blc_proforma_acc%ROWTYPE;
    l_count                   PLS_INTEGER := 1;
    l_dr_segment10            VARCHAR2(25 CHAR);
    l_cr_segment10            VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Prem_AC';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Prem_AC');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);

    -- prepare header data for document
    BEGIN
      SELECT  gl.legal_entity,
              gl.dr_segment15,
              gl.effective_date,
              gl.op_currency,
              gl.dr_segment16,
              gl.attrib_0,
              to_date(gl.dr_segment17,'dd-mm-yyyy'),
              to_date(gl.dr_segment18,'dd-mm-yyyy'),
              gl.dr_segment19,
              gl.attrib_2,
              gl.dr_segment20,
              gl.dr_segment21,
              to_date(gl.dr_segment22,'dd-mm-yyyy'),
              gl.dr_segment25,
              gl.insr_type,
              gl.attrib_1,
              gl.dr_segment27,
              to_number(gl.dr_segment28),
              to_number(gl.dr_segment29),
              gl.cr_segment12,
              gl.cr_segment13,
              gl.cr_segment15,
              gl.dr_segment12,
              gl.dr_segment13,
              gl.policy_id,
              gl.cr_segment16
              --gl.cr_segment17
      INTO  l_blc_proforma_gen_type.legal_entity,
            l_blc_proforma_gen_type.action_type,
            l_blc_proforma_gen_type.doc_issue_date,
            l_blc_proforma_gen_type.currency,
            l_blc_proforma_gen_type.tech_branch,
            l_blc_proforma_gen_type.policy_no,
            l_blc_proforma_gen_type.doc_start_date,
            l_blc_proforma_gen_type.doc_end_date,
            l_blc_proforma_gen_type.doc_party,
            l_blc_proforma_gen_type.depend_policy_no,
            l_blc_proforma_gen_type.leader_policy_no,
            l_blc_proforma_gen_type.ref_doc_number,
            l_blc_proforma_gen_type.ref_doc_date,
            l_blc_proforma_gen_type.office_gl_no,
            l_blc_proforma_gen_type.insr_type,
            l_blc_proforma_gen_type.pol_end_party_name,
            l_blc_proforma_gen_type.pol_end_party,
            l_blc_proforma_gen_type.doc_prem_amount,
            l_blc_proforma_gen_type.ci_percent,
            l_blc_proforma_gen_type.sales_channel,
            l_blc_proforma_gen_type.intermed_type,
            l_blc_proforma_gen_type.business_unit,
            l_blc_proforma_gen_type.policy_class,
            l_blc_proforma_gen_type.header_class,
            l_blc_proforma_gen_type.doc_id,
            l_blc_proforma_gen_type.ip_code
            --l_blc_proforma_gen_type.priority
      FROM blc_gl_insis2gl gl
      WHERE gl.status = cust_gvar.STATUS_INITIAL
      AND EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.event_id = gl.event_id
                  AND be.attrib_9 = to_char(pi_acc_doc_id))
      AND ROWNUM = 1;
    END;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_proforma_gen_type.id
    FROM dual;

    l_blc_proforma_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_proforma_gen_type.created_on := SYSDATE;
    l_blc_proforma_gen_type.updated_on := SYSDATE;
    l_blc_proforma_gen_type.created_by := insis_context.get_user;
    l_blc_proforma_gen_type.updated_by := insis_context.get_user;
    l_blc_proforma_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_proforma_gen VALUES l_blc_proforma_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN (SELECT SUM(gl.op_amount) sum_amount,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 dr_acc_number,
                              gl.dr_segment6,
                              gl.dr_segment7, --03.07.2019 --Phase 2
                              gl.dr_segment9,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 cr_acc_number,
                              gl.event_code,
                              gl.dt_account,
                              gl.ct_account,
                              MAX(gl.gltrans_id) gltrans_id
                        FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                        WHERE gl.status = cust_gvar.STATUS_INITIAL
                        AND EXISTS (SELECT 'EVENT'
                                    FROM blc_sla_events be
                                    WHERE be.event_id = gl.event_id
                                    AND be.attrib_9 = to_char(pi_acc_doc_id))
                        GROUP BY gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                                 gl.dr_segment6,
                                 gl.dr_segment7, --03.07.2019 --Phase 2
                                 gl.dr_segment9,
                                 gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                                 gl.event_code,
                                 gl.dt_account,
                                 gl.ct_account
                         ORDER BY MAX(gl.gltrans_id))
       LOOP
          l_blc_proforma_acc_type.id := l_blc_proforma_gen_type.id;
          l_blc_proforma_acc_type.amount := gl_detail.sum_amount;
          l_blc_proforma_acc_type.acc_temp_code := gl_detail.event_code;
          l_blc_proforma_acc_type.gltrans_id := gl_detail.gltrans_id;
          l_blc_proforma_acc_type.line_party := gl_detail.dr_segment6;
          l_blc_proforma_acc_type.comm_ci_percent := to_number(gl_detail.dr_segment9);
          --
          l_blc_proforma_acc_type.created_on := SYSDATE;
          l_blc_proforma_acc_type.updated_on := SYSDATE;
          l_blc_proforma_acc_type.created_by := insis_context.get_user;
          l_blc_proforma_acc_type.updated_by := insis_context.get_user;
          l_blc_proforma_acc_type.status := cust_gvar.STATUS_NEW;
          --
          l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
          l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
          --
          l_blc_proforma_acc_type.account := gl_detail.dr_acc_number;
          l_blc_proforma_acc_type.account_attribs := l_dr_segment10;

          l_blc_proforma_acc_type.line_number := l_count;
          l_blc_proforma_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;

          INSERT INTO blc_proforma_acc VALUES l_blc_proforma_acc_type;

          --
          l_blc_proforma_acc_type.account := gl_detail.cr_acc_number;
          l_blc_proforma_acc_type.account_attribs := l_cr_segment10;

          l_blc_proforma_acc_type.line_number := l_count + 1;
          l_blc_proforma_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;

          INSERT INTO blc_proforma_acc VALUES l_blc_proforma_acc_type;

          UPDATE blc_gl_insis2gl gl
          SET gl.status = cust_gvar.STATUS_TRANSFER,
              gl.operation_num = l_blc_proforma_gen_type.id,
              gl.cr_segment28 = l_count,
              gl.dr_segment10 = l_dr_segment10,
              gl.cr_segment10 = l_cr_segment10,
              gl.cr_segment18 = pi_acc_doc_id
          WHERE gl.status = cust_gvar.STATUS_INITIAL
          AND EXISTS (SELECT 'EVENT'
                      FROM blc_sla_events be
                      WHERE be.event_id = gl.event_id
                      AND be.attrib_9 = to_char(pi_acc_doc_id))
          AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
          AND nvl(gl.dr_segment6,'-999') = nvl(gl_detail.dr_segment6,'-999')
          AND nvl(gl.dr_segment7,'-999') = nvl(gl_detail.dr_segment7,'-999') --03.07.2019 --Phase 2
          AND nvl(gl.dr_segment9,'-999') = nvl(gl_detail.dr_segment9,'-999')
          AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
          AND gl.event_code = gl_detail.event_code;

          l_count := l_count + 2;
       END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_proforma_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Prem_AC');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Prem_AC', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_acc_doc_id = '||pi_acc_doc_id||' - '||SQLERRM);
END Insert_SAP_Prem_AC;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_AC
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      10.12.2017  Creation;
-- Fadata      01.11.2021  LAP85-190 - remove '/' from claim_no
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_AC
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr )
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    --
    l_blc_claim_gen_type     blc_claim_gen%ROWTYPE;
    l_blc_claim_acc_type     blc_claim_acc%ROWTYPE;
    l_count                  PLS_INTEGER := 1;
    l_dr_segment10           VARCHAR2(25 CHAR);
    l_cr_segment10           VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Claim_Adj';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Insert_SAP_Claim_AC');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_acc_doc_id = '||pi_acc_doc_id);
    --
    -- prepare header data for document
    BEGIN
     SELECT gl.legal_entity,
            gl.effective_date,
            gl.dr_segment15,
            to_date(gl.dr_segment17,'dd-mm-yyyy'),
            --gl.dr_segment14, --LAP85-190
            DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190,
            gl.dr_segment16,
            gl.attrib_0,
            gl.attrib_2,
            to_date(gl.dr_segment18,'dd-mm-yyyy'),
            gl.dr_segment19,
            gl.attrib_1,
            gl.dr_segment21,
            gl.cr_segment15,
            gl.dr_segment25,
            to_number(gl.dr_segment29),
            gl.dr_segment12,
            gl.dr_segment13,
            gl.cr_segment16,
            gl.cr_segment17
       INTO l_blc_claim_gen_type.legal_entity,
            l_blc_claim_gen_type.issue_date,
            l_blc_claim_gen_type.action_type,
            l_blc_claim_gen_type.reception_date,
            l_blc_claim_gen_type.claim_no,
            l_blc_claim_gen_type.tech_branch,
            l_blc_claim_gen_type.policy_no,
            l_blc_claim_gen_type.depend_policy_no,
            l_blc_claim_gen_type.claim_event_date,
            l_blc_claim_gen_type.benef_party,
            l_blc_claim_gen_type.benef_party_name,
            l_blc_claim_gen_type.insurer_party,
            l_blc_claim_gen_type.business_unit,
            l_blc_claim_gen_type.office_gl_no,
            l_blc_claim_gen_type.ci_percent,
            l_blc_claim_gen_type.policy_class,
            l_blc_claim_gen_type.header_class,
            l_blc_claim_gen_type.ip_code,
            l_blc_claim_gen_type.object_id
        FROM blc_gl_insis2gl gl
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND EXISTS (SELECT 'EVENT'
                    FROM blc_sla_events be
                    WHERE be.event_id = gl.event_id
                    AND be.attrib_9 = to_char(pi_acc_doc_id))
        AND ROWNUM = 1;
    END;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_claim_gen_type.id
    FROM dual;

    l_blc_claim_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_claim_gen_type.created_on := SYSDATE;
    l_blc_claim_gen_type.updated_on := SYSDATE;
    l_blc_claim_gen_type.created_by := insis_context.get_user;
    l_blc_claim_gen_type.updated_by := insis_context.get_user;
    l_blc_claim_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_claim_gen VALUES l_blc_claim_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN ( SELECT SUM(gl.op_amount) AS sum_amount,
                              gl.op_currency,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 AS dr_acc_number,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 AS cr_acc_number,
                              gl.event_code,
                              gl.dt_account,
                              gl.ct_account,
                              MAX(gl.gltrans_id) AS gltrans_id
                       FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                       WHERE gl.status = cust_gvar.STATUS_INITIAL
                           AND EXISTS (SELECT 'EVENT'
                                       FROM blc_sla_events be
                                       WHERE be.event_id = gl.event_id
                                           AND be.attrib_9 = to_char(pi_acc_doc_id))
                       GROUP BY op_currency,
                           gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                           gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                           gl.event_code,
                           gl.dt_account,
                           gl.ct_account
                       ORDER BY MAX(gl.gltrans_id) )
    LOOP
        l_blc_claim_acc_type.id := l_blc_claim_gen_type.id;
        l_blc_claim_acc_type.currency := gl_detail.op_currency;
        l_blc_claim_acc_type.amount := ABS(gl_detail.sum_amount);
        l_blc_claim_acc_type.acc_temp_code := gl_detail.event_code;
        l_blc_claim_acc_type.gltrans_id := gl_detail.gltrans_id;
        --
        l_blc_claim_acc_type.created_on := SYSDATE;
        l_blc_claim_acc_type.updated_on := SYSDATE;
        l_blc_claim_acc_type.created_by := insis_context.get_user;
        l_blc_claim_acc_type.updated_by := insis_context.get_user;
        l_blc_claim_acc_type.status := cust_gvar.STATUS_NEW;
        --
        l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
        l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
        --
        l_blc_claim_acc_type.account := gl_detail.dr_acc_number;
        l_blc_claim_acc_type.account_attribs := l_dr_segment10;

        l_blc_claim_acc_type.line_number := l_count;
        l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;

        INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;
        --
        l_blc_claim_acc_type.account := gl_detail.cr_acc_number;
        l_blc_claim_acc_type.account_attribs := l_cr_segment10;

        l_blc_claim_acc_type.line_number := l_count + 1;
        l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;

        INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;

        --
        UPDATE blc_gl_insis2gl gl
        SET gl.status = cust_gvar.STATUS_TRANSFER,
            gl.operation_num = l_blc_claim_gen_type.id,
            gl.cr_segment28 = l_count, --?
            gl.dr_segment10 = l_dr_segment10,
            gl.cr_segment10 = l_cr_segment10,
            gl.cr_segment18 = pi_acc_doc_id
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND EXISTS ( SELECT 'EVENT'
                     FROM blc_sla_events be
                     WHERE be.event_id = gl.event_id
                     AND be.attrib_9 = to_char(pi_acc_doc_id) )
        AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
        AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
        AND gl.op_currency = gl_detail.op_currency
        AND gl.event_code = gl_detail.event_code;
        --
        l_count := l_count + 2;
    END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_claim_gen_type.id;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Insert_SAP_Claim_AC');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Claim_AC', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '||SQLERRM);
END Insert_SAP_Claim_AC;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_Clr_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      19.12.2017  Creation;
-- Fadata      23.02.2021  changed LAP85-99 add ci_percent
-- Fadata      01.11.2021  LAP85-190 - remove '/' from claim_no
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_Clr_Pmnt
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr )
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    --
    l_blc_claim_gen_type     blc_claim_gen%ROWTYPE;
    l_blc_claim_acc_type     blc_claim_acc%ROWTYPE;
    l_count                  PLS_INTEGER := 1;
    l_dr_segment10           VARCHAR2(25 CHAR);
    l_cr_segment10           VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Claim_Clr_Pmnt';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Insert_SAP_Claim_Clr_Pmnt');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_acc_doc_id = '||pi_acc_doc_id);
    --
    -- prepare header data for document
    -- CO
    BEGIN
        SELECT gl.legal_entity,
            gl.effective_date,
            gl.dr_segment15,
            --gl.dr_segment14, --LAP85-190
            DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190,
            gl.dr_segment16,
            gl.attrib_0,
            gl.attrib_2,
            to_date(gl.dr_segment18,'dd-mm-yyyy'),
            gl.dr_segment19,
            gl.attrib_1,
            gl.dr_segment21,
            gl.cr_segment15,
            gl.insr_type,
            gl.dr_segment25,
            to_number(gl.dr_segment29),  -- add LAP85-99
            gl.dr_segment12,
            gl.dr_segment13,
            gl.cr_segment16,
            gl.cr_segment17,
            TO_NUMBER(gl.cr_segment17)
        INTO l_blc_claim_gen_type.legal_entity,
            l_blc_claim_gen_type.issue_date,
            l_blc_claim_gen_type.action_type,
            l_blc_claim_gen_type.claim_no,
            l_blc_claim_gen_type.tech_branch,
            l_blc_claim_gen_type.policy_no,
            l_blc_claim_gen_type.depend_policy_no,
            l_blc_claim_gen_type.claim_event_date,
            l_blc_claim_gen_type.benef_party,
            l_blc_claim_gen_type.benef_party_name,
            l_blc_claim_gen_type.insurer_party,
            l_blc_claim_gen_type.business_unit,
            l_blc_claim_gen_type.insr_type,
            l_blc_claim_gen_type.office_gl_no,
            l_blc_claim_gen_type.ci_percent,  -- add LAP85-99
            l_blc_claim_gen_type.policy_class,
            l_blc_claim_gen_type.header_class,
            l_blc_claim_gen_type.ip_code,
            l_blc_claim_gen_type.object_id,
            l_blc_claim_gen_type.clearing_id
        FROM blc_gl_insis2gl gl
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND gl.event_code = 'OUT002.CO'
        AND EXISTS (SELECT 'EVENT'
                    FROM blc_sla_events be
                    WHERE be.event_id = gl.event_id
                    AND be.attrib_9 = to_char(pi_acc_doc_id))
       AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;

    -- Ri
    BEGIN
        SELECT gl.legal_entity,
            gl.effective_date,
            gl.dr_segment15,
            --gl.dr_segment14, --LAP85-190
            DECODE(INSTR(gl.dr_segment14,'/'), 0, gl.dr_segment14, SUBSTR(gl.dr_segment14, 1, INSTR(gl.dr_segment14,'/')-1)), --LAP85-190,
            gl.dr_segment16,
            gl.attrib_0,
            gl.attrib_2,
            to_date(gl.dr_segment18,'dd-mm-yyyy'),
            gl.dr_segment19,
            gl.attrib_1,
            gl.dr_segment21,
            gl.cr_segment11,
            gl.dr_segment24,
            gl.cr_segment12,
            gl.cr_segment13,
            gl.insr_type,
            gl.dr_segment25,
            to_number(gl.dr_segment29),  -- add LAP85-99
            gl.dr_segment20,
            gl.dr_segment12,
            gl.dr_segment13,
            gl.cr_segment16,
            gl.cr_segment17,
            to_number(gl.cr_segment17)
        INTO l_blc_claim_gen_type.legal_entity,
            l_blc_claim_gen_type.issue_date,
            l_blc_claim_gen_type.action_type,
            l_blc_claim_gen_type.claim_no,
            l_blc_claim_gen_type.tech_branch,
            l_blc_claim_gen_type.policy_no,
            l_blc_claim_gen_type.depend_policy_no,
            l_blc_claim_gen_type.claim_event_date,
            l_blc_claim_gen_type.benef_party,
            l_blc_claim_gen_type.benef_party_name,
            l_blc_claim_gen_type.insurer_party,
            l_blc_claim_gen_type.policy_currency,
            l_blc_claim_gen_type.ri_contract_type,
            l_blc_claim_gen_type.sales_channel,
            l_blc_claim_gen_type.intermed_type,
            l_blc_claim_gen_type.insr_type,
            l_blc_claim_gen_type.office_gl_no,
            l_blc_claim_gen_type.ci_percent,  -- add LAP85-99
            l_blc_claim_gen_type.ri_fac_flag,
            l_blc_claim_gen_type.policy_class,
            l_blc_claim_gen_type.header_class,
            l_blc_claim_gen_type.ip_code,
            l_blc_claim_gen_type.object_id,
            l_blc_claim_gen_type.clearing_id
        FROM blc_gl_insis2gl gl
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND gl.event_code = 'OUT004.RI'
        AND EXISTS (SELECT 'EVENT'
                    FROM blc_sla_events be
                    WHERE be.event_id = gl.event_id
                    AND be.attrib_9 = to_char(pi_acc_doc_id))
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;
    --
    IF l_blc_claim_gen_type.legal_entity IS NULL -- no data found
    THEN
       SELECT 1
       INTO l_blc_claim_gen_type.legal_entity
       FROM dual
       WHERE 1=2;
    END IF;
    --
    SELECT blc_sap_header_seq.nextval
    INTO l_blc_claim_gen_type.id
    FROM dual;

    l_blc_claim_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_claim_gen_type.created_on := SYSDATE;
    l_blc_claim_gen_type.updated_on := SYSDATE;
    l_blc_claim_gen_type.created_by := insis_context.get_user;
    l_blc_claim_gen_type.updated_by := insis_context.get_user;
    l_blc_claim_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_claim_gen VALUES l_blc_claim_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN ( SELECT SUM(gl.op_amount) AS sum_amount,
                              gl.op_currency,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 AS dr_acc_number,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 AS cr_acc_number,
                              gl.event_code,
                              gl.dt_account,
                              gl.ct_account,
                              MAX(gl.gltrans_id) AS gltrans_id
                       FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                       WHERE gl.status = cust_gvar.STATUS_INITIAL
                       AND EXISTS (SELECT 'EVENT'
                                   FROM blc_sla_events be
                                   WHERE be.event_id = gl.event_id
                                   AND be.attrib_9 = to_char(pi_acc_doc_id))
                       GROUP BY op_currency,
                           gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                           gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                           gl.event_code,
                           gl.dt_account,
                           gl.ct_account
                       ORDER BY MAX(gl.gltrans_id) )
    LOOP
        l_blc_claim_acc_type.id := l_blc_claim_gen_type.id;
        l_blc_claim_acc_type.currency := gl_detail.op_currency;
        l_blc_claim_acc_type.amount := ABS(gl_detail.sum_amount);
        l_blc_claim_acc_type.acc_temp_code := gl_detail.event_code;
        l_blc_claim_acc_type.gltrans_id := gl_detail.gltrans_id;
        --
        l_blc_claim_acc_type.created_on := SYSDATE;
        l_blc_claim_acc_type.updated_on := SYSDATE;
        l_blc_claim_acc_type.created_by := insis_context.get_user;
        l_blc_claim_acc_type.updated_by := insis_context.get_user;
        l_blc_claim_acc_type.status := cust_gvar.STATUS_NEW;
        --
        l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
        l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
        --
        l_blc_claim_acc_type.account := gl_detail.dr_acc_number;
        l_blc_claim_acc_type.account_attribs := l_dr_segment10;

        IF gl_detail.sum_amount > 0
        THEN
            l_blc_claim_acc_type.line_number := l_count;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
        ELSE
            l_blc_claim_acc_type.line_number := l_count + 1;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
        END IF;

        INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;
        --
        l_blc_claim_acc_type.account := gl_detail.cr_acc_number;
        l_blc_claim_acc_type.account_attribs := l_cr_segment10;

        IF gl_detail.sum_amount > 0
        THEN
            l_blc_claim_acc_type.line_number := l_count + 1;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
        ELSE
            l_blc_claim_acc_type.line_number := l_count;
            l_blc_claim_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
        END IF;

        INSERT INTO blc_claim_acc VALUES l_blc_claim_acc_type;

        UPDATE blc_gl_insis2gl gl
        SET gl.status = cust_gvar.STATUS_TRANSFER,
            gl.operation_num = l_blc_claim_gen_type.id,
            gl.cr_segment28 = l_count, --?
            gl.dr_segment10 = l_dr_segment10,
            gl.cr_segment10 = l_cr_segment10,
            gl.cr_segment18 = pi_acc_doc_id
        WHERE gl.status = cust_gvar.STATUS_INITIAL
        AND EXISTS ( SELECT 'EVENT'
                     FROM blc_sla_events be
                     WHERE be.event_id = gl.event_id
                     AND be.attrib_9 = to_char(pi_acc_doc_id) )
        AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
        AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
        AND gl.op_currency = gl_detail.op_currency
        AND gl.event_code = gl_detail.event_code;
        --
        l_count := l_count + 2;
    END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_claim_gen_type.id;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Insert_SAP_Claim_Adj');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Claim_Clr_Pmnt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'pi_acc_doc_id = '||pi_acc_doc_id||' - '||SQLERRM);
END Insert_SAP_Claim_Clr_Pmnt;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Unclear_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      19.12.2017  Creation;
--
-- Purpose:
--    Insert record for reversing of clearing into BLC_CLAIM_GEN
--
-- Input parameters:
--     pi_clearing_id         NUMBER       Clearing Id
--     pi_payment_id          NUMBER       Payment Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Unclear_Pmnt
   (pi_clearing_id   IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    pi_reversed_id   IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_claim_gen_type      blc_claim_gen%ROWTYPE;
    l_payment                 BLC_PAYMENTS_TYPE;
    l_reason_descr            VARCHAR2(400 CHAR);
    l_unclearing_id           NUMBER;
    l_uncleared_on            DATE;
    l_legal_entity_id         NUMBER;
    l_payment_id              NUMBER;
    l_reverse_date            DATE;
    --
    CURSOR c_act IS
      SELECT ba.action_date,
             substr(ba.notes,1,400), blr.lookup_code
      FROM blc_pmnt_actions ba,
           blc_lookups bl,
           blc_lookups blr
      WHERE ba.payment_id = l_payment_id
      AND ba.action_type_id = bl.lookup_id
      AND bl.lookup_code IN (cust_gvar.ACTIVITY_UNCLEAR)
      AND ba.reason_id IS NOT NULL
      AND ba.reason_id = blr.lookup_id
      ORDER BY ba.action_id;
    --
    CURSOR c_clear IS
      SELECT bc.clearing_id, bc.cleared_on,
             bp.payment_id, bp.legal_entity
      FROM blc_clearings bc,
           blc_payments bp
      WHERE bc.uncleared = pi_clearing_id
      AND bc.payment_id = bp.payment_id;
    --
    CURSOR c_insr_party IS  -- Added on 27.06.2018 - LPV-1648
      SELECT attrib_2
      FROM blc_documents
      WHERE doc_id = pi_acc_doc_id;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Unclear_Pmnt';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Unclear_Pmnt');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_clearing_id = '||pi_clearing_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reversed_id = '||pi_reversed_id);

    OPEN c_clear;
      FETCH c_clear
      INTO l_unclearing_id, l_uncleared_on,
           l_payment_id, l_legal_entity_id;
    CLOSE c_clear;

    -- prepare header data for document
    l_blc_claim_gen_type.legal_entity := l_legal_entity_id;
    l_blc_claim_gen_type.action_type := 'ANU';
    l_blc_claim_gen_type.clearing_id := pi_clearing_id;
    l_blc_claim_gen_type.unclearing_id := l_unclearing_id;
    l_blc_claim_gen_type.ip_code := 'I013';
    l_blc_claim_gen_type.reversed_id := pi_reversed_id;
    l_blc_claim_gen_type.reverse_date := l_uncleared_on;
    --
    OPEN c_insr_party; -- Added on 27.06.2018 - LPV-1648
      FETCH c_insr_party
      INTO l_blc_claim_gen_type.insurer_party;
    CLOSE c_insr_party;
    --
    OPEN c_act;
       FETCH c_act
       INTO l_reverse_date,
            l_reason_descr,
            l_blc_claim_gen_type.reverse_reason;
    CLOSE c_act;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_claim_gen_type.id
    FROM dual;

    l_blc_claim_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_claim_gen_type.created_on := SYSDATE;
    l_blc_claim_gen_type.updated_on := SYSDATE;
    l_blc_claim_gen_type.created_by := insis_context.get_user;
    l_blc_claim_gen_type.updated_by := insis_context.get_user;
    l_blc_claim_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_claim_gen VALUES l_blc_claim_gen_type;
    -- End:  Insert header data

    UPDATE blc_gl_insis2gl gl
    SET gl.status = cust_gvar.STATUS_TRANSFER,
        gl.operation_num = l_blc_claim_gen_type.id,
        gl.dr_segment15 = l_blc_claim_gen_type.action_type,
        gl.cr_segment16 = l_blc_claim_gen_type.ip_code,
        gl.effective_date = l_blc_claim_gen_type.reverse_date,
        gl.cr_segment17 = l_unclearing_id,
        gl.cr_segment18 = pi_acc_doc_id
    WHERE gl.status = cust_gvar.STATUS_INITIAL
    AND EXISTS (SELECT 'EVENT'
                FROM blc_sla_events be
                WHERE be.event_id = gl.event_id
                AND be.attrib_9 = to_char(pi_acc_doc_id));

    po_header_id := l_blc_claim_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_clearing_id = '||pi_clearing_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Unclear_Pmnt');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Unclear_Pmnt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_clearing_id = '||pi_clearing_id||' - '||SQLERRM);
END Insert_SAP_Unclear_Pmnt;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_RI_Bill
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      02.01.2018  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given doc_id
--    are selected, grouped and summed into tables BLC_REI_GEN - as
--    master table and into BLC_REI_ACC - as detailed.
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_RI_Bill
   (pi_doc_id        IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_rei_gen_type        blc_rei_gen%ROWTYPE;
    l_blc_rei_acc_type        blc_rei_acc%ROWTYPE;
    l_count                   PLS_INTEGER := 1;
    l_dr_segment10            VARCHAR2(25 CHAR);
    l_cr_segment10            VARCHAR2(25 CHAR);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_RI_Bill';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_RI_Bill');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);

    -- prepare header data for document
    BEGIN
      SELECT  gl.legal_entity,
              gl.doc_id,
              gl.dr_segment15,
              gl.dr_segment20,
              gl.dr_segment24,
              gl.dr_segment25,
              gl.attrib_1,
              gl.dr_segment21,
              gl.op_currency,
              gl.dr_segment28,
              gl.effective_date,
              gl.dr_segment14,
              gl.dr_segment13
      INTO  l_blc_rei_gen_type.legal_entity,
            l_blc_rei_gen_type.doc_id,
            l_blc_rei_gen_type.action_type,
            l_blc_rei_gen_type.ri_fac_flag,
            l_blc_rei_gen_type.ri_contract_type,
            l_blc_rei_gen_type.office_gl_no,
            l_blc_rei_gen_type.insurer_party_name,
            l_blc_rei_gen_type.insurer_party,
            l_blc_rei_gen_type.currency,
            l_blc_rei_gen_type.reinsurer_type,
            l_blc_rei_gen_type.doc_issue_date,
            l_blc_rei_gen_type.doc_number,
            l_blc_rei_gen_type.header_class
      FROM blc_gl_insis2gl gl
      WHERE gl.status = cust_gvar.STATUS_INITIAL
      AND gl.doc_id = pi_doc_id
      AND gl.event_code = 'BLC009.PREM'
      --AND gl.reversed_gltrans_id IS NULL
      AND EXISTS (SELECT 'EVENT'
                  FROM blc_sla_events be
                  WHERE be.event_id = gl.event_id
                  AND be.attrib_9 = to_char(pi_acc_doc_id))
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          SELECT  gl.legal_entity,
                  gl.doc_id,
                  gl.dr_segment15,
                  gl.dr_segment20,
                  gl.dr_segment24,
                  gl.dr_segment25,
                  gl.attrib_1,
                  gl.dr_segment21,
                  gl.op_currency,
                  gl.dr_segment28,
                  gl.effective_date,
                  gl.dr_segment14,
                  gl.dr_segment13
          INTO  l_blc_rei_gen_type.legal_entity,
                l_blc_rei_gen_type.doc_id,
                l_blc_rei_gen_type.action_type,
                l_blc_rei_gen_type.ri_fac_flag,
                l_blc_rei_gen_type.ri_contract_type,
                l_blc_rei_gen_type.office_gl_no,
                l_blc_rei_gen_type.insurer_party_name,
                l_blc_rei_gen_type.insurer_party,
                l_blc_rei_gen_type.currency,
                l_blc_rei_gen_type.reinsurer_type,
                l_blc_rei_gen_type.doc_issue_date,
                l_blc_rei_gen_type.doc_number,
                l_blc_rei_gen_type.header_class
          FROM blc_gl_insis2gl gl
          WHERE gl.status = cust_gvar.STATUS_INITIAL
          AND gl.doc_id = pi_doc_id
          --AND gl.reversed_gltrans_id IS NULL
          AND EXISTS (SELECT 'EVENT'
                      FROM blc_sla_events be
                      WHERE be.event_id = gl.event_id
                      AND be.attrib_9 = to_char(pi_acc_doc_id))
          AND ROWNUM = 1;
    END;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_rei_gen_type.id
    FROM dual;

    l_blc_rei_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_rei_gen_type.created_on := SYSDATE;
    l_blc_rei_gen_type.updated_on := SYSDATE;
    l_blc_rei_gen_type.created_by := insis_context.get_user;
    l_blc_rei_gen_type.updated_by := insis_context.get_user;
    l_blc_rei_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_rei_gen VALUES l_blc_rei_gen_type;
    -- End:  Insert header data

    -- Insert lines
    FOR gl_detail IN (SELECT SUM(gl.op_amount) sum_amount,
                             SUM(gl.amount) sum_fc_amount,
                              gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 dr_acc_number,
                              gl.dr_segment12,
                              gl.dr_segment16,
                              gl.attrib_0,
                              to_date(gl.dr_segment22,'dd-mm-yyyy') policy_start_date,
                              gl.dr_segment19,
                              gl.dr_segment27,
                              gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 cr_acc_number,
                              gl.cr_segment11,
                              gl.cr_segment12,
                              gl.cr_segment13,
                              gl.insr_type,
                              gl.event_code,
                              gl.dt_account,
                              gl.ct_account,
                              MAX(gl.gltrans_id) gltrans_id
                        FROM insis_gen_blc_v10.blc_gl_insis2gl gl
                        WHERE gl.status = cust_gvar.STATUS_INITIAL
                        AND gl.doc_id = pi_doc_id
                        --AND gl.reversed_gltrans_id IS NULL
                        AND EXISTS (SELECT 'EVENT'
                                    FROM blc_sla_events be
                                    WHERE be.event_id = gl.event_id
                                    AND be.attrib_9 = to_char(pi_acc_doc_id))
                        GROUP BY gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5,
                                 gl.dr_segment12,
                                 gl.dr_segment16,
                                 gl.attrib_0,
                                 gl.dr_segment22,
                                 gl.dr_segment19,
                                 gl.dr_segment27,
                                 gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5,
                                 gl.cr_segment11,
                                 gl.cr_segment12,
                                 gl.cr_segment13,
                                 gl.insr_type,
                                 gl.event_code,
                                 gl.dt_account,
                                 gl.ct_account
                         ORDER BY MAX(gl.gltrans_id))
       LOOP
          l_blc_rei_acc_type.id := l_blc_rei_gen_type.id;
          l_blc_rei_acc_type.amount := abs(gl_detail.sum_amount);
      --    l_blc_rei_acc_type.acc_temp_code := gl_detail.event_code;
          l_blc_rei_acc_type.gltrans_id := gl_detail.gltrans_id;
          l_blc_rei_acc_type.policy_class := gl_detail.dr_segment12;
          l_blc_rei_acc_type.tech_branch := gl_detail.dr_segment16;
          l_blc_rei_acc_type.policy_no := gl_detail.attrib_0;
          l_blc_rei_acc_type.policy_start_date := gl_detail.policy_start_date;
          l_blc_rei_acc_type.doc_party := gl_detail.dr_segment19;
          l_blc_rei_acc_type.proforma_number := gl_detail.dr_segment27;
          l_blc_rei_acc_type.fc_amount := abs(gl_detail.sum_fc_amount);
          l_blc_rei_acc_type.policy_currency := gl_detail.cr_segment11;
          l_blc_rei_acc_type.sales_channel := gl_detail.cr_segment12;
          l_blc_rei_acc_type.intermed_type := gl_detail.cr_segment13;
          l_blc_rei_acc_type.insr_type := gl_detail.insr_type;
          --
          l_blc_rei_acc_type.created_on := SYSDATE;
          l_blc_rei_acc_type.updated_on := SYSDATE;
          l_blc_rei_acc_type.created_by := insis_context.get_user;
          l_blc_rei_acc_type.updated_by := insis_context.get_user;
          l_blc_rei_acc_type.status := cust_gvar.STATUS_NEW;
          --
          l_dr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.dt_account);
          l_cr_segment10 := cust_acc_util_pkg.Get_GL_Account_Attribs(gl_detail.ct_account);
          --
          l_blc_rei_acc_type.account := gl_detail.dr_acc_number;
          l_blc_rei_acc_type.account_attribs := l_dr_segment10;

          IF gl_detail.sum_amount > 0
          THEN
             l_blc_rei_acc_type.line_number := l_count;
             l_blc_rei_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
          ELSE
             l_blc_rei_acc_type.line_number := l_count + 1;
             l_blc_rei_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
          END IF;

          INSERT INTO blc_rei_acc VALUES l_blc_rei_acc_type;
          --
          l_blc_rei_acc_type.account := gl_detail.cr_acc_number;
          l_blc_rei_acc_type.account_attribs := l_cr_segment10;

          IF gl_detail.sum_amount > 0
          THEN
             l_blc_rei_acc_type.line_number := l_count + 1;
             l_blc_rei_acc_type.dr_cr_flag := cust_gvar.FLG_CREDIT;
          ELSE
             l_blc_rei_acc_type.line_number := l_count;
             l_blc_rei_acc_type.dr_cr_flag := cust_gvar.FLG_DEBIT;
          END IF;

          INSERT INTO blc_rei_acc VALUES l_blc_rei_acc_type;

          UPDATE blc_gl_insis2gl gl
          SET gl.status = cust_gvar.STATUS_TRANSFER,
              gl.operation_num = l_blc_rei_gen_type.id,
              gl.cr_segment28 = l_count,
              gl.dr_segment10 = l_dr_segment10,
              gl.cr_segment10 = l_cr_segment10,
              gl.cr_segment18 = pi_acc_doc_id
          WHERE gl.status = cust_gvar.STATUS_INITIAL
          AND gl.doc_id = pi_doc_id
          --AND gl.reversed_gltrans_id IS NULL
          AND EXISTS (SELECT 'EVENT'
                      FROM blc_sla_events be
                      WHERE be.event_id = gl.event_id
                      AND be.attrib_9 = to_char(pi_acc_doc_id))
          AND gl.dr_segment1||gl.dr_segment2||gl.dr_segment3||gl.dr_segment4||gl.dr_segment5 = gl_detail.dr_acc_number
          AND nvl(gl.dr_segment12,'-999') = nvl(gl_detail.dr_segment12,'-999')
          AND nvl(gl.dr_segment16,'-999') = nvl(gl_detail.dr_segment16,'-999')
          AND nvl(gl.attrib_0,'-999') = nvl(gl_detail.attrib_0,'-999')
          AND nvl(gl.dr_segment22,'-999') = nvl(to_char(gl_detail.policy_start_date,'dd-mm-yyyy'),'-999')
          AND nvl(gl.dr_segment19,'-999') = nvl(gl_detail.dr_segment19,'-999')
          AND nvl(gl.dr_segment27,'-999') = nvl(gl_detail.dr_segment27,'-999')
          AND gl.cr_segment1||gl.cr_segment2||gl.cr_segment3||gl.cr_segment4||gl.cr_segment5 = gl_detail.cr_acc_number
          AND nvl(gl.cr_segment11,'-999') = nvl(gl_detail.cr_segment11,'-999')
          AND nvl(gl.cr_segment12,'-999') = nvl(gl_detail.cr_segment12,'-999')
          AND nvl(gl.cr_segment13,'-999') = nvl(gl_detail.cr_segment13,'-999')
          AND nvl(gl.insr_type,'-999') = nvl(gl_detail.insr_type,'-999')
          AND gl.event_code = gl_detail.event_code;

          l_count := l_count + 2;
       END LOOP;
    -- End:  Insert details

    po_header_id := l_blc_rei_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_RI_Bill');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_RI_Bill', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Insert_SAP_RI_Bill;

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Delete_RI_Bill
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      02.01.2018  Creation;
--
-- Purpose:
--    Insert record for deletion of RI bill into BLC_REI_GEN
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pi_acc_doc_prefix      VARCHAR2     Voucher doc prefix
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Delete_RI_Bill
   (pi_doc_id         IN     NUMBER,
    pi_acc_doc_id     IN     NUMBER,
    pi_reversed_id    IN     NUMBER,
    pi_acc_doc_prefix IN     VARCHAR2,
    po_header_id      OUT    NUMBER,
    pio_Err           IN OUT SrvErr)
IS
    l_log_module              VARCHAR2(240);
    l_SrvErrMsg               SrvErrMsg;
    l_blc_rei_gen_type        blc_rei_gen%ROWTYPE;
    l_doc                     blc_documents_type;
    l_reverse_date            DATE;
    l_reverse_reason          VARCHAR2(400 CHAR);
    --
    CURSOR c_act IS
      SELECT ba.action_date, substr(ba.notes,1,400)
      FROM blc_actions ba,
           blc_lookups bl
      WHERE ba.document_id = pi_doc_id
      AND ba.action_type_id = bl.lookup_id
      AND bl.lookup_code = cust_gvar.ACTIVITY_DELETE
      ORDER BY ba.action_id DESC;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Insert_SAP_Delete_RI_Bill';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Insert_SAP_Delete_RI_Bill');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_id = '||pi_acc_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_reversed_id = '||pi_reversed_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_acc_doc_prefix = '||pi_acc_doc_prefix);

    l_doc := blc_documents_type(pi_doc_id);

    -- prepare header data for document
    l_blc_rei_gen_type.legal_entity := l_doc.legal_entity_id;
    l_blc_rei_gen_type.doc_number := l_doc.doc_number;
    l_blc_rei_gen_type.action_type := 'ANN';
    --l_blc_rei_gen_type.action_type := substr(pi_acc_doc_prefix,instr(pi_acc_doc_prefix,'-')+1);
    l_blc_rei_gen_type.doc_id := l_doc.doc_id;
    --l_blc_proforma_gen_type.ip_code := substr(pi_acc_doc_prefix,1,instr(pi_acc_doc_prefix,'-')-1);
    l_blc_rei_gen_type.reversed_id := pi_reversed_id;

    --
    OPEN c_act;
       FETCH c_act
       INTO l_reverse_date, --l_blc_rei_gen_type.doc_reverse_date,
            l_reverse_reason; --l_blc_rei_gen_type.reverse_reason;
    CLOSE c_act;

    SELECT blc_sap_header_seq.nextval
    INTO l_blc_rei_gen_type.id
    FROM dual;

    l_blc_rei_gen_type.acc_doc_id := pi_acc_doc_id;

    l_blc_rei_gen_type.created_on := SYSDATE;
    l_blc_rei_gen_type.updated_on := SYSDATE;
    l_blc_rei_gen_type.created_by := insis_context.get_user;
    l_blc_rei_gen_type.updated_by := insis_context.get_user;
    l_blc_rei_gen_type.status := cust_gvar.STATUS_NEW;

    INSERT INTO blc_rei_gen VALUES l_blc_rei_gen_type;

    UPDATE blc_gl_insis2gl gl
    SET gl.status = cust_gvar.STATUS_TRANSFER,
        gl.operation_num = l_blc_rei_gen_type.id,
        gl.dr_segment15 = l_blc_rei_gen_type.action_type,
        --gl.cr_segment16 = l_blc_rei_gen_type.ip_code,
        gl.effective_date = l_reverse_reason, --l_blc_rei_gen_type.doc_reverse_date,
        gl.cr_segment18 = pi_acc_doc_id
    WHERE gl.status = cust_gvar.STATUS_INITIAL
    AND gl.doc_id = pi_doc_id
    --AND gl.reversed_gltrans_id IS NOT NULL;
    AND EXISTS (SELECT 'EVENT'
                FROM blc_sla_events be
                WHERE be.event_id = gl.event_id
                AND be.attrib_9 = to_char(pi_acc_doc_id));

    po_header_id := l_blc_rei_gen_type.id;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_header_id = '||po_header_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Insert_SAP_Delete_RI_Bill');

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_acc_export_pkg.Insert_SAP_Delete_RI_Bill', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_EXCEPTION,
                               'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Insert_SAP_Delete_RI_Bill;
--
END cust_acc_export_pkg;
/

