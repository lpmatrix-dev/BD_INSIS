CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.blc_acc_pkg AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during integration process with SAP
--------------------------------------------------------------------------------
    
    -- Provides the Business Unit Code using the given parameters.
    -- @param PRODUCT [IN] Product Code.
    -- @param SALES_CHANNEL [IN] Sales Channel Code.
    -- @return BUSINESS_UNIT The Business Unit 2-Digit Code.
    FUNCTION get_business_unit (
        product IN NUMBER,
        sales_channel IN VARCHAR2
    ) RETURN CHAR IS
        business_unit CHAR(2);
    BEGIN
        business_unit :=
            /*CASE product
                WHEN 2000 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '4' THEN '02'
                        WHEN '11' THEN '02'
                        WHEN '15' THEN '02'
                        WHEN '2' THEN '24'
                        WHEN '13' THEN '21'
                        ELSE NULL
                    END
                WHEN 2001 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '5' THEN '25'
                        WHEN '7' THEN '25'
                        ELSE NULL
                    END
                WHEN 2002 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '4' THEN '02'
                        WHEN '8' THEN '02'
                        WHEN '2' THEN '24'
                        ELSE NULL
                    END
                WHEN 2003 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '4' THEN '02'
                        WHEN '9' THEN '02'
                        WHEN '15' THEN '02'
                        WHEN '2' THEN '24'
                        ELSE NULL
                    END
                WHEN 2004 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '5' THEN '25'
                        WHEN '7' THEN '25'
                        ELSE NULL
                    END
                WHEN 2005 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '4' THEN '02'
                        WHEN '8' THEN '02'
                        WHEN '2' THEN '24'
                        ELSE NULL
                    END
                WHEN 2006 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '4' THEN '02'
                        WHEN '9' THEN '02'
                        WHEN '6' THEN '04'
                        WHEN '13' THEN '21'
                        WHEN '2' THEN '24'
                        ELSE NULL
                    END
                WHEN 2007 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '5' THEN '25'
                        WHEN '7' THEN '25'
                        ELSE NULL
                    END
                WHEN 2008 THEN
                    CASE sales_channel
                        WHEN '1' THEN '02'
                        WHEN '3' THEN '02'
                        WHEN '5' THEN '25'
                        WHEN '7' THEN '25'
                        ELSE NULL
                    END
                ELSE NULL
            END;
            */
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
                    2009,
                    2010,
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
                        WHEN '10' THEN '02'
                        WHEN '11' THEN '02'
                        WHEN '12' THEN '02'
                        WHEN '13' THEN '21'
                        WHEN '15' THEN '02'
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
        --
        RETURN(business_unit);
    END get_business_unit;
    
    --
    FUNCTION get_office_gl (
        OFFICE_ID IN blc_account_gen.office_gl_no%TYPE
    ) RETURN varchar2 AS
        OFFICE_NO number;
    BEGIN
        BEGIN
            SELECT
                gl_no
            INTO
                OFFICE_NO
            FROM
                INSIS_PEOPLE_v10.p_offices
            WHERE
                office_id = OFFICE_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                OFFICE_NO := NULL;
        END;        
        RETURN OFFICE_NO;
    END get_office_gl;
    
    FUNCTION get_department_office (
        office IN NUMBER
    ) RETURN CHAR IS
        department_office CHAR(4);
    BEGIN
        department_office :=
            CASE
                WHEN office = 1 OR office = 41 OR office = 61 THEN '0105'
                WHEN office = 2 OR office = 11 OR office = 22 OR office = 23 OR office = 25 OR office = 30 THEN '0201'
                WHEN office = 3 OR office = 46 OR office = 63 THEN '0322'
                WHEN office = 4 OR office = 45 OR office = 64 THEN '0408'
                WHEN office = 5 OR office = 65 THEN '0520'
                WHEN office = 6 OR office = 42 OR office = 66 THEN '0613'
                WHEN office = 9 THEN '0914'
                WHEN office = 12 OR office = 44 OR office = 72 THEN '1212'
                WHEN office = 13 OR office = 52 OR office = 73 THEN '1319'
                WHEN office = 14 THEN '1405'
                WHEN office = 15 OR office = 51 OR office = 74 THEN '1503'
                WHEN office = 18 OR office = 75 THEN '1811'
                WHEN office = 19 THEN '1905'
                WHEN office = 21 THEN '2117'
                WHEN office = 24 OR office = 71 THEN '2424'
                WHEN office = 26 OR office = 70 THEN '2615'
                WHEN office = 32 THEN '3201'
                WHEN office = 33 THEN '3307'
                WHEN office = 34 THEN '3401'
                WHEN office = 35 OR office = 47 THEN '3501'
                WHEN office = 36 THEN '3601'
                WHEN office = 37 THEN '3701'
                WHEN office = 39 THEN '3903'
                WHEN office = 40 THEN '4012'
                WHEN office = 43 OR office = 69 THEN '4314'
                WHEN office = 48 OR office = 50 OR office = 54 THEN '4801'
                WHEN office = 38 OR office = 49 THEN '4925'
                WHEN office = 55 THEN '5519'
                WHEN office = 56 THEN '5601'
                WHEN office = 57 THEN '5701'
                WHEN office = 58 THEN '5801'
                WHEN office = 59 THEN '5901'
                WHEN office = 60 THEN '6001'
                WHEN office = 10 OR office = 62 THEN '6201'
                WHEN office = 68 THEN '6801'
                WHEN office = 67 OR office = 76 THEN '7617'
                WHEN office = 78 THEN '7810'
                WHEN office = 79 THEN '7905'
                WHEN office = 80 THEN '8001'
                WHEN office = 81 THEN '8116'
                WHEN office = 82 THEN '8206'
                WHEN office = 83 THEN '8301'
                WHEN office = 84 THEN '8401'
                ELSE NULL
            END;
        RETURN(department_office);
    END get_department_office;
    
    --------------------------------------------------------------------------------
    -- Name: BLC_COPA_INSERT
    --
    -- Type: FUNCTION
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   27.11.2017  creation
    --
    -- Purpose:  Transfer the data from staging tables to IIB tables
    --
    -- Input parameters:
    --    pi_sequence  NUMBER,
    --   pi_item  VARCHAR2,
    --   pi_branch  VARCHAR2,
    --   pi_office  VARCHAR2,
    --    pi_sales_channel  VARCHAR2,
    --   pi_bussityp  VARCHAR2,
    --    pi_product  VARCHAR2,
    --    pi_intermedtyp  VARCHAR2,
    --
    -- Output parameters:
    --     po_bussiunit       VARCHAR2
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
    PROCEDURE blc_copa_insert (
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
        l_copa_value VARCHAR2(25);
        l_copa_type VARCHAR2(25);
        l_id_insis VARCHAR2(50);
        CURSOR sap_cla_copa IS SELECT copa_type
                               FROM insis_cust_lpv.ht_copa
                               WHERE status = 'A';
    BEGIN
        OPEN sap_cla_copa;
        LOOP
            FETCH sap_cla_copa INTO l_copa_type;
            EXIT WHEN sap_cla_copa%NOTFOUND OR sap_cla_copa%NOTFOUND IS NULL;
            l_id_insis :=
                CASE l_copa_type
                    WHEN 'WWRCN' THEN pi_branch
                    WHEN 'WWRCM' THEN pi_branch
                    WHEN 'WWTNE' THEN pi_bussityp
                    --WHEN 'WWPRO' THEN pi_product || '-' || pi_sales_channel
                    WHEN 'WWPRO' THEN pi_product
                    WHEN 'WWNES' THEN '0'
                    --WHEN 'GSBER' THEN pi_office
                    WHEN 'GSBER' THEN TO_CHAR(TO_NUMBER(pi_office))
                    WHEN 'WWCVE' THEN pi_sales_channel
                    WHEN 'WWUNE' THEN pi_bussiunit
                    WHEN 'WWTIN' THEN pi_intermedtyp
                END;
            --
            
            IF
                l_id_insis IS NOT NULL
            THEN
            /*
                SELECT hcv.id_sap
                INTO l_copa_value
                FROM insis_cust_lpv.ht_copa_values hcv
                WHERE hcv.copa_type = l_copa_type AND
                      hcv.id_insis = l_id_insis;
               */
                --
               BEGIN
                SELECT hcv.id_sap
                INTO l_copa_value
                FROM insis_cust_lpv.ht_copa_values hcv
                WHERE hcv.copa_type = l_copa_type AND
                      hcv.id_insis = l_id_insis;
                 
              EXCEPTION
                 WHEN OTHERS THEN   
                     l_copa_value := l_id_insis;
              END;
      
                insis_cust_lpv.iibpkgacc.iibprcinsacc003(
                    pi_sequence,
                    pi_item,
                    l_copa_type,
                    l_copa_value
                );
            END IF;
            l_id_insis := NULL;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR IN BLC_COPA_INSERT');
            raise_application_error(
                -20500,
                'ERROR IN BLC_COPA_INSERT. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
            );
    END blc_copa_insert;
    
    --------------------------------------------------------------------------------
    -- Name: BLC_ACCOUNT_MAP_HEADER
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   17.11.2017  creation
    --
    -- Purpose:  Mapping for the header to SAP
    --
    -- Input parameters:
    --   pio_sap_acc_gen_row BLC_ACCOUNT_GEN%ROWTYPE
    --
    -- Output parameters:
    --   po_doc_type     VARCHAR2
    --   po_text         VARCHAR2
    --   po_currency_sap NUMBER
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
    PROCEDURE blc_account_map_header (
        pi_sap_acc_gen_row IN blc_account_gen%ROWTYPE,
        po_doc_type OUT CHAR,
        po_text OUT VARCHAR2, --OK
        po_currency_sap OUT VARCHAR2,
        po_ref_doc OUT CHAR,
        po_trans_date OUT DATE,
        po_ref_key OUT VARCHAR
    ) IS
        l_temp_code pi_sap_acc_gen_row.acc_temp_code%TYPE := pi_sap_acc_gen_row.acc_temp_code;
        l_currency pi_sap_acc_gen_row.currency%TYPE := pi_sap_acc_gen_row.currency;
        l_tpo_asnto CHAR(4);
    BEGIN
        po_text := 'RCC-' || trim(
            TO_CHAR(
                pi_sap_acc_gen_row.issue_date,
                'MONTH'
            )
        ) || extract ( YEAR FROM pi_sap_acc_gen_row.issue_date ) || ',INSIS';
        dbms_output.put_line('po_text:' || po_text);
        po_doc_type :=
            CASE l_temp_code
                --WHEN 'EOM001.SAVE' THEN 'FF'
                --WHEN 'EOM002.MR' THEN 'RM'
                WHEN 'EOM003.UPR' THEN 'IT' --Solo para este Evento (Jose Caycho) 01.06.2021
                --WHEN 'EOM004.RIMR' THEN 'RM'
                --WHEN 'EOM005.RIUPR' THEN 'IT'
                --WHEN 'EOM007.IBNR' THEN 'IS'
                --WHEN 'EOM008.RIIBNR' THEN 'IS'
                --WHEN 'EOM009.DRCT' THEN 'IS'
                --WHEN 'EOM010.NDRCT' THEN 'IS'
            END;
        dbms_output.put_line('po_doc_type:' || po_doc_type);
        l_tpo_asnto :=
            CASE
                WHEN po_doc_type = 'IT' AND l_currency = 'PEN' THEN '4006'
                WHEN po_doc_type = 'IT' AND l_currency = 'USD' THEN '4007'
                WHEN po_doc_type = 'IS' AND l_currency = 'PEN' THEN '4032'
                WHEN po_doc_type = 'IS' AND l_currency = 'USD' THEN '4033'
                WHEN po_doc_type = 'RM' THEN 'XXXX' --TBD BY LPV
                WHEN po_doc_type = 'FF' THEN 'YYYY' --TBD BY LPV
            END;
        dbms_output.put_line('l_tpo_asnto:' || l_tpo_asnto);
        po_ref_doc := '5' || l_tpo_asnto;
        dbms_output.put_line('po_ref_doc:' || po_ref_doc);
        
        IF
            l_currency = 'PEN'
        THEN
            --po_currency_sap := 1; -- JCC 14.05.2021 UPR          
            po_trans_date := NULL;
        ELSE
            --po_currency_sap := 2; -- JCC 14.05.2021 UPR
            po_trans_date := trunc(pi_sap_acc_gen_row.issue_date); -- JCC 14.05.2021 UPR
        END IF;
        po_currency_sap := l_currency;   
        
        dbms_output.put_line('po_currency_sap:' || po_currency_sap);
        dbms_output.put_line('po_trans_date:' || po_trans_date);
        po_ref_key := '5' || pi_sap_acc_gen_row.legal_entity || extract ( YEAR FROM pi_sap_acc_gen_row.issue_date ) || trim(extract(MONTH FROM pi_sap_acc_gen_row.issue_date) ) || l_tpo_asnto || pi_sap_acc_gen_row.ID;
        dbms_output.put_line('po_ref_key:' || po_ref_key);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR IN BLC_ACCOUNT_MAP_HEADER');
            raise_application_error(
                -20501,
                'ERROR IN BLC_ACCOUNT_MAP_HEADER. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
            );
    END;
    
    --------------------------------------------------------------------------------
    -- Name: BLC_ACCOUNT_MAP_LINE
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   17.11.2017  creation
    --
    -- Purpose:  Mapping for the acc table to SAP
    --
    -- Input parameters:
    --     pi_sap_acc_acc_row  BLC_ACCOUNT_GEN%ROWTYPE
    --
    -- Output parameters:
    --     po_acct_type  VARCHAR2
    --    po_bussiunit  VARCHAR2
    --    po_alloc_nmbr  VARCHAR2
    --    po_profit_flag  VARCHAR2
    --    po_bussityp  VARCHAR2
    --    po_busi_class  VARCHAR2
    --     po_sintermedtyp  VARCHAR2
    --    po_copa  VARCHAR2
    --    po_profit_center  VARCHAR2
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
    PROCEDURE blc_account_map_line (
        pi_sap_acc_acc_row IN blc_account_acc%ROWTYPE,
        pi_office IN VARCHAR2,
        pi_issue_date DATE,
        po_acct_type OUT VARCHAR2,
        po_bussiunit OUT VARCHAR2,
        po_alloc_nmbr OUT VARCHAR2,
      --po_profit_flag OUT VARCHAR2,  --FALTA
        po_bussityp OUT CHAR,
      --po_busi_class OUT CHAR,
        po_sintermedtyp OUT CHAR,
        po_copa OUT CHAR,
      --po_profit_center OUT CHAR,
        po_post_key OUT CHAR,
        po_numro_refer OUT VARCHAR2,
        po_glosa OUT VARCHAR2,
        po_branch OUT VARCHAR2,
        po_amount OUT NUMBER,
        po_cr_dr_flag OUT CHAR
    ) IS
        l_profit_flag CHAR(1);
        l_acct_type CHAR(1);
        l_first INTEGER;
        l_second INTEGER;
        l_department_office VARCHAR2(10);
        l_branch_name VARCHAR2(100);
        l_account_attr pi_sap_acc_acc_row.account_attribs%TYPE := pi_sap_acc_acc_row.account_attribs;
    BEGIN
        dbms_output.put_line('BLC_ACCOUNT_MAP_LINE INI');
        po_glosa := '';
        l_profit_flag := '';
        po_bussiunit := get_business_unit(
            pi_sap_acc_acc_row.insr_type,
            pi_sap_acc_acc_row.sales_channel
        );       
        l_department_office := get_department_office(to_number(pi_office) );
        l_first := instr(
            l_account_attr,
            '-',
            1,
            1
        );
        l_second := instr(
            l_account_attr,
            '-',
            1,
            2
        );
        po_acct_type := substr(
            l_account_attr,
            1,
            1
        );
        --po_profit_center := SUBSTR(l_account_attr,l_first+1,1);
        po_copa := substr(
            l_account_attr,
            l_second + 1,
            1
        );
        po_alloc_nmbr := substr(
            pi_sap_acc_acc_row.ACCOUNT,
            1,
            8
        ) || pi_sap_acc_acc_row.tech_branch;
       /*
       CASE
            WHEN pi_sap_acc_acc_row.account LIKE '51-NC-__-01_01' THEN
                po_glosa := 'INSIS-PRIMAS CEDIDAS';
            WHEN pi_sap_acc_acc_row.account LIKE '27-03-__-01_01' OR pi_sap_acc_acc_row.account LIKE '27-01-__-00_01' OR pi_sap_acc_acc_row.account LIKE '41-NC-__-00_01' OR pi_sap_acc_acc_row.account LIKE '41-NC-__-00_07' THEN
                SELECT cpts.tb_name
                INTO l_branch_name
                FROM insis_cust.cfglpv_policy_techbranch_sbs cpts
                WHERE cpts.insr_type = pi_sap_acc_acc_row.insr_type AND
                      cpts.as_is_product = pi_sap_acc_acc_row.sales_channel
                GROUP BY cpts.tb_name;
                po_glosa := 'INSIS-' || l_branch_name;
            WHEN pi_sap_acc_acc_row.account LIKE '27-06-__-03_01' OR pi_sap_acc_acc_row.account LIKE '27-05-__-01_01' THEN
                SELECT cpts.tb_name
                INTO l_branch_name
                FROM insis_cust.cfglpv_policy_techbranch_sbs cpts
                WHERE cpts.insr_type = pi_sap_acc_acc_row.insr_type AND
                      cpts.as_is_product = pi_sap_acc_acc_row.sales_channel
                GROUP BY cpts.tb_name;
                po_glosa := 'INSIS-PRIMAS DE SEGUROS ' || l_branch_name;
            ELSE
                po_glosa := '';
        END CASE;
        */
         CASE 
         WHEN pi_sap_acc_acc_row.tech_branch = '61' THEN 
            po_glosa := 'ACC.PERS';
         WHEN pi_sap_acc_acc_row.tech_branch = '71' THEN 
            po_glosa := 'VID.LAR.PLAZ';
         WHEN pi_sap_acc_acc_row.tech_branch = '72' THEN 
            po_glosa := 'VID.GRUP.PART';
         WHEN pi_sap_acc_acc_row.tech_branch = '73' THEN 
            po_glosa := 'VID.LEY.TRAB';
         WHEN pi_sap_acc_acc_row.tech_branch = '74' THEN 
            po_glosa := 'DESG';
         WHEN pi_sap_acc_acc_row.tech_branch = '79' THEN 
            po_glosa := 'SEP.LARG.PLAZ';
         WHEN pi_sap_acc_acc_row.tech_branch = '77' THEN 
            po_glosa := 'SCTR';
         WHEN pi_sap_acc_acc_row.tech_branch = '80' THEN    
            po_glosa := 'VID.COR.PLAZ';
         WHEN pi_sap_acc_acc_row.tech_branch = '81' THEN 
            po_glosa := 'SEP.CORT.PLAZ';
         WHEN pi_sap_acc_acc_row.tech_branch = '82' THEN 
            po_glosa := 'VID.LEY.EXT-T';
         ELSE 
            po_glosa := pi_sap_acc_acc_row.tech_branch;
         END CASE;
                  
         po_glosa := 'AJUSTE RRC AL '|| TO_CHAR(pi_issue_date,'DD/MM/YYYY') || ' ' || po_glosa;         
        
        CASE
            WHEN pi_sap_acc_acc_row.ACCOUNT LIKE '5%' THEN
                l_profit_flag := 'X';
            WHEN pi_sap_acc_acc_row.ACCOUNT LIKE '46%' OR pi_sap_acc_acc_row.ACCOUNT LIKE '47%' THEN
                l_profit_flag := '';
            WHEN pi_sap_acc_acc_row.ACCOUNT LIKE '4%' THEN
                l_profit_flag := 'X';
            ELSE
                l_profit_flag := '';
        END CASE;
        IF
            l_profit_flag = 'X'
        THEN
            po_branch := pi_sap_acc_acc_row.tech_branch;
        ELSE
            po_branch := NULL;
        END IF;
        po_numro_refer := '12' || po_bussiunit || l_department_office || '0';
        IF
            pi_sap_acc_acc_row.policy_class = 'A'
        THEN
            po_bussityp := '2';
        ELSE
            po_bussityp := '1';
        END IF;
        /*EOM003.UPR 
        IF
            pi_sap_acc_acc_row.intermed_type = '0'
        THEN
            po_sintermedtyp := 'NA';
        ELSE
            po_sintermedtyp := pi_sap_acc_acc_row.intermed_type;
        END IF;
        */
        po_sintermedtyp := 'D';
        IF
            pi_sap_acc_acc_row.dr_cr_flag = 'CR'
        THEN
            po_post_key := '40';
            po_amount := pi_sap_acc_acc_row.amount *-1;
        ELSE
            po_post_key := '50';
            po_amount := pi_sap_acc_acc_row.amount;
        END IF;
        
        IF 
            pi_sap_acc_acc_row.dr_cr_flag = 'DR'
        THEN
            po_cr_dr_flag := 'S';
         ELSE
            po_cr_dr_flag := 'H';
        END IF;
    dbms_output.put_line('BLC_ACCOUNT_MAP_LINE FIN');
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR IN BLC_ACCOUNT_MAP_LINE');
            raise_application_error(
                -20502,
                'ERROR IN BLC_ACCOUNT_MAP_LINE. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
            );
    END;
    
    --------------------------------------------------------------------------------
    -- Name: BLC_ACCOUNT_INSERT
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   17.11.2017  creation
    --
    -- Purpose:  Insert the information to the stagging tables to IIB SAP
    --
    -- Input parameters:
    --     p_sap_acc_gen_row BLC_ACCOUNT_GEN%ROWTYPE
    --
    -- Output parameters:
    --     p_sap_cla_gen_row BLC_ACCOUNT_GEN%ROWTYPE
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
    PROCEDURE blc_account_insert (
        p_sap_acc_gen_row IN OUT blc_account_gen%ROWTYPE
    ) IS
        l_sap_acc_line_row blc_account_acc%ROWTYPE;
        l_doc_type CHAR(2);
        l_text VARCHAR2(25);
        --l_currency NUMBER;
        l_currency VARCHAR2(8);
        l_busstyp CHAR(1);
        l_id_gen NUMBER;
        l_num_records INTEGER;
        l_ini_records INTEGER;
        l_fin_records INTEGER;
        l_ref_doc CHAR(16);
        l_ref_key VARCHAR(50);
        l_acct_type CHAR(1);
        l_profit_center CHAR(2);
        l_copa CHAR(2);
        l_sequence NUMBER;
        l_trans_date DATE;
        l_bussiunit VARCHAR2(25);
        l_alloc_nmbr VARCHAR2(25);
        l_sintermedtyp CHAR(2);
        l_post_key CHAR(2);
        l_numro_refer VARCHAR2(10);
        l_glosa VARCHAR2(80);
        l_brach varchar2(25);
        l_amount NUMBER(18,2);
        --l_office NUMBER(5);
        l_office VARCHAR(5);
        l_dr_cr_flag CHAR(1);
        
        CURSOR sap_cla_acc_cur_list (
            c_ini_records INTEGER,
            c_fin_records INTEGER,
            c_id_gen NUMBER
        ) IS SELECT cacc.*
             FROM insis_blc_global_cust.blc_account_acc cacc
             WHERE cacc.ID = c_id_gen --AND
             --cacc.line_number > c_ini_records AND
             --cacc.line_number < c_fin_records
                   --ROWNUM > c_ini_records AND
                   --ROWNUM < c_fin_records
        ORDER BY cacc.ID,
                 cacc.line_number;
    BEGIN
        l_id_gen := p_sap_acc_gen_row.ID;
        SELECT COUNT(ID)
        INTO l_num_records
        FROM insis_blc_global_cust.blc_account_acc cacc
        WHERE cacc.ID = l_id_gen;
        --
        blc_account_map_header(
            p_sap_acc_gen_row,
            l_doc_type,
            l_text,
            l_currency,
            l_ref_doc,
            l_trans_date,
            l_ref_key
        );
        l_ini_records := 1;
        WHILE l_ini_records < l_num_records LOOP
            l_fin_records := l_ini_records + 899;
            --INSERT IN HEADER
            dbms_output.put_line('INSERT IN HEADER');
            insis_cust_lpv.iibpkgacc.iibprcinsacc001(
                l_sequence,
                5,
                '1020',                           --p_sap_acc_gen_row.LEGAL_ENTITY,-- NANO
                NULL,                           --NMES
                p_sap_acc_gen_row.issue_date,   -- DFECHA
                NULL,                           --NSUBSIDIARIO
                NULL,                           --NFLE_CNTBLE
                NULL,                           --NTOT_CRGOS
                NULL,                           --p_sap_acc_gen_row.EXCHANGE_RATE, --NTOT_ABNOS
                NULL,                           --NTOT_CRGOS_DLRES
                NULL,                           --NTOT_ABNOS_DLRES
                l_doc_type,                     --SPRCDNCIA
                l_currency,                     --STPO_ASNTO
                NULL,                           --STPO_ACTLZCION
                NULL,                           --NESTADO
                NULL,                           --NLED_COMPAN
                NULL,                           --NVOUCHER
                l_text,                         --SNMRO_ASNTO_CRE
                NULL,                           --NLINESCOUNT
                NULL,                           --NSEGMCOUNT
                NULL,                           --SCODERRORS
                p_sap_acc_gen_row.issue_date,   --DPSTNG_DATE
                l_trans_date,                   --DTRANS_DATE
                NULL,                           --DCOMPDATE
                l_ref_doc,                      --SREF_DOC_NO
                'PEN',                          --SLOC_CURRCY
                substr(
                    l_ref_key,
                    1,
                    20
                ),                              --SHD_REF_KEY_1
                p_sap_acc_gen_row.ID            --NSEQUENCE_TRA
            );
            dbms_output.put_line('FIN INSERT IN HEADER');
            dbms_output.put_line('p_sap_acc_gen_row.office_gl_no--> ' ||p_sap_acc_gen_row.office_gl_no);
            --
            BEGIN             
               SELECT OFI.OFFICE_NO INTO l_office
               FROM INSIS_PEOPLE_V10.P_OFFICES OFI
               WHERE OFI.OFFICE_ID = p_sap_acc_gen_row.OFFICE_GL_NO;
            EXCEPTION
            WHEN OTHERS THEN     
               l_office := '0';
            END;
            --
           --l_office := get_office_gl(p_sap_acc_gen_row.office_gl_no);
            OPEN sap_cla_acc_cur_list(
                l_ini_records,
                l_fin_records,
                l_id_gen
            );
            dbms_output.put_line('l_ini_records--> ' ||l_ini_records);
            dbms_output.put_line('l_fin_records--> ' ||l_fin_records);
            dbms_output.put_line('l_id_gen--> ' ||l_id_gen);
            LOOP
                FETCH sap_cla_acc_cur_list INTO l_sap_acc_line_row;
                exit WHEN sap_cla_acc_cur_list%NOTFOUND OR sap_cla_acc_cur_list%NOTFOUND IS NULL;
                dbms_output.put_line('l_sap_acc_line_row.line_number--> ' ||l_sap_acc_line_row.line_number);
                blc_account_map_line(
                    l_sap_acc_line_row,
                    l_office,
                    p_sap_acc_gen_row.issue_date,
                    l_acct_type,
                    l_bussiunit,
                    l_alloc_nmbr,
                    l_busstyp,
                    l_sintermedtyp,
                    l_copa,
                    l_post_key,
                    l_numro_refer,
                    l_glosa,
                    l_brach,
                    l_amount,
                    l_dr_cr_flag
                );
                -- INSERT THE LINE
                dbms_output.put_line('INSERT THE LINE');    
                --l_glosa := 'AJUSTE RRC AL '|| TO_CHAR(p_sap_acc_gen_row.issue_date,'DD/MM/YYYY') || ' ' || l_glosa;
                insis_cust_lpv.iibpkgacc.iibprcinsacc002(
                    l_sequence,--NSEQUENCE
                    l_sap_acc_line_row.line_number, --NITEM
                    NULL,                           --NIMPRTE
                    NULL,                           --NIMPRTE_RXPRSDO
                    NULL,                           --STPO_MVMNTO
                    l_acct_type,                    --SDSTNO_AUTMTCO
                    l_glosa,                        --SGLOSA
                    l_bussiunit,                           --SREEXPRESION
                    l_alloc_nmbr,                   --SNMRO_DCMNTO
                    l_post_key,                     --STPO_MONEDA -- POST_KEY????
                    NULL,                           --DFCHA_DCMNTO
                    NULL,                           --NTSA_CMBIO
                    NULL,                           --STPO_DCMNTO
                    l_numro_refer,                  --NULL, --SNMRO_RFRNCIA -- falta
                    --l_sap_acc_line_row.dr_cr_flag,  --STPO_RFRNCIA
                    l_dr_cr_flag,                  --STPO_RFRNCIA
                    NULL,                           --SCORRENTISTA
                    NULL,                           --NC_COMPANIA
                    l_sap_acc_line_row.ACCOUNT,     --SCUENTA
                    NULL,                           --STPO_ACTLZCION
                   --'0',                             --SBUS_AREA 
                   l_office,                       --SBUS_AREA 
                    l_amount                        --l_sap_acc_line_row.AMOUNT --NAMT_DOCCUR
                );
                IF
                    --l_copa = 'X'
                    l_copa = 'Y'
                THEN
                    dbms_output.put_line('INSERT COPA VALUES');
                    dbms_output.put_line('l_sequence--> ' || l_sequence);
                    dbms_output.put_line('l_sap_acc_line_row.line_number--> ' || l_sap_acc_line_row.line_number);
                    dbms_output.put_line('l_brach--> ' || l_brach);
                    dbms_output.put_line('l_office--> ' || l_office);
                    dbms_output.put_line('l_sap_acc_line_row.sales_channel--> ' || l_sap_acc_line_row.sales_channel);
                    dbms_output.put_line('l_busstyp--> ' || l_busstyp);
                    dbms_output.put_line('l_sap_acc_line_row.insr_type--> ' || l_sap_acc_line_row.insr_type);
                    dbms_output.put_line('l_sintermedtyp--> ' || l_sintermedtyp);
                    dbms_output.put_line('l_bussiunit--> ' || l_bussiunit);
                    blc_copa_insert(
                        l_sequence,                       --pi_sequence IN NUMBER,
                        l_sap_acc_line_row.line_number,   --pi_item IN VARCHAR2,
                        l_brach,                          --l_sap_acc_line_row.TECH_BRANCH, --pi_branch IN VARCHAR2,
                        --p_sap_acc_gen_row.office_gl_no,   --pi_office IN VARCHAR2,
                        l_office,   --pi_office IN VARCHAR2,
                        l_sap_acc_line_row.sales_channel, --pi_sales_channel IN VARCHAR2,
                        l_busstyp,                        --pi_bussityp IN VARCHAR2,
                        l_sap_acc_line_row.insr_type,     --pi_product IN VARCHAR2,
                        l_sintermedtyp,                   --l_sap_acc_line_row.INTERMED_TYPE, -- pi_intermedtyp IN VARCHAR2
                        l_bussiunit
                    );
                END IF;                                    
                         
            END LOOP;
            CLOSE sap_cla_acc_cur_list;
            l_ini_records := l_fin_records + 1;
            --INSERT JOB
            dbms_output.put_line('INSERT JOB');
            insis_cust_lpv.iibpkgacc.iibprcinsacc004(
                l_sequence, --NSEQUENCE
                2,          --p_sap_acc_gen_row.LEGAL_ENTITY, --NCOMPANY
                5,          --NSISTORIGIN
                NULL,       --SDATA1
                NULL,       --SDATA2
                NULL,       --NPRIOR
                0,          --NSTATUS
                SYSDATE,    --DPASSDATE
                NULL,       --DCOMPDATE
                NULL,       --DPROCINI
                NULL,       --DPROCEND
                NULL,       --SSEQUENCE_SAP
                NULL,       --SMSGERROR
                NULL        --RETRY
            );
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR IN BLC_ACCOUNT_INSERT');
            raise_application_error(
                -20503,
                'ERROR IN BLC_ACCOUNT_INSERT. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
            );
    END;
    
    --------------------------------------------------------------------------------
    -- Name: BLC_ACC_EXEC
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   17.11.2017  creation
    --
    -- Purpose:  Procedure that starts the claims process to send to SAP
    --
    -- Input parameters
    --     pi_le_id         NUMBER
    --     pi_table_name    VARCHAR2
    --    pi_list_records  VARCHAR2
    --
    -- Output parameters:
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
    PROCEDURE blc_acc_exec (
        pi_le_id IN NUMBER,
        pi_list_records IN VARCHAR2
    ) IS
        l_context insis_sys_v10.srvcontext;
        l_retcontext insis_sys_v10.srvcontext;
        l_srverr insis_sys_v10.srverr;
        l_srverrmsg insis_sys_v10.srverrmsg;
        l_sap_acc_gen_row blc_account_gen%ROWTYPE;
        l_begin INTEGER := 1;
        l_end INTEGER;
        l_new_list_records VARCHAR2(240);
        l_list_records VARCHAR2(240);
        l_value VARCHAR2(25);
        l_username VARCHAR2(25);
        l_id NUMBER;
        CURSOR sap_acc_gen_cur_list (
            l_id VARCHAR2
        ) IS SELECT *
             FROM insis_blc_global_cust.blc_account_gen agen
             WHERE agen.status = 'N' AND
                   agen.ID = l_id;
        CURSOR sap_acc_gen_cur IS SELECT *
                                  FROM insis_blc_global_cust.blc_account_gen agen
                                  WHERE agen.status = 'N';
    BEGIN
        insis_sys_v10.srv_context.setcontextattrchar(
            l_context,
            'USERNAME',
            'insis_gen_v10'
        );
        insis_sys_v10.srv_context.setcontextattrchar(
            l_context,
            'USER_ENT_ROLE',
            'InsisStaff'
        );
        insis_sys_v10.srv_events.sysevent(
            insis_sys_v10.srv_events_system.get_context,
            l_context,
            l_retcontext,
            l_srverr
        );
        IF
            NOT insis_sys_v10.srv_error.rqstatus(l_srverr)
        THEN
            RETURN;
        END IF;
        --insis_sys_v10.srv_context.GetContextAttrChar( l_Context, 'USERNAME', l_username);
        SELECT sys_context(
            'USERENV',
            'SESSION_USER'
        )
        INTO l_username
        FROM dual;
        BEGIN
            IF
                pi_list_records IS NOT NULL
            THEN
                l_list_records := pi_list_records;
                WHILE l_list_records IS NOT NULL LOOP
                    l_end := instrc(
                        l_list_records,
                        ','
                    );
                    IF
                        l_end = 0
                    THEN
                        l_end := length(l_list_records);
                        l_new_list_records := NULL;
                        l_value := substr(
                            l_list_records,
                            l_begin,
                            l_end
                        );
                    ELSE
                        l_new_list_records := substr(
                            l_list_records,
                            l_end + 1,
                            length(l_list_records)
                        );
                        l_value := substr(
                            l_list_records,
                            l_begin,
                            l_end - 1
                        );
                    END IF;
                    l_list_records := l_new_list_records;
                    OPEN sap_acc_gen_cur_list(l_value);
                    LOOP
                        FETCH sap_acc_gen_cur_list INTO l_sap_acc_gen_row;
                        EXIT WHEN sap_acc_gen_cur_list%NOTFOUND OR sap_acc_gen_cur_list%NOTFOUND IS NULL;
                        l_id := l_sap_acc_gen_row.ID;
                        UPDATE insis_blc_global_cust.blc_account_gen
                        SET status = 'P',
                            updated_by = l_username,
                            updated_on = SYSDATE
                        WHERE ID = l_id;
                        blc_account_insert(l_sap_acc_gen_row);
                        UPDATE insis_blc_global_cust.blc_account_gen
                        SET status = 'S',
                            updated_by = l_username,
                            updated_on = SYSDATE
                        WHERE ID = l_id;
                        COMMIT;
                    END LOOP;
                    CLOSE sap_acc_gen_cur_list;
                END LOOP;
            ELSE
                OPEN sap_acc_gen_cur;
                LOOP
                    FETCH sap_acc_gen_cur INTO l_sap_acc_gen_row;
                    EXIT WHEN sap_acc_gen_cur%NOTFOUND OR sap_acc_gen_cur%NOTFOUND IS NULL;
                    l_id := l_sap_acc_gen_row.ID;
                    UPDATE insis_blc_global_cust.blc_account_gen
                    SET status = 'P',
                        updated_by = l_username,
                        updated_on = SYSDATE
                    WHERE ID = l_id;
                    blc_account_insert(l_sap_acc_gen_row);
                    UPDATE insis_blc_global_cust.blc_account_gen
                    SET status = 'S',
                        updated_by = l_username,
                        updated_on = SYSDATE
                    WHERE ID = l_id;    
                    
                    UPDATE insis_blc_global_cust.blc_account_acc
                    SET status = 'S',
                        updated_by = l_username,
                        updated_on = SYSDATE
                    WHERE ID = l_id; 
                    
                    COMMIT;
                END LOOP;
                CLOSE sap_acc_gen_cur;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                dbms_output.put_line('ID:' || l_id);
                UPDATE insis_blc_global_cust.blc_account_gen
                SET status = 'E',
                    updated_by = l_username,
                    updated_on = SYSDATE
                WHERE ID = l_id;
                COMMIT;
                raise_application_error(
                    -20504,
                    'ERROR IN BLC_ACC_EXEC. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
                );
                RETURN;
        END;
    END;
    
    --------------------------------------------------------------------------------
    -- Name: BLC_ACC_CLO
    --
    -- Type: PROCEDURE
    --
    -- Subtype: DATA_PROCESSING
    --
    -- Status: ACTIVE
    --
    -- Versioning:
    --     CTi   17.11.2017  creation
    --
    -- Purpose:  Procedure for the answer from SAP
    --
    -- Input parameters:
    --     p_sequence      NUMBER
    --    p_procinid      DATE
    --    p_procend       DATE
    --    p_status        NUMBER
    --    p_msgerror      VARCHAR2
    --    p_sequence_sap  VARCHAR2
    --
    -- Output parameters:
    --
    -- Usage: For Integration with SAP
    --
    -- Exceptions: N/A
    --
    -- Dependences: N/A
    --
    -- Note: N/A
    --------------------------------------------------------------------------------
    PROCEDURE blc_acc_clo (
        p_sequence IN NUMBER,
        p_procinid IN DATE,
        p_procend IN DATE,
        p_status IN NUMBER,
        p_msgerror IN VARCHAR2,
        p_sequence_sap IN VARCHAR2
    ) IS
        l_status VARCHAR2(1);
        l_context insis_sys_v10.srvcontext;
        l_retcontext insis_sys_v10.srvcontext;
        l_srverr insis_sys_v10.srverr;
    BEGIN
        CASE
            p_status
            WHEN 2 THEN
                l_status := 'T';
            WHEN 3 THEN
                l_status := 'E';
            ELSE
                l_status := 'E';
        END CASE;
        UPDATE blc_account_gen
        SET process_start_date = blc_acc_clo.p_procinid,
            process_end_date = blc_acc_clo.p_procend,
            status = l_status,
            error_msg = blc_acc_clo.p_msgerror,
            sap_doc_number = blc_acc_clo.p_sequence_sap
        WHERE ID = blc_acc_clo.p_sequence;
        srv_context.setcontextattrnumber(
            l_context,
            'HEADER_ID',
            srv_context.integers_format,
            blc_acc_clo.p_sequence
        );
        srv_context.setcontextattrchar(
            l_context,
            'HEADER_TABLE',
            'BLC_ACCOUNT_GEN'
        );
        IF
            l_status = 'T'
        THEN
            srv_context.setcontextattrchar(
                l_context,
                'SAP_DOC_NUMBER',
                blc_acc_clo.p_sequence_sap
            ); -- SUBSTRING ???
        ELSE
            srv_context.setcontextattrchar(
                l_context,
                'ERROR_MSG',
                blc_acc_clo.p_msgerror
            );
            srv_context.setcontextattrchar(
                l_context,
                'ERROR_TYPE',
                'SAP_ERROR'
            );
        END IF;
        srv_context.setcontextattrchar(
            l_context,
            'STATUS',
            l_status
        );
        srv_context.setcontextattrdate(
            l_context,
            'PROCESS_START_DATE',
            srv_context.date_format,
            blc_acc_clo.p_procinid
        );
        srv_context.setcontextattrdate(
            l_context,
            'PROCESS_END_DATE',
            srv_context.date_format,
            blc_acc_clo.p_procend
        );
        srv_events.sysevent(
            'CUST_BLC_PROCESS_IP_RESULT',
            l_context,
            l_retcontext,
            l_srverr
        );
        IF
            l_srverr IS NOT NULL
        THEN
            FOR r IN l_srverr.first..l_srverr.last LOOP
                dbms_output.put_line(l_srverr(r).errfn || ' - ' || l_srverr(r).errcode || ' - ' || l_srverr(r).errmessage);
            END LOOP;
        END IF;
        IF
            NOT srv_error.rqstatus(l_srverr)
        THEN
            ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR IN BLC_ACC_CLO');
            raise_application_error(
                -20506,
                'ERROR IN BLC_ACC_CLO. SQLERRM -> ' || SQLERRM || ' SQLCODE -> ' || SQLCODE
            );
    END;

END;
/


