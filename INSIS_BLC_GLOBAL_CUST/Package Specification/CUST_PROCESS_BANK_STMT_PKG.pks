CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_PROCESS_BANK_STMT_PKG AS 

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
                                     pio_Err    IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_process_bank_stmt_pkg.Process_Bank_Stmt
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
PROCEDURE Process_Bank_Stmt( pi_bank_stmt_id    IN     NUMBER,
                             pi_legal_entity_id IN     NUMBER DEFAULT NULL,
                             pi_org_id          IN     NUMBER DEFAULT NULL,
                             pio_Err            IN OUT SrvErr );
--
END CUST_PROCESS_BANK_STMT_PKG;
/


