-- events
  INSERT INTO insis_sys_v10.srv_event_function (event_id,function_name,order_no,processing_component,processing_mode,timeout,dest_app) 
  VALUES ('CREATE_BLC_TRANSACTION','INSIS_BLC_GLOBAL_CUST.srv_cust_bo.ValidateNewAdjTrx',0,'DB','S',null,null);

  INSERT INTO insis_sys_v10.srv_event_function (event_id,function_name,order_no,processing_component,processing_mode,timeout,dest_app) 
  VALUES ('MODIFY_BLC_TRANSACTION','INSIS_BLC_GLOBAL_CUST.srv_cust_bo.ValidateNewAdjTrx',0,'DB','S',null,null);

  INSERT INTO insis_sys_v10.srv_event_function (event_id,function_name,order_no,processing_component,processing_mode,timeout,dest_app) 
  VALUES ('MODIFY_BLC_DOCUMENT','INSIS_BLC_GLOBAL_CUST.srv_cust_bo.SetModifyTrxYes',0,'DB','S',null,null);

-- msg
  INSERT INTO insis_sys_v10.srv_messages( msg_id, msg_type, msg_text )
  VALUES( 'cust_billing_pkg.VCT.ErrAmnt', 'ERROR', 'The amount of manual transaction #1 must be less than #2' );


COMMIT;