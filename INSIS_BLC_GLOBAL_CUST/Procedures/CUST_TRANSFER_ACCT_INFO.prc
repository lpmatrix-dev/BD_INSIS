CREATE OR REPLACE PROCEDURE INSIS_BLC_GLOBAL_CUST.CUST_TRANSFER_ACCT_INFO 
    ( pi_legal_entity_id  IN     NUMBER,
      pi_table_name       IN     VARCHAR2,
      pi_priority         IN     VARCHAR2) 
IS
   l_SrvErr             SrvErr;
   l_err_message        VARCHAR2(2048);
   l_procedure_result   VARCHAR2(30);
BEGIN   
  cust_intrf_util_pkg.Transfer_Acct_Info
         (pi_le_id             =>     pi_legal_entity_id,
          pi_table_name        =>     pi_table_name,
          pi_ip_code           =>     NULL,
          pi_action_type       =>     NULL,
          pi_priority          =>     pi_priority,
          pi_ids               =>     NULL,
          po_procedure_result  =>     l_procedure_result,
          pio_Err              =>     l_srvErr);    
  --    
  IF NOT srv_error.rqStatus( l_SrvErr ) OR l_procedure_result = cust_gvar.FLG_ERROR
  THEN
     ROLLBACK;
     IF l_SrvErr IS NOT NULL
     THEN
        l_err_message := substr(l_SrvErr(l_SrvErr.FIRST).errmessage,1,2048);
     ELSE
        l_err_message := 'Transfer_Acct_Info returns ERROR';
     END IF;
     
     raise_application_error(-20000,l_err_message);
  END IF;
  --
  COMMIT;
END CUST_TRANSFER_ACCT_INFO;
/


