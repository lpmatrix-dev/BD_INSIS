CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_ACC_UTIL_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during accounting process.
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

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_acc_util_pkg';
--==============================================================================

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
--     Fadata   09.10.2017  creation
--
-- Purpose: Get office code for given office_id
--
-- Input parameters:
--     pi_office_id          NUMBER        Office Id;
--
-- Returns:
--     Office code
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
   (pi_office_id   IN     NUMBER)
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_office_code     VARCHAR2(50);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Office_Code';

   SELECT po.office_no
   INTO l_office_code
   FROM p_offices po
   WHERE po.office_id = pi_office_id;

   l_office_code := ltrim(l_office_code,'0');

   RETURN l_office_code;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Office_Code;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Currency_Code
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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_currency_code   VARCHAR2(10);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Currency_Code';

   IF pi_currency = 'PEN'
   THEN
      l_currency_code := '1';
   ELSIF pi_currency = 'USD'
   THEN
      l_currency_code := '2';
   END IF;

   RETURN l_currency_code;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Currency_Code;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_company_code    VARCHAR2(50);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Company_Code';

   SELECT acc_code
   INTO l_company_code
   FROM blc_orgs
   WHERE org_id = pi_org_id;

   RETURN l_company_code;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Company_Code;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_rr_type         VARCHAR2(50);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Tech_Brnch_RR';

   IF pi_tech_branch IS NULL
   THEN
      l_rr_type := NULL;
   ELSE
      l_rr_type := blc_common_pkg.Get_Lookup_Attrib_Value('CUST_LPV_XX_VS_RR',pi_tech_branch,0,NULL,0);
   END IF;

   RETURN l_rr_type;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Tech_Brnch_RR;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_bus_unit        VARCHAR2(50);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Business_Unit';

   IF pi_sales_channel IS NULL
   THEN
      l_bus_unit := NULL;
   ELSE
      l_bus_unit := blc_common_pkg.Get_Lookup_Attrib_Value('CUST_LPV_BUS_UNIT_VS_SALE_CHAN',pi_sales_channel,0,NULL,0);
   END IF;

   RETURN l_bus_unit;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Business_Unit;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_Intrmd_Type -- not in use, use Get_Pol_Intrmd_Type
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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_intrmd_type     VARCHAR2(50);
  l_count           PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Intrmd_Type';

   IF pi_sales_channel IS NULL
   THEN
      l_intrmd_type := NULL;
   ELSE
      SELECT count(*)
      INTO l_count
      FROM blc_lookups
      WHERE lookup_set = 'CUST_LPV_INTERMD_TYP_SALE_CHAN'
      AND lookup_code = pi_sales_channel;

      IF l_count = 0
      THEN
         l_intrmd_type := 'I';
      ELSE
         l_intrmd_type := 'D';
      END IF;
   END IF;

   RETURN l_intrmd_type;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Intrmd_Type;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_reception_date  DATE;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Claim_Reception_Date';

   --
   RETURN l_reception_date;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Claim_Reception_Date;

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
--     Fadata   08.02.2018  changed LPV-819, change policy_no with policy_name
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
RETURN VARCHAR2
IS
    l_log_module      VARCHAR2(240);
    --
    l_policy_level        VARCHAR2(30);
    l_master_policy_id    NUMBER;
    l_policy_type         p_policy_type;
    l_master_policy_name  VARCHAR2(50);
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Get_Policy_Master';

    -- RETURN cust_billing_pkg.Get_Item_Agreement( pi_policy_id, NULL, NULL); -- comment LPV-819
    l_policy_level := cust_billing_pkg.Get_Policy_Level( pi_policy_id, NULL, NULL );
    --
    IF l_policy_level = 'INDIVIDUAL'
    THEN
        l_policy_type := pol_types.get_policy( pi_policy_id );
    ELSE
        l_master_policy_id := cust_billing_pkg.Get_Master_Policy_Id( pi_policy_id );
        l_policy_type := pol_types.get_policy(nvl(l_master_policy_id, pi_policy_id));
    END IF;
    --
    l_master_policy_name := l_policy_type.policy_name;
    --
    RETURN l_master_policy_name;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_Master;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_currency        VARCHAR2(3);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Bank_Acc_Currency';

   SELECT pba.account_currency
   INTO l_currency
   FROM p_banks pb,
        p_bank_account pba
   WHERE pb.bank_id =  pba.bank_id
   AND nvl(pb.bank_code, pb.swift_code) = pi_bank_code
   AND pba.account_num = pi_bank_account_code;

   RETURN l_currency;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Bank_Acc_Currency;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_amount          NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Trx_Savings';

   SELECT nvl(sum(bts.amount),0)
   INTO l_amount
   FROM blc_transactions bt,
        blc_transactions bts
   WHERE bt.transaction_id = pi_transaction_id
   AND bt.transaction_type = 'PREMIUM'
   AND bt.doc_id = bts.doc_id
   AND bts.transaction_type = 'PREMIUM_SAVING'
   AND blc_appl_util_pkg.Get_Trx_External_Id(bt.transaction_id) = blc_appl_util_pkg.Get_Trx_External_Id(bts.transaction_id);

   RETURN l_amount;
EXCEPTION
   WHEN OTHERS THEN
     RETURN 0;
END Get_Trx_Savings;

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
--     Fadata   12.07.2021  changed LPV-2985, check treaty attribute UEISFATRTY
--
-- Purpose: Get if there is RI facultative for given policy_id
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id;
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
FUNCTION Get_Policy_RI_Fac
   (pi_policy_id   IN     NUMBER)
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_ri_flag         VARCHAR2(1);
  l_count           PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Policy_RI_Fac';

   SELECT count(*)
   INTO l_count
   FROM ri_fac rf
   WHERE rf.policy_id = pi_policy_id
   AND rf.fac_type = 'FAC'
   AND rf.inout_flag = 'OUTWARD';

   IF l_count > 0
   THEN
      l_ri_flag := 'Y';
   ELSE
      --LPV-2985 start
      --l_ri_flag := 'N';

      SELECT count(*)
      INTO l_count
      FROM insis_gen_ri_v10.ri_ceded_premiums rcp,
           insis_gen_ri_v10.ri_ceded_premiums_treaty rct,
           insis_gen_ri_v10.ri_treaty_attributes ta
      WHERE rcp.policy_id = pi_policy_id
      AND rcp.ri_treaty_prem_id = rct.ri_treaty_prem_id
      AND rcp.policy_pplan_id IS NOT NULL
      AND rcp.ri_clause_type IN ('QS', 'SP')
      AND rct.ri_treaty_id = ta.treaty_id
      AND ta.attribute_id = 'UEISFATRTY'
      AND ta.attribute_value = 'Y';

       IF l_count > 0
       THEN
          l_ri_flag := 'Y';
       ELSE
          l_ri_flag := 'N';
       END IF;
       --LPV-2985 end
   END IF;

   RETURN l_ri_flag;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_RI_Fac;

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
--     Fadata   12.07.2021  changed LPV-2985, check treaty attribute UEISFATRTY
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
RETURN VARCHAR2
IS
  l_ri_flag         VARCHAR2(1);
  --LPV-2985
  l_count_ue        SIMPLE_INTEGER := 0;
BEGIN
   IF pi_ri_clause IS NOT NULL
   THEN
      IF pi_ri_fac_id IS NOT NULL
      THEN
         l_ri_flag := 'Y';
      ELSE
         --LPV-2985 start
         --l_ri_flag := 'N';

         IF pi_ri_clause IN ('QS', 'SP')
         THEN
             SELECT count(*)
             INTO l_count_ue
             FROM insis_gen_ri_v10.ri_treaty_attributes ta
             WHERE ta.treaty_id = TO_NUMBER(pi_treaty_id)
             AND ta.attribute_id = 'UEISFATRTY'
             AND ta.attribute_value = 'Y';

             IF l_count_ue > 0
             THEN
                l_ri_flag := 'Y';
             ELSE
                l_ri_flag := 'N';
             END IF;
         ELSE
            l_ri_flag := 'N';
         END IF;
         --LPV-2985 end
      END IF;
   ELSE
      l_ri_flag := Get_Policy_RI_Fac(pi_policy_id);
   END IF;

   RETURN l_ri_flag;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_RI_Fac_2;

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
--     Fadata   08.03.2019  changed - add calculation for special case 'M-%'
--                                    LPVS-98
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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_doc_number      VARCHAR2(30);
  l_reference       blc_documents.reference%TYPE;
  l_ref_doc_id      blc_documents.doc_id%TYPE;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Ref_Doc_Number';

   SELECT bd.reference
   INTO l_reference
   FROM blc_documents bd
   WHERE bd.doc_id = pi_doc_id;

   IF l_reference like 'M-%'
   THEN
      l_doc_number := TRIM(substr(l_reference,3));
   ELSE
      l_ref_doc_id := TO_NUMBER(l_reference);

      SELECT bdr.doc_number
      INTO l_doc_number
      FROM blc_documents bdr
      WHERE bdr.doc_id = l_ref_doc_id;
   END IF;

   RETURN l_doc_number;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Ref_Doc_Number;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_date_char       VARCHAR2(30);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Doc_Start_Date';

   SELECT /*+ leading(bt) use_nl(bi) */
          MIN(bi.attrib_4)
   INTO l_date_char
   FROM blc_transactions bt,
        blc_installments bi
   WHERE bt.doc_id = pi_doc_id
   AND bt.transaction_id = bi.transaction_id;

   RETURN to_date(l_date_char,'YYYY-MM-DD');

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Doc_Start_Date;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_date_char       VARCHAR2(30);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Doc_End_Date';

   SELECT /*+ leading(bt) use_nl(bi) */
         MAX(bi.attrib_5)
   INTO l_date_char
   FROM blc_transactions bt,
        blc_installments bi
   WHERE bt.doc_id = pi_doc_id
   AND bt.transaction_id = bi.transaction_id;

   RETURN to_date(l_date_char,'YYYY-MM-DD');

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Doc_End_Date;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_date            DATE;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Policy_Start_Date';

   SELECT /*+ leading(bt) use_nl(bi, pp) */
          MIN(trunc(pp.insr_begin))
   INTO l_date
   FROM blc_transactions bt,
        blc_installments bi,
        policy pp
   WHERE bt.doc_id = pi_doc_id
   AND bt.transaction_id = bi.transaction_id
   AND to_number(bi.policy) = pp.policy_id;

   RETURN l_date;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_Start_Date;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_date            DATE;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Policy_End_Date';

   SELECT /*+ leading(bt) use_nl(bi, pp) */
         MAX(trunc(pp.insr_end)-1)
   INTO l_date
   FROM blc_transactions bt,
        blc_installments bi,
        policy pp
   WHERE bt.doc_id = pi_doc_id
   AND bt.transaction_id = bi.transaction_id
   AND to_number(bi.policy) = pp.policy_id;

   RETURN l_date;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_End_Date;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_end_flag        VARCHAR2(1);
  l_count           PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Pol_End_Flag';

   SELECT count(*)
   INTO l_count
   FROM policy_participants pp
   WHERE pp.policy_id = pi_policy_id
   AND pp.particpant_role = 'FINBENEF';

   IF l_count > 0
   THEN
      l_end_flag := 'Y';
   ELSE
      l_end_flag := 'N';
   END IF;

   RETURN l_end_flag;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Pol_End_Flag;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_party_name      VARCHAR2(400 CHAR);
  --
  CURSOR c_end_party IS
     SELECT pl.name
     FROM policy_participants pp,
          p_people pl
     WHERE pp.policy_id = pi_policy_id
     AND pp.particpant_role = 'FINBENEF'
     AND pp.man_id = pl.man_id
     ORDER BY pp.annex_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Pol_End_Party_Name';

   OPEN c_end_party;
     FETCH c_end_party
     INTO l_party_name;
   CLOSE c_end_party;

   RETURN l_party_name;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Pol_End_Party_Name;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_party           VARCHAR2(30);
  --
   CURSOR c_end_party IS
     SELECT pp.man_id
     FROM policy_participants pp
     WHERE pp.policy_id = pi_policy_id
     AND pp.particpant_role = 'FINBENEF'
     ORDER BY pp.annex_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Pol_End_Party';

   OPEN c_end_party;
     FETCH c_end_party
     INTO l_party;
   CLOSE c_end_party;

   RETURN l_party;

   RETURN NULL;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Pol_End_Party;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_amount          NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Doc_Prem_Amount';

   SELECT nvl(sum(bt.amount),0)
   INTO l_amount
   FROM blc_transactions bt
   WHERE bt.doc_id = pi_doc_id
   AND bt.transaction_type <> 'VAT';

   RETURN l_amount;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Doc_Prem_Amount;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_intrmd_type     VARCHAR2(30);
  l_to_date         DATE;
  --
  /*
  CURSOR c_group IS
     SELECT pg.group_code
     FROM policy p,
          p_agents pa,
          p_people_groups pg
     WHERE p.policy_id = pi_policy_id
     AND p.agent_id = pa.agent_id
     AND pa.man_id = pg.man_id
     AND l_to_date BETWEEN nvl(trunc(pg.from_date),l_to_date) AND nvl(trunc(pg.to_date),l_to_date)
     AND pg.group_code IN ('S', 'P', 'E', 'O', 'D');
  */
  CURSOR c_group IS
     SELECT pg.group_code
     FROM policy_agents ppa,
          p_agents pa,
          p_people_groups pg
     WHERE ppa.policy_id = pi_policy_id
     AND ppa.agent_role = 'BROK'
     AND ppa.agent_id = pa.agent_id
     AND pa.man_id = pg.man_id
     AND l_to_date BETWEEN nvl(trunc(pg.from_date),l_to_date) AND nvl(trunc(pg.to_date),l_to_date)
     AND pg.group_code IN ('S', 'P', 'E', 'O', 'D')
     ORDER BY ppa.policy_agent_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Pol_Intrmd_Type';
   /*
   SELECT pa.qualif_level
   INTO l_intrmd_type
   FROM policy p,
        p_agents pa
   WHERE p.policy_id = pi_policy_id
   AND p.agent_id = pa.agent_id;
   */
   IF pi_to_date IS NOT NULL
   THEN
      l_to_date := pi_to_date;
   ELSE
      l_to_date := trunc(sys_days.get_open_date);
   END IF;

   OPEN c_group;
     FETCH c_group
     INTO l_intrmd_type;
   CLOSE c_group;

   l_intrmd_type := nvl(l_intrmd_type,'0');

   RETURN l_intrmd_type;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Pol_Intrmd_Type;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_vat_flag        VARCHAR2(1);
  l_count           PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Doc_VAT_Flag';

   SELECT count(*)
   INTO l_count
   FROM blc_transactions
   WHERE doc_id = pi_doc_id
   AND transaction_type = 'VAT';

   IF l_count > 0
   THEN
      l_vat_flag := 'Y';
   ELSE
      l_vat_flag := 'N';
   END IF;

   RETURN l_vat_flag;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Doc_VAT_Flag;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_policy_class    VARCHAR2(10);
  l_count           PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Policy_Class';

   SELECT count(*)
   INTO l_count
   FROM ri_fac rf
   WHERE rf.policy_id = pi_policy_id
   AND rf.fac_type = 'COINS'
   AND rf.inout_flag = 'INWARD';

   IF l_count > 0
   THEN
      l_policy_class := 'A';
   ELSE
      l_policy_class := 'D';
      --
      SELECT count(*)
      INTO l_count
      FROM ri_fac rf
      WHERE rf.policy_id = pi_policy_id
      AND rf.fac_type = 'COINS'
      AND rf.inout_flag = 'OUTWARD';

      IF l_count > 0
      THEN
         l_policy_class := l_policy_class||'C';
      END IF;
      --
      SELECT count(*)
      INTO l_count
      FROM ri_ceded_premiums rcp
      WHERE rcp.policy_id = pi_policy_id
      AND rcp.ri_treaty_prem_id IS NOT NULL;

      IF l_count > 0 OR Get_Policy_RI_Fac(pi_policy_id) = 'Y'
      THEN
         l_policy_class := l_policy_class||'R';
      END IF;
   END IF;


   RETURN l_policy_class;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_Class;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_percent         NUMBER;
  --
  /*
  CURSOR c_co_rate IS
    SELECT ri.risk_share
    FROM ri_fac rf,
         ri_fac_insurers ri
    WHERE rf.policy_id = pi_policy_id
    AND rf.ri_fac_no = pi_fac_no
    AND rf.ri_fac_id = ri.ri_fac_id
    AND insurer_id = pi_insurer_id
    ORDER BY ri.ri_fac_id DESC;
  */
  --
  CURSOR c_co_rate IS
    SELECT (rc.placement*ri.risk_share)/100
    FROM ri_fac rf,
         ri_fac_coverage rc,
         ri_fac_insurers ri
    WHERE rf.policy_id = pi_policy_id
    AND rf.ri_fac_no = pi_fac_no
    AND rf.ri_fac_id = rc.ri_fac_id
    AND rc.insurer_group_id = ri.insurer_group_id
    AND ri.insurer_id = pi_insurer_id
    ORDER BY rf.ri_fac_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Coins_Percent';

   OPEN c_co_rate;
     FETCH c_co_rate
     INTO l_percent;
   CLOSE c_co_rate;

   RETURN l_percent;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Coins_Percent;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_percent         NUMBER;
  l_policy_id       NUMBER;
  l_policy_pplan_id NUMBER;
  --
  CURSOR c_co_rate IS
    SELECT rc.ri_share
    FROM ri_ceded_premiums rc,
         ri_ceded_premiums_fac rcf,
         ri_fac rf
    WHERE rc.policy_id = l_policy_id
    AND rc.policy_pplan_id = l_policy_pplan_id
    AND rc.premium_type = 'DUEPP'
    AND rc.ri_fac_prem_id = rcf.ri_fac_prem_id
    AND rcf.ri_fac_insurer = pi_insurer_id
    AND rcf.ri_fac_id = rf.ri_fac_id
    AND rf.ri_fac_no = pi_fac_no;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Coins_Percent_Ext';

   l_policy_id := to_number(pi_policy_id);
   l_policy_pplan_id := to_number(pi_external_id);

   OPEN c_co_rate;
     FETCH c_co_rate
     INTO l_percent;
   CLOSE c_co_rate;

   RETURN l_percent;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Coins_Percent_Ext;

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
RETURN VARCHAR2
IS
BEGIN
    IF pi_amount IS NULL
    THEN
        RETURN NULL;
    END IF;
    --
    RETURN( LTRIM( TO_CHAR( pi_amount, '999999999999999990D00' ) ) );
    --
EXCEPTION WHEN OTHERS THEN RETURN pi_amount;
END Convert_Amount_To_Char;

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
RETURN NUMBER
IS
    l_number   NUMBER;
BEGIN
    l_number := to_number(pi_value);

    RETURN nvl(l_number,0);
    --
EXCEPTION
   WHEN OTHERS THEN
      RETURN 0;
END;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_account_attribs VARCHAR2(10);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_GL_Account_Attribs';

   SELECT bam.attrib_7||'-'||bam.attrib_8||'-'||bam.attrib_9
   INTO l_account_attribs
   FROM INSIS_GEN_BLC_V10.blc_sla_acc_map_rules bam
   WHERE bam.account = pi_gl_account;

   RETURN l_account_attribs;
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_GL_Account_Attribs;

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
RETURN VARCHAR2
IS
    l_party_name      VARCHAR2(400 CHAR);
BEGIN
    IF pi_party IS NULL
    THEN RETURN NULL;
    END IF;
    --
    SELECT pl.name INTO l_party_name
    FROM p_people pl
    WHERE pl.man_id = TO_NUMBER(pi_party);
    --
    RETURN l_party_name;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_Party_Name;

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
RETURN NUMBER
IS
    l_man_id          NUMBER;
    --
    CURSOR c_ins IS
    SELECT oai.man_id
    FROM insured_object iob,
         o_accinsured  oai
    WHERE iob.policy_id = TO_NUMBER( pi_policy_id )
        AND iob.object_id = oai.object_id
    ORDER BY iob.annex_id DESC;
BEGIN
    OPEN c_ins;
    FETCH c_ins INTO l_man_id;
    CLOSE c_ins;
    --
    RETURN l_man_id;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_Accepted_Benef_Id;

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
RETURN VARCHAR2
IS
    l_party         VARCHAR2(30 CHAR);
    l_party_name    VARCHAR2(400 CHAR);
BEGIN
    l_party := Get_Accepted_Benef_Id(pi_policy_id);
    l_party_name := Get_Party_Name(l_party);
    --
    RETURN l_party_name;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_Accepted_Benef_Name;

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
RETURN VARCHAR2
IS
    l_party          blc_accounts.party%TYPE;
BEGIN
    IF pi_parent_external_id IS NULL
    THEN RETURN NULL;
    END IF;
    --
    SELECT a.party INTO l_party
    FROM blc_installments i, blc_accounts a
    WHERE i.external_id = pi_parent_external_id
        AND i.account_id = a.account_id
    GROUP BY a.party;
    --
    RETURN l_party;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_RI_Benef_Id;

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
RETURN VARCHAR2
IS
    l_party         VARCHAR2(30 CHAR);
    l_party_name    VARCHAR2(400 CHAR);
BEGIN
    l_party := Get_RI_Benef_Id(pi_parent_external_id);
    l_party_name := Get_Party_Name(l_party);
    --
    RETURN l_party_name;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_RI_Benef_Name;

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
RETURN VARCHAR2
IS
    l_bank_account_type      VARCHAR2(30);
BEGIN

    RETURN l_bank_account_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_Pmnt_Bank_Account_Type;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Contr_Type_Claim
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.11.2017  creation
--     Fadata   08.05.2018 changed - LPV-1566
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
RETURN VARCHAR2
IS
    l_type      VARCHAR2(30);
BEGIN
   /*
    IF pi_treaty IS NOT NULL
    THEN
        BEGIN
            SELECT treaty_type
            INTO l_type
            FROM insis_gen_ri_v10.ri_treaty
            WHERE treaty_id = pi_treaty;
        EXCEPTION
          WHEN OTHERS THEN
            l_type := NULL;
        END;
    END IF;
  */

    --SELECT DISTINCT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'NPR', 'NPR' ) INTO l_type --LPV-1566
    SELECT DISTINCT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NPR' ) INTO l_type --LPV-1566
    FROM ri_ceded_claims
    WHERE claim_id = TO_NUMBER( pi_claim_id );

    --
    RETURN l_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_RI_Contr_Type_Claim;

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
RETURN VARCHAR2
IS
    l_type      VARCHAR2(30);
BEGIN
   IF pi_ri_clause IS NOT NULL
   THEN
      IF pi_ri_clause IN ('QS', 'SP')
      THEN
         l_type := 'PR';
      ELSE
         l_type := 'NPR';
      END IF;
   ELSE
      l_type := Get_RI_Contr_Type_Claim(pi_claim_id);
   END IF;
   --
   RETURN l_type;
   --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_RI_Contr_Type_Claim_2;

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
--      changed with JIRA LPV-1732 - change + correction
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
RETURN VARCHAR2
IS
    l_pr_flag       VARCHAR2(3);
    l_fac_count     PLS_INTEGER;
    l_treaty_count  PLS_INTEGER;
    l_count_ue      SIMPLE_INTEGER := 0;
    --l_ri_treaty_attr_id insis_gen_ri_v10.ri_treaty_attributes.attribute_id%TYPE;
    --l_ri_treaty_attr_value insis_gen_ri_v10.ri_treaty_attributes.attribute_value%TYPE;

BEGIN
    SELECT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NP' ), COUNT( ri_fac_record_id ), COUNT( ri_treaty_record_id )
        INTO l_pr_flag, l_fac_count, l_treaty_count
    FROM ri_ceded_claims
    WHERE claim_id = TO_NUMBER( pi_claim_id )
    GROUP BY DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NP' );

     -- before JIRA LPV-1732
    /*
    IF l_pr_flag = 'PR'
    THEN
        IF l_fac_count > 0
        THEN
            RETURN '02';
        ELSE
            IF l_fac_count = 0
               AND insis_gen_ri_v10.ri_treaty_attributes.attribute_id = 'UEISFATRTY'
               AND insis_gen_ri_v10.ri_treaty_attributes.attribute_value = 'Y'
            THEN
                RETURN '02';
            ELSE
                RETURN '01';
            END IF;
        END IF;
        */
     -- before JIRA LPV-1732

 -- JIRA LPV-1732
/*
    l_ri_treaty_attr_id := 'NO_SUCH';
    l_ri_treaty_attr_value := '0';
    SELECT attribute_id, attribute_value
        INTO l_ri_treaty_attr_id, l_ri_treaty_attr_value
    FROM insis_gen_ri_v10.ri_treaty_attributes
    WHERE treaty_id IN
        (
    SELECT ri_treaty_id
            FROM insis_gen_ri_v10.ri_ceded_claims_treaty
            WHERE ri_treaty_record_id IN
                (
                SELECT ri_treaty_record_id
                    FROM insis_gen_ri_v10.ri_ceded_claims
                    WHERE claim_id = pi_claim_id
                )
        )
        AND attribute_id = 'UEISFATRTY'
        AND attribute_value = 'Y';

    --
    IF l_pr_flag = 'PR'
    THEN
        IF l_fac_count > 0
        THEN
            RETURN '02';
        ELSE
            IF  l_fac_count = 0

                AND l_ri_treaty_attr_id = 'UEISFATRTY'

                AND l_ri_treaty_attr_value = 'Y'
            THEN
                RETURN '02';
            ELSE
                RETURN '01';
            END IF;
        END IF;
    ELSE
        IF l_fac_count > 0
        THEN
            RETURN '04';
        ELSE
            RETURN '03';
        END IF;
    END IF;
    --
    */

 -- JIRA LPV-1732

 -- JIRA LPV-1732 after 17-08-2018
/*
 l_ri_treaty_attr_id := 'NO_SUCH';
 l_ri_treaty_attr_value := '0';

     FOR attr IN
        (SELECT attribute_id, attribute_value
          FROM insis_gen_ri_v10.ri_treaty_attributes
         WHERE     treaty_id IN
         (
        SELECT ri_treaty_id
            FROM insis_gen_ri_v10.ri_ceded_claims_treaty
            WHERE ri_treaty_record_id IN
                (
                SELECT ri_treaty_record_id
                    FROM insis_gen_ri_v10.ri_ceded_claims
                    WHERE claim_id = pi_claim_id
                )
        )
               AND attribute_id = 'UEISFATRTY'
               AND attribute_value = 'Y')
        LOOP
               l_ri_treaty_attr_id := attr.attribute_id;
               l_ri_treaty_attr_value := attr.attribute_value;
        END LOOP;
*/
        --
        IF l_pr_flag = 'PR'
        THEN
            IF l_fac_count > 0
            THEN
                RETURN '02';
            ELSE
                SELECT count(*)
                INTO l_count_ue
                FROM insis_gen_ri_v10.ri_ceded_claims cc,
                     insis_gen_ri_v10.ri_ceded_claims_treaty cct,
                     insis_gen_ri_v10.ri_treaty_attributes ta
                WHERE cc.claim_id = pi_claim_id
                AND cc.ri_treaty_record_id = cct.ri_treaty_record_id
                AND cct.ri_treaty_id = ta.treaty_id
                AND ta.attribute_id = 'UEISFATRTY'
                AND ta.attribute_value = 'Y';

                --IF     l_ri_treaty_attr_id = 'UEISFATRTY' -- l_fac_count = 0
                --       AND l_ri_treaty_attr_value = 'Y'
                IF l_count_ue > 0
                THEN
                     RETURN '02';
                ELSE
                    RETURN '01';

                END IF;
            END IF;
        ELSE
            IF l_fac_count > 0
            THEN
                RETURN '04';
            ELSE
                RETURN '03';
            END IF;
        END IF;

-- JIRA LPV-1732 after 17-08-2018

EXCEPTION
    WHEN OTHERS THEN RETURN NULL;

END Get_RI_Type_Claim;

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
RETURN VARCHAR2
IS
    l_pr_flag       VARCHAR2(3);
    l_ri_type       VARCHAR2(2);
    l_count_ue      SIMPLE_INTEGER := 0;
BEGIN
    IF pi_ri_clause IS NOT NULL
    THEN
       IF pi_ri_clause IN ('QS', 'SP')
       THEN
          l_pr_flag := 'PR';
       ELSE
          l_pr_flag := 'NPR';
       END IF;

       IF l_pr_flag = 'PR'
       THEN
          IF pi_ri_fac_id IS NOT NULL
          THEN
             l_ri_type := '02';
          ELSE
             SELECT count(*)
             INTO l_count_ue
             FROM insis_gen_ri_v10.ri_treaty_attributes ta
             WHERE ta.treaty_id = TO_NUMBER(pi_treaty_id)
             AND ta.attribute_id = 'UEISFATRTY'
             AND ta.attribute_value = 'Y';

              IF l_count_ue > 0
              THEN
                 l_ri_type := '02';
              ELSE
                 l_ri_type := '01';
              END IF;
          END IF;
       ELSE
          IF pi_ri_fac_id IS NOT NULL
          THEN
             l_ri_type := '04';
          ELSE
             l_ri_type := '03';
          END IF;
       END IF;
    ELSE
       l_ri_type := Get_RI_Type_Claim( pi_claim_id );
    END IF;

    RETURN l_ri_type;

EXCEPTION
    WHEN OTHERS THEN RETURN NULL;

END Get_RI_Type_Claim_2;

--------------------------------------------------------------------------------
-- Name: cust_acc_util_pkg.Get_RI_Type_Claim_E
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.11.2017  creation
--      changed with JIRA LPV-1732 - change + correction
--
-- Purpose: Reinsurance Type
--
-- Input parameters:
--     pi_claim_id         VARCHAR2      Claim Id;
--     pi_external_id      VARCHAR2      External Id;
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
FUNCTION Get_RI_Type_Claim_E
        ( pi_claim_id IN VARCHAR2,
          pi_external_id IN VARCHAR2)
RETURN VARCHAR2
IS
    l_pr_flag              VARCHAR2(3);
    l_ri_fac_record_id     NUMBER;
    l_ri_treaty_record_id  NUMBER;
    l_count_ue             SIMPLE_INTEGER := 0;
BEGIN
    SELECT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NP' ), ri_fac_record_id, ri_treaty_record_id
    INTO l_pr_flag, l_ri_fac_record_id, l_ri_treaty_record_id
    FROM ri_ceded_claims
    WHERE claim_id = TO_NUMBER( pi_claim_id )
    AND ri_record_id = TO_NUMBER( pi_external_id );

    IF l_pr_flag = 'PR'
    THEN
       IF l_ri_fac_record_id IS NOT NULL
       THEN
          RETURN '02';
       ELSE
          SELECT count(*)
          INTO l_count_ue
          FROM insis_gen_ri_v10.ri_treaty_attributes ta,
               insis_gen_ri_v10.ri_ceded_claims_treaty ct
          WHERE ta.treaty_id = ct.ri_treaty_id
          AND ct.ri_treaty_record_id = l_ri_treaty_record_id
          AND ta.attribute_id = 'UEISFATRTY'
          AND ta.attribute_value = 'Y';

          IF l_count_ue > 0
          THEN
             RETURN '02';
          ELSE
             RETURN '01';
          END IF;
       END IF;
    ELSE
       IF l_ri_fac_record_id IS NOT NULL
       THEN
          RETURN '04';
       ELSE
          RETURN '03';
       END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END Get_RI_Type_Claim_E;

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
RETURN NUMBER
IS
    l_claim_payment_id NUMBER;
    l_external_id      NUMBER;
BEGIN
    l_external_id := TO_NUMBER(pi_external_id);

    SELECT payment_ref_id
    INTO l_claim_payment_id
    FROM blc_claim
    WHERE blc_clm_pk = l_external_id;

    RETURN l_claim_payment_id;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Claim_Pmnt;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_percent         NUMBER;
  --
  CURSOR c_co_rate IS
    SELECT inward_placement
    FROM ri_fac ri
    WHERE inout_flag = 'INWARD'
    AND fac_type = 'COINS'
    AND policy_id = pi_policy_id
    ORDER BY ri.ri_fac_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_AC_Coins_Percent';

   OPEN c_co_rate;
     FETCH c_co_rate
     INTO l_percent;
   CLOSE c_co_rate;

   RETURN l_percent;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_AC_Coins_Percent;

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
RETURN VARCHAR2
IS
    l_type      VARCHAR2(30);
BEGIN
    --l_type := '01';

    SELECT DECODE(rta.attribute_value, 'Y', '03', '01')
        INTO l_type
        FROM insis_gen_ri_v10.ri_treaty_attributes rta, insis_gen_ri_v10.ri_ceded_claims_treaty rcct, insis_gen_ri_v10.ri_ceded_claims rcc
        WHERE rta.attribute_id = 'UEISFATRTY'
            AND rta.treaty_id = rcct.ri_treaty_id
            AND rcct.ri_treaty_record_id = rcc.ri_treaty_record_id
            AND rcc.claim_id = pi_claim_id
    GROUP BY DECODE(rta.attribute_value, 'Y', '03', '01');

    RETURN l_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_Treaty_Type_Claim;

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
RETURN VARCHAR2
IS
    l_type      VARCHAR2(30);
    l_count_ue  SIMPLE_INTEGER := 0;
BEGIN
   IF pi_ri_clause IS NOT NULL
   THEN
      IF pi_ri_fac_id IS NOT NULL
      THEN
         l_type := '03';
      ELSE
         SELECT count(*)
         INTO l_count_ue
         FROM insis_gen_ri_v10.ri_treaty_attributes ta
         WHERE ta.treaty_id = TO_NUMBER(pi_treaty_id)
         AND ta.attribute_id = 'UEISFATRTY'
         AND ta.attribute_value = 'Y';

         IF l_count_ue > 0
         THEN
            l_type := '03';
         ELSE
            l_type := '01';
         END IF;
      END IF;
   ELSE
      l_type := Get_Treaty_Type_Claim(pi_claim_id);
   END IF;

   RETURN l_type;
   --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_Treaty_Type_Claim_2;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_acc_code        VARCHAR2(30);

BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Insurer_Account_Number';

   SELECT pi.reg_num
   INTO l_acc_code
   FROM p_insurers pi
   WHERE insurer_id = TO_NUMBER(pi_insurer_id);

   RETURN l_acc_code;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Insurer_Account_Number;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_country         VARCHAR2(30);
  l_type            VARCHAR2(30);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_RI_Clm_Action_Type';

   IF pi_party IS NULL OR pi_currency IS NULL
   THEN
      l_type := 'AAA';
   ELSE
      SELECT home_country
      INTO l_country
      FROM p_people
      WHERE man_id = TO_NUMBER(pi_party);
      --
      IF l_country <> 'PE' AND pi_currency = 'USD'
      THEN
         l_type := 'CF1';
      ELSIF l_country = 'PE'
      THEN
         l_type := 'CSF';
      ELSE
         l_type := 'AAA';
      END IF;
   END IF;

   RETURN l_type;

EXCEPTION
   WHEN OTHERS THEN
     RETURN 'AAA';
END Get_RI_Clm_Action_Type;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_currency        VARCHAR2(3);
  --
  CURSOR c_item IS
    SELECT bill_currency
    FROM blc_items
    WHERE component = to_char(pi_policy_id)
    AND item_type = 'POLICY'
    ORDER BY item_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Policy_Currency';

   --l_currency := insis_gen_v10.pol_values.Get_policy_currency (pi_policy_id);

   OPEN c_item;
     FETCH c_item
     INTO l_currency;
   CLOSE c_item;

   RETURN l_currency;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_Currency;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_amount          NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_AC_Prem_Amount';

   SELECT nvl(sum(bii.amount),0)
   INTO l_amount
   FROM blc_items bi,
        blc_installments bii
   WHERE bi.component = pi_policy_id
   AND bi.item_type = 'AC'
   AND bi.item_id = bii.item_id
   AND bii.installment_type = 'BCPRCOA'
   AND bii.annex = pi_annex_id;

   RETURN l_amount*(-1);

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_AC_Prem_Amount;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_fac_no          VARCHAR2(100);
  --
  CURSOR c_co_no IS
    SELECT ri_fac_no
    FROM ri_fac ri
    WHERE inout_flag = 'INWARD'
    AND fac_type = 'COINS'
    AND policy_id = pi_policy_id
    ORDER BY ri.ri_fac_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_AC_Fac_No';

   OPEN c_co_no;
     FETCH c_co_no
     INTO l_fac_no;
   CLOSE c_co_no;

   RETURN l_fac_no;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_AC_Fac_No;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_report_number   VARCHAR2(100);

BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_AC_Rep_Number';

   SELECT quest_answer
   INTO l_report_number
   FROM quest_questions
   WHERE policy_id = pi_policy_id
   AND quest_id = 'COINSREPNUM'
   AND annex_id = '0';

   RETURN l_report_number;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_AC_Rep_Number;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_reception_date  VARCHAR2(100);

BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_AC_Reception_Date';

   SELECT quest_answer
   INTO l_reception_date
   FROM quest_questions
   WHERE policy_id = pi_policy_id
   AND quest_id = 'COINSREPDATE'
   AND annex_id = '0';

   RETURN to_date(l_reception_date,'dd-mm-yyyy');

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_AC_Reception_Date;

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
RETURN DATE
IS
  l_log_module      VARCHAR2(240);
  l_annex_date      DATE;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Annex_Convert_Date';

   IF pi_policy_id IS NULL OR pi_annex_id IS NULL
   THEN
      l_annex_date := NULL;
   ELSIF pi_annex_id = '0'
   THEN
      SELECT convert_date
      INTO l_annex_date
      FROM policy p
      WHERE p.policy_id = to_number(pi_policy_id);
   ELSE
      SELECT convert_date
      INTO l_annex_date
      FROM gen_annex ga
      WHERE ga.policy_id = to_number(pi_policy_id)
      AND ga.annex_id = to_number(pi_annex_id);
   END IF;

   RETURN l_annex_date;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Annex_Convert_Date;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_percent         NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Comm_Percent';

   SELECT bc.attrn1
   INTO l_percent
   FROM blc_commission bc
   WHERE bc.blc_com_pk = to_number(pi_external_id);

   RETURN l_percent;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Comm_Percent;

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
RETURN NUMBER
IS
    l_man_id           NUMBER;
    l_external_id      NUMBER;
BEGIN
    l_external_id := TO_NUMBER(pi_external_id);

    SELECT cp.man_id
    INTO l_man_id
    FROM blc_claim bc,
         claim_payments cp
    WHERE bc.blc_clm_pk = l_external_id
    AND bc.payment_ref_id = cp.payment_id;

    RETURN l_man_id;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Claim_Pmnt_Man_Id;

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
RETURN NUMBER
IS
BEGIN
    RETURN Get_Party_Name(Get_Claim_Pmnt_Man_Id( pi_external_id));
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Claim_Pmnt_Man_Name;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_man_id          NUMBER;
  --
  CURSOR c_holder IS
    SELECT man_id
    FROM policy_participants
    WHERE policy_id = pi_policy_id
    AND particpant_role = 'PHOLDER'
    ORDER BY participant_id DESC;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Policy_Holder_Man_id';

   OPEN c_holder;
     FETCH c_holder
     INTO l_man_id;
   CLOSE c_holder;

   RETURN l_man_id;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_Holder_Man_id;

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
RETURN VARCHAR2
IS
    l_doc_number       VARCHAR2(30);
    l_amnt_type        VARCHAR2(30);
    l_external_id      NUMBER;
    --
    CURSOR c_plan IS
      SELECT amnt_type, external_id
      FROM blc_policy_payment_plan
      WHERE policy_pplan_id = to_number(pi_external_id);
BEGIN
    OPEN c_plan;
      FETCH c_plan
      INTO l_amnt_type, l_external_id;
    CLOSE c_plan;

    IF l_amnt_type = 'DUE'
    THEN
       SELECT DISTINCT bd.doc_number
       INTO l_doc_number
       FROM blc_installments bi,
            blc_items bii,
            blc_transactions bt,
            blc_documents bd
       WHERE bi.external_id = pi_external_id
       AND bi.item_id = bii.item_id
       AND bii.item_type = 'POLICY'
       AND bi.transaction_id = bt.transaction_id
       AND bt.doc_id = bd.doc_id;
    ELSIF l_amnt_type = 'PAID'
    THEN
       SELECT bd.doc_number
       INTO l_doc_number
       FROM blc_applications ba,
            blc_transactions bt,
            blc_documents bd
       WHERE ba.application_id = l_external_id
       AND ba.target_trx = bt.transaction_id
       AND bt.doc_id = bd.doc_id;
    END IF;

    RETURN l_doc_number;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Proforma_Number;

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
--     Fadata   08.05.2018 changed - LPV-1566
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
RETURN VARCHAR2
IS
    l_type      VARCHAR2(30);
BEGIN

    --SELECT DISTINCT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'NPR', 'NPR' ) INTO l_type --LPV-1566
    SELECT DISTINCT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NPR' ) INTO l_type --LPV-1566
    FROM ri_ceded_premiums
    WHERE policy_id = pi_policy_id;

    --
    RETURN l_type;
    --
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END Get_RI_Contr_Type_Policy;

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
RETURN VARCHAR2
IS
    l_type      VARCHAR2(30);
BEGIN
   IF pi_ri_clause IS NOT NULL
   THEN
      IF pi_ri_clause IN ('QS', 'SP')
      THEN
         l_type := 'PR';
      ELSE
         l_type := 'NPR';
      END IF;
   ELSE
      l_type := Get_RI_Contr_Type_Policy(pi_policy_id);
   END IF;
   --
   RETURN l_type;
    --
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END Get_RI_Contr_Type_Policy_2;

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
--      changed with JIRA LPV-1732 - change + correction
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
RETURN VARCHAR2
IS
    l_pr_flag       VARCHAR2(3);
    l_fac_count     PLS_INTEGER;
    l_treaty_count  PLS_INTEGER;
--    l_ri_treaty_attr_id insis_gen_ri_v10.ri_treaty_attributes.attribute_id%TYPE;
--    l_ri_treaty_attr_value insis_gen_ri_v10.ri_treaty_attributes.attribute_value%TYPE;
    l_count_ue      SIMPLE_INTEGER := 0;
BEGIN
    SELECT DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NP' ), COUNT( ri_fac_prem_id ), COUNT( ri_treaty_prem_id )
        INTO l_pr_flag, l_fac_count, l_treaty_count
    FROM ri_ceded_premiums
    WHERE policy_id = pi_policy_id
    GROUP BY DECODE( ri_clause_type, 'QS', 'PR', 'SP', 'PR', 'NP' );

    /*

    code before JIRA LPV-1732 :

    IF l_pr_flag = 'PR'
    THEN
        IF l_fac_count > 0
        THEN
            RETURN '02';
        ELSE
            IF l_fac_count = 0
               AND insis_gen_ri_v10.ri_treaty_attributes.attribute_id = 'UEISFATRTY'
               AND insis_gen_ri_v10.ri_treaty_attributes.attribute_value = 'Y'
            THEN
                RETURN '02';
            ELSE
                RETURN '01';
            END IF;
        END IF;
    */

    -- JIRA LPV-1732

    /*
    l_ri_treaty_attr_id := 'NO_SUCH';
    l_ri_treaty_attr_value := '0';

    SELECT attribute_id, attribute_value
        INTO l_ri_treaty_attr_id, l_ri_treaty_attr_value
    FROM insis_gen_ri_v10.ri_treaty_attributes
    WHERE treaty_id IN
        (
        SELECT ri_treaty_id
            FROM insis_gen_ri_v10.ri_ceded_premiums_treaty
            WHERE ri_treaty_prem_id IN
                (
                SELECT ri_treaty_prem_id
                    FROM insis_gen_ri_v10.ri_ceded_premiums
                    WHERE policy_id = pi_policy_id
                )
        )
        AND attribute_id = 'UEISFATRTY'
        AND attribute_value = 'Y';
    --
    IF l_pr_flag = 'PR'
    THEN
        IF l_fac_count > 0
        THEN
            RETURN '02';
        ELSE
            IF l_fac_count < 0
            THEN
                RETURN '01';
            ELSE
                IF l_ri_treaty_attr_id = 'UEISFATRTY'   -- l_fac_count = 0
                    AND l_ri_treaty_attr_value = 'Y'
                THEN
                    RETURN '02';
                END IF;
            END IF;
        END IF;
    ELSE
        IF l_fac_count > 0
        THEN
            RETURN '04';
        ELSE
            RETURN '03';
        END IF;
    END IF;
    --
    */

-- JIRA LPV-1732

 -- JIRA LPV-1732 after 17-08-2018

/*
 l_ri_treaty_attr_id := 'NO_SUCH';
 l_ri_treaty_attr_value := '0';

     FOR attr IN
        (SELECT attribute_id, attribute_value
          FROM insis_gen_ri_v10.ri_treaty_attributes
         WHERE     treaty_id IN (SELECT ri_treaty_id
                                   FROM insis_gen_ri_v10.ri_ceded_premiums_treaty
                                  WHERE ri_treaty_prem_id IN (SELECT ri_treaty_prem_id
                                                                FROM insis_gen_ri_v10.ri_ceded_premiums
                                                               WHERE policy_id =
                                                                         pi_policy_id))
               AND attribute_id = 'UEISFATRTY'
               AND attribute_value = 'Y')
        LOOP
               l_ri_treaty_attr_id := attr.attribute_id;
               l_ri_treaty_attr_value := attr.attribute_value;
        END LOOP;
*/
        --
        IF l_pr_flag = 'PR'
        THEN
            IF l_fac_count > 0
            THEN
                RETURN '02';
            ELSE
                SELECT count(*)
                INTO l_count_ue
                FROM insis_gen_ri_v10.ri_ceded_premiums cp,
                     insis_gen_ri_v10.ri_ceded_premiums_treaty cpt,
                     insis_gen_ri_v10.ri_treaty_attributes ta
                WHERE cp.policy_id = pi_policy_id
                AND cp.ri_treaty_prem_id = cpt.ri_treaty_prem_id
                AND cpt.ri_treaty_id = ta.treaty_id
                AND ta.attribute_id = 'UEISFATRTY'
                AND ta.attribute_value = 'Y';

                --IF     l_ri_treaty_attr_id = 'UEISFATRTY' -- l_fac_count = 0
                --       AND l_ri_treaty_attr_value = 'Y'
                IF l_count_ue > 0
                THEN
                     RETURN '02';
                ELSE
                    RETURN '01';

                END IF;
            END IF;
        ELSE
            IF l_fac_count > 0
            THEN
                RETURN '04';
            ELSE
                RETURN '03';
            END IF;
        END IF;

-- JIRA LPV-1732 after 17-08-2018

EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END Get_RI_Type_Policy;

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
RETURN VARCHAR2
IS
    l_pr_flag       VARCHAR2(3);
    l_ri_type       VARCHAR2(2);
    l_count_ue      SIMPLE_INTEGER := 0;
BEGIN
    IF pi_ri_clause IS NOT NULL
    THEN
       IF pi_ri_clause IN ('QS', 'SP')
       THEN
          l_pr_flag := 'PR';
       ELSE
          l_pr_flag := 'NPR';
       END IF;

       IF l_pr_flag = 'PR'
       THEN
          IF pi_ri_fac_id IS NOT NULL
          THEN
             l_ri_type := '02';
          ELSE
             SELECT count(*)
             INTO l_count_ue
             FROM insis_gen_ri_v10.ri_treaty_attributes ta
             WHERE ta.treaty_id = TO_NUMBER(pi_treaty_id)
             AND ta.attribute_id = 'UEISFATRTY'
             AND ta.attribute_value = 'Y';

              IF l_count_ue > 0
              THEN
                 l_ri_type := '02';
              ELSE
                 l_ri_type := '01';
              END IF;
          END IF;
       ELSE
          IF pi_ri_fac_id IS NOT NULL
          THEN
             l_ri_type := '04';
          ELSE
             l_ri_type := '03';
          END IF;
       END IF;
    ELSE
       l_ri_type := Get_RI_Type_Policy( pi_policy_id );
    END IF;

    RETURN l_ri_type;

EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END Get_RI_Type_Policy_2;

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
RETURN NUMBER
IS
    l_claim_id     NUMBER;
    l_attrib_9     VARCHAR2(120 CHAR);
BEGIN

    SELECT DISTINCT bi.attrib_9
    INTO l_attrib_9
    FROM blc_installments bi
    WHERE bi.transaction_id = pi_transaction_id;

    SELECT claim_id
    INTO l_claim_id
    FROM claim_payments
    WHERE payment_id = to_number(l_attrib_9);

    RETURN l_claim_id;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Trx_Claim_Id;

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
RETURN VARCHAR2
IS
    l_claim_no     claim.claim_regid%type;
    l_claim_id     NUMBER;
BEGIN
    IF pi_transaction_type IN ('RI_CLAIM','CO_CLAIM','AC_CLAIM')
    THEN
       l_claim_id := Get_Trx_Claim_Id(pi_transaction_id);

       SELECT claim_regid
       INTO l_claim_no
       FROM claim
       WHERE claim_id = l_claim_id;
    ELSE
       l_claim_no := NULL;
    END If;

    RETURN l_claim_no;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Trx_Claim_No;

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
RETURN VARCHAR2
IS
    l_proforma_number    VARCHAR2(30);
BEGIN
    IF pi_transaction_type IN ('RI_COMMISSION','RI_EXPENSES','RI_PREMIUM','RI_TAX','CO_COMMISSION','CO_PREMIUM','CO_LFEES')
    THEN
       l_proforma_number := insis_blc_global_cust.cust_acc_util_pkg.Get_Proforma_Number(blc_appl_util_pkg.Get_Trx_External_Id(pi_transaction_id));
    ELSE
       l_proforma_number := NULL;
    END If;

    RETURN l_proforma_number;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Trx_Proforma_Number;

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
RETURN VARCHAR2
IS
    l_party       VARCHAR2(30);
    l_amnt_type        VARCHAR2(30);
    l_external_id      NUMBER;
    --
    CURSOR c_plan IS
      SELECT amnt_type, external_id
      FROM blc_policy_payment_plan
      WHERE policy_pplan_id = to_number(pi_external_id);
BEGIN
    OPEN c_plan;
      FETCH c_plan
      INTO l_amnt_type, l_external_id;
    CLOSE c_plan;

    IF l_amnt_type = 'DUE'
    THEN
       SELECT DISTINCT ba.party
       INTO l_party
       FROM blc_installments bi,
            blc_accounts ba,
            blc_items bii
       WHERE bi.external_id = pi_external_id
       AND bi.account_id = ba.account_id
       AND bi.item_id = bii.item_id
       AND bii.item_type = 'POLICY';
    ELSIF l_amnt_type = 'PAID'
    THEN
       SELECT baa.party
       INTO l_party
       FROM blc_applications ba,
            blc_transactions bt,
            blc_accounts baa
       WHERE ba.application_id = l_external_id
       AND ba.target_trx = bt.transaction_id
       AND bt.account_id = baa.account_id;
    END IF;

    RETURN l_party;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Inst_Party;

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
RETURN NUMBER
IS
  l_log_module      VARCHAR2(240);
  l_amount          NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_VS_Pmnt_Amount';

   SELECT nvl(sum(ba.target_amount),0)
   INTO l_amount
   FROM blc_applications ba,
        blc_transactions bt
   WHERE ba.source_payment = pi_payment_id
   AND ba.target_trx = bt.transaction_id
   AND bt.transaction_type = 'PAIDUPSRNDR';

   RETURN l_amount;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_VS_Pmnt_Amount;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_country         VARCHAR2(30);
  l_type            VARCHAR2(30);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_RI_Pol_Action_Type';

   IF pi_party IS NULL OR pi_currency IS NULL
   THEN
      l_type := 'AAA';
   ELSE
      SELECT home_country
      INTO l_country
      FROM p_people
      WHERE man_id = TO_NUMBER(pi_party);
      --
      IF l_country <> 'PE' AND pi_currency = 'USD'
      THEN
         l_type := 'CP1';
      ELSIF l_country = 'PE'
      THEN
         l_type := 'CPR';
      ELSE
         l_type := 'AAA';
      END IF;
   END IF;

   RETURN l_type;

EXCEPTION
   WHEN OTHERS THEN
     RETURN 'AAA';
END Get_RI_Pol_Action_Type;

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
RETURN VARCHAR2
IS
  l_log_module      VARCHAR2(240);
  l_priority        VARCHAR2(30);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Prof_Priority';

   IF pi_run_mode = 'I'
   THEN
      IF blc_common_pkg.Get_Lookup_Code(pi_bill_method_id) = 'PROTOCOL'
      THEN
         l_priority := 'MASS';
      ELSE
         l_priority := 'HIGH';
      END IF;
   ELSIF pi_run_mode = 'E'
   THEN
      l_priority := 'HIGH';
   ELSE
      l_priority := 'MASS';
   END IF;

   RETURN l_priority;

EXCEPTION
   WHEN OTHERS THEN
     RETURN 'MASS';
END Get_Prof_Priority;

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
RETURN VARCHAR2
IS
  l_account_type VARCHAR2(100);
  --
  CURSOR c_get_bank_blc_claim IS
    SELECT cba.account_purpose
    FROM claim_payments cp, claim_bank_accounts cba, p_bank_account pba
    WHERE cp.claim_id = TO_NUMBER(pi_claim)
    AND cp.payment_id = TO_NUMBER(pi_claim_payment)
    AND cp.claim_id = cba.claim_id
    AND cp.request_id = cba.request_id
    AND cp.doclad_id = NVL(cba.doclad_id, cp.doclad_id)
    AND pba.bank_acc_id = cba.bank_account_id
    AND pba.man_id = cp.man_id
    AND cp.payment_way = '3' -- payment_way = 3 - Bank transfer
    AND pba.account_num = pi_bank_account_code;

BEGIN
   IF pi_bank_account_code IS NOT NULL
   THEN
      OPEN C_get_bank_blc_claim;
        FETCH C_get_bank_blc_claim
        INTO l_account_type;
      CLOSE C_get_bank_blc_claim;
   ELSE
      l_account_type := NULL;
   END IF;
   --
   RETURN l_account_type;
EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END Get_Claim_Bank_Account_Type;

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
RETURN VARCHAR2
IS
    l_NC_type    VARCHAR2(2);
BEGIN
    IF pi_man_id IS NULL
    THEN
        l_NC_type := '01';
    ELSE
        SELECT CASE WHEN customer_type IN ( '1', '3', '4', '7' ) THEN '01'
                    WHEN customer_type IN ( '2' ) THEN '02'
                    WHEN customer_type IN ( '5', '6' ) THEN '08'
                    ELSE '01' END
            INTO l_NC_type
        FROM p_clients
        WHERE man_id = TO_NUMBER( pi_man_id );
    END IF;
    --
    RETURN l_NC_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN '01';
END Get_NC_Client;

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
RETURN VARCHAR2
IS
    l_NC_type    VARCHAR2(2);
BEGIN
    IF pi_man_id IS NULL
    THEN
        l_NC_type := '01';
    ELSE
        SELECT DECODE( home_country, 'PE', '01', NULL, '01', '02' ) INTO l_NC_type
        FROM p_people
        WHERE man_id = TO_NUMBER( pi_man_id );
    END IF;
    --
    RETURN l_NC_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN '01';
END Get_NC_Reinsurer;

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
RETURN VARCHAR2
IS
    l_type    VARCHAR2(2);
BEGIN
    IF pi_man_id IS NULL
    THEN
        l_type := '00';
    ELSE
        SELECT CASE WHEN pc.customer_type IN ( '1', '2', '3', '4', '7' ) THEN '00'
                    WHEN pc.customer_type IN ( '5', '6' ) AND pp.nationality = 'PE' THEN '01'
                    WHEN pc.customer_type IN ( '5', '6' ) AND pp.nationality <> 'PE' THEN '02'
                    ELSE '00' END
            INTO l_type
        FROM p_clients pc, p_people pp
        WHERE pc.man_id = TO_NUMBER( pi_man_id )
            AND pc.man_id = pp.man_id;
    END IF;
    --
    RETURN l_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN '00';
END Get_GR_Code;

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
--     Fadata   23.03.2020  creation  LAP85-23  CSR 170
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
RETURN VARCHAR2
IS
    l_client_type   VARCHAR2(15);
    l_type          VARCHAR2(2);
BEGIN
    IF pi_man_id IS NULL
    THEN
        l_type := '01';
    ELSE
        SELECT customer_type INTO l_client_type
        FROM p_clients
        WHERE man_id = TO_NUMBER( pi_man_id );
    END IF;
    --
    IF l_client_type IN ( '1', '2', '3', '4', '7' )
    THEN
        l_type := '00';
    ELSIF l_client_type IN ( '5', '6' )
    THEN
        IF policy_class IN ( 'D', 'DC', 'DR', 'DCR' )
        THEN
            l_type := '01';
        ELSE
            l_type := '02';
        END IF;
    ELSE
        l_type := '01';
    END IF;
    --
    RETURN l_type;
    --
EXCEPTION WHEN OTHERS THEN RETURN '01';
END Get_PC_Code;

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
RETURN VARCHAR2
IS
    l_doc_type         VARCHAR2(30);
    l_amnt_type        VARCHAR2(30);
    l_external_id      NUMBER;
    --
    CURSOR c_plan IS
      SELECT amnt_type, external_id
      FROM blc_policy_payment_plan
      WHERE policy_pplan_id = to_number(pi_external_id);
BEGIN
    OPEN c_plan;
      FETCH c_plan
      INTO l_amnt_type, l_external_id;
    CLOSE c_plan;

    IF l_amnt_type = 'DUE'
    THEN
       SELECT DISTINCT bl.lookup_code
       INTO l_doc_type
       FROM blc_installments bi,
            blc_items bii,
            blc_transactions bt,
            blc_documents bd,
            blc_lookups bl
       WHERE bi.external_id = pi_external_id
       AND bi.item_id = bii.item_id
       AND bii.item_type = 'POLICY'
       AND bi.transaction_id = bt.transaction_id
       AND bt.doc_id = bd.doc_id
       AND bd.doc_type_id = bl.lookup_id;
    ELSIF l_amnt_type = 'PAID'
    THEN
       SELECT bl.lookup_code
       INTO l_doc_type
       FROM blc_applications ba,
            blc_transactions bt,
            blc_documents bd,
            blc_lookups bl
       WHERE ba.application_id = l_external_id
       AND ba.target_trx = bt.transaction_id
       AND bt.doc_id = bd.doc_id
       AND bd.doc_type_id = bl.lookup_id;
    END IF;

    RETURN l_doc_type;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Proforma_Type;

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
RETURN NUMBER
IS
  l_log_module    VARCHAR2(240);
  l_annex_id      NUMBER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_PiadUp_Annex';

   SELECT MAX(gar.annex_id)
   INTO l_annex_id
   FROM gen_annex_reason gar
   WHERE gar.policy_id = pi_policy_id
   AND gar.annex_reason = 'PAIDUP';

   RETURN l_annex_id;

EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_PiadUp_Annex;

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
-- Purpose: Get insured value
--
-- Input parameters:
--     pi_policy          NUMBER       Policy ID;
--
-- Returns: insured value
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
RETURN NUMBER
IS
    l_insured_value          NUMBER;
    --
    CURSOR c_ins IS
    SELECT iob.insured_value
    FROM insured_object iob
    WHERE iob.policy_id = pi_policy_id
    ORDER BY iob.annex_id DESC;
BEGIN
    OPEN c_ins;
      FETCH c_ins
      INTO l_insured_value;
    CLOSE c_ins;
    --
    RETURN l_insured_value;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Insured_value;

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
RETURN VARCHAR2
IS
    l_int_rate          VARCHAR2(100);
    --
    CURSOR c_rate IS
      SELECT iap.attr1
      FROM inv_account_pwithdraw iap
      WHERE iap.policy_id = pi_policy_id
      AND iap.annex_id = pi_annex_id
      ORDER BY iap.withdraw_id DESC;
BEGIN
    OPEN c_rate;
      FETCH c_rate
      INTO l_int_rate;
    CLOSE c_rate;
    --
    RETURN l_int_rate;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Loan_Int_Rate;

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
RETURN VARCHAR2
IS
    l_periods          VARCHAR2(100);
    --
    CURSOR c_periods IS
      SELECT iap.attr2
      FROM inv_account_pwithdraw iap
      WHERE iap.policy_id = pi_policy_id
      AND iap.annex_id = pi_annex_id
      ORDER BY iap.withdraw_id DESC;
BEGIN
    OPEN c_periods;
      FETCH c_periods
      INTO l_periods;
    CLOSE c_periods;
    --
    RETURN l_periods;
    --
EXCEPTION
   WHEN OTHERS THEN
     RETURN NULL;
END Get_Loan_Periods;

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
RETURN VARCHAR2
IS
  l_count SIMPLE_INTEGER := 0;
  l_spec  VARCHAR2(1);
BEGIN
   SELECT SUM(NVL2(bl.lookup_code,1,0))
   INTO l_count
   FROM claim_payments_details cpd,
        blc_lookups bl
   WHERE cpd.claim_id = TO_NUMBER(pi_claim)
   AND cpd.payment_id = TO_NUMBER(pi_claim_payment)
   AND cpd.cover_type = bl.attrib_1 (+)
   AND cpd.risk_type = bl.attrib_2 (+)
   AND NVL(bl.lookup_set,'LPV_CLAIM_COVER_RISK') = 'LPV_CLAIM_COVER_RISK';

   IF l_count = 0
   THEN
      l_spec := 'N';
   ELSE
      l_spec := 'Y';
   END IF;
   --
   RETURN l_spec;
EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
END Is_Spec_Claim_Cover_Risk;

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
RETURN VARCHAR2
IS
  l_priority        VARCHAR2(30);
BEGIN
   IF pi_run_mode = 'I'
   THEN
      IF blc_common_pkg.Get_Lookup_Code(pi_bill_method_id) = 'PROTOCOL'
      THEN
         IF pi_policy_type = 'CLIENT_GROUP'
         THEN
            l_priority := 'HIGH';
         ELSE
            l_priority := 'MASS';
         END IF;
      ELSE
         l_priority := 'HIGH';
      END IF;
   ELSIF pi_run_mode = 'E'
       OR pi_run_mode IS NULL -- LAP85-132
   THEN
      l_priority := 'HIGH';
   ELSE
      l_priority := 'MASS';
   END IF;

   RETURN l_priority;

EXCEPTION
   WHEN OTHERS THEN
     RETURN 'MASS';
END Get_Prof_Priority_2;
--
END CUST_ACC_UTIL_PKG;
/