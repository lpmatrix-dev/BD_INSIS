CREATE OR REPLACE PROCEDURE INSIS_BLC_GLOBAL_CUST.CUST_TRANSFER_PROFORMA_HIGH 
    ( pi_legal_entity_id  IN     NUMBER) 
IS
   l_SrvErr             SrvErr;
   l_err_message        VARCHAR2(2048);
   l_procedure_result   VARCHAR2(30);
BEGIN
  cust_intrf_util_pkg.Transfer_Acct_Info
   (pi_le_id             => pi_legal_entity_id,
    pi_table_name        => 'BLC_PROFORMA_GEN',
    pi_ip_code           => NULL,
    pi_action_type       => NULL,
    pi_priority          => 'HIGH',
    pi_ids               => NULL,
    po_procedure_result  => l_procedure_result,
    pio_Err              => l_SrvErr);  
  --    
  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     ROLLBACK;
     l_err_message := substr(l_SrvErr(l_SrvErr.FIRST).errmessage,1,2048);
     raise_application_error(-20000,l_err_message);
  ELSIF l_procedure_result = cust_gvar.FLG_ERROR
  THEN
     ROLLBACK;
     l_err_message := 'Integration for transfer high priority proforma accounting in SAP return error';
     raise_application_error(-20000,l_err_message);
  END IF;
  --
  COMMIT;
END CUST_TRANSFER_PROFORMA_HIGH;
/


