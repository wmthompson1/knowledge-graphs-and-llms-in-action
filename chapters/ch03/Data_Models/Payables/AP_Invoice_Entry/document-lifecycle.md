# Document Lifecycle

A/P documents follow a sequence from creation through settlement. This lifecycle helps auditors and operators understand permitted transitions.

States:

1. **Draft / Created** — Voucher created but not approved or posted. Editable.
2. **Matched / Approved** — Voucher has been matched to receipts and approved for payment.
3. **Pending Payment** — Voucher is approved and included in a payment proposal or batch.
4. **Paid / Cleared** — Payment has been issued; status changes when bank clears the payment.
5. **Voided / Reversed** — Voucher or payment has been voided; GL corrections may be required.
6. **Archived** — Old vouchers may be archived for retention policies.

Controls:

- Approval workflows should be enforced before moving a document from Draft to Approved.
- Maintain timestamps and user IDs for each state change for auditability.

Index: `../../Accounts_Payable_INDEX.md`
