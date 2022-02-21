CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.BLC_DOC_WF_PKG AS 

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains functions used during process of document workflow. Hire
-- you can write custom logic or use some functions from predifined libraries
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: blc_doc_number_lib_pkg.Set_Number_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Execute rules for document number generation
--
-- Input parameters:
--     pi_doc_id     NUMBER                Document id
--     pio_notes     VARCHAR2              List of validation errors separated 
--                                         with ';'
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_notes     VARCHAR2              List of validation errors separated 
--                                         with ';'
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In billing process when validate document
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Number_Document
   (pi_doc_id  IN     NUMBER,
    pio_notes  IN OUT VARCHAR2,
    pio_Err    IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: blc_doc_wf_pkg.Validate_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Execute rules for document validation
--
-- Input parameters:
--     pi_doc_id     NUMBER                Document id
--     pio_notes     VARCHAR2              List of validation errors separated 
--                                         with ';'
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_doc       BLC_DOCUMENTS_TYPE    Document type
--     pio_notes     VARCHAR2              List of validation errors separated 
--                                         with ';'
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In billing process when validate document
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Document
   (pi_doc_id  IN     NUMBER,
    pio_notes  IN OUT VARCHAR2,
    pio_Err    IN OUT SrvErr);
    
--------------------------------------------------------------------------------
-- Name: blc_doc_wf_pkg.Approve_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Execute rules for document approval
--
-- Input parameters:
--     pi_doc_id     NUMBER                Document id
--     pio_notes     VARCHAR2              List of validation errors separated 
--                                         with ';'
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_notes     VARCHAR2              List of validation errors separated 
--                                         with ';'
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In billing process when approve document
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Approve_Document
   (pi_doc_id  IN     NUMBER,
    pio_notes  IN OUT VARCHAR2,
    pio_Err    IN OUT SrvErr);

--------------------------------------------------------------------------------
-- Name: blc_doc_wf_pkg.Post_Document
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Execute procedures for sending a document to accounting 
-- or external system
--
-- Input parameters:
--     pi_doc_id     NUMBER                Document id
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr               Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--    'Y'  - In case of successful processing, documnet is sent
--    'N' - In case of some errors
--
-- Usage: In billing process when complete document
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Post_Document
   (pi_doc_id  IN     NUMBER,
    pio_Err    IN OUT SrvErr)    
RETURN VARCHAR2;

--------------------------------------------------------------------------------
-- Name: blc_doc_wf_pkg.Get_BankAcc_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--
-- Purpose: Execute custom function for getting bank account type for given 
-- document
--
-- Input parameters:
--     pi_doc_id       NUMBER              Document Id
--     pio_Err         SrvErr              Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err         SrvErr              Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Returns:
--    bank account type: CASHDESK/BANKACCT
--
-- Usage: When need to now bank account type for a document
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A  
--------------------------------------------------------------------------------
FUNCTION Get_BankAcc_Type
   (pi_doc_id  IN     NUMBER,
    pio_Err    IN OUT SrvErr)
RETURN VARCHAR2;
--
END BLC_DOC_WF_PKG;
/


