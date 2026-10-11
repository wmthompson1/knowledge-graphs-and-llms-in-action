I’ll inspect the current step-2 block around the specified lines and compare its column shape with the new NCM mapping added in step 1. The key check is whether the union belongs in `DATASETGROUPBYNCM`, `DATASETWOX`, or both; I’ll preserve the existing legacy/archive branches and add only the missing target-NCM branch at the owning CTE boundary.

Read , lines 210 to 386

Searched for regex `DATASETGROUPBYNCM|DATASETWOX|INTO #DATASETNCM|NCM\.dbo\.NONCONFORMANCE|NONCONFORMANCE NCM` (`**/Documentation/Schema/Data_Models/Quality/Report - ETL - usp_Extract_Cost_Of_Quality3_step2.sql`), 7 results

Read , lines 120 to 219

The current file has two concrete issues in this slice: `DATASETWOX` has no Quality Database #2 branch, and the downstream `#REQUIRESET` load still references the undefined `DATASETWO` CTE. I’ll add the new NCM branch to `DATASETWOX`, add a matching branch to `DATASETNCM` so `#DATASETNCM` carries the new records, and correct that local CTE reference without altering the legacy/archive logic.

Generating patch (45 lines) in 


```

```
The `DATASETWOX` union and undefined-CTE correction are in place. I’m adding the second, parallel projection inside `DATASETNCM`; this is the branch that feeds `#DATASETNCM` and therefore the final cost-of-quality result.

Read , lines 300 to 345

Generating patch (51 lines) in 


```

```
Both consuming paths now include the new NCM source: `DATASETWOX` supplies the rework-set rows, and `DATASETNCM` supplies the detailed NCM rows consumed by `#DATASETNCM`. I’m validating column alignment and the critical downstream references now, especially the typed `NULL` placeholders and the `OPERATION_REC_ID` limitation.

Ran terminal command: $path = 'Documentation\Schema\Data_Models\Quality\Report - ETL - usp_Extract_Cost_Of_Quality3_step2.sql'; $text = Get-Content -Raw $path; $required = @('[SQL-Lab-2].[NCM].[dbo].[NONCONFORMANCE]','NCM.AS_IS_DIMENSION','NCM.SHOULD_BE_DIMENSION','NCM.DISPOSITION_NOTES','NCM.DISPOSITION_TYPE_CODE','NCM.PROCESS_ID','NCM.SUBPROCESS_ID','NCM.DEFECT_ID','NCM.PART_ID','NCM.VENDOR_PO_NUMBER','CAST(NULL AS bigint) OPERATION_REC_ID'); $missing = @($required | Where-Object { -not $text.Contains($_) }); [pscustomobject]@{NewNcmSourceCount=([regex]::Matches($text,'\[SQL-Lab-2\]\.?\[NCM\]\.?\[dbo\]\.\[NONCONFORMANCE\]').Count); UnionAllCount=([regex]::Matches($text,'(?im)^\s*UNION ALL\s*$')).Count; MissingRequired=($missing -join ', '); UsesDefinedDataSetWox=($text.Contains('FROM DATASETWOX')); LoadsDatasetNcm=($text.Contains('INTO #DATASETNCM')); HasAsIsComment=$text.Contains('AS_IS_DIMENSION -- AS [ASIS_DIM]'); HasShouldBeComment=$text.Contains('SHOULD_BE_DIMENSION -- AS [SHOULD_BE_DIM]')} | Format-List

Ran terminal command: git diff --check -- 'Documentation/Schema/Data_Models/Quality/Report - ETL - usp_Extract_Cost_Of_Quality3_step2.sql'; git status --short -- 'Documentation/Schema/Data_Models/Quality/Report - ETL - usp_Extract_Cost_Of_Quality3_step2.sql'

Checked , no problems found

Added the Quality Database #2 union logic to `Report - ETL - usp_Extract_Cost_Of_Quality3_step2.sql`.

Changes include:

- Added the NCM branch to `DATASETWOX`.
- Corrected the downstream reference from undefined `DATASETWO` to `DATASETWOX`.
- Added the NCM branch to `DATASETNCM`, which feeds `#DATASETNCM`.
- Source used:
  ```sql
  [SQL-Lab-2].[NCM].[dbo].[NONCONFORMANCE]
  ```
- Joined new NCM records to live work orders using:
  - `BASE_ID`
  - `LOT_ID`
  - `SPLIT_ID`
  - `SUB_ID`

Applied SME mappings include:

- `NCM_NUMBER` → legacy `NCM_ID`
- `NCM_TYPE_CODE` → `NCM_TYPE`
- `DISPOSITION_TYPE_CODE` → `DISPOSITION_TYPE`
- `DISPOSITION_NOTES` → `DISPOSITION`
- `DISPOSITION_DATE` → `DISP_DATE`
- `VENDOR_PO_NUMBER` → `PO_NUMBER`
- `AS_IS_DIMENSION` → `REFERENCE_3`, `[ASIS_DIM]`
- `SHOULD_BE_DIMENSION` → `REFERENCE_4`, `[SHOULD_BE_DIM]`
- `REWORK_QTY`, `SCRAP_QTY`, `OVERAGE_QTY`, `RETURN_QTY`
- `PROCESS_ID`, `SUBPROCESS_ID`, and `DEFECT_ID` split into FIN/MFG-compatible fields using `TAG_AREA`
- `PART_ID` → `PRODUCT_ID`

Legacy-only fields are represented with typed `NULL` values.

Validation passed with no editor diagnostics and no whitespace errors. The query was not executed against the databases. `OPERATION_REC_ID` is emitted as `NULL` for new NCM rows because the target schema’s `OPERATION_ID` is a natural operation identifier, not the legacy warehouse `VQ_OPERATION.RECORD_ID`; this avoids creating an invalid record-ID join.

Made changes.