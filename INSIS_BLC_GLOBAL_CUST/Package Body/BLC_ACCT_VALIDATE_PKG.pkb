CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST."BLC_ACCT_VALIDATE_PKG" AS
--------------------------------------------------------------------------------
-- Name: BLC_ACCT_VALIDATE_PKG.Validate_Create_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   05.06.2012  creation
--
-- Purpose:  Performs custom data validation before inserting an account
-- Actions:
--     1) Validates the data provided by the parameters;
--
-- Input parameters:
--     
--  pi_account_id        blc_accounts.account_id%type   Account Identificator
--  pi_party             blc_accounts.party%type        Man ID
--  pi_bill_to_site      blc_accounts.bill_to_site%type Address Id
--  pi_reference         blc_accounts.reference%type    Account Identificator of 
--                                                      the Corresponding Agent
--  pi_profile           blc_accounts.profile%type      Profile Name
--  pi_account_name      blc_accounts.profile%type      Account Name
--  pi_bill_date         blc_accounts.next_date%type    Next Billing Date
--  pi_payment_frequency NUMBER                         Payment Frequency
--  pi_account_type      blc_accounts.lookup_code%type  Account Type Code
--  pi_payment_method    blc_accounts.lookup_code%type  Payment Method Code
--  pi_billing_site_id   NUMBER                         Branch of the account 
--  pi_attrib_0          blc_accounts.attrib_0%type     Additional Information
--  pi_attrib_1          blc_accounts.attrib_1%type     Additional Information
--  pi_attrib_2          blc_accounts.attrib_2%type     Additional Information
--  pi_attrib_3          blc_accounts.attrib_3%type     Additional Information
--  pi_attrib_4          blc_accounts.attrib_4%type     Additional Information
--  pi_attrib_5          blc_accounts.attrib_5%type     Additional Information
--  pi_attrib_6          blc_accounts.attrib_6%type     Additional Information
--  pi_attrib_7          blc_accounts.attrib_7%type     Additional Information
--  pi_attrib_8          blc_accounts.attrib_8%type     Additional Information
--  pi_attrib_9          blc_accounts.attrib_9%type     Additional Information
--  
--
-- Output parameters:
--  pio_Err              SrvErr                        Specifies structure for 
--                                                     passing back the error 
--                                                     code, error TYPE and 
--                                                     corresponding message.
--
-- Returns:
-- N/A
--
-- Usage: /*TBD_COM*/
--
-- Exceptions: 
--    1) When the data passed by parameters is not valid.
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Validate_Create_Account  ( pi_account_id IN NUMBER,
                                       pi_party IN VARCHAR2,
                                       pi_bill_to_site IN VARCHAR2,
                                       pi_reference IN VARCHAR2,
                                       pi_profile IN OUT VARCHAR2,
                                       pi_account_name IN VARCHAR2,
                                       pi_bill_date IN DATE,
                                       pi_payment_frequency IN NUMBER,
                                       pi_account_type IN VARCHAR2,
                                       pi_payment_method IN VARCHAR2,
                                       pi_office IN VARCHAR2,
                                       pi_attrib_0 IN VARCHAR2,
                                       pi_attrib_1 IN VARCHAR2,
                                       pi_attrib_2 IN VARCHAR2,
                                       pi_attrib_3 IN VARCHAR2,
                                       pi_attrib_4 IN VARCHAR2,
                                       pi_attrib_5 IN VARCHAR2,
                                       pi_attrib_6 IN VARCHAR2,
                                       pi_attrib_7 IN VARCHAR2,
                                       pi_attrib_8 IN VARCHAR2,
                                       pi_attrib_9 IN VARCHAR2,
                                       pio_Err IN OUT SrvErr )  AS
    l_SrvErrMsg       SrvErrMsg;
  BEGIN
      INSIS_GEN_BLC_V10.BLC_ACCT_VALIDATE_LIB_PKG.Validate_Create_Account_1
                                     ( pi_account_id,
                                       pi_party,
                                       pi_bill_to_site,
                                       pi_reference,
                                       pi_profile,
                                       pi_account_name,
                                       pi_bill_date,
                                       pi_payment_frequency,
                                       pi_account_type,
                                       pi_payment_method,
                                       pi_office,
                                       pi_attrib_0,
                                       pi_attrib_1,
                                       pi_attrib_2,
                                       pi_attrib_3,
                                       pi_attrib_4,
                                       pi_attrib_5,
                                       pi_attrib_6,
                                       pi_attrib_7,
                                       pi_attrib_8,
                                       pi_attrib_9,
                                       pio_Err );
  EXCEPTION
    WHEN OTHERS THEN
       srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_ACCT_VALIDATE_PKG.Validate_Create_Account', SQLERRM );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
  END Validate_Create_Account;
--------------------------------------------------------------------------------
-- Name: BLC_ACCT_VALIDATE_PKG.Validate_Update_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   05.06.2012  creation
--
-- Purpose:  Performs custom data validation before updating an account
-- Actions:
--     1) Validates the data provided by the parameters;
--
-- Input parameters:
--  
-- pi_account_id                blc_accounts.account_id%type
-- pi_bill_to_site              blc_accounts.bill_to_site%type
-- pi_reference                 blc_accounts.reference%type
-- pi_profile                   blc_accounts.profile%type
-- pi_from_date                 blc_accounts.from_date%type
-- pi_to_date                   blc_accounts.to_date%type
-- pi_party                     blc_accounts.party%type
-- pi_notes                     blc_accounts.notes%type
-- pi_bill_date                 blc_accounts.next_date%type
-- pi_bill_office               blc_orgs.office%type
-- pi_coll_office               blc_orgs.office%type
-- pi_pay_office                blc_orgs.office%type
-- pi_bill_method               blc_lookups.lookup_code%type
-- pi_bill_cycle                blc_lookups.lookup_code%type
-- pi_payment_frequency         NUMBER
-- pi_bill_horizon              blc_accounts.bill_horizon%type
-- pi_min_retain_days           blc_accounts.min_retain_days%type
-- pi_max_retain_days           blc_accounts.max_retain_days%type
-- pi_due_period                blc_accounts.due_period%type
-- pi_grace_period              blc_accounts.grace_period%type
-- pi_min_bill_amount           blc_accounts.min_bill_amount%type
-- pi_min_refund_amount         blc_accounts.min_refund_amount%type
-- pi_min_amount_action         blc_lookups.lookup_code%type
-- pi_receipt_method            blc_lookups.lookup_code%type
-- pi_collection_set            blc_lookups.lookup_code%type
-- pi_interest_method           blc_lookups.lookup_code%type
-- pi_payment_method            blc_lookups.lookup_code%type
-- pi_pay_horizon               blc_accounts.pay_horizon%type
-- pi_net_horizon               blc_accounts.net_horizon%type
-- pi_pay_group                 blc_lookups.lookup_code%type
-- pi_status                    blc_lookups.lookup_code%type
-- pi_account_name              blc_accounts.profile%type
-- pi_account_type              blc_lookups.lookup_code%type
-- pi_attrib_0                  blc_accounts.attrib_0%type
-- pi_attrib_1                  blc_accounts.attrib_1%type
-- pi_attrib_2                  blc_accounts.attrib_2%type
-- pi_attrib_3                  blc_accounts.attrib_3%type
-- pi_attrib_4                  blc_accounts.attrib_4%type
-- pi_attrib_5                  blc_accounts.attrib_5%type
-- pi_attrib_6                  blc_accounts.attrib_6%type
-- pi_attrib_7                  blc_accounts.attrib_7%type
-- pi_attrib_8                  blc_accounts.attrib_8%type
-- pi_attrib_9                  blc_accounts.attrib_9%type
--  
--
-- Output parameters:
--  pio_Err              SrvErr                        Specifies structure for 
--                                                     passing back the error 
--                                                     code, error TYPE and 
--                                                     corresponding message.
--
-- Returns:
-- N/A
--
-- Usage: /*TBD_COM*/
--
-- Exceptions: 
--    1) When the data passed by parameters is not valid.
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Validate_Update_Account  ( pi_account_id IN NUMBER,
                                       pi_bill_to_site IN VARCHAR2,
                                       pi_reference IN VARCHAR2,
                                       pi_profile IN VARCHAR2,
                                       pi_from_date IN DATE,
                                       pi_to_date IN DATE,
                                       pi_party IN VARCHAR2,
                                       pi_notes IN VARCHAR2,
                                       pi_bill_date IN DATE,  --next_date
                                       pi_bill_office IN VARCHAR2,
                                       pi_coll_office IN VARCHAR2,
                                       pi_pay_office IN VARCHAR2,
                                       pi_bill_method IN VARCHAR2,
                                       pi_bill_cycle IN VARCHAR2,
                                       pi_payment_frequency IN NUMBER, --bill_period
                                       pi_bill_horizon IN NUMBER,
                                       pi_min_retain_days IN NUMBER,
                                       pi_max_retain_days IN NUMBER,
                                       pi_due_period IN NUMBER,
                                       pi_grace_period IN NUMBER,
                                       pi_min_bill_amount IN NUMBER,
                                       pi_min_refund_amount IN NUMBER,
                                       pi_min_amount_action IN VARCHAR2,
                                       pi_receipt_method IN VARCHAR2,
                                       pi_collection_set IN VARCHAR2,
                                       pi_interest_method IN VARCHAR2,
                                       pi_payment_method IN VARCHAR2,
                                       pi_pay_horizon IN NUMBER,
                                       pi_net_horizon IN NUMBER,
                                       pi_pay_group IN VARCHAR2,
                                       pi_status IN VARCHAR2,
                                       pi_account_name IN VARCHAR2,
                                       pi_account_type IN VARCHAR2,
                                       pi_attrib_0 IN VARCHAR2,
                                       pi_attrib_1 IN VARCHAR2,
                                       pi_attrib_2 IN VARCHAR2,
                                       pi_attrib_3 IN VARCHAR2,
                                       pi_attrib_4 IN VARCHAR2,
                                       pi_attrib_5 IN VARCHAR2,
                                       pi_attrib_6 IN VARCHAR2,
                                       pi_attrib_7 IN VARCHAR2,
                                       pi_attrib_8 IN VARCHAR2,
                                       pi_attrib_9 IN VARCHAR2,
                                       pio_Err IN OUT SrvErr ) AS
    l_SrvErrMsg       SrvErrMsg;
  BEGIN
      INSIS_GEN_BLC_V10.BLC_ACCT_VALIDATE_LIB_PKG.Validate_Update_Account_1 
                                     ( pi_account_id,
                                       pi_bill_to_site,
                                       pi_reference,
                                       pi_profile,
                                       pi_from_date,
                                       pi_to_date,
                                       pi_party,
                                       pi_notes,
                                       pi_bill_date,  
                                       pi_bill_office,
                                       pi_coll_office,
                                       pi_pay_office,
                                       pi_bill_method,
                                       pi_bill_cycle,
                                       pi_payment_frequency, 
                                       pi_bill_horizon,
                                       pi_min_retain_days,
                                       pi_max_retain_days,
                                       pi_due_period,
                                       pi_grace_period,
                                       pi_min_bill_amount,
                                       pi_min_refund_amount,
                                       pi_min_amount_action,
                                       pi_receipt_method,
                                       pi_collection_set,
                                       pi_interest_method,
                                       pi_payment_method,
                                       pi_pay_horizon,
                                       pi_net_horizon,
                                       pi_pay_group,
                                       pi_status,
                                       pi_account_name,
                                       pi_account_type,
                                       pi_attrib_0,
                                       pi_attrib_1,
                                       pi_attrib_2,
                                       pi_attrib_3,
                                       pi_attrib_4,
                                       pi_attrib_5,
                                       pi_attrib_6,
                                       pi_attrib_7,
                                       pi_attrib_8,
                                       pi_attrib_9,
                                       pio_Err );
  EXCEPTION
    WHEN OTHERS THEN
       srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_ACCT_VALIDATE_PKG.Validate_Update_Account', SQLERRM );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
  END Validate_Update_Account;

END BLC_ACCT_VALIDATE_PKG;
/


