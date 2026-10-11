--MODEL (
--    name = three_way_match,
--    kind = INCREMENTAL_BY_TIME_RANGE,
--    start = '2010-01-01',
--    time_column = event_ts,
--    cron = '@daily',
--    owner = 'mrp'
--);

-- This is AI designed SQL code for a three-way match model that combines purchase orders, receipts, 
--and payables to determine the match state of each line item. The model uses Common Table Expressions (CTEs) 
--to extract relevant data from the PURC_ORDER_LINE, RECEIVER_LINE, RECEIVER, PAYABLE_LINE, and PAYABLE tables. 
--It then performs a full outer join on these CTEs to create a comprehensive view of the three-way match status for 
--each purchase order line item.

-- would youi determine what the invoice_document_exists column should be based on the presence of an invoice document
-- in the system.

-- currently renders error:
/*
Msg 207, Level 16, State 1, Line 160
Invalid column name 'invoice_document_exists'

*/

declare @START_DATE datetime = '2026-04-01';
declare @PURC_ORDER_ID nvarchar(15) = '191875';

WITH po AS (
    SELECT
        pu.VENDOR_ID,
        pol.PURC_ORDER_ID,
        pol.LINE_NO,
        pol.PART_ID,
        pol.ORDER_QTY,
        pol.UNIT_PRICE,
        pol.DESIRED_RECV_DATE,
        pol.LAST_RECEIVED_DATE,
        pol.TOTAL_RECEIVED_QTY,
        pol.TOTAL_AMT_ORDERED,
        pol.TOTAL_AMT_RECVD,
        -- Format for sql server 2019 and later, using VALUES to get the max of multiple columns
        (
            SELECT MAX(v)
            FROM (VALUES (pol.LAST_RECEIVED_DATE),
                         (pol.DESIRED_RECV_DATE)) AS value_list(v)
        ) AS po_event_ts

    FROM dbo.PURC_ORDER_LINE pol
    INNER JOIN dbo.PURCHASE_ORDER pu
      ON pol.PURC_ORDER_ID = pu.ID
    where 1=1
      and (pu.[ORDER_DATE] >= @START_DATE or @START_DATE is null)
      and (@PURC_ORDER_ID is null or pu.ID = @PURC_ORDER_ID)
),

recv AS (
    SELECT
                po.PURC_ORDER_ID,
                po.LINE_NO AS PURC_ORDER_LINE_NO,
        rl.RECEIVER_ID,
        rl.LINE_NO AS RECEIVER_LINE_NO,
        rl.RECEIVED_QTY,
        rl.INSPECT_QTY,
        rl.REJECTED_QTY,
        rl.WAREHOUSE_ID,
        rl.LOCATION_ID,
        rl.TRANSACTION_ID,
        r.RECEIVED_DATE,
        r.RECEIVED_DATE AS recv_event_ts
        FROM po
        LEFT JOIN dbo.RECEIVER_LINE rl
            ON rl.PURC_ORDER_ID = po.PURC_ORDER_ID
         AND rl.PURC_ORDER_LINE_NO = po.LINE_NO
        LEFT JOIN dbo.RECEIVER r
            ON r.ID = rl.RECEIVER_ID
),

pay AS (
    SELECT
            po.PURC_ORDER_ID,
            po.LINE_NO AS PURC_ORDER_LINE_NO,
            pl.VOUCHER_ID,
            pl.RECEIVER_ID,
            pl.RECEIVER_LINE_NO,
            pl.QTY AS INVOICED_QTY,
            pl.AMOUNT AS INVOICED_AMOUNT,
            p.INVOICE_ID,
            CASE WHEN p.INVOICE_ID IS NOT NULL THEN 1 ELSE 0 END AS invoice_document_exists,
            p.INVOICE_DATE,
            p.PAYMENT_DATE,
            p.POSTING_DATE,
            p.POSTING_DATE AS pay_event_ts
        FROM po
        LEFT JOIN dbo.PAYABLE_LINE pl
            ON pl.PURC_ORDER_ID = po.PURC_ORDER_ID
         AND pl.PURC_ORDER_LINE_NO = po.LINE_NO
        LEFT JOIN dbo.PAYABLE p
            ON p.VOUCHER_ID = pl.VOUCHER_ID
)
-- -- select * from po;

SELECT
    po.PURC_ORDER_ID,
     po.LINE_NO,

    -- Contractual truth
    CASE WHEN po.PURC_ORDER_ID IS NOT NULL THEN 1 ELSE 0 END AS po_exists,

    -- Physical truth
    CASE WHEN recv.RECEIVER_ID IS NOT NULL THEN 1 ELSE 0 END AS receiver_exists,
    recv.RECEIVER_ID,

    -- Financial truth
    CASE WHEN pay.VOUCHER_ID IS NOT NULL THEN 1 ELSE 0 END AS voucher_exists,

    -- Document truth
    pay.invoice_document_exists,

    -- Quantities
    po.ORDER_QTY,
    recv.RECEIVED_QTY,
    pay.INVOICED_QTY,

    -- Dates
    po.DESIRED_RECV_DATE,
    recv.RECEIVED_DATE,
    pay.INVOICE_DATE,
    pay.POSTING_DATE,

    ---- Incremental event timestamp
    --GREATEST(
    --    po.po_event_ts,
    --    recv.recv_event_ts,
    --    pay.pay_event_ts
    --) AS event_ts,
    -- Format for sql server 2019 and later, using VALUES to get the max of multiple columns
       (
            SELECT MAX(v)
            FROM (VALUES (po.po_event_ts),
                         (recv.recv_event_ts),
                         (pay.pay_event_ts)) AS value_list(v)
        ) AS event_ts,

    -- Three‑Way Match State
    CASE
        WHEN po.PURC_ORDER_ID IS NOT NULL
         AND recv.RECEIVER_ID IS NULL
         AND pay.VOUCHER_ID IS NULL
        THEN 'Ordered_Not_Received_Not_Invoiced'

        WHEN po.PURC_ORDER_ID IS NOT NULL
         AND recv.RECEIVER_ID IS NOT NULL
         AND pay.VOUCHER_ID IS NULL
        THEN 'Received_Not_Invoiced_GRNI'

        WHEN po.PURC_ORDER_ID IS NOT NULL
         AND recv.RECEIVER_ID IS NOT NULL
         AND pay.VOUCHER_ID IS NULL
         AND 1 = 1
        THEN 'Plant_Stacked_Invoice'

        WHEN po.PURC_ORDER_ID IS NOT NULL
         AND recv.RECEIVER_ID IS NULL
         AND pay.VOUCHER_ID IS NOT NULL
        THEN 'Invoiced_Not_Received'

        WHEN po.PURC_ORDER_ID IS NOT NULL
         AND recv.RECEIVER_ID IS NOT NULL
         AND pay.VOUCHER_ID IS NOT NULL
        THEN 'Fully_Matched'

        WHEN po.PURC_ORDER_ID IS NULL
         AND recv.RECEIVER_ID IS NOT NULL
         AND pay.VOUCHER_ID IS NULL
        THEN 'Unexpected_Receipt'

        WHEN po.PURC_ORDER_ID IS NULL
         AND recv.RECEIVER_ID IS NOT NULL
         AND pay.VOUCHER_ID IS NOT NULL
        THEN 'Receipt_And_Invoice_No_PO'

        WHEN po.PURC_ORDER_ID IS NULL
         AND recv.RECEIVER_ID IS NULL
         AND pay.VOUCHER_ID IS NOT NULL
        THEN 'Invoice_No_PO_No_Receipt'

        WHEN pay.VOUCHER_ID IS NOT NULL
        AND pay.invoice_document_exists = 0
        THEN 'Voucher_No_Invoice_In_Processing'

        ELSE 'No_Activity'
    END AS match_state,
  'test' AS note
FROM po
LEFT JOIN recv
    ON recv.PURC_ORDER_ID = po.PURC_ORDER_ID
 AND recv.PURC_ORDER_LINE_NO = po.LINE_NO
LEFT JOIN pay
    ON pay.PURC_ORDER_ID = po.PURC_ORDER_ID
 AND pay.PURC_ORDER_LINE_NO = po.LINE_NO;