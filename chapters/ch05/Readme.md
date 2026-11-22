# Chapter 5: Build a Knowledge Graph from Structured Sources

## Reading objective

Learn how to transform structured and unstructured domain data into a knowledge
graph that supports questions about entities, relationships, and patterns.

The chapter's working example uses Rockefeller Foundation program officers'
diaries. Their notes contain valuable historical information, but the language
is abbreviated, domain-specific, and difficult for generic NLP models to
interpret.

## Reading preparation

Before beginning:

- Review [plan5.01.md](./plan5.01.md) for the current section outline and
  accumulated notes.
- Keep these entity types in mind:
  - Person
  - Organization
  - Location
  - Topic
- Distinguish the three `Topic` subtypes:
  - Research discipline
  - Technology
  - Disease

As the chapter progresses, add:

- Important concepts and definitions
- Domain-specific entities and relationships
- Extraction and normalization steps
- Graph schema decisions
- Questions the resulting graph should answer
- Code examples and validation exercises

## Questions to keep in mind

- What patterns tend to precede the funding of an idea?
- Do funded projects follow recommendations from influential scientists or
  previous grantees?
- How many internal discussions occur before a grant is awarded?
- How does funding of research subdisciplines change over time?
- Which relationships in the source text must be preserved in the graph?
- What information cannot be captured accurately by generic named-entity
  categories?

## Repository study workflow

1. Read the next section or excerpt.
2. Summarize its main idea and terminology.
3. Add section-specific working notes to [plan5.01.md](./plan5.01.md).
4. Connect the concept to the importer, reconciliation, or graph-modeling code
   in this chapter when applicable.
5. Run the relevant example or validation command and record the result.

## Practical focus

The code in this directory demonstrates how to:

- Install the chapter dependencies.
- Download disease and microRNA datasets.
- Import structured data into Neo4j.
- Reconcile diseases across datasets.

This practical material complements the chapter's broader lesson: a useful
knowledge graph requires both the extracted facts and domain-aware modeling of
their meaning.

## Exercises

- [ ] Identify the entities and relations present in a sample diary entry.
- [ ] Extend a generic entity schema with the three `Topic` subtypes.
- [ ] Compare generic entity extraction with domain-specific extraction.
- [ ] Decide how ambiguous or abbreviated mentions should be represented.
- [ ] Run the chapter's import pipeline.
- [ ] Verify that reconciled entities link to the intended source records.

## Build the Chapter Example

### Getting Started

Run every command in this section from the Chapter 5 directory:

```bash
cd chapters/ch05
```

#### Prerequisites

- Python 3.9
- GNU Make
- A running Neo4j instance
- A Neo4j database named `hmdd2.0`
- Network access for downloading the source datasets and Python model

The importers in this chapter target the `hmdd2.0` database. Create that
database in Neo4j before running the import. If local Neo4j uses another name or
connection, update the root `config.ini` or provide `NEO4J_URI`, `NEO4J_USER`,
and `NEO4J_PASSWORD`.

The chapter's `Makefile` assumes that the repository has a Python 3.9 virtual
environment at `venv/`. Create it from the repository root if needed:

```bash
python3.9 -m venv venv
```

If the environment is stored elsewhere, update `PIP` and `PYTHON` at the top of
this directory's `Makefile`.

#### Verify Neo4j configuration

Before importing data, confirm that:

1. Neo4j is running.
2. The credentials in `config.ini` are valid for the local instance.
3. The `hmdd2.0` database exists and is online.

Do not put production credentials into committed configuration files. Prefer
environment variables for local overrides.

#### Install Requirements

```shell
make init
```

This installs the pinned packages and the scispaCy language model listed in
`requirements.lock`.

#### Download the Datasets

```shell
make download
```

The command creates the repository-level `dataset/hmdd/` directory and
downloads:

- HMDD
- dbDEMC
- miR2Disease
- miRBase
- miRDB
- miSim

Downloads can fail when an upstream host is unavailable. The command is
finished successfully only when the expected files exist in `dataset/hmdd/`.

#### Import the Datasets

Once the database and downloaded files are ready, run:

```shell
make import
```

This runs all chapter importers in sequence and writes nodes and relationships
to `hmdd2.0`. Re-running the import is intended to be incremental because the
import queries use `MERGE`.

In Neo4j Browser, use the following checks after import:

```cypher
:use hmdd2.0
MATCH (m:MiRNA) RETURN count(m) AS miRNACount;
MATCH (d:Disease) RETURN count(d) AS diseaseCount;
MATCH (:MiRNA)-[r:RELATED_TO|REGULATES]->() RETURN count(r) AS relationshipCount;
```

To inspect the distribution of ingested miRNAs by source, run Listing 5.6:

```cypher
MATCH (n:MiRNA)
WITH
 DISTINCT LABELS(n) AS labels,
 COUNT(*) AS count
RETURN
 [l IN labels WHERE "MiRNA" <> l] AS labels,
 count
ORDER BY count DESC;
```

The five current source labels are assigned directly by the importer code:

| Importer | Source label |
| --- | --- |
| `import_miRNA_hmdd.py` | `MiRNA_HMDD` |
| `import_miRNA_dbDEMC.py` | `MiRNA_dbDEMC` |
| `import_miRNA_miR2Disease.py` | `MiRNA_miR2Disease` |
| `import_miRNA_EMBL.py` | `MiRNA_miRBase` |
| `import_miRNA_RDB.py` | `MiRNA_RDB` |

Because one miRNA can occur in several datasets, a row may contain multiple
labels and the counts describe label combinations, not mutually exclusive
dataset membership. miRBase feature nodes created by `import_miRNA_EMBL.py`
also have the base `MiRNA` label without one of these five source labels, so an
empty `labels` list is currently possible.

#### Reconcile Diseases

Run disease reconciliation after the import succeeds:

```shell
make reconciliate
```

The reconciliation step uses scispaCy to normalize disease names and create
`NormalizedDisease` nodes connected by `REPRESENTS` relationships.

Verify reconciliation in Neo4j Browser:

```cypher
:use hmdd2.0
MATCH (d:Disease)-[:REPRESENTS]->(n:NormalizedDisease)
RETURN count(d) AS diseasesRepresented, count(DISTINCT n) AS normalizedDiseases;
```

Run the workflow in order:

```bash
make init
make download
make import
make reconciliate
```

Do not continue to reconciliation if `make import` reports a missing file,
database, authentication, or connectivity error.

### Notes for macOS Users

If scispaCy dependencies do not install in the local environment, run the
chapter from a Python 3.9 container.

#### Create a Suitable Container

From the repository root, create an ephemeral container named `venv_ch5`:

```bash
docker run -d -it \
  --name venv_ch5 \
  -e NEO4J_URI=bolt://host.docker.internal:7687 \
  -e PYTHONPATH=../../ \
  -w /work/chapters/ch05 \
  -v "$PWD":/work \
  python:3.9-slim
```

The command assumes Neo4j runs on the host. Pass `NEO4J_USER` and
`NEO4J_PASSWORD` as additional environment variables instead of editing the
container or committing credentials.

#### Update the Makefile

In `chapters/ch05/Makefile`, change the first two lines to:

```makefile
PIP=docker exec -it venv_ch5 pip
PYTHON=docker exec -it venv_ch5 python
```

#### Run the Make Commands

Run the chapter workflow from the host:

```bash
make init
make download
make import
make reconciliate
```

To remove the temporary container after completing the chapter:

```bash
docker rm -f venv_ch5
```

### Troubleshooting

- **Python package installation fails:** Confirm that `venv` uses Python 3.9 and
  install the pinned packages rather than substituting a newer scispaCy stack.
- **Neo4j connectivity fails:** Verify `NEO4J_URI` and that port 7687 is
  reachable.
- **Authentication fails:** Confirm the configured username and password using
  the environment-variable overrides.
- **The `hmdd2.0` database is missing:** Create and start it in Neo4j, then rerun
  `make import`.
- **A dataset is missing:** Re-run `make download` and confirm the expected file
  is present under `dataset/hmdd/`.