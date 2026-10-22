# Manufacturing Domain Module (Upper Ontologies)

This folder contains the three upper-ontology modules used for the
Manufacturing, Quality, and Finance domains. These ontologies are designed
to align with the synthetic ERP used in the KG+LLM project and will
eventually become governed canonical assets.

## Contents

- `mfg.ttl` — Manufacturing domain ontology  
- `quality.ttl` — Quality domain ontology  
- `finance.ttl` — Finance domain ontology  
- `catalog-v001.xml` — Local OWL catalog for import resolution  
- `load-order.txt` — Recommended load sequence for OWL tools  

## Load Instructions

OWL tools such as Protégé, OWLAPI, ROBOT, and Ontop must load the
`catalog-v001.xml` file to resolve imports. Without the catalog, the PURL
IRIs will return 404.

**Valid load unit:**  
Load `mfg.ttl` as the entry point. It imports both `quality.ttl` and
`finance.ttl`.

Loading `quality.ttl` or `finance.ttl` alone is not supported at this
stage.

## Modeling Decisions

- **No `rdfs:domain`** is used in any module. All domain constraints are
  expressed via OWL DL class-local restrictions.
- **Duplicate properties** (`hasQualityEvent`, `eventTimestamp`) were
  removed from `mfg.ttl`. Quality owns these terms.
- **Inspection** currently models production inspection. Receiving
  inspection may be added later.
- **PlannedOrderReceipt** currently models manufacturing supply only.
  Purchased supply may be added later.
- **CostBucket** may be renamed to `CostElement` in a future revision to
  avoid collision with inventory bucket terminology.

## Status

These ontologies parse cleanly and load together without errors. They are
structurally close to usable but not yet ready for canonical governance
until the Phase 1–3 catalogs and alignment work are complete.

