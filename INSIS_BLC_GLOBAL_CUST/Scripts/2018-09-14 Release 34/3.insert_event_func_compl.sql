UPDATE insis_sys_v10.srv_event_function
SET processing_component = NULL 
WHERE event_id = 'COMPLETE_BLC_DOCUMENT'
AND function_name = 'INSIS_GEN_BLC_V10.srv_blc_bill_process_bo.AutoApproveDocument';

Insert into insis_sys_v10.srv_event_function (EVENT_ID,FUNCTION_NAME,ORDER_NO,PROCESSING_COMPONENT,PROCESSING_MODE,TIMEOUT,DEST_APP) values ('COMPLETE_BLC_DOCUMENT','INSIS_BLC_GLOBAL_CUST.srv_cust_pas_bo.AutoApproveDocument',29,'DB','S',null,null);

COMMIT;




