# Adding Drill-to Buttons to Query Results (drill-to guidance)

To add drill-to buttons to query results, clear the **No Auto Joining** checkbox when writing the query. Drill-to buttons are added automatically provided your query includes the required primary or foreign keys and columns. You must explicitly select the database columns in your query (for example, `SELECT r.ID, r.PURC_ORDER_ID, r.SITE_ID FROM RECEIVER r`)—`SELECT *` does not activate drill-to links.

Key drill-to mapping relevant to A/P:

| Database Column | Drills to |
| --- | --- |
| `VOUCHER_ID` | Accounts Payable Invoice Entry |
| `VENDOR_ID` | Vendor Maintenance |
| `SITE_ID` | Site Maintenance |

Notes:
- Include the appropriate entity ID columns in the query to activate links.
- The drill-to feature relies on explicit column selections and the presence of keys/IDs in the result set.

_Source: Adding_Drill-to_Buttons_to_Query_Results.htm (converted)._ 

**See also:**
![nav](btn_mini.gif) `Query tool drill-to icons`
