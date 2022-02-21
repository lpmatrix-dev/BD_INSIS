CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.cust_gl_intrf
IS
-- Returns attrib_0 value of the lookup by passed lookup code and set
--FUNCTION Get_attr_0_by_lookup_code_set (pi_lookup_code IN VARCHAR2,
  --  pi_lookup_set IN VARCHAR2) RETURN VARCHAR2;

-- Returns intermediary type accounting analytics by passed lookup code and policy ID
FUNCTION Get_intrmd_typ_by_lkup_cod_pol (pi_policy_id IN VARCHAR2) RETURN VARCHAR2;

-- Returns NC nomenclature value by passed party
-- local-01, foreign-02 (home_country field in p_people), company is related to LPV - 08
-- If home_contry is NULL, considers it to be 'PE'
FUNCTION Get_NC (pi_party IN VARCHAR2) RETURN VARCHAR2;

-- Returns policy attribute by policy ID
FUNCTION Get_policy_attr_by_ID (pi_policy_id IN VARCHAR2,
pi_attr_number IN NUMBER) RETURN VARCHAR2;

-- Returns the company code: 1 for LPG (GEN), 2 for LPV (LIFE)
-- extracted from acc_code field of blc_orgs by passed org_id
FUNCTION Get_company( pi_org IN NUMBER ) RETURN VARCHAR2;

-- Returns office code by passed policy ID
FUNCTION Get_office_code (pi_policy_id IN VARCHAR2) RETURN VARCHAR2;

-- Returns insurance type by passed policy ID
FUNCTION Get_insr_type (pi_policy_id IN VARCHAR2) RETURN VARCHAR2;

-- Returns the Profit Center by passed organization and policy ID
FUNCTION Get_profit_center( pi_org IN NUMBER,pi_policy_id IN VARCHAR2 ) RETURN VARCHAR2;

-- Returns DD nomenclature code for the coinsurer by passed party ID
FUNCTION Get_DD( pi_party IN VARCHAR2 ) RETURN VARCHAR2;

-- Returns the document number by transaction_id
FUNCTION Get_doc_no_trx_id( pi_trx_id IN NUMBER ) RETURN VARCHAR2;


END; -- Package spec
/


