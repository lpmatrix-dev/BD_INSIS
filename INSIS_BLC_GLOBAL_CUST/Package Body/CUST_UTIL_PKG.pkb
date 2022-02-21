CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_UTIL_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains custom functions for manipulation of BLC objects
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

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_util_pkg';
--==============================================================================

--------------------------------------------------------------------------------
-- Name: cust_util_pkg.Add_Proforma_Notes
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
--
--       pi_table_name  VARCHAR2     Table Name
--       pi_pk_value    NUMBER       Primary key value (doc_id)
--       pi_text        VARCHAR2     Note text (attrib_2)
--       pio_Err        SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err          SrvErr        Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Usage: event UPDATE_BLC_ATTRIBUTES
--------------------------------------------------------------------------------
PROCEDURE Add_Proforma_Notes( pi_table_name  IN     VARCHAR2,
                              pi_pk_value    IN     NUMBER,
                              pi_text        IN     VARCHAR2,
                              po_sbstr_text     OUT VARCHAR2,
                              pio_Err        IN OUT SrvErr )
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    l_SrvErrMsg       SrvErrMsg;
    l_log_module      VARCHAR2(240);
    --
    l_doc    BLC_DOCUMENTS_TYPE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    l_log_module := C_DEFAULT_MODULE||'.Add_Proforma_Notes';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Add_Proforma_Notes');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_table_name = '||pi_table_name);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_pk_value = '||pi_pk_value);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_text = '||pi_text);
    --
    IF UPPER(pi_table_name) = 'BLC_DOCUMENTS'
        AND pi_pk_value IS NOT NULL
        AND pi_text IS NOT NULL
    THEN
        l_doc := NEW blc_documents_type( pi_pk_value );
        --
        IF blc_common_pkg.Get_Lookup_Code(l_doc.doc_type_id) IN ( 'PROFORMA', 'REFUND-CN' )
            AND ( l_doc.attrib_2 IS NULL OR l_doc.attrib_2 <> RTRIM(SUBSTR(pi_text, 1, 120 )) )
        THEN
            blc_doc_util_pkg.Insert_Action( pi_action_type   => 'ADD_NOTES',
                                            pi_notes         => pi_text,
                                            pi_status        => 'S',
                                            pi_doc_id        => l_doc.doc_id,
                                            pio_Err          => pio_Err );
            --
            po_sbstr_text := RTRIM(SUBSTR(pi_text, 1, 120));
            --
            COMMIT;
        END IF;
    END IF;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'po_sbstr_text = '||po_sbstr_text);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Add_Proforma_Notes');
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_util_pkg.Add_Proforma_Notes', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
END Add_Proforma_Notes;
--
END CUST_UTIL_PKG;
/


