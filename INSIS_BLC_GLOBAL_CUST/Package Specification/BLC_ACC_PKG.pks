CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.blc_acc_pkg AS

PROCEDURE BLC_ACC_EXEC(
    pi_le_id        IN NUMBER,
	pi_list_records IN VARCHAR2
);

PROCEDURE BLC_ACC_CLO(
	p_sequence IN NUMBER,
	p_procinid IN DATE,
	p_procend IN DATE,
	p_status IN NUMBER,
	p_msgerror IN VARCHAR2,
	p_sequence_sap IN VARCHAR2
);

END BLC_ACC_PKG;
/


