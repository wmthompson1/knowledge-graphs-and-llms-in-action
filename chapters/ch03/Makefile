PIP=../../venv/bin/pip
PYTHON=../../venv/bin/python
# Host folder mounted as /ontology in the Neo4j container
ONTOLOGY_DIR?=/mnt/c/Users/Clovi/source/create-context-graph/ontology

init:
	$(PIP) install -r requirements.lock

generate-instances:
	$(PYTHON) generator/generate_manufacturing_instances.py

import:
	PYTHONPATH=../../ $(PYTHON) importer/import_hpo.py

load-manufacturing: generate-instances
	cp ../../ontology/mfg/manufacturing-instances.ttl $(ONTOLOGY_DIR)/mfg/
	$(PYTHON) importer/load_manufacturing.py

erp-generate-ontology:
	$(PYTHON) ../../ontology/erp/generator/generate_erp_ontology_from_ddl.py

erp-validate-obda:
	cd ../../ontology/erp/generator && ../../../venv/bin/python validate_obda.py

erp-inspect:
	@echo "ERP ontology files:"
	@ls -la ../../ontology/erp/schema

# Knowledge loop: ingest -> anchors -> stage proposals -> (human review of proposed_terms.csv) -> approve
loop-ingest:
	$(PYTHON) scripts/my_mrp_ingestion_runner.py

loop-anchors:
	$(PYTHON) scripts/build_anchor_db.py

loop-stage: loop-anchors
	$(PYTHON) scripts/mrp_terminology_stager.py $(if $(PREV),--preserve-decisions $(PREV))

# Dry run unless COMMIT=1 (which also needs MRP_ENABLE_GRAPH_COMMIT=true and a reachable ArangoDB)
loop-approve:
	$(PYTHON) scripts/mrp_approval_committer.py $(if $(COMMIT),--commit)

knowledge-loop: loop-ingest loop-stage
	@echo "Review librarian/mrp_research_staging/<run>/proposed_terms.csv (set reviewer_decision), then: make loop-approve"

librarian-serve:
	$(PYTHON) librarian/librarian_server.py

ask:
	$(PYTHON) retrieval/ask_graph.py "$(Q)"

inspect:
	@echo "Run the Cypher in ontology-inspection.cypher in Neo4j Browser or Cypher Shell."
	@echo "Example: MATCH (n) RETURN count(n) AS totalNodes;"
.PHONY: loop-test
loop-test:
	$(PYTHON) -m pytest tests/test_mrp_approval_committer.py tests/test_mrp_terminology_stager_preserve.py tests/test_mrp_term_promoter.py -q

KB_DIR?=../../kb
.PHONY: librarian-build-kb librarian-inspect kb-pack
librarian-build-kb:
	$(PYTHON) librarian/librarian.py --ontology ../../ontology --out $(KB_DIR)
librarian-inspect:
	@ls -la $(KB_DIR)
kb-pack: librarian-build-kb
	$(PYTHON) librarian/knowledge_loop.py --kb $(KB_DIR) --agent agent

.PHONY: slice
slice:  # make slice CLASSES="WorkOrder Part"
	$(PYTHON) librarian/slice.py $(CLASSES) --ontology ../../ontology --out $(KB_DIR)

.PHONY: poc-mapping-check sql-coverage
poc-mapping-check:
	cd ../../ontology/erp/ontop-ontology-poc && ../../../venv/bin/python generate_mapping.py --all --check
sql-coverage:
	$(PYTHON) scripts/check_sql_coverage.py

.PHONY: erp-unknown-list erp-generate-views
erp-unknown-list:  # writes ontology/erp/schema/unknown-views.csv (edit include=yes/no)
	$(PYTHON) scripts/check_sql_coverage.py --csv ../../ontology/erp/schema/unknown-views.csv
erp-generate-views:
	$(PYTHON) ../../ontology/erp/generator/generate_erp_views.py
