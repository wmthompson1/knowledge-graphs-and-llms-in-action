# Creating A/P Invoices from Purchase Order Receipts

Use the PO Receipt-to-Invoice flow to match vendor invoices to goods received and avoid duplicate billing.

Typical flow:

1. Ensure the Purchase Order and Receipt records exist and quantities are confirmed.
2. In `Invoice Entry`, choose `Create From Receipts` (menu label may vary) and select the relevant receipts or PO numbers.
3. The system will attempt to match receipt line quantities and item codes to create invoice line suggestions. Review suggested lines for price or quantity discrepancies.
4. For exceptions (price variance, partial receipts), edit the invoice lines or flag the item for PO follow-up.
5. Save the invoice; optionally route exceptions to a review queue prior to posting.

Matching rules and notes:

- Tolerances: Many sites set a price/quantity tolerance to auto-accept small variances.
- Receipts without matching invoices will remain available in `Uninvoiced Receipts` for manual invoicing.
- Use the `PO Number` and `Receipt ID` in references to maintain traceability.

Index: `../../Accounts_Payable_INDEX.md`
