CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_ACC_EXPORT_PKG AS

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains procedures preparing data for export for the purposes of
-- accounting transaction posting
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Process_SAP_Result
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      12.10.2017  Creation;
--
-- Purpose:
--    Process SAP result to the interface and BLC tables
--
-- Input parameters:
--     pi_header_id        NUMBER(17,0)       Header Id  - ID in interface table
--     pi_header_table     VARCHAR2(30)       Interface table name (BLC_PROFORMA_GEN,..)
--     pi_line_number_from NUMBER(5,0)        Line number from
--     pi_line_number_to   NUMBER(5,0)        Line number to
--     pi_SAP_doc_number   VARCHAR2(25 CHAR)  SAP doc number contains 3 concatenated parts:
--                                             - SAP Document ID
--                                             - SAP Company
--                                             - SAP Year
--     pi_SAP_start_date   DATE               SAP execution start date
--     pi_SAP_end_date     DATE               SAP execution end date
--     pi_status           VARCHAR2(1)        Status - possible values:
--                                              - T - Transferred
--                                              - E - Error
--     pi_err_code         VARCHAR2(30)       Error type
--                                              - SAP_ERROR - returning from SAP
--                                              - IP_ERROR - returning from IP - not successfully send to SAP
--     pi_err_message      VARCHAR2(4000)     Error message
--     pio_Err             SrvErr             Specifies structure for passing back
--                                            the error code, error TYPE and
--                                            corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration to return some result from SAP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Process_SAP_Result
   (pi_header_id        IN     NUMBER,
    pi_header_table     IN     VARCHAR2,
    pi_line_number_from IN     NUMBER,
    pi_line_number_to   IN     NUMBER,
    pi_SAP_doc_number   IN     VARCHAR2,
    pi_SAP_start_date   IN     DATE,
    pi_SAP_end_date     IN     DATE,
    pi_status           IN     VARCHAR2,
    pi_err_code         IN     VARCHAR2 DEFAULT NULL,
    pi_err_message      IN     VARCHAR2,
    pio_Err             IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      27.10.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given doc_id
--    are selected, grouped and summed into tables BLC_PROFORMA_GEN - as
--    master table and into BLC_PROFORMA_ACC - as detailed.
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Proforma
   (pi_doc_id        IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Delete_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      25.11.2017  Creation;
--
-- Purpose:
--    Insert record for deletion of proforma into BLC_PROFORMA_GEN
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pi_acc_doc_prefix      VARCHAR2     Voucher doc prefix
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Delete_Proforma
   (pi_doc_id         IN     NUMBER,
    pi_acc_doc_id     IN     NUMBER,
    pi_reversed_id    IN     NUMBER,
    pi_acc_doc_prefix IN     VARCHAR2,
    po_header_id      OUT    NUMBER,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      26.11.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given payment_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_Pmnt
   (pi_payment_id    IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Rvrs_Claim_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      26.11.2017  Creation;
--
-- Purpose:
--    Insert record for reversing of payment into BLC_CLAIM_GEN
--
-- Input parameters:
--     pi_payment_id          NUMBER       Payment Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pi_acc_doc_prefix      VARCHAR2     Voucher doc prefix
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Rvrs_Claim_Pmnt
   (pi_payment_id     IN     NUMBER,
    pi_acc_doc_id     IN     NUMBER,
    pi_reversed_id    IN     NUMBER,
    pi_acc_doc_prefix IN     VARCHAR2,
    po_header_id      OUT    NUMBER,
    pio_Err           IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_Adj
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      29.10.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_Adj
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      29.10.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_ACCOUNT_GEN - as
--    master table and into BLC_ACCOUNT_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Account
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Prem_AC
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      27.10.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given doc_id
--    are selected, grouped and summed into tables BLC_PROFORMA_GEN - as
--    master table and into BLC_PROFORMA_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Prem_AC
   (pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_AC
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      10.12.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_AC
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Claim_Clr_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      19.12.2017  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for voucher doc_id
--    are selected, grouped and summed into tables BLC_CLAIM_GEN - as
--    master table and into BLC_CLAIM_ACC - as detailed.
--
-- Input parameters:
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Claim_Clr_Pmnt
    ( pi_acc_doc_id    IN     NUMBER,
      po_header_id     OUT    NUMBER,
      pio_Err          IN OUT SrvErr );

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Unclear_Pmnt
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      19.12.2017  Creation;
--
-- Purpose:
--    Insert record for reversing of clearing into BLC_CLAIM_GEN
--
-- Input parameters:
--     pi_clearing_id         NUMBER       Clearing Id
--     pi_payment_id          NUMBER       Payment Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Unclear_Pmnt
   (pi_clearing_id   IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    pi_reversed_id   IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_RI_Bill
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      02.01.2018  Creation;
--
-- Purpose:
--    Retrieves data from table insis_gen_blc_v10.BLC_GL_INSIS2GL.
--    All rows in status 'I' (initial, not transferred) for given doc_id
--    are selected, grouped and summed into tables BLC_REI_GEN - as
--    master table and into BLC_REI_ACC - as detailed.
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_RI_Bill
   (pi_doc_id        IN     NUMBER,
    pi_acc_doc_id    IN     NUMBER,
    po_header_id     OUT    NUMBER,
    pio_Err          IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: cust_acc_export_pkg.Insert_SAP_Delete_RI_Bill
--
-- Type: PROCEDURE
--
-- Subtype: DATA PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
-- Fadata      02.01.2018  Creation;
--
-- Purpose:
--    Insert record for deletion of RI bill into BLC_REI_GEN
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document Id
--     pi_acc_doc_id          NUMBER       Voucher doc Id
--     pi_reversed_id         NUMBER       Reversed header Id
--     pi_acc_doc_prefix      VARCHAR2     Voucher doc prefix
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_header_id           NUMBER      Interface header Id
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In integration scheduled programs
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Insert_SAP_Delete_RI_Bill
   (pi_doc_id         IN     NUMBER,
    pi_acc_doc_id     IN     NUMBER,
    pi_reversed_id    IN     NUMBER,
    pi_acc_doc_prefix IN     VARCHAR2,
    po_header_id      OUT    NUMBER,
    pio_Err           IN OUT SrvErr);
--
END cust_acc_export_pkg;
/


