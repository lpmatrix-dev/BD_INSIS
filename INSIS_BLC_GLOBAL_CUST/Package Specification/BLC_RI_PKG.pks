CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.BLC_RI_PKG AS
/**
 * Package for SAP Re-Insurance Interface
 * 
 * @headcom
 */
    
    /**
     * Executes the main interface program.
     * @param pi_le_id [IN] INSIS Org ID
     * @param pi_list_records [IN] List of BLC Document Identifiers (Comma-Separated)
     */
    PROCEDURE BLC_RI_EXEC (
        pi_le_id IN NUMBER,
        pi_list_records IN VARCHAR2
    );
           
    /**
     * Returns SAP Response to INSIS.
     * @param pi_nSequence [IN] Sequence Number Identifier
     * @param pi_dProcIni [IN] Process Start Date
     * @param pi_dProcEnd [IN] Process End Date
     * @param pi_nStatus [IN] Status Code
     * @param pi_sMsgError [IN] Error Message
     * @param pi_sSequence_SAP [IN] SAP Document Number
     */
    PROCEDURE BLC_RI_CLO (
        pi_nSequence IN NUMBER,
        pi_dProcIni IN DATE,
        pi_dProcEnd IN DATE,
        pi_nStatus IN NUMBER,
        pi_sMsgError IN VARCHAR2,
        pi_sSequence_SAP IN VARCHAR2
    );
    
     PROCEDURE BLC_CMP_EXEC (
        pi_le_id IN NUMBER,
        pi_list_records IN VARCHAR2
    ) ;
--
END BLC_RI_PKG;
--
/


