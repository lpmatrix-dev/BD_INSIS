CREATE OR REPLACE PROCEDURE INSIS_BLC_GLOBAL_CUST.CUST_CREATE_RI_BILL_VOUCHER
    ( pi_legal_entity_id  IN     NUMBER)
IS
   l_SrvErr             SrvErr;
   l_err_message        VARCHAR2(2048);
   l_acc_doc_id         NUMBER;
BEGIN
  cust_acc_process_pkg.Create_RI_Bill_Voucher
    ( pi_doc_id       => NULL,
      pi_le_id        => pi_legal_entity_id,
      pi_batch_flag   => cust_gvar.FLG_YES,
      po_acc_doc_id   => l_acc_doc_id,
      pio_Err         => l_SrvErr);
  --
  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     ROLLBACK;
     l_err_message := substr(l_SrvErr(l_SrvErr.FIRST).errmessage,1,2048);
     raise_application_error(-20000,l_err_message);
  END IF;
  --
  COMMIT;

  cust_acc_process_2_pkg.Create_CORI_Pmnt_Voucher
    ( pi_payment_id   => NULL,
      pi_le_id        => pi_legal_entity_id,
      pi_batch_flag   => cust_gvar.FLG_YES,
      po_acc_doc_id   => l_acc_doc_id,
      pio_Err         => l_SrvErr);
  --
  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     ROLLBACK;
     l_err_message := substr(l_SrvErr(l_SrvErr.FIRST).errmessage,1,2048);
     raise_application_error(-20000,l_err_message);
  END IF;
  --
  COMMIT;
END CUST_CREATE_RI_BILL_VOUCHER;
/


