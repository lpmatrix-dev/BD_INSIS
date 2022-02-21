CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.BLC_DOC_WF_PKG AS

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
    pio_Err    IN OUT SrvErr)
IS  
   l_SrvErrMsg       SrvErrMsg;
BEGIN
   IF srv_blc_data.gDocumentRecord.doc_id IS NULL OR srv_blc_data.gDocumentRecord.doc_id <> pi_doc_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN;
   END IF;
   --
   insis_gen_blc_v10.blc_doc_number_lib_pkg.Set_Number_Document(pio_notes,pio_Err);
   --
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Set_Number_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
END Set_Number_Document;

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
    pio_Err    IN OUT SrvErr)
IS  
   l_SrvErrMsg       SrvErrMsg;
BEGIN
   IF srv_blc_data.gDocumentRecord.doc_id IS NULL OR srv_blc_data.gDocumentRecord.doc_id <> pi_doc_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN;
   END IF;
   --
   insis_gen_blc_v10.blc_doc_validate_lib_pkg.Validate_Document(pio_notes,pio_Err);
   --
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Set_Number_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
END Validate_Document;

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
    pio_Err    IN OUT SrvErr)
IS  
   l_SrvErrMsg       SrvErrMsg;
BEGIN
   IF srv_blc_data.gDocumentRecord.doc_id IS NULL OR srv_blc_data.gDocumentRecord.doc_id <> pi_doc_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN;
   END IF;
   --
   insis_gen_blc_v10.blc_doc_approve_lib_pkg.Approve_Document(pio_notes,pio_Err);
   --
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Approve_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
END Approve_Document;

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
RETURN VARCHAR2    
IS
    l_SrvErrMsg       SrvErrMsg;
BEGIN
   IF srv_blc_data.gDocumentRecord.doc_id IS NULL OR srv_blc_data.gDocumentRecord.doc_id <> pi_doc_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN 'N';
   END IF;
   
   IF NOT insis_gen_blc_v10.blc_doc_post_lib_pkg.Post_Document(pio_Err)
   THEN
      RETURN 'N';
   ELSE
      RETURN 'Y';
   END IF;                                  
   --
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Approve_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );  
END Post_Document;

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
RETURN VARCHAR2    
IS
    l_SrvErrMsg       SrvErrMsg;
    l_acc_type        VARCHAR2(30);
BEGIN
   IF srv_blc_data.gDocumentRecord.doc_id IS NULL OR srv_blc_data.gDocumentRecord.doc_id <> pi_doc_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN NULL;
   END IF;
   
   IF srv_blc_data.gDocumentRecord.attrib_0 = 'CASH'
   THEN
      l_acc_type := 'CASHDESK';
   ELSIF srv_blc_data.gDocumentRecord.attrib_0 = 'BANK'
   THEN
      l_acc_type := 'BANKACCT';
   ELSE
      l_acc_type := NULL;
   END IF;                                  
   --
   RETURN l_acc_type;
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Get_BankAcc_Type', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err ); 
     RETURN NULL;
END Get_BankAcc_Type;

END BLC_DOC_WF_PKG;
/


