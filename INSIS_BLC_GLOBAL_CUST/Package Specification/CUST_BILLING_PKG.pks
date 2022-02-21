CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_BILLING_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during billing process. They can
-- be used in dynamic building of clauses for select installments,
-- create transactions and documents
--------------------------------------------------------------------------------
-- HISTORY
--
-- 21/04/2017 Fadata Creation;
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Policy_Level
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata 27.04.2017 creation
--
-- Purpose: Return policy level ENGAGEMENT/MASTER/INDIVIDUAL
--
-- Input parameters:
-- pi_policy_id NUMBER Policy ID
-- pi_annex_id NUMBER Annex ID
-- pi_policy_type VARCHAR2 Policy type
--
-- Returns: policy level
--
-- Usage: In create, update blc item
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Level
 ( pi_policy_id IN NUMBER,
 pi_annex_id IN NUMBER,
 pi_policy_type IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: INSIS_BLC_GLOBAL_CUST.cust_billing_pkg.Get_Master_Policy_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Return master policy id
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--
-- Returns: master policy id
--
-- Usage: When need to know master policy id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Master_Policy_Id
      (pi_policy_id IN NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Master_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Check if given policy is master policy
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--
-- Returns: Y/N
--
-- Usage: When need to know if master policy
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Master_Policy
      (pi_policy_id IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Item_Agreement
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Return policy item agreement depend on policy level
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--       pi_annex_id       NUMBER   Annex ID
--       pi_policy_type    VARCHAR2 Policy type
--
-- Returns: agreement
--
-- Usage: In create, update blc item
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Item_Agreement
    ( pi_policy_id   IN NUMBER,
      pi_annex_id    IN NUMBER,
      pi_policy_type IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Create_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an account to
-- modify some of the parameters.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_ACCOUNT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Create_Account ( pi_Context IN SrvContext,
                               pio_OutContext IN OUT SrvContext,
                               pio_Err IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Item_Comp
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called instead of core get item composite and do not use
-- agreement when need to get item from type POLICY
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'GET_BLC_ITEM_COMP'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Get_Item_Comp ( pi_Context IN SrvContext,
                          pio_OutContext IN OUT SrvContext,
                          pio_Err IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Create_Update_Item
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an item to
-- modify some of the parameters. Calculate billing organization.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_ITEM',
--              'MODIFY_BLC_ITEM'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Create_Update_Item ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Create_Installment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an installment to
-- modify some of the parameters. Calculate end date.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_INSTALLMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Create_Installment ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Reg_Bill_To_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation - copy from blc_billing_pkg.Get_Reg_Bill_To_Date
--                                     add case when run date is less than
--                                     account next date
--
-- Purpose: Calculate billing to date depend on billing cycle and bill period
-- for a next billing date and given run date
--
-- Input parameters:
--     pi_next_date       DATE       Current value of account attribute
--                                   next date (required)
--     pi_bill_cycle_id   NUMBER     Billing cycle identifier -
--                                   definition from lookup set BILL_CYCLES
--                                   (required)
--     pi_bill_period     NUMBER     Period of time between two consequence
--                                   bills (required)
--     pi_run_date        DATE       Billing run date (required)
--     pi_nd_offset       NUMBER     Next date offset
--     pi_nwd_offset      NUMBER     Non working date offset
--
-- Returns:
--     bill to date
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Reg_Bill_To_Date
   (pi_next_date     IN     DATE,
    pi_bill_cycle_id IN     NUMBER,
    pi_bill_period   IN     NUMBER,
    pi_run_date      IN     DATE,
    pi_nd_offset     IN     NUMBER,
    pi_nwd_offset    IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Reg_Bill_To_Date_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.06.2016  creation - rq 1000010513
--     Fadata   15.05.2017  changed - Add check if required parameters are NULL
--                                    rq 1000011006
--     Fadata   22.08.2018  changed - copy from core Get_Reg_Bill_To_Date, but
--                                    change clause nvl(pi_bill_period,0) > 0
--                                    with nvl(pi_bill_period,0) = 0
--
-- Purpose: Calculate billing to date depend on billing cycle and bill period
-- for a next billing date and given run date
--
-- Input parameters:
--     pi_next_date       DATE       Current value of account attribute
--                                   next date (required)
--     pi_bill_cycle_id   NUMBER     Billing cycle identifier -
--                                   definition from lookup set BILL_CYCLES
--                                   (required)
--     pi_bill_period     NUMBER     Period of time between two consequence
--                                   bills (required)
--     pi_run_date        DATE       Billing run date (required)
--     pi_nd_offset       NUMBER     Next date offset
--     pi_nwd_offset      NUMBER     Non working date offset
--
-- Returns:
--     bill to date
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Reg_Bill_To_Date_2
   (pi_next_date     IN     DATE,
    pi_bill_cycle_id IN     NUMBER,
    pi_bill_period   IN     NUMBER,
    pi_run_date      IN     DATE,
    pi_nd_offset     IN     NUMBER,
    pi_nwd_offset    IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Reg_Bill_Prev_To_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--
-- Purpose: Calculate previous before current billing to date depend on
-- billing cycle and bill period for a next billing date and given run date and
--
-- Input parameters:
--     pi_next_date       DATE       Current value of account attribute
--                                   next date (required)
--     pi_bill_cycle_id   NUMBER     Billing cycle identifier -
--                                   definition from lookup set BILL_CYCLES
--                                   (required)
--     pi_bill_period     NUMBER     Period of time between two consequence
--                                   bills (required)
--     pi_run_date        DATE       Billing run date (required)
--     pi_nd_offset       NUMBER     Next date offset
--     pi_nwd_offset      NUMBER     Non working date offset
--
-- Returns:
--     bill to date
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Reg_Bill_Prev_To_Date
   (pi_next_date     IN     DATE,
    pi_bill_cycle_id IN     NUMBER,
    pi_bill_period   IN     NUMBER,
    pi_run_date      IN     DATE,
    pi_nd_offset     IN     NUMBER,
    pi_nwd_offset    IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Select_Bill_Installments_2
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   25.04.2017  creation
--
-- Purpose: Select eligible installments for billing according billing run
-- parameters and additional elibility clause for parameter billing method of run
-- or for all existing billing methods, if parameter is empty
-- Update billing_run_id column in blc_installments to mark one
-- installment as selected . If external run id is given then propose that
-- instalments are already selected

-- Input parameters:
--     pi_external_run_id     NUMBER       External run id
--     pi_billing_run_id      NUMBER       Billing run identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--     po_count               NUMBER      Count of selected installments
--
-- Usage: In billing process
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Select_Bill_Installments_2
   (pi_external_run_id  IN     NUMBER,
    pi_billing_run_id   IN     NUMBER,
    pio_Err             IN OUT SrvErr,
    po_count            OUT    NUMBER);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Create_Bill_Transactions
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   07.08.2013  changed - add postprocess in group by
--     Fadata   27.12.2013  changed - add order by
--     Fadata   10.01.2014  changed - group installments by rec_rate_date depend
--                                    on setting 'RevenueRecognitionBasis' and
--                                    if transaction is in functional currency
--                                    or not
--     Fadata   04.03.2014  changed - set to null bill methods for regular
--                                    bill in run variable
--                                    rq 1000008191
--     Fadata   11.07.2014  changed - change sign of transaction amount in case
--                                    that transaction class is different from
--                                    installment class
--                                    rq 1000008835
--     Fadata   15.08.2014  changed - populate pay_way_id and pay_instr
--                                    rq 1000009023
--     Fadata   26.08.2014  changed - do not create transactions in case that
--                                    given billing method is NONE
--                                    rq 1000009066
--     Fadata   26.08.2014  changed - populate column line_number
--                                    rq 1000009258
--     Fadata   31.10.2014  changed - Add parameters fraction_type and lob in
--                                    call Calc_Pay_Way_Instr
--                                    rq 1000009291
--     Fadata   06.11.2014  changed - Change in call Calc_Pay_Way_Instr
--                                    pi_to_date to be minimum of installment
--                                    due_dates instead of transaction due date
--                                    rq 1000009317
--     Fadata   07.11.2014  changed - always call Recalculate_transaction
--                                    to populate transaction rate and rate_date
--                                    rq 1000009319
--     Fadata   06.04.2015  changed - add procedure specification, add savepoint
--                                    and rollback
--                                    rq 1000009741
--     Fadata   14.04.2015  changed - populate line_number with total_count of
--                                    transactions
--                                    rq 1000009750
--     Fadata   02.06.2015  changed - move recalculate transation after
--                                    transaction update
--                                    rq 1000009853
--     Fadata   15.08.2015  changed - get transaction org_id from installment
--                                    org_id instead of run bill_to_site_id
--                                    rq 1000009995
--     Fadata   15.08.2015  changed - get transaction org_id from installment
--                                    org_id instead of run bill_to_site_id
--                                    rq 1000009995
--     Fadata   11.11.2015  changed - when bill_site_id of run is global
--                                    organization (org_id = 0) use transaction
--                                    org_id to get transaction type
--                                    rq 1000010180
--     Fadata   24.03.2016  changed - add parameter pi_usage_acc_class and
--                                    pi_external_id when
--                                    call Calc_Pay_Way_Instr
--                                    rq 1000010381
--     Fadata   09.05.2016  changed - add bind variable for billing_run_id
--                                    rq 1000010464
--     Fadata   17.03.2017  changed - exclude lock for update for regular
--                                    billing runs
--                                    rq 1000010947
--     Fadata   25.04.2017  changed - copy from core and change to use cust
--                                    view blc_installments_item_bill
--
-- Purpose: Create biil transactions for selected installments for
-- given biling_run_id
-- Actions:
--     1) Group installments by installment_class, item_id, account_id,
--       nvl(bill_currency,currency) and additional group clause;
--     2) Calculate transaction type according classifying rule, calculate amount,
--       fc_amount and other required columns.
--       Possible statuses of created transactions are
--       'I' - Invalid because no exchange rates
--       'V' - Valid
--     3) Insert row into blc_transaction for each group;
--     4) Link installments to the created transaction as update column
--       transaction_id in blc_installments;
--     5) Execute additional transaction update statement to populate
--       transaction attributes;
-- Additional group clause, classifying rule and transaction update statement are
-- taken for parameter billing method of run or for distinct billing methods
-- of accounts for selected installments, if parameter is empty
--
-- Input parameters:
--     pi_billing_run_id      NUMBER       Billing run identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In billing process
--
-- Exceptions:
-- 1) When transaction classifying rule is empty for using billing method
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Bill_Transactions
   (pi_billing_run_id   IN     NUMBER,
    pio_Err             IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Trx_Due_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--     Fadata   10.08.2017  changed - add parameter transaction_id GAP 135
--     Fadata   10.04.2019  changed - LPVS-109
--
-- Purpose: Calculate transaction due date
-- Init legal entity before use function
--
-- Input parameters:
--     pi_transaction_id  NUMBER     Transaction identifier
--     pi_due_date        DATE       Current transaction due date (required)
--     pi_fix_due_date    VARCHAR2   Fixed due date (number between 0 and 31)
--     pi_offset_due_date VARCHAR2   Positive number added to the due date
--     pi_item_type       VARCHAR2   Item type
--     pi_bill_scope      VARCHAR2   Bill scope
--     pi_run_id          NUMBER     Run identifier
--     pi_account_id      NUMBER     Account identifier
--     pi_item_id         NUMBER     Item identifier
--
-- Returns:
--     new due date
--
-- Usage: In run billing to calculate transaction due date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Trx_Due_Date
   (pi_transaction_id   IN     NUMBER,
    pi_due_date         IN     DATE,
    pi_fix_due_date     IN     NUMBER,
    pi_offset_due_date  IN     NUMBER,
    pi_item_type        IN     VARCHAR2,
    pi_bill_scope       IN     VARCHAR2,
    pi_run_id           IN     NUMBER,
    pi_account_id       IN     NUMBER,
    pi_item_id          IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Trx_Grace_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--
-- Purpose: Calculate transaction grace date
-- Init legal entity before use function
--
-- Input parameters:
--     pi_transaction_id  NUMBER     Transaction identifier
--     pi_grace_date      DATE       Current transaction grace date (required)
--     pi_due_date        DATE       Current transaction due date (required)
--     pi_fix_due_date    VARCHAR2   Fixed due date (number between 0 and 31)
--     pi_offset_due_date VARCHAR2   Positive number added to the due date
--     pi_item_type       VARCHAR2   Item type
--     pi_bill_scope      VARCHAR2   Bill scope
--     pi_run_id          NUMBER     Run identifier
--     pi_account_id      NUMBER     Account identifier
--     pi_item_id         NUMBER     Item identifier
--
-- Returns:
--     new due date
--
-- Usage: In run billing to calculate transaction grace date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Trx_Grace_Date
   (pi_transaction_id   IN     NUMBER,
    pi_grace_date       IN     DATE,
    pi_due_date         IN     DATE,
    pi_fix_due_date     IN     NUMBER,
    pi_offset_due_date  IN     NUMBER,
    pi_item_type        IN     VARCHAR2,
    pi_bill_scope       IN     VARCHAR2,
    pi_run_id           IN     NUMBER,
    pi_account_id       IN     NUMBER,
    pi_item_id          IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Change_Account_Next_Date
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   04.03.2014  changed - add parameters pi_bill_method and
--                                    pi_bill_method_id
--                                    rq 1000008191
--     Fadata   06.04.2015  changed - add procedure specification, add savepoint
--                                    and rollback
--                                    rq 1000009741
--     Fadata   15.09.2015  changed - add offset depend on setting
--                                    BillingNextDateOffset
--                                    increment next date non only with one
--                                    period and with necessary count of periods
--                                    to become next date greater than run date
--                                    rq 1000010052
--     Fadata   08.06.2016  changed - use bill horizon as next date offset and
--                                    add additional offset for non-working days
--                                    rq 1000010513
--     Fadata   02.05.2017  changed - copy from core and add logic to update
--                                    only accounts with CLIENT billing skope
--                                    for party role Holder
--
-- Purpose: Update next billing date with new calculated for accounts with
-- billing site equals to given billing organization and next date not greater
-- than given billing run date

-- Input parameters:
--     pi_org_id         NUMBER       Billing organization identifier (required)
--     pi_run_date       DATE         Billing run date (required)
--     pi_bill_method    VARCHAR2(30) Bill method code
--     pi_bill_method_id NUMBER       Bill method id
--     pi_billing_run_id NUMBER       Billing run identifier (required)
--     pio_Err           SrvErr       Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     pio_Err           SrvErr      Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: Final step in regular billing process
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Change_Account_Next_Date
   (pi_org_id         IN     NUMBER,
    pi_run_date       IN     DATE,
    pi_bill_method    IN     VARCHAR2,
    pi_bill_method_id IN     NUMBER,
    pi_billing_run_id IN     NUMBER,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Change_Item_Next_Date
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--
-- Purpose: Update next billing date with new calculated for items with
-- billing site(attrib_0) equals to given billing organization and next date
-- (attrib_4) not greater than given billing run date

-- Input parameters:
--     pi_org_id         NUMBER       Billing organization identifier (required)
--     pi_run_date       DATE         Billing run date (required)
--     pi_bill_method    VARCHAR2(30) Bill method code
--     pi_bill_method_id NUMBER       Bill method id
--     pi_billing_run_id NUMBER       Billing run identifier (required)
--     pio_Err           SrvErr       Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     pio_Err           SrvErr      Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: Final step in regular billing process
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Change_Item_Next_Date
   (pi_org_id         IN     NUMBER,
    pi_run_date       IN     DATE,
    pi_bill_method    IN     VARCHAR2,
    pi_bill_method_id IN     NUMBER,
    pi_billing_run_id IN     NUMBER,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Postprocess_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--
-- Purpose: Execute custom postprocess procedure for document depend on
-- accounting class and given postprocess
--
-- Input parameters:
--     pi_doc_id            NUMBER     Document Id (required)
--     pio_postprocess      VARCHAR2   Postprocess
--     pio_procedure_result VARCHAR2   Procedure result
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_postprocess      VARCHAR2   Postprocess
--     pio_procedure_result VARCHAR2   Procedure result
--     po_action_notes       VARCHAR2  Action notes
--     pio_Err               SrvErr    Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: In billing process after complete document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Postprocess_Document
   (pi_doc_id             IN     NUMBER,
    pio_postprocess       IN OUT VARCHAR2,
    pio_procedure_result  IN OUT VARCHAR2,
    po_action_notes       OUT    VARCHAR2,
    pio_Err               IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Check_Imm_Run_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--
-- Purpose: Calculate if given run date is elligible for run immediate bill
-- depend on next date and bill period of the given agreement
--
-- Input parameters:
--     pi_run_date        DATE       Billing run date (required)
--     pi_bill_method_id  NUMBER     Bill method (required)
--     pi_agreement       VARCHAR2   Agreement (required)
--
-- Returns:
--     Y/N
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Check_Imm_Run_Date
   (pi_run_date        IN     DATE,
    pi_bill_method_id  IN     NUMBER,
    pi_agreement       IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: blc_refund_util_pkg.Create_Payment_for_Document
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2013  creation
--     Fadata   05.02.2014  changed - add parameter bank_acc_type in call
--                                    Get_Usage_By_Acc_Class
--                                    rq 1000007988
--     Fadata   06.06.2014  changed - replace parameter bank_acc_type with
--                                    pmnt_clas in call and add pmnt_currency
--                                    Get_Usage_By_Acc_Class
--                                    rq 1000008694
--     Fadata   15.08.2014  changed - replace function Get_Usage_By_Acc_Class
--                                    and function Calc_Proper_Pmnt_Class
--                                    with procedure Calc_Doc_Usage_Id
--                                    rq 1000009023
--     Fadata   01.10.2014  changed - calculate open balance of document
--                                    as sum of open balance of selected
--                                    transactions
--                                    in case that parameters org_id and office
--                                    are empty than get office from document
--                                    org_site_id instead of insis_context
--                                    rq 1000009178
--     Fadata   30.10.2014  changed - call blc_pmnt_util_pkg.Create_Payment
--                                    because removing of
--                                    blc_refund_util_pkg.Create_Payment
--                                    rq 1000009286
--     Fadata   05.12.2014  changed - add parameter update transaction
--                                    in call Accumulate_Reminders
--                                    rq 1000009392
--     Fadata   05.03.2015  changed - add parameters party_site, pay_party,
--                                    pay_address and currency
--                                    do not change status of document to F
--                                    because in can not pay again when payment
--                                    exists
--                                    rq 1000009677
--     Fadata   26.03.2015  changed - add nvl when select sum of transactions
--                                    for applied
--                                    rq 1000009717
--     Fadata   16.06.2015  changed - add case to create incoming payment for
--                                    negative liability document
--                                    add posibility to pay documents in status
--                                    'F'
--                                    rq 1000009869
--     Fadata   05.08.2015  changed - add default depend setting
--                                    'DatesValidationBase'
--                                    rq 1000009974
--     Fadata   06.08.2015  changed - default party from account of transactions
--                                    check amount of payment to be > 0
--                                    call process PAY_DOC in
--                                    Select_Trx_For_Apply
--                                    rq 1000009977
--     Fadata   24.03.2016  changed - add parameter pay_instrument_id
--                                    rq 1000010381
--     Fadata   26.05.2016  changed - replace substr(l_pmnt_class,1) with
--                                    substr(l_pmnt_class,2) when recalculate
--                                    payment class for negative documents
--                                    rq 1000010498
--     Fadata   10.01.2016  changed - add error message when transactions for
--                                    the document are included into payment run
--                                    rq 1000010842
--     Fadata   03.05.2016  changed - copy from core and change always to set
--                                    limit amount
--     Fadata   15.02.2018  changed - call custom Accumulate_Reminders
--
-- Purpose: Execute procedure for creation of payment for positive liability
-- or negative receivable document
-- Actions:
--     1) Create payment
--     2) Apply payment on document transactions
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required);
--     pi_office              VARCHAR2     Office issue payment;
--     pi_org_id              NUMBER       Payment site id;
--     pi_usage_id            NUMBER       Usage Id;
--     pi_amount              NUMBER       Payment amount;
--     pi_party               VARCHAR2     Party id;
--     pi_party_site          VARCHAR2     Party address id;
--     pi_pay_party           VARCHAR2     Payer party;
--     pi_pay_address         VARCHAR2     Payer party address;
--     pi_bank_code           VARCHAR2     Bank code;
--     pi_bank_acc_code       VARCHAR2     Bank account code;
--     pi_pmnt_address        VARCHAR2     Payment address;
--     pi_currency            VARCHAR      Payment currency;
--     pi_pmnt_date           VARCHAR2     Payment date;
--     pi_pmnt_number         VARCHAR2     Payment number;
--     pi_pay_instr_id        NUMBER       Payment instrument id;
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
-- Returns:
--     payment id
--
-- Usage: In UI when need to pay a document
--
-- Exceptions:
--    1) In case that document is not in proper status
--    2) In cast that usage_id is empty and is not possible to default it
--    3) In case that creation of payment faled
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Create_Payment_for_Document
   (pi_doc_id         IN     NUMBER,
    pi_office         IN     VARCHAR2,
    pi_org_id         IN     NUMBER,
    pi_usage_id       IN     NUMBER,
    pi_amount         IN     NUMBER,
    pi_party          IN     VARCHAR2,
    pi_party_site     IN     VARCHAR2,
    pi_pay_party      IN     VARCHAR2,
    pi_pay_address    IN     VARCHAR2,
    pi_bank_code      IN     VARCHAR2,
    pi_bank_acc_code  IN     VARCHAR2,
    pi_pmnt_address   IN     VARCHAR2,
    pi_currency       IN     VARCHAR2,
    pi_pmnt_date      IN     DATE,
    pi_pmnt_number    IN     VARCHAR2,
    pi_pay_instr_id   IN     NUMBER,
    pio_Err           IN OUT SrvErr)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Check_Reg_Run_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   04.05.2017  creation
--
-- Purpose: Calculate if for client group policies immediate billing is executed
-- to can select installments from regular billing
--
-- Input parameters:
--     pi_item_type       VARCHAR2   Item type (required)
--     pi_policy_type     VARCHAR2   Policy type (required)
--     pi_agreement       VARCHAR2   Agreement (required)
--
-- Returns:
--     Y/N
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Check_Reg_Run_Policy
   (pi_item_type       IN     VARCHAR2,
    pi_policy_type     IN     VARCHAR2,
    pi_agreement       IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Convert_Doc_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.08.2017  creation
--
-- Purpose: Modify given number to string with given length numeric digits with
-- leading zeroes
--
-- Input parameters:
--       pi_number      NUMBER   Document number
--       pi_length      NUMBER   Length of number
--
-- Returns: Y/N
--
-- Usage: When need to create fixed digit document number
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Convert_Doc_Number
      (pi_number IN NUMBER,
       pi_length IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Modify_Doc_Number
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
-- Purpose:  Execute procedure for modifying document number
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_action_notes        VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI or workflow process when need to change document number
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--    2) Update document is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Modify_Doc_Number
   (pi_doc_id            IN     NUMBER,
    pio_procedure_result IN OUT VARCHAR2,
    po_action_notes      OUT    VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Set_Doc_AD
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
-- Purpose:  Execute procedure for set document suffix with given AD (autorized
-- document) number
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_action_type         VARCHAR2     Action type (required) CREATE_AD/DELETE_AD
--     pi_ad_number           VARCHAR2     AD number (required)
--     pi_ad_date             DATE         Issued or deleted date of AD (required)
--     pi_action_reason       VARCHAR2     Action reason notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_procedure_result    VARCHAR2     Procedure result
--                                         SUCCESS/WARNING/ERROR
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to change document autorized document
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--    2) Update document is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Doc_AD
   (pi_doc_id            IN     NUMBER,
    pi_action_type       IN     VARCHAR2,
    pi_ad_number         IN     VARCHAR2,
    pi_ad_date           IN     DATE,
    pi_action_reason     IN     VARCHAR2,
    po_procedure_result  OUT VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Modify_Inst_Attributes
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  Creation - copy from blc_process_pkg
--                                     and extend with processing
--                                     set in context parameter run_id
--
-- Purpose: Function updates installment attributes for an item_id,
-- limited in addition by policy, annex and claim if passed
--
-- Input parameters:
--     pi_item_id          NUMBER        Unique identifier of billing item
--                                       (reguired)
--     pi_policy           VARCHAR2(30)  Policy Id
--     pi_annex            VARCHAR2(30)  Annex Id
--     pi_claim            VARCHAR2(30)  Claim Id
--     pi_external_id      VARCHAR2(30)  Insurance payment plan reference
--     pi_Context          SrvContext    Input context from where get
--                                       values for updated installment
--                                       attributes
--     pio_Err            SrvErr         Specifies structure for passing back the
--                                       error code, error TYPE and corresponding
--                                       message.
--
-- Output parameters:
--     pio_Err            SrvErr         Specifies structure for passing back the
--                                       error code, error TYPE and corresponding
--                                       message.
--
-- Returns:
-- FALSE - When operation cannot be procesed.
-- TRUE  - In case of successful operation.
--
-- Usage: When need to modify installment attributes immediately after creation
-- of one installment group
--
-- Exceptions:
-- 1) when Update_Installment fails
--
-- Dependences: /*TBD-COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Modify_Inst_Attributes
   (pi_item_id          IN     NUMBER,
    pi_policy           IN     VARCHAR2,
    pi_annex            IN     VARCHAR2,
    pi_claim            IN     VARCHAR2,
    pi_external_id      IN     VARCHAR2,
    pi_Context          IN     SrvContext,
    pio_Err             IN OUT SrvErr )
RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Doc_Reference
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  creation
--
-- Purpose: Calculates list of positive documents related to the same bill
-- period as is for the given negative document
--
-- Input parameters:
--     pi_doc_id          NUMBER     Document identifier
--
-- Returns:
--     List of doc ids
--
-- Usage: In run billing to calculate reference of the document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Doc_Reference
   (pi_doc_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Validate_Doc_Reference
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  creation
--
-- Purpose: Execute procedure for validate doc reference
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_doc_status          VARCHAR2     Document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In complete document to validate doc reference
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Doc_Reference
   (pi_doc_id             IN     NUMBER,
    pio_procedure_result  IN OUT VARCHAR2,
    po_doc_status         OUT    VARCHAR2,
    pio_Err               IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Appr_Compl_Documents
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.08.2017  creation - rq 1000011083
--
-- Purpose: Executes procedure for approve and complete documents with ids from
-- given list indepent on them status and return list of not posiible to
-- complete documents
--
-- Input parameters:
--     pi_doc_ids           VARCHAR2      List of document Ids
--     pio_Err              SrvErr        Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Output parameters:
--     po_doc_list          VARCHAR2      List of document numbers which are
--                                        continue to stay not approved after
--                                        successfully execution of procedure
--     pio_Err              SrvErr        Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: From UI when need to approve documents.
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Appr_Compl_Documents
   (pi_doc_ids        IN     VARCHAR2,
    po_doc_list       OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Referred_Doc
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.08.2017  creation
--
-- Purpose: Calculates list of negative documents for an agreement which
-- referred given doc_id
--
-- Input parameters:
--     pi_doc_id          NUMBER     Document identifier
--     pi_agreement       VARCHAR2   Item agreement
--
-- Returns:
--     List of doc ids
--
-- Usage: In document deletion to calculate list of referred documents
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Referred_Doc
   (pi_doc_id     IN     NUMBER,
    pi_agreement  IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mark_For_Deletion
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.08.2017  creation
--     Fadata   13.06.2018  changed - change parameter po_action_notes to
--                          pio_action_notes
--                          add parameter pi_rev_reason in
--                          Lock_Doc_For_Delete - LPV-1654
--
-- Purpose:  Execute procedure for check availability for deletion of proforma
-- and call integration server to lock for deletion proforma in SAP
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_action_notes       VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_action_notes       VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI when need to delete proforma
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mark_For_Deletion
   (pi_doc_id            IN     NUMBER,
    pio_procedure_result IN OUT VARCHAR2,
    pio_action_notes     IN OUT VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Set_Formal_Unformal
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2017  creation
--
-- Purpose: Execute procedure for validation of change status to Formal/Unformal
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_action_notes        VARCHAR2     Action notes
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_doc_status          VARCHAR2     New document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI or workflow process when need to set document in Formal or
-- Unformal status
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Set_Formal_Unformal
   (pi_doc_id             IN     NUMBER,
    pi_action_notes       IN     VARCHAR2,
    pio_procedure_result  IN OUT VARCHAR2,
    pio_Err               IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Not_Pay_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2017  creation
--
-- Purpose: Check if given annex is cancellation for not payment
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for cancellation for not payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Not_Pay_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Canc_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2017  creation
--
-- Purpose: Check if given annex is cancellation
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for cancellation for not payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Canc_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Item_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2017  creation
--
-- Purpose: Check if given item list includes only one iten from type POLICY
--
-- Input parameters:
--     pi_item_ids   Varchar2    Item ids (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if it is item policy
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Item_Policy
   (pi_item_ids     IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mass_Delete_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2017  creation
--     Fadata   13.06.2018  changed - add parameter pi_rev_reason in
--                          Lock_Doc_For_Delete - LPV-1654
--
-- Purpose:  Execute procedure for delete all unpaid and without AD number
-- proformas related to given parameters
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pi_agreement           VARCHAR2     Item agreement
--     pi_protocol            VARCHAR2     Protocol number
--     pi_lock_flag           VARCHAR2     Call integration for lock for delete
--     pi_item_ids            VARCHAR2     Item Ids
--     pi_master_policy_no    VARCHAR2     Master policy no
--     pi_delete_reason       VARCHAR2     Delete reason
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to delete all unpaid documents before transfer installments
-- for an adjustment to be able to compensate some installments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mass_Delete_Proforma
   (pi_policy_id         IN     NUMBER,
    pi_annex_id          IN     NUMBER,
    pi_agreement         IN     VARCHAR2,
    pi_protocol          IN     VARCHAR2,
    pi_lock_flag         IN     VARCHAR2,
    pi_item_ids          IN     VARCHAR2,
    pi_master_policy_no  IN     VARCHAR2,
    pi_delete_reason     IN     VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calc_Policy_Protocol_Attr
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.10.2017  creation
--
-- Purpose: Calculate policy protocol related attributes
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_protocol_flag       VARCHAR2     Protocol flag
--     po_protocol_number     VARCHAR2     Protocol number
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In create, update blc item
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Calc_Policy_Protocol_Attr
    ( pi_policy_id       IN     NUMBER,
      po_protocol_flag   OUT    VARCHAR2,
      po_protocol_number OUT    VARCHAR2,
      pio_Err            IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_SIP_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.10.2017  creation
--
-- Purpose: Check if given annex is for SIP
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for SIP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_SIP_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Pay_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.11.2017  creation
--
-- Purpose:  Execute procedure for validation before pay a document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_org_id              NUMBER       Organization Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI when need to pay a document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Pay_Document
   (pi_doc_id            IN     NUMBER,
    po_org_id            OUT    NUMBER,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Not_Allow_Activity
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.12.2017  creation
--
-- Purpose:  Execute procedure for stop ativity for accounting voucher document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_action_notes        VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI when to stop activity
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Not_Allow_Activity
   (pi_doc_id            IN     NUMBER,
    pio_procedure_result IN OUT VARCHAR2,
    po_action_notes      OUT    VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Policy_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   10.12.2017  creation
--
-- Purpose: Return policy type - attr7 from policy_engagement_billing
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--       pi_annex_id       NUMBER   Annex ID
--
-- Returns: policy type
--
-- Usage: When need to know policy type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Type
    ( pi_policy_id   IN NUMBER,
      pi_annex_id    IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_PaidUp_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.10.2017  creation
--
-- Purpose: Check if given annex is for PiadUp
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for SIP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_PaidUp_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Set_Doc_Delete_Reason
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.01.2018  creation
--
-- Purpose:  Execute procedure for set delete reason code in delete action
-- attrib_0 for given deleted document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_delete_reason       VARCHAR2     Delete reason code
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to set delete reason code in delete document action
--
-- Exceptions:
--    1) Update document action is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Doc_Delete_Reason
   (pi_doc_id            IN     NUMBER,
    pi_delete_reason     IN     VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calc_Policy_Pay_Way
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2018  creation - LPV-1768 get pay way and pay instrument
--                          for policy item with select from
--                          policy_engagement_billing and avoid call of event
--                          GET_PAY_INSTR
--
-- Purpose: Get pay way and pay instrument
--
-- Input parameters:
--     pi_item_id         NUMBER         Item Id (required)
--     pi_org_id          NUMBER         Organization identifier (required)
--     pi_to_date         DATE           Date for wich get value (required)
--
-- Output parameters:
--     po_pay_way_id      NUMBER         Pay way Id (BLC lookup_id)
--     po_pay_instr_id    NUMBER         Pay instrument id
--                                       (BLC pay instrument_id)
--     pio_Err            SrvErr         Specifies structure for passing back
--                                       the error code, error TYPE and
--                                       corresponding message.
--
-- Usage: When need to know policy pay way and pay instrument
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Calc_Policy_Pay_Way
   (pi_item_id           IN     NUMBER,
    pi_org_id            IN     NUMBER,
    pi_to_date           IN     DATE,
    po_pay_way_id        OUT    NUMBER,
    po_pay_instr_id      OUT    NUMBER,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Auto_Approve_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.09.2018  creation - LPV-1768 copy from core and remove call
--                          of the rule
--
-- Purpose: Check rule Autoapproval ability and if Yes execute procedure of
-- change status to Approve for document in status Validated
-- Actions:
--     1) Check rule Autoapproval
--     2) Update document status
--     3) Insert action approve
--     4) Create accounting events for transactions into document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_action_notes        VARCHAR2     Action notes
--     pi_doc_class           VARCHAR2     Document class
--     pi_doc_type            VARCHAR2     Document type
--     pi_trx_type            VARCHAR2     Transaction type
--     pi_postprocess         VARCHAR2     Installment postprocess
--     pi_run_id              NUMBER       Billing run id
--     pi_norm_interpret      VARCHAR2     Norm interpret setting
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_doc_status         VARCHAR2     Old document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_doc_status         VARCHAR2     New document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In billing process when need to approve document
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--    2) Update document is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Auto_Approve_Document
   (pi_doc_id             IN     NUMBER,
    pi_action_notes       IN     VARCHAR2,
    pi_doc_class          IN     VARCHAR2,
    pi_doc_type           IN     VARCHAR2,
    pi_trx_type           IN     VARCHAR2,
    pi_postprocess        IN     VARCHAR2,
    pi_run_id             IN     NUMBER,
    pi_norm_interpret     IN     VARCHAR2,
    pio_procedure_result  IN OUT VARCHAR2,
    pio_doc_status        IN OUT VARCHAR2,
    pio_Err               IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Bill_Grouping
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   04.12.2018  creation - LPVS-14
--
-- Purpose: Calculate transaction grouping
--
-- Input parameters:
--     pi_attrib_6        VARCHAR    Transaction attrib_6 - begin bill period
--     pi_attrib_7        VARCHAR    Transaction attrib_7 - end bill period
--     pi_item_type       VARCHAR2   Item type
--     pi_policy_type     VARCHAR2   Policy type - item.attrib_7
--     pi_run_id          NUMBER     Run identifier
--
-- Returns:
--     groupin value
--
-- Usage: In run billing to calculate transaction grouping value
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Bill_Grouping
   (pi_attrib_6    IN     VARCHAR2,
    pi_attrib_7    IN     VARCHAR2,
    pi_item_type   IN     VARCHAR2,
    pi_policy_type IN     VARCHAR2,
    pi_run_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Comp_Tolerance_USD
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.06.2019  creation - LPVS-111
--
-- Purpose: Get value for setting 'CustCompToleranceUSD'
-- for global variables legal entity and oper_date set after execution if
-- Init legal entity
--
-- Returns:
--     tolerance
--
-- Usage: In installments compensation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Comp_Tolerance_USD
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Comp_Tolerance_PEN
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.06.2019  creation - LPVS-111
--
-- Purpose: Get value for setting 'CustCompTolerancePEN'
-- for global variables legal entity and oper_date set after execution if
-- Init legal entity
--
-- Returns:
--     tolerance
--
-- Usage: In installments compensation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Comp_Tolerance_PEN
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Manual_Canc_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Check if given annex is manual cancellation or paidup
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for manula cancellation or paidup
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Manual_Canc_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Annex_Reverse
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Check if given annex is reversed
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is reversed
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Annex_Reverse
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Comp_Item_Installments_Spec
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Compensate installments for given item id by bill period specified
-- in attrib_4(begin date) and attrib_5(end date) of instalments if absolute
-- value of total amount for period is less than given tolerance
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pi_annex_id          NUMBER     Annex id
--     pi_tolerance_usd     NUMBER     Tolerance for USD
--     pi_tolerance_pen     NUMBER     Tolerance for PEN
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for policy cancellation annex
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Comp_Item_Installments_Spec( pi_item_id       IN NUMBER,
                                       pi_annex_id      IN NUMBER,
                                       pi_tolerance_usd IN NUMBER,
                                       pi_tolerance_pen IN NUMBER,
                                       pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Reinstate_Comp_Install_Spec
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Reinstate compensatation specific, delete technical added
-- installments and update compensation flag to N
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pi_annex_id          NUMBER     Annex id
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for annex reverse
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Reinstate_Comp_Install_Spec( pi_item_id       IN NUMBER,
                                       pi_annex_id      IN NUMBER,
                                       pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: blc_pas_transfer_installs_pkg.Comp_Item_Installments_Norm
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Compensate similar installments for given item id
--
-- Actions:
--  1) Get and lock installments records for comprnsation;
--  2) Loops over collection, retrieve similar installments and reserve their ids;
--  3) Mark reserved installments as compensated;
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for annex reverse
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Comp_Item_Installments_Norm( pi_item_id       IN NUMBER,
                                       pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mass_Delete_Proforma_Bill
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose:  Execute procedure for delete all unpaid and without AD number
-- proformas related to given item and calculate proper bill method
--
-- Input parameters:
--     pi_item_ids            VARCHAR2     Item Ids
--     pi_annex_id            NUMBER       Annex Id
--     pio_bill_method        VARCHAR2     Bill method
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to delete all unpaid documents before transfer installments
-- for an adjustment to be able to compensate some installments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mass_Delete_Proforma_Bill
   (pi_item_ids          IN     VARCHAR2,
    pi_annex_id          IN     NUMBER,
    pio_bill_method      IN OUT VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Unapply_Net_Appl_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Execute procedure for unapply internal CREDIT_ON_TRX applications
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: Before delete document
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Unapply_Net_Appl_Document
   (pi_doc_id             IN     NUMBER,
    pio_Err               IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Auto_Policy_Cancel
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.07.2019  creation - Phase 2
--
-- Purpose: Check if allowed policy cancellation for given policy in component
-- if item type is POLICY
--
-- Input parameters:
--     pi_item_type   Varchar2    Item type (required)
--     pi_component   Varchar2    Item component (required)
--
-- Returns:
--     Y/N or NULL for non POLICY types
--
-- Usage: When need to know if policy is restricted from automatic cancellation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Auto_Policy_Cancel
   (pi_item_type     IN     VARCHAR2,
    pi_component     IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Agent_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.07.2019  creation - Phase 2
--
-- Purpose: get agent name
--
-- Input parameters:
--     pi_agent_id    Varchar2    Agent id (required)
--
-- Returns:
--     agent name
--
-- Usage: When need to know agent_name
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Agent_Name
   (pi_agent_id     IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Agent_Change_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   31.07.2019  creation - LPV-2000
--
-- Purpose: Check if given annex is for SIP
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for SIP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Agent_Change_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Update_Comp_Install
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  31.07.2019 creation - LPV_2000
--
-- Purpose: Update compensation flag to N
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for annex change agent
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Update_Comp_Install( pi_item_id       IN NUMBER,
                               pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calc_Collector_Agent
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.08.2019  creation LPV-2000
--
-- Purpose: Calculate collector agent
--
-- Input parameters:
--     pi_item_type       VARCHAR2   Item type
--     pi_policy_id       VARCHAR2   Policy Id
--     pi_period_from     VARCHAR2   Bill premium begin date (YYYY-MM-DD)
--
-- Returns:
--     Collector agent id
--
-- Usage: In run billing to calculate collector agent
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calc_Collector_Agent
   (pi_item_type        IN     VARCHAR2,
    pi_policy_id        IN     VARCHAR2,
    pi_period_from      IN     VARCHAR2)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mass_Update_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.08.2019  creation - LPV-2000
--
-- Purpose:  Execute procedure for update unpaid proforma attributes
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to update all unpaid documents affected by an annex change
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mass_Update_Proforma
   (pi_policy_id         IN     NUMBER,
    pi_annex_id          IN     NUMBER,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Annex_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  13.08.2019 creation - LPV-2000
--
-- Purpose: Get annex type
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know annex type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Annex_Type
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Office
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.12.2019  creation  LPV-2429
--
-- Purpose: Get the office id from the policy
--
-- Input parameters:
--       pi_component      VARCHAR2  Item component
--
-- Returns: office
--
-- Usage: In billing process, update transaction attrib_1
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Office( pi_component IN VARCHAR2 ) RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Update_Item_Due_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   10.02.2020  creation - CON94S-9
--
-- Purpose: Change due date with new annex reason - Change Payment due date
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pi_stage               VARCHAR2
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Return: Boolean
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Update_Item_Due_Date
    ( pi_policy_id IN     NUMBER,
      pi_annex_id  IN     NUMBER,
      pi_stage     IN     VARCHAR2,
      pio_Err      IN OUT SrvErr )
RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Item_Non_Protocol_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.04.2020  creation - LPV-2621
--
-- Purpose: Check if given item list includes only one item for non protocol
-- billed policy
--
-- Input parameters:
--     pi_item_ids   Varchar2    Item ids (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if item is for policy not marked for protocol biling
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Item_Non_Protocol_Policy
   (pi_item_ids     IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Annex_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  16.12.2020 creation - CON94S-55
--
-- Purpose: Get annex type
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know annex begin date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Annex_Date
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_PayWay_Change_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.12.2020  creation - CON94S-55
--
-- Purpose: Check if given annex is for pay way change
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for pay way change
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_PayWay_Change_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Run_Billing_PayWay_Change
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.12.2020  creation - CON94S-55
--
-- Purpose:  Execute rum immediate billing for pay way change annex
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pi_stage               VARCHAR2     Stage
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to explicitly run immediate billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Run_Billing_PayWay_Change
   (pi_policy_id         IN     NUMBER,
    pi_annex_id          IN     NUMBER,
    pi_stage             IN     VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Validate_New_Adj_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.09.2021  creation - LAP85-132
--
-- Purpose: Validate amount on manual adjust transactions
--
-- Input parameters:
--     pi_trx_id              NUMBER       Transaction Id
--     pi_trx_type            VARCHAR2     Transaction type
--     pi_amount              NUMBER       Amount
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: Pre create/modify transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_New_Adj_Trx
   ( pi_trx_id      IN     NUMBER,
     pi_trx_type    IN     VARCHAR2,
     pi_amount      IN     NUMBER,
     pio_Err        IN OUT SrvErr );
--
END cust_billing_pkg;
/