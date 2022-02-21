CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST."BLC_PM_ACCT_PKG" AS
  --------------------------------------------------------------------------------
-- Name: blc_pm_acct_custom_pkg.Post_Insert
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Performs data processing after creating an account
--
-- Input parameters:
--     pi_account_id NUMBER
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr               Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--    N/A
--
-- Usage: In account cretaion process 
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Post_Insert ( pi_account_id IN NUMBER,
                          pio_Err IN OUT SrvErr
                              ) 
  AS
    l_SrvErrMsg       SrvErrMsg;
  BEGIN
      INSIS_GEN_BLC_V10.BLC_PM_ACCT_LIB_PKG.Post_Insert ( pi_account_id,
                                                            pio_Err );
  EXCEPTION
    WHEN OTHERS THEN
       srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_PM_ACCT_PKG.Post_Insert', SQLERRM );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err ); 
  END Post_Insert;
  ------------------------------------------------------------------------------
-- Name: blc_pm_acct_custom_pkg.Post_Update
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Performs data processing after updating an account
--
-- Input parameters:
--     pi_account_id NUMBER
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr               Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--    N/A
--
-- Usage: In account updating process 
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Post_Update ( pi_account_id IN NUMBER,
                          pio_Err IN OUT SrvErr
                              ) 
  AS
    l_SrvErrMsg       SrvErrMsg;
  BEGIN
      INSIS_GEN_BLC_V10.BLC_PM_ACCT_LIB_PKG.Post_Update ( pi_account_id,
                                                            pio_Err );
  EXCEPTION
    WHEN OTHERS THEN
       srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_PM_ACCT_PKG.Post_Update', SQLERRM );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err ); 
  END Post_Update;

END BLC_PM_ACCT_PKG;
/


