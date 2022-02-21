CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during integration process with SAP
--------------------------------------------------------------------------------
  
  --------------------------------------------------------------------------------
  -- Name: PEOPLE_SAP_CODE
  --
  -- Type: FUNCTION
  --
  -- Subtype: DATA_PROCESSING
  --
  -- Status: ACTIVE
  
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
  FUNCTION PEOPLE_SAP_CODE(
      MAN_ID NUMBER
  )
    RETURN VARCHAR
  IS
    SAP_CODE VARCHAR(10);
    S_LEGACY_ID INSIS_CUST.INTRF_LPV_PEOPLE_IDS.LEGACY_ID%TYPE;
    S_SAP_CODE_PERSON INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_CODE_PERSON%TYPE;
    S_SAP_CODE_LEGAL INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_CODE_LEGAL%TYPE;
    S_INSUNIX_CODE INSIS_CUST.INTRF_LPV_PEOPLE_IDS.INSUNIX_CODE%TYPE;
  BEGIN
    insis_cust_lpv.INSPKGCLI.GET_PEOPLE_CODES(MAN_ID,NULL,NULL,S_LEGACY_ID,S_SAP_CODE_PERSON,S_SAP_CODE_LEGAL,S_INSUNIX_CODE);
    IF S_SAP_CODE_PERSON IS NOT NULL THEN
      SAP_CODE           := S_SAP_CODE_PERSON;
    ELSE
      SAP_CODE := S_SAP_CODE_LEGAL;
    END IF;
    RETURN SAP_CODE;
  EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR IN GET SAP CODE');
    RETURN NULL;
  END PEOPLE_SAP_CODE;
  */
  --------------------------------------------------------------------------------
  FUNCTION PEOPLE_SAP_CODE (
    MAN_ID NUMBER
  ) RETURN VARCHAR IS
    l_SAP_CODE VARCHAR2(10);
    l_MAN_COMP INSIS_PEOPLE_V10.P_PEOPLE.MAN_COMP%TYPE;
    r_LPV_PEOPLE INSIS_CUST.INTRF_LPV_PEOPLE_IDS%ROWTYPE;
  BEGIN
    IF MAN_ID IS NULL  THEN
        RAISE_APPLICATION_ERROR(
        -20000,
        'Provided MAN_ID is null!'
      );
    ELSE
        BEGIN
            SELECT MAN_COMP
            INTO    l_MAN_COMP
            FROM  INSIS_PEOPLE_V10.P_PEOPLE
            WHERE  MAN_ID = PEOPLE_SAP_CODE.MAN_ID;
      
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                -20000,
                'No MAN_COMP found in P_PEOPLE for MAN_ID=' || PEOPLE_SAP_CODE.MAN_ID
            );
        END;
      --
        BEGIN
            SELECT  *
            INTO  r_LPV_PEOPLE
            FROM  INSIS_CUST.INTRF_LPV_PEOPLE_IDS
            WHERE MAN_ID = PEOPLE_SAP_CODE.MAN_ID;
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
    IF  l_SAP_CODE IS NULL THEN
        RAISE_APPLICATION_ERROR(
        -20000,
        'No SAP_CODE found in INTRF_LPV_PEOPLE_IDS using MAN_ID=' || PEOPLE_SAP_CODE.MAN_ID
      );
    END IF;
    
    RETURN l_SAP_CODE;
  END PEOPLE_SAP_CODE;
  
  FUNCTION PROVIDER_SAP_CODE (
    MAN_ID NUMBER
  ) RETURN VARCHAR IS
    l_SAP_PROVIDER_ID INSIS_CUST.INTRF_LPV_PEOPLE_IDS.SAP_PROVIDER_ID%TYPE := NULL;
  
  BEGIN
    IF  MAN_ID IS NULL  THEN
        RAISE_APPLICATION_ERROR(
        -20000,
        'Provided MAN_ID is null!'
      );
    ELSE
        BEGIN
            SELECT  SAP_PROVIDER_ID
            INTO      l_SAP_PROVIDER_ID
            FROM     INSIS_CUST.INTRF_LPV_PEOPLE_IDS
            WHERE   MAN_ID = PROVIDER_SAP_CODE.MAN_ID;
      
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                -20000,
                'No record found in INTRF_LPV_PEOPLE_IDS for MAN_ID=' || PROVIDER_SAP_CODE.MAN_ID
            );
        END;
      --
    END IF;
    --
    IF  l_SAP_PROVIDER_ID IS NULL  THEN
        RAISE_APPLICATION_ERROR(
        -20000,
        'No SAP_PROVIDER found in INTRF_LPV_PEOPLE_IDS using MAN_ID=' || PROVIDER_SAP_CODE.MAN_ID
      );
    END IF;
    
    RETURN l_SAP_PROVIDER_ID;
  END PROVIDER_SAP_CODE;

  --------------------------------------------------------------------------------
  --    * Provides the Business Unit Code using the given parameters.
  --    * @param PRODUCT [IN] Product Code.
  --    * @param SALES_CHANNEL [IN] Sales Channel Code.
  --    * @return BUSINESS_UNIT The Business Unit 2-Digit Code.
  --------------------------------------------------------------------------------
  FUNCTION get_BUSINESS_UNIT (
    PRODUCT IN NUMBER,
    SALES_CHANNEL IN VARCHAR2
  ) RETURN CHAR IS
    BUSINESS_UNIT CHAR(2);
    
  BEGIN
    BUSINESS_UNIT :=
      CASE
        WHEN PRODUCT IN (2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2011,2012,2013,2014,2015) THEN
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
  --     CTi   17.11.2017  creation
  --
  -- Purpose:  Obtain the SAP_CODE with the MAN_ID
  --
  -- Input parameters:
  --    pi_sequence NUMBER,
  --    pi_item VARCHAR2,
  --    pi_branch ,
  --    pi_office ,
  --    pi_bunit ,
  --    pi_policy,
  --    pi_sales_channel,
  --    pi_client
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
  PROCEDURE BLC_COPA_INSERT(
    pi_sequence      IN NUMBER,
    pi_item          IN VARCHAR2,
    pi_branch        IN VARCHAR2,
    pi_office        IN VARCHAR2,
    pi_bunit         IN VARCHAR2,
    pi_policy        IN VARCHAR2,
    pi_sales_channel IN VARCHAR2,
    pi_client        IN VARCHAR2,
    pi_product       IN VARCHAR2,
    pi_bussityp      IN VARCHAR2,
    pi_intermedtyp   IN VARCHAR2)
  IS
    l_copa_value     VARCHAR2(25);
    l_copa_type      VARCHAR2(25);
    l_insr_type      NUMBER(4,0);
    l_cond_dimension VARCHAR2(4);
    l_id_insis       VARCHAR2(50);
    l_client_group   VARCHAR2(20);
    l_quest          VARCHAR2(20);
    CURSOR sap_cla_copa IS
      SELECT COPA_TYPE FROM INSIS_CUST_LPV.HT_COPA WHERE STATUS = 'A';
  BEGIN
    OPEN sap_cla_copa;
    LOOP
      FETCH sap_cla_copa INTO l_copa_type;
      EXIT WHEN sap_cla_copa%NOTFOUND OR sap_cla_copa%NOTFOUND IS NULL;
      CASE l_copa_type
        WHEN 'WWRCN' THEN
          l_id_insis := pi_branch;
        WHEN 'WWRCM' THEN
          l_id_insis := pi_branch;
        WHEN 'WWTNE' THEN
          l_id_insis:=pi_bussityp;
        WHEN 'WWPRO' THEN
          l_id_insis:= pi_product;
        WHEN 'WWNES' THEN
          l_id_insis := '0';
        WHEN 'GSBER' THEN
          l_id_insis := pi_office;
        WHEN 'WWCVE' THEN
          l_id_insis := pi_sales_channel;
        WHEN 'WWUNE' THEN
          l_id_insis := pi_bunit;
        WHEN 'WWTIN' THEN
          l_id_insis:=pi_intermedtyp;
      END CASE;
      IF l_id_insis IS NOT NULL THEN
        BEGIN
          IF l_copa_type = 'WWCVE' OR l_copa_type = 'WWTIN' THEN
            SELECT hcv.ID_SAP
            INTO l_copa_value
            FROM INSIS_CUST_LPV.HT_COPA_VALUES hcv
            WHERE hcv.COPA_TYPE = l_copa_type
            AND hcv.ID_INSIS    = l_id_insis;
          ELSE
            l_copa_value:=l_id_insis;
          END IF;
          
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20010,'ERROR BLC_COPA_INSERT. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
        END;
        
        INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI003(
          NSEQUENCE   => pi_sequence,
          SITEM       => pi_item,
          SFIELD      => l_copa_type,
          SVALUE      => l_copa_value,
          DCOMPDATE   => SYSDATE
        );
      END IF;
      l_id_insis := NULL;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR BLC_COPA_INSERT');
      RAISE_APPLICATION_ERROR(-20000,'ERROR BLC_COPA_INSERT. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
  END BLC_COPA_INSERT;
  
  --------------------------------------------------------------------------------
  -- Name: BLC_CLAIM_MAP_HEADER
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
  --    pi_sap_code         VARCHAR2
  --    pio_sap_cla_gen_row BLC_CLAIM_GEN%ROWTYPE
  --
  -- Output parameters:
  --    po_client       VARCHAR2
  --    po_doc_type     VARCHAR2
  --    po_text         VARCHAR2
  --    po_leader       VARCHAR2
  --    po_blockade     VARCHAR2
  --    po_busstyp      VARCHAR2
  --    po_currency_sap NUMBER
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
  PROCEDURE BLC_CLAIM_MAP_HEADER(
  --pi_sap_code IN VARCHAR2,
    pio_sap_cla_gen_row IN OUT BLC_CLAIM_GEN%ROWTYPE,
    pi_drcr IN VARCHAR2,
  --po_client OUT VARCHAR2,
    po_doc_type OUT VARCHAR2,
    po_text OUT VARCHAR2,
  --po_leader OUT VARCHAR2,
    po_blockade OUT VARCHAR2,
    po_busstyp OUT VARCHAR2,
    po_currency_sap OUT NUMBER,
    po_leader_man_id OUT VARCHAR2)
  IS
    l_header_class      pio_sap_cla_gen_row.HEADER_CLASS%TYPE        := pio_sap_cla_gen_row.HEADER_CLASS;
    l_action                  pio_sap_cla_gen_row.ACTION_TYPE%TYPE             := pio_sap_cla_gen_row.ACTION_TYPE;
    l_payway               pio_sap_cla_gen_row.PAY_WAY%TYPE                     := pio_sap_cla_gen_row.PAY_WAY;
    l_facultative           pio_sap_cla_gen_row.RI_FAC_FLAG%TYPE              := pio_sap_cla_gen_row.RI_FAC_FLAG;
    l_policy_class       pio_sap_cla_gen_row.POLICY_CLASS%TYPE            := pio_sap_cla_gen_row.POLICY_CLASS;
    l_currency             pio_sap_cla_gen_row.CURRENCY%TYPE                  := pio_sap_cla_gen_row.CURRENCY;
    l_doc_type            pio_sap_cla_gen_row.DOC_TYPE%TYPE                    := pio_sap_cla_gen_row.DOC_TYPE;
  BEGIN  
  --COISURANCE LEADER
      BEGIN
            SELECT P.man_id
            INTO po_leader_man_id
            FROM insis_gen_v10.policy_participants P
            INNER JOIN insis_gen_v10.claim c ON (P.policy_id = c.policy_id)
            WHERE c.claim_id = substr(pio_sap_cla_gen_row.claim_no,1,11)
            AND particpant_role = 'FCOINS'
            AND annex_id = 0;
      EXCEPTION
      WHEN others THEN
            po_leader_man_id := NULL;
      END;  
      
    IF l_action            = 'APE' THEN
      IF l_header_class    = 'D' THEN
        po_busstyp        := '1';
        po_doc_type       :='TA';
        po_text           := 'APERTURA DE SINIESTROS';
      ELSIF l_header_class = 'C' THEN
        po_busstyp        := '1';
        po_doc_type       :='C3';
        po_text           := 'APERT.SINI.COAS.CEDIDO';
      ELSIF l_header_class = 'A' THEN
        IF l_policy_class  = 'DCR' THEN
          po_busstyp      := '1';
          IF l_facultative = 'Y' THEN
            po_doc_type   :='Q1';
            po_text       := 'APER SNT COAREC R.CF';
          ELSE
            po_doc_type :='Q6';
            po_text     := 'APER SNT COAREC R.CA';
          END IF;
        ELSE
          po_busstyp    := '2';
          po_doc_type   := 'C7';
          po_text       := 'APERT.SINI.COAS.RECIBIDO';
          IF l_payway    = 'T' THEN
            po_blockade := 'A';
          END IF;
        END IF;
      ELSIF l_header_class = 'R' THEN
        po_busstyp        := '1';
        IF l_facultative   = 'Y' THEN
          po_doc_type     :='R1';
          po_text         := 'APER SNTR DIR REA CF';
        ELSE
          po_doc_type :='R6';
          po_text     := 'APER SNTR DIR REA CA';
        END IF;
      END IF;
    ELSIF l_action         = 'AJU' THEN
      IF l_header_class = 'D' THEN
        po_busstyp     := '1';
        po_doc_type    :='TJ';
        IF pi_drcr      = 'CR' THEN
          po_text      := 'AJUSTE SINIESTRO NEGATIVO';
        ELSIF pi_drcr   = 'DR' THEN
          po_text      := 'AJUSTE SINIESTRO POSITIVO';
        ELSE
          po_text := 'AJUSTE SINIESTRO';
        END IF;
      ELSIF l_header_class = 'C' THEN
        po_busstyp        := '1';
        po_doc_type       :='C4';
        po_text           := 'AJUS.SINI.COAS.CEDIDO';
      ELSIF l_header_class = 'R' THEN
        po_busstyp        := '1';
        IF l_facultative   = 'Y' THEN
          po_doc_type     :='R2';
          po_text         := 'AJUS SNTR DIR REA CF';
        ELSE
          po_doc_type :='R7';
          po_text     := 'AJUS SNTR DIR REA CA';
        END IF;
      ELSIF l_header_class = 'A' THEN
        IF l_policy_class  = 'DCR' THEN
          po_busstyp      := '1';
          IF l_facultative = 'Y' THEN
            po_doc_type   :='Q2';
            po_text       := 'AJUS SNT COAREC R.CF';
          ELSE
            po_doc_type :='Q7';
            po_text     := 'AJUS SNT COAREC R.CA';
          END IF;
        ELSE
          po_busstyp    := '2';
          po_doc_type   := 'C8';
          po_text       := 'AJUS.SINI.COAS.RECIBIDO';
          IF l_payway    = 'T' THEN
            po_blockade := 'A';
          END IF;
        END IF;
      END IF;
    --ELSIF l_action         = 'PSC' THEN
    ELSIF l_action         IN ('PSC', 'PCC') THEN -- IP CLA006
      IF l_header_class    = 'D' THEN
        po_busstyp        := '1';
        IF l_action = 'PSC' THEN
            po_doc_type       := 'TL';
            po_text           := 'LIQUIDACIÓN SINIESTROS';        
        ELSIF l_action = 'PCC' THEN
            --po_doc_type       := pio_sap_cla_gen_row.INV_DOC_TYPE; --Defect 520 comment
            po_doc_type       := lpad(pio_sap_cla_gen_row.INV_DOC_TYPE,2,'0'); --Defect 520
            po_text           := NULL;                
        END IF;
      ELSIF l_header_class = 'C' THEN
        po_busstyp        := '4';
        po_doc_type       :='C5';
        po_text           := 'PAGO SINI.COAS.CEDIDO';
      ELSIF l_header_class = 'R' THEN
        po_busstyp        := '5';
        IF l_facultative   = 'Y' THEN
          po_doc_type     :='R4';
          po_text         := 'PAGO SNTR DIR REA CF';
        ELSE
          po_doc_type :='R9';
          po_text     := 'PAGO SNTR DIR REA CA';
        END IF;
     
      ELSIF l_header_class = 'A' THEN
      -- Pago siniestro cosaseguro recibido C0 y C9   
            IF PIO_SAP_CLA_GEN_ROW.BENEF_PARTY = po_leader_man_id THEN
                  po_doc_type       := 'C9';
            ELSE 
                  po_doc_type       := 'C0';
            END IF;
        po_busstyp        := '2';
        PO_TEXT           := 'PAGO SINI.COAS.RECIBIDO';
        IF l_payway        <> 'C' OR  l_payway        IS NULL THEN
          po_blockade     := 'A';
        END IF;
      END IF;
    ELSIF l_action         = 'ANU' THEN
      IF l_header_class = 'A' THEN
        po_busstyp     := '2';
        po_doc_type    :='C0';
        po_text        := 'PAGO SINI.COAS.RECIBIDO';
        IF l_payway     = 'T' THEN
          po_blockade  := 'A';
        END IF;
      END IF;
    ELSIF l_action         = 'CF1' THEN 
      IF l_header_class = 'R' THEN
        IF l_facultative = 'Y' THEN
          po_doc_type    :='R4';
          po_text     := 'PAGO SNTR DIR REA CF';
        ELSIF l_facultative = 'N' THEN
          po_doc_type    :='R9';
          po_text     := 'PAGO SNTR DIR REA CA';
        END IF;
      END IF;
      /*
      Begin: Defect 524 add action_type: 'AAA'
      */      
      ELSIF l_action         = 'AAA' THEN 
      IF l_header_class = 'R' THEN
        IF l_facultative = 'Y' THEN
          po_doc_type    :='R4';
          po_text     := 'PAGO SNTR DIR REA CF';
        ELSIF l_facultative = 'N' THEN
          po_doc_type    :='R9';
          po_text     := 'PAGO SNTR DIR REA CA';
        END IF;
      END IF;
      --End Defect 524
    ELSIF l_action         = 'LQP' OR l_action = 'LQS' THEN
      IF l_doc_type = 'MATURITY' THEN
          po_text     := 'DOTE';
          po_doc_type  := 'MT';
          po_busstyp        := '1';
      ELSIF l_doc_type = 'SURRENDER' THEN
          po_text     := 'RESCATE'; 
          po_doc_type  := 'RT';
          po_busstyp        := '1';
      ELSIF l_doc_type = 'PARTSRNDR' THEN
          po_text     := 'RETIRO PARCIAL';
          po_doc_type  := 'RP';
          po_busstyp        := '1';       
      ELSIF l_doc_type = 'PAIDUP' THEN
          po_text     := 'SALDAMIENTO';
          po_doc_type  := 'SM';  
          po_busstyp   := '1';           
      --22.07.2021 Liquidacion de Siniestros con Prestamo
      ELSIF l_doc_type = 'CLAIM' THEN
          po_text     := 'LIQUIDACIÓN SINIESTROS';
          po_doc_type  := 'TL';  
          po_busstyp   := '1';                    
      END IF; 
    END IF;
    IF l_currency     = 'PEN' THEN
      po_currency_sap:= 1;
    ELSIF l_currency  = 'USD' THEN
      po_currency_sap:= 2;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR IN BLC_CLAIM_MAP_HEADER');
      RAISE_APPLICATION_ERROR(-20001,'ERROR IN BLC_CLAIM_MAP_HEADER. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
  END;
  
  --------------------------------------------------------------------------------
  -- Name: BLC_CLAIM_MAP_ACC
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
  --     pi_sap_cla_gen_row  BLC_CLAIM_GEN%ROWTYPE
  --     pio_sap_cla_acc_row BLC_CLAIM_ACC%ROWTYPE
  --
  -- Output parameters:
  --     po_stipprc       VARCHAR2
  --     po_profit_center VARCHAR2
  --     po_copa          VARCHAR2
  --     po_currency_sap  NUMBER
  --     po_text          VARCHAR2
  --     po_amount        NUMBER
  --     po_amount_base   VARCHAR2
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
  PROCEDURE BLC_CLAIM_MAP_ACC(
    pi_sap_cla_gen_row  IN BLC_CLAIM_GEN%ROWTYPE,
    pio_sap_cla_acc_row IN OUT BLC_CLAIM_ACC%ROWTYPE,
    po_stipprc OUT VARCHAR2,
    po_profit_center OUT VARCHAR2,
    po_copa OUT VARCHAR2,
    po_currency_sap OUT NUMBER,
    po_text OUT VARCHAR2,
    po_amount OUT NUMBER,
    po_amount_base OUT VARCHAR2,
    po_payway OUT VARCHAR2,
    po_ri_contract_type OUT NUMBER )
  IS
    l_acc_class VARCHAR2(1);
    l_account   VARCHAR2(25);
    l_first     INTEGER;
    l_second    INTEGER;
    l_header_class pi_sap_cla_gen_row.HEADER_CLASS%TYPE        := PI_SAP_CLA_GEN_ROW.HEADER_CLASS;
    l_action pi_sap_cla_gen_row.ACTION_TYPE%TYPE                        := PI_SAP_CLA_GEN_ROW.ACTION_TYPE;
    l_facultative pi_sap_cla_gen_row.RI_FAC_FLAG%TYPE                  := PI_SAP_CLA_GEN_ROW.RI_FAC_FLAG;
    l_policy_class pi_sap_cla_gen_row.POLICY_CLASS%TYPE           := PI_SAP_CLA_GEN_ROW.POLICY_CLASS;
    l_amount pio_sap_cla_acc_row.AMOUNT%TYPE                            := PIO_SAP_CLA_ACC_ROW.AMOUNT;
    l_account_attr pio_sap_cla_acc_row.ACCOUNT_ATTRIBS%TYPE := PIO_SAP_CLA_ACC_ROW.ACCOUNT_ATTRIBS;
  BEGIN
    IF l_policy_class   = 'DR' OR l_policy_class = 'DCR' THEN
      IF l_header_class = 'C' THEN
        po_amount_base := '%';
      END IF;
    ELSE
      IF l_header_class = 'A' OR l_header_class = 'C' THEN --coaseguro recibido,  coaseguro cedido
        po_amount_base := '%';
      END IF;
    END IF;
    l_first                            := INSTR(l_account_attr, '-',1,1);
    l_second                           := INSTR(l_account_attr, '-',1,2);
    l_acc_class                        := SUBSTR(l_account_attr,1,1);
    po_profit_center                   := SUBSTR(l_account_attr,l_first +1,1);
    po_copa                            := SUBSTR(l_account_attr,l_second+1, 1);
    po_text                            := PI_SAP_CLA_GEN_ROW.BENEF_PARTY_NAME;
    /*
    IF pi_sap_cla_gen_row.IP_CODE       = 'I009' THEN
      IF pio_sap_cla_acc_row.DR_CR_FLAG = 'CR' THEN
        po_amount                      := pi_sap_cla_gen_row.PAY_AMOUNT * -1;
      ELSE
        po_amount := pi_sap_cla_gen_row.PAY_AMOUNT;
      END IF;
    ELSE
    */
    IF pio_sap_cla_acc_row.DR_CR_FLAG = 'CR' THEN
      po_amount                      := pio_sap_cla_acc_row.AMOUNT * -1;
    ELSE
      po_amount := pio_sap_cla_acc_row.AMOUNT;
    END IF;
    /*END IF;*/
    IF pio_sap_cla_acc_row.CURRENCY    = 'PEN' THEN
      po_currency_sap                 := 1;
    ELSIF pio_sap_cla_acc_row.CURRENCY = 'USD' THEN
      po_currency_sap                 := 2;
    END IF;
    CASE l_acc_class
      WHEN 'S' THEN
        po_stipprc := '4';
      WHEN 'D' THEN
        po_stipprc := '3';
      WHEN 'K' THEN
        po_stipprc := '2';
      ELSE
        po_stipprc := '0';
      END CASE;
    CASE pi_sap_cla_gen_row.PAY_WAY
      WHEN 'CHECK' THEN
        po_payway := 'C';
      WHEN 'BANK' THEN
        po_payway := 'T';
      WHEN 'CHECK_DNI' THEN
        po_payway := 'O';
      ELSE
        po_payway := '';
    END CASE;
    CASE pi_sap_cla_gen_row.RI_CONTRACT_TYPE
      WHEN 'PR' THEN
        po_ri_contract_type := 1;
      WHEN 'NPR' THEN
        po_ri_contract_type := 2;
      ELSE
        po_ri_contract_type := 0;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR IN BLC_CLAIM_MAP_ACC');
      RAISE_APPLICATION_ERROR(-20002,'ERROR IN BLC_CLAIM_MAP_ACC. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
  END;
  
  --------------------------------------------------------------------------------
  -- Name: BLC_CLAIM_INSERT
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
  --     p_username VARCHAR2
  --
  -- Output parameters:
  --     p_sap_cla_gen_row BLC_CLAIM_GEN%ROWTYPE
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
  PROCEDURE BLC_CLAIM_INSERT(
    P_SAP_CLA_GEN_ROW IN OUT BLC_CLAIM_GEN%ROWTYPE
  ) IS
    l_sap_cla_acc_row       BLC_CLAIM_ACC%ROWTYPE;
    l_sap_cla_gen_row       BLC_CLAIM_GEN%ROWTYPE;
    l_transaccion           NUMBER;
    l_doc_type              VARCHAR2(2);
    l_text                  VARCHAR2(400);
    --l_client VARCHAR2(30);
    l_leader_sap            VARCHAR2(10);
    l_leader_sapclicod      VARCHAR2(10);
    l_leader_sapprvcod      VARCHAR2(10);
    l_sap_code              VARCHAR2(30);
    l_blockade              VARCHAR2(1);
    l_benef_sapcode         VARCHAR2(30);
    l_provider_sapcode      VARCHAR2(30);
    l_client_sapcode        VARCHAR2(30);
    l_currency_header       NUMBER;
    l_currency_acc          NUMBER;
    l_busstyp               VARCHAR2(1);
    l_payway                VARCHAR2(1);
    l_id_gen                NUMBER;
    l_contact_type          NUMBER;
    l_num_records           INTEGER;
    l_ini_records           INTEGER;
    l_fin_records           INTEGER;
    l_ipcode                VARCHAR2(25);
    l_stipprc               VARCHAR2(2);
    l_profit_center         VARCHAR2(2);
    l_copa                  VARCHAR2(2);
    l_copa_value            VARCHAR2(50);
    l_copa_description      VARCHAR2(500);
    l_amount                NUMBER(18,4);
    l_amount_acc            NUMBER(18,4);
    l_amount_base           VARCHAR2(1);
    l_nullcode              VARCHAR2(2);
    l_drcr                  VARCHAR2(10);
    l_sequence              NUMBER;
    l_sref_doc              VARCHAR2(25);    
    l_egn                   VARCHAR2(50);    --IP CLA006
    l_tax_code              VARCHAR2(2);     --IP CLA006
    l_amountbase            NUMBER(18,6);    --IP CLA006
    l_cliename              VARCHAR2(140);   --IP CLA006
    error_desc              VARCHAR2(255);
    error_code              VARCHAR2(6);
    l_holder                NUMBER;
    l_benef_lqp          NUMBER;
    l_holder_sapcode        VARCHAR2(30);            
    l_ledgerdat        BLC_CLAIM_GEN.ISSUE_DATE%TYPE; 
    l_changdate        BLC_CLAIM_GEN.ISSUE_DATE%TYPE; 
    l_claim_no         BLC_CLAIM_GEN.CLAIM_NO%TYPE;
    l_account_dote          VARCHAR2(10);
    l_coinsrepnum           VARCHAR2(10);
    l_coinsrepdate          BLC_CLAIM_GEN.ISSUE_DATE%TYPE;
    l_leader_man_id         BLC_CLAIM_GEN.INSURER_PARTY%TYPE; 
    
    l_doc_sap                 VARCHAR2(20); --Defect 520
    l_item_num        BLC_CLAIM_ACC.LINE_NUMBER%TYPE; --Defect 520
    l_currency_coa NUMBER(2);  --Defect 520
    l_vat_amount NUMBER(18,6);  --Defect 520
    
    
    CURSOR SAP_CLA_ACC_CUR_LIST(c_ini_records INTEGER,c_fin_records INTEGER,c_id_gen NUMBER) IS
        SELECT *
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_ACC CACC
        WHERE CACC.ID = C_ID_GEN
        AND CACC.LINE_NUMBER BETWEEN c_ini_records AND c_fin_records
        ORDER BY ID,LINE_NUMBER;
    CURSOR SAP_CLA_ANU_AMOUNT (c_claim_no VARCHAR2, c_ip_code VARCHAR2) IS
        SELECT GEN.*
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN GEN,
             INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_ACC CACC
        WHERE GEN.CLAIM_NO = c_claim_no
        AND GEN.IP_CODE = c_ip_code
        --AND GEN.ACTION_TYPE = 'PSC'
        AND GEN.ACTION_TYPE IN ('PSC', 'PCC') -- IP CLA006
        AND GEN.ID = CACC.ID
        AND CACC.AMOUNT > 0
        AND ROWNUM = 1;
  
    BEGIN
        l_id_gen := P_SAP_CLA_GEN_ROW.ID;
        
        SELECT COUNT(BLCGEN.CLAIM_NO) + 1
        INTO l_transaccion
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN BLCGEN
        WHERE BLCGEN.CLAIM_NO   = P_SAP_CLA_GEN_ROW.CLAIM_NO;
        
        SELECT SUM(CACC.AMOUNT)
        INTO l_amount_acc
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_ACC CACC
        WHERE CACC.ID   = l_id_gen
        ORDER BY ID DESC;
        
        BEGIN
            SELECT BLC_ACC.DR_CR_FLAG
            INTO l_drcr
            FROM BLC_CLAIM_ACC BLC_ACC
            WHERE BLC_ACC.ACCOUNT LIKE '42____0001'
            AND BLC_ACC.ID   = l_id_gen
            AND ROWNUM = 1;     
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  l_drcr   := '';
        END;
        
        BEGIN
            SELECT MAN_ID
            INTO l_holder
            FROM INSIS_GEN_V10.POLICY_PARTICIPANTS
            WHERE POLICY_ID = (
                  SELECT POLICY_ID
                  FROM INSIS_GEN_V10.POLICY
                  WHERE POLICY_NO   = P_SAP_CLA_GEN_ROW.POLICY_NO)
            AND PARTICPANT_ROLE   = 'PHOLDER'
            AND ANNEX_ID          = 0;
        EXCEPTION
            WHEN OTHERS THEN
                  l_holder   := NULL;
        END;
    
    IF P_SAP_CLA_GEN_ROW.BENEF_PARTY IS NOT NULL THEN
        l_sap_code              := PEOPLE_SAP_CODE(P_SAP_CLA_GEN_ROW.BENEF_PARTY);
        IF P_SAP_CLA_GEN_ROW.ACTION_TYPE = 'APE' OR P_SAP_CLA_GEN_ROW.ACTION_TYPE = 'AJU' THEN
            l_provider_sapcode  := l_sap_code;
        ELSIF P_SAP_CLA_GEN_ROW.ACTION_TYPE = 'PSC' THEN
            l_benef_sapcode     := l_sap_code;
        ELSIF P_SAP_CLA_GEN_ROW.ACTION_TYPE = 'PCC' THEN   -- IP CLA006
            --l_provider_sapcode  := l_sap_code; --Defect 520 comment
            l_provider_sapcode  := PROVIDER_SAP_CODE(P_SAP_CLA_GEN_ROW.BENEF_PARTY); --Defect 520
        ELSIF P_SAP_CLA_GEN_ROW.ACTION_TYPE IN ('LQP','LQS') THEN
            l_holder_sapcode    := PEOPLE_SAP_CODE(l_holder);
        END IF;
        l_client_sapcode    := l_sap_code;
    END IF;
    
    IF P_SAP_CLA_GEN_ROW.ACTION_TYPE != 'ANU' OR (P_SAP_CLA_GEN_ROW.IP_CODE = 'I008' AND l_amount_acc < 0) THEN --p_sap_cla_gen_row.PAY_AMOUNT < 0)  THEN    
        SELECT COUNT(ID)
        INTO l_num_records
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_ACC CACC
        WHERE CACC.ID                       = l_id_gen;
      
--        IF p_sap_cla_gen_row.INSURER_PARTY IS NOT NULL THEN
--            l_leader_sapclicod    := PEOPLE_SAP_CODE(p_sap_cla_gen_row.INSURER_PARTY);
--            l_leader_sapprvcod    := PROVIDER_SAP_CODE(p_sap_cla_gen_row.INSURER_PARTY);
--        END IF;
      
        BLC_CLAIM_MAP_HEADER(
            pio_sap_cla_gen_row   => p_sap_cla_gen_row,
            pi_drcr               => l_drcr,
            po_doc_type           => l_doc_type,
            po_text               => l_text,
            po_blockade           => l_blockade,
            po_busstyp            => l_busstyp,
            po_currency_sap       => l_currency_header,
            po_leader_man_id      => l_leader_man_id
            
        );
        l_ini_records       := 1;
     
        WHILE l_ini_records <= l_num_records
        LOOP
            l_fin_records                    := l_ini_records + 899;
            
            IF P_SAP_CLA_GEN_ROW.HEADER_CLASS = 'R' THEN
            --Reaseguros de Siniestros AP056           
                INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI001(
                    NSEQUENCE       => l_sequence,
                    NCOMPANY        => 2,
                    NSISTORIGIN     => 5,
                    NVOUCHER        => NULL,
                    NPRIOR          => NULL,
                    SGLOSA          => l_text,
                    DEFFECDATE      => p_sap_cla_gen_row.ISSUE_DATE,
                    SDOC_TYPE       => l_doc_type,
                    SREF_DOC        => p_sap_cla_gen_row.ACC_DOC_ID,
                    SACTION         => p_sap_cla_gen_row.ACTION_TYPE,
                    NGROUP          => NULL,
                    SDOC_SAP        => NULL,
                    SDOC_YEAR       => NULL,
                    DLEDGERDAT      => NULL,
                    SNULLCODE       => NULL,
                    DCOMPDATE       => SYSDATE,
                    NSEQUENCE_TRA   => p_sap_cla_gen_row.ID
                );
            ELSE               
                IF l_doc_type = 'C5' THEN
                     --C5: Coaseguro Cedido (AP027)
                     BEGIN
                           SELECT CASE WHEN CURRENCY = 'PEN' THEN 1 ELSE 2 END
                           INTO l_currency_acc
                           FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_ACC
                           WHERE ID = P_SAP_CLA_GEN_ROW.ID AND ROWNUM=1;
                     EXCEPTION
                     WHEN OTHERS THEN
                           l_currency_acc := NULL;
                     END;
                     l_leader_sapclicod                := PEOPLE_SAP_CODE(P_SAP_CLA_GEN_ROW.INSURER_PARTY); --defect 281                 
                     l_sref_doc := to_char(P_SAP_CLA_GEN_ROW.ISSUE_DATE,'YYYYMM') || lpad(P_SAP_CLA_GEN_ROW.TECH_BRANCH, 2, '0') || 'S' || l_currency_acc ;
                
                ELSIF L_DOC_TYPE = 'C7'  OR L_DOC_TYPE = 'C8' OR  L_DOC_TYPE = 'C0' OR L_DOC_TYPE = 'C9' THEN
                     --C7,C8: Apertura, Ajuste, de Coaseguro Recibido,  
                     --C0: CxP a Asegurado
                     --C9: CxP a Coasegurador
                     BEGIN
                        SELECT G.BENEF_PARTY, P.NAME 
                        INTO l_sap_code, l_cliename 
                        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN G
                        LEFT JOIN INSIS_PEOPLE_V10.P_PEOPLE P ON P.MAN_ID = G.BENEF_PARTY
                        WHERE G.CLAIM_NO =  P_SAP_CLA_GEN_ROW.CLAIM_NO
                        AND G.ACTION_TYPE = 'APE'
                        AND G.HEADER_CLASS = 'A';                    
                    EXCEPTION
                    WHEN OTHERS THEN
                        l_sap_code := NULL;
                    END;
                    
                    l_benef_sapcode := PEOPLE_SAP_CODE(l_sap_code); 
                  
                    BEGIN
                        SELECT Q.QUEST_ANSWER
                        INTO l_coinsrepnum
                        FROM INSIS_GEN_V10.POLICY P 
                        INNER JOIN INSIS_GEN_V10.QUEST_QUESTIONS Q ON (P.POLICY_ID = Q.POLICY_ID)
                        INNER JOIN INSIS_GEN_V10.CLAIM C ON (Q.POLICY_ID = C.POLICY_ID)
                        WHERE QUEST_ID IN ('COINSREPNUM')
                        AND C.CLAIM_ID =  SUBSTR(p_sap_cla_gen_row.CLAIM_NO,1,11)
                        AND Q.ANNEX_ID = 0;
                    EXCEPTION
                    WHEN OTHERS THEN
                        l_coinsrepnum := NULL;
                    END; 
                    
                    l_sref_doc := l_coinsrepnum;  
                  
                    BEGIN                        
                        SELECT TO_DATE(Q.QUEST_ANSWER,'dd/mm/yyyy')
                        INTO l_coinsrepdate
                        FROM INSIS_GEN_V10.POLICY P 
                        INNER JOIN INSIS_GEN_V10.QUEST_QUESTIONS Q ON (P.POLICY_ID = Q.POLICY_ID)
                        INNER JOIN INSIS_GEN_V10.CLAIM C ON (Q.POLICY_ID = C.POLICY_ID)
                        WHERE QUEST_ID IN ('COINSREPDATE')
                        AND C.CLAIM_ID =  SUBSTR(p_sap_cla_gen_row.CLAIM_NO,1,11)
                        AND Q.ANNEX_ID = 0;                        
                    EXCEPTION
                    WHEN OTHERS THEN
                        l_coinsrepnum := NULL;
                        l_coinsrepdate := NULL;
                    END;                                       
                    
                    P_SAP_CLA_GEN_ROW.RECEPTION_DATE  := l_coinsrepdate;   
                    l_client_sapcode                  := PEOPLE_SAP_CODE(l_leader_man_id);
                    l_leader_sapclicod                := PROVIDER_SAP_CODE(l_leader_man_id);
                
                ELSE
                    IF P_SAP_CLA_GEN_ROW.ACTION_TYPE = 'PCC' THEN --IPCLA006 
                        --l_sref_doc := LPAD(p_sap_cla_gen_row.INV_DOC_TYPE, 2, 0) || '-' || p_sap_cla_gen_row.INV_SERIAL_NUMBER || '-' || p_sap_cla_gen_row.INV_NUMBER; --Defect 520 comment
                         l_sref_doc := LPAD(p_sap_cla_gen_row.INV_DOC_TYPE, 2, 0) || '-' || p_sap_cla_gen_row.INV_SERIAL_NUMBER || '-' || substr(TRIM(p_sap_cla_gen_row.INV_NUMBER), -7); --Defect 520
                        l_claim_no :=  p_sap_cla_gen_row.CLAIM_NO;
                    ELSE
                        l_sref_doc := p_sap_cla_gen_row.CLAIM_NO;    
                    END IF;
                    
                END IF;
                
                IF P_SAP_CLA_GEN_ROW.CURRENCY = 'PEN' THEN
                      l_changdate := NULL; 
                ELSE
                      l_changdate := p_sap_cla_gen_row.ISSUE_DATE;
                END IF;
                
                IF l_doc_type = 'C9' THEN
                    p_sap_cla_gen_row.action_type := 'PCC';
                END IF;
                
        
                --IP CLA006--
                BEGIN
                    SELECT EI.EGN, ED.TAX_CODE, ED.TOTAL_AMOUNT, EI.CURRENCY,  ED.VAT_AMOUNT, EI.ISSUE_DATE
                    INTO l_egn, l_tax_code, l_amountbase, l_currency_coa, l_vat_amount,
                             l_ledgerdat --defect 536
                    FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN G
                    LEFT JOIN INSIS_CUST_LPV.EXP_INVOICES_STG EI 
                    ON (G.INV_DOC_TYPE = EI.DOC_TYPE AND G.INV_SERIAL_NUMBER = EI.INV_SERIAL_NUMBER
                        AND G.INV_NUMBER = EI.INV_NUMBER AND G.INSURED_OBJ = EI.MAN_ID) 
                    LEFT JOIN INSIS_CUST_LPV.EXP_INV_DTL_STG ED ON (EI.DOC_PROV_ID = ED.DOC_PROV_ID AND ED.ITEMNO_ACC <> '001')
                    WHERE G.ID = p_sap_cla_gen_row.ID AND ROWNUM=1; 
                EXCEPTION
                    WHEN OTHERS THEN
                        l_egn := NULL;
                        l_tax_code := NULL;
                        l_currency_coa := 0;
                        l_vat_amount := 0;    
                        l_ledgerdat :=NULL;--defect 536
                END;
                
                l_ledgerdat := NVL(l_ledgerdat,P_SAP_CLA_GEN_ROW.ISSUE_DATE); --defect 536
          
                INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA001(
                    NCLAIM            => P_SAP_CLA_GEN_ROW.CLAIM_NO,
                    NCASE_NUM         => 1,
                    NDEMAN_TYPE       => 1,
                    SBUSSITYP         => l_busstyp,
                    /*NDOC_TYPE         => NULL,
                    SSERIAL           => NULL,
                    SNUMBER           => NULL,
                    SRUC              => NULL,*/
                    ndoc_type         => P_SAP_CLA_GEN_ROW.INV_DOC_TYPE,             -- IP CLA006                    
                    SSERIAL           => P_SAP_CLA_GEN_ROW.INV_SERIAL_NUMBER,        -- IP CLA006        
                    SNUMBER           => P_SAP_CLA_GEN_ROW.INV_NUMBER,               -- IP CLA006
                    SRUC              => l_egn,                                      -- IP CLA006
                    DPASSDATE         => NULL,
                    DPROCINI          => NULL,
                    DPROCEND          => NULL,
                    NSTATUS           => 0,
                    NUSERCODE         => 8888,
                    DCOMPDATE         => P_SAP_CLA_GEN_ROW.ISSUE_DATE,
                    NSEQUENCE_REF     => NULL,
                    NTRANSAC          => P_SAP_CLA_GEN_ROW.ACC_DOC_ID,
                    SRPTA_ANU         => NULL,
                    SACTION           => P_SAP_CLA_GEN_ROW.ACTION_TYPE,
                    SGLOSA            => l_text,
                    NCOMPANY          => 2,
                    DOPERDATE         => P_SAP_CLA_GEN_ROW.ISSUE_DATE,
                    --DLEDGERDATE       => P_SAP_CLA_GEN_ROW.ISSUE_DATE, -- defect 538 comment
                    DLEDGERDATE       => l_ledgerdat, --defect 538
                    DCHANGEDATE       => l_changdate,
                    SDOC_TYPE         => l_doc_type,
                    SREF_DOC          => l_sref_doc,
                    NPRIOR            => NULL,
                    NSISTORIGIN       => 5,
                    SDOC_SAP          => NULL,
                    SDOC_YEAR         => NULL,
                    DLEDGERDAT        => NULL,
                    SNULLCODE         => NULL,
                    NSEQUENCE_TRA     => P_SAP_CLA_GEN_ROW.ID,
                    SCLAIM_CASE       => P_SAP_CLA_GEN_ROW.CLAIM_NO,
                    NBRANCH           => P_SAP_CLA_GEN_ROW.TECH_BRANCH,
                    NPOLICY           => P_SAP_CLA_GEN_ROW.POLICY_NO,
                    NCERTIF           => P_SAP_CLA_GEN_ROW.DEPEND_POLICY_NO,
                    DOCCURDAT         => P_SAP_CLA_GEN_ROW.CLAIM_EVENT_DATE,
                    SBRAND            => NULL,
                    SVEHTYPE          => NULL,
                    SREGIST           => NULL,
                    SCAUSE            => NULL,
                    SPLANILLA         => l_coinsrepnum,
                    SCLIENT_SAP       => l_client_sapcode,
                    SCLAIM_EXT        => NULL,
                    DRECEPTION_DATE   => P_SAP_CLA_GEN_ROW.RECEPTION_DATE,
                    BANK_CODE         => P_SAP_CLA_GEN_ROW.BANK_CODE,
                    NRO_CTA           => P_SAP_CLA_GEN_ROW.BANK_ACCOUNT_CODE,
                    CURRENCY          => P_SAP_CLA_GEN_ROW.BANK_ACCOUNT_CURRENCY,
                    CTA_TYPE          => P_SAP_CLA_GEN_ROW.BANK_ACCOUNT_TYPE,
                    NSEQUENCE         => l_sequence
                );
            END IF;
            
            OPEN SAP_CLA_ACC_CUR_LIST(l_ini_records,l_fin_records,l_id_gen);
            LOOP
                FETCH SAP_CLA_ACC_CUR_LIST INTO l_sap_cla_acc_row;
                EXIT WHEN SAP_CLA_ACC_CUR_LIST%NOTFOUND OR SAP_CLA_ACC_CUR_LIST%NOTFOUND IS NULL;
                
                BLC_CLAIM_MAP_ACC(
                    pi_sap_cla_gen_row    => p_sap_cla_gen_row,
                    pio_sap_cla_acc_row   => l_sap_cla_acc_row,
                    po_stipprc            => l_stipprc,
                    po_profit_center      => l_profit_center,
                    po_copa               => l_copa,
                    po_currency_sap       => l_currency_acc,
                    po_text               => l_text,
                    po_amount             => l_amount,
                    po_amount_base        => l_amount_base,
                    po_payway             => l_payway,
                    po_ri_contract_type   => l_contact_type
                );
                
                l_ledgerdat := NULL;
          
                IF l_amount <> 0 THEN
                    IF p_sap_cla_gen_row.ACTION_TYPE IN ('LQP','LQS') AND l_stipprc IN ('3') THEN
                        l_benef_sapcode := l_holder_sapcode; 
                        IF substr(l_sap_cla_acc_row.ACCOUNT,1,2) = '16' THEN
                        --03.08.2021 Agregar la fecha del prestamo, incidente 83
                           BEGIN
                              SELECT doc_due_date
                                 INTO l_ledgerdat                           
                              FROM insis_blc_global_cust.blc_loan_gen
                              WHERE loan_number = l_sap_cla_acc_row.loan_number
                              AND loan_seq = l_sap_cla_acc_row.loan_seq;
                           EXCEPTION
                                  WHEN OTHERS THEN
                                      l_ledgerdat := p_sap_cla_gen_row.ISSUE_DATE;  
                           END;          
                           --04.08.2021 Customer del Prestamo
                           BEGIN
                              SELECT doc_party
                                 INTO l_benef_lqp                       
                              FROM insis_blc_global_cust.blc_loan_gen
                              WHERE loan_number = l_sap_cla_acc_row.loan_number
                              AND loan_seq = l_sap_cla_acc_row.loan_seq;
                               l_client_sapcode    := PEOPLE_SAP_CODE(l_benef_lqp);
                           EXCEPTION
                                  WHEN OTHERS THEN
                                      l_client_sapcode    := l_sap_code;
                           END;   

                        ELSE
                            l_ledgerdat  := NULL;                
                        END IF;    
                        
                        IF l_sap_cla_acc_row.ACCOUNT = '2301020002' AND p_sap_cla_gen_row.doc_type = 'SALDAMIENTO' THEN
                            l_blockade  := 'A';
                        ELSE
                            l_blockade  := NULL;                
                        END IF;              
                    END IF;
                    
                    l_account_dote := '4401' ||  trim(to_char(p_sap_cla_gen_row.TECH_BRANCH)) || '0101';
                        
                    IF p_sap_cla_gen_row.ACTION_TYPE IN ('LQP') AND l_sap_cla_acc_row.ACCOUNT IN (l_account_dote,'2002090003','2301010001') THEN
                        l_claim_no := p_sap_cla_gen_row.CLAIM_NO;
                    END IF; 
                    
                    IF p_sap_cla_gen_row.ACTION_TYPE IN ('LQP') AND l_sap_cla_acc_row.ACCOUNT IN ('1604070001','1604070003') THEN
                        l_claim_no := 'KC' || TO_CHAR(l_sap_cla_acc_row.LOAN_NUMBER) || '-' || lpad(TO_CHAR(l_sap_cla_acc_row.LOAN_SEQ),3,0);
                    END IF;  
                    
                    --Numero de Asignación Dote sin prestamo y rescate sin prestamo siempre es la Poliza
                    IF p_sap_cla_gen_row.ACTION_TYPE IN ('LQS') THEN
                        l_claim_no := p_sap_cla_gen_row.POLICY_NO;
                    END IF;   
                                
                    IF p_sap_cla_gen_row.ACTION_TYPE = 'PSC' AND l_stipprc = '4' THEN
                        l_provider_sapcode := l_benef_sapcode;
                    ELSIF p_sap_cla_gen_row.ACTION_TYPE = 'PCC' AND l_stipprc = '4' THEN    -- IPCLA006
                        l_provider_sapcode := l_client_sapcode;
                    END IF;
                    
                    IF p_sap_cla_gen_row.ACTION_TYPE IN ('LQP','LQS') AND l_stipprc = '4' THEN
                        l_provider_sapcode := l_holder_sapcode;
                    END IF; 
                    --
                    IF p_sap_cla_gen_row.HEADER_CLASS = 'R' THEN
                    --
                        IF p_sap_cla_gen_row.INSURER_PARTY IS NOT NULL THEN
                              l_leader_sapclicod    := PEOPLE_SAP_CODE(P_SAP_CLA_GEN_ROW.INSURER_PARTY);
                              l_leader_sapprvcod    := PROVIDER_SAP_CODE(p_sap_cla_gen_row.INSURER_PARTY);
                        END IF;
                        
                        IF  l_stipprc = '2' OR  l_stipprc = '4' THEN
                            l_leader_sap := l_leader_sapprvcod;
                        ELSE
                            l_leader_sap := l_leader_sapclicod;
                        END IF;
                        --
                        INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI002(
                            NSEQUENCE         => l_sequence,
                            NITEM_NUM         => l_sap_cla_acc_row.LINE_NUMBER,
                            SVENDOR_SAP       => NULL,
                            SACCOUNT          => l_sap_cla_acc_row.ACCOUNT,
                            SDOC_TYPE         => l_doc_type,
                            SBRANCH_POLICY    => p_sap_cla_gen_row.TECH_BRANCH || '-' || SUBSTR(p_sap_cla_gen_row.POLICY_NO,1,15),
                            DEFFECDATE        => p_sap_cla_gen_row.ISSUE_DATE,
                            SCLIENT           => l_client_sapcode,
                            NRECEIPT          => NULL,
                            NOFFICE           => p_sap_cla_gen_row.OFFICE_GL_NO,
                            SGLOSA            => substr(l_client_sapcode || '-' || l_text,1,50),
                            NCURRENCY         => l_currency_acc,
                            NORI_AMO          => l_amount,
                            NCOUNTRY          => 1,
                            NCOMPANY          => 2,
                            NBRANCH_BAL       => p_sap_cla_gen_row.TECH_BRANCH,
                            NGEOGRAPHICZONE   => NULL,
                            NCURRENCY_POL     => NULL,
                            SCUSTOMER_SAP     => l_leader_sap,  --PEOPLE_SAP_CODE(p_sap_cla_gen_row.INSURER_PARTY),
                            SCLAIM_CASE       => p_sap_cla_gen_row.CLAIM_NO,
                            DOCCURDAT         => p_sap_cla_gen_row.CLAIM_EVENT_DATE,
                            STIPPRC           => l_stipprc,
                            NTYPECONTRACT     => l_contact_type,
                            NBUSSIUNIT        => get_BUSINESS_UNIT(p_sap_cla_gen_row.INSR_TYPE,p_sap_cla_gen_row.SALES_CHANNEL)
                         );
                  
                        IF l_copa = 'Y' THEN
                            BLC_COPA_INSERT(
                                l_sequence,
                                l_sap_cla_acc_row.LINE_NUMBER,
                                p_sap_cla_gen_row.TECH_BRANCH,
                                p_sap_cla_gen_row.OFFICE_GL_NO,
                                get_BUSINESS_UNIT(p_sap_cla_gen_row.INSR_TYPE, p_sap_cla_gen_row.SALES_CHANNEL),
                                p_sap_cla_gen_row.POLICY_NO,
                                p_sap_cla_gen_row.SALES_CHANNEL,
                                p_sap_cla_gen_row.BENEF_PARTY,
                                p_sap_cla_gen_row.INSR_TYPE,
                                l_busstyp,
                                p_sap_cla_gen_row.INTERMED_TYPE
                            );
                        END IF;
                    ELSE
                        IF l_doc_type = 'C5' THEN
                            l_client_sapcode := l_leader_sapclicod;
--                            IF l_stipprc = '4'   THEN
--                                l_text := l_client_sapcode || '-' || l_text;
                                l_text := l_benef_sapcode || '-' || l_text;
--                            END IF;                                                
                            l_leader_sapclicod := P_SAP_CLA_GEN_ROW.CI_PERCENT;
                            
                        ELSIF l_doc_type = 'C7' OR l_doc_type = 'C8'  THEN                                                        
                            
--                            l_client_sapcode := PEOPLE_SAP_CODE(l_leader_man_id);
                            
--                            l_leader_sapclicod := PROVIDER_SAP_CODE(l_leader_man_id);
                            
                            IF l_stipprc = '4' THEN
                                l_text := l_provider_sapcode || '-' || l_text;
                            END IF;
                        ELSIF l_doc_type = 'C9' OR l_doc_type = 'C0' THEN                                                          
                            
                            l_text := l_benef_sapcode || '-' || l_cliename;   
                            
--                            l_text := l_benef_sapcode || '-' || l_cliename;
                            
                            IF l_stipprc = '2' THEN
                              l_provider_sapcode := l_leader_sapclicod;
                            ELSIF l_stipprc = '3' THEN
                              l_provider_sapcode := l_benef_sapcode;
                            ELSIF l_stipprc = '4' THEN
                              l_provider_sapcode :=  l_benef_sapcode;
--                              l_text := l_benef_sapcode || '-' || l_cliename;
                            END IF;
                                                    
                        END IF;

                        --IP CLA006--
                        IF p_sap_cla_gen_row.action_type = 'PCC' THEN
                              BEGIN
                                  SELECT I.SAP_CODE_LEGAL || '-' || P.NAME
                                  INTO l_cliename
                                  FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN G
                                  LEFT JOIN INSIS_CUST.INTRF_LPV_PEOPLE_IDS I ON I.MAN_ID = G.INSURED_OBJ
                                  LEFT JOIN INSIS_PEOPLE_V10.P_PEOPLE P ON P.MAN_ID = G.INSURED_OBJ
                                  WHERE G.ID = l_id_gen; 
                              EXCEPTION
                                  WHEN OTHERS THEN
                                      l_cliename := NULL;
                              END;
                        END IF;
                        
                        /*Start: 03.05.21 LPV-JCC - PAY WAY Defect 502 */
                        /* Defect 513
                        IF  l_stipprc = '3' AND  
                           NOT( l_sap_cla_acc_row.ACCOUNT like '2606__001'  OR  --Siniestros
                           l_sap_cla_acc_row.ACCOUNT = '2301020001' OR              --Rescate
                           l_sap_cla_acc_row.ACCOUNT = '2301010001' OR             --Dote                   
                           l_sap_cla_acc_row.ACCOUNT = '2309090007' )                 --Retiro Parcial      
                        THEN
                           l_payway := NULL;
                        END IF;
                        */ 
                       /*End:  03.05.21 LPV-JCC - PAY WAY Defect 502 */ 
                       
                       /*Start: 12.05.21 LPV-JCC - PAY WAY Defect 513 */  
                        IF  l_stipprc = '3' THEN
                           IF  (substr(l_sap_cla_acc_row.ACCOUNT,1,4) = '2606' AND  substr(l_sap_cla_acc_row.ACCOUNT,7,4) = '0001')  THEN --Siniestros
                               l_payway := l_payway;
                           ELSIF l_sap_cla_acc_row.ACCOUNT = '2301020001' THEN  --Rescate
                              l_payway := l_payway;
                           ELSIF l_sap_cla_acc_row.ACCOUNT = '2301010001' THEN --Dote         
                              l_payway := l_payway;
                           ELSIF l_sap_cla_acc_row.ACCOUNT = '2309090007' THEN --Retiro Parcial
                              l_payway := l_payway;  
                           ELSE
                              l_payway := NULL;
                           END IF;
                        END IF;
                       /*End:  12.05.21 LPV-JCC - PAY WAY Defect 513 */ 
                       
                       /*BEGIN Defect 520 set doc_sap AP011*/
                        IF p_sap_cla_gen_row.action_type = 'PCC'  AND  l_stipprc = '2'  THEN
                              BEGIN
                                  SELECT DOC_SAP SDOC_SAP
                                  INTO l_doc_sap
                                  FROM INSIS_CUST_LPV.EXP_INVOICES_STG
                                  WHERE 1 = 1
                                  --AND CLAIM_ID = P_SAP_CLA_GEN_ROW.CLAIM_NO
                                  AND DOC_TYPE = P_SAP_CLA_GEN_ROW.INV_DOC_TYPE
                                  AND INV_SERIAL_NUMBER = P_SAP_CLA_GEN_ROW.INV_SERIAL_NUMBER
                                  AND INV_NUMBER = P_SAP_CLA_GEN_ROW.INV_NUMBER
                                  AND MAN_ID = P_SAP_CLA_GEN_ROW.INSURED_OBJ;                               
                              EXCEPTION
                              WHEN OTHERS THEN
                                      l_doc_sap := NULL;
                              END;      
                        END IF;
                         /*END Defect 520 set doc_sap */

                        INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA002(
                            NITEM_NUM         => l_sap_cla_acc_row.LINE_NUMBER,
                            STIPPRC           => l_stipprc,
                            SPROVIDER         => l_provider_sapcode,
                            SACCOUNT          => l_sap_cla_acc_row.ACCOUNT,
                            ntransac          => p_sap_cla_gen_row.acc_doc_id,
                            SBENEF            => l_benef_sapcode,
                            SBRANCH_POLICY    => p_sap_cla_gen_row.TECH_BRANCH || '-' || SUBSTR(p_sap_cla_gen_row.POLICY_NO,1,17),
                            SOFFICE_SAP       => p_sap_cla_gen_row.OFFICE_GL_NO,
                            --DVENC_DATE        => NULL,
                            DVENC_DATE        => TRUNC(SYSDATE),   --IP006
                            SPAYWAY           => l_payway,
                            sblockade         => l_blockade,
                            SCLAIM_CASE       => nvl(l_claim_no,p_sap_cla_gen_row.CLAIM_NO), --SUBSTR(p_sap_cla_gen_row.CLAIM_NO,1,18),
                            --SCLIENAME         => NULL,
                            SCLIENAME           => l_cliename,      --IP CLA006
                            --STAX_CODE         => NULL,
                            STAX_CODE           => l_tax_code,    --IP CLA006 
                            NCURRENCY         => l_currency_acc,
                            NAMOUNT           => l_amount,
                            --NAMOUNT_BASE      => NULL,
                            NAMOUNT_BASE        => l_amountbase,    --IP CLA006
                            --STYPE_CODE_WT     => NULL,
                            STYPE_CODE_WT     => p_sap_cla_gen_row.TYPE_CODE_WT,    -- IP CLA006
                            --SDOC_SAP          => NULL,
                            SDOC_SAP          => l_doc_sap, -- Defect 520                            
                            SLEADER_CODE      => l_leader_sapclicod,
                            SCLIENT           => l_client_sapcode,
                            dledgerdat        => l_ledgerdat,
                            STEXT             => substr(l_text,1,50),
                            NOFFICE           => p_sap_cla_gen_row.OFFICE_GL_NO,
                            DOCCURDAT         => p_sap_cla_gen_row.CLAIM_EVENT_DATE,
                            NCOUNTRY          => 1,
                            NBRANCH_LED       => p_sap_cla_gen_row.TECH_BRANCH,
                            NGEOGRAPHICZONE   => NULL,
                            nquantity         => p_sap_cla_gen_row.ci_percent,
                            SBASE             => l_amount_base, -- NULL,
                            SBUSSIUNIT        => p_sap_cla_gen_row.BUSINESS_UNIT,
                            SDOC_YEAR         => NULL,
                            SNULLCODE         => NULL,
                            NCOMPANY          => 2,
                            PROFIT_CTR        => NULL,
                            NSEQUENCE         => l_sequence
                        );
                    END IF;
                    
                     --DEFECT 520
                     BEGIN
                        SELECT max(LINE_NUMBER)
                        INTO l_item_num
                        FROM BLC_CLAIM_ACC
                        WHERE ID =  p_sap_cla_gen_row.ID;
                     EXCEPTION
                       WHEN OTHERS THEN
                           l_item_num := NULL;
                     END;                     
                     
                    IF SAP_CLA_ACC_CUR_LIST%ROWCOUNT = l_item_num THEN
                        IF P_SAP_CLA_GEN_ROW.ACTION_TYPE = 'PCC' THEN                         
                              INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA002(
                                  NITEM_NUM         => l_sap_cla_acc_row.LINE_NUMBER+1,
                                  STIPPRC           => 5,
                                  SPROVIDER         =>NULL,
                                  SACCOUNT          => NULL,
                                  ntransac          => NULL,
                                  SBENEF            => NULL,
                                  SBRANCH_POLICY    => NULL,
                                  SOFFICE_SAP       => NULL,
                                  DVENC_DATE        => NULL,
                                  SPAYWAY           =>  NULL,
                                  sblockade         => NULL,
                                  SCLAIM_CASE       => NULL,
                                  SCLIENAME           => NULL,
                                  STAX_CODE           => l_tax_code,
                                  NCURRENCY         => l_currency_coa,
                                  NAMOUNT           => l_amountbase,
                                  NAMOUNT_BASE        => l_vat_amount, 
                                  STYPE_CODE_WT     =>NULL,
                                  SDOC_SAP          => NULL,                            
                                  SLEADER_CODE      => NULL,
                                  SCLIENT           => NULL,
                                  dledgerdat        => NULL,
                                  STEXT             => NULL,
                                  NOFFICE           => NULL,
                                  DOCCURDAT         => NULL,
                                  NCOUNTRY          => NULL,
                                  NBRANCH_LED       => NULL,
                                  NGEOGRAPHICZONE   => NULL,
                                  nquantity         => NULL,
                                  SBASE             => NULL,
                                  SBUSSIUNIT        => NULL,
                                  SDOC_YEAR         => NULL,
                                  SNULLCODE         => NULL,
                                  NCOMPANY          => NULL,
                                  PROFIT_CTR        => NULL,
                                  NSEQUENCE         => l_sequence
                              );                                    
                        END IF;
                     END IF;
                     --DEFECT 520
                    
                        
                    
                END IF;
            END LOOP;
            CLOSE sap_cla_acc_cur_list;
            
            l_ini_records                    := l_fin_records + 1;
            
            IF p_sap_cla_gen_row.HEADER_CLASS = 'R' THEN
                INSIS_CUST_LPV.IIBPKGREI.IIBPRCINSREI004(
                    NSEQUENCE       => l_sequence,
                    NCOMPANY        => 2,
                    NSISTORIGIN     => 5,
                    NVOUCHER        => NULL,
                    NPRIOR          => NULL,
                    DCOMPDATE       => NULL,
                    DPASSDATE       => NULL,
                    DPROCINI        => NULL,
                    DPROCEND        => NULL,
                    NSTATUS         => 0,
                    SMSGERROR       => NULL,
                    SSEQUENCE_SAP   => NULL,
                    NREINTENTOS     => NULL
                );
            ELSE
                INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA003(
                    NSEQUENCE       => l_sequence,
                    NCOMPANY        => 2,
                    NSISTORIGIN     => 5,
                    NCLAIM          => SUBSTR(p_sap_cla_gen_row.CLAIM_NO,1,16),
                    NCASE_NUM       => 1,
                    NDEMAN_TYPE     => NULL,
                    NPRIOR          => NULL,
                    DCOMPDATE       => NULL,
                    DPASSDATE       => NULL,
                    NTRANSAC        => p_sap_cla_gen_row.PAYMENT_ID,
                    DPROCINI        => NULL,
                    DPROCEND        => NULL,
                    NSTATUS         => 0,
                    SMSGERROR       => NULL,
                    SSEQUENCE_SAP   => NULL,
                    NREINTENTOS     => NULL
                );
            END IF;
        END LOOP;
        
    ELSE
        IF p_sap_cla_gen_row.IP_CODE = 'I008' THEN
            OPEN sap_cla_anu_amount (p_sap_cla_gen_row.CLAIM_NO, p_sap_cla_gen_row.IP_CODE);
            LOOP
                FETCH sap_cla_anu_amount INTO l_sap_cla_gen_row;
                EXIT WHEN sap_cla_anu_amount%NOTFOUND OR sap_cla_anu_amount%NOTFOUND IS NULL;
          
                BLC_CLAIM_MAP_HEADER(
                    pio_sap_cla_gen_row   => l_sap_cla_gen_row,
                    pi_drcr               => l_drcr,
                    po_doc_type           => l_doc_type,
                    po_text               => l_text,
                    po_blockade           => l_blockade,
                    po_busstyp            => l_busstyp,
                    po_currency_sap       => l_currency_header,
                    po_leader_man_id      => l_leader_man_id
                );
          
                IF EXTRACT(MONTH FROM l_sap_cla_gen_row.ISSUE_DATE) = EXTRACT(MONTH FROM p_sap_cla_gen_row.ISSUE_DATE) THEN
                    l_nullcode                                       :='01';
                ELSE
                    l_nullcode:='02';
                END IF;
          --IP CLA006 no aplica
                INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA001(
                    NCLAIM            => l_sap_cla_gen_row.CLAIM_NO,
                    NCASE_NUM         => 1,
                    NDEMAN_TYPE       => 1,
                    SBUSSITYP         => l_busstyp,
                    NDOC_TYPE         => NULL,
                    SSERIAL           => NULL,
                    SNUMBER           => NULL,
                    SRUC              => NULL,
                    DPASSDATE         => NULL,
                    DPROCINI          => NULL,
                    DPROCEND          => NULL,
                    NSTATUS           => 0,
                    NUSERCODE         => 8888,
                    DCOMPDATE         => l_sap_cla_gen_row.ISSUE_DATE,
                    NSEQUENCE_REF     => NULL,
                    NTRANSAC          => p_sap_cla_gen_row.ACC_DOC_ID,
                    SRPTA_ANU         => NULL,
                    SACTION           => l_sap_cla_gen_row.ACTION_TYPE,
                    SGLOSA            => 'REEMBOLSO SINIESTROS',
                    NCOMPANY          => 2,
                    DOPERDATE         => l_sap_cla_gen_row.ISSUE_DATE,
                    DLEDGERDATE       => l_sap_cla_gen_row.ISSUE_DATE,
                    DCHANGEDATE       => l_sap_cla_gen_row.ISSUE_DATE,
--                    sdoc_type         => 'TL',
                    SDOC_TYPE         => l_doc_type, --defect 170
                    SREF_DOC          => p_sap_cla_gen_row.CLAIM_NO,
                    NPRIOR            => NULL,
                    NSISTORIGIN       => 5,
                    SDOC_SAP          => NULL,
                    SDOC_YEAR         => NULL,
                    DLEDGERDAT        => NULL,
                    SNULLCODE         => NULL,
                    NSEQUENCE_TRA     => p_sap_cla_gen_row.ID,
                    SCLAIM_CASE       => p_sap_cla_gen_row.CLAIM_NO,
                    NBRANCH           => l_sap_cla_gen_row.TECH_BRANCH,
                    NPOLICY           => TO_NUMBER(p_sap_cla_gen_row.POLICY_NO),
                    NCERTIF           => l_sap_cla_gen_row.DEPEND_POLICY_NO,
                    DOCCURDAT         => l_sap_cla_gen_row.CLAIM_EVENT_DATE,
                    SBRAND            => NULL,
                    SVEHTYPE          => NULL,
                    SREGIST           => NULL,
                    SCAUSE            => NULL,
                    SPLANILLA         => NULL,
                    SCLIENT_SAP       => l_sap_cla_gen_row.BENEF_PARTY,
                    SCLAIM_EXT        => NULL,
                    DRECEPTION_DATE   => NULL,
                    BANK_CODE         => NULL,
                    NRO_CTA           => NULL,
                    CURRENCY          => NULL,
                    CTA_TYPE          => NULL,
                    NSEQUENCE         => l_sequence
                );
                --IP CLA006 no aplica
                INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA002(
                    NITEM_NUM         => 1,
                    STIPPRC           => 6,
                    SPROVIDER         => NULL,
                    SACCOUNT          => NULL,
                    NTRANSAC          => NULL,
                    SBENEF            => NULL,
                    SBRANCH_POLICY    => NULL,
                    SOFFICE_SAP       => NULL,
                    DVENC_DATE        => NULL,
                    SPAYWAY           => NULL,
                    SBLOCKADE         => NULL,
                    SCLAIM_CASE       => NULL,
                    SCLIENAME         => NULL,
                    STAX_CODE         => NULL,
                    NCURRENCY         => NULL,
                    NAMOUNT           => NULL,
                    NAMOUNT_BASE      => NULL,
                    STYPE_CODE_WT     => NULL,
                    SDOC_SAP          => SUBSTR(l_sap_cla_gen_row.SAP_DOC_NUMBER,1,10),
                    SLEADER_CODE      => NULL,
                    SCLIENT           => NULL,
                    DLEDGERDAT        => l_sap_cla_gen_row.ISSUE_DATE,
                    STEXT             => NULL,
                    NOFFICE           => NULL,
                    DOCCURDAT         => NULL,
                    NCOUNTRY          => NULL,
                    NBRANCH_LED       => NULL,
                    NGEOGRAPHICZONE   => NULL,
                    NQUANTITY         => NULL,
                    SBASE             => NULL,
                    SBUSSIUNIT        => NULL,
                    SDOC_YEAR         => SUBSTR(l_sap_cla_gen_row.SAP_DOC_NUMBER,15,4),
                    SNULLCODE         => l_nullcode,
                    NCOMPANY          => 2,
                    PROFIT_CTR        => NULL,
                    NSEQUENCE         => l_sequence
                );
            END LOOP;
        
            INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA003(
                NSEQUENCE => l_sequence,
                NCOMPANY => 2,
                NSISTORIGIN => 5,
                NCLAIM => SUBSTR(p_sap_cla_gen_row.CLAIM_NO,1,10),
                NCASE_NUM => 1,
                NDEMAN_TYPE => NULL,
                NPRIOR => NULL,
                DCOMPDATE => NULL,
                DPASSDATE => NULL,
                NTRANSAC => l_sap_cla_gen_row.PAYMENT_ID,
                DPROCINI => NULL,
                DPROCEND => NULL,
                NSTATUS => 0,
                SMSGERROR => NULL,
                SSEQUENCE_SAP => NULL,
                NREINTENTOS => NULL
            );
            CLOSE sap_cla_anu_amount;
      
        ELSIF p_sap_cla_gen_row.IP_CODE = 'I011-1' OR p_sap_cla_gen_row.IP_CODE = 'I011-2' OR p_sap_cla_gen_row.IP_CODE = 'I013' OR p_sap_cla_gen_row.IP_CODE = 'I016' THEN --ANU
            IF p_sap_cla_gen_row.IP_CODE  = 'I013' THEN
                BEGIN
                    SELECT blc_cle.*
                    INTO l_sap_cla_gen_row
                    FROM BLC_CLAIM_GEN blc_anu, BLC_CLAIM_GEN blc_cle
                    WHERE blc_anu.ID         = l_id_gen
                    AND blc_cle.ACTION_TYPE <> 'ANU'
                    AND blc_anu.ACTION_TYPE  = 'ANU'
                    AND blc_cle.STATUS       = 'T'
                    AND blc_anu.CLEARING_ID  = blc_cle.CLEARING_ID
                    AND blc_cle.ID           = blc_anu.REVERSED_ID
                    ORDER BY blc_cle.ID DESC;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_sap_cla_gen_row := NULL;
                END;            
            ELSE
                BEGIN
                    SELECT blc_pay.*
                    INTO l_sap_cla_gen_row
                    FROM BLC_CLAIM_GEN blc_anu, BLC_CLAIM_GEN blc_pay
                    WHERE blc_anu.ID         = l_id_gen
                    AND blc_pay.ACTION_TYPE <> 'ANU'
                    AND blc_anu.ACTION_TYPE  = 'ANU'
                    AND blc_pay.STATUS       = 'T'
                    AND blc_anu.PAYMENT_ID   = blc_pay.PAYMENT_ID
                    AND blc_pay.ID           = blc_anu.REVERSED_ID
                    ORDER BY blc_pay.ID DESC;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        l_sap_cla_gen_row := NULL;
                  END;
            END IF;
        
            IF l_sap_cla_gen_row.ID IS NOT NULL THEN
                BLC_CLAIM_MAP_HEADER(
                    pio_sap_cla_gen_row   => l_sap_cla_gen_row,
                    pi_drcr               => l_drcr,
                    po_doc_type           => l_doc_type,
                    po_text               => l_text,
                    po_blockade           => l_blockade,
                    po_busstyp            => l_busstyp,
                    po_currency_sap       => l_currency_header,
                    po_leader_man_id      => l_leader_man_id
                );
                
                IF EXTRACT(MONTH FROM l_sap_cla_gen_row.ISSUE_DATE) = EXTRACT(MONTH FROM p_sap_cla_gen_row.ISSUE_DATE) THEN
                    l_nullcode                                       :='01';
                ELSE
                    l_nullcode :='02';
                END IF;
                --IP CLA006 no aplica ¿?  
                  
                  /*INI defect 170*/
                  IF
                        l_doc_type = 'TL'
                  THEN
                        l_text   := 'REEMBOLSO SINIESTROS';
                  ELSE
                        l_text   := 'ANU ' || l_text;
                  END IF;
                  /*FIN defect 170*/                
                
                INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA001(
                    NCLAIM            => l_sap_cla_gen_row.CLAIM_NO,
                    NCASE_NUM         => 1,
                    NDEMAN_TYPE       => 1,
                    SBUSSITYP         => l_busstyp,
                    NDOC_TYPE         => NULL,
                    SSERIAL           => NULL,
                    SNUMBER           => NULL,
                    SRUC              => NULL,
                    DPASSDATE         => NULL,
                    DPROCINI          => NULL,
                    DPROCEND          => NULL,
                    NSTATUS           => 0,
                    NUSERCODE         => 8888,
                    DCOMPDATE         => l_sap_cla_gen_row.ISSUE_DATE,
                    NSEQUENCE_REF     => NULL,
                    NTRANSAC          => l_sap_cla_gen_row.ACC_DOC_ID,
                    SRPTA_ANU         => NULL,
                    SACTION           => p_sap_cla_gen_row.action_type,
--                    SGLOSA            => 'REEMBOLSO DE SINIESTROS',
                    SGLOSA            => l_text, --defect 170
                    NCOMPANY          => 2,
                    DOPERDATE         => l_sap_cla_gen_row.ISSUE_DATE,
                    DLEDGERDATE       => l_sap_cla_gen_row.ISSUE_DATE,
                    DCHANGEDATE       => l_sap_cla_gen_row.ISSUE_DATE,
--                    sdoc_type         => 'TL',
                    SDOC_TYPE         => l_doc_type, --defect 170
                    SREF_DOC          => l_sap_cla_gen_row.CLAIM_NO,
                    NPRIOR            => NULL,
                    NSISTORIGIN       => 5,
                    SDOC_SAP          => NULL,
                    SDOC_YEAR         => NULL,
                    DLEDGERDAT        => NULL,
                    SNULLCODE         => NULL,
                    NSEQUENCE_TRA     => p_sap_cla_gen_row.ID,
                    SCLAIM_CASE       => l_sap_cla_gen_row.CLAIM_NO,
                    NBRANCH           => l_sap_cla_gen_row.TECH_BRANCH,
                    NPOLICY           => TO_NUMBER(l_sap_cla_gen_row.POLICY_NO),
                    NCERTIF           => l_sap_cla_gen_row.DEPEND_POLICY_NO,
                    DOCCURDAT         => l_sap_cla_gen_row.CLAIM_EVENT_DATE,
                    SBRAND            => NULL,
                    SVEHTYPE          => NULL,
                    SREGIST           => NULL,
                    SCAUSE            => NULL,
                    SPLANILLA         => NULL,
                    SCLIENT_SAP       => l_sap_code,
                    SCLAIM_EXT        => NULL,
                    DRECEPTION_DATE   => NULL,
                    BANK_CODE         => NULL,
                    NRO_CTA           => NULL,
                    CURRENCY          => NULL,
                    CTA_TYPE          => NULL,
                    NSEQUENCE         => l_sequence
                  );
                --IP CLA006 no aplica ¿?  
                INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA002(
                    NITEM_NUM         => 1,
                    STIPPRC           => 6,
                    SPROVIDER         => NULL,
                    SACCOUNT          => NULL,
                    NTRANSAC          => NULL,
                    SBENEF            => NULL,
                    SBRANCH_POLICY    => NULL,
                    SOFFICE_SAP       => NULL,
                    DVENC_DATE        => NULL,
                    SPAYWAY           => NULL,
                    SBLOCKADE         => NULL,
                    SCLAIM_CASE       => NULL,
                    SCLIENAME         => NULL,
                    STAX_CODE         => NULL,
                    NCURRENCY         => NULL,
                    NAMOUNT           => NULL,
                    NAMOUNT_BASE      => NULL,
                    STYPE_CODE_WT     => NULL,
                    SDOC_SAP          => SUBSTR(l_sap_cla_gen_row.SAP_DOC_NUMBER,1,10),
                    SLEADER_CODE      => NULL,
                    SCLIENT           => NULL,
                    DLEDGERDAT        => p_sap_cla_gen_row.REVERSE_DATE,
                    STEXT             => NULL,
                    NOFFICE           => NULL,
                    DOCCURDAT         => NULL,
                    NCOUNTRY          => NULL,
                    NBRANCH_LED       => NULL,
                    NGEOGRAPHICZONE   => NULL,
                    NQUANTITY         => NULL,
                    SBASE             => NULL,
                    SBUSSIUNIT        => NULL,
                    SDOC_YEAR         => SUBSTR(l_sap_cla_gen_row.SAP_DOC_NUMBER,15,4),
                    SNULLCODE         => l_nullcode,
                    NCOMPANY          => 2,
                    PROFIT_CTR        => NULL,
                    NSEQUENCE         => l_sequence
                  );
                  
                  IF p_sap_cla_gen_row.IP_CODE = 'I013' THEN
                    INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA003(
                        NSEQUENCE => l_sequence,
                        NCOMPANY => 2,
                        NSISTORIGIN => 5,
                        NCLAIM => l_sap_cla_gen_row.CLAIM_NO,
                        NCASE_NUM => 1,
                        NDEMAN_TYPE => NULL,
                        NPRIOR => NULL,
                        DCOMPDATE => NULL,
                        DPASSDATE => NULL,
                        NTRANSAC => p_sap_cla_gen_row.UNCLEARING_ID,
                        DPROCINI => NULL,
                        DPROCEND => NULL,
                        NSTATUS => 0,
                        SMSGERROR => NULL,
                        SSEQUENCE_SAP => NULL,
                        NREINTENTOS => NULL
                    );
                  ELSE
                    INSIS_CUST_LPV.IIBPKGCLA.IIBPRCINSCLA003(
                        NSEQUENCE => l_sequence,
                        NCOMPANY => 2,
                        NSISTORIGIN => 5,
                        NCLAIM => l_sap_cla_gen_row.CLAIM_NO,
                        NCASE_NUM => 1,
                        NDEMAN_TYPE => NULL,
                        NPRIOR => NULL,
                        DCOMPDATE => NULL,
                        DPASSDATE => NULL,
                        NTRANSAC => l_sap_cla_gen_row.PAYMENT_ID,
                        DPROCINI => NULL,
                        DPROCEND => NULL,
                        NSTATUS => 0,
                        SMSGERROR => NULL,
                        SSEQUENCE_SAP => NULL,
                        NREINTENTOS => NULL
                      );
                    /* FIXME */
                    COMMIT;
                  END IF;
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERROR IN BLC_CLAIM_ANU. NO DATA FOUND');
                RAISE_APPLICATION_ERROR(-20013,'ERROR IN BLC_CLAIM_ANU. NO DATA FOUND');
            END IF;
        END IF;
    END IF;
  EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR IN BLC_CLAIM_INSERT. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
        RAISE_APPLICATION_ERROR(-20003,'ERROR IN BLC_CLAIM_INSERT. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
  END;
  
  --------------------------------------------------------------------------------
  -- Name: BLC_CLAIM_EXEC
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
  -- Input parameters:
  --     pi_table_name    VARCHAR2,
  --     pi_list_records  VARCHAR2
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
  PROCEDURE BLC_CLAIM_EXEC(
    pi_le_id        IN NUMBER,
    pi_list_records IN VARCHAR2)
  IS
    l_Context insis_sys_v10.SRVContext;
    l_RetContext insis_sys_v10.SRVContext;
    l_SrvErr insis_sys_v10.SrvErr;
    l_SrvErrMsg insis_sys_v10.SrvErrMsg;
    l_sap_cla_gen_row BLC_CLAIM_GEN%ROWTYPE;
    l_begin            INTEGER := 1;
    l_end              INTEGER;
    l_new_list_records VARCHAR2(240);
    l_list_records     VARCHAR2(240);
    l_value            VARCHAR2(25);
    l_username         VARCHAR2(25);
    l_id               NUMBER;
    l_ERROR_MESSAGE    VARCHAR2(250 CHAR);
    l_process_start    DATE;
    
    CURSOR sap_cla_gen_cur_list (l_id VARCHAR2, le_id NUMBER)
    IS
        SELECT *
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN CGEN
        WHERE CGEN.STATUS     = 'N'
        AND CGEN.ID           = l_id
        AND CGEN.LEGAL_ENTITY = le_id;
        
    CURSOR sap_cla_gen_cur (le_id NUMBER)
    IS
        SELECT *
        FROM INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN CGEN
        WHERE CGEN.STATUS     = 'N'
        AND CGEN.LEGAL_ENTITY = le_id;
    BEGIN
        insis_sys_v10.srv_context.SetContextAttrChar( l_Context, 'USERNAME', 'insis_gen_v10' );
        insis_sys_v10.srv_context.SetContextAttrChar( l_Context, 'USER_ENT_ROLE', 'InsisStaff' );
        insis_sys_v10.srv_events.sysEvent( insis_sys_v10.srv_events_system.GET_CONTEXT, l_Context, l_RetContext, l_srvErr);
        
        IF NOT insis_sys_v10.srv_error.rqStatus( l_srvErr ) THEN
            RETURN;
        END IF;
        
        SELECT SYS_CONTEXT ('USERENV', 'SESSION_USER') INTO l_username FROM DUAL;
    
        l_process_start := SYSDATE;
    
        BEGIN
            IF pi_list_records     IS NOT NULL THEN
                l_list_records       := pi_list_records;
        
                WHILE l_list_records IS NOT NULL
                LOOP
                    l_end                := INSTRC(l_list_records,',');
          
                    IF l_end              = 0 THEN
                        l_end              := LENGTH( l_list_records);
                        l_new_list_records := NULL;
                        l_value            := SUBSTR( l_list_records, l_begin , l_end);
                    ELSE
                        l_new_list_records := SUBSTR( l_list_records, l_end          +1,LENGTH(l_list_records));
                        l_value            := SUBSTR( l_list_records, l_begin , l_end-1 );
                    END IF;
          
                    l_list_records := l_new_list_records;
                    DBMS_OUTPUT.PUT_LINE (l_list_records);
          
                    OPEN sap_cla_gen_cur_list(l_value,pi_le_id);
                    LOOP
                        FETCH sap_cla_gen_cur_list INTO l_sap_cla_gen_row;
                        EXIT WHEN sap_cla_gen_cur_list%NOTFOUND OR sap_cla_gen_cur_list%NOTFOUND IS NULL;
                            l_id                                                              := l_sap_cla_gen_row.ID;
                            
                            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN
                            SET STATUS   = 'P',
                            UPDATED_BY = l_username ,
                            UPDATED_ON = SYSDATE
                            WHERE ID     = l_id;
                        
                            BLC_CLAIM_INSERT(l_sap_cla_gen_row);
                            
                            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN
                            SET STATUS   = 'S',
                            UPDATED_BY = l_username ,
                            UPDATED_ON = SYSDATE
                            WHERE ID     = l_id;
                            
                        COMMIT;
                    END LOOP;
                    CLOSE sap_cla_gen_cur_list;
                END LOOP;
            ELSE
                OPEN sap_cla_gen_cur(pi_le_id);
                LOOP
                    FETCH sap_cla_gen_cur INTO l_sap_cla_gen_row;
                    EXIT WHEN sap_cla_gen_cur%NOTFOUND OR sap_cla_gen_cur%NOTFOUND IS NULL;
                        l_id                                                    := l_sap_cla_gen_row.ID;
                        
                        UPDATE INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN
                        SET STATUS   = 'P',
                        UPDATED_BY = l_username ,
                        UPDATED_ON = SYSDATE
                        WHERE ID     = l_id;
                  
                        BLC_CLAIM_INSERT(l_sap_cla_gen_row);
                  
                        UPDATE INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN
                        SET STATUS   = 'S',
                        UPDATED_BY = l_username ,
                        UPDATED_ON = SYSDATE
                        WHERE ID     = l_id;
                  
                    COMMIT;
                END LOOP;
            END IF;
        EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE ('ERROR IN BLC_CLAIM_EXEC. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
            srv_error.SetSysErrorMsg( l_SrvErrMsg, 'BLC_CLAIM_EXEC', SQLERRM );
            l_ERROR_MESSAGE := 'ERROR IN BLC_CLAIM_EXEC' ||' SQLERRM=' ||SQLERRM ||' SQLCODE=' ||SQLCODE;
            --replace direct update with call BLC event for update in case of error --20.11.2019
            
            UPDATE INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_GEN
            SET STATUS   = 'E',
              UPDATED_BY = l_username ,
              UPDATED_ON = SYSDATE,
              ERROR_TYPE = 'IP_ERROR',
              ERROR_MSG  = l_ERROR_MESSAGE
            WHERE ID     = l_id;
            
            /*
             IF l_id IS NOT NULL
             THEN
                cust_intrf_util_pkg.Blc_Process_Ip_Result(
                    pi_header_id => l_id,
                    pi_header_table => 'BLC_CLAIM_GEN',
                    pi_status => 'E',
                    pi_sap_doc_number => NULL,
                    pi_error_type => 'IP_ERROR',
                    pi_error_msg => l_ERROR_MESSAGE,
                    pi_process_start => NVL(l_process_start,SYSDATE),
                    pi_process_end => SYSDATE);
             END IF;
            */
            COMMIT;
            RAISE_APPLICATION_ERROR(-20004,'ERROR IN BLC_CLAIM_EXEC. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
        RETURN;
        END;
    END;
  
  --------------------------------------------------------------------------------
  -- Name: BLC_CLAIM_PAY
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
  -- Purpose:  Procedure SP that sends the request for clearing or reverse of a payment
  --
  -- Input parameters:
  --     p_account_number   VARCHAR2
  --     p_sequence_tra     NUMBER
  --     p_operation_type   VARCHAR2
  --     p_rev_reason_code  VARCHAR2
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
  PROCEDURE BLC_CLAIM_PAY(
    p_account_number  IN VARCHAR2,
    p_sequence_tra    IN NUMBER,
    p_operation_type  IN VARCHAR2,
    p_rev_reason_code IN VARCHAR2)
  IS
    l_Context insis_sys_v10.SRVContext;
    l_RetContext insis_sys_v10.SRVContext;
    l_SrvErr insis_sys_v10.SrvErr;
    l_log_module   VARCHAR2(240);
    l_bank_stmt_id NUMBER;
    l_line_id      NUMBER;
    l_count_bs     NUMBER;
    l_bs_number    NUMBER;
    l_oper_date    DATE;
    l_bs_numb      NUMBER;
    l_bs_id        NUMBER;
    l_payment_prefix BLC_PAYMENTS.PAYMENT_PREFIX%TYPE;
    l_payment_number BLC_PAYMENTS.PAYMENT_NUMBER%TYPE;
    l_payment_suffix BLC_PAYMENTS.PAYMENT_SUFFIX%TYPE;
    l_amount insis_gen_blc_v10.blc_payments.amount%TYPE;
    l_ben_bank_code insis_gen_blc_v10.blc_payments.bank_code%TYPE;
    l_ben_bank_acct insis_gen_blc_v10.blc_payments.bank_account_code%TYPE;
    l_result VARCHAR2(30);
    l_bsl_status insis_gen_blc_v10.blc_bank_statement_lines.status%TYPE;
    l_bsl_pmnt_id insis_gen_blc_v10.blc_bank_statement_lines.payment_id%TYPE;
    l_bsl_clearing_id insis_gen_blc_v10.blc_bank_statement_lines.clearing_id%TYPE;
    l_bsl_err_type insis_gen_blc_v10.blc_bank_statement_lines.err_type%TYPE;
    l_bsl_err_message insis_gen_blc_v10.blc_bank_statement_lines.err_message%TYPE;
    l_username    VARCHAR2(50);
    p_currency    VARCHAR2(3);
    p_payment_id  NUMBER;
    g_le_id       NUMBER := 10000000;
    g_pmnt_org_id NUMBER := 10000001;
  BEGIN
    insis_sys_v10.srv_context.SetContextAttrChar( l_Context, 'USERNAME', 'insis_gen_v10' );
    insis_sys_v10.srv_context.SetContextAttrChar( l_Context, 'USER_ENT_ROLE', 'InsisStaff' );
    insis_sys_v10.srv_events.sysEvent( insis_sys_v10.srv_events_system.GET_CONTEXT, l_Context, l_RetContext, l_srvErr);
    
    IF NOT insis_sys_v10.srv_error.rqStatus( l_srvErr ) THEN
        RETURN;
    END IF;
    -- get current oper date
    
    l_oper_date    := NVL( blc_common_pkg.Get_Oper_Date( pi_org_id => g_LE_id ), blc_appl_cache_pkg.g_to_date );
    IF l_oper_date IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('err_message = oper date is null');
        RETURN;
    END IF;
    
    BEGIN
        SELECT PAYMENT_ID, CURRENCY
        INTO p_payment_id, p_currency
        FROM BLC_CLAIM_GEN gen
        WHERE gen.ID        = p_sequence_tra
        AND gen.PAYMENT_ID IS NOT NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            --RAISE_APPLICATION_ERROR(-20006,'BLC_CLAIM_PAY DATA NOT FOUND (PAYMENT ID). SEARCH VALUE:'||p_sequence_tra); -- Defect 398  
            p_payment_id := NULL;
    END;
        
 --BEGIN Defect 398 LPV MATRIX 27.05.2021  
 --Desembolso de Prestamos compensar Payment_id
    IF p_payment_id IS NULL THEN 
          BEGIN
               SELECT PAYMENT_ID, CURRENCY
               INTO p_payment_id, p_currency
               FROM BLC_LOAND_GEN gen
               WHERE gen.ID        = p_sequence_tra
               AND gen.PAYMENT_ID IS NOT NULL;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  RAISE_APPLICATION_ERROR(-20006,'BLC_CLAIM_PAY DATA NOT FOUND (PAYMENT ID). SEARCH VALUE:'||p_sequence_tra);
          END;           
    END IF;        
 --END Defect 398     
    IF p_payment_id IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('err_message = payment id is null');
        RETURN;
    END IF;
    
    -- check if BS for current operating date is allready created
    IF p_account_number = 'IN_SAP_BANK' THEN
        l_bs_numb        := 100;
    ELSE
        l_bs_numb := 200;
    END IF;
    
    IF p_currency <> 'PEN' THEN
        l_bs_numb   := l_bs_numb +1;
    END IF;
    
    l_bs_numb := l_bs_numb * 100000000 + to_number(TO_CHAR(l_oper_date,'yyyymmdd'));
    
    BEGIN
        SELECT MAX(bank_stmt_id)
        INTO l_bs_id
        FROM blc_bank_statements
        WHERE bank_stmt_num = l_bs_numb;
        
        l_bs_id            := NVL(l_bs_id,0);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007,'BLC_CLAIM_PAY NO DATA FOUND (bank_stmt_id). SEARCH VALUE:'||l_bs_numb);
    END;
    
    IF l_bs_id > 0 THEN
        srv_context.SetContextAttrNumber( l_Context, 'BANK_STMT_ID', srv_context.Integers_Format, l_bs_id );
        srv_context.SetContextAttrNumber( l_Context, 'BANK_STMT_NUM', srv_context.Integers_Format, NULL );
    ELSE
        srv_context.SetContextAttrNumber( l_Context, 'BANK_STMT_ID', srv_context.Integers_Format, NULL );
        srv_context.SetContextAttrNumber( l_Context, 'BANK_STMT_NUM', srv_context.Integers_Format, l_bs_numb );
    END IF;
    
    -- get payment amount
    BEGIN
        SELECT payment_prefix,
        payment_number,
        payment_suffix,
        amount,
        bank_code,
        bank_account_code
        INTO l_payment_prefix,
        l_payment_number,
        l_payment_suffix,
        l_amount,
        l_ben_bank_code,
        l_ben_bank_acct
        FROM insis_gen_blc_v10.blc_payments
        WHERE payment_id = p_payment_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20008,'BLC_CLAIM_PAY DATA NOT FOUND (payment amount). SEARCH VALUE:'||p_payment_id);
    END;
    
    -- Creation of a new line in related BS
    srv_context.SetContextAttrChar( l_Context, 'ACCOUNT_NUMBER',p_account_number);
    srv_context.SetContextAttrChar( l_Context, 'CURRENCY',p_currency);
    srv_context.SetContextAttrChar( l_Context, 'OPERATION_TYPE',p_operation_type);
    srv_context.SetContextAttrDate( l_Context, 'BS_DATE',srv_context.Date_Format,l_oper_date);
    srv_context.SetContextAttrNumber( l_Context, 'AMOUNT', srv_context.Real_Number_Format, l_amount);
    srv_context.SetContextAttrChar( l_Context, 'BANK_CODE_BEN', l_ben_bank_code);
    srv_context.SetContextAttrChar( l_Context, 'BANK_ACCOUNT_BEN', l_ben_bank_acct );
    srv_context.SetContextAttrChar( l_Context, 'PAYMENT_PREFIX',l_payment_prefix);
    srv_context.SetContextAttrChar( l_Context, 'PAYMENT_NUMBER',l_payment_number);
    srv_context.SetContextAttrChar( l_Context, 'PAYMENT_SUFFIX',l_payment_suffix);
    
    IF p_operation_type = 'REVERSE' THEN
        srv_context.SetContextAttrChar( l_Context, 'REV_REASON_CODE',p_rev_reason_code);
    END IF;
    
    srv_events.sysEvent( 'LOAD_BLC_BS_LINE', l_Context, l_RetContext, l_SrvErr );
    srv_context.GetContextAttrNumber( l_RetContext, 'BANK_STMT_ID', l_bank_stmt_id );
    srv_context.GetContextAttrNumber( l_RetContext, 'LINE_ID', l_line_id );
    --
    DBMS_OUTPUT.PUT_LINE('l_bank_stmt_id = '||l_bank_stmt_id);
    DBMS_OUTPUT.PUT_LINE('l_line_id = '||l_line_id);
    
    IF l_SrvErr IS NOT NULL THEN
        FOR r IN l_SrvErr.first..l_SrvErr.last
            LOOP
                DBMS_OUTPUT.PUT_LINE(l_SrvErr(r).errfn||' - '||l_SrvErr(r).errcode||' - '||l_SrvErr(r).errmessage);
            END LOOP;
    END IF;
    
    IF NOT srv_error.rqStatus( l_SrvErr ) THEN
        ROLLBACK;
    ELSE
        -- execute BS line
        srv_context.SetContextAttrNumber( l_Context, 'LEGAL_ENTITY_ID', srv_context.Integers_Format, g_le_id );
        srv_context.SetContextAttrNumber( l_Context, 'ORG_ID', srv_context.Integers_Format, g_pmnt_org_id );
        srv_context.SetContextAttrNumber( l_Context, 'BANK_STMT_ID', srv_context.Integers_Format, l_bank_stmt_id );
        -- run for first execution of new entered bank statement
        IF l_bs_id = 0 THEN
            srv_context.SetContextAttrNumber( l_Context, 'LINE_ID', srv_context.Integers_Format, NULL );
            srv_events.sysEvent( 'PROCESS_BLC_BANK_STATEMENT', l_Context, l_RetContext, l_SrvErr );
        ELSE
            -- run for next execution of bank statement to process new or with error lines, if need partucular line then set LINE_ID
            srv_context.SetContextAttrNumber( l_Context, 'LINE_ID', srv_context.Integers_Format, l_line_id );
            srv_events.sysEvent( 'EXECUTE_BLC_BANK_STATEMENT', l_Context, l_RetContext, l_SrvErr );
        END IF;
        
        srv_context.GetContextAttrChar( l_RetContext, 'PROCEDURE_RESULT', l_result );
        DBMS_OUTPUT.PUT_LINE('l_result = '||l_result);
      
        IF l_SrvErr IS NOT NULL THEN
            FOR r IN l_SrvErr.first..l_SrvErr.last
                LOOP
                    DBMS_OUTPUT.PUT_LINE(l_SrvErr(r).errfn||' - '||l_SrvErr(r).errcode||' - '||l_SrvErr(r).errmessage);
                END LOOP;
        END IF;
      
        IF NOT srv_error.rqStatus( l_SrvErr ) THEN
            ROLLBACK;
        ELSE
            -- Get information for the result of execution of BS line
            SELECT status,
            payment_id,
            clearing_id,
            err_type,
            err_message
            INTO l_bsl_status,
            l_bsl_pmnt_id,
            l_bsl_clearing_id,
            l_bsl_err_type,
            l_bsl_err_message
            FROM INSIS_GEN_BLC_V10.BLC_BANK_STATEMENT_LINES
            WHERE LINE_ID    = l_line_id;
            
            IF l_bsl_status <> 'P' THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('err_type = '||l_bsl_err_type);
                DBMS_OUTPUT.PUT_LINE('err_message = '||l_bsl_err_message);
                RAISE_APPLICATION_ERROR(-20000, l_bsl_err_message);
            ELSE
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('payment_id = '||l_bsl_pmnt_id);
                DBMS_OUTPUT.PUT_LINE('clearing_id = '||l_bsl_clearing_id);
            END IF;
        END IF;
    END IF;
  END;
  
  --------------------------------------------------------------------------------
  -- Name: BLC_CLAIM_CLO
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
  --     p_procinid      DATE
  --     p_procend       DATE
  --     p_status        NUMBER
  --     p_msgerror      VARCHAR2
  --     p_sequence_sap  VARCHAR2
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
  PROCEDURE BLC_CLAIM_CLO(
    p_sequence     IN NUMBER,
    p_procinid     IN DATE,
    p_procend      IN DATE,
    p_status       IN NUMBER,
    p_msgerror     IN VARCHAR2,
    p_sequence_sap IN VARCHAR2)
  IS
    l_status  VARCHAR2(1);
    l_ip_code VARCHAR2(25);
    l_Context insis_sys_v10.SRVContext;
    l_RetContext insis_sys_v10.SRVContext;
    l_SrvErr insis_sys_v10.SrvErr;
    l_err_message VARCHAR2(2000);
    l_err_type    VARCHAR2(30);
    
  BEGIN
    insis_sys_v10.srv_context.SetContextAttrChar( l_Context, 'USERNAME', 'insis_gen_v10' );
    insis_sys_v10.srv_context.SetContextAttrChar( l_Context, 'USER_ENT_ROLE', 'InsisStaff' );
    insis_sys_v10.srv_events.sysEvent( insis_sys_v10.srv_events_system.GET_CONTEXT, l_Context, l_RetContext, l_srvErr );
    IF NOT insis_sys_v10.srv_error.rqStatus( l_srvErr ) THEN
        RETURN;
    END IF;
    --remove direct update only call BLC event for update in case of error or success --20.11.2019
    /*
    CASE p_status
      WHEN 2 THEN
        l_status := 'T';
      WHEN 3 THEN
        l_status := 'E';
      ELSE
        l_status := 'E';
    END CASE;
    SELECT IP_CODE
    INTO l_ip_code
    FROM BLC_CLAIM_GEN
    WHERE ID     = BLC_CLAIM_CLO.p_sequence;
    IF l_ip_code = 'I011' OR l_ip_code = 'I013' THEN
      UPDATE BLC_CLAIM_GEN
      SET PROCESS_START_DATE    = BLC_CLAIM_CLO.p_procinid,
        PROCESS_END_DATE        = BLC_CLAIM_CLO.p_procend,
        STATUS                  = l_status,
        ERROR_MSG               = BLC_CLAIM_CLO.p_msgerror,
        REVERSAL_SAP_DOC_NUMBER = BLC_CLAIM_CLO.p_sequence_sap
      WHERE ID                  = BLC_CLAIM_CLO.p_sequence;
    ELSE
      UPDATE BLC_CLAIM_GEN
      SET PROCESS_START_DATE = BLC_CLAIM_CLO.p_procinid,
        PROCESS_END_DATE     = BLC_CLAIM_CLO.p_procend,
        STATUS               = l_status,
        ERROR_MSG            = BLC_CLAIM_CLO.p_msgerror,
        SAP_DOC_NUMBER       = BLC_CLAIM_CLO.p_sequence_sap
      WHERE ID               = BLC_CLAIM_CLO.p_sequence;
    END IF;
    COMMIT;
    srv_context.SetContextAttrNumber( l_Context, 'HEADER_ID', srv_context.Integers_Format, BLC_CLAIM_CLO.p_sequence );
    srv_context.SetContextAttrChar( l_Context, 'HEADER_TABLE', 'BLC_CLAIM_GEN' );
    IF l_status = 'T' THEN
      srv_context.SetContextAttrChar( l_Context, 'SAP_DOC_NUMBER', BLC_CLAIM_CLO.p_sequence_sap ); -- SUBSTRING ???
    ELSE
      srv_context.SetContextAttrChar( l_Context, 'ERROR_MSG', BLC_CLAIM_CLO.p_msgerror );
      srv_context.SetContextAttrChar( l_Context, 'ERROR_TYPE', 'SAP_ERROR' );
    END IF;
    srv_context.SetContextAttrChar( l_Context, 'STATUS', l_status );
    srv_context.SetContextAttrDate( l_Context, 'PROCESS_START_DATE', srv_context.Date_Format, BLC_CLAIM_CLO.p_procinid );
    srv_context.SetContextAttrDate( l_Context, 'PROCESS_END_DATE', srv_context.Date_Format, BLC_CLAIM_CLO.p_procend );
    srv_events.sysEvent( 'CUST_BLC_PROCESS_IP_RESULT', l_Context, l_RetContext, l_SrvErr );
    IF l_SrvErr IS NOT NULL THEN
      FOR r IN l_SrvErr.first..l_SrvErr.last
      LOOP
        DBMS_OUTPUT.PUT_LINE(l_SrvErr(r).errfn||' - '||l_SrvErr(r).errcode||' - '||l_SrvErr(r).errmessage);
      END LOOP;
    END IF;
    IF NOT srv_error.rqStatus( l_SrvErr ) THEN
      ROLLBACK;
    ELSE
      COMMIT;
    END IF;
    */
    
    IF p_status = 2  THEN
        cust_intrf_util_pkg.Blc_Process_Ip_Result(
            pi_header_id => BLC_CLAIM_CLO.p_sequence,
            pi_header_table => 'BLC_CLAIM_GEN',
            pi_status => 'T',
            pi_sap_doc_number => BLC_CLAIM_CLO.p_sequence_sap,
            pi_error_type => NULL,
            pi_error_msg => NULL,
            pi_process_start => BLC_CLAIM_CLO.p_procinid,
            pi_process_end => BLC_CLAIM_CLO.p_procend);
    ELSE
       cust_intrf_util_pkg.Blc_Process_Ip_Result(
            pi_header_id => BLC_CLAIM_CLO.p_sequence,
            pi_header_table => 'BLC_CLAIM_GEN',
            pi_status => 'E',
            pi_sap_doc_number => NULL,
            pi_error_type => 'SAP_ERROR',
            pi_error_msg => BLC_CLAIM_CLO.p_msgerror,
            pi_process_start => BLC_CLAIM_CLO.p_procinid,
            pi_process_end => BLC_CLAIM_CLO.p_procend);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR IN BLC_CLAIM_CLO');
        RAISE_APPLICATION_ERROR(-20005,'ERROR IN BLC_CLAIM_CLO. SQLERRM -> '||SQLERRM||' SQLCODE -> '||SQLCODE);
  END;
  
END;
/


