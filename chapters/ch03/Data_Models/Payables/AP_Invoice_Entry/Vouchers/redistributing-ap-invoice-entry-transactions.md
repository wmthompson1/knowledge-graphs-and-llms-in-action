# Redistributing A/P Invoice Entry Transactions

Redistribution reassigns line distributions to different GL accounts, cost centers, or jobs after the initial entry.

When to redistribute:

- Incorrect GL account selected at entry
- Reallocating costs across multiple projects or cost centers
- Correcting allocation errors discovered during PO/GRN reconciliation

Steps to redistribute:

1. Open the voucher and locate the line(s) to be redistributed.
2. Edit the distribution details (GL account, department, job) for each affected line or use a redistribution tool if provided.
3. Save changes and run a pre-post validation report to confirm totals and distributions.
4. If the voucher was already posted, follow the approved correction or reversal workflow — redistribution may require offset entries if GL was impacted.

Notes:

- Track redistribution reasons in the voucher notes for audit.
- Large redistributions across many vouchers are often performed via a mass-redistribution utility or a spreadsheet import; test on a copy environment first.

Index: `../../../Accounts_Payable_INDEX.md`
