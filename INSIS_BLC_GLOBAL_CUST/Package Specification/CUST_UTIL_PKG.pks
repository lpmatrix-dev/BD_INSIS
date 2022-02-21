CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_UTIL_PKG AS 
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains custom functions for manipulation of BLC objects
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: cust_util_pkg.Add_Proforma_Notes
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.04.2019  creation LPVS-108
--
-- Purpose: Insert action for PROFORMA document and changes in ATTRIB_2
--
-- Input parameters:
--
--       pi_table_name  VARCHAR2     Table Name
--       pi_pk_value    NUMBER       Primary key value (doc_id)
--       pi_text        VARCHAR2     Note text (attrib_2)
--       pio_Err        SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
-- Output parameters:
--     pio_Err          SrvErr        Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Usage: event UPDATE_BLC_ATTRIBUTES
--------------------------------------------------------------------------------
PROCEDURE Add_Proforma_Notes( pi_table_name  IN     VARCHAR2,
                              pi_pk_value    IN     NUMBER,
                              pi_text        IN     VARCHAR2,
                              po_sbstr_text     OUT VARCHAR2,
                              pio_Err        IN OUT SrvErr );
--
END CUST_UTIL_PKG;
/


