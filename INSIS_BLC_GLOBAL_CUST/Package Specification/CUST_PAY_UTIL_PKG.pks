CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_PAY_UTIL_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during payment process
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: cust_pmnt_util_pkg.Validate_Pmnt_Appl
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.01.2017  creation
--
-- Purpose:  Execute procedure of validation of payment application details
-- and return doc_id if payment have to be applied on particular document
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_remittance_ids      VARCHAR2     List of remittance id
--     pi_unapply             VARCHAR2     Unapply mode - set to 'Y' for
--                                         validataion of unapply
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_doc_id              NUMBER       Document Identifier
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In pre-validate and pre-apply payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Pmnt_Appl
   (pi_payment_id        IN     NUMBER,
    pi_remittance_ids    IN     VARCHAR2,
    pi_unapply           IN     VARCHAR2 DEFAULT 'N',
    po_doc_id            OUT    NUMBER,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Pre_Validate_Payment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.01.2017  creation
--
-- Purpose: Execute procedure of custom validation of payment
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pio_action_notes       VARCHAR2     Action notes
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_action_notes       VARCHAR2     Action notes
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In validate payment before standard payment validation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Validate_Payment
   (pi_payment_id        IN     NUMBER,
    pio_action_notes     IN OUT VARCHAR2,
    pio_procedure_result IN OUT VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Apply_Receipt_On_Doc
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.15.2017  creation
--     Fadata   15.02.2018  changed - call custom Accumulate_Reminders
--
-- Purpose: Execute procedure of receipt application on billing reference
-- document if given or standard apply receipt/remittances if not given
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment Id (required);
--     pi_remittance_ids      VARCHAR2     List of remittance id;
--     pi_doc_id              NUMBER       Document Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns: N/A
--
-- Usage: In UI when need to apply receipt (button Apply Receipt).
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Apply_Receipt_On_Doc
    ( pi_payment_id        IN     NUMBER,
      pi_remittance_ids    IN     VARCHAR2,
      pi_doc_id            IN     NUMBER,
      pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Check_SYSADMIN_User
--
-- Type: PROCEDURE
--
-- Subtype: DATA_SET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.07.2017  creation
--
-- Purpose: Check if context user is defined in the lookup set BLC_SYSADMINS
--
-- Input parameters:
--     pi_org_id       NUMBER     Organization Id
--     pi_to_date      VARCHAR2   To date
--     pio_Err         SrvErr     Specifies structure for passing back
--                                the error code, error TYPE and
--                                corresponding message.
--
-- Output parameters:
--     pio_Err         SrvErr     Specifies structure for passing back
--                                the error code, error TYPE and
--                                corresponding message.
--
-- Usage: In validation of reverse reason and cancel preliminary mark
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Check_SYSADMIN_User
   (pi_org_id         IN     NUMBER,
    pi_to_date        IN     DATE,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Is_Allowed_Reverse_Reason
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.07.2017  Creation
--
-- Purpose: Calculate if given reverse reason is allowed for given payment
--
-- Input parameters:
--     pi_reason_id           NUMBER     Reason for reverse (required)
--                                       lookup id for lookup_set
--                                       PMNT_REVERSE_REASON
--     pi_payment_id          NUMBER     Payment identifier (required)
--
-- Returns:
--     TRUE - if allowed
--     FALSE - if not allowed
--
-- Usage: In UI to select proper reverse reasons for a payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
-------------------------------------------------------------------------------
FUNCTION Is_Allowed_Reverse_Reason
   (pi_reason_id      IN     NUMBER,
    pi_payment_id     IN     NUMBER)
RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Pre_Reverse_Payment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.07.2017  creation
--
-- Purpose: Execute custom procedure of pre reverse payment
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_reason_id           NUMBER       Reverse reason id - lookup_id
--     pi_manual_flag         VARCHAR2     Manual flag M/A
--     pi_reason_code         VARCHAR2     Reverse reason code - lookup_code
--     pi_notes               VARCHAR2     Reverse notes
--     pi_reversed_on         DATE         Reversed date
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_new_status          VARCHAR2    Change to the new status instead of
--                                        Reverse
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In UI when need to reverse payment
--
-- Exceptions: N/A
--
-- Dependences: /N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Reverse_Payment
   (pi_payment_id      IN     NUMBER,
    pi_reason_id       IN     NUMBER,
    pi_manual_flag     IN     VARCHAR2,
    pi_reason_code     IN     VARCHAR2,
    pi_notes           IN     VARCHAR2,
    pi_reversed_on     IN     DATE,
    po_new_status      OUT    VARCHAR2,
    pio_Err            IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Reverse_Payment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.07.2017  creation
--
-- Purpose: Execute core procedure of reverse payment only case that
-- the new status is null
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_reason_id           NUMBER       Reverse reason id - lookup_id
--     pi_reason_code         VARCHAR2     Reverse reason code - lookup_code
--     pi_notes               VARCHAR2     Reverse notes
--     pi_reversed_on         DATE         Reversed date
--     pi_execute_unclear     VARCHAR2     Execute unclear before reverse Y/N
--     pi_new_status          VARCHAR2     Change to the new status instead of
--                                         Reverse
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In UI when need to reverse payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Reverse_Payment
   (pi_payment_id      IN     NUMBER,
    pi_reason_id       IN     NUMBER,
    pi_reason_code     IN     VARCHAR2,
    pi_notes           IN     VARCHAR2,
    pi_reversed_on     IN     DATE,
    pi_execute_unclear IN     VARCHAR2,
    pi_new_status      IN     VARCHAR2,
    pio_Err            IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Approve_Payments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Execute steps of process BLC_APPROVE_PAYMENT for list of payments
--
-- Input parameters:
--     pi_payment_ids         NUMBER       List od payment identifiers (required)
--     pi_notes               VARCHAR2     Notes
--     pi_changed_on          DATE         Change date
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_changed_status      VARCHAR2    Changed status payment
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In UI when need to approve payments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Approve_Payments
   (pi_payment_ids    IN     VARCHAR2,
    pi_notes          IN     VARCHAR2,
    po_changed_status OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Modify_Pmnt_Activities
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Modify allowed activities for given payment
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_act_list            VARCHAR2     Activity list
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_act_list            VARCHAR2     Modified Activity list
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.

-- Usage: In UI when need calculate allowed activities
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Modify_Pmnt_Activities
   (pi_payment_id     IN     NUMBER,
    pi_act_list       IN     VARCHAR2,
    po_act_list       OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Is_Pmnt_Sent
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.07.2017  creation
--
-- Purpose: Check if payment is sent
--
-- Input parameters:
--     pi_payment_id   NUMBER     Payment identifier (required)
--
-- Returns: Y/N
--
-- Usage: when need to know if payment is sent
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Pmnt_Sent
   (pi_payment_id     IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_pmnt_util_pkg.Validate_Pmnt_UnAppl
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.08.2017  creation
--
-- Purpose:  Execute procedure of validation of payment unapplication
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment identifier (required)
--     pi_remittance_ids      VARCHAR2     List of remittance id
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
-- Usage: In unapply payment and remittance
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Pmnt_UnAppl
   (pi_payment_id        IN     NUMBER,
    pi_remittance_ids    IN     VARCHAR2,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Update_Appl_Event - not in use
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   25.09.2017  creation
--
-- Purpose: Execute procedure for set payment event id in attrib_9 of payment
-- application
--
-- Input parameters:
--     pi_application_id      NUMBER       Application identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In apply payment before transfer to PAS
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Update_Appl_Event
   (pi_application_id    IN     NUMBER,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Net_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.08.2017  creation
--
-- Purpose: Execute procedure for netting document, firstly between transactions
-- in a document and that with transactions from the agreement of document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err         SrvErr        Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In billing process to execute netting for a document after it
-- validation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Net_Document
   (pi_doc_id      IN     NUMBER,
    pio_Err        IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Void_Payment_for_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2013  creation
--     Fadata   05.03.2015  changed - do not check status of document to be F
--                                    add where clause to reverse only payments
--                                    with amount <> 0
--                                    replace BLC_APPL_UTIL_PKG.Reverse_Payment
--                                    with BLC_PMNT_UTIL_PKG.Reverse_Payment
--                                    to pass parameter reverse reason
--                                    rq 1000009677
--     Fadata  20.11.2017   copy from core and remove substr(bp.payment_class,1,1) = 'O'
--
-- Purpose: Execute procedure for reverse of outgoing payments with amount > 0
-- for given document
--
-- Actions:
--     1) Reverse payment
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required);
--     pi_reason              VARCHAR2     Reverse payment reason code -
--                                         lookup_code
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--     TRUE/FALSE
--
-- Usage: In UI when need to void the payment for a document
--
-- Exceptions:
--    1) In case that reversal of payment failed
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Void_Payment_for_Document
   (pi_doc_id         IN     NUMBER,
    pi_reason         IN     VARCHAR2,
    pio_Err           IN OUT SrvErr)
RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Pay_Refund_CN_Doc
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
-- Purpose:  Execute procedure for pay a refund CN document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_org_id              NUMBER       Org Id
--     pi_usage_id            NUMBER       Usage Id
--     pi_amount              NUMBER       Payment amount (required)
--     pi_party               VARCHAR2     Party id
--     pi_pay_party           VARCHAR2     Payer party
--     pi_pmnt_address        VARCHAR2     Payment address
--     pi_currency            VARCHAR      Payment currency (required)
--     pi_pmnt_date           VARCHAR2     Payment date (required)
--     pi_attrib_3            VARCHAR2     AD number
--     pi_attrib_4            VARCHAR2     AD date
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_payment_id          NUMBER       Payment Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to create payment for refund CN document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pay_Refund_CN_Doc
   (pi_doc_id            IN     NUMBER,
    pi_org_id            IN     NUMBER,
    pi_usage_id          IN     NUMBER,
    pi_amount            IN     NUMBER,
    pi_party             IN     VARCHAR2,
    pi_pay_party         IN     VARCHAR2,
    pi_pmnt_address      IN     VARCHAR2,
    pi_currency          IN     VARCHAR2,
    pi_pmnt_date         IN     DATE,
    pi_attrib_3          IN     VARCHAR2,
    pi_attrib_4          IN     VARCHAR2,
    po_payment_id        OUT    NUMBER,
    pio_Err              IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Get_Pmnt_Doc_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.11.2017  creation
--
-- Purpose: Get document id for given payment
--
-- Input parameters:
--     pi_payment_id   NUMBER     Payment identifier (required)
--
-- Returns: Y/N
--
-- Usage: when need to know document paid with a payment
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pmnt_Doc_Id
   (pi_payment_id     IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Create_Acc_Event_Clear_Inst
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
-- Purpose: Create accounting event for claim RI/CO installments related to
-- clearing of given payment
--
-- Input parameters:
--     pi_clearing_id      NUMBER    Clearing Id
--     pi_uncleared        NUMBER    Uncleared clearing Id
--     pi_payment_id       NUMBER    Payment Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: After creation of a clearing to create accounting event for it
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Acc_Event_Clear_Inst
   (pi_clearing_id   IN     NUMBER,
    pi_uncleared     IN     NUMBER,
    pi_payment_id    IN     NUMBER,
    pio_Err          IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Accumulate_Reminders
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   02.09.2013  changed - add parameter limit_amount, doc_id
--     Fadata   09.10.2013  changed - change sign of source amount depend on
--                          transaction class and payment class
--     Fadata   05.12.2014  changed - add order by application sign
--                          add parameter for update transaction balance
--                          rq 1000009392
--     Fadata   05.03.2015  changed - in case when payment is outgoing,
--                          limit amount is null and payment amount <> 0
--                          add calculation of apply amount for last
--                          transactions as difference between payment amount
--                          and sum of applied amount
--                          rq 1000009677
--     Fadata   18.12.2015  RQ1000010253 add sign in Order by
--     Fadata   09.07.2016  changed - multiply target_set amount with l_sign
--                          when calculate total applied amount
--                          rq 1000010596
--     Fadata   17.05.2017  changed - fix for rq 1000009677 - do not change
--                          sign of the balance in this case
--                          rq 1000011010
--     Fadata   15.02.2018  copy of blc_appl_util_pkg.Accumulate_Reminders
--                          and order by priority and transaction_id
--
-- Purpose: Accumulate outstanding balances of selected credit transactions
-- in the unapplied receipt amount to reach to accumulated amount if given
--
-- Input parameters:
--     pi_date              DATE      Receipt date
--     pi_rate              NUMBER    Receipt rate
--     pi_rate_type         VARCHAR   Receipt rate type
--     pi_rate_date         DATE      Receipt rate date
--     pi_appl_date         DATE      Application date
--     pi_value_date        DATE      Receipt value date
--     pi_due_date          DATE      Transacion due date
--     pi_limit_amount      NUMBER    Limit of accumulated amount
--     pi_doc_id            NUMBER    Document Id
--     pi_update_trx        VARCHAR2  Update balance of selected transaction
--     pio_source_amount    NUMBER    Unapplied receipt amount
--     pio_fc_source_amount NUMBER    Unapplied receipt amount in func curr
--     pio_Err              SrvErr    Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     pio_source_amount    NUMBER    Unapplied receipt amount
--     pio_fc_source_amount NUMBER    Unapplied receipt amount in func curr
--     pio_Err              SrvErr    Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Usage: When need to accumulate credit from a transaction to a receipt
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Accumulate_Reminders
    ( pi_source_payment     IN     NUMBER,
      pi_rate               IN     NUMBER,
      pi_rate_date          IN     DATE,
      pi_rate_type          IN     VARCHAR2,
      pi_appl_date          IN     DATE,
      pi_value_date         IN     DATE,
      pi_due_date           IN     DATE,
      pi_limit_amount       IN     NUMBER,
      pi_doc_id             IN     NUMBER,
      pi_update_trx         IN     VARCHAR2 DEFAULT 'N',
      pio_source_amount     IN OUT NUMBER,
      pio_fc_source_amount  IN OUT NUMBER,
      pio_Err               IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Is_Pmnt_Adv_Claim
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   15.01.2020  creation - CHA93S-8
--
-- Purpose: Check if payment is related to advance claim
--
-- Input parameters:
--     pi_payment_id   NUMBER     Payment identifier (required)
--
-- Returns: Y/N
--
-- Usage: when need to know if payment is for advance claim
--
-- Exceptions:  N/A
--
-- Dependences:  N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Pmnt_Adv_Claim
   (pi_payment_id     IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_pay_util_pkg.Clear_Adv_Claim_Payments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.01.2020  creation - CHA93S-8
--
-- Purpose: Execute clear payment for advance claim related payments
--
-- Input parameters:
--     pi_legal_entity_id     NUMBER       Legal entity Id (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
--
-- Usage: In job program to cleal advance claim payments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Clear_Adv_Claim_Payments
   (pi_legal_entity_id    IN     NUMBER,
    pio_Err               IN OUT SrvErr);
--
END CUST_PAY_UTIL_PKG;
/


