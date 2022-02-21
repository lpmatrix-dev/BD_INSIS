CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.BLC_PMNT_WF_PKG AS

--------------------------------------------------------------------------------
-- Name: blc_pmnt_wf_pkg.Set_Number_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.06.2012  creation
--
-- Purpose: Execute rules for payment validation
--
-- Input parameters:
--     pi_payment_id NUMBER                Payment id
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In validate payment
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: Service is associated with event 'VALIDATE_BLC_PMNT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Payment
   (pi_payment_id  IN     NUMBER,
    pio_Err        IN OUT SrvErr)
IS
   l_SrvErrMsg       SrvErrMsg;
   l_payment_class   VARCHAR2(30);
   l_payment_date    DATE;
--
   l_usage_id     NUMBER;
   l_usage_name   VARCHAR2(30);
   --
   l_value_date   DATE;
BEGIN
   --for now is is not needed to do additional validations
   RETURN;
   
   SELECT payment_class, payment_date, usage_id,
          NVL(value_date, payment_date)
   INTO l_payment_class, l_payment_date, l_usage_id,
        l_value_date
   FROM insis_gen_blc_v10.blc_payments
   WHERE payment_id = pi_payment_id;
   --
   -- add 23.07.2013
   SELECT UPPER(usage_name) INTO l_usage_name
   FROM insis_gen_blc_v10.blc_bacc_usages
   WHERE usage_id = l_usage_id;
   IF INSTR(l_usage_name,'ZERO') > 0
   THEN
       RETURN;
   END IF;
   --
   -- add 06.08.2013
   SELECT nvl(max(nvl(value_date,to_date('01-01-1900','dd-mm-yyyy'))), l_value_date)
   INTO l_value_date
   FROM insis_gen_blc_v10.blc_remittances
   WHERE payment_id = pi_payment_id;
   --
   IF substr(l_payment_class,1,1) = 'I'
   THEN
     /* IF l_payment_date < sys_periods.get_sys_period_date
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Validate_Payment', 'blc_pmnt_wf_pkg.VP.Not_Open_Period');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      END IF;
      --
      IF l_payment_date > sys_days.get_open_date
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Validate_Payment', 'blc_pmnt_wf_pkg.VP.Greater_PmntDate');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      END IF; */
      --
      -- add 06.08.2013
      /*
      IF l_value_date > l_payment_date
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Validate_Payment', 'blc_appl_util_pkg.VP.Inv_Value_Date_IN');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      END IF;
      */
   -- add 06.08.2013   
     NULL;
   ELSIF substr(l_payment_class,1,1) = 'O' 
   THEN
      /*
      IF l_value_date < l_payment_date
      THEN
         srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Validate_Payment', 'blc_appl_util_pkg.VP.Inv_Value_Date_OUT');
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      END IF;
      */
      NULL;
   END IF;   
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Validate_Payment', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
END Validate_Payment;

--------------------------------------------------------------------------------
-- Name: blc_pmnt_wf_pkg.Reverse_Payment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.06.2012  creation
--
-- Purpose: Execute additional validations for payment revresal
--
-- Input parameters:
--     pi_payment_id NUMBER                Payment id
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In validate payment
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: Service is associated with event 'REVERSE_BLC_PMNT'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Reverse_Payment
   (pi_payment_id  IN     NUMBER,
    pio_Err        IN OUT SrvErr)
IS
   l_SrvErrMsg       SrvErrMsg;
   l_doc_ids         VARCHAR2(2000);
   l_log_module      VARCHAR2(240);
BEGIN
   l_doc_ids := NULL;
   FOR c_doc IN (SELECT bd.doc_id 
                 FROM insis_gen_blc_v10.blc_applications ba,
                      insis_gen_blc_v10.blc_transactions bt,
                      insis_gen_blc_v10.blc_documents bd
                 WHERE ba.source_payment = pi_payment_id
                 AND ba.target_trx = bt.transaction_id
                 AND bt.doc_id = bd.doc_id
                 AND bd.status = 'F'
                 GROUP BY bd.doc_id)
   LOOP
      IF l_doc_ids IS NULL
      THEN
         l_doc_ids := c_doc.doc_id;
      ELSE
         l_doc_ids := l_doc_ids||', '||c_doc.doc_id;
      END IF;   
   END LOOP; 
   IF l_doc_ids IS NOT NULL
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Reverse_Payment', 'blc_pmnt_wf_pkg.RP.Formal_Doc', l_doc_ids );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
   END IF;    
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_pmnt_wf_pkg.Reverse_Payment', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
END Reverse_Payment;

END BLC_PMNT_WF_PKG;
/


