
## Schema-only ontology layer (generated from `ddl/`)

`generator/generate_erp_ontology_from_ddl.py` reads every `CREATE TABLE`, primary key and foreign key in `ddl/*.sql` and writes, with no data involved:

- `schema/erp-schema.ttl`: one `owl:Class` per table (`erp:WorkOrder`), one datatype property per column (`erp:workOrder_baseId`), one object property per foreign key (`erp:workOrder_part`).
- `schema/erp-obda.obda`: Ontop mappings, one per table with a primary key; IRIs are built from the primary key and foreign keys become object-property triples.
- `schema/erp-topology.json`: `nodes` (tables) and `edges` (foreign keys) for the mosaic renderer.

Run from the repo root: `make -C chapters/ch03 erp-generate-ontology` then `make -C chapters/ch03 erp-inspect`.

Known limits: tables without a primary key get classes and properties but no OBDA mapping; foreign keys that do not reference the target's primary key get no object mapping (both are listed in the generator output).

### Validating the mappings

`make -C chapters/ch03 erp-validate-obda` builds an empty H2 database from the DDL and runs `ontop validate` on `erp-schema.ttl` + `erp-obda.obda` (about 2 minutes). It needs a JRE and the Ontop CLI with `jdbc/h2.jar` (`ONTOP_HOME`, default `~/tools/ontop`). Reserved T-SQL words used as column names are double-quoted in the mapping source queries.

## Knowledge Loop Integration

`chapters/ch03/librarian/librarian.py` reads this schema-only ERP ontology plus `ontology/mfg/*.ttl` (no ERP rows) and writes per-class semantic slices to `kb/`. `knowledge_loop.py` packs them for the agent.

    make -C chapters/ch03 kb-pack          # build kb/ and agent/kb_pack.json
    make -C chapters/ch03 librarian-inspect

See `chapters/ch03/agent/few_shot_examples.md` for usage patterns.

## POC mappings and SQL coverage

- `make -C chapters/ch03 poc-mapping-check` runs `ontop-ontology-poc/generate_mapping.py --all --check`, verifying every `mapping/*_manifest.json` against `replit_integrations/graph_metadata.json`. A manifest may set `"sql_dialect"` (default `sqlite`) for sqlglot's column validation.
- `make -C chapters/ch03 sql-coverage` classifies every table the `Data_Models` query SQL references as table / view / cte / temp / system / unknown against `erp-topology.json`. The `unknown` list is the real gap set (mostly views and non-ERP tables that are not defined by `CREATE VIEW` in the corpus).
- `make -C chapters/ch03 erp-unknown-list` writes the unknown relations to `schema/unknown-views.csv`; set `include` to `no` for rows to drop. `make -C chapters/ch03 erp-generate-views` then writes `schema/erp-views.ttl` (classes plus referenced columns, tagged `erp:inferredFromQuery`; no datatypes, no data). The librarian and `make slice` include it when present.
