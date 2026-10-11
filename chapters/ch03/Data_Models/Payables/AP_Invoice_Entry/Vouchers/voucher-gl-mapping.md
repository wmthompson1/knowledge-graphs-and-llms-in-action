# Voucher GL Mapping Examples

This page provides example GL mapping patterns you can adapt for your environment. These are templates — confirm with your chart of accounts and posting rules before using in production.

## Typical mappings

- **AP Invoice (header)**:
  - Debit: Expense or Inventory (depending on invoice type) — e.g. `EXPENSE_ACCT_ID` or `INV_RECEIPT_ACCT`
  - Credit: Accounts Payable Control — e.g. `AP_CONTROL_ACCT`

- **AP Invoice (distribution lines)**:
  - Debit: Specific expense/COGS/asset account based on distribution (`PAYABLE_DIST` → `DIST_ACCT_ID`)
  - Credit: Accounts Payable Control (header-level) or payables clearing if separate entries are used

- **AP Tax lines**:
  - Debit: Tax Expense / Tax Payable (as configured) — separate tax GL mapping may be required

- **AP Payment**:
  - Debit: Accounts Payable Control (clears the vendor balance)
  - Credit: Bank/Cash Account (`BANK_ACCOUNT_ACCT_ID`)

## Example workflow (purchase receipt → invoice → payment)

1. Receipt of goods creates inventory receipt accounting (inventory and accrual) depending on costing method.
2. AP Invoice matched to receiver: invoice creates `PAYABLE` and `PAYABLE_DIST` rows; header-credit to AP control, distribution debits to expense/inventory accounts.
3. When payment is issued, `CASH_DISBURSEMENT` and `CASH_DISBURSE_LINE` reduce bank balance and clear `PAYABLE` by voucher ID.

## Notes & placeholders

- Replace `AP_CONTROL_ACCT`, `EXPENSE_ACCT_ID`, and `BANK_ACCOUNT_ACCT_ID` with real GL account IDs from your `ACCOUNT` table or GL mapping maintenance.
- If you use multi-currency, reference `PAYABLE_CURR` for currency amounts and ensure FX postings are handled (gain/loss accounts).

_Source: adapted guidance and typical VISUAL postings — tailor to your company setup._
