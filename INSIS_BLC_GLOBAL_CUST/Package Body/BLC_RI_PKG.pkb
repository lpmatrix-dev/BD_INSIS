create or replace PACKAGE BODY                       BLC_RI_PKG AS
    
    --------------------------------------------------------------------------------
    -- Name: PEOPLE_SAP_CODE
    --
    -- Type: FUNCTION
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   17.11.2017  creation
    --
    -- Purpose:  Obtain the SAP_CODE with the MAN_ID
    --
    -- Input parameters:
    --     MAN_ID              NUMBER       MAN_ID(people code)
    --
    -- Output parameters:
    --     SAP_CODE            VARCHAR2     People code for SAP
    --
    --
    -- Usage: For Integration with SAP
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    /*
    FUNCTION PEOPLE_SAP_CODE (
        MAN_ID NUMBER
    ) RETURN VARCHAR IS
        SAP_CODE VARCHAR(10);
        S_LEGACY_ID INSIS_CUST.INTRF_LPV_PEOPLE_IDS.LEGACY_ID%TYPE;
        S_SAP_CODE_PERSON INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_CODE_PERSON%TYPE;
        S_SAP_CODE_LEGAL INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_CODE_LEGAL%TYPE;
        S_INSUNIX_CODE INSIS_CUST.INTRF_LPV_PEOPLE_IDS.INSUNIX_CODE%TYPE;
    BEGIN
        --dbms_output.put_line('MAN_ID'||MAN_ID);
        insis_cust_lpv.INSPKGCLI.GET_PEOPLE_CODES(
            MAN_ID,
            NULL,
            NULL,
            S_LEGACY_ID,
            S_SAP_CODE_PERSON,
            S_SAP_CODE_LEGAL,
            S_INSUNIX_CODE
        );
        IF
            S_SAP_CODE_PERSON IS NOT NULL
        THEN
            SAP_CODE := S_SAP_CODE_PERSON;
        ELSE
            SAP_CODE := S_SAP_CODE_LEGAL;
        END IF;
        RETURN SAP_CODE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR IN GET SAP CODE');
            RETURN NULL;
    END PEOPLE_SAP_CODE;--
    */
    FUNCTION PEOPLE_SAP_CODE (
        MAN_ID NUMBER
    ) RETURN VARCHAR IS
        l_SAP_CODE VARCHAR2(10);
        l_MAN_COMP INSIS_PEOPLE_V10.P_PEOPLE.MAN_COMP%TYPE;
        r_LPV_PEOPLE INSIS_CUST.INTRF_LPV_PEOPLE_IDS%ROWTYPE;
    BEGIN
        IF
            MAN_ID IS NULL
        THEN
            /*
            RAISE_APPLICATION_ERROR(
                -20000,
                'Provided MAN_ID is null!'
            );
            */
            RAISE_APPLICATION_ERROR(-20000,'ERROR PEOPLE_SAP_CODE. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
        ELSE
            BEGIN
                SELECT
                    MAN_COMP
                INTO
                    l_MAN_COMP
                FROM
                    INSIS_PEOPLE_V10.P_PEOPLE
                WHERE
                    MAN_ID = PEOPLE_SAP_CODE.MAN_ID;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20000,
                        'No MAN_COMP found in P_PEOPLE for MAN_ID=' || PEOPLE_SAP_CODE.MAN_ID
                    );
            END;
            --
            BEGIN
                SELECT
                    *
                INTO
                    r_LPV_PEOPLE
                FROM
                    INSIS_CUST.INTRF_LPV_PEOPLE_IDS
                WHERE
                    MAN_ID = PEOPLE_SAP_CODE.MAN_ID;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(
                        -20000,
                        'No record found in INTRF_LPV_PEOPLE_IDS for MAN_ID=' || PEOPLE_SAP_CODE.MAN_ID
                    );
            END;
            --
            CASE
                WHEN l_MAN_COMP = 1 THEN
                    l_SAP_CODE := r_LPV_PEOPLE.SAP_CODE_PERSON;
                WHEN l_MAN_COMP = 2 THEN
                    l_SAP_CODE := r_LPV_PEOPLE.SAP_CODE_LEGAL;
                ELSE
                    RAISE_APPLICATION_ERROR(
                        -20000,
                        'No INTRF_LPV_PEOPLE_IDS column mapping defined for MAN_COMP=' || l_MAN_COMP
                    );
            END CASE;
        END IF;
        --
        IF
            l_SAP_CODE IS NULL
        THEN
            RAISE_APPLICATION_ERROR(
                -20000,
                'No SAP_CODE found in INTRF_LPV_PEOPLE_IDS using MAN_ID=' || PEOPLE_SAP_CODE.MAN_ID
            );
        END IF;
        RETURN l_SAP_CODE;
    END PEOPLE_SAP_CODE;
    
    /**
    * Get SAP Office.
    * @param OFFICE_NO [IN] INSIS Office Number.
    */
    FUNCTION get_nOffice (
        OFFICE_NO IN INSIS_PEOPLE_V10.P_OFFICES.OFFICE_NO%TYPE
    ) RETURN NUMBER AS
        nOffice NUMBER(5);
    BEGIN
        nOffice :=
            CASE OFFICE_NO
                WHEN 1 THEN 1
                WHEN 2 THEN 2
                WHEN 3 THEN 3
                WHEN 4 THEN 4
                WHEN 5 THEN 5
                WHEN 6 THEN 6
                WHEN 7 THEN 2
                WHEN 8 THEN 35
                WHEN 9 THEN 9
                WHEN 10 THEN 2
                WHEN 11 THEN 2
                WHEN 12 THEN 12
                WHEN 13 THEN 13
                WHEN 14 THEN 14
                WHEN 15 THEN 15
                WHEN 16 THEN 2
                WHEN 17 THEN 2
                WHEN 18 THEN 18
                WHEN 19 THEN 19
                WHEN 20 THEN 2
                WHEN 21 THEN 21
                WHEN 22 THEN 2
                WHEN 23 THEN 2
                WHEN 24 THEN 24
                WHEN 25 THEN 2
                WHEN 26 THEN 26
                WHEN 29 THEN 35
                WHEN 30 THEN 2
                WHEN 31 THEN 2
                WHEN 32 THEN 32
                WHEN 33 THEN 33
                WHEN 34 THEN 34
                WHEN 35 THEN 35
                WHEN 36 THEN 36
                WHEN 37 THEN 37
                WHEN 38 THEN 49
                WHEN 39 THEN 39
                WHEN 40 THEN 40
                WHEN 41 THEN 1
                WHEN 42 THEN 6
                WHEN 43 THEN 43
                WHEN 44 THEN 12
                WHEN 45 THEN 4
                WHEN 46 THEN 3
                WHEN 47 THEN 35
                WHEN 48 THEN 48
                WHEN 49 THEN 49
                WHEN 50 THEN 48
                WHEN 51 THEN 15
                WHEN 52 THEN 13
                WHEN 53 THEN 33
                WHEN 54 THEN 48
                WHEN 55 THEN 55
                WHEN 56 THEN 56
                WHEN 57 THEN 57
                WHEN 58 THEN 58
                WHEN 59 THEN 59
                WHEN 60 THEN 60
                WHEN 61 THEN 1
                WHEN 62 THEN 62
                WHEN 63 THEN 3
                WHEN 64 THEN 4
                WHEN 65 THEN 5
                WHEN 66 THEN 6
                WHEN 67 THEN 76
                WHEN 68 THEN 68
                WHEN 69 THEN 43
                WHEN 70 THEN 26
                WHEN 71 THEN 24
                WHEN 72 THEN 12
                WHEN 73 THEN 13
                WHEN 74 THEN 15
                WHEN 75 THEN 18
                WHEN 76 THEN 76
                WHEN 77 THEN 77
                WHEN 78 THEN 78
                WHEN 79 THEN 1
                WHEN 80 THEN 80
                WHEN 81 THEN 81
                WHEN 82 THEN 82
                WHEN 83 THEN 83
                WHEN 84 THEN 84
                WHEN 92 THEN 33
                WHEN 93 THEN 77
                WHEN 99 THEN 2
                WHEN 100 THEN 2
                ELSE OFFICE_NO
            END;
        IF
            nOffice IS NULL
        THEN
        DBMS_OUTPUT.put_line('OFFICE_NO: '||OFFICE_NO);
        /*
            raise_application_error(
                -20000,
                'No mapping found for office number: ' || OFFICE_NO
            );
     */
        END IF;
        RETURN nOffice;
    END get_nOffice;
    
    /**
    * Get Office Name.
    * @param OFFICE_NO [IN] Office Number.
    */
    FUNCTION get_OFFICE_NAME (
        OFFICE_NO IN BLC_REI_ACC.TECH_BRANCH%TYPE
    ) RETURN VARCHAR2 AS
        OFFICE_NAME VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT
                NAME
            INTO
                OFFICE_NAME
            FROM
                INSIS_PEOPLE_v10.p_people
                NATURAL JOIN INSIS_PEOPLE_v10.p_offices
            WHERE
                office_no = OFFICE_NO AND
                ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                OFFICE_NAME := NULL;
        END;
        --DBMS_OUTPUT.put_line('OFFICE_NAME:'||OFFICE_NAME);
        RETURN OFFICE_NAME;
    END get_OFFICE_NAME;
    
    /**
    * Get Home Country.
    * @param MAN_ID [IN] People Identifier.
    */
    FUNCTION get_HOME_COUNTRY (
        MAN_ID IN INSIS_PEOPLE_V10.P_PEOPLE.MAN_ID%TYPE
    ) RETURN VARCHAR2 AS
        HOME_COUNTRY INSIS_PEOPLE_V10.P_PEOPLE.HOME_COUNTRY%TYPE;
    BEGIN
        BEGIN
            SELECT
                P.home_country
            INTO
                HOME_COUNTRY
            FROM
                INSIS_PEOPLE_V10.P_PEOPLE P
            WHERE
                P.man_id = MAN_ID AND
                ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                HOME_COUNTRY := NULL;
        END;
        --DBMS_OUTPUT.put_line('HOME_COUNTRY:'||HOME_COUNTRY);
        RETURN HOME_COUNTRY;
    END get_HOME_COUNTRY;
    
    /**
     * Provides the Business Unit Code using the given parameters.
     * @param PRODUCT [IN] Product Code.
     * @param SALES_CHANNEL [IN] Sales Channel Code.
     * @return BUSINESS_UNIT The Business Unit 2-Digit Code.
     */
    FUNCTION get_BUSINESS_UNIT (
        PRODUCT IN NUMBER,
        SALES_CHANNEL IN VARCHAR2
    ) RETURN CHAR IS
        BUSINESS_UNIT CHAR(2);
    BEGIN
        BUSINESS_UNIT :=
            CASE
                WHEN PRODUCT IN (
                    2000,
                    2001,
                    2002,
                    2003,
                    2004,
                    2005,
                    2006,
                    2007,
                    2008,
                    --Defect 537 add products for get bussiness unit
                    2009,
                    2011,
                    2012,
                    2013,
                    2014,
                    2015 
                ) THEN
                    CASE SALES_CHANNEL
                        WHEN '1' THEN '02'
                        WHEN '2' THEN '24'
                        WHEN '3' THEN '02'
                        WHEN '4' THEN '02'
                        WHEN '5' THEN '03'
                        WHEN '6' THEN '04'
                        WHEN '7' THEN '25'
                        WHEN '8' THEN '02'
                        WHEN '9' THEN '02'
                        WHEN '11' THEN '02'
                        WHEN '13' THEN '21'
                        WHEN '15' THEN '02'
                        --Defect 537 add sales_channel for get bussiness unit
                        WHEN '16' THEN '22'
                        WHEN '17' THEN '24'
                        WHEN '18' THEN '24'
                        WHEN '19' THEN '02'
                        WHEN '20' THEN '02'
                        WHEN '21' THEN '02'
                        WHEN '22' THEN '02'
                        ELSE NULL
                    END
                ELSE NULL
            END;
        RETURN(BUSINESS_UNIT);
    END get_BUSINESS_UNIT;
    
    --
    PROCEDURE BLC_COPA_INSERT (
        pi_sequence IN NUMBER,
        pi_item IN VARCHAR2,
        pi_branch IN VARCHAR2,
        pi_office IN VARCHAR2,
        pi_sales_channel IN VARCHAR2,
        pi_bussityp IN VARCHAR2,
        pi_product IN VARCHAR2,
        pi_intermedtyp IN VARCHAR2,
        pi_bussiunit IN VARCHAR2
    ) IS
        l_id_insis INSIS_CUST_LPV.HT_COPA_VALUES.ID_INSIS%TYPE;
        l_copa_type INSIS_CUST_LPV.IIBTBLREI_POL.SFIELD%TYPE;
        l_copa_value INSIS_CUST_LPV.IIBTBLREI_POL.SVALUE%TYPE;
    BEGIN
        FOR l_copa_item IN (
            SELECT
                *
            FROM
                INSIS_CUST_LPV.HT_COPA
            WHERE
                STATUS = 'A'
        ) LOOP
            --
            l_copa_type := l_copa_item.COPA_TYPE;
            l_id_insis :=
                CASE l_copa_type
                    WHEN 'WWRCN' THEN pi_branch
                    WHEN 'WWRCM' THEN pi_branch
                    WHEN 'WWTNE' THEN pi_bussityp
                    WHEN 'WWPRO' THEN pi_product
                    WHEN 'WWNES' THEN '0'
                    WHEN 'GSBER' THEN pi_office
                    WHEN 'WWCVE' THEN pi_sales_channel
                    WHEN 'WWUNE' THEN pi_bussiunit
                    WHEN 'WWTIN' THEN pi_intermedtyp
                END;
            --
            IF
                l_id_insis IS NOT NULL
            THEN
                BEGIN                    
                    --
                    BEGIN
                        SELECT
                            ID_SAP
                        INTO
                            l_copa_value
                        FROM
                            INSIS_CUST_LPV.HT_COPA_VALUES
                        WHERE
                            COPA_TYPE = l_copa_type AND
                            ID_INSIS = l_id_insis;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            l_copa_value := l_id_insis;
                    END;
                    --
                    INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI003(
                        pi_sequence,
                        pi_item,
                        l_copa_type,
                        l_copa_value,
                        SYSDATE
                    );
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        /*
                        RAISE_APPLICATION_ERROR(
                            -20401,
                            'ERROR BLC_COPA_INSERT. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
                        );
                        */
                        NULL;
                END;
            END IF;
            l_id_insis := NULL;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(
                -20400,
                'ERROR IN BLC_COPA_INSERT. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
            );
    END BLC_COPA_INSERT;
    
  --------------------------------------------------------------------------------
    PROCEDURE BLC_RI_EXEC (
        pi_le_id IN NUMBER,
        pi_list_records IN VARCHAR2) 
    IS
        l_username VARCHAR2(30);
        l_blc_rei_acc_count NUMBER;
        
        CURSOR c_blc_rei_gen_a (
            legal_entity IN NUMBER, 
            id_list IN VARCHAR2
        ) IS
            SELECT GEN.*
            FROM BLC_REI_GEN GEN
            JOIN XMLTABLE ( id_list )
                ON GEN.ID = to_number(COLUMN_VALUE)
            WHERE GEN.LEGAL_ENTITY = legal_entity 
            AND GEN.STATUS = 'N' 
            AND (GEN.IP_CODE IS NULL OR GEN.IP_CODE = 'I018') --07.11.2019 - Dora - add to select only RI bill transactions
            ORDER BY GEN.ID;

        CURSOR c_blc_rei_gen_b (
            legal_entity IN NUMBER
        ) IS       
            SELECT GEN.*
            FROM BLC_REI_GEN GEN
            WHERE GEN.LEGAL_ENTITY = legal_entity
            AND GEN.STATUS = 'N'
            AND (GEN.IP_CODE IS NULL OR GEN.IP_CODE = 'I018') --07.11.2019 - Dora - add to select only RI bill transactions
            ORDER BY GEN.ID;
/*
        CURSOR c_BLC_REI_ACC (
            gen_id IN NUMBER,
            row_begin IN NUMBER,
            row_end IN NUMBER
        ) IS
            SELECT
                ACC.*
            FROM
                BLC_REI_ACC ACC
            WHERE
                ACC.ID = gen_id AND
                ACC.LINE_NUMBER BETWEEN row_begin AND row_end
            ORDER BY
                ACC.ID,
                ACC.LINE_NUMBER;
*/
        CURSOR c_BLC_REI_ACC (
            gen_id IN NUMBER,
            row_begin IN NUMBER,
            row_end IN NUMBER
        ) IS
            SELECT *
            FROM (
                SELECT
                A.ID,
                ROWNUM LINE_NUMBER,
                A.DR_CR_FLAG,
                A.ACCOUNT,
                A.TECH_BRANCH,
                A.POLICY_NO,
                A.POLICY_START_DATE,
                A.DOC_PARTY,
                A.PROFORMA_NUMBER,
                NULL FC_AMOUNT,
                A.AMOUNT,
                A.POLICY_CURRENCY,
                A.SALES_CHANNEL,
                A.INSR_TYPE,
                A.INTERMED_TYPE,
                A.POLICY_CLASS,
                NULL GLTRANS_ID,
                NULL SAP_DOC_NUMBER,
                NULL REVERSAL_SAP_DOC_NUMBER,
                NULL CREATED_ON,
                NULL CREATED_BY,
                NULL UPDATED_ON,
                NULL UPDATED_BY,
                NULL STATUS,
                NULL PROCESS_START_DATE,
                NULL PROCESS_END_DATE,
                A.ACCOUNT_ATTRIBS,
                NULL BUSINESS_UNIT, --07.11.2019 --Dora add new columns
                NULL PROFORMA_DOC_TYPE,
                NULL DOC_PARTY_NAME,
                NULL CLAIM_NUMBER,
                NULL POLICY_OFFICE,
                NULL ACC_TEMP_CODE
                FROM (
                SELECT
                    ID,
                    CASE WHEN SUM(CASE WHEN  DR_CR_FLAG = 'DR'  THEN AMOUNT ELSE AMOUNT * -1 END) > 0 THEN 'DR' ELSE 'CR' END DR_CR_FLAG,
                    ACCOUNT,
                    TECH_BRANCH,
                    POLICY_NO,
                    MIN(POLICY_START_DATE) POLICY_START_DATE,
                    MIN(DOC_PARTY) DOC_PARTY,
                    MIN(PROFORMA_NUMBER) PROFORMA_NUMBER,
                    ABS(SUM(CASE WHEN  DR_CR_FLAG = 'DR'  THEN AMOUNT ELSE AMOUNT * -1 END) ) AMOUNT,
                    POLICY_CURRENCY,
                    MIN(SALES_CHANNEL) SALES_CHANNEL,
                    INSR_TYPE,
                    MIN(INTERMED_TYPE) INTERMED_TYPE,
                    MIN(POLICY_CLASS) POLICY_CLASS,
                    MIN(ACCOUNT_ATTRIBS) ACCOUNT_ATTRIBS
                FROM INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                WHERE ID = gen_id
                GROUP BY ID, ACCOUNT, TECH_BRANCH, POLICY_NO,  -- DOC_PARTY, PROFORMA_NUMBER,
                  POLICY_CURRENCY, INSR_TYPE
                ) A
            )
            WHERE AMOUNT > 0 AND LINE_NUMBER BETWEEN row_begin AND row_end;
        --
        l_blc_rei_acc_ini NUMBER := 1;
        l_blc_rei_acc_fin NUMBER;
        l_bussunit VARCHAR2(2);
        --
        r_blc_rei_gen BLC_REI_GEN%ROWTYPE;
        r_blc_rei_acc BLC_REI_ACC%ROWTYPE;
        r_iib_rei_gen INSIS_CUST_LPV.IIBTBLREI_GEN%ROWTYPE;
        r_iib_rei_acc INSIS_CUST_LPV.IIBTBLREI_ACC%ROWTYPE;
        r_iib_rei_pol INSIS_CUST_LPV.IIBTBLREI_POL%ROWTYPE;
        l_error_message VARCHAR2(255);
        l_process_start DATE;
    BEGIN
        BEGIN
            SELECT SYS_CONTEXT ('USERENV', 'SESSION_USER') INTO l_username FROM DUAL;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_username := 'INSIS_BLC_GLOBAL_CUST';
        END;
        --
        IF
            pi_list_records IS NOT NULL
        THEN
            OPEN c_BLC_REI_GEN_A(
                pi_le_id, pi_list_records
            );
        ELSE
            OPEN c_BLC_REI_GEN_B(pi_le_id);
        END IF;
        --
        LOOP
            IF
                pi_list_records IS NOT NULL
            THEN
                FETCH c_BLC_REI_GEN_A INTO r_BLC_REI_GEN;
                IF
                    c_BLC_REI_GEN_A%NOTFOUND
                THEN
                    EXIT;
                END IF;
            ELSE
                FETCH c_BLC_REI_GEN_B INTO r_BLC_REI_GEN;
                IF
                    c_BLC_REI_GEN_B%NOTFOUND
                THEN
                    EXIT;
                END IF;
            END IF;
            -- Iterate accounting lines to generate additional headers if needed
/*
            SELECT
                COUNT(1)
            INTO
                l_BLC_REI_ACC_count
            FROM
                BLC_REI_ACC
            WHERE
                ID = r_BLC_REI_GEN.ID;
*/
            SELECT
                COUNT(1)
            INTO
                l_BLC_REI_ACC_count
            FROM(
            SELECT 1
            FROM INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
            WHERE ID = r_BLC_REI_GEN.ID
            AND DR_CR_FLAG = 'DR' 
            GROUP BY ID, ACCOUNT, TECH_BRANCH, POLICY_NO,  DOC_PARTY, PROFORMA_NUMBER,
              POLICY_CURRENCY, INSR_TYPE
            HAVING SUM(AMOUNT) > 0
            );
            DBMS_OUTPUT.put_line('l_BLC_REI_ACC_count: ' || l_BLC_REI_ACC_count);
            --
            l_ERROR_MESSAGE := NULL;
            -- Update Status to: Processing
            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_GEN
                    SET
                        STATUS = 'P',
                        UPDATED_ON = SYSDATE,
                        UPDATED_BY = l_username
                WHERE
                    ID = r_BLC_REI_GEN.ID;
                    
            l_process_start := SYSDATE;        
            l_BLC_REI_ACC_ini :=1;
            DBMS_OUTPUT.put_line('l_BLC_REI_ACC_ini: ' || l_BLC_REI_ACC_ini);
            WHILE
                l_BLC_REI_ACC_ini < l_BLC_REI_ACC_count
                --
                LOOP
                    --
                    r_IIB_REI_GEN.NSEQUENCE := NULL;
                    /* FIXME Mapping function */
                    r_IIB_REI_GEN.NCOMPANY :=
                        CASE r_BLC_REI_GEN.LEGAL_ENTITY
                            WHEN 10000000 THEN '2'
                        END;
                    r_IIB_REI_GEN.NSISTORIGIN := '5';
                    r_IIB_REI_GEN.NVOUCHER := NULL;
                    /* FIXME HIGH/MASS=10/1 */
                    r_IIB_REI_GEN.NPRIOR := 2;
                    r_IIB_REI_GEN.SGLOSA :=
                        CASE r_BLC_REI_GEN.RI_FAC_FLAG
                            --WHEN 'X' THEN 'PRIMAS DIRECTO REA CF' --defect 537 comment
                            WHEN 'Y' THEN 'PRIMAS DIRECTO REA CF' --defect 537
                            ELSE 'PRIMAS DIRECTO REA CA'
                        END;
                    --r_IIB_REI_GEN.DEFFECDATE := last_day(r_BLC_REI_GEN.DOC_ISSUE_DATE); --INC-169/205
                    r_IIB_REI_GEN.DEFFECDATE := last_day(add_months(r_BLC_REI_GEN.DOC_ISSUE_DATE,-1)); --INC-169/205
                    r_IIB_REI_GEN.SDOC_TYPE :=
                        CASE r_BLC_REI_GEN.RI_FAC_FLAG
                            --WHEN 'X' THEN 'R0' --defect 537 comment
                            WHEN 'Y' THEN 'R0' --defect 537
                            ELSE 'R5'
                        END;
                    r_IIB_REI_GEN.SREF_DOC := r_BLC_REI_GEN.ACC_DOC_ID;
                    /* TODO Check fadata rule for this value */
                    r_IIB_REI_GEN.SACTION := r_BLC_REI_GEN.ACTION_TYPE;
                    r_IIB_REI_GEN.NGROUP := NULL;
                    r_IIB_REI_GEN.SDOC_SAP := NULL;
                    r_IIB_REI_GEN.SDOC_YEAR := NULL;
                    /* TODO Check this mapping */
                    r_IIB_REI_GEN.DLEDGERDAT := SYSDATE;
                    /* FIXME Check this mapping */
                    r_IIB_REI_GEN.SNULLCODE := NULL;
                    /*
                    CASE
                    WHEN ((TRUNC(SYSDATE) BETWEEN TRUNC(DEFFECDATE_AUX, 'MONTH') AND LAST_DAY(DEFFECDATE_AUX))
                    OR (TRUNC(SYSDATE) <= (LAST_DAY(DEFFECDATE_AUX) + 7))) THEN
                    '01'
                    ELSE
                    '02'
                    END AS SNULLCODE
                    */
                    r_IIB_REI_GEN.DCOMPDATE := SYSDATE;
                    -- INSERT GEN
                    INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI001(
                        NSEQUENCE => r_IIB_REI_GEN.NSEQUENCE,
                        NCOMPANY => r_IIB_REI_GEN.NCOMPANY,
                        NSISTORIGIN => r_IIB_REI_GEN.NSISTORIGIN,
                        NVOUCHER => r_IIB_REI_GEN.NVOUCHER,
                        NPRIOR => r_IIB_REI_GEN.NPRIOR,
                        SGLOSA => r_IIB_REI_GEN.SGLOSA,
                        DEFFECDATE => r_IIB_REI_GEN.DEFFECDATE,
                        SDOC_TYPE => r_IIB_REI_GEN.SDOC_TYPE,
                        SREF_DOC => r_IIB_REI_GEN.SREF_DOC,
                        SACTION => r_IIB_REI_GEN.SACTION,
                        NGROUP => r_IIB_REI_GEN.NGROUP,
                        SDOC_SAP => r_IIB_REI_GEN.SDOC_SAP,
                        SDOC_YEAR => r_IIB_REI_GEN.SDOC_YEAR,
                        DLEDGERDAT => r_IIB_REI_GEN.DLEDGERDAT,
                        SNULLCODE => r_IIB_REI_GEN.SNULLCODE,
                        DCOMPDATE => r_IIB_REI_GEN.DCOMPDATE,
                        NSEQUENCE_TRA => r_BLC_REI_GEN.ID
                    );
                    DBMS_OUTPUT.put_line('r_IIB_REI_GEN.NSEQUENCE: ' || r_IIB_REI_GEN.NSEQUENCE);  
                    --
                    /* TODO Define a constant for the max row value */
                    l_BLC_REI_ACC_fin := l_BLC_REI_ACC_ini + 5;
                    DBMS_OUTPUT.put_line('l_BLC_REI_ACC_ini: ' || l_BLC_REI_ACC_ini);
                    DBMS_OUTPUT.put_line('l_BLC_REI_ACC_fin: ' || l_BLC_REI_ACC_fin);
                    DBMS_OUTPUT.put_line('r_BLC_REI_GEN.ID: ' || r_BLC_REI_GEN.ID);
                    --
                    OPEN c_BLC_REI_ACC(
                        r_BLC_REI_GEN.ID, l_BLC_REI_ACC_ini, l_BLC_REI_ACC_fin
                    );
                    LOOP
                        BEGIN
                            FETCH c_BLC_REI_ACC INTO r_BLC_REI_ACC;
                            EXIT WHEN c_BLC_REI_ACC%NOTFOUND OR c_BLC_REI_ACC%NOTFOUND IS NULL;
                            IF
                                r_BLC_REI_ACC.AMOUNT > 0
                            THEN
                                -- Update Status to: Processing
                                UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                                    SET
                                        STATUS = 'P',
                                        UPDATED_ON = SYSDATE,
                                        UPDATED_BY = l_username
                                WHERE
                                    ID = r_BLC_REI_ACC.ID AND
                                    LINE_NUMBER = r_BLC_REI_ACC.LINE_NUMBER;
                                --
                                r_IIB_REI_ACC.NSEQUENCE := r_IIB_REI_GEN.NSEQUENCE;
                                r_IIB_REI_ACC.NITEM_NUM := r_BLC_REI_ACC.LINE_NUMBER;
                                DBMS_OUTPUT.put_line('r_IIB_REI_ACC.NSEQUENCE: ' || r_IIB_REI_ACC.NSEQUENCE);
                                DBMS_OUTPUT.put_line('r_IIB_REI_ACC.NITEM_NUM: ' || r_IIB_REI_ACC.NITEM_NUM);
                                IF
                                    r_BLC_REI_GEN.INSURER_PARTY IS NOT NULL
                                THEN
                                    BEGIN
                                        SELECT
                                            lpad(
                                                SAP_PROVIDER_ID,
                                                10,
                                                '0'
                                            )
                                        INTO
                                            r_IIB_REI_ACC.SVENDOR_SAP
                                        FROM
                                            INSIS_CUST.INTRF_LPV_PEOPLE_IDS
                                        WHERE
                                            MAN_ID = r_BLC_REI_GEN.INSURER_PARTY;
                                    EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                            raise_application_error(
                                                -20000,
                                                'SVENDOR_SAP NO EXISTE EN INTRF_LPV_PEOPLE_IDS'
                                            );
                                    END;
                                ELSE
                                    r_IIB_REI_ACC.SVENDOR_SAP := NULL;
                                END IF;
                                r_IIB_REI_ACC.SACCOUNT := r_BLC_REI_ACC.ACCOUNT;
                                r_IIB_REI_ACC.SDOC_TYPE := r_IIB_REI_GEN.SDOC_TYPE;
                                r_IIB_REI_ACC.SBRANCH_POLICY := r_BLC_REI_ACC.TECH_BRANCH || '-' || r_BLC_REI_ACC.POLICY_NO;
                                r_IIB_REI_ACC.DEFFECDATE := r_BLC_REI_ACC.POLICY_START_DATE;
                                IF
                                    r_BLC_REI_ACC.DOC_PARTY IS NOT NULL
                                THEN
                                    r_IIB_REI_ACC.SCLIENT := PEOPLE_SAP_CODE(r_BLC_REI_ACC.DOC_PARTY);
                                ELSE
                                    r_IIB_REI_ACC.SCLIENT := NULL;
                                END IF;
                                r_IIB_REI_ACC.NRECEIPT := r_BLC_REI_ACC.PROFORMA_NUMBER;
                                /* TODO Check mapping */
                                r_IIB_REI_ACC.NOFFICE := get_nOffice(r_BLC_REI_GEN.OFFICE_GL_NO);
                                r_IIB_REI_ACC.SGLOSA :=
                                    CASE
                                        WHEN r_BLC_REI_ACC.ACCOUNT LIKE '20%' THEN 'INSIS-' || 'RETENCIONES RENTA DE NO DOMICILIADO'
                                     -- WHEN r_BLC_REI_ACC.ACCOUNT LIKE '40%' THEN 'INSIS-' || get_OFFICE_NAME(get_nOffice(r_BLC_REI_ACC.TECH_BRANCH) )
                                        /* FIXME */
                                        WHEN r_BLC_REI_ACC.ACCOUNT LIKE '40%' THEN 'INSIS-' || r_BLC_REI_ACC.TECH_BRANCH
                                        WHEN r_BLC_REI_ACC.ACCOUNT LIKE '24%' THEN 'INSIS-' || r_BLC_REI_GEN.INSURER_PARTY_NAME
                                    END;
                                r_IIB_REI_ACC.NCURRENCY :=
                                    CASE r_BLC_REI_GEN.CURRENCY
                                        WHEN 'PEN' THEN 1
                                        WHEN 'USD' THEN 2
                                        ELSE NULL
                                    END;
                                r_IIB_REI_ACC.NORI_AMO :=
                                    CASE r_BLC_REI_ACC.DR_CR_FLAG
                                        WHEN 'DR' THEN r_BLC_REI_ACC.AMOUNT
                                        WHEN 'CR' THEN r_BLC_REI_ACC.AMOUNT *-1
                                        ELSE NULL
                                    END;
                                /* FIXME Mapping */
                                r_IIB_REI_ACC.NCOUNTRY := 1;
                                r_IIB_REI_ACC.NCOMPANY := r_IIB_REI_GEN.NCOMPANY;
                                r_IIB_REI_ACC.NBRANCH_BAL := r_BLC_REI_ACC.TECH_BRANCH;
                                r_IIB_REI_ACC.NGEOGRAPHICZONE := 0;
                                /* FIXME Mapping */
                                r_IIB_REI_ACC.NCURRENCY_POL :=
                                    CASE r_BLC_REI_ACC.POLICY_CURRENCY
                                        WHEN 'PEN' THEN '1'
                                        WHEN 'USD' THEN '2'
                                        ELSE NULL
                                    END;
                                r_IIB_REI_ACC.SCUSTOMER_SAP := r_IIB_REI_ACC.SVENDOR_SAP;
                                /* FIXME When technical field ACC_CLASS is added */
                                r_IIB_REI_ACC.SCLAIM_CASE := '1';
                                r_IIB_REI_ACC.DOCCURDAT := NULL;
                                r_IIB_REI_ACC.STIPPRC :=
                                    CASE substr(
                                        r_BLC_REI_ACC.ACCOUNT_ATTRIBS,
                                        1,
                                        1
                                    )
                                        WHEN 'S' THEN '4'
                                        WHEN 'D' THEN '3'
                                        WHEN 'K' THEN '2'
                                        ELSE '0'
                                    END;
                                r_IIB_REI_ACC.NTYPECONTRACT :=
                                    CASE r_BLC_REI_GEN.RI_CONTRACT_TYPE
                                        WHEN 'NPR' THEN '0'
                                        WHEN 'PR' THEN '1'
                                        ELSE NULL
                                    END;
                                l_bussunit := get_BUSINESS_UNIT(
                                    r_BLC_REI_ACC.INSR_TYPE,
                                    r_BLC_REI_ACC.SALES_CHANNEL
                                );
                                INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI002(
                                    NSEQUENCE => r_IIB_REI_ACC.NSEQUENCE,
                                    NITEM_NUM => r_IIB_REI_ACC.NITEM_NUM,
                                    SVENDOR_SAP => r_IIB_REI_ACC.SVENDOR_SAP,
                                    SACCOUNT => r_IIB_REI_ACC.SACCOUNT,
                                    SDOC_TYPE => r_IIB_REI_ACC.SDOC_TYPE,
                                    SBRANCH_POLICY => r_IIB_REI_ACC.SBRANCH_POLICY,
                                    DEFFECDATE => r_IIB_REI_ACC.DEFFECDATE,
                                    SCLIENT => r_IIB_REI_ACC.SCLIENT,
                                    NRECEIPT => r_IIB_REI_ACC.NRECEIPT,
                                    NOFFICE => r_IIB_REI_ACC.NOFFICE,
                                    SGLOSA => r_IIB_REI_ACC.SGLOSA,
                                    NCURRENCY => r_IIB_REI_ACC.NCURRENCY,
                                    NORI_AMO => r_IIB_REI_ACC.NORI_AMO,
                                    NCOUNTRY => r_IIB_REI_ACC.NCOUNTRY,
                                    NCOMPANY => r_IIB_REI_ACC.NCOMPANY,
                                    NBRANCH_BAL => r_IIB_REI_ACC.NBRANCH_BAL,
                                    NGEOGRAPHICZONE => r_IIB_REI_ACC.NGEOGRAPHICZONE,
                                    NCURRENCY_POL => r_IIB_REI_ACC.NCURRENCY_POL,
                                    SCUSTOMER_SAP => r_IIB_REI_ACC.SCUSTOMER_SAP,
                                    SCLAIM_CASE => r_IIB_REI_ACC.SCLAIM_CASE,
                                    DOCCURDAT => r_IIB_REI_ACC.DOCCURDAT,
                                    STIPPRC => r_IIB_REI_ACC.STIPPRC,
                                    NTYPECONTRACT => r_IIB_REI_ACC.NTYPECONTRACT,
                                    NBUSSIUNIT => l_bussunit
                                );
                                IF
                                    r_BLC_REI_ACC.ACCOUNT_ATTRIBS IS NOT NULL AND 
                                    LENGTH(r_BLC_REI_ACC.ACCOUNT_ATTRIBS) = 5 AND 
                                    SUBSTR(
                                        r_BLC_REI_ACC.ACCOUNT_ATTRIBS,
                                        5,
                                        1
                                    ) = 'Y'
                                THEN
                                    BLC_COPA_INSERT(
                                        r_IIB_REI_ACC.NSEQUENCE,
                                        r_BLC_REI_ACC.LINE_NUMBER,
                                        r_BLC_REI_ACC.TECH_BRANCH,
                                        r_BLC_REI_GEN.OFFICE_GL_NO,
                                        r_BLC_REI_ACC.SALES_CHANNEL,
                                        '1',
                                        r_BLC_REI_ACC.INSR_TYPE,
                                        r_BLC_REI_ACC.INTERMED_TYPE,
                                        get_BUSINESS_UNIT(
                                            r_BLC_REI_ACC.INSR_TYPE,
                                            r_BLC_REI_ACC.SALES_CHANNEL)
                                    );
                                END IF;
                            END IF;
                            --
                            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                                SET
                                    STATUS = 'S',
                                    UPDATED_ON = SYSDATE,
                                    UPDATED_BY = l_username
                            WHERE
                                ID = r_BLC_REI_ACC.ID AND
                                LINE_NUMBER = r_BLC_REI_ACC.LINE_NUMBER;                        
                            
                            
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_ERROR_MESSAGE := 'ERROR IN REI ACC PROCESS' || ' SQLERRM=' || SQLERRM || ' SQLCODE=' || SQLCODE;
                                /*                        
                                --
                                UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                                    SET
                                        STATUS = 'E',
                                        UPDATED_ON = SYSDATE,
                                        UPDATED_BY = l_username
                                WHERE
                                    ID = r_BLC_REI_ACC.ID;
                                --
                                UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_GEN
                                    SET
                                        STATUS = 'E',
                                        UPDATED_ON = SYSDATE,
                                        UPDATED_BY = l_username,
                                        ERROR_TYPE = 'IP_ERROR',
                                        ERROR_MSG = l_ERROR_MESSAGE
                                WHERE
                                    ID = r_BLC_REI_GEN.ID;
                                    
                                COMMIT;
                                -->RAISE;
                                */
                        END;
                    END LOOP;
                    IF l_ERROR_MESSAGE IS NULL
                    THEN
                        UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                        SET
                            STATUS = 'S',
                            UPDATED_ON = SYSDATE,
                            UPDATED_BY = l_username
                        WHERE
                            ID = r_BLC_REI_ACC.ID AND STATUS = 'N';
                    END IF;
                    
                    CLOSE c_BLC_REI_ACC;
                    
                    IF l_ERROR_MESSAGE IS NULL
                    THEN
                    DBMS_OUTPUT.put_line('l_ERROR_MESSAGE NULL:');
                      -- INSERT JOB
                      INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI004(
                          NSEQUENCE => r_IIB_REI_GEN.NSEQUENCE,
                          NCOMPANY => r_IIB_REI_GEN.NCOMPANY,
                          NSISTORIGIN => 5,
                          NVOUCHER => NULL,
                          NPRIOR => 2,
                          DCOMPDATE => SYSDATE,
                          DPASSDATE => SYSDATE,
                          DPROCINI => NULL,
                          DPROCEND => NULL,
                          NSTATUS => 0,
                          SMSGERROR => NULL,
                          SSEQUENCE_SAP => NULL,
                          NREINTENTOS => NULL
                         );
                      ELSE
                      DBMS_OUTPUT.put_line('r_BLC_REI_GEN.ID: ' || r_BLC_REI_GEN.ID);
                      DBMS_OUTPUT.put_line('l_BLC_REI_ACC_ini: ' || l_BLC_REI_ACC_ini);
                      DBMS_OUTPUT.put_line('l_BLC_REI_ACC_fin: ' || l_BLC_REI_ACC_fin);
                      DBMS_OUTPUT.put_line('l_ERROR_MESSAGE: ' || l_ERROR_MESSAGE);
                         cust_intrf_util_pkg.Blc_Process_Ip_Result_2(
                            pi_header_id => r_BLC_REI_GEN.ID,
                            pi_header_table => 'BLC_REI_GEN',
                            pi_line_number_from => l_BLC_REI_ACC_ini,
                            pi_line_number_to => l_BLC_REI_ACC_fin,
                            pi_status => 'E',
                            pi_sap_doc_number => NULL,
                            pi_error_type => 'IP_ERROR',
                            pi_error_msg => l_ERROR_MESSAGE,
                            pi_process_start => l_process_start,
                            pi_process_end => SYSDATE);
                      END IF;      
                     
                    --
                    l_BLC_REI_ACC_ini := l_BLC_REI_ACC_fin + 1;
                --END LOOP;
                IF l_ERROR_MESSAGE IS NULL
                THEN
                      UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_GEN
                          SET
                              STATUS = 'S',
                              UPDATED_ON = SYSDATE,
                              UPDATED_BY = l_username
                      WHERE
                          ID = r_BLC_REI_GEN.ID; 
                END IF;      
                END LOOP;            
        END LOOP;
        --
        IF
            pi_list_records IS NOT NULL
        THEN
            CLOSE c_BLC_REI_GEN_A;
        ELSE
            CLOSE c_BLC_REI_GEN_B;
        END IF;
        --
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            --
            l_ERROR_MESSAGE := 'ERROR IN BLC_RI_EXEC' || ' SQLERRM=' || SQLERRM || ' SQLCODE=' || SQLCODE;
            --
            ROLLBACK;
            --
            /*
            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_GEN
                SET
                    STATUS = 'E',
                    UPDATED_ON = SYSDATE,
                    UPDATED_BY = l_username,
                    ERROR_TYPE = 'IP_ERROR',
                    ERROR_MSG = l_ERROR_MESSAGE
            WHERE
                ID = r_BLC_REI_GEN.ID;
            --
            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                SET
                    STATUS = 'E',
                    UPDATED_ON = SYSDATE,
                    UPDATED_BY = l_username
            WHERE
                ID = r_BLC_REI_ACC.ID;
            */
             cust_intrf_util_pkg.Blc_Process_Ip_Result(
                        pi_header_id => r_BLC_REI_GEN.ID,
                        pi_header_table => 'BLC_REI_GEN',
                        pi_status => 'E',
                        pi_sap_doc_number => NULL,
                        pi_error_type => 'IP_ERROR',
                        pi_error_msg => l_ERROR_MESSAGE,
                        pi_process_start => NVL(l_process_start,SYSDATE),
                        pi_process_end => SYSDATE);
            --
            COMMIT;
            RAISE_APPLICATION_ERROR(
                -20402,
                l_ERROR_MESSAGE
            );


    END BLC_RI_EXEC;
    
    --
    PROCEDURE BLC_RI_CLO (
        pi_nSequence IN NUMBER,
        pi_dProcIni IN DATE,
        pi_dProcEnd IN DATE,
        pi_nStatus IN NUMBER,
        pi_sMsgError IN VARCHAR2,
        pi_sSequence_SAP IN VARCHAR2
    ) IS
        l_ERROR_MESSAGE VARCHAR2(250 CHAR);
        l_status VARCHAR2(1);
        l_Context insis_sys_v10.SRVContext;
        l_RetContext insis_sys_v10.SRVContext;
        l_SrvErr insis_sys_v10.SrvErr;
    BEGIN
        CASE
            pi_nStatus            
            WHEN 2 THEN
                l_status := 'T';
            WHEN 3 THEN
                l_status := 'E';
            ELSE
                l_status := 'E';
        END CASE;
        
        
        UPDATE BLC_REI_GEN
            SET
                PROCESS_START_DATE = BLC_RI_CLO.pi_dProcIni,
                PROCESS_END_DATE = BLC_RI_CLO.pi_dProcEnd,
                STATUS = l_status,
                ERROR_MSG = BLC_RI_CLO.pi_sMsgError,
                SAP_DOC_NUMBER = BLC_RI_CLO.pi_sSequence_SAP
        WHERE
            ID = BLC_RI_CLO.pi_nSequence;
        
        
        srv_context.SetContextAttrNumber(
            l_Context,
            'HEADER_ID',
            srv_context.Integers_Format,
            BLC_RI_CLO.pi_nSequence
        );
        srv_context.SetContextAttrChar(
            l_Context,
            'HEADER_TABLE',
            'BLC_REI_GEN'
        );
        IF
            l_status = 'T'
        THEN
            srv_context.SetContextAttrChar(
                l_Context,
                'SAP_DOC_NUMBER',
                BLC_RI_CLO.pi_sSequence_SAP
            );
        -- SUBSTRING ???
        ELSE
            srv_context.SetContextAttrChar(
                l_Context,
                'ERROR_MSG',
                BLC_RI_CLO.pi_sMsgError
            );
            srv_context.SetContextAttrChar(
                l_Context,
                'ERROR_TYPE',
                'SAP_ERROR'
            );
        END IF;
        srv_context.SetContextAttrChar(
            l_Context,
            'STATUS',
            l_status
        );
        srv_context.SetContextAttrDate(
            l_Context,
            'PROCESS_START_DATE',
            srv_context.Date_Format,
            BLC_RI_CLO.pi_dProcIni
        );
        srv_context.SetContextAttrDate(
            l_Context,
            'PROCESS_END_DATE',
            srv_context.Date_Format,
            BLC_RI_CLO.pi_dProcEnd
        );
        srv_events.sysEvent(
            'CUST_BLC_PROCESS_IP_RESULT',
            l_Context,
            l_RetContext,
            l_SrvErr
        );
        IF
            l_SrvErr IS NOT NULL
        THEN
            FOR r IN l_SrvErr.first..l_SrvErr.last LOOP
                dbms_output.put_line(l_SrvErr(r).errfn || ' - ' || l_SrvErr(r).errcode || ' - ' || l_SrvErr(r).errmessage);
            END LOOP;
        END IF;
        IF
            NOT srv_error.rqStatus(l_SrvErr)
        THEN
            ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            l_ERROR_MESSAGE := 'ERROR IN BLC_RI_CLO' || ' SQLERRM=' || SQLERRM || ' SQLCODE=' || SQLCODE;
            DBMS_OUTPUT.put_line(l_ERROR_MESSAGE);
            RAISE_APPLICATION_ERROR(
                -20401,
                l_ERROR_MESSAGE
            );
    END BLC_RI_CLO;
    
--

    PROCEDURE BLC_CMP_EXEC (
        pi_le_id IN NUMBER,
        pi_list_records IN VARCHAR2
    ) IS
    
        l_username VARCHAR2(30);
    --
        l_BLC_REI_ACC_count NUMBER;
        CURSOR c_BLC_REI_GEN_A (
            LEGAL_ENTITY IN NUMBER,
            ID_LIST IN VARCHAR2
        ) IS
            SELECT
                GEN.*
            FROM
                BLC_REI_GEN GEN
            JOIN XMLTABLE ( ID_LIST )
                ON GEN.ID = to_number(COLUMN_VALUE)
            WHERE
                GEN.LEGAL_ENTITY = LEGAL_ENTITY AND
                GEN.STATUS = 'N' AND
                GEN.IP_CODE  IN ('I017','I019')
            ORDER BY
                GEN.ID;
                
        CURSOR c_BLC_REI_GEN_B (
            LEGAL_ENTITY IN NUMBER
        ) IS
            SELECT
                GEN.*
            FROM
                BLC_REI_GEN GEN
            WHERE
                GEN.LEGAL_ENTITY = LEGAL_ENTITY AND
                GEN.STATUS = 'N' AND
                GEN.IP_CODE IN ('I017','I019') 
            ORDER BY
                GEN.ID;

        CURSOR c_BLC_REI_ACC (
            gen_id IN NUMBER, 
            row_begin IN NUMBER,
            row_end IN NUMBER
        ) IS
            SELECT
            A.ID,
            ROWNUM LINE_NUMBER,
            A.DR_CR_FLAG,
            A.ACCOUNT,
            A.TECH_BRANCH,
            A.POLICY_NO,
            A.POLICY_START_DATE,
            A.DOC_PARTY,
            A.PROFORMA_NUMBER,
            A.CLAIM_NUMBER,
            A.AMOUNT,
            A.SALES_CHANNEL,
            A.INSR_TYPE,
            A.INTERMED_TYPE,
            A.POLICY_CLASS,
            CASE SUBSTR(A.ACCOUNT_ATTRIBS,1,1)
                    WHEN 'S' THEN '2'
                    WHEN 'D' THEN '3'
                    WHEN 'K' THEN '4'
                    ELSE '0'
            END AS SACC_CLASS,
            A.BUSINESS_UNIT, 
            NULL SALLOC_NMBR,
            A.ACC_TEMP_CODE,
            A.DOC_TYPE,
            A.DOC_PARTY_NAME
            FROM (
            SELECT ID,
                        CASE WHEN SUM(CASE WHEN  DR_CR_FLAG = 'DR'  THEN AMOUNT ELSE AMOUNT * -1 END) > 0 THEN 'DR' ELSE 'CR' END DR_CR_FLAG,
                        ACCOUNT,
                        TECH_BRANCH,
                        POLICY_NO,
                        MIN(POLICY_START_DATE) POLICY_START_DATE,
                        MIN(DOC_PARTY) DOC_PARTY,
                        MIN(TO_NUMBER(PROFORMA_NUMBER)) PROFORMA_NUMBER,
                        MIN(CLAIM_NUMBER) CLAIM_NUMBER,
                        ABS(SUM(CASE WHEN  DR_CR_FLAG = 'DR' THEN AMOUNT ELSE AMOUNT * -1 END) ) AMOUNT,
                        POLICY_CURRENCY,
                        MIN(SALES_CHANNEL) SALES_CHANNEL,
                        INSR_TYPE,
                        MIN(INTERMED_TYPE) INTERMED_TYPE,
                        MIN(POLICY_CLASS) POLICY_CLASS,
                        MIN(ACCOUNT_ATTRIBS) ACCOUNT_ATTRIBS,
                        CASE  WHEN PROFORMA_DOC_TYPE ='PROFORMA' THEN 'FA'
                                  WHEN PROFORMA_DOC_TYPE = 'NOTA CREDITO' THEN 'FB' END AS DOC_TYPE,             
                        BUSINESS_UNIT,
                         SUBSTR(ACC_TEMP_CODE,1,6) ACC_TEMP_CODE, DOC_PARTY_NAME  
              FROM INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
            WHERE ID = gen_id
             GROUP BY ID, ACCOUNT, TECH_BRANCH, POLICY_NO, POLICY_CURRENCY, INSR_TYPE, PROFORMA_DOC_TYPE, 
                        BUSINESS_UNIT,  SUBSTR(ACC_TEMP_CODE,1,6)  ,DOC_PARTY_NAME  
            ) A
           WHERE AMOUNT > 0 AND ROWNUM BETWEEN row_begin AND row_end;
        --
        l_COINSURAN_TYPE CHAR(1);
        l_DATE DATE;
        l_ANIOTRI_DATE CHAR(6);
        l_client_sap        INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_CODE_PERSON%TYPE;
        l_provider_sap    INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_PROVIDER_ID%TYPE;
        l_salloc_nmbr NUMBER(10);
        l_reinsuran_type CHAR(2);
        
        l_BLC_REI_ACC_ini NUMBER := 1;
        l_BLC_REI_ACC_fin NUMBER;
        l_bussunit VARCHAR2(2);
        --
        r_BLC_REI_GEN BLC_REI_GEN%ROWTYPE;
        r_BLC_REI_ACC c_BLC_REI_ACC%ROWTYPE;
        
        r_IIB_CMP_GEN INSIS_CUST_LPV.IIBTBLCMP_GEN%ROWTYPE;
        r_IIB_CMP_ACC INSIS_CUST_LPV.IIBTBLCMP_ACC%ROWTYPE;
       -- r_IIB_CMP_POL INSIS_CUST_LPV.IIBTBLCMP_POL%ROWTYPE;
        l_ERROR_MESSAGE VARCHAR2(255);
        l_process_start DATE;

    BEGIN

        BEGIN
            SELECT
                SYS_CONTEXT(
                    'USERENV',
                    'SESSION_USER'
                )
            INTO
                l_username
            FROM
                DUAL;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_username := 'INSIS_BLC_GLOBAL_CUST';
        END;
        --
        IF
            pi_list_records IS NOT NULL
        THEN
            OPEN c_BLC_REI_GEN_A(
                pi_le_id, pi_list_records
            );
        ELSE
            OPEN c_BLC_REI_GEN_B(pi_le_id);
        END IF;
        --
        LOOP
            IF
                pi_list_records IS NOT NULL
            THEN
                FETCH c_BLC_REI_GEN_A INTO r_BLC_REI_GEN;
                IF
                    c_BLC_REI_GEN_A%NOTFOUND
                THEN
                    DBMS_OUTPUT.put_line('c_BLC_REI_GEN_A%NOTFOUND');
                    EXIT;
                END IF;
            ELSE
                FETCH c_BLC_REI_GEN_B INTO r_BLC_REI_GEN;
                IF
                    c_BLC_REI_GEN_B%NOTFOUND
                THEN
                    DBMS_OUTPUT.put_line('c_BLC_REI_GEN_B%NOTFOUND');
                    EXIT;
                END IF;
            END IF;
            -- Iterate accounting lines to generate additional headers if needed
            
            SELECT
                COUNT(1)
            INTO
                l_BLC_REI_ACC_count
            FROM(
            SELECT 1
            FROM INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
            WHERE ID = r_BLC_REI_GEN.ID
            GROUP BY ID, ACCOUNT, TECH_BRANCH, POLICY_NO,  DOC_PARTY, PROFORMA_NUMBER,
              POLICY_CURRENCY, INSR_TYPE
            HAVING SUM(AMOUNT) > 0
            );

             l_ERROR_MESSAGE := NULL;
            
            -- Update Status to: Processing
            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_GEN
                    SET
                        STATUS = 'P',
                        UPDATED_ON = SYSDATE,
                        UPDATED_BY = l_username
                WHERE
                    ID = r_BLC_REI_GEN.ID;
                    
            l_process_start := SYSDATE;        
             DBMS_OUTPUT.put_line ('id '  ||  r_BLC_REI_GEN.ID);
             DBMS_OUTPUT.put_line ('l_BLC_REI_ACC_ini '  || l_BLC_REI_ACC_ini);
             DBMS_OUTPUT.put_line ('l_BLC_REI_ACC_count '  || l_BLC_REI_ACC_count);
            WHILE
                l_BLC_REI_ACC_ini < l_BLC_REI_ACC_count
            LOOP
                
                l_DATE := TO_DATE(LAST_DAY(ADD_MONTHS(r_BLC_REI_GEN.DOC_ISSUE_DATE,-1)));

                
                r_IIB_CMP_GEN.NSEQUENCE := NULL;
                
                CASE r_BLC_REI_GEN.IP_CODE WHEN 'I017' THEN 
                        r_IIB_CMP_GEN.SDOC_TYPE := 'YO';
                        l_ANIOTRI_DATE := TO_CHAR(l_DATE,'YYYYMM');
                ELSE                  
                        r_IIB_CMP_GEN.SDOC_TYPE := 'YE';
                        l_ANIOTRI_DATE := TO_CHAR(l_DATE,'YYYY') || '0' || TO_CHAR(l_DATE,'Q');
                END CASE;
                
                r_IIB_CMP_GEN.SGLOSA :=  'SALDOS CONCILIADOS ' || l_ANIOTRI_DATE;
                r_IIB_CMP_GEN.NCOMPANY :=  CASE r_BLC_REI_GEN.LEGAL_ENTITY  WHEN 10000000 THEN 1020 END;
                r_IIB_CMP_GEN.DDOC_DATE := TO_CHAR(l_DATE,'DD/MM/YYYY');
                r_IIB_CMP_GEN.DLEDGERDATE := TO_CHAR(l_DATE,'DD/MM/YYYY');
                r_IIB_CMP_GEN.DCHANGEDATE := TO_CHAR(l_DATE,'DD/MM/YYYY'); 

                r_IIB_CMP_GEN.SREF_DOC :=  CASE r_BLC_REI_GEN.HEADER_CLASS
                                                                     WHEN 'A' THEN 'COA REC' 
                                                                     WHEN 'C' THEN 'COA CED' 
                                                                     WHEN 'R' THEN 'REA CED' 
                                                              END || ' ' ||  l_ANIOTRI_DATE;
                r_IIB_CMP_GEN.SACTION := r_BLC_REI_GEN.ACTION_TYPE;
                r_IIB_CMP_GEN.SCURRENCY := r_BLC_REI_GEN.CURRENCY;
                r_IIB_CMP_GEN.SBUSSITYP := r_BLC_REI_GEN.HEADER_CLASS;

                IF r_BLC_REI_GEN.INSURER_PARTY IS NOT NULL  THEN

                    BEGIN
                        SELECT lpad(SAP_PROVIDER_ID, 10, '0' )
                           INTO l_provider_sap
                          FROM
                                  INSIS_CUST.INTRF_LPV_PEOPLE_IDS
                        WHERE
                                  MAN_ID = r_BLC_REI_GEN.INSURER_PARTY;
                                  
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                        raise_application_error( -20000, 'CÓDIGO DE COMPAÑÍA NO EXISTE EN INTRF_LPV_PEOPLE_IDS');
                    END;
                    
                ELSE
                    l_provider_sap := NULL;
                END IF;
                
                l_client_sap := PEOPLE_SAP_CODE(r_BLC_REI_GEN.INSURER_PARTY);
                
                r_IIB_CMP_GEN.SCOMPANY :=  l_client_sap;
                r_IIB_CMP_GEN.NTYPECONTRACT := NULL;
                IF r_BLC_REI_GEN.HEADER_CLASS = 'R' THEN
                    --l_reinsuran_type := CASE r_BLC_REI_GEN.RI_FAC_FLAG  WHEN 'X' THEN 'R0' ELSE 'R5'  END; --defect 537 comment
                    l_reinsuran_type := CASE r_BLC_REI_GEN.RI_FAC_FLAG  WHEN 'Y' THEN 'R0' ELSE 'R5'  END; --defect 537 
                    r_IIB_CMP_GEN.NTYPECONTRACT := CASE r_BLC_REI_GEN.RI_CONTRACT_TYPE
                                                                            WHEN 'NPR' THEN '2'
                                                                            WHEN 'PR' THEN '1'
                                                                            ELSE NULL
                                                                        END;
                END IF;    
                
               --r_IIB_CMP_GEN.SCOMPANY := PEOPLE_SAP_CODE(r_BLC_REI_GEN.INSURER_PARTY);
                l_salloc_nmbr := r_IIB_CMP_GEN.NCOMPANY || l_ANIOTRI_DATE;

                -- INSERT GEN
                INSIS_CUST_LPV.IIBPKGCMP.IIBPRCINSCMP001(
                                        NSEQUENCE => r_IIB_CMP_GEN.NSEQUENCE,
                                        SGLOSA => r_IIB_CMP_GEN.SGLOSA,
                                        NCOMPANY => r_IIB_CMP_GEN.NCOMPANY,
                                        DDOC_DATE => r_IIB_CMP_GEN.DDOC_DATE,
                                        DLEDGERDATE => r_IIB_CMP_GEN.DLEDGERDATE,
                                        DCHANGEDATE => r_IIB_CMP_GEN.DCHANGEDATE,
                                        SDOC_TYPE => r_IIB_CMP_GEN.SDOC_TYPE,
                                        SREF_DOC => r_IIB_CMP_GEN.SREF_DOC,
                                        SACTION => r_IIB_CMP_GEN.SACTION, 
                                        SCURRENCY => r_IIB_CMP_GEN.SCURRENCY,
                                        SCOMPANY => r_IIB_CMP_GEN.SCOMPANY,
                                        NTYPECONTRACT => r_IIB_CMP_GEN.NTYPECONTRACT,
                                        SBUSSITYP => r_IIB_CMP_GEN.SBUSSITYP,
                                        NSEQUENCE_TRA => r_BLC_REI_GEN.ID );
               
                  DBMS_OUTPUT.put_line ('CODIGO' || r_IIB_CMP_GEN.NSEQUENCE);
                l_BLC_REI_ACC_fin := l_BLC_REI_ACC_ini + 899;

                OPEN c_BLC_REI_ACC(
                    r_BLC_REI_GEN.ID, l_BLC_REI_ACC_ini, l_BLC_REI_ACC_fin
                );
                LOOP
                    BEGIN
                        FETCH c_BLC_REI_ACC INTO r_BLC_REI_ACC;
                        EXIT WHEN c_BLC_REI_ACC%NOTFOUND OR c_BLC_REI_ACC%NOTFOUND IS NULL;
                        DBMS_OUTPUT.put_line('ID=' || r_BLC_REI_ACC.ID);
                        DBMS_OUTPUT.put_line('LINE_NUMBER=' || r_BLC_REI_ACC.LINE_NUMBER);
                        
                        IF r_BLC_REI_ACC.AMOUNT > 0 THEN
                            -- Update Status to: Processing
                            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                                SET
                                    STATUS = 'P',
                                    UPDATED_ON = SYSDATE,
                                    UPDATED_BY = l_username
                            WHERE
                                ID = r_BLC_REI_ACC.ID AND
                                LINE_NUMBER = r_BLC_REI_ACC.LINE_NUMBER;

                            r_IIB_CMP_ACC.NSEQUENCE := r_IIB_CMP_GEN.NSEQUENCE;
                            r_IIB_CMP_ACC.NITEM_NUM := r_BLC_REI_ACC.LINE_NUMBER;
                            r_IIB_CMP_ACC.SACCOUNT := r_BLC_REI_ACC.ACCOUNT;
                            r_IIB_CMP_ACC.NOFFICE := get_nOffice(r_BLC_REI_GEN.OFFICE_GL_NO);
                            r_IIB_CMP_ACC.NCOUNTRY := 1;
                            r_IIB_CMP_ACC.SIND_DEB_CRED :=  CASE r_BLC_REI_ACC.DR_CR_FLAG WHEN 'DR' THEN 'S' ELSE 'H' END;
                            r_IIB_CMP_ACC.NAMOUNT := CASE r_BLC_REI_ACC.DR_CR_FLAG
                                                                                WHEN 'DR' THEN r_BLC_REI_ACC.AMOUNT
                                                                                WHEN 'CR' THEN r_BLC_REI_ACC.AMOUNT *-1
                                                                                ELSE NULL
                                                                        END;
                            
                            r_IIB_CMP_ACC.SPROFIT_FLAG := 'X';
                            r_IIB_CMP_ACC.SBUSINESS_UNIT := r_BLC_REI_ACC.BUSINESS_UNIT;--get_BUSINESS_UNIT(r_BLC_REI_ACC.INSR_TYPE, r_BLC_REI_ACC.SALES_CHANNEL);
                            r_IIB_CMP_ACC.NBRANCH := r_BLC_REI_ACC.TECH_BRANCH;
                            r_IIB_CMP_ACC.NPOLICY := r_BLC_REI_ACC.POLICY_NO;
                            r_IIB_CMP_ACC.SCLAIM  := r_BLC_REI_ACC.CLAIM_NUMBER;
                            r_IIB_CMP_ACC.NRECEIPT := r_BLC_REI_ACC.PROFORMA_NUMBER;
                            r_IIB_CMP_ACC.SCURRENCY :=  r_BLC_REI_GEN.CURRENCY;
                            r_IIB_CMP_ACC.POLICY_CLASS := r_BLC_REI_ACC.POLICY_CLASS;
                            r_IIB_CMP_ACC.STIPPRC :=  r_BLC_REI_ACC.SACC_CLASS;
                            
                            r_IIB_CMP_ACC.SCLI_PROVIDER := l_provider_sap; --000
                            r_IIB_CMP_ACC.SCLI_CUSTOMER := l_client_sap; --N001
                            r_IIB_CMP_ACC.SCLI_INSURED := PEOPLE_SAP_CODE(r_BLC_REI_ACC.DOC_PARTY); --cod client sap
                            
                            IF r_BLC_REI_ACC.SACC_CLASS = '2' THEN --Accountgl
                                 r_IIB_CMP_ACC.SALLOC_NMBR :=  l_salloc_nmbr;
                                 r_IIB_CMP_ACC.SGLOSA :=  'SALDOS CONCILIADOS ' || l_ANIOTRI_DATE;
                                 
                            ELSIF r_BLC_REI_ACC.SACC_CLASS = '3' THEN --AccountReceivable
                                IF r_BLC_REI_ACC.ACC_TEMP_CODE ='COM001' THEN
                                   
                                    CASE WHEN r_BLC_REI_ACC.ACCOUNT LIKE '1403%0302' THEN 
                                                       r_IIB_CMP_ACC.SALLOC_NMBR := l_salloc_nmbr;
                                                       r_IIB_CMP_ACC.SGLOSA := r_BLC_REI_ACC.DOC_TYPE || r_BLC_REI_ACC.PROFORMA_NUMBER;
                                             WHEN r_BLC_REI_ACC.ACCOUNT LIKE '1403%0201' THEN
                                                       r_IIB_CMP_ACC.SALLOC_NMBR := r_BLC_REI_ACC.CLAIM_NUMBER;
                                                       r_IIB_CMP_ACC.SGLOSA := Substr(r_IIB_CMP_ACC.SCLI_INSURED ||  '-' ||  r_BLC_REI_ACC.DOC_PARTY_NAME,1,50);
                                    END CASE;

                                ELSIF r_BLC_REI_ACC.ACC_TEMP_CODE = 'COM002' THEN

                                         IF r_BLC_REI_ACC.DOC_TYPE IS NOT NULL THEN  
                                             r_IIB_CMP_ACC.SALLOC_NMBR := r_BLC_REI_ACC.PROFORMA_NUMBER;
                                         END IF;    
                                         
                                         r_IIB_CMP_ACC.SGLOSA :=  Substr(r_IIB_CMP_ACC.SCLI_INSURED ||  '-' ||  r_BLC_REI_ACC.DOC_PARTY_NAME,1,50);
                                         
                                ELSIF r_BLC_REI_ACC.ACC_TEMP_CODE ='COM003' THEN
                                    r_IIB_CMP_ACC.SALLOC_NMBR := r_BLC_REI_ACC.CLAIM_NUMBER;
                                    
                                    r_IIB_CMP_ACC.SGLOSA := CASE WHEN r_BLC_REI_ACC.ACCOUNT LIKE '16%' THEN 'CTA.PEND.SIN CEDIDO REASEGURADORES'
                                                                                     WHEN r_BLC_REI_ACC.ACCOUNT LIKE '24%' THEN Substr(r_BLC_REI_ACC.DOC_PARTY_NAME,1,50) 
                                                                                     WHEN r_BLC_REI_ACC.ACCOUNT LIKE '14%' THEN Substr(r_BLC_REI_ACC.DOC_PARTY_NAME,1,50) 
                                                                            END;
                                  
                                END IF;
                                
                            ELSIF r_BLC_REI_ACC.SACC_CLASS = '4' THEN --AccountPayable
                                IF r_BLC_REI_ACC.ACC_TEMP_CODE ='COM001' THEN
                                    r_IIB_CMP_ACC.SALLOC_NMBR := r_BLC_REI_ACC.DOC_TYPE || r_BLC_REI_ACC.PROFORMA_NUMBER;   

                                ELSIF r_BLC_REI_ACC.ACC_TEMP_CODE ='COM002' THEN
                                        CASE WHEN r_BLC_REI_ACC.ACCOUNT LIKE '2403%0301' THEN 
                                                    r_IIB_CMP_ACC.SALLOC_NMBR := l_salloc_nmbr;
                                                    r_IIB_CMP_ACC.SGLOSA := 'GTOS. ADM. COA. REC';
                                                 WHEN r_BLC_REI_ACC.ACCOUNT LIKE '2403%0201' THEN 
                                                    r_IIB_CMP_ACC.SALLOC_NMBR := r_BLC_REI_ACC.CLAIM_NUMBER;
                                                    r_IIB_CMP_ACC.SGLOSA := Substr(r_IIB_CMP_ACC.SCLI_INSURED || ' ' ||  r_BLC_REI_ACC.DOC_PARTY_NAME,1,50);
                                        END CASE;

                                ELSIF r_BLC_REI_ACC.ACC_TEMP_CODE ='COM003' THEN      
                                    r_IIB_CMP_ACC.SALLOC_NMBR :=  r_IIB_CMP_GEN.NCOMPANY || to_char(l_DATE,'YYYYMM') ||  '-'  || l_reinsuran_type ||  '-' ||  r_IIB_CMP_GEN.NTYPECONTRACT;
                                    r_IIB_CMP_ACC.SGLOSA := CASE WHEN r_BLC_REI_ACC.ACCOUNT LIKE '16%' THEN 'CTA.PEND.PRIMAS CEDIDA REASEGURADORES'
                                                                                     WHEN r_BLC_REI_ACC.ACCOUNT LIKE '24%' THEN Substr(r_BLC_REI_ACC.DOC_PARTY_NAME,1,50)  
                                                                                     WHEN r_BLC_REI_ACC.ACCOUNT LIKE '14%' THEN Substr(r_BLC_REI_ACC.DOC_PARTY_NAME,1,50) 
                                                                             END;
                                END IF;
                            END IF;


                            DBMS_OUTPUT.PUT_LINE('<IIBPRCINSREI002>');
                            DBMS_OUTPUT.PUT_LINE('NSEQUENCE=' || r_IIB_CMP_ACC.NSEQUENCE);
                            DBMS_OUTPUT.PUT_LINE('NITEM_NUM=' || r_IIB_CMP_ACC.NITEM_NUM);
                            DBMS_OUTPUT.PUT_LINE('NBUSSIUNIT=' || l_bussunit);
                            INSIS_CUST_LPV.IIBPKGCMP.IIBPRCINSCMP002(
                            NSEQUENCE => r_IIB_CMP_ACC.NSEQUENCE,
                            NITEM_NUM => r_IIB_CMP_ACC.NITEM_NUM,
                            SACCOUNT => r_IIB_CMP_ACC.SACCOUNT,         
                            NOFFICE => r_IIB_CMP_ACC.NOFFICE,
                            NCOUNTRY => r_IIB_CMP_ACC.NCOUNTRY,
                            SIND_DEB_CRED =>  r_IIB_CMP_ACC.SIND_DEB_CRED,
                            NAMOUNT => r_IIB_CMP_ACC.NAMOUNT,
                            SPROFIT_FLAG => r_IIB_CMP_ACC.SPROFIT_FLAG,
                            SBUSINESS_UNIT => r_IIB_CMP_ACC.SBUSINESS_UNIT,
                            SALLOC_NMBR => r_IIB_CMP_ACC.SALLOC_NMBR,
                            SCLI_PROVIDER => r_IIB_CMP_ACC.SCLI_PROVIDER,
                            SCLI_CUSTOMER => r_IIB_CMP_ACC.SCLI_CUSTOMER,
                            NBRANCH => r_IIB_CMP_ACC.NBRANCH,
                            NPOLICY => r_IIB_CMP_ACC.NPOLICY, 
                            SCLI_INSURED => r_IIB_CMP_ACC.SCLI_INSURED, 
                            SCLAIM  => r_IIB_CMP_ACC.SCLAIM,
                            NRECEIPT  => r_IIB_CMP_ACC.NRECEIPT, 
                            SCURRENCY => r_IIB_CMP_ACC.SCURRENCY, 
                            POLICY_CLASS => r_IIB_CMP_ACC.POLICY_CLASS,
                            STIPPRC => r_IIB_CMP_ACC.STIPPRC,
                            SGLOSA => r_IIB_CMP_ACC.SGLOSA
                            );
                            
                            DBMS_OUTPUT.PUT_LINE('</IIBPRCINSCMP002>');

                        END IF;
                        --
                        UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                            SET
                                STATUS = 'S',
                                UPDATED_ON = SYSDATE,
                                UPDATED_BY = l_username
                        WHERE
                            ID = r_BLC_REI_ACC.ID AND
                            LINE_NUMBER = r_BLC_REI_ACC.LINE_NUMBER;                        
                        
                        
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_ERROR_MESSAGE := 'ERROR IN CMP ACC PROCESS' || ' SQLERRM=' || SQLERRM || ' SQLCODE=' || SQLCODE;
                            
                    END;
                END LOOP;
                  
                IF l_ERROR_MESSAGE IS NULL
                THEN
                    UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_ACC
                    SET
                        STATUS = 'S',
                        UPDATED_ON = SYSDATE,
                        UPDATED_BY = l_username
                    WHERE
                        ID = r_BLC_REI_ACC.ID AND STATUS = 'N';
                END IF;
                
                CLOSE c_BLC_REI_ACC;
                
                     
                IF l_ERROR_MESSAGE IS NULL THEN
                      -- INSERT JOB
                    INSIS_CUST_LPV.IIBPKGCMP.IIBPRCINSCMP003(
                                                              NSEQUENCE => r_IIB_CMP_GEN.NSEQUENCE,
                                                              SREF_DOC => r_IIB_CMP_GEN.SREF_DOC,
                                                              DCOMPDATE => SYSDATE, 
                                                              DPROCINI => NULL,
                                                              DPROCEND => NULL,
                                                              NSTATUS => 0,
                                                              SMNSJE_ERROR => NULL,
                                                              SSEQUENCE_SAP => NULL,
                                                              NPRIOR => 2,
                                                              DPASSDATE => SYSDATE,
                                                              NREINTENTOS => NULL,
                                                              NCOMPANY => r_IIB_CMP_GEN.NCOMPANY,
                                                              NSEQUENCE_TRA => r_BLC_REI_GEN.ID
                                                             );

                ELSE
                     cust_intrf_util_pkg.Blc_Process_Ip_Result_2(
                        pi_header_id => r_BLC_REI_GEN.ID,
                        pi_header_table => 'BLC_REI_GEN',
                        pi_line_number_from => l_BLC_REI_ACC_ini,
                        pi_line_number_to => l_BLC_REI_ACC_fin,
                        pi_status => 'E',
                        pi_sap_doc_number => NULL,
                        pi_error_type => 'IP_ERROR',
                        pi_error_msg => l_ERROR_MESSAGE,
                        pi_process_start => l_process_start,
                        pi_process_end => SYSDATE);
                        
                END IF;      
                
                --
                l_BLC_REI_ACC_ini := l_BLC_REI_ACC_fin + 1;
            END LOOP;
            DBMS_OUTPUT.put_line (l_ERROR_MESSAGE);
            IF l_ERROR_MESSAGE IS NULL
            THEN
                  UPDATE INSIS_BLC_GLOBAL_CUST.BLC_REI_GEN
                      SET
                          STATUS = 'S',
                          UPDATED_ON = SYSDATE,
                          UPDATED_BY = l_username
                  WHERE
                      ID = r_BLC_REI_GEN.ID; 
            END IF;  
                    
        END LOOP;

        IF
            pi_list_records IS NOT NULL
        THEN
            CLOSE c_BLC_REI_GEN_A;
        ELSE
            CLOSE c_BLC_REI_GEN_B;
        END IF;

        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN

            l_ERROR_MESSAGE := 'ERROR IN BLC_CMP_EXEC ' || ' SQLERRM=' || SQLERRM || ' SQLCODE=' || SQLCODE;

            ROLLBACK;

             cust_intrf_util_pkg.Blc_Process_Ip_Result(
                        pi_header_id => r_BLC_REI_GEN.ID,
                        pi_header_table => 'BLC_REI_GEN',
                        pi_status => 'E',
                        pi_sap_doc_number => NULL,
                        pi_error_type => 'IP_ERROR',
                        pi_error_msg => l_ERROR_MESSAGE,
                        pi_process_start => NVL(l_process_start,SYSDATE),
                        pi_process_end => SYSDATE);
            --
            COMMIT;
            RAISE_APPLICATION_ERROR(
                -20402,
                l_ERROR_MESSAGE
            );
    END BLC_CMP_EXEC;
    
END BLC_RI_PKG;
--