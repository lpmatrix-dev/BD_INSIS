CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_ACC_UTIL_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during accounting process.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Office_Code
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata 09.10.2017 creation
--
-- Purpose: Get office code for given office_id
--
-- Input parameters:
-- pi_office_id NUMBER Office Id;
--
-- Returns:
-- Office code
--
-- Usage: When need to know office code
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Office_Code
 (pi_office_id IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: INSIS_BLC_GLOBAL_CUST.cust_acc_util_pkg.Get_Currency_Code
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata 09.10.2017 creation
--
-- Purpose: Get currency code for given currency
--
-- Input parameters:
--     pi_currency          VARCHAR2        Currency;
--
-- Returns:
--     Currency code
--
-- Usage: When need to know currency code
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Currency_Code
   (pi_currency   IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Company_Code
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get company for given org_id
--
-- Input parameters:
--     pi_org_id          NUMBER        Organization Id;
--
-- Returns:
--     Company code
--
-- Usage: When need to know company
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Company_Code
   (pi_org_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Tech_Brnch_RR
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get RR type for given technical branch(policy.attr1)
--
-- Input parameters:
--     pi_tech_branch          VARCHAR2        Technical branch;
--
-- Returns:
--     Technical branch RR
--
-- Usage: When need to know RR type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Tech_Brnch_RR
   (pi_tech_branch   IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Business_Unit
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get business unit for given sales channel(policy.attr3)
--
-- Input parameters:
--     pi_sales_channel          VARCHAR2        Sales Channel;
--     pi_insr_type              VARCHAR2        Insurance type;
--
-- Returns:
--     Business unit
--
-- Usage: When need to know business unit
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Business_Unit
   (pi_sales_channel   IN     VARCHAR2,
    pi_insr_type       IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Intrmd_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get indermediary type for given sales channel(policy.attr3)
--
-- Input parameters:
--     pi_sales_channel          VARCHAR2        Sales Channel;
--
-- Returns:
--     Indermediary type - I/D
--
-- Usage: When need to know indermediary type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Intrmd_Type
   (pi_sales_channel   IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Claim_Reception_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get reception_date for given claim_id
--
-- Input parameters:
--     pi_claim_id          NUMBER        Claim id;
--
-- Returns:
--     Claim event date
--
-- Usage: When need to know claim reception date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Claim_Reception_Date
   (pi_claim_id   IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_Master
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get master policy no for given policy_id
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     Master policy no
--
-- Usage: When need to know master policy number
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Master
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Bank_Acc_Currency
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2017  creation
--
-- Purpose: Get bank account currency for given bank code and bank account code
--
-- Input parameters:
--     pi_bank_code          VARCHAR2        Bank code;
--     pi_bank_account_code  VARCHAR2        Bank account code;
--
-- Returns:
--     Bank account currency
--
-- Usage: When need to know bank account currency
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Bank_Acc_Currency
   (pi_bank_code          IN     VARCHAR2,
    pi_bank_account_code  IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Trx_Savings
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get savings amount for given transaction_id
--
-- Input parameters:
--     pi_transaction_id     NUMBER       Transaction Id;
--
-- Returns:
--     savings amount
--
-- Usage: When need to know saving amount
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Trx_Savings
   (pi_transaction_id     IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_RI_Fac
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get if there is RI facultative for given policy_id
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--      RI fac flag
--
-- Usage: When need to know if RI facultative
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_RI_Fac
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_RI_Fac_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.09.2018  creation - LPV-1732
--
-- Purpose: Get if there is RI facultative for given policy_id
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--     pi_ri_clause         VARCHAR2    RI clause type;
--     pi_ri_fac_id         VARCHAR2    RI fac id;
--     pi_treaty_id         VARCHAR2    RI fac id;
--
-- Returns:
--     RI fac flag
--
-- Usage: When need to know if RI facultative
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_RI_Fac_2
   (pi_policy_id IN NUMBER,
    pi_ri_clause IN VARCHAR2,
    pi_ri_fac_id IN VARCHAR2,
    pi_treaty_id IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Ref_Doc_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get document reference number
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--     doc reference number
--
-- Usage: When need to know doc reference number
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Ref_Doc_Number
   (pi_doc_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Doc_Start_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get document start date
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--     document start date
--
-- Usage: When need to know document start date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Doc_Start_Date
   (pi_doc_id   IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Doc_End_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get document end date
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--     document end date
--
-- Usage: When need to know document end date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Doc_End_Date
   (pi_doc_id   IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_Start_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get policy start date for given doc_id
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--     policy start date
--
-- Usage: When need to know policy start date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Start_Date
   (pi_doc_id   IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_End_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get policy end date for given doc_id
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--     policy end date
--
-- Usage: When need to know policy end date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_End_Date
   (pi_doc_id   IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Pol_End_Flag
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get endorsed policy flag
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     endorsed policy flag
--
-- Usage: When need to know endorsed policy flag
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pol_End_Flag
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Pol_End_Party_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get endorsed policy party name
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     endorsed policy party name
--
-- Usage: When need to know endorsed policy party name
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pol_End_Party_Name
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Pol_End_Party
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get endorsed policy party
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     endorsed policy party
--
-- Usage: When need to know endorsed policy party
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pol_End_Party
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Doc_Prem_Amount
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get prem amount for given doc_id
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--    prem amount
--
-- Usage: When need to know prem amount of a document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Doc_Prem_Amount
   (pi_doc_id   IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Pol_Intrmd_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get policy intermediary type
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--     pi_to_date            DATE          To date;
--
-- Returns:
--     intermediary type
--
-- Usage: When need to know intermediary type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pol_Intrmd_Type
   (pi_policy_id   IN     NUMBER,
    pi_to_date     IN     DATE DEFAULT NULL)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Doc_VAT_Flag
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Get VAT flag for given doc_id
--
-- Input parameters:
--     pi_doc_id          NUMBER        Doc Id;
--
-- Returns:
--    VAT flag
--
-- Usage: When need to know VAT flag of a document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Doc_VAT_Flag
   (pi_doc_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_Class
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Calculate policy class
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     Policy class D/DC/DR/DCR/A
--
-- Usage: When need to know if RI facultative
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Class
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Coins_Percent
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Calculate coinsurance share percent
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--     pi_insurer_id         NUMBER        Insusrer Id
--     pi_fac_no             VARCHAR2      Fucultative no
--
-- Returns:
--     share percent
--
-- Usage: When need to know if RI facultative
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Coins_Percent
   (pi_policy_id   IN     NUMBER,
    pi_insurer_id  IN     NUMBER,
    pi_fac_no      IN     VARCHAR2)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Coins_Percent_Ext
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Calculate coinsurance share percent
--
-- Input parameters:
--     pi_policy_id          VARCHAR2      Policy Id
--     pi_insurer_id         NUMBER        Insusrer Id
--     pi_external_id        VARCHAR2      Installment external Id
--     pi_fac_no             VARCHAR2      Fucultative no
--
-- Returns:
--     share percent
--
-- Usage: When need to know if RI facultative
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Coins_Percent_Ext
   (pi_policy_id   IN     VARCHAR2,
    pi_insurer_id  IN     NUMBER,
    pi_external_id IN     VARCHAR2,
    pi_fac_no      IN     VARCHAR2)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Convert_Amount_To_Char
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   26.10.2017  creation
--
-- Purpose: Convert decimal number to char.
--
-- Input parameters:
--     pi_amount             NUMBER     Decimal Number(required)
--
-- Returns: Amount in char format
--
-- Usage: In accounting, when insert sum amount in char column.
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Convert_Amount_To_Char( pi_amount IN NUMBER )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Convert_To_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   26.10.2017  creation
--
-- Purpose: Convert given char value to number
--
-- Input parameters:
--     pi_value       VARCHAR2      Char value
--
-- Returns: Number
--
-- Usage: In accounting rules
--------------------------------------------------------------------------------
FUNCTION Convert_To_Number( pi_value    IN VARCHAR2 )
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_GL_Account_Attribs
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.11.2017  creation
--
-- Purpose: Get gl_account attributes - acc_class, profit_center, copa_attributes
--
-- Input parameters:
--     pi_gl_account          VARCHAR2        GL account code;
--
-- Returns:
--     Account attributes
--
-- Usage: When need to know gl account attributes
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_GL_Account_Attribs
   (pi_gl_account   IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Party_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get party name
--
-- Input parameters:
--     pi_party          VARCHAR2       Party (man_id);
--
-- Returns: party name
--
-- Usage: When need to know party name
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Party_Name( pi_party IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Accepted_Benef_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get man id
--
-- Input parameters:
--     pi_policy          VARCHAR2       Policy ID;
--
-- Returns: man_id
--
-- Usage: When need to know accepted benef man_id - DR_SEGMENT19
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Accepted_Benef_Id( pi_policy_id IN VARCHAR2 )
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Accepted_Benef_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get man id
--
-- Input parameters:
--     pi_policy          VARCHAR2       Policy ID;
--
-- Returns: man_id
--
-- Usage: When need to know accepted benef name - ATTRIB_1
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Accepted_Benef_Name( pi_policy_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Benef_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get party on parent Direct installment
--
-- Input parameters:
--     pi_parent_external_id         VARCHAR2       External ID (attrib_9)
--
-- Returns: party - man_id
--
-- Usage: When need to know RI man_id  DR_SEGMENT19
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Benef_Id( pi_parent_external_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Benef_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get party name on parent Direct installment
--
-- Input parameters:
--     pi_parent_external_id         VARCHAR2       External ID (attrib_9)
--
-- Returns: party - man_id
--
-- Usage: When need to know RI party name  ATTRIB_1
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Benef_Name( pi_parent_external_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Pmnt_Bank_Account_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get payment bank account type
--
-- Input parameters:
--     pi_payment_id         NUMBER      Payment Id;
--
-- Returns: party name
--
-- Usage: When need to know bank account type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Pmnt_Bank_Account_Type( pi_payment_id IN NUMBER )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Contr_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.11.2017  creation
--
-- Purpose: Reinsurance contract type, INSIS values:
--     PR (proportional)
--     NPR (non-proportional)
--
-- Input parameters:
--     pi_claim_id         VARCHAR2      Claim Id;
--
-- Returns: PR/NPR
--
-- Usage: accounting DR_SEGMENT24
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Contr_Type_Claim( pi_claim_id IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Contr_Type_Claim_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.09.2018  creation - LPV-1732
--
-- Purpose: Reinsurance contract type, INSIS values:
--     PR (proportional)
--     NPR (non-proportional)
--
-- Input parameters:
--     pi_claim_id         VARCHAR2      Claim Id;
--     pi_ri_clause        VARCHAR2      RI clause type;
--
-- Returns: PR/NPR
--
-- Usage: accounting DR_SEGMENT24
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Contr_Type_Claim_2
   ( pi_claim_id  IN VARCHAR2,
     pi_ri_clause IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Type_Claim
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.11.2017  creation
--
-- Purpose: Reinsurance Type
--
-- Input parameters:
--     pi_claim_id         VARCHAR2      Claim Id;
--
-- Returns: 01    Automatic Proportional
--          02    Facultative Proportional
--          03    Automatic Non Proportional
--          04    Facultative Non Proportional
--
-- Usage: accounting DR_SEGMENT5
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Type_Claim( pi_claim_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Type_Claim_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.09.2018  creation - LPV-1732
--
-- Purpose: Reinsurance Type
--
-- Input parameters:
--     pi_claim_id          VARCHAR2    Claim Id;
--     pi_ri_clause         VARCHAR2    RI clause type;
--     pi_ri_fac_id         VARCHAR2    RI fac id;
--     pi_treaty_id         VARCHAR2    RI fac id;
--
-- Returns: 01    Automatic Proportional
--          02    Facultative Proportional
--          03    Automatic Non Proportional
--          04    Facultative Non Proportional
--
-- Usage: accounting DR_SEGMENT5
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Type_Claim_2
   ( pi_claim_id IN VARCHAR2,
     pi_ri_clause IN VARCHAR2,
     pi_ri_fac_id IN VARCHAR2,
     pi_treaty_id IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Claim_Pmnt
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get claim payment id for given external_id(blc_claim.blc_clm_pk)
--
-- Input parameters:
--     pi_external_id        VARCHAR2      Installment external Id;
--
-- Returns: claim payment id
--
-- Usage: When need to know claim payment id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Claim_Pmnt( pi_external_id IN VARCHAR2 )
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_AC_Coins_Percent
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Calculate coinsurance share percent
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     share percent
--
-- Usage: When need to know coinsurance share percent
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_AC_Coins_Percent
   (pi_policy_id   IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Treaty_Type_Claim
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.11.2017  creation
--
-- Purpose: Reinsurance treaty type
--
-- Input parameters:
--     pi_claim_id          VARCHAR2      Claim Id
--
-- Returns: 01/02
--
-- Usage: accounting CR_SEGMENT5
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Treaty_Type_Claim( pi_claim_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Treaty_Type_Claim_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.09.2018  creation - LPV-1732
--
-- Purpose: Reinsurance treaty type
--
-- Input parameters:
--     pi_claim_id          VARCHAR2    Claim Id
--     pi_ri_clause         VARCHAR2    RI clause type;
--     pi_ri_fac_id         VARCHAR2    RI fac id;
--     pi_treaty_id         VARCHAR2    RI fac id;
--
-- Returns: 01/02
--
-- Usage: accounting CR_SEGMENT5
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Treaty_Type_Claim_2
   ( pi_claim_id IN VARCHAR2,
     pi_ri_clause IN VARCHAR2,
     pi_ri_fac_id IN VARCHAR2,
     pi_treaty_id IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Insurer_Account_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.11.2017  creation
--
-- Purpose: Calculate insurer account number - DD accounting nomenclature
--
-- Input parameters:
--     pi_insurer_id         VARCHAR2        Insusrer Id
--
-- Returns:
--     insurer account number
--
-- Usage: When need to know insurer account number
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Insurer_Account_Number
   (pi_insurer_id  IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Clm_Action_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.11.2017  creation
--
-- Purpose: Get action type for RI claim
--
-- Input parameters:
--     pi_party         VARCHAR2      Party (Man Id);
--     pi_currency      VARCHAR2      Currency
--
-- Returns:
--     action type CF1/CSF/AAA
--
-- Usage: When need to know action type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Clm_Action_Type
   (pi_party    IN     VARCHAR2,
    pi_currency IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_Currency
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.11.2017  creation
--
-- Purpose: Get policy currency
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     share percent
--
-- Usage: When need to know policy currency
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Currency
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_AC_Prem_Amount
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.12.2017  creation
--
-- Purpose: Get AC premium amount for given policy and annex
--
-- Input parameters:
--     pi_policy_id          VARCHAR2       Policy Id;
--     pi_annex_id           VARCHAR2       Annex Id;
--
-- Returns:
--     AC prem amount
--
-- Usage: When need to know AC premium amount
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_AC_Prem_Amount
   (pi_policy_id   IN     VARCHAR2,
    pi_annex_id    IN     VARCHAR2)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_AC_Fac_No
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.12.2017  creation
--
-- Purpose: Calculate coinsurance fac no
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     AC fac no
--
-- Usage: When need to know coinsurance fac no
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_AC_Fac_No
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_AC_Rep_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.12.2017  creation
--
-- Purpose: Calculate coinsurance report number
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     AC report number
--
-- Usage: When need to know coinsurance report number
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_AC_Rep_Number
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_AC_Reception_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.12.2017  creation
--
-- Purpose: Calculate coinsurance reception date
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     AC reception date
--
-- Usage: When need to know coinsurance reception date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_AC_Reception_Date
   (pi_policy_id   IN     NUMBER)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Annex_Convert_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.12.2017  creation
--
-- Purpose: Get convert date for given policy and annex
--
-- Input parameters:
--     pi_policy_id          VARCHAR2       Policy Id;
--     pi_annex_id           VARCHAR2       Annex Id;
--
-- Returns:
--     annex date
--
-- Usage: When need to know convert date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Annex_Convert_Date
   (pi_policy_id   IN     VARCHAR2,
    pi_annex_id    IN     VARCHAR2)
RETURN DATE;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Comm_Percent
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.12.2017  creation
--
-- Purpose: Get commision percent for given blc_comm_pk
--
-- Input parameters:
--     pi_external_id          VARCHAR2        Installment external Id;
--
-- Returns:
--     commission percent
--
-- Usage: When need to know commission percent
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Comm_Percent
   (pi_external_id   IN     VARCHAR2)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Claim_Pmnt_Man_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get man_id for claim payment id for given external_id(blc_claim.blc_clm_pk)
--
-- Input parameters:
--     pi_external_id        VARCHAR2      Installment external Id;
--
-- Returns: party name
--
-- Usage: When need to know claim payment party
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Claim_Pmnt_Man_Id( pi_external_id IN VARCHAR2 )
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Claim_Pmnt_Man_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Get man_id name for claim payment id for given external_id(blc_claim.blc_clm_pk)
--
-- Input parameters:
--     pi_external_id        VARCHAR2      Installment external Id;
--
-- Returns: party name
--
-- Usage: When need to know claim payment party
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Claim_Pmnt_Man_Name( pi_external_id IN VARCHAR2 )
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Policy_Holder_Man_id
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.12.2017  creation
--
-- Purpose: Calculate policy holder man_id
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
--
-- Returns:
--     AC reception date
--
-- Usage: When need to know policy holder man_id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Holder_Man_id
   (pi_policy_id   IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Proforma_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.12.2017  creation
--
-- Purpose: Get doc number from document in which premium installment for given
-- external_id(blc_policy_payment_plan.policy_pplan_id) is included
--
-- Input parameters:
--     pi_external_id        VARCHAR2      Installment external Id;
--
-- Returns: doc number
--
-- Usage: When need to know doc number for the payment plan id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Proforma_Number
  (pi_external_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Contr_Type_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.12.2017  creation
--
-- Purpose: Reinsurance contract type, INSIS values:
--     PR (proportional)
--     NPR (non-proportional)
--
-- Input parameters:
--     pi_policy_id         NUMBER      Policy Id;
--
-- Returns: PR/NPR
--
-- Usage: when need to know RI contract type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Contr_Type_Policy( pi_policy_id IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Contr_Type_Policy_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.09.2018  creation - LPV-1732
--
-- Purpose: Reinsurance contract type, INSIS values:
--     PR (proportional)
--     NPR (non-proportional)
--
-- Input parameters:
--     pi_policy_id         NUMBER      Policy Id;
--     pi_ri_clause         VARCHAR2    RI clause type;
--
-- Returns: PR/NPR
--
-- Usage: when need to know RI contract type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Contr_Type_Policy_2
   ( pi_policy_id IN NUMBER,
     pi_ri_clause IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Type_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.12.2017  creation
--
-- Purpose: Reinsurance Type
--
-- Input parameters:
--     pi_policy_id         NUMBER      Policy Id;
--
-- Returns: 01    Automatic Proportional
--          02    Facultative Proportional
--          03    Automatic Non Proportional
--          04    Facultative Non Proportional
--
-- Usage: when need to know RI type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Type_Policy( pi_policy_id IN NUMBER )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Type_Policy_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.09.2018  creation - LPV-1732
--
-- Purpose: Reinsurance Type
--
-- Input parameters:
--     pi_policy_id         NUMBER      Policy Id;
--     pi_ri_clause         VARCHAR2    RI clause type;
--     pi_ri_fac_id         VARCHAR2    RI fac id;
--     pi_treaty_id         VARCHAR2    RI fac id;
--
-- Returns: 01    Automatic Proportional
--          02    Facultative Proportional
--          03    Automatic Non Proportional
--          04    Facultative Non Proportional
--
-- Usage: when need to know RI type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Type_Policy_2
  ( pi_policy_id IN NUMBER,
    pi_ri_clause IN VARCHAR2,
    pi_ri_fac_id IN VARCHAR2,
    pi_treaty_id IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Trx_Claim_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.12.2017  creation
--
-- Purpose: Get claim id for given transaction_id from included
-- installment.attrib_9(claim payment id)
--
-- Input parameters:
--     pi_transaction_id        NUMBER      Transaction Id;
--
-- Returns: claim id
--
-- Usage: When need to know claim id for a transaction
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Trx_Claim_Id( pi_transaction_id IN NUMBER )
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Trx_Claim_No
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.12.2017  creation
--
-- Purpose: Get claim no for given transaction_id if it is claim related
--
-- Input parameters:
--     pi_transaction_id        NUMBER      Transaction Id;
--     pi_transaction_type      VARCHAR2    Trasaction type;
--
-- Returns: claim id
--
-- Usage: When need to know claim id for a transaction
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Trx_Claim_No
        ( pi_transaction_id   IN NUMBER,
          pi_transaction_type IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Trx_Proforma_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.12.2017  creation
--
-- Purpose: Get proforma number for given transaction_id if it is premim related
--
-- Input parameters:
--     pi_transaction_id        NUMBER      Transaction Id;
--     pi_transaction_type      VARCHAR2    Trasaction type;
--
-- Returns: doc number
--
-- Usage: When need to know claim id for a transaction
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Trx_Proforma_Number
        ( pi_transaction_id   IN NUMBER,
          pi_transaction_type IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Inst_Party
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.12.2017  creation
--
-- Purpose: Get party from premium installment for given
-- external_id (blc_policy_payment_plan.policy_pplan_id)
--
-- Input parameters:
--     pi_external_id        VARCHAR2      Installment external Id;
--
-- Returns: party
--
-- Usage: When need to know party for the payment plan id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Inst_Party
  (pi_external_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_VS_Pmnt_Amount
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.01.2018  creation
--
-- Purpose: Get paidup amount for given zero payment_id
--
-- Input parameters:
--     pi_payment_id          NUMBER        payment Id;
--
-- Returns:
--    prem amount
--
-- Usage: When need to know paidup amount of a payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_VS_Pmnt_Amount
   (pi_payment_id   IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Pol_Action_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.04.2018  creation
--
-- Purpose: Get action type for RI policy
--
-- Input parameters:
--     pi_party         VARCHAR2      Party (Man Id);
--     pi_currency      VARCHAR2      Currency
--
-- Returns:
--     action type CP1/CPR/AAA
--
-- Usage: When need to know action type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_RI_Pol_Action_Type
   (pi_party    IN     VARCHAR2,
    pi_currency IN     VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Prof_Priority
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.04.2018  creation
--
-- Purpose: Get priority for bill proforma
--
-- Input parameters:
--     pi_run_mode        VARCHAR2      Run Mode;
--     pi_bill_method_id  VARCHAR2      Bill method Id;
--
-- Returns:
--     priority HIGH/MASS
--
-- Usage: When need to know priority
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Prof_Priority
   (pi_run_mode       IN     VARCHAR2,
    pi_bill_method_id IN     NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Claim_Bank_Account_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   25.04.2018
--
-- Purpose: Return account purpose for given claim and claim payment
--
-- Input parameters:
--     pi_bank_code          VARCHAR2  Payment bank code;
--     pi_bank_account_code  VARCHAR2  Payment bank account code (required);
--     pi_claim              VARCHAR2  Claim id (required);
--     pi_claim_payment      VARCHAR2  Claim payment id (required);
--
-- Returns: bank account type
--
-- Usage: When need to know claim bank account type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Claim_Bank_Account_Type
           (pi_bank_code          IN VARCHAR2,
            pi_bank_account_code  IN VARCHAR2,
            pi_claim              IN VARCHAR2,
            pi_claim_payment      IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_NC_Client
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.04.2019  creation  LPVS-110
--
-- Purpose: Get NC on clients on customer_type
--  id     name                           NC
--  1    NATIONAL CUSTOMER                01
--  2    FOREIGN CLIENT                   02
--  3    STATE CLIENT                     01
--  4    GROUP CONTRIBUTOR                01
--  5    GROUP COMPANIES                  08
--  6    SHAREHOLDER COMPANIES            08
--  7    CO-INSURER/REINSURER CLIENT      01
--
-- Input parameters:
--     pi_man_id          VARCHAR2        Man ID;
--
-- Returns: NC - 01/02/08
--
-- Usage: When need to know NC (segment_2) on accounts
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_NC_Client( pi_man_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_NC_Reinsurer
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.04.2019  creation  LPVS-110
--
-- Purpose: Get NC on reinsurer on home_country
--  PE      Peru               01
--  Other   Other countries    02
--
-- Input parameters:
--     pi_man_id          VARCHAR2        Man ID;
--
-- Returns: NC - 01/02
--
-- Usage: When need to know NC (segment_2) on accounts
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_NC_Reinsurer( pi_man_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_GR_Code
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.03.2020  creation  LAP85-23 CSR 170
--
-- Purpose: Get GR (Client Type) on customer_type and nationality
--  id     name                        Country   GR
--  1    NATIONAL CUSTOMER               --      00
--  2    FOREIGN CLIENT                  --      00
--  3    STATE CLIENT                    --      00
--  4    GROUP CONTRIBUTOR               --      00
--  5    GROUP COMPANIES                 = Peru  01
--  5    GROUP COMPANIES                 <> Peru 02
--  6    SHAREHOLDER COMPANIES           = Peru  01
--  6    SHAREHOLDER COMPANIES           <> Peru 02
--  7    CO-INSURER/REINSURER CLIENT     --      00
--
-- Input parameters:
--     pi_man_id          VARCHAR2        Man ID;
--
-- Returns: GR - 00/01/02
--
-- Usage: When need to know GR (dr_segment_4) on accounts
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_GR_Code( pi_man_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_PC_Code
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.03.2020  creation  LAP85-23 CSR 170
--
-- Purpose: Get PC (Business Type) on customer_type and policy class
--  id     name                        GR
--  1    NATIONAL CUSTOMER             00
--  2    FOREIGN CLIENT                00
--  3    STATE CLIENT                  00
--  4    GROUP CONTRIBUTOR             00
--  5    GROUP COMPANIES               Depends of the Policy Class
--  6    SHAREHOLDER COMPANIES         Depends of the Policy Class
--  7    CO-INSURER/REINSURER CLIENT   00
--
--  Policy Class               PC Code
--  DIRECT                       01
--  DIRECT + CEDED_CO            01
--  DIRECT + CEDED_RI            01
--  DIRECT + CEDED_CO + CEDED_RI 01
--  Others                       02
--
-- Input parameters:
--     pi_man_id          VARCHAR2        Man ID;
--     pi_policy_class    VARCHAR2        Policy class;
--
-- Returns: PC - 00/01/02
--
-- Usage: When need to know PC (segment_4) on accounts
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_PC_Code( pi_man_id     IN VARCHAR2,
                      policy_class  IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Proforma_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   06.11.2019  creation - RB-2157
--
-- Purpose: Get doc type from document in which premium installment for given
-- external_id(blc_policy_payment_plan.policy_pplan_id) is included
--
-- Input parameters:
--     pi_external_id        VARCHAR2      Installment external Id;
--
-- Returns: doc number
--
-- Usage: When need to know doc type for the payment plan id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Proforma_Type
  (pi_external_id IN VARCHAR2 )
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_PiadUp_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.11.2019  creation LPVS-159
--
-- Purpose: Get paid-up for given policy
--
-- Input parameters:
--     pi_policy_id          NUMBER       Policy Id;
--
-- Returns:
--     annex id
--
-- Usage: When need to know paid-up annex
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_PiadUp_Annex
   (pi_policy_id   IN     NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Insured_value
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   22.11.2019  creation - LPV-2158
--
-- Purpose: Get man id
--
-- Input parameters:
--     pi_policy          NUMBER       Policy ID;
--
-- Purpose: Get insured value
--
-- Usage: When need to know insured value
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Insured_value
   (pi_policy_id IN NUMBER)
RETURN NUMBER;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Loan_Int_Rate
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   22.11.2019  creation - LPV-2158
--
-- Purpose: Get interest rate
--
-- Input parameters:
--     pi_policy          NUMBER       Policy ID;
--     pi_annex_id        NUMBER       Annex ID;
--     pi_amn_id          NUMBER       Man ID;
--
-- Returns: interest rate
--
-- Usage: When need to know interest rate
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Loan_Int_Rate
   (pi_policy_id IN NUMBER,
    pi_annex_id  IN NUMBER,
    pi_man_id    IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Loan_Periods
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   22.11.2019  creation - LPV-2158
--
-- Purpose: Get loan periods
--
-- Input parameters:
--     pi_policy          NUMBER       Policy ID;
--     pi_annex_id        NUMBER       Annex ID;
--     pi_amn_id          NUMBER       Man ID;
--
-- Returns: loan periods
--
-- Usage: When need to know loan periods
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Loan_Periods
   (pi_policy_id IN NUMBER,
    pi_annex_id  IN NUMBER,
    pi_man_id    IN NUMBER)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Is_Spec_Claim_Cover_Risk
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.01.2010 - LPV-2391
--
-- Purpose: To calculate is combination insr_type, cover and risk is specific
--
-- Input parameters:
--     pi_claim              VARCHAR2  Claim id (required);
--     pi_claim_payment      VARCHAR2  Claim payment id (required);
--
-- Returns: Y - specific, N - non specific
--
-- Usage: When need to know if claim has specific cover, risk
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Spec_Claim_Cover_Risk
           (pi_claim              IN VARCHAR2,
            pi_claim_payment      IN VARCHAR2)
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Prof_Priority_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.02.2021  creation LAP85-97
--
-- Purpose: Get priority for bill proforma
--
-- Input parameters:
--     pi_run_mode        VARCHAR2      Run Mode;
--     pi_bill_method_id  NUMBER        Bill method Id;
--     pi_policy_type     VARCHAR2      Policy Type - blc_item.attrib_7;
--
-- Returns:
--     priority HIGH/MASS
--
-- Usage: When need to know priority
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Prof_Priority_2
   (pi_run_mode       IN     VARCHAR2,
    pi_bill_method_id IN     NUMBER,
    pi_policy_type    IN     VARCHAR2)
RETURN VARCHAR2;
--
END CUST_ACC_UTIL_PKG;
/


