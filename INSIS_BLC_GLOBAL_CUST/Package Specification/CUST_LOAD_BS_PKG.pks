CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_LOAD_BS_PKG AS 

  PROCEDURE LOAD_BANK_STATEMENTS ( PI_LEGAL_ENTITY_ID IN NUMBER,
                                   PI_OPERATION_TYPE IN VARCHAR2,
                                   PI_PAYMENT_ID IN NUMBER DEFAULT NULL,
                                   PIO_ERR IN OUT SRVERR );
---------------------------------------------------------------------
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
                           PIO_ERR IN OUT SRVERR );
 --------------------------------------------------------------
END CUST_LOAD_BS_PKG;
/


