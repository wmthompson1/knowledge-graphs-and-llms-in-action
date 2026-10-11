
/**********************************************************************************************
Description:
Sample:
Date      Modified By      Change Description
---------- ------------------ ------------------------------------------------------------
07/07/2026  Williamt  Initial version of the uninvoiced receipts query for 3WM.
**********************************************************************************************/



/*

Lineage summary
- Purchase order header: PURCHASE_ORDER -> RECEIVER -> RECEIVER_LINE
- Payable match check: RECEIVER_LINE -> PAYABLE_LINE -> PAYABLE
- Vendor enrichment: PURCHASE_ORDER -> VENDOR

Field descriptions
- Query_Name: Report label for this exception extract.
- RECEIVER_ID: Receipt header identifier from RECEIVER.ID.
- RECEIVED_DATE: Receipt date from RECEIVER.RECEIVED_DATE.
- PURC_ORDER_ID: Purchase order number from RECEIVER.PURC_ORDER_ID.
- VENDOR_ID: Vendor code from VENDOR.ID.
- VENDOR_NAME: Vendor display name from VENDOR.NAME.
- SITE_ID: Site code from RECEIVER.SITE_ID.

Join-driving columns used in the exception logic
- RECEIVER_LINE.USER_RECEIVED_QTY: Quantity recorded on the receipt line.
- RECEIVER_LINE.LINE_NO: Receiver line identifier.
- PAYABLE_LINE.QTY: Payable quantity matched to the receiver line.
- PAYABLE_LINE.RECEIVER_LINE_NO: Receiver line reference on the payable line.
- PAYABLE.PAY_STATUS: Payable status used to exclude landed-cost and canceled vouchers.
- PAYABLE.VOUCHER_ID: Voucher key that anchors the payable header/line relationship.

*/

SELECT DISTINCT 
     'Uninvoiced Receipts' Query_Name
   , R.ID RECEIVER_ID
   , R.RECEIVED_DATE
   , R.PURC_ORDER_ID
   , V.ID VENDOR_ID
   , V.NAME VENDOR_NAME
   , R.SITE_ID
FROM RECEIVER R,
     RECEIVER_LINE RL,
     PURCHASE_ORDER P,
     VENDOR V
WHERE R.PURC_ORDER_ID = P.ID
  AND P.VENDOR_ID = V.ID
  AND RL.RECEIVER_ID = R.ID
  AND (
        (
            RL.USER_RECEIVED_QTY > (
                SELECT ISNULL(SUM(ABS(PL.QTY)), 0)
                FROM PAYABLE_LINE PL,
                     PAYABLE P
                WHERE PL.RECEIVER_ID = RL.RECEIVER_ID
                  AND PL.RECEIVER_LINE_NO = RL.LINE_NO
                  AND PL.VOUCHER_ID = P.VOUCHER_ID
                  AND P.PAY_STATUS <> N'L'
                  AND P.PAY_STATUS <> N'X'
            )
        )
        OR (
            RL.LINE_NO NOT IN (
                SELECT PL.RECEIVER_LINE_NO
                FROM PAYABLE_LINE PL,
                     PAYABLE P
                WHERE PL.RECEIVER_ID = RL.RECEIVER_ID
                  AND PL.VOUCHER_ID = P.VOUCHER_ID
                  AND P.PAY_STATUS <> N'L'
                  AND P.PAY_STATUS <> N'X'
            )
        )
      )
  AND R.SITE_ID IN (N'SK01')
ORDER BY V.ID, R.SITE_ID, R.RECEIVED_DATE ASC;