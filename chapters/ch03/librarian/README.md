# Librarian and knowledge loop (Chapter 3)

Ported from `product-ontime-analysis` (`scripts/` and `docs/my-mrp-kb`). Defaults now resolve inside this chapter:
documents in `librarian/my-mrp-kb`, artifacts in `librarian/mrp_ingest_artifacts`, staging in `librarian/mrp_research_staging`
(override with `MRP_DOCUMENTS_DIR`, `MRP_INGEST_ARTIFACT_ROOT`, `MRP_RESEARCH_STAGING_ROOT`).

## The loop (run from `chapters/ch03`)

| Step | Command | Writes |
|------|---------|--------|
| 1 Ingest KB documents (PII scan, hashing, trace) | `make loop-ingest` | `mrp_ingest_artifacts/<run>/` |
| 2 Build anchors (perspectives from KB topics, categories from the mfg ontology and ERP topology) | `make loop-anchors` | `anchors.db` |
| 3 Stage candidate terms as proposals (dry run) | `make loop-stage` | `mrp_research_staging/<run>/proposed_terms.{json,csv}` |
| 4 Human review: set `reviewer_decision` to `approved` or `rejected` in the CSV | edit the CSV | |
| 5 Approve (dry run; `COMMIT=1` for live) | `make loop-approve` | `mrp_research` ArangoDB graph, only with `MRP_ENABLE_GRAPH_COMMIT=true` |

`make knowledge-loop` runs steps 1 to 3. Re-stage with `make loop-stage PREV=<old proposed_terms.csv>` to carry decisions forward.
`make librarian-serve` starts the MCP librarian server (needs `mcp<2`, `python-docx`, `python-dotenv`, `sqlglot`).

## Governance

Nothing is approved automatically, the certified graph is unreachable from the commit path, and live writes need both `--commit` and `MRP_ENABLE_GRAPH_COMMIT=true`.
The anchors here are derived from this repo, not SME-certified. `scripts/mrp_term_promoter.py` targets the original project's certified SQLite database and exporter and is not wired in here.
