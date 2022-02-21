CREATE OR REPLACE PROCEDURE INSIS_BLC_GLOBAL_CUST."CUST_PROCESS_ACC_TRX" 
    ( pi_legal_entity_id  IN     NUMBER) 
IS
   l_SrvErr             SrvErr;
   l_err_message        VARCHAR2(2048);
BEGIN
  cust_acc_process_pkg.Process_Acc_Trx
   ( pi_acc_doc_id   => NULL,
     pi_le_id        => pi_legal_entity_id,
     pi_status       => cust_gvar.STATUS_VALID,
     pi_ip_code      => NULL,
     pi_imm_flag     => NULL,
     pi_batch_flag   => cust_gvar.FLG_YES,
     pio_Err         => l_SrvErr );  
  --    
  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     ROLLBACK;
     l_err_message := substr(l_SrvErr(l_SrvErr.FIRST).errmessage,1,2048);
     raise_application_error(-20000,l_err_message);
  END IF;
  --
  COMMIT;
END CUST_PROCESS_ACC_TRX;
/


