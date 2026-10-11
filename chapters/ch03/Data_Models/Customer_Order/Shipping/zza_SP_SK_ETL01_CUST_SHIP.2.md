## Problem: Code for SP_SK_ETL03_CUST_SHIP in SP_SK_ETL01_CUST_SHIP 

Problem: Code for SP_SK_ETL03_CUST_SHIP was placed in procedure SP_SK_ETL01_CUST_SHIP test file Documentation\Schema\Data_Models\Customer_Order\Shipping\zza_SP_SK_ETL01_CUST_SHIP.sql
made a comprison to SP_SK_ETL03_CUST_SHIP in test file Documentation\Schema\Data_Models\Customer_Order\Shipping\zza_SP_SK_ETL03_CUST_SHIP.sql
This is an unimplemented plan.

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL01_CUST_SHIP.md)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL01_CUST_SHIP.sql), lines 600 to 712

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL03_CUST_SHIP.sql)

sqlmesh-tools-list_directory
Completed with input: {"serverName":"sqlmesh-tools","toolName":"sqlmesh-tools-list_directory"}

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL01_CUST_SHIP.sql), lines 1 to 60

Searched for `SP_SK_ETL03_CUST_SHIP|CREATE PROCEDURE|ALTER PROCEDURE`

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_03.sql)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_01.sql), lines 580 to 650

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL01_CUST_SHIP.sql), lines 575 to 615

"sqlmesh-tools-save_file" failed
Completed with input: {"serverName":"sqlmesh-tools","toolName":"sqlmesh-tools-save_file"}

Read [](file:///c%3A/Users/williamt/.copilot/session-state/cef2e1d1-1c83-47fe-a887-70f948c00d32/plan.md)
Completed with input: {
  "path": "C:\\Users\\williamt\\.copilot\\session-state\\cef2e1d1-1c83-47fe-a887-70f948c00d32\\plan.md"
}

Edited [](file:///c%3A/Users/williamt/.copilot/session-state/cef2e1d1-1c83-47fe-a887-70f948c00d32/plan.md)

Insert comparison plan todos
Completed with input: {
  "description": "Insert comparison plan todos",
  "query": "INSERT INTO todos (id, title, description, status) VALUES\n  ('extract-blocks', 'Extract ETL03 code blocks', 'Extract the misplaced SP_SK_ETL03 block from zza_SP_SK_ETL01_CUST_SHIP.sql (~lines 609-699) and the canonical block from sp_Shipments_Core_Feed_03.sql.', 'pending'),\n  ('analyze-differences', 'Analyze differences between blocks', 'Compare the two blocks and identify meaningful differences (table names, LIVEARC branches, BASE_TABLE filters, date casting, etc.).', 'pending'),\n  ('write-comparison-doc', 'Write comparison document', 'Create a Markdown comparison document in the Shipping directory.', 'pending'),\n  ('verify-doc', 'Verify comparison document', 'Review the comparison document for accuracy and readability.', 'pending');"
}

Insert comparison todo dependencies
Completed with input: {
  "description": "Insert comparison todo dependencies",
  "query": "INSERT INTO todo_deps (todo_id, depends_on) VALUES\n  ('analyze-differences', 'extract-blocks'),\n  ('write-comparison-doc', 'analyze-differences'),\n  ('verify-doc', 'write-comparison-doc');"
}

Ask User
Completed with input: {
  "question": "Where should the comparison document live, and what should it cover?",
  "choices": [
    "Create a new `SP_SK_ETL03_comparison.md` in the Shipping folder (recommended)",
    "Append the comparison to the existing `CHANGELOG.md`",
    "Update `zza_SP_SK_ETL01_CUST_SHIP.md` with the comparison",
    "Something else"
  ]
}

Ask User
Completed with input: {
  "question": "Should I also clean up the source files?",
  "choices": [
    "No — only document the comparison, leave SQL files untouched",
    "Yes — remove the misplaced ETL03 block from `zza_SP_SK_ETL01_CUST_SHIP.sql`",
    "Yes — remove the misplaced block AND note/rename the misnamed `zza_SP_SK_ETL03_CUST_SHIP.sql`",
    "Something else"
  ]
}

Edited [](file:///c%3A/Users/williamt/.copilot/session-state/cef2e1d1-1c83-47fe-a887-70f948c00d32/plan.md)

Exited plan mode
Completed with input: {
  "summary": "- **Goal:** Document a comparison showing that `zza_SP_SK_ETL01_CUST_SHIP.sql` contains a block of `SP_SK_ETL03_CUST_SHIP` logic (lines ~609–699) and how that logic differs from the canonical implementation in `sp_Shipments_Core_Feed_03.sql`.\n- **Approach:** Extract both code blocks, identify meaningful differences, and create a new `SP_SK_ETL03_comparison.md` in the Shipping directory.\n- **Files changed:** New `SP_SK_ETL03_comparison.md` only; SQL source files will not be modified.\n- **Key decisions:** Comparison will be a standalone Markdown file; no cleanup of the misplaced code; the misnamed `zza_SP_SK_ETL03_CUST_SHIP.sql` will be noted as actually containing `SP_SK_ETL02_CUST_SHIP`.",
  "recommendedAction": "interactive",
  "showFleet": false
}

Mark extract and analyze in progress
Completed with input: {
  "description": "Mark extract and analyze in progress",
  "query": "UPDATE todos SET status = 'done' WHERE id = 'extract-blocks';\nUPDATE todos SET status = 'in_progress' WHERE id = 'analyze-differences';"
}

Mark analyze done and writing in progress
Completed with input: {
  "description": "Mark analyze done and writing in progress",
  "query": "UPDATE todos SET status = 'done' WHERE id = 'analyze-differences';\nUPDATE todos SET status = 'in_progress' WHERE id = 'write-comparison-doc';"
}

Created [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/SP_SK_ETL03_comparison.md)

Read [](file:///c%3A/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/SP_SK_ETL03_comparison.md)

Mark comparison todos done
Completed with input: {
  "description": "Mark comparison todos done",
  "query": "UPDATE todos SET status = 'done' WHERE id = 'write-comparison-doc';\nUPDATE todos SET status = 'done' WHERE id = 'verify-doc';"
}

Created [`SP_SK_ETL03_comparison.md`](c:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/SP_SK_ETL03_comparison.md) in the Shipping directory.

Key findings captured:
- The canonical `SP_SK_ETL03_CUST_SHIP` implementation is in [`sp_Shipments_Core_Feed_03.sql`](c:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/sp_Shipments_Core_Feed_03.sql), not in [`zza_SP_SK_ETL03_CUST_SHIP.sql`](c:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL03_CUST_SHIP.sql) (which is misnamed and actually contains ETL02).
- The misplaced block in [`zza_SP_SK_ETL01_CUST_SHIP.sql`](c:/Users/williamt/source/skillsinc/skills-inc-org/SQL-Projects/Documentation/Schema/Data_Models/Customer_Order/Shipping/zza_SP_SK_ETL01_CUST_SHIP.sql) lines ~586–698 is commented out and targets the legacy `PBI_Customer_Shipments_complement_OT` table, while the canonical ETL03 targets `Feed_01_Core_Intermediate_complement_OT`.
- The document lists the major differences: target table, active vs. commented-out `LIVEARC` branches, `BASE_TABLE` filters, delete style, and activation state.

No SQL files were modified.