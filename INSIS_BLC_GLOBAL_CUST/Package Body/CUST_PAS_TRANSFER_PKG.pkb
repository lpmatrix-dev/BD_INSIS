CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_PAS_TRANSFER_PKG AS 
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during PAS transfer
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

C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'cust_pas_transfer_pkg';
--==============================================================================

--------------------------------------------------------------------------------
-- Name: cust_pas_transfer_pkg.Pre_Process_Item
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.08.2018  creation
--     Fadata   12.11.2018  changed - LPVS-13 - not allign attrib_4 for CLIENT_IND case
--
-- Purpose:  Procedure is called before Process_Item during policy payment plan
-- transfer to modify some of item attributes
--
-- Input parameters:
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Output parameters:
--     pio_Err         SrvErr       Specifies structure for passing back the
--                                  error code, error TYPE and corresponding
--                                  message.
--
-- Usage: In policy payment plan transefer
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Process_Item ( pio_Err IN OUT SrvErr )
IS
    l_policy_id          NUMBER;
    l_annex_id           NUMBER;
    l_item               blc_items_type;
    l_eng_billing_id     NUMBER;
    l_agreement          blc_items.agreement%TYPE;
    l_policy_level_old   VARCHAR2(30);
    l_policy_level_new   VARCHAR2(30);
    l_log_module         VARCHAR2(240);
    l_count              SIMPLE_INTEGER := 0;
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
      FROM insis_gen_v10.policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND annex_id = x_annex_id;
    --
    CURSOR CgetBillingAnnex_2 (x_policy_id NUMBER, x_annex_id NUMBER) IS
    SELECT eng_billing_id, attr2,
           attr3, attr4, attr5,
           attr6, attr7, attr8
      FROM insis_gen_v10.policy_engagement_billing
     WHERE policy_id = x_policy_id
       AND attr7 IS NOT NULL
     ORDER BY decode(annex_id, x_annex_id, 0, 1), annex_id DESC;
    --
    CURSOR CgetBillingAnnex_3 (x_policy_id NUMBER) IS
    SELECT eng_billing_id,
           attr7
      FROM insis_gen_v10.policy_engagement_billing
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
    --15.08.2018
    l_inward_coins     VARCHAR2(1);
    l_bill_currency    VARCHAR2(3);
    l_source           VARCHAR2(30);
    l_component        VARCHAR2(30);
    --
    CURSOR CGetInwordCoins (pid NUMBER) IS
    SELECT 'x'
      FROM ri_fac
     WHERE policy_id = pid
       AND inout_flag = 'INWARD'
       AND fac_type = 'COINS';
    --
    CURSOR c_item IS
      SELECT bi.item_id
      FROM blc_items bi
      WHERE bi.component = l_component
      AND bi.source = l_source
      AND bi.bill_currency = nvl(l_bill_currency, bi.bill_currency)
      AND bi.item_type = 'POLICY';
    --
    CURSOR c_item_on_acc IS
      SELECT bi.item_id,
             bi.source,
             bi.agreement,
             bi.component,
             bi.legal_entity_id,
             bi.item_type
      FROM blc_items bi
      WHERE bi.item_type = 'ON-ACCOUNT';
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;

    l_log_module := C_DEFAULT_MODULE||'.Pre_Process_Item';
    --
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'BEGIN of procedure Pre_Process_Item');

    IF srv_blc_pas_data.gItemRecord.agreement_type = 'POLICY'
    THEN
       l_policy_id := srv_blc_pas_data.gItemRecord.component;
       l_annex_id := srv_blc_pas_data.gItemRecord.annex;

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'pi_policy_id = '||l_policy_id);
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                 'l_annex_id = '||l_annex_id);

       IF cust_billing_pkg.Is_Master_Policy(l_policy_id) = 'Y'
       THEN
          OPEN c_item_on_acc;
            FETCH c_item_on_acc
            INTO l_item_id,
                 --the next rows can be removed after applying 2.1.5.1
                 --because if item_id is populated in global record it will not be updated
                 srv_blc_pas_data.gItemRecord.source_system,
                 srv_blc_pas_data.gItemRecord.agreement,
                 srv_blc_pas_data.gItemRecord.component,
                 srv_blc_pas_data.gCommonParamsRecord.legal_entity_id,
                 srv_blc_pas_data.gItemRecord.agreement_type;
          CLOSE c_item_on_acc;

          srv_blc_pas_data.gItemRecord.item_id := l_item_id;
       ELSE
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

          l_agreement := cust_billing_pkg.Get_Item_Agreement(l_policy_id, l_annex_id, l_attr7);

          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_STATEMENT,
                                    'l_agreement = '||l_agreement);

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

          IF l_attr7 IN ('CLIENT_GROUP', 'CLIENT_IND', 'CLIENT_IND_DEPEND')
          THEN
             l_master_policy_id := cust_billing_pkg.Get_Master_Policy_Id( l_policy_id );
             l_policy_type := pol_types.get_policy(nvl(l_master_policy_id, l_policy_id));
             l_master_policy_no := l_policy_type.policy_no;
          ELSE
             l_master_policy_no := NULL;
          END IF;

          srv_blc_pas_data.gItemRecord.attrib_1 := l_master_policy_no;

          OPEN CGetInwordCoins (l_policy_id);
            FETCH CGetInwordCoins
            INTO l_inward_coins;
          CLOSE CGetInwordCoins;

          IF l_inward_coins IS NOT NULL
          THEN
             srv_blc_pas_data.gItemRecord.agreement_type := 'AC';
          ELSE
             l_office := srv_blc_pas_data.gItemRecord.issuing_office;

             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_PROCEDURE,
                                        'l_office = '||l_office);

             l_org_id := blc_common_pkg.Get_Billing_Site(l_office,TRUNC(sysdate),l_le_id,pio_Err);

             IF NOT srv_error.rqStatus( pio_Err )
             THEN
                blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                           'pi_office = '||l_office||' - '||
                                           pio_Err(pio_Err.LAST).errmessage);
                RETURN;
             END IF;

             --27.08.2018 -- add to stop execution of billing
             IF l_attr7 IN ('CLIENT_GROUP', 'CLIENT_IND', 'CLIENT_IND_DEPEND') AND l_annex_id = 0 -- add to be sure that not create bill only for policy convert -12.09.2018
             THEN
                srv_blc_pas_data.gCommonParamsRecord.billing_flag := 'N';
             ELSE
                srv_blc_pas_data.gCommonParamsRecord.billing_flag := 'Y';
             END IF;

             srv_blc_pas_data.gItemRecord.agreement := l_agreement;
             srv_blc_pas_data.gItemRecord.attrib_0 := l_org_id;

             l_bill_currency := srv_blc_pas_data.gItemRecord.bill_currency;
             l_source := srv_blc_pas_data.gItemRecord.source_system;
             l_component := srv_blc_pas_data.gItemRecord.component;

             OPEN c_item;
               FETCH c_item
               INTO l_item_id;
             CLOSE c_item;

             IF l_item_id IS NULL
             THEN
                cust_billing_pkg.Calc_Policy_Protocol_Attr
                  ( pi_policy_id       => l_policy_id,
                    po_protocol_flag   => l_protocol_flag,
                    po_protocol_number => l_protocol_number,
                    pio_Err            => pio_Err);

                IF NOT srv_error.rqStatus( pio_Err )
                THEN
                   RETURN;
                END IF;

                srv_blc_pas_data.gItemRecord.attrib_4 := to_char(to_date(l_attr4,'YYYYMMDD'),'YYYY-MM-DD');
                srv_blc_pas_data.gItemRecord.attrib_5 := l_attr5;
                srv_blc_pas_data.gItemRecord.attrib_6 := l_attr2;
                srv_blc_pas_data.gItemRecord.attrib_7 := l_attr7;
                srv_blc_pas_data.gItemRecord.attrib_8 := l_attr8;
                srv_blc_pas_data.gItemRecord.attrib_9 := l_attr3;

                srv_blc_pas_data.gItemRecord.attrib_2 := l_protocol_flag;
                srv_blc_pas_data.gItemRecord.attrib_3 := l_protocol_number;

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
                */
                ELSE
                   l_max_attrib_4 := NULL;
                END IF;

                blc_log_pkg.insert_message(l_log_module,
                                           C_LEVEL_STATEMENT,
                                           'l_max_attrib_4 = '||l_max_attrib_4);

                IF l_max_attrib_4 IS NOT NULL
                THEN
                   srv_blc_pas_data.gItemRecord.attrib_4 := l_max_attrib_4;
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

                -- set with the same item attribute values
                srv_blc_pas_data.gItemRecord.attrib_2 := l_item.attrib_2;
                srv_blc_pas_data.gItemRecord.attrib_3 := l_item.attrib_3;
                srv_blc_pas_data.gItemRecord.attrib_4 := l_item.attrib_4;
                srv_blc_pas_data.gItemRecord.attrib_5 := l_item.attrib_5;
                srv_blc_pas_data.gItemRecord.attrib_6 := l_item.attrib_6;
                srv_blc_pas_data.gItemRecord.attrib_7 := l_item.attrib_7;
                srv_blc_pas_data.gItemRecord.attrib_8 := l_item.attrib_8;
                srv_blc_pas_data.gItemRecord.attrib_9 := l_item.attrib_9;
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
                   IF l_attr4 IS NOT NULL AND l_attr6 IS NOT NULL --annex for change frequency
                   THEN
                      srv_blc_pas_data.gItemRecord.attrib_4 := to_char(to_date(l_attr4,'YYYYMMDD'),'YYYY-MM-DD');
                   END IF;

                   IF l_attr5 IS NOT NULL
                   THEN
                      srv_blc_pas_data.gItemRecord.attrib_5 := l_attr5;
                   END IF;

                   IF l_attr2 IS NOT NULL
                   THEN
                      srv_blc_pas_data.gItemRecord.attrib_6 := l_attr2;
                   END IF;

                   IF l_attr7 IS NOT NULL
                   THEN
                      srv_blc_pas_data.gItemRecord.attrib_7 := l_attr7;

                      l_policy_level_old := cust_billing_pkg.Get_Policy_level(NULL, NULL, l_attr7);
                      l_policy_level_new := cust_billing_pkg.Get_Policy_level(NULL, NULL, l_item.attrib_7);

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
                            srv_error.SetErrorMsg( l_SrvErrMsg, 'cust_pas_transfer_pkg.Pre_Create_Update_Item', 'cust_billing_pkg.PCUI.Exist_On_Acc',l_item_id||'|'||l_item.agreement||'|'||l_agreement);
                            srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
                            blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                                       'Cannot change the agreement! There are on-account applications for target item id '||l_item_id||', old agreement '||l_item.agreement||', new agreement '||l_agreement);
                         END IF;
                      END IF;
                   END IF;

                   srv_blc_pas_data.gItemRecord.attrib_8 := l_attr8;
                   srv_blc_pas_data.gItemRecord.attrib_9 := l_attr3;
                END IF;

                --start 01.10.2018 add update item here, because core process item will get item composite (by agreement, component, detail) and if agreement was changed will create a new item
                --Modify Item
                IF NOT blc_process_pkg.Modify_Item(pi_item_id => l_item_id,
                                                   pi_source => srv_blc_pas_data.gItemRecord.source_system,
                                                   pi_agreement => srv_blc_pas_data.gItemRecord.agreement,
                                                   pi_component => NVL( srv_blc_pas_data.gItemRecord.component, l_item.component ),
                                                   pi_detail => NVL( srv_blc_pas_data.gItemRecord.detail, l_item.detail ),
                                                   pi_item_type => srv_blc_pas_data.gItemRecord.agreement_type,
                                                   pi_party => nvl(srv_blc_pas_data.gItemRecord.policy_holder,srv_blc_pas_data.gAccountRecord.party_id),
                                                   pi_bill_to_site => NULL,
                                                   pi_priority => l_item.priority,
                                                   pi_bill_currency => NVL( srv_blc_pas_data.gItemRecord.bill_currency, l_item.bill_currency ),
                                                   pi_item_name => NVL( srv_blc_pas_data.gItemRecord.item_name, l_item.item_name ),
                                                   pi_le_id => NVL(srv_blc_pas_data.gCommonParamsRecord.legal_entity_id, l_item.legal_entity_id ),
                                                   pi_legal_entity => NULL,
                                                   pi_office => srv_blc_pas_data.gItemRecord.issuing_office,
                                                   pi_insurance_type => srv_blc_pas_data.gItemRecord.insurance_type,
                                                   pi_agent => srv_blc_pas_data.gItemRecord.agent_id,
                                                   pi_mode => l_item.bill_mode,
                                                   pi_retained => NVL( srv_blc_pas_data.gItemRecord.retained, l_item.retained ),
                                                   pi_attrib_0 => NVL( srv_blc_pas_data.gItemRecord.attrib_0, l_item.attrib_0 ),
                                                   pi_attrib_1 => NVL( srv_blc_pas_data.gItemRecord.attrib_1, l_item.attrib_1 ),
                                                   pi_attrib_2 => NVL( srv_blc_pas_data.gItemRecord.attrib_2, l_item.attrib_2 ),
                                                   pi_attrib_3 => NVL( srv_blc_pas_data.gItemRecord.attrib_3, l_item.attrib_3 ),
                                                   pi_attrib_4 => NVL( srv_blc_pas_data.gItemRecord.attrib_4, l_item.attrib_4 ),
                                                   pi_attrib_5 => NVL( srv_blc_pas_data.gItemRecord.attrib_5, l_item.attrib_5 ),
                                                   pi_attrib_6 => NVL( srv_blc_pas_data.gItemRecord.attrib_6, l_item.attrib_6 ),
                                                   pi_attrib_7 => NVL( srv_blc_pas_data.gItemRecord.attrib_7, l_item.attrib_7 ),
                                                   pi_attrib_8 => NVL( srv_blc_pas_data.gItemRecord.attrib_8, l_item.attrib_8 ),
                                                   pi_attrib_9 => NVL( srv_blc_pas_data.gItemRecord.attrib_9, l_item.attrib_9 ),
                                                   pi_policy_no => NVL( srv_blc_pas_data.gItemRecord.policy_no, l_item.policy_no ),
                                                   pi_engagement_no => NVL( srv_blc_pas_data.gItemRecord.engagement_no, l_item.engagement_no),
                                                   pio_Err => pio_Err )
                THEN
                   RETURN;
                END IF;

                srv_blc_pas_data.gItemRecord.item_id := l_item_id;
                --end 01.10.2018
             END IF;
          END IF;
       END IF;
    END IF;
    blc_log_pkg.insert_message(l_log_module,
                               C_LEVEL_PROCEDURE,
                              'END of procedure Pre_Process_Item');
EXCEPTION
    WHEN OTHERS THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pas_transfer_pkg.Pre_Process_Item', SQLERRM );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
        blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_policy_id = '||l_policy_id||' - '|| SQLERRM);
END Pre_Process_Item;

--------------------------------------------------------------------------------
-- Name: cust_pas_transfer_pkg.Pre_Process_Installments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   16.08.2018  creation
--     Fadata   31.07.2019 - populate attrib_0 with agent_id
--                           policy_payment_plan(attrn2) - LPV-2000
--     Fadata   09.01.2020 - LPV-2429 office_id(attrib_1) to be removed from
--      blc_installments and stored at blc_transactions at the moment of billing
--
-- Purpose:  Procedure is called before Process_Installments during policy
-- payment plan transfer to modify some of installment attributes
--
-- Input parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Usage: In policy payment plan transfer
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Pre_Process_Installments( pio_Err IN OUT SrvErr )
IS
    l_log_module VARCHAR2(240);
    l_SrvErrMsg  SrvErrMsg;
    l_count      SIMPLE_INTEGER := 0;
    l_inst_date  DATE;
    l_policy_id  NUMBER;
    l_annex_id   NUMBER;
    l_external_id NUMBER; -- J_LAP85_312,CSR282	
    --
    l_bc_pol_pay_plan_rec bc_policy_pay_plan_type;
    l_annex_reason_rec    p_annex_reason_type;-- J_LAP85_312,CSR282	
BEGIN
    blc_log_pkg.initialize(pio_Err);
    --
    l_log_module := C_DEFAULT_MODULE||'.Pre_Process_Installments';
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'BEGIN of procedure '|| l_log_module );
    -- Check installments
    SELECT COUNT(*)
    INTO l_count
    FROM TABLE(srv_blc_pas_data.gInstallmentsTable);

    IF l_count <> 0 AND srv_blc_pas_data.gItemRecord.agreement_type = 'POLICY'
    THEN
       l_bc_pol_pay_plan_rec := NEW bc_policy_pay_plan_type;

       l_policy_id := srv_blc_pas_data.gItemRecord.component;

       FOR i IN srv_blc_pas_data.gInstallmentsTable.FIRST..srv_blc_pas_data.gInstallmentsTable.LAST
       LOOP
          IF srv_blc_pas_data.gInstallmentsTable(i).installment_type IN ('BCPR', 'BCTAX',
                                                                         'BCISSUETAX') --03.07.2019 --Phase 2
          THEN
             IF l_inst_date IS NULL OR l_inst_date <> srv_blc_pas_data.gInstallmentsTable(i).installment_date OR
                l_annex_id IS NULL OR l_annex_id <> NVL(srv_blc_pas_data.gInstallmentsTable(i).annex, srv_blc_pas_data.gItemRecord.annex)
             THEN
                l_inst_date := srv_blc_pas_data.gInstallmentsTable(i).installment_date;
                l_annex_id := NVL(srv_blc_pas_data.gInstallmentsTable(i).annex, srv_blc_pas_data.gItemRecord.annex);
				l_external_id := srv_blc_pas_data.gInstallmentsTable(i).external_id;--J_LAP85_312,CSR282
                l_annex_reason_rec := insis_gen_v10.pol_types.get_annexreason_by_annex(l_policy_id, l_annex_id);--J_LAP85_312,CSR282

                --l_bc_pol_pay_plan_rec := cust_policy.GetAlign_Params_PayPlan_BLC (l_policy_id, l_annex_id, l_inst_date, pio_Err); --J_LAP85_312 commented
				
				-- J_LAP85_312,CSR282
                IF l_annex_reason_rec.annex_reason IN (insis_cust.gvar_cust.AnnexReason_CHANFREQ,'CHANFREQ')--J_LAP85_312, CSR282, to work both with CHNGFRQ and CHANFREQ
                THEN
                    l_bc_pol_pay_plan_rec := insis_cust.cust_blc_modifications.Align_Params_PayPlan_CHANFREQ (l_external_id,l_policy_id, l_annex_id, l_inst_date, pio_Err);
                ELSE
                    l_bc_pol_pay_plan_rec := cust_policy.GetAlign_Params_PayPlan_BLC (l_policy_id, l_annex_id, l_inst_date, pio_Err);
                END IF;
                -- J_LAP85_312,CSR282
				
             END IF;
             --
             /* Comment 09.01.2020 LPV-2429
             --03.07.2019 --Phase 2
             srv_blc_pas_data.gInstallmentsTable(i).attrib_1 := l_bc_pol_pay_plan_rec.attr1; --office for group billing per office --LPV-2102
             */
             --
             srv_blc_pas_data.gInstallmentsTable(i).attrib_4 := l_bc_pol_pay_plan_rec.attr4;
             srv_blc_pas_data.gInstallmentsTable(i).attrib_5 := l_bc_pol_pay_plan_rec.attr5;

             srv_blc_pas_data.gInstallmentsTable(i).attrib_0 := l_bc_pol_pay_plan_rec.attrn2; --LPV-2000
          END IF;
       END LOOP;
    END IF;

    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure '|| l_log_module );
EXCEPTION
   WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, l_log_module, SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                 'Error in' || l_log_module||' - '||SQLERRM);
END Pre_Process_Installments;

--------------------------------------------------------------------------------
-- Name: blc_pas_transfer_installs_pkg.Compensate_Item_Installments
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  12.09.2018 - copy from core and add order by installment_id
--                          to compensate firstly created
--                          LPV-1768
--     Fadate  31.07.2019 - call specific compensation - LPV-2000
--
-- Purpose: Compensate similar installments for given item id
--
-- Actions:
--  1) Get and lock installments records for compensation;
--  2) Loops over collection, retrieve similar installments and reserve their ids
--  3) Mark reserved installments as compensated.
--
-- Input parameters:
--     pi_item_id           NUMBER     Required item id parameter
--     pio_Err              SrvErr     Specifies structure for passing back
--                                     the error code, error TYPE and
--                                     corresponding message.
--
-- Output parameters:
--     pio_Err              SrvErr       Specifies structure for passing back
--                                       the error code, error TYPE and
--                                       corresponding message.
--
-- Usage: This procedure is called by policy payment plan transfer.
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Compensate_Item_Installments( pio_Err    IN OUT SrvErr )
IS
    l_item_id     blc_items.item_id%TYPE;
    l_log_module      VARCHAR2(240);
    l_SrvErrMsg       SrvErrMsg;
    l_cnt             SIMPLE_INTEGER := 0;
    l_similar_install blc_installments.installment_id%TYPE;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    --
    l_log_module := C_DEFAULT_MODULE||'.Compensate_Item_Installments';
    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'BEGIN of procedure '|| l_log_module);

    l_item_id := srv_blc_pas_data.gItemRecord.item_id;

    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'l_item_id = '||l_item_id );

    IF l_item_id IS NULL
    THEN
       RETURN;
    END IF;

    cust_billing_pkg.Comp_Item_Installments_Norm
                               ( pi_item_id =>  l_item_id,
                                 pio_Err    =>  pio_Err);

    blc_log_pkg.insert_message( l_log_module,
                                C_LEVEL_PROCEDURE,
                                'END of procedure '|| l_log_module);
END Compensate_Item_Installments;

--------------------------------------------------------------------------------
-- Name: cust_pas_transfer_pkg.Create_Installment
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata  12.01.2020 - copy from core and add check to not create
--                          installment with zero amount
--                          LPV-2514
--
-- Purpose: Function inserts installment
--
-- Input parameters:
--     pi_item_id          NUMBER        Unique identifier of billing item
--     pi_account_id       NUMBER        Unique identifier of account
--     pi_date             DATE          Installment date (due date)
--     pi_currency         VARCHAR2(3)   Installment currency
--     pi_amount           NUMBER(18,4)  Installment amount
--     pi_anniversary      NUMBER(3,0)   Consequtive year number of the agreement
--                                       lifecycle
--     pi_postprocess      VARCHAR2(30)  Postprocess speciality
--     pi_rec_rate_date    DATE          Date of the revenue/expense recognition
--     pi_policy_office    VARCHAR2(30)  Office Id when the policy is issued
--     pi_activity_office  VARCHAR2(30)  Office Id when the activity is done
--     pi_insurance_type   VARCHAR2(30)  Insurance type
--     pi_policy           VARCHAR2(30)  Policy Id
--     pi_annex            VARCHAR2(30)  Annex Id
--     pi_lob              VARCHAR2(30)  Line of business
--     pi_fraction_type    VARCHAR2(30)  Fraction type
--     pi_agent            VARCHAR2(30)  Agent Id
--     pi_claim            VARCHAR2(30)  Claim Id
--     pi_claim_request    VARCHAR2(30)  Claim request Id
--     pi_treaty           VARCHAR2(30)  Treaty Id
--     pi_adjustment       VARCHAR2(30)  Adjustment Id
--     pi_type             VARCHAR2(30)  Installment type
--     pi_command          VARCHAR2(30)  Procedure for installment distribution
--                                       'STD' -  non distributed
--                                       'UNPAID' - should be distributed between
--                                        non paid installments
--                                       'ONTIME' - should be distributed by time
--                                       'UNIFORM' - should be distributed on
--                                       pieces specified in parameter pieces
--                                       between isnatllment date and end date
--                                       specified in parameter end date
--     pi_pieces           NUMBER        Count of installments for 'UNIFORM'
--                                       ditribution
--     pi_end_date         DATE          End date for 'UNIFORM' distribution
--     pi_run_id           NUMBER        Mark installment for already created
--                                       empty billing_run
--     pi_attrib_0         VARCHAR2(120) Additional information
--     pi_attrib_1         VARCHAR2(120) Additional information
--     pi_attrib_2         VARCHAR2(120) Additional information
--     pi_attrib_3         VARCHAR2(120) Additional information
--     pi_attrib_4         VARCHAR2(120) Additional information
--     pi_attrib_5         VARCHAR2(120) Additional information
--     pi_attrib_6         VARCHAR2(120) Additional information
--     pi_attrib_7         VARCHAR2(120) Additional information
--     pi_attrib_8         VARCHAR2(120) Additional information
--     pi_attrib_9         VARCHAR2(120) Additional information
--     pi_external_id      VARCHAR2(30)  External_Id - insurance system reference
--     pi_batch            VARCHAR2(30)  Claims batch
--     pi_split_flag       VARCHAR2(1)   Split flag
--     pi_notes            VARCHAR2(120 CHAR) Notes
--     pi_sequence_order   VARCHAR2(1)   Sequence order
--     pio_Err             SrvErr        Specifies structure for passing back the
--                                       error code, error TYPE and corresponding
--                                       message.
--
-- Output parameters:
--     pio_Err             SrvErr        Specifies structure for passing back the
--                                       error code, error TYPE and corresponding
--                                       message.
--
-- Returns:
-- FALSE - When operation cannot be procesed.
-- TRUE  - In case of successful operation.
--
-- Usage: When create a installment
--
-- Exceptions:
-- 1) when Insert_Installment fails
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
FUNCTION Create_Installment
   (pi_item_id          IN     NUMBER,
    pi_account_id       IN     NUMBER,
    pi_date             IN     DATE,
    pi_currency         IN     VARCHAR2,
    pi_amount           IN     NUMBER,
    pi_anniversary      IN     NUMBER,
    pi_postprocess      IN     VARCHAR2,
    pi_rec_rate_date    IN     DATE,
    pi_policy_office    IN     VARCHAR2,
    pi_activity_office  IN     VARCHAR2,
    pi_insurance_type   IN     VARCHAR2,
    pi_policy           IN     VARCHAR2,
    pi_annex            IN     VARCHAR2,
    pi_lob              IN     VARCHAR2,
    pi_fraction_type    IN     VARCHAR2,
    pi_agent            IN     VARCHAR2,
    pi_claim            IN     VARCHAR2,
    pi_claim_request    IN     VARCHAR2,
    pi_treaty           IN     VARCHAR2,
    pi_adjustment       IN     VARCHAR2,
    pi_type             IN     VARCHAR2,
    pi_command          IN     VARCHAR2,
    pi_pieces           IN     NUMBER,
    pi_end_date         IN     DATE,
    pi_run_id           IN     NUMBER,
    pi_attrib_0         IN     VARCHAR2,
    pi_attrib_1         IN     VARCHAR2,
    pi_attrib_2         IN     VARCHAR2,
    pi_attrib_3         IN     VARCHAR2,
    pi_attrib_4         IN     VARCHAR2,
    pi_attrib_5         IN     VARCHAR2,
    pi_attrib_6         IN     VARCHAR2,
    pi_attrib_7         IN     VARCHAR2,
    pi_attrib_8         IN     VARCHAR2,
    pi_attrib_9         IN     VARCHAR2,
    pi_external_id      IN     VARCHAR2,
    pi_batch            IN     VARCHAR2,
    pi_split_flag       IN     VARCHAR2,
    pi_notes            IN     VARCHAR2,
    pi_sequence_order   IN     VARCHAR2,
    pio_Err             IN OUT SrvErr )
RETURN BOOLEAN
IS
   CURSOR c_inst (x_amount IN NUMBER,
                  x_inst_type IN VARCHAR2,
                  x_inst_date IN DATE,
                  x_rec_rate_date IN DATE,
                  x_fract_type IN VARCHAR2) IS
     SELECT installment_id
     FROM blc_installments
     WHERE account_id + 0 = pi_account_id
     AND item_id = pi_item_id
     AND currency = pi_currency
     AND installment_type = x_inst_type
     AND TRUNC(installment_date) = TRUNC(x_inst_date)
     AND ((rec_rate_date IS NULL AND x_rec_rate_date IS NULL) OR TRUNC(rec_rate_date) = TRUNC(x_rec_rate_date))
     AND nvl(lob, blc_gvar_process.FLG_CHAR_999) = nvl(pi_lob, blc_gvar_process.FLG_CHAR_999)
     AND nvl(fraction_type, blc_gvar_process.FLG_CHAR_999) = nvl(x_fract_type, blc_gvar_process.FLG_CHAR_999)
    -- AND status = 'N' --rq 1000009102
     AND compensated = blc_gvar_process.FLG_NO
     AND billing_run_id IS NULL
     AND abs(amount) = abs(x_amount)
     AND sign(amount) <> sign(x_amount)
     AND installment_class NOT IN (blc_gvar_process.INSTALLMENT_CLASS_R, blc_gvar_process.INSTALLMENT_CLASS_E)
     FOR UPDATE; --rq 1000011245

   l_inst            BLC_INSTALLMENTS_TYPE;
   l_inst_upd        BLC_INSTALLMENTS_TYPE;
   l_inst_id         blc_installments.installment_id%type;
   l_log_module      VARCHAR2(240);
   l_org_id          blc_orgs.org_id%type;
   l_SrvErrMsg       SrvErrMsg;
   l_inst_class      VARCHAR2(30);
   l_inst_amount     blc_installments.amount%type;
   l_rec_rate_type   VARCHAR2(30);
   l_le_id           blc_orgs.org_id%type;
   l_lookup_id       blc_lookups.lookup_id%type;
   l_sign            SIMPLE_INTEGER := 0;
   --
   l_default_post_process VARCHAR2(30);
   l_item            BLC_ITEMS_TYPE;
   l_dist_le_flag    VARCHAR2(1);
   l_count_le        SIMPLE_INTEGER := 0;
   --
   l_run             blc_run_type;
   l_account         blc_accounts_type;
   l_SrvErr          SrvErr;
   l_OpSt            BOOLEAN := TRUE;
BEGIN
   l_log_module := C_DEFAULT_MODULE||'.Create_Installment';
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'BEGIN of function Create_Installment');
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_item_id = '||pi_item_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_account_id = '||pi_account_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_date = '||to_char(pi_date,'dd-mm-yyyy'));
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_currency = '||pi_currency);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_amount = '||pi_amount);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_anniversary = '||pi_anniversary);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_postprocess = '||pi_postprocess);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_rec_rate_date = '||to_char(pi_rec_rate_date,'dd-mm-yyyy'));
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_policy_office = '||pi_policy_office);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_activity_office = '||pi_activity_office);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_insurance_type = '||pi_insurance_type);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_policy = '||pi_policy);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_annex = '||pi_annex);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_lob = '||pi_lob);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_fraction_type = '||pi_fraction_type);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_agent = '||pi_agent);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_claim = '||pi_claim);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_claim_request = '||pi_claim_request);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_treaty = '||pi_treaty);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_adjustment = '||pi_adjustment);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_type = '||pi_type);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_command = '||pi_command);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_pieces = '||pi_pieces);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_end_date = '||to_char(pi_end_date,'dd-mm-yyyy'));
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_run_id = '||pi_run_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_0 = '||pi_attrib_0);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_1 = '||pi_attrib_1);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_2 = '||pi_attrib_2);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_3 = '||pi_attrib_3);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_4 = '||pi_attrib_4);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_5 = '||pi_attrib_5);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_6 = '||pi_attrib_6);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_7 = '||pi_attrib_7);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_8 = '||pi_attrib_8);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_attrib_9 = '||pi_attrib_9);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_external_id = '||pi_external_id);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_batch = '||pi_batch);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_split_flag = '||pi_split_flag);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_notes = '||pi_notes);
   blc_log_pkg.insert_message(l_log_module,
                              C_LEVEL_PROCEDURE,
                              'pi_sequence_order = '||pi_sequence_order);

   IF pi_amount <> 0
   THEN
       IF pi_run_id IS NOT NULL
       THEN
          l_run := NEW blc_run_type( pi_run_id, pio_Err);

          IF l_run.status = blc_gvar_process.RUN_STATUS_C
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Complete_Billing_Run', 'blc_billing_pkg.CBR.Compl_Status' );
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          END IF;

          IF l_run.status <> blc_gvar_process.RUN_STATUS_I
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_billing_pkg.Complete_Billing_Run', 'blc_billing_pkg.CBR.Different_Status' );
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          END IF;
       END IF;

       IF pi_activity_office IS NULL
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','blc_process_pkg.CInst.No_ActOffice');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;

       IF pi_item_id IS NULL
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','CheckBLCInstallmentsRecord_No_ItemId');
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;

       --l_org_id := blc_common_pkg.Get_Org_Id_Office(pi_activity_office,pio_Err);
       l_org_id := blc_common_pkg.Get_Billing_Site(pi_activity_office,TRUNC(sysdate),l_le_id,pio_Err);

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_org_id = '||l_org_id);

       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_le_id = '||l_le_id);

       IF l_org_id IS NULL
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','blc_process_pkg.CInst.MissBillOrg',pi_activity_office );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;

       -- get item variable
       l_item := blc_items_type(pi_item_id, l_SrvErr);

       IF NOT srv_error.rqStatus(l_SrvErr)
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, l_log_module, 'blc_pas_transfer.Trans.InvalidItemId', pi_item_id);
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;

       IF l_le_id IS NULL
       THEN
          SELECT count(*)
          INTO l_count_le
          FROM blc_org_roles bor
          WHERE bor.org_id = l_org_id
          AND TRUNC(sysdate) BETWEEN TRUNC( bor.from_date ) AND TRUNC( NVL( bor.to_date, sysdate ) )
          AND blc_common_pkg.get_lookup_code(bor.lookup_id) = blc_gvar_process.ORG_ROLES_BILLING
          AND bor.legal_entity_id = l_item.legal_entity_id;

          IF l_count_le = 0
          THEN
             l_dist_le_flag := blc_gvar_process.FLG_YES;
          END IF;
       ELSE
          IF l_le_id <> l_item.legal_entity_id
          THEN
             l_dist_le_flag := blc_gvar_process.FLG_YES;
          END IF;
       END IF;

       IF l_dist_le_flag = blc_gvar_process.FLG_YES
       THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','blc_process_pkg.CInst.InvAcivityOffice',pi_activity_office||'|'||l_item.legal_entity_id );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
       END IF;

       l_le_id := l_item.legal_entity_id;

       -- rq 1000009319
       IF pi_account_id IS NOT NULL
       THEN
          l_SrvErr := NULL;
          l_account := NEW blc_accounts_type(pi_account_id, l_SrvErr);

          IF NOT srv_error.rqStatus( l_SrvErr )
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','blc_process_pkg.CInst.InvalidAccountId', pi_account_id );
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          END IF;

          SELECT count(*)
          INTO l_count_le
          FROM blc_org_roles bor
          WHERE bor.org_id = l_account.billing_site_id
          AND TRUNC(sysdate) BETWEEN TRUNC( bor.from_date ) AND TRUNC( NVL( bor.to_date, sysdate ) )
          AND blc_common_pkg.get_lookup_code(bor.lookup_id) = blc_gvar_process.ORG_ROLES_BILLING
          AND bor.legal_entity_id = l_item.legal_entity_id;

          IF l_count_le = 0
          THEN
             srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','blc_process_pkg.CInst.InvOrg',l_account.billing_site_id||'|'||l_item.legal_entity_id );
             srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          END IF;
       END IF;
       -- rq 1000009319

       l_default_post_process := blc_common_pkg.Get_Setting_Lookup_Value
                                          ( blc_gvar_process.S_DEFAULT_POST_PROCESS,
                                            pio_Err,
                                            l_org_id,
                                            trunc(SYSDATE));

       --get installment class, recognition rate type and verify installment type
       IF pi_type IS NOT NULL
       THEN
          l_lookup_id := blc_common_pkg.Get_Lookup_Value_Id
                                ( pi_lookup_name => blc_gvar_process.LS_INSTALLMENT_TYPES,
                                  pi_lookup_code => pi_type,
                                  pio_ErrMsg     => pio_Err);
          --
          BEGIN
             SELECT tag_0, nvl(tag_1,blc_gvar_process.CURRENCY_RATE_TYPES_FIXING), blc_process_pkg.Get_Sign_Inst_Amount(tag_0,tag_2)
             INTO l_inst_class, l_rec_rate_type, l_sign
             FROM blc_lookups
             WHERE lookup_id = l_lookup_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                srv_error.SetErrorMsg( l_SrvErrMsg, 'blc_process_pkg.Create_Installment','blc_process_pkg.CInst.InvalidInstType',pi_type );
                srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
          END;

          --check if need to convert installment amount if destination is
          --different from installment class
          l_inst_amount := pi_amount*l_sign;
          blc_log_pkg.insert_message(l_log_module,
                                     C_LEVEL_PROCEDURE,
                                    'l_inst_amount = '||l_inst_amount);
       END IF;
       --
       --verify currency
       IF pi_currency IS NOT NULL
       THEN
          l_lookup_id := blc_common_pkg.Get_Lookup_Value_Id
                                ( pi_lookup_name => blc_gvar_process.LS_CURRENCIES,
                                  pi_lookup_code => pi_currency,
                                  pio_ErrMsg     => pio_Err);
       END IF;

       l_OpSt := srv_error.rqStatus(pio_Err);
       --
       l_inst := blc_installments_type;
       l_inst.item_id := pi_item_id;
       l_inst.account_id := pi_account_id;
       l_inst.installment_date := TRUNC(pi_date);
       l_inst.currency := pi_currency;
       l_inst.rec_rate_date := TRUNC(pi_rec_rate_date);
       l_inst.policy_office := nvl(pi_policy_office, pi_activity_office);
       l_inst.activity_office := pi_activity_office;
       l_inst.insurance_type := pi_insurance_type;
       l_inst.policy := pi_policy;
       l_inst.annex := pi_annex;
       l_inst.lob := pi_lob;
       l_inst.fraction_type := pi_fraction_type;
       l_inst.agent := pi_agent;
       l_inst.claim := pi_claim;
       l_inst.claim_request := pi_claim_request;
       l_inst.treaty := pi_treaty;
       l_inst.adjustment := pi_adjustment;
       l_inst.installment_type := pi_type;
       l_inst.billing_run_id := pi_run_id;
       l_inst.org_id := l_org_id;
       l_inst.legal_entity := l_le_id;
       l_inst.attrib_0 := pi_attrib_0;
       l_inst.attrib_1 := pi_attrib_1;
       l_inst.attrib_2 := pi_attrib_2;
       l_inst.attrib_3 := pi_attrib_3;
       l_inst.attrib_4 := pi_attrib_4;
       l_inst.attrib_5 := pi_attrib_5;
       l_inst.attrib_6 := pi_attrib_6;
       l_inst.attrib_7 := pi_attrib_7;
       l_inst.attrib_8 := pi_attrib_8;
       l_inst.attrib_9 := pi_attrib_9;
       l_inst.installment_class := l_inst_class;
       l_inst.rec_rate_type := l_rec_rate_type;
       l_inst.amount := l_inst_amount;
       l_inst.sequence_order := NVL(pi_sequence_order, blc_gvar_process.INST_SEQ_ORDER_S);
       l_inst.external_id := pi_external_id;
       l_inst.command := NVL(pi_command, blc_gvar_process.INST_COMMAND_STD);
       l_inst.batch := pi_batch;
       l_inst.split_flag := pi_split_flag;
       l_inst.notes := pi_notes;
       l_inst.anniversary := pi_anniversary;
       l_inst.postprocess := NVL(pi_postprocess, l_default_post_process);

       --calculate compensated flag
       l_inst.compensated := blc_gvar_process.FLG_NO;
       IF l_inst.amount = 0
       THEN
          l_inst.compensated := blc_gvar_process.FLG_YES;
       ELSE
          OPEN c_inst(l_inst.amount,
                      l_inst.installment_type,
                      l_inst.installment_date,
                      l_inst.rec_rate_date,
                      l_inst.fraction_type);
            FETCH c_inst
            INTO l_inst_id;
          CLOSE c_inst;

          IF l_inst_id IS NOT NULL
          THEN
             l_inst_upd := NEW blc_installments_type(l_inst_id, pio_Err );

             l_inst_upd.compensated := blc_gvar_process.FLG_YES;

             -- Update installment
             IF l_OpSt
             THEN
                l_OpSt := l_inst_upd.update_blc_installments(pio_Err);
             END IF;

             blc_log_pkg.insert_message(l_log_module,
                                        C_LEVEL_STATEMENT,
                                        'Updated compensated installment_id = '|| l_inst_id );

             l_inst.compensated := blc_gvar_process.FLG_YES;
          END IF;
       END IF;

       -- Insert installment
       IF l_OpSt
       THEN
          l_OpSt := l_inst.insert_blc_installments( pio_Err );
       END IF;

       IF NOT srv_error.rqStatus( pio_Err )
       THEN
          FOR i IN 1..pio_Err.COUNT
          LOOP
             blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                       'pi_item_id = '||pi_item_id||' - '||
                                        pio_Err(i).errmessage);
          END LOOP;
       END IF;
       --
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'Created installment_id = '||l_inst.installment_id);
   ELSE
       blc_log_pkg.insert_message(l_log_module,
                                  C_LEVEL_STATEMENT,
                                 'Installment is not created');
   END IF;

   blc_log_pkg.insert_message(l_log_module,
                             C_LEVEL_PROCEDURE,
                             'END of function Create_Installment');
   RETURN l_OpSt;
EXCEPTION
  WHEN OTHERS THEN
     srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_pas_transfer_pkg.Create_Installment', SQLERRM );
     srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
     blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                                'pi_item_id = '||pi_item_id||' - '||SQLERRM);
     RETURN FALSE;
END Create_Installment;
--
END CUST_PAS_TRANSFER_PKG;
/

