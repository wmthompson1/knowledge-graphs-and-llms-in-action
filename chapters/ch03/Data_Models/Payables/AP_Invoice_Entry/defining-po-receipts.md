# Defining Purchase Order Receipts

How PO receipts are defined and linked to invoice entry.

PO Accrual Report


# PO Accrual Report

Use this report to help reconcile PO accrual. Compare the information
in this report to the information in the Uninvoiced Receivers Report
Detail. Use this report for both project and non-project transactions.

1. From the Ledger menu,
   select Post Manufacturing Journals.
   The Post Manufacturing Journals window appears.
2. From the Reports menu,
   select Print PO Accrual. The Print PO
   Accrual window appears.
3. In the Print PO Accrual
   dialog box, in the Print Selection section, click the Site ID(s)
   arrow and select the sites to use.
4. In the Print Select
   box, enter a date that falls within the period you would like
   to close in the End Date of Accounting Period field. VISUAL adjusts
   the date to the last day in the period and populates the Fiscal
   Period field.
5. Select the Summary
   check box to view a summary report. Leave the Summary check box
   blank to view a detailed report.
6. Click Ok.
   The report outputs.

```SQL
/**
7.  Any transactions that debit the PRA (purchase receipts accrual) account but does not reference a receiver can found by running the following SQL statement.  Replace the variable with the PRA account:
**/

SELECT * FROM PAYABLE_LINE WHERE GL_ACCOUNT_ID = '205' AND RECEIVER_ID IS NULL

```


```SQL
   /**
If the above steps do not identify the issue, in a fully costed, static environment:

If an invoice exists but the receiver remains on the reports, RECEIVER_LINE and PAYABLE_LINE can be compared to review the 5 fields the accrual report looks at:  Purchase order ID, Purchase order line no, Receiver ID, Receiver line no and User Received Qty.
**/

SELECT PURC_ORDER_ID, PURC_ORDER_LINE_NO, RECEIVER_ID, LINE_NO, USER_RECEIVED_QTY
FROM RECEIVER_LINE WHERE RECEIVER_ID = '<ENTER RECEIVER ID HERE>'

SELECT VOUCHER_ID, PURC_ORDER_ID, PURC_ORDER_LINE_NO, RECEIVER_ID, RECEIVER_LINE_NO, QTY
FROM PAYABLE_LINE WHERE RECEIVER_ID = '<ENTER RECEIVER ID HERE>'
```

```SQL
/**
The PAYABLE table will show the invoice status:

X = Void, which would reopen the receiver
L = Log.  An invoice with a logged status does not create distributions therefore, the receivers referenced will continue to show on the PO Accrual Report.
H = Hold.  Invoice will not be paid.  This will not impact the PO Accrual Report.

**/

SELECT VOUCHER_ID, PAY_STATUS, LANDED_COST_INV FROM PAYABLE WHERE VOUCHER_ID IN 
(SELECT VOUCHER_ID FROM PAYABLE_LINE WHERE RECEIVER_ID = '<ENTER RECEIVER ID HERE>')
```


[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](User_defined_Help_Files_Period_Closing.md) User-defined Help

Index: `../../Accounts_Payable_INDEX.md`


