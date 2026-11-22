# MRP OWL design notebook

## Purpose and status

This design develops the 45 candidate classes in the
[MRP ontology notebook](./mrp-ontology-notebook.md) without loading a graph or
declaring an approved ontology. Evidence IDs `E01`–`E35` and competency
questions `CQ01`–`CQ16` refer to that notebook and its
[source-evidence records](./mrp-source-evidence.json). Source page numbers
remain unknown; evidence records provide source lines and surrounding context.
The documents describe a domain and proposed models, not the user's actual
production data.

All axioms below are **proposals for review**, not statements found verbatim
in the documents. No ontology, reasoner, SHACL validation, operational data or
identity resolution was run. `mrp:` denotes the unpublished placeholder
namespace `https://example.org/mrp#`; names are not externally aligned.

See the [domain glossary](./mrp-domain-glossary.md),
[competency-question catalog](./mrp-competency-question-catalog.md), and
[minimal candidate OWL vocabulary](./mrp-minimal-owl-profile.md) for the next
iteration of this design.

### Reading the class matrix

- **Superclass** and **proposed direct subclasses** together state proposed
  `SubClassOf` axioms; a dash means none is currently proposed, not that none
  can exist. `owl:Thing` means the more specific parent is undecided.
- **Form** distinguishes a class describing kinds of things, an individual
  occurrence, a role assignment, or a time-dependent state. The OWL entity in
  the first column remains a *class*; the form describes its prospective
  instances. An individual is not a class merely because it has a type.
- **Disjointness: none proposed for every row** unless explicitly stated.
  This is a conservative modeling decision, **not** an assertion that all
  classes overlap. Unlisted pairs are not declared disjoint.
- **Axiom / decision** records an additional proposal or an explicit deferral.
  Existence, uniqueness and closed-world requirements belong in reviewed data
  shapes until there is evidence that OWL restrictions are appropriate.
- The matrix preserves candidate names even where their modeling form is
  disputed. A future ontology may rename or split them after review; no
  equivalence is asserted merely because two labels sound similar.

### Working scaffolding

These are proposed modeling scaffolds, not asserted ISA-95 alignments:
`Process`, `PlanningProcess`, `InformationArtifact`, `Order`,
`OrderRecommendation`, `Policy`, `RoleAssignment`, `InventoryState`,
`Measure`, `Requirement`, `Resource`, `Organization`, `Agent`,
`Location`, `Unit` and `DemandSource`. Except where a parent is explicitly
listed below, their superclass is `owl:Thing`, they have no proposed
disjointness, and their precise boundaries remain open. `PlanningProcess`
is proposed under `Process`; `Order` and `OrderRecommendation` under
`InformationArtifact`. These scaffolds need domain review before
formalization; they are not proof that the source itself defined them.

## Class-by-class decisions

| Candidate class | Proposed superclass | Proposed direct subclasses | Form of individual / role / state | Axiom / decision for review | Evidence; related CQ |
| --- | --- | --- | --- | --- | --- |
| `Item` | `owl:Thing` | `RawMaterial`, `DetailPart`, `StandardPart`, `Product` | Class; a specific item or item definition, identity policy open | Proposed subclasses do not imply disjointness or that every item fits one. | E01, E16; CQ01–CQ02, CQ15 |
| `RawMaterial` | `Item` | — | Class or contextual use classification | `RawMaterial ⊑ Item`; test whether material status varies by process. | E01, E09; CQ01–CQ02 |
| `DetailPart` | `Item` | — | Class or contextual classification | `DetailPart ⊑ Item`; do not infer exclusive membership against `StandardPart`. | E32; CQ15 |
| `StandardPart` | `Item` | — | Class or contextual classification | `StandardPart ⊑ Item`; “off-the-shelf” need not define equivalence globally. | E33; CQ15 |
| `Product` | `Item` | — | Class; a product definition or variant, scope open | `Product ⊑ Item` is a proposed design choice, not identity with `Item`; SKU scope needs review. | E01, E06, E08; CQ02 |
| `ManufacturingProcess` | `Process` | — | Process occurrence or type; split if required | `ManufacturingProcess ⊑ Process`; don't infer a physical execution from a process definition. | E01; CQ18 |
| `ProductionPlanning` | `PlanningProcess` | — | Planning occurrence; method/plan separated | `ProductionPlanning ⊑ PlanningProcess`; inputs are not automatically outputs. | E02; CQ05, CQ10 |
| `CapacityPlanning` | `PlanningProcess` | `RoughCutCapacityPlanning`, `CapacityRequirementsPlanning` | Planning occurrence | `CapacityPlanning ⊑ PlanningProcess`; two proposed subtypes do not exhaust all capacity planning. | E07, E26–E27; CQ12 |
| `RoughCutCapacityPlanning` | `CapacityPlanning` | — | Pre-MRP check occurrence | `RoughCutCapacityPlanning ⊑ CapacityPlanning`; do not enforce sequence solely from a label. | E26; CQ12 |
| `CapacityRequirementsPlanning` | `CapacityPlanning` | — | Detailed planning occurrence | `CapacityRequirementsPlanning ⊑ CapacityPlanning`; no disjointness with rough-cut activities asserted. | E27; CQ12 |
| `ManufacturingResourcePlanning` | `PlanningProcess` | — | Candidate MRP II process/run; distinguish system from process | `ManufacturingResourcePlanning ⊑ PlanningProcess`; no equivalence or subclass relation with material MRP yet. | E14; CQ05, CQ19 |
| `MaterialRequirementsPlanning` | `PlanningProcess` | — | Calculation run; separately model method/software if needed | `MaterialRequirementsPlanning ⊑ PlanningProcess`; inputs can be recorded without asserting universal cardinalities. | E13; CQ05, CQ19 |
| `ManufacturingResource` | `Resource` | `WorkCenter` | Resource individual or grouping | `ManufacturingResource ⊑ Resource`; individual machine and labor kinds remain undecided. | E03; CQ03, CQ18 |
| `WorkCenter` | `ManufacturingResource` | — | Resource grouping individual, not a particular machine | `WorkCenter ⊑ ManufacturingResource`; `hasResource` links a group to members, not identity. | E03, E05; CQ03 |
| `Routing` | `InformationArtifact` | — | Versioned process-definition individual | `Routing ⊑ InformationArtifact`; define ordering on versioned steps, not on all operation executions. | E04; CQ03, CQ11 |
| `Operation` | `owl:Thing` | — | Proposed operation *definition* individual | Parent deferred: a step definition is not necessarily a process occurrence. Introduce `OperationExecution` if needed. | E04–E05; CQ03, CQ11 |
| `BillOfMaterials` | `InformationArtifact` | — | Versioned BOM definition individual | `BillOfMaterials ⊑ InformationArtifact`; no single-current-BOM axiom. | E13, E16; CQ01–CQ02, CQ16 |
| `BOMLine` | `InformationArtifact` | — | A particular component usage in a BOM version | `BOMLine ⊑ InformationArtifact`; attach quantity, unit, parent, component and effectivity to this usage. | E16; CQ01–CQ02, CQ16 |
| `ProductionOrder` | `Order` | — | Particular production authorization | `ProductionOrder ⊑ Order`; system-specific work-order labels require review. | E06; CQ07, CQ18 |
| `PurchaseOrder` | `Order` | — | Particular purchasing authorization | `PurchaseOrder ⊑ Order`; don't equate with a planned recommendation. | E17, E19; CQ04, CQ07 |
| `CustomerOrder` | `Order` | — | Particular customer demand order | `CustomerOrder ⊑ Order`; its relationship to demand must be modeled explicitly. | E25; CQ09–CQ10 |
| `PlannedOrder` | `OrderRecommendation` | `FirmPlannedOrder` | Particular planning recommendation | `PlannedOrder ⊑ OrderRecommendation`; a separate release or conversion event may link it to an actual order. | E19; CQ07–CQ08 |
| `FirmPlannedOrder` | `PlannedOrder` | — | A planned order with review/firming status | `FirmPlannedOrder ⊑ PlannedOrder`; consider a dated status/event instead of a permanent type if status can change. | E20; CQ08 |
| `MasterProductionSchedule` | `InformationArtifact` | — | A particular time-phased schedule/version | `MasterProductionSchedule ⊑ InformationArtifact`; its item quantities and periods require contextual schedule entries. | E13, E15; CQ05, CQ12 |
| `Forecast` | `InformationArtifact` | — | A forecast individual, not automatically a confirmed order | `Forecast ⊑ InformationArtifact`; demand source mapping is context-specific. | E02, E25; CQ09, CQ19 |
| `Demand` | `owl:Thing` | — | Dated demand observation or requirement; boundary open | No proposed superclass beyond `owl:Thing`; distinguish demand, forecast and order. | E07, E25; CQ09–CQ10 |
| `NetRequirement` | `Requirement` | — | Item/period requirement individual | `NetRequirement ⊑ Requirement`; calculation is not an OWL subclass axiom. | E17; CQ06, CQ10 |
| `ScheduledReceipt` | `owl:Thing` | — | Expected supply event/record; distinguish actual receipt | Parent and status model deferred; an open order is not automatically a physical receipt. | E17; CQ06, CQ10 |
| `InventoryPosition` | `owl:Thing` | — | Item-location-time position individual | Parent deferred; represent time and stock status before equating on-hand with available. | E11, E17; CQ06, CQ10 |
| `WorkInProcess` | `InventoryState` | — | Proposed state individual applied to an item/lot over an interval | `WorkInProcess ⊑ InventoryState`; do not assert WIP as a permanent subtype of `Item`. | E10; CQ20 |
| `Supplier` | `RoleAssignment` | — | Contextual role assignment held by an organization or other agent | `Supplier ⊑ RoleAssignment`; propose `heldBy` an `Agent`. A supplier role is not automatically an organization. | E09, E30; CQ04, CQ17 |
| `PlannerRole` | `RoleAssignment` | — | Contextual role assignment held by an agent | `PlannerRole ⊑ RoleAssignment`; use dated review events where accountability matters. | E20; CQ08, CQ17 |
| `DataArchitectRole` | `RoleAssignment` | — | Contextual governance-role assignment | `DataArchitectRole ⊑ RoleAssignment`; no specific person inferred. | E31; CQ17 |
| `PurchasingContract` | `InformationArtifact` | — | Particular agreement/version | `PurchasingContract ⊑ InformationArtifact`; parties and effective dates require evidence. | E30; CQ04 |
| `SafetyStockPolicy` | `Policy` | — | Policy individual, not the stock quantity itself | `SafetyStockPolicy ⊑ Policy`; connect policy to item/location and a quantity with units. | E11–E12, E24; CQ14 |
| `SafetyLeadTimePolicy` | `Policy` | — | Policy individual specifying a duration buffer | `SafetyLeadTimePolicy ⊑ Policy`; distinguish policy from its measured duration. | E24; CQ14 |
| `LotSizingPolicy` | `Policy` | — | Policy individual; method may be a controlled concept | `LotSizingPolicy ⊑ Policy`; do not equate distinct lot-sizing methods. | E23; CQ10 |
| `LeadTime` | `Measure` | — | Measured or planned duration individual | `LeadTime ⊑ Measure`; use unit, interval and planned/actual qualification. | E22, E24; CQ14, CQ19 |
| `CapacityMeasure` | `Measure` | — | Quantity for resource and period | `CapacityMeasure ⊑ Measure`; separate available, required and demonstrated meanings. | E07, E27; CQ12 |
| `CapacityConstraint` | `owl:Thing` | — | Constraint individual or rule; representation open | Parent deferred; a constraint is not the same individual as its measured capacity. | E02, E07; CQ12 |
| `TimeBucket` | `owl:Thing` | — | Planning interval individual | Parent deferred pending temporal vocabulary; use clear boundary and timezone rules. | E15, E21; CQ05–CQ06 |
| `PeggingLink` | `owl:Thing` | — | Contextual trace record connecting requirement and demand source | Parent deferred; a pegging path is not a causal or supply guarantee. | E25; CQ09–CQ10 |
| `KPIObservation` | `Measure` | — | One measurement of a named KPI for scope and period | `KPIObservation ⊑ Measure`; OEE definition and each observed value are separate. | E28; CQ13 |
| `ReasoningTool` | `owl:Thing` | — | A particular tool or tool type; scope open | Parent deferred; source requests reasoning but no tool execution is evidenced. | E35; CQ21 |
| `RelationshipAssertion` | `InformationArtifact` | — | One source-backed or proposed assertion record | `RelationshipAssertion ⊑ InformationArtifact`; preserve evidence, status and provenance independently of canonical triples. | E34; CQ22 |

### Supporting acquisition-layer classes

These classes were proposed alongside the 45 terms and are necessary for the
three-layer process. They are additional candidates, not a merge of layers.

| Class | Proposed superclass / subclasses | Form and proposed axiom | Disjointness | Evidence / CQ |
| --- | --- | --- | --- | --- |
| `SourceDocument` | `InformationArtifact` / — | Document-version individual; `SourceDocument ⊑ InformationArtifact`. | None proposed. | E34–E35; CQ22 |
| `SourcePassage` | `InformationArtifact` / — | A located passage of one version; `SourcePassage ⊑ InformationArtifact`. | None proposed. | E34; CQ22 |
| `Mention` | `InformationArtifact` / — | A source occurrence, not a canonical entity; `Mention ⊑ InformationArtifact`. | None proposed. | E34; CQ22 |

These are modeling choices; OWL does not guarantee a one-to-one mapping
between a document, its text, a passage, a mention, and an external referent.
Source quotation fidelity is checked independently of ontology semantics.

## The difficult hierarchy: item, part, role and state

The following is a **proposed** fragment, not a partition:

```text
Item
├── RawMaterial
├── DetailPart
├── StandardPart
└── Product
```

In this draft `Product ⊑ Item` is useful for CQ02, but a product definition,
individual manufactured unit and SKU may need different classes or identifiers.
`RawMaterial` describes a use relative to a process; a particular item may
be a finished product for one supplier and raw material for another.
`DetailPart` and `StandardPart` describe sourcing/design classifications;
whether their meanings overlap depends on the enterprise's rules. **No
`DisjointClasses` axiom, exhaustive union, or equivalent-class axiom is
proposed for these four candidates.**

`WorkInProcess` is instead proposed as a state: a part can enter and leave it.
State can be recorded as a time-bounded observation/assignment linked to an
item or lot; an immutable OWL type on an item alone does not capture change.
Likewise, a `Supplier` or `PlannerRole` is a contextual role assignment, held
by an agent over some period. Neither role need be an intrinsic, permanent
type of the agent. Review whether the intended ontology prefers roles as
classes on agents or separate assignment individuals before committing.

## Candidate object and datatype property design

This is a focused design for the main questions, not a full property
inventory. Other candidates and their source references remain in the
[acquisition notebook](./mrp-ontology-notebook.md#candidate-owl-object-properties).
All property names and interpretations remain provisional.

| Property | Intended subject → object/value | Proposed OWL characteristic or axiom | CQ and review concern |
| --- | --- | --- | --- |
| `hasBOM` | Item → BillOfMaterials | Object property; no global domain/range or cardinality asserted yet. | CQ02; product variants, versions and effectivity matter. |
| `hasBOMLine` | BillOfMaterials → BOMLine | Object property; no functional/inverse-functional assertion. | CQ01–CQ02; lines may recur in versions. |
| `parentItem`, `componentItem` | BOMLine → Item | Separate object properties; no `owl:sameAs` or transitivity. | CQ01–CQ02; record a specific usage. |
| `quantityPerParent` | BOMLine → decimal | Datatype property; propose `xsd:decimal` value and separate `unitOfMeasure`. | CQ01, CQ16; quantity is not a property of the component globally. |
| `unitOfMeasure` | BOMLine / measure → Unit | Object property; no single global domain restriction. | CQ01, CQ14, CQ16; agree on unit scheme/conversion. |
| `hasRouting`, `hasOperation` | Order → Routing; Routing → Operation | Object properties; no global uniqueness or existence restrictions. | CQ03, CQ11; distinguish reusable definition from assignment. |
| `performedAt` | Operation definition/assignment → WorkCenter | Object property; selection of a definition vs dated execution/assignment is unresolved. | CQ03; no claim that an operation actually occurred. |
| `hasNextOperation` | Operation → Operation | Object property; do **not** make direct-next transitive. | CQ11; repeatable steps, branches and routing versions require contextual ordering. |
| `hasResource` | WorkCenter → ManufacturingResource | Object property; no identity implication between group and member. | CQ03; group membership may change over time. |
| `heldBy` | RoleAssignment → Agent | Object property; no `owl:FunctionalProperty` until role multiplicity and time scope are reviewed. | CQ04, CQ08, CQ17. |
| `suppliesMaterial` | Supplier role assignment → Item | Object property; reviewed source/period required for instance assertions. | CQ04; sourcing capability is not necessarily a completed delivery. |
| `fulfillsRequirement` | PlannedOrder → NetRequirement | Object property; no assertion that a plan was executed or demand fulfilled. | CQ06–CQ07, CQ10; name may require replacement if interpreted as actual fulfillment. |
| `sku` | Product variant → string | Datatype property with proposed `xsd:string` range; no global key. | CQ02; leading zeroes, issuing system and lifecycle need review. |
| `orderQuantity` | PlannedOrder / ProductionOrder → decimal | Datatype property; unit and status required by design, not by an OWL assertion here. | CQ07–CQ08. |
| `setupTime`, `runTime` | Operation → decimal | Datatype properties; pair with explicit unit and per-unit basis. | CQ03, CQ11–CQ12. |
| `supportedBy` | Mention / RelationshipAssertion → SourcePassage | Object property; review evidence before promoting an assertion. | CQ22; evidence of a source claim is not automatic proof of its truth. |
| `refersTo` | Mention → reviewed domain individual or concept | Object property; add only after a resolution decision. | CQ22; no automatic identity merging. |

Do not set one shared property domain for multiple intended kinds by repeating
`rdfs:domain`: multiple domain statements mean intersection, not choice.
Avoid global OWL cardinalities or disjointness until their consequences are
agreed; use reviewed SHACL shapes for record completeness and value checks.
OWL follows an open-world assumption: absent facts are not automatically
false, and an existential restriction may be satisfied by an unnamed
individual. OWL reasoning is not an MRP calculator.

## Additional competency questions for uncovered design decisions

These complement the original questions; they are not asserted answers about
real operations.

| ID | Question | Design implication / current evidence |
| --- | --- | --- |
| CQ17 | Who held the supplier, planner or data-architect role, in what context and period? | Role assignment, agent and time are separate; E20, E30–E31 do not identify actual assignments. |
| CQ18 | Which resources and processes were actually used for an order? | Separate a definition and authorization from dated execution and assignments; E01, E03, E06 are generic. |
| CQ19 | Which planning method, inputs, forecast and lead-time assumptions were used in a particular run? | Distinguish MRP from MRP II and a method from its run; E13–E14, E22. |
| CQ20 | When was a particular item or lot work in process? | State assignment and interval, not a permanent item subclass; E10 gives no actual item. |
| CQ21 | Which reasoner checked which ontology version, and with what result? | Model a validation activity and result separately if needed; E35 is an instruction, not a run. |
| CQ22 | Which source passage and mention support a proposed or reviewed assertion? | Separate source, passage, mention, assertion, resolution and review status; E34 and evidence records. |

## Test scenarios before formalizing

These are **synthetic design scenarios**, not records from the documents or a
claim that a reasoner has been run.

1. A fictional item is a `DetailPart` and also a `StandardPart`. The proposed
   hierarchy permits both; a future disjointness decision would make the
   combination inconsistent and must be justified by the domain.
2. A fictional BOM has a line pointing to a component, with quantity `2`
   and a unit. CQ01 can retrieve the line's usage data. Reaching the component
   through a path does **not** by itself calculate multi-level requirements
   or account for revisions, lot sizing, yield or units (CQ16).
3. A fictional planned purchase recommendation exists without an actual
   purchase order. CQ07 must not return it as a released purchase merely
   because it is a `PlannedOrder`.
4. A fictional mention says “supplier” in a source passage, but has no
   reviewed `refersTo` link. CQ22 can retrieve the mention and evidence; it
   must not claim a particular canonical supplier or supply relationship.
5. A missing `performedAt` value in an incomplete source does not prove that
   an operation has no work center. A closed-world completeness check may
   flag the record; OWL alone does not make that inference (CQ03).

## Review decisions before implementation

1. Resolve the 12 questions in the acquisition notebook, particularly item
   identity, part categories, role assignments, temporal status, and BOM
   versioning. Decide who approves each mapping.
2. Select external standards and stable IRIs only after reviewing their
   semantics and licensing; no ISA-95 or other equivalence is asserted here.
3. Define executable OWL axioms and separate SHACL constraints with explicit
   temporal, unit and provenance conventions. Test satisfiability and the
   synthetic scenarios with a reasoner and validator.
4. Turn competency questions into queries over versioned test fixtures,
   including expected unknowns. Obtain domain-expert approval before loading
   operational data or treating the proposed relationships as facts.
