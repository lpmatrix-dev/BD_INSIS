CREATE OR REPLACE PROCEDURE INSIS_BLC_GLOBAL_CUST.CUST_EXEC_BDC_STRATEGIES ( pi_legal_entity_id IN NUMBER )
AS 
  l_SrvErr             SrvErr;
  l_err_message        VARCHAR2(2048);  
  l_count_updated_docs NUMBER;
  l_count_errors       NUMBER;
  l_err_doc_count      PLS_INTEGER;  -- LPV-1042
  --
  l_Context         SRVContext;
  l_RetContext      SRVContext;
BEGIN
    srv_context.SetContextAttrChar( l_Context, 'USERNAME', 'insis_gen_v10' );
    srv_context.SetContextAttrChar( l_Context, 'USER_ENT_ROLE', 'InsisStaff' );
    --
    srv_events.sysEvent( srv_events_system.GET_CONTEXT, l_Context, l_RetContext, l_srvErr);
    IF NOT srv_error.rqStatus( l_srvErr )
    THEN
       RETURN;
    END IF;
    
    LOOP
        l_count_updated_docs := 0;
        
        CUST_COLL_UTIL_PKG.Execute_BDC_Strategies ( pi_legal_entity_id => pi_legal_entity_id,
                                                    pi_org_id => NULL,
                                                    pi_to_date => NULL,
                                                    pi_agreement => NULL,
                                                    pi_account_id => NULL,
                                                    po_count_updated_docs => l_count_updated_docs,
                                                    po_count_errors       => l_err_doc_count, -- LPV-1042
                                                    pio_Err => l_SrvErr );
    
        IF NOT srv_error.rqStatus( l_SrvErr )
        THEN
            ROLLBACK;
            l_err_message := substr(l_SrvErr(l_SrvErr.FIRST).errmessage,1,2048);
            raise_application_error(-20000,l_err_message);
            EXIT;
        END IF;
        --
        COMMIT;
        --
        -- Begin  LPV-1042
        IF l_count_errors > 0
        THEN
            Raise_Application_Error( -20000, 'ERROR. See log table cust_bdc_error_log (' || l_err_doc_count || ')' );
            EXIT;
        END IF;
        -- End  LPV-1042
        --
        EXIT WHEN l_count_updated_docs = 0;
    END LOOP;
END CUST_EXEC_BDC_STRATEGIES;
/


