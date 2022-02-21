CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.BLC_APPL_WF_PKG AS

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains functions used during process of payment and transaction 
-- applications. Hire you can write custom logic or use some functions from 
-- blc packages
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Use_Tolerance
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
-- Purpose: Check if item type for passed billing item is defined to use tolerance
-- lookup set ITEM_TYPES/tag_0
--
-- Input parameters:
--     pi_item_id       NUMBER       Item Id
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Returns:
--     'Y' - in case that for item type have to use tolerance
--     'N' - in case that do not have to use tolerance
--
-- Usage: When apply receipt to know if calculate tolerance
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Use_Tolerance
   (pi_item_id   IN  NUMBER, 
    pio_Err      IN OUT SrvErr)
RETURN VARCHAR2
IS       
   l_SrvErrMsg  SrvErrMsg;
   l_log_module VARCHAR2(240);
   l_flag       VARCHAR2(30);
BEGIN   
   IF srv_blc_data.gItemRecord.item_id IS NULL OR srv_blc_data.gItemRecord.item_id <> pi_item_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN 'N';
   END IF;
  
   IF srv_blc_data.gItemRecord.item_type IS NOT NULL
   THEN
      l_flag := insis_gen_blc_v10.blc_common_pkg.Get_Lookup_Tag_Value 
                                    ( 'ITEM_TYPES', --pi_lookup_set,
                                      srv_blc_data.gItemRecord.item_type, --pi_lookup_code,
                                      srv_blc_data.gItemRecord.legal_entity_id, --pi_org_id,
                                      NULL, --pi_lookup_value_id
                                      0 );
   END IF;
   --
   RETURN nvl(l_flag, 'N');
   
END Use_Tolerance;

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Use_DA_FA_PSA
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
-- Purpose: Check if item type for passed billing item is defined to apply to
-- DA/FA/PSA lookup set ITEM_TYPES/tag_1
--
-- Input parameters:
--     pi_item_id       NUMBER       Item Id
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Returns:
--     'Y' - in case that for item type have to apply to DA/FA/PSA
--     'N' - in case that do not have to apply to DA/FA/PSA
--
-- Usage: When apply receipt to know if apply to DA/FA/PSA
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Use_DA_FA_PSA
   (pi_item_id   IN  NUMBER, 
    pio_Err      IN OUT SrvErr)
RETURN VARCHAR2
IS       
   l_SrvErrMsg  SrvErrMsg;
   l_log_module VARCHAR2(240);
   l_flag       VARCHAR2(30);
BEGIN   
   IF srv_blc_data.gItemRecord.item_id IS NULL OR srv_blc_data.gItemRecord.item_id <> pi_item_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN 'N';
   END IF;
   
   IF srv_blc_data.gItemRecord.item_type IS NOT NULL
   THEN
      l_flag := insis_gen_blc_v10.blc_common_pkg.Get_Lookup_Tag_Value 
                                  ( 'ITEM_TYPES', --pi_lookup_set,
                                    srv_blc_data.gItemRecord.item_type, --pi_lookup_code,
                                    srv_blc_data.gItemRecord.legal_entity_id, --pi_org_id,
                                    NULL, --pi_lookup_value_id
                                    1 );
   END IF;
   --
   RETURN nvl(l_flag, 'N');
   
END Use_DA_FA_PSA;

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Transfer_DA
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   05.07.2013  creation
--
-- Purpose: Check if item type for passed billing item is defined to
-- transfer DA amount to insurance system
-- lookup set ITEM_TYPES/tag_2, if empty default 'Y'
--
-- Input parameters:
--     pi_item_id       NUMBER       Item Id
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Returns:
--     'Y' - in case that for item type have to transfer DA to insurance system
--     'N' - in case that do not have to transfer DA to insurance system
--
-- Usage: When make application to know if transfer DA to insurance system
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Transfer_DA
   (pi_item_id   IN  NUMBER, 
    pio_Err      IN OUT SrvErr)
RETURN VARCHAR2
IS       
   l_SrvErrMsg  SrvErrMsg;
   l_log_module VARCHAR2(240);
   l_flag       VARCHAR2(30);
BEGIN   
   IF srv_blc_data.gItemRecord.item_id IS NULL OR srv_blc_data.gItemRecord.item_id <> pi_item_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN 'N';
   END IF;
   
   IF srv_blc_data.gItemRecord.item_type IS NOT NULL
   THEN
      l_flag := insis_gen_blc_v10.blc_common_pkg.Get_Lookup_Tag_Value 
                                  ( 'ITEM_TYPES', --pi_lookup_set,
                                    srv_blc_data.gItemRecord.item_type, --pi_lookup_code,
                                    srv_blc_data.gItemRecord.legal_entity_id, --pi_org_id,
                                    NULL, --pi_lookup_value_id
                                    2 );
   END IF;
   --
   RETURN nvl(l_flag, 'Y');
   
END Transfer_DA;

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Transfer_FA
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   05.07.2013  creation
--
-- Purpose: Check if item type for passed billing item is defined to
-- transfer FA amount to insurance system
-- lookup set ITEM_TYPES/tag_3, if empty default 'Y'
--
-- Input parameters:
--     pi_item_id       NUMBER       Item Id
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Returns:
--     'Y' - in case that for item type have to transfer DA to insurance system
--     'N' - in case that do not have to transfer FA to insurance system
--
-- Usage: When make application to know if transfer FA to insurance system
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Transfer_FA
   (pi_item_id   IN  NUMBER, 
    pio_Err      IN OUT SrvErr)
RETURN VARCHAR2
IS       
   l_SrvErrMsg  SrvErrMsg;
   l_log_module VARCHAR2(240);
   l_flag       VARCHAR2(30);
BEGIN   
   IF srv_blc_data.gItemRecord.item_id IS NULL OR srv_blc_data.gItemRecord.item_id <> pi_item_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN 'N';
   END IF;
   
   IF srv_blc_data.gItemRecord.item_type IS NOT NULL
   THEN
      l_flag := insis_gen_blc_v10.blc_common_pkg.Get_Lookup_Tag_Value 
                                  ( 'ITEM_TYPES', --pi_lookup_set,
                                    srv_blc_data.gItemRecord.item_type, --pi_lookup_code,
                                    srv_blc_data.gItemRecord.legal_entity_id, --pi_org_id,
                                    NULL, --pi_lookup_value_id
                                    3 );
   END IF;
   --
   RETURN nvl(l_flag, 'Y');
   
END Transfer_FA;

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Transfer_PSA
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   05.07.2013  creation
--
-- Purpose: Check if item type for passed billing item is defined to
-- transfer PSA amount to insurance system
-- lookup set ITEM_TYPES/tag_4, if empty default 'Y'
--
-- Input parameters:
--     pi_item_id       NUMBER       Item Id
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err          SrvErr       Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Returns:
--     'Y' - in case that for item type have to transfer PSA to insurance system
--     'N' - in case that do not have to transfer PSA to insurance system
--
-- Usage: When make application to know if transfer PSA to insurance system
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Transfer_PSA
   (pi_item_id   IN  NUMBER, 
    pio_Err      IN OUT SrvErr)
RETURN VARCHAR2
IS       
   l_SrvErrMsg  SrvErrMsg;
   l_log_module VARCHAR2(240);
   l_flag       VARCHAR2(30);
BEGIN   
   IF srv_blc_data.gItemRecord.item_id IS NULL OR srv_blc_data.gItemRecord.item_id <> pi_item_id
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_wf_pkg.Document', 'blc_doc_wf_pkg.DOC.Missing_Global_Data' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN 'N';
   END IF;
   
   IF srv_blc_data.gItemRecord.item_type IS NOT NULL
   THEN
      l_flag := insis_gen_blc_v10.blc_common_pkg.Get_Lookup_Tag_Value 
                                  ( 'ITEM_TYPES', --pi_lookup_set,
                                    srv_blc_data.gItemRecord.item_type, --pi_lookup_code,
                                    srv_blc_data.gItemRecord.legal_entity_id, --pi_org_id,
                                    NULL, --pi_lookup_value_id
                                    4 );
   END IF;
   --
   RETURN nvl(l_flag, 'Y');
   
END Transfer_PSA;

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Calculate_DA_FA_PSA
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
-- Purpose: Calculate deposit, forward and suspense amount
-- depend on available installments. Init legal entity before use procedure
--
-- Input parameters:
--     pi_source            VARCHAR   Item source
--     pi_agreement         VARCHAR   Item agreement
--     pi_component         VARCHAR   Item component
--     pi_detail            VARCHAR   Item detail
--     pi_item_id           NUMBER    Item_id
--     pi_account_id        NUMBER    Account Id
--     pi_payment_id        NUMBER    Payment Id
--     pi_payment_currency  VARCHAR   Payment currency
--     pi_payment_rate_type VARCHAR   Payment rate type
--     pi_payment_rate_date DATE      Payment rate date
--     pi_payment_rate      NUMBER    Payment rate
--     pi_apply_amount      NUMBER    Apply amount
--     pio_Err              SrvErr    Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     po_da_amount         NUMBER    DA amount for apply
--     po_fa_amount         NUMBER    FA amount for apply
--     po_psa_amount        NUMBER    PSA amount for apply
--     pio_Err              SrvErr    Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Usage: In Appy_DA_FA_PSA
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Calculate_DA_FA_PSA
   (pi_source            IN     VARCHAR2,
    pi_agreement         IN     VARCHAR2,
    pi_component         IN     VARCHAR2,
    pi_detail            IN     VARCHAR2,
    pi_item_id           IN     NUMBER,
    pi_account_id        IN     NUMBER,
    pi_payment_id        IN     NUMBER,
    pi_payment_currency  IN     VARCHAR2,
    pi_payment_rate_type IN     VARCHAR2,
    pi_payment_rate_date IN     DATE,
    pi_payment_rate      IN     NUMBER,
    pi_apply_amount      IN     NUMBER,
    po_da_amount         OUT    NUMBER,
    po_fa_amount         OUT    NUMBER,
    po_psa_amount        OUT    NUMBER, 
    pio_Err              IN OUT SrvErr) 
IS
    l_log_module        VARCHAR2(240);
    l_SrvErrMsg         SrvErrMsg;
    l_count             NUMBER;
    l_application_id    NUMBER; 
    l_trx_balance       NUMBER;
    l_inst_balance      NUMBER;
    l_fa_balance        NUMBER;
    l_fc_trx_balance    NUMBER;
    l_fc_inst_balance   NUMBER;
    l_fc_fa_balance     NUMBER;
    l_fa_amount         NUMBER;
    l_fc_fa_amount      NUMBER;
    l_DA_FA_PSA_flag    VARCHAR2(30);
BEGIN
    insis_gen_blc_v10.blc_appl_util_pkg.Calculate_DA_FA_PSA
           (pi_source,
            pi_agreement,
            pi_component,
            pi_detail,
            pi_item_id,
            pi_account_id,
            pi_payment_id,
            pi_payment_currency,
            pi_payment_rate_type,
            pi_payment_rate_date,
            pi_payment_rate,
            pi_apply_amount,
            po_da_amount,
            po_fa_amount,
            po_psa_amount, 
            pio_Err); 
END Calculate_DA_FA_PSA;

--------------------------------------------------------------------------------
-- Name: blc_appl_wf_pkg.Calculate_OnAcc_Unapply
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.09.2013  creation
--     Fadata   21.01.2015  changed - add parameter party
--                                    rq 1000009519
--
-- Purpose: Calculate if need to unapply on-account applications from some
-- application detail to apply to another on-account application detail or 
-- tolerance activity. Init legal entity before use procedure
--
-- Input parameters:
--     pi_source           VARCHAR   Item source
--     pi_agreement        VARCHAR   Item agreement (required)
--     pi_component        VARCHAR   Item component
--     pi_detail           VARCHAR   Item detail
--     pi_currency         VARCHAR   Item currency
--     pi_insr_type        VARCHAR   Insurance type
--     pi_party            VARCHAR   Party
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     po_tlrn_flag        VARCHAR   Y/N - Y if need to unapply from on-account 
--                                   and try to apply on tolerance
--     po_da_flag          VARCHAR   Y/N - Y if need to unapply from DA
--     po_fa_flag          VARCHAR   Y/N - Y if need to unapply from FA
--     po_psa_flag         VARCHAR   Y/N - Y if need to unapply from PSA
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In adjust account balances or before refund to racalculate balances
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Calculate_OnAcc_Unapply
   (pi_source     IN     VARCHAR2, 
    pi_agreement  IN     VARCHAR2,
    pi_component  IN     VARCHAR2,
    pi_detail     IN     VARCHAR2,
    pi_currency   IN     VARCHAR2,
    pi_insr_type  IN     VARCHAR2,
    pi_party      IN     VARCHAR2,
    po_tlrn_flag  OUT    VARCHAR2,
    po_da_flag    OUT    VARCHAR2,
    po_fa_flag    OUT    VARCHAR2,
    po_psa_flag   OUT    VARCHAR2,
    pio_Err       IN OUT SrvErr)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
   l_count             NUMBER;
BEGIN
   insis_gen_blc_v10.blc_appl_util_pkg.Calculate_OnAcc_Unapply
       (pi_source, 
        pi_agreement,
        pi_component,
        pi_detail,
        pi_currency,
        pi_insr_type, 
        pi_party,
        po_tlrn_flag,
        po_da_flag,
        po_fa_flag,
        po_psa_flag,
        pio_Err);                                                  
END Calculate_OnAcc_Unapply;

END BLC_APPL_WF_PKG;
/


