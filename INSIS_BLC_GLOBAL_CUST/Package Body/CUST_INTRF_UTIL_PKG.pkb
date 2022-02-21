CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_INTRF_UTIL_PKG AS

    --
    PROCEDURE Run_Send_Payment (
        pi_currency IN CHAR,
        pi_doc_number IN VARCHAR2,
        pi_ad_number IN VARCHAR2,
        pi_ad_date IN DATE,
        po_pay_id OUT NUMBER,
        po_err_code OUT VARCHAR2,
        po_err_desc OUT VARCHAR2
    ) AS
        l_Context INSIS_SYS_V10.SrvContext;
        l_RetContext INSIS_SYS_V10.SrvContext;
        l_SrvErr INSIS_SYS_V10.SrvErr;
        l_log_module VARCHAR2(240);
        l_bank_stmt_id NUMBER;
        l_line_id NUMBER;
        l_count_bs NUMBER;
        l_bs_number NUMBER;
        l_oper_date DATE;
        l_bs_numb NUMBER;
        l_bs_id NUMBER;
        l_result VARCHAR2(30);
        l_bsl_status INSIS_GEN_BLC_V10.blc_bank_statement_lines.status%TYPE;
        l_bsl_pmnt_id INSIS_GEN_BLC_V10.blc_bank_statement_lines.payment_id%TYPE;
        l_bsl_err_type INSIS_GEN_BLC_V10.blc_bank_statement_lines.err_type%TYPE;
        l_bsl_err_message INSIS_GEN_BLC_V10.blc_bank_statement_lines.err_message%TYPE;
        -- Company
        g_le_id NUMBER := 10000000;
        -- Legal Entity
        g_pmnt_org_id NUMBER := 10000001;
        p_account_number VARCHAR2(12);
        p_operation_type INSIS_GEN_BLC_V10.blc_bank_statement_lines.operation_type%TYPE := 'CREDIT_TRANSFER';
        p_amount NUMBER;
        p_doc_type VARCHAR2(12); --Defect 398 LPV MATRIX 27.05.2021
    BEGIN
        DBMS_OUTPUT.put_line('<CUST_INTRF_UTIL_PKG.Run_Send_Payment>');
        DBMS_OUTPUT.put_line('(p) pi_currency=' || pi_currency);
        DBMS_OUTPUT.put_line('(p) pi_doc_number=' || pi_doc_number);
        DBMS_OUTPUT.put_line('(p) pi_ad_number=' || pi_ad_number);
        DBMS_OUTPUT.put_line('(p) pi_ad_date=' || pi_ad_date);
        --
        INSIS_SYS_V10.srv_context.setContextAttrChar(
            l_Context,
            'USERNAME',
            'insis_gen_v10'
        );
        INSIS_SYS_V10.srv_context.setContextAttrChar(
            l_Context,
            'USER_ENT_ROLE',
            'InsisStaff'
        );
        INSIS_SYS_V10.srv_events.sysEvent(
            INSIS_SYS_V10.srv_events_system.GET_CONTEXT,
            l_Context,
            l_RetContext,
            l_srvErr
        );
        --
        IF
            NOT INSIS_SYS_V10.srv_error.rqStatus(l_srvErr)
        THEN
            DBMS_OUTPUT.put_line('RETURN');
            RETURN;
        END IF;
        -- get current oper date;
        l_oper_date := nvl(
            blc_common_pkg.Get_Oper_Date(pi_org_id => g_LE_id),
            blc_appl_cache_pkg.g_to_date
        );
        DBMS_OUTPUT.put_line('l_oper_date=' || l_oper_date);
        -- check if BS for current operating date is existing
        IF
            l_oper_date IS NULL
        THEN
            DBMS_OUTPUT.put_line('l_oper_date IS NULL');
            --
            RETURN;
        END IF;

        BEGIN --Defect 398 LPV MATRIX 27.05.2021
              SELECT
                  ABS(DOC_AMOUNT),
                  CASE
                          WHEN DOC_AMOUNT > 0 THEN 'IN_SAP_BANK'
                          ELSE 'OUT_SAP_BANK'
                  END,
                 'PROFORMA'
              INTO
                  p_amount, p_account_number, p_doc_type --Defect 398 LPV MATRIX 27.05.2021 Add p_doc_type
              FROM
                  BLC_PROFORMA_GEN
              WHERE
                  ltrim(
                      DOC_NUMBER,
                      '0'
                  ) = pi_doc_number;
        --BEGIN Defect 398 LPV MATRIX 27.05.2021
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_amount := NULL;
            p_account_number := NULL;
        END;
        --END Defect 398 LPV MATRIX 27.05.2021
        DBMS_OUTPUT.put_line('p_amount=' || p_amount);
        DBMS_OUTPUT.put_line('p_account_number=' || p_account_number);
        --BEGIN Defect 398 LPV MATRIX 27.05.2021
        IF p_amount IS NULL THEN
              BEGIN
                    SELECT
                        ABS(AMOUNT),
                        CASE
                                WHEN AMOUNT > 0 THEN 'IN_SAP_BANK'
                                ELSE 'OUT_SAP_BANK'
                        END,
                        'LOAN'
                    INTO
                        p_amount, p_account_number, p_doc_type
                    FROM
                        INSIS_GEN_BLC_V10.BLC_DOCUMENTS
                    WHERE
                        ltrim(
                            DOC_NUMBER,
                            '0'
                        ) = pi_doc_number;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  RAISE_APPLICATION_ERROR(-20006,'Run_Send_Payment DATA NOT FOUND (DOC_NUMBER). SEARCH VALUE: ' || pi_doc_number);
              END;
        END IF;
        --END 398 LPV MATRIX 27.05.2021
        IF
            p_account_number = 'IN_SAP_BANK'
        THEN
            l_bs_numb := 100;
        ELSE
            l_bs_numb := 200;
        END IF;
        --
        IF
            trim(pi_currency) <> 'PEN'
        THEN
            l_bs_numb := l_bs_numb + 1;
        END IF;
        --
        l_bs_numb := l_bs_numb * 100000000 + to_number(TO_CHAR(
            l_oper_date,
            'yyyymmdd'
        ) );
        --
        DBMS_OUTPUT.put_line('l_bs_numb=' || l_bs_numb);
        --
        SELECT
            MAX(bank_stmt_id)
        INTO
            l_bs_id
        FROM
            blc_bank_statements
        WHERE
            bank_stmt_num = l_bs_numb;
        --
        l_bs_id := nvl(
            l_bs_id,
            0
        );
        DBMS_OUTPUT.put_line('l_bs_id=' || l_bs_id);
        --
        IF
            l_bs_id > 0
        THEN
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_ID',
                srv_context.Integers_Format,
                l_bs_id
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_NUM',
                srv_context.Integers_Format,
                NULL
            );
        ELSE
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_ID',
                srv_context.Integers_Format,
                NULL
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_NUM',
                srv_context.Integers_Format,
                l_bs_numb
            );
        END IF;
        -- Creation of a new line in the related BS
        srv_context.setContextAttrChar(
            l_Context,
            'ACCOUNT_NUMBER',
            p_account_number
        );
        DBMS_OUTPUT.put_line('ACCOUNT_NUMBER=' || p_account_number);
        srv_context.setContextAttrChar(
            l_Context,
            'CURRENCY',
            trim(pi_currency)
        );
        DBMS_OUTPUT.put_line('CURRENCY=' || trim(pi_currency) );
        srv_context.setContextAttrChar(
            l_Context,
            'OPERATION_TYPE',
            p_operation_type
        );
        DBMS_OUTPUT.put_line('OPERATION_TYPE=' || p_operation_type);
        srv_context.setContextAttrDate(
            l_Context,
            'BS_DATE',
            srv_context.Date_Format,
            l_oper_date
        );
        DBMS_OUTPUT.put_line('BS_DATE=' || l_oper_date);
        srv_context.setContextAttrNumber(
            l_Context,
            'AMOUNT',
            srv_context.Real_Number_Format,
            p_amount
        );
        /*Defect 398 LPV MATRIX 27.05.2021 COMMENT
        DBMS_OUTPUT.put_line('AMOUNT=' || p_amount);
        srv_context.setContextAttrChar(
            l_Context,
            'DOC_NUMBER',
            lpad(
                pi_doc_number,
                12,
                '0'
            )
        );
        */
        --BEGIN Defect 398 LPV MATRIX 27.05.2021
        IF
            p_doc_type = 'PROFORMA'
         THEN
            srv_context.setContextAttrChar(
               l_Context,
               'DOC_NUMBER',
               lpad(
                   pi_doc_number,
                  12,
                  '0'
                )
            );
            DBMS_OUTPUT.put_line('DOC_NUMBER=' || lpad(
               pi_doc_number,
               12,
               '0'
            ) );
         ELSE
            srv_context.setContextAttrChar(
               l_Context,
               'DOC_NUMBER',
               lpad(
                   pi_doc_number,
                  10,
                  '0'
                )
            );
            DBMS_OUTPUT.put_line('DOC_NUMBER=' || lpad(
               pi_doc_number,
               10,
               '0'
            ) );
         END IF;
         --END Defect 398 LPV MATRIX 27.05.2021
        srv_context.setContextAttrChar(
            l_Context,
            'ATTRIB_3',
            pi_ad_number
        );
        DBMS_OUTPUT.put_line('ATTRIB_3=' || pi_ad_number);
        srv_context.setContextAttrChar(
            l_Context,
            'ATTRIB_4',
            TO_CHAR(
                pi_ad_date,
                'dd-mm-yyyy'
            )
        );
        DBMS_OUTPUT.put_line('ATTRIB_4=' || pi_ad_date);
        --
        srv_events.sysEvent(
            'LOAD_BLC_BS_LINE',
            l_Context,
            l_RetContext,
            l_SrvErr
        );
        --
        srv_context.GetContextAttrNumber(
            l_RetContext,
            'BANK_STMT_ID',
            l_bank_stmt_id
        );
        DBMS_OUTPUT.put_line('l_bank_stmt_id=' || l_bank_stmt_id);
        srv_context.GetContextAttrNumber(
            l_RetContext,
            'LINE_ID',
            l_line_id
        );
        DBMS_OUTPUT.put_line('l_line_id=' || l_line_id);
        --
        IF
            l_SrvErr IS NOT NULL
        THEN
            DBMS_OUTPUT.put_line('l_SrvErr IS NOT NULL');
            FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                DBMS_OUTPUT.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
            END LOOP;
        END IF;
        --
        IF
            NOT srv_error.rqStatus(l_SrvErr)
        THEN
            DBMS_OUTPUT.put_line('ROLLBACK');
            ROLLBACK;
        ELSE
            -- Execute created BS line
            srv_context.setContextAttrNumber(
                l_Context,
                'LEGAL_ENTITY_ID',
                srv_context.Integers_Format,
                g_le_id
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'ORG_ID',
                srv_context.Integers_Format,
                g_pmnt_org_id
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_ID',
                srv_context.Integers_Format,
                l_bank_stmt_id
            );
            --
            DBMS_OUTPUT.put_line('l_bs_id=' || l_bs_id);
            --
            IF
                l_bs_id = 0
            THEN
                -- Run for first time execution of newly entered bank statement
                srv_context.setContextAttrNumber(
                    l_Context,
                    'LINE_ID',
                    srv_context.Integers_Format,
                    NULL
                );
                srv_events.sysEvent(
                    'PROCESS_BLC_BANK_STATEMENT',
                    l_Context,
                    l_RetContext,
                    l_SrvErr
                );
            ELSE
                -- Run for next execution of bank statement to process newly or with error lines, if need partucular line then set LINE_ID
                srv_context.setContextAttrNumber(
                    l_Context,
                    'LINE_ID',
                    srv_context.Integers_Format,
                    l_line_id
                );
                srv_events.sysEvent(
                    'EXECUTE_BLC_BANK_STATEMENT',
                    l_Context,
                    l_RetContext,
                    l_SrvErr
                );
            END IF;
            --
            srv_context.GetContextAttrChar(
                l_RetContext,
                'PROCEDURE_RESULT',
                l_result
            );
            DBMS_OUTPUT.put_line('l_result=' || l_result);
            /* FIXME */
            -- UPDATE PAYMENT ID (l_result) IN THE LOG TABLE
            -- update edf set abc = l_result where edf.proforma_number = p_pro_number;
            IF
                NOT srv_error.rqStatus(l_SrvErr)
            THEN
                DBMS_OUTPUT.put_line('ROLLBACK');
                ROLLBACK;
                IF
                    l_SrvErr IS NOT NULL
                THEN
                    FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                        DBMS_OUTPUT.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
                    END LOOP;
                END IF;
            ELSE
                -- Get information for the result of execution of BS line
                SELECT
                    status,
                    payment_id,
                    err_type,
                    err_message
                INTO
                    l_bsl_status, l_bsl_pmnt_id, l_bsl_err_type, l_bsl_err_message
                FROM
                    INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES
                WHERE
                    LINE_ID = l_line_id;
                --
                DBMS_OUTPUT.put_line('l_bsl_status = ' || l_bsl_status);
                --
                IF
                    l_bsl_status <> 'P'
                THEN
                    ROLLBACK;
                    DBMS_OUTPUT.put_line('err_type = ' || l_bsl_err_type);
                    DBMS_OUTPUT.put_line('err_message = ' || l_bsl_err_message);
                    --
                    po_pay_id := NULL;
                    po_err_code := l_bsl_err_type;
                    po_err_desc := substr(l_bsl_err_message,1,255);
                ELSE
                    COMMIT;
                    DBMS_OUTPUT.put_line('payment_id = ' || l_bsl_pmnt_id);
                    --
                    po_pay_id := l_bsl_pmnt_id;
                    po_err_code := NULL;
                    po_err_desc := NULL;
                END IF;
            END IF;
        END IF;
        DBMS_OUTPUT.put_line('</Run_Send_Payment>');
    END Run_Send_Payment;

    --
    -- Changed Fadata 24.07.2019 CSR: 142 Jira: LPVS-155
    --
    PROCEDURE Run_Reverse_Payment (
        pi_pay_id IN NUMBER,
        pi_currency IN CHAR,
        pi_doc_number IN VARCHAR2,
        pi_ad_number IN VARCHAR2,
        pi_ad_date IN DATE,
        po_pay_id OUT NUMBER,
        po_err_code OUT VARCHAR2,
        po_err_desc OUT VARCHAR2
    ) AS
        l_Context INSIS_SYS_V10.SrvContext;
        l_RetContext INSIS_SYS_V10.SrvContext;
        l_SrvErr INSIS_SYS_V10.SrvErr;
        l_log_module VARCHAR2(240);
        l_bank_stmt_id NUMBER;
        l_line_id NUMBER;
        l_count_bs NUMBER;
        l_bs_number NUMBER;
        l_oper_date DATE;
        l_bs_numb NUMBER;
        l_bs_id NUMBER;
        l_result VARCHAR2(30);
        l_payment_prefix BLC_PAYMENTS.PAYMENT_PREFIX%TYPE;
        l_payment_number BLC_PAYMENTS.PAYMENT_NUMBER%TYPE;
        l_payment_suffix BLC_PAYMENTS.PAYMENT_SUFFIX%TYPE;
        l_amount INSIS_GEN_BLC_V10.blc_payments.amount%TYPE;
        l_bsl_status INSIS_GEN_BLC_V10.blc_bank_statement_lines.status%TYPE;
        l_bsl_pmnt_id INSIS_GEN_BLC_V10.blc_bank_statement_lines.payment_id%TYPE;
        l_bsl_err_type INSIS_GEN_BLC_V10.blc_bank_statement_lines.err_type%TYPE;
        l_bsl_err_message INSIS_GEN_BLC_V10.blc_bank_statement_lines.err_message%TYPE;
        g_le_id NUMBER := 10000000;
        -- Company
        g_pmnt_org_id NUMBER := 10000001;
        -- Legal Entity
        p_account_number VARCHAR2(12) := 'IN_SAP_BANK';
        p_operation_type INSIS_GEN_BLC_V10.blc_bank_statement_lines.operation_type%TYPE := 'REVERSE';
        p_rev_reason_code VARCHAR2(16) := 'IP_REVERSE';
        --p_payment_id NUMBER;
    BEGIN
        INSIS_SYS_V10.srv_context.setContextAttrChar(
            l_Context,
            'USERNAME',
            'insis_gen_v10'
        );
        INSIS_SYS_V10.srv_context.setContextAttrChar(
            l_Context,
            'USER_ENT_ROLE',
            'InsisStaff'
        );
        INSIS_SYS_V10.srv_events.sysEvent(
            INSIS_SYS_V10.srv_events_system.GET_CONTEXT,
            l_Context,
            l_RetContext,
            l_srvErr
        );
        --
        IF
            NOT INSIS_SYS_V10.srv_error.rqStatus(l_srvErr)
        THEN
            RETURN;
        END IF;
        -- get current oper date;
        l_oper_date := nvl(
            blc_common_pkg.Get_Oper_Date(pi_org_id => g_LE_id),
            blc_appl_cache_pkg.g_to_date
        );
        --
        IF
            l_oper_date IS NULL
        THEN
            RETURN;
        END IF;
        -- CSR: 142 Jira: LPVS-155 move select payment and add calculate account_number
        -- Get payment amount
        DBMS_OUTPUT.put_line('pi_pay_id=' || pi_pay_id);
        SELECT
            payment_prefix,
            payment_number,
            payment_suffix,
            amount,
            CASE WHEN SUBSTR( payment_class, 1,1 ) = 'I' THEN 'IN_SAP_BANK'
                ELSE 'OUT_SAP_BANK'
            END AS account_number
        INTO
            l_payment_prefix, l_payment_number, l_payment_suffix, l_amount, p_account_number
        FROM
            INSIS_GEN_BLC_V10.blc_payments
        WHERE
            payment_id = pi_pay_id;
        --
        -- check if BS for current operating date is existing;
        IF
            p_account_number = 'IN_SAP_BANK'
        THEN
            l_bs_numb := 100;
        ELSE
            l_bs_numb := 200;
        END IF;
        --
        IF
            trim(pi_currency) <> 'PEN'
        THEN
            l_bs_numb := l_bs_numb + 1;
        END IF;
        --
        l_bs_numb := l_bs_numb * 100000000 + to_number(TO_CHAR(
            l_oper_date,
            'yyyymmdd'
        ) );
        --
        SELECT
            MAX(bank_stmt_id)
        INTO
            l_bs_id
        FROM
            blc_bank_statements
        WHERE
            bank_stmt_num = l_bs_numb;
        l_bs_id := nvl(
            l_bs_id,
            0
        );
        --
        IF
            l_bs_id > 0
        THEN
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_ID',
                srv_context.Integers_Format,
                l_bs_id
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_NUM',
                srv_context.Integers_Format,
                NULL
            );
        ELSE
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_ID',
                srv_context.Integers_Format,
                NULL
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_NUM',
                srv_context.Integers_Format,
                l_bs_numb
            );
        END IF;
        /* CSR: 142 Jira: LPVS-155 move select from the beginning on the procedure
        -- Get payment amount
        DBMS_OUTPUT.put_line('pi_pay_id=' || pi_pay_id);
        SELECT
            payment_prefix,
            payment_number,
            payment_suffix,
            amount
            --, bank_code, bank_account_code
        INTO
            l_payment_prefix, l_payment_number, l_payment_suffix, l_amount
            --, l_ben_bank_code, l_ben_bank_acct
        FROM
            INSIS_GEN_BLC_V10.blc_payments
        WHERE
            payment_id = pi_pay_id; */

        -- Creation of a new line in the related BS
        srv_context.setContextAttrChar(
            l_Context,
            'ACCOUNT_NUMBER',
            p_account_number
        );
        srv_context.setContextAttrChar(
            l_Context,
            'CURRENCY',
            trim(pi_currency)
        );
        srv_context.setContextAttrChar(
            l_Context,
            'OPERATION_TYPE',
            p_operation_type
        );
        srv_context.setContextAttrDate(
            l_Context,
            'BS_DATE',
            srv_context.Date_Format,
            l_oper_date
        );
        srv_context.setContextAttrChar(
            l_Context,
            'ATTRIB_3',
            pi_ad_number
        );
        srv_context.setContextAttrChar(
            l_Context,
            'ATTRIB_4',
            pi_ad_date
        );
        srv_context.setContextAttrChar(
            l_Context,
            'REV_REASON_CODE',
            p_rev_reason_code
        );
        srv_context.setContextAttrNumber(
            l_Context,
            'AMOUNT',
            srv_context.Real_Number_Format,
            l_amount
        );
        srv_context.setContextAttrChar(
            l_Context,
            'PAYMENT_PREFIX',
            l_payment_prefix
        );
        srv_context.setContextAttrChar(
            l_Context,
            'PAYMENT_NUMBER',
            l_payment_number
        );
        srv_context.setContextAttrChar(
            l_Context,
            'PAYMENT_SUFFIX',
            l_payment_suffix
        );
        --
        srv_events.sysEvent(
            'LOAD_BLC_BS_LINE',
            l_Context,
            l_RetContext,
            l_SrvErr
        );
        --
        srv_context.GetContextAttrNumber(
            l_RetContext,
            'BANK_STMT_ID',
            l_bank_stmt_id
        );
        DBMS_OUTPUT.put_line('l_bank_stmt_id = ' || l_bank_stmt_id);
        srv_context.GetContextAttrNumber(
            l_RetContext,
            'LINE_ID',
            l_line_id
        );
        DBMS_OUTPUT.put_line('l_line_id = ' || l_line_id);
        --
        IF
            NOT srv_error.rqStatus(l_SrvErr)
        THEN
            ROLLBACK;
            DBMS_OUTPUT.put_line('ROLLBACK');
            --
            IF
                l_SrvErr IS NOT NULL
            THEN
                FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                    DBMS_OUTPUT.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
                END LOOP;
            END IF;
        ELSE
            srv_context.setContextAttrNumber(
                l_Context,
                'LEGAL_ENTITY_ID',
                srv_context.Integers_Format,
                g_le_id
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'ORG_ID',
                srv_context.Integers_Format,
                g_pmnt_org_id
            );
            srv_context.setContextAttrNumber(
                l_Context,
                'BANK_STMT_ID',
                srv_context.Integers_Format,
                l_bank_stmt_id
            );
            --
            IF
                l_bs_id = 0
            THEN
                -- Run for first time execution of newly entered bank statement
                srv_context.setContextAttrNumber(
                    l_Context,
                    'LINE_ID',
                    srv_context.Integers_Format,
                    NULL
                );
                -- Execute created BS line
                srv_events.sysEvent(
                    'PROCESS_BLC_BANK_STATEMENT',
                    l_Context,
                    l_RetContext,
                    l_SrvErr
                );
            ELSE
                -- Run for next execution of bank statement to process newly or with error lines, if need partucular line then set LINE_ID
                srv_context.setContextAttrNumber(
                    l_Context,
                    'LINE_ID',
                    srv_context.Integers_Format,
                    l_line_id
                );
                --
                srv_events.sysEvent(
                    'EXECUTE_BLC_BANK_STATEMENT',
                    l_Context,
                    l_RetContext,
                    l_SrvErr
                );
            END IF;
            --
            srv_context.GetContextAttrChar(
                l_RetContext,
                'PROCEDURE_RESULT',
                l_result
            );
            DBMS_OUTPUT.put_line('l_result = ' || l_result);
            --
            IF
                NOT srv_error.rqStatus(l_SrvErr)
            THEN
                ROLLBACK;
                DBMS_OUTPUT.put_line('ROLLBACK');
                --
                IF
                    l_SrvErr IS NOT NULL
                THEN
                    FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                        DBMS_OUTPUT.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
                    END LOOP;
                END IF;
            ELSE
                -- Get information for the result of execution of BS line
                SELECT
                    status,
                    payment_id,
                    err_type,
                    err_message
                INTO
                    l_bsl_status, l_bsl_pmnt_id, l_bsl_err_type, l_bsl_err_message
                FROM
                    INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES
                WHERE
                    LINE_ID = l_line_id;
                DBMS_OUTPUT.put_line('status = ' || l_bsl_status);
                DBMS_OUTPUT.put_line('payment_id = ' || l_bsl_pmnt_id);
                --
                IF
                    l_bsl_status <> 'P'
                THEN
                    ROLLBACK;
                    --
                    DBMS_OUTPUT.put_line('err_type = ' || l_bsl_err_type);
                    DBMS_OUTPUT.put_line('err_message = ' || l_bsl_err_message);
                    --
                    po_pay_id := NULL;
                    po_err_code := l_bsl_err_type;
                    po_err_desc := substr(l_bsl_err_message,1,255);
                ELSE
                    COMMIT;
                    --
                    po_pay_id := l_bsl_pmnt_id;
                    po_err_code := NULL;
                    po_err_desc := NULL;
                END IF;
            END IF;
        END IF;
    END Run_Reverse_Payment;

    --
    PROCEDURE Run_Process_AD (
        pi_doc_id IN NUMBER,
        pi_action_type IN VARCHAR2,
        pi_ad_number IN VARCHAR2,
        pi_ad_date IN DATE,
        pi_action_reason IN VARCHAR2,
        po_result OUT VARCHAR2,
        po_err_desc OUT VARCHAR2
    ) AS
        l_Context INSIS_SYS_V10.SrvContext;
        l_RetContext INSIS_SYS_V10.SrvContext;
        l_SrvErr INSIS_SYS_V10.SrvErr;
        l_result VARCHAR2(30);
        l_bsl_err_message VARCHAR2(2000) := ' ';
    BEGIN
        INSIS_SYS_V10.srv_context.setContextAttrChar(
            l_Context,
            'USERNAME',
            'insis_gen_v10'
        );
        INSIS_SYS_V10.srv_context.setContextAttrChar(
            l_Context,
            'USER_ENT_ROLE',
            'InsisStaff'
        );
        --
        INSIS_SYS_V10.srv_events.sysEvent(
            INSIS_SYS_V10.srv_events_system.GET_CONTEXT,
            l_Context,
            l_RetContext,
            l_srvErr
        );
        --
        IF
            NOT INSIS_SYS_V10.srv_error.rqStatus(l_srvErr)
        THEN
            po_result := 'Error set sysEvent';
            RETURN;
        END IF;
        --
        DBMS_OUTPUT.PUT_LINE('pi_doc_id: ' || pi_doc_id);
        srv_context.setContextAttrNumber(
            l_Context,
            'DOC_ID',
            srv_context.Integers_Format,
            pi_doc_id
        );
        srv_context.setContextAttrChar(
            l_Context,
            'ACTION_TYPE',
            pi_action_type
        );
        srv_context.setContextAttrChar(
            l_Context,
            'AD_NUMBER',
            pi_ad_number
        );
        srv_context.setContextAttrDate(
            l_Context,
            'AD_DATE',
            srv_context.Date_Format,
            pi_ad_date
        );
        srv_context.setContextAttrChar(
            l_Context,
            'ACTION_REASON',
            pi_action_reason
        );
        --
        srv_events.sysEvent(
            'CUST_BLC_SET_AD',
            l_Context,
            l_RetContext,
            l_SrvErr
        );
        --
        srv_context.GetContextAttrChar(
            l_RetContext,
            'PROCEDURE_RESULT',
            l_result
        );
        DBMS_OUTPUT.put_line('l_result = ' || l_result);
        --
        IF
            NOT srv_error.rqStatus(l_SrvErr)
        THEN
            ROLLBACK;
            --
            IF
                l_SrvErr IS NOT NULL
            THEN
                FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                    l_bsl_err_message:=l_bsl_err_message || l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage;
                    DBMS_OUTPUT.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
                END LOOP;
            END IF;
        ELSE
            COMMIT;
        END IF;
        --
        po_result := l_result;
        po_err_desc := substr(l_bsl_err_message,1,255);
    END Run_Process_AD;

    --
    PROCEDURE Lock_Doc_For_Delete (
        pi_doc_id IN NUMBER,
        pi_rev_reason IN NUMBER,
        po_procedure_result OUT VARCHAR2,
        pio_Err IN OUT SrvErr
    ) IS
        l_srv_in_context SrvContext := NULL;
        l_srv_out_context SrvContext := NULL;
        l_srv_err SrvErr := NULL;
        l_srv_err_msg SrvErrMsg;
        --
        v_companyCode NUMBER;
        v_receiptNumber NUMBER;
        l_coinsuranceCount NUMBER;
        v_coinsuranceFlag CHAR(1);
        v_anullmentDate DATE;
        v_anullmentReason NUMBER;
        --
        v_statusCode VARCHAR2(2);
        v_errorMessage VARCHAR2(500);
        --
        REC_BLC_GEN BLC_PROFORMA_GEN%ROWTYPE;
    BEGIN
        RETURN; -- add this do no call lock in test environment - Dora-24.04.2020

        DBMS_OUTPUT.put_line('pi_rev_reason=' || pi_rev_reason);
        IF
            pi_rev_reason IS NULL
        THEN
            srv_error.SetErrorMsg(
                l_srv_err_msg,
                'cust_intrf_util_pkg.Lock_Doc_For_Delete-',
                'cust_intrf_util_pkg.LDFD.No_ReverseReason'
            );
            srv_error.SetErrorMsg(
                l_srv_err_msg,
                pio_Err
            );
        ELSIF
            pi_rev_reason NOT IN (
                1,
                4,
                17,
                70,
                114
            )
        THEN
            srv_error.SetErrorMsg(
                l_srv_err_msg,
                'cust_intrf_util_pkg.Lock_Doc_For_Delete',
                'cust_intrf_util_pkg.LDFD.Inv_ReverseReason',
                pi_rev_reason
            );
            srv_error.SetErrorMsg(
                l_srv_err_msg,
                pio_Err
            );
        END IF;
        --
        IF
            NOT srv_error.rqStatus(pio_Err)
        THEN
            po_procedure_result := cust_gvar.FLG_ERROR;
            RETURN;
        ELSE
            v_anullmentReason := pi_rev_reason;
        END IF;
        DBMS_OUTPUT.put_line('v_anullmentReason=' || v_anullmentReason);
        --
        DBMS_OUTPUT.put_line('pi_doc_id=' || pi_doc_id);
        --
        SELECT
            *
        INTO
            REC_BLC_GEN
        FROM
            BLC_PROFORMA_GEN
        WHERE
            DOC_ID = pi_doc_id AND
            ACTION_TYPE IN (
                'CRE'
            ) AND
            STATUS = 'T';
        --
        DBMS_OUTPUT.put_line('ID=' || REC_BLC_GEN.ID);
        --
        v_companyCode :=
            -- FIXME Mapping
            CASE REC_BLC_GEN.LEGAL_ENTITY
                WHEN 10000000   THEN '2'
                ELSE NULL
            END;
        DBMS_OUTPUT.put_line('v_companyCode=' || v_companyCode);
        --
        v_receiptNumber := to_number(REC_BLC_GEN.DOC_NUMBER);
        DBMS_OUTPUT.put_line('v_receiptNumber=' || v_receiptNumber);
        --
        BEGIN
            SELECT
                COUNT(*)
            INTO
                l_coinsuranceCount
            FROM
                BLC_PROFORMA_ACC
            WHERE
                ID = REC_BLC_GEN.ID AND
                INTER_TYPE = 'COINSURER';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_coinsuranceCount := 0;
        END;
        DBMS_OUTPUT.put_line('l_coinsuranceCount=' || l_coinsuranceCount);
        --
        v_coinsuranceFlag :=
            CASE
                WHEN l_coinsuranceCount > 0 THEN 'X'
                ELSE ' '
            END;
        DBMS_OUTPUT.put_line('v_coinsuranceFlag=' || v_coinsuranceFlag);
        --v_anullmentDate := REC_BLC_GEN.DOC_REVERSE_DATE;
        v_anullmentDate := nvl(
            blc_common_pkg.Get_Oper_Date(pi_org_id => REC_BLC_GEN.LEGAL_ENTITY),
            blc_appl_cache_pkg.g_to_date
        );
        DBMS_OUTPUT.put_line('v_anullmentDate=' || v_anullmentDate);
        --
        --srv_context.setContextAttrChar( l_srv_in_context, 'USERNAME', 'insis_gen_v10' );
        --srv_context.setContextAttrChar( l_srv_in_context, 'USER_ENT_ROLE', 'InsisStaff' );
        srv_context.setContextAttrNumber(
            l_srv_in_context,
            'COMPANY_CODE',
            srv_context.Integers_Format,
            v_companyCode
        );
        srv_context.setContextAttrNumber(
            l_srv_in_context,
            'RECEIPT_NUMBER',
            srv_context.Integers_Format,
            v_receiptNumber
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'COINSURANCE_FLAG',
            v_coinsuranceFlag
        );
        srv_context.setContextAttrDate(
            l_srv_in_context,
            'ANULLMENT_DATE',
            'yyyy-MM-dd',
            v_anullmentDate
        );
        srv_context.setContextAttrNumber(
            l_srv_in_context,
            'ANULLMENT_REASON',
            srv_context.Integers_Format,
            v_anullmentReason
        );
        --
        DBMS_OUTPUT.put_line('execute_synchronous_request: SAP_PROFORMA_HOLD');
        IF
            srv_events_utils.execute_synchronous_request(
                'SAP_PROFORMA_HOLD',
                'UE.WS.DEBUG',
                l_srv_in_context,
                l_srv_out_context,
                l_srv_err,
                20
            )
        THEN
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'STATUS_CODE',
                v_statusCode
            );
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'ERROR_MESSAGE',
                v_errorMessage
            );
            --
            DBMS_OUTPUT.put_line('v_statusCode=' || v_statusCode);
            IF
                v_statusCode = '2'
            THEN
                po_procedure_result := cust_gvar.FLG_SUCCESS;
            ELSIF
                v_statusCode = '3'
            THEN
                l_srv_err_msg := SrvErrMsg(
                    v_statusCode,
                    NULL,
                    'SAP_PROFORMA_HOLD',
                    v_errorMessage,
                    'Lock_Doc_For_Delete'
                );
                pio_Err := SrvErr(l_srv_err_msg);
                --
                po_procedure_result := cust_gvar.FLG_ERROR;
            ELSE
                po_procedure_result := NULL;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            srv_error.SetSysErrorMsg(
                l_srv_err_msg,
                'cust_intrf_util_pkg.Lock_Doc_For_Delete' || ' - pi_doc_id=' || pi_doc_id,
                SQLERRM
            );
            srv_error.SetErrorMsg(
                l_srv_err_msg,
                pio_Err
            );
            --
            po_procedure_result := cust_gvar.FLG_ERROR;
    END Lock_Doc_For_Delete;

    --
    PROCEDURE Lock_Pmnt_For_Reverse_Old (
        pi_payment_id IN NUMBER,
        po_procedure_result OUT VARCHAR2,
        pio_Err IN OUT SrvErr
    ) IS
        l_SrvErrMsg SrvErrMsg;
        l_srv_in_context SrvContext := NULL;
        l_srv_out_context SrvContext := NULL;
        l_srv_err SrvErr := NULL;
        --
        v_SapDoc VARCHAR(10);
        v_Year VARCHAR(4);
        v_voidReason VARCHAR(4) := '';
        v_Company NUMBER;
        v_Operdate DATE;
        v_errorDescription VARCHAR(300);
        v_errorCode NUMBER;
    BEGIN
        DBMS_OUTPUT.put_line('Lock_Pmnt_For_Reverse');
        DBMS_OUTPUT.put_line('pi_payment_id=' || pi_payment_id);
        --
        SELECT
            SAP_GEN.ISSUE_DATE,
            IIB_JOB.NCOMPANY,
            SUBSTR(
                SSEQUENCE_SAP,
                15,
                4
            ) AS YEAR,
            SUBSTR(
                SSEQUENCE_SAP,
                1,
                10
            ) AS SAP_DOC
        INTO
            v_Operdate, v_Company, v_Year, v_SapDoc
        FROM
            BLC_CLAIM_GEN SAP_GEN,
            INSIS_CUST_LPV.IIBTBLCLAIM_GEN IIB_GEN,
            INSIS_CUST_LPV.IIBTBLCLAIM_JOB IIB_JOB
        WHERE
            SAP_GEN.PAYMENT_ID = pi_payment_id AND
            IIB_GEN.NSEQUENCE_TRA = SAP_GEN.ID AND
            IIB_GEN.NSEQUENCE = IIB_JOB.NSEQUENCE AND
            length(SSEQUENCE_SAP) = 18;
        --
        DBMS_OUTPUT.put_line('v_Operdate='||v_Operdate);
        DBMS_OUTPUT.put_line('v_Company='||v_Company);
        DBMS_OUTPUT.put_line('v_Year='||v_Year);
        DBMS_OUTPUT.put_line('v_SapDoc='||v_SapDoc);
        --
        --srv_context.setContextAttrChar( l_srv_in_context, 'USERNAME', 'insis_gen_v10' );
        --srv_context.setContextAttrChar( l_srv_in_context, 'USER_ENT_ROLE', 'InsisStaff' );
        --
        srv_context.setContextAttrNumber(
            l_srv_in_context,
            'COMPANY',
            srv_context.Integers_Format,
            v_Company
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'SAP_DOCUMENT',
            v_SapDoc
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'YEAR',
            v_Year
        );
        srv_context.setContextAttrDate(
            l_srv_in_context,
            'DATE',
            srv_context.Date_Format,
            v_Operdate
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'VOID_REASON',
            v_voidReason
        );
        --
        IF
            srv_events_utils.execute_synchronous_request(
                'SAP_CLAIMS_HOLD',
                'UE.WS.DEBUG',
                l_srv_in_context,
                l_srv_out_context,
                l_srv_err,
                20
            )
        THEN
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'COD_NUMBER',
                v_errorCode
            );
            DBMS_OUTPUT.put_line('v_errorCode=' || v_errorCode);
            --
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'DESCRIPTION',
                v_errorDescription
            );
            DBMS_OUTPUT.put_line('v_errorDescription=' || v_errorDescription);
            --
        IF
                v_errorCode = '2'
        THEN
                po_procedure_result := cust_gvar.FLG_SUCCESS;
            ELSIF
                v_errorCode = '3'
            THEN
                l_SrvErrMsg := SrvErrMsg(
                    v_errorCode,
                    NULL,
                    'SAP_CLAIMS_HOLD',
                    v_errorDescription,
                    'Lock_PMNT_For_Delete'
                );
                --
                pio_Err := SrvErr(l_SrvErrMsg);
                po_procedure_result := cust_gvar.FLG_ERROR;
            ELSE
                po_procedure_result := NULL;
            END IF;
            END IF;
    EXCEPTION
        WHEN OTHERS THEN
            srv_error.SetSysErrorMsg(
                l_SrvErrMsg,
                'cust_intrf_util_pkg.Lock_Pmnt_For_Reverse',
                SQLERRM
            );
            srv_error.SetErrorMsg(
                l_SrvErrMsg,
                pio_Err
            );
            po_procedure_result := cust_gvar.FLG_ERROR;
    END Lock_Pmnt_For_Reverse_Old;

--------------------------------------------------------------------------------
-- Name: cust_intrf_util_pkg.Lock_Pmnt_For_Reverse
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
-- Purpose:  Execute procedure for lock for reversing given payment into SAP
--
-- Input parameters:
--     pi_payment_id          NUMBER       BLC payment identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_procedure_result    VARCHAR2     Procedure result
--                                         SUCCESS/ERROR
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to reverse(set in HOLD) payment from BLC application
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Lock_Pmnt_For_Reverse (
        pi_payment_id IN NUMBER,
        po_procedure_result OUT VARCHAR2,
        pio_Err IN OUT SrvErr
    ) IS

    l_SrvErrMsg SrvErrMsg;
    l_srv_in_context SrvContext := NULL;
    l_srv_out_context SrvContext := NULL;
    l_srv_err SrvErr := NULL;
    l_usage_type VARCHAR2(30);
    --
    v_SapDoc VARCHAR(10);
    v_Year VARCHAR(4);
    v_voidReason VARCHAR(4) := '';
    v_Company NUMBER;
    v_Operdate DATE;
    v_errorDescription VARCHAR(300);
    v_errorCode NUMBER;
BEGIN

    SELECT bu.attrib_0
    INTO l_usage_type
    FROM blc_payments bp,
         blc_bacc_usages bu
    WHERE bp.payment_id = pi_payment_id
    AND bp.usage_id = bu.usage_id;

    IF l_usage_type = 'LOAN'
    THEN
       SELECT
            SAP_LOAN.ISSUE_DATE,
            DECODE(SAP_LOAN.LEGAL_ENTITY,10000000,'2',NULL),
            SUBSTR(
                SAP_LOAN.SAP_DOC_NUMBER,
                15,
                4
            ) AS YEAR,
            SUBSTR(
                SAP_LOAN.SAP_DOC_NUMBER,
                1,
                10
            ) AS SAP_DOC
        INTO
            v_Operdate, v_Company, v_Year, v_SapDoc
        FROM
            BLC_LOAND_GEN SAP_LOAN
        WHERE SAP_LOAN.PAYMENT_ID = pi_payment_id
        AND length(SAP_LOAN.SAP_DOC_NUMBER) = 18;

        srv_context.setContextAttrNumber(
            l_srv_in_context,
            'COMPANY',
            srv_context.Integers_Format,
            v_Company
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'SAP_DOCUMENT',
            v_SapDoc
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'YEAR',
            v_Year
        );
        srv_context.setContextAttrDate(
            l_srv_in_context,
            'DATE',
            srv_context.Date_Format,
            v_Operdate
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'VOID_REASON',
            v_voidReason
        );
        --
        IF
            srv_events_utils.execute_synchronous_request(
                'SAP_LOANS_HOLD',
                'UE.WS.DEBUG',
                l_srv_in_context,
                l_srv_out_context,
                l_srv_err,
                20
            )
        THEN
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'COD_NUMBER',
                v_errorCode
            );
            DBMS_OUTPUT.put_line('v_errorCode=' || v_errorCode);
            --
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'DESCRIPTION',
                v_errorDescription
            );
            DBMS_OUTPUT.put_line('v_errorDescription=' || v_errorDescription);
            --
            IF
                v_errorCode = '2'
            THEN
                po_procedure_result := cust_gvar.FLG_SUCCESS;
            ELSIF
                v_errorCode = '3'
            THEN
                l_SrvErrMsg := SrvErrMsg(
                    v_errorCode,
                    'ERROR',
                    'SAP_LOANS_HOLD',
                    v_errorDescription,
                    'Lock_PMNT_For_Delete'
                );
                --
                pio_Err := SrvErr(l_SrvErrMsg);
                po_procedure_result := cust_gvar.FLG_ERROR;
            ELSE
                po_procedure_result := NULL;
            END IF;
         END IF;
    ELSE
        SELECT
            SAP_GEN.ISSUE_DATE,
            IIB_JOB.NCOMPANY,
            SUBSTR(
                SSEQUENCE_SAP,
                15,
                4
            ) AS YEAR,
            SUBSTR(
                SSEQUENCE_SAP,
                1,
                10
            ) AS SAP_DOC
        INTO
            v_Operdate, v_Company, v_Year, v_SapDoc
        FROM
            BLC_CLAIM_GEN SAP_GEN,
            INSIS_CUST_LPV.IIBTBLCLAIM_GEN IIB_GEN,
            INSIS_CUST_LPV.IIBTBLCLAIM_JOB IIB_JOB
        WHERE
            SAP_GEN.PAYMENT_ID = pi_payment_id AND
            IIB_GEN.NSEQUENCE_TRA = SAP_GEN.ID AND
            IIB_GEN.NSEQUENCE = IIB_JOB.NSEQUENCE AND
            length(SSEQUENCE_SAP) = 18;
        --
        --DBMS_OUTPUT.put_line('v_Operdate='||v_Operdate);
        --DBMS_OUTPUT.put_line('v_Company='||v_Company);
        --DBMS_OUTPUT.put_line('v_Year='||v_Year);
        --DBMS_OUTPUT.put_line('v_SapDoc='||v_SapDoc);
        --
        --srv_context.setContextAttrChar( l_srv_in_context, 'USERNAME', 'insis_gen_v10' );
        --srv_context.setContextAttrChar( l_srv_in_context, 'USER_ENT_ROLE', 'InsisStaff' );
        --
        srv_context.setContextAttrNumber(
            l_srv_in_context,
            'COMPANY',
            srv_context.Integers_Format,
            v_Company
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'SAP_DOCUMENT',
            v_SapDoc
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'YEAR',
            v_Year
        );
        srv_context.setContextAttrDate(
            l_srv_in_context,
            'DATE',
            srv_context.Date_Format,
            v_Operdate
        );
        srv_context.setContextAttrChar(
            l_srv_in_context,
            'VOID_REASON',
            v_voidReason
        );
        --
        IF
            srv_events_utils.execute_synchronous_request(
                'SAP_CLAIMS_HOLD',
                'UE.WS.DEBUG',
                l_srv_in_context,
                l_srv_out_context,
                l_srv_err,
                20
            )
        THEN
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'COD_NUMBER',
                v_errorCode
            );
            DBMS_OUTPUT.put_line('v_errorCode=' || v_errorCode);
            --
            srv_context.getContextAttrChar(
                l_srv_out_context,
                'DESCRIPTION',
                v_errorDescription
            );
            DBMS_OUTPUT.put_line('v_errorDescription=' || v_errorDescription);
            --
            IF
                v_errorCode = '2'
            THEN
                po_procedure_result := cust_gvar.FLG_SUCCESS;
            ELSIF
                v_errorCode = '3'
            THEN
                l_SrvErrMsg := SrvErrMsg(
                    v_errorCode,
                    'ERROR', --NULL,
                    'SAP_CLAIMS_HOLD',
                    v_errorDescription,
                    'Lock_PMNT_For_Delete'
                );
                --
                pio_Err := SrvErr(l_SrvErrMsg);
                po_procedure_result := cust_gvar.FLG_ERROR;
            ELSE
                po_procedure_result := NULL;
            END IF;
         END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
            srv_error.SetSysErrorMsg(
                l_SrvErrMsg,
                'cust_intrf_util_pkg.Lock_Pmnt_For_Reverse',
                SQLERRM
            );
            srv_error.SetErrorMsg(
                l_SrvErrMsg,
                pio_Err
            );
            po_procedure_result := cust_gvar.FLG_ERROR;
END Lock_Pmnt_For_Reverse;

    --
    PROCEDURE Blc_Process_Ip_Result (
        pi_header_id IN NUMBER,
        pi_header_table IN VARCHAR2,
        -->pi_line_number_from IN NUMBER,
        -->pi_line_number_to IN NUMBER,
        pi_status IN VARCHAR2,
        pi_sap_doc_number IN VARCHAR2,
        pi_error_type IN VARCHAR2,
        pi_error_msg IN VARCHAR2,
        pi_process_start IN DATE,
        pi_process_end IN DATE
    ) IS
        l_Context insis_sys_v10.SrvContext;
        l_RetContext insis_sys_v10.SrvContext;
        l_SrvErr insis_sys_v10.SrvErr;
        l_err_message     VARCHAR2(2048); --LPVS-42
    BEGIN
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'USERNAME',
            'insis_gen_v10'
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'USER_ENT_ROLE',
            'InsisStaff'
        );
        --
        insis_sys_v10.srv_events.sysEvent(
            insis_sys_v10.srv_events_system.GET_CONTEXT,
            l_Context,
            l_RetContext,
            l_srvErr
        );
        --
        --LPVS-42
        /*
        IF
            NOT insis_sys_v10.srv_error.rqStatus(l_srvErr)
        THEN
            RETURN;
        END IF;
        */
        --
        insis_sys_v10.srv_context.SetContextAttrNumber(
            l_Context,
            'HEADER_ID',
            insis_sys_v10.srv_context.Integers_Format,
            pi_header_id
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'HEADER_TABLE',
            pi_header_table
        );
        -->insis_sys_v10.srv_context.SetContextAttrNumber(
        -->    l_Context,
        -->    'LINE_NUMBER_FROM',
        -->    insis_sys_v10.srv_context.Integers_Format,
        -->    pi_header_id
        -->);
        -->insis_sys_v10.srv_context.SetContextAttrNumber(
        -->    l_Context,
        -->    'LINE_NUMBER_TO',
        -->    insis_sys_v10.srv_context.Integers_Format,
        -->    pi_header_id
        -->);
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'STATUS',
            pi_status
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'SAP_DOC_NUMBER',
            pi_sap_doc_number
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'ERROR_TYPE',
            pi_error_type
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'ERROR_MSG',
            pi_error_msg
        );
        insis_sys_v10.srv_context.SetContextAttrDate(
            l_Context,
            'PROCESS_START_DATE',
            srv_context.Date_Format,
            pi_process_start
        );
        insis_sys_v10.srv_context.SetContextAttrDate(
            l_Context,
            'PROCESS_END_DATE',
            srv_context.Date_Format,
            pi_process_end
        );
        --
        SAVEPOINT PROCESS_RESULT;

        insis_sys_v10.srv_events.sysEvent(
            'CUST_BLC_PROCESS_IP_RESULT',
            l_Context,
            l_RetContext,
            l_SrvErr
        );
        --
        --begin LPVS-42 - remove commit, add raise application error and return to savepoint
        /*
        IF
            l_SrvErr IS NOT NULL
        THEN
            ROLLBACK;
            --
            FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                dbms_output.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
            END LOOP;
        ELSE
            COMMIT;
        END IF;
        */

        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
           ROLLBACK TO PROCESS_RESULT;
           FOR i IN 1..l_SrvErr.COUNT
           LOOP
              IF i = 1
              THEN
                 l_err_message := substr(l_SrvErr(i).errcode||'-'||l_SrvErr(i).errmessage,1,2048);
              ELSIF length(l_err_message) < 2048
              THEN
                 l_err_message := substr(l_err_message||'; '||l_SrvErr(i).errcode||'-'||l_SrvErr(i).errmessage,1,2048);
              END IF;
           END LOOP;
           raise_application_error(-20000,l_err_message);
        END IF;
        --end LPVS-42
    END Blc_Process_Ip_Result;

    --
    PROCEDURE Transfer_Acct_Info (
        pi_le_id IN NUMBER,
        pi_table_name IN VARCHAR2,
        pi_ip_code IN VARCHAR2,
        pi_action_type IN VARCHAR2,
        pi_priority IN VARCHAR2,
        pi_ids IN VARCHAR2,
        po_procedure_result OUT VARCHAR2,
        pio_Err IN OUT SrvErr
    ) IS
        l_SrvErrMsg SrvErrMsg;
        --
        l_process_start DATE;
        l_process_end DATE;
    BEGIN
        l_process_start := SYSDATE;
        --
        CASE
            pi_table_name
            WHEN 'BLC_PROFORMA_GEN' THEN
                INSIS_CUST_LPV.IIBPKGPRO.IIBPRCINSPRO000(
                    pi_le_id,
                    pi_priority,
                    pi_ids
                );
            WHEN 'BLC_CLAIM_GEN' THEN
                BLC_CLAIM_PKG.BLC_CLAIM_EXEC(
                    pi_le_id,
                    pi_ids
                );
            WHEN 'BLC_ACCOUNT_GEN' THEN
                BLC_ACC_PKG.BLC_ACC_EXEC(
                    pi_le_id,
                    pi_ids
                );
            WHEN 'BLC_REI_GEN' THEN
                BLC_RI_PKG.BLC_RI_EXEC(
                    pi_le_id,
                    pi_ids
                );
            ELSE
                raise_application_error(
                    -20000,
                    'pi_table_name not valid'
                );
        END CASE;
        --
        po_procedure_result := cust_gvar.FLG_SUCCESS;
    EXCEPTION
        WHEN OTHERS THEN
            /* --07.11.2019 -- Dora - remove this code, it is not useful
            l_process_end := SYSDATE;

            IF pi_table_name <> 'BLC_PROFORMA_GEN' THEN
                -- FIXME This should be done in a record-by-record basis --
            Blc_Process_Ip_Result(
                pi_header_id => pi_le_id,
                pi_header_table => pi_table_name,
                pi_status => 'E',
                pi_sap_doc_number => NULL,
                pi_error_type => 'IP_ERROR',
                pi_error_msg => SQLERRM,
                pi_process_start => l_process_start,
                pi_process_end => l_process_end
            );
            END IF;
            */
            srv_error.SetSysErrorMsg(
                l_SrvErrMsg,
                'cust_intrf_util_pkg.Transfer_Acct_Info' || ' - pi_table_name = ' || pi_table_name,
                SQLERRM
            );
            srv_error.SetErrorMsg(
                l_SrvErrMsg,
                pio_Err
            );
            --
            po_procedure_result := cust_gvar.FLG_ERROR;
    END Transfer_Acct_Info;

PROCEDURE Blc_Process_Ip_Result_2 (
        pi_header_id IN NUMBER,
        pi_header_table IN VARCHAR2,
        pi_line_number_from IN NUMBER,
        pi_line_number_to IN NUMBER,
        pi_status IN VARCHAR2,
        pi_sap_doc_number IN VARCHAR2,
        pi_error_type IN VARCHAR2,
        pi_error_msg IN VARCHAR2,
        pi_process_start IN DATE,
        pi_process_end IN DATE
    ) IS
        l_Context insis_sys_v10.SrvContext;
        l_RetContext insis_sys_v10.SrvContext;
        l_SrvErr insis_sys_v10.SrvErr;
        l_err_message     VARCHAR2(2048); --LPVS-42
    BEGIN
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'USERNAME',
            'insis_gen_v10'
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'USER_ENT_ROLE',
            'InsisStaff'
        );
        --
        insis_sys_v10.srv_events.sysEvent(
            insis_sys_v10.srv_events_system.GET_CONTEXT,
            l_Context,
            l_RetContext,
            l_srvErr
        );

        insis_sys_v10.srv_context.SetContextAttrNumber(
            l_Context,
            'HEADER_ID',
            insis_sys_v10.srv_context.Integers_Format,
            pi_header_id
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'HEADER_TABLE',
            pi_header_table
        );
        insis_sys_v10.srv_context.SetContextAttrNumber(
            l_Context,
            'LINE_NUMBER_FROM',
            insis_sys_v10.srv_context.Integers_Format,
            pi_header_id
        );
        insis_sys_v10.srv_context.SetContextAttrNumber(
            l_Context,
            'LINE_NUMBER_TO',
            insis_sys_v10.srv_context.Integers_Format,
            pi_header_id
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'STATUS',
            pi_status
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'SAP_DOC_NUMBER',
            pi_sap_doc_number
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'ERROR_TYPE',
            pi_error_type
        );
        insis_sys_v10.srv_context.SetContextAttrChar(
            l_Context,
            'ERROR_MSG',
            pi_error_msg
        );
        insis_sys_v10.srv_context.SetContextAttrDate(
            l_Context,
            'PROCESS_START_DATE',
            srv_context.Date_Format,
            pi_process_start
        );
        insis_sys_v10.srv_context.SetContextAttrDate(
            l_Context,
            'PROCESS_END_DATE',
            srv_context.Date_Format,
            pi_process_end
        );
        --
        SAVEPOINT PROCESS_RESULT;

        insis_sys_v10.srv_events.sysEvent(
            'CUST_BLC_PROCESS_IP_RESULT',
            l_Context,
            l_RetContext,
            l_SrvErr
        );

        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
           ROLLBACK TO PROCESS_RESULT;
           FOR i IN 1..l_SrvErr.COUNT
           LOOP
              IF i = 1
              THEN
                 l_err_message := substr(l_SrvErr(i).errcode||'-'||l_SrvErr(i).errmessage,1,2048);
              ELSIF length(l_err_message) < 2048
              THEN
                 l_err_message := substr(l_err_message||'; '||l_SrvErr(i).errcode||'-'||l_SrvErr(i).errmessage,1,2048);
              END IF;
           END LOOP;
           raise_application_error(-20000,l_err_message);
        END IF;
    END Blc_Process_Ip_Result_2;
--
END CUST_INTRF_UTIL_PKG;
/


