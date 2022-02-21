CREATE OR REPLACE PACKAGE INSIS_BLC_GLOBAL_CUST.CUST_PAS_TRANSFER_PKG AS
--------------------------------------------------------------------------------
-- PACKAGE DESCRIPTION:
-- Package contains auxiliary functions used during PAS transfer
--------------------------------------------------------------------------------

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
PROCEDURE Pre_Process_Item ( pio_Err IN OUT SrvErr );

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
PROCEDURE Pre_Process_Installments( pio_Err IN OUT SrvErr );

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
PROCEDURE Compensate_Item_Installments( pio_Err    IN OUT SrvErr );

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
RETURN BOOLEAN;
--
END CUST_PAS_TRANSFER_PKG;
/


