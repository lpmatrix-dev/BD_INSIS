CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_LOAD_BS_PKG AS
  C_LEVEL_STATEMENT     CONSTANT NUMBER := 1;
  C_LEVEL_PROCEDURE     CONSTANT NUMBER := 2;
  C_LEVEL_EVENT         CONSTANT NUMBER := 3;
  C_LEVEL_EXCEPTION     CONSTANT NUMBER := 4;
  C_LEVEL_ERROR         CONSTANT NUMBER := 5;
  C_LEVEL_UNEXPECTED    CONSTANT NUMBER := 6;

  C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'CUST_LOAD_BS_DEMO_PKG';
--------------------------------------------------------------------------------
  FUNCTION GET_BANK_STMT_NUMBER ( PI_FIRST_PART IN NUMBER )
  RETURN VARCHAR2 
  IS
    L_MAX_BS_NUMBER VARCHAR2(40);
    L_NEW_BS_NUMBER VARCHAR2(40);
  BEGIN
      SELECT MAX( BANK_STMT_NUM )
      INTO L_MAX_BS_NUMBER
      FROM BLC_BANK_STATEMENTS
      WHERE BANK_STMT_NUM LIKE PI_FIRST_PART || '%';
      
      IF L_MAX_BS_NUMBER IS NULL
      THEN
          RETURN( PI_FIRST_PART || '00001' );
      ELSE
          SELECT PI_FIRST_PART || 
                 LPAD( TO_NUMBER( SUBSTR( L_MAX_BS_NUMBER, LENGTH( PI_FIRST_PART ) + 1 ) ) + 1, 5, '0' )
          INTO L_NEW_BS_NUMBER
          FROM DUAL;
      END IF;
      
      RETURN( L_NEW_BS_NUMBER );
  END GET_BANK_STMT_NUMBER;
--------------------------------------------------------------------------------
  PROCEDURE CREATE_BS_HEADER ( PI_LEGAL_ENTITY_ID IN NUMBER,
                               PI_BANK_CODE IN VARCHAR2,
                               PI_BANK_ACCOUNT IN VARCHAR2,
                               PI_CURRENCY IN VARCHAR2,
                               PI_DATE IN DATE,
                               PO_BANK_STMT_ID OUT NUMBER,
                               PIO_ERR IN OUT SRVERR )
  IS
    L_LOG_MODULE VARCHAR2(240);
    L_SRVERRMSG SRVERRMSG;
    
    L_BANK_STMT_REC BLC_BANK_STATEMENTS_TYPE;
  BEGIN
      L_LOG_MODULE := C_DEFAULT_MODULE||'.CREATE_BS_HEADER';

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN OF PROCEDURE CREATE_BS_HEADER' );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BANK_CODE = ' || PI_BANK_CODE );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BANK_ACCOUNT = ' || PI_BANK_ACCOUNT );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_CURRENCY = ' || PI_CURRENCY );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_DATE = ' || PI_DATE );
                                  
      L_BANK_STMT_REC := NEW BLC_BANK_STATEMENTS_TYPE();
      
      L_BANK_STMT_REC.BANK_STMT_NUM := GET_BANK_STMT_NUMBER ( PI_FIRST_PART => 999 );
      L_BANK_STMT_REC.BANK_STMT_SEGMENT := 1;
      L_BANK_STMT_REC.TRANSACTION_REF := 'CITIMT940';
      L_BANK_STMT_REC.BANK_CODE := PI_BANK_CODE;
      L_BANK_STMT_REC.ACCOUNT_NUMBER := PI_BANK_ACCOUNT;
      L_BANK_STMT_REC.BALANCE_DATE := PI_DATE;
      L_BANK_STMT_REC.CURRENCY := PI_CURRENCY;
      L_BANK_STMT_REC.BANK_STMT_TYPE := 'C';
      L_BANK_STMT_REC.STATUS := 'N';
      L_BANK_STMT_REC.LEGAL_ENTITY_ID := PI_LEGAL_ENTITY_ID;
      
      IF NOT L_BANK_STMT_REC.INSERT_BLC_BANK_STATEMENTS( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                      C_LEVEL_EXCEPTION,
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );
                                         
          RETURN;
      END IF;
      
      PO_BANK_STMT_ID := L_BANK_STMT_REC.BANK_STMT_ID;
      
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PO_BANK_STMT_ID = ' || PO_BANK_STMT_ID );
      
      
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'END OF PROCEDURE CREATE_BS_HEADER' );
  EXCEPTION                                
    WHEN OTHERS THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.CREATE_BS_HEADER', SQLERRM );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_EXCEPTION,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID || ' - ' || 
                                  'PI_BANK_CODE = ' || PI_BANK_CODE || ' - ' || 
                                  'PI_BANK_ACCOUNT = ' || PI_BANK_ACCOUNT || ' - ' ||
                                  'PI_CURRENCY = ' || PI_CURRENCY || ' - ' ||
                                  'PI_DATE = ' || PI_DATE || ' - ' ||
                                  SQLERRM );        
  END CREATE_BS_HEADER;
--------------------------------------------------------------------------------
  FUNCTION GENERATE_TRX_DETAILS ( PI_OUR_PAYMENT_REC IN BLC_PAYMENTS_TYPE,
                                  PI_ORIG_AMOUNT IN NUMBER,
                                  PI_ORIG_CURRENCY IN VARCHAR2,
                                  PI_EXCHANGE_RATE IN NUMBER )
  RETURN VARCHAR2
  IS
    L_TRX_DETAILS VARCHAR2(4000);
    L_BANK_NAME VARCHAR2(400);
  BEGIN
      L_TRX_DETAILS := L_TRX_DETAILS || '/PYD/' || TO_CHAR( PI_OUR_PAYMENT_REC.PAYMENT_DATE, 'YYMMDD' );
      
      IF PI_ORIG_AMOUNT IS NOT NULL AND PI_ORIG_CURRENCY IS NOT NULL
      THEN
          L_TRX_DETAILS := L_TRX_DETAILS || '/OA/' || 
                           PI_ORIG_CURRENCY || REPLACE( TO_CHAR( PI_ORIG_AMOUNT ), '.', ',' );
          
      END IF;
      
      IF PI_EXCHANGE_RATE IS NOT NULL
      THEN
          L_TRX_DETAILS := L_TRX_DETAILS || '/ER/' || REPLACE( TO_CHAR( PI_EXCHANGE_RATE ), '.', ',' );
      END IF;
      
      IF SUBSTR( PI_OUR_PAYMENT_REC.PAYMENT_CLASS, 1, 1 ) = 'I'
      THEN
          IF PI_OUR_PAYMENT_REC.PARTY_NAME IS NOT NULL
          THEN
              L_TRX_DETAILS := L_TRX_DETAILS || '/BO1/' || PI_OUR_PAYMENT_REC.PARTY_NAME;
          END IF;
          
          IF PI_OUR_PAYMENT_REC.PARTY_ADDRESS IS NOT NULL
          THEN
              L_TRX_DETAILS := L_TRX_DETAILS || '/BO2/' || PI_OUR_PAYMENT_REC.PARTY_ADDRESS;
          END IF;
          
          IF PI_OUR_PAYMENT_REC.BANK_ACCOUNT_CODE IS NOT NULL
          THEN 
              L_TRX_DETAILS := L_TRX_DETAILS || '/BO1/' || 'DUMMY';
              
              L_TRX_DETAILS := L_TRX_DETAILS || '/BO/' || PI_OUR_PAYMENT_REC.BANK_ACCOUNT_CODE;
          END IF;
      ELSIF SUBSTR( PI_OUR_PAYMENT_REC.PAYMENT_CLASS, 1, 1 ) = 'O'
      THEN
          IF PI_OUR_PAYMENT_REC.PARTY_NAME IS NOT NULL
          THEN
              L_TRX_DETAILS := L_TRX_DETAILS || '/BN/' || PI_OUR_PAYMENT_REC.PARTY_NAME;
          END IF;
          
          IF PI_OUR_PAYMENT_REC.PARTY_ADDRESS IS NOT NULL
          THEN
              L_TRX_DETAILS := L_TRX_DETAILS || '/BN1/' || PI_OUR_PAYMENT_REC.PARTY_ADDRESS;
          END IF;
          
          IF PI_OUR_PAYMENT_REC.BANK_CODE IS NOT NULL
          THEN
              BEGIN
                  SELECT P.NAME 
                  INTO L_BANK_NAME
                  FROM P_BANKS B,
                       P_PEOPLE P
                  WHERE B.MAN_ID = P.MAN_ID
                    AND B.BANK_CODE = PI_OUR_PAYMENT_REC.BANK_CODE;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  L_BANK_NAME := NULL;
              END;
              
              IF L_BANK_NAME IS NOT NULL
              THEN
                  L_TRX_DETAILS := L_TRX_DETAILS || '/AB1/' || L_BANK_NAME;
                  
                  IF PI_OUR_PAYMENT_REC.BANK_ACCOUNT_CODE IS NOT NULL
                  THEN 
                      L_TRX_DETAILS := L_TRX_DETAILS || '/AB/' || PI_OUR_PAYMENT_REC.BANK_ACCOUNT_CODE;
                  END IF;
              ELSE
                  IF PI_OUR_PAYMENT_REC.BANK_ACCOUNT_CODE IS NOT NULL
                  THEN 
                      L_TRX_DETAILS := L_TRX_DETAILS || '/BI/' || PI_OUR_PAYMENT_REC.BANK_ACCOUNT_CODE;
                  END IF;
              END IF;
          END IF;
      END IF;
      
      RETURN( L_TRX_DETAILS );
  END GENERATE_TRX_DETAILS;
--------------------------------------------------------------------------------
  PROCEDURE CREATE_BS_LINE ( PI_OUR_PAYMENT_REC IN BLC_PAYMENTS_TYPE,
                             PI_BANK_STMT_ID IN NUMBER,
                             PI_BS_CURRENCY IN VARCHAR2,
                             PI_DATE IN DATE,
                             PI_OPERATION_TYPE IN VARCHAR2,
                             PIO_ERR IN OUT SRVERR )
  IS
    L_LOG_MODULE VARCHAR2(240);
    L_SRVERRMSG SRVERRMSG;
    
    L_BANK_STMT_LINE_REC BLC_BANK_STATEMENT_LINES_TYPE;
    
    L_ORIG_AMOUNT NUMBER;
    L_ORIG_CURRENCY VARCHAR2(3);
    L_RATE_PMNT_TO_BS_CURR NUMBER;
  BEGIN
      L_LOG_MODULE := C_DEFAULT_MODULE||'.CREATE_BS_LINE';

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN OF PROCEDURE CREATE_BS_LINE' );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_PAYMENT_ID = ' || PI_OUR_PAYMENT_REC.PAYMENT_ID );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BANK_STMT_ID = ' || PI_BANK_STMT_ID );
                                
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BS_CURRENCY = ' || PI_BS_CURRENCY );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_DATE = ' || PI_DATE );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_OPERATION_TYPE = ' || PI_OPERATION_TYPE );
                                  
      L_BANK_STMT_LINE_REC := NEW BLC_BANK_STATEMENT_LINES_TYPE();
      
      L_BANK_STMT_LINE_REC.BANK_STMT_ID := PI_BANK_STMT_ID;
      L_BANK_STMT_LINE_REC.VALUE_DATE := PI_DATE;
      L_BANK_STMT_LINE_REC.ENTRY_DATE := PI_DATE;
      
      IF PI_OPERATION_TYPE = 'CLEARING'
      THEN
          IF SUBSTR( PI_OUR_PAYMENT_REC.PAYMENT_CLASS, 1, 1 ) = 'I'
          THEN
              L_BANK_STMT_LINE_REC.D_C_TYPE := 'CR';
              L_BANK_STMT_LINE_REC.TRANSACTION_DESCR := '/CTC/776/SEPA DD CDTR CORE BLK';
          ELSIF SUBSTR( PI_OUR_PAYMENT_REC.PAYMENT_CLASS, 1, 1 ) = 'O'
          THEN
              L_BANK_STMT_LINE_REC.D_C_TYPE := 'DR';
              L_BANK_STMT_LINE_REC.TRANSACTION_DESCR := '/CTC/136/WIRE PYMT XB AUTO';
          END IF;
      
          L_BANK_STMT_LINE_REC.TR_SWIFT_CD := 'NTRF';
      ELSIF PI_OPERATION_TYPE = 'REVERSE'
      THEN
          IF SUBSTR( PI_OUR_PAYMENT_REC.PAYMENT_CLASS, 1, 1 ) = 'I'
          THEN
              L_BANK_STMT_LINE_REC.D_C_TYPE := 'DR';
              L_BANK_STMT_LINE_REC.TRANSACTION_DESCR := '/CTC/776/SEPA DD CDTR RFUND';
          ELSIF SUBSTR( PI_OUR_PAYMENT_REC.PAYMENT_CLASS, 1, 1 ) = 'O'
          THEN
              L_BANK_STMT_LINE_REC.D_C_TYPE := 'CR';
              L_BANK_STMT_LINE_REC.TRANSACTION_DESCR := '/CTC/136/SEPA PYMT REJECTED';
          END IF;
      
          L_BANK_STMT_LINE_REC.TR_SWIFT_CD := 'NRTI';
      END IF;
      
      IF PI_BS_CURRENCY = PI_OUR_PAYMENT_REC.CURRENCY
      THEN
          L_BANK_STMT_LINE_REC.AMOUNT := PI_OUR_PAYMENT_REC.AMOUNT;
      ELSE
          L_ORIG_AMOUNT := PI_OUR_PAYMENT_REC.AMOUNT;
          L_ORIG_CURRENCY := PI_OUR_PAYMENT_REC.CURRENCY;
      
      
          L_RATE_PMNT_TO_BS_CURR := BLC_COMMON_PKG.GET_CURRENCY_RATE
                                                        ( PI_OUR_PAYMENT_REC.CURRENCY,
                                                          PI_BS_CURRENCY,
                                                          BLC_APPL_CACHE_PKG.G_COUNTRY, 
                                                          PI_DATE,
                                                          NVL( PI_OUR_PAYMENT_REC.RATE_TYPE, 'FIXING' ),
                                                          PIO_ERR );
                  
              IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
              THEN
                  BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, C_LEVEL_EXCEPTION,
                        'PI_PMNT_CURR = '||PI_OUR_PAYMENT_REC.CURRENCY||' - '||
                        'PI_BS_CURRENCY = '||PI_BS_CURRENCY||' - '||
                        'COUNTRY = '||BLC_APPL_CACHE_PKG.G_COUNTRY||' - '||
                        'RATE_TYPE = '||NVL( PI_OUR_PAYMENT_REC.RATE_TYPE, 'FIXING' )||' - '||
                        'PI_DATE = '||PI_DATE||' - '||
                         PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );
              END IF;
              
              L_BANK_STMT_LINE_REC.AMOUNT := ROUND( L_ORIG_AMOUNT * L_RATE_PMNT_TO_BS_CURR, 2 );
      END IF;     
      
      L_BANK_STMT_LINE_REC.CUSTOMER_REF := PI_OUR_PAYMENT_REC.PAYMENT_NUMBER;
      
      L_BANK_STMT_LINE_REC.TRANSACTION_DETAILS := GENERATE_TRX_DETAILS 
                                                   ( PI_OUR_PAYMENT_REC => PI_OUR_PAYMENT_REC,
                                                     PI_ORIG_AMOUNT => L_ORIG_AMOUNT,
                                                     PI_ORIG_CURRENCY => L_ORIG_CURRENCY,
                                                     PI_EXCHANGE_RATE => L_RATE_PMNT_TO_BS_CURR );
      
      L_BANK_STMT_LINE_REC.STATUS := 'N';
      
      IF NOT L_BANK_STMT_LINE_REC.INSERT_BLC_BANK_STMT_LINES( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                      C_LEVEL_EXCEPTION,
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );
                                         
          RETURN;
      END IF;
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'END OF PROCEDURE CREATE_BS_LINE' );
                                  
  EXCEPTION                                
    WHEN OTHERS THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.CREATE_BS_LINE', SQLERRM );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_EXCEPTION,
                                  SQLERRM );    
  END CREATE_BS_LINE;
--------------------------------------------------------------------------------
  PROCEDURE SEND_PAYMENTS ( PI_LEGAL_ENTITY_ID IN NUMBER,
                            PI_DAYS_BEFORE IN NUMBER,
                            PIO_ERR IN OUT SRVERR )
  IS
    CURSOR APPROVED_PAYMENTS ( X_LEGAL_ENTITY_ID IN NUMBER,
                               X_DAYS_BEFORE IN NUMBER ) 
    IS SELECT PAYMENT_ID
       FROM BLC_PAYMENTS
       WHERE LEGAL_ENTITY = X_LEGAL_ENTITY_ID
         AND TRUNC( CREATED_ON ) BETWEEN TRUNC( SYSDATE - NVL( X_DAYS_BEFORE, 0 ) ) AND TRUNC( SYSDATE )
         AND SUBSTR( PAYMENT_CLASS, 1, 1 ) IN ( 'O', 'I' )
         AND PAYMENT_CLASS NOT IN ( 'OZ', 'IZ' )
         AND STATUS ='A';
         
    L_LOG_MODULE VARCHAR2(240);
    L_SRVERRMSG SRVERRMSG;
    L_SRVERR SRVERR;
    
    L_CONTEXT SRVCONTEXT;
    L_RETCONTEXT SRVCONTEXT;
  BEGIN
      L_LOG_MODULE := C_DEFAULT_MODULE||'.SEND_PAYMENTS';

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN OF PROCEDURE SEND_PAYMENTS' );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_DAYS_BEFORE = ' || PI_DAYS_BEFORE );
                                  
      FOR AP IN APPROVED_PAYMENTS ( PI_LEGAL_ENTITY_ID,
                                    PI_DAYS_BEFORE ) 
      LOOP
          L_CONTEXT := NULL;
          L_RETCONTEXT := NULL;
          
          SRV_CONTEXT.SETCONTEXTATTRCHAR( L_CONTEXT, 'PAYMENT_IDS', AP.PAYMENT_ID );
          
          SRV_EVENTS.SYSEVENT( 'SEND_BLC_PMNTS', L_CONTEXT, L_RETCONTEXT, L_SRVERR );
          
          IF NOT SRV_ERROR.RQSTATUS( L_SRVERR )
          THEN
              BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                          C_LEVEL_EXCEPTION,
                                          'AP.PAYMENT_ID = ' || AP.PAYMENT_ID || ' - ' || 
                                          L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE );

          END IF;    
          
      END LOOP;
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'END OF PROCEDURE SEND_PAYMENTS' );
                                  
  EXCEPTION
    WHEN OTHERS THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.SEND_PAYMENTS', SQLERRM );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_EXCEPTION,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID || ' - ' || 
                                  'PI_DAYS_BEFORE = ' || PI_DAYS_BEFORE || ' - ' || 
                                  SQLERRM );        
  END SEND_PAYMENTS;
--------------------------------------------------------------------------------
  PROCEDURE LOAD_BANK_STATEMENTS ( PI_LEGAL_ENTITY_ID IN NUMBER,
                                   PI_OPERATION_TYPE IN VARCHAR2,
                                   PI_PAYMENT_ID IN NUMBER DEFAULT NULL,
                                   PIO_ERR IN OUT SRVERR )
  IS
    CURSOR BS_HEADERS ( X_LEGAL_ENTITY_ID IN NUMBER,
                        X_DAYS_BEFORE IN NUMBER )
    IS SELECT BA.BANK_ACC_CODE, BA.BANK_CODE, NVL( BA.CURRENCY, 'EUR' ) CURRENCY,
              LISTAGG ( BP.PAYMENT_ID, ', ' ) WITHIN GROUP ( ORDER BY BP.PAYMENT_ID ) AS LIST_PAYMENT_IDS
       FROM BLC_PAYMENTS BP,
            BLC_BACC_USAGES BAU,
            BLC_BANK_ACCOUNTS BA
       WHERE BP.LEGAL_ENTITY = X_LEGAL_ENTITY_ID
         AND BP.PAYMENT_ID = NVL( PI_PAYMENT_ID, BP.PAYMENT_ID )
         AND TRUNC( BP.CREATED_ON ) BETWEEN TRUNC( SYSDATE - NVL( X_DAYS_BEFORE, 0 ) ) AND TRUNC( SYSDATE )
         AND BP.PAYMENT_CLASS NOT IN ( 'IZ', 'OZ' )
         AND BP.STATUS IN ( 'S', 'F' )
         AND BP.USAGE_ID = BAU.USAGE_ID
         AND BAU.BANK_ACC_ID = BA.BANK_ACC_ID
         AND BA.LEGAL_ENTITY = X_LEGAL_ENTITY_ID
         --AND BA.BANK_CODE LIKE 'CITI%'
       GROUP BY BA.BANK_ACC_CODE, BA.BANK_CODE, NVL( BA.CURRENCY, 'EUR' );
       
    CURSOR BS_LINES ( X_LIST_PAYMENT_IDS IN VARCHAR2 )
    IS SELECT PAYMENT_ID
       FROM BLC_PAYMENTS
       WHERE PAYMENT_ID IN ( SELECT * FROM TABLE( BLC_COMMON_PKG.CONVERT_LIST( X_LIST_PAYMENT_IDS ) ) );
       
    L_LOG_MODULE VARCHAR2(240);

    L_ERR_MESSAGE VARCHAR2(2000);
    L_EXP_ERROR EXCEPTION;
    L_SRVERRMSG SRVERRMSG;
    L_SRVERR SRVERR;
    
    L_DAYS_BEFORE NUMBER;
    L_OPER_DATE DATE;
    L_BANK_STMT_ID NUMBER;
    
    L_OUR_PAYMENT_REC BLC_PAYMENTS_TYPE;
  BEGIN
      BLC_LOG_PKG.INITIALIZE( PIO_ERR );
      IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
      THEN
          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;
      
      L_LOG_MODULE := C_DEFAULT_MODULE||'.LOAD_BANK_STATEMENTS';

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN OF PROCEDURE LOAD_BANK_STATEMENTS' );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_OPERATION_TYPE = ' || PI_OPERATION_TYPE );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_PAYMENT_ID = ' || PI_PAYMENT_ID );
                                  
      L_DAYS_BEFORE := BLC_COMMON_PKG.GET_SETTING_NUMBER_VALUE ( 'LOADBSDEMODAYSBEFORE',
                                                                 PIO_ERR );
                                                                 

      IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                      C_LEVEL_EXCEPTION,
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );

          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;    
      
      L_DAYS_BEFORE := 1000;
      
      L_OPER_DATE := BLC_COMMON_PKG.GET_SETTING_DATE_VALUE ( 'OPERDATE',
                                                              PIO_ERR,
                                                              PI_LEGAL_ENTITY_ID );
                                                               
      IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                      C_LEVEL_EXCEPTION,
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );

          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;
      
      BLC_APPL_CACHE_PKG.INIT_LE( PI_LEGAL_ENTITY_ID,
                                  PIO_ERR );
          
      IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                      C_LEVEL_EXCEPTION,
                                      'PI_LEGAL_ENTITY_ID = '||PI_LEGAL_ENTITY_ID||' - '||
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );
                                           
          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;  
      
/*      SEND_PAYMENTS ( PI_LEGAL_ENTITY_ID => PI_LEGAL_ENTITY_ID,
                      PI_DAYS_BEFORE => L_DAYS_BEFORE,
                      PIO_ERR => PIO_ERR );
                               
      IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                      C_LEVEL_EXCEPTION,
                                      'PI_LEGAL_ENTITY_ID = '||PI_LEGAL_ENTITY_ID||' - '||
                                      'L_DAYS_BEFORE = '||L_DAYS_BEFORE||' - '||
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );
                                           
          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;  */
      
      FOR BSH IN BS_HEADERS ( PI_LEGAL_ENTITY_ID,
                              L_DAYS_BEFORE )
      LOOP
          BEGIN
              L_SRVERR := NULL;
              L_BANK_STMT_ID := NULL;
              
              CREATE_BS_HEADER ( PI_LEGAL_ENTITY_ID => PI_LEGAL_ENTITY_ID,
                                 PI_BANK_CODE => BSH.BANK_CODE,
                                 PI_BANK_ACCOUNT => BSH.BANK_ACC_CODE,
                                 PI_CURRENCY => BSH.CURRENCY,
                                 PI_DATE => L_OPER_DATE,
                                 PO_BANK_STMT_ID => L_BANK_STMT_ID,
                                 PIO_ERR => L_SRVERR );
                                 
              IF NOT SRV_ERROR.RQSTATUS( L_SRVERR )
              THEN
                  BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                              C_LEVEL_EXCEPTION,
                                              L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE );

                  L_ERR_MESSAGE := L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE;
                  RAISE L_EXP_ERROR;
              END IF;
              
              FOR BSL IN BS_LINES ( BSH.LIST_PAYMENT_IDS )
              LOOP
                  L_OUR_PAYMENT_REC := NULL;
                  L_SRVERR := NULL;
                  
                  L_OUR_PAYMENT_REC := NEW BLC_PAYMENTS_TYPE( BSL.PAYMENT_ID, L_SRVERR );  
      
                  IF NOT SRV_ERROR.RQSTATUS( L_SRVERR )
                  THEN
                      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                                  C_LEVEL_EXCEPTION,
                                                  L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE );

                      L_ERR_MESSAGE := L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE;
                      RAISE L_EXP_ERROR;
                  END IF;
                  
                  CREATE_BS_LINE ( PI_OUR_PAYMENT_REC => L_OUR_PAYMENT_REC,
                                   PI_BANK_STMT_ID => L_BANK_STMT_ID,
                                   PI_BS_CURRENCY => BSH.CURRENCY,
                                   PI_DATE => L_OPER_DATE,
                                   PI_OPERATION_TYPE => PI_OPERATION_TYPE,
                                   PIO_ERR => L_SRVERR );
                                   
                  IF NOT SRV_ERROR.RQSTATUS( L_SRVERR )
                  THEN
                      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                                  C_LEVEL_EXCEPTION,
                                                  L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE );

                      L_ERR_MESSAGE := L_SRVERR(L_SRVERR.FIRST).ERRMESSAGE;
                      RAISE L_EXP_ERROR;
                  END IF;
                  
              END LOOP;
              
              COMMIT;
          EXCEPTION
            WHEN L_EXP_ERROR THEN
              SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.LOAD_BANK_STATEMENTS', L_ERR_MESSAGE );
              SRV_ERROR.SETERRORMSG( L_SRVERRMSG, L_SRVERR );
      
              BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                          C_LEVEL_EXCEPTION,
                                          'BSH.BANK_ACC_CODE = ' || BSH.BANK_ACC_CODE || ' - ' || 
                                          L_ERR_MESSAGE );
              ROLLBACK;
            WHEN OTHERS THEN
              SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.LOAD_BANK_STATEMENTS', SQLERRM );
              SRV_ERROR.SETERRORMSG( L_SRVERRMSG, L_SRVERR );

              BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                          C_LEVEL_EXCEPTION,
                                          'BSH.BANK_ACC_CODE = ' || BSH.BANK_ACC_CODE || ' - ' || 
                                          SQLERRM );        
             ROLLBACK;
          END;
      END LOOP;
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'END OF PROCEDURE LOAD_BANK_STATEMENTS' );
  EXCEPTION
    WHEN L_EXP_ERROR THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.LOAD_BANK_STATEMENTS', L_ERR_MESSAGE );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );
      
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                  C_LEVEL_EXCEPTION,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID || ' - ' || 
                                  L_ERR_MESSAGE );
      ROLLBACK;
    WHEN OTHERS THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.LOAD_BANK_STATEMENTS', SQLERRM );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_EXCEPTION,
                                  'PI_LEGAL_ENTITY_ID = ' || PI_LEGAL_ENTITY_ID || ' - ' || 
                                  SQLERRM );        
      ROLLBACK;
  END LOAD_BANK_STATEMENTS;
--------------------------------------------------------------------------------
  PROCEDURE LOAD_BS_LINE ( PI_BANK_STMT_ID IN NUMBER DEFAULT NULL,
                           PI_BANK_STMT_NUM IN NUMBER DEFAULT NULL,
                           PI_BANK_ACCOUNT IN VARCHAR2 DEFAULT NULL,
                           PI_BS_DATE IN DATE DEFAULT NULL,
                           PI_CURRENCY IN VARCHAR2 DEFAULT 'PEN',
                           PI_OPERATION_TYPE IN VARCHAR2,
                           PI_AMOUNT IN NUMBER,
                           PI_PAYMENT_PREFIX IN VARCHAR2 DEFAULT NULL,
                           PI_PAYMENT_NUMBER IN VARCHAR2,
                           PI_PAYMENT_SUFFIX IN VARCHAR2 DEFAULT NULL,
                           PI_POLICY_NUMBER IN VARCHAR2 DEFAULT NULL,
                           PI_DOC_PREFIX IN VARCHAR2 DEFAULT NULL, 
                           PI_DOC_NUMBER IN VARCHAR2 DEFAULT NULL,
                           PI_DOC_SUFFIX IN VARCHAR2 DEFAULT NULL, 
                           PI_PARTY_NAME_ORD IN VARCHAR2 DEFAULT NULL,
                           PI_USAGE_ID IN NUMBER DEFAULT NULL,
                           PI_REV_REASON_CODE IN VARCHAR2 DEFAULT NULL, 
                           PI_BANK_ACCOUNT_BEN IN VARCHAR2 DEFAULT NULL, 
                           PI_BANK_CODE_BEN IN VARCHAR2 DEFAULT NULL, 
                           PI_BANK_ACCOUNT_ORD IN VARCHAR2 DEFAULT NULL, 
                           PI_BANK_CODE_ORD IN VARCHAR2 DEFAULT NULL, 
                           PI_ATTRIB_0 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_1 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_2 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_3 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_4 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_5 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_6 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_7 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_8 IN VARCHAR2 DEFAULT NULL,
                           PI_ATTRIB_9 IN VARCHAR2 DEFAULT NULL,
                           PO_BANK_STMT_ID OUT NUMBER,
                           PO_LINE_ID OUT NUMBER,
                           PIO_ERR IN OUT SRVERR )
  IS 
    L_LOG_MODULE VARCHAR2(240);

    L_ERR_MESSAGE VARCHAR2(2000);
    L_EXP_ERROR EXCEPTION;
    L_SRVERRMSG SRVERRMSG;
    L_SRVERR SRVERR;
    
    L_BANK_STATEMENT_REC BLC_BANK_STATEMENTS_TYPE;
    L_BANK_STATEMENT_LINE_REC BLC_BANK_STATEMENT_LINES_TYPE;

  BEGIN 
      BLC_LOG_PKG.INITIALIZE( PIO_ERR );
      IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
      THEN
          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;
      
      L_LOG_MODULE := C_DEFAULT_MODULE||'.LOAD_BS_LINE';

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN OF PROCEDURE LOAD_BS_LINE' );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BANK_STMT_ID = ' || PI_BANK_STMT_ID );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BANK_STMT_NUM = ' || PI_BANK_STMT_NUM );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BANK_ACCOUNT = ' || PI_BANK_ACCOUNT );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_BS_DATE = ' || PI_BS_DATE );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_CURRENCY = ' || PI_CURRENCY );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_OPERATION_TYPE = ' || PI_OPERATION_TYPE );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_AMOUNT = ' || PI_AMOUNT );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_PAYMENT_NUMBER = ' || PI_PAYMENT_NUMBER );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_POLICY_NUMBER = ' || PI_POLICY_NUMBER );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_DOC_NUMBER = ' || PI_DOC_NUMBER );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PI_PARTY_NAME_ORD = ' || PI_PARTY_NAME_ORD );
                                  
      IF PI_BANK_STMT_ID IS NULL
      THEN
          L_BANK_STATEMENT_REC := NEW BLC_BANK_STATEMENTS_TYPE;
          
          L_BANK_STATEMENT_REC.BANK_STMT_NUM := PI_BANK_STMT_NUM;
          L_BANK_STATEMENT_REC.BANK_STMT_SEGMENT := 1;
          L_BANK_STATEMENT_REC.TRANSACTION_REF := 'N/A';
          L_BANK_STATEMENT_REC.BANK_CODE := 'N/A';
          L_BANK_STATEMENT_REC.ACCOUNT_NUMBER := PI_BANK_ACCOUNT;
          L_BANK_STATEMENT_REC.BALANCE_DATE := PI_BS_DATE;
          L_BANK_STATEMENT_REC.CURRENCY := PI_CURRENCY;
          L_BANK_STATEMENT_REC.BANK_STMT_TYPE := 'C';
          L_BANK_STATEMENT_REC.STATUS := 'N';
          
          IF NOT L_BANK_STATEMENT_REC.INSERT_BLC_BANK_STATEMENTS ( PIO_ERR )
          THEN
              BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                          C_LEVEL_EXCEPTION,
                                          PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );

              L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
              RAISE L_EXP_ERROR;
          END IF;
      ELSE
          L_BANK_STATEMENT_REC := NEW BLC_BANK_STATEMENTS_TYPE ( PI_BANK_STMT_ID, PIO_ERR );
          
          IF PI_BANK_ACCOUNT IS NOT NULL AND L_BANK_STATEMENT_REC.ACCOUNT_NUMBER <> PI_BANK_ACCOUNT
          THEN
             srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_load_bs_pkg.Load_BS_Line','cust_load_bs_pkg.LBSL.DiffAccout', PI_BANK_ACCOUNT||'|'||L_BANK_STATEMENT_REC.ACCOUNT_NUMBER );
             srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
          END IF;
          
          IF PI_CURRENCY IS NOT NULL AND L_BANK_STATEMENT_REC.CURRENCY <> PI_CURRENCY
          THEN
             srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_load_bs_pkg.Load_BS_Line','cust_load_bs_pkg.LBSL.DiffCurrency', PI_CURRENCY||'|'||L_BANK_STATEMENT_REC.CURRENCY );
             srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
          END IF;
          
          IF NOT SRV_ERROR.RQSTATUS( PIO_ERR )
          THEN
              BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                          C_LEVEL_EXCEPTION,
                                          PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );

              L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
              RAISE L_EXP_ERROR;
          END IF;
      END IF;
      
      
      L_BANK_STATEMENT_LINE_REC := NEW BLC_BANK_STATEMENT_LINES_TYPE;
      
      L_BANK_STATEMENT_LINE_REC.BANK_STMT_ID := L_BANK_STATEMENT_REC.BANK_STMT_ID;
      L_BANK_STATEMENT_LINE_REC.VALUE_DATE := L_BANK_STATEMENT_REC.BALANCE_DATE;
      L_BANK_STATEMENT_LINE_REC.ENTRY_DATE := L_BANK_STATEMENT_REC.BALANCE_DATE;
      L_BANK_STATEMENT_LINE_REC.AMOUNT := PI_AMOUNT;
      L_BANK_STATEMENT_LINE_REC.CUSTOMER_REF := 'N/A';
      L_BANK_STATEMENT_LINE_REC.STATUS := 'N';
      
      
      L_BANK_STATEMENT_LINE_REC.TR_SWIFT_CD := 'N/A';
      L_BANK_STATEMENT_LINE_REC.D_C_TYPE := 'N/A';
      --L_BANK_STATEMENT_LINE_REC.TRANSACTION_DESCR := 'N/A';
      L_BANK_STATEMENT_LINE_REC.TRANSACTION_DETAILS := 'N/A';
          
      L_BANK_STATEMENT_LINE_REC.OPERATION_TYPE := PI_OPERATION_TYPE;
      L_BANK_STATEMENT_LINE_REC.CLEARING_DATE := PI_BS_DATE;
      L_BANK_STATEMENT_LINE_REC.PAYMENT_PREFIX := PI_PAYMENT_PREFIX;
      L_BANK_STATEMENT_LINE_REC.PAYMENT_NUMBER := PI_PAYMENT_NUMBER;
      L_BANK_STATEMENT_LINE_REC.PAYMENT_SUFFIX := PI_PAYMENT_SUFFIX;
      L_BANK_STATEMENT_LINE_REC.PARTY_NAME_ORD := PI_PARTY_NAME_ORD;
      L_BANK_STATEMENT_LINE_REC.POLICY_NO := PI_POLICY_NUMBER;
      L_BANK_STATEMENT_LINE_REC.DOC_PREFIX := PI_DOC_PREFIX;
      L_BANK_STATEMENT_LINE_REC.DOC_NUMBER := PI_DOC_NUMBER;
      L_BANK_STATEMENT_LINE_REC.DOC_SUFFIX := PI_DOC_SUFFIX;
      L_BANK_STATEMENT_LINE_REC.USAGE_ID := PI_USAGE_ID;
      L_BANK_STATEMENT_LINE_REC.REV_REASON_CODE := PI_REV_REASON_CODE;
      
      L_BANK_STATEMENT_LINE_REC.BANK_ACCOUNT_BEN := PI_BANK_ACCOUNT_BEN;
      L_BANK_STATEMENT_LINE_REC.BANK_CODE_BEN := PI_BANK_CODE_BEN;
      L_BANK_STATEMENT_LINE_REC.BANK_ACCOUNT_ORD := PI_BANK_ACCOUNT_ORD;
      L_BANK_STATEMENT_LINE_REC.BANK_CODE_ORD := PI_BANK_CODE_ORD;
      
      L_BANK_STATEMENT_LINE_REC.ATTRIB_0 := PI_ATTRIB_0;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_1 := PI_ATTRIB_1;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_2 := PI_ATTRIB_2;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_3 := PI_ATTRIB_3;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_4 := PI_ATTRIB_4;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_5 := PI_ATTRIB_5;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_6 := PI_ATTRIB_6;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_7 := PI_ATTRIB_7;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_8 := PI_ATTRIB_8;
      L_BANK_STATEMENT_LINE_REC.ATTRIB_9 := PI_ATTRIB_9;
      
      
      IF NOT L_BANK_STATEMENT_LINE_REC.INSERT_BLC_BANK_STMT_LINES ( PIO_ERR )
      THEN
          BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                      C_LEVEL_EXCEPTION,
                                      PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE );

          L_ERR_MESSAGE := PIO_ERR(PIO_ERR.FIRST).ERRMESSAGE;
          RAISE L_EXP_ERROR;
      END IF;
      
      PO_BANK_STMT_ID := L_BANK_STATEMENT_REC.BANK_STMT_ID;
      PO_LINE_ID := L_BANK_STATEMENT_LINE_REC.LINE_ID;
      
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PO_BANK_STMT_ID = ' || PO_BANK_STMT_ID );
                                  
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'PO_LINE_ID = ' || PO_LINE_ID );                            
      
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_PROCEDURE,
                                  'END OF PROCEDURE LOAD_BS_LINE' );
  EXCEPTION
    WHEN L_EXP_ERROR THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.LOAD_BS_LINE', L_ERR_MESSAGE );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );
      
      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE, 
                                  C_LEVEL_EXCEPTION,
                                  'PI_BANK_STMT_ID = ' || PI_BANK_STMT_ID || ' - ' || 
                                  'PI_BANK_STMT_NUM = ' || PI_BANK_STMT_NUM || ' - ' || 
                                  'PI_BANK_ACCOUNT = ' || PI_BANK_ACCOUNT || ' - ' || 
                                  'PI_BS_DATE = ' || PI_BS_DATE || ' - ' || 
                                  'PI_CURRENCY = ' || PI_CURRENCY || ' - ' || 
                                  'PI_OPERATION_TYPE = ' || PI_OPERATION_TYPE || ' - ' || 
                                  'PI_AMOUNT = ' || PI_AMOUNT || ' - ' || 
                                  'PI_PAYMENT_NUMBER = ' || PI_PAYMENT_NUMBER || ' - ' || 
                                  'PI_POLICY_NUMBER = ' || PI_POLICY_NUMBER || ' - ' || 
                                  'PI_PARTY_NAME_ORD = ' || PI_PARTY_NAME_ORD || ' - ' || 
                                  L_ERR_MESSAGE );
    WHEN OTHERS THEN
      SRV_ERROR.SETSYSERRORMSG( L_SRVERRMSG, 'CUST_LOAD_BS_DEMO_PKG.LOAD_BANK_STATEMENTS', SQLERRM );
      SRV_ERROR.SETERRORMSG( L_SRVERRMSG, PIO_ERR );

      BLC_LOG_PKG.INSERT_MESSAGE( L_LOG_MODULE,
                                  C_LEVEL_EXCEPTION,
                                  'PI_BANK_STMT_ID = ' || PI_BANK_STMT_ID || ' - ' || 
                                  'PI_BANK_STMT_NUM = ' || PI_BANK_STMT_NUM || ' - ' || 
                                  'PI_BANK_ACCOUNT = ' || PI_BANK_ACCOUNT || ' - ' || 
                                  'PI_BS_DATE = ' || PI_BS_DATE || ' - ' || 
                                  'PI_CURRENCY = ' || PI_CURRENCY || ' - ' || 
                                  'PI_OPERATION_TYPE = ' || PI_OPERATION_TYPE || ' - ' || 
                                  'PI_AMOUNT = ' || PI_AMOUNT || ' - ' || 
                                  'PI_PAYMENT_NUMBER = ' || PI_PAYMENT_NUMBER || ' - ' || 
                                  'PI_POLICY_NUMBER = ' || PI_POLICY_NUMBER || ' - ' || 
                                  'PI_PARTY_NAME_ORD = ' || PI_PARTY_NAME_ORD || ' - ' || 
                                  SQLERRM );        
  END LOAD_BS_LINE;
--------------------------------------------------------------------------------
END CUST_LOAD_BS_PKG;
/


