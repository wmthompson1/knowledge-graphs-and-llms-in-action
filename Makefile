.PHONY: validate-shacl

validate-shacl:
	@python3 -m venv .venv-shacl >/dev/null 2>&1 || true
	@. .venv-shacl/bin/activate && python -m pip install --quiet rdflib pyshacl
	@. .venv-shacl/bin/activate && python -c 'exec("from pathlib import Path\nfrom pyshacl import validate\nfrom rdflib import Graph\nbase = Path(\"ontology/mfg\")\nontology = base / \"mfg-unified.ttl\"\nshapes = base / \"mfg-unified-shapes.ttl\"\nvalid_data = Path(\"tests/shacl/por-valid.ttl\")\ninvalid_data = Path(\"tests/shacl/por-invalid.ttl\")\nfor target in [valid_data, invalid_data]:\n    data_graph = Graph().parse(str(target), format=\"turtle\")\n    conforms, _, results_text = validate(data_graph, shacl_graph=Graph().parse(str(shapes), format=\"turtle\"), ont_graph=Graph().parse(str(ontology), format=\"turtle\"), inference=\"rdfs\", abort_on_error=False)\n    print(f\"== {target.name}: conforms={conforms} ==\")\n    print(results_text)\n")'
