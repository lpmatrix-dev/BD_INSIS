CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.BLC_PMNT_WF_PKG AS 

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains functions used during process of payment workflow. Hire
-- you can write custom logic or use some functions from predifined libraries.
-- Functions can be associated to predefined events
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: blc_pmnt_wf_pkg.Set_Number_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.06.2012  creation
--
-- Purpose: Execute rules for payment validation
--
-- Input parameters:
--     pi_payment_id NUMBER                Payment id
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In validate payment
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: Service is associated with event 'VALIDATE_BLC_PMNT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Payment
   (pi_payment_id  IN     NUMBER,
    pio_Err        IN OUT SrvErr);
    
--------------------------------------------------------------------------------
-- Name: blc_pmnt_wf_pkg.Reverse_Payment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.06.2012  creation
--
-- Purpose: Execute additional validations for payment revresal
--
-- Input parameters:
--     pi_payment_id NUMBER                Payment id
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In validate payment
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: Service is associated with event 'REVERSE_BLC_PMNT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Reverse_Payment
   (pi_payment_id  IN     NUMBER,
    pio_Err        IN OUT SrvErr);    
--
END BLC_PMNT_WF_PKG;
/


