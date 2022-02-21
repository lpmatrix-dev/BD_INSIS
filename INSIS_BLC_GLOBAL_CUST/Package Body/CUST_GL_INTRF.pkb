CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.cust_gl_intrf
IS
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
/* Replace with blc_common_pkg.Get_Lookup_Attrib_Value

-- Returns attrib_0 value of the lookup by passed lookup code and set

FUNCTION Get_attr_0_by_lookup_code_set (pi_lookup_code IN VARCHAR2,
    pi_lookup_set IN VARCHAR2) RETURN VARCHAR2
  IS

      l_attrib_0 VARCHAR2(25 CHAR);

  BEGIN


    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(l_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(blc_appl_cache_pkg.g_to_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'begin');

    SELECT attrib_0 INTO l_attrib_0
        FROM insis_gen_blc_v10.blc_lookups
        WHERE lookup_set = pi_lookup_set
            AND lookup_code = pi_lookup_code;


    RETURN (l_attrib_0);
        --DBMS_OUTPUT.PUT_LINE( 'end');

    EXCEPTION
        WHEN OTHERS THEN RETURN(NULL);


  END Get_attr_0_by_lookup_code_set;
*/

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns intermediary type accounting analytics by passed lookup code and policy ID
FUNCTION Get_intrmd_typ_by_lkup_cod_pol (pi_policy_id IN VARCHAR2) RETURN VARCHAR2
IS
      l_attrib_0 VARCHAR2(25 CHAR);
      l_intermediary_type VARCHAR2(25 CHAR);
      l_policy VARCHAR2(30 BYTE);
      l_pol_attr3 VARCHAR2(50);
BEGIN
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(l_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(blc_appl_cache_pkg.g_to_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'begin');
    IF pi_policy_id IS NULL
    THEN RETURN NULL;
    END IF;

    SELECT attr3 INTO l_pol_attr3 -- sales channel
        FROM insis_gen_v10.policy
        WHERE policy_id = to_number(pi_policy_id);

    SELECT 'D' INTO l_intermediary_type
        FROM insis_gen_blc_v10.blc_lookups
        WHERE lookup_set = 'CUST_LPV_INTERMD_TYP_SALE_CHAN'
            AND lookup_code = l_pol_attr3; -- sales channel


    RETURN (l_intermediary_type);
        --DBMS_OUTPUT.PUT_LINE( 'end');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN('I');
        WHEN OTHERS THEN RETURN(NULL);


  END Get_intrmd_typ_by_lkup_cod_pol;

--------------------------------------------------------------------------------
-- Returns NC nomenclature value by passed party
-- local-01, foreign-02 (home_country field in p_people), company is related to LPV - 08
-- If home_contry is NULL, considers it to be 'PE'

/*FUNCTION Get_NC (pi_party IN VARCHAR2) RETURN VARCHAR2
  IS

      l_home_country insis_people_v10.p_people.home_country%TYPE;
      l_man_comp insis_people_v10.p_people.man_comp%TYPE;
      l_NC VARCHAR2(10 CHAR);
      l_flag NUMBER;       -- flag for time when exception was raised

  BEGIN

    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(l_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(blc_appl_cache_pkg.g_to_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'begin');

    l_flag := 1;

    SELECT '02' INTO l_NC
        FROM insis_people_v10.p_people
        WHERE man_id = pi_party
            AND home_country <> 'PE'
            AND home_country IS NOT NULL;

    l_flag := 2;

    SELECT '08' INTO l_NC
        FROM DUAL
        WHERE EXISTS (SELECT 'X' FROM insis_people_v10.p_people_relation
        WHERE part1_id = pi_party
            AND rel_id IS NOT NULL);


    RETURN (l_NC);
        --DBMS_OUTPUT.PUT_LINE( 'end');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            BEGIN
                IF l_flag = 1
                    THEN
                      BEGIN
                        l_flag := 2;
                        SELECT '08' INTO l_NC
                            FROM DUAL
                            WHERE EXISTS (SELECT 'X' FROM insis_people_v10.p_people_relation
                            WHERE part1_id = pi_party
                                AND rel_id IS NOT NULL);
                        RETURN(l_NC);
                      END;
                    ELSE RETURN ('01');
                 END IF;
            END;
        WHEN OTHERS THEN RETURN(NULL);


  END Get_NC; */
FUNCTION Get_NC( pi_party IN VARCHAR2 ) RETURN VARCHAR2
IS
    l_count  PLS_INTEGER;
    l_code   VARCHAR2(2) ;
BEGIN
    IF pi_party IS NULL
    THEN RETURN NULL;
    END IF;
    --
    SELECT COUNT(*) INTO l_count
    FROM insis_people_v10.p_people_relation
    WHERE part1_id = pi_party;
    --
    IF l_count > 0
    THEN
        RETURN '08';
    ELSE
        SELECT DECODE( home_country, NULL, '01', 'PE', '01', '02' )
            INTO l_code
        FROM insis_people_v10.p_people
        WHERE man_id = pi_party;
        --
        RETURN l_code;
    END IF;
    --
EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END Get_NC;

--------------------------------------------------------------------------------
-- Returns policy attribute by policy ID

FUNCTION Get_policy_attr_by_ID (pi_policy_id IN VARCHAR2,
pi_attr_number IN NUMBER) RETURN VARCHAR2
  IS

      l_attr insis_gen_v10.policy.attr1%TYPE;


  BEGIN

    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(l_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(blc_appl_cache_pkg.g_to_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'begin');

        SELECT DECODE ( pi_attr_number,
                                   1, attr1,
                                   2, attr2,
                                   3, attr3,
                                   4, attr4,
                                   5, attr5,
                                   6, attr6,
                                   7, attr7,
                                   8, attr8
                                   )
       INTO l_attr
       FROM insis_gen_v10.policy
       WHERE policy_id = pi_policy_id;


    RETURN (l_attr);
        --DBMS_OUTPUT.PUT_LINE( 'end');

    EXCEPTION
        --WHEN NO_DATA_FOUND THEN RETURN('I');
        WHEN OTHERS THEN RETURN(NULL);


  END Get_policy_attr_by_ID;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns the company code: 1 for LPG (GEN), 2 for LPV (LIFE)
-- extracted from acc_code field of blc_orgs by passed org_id

FUNCTION Get_company( pi_org IN NUMBER ) RETURN VARCHAR2
IS
    l_company  insis_gen_blc_v10.blc_orgs.acc_code%TYPE;

BEGIN
    IF pi_org IS NULL
    THEN RETURN NULL;
    END IF;
    --
    SELECT acc_code INTO l_company
    FROM insis_gen_blc_v10.blc_orgs
    WHERE org_id=pi_org;

    RETURN (l_company);
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_company;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns office code by passed policy ID

FUNCTION Get_office_code (pi_policy_id IN VARCHAR2) RETURN VARCHAR2
IS
      l_attrib_0 VARCHAR2(25 CHAR);
      l_gl_no insis_people_v10.p_offices.gl_no%TYPE;
      l_policy VARCHAR2(30 BYTE);
      l_pol_attr4 VARCHAR2(50);
BEGIN
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(l_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(blc_appl_cache_pkg.g_to_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'begin');
    IF pi_policy_id IS NULL
    THEN RETURN NULL;
    END IF;

    SELECT attr4 INTO l_pol_attr4 -- office
        FROM insis_gen_v10.policy
        WHERE policy_id = to_number(pi_policy_id);

    IF l_pol_attr4 IS NULL
    THEN RETURN '02'; -- code of office San Isidro
    END IF;

    SELECT gl_no INTO l_gl_no
        FROM insis_people_v10.p_offices
        WHERE office_id = l_pol_attr4;


    RETURN (l_gl_no);
        --DBMS_OUTPUT.PUT_LINE( 'end');

    EXCEPTION
        --WHEN NO_DATA_FOUND THEN RETURN('I');
        WHEN OTHERS THEN RETURN(NULL);


  END Get_office_code;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns insurance type by passed policy ID

FUNCTION Get_insr_type (pi_policy_id IN VARCHAR2) RETURN VARCHAR2
IS
      l_insr_type insis_gen_v10.policy.insr_type%TYPE;

BEGIN
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(l_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'now'||to_char(blc_appl_cache_pkg.g_to_date,'yyyy'));
    --DBMS_OUTPUT.PUT_LINE( 'begin');
    IF pi_policy_id IS NULL
    THEN RETURN NULL;
    END IF;

    SELECT insr_type INTO l_insr_type
        FROM insis_gen_v10.policy
        WHERE policy_id = to_number(pi_policy_id);


    RETURN (l_insr_type);
        --DBMS_OUTPUT.PUT_LINE( 'end');

    EXCEPTION
        --WHEN NO_DATA_FOUND THEN RETURN('I');
        WHEN OTHERS THEN RETURN(NULL);


  END Get_insr_type;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns the Profit Center by passed organization and policy ID
--Organization Structure:	Number of Digits /	Values
--Country	1  /	Perú
--Company	1  /	LPV
--Business Unit	2	/  Registered on policy level
--Department	2  /	Included in List Values Sheet
--Office	2  /	Registered on policy level
--Segment	1 /	0
--Total of Digits (Profit Center)	9


FUNCTION Get_profit_center( pi_org IN NUMBER,pi_policy_id IN VARCHAR2 ) RETURN VARCHAR2
IS
    l_company  insis_gen_blc_v10.blc_orgs.acc_code%TYPE;
    l_profit_center  insis_gen_blc_v10.blc_gl_insis2gl.attrib_1%TYPE;
    l_office insis_people_v10.p_offices.gl_no%TYPE;
    l_department insis_people_v10.p_offices.gl_no%TYPE;
    l_business_unit VARCHAR2(50);

BEGIN
    IF pi_org IS NULL
    THEN RETURN NULL;
    END IF;
    --
    SELECT acc_code INTO l_company
    FROM insis_gen_blc_v10.blc_orgs
    WHERE org_id=pi_org;

     l_office := Get_office_code (pi_policy_id);
     IF l_office IS NULL
        THEN RETURN NULL;
        END IF;

     l_department := blc_common_pkg.Get_Lookup_Attrib_Value('CUST_LPV_OFFICE_VS_DEPARTMENT',l_office,0,null,0);
     IF l_department IS NULL
        THEN RETURN NULL;
        END IF;

     l_business_unit := insis_gen_blc_v10.blc_common_pkg.Get_Lookup_Attrib_Value('CUST_LPV_BUS_UNIT_VS_SALE_CHAN',insis_blc_global_cust.cust_gl_intrf.Get_policy_attr_by_ID(pi_policy_id,3),0,null,0);
     IF l_business_unit IS NULL
        THEN RETURN NULL;
        END IF;

     l_profit_center := '1' -- for country Peru = 1 - for now constant
        || l_company || l_business_unit || l_department || l_office
        || '0' ; -- segment for now = constant 0

    RETURN (l_profit_center);
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_profit_center;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns DD nomenclature code for the coinsurer by passed party ID

FUNCTION Get_DD( pi_party IN VARCHAR2 ) RETURN VARCHAR2
IS
    l_DD  insis_people_v10.p_insurers.reg_num%TYPE;

BEGIN
    IF pi_party IS NULL
    THEN RETURN NULL;
    END IF;
    --
    SELECT reg_num INTO l_DD
    FROM insis_people_v10.p_insurers
    WHERE man_id = pi_party;

    RETURN l_DD;

    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_DD;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Returns the document number by transaction_id

FUNCTION Get_doc_no_trx_id( pi_trx_id IN NUMBER ) RETURN VARCHAR2
IS
    l_doc_no  insis_gen_blc_v10.blc_documents.doc_number%TYPE;

BEGIN
    SELECT doc_number INTO l_doc_no
    FROM insis_gen_blc_v10.blc_documents
    WHERE doc_id IN
        (SELECT doc_id FROM insis_gen_blc_v10.blc_transactions
            WHERE transaction_id=pi_trx_id);

    RETURN (l_doc_no);
    --
EXCEPTION WHEN OTHERS THEN RETURN NULL;
END Get_doc_no_trx_id;

END;
/


