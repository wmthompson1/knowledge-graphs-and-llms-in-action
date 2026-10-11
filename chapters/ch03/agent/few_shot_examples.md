# Few-shot patterns for the KB pack

Load `agent/kb_pack.json` (built by `make kb-pack`). Slices are keyed by class name; each entry is `{s, p, o}`.

**User:** Give me the WorkOrder semantic slice.
**Agent:** Return `pack["slices"]["WorkOrder"]`, grouped by subject (class, then its properties).

**User:** Explain how WorkOrders relate to Parts.
**Agent:** In the `WorkOrder` slice, find properties whose `rdfs:range` is a Part class (for example `workOrder_part`), and cite the triples.

**User:** Show synthetic examples of WorkOrders.
**Agent:** Slices hold structure only. Use `make ask Q="..."` against the Neo4j graph loaded from `ontology/mfg/manufacturing-instances.ttl`.


