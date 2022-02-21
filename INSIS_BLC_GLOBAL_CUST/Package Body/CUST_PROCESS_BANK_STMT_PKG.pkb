CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_PROCESS_BANK_STMT_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains process of Process Bank Statements
--------------------------------------------------------------------------------

--=============================================================================
--               *********** Local Trace Routine **********
--=============================================================================
C_LEVEL_STATEMENT     CONSTANT NUMBER := 1;
C_LEVEL_PROCEDURE     CONSTANT NUMBER := 2;
C_LEVEL_EVENT         CONSTANT NUMBER := 3;
C_LEVEL_EXCEPTION     CONSTANT NUMBER := 4;
C_LEVEL_ERROR         CONSTANT NUMBER := 5;
C_LEVEL_UNEXPECTED    CONSTANT NUMBER := 6;

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_process_bank_stmt_pkg';
--=============================================================================

--------------------------------------------------------------------------------
--GRANT EXECUTE ON INSIS_GEN_CFG_V10.RB_SRV TO INSIS_BLC_GLOBAL_CUST;
--------------------------------------------------------------------------------
FUNCTION Get_Rule_Result_Char( pi_rule_code IN     VARCHAR2,
                               pi_line_id   IN     NUMBER,
                               pio_Err      IN OUT SrvErr )
RETURN VARCHAR2
IS
    l_log_module VARCHAR2 (240);
    l_SrvErrMsg SrvErrMsg;

    l_Context srvcontext;
    l_RetContext srvcontext;

    l_rule_value VARCHAR2(100);
    l_rule_id     NUMBER;
BEGIN
    blc_log_pkg.initialize( pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        RETURN( NULL );
    END IF;
    l_log_module := C_DEFAULT_MODULE || '.Get_Rule_Result_Char';
    blc_log_pkg.insert_message ( l_log_module,C_LEVEL_PROCEDURE,'BEGIN of function Get_Rule_Result_Char' );
    blc_log_pkg.insert_message ( l_log_module,C_LEVEL_PROCEDURE,'pi_rule_code = ' || pi_rule_code );
    blc_log_pkg.insert_message ( l_log_module,C_LEVEL_PROCEDURE,'pi_line_id = ' || pi_line_id );
    --
    IF pi_rule_code IS NULL OR pi_line_id IS NULL
    THEN
        RETURN ( NULL );
    END IF;
    --
    srv_context.SetContextAttrNumber( l_Context, 'LINE_ID', srv_context.Integers_Format, pi_line_id );
    Srv_Context.SetContextAttrChar  ( l_context, 'RULE_CODE', pi_rule_code );
    --
    rb_srv.GetRuleIdByCode( l_Context, l_RetContext, pio_Err );
    --
    IF srv_error.rqStatus( pio_Err )
    THEN
        srv_context.GetContextAttrNumber( l_RetContext, 'RULE_ID', l_rule_id );
        Srv_Context.SetContextAttrNumber( l_Context, 'RULE_ID', srv_context.Integers_Format, l_rule_id );
    END IF;
    --
    RB_SRV.RuleRequest ( pi_rule_code, l_Context, l_RetContext, pio_Err );
    --
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_rule_code = '|| pi_rule_code ||' - '|| pio_Err(pio_Err.FIRST).errmessage );
        RETURN ( NULL );
    END IF;

    srv_context.GetContextAttrChar( l_RetContext, 'RULE_VALUE', l_rule_value );
    --
    blc_log_pkg.insert_message ( l_log_module,C_LEVEL_PROCEDURE,'l_rule_value = ' || l_rule_value );
    blc_log_pkg.insert_message ( l_log_module,C_LEVEL_PROCEDURE,'END of function Get_Rule_Result_Char' );
    --
    RETURN( l_rule_value );
EXCEPTION WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_PROCESS_BANK_STMT_PKG.Get_Rule_Result_Char', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message( l_log_module,C_LEVEL_EXCEPTION,'pi_rule_code = ' || pi_rule_code || ' - ' || 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
      --
      RETURN( NULL );
END Get_Rule_Result_Char;

--------------------------------------------------------------------------------
PROCEDURE Create_Apply_Receipt( pi_line_id       IN     NUMBER,
                                pi_doc_ids_list  IN     VARCHAR2,
                                pi_policy_list   IN     VARCHAR2,
                                pio_Err          IN OUT SrvErr )
IS
    l_log_module   VARCHAR2(240);
    l_SrvErrMsg    SrvErrMsg;
    --
    l_SrvErr           SrvErr;
    l_result_flag      VARCHAR2(1) := 'Y';
    l_bank_st_line     BLC_BANK_STATEMENT_LINES_TYPE;
    l_doc_id           NUMBER;
    l_procedure_result VARCHAR2(30);
    l_ad_date          DATE;
BEGIN
    l_log_module := C_DEFAULT_MODULE || '.Create_Apply_Receipt';
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Create_Apply_Receipt' );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_line_id = ' || pi_line_id );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_doc_ids_list = ' || pi_doc_ids_list );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_policy_list = ' || pi_policy_list );

    l_bank_st_line := NEW BLC_BANK_STATEMENT_LINES_TYPE(pi_line_id,l_SrvErr);
    --
    -- Create receipt CREATE_BLC_BSL_RECEIPT
    SAVEPOINT CREATE_RECEIPT;
    --
    blc_bank_stmt_util_pkg.Pr_Create_Receipt( pi_line_id, l_SrvErr );
    IF NOT srv_error.rqStatus( l_SrvErr )
    THEN
        l_result_flag := 'N';
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Create_Receipt: result_flag = ' || l_result_flag );
    --
    -- CREATE_BLC_BSL_REMITTANCES
    IF l_result_flag = 'Y'
    THEN
        blc_bank_stmt_util_pkg.Pr_Create_Remittances( pi_line_id             => pi_line_id,
                                                      pi_doc_ids_list        => pi_doc_ids_list,
                                                      pi_policy_numbers_list => pi_policy_list,
                                                      pio_Err                => l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            l_result_flag := 'N';
            ROLLBACK TO CREATE_RECEIPT;

            BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                  ( pio_bank_stmt_line_rec => l_bank_st_line,
                                    pio_Err => l_SrvErr );
        END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Create_Remittances: result_flag = ' || l_result_flag );
    --
    -- CUST_BLC_SET_AD
    IF l_result_flag = 'Y' AND l_bank_st_line.attrib_3 IS NOT NULL
    THEN
       BEGIN
          l_doc_id := TO_NUMBER(pi_doc_ids_list);
       EXCEPTION
          WHEN OTHERS THEN
            l_doc_id := NULL;
       END;

       IF l_bank_st_line.attrib_4 IS NOT NULL
       THEN
          BEGIN
             l_ad_date := TO_DATE(l_bank_st_line.attrib_4, 'dd-mm-yyyy');
          EXCEPTION
            WHEN OTHERS THEN
               l_ad_date := l_bank_st_line.clearing_date;
          END;
       ELSE
          l_ad_date := l_bank_st_line.clearing_date;
       END IF;

       cust_billing_pkg.Set_Doc_AD
                     ( pi_doc_id             => l_doc_id,
                       pi_action_type        => 'CREATE_AD',
                       pi_ad_number          => l_bank_st_line.attrib_3,
                       pi_ad_date            => l_ad_date,
                       pi_action_reason      => NULL,
                       po_procedure_result   => l_procedure_result,
                       pio_Err               => l_SrvErr);

        IF l_procedure_result = 'ERROR'
        THEN
            l_result_flag := 'N';
            ROLLBACK TO CREATE_RECEIPT;

            BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                  ( pio_bank_stmt_line_rec => l_bank_st_line,
                                    pio_Err => l_SrvErr );
        END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Set_Doc_AD: result_flag = ' || l_result_flag );
    --
    -- VALIDATE_BLC_BSL_RECEIPT
    IF l_result_flag = 'Y'
    THEN
         blc_bank_stmt_util_pkg.Pr_Validate_Receipt( pi_line_id => pi_line_id,
                                                     pio_Err    => l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            l_result_flag := 'N';
            ROLLBACK TO CREATE_RECEIPT;

            BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                  ( pio_bank_stmt_line_rec => l_bank_st_line,
                                    pio_Err => l_SrvErr );
        END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Validate_Receipt: result_flag = ' || l_result_flag );
    --
    -- APPLY_BLC_BSL_BY_REMITTANCES
    IF l_result_flag = 'Y'
    THEN
        blc_bank_stmt_util_pkg.Pr_Apply_By_Remittances( pi_line_id => pi_line_id,
                                                        pio_Err    => l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            l_result_flag := 'N';
            ROLLBACK TO CREATE_RECEIPT;

            BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                  ( pio_bank_stmt_line_rec => l_bank_st_line,
                                    pio_Err => l_SrvErr );
        END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Apply_By_Remittances: result_flag = ' || l_result_flag );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Create_Apply_Receipt' );
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Create_Apply_Receipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Create_Apply_Receipt;

--------------------------------------------------------------------------------
PROCEDURE Create_Receipt( pi_line_id   IN     NUMBER,
                          pio_Err      IN OUT SrvErr )
IS
    l_log_module   VARCHAR2(240);
    l_SrvErrMsg    SrvErrMsg;
    --
    l_SrvErr          SrvErr;
    l_result_flag     VARCHAR2(1) := 'Y';
    --
    l_full_flag      VARCHAR2(1);
    l_doc_ids_list   VARCHAR2(2000);
    l_policy_list    VARCHAR2(2000);
BEGIN
    l_log_module := C_DEFAULT_MODULE || '.Create_Receipt';
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Create_Receipt' );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_line_id = ' || pi_line_id );
    --
    -- Recognize Party   RECOGNIZE_BLC_BSL_PARTY
    IF l_result_flag = 'Y'
    THEN
        blc_bank_stmt_util_pkg.Pr_Recognize_Party( pi_line_id, l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            l_result_flag := 'N';
        END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Recognize_Party: result_flag = ' || l_result_flag );
    --
    -- Retrieve Doc IDs   RETRIEVE_BLC_BSL_DOC_IDS
    IF l_result_flag = 'Y'
    THEN
        l_full_flag := blc_bank_stmt_util_pkg.Pr_Retrieve_Doc_Ids_F( pi_line_id      => pi_line_id,
                                                                     po_doc_ids_list => l_doc_ids_list,
                                                                     pio_Err         => l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            l_result_flag := 'N';
        END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Retrieve_Doc_Ids_F: result_flag = ' || l_result_flag );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Retrieve_Doc_Ids_F: full_flag = ' || l_full_flag );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Retrieve_Doc_Ids_F: l_doc_ids_list = ' || l_doc_ids_list );
    --
    --  Retrieve policy Numbers   RETRIEVE_BLC_BSL_PLC_NUMS
    /* no need because no applicationon policy
    IF l_result_flag = 'Y' AND NVL(l_full_flag,'N') = 'N'
    THEN
        l_full_flag := blc_bank_stmt_util_pkg.Pr_Retrieve_Policy_Numbers_F( pi_line_id             => pi_line_id,
                                                                            po_policy_numbers_list => l_policy_list,
                                                                            pio_Err                => l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            l_result_flag := 'N';
        END IF;
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Retrieve_Policy_Numbers_F: result_flag = ' || l_result_flag );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Retrieve_Policy_Numbers_F: full_flag = ' || l_full_flag );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Retrieve_Policy_Numbers_F: l_policy_list = ' || l_policy_list );
        --
        IF l_result_flag = 'Y' AND l_policy_list IS NOT NULL
        THEN
            l_full_flag := blc_bank_stmt_util_pkg.Pr_Validate_Policy_Numbers_F( pi_line_id              => pi_line_id,
                                                                                pio_policy_numbers_list => l_policy_list,
                                                                                pio_Err                 => l_SrvErr );
            IF NOT srv_error.rqStatus( l_SrvErr )
            THEN
                l_result_flag := 'N';
            END IF;
        END IF;
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Validate_Policy_Numbers_F: result_flag = ' || l_result_flag );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Validate_Policy_Numbers_F: full_flag = ' || l_full_flag );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Validate_Policy_Numbers_F: l_policy_list = ' || l_policy_list );
        --
        IF l_result_flag = 'Y'
        THEN
            blc_bank_stmt_util_pkg.Pr_Set_Unrecognized_Error( pi_line_id             => pi_line_id,
                                                              pi_doc_ids_list        => l_doc_ids_list,
                                                              pi_policy_numbers_list => l_policy_list,
                                                              pio_Err                => l_SrvErr );
            IF NOT srv_error.rqStatus( l_SrvErr )
            THEN
               l_result_flag := 'N';
            END IF;
        END IF;
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Set_Unrecognized_Error: result_flag = ' || l_result_flag );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Set_Unrecognized_Error: full_flag = ' || l_full_flag );
        --
    END IF;
    */
    IF l_result_flag = 'Y'
    THEN
       blc_bank_stmt_util_pkg.Pr_Set_Unrecognized_Error( pi_line_id             => pi_line_id,
                                                         pi_doc_ids_list        => l_doc_ids_list,
                                                         pi_policy_numbers_list => l_policy_list,
                                                         pio_Err                => l_SrvErr );
       IF NOT srv_error.rqStatus( l_SrvErr )
       THEN
          l_result_flag := 'N';
       END IF;
    END IF;
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Set_Unrecognized_Error: result_flag = ' || l_result_flag );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Pr_Set_Unrecognized_Error: full_flag = ' || l_full_flag );
    --
    -- Create_Apply_Receipt
    IF l_result_flag = 'Y' AND NVL(l_full_flag,'N') = 'Y'
    THEN
        Create_Apply_Receipt( pi_line_id       => pi_line_id,
                              pi_doc_ids_list  => l_doc_ids_list,
                              pi_policy_list   => l_policy_list,
                              pio_Err          => l_SrvErr );
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
           l_result_flag := 'N';
        END IF;

        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'After Create_Apply_Receipt: result_flag = ' || l_result_flag );
    END IF;
    --
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Create_Receipt' );
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Create_Receipt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, c_level_exception, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Create_Receipt;

--------------------------------------------------------------------------------
-- Name: cust_process_bank_stmt_pkg.Create_Clearing
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
-- Purpose: Procedure executes bank statement lines
--
-- Input parameters:
-- pi_line_id                 NUMBER      Bank Statement Line ID(required)
-- pio_Err                    SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In Process_Exec_Bank_St_Line
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Clearing( pi_line_id IN     NUMBER,
                           pio_Err    IN OUT SrvErr )
IS
    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
    --
    l_exp_error EXCEPTION;
    l_err_message VARCHAR2(2000);
    --
    l_Context    srvcontext;
    l_RetContext srvcontext;
    --
    l_procedure_result VARCHAR2(30);
    l_is_valid         VARCHAR2(30);
BEGIN
    l_log_module := C_DEFAULT_MODULE || '.Create_Clearing';
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Create_Clearing' );
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'pi_line_id = ' || pi_line_id );
    --
    -- 1 Validate Clearing Data
    srv_prm_process.Set_Line_Id( l_Context, pi_line_id );
    srv_prm_process.Set_Procedure_Result( l_Context, blc_gvar_process.flg_ok );

    srv_events.sysEvent( 'VALIDATE_BLC_BSL_PAYMENT_DATA', l_Context, l_RetContext, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    --
    l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
    l_is_valid := srv_prm_process.Get_Is_Valid( l_RetContext );
    --
    IF l_is_valid = 'Y'
    THEN
        -- Clear Payment
        l_Context := l_RetContext;
        l_RetContext := NULL;
        --
        srv_events.sysEvent( 'CLEAR_BLC_BSL_PAYMENT', l_Context, l_RetContext, pio_Err );
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            FOR i IN 1..pio_Err.COUNT
            LOOP
                blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
            END LOOP;
            --
            RAISE l_exp_error;
        END IF;
        --
        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        --
    ELSIF l_is_valid = 'R'
    THEN
        -- 1 Reinstate Payment
        l_Context := l_RetContext;
        l_RetContext := NULL;
        --
        srv_events.sysEvent( 'REINSTATE_BLC_BSL_PAYMENT', l_Context, l_RetContext, pio_Err );
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            FOR i IN 1..pio_Err.COUNT
            LOOP
                blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
            END LOOP;
            --
            RAISE l_exp_error;
        END IF;
        --
        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        --
        -- 2 Validate Payment
        l_Context := l_RetContext;
        l_RetContext := NULL;
        --
        srv_events.sysEvent( 'VALIDATE_BLC_BSL_RECEIPT', l_Context, l_RetContext, pio_Err );
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            FOR i IN 1..pio_Err.COUNT
            LOOP
                blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
            END LOOP;
            --
            RAISE l_exp_error;
        END IF;
        --
        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        --
       --
       -- Clear Payment
        l_Context := l_RetContext;
        l_RetContext := NULL;
        --
        srv_events.sysEvent( 'CLEAR_BLC_BSL_PAYMENT', l_Context, l_RetContext, pio_Err );
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            FOR i IN 1..pio_Err.COUNT
            LOOP
                blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
            END LOOP;
            --
            RAISE l_exp_error;
        END IF;
        --
        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        --
    ELSE
        RETURN;
    END IF;

    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Create_Clearing' );
    --
EXCEPTION
    WHEN l_exp_error THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Create_Clearing', l_err_message );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' ||  l_err_message );
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Create_Clearing', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Create_Clearing;

--------------------------------------------------------------------------------
PROCEDURE Clear_Line( pi_line_id   IN     NUMBER,
                      pio_Err      IN OUT SrvErr )
IS
    l_log_module   VARCHAR2(240);
    l_SrvErrMsg    SrvErrMsg;
    --
    l_SrvErr       SrvErr;
    l_bank_st_line BLC_BANK_STATEMENT_LINES_TYPE;
BEGIN
    -- Validate data VALIDATE_BLC_BSL_PAYMENT_DATA
    SAVEPOINT CREATE_CLEARING;
    blc_bank_stmt_util_pkg.Pr_Validate_Payment_Data( pi_line_id, l_SrvErr );
    IF NOT srv_error.rqStatus( l_SrvErr )
    THEN
       NULL;
    ELSE
       l_bank_st_line := NEW BLC_BANK_STATEMENT_LINES_TYPE(pi_line_id, l_SrvErr);
       --
       IF cust_pay_util_pkg.Is_Pmnt_Adv_Claim(l_bank_st_line.payment_id) = 'N' --CHA93S-8 add to not create clearing for advance claims
       THEN
          blc_bank_stmt_util_pkg.Pr_Clear_Payment( pi_line_id, l_SrvErr );

          IF NOT srv_error.rqStatus( l_SrvErr )
          THEN
             NULL;
          ELSE
             cust_pay_util_pkg.Create_Acc_Event_Clear_Inst
                     (pi_clearing_id  => NULL,
                      pi_uncleared    => NULL,
                      pi_payment_id   => l_bank_st_line.payment_id,
                      pio_Err         => l_SrvErr);
              IF NOT srv_error.rqStatus( l_SrvErr )
              THEN
                 ROLLBACK TO CREATE_CLEARING;

                 BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                      ( pio_bank_stmt_line_rec => l_bank_st_line,
                                        pio_Err => l_SrvErr );
              END IF;
          END IF;
       ELSE
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Clear_Line', 'cust_process_bank_stmt_pkg.CL.WrongActivity');
          srv_error.SetErrorMsg( l_SrvErrMsg, l_SrvErr );
          --
          BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                    ( pio_bank_stmt_line_rec => l_bank_st_line,
                                      pio_Err => l_SrvErr );
       END IF;
    END IF;

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Clear_Line', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, c_level_exception, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Clear_Line;

--------------------------------------------------------------------------------
PROCEDURE Reject_Line( pi_line_id   IN     NUMBER,
                       pio_Err      IN OUT SrvErr )
IS
    l_log_module   VARCHAR2(240);
    l_SrvErrMsg    SrvErrMsg;
    --
    l_SrvErr       SrvErr;
    l_SrvErr_1     SrvErr;
    l_SrvErr_2     SrvErr;
    l_bank_st_line BLC_BANK_STATEMENT_LINES_TYPE;
    l_doc_id       NUMBER;
    l_doc          blc_documents_type;
    l_ad_date      DATE;
    --
    l_procedure_result VARCHAR2(30);
BEGIN
    -- Validate Reject data VALIDATE_BLC_BSL_PAYMENT_DATA
    blc_bank_stmt_util_pkg.Pr_Validate_Payment_Data( pi_line_id, l_SrvErr );
    IF NOT srv_error.rqStatus( l_SrvErr )
    THEN
       NULL;
    ELSE
       l_bank_st_line := NEW BLC_BANK_STATEMENT_LINES_TYPE(pi_line_id, l_SrvErr);

       IF cust_pay_util_pkg.Is_Pmnt_Adv_Claim(l_bank_st_line.payment_id) = 'N' --CHA93S-8 add to not create reversing for advance claims
       THEN
           -- Reject Payment  REJECT_BLC_BSL_PAYMENT - call reverse before delete AD --LAP85-17
           blc_bank_stmt_util_pkg.Pr_Reject_Payment( pi_line_id, l_SrvErr );

           IF NOT srv_error.rqStatus( l_SrvErr )
           THEN
               NULL;
           ELSE
               IF l_bank_st_line.attrib_3 IS NOT NULL
               THEN
                  cust_pay_util_pkg.Validate_Pmnt_Appl
                         (pi_payment_id        => l_bank_st_line.payment_id,
                          pi_remittance_ids    => NULL,
                          pi_unapply           => 'Y',
                          po_doc_id            => l_doc_id,
                          pio_Err              => l_SrvErr_1);

                  IF l_doc_id IS NOT NULL
                  THEN
                     l_doc := NEW blc_documents_type(l_doc_id);

                     --IF blc_common_pkg.get_lookup_code(l_doc.doc_type_id) = 'PROFORMA' --LAP85-17
                     IF blc_common_pkg.get_lookup_code(l_doc.doc_type_id) IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE) --LAP85-17
                     THEN
                         IF l_bank_st_line.attrib_4 IS NOT NULL
                         THEN
                            BEGIN
                               l_ad_date := TO_DATE(l_bank_st_line.attrib_4, 'dd-mm-yyyy');
                            EXCEPTION
                              WHEN OTHERS THEN
                                 l_ad_date := l_bank_st_line.clearing_date;
                            END;
                         ELSE
                            l_ad_date := l_bank_st_line.clearing_date;
                         END IF;

                         cust_billing_pkg.Set_Doc_AD
                                       ( pi_doc_id             => l_doc_id,
                                         pi_action_type        => 'DELETE_AD',
                                         pi_ad_number          => l_bank_st_line.attrib_3,
                                         pi_ad_date            => l_ad_date,
                                         pi_action_reason      => NULL,
                                         po_procedure_result   => l_procedure_result,
                                         pio_Err               => l_SrvErr);

                         IF NOT srv_error.rqStatus( l_SrvErr )
                         THEN
                            l_SrvErr_2 := l_SrvErr;
                            BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                                  ( pio_bank_stmt_line_rec => l_bank_st_line,
                                                    pio_Err => l_SrvErr_2 );
                         END IF;

                     END IF;
                  END IF;
               END IF;
           END IF;
       ELSE
           srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Reject_Line', 'cust_process_bank_stmt_pkg.RL.WrongActivity');
           srv_error.SetErrorMsg( l_SrvErrMsg, l_SrvErr );
           --
           l_SrvErr_2 := l_SrvErr;
           BLC_BANK_STMT_UTIL_PKG.Update_Bank_St_Line
                                    ( pio_bank_stmt_line_rec => l_bank_st_line,
                                      pio_Err => l_SrvErr_2 );
       END IF;

       --move to be before delete AD --LAP85-17
       /*
       IF NOT srv_error.rqStatus( l_SrvErr )
       THEN
          NULL;
       ELSE
          -- Reject Payment  REJECT_BLC_BSL_PAYMENT
          blc_bank_stmt_util_pkg.Pr_Reject_Payment( pi_line_id, l_SrvErr );
       END IF;
       */
    END IF;

EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Reject_Line', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, c_level_exception, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Reject_Line;

--------------------------------------------------------------------------------
-- Name: cust_process_bank_stmt_pkg.Create_Reject
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
-- Purpose: Procedure executes bank statement lines
--
-- Input parameters:
-- pi_line_id                 NUMBER      Bank Statement Line ID(required)
-- pio_Err                    SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In Process_Exec_Bank_St_Line
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Reject( pi_line_id IN     NUMBER,
                         pio_Err    IN OUT SrvErr )
IS
    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
    --
    l_exp_error EXCEPTION;
    l_err_message VARCHAR2(2000);
    --
    l_Context    srvcontext;
    l_RetContext srvcontext;
    --
    l_procedure_result VARCHAR2(30);
    l_is_valid         VARCHAR2(30);
BEGIN
    l_log_module := C_DEFAULT_MODULE || '.Create_Reject';
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Create_Reject' );
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'pi_line_id = ' || pi_line_id );
    --
    -- 1 Validate Reject data
    srv_prm_process.Set_Line_Id( l_Context, pi_line_id );
    srv_prm_process.Set_Procedure_Result( l_Context, blc_gvar_process.flg_ok );
    --
    srv_events.sysEvent( 'VALIDATE_BLC_BSL_PAYMENT_DATA', l_Context, l_RetContext, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    --
    l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
    l_is_valid := srv_prm_process.Get_Is_Valid( l_RetContext );
    --
    IF l_procedure_result = BLC_GVAR_PROCESS.FLG_ERR
    THEN
        RETURN;
    END IF;
    --
    IF l_is_valid = 'Y'
    THEN
        -- Reject Payment
        l_Context := l_RetContext;
        l_RetContext := NULL;
        --
        srv_events.sysEvent( 'REJECT_BLC_BSL_PAYMENT', l_Context, l_RetContext, pio_Err );
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            FOR i IN 1..pio_Err.COUNT
            LOOP
                blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
            END LOOP;
            --
            RAISE l_exp_error;
        END IF;
        --
        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        --
    ELSIF l_is_valid = 'R'
    THEN
        -- 1 Return Payment
        l_Context := l_RetContext;
        l_RetContext := NULL;
        --
        srv_events.sysEvent( 'CREATE_BLC_BSL_RET_RECEIPT', l_Context, l_RetContext, pio_Err );
        --
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
            FOR i IN 1..pio_Err.COUNT
            LOOP
                blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
            END LOOP;
            --
            RAISE l_exp_error;
        END IF;
        --
        l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
        --
    ELSE
        RETURN;
    END IF;

    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Create_Reject' );
    --
EXCEPTION
    WHEN l_exp_error THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_BANK_STMT_UTIL_PKG.Create_Reject', l_err_message );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' ||  l_err_message );
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_BANK_STMT_UTIL_PKG.Create_Reject', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Create_Reject;

--------------------------------------------------------------------------------
-- Name: cust_process_bank_stmt_pkg.Process_Exec_Bank_St_Line
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
-- Purpose: Procedure executes bank statement lines
--
-- Input parameters:
-- pi_line_id                 NUMBER      Bank Statement Line ID(required)
-- pio_Err                    SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In bank statement BPMN processing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_Exec_Bank_St_Line( pi_line_id IN     NUMBER,
                                     pio_Err    IN OUT SrvErr )
IS
    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
    --
    l_exp_error EXCEPTION;
    l_err_message VARCHAR2(2000);
    --
    l_Context srvcontext;
    l_RetContext srvcontext;
    --
    l_procedure_result VARCHAR2(30);
    l_oper_type      VARCHAR2(30);
    l_bank_st_line   BLC_BANK_STATEMENT_LINES_TYPE;
    l_bank_st_header BLC_BANK_STATEMENTS_TYPE;
BEGIN
    blc_log_pkg.initialize( pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    l_log_module := C_DEFAULT_MODULE || '.Process_Exec_Bank_St_Line';
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Process_Exec_Bank_St_Line' );
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'pi_line_id = ' || pi_line_id );
    --
    --
    -- 1 begin line
    srv_prm_process.Set_Line_Id( l_Context, pi_line_id );
    --
    BLC_BANK_STMT_UTIL_PKG.g_recognized_objects_tbl := NULL; --added on 01.12.2016
    -- srv_events.sysEvent( 'BEGIN_BLC_EXEC_LINE', l_Context, l_RetContext, pio_Err );
    -- Begin Execute Line BEGIN_BLC_EXEC_LINE
    blc_bank_stmt_util_pkg.Pr_Begin_Execute_Line( pi_line_id, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    --
    l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
    --
    IF l_procedure_result = BLC_GVAR_PROCESS.FLG_ERR
    THEN RETURN;
    END IF;
    --
    l_bank_st_line := NEW BLC_BANK_STATEMENT_LINES_TYPE(pi_line_id,pio_Err);
    --remove calling rule
    /*
    l_oper_type := Get_Rule_Result_Char ( pi_rule_code => 'BLC_BSL_OPERATION_TYPE',
                                          pi_line_id => pi_line_id,
                                          pio_Err => pio_Err );

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' || pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    */
    --
    l_oper_type := l_bank_st_line.operation_type;
    --
    IF l_oper_type = 'CREDIT_TRANSFER'
    THEN
       IF l_bank_st_line.usage_id IS NULL
       THEN
          l_bank_st_header := NEW BLC_BANK_STATEMENTS_TYPE(l_bank_st_line.bank_stmt_id, pio_Err);

          l_bank_st_line.usage_id := BLC_BANK_STMT_UTIL_PKG.Get_BS_Usage_Id
                                             ( pi_legal_entity_id => l_bank_st_header.legal_entity_id,
                                               pi_org_id => l_bank_st_header.org_id,
                                               pi_bank_account => l_bank_st_header.account_number,
                                               pi_currency => l_bank_st_header.currency,
                                               pi_operation_type => l_oper_type,
                                               pi_to_date => l_bank_st_line.value_date,
                                               pio_Err => pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              FOR i IN 1..pio_Err.COUNT
              LOOP
                  blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                  l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
              END LOOP;
              --
              RAISE l_exp_error;
          END IF;

          --add case for DEBIT_TRANSFER 28.02.2018
          IF l_bank_st_line.usage_id IS NULL
          THEN
             pio_Err := NULL;
             l_bank_st_line.usage_id := BLC_BANK_STMT_UTIL_PKG.Get_BS_Usage_Id
                                             ( pi_legal_entity_id => l_bank_st_header.legal_entity_id,
                                               pi_org_id => l_bank_st_header.org_id,
                                               pi_bank_account => l_bank_st_header.account_number,
                                               pi_currency => l_bank_st_header.currency,
                                               pi_operation_type => 'DEBIT_TRANSFER',
                                               pi_to_date => l_bank_st_line.value_date,
                                               pio_Err => pio_Err );

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                FOR i IN 1..pio_Err.COUNT
                LOOP
                    blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
                    l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
                END LOOP;
                --
                RAISE l_exp_error;
             END IF;
          END IF;

          pio_Err := NULL;

          IF NOT l_bank_st_line.update_blc_bank_stmt_lines ( pio_Err )
          THEN
             blc_log_pkg.insert_message( l_log_module,
                                         C_LEVEL_EXCEPTION,
                                          'l_bank_st_line.line_id = ' || l_bank_st_line.line_id || ' - ' ||
                                          pio_Err(pio_Err.FIRST).errmessage );
          END IF;

          INSIS_GEN_BLC_V10.blc_log_pkg.insert_message( l_log_module,
                                                         C_LEVEL_STATEMENT,
                                                        'l_bank_st_line.usage_id = ' || l_bank_st_line.usage_id );

        END IF;

        Create_Receipt( pi_line_id, pio_Err );
    ELSIF l_oper_type = 'CLEARING'
    THEN
       -- Create_Clearing( pi_line_id, pio_Err );
        Clear_Line( pi_line_id, pio_Err );
    ELSIF l_oper_type = 'REVERSE'
    THEN
        --Create_Reject( pi_line_id, pio_Err );
        Reject_Line( pi_line_id, pio_Err );
    ELSE
        RETURN;
    END IF;
    --
    -- srv_events.sysEvent( 'END_BLC_EXEC_LINE', l_Context, l_RetContext, pio_Err );
    -- End Execute Line   END_BLC_EXEC_LINE
    blc_bank_stmt_util_pkg.pr_end_execute_line( pi_line_id, pio_err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id =' || pi_line_id || ' - ' ||pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    --
    blc_log_pkg.insert_message ( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Process_Exec_Bank_St_Line' );
    --
EXCEPTION
    WHEN l_exp_error THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_BANK_STMT_UTIL_PKG.Process_Exec_Bank_St_Line', l_err_message );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' ||  l_err_message );
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_BANK_STMT_UTIL_PKG.Process_Exec_Bank_St_Line', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_line_id = ' || pi_line_id || ' - ' || SQLERRM );
END Process_Exec_Bank_St_Line;

--------------------------------------------------------------------------------
-- Name: cust_process_bank_stmt_pkg.Process_Bank_Stmt_Events
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
-- Purpose: Procedure executes bank statements
--
-- Input parameters:
-- pi_bank_stmt_id            NUMBER      Bank Statement ID(required)
-- pi_legal_entity_id         NUMBER      Legal Entity ID
-- pi_org_id                  NUMBER      Org Id
-- pio_Err                    SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In bank statement BPMN processing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_Bank_Stmt_E( pi_bank_stmt_id    IN     NUMBER,
                               pi_legal_entity_id IN     NUMBER DEFAULT NULL,
                               pi_org_id          IN     NUMBER DEFAULT NULL,
                               pio_Err            IN OUT SrvErr )
IS
    l_log_module VARCHAR2 (240);
    l_SrvErrMsg SrvErrMsg;
    --
    l_exp_error EXCEPTION;
    l_err_message VARCHAR2(2000);
    --
    l_procedure_result VARCHAR2(30);
    --
    l_Context srvcontext;
    l_RetContext srvcontext;
    --
    l_bank_st  blc_bank_statements_type;
BEGIN
    blc_log_pkg.initialize( pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    l_log_module := C_DEFAULT_MODULE||'.Process_Bank_Stmt';
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of function Process_Bank_Stmt' );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_bank_stmt_id = ' || pi_bank_stmt_id );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_legal_entity_id = ' || pi_legal_entity_id );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_org_id = ' || pi_org_id );
    --
    IF pi_bank_stmt_id IS NULL
    THEN
        RETURN;
    END IF;
    --
    l_bank_st := NEW blc_bank_statements_type( pi_bank_stmt_id, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    IF l_bank_st.legal_entity_id IS NOT NULL
        AND pi_legal_entity_id IS NOT NULL
        AND l_bank_st.legal_entity_id <> pi_legal_entity_id
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Init_Receipt_Global_Params', 'cust_process_bank_stmt_pkg.AR.ErrLE' );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,'The bank statememnt is reserved for other Legal Entity.');
        RETURN;
    END IF;
    --
    IF l_bank_st.org_id IS NOT NULL
        AND pi_org_id IS NOT NULL
        AND l_bank_st.org_id <> pi_org_id
    THEN
        srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Init_Receipt_Global_Params', 'cust_process_bank_stmt_pkg.AR.ErrOrgID' );
        srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,'The bank statememnt is reserved for other Organization.');
        RETURN;
    END IF;
    --
    IF l_bank_st.legal_entity_id IS NULL OR l_bank_st.org_id IS NULL
    THEN
        IF l_bank_st.legal_entity_id IS NULL
        THEN
            IF pi_legal_entity_id IS NULL
            THEN
                srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Init_Receipt_Global_Params', 'cust_process_bank_stmt_pkg.AR.NoLE' );
                srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
                blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,'Legal Entity is not specified');
                RETURN;
            ELSE
                l_bank_st.legal_entity_id := pi_legal_entity_id;
           END IF;
        END IF;
        IF l_bank_st.org_id IS NULL
        THEN
            IF pi_org_id IS NULL
            THEN
                srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Init_Receipt_Global_Params', 'cust_process_bank_stmt_pkg.AR.NoOrgId' );
                srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
                blc_log_pkg.insert_message(l_log_module,C_LEVEL_EXCEPTION,'Org ID is not specified');
                RETURN;
            ELSE
               l_bank_st.org_id := pi_org_id;
            END IF;
        END IF;
        --
        IF NOT l_bank_st.update_blc_bank_statements( pio_Err )
        THEN
           RAISE l_exp_error;
        END IF;
    END IF;
    --
    --
    --1st step - processing bank statement header
    SRV_PRM_PROCESS.Set_Bank_Stmt_Id( l_Context, pi_bank_stmt_id );

    srv_events.sysEvent( 'PROCESS_BLC_BANK_ST_HDR', l_Context, l_RetContext, pio_Err );

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,'pi_bank_stmt_id =' || pi_bank_stmt_id || ' - ' ||pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    --
    l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
    --
    --2nd step - executing bank statement header
    l_Context := l_RetContext;
    l_RetContext := NULL;
    --
    srv_events.sysEvent( 'EXECUTE_BLC_BANK_STATEMENT', l_Context, l_RetContext, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_bank_stmt_id =' || pi_bank_stmt_id || ' - ' || pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        RAISE l_exp_error;
    END IF;
    --
    l_procedure_result := srv_prm_process.Get_Procedure_Result( l_RetContext );
    --
    --3rd step - creating a set of receipts
    /*
    l_Context := l_RetContext;
    l_RetContext := NULL;
    --
    srv_events.sysEvent( 'CREATE_BLC_SET_OF_RCPTS', l_Context, l_RetContext, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
        FOR i IN 1..pio_Err.COUNT
        LOOP
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_bank_stmt_id =' || pi_bank_stmt_id || ' - ' || pio_Err(i).errmessage );
            l_err_message := l_err_message || pio_Err(i).errmessage || '; ';
        END LOOP;
        --
        RAISE l_exp_error;
    END IF;
    */
    --
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'END of function Process_Bank_Stmt' );
EXCEPTION
    WHEN l_exp_error THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Process_Bank_Stmt', l_err_message );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_bank_stmt_id = ' || pi_bank_stmt_id || ' - ' ||
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                  'pi_org_id = ' || pi_org_id || ' - ' ||
                                  l_err_message );
    WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Process_Bank_Stmt', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_bank_stmt_id = ' || pi_bank_stmt_id || ' - ' ||
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                  'pi_org_id = ' || pi_org_id || ' - ' ||
                                  SQLERRM );
END Process_Bank_Stmt_E;

--------------------------------------------------------------------------------
PROCEDURE Process_Bank_Stmt( pi_bank_stmt_id    IN     NUMBER,
                             pi_legal_entity_id IN     NUMBER DEFAULT NULL,
                             pi_org_id          IN     NUMBER DEFAULT NULL,
                             pio_Err            IN OUT SrvErr )
IS
    l_log_module   VARCHAR2(240);
    l_SrvErrMsg    SrvErrMsg;
    --
    l_result_flag     VARCHAR2(1) := 'Y';
    --
    l_exp_error EXCEPTION;
    l_err_message VARCHAR2(2000);

    l_procedure_result VARCHAR2(30);

    l_Context srvcontext;
    l_RetContext srvcontext;
BEGIN
    blc_log_pkg.initialize( pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    l_log_module := C_DEFAULT_MODULE||'.Process_Bank_Stmt';
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Process_Bank_Stmt' );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_bank_stmt_id = ' || pi_bank_stmt_id );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_legal_entity_id = ' || pi_legal_entity_id );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_org_id = ' || pi_org_id );
    --
    IF pi_bank_stmt_id IS NULL
    THEN RETURN;
    END IF;
    --
    -- 1st step - processing bank statement header
    blc_bank_stmt_util_pkg.Pr_Process_Bank_St_Header( pi_legal_entity_id, pi_org_id, pi_bank_stmt_id, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    --2nd step - executing bank statement header
    blc_bank_stmt_util_pkg.Pr_Execute_Bank_Statement( pi_bank_stmt_id => pi_bank_stmt_id,
                                                      pio_Err         => pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    --3rd step - creating a set of receipts
    /* No in SGI
    blc_bank_stmt_util_pkg.Pr_Create_Set_Of_Receipts( pi_bank_stmt_id, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF; */
    --
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Process_Bank_Stmt' );
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_process_bank_stmt_pkg.Process_Bank_Stmt', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, c_level_exception, 'pi_bank_stmt_id = ' || pi_bank_stmt_id || ' - ' || SQLERRM );
END Process_Bank_Stmt;
--
END CUST_PROCESS_BANK_STMT_PKG;
/


