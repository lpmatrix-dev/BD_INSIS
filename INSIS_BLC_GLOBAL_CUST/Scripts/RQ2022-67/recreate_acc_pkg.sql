DECLARE
  PI_ACC_METHOD   VARCHAR2(200);
  PO_NEW_PKG_NAME VARCHAR2(200);
  PIO_ERR         INSIS_SYS_V10.SRVERR;
  l_value         VARCHAR2(200);
  l_sql           VARCHAR2(2000);
BEGIN
  PI_ACC_METHOD := 'LPV';
  PO_NEW_PKG_NAME := NULL;
  PIO_ERR := NULL;

  SELECT param_value INTO l_value
  FROM insis_sys_v10.srv_system_params
  WHERE param_name = 'DATABASE_VERSION';

  IF REPLACE( SUBSTR( l_value, 1, INSTR( l_value, '.', 1, 3 ) ), '.' ) < 1054
  THEN  
      l_sql := 'BEGIN INSIS_GEN_BLC_V10.blc_sla_create_acc_pkg.Create_Accaunting_Pkg(:1, :2, :3); END;';
  ELSE
      l_sql := 'BEGIN INSIS_GEN_BLC_V10.blc_sla_create_acc_pkg.Create_Accounting_Pkg(:1, :2, :3); END;';
  END IF;
  
  EXECUTE IMMEDIATE l_sql
     USING IN PI_ACC_METHOD, OUT PO_NEW_PKG_NAME, IN OUT PIO_ERR;

END;