CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.BLC_CLAIM_PKG AS

PROCEDURE BLC_CLAIM_EXEC(
    pi_le_id        IN NUMBER,
	pi_list_records IN VARCHAR2
); 

PROCEDURE BLC_CLAIM_PAY (
	p_account_number  IN VARCHAR2,
	p_sequence_tra    IN NUMBER,
	p_operation_type  IN VARCHAR2,
	p_rev_reason_code IN VARCHAR2
);

PROCEDURE BLC_CLAIM_CLO(
	p_sequence IN NUMBER, 
	p_procinid IN DATE, 
	p_procend IN DATE, 
	p_status IN NUMBER, 
	p_msgerror IN VARCHAR2, 
	p_sequence_sap IN VARCHAR2
);

END BLC_CLAIM_PKG;
/


