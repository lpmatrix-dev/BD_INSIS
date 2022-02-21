CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_COLL_UTIL_PKG AS

  FUNCTION Get_Amount_FC ( pi_amount IN NUMBER,
                           pi_amount_currency IN VARCHAR2,
                           pi_fc_currency IN VARCHAR2,
                           pi_fc_precision IN NUMBER,
                           pi_country IN VARCHAR2,
                           pi_rate_date IN DATE,
                           pi_rate_type IN VARCHAR2 )
  RETURN NUMBER;
--------------------------------------------------------------------------------
  PROCEDURE Execute_BDC_Strategies ( pi_legal_entity_id IN NUMBER,
                                     pi_org_id IN NUMBER,
                                     pi_to_date IN DATE,
                                     pi_agreement IN VARCHAR2,
                                     pi_account_id IN NUMBER,
                                     po_count_updated_docs OUT NUMBER,
                                     po_count_errors  OUT NUMBER,   --Add LPV-1042
                                     pio_Err IN OUT SrvErr );
--------------------------------------------------------------------------------
 -- PROCEDURE Change_Item_Hold_Flag ( pi_item_id IN NUMBER,
   --                                 pio_Err IN OUT SrvErr );
--------------------------------------------------------------------------------
  FUNCTION Register_Report_Action ( pi_doc_id IN NUMBER,
                                    pi_report_status IN VARCHAR2,
                                    pi_notes VARCHAR2,
                                    pio_Err IN OUT SrvErr )
  RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Get_Acct_Plc_Open_Bal_FC
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.09.2014  creation
--
-- Purpose: The function calculates the open balance amount in functional currency
-- for a particular account or/and a particular policy as of date.
--
-- Input parameters:
--     pi_account_id          NUMBER         Account ID
--     pi_agreement           VARCHAR2       Policy Number
--     pi_overdue_as_of_date  DATE           Overdue as of date
--     pio_Err                SrvErr         Specifies structure for passing back
--                                           the error code, error TYPE and
--                                           corresponding message.
-- Output parameters:
--   pio_Err                  SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--     Open balance amount in functional currency
--
-- Usage: In calculation policy/account open balance
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
  FUNCTION Get_Acct_Plc_Open_Bal_FC ( pi_account_id IN NUMBER,
                                      pi_agreement IN VARCHAR2,
                                      pi_overdue_as_of_date IN DATE,
                                      pio_Err IN OUT SrvErr )
  RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_util_pkg.Create_Bad_Debit
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   01.02.2018  creation
--
-- Purpose: Create bad debit notes
--
-- Input parameters:
--     pi_office        VARCHAR2    Insis Office(required)
--     pio_Err          SrvErr      Specifies structure for passing back
--                                  the error code, error TYPE and
--                                  corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr        Specifies structure for passing back
--                                 the error code, error TYPE and
--                                 corresponding message.
--
-- Usage: Close date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Bad_Debit( pi_office   IN VARCHAR2,
                            pio_Err     IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Chek_Policy_Cancel
--
-- Type: FUNCTION
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   15.12.2020   LAP85-66 comment the old function and add new logic
--
-- Purpose: If policy is canceled from other annex we will not start a new
-- cancellation process. Add new - not cancel if the policy correspond at some
-- of the parameters in the new custom table
--
-- Input parameters:
--     pi_policy_id    NUMBER     Policy Id (required)
--     pi_date         DATE       Current Date (required)
--
-- Returns: Cancel flag - Y / N
--
-- Usage: In pkg
-- When you need to check data in table insis_cust.cust_blc_bdc_cancel_params
--------------------------------------------------------------------------------
FUNCTION Chek_Policy_Cancel( pi_policy_id IN     NUMBER,
                             pi_date      IN     DATE,
                             pio_Err      IN OUT SrvErr ) RETURN VARCHAR;
--
END CUST_COLL_UTIL_PKG;
/


