Uninvoiced Receivers Report - Detailed

1. I reviewed the uninvoiced receiver
2. it included partial lines paidUninvoiced Receipts Report Detailed.
3. this doc from the ERP is the first and only
4. will look on infor support site
5. KB0810989 for POA report: POA includes only pre-costing-utilities amounts 
6. KB0731384
6. Payables | Invoice Entry | File | 


# Uninvoiced Receivers Report Detailed

To make sure that invoices have been entered for all
payables for the month, run the Uninvoiced Receipts report.

1. From the Payables menu,
   select Invoice Entry. The Accounts Payable
   Invoice Entry window appears.
2. From the File menu,
   select Print Uninvoiced Receipts Report Detailed.
   The Print Uninvoiced Receipts Report Detailed report window appears.
3. In the Print Uninvoiced
   Receipt Detail dialog box, click the Site ID(s) arrow and select
   the sites to use.
4. In the Starting Date
   field, enter the first date of the period you would like to close.
   In the Ending Date field, enter the last date of the period you
   would like to close.
5. In the Status box, select
   the types of invoices you would like to view in the report. For
   the most complete report, select all options. Your options are

   * Released
   * Closed
   * Cancelled
6. In the Sequence box,
   select the order for the report. You can sort the report by Purchase Order ID or Vendor
   ID.
7. In the Type box, select
   Summary to view a summary report or
   Detailed to view a detailed report. We recommend running a detailed
   report. The detailed report shows purchase order line detail.
8. Click Ok.
   The report outputs.

[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](User_defined_Help_Files_Period_Closing.md) User-defined Help

KB0741516

How a Purchase Order Flows through VISUAL Financials.


Description : How a Purchase Order Flows through VISUAL Financials.

Resolution :
A purchase order flows through VISUAL Financials as follows:

1. In Purchasing/Purchase Order Entry, create a new purchase order for a purchased part.
2. In Purchasing/Purchase Receipt Entry, receive the purchase order.
3. In Ledger/Costing Utilities, run the top two options and prepare the purchase journal.
4. In Ledger/Post Manufacturing Journals, post the Purchase Journal.

The postings will show the following:

DR Inventory
CR Purchase Receipt Accrual (PRA)

5. In Payables/Invoice Entry, invoice this receiver by clicking F6 to format the receiver. Enter the invoice information and save. Post to Ledger.

The postings will show the following:

DR PRA
CR Accounts Payable

This clears out the PRA account, leaving a DR to inventory and CR to AP.

6. In Payables/Payment Entry, pay the invoice. Post the payment.

The postings will show the following:

DR AP
CR Cash

This clears out the AP account, leaving a DR to Inventory and CR to Cash.

If the invoice is for a different dollar amount than the value of the receiver, a message will be generated. If processed and in Admin/Application Global Maintenance the Source of Raw Material is set to AP Invoice, the receiver will be updated with the value from the invoice. These postings would leave a balance in the PRA account.

The next time Costing runs and the Purchasing journal is prepared, the balance in the PRA account will be cleared, with an offsetting entry to Inventory.

For example:

Receipt entered for 1 @ 100.00
Inventory transaction record created for qty=1, value = 100.00

Purchasing journals prepared:

DR Inventory 100.00
CR PRA 100.00

Invoice is entered against the receipt for 110.00

Invoice generates the following:

DR PRA 110
CR A/P 110

Inventory transaction record updated for qty=1 , value = 110.00

The next time purchase journals are prepared, costing will:

CR PRA 10
DR Inventory 10

The PRA account is then fully relieved; there is no variance entry because the value on the po receipt is changed to the invoice value so it's the inventory account and PRA.

If there is a return, the return is valued based on the IN transaction it is linked to unless the purchase order is directly linked to a work order.  If the purchase order is directly linked, the return takes its value from the receipt.  If it is not directly linked, how the return is valued is is controlled by the FIFO method and the perspicuous setting.  Referenced linked KBA 937847 for FIFO By Part or 1004604 for FIFO By Part Location.

If the memo is entered in Payables with a different value than the return, the return value is NOT overridden by the invoice as its value has been derived from the FIFO layer.  If there is a difference, the PO Accrual account is relieved by the amount of the return as it exists on the inventory_trans table and any difference is then booked to the Purchase Receipt Expense (PRE) account unless the purchase order is directly expensed.  If the purchase order is directly expensed (no part ID; GL expense account ID entered), the difference goes to the GL expense account ID on the line. 

For example:

PO entered and received for 1 @ $100.00
Inventory transaction valued at $100.00
Return the material. The return is valued at 90.00 due to FIFO layer linking.

When Costing is run and the Purchasing journal is prepared, the postings as follows:

DR Inventory    $-90.00
CR        PRA $-90.00

The memo is then entered into Payables for 100.00. 

AP Postings:

DR Accounts Payable $100.00
CR PRE $10.00
CR PRA $90.00

If this is a directly expensed PO, the Purchase Return Expense account is NOT used since the REAL expense account is used. The $10 would go against the expense account on the PO.


Note :
If the purchase order is entered and/or received at the wrong price, refer to linked KB732341.



____________________________