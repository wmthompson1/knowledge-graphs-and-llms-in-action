PIP=../../venv/bin/pip
PYTHON=../../venv/bin/python

init:
	$(PIP) install -r requirements.lock
	$(PIP) install https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.6.0/en_core_web_sm-3.6.0-py3-none-any.whl

import:
	PYTHONPATH=../../ $(PYTHON) importer/step1__import_bbc.py
	PYTHONPATH=../../ $(PYTHON) importer/step2__enrich_organizations.py
	PYTHONPATH=../../ $(PYTHON) importer/step3__enrich_by_ownerships.py



