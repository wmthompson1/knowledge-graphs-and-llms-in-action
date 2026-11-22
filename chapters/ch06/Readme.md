## Knowledge graphs and natural language processing

This example imports the bundled BBC news corpus into Neo4j, extracts named
entities and keywords with spaCy and TextRank, and enriches frequently
mentioned organizations with Wikidata. It is separate from the Rockefeller
diary and Chapter 5 biomedical examples.

For listing results, source evidence, and candidate ontology concepts, see the
[ontology notebook](./ontology-notebook.md).

### Getting started

Run commands from this directory:

```bash
cd chapters/ch06
```

#### Prerequisites

- Python 3.10, GNU Make, Docker, and network access to install dependencies.
- A separate Neo4j 4.4 database named `neo4j`. The importers write to this
  database regardless of `NEO4J_DATABASE`; do not point them at a database
  containing unrelated data.
- Enough memory for Neo4j and the NLP pipeline. On a shared machine, check
  available memory and stop the import if it causes severe memory pressure.

#### Install requirements

The existing repository-level `venv` may be shared or tracked. Use a separate
environment instead:

```bash
python3.10 -m venv ../../.venv-ch06
make init PIP=../../.venv-ch06/bin/pip PYTHON=../../.venv-ch06/bin/python
```

The environment is covered by `.gitignore`. The chapter pins spaCy and uses
the matching English model; NumPy is restricted to versions below 2 for
compatibility with the pinned NLP stack.

#### Start an isolated database

For a new instance, choose an unused port, container name, and volume. For
example, using port `17688`:

```bash
read -rs -p "New Neo4j password: " NEO4J_PASSWORD; echo
export NEO4J_PASSWORD NEO4J_USER=neo4j NEO4J_URI=bolt://127.0.0.1:17688
export NEO4J_AUTH="neo4j/$NEO4J_PASSWORD"
docker run -d --name chapter6-news -p 127.0.0.1:17688:7687 \
  -v chapter6-news-data:/data -e NEO4J_AUTH \
  -e NEO4J_dbms_memory_heap_initial__size=256m \
  -e NEO4J_dbms_memory_heap_max__size=768m \
  -e NEO4J_dbms_memory_pagecache_size=256m neo4j:4.4
unset NEO4J_AUTH
```

Wait for Neo4j to start before importing. The named volume retains the data
when the container stops. If this container or volume already exists, inspect
it first rather than replacing it; Neo4j initializes the password only for a
new database. Keep credentials outside the repository.

#### Prepare Wikidata caches

The bundled `data/cache_org` and `data/cache_owners` files are tracked. Copy
them to a writable private cache to avoid modifying the originals:

```bash
export CH6_CACHE_ROOT="$(cd ../.. && pwd)/.venv-ch06/wikidata-cache"
if [ ! -e "$CH6_CACHE_ROOT" ]; then
  mkdir -p "$CH6_CACHE_ROOT"
  cp -R ../../data/cache_org ../../data/cache_owners "$CH6_CACHE_ROOT/"
fi
```

Cached results, including empty results, are reused. A cache miss sends the
organization name or Wikidata ID to the public Wikidata query service.
Requests are throttled and transient errors retried; a failed lookup stops the
enrichment stage rather than being cached as an empty result. Each enrichment
stage reports cache hits, misses, empty results, and failed lookups. A result
can be empty or ambiguous, so enrichment is not guaranteed for every entity.
If `CH6_CACHE_ROOT` is unset, the scripts use the repository's original
`data/cache_org` and `data/cache_owners` directories.

#### Import the datasets

With the connection variables and cache set, run:

```bash
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  make import PYTHON=../../.venv-ch06/bin/python
```

The stages import BBC documents and entities, extract keywords, enrich
frequently mentioned organizations, and add ownership relationships. The
corpus contains 2,225 articles; one is decoded as Latin-1 after UTF-8 fails.
The workflow can take substantial time, particularly on cache misses.

The import uses `MERGE` and can be rerun after an interruption with the same
model and cache. It does not remove stale relationships left by older runs,
different models, or earlier versions of the enrichment code; use a fresh,
isolated database when a clean rebuild is required. Do not delete another
database or volume to do so.

#### Verify the graph

In a Neo4j client connected to the isolated instance, select database
`neo4j` and run:

```cypher
MATCH (d:Document) RETURN count(d) AS documents;
MATCH (t:Topic)-[:HAS_DOCUMENT]->(d:Document)
RETURN t.name AS topic, count(d) AS documents ORDER BY topic;
MATCH (d:Document)-[:MENTIONS_KEYWORD]->(k:Keyword)
RETURN count(DISTINCT d) AS documentsWithKeywords, count(k) AS keywordMentions;
MATCH (o:Organization) WHERE o.wikidata_id IS NOT NULL
RETURN count(o) AS enrichedOrganizations;
MATCH ()-[r:OWNED_BY_ORG|OWNED_BY_PER]->() RETURN type(r) AS type, count(r) AS count;
```

Compare the document count with the bundled corpus, and review sample
relationships and enrichment against source text and cached responses.
Automatic named-entity extraction and Wikidata label matching can be wrong;
ownership results also depend on available Wikidata instance-of statements.

#### Example run

An isolated run imported all 2,225 documents, each with keyword links.
It produced 65,626 keyword relationships, 243 enriched organizations,
88 organization-owner links, and 7 person-owner links. The organization
stage reported 419 cache hits and 7 misses; the ownership stage reported
242 hits and 1 miss. Both completed without failed lookups, but returned
183 and 189 empty results respectively. These counts depend on the corpus,
models and cache contents and are not guarantees for later runs.

#### Tests

From the repository root:

```bash
.venv-ch06/bin/python -m unittest discover -s tests -p test_ch06_import.py -v
```
