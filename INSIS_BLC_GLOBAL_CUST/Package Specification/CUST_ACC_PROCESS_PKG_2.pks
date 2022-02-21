CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.cust_acc_process_pkg_2 AS

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains procedures for create and validate accounting transactions
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Proforma_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Create a document for the accounting events for given document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Proforma_Voucher( pi_doc_id       IN     NUMBER,
                                   pi_le_id        IN     NUMBER,
                                   pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                   po_acc_doc_id   OUT    NUMBER,
                                   pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Payment_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   26.11.2017  creation
--
-- Purpose: Create a document for the accounting events for given payment
--
-- Input parameters:
--     pi_payment_id       NUMBER    Payment Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Payment_Voucher( pi_payment_id   IN     NUMBER,
                                  pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  po_acc_doc_id   OUT    NUMBER,
                                  pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Claim_Adj_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.11.2017  creation
--
-- Purpose: Create a document for the accounting events for claim adjustments
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Claim_Adj_Voucher( pi_le_id        IN     NUMBER,
                                    pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                    pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Reserve_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.11.2017  creation
--
-- Purpose: Create a document for the accounting events for reserves
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Reserve_Voucher( pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Claim_AC_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.12.2017  creation
--
-- Purpose: Create a document for the accounting events for AC claim
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Claim_AC_Voucher( pi_le_id        IN     NUMBER,
                                   pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                   pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Prem_AC_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.12.2017  creation
--
-- Purpose: Create a document for the accounting events for AC premium
--
-- Input parameters:
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Prem_AC_Voucher( pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_Claim_CORI_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.12.2017  creation
--
-- Purpose: Create a document for the accounting events for given payment
-- clearing or for all clearing related events to a legal enity
--
-- Input parameters:
--     pi_clearing_id      NUMBER    Clearing Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Claim_CORI_Voucher( pi_clearing_id  IN     NUMBER,
                                     pi_le_id        IN     NUMBER,
                                     pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                     po_acc_doc_id   OUT    NUMBER,
                                     pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Create_RI_Bill_Voucher
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.01.2018  creation
--
-- Purpose: Create a document for the accounting events for given document
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_acc_doc_id       NUMBER    Created document Id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In process for transfer accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_RI_Bill_Voucher( pi_doc_id       IN     NUMBER,
                                  pi_le_id        IN     NUMBER,
                                  pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                                  po_acc_doc_id   OUT    NUMBER,
                                  pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Process_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: For given accounting voucher document validate created accounting
-- transactions and transfer data to the intreface tables. In case of some
-- accounting or validation errors delete created accounting transactions and
-- change event status to Z, add action with the error for the document. In case
-- of success approve document and update document number with created interface
-- header_id
--
-- Input parameters:
--     pi_acc_doc_id       NUMBER    Voucher doc Id
--     pi_le_id            NUMBER    Legal entity Id
--     pi_status           VARCHAR2  Document status
--     pi_ip_code          VARCHAR2  IP code (document preffix)
--     pi_imm_flag         VARCHAR2  Called for immediate bill
--     pi_batch_flag       VARCHAR2  Flag Y/N - call from batch process or not
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In schedule process for transfer accounting transaction or for
-- immediate creation of accounting transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_Acc_Trx( pi_acc_doc_id   IN     NUMBER,
                           pi_le_id        IN     NUMBER,
                           pi_status       IN     VARCHAR2,
                           pi_ip_code      IN     VARCHAR2,
                           pi_imm_flag     IN     VARCHAR2,
                           pi_batch_flag   IN     VARCHAR2 DEFAULT 'N',
                           pio_Err         IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Set_Result_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.10.2017  creation
--
-- Purpose: Process SAP result for given accounting voucher document. In case of
-- error set status to Reject. In case of transfer write the SAP doc number into
-- voucher document and original BLC object attribute
--
-- Input parameters:
--     pi_acc_doc_id       NUMBER    Voucher doc Id (required)
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - E - Error
--                                              - S - Success
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In procedure for process SAP result
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Result_Acc_Trx( pi_acc_doc_id     IN     NUMBER,
                              pi_SAP_doc_number IN     VARCHAR2,
                              pi_status         IN     VARCHAR2,
                              pi_err_message    IN     VARCHAR2,
                              pio_Err           IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_process_pkg_2.Recreate_Acc_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.11.2017  creation
--
-- Purpose: For given accounting voucher document in status R recreate accounting
-- transactions
--
-- Input parameters:
--     pi_acc_doc_id       NUMBER    Voucher doc Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     po_procedure_result VARCHAR2  Procedure result
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In UI to process accounting voucher documents in status R (Rejected)
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Recreate_Acc_Trx( pi_acc_doc_id       IN     NUMBER,
                            po_procedure_result OUT    VARCHAR2,
                            pio_Err             IN OUT SrvErr );

END cust_acc_process_pkg_2;
/
