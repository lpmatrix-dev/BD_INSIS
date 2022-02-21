CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_BILLING_PKG AS

--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during billing process. They can
-- be used in dynamic building of clauses for select installments,
-- create transactions and documents
--------------------------------------------------------------------------------

--==============================================================================
--               *********** Local Trace Routine **********
--==============================================================================
C_LEVEL_STATEMENT     CONSTANT NUMBER := 1;
C_LEVEL_PROCEDURE     CONSTANT NUMBER := 2;
C_LEVEL_EVENT         CONSTANT NUMBER := 3;
C_LEVEL_EXCEPTION     CONSTANT NUMBER := 4;
C_LEVEL_ERROR         CONSTANT NUMBER := 5;
C_LEVEL_UNEXPECTED    CONSTANT NUMBER := 6;

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_billing_pkg';
--==============================================================================

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Policy_Level
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Return policy level ENGAGEMENT/MASTER/INDIVIDUAL
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--       pi_annex_id       NUMBER   Annex ID
--       pi_policy_type    VARCHAR2 Policy type
--
-- Returns: policy level
--
-- Usage: In create, update blc item
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Level
    ( pi_policy_id   IN NUMBER,
      pi_annex_id    IN NUMBER,
      pi_policy_type IN VARCHAR2)
RETURN VARCHAR2
IS
    l_policy_type  VARCHAR2(30);
    l_policy_level VARCHAR2(30);
    --
    CURSOR CgetBillingAnnex (x_policy_id NUMBER, x_annex_id NUMBER) IS
    SELECT attr7
      FROM policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND attr7 IS NOT NULL
     ORDER BY decode(annex_id, x_annex_id, 0, 1), annex_id DESC;
BEGIN
    IF pi_policy_type IS NOT NULL
    THEN
       l_policy_type := pi_policy_type;
    ELSE
       OPEN CgetBillingAnnex(pi_policy_id, pi_annex_id);
       FETCH CgetBillingAnnex
         INTO l_policy_type;
       CLOSE CgetBillingAnnex;
    END IF;
    --
    l_policy_level := 'INDIVIDUAL';

    IF l_policy_type = 'CLIENT_GROUP'
    THEN
       l_policy_level := 'MASTER';
    ELSIF l_policy_type = 'ENGAGEMENT_GROUP'
    THEN
       l_policy_level := 'ENGAGEMENT';
    END IF;
    --
    RETURN l_policy_level;
EXCEPTION
  WHEN OTHERS THEN
     RETURN 'INDIVIDUAL';
END;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Master_Policy_Id
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Return master policy id
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--
-- Returns: master policy id
--
-- Usage: When need to know master policy id
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Master_Policy_Id
      (pi_policy_id IN NUMBER)
RETURN NUMBER
IS
  --
  l_eng_policy              p_eng_policies_type;
BEGIN
    --
    l_eng_policy := pol_engagement_types.get_policyengpolicies(pi_policy_id, NULL);
    --
    RETURN l_eng_policy.master_policy_id;
END Get_Master_Policy_Id;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Master_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Check if given policy is master policy
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--
-- Returns: Y/N
--
-- Usage: When need to know if master policy
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Master_Policy
      (pi_policy_id IN NUMBER)
RETURN VARCHAR2
IS
  --
  l_eng_policy              p_eng_policies_type;
  l_master_flag             VARCHAR2(1);
BEGIN
    --
    l_eng_policy := pol_engagement_types.get_policyengpolicies(pi_policy_id, NULL);

    IF l_eng_policy.eng_pol_type = 'MASTER'
    THEN
       l_master_flag := 'Y';
    ELSE
       l_master_flag := 'N';
    END IF;
    --
    RETURN l_master_flag;
END Is_Master_Policy;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Item_Agreement
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.04.2017  creation
--
-- Purpose: Return policy item agreement depend on policy level
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--       pi_annex_id       NUMBER   Annex ID
--       pi_policy_type    VARCHAR2 Policy type
--
-- Returns: agreement
--
-- Usage: In create, update blc item
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Item_Agreement
    ( pi_policy_id   IN NUMBER,
      pi_annex_id    IN NUMBER,
      pi_policy_type IN VARCHAR2)
RETURN VARCHAR2
IS
   l_policy_level      VARCHAR2(30);
   l_agreement         VARCHAR2(50);
   l_policy_type       p_policy_type;
   l_master_policy_id  NUMBER;
BEGIN
   l_policy_level := Get_Policy_Level
                      ( pi_policy_id,
                        pi_annex_id,
                        pi_policy_type);

   IF l_policy_level = 'INDIVIDUAL'
   THEN
      l_policy_type := pol_types.get_policy( pi_policy_id );
   ELSE
      l_master_policy_id := Get_Master_Policy_Id( pi_policy_id );
      l_policy_type := pol_types.get_policy(nvl(l_master_policy_id, pi_policy_id));
   END IF;

   l_agreement := nvl(l_policy_type.policy_no, l_policy_type.policy_id);
   --
   RETURN l_agreement;

END;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Create_Account
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an account to
-- modify some of the parameters.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_ACCOUNT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Create_Account ( pi_Context IN SrvContext,
                               pio_OutContext IN OUT SrvContext,
                               pio_Err IN OUT SrvErr )
IS
  l_date            DATE;
  l_log_module      VARCHAR2(240);
  l_account_id      NUMBER;
  l_SrvErrMsg       SrvErrMsg;
  l_account_type    VARCHAR2(30);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Pre_Create_Account';
    --
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Pre_Create_Account');

    srv_context.GetContextAttrNumber( pi_Context, 'ACCOUNT_ID', l_account_id );
    srv_context.GetContextAttrChar( pi_Context, 'ACCOUNT_TYPE', l_account_type );

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_account_id = '||l_account_id);

    IF l_account_type = 'HLDR'
    THEN
       l_date := sys_days.get_open_date;
       l_date := to_date('01-'||to_char(l_date,'mm-yyyy'),'dd-mm-yyyy');

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'l_date = '||to_char(l_date,'dd-mm-yyyy'));

       srv_context.SetContextAttrDate(pio_OutContext, 'BILL_DATE', srv_context.Date_Format, l_date);

       srv_context.SetContextAttrNumber(pio_OutContext, 'PAYMENT_FREQUENCY', srv_context.Integers_Format, 12);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'END of procedure Pre_Create_Account');
EXCEPTION
    WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Account', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_account_id = '||l_account_id||' - '|| SQLERRM);
END Pre_Create_Account;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Item_Comp
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called instead of core get item composite and do not use
-- agreement when need to get item from type POLICY
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'GET_BLC_ITEM_COMP'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Get_Item_Comp ( pi_Context IN SrvContext,
                          pio_OutContext IN OUT SrvContext,
                          pio_Err IN OUT SrvErr )
IS
    l_source           blc_items.SOURCE%TYPE;
    l_agreement        blc_items.agreement%TYPE;
    l_component        blc_items.component%TYPE;
    l_detail           blc_items.detail%TYPE;
    l_bill_currency    blc_items.bill_currency%TYPE;
    l_errmsg           srverrmsg;
    l_item_id          blc_items.item_id%TYPE;
    l_ref_type         VARCHAR2(300);
    l_log_module       VARCHAR2(240);
    --
    CURSOR c_item IS
      SELECT bi.item_id
      FROM blc_items bi
      WHERE bi.component = l_component
      AND bi.SOURCE = l_source
      AND bi.bill_currency = l_bill_currency
      AND bi.item_type = 'POLICY'
      ORDER BY bi.item_id DESC; --01.10.2018 to get the last created item when double items are created for the same policy_id
    --
    CURSOR c_item_on_acc IS
      SELECT bi.item_id
      FROM blc_items bi
      WHERE bi.item_type = 'ON-ACCOUNT';
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Get_Item_Comp';
    --
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Get_Item_Comp');

    pio_OutContext := pi_Context; -- TS 27.07.2017

    srv_context.GetContextAttrChar( pi_Context, 'SOURCE', l_source );
    srv_context.GetContextAttrChar( pi_Context, 'AGREEMENT', l_agreement );
    srv_context.GetContextAttrChar( pi_Context, 'COMPONENT', l_component );
    srv_context.GetContextAttrChar( pi_Context, 'DETAIL', l_detail );
    srv_context.GetContextAttrChar( pi_Context, 'BILL_CURRENCY', l_bill_currency );
    srv_context.GetContextAttrChar( pi_Context, 'REFERENCE_TYPE',l_ref_type );


    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_ref_type = '||l_ref_type);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_source = '||l_source);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_agreement = '||l_agreement);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_component = '||l_component);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_detail = '||l_detail);

    srv_blc_data.gItemRecord := NULL;
    srv_blc_data.gItemTable := NULL;

    IF l_source IS NOT NULL THEN
       -- Extract item data in global record

       IF l_ref_type = 'POLICY'
       THEN
          IF Is_Master_Policy(to_number(l_component)) = 'Y'
          THEN

             OPEN c_item_on_acc;
               FETCH c_item_on_acc
               INTO l_item_id;
             CLOSE c_item_on_acc;
          ELSE

             OPEN c_item;
               FETCH c_item
               INTO l_item_id;
             CLOSE c_item;
          END IF;

          --
          IF l_item_id IS NOT NULL
          THEN
             srv_blc_data.gItemRecord := blc_items_type( l_item_id,
                                                         pio_Err );
          END IF;
       ELSE
          srv_blc_data.gItemRecord := blc_items_type( l_source,
                                                      l_agreement,
                                                      l_component,
                                                      l_detail,
                                                      l_bill_currency,
                                                      pio_Err );
       END IF;

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
           pio_OutContext := NULL;
           --
           RETURN;
       END IF;
    ELSE
       srv_error.SetErrorMsg( l_errmsg, 'cust_billing_pkg.Get_Item_Comp', 'GetBLCItemComp_No_Source' );
       srv_error.SetErrorMsg( l_errmsg, pio_Err );
       pio_OutContext := NULL;
       RETURN;
    END IF;
    --
    -- Init OutContext;
    IF srv_blc_data.gItemRecord.item_id IS NULL
    THEN
        pio_OutContext := NULL;
        --
        RETURN;
    END IF;
    --
    -- Fill OutContext;
    IF NOT srv_blc_data.SetItemRecordInContext( pio_OutContext, pio_Err ) -- SetItemDataInContext( po_OutContext, pio_ErrMsg )
    THEN
        pio_OutContext := NULL;
        --
        RETURN;
    END IF;
    --
    srv_blc_data.gItemTable := blc_items_table( srv_blc_data.gItemRecord );

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'END of procedure Get_Item_Comp');
EXCEPTION
  WHEN OTHERS THEN
      pio_OutContext := NULL;
      srv_blc_data.gItemRecord := NULL;
      srv_blc_data.gItemTable := NULL;
      --
      srv_error.SetSysErrorMsg ( l_errmsg, 'cust_billing_pkg.Get_Item_Comp', SQLERRM );
      srv_error.SetErrorMsg( l_errmsg, pio_err );

      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_component = '||l_component||' - '|| SQLERRM);

END Get_Item_Comp;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Create_Update_Item - not in use
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--     Fadata   12.11.2018  changed - LPVS-13 - not allign attrib_4 for CLIENT_IND case
--
-- Purpose:  Service called before generates a record for an item to
-- modify some of the parameters. Calculate billing organization.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_ITEM',
--              'MODIFY_BLC_ITEM'.
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Create_Update_Item ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
IS
    l_policy_id          NUMBER;
    l_annex_id           NUMBER;
    l_ref_type           VARCHAR2(300);
    l_account_id         NUMBER;
    l_item               blc_items_type;
    l_eng_billing_id     NUMBER;
    l_agreement          blc_items.agreement%TYPE;
    l_policy_level_old   VARCHAR2(30);
    l_policy_level_new   VARCHAR2(30);
    l_log_module         VARCHAR2(240);
    l_count              PLS_INTEGER;
    l_SrvErrMsg          SrvErrMsg;
    l_le_id              NUMBER;
    l_org_id             NUMBER;
    l_office             blc_items.office%TYPE;
    l_protocol_flag      VARCHAR2(1);
    l_protocol_number    VARCHAR2(30);
    --
    CURSOR CgetBillingAnnex (x_policy_id NUMBER, x_annex_id NUMBER) IS
    SELECT eng_billing_id, attr2,
           attr3, attr4, attr5,
           attr6, attr7, attr8
      FROM policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND annex_id = x_annex_id;
    --
    CURSOR CgetBillingAnnex_2 (x_policy_id NUMBER, x_annex_id NUMBER) IS
    SELECT eng_billing_id, attr2,
           attr3, attr4, attr5,
           attr6, attr7, attr8
      FROM policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND attr7 IS NOT NULL
     ORDER BY decode(annex_id, x_annex_id, 0, 1), annex_id DESC;
    --
    CURSOR CgetBillingAnnex_3 (x_policy_id NUMBER) IS
    SELECT eng_billing_id,
           attr7
      FROM policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND attr7 IS NOT NULL
     ORDER BY annex_id DESC;
    --
    l_attr2 policy_engagement_billing.attr2%TYPE;
    l_attr3 policy_engagement_billing.attr3%TYPE;
    l_attr4 policy_engagement_billing.attr4%TYPE;
    l_attr5 policy_engagement_billing.attr5%TYPE;
    l_attr6 policy_engagement_billing.attr6%TYPE;
    l_attr7 policy_engagement_billing.attr7%TYPE;
    l_attr8 policy_engagement_billing.attr8%TYPE;
    l_item_id NUMBER;
    --07.11.2017
    l_max_attrib_4     VARCHAR2(30);
    l_master_policy_id NUMBER;
    l_policy_type      p_policy_type;
    --13.11.2017
    l_master_policy_no VARCHAR2(50);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Pre_Create_Update_Item';
    --
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Pre_Create_Update_Item');
    srv_context.GetContextAttrChar  ( pi_Context, 'REFERENCE_TYPE',l_ref_type );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_ref_type = '||l_ref_type);

    pio_OutContext := pi_Context;

    srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_0', NULL);
    srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_1', NULL);
    srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_2', NULL);
    srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_3', NULL);

    IF l_ref_type = 'POLICY'
    THEN
       srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );
       srv_context.GetContextAttrNumber( pi_Context, 'ANNEX_ID', l_annex_id );

       srv_context.GetContextAttrNumber( pi_Context, 'ITEM_ID', l_item_id );
       srv_context.GetContextAttrChar( pi_Context, 'OFFICE', l_office );

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_policy_id = '||l_policy_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'l_annex_id = '||l_annex_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_item_id = '||l_item_id);

       OPEN CgetBillingAnnex(l_policy_id, l_annex_id);
         FETCH CgetBillingAnnex
         INTO l_eng_billing_id, l_attr2,
              l_attr3, l_attr4, l_attr5,
              l_attr6, l_attr7, l_attr8;
       CLOSE CgetBillingAnnex;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_eng_billing_id = '||l_eng_billing_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr2 = '||l_attr2);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr3 = '||l_attr3);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr4 = '||l_attr4);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr5 = '||l_attr5);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr6 = '||l_attr6);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr7 = '||l_attr7);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr8 = '||l_attr8);

       l_agreement := Get_Item_Agreement(l_policy_id, l_annex_id, l_attr7);

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_agreement = '||l_agreement);

       srv_context.SetContextAttrChar(pio_OutContext, 'AGREEMENT', l_agreement);

       l_org_id := blc_common_pkg.Get_Billing_Site(l_office,TRUNC(sysdate),l_le_id,pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                     'pi_office = '||l_office||' - '||
                                     pio_Err(pio_Err.LAST).errmessage);
          RETURN;
       END IF;

       srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_0', l_org_id);

       IF l_item_id IS NULL
       THEN
          IF l_attr7 IS NULL -- add for case when new item is created because of the other currency and annex is not created record in policy_engagement_billing
          THEN
             OPEN CgetBillingAnnex_2(l_policy_id, l_annex_id);
               FETCH CgetBillingAnnex_2
               INTO l_eng_billing_id, l_attr2,
                    l_attr3, l_attr4, l_attr5,
                    l_attr6, l_attr7, l_attr8;
             CLOSE CgetBillingAnnex_2;

             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_eng_billing_id = '||l_eng_billing_id);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr2 = '||l_attr2);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr3 = '||l_attr3);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr4 = '||l_attr4);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr5 = '||l_attr5);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr6 = '||l_attr6);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr7 = '||l_attr7);
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                       'l_attr8 = '||l_attr8);
          END IF;

          --remove comment from the next rows to be sure that billing required attributes always are populated - 21.10.2017
          /*
          IF l_attr4 IS NULL
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Update_Item', 'cust_billing_pkg.PCUI.Req_Item_Bill_Date');
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'Item bill date is not specified');
          END IF;

          IF l_attr5 IS NULL
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Update_Item', 'cust_billing_pkg.PCUI.Req_Item_Bill_Period');
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'Item bill period is not specified');
          END IF;

          IF l_attr7 IS NULL
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Update_Item', 'cust_billing_pkg.PCUI.Req_Item_Policy_Type');
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'Item policy type is not specified');
          END IF;
          */

          Calc_Policy_Protocol_Attr
            ( pi_policy_id       => l_policy_id,
              po_protocol_flag   => l_protocol_flag,
              po_protocol_number => l_protocol_number,
              pio_Err            => pio_Err);

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             RETURN;
          END IF;

          --calculate master policy_no -- 13.11.2017
          IF l_attr7 IN ('CLIENT_GROUP', 'CLIENT_IND', 'CLIENT_IND_DEPEND')
          THEN
             l_master_policy_id := Get_Master_Policy_Id( l_policy_id );
             l_policy_type := pol_types.get_policy(nvl(l_master_policy_id, l_policy_id));
             l_master_policy_no := l_policy_type.policy_no;
          ELSE
             l_master_policy_no := NULL;
          END IF;

          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', to_char(to_date(l_attr4,'YYYYMMDD'),'YYYY-MM-DD'));
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_5', l_attr5);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_6', l_attr2);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_7', l_attr7);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_8', l_attr8);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_9', l_attr3);

          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_2', l_protocol_flag);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_3', l_protocol_number);
          --13.11.2017
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_1', l_master_policy_no);

          --07.11.2017 -- modify ATTRIB_4 for case of group policy
          IF l_attr7 = 'CLIENT_GROUP'
          THEN
             SELECT MAX(bi.attrib_4)
             INTO l_max_attrib_4
             FROM blc_items bi
             WHERE bi.agreement = l_agreement
             AND bi.item_type = 'POLICY'
             AND bi.attrib_7 = l_attr7;
          /* --LPVS-13
          ELSIF l_attr7 IN ('CLIENT_IND', 'CLIENT_IND_DEPEND') -- 13.11.2017
          THEN
             SELECT MAX(bi.attrib_4)
             INTO l_max_attrib_4
             FROM blc_items bi
             WHERE bi.attrib_1 = l_master_policy_no
             AND bi.item_type = 'POLICY'
             AND bi.attrib_7 IN ('CLIENT_IND', 'CLIENT_IND_DEPEND');
          ELSE
          */
             l_max_attrib_4 := NULL;
          END IF;

          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_max_attrib_4 = '||l_max_attrib_4);

          IF l_max_attrib_4 IS NOT NULL
          THEN
             srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', l_max_attrib_4);
          END IF;
       ELSE
          l_item := blc_items_type(l_item_id, pio_Err);
          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'l_item_id = '||l_item_id||' - '||
                                         pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

          IF l_item.item_type = 'ON-ACCOUNT' -- TS.27.07.2017
          THEN
             srv_blc_data.gItemRecord := l_item;

             -- Fill OutContext;
             IF NOT srv_blc_data.SetItemRecordInContext( pio_OutContext, pio_Err)
             THEN
                pio_OutContext := NULL;
                --
                RETURN;
             END IF;
          ELSE
            -- update with the same item attribute values
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_1', l_item.attrib_1); --13.11.2017
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_2', l_item.attrib_2);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_3', l_item.attrib_3);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', l_item.attrib_4);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_5', l_item.attrib_5);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_6', l_item.attrib_6);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_7', l_item.attrib_7);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_8', l_item.attrib_8);
            srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_9', l_item.attrib_9);
            --
            blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_item.attrib_4 = '||l_item.attrib_4);
            blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_item.attrib_5 = '||l_item.attrib_5);
            blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_item.attrib_6 = '||l_item.attrib_6);
            blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_item.attrib_7 = '||l_item.attrib_7);
            blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_item.attrib_8 = '||l_item.attrib_8);
            blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_item.attrib_9 = '||l_item.attrib_9);

            IF l_eng_billing_id IS NOT NULL
            THEN
               --start CON94S-55
               IF l_attr7 IS NULL -- add for case when attributes for annex record es empty
               THEN
                  OPEN CgetBillingAnnex_2(l_policy_id, l_annex_id);
                    FETCH CgetBillingAnnex_2
                    INTO l_eng_billing_id, l_attr2,
                        l_attr3, l_attr4, l_attr5,
                        l_attr6, l_attr7, l_attr8;
                  CLOSE CgetBillingAnnex_2;
               END IF;
               --end CON94S-55

               IF l_attr4 IS NOT NULL AND l_attr6 IS NOT NULL --annex for change frequency
               THEN
                  srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', to_char(to_date(l_attr4,'YYYYMMDD'),'YYYY-MM-DD'));

                  --07.11.2017 --modify for case of group policy get insr begin of master policy
                  /* remove next rows because expectation is that in this case annex_begin date will be given
                  IF l_item.attrib_7 = 'CLIENT_GROUP'
                  THEN
                     l_master_policy_id := Get_Master_Policy_Id( l_policy_id );
                     l_policy_type := pol_types.get_policy(nvl(l_master_policy_id, l_policy_id));
                     l_max_attrib_4 := to_char(l_policy_type.insr_begin,'YYYY-MM-DD');
                     blc_log_pkg.insert_message(l_log_module,
                                                C_LEVEL_STATEMENT,
                                                'l_max_attrib_4 = '||l_max_attrib_4);
                     srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', l_max_attrib_4);
                  END IF;
                  */
                  --
               END IF;

               IF l_attr5 IS NOT NULL
               THEN
                  srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_5', l_attr5);
               END IF;

               IF l_attr2 IS NOT NULL
               THEN
                  srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_6', l_attr2);
               END IF;

               IF l_attr7 IS NOT NULL
               THEN
                  srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_7', l_attr7);

                  l_policy_level_old := Get_Policy_level(NULL, NULL, l_attr7);
                  l_policy_level_new := Get_Policy_level(NULL, NULL, l_item.attrib_7);

                  IF l_policy_level_old <> l_policy_level_new
                  THEN
                     SELECT count(*)
                     INTO l_count
                     FROM blc_applications ba
                     WHERE ba.target_item = l_item_id
                     AND ba.appl_class = 'RCPT_ON_ACCOUNT'
                     AND ba.status <> 'D'
                     AND ba.reversed_appl IS NULL
                     AND NOT EXISTS (SELECT 'REVERSE'
                                     FROM blc_applications ba1
                                     WHERE ba1.reversed_appl = ba.application_id
                                     AND ba1.status <> 'D');

                     IF l_count > 0
                     THEN
                        srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Update_Item', 'cust_billing_pkg.PCUI.Exist_On_Acc',l_item_id||'|'||l_item.agreement||'|'||l_agreement);
                        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                                  'Cannot change the agreement! There are on-account applications for target item id '||l_item_id||', old agreement '||l_item.agreement||', new agreement '||l_agreement);
                     END IF;
                  END IF;
               END IF;

               srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_8', l_attr8);
               srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_9', l_attr3);
            END IF;
          END IF;
       END IF;
    /*   no needed because no change fo commission items
    ELSIF l_ref_type = 'COMMISSION'
    THEN
       srv_context.GetContextAttrNumber( pi_Context, 'ITEM_ID', l_item_id );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_item_id = '||l_item_id);
       IF l_item_id IS NOT NULL
       THEN
          l_item := blc_items_type(l_item_id, pio_Err);
          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'l_item_id = '||l_item_id||' - '||
                                         pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

          srv_context.GetContextAttrChar( pi_Context, 'DETAIL', l_detail );
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_PROCEDURE,
                                     'pi_detail = '||l_detail);
          IF nvl(l_detail,'-999') <> l_item.detail
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_PROCEDURE,
                                        'l_item.detail = '||l_item.detail);
             srv_context.SetContextAttrChar( pio_OutContext, 'DETAIL', l_item.detail );
          END IF;
       END IF;
    */
    ELSE
       srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );

       IF l_policy_id IS NOT NULL
       THEN
          OPEN CgetBillingAnnex_3(l_policy_id);
             FETCH CgetBillingAnnex_3
             INTO l_eng_billing_id,
                  l_attr7;
          CLOSE CgetBillingAnnex_3;

          --calculate master policy_no -- 23.11.2017
          IF l_attr7 IN ('CLIENT_GROUP', 'CLIENT_IND', 'CLIENT_IND_DEPEND')
          THEN
             l_master_policy_id := Get_Master_Policy_Id( l_policy_id );
             l_policy_type := pol_types.get_policy(nvl(l_master_policy_id, l_policy_id));
             l_master_policy_no := l_policy_type.policy_no;
          ELSE
             l_master_policy_no := NULL;
          END IF;

          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_1', l_master_policy_no);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_8', NULL);
          srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_9', NULL);
       END IF;

    END IF;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'END of procedure Pre_Create_Update_Item');
EXCEPTION
    WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Update_Item', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_policy_id = '||l_policy_id||' - '|| SQLERRM);
END Pre_Create_Update_Item;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Create_Installment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation
--
-- Purpose:  Service called before generates a record for an installment to
-- modify some of the parameters. Calculate end date.
--
-- Input parameters:
--     pi_Context      SrvContext   Specifies installment data as attributes in
--                                  context;
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_OutContext  SrvContext   Collection of object's attributes;
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Returns:
-- Not applicable.
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: Service is associated with events 'CREATE_BLC_INSTALLMENT'
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Create_Installment ( pi_Context IN SrvContext,
                                   pio_OutContext IN OUT SrvContext,
                                   pio_Err IN OUT SrvErr )
IS
    /*
    l_policy_id       NUMBER;
    l_annex_id        NUMBER;
    l_account_id      NUMBER;
    l_item_id         NUMBER;
    l_inst_date       DATE;
    l_account         blc_accounts_type;
    l_item            blc_items_type;
    l_begin_date      DATE;
    l_end_date        DATE;
    l_bill_period     NUMBER;
    l_next_date       DATE;
    l_bill_cycle_id   NUMBER;
    l_external_id     VARCHAR2(30);
    */
    l_SrvErrMsg       SrvErrMsg;
    l_log_module      VARCHAR2(240);
    l_inst_type       VARCHAR2(30);
    l_ref_type        VARCHAR2(300);
    --
    /*
    CURSOR CgetPPlan (x_policy_id NUMBER, x_pplan_id NUMBER) IS
    SELECT attr4, attr5
      FROM blc_policy_payment_plan
     WHERE policy_id = x_policy_id
       AND policy_pplan_id = x_pplan_id;
    --
    l_attr4 blc_policy_payment_plan.attr4%TYPE;
    l_attr5 blc_policy_payment_plan.attr5%TYPE;
    */
    l_claim_id          NUMBER;
    l_policy_id         NUMBER;
    l_provider_man_id   NUMBER;
    l_attrib_1          VARCHAR2(120 CHAR);
    l_attrib_2          VARCHAR2(120 CHAR);
    l_attrib_3          VARCHAR2(120 CHAR);
    l_attrib_4          VARCHAR2(120 CHAR);
    l_attrib_5          VARCHAR2(120 CHAR);
    l_attrib_6          VARCHAR2(120 CHAR);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Pre_Create_Installment';

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Pre_Create_Installment');
    srv_context.GetContextAttrChar  ( pi_Context, 'REFERENCE_TYPE',l_ref_type );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_ref_type = '||l_ref_type);

    srv_context.GetContextAttrChar  ( pi_Context, 'TYPE', l_inst_type );
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_inst_type = '||l_inst_type);
    --LPV-2078
    --get provider claim attributes
    pio_OutContext := pi_Context;

/* no need to log
dbms_output.put_line( '--------------------' );
dbms_output.put_line( 'Start Pre_Create_Installment' );
IF pi_Context IS NOT NULL THEN
        FOR r IN pi_Context.first..pi_Context.last
        LOOP
            dbms_output.put_line( pi_Context(r).attrcode || '(' || pi_Context(r).attrformat || ') ' || pi_Context(r).attrvalue );
        END LOOP;
--     insis_sys_v10.srv_context.getcontextattrnumber(po_outcontext, 'CLAIM_ID', l_claim_context);
     --dbms_output.put_line( 'Current claim_id value in context is: ' || l_claim_context );
END IF;
*/

    IF l_ref_type = 'CLAIM'
    THEN
       --srv_context.GetContextAttrNumber( pi_Context, 'CLAIM_ID', l_claim_id ); -- Dora 25-02-2020
       srv_context.GetContextAttrChar( pi_Context, 'CLAIM', l_claim_id ); -- Dora 25-02-2020
       srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );

       IF l_claim_id IS NOT NULL
       THEN
           BEGIN
              SELECT doc_type, inv_serial_number,
                     inv_number, SUBSTR(type_code_wt,1,120),
                     doc_sap, man_id
              INTO l_attrib_1, l_attrib_2,
                   l_attrib_3, l_attrib_5,
                   l_attrib_6, l_provider_man_id
              FROM insis_cust_lpv.exp_invoices_stg
              WHERE claim_id = l_claim_id;

              --l_attrib_4 := cust_acc_util_pkg.Get_Accepted_Benef_Id(l_policy_id); --Dora 02.03.2020 - populate insured obj with given man_id
              l_attrib_4 := l_provider_man_id;

              srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_1', l_attrib_1);
              srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_2', l_attrib_2);
              srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_3', l_attrib_3);
              --srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', l_attrib_4); --move to attrib_7 - Dora -27.02.2020
              --srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_5', l_attrib_5); --move to attrib_8 - Dora -27.02.2020
              srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_6', l_attrib_6);
              srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_7', l_attrib_4);
              srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_8', l_attrib_5);
          EXCEPTION
             WHEN OTHERS THEN
               l_attrib_1 := NULL;
          END;
      END IF;
    END IF;
    /*
    IF NOT (l_ref_type = 'POLICY' AND l_inst_type IN ('BCPR', 'BCTAX', 'BCISSUETAX')) --set to null in other cases, do not set for AC policies -18.11.2017
    THEN
       srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', NULL);
       srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_5', NULL);
    END IF;
    */
     /*
    IF l_ref_type = 'POLICY' AND l_inst_type IN ('BCPR', 'BCTAX')
    THEN
       srv_context.GetContextAttrNumber( pi_Context, 'POLICY_ID', l_policy_id );
       srv_context.GetContextAttrNumber( pi_Context, 'ANNEX_ID', l_annex_id );
       srv_context.GetContextAttrNumber( pi_Context, 'ACCOUNT_ID', l_account_id );
       srv_context.GetContextAttrNumber( pi_Context, 'ITEM_ID', l_item_id );
       srv_context.GetContextAttrDate  ( pi_Context, 'DATE', l_inst_date );
       srv_context.GetContextAttrChar  ( pi_Context, 'EXTERNAL_ID', l_external_id );

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_policy_id = '||l_policy_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_annex_id = '||l_annex_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_item_id = '||l_item_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_account_id = '||l_account_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_external_id = '||l_external_id);

       OPEN CgetPPlan(l_policy_id, to_number(l_external_id));
         FETCH CgetPPlan
         INTO l_attr4, l_attr5;
       CLOSE CgetPPlan;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr4 = '||l_attr4);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_attr5 = '||l_attr5);

       IF l_attr4 IS NOT NULL AND l_attr5 IS NOT NULL
       THEN
          l_begin_date := to_date(l_attr4,'YYYYMMDD');
          l_end_date := to_date(l_attr5,'YYYYMMDD');
       ELSE
          NULL;
          /*
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Installment', 'cust_billing_pkg.PCI.Req_Bill_Dates');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                     'Bill period dates (attr4 and attr5 in blc_policy_payment_plan) are required');
          */
          -- remove BLC logic stay only PAS logic
          /*
          l_account := blc_accounts_type(l_account_id, pio_Err);
          l_item := blc_items_type(l_item_id, pio_Err);
          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'l_item_id = '||l_item_id||' - '||
                                        'l_account_id = '||l_account_id||' - '||
                                         pio_Err(pio_Err.FIRST).errmessage);
             RETURN;
          END IF;

          IF l_account.attrib_0 = 'CLIENT'
          THEN
             l_next_date := l_account.next_date;
             l_bill_period := l_account.bill_period;
             l_bill_cycle_id := l_account.bill_cycle_id;
          ELSE
             --the next values have to be changed after they received from PAS to get from item or account depend on account setup
             l_next_date := to_date(l_item.attrib_4,'yyyy-mm-dd');
             l_bill_period := to_number(l_item.attrib_5);
             l_bill_cycle_id := l_account.bill_cycle_id;
          END IF;

          IF l_next_date IS NOT NULL AND l_bill_period IS NOT NULL
          THEN
             l_end_date := Get_Reg_Bill_To_Date
                                             (pi_next_date     => l_next_date,
                                              pi_bill_cycle_id => l_bill_cycle_id,
                                              pi_bill_period   => l_bill_period,
                                              pi_run_date      => l_inst_date,
                                              pi_nd_offset     => 0,
                                              pi_nwd_offset    => 0);

             IF to_char(l_inst_date,'dd') =  to_char(l_end_date,'dd')
             THEN
                -- get current period
                l_begin_date := blc_billing_pkg.Get_Next_Billing_Date
                                            (l_end_date,
                                             l_bill_cycle_id,
                                             (-1)*l_bill_period);
                l_end_date := l_end_date - 1;
             ELSE
                --get the next period
                l_begin_date := l_end_date;
                l_end_date := blc_billing_pkg.Get_Next_Billing_Date
                                            (l_begin_date,
                                             l_bill_cycle_id,
                                             l_bill_period);
                l_end_date := l_end_date - 1;
             END IF;
          END IF; */
  /*
       END IF;

       --srv_context.SetContextAttrDate(pio_OutContext, 'END_DATE', srv_context.Date_Format, l_end_date);
       srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_4', to_char(l_begin_date,'YYYY-MM-DD'));
       srv_context.SetContextAttrChar(pio_OutContext, 'ATTRIB_5', to_char(l_end_date,'YYYY-MM-DD'));
   END IF;
   */

   blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'END of procedure Pre_Create_Installment');
EXCEPTION
    WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Create_Installment', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'l_inst_type = '||l_inst_type||' - '|| SQLERRM);
END Pre_Create_Installment;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Reg_Bill_To_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   21.04.2017  creation - copy from blc_billing_pkg.Get_Reg_Bill_To_Date
--                                     add case when run date is less than
--                                     account next date
--
-- Purpose: Calculate billing to date depend on billing cycle and bill period
-- for a next billing date and given run date
--
-- Input parameters:
--     pi_next_date       DATE       Current value of account attribute
--                                   next date (required)
--     pi_bill_cycle_id   NUMBER     Billing cycle identifier -
--                                   definition from lookup set BILL_CYCLES
--                                   (required)
--     pi_bill_period     NUMBER     Period of time between two consequence
--                                   bills (required)
--     pi_run_date        DATE       Billing run date (required)
--     pi_nd_offset       NUMBER     Next date offset
--     pi_nwd_offset      NUMBER     Non working date offset
--
-- Returns:
--     bill to date
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Reg_Bill_To_Date
   (pi_next_date     IN     DATE,
    pi_bill_cycle_id IN     NUMBER,
    pi_bill_period   IN     NUMBER,
    pi_run_date      IN     DATE,
    pi_nd_offset     IN     NUMBER,
    pi_nwd_offset    IN     NUMBER)
RETURN DATE
IS
    l_date       DATE;
    l_prev_date  DATE;
BEGIN
    IF pi_next_date IS NULL OR pi_bill_cycle_id IS NULL OR nvl(pi_bill_period,0) = 0
    THEN
       RETURN NULL;
    END IF;

    l_date := pi_next_date;
    --
    IF l_date - (nvl(pi_nd_offset,0) + nvl(pi_nwd_offset,0)) <= pi_run_date
    THEN
       LOOP
         EXIT WHEN l_date - (nvl(pi_nd_offset,0) + nvl(pi_nwd_offset,0)) > pi_run_date;
             --
             l_date := blc_billing_pkg.Get_Next_Billing_Date
                                        (l_date,
                                         pi_bill_cycle_id,
                                         pi_bill_period);
       END LOOP;
    ELSE
       LOOP
         EXIT WHEN l_date - (nvl(pi_nd_offset,0) + nvl(pi_nwd_offset,0)) <= pi_run_date;
             --
             l_prev_date := l_date;
             l_date := blc_billing_pkg.Get_Next_Billing_Date
                                        (l_date,
                                         pi_bill_cycle_id,
                                         (-1)*pi_bill_period);
       END LOOP;
         l_date := l_prev_date;
    END IF;

    IF blc_common_pkg.Get_Lookup_Code(pi_bill_cycle_id) = 'MNTHLY_END'
    THEN
       l_date := to_date('01'||to_char(l_date,'mm-yyyy'),'dd-mm-yyyy');
    END IF;

    RETURN l_date;
END Get_Reg_Bill_To_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Reg_Bill_Prev_To_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--
-- Purpose: Calculate previous before current billing to date depend on
-- billing cycle and bill period for a next billing date and given run date and
--
-- Input parameters:
--     pi_next_date       DATE       Current value of account attribute
--                                   next date (required)
--     pi_bill_cycle_id   NUMBER     Billing cycle identifier -
--                                   definition from lookup set BILL_CYCLES
--                                   (required)
--     pi_bill_period     NUMBER     Period of time between two consequence
--                                   bills (required)
--     pi_run_date        DATE       Billing run date (required)
--     pi_nd_offset       NUMBER     Next date offset
--     pi_nwd_offset      NUMBER     Non working date offset
--
-- Returns:
--     bill to date
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Reg_Bill_Prev_To_Date
   (pi_next_date     IN     DATE,
    pi_bill_cycle_id IN     NUMBER,
    pi_bill_period   IN     NUMBER,
    pi_run_date      IN     DATE,
    pi_nd_offset     IN     NUMBER,
    pi_nwd_offset    IN     NUMBER)
RETURN DATE
IS
    l_date       DATE;
BEGIN
    --22.08.2018 replace blc_billing_pkg.Get_Reg_Bill_To_Date with cust_billing_pkg.Get_Reg_Bill_To_Date_2
    l_date := cust_billing_pkg.Get_Reg_Bill_To_Date_2
                          (pi_next_date,
                           pi_bill_cycle_id,
                           pi_bill_period,
                           pi_run_date,
                           pi_nd_offset,
                           pi_nwd_offset);

    l_date := blc_billing_pkg.Get_Next_Billing_Date
                                        (l_date,
                                         pi_bill_cycle_id,
                                         (-1)*pi_bill_period);

    RETURN l_date;
END Get_Reg_Bill_Prev_To_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Custom_Pkg
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
-- Purpose: Get custom package name for a given billing method
-- billing method is a lookup_id from lookup_set BILL_METHODS
-- or IMMEDIATE_BILLING_METHOD
-- Classifying rule is written in tag_7
-- Example:
-- blc_imm_billing_custom_pkg
--
-- Input parameters:
--     pi_bill_method_id  NUMBER     Billing method identifier (required)
--
-- Returns:
--     custom package name
--
-- Usage: In billing process if you want to override predefined procedure for
-- installment sellection, transaction and document creation with custom written
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Custom_Pkg
   (pi_bill_method_id     IN     NUMBER)
RETURN VARCHAR2
IS
    l_value blc_lookups.tag_7%TYPE;
BEGIN
   SELECT tag_7
   INTO l_value
   FROM blc_lookups
   WHERE lookup_id = pi_bill_method_id;

   RETURN l_value;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
      blc_log_pkg.insert_message('blc_billing_pkg.Get_Custom_Pkg', C_LEVEL_EXCEPTION,
              'pi_bill_method_id = '||pi_bill_method_id||' - '||SQLERRM);
      RETURN NULL;
END Get_Custom_Pkg;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_I_Eligibility
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
-- Purpose: Get installment elibility clause for a given billing method
-- Billing method is a lookup_id from lookup_set BILL_METHODS
-- or IMMEDIATE_BILLING_METHOD
-- Eligibility clause is written in tag_0
-- Posible attributes in where clause are all columns from view
-- blc_installments_all (required preffix i.)
-- and all columns from table blc_run (required preffix is c.)
-- Example:
-- (i.bill_mode = 'D'
--    OR i.next_date <= nvl(c.run_date,i.next_date)
--    OR i.installment_date <
--              blc_billing_pkg.Get_Next_Billing_Date(i.next_date,
--                                                    i.bill_cycle_id,
--                                                    i.bill_period)
--  )
--
-- Input parameters:
--     pi_bill_method_id  NUMBER     Billing method identifier (required)
--
-- Returns:
--     installment elibility clause
--
-- Usage: In installment sellection as additional where clause
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_I_Eligibility
   (pi_bill_method_id     IN     NUMBER)
RETURN VARCHAR2
IS
    l_value blc_lookups.tag_0%TYPE;
BEGIN
   SELECT tag_0
   INTO l_value
   FROM blc_lookups
   WHERE lookup_id = pi_bill_method_id;

   RETURN l_value;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      blc_log_pkg.insert_message('blc_billing_pkg.Get_I_Eligibility', C_LEVEL_EXCEPTION,
                'pi_bill_method_id = '||pi_bill_method_id||' - '||SQLERRM);
      RETURN NULL;
END Get_I_Eligibility;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Set_Reg_Bill_Time
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.03.2017  creation - rq 1000010947
--
-- Purpose: Set value of setting RegBillingTimestamp for given billing
-- organization with lock for update to prevent installment selection from
-- other runs
--
-- Input parameters:
--     pi_billing_site_id   NUMBER   Billing site id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: Before selection for regular billing to stop other selections for the
-- same organization
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Reg_Bill_Time
   (pi_billing_site_id IN     NUMBER,
    pio_Err            IN OUT SrvErr)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
   l_setting           VARCHAR2(50);
   l_count             PLS_INTEGER;
   --
    CURSOR c_setting IS
      SELECT date_value
      FROM blc_values
      WHERE setting = l_setting
      AND org_id = pi_billing_site_id
      AND trunc(sysdate) BETWEEN from_date AND NVL(to_date, trunc(sysdate))
      FOR UPDATE NOWAIT;
BEGIN

   l_log_module := C_DEFAULT_MODULE||'.Set_Reg_Bill_Time';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Set_Reg_Bill_Time');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_billing_site_id = '||pi_billing_site_id);

   l_setting := 'RegBillingTimestamp';

   SELECT count(*)
   INTO l_count
   FROM blc_values
   WHERE setting = l_setting
   AND org_id = pi_billing_site_id
   AND trunc(sysdate) BETWEEN from_date AND NVL(to_date, trunc(sysdate));

   IF l_count = 0
   THEN
      INSERT INTO blc_values
        (setting, org_id, from_date, to_date, number_value, date_value,
         text_value, lookup_id, PRIVATE, notes,
         created_on, created_by, updated_on, updated_by, attrib_0, attrib_1, attrib_2,
         attrib_3, attrib_4, attrib_5, attrib_6, attrib_7, attrib_8, attrib_9)
      VALUES
        (l_setting, pi_billing_site_id, trunc(sysdate), NULL, NULL, to_date('01-01-1900','dd-mm-yyyy'),
         NULL, NULL, 'N', NULL,
         NULL, NULL, NULL, NULL, NULL, NULL, NULL,
         NULL, NULL, NULL, NULL, NULL, NULL, NULL);
   END IF;

   OPEN c_setting;
      UPDATE blc_values
      SET date_value = sysdate
      WHERE setting = l_setting
      AND org_id = pi_billing_site_id
      AND trunc(sysdate) BETWEEN from_date AND NVL(to_date, trunc(sysdate));
   CLOSE c_setting;

   --
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Set_Reg_Bill_Time');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Set_Reg_Bill_Time', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_billing_site_id = '||pi_billing_site_id||' - '||SQLERRM);
END Set_Reg_Bill_Time;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Reg_Bill_To_Date_2
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   08.06.2016  creation - rq 1000010513
--     Fadata   15.05.2017  changed - Add check if required parameters are NULL
--                                    rq 1000011006
--     Fadata   22.08.2018  changed - copy from core Get_Reg_Bill_To_Date, but
--                                    change clause nvl(pi_bill_period,0) > 0
--                                    with nvl(pi_bill_period,0) = 0
--
-- Purpose: Calculate billing to date depend on billing cycle and bill period
-- for a next billing date and given run date
--
-- Input parameters:
--     pi_next_date       DATE       Current value of account attribute
--                                   next date (required)
--     pi_bill_cycle_id   NUMBER     Billing cycle identifier -
--                                   definition from lookup set BILL_CYCLES
--                                   (required)
--     pi_bill_period     NUMBER     Period of time between two consequence
--                                   bills (required)
--     pi_run_date        DATE       Billing run date (required)
--     pi_nd_offset       NUMBER     Next date offset
--     pi_nwd_offset      NUMBER     Non working date offset
--
-- Returns:
--     bill to date
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Reg_Bill_To_Date_2
   (pi_next_date     IN     DATE,
    pi_bill_cycle_id IN     NUMBER,
    pi_bill_period   IN     NUMBER,
    pi_run_date      IN     DATE,
    pi_nd_offset     IN     NUMBER,
    pi_nwd_offset    IN     NUMBER)
RETURN DATE
IS
    l_date       DATE;
    l_bill_cycle VARCHAR2(30);
BEGIN
    --rq 1000011006
    IF pi_next_date IS NULL OR pi_bill_cycle_id IS NULL OR nvl(pi_bill_period,0) = 0
    THEN
       RETURN NULL;
    END IF;

    l_date := pi_next_date;
    --
    LOOP
       EXIT WHEN l_date - (nvl(pi_nd_offset,0) + nvl(pi_nwd_offset,0)) > pi_run_date;
           --
           l_date := blc_billing_pkg.Get_Next_Billing_Date
                                      (l_date,
                                       pi_bill_cycle_id,
                                       pi_bill_period);
    END LOOP;

    IF blc_common_pkg.Get_Lookup_Code(pi_bill_cycle_id) = 'MNTHLY_END'
    THEN
       l_date := to_date('01'||to_char(l_date,'mm-yyyy'),'dd-mm-yyyy');
    END IF;

    RETURN l_date;
END Get_Reg_Bill_To_Date_2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Select_Bill_Installments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   20.05.2013  changed - exclude from selection installments
--                                    from class 'R'
--     Fadata   07.08.2013  changed - in selection installment replace
--                                    (trunc(sysdate) - trunc(i.created_on)) <=
--                                     nvl(i.min_retain_days,0) with
--                                    (trunc(sysdate) - trunc(i.created_on)) >=
--                                     nvl(i.min_retain_days,0)
--     Fadata   17.10.2013  changed - in selection installment add party and
--                                    from/to recognition rate date
--     Fadata   04.03.2014  changed - add parameters bill_method in cursor
--                                    for selection of bill methods for regular
--                                    bill and after that set to null in run
--                                    variable
--                                    rq 1000008191
--     Fadata   26.08.2014  changed - do not select installments in case that
--                                    given billing method is NONE
--                                    rq 1000009066
--     Fadata   02.12.2014  changed - select negative installments by
--                                    net_horizon instead of bill_horizon
--                                    rq 1000009381
--     Fadata   06.04.2015  changed - add procedure specification, add savepoint
--                                    and rollback
--                                    rq 1000009741
--     Fadata   15.09.2015  changed - add calculation of horizon depend on
--                                    setting BillNonWorkingDays
--                                    add logic for setting
--                                    BillingNextDateOffset
--                                    rq 1000010052
--     Fadata   18.11.2015  changed - call function to calculate real
--                                    compensated flag for billing depend on
--                                    setting BillCompensatedInstallments
--                                    add case for extra billing to work as
--                                    daily mode
--                                    rq 1000010196
--     Fadata   30.11.2015  changed - add where clause for legal entity
--                                    rq 1000010209
--     Fadata   09.05.2016  changed - replace creation of where clauses with fix
--                                    values with values from table blc_run
--                                    add '()' in additional where clause
--                                    rq 1000010464
--     Fadata   08.06.2016  changed - add logic for calculation of to date for
--                                    sellection of installments depend on
--                                    value for setting RegBillToDateCalcBasis
--                                    use bill horizon as next date offset for
--                                    bill mode R
--                                    rq 1000010513
--     Fadata   20.01.2017  changed - replase clause AND (c.run_mode <> 'R'
--                                    OR c.bill_site_id = i.billing_site_id)
--                                    with dynamic added clause
--                                    i.billing_site_id = :2 only for regular
--                                    billing
--                                    replace clauses installment_class <> 'R',
--                                    installment_class <> 'E' with
--                                    installment_class IN ('B','P','D','A')
--                                    rq 1000010863
--     Fadata   08.02.2017  changed - add where clause for value of run column
--                                    bill_clause_id
--                                    rq 1000010886
--     Fadata   17.03.2017  changed - add lock of setting value and exclude
--                                    lock for update for regular billing runs
--                                    rq 1000010947
--     Fadata   25.04.2017  changed - copy from core and change to use cust
--                                    view blc_installments_item_bill
--     Fadata   15.02.2018  changed - remove check if to run immediate for given
--                                    run_date - LPV-861
--
-- Purpose: Select eligible installments for billing according billing run
-- parameters and additional elibility clause for parameter billing method of run
-- or for all existing billing methods, if parameter is empty
-- Update billing_run_id column in blc_installments to mark one
-- installment as selected

-- Input parameters:
--     pi_billing_run_id      NUMBER       Billing run identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--     po_count               NUMBER      Count of selected installments
--
-- Usage: In billing process
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Select_Bill_Installments
   (pi_billing_run_id   IN     NUMBER,
    pio_Err             IN OUT SrvErr,
    po_count            OUT    NUMBER)
IS
    TYPE cv_typ IS REF CURSOR;
    CV cv_typ;

    l_blc_run   blc_run_type;

    CURSOR c_bill_methods(x_bill_method_id IN NUMBER) IS
       SELECT lookup_id bill_method_id
       FROM blc_lookups
       WHERE lookup_set = 'BILL_METHODS'
       AND lookup_code <> 'NONE'
       AND (x_bill_method_id IS NULL OR lookup_id = x_bill_method_id);
    /*
        SELECT DISTINCT i.bill_method_id
        FROM blc_installments_all i,
             blc_run c
        WHERE c.run_id = pi_billing_run_id
        AND (c.run_mode <> 'R' OR c.bill_site_id = i.billing_site_id)
--        AND (blc_billing_pkg.Is_BLC_Source(c.run_mode) = 'N' OR c.bill_site_id = i.billing_site_id)
--        AND (c.bill_site_id IS NULL OR c.bill_site_id = i.billing_site_id)
        AND (c.source IS NULL OR c.source = i.source)
        AND (c.agreement IS NULL OR c.agreement = i.agreement)
        AND (c.component IS NULL OR c.component = i.component)
        AND (c.detail IS NULL OR c.detail = i.detail)
        AND (c.annex IS NULL OR c.annex = i.annex)
        AND (c.claim IS NULL OR c.claim = i.claim)
        AND (c.account_ids IS NULL OR i.account_id IN (SELECT * FROM TABLE(blc_common_pkg.Convert_List(c.account_ids))))
        AND (c.item_ids IS NULL OR i.item_id IN (SELECT * FROM TABLE( blc_common_pkg.Convert_List(c.item_ids))))
--        AND (pi_account_ids IS NULL OR i.account_id IN (SELECT * FROM TABLE(pi_account_ids)))
--        AND (pi_item_ids IS NULL OR i.item_id IN (SELECT * FROM TABLE(pi_item_ids)))
        AND i.billing_run_id IS NULL
        AND blc_common_pkg.Get_Lookup_Code(i.bill_method_id) <> 'NONE'
--        AND (c.run_mode <> 'R' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id,nvl(c.run_date,i.next_date)) = 'Y')
        AND (c.run_mode <> 'R' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id, c.bill_date) = 'Y')
        AND i.compensated = 'N'
--        AND i.installment_class IN ('B', 'D')
        AND (c.run_mode = 'I'
             OR (trunc(i.created_on) <= nvl(c.run_date,i.next_date) + nvl(i.min_retain_days,0) AND i.installment_date <= nvl(c.run_date,i.next_date) + nvl(i.bill_horizon,0))
                 AND (i.bill_mode = 'D'
                      OR i.next_date <= nvl(c.run_date,i.next_date)
                      OR i.installment_date < blc_billing_pkg.Get_Next_Billing_Date(i.next_date,i.bill_cycle_id,i.bill_period) - nvl(i.max_retain_days,0))); */

    l_SrvErrMsg        SrvErrMsg;
    l_i_eligibility_s  VARCHAR2(2000);
    l_i_eligibility_b  VARCHAR2(2000);
    l_sql_base         VARCHAR2(32767);
    l_sql_select       VARCHAR2(32767);
    l_installment_id   NUMBER;
    l_log_module       VARCHAR2(240);
    l_count            NUMBER;
    l_custom_pkg       VARCHAR2(100);
    l_bill_method_id   NUMBER;
    -- rq 1000010052
    l_horizon_offset   NUMBER;
    l_next_date        DATE;
    -- rq 1000010196
    l_bill_comp_inst   VARCHAR2(30);
    l_reg_bill_to_date VARCHAR2(30);
    -- rq 1000010863
    l_billing_site_id  NUMBER;
    -- rq 1000010947
    l_lock_clause      VARCHAR2(100);
    l_due_date         DATE;
    l_run_date_elig    VARCHAR2(1);
    l_run_date_clause  VARCHAR2(1);
    --
    l_run_item_id      blc_items.item_id%TYPE;
    l_ids_tab          blc_selected_ids_table;
    l_ins_count        SIMPLE_INTEGER := 0;
    l_run_account_id   blc_accounts.account_id%TYPE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Select_Bill_Installments';
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Select_Bill_Installments');

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_billing_run_id = '||pi_billing_run_id);

    l_blc_run := NEW blc_run_type(pi_billing_run_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_billing_run_id = '||pi_billing_run_id||' - '||
                                  pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
    END IF;

    IF l_blc_run.run_mode = 'R' AND l_blc_run.bill_method_id IS NOT NULL
    THEN
       l_bill_method_id := l_blc_run.bill_method_id;
       l_blc_run.bill_method_id := NULL;
    END IF;

    l_bill_comp_inst := blc_billing_pkg.Get_Bill_Comp_Inst
                                   (pi_org_id     => l_blc_run.bill_site_id,
                                    pi_to_date    => nvl(l_blc_run.run_date,trunc(sysdate)));

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_bill_comp_inst = '||l_bill_comp_inst);

    --12.12.2017 - add to bill compensated installments for RI method
    IF blc_common_pkg.get_lookup_code(l_blc_run.bill_method_id) = 'RI'
    THEN
       l_bill_comp_inst := 'PAY';
    END IF;

    l_run_date_elig := 'Y';

    IF l_blc_run.run_mode = 'I'
    THEN
       l_horizon_offset := 0;

       --check if to run immediate for given run_date

       --start 15.02.2018 LPV-861 --remove the check - always bill installments with installment date less than end date of current bill period
       /*
       IF NVL(l_blc_run.annex,'0') = '0'
       THEN
          l_run_date_elig := 'Y';
       ELSE
          --check if it is cancellation annex or SIP annex
          IF Is_Canc_Annex(l_blc_run.component,l_blc_run.annex) = 'Y' OR Is_SIP_Annex(l_blc_run.component,l_blc_run.annex) = 'Y' OR Is_PaidUp_Annex(l_blc_run.component,l_blc_run.annex) = 'Y'
          THEN
             l_run_date_elig := 'Y';
          ELSE
             l_run_date_elig := Check_Imm_Run_Date
                 (pi_run_date        => l_blc_run.run_date,
                  pi_bill_method_id  => l_blc_run.bill_method_id,
                  pi_agreement       => l_blc_run.agreement);
          END IF;
       END IF;
       */
       l_run_date_elig := 'Y';
       --end 15.02.2018 LPV-861

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_run_date_elig = '||l_run_date_elig);
    ELSE
       l_horizon_offset := blc_billing_pkg.Get_Bill_Horizon_Offset
                               (pi_org_id     => l_blc_run.bill_site_id,
                                pi_run_date   => nvl(l_blc_run.run_date,trunc(sysdate)));
    END IF;

    l_reg_bill_to_date := blc_billing_pkg.Get_Reg_Bill_To_Date_Basis
                                   (pi_org_id     => l_blc_run.bill_site_id,
                                    pi_to_date    => nvl(l_blc_run.run_date,trunc(sysdate)));

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_reg_bill_to_date = '||l_reg_bill_to_date);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_horizon_offset = '||l_horizon_offset);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_blc_run.bill_method_id = '||l_blc_run.bill_method_id);

    --begin rq 1000010886
    --get l_i_eligibility_s --additional selection criteria get from parameter bill clause
    IF l_blc_run.bill_clause_id IS NOT NULL
    THEN
       l_i_eligibility_s := blc_common_pkg.Get_Lookup_Tag_Value
                         ( pi_lookup_set  => 'BILL_CLAUSES',
                           pi_lookup_code => NULL,
                           pi_org_id      => NULL,
                           pi_lookup_id   => l_blc_run.bill_clause_id,
                           pi_tag_number  => 0 );
    END IF;
    --end rq 1000010886

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_i_eligibility_s = '||l_i_eligibility_s);

   /* l_sql_base  := 'SELECT i.installment_id'||
                   ' FROM blc_installments_all i,'||
                        ' blc_run c'||
                   ' WHERE c.run_id = '||pi_billing_run_id||
                   ' AND (c.run_mode <> ''R'' OR c.bill_site_id = i.billing_site_id)'||
                   ' AND (c.source IS NULL OR c.source = i.source)'||
                   ' AND (c.agreement IS NULL OR c.agreement = i.agreement)'||
                   ' AND (c.component IS NULL OR c.component = i.component)'||
                   ' AND (c.detail IS NULL OR c.detail = i.detail)'||
                   ' AND (c.annex IS NULL OR c.annex = i.annex)'||
                   ' AND (c.claim IS NULL OR c.claim = i.claim)'||
                 --  ' AND (c.anniversary IS NULL OR c.anniversary = i.anniversary)'||
                   ' AND (c.account_ids IS NULL OR i.account_id IN (SELECT * FROM TABLE(blc_common_pkg.Convert_List(c.account_ids))))'||
                   ' AND (c.item_ids IS NULL OR blc_common_pkg.Convert_List_Number(c.item_ids) IS NOT NULL OR i.item_id IN (SELECT * FROM TABLE( blc_common_pkg.Convert_List(c.item_ids))))'||
                   ' AND (blc_common_pkg.Convert_List_Number(c.item_ids) IS NULL OR i.item_id = blc_common_pkg.Convert_List_Number(c.item_ids))'||
                   ' AND i.billing_run_id IS NULL'||
                  -- ' AND (c.run_mode <> ''R'' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id, c.bill_date) = ''Y'')'||
                   ' AND i.compensated = ''N'''||
                   ' AND i.installment_class <> ''E'''||
                   ' AND NVL(i.item_status,''C'') <> ''N'''||
                   ' AND (c.run_mode = ''I'''||
                          ' OR ((trunc(sysdate) - trunc(i.created_on)) <= nvl(i.min_retain_days,0) AND i.installment_date <= nvl(c.run_date,i.next_date) + nvl(i.bill_horizon,0)'||
                   ' AND (i.bill_mode = ''D'''||
                          ' OR i.next_date <= nvl(c.run_date,i.next_date)'||
                          ' OR i.installment_date < blc_billing_pkg.Get_Next_Billing_Date(i.next_date,i.bill_cycle_id,i.bill_period) - nvl(i.max_retain_days,0))))'||
                   ' AND '||nvl(l_i_eligibility_s, '1=1'); */

    /* -- rq 1000010464
    l_sql_base  := 'SELECT i.installment_id'||
                   ' FROM blc_installments_all i,'||
                        ' blc_run c'||
                   ' WHERE c.run_id = '||pi_billing_run_id||
                   ' AND (c.run_mode <> ''R'' OR c.bill_site_id = i.billing_site_id)'||
                   ' AND (c.annex IS NULL OR c.annex = i.annex)'||
                   ' AND (c.claim IS NULL OR c.claim = i.claim)'||
                   ' AND (c.from_rec_date IS NULL OR i.rec_rate_date >= c.from_rec_date)'||
                   ' AND (c.to_rec_date IS NULL OR i.rec_rate_date <= c.to_rec_date)'||
                 --  ' AND (c.anniversary IS NULL OR c.anniversary = i.anniversary)'||
                   ' AND i.billing_run_id IS NULL'||
                  -- ' AND (c.run_mode <> ''R'' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id, c.bill_date) = ''Y'')'||
                   ' AND blc_billing_pkg.Get_Inst_Compensated_For_Bill(i.installment_class,i.compensated,:1) = ''N'''||
                   ' AND i.amount <> 0'||
                   ' AND i.installment_class <> ''E'''||
                   ' AND i.installment_class <> ''R'''||
                   ' AND NVL(i.item_status,''C'') <> ''N'''||
                   ' AND (c.run_mode = ''I'''||
                          ' OR ((trunc(sysdate) - trunc(i.created_on)) >= nvl(i.min_retain_days,0) AND i.installment_date <= c.run_date + :2 + decode(sign(i.amount),-1,nvl(i.net_horizon,0),decode(i.installment_class,''B'',nvl(i.bill_horizon,0),''D'',nvl(i.bill_horizon,0),''P'',nvl(i.pay_horizon,0),''A'',nvl(i.pay_horizon,0),0))'||
                   ' AND (i.bill_mode = ''D'''||
                          ' OR c.run_mode = ''E'''||
                          ' OR c.run_date >= i.next_date - :3'||
                          ' OR c.run_date < i.next_date - nvl(i.max_retain_days,0))))'||
                   ' AND '||nvl(l_i_eligibility_s, '1=1');

    IF l_blc_run.item_ids IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.item_id IN ('||l_blc_run.item_ids||')';
    END IF;

    IF l_blc_run.account_ids IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.account_id IN ('||l_blc_run.account_ids||')';
    END IF;

    IF l_blc_run.source IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.source = '''||l_blc_run.source||'''';
    END IF;

    IF l_blc_run.agreement IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.agreement = '''||l_blc_run.agreement||'''';
    END IF;

    IF l_blc_run.component IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.component = '''||l_blc_run.component||'''';
    END IF;

    IF l_blc_run.detail IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.detail = '''||l_blc_run.detail||'''';
    END IF;

    IF l_blc_run.party IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.party = '''||l_blc_run.party||'''';
    END IF;

    IF l_blc_run.legal_entity_id IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND i.legal_entity_id = '||l_blc_run.legal_entity_id;
    END IF;
    */ -- rq 1000010464

    /* -- start rq 1000010513
    l_sql_base  := 'SELECT i.installment_id'||
                   ' FROM blc_installments_all i,'||
                        ' blc_run c'||
                   ' WHERE c.run_id = :1'||
                   ' AND (c.run_mode <> ''R'' OR c.bill_site_id = i.billing_site_id)'||
                   ' AND (c.annex IS NULL OR c.annex = i.annex)'||
                   ' AND (c.claim IS NULL OR c.claim = i.claim)'||
                   ' AND (c.from_rec_date IS NULL OR i.rec_rate_date >= c.from_rec_date)'||
                   ' AND (c.to_rec_date IS NULL OR i.rec_rate_date <= c.to_rec_date)'||
                 --  ' AND (c.anniversary IS NULL OR c.anniversary = i.anniversary)'||
                   ' AND i.billing_run_id IS NULL'||
                  -- ' AND (c.run_mode <> ''R'' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id, c.bill_date) = ''Y'')'||
                   ' AND blc_billing_pkg.Get_Inst_Compensated_For_Bill(i.installment_class,i.compensated,:2) = ''N'''||
                   ' AND i.amount <> 0'||
                   ' AND i.installment_class <> ''E'''||
                   ' AND i.installment_class <> ''R'''||
                   ' AND NVL(i.item_status,''C'') <> ''N'''||
                   ' AND (c.run_mode = ''I'''||
                          ' OR ((trunc(sysdate) - trunc(i.created_on)) >= nvl(i.min_retain_days,0) AND i.installment_date <= c.run_date + :3 + decode(sign(i.amount),-1,nvl(i.net_horizon,0),decode(i.installment_class,''B'',nvl(i.bill_horizon,0),''D'',nvl(i.bill_horizon,0),''P'',nvl(i.pay_horizon,0),''A'',nvl(i.pay_horizon,0),0))'||
                   ' AND (i.bill_mode = ''D'''||
                          ' OR c.run_mode = ''E'''||
                          ' OR c.run_date >= i.next_date - :4 - nvl(i.bill_horizon,0)'|| --change :4 to be offset_horizon and add bill_horizon as next_date_offset  --rq 1000010513
                          ' OR c.run_date < i.next_date - nvl(i.max_retain_days,0))))'||
                   ' AND ('||nvl(l_i_eligibility_s, '1=1')||')';
    */
    IF l_reg_bill_to_date = 'BILL_HORIZON'
    THEN
       l_sql_base :=  'SELECT i.installment_id'||
                     ' FROM blc_installments_item_bill i,'||
                          ' blc_run c'||
                     ' WHERE c.run_id = :1'||
                     --' AND (c.run_mode <> ''R'' OR c.bill_site_id = i.billing_site_id)'|| --rq 1000010863
                     --' AND (c.annex IS NULL OR c.annex = i.annex)'|| --21.11.2017 move below to check if annex in cancellation
                     ' AND (c.claim IS NULL OR c.claim = i.claim)'||
                     ' AND (c.from_rec_date IS NULL OR i.rec_rate_date >= c.from_rec_date)'||
                     ' AND (c.to_rec_date IS NULL OR i.rec_rate_date <= c.to_rec_date)'||
                   --  ' AND (c.anniversary IS NULL OR c.anniversary = i.anniversary)'||
                     ' AND i.billing_run_id IS NULL'||
                    -- ' AND (c.run_mode <> ''R'' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id, c.bill_date) = ''Y'')'||
                     ' AND blc_billing_pkg.Get_Inst_Compensated_For_Bill(i.installment_class,i.compensated,:2) = ''N'''||
                     ' AND i.amount <> 0'||
                     --' AND i.installment_class <> ''E'''|| --rq 1000010863
                     --' AND i.installment_class <> ''R'''|| --rq 1000010863
                     ' AND i.installment_class IN (''B'',''P'',''D'',''A'')'||
                     ' AND NVL(i.item_status,''C'') <> ''N'''||
                     ' AND ((c.run_mode = ''I'' OR c.run_mode = ''E'' AND c.bill_method_id IS NOT NULL)'||
                           --' OR ((trunc(sysdate) - trunc(i.created_on)) >= nvl(i.min_retain_days,0)'||
                           ' OR (4=4'||
                                ' AND ((i.bill_mode = ''D'' AND i.installment_date <= c.run_date + :3 + decode(sign(i.amount),-1,nvl(i.net_horizon,0),decode(i.installment_class,''B'',nvl(i.bill_horizon,0),''D'',nvl(i.bill_horizon,0),''P'',nvl(i.pay_horizon,0),''A'',nvl(i.pay_horizon,0),0)))'||
                                     ' OR'||
                                     ' (i.bill_mode = ''R'' AND i.installment_date <= c.run_date + :4 + decode(sign(i.amount),-1,nvl(i.net_horizon,0),decode(i.installment_class,''B'',nvl(i.bill_horizon,0),''D'',nvl(i.bill_horizon,0),''P'',nvl(i.pay_horizon,0),''A'',nvl(i.pay_horizon,0),0))'||
                                     ' AND (c.run_mode = ''E'' OR c.run_date >= i.next_date - :5 - nvl(i.bill_horizon,0) OR c.run_date < i.next_date - nvl(i.max_retain_days,0))))))'||
                     ' AND ('||nvl(l_i_eligibility_s, '1=1')||')';
    ELSE
       l_sql_base  := 'SELECT i.installment_id'||
                     ' FROM blc_installments_item_bill i,'||
                          ' blc_run c'||
                     ' WHERE c.run_id = :1'||
                     --' AND (c.run_mode <> ''R'' OR c.bill_site_id = i.billing_site_id)'|| --rq 1000010863
                     --' AND (c.annex IS NULL OR c.annex = i.annex)'|| --21.11.2017 move below to check if annex in cancellation
                     ' AND (c.claim IS NULL OR c.claim = i.claim)'||
                     ' AND (c.from_rec_date IS NULL OR i.rec_rate_date >= c.from_rec_date)'||
                     ' AND (c.to_rec_date IS NULL OR i.rec_rate_date <= c.to_rec_date)'||
                   --  ' AND (c.anniversary IS NULL OR c.anniversary = i.anniversary)'||
                     ' AND i.billing_run_id IS NULL'||
                    -- ' AND (c.run_mode <> ''R'' OR blc_billing_pkg.Exist_Bill_Relation(i.legal_entity_id, c.bill_site_id, c.bill_date) = ''Y'')'||
                     ' AND blc_billing_pkg.Get_Inst_Compensated_For_Bill(i.installment_class,i.compensated,:2) = ''N'''||
                     ' AND i.amount <> 0'||
                     --' AND i.installment_class <> ''E'''|| --rq 1000010863
                     --' AND i.installment_class <> ''R'''|| --rq 1000010863
                     ' AND i.installment_class IN (''B'',''P'',''D'',''A'')'||
                     ' AND NVL(i.item_status,''C'') <> ''N'''||
                     ' AND ((c.run_mode = ''I'' OR c.run_mode = ''E'' AND c.bill_method_id IS NOT NULL)'||
                           --' OR ((trunc(sysdate) - trunc(i.created_on)) >= nvl(i.min_retain_days,0)'||
                           ' OR (4=4'||
                                ' AND ((i.bill_mode = ''D'' AND i.installment_date <= c.run_date + :3 + decode(sign(i.amount),-1,nvl(i.net_horizon,0),decode(i.installment_class,''B'',nvl(i.bill_horizon,0),''D'',nvl(i.bill_horizon,0),''P'',nvl(i.pay_horizon,0),''A'',nvl(i.pay_horizon,0),0)))'||
                                     ' OR'||
                                     --22.08.2018 replace blc_billing_pkg.Get_Reg_Bill_To_Date with cust_billing_pkg.Get_Reg_Bill_To_Date_2
                                     ' (i.bill_mode = ''R'' AND i.installment_date < insis_blc_global_cust.cust_billing_pkg.Get_Reg_Bill_To_Date_2(i.next_date,i.bill_cycle_id,i.bill_period,c.run_date,i.bill_horizon,:4)'||
                                     ' AND (c.run_mode = ''E'' OR c.run_date >= i.next_date - :5 - nvl(i.bill_horizon,0) OR c.run_date < i.next_date - nvl(i.max_retain_days,0))))))'||
                     ' AND ('||nvl(l_i_eligibility_s, '1=1')||')';
    END IF;
    -- end rq 1000010513

    --begin rq 1000010863
    IF l_blc_run.run_mode = 'R'
    THEN
       l_billing_site_id := l_blc_run.bill_site_id;
       l_sql_base := l_sql_base||' AND i.billing_site_id = :6';

       --begin rq 1000010947 -lock setting value
       /* setting is removed and no need to set it
       Set_Reg_Bill_Time
         (pi_billing_site_id => l_billing_site_id,
          pio_Err            => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          RETURN;
       END IF;
       */
       l_lock_clause := NULL;

       --next row is removed according Gap 112
       --l_sql_base := l_sql_base||' AND insis_blc_global_cust.cust_billing_pkg.Check_Reg_Run_Policy(i.item_type, i.attrib_7, i.agreement) = ''Y'''; -- REG_BILL_MASTER --add custom clause here instead of in bill method becuase of lock in extra billing
       --end rq 1000010947
    ELSE
       l_billing_site_id := NULL;
       l_sql_base := l_sql_base||' AND :6 IS NULL';

       --l_lock_clause := ' FOR UPDATE OF i.billing_run_id NOWAIT'; --rq 1000010947
       l_lock_clause := NULL; --22.08.2018 remove because of replace blc_billing_pkg.Get_Reg_Bill_To_Date with cust_billing_pkg.Get_Reg_Bill_To_Date_2
    END IF;
    --end rq 1000010863

    IF l_blc_run.item_ids IS NOT NULL
    THEN
       IF blc_common_pkg.Convert_List_Number(l_blc_run.item_ids) IS NOT NULL
       THEN
          --l_sql_base := l_sql_base||' AND i.item_id = TO_NUMBER(c.item_ids)';
          l_sql_base := l_sql_base||' AND i.item_id = :7';
          l_run_item_id := TO_NUMBER(l_blc_run.item_ids);
       ELSE
          --l_sql_base := l_sql_base||' AND :7 IS NULL AND i.item_id IN (SELECT * FROM TABLE( blc_common_pkg.Convert_List(c.item_ids)))';
          l_sql_base := l_sql_base||' AND :7 IS NULL AND i.item_id IN ( SELECT regexp_substr( UPPER(REPLACE(c.item_ids,'' '')), ''[^,]+'', 1, level ) FROM dual'||
                                                                      ' CONNECT BY regexp_substr( UPPER(REPLACE(c.item_ids,'' '')), ''[^,]+'', 1, level ) IS NOT NULL )';
          l_run_item_id := NULL;
       END IF;
    ELSE
       l_sql_base := l_sql_base||' AND :7 IS NULL';
    END IF;

    -- 05.11.2019 -- add core logic for account_id calculation and remove clause AND i.account_id = TO_NUMBER(c.account_ids) because it is not work correctly
    IF l_blc_run.account_ids IS NOT NULL
    THEN
       IF blc_common_pkg.Convert_List_Number(l_blc_run.account_ids) IS NOT NULL AND l_run_item_id IS NULL
       THEN
          l_sql_base := l_sql_base||' AND i.account_id = :8';
          l_run_account_id := TO_NUMBER(l_blc_run.account_ids);
       ELSE
          l_sql_base := l_sql_base||' AND :8 IS NULL AND i.account_id IN ( SELECT regexp_substr( UPPER(REPLACE(c.account_ids,'' '')), ''[^,]+'', 1, level ) FROM dual'||
                                                          ' CONNECT BY regexp_substr( UPPER(REPLACE(c.account_ids,'' '')), ''[^,]+'', 1, level ) IS NOT NULL )';
       END IF;
    ELSE
       l_sql_base := l_sql_base||' AND :8 IS NULL';
    END IF;

    /*
    IF l_blc_run.account_ids IS NOT NULL
    THEN
       IF blc_common_pkg.Convert_List_Number(l_blc_run.account_ids) IS NOT NULL
       THEN
          IF l_blc_run.account_ids = '40200000063743'
          THEN
             l_sql_base := l_sql_base||' AND i.account_id = 40200000063743';
          ELSE
             l_sql_base := l_sql_base||' AND i.account_id = TO_NUMBER(c.account_ids)';
          END IF;
       ELSE
          l_sql_base := l_sql_base||' AND i.account_id IN (SELECT * FROM TABLE(blc_common_pkg.Convert_List(c.account_ids)))';
       END IF;
    END IF;
    */

    IF l_blc_run.SOURCE IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND c.source = i.source';
    END IF;

     -- change to add selection for agreement only for case that item_ids IS NULL
    IF l_blc_run.agreement IS NOT NULL AND l_blc_run.item_ids IS NULL
    THEN
       IF l_blc_run.item_ids IS NULL
       THEN
          l_sql_base := l_sql_base||' AND c.agreement = i.agreement';
       END IF;
    END IF;

    IF l_blc_run.component IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND c.component = i.component';
    END IF;

    IF l_blc_run.detail IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND c.detail = i.detail';
    END IF;

    -- Commented on 28.03.2018 LPV-964 - removing the restriction for all annexes not only for cancellation annexes

    --IF l_blc_run.annex IS NOT NULL AND Is_Canc_Annex(l_blc_run.component,l_blc_run.annex) = 'N'  --21.11.2017 add clause for annex only if it is not cancellation annex
    --THEN
       --l_sql_base := l_sql_base||' AND c.annex = i.annex';
    --END IF;

    -- End commented on 28.03.2018 LPV-964

    IF l_blc_run.party IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND c.party = i.party';
    END IF;

    IF l_blc_run.legal_entity_id IS NOT NULL
    THEN
       l_sql_base := l_sql_base||' AND c.legal_entity_id = i.legal_entity_id';
    END IF;

    IF l_run_date_elig = 'N'
    THEN
       l_sql_base := l_sql_base||' AND 1=2';
    END IF;

    SAVEPOINT SELECT_INSTALLMENT;

    po_count := 0;

    IF l_blc_run.bill_method_id IS NOT NULL
    THEN
       IF blc_common_pkg.Get_Lookup_Code(l_blc_run.bill_method_id) <> 'NONE'
       THEN
          l_custom_pkg := Get_Custom_Pkg(l_blc_run.bill_method_id);
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_custom_pkg = '||l_custom_pkg);
          IF l_custom_pkg IS NOT NULL
          THEN
             EXECUTE IMMEDIATE 'BEGIN ' || l_custom_pkg || '.Select_Installments( :pi_billing_run_id, :pi_bill_method_id, :pio_Err, :po_count ); END;'
             USING pi_billing_run_id, l_blc_run.bill_method_id, IN OUT pio_Err, OUT l_count;
          ELSE
             l_i_eligibility_b := Get_I_Eligibility(l_blc_run.bill_method_id);
             blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_STATEMENT,
                                       'l_i_eligibility_b = '||l_i_eligibility_b);
            -- l_sql_select := l_sql_base||' AND '||nvl(l_i_eligibility_b, '1=1')||' AND blc_common_pkg.Get_Lookup_Code(i.bill_method_id) <> ''NONE'' FOR UPDATE OF i.billing_run_id NOWAIT';
             l_sql_select := l_sql_base||' AND ('||nvl(l_i_eligibility_b, '1=1')||') AND ((c.run_mode <> ''R'') OR blc_common_pkg.Get_Lookup_Code(i.bill_method_id) <> ''NONE'')'||l_lock_clause; -- FOR UPDATE OF i.billing_run_id NOWAIT'; -- rq 1000010947
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'l_sql_select = '||l_sql_select);
             l_count := 0;
             l_ins_count := 0;

             OPEN CV FOR
                l_sql_select USING pi_billing_run_id, l_bill_comp_inst, l_horizon_offset, l_horizon_offset, l_horizon_offset, l_billing_site_id, l_run_item_id, l_run_account_id; --add pi_billing_run_id - rq 1000010464, --replace l_next_date_offset with l_horizon_offset -- rq 1000010513, add l_billing_site_id --rq 1000010863
             LOOP
                FETCH CV INTO l_installment_id;
                  EXIT WHEN CV%NOTFOUND;
                    /*
                    SELECT insis_blc_global_cust.cust_billing_pkg.Calculate_Trx_Due_Date(installment_date,item_attrib_8,item_attrib_9,item_type,acc_attrib_0,pi_billing_run_id,account_id,item_id)
                    INTO l_due_date
                    FROM blc_installments_item_bill
                    WHERE installment_id = l_installment_id;
                    */
                    /* 27.08.2018 --move update into bulk
                    UPDATE blc_installments
                    SET billing_run_id = pi_billing_run_id
                        --attrib_6 = to_char(l_due_date,'yyyy-mm-dd') --no need replace ordering by due date with external_id in bill method
                    WHERE installment_id = l_installment_id;
                    */
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_STATEMENT,
                                               'selected installment - installment_id = '||l_installment_id);
                    l_count := l_count + 1;

                    IF l_ids_tab IS NULL
                    THEN
                       l_ids_tab := blc_selected_ids_table( blc_selected_objects(l_installment_id) );
                    ELSE
                       l_ids_tab.EXTEND;
                       l_ids_tab(l_ids_tab.count) := blc_selected_objects(l_installment_id);
                    END IF;

                    IF l_ids_tab.count = 1000
                    THEN
                       FORALL i IN l_ids_tab.FIRST..l_ids_tab.LAST
                          UPDATE blc_installments
                          SET billing_run_id = pi_billing_run_id
                          WHERE installment_id = l_ids_tab(i).object_id;
                       --
                       l_ins_count := l_ins_count + l_ids_tab.count;
                       l_ids_tab := NULL;
                    END IF;
             END LOOP;
             CLOSE CV;

             IF l_ids_tab IS NOT NULL
             THEN
                FORALL i IN l_ids_tab.FIRST..l_ids_tab.LAST
                   UPDATE blc_installments
                   SET billing_run_id = pi_billing_run_id
                   WHERE installment_id = l_ids_tab(i).object_id;
                --
                l_ins_count := l_ins_count + l_ids_tab.count;
                l_ids_tab := NULL;
             END IF;

             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'selected installments: '||l_count||'; update installments: '||l_ins_count);
          END IF;
          po_count := po_count + l_count;
       END IF;
    ELSE
      --l_sql_base := l_sql_base||' AND i.bill_method_id = :6 AND '; --rq 1000010863
      l_sql_base := l_sql_base||' AND i.bill_method_id = :9 AND '; --rq 1000010863
      FOR l_bill_method_rec IN c_bill_methods(l_bill_method_id)
        LOOP
           blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'BEGIN for l_bill_method_id = '||l_bill_method_rec.bill_method_id);
           l_custom_pkg := Get_Custom_Pkg(l_bill_method_rec.bill_method_id);
           blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                     'l_custom_pkg = '||l_custom_pkg);
           IF l_custom_pkg IS NOT NULL
           THEN
              EXECUTE IMMEDIATE 'BEGIN ' || l_custom_pkg || '.Select_Installments( :pi_billing_run_id, :pi_bill_method_id, :pio_Err, :po_count ); END;'
              USING pi_billing_run_id, l_bill_method_rec.bill_method_id, IN OUT pio_Err, OUT l_count;
           ELSE
             --get l_i_eligibility_b --additional selection criteria get from tag_0 of billing method
              l_i_eligibility_b := Get_I_Eligibility(l_bill_method_rec.bill_method_id);
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                        'l_i_eligibility_b = '||l_i_eligibility_b);
             -- l_sql_select := l_sql_base||nvl(l_i_eligibility_b, '1=1')||' FOR UPDATE OF i.billing_run_id NOWAIT';
              l_sql_select := l_sql_base||'('||nvl(l_i_eligibility_b, '1=1')||')'||l_lock_clause; -- FOR UPDATE OF i.billing_run_id NOWAIT'; --rq 1000010947
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                        'l_sql_select = '||l_sql_select);
              l_count := 0;
              l_ins_count := 0;
              OPEN CV FOR
                 l_sql_select USING pi_billing_run_id, l_bill_comp_inst, l_horizon_offset, l_horizon_offset, l_horizon_offset, l_billing_site_id, l_run_item_id, l_run_account_id, l_bill_method_rec.bill_method_id; --add pi_billing_run_id - rq 1000010464 --replace l_next_date_offset with l_horizon_offset -- rq 1000010513, add l_billing_site_id --rq 1000010863
              LOOP
                 FETCH CV INTO l_installment_id;
                  EXIT WHEN CV%NOTFOUND;
                    /*
                    SELECT insis_blc_global_cust.cust_billing_pkg.Calculate_Trx_Due_Date(installment_date,item_attrib_8,item_attrib_9,item_type,acc_attrib_0,pi_billing_run_id,account_id,item_id)
                    INTO l_due_date
                    FROM blc_installments_item_bill
                    WHERE installment_id = l_installment_id;
                    */
                    /* 27.08.2018 --move update into bulk
                    UPDATE blc_installments
                    SET billing_run_id = pi_billing_run_id
                        --attrib_6 = to_char(l_due_date,'yyyy-mm-dd') --no need replace ordering by due date with external_id in bill method
                    WHERE installment_id = l_installment_id;
                    */
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_STATEMENT,
                                               'selected installment - installment_id = '||l_installment_id);
                    l_count := l_count + 1;

                    IF l_ids_tab IS NULL
                    THEN
                       l_ids_tab := blc_selected_ids_table( blc_selected_objects(l_installment_id) );
                    ELSE
                       l_ids_tab.EXTEND;
                       l_ids_tab(l_ids_tab.count) := blc_selected_objects(l_installment_id);
                    END IF;

                    IF l_ids_tab.count = 1000
                    THEN
                       FORALL i IN l_ids_tab.FIRST..l_ids_tab.LAST
                          UPDATE blc_installments
                          SET billing_run_id = pi_billing_run_id
                          WHERE installment_id = l_ids_tab(i).object_id;
                       --
                       l_ins_count := l_ins_count + l_ids_tab.count;
                       l_ids_tab := NULL;
                    END IF;
              END LOOP;
              CLOSE CV;

              IF l_ids_tab IS NOT NULL
              THEN
                 FORALL i IN l_ids_tab.FIRST..l_ids_tab.LAST
                    UPDATE blc_installments
                    SET billing_run_id = pi_billing_run_id
                    WHERE installment_id = l_ids_tab(i).object_id;
                 --
                 l_ins_count := l_ins_count + l_ids_tab.count;
                 l_ids_tab := NULL;
              END IF;
           END IF;

           blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                      'END for l_bill_method_id = '||l_bill_method_rec.bill_method_id||' - selected installments: '||l_count||'; update installments: '||l_ins_count);
          po_count := po_count + l_count;
      END LOOP;
    END IF;
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Select_Bill_Installments - selected installments: '||po_count);
EXCEPTION WHEN OTHERS THEN
    IF CV%isopen
    THEN
      CLOSE CV;
    END IF;

    ROLLBACK TO SELECT_INSTALLMENT;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Select_Bill_Installments', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
        'pi_billing_run_id = '||pi_billing_run_id||' - '|| SQLERRM);
END Select_Bill_Installments;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Select_Bill_Installments_2
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   25.04.2017  creation
--
-- Purpose: Select eligible installments for billing according billing run
-- parameters and additional elibility clause for parameter billing method of run
-- or for all existing billing methods, if parameter is empty
-- Update billing_run_id column in blc_installments to mark one
-- installment as selected . If external run id is given then propose that
-- instalments are already selected

-- Input parameters:
--     pi_external_run_id     NUMBER       External run id
--     pi_billing_run_id      NUMBER       Billing run identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--     po_count               NUMBER      Count of selected installments
--
-- Usage: In billing process
--
-- Exceptions: /*TBD_COM*/
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Select_Bill_Installments_2
   (pi_external_run_id  IN     NUMBER,
    pi_billing_run_id   IN     NUMBER,
    pio_Err             IN OUT SrvErr,
    po_count            OUT    NUMBER)
IS
    l_SrvErrMsg       SrvErrMsg;
    l_log_module      VARCHAR2(240);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Select_Bill_Installments_2';
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Select_Bill_Installments_2');
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_external_run_id = '||pi_external_run_id);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_billing_run_id = '||pi_billing_run_id);
    IF pi_external_run_id IS NOT NULL
    THEN
       SELECT count(*)
       INTO po_count
       FROM blc_installments
       WHERE billing_run_id = pi_billing_run_id;
    ELSE
       cust_billing_pkg.Select_Bill_Installments
                         (pi_billing_run_id   => pi_billing_run_id,
                          pio_Err             => pio_Err,
                          po_count            => po_count);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'po_count = '||po_count);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Select_Bill_Installments_2');
END Select_Bill_Installments_2;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Generate_Trx_Clause
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   07.08.2013  changed - add postprocess parameter in WHERE
--     Fadata   27.12.2013  changed - add ORDER BY clause
--     Fadata   10.01.2014  changed - add in where group of installments
--                                    rec_rate_date which depend on setting
--                                    'RevenueRecognitionBasis' and
--                                    if transaction is in functional cuyrrrency
--                                    or not
--     Fadata   25.04.2017  changed - copy from core and change to use cust
--                                    view blc_installments_item_bill
--
-- Purpose: Generate additional group by clause for group installments in
-- transactions and update statement for blc_installments_all to set
-- column transaction_id with generated transaction id
-- Installments grouping always includes columns billing_run_id,
-- installment_class, item_id, account_id, nvl(bill_currency,currency),
-- postprocess, rec_rate_date
-- Installments grouping can contain ORDER BY clause which will be removed
-- and return as order clause
--
-- Input parameters:
--     pi_i_grouping  VARCHAR2  Installment grouping clause
--
-- Output parameters:
--     po_add_group   VARCHAR2  Group by clause
--     po_update      VARCHAR2  Update statement
--     po_order       VARCHAR2  Order by clause
--
-- Usage: In create transactions to generate dynamic select and update statement
-- on blc_installments_all
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Generate_Trx_Clause
    (pi_i_grouping  IN     VARCHAR2,
     po_add_group   OUT    VARCHAR2,
     po_update      OUT    VARCHAR2,
     po_order       OUT    VARCHAR2)
IS
    l_count    NUMBER;
    l_count_u  NUMBER;
    l_grouping VARCHAR2(32767);
    l_in       NUMBER;
    l_part     VARCHAR2(32767);
BEGIN
  l_in := instr(pi_i_grouping,'ORDER BY');

  IF l_in > 0
  THEN
     l_grouping := rtrim(substr(pi_i_grouping,1,l_in-1));
     po_order := ' '||substr(pi_i_grouping, l_in);
  ELSE
     l_grouping :=  pi_i_grouping;
     po_order := NULL;
  END IF;
  --l_grouping := pi_i_grouping;
  l_count := 0;

  po_update := 'UPDATE blc_installments_item_bill'||
               ' SET transaction_id = :1'||
               ', rec_rate_date = nvl(rec_rate_date,:2)'||
               ' WHERE billing_run_id = :3'||
               ' AND transaction_id IS NULL'||
               ' AND installment_class = :4'||
               ' AND item_id = :5'||
               ' AND account_id = :6'||
               ' AND nvl(postprocess,''-999'') = nvl(:7,''-999'')'||
               ' AND nvl(decode(nvl(bill_currency,currency),:8,NULL,decode(:9,''TRX_DEPEND'',to_char(rec_rate_date,''yyyy-mm-dd''),NULL)),''-999'') = nvl(:10,''-999'')'||
               ' AND nvl(bill_currency,currency) = :11';

  l_count_u := 11;
  LOOP
      l_count := l_count + 1;
      l_count_u := l_count_u + 1;
      IF l_grouping IS NULL
      THEN
         l_part := 'NULL';
      ELSE
         l_in := instr(l_grouping,';');

         IF l_in = 0
         THEN
            l_part := trim(l_grouping);
            l_grouping := NULL;
         ELSE
            l_part := trim(substr(l_grouping,1,l_in-1));
            l_grouping := substr(l_grouping,l_in+1);
         END IF;
      END IF;
      po_add_group := po_add_group||', '||l_part;
      po_update := po_update||' AND nvl('||l_part||',''-999'') = nvl(:'||l_count_u||',''-999'')';
    EXIT WHEN l_count = 10;
  END LOOP;

END Generate_Trx_Clause;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_I_Grouping
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
-- Purpose: Get installment grouping clause for a given billing method
-- billing method is a lookup_id from lookup_set BILL_METHODS
-- or IMMEDIATE_BILLING_METHOD
-- Grouping clause is written in tag_1
-- Posible attributes in group clause are all columns from view
-- blc_installments_all, use ';' to separate columns
-- Example:
-- sign(amount); decode(installment_class, 'B', 'RCVBL','P', 'PAY', 'GEN')
--
-- Input parameters:
--     pi_bill_method_id  NUMBER     Billing method identifier (required)
--
-- Returns:
--     installment grouping clause
--
-- Usage: In transaction creation as additional group by clause
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_I_Grouping
   (pi_bill_method_id     IN     NUMBER)
RETURN VARCHAR2
IS
    l_value blc_lookups.tag_1%TYPE;
BEGIN
   SELECT tag_1
   INTO l_value
   FROM blc_lookups
   WHERE lookup_id = pi_bill_method_id;

   RETURN l_value;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
      blc_log_pkg.insert_message('blc_billing_pkg.Get_I_Grouping', C_LEVEL_EXCEPTION,
                        'pi_bill_method_id = '||pi_bill_method_id||' - '||SQLERRM);
      RETURN NULL;
END Get_I_Grouping;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Trx_Classifying
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
-- Purpose: Get transaction classifying rule for a given billing method
-- billing method is a lookup_id from lookup_set BILL_METHODS
-- or IMMEDIATE_BILLING_METHOD
-- Classifying rule is written in tag_2
-- Posible attributes in classifying rule are all columns from view
-- blc_installments_all and have to be written with decode or some custom
-- function
-- Example:
-- decode(installment_class, 'B', 'RCVBL','P', 'PAY', 'GEN')
--
-- Input parameters:
--     pi_bill_method_id  NUMBER     Billing method identifier (required)
--
-- Returns:
--     transaction classifying rule
--
-- Usage: In transaction creation for calculation of transaction type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Trx_Classifying
   (pi_bill_method_id     IN     NUMBER)
RETURN VARCHAR2
IS
    l_value blc_lookups.tag_2%TYPE;
BEGIN
   SELECT tag_2
   INTO l_value
   FROM blc_lookups
   WHERE lookup_id = pi_bill_method_id;

   RETURN l_value;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
      blc_log_pkg.insert_message('blc_billing_pkg.Get_Trx_Classifying', C_LEVEL_EXCEPTION,
                'pi_bill_method_id = '||pi_bill_method_id||' - '||SQLERRM);
      RETURN NULL;
END Get_Trx_Classifying;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Trx_Update
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   25.09.2014  change - add check of update statement for proper
--                                   update and where clauses
--                                   if update ane where clauses are missing
--                                   than add them
--                                   rq 1000009158
--
-- Purpose: Get transaction update statement for a given billing method
-- billing method is a lookup_id from lookup_set BILL_METHODS
-- or IMMEDIATE_BILLING_METHOD
-- Transaction update statement is written in tag_3
-- Write update when have to transfer some additional values in transaction
-- attributes from included installments
-- Example:
-- UPDATE blc_transactions t
-- SET (t.attrib_0, t.attrib_1)=
--      (SELECT max(i.detail), min(i.detail)
--       FROM blc_installments_all i
--       WHERE i.transaction_id = t.transaction_id )
-- WHERE t.transaction_id = :1
--
-- Input parameters:
--     pi_bill_method_id  NUMBER     Billing method identifier (required)
--
-- Returns:
--     transaction update statement
--
-- Usage: In transaction creation for populating transaction attributes
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Trx_Update
   (pi_bill_method_id     IN     NUMBER)
RETURN VARCHAR2
IS
    l_value blc_lookups.tag_3%TYPE;
BEGIN
   SELECT tag_3
   INTO l_value
   FROM blc_lookups
   WHERE lookup_id = pi_bill_method_id;

   IF l_value IS NOT NULL
   THEN
      IF NOT (upper(l_value) LIKE 'UPDATE BLC_TRANSACTIONS%' AND upper(l_value) LIKE '%WHERE %TRANSACTION_ID = :1')
      THEN
         l_value := 'UPDATE blc_transactions_all t SET '||l_value||' WHERE t.transaction_id = :1';
      END IF;
   END IF;

   RETURN l_value;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
      blc_log_pkg.insert_message('blc_billing_pkg.Get_Trx_Update', C_LEVEL_EXCEPTION,
            'pi_bill_method_id = '||pi_bill_method_id||' - '||SQLERRM);
      RETURN NULL;
END Get_Trx_Update;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Create_Bill_Transactions
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   07.08.2013  changed - add postprocess in group by
--     Fadata   27.12.2013  changed - add order by
--     Fadata   10.01.2014  changed - group installments by rec_rate_date depend
--                                    on setting 'RevenueRecognitionBasis' and
--                                    if transaction is in functional currency
--                                    or not
--     Fadata   04.03.2014  changed - set to null bill methods for regular
--                                    bill in run variable
--                                    rq 1000008191
--     Fadata   11.07.2014  changed - change sign of transaction amount in case
--                                    that transaction class is different from
--                                    installment class
--                                    rq 1000008835
--     Fadata   15.08.2014  changed - populate pay_way_id and pay_instr
--                                    rq 1000009023
--     Fadata   26.08.2014  changed - do not create transactions in case that
--                                    given billing method is NONE
--                                    rq 1000009066
--     Fadata   26.08.2014  changed - populate column line_number
--                                    rq 1000009258
--     Fadata   31.10.2014  changed - Add parameters fraction_type and lob in
--                                    call Calc_Pay_Way_Instr
--                                    rq 1000009291
--     Fadata   06.11.2014  changed - Change in call Calc_Pay_Way_Instr
--                                    pi_to_date to be minimum of installment
--                                    due_dates instead of transaction due date
--                                    rq 1000009317
--     Fadata   07.11.2014  changed - always call Recalculate_transaction
--                                    to populate transaction rate and rate_date
--                                    rq 1000009319
--     Fadata   06.04.2015  changed - add procedure specification, add savepoint
--                                    and rollback
--                                    rq 1000009741
--     Fadata   14.04.2015  changed - populate line_number with total_count of
--                                    transactions
--                                    rq 1000009750
--     Fadata   02.06.2015  changed - move recalculate transation after
--                                    transaction update
--                                    rq 1000009853
--     Fadata   15.08.2015  changed - get transaction org_id from installment
--                                    org_id instead of run bill_to_site_id
--                                    rq 1000009995
--     Fadata   15.08.2015  changed - get transaction org_id from installment
--                                    org_id instead of run bill_to_site_id
--                                    rq 1000009995
--     Fadata   11.11.2015  changed - when bill_site_id of run is global
--                                    organization (org_id = 0) use transaction
--                                    org_id to get transaction type
--                                    rq 1000010180
--     Fadata   24.03.2016  changed - add parameter pi_usage_acc_class and
--                                    pi_external_id when
--                                    call Calc_Pay_Way_Instr
--                                    rq 1000010381
--     Fadata   09.05.2016  changed - add bind variable for billing_run_id
--                                    rq 1000010464
--     Fadata   17.03.2017  changed - exclude lock for update for regular
--                                    billing runs
--                                    rq 1000010947
--     Fadata   25.04.2017  changed - copy from core and change to use cust
--                                    view blc_installments_item_bill
--     Fadata   13.09.2018  changed - call cust function for get pay way
--                                    LPV-1768
--
-- Purpose: Create biil transactions for selected installments for
-- given biling_run_id
-- Actions:
--     1) Group installments by installment_class, item_id, account_id,
--       nvl(bill_currency,currency) and additional group clause;
--     2) Calculate transaction type according classifying rule, calculate amount,
--       fc_amount and other required columns.
--       Possible statuses of created transactions are
--       'I' - Invalid because no exchange rates
--       'V' - Valid
--     3) Insert row into blc_transaction for each group;
--     4) Link installments to the created transaction as update column
--       transaction_id in blc_installments;
--     5) Execute additional transaction update statement to populate
--       transaction attributes;
-- Additional group clause, classifying rule and transaction update statement are
-- taken for parameter billing method of run or for distinct billing methods
-- of accounts for selected installments, if parameter is empty
--
-- Input parameters:
--     pi_billing_run_id      NUMBER       Billing run identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: In billing process
--
-- Exceptions:
-- 1) When transaction classifying rule is empty for using billing method
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Bill_Transactions
   (pi_billing_run_id   IN     NUMBER,
    pio_Err             IN OUT SrvErr)
IS
    TYPE cv_typ IS REF CURSOR;
    CV cv_typ;

    l_blc_run   blc_run_type;

   /* CURSOR c_inst IS
       SELECT installment_id
       FROM blc_installments
       WHERE billing_run_id = pi_billing_run_id
       AND transaction_id IS NULL
       FOR UPDATE of transaction_id NOWAIT; */

    CURSOR c_inst IS
       SELECT installment_id
       FROM blc_installments
       WHERE billing_run_id = pi_billing_run_id
       AND transaction_id IS NULL
       FOR UPDATE NOWAIT;

    CURSOR c_bill_methods(x_bill_method_id IN NUMBER, x_billing_site_id IN NUMBER) IS
        SELECT DISTINCT DECODE(x_bill_method_id, NULL, bill_method_id, NULL) bill_method_id, x_billing_site_id billing_site_id
        FROM blc_installments_item_bill
        WHERE billing_run_id = pi_billing_run_id
        AND transaction_id IS NULL
        AND(( x_bill_method_id IS NOT NULL AND blc_common_pkg.Get_Lookup_Code(x_bill_method_id) <> 'NONE')
           OR
            ( x_bill_method_id IS NULL AND blc_common_pkg.Get_Lookup_Code(bill_method_id) <> 'NONE'));
    --get billing_site from run, not from account
   /* CURSOR c_bill_methods(x_bill_method_id IN NUMBER) IS
        SELECT DISTINCT DECODE(x_bill_method_id, NULL, bill_method_id, NULL) bill_method_id, billing_site_id
        FROM blc_installments_all
        WHERE billing_run_id = pi_billing_run_id
        AND transaction_id IS NULL;  */

    l_SrvErrMsg          SrvErrMsg;
    l_i_grouping         VARCHAR2(2000);
    l_trx_classifying    VARCHAR2(2000);
    l_trx_update         VARCHAR2(2000);
    l_sql_select         VARCHAR2(32767);
    l_add_group          VARCHAR2(32767);
    l_sql_update         VARCHAR2(32767);

    l_installment_class  BLC_INSTALLMENTS_ITEM_BILL.installment_class%TYPE;
    l_item_id            BLC_INSTALLMENTS_ITEM_BILL.item_id%TYPE;
    l_account_id         BLC_INSTALLMENTS_ITEM_BILL.account_id%TYPE;
    l_bill_currency      BLC_INSTALLMENTS_ITEM_BILL.bill_currency%TYPE;
    l_currency           BLC_INSTALLMENTS_ITEM_BILL.currency%TYPE;
    l_item_name          BLC_INSTALLMENTS_ITEM_BILL.item_name%TYPE;
    l_due_period         BLC_INSTALLMENTS_ITEM_BILL.due_period%TYPE;
    l_grace_period       BLC_INSTALLMENTS_ITEM_BILL.grace_period%TYPE;
    l_notes              BLC_INSTALLMENTS_ITEM_BILL.notes%TYPE;
    l_due_date           DATE;
    l_trx_amount         NUMBER;
    l_trx_type           BLC_TRANSACTIONS.transaction_type%TYPE;
    l_value_1            VARCHAR2(500);
    l_value_2            VARCHAR2(500);
    l_value_3            VARCHAR2(500);
    l_value_4            VARCHAR2(500);
    l_value_5            VARCHAR2(500);
    l_value_6            VARCHAR2(500);
    l_value_7            VARCHAR2(500);
    l_value_8            VARCHAR2(500);
    l_value_9            VARCHAR2(500);
    l_value_10           VARCHAR2(500);
    l_count              NUMBER;
  --  l_fc_currency        BLC_TRANSACTIONS_ALL.fc_currency%TYPE;
    l_due_calc_type      VARCHAR2(30);
    l_rev_rec_accounting VARCHAR2(30);
    l_blc_transactions   BLC_TRANSACTIONS_TYPE;
    l_log_module         VARCHAR2(240);
    l_exp_error          EXCEPTION;
    l_total_count        NUMBER;
 --   l_precision          NUMBER;
 --   l_fc_precision       NUMBER;
    l_SrvErr             SrvErr;
    l_custom_pkg         VARCHAR2(100);
    l_count_curr         NUMBER;
    l_rate_type          VARCHAR2(30);
    l_country            VARCHAR2(30);
    l_notes_val          VARCHAR2(4000);
    l_legal_entity_id    NUMBER;
    l_round_inst_amount  NUMBER;
    l_rec_rate_date      DATE;
    l_postprocess        VARCHAR2(30);
    l_order              VARCHAR2(32767);
    l_gr_rec_rate_date   VARCHAR2(50);
    l_trx_sign           NUMBER; --rq 1000008835
    l_fraction_type      VARCHAR2(30);
    l_lob                VARCHAR2(30);
    l_org_id             NUMBER; --rq 1000009995
    l_bill_site_id       NUMBER; --rq 1000010180
    l_usage_acc_class    VARCHAR2(30);
    l_external_id        VARCHAR2(30);
    l_open_flag          VARCHAR2(2000);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Create_Bill_Transactions';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Create_Bill_Transactions');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_billing_run_id = '||pi_billing_run_id);

    l_blc_run := NEW blc_run_type(pi_billing_run_id, pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_billing_run_id = '||pi_billing_run_id||' - '||
                                  pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
    END IF;

    IF l_blc_run.run_mode = 'R' AND l_blc_run.bill_method_id IS NOT NULL
    THEN
       l_blc_run.bill_method_id := NULL;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'l_blc_run.bill_method_id = '||l_blc_run.bill_method_id);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_blc_run.bill_date = '||to_char(l_blc_run.bill_date,'dd-mm-yyyy'));

    IF l_blc_run.bill_method_id IS NOT NULL AND blc_common_pkg.Get_Lookup_Code(l_blc_run.bill_method_id) <> 'NONE'
    THEN
       l_custom_pkg := Get_Custom_Pkg(l_blc_run.bill_method_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'l_custom_pkg = '||l_custom_pkg);
       IF l_custom_pkg IS NULL
       THEN
          --get l_i_grouping -- grouping criteria - get from tag_1 of billing method
          l_i_grouping := Get_I_Grouping(l_blc_run.bill_method_id);
        /*  IF l_i_grouping IS NULL
          THEN
             l_i_grouping := 'installment_id';
          END IF; */
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_i_grouping = '||l_i_grouping);
          Generate_Trx_Clause (l_i_grouping,
                               l_add_group,
                               l_sql_update,
                               l_order);
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_add_group = '||l_add_group);
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_sql_update = '||l_sql_update);
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_order = '||l_order);
          --get l_trx_classifying -- classifying criteria - get from tag_2 of billing method
          l_trx_classifying := Get_Trx_Classifying(l_blc_run.bill_method_id);
          IF l_trx_classifying IS NULL
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Create_Bill_Transactions', 'blc_billing_pkg.CBT.Missing_Trx_Classifying','bill_method_id = '||l_blc_run.bill_method_id );
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
             RAISE l_exp_error;
             --l_trx_classifying := 'decode(installment_class, ''B'', ''RCVBL'',''P'', ''PAY'', ''GEN'')';
          END IF;
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_trx_classifying = '||l_trx_classifying);
          --get l_trx_update -- get update addtional transaction attribute - get from tag_3 of billing method
          l_trx_update := Get_Trx_Update(l_blc_run.bill_method_id);
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'l_trx_update = '||l_trx_update);
       END IF;
    END IF;

    -- lock installment for given pi_billing_run_id
    IF nvl(l_blc_run.run_mode, '-999') <> 'R'  -- do not lock regular - rq 1000010947
    THEN
       OPEN c_inst;
       CLOSE c_inst;
    END IF;

    SAVEPOINT TRX_CREATE;

    l_total_count := 0;
    FOR l_bill_method_rec IN c_bill_methods(l_blc_run.bill_method_id, l_blc_run.bill_site_id)
        LOOP
           IF l_blc_run.bill_method_id IS NOT NULL
           THEN
              blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'BEGIN for billing_site_id = '||l_bill_method_rec.billing_site_id);
           ELSE
              blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'BEGIN for billing_site_id = '||l_bill_method_rec.billing_site_id||' and bill_method_id = '||l_bill_method_rec.bill_method_id);
              l_custom_pkg := Get_Custom_Pkg(l_bill_method_rec.bill_method_id);
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                        'l_custom_pkg = '||l_custom_pkg);
           END IF;

           IF l_custom_pkg IS NOT NULL
           THEN
              IF l_blc_run.bill_method_id IS NOT NULL
              THEN
                 EXECUTE IMMEDIATE 'BEGIN ' || l_custom_pkg || '.Create_Transactions( :pi_billing_run_id, :pi_bill_method_id, :pi_billing_site_id, :pi_run_mode, :pi_bill_date, :pi_trx_rate_date, :pio_Err, :po_count ); END;'
                 USING pi_billing_run_id, l_blc_run.bill_method_id, l_bill_method_rec.billing_site_id, l_blc_run.run_mode, l_blc_run.bill_date, l_blc_run.gl_date, IN OUT pio_Err, OUT l_count;
              ELSE
                 EXECUTE IMMEDIATE 'BEGIN ' || l_custom_pkg || '.Create_Transactions( :pi_billing_run_id, :pi_bill_method_id, :pi_billing_site_id, :pi_run_mode, :pi_bill_date, :pi_trx_rate_date, :pio_Err, :po_count ); END;'
                 USING pi_billing_run_id, l_bill_method_rec.bill_method_id, l_bill_method_rec.billing_site_id, l_blc_run.run_mode, l_blc_run.bill_date, l_blc_run.gl_date, IN OUT pio_Err, OUT l_count;
              END IF;
              l_total_count := l_total_count + l_count;
           ELSE
              l_count := 0;

              --get due_date calculation type
              l_due_calc_type := blc_billing_pkg.Get_Due_Calc_Type(l_bill_method_rec.billing_site_id,l_blc_run.bill_date);
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'l_due_calc_type = '||l_due_calc_type);
            /*  IF l_due_calc_type IS NULL
              THEN
                 srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Create_Bill_Transactions', 'blc_billing_pkg.CBT.Missing_Due_Calc_type' );
                 srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                 RAISE l_exp_error;
              END IF;   */
              --get revenue recognition accounting basis
              l_rev_rec_accounting := blc_billing_pkg.Get_Rev_Rec_Accounting(l_bill_method_rec.billing_site_id,l_blc_run.bill_date);
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'l_rev_rec_accounting = '||l_rev_rec_accounting);

               IF l_blc_run.bill_method_id IS NULL
               THEN
                  IF blc_common_pkg.Get_Lookup_Code(l_bill_method_rec.bill_method_id) = 'NONE'
                  THEN
                     srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Create_Bill_Transactions', 'blc_billing_pkg.CBT.None_Bill_Method');
                     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                     RAISE l_exp_error;
                  END IF;
                  --get l_i_grouping -- grouping criteria - get from tag_1 of current billing method
                  l_i_grouping := Get_I_Grouping(l_bill_method_rec.bill_method_id);
                  /*IF l_i_grouping IS NULL
                  THEN
                     l_i_grouping := 'installment_id';
                  END IF; */
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_STATEMENT,
                                             'l_i_grouping = '||l_i_grouping);
                  Generate_Trx_Clause (l_i_grouping,
                                       l_add_group,
                                       l_sql_update,
                                       l_order);
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_STATEMENT,
                                             'l_add_group = '||l_add_group);
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_STATEMENT,
                                             'l_sql_update = '||l_sql_update);
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_STATEMENT,
                                             'l_order = '||l_order);
                  --get l_trx_classifying -- classifying criteria - get from tag_2 of billing method
                  l_trx_classifying := Get_Trx_Classifying(l_bill_method_rec.bill_method_id);
                  IF l_trx_classifying IS NULL
                  THEN
                     srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Create_Bill_Transactions', 'blc_billing_pkg.CBT.Missing_Trx_Classifying','bill_method_id = '||l_bill_method_rec.bill_method_id );
                     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                     RAISE l_exp_error;
                     --l_trx_classifying := 'decode(installment_class, ''B'', ''RCVBL'',''P'', ''PAY'', ''GEN'')';
                  END IF;
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_STATEMENT,
                                             'l_trx_classifying = '||l_trx_classifying);
                  -- get l_trx_update -- get additional update for transaction attributes
                  -- get from tag_3 of billing method
                  l_trx_update := Get_Trx_Update(l_bill_method_rec.bill_method_id);
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_STATEMENT,
                                             'l_trx_update = '||l_trx_update);

                  l_sql_select := 'SELECT installment_class,item_id,account_id,postprocess,legal_entity_id,nvl(bill_currency,currency),'||
                                         'max(currency),item_name,bin_org_id,min(rec_rate_date),due_period,grace_period,'||
                                         'min(installment_date),sum(amount),sum(round(amount,:1)),max(notes),'||
                                         'max(fraction_type),max(lob),max(blc_common_pkg.Get_Lookup_Tag_Value(''INSTALLMENT_TYPES'',installment_type,bin_org_id,NULL,4)),max(external_id),'||
                                         'count(distinct currency),'||
                                         'decode(nvl(bill_currency,currency),blc_common_pkg.Get_Func_Currency(legal_entity_id,trunc(sysdate)),NULL,decode('''||l_rev_rec_accounting||''',''TRX_DEPEND'',to_char(rec_rate_date,''yyyy-mm-dd''),NULL)),'||
                                         l_trx_classifying||l_add_group||
                                ' FROM blc_installments_item_bill'||
                                ' WHERE billing_run_id = :2'||
                                ' AND bill_method_id = '||l_bill_method_rec.bill_method_id||
                 --               ' AND billing_site_id = '||l_bill_method_rec.billing_site_id||
                                ' AND transaction_id IS NULL'||
                                ' GROUP BY installment_class,item_id,account_id,postprocess,legal_entity_id,nvl(bill_currency,currency),'||
                                          'item_name,bin_org_id,due_period,grace_period,'||
                                          'decode(nvl(bill_currency,currency),blc_common_pkg.Get_Func_Currency(legal_entity_id,trunc(sysdate)),NULL,decode('''||l_rev_rec_accounting||''',''TRX_DEPEND'',to_char(rec_rate_date,''yyyy-mm-dd''),NULL))'||
                                           l_add_group||l_order;
               ELSE
                   l_sql_select := 'SELECT installment_class,item_id,account_id,postprocess,legal_entity_id,nvl(bill_currency,currency),'||
                                          'max(currency),item_name,bin_org_id,min(rec_rate_date),due_period,grace_period,'||
                                          'min(installment_date),sum(amount),sum(round(amount,:1)),max(notes),'||
                                          'max(fraction_type),max(lob),max(blc_common_pkg.Get_Lookup_Tag_Value(''INSTALLMENT_TYPES'',installment_type,bin_org_id,NULL,4)),max(external_id),'||
                                          'count(distinct currency),'||
                                          'decode(nvl(bill_currency,currency),blc_common_pkg.Get_Func_Currency(legal_entity_id,trunc(sysdate)),NULL,decode('''||l_rev_rec_accounting||''',''TRX_DEPEND'',to_char(rec_rate_date,''yyyy-mm-dd''),NULL)),'||
                                          l_trx_classifying||l_add_group||
                                  ' FROM blc_installments_item_bill'||
                                  ' WHERE billing_run_id = :2'||
                   --               ' AND billing_site_id = '||l_bill_method_rec.billing_site_id||
                                  ' AND transaction_id IS NULL'||
                                  ' GROUP BY installment_class,item_id,account_id,postprocess,legal_entity_id,nvl(bill_currency,currency),'||
                                            'item_name,bin_org_id,due_period,grace_period,'||
                                            'decode(nvl(bill_currency,currency),blc_common_pkg.Get_Func_Currency(legal_entity_id,trunc(sysdate)),NULL,decode('''||l_rev_rec_accounting||''',''TRX_DEPEND'',to_char(rec_rate_date,''yyyy-mm-dd''),NULL))'||
                                            l_add_group||l_order;
               END IF;
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_STATEMENT,
                                         'l_sql_select = '||l_sql_select);

               OPEN CV FOR
                   l_sql_select USING nvl(blc_appl_cache_pkg.g_fc_precision,2), pi_billing_run_id; --,blc_appl_cache_pkg.g_fc_currency,l_rev_rec_accounting,blc_appl_cache_pkg.g_fc_currency,l_rev_rec_accounting; --add pi_billing_run_id - rq 1000010464
               LOOP
                  FETCH CV
                     INTO l_installment_class, l_item_id, l_account_id, l_postprocess, l_legal_entity_id, l_bill_currency,
                          l_currency, l_item_name, l_org_id, l_rec_rate_date,l_due_period, l_grace_period,
                          l_due_date, l_trx_amount, l_round_inst_amount, l_notes,
                          l_fraction_type, l_lob, l_usage_acc_class, l_external_id,
                          l_count_curr,
                          l_gr_rec_rate_date,
                          l_trx_type, l_value_1, l_value_2, l_value_3, l_value_4, l_value_5, l_value_6,
                          l_value_7, l_value_8, l_value_9, l_value_10;
                   EXIT WHEN CV%NOTFOUND;

                   l_blc_transactions := NEW blc_transactions_type;

                   -- init legal entity, functional currency and country
                   blc_appl_cache_pkg.init_le(l_legal_entity_id, pio_Err);
                   IF NOT srv_error.rqStatus( pio_Err )
                   THEN
                      RAISE l_exp_error;
                   END IF;
                   --rg 1000010180
                   IF l_bill_method_rec.billing_site_id = 0
                   THEN
                      l_bill_site_id := l_org_id;
                   ELSE
                      l_bill_site_id := l_bill_method_rec.billing_site_id;
                   END IF;
                   --l_blc_transactions.transaction_class := Get_Trx_Class(l_trx_type,l_bill_method_rec.billing_site_id,NVL(blc_appl_cache_pkg.g_to_date,l_blc_run.bill_date), l_rate_type);
                   blc_billing_pkg.Get_Trx_Class(l_trx_type,
                                                 l_bill_site_id,
                                                 NVL(blc_appl_cache_pkg.g_to_date,l_blc_run.bill_date),
                                                 l_rate_type,
                                                 l_blc_transactions.transaction_class,
                                                 l_open_flag);

                   --rg 1000010180
                   --rq 1000008835
                   l_trx_sign := blc_process_pkg.Get_Sign_Inst_Amount(l_blc_transactions.transaction_class,l_installment_class);
                   --rq 1000008835
                   l_rate_type := nvl(l_rate_type,'FIXING');
                   l_blc_transactions.transaction_type := l_trx_type;
                   l_blc_transactions.transaction_date := NVL(blc_appl_cache_pkg.g_to_date,l_blc_run.bill_date);
                   l_blc_transactions.currency := l_bill_currency;
                   l_blc_transactions.status := 'I';
                   l_blc_transactions.fc_currency := blc_appl_cache_pkg.g_fc_currency;
                   l_blc_transactions.legal_entity := l_legal_entity_id;
                   l_blc_transactions.org_id := l_org_id; --l_blc_run.bill_site_id; -- rq 1000009995
                   /* rq 1000009319
                   IF l_bill_currency = l_currency AND l_bill_currency = blc_appl_cache_pkg.g_fc_currency AND l_count_curr = 1
                   THEN
                      --rq 1000008835
                      --l_blc_transactions.amount := l_round_inst_amount; --round(l_trx_amount,blc_appl_cache_pkg.g_fc_precision);
                      l_blc_transactions.amount := l_round_inst_amount*l_trx_sign;
                      --rq 1000008835
                      l_blc_transactions.fc_amount := l_blc_transactions.amount;
                      l_blc_transactions.fc_variance := 0; --l_blc_transactions.fc_amount - l_round_inst_amount;
                      l_blc_transactions.variance := 0; --l_blc_transactions.fc_variance;
                   ELSE
                      l_blc_transactions.amount := NULL;
                      l_blc_transactions.fc_amount := NULL;
                      l_blc_transactions.status := 'I';
                      l_blc_transactions.rate_date := l_blc_run.gl_date;
                   END IF;
                   */
                   l_blc_transactions.amount := NULL;
                   l_blc_transactions.fc_amount := NULL;
                   l_blc_transactions.status := 'I';
                   l_blc_transactions.rate_date := l_blc_run.gl_date;
                   l_blc_transactions.item_name := l_item_name;
                   l_blc_transactions.notes := l_notes;
                   --
                   IF l_due_calc_type = 'TRX'
                   THEN
                      l_blc_transactions.due_date := NVL(blc_appl_cache_pkg.g_to_date,l_blc_run.bill_date) + l_due_period;
                   ELSE
                      l_blc_transactions.due_date := l_due_date;
                   END IF;
                   --
                   l_blc_transactions.grace := l_blc_transactions.due_date + nvl(l_grace_period,0);
                   l_blc_transactions.account_id := l_account_id;
                   l_blc_transactions.item_id := l_item_id;
                   l_blc_transactions.billing_run_id := pi_billing_run_id;

                   --LPV-1768 call Calc_Policy_Pay_Way before core Calc_Pay_Way_Instr
                   Calc_Policy_Pay_Way
                         (pi_item_id           => l_blc_transactions.item_id,
                          pi_org_id            => l_blc_transactions.org_id,
                          pi_to_date           => l_due_date,
                          po_pay_way_id        => l_blc_transactions.pay_way_id,
                          po_pay_instr_id      => l_blc_transactions.pay_instr,
                          pio_Err              => pio_Err);
                   IF NOT srv_error.rqStatus( pio_Err )
                   THEN
                      RAISE l_exp_error;
                   END IF;

                   IF l_blc_transactions.pay_way_id IS NULL --LPV-1768
                   THEN
                       blc_billing_pkg.Calc_Pay_Way_Instr
                             (pi_item_id           => l_blc_transactions.item_id,
                              pi_account_id        => l_blc_transactions.account_id,
                              pi_trx_class         => l_blc_transactions.transaction_class,
                              pi_org_id            => l_blc_transactions.org_id,
                              pi_to_date           => l_due_date, --l_blc_transactions.due_date, --rq 1000009317
                              pi_curr              => l_blc_transactions.currency,
                              pi_fc_curr           => l_blc_transactions.fc_currency,
                              pi_fraction_type     => l_fraction_type,
                              pi_lob               => l_lob,
                              pi_usage_acc_class   => l_usage_acc_class,
                              pi_external_id       => l_external_id,
                              po_pay_way_id        => l_blc_transactions.pay_way_id,
                              po_pay_instr         => l_blc_transactions.pay_instr,
                              pio_Err              => pio_Err);
                       IF NOT srv_error.rqStatus( pio_Err )
                       THEN
                          RAISE l_exp_error;
                       END IF;
                   END IF;

                   blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                        'l_account_id = '||l_blc_transactions.account_id);
                   blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                        'l_trx_currency = '||l_blc_transactions.currency);
                   blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                        'l_trx_amount = '||l_blc_transactions.amount);
                   blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'l_trx_type = '||l_blc_transactions.transaction_type);

                   l_count := l_count + 1;

                   --begin rq 1000009750
                   --l_blc_transactions.line_number := l_count;
                   l_total_count := l_total_count + 1;
                   l_blc_transactions.line_number := l_total_count;
                   --end rq 1000009750

                   blc_log_pkg.insert_message(l_log_module,
                                              C_LEVEL_STATEMENT,
                                             'l_line_number = '||l_blc_transactions.line_number);

                   IF NOT l_blc_transactions.insert_blc_transactions ( pio_Err )
                   THEN
                      RAISE l_exp_error;
                   END IF;

                   blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'created transcation - transaction_id = '||l_blc_transactions.transaction_id);

                   EXECUTE IMMEDIATE l_sql_update USING l_blc_transactions.transaction_id,l_blc_transactions.transaction_date,
                                 pi_billing_run_id, l_installment_class,
                                 l_item_id, l_account_id, l_postprocess,
                                 blc_appl_cache_pkg.g_fc_currency,l_rev_rec_accounting,
                                 l_gr_rec_rate_date, l_bill_currency,
                                 l_value_1, l_value_2, l_value_3, l_value_4,
                                 l_value_5, l_value_6, l_value_7, l_value_8,
                                 l_value_9, l_value_10;

                   blc_log_pkg.insert_message(l_log_module,
                                              C_LEVEL_STATEMENT,
                                             'included installments into transaction: '||SQL%ROWCOUNT||' - transaction_id = '||l_blc_transactions.transaction_id);

                   IF l_trx_update IS NOT NULL
                   THEN
                      EXECUTE IMMEDIATE l_trx_update USING l_blc_transactions.transaction_id;
                      blc_log_pkg.insert_message(l_log_module,
                                                 C_LEVEL_STATEMENT,
                                                 'updated transaction: '||SQL%ROWCOUNT||' - transaction_id = '||l_blc_transactions.transaction_id);
                      --requery transaction type
                      l_blc_transactions := blc_transactions_type(l_blc_transactions.transaction_id);
                   END IF;

                   IF NOT blc_doc_util_pkg.Recalculate_Transaction
                         (pio_trx => l_blc_transactions,
                          pi_rev_rec_acct => l_rev_rec_accounting,
                          pi_trx_rate_type => l_rate_type,
                          pio_Err => pio_Err,
                          po_notes => l_notes_val)
                   THEN
                      IF NOT srv_error.rqStatus( pio_Err )
                      THEN
                         RAISE l_exp_error;
                      END IF;
                      blc_log_pkg.insert_message(l_log_module,
                                                 C_LEVEL_STATEMENT,
                                                 l_notes_val);
                   END IF;


                END LOOP;
              CLOSE CV;
          END IF;
          IF l_blc_run.bill_method_id IS NOT NULL
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'END for billing_site_id = '||l_bill_method_rec.billing_site_id||' - created transactions: '||l_count);
          ELSE
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'END for billing_site_id = '||l_bill_method_rec.billing_site_id||' and bill_method_id = '||l_bill_method_rec.bill_method_id||' - created transactions: '||l_count);
          END IF;
          --l_total_count := l_total_count + l_count;  --rq 1000009750
      END LOOP;
      blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Create_Bill_Transactions - created transactions: '||l_total_count);
EXCEPTION
  WHEN l_exp_error THEN
    IF CV%isopen
    THEN
      CLOSE CV;
    END IF;
    IF c_bill_methods%isopen
    THEN
      CLOSE c_bill_methods;
    END IF;

    ROLLBACK TO TRX_CREATE;
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                               'pi_billing_run_id = '||pi_billing_run_id||' - '||
                               pio_Err(pio_Err.FIRST).errmessage);
  WHEN OTHERS THEN
    IF CV%isopen
    THEN
      CLOSE CV;
    END IF;
    IF c_bill_methods%isopen
    THEN
      CLOSE c_bill_methods;
    END IF;

    ROLLBACK TO TRX_CREATE;
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Create_Bill_Transactions', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                               'pi_billing_run_id = '||pi_billing_run_id||' - '|| SQLERRM);
END Create_Bill_Transactions;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Trx_Due_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--     Fadata   10.08.2017  changed - add parameter transaction_id GAP 135
--     Fadata   10.04.2019  changed - LPVS-109
--     Fadata   13.08.2019  changed - LPV-1967
--     Fadata   10.11.2020  changed - LAP85-47, CSR187
--
-- Purpose: Calculate transaction due date
-- Init legal entity before use function
--
-- Input parameters:
--     pi_transaction_id  NUMBER     Transaction identifier
--     pi_due_date        DATE       Current transaction due date (required)
--     pi_fix_due_date    VARCHAR2   Fixed due date (number between 0 and 31)
--     pi_offset_due_date VARCHAR2   Positive number added to the due date
--     pi_item_type       VARCHAR2   Item type
--     pi_bill_scope      VARCHAR2   Bill scope
--     pi_run_id          NUMBER     Run identifier
--     pi_account_id      NUMBER     Account identifier
--     pi_item_id         NUMBER     Item identifier
--
-- Returns:
--     new due date
--
-- Usage: In run billing to calculate transaction due date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Trx_Due_Date
   (pi_transaction_id   IN     NUMBER,
    pi_due_date         IN     DATE,
    pi_fix_due_date     IN     NUMBER,
    pi_offset_due_date  IN     NUMBER,
    pi_item_type        IN     VARCHAR2,
    pi_bill_scope       IN     VARCHAR2,
    pi_run_id           IN     NUMBER,
    pi_account_id       IN     NUMBER,
    pi_item_id          IN     NUMBER)
RETURN DATE
IS
  l_new_due_date    DATE;
  l_blc_run         blc_run_type;
  l_SrvErr          SrvErr;
  l_account         blc_accounts_type;
  l_item            blc_items_type; --GAP139
  l_count           PLS_INTEGER;
  l_offset_days     NUMBER;  -- LPVS-109
BEGIN
   l_new_due_date := pi_due_date;

   IF pi_item_type = 'POLICY' AND pi_run_id IS NOT NULL
   THEN
      l_blc_run := NEW blc_run_type(pi_run_id, l_SrvErr);
      l_item := NEW blc_items_type(pi_item_id, l_SrvErr);

      IF pi_bill_scope = 'CLIENT' AND l_item.insurance_type IN ('2001', '2004', '2007', '2008', '2000', '2006') --client level is available only for these products --GAP139
      THEN
         l_account := NEW blc_accounts_type(pi_account_id , l_SrvErr);
         l_new_due_date := Get_Reg_Bill_To_Date
                                     (pi_next_date     => l_account.next_date,
                                      pi_bill_cycle_id => l_account.bill_cycle_id,
                                      pi_bill_period   => l_account.bill_period,
                                      pi_run_date      => nvl(l_blc_run.run_date,blc_appl_cache_pkg.g_to_date),
                                      pi_nd_offset     => l_account.bill_horizon,
                                      pi_nwd_offset    => 0);

         l_new_due_date := l_new_due_date - 1;

         l_new_due_date := greatest(l_new_due_date, nvl(l_blc_run.run_date,blc_appl_cache_pkg.g_to_date)); --move here to avoid execution for product 2014 - LPV-1967
      ELSE
         /*
         IF pi_fix_due_date IS NOT NULL
         THEN
            IF to_char(pi_due_date,'DD') <> pi_fix_due_date
            THEN
               l_new_due_date := add_months(to_date(pi_fix_due_date||'-01-'||to_char(pi_due_date,'YYYY'),'DD-MM-YYYY'),to_number(to_char(pi_due_date,'MM')-1));
            END IF;
         ELSIF pi_offset_due_date IS NOT NULL AND to_number(pi_offset_due_date) > 0
         THEN
            l_new_due_date := pi_due_date + to_number(pi_offset_due_date);
         END IF;
         */

         --BEGIN LAP85-47, CSR187  commented the IF in order Protocol policy to be processed as others
         /*
         IF blc_common_pkg.get_lookup_code(l_blc_run.bill_method_id) = 'PROTOCOL' --GAP 125
         THEN
            l_new_due_date := blc_appl_cache_pkg.g_to_date;
         ELSIF l_item.insurance_type = '2014' --LPV-1967
         */
         -- END LAP85-47, CSR187
         IF l_item.insurance_type = '2014' --LPV-1967
         THEN
            IF pi_fix_due_date IS NOT NULL
            THEN
               IF to_char(l_new_due_date,'DD') <> pi_fix_due_date
               THEN
                  l_new_due_date := add_months(to_date(pi_fix_due_date||'-01-'||to_char(l_new_due_date,'YYYY'),'DD-MM-YYYY'),to_number(to_char(l_new_due_date,'MM')-1));

                  IF l_new_due_date < pi_due_date
                  THEN
                     --l_new_due_date := add_months(l_new_due_date,to_number(l_item.attrib_5)); --CON94S-9
                     l_new_due_date := add_months(l_new_due_date,1);
                  END IF;
               END IF;
            END IF;
         ELSE
            --check if SIP - GAP 2009
            SELECT count(*)
            INTO l_count
            FROM blc_installments
            WHERE transaction_id = pi_transaction_id
            AND installment_type = 'BCSIP';
            --
            IF l_count > 0
            THEN
               l_new_due_date := blc_appl_cache_pkg.g_to_date;
            ELSE
               -- Comment LPVS-109
               /*IF pi_offset_due_date IS NOT NULL AND to_number(pi_offset_due_date) > 0
               THEN
                  l_new_due_date := l_new_due_date + to_number(pi_offset_due_date);
               ELSIF pi_fix_due_date IS NOT NULL
               THEN
                  IF to_char(l_new_due_date,'DD') <> pi_fix_due_date
                  THEN
                     l_new_due_date := add_months(to_date(pi_fix_due_date||'-01-'||to_char(l_new_due_date,'YYYY'),'DD-MM-YYYY'),to_number(to_char(l_new_due_date,'MM')-1));
                  END IF;
               END IF;*/
               -- Begin LPVS-109
               IF pi_fix_due_date IS NOT NULL
               THEN
                  IF to_char(l_new_due_date,'DD') <> pi_fix_due_date
                  THEN
                     l_new_due_date := add_months(to_date(pi_fix_due_date||'-01-'||to_char(l_new_due_date,'YYYY'),'DD-MM-YYYY'),to_number(to_char(l_new_due_date,'MM')-1));
                  END IF;
               ELSIF pi_offset_due_date IS NOT NULL AND to_number(pi_offset_due_date) > 0
               THEN
                  l_new_due_date := l_new_due_date + to_number(pi_offset_due_date);
               ELSE
                   l_offset_days := blc_common_pkg.Get_Setting_Number_Value( pi_setting_name => 'DueDateOffset',
                                                                             pio_ErrMsg      => l_SrvErr );
                   IF l_offset_days > 0
                   THEN
                       l_new_due_date := l_new_due_date + l_offset_days;
                   END IF;
               END IF;
               -- End LPVS-109
            END IF;

            l_new_due_date := greatest(l_new_due_date, nvl(l_blc_run.run_date,blc_appl_cache_pkg.g_to_date)); --move here to avoid execution for product 2014 - LPV-1967

         END IF;
      END IF;

      --l_new_due_date := greatest(l_new_due_date, nvl(l_blc_run.run_date,blc_appl_cache_pkg.g_to_date)); --move in specic cases to avoid execution for product 2014 - LPV-1967
   END IF;

   RETURN l_new_due_date;
END Calculate_Trx_Due_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Trx_Grace_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--
-- Purpose: Calculate transaction grace date
-- Init legal entity before use function
--
-- Input parameters:
--     pi_transaction_id  NUMBER     Transaction identifier
--     pi_grace_date      DATE       Current transaction grace date (required)
--     pi_due_date        DATE       Current transaction due date (required)
--     pi_fix_due_date    VARCHAR2   Fixed due date (number between 0 and 31)
--     pi_offset_due_date VARCHAR2   Positive number added to the due date
--     pi_item_type       VARCHAR2   Item type
--     pi_bill_scope      VARCHAR2   Bill scope
--     pi_run_id          NUMBER     Run identifier
--     pi_account_id      NUMBER     Account identifier
--     pi_item_id         NUMBER     Item identifier
--
-- Returns:
--     new due date
--
-- Usage: In run billing to calculate transaction grace date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Trx_Grace_Date
   (pi_transaction_id   IN     NUMBER,
    pi_grace_date       IN     DATE,
    pi_due_date         IN     DATE,
    pi_fix_due_date     IN     NUMBER,
    pi_offset_due_date  IN     NUMBER,
    pi_item_type        IN     VARCHAR2,
    pi_bill_scope       IN     VARCHAR2,
    pi_run_id           IN     NUMBER,
    pi_account_id       IN     NUMBER,
    pi_item_id          IN     NUMBER)
RETURN DATE
IS
  l_new_grace_date  DATE;
  l_due_date        DATE;
BEGIN
   l_new_grace_date := pi_grace_date;

   IF pi_item_type = 'POLICY'
   THEN
      l_due_date := Calculate_Trx_Due_Date
                       (pi_transaction_id,
                        pi_due_date,
                        pi_fix_due_date,
                        pi_offset_due_date,
                        pi_item_type,
                        pi_bill_scope,
                        pi_run_id,
                        pi_account_id,
                        pi_item_id);

      l_new_grace_date := l_due_date;
   END IF;

   RETURN l_new_grace_date;
END Calculate_Trx_Grace_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Change_Account_Next_Date
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2012  creation
--     Fadata   04.03.2014  changed - add parameters pi_bill_method and
--                                    pi_bill_method_id
--                                    rq 1000008191
--     Fadata   06.04.2015  changed - add procedure specification, add savepoint
--                                    and rollback
--                                    rq 1000009741
--     Fadata   15.09.2015  changed - add offset depend on setting
--                                    BillingNextDateOffset
--                                    increment next date non only with one
--                                    period and with necessary count of periods
--                                    to become next date greater than run date
--                                    rq 1000010052
--     Fadata   08.06.2016  changed - use bill horizon as next date offset and
--                                    add additional offset for non-working days
--                                    rq 1000010513
--     Fadata   02.05.2017  changed - copy from core and add logic to update
--                                    only accounts with CLIENT billing skope
--                                    for party role Holder
--
-- Purpose: Update next billing date with new calculated for accounts with
-- billing site equals to given billing organization and next date not greater
-- than given billing run date

-- Input parameters:
--     pi_org_id         NUMBER       Billing organization identifier (required)
--     pi_run_date       DATE         Billing run date (required)
--     pi_bill_method    VARCHAR2(30) Bill method code
--     pi_bill_method_id NUMBER       Bill method id
--     pi_billing_run_id NUMBER       Billing run identifier (required)
--     pio_Err           SrvErr       Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     pio_Err           SrvErr      Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: Final step in regular billing process
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Change_Account_Next_Date
   (pi_org_id         IN     NUMBER,
    pi_run_date       IN     DATE,
    pi_bill_method    IN     VARCHAR2,
    pi_bill_method_id IN     NUMBER,
    pi_billing_run_id IN     NUMBER,
    pio_Err           IN OUT SrvErr)
IS
   CURSOR c_accounts (x_offset IN NUMBER) IS
      SELECT ba.account_id, ba.next_date
      FROM blc_accounts ba
      WHERE blc_common_pkg.Get_Lookup_Code(ba.bill_method_id) <> 'NONE'
      AND ba.billing_site_id = pi_org_id
      AND ba.next_date - (nvl(ba.bill_horizon,0) + x_offset) <= pi_run_date
      AND (pi_bill_method_id IS NULL OR bill_method_id = pi_bill_method_id)
      AND (pi_bill_method IS NULL OR blc_common_pkg.Get_Lookup_Code(ba.bill_method_id) = pi_bill_method)
      AND (blc_common_pkg.Get_Lookup_Code(ba.party_role_id) <> 'HLDR'
           OR (blc_common_pkg.Get_Lookup_Code(ba.party_role_id) = 'HLDR'
               AND ba.attrib_0 = 'CLIENT'
               AND EXISTS (SELECT 'INST'
                           FROM blc_installments bin
                           WHERE bin.account_id = ba.account_id
                           AND bin.insurance_type IN ('2001', '2004', '2007', '2008', '2000', '2006')))); --client level is available only for these products --GAP139;

   l_SrvErrMsg       SrvErrMsg;
   l_log_module      VARCHAR2(240);
   l_account         BLC_ACCOUNTS_TYPE;
   l_count           NUMBER;
   l_exp_error       EXCEPTION;
   --
   l_horizon_offset  NUMBER;
   l_blc_run         blc_run_type;
   l_i_eligibility_s VARCHAR2(2000);
   l_query           VARCHAR2(4000 CHAR);
   l_count_v         PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Change_Account_Next_Date';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Change_Account_Next_Date');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_org_id = '||pi_org_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_run_date = '||to_char(pi_run_date,'dd-mm-yyyy'));
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_bill_method = '||pi_bill_method);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_bill_method_id = '||pi_bill_method_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_billing_run_id = '||pi_billing_run_id);

   l_blc_run := NEW blc_run_type(pi_billing_run_id, pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_billing_run_id = '||pi_billing_run_id||' - '||
                                  pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
   END IF;

   IF l_blc_run.bill_clause_id IS NOT NULL
   THEN
      l_i_eligibility_s := blc_common_pkg.Get_Lookup_Tag_Value
                         ( pi_lookup_set  => 'BILL_CLAUSES',
                           pi_lookup_code => NULL,
                           pi_org_id      => NULL,
                           pi_lookup_id   => l_blc_run.bill_clause_id,
                           pi_tag_number  => 0 );

      IF l_i_eligibility_s IS NOT NULL
      THEN
         l_query := 'SELECT COUNT(*)
                     FROM blc_installments_item_bill i
                     WHERE i.account_id = :1
                     AND ('||l_i_eligibility_s||')';
      END IF;
   END IF;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_STATEMENT,
                              'l_query = '||l_query);

   l_horizon_offset := blc_billing_pkg.Get_Bill_Horizon_Offset
                                (pi_org_id     => pi_org_id,
                                 pi_run_date   => pi_run_date);

   SAVEPOINT CHANGE_DATE;
   l_count := 0;
   l_count_v := 1;
   FOR l_rec IN c_accounts(l_horizon_offset)
   LOOP
      l_account := NEW blc_accounts_type(l_rec.account_id,pio_Err);

      IF l_query IS NOT NULL
      THEN
         EXECUTE IMMEDIATE l_query INTO l_count_v USING l_rec.account_id;
      END IF;

      IF l_count_v > 0
      THEN
         LOOP
            EXIT WHEN l_account.next_date - (nvl(l_account.bill_horizon,0) + l_horizon_offset) > pi_run_date;
            --
            l_account.next_date := blc_billing_pkg.Get_Next_Billing_Date
                                             (l_account.next_date,
                                              l_account.bill_cycle_id,
                                              l_account.bill_period);
         END LOOP;

         IF NOT l_account.update_blc_accounts(pio_Err)
         THEN
            RAISE l_exp_error;
         END IF;
         blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'Updated account - account_id = '||l_account.account_id||
                                     '; old_next_date = '||to_char(l_rec.next_date,'dd-mm-yyyy')||
                                     '; new_next_date = '||to_char(l_account.next_date,'dd-mm-yyyy'));
         l_count := l_count + 1;
      END IF;
   END LOOP;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Change_Account_Next_Date - updated accounts: '||l_count);
EXCEPTION
   WHEN l_exp_error THEN
      IF c_accounts%isopen
      THEN
         CLOSE c_accounts;
      END IF;

      ROLLBACK TO CHANGE_DATE;
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                        'pi_org_id = '||pi_org_id||' - '||
                        'pi_run_date = '||TO_CHAR(pi_run_date,'DD-MM-YYYY')||' - '||
                        pio_Err(pio_Err.FIRST).errmessage);
   WHEN OTHERS THEN
      IF c_accounts%isopen
      THEN
         CLOSE c_accounts;
      END IF;

      ROLLBACK TO CHANGE_DATE;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Change_Account_Next_Date', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_org_id = '||pi_org_id||' - '||
                                'pi_run_date = '||TO_CHAR(pi_run_date,'DD-MM-YYYY')||' - '||
                                SQLERRM);
END Change_Account_Next_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Change_Item_Next_Date
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--
-- Purpose: Update next billing date with new calculated for items with
-- billing site(attrib_0) equals to given billing organization and next date
-- (attrib_4) not greater than given billing run date

-- Input parameters:
--     pi_org_id         NUMBER       Billing organization identifier (required)
--     pi_run_date       DATE         Billing run date (required)
--     pi_bill_method    VARCHAR2(30) Bill method code
--     pi_bill_method_id NUMBER       Bill method id
--     pi_billing_run_id NUMBER       Billing run identifier (required)
--     pio_Err           SrvErr       Specifies structure for passing back
--                                    the error code, error TYPE and
--                                    corresponding message.
--
-- Output parameters:
--     pio_Err           SrvErr      Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: Final step in regular billing process
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Change_Item_Next_Date
   (pi_org_id         IN     NUMBER,
    pi_run_date       IN     DATE,
    pi_bill_method    IN     VARCHAR2,
    pi_bill_method_id IN     NUMBER,
    pi_billing_run_id IN     NUMBER,
    pio_Err           IN OUT SrvErr)
IS
   CURSOR c_items IS
      SELECT bi.item_id, to_date(bi.attrib_4,'yyyy-mm-dd') next_date
      FROM blc_items bi
      WHERE bi.item_type = 'POLICY'
      AND bi.attrib_0 = to_char(pi_org_id)
      AND bi.attrib_4 IS NOT NULL
      AND bi.attrib_5 IS NOT NULL
      AND to_date(bi.attrib_4,'yyyy-mm-dd') - nvl(to_number(bi.attrib_6),0) <= pi_run_date
      --AND Check_Reg_Run_Policy(bi.item_type, bi.attrib_7, bi.agreement) = 'Y' removed according Gap 112
      AND EXISTS (SELECT 'POLICY'
                  FROM blc_installments bin,
                       blc_accounts ba
                  WHERE bin.item_id = bi.item_id
                  AND bin.account_id = ba.account_id
                  AND (nvl(ba.attrib_0,'-999') <> 'CLIENT' OR (ba.attrib_0 = 'CLIENT' AND bin.insurance_type NOT IN ('2001', '2004', '2007', '2008', '2000', '2006')))); --client level is available only for these products --GAP139

   l_SrvErrMsg       SrvErrMsg;
   l_log_module      VARCHAR2(240);
   l_item            BLC_ITEMS_TYPE;
   l_count           NUMBER;
   l_exp_error       EXCEPTION;
   l_bill_cycle_id   NUMBER := 23;
   l_blc_run         blc_run_type;
   l_i_eligibility_s VARCHAR2(2000);
   l_query           VARCHAR2(4000 CHAR);
   l_query_2         VARCHAR2(4000 CHAR);
   l_query_3         VARCHAR2(4000 CHAR);
   l_count_v         PLS_INTEGER;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Change_Item_Next_Date';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Change_Account_Next_Date');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_org_id = '||pi_org_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_run_date = '||to_char(pi_run_date,'dd-mm-yyyy'));
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_bill_method = '||pi_bill_method);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_bill_method_id = '||pi_bill_method_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_bill_method_id = '||pi_bill_method_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_billing_run_id = '||pi_billing_run_id);

   l_blc_run := NEW blc_run_type(pi_billing_run_id, pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_billing_run_id = '||pi_billing_run_id||' - '||
                                  pio_Err(pio_Err.FIRST).errmessage);
       RETURN;
   END IF;

   IF l_blc_run.bill_clause_id IS NOT NULL
   THEN
      l_i_eligibility_s := blc_common_pkg.Get_Lookup_Tag_Value
                         ( pi_lookup_set  => 'BILL_CLAUSES',
                           pi_lookup_code => NULL,
                           pi_org_id      => NULL,
                           pi_lookup_id   => l_blc_run.bill_clause_id,
                           pi_tag_number  => 0 );

      IF l_i_eligibility_s IS NOT NULL
      THEN
         l_query := 'SELECT COUNT(*)
                     FROM blc_installments_item_bill i
                     WHERE i.item_id = :1
                     AND ('||l_i_eligibility_s||')';
      END IF;
   END IF;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_STATEMENT,
                              'l_query = '||l_query);

   IF pi_bill_method_id IS NOT NULL
   THEN
      IF l_query IS NOT NULL
      THEN
         l_query_2 := l_query||' AND i.bill_method_id = :2';
      ELSE
         l_query_2 := 'SELECT COUNT(*)
                       FROM blc_installments_item_bill i
                       WHERE i.item_id = :1
                       AND i.bill_method_id = :2';
      END IF;
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_STATEMENT,
                                 'l_query_2 = '||l_query_2);
   ELSIF pi_bill_method IS NOT NULL
   THEN
      IF l_query IS NOT NULL
      THEN
         l_query_3 := l_query||' AND blc_common_pkg.Get_Lookup_Code(i.bill_method_id) = :2';
      ELSE
         l_query_3 := 'SELECT COUNT(*)
                       FROM blc_installments_item_bill i
                       WHERE i.item_id = :1
                       AND blc_common_pkg.Get_Lookup_Code(i.bill_method_id) = :2';
      END IF;
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_STATEMENT,
                                 'l_query_3 = '||l_query_3);
   END IF;

   SAVEPOINT CHANGE_DATE;

   l_count := 0;
   l_count_v := 1;
   FOR l_rec IN c_items
   LOOP
      l_item := NEW blc_items_type(l_rec.item_id,pio_Err);

      IF l_query_3 IS NOT NULL
      THEN
         EXECUTE IMMEDIATE l_query INTO l_count_v USING l_rec.item_id, pi_bill_method;
      ELSIF l_query_2 IS NOT NULL
      THEN
         EXECUTE IMMEDIATE l_query INTO l_count_v USING l_rec.item_id, pi_bill_method_id;
      ELSIF l_query IS NOT NULL
      THEN
         EXECUTE IMMEDIATE l_query INTO l_count_v USING l_rec.item_id;
      END IF;

      IF l_count_v > 0
      THEN
         LOOP
            EXIT WHEN to_date(l_item.attrib_4,'yyyy-mm-dd') - nvl(to_number(l_item.attrib_6),0) > pi_run_date;
            --
            l_item.attrib_4 := to_char(blc_billing_pkg.Get_Next_Billing_Date
                                           (to_date(l_item.attrib_4,'yyyy-mm-dd'),
                                            l_bill_cycle_id,
                                            to_number(l_item.attrib_5)),'yyyy-mm-dd');
         END LOOP;

         IF NOT l_item.update_blc_items(pio_Err)
         THEN
            RAISE l_exp_error;
         END IF;

         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_STATEMENT,
                                    'Updated item - item_id = '||l_item.item_id||
                                    '; old_next_date = '||to_char(l_rec.next_date,'dd-mm-yyyy')||
                                    '; new_next_date = '||to_char(to_date(l_item.attrib_4,'yyyy-mm-dd'),'dd-mm-yyyy'));
         l_count := l_count + 1;
      END IF;
   END LOOP;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Change_Item_Next_Date - updated items: '||l_count);
EXCEPTION
   WHEN l_exp_error THEN
      IF c_items%isopen
      THEN
         CLOSE c_items;
      END IF;

      ROLLBACK TO CHANGE_DATE;
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                        'pi_org_id = '||pi_org_id||' - '||
                        'pi_run_date = '||TO_CHAR(pi_run_date,'DD-MM-YYYY')||' - '||
                        pio_Err(pio_Err.FIRST).errmessage);
   WHEN OTHERS THEN
      IF c_items%isopen
      THEN
         CLOSE c_items;
      END IF;

      ROLLBACK TO CHANGE_DATE;
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Change_Item_Next_Date', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                    'pi_org_id = '||pi_org_id||' - '||
                    'pi_run_date = '||TO_CHAR(pi_run_date,'DD-MM-YYYY')||' - '||
                    SQLERRM);
END Change_Item_Next_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Postprocess_Document_CLMCNL
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   27.07.2017  creation
--
-- Purpose: Execute postprocess procedure for cancel claim payment
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     po_item_ids         VARCHAR2  List of items ids
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In billing process to execute cancel claim compensation for a document
-- after it validation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Postprocess_Document_CLMCNL
   (pi_doc_id      IN     NUMBER,
    po_item_ids    OUT    VARCHAR2,
    pio_Err        IN OUT SrvErr)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
   l_count             PLS_INTEGER;
   l_payment           BLC_PAYMENTS_TYPE;
   l_Context           insis_sys_v10.SRVContext;
   l_RetContext        insis_sys_v10.SRVContext;
   l_balance           NUMBER;
BEGIN
  l_log_module := C_DEFAULT_MODULE||'.Postprocess_Document_CLMCNL';
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Postprocess_Document_CLMCNL');
  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);

  FOR c_item IN (SELECT bt.item_id
                 FROM blc_transactions bt
                 WHERE bt.doc_id = pi_doc_id
                 AND bt.status NOT IN ('C','R','D')
                 AND NOT EXISTS (SELECT 'R'
                                 FROM blc_pay_run pr
                                 WHERE pr.transaction_id = bt.transaction_id
                                 AND pr.status = 'I')
                 GROUP BY bt.item_id )
     LOOP
         l_count := 0;
         FOR c_rec IN
              (SELECT ba.source_payment payment_id, ba.rate_date value_date,
                      bp.payment_class, bp.amount, nvl(bl.tag_12,'Y') reverse_flag,
                      bu.attrib_0, bp.status
               FROM blc_applications ba,
                    blc_payments bp,
                    blc_bacc_usages bu,
                    blc_lookups bl
               WHERE ba.target_item = c_item.item_id
               AND ba.reversed_appl IS NULL
               AND ba.status <> 'D'
               AND NOT EXISTS (SELECT 'REVERSE'
                               FROM blc_applications ba1
                               WHERE ba1.reversed_appl = ba.application_id
                               AND ba1.status <> 'D'
                               )
               AND ba.source_payment = bp.payment_id
               AND bp.usage_id = bu.usage_id
               AND bu.pay_method = bl.lookup_id
               GROUP BY ba.source_payment, ba.rate_date, bp.payment_class,
                        bp.amount, nvl(bl.tag_12,'Y'), bu.attrib_0, bp.status
               ORDER BY ba.rate_date DESC, ba.source_payment DESC)
            LOOP
               IF c_rec.amount = 0 AND c_rec.reverse_flag = 'Y'--substr(c_rec.payment_class,1,1) = 'I' any kind of compensation
               THEN
                  blc_appl_util_pkg.Reverse_Payment(c_rec.payment_id, pio_Err);
                  l_count := l_count + 1;
               END IF;

               -- add logic for reverse payment in status A and H
               IF c_rec.amount > 0 AND c_rec.status IN ('A','H')
               THEN
                  srv_context.SetContextAttrNumber( l_Context, 'PAYMENT_ID', srv_context.Integers_Format, c_rec.payment_id);
                  srv_context.SetContextAttrChar( l_Context, 'REASON_CODE', 'CLM_CANCEL_REVERSE');

                  srv_events.sysEvent( 'REVERSE_BLC_PMNT', l_Context, l_RetContext, pio_Err );
                  l_count := l_count + 1;
               END IF;

               IF NOT srv_error.rqStatus( pio_Err )
               THEN
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_EXCEPTION,
                                             'c_item.item_id = '||c_item.item_id||' - '||
                                             'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                  RETURN;
               END IF;
            END LOOP;

        IF l_count > 0
        THEN
           IF po_item_ids IS NULL
           THEN
              po_item_ids := c_item.item_id;
           ELSIF po_item_ids||', '||c_item.item_id <= 2000
           THEN
              po_item_ids := po_item_ids||', '||c_item.item_id;
           END IF;
        END IF;
        --
        blc_appl_util_pkg.Postprocess_Document_NORM
                     (NULL, --pi_source,
                      NULL, --pi_agreement,
                      NULL, --pi_component,
                      NULL, --pi_detail,
                      c_item.item_id,
                      pi_doc_id,
                      'NET',
                      pio_Err);
        IF NOT srv_error.rqStatus( pio_Err )
        THEN
           blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_EXCEPTION,
                                      'c_item.item_id = '||c_item.item_id||' - '||
                                      'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            RETURN;
        END IF;

        --
        SELECT SUM(open_balance)
        INTO l_balance
        FROM blc_transactions
        WHERE doc_id = pi_doc_id;

        IF l_balance <> 0
        THEN
           srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Postprocess_Document_CLMCNL', 'blc_appl_util_pkg.PCC.ExistsOpenBalance' );
           srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
           blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'pi_doc_id = '||pi_doc_id||' - '||
                                        'Claim can not be cancelled. Document status is not proper for netting');
        END IF;

     END LOOP;

  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'po_item_ids = '||po_item_ids);
  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Postprocess_Document_CLMCNL');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Postprocess_Document_CLMCNL', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Postprocess_Document_CLMCNL;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Postprocess_Doc_Accounting
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.11.2017  creation
--
-- Purpose: Execute postprocess procedure for create accounting for proforma
--
-- Input parameters:
--     pi_doc_id           NUMBER    Document Id (required)
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Output parameters:
--     po_acc_doc_id       NUMBER    Voucher doc id
--     pio_Err             SrvErr    Specifies structure for passing back
--                                   the error code, error TYPE and
--                                   corresponding message.
--
-- Usage: In billing process to execute immediate accounting of proforma
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Postprocess_Doc_Accounting
   (pi_doc_id      IN     NUMBER,
    po_acc_doc_id  OUT    NUMBER,
    pio_Err        IN OUT SrvErr)
IS
   l_log_module        VARCHAR2(240);
   l_SrvErrMsg         SrvErrMsg;
   l_SrvErr            SrvErr;
BEGIN
  l_log_module := C_DEFAULT_MODULE||'.Postprocess_Doc_Accounting';
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Postprocess_Doc_Accounting');
  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);
  SAVEPOINT DOC_UPDATE_A;

  blc_doc_util_pkg.Insert_Action
             ('POST',
              'POSTPROCESS.NET_DOC_PROFORMA_ACCOUNTING',
              'S',
              pi_doc_id,
              NULL,
              l_SrvErr);
  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||l_SrvErr(l_SrvErr.FIRST).errmessage);
     ROLLBACK TO DOC_UPDATE_A;
     RETURN;
  END IF;

  --
  cust_acc_process_pkg.Create_Proforma_Voucher( pi_doc_id      => pi_doc_id,
                                                pi_le_id       => NULL,
                                                po_acc_doc_id  => po_acc_doc_id,
                                                pio_Err        => l_SrvErr);

  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||l_SrvErr(l_SrvErr.FIRST).errmessage);
     ROLLBACK TO DOC_UPDATE_A;
     RETURN;
  END IF;

  --
  cust_acc_process_pkg.Process_Acc_Trx( pi_acc_doc_id  => po_acc_doc_id,
                                        pi_le_id       => NULL,
                                        pi_status      => NULL,
                                        pi_ip_code     => NULL,
                                        pi_imm_flag    => 'Y',
                                        pio_Err        => l_SrvErr);

  IF NOT srv_error.rqStatus( l_SrvErr )
  THEN
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||l_SrvErr(l_SrvErr.FIRST).errmessage);
     ROLLBACK TO DOC_UPDATE_A;
     po_acc_doc_id := NULL;
     RETURN;
  END IF;

  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'po_acc_doc_id = '||po_acc_doc_id);

  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Postprocess_Doc_Accounting');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Postprocess_Doc_Accounting', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Postprocess_Doc_Accounting;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Postprocess_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   02.05.2017  creation
--     Fadata   02.02.2021  changed - LAP85-97 - add policy type as parameter
--                                    for priority calculation
--
-- Purpose: Execute custom postprocess procedure for document depend on
-- accounting class and given postprocess
--
-- Input parameters:
--     pi_doc_id            NUMBER     Document Id (required)
--     pio_postprocess      VARCHAR2   Postprocess
--     pio_procedure_result VARCHAR2   Procedure result
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_postprocess      VARCHAR2   Postprocess
--     pio_procedure_result VARCHAR2   Procedure result
--     po_action_notes       VARCHAR2  Action notes
--     pio_Err               SrvErr    Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: In billing process after complete document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Postprocess_Document
   (pi_doc_id             IN     NUMBER,
    pio_postprocess       IN OUT VARCHAR2,
    pio_procedure_result  IN OUT VARCHAR2,
    po_action_notes       OUT    VARCHAR2,
    pio_Err               IN OUT SrvErr)
IS
   l_log_module             VARCHAR2(240);
   l_SrvErrMsg              SrvErrMsg;
   l_doc                    BLC_DOCUMENTS_TYPE;
   l_item_type              VARCHAR2(30);
   l_item_ids               VARCHAR2(2000);
   l_doc_balance            NUMBER;
   l_Context                SRVContext;
   l_RetContext             SRVContext;
   l_rfnd_pay_way           VARCHAR2(30) := 'CHECK';
   l_ri_pay_way             VARCHAR2(30) := 'WIRE';
   l_def_pay_way            VARCHAR2(30);
   l_pay_way_set            VARCHAR2(30);
   l_pay_way_id             NUMBER;
   l_SrvErr                 SrvErr;
   l_list                   VARCHAR2(500);
   l_payment_id             NUMBER;
   l_policy_type            VARCHAR2(120); --LAP85-97
   --
   CURSOR c_item_type IS
     SELECT bi.item_type, bi.attrib_7 --LAP85-97 - add policy_type
     FROM blc_transactions bt,
          blc_items bi
     WHERE bt.doc_id = pi_doc_id
     AND bt.status NOT IN ('C','R','D')
     AND bt.item_id = bi.item_id;
    --
    l_run                  BLC_RUN_TYPE;
    l_doc_type             VARCHAR2(30);
    l_acc_doc_id           NUMBER;
    l_usage_id             NUMBER;
BEGIN
  blc_log_pkg.initialize(pio_Err);
  IF NOT srv_error.rqStatus( pio_Err )
  THEN
     RETURN;
  END IF;

  l_log_module := C_DEFAULT_MODULE||'.Postprocess_Document';
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'BEGIN of procedure Postprocess_Document');
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_doc_id = '||pi_doc_id);
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pio_postprocess = '||pio_postprocess);
  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pio_procedure_result = '||pio_procedure_result);

 BEGIN
     l_doc := NEW blc_documents_type(pi_doc_id);
  EXCEPTION
     WHEN OTHERS THEN
        srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_doc_process_pkg.Get_Postprocess_Attribs', 'GetBLCDocument_No_Doc_id' );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_EXCEPTION,
                                   'pi_doc_id = '||pi_doc_id||' - '||'Invalid document Id');
     RETURN;
  END;

  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_STATEMENT,
                             'l_doc_class = '||l_doc.doc_class);

  OPEN c_item_type;
    FETCH c_item_type
    INTO l_item_type, l_policy_type; --LAP85-97 - add policy_type
  CLOSE c_item_type;

  blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_STATEMENT,
                             'l_item_type = '||l_item_type);

  IF l_doc.run_id IS NOT NULL
  THEN
     l_run := blc_run_type(l_doc.run_id, pio_Err);
  END IF;

  IF pio_postprocess IN ('NORM','NONE','CLM_CANCEL') -- add NONE for reinsurance and payable commissions - 17.08.2016
  THEN
     l_doc_balance := BLC_DOC_UTIL_PKG.Get_Doc_Open_Balance
                            (PI_DOC_ID => pi_doc_id,
                             PI_DOC_CURRENCY => l_doc.currency);

     IF l_doc.doc_class = 'N'
     THEN
        pio_postprocess := 'NONE';
     ELSIF l_item_type = 'POLICY'
     THEN
        IF l_doc_balance < 0
        THEN
           --l_def_pay_way := l_rfnd_pay_way; -- do not default stay as is original
           --
           pio_postprocess := 'NONE';
           --pio_postprocess := 'PAY_DOC';  --add this if need to create refund payment automatic
        ELSE
           pio_postprocess := 'NONE';
        END IF;
        --
        IF l_doc.run_id IS NOT NULL AND l_doc.status = 'A'
        THEN
           l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

           SAVEPOINT DOC_UPDATE;

           -- Netting
           cust_pay_util_pkg.Net_Document
                   (pi_doc_id      => pi_doc_id,
                    pio_Err        => pio_Err);

           IF NOT srv_error.rqStatus( pio_Err )
           THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = '||pi_doc_id||' - '|| pio_Err(pio_Err.FIRST).errmessage );
              pio_procedure_result := blc_gvar_process.flg_err;
              ROLLBACK TO DOC_UPDATE;
              RETURN;
           END IF;

           pio_postprocess := 'CUST_NET_DOC';
           po_action_notes := 'POSTPROCESS.NET_DOC';

           --IF l_run.run_mode IN ('I','E') AND l_doc_type IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE) AND l_doc.amount <> 0 --23.04.2018
           --IF cust_acc_util_pkg.Get_Prof_Priority(l_run.run_mode, l_run.bill_method_id) = 'HIGH' --LAP85-97
           IF cust_acc_util_pkg.Get_Prof_Priority_2(l_run.run_mode, l_run.bill_method_id, l_policy_type) = 'HIGH'
              AND l_doc_type IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE) AND l_doc.amount <> 0
           THEN
              Postprocess_Doc_Accounting
                   (pi_doc_id      => pi_doc_id,
                    po_acc_doc_id  => l_acc_doc_id,
                    pio_Err        => pio_Err);

              IF NOT srv_error.rqStatus( pio_Err )
              THEN
                 blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                            'pi_doc_id = '||pi_doc_id||' - '||
                                             pio_Err( pio_Err.FIRST).errmessage);
                 pio_procedure_result := blc_gvar_process.flg_err;
              END IF;

              pio_postprocess := 'NET_DOC_PROFORMA_ACCOUNTING';
              po_action_notes := 'POSTPROCESS.NET_DOC_PROFORMA_ACCOUNTING voucher doc: '||l_acc_doc_id;
           END IF;
        END IF;
     ELSIF l_item_type IN ('CLAIM','LOAN','PAIDUP')
     THEN
        IF l_doc_balance > 0
        THEN
           pio_postprocess := 'NONE';
           --pio_postprocess := 'PAY_DOC'; --add this if need to create payment automatic
        ELSIF (l_doc.amount < 0 AND pio_postprocess = 'CLM_CANCEL') OR (l_doc.amount = 0 AND blc_common_pkg.Get_Lookup_Code(l_run.bill_method_id) = 'CANCEL_PAIDUP')
        THEN
           IF l_doc.status = 'A'
           THEN
              SAVEPOINT DOC_UPDATE;
              --
              blc_appl_cache_pkg.init_le(l_doc.legal_entity_id, pio_Err);
              IF NOT srv_error.rqStatus( pio_Err )
              THEN
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                RETURN;
              END IF;

              Postprocess_Document_CLMCNL
                   (pi_doc_id      => pi_doc_id,
                    po_item_ids    => l_item_ids,
                    pio_Err        => pio_Err);

              IF NOT srv_error.rqStatus( pio_Err )
              THEN
                 blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                                  'pi_doc_id = '||pi_doc_id||' - '||
                                                   pio_Err( pio_Err.FIRST).errmessage);
                 pio_procedure_result := blc_gvar_process.flg_err;
                 ROLLBACK TO DOC_UPDATE;
              END IF;
              --
              IF l_item_ids IS NOT NULL
              THEN
                 pio_postprocess := 'CLM_CANCEL_RVRS_NET';
                 po_action_notes := 'POSTPROCESS.CLM_CANCEL_RVRS_NET items: '||l_item_ids;
              ELSE
                 pio_postprocess := 'CLM_CANCEL_NET';
                 po_action_notes := 'POSTPROCESS.CLM_CANCEL_NET';
              END IF;
           END IF;
        ELSIF l_item_type = 'PAIDUP' AND l_doc.amount = 0
        THEN
            FOR r_usages IN (
                SELECT usage_id
                FROM insis_gen_blc_v10.BLC_BACC_USAGES
                WHERE usage_name = 'Zero Payment - PAIDUPSRNDR'
                  AND org_id = l_doc.org_site_id
                  AND l_doc.issue_date BETWEEN from_date AND NVL( to_date, SYSDATE ))
              LOOP
                  l_usage_id := r_usages.usage_id;
                  EXIT;
              END LOOP;
           --
           pio_postprocess := 'PAY_DOC';
        END IF;
     ELSIF l_item_type = 'REGRES'
     THEN
        pio_postprocess := 'NONE';
     ELSIF l_item_type IN ('RI','CO','AC')
     THEN
        IF l_doc_balance <> 0
        THEN
           l_def_pay_way := l_ri_pay_way;
           --
           pio_postprocess := 'NONE';
           --pio_postprocess := 'PAY_DOC'; --add this if need to create payment automatic
        ELSE
           pio_postprocess := 'NONE';
        END IF;
     ELSIF l_item_type = 'COMMISSION'
     THEN
        pio_postprocess := 'NONE'; -- for now
     ELSE
        pio_postprocess := 'NONE';
     END IF;
     --
     IF l_doc.status = 'A'
     THEN
        IF l_def_pay_way IS NOT NULL
        THEN
           IF l_doc.doc_class = 'B'
           THEN
              l_pay_way_set := 'PAY_WAY_IN';
           ELSE
              l_pay_way_set := 'PAY_WAY_OUT';
           END IF;
           --
           l_pay_way_id := blc_common_pkg.Get_Lookup_Value_Id
                            ( pi_lookup_name => l_pay_way_set,
                              pi_lookup_code => l_def_pay_way,
                              pio_ErrMsg     => pio_Err,
                              pi_org_id      => 0,
                              pi_to_date     => TRUNC(sysdate));

           IF l_pay_way_id IS NOT NULL
           THEN
              blc_pay_instr_util_pkg.Change_Doc_Pay_Way
                  ( pi_doc_id       => pi_doc_id,
                    pi_pay_way_id   => l_pay_way_id,
                    pi_pay_instr    => NULL,
                    pi_change_all   => 'N',
                    po_doc_ids_list => l_list,
                    pio_Err         => pio_Err );
           END IF;

           IF NOT srv_error.rqStatus( pio_Err )
           THEN
              blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                         'pi_doc_id = '||pi_doc_id||' - '||
                                          pio_Err( pio_Err.FIRST).errmessage);
              pio_procedure_result := blc_gvar_process.flg_err;
              RETURN;
           END IF;
       END IF;

       IF pio_postprocess = 'PAY_DOC'
       THEN
          /*
          srv_context.SetContextAttrNumber( l_Context, 'DOC_ID', srv_context.Integers_Format, pi_doc_id);
          srv_context.SetContextAttrNumber( l_Context, 'ORG_ID', srv_context.Integers_Format, l_doc.org_site_id);
          -- srv_context.SetContextAttrNumber( l_Context, 'USAGE_ID', srv_context.Integers_Format, l_usage_id);
          srv_context.SetContextAttrNumber( l_Context, 'AMOUNT', srv_context.Real_Number_Format, l_doc_balance);
          --  srv_events.sysEvent( 'PAY_BLC_DOCUMENT', l_Context, l_RetContext, pio_Err );
          */
          SAVEPOINT DOC_UPDATE;

          l_payment_id := Create_Payment_for_Document
                 (pi_doc_id         => pi_doc_id,
                  pi_office         => NULL,
                  pi_org_id         => l_doc.org_site_id,
                  pi_usage_id       => l_usage_id,
                  pi_amount         => l_doc_balance,
                  pi_party          => NULL,
                  pi_party_site     => NULL,
                  pi_pay_party      => NULL,
                  pi_pay_address    => NULL,
                  pi_bank_code      => NULL,
                  pi_bank_acc_code  => NULL,
                  pi_pmnt_address   => NULL,
                  pi_currency       => NULL,
                  pi_pmnt_date      => NULL,
                  pi_pmnt_number    => NULL,
                  pi_pay_instr_id   => NULL,
                  pio_Err           => l_SrvErr);

          IF NOT srv_error.rqStatus( l_SrvErr )
          THEN
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'pi_doc_id = '||pi_doc_id||' - '||
                                         l_SrvErr( l_SrvErr.FIRST).errmessage);

             po_action_notes := 'POSTPROCESS.PAY_DOC: '||l_SrvErr( l_SrvErr.FIRST).errmessage;
             --pio_procedure_result := blc_gvar_process.flg_err;
             ROLLBACK TO DOC_UPDATE;
          ELSE
             po_action_notes := 'POSTPROCESS.PAY_DOC: payment_id '||l_payment_id;
          END IF;

       END IF;
     END IF;
  ELSIF pio_postprocess IN ('COMP','COMP_LOAN','WOP')
  THEN
     pio_postprocess := 'NONE';
  END IF;

  blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Postprocess_Document');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Postprocess_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Postprocess_Document;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Check_Imm_Run_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.04.2017  creation
--
-- Purpose: Calculate if given run date is elligible for run immediate bill
-- depend on next date and bill period of the given agreement
--
-- Input parameters:
--     pi_run_date        DATE       Billing run date (required)
--     pi_bill_method_id  NUMBER     Bill method (required)
--     pi_agreement       VARCHAR2   Agreement (required)
--
-- Returns:
--     Y/N
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Check_Imm_Run_Date
   (pi_run_date        IN     DATE,
    pi_bill_method_id  IN     NUMBER,
    pi_agreement       IN     VARCHAR2)
RETURN VARCHAR2
IS
    l_date          DATE;
    l_eligible      VARCHAR2(1);
    l_next_date     DATE;
    l_bill_period   NUMBER;
    l_bill_horizon  NUMBER;
    l_bill_cycle_id NUMBER := 23;
    --
    CURSOR c_items IS
      SELECT to_date(bi.attrib_4,'yyyy-mm-dd') next_date,
             to_number(bi.attrib_5) bill_period,
             nvl(to_number(bi.attrib_6),0) bill_horizon
      FROM blc_items bi
      WHERE bi.agreement = pi_agreement
      AND bi.item_type = 'POLICY'
      AND bi.attrib_4 IS NOT NULL
      AND bi.attrib_5 IS NOT NULL
      AND EXISTS (SELECT 'POLICY'
                  FROM blc_installments bin,
                       blc_accounts ba
                  WHERE bin.item_id = bi.item_id
                  AND bin.account_id = ba.account_id
                  AND (nvl(ba.attrib_0,'-999') <> 'CLIENT' OR (ba.attrib_0 = 'CLIENT' AND bin.insurance_type NOT IN ('2001', '2004', '2007', '2008', '2000', '2006')))) --GAP139
      ORDER BY item_id DESC;
BEGIN
   l_eligible := 'Y';

   IF blc_common_pkg.Get_Lookup_Code(pi_bill_method_id) IN ('STANDARD','CANCEL','STANDARD_GROUP') AND pi_run_date IS NOT NULL
   THEN
      OPEN c_items;
        FETCH c_items
        INTO l_next_date, l_bill_period, l_bill_horizon;
      CLOSE c_items;

      IF l_next_date IS NOT NULL
      THEN
        --22.08.2018 replace blc_billing_pkg.Get_Reg_Bill_To_Date with cust_billing_pkg.Get_Reg_Bill_To_Date_2
        l_date := cust_billing_pkg.Get_Reg_Bill_To_Date_2
                          (l_next_date,
                           l_bill_cycle_id,
                           l_bill_period,
                           pi_run_date,
                           l_bill_horizon,
                           0);

        l_date := blc_billing_pkg.Get_Next_Billing_Date
                                        (l_date,
                                         l_bill_cycle_id,
                                         (-1)*l_bill_period);

        IF pi_run_date > l_date
        THEN
           l_eligible := 'N';
        END IF;
      END IF;
    END IF;

    RETURN l_eligible;
END Check_Imm_Run_Date;

--------------------------------------------------------------------------------
-- Name: blc_refund_util_pkg.Create_Payment_for_Document
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.10.2013  creation
--     Fadata   05.02.2014  changed - add parameter bank_acc_type in call
--                                    Get_Usage_By_Acc_Class
--                                    rq 1000007988
--     Fadata   06.06.2014  changed - replace parameter bank_acc_type with
--                                    pmnt_clas in call and add pmnt_currency
--                                    Get_Usage_By_Acc_Class
--                                    rq 1000008694
--     Fadata   15.08.2014  changed - replace function Get_Usage_By_Acc_Class
--                                    and function Calc_Proper_Pmnt_Class
--                                    with procedure Calc_Doc_Usage_Id
--                                    rq 1000009023
--     Fadata   01.10.2014  changed - calculate open balance of document
--                                    as sum of open balance of selected
--                                    transactions
--                                    in case that parameters org_id and office
--                                    are empty than get office from document
--                                    org_site_id instead of insis_context
--                                    rq 1000009178
--     Fadata   30.10.2014  changed - call blc_pmnt_util_pkg.Create_Payment
--                                    because removing of
--                                    blc_refund_util_pkg.Create_Payment
--                                    rq 1000009286
--     Fadata   05.12.2014  changed - add parameter update transaction
--                                    in call Accumulate_Reminders
--                                    rq 1000009392
--     Fadata   05.03.2015  changed - add parameters party_site, pay_party,
--                                    pay_address and currency
--                                    do not change status of document to F
--                                    because in can not pay again when payment
--                                    exists
--                                    rq 1000009677
--     Fadata   26.03.2015  changed - add nvl when select sum of transactions
--                                    for applied
--                                    rq 1000009717
--     Fadata   16.06.2015  changed - add case to create incoming payment for
--                                    negative liability document
--                                    add posibility to pay documents in status
--                                    'F'
--                                    rq 1000009869
--     Fadata   05.08.2015  changed - add default depend setting
--                                    'DatesValidationBase'
--                                    rq 1000009974
--     Fadata   06.08.2015  changed - default party from account of transactions
--                                    check amount of payment to be > 0
--                                    call process PAY_DOC in
--                                    Select_Trx_For_Apply
--                                    rq 1000009977
--     Fadata   24.03.2016  changed - add parameter pay_instrument_id
--                                    rq 1000010381
--     Fadata   26.05.2016  changed - replace substr(l_pmnt_class,1) with
--                                    substr(l_pmnt_class,2) when recalculate
--                                    payment class for negative documents
--                                    rq 1000010498
--     Fadata   10.01.2016  changed - add error message when transactions for
--                                    the document are included into payment run
--                                    rq 1000010842
--     Fadata   03.05.2016  changed - copy from core and change always to set
--                                    limit amount
--     Fadata   15.02.2018  changed - call custom Accumulate_Reminders
--
-- Purpose: Execute procedure for creation of payment for positive liability
-- or negative receivable document
-- Actions:
--     1) Create payment
--     2) Apply payment on document transactions
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required);
--     pi_office              VARCHAR2     Office issue payment;
--     pi_org_id              NUMBER       Payment site id;
--     pi_usage_id            NUMBER       Usage Id;
--     pi_amount              NUMBER       Payment amount;
--     pi_party               VARCHAR2     Party id;
--     pi_party_site          VARCHAR2     Party address id;
--     pi_pay_party           VARCHAR2     Payer party;
--     pi_pay_address         VARCHAR2     Payer party address;
--     pi_bank_code           VARCHAR2     Bank code;
--     pi_bank_acc_code       VARCHAR2     Bank account code;
--     pi_pmnt_address        VARCHAR2     Payment address;
--     pi_currency            VARCHAR      Payment currency;
--     pi_pmnt_date           VARCHAR2     Payment date;
--     pi_pmnt_number         VARCHAR2     Payment number;
--     pi_pay_instr_id        NUMBER       Payment instrument id;
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
-- Returns:
--     payment id
--
-- Usage: In UI when need to pay a document
--
-- Exceptions:
--    1) In case that document is not in proper status
--    2) In cast that usage_id is empty and is not possible to default it
--    3) In case that creation of payment faled
--
-- Dependences: /*TBD_COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Create_Payment_for_Document
   (pi_doc_id         IN     NUMBER,
    pi_office         IN     VARCHAR2,
    pi_org_id         IN     NUMBER,
    pi_usage_id       IN     NUMBER,
    pi_amount         IN     NUMBER,
    pi_party          IN     VARCHAR2,
    pi_party_site     IN     VARCHAR2,
    pi_pay_party      IN     VARCHAR2,
    pi_pay_address    IN     VARCHAR2,
    pi_bank_code      IN     VARCHAR2,
    pi_bank_acc_code  IN     VARCHAR2,
    pi_pmnt_address   IN     VARCHAR2,
    pi_currency       IN     VARCHAR2,
    pi_pmnt_date      IN     DATE,
    pi_pmnt_number    IN     VARCHAR2,
    pi_pay_instr_id   IN     NUMBER,
    pio_Err           IN OUT SrvErr)
RETURN NUMBER
IS
    l_log_module       VARCHAR2(240);
    l_SrvErrMsg        SrvErrMsg;
    l_doc              BLC_DOCUMENTS_TYPE;
    l_usage_id         NUMBER;
    l_pmnt_date        DATE;
    l_payment_id       NUMBER;
    l_acc_class        VARCHAR2(150);
    l_le_id            NUMBER;
    l_org_id           NUMBER;
    l_office           VARCHAR2(30);
    l_amount           NUMBER;
    l_doc_balance      NUMBER;
    l_unappl_amount    NUMBER;
    l_fc_unappl_amount NUMBER;
    l_payment          BLC_PAYMENTS_TYPE;
    l_party            VARCHAR2(30);
    l_party_site       VARCHAR2(30);
    l_reason           VARCHAR2(2000);
    l_pmnt_class       VARCHAR2(150);
    l_bank_code        VARCHAR2(30);
    l_bank_acc_code    VARCHAR2(30);
    l_currency         VARCHAR2(3);
    l_limit_amount     NUMBER;
    l_pay_method_id    NUMBER;
    l_pay_class        VARCHAR2(30);
    l_pay_rate_type    VARCHAR2(30);
    l_pc_rate          NUMBER;
    l_dc_rate          NUMBER;
    l_pc_precision     NUMBER;
    l_dc_precision     NUMBER;
    l_pc_doc_balance   NUMBER;
    l_pay_method       VARCHAR2(120);
    l_usage_name       VARCHAR2(120);
    l_run_list         VARCHAR2(2000);
    --
    CURSOR c_bank_acc(x_bank_acc_id IN NUMBER) IS
      SELECT nvl(pb.bank_code, pb.swift_code), pa.account_num
      FROM p_bank_account pa,
           p_banks pb
      WHERE pa.bank_acc_id = x_bank_acc_id
      AND pa.bank_id = pb.bank_id;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN NULL;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Create_Payment_for_Document';
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'BEGIN of function Create_Payment_for_Document');
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_office = '||pi_office);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                             'pi_org_id = '||pi_org_id);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_usage_id = '||pi_usage_id);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_amount = '||pi_amount);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_party = '||pi_party);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_party_site = '||pi_party_site);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_pay_party = '||pi_pay_party);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_pay_address = '||pi_pay_address);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_bank_code = '||pi_bank_code);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_bank_acc_code = '||pi_bank_acc_code);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_pmnt_address = '||pi_pmnt_address);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_currency = '||pi_currency);
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_pmnt_date = '||to_char(pi_pmnt_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_pmnt_number = '||pi_pmnt_number);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_pay_instr_id = '||pi_pay_instr_id);

    l_doc := NEW blc_documents_type(pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_doc_status = '||l_doc.status);

    IF l_doc.status NOT IN ('A','F')
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_refund_util_pkg.Create_Payment_for_Document', 'blc_refund_util_pkg.CPD.Invalid_Status' );
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||
                                  'Document status is not proper for pay!');
       RETURN NULL;
    END IF;

    --begin rq 1000010842
    l_run_list := blc_appl_util_pkg.Get_Pmnt_Run_Agr_Doc
                     (pi_agreement      => NULL,
                      pi_doc_id         => pi_doc_id);

   IF l_run_list IS NOT NULL
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_refund_util_pkg.Create_Payment_for_Document', 'appl_util_pkg.ACM.InitPmntRunDoc', pi_doc_id||'|'||l_run_list );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||
                                'There are transactions for the document which are selected in payment run(s) '||l_run_list);
      RETURN NULL;
   END IF;
   --end rq 1000010842

    /* Init legal entity */
    blc_appl_cache_pkg.Init_LE( l_doc.legal_entity_id, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'pi_doc_id = '||pi_doc_id||' - '||
                                  pio_Err(pio_Err.FIRST).errmessage);
       RETURN NULL;
    END IF;

    BLC_APPL_UTIL_PKG.Lock_Transactions
    (  PI_SOURCE => NULL,
       PI_AGREEMENT => NULL,
       PI_COMPONENT => NULL,
       PI_DETAIL => NULL,
       PI_ITEM_ID => NULL,
       PI_DOC_ID => PI_DOC_ID,
       PI_TRX_ID => NULL,
       PI_PARTY => NULL,
       PI_ACCOUNT_ID => NULL,
       PIO_ERR => PIO_ERR);

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_doc_id = '||pi_doc_id||' - '||
                                     pio_Err(pio_Err.FIRST).errmessage);
       RETURN NULL;
    END IF;

    IF pi_pmnt_date IS NOT NULL
    THEN
       l_pmnt_date := pi_pmnt_date;
    ELSE
       l_pmnt_date := blc_pmnt_util_pkg.Get_Base_Date; --blc_appl_cache_pkg.g_to_date; -- rq 1000009974
    END IF;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_pmnt_date = '||to_char(l_pmnt_date, 'dd-mm-yyyy'));

    IF pi_currency IS NOT NULL
    THEN
       l_currency := pi_currency;
    ELSE
       l_currency := l_doc.currency;
    END IF;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_currency = '||l_currency);

    IF pi_org_id IS NOT NULL
    THEN
       l_org_id := pi_org_id;
    ELSE
       IF pi_office IS NOT NULL
       THEN
          l_office := pi_office;
       ELSE
          --l_office := insis_context.get_office_id;
          l_office := blc_common_pkg.Get_Office_Id_Org(l_doc.org_site_id,pio_Err);
       END IF;

       l_org_id := blc_common_pkg.Get_Office_Site
          ( l_office,
            l_pmnt_date,
            'PAYMENTS',
            l_le_id,
            pio_Err);
       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_doc_id = '||pi_doc_id||' - '||
                                     pio_Err(pio_Err.FIRST).errmessage);
          RETURN NULL;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_org_id = '||l_org_id);

    IF pi_usage_id IS NOT NULL
    THEN
       l_usage_id := pi_usage_id;
    ELSE
       l_acc_class := BLC_COMMON_PKG.Get_Lookup_Tag_Value
                                 (PI_LOOKUP_SET => 'DOCUMENT_TYPES',
                                  PI_LOOKUP_CODE => NULL,
                                  PI_ORG_ID => l_org_id,
                                  PI_LOOKUP_ID => l_doc.doc_type_id,
                                  PI_TAG_NUMBER => 8);

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'l_acc_class = '||l_acc_class);

       blc_pmnt_util_pkg.Calc_Doc_Pmnt_Attribs
         (pi_doc_id     => pi_doc_id,
          po_usage_name => l_usage_name,
          po_pay_method => l_pay_method,
          po_pmnt_class => l_pmnt_class,
          pio_Err       => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          RETURN NULL;
       END IF;

       IF (l_doc.doc_class = 'B' AND l_doc.amount < 0 AND substr(l_pmnt_class,1,1) = 'I')
       THEN
          l_pmnt_class := 'O'||substr(l_pmnt_class,2); -- rq 1000010498
       ELSIF (l_doc.doc_class = 'L' AND l_doc.amount < 0 AND substr(l_pmnt_class,1,1) = 'O')
       THEN
          l_pmnt_class := 'I'||substr(l_pmnt_class,2); -- rq 1000010498
       END IF;

       IF l_acc_class IS NOT NULL OR l_usage_name IS NOT NULL
           OR l_pay_method IS NOT NULL OR l_pmnt_class IS NOT NULL
       THEN
          blc_pmnt_util_pkg.Calc_Usage_By_Pmnt_Attribs
               (pi_acc_class      => l_acc_class,
                pi_org_id         => l_org_id,
                pi_to_date        => l_pmnt_date,
                pi_bank_acc_code  => NULL,
                pi_pmnt_class     => l_pmnt_class,
                pi_pmnt_currency  => l_currency,
                pi_pay_method     => l_pay_method,
                pi_usage_name     => l_usage_name,
                po_usage_id       => l_usage_id,
                pio_Err           => pio_Err);

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'pi_doc_id = '||pi_doc_id||' - '||
                                         pio_Err(pio_Err.FIRST).errmessage);
             RETURN NULL;
          END IF;
       END IF;

       /*
       blc_pmnt_util_pkg.Calc_Doc_Usage_Id
           (pi_doc_id         => pi_doc_id,
            pi_acc_class      => l_acc_class,
            pi_org_id         => l_org_id,
            pi_to_date        => l_pmnt_date,
            pi_pmnt_currency  => l_doc.currency,
            po_usage_id       => l_usage_id,
            pio_Err           => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          RETURN NULL;
       END IF;
       */
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_STATEMENT,
                              'l_usage_id = '||l_usage_id);

    IF pi_party IS NOT NULL
    THEN
       l_party := pi_party;
       l_party_site := pi_party_site;
    ELSE
       BEGIN
          SELECT DISTINCT ba.party
          INTO l_party
          FROM blc_transactions bt,
               blc_accounts ba
          WHERE bt.doc_id = pi_doc_id
          AND bt.account_id = ba.account_id
          AND bt.status NOT IN ('C','R','D');

          /*
          SELECT man_id
          INTO l_party
          FROM p_address
          WHERE address_id = l_doc.party_site;
          --
          l_party_site := l_doc.party_site;
          */
       EXCEPTION
         WHEN OTHERS THEN
           l_party := NULL;
           l_party_site := NULL;
       END;
   END IF;

   IF l_usage_id IS NOT NULL
   THEN
      BLC_APPL_UTIL_PKG.Select_Trx_For_Apply
       (  PI_SOURCE => NULL,
          PI_AGREEMENT => NULL,
          PI_COMPONENT => NULL,
          PI_DETAIL => NULL,
          PI_ITEM_ID => NULL,
          PI_DUE_DATE => NULL,
          PI_DOC_ID => PI_DOC_ID,
          PI_TRX_ID => NULL,
          PI_PARTY => NULL,
          PI_ACCOUNT_ID => NULL,
          PI_PROCESS => 'PAY_DOC',
          PIO_ERR => PIO_ERR) ;

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                   'pi_doc_id = '||pi_doc_id||' - '||
                                    pio_Err(pio_Err.FIRST).errmessage);
         RETURN NULL;
      END IF;

      SELECT nvl(sum(bt.balance),0)
      INTO l_doc_balance
      FROM TABLE(blc_appl_cache_pkg.g_trx_table) bt;

      IF l_currency <> l_doc.currency
      THEN
         BEGIN
           SELECT pay_method
           INTO l_pay_method_id
           FROM blc_bacc_usages
           WHERE usage_id = l_usage_id;

           l_pay_class := blc_common_pkg.Get_Lookup_Tag_Value
                                     ( NULL, --pi_lookup_set,
                                       NULL, --pi_lookup_code,
                                       NULL, --pi_org_id,
                                       l_pay_method_id,
                                       0);

           l_pay_rate_type := blc_common_pkg.Get_Lookup_Tag_Value
                                     ( 'PAYMENT_CLASS', --pi_lookup_set,
                                       l_pay_class, --pi_lookup_code,
                                       l_org_id,
                                       NULL,
                                       1);
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            l_pay_rate_type := 'FIXING';
         END;

         IF l_currency = blc_appl_cache_pkg.g_fc_currency
         THEN
            l_pc_precision := blc_appl_cache_pkg.g_fc_precision;
            l_pc_rate := 1;
         ELSE
            l_pc_precision := blc_common_pkg.Get_Curr_Precision(l_currency,NULL,blc_appl_cache_pkg.g_country);
            l_pc_rate := blc_common_pkg.Get_Currency_Rate(l_currency,blc_appl_cache_pkg.g_fc_currency,blc_appl_cache_pkg.g_country,l_pmnt_date,l_pay_rate_type,pio_Err);
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                          'pi_doc_id = '||pi_doc_id||' - '||
                                          pio_Err(pio_Err.FIRST).errmessage);
               RETURN NULL;
            END IF;
         END IF;

         IF l_doc.currency = blc_appl_cache_pkg.g_fc_currency
         THEN
            l_dc_precision := blc_appl_cache_pkg.g_fc_precision;
            l_dc_rate := 1;
         ELSE
            l_dc_precision := blc_common_pkg.Get_Curr_Precision(l_doc.currency,NULL,blc_appl_cache_pkg.g_country);
            l_dc_rate := blc_common_pkg.Get_Currency_Rate(l_doc.currency,blc_appl_cache_pkg.g_fc_currency,blc_appl_cache_pkg.g_country,l_pmnt_date,l_pay_rate_type,pio_Err);
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                          'pi_doc_id = '||pi_doc_id||' - '||
                                          pio_Err(pio_Err.FIRST).errmessage);
               RETURN NULL;
            END IF;
         END IF;
         l_pc_doc_balance := round(round(l_doc_balance*l_dc_rate,blc_appl_cache_pkg.g_fc_precision)/l_pc_rate, l_pc_precision);
      ELSE
         l_pc_doc_balance := l_doc_balance;
      END IF;

      IF pi_amount IS NOT NULL
      THEN
         IF abs(pi_amount) > abs(l_pc_doc_balance)
         THEN
            srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_refund_util_pkg.Create_Payment_for_Document', 'blc_refund_util_pkg.CPD.Bigger_Amount', abs(l_pc_doc_balance ));
            srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||
                                       'Payment amount is bigger than document open balance '||abs(l_pc_doc_balance));
            RETURN NULL;
         END IF;
         l_amount := abs(pi_amount);
      ELSE
         l_amount := abs(l_pc_doc_balance);
      END IF;
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_STATEMENT,
                                'l_amount = '||l_amount);
      --03.05.2017
      /*
      IF l_amount = abs(l_pc_doc_balance)
      THEN
         l_limit_amount := NULL;
      ELSE
         l_limit_amount := l_amount;
      END IF;
      */
      l_limit_amount := l_amount;

      IF l_doc.amount = 0
      THEN
         l_limit_amount := NULL;
      END IF;

      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_STATEMENT,
                                 'l_limit_amount = '||l_limit_amount);

      IF pi_bank_code IS NOT NULL OR pi_bank_acc_code IS NOT NULL
      THEN
         l_bank_code := pi_bank_code;
         l_bank_acc_code := pi_bank_acc_code;
      ELSIF l_doc.bank_account IS NOT NULL
      THEN
         OPEN c_bank_acc(l_doc.bank_account);
           FETCH c_bank_acc
           INTO l_bank_code,
                l_bank_acc_code;
         CLOSE c_bank_acc;
      END IF;

      IF l_amount >= 0  -- rq 1000009977
      THEN
         blc_pmnt_util_pkg.Create_Payment
               (pi_payment_date      => l_pmnt_date,
                pi_usage_id          => l_usage_id,
                pi_party             => l_party,
                pi_party_site        => l_party_site,
                pi_pay_party         => pi_pay_party,
                pi_pay_address       => pi_pay_address,
                pi_bank_code         => l_bank_code,
                pi_bank_acc_code     => l_bank_acc_code,
                pi_paym_address      => pi_pmnt_address,
                pi_currency          => l_currency,
                pi_org_id            => l_org_id,
                pi_amount            => l_amount,
                pi_billing_reference => pi_doc_id,
                pi_pay_instr_id      => pi_pay_instr_id,
                po_payment_id        => l_payment_id,
                pio_Err              => pio_Err);

         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||
                                        pio_Err(pio_Err.FIRST).errmessage);
            RETURN NULL;
         END IF;

         l_payment := blc_payments_type(l_payment_id, pio_Err);
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||
                                        pio_Err(pio_Err.FIRST).errmessage);
            RETURN NULL;
         END IF;

         l_unappl_amount := l_amount;
         l_fc_unappl_amount := round(l_amount*l_payment.rate, blc_appl_cache_pkg.g_fc_precision);

         /* Apply transactions to payment */
         --blc_appl_util_pkg.Accumulate_Reminders  --15.02.2018 - replace with custom Accumulate_Reminders
         cust_pay_util_pkg.Accumulate_Reminders
               ( l_payment_id,
                 l_payment.rate,
                 l_payment.rate_date,
                 l_payment.rate_type,
                 blc_appl_cache_pkg.g_to_date,
                 l_payment.rate_date,
                 NULL,
                 l_limit_amount,
                 pi_doc_id,
                 NULL,
                 l_unappl_amount,
                 l_fc_unappl_amount,
                 pio_Err);
         --
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||
                                        pio_Err(pio_Err.FIRST).errmessage);
            RETURN NULL;
         END IF;

         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_STATEMENT,
                                   'l_unappl_amount = '||l_unappl_amount);
      END IF;
   END IF;

   blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'END of function Create_Payment_for_Document - created payment_id = '||l_payment_id);
   RETURN l_payment_id;
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'blc_refund_util_pkg.Create_Payment_for_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '|| SQLERRM);
     RETURN NULL;
END Create_Payment_for_Document;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Check_Reg_Run_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   04.05.2017  creation
--
-- Purpose: Calculate if for client group policies immediate billing is executed
-- to can select installments from regular billing
--
-- Input parameters:
--     pi_item_type       VARCHAR2   Item type (required)
--     pi_policy_type     VARCHAR2   Policy type (required)
--     pi_agreement       VARCHAR2   Agreement (required)
--
-- Returns:
--     Y/N
--
-- Usage: When select eligible installment for billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Check_Reg_Run_Policy
   (pi_item_type       IN     VARCHAR2,
    pi_policy_type     IN     VARCHAR2,
    pi_agreement       IN     VARCHAR2)
RETURN VARCHAR2
IS
   l_policy_level  VARCHAR2(30);
   l_count         PLS_INTEGER;
   l_eligible      VARCHAR2(1);
BEGIN
   l_eligible := 'Y';

   IF pi_item_type = 'POLICY'
   THEN
      l_policy_level := Get_Policy_Level
          ( pi_policy_id   => NULL,
            pi_annex_id    => NULL,
            pi_policy_type => pi_policy_type);

      IF l_policy_level = 'MASTER'
      THEN
         SELECT count(*)
         INTO l_count
         FROM blc_run
         WHERE agreement = pi_agreement
         AND blc_common_pkg.Get_Lookup_Code(bill_method_id) = 'STANDARD_GROUP';

         IF l_count = 0
         THEN
            l_eligible := 'N';
         END IF;
      END IF;
   END IF;

   RETURN l_eligible;

END Check_Reg_Run_Policy;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Convert_Doc_Number
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.08.2017  creation
--
-- Purpose: Modify given number to string with given length numeric digits with
-- leading zeroes
--
-- Input parameters:
--       pi_number      NUMBER   Document number
--       pi_length      NUMBER   Length of number
--
-- Returns: Y/N
--
-- Usage: When need to create fixed digit document number
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Convert_Doc_Number
      (pi_number IN NUMBER,
       pi_length IN NUMBER)
RETURN VARCHAR2
IS
  l_value          VARCHAR2(100);
  l_length         NUMBER;
BEGIN
   IF pi_number IS NULL OR pi_length IS NULL
   THEN
      RETURN NULL;
   END IF;

   l_value := TO_CHAR (pi_number);
   l_length := LENGTH(l_value);
   --
   IF l_length > pi_length
   THEN
      l_value := substr(l_value,(-1)*pi_length);
   END IF;
   --
   WHILE l_length < pi_length -- replace LOOP with WHILE --rq 1000010789
   LOOP
      l_value := '0' || l_value;
      l_length := l_length + 1;
   END LOOP;

   RETURN l_value;
END Convert_Doc_Number;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Modify_Doc_Number
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.08.2017  creation
--
-- Purpose:  Execute procedure for modifying document number
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_action_notes        VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI or workflow process when need to change document number
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--    2) Update document is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Modify_Doc_Number
   (pi_doc_id            IN     NUMBER,
    pio_procedure_result IN OUT VARCHAR2,
    po_action_notes      OUT    VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc                 blc_documents_type;
    l_doc_type            VARCHAR2(30);
    l_SrvErr              SrvErr;
    l_ref_notes           VARCHAR2(4000);
    l_blc_run             blc_run_type;
   --
   CURSOR get_org IS
     SELECT bt.org_id
     FROM blc_transactions bt
     WHERE bt.doc_id = pi_doc_id
     AND bt.status NOT IN ('C','R','D');
     --
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Modify_Doc_Number';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Modify_Doc_Number');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_procedure_result = '||pio_procedure_result);

    l_doc := NEW blc_documents_type(pi_doc_id);

    IF l_doc.status = 'V' AND l_doc.doc_class IN ('B','L') AND (pio_procedure_result IS NULL OR pio_procedure_result = blc_gvar_process.flg_ok)
    THEN
       l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

       IF instr(l_doc.doc_number, l_doc_type) > 0
       THEN
          l_doc.doc_number := REPLACE(l_doc.doc_number,l_doc_type||'-','');
          --
          IF l_doc_type = cust_gvar.DOC_RFND_CN_TYPE OR l_doc_type = cust_gvar.DOC_PROF_TYPE AND l_doc.amount < 0
          THEN
             -- add logic for org dependent prefix

             --calculate reference
             l_ref_notes := Calculate_Doc_Reference(pi_doc_id);

             IF l_ref_notes IS NOT NULL AND instr(l_ref_notes,',') = 0
             THEN
                l_doc.REFERENCE := l_ref_notes;
             ELSE
                l_doc.REFERENCE := CUST_GVAR.MORE_REF;
             END IF;
             --
             blc_doc_util_pkg.Insert_Action
                 ('CALC_REFERENCE',
                  l_ref_notes,
                  'S',
                  pi_doc_id,
                  NULL,
                  pio_Err);

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                pio_procedure_result := blc_gvar_process.flg_err;
                RETURN;
             END IF;
          END IF;

          IF l_doc.run_id IS NOT NULL
          THEN
             l_blc_run := NEW blc_run_type(l_doc.run_id, pio_Err);

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                pio_procedure_result := blc_gvar_process.flg_err;
                RETURN;
             END IF;

             IF blc_common_pkg.get_lookup_code(l_blc_run.bill_method_id) = 'PROTOCOL'
             THEN
                l_doc.doc_prefix := l_blc_run.attrib_6;
             END IF;
          END IF;

          --
          IF NOT l_doc.update_blc_documents( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_EXCEPTION,
                                         'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             pio_procedure_result := blc_gvar_process.flg_err;
             RETURN;
          END IF;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'po_action_notes = '||po_action_notes);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Modify_Doc_Number');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Modify_Doc_Number', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
     pio_procedure_result := blc_gvar_process.flg_err;
END Modify_Doc_Number;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Set_Doc_AD
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.08.2017  creation
--     Fadata   25.06.2021  changed - add check to can set AD only for documents
--                          in status A or F - LAP85-74
--
-- Purpose:  Execute procedure for set document suffix with given AD (autorized
-- document) number
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_action_type         VARCHAR2     Action type (required) CREATE_AD/DELETE_AD
--     pi_ad_number           VARCHAR2     AD number (required)
--     pi_ad_date             DATE         Issued or deleted date of AD (required)
--     pi_action_reason       VARCHAR2     Action reason notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_procedure_result    VARCHAR2     Procedure result
--                                         SUCCESS/WARNING/ERROR
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to change document autorized document
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--    2) Update document is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Doc_AD
   (pi_doc_id            IN     NUMBER,
    pi_action_type       IN     VARCHAR2,
    pi_ad_number         IN     VARCHAR2,
    pi_ad_date           IN     DATE,
    pi_action_reason     IN     VARCHAR2,
    po_procedure_result  OUT VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc                 blc_documents_type;
    l_doc_type            VARCHAR2(30);
    l_SrvErr              SrvErr;
    l_upd_flag            VARCHAR2(1) := 'N';
    l_count_p             PLS_INTEGER;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Set_Doc_AD';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Set_Doc_AD');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_action_type = '||pi_action_type);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_ad_date = '||to_char(pi_ad_date,'dd-mm-yyyy'));
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_action_reason = '||pi_action_reason);

    IF pi_doc_id IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'blc_doc_util_pkg.VDO.No_DocId');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_ad_number IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.No_ADnumber');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_ad_date IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.No_ADdate');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_action_type IS NULL
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.No_ActType');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF pi_action_type NOT IN ('CREATE_AD','DELETE_AD')
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.Inv_ActType');
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    BEGIN
       l_doc := NEW blc_documents_type(pi_doc_id);
       IF blc_common_pkg.get_lookup_code(l_doc.doc_type_id) NOT IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE, 'LOAN_BILL') -- Defect 398 LPV MATRIX 27.05.2021 add 'LOAN_BILL'
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.Inv_DocType');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;
    EXCEPTION
       WHEN OTHERS THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'blc_doc_util_pkg.VDO.Inv_DocId', pi_doc_id);
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END;

    IF pi_action_type = 'CREATE_AD' AND l_doc.status NOT IN ('A','F') --LAP85-74
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.Not_Allow_ActType', l_doc.status);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       FOR i IN 1..pio_Err.COUNT
       LOOP
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = '||pi_doc_id||' - ' ||pio_Err(i).errmessage );
       END LOOP;

       po_procedure_result := cust_gvar.FLG_ERROR;

       RETURN;
    END IF;

    IF pi_action_type = 'CREATE_AD' AND (l_doc.doc_suffix IS NULL OR l_doc.doc_suffix <> pi_ad_number)
    THEN
       IF l_doc.doc_suffix <> pi_ad_number
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.DiffADCreate', l_doc.doc_suffix||'|'||pi_ad_number);
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          po_procedure_result := cust_gvar.FLG_WARNING;
       END IF;

       l_doc.doc_suffix := pi_ad_number;
       l_upd_flag := 'Y';
    ELSIF pi_action_type = 'CREATE_AD' AND l_doc.doc_suffix = pi_ad_number
    THEN
       po_procedure_result := cust_gvar.FLG_SUCCESS;
    ELSIF pi_action_type = 'DELETE_AD' AND l_doc.doc_suffix = pi_ad_number
    THEN
       SELECT count(*)
       INTO l_count_p
       FROM blc_transactions bt,
            blc_applications ba
       WHERE bt.doc_id = pi_doc_id
       AND bt.transaction_id = ba.target_trx
       AND ba.status <> 'D'
       AND ba.reversed_appl IS NULL
       AND NOT EXISTS (SELECT 'REVERSE'
                       FROM blc_applications ba1
                       WHERE ba1.reversed_appl = ba.application_id
                       AND ba1.status <> 'D');

       IF l_count_p = 0
       THEN
          l_doc.doc_suffix := NULL;
          l_upd_flag := 'Y';
       ELSE
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.PaidDoc');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          po_procedure_result := cust_gvar.FLG_ERROR;
       END IF;
    ELSIF pi_action_type = 'DELETE_AD' AND (l_doc.doc_suffix IS NULL OR l_doc.doc_suffix <> pi_ad_number)
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', 'cust_billing_pkg.SDA.DiffADDelete', l_doc.doc_suffix||'|'||pi_ad_number);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       po_procedure_result := cust_gvar.FLG_ERROR;
    END IF;

    IF l_upd_flag = 'Y'
    THEN
       IF NOT l_doc.update_blc_documents( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);

          po_procedure_result := cust_gvar.FLG_ERROR;

          RETURN;
       END IF;

       blc_doc_util_pkg.Insert_Action_2
           (pi_action_type   => pi_action_type,
            pi_notes         => pi_action_reason,
            pi_status        => 'S',
            pi_doc_id        => pi_doc_id,
            pi_reason_id     => NULL,
            pi_attrib_0      => pi_ad_number,
            pi_attrib_1      => NULL,
            pi_attrib_2      => NULL,
            pi_attrib_3      => NULL,
            pi_attrib_4      => NULL,
            pi_attrib_5      => NULL,
            pi_attrib_6      => NULL,
            pi_attrib_7      => NULL,
            pi_attrib_8      => NULL,
            pi_attrib_9      => NULL,
            pi_action_date   => pi_ad_date,
            pio_Err          => pio_Err);

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          FOR i IN 1..pio_Err.COUNT
          LOOP
             blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = '||pi_doc_id||' - ' ||pio_Err(i).errmessage );
          END LOOP;

          po_procedure_result := cust_gvar.FLG_ERROR;

          RETURN;
       END IF;

       IF po_procedure_result IS NULL
       THEN
          po_procedure_result := cust_gvar.FLG_SUCCESS;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_procedure_result = '||po_procedure_result);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Set_Doc_AD');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_AD', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);

END Set_Doc_AD;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Modify_Inst_Attributes
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  Creation - copy from blc_process_pkg
--                                     and extend with processing
--                                     set in context parameter run_id
--
-- Purpose: Function updates installment attributes for an item_id,
-- limited in addition by policy, annex and claim if passed
--
-- Input parameters:
--     pi_item_id          NUMBER        Unique identifier of billing item
--                                       (reguired)
--     pi_policy           VARCHAR2(30)  Policy Id
--     pi_annex            VARCHAR2(30)  Annex Id
--     pi_claim            VARCHAR2(30)  Claim Id
--     pi_external_id      VARCHAR2(30)  Insurance payment plan reference
--     pi_Context          SrvContext    Input context from where get
--                                       values for updated installment
--                                       attributes
--     pio_Err            SrvErr         Specifies structure for passing back the
--                                       error code, error TYPE and corresponding
--                                       message.
--
-- Output parameters:
--     pio_Err            SrvErr         Specifies structure for passing back the
--                                       error code, error TYPE and corresponding
--                                       message.
--
-- Returns:
-- FALSE - When operation cannot be procesed.
-- TRUE  - In case of successful operation.
--
-- Usage: When need to modify installment attributes immediately after creation
-- of one installment group
--
-- Exceptions:
-- 1) when Update_Installment fails
--
-- Dependences: /*TBD-COM*/
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Modify_Inst_Attributes
   (pi_item_id          IN     NUMBER,
    pi_policy           IN     VARCHAR2,
    pi_annex            IN     VARCHAR2,
    pi_claim            IN     VARCHAR2,
    pi_external_id      IN     VARCHAR2,
    pi_Context          IN     SrvContext,
    pio_Err             IN OUT SrvErr )
RETURN BOOLEAN
IS
   l_SrvErrMsg        SrvErrMsg;
   l_log_module       VARCHAR2(240);
   l_inst             blc_installments_type;
   l_update_flag      VARCHAR2(1);
   l_new_postprocess  blc_installments.postprocess%TYPE;
   l_appl_source      NUMBER;
   l_appl_target      NUMBER;
   l_total_unappl     NUMBER;
   l_payment_id       NUMBER;
   l_pmnt_precision   NUMBER;
   l_trx_precision    NUMBER;
   l_rate             NUMBER;
   l_inst_old         blc_installments_type;
   --
   CURSOR get_appl IS
     SELECT bp.currency, bp.payment_id, ba.source_rate_type rate_type,
            ba.target_amount, ba.source_amount, ba.source_rate,
            ba.rate_date, bt.currency trx_currency, bt.rate_type trx_rate_type,
            aa.coeff, bp.legal_entity, bt.rate_date trx_rate_date, bt.rate trx_rate,
            BLC_APPLICATIONS_TYPE(ba.APPLICATION_ID, ba.APPL_CLASS,
                ba.APPL_DATE, ba.VALUE_DATE, ba.RATE_DATE, ba.SOURCE_AMOUNT,
                ba.SOURCE_RATE, ba.SOURCE_RATE_TYPE, ba.SOURCE_ROUNDING, ba.TARGET_AMOUNT,
                ba.TARGET_RATE, ba.TARGET_RATE_TYPE, ba.TARGET_ROUNDING, ba.TARGET_TRX,
                ba.SOURCE_TRX, ba.TARGET_ITEM, ba.APPL_ACTIVITY, ba.APPL_DETAIL, ba.LEGAL_ENTITY,
                ba.ACCOUNT_ID, ba.SOURCE_PAYMENT, ba.REVERSED_APPL, ba.STATUS,
                ba.RUN_ID, ba.CREATED_ON, ba.CREATED_BY, ba.UPDATED_ON,
                ba.UPDATED_BY, ba.ATTRIB_0, ba.ATTRIB_1, ba.ATTRIB_2, ba.ATTRIB_3,
                ba.ATTRIB_4, ba.ATTRIB_5, ba.ATTRIB_6, ba.ATTRIB_7, ba.ATTRIB_8,
                ba.ATTRIB_9, ba.LOB, ba.BATCH, ba.doc_id, ba.status_date, ba.reinstated_appl) r_appl
     FROM blc_applications ba,
          (SELECT bt.transaction_id,
                  bi.postprocess,
                  sum(bi.amount/(SELECT nvl(sum(bi1.amount),0)
                                 FROM blc_installments bi1
                                 WHERE bi1.transaction_id = bt.transaction_id
                                 AND bi1.postprocess = bi.postprocess)) coeff
            FROM blc_installments bi,
                 blc_transactions bt,
                 blc_items bii
            WHERE bi.item_id = pi_item_id
            AND (pi_policy IS NULL OR bi.POLICY = pi_policy)
            AND (pi_annex IS NULL OR bi.annex = pi_annex)
            AND (pi_claim IS NULL OR bi.claim = pi_claim)
            AND (pi_external_id IS NULL OR bi.external_id = pi_external_id)
            AND bi.transaction_id = bt.transaction_id
            AND bi.item_id = bii.item_id
            AND bi.postprocess LIKE 'FREE%'
            AND bi.amount <> 0
            AND (SELECT nvl(sum(bi1.amount),0)
                 FROM blc_installments bi1
                 WHERE bi1.transaction_id = bt.transaction_id
                 AND bi1.postprocess = bi.postprocess) <> 0
            GROUP BY bt.transaction_id, bi.postprocess) aa,
          blc_payments bp,
          blc_transactions bt
     WHERE ba.target_item = pi_item_id
     AND ba.appl_class = 'PMNT_ON_TRANSACTION'
     AND ba.target_trx = aa.transaction_id
     AND blc_pmnt_util_pkg.Get_Pmnt_Acc_Class(ba.source_payment) = aa.postprocess
     AND ba.source_payment = bp.payment_id
     AND ba.target_trx = bt.transaction_id
     AND ba.target_amount <> 0
     AND ba.status <> 'D'  -- RQ1000009218
     AND ba.reversed_appl IS NULL
     AND NOT EXISTS (SELECT 'REVERSE'
                     FROM blc_applications ba1
                     WHERE ba1.reversed_appl = ba.application_id
                     AND ba1.status <> 'D'  -- RQ1000009218
                     )
     ORDER BY bp.payment_id, decode(sign(ba.target_amount),1,1,2);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Modify_Inst_Attributes';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of function Modify_Inst_Attributes');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_item_id = '||pi_item_id);
   /*
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_policy = '||pi_policy);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_annex = '||pi_annex);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_claim = '||pi_claim);
   */
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_external_id = '||pi_external_id);
   --
   l_update_flag := 'N';
   --
   l_new_postprocess := NULL;
   --
   IF pi_item_id IS NULL
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Modify_Inst_Attributes', 'blc_process_pkg.MIA.No_ItemId' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      RETURN FALSE;
   END IF;

   FOR i IN pi_Context.first..pi_Context.last
   LOOP
      CASE pi_Context(i).AttrCode
      WHEN 'POSTPROCESS'
      THEN
         srv_context.GetContextAttrChar (pi_Context, 'POSTPROCESS', l_new_postprocess);
      ELSE NULL;
      END CASE;
   END LOOP;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_STATEMENT,
                              'l_new_postprocess = '||l_new_postprocess);

   l_total_unappl := 0;

   IF l_new_postprocess = 'NORM'
   THEN
      FOR c_appl IN get_appl
      LOOP
         IF l_payment_id IS NULL OR l_payment_id <> c_appl.payment_id
         THEN
            IF l_total_unappl <> 0
            THEN
               --unapply free payment
               BLC_PMNT_UTIL_PKG.Unapply_FREE_Payment
                (PI_PAYMENT_ID => l_payment_id,
                 PI_UNAPPLY_AMOUNT => l_total_unappl*(-1),
                 PIO_ERR => pio_err);

               IF NOT srv_error.rqStatus( pio_Err )
               THEN
                  blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                            'l_payment_id = '||l_payment_id||' - '||
                                             pio_Err(pio_Err.FIRST).errmessage);
                  RETURN FALSE;
               END IF;
            END IF;
            --
            l_total_unappl := 0;
            l_payment_id := c_appl.payment_id;
            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_STATEMENT,
                                       'l_payment_id = '||l_payment_id);
            /* Init legal entity */
            blc_appl_cache_pkg.Init_LE( c_appl.legal_entity, pio_Err );
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                         'l_payment_id = '||l_payment_id||' - '||
                                          pio_Err(pio_Err.FIRST).errmessage);
               RETURN FALSE;
            END IF;
            --
            blc_appl_util_pkg.Lock_Receipts
                     (l_payment_id,
                      pio_Err);
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                          'l_payment_id = '||l_payment_id||' - '||
                                          pio_Err(pio_Err.FIRST).errmessage);
               RETURN NULL;
            END IF;

            l_pmnt_precision := blc_common_pkg.Get_Curr_Precision(c_appl.currency,NULL,blc_appl_cache_pkg.g_country);
         END IF;

         --unapply application
         blc_appl_util_pkg.unapply_application(c_appl.r_appl,
                                  blc_appl_cache_pkg.g_to_date,
                                  pio_Err);
         --
         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                                   'c_appl.r_appl.application_id = '||c_appl.r_appl.application_id||' - '||
                                                   pio_Err(pio_Err.FIRST).errmessage);
               RETURN FALSE;
            END IF;
         END IF;

         IF c_appl.coeff < 1
         THEN
            l_trx_precision := blc_common_pkg.Get_Curr_Precision(c_appl.trx_currency,NULL,blc_appl_cache_pkg.g_country);
            l_appl_target := c_appl.target_amount - round(c_appl.target_amount*c_appl.coeff,l_trx_precision);
            IF c_appl.currency = c_appl.trx_currency
            THEN
               l_appl_source := sign(c_appl.source_amount)*abs(l_appl_target);
            ELSE
               IF c_appl.trx_currency = blc_appl_cache_pkg.g_fc_currency
               THEN
                  l_appl_source := round(sign(c_appl.source_amount)*abs(l_appl_target)/c_appl.source_rate,l_pmnt_precision);
               ELSE
                  IF c_appl.rate_type = c_appl.trx_rate_type AND c_appl.rate_date = c_appl.trx_rate_date
                  THEN
                     l_rate := c_appl.trx_rate;
                  ELSE
                     l_rate := blc_common_pkg.Get_Currency_Rate(c_appl.trx_currency,blc_appl_cache_pkg.g_fc_currency,blc_appl_cache_pkg.g_country,c_appl.rate_date,c_appl.rate_type,pio_Err);
                     IF NOT srv_error.rqStatus( pio_Err )
                     THEN
                        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                                   'c_appl.r_appl.application_id = '||c_appl.r_appl.application_id||' - '||
                                                   pio_Err(pio_Err.FIRST).errmessage);
                        RETURN FALSE;
                     END IF;
                  END IF;
                  --
                  IF c_appl.currency = blc_appl_cache_pkg.g_fc_currency
                  THEN
                     l_appl_source := round(sign(c_appl.source_amount)*abs(l_appl_target)*l_rate,l_pmnt_precision);
                  ELSE
                     l_appl_source := round(round(sign(c_appl.source_amount)*abs(l_appl_target)*l_rate,blc_appl_cache_pkg.g_fc_precision)/c_appl.source_rate,l_pmnt_precision);
                  END IF;
               END IF;
            END IF;
            --
            IF l_appl_target <> 0 AND l_appl_source <> 0
            THEN
               blc_appl_util_pkg.Double_application(c_appl.r_appl,
                                  blc_appl_cache_pkg.g_to_date,
                                  l_appl_source,
                                  l_appl_target,
                                  pio_Err);
               --
               IF NOT srv_error.rqStatus( pio_Err )
               THEN
                   blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                                   'c_appl.r_appl.application_id = '||c_appl.r_appl.application_id||' - '||
                                                   pio_Err(pio_Err.FIRST).errmessage);
                   RETURN FALSE;
               END IF;
            END IF;
         ELSE
            l_appl_source := 0;
         END IF;
         --
         l_total_unappl := l_total_unappl + c_appl.source_amount - l_appl_source;
      END LOOP;

      --process last payment
      IF l_total_unappl <> 0
      THEN
         --unapply free payment
         BLC_PMNT_UTIL_PKG.Unapply_FREE_Payment
          (PI_PAYMENT_ID => l_payment_id,
           PI_UNAPPLY_AMOUNT => l_total_unappl*(-1),
           PIO_ERR => pio_err);

         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                      'l_payment_id = '||l_payment_id||' - '||
                                       pio_Err(pio_Err.FIRST).errmessage);
            RETURN FALSE;
         END IF;
      END IF;
   END IF;

   FOR c_inst IN (SELECT BLC_INSTALLMENTS_TYPE (INSTALLMENT_ID, INSTALLMENT_CLASS, INSTALLMENT_TYPE,
                       INSTALLMENT_DATE, CURRENCY, AMOUNT, ANNIVERSARY, POSTPROCESS, TRX_RATE, TRX_RATE_TYPE, TRX_RATE_DATE,
                       REC_RATE, REC_RATE_TYPE, REC_RATE_DATE, POLICY_OFFICE, ACTIVITY_OFFICE, INSURANCE_TYPE,
                       POLICY, ANNEX, LOB, FRACTION_TYPE, AGENT, CLAIM, CLAIM_REQUEST, TREATY,
                       ADJUSTMENT, COMPENSATED, SEQUENCE_ORDER, NOTES, LEGAL_ENTITY, ORG_ID, ACCOUNT_ID, ITEM_ID,
                       TRANSACTION_ID, BILLING_RUN_ID, INTERNAL, STATUS, CREATED_ON, CREATED_BY, UPDATED_ON,
                       UPDATED_BY, ATTRIB_0, ATTRIB_1, ATTRIB_2, ATTRIB_3, ATTRIB_4,
                       ATTRIB_5, ATTRIB_6, ATTRIB_7, ATTRIB_8,ATTRIB_9, EXTERNAL_ID, COMMAND, BATCH,
                       FC_VARIANCE, SPLIT_FLAG) r_inst_type
                     FROM blc_installments
                     WHERE item_id = pi_item_id
                     AND compensated = 'N'
                     AND (pi_policy IS NULL OR POLICY = pi_policy)
                     AND (pi_annex IS NULL OR annex = pi_annex)
                     AND (pi_claim IS NULL OR claim = pi_claim)
                     AND (pi_external_id IS NULL OR external_id = pi_external_id))
      LOOP
         l_inst := c_inst.r_inst_type;
         l_inst_old := l_inst;
         FOR i IN pi_Context.first..pi_Context.last
         LOOP
            CASE pi_Context(i).AttrCode
            WHEN 'INST_ATTRIB_0' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_0', l_inst.attrib_0);
            WHEN 'INST_ATTRIB_1' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_1', l_inst.attrib_1);
            WHEN 'INST_ATTRIB_2' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_2', l_inst.attrib_2);
            WHEN 'INST_ATTRIB_3' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_3', l_inst.attrib_3);
            WHEN 'INST_ATTRIB_4' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_4', l_inst.attrib_4);
            WHEN 'INST_ATTRIB_5' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_5', l_inst.attrib_5);
            WHEN 'INST_ATTRIB_6' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_6', l_inst.attrib_6);
            WHEN 'INST_ATTRIB_7' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_7', l_inst.attrib_7);
            WHEN 'INST_ATTRIB_8' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_8', l_inst.attrib_8);
            WHEN 'INST_ATTRIB_9' THEN srv_context.GetContextAttrChar (pi_Context, 'INST_ATTRIB_9', l_inst.attrib_9);
            WHEN 'RUN_ID' THEN srv_context.GetContextAttrNumber (pi_Context, 'RUN_ID', l_inst.billing_run_id);
            WHEN 'POSTPROCESS'
            THEN
               srv_context.GetContextAttrChar (pi_Context, 'POSTPROCESS', l_new_postprocess);

               IF NVL(l_inst.postprocess,'NORM') <> 'NORM' AND l_new_postprocess LIKE 'FREE%' AND l_inst.postprocess <> l_new_postprocess
               THEN
                  srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Modify_Inst_Attributes', 'blc_process_pkg.MIA.Not_Allow_Postprocess', l_inst.postprocess||'|'||l_new_postprocess);
                  srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_EXCEPTION,
                                             'l_insatllment_id = '||l_inst.installment_id||' - '||'It is not allowed to change postprocess from '||l_inst.postprocess||' to '||l_new_postprocess);
               ELSE
                  l_inst.postprocess := l_new_postprocess;
                  l_update_flag := 'Y';
               END IF;
            ELSE NULL;
            END CASE;
         END LOOP;

         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_PROCEDURE,
                                   'pi_protocol_number = '||l_inst.attrib_6);
         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_PROCEDURE,
                                   'pi_run_id = '||l_inst.billing_run_id);

         IF l_inst_old.billing_run_id IS NOT NULL AND l_inst.billing_run_id IS NOT NULL
         THEN
            srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Modify_Inst_Attributes', 'cust_billing_pkg.MIA.Already_Billed', l_inst.external_id||'|'||l_inst_old.billing_run_id);
            srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_EXCEPTION,
                                       'Installment - installment_id = '||l_inst.installment_id||' - '||' with external_id '||l_inst.external_id||' is already billed with run_id '||l_inst_old.billing_run_id);
            RETURN FALSE;
         END IF;
         --
         IF NOT l_inst.update_blc_installments(pio_Err)
         THEN
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'l_inst.installment_id = '||l_inst.installment_id ||' - '||
                                        pio_Err(pio_Err.FIRST).errmessage);
            RETURN FALSE;
         END IF;
     END LOOP;

   IF l_update_flag = 'Y' AND l_inst.postprocess LIKE 'FREE%'
   THEN
      FOR c_doc IN ( SELECT bt.doc_id, bt.legal_entity, bii.agreement
                     FROM blc_installments bi,
                          blc_transactions bt,
                          blc_items bii
                     WHERE bi.item_id = pi_item_id
                     AND (pi_policy IS NULL OR bi.POLICY = pi_policy)
                     AND (pi_annex IS NULL OR bi.annex = pi_annex)
                     AND (pi_claim IS NULL OR bi.claim = pi_claim)
                     AND (pi_external_id IS NULL OR bi.external_id = pi_external_id)
                     AND bi.transaction_id = bt.transaction_id
                     AND bi.item_id = bii.item_id
                     GROUP BY bt.doc_id, bt.legal_entity, bii.agreement)
          LOOP
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'l_doc_id = '||c_doc.doc_id);
             /* Init legal entity */
             blc_appl_cache_pkg.Init_LE( c_doc.legal_entity, pio_Err );
             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_item_id = '||pi_item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                RETURN FALSE;
             END IF;
             --
             blc_appl_util_pkg.Postprocess_Document_FREE
                                 (pi_source      => NULL,
                                  pi_agreement   => c_doc.agreement,
                                  pi_component   => NULL,
                                  pi_detail      => NULL,
                                  pi_doc_id      => c_doc.doc_id,
                                  pi_postprocess => l_inst.postprocess,
                                  pio_Err        => pio_Err);

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_item_id = '||pi_item_id||' - '||
                                           'pi_doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                RETURN FALSE;
             END IF;
          END LOOP;
    END IF;
    blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of function Modify_Inst_Attributes');
    RETURN TRUE;
END;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Doc_Reference
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  creation
--
-- Purpose: Calculates list of positive documents related to the same bill
-- period as is for the given negative document
--
-- Input parameters:
--     pi_doc_id          NUMBER     Document identifier
--
-- Returns:
--     List of doc ids
--
-- Usage: In run billing to calculate reference of the document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Doc_Reference
   (pi_doc_id   IN     NUMBER)
RETURN VARCHAR2
IS
  l_doc_ids VARCHAR2(2000);
BEGIN
  FOR c_cr IN (SELECT bi.item_id, bi.attrib_4, bi.attrib_5
               FROM blc_installments bi,
                    blc_transactions bt
               WHERE bi.transaction_id = bt.transaction_id
               AND bt.status NOT IN ('C','R','D')
               AND bt.doc_id = pi_doc_id
               AND bt.amount < 0
               GROUP BY bi.item_id, bi.attrib_4, bi.attrib_5)
  LOOP
     FOR c_dr IN (SELECT bt.doc_id
                  FROM blc_installments bi,
                       blc_transactions bt,
                       blc_documents bd
                  WHERE bi.item_id  = c_cr.item_id
                  AND (bi.attrib_4 <= nvl(c_cr.attrib_4, bi.attrib_4) OR bi.attrib_4 IS NULL AND c_cr.attrib_4 IS NULL)
                  AND (bi.attrib_5 = nvl(c_cr.attrib_5, bi.attrib_5) OR bi.attrib_5 IS NULL AND c_cr.attrib_5 IS NULL)
                  AND bi.transaction_id = bt.transaction_id
                  AND bt.status NOT IN ('C','R','D')
                  AND bt.amount > 0
                  AND bt.doc_id = bd.doc_id
                  AND bd.status IN ('A','F')
                  AND bd.amount > 0
                  GROUP BY bt.doc_id)
     LOOP
        IF l_doc_ids IS NULL
        THEN
           l_doc_ids := c_dr.doc_id;
        ELSIF instr(','||l_doc_ids||',', ','||c_dr.doc_id||',') = 0 AND length(l_doc_ids||','||c_dr.doc_id) <= 2000
        THEN
           l_doc_ids := l_doc_ids||','||c_dr.doc_id;
        END IF;
     END LOOP;
  END LOOP;

  RETURN l_doc_ids;
END Calculate_Doc_Reference;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Validate_Doc_Reference
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.08.2017  creation
--     Fadata   08.03.2019  changed - add validation for empty reference and
--                                    special case 'M-%'
--                                    LPVS-98
--
-- Purpose: Execute procedure for validate doc reference
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_doc_status          VARCHAR2     Document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In complete document to validate doc reference
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_Doc_Reference
   (pi_doc_id             IN     NUMBER,
    pio_procedure_result  IN OUT VARCHAR2,
    po_doc_status         OUT    VARCHAR2,
    pio_Err               IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_SrvErr              SrvErr;
    l_doc                 blc_documents_type;
    l_doc_type            VARCHAR2(30);
    l_ref_list            VARCHAR2(2000);
    l_ref_notes           VARCHAR2(4000);
BEGIN
   blc_log_pkg.initialize(pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   l_log_module := C_DEFAULT_MODULE||'.Validate_Doc_Reference';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Validate_Doc_Reference');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

   l_doc := NEW blc_documents_type(pi_doc_id);
   IF l_doc.doc_id IS NULL
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Validate_Doc_Reference', 'GetBLCDocument_No_Doc_id' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||'Invalid document Id');
      pio_procedure_result := blc_gvar_process.flg_err;
      RETURN;
   END IF;

   l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

   IF l_doc_type = cust_gvar.DOC_RFND_CN_TYPE OR l_doc_type = cust_gvar.DOC_PROF_TYPE AND l_doc.amount < 0
   THEN
      IF l_doc.REFERENCE LIKE 'M-%'
      THEN
         l_ref_notes := NULL; --exclude special case M-% from check reference -- LPVS-98
      ELSIF TRIM(l_doc.REFERENCE) IS NULL --check if empty -- LPVS-98
      THEN
         l_ref_notes := srv_error.GetSrvMessage('cust_billing_pkg.VDR.EmptyRef');
      ELSE
         l_ref_list := Calculate_Doc_Reference(pi_doc_id);

         IF instr(l_doc.REFERENCE,',') > 0 OR instr(','||l_ref_list||',', ','||l_doc.REFERENCE||',') = 0
         THEN
            l_ref_notes := srv_error.GetSrvMessage('cust_billing_pkg.VDR.InvRef')||': '||l_ref_list;
         ELSE
            l_ref_notes := NULL;
         END IF;
      END IF;
      --
      IF l_ref_notes IS NOT NULL
      THEN
         SAVEPOINT DOC_UPDATE;

         IF NOT blc_doc_util_pkg.Hold_Document
                     (pio_doc    => l_doc,
                      pi_notes   => l_ref_notes,
                      pio_Err    => pio_Err)
         THEN
            pio_procedure_result := blc_gvar_process.flg_err;
            ROLLBACK TO DOC_UPDATE;
            RETURN;
         END IF;
      END IF;
      --
   END IF;

   po_doc_status := l_doc.status;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'po_doc_status = '||po_doc_status);

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Validate_Doc_Reference');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Validate_Doc_Reference', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
     pio_procedure_result := blc_gvar_process.flg_err;
     ROLLBACK TO DOC_UPDATE;
END Validate_Doc_Reference;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Appr_Compl_Document
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.08.2017  creation - rq 1000011083
--
-- Purpose: Execute procedure for document approval and completion
-- Depend on current document status execute the steps:
--     1) Approve document
--     2) Postprocess document

-- Input parameters:
--     pio_doc         BLC_DOCUMENTS_TYPE  Document type
--     pio_Err         SrvErr              Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_doc         BLC_DOCUMENTS_TYPE  Document type
--     pio_Err         SrvErr              Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
-- Returns:
--    TRUE  - In case of successful processing, documnet is approved
--    FALSE - In case of some errors, document is in it current status
--
-- Usage: In UI when need to approve documents
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Appr_Compl_Document
   (pio_doc    IN OUT NOCOPY BLC_DOCUMENTS_TYPE,
    pio_Err    IN OUT SrvErr)
RETURN BOOLEAN
IS
    l_log_module    VARCHAR2(240);
    l_SrvErrMsg     SrvErrMsg;
    l_Context       srvcontext;
    l_RetContext    srvcontext;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Appr_Compl_Document';
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'BEGIN of function Appr_Compl_Document');
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'l_doc_id = '||pio_doc.doc_id);
    blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'l_doc_status = '||pio_doc.status);

    srv_prm_process.Set_Doc_Id( l_Context, pio_doc.doc_id );

    IF pio_doc.doc_class IN ('R','P')
    THEN
       srv_events.sysEvent( 'CUST_APPR_COMPL_BLC_DOCUMENT_RP', l_Context, l_RetContext, pio_Err );
    ELSE
       srv_events.sysEvent( 'CUST_APPR_COMPL_BLC_DOCUMENT', l_Context, l_RetContext, pio_Err );
    END IF;

    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pio_doc.doc_id = '||pio_doc.doc_id||' - '||pio_Err(pio_Err.LAST).errmessage);
       RETURN FALSE;
    ELSE
       pio_doc := NEW blc_documents_type(pio_doc.doc_id);
       RETURN TRUE;
    END IF;
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Appr_Compl_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pio_doc.doc_id = '||pio_doc.doc_id||' - '|| SQLERRM);
     RETURN FALSE;
END Appr_Compl_Document;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Appr_Compl_Documents
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.08.2017  creation - rq 1000011083
--
-- Purpose: Executes procedure for approve and complete documents with ids from
-- given list indepent on them status and return list of not posiible to
-- complete documents
--
-- Input parameters:
--     pi_doc_ids           VARCHAR2      List of document Ids
--     pio_Err              SrvErr        Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Output parameters:
--     po_doc_list          VARCHAR2      List of document numbers which are
--                                        continue to stay not approved after
--                                        successfully execution of procedure
--     pio_Err              SrvErr        Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Usage: From UI when need to approve documents.
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Appr_Compl_Documents
   (pi_doc_ids        IN     VARCHAR2,
    po_doc_list       OUT    VARCHAR2,
    pio_Err           IN OUT SrvErr)
IS
   l_count           PLS_INTEGER;
   l_log_module      VARCHAR2(240);
   l_SrvErrMsg       SrvErrMsg;
   l_doc_ids         BLC_SELECTED_OBJECTS_TABLE;
   l_count_s         PLS_INTEGER;
   l_count_e         PLS_INTEGER;
   l_count_p         PLS_INTEGER;
   l_doc_list        VARCHAR2(2000);
   l_SrvErr          SrvErr;
   l_Context         srvcontext;
   l_RetContext      srvcontext;
   l_doc             BLC_DOCUMENTS_TYPE;
   --

   CURSOR c_documents IS
      SELECT bd.doc_id, bd.status, bd.doc_number,
             BLC_DOCUMENTS_TYPE (bd.DOC_ID, bd.LEGAL_ENTITY_ID, bd.ORG_SITE_ID, bd.OFFICE, bd.PARTY_SITE,
                     bd.DOC_CLASS, bd.DOC_TYPE_ID, bd.ISSUE_DATE, bd.DUE_DATE, bd.CURRENCY, bd.AMOUNT, bd.NOTES,
                     bd.GRACE, bd.GRACE_EXTRA, bd.COLLECTION_LEVEL, bd.BANK_ACCOUNT, bd.PAY_METHOD_ID,
                     bd.DOC_PREFIX, bd.DOC_NUMBER, bd.DOC_SUFFIX, bd.REFERENCE, bd.REF_DOC_ID, bd.RUN_ID,
                     bd.DIRECTION, bd.STATUS, bd.CREATED_ON, bd.CREATED_BY, bd.UPDATED_ON, bd.UPDATED_BY,
                     bd.ATTRIB_0, bd.ATTRIB_1, bd.ATTRIB_2, bd.ATTRIB_3, bd.ATTRIB_4,
                     bd.ATTRIB_5, bd.ATTRIB_6, bd.ATTRIB_7, bd.ATTRIB_8, bd.ATTRIB_9, PAY_WAY_ID, PAY_INSTR
                     ) r_doc_type
      FROM blc_documents bd
      WHERE bd.doc_id IN (SELECT * FROM TABLE(l_doc_ids))
      AND NVL(blc_doc_process_pkg.Get_Doc_Last_Action(bd.doc_id), '-999') <> 'WAIT_APPROVE'
      ORDER BY bd.issue_date
      FOR UPDATE WAIT 10;
BEGIN
   blc_log_pkg.initialize(pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;
   l_log_module := C_DEFAULT_MODULE||'.Appr_Compl_Documents';

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of function Appr_Compl_Documents' );
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_ids = '||pi_doc_ids);

   l_count_s := 0;
   l_count_e := 0;
   l_count_p := 0;
   l_doc_list := NULL;

   l_doc_ids := blc_common_pkg.convert_list(pi_doc_ids);

   FOR c_doc IN c_documents
   LOOP
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_STATEMENT,
                                 'l_doc_id = '||c_doc.doc_id||' - '||c_doc.status);
      l_SrvErr := NULL;
      l_doc := c_doc.r_doc_type;

      IF NOT Appr_Compl_Document(l_doc, l_SrvErr)
      THEN
         l_count_e := l_count_e + 1;
         IF l_doc_list IS NULL
         THEN
            l_doc_list := c_doc.doc_number;
         ELSE
            l_doc_list := substr(l_doc_list||'; '||c_doc.doc_number,1,2000);
         END IF;
      ELSE
         SELECT count(*)
         INTO l_count_p
         FROM blc_documents bd
         WHERE bd.doc_id = c_doc.doc_id
         AND bd.status = 'V';

          IF l_count_p = 1
          THEN
             l_count_e := l_count_e + 1;
             IF l_doc_list IS NULL
             THEN
                l_doc_list := c_doc.doc_number;
             ELSE
                l_doc_list := substr(l_doc_list||'; '||c_doc.doc_number,1,2000);
             END IF;
          ELSE
             SELECT count(*)
             INTO l_count_p
             FROM blc_actions ba,
                  blc_lookups bl
             WHERE ba.document_id = l_doc.doc_id
             AND ba.action_type_id = bl.lookup_id
             AND bl.lookup_code = 'POST'
             AND ba.status = 'S';

             IF l_count_p = 0
             THEN
                l_count_e := l_count_e + 1;
                IF l_doc_list IS NULL
                THEN
                   l_doc_list := l_doc.doc_number;
                ELSE
                   l_doc_list := substr(l_doc_list||'; '||l_doc.doc_number,1,2000);
                END IF;
             ELSE
                l_count_s := l_count_s + 1;
             END IF;
          END IF;
      END IF;
      --
      IF l_SrvErr IS NOT NULL
      THEN
        FOR i IN l_SrvErr.first..l_SrvErr.last
        LOOP
           IF pio_Err IS NULL
           THEN
              pio_Err := SrvErr(l_SrvErr(i));
           ELSE
              l_count := pio_Err.count;
              pio_Err.EXTEND;
              pio_Err(l_count+1) := l_SrvErr(i);
            END IF;
        END LOOP;
      END IF;

      l_RetContext := NULL;
    END LOOP;

    IF l_doc_list IS NOT NULL
   THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Appr_Compl_Documents', 'blc_process_pkg.CD.Exist_Incomplete_Doc',l_doc_list );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'There are incomplete documents: '||l_doc_list);
   END IF;

    po_doc_list := l_doc_list;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'END of procedure Appr_Compl_Documents - completed documents: '||l_count_s||' incompleted documents: '||l_count_e);

END Appr_Compl_Documents;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Referred_Doc
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.08.2017  creation
--
-- Purpose: Calculates list of negative documents for an agreement which
-- referred given doc_id
--
-- Input parameters:
--     pi_doc_id          NUMBER     Document identifier
--     pi_agreement       VARCHAR2   Item agreement
--
-- Returns:
--     List of doc ids
--
-- Usage: In document deletion to calculate list of referred documents
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Referred_Doc
   (pi_doc_id     IN     NUMBER,
    pi_agreement  IN     VARCHAR2)
RETURN VARCHAR2
IS
  l_doc_ids VARCHAR2(4000);
BEGIN
  FOR c_doc IN (SELECT bd.doc_id
                FROM blc_items bi,
                     blc_transactions bt,
                     blc_documents bd
                WHERE bi.agreement = pi_agreement
                AND bi.item_type = 'POLICY'
                AND bi.item_id = bt.item_id
                AND bt.status NOT IN ('C','R','D')
                AND bt.doc_id = bd.doc_id
                AND bd.status IN ('A','F')
                AND bd.REFERENCE = TO_CHAR( pi_doc_id )
                GROUP BY bd.doc_id)
  LOOP
     IF l_doc_ids IS NULL
     THEN
        l_doc_ids := c_doc.doc_id;
     ELSE
        l_doc_ids := l_doc_ids||','||c_doc.doc_id;
     END IF;
  END LOOP;

  RETURN l_doc_ids;
END Calculate_Referred_Doc;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mark_For_Deletion
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   28.08.2017  creation
--     Fadata   13.06.2018  changed - change parameter po_action_notes to
--                          pio_action_notes
--                          add parameter pi_rev_reason in
--                          Lock_Doc_For_Delete - LPV-1654
--
-- Purpose:  Execute procedure for check availability for deletion of proforma
-- and call integration server to lock for deletion proforma in SAP
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_action_notes       VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_action_notes       VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI when need to delete proforma
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mark_For_Deletion
   (pi_doc_id            IN     NUMBER,
    pio_procedure_result IN OUT VARCHAR2,
    pio_action_notes     IN OUT VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc                 blc_documents_type;
    l_agreement           VARCHAR2(50);
    l_SrvErr              SrvErr;
    l_doc_ids             VARCHAR2(4000);
    l_count               PLS_INTEGER;
    l_procedure_result    VARCHAR2(30);
    l_doc_status          VARCHAR2(1);
    l_rev_reason          VARCHAR2(4000);
   --
   CURSOR get_agr IS
     SELECT bi.agreement
     FROM blc_transactions bt,
          blc_items bi
     WHERE bt.doc_id = pi_doc_id
     AND bt.status NOT IN ('C','R','D')
     AND bt.item_id = bi.item_id;
    --
    l_doc_type  VARCHAR2(30);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Mark_For_Deletion';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Mark_For_Deletion');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_procedure_result = '||pio_procedure_result);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_action_notes = '||pio_action_notes);

    l_doc := NEW blc_documents_type(pi_doc_id);

    l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

    IF l_doc_type IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE) AND (pio_procedure_result IS NULL OR pio_procedure_result = blc_gvar_process.flg_ok)
    THEN
       IF l_doc.doc_suffix IS NOT NULL
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mark_For_Deletion', 'cust_billing_pkg.MFD.Exist_ADnumber');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_EXCEPTION,
                                     'pi_doc_id = '||pi_doc_id||' - '||'The document has AD number');
       END IF;

       IF l_doc.amount > 0
       THEN
          OPEN get_agr;
            FETCH get_agr
            INTO l_agreement;
          CLOSE get_agr;

          l_doc_ids := Calculate_Referred_Doc(pi_doc_id,l_agreement);

          IF l_doc_ids IS NOT NULL
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mark_For_Deletion', 'cust_billing_pkg.MFD.Exist_CNReference', l_doc_ids );
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||'The document is referred from doc_id(s): '||l_doc_ids);
          END IF;
       END IF;

       SELECT count(*)
       INTO l_count
       FROM blc_transactions bt,
            blc_applications ba
       WHERE bt.doc_id = pi_doc_id
       AND ba.target_trx = bt.transaction_id
       AND ba.reversed_appl IS NULL
       AND NOT EXISTS (SELECT 'REVERSE'
                       FROM blc_applications ba1
                       WHERE ba1.reversed_appl = ba.application_id);

       IF l_count = 0
       THEN
          SELECT count(*)
          INTO l_count
          FROM blc_transactions bt,
               blc_applications ba
          WHERE bt.doc_id = pi_doc_id
          AND ba.source_trx = bt.transaction_id
          AND ba.reversed_appl IS NULL
          AND NOT EXISTS (SELECT 'REVERSE'
                          FROM blc_applications ba1
                          WHERE ba1.reversed_appl = ba.application_id);
       END IF;

       IF l_count > 0
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mark_For_Deletion', 'blc_doc_util_pkg.CTBD.ApplFound' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_doc_id = '||pi_doc_id||' - '||
                                    'There are not reversed applications');
       END IF;

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          pio_procedure_result := blc_gvar_process.flg_err;
          RETURN;
       END IF;

       IF l_doc.status = 'F'
       THEN
          --IP - need to call service for lock document in SAP
          l_rev_reason := pio_action_notes;

          cust_intrf_util_pkg.Lock_Doc_For_Delete
                            (pi_doc_id            => pi_doc_id,
                             pi_rev_reason        => l_rev_reason, --LPV-1654
                             po_procedure_result  => l_procedure_result,
                             pio_Err              => pio_Err);

          IF l_procedure_result = cust_gvar.FLG_ERROR
          THEN
             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
             ELSE
                srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mark_For_Deletion', 'cust_billing_pkg.PRP.IP_Error');
                srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'pi_doc_id = '||pi_doc_id||' - '||'Integration for lock document for deletion in SAP return error');
             END IF;
             --
             pio_procedure_result := blc_gvar_process.flg_err;
             RETURN;
          END IF;

       END IF;

       blc_doc_process_pkg.Set_Unformal_Document
              (pi_doc_id             => pi_doc_id,
               pi_action_notes       => srv_error.GetSrvMessage('cust_billing_pkg.MFD.MarkDelete'),
               pio_procedure_result  => pio_procedure_result,
               po_doc_status         => l_doc_status,
               pio_Err               => pio_Err);
    ELSIF l_doc_type = cust_gvar.DOC_ACC_TYPE AND (pio_procedure_result IS NULL OR pio_procedure_result = blc_gvar_process.flg_ok)
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mark_For_Deletion', 'cust_billing_pkg.MFD.Not_Allowed', l_doc_type);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||'Activity is not allowed for the document type '||l_doc_type);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pio_action_notes = '||pio_action_notes);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Mark_For_Deletion');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mark_For_Deletion', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
     pio_procedure_result := blc_gvar_process.flg_err;
END Mark_For_Deletion;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Set_Formal_Unformal
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2017  creation
--     Fadata   13.06.2018  changed - change parameter po_action_notes to
--                          pio_action_notes in call Mark_For_Deletion - LPV-1654
--
-- Purpose: Execute procedure for validation of change status to Formal/Unformal
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_action_notes        VARCHAR2     Action notes
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_doc_status          VARCHAR2     New document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI or workflow process when need to set document in Formal or
-- Unformal status
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Set_Formal_Unformal
   (pi_doc_id             IN     NUMBER,
    pi_action_notes       IN     VARCHAR2,
    pio_procedure_result  IN OUT VARCHAR2,
    pio_Err               IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_SrvErr              SrvErr;
    l_doc                 blc_documents_type;
    l_doc_type            VARCHAR2(30);
    l_action_notes        VARCHAR2(4000);
    l_doc_status          VARCHAR2(1);
BEGIN
   blc_log_pkg.initialize(pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   l_log_module := C_DEFAULT_MODULE||'.Pre_Set_Formal_Unformal';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Pre_Set_Formal_Unformal');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

   l_doc := NEW blc_documents_type(pi_doc_id);

   IF l_doc.status = 'F'
   THEN
      l_action_notes := pi_action_notes;
      l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);
      IF l_doc_type IN (cust_gvar.DOC_PROF_TYPE, cust_gvar.DOC_RFND_CN_TYPE)
      THEN
         cust_billing_pkg.Mark_For_Deletion
                           (pi_doc_id            => pi_doc_id,
                            pio_procedure_result => pio_procedure_result,
                            pio_action_notes     => l_action_notes,
                            pio_Err              => pio_Err);

         IF NOT srv_error.rqStatus( pio_Err )
         THEN
            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            RETURN;
         END IF;

         blc_doc_process_pkg.Delete_Document
                    (pi_doc_id             => pi_doc_id,
                     pi_action_notes       => pi_action_notes,
                     pio_procedure_result  => pio_procedure_result,
                     po_doc_status         => l_doc_status,
                     pio_Err               => pio_Err);

         IF pio_procedure_result = cust_gvar.FLG_ERROR
         THEN
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
            END IF;

            RETURN;
         END IF;
      END IF;
   ELSE
      srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Set_Formal_Unformal', 'cust_billing_pkg.PSFU.ActNotAllowed' );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_EXCEPTION,
                                 'pi_doc_id = '||pi_doc_id||' - '||'The activity is not allowed');
      pio_procedure_result := blc_gvar_process.flg_err;
   END IF;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Pre_Set_Formal_Unformal');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Set_Formal_Unformal', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
     pio_procedure_result := blc_gvar_process.flg_err;
END Pre_Set_Formal_Unformal;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Not_Pay_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2017  creation
--
-- Purpose: Check if given annex is cancellation for not payment
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for cancellation for not payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Not_Pay_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  l_value       VARCHAR2(1);
  l_count       PLS_INTEGER;
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      l_value := 'N';
   ELSE
       SELECT count(*)
       INTO l_count
       FROM gen_annex_reason
       WHERE policy_id = pi_policy_id
       AND annex_id = pi_annex_id
       AND ((annex_type = '17' AND annex_reason = 'CANCLAPS')
            OR
            (annex_type = '12' AND annex_reason = 'PAIDUP'));

      IF l_count > 0
      THEN
         l_value := 'Y';
         --
         SELECT count(*)
         INTO l_count
         FROM gen_annex_reason
         WHERE policy_id = pi_policy_id
         AND annex_id = pi_annex_id
         AND annex_reason = 'MANUAL';

         IF l_count > 0
         THEN
            l_value := 'N';
         END IF;
      ELSE
         l_value := 'N';
      END IF;
   END IF;

   RETURN l_value;
END Is_Not_Pay_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Canc_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2017  creation
--
-- Purpose: Check if given annex is cancellation
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for cancellation for not payment
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Canc_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  --
  CURSOR c_annex IS
    SELECT annex_id
    FROM gen_annex
    WHERE policy_id = pi_policy_id
    AND annex_id = pi_annex_id
    AND annex_type = '17';
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      RETURN 'N';
   END IF;

   OPEN c_annex;
     FETCH c_annex
     INTO l_annex_id;
   CLOSE c_annex;

   IF l_annex_id IS NOT NULL
   THEN
      RETURN 'Y';
   ELSE
      RETURN 'N';
   END IF;
END Is_Canc_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Item_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2017  creation
--
-- Purpose: Check if given item list includes only one iten from type POLICY
--
-- Input parameters:
--     pi_item_ids   Varchar2    Item ids (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if it is item policy
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Item_Policy
   (pi_item_ids     IN     VARCHAR2)
RETURN VARCHAR2
IS
   l_count PLS_INTEGER;
BEGIN
    IF pi_item_ids IS NOT NULL AND instr(pi_item_ids,',') = 0
    THEN
       BEGIN
         SELECT count(*)
         INTO l_count
         FROM blc_items
         WHERE item_id = to_number(pi_item_ids)
         AND item_type = 'POLICY';
       EXCEPTION
          WHEN OTHERS THEN
             l_count := NULL;
       END;
    END IF;

    IF l_count = 1
    THEN
       RETURN 'Y';
    ELSE
       RETURN 'N';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
END Is_Item_Policy;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mass_Delete_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   29.08.2017  creation
--     Fadata   13.06.2018  changed - add parameter pi_rev_reason in
--                          Lock_Doc_For_Delete - LPV-1654
--
-- Purpose:  Execute procedure for delete all unpaid and without AD number
-- proformas related to given parameters
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pi_agreement           VARCHAR2     Item agreement
--     pi_protocol            VARCHAR2     Protocol number
--     pi_lock_flag           VARCHAR2     Call integration for lock for delete
--     pi_item_ids            VARCHAR2     Item Ids
--     pi_master_policy_no    VARCHAR2     Master policy no
--     pi_delete_reason       VARCHAR2     Delete reason
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to delete all unpaid documents before transfer installments
-- for an adjustment to be able to compensate some installments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mass_Delete_Proforma
   (pi_policy_id         IN     NUMBER,
    pi_annex_id          IN     NUMBER,
    pi_agreement         IN     VARCHAR2,
    pi_protocol          IN     VARCHAR2,
    pi_lock_flag         IN     VARCHAR2,
    pi_item_ids          IN     VARCHAR2,
    pi_master_policy_no  IN     VARCHAR2,
    pi_delete_reason     IN     VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_agreement           VARCHAR2(50);
    l_doc_ids             VARCHAR2(4000);
    l_count               SIMPLE_INTEGER := 0;
    l_count_d             SIMPLE_INTEGER := 0;
    l_procedure_result    VARCHAR2(30);
    l_doc_status          VARCHAR2(1);
    l_SrvErr              SrvErr;
    l_item                blc_items_type;
    l_item_id             NUMBER;
    l_delete_reason       VARCHAR2(30) := '4';
    l_rev_reason          NUMBER;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Mass_Delete_Proforma';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Mass_Delete_Proforma');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_policy_id = '||pi_policy_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_annex_id = '||pi_annex_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_agreement = '||pi_agreement);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_protocol = '||pi_protocol);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_lock_flag = '||pi_lock_flag);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_item_ids = '||pi_item_ids);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_master_policy_no = '||pi_master_policy_no);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_delete_reason = '||pi_delete_reason);

    IF pi_policy_id IS NOT NULL
    THEN
       IF Is_Not_Pay_Annex(pi_policy_id, pi_annex_id) = 'Y'
       THEN
          l_agreement := Get_Item_Agreement(pi_policy_id, NULL, NULL);
          l_delete_reason := '70';
       END IF;
    ELSIF pi_item_ids IS NOT NULL
    THEN
       IF Is_Item_Policy(pi_item_ids) = 'Y' AND nvl(pi_annex_id,0) <> 0
       THEN
          l_item_id := TO_NUMBER(pi_item_ids);
          l_item := NEW blc_items_type(l_item_id, l_SrvErr);

          IF Is_Not_Pay_Annex(TO_NUMBER(l_item.component), pi_annex_id) = 'Y'
          THEN
             l_agreement := l_item.agreement;
             l_delete_reason := '70';
          END IF;
       END IF;
    ELSE
       l_agreement := pi_agreement;
    END IF;

    IF l_agreement IS NOT NULL
    THEN
       FOR c_doc IN (SELECT bd.doc_id, bd.amount, bd.status
                     FROM blc_items bi,
                          blc_transactions bt,
                          blc_documents bd
                     WHERE bi.agreement = l_agreement
                     AND bi.item_type = 'POLICY'
                     AND bi.item_id = bt.item_id
                     AND bt.status NOT IN ('C','R','D')
                     AND bt.doc_id = bd.doc_id
                     AND bd.status IN ('A','F')
                     AND bd.doc_class = 'B' -- add to not delete notification documents
                     AND bd.doc_suffix IS NULL
                     AND (pi_protocol IS NULL OR bd.doc_prefix = pi_protocol)
                     GROUP BY bd.doc_id, bd.amount, bd.status
                     ORDER BY bd.amount)
       LOOP
           blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                      'c_doc.doc_id = '||c_doc.doc_id);

           l_doc_ids := Calculate_Referred_Doc(c_doc.doc_id,l_agreement);

           IF l_doc_ids IS NOT NULL
           THEN
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'The document is referred from doc_id(s): '||l_doc_ids);
              CONTINUE;
           END IF;

           Unapply_Net_Appl_Document( pi_doc_id => c_doc.doc_id,
                                      pio_Err   => l_SrvErr );

           --
           SELECT count(*)
           INTO l_count
           FROM blc_transactions bt,
                blc_applications ba
           WHERE bt.doc_id = c_doc.doc_id
           AND ba.target_trx = bt.transaction_id
           AND ba.reversed_appl IS NULL
           AND NOT EXISTS (SELECT 'REVERSE'
                           FROM blc_applications ba1
                           WHERE ba1.reversed_appl = ba.application_id);

           IF l_count = 0
           THEN
              SELECT count(*)
              INTO l_count
              FROM blc_transactions bt,
                   blc_applications ba
              WHERE bt.doc_id = c_doc.doc_id
              AND ba.source_trx = bt.transaction_id
              AND ba.reversed_appl IS NULL
              AND NOT EXISTS (SELECT 'REVERSE'
                              FROM blc_applications ba1
                              WHERE ba1.reversed_appl = ba.application_id);
           END IF;

           IF l_count > 0
           THEN
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'There are not reversed applications');
              CONTINUE;
           END IF;

           --IF l_doc_status = 'F' AND pi_lock_flag = 'Y' --LPVS-111 replace with the next row because l_doc_status is empty
           IF c_doc.status = 'F' AND pi_lock_flag = 'Y'
           THEN
              --IP - need to call service for lock document in SAP
              cust_intrf_util_pkg.Lock_Doc_For_Delete
                                (pi_doc_id            => c_doc.doc_id,
                                 pi_rev_reason        => l_delete_reason, --LPV-1654
                                 po_procedure_result  => l_procedure_result,
                                 pio_Err              => pio_Err);

              IF l_procedure_result = cust_gvar.FLG_ERROR
              THEN
                 IF NOT srv_error.rqStatus( pio_Err )
                 THEN
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_EXCEPTION,
                                               'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                 ELSE
                    srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mass_Delete_Proforma', 'cust_billing_pkg.PRP.IP_Error');
                    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_EXCEPTION,
                                               'c_doc.doc_id = '||c_doc.doc_id||' - '||'Integration for lock document for deletion in SAP return error');
                 END IF;
                 --
                 RETURN;
              END IF;
           END IF;

           l_procedure_result := NULL;

           blc_doc_process_pkg.Set_Unformal_Document
                  (pi_doc_id             => c_doc.doc_id,
                   pi_action_notes       => NULL,
                   pio_procedure_result  => l_procedure_result,
                   po_doc_status         => l_doc_status,
                   pio_Err               => pio_Err);

           IF l_doc_status = 'A'
           THEN
               blc_doc_process_pkg.Delete_Document
                    (pi_doc_id             => c_doc.doc_id,
                     pi_action_notes       => nvl(pi_delete_reason,srv_error.GetSrvMessage('cust_billing_pkg.MDP.MassDelete')||': '||pi_policy_id||'/'||pi_annex_id||'/'||l_agreement||'/'||pi_protocol),
                     pio_procedure_result  => l_procedure_result,
                     po_doc_status         => l_doc_status,
                     pio_Err               => pio_Err);

               IF l_procedure_result = cust_gvar.FLG_ERROR
               THEN
                  IF NOT srv_error.rqStatus( pio_Err )
                  THEN
                     blc_log_pkg.insert_message(l_log_module,
                                                C_LEVEL_EXCEPTION,
                                                'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                  END IF;

                  RETURN;
              END IF;
              --
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'Document is deleted');
              --
              Set_Doc_Delete_Reason
                 (pi_doc_id            => c_doc.doc_id,
                  pi_delete_reason     => l_delete_reason,
                  pio_Err              => pio_Err);

               IF NOT srv_error.rqStatus( pio_Err )
               THEN
                  blc_log_pkg.insert_message(l_log_module,
                                             C_LEVEL_EXCEPTION,
                                             'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                  RETURN;
               END IF;

              l_count_d := l_count_d + 1;
           END IF;
       END LOOP;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'Number of deleted documents '||l_count_d);

       --IF l_count_d > 0 --do compensation indepent of count of deleted documents
       --THEN
          --compensate installments;
          FOR c_item IN (SELECT bi.item_id
                         FROM blc_items bi
                         WHERE bi.agreement = l_agreement
                         AND bi.item_type = 'POLICY')
          LOOP
             --LPVS-111 call optimized compensation
             /*
             blc_pas_transfer_installs_pkg.Compensate_Item_Installments
                               (pi_item_id   =>  c_item.item_id,
                                pioErr       =>  pio_Err);
             */
             Comp_Item_Installments_Norm
                               (pi_item_id   =>  c_item.item_id,
                                pio_Err      =>  pio_Err);

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'c_item.item_id = '||c_item.item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                RETURN;
             END IF;
          END LOOP;
       --END IF;
    ELSIF pi_master_policy_no IS NOT NULL
    THEN
       FOR c_doc IN (SELECT bd.doc_id, bd.amount, bd.status
                     FROM blc_items bi,
                          blc_transactions bt,
                          blc_documents bd
                     WHERE bi.attrib_1 = pi_master_policy_no
                     AND bi.item_type = 'POLICY'
                     AND bi.attrib_7 IN ('CLIENT_GROUP', 'CLIENT_IND_DEPEND', 'CLIENT_IND')
                     AND bi.item_id = bt.item_id
                     AND bt.status NOT IN ('C','R','D')
                     AND bt.doc_id = bd.doc_id
                     AND bd.status IN ('A','F')
                     AND bd.doc_suffix IS NULL
                     AND (pi_protocol IS NULL OR bd.doc_prefix = pi_protocol)
                     GROUP BY bd.doc_id, bd.amount, bd.status
                     ORDER BY bd.amount)
       LOOP
           blc_log_pkg.insert_message(l_log_module,
                                      C_LEVEL_STATEMENT,
                                      'c_doc.doc_id = '||c_doc.doc_id);

           l_doc_ids := Calculate_Referred_Doc(c_doc.doc_id,l_agreement);

           IF l_doc_ids IS NOT NULL
           THEN
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'The document is referred from doc_id(s): '||l_doc_ids);
              CONTINUE;
           END IF;

           Unapply_Net_Appl_Document( pi_doc_id => c_doc.doc_id,
                                      pio_Err   => l_SrvErr );

           --
           SELECT count(*)
           INTO l_count
           FROM blc_transactions bt,
                blc_applications ba
           WHERE bt.doc_id = c_doc.doc_id
           AND ba.target_trx = bt.transaction_id
           AND ba.reversed_appl IS NULL
           AND NOT EXISTS (SELECT 'REVERSE'
                           FROM blc_applications ba1
                           WHERE ba1.reversed_appl = ba.application_id);

           IF l_count = 0
           THEN
              SELECT count(*)
              INTO l_count
              FROM blc_transactions bt,
                   blc_applications ba
              WHERE bt.doc_id = c_doc.doc_id
              AND ba.source_trx = bt.transaction_id
              AND ba.reversed_appl IS NULL
              AND NOT EXISTS (SELECT 'REVERSE'
                              FROM blc_applications ba1
                              WHERE ba1.reversed_appl = ba.application_id);
           END IF;

           IF l_count > 0
           THEN
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'There are not reversed applications');
              CONTINUE;
           END IF;

           --IF l_doc_status = 'F' AND pi_lock_flag = 'Y' --LPVS-111 replace with the next row because l_doc_status is empty
           IF c_doc.status = 'F' AND pi_lock_flag = 'Y'
           THEN
              --IP - need to call service for lock document in SAP
              cust_intrf_util_pkg.Lock_Doc_For_Delete
                                (pi_doc_id            => c_doc.doc_id,
                                 pi_rev_reason        => pi_delete_reason, --LPV-1654
                                 po_procedure_result  => l_procedure_result,
                                 pio_Err              => pio_Err);

              IF l_procedure_result = cust_gvar.FLG_ERROR
              THEN
                 IF NOT srv_error.rqStatus( pio_Err )
                 THEN
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_EXCEPTION,
                                               'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                 ELSE
                    srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mass_Delete_Proforma', 'cust_billing_pkg.PRP.IP_Error');
                    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_EXCEPTION,
                                               'c_doc.doc_id = '||c_doc.doc_id||' - '||'Integration for lock document for deletion in SAP return error');
                 END IF;
                 --
                 RETURN;
              END IF;
           END IF;

           l_procedure_result := NULL;

           blc_doc_process_pkg.Set_Unformal_Document
                  (pi_doc_id             => c_doc.doc_id,
                   pi_action_notes       => NULL,
                   pio_procedure_result  => l_procedure_result,
                   po_doc_status         => l_doc_status,
                   pio_Err               => pio_Err);

           IF l_doc_status = 'A'
           THEN
               blc_doc_process_pkg.Delete_Document
                    (pi_doc_id             => c_doc.doc_id,
                     pi_action_notes       => pi_delete_reason,
                     pio_procedure_result  => l_procedure_result,
                     po_doc_status         => l_doc_status,
                     pio_Err               => pio_Err);

               IF l_procedure_result = cust_gvar.FLG_ERROR
               THEN
                  IF NOT srv_error.rqStatus( pio_Err )
                  THEN
                     blc_log_pkg.insert_message(l_log_module,
                                                C_LEVEL_EXCEPTION,
                                                'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                  END IF;

                  RETURN;
              END IF;
              --
              blc_log_pkg.insert_message(l_log_module,
                                         C_LEVEL_STATEMENT,
                                         'Document is deleted');

              --LPV-1654 - 13.06.2018 set action.attrib_0 with value of pi_delete_reason when it is number (reverse reason code)
              BEGIN
                 l_rev_reason := TO_NUMBER(pi_delete_reason);
              EXCEPTION
                 WHEN OTHERS THEN
                   l_rev_reason := NULL;
              END;

              IF l_rev_reason IS NOT NULL
              THEN
                 l_delete_reason := TO_CHAR(l_rev_reason);
              END IF;
              --

              Set_Doc_Delete_Reason
                 (pi_doc_id            => c_doc.doc_id,
                  pi_delete_reason     => l_delete_reason,
                  pio_Err              => pio_Err);

              IF NOT srv_error.rqStatus( pio_Err )
              THEN
                 blc_log_pkg.insert_message(l_log_module,
                                            C_LEVEL_EXCEPTION,
                                            'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                 RETURN;
              END IF;

              l_count_d := l_count_d + 1;
           END IF;
       END LOOP;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'Number of deleted documents '||l_count_d);

       --IF l_count_d > 0 --do compensation indepent of count of deleted documents
       --THEN
          --compensate installments;
          FOR c_item IN (SELECT bi.item_id
                         FROM blc_items bi
                         WHERE bi.attrib_1 = pi_master_policy_no
                         AND bi.item_type = 'POLICY'
                         AND bi.attrib_7 IN ('CLIENT_GROUP', 'CLIENT_IND_DEPEND', 'CLIENT_IND'))
          LOOP
             --LPVS-111 call optimized compensation
             /*
             blc_pas_transfer_installs_pkg.Compensate_Item_Installments
                               (pi_item_id   =>  c_item.item_id,
                                pioErr       =>  pio_Err);
             */
             Comp_Item_Installments_Norm
                               (pi_item_id   =>  c_item.item_id,
                                pio_Err      =>  pio_Err);
             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_EXCEPTION,
                                           'c_item.item_id = '||c_item.item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                RETURN;
             END IF;
          END LOOP;
       --END IF;
    END IF;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Mass_Delete_Proforma');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mass_Delete_Proforma', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_policy_id = '||pi_policy_id||' - '||SQLERRM);
END Mass_Delete_Proforma;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calc_Policy_Protocol_Attr
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   19.10.2017  creation
--     Fadata   11.09.2018  LPV-1768 return protocol number only for
--                          insr_type in (2003, 2002, 2005)
--     Fadata   02.03.2020  CHA93S-30 add products for phase 2
--
-- Purpose: Calculate policy protocol related attributes
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_protocol_flag       VARCHAR2     Protocol flag
--     po_protocol_number     VARCHAR2     Protocol number
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In create, update blc item
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Calc_Policy_Protocol_Attr
    ( pi_policy_id       IN     NUMBER,
      po_protocol_flag   OUT    VARCHAR2,
      po_protocol_number OUT    VARCHAR2,
      pio_Err            IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_count               PLS_INTEGER;
    l_insr_type           POLICY.insr_type%TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Calc_Policy_Protocol_Attr';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Calc_Policy_Protocol_Attr');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_policy_id = '||pi_policy_id);
    --LPV-1768
    BEGIN
       SELECT insr_type
       INTO l_insr_type
       FROM POLICY
       WHERE policy_id = pi_policy_id;
    EXCEPTION
      WHEN OTHERS THEN
        l_insr_type := NULL;
    END;

    --IF l_insr_type IN (2003, 2002, 2005) --LPV-1768
    IF l_insr_type IN (2003, 2002, 2005, 2009, 2010, 2011, 2012, 2013) --CHA93S-30, add products for phase 2
    THEN
       BEGIN
          SELECT quest_answer
          INTO po_protocol_number
          FROM quest_questions
          WHERE policy_id = pi_policy_id
          AND quest_id = 'PROTNUMB'
          AND annex_id = '0';
       EXCEPTION
          WHEN OTHERS THEN
            po_protocol_number := NULL;
       END;
    ELSE
       po_protocol_number := NULL;
    END IF;

    /*
    SELECT COUNT(*)
    INTO l_count
    FROM quest_questions
    WHERE policy_id = pi_policy_id
    AND quest_id = 'EPOLR'
    AND annex_id = '0'
    AND quest_answer = '3';
    */

    --IF l_count > 0
    IF po_protocol_number IS NOT NULL
    THEN
       po_protocol_flag := 'Y';
    ELSE
       po_protocol_flag := 'N';
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_protocol_flag = '||po_protocol_flag);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_protocol_number = '||po_protocol_number);
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Calc_Policy_Protocol_Attr', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_policy_id = '||pi_policy_id||' - '||SQLERRM);
END Calc_Policy_Protocol_Attr;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_SIP_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.10.2017  creation
--
-- Purpose: Check if given annex is for SIP
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for SIP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_SIP_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  --
  CURSOR c_annex IS
    SELECT annex_id
    FROM gen_annex_reason
    WHERE policy_id = pi_policy_id
    AND annex_id = pi_annex_id
    AND annex_reason = 'SIPANNEX';
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      RETURN 'N';
   END IF;

   OPEN c_annex;
     FETCH c_annex
     INTO l_annex_id;
   CLOSE c_annex;

   IF l_annex_id IS NOT NULL
   THEN
      RETURN 'Y';
   ELSE
      RETURN 'N';
   END IF;
END Is_SIP_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Pre_Pay_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.11.2017  creation
--
-- Purpose:  Execute procedure for validation before pay a document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     po_org_id              NUMBER       Organization Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI when need to pay a document
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Pay_Document
   (pi_doc_id            IN     NUMBER,
    po_org_id            OUT    NUMBER,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc                 blc_documents_type;
    l_doc_type            VARCHAR2(30);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Pre_Pay_Document';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Pre_Pay_Document');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);

    l_doc := NEW blc_documents_type(pi_doc_id);

    l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

    IF l_doc_type IN (cust_gvar.DOC_RI_BILL_TYPE,cust_gvar.DOC_CO_BILL_TYPE)
    THEN
       po_org_id := l_doc.org_site_id;
    ELSE
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Pay_Document', 'cust_billing_pkg.MFD.Not_Allowed', l_doc_type);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||'Activity is not allowed for the document type '||l_doc_type);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'po_org_id = '||po_org_id);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Pre_Pay_Document');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Pre_Pay_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Pre_Pay_Document;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Not_Allow_Activity
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
-- Purpose:  Execute procedure for stop ativity for accounting voucher document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     po_action_notes        VARCHAR2     Action notes
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In UI when to stop activity
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Not_Allow_Activity
   (pi_doc_id            IN     NUMBER,
    pio_procedure_result IN OUT VARCHAR2,
    po_action_notes      OUT    VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_doc                 BLC_DOCUMENTS_TYPE;
    l_doc_type            VARCHAR2(30);
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Not_Allow_Activity';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Not_Allow_Activity');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_procedure_result = '||pio_procedure_result);

    l_doc := NEW blc_documents_type(pi_doc_id);

    l_doc_type := blc_common_pkg.get_lookup_code(l_doc.doc_type_id);

    IF l_doc_type = cust_gvar.DOC_ACC_TYPE AND (pio_procedure_result IS NULL OR pio_procedure_result = blc_gvar_process.flg_ok)
    THEN
       srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Not_Allow_Activity', 'cust_billing_pkg.MFD.Not_Allowed', l_doc_type);
       srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_doc_id = '||pi_doc_id||' - '||'Activity is not allowed for the document type '||l_doc_type);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'po_action_notes = '||po_action_notes);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Not_Allow_Activity');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Not_Allow_Activity', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
     pio_procedure_result := blc_gvar_process.flg_err;
END Not_Allow_Activity;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Policy_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   10.12.2017  creation
--
-- Purpose: Return policy type - attr7 from policy_engagement_billing
--
-- Input parameters:
--       pi_policy_id      NUMBER   Policy ID
--       pi_annex_id       NUMBER   Annex ID
--
-- Returns: policy type
--
-- Usage: When need to know policy type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Policy_Type
    ( pi_policy_id   IN NUMBER,
      pi_annex_id    IN NUMBER)
RETURN VARCHAR2
IS
    l_policy_type  VARCHAR2(30);
    --
    CURSOR CgetBillingAnnex (x_policy_id NUMBER, x_annex_id NUMBER) IS
    SELECT attr7
      FROM policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND attr7 IS NOT NULL
     ORDER BY decode(annex_id, x_annex_id, 0, 1), annex_id DESC;
BEGIN
    OPEN CgetBillingAnnex(pi_policy_id, pi_annex_id);
       FETCH CgetBillingAnnex
       INTO l_policy_type;
    CLOSE CgetBillingAnnex;
    --
    RETURN l_policy_type;
EXCEPTION
  WHEN OTHERS THEN
     RETURN NULL;
END Get_Policy_Type;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_PaidUp_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   23.10.2017  creation
--
-- Purpose: Check if given annex is for PiadUp
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for SIP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_PaidUp_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  --
  CURSOR c_annex IS
    SELECT annex_id
    FROM gen_annex_reason
    WHERE policy_id = pi_policy_id
    AND annex_id = pi_annex_id
    AND annex_reason IN ('PAIDUP','PAIDUPREV'); --06.02.2018 --add PAIDUPREV
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      RETURN 'N';
   END IF;

   OPEN c_annex;
     FETCH c_annex
     INTO l_annex_id;
   CLOSE c_annex;

   IF l_annex_id IS NOT NULL
   THEN
      RETURN 'Y';
   ELSE
      RETURN 'N';
   END IF;
END Is_PaidUp_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Set_Doc_Delete_Reason
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.01.2018  creation
--
-- Purpose:  Execute procedure for set delete reason code in delete action
-- attrib_0 for given deleted document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_delete_reason       VARCHAR2     Delete reason code
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: When need to set delete reason code in delete document action
--
-- Exceptions:
--    1) Update document action is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Set_Doc_Delete_Reason
   (pi_doc_id            IN     NUMBER,
    pi_delete_reason     IN     VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_act                 blc_actions_type;
    l_action_id           NUMBER;
    --
    CURSOR c_act IS
      SELECT ba.action_id
      FROM blc_actions ba,
           blc_lookups bla
      WHERE ba.document_id = pi_doc_id
      AND ba.action_type_id = bla.lookup_id
      AND bla.lookup_code = 'DELETE'
      ORDER BY ba.action_id DESC;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Set_Doc_Delete_Reason';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Set_Doc_Delete_Reason');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_doc_id = '||pi_doc_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_delete_reason = '||pi_delete_reason);

    OPEN c_act;
      FETCH c_act
      INTO l_action_id;
    CLOSE c_act;

    IF l_action_id IS NOT NULL
    THEN
       l_act := blc_actions_type(l_action_id);

       l_act.attrib_0 := pi_delete_reason;

       IF NOT l_act.update_blc_actions ( pio_Err )
       THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                    'pi_doc_id = '||pi_doc_id||' - '||
                                     pio_Err(pio_Err.FIRST).errmessage);
          RETURN;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Set_Doc_Delete_Reason');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Set_Doc_Delete_Reason', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);

END Set_Doc_Delete_Reason;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calc_Policy_Pay_Way
--
-- Type: PROCEDURE
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   13.09.2018  creation - LPV-1768 get pay way and pay instrument
--                          for policy item with select from
--                          policy_engagement_billing and avoid call of event
--                          GET_PAY_INSTR
--     Fadata  16.12.2020   creation - CON94S-55 - add TRUNC of valid from/to
--                          dates and check that record is active - valid from
--                          have to be smaller or equal to valid_to
--
-- Purpose: Get pay way and pay instrument
--
-- Input parameters:
--     pi_item_id         NUMBER         Item Id (required)
--     pi_org_id          NUMBER         Organization identifier (required)
--     pi_to_date         DATE           Date for wich get value (required)
--
-- Output parameters:
--     po_pay_way_id      NUMBER         Pay way Id (BLC lookup_id)
--     po_pay_instr_id    NUMBER         Pay instrument id
--                                       (BLC pay instrument_id)
--     pio_Err            SrvErr         Specifies structure for passing back
--                                       the error code, error TYPE and
--                                       corresponding message.
--
-- Usage: When need to know policy pay way and pay instrument
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Calc_Policy_Pay_Way
   (pi_item_id           IN     NUMBER,
    pi_org_id            IN     NUMBER,
    pi_to_date           IN     DATE,
    po_pay_way_id        OUT    NUMBER,
    po_pay_instr_id      OUT    NUMBER,
    pio_Err              IN OUT SrvErr)
IS
    l_item                BLC_ITEMS_TYPE;
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_policy_id           POLICY.policy_id%TYPE;
    l_pay_way             policy_engagement_billing.payment_way%TYPE;
    l_pay_instr           policy_engagement_billing.attr10%TYPE;
    l_pay_way_lookup      blc_lookups.lookup_code%TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Calc_Policy_Pay_Way';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Calc_Policy_Pay_Way');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_item_id = '||pi_item_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_org_id = '||pi_org_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_to_date = '||to_char(pi_to_date,'DD-MM-YYYY'));

    IF pi_item_id IS NOT NULL
    THEN
       l_item := NEW blc_items_type(pi_item_id, pio_Err);
       --
       IF l_item.item_type = 'POLICY'
       THEN
          l_policy_id := l_item.component;

          BEGIN
            SELECT payment_way, attr10
            INTO l_pay_way, l_pay_instr
            FROM policy_engagement_billing
            WHERE policy_id = l_policy_id
            AND pi_to_date BETWEEN TRUNC(valid_from) AND NVL(TRUNC(valid_to),pi_to_date)
            AND valid_from <= valid_to
            ORDER BY valid_from DESC
            FETCH FIRST ROW ONLY;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                SELECT payment_way, attr10
                INTO l_pay_way, l_pay_instr
                FROM policy_engagement_billing
                WHERE policy_id = l_policy_id
                AND valid_from <= valid_to
                ORDER BY valid_from DESC
                FETCH FIRST ROW ONLY;
              EXCEPTION
                WHEN OTHERS THEN
                  l_pay_way := NULL;
              END;
          END;

          IF l_pay_way IS NOT NULL
          THEN
             l_pay_way_lookup := blc_billing_pkg.Get_Pay_Way_In(l_pay_way, pi_org_id, pi_to_date);

             IF l_pay_way_lookup IS NOT NULL
             THEN
                po_pay_way_id := blc_common_pkg.Get_Lookup_Value_Id('PAY_WAY_IN', l_pay_way_lookup, pio_Err, pi_org_id, pi_to_date);
                po_pay_instr_id := l_pay_instr;
             END IF;

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message( 'cust_billing_pkg.Calc_Policy_Pay_Way', C_LEVEL_EXCEPTION,
                                            'pi_item_id = '||pi_item_id||' - '||
                                            'pi_org_id = '||pi_org_id||' - '||
                                            'pi_to_date = '||TO_CHAR(pi_to_date,'DD-MM-YYYY')||' - '|| pio_Err(pio_Err.FIRST).errmessage);
             END IF;
          END IF;
      END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_pay_way_id = '||po_pay_way_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'po_pay_instr_id = '||po_pay_instr_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Calc_Policy_Pay_Way');

EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Calc_Policy_Pay_Way', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_item_id = '||pi_item_id||' - '||SQLERRM);
END Calc_Policy_Pay_Way;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Auto_Approve_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   14.09.2018  creation - LPV-1768 copy from core and remove call
--                          of the rule
--     Fadata   02.03.2020  CHA93S-30 add special logic for products for phase 2
--
-- Purpose: Check rule Autoapproval ability and if Yes execute procedure of
-- change status to Approve for document in status Validated
-- Actions:
--     1) Check rule Autoapproval
--     2) Update document status
--     3) Insert action approve
--     4) Create accounting events for transactions into document
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pi_action_notes        VARCHAR2     Action notes
--     pi_doc_class           VARCHAR2     Document class
--     pi_doc_type            VARCHAR2     Document type
--     pi_trx_type            VARCHAR2     Transaction type
--     pi_postprocess         VARCHAR2     Installment postprocess
--     pi_run_id              NUMBER       Billing run id
--     pi_norm_interpret      VARCHAR2     Norm interpret setting
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_doc_status         VARCHAR2     Old document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_doc_status         VARCHAR2     New document status
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: In billing process when need to approve document
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--    2) Update document is failed
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Auto_Approve_Document
   (pi_doc_id             IN     NUMBER,
    pi_action_notes       IN     VARCHAR2,
    pi_doc_class          IN     VARCHAR2,
    pi_doc_type           IN     VARCHAR2,
    pi_trx_type           IN     VARCHAR2,
    pi_postprocess        IN     VARCHAR2,
    pi_run_id             IN     NUMBER,
    pi_norm_interpret     IN     VARCHAR2,
    pio_procedure_result  IN OUT VARCHAR2,
    pio_doc_status        IN OUT VARCHAR2,
    pio_Err               IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    /*
    l_SrvErr              SrvErr;
    l_rule_id             NUMBER;
    l_Context             SrvContext;
    l_OutContext          SrvContext;
    */
    l_approval_flag       VARCHAR2(30);
    l_doc                 BLC_DOCUMENTS_TYPE;
    l_run                 BLC_RUN_TYPE;
    --
    l_policy_type         p_policy_type;
    l_count               SIMPLE_INTEGER := 0;
BEGIN
   blc_log_pkg.initialize(pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   l_log_module := C_DEFAULT_MODULE||'.Auto_Approve_Document';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Auto_Approve_Document');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_action_notes = '||pi_action_notes);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_class = '||pi_doc_class);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_type = '||pi_doc_type);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_trx_type = '||pi_trx_type);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_postprocess = '||pi_postprocess);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_run_id = '||pi_run_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_norm_interpret = '||pi_norm_interpret);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_doc_status = '||pio_doc_status);


   IF pio_doc_status = 'V'
   THEN
      /*
      l_rule_id := NULL;
      srv_prm_process.Set_Doc_Id( l_Context, pi_doc_id );
      Srv_Context.SetContextAttrChar  ( l_Context, 'RULE_CODE', 'BLC_BILL_DOC_AUTOAPPROVAL' );
      rb_srv.GetRuleIdByCode( l_Context, l_OutContext, pio_Err );
      --
      IF srv_error.rqStatus( pio_Err )
      THEN
         srv_context.GetContextAttrNumber( l_OutContext, 'RULE_ID', l_rule_id );
         Srv_Context.SetContextAttrNumber( l_Context, 'RULE_ID', srv_context.Integers_Format, l_rule_id );
      END IF;

      srv_prm_process.Set_Doc_Class( l_Context, pi_doc_class );
      srv_prm_process.Set_Doc_Type( l_Context, pi_doc_type );
      srv_prm_process.Set_Trx_Type( l_Context, pi_trx_type );
      srv_prm_process.Set_Doc_Postprocess( l_Context, pi_postprocess );
      srv_prm_process.Set_Doc_Run_Id( l_Context, pi_run_id );
      srv_prm_process.Set_Norm_Interpret( l_Context, pi_norm_interpret );

      RB_SRV.RuleRequest ('BLC_BILL_DOC_AUTOAPPROVAL',
                          l_Context ,
                          l_OutContext ,
                          pio_Err  );
      --
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_EXCEPTION,
                                    'pi_doc_id = '||pi_doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
         RETURN;
      END IF;
      --
      srv_context.GetContextAttrChar( l_OutContext, 'RULE_VALUE', l_approval_flag );
      */

      BEGIN
         l_doc := NEW blc_documents_type(pi_doc_id);
      EXCEPTION
         WHEN OTHERS THEN
            srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Auto_Approve_Document', 'GetBLCDocument_No_Doc_id' );
            srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_EXCEPTION,
                                       'pi_doc_id = '||pi_doc_id||' - '||'Invalid document Id');
            RETURN;
      END;

      l_approval_flag := blc_gvar_process.FLG_YES;

      --07.07.2020 - change always to check bill method
      IF l_doc.run_id IS NOT NULL
      THEN
         l_run := blc_run_type(l_doc.run_id, pio_Err);
      END IF;

      --LAP85-132
      IF l_run.run_mode = 'E' --add case for extra billing
          AND blc_common_pkg.Get_Lookup_Code(l_doc.doc_type_id) IN ( 'PROFORMA','REFUND-CN' )  -- LAP85-132  03.12.2021
      THEN
         l_approval_flag := blc_gvar_process.FLG_NO;
      ELSIF l_doc.attrib_7 = 'CLIENT_GROUP' AND blc_common_pkg.Get_Lookup_Code(l_run.bill_method_id) = 'PROTOCOL'
      THEN
         --CHA93S-30
         l_policy_type := pol_types.Get_Policy_By_PolNo ( l_doc.attrib_6, pio_err );
         IF l_policy_type.insr_type IN (2012, 2013)
         THEN
            l_approval_flag := blc_gvar_process.FLG_NO;
         ELSIF l_policy_type.insr_type = 2011
         THEN
            SELECT count(*)
            INTO l_count
            FROM policy_conditions
            WHERE policy_id = l_policy_type.policy_id
            AND cond_type = 'AS_IS_VIDAGR'
            AND cond_dimension = '7';
            --
            IF l_count = 0
            THEN
               l_approval_flag := blc_gvar_process.FLG_NO;
            ELSE
               l_approval_flag := blc_gvar_process.FLG_YES;
            END IF;
         ELSIF l_policy_type.insr_type IN (2009, 2010)
         THEN
            l_approval_flag := blc_gvar_process.FLG_YES;
         ELSE --product for Phase I
            l_approval_flag := blc_gvar_process.FLG_NO;
         END IF;
      END IF;

      IF l_approval_flag = blc_gvar_process.FLG_YES
      THEN
         blc_doc_process_pkg.Approve_Document
               (pi_doc_id             => pi_doc_id,
                pi_action_notes       => pi_action_notes,
                pio_procedure_result  => pio_procedure_result,
                po_doc_status         => pio_doc_status,
                pio_Err               => pio_Err);
      END IF;
   END IF;
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_procedure_result = '||pio_procedure_result);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pio_doc_status = '||pio_doc_status);

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Auto_Approve_Document');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Auto_Approve_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
     pio_procedure_result := blc_gvar_process.flg_err;
END Auto_Approve_Document;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calculate_Bill_Grouping
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   04.12.2018  creation - LPVS-14
--     Fadata   27.01.2021  changed -  LAP85-94, CSR227
--
-- Purpose: Calculate transaction grouping
--
-- Input parameters:
--     pi_attrib_6        VARCHAR    Transaction attrib_6 - begin bill period
--     pi_attrib_7        VARCHAR    Transaction attrib_7 - end bill period
--     pi_item_type       VARCHAR2   Item type
--     pi_policy_type     VARCHAR2   Policy type - item.attrib_7
--     pi_run_id          NUMBER     Run identifier
--
-- Returns:
--     groupin value
--
-- Usage: In run billing to calculate transaction grouping value
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calculate_Bill_Grouping
   (pi_attrib_6    IN     VARCHAR2,
    pi_attrib_7    IN     VARCHAR2,
    pi_item_type   IN     VARCHAR2,
    pi_policy_type IN     VARCHAR2,
    pi_run_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_blc_run         blc_run_type;
  l_SrvErr          SrvErr;
  l_group_value     VARCHAR2(240) := '-999';
BEGIN
   IF pi_item_type = 'POLICY' AND  pi_policy_type IN ('CLIENT_IND','CLIENT_IND_DEPEND','REGULAR','GENERIC') AND pi_run_id IS NOT NULL --add GENERIC 13.08.2019
   THEN
      l_blc_run := NEW blc_run_type(pi_run_id, l_SrvErr);

      IF l_blc_run.run_mode IN ('I','R')
      THEN
         --l_group_value := pi_attrib_7;--LAP85-94 ,LPV CSR227
         l_group_value := pi_attrib_6||pi_attrib_7;--LAP85-94 ,LPV CSR227
      END IF;

   END IF;

   RETURN l_group_value;
END Calculate_Bill_Grouping;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Manual_Canc_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Check if given annex is manual cancellation or paidup
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for manula cancellation or paidup
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Manual_Canc_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  l_value       VARCHAR2(1);
  l_count       PLS_INTEGER;
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      l_value := 'N';
   ELSE
       SELECT count(*)
       INTO l_count
       FROM gen_annex_reason ar
       WHERE ar.policy_id = pi_policy_id
       AND ar.annex_id = pi_annex_id
       AND ((ar.annex_type = '17' AND NVL(ar.annex_reason,'-999') <> 'CANCLAPS')
            OR
            (ar.annex_type = '12' AND ar.annex_reason = 'PAIDUP'
             AND EXISTS (SELECT 'MANUAL'
                         FROM gen_annex_reason arr
                         WHERE arr.policy_id = ar.policy_id
                         AND arr.annex_id = ar.annex_id
                         AND arr.annex_reason = 'MANUAL')));

      IF l_count > 0
      THEN
         l_value := 'Y';
      ELSE
         l_value := 'N';
      END IF;
   END IF;

   RETURN l_value;
END Is_Manual_Canc_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Annex_Reverse
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Check if given annex is reversed
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is reversed
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Annex_Reverse
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_value       VARCHAR2(1);
  l_count       PLS_INTEGER;
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      l_value := 'N';
   ELSE
      SELECT count(*)
      INTO l_count
      FROM gen_annex A
      WHERE A.policy_id = pi_policy_id
      AND A.annex_id = pi_annex_id
      AND A.annex_state IN (0,11,12);

      IF l_count > 0
      THEN
         l_value := 'N';
      ELSE
         l_value := 'Y';
      END IF;
   END IF;

   RETURN l_value;
END Is_Annex_Reverse;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Comp_Tolerance_USD
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.06.2019  creation - LPVS-111
--
-- Purpose: Get value for setting 'CustCompToleranceUSD'
-- for global variables legal entity and oper_date set after execution if
-- Init legal entity
--
-- Returns:
--     tolerance
--
-- Usage: In installments compensation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Comp_Tolerance_USD
RETURN NUMBER
IS
    l_value   blc_values.number_value%TYPE;
    l_ErrMsg  SrvErr;
    l_log_module    VARCHAR2(240);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Comp_Tolerance_USD';

   l_value := blc_common_pkg.Get_Setting_Number_Value
                         ( 'CustCompToleranceUSD',
                           l_ErrMsg,
                           blc_appl_cache_pkg.g_legal_entity_id,
                           blc_appl_cache_pkg.g_to_date);

   l_value := nvl(l_value, 0);

   RETURN l_value;
END Get_Comp_Tolerance_USD;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Comp_Tolerance_PEN
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   11.06.2019  creation - LPVS-111
--
-- Purpose: Get value for setting 'CustCompTolerancePEN'
-- for global variables legal entity and oper_date set after execution if
-- Init legal entity
--
-- Returns:
--     tolerance
--
-- Usage: In installments compensation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Comp_Tolerance_PEN
RETURN NUMBER
IS
    l_value   blc_values.number_value%TYPE;
    l_ErrMsg  SrvErr;
    l_log_module    VARCHAR2(240);
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Get_Comp_Tolerance_PEN';

   l_value := blc_common_pkg.Get_Setting_Number_Value
                         ( 'CustCompTolerancePEN',
                           l_ErrMsg,
                           blc_appl_cache_pkg.g_legal_entity_id,
                           blc_appl_cache_pkg.g_to_date);

   l_value := nvl(l_value, 0);

   RETURN l_value;
END Get_Comp_Tolerance_PEN;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Comp_Item_Installments_Spec
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--     Fadata  31.07.2010 creation - LPV-2000 -- add comparing by attrib_0
--
-- Purpose: Compensate installments for given item id by bill period specified
-- in attrib_4(begin date) and attrib_5(end date) of instalments if absolute
-- value of total amount for period is less than given tolerance
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pi_annex_id          NUMBER     Annex id
--     pi_tolerance_usd     NUMBER     Tolerance for USD
--     pi_tolerance_pen     NUMBER     Tolerance for PEN
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for policy cancellation annex
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Comp_Item_Installments_Spec( pi_item_id       IN NUMBER,
                                       pi_annex_id      IN NUMBER,
                                       pi_tolerance_usd IN NUMBER,
                                       pi_tolerance_pen IN NUMBER,
                                       pio_Err          IN OUT SrvErr )
IS
    l_log_module         VARCHAR2(240);
    l_SrvErrMsg          SrvErrMsg;
    --
    CURSOR c_inst IS
      SELECT bi.installment_id
      FROM blc_installments bi
      WHERE bi.item_id = pi_item_id
      AND bi.compensated = blc_gvar_process.FLG_NO
      AND bi.billing_run_id IS NULL
      AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
      AND bi.amount <> 0
      FOR UPDATE OF bi.compensated;
    --
    l_inst BLC_INSTALLMENTS_TYPE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    --
    l_log_module := C_DEFAULT_MODULE||'.Comp_Item_Installments_Spec';
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'BEGIN of procedure '|| l_log_module);
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_item_id = '||pi_item_id );
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_annex_id = '||pi_annex_id );
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_tolerance_usd = '||pi_tolerance_usd );
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_tolerance_pen = '||pi_tolerance_pen );

    OPEN c_inst;
    CLOSE c_inst;

    FOR c_inst_gr IN (SELECT A.begin_date,
                             A.end_date,
                             A.currency,
                             SUM(A.group_amount) period_amount
                      FROM (SELECT bi.account_id,
                                   bi.currency,
                                   bi.installment_type,
                                   bi.attrib_4 begin_date,
                                   bi.attrib_5 end_date,
                                   bi.LOB,
                                   bi.fraction_type,
                                   bi.attrib_0,
                                   SUM(bi.amount) group_amount
                            FROM blc_installments bi
                            WHERE bi.item_id = pi_item_id
                            AND bi.compensated = blc_gvar_process.FLG_NO
                            AND bi.billing_run_id IS NULL
                            AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
                            GROUP BY bi.account_id,
                                   bi.currency,
                                   bi.installment_type,
                                   bi.attrib_4,
                                   bi.attrib_5,
                                   bi.LOB,
                                   bi.fraction_type,
                                   bi.attrib_0) A
                      GROUP BY A.begin_date,
                               A.end_date,
                               A.currency
                      HAVING ABS(SUM(A.group_amount)) <= DECODE(A.currency,'USD', pi_tolerance_usd, pi_tolerance_pen)
                      ORDER BY A.begin_date)
    LOOP
       blc_log_pkg.insert_message( l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'c_inst_gr.begin_date = '||c_inst_gr.begin_date );
       blc_log_pkg.insert_message( l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'c_inst_gr.currency = '||c_inst_gr.currency );
       blc_log_pkg.insert_message( l_log_module,
                                   C_LEVEL_STATEMENT,
                                   'c_inst_gr.period_amount = '||c_inst_gr.period_amount );

       IF c_inst_gr.period_amount <> 0
       THEN
          FOR c_inst IN ( SELECT bi.account_id,
                                 bi.installment_type,
                                 bi.LOB,
                                 bi.fraction_type,
                                 bi.attrib_0,
                                 SUM(bi.amount) comp_amount,
                                 MAX(bi.installment_id) max_inst_id
                          FROM blc_installments bi
                          WHERE bi.item_id = pi_item_id
                          AND bi.compensated = blc_gvar_process.FLG_NO
                          AND bi.billing_run_id IS NULL
                          AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
                          AND bi.currency = c_inst_gr.currency
                          AND bi.attrib_4 = c_inst_gr.begin_date
                          AND bi.attrib_5 = c_inst_gr.end_date
                          GROUP BY bi.account_id,
                                   bi.installment_type,
                                   bi.LOB,
                                   bi.fraction_type,
                                   bi.attrib_0
                          HAVING SUM(bi.amount) <> 0 )
         LOOP
            l_inst := NEW blc_installments_type(c_inst.max_inst_id, pio_Err );

            IF l_inst.installment_type = 'BCPR'
            THEN
               l_inst.installment_type := 'BCPR_COMP';
            ELSIF l_inst.installment_type = 'BCISSUETAX' --03.07.2019 - phase 2
            THEN
               l_inst.installment_type := 'BCISSUETAX_COMP';
            ELSE
               l_inst.installment_type := 'BCTAX_COMP';
            END IF;

            l_inst.amount := (-1)*c_inst.comp_amount;
            l_inst.compensated := blc_gvar_process.FLG_YES;
            l_inst.notes := 'special compensated';
            l_inst.annex := pi_annex_id;
            l_inst.installment_id := NULL;

            IF NOT l_inst.insert_blc_installments( pio_Err )
            THEN
               RETURN;
            END IF;

            blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_STATEMENT,
                                       'inserted compensation installment - '||l_inst.installment_id);
         END LOOP;
       END IF;

       UPDATE blc_installments bi
       SET bi.compensated = blc_gvar_process.FLG_YES,
           bi.notes = TRIM(SUBSTR(nvl2(bi.notes, bi.notes||' - special compensated', 'special compensated'),1,120))
       WHERE bi.item_id = pi_item_id
       AND bi.compensated = blc_gvar_process.FLG_NO
       AND bi.billing_run_id IS NULL
       AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
       AND bi.currency = c_inst_gr.currency
       AND bi.attrib_4 = c_inst_gr.begin_date
       AND bi.attrib_5 = c_inst_gr.end_date;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'updated installments - '||SQL%ROWCOUNT);
    END LOOP;
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure '|| l_log_module);
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, l_log_module, SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'Error in' ||l_log_module||' - '||SQLERRM);
END Comp_Item_Installments_Spec;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Reinstate_Comp_Install_Spec
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Reinstate compensatation specific, delete technical added
-- installments and update compensation flag to N
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pi_annex_id          NUMBER     Annex id
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for annex reverse
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Reinstate_Comp_Install_Spec( pi_item_id       IN NUMBER,
                                       pi_annex_id      IN NUMBER,
                                       pio_Err          IN OUT SrvErr )
IS
    l_log_module         VARCHAR2(240);
    l_SrvErrMsg          SrvErrMsg;
    --
    l_inst BLC_INSTALLMENTS_TYPE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    --
    l_log_module := C_DEFAULT_MODULE||'.Reinstate_Comp_Install_Spec';
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'BEGIN of procedure '|| l_log_module);
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_item_id = '||pi_item_id );
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_annex_id = '||pi_annex_id );

    FOR c_inst IN ( SELECT bi.installment_id
                    FROM blc_installments bi
                    WHERE bi.item_id = pi_item_id
                    AND bi.installment_type IN ('BCPR_COMP','BCTAX_COMP','BCISSUETAX_COMP')
                    AND bi.annex = to_char(pi_annex_id)
                    AND bi.notes NOT LIKE '%reversal%' )
    LOOP
       l_inst := NEW blc_installments_type(c_inst.installment_id, pio_Err );

       l_inst.amount := (-1)*l_inst.amount;
       l_inst.notes := 'special compensated reversal';
       l_inst.installment_id := NULL;

       IF NOT l_inst.insert_blc_installments( pio_Err )
       THEN
          RETURN;
       END IF;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'inserted reversal of compensation installment - '||l_inst.installment_id);
    END LOOP;

    UPDATE blc_installments bi
    SET bi.compensated = blc_gvar_process.FLG_NO,
        bi.notes = REPLACE(REPLACE(bi.notes, ' - special compensated', ''), 'special compensated', '')
    WHERE bi.item_id = pi_item_id
    AND bi.compensated = blc_gvar_process.FLG_YES
    AND bi.installment_type NOT IN ('BCPR_COMP','BCTAX_COMP','BCISSUETAX_COMP')
    AND bi.notes LIKE '%special compensated%';

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'updated installments - '||SQL%ROWCOUNT);

    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure '|| l_log_module);
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, l_log_module, SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'Error in' ||l_log_module||' - '||SQLERRM);
END Reinstate_Comp_Install_Spec;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Comp_Item_Installments_Norm
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--     Fadata  31.07.2010 creation - LPV-2000 -- add comparing by attrib_0
--
-- Purpose: Compensate similar installments for given item id
--
-- Actions:
--  1) Get and lock installments records for comprnsation;
--  2) Loops over collection, retrieve similar installments and reserve their ids;
--  3) Mark reserved installments as compensated;
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for annex reverse
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Comp_Item_Installments_Norm( pi_item_id       IN NUMBER,
                                       pio_Err          IN OUT SrvErr )
IS
    l_log_module         VARCHAR2(240);
    l_SrvErrMsg          SrvErrMsg;
    --
    CURSOR c_inst IS
      SELECT bi.installment_id
      FROM blc_installments bi
      WHERE bi.item_id = pi_item_id
      AND bi.compensated = blc_gvar_process.FLG_NO
      AND bi.billing_run_id IS NULL
      AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
      AND bi.amount <> 0
      FOR UPDATE OF bi.compensated;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    --
    l_log_module := C_DEFAULT_MODULE||'.Compensate_Item_Installments';
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'BEGIN of procedure '|| l_log_module);
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_item_id = '||pi_item_id );

    OPEN c_inst;
    CLOSE c_inst;

    UPDATE blc_installments
    SET compensated = blc_gvar_process.FLG_YES
    WHERE installment_id IN ( SELECT bip.installment_id
                              FROM
                                 ( SELECT bi.installment_id,
                                          SUM(bi.amount) OVER ( PARTITION BY
                                                                    bi.account_id,
                                                                    bi.currency,
                                                                    bi.installment_type,
                                                                    TRUNC(bi.installment_date),
                                                                    TRUNC(bi.rec_rate_date),
                                                                    bi.LOB,
                                                                    bi.fraction_type,
                                                                    ABS(bi.amount),
                                                                    TRUNC(bi.end_date),
                                                                    bi.attrib_0) sum_inst
                                   FROM blc_installments bi
                                   WHERE bi.item_id = pi_item_id
                                   AND bi.compensated = blc_gvar_process.FLG_NO
                                   AND bi.billing_run_id IS NULL
                                   AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
                                  ) bip
                              WHERE bip.sum_inst = 0
                            );

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'updated installments with sum amount 0 - '||SQL%ROWCOUNT);

    UPDATE blc_installments
    SET compensated = blc_gvar_process.FLG_YES
    WHERE installment_id IN (
        SELECT inst_id
        FROM
        (SELECT bip.installment_id pos_installment_id, bin.installment_id neg_installment_id
         FROM
          ( SELECT bi.installment_id,
                   bi.account_id,
                   bi.currency,
                   bi.installment_type,
                   TRUNC(bi.installment_date) installment_date,
                   TRUNC(bi.rec_rate_date) rec_rate_date,
                   bi.LOB,
                   bi.fraction_type,
                   bi.amount,
                   TRUNC(bi.end_date) end_date,
                   bi.attrib_0 agent_id,
                   ROW_NUMBER() OVER ( PARTITION BY bi.account_id,
                                                    bi.currency,
                                                    bi.installment_type,
                                                    TRUNC(bi.installment_date),
                                                    TRUNC(bi.rec_rate_date),
                                                    bi.LOB,
                                                    bi.fraction_type,
                                                    bi.amount,
                                                    TRUNC(bi.end_date),
                                                    bi.attrib_0 ORDER BY bi.installment_id) rn
                   FROM blc_installments bi
                   WHERE bi.item_id = pi_item_id
                   AND bi.compensated = blc_gvar_process.FLG_NO
                   AND bi.billing_run_id IS NULL
                   AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
                   AND bi.amount > 0 ) bip,
           ( SELECT bi.installment_id,
                   bi.account_id,
                   bi.currency,
                   bi.installment_type,
                   TRUNC(bi.installment_date) installment_date,
                   TRUNC(bi.rec_rate_date) rec_rate_date,
                   bi.LOB,
                   bi.fraction_type,
                   bi.amount,
                   TRUNC(bi.end_date) end_date,
                   bi.attrib_0 agent_id,
                   ROW_NUMBER() OVER ( PARTITION BY bi.account_id,
                                                    bi.currency,
                                                    bi.installment_type,
                                                    TRUNC(bi.installment_date),
                                                    TRUNC(bi.rec_rate_date),
                                                    bi.LOB,
                                                    bi.fraction_type,
                                                    bi.amount,
                                                    TRUNC(bi.end_date),
                                                    bi.attrib_0 ORDER BY bi.installment_id) rn
                   FROM blc_installments bi
                   WHERE bi.item_id = pi_item_id
                   AND bi.compensated = blc_gvar_process.FLG_NO
                   AND bi.billing_run_id IS NULL
                   AND bi.installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
                   AND bi.amount < 0 ) bin
        WHERE bip.rn = bin.rn
        AND bip.amount = bin.amount*(-1)
        AND bip.account_id = bin.account_id
        AND bip.currency = bin.currency
        AND bip.installment_type = bin.installment_type
        AND bip.installment_date = bin.installment_date
        AND (bip.rec_rate_date IS NULL AND bin.rec_rate_date IS NULL
             OR bip.rec_rate_date = bin.rec_rate_date)
        AND NVL(bip.LOB, blc_gvar_process.FLG_CHAR_999) = NVL(bin.LOB, blc_gvar_process.FLG_CHAR_999)
        AND NVL(bip.fraction_type, blc_gvar_process.FLG_CHAR_999) = NVL(bin.fraction_type, blc_gvar_process.FLG_CHAR_999)
        AND (bip.end_date IS NULL AND bin.end_date IS NULL
             OR bip.end_date = bin.end_date)
        AND NVL(bip.agent_id, blc_gvar_process.FLG_CHAR_999) = NVL(bin.agent_id, blc_gvar_process.FLG_CHAR_999) )
        UNPIVOT ( inst_id FOR src IN (pos_installment_id, neg_installment_id) )
      );

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'updated pairs of installments - '||SQL%ROWCOUNT);
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure '|| l_log_module);
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, l_log_module, SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'Error in' ||l_log_module||' - '||SQLERRM);
END Comp_Item_Installments_Norm;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mass_Delete_Proforma_Bill
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--     Fadata  31.07.2019 creation - LPV-2000 add case for annex change agent
--     Fadata  29.01.2019 creation - LAP85-15 does not delete documents for next
--                                   billing runs for an annex
--     Fadata  16.12.2020 creation - CON94S-55 - stop deletion of documents for
--                                   GROUP_BILLING items and with begin period
--                                   date smaller than annex begin date
--
-- Purpose:  Execute procedure for delete all unpaid and without AD number
-- proformas related to given item and calculate proper bill method
--
-- Input parameters:
--     pi_item_ids            VARCHAR2     Item Ids
--     pi_annex_id            NUMBER       Annex Id
--     pio_bill_method        VARCHAR2     Bill method
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to delete all unpaid documents before transfer installments
-- for an adjustment to be able to compensate some installments
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mass_Delete_Proforma_Bill
   (pi_item_ids          IN     VARCHAR2,
    pi_annex_id          IN     NUMBER,
    pio_bill_method      IN OUT VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_agreement           blc_items.agreement%TYPE;
    l_policy_id           POLICY.policy_id%TYPE;
    l_doc_ids             VARCHAR2(4000);
    l_count               SIMPLE_INTEGER := 0;
    l_count_d             SIMPLE_INTEGER := 0;
    l_procedure_result    VARCHAR2(30);
    l_doc_status          VARCHAR2(1);
    l_SrvErr              SrvErr;
    l_item                blc_items_type;
    l_item_id             NUMBER;
    l_delete_reason       VARCHAR2(30) := '70';
    l_cancel_bill         VARCHAR2(30) := 'CANCEL';
    --
    l_lock_flag           VARCHAR2(1) := blc_gvar_process.FLG_NO;
    l_comp_spec           VARCHAR2(1) := blc_gvar_process.FLG_NO;
    l_comp_norm           VARCHAR2(1) := blc_gvar_process.FLG_NO;
    l_comp_reverse        VARCHAR2(1) := blc_gvar_process.FLG_NO;
    l_reverse_annex       VARCHAR2(1) := blc_gvar_process.FLG_NO;
    --
    l_tolerance_usd       blc_values.number_value%TYPE;
    l_tolerance_pen       blc_values.number_value%TYPE;
    --
    l_count_runs          SIMPLE_INTEGER := 0; --LAP85-15
    --CON94S-55
    l_delete_flag         VARCHAR2(1) := blc_gvar_process.FLG_NO;
    l_annex_date          DATE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Mass_Delete_Proforma_Bill';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Mass_Delete_Proforma_Bill');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_item_ids = '||pi_item_ids);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_annex_id = '||pi_annex_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_bill_method = '||pio_bill_method);

    --IF Is_Item_Policy(pi_item_ids) = blc_gvar_process.FLG_YES AND nvl(pi_annex_id,0) <> 0
    --only for non protocol billing policies (blc_items.attrib_2 = 'N') documents will be deleted --LPV-2621
    IF Is_Item_Non_Protocol_Policy(pi_item_ids) = blc_gvar_process.FLG_YES AND nvl(pi_annex_id,0) <> 0 --
    THEN
       l_item_id := TO_NUMBER(pi_item_ids);
       l_item := NEW blc_items_type(l_item_id, l_SrvErr);

       l_agreement := l_item.agreement;
       l_policy_id := TO_NUMBER(l_item.component);

       l_reverse_annex := Is_Annex_Reverse(l_policy_id, pi_annex_id);

       --LAP85-15
       SELECT count(*)
       INTO l_count_runs
       FROM blc_run br
       WHERE br.item_ids = pi_item_ids
       AND br.annex = TO_CHAR(pi_annex_id);

       IF Is_Agent_Change_Annex(l_policy_id, pi_annex_id) = blc_gvar_process.FLG_YES --LPV-2000
          AND l_count_runs = 0 --LAP85-15
       THEN
          Mass_Update_Proforma
             (pi_policy_id => l_policy_id,
              pi_annex_id  => pi_annex_id,
              pio_Err      => pio_Err);
       ELSIF Get_Annex_Type(l_policy_id, pi_annex_id) IN ('12','17')
             AND l_count_runs = 0 --LAP85-15
       THEN
         IF Is_Not_Pay_Annex(l_policy_id, pi_annex_id) = blc_gvar_process.FLG_YES
         THEN
            l_delete_flag := blc_gvar_process.FLG_YES; --CON94S-55
            --
            IF l_reverse_annex = blc_gvar_process.FLG_YES
            THEN
               l_comp_reverse := blc_gvar_process.FLG_YES;
               l_comp_norm := blc_gvar_process.FLG_YES;
               l_lock_flag := blc_gvar_process.FLG_YES;
            ELSE
               l_comp_spec := blc_gvar_process.FLG_YES;
               pio_bill_method := l_cancel_bill;
            END IF;
         ELSIF NVL(l_item.attrib_7, blc_gvar_process.FLG_CHAR_999) <> 'CLIENT_GROUP'
         THEN
            l_lock_flag := blc_gvar_process.FLG_YES;
            l_delete_flag := blc_gvar_process.FLG_YES; --CON94S-55
            --
            IF Is_Manual_Canc_Annex(l_policy_id, pi_annex_id) = blc_gvar_process.FLG_YES
            THEN
               IF l_reverse_annex = blc_gvar_process.FLG_YES
               THEN
                  l_comp_reverse := blc_gvar_process.FLG_YES;
                  l_comp_norm := blc_gvar_process.FLG_YES;
               ELSE
                  l_comp_spec := blc_gvar_process.FLG_YES;
                  pio_bill_method := l_cancel_bill;
               END IF;
            ELSIF l_reverse_annex = blc_gvar_process.FLG_YES
            THEN
               l_comp_norm := blc_gvar_process.FLG_YES;
            END IF;
         END IF;
         --
         IF blc_appl_cache_pkg.g_legal_entity_id IS NULL OR blc_appl_cache_pkg.g_legal_entity_id <> l_item.legal_entity_id
         THEN
            blc_appl_cache_pkg.Init_LE( l_item.legal_entity_id, pio_Err );
         END IF;

         --delete documents
         /*
         FOR c_doc IN (SELECT bd.doc_id, bd.amount, bd.status
                       FROM blc_items bi,
                            blc_transactions bt,
                            blc_documents bd
                       WHERE bi.agreement = l_agreement
                       AND bi.item_type = 'POLICY'
                       AND bi.item_id = bt.item_id
                       AND bt.status NOT IN ('C','R','D')
                       AND bt.doc_id = bd.doc_id
                       AND bd.status IN ('A','F')
                       AND bd.doc_class = 'B' -- add to not delete notification documents
                       AND bd.doc_suffix IS NULL
                       GROUP BY bd.doc_id, bd.amount, bd.status
                       ORDER BY bd.amount)
         */
         -- delete documents only related to given item_id --05.08.2019
         IF l_delete_flag = blc_gvar_process.FLG_YES --CON94S-55
         THEN
             l_annex_date := Get_Annex_Date(l_policy_id, pi_annex_id);

             FOR c_doc IN (SELECT DISTINCT bd.doc_id, bd.amount, bd.status
                           FROM blc_transactions bt,
                                blc_documents bd
                           WHERE bt.item_id = l_item_id
                           AND bt.status NOT IN ('C','R','D')
                           AND bt.doc_id = bd.doc_id
                           AND bd.status IN ('A','F')
                           AND bd.doc_class = 'B' -- add to not delete notification documents
                           AND bd.doc_suffix IS NULL
                           AND bt.attrib_6 >= TO_CHAR(TRUNC(l_annex_date),'YYYY-MM-DD') --CON94S-55
                           --AND bd.due_date >= TRUNC(l_annex_date) --CON94S-55 - use the above as more precize
                           ORDER BY bd.amount)
             LOOP
                 blc_log_pkg.insert_message(l_log_module,
                                            C_LEVEL_STATEMENT,
                                            'c_doc.doc_id = '||c_doc.doc_id);

                 l_doc_ids := Calculate_Referred_Doc(c_doc.doc_id,l_agreement);

                 IF l_doc_ids IS NOT NULL
                 THEN
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_STATEMENT,
                                               'The document is referred from doc_id(s): '||l_doc_ids);
                    CONTINUE;
                 END IF;

                 --
                 Unapply_Net_Appl_Document( pi_doc_id => c_doc.doc_id,
                                            pio_Err   => l_SrvErr );

                 --
                 SELECT count(*)
                 INTO l_count
                 FROM blc_transactions bt,
                      blc_applications ba
                 WHERE bt.doc_id = c_doc.doc_id
                 AND ba.target_trx = bt.transaction_id
                 AND ba.reversed_appl IS NULL
                 AND NOT EXISTS (SELECT 'REVERSE'
                                 FROM blc_applications ba1
                                 WHERE ba1.reversed_appl = ba.application_id);

                 IF l_count = 0
                 THEN
                    SELECT count(*)
                    INTO l_count
                    FROM blc_transactions bt,
                         blc_applications ba
                    WHERE bt.doc_id = c_doc.doc_id
                    AND ba.source_trx = bt.transaction_id
                    AND ba.reversed_appl IS NULL
                    AND NOT EXISTS (SELECT 'REVERSE'
                                    FROM blc_applications ba1
                                    WHERE ba1.reversed_appl = ba.application_id);
                 END IF;

                 IF l_count > 0
                 THEN
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_STATEMENT,
                                               'There are not reversed applications');
                    CONTINUE;
                 END IF;

                 IF c_doc.status = 'F' AND l_lock_flag = 'Y'
                 THEN
                    --IP - need to call service for lock document in SAP
                    cust_intrf_util_pkg.Lock_Doc_For_Delete
                                      (pi_doc_id            => c_doc.doc_id,
                                       pi_rev_reason        => l_delete_reason,
                                       po_procedure_result  => l_procedure_result,
                                       pio_Err              => pio_Err);

                    IF l_procedure_result = cust_gvar.FLG_ERROR
                    THEN
                       IF NOT srv_error.rqStatus( pio_Err )
                       THEN
                          blc_log_pkg.insert_message(l_log_module,
                                                     C_LEVEL_EXCEPTION,
                                                     'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                       ELSE
                          srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mass_Delete_Proforma', 'cust_billing_pkg.PRP.IP_Error');
                          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                          blc_log_pkg.insert_message(l_log_module,
                                                     C_LEVEL_EXCEPTION,
                                                     'c_doc.doc_id = '||c_doc.doc_id||' - '||'Integration for lock document for deletion in SAP return error');
                       END IF;
                       --
                       RETURN;
                    END IF;
                 END IF;

                 l_procedure_result := NULL;

                 blc_doc_process_pkg.Set_Unformal_Document
                        (pi_doc_id             => c_doc.doc_id,
                         pi_action_notes       => NULL,
                         pio_procedure_result  => l_procedure_result,
                         po_doc_status         => l_doc_status,
                         pio_Err               => pio_Err);

                 IF l_doc_status = 'A'
                 THEN
                     blc_doc_process_pkg.Delete_Document
                          (pi_doc_id             => c_doc.doc_id,
                           pi_action_notes       => srv_error.GetSrvMessage('cust_billing_pkg.MDP.MassDelete')||': '||l_policy_id||'/'||pi_annex_id||'/'||l_agreement,
                           pio_procedure_result  => l_procedure_result,
                           po_doc_status         => l_doc_status,
                           pio_Err               => pio_Err);

                     IF l_procedure_result = cust_gvar.FLG_ERROR
                     THEN
                        IF NOT srv_error.rqStatus( pio_Err )
                        THEN
                           blc_log_pkg.insert_message(l_log_module,
                                                      C_LEVEL_EXCEPTION,
                                                      'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                        END IF;

                        RETURN;
                    END IF;
                    --
                    blc_log_pkg.insert_message(l_log_module,
                                               C_LEVEL_STATEMENT,
                                               'Document is deleted');
                    --
                    Set_Doc_Delete_Reason
                       (pi_doc_id            => c_doc.doc_id,
                        pi_delete_reason     => l_delete_reason,
                        pio_Err              => pio_Err);

                     IF NOT srv_error.rqStatus( pio_Err )
                     THEN
                        blc_log_pkg.insert_message(l_log_module,
                                                   C_LEVEL_EXCEPTION,
                                                   'c_doc.doc_id = '||c_doc.doc_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
                        RETURN;
                     END IF;

                    l_count_d := l_count_d + 1;
                 END IF;
             END LOOP;
         END IF;

         blc_log_pkg.insert_message(l_log_module,
                                    C_LEVEL_STATEMENT,
                                    'Number of deleted documents '||l_count_d);

         --update compensated flag to N for agent change annex to can make specific compensation by agent_id (attrib_0) - LPV-2000
         --remove next code because of decision to not store agent_id in installment.attrib_0
         /*
         IF Is_Agent_Change_Annex(l_policy_id, pi_annex_id) = blc_gvar_process.FLG_YES
         THEN
            Update_Comp_Install
                                (pi_item_id   =>  l_item_id,
                                 pio_Err      =>  pio_Err);

            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'l_item_id = '||l_item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
               RETURN;
             END IF;

             l_comp_norm := blc_gvar_process.FLG_YES;
         END IF;
         */

         --reverse custom compensation in case of reverse of cancellation annex
         IF l_comp_reverse = blc_gvar_process.FLG_YES
         THEN
            Reinstate_Comp_Install_Spec
                                 (pi_item_id   =>  l_item_id,
                                  pi_annex_id  =>  pi_annex_id,
                                  pio_Err      =>  pio_Err);

            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'l_item_id = '||l_item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
               RETURN;
            END IF;
         END IF;

         --execute normal compensation in case of reverse of an annex
         IF l_comp_norm = blc_gvar_process.FLG_YES
         THEN
            Comp_Item_Installments_Norm
                                 (pi_item_id   =>  l_item_id,
                                  pio_Err      =>  pio_Err);

            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'l_item_id = '||l_item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
               RETURN;
            END IF;
         END IF;

         --execute custom compensation in case of cancellation annex
         IF l_comp_spec = blc_gvar_process.FLG_YES
         THEN
            l_tolerance_usd := Get_Comp_Tolerance_USD;
            l_tolerance_pen := Get_Comp_Tolerance_PEN;

            Comp_Item_Installments_Spec
                                 (pi_item_id        => l_item_id,
                                  pi_annex_id       => pi_annex_id,
                                  pi_tolerance_usd  => l_tolerance_usd,
                                  pi_tolerance_pen  => l_tolerance_pen,
                                  pio_Err           => pio_Err);

            IF NOT srv_error.rqStatus( pio_Err )
            THEN
               blc_log_pkg.insert_message(l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'l_item_id = '||l_item_id||' - '||pio_Err(pio_Err.FIRST).errmessage);
               RETURN;
            END IF;
         END IF;
       END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pio_bill_method = '||pio_bill_method);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Mass_Delete_Proforma_Bill');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mass_Delete_Proforma_Bill', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_item_ids = '||pi_item_ids||' - '||SQLERRM);
END Mass_Delete_Proforma_Bill;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Unapply_Net_Appl_Document
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  11.06.2019 creation - LPVS-111
--
-- Purpose: Execute procedure for unapply internal CREDIT_ON_TRX applications
--
-- Input parameters:
--     pi_doc_id              NUMBER       Document identifier (required)
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_procedure_result   VARCHAR2     Procedure result
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
--
-- Usage: Before delete document
--
-- Exceptions:
--    1) In case that doc_id is not specified or is invalid
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Unapply_Net_Appl_Document
   (pi_doc_id             IN     NUMBER,
    pio_Err               IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_SrvErr              SrvErr;
    l_doc                 BLC_DOCUMENTS_TYPE;
BEGIN
   blc_log_pkg.initialize(pio_Err);
   IF NOT srv_error.rqStatus( pio_Err )
   THEN
      RETURN;
   END IF;

   l_log_module := C_DEFAULT_MODULE||'.Unapply_Net_Appl_Document';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Unapply_Net_Appl_Document');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_doc_id = '||pi_doc_id);

   FOR c_appl IN (SELECT BLC_APPLICATIONS_TYPE(ba.APPLICATION_ID, ba.APPL_CLASS,
                                ba.APPL_DATE, ba.VALUE_DATE, ba.RATE_DATE, ba.SOURCE_AMOUNT,
                                ba.SOURCE_RATE, ba.SOURCE_RATE_TYPE, ba.SOURCE_ROUNDING, ba.TARGET_AMOUNT,
                                ba.TARGET_RATE, ba.TARGET_RATE_TYPE, ba.TARGET_ROUNDING, ba.TARGET_TRX,
                                ba.SOURCE_TRX, ba.TARGET_ITEM, ba.APPL_ACTIVITY, ba.APPL_DETAIL, ba.LEGAL_ENTITY,
                                ba.ACCOUNT_ID, ba.SOURCE_PAYMENT, ba.REVERSED_APPL, ba.STATUS,
                                ba.RUN_ID, ba.CREATED_ON, ba.CREATED_BY, ba.UPDATED_ON,
                                ba.UPDATED_BY, ba.ATTRIB_0, ba.ATTRIB_1, ba.ATTRIB_2, ba.ATTRIB_3,
                                ba.ATTRIB_4, ba.ATTRIB_5, ba.ATTRIB_6, ba.ATTRIB_7, ba.ATTRIB_8,
                                ba.ATTRIB_9, ba.LOB, ba.BATCH, ba.doc_id, ba.status_date, ba.reinstated_appl) r_appl
                        FROM blc_applications ba,
                             blc_transactions btt,
                             blc_transactions bts
                        WHERE ba.target_trx = btt.transaction_id
                        AND btt.doc_id = pi_doc_id
                        AND ba.source_trx = bts.transaction_id
                        AND bts.doc_id = pi_doc_id
                        AND ba.status <> 'D'
                        AND ba.reversed_appl IS NULL
                        AND (ba.attrib_9 IS NULL OR ba.attrib_9 = '-999') --04.02.2017
                        AND NOT EXISTS (SELECT 'REVERSE'
                                        FROM blc_applications ba1
                                        WHERE ba1.reversed_appl = ba.application_id
                                        AND ba1.status <> 'D')
                        ORDER BY ba.updated_on DESC, ba.application_id DESC                   )
  LOOP
     blc_appl_util_pkg.Unapply_Application
                            ( c_appl.r_appl, blc_appl_cache_pkg.g_to_date, pio_Err);

     IF NOT srv_error.rqStatus( pio_Err )
     THEN
        blc_log_pkg.insert_message(l_log_module,
                                   C_LEVEL_EXCEPTION,
                                   'c_appl.r_appl.application_id = '||c_appl.r_appl.application_id||' - '||pio_Err(pio_Err.FIRST).errmessage);

        RETURN;
     END IF;
   END LOOP;

   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'END of procedure Unapply_Net_Appl_Document');
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Unapply_Net_Appl_Document', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module,
                                C_LEVEL_EXCEPTION,
                                'pi_doc_id = '||pi_doc_id||' - '||SQLERRM);
END Unapply_Net_Appl_Document;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Auto_Policy_Cancel
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.07.2019  creation - Phase 2
--
-- Purpose: Check if allowed policy cancellation for given policy in component
-- if item type is POLICY
--
-- Input parameters:
--     pi_item_type   Varchar2    Item type (required)
--     pi_component   Varchar2    Item component (required)
--
-- Returns:
--     Y/N or NULL for non POLICY types
--
-- Usage: When need to know if policy is restricted from automatic cancellation
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Auto_Policy_Cancel
   (pi_item_type     IN     VARCHAR2,
    pi_component     IN     VARCHAR2)
RETURN VARCHAR2
IS
   l_policy_id  POLICY.policy_id%TYPE;
   l_value      VARCHAR2(1);
   l_count      SIMPLE_INTEGER := 0;
BEGIN
    IF pi_item_type = 'POLICY'
    THEN
       l_value := 'Y';
       l_policy_id := to_number(pi_component);

       SELECT count(*)
       INTO l_count
       FROM policy_conditions
       WHERE policy_id = l_policy_id
       AND cond_type IN ('LICITACION_TENDER', 'CONSORCIO')
       AND cond_dimension = '2'; -- 1-No; 2-Yes

       IF l_count > 0
       THEN
          l_value := 'N';
       END IF;
    ELSE
       l_value := NULL;
    END IF;

    RETURN l_value;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END Is_Auto_Policy_Cancel;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Agent_Name
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.07.2019  creation - Phase 2
--
-- Purpose: get agent name
--
-- Input parameters:
--     pi_agent_id    Varchar2    Agent id (required)
--
-- Returns:
--     agent name
--
-- Usage: When need to know agent_name
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Agent_Name
   (pi_agent_id     IN     VARCHAR2)
RETURN VARCHAR2
IS
   l_name      VARCHAR2(400 CHAR);
BEGIN
   SELECT pp.NAME
   INTO l_name
   FROM p_agents pa,
        p_people pp
   WHERE pa.agent_id = TO_NUMBER(pi_agent_id)
   AND pa.man_id = pp.man_id;

   RETURN l_name;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END Get_Agent_Name;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Agent_Change_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   31.07.2019  creation - LPV-2000
--
-- Purpose: Check if given annex is for SIP
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for SIP
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Agent_Change_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  --
  CURSOR c_annex IS
    SELECT annex_id
    FROM gen_annex_reason
    WHERE policy_id = pi_policy_id
    AND annex_id = pi_annex_id
    AND annex_reason = 'AGENTNOCOM';
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      RETURN 'N';
   END IF;

   OPEN c_annex;
     FETCH c_annex
     INTO l_annex_id;
   CLOSE c_annex;

   IF l_annex_id IS NOT NULL
   THEN
      RETURN 'Y';
   ELSE
      RETURN 'N';
   END IF;
END Is_Agent_Change_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Update_Comp_Install
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  31.07.2019 creation - LPV_2000
--
-- Purpose: Update compensation flag to N
--
-- Input parameters:
--     pi_item_id           NUMBER     Item id (required)
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: Before billing for annex change agent
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Update_Comp_Install( pi_item_id       IN NUMBER,
                               pio_Err          IN OUT SrvErr )
IS
    l_log_module         VARCHAR2(240);
    l_SrvErrMsg          SrvErrMsg;
    --
    l_inst BLC_INSTALLMENTS_TYPE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    --
    l_log_module := C_DEFAULT_MODULE||'.Update_Comp_Install';
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'BEGIN of procedure '|| l_log_module);
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'pi_item_id = '||pi_item_id );

    UPDATE blc_installments bi
    SET bi.compensated = blc_gvar_process.FLG_NO
    WHERE bi.item_id = pi_item_id
    AND bi.compensated = blc_gvar_process.FLG_YES;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'updated installments - '||SQL%ROWCOUNT);

    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure '|| l_log_module);
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, l_log_module, SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'Error in' ||l_log_module||' - '||SQLERRM);
END Update_Comp_Install;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Calc_Collector_Agent
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.08.2019  creation LPV-2000
--
-- Purpose: Calculate collector agent
--
-- Input parameters:
--     pi_item_type       VARCHAR2   Item type
--     pi_policy_id       VARCHAR2   Policy Id
--     pi_period_from     DATE       Bill premium begin date (YYYY-MM-DD)
--
-- Returns:
--     Collector agent id
--
-- Usage: In run billing to calculate collector agent
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Calc_Collector_Agent
   (pi_item_type        IN     VARCHAR2,
    pi_policy_id        IN     VARCHAR2,
    pi_period_from      IN     VARCHAR2)
RETURN NUMBER
IS
  l_policy_id    POLICY.policy_id%TYPE;
  l_agent_id     policy_agents.agent_id%TYPE;
BEGIN
   IF pi_item_type = 'POLICY'
   THEN
      l_policy_id := pi_policy_id;

      BEGIN
        SELECT pa.agent_id
        INTO l_agent_id
        FROM policy_agents pa
        WHERE pa.policy_id = l_policy_id
        AND pa.agent_role = 'INTAGCOLL'
        AND pi_period_from BETWEEN TO_CHAR(TRUNC(pa.valid_from),'YYYY-MM-DD') AND NVL(TO_CHAR(TRUNC(pa.valid_to)-1,'YYYY-MM-DD'), '3000-12-31');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_agent_id := NULL;
      END;
   END IF;

   RETURN l_agent_id;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END Calc_Collector_Agent;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Mass_Update_Proforma
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   12.08.2019  creation - LPV-2000
--
-- Purpose:  Execute procedure for update unpaid proforma attributes
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to update all unpaid documents affected by an annex change
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Mass_Update_Proforma
   (pi_policy_id         IN     NUMBER,
    pi_annex_id          IN     NUMBER,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_valid_from          VARCHAR2(20);
    l_valid_to            VARCHAR2(20);
    l_agent_id            VARCHAR2(50);
    l_count               SIMPLE_INTEGER := 0;
    l_count_diff          SIMPLE_INTEGER := 0;
    l_doc                 blc_documents_type;
    l_trx                 blc_transactions_type;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Mass_Update_Proforma';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Mass_Update_Proforma');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_policy_id = '||pi_policy_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_annex_id = '||pi_annex_id);

    BEGIN
       SELECT TO_CHAR(TRUNC(pa.valid_from),'YYYY-MM-DD'),
              NVL(TO_CHAR(TRUNC(pa.valid_to)-1,'YYYY-MM-DD'), '3000-12-31'),
              agent_id
       INTO l_valid_from,
            l_valid_to,
            l_agent_id
       FROM policy_agents pa
       WHERE pa.policy_id = pi_policy_id
       AND pa.annex_id = pi_annex_id
       AND pa.agent_role = 'INTAGCOLL'
       AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           l_valid_from := NULL;
           l_valid_to := NULL;
    END;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                               'l_valid_from = '||l_valid_from);

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_STATEMENT,
                              'l_valid_to = '||l_valid_to);

    --
    IF l_valid_from IS NOT NULL
    THEN
       FOR c_doc IN (SELECT DISTINCT bd.doc_id, bd.attrib_3
                     FROM blc_items bi,
                          blc_transactions bt,
                          blc_documents bd
                     WHERE bi.item_type = 'POLICY'
                     AND bi.component = TO_CHAR(pi_policy_id)
                     AND bi.item_id = bt.item_id
                     AND bt.status NOT IN ('C','R','D')
                     AND bt.open_balance <> 0
                     AND bt.attrib_6 BETWEEN l_valid_from AND l_valid_to
                     AND bt.doc_id = bd.doc_id
                     --AND bd.status IN ('A','F') no need to check doc status
                     AND bd.doc_class = 'B' -- add to not delete notification documents
                     AND bd.attrib_3 <> l_agent_id
                     ORDER BY bd.doc_id)
       LOOP
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                     'c_doc.doc_id = '||c_doc.doc_id);

          SELECT count(*)
          INTO l_count_diff
          FROM blc_transactions bt
          WHERE bt.doc_id = c_doc.doc_id
          AND bt.status NOT IN ('C','R','D')
          AND (bt.attrib_6 IS NULL
               OR bt.attrib_6 NOT BETWEEN l_valid_from AND l_valid_to);

          IF l_count_diff > 0
          THEN
             CONTINUE;
          END IF;

          FOR c_trx IN ( SELECT BLC_TRANSACTIONS_TYPE (TRANSACTION_ID, TRANSACTION_CLASS, TRANSACTION_TYPE,
                                 TRANSACTION_DATE, GL_DATE, CURRENCY, AMOUNT, ASSESSED_VALUE, RATE,
                                 RATE_DATE, RATE_TYPE, VARIANCE, FC_CURRENCY, FC_AMOUNT, FC_VARIANCE, ITEM_NAME,
                                 NOTES, DUE_DATE, GRACE, GRACE_EXTRA, LEGAL_ENTITY, ORG_ID, ACCOUNT_ID, ITEM_ID, DOC_ID,
                                 APPLICATION_ID, TAX_ID, PARENT_TRX_ID, BILLING_RUN_ID, STATUS, CREATED_ON,
                                 CREATED_BY, UPDATED_ON, UPDATED_BY, ATTRIB_0, ATTRIB_1, ATTRIB_2,
                                 ATTRIB_3, ATTRIB_4, ATTRIB_5, ATTRIB_6, ATTRIB_7, ATTRIB_8, ATTRIB_9,
                                 OPEN_BALANCE, PAID_STATUS, CHARGE_TO, REF_DOC_ID, PAY_WAY_ID, PAY_INSTR,
                                 ACTUAL_OPEN_BALANCE, LINE_NUMBER ) r_trx_type
                         FROM blc_transactions
                         WHERE doc_id = c_doc.doc_id
                         AND status NOT IN ('C','R','D'))
          LOOP
             l_trx := c_trx.r_trx_type;
             --
             blc_log_pkg.insert_message(l_log_module,
                                       C_LEVEL_STATEMENT,
                                       'l_trx_id = '||l_trx.transaction_id);

             l_trx.attrib_9 := l_agent_id;
             --
             IF NOT l_trx.update_blc_transactions(pio_Err)
             THEN
                 blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                            'l_trx_id  = '||l_trx.transaction_id||' - '||
                                            pio_Err(pio_Err.FIRST).errmessage);
                 CONTINUE;
             END IF;
          END LOOP;

          l_doc := NEW blc_documents_type(c_doc.doc_id);

          l_doc.attrib_3 := l_agent_id;
          l_doc.attrib_4 := substr(Get_Agent_Name(l_agent_id),1,120);

          IF NOT l_doc.update_blc_documents( pio_Err )
          THEN
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'c_doc.doc_id = '||c_doc.doc_id||' - '||
                                        pio_Err(pio_Err.FIRST).errmessage);
          ELSE
             srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Mass_Update_Proforma', 'blc_pmnt_util_pkg.MP.ChangeField','ATTRIB_3|'||c_doc.attrib_3||'/'||l_agent_id);

             blc_doc_util_pkg.Insert_Action( pi_action_type   => 'CHANGE_AGENT',
                                             pi_notes         => l_SrvErrMsg.errmessage,
                                             pi_status        => 'S',
                                             pi_doc_id        => l_doc.doc_id,
                                             pio_Err          => pio_Err );

          END IF;

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
             l_count := 0;
             CONTINUE;
          ELSE
             l_count := l_count + 1;
          END IF;
       END LOOP;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                  'Number of updated documents '||l_count);
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Mass_Update_Proforma');

END Mass_Update_Proforma;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Annex_Type
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  13.08.2019 creation - LPV-2000
--
-- Purpose: Get annex type
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know annex type
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Annex_Type
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_type   VARCHAR2(30);
BEGIN
   SELECT A.annex_type
   INTO l_annex_type
   FROM gen_annex A
   WHERE A.policy_id = pi_policy_id
   AND A.annex_id = pi_annex_id;

   RETURN l_annex_type;
EXCEPTION
  WHEN OTHERS THEN
     RETURN NULL;
END Get_Annex_Type;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Office
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   20.12.2019  creation  LPV-2429
--
-- Purpose: Get the office id from the policy
--
-- Input parameters:
--       pi_component      VARCHAR2  Item component
--
-- Returns: office
--
-- Usage: In billing process, update transaction attrib_1
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Office( pi_component IN VARCHAR2 ) RETURN VARCHAR2
IS
    l_count    SIMPLE_INTEGER := 0;
    l_office   VARCHAR2(200);
    --
    CURSOR o_pol_office IS
    SELECT A.oaip4
    FROM o_accinsured A, insured_object i
    WHERE i.object_id = A.object_id
        AND i.policy_id = TO_NUMBER(pi_component)
    ORDER BY i.annex_id DESC;
BEGIN
    SELECT COUNT(*) INTO l_count
    FROM policy_engagement_billing
    WHERE policy_id = TO_NUMBER(pi_component)
        AND attr1 = '3';
    --
    IF l_count > 0
    THEN
        OPEN o_pol_office;
        FETCH o_pol_office INTO l_office;
        CLOSE o_pol_office;
    END IF;
    --
    RETURN l_office;
END Get_Office;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Update_Item_Due_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   10.02.2020  creation - CON94S-9
--
-- Purpose: Change due date with new annex reason - Change Payment due date
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pi_stage               VARCHAR2
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Return: Boolean
--
-- Usage: N/A
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Update_Item_Due_Date
    ( pi_policy_id IN     NUMBER,
      pi_annex_id  IN     NUMBER,
      pi_stage     IN     VARCHAR2,
      pio_Err      IN OUT SrvErr )
RETURN BOOLEAN
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    --
    l_OpSt    BOOLEAN := TRUE;
    l_count   SIMPLE_INTEGER := 0;
    l_item_id  blc_items.item_id%TYPE;
    l_item     blc_items_type;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    --
    l_log_module := C_DEFAULT_MODULE||'.Update_Item_Due_Date';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Update_Item_Due_Date');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_policy_id = '||pi_policy_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_annex_id = '||pi_annex_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_stage = '||pi_stage);
    --
    IF NVL(pi_stage, 'CONVERT') = 'CONVERT'
        AND pi_annex_id > 0
    THEN
        SELECT COUNT(*) INTO l_count
        FROM gen_annex_reason
        WHERE policy_id = pi_policy_id
            AND annex_id = pi_annex_id
            AND annex_reason = 'PAYDUEDATE';
        --
        IF l_count > 0
        THEN
            SELECT MAX(item_id) INTO l_item_id
            FROM blc_items
            WHERE component = TO_CHAR(pi_policy_id)
                AND item_type = 'POLICY';
            --
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'l_item_id = '||l_item_id);
            --
            IF l_item_id IS NOT NULL
            THEN
                l_item := blc_items_type(l_item_id, pio_Err);
                --
                SELECT NVL(attr8, TO_CHAR(payment_due_date)) INTO l_item.attrib_8
                FROM policy_engagement_billing
                WHERE policy_id = pi_policy_id
                    AND annex_id = pi_annex_id;
                --
                blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'new blc_item.attrib_8 = '||l_item.attrib_8);
                --
                l_OpSt := l_item.update_blc_items( pio_Err );
            END IF;
        END IF;
    END IF;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Update_Item_Due_Date');
    --
    RETURN l_OpSt;
    --
EXCEPTION
     WHEN OTHERS THEN
         srv_error.SetSysErrorMsg( l_SrvErrMsg, l_log_module, SQLERRM );
         srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
         blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_policy_id = '||pi_policy_id||' - '|| 'pi_annex_id = '||pi_annex_id||' - '||SQLERRM);
         RETURN FALSE;
END Update_Item_Due_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_Item_Non_Protocol_Policy
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   24.04.2020  creation - LPV-2621
--
-- Purpose: Check if given item list includes only one item for non protocol
-- billed policy
--
-- Input parameters:
--     pi_item_ids   Varchar2    Item ids (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if item is for policy not marked for protocol biling
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_Item_Non_Protocol_Policy
   (pi_item_ids     IN     VARCHAR2)
RETURN VARCHAR2
IS
   l_count PLS_INTEGER;
BEGIN
    IF pi_item_ids IS NOT NULL AND instr(pi_item_ids,',') = 0
    THEN
       BEGIN
         SELECT count(*)
         INTO l_count
         FROM blc_items
         WHERE item_id = to_number(pi_item_ids)
         AND item_type = 'POLICY'
         AND nvl(attrib_2,'N') = 'N';
       EXCEPTION
          WHEN OTHERS THEN
             l_count := NULL;
       END;
    END IF;

    IF l_count = 1
    THEN
       RETURN 'Y';
    ELSE
       RETURN 'N';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      RETURN 'N';
END Is_Item_Non_Protocol_Policy;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Get_Annex_Date
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  16.12.2020 creation - CON94S-55
--
-- Purpose: Get annex type
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know annex begin date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Get_Annex_Date
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN DATE
IS
  l_annex_date   DATE;
BEGIN
   SELECT A.insr_begin
   INTO l_annex_date
   FROM gen_annex A
   WHERE A.policy_id = pi_policy_id
   AND A.annex_id = pi_annex_id;

   RETURN l_annex_date;
EXCEPTION
  WHEN OTHERS THEN
     RETURN NULL;
END Get_Annex_Date;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Is_PayWay_Change_Annex
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.12.2020  creation - CON94S-55
--
-- Purpose: Check if given annex is for pay way change
--
-- Input parameters:
--     pi_policy_id          NUMBER        Policy Id (required)
--     pi_annex_id           NUMBER        Annex Id (required)
--
-- Returns:
--     Y/N
--
-- Usage: When need to know if annex is for pay way change
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Is_PayWay_Change_Annex
   (pi_policy_id     IN     NUMBER,
    pi_annex_id      IN     NUMBER)
RETURN VARCHAR2
IS
  l_annex_id    NUMBER;
  --
  CURSOR c_annex IS
    SELECT annex_id
    FROM gen_annex_reason
    WHERE policy_id = pi_policy_id
    AND annex_id = pi_annex_id
    AND annex_reason = 'PAYWAY';
BEGIN
   IF nvl(pi_annex_id,0) = 0
   THEN
      RETURN blc_gvar_process.FLG_NO;
   END IF;

   OPEN c_annex;
     FETCH c_annex
     INTO l_annex_id;
   CLOSE c_annex;

   IF l_annex_id IS NOT NULL
   THEN
      RETURN blc_gvar_process.FLG_YES;
   ELSE
      RETURN blc_gvar_process.FLG_NO;
   END IF;
END Is_PayWay_Change_Annex;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Run_Billing_PayWay_Change
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.12.2020  creation - CON94S-55
--
-- Purpose:  Execute rum immediate billing for pay way change annex
--
-- Input parameters:
--     pi_policy_id           NUMBER       Policy Id
--     pi_annex_id            NUMBER       Annex Id
--     pi_stage               VARCHAR2     Stage
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: When need to explicitly run immediate billing
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Run_Billing_PayWay_Change
   (pi_policy_id         IN     NUMBER,
    pi_annex_id          IN     NUMBER,
    pi_stage             IN     VARCHAR2,
    pio_Err              IN OUT SrvErr)
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    l_item_id             blc_items.item_id%TYPE;
    l_Context             SrvContext;
    l_RetContext          SrvContext;
    l_item                blc_items_type;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Run_Billing_PayWay_Change';
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'BEGIN of procedure Run_Billing_PayWay_Change');
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_policy_id = '||pi_policy_id);
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'pi_annex_id = '||pi_annex_id);

    IF NVL(pi_stage, 'CONVERT') = 'CONVERT' AND
       Is_PayWay_Change_Annex(pi_policy_id, pi_annex_id) = blc_gvar_process.FLG_YES
    THEN
        SELECT MAX(item_id) INTO l_item_id
        FROM blc_items
        WHERE component = TO_CHAR(pi_policy_id)
        AND item_type = 'POLICY';
        --
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'l_item_id = '||l_item_id);
        --
        IF l_item_id IS NOT NULL
        THEN
           l_item := blc_items_type(l_item_id, pio_Err);

           srv_context.SetContextAttrChar( l_Context, 'OFFICE', l_item.office);
           srv_context.SetContextAttrChar( l_Context, 'ITEM_IDS', l_item_id);
           srv_context.SetContextAttrChar( l_Context, 'AGREEMENT', l_item.agreement);
           srv_context.SetContextAttrChar( l_Context, 'COMPONENT', l_item.component);
           srv_context.SetContextAttrChar( l_Context, 'SOURCE', l_item.SOURCE);
           srv_context.SetContextAttrChar( l_Context, 'ANNEX', pi_annex_id);
           srv_context.SetContextAttrChar( l_Context, 'BILL_METHOD', 'STANDARD');

           srv_events.sysEvent( 'RUN_BLC_BILLING', l_Context, l_RetContext, pio_Err );
        END IF;
    END IF;

    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                               'END of procedure Run_Billing_PayWay_Change');

END Run_Billing_PayWay_Change;

--------------------------------------------------------------------------------
-- Name: cust_billing_pkg.Validate_New_Adj_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.09.2021  creation - LAP85-132
--
-- Purpose: Validate amount on manual adjust transactions
--
-- Input parameters:
--     pi_trx_id              NUMBER       Transaction Id
--     pi_trx_type            VARCHAR2     Transaction type
--     pi_amount              NUMBER       Amount
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err                SrvErr       Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: Pre create/modify transactions
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Validate_New_Adj_Trx
   ( pi_trx_id      IN     NUMBER,
     pi_trx_type    IN     VARCHAR2,
     pi_amount      IN     NUMBER,
     pio_Err        IN OUT SrvErr )
IS
    l_log_module          VARCHAR2(240);
    l_SrvErrMsg           SrvErrMsg;
    --
    l_trx_type VARCHAR2(30);
    l_limit    blc_values.number_value%TYPE;
    l_SrvErr   SrvErr;
BEGIN
    blc_log_pkg.initialize(pio_Err);

    l_log_module := C_DEFAULT_MODULE||'.Validate_New_Adj_Trx';
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Validate_New_Adj_Trx');
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_trx_id = '||pi_trx_id);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'pi_trx_type = '||pi_trx_type);
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE,
                               'pi_amount = '||pi_amount);
    IF pi_trx_id IS NOT NULL
        AND pi_trx_type IS NULL
    THEN
        SELECT transaction_type
        INTO l_trx_type
        FROM blc_transactions
        WHERE transaction_id = pi_trx_id;
    ELSE
        l_trx_type := pi_trx_type;
    END IF;
    --
    IF l_trx_type = 'MANUAL_PREMIUM_ADJ'
        AND pi_amount IS NOT NULL
    THEN
        l_limit := blc_common_pkg.Get_Setting_Number_Value( pi_setting_name => 'CustManualTrxMaxAmount',
                                                            pio_ErrMsg      => l_SrvErr );
        --
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE, 'l_limit = '||l_limit);
        --
        IF ABS(pi_amount) > ABS(l_limit)
        THEN
            srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Validate_New_Adj_Trx', 'cust_billing_pkg.VCT.ErrAmnt',pi_amount ||'|'|| l_limit);
            srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                        'The amount of manual transaction '||pi_amount||' must be less than '||l_limit);

        END IF;
    END IF;
    --
    blc_log_pkg.insert_message(l_log_module, C_LEVEL_PROCEDURE,
                               'END of procedure Validate_New_Adj_Trx');
EXCEPTION
    WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_billing_pkg.Validate_New_Adj_Trx', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, SQLERRM);
END Validate_New_Adj_Trx;
--
END CUST_BILLING_PKG;
/