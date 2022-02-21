CREATE OR REPLACE PACKAGE BODY INSIS_BLC_GLOBAL_CUST.CUST_COLL_UTIL_PKG AS
--------------------------------------------------------------------------------
  C_LEVEL_STATEMENT     CONSTANT NUMBER := 1;
  C_LEVEL_PROCEDURE     CONSTANT NUMBER := 2;
  C_LEVEL_EVENT         CONSTANT NUMBER := 3;
  C_LEVEL_EXCEPTION     CONSTANT NUMBER := 4;
  C_LEVEL_ERROR         CONSTANT NUMBER := 5;
  C_LEVEL_UNEXPECTED    CONSTANT NUMBER := 6;

  C_DEFAULT_MODULE      CONSTANT VARCHAR2(240) := 'CUST_COLL_UTIL_PKG';
--------------------------------------------------------------------------------
  FUNCTION Get_Amount_FC ( pi_amount IN NUMBER,
                           pi_amount_currency IN VARCHAR2,
                           pi_fc_currency IN VARCHAR2,
                           pi_fc_precision IN NUMBER,
                           pi_country IN VARCHAR2,
                           pi_rate_date IN DATE,
                           pi_rate_type IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_currency_rate NUMBER;
    l_amount_fc NUMBER;
    l_SrvErr SrvErr;
    l_log_module VARCHAR2(240);
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Get_Amount_FC';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of function Get_Amount_FC' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_amount = ' || pi_amount );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_amount_currency = ' || pi_amount_currency );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_fc_currency = ' || pi_fc_currency );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_fc_precision = ' || pi_fc_precision );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_country = ' || pi_country );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate_date = ' || pi_rate_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate_type = ' || pi_rate_type );

      IF pi_amount_currency = pi_fc_currency
      THEN
          l_amount_fc := pi_amount;
      ELSE
          l_currency_rate := BLC_COMMON_PKG.Get_Currency_Rate
                                        ( pi_amount_currency,
                                          pi_fc_currency,
                                          pi_country,
                                          pi_rate_date,
                                          pi_rate_type,
                                          l_SrvErr
                                        );

          IF NOT srv_error.rqStatus( l_SrvErr )
          THEN
              blc_log_pkg.insert_message( l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'from_currency = ' || pi_amount_currency || ' - ' ||
                                          'to_currency = ' || pi_fc_currency || ' - ' ||
                                          'country = ' || pi_country || ' - ' ||
                                          'pi_rate_date = ' || pi_rate_date || ' - ' ||
                                          'pi_rate_type = ' || pi_rate_type || ' - ' ||
                                          l_SrvErr(l_SrvErr.FIRST).errmessage );
          END IF;

          l_amount_fc := ROUND( pi_amount * l_currency_rate, pi_fc_precision );
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of function Get_Amount_FC' );

      RETURN( l_amount_fc );
  END;

--------------------------------------------------------------------------------
-- Name: BLC_OPEN_BAL_STAT_PKG.Create_Ntf_Header
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.06.2014  creation
--
-- Purpose: The procedure creates a notification document
--
-- Input parameters:
-- pi_legal_entity_id           NUMBER           Legal entity ID
-- pi_org_id                    NUMBER           Organization ID
-- pi_doc_type_id               NUMBER           Document type ID
-- pi_issue_date                DATE             Issue date
-- pi_party_site                VARCHAR2         Party site identificator
-- pi_due_date                  DATE             Due Date
-- pi_reference                 VARCHAR2         Reference
-- pi_coll_level                NUMBER           Collection level
--  pio_Err                     SrvErr           Specifies structure for
--                                               passing back the error
--                                               code, error TYPE and
--                                               corresponding message.
--
-- Output parameters:
--  po_doc_id                   NUMBER           Newly created notification
--                                               document ID
--  pio_Err                     SrvErr           Specifies structure for
--                                               passing back the error
--                                               code, error TYPE and
--                                               corresponding message.
--
-- Returns:
-- N/A
--
-- Usage: In bad debt collections process
--
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Create_Ntf_Header ( pi_legal_entity_id IN NUMBER,
                                pi_org_id IN NUMBER,
                                pi_doc_type_id IN NUMBER,
                                pi_issue_date IN DATE,
                                pi_party_site IN VARCHAR2,
                                pi_due_date IN DATE,
                                pi_reference IN VARCHAR2,
                                pi_coll_level IN NUMBER,
                                po_doc_id OUT NUMBER,
                                pio_Err IN OUT SrvErr
                                )
  IS
    l_nt_doc_rec BLC_DOCUMENTS_TYPE;

    l_number NUMBER;

    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Create_Ntf_Header';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Create_Ntf_Header' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_org_id = ' || pi_org_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_doc_type_id = ' || pi_doc_type_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_issue_date = ' || pi_issue_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_party_site = ' || pi_party_site );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_due_date = ' || pi_due_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_reference = ' || pi_reference );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_coll_level = ' || pi_coll_level );


      l_nt_doc_rec := NEW BLC_DOCUMENTS_TYPE;

      l_nt_doc_rec.legal_entity_id := pi_legal_entity_id;
      l_nt_doc_rec.org_site_id := pi_org_id;
      l_nt_doc_rec.party_site := pi_party_site;
      l_nt_doc_rec.doc_class := 'N';
      l_nt_doc_rec.doc_type_id := pi_doc_type_id;
      l_nt_doc_rec.issue_date := pi_issue_date;
      l_nt_doc_rec.due_date := pi_due_date;
      l_nt_doc_rec.reference := pi_reference;
      l_nt_doc_rec.collection_level := pi_coll_level;
      l_nt_doc_rec.direction := 'N';
      l_nt_doc_rec.status := 'O';

      IF NOT l_nt_doc_rec.insert_blc_documents( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_EXCEPTION,
                                      'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                      'pi_org_id = ' || pi_org_id || ' - ' ||
                                      'pi_doc_type_id = ' || pi_doc_type_id || ' - ' ||
                                      'pi_issue_date = ' || pi_issue_date || ' - ' ||
                                      'pi_party_site = ' || pi_party_site || ' - ' ||
                                      'pi_due_date = ' || pi_due_date || ' - ' ||
                                      'pi_reference = ' || pi_reference || ' - ' ||
                                      'pi_coll_level = ' || pi_coll_level || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          RETURN;
      END IF;

      po_doc_id := l_nt_doc_rec.doc_id;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Create_Ntf_Header' );
  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Create_Ntf_Header', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_EXCEPTION,
                                 'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                 'pi_org_id = ' || pi_org_id || ' - ' ||
                                 'pi_doc_type_id = ' || pi_doc_type_id || ' - ' ||
                                 'pi_issue_date = ' || pi_issue_date || ' - ' ||
                                 'pi_party_site = ' || pi_party_site || ' - ' ||
                                 'pi_due_date = ' || pi_due_date || ' - ' ||
                                 'pi_reference = ' || pi_reference || ' - ' ||
                                 'pi_coll_level = ' || pi_coll_level || ' - ' ||
                                 SQLERRM );
  END Create_Ntf_Header;

--------------------------------------------------------------------------------
-- Name: BLC_OPEN_BAL_STAT_PKG.Add_Ntf_Transaction
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   03.06.2014  creation
--
-- Purpose: The procedure creates a notification transaction and assignes it to
-- previously created notification document
--
-- Input parameters:
-- pi_nt_doc_id                 NUMBER          Previously created notification
--                                              document ID
-- pi_rel_doc_id                NUMBER          Related document ID
-- pi_trx_date                  DATE            Transaction date
-- pi_due_date                  DATE            Due date
-- pi_open_balance              NUMBER          Open balance of the related document
-- pi_paid_status               VARCHAR2        Paid status of the related document
-- pi_legal_entity_id           NUMBER          Legal entity ID
-- pi_org_id                    NUMBER          Organization ID
-- pi_item_id                   NUMBER          Item ID
-- pi_item_name                 VARCHAR2        Item name
-- pi_currency                  VARCHAR2        Currency
-- pi_account_id                NUMBER          Account Identificator
-- pi_notes                     VARCHAR2        Document number of the related
--                                              document
-- pi_rate                      NUMBER          Currency rate
-- pi_rate_date                 DATE            Currency rate date
-- pi_rate_type                 VARCHAR2        Currency rate type
-- pi_open_balance_fc           NUMBER          Open balance of the related
--                                              document in func. currency
-- pi_fc_currency               VARCHAR2        Functional currency
-- pio_Err                      SrvErr          Specifies structure for
--                                              passing back the error
--                                              code, error TYPE and
--                                              corresponding message.
--
-- Output parameters:
--  pio_Err                     SrvErr          Specifies structure for
--                                              passing back the error
--                                              code, error TYPE and
--                                              corresponding message.
--
-- Returns:
-- N/A
--
-- Usage: In bad debt collections process
--
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Add_Ntf_Transaction( pi_nt_doc_id IN NUMBER,
                                 pi_rel_doc_id IN NUMBER,
                                 pi_trx_date IN DATE,
                                 pi_due_date IN DATE,
                                 pi_open_balance IN NUMBER,
                                 pi_paid_status IN VARCHAR2,
                                 pi_legal_entity_id IN NUMBER,
                                 pi_org_id IN NUMBER,
                                 pi_item_id IN NUMBER,
                                 pi_item_name IN VARCHAR2,
                                 pi_currency IN VARCHAR2,
                                 pi_account_id IN NUMBER,
                                 pi_notes IN VARCHAR2,
                                 pi_rate IN NUMBER,
                                 pi_rate_date IN DATE,
                                 pi_rate_type IN VARCHAR2,
                                 pi_open_balance_fc IN NUMBER,
                                 pi_fc_currency IN VARCHAR2,
                                 pio_Err IN OUT SrvErr )
  IS
    l_notification_trx BLC_TRANSACTIONS_TYPE;

    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Add_Ntf_Transaction';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Add_Ntf_Transaction' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_nt_doc_id = ' || pi_nt_doc_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rel_doc_id = ' || pi_rel_doc_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_trx_date = ' || pi_trx_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_due_date = ' || pi_due_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_open_balance = ' || pi_open_balance );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_paid_status = ' || pi_paid_status );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_org_id = ' || pi_org_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_item_id = ' || pi_item_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_item_name = ' || pi_item_name );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_currency = ' || pi_currency );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_notes = ' || pi_notes );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate = ' || pi_rate );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate_date = ' || pi_rate_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate_type = ' || pi_rate_type );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_open_balance_fc = ' || pi_open_balance_fc );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_fc_currency = ' || pi_fc_currency );


      l_notification_trx := NEW blc_transactions_type;

      l_notification_trx.transaction_class := 'N';
      l_notification_trx.transaction_type := 'NOTIFICATION';
      l_notification_trx.transaction_date := pi_trx_date;
      l_notification_trx.currency := pi_currency;
      l_notification_trx.item_name := pi_item_name;
      l_notification_trx.account_id := pi_account_id;
      l_notification_trx.item_id := pi_item_id;
      l_notification_trx.amount := pi_open_balance;
      l_notification_trx.notes := pi_notes;
      l_notification_trx.due_date := pi_due_date;
      l_notification_trx.grace := pi_due_date;
      l_notification_trx.legal_entity := pi_legal_entity_id;
      l_notification_trx.org_id := pi_org_id;
      l_notification_trx.doc_id := pi_nt_doc_id;
      l_notification_trx.ref_doc_id := pi_rel_doc_id;
      l_notification_trx.status := 'V';
      l_notification_trx.open_balance := pi_open_balance;
      l_notification_trx.paid_status := pi_paid_status;

      l_notification_trx.fc_currency := pi_fc_currency;
      l_notification_trx.rate := pi_rate;
      l_notification_trx.rate_date := pi_rate_date;
      l_notification_trx.rate_type := pi_rate_type;
      l_notification_trx.fc_amount := pi_open_balance_fc;


      IF NOT l_notification_trx.insert_blc_transactions( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_EXCEPTION,
                                      'pi_nt_doc_id = ' || pi_nt_doc_id || ' - ' ||
                                      'pi_rel_doc_id = ' || pi_rel_doc_id || ' - ' ||
                                      'pi_trx_date = ' || pi_trx_date || ' - ' ||
                                      'pi_due_date = ' || pi_due_date || ' - ' ||
                                      'pi_open_balance = ' || pi_open_balance || ' - ' ||
                                      'pi_paid_status = ' || pi_paid_status || ' - ' ||
                                      'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                      'pi_org_id = ' || pi_org_id || ' - ' ||
                                      'pi_item_id = ' || pi_item_id || ' - ' ||
                                      'pi_item_name = ' || pi_item_name || ' - ' ||
                                      'pi_currency = ' || pi_currency || ' - ' ||
                                      'pi_account_id = ' || pi_account_id || ' - ' ||
                                      'pi_notes = ' || pi_notes || ' - ' ||
                                      'pi_rate = ' || pi_rate || ' - ' ||
                                      'pi_rate_date = ' || pi_rate_date || ' - ' ||
                                      'pi_rate_type = ' || pi_rate_type || ' - ' ||
                                      'pi_open_balance_fc = ' || pi_open_balance_fc || ' - ' ||
                                      'pi_fc_currency = ' || pi_fc_currency || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          RETURN;
      END IF;


      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Add_Ntf_Transaction' );

  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Add_Ntf_Transaction', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message(l_log_module,
                                 C_LEVEL_EXCEPTION,
                                 'pi_nt_doc_id = ' || pi_nt_doc_id || ' - ' ||
                                 'pi_rel_doc_id = ' || pi_rel_doc_id || ' - ' ||
                                 'pi_trx_date = ' || pi_trx_date || ' - ' ||
                                 'pi_due_date = ' || pi_due_date || ' - ' ||
                                 'pi_open_balance = ' || pi_open_balance || ' - ' ||
                                 'pi_paid_status = ' || pi_paid_status || ' - ' ||
                                 'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                 'pi_org_id = ' || pi_org_id || ' - ' ||
                                 'pi_item_id = ' || pi_item_id || ' - ' ||
                                 'pi_item_name = ' || pi_item_name || ' - ' ||
                                 'pi_currency = ' || pi_currency || ' - ' ||
                                 'pi_account_id = ' || pi_account_id || ' - ' ||
                                 'pi_notes = ' || pi_notes || ' - ' ||
                                 'pi_rate = ' || pi_rate || ' - ' ||
                                 'pi_rate_date = ' || pi_rate_date || ' - ' ||
                                 'pi_rate_type = ' || pi_rate_type || ' - ' ||
                                 'pi_open_balance_fc = ' || pi_open_balance_fc || ' - ' ||
                                 'pi_fc_currency = ' || pi_fc_currency || ' - ' ||
                                 SQLERRM );
  END Add_Ntf_Transaction;

--------------------------------------------------------------------------------
  PROCEDURE Create_Ntf_Document ( pi_legal_entity_id IN NUMBER,
                                  pi_org_id IN NUMBER,
                                  pi_agreement IN VARCHAR2,
                                  pi_account_id IN NUMBER,
                                  pi_doc_id IN NUMBER,  -- added on 07.11.2016
                                  pi_bill_to_site IN VARCHAR2,
                                  pi_issue_date IN DATE,
                                  pi_due_date IN DATE,
                                  pi_coll_event_id IN NUMBER,
                                  pi_collection_level IN NUMBER,
                                  pi_fc_currency IN VARCHAR2,
                                  pi_fc_precision IN NUMBER,
                                  pi_country IN VARCHAR2,
                                  pi_rate_date IN DATE,
                                  pi_rate_type IN VARCHAR2,
                                  pi_ntf_doc_type_id IN NUMBER,
                                  po_ntf_doc_id OUT VARCHAR2,
                                  pio_Err IN OUT SrvErr )
  IS
    CURSOR documents ( x_legal_entity_id IN NUMBER,
                       x_agreement IN VARCHAR2,
                       x_account_id IN NUMBER,
                       x_doc_id IN NUMBER ) -- added on 07.11.2016

    IS SELECT bd.doc_id, bt.currency, bt.account_id,
              NVL2( bd.doc_prefix, bd.doc_prefix || '-', NULL) || bd.doc_number || NVL2( bd.doc_suffix, '-' || bd.doc_suffix, NULL ) doc_number,
              SUM ( bt.open_balance ) open_balance, MAX( bt.paid_status ) paid_status,
              bi.item_id, bi.item_name, bi.component, bi.agreement
             -- LISTAGG (bt.transaction_id, ',') WITHIN GROUP (ORDER BY bt.transaction_id) bill_trx_list  comment 17.01.2018
       FROM blc_documents bd,
            blc_transactions bt,
            blc_accounts ba,
            blc_items bi
       WHERE bd.doc_id = NVL( x_doc_id, bd.doc_id ) -- added on 07.11.2016
         AND bd.doc_id = bt.doc_id
         AND bt.legal_entity = NVL( x_legal_entity_id, bt.legal_entity )
         AND bt.account_id = ba.account_id
         AND bt.item_id = bi.item_id
         AND bi.agreement = NVL( x_agreement, bi.agreement )
         AND bt.account_id = NVL( x_account_id, bt.account_id )
         --AND NVL( bi.attrib_0, 'N' ) = 'N' --hold_flag
         AND bd.doc_class = 'B'
         AND bt.transaction_class = 'B'
         AND bt.status NOT IN ( 'C', 'R', 'D' )
         AND bt.paid_status IN ( 'N', 'P' )
       GROUP BY bd.doc_id, bt.currency, bt.account_id,
                NVL2( bd.doc_prefix, bd.doc_prefix || '-', NULL) || bd.doc_number || NVL2( bd.doc_suffix, '-' || bd.doc_suffix, NULL ),
                bi.item_id, bi.item_name, bi.component, bi.agreement
       HAVING SUM ( bt.open_balance ) > 0;
       --ORDER BY bt.doc_id;

    l_log_module VARCHAR2(240);
    l_err_message VARCHAR2(2000);
    l_exp_error EXCEPTION;
    l_SrvErrMsg SrvErrMsg;

    l_ntf_doc_id NUMBER;
    l_rate NUMBER;
    l_rate_date DATE;
    l_rate_type VARCHAR2(30);
    l_open_balance_fc NUMBER;
    l_notes VARCHAR2(4000);
    l_min_currency VARCHAR2(3);
    l_max_currency VARCHAR2(3);
    l_ntf_doc_amount NUMBER;

    l_nt_doc_rec BLC_DOCUMENTS_TYPE;

  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Create_Ntf_Document';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Create_Ntf_Document' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_org_id = ' || pi_org_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_doc_id = ' || pi_doc_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_bill_to_site = ' || pi_bill_to_site );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_issue_date = ' || pi_issue_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_due_date = ' || pi_due_date );


      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_coll_event_id = ' || pi_coll_event_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_collection_level = ' || pi_collection_level );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_fc_currency = ' || pi_fc_currency );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_fc_precision = ' || pi_fc_precision );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_country = ' || pi_country );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate_date = ' || pi_rate_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_rate_type = ' || pi_rate_type );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_ntf_doc_type_id = ' || pi_ntf_doc_type_id );






      FOR doc IN documents ( pi_legal_entity_id,
                             pi_agreement,
                             pi_account_id,
                             pi_doc_id )
      LOOP

          IF l_ntf_doc_id IS NULL
          THEN
              Create_Ntf_Header ( pi_legal_entity_id,
                                  pi_org_id,
                                  pi_ntf_doc_type_id,
                                  pi_issue_date,
                                  pi_bill_to_site,
                                  pi_due_date,
                                  pi_coll_event_id,
                                  pi_collection_level,
                                  l_ntf_doc_id,
                                  pio_Err );

              IF NOT srv_error.rqStatus( pio_Err )
              THEN
                  blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                        'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                        'pi_org_id = ' || pi_org_id || ' - ' ||
                        'pi_ntf_doc_type_id = ' || pi_ntf_doc_type_id || ' - ' ||
                        'pi_issue_date = ' || pi_issue_date || ' - ' ||
                        'pi_bill_to_site = ' || pi_bill_to_site || ' - ' ||
                        'pi_due_date = ' || pi_due_date || ' - ' ||
                        'pi_coll_event_id = ' || pi_coll_event_id || ' - ' ||
                        'pi_collection_level = ' || pi_collection_level || ' - ' ||
                        pio_Err(pio_Err.FIRST).errmessage );

                  l_err_message := pio_Err(pio_Err.FIRST).errmessage;
                  RAISE l_exp_error;
              END IF;

              blc_log_pkg.insert_message( l_log_module,
                                          C_LEVEL_PROCEDURE,
                                          'OK1 - l_ntf_doc_id = ' || l_ntf_doc_id );
          END IF;

          IF doc.currency = pi_fc_currency
          THEN
              l_rate := NULL;
              l_rate_date := NULL;
              l_rate_type := NULL;
              l_open_balance_fc := doc.open_balance;
          ELSE
              l_rate := BLC_COMMON_PKG.Get_Currency_Rate
                                        ( doc.currency,
                                          pi_fc_currency,
                                          pi_country,
                                          pi_rate_date,
                                          pi_rate_type,
                                          pio_Err
                                        );

              IF NOT srv_error.rqStatus( pio_Err )
              THEN
                  blc_log_pkg.insert_message( l_log_module,
                                              C_LEVEL_EXCEPTION,
                                              'doc.currency = ' || doc.currency || ' - ' ||
                                              'pi_fc_currency = ' || pi_fc_currency || ' - ' ||
                                              'pi_country = ' || pi_country || ' - ' ||
                                              'pi_rate_date = ' || pi_rate_date || ' - ' ||
                                              'pi_rate_type = ' || pi_rate_type || ' - ' ||
                                              pio_Err(pio_Err.FIRST).errmessage );

                  l_err_message := pio_Err(pio_Err.FIRST).errmessage;
                  RAISE l_exp_error;
              END IF;

              l_rate_date := pi_rate_date;
              l_rate_type := pi_rate_type;
              l_open_balance_fc := ROUND( doc.open_balance * l_rate, pi_fc_precision );
          END IF;


          Add_Ntf_Transaction( l_ntf_doc_id,
                               doc.doc_id,
                               pi_issue_date,
                               pi_due_date,
                               doc.open_balance,
                               doc.paid_status,
                               pi_legal_entity_id,
                               pi_org_id,
                               doc.item_id,
                               doc.doc_number || ' / ' || doc.item_name,
                               doc.currency,
                               doc.account_id,
                               NULL, -- doc.bill_trx_list,
                               l_rate,
                               l_rate_date,
                               l_rate_type,
                               l_open_balance_fc,
                               pi_fc_currency,
                               pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                        'l_ntf_doc_id = ' || l_ntf_doc_id || ' - ' ||
                        'doc.doc_id = ' || doc.doc_id || ' - ' ||
                        'pi_issue_date = ' || pi_issue_date || ' - ' ||
                        'pi_due_date = ' || pi_due_date || ' - ' ||
                        'doc.open_balance = ' || doc.open_balance || ' - ' ||
                        'doc.paid_status = ' || doc.paid_status || ' - ' ||
                        'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                        'pi_org_id = ' || pi_org_id || ' - ' ||
                        'doc.item_id = ' || doc.item_id || ' - ' ||
                        'doc.item_name = ' || doc.item_name || ' - ' ||
                        'doc.currency = ' || doc.currency || ' - ' ||
                        'doc.account_id = ' || doc.account_id || ' - ' ||
                        'doc.doc_number = ' || doc.doc_number || ' - ' ||
                        'l_rate = ' || l_rate || ' - ' ||
                        'l_rate_date = ' || l_rate_date || ' - ' ||
                        'l_rate_type = ' || l_rate_type || ' - ' ||
                        'l_open_balance_fc = ' || l_open_balance_fc || ' - ' ||
                        'pi_fc_currency = ' || pi_fc_currency || ' - ' || pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;

      END LOOP; --documents

      IF l_ntf_doc_id IS NOT NULL
      THEN
          l_notes :=     'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                         'pi_org_id = ' || pi_org_id || '; ' ||
                         'pi_agreement = ' || pi_agreement || '; ' ||
                         'pi_account_id = ' || pi_account_id || '; ' ||
                         'pi_bill_to_site = ' || pi_bill_to_site || '; ' ||
                         'pi_issue_date = ' || pi_issue_date || '; ' ||
                         'pi_due_date = ' || pi_due_date || '; ' ||
                         'pi_coll_event_id = ' || pi_coll_event_id || '; ' ||
                         'pi_collection_level = ' || pi_collection_level || '; ' ||
                         'pi_fc_currency = ' || pi_fc_currency || '; ' ||
                         'pi_fc_precision = ' || pi_fc_precision || '; ' ||
                         'pi_country = ' || pi_country || '; ' ||
                         'pi_rate_date = ' || pi_rate_date || '; ' ||
                         'pi_rate_type = ' || pi_rate_type || '; ' ||
                         'pi_ntf_doc_type_id = ' || pi_ntf_doc_type_id;

          BLC_DOC_UTIL_PKG.Insert_Action ( pi_action_type => 'OB_NTF',
                                           pi_notes => l_notes,
                                           pi_status => 'S',
                                           pi_doc_id => l_ntf_doc_id,
                                           pio_Err => pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                         'OB_NTF Action - ' ||
                         'l_ntf_doc_id = ' || l_ntf_doc_id || ' - ' ||pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;

          l_nt_doc_rec := NEW BLC_DOCUMENTS_TYPE ( l_ntf_doc_id );

          SELECT MIN( currency ), MAX( currency )
          INTO l_min_currency, l_max_currency
          FROM blc_transactions
          WHERE doc_id = l_ntf_doc_id;

          IF l_min_currency = l_max_currency
          THEN
              SELECT SUM ( amount )
              INTO l_ntf_doc_amount
              FROM blc_transactions
              WHERE doc_id = l_ntf_doc_id;

              l_nt_doc_rec.amount := l_ntf_doc_amount;
              l_nt_doc_rec.currency := l_min_currency;

          ELSE
              SELECT SUM ( fc_amount )
              INTO l_ntf_doc_amount
              FROM blc_transactions
              WHERE doc_id = l_ntf_doc_id;

              l_nt_doc_rec.amount := l_ntf_doc_amount;
              l_nt_doc_rec.currency := pi_fc_currency;
          END IF;

          IF NOT l_nt_doc_rec.update_blc_documents ( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                         'l_ntf_doc_id = ' || l_ntf_doc_id || ' - ' ||
                         'l_ntf_doc_amount = ' || l_ntf_doc_amount || ' - ' ||
                         'pi_fc_currency = ' || pi_fc_currency || ' - ' ||
                         pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;

          BLC_DOC_UTIL_PKG.Complete_Documents ( l_ntf_doc_id,
                                                pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                         'l_ntf_doc_id = ' || l_ntf_doc_id || ' - ' ||pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;

      END IF;

      po_ntf_doc_id := l_ntf_doc_id;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Create_Ntf_Document' );
  EXCEPTION
    WHEN l_exp_error THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Create_Ntf_Document', l_err_message );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_org_id = ' || pi_org_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  'pi_bill_to_site = ' || pi_bill_to_site || '; ' ||
                                  'pi_issue_date = ' || pi_issue_date || '; ' ||
                                  'pi_due_date = ' || pi_due_date || '; ' ||
                                  'pi_coll_event_id = ' || pi_coll_event_id || '; ' ||
                                  'pi_collection_level = ' || pi_collection_level || '; ' ||
                                  'pi_fc_currency = ' || pi_fc_currency || '; ' ||
                                  'pi_fc_precision = ' || pi_fc_precision || '; ' ||
                                  'pi_country = ' || pi_country || '; ' ||
                                  'pi_rate_date = ' || pi_rate_date || '; ' ||
                                  'pi_rate_type = ' || pi_rate_type || '; ' ||
                                  'pi_ntf_doc_type_id = ' || pi_ntf_doc_type_id || '; ' ||
                                  l_err_message );
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Create_Ntf_Document', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_org_id = ' || pi_org_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  'pi_bill_to_site = ' || pi_bill_to_site || '; ' ||
                                  'pi_issue_date = ' || pi_issue_date || '; ' ||
                                  'pi_due_date = ' || pi_due_date || '; ' ||
                                  'pi_coll_event_id = ' || pi_coll_event_id || '; ' ||
                                  'pi_collection_level = ' || pi_collection_level || '; ' ||
                                  'pi_fc_currency = ' || pi_fc_currency || '; ' ||
                                  'pi_fc_precision = ' || pi_fc_precision || '; ' ||
                                  'pi_country = ' || pi_country || '; ' ||
                                  'pi_rate_date = ' || pi_rate_date || '; ' ||
                                  'pi_rate_type = ' || pi_rate_type || '; ' ||
                                  'pi_ntf_doc_type_id = ' || pi_ntf_doc_type_id || '; ' ||
                                  SQLERRM );
  END Create_Ntf_Document;

--------------------------------------------------------------------------------
PROCEDURE Cancel_Policies ( pi_cancel_date IN DATE,
                             pi_legal_entity_id IN NUMBER,
                             pi_agreement IN VARCHAR2,
                             pi_account_id IN NUMBER,
                             pi_collection_level IN NUMBER,
                             pi_next_event_date IN DATE,
                             pi_next_event_id IN NUMBER,
                             pio_Err IN OUT SrvErr )
  IS
    CURSOR policies_for_cancelling ( x_legal_entity_id IN NUMBER,
                                     x_agreement IN VARCHAR2,
                                     x_account_id IN NUMBER )

    IS SELECT bi.item_id, bi.component
       FROM blc_items bi
       WHERE bi.item_type = 'POLICY'
         AND bi.agreement = x_agreement
         --AND bi.status <> 'N'
         AND bi.status <> 'H'
         AND EXISTS ( SELECT 'TRX'
                      FROM blc_transactions bt
                      WHERE bt.item_id = bi.item_id
                        AND bt.account_id = NVL( x_account_id, bt.account_id ) -- added on 17.01.2018
                        AND bt.legal_entity = x_legal_entity_id )
         /*AND EXISTS ( SELECT 'BETWEEN'  -- added on 16.01.2017
                      FROM policy pol
                      WHERE pol.policy_id = bi.component
                        AND pi_cancel_date BETWEEN pol.insr_begin AND pol.insr_end );*/

        AND EXISTS ( SELECT 'LESS'  -- added on 26.01.2017
                      FROM policy pol
                      WHERE pol.policy_id = bi.component
                        AND pi_cancel_date <= pol.insr_end );

    CURSOR rel_documents ( x_legal_entity_id IN NUMBER,
                           x_agreement IN VARCHAR2,
                           x_account_id IN NUMBER )

    IS SELECT bd.doc_id
       FROM blc_documents bd,
            blc_transactions bt,
            --blc_accounts ba,
            blc_items bi
       WHERE bd.doc_id = bt.doc_id
         AND bt.legal_entity = NVL( x_legal_entity_id, bt.legal_entity )
         --AND bt.account_id = ba.account_id
         AND bt.item_id = bi.item_id
         AND bi.agreement = x_agreement
         AND bt.account_id = NVL( x_account_id, bt.account_id ) -- added on 17.01.2018
         AND bd.doc_class = 'B'
         AND bt.transaction_class = 'B'
         AND bt.status NOT IN ( 'C', 'R', 'D' )
         AND bt.paid_status IN ( 'N', 'P' )
       GROUP BY bd.doc_id
       HAVING SUM ( bt.open_balance ) > 0;
       --ORDER BY bt.doc_id;

    l_log_module VARCHAR2(240);

    l_err_message VARCHAR2(2000);
    l_exp_error EXCEPTION;
    l_SrvErrMsg SrvErrMsg;

    l_count NUMBER;

    l_Context srvcontext;
    l_RetContext srvcontext;

    l_item_rec BLC_ITEMS_TYPE;
    l_rel_doc_rec BLC_DOCUMENTS_TYPE;
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Cancel_Policies';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Cancel_Policies' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_cancel_date = ' || pi_cancel_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_collection_level = ' || pi_collection_level );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_next_event_date = ' || pi_next_event_date );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_next_event_id = ' || pi_next_event_id );

      l_count := 0;

      RETURN; -- 19.01.2018

      FOR pfc IN policies_for_cancelling ( pi_legal_entity_id,
                                           pi_agreement,
                                           pi_account_id )
      LOOP
          l_Context := NULL;
          l_RetContext := NULL;

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK1 - pfc.component = ' || pfc.component );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK2 - pfc.item_id = ' || pfc.item_id );

          srv_context.SetContextAttrNumber( l_Context, 'POLICY_ID', srv_context.Integers_Format, pfc.component );
          srv_context.SetContextAttrDate ( l_Context, 'CANCEL_DATE', srv_context.Date_Format, pi_cancel_date );
          srv_context.SetContextAttrChar( l_Context, 'LAPSE_VALUE', 'LAPSE' );

          srv_events.sysEvent( 'BLC_TO_PAS_PREM_OVERDUE', l_Context, l_RetContext, pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              FOR i IN 1..pio_Err.COUNT
              LOOP
                  blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                              'pfc.component = ' || pfc.component || ' - ' ||
                                              'pi_cancel_date = ' || pi_cancel_date || ' - ' ||
                                              pio_Err(i).errmessage );

                  l_err_message := l_err_message || pio_Err(i).errmessage || '; ';

              END LOOP;

              RAISE l_exp_error;
          END IF;


          l_item_rec := NEW blc_items_type( pfc.item_id, pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                          'pfc.item_id = ' || pfc.item_id || ' - ' ||
                                          pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;

          --l_item_rec.status := 'N';
          l_item_rec.status := 'H';

          IF NOT l_item_rec.update_blc_items ( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                          'pfc.item_id = ' || pfc.item_id || ' - ' ||
                                          pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;

          l_count := l_count + 1;
      END LOOP;

    /*  FOR rd IN rel_documents ( pi_legal_entity_id,
                                pi_agreement,
                                pi_account_id )
      LOOP
          l_rel_doc_rec := NULL;

          l_rel_doc_rec := NEW BLC_DOCUMENTS_TYPE ( rd.doc_id );

          l_rel_doc_rec.collection_level := pi_collection_level;
          l_rel_doc_rec.attrib_0 := TO_CHAR( pi_next_event_date, 'dd-mm-yyyy' );
          l_rel_doc_rec.attrib_2 := pi_next_event_id;

          IF NOT l_rel_doc_rec.update_blc_documents( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                          'l_rel_doc_rec.doc_id = '|| l_rel_doc_rec.doc_id || ' - '||
                                          'pi_collection_level = '|| pi_collection_level ||' - '||
                                          'pi_next_event_date = '|| pi_next_event_date ||' - '||
                                          'pi_next_event_id = '|| pi_next_event_id ||' - '||
                                          pio_Err(pio_Err.FIRST).errmessage);

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;
      END LOOP; */


      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Cancel_Policies' );

  EXCEPTION
    WHEN l_exp_error THEN
      --srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Cancel_Policies', l_err_message );
      --srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_cancel_date = ' || pi_cancel_date || '; ' ||
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  'pi_collection_level = '|| pi_collection_level ||'; '||
                                  'pi_next_event_date = '|| pi_next_event_date ||'; '||
                                  'pi_next_event_id = '|| pi_next_event_id ||'; '||
                                  l_err_message );
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Cancel_Policies', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_cancel_date = ' || pi_cancel_date || '; ' ||
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  'pi_collection_level = '|| pi_collection_level ||'; '||
                                  'pi_next_event_date = '|| pi_next_event_date ||'; '||
                                  'pi_next_event_id = '|| pi_next_event_id ||'; '||
                                  SQLERRM );
  END Cancel_Policies;

--------------------------------------------------------------------------------
/* Comment LAP85-66
FUNCTION Chek_Policy_Cancel( pi_component IN VARCHAR2 ) RETURN VARCHAR
IS
    l_state  NUMBER;
BEGIN
    SELECT policy_state INTO l_state
    FROM policy
    WHERE policy_id = TO_NUMBER(pi_component);
    --
    IF l_state = 30
    THEN
       RETURN 'N';
    END IF;
    --
    RETURN 'Y';
    --
EXCEPTION WHEN OTHERS THEN RETURN 'N';
END; */

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Chek_Policy_Cancel
--
-- Type: FUNCTION
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   15.12.2020   LAP85-66 comment the old function and add new logic
--              29.04.2021   add protocol_flag
--
-- Purpose: If policy is canceled from other annex we will not start a new
-- cancellation process. Add new - not cancel if the policy correspond at some
-- of the parameters in the new custom table
--
-- Input parameters:
--     pi_policy_id    NUMBER     Policy Id (required)
--     pi_date         DATE       Current Date (required)
--
-- Returns: Cancel flag - Y / N
--
-- Usage: In pkg
-- When you need to check data in table insis_cust.cust_blc_bdc_cancel_params
--------------------------------------------------------------------------------
FUNCTION Chek_Policy_Cancel( pi_policy_id IN     NUMBER,
                             pi_date      IN     DATE,
                             pio_Err      IN OUT SrvErr ) RETURN VARCHAR
IS
    l_SrvErrMsg      SrvErrMsg;
    --
    l_state           policy.policy_state%TYPE;
    l_insr_type       policy.insr_type%TYPE;
    l_office_id       policy.office_id%TYPE;
    l_lob             policy.product_lob%TYPE;
    l_tech_branch     policy.attr1%TYPE;
    l_sales_channel   policy.attr3%TYPE;
    l_pay_way         VARCHAR2(30);
    l_master_policy   blc_items.attrib_1%TYPE;
    l_protocol_flag   blc_items.attrib_2%TYPE;
    l_benef_flag      VARCHAR2(1);
    --
    l_cancel_flag   VARCHAR2(1) := 'Y';
    l_count         SIMPLE_INTEGER := 0;
    --
    CURSOR cur_pay_way IS
    SELECT payment_way
    FROM policy_engagement_billing
    WHERE policy_id = pi_policy_id
        AND pi_date BETWEEN TRUNC(valid_from) AND NVL(TRUNC(valid_to), pi_date)
    ORDER BY valid_from, annex_id DESC;
BEGIN
    SELECT policy_state,
        insr_type, office_id, NVL(product_lob,'-9999'), NVL(attr1,'-9999'), NVL(attr3,'-9999')
    INTO l_state,
        l_insr_type, l_office_id, l_lob, l_tech_branch, l_sales_channel
    FROM policy
    WHERE policy_id = pi_policy_id;
    --
    IF l_state = 30
    THEN
       l_cancel_flag := 'N';
    ELSE
        SELECT NVL(attrib_1,'-9999') AS master_policy, NVL(attrib_2,'N') AS protocol_flag
        INTO l_master_policy, l_protocol_flag
        FROM blc_items
        WHERE item_type = 'POLICY'
            AND component = TO_CHAR(pi_policy_id)
            AND ROWNUM = 1;
        --
        OPEN cur_pay_way;
        FETCH cur_pay_way INTO l_pay_way;
        CLOSE cur_pay_way;
        --
        l_pay_way := NVL(l_pay_way,'-9999');
        --
        SELECT DECODE( SIGN(COUNT(*)), 1, 'Y', 'N' ) INTO l_benef_flag
        FROM policy_participants
        WHERE policy_id = pi_policy_id
            AND particpant_role = 'FINBENEF'
            AND pi_date BETWEEN valid_from AND NVL(valid_to,pi_date);
        --
        SELECT COUNT(*) INTO l_count
        FROM insis_cust.cust_blc_bdc_cancel_params
        WHERE ( policy_id IS NULL OR policy_id = pi_policy_id )
            AND ( master_policy_no IS NULL OR master_policy_no = l_master_policy )
            AND ( cond_type IS NULL OR cond_type IN ( SELECT cond_type
                                                      FROM policy_conditions
                                                      WHERE policy_id = pi_policy_id ) )
            AND ( finbenef_role IS NULL OR finbenef_role = l_benef_flag )
            AND ( product_lob IS NULL OR product_lob = l_lob )
            AND ( technical_branch IS NULL OR technical_branch = l_tech_branch )
            AND ( business_channel IS NULL OR business_channel = l_sales_channel )
            AND ( insr_type IS NULL OR insr_type = l_insr_type )
            AND ( as_is_code IS NULL OR as_is_code IN ( SELECT cond_dimension --cond_type ?
                                                        FROM policy_conditions
                                                        WHERE policy_id = pi_policy_id
                                                            AND cond_type LIKE 'AS_IS%' ) )
            AND ( office_id IS NULL OR office_id = l_office_id )
            AND ( agent_id IS NULL OR agent_id IN ( SELECT agent_id
                                                    FROM policy_agents
                                                    WHERE policy_id =  pi_policy_id
                                                        AND pi_date BETWEEN valid_from AND NVL(valid_to,pi_date) ) )
            AND ( premium_payer_id IS NULL OR premium_payer_id IN ( SELECT man_id
                                                                    FROM policy_participants
                                                                    WHERE policy_id = pi_policy_id
                                                                       AND particpant_role = 'PAYOR'
                                                                       AND pi_date BETWEEN valid_from AND NVL(valid_to,pi_date) ) )
            AND ( pay_way IS NULL OR pay_way = l_pay_way )
            AND ( protocol_flag IS NULL OR protocol_flag = l_protocol_flag );
        --
        IF l_count > 0
        THEN
            l_cancel_flag := 'N';
            srv_error.SetErrorMsg(l_SrvErrMsg, 'cust_coll_util_pkg.Chek_Policy_Cancel','cust_coll_util_pkg.CPC.NoCancel' );
            srv_error.SetErrorMsg(l_SrvErrMsg, pio_Err);
        END IF;
    END IF;
    --
    RETURN l_cancel_flag;
    --
EXCEPTION WHEN OTHERS THEN RETURN 'N';
END;

--------------------------------------------------------------------------------
PROCEDURE Cancel_Policies_Doc( pi_doc_id           IN     NUMBER,
                               pi_cancel_date      IN     DATE,
                               pi_collection_level IN     NUMBER,
                               pi_next_event_date  IN     DATE,
                               pi_next_event_id    IN     NUMBER,
                               pio_Err             IN OUT SrvErr )
IS
    CURSOR policies_for_cancelling IS
    SELECT bi.component, bi.agreement
    FROM blc_transactions bt,
         blc_items bi
    WHERE bt.doc_id = pi_doc_id
        AND bt.item_id = bi.item_id
        AND bi.item_type = 'POLICY'
        AND bi.status <> 'N'
        AND bt.status NOT IN ( 'C', 'R', 'D' )
        AND EXISTS ( SELECT 'LESS'  -- renewval policy?
                     FROM policy pol
                     WHERE pol.policy_id = bi.component
                         AND pi_cancel_date <= pol.insr_end )
        AND bi.insurance_type <> '2008'  -- add 19.01.2018
        AND NVL(bt.attrib_8,'Y') <> 'N' --LPV-1965 -exclude policies marked witn N for auto cancel
    GROUP BY bi.component, bi.agreement
    ORDER BY bi.component;
    --
    CURSOR rel_documents( x_agreement  IN VARCHAR2 ) IS
    SELECT bd.doc_id
    FROM blc_documents bd,
        blc_transactions bt,
        blc_items bi
    WHERE bd.doc_id = bt.doc_id
        AND bt.item_id = bi.item_id
        AND bi.agreement = x_agreement
        AND bd.doc_class = 'B'
        AND bt.transaction_class = 'B'
        AND bt.status NOT IN ( 'C', 'R', 'D' )
        AND blc_doc_util_pkg.Get_Doc_Open_Balance( bd.doc_id, bd.currency, NULL ) > 0
        AND bd.doc_id <> pi_doc_id
        AND bi.insurance_type <> '2008'  -- add 19.01.2018
        AND NVL(bt.attrib_8,'Y') <> 'N' --LPV-1965 -exclude policies marked witn N for auto cancel
    GROUP BY bd.doc_id
    ORDER BY bd.doc_id;
    --
    l_log_module  VARCHAR2(240);
    l_SrvErrMsg   SrvErrMsg;
    --
    l_Context     srvcontext;
    l_RetContext  srvcontext;
    --
    l_agreement   VARCHAR2(50);
    l_rel_doc_rec BLC_DOCUMENTS_TYPE;
    --
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Cancel_Policies_Doc';
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Cancel_Policies_Doc' );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_doc_id = ' || pi_doc_id );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_cancel_date = ' || TO_CHAR( pi_cancel_date, 'DD-MM-YYYY' ) );
    --
    IF pi_doc_id IS NULL
    THEN RETURN;
    END IF;
    --
    FOR pfc IN policies_for_cancelling
    LOOP
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'component = ' || pfc.component );
        --
        IF Chek_Policy_Cancel( TO_NUMBER(pfc.component), pi_cancel_date, pio_Err ) = 'Y'  -- LAP85-66 add param date
        THEN
            l_Context := NULL;
            l_RetContext := NULL;
            --
            srv_context.SetContextAttrNumber( l_Context, 'POLICY_ID', srv_context.Integers_Format, TO_NUMBER(pfc.component) );
            srv_context.SetContextAttrDate ( l_Context, 'CANCEL_DATE', srv_context.Date_Format, pi_cancel_date );
            srv_context.SetContextAttrChar( l_Context, 'LAPSE_VALUE', 'LAPSE' );
            --
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'Begin start event BLC_TO_PAS_PREM_OVERDUE'
                                        || ' policy = ' || pfc.component || ' cancel_date = ' || TO_CHAR( pi_cancel_date, 'DD-MM-YYYY' ) );
            --
            srv_events.sysEvent( 'BLC_TO_PAS_PREM_OVERDUE', l_Context, l_RetContext, pio_Err );
            --
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'End event BLC_TO_PAS_PREM_OVERDUE' );
            --
            IF NOT srv_error.rqStatus( pio_Err )
            THEN
                FOR i IN 1..pio_Err.COUNT
                LOOP
                    blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pfc.component = ' || pfc.component || ' - ' ||
                                                'pi_cancel_date = ' || TO_CHAR( pi_cancel_date, 'DD-MM-YYYY' ) || ' - ' || pio_Err(i).errmessage );
                    RETURN;
                END LOOP;
            END IF;
            --
            l_agreement := pfc.agreement;
        ELSE
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'No cancel.' );
        END IF;
    END LOOP;
    --remove because we not sure if all document have to be marked as finished --05.08.2019
    /*
    FOR rd IN rel_documents( l_agreement )
    LOOP
        l_rel_doc_rec := NULL;
        --
        l_rel_doc_rec := NEW BLC_DOCUMENTS_TYPE ( rd.doc_id );
        --
        l_rel_doc_rec.collection_level := pi_collection_level;
        l_rel_doc_rec.attrib_0 := TO_CHAR( pi_next_event_date, 'dd-mm-yyyy' );
        l_rel_doc_rec.attrib_1 := pi_next_event_id;
        --
        IF NOT l_rel_doc_rec.update_blc_documents( pio_Err )
        THEN
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'l_rel_doc_rec.doc_id = '|| l_rel_doc_rec.doc_id || ' - '||
                                        'pi_collection_level = '|| pi_collection_level ||' - '||
                                        'pi_next_event_date = '|| pi_next_event_date ||' - '||
                                        'pi_next_event_id = '|| pi_next_event_id ||' - '||
                                        pio_Err(pio_Err.FIRST).errmessage );
        END IF;
    END LOOP;
    */
    --
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Cancel_Policies_Doc' );
    --
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Cancel_Policies_Doc', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = ' || pi_doc_id || 'pi_cancel_date = ' || TO_CHAR( pi_cancel_date, 'DD-MM-YYYY' ) || '; ' ||
        'pi_collection_level = '|| pi_collection_level ||'; '|| 'pi_next_event_date = '|| TO_CHAR( pi_next_event_date, 'DD-MM-YYYY' ) ||'; '||
        'pi_next_event_id = '|| pi_next_event_id ||'; '|| SQLERRM );
END Cancel_Policies_Doc;


--------------------------------------------------------------------------------
  PROCEDURE Write_Off_Documents ( pi_legal_entity_id IN NUMBER,
                                  pi_agreement IN VARCHAR2,
                                  pi_account_id IN NUMBER,
                                  pi_to_date IN DATE,
                                  pio_Err IN OUT SrvErr )
  IS
    CURSOR rel_documents ( x_legal_entity_id IN NUMBER,
                           x_agreement IN VARCHAR2,
                           x_account_id IN NUMBER )

    IS SELECT bd.doc_id
       FROM blc_documents bd,
            blc_transactions bt,
            blc_items bi
       WHERE bd.doc_id = bt.doc_id
         AND bt.legal_entity = NVL( x_legal_entity_id, bt.legal_entity )
         AND bt.item_id = bi.item_id
         AND bi.agreement = x_agreement
         AND bt.account_id = NVL( x_account_id, bt.account_id ) -- added on 07.11.2016
         AND bd.doc_class = 'B'
         AND bt.transaction_class = 'B'
         AND bt.status NOT IN ( 'C', 'R', 'D' )
         AND bt.paid_status IN ( 'N', 'P' )
       GROUP BY bd.doc_id
       HAVING SUM ( bt.open_balance ) > 0;

    l_log_module VARCHAR2(240);

    l_err_message VARCHAR2(2000);
    l_exp_error EXCEPTION;
    l_SrvErrMsg SrvErrMsg;

    l_activity_id NUMBER;
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Write_Off_Documents';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Write_Off_Documents' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_to_date = ' || pi_to_date );

     --Getting the default write-off activity

     l_activity_id := BLC_COMMON_PKG.Get_Lookup_Value_Id
                                ( pi_lookup_name => 'APPL_ACTIVITIES',
                                  pi_lookup_code => 'TRX_WRITE_OFF',
                                  pi_to_date => pi_to_date );


     FOR rd IN rel_documents ( pi_legal_entity_id,
                               pi_agreement,
                               pi_account_id )
     LOOP
         BLC_PAY_UTIL_PKG.Create_Document_WriteOff ( pi_doc_id => rd.doc_id,
                                                     pi_activity_id => l_activity_id,
                                                     pio_Err   => pio_Err );

         IF NOT srv_error.rqStatus( pio_Err )
         THEN
             blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                         'rd.doc_id = ' || rd.doc_id || ' - ' ||
                                         'l_activity_id = ' || l_activity_id || ' - ' ||
                                         pio_Err(pio_Err.FIRST).errmessage );

             l_err_message := pio_Err(pio_Err.FIRST).errmessage;
             RAISE l_exp_error;
         END IF;
     END LOOP;

     blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Write_Off_Documents' );
  EXCEPTION
    WHEN l_exp_error THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Write_Off_Documents', l_err_message );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  'pi_to_date = ' || pi_to_date || '; ' ||
                                  l_err_message );
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Write_Off_Documents', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  'pi_to_date = ' || pi_to_date || '; ' ||
                                  SQLERRM );

  END Write_Off_Documents;

--------------------------------------------------------------------------------
  FUNCTION Get_Max_Collection_Level ( pi_legal_entity_id IN NUMBER,
                                      pi_agreement IN VARCHAR2 DEFAULT NULL,
                                      pi_account_id IN NUMBER DEFAULT NULL,
                                      pi_doc_id IN NUMBER DEFAULT NULL,
                                      pio_Err IN OUT SrvErr )
  RETURN NUMBER --changed on 07.11.2016
  IS
    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;


    l_max_level NUMBER;
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Get_Max_Collection_Level';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of function Get_Max_Collection_Level' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_doc_id = ' || pi_doc_id );


      l_max_level := 0;

      FOR lv IN ( SELECT NVL( MAX( bd.collection_level ), 0 ) max_level
                  FROM blc_documents bd,
                       blc_transactions bt,
                       blc_accounts ba,
                       blc_items bi
                  WHERE bd.doc_id = NVL( pi_doc_id, bd.doc_id )
                    AND bd.doc_id = bt.doc_id
                    AND bt.legal_entity = NVL( pi_legal_entity_id, bt.legal_entity )
                    AND bt.account_id = ba.account_id
                    AND bt.item_id = bi.item_id
                    AND bi.agreement = NVL( pi_agreement, bi.agreement )
                    AND bt.account_id = NVL( pi_account_id, bt.account_id )
                    AND bd.doc_class = 'B'
                    AND bt.transaction_class = 'B'
                    AND bt.status NOT IN ( 'C', 'R', 'D' )
                    AND bt.paid_status IN ( 'N', 'P' )
                  GROUP BY bd.doc_id, bt.currency
                  HAVING SUM ( bt.open_balance ) > 0 )

      LOOP
          IF lv.max_level > l_max_level
          THEN
              l_max_level := lv.max_level;
          END IF;
      END LOOP;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_max_level = ' || l_max_level );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of function Get_Max_Collection_Level' );

      RETURN( l_max_level );
  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Get_Max_Collection_Level', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || '; ' ||
                                  'pi_agreement = ' || pi_agreement || '; ' ||
                                  'pi_account_id = ' || pi_account_id || '; ' ||
                                  SQLERRM );
      RETURN( NULL );
  END Get_Max_Collection_Level;

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Insert_Cust_Srv_Error
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESS
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   07.06.2018  creation
--
-- Purpose: Inserts a record into cust_bdc_error_log table.
--
-- Input parameters:
--     pi_policy            VARCHAR2       Policy ID
--     pi_error_message     VARCHAR2       Error Msg
--     pi_details           VARCHAR2       Message Text
--
-- Returns:
--     N/A
--
-- Usage: In Execute_BDC_Strategies
--
--------------------------------------------------------------------------------
PROCEDURE Insert_Cust_Srv_Error( pi_agreement     IN VARCHAR2,
                                 pi_doc_id        IN NUMBER,
                                 pi_error_message IN VARCHAR2,
                                 pi_details       IN VARCHAR2,
                                 pi_number        IN NUMBER )
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    --
    l_log_sequence NUMBER;
BEGIN
    SELECT cust_bdc_error_log_seq.NEXTVAL INTO l_log_sequence
    FROM dual;
    --
    INSERT INTO cust_bdc_error_log
    VALUES
        ( l_log_sequence,
          SYSDATE,
          pi_agreement,
          pi_doc_id,
          SUBSTR(pi_error_message,1,4000),
          SUBSTR(pi_details,1,2000),
          pi_number
         );
    --
    COMMIT;
END;

--------------------------------------------------------------------------------
-- Change LPV-1042 05.06.2018  When a error will be raised, process the next policy (do not stop the job working)
--
  PROCEDURE Execute_BDC_Strategies ( pi_legal_entity_id IN NUMBER,
                                     pi_org_id IN NUMBER,
                                     pi_to_date IN DATE,
                                     pi_agreement IN VARCHAR2,
                                     pi_account_id IN NUMBER,
                                     po_count_updated_docs OUT NUMBER,
                                     po_count_errors  OUT NUMBER,   --Add LPV-1042
                                     pio_Err IN OUT SrvErr )
  IS
    CURSOR documents_for_updating ( x_legal_entity_id IN NUMBER,
                                    x_to_date IN DATE,
                                    x_agreement IN VARCHAR2,
                                    x_account_id IN NUMBER,
                                    x_fc_currency IN VARCHAR2,
                                    x_fc_precision IN NUMBER,
                                    x_country IN VARCHAR2,
                                    x_rate_date IN DATE )
    IS SELECT doc.*,
              bce.event_id, bce.event_level, bce.respite_days,
              bce.currency event_currency,
              bce.min_amount min_amount_event,
              bce.attrib_0 ntf_doc_type_code,
              NVL( bce.attrib_2, NVL( doc.cs_grouping_rule, 'IA' ) ) event_grouping_rule, -- added on 07.11.2016
              ble.lookup_code event_code,

             NVL( ( SELECT bce2.event_id
                    FROM blc_coll_events bce2
                    WHERE bce2.collection_set_id = doc.collection_set_id
                      AND bce2.attrib_1 = doc.doc_type_code
                      AND bce2.event_level = ( SELECT MIN( bce3.event_level )
                                               FROM blc_coll_events bce3
                                               WHERE bce3.collection_set_id = doc.collection_set_id
                                                 AND bce3.attrib_1 = doc.doc_type_code
                                                 AND bce3.event_level > bce.event_level ) ), -1
             ) new_next_event_id,

             NVL( ( SELECT ( x_to_date + bce2.respite_days )
                    FROM blc_coll_events bce2
                    WHERE bce2.collection_set_id = doc.collection_set_id
                      AND bce2.attrib_1 = doc.doc_type_code
                      AND bce2.event_level = ( SELECT MIN( bce3.event_level )
                                               FROM blc_coll_events bce3
                                               WHERE bce3.collection_set_id = doc.collection_set_id
                                                 AND bce3.attrib_1 = doc.doc_type_code
                                                 AND bce3.event_level > bce.event_level ) ),
                  TO_DATE( '01-01-3000', 'dd-mm-yyyy' )
             ) new_next_event_date

       FROM ( SELECT bd.doc_id,
                     NVL( bd.grace_extra, NVL( bd.grace, bd.due_date ) ) due_date,
                     dt.lookup_code doc_type_code,  -- 2017
                     bd.org_site_id, bt.currency,
                     SUM ( bt.open_balance ) open_balance, MAX( bt.paid_status ) doc_paid_status,
                     bd.collection_level, bd.attrib_0 next_event_date, bd.attrib_1 next_event_id,
                     ba.account_id, ba.collection_set_id, cs.attrib_0 cs_grouping_rule, ba.bill_to_site,
                     --bi.item_id, bi.item_name, bi.component,
                     bi.agreement,
                     bi.status item_status
              FROM blc_documents bd,
                   blc_transactions bt,
                   blc_accounts ba,
                   blc_items bi,
                   blc_lookups cs,
                   blc_lookups dt
              WHERE bd.doc_id = bt.doc_id
                AND bt.legal_entity = NVL( x_legal_entity_id, bt.legal_entity )
                AND bt.account_id = ba.account_id
                AND ba.collection_set_id = cs.lookup_id
                AND bt.item_id = bi.item_id
                --AND NVL( bi.attrib_0, 'N' ) = 'N' --hold_flag  2017
                AND bi.agreement = NVL( x_agreement, bi.agreement )
                AND bt.account_id = NVL( x_account_id, bt.account_id )
                AND bd.doc_class = 'B'
                AND bt.transaction_class = 'B'
                AND bt.status NOT IN ( 'C', 'R', 'D' )
                AND bt.paid_status IN ( 'N', 'P' )
                AND bd.doc_type_id = dt.lookup_id
                AND blc_doc_util_pkg.Get_Doc_Open_Balance( bd.doc_id, bd.currency, NULL ) > 0
              GROUP BY bd.doc_id,
                       NVL( bd.grace_extra, NVL( bd.grace, bd.due_date ) ), dt.lookup_code,
                       bd.org_site_id, bt.currency,
                       bd.collection_level, bd.attrib_0, bd.attrib_1,
                       ba.account_id, ba.collection_set_id, cs.attrib_0, ba.bill_to_site,
                       --bi.item_id, bi.item_name, bi.component,
                       bi.agreement,
                       bi.status
              --HAVING SUM ( bt.open_balance ) > 0
            ) doc,

            blc_coll_events bce,
            blc_lookups ble

       WHERE doc.collection_set_id = bce.collection_set_id
         AND NVL( doc.next_event_id, ( SELECT event_id
                                       FROM blc_coll_events bce1
                                       WHERE bce1.collection_set_id = bce.collection_set_id
                                         AND bce1.attrib_1 = doc.doc_type_code
                                         AND bce1.event_level = 1 ) ) = bce.event_id

         AND bce.collection_activity_id = ble.lookup_id
         AND NVL( TO_DATE( doc.next_event_date, 'dd-mm-yyyy' ), doc.due_date + bce.respite_days ) <= x_to_date
         AND CUST_COLL_UTIL_PKG.Get_Amount_FC
                                   ( doc.open_balance,
                                     doc.currency,
                                     x_fc_currency,
                                     x_fc_precision,
                                     x_country,
                                     x_rate_date,
                                     'FIXING' ) > CUST_COLL_UTIL_PKG.Get_Amount_FC
                                                                           ( bce.min_amount,
                                                                             bce.currency,
                                                                             x_fc_currency,
                                                                             x_fc_precision,
                                                                             x_country,
                                                                             x_rate_date,
                                                                             'FIXING' )
       ORDER BY doc.agreement, doc.account_id, doc.collection_level desc;

    CURSOR lock_document ( x_doc_id IN NUMBER )
    IS SELECT doc_id
       FROM blc_documents
       WHERE doc_id = x_doc_id;

    l_log_module VARCHAR2(240);

    l_err_message VARCHAR2(2000);
    l_exp_error EXCEPTION;
    l_SrvErrMsg SrvErrMsg;
    --l_SrvErr SrvErr;

    l_oper_date DATE;
    l_to_date DATE;
    l_ntf_doc_type_id NUMBER;
    l_ntf_doc_id NUMBER;
    l_previous_agreement VARCHAR2(30);
    l_previous_account_id NUMBER;
    l_count NUMBER;
    l_max_level NUMBER;

    l_curr_agreement VARCHAR2(30); -- added on 07.11.2016
    l_curr_account_id NUMBER; -- added on 07.11.2016
    l_curr_doc_id NUMBER; -- added on 07.11.2016

    l_SrvErr        SrvErr; -- LPV-1042 05.06.2018
    l_count_errors  PLS_INTEGER := 0;  -- LPV-1042 05.06.2018
    l_num_prg       NUMBER;  -- LPV-1042

    l_doc_rec BLC_DOCUMENTS_TYPE;
  BEGIN
      blc_log_pkg.initialize( pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          RETURN;
      END IF;

      l_log_module := C_DEFAULT_MODULE||'.Execute_BDC_Strategies';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Execute_BDC_Strategies' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_org_id = ' || pi_org_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_to_date = ' || pi_to_date );


      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      l_oper_date := BLC_COMMON_PKG.Get_Setting_Date_Value ( 'OperDate',
                                                             pio_Err,
                                                             pi_legal_entity_id );

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                      'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                      'pi_to_date = ' || pi_to_date || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          l_err_message := pio_Err(pio_Err.FIRST).errmessage;
          RAISE l_exp_error;
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'OK1 - l_oper_date = ' || l_oper_date );

      l_to_date := NVL( pi_to_date, l_oper_date );

      blc_appl_cache_pkg.init_le( pi_legal_entity_id, pio_Err );

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                      'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          l_err_message := pio_Err(pio_Err.FIRST).errmessage;
          RAISE l_exp_error;
      END IF;

      IF BLC_APPL_CACHE_PKG.g_country IS NULL
      THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Execute_BDC_Strategies', 'CUST_COLL_UTIL_PKG.EBDCS.MissingCountry' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
            'pi_to_date = ' || pi_to_date || ' - ' ||
            'legal_entity = ' || pi_legal_entity_id || ' - ' || 'Missing Country' );

          l_err_message := 'Missing Country';
          RAISE l_exp_error;
      END IF;

      IF BLC_APPL_CACHE_PKG.g_fc_currency IS NULL
      THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Execute_BDC_Strategies', 'CUST_COLL_UTIL_PKG.EBDCS.MissingFuncCurr' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
            'pi_to_date = ' || pi_to_date || ' - ' ||
            'legal_entity = ' || pi_legal_entity_id || ' - ' || 'Missing functional currency' );

          l_err_message := 'Missing functional currency';
          RAISE l_exp_error;
      END IF;

      IF BLC_APPL_CACHE_PKG.g_fc_precision IS NULL
      THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Execute_BDC_Strategies', 'CUST_COLL_UTIL_PKG.EBDCS.MissingFuncCurrPr' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
            'pi_to_date = ' || pi_to_date || ' - ' ||
            'legal_entity = ' || pi_legal_entity_id || ' - ' || 'Missing functional currency precision' );

          l_err_message := 'Missing functional currency precision';
          RAISE l_exp_error;
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'OK2 - BLC_APPL_CACHE_PKG.g_country = ' || BLC_APPL_CACHE_PKG.g_country );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'OK3 - BLC_APPL_CACHE_PKG.g_fc_currency = ' || BLC_APPL_CACHE_PKG.g_fc_currency );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'OK4 - BLC_APPL_CACHE_PKG.g_fc_precision = ' || BLC_APPL_CACHE_PKG.g_fc_precision );


      l_previous_agreement := '-555';
      l_previous_account_id := -555;
      l_count := 0;

      SELECT cust_bdc_num_seq.NEXTVAL INTO l_num_prg  -- Add LPV-1042 05.06.2018
      FROM dual;

      FOR dfu IN documents_for_updating ( pi_legal_entity_id,
                                          l_to_date,
                                          pi_agreement,
                                          pi_account_id,
                                          BLC_APPL_CACHE_PKG.g_fc_currency,
                                          BLC_APPL_CACHE_PKG.g_fc_precision,
                                          BLC_APPL_CACHE_PKG.g_country,
                                          l_to_date )
      LOOP

          --l_SrvErr := NULL;
          --l_SrvErrMsg := NULL;
          --l_err_message := NULL;
          l_doc_rec := NULL;
          l_ntf_doc_id := NULL;
          l_curr_agreement := NULL; -- added on 07.11.2016
          l_curr_account_id := NULL; -- added on 07.11.2016
          l_curr_doc_id := NULL; -- added on 07.11.2016

          SAVEPOINT BDC_DOC;   -- Add LPV-1042 05.06.2018
          l_SrvErr := NULL;    -- Add LPV-1042 05.06.2018

          OPEN lock_document ( dfu.doc_id );
          CLOSE lock_document;

          --l_count := l_count + 1; -- LPV-1042 Move on the end loop

          -- start added on 07.11.2016

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                     'dfu.event_grouping_rule = ' || dfu.event_grouping_rule );

          IF INSTR ( dfu.event_grouping_rule, 'I' ) > 0
          THEN
              l_curr_agreement := dfu.agreement;
          END IF;

          IF INSTR ( dfu.event_grouping_rule, 'A' ) > 0
          THEN
              l_curr_account_id := dfu.account_id;
          END IF;

          IF INSTR ( dfu.event_grouping_rule, 'D' ) > 0
          THEN
              l_curr_doc_id := dfu.doc_id;
          END IF;

          -- end added on 07.11.2016
          l_max_level := Get_Max_Collection_Level ( pi_legal_entity_id => pi_legal_entity_id,
                                                    pi_agreement => l_curr_agreement,
                                                    pi_account_id => l_curr_account_id,
                                                    pi_doc_id => l_curr_doc_id,
                                                    pio_Err => l_SrvErr );     -- LPV-1042 Change pio_Err with l_SrvErr
          IF NOT srv_error.rqStatus( l_SrvErr ) -- LPV-1042 Change pio_Err with l_SrvErr
          THEN
              blc_log_pkg.insert_message( l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                          'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                          'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                          'l_curr_doc_id = ' || l_curr_doc_id || ' - ' ||
                                          l_SrvErr(l_SrvErr.FIRST).errmessage ); -- LPV-1042 Change pio_Err with l_SrvErr

              -- l_err_message := pio_Err(pio_Err.FIRST).errmessage; -- Comment LPV-1042
              -- RAISE l_exp_error;  -- Comment LPV-1042
              Insert_Cust_Srv_Error( dfu.agreement, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                     'Get_Max_Collection_Level:  ' ||
                                     'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' || 'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                     'l_curr_account_id = ' || l_curr_account_id || ' - ' || 'l_curr_doc_id = ' || l_curr_doc_id,
                                     l_num_prg ); -- LPV-1042
              l_count_errors := l_count_errors + 1;  -- Add LPV-1042
              ROLLBACK TO BDC_DOC;  -- Add Add LPV-1042
              CONTINUE;  -- Add LPV-1042
          END IF;


          IF ( l_previous_agreement <> NVL( l_curr_agreement, '-999' )
            OR l_previous_account_id <> NVL( l_curr_account_id, -999 ) )

            AND dfu.event_level > l_max_level

          THEN
              -- Complete the corresponding event action
              IF dfu.event_code = 'NOTIFICATION'
              THEN
                  l_ntf_doc_id := NULL;
                  l_ntf_doc_type_id := NULL;

                  l_ntf_doc_type_id := BLC_COMMON_PKG.Get_Lookup_Value_Id(
                                                      'DOCUMENT_TYPES',
                                                      dfu.ntf_doc_type_code,
                                                      l_SrvErr,  -- LPV-1042 Change pio_Err with l_SrvErr
                                                      NVL( pi_org_id, 0 ),
                                                      l_to_date );

                  IF NOT srv_error.rqStatus( l_SrvErr ) -- LPV-1042 Change pio_Err with l_SrvErr
                  THEN
                      blc_log_pkg.insert_message( l_log_module,
                                                  C_LEVEL_EXCEPTION,
                                                  'lookup_set = DOCUMENT_TYPES - ' ||
                                                  'lookup_code = ' || dfu.ntf_doc_type_code || ' - ' ||
                                                  'org_id = ' || NVL( pi_org_id, 0 ) || ' - ' ||
                                                  'l_to_date = ' || l_to_date || ' - ' ||
                                                  l_SrvErr(l_SrvErr.FIRST).errmessage ); -- LPV-1042 Change pio_Err with l_SrvErr

                      -- l_err_message := pio_Err(pio_Err.FIRST).errmessage; -- Comment LPV-1042
                       -- RAISE l_exp_error; -- Comment LPV-1042
                      Insert_Cust_Srv_Error( dfu.agreement, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                             'BLC_COMMON_PKG.Get_Lookup_Value_Id:  ' ||
                                             'lookup_set = DOCUMENT_TYPES - ' || 'lookup_code = ' || dfu.ntf_doc_type_code || ' - ' ||
                                             'org_id = ' || NVL( pi_org_id, 0 ) || ' - ' || 'l_to_date = ' || TO_CHAR(l_to_date,'DD-MM-YYYY'),
                                             l_num_prg );  -- Add LPV-1042
                      l_count_errors := l_count_errors + 1;  -- Add LPV-1042
                      ROLLBACK TO BDC_DOC;  -- Add LPV-1042
                      CONTINUE;  -- LPV-1042
                  END IF;

                  blc_log_pkg.insert_message( l_log_module,
                                              C_LEVEL_PROCEDURE,
                                              'OK5 - l_ntf_doc_type_id = ' || l_ntf_doc_type_id );

                  Create_Ntf_Document ( pi_legal_entity_id => pi_legal_entity_id,
                                        pi_org_id => dfu.org_site_id,
                                        pi_agreement => l_curr_agreement, --dfu.agreement, --changed on 07.11.2016
                                        pi_account_id => l_curr_account_id, --dfu.account_id, --changed on 07.11.2016
                                        pi_doc_id => l_curr_doc_id, --added on 07.11.2016
                                        pi_bill_to_site => dfu.bill_to_site,
                                        pi_issue_date => l_to_date,
                                        pi_due_date => l_to_date,
                                        pi_coll_event_id => dfu.event_id,
                                        pi_collection_level => dfu.event_level,
                                        pi_fc_currency => BLC_APPL_CACHE_PKG.g_fc_currency,
                                        pi_fc_precision => BLC_APPL_CACHE_PKG.g_fc_precision,
                                        pi_country => BLC_APPL_CACHE_PKG.g_country,
                                        pi_rate_date => l_to_date,
                                        pi_rate_type => 'FIXING',
                                        pi_ntf_doc_type_id => l_ntf_doc_type_id,
                                        po_ntf_doc_id => l_ntf_doc_id,
                                        pio_Err => l_SrvErr ); -- LPV-1042 Change pio_Err with l_SrvErr

                  IF NOT srv_error.rqStatus( l_SrvErr ) -- LPV-1042 Change pio_Err with l_SrvErr
                  THEN
                      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                                 'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                                 'dfu.org_site_id = ' || dfu.org_site_id || ' - ' ||
                                                 'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                                 'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                                 'l_curr_doc_id = ' || l_curr_doc_id || ' - ' ||
                                                 'dfu.bill_to_site = ' || dfu.bill_to_site || ' - ' ||
                                                 'l_to_date = ' || l_to_date || ' - ' ||
                                                 'dfu.event_id = ' || dfu.event_id || ' - ' ||
                                                 'dfu.event_level = ' || dfu.event_level || ' - ' ||
                                                 'l_ntf_doc_type_id = ' || l_ntf_doc_type_id || ' - ' ||
                                                 l_SrvErr(l_SrvErr.FIRST).errmessage ); -- LPV-1042 Change pio_Err with l_SrvErr

                      --l_err_message := pio_Err(pio_Err.FIRST).errmessage; -- Comment LPV-1042
                      --RAISE l_exp_error; -- Comment LPV-1042
                      Insert_Cust_Srv_Error( dfu.agreement, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                             'Create_Ntf_Document:  ' ||
                                              'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' || 'dfu.org_site_id = ' || dfu.org_site_id || ' - ' ||
                                              'l_curr_agreement = ' || l_curr_agreement || ' - ' || 'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                              'l_curr_doc_id = ' || l_curr_doc_id || ' - ' || 'dfu.bill_to_site = ' || dfu.bill_to_site || ' - ' ||
                                              'l_to_date = ' || TO_CHAR(l_to_date,'DD-MM-YYYY') || ' - ' || 'dfu.event_id = ' || dfu.event_id || ' - ' ||
                                              'dfu.event_level = ' || dfu.event_level || ' - ' || 'l_ntf_doc_type_id = ' || l_ntf_doc_type_id,
                                              l_num_prg ); -- LPV-1042
                      l_count_errors := l_count_errors + 1;  -- Add LPV-1042
                      ROLLBACK TO BDC_DOC;  -- Add LPV-1042
                      CONTINUE;  -- LPV-1042
                  END IF;

                  IF l_ntf_doc_id IS NOT NULL
                  THEN
                      blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE,
                                                  'OK5.1 - pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                                  'dfu.org_site_id = ' || dfu.org_site_id || ' - ' ||
                                                  'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                                 'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                                 'l_curr_doc_id = ' || l_curr_doc_id || ' - ' ||
                                                  'dfu.bill_to_site = ' || dfu.bill_to_site || ' - ' ||
                                                  'l_to_date = ' || l_to_date || ' - ' ||
                                                  'dfu.event_id = ' || dfu.event_id || ' - ' ||
                                                  'dfu.event_level = ' || dfu.event_level || ' - ' ||
                                                  'dfu.event_code = ' || dfu.event_code || ' - ' ||
                                                  'dfu.new_next_event_date = ' || dfu.new_next_event_date || ' - ' ||
                                                  'dfu.new_next_event_id = ' || dfu.new_next_event_id || ' - ' ||
                                                  'l_ntf_doc_type_id = ' || l_ntf_doc_type_id || ' - ' ||
                                                  'l_ntf_doc_id = ' || l_ntf_doc_id );
                  END IF;

              ELSIF dfu.event_code = 'CANCEL_POLICY'
                AND dfu.item_status <> 'N'
              THEN
                  IF INSTR ( dfu.event_grouping_rule, 'D' ) > 0
                  THEN
                      Cancel_Policies_Doc( pi_doc_id           => l_curr_doc_id,
                                           pi_cancel_date      => l_to_date,
                                           pi_collection_level => dfu.event_level,
                                           pi_next_event_date  => dfu.new_next_event_date,
                                           pi_next_event_id    => dfu.new_next_event_id,
                                           pio_Err             => l_SrvErr ); -- LPV-1042 Change pio_Err with l_SrvErr
                      IF NOT srv_error.rqStatus( l_SrvErr ) -- LPV-1042 Change pio_Err with l_SrvErr
                      THEN
                          -- l_err_message := pio_Err(pio_Err.FIRST).errmessage; -- LPV-1042 Change pio_Err with l_SrvErr
                          --RAISE l_exp_error; -- Comment LPV-1042
                          Insert_Cust_Srv_Error( dfu.agreement, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                                'Cancel_Policies_Doc:  ' ||
                                                'pi_doc_id = ' || l_curr_doc_id || ' - ' || 'pi_cancel_date = ' || TO_CHAR(l_to_date,'DD-MM-YYYY')  || ' - ' ||
                                                'pi_collection_level = ' || dfu.event_level || ' - ' || 'pi_next_event_date = ' || TO_CHAR(dfu.new_next_event_date,'DD-MM-YYYY')  || ' - ' ||
                                                'pi_next_event_id = ' || dfu.new_next_event_id,
                                                l_num_prg );  -- Add LPV-1042
                          l_count_errors := l_count_errors + 1;  -- Add LPV-1042
                          ROLLBACK TO BDC_DOC;  -- Add LPV-1042
                          CONTINUE;  -- LPV-1042
                      END IF;
                  ELSE
                       Cancel_Policies (  pi_cancel_date => l_to_date,
                                     pi_legal_entity_id => pi_legal_entity_id,
                                     pi_agreement => l_curr_agreement,
                                     pi_account_id => l_curr_account_id,
                                     pi_collection_level => dfu.event_level,
                                     pi_next_event_date => dfu.new_next_event_date,
                                     pi_next_event_id => dfu.new_next_event_id,
                                     pio_Err => l_SrvErr ); -- LPV-1042 Change pio_Err with l_SrvErr

                      IF NOT srv_error.rqStatus( l_SrvErr ) -- LPV-1042 Change pio_Err with l_SrvErr
                      THEN
                          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                                 'l_to_date = ' || l_to_date || ' - ' ||
                                                 'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                                 'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                                 'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                                 'dfu.event_level = ' || dfu.event_level || ' - ' ||
                                                 'dfu.new_next_event_date = ' || dfu.new_next_event_date || ' - ' ||
                                                 'dfu.new_next_event_id = ' || dfu.new_next_event_id || ' - ' ||
                                                 l_SrvErr(l_SrvErr.FIRST).errmessage ); -- LPV-1042 Change pio_Err with l_SrvErr
                          --l_err_message := pio_Err(pio_Err.FIRST).errmessage;
                          --RAISE l_exp_error; -- Comment LPV-1042
                          Insert_Cust_Srv_Error( dfu.agreement, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                                 'Cancel_Policies:  ' ||
                                                 'l_to_date = ' || TO_CHAR(l_to_date,'DD-MM-YYYY') || ' - ' || 'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                                 'l_curr_agreement = ' || l_curr_agreement || ' - ' ||  'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                                 'pi_collection_level = ' || dfu.event_level || ' - ' ||
                                                 'pi_next_event_date = ' || dfu.new_next_event_date || ' - ' ||
                                                 'pi_next_event_id = ' || dfu.new_next_event_id,
                                                 l_num_prg );  -- Add SGI-1184
                          l_count_errors := l_count_errors + 1;  -- Add LPV-1042
                          ROLLBACK TO BDC_DOC;  -- Add LPV-1042
                          CONTINUE;  -- LPV-1042
                      END IF;
                  END IF;
              ELSIF dfu.event_code = 'WRITE_OFF'
              THEN
                  Write_Off_Documents ( pi_legal_entity_id => pi_legal_entity_id,
                                        pi_agreement => l_curr_agreement,
                                        pi_account_id => l_curr_account_id,
                                        pi_to_date => l_to_date,
                                        pio_Err => l_SrvErr ); -- LPV-1042 Change pio_Err with l_SrvErr

                  IF NOT srv_error.rqStatus( l_SrvErr ) -- LPV-1042 Change pio_Err with l_SrvErr
                  THEN
                      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                                 'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                                 'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                                 'l_curr_account_id = ' || l_curr_account_id || ' - ' ||
                                                 'l_to_date = ' || l_to_date || ' - ' ||
                                                 l_SrvErr(l_SrvErr.FIRST).errmessage ); -- LPV-1042 Change pio_Err with l_SrvErr
                      --l_err_message := pio_Err(pio_Err.FIRST).errmessage; -- Comment LPV-1042
                      -- RAISE l_exp_error; -- Comment LPV-1042
                      Insert_Cust_Srv_Error( dfu.agreement, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                     'Write_Off_Documents:  ' ||
                                     'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' || 'l_curr_agreement = ' || l_curr_agreement || ' - ' ||
                                     'l_curr_account_id = ' || l_curr_account_id || ' - ' || 'l_to_date = ' || TO_CHAR(l_to_date, 'DD-MM-YYYY'),
                                     l_num_prg ); -- LPV-1042
                      l_count_errors := l_count_errors + 1;  -- Add LPV-1042
                      ROLLBACK TO BDC_DOC;  -- Add LPV-1042
                      CONTINUE;  -- LPV-1042
                  END IF;

              ELSIF dfu.event_code = 'NOPE'
              THEN
                  NULL;
              END IF;
          END IF;

          l_previous_agreement := dfu.agreement;
          l_previous_account_id := dfu.account_id;

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK6 - dfu.doc_id = ' || dfu.doc_id );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK7 - l_previous_agreement = ' || l_previous_agreement );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK8 - l_previous_account_id = ' || l_previous_account_id );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK9 - dfu.event_level = ' || dfu.event_level );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK10 - dfu.new_next_event_date = ' || dfu.new_next_event_date );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK11 - dfu.new_next_event_id = ' || dfu.new_next_event_id );

          l_doc_rec := NEW BLC_DOCUMENTS_TYPE ( dfu.doc_id );

          l_doc_rec.collection_level := dfu.event_level;
          l_doc_rec.attrib_0 := TO_CHAR( dfu.new_next_event_date, 'dd-mm-yyyy' );
          l_doc_rec.attrib_1 := dfu.new_next_event_id;

          IF NOT l_doc_rec.update_blc_documents( l_SrvErr )  -- LPV-1042 Change pio_Err with l_SrvErr
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                          'dfu.doc_id = '|| dfu.doc_id || ' - '||
                                          l_SrvErr(l_SrvErr.FIRST).errmessage ); -- LPV-1042 Change pio_Err with l_SrvErr
              --l_err_message := pio_Err(pio_Err.FIRST).errmessage;  -- Comment LPV-1042
              --RAISE l_exp_error; -- Comment LPV-1042
              Insert_Cust_Srv_Error( NULL, dfu.doc_id, l_SrvErr(l_SrvErr.FIRST).errmessage,
                                     'l_doc_rec.update_blc_documents: ' || ' - ' || 'dfu.doc_id = ' || dfu.doc_id,
                                     l_num_prg ); -- LPV-1042
              l_count_errors := l_count_errors + 1;  -- Add LPV-1042
              ROLLBACK TO BDC_DOC;  -- Add LPV-1042
              CONTINUE;  -- LPV-1042
          END IF;

          l_count := l_count + 1; -- LPV-1042

      END LOOP;


      po_count_updated_docs := l_count;
      po_count_errors := l_count_errors;

      blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_PROCEDURE,
                                      'OK11 - l_count = ' || l_count );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Execute_BDC_Strategies' );


  EXCEPTION
    WHEN l_exp_error THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Execute_BDC_Strategies', l_err_message );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = '|| pi_legal_entity_id || ' - '||
                                  'pi_org_id = '|| pi_org_id || ' - '||
                                  'pi_to_date = '|| pi_to_date ||' - '||
                                  'pi_agreement = ' || pi_agreement || ' - ' ||
                                  'pi_account_id = ' || pi_account_id || ' - ' ||
                                  l_err_message );

    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Execute_BDC_Strategies', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = '|| pi_legal_entity_id || ' - '||
                                  'pi_org_id = '|| pi_org_id || ' - '||
                                  'pi_to_date = '|| pi_to_date ||' - '||
                                  'pi_agreement = ' || pi_agreement || ' - ' ||
                                  'pi_account_id = ' || pi_account_id || ' - ' ||
                                  SQLERRM );
  END Execute_BDC_Strategies;

--------------------------------------------------------------------------------
  /*PROCEDURE Change_Item_Hold_Flag ( pi_item_id IN NUMBER,
                                    pio_Err IN OUT SrvErr )
  IS
    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
    l_item_rec BLC_ITEMS_TYPE;
  BEGIN
      blc_log_pkg.initialize( pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          RETURN;
      END IF;

      l_log_module := C_DEFAULT_MODULE||'.Change_Item_Hold_Flag';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Change_Item_Hold_Flag' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_item_id = ' || pi_item_id );

      l_item_rec := NEW blc_items_type( pi_item_id, pio_Err );

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                      'pi_item_id = ' || pi_item_id || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          RETURN;
      END IF;

      IF NVL( l_item_rec.attrib_0, 'N' ) = 'N'
      THEN
          l_item_rec.attrib_0 := 'Y';
      ELSIF l_item_rec.attrib_0 = 'Y'
      THEN
          l_item_rec.attrib_0 := 'N';
      END IF;

      IF NOT l_item_rec.update_blc_items ( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                      'pi_item_id = ' || pi_item_id || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          RETURN;
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Change_Item_Hold_Flag' );
  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Change_Item_Hold_Flag', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_item_id = '|| pi_item_id || ' - '||
                                  SQLERRM );
  END Change_Item_Hold_Flag; */
--------------------------------------------------------------------------------

  FUNCTION Register_Report_Action ( pi_doc_id IN NUMBER,
                                    pi_report_status IN VARCHAR2,
                                    pi_notes VARCHAR2,
                                    pio_Err IN OUT SrvErr )
  RETURN BOOLEAN
  IS
    l_document_rec BLC_DOCUMENTS_TYPE;

    l_log_module     VARCHAR2(240);
    l_SrvErrMsg      SrvErrMsg;
  BEGIN

      blc_log_pkg.initialize( pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          RETURN FALSE;
      END IF;

      l_log_module := C_DEFAULT_MODULE||'.Register_Report_Action';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of function Register_Report_Action' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_doc_id = ' || pi_doc_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_report_status = ' || pi_report_status );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_notes = ' || pi_notes );

      IF pi_report_status = 'S'
      THEN
          l_document_rec := blc_documents_type ( pi_doc_id );

          l_document_rec.status := 'F';

          IF NOT l_document_rec.update_blc_documents( pio_Err )
          THEN
              blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                          'pi_doc_id = '||pi_doc_id||' - '||
                          'pi_report_status = '||pi_report_status||' - '||pio_Err(pio_Err.FIRST).errmessage);
              RETURN ( FALSE );
          END IF;

          blc_doc_util_pkg.Insert_Action ( pi_action_type => 'SENT',
                                           pi_notes       => pi_notes,
                                           pi_status      => 'S',
                                           pi_doc_id      => pi_doc_id,
                                           pio_Err        => pio_Err );

            IF NOT srv_error.rqStatus( pio_Err )
            THEN

                blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                        'SENT Action - ' ||
                        'pi_report_status = '||pi_report_status||' - '||
                        'pi_notes = '||pi_notes||' - '||
                        'pi_doc_id = '||pi_doc_id||' - '|| pio_Err(pio_Err.FIRST).errmessage);

                RETURN ( FALSE );
            END IF;
      ELSIF pi_report_status = 'E'
      THEN
          --Doc status should not be changed only an action should be registered
          blc_doc_util_pkg.Insert_Action ( pi_action_type => 'SENT',
                                           pi_notes => pi_notes,
                                           pi_status => 'F',
                                           pi_doc_id => pi_doc_id,
                                           pio_Err => pio_Err );

            IF NOT srv_error.rqStatus( pio_Err )
            THEN

                blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                        'SENT Action - ' ||
                        'pi_report_status = '||pi_report_status||' - '||
                        'pi_notes = '||pi_notes||' - '||
                        'pi_doc_id = '||pi_doc_id||' - '|| pio_Err(pio_Err.FIRST).errmessage);

                RETURN ( FALSE );
            END IF;
      END IF;

      RETURN( TRUE );
  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Register_Report_Action', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

    blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                    'pi_doc_id = '||pi_doc_id||' - '||
                    'pi_report_status = '||pi_report_status||' - '||
                    'pi_notes = '||pi_notes||' - '|| SQLERRM );

    RETURN( FALSE );
  END Register_Report_Action;

--------------------------------------------------------------------------------
  FUNCTION Get_Acct_Plc_LE_ID ( pi_account_id IN NUMBER,
                                pi_agreement IN VARCHAR2,
                                pio_Err IN OUT SrvErr )
  RETURN NUMBER
  IS
    l_legal_entity_id NUMBER;
    l_acct_rec BLC_ACCOUNTS_TYPE;

    l_SrvErrMsg SrvErrMsg;
    l_log_module VARCHAR2(240);
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Get_Acct_Plc_LE_ID';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of function Get_Acct_Plc_LE_ID' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      IF pi_agreement IS NOT NULL
      THEN
          FOR i IN ( SELECT legal_entity_id
                     FROM blc_items
                     WHERE agreement = pi_agreement
                       AND item_type = 'POLICY' )
          LOOP
              l_legal_entity_id := i.legal_entity_id;
          END LOOP;
      ELSIF pi_account_id IS NOT NULL
      THEN
          l_acct_rec := NEW BLC_ACCOUNTS_TYPE ( pi_account_id, pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN

              blc_log_pkg.insert_message( l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'pi_account_id = ' || pi_account_id || ' - ' ||
                                          'pi_agreement = ' || pi_agreement || ' - ' ||
                                          pio_Err(pio_Err.FIRST).errmessage );

              RETURN ( NULL );
          END IF;

          BEGIN
              SELECT bor.legal_entity_id
              INTO l_legal_entity_id
              FROM INSIS_GEN_BLC_V10.blc_org_roles bor
              WHERE bor.org_id = l_acct_rec.billing_site_id
                AND TRUNC(sysdate) BETWEEN TRUNC( bor.from_date ) AND TRUNC( NVL( bor.to_date, sysdate ) )
                AND blc_common_pkg.get_lookup_code(bor.lookup_id) = 'BILLING';
          EXCEPTION
            WHEN OTHERS THEN
              BEGIN
                  SELECT DISTINCT bor.legal_entity_id
                  INTO l_legal_entity_id
                  FROM INSIS_GEN_BLC_V10.blc_org_roles bor
                  WHERE bor.org_id = l_acct_rec.billing_site_id
                    AND TRUNC(sysdate) BETWEEN TRUNC( bor.from_date ) AND TRUNC( NVL( bor.to_date, sysdate ) );
              EXCEPTION
                WHEN OTHERS THEN
                  l_legal_entity_id := NULL;
              END;
          END;
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_legal_entity_id = ' || l_legal_entity_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of function Get_Acct_Plc_LE_ID' );

      RETURN ( l_legal_entity_id );
  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Get_Acct_Plc_LE_ID', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_account_id = ' || pi_account_id || ' - ' ||
                                  'pi_agreement = ' || pi_agreement || ' - ' ||  SQLERRM );

    RETURN( NULL );
  END Get_Acct_Plc_LE_ID;

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Get_Acct_Plc_Open_Bal_FC
--
-- Type: FUNCTION
--
-- Subtype: DATA_GET
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   09.09.2014  creation
--
-- Purpose: The function calculates the open balance amount in functional currency
-- for a particular account or/and a particular policy as of date.
--
-- Input parameters:
--     pi_account_id          NUMBER         Account ID
--     pi_agreement           VARCHAR2       Policy Number
--     pi_overdue_as_of_date  DATE           Overdue as of date
--     pio_Err                SrvErr         Specifies structure for passing back
--                                           the error code, error TYPE and
--                                           corresponding message.
-- Output parameters:
--   pio_Err                  SrvErr      Specifies structure for passing back
--                                        the error code, error TYPE and
--                                        corresponding message.
--
-- Returns:
--     Open balance amount in functional currency
--
-- Usage: In calculation policy/account open balance
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
  FUNCTION Get_Acct_Plc_Open_Bal_FC ( pi_account_id IN NUMBER,
                                      pi_agreement IN VARCHAR2,
                                      pi_overdue_as_of_date IN DATE,
                                      pio_Err IN OUT SrvErr )
  RETURN NUMBER

  IS
    l_legal_entity_id NUMBER;
    l_oper_date DATE;
    l_to_date DATE;
    l_open_amount_fc NUMBER;

    l_SrvErrMsg SrvErrMsg;
    l_log_module VARCHAR2(240);

  BEGIN
      blc_log_pkg.initialize( pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          RETURN ( NULL );
      END IF;

      l_log_module := C_DEFAULT_MODULE||'.Get_Acct_Plc_Open_Bal_FC';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of function Get_Acct_Plc_Open_Bal_FC' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_account_id = ' || pi_account_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_overdue_as_of_date = ' || pi_overdue_as_of_date );

      l_legal_entity_id := Get_Acct_Plc_LE_ID ( pi_account_id,
                                                pi_agreement,
                                                pio_Err );

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                      'pi_account_id = ' || pi_account_id || ' - ' ||
                                      'pi_agreement = ' || pi_agreement || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          RETURN ( NULL );
      END IF;

      l_oper_date := BLC_COMMON_PKG.Get_Setting_Date_Value ( 'OperDate',
                                                             pio_Err,
                                                             l_legal_entity_id );

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                      'l_legal_entity_id = ' || l_legal_entity_id || ' - ' ||
                                      pio_Err(pio_Err.FIRST).errmessage );

          RETURN ( NULL );
      END IF;

      l_to_date := NVL( pi_overdue_as_of_date, l_oper_date );

      blc_appl_cache_pkg.init_le( l_legal_entity_id, pio_Err );

      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                 'l_legal_entity_id = ' || l_legal_entity_id || ' - ' ||
                                 pio_Err(pio_Err.FIRST).errmessage );

          RETURN( NULL );
      END IF;

      IF pi_account_id IS NOT NULL
      THEN

          SELECT SUM( CUST_COLL_UTIL_PKG.Get_Amount_FC ( bt.open_balance,
                                                         bt.currency,
                                                         BLC_APPL_CACHE_PKG.g_fc_currency,
                                                         BLC_APPL_CACHE_PKG.g_fc_precision,
                                                         BLC_APPL_CACHE_PKG.g_country,
                                                         l_to_date,
                                                         bt.rate_type )
                     )
           INTO l_open_amount_fc
           FROM blc_items bi,
                blc_transactions bt,
                blc_documents bd
           WHERE bi.item_type = 'POLICY'
             AND bi.agreement = NVL( pi_agreement, bi.agreement )
             AND bi.item_id = bt.item_id
             AND bt.account_id  = pi_account_id
             AND bt.legal_entity = l_legal_entity_id
             AND bt.transaction_class = 'B'
             AND bt.status NOT IN ( 'C', 'R', 'D' )
             AND bt.open_balance > 0
             AND NVL( bt.grace_extra, NVL( bt.grace, bt.due_date ) ) < l_to_date
             AND bt.doc_id = bd.doc_id
             AND bd.status IN ( 'A', 'F' )
             AND bd.doc_class = 'B';

         ELSIF pi_agreement IS NOT NULL
         THEN

             SELECT SUM( CUST_COLL_UTIL_PKG.Get_Amount_FC ( bt.open_balance,
                                                            bt.currency,
                                                            BLC_APPL_CACHE_PKG.g_fc_currency,
                                                            BLC_APPL_CACHE_PKG.g_fc_precision,
                                                            BLC_APPL_CACHE_PKG.g_country,
                                                            l_to_date,
                                                            bt.rate_type )
                     )
           INTO l_open_amount_fc
           FROM blc_items bi,
                blc_transactions bt,
                blc_documents bd
           WHERE bi.item_type = 'POLICY'
             AND bi.agreement = pi_agreement
             AND bi.item_id = bt.item_id
             AND bt.account_id  = NVL( pi_account_id, bt.account_id )
             AND bt.legal_entity = l_legal_entity_id
             AND bt.transaction_class = 'B'
             AND bt.status NOT IN ( 'C', 'R', 'D' )
             AND bt.open_balance > 0
             AND NVL( bt.grace_extra, NVL( bt.grace, bt.due_date ) ) < l_to_date
             AND bt.doc_id = bd.doc_id
             AND bd.status IN ( 'A', 'F' )
             AND bd.doc_class = 'B';

         END IF;

         blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_open_amount_fc = ' || l_open_amount_fc );

        blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of function Get_Acct_Plc_Open_Bal_FC' );

        RETURN( NVL( l_open_amount_fc, 0 ) );
  EXCEPTION
    WHEN OTHERS THEN

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_account_id = ' || pi_account_id || ' - ' ||
                                  'pi_agreement = ' || pi_agreement || ' - ' ||
                                  'pi_overdue_as_of_date = ' || pi_overdue_as_of_date || ' - ' ||
                                  SQLERRM );

      RETURN NULL;
  END Get_Acct_Plc_Open_Bal_FC;

--------------------------------------------------------------------------------
  FUNCTION Get_Max_Value_Date ( pi_agreement IN VARCHAR2,
                                pi_legal_entity_id IN NUMBER,
                                pio_Err IN OUT SrvErr )
  RETURN DATE
  IS
    l_SrvErrMsg SrvErrMsg;
    l_log_module VARCHAR2(240);

    l_doc_open_balance NUMBER;
    l_max_value_date DATE;
  BEGIN
      l_log_module := C_DEFAULT_MODULE||'.Get_Max_Value_Date';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of function Get_Max_Value_Date' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_agreement = ' || pi_agreement );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id );

      FOR doc IN  ( SELECT bd.doc_id, bd.currency, MAX( bp.value_date ) doc_max_value_date
                    FROM blc_documents bd,
                         blc_transactions bt,
                         blc_accounts ba,
                         blc_items bi,
                         blc_applications baa,
                         blc_payments bp
                    WHERE bd.doc_id = bt.doc_id
                      AND bt.legal_entity = pi_legal_entity_id
                      AND bt.item_id = bi.item_id
                      AND bt.account_id = ba.account_id
                      AND bi.agreement = pi_agreement
                      AND bd.doc_class = 'B'
                      AND bt.transaction_class = 'B'
                      AND bt.status NOT IN ( 'C', 'R', 'D' )
                      AND bd.collection_level >= ( SELECT ce.event_level
                                                   FROM blc_coll_events ce,
                                                        blc_lookups bl
                                                   WHERE ce.collection_set_id = ba.collection_set_id
                                                     AND ce.collection_activity_id = bl.lookup_id
                                                     AND bl.lookup_code = 'SUSPEND_POLICY' )
                      AND bt.transaction_id = baa.target_trx
                      AND baa.appl_class = 'PMNT_ON_TRANSACTION'
                      AND baa.status <> 'D'
                      AND baa.reversed_appl IS NULL
                      AND NOT EXISTS ( SELECT 'REVERSING_TRX'
                                       FROM blc_applications
                                       WHERE reversed_appl = baa.application_id
                                         AND status <> 'D' )
                      AND baa.source_payment = bp.payment_id
                      AND bp.status NOT IN ( 'I', 'R', 'D' )
                    GROUP BY bd.doc_id, bd.currency )

      LOOP
          l_doc_open_balance := BLC_DOC_UTIL_PKG.Get_Doc_Open_Balance
                                                      ( pi_doc_id => doc.doc_id,
                                                        pi_doc_currency => doc.currency );

          IF l_doc_open_balance > 0
          THEN
              srv_error.SetErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Get_Max_Value_Date', 'CUST_COLL_UTIL_PKG.GMVD.Inv_Plc_St' );
              srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

              blc_log_pkg.insert_message( l_log_module,
                                          C_LEVEL_EXCEPTION,
                                          'There is a document with open balance (IN)' );

              RETURN ( NULL );
          ELSE
              IF l_max_value_date IS NULL OR l_max_value_date < doc.doc_max_value_date
              THEN
                  l_max_value_date := doc.doc_max_value_date;
              END IF;
          END IF;
      END LOOP;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_max_value_date = ' || l_max_value_date );

      IF l_max_value_date IS NULL
      THEN
          srv_error.SetErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Get_Max_Value_Date', 'CUST_COLL_UTIL_PKG.GMVD.Inv_Plc_St' );
          srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

          blc_log_pkg.insert_message( l_log_module,
                                      C_LEVEL_EXCEPTION,
                                      'There is a document with open balance (OUT)' );

          RETURN ( NULL );
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of function Get_Max_Value_Date' );

      RETURN ( l_max_value_date );
  EXCEPTION
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Get_Max_Value_Date', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                  'pi_agreement = ' || pi_agreement || ' - ' ||
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||  SQLERRM );

      RETURN( NULL );
  END Get_Max_Value_Date;

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Update_Ntf_Trx_Doc
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   17.01.2018  creation
--
-- Purpose: The procedure updates open balance and paid status of the passed
-- notification transaction
--
-- Input parameters:
--     pi_doc_id      NUMBER      Notification transaction ID
--     pio_Err        SrvErr      Specifies structure for passing back the error
--                                code, error TYPE and corresponding message.
--
-- Output parameters:
--     pio_Err        SrvErr      Specifies structure for passing back the error
--                                code, error TYPE and corresponding message.
--
-- Usage: in pkg
--------------------------------------------------------------------------------
PROCEDURE Update_Ntf_Trx_Doc( pi_doc_id IN     NUMBER,
                              pio_Err   IN OUT SrvErr )
IS
    l_log_module  VARCHAR2(240);
    l_SrvErrMsg   SrvErrMsg;
    --
    l_open_balance NUMBER;
    l_actual_balance NUMBER;
    l_ntf_trx_rec BLC_TRANSACTIONS_TYPE;
BEGIN
    l_log_module := C_DEFAULT_MODULE||'.Update_Ntf_Trx_Doc';
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'BEGIN of procedure Update_Ntf_Trx_Doc' );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'pi_doc_id = ' || pi_doc_id );
    --
    FOR cur_ntf IN ( SELECT transaction_id, amount, item_id, account_id, ref_doc_id, open_balance, actual_open_balance
                     FROM blc_transactions bt
                     WHERE bt.doc_id = pi_doc_id
                     ORDER BY transaction_id )
    LOOP
        --
        blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'cur_ntf.transaction_id = ' || cur_ntf.transaction_id );
        --
        SELECT NVL( SUM(open_balance), 0 ), NVL( SUM(actual_open_balance), 0 ) INTO l_open_balance, l_actual_balance
        FROM blc_transactions
        WHERE doc_id = cur_ntf.ref_doc_id
            AND account_id = cur_ntf.account_id
            AND item_id = cur_ntf.item_id
            AND status NOT IN ( 'C', 'R', 'D' );
        --
        IF ( cur_ntf.open_balance IS NOT NULL AND cur_ntf.open_balance <> l_open_balance )
            OR ( cur_ntf.actual_open_balance IS NOT NULL AND cur_ntf.actual_open_balance <> l_actual_balance )
        THEN
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'l_open_balance = ' || l_open_balance );
            blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'l_actual_balance = ' || l_actual_balance );
            --
            l_ntf_trx_rec := NEW BLC_TRANSACTIONS_TYPE( cur_ntf.transaction_id );
            --
            l_ntf_trx_rec.open_balance := l_open_balance;
            IF cur_ntf.actual_open_balance IS NOT NULL
            THEN
                l_ntf_trx_rec.actual_open_balance := l_actual_balance;
            END IF;
            --
            IF cur_ntf.amount = l_ntf_trx_rec.open_balance
            THEN
                l_ntf_trx_rec.paid_status := 'N';
            ELSIF l_ntf_trx_rec.open_balance = 0
            THEN
                l_ntf_trx_rec.paid_status := 'Y';
            ELSIF cur_ntf.amount > l_ntf_trx_rec.open_balance
            THEN
                l_ntf_trx_rec.paid_status := 'P';
            ELSE
                l_ntf_trx_rec.paid_status := 'E';
            END IF;
            --
            IF NOT l_ntf_trx_rec.update_blc_transactions ( pio_Err )
            THEN
                blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'cur_ntf.transaction_id = '|| cur_ntf.transaction_id || ' - '|| pio_Err(pio_Err.FIRST).errmessage);
                RETURN;
            END IF;
        END IF;
    END LOOP;
    --
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_PROCEDURE, 'END of procedure Update_Ntf_Trx_Doc' );
    --
EXCEPTION WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Update_Ntf_Trx_Doc', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
      blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION, 'pi_doc_id = '|| pi_doc_id || ' - '|| SQLERRM );
END Update_Ntf_Trx_Doc;

--------------------------------------------------------------------------------
  -- Name: CUST_COLL_UTIL_PKG.Update_Ntf_Balances
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   18.03.2016  creation
--
-- Purpose: Procedure starts a batch process for all notifications referring at
-- least one document with an open balance which updates every transaction with
-- the current balance of the corresponding billing document
--
-- Input parameters:
--     pi_legal_entity_id     NUMBER       Legal entity id
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr                Specifies structure for passing back
--                                         the error code, error TYPE and
--                                         corresponding message.
--
-- Usage: In a scheduled job
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Update_Ntf_Balances ( pi_legal_entity_id IN NUMBER,
                                  pio_Err IN OUT SrvErr )
  IS
    CURSOR open_balanced_ntf ( x_legal_entity_id IN NUMBER )
    IS SELECT bd.doc_id
       FROM blc_documents bd,
            blc_transactions bt
       WHERE bd.doc_class = 'N'
         AND bd.doc_id = bt.doc_id
         AND bt.status NOT IN ( 'C', 'R', 'D' )
         AND bt.open_balance + NVL(bt.actual_open_balance,0) > 0 -- add NVL 17.01.2018  --( bt.open_balance > 0 OR bt.actual_open_balance > 0 ) -- changed on 04.01.2017
         AND bt.paid_status IN ( 'N', 'P' )
       GROUP BY bd.doc_id;

    l_log_module VARCHAR2(240);
    l_SrvErrMsg SrvErrMsg;
    l_exp_error EXCEPTION;
    l_err_message VARCHAR2(2000);

    l_SrvErr   SrvErr;

  BEGIN
      blc_log_pkg.initialize( pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          l_err_message := pio_Err(pio_Err.FIRST).errmessage;
          RAISE l_exp_error;
      END IF;

      l_log_module := C_DEFAULT_MODULE || '.Update_Ntf_Balances';

      FOR obn IN open_balanced_ntf ( pi_legal_entity_id )
      LOOP
          /*  Comment 17.01.2018
          BLC_OPEN_BAL_STAT_PKG.Update_Ntf_Doc ( pi_ntf_doc_id => obn.doc_id,
                                                 pio_Err => pio_Err );

          IF NOT srv_error.rqStatus( pio_Err )
          THEN
              blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,
                                          'obn.doc_id = ' || obn.doc_id || ' - ' ||
                                          pio_Err(pio_Err.FIRST).errmessage );

              l_err_message := pio_Err(pio_Err.FIRST).errmessage;
              RAISE l_exp_error;
          END IF;*/
          --
          SAVEPOINT UPDT_DOCS;
          --
          l_SrvErr := NULL;
          --
          Update_Ntf_Trx_Doc( obn.doc_id, l_SrvErr );
          --
          IF NOT srv_error.rqStatus( l_SrvErr )
          THEN
              blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION, 'notif doc_id = '|| obn.doc_id ||' - '||l_SrvErr(l_SrvErr.FIRST).errmessage);
              --
              ROLLBACK TO UPDT_DOCS;
              CONTINUE;
          END IF;
      END LOOP;

  EXCEPTION
    WHEN l_exp_error THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Update_Ntf_Balances', l_err_message );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                  l_err_message );
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Update_Ntf_Balances', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_EXCEPTION,
                                  'pi_legal_entity_id = ' || pi_legal_entity_id || ' - ' ||
                                  SQLERRM );
  END Update_Ntf_Balances;

--------------------------------------------------------------------------------
-- Name: CUST_COLL_UTIL_PKG.Update_Ntf_Trx
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   01.04.2016  creation
--
-- Purpose: The procedure updates open balance and paid status of the passed
-- notification transaction based on billing trx list saved in notes column
--
-- Input parameters:
-- pi_ntf_trx_id                NUMBER          Notification transaction ID
--
--
-- Output parameters:
--  pio_Err              SrvErr                   Specifies structure for
--                                                passing back the error
--                                                code, error TYPE and
--                                                corresponding message.
--
-- Returns:
-- N/A
--
-- Usage: N/A
--
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
  PROCEDURE Update_Ntf_Trx ( pi_ntf_trx_id IN NUMBER,
                             pio_Err IN OUT SrvErr )
  IS
    l_ntf_trx_rec BLC_TRANSACTIONS_TYPE;
    l_open_balance NUMBER;
    l_actual_open_balance NUMBER; -- added on 11.12.2016
    l_paid_status VARCHAR2(1);

    l_log_module VARCHAR2(240);
    l_err_message VARCHAR2(2000);
    l_exp_error EXCEPTION;
    l_SrvErrMsg SrvErrMsg;
    l_SrvErr SrvErr;
    l_Context srvcontext;
    l_RetContext srvcontext;

    l_bill_trx_ids BLC_SELECTED_OBJECTS_TABLE;
  BEGIN
      blc_log_pkg.initialize( pio_Err );
      IF NOT srv_error.rqStatus( pio_Err )
      THEN
          RETURN;
      END IF;

      l_log_module := C_DEFAULT_MODULE||'.Update_Ntf_Trx';

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'BEGIN of procedure Update_Ntf_Trx' );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'pi_ntf_trx_id = ' || pi_ntf_trx_id );

      l_ntf_trx_rec := NEW BLC_TRANSACTIONS_TYPE ( pi_ntf_trx_id );

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'l_ntf_trx_rec.notes = ' || l_ntf_trx_rec.notes );

      l_bill_trx_ids := blc_common_pkg.convert_list( l_ntf_trx_rec.notes );

      SELECT SUM( open_balance ), SUM( actual_open_balance), DECODE ( SUM( open_balance ), 0, 'Y', SUM( amount ), 'N', 'P' )   --changed on 04.01.2017 --MAX( paid_status )
      INTO l_open_balance, l_actual_open_balance, l_paid_status
      FROM blc_transactions
      WHERE transaction_id IN ( SELECT * FROM TABLE( l_bill_trx_ids ) )
        AND status NOT IN ( 'C', 'R', 'D' );

      l_ntf_trx_rec.open_balance := l_open_balance;
      l_ntf_trx_rec.actual_open_balance := l_actual_open_balance; -- changed on 04.01.2017 -- := 0;
      l_ntf_trx_rec.paid_status := l_paid_status;

      IF NOT l_ntf_trx_rec.update_blc_transactions ( pio_Err )
      THEN
          blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                  'pi_ntf_trx_id = '|| pi_ntf_trx_id || ' - '||
                  'l_open_balance = '|| l_open_balance || ' - '||
                  'l_actual_open_balance = '|| l_actual_open_balance || ' - '||
                  'l_paid_status = '|| l_paid_status || ' - '|| pio_Err(pio_Err.FIRST).errmessage);

          l_err_message := pio_Err(pio_Err.FIRST).errmessage;
          RAISE l_exp_error;
      END IF;

      blc_log_pkg.insert_message( l_log_module,
                                  C_LEVEL_PROCEDURE,
                                  'END of procedure Update_Ntf_Trx' );
  EXCEPTION
    WHEN l_exp_error THEN
      srv_error.SetErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Update_Ntf_Trx', l_err_message );
      srv_error.SetErrorMsg( l_SrvErrMsg, l_SrvErr );

      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                  'pi_ntf_trx_id = '|| pi_ntf_trx_id || ' - '|| pio_Err(pio_Err.FIRST).errmessage);
    WHEN OTHERS THEN
      srv_error.SetSysErrorMsg( l_SrvErrMsg, 'CUST_COLL_UTIL_PKG.Update_Ntf_Trx', SQLERRM );
      srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );

      blc_log_pkg.insert_message(l_log_module, C_LEVEL_EXCEPTION,
                  'pi_ntf_trx_id = '|| pi_ntf_trx_id || ' - '|| pio_Err(pio_Err.FIRST).errmessage);
  END Update_Ntf_Trx;

--------------------------------------------------------------------------------
-- Name: cust_util_pkg.Create_Bad_Debit
--
-- Type: PROCEDURE
--
-- Subtype: DATA_PROCESSING
--
-- Status: ACTIVE
--
-- Versioning:
--     Fadata   01.02.2018  creation
--
-- Purpose: Create bad debit notes
--
-- Input parameters:
--     pi_office        VARCHAR2    Insis Office(required)
--     pio_Err          SrvErr      Specifies structure for passing back
--                                  the error code, error TYPE and
--                                  corresponding message.
--
-- Output parameters:
--     pio_Err       SrvErr        Specifies structure for passing back
--                                 the error code, error TYPE and
--                                 corresponding message.
--
-- Usage: Close date
--
-- Exceptions: N/A
--
-- Dependences: N/A
--
-- Note: N/A
--------------------------------------------------------------------------------
PROCEDURE Create_Bad_Debit( pi_office   IN VARCHAR2,
                            pio_Err     IN OUT SrvErr )
IS
    l_log_module      VARCHAR2(240);
    l_SrvErrMsg       SrvErrMsg;
    --
    l_le_id              NUMBER;
    l_count_updated_docs NUMBER;
    l_err_doc_count      PLS_INTEGER; -- LPV-1042
    --
    l_Context         SRVContext;
    l_RetContext      SRVContext;
BEGIN
    blc_log_pkg.initialize(pio_Err);
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    l_log_module := C_DEFAULT_MODULE||'.Create_Bad_Debit';
    blc_log_pkg.insert_message( l_log_module,C_LEVEL_PROCEDURE,'BEGIN of procedure Create_Bad_Debit' );
    blc_log_pkg.insert_message( l_log_module,C_LEVEL_PROCEDURE,'pi_office = ' || pi_office );
    --
    IF pi_office IS NULL
    THEN RETURN;
    END IF;
    --
    srv_context.SetContextAttrChar( l_Context, 'USERNAME', 'insis_gen_v10' );
    srv_context.SetContextAttrChar( l_Context, 'USER_ENT_ROLE', 'InsisStaff' );
    --
    srv_events.sysEvent( srv_events_system.GET_CONTEXT, l_Context, l_RetContext, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN
       RETURN;
    END IF;
    --
    l_le_id := blc_common_pkg.Get_LE_Id_Office( pi_office, pio_Err );
    IF NOT srv_error.rqStatus( pio_Err )
    THEN RETURN;
    END IF;
    --
    IF l_le_id IS NOT NULL
    THEN
        Execute_BDC_Strategies( pi_legal_entity_id    => l_le_id,
                                pi_org_id             => NULL,
                                pi_to_date            => NULL,
                                pi_agreement          => NULL,
                                pi_account_id         => NULL,
                                po_count_updated_docs => l_count_updated_docs,
                                po_count_errors       => l_err_doc_count, -- LPV-1042
                                pio_Err               => pio_Err );
        IF NOT srv_error.rqStatus( pio_Err )
        THEN RETURN;
        END IF;
    END IF;
    --
    -- Begin  LPV-1042
    IF l_err_doc_count > 0
    THEN
        srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_util_pkg.Create_Bad_Debit', 'ERROR. See log table cust_bdc_error_log (' || l_err_doc_count || ' )' );
        srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    END IF;
    -- End  LPV-1042
    --
    blc_log_pkg.insert_message( l_log_module,C_LEVEL_PROCEDURE,'END of procedure Create_Bad_Debit' );
EXCEPTION WHEN OTHERS THEN
    srv_error.SetSysErrorMsg( l_SrvErrMsg, 'cust_util_pkg.Create_Bad_Debit', SQLERRM );
    srv_error.SetErrorMsg( l_SrvErrMsg, pio_Err );
    blc_log_pkg.insert_message( l_log_module, C_LEVEL_EXCEPTION,'pi_office = '||pi_office||' - '||SQLERRM );
END Create_Bad_Debit;
--
END CUST_COLL_UTIL_PKG;
/


