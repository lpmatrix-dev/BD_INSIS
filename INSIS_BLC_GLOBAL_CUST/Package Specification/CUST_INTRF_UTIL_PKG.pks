CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_INTRF_UTIL_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during interface process
--------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Run_Send_Payment
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     Fadata   17.10.2017  creation
    --
    -- Purpose:  Execute procedure for create a proforma payment into INSIS
    --
    -- Input parameters:
    --     pi_currency         NUMBER       Currency
    --     pi_doc_number       VARCHAR2     Proforma number
    --     pi_ad_number        VARCHAR2     Billing Document number
    --     pi_ad_date          DATE         Billing Document date
    --
    -- Output parameters:
    --     po_pay_id           NUMBER(17,0) Payment ID
    --     po_err_code         VARCHAR2     Error type
    --     po_err_desc         VARCHAR2     Error description
    --
    -- Usage: Use to send a proforma payment from SAP application
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE Run_Send_Payment (
        pi_currency IN CHAR,
        pi_doc_number IN VARCHAR2,
        pi_ad_number IN VARCHAR2,
        pi_ad_date IN DATE,
        po_pay_id OUT NUMBER,
        po_err_code OUT VARCHAR2,
        po_err_desc OUT VARCHAR2
    );

    --------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Run_Reverse_Payment
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     Fadata   17.10.2017  creation
    --
    -- Purpose:  Execute procedure for reverse a proforma payment into INSIS
    --
    -- Input parameters:
    --     pi_pay_id           NUMBER(17,0) Payment ID
    --     pi_currency         NUMBER       Currency
    --     pi_doc_number       VARCHAR2     Proforma number
    --     pi_ad_number        VARCHAR2     Billing Document number
    --     pi_ad_date          DATE         Billing Document date
    --
    -- Output parameters:
    --     po_pay_id           NUMBER(17,0) Payment ID (reverse)
    --     po_err_code         VARCHAR2     Error type
    --     po_err_desc         VARCHAR2     Error description
    --
    -- Usage: Use to send a reverse a proforma payment from SAP application
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE Run_Reverse_Payment (
        pi_pay_id IN NUMBER,
        pi_currency IN CHAR,
        pi_doc_number IN VARCHAR2,
        pi_ad_number IN VARCHAR2,
        pi_ad_date IN DATE,
        po_pay_id OUT NUMBER,
        po_err_code OUT VARCHAR2,
        po_err_desc OUT VARCHAR2
    );

    --------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Run_Process_AD
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     Fadata   18.10.2017  creation
    --
    -- Purpose:
    --
    -- Input parameters:
    --
    --    pi_doc_id             NUMBER
    --    pi_action_type        VARCHAR2
    --    pi_ad_number          VARCHAR2
    --    pi_ad_date            DATE
    --    pi_action_reason      VARCHAR2
    --
    -- Output parameters:
    --     po_result            VARCHAR2    Result
	--     po_err_desc          VARCHAR2    Error description
    --
    -- Usage:
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE Run_Process_AD (
        pi_doc_id IN NUMBER,
        pi_action_type IN VARCHAR2,
        pi_ad_number IN VARCHAR2,
        pi_ad_date IN DATE,
        pi_action_reason IN VARCHAR2,
        po_result OUT VARCHAR2,
        po_err_desc OUT VARCHAR2
    );

    --------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Lock_Doc_For_Delete
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
    -- Purpose:  Execute procedure for lock for deletion given proforma document
    -- into SAP
    --
    -- Input parameters:
    --     pi_doc_id              NUMBER       BLC document identifier (required)
    --     pi_rev_reason          NUMBER       Reverse reason code:
    --                                         1    By Error
    --                                         4    Substitution
    --                                         17   Client decision
    --                                         70   Non-Payment (automatic massive dunning process)
    --                                         114  By Technical Order
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
    -- Usage: When need to delete proforma from BLC application
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE Lock_Doc_For_Delete (
        pi_doc_id IN NUMBER,
        pi_rev_reason IN NUMBER,
        po_procedure_result OUT VARCHAR2,
        pio_Err IN OUT SrvErr
    );

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
    );

    -------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Blc_Process_Ip_Result
    --
    -- Type: PROCEDURE
    --
    -- Subtype: ERROR_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTI   01.03.2018  creation
    --
    -- Purpose:  Execute procedure to inform all errors in the ST.
    --
    -- Input parameters:
    --     pi_header_id         NUMBER       Id of the header table (required)
    --     pi_header_table      VARCHAR2     BLC accounting table:
    --                                         BLC_PROFORMA_GEN
    --                                         BLC_CLAIM_GEN
    --                                         BLC_ACCOUNT_GEN
    --                                         BLC_REI_GEN
    --     pi_status            VARCHAR2     Status:
    --                                         T (transferred)
    --                                         E (error)
    --     pi_sap_doc_number    VARCHAR2     SAP Document Number
    --     pi_error_type        VARCHAR2     Error type:
    --                                         IP_ERROR
    --                                         SAP_ERROR
    --     pi_error_msg         VARCHAR2     Specifies structure for passing back
    --                                       the error code, error TYPE and
    --                                       corresponding message.
    --     pi_process_start     DATE         Process start date.
    --     pi_process_end       DATE         Process end date.
    --
    -- Usage:
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE Blc_Process_Ip_Result (
        pi_header_id IN NUMBER,
        pi_header_table IN VARCHAR2,
        pi_status IN VARCHAR2,
        pi_sap_doc_number IN VARCHAR2,
        pi_error_type IN VARCHAR2,
        pi_error_msg IN VARCHAR2,
        pi_process_start IN DATE,
        pi_process_end IN DATE
    );

    --------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Transfer_Acct_Info
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     Fadata   24.11.2017  creation
    --
    -- Purpose:  Execute procedure for transfer accounting data into SAP for given
    -- parameters. After successfully execution the records from the affected tables
    -- should be marked with status S - cust_gvar.STATUS_SENT
    --
    -- Input parameters:
    --     pi_le_id               NUMBER       BLC legal entity Id (required)
    --     pi_table_name          VARCHAR2     BLC accounting table
    --                                         BLC_PROFORMA_GEN
    --                                         BLC_CLAIM_GEN
    --                                         BLC_ACCOUNT_GEN
    --                                         BLC_REI_GEN
    --     pi_ip_code             VARCHAR2     IP code - the column IP_CODE from above table
    --     pi_action_type         VARCHAR2     Action type - the column ACTION_TYPE from above table
    --     pi_priority            VARCHAR2     Priority HIGH/MASS - the column PRIORITY from above table, use only for table BLC_PROFORMA_GEN
    --     pi_ids                 VARCHAR2     List of id - the column ID from above table
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
    -- Usage: In schedule proces for transfer accounting data to SAP
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE Transfer_Acct_Info (
        pi_le_id IN NUMBER,
        pi_table_name IN VARCHAR2,
        pi_ip_code IN VARCHAR2,
        pi_action_type IN VARCHAR2,
        pi_priority IN VARCHAR2,
        pi_ids IN VARCHAR2,
        po_procedure_result OUT VARCHAR2,
        pio_Err IN OUT SrvErr
    );

-------------------------------------------------------------------------------
    -- Name: cust_intrf_util_pkg.Blc_Process_Ip_Result
    --
    -- Type: PROCEDURE
    --
    -- Subtype: ERROR_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTI   01.03.2018  creation
    --
    -- Purpose:  Execute procedure to inform all errors in the ST.
    --
    -- Input parameters:
    --     pi_header_id         NUMBER       Id of the header table (required)
    --     pi_header_table      VARCHAR2     BLC accounting table:
    --                                         BLC_PROFORMA_GEN
    --                                         BLC_CLAIM_GEN
    --                                         BLC_ACCOUNT_GEN
    --                                         BLC_REI_GEN
    --     pi_line_number_from  NUMBER       line number from
    --     pi_line_number_to    NUMBER       line number to
    --     pi_status            VARCHAR2     Status:
    --                                         T (transferred)
    --                                         E (error)
    --     pi_sap_doc_number    VARCHAR2     SAP Document Number
    --     pi_error_type        VARCHAR2     Error type:
    --                                         IP_ERROR
    --                                         SAP_ERROR
    --     pi_error_msg         VARCHAR2     Specifies structure for passing back
    --                                       the error code, error TYPE and
    --                                       corresponding message.
    --     pi_process_start     DATE         Process start date.
    --     pi_process_end       DATE         Process end date.
    --
    -- Usage:
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
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
        pi_process_end IN DATE);

END CUST_INTRF_UTIL_PKG;
/


