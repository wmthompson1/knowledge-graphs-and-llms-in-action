# Minimal candidate OWL vocabulary

The [Turtle draft](./mrp-minimal-candidate.owl.ttl) is a small, **unapproved
working ontology**, not a claim of conformance to a particular W3C OWL 2
profile. Its namespace, `https://example.org/mrp#`, is a placeholder, not a
published or externally aligned vocabulary. It contains exactly **20 classes,
20 object properties and 10 datatype properties**, including acquisition-layer
classes. It contains no production instances.

Its purpose is to test the shape of the highest-priority product, BOM,
routing, planning, supplier and provenance questions before expanding toward
the 45-class [design notebook](./mrp-owl-design-notebook.md). It is not a
complete MRP ontology, MRP engine, validation schema, or production-ready
knowledge graph.

## Commitments and deferrals

Two provisional subclass axioms are expressed: `Product ⊑ Item` and
`Supplier ⊑ RoleAssignment`. Both are design choices for review, not
source-verified universal truths. `Supplier` denotes a role assignment, not
the agent holding it; `heldBy` points to that agent. No individual agents are
asserted and no agent class is required by this draft.

There are **no** declared class disjointness, equivalence, keys, property
characteristics, domain/range axioms, cardinality restrictions, external
imports or instance data. In particular, different part types may overlap,
and absence of a fact is not proof of its negation. Datatype choices,
required values, units, identifier scope and temporal consistency still need
SME review and separate SHACL/data validation.

`Operation` represents a step definition in this draft, not proof of an
execution. `PlannedOrder` is a recommendation, not a released purchase.
`BOMLine` is the proposed context for component usage and quantity; direct
paths alone do not compute multilevel requirements. The name
`fulfillsRequirement` is provisional and must not be interpreted as proof
that a requirement has actually been fulfilled.

## Proposed interpretation and evidence

These are intended uses for review, **not asserted global domains/ranges**.
Evidence IDs refer to the [acquisition notebook](./mrp-ontology-notebook.md#layer-1--source-evidence-only)
and [source-context records](./mrp-source-evidence.json).

| Included elements | Intended use and evidence | Primary questions |
| --- | --- | --- |
| `Item`, `Product`, `BillOfMaterials`, `BOMLine`, `Unit`; `hasBOM`, `hasBOMLine`, `parentItem`, `componentItem`, `unitOfMeasure`, `quantityPerParent`, `sku` | Versioned product structure and per-parent usage; E01, E08, E16. Versioning and units still need agreed conventions. | CQ01, CQ02, CQ16 |
| `Routing`, `Operation`, `WorkCenter`, `ProductionOrder`; `hasRouting`, `hasOperation`, `performedAt`, `hasNextOperation`, `setupTime`, `runTime` | Defined steps and their proposed assignments; E03–E06. Execution events and contextual ordering remain outside the draft. | CQ03, CQ11 |
| `MaterialRequirementsPlanning`, `MasterProductionSchedule`, `InventoryPosition`, `NetRequirement`, `PlannedOrder`; `usesSchedule`, `usesBOM`, `usesInventory`, `fulfillsRequirement`, `orderQuantity`, `onHandQuantity` | Planning inputs and recommendation structure; E13, E15, E17, E19. No netting, conversion, dates or execution logic is supplied. | CQ05–CQ07 |
| `Supplier`, `RoleAssignment`; `heldBy`, `suppliesMaterial` | Proposed contextual supplier role and potential material relation; E09, E30. Context, review, temporal scope and actual transactions remain to be modeled. | CQ04, CQ17 |
| `SourceDocument`, `SourcePassage`, `Mention`, `RelationshipAssertion`; `hasPassage`, `supportedBy`, `subjectMention`, `objectMention`, `refersTo`, `sourceText`, `sourceLocator`, `mentionText`, `assertionStatus` | Source, occurrence, assertion and proposed referent remain separate; E34 and the acquisition design. This schema does not automatically resolve mentions. | CQ22 |

For readable representations, `sourceText`, `sourceLocator`, `mentionText`,
`assertionStatus` and `sku` are expected to use strings; quantities and times
are candidates for decimals with explicit units. These are design suggestions,
not OWL datatype range axioms in the draft.

## Known gaps

- CQ08–CQ10 need review events, dated status, pegging, demand and additional
  supply data; a planned order alone cannot answer them.
- CQ11 has only a simple direct-next relation; branches, repeated steps and
  routing-specific ordering are not modeled.
- CQ12–CQ15 and CQ19–CQ21 need capacity, metrics, policies, part
  classifications, planning assumptions, WIP and validation records.
- `sourceLocator` does not provide missing page numbers or guarantee citation
  completeness. Neither it nor `supportedBy` establishes claim truth.
- Property names and labels do not enforce types or completeness. The draft
  includes no persisted query fixtures, SHACL shapes, MRP calculations or
  reasoner results. The [question catalog](./mrp-competency-question-catalog.md)
  identifies intended coverage rather than claiming executable answers.

The Turtle was parsed with RDFLib, and transient synthetic BOM and
mention-to-evidence queries returned the expected results. Those checks do not
validate OWL consistency or establish competency-question coverage.

Before using this schema, review its subclass choices and role model with
domain experts, agree stable IRIs and source mappings, add test fixtures and
SHACL constraints, and check OWL consistency with a reasoner.
