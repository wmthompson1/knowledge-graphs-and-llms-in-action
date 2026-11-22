# MRP document analysis: evidence, mentions, and candidate ontology

## Scope and method

The primary source is [Manufacturing and MRP Terminology in Semantic Models](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md)
(**T**); supporting sources are [Core - Parts](./My%20MRP%20501.001%20Outline%20-%20Core%20-%20Parts.md)
(**P**) and [Deterministic Semantic Architecture](./My%20MRP%20-%20Deterministic%20Semantic%20Architecture.md)
(**A**). These are separate documents; their assertions are not automatically
equivalent. The tagged `:Zone.Identifier` files are empty metadata, not content.
The DOCX versions have no usable stored page breaks. The main DOCX reports
one page in metadata despite containing approximately 15,000 words, so that
number is not reliable. **Page for every record below: unknown**. Markdown line
and section references are reproducible substitutes, not inferred page numbers.
Rendered page numbers must be added from an authoritative paginated version.

The main reference is an internal, general terminology document, not a
production dataset. The parts document itself warns that AI responses may
contain mistakes. Statements below are **claims made by these sources**, not
independently verified facts or assertions about an actual factory.

Local Chapter 6-style extraction was run over the three Markdown files with
spaCy `en_core_web_sm` and a small case-insensitive entity ruler. The generic
model labeled `BOM` as `ORG` and `MRP` as `GPE`; these are examples of why
automatic labels need domain review. The domain rules found occurrences of,
among others, `bill of materials`, `planned order`, `routing`, and `work center`,
but did not establish relationships or identities. Counts from the Markdown
are not document frequencies and are not an exhaustive vocabulary: rule
matches can be masked by existing NER spans and morphology. The inventory
below is a **curated initial selection**, not all occurrences or a complete
ontology. No source was sent to an external service or loaded into a graph.

## Layer 1 — source evidence only

Each entry preserves the source sentence, its surrounding section or paragraph
context, and confidence in *transcription*, not truth. Bold formatting is
omitted from quotations; text otherwise follows the Markdown. The page is
unknown for **each** entry. IDs permit independent mention and semantic
records to point back to this layer.

The companion [source-evidence records](./mrp-source-evidence.json) retain
each original Markdown line and its neighboring nonempty lines, source-file
hash, location, unknown page and transcription-confidence note. These
surrounding lines are source context, not inferred concepts.

| ID | Source and context | Source sentence | Confidence notes |
| --- | --- | --- | --- |
| E01 | [T §2.2, line 135](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L135); definition paragraph | Manufacturing is the transformation of raw materials, components, or semi-finished goods into finished products through physical, chemical, or assembly processes. | Exact text; general definition. |
| E02 | [T §2.2, line 137](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L137); planning definition | Production Planning is the process of determining what to manufacture, in what quantities, and on what schedule, balancing demand forecasts against capacity constraints and inventory levels. | Exact text; general process description. |
| E03 | [T §2.2, line 141](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L141); work-center definition | Work Center is a defined grouping of machines, tools, or labor resources used to perform specific manufacturing operations. | Exact text; definition rather than instance. |
| E04 | [T §2.2, line 143](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L143); routing definition | Routing is the defined sequence of operations, work centers, and time standards required to manufacture one unit of a product. | Exact text; definition. |
| E05 | [T §2.2, line 145](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L145); operation definition | Each operation specifies the work center where it is performed, the standard setup time (time to prepare the work center), the standard run time per unit produced, and any tooling or resource requirements. | Exact text; general specification. |
| E06 | [T §2.2, line 147](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L147); order definition | Production Order (Work Order) is a formal shop-floor document — in paper or electronic form — that authorizes the manufacture of a specified quantity of a product by a target completion date. | Exact text; parenthesized label occurs in this source context. |
| E07 | [T §2.2, line 149](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L149); capacity-planning definition | Capacity Planning is the process of determining the production capacity needed to meet demand, expressed in machine hours or labor hours per work center per planning period. | Exact text; general definition. |
| E08 | [T §2.3, line 155](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L155); inventory identifiers | Stock Keeping Unit (SKU) is the lowest-level unique identifier for a product variant — the atomic unit of inventory management. | Exact text; scope of uniqueness needs review. |
| E09 | [T §2.3, line 157](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L157); material definition | Raw materials sit at the deepest levels of the Bill of Materials hierarchy (Level N) and are typically sourced from external suppliers rather than produced internally. | Exact text; “typically” is not universal. |
| E10 | [T §2.3, line 159](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L159); inventory states | Work in Process (WIP) refers to partially manufactured goods currently in production — units for which manufacturing has begun but not yet completed. | Exact text; general definition. |
| E11 | [T §2.3, line 163](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L163); safety-stock paragraph | It is a quantity expressed in units and is a property of the Material–Location combination in ERP systems. | Exact text; “It” refers to safety stock in preceding sentence. |
| E12 | [T §2.3, line 165](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L165); reorder-point paragraph | It is calculated as: average demand during lead time plus safety stock. | Exact text; “It” refers to reorder point in preceding sentence. |
| E13 | [T §3.1, line 171](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L171); MRP definition and history | It is, at its core, a deterministic calculation engine: given a Master Production Schedule (what finished goods to produce and when), a set of Bills of Materials (what components are needed), and current inventory levels, MRP calculates the time-phased quantities of each component that must be either manufactured or purchased to support the production plan. | Exact text; “It” refers to Material Requirements Planning. |
| E14 | [T §3.1, line 173](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L173); MRP II contrast | MRP II (Manufacturing Resource Planning) extended MRP beyond material requirements into the broader domain of manufacturing resource management. | Exact text; distinguishes the two names in this context. |
| E15 | [T §3.2, line 181](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L181); schedule definition | Master Production Schedule (MPS) is the time-phased plan that states which end items (Level 0 BOM items — finished goods or major subassemblies) will be produced, in what quantities, and in which time periods. | Exact text; definition. |
| E16 | [T §3.2, line 186](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L186); BOM definition | Bill of Materials (BOM) is a hierarchical, structured list of all components, sub-assemblies, and raw materials required to manufacture one unit of a parent item, together with the quantities required per parent unit and the units of measure. | Exact text; generic structure, not a particular BOM. |
| E17 | [T §3.2, line 190](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L190); net-requirements paragraph | Net Requirements represent the uncovered demand for a component after accounting for on-hand inventory and scheduled receipts (open purchase orders and production orders). | Exact text; source's simplified description. |
| E18 | [T §3.2, line 192](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L192); gross-requirements paragraph | They are computed by multiplying planned quantities of each parent item by the BOM quantity of the component. | Exact text; “They” refers to gross requirements. |
| E19 | [T §3.2, line 194](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L194); planned-order paragraph | Planned orders are not yet released to the shop floor or to suppliers; they represent the MRP system's suggested action. | Exact text; recommendation is not an executed order. |
| E20 | [T §3.2, line 196](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L196); firm planned order | Firm Planned Order (FPO) is a planned order that has been manually reviewed and confirmed by a planner. | Exact text; general definition. |
| E21 | [T §3.2, line 198](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L198); time-bucket paragraph | Time Bucket is the planning period unit over which MRP aggregates requirements and calculates planned orders. | Exact text; general definition. |
| E22 | [T §3.2, line 200](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L200); lead-time paragraph | For purchased items, lead time is the vendor's delivery time. | Exact text; not a measured delivery for a named supplier. |
| E23 | [T §3.2, line 202](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L202); lot-sizing paragraph | Lot Sizing is the rule that determines the quantity of a planned order. | Exact text; no particular policy selected. |
| E24 | [T §3.2, line 210](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L210); buffers paragraph | It is a time-based buffer (measured in days), as distinct from safety stock, which is a quantity-based buffer. | Exact text; “It” refers to safety lead time. |
| E25 | [T §3.2, line 212](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L212); pegging paragraph | Pegging is the ability to trace a component requirement back through the BOM hierarchy to the original demand source — typically a customer order or forecast. | Exact text; “typically” qualifies examples. |
| E26 | [T §3.3, line 216](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L216); rough-cut capacity | Rough-Cut Capacity Planning (RCCP) is a high-level, pre-MRP check of whether the Master Production Schedule is feasible against key resource capacities — the production lines, machines, or labor pools that are most likely to constrain output. | Exact text; general planning method. |
| E27 | [T §3.3, line 218](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L218); detailed capacity | Capacity Requirements Planning (CRP) is the detailed calculation of the capacity required at each work center in each time period, derived from MRP planned orders and their associated routings. | Exact text; general planning method. |
| E28 | [T §7.2, line 374](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L374); equipment KPI | Overall Equipment Effectiveness (OEE) is the product of three component factors: Availability (actual runtime divided by planned production time), Performance (actual output rate divided by ideal output rate), and Quality (good units produced divided by total units started). | Exact text; definition, not an observed KPI value. |
| E29 | [T §8.3, line 415](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L415); hybrid BOM and routing pattern | The BOM and routing graphs are connected via an associatedOperation ObjectProperty linking each MaterialComponent individual (in the BOM graph) to the Operation individuals (in the routing graph) that consume it. | Exact text; proposed modeling pattern. |
| E30 | [T §8.5, line 429](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L429); supplier ontology pattern | Each Supplier individual is linked to the MaterialClass individuals it supplies via the suppliesMaterial ObjectProperty, and to PurchasingContract individuals via the governedBy ObjectProperty. | Exact text; describes a proposed schema, not a specific supply transaction. |
| E31 | [T §8.7, line 443](./Manufacturing%20and%20MRP%20Terminology%20in%20Semantic%20Models.md#L443); governance role list | Data Architect: responsible for ontology design, OWL class hierarchy decisions, property definitions, and alignment to external standards (ISA-95, eCl@ss, SKOS) | Exact list item, not a complete sentence; role description. |
| E32 | [P opening, line 5](./My%20MRP%20501.001%20Outline%20-%20Core%20-%20Parts.md#L5); first of two contrasted definitions | In manufacturing, a detail part is a custom-engineered component manufactured specifically for a unique assembly, often made to order via custom drawings. | Exact text; source warns of possible AI mistakes. |
| E33 | [P opening, line 5](./My%20MRP%20501.001%20Outline%20-%20Core%20-%20Parts.md#L5); second contrasted definition | Conversely, a standard part (or "off-the-shelf" item) is a pre-manufactured, interchangeable component (like bolts, bearings, or resistors) designed for general use, high-volume consistency, and ease of sourcing. | Exact text; examples are not named inventory instances. |
| E34 | [A §2, line 22](./My%20MRP%20-%20Deterministic%20Semantic%20Architecture.md#L22); NLP workflow actions | Identify relationships between entities (verbs, prepositions). | Exact list item; proposed workflow instruction. |
| E35 | [A §5, line 45](./My%20MRP%20-%20Deterministic%20Semantic%20Architecture.md#L45); ontology validation actions | Validate ontology consistency using reasoners. | Exact list item; validation has not been performed here. |

## Layer 2 — metagraph of mentions

Each row is one selected occurrence, not an automatically merged entity.
Evidence IDs locate the sentence and therefore the source and page; **page:
unknown for every row**. Normalized labels are lexical suggestions only; they
are not identity links. Repeated terms in other passages remain separate
mentions. “Type” is a candidate interpretation, not a source-layer fact.

| Mention ID | Term as written | Proposed label | Candidate type | Evidence |
| --- | --- | --- | --- | --- |
| M01 | Manufacturing | Manufacturing | Process | E01 |
| M02 | raw materials | raw material | Material | E01 |
| M03 | components | component | Inventory item | E01 |
| M04 | finished products | finished product | Product | E01 |
| M05 | Production Planning | production planning | Process | E02 |
| M06 | demand forecasts | demand forecast | Planning input | E02 |
| M07 | capacity constraints | capacity constraint | Constraint | E02 |
| M08 | inventory levels | inventory level | Inventory measure | E02 |
| M09 | Work Center | work center | Work center / resource | E03 |
| M10 | machines | machine | Resource | E03 |
| M11 | labor resources | labor resource | Resource | E03 |
| M12 | Routing | routing | Process definition | E04 |
| M13 | operations | operation | Process step | E04 |
| M14 | work center | work center | Work center | E05 |
| M15 | standard setup time | standard setup time | Duration | E05 |
| M16 | Production Order | production order | Order | E06 |
| M17 | Work Order | work order | Order | E06 |
| M18 | Capacity Planning | capacity planning | Process | E07 |
| M19 | Stock Keeping Unit (SKU) | stock keeping unit | Identifier | E08 |
| M20 | suppliers | supplier | Organization / role | E09 |
| M21 | Work in Process (WIP) | work in process | Inventory state | E10 |
| M22 | Material–Location combination | material-location combination | Inventory context | E11 |
| M23 | safety stock | safety stock | Inventory policy / quantity | E12 |
| M24 | Master Production Schedule | master production schedule | Plan | E13 |
| M25 | Bills of Materials | bill of materials | Product structure | E13 |
| M26 | MRP | MRP | Planning method / engine | E13 |
| M27 | MRP II | MRP II | Planning method / system | E14 |
| M28 | Manufacturing Resource Planning | manufacturing resource planning | Planning method | E14 |
| M29 | Master Production Schedule (MPS) | master production schedule | Plan | E15 |
| M30 | Bill of Materials (BOM) | bill of materials | Product structure | E16 |
| M31 | parent item | parent item | Inventory item | E16 |
| M32 | units of measure | unit of measure | Unit | E16 |
| M33 | Net Requirements | net requirements | Requirement | E17 |
| M34 | on-hand inventory | on-hand inventory | Inventory measure | E17 |
| M35 | scheduled receipts | scheduled receipt | Supply | E17 |
| M36 | purchase orders | purchase order | Order | E17 |
| M37 | Planned orders | planned order | Order recommendation | E19 |
| M38 | Firm Planned Order (FPO) | firm planned order | Order recommendation | E20 |
| M39 | planner | planner | Role | E20 |
| M40 | Time Bucket | time bucket | Planning period | E21 |
| M41 | lead time | lead time | Duration | E22 |
| M42 | Lot Sizing | lot sizing | Policy | E23 |
| M43 | safety stock | safety stock | Inventory quantity | E24 |
| M44 | Pegging | pegging | Planning method | E25 |
| M45 | customer order | customer order | Order | E25 |
| M46 | forecast | forecast | Planning input | E25 |
| M47 | Rough-Cut Capacity Planning (RCCP) | rough-cut capacity planning | Planning method | E26 |
| M48 | Capacity Requirements Planning (CRP) | capacity requirements planning | Planning method | E27 |
| M49 | Overall Equipment Effectiveness (OEE) | overall equipment effectiveness | KPI | E28 |
| M50 | Supplier | supplier | Organization / role | E30 |
| M51 | PurchasingContract | purchasing contract | Agreement | E30 |
| M52 | Data Architect | data architect | Role | E31 |
| M53 | detail part | detail part | Inventory item | E32 |
| M54 | standard part | standard part | Inventory item | E33 |
| M55 | off-the-shelf | off-the-shelf | Qualifier | E33 |
| M56 | relationships | relationship | Semantic-model element | E34 |
| M57 | reasoners | reasoner | Validation tool | E35 |
| M58 | Safety Lead Time | safety lead time | Policy / duration | E24 |
| M59 | demand | demand | Planning input | E07 |
| M60 | product | product | Product | E06 |
| M61 | inventory | inventory | Planning input | E13 |
| M62 | capacity | capacity | Resource measure | E07 |
| M63 | Operation | operation | Process step | E05 |
| M64 | Material Requirements Planning (MRP) | material requirements planning | Planning method / engine | E13 |

### Relationship mentions and classification

**Observed** means a relationship is explicitly described by a cited sentence
or source pattern, not that any particular operational instance exists.
**Candidate** is a proposed mapping or question-driven relation not directly
asserted in the cited sentence. **Inferred** is a conditional conclusion that
requires explicit facts and rules; no such conclusion has been materialized.

| ID | Mention-level relationship | Classification | Evidence and qualification |
| --- | --- | --- | --- |
| R01 | Work Center — grouping used to perform → operations | Observed | E03; generic definition. |
| R02 | operation — specifies where performed → work center | Observed | E05; not evidence that a specific operation ran. |
| R03 | Routing — defines sequence of → operations | Observed | E04; order must be represented explicitly. |
| R04 | BOM — lists → components, sub-assemblies, raw materials and per-parent quantities | Observed | E16; schema-level description. |
| R05 | Supplier — supplies → MaterialClass | Observed | E30 describes a model pattern, not an actual supplier/material pairing. |
| R06 | planned order — is not yet released to → suppliers or shop floor | Observed | E19; preserve negation and recommendation status. |
| R07 | firm planned order — reviewed and confirmed by → planner | Observed | E20; general definition, no identified planner. |
| R08 | pegging — traces requirement to → demand source | Observed | E25; customer order or forecast is qualified as typical. |
| R09 | Production Order — authorizes manufacture of → specified product quantity | Observed | E06; generic definition. |
| R10 | Demand — generates → Planned Order | Candidate | E17, E19, E25 support a planning connection but not this direct edge; intervening netting and policies matter. |
| R11 | MRP plan — requires → inventory | Candidate | E13 names current inventory levels as an input; “requires inventory” must not conflate an input with material demand. |
| R12 | product — uses → material | Candidate | E16 describes a BOM list; an actual product-material pairing needs a particular effective BOM line. |
| R13 | component → indirect component of product via multiple BOM lines | Inferred, conditional | Requires reviewed direct component links, versions and effective dates. This follows only under an adopted transitive rule; it does not calculate required quantities. |
| R14 | shortage → affects a customer order | Inferred, conditional | Requires a dated shortage, valid pegging and supply/availability rules; E25 describes traceability, not an actual affected order. |

## Layer 3 — candidate semantic / ontology notebook

All names in this layer are **proposals**, not an installed OWL ontology.
`mrp:` below stands for a placeholder namespace, `https://example.org/mrp#`,
not a published vocabulary. A class denotes a kind; a particular SKU,
supplier, order, operation or material would be an individual only when
identified in a source system. The source definitions alone do not provide
verified operational individuals. Example names in the reference are
illustrative, not evidence of this user's factory.

The table gives each term's proposed class, possible individual and suggested
object/datatype properties; a dash means none is established or none is
proposed here. Synonyms are lexical candidates scoped to the cited passage,
not automatic `owl:sameAs` assertions.

| Extracted term | Candidate OWL class | Candidate individual | Candidate object / datatype properties | Synonyms or variants; evidence |
| --- | --- | --- | --- | --- |
| Manufacturing | `ManufacturingProcess` | A particular process, not identified | `usesInput`, `producesItem` / — | —; E01 |
| raw materials | `RawMaterial` | A particular material, not identified | — / — | material is broader, not necessarily a synonym; E01, E09 |
| components | `Item` | A particular component, not identified | `componentItem` / — | part may be context-dependent; E01, E16 |
| finished products | `Product` | A particular product, not identified | `hasBOM` / `sku` | finished goods in context require review; E01, E08 |
| Production Planning | `ProductionPlanning` | A planning run, not identified | `usesDemand`, `considersCapacity` / — | —; E02 |
| demand forecasts; forecast | `Forecast` | A particular forecast, not identified | `forecastFor` / `quantity`, `periodStart`, `periodEnd` | forecast; E02, E25 |
| capacity constraints | `CapacityConstraint` | A specific constraint, not identified | `appliesToResource` / `quantity` | —; E02, E07 |
| inventory levels; on-hand inventory | `InventoryPosition` | A position for an item/location/time, not identified | `forItem`, `atLocation` / `onHandQuantity` | not automatically equivalent to available inventory; E02, E11, E17 |
| Work Center; work center | `WorkCenter` | A particular work center, not identified | `hasResource` / — | capitalization only; E03, E05 |
| machines; labor resources | `ManufacturingResource` | Specific machine or labor resource, not identified | — / — | potential subtypes require review; E03 |
| Routing | `Routing` | A particular routing/version, not identified | `hasOperation` / `effectiveFrom`, `effectiveTo` | —; E04 |
| operations | `Operation` | A particular operation definition, not identified | `performedAt`, `hasNextOperation` / `setupTime`, `runTime` | process step is a candidate, not an identity decision; E04–E05 |
| Production Order; Work Order | `ProductionOrder` | A particular authorized order, not identified | `authorizesItem`, `hasBOM`, `hasRouting` / `orderQuantity`, `targetDate` | source associates names in E06; cross-system equivalence pending |
| Capacity Planning | `CapacityPlanning` | A particular planning run, not identified | `considersCapacity` / — | —; E07 |
| Stock Keeping Unit (SKU) | — | A particular SKU value, not identified | — / `sku` | SKU; E08; datatype vs identifier object depends on governance |
| suppliers; Supplier | `Supplier` | A particular supplier, not identified | `suppliesMaterial` / — | supplier as organization or role remains open; E09, E30 |
| Work in Process (WIP) | `WorkInProcess` | A particular partially completed item/lot, not identified | — / — | WIP; E10; state vs class is open |
| Material–Location combination | `InventoryPosition` | A particular item-location position, not identified | `forItem`, `atLocation` / `safetyStockQuantity` | source uses material-location; E11 |
| safety stock | `SafetyStockPolicy` | A specific policy/quantity, not identified | `appliesToPosition` / `safetyStockQuantity` | no equivalence with safety lead time; E11–E12, E24 |
| Master Production Schedule (MPS) | `MasterProductionSchedule` | A particular schedule/version, not identified | `schedulesItem`, `hasTimeBucket` / — | MPS; E13, E15 |
| Bill of Materials (BOM) | `BillOfMaterials`, `BOMLine` | A specific BOM or line, not identified | `hasBOMLine`, `parentItem`, `componentItem`, `unitOfMeasure` / `quantityPerParent`, `effectiveFrom`, `effectiveTo` | BOM; E13, E16 |
| MRP | `MaterialRequirementsPlanning` | A particular calculation run, not identified | `usesSchedule`, `usesBOM`, `usesInventory` / — | Material Requirements Planning in §3.1; E13; see U01 |
| MRP II; Manufacturing Resource Planning | `ManufacturingResourcePlanning` | A particular planning system/run, not identified | — / — | MRP II in E14, not equivalent to MRP; E14 |
| Net Requirements | `NetRequirement` | A specific item/period requirement, not identified | `forItem`, `hasTimeBucket` / `quantity` | —; E17 |
| scheduled receipts | `ScheduledReceipt` | A particular receipt, not identified | `forItem` / `quantity`, `dueDate` | source gives open orders as context; E17 |
| purchase orders | `PurchaseOrder` | A particular purchase order, not identified | `ordersItem`, `orderedFrom` / `orderQuantity`, `dueDate` | not automatically a planned order; E17, E19 |
| Planned orders | `PlannedOrder` | A particular recommendation, not identified | `forItem`, `fulfillsRequirement` / `orderQuantity`, `dueDate` | —; E19 |
| Firm Planned Order (FPO) | `FirmPlannedOrder` | A particular reviewed order, not identified | `reviewedBy` / — | FPO; E20 |
| planner | `PlannerRole` | A particular planner role, not identified | `reviewedBy` inverse subject use / — | —; E20 |
| Time Bucket | `TimeBucket` | A particular period, not identified | — / `periodStart`, `periodEnd` | planning period, context-dependent; E21 |
| lead time | `LeadTime` | A particular measured/planned duration, not identified | `appliesToItem`, `unitOfMeasure` / `durationValue` | delivery time in E22 context; not safety lead time |
| Lot Sizing | `LotSizingPolicy` | A chosen policy, not identified | `appliesToItem` / — | lot-for-lot, EOQ, FOQ, POQ are different methods, not synonyms; E23 |
| Pegging | `PeggingLink` | A particular pegging record, not identified | `requirement`, `demandSource` / — | —; E25 |
| customer order | `CustomerOrder` | A particular order, not identified | — / — | sales order may be equivalent in a specific system; E25 |
| Rough-Cut Capacity Planning (RCCP) | `RoughCutCapacityPlanning` | A particular check, not identified | `checksSchedule` / — | RCCP; E26 |
| Capacity Requirements Planning (CRP) | `CapacityRequirementsPlanning` | A particular calculation, not identified | `evaluatesWorkCenter`, `hasTimeBucket` / — | CRP; E27, distinct from RCCP |
| Overall Equipment Effectiveness (OEE) | `KPIObservation` | A specific OEE observation, not identified | `measuresResource`, `hasTimeBucket` / `value` | OEE is a measure definition; observation is a separate individual; E28 |
| PurchasingContract | `PurchasingContract` | A particular contract, not identified | `governsSupplier` / — | —; E30 |
| Data Architect | `DataArchitectRole` | A particular role assignment, not identified | — / — | —; E31 |
| detail part | `DetailPart` | A particular part, not identified | `specifiedByDrawing` / `partNumber` | custom/non-standard are contextual labels in P, not universal synonyms; E32 |
| standard part; off-the-shelf | `StandardPart` | A particular part, not identified | `conformsToStandard` / `partNumber` | off-the-shelf is contextual; E33 |
| relationships | `RelationshipAssertion` | A particular assertion, not identified | `subjectMention`, `objectMention`, `supportedBy` / `status` | —; E34 |
| reasoners | `ReasoningTool` | A particular reasoner, not identified | — / — | —; E35 |
| Safety Lead Time | `SafetyLeadTimePolicy` | A particular buffer, not identified | `appliesToItem`, `unitOfMeasure` / `durationValue` | distinct from safety stock; E24 |
| demand | `Demand` | A particular demand, not identified | `forItem`, `hasTimeBucket` / `quantity` | customer order and forecast can be demand sources; E07, E25 |
| product | `Product` | A particular product, not identified | `hasBOM` / `sku` | product variant distinctions need review; E06, E08 |
| inventory | `InventoryPosition` | A particular position, not identified | `forItem`, `atLocation` / `onHandQuantity` | inventory level is contextual, not a synonym for all inventory; E11, E13 |
| capacity | `CapacityMeasure` | A particular capacity measure, not identified | `appliesToResource`, `hasTimeBucket` / `quantity` | available vs required capacity need distinction; E07, E27 |
| Operation | `Operation` | A particular operation, not identified | `performedAt`, `hasNextOperation` / `setupTime`, `runTime` | —; E05 |
| Material Requirements Planning (MRP) | `MaterialRequirementsPlanning` | A particular run, not identified | `usesSchedule`, `usesBOM`, `usesInventory` / — | MRP, in this source context; E13 |

### Candidate RDF/OWL classes and design constraints

The table above is the candidate class inventory. Plausible subclass choices
for review include `RawMaterial`, `DetailPart`, and `StandardPart` under
`Item`, and `FirmPlannedOrder` under `PlannedOrder`. They are proposals,
not proven disjoint classes: raw material, manufactured item, purchased item,
standard part, and inventory status can overlap or depend on context.
`Product` and `Item` are not automatically identical.

Suggested metadata classes are `SourceDocument`, `SourcePassage`, `Mention`,
and `RelationshipAssertion`. Keep source passage, source mentions, proposed
resolution, and reviewed domain concept as distinct resources. Link a
mention to evidence with `supportedBy`, and only add `refersTo` after review.
An assertion can link its subject and object mentions, evidence, status, and
reviewer. An inferred assertion should also identify its rule and inputs.

### Candidate OWL object properties

Domains and ranges below are *intended modeling guidance*, not asserted OWL
axioms: hard `rdfs:domain` and `rdfs:range` can infer types. Review with a
domain expert before formalizing; use SHACL separately for data validation.

| Property | Intended subject → object | Basis |
| --- | --- | --- |
| `hasBOM` | Product / Item → BillOfMaterials | Candidate; E16 |
| `hasBOMLine` | BillOfMaterials → BOMLine | Candidate reification; E16 |
| `parentItem`, `componentItem` | BOMLine → Item | Candidate; E16 |
| `unitOfMeasure` | BOMLine / LeadTime → Unit | Candidate; E16, E22 |
| `hasRouting` | ProductionOrder → Routing | Candidate; E04, E06 |
| `hasOperation` | Routing → Operation | Observed schema mapping; E04 |
| `hasNextOperation` | Operation → Operation | Candidate ordering representation; E04 |
| `performedAt` | Operation → WorkCenter | Observed schema mapping; E05 |
| `hasResource` | WorkCenter → ManufacturingResource | Candidate; E03 |
| `suppliesMaterial` | Supplier → RawMaterial or other Item | Source pattern, E30; actual pairs need evidence |
| `usesSchedule`, `usesBOM`, `usesInventory` | MaterialRequirementsPlanning run → respective input | Candidate; E13 |
| `fulfillsRequirement` | PlannedOrder → NetRequirement | Candidate; E17, E19 |
| `reviewedBy` | FirmPlannedOrder → PlannerRole | Observed schema mapping; E20 |
| `requirement`, `demandSource` | PeggingLink → Requirement / DemandSource | Candidate; E25 |
| `forItem`, `atLocation` | InventoryPosition → Item / Location | Candidate; E11, E17 |
| `supportedBy`, `refersTo` | Mention / assertion → SourcePassage; Mention → reviewed concept | Provenance design; E34; `refersTo` requires review |
| `usesInput`, `producesItem` | ManufacturingProcess → Item | Candidate; E01 |
| `usesDemand`, `considersCapacity` | ProductionPlanning → Demand / CapacityConstraint | Candidate; E02 |
| `forecastFor` | Forecast → Item | Candidate; E02; item association needs source-specific evidence |
| `appliesToResource` | CapacityConstraint / CapacityMeasure → ManufacturingResource | Candidate; E07, E27 |
| `authorizesItem` | ProductionOrder → Product | Candidate; E06 |
| `schedulesItem`, `hasTimeBucket` | MasterProductionSchedule → Item / TimeBucket | Candidate; E15 |
| `hasTimeBucket` | Demand / NetRequirement / KPIObservation / CapacityMeasure → TimeBucket | Candidate; E15, E17, E21, E27–E28 |
| `ordersItem`, `orderedFrom` | PurchaseOrder → Item / Supplier | Candidate; E09, E17; actual order association needs evidence |
| `appliesToPosition` | SafetyStockPolicy → InventoryPosition | Candidate; E11 |
| `appliesToItem` | LeadTime / LotSizingPolicy / SafetyLeadTimePolicy → Item | Candidate; E22–E24 |
| `checksSchedule` | RoughCutCapacityPlanning → MasterProductionSchedule | Candidate; E26 |
| `evaluatesWorkCenter` | CapacityRequirementsPlanning → WorkCenter | Candidate; E27 |
| `measuresResource` | KPIObservation → ManufacturingResource | Candidate; E28 |
| `governsSupplier` | PurchasingContract → Supplier | Candidate inverse of source's supplier-to-contract link; E30 |
| `specifiedByDrawing`, `conformsToStandard` | DetailPart / StandardPart → Drawing / Standard | Candidate; E32–E33; confirm specific links |
| `subjectMention`, `objectMention` | RelationshipAssertion → Mention | Candidate provenance design; E34 |

These properties are exploratory, not an approved inventory. In particular,
neither a generic
`hasPart` assertion nor a graph path alone can attach quantity and effective
dates to a specific parent-child usage. A `BOMLine` explicitly captures each
usage, quantity, unit, and version/effectivity. Recursive quantity roll-up
requires arithmetic, units, version selection, cycle checks and relevant MRP
rules; SPARQL property-path reachability alone does not accumulate quantities.

### Candidate OWL datatype properties

Ranges are proposals, not validation rules. Quantities must also carry a
unit and, where needed, a planning period and precision.

| Property | Intended subject | Candidate range | Evidence / qualification |
| --- | --- | --- | --- |
| `sku` | Product variant | `xsd:string` | E08; preserve leading zeroes. |
| `quantityPerParent` | BOMLine | `xsd:decimal` | E16; attach to the line, not globally to a component. |
| `orderQuantity` | ProductionOrder / PlannedOrder | `xsd:decimal` | E06, E19; unit required. |
| `onHandQuantity` | InventoryPosition | `xsd:decimal` | E17; time and availability scope needed. |
| `safetyStockQuantity` | InventoryPosition or policy | `xsd:decimal` | E11; item and location context. |
| `targetDate`, `dueDate` | Order | `xsd:date` or `xsd:dateTime` | E06; date/time choice depends on source precision. |
| `periodStart`, `periodEnd` | TimeBucket | `xsd:dateTime` | E15, E21; timezone and interval boundaries need policy. |
| `setupTime`, `runTime` | Operation | `xsd:decimal` | E05; explicit time unit and per-unit basis needed. |
| `durationValue` | LeadTime | `xsd:decimal` | E22; explicit unit and planned vs actual status needed. |
| `durationValue` | SafetyLeadTimePolicy | `xsd:decimal` | E24; unit and applicability needed. |
| `quantity` | Forecast / CapacityConstraint / NetRequirement / ScheduledReceipt / Demand / CapacityMeasure | `xsd:decimal` | E02, E07, E17, E27; unit and time context needed. |
| `effectiveFrom`, `effectiveTo` | BOMLine / Routing | `xsd:date` or `xsd:dateTime` | Candidate versioning extension; E04, E16 identify the structures, not specific effective dates. |
| `partNumber` | DetailPart / StandardPart | `xsd:string` | Candidate identifier; E32–E33; actual values require sources. |
| `value` | KPIObservation | `xsd:decimal` | E28; retain measurement period and metric definition. |
| `status` | RelationshipAssertion | `xsd:string` | E34; proposed controlled values observed/candidate/inferred. |

## Proposed KG schema — not loaded

The arrows below are **schema candidates**, not instance claims. The
evidence and mention layers stay separate from the canonical domain layer:

```text
SourceDocument --hasPassage--> SourcePassage <--supportedBy-- Mention
                                                        ^       |
                                                        |       +--refersTo--> reviewed domain individual
                                         RelationshipAssertion
                                           | subjectMention / objectMention
                                           +--> Mention

Product --hasBOM--> BillOfMaterials --hasBOMLine--> BOMLine
BOMLine --parentItem--> Item; BOMLine --componentItem--> Item
BOMLine --unitOfMeasure--> Unit; BOMLine --quantityPerParent--> decimal
ProductionOrder --hasRouting--> Routing --hasOperation--> Operation
Operation --performedAt--> WorkCenter --hasResource--> ManufacturingResource
Supplier --suppliesMaterial--> Item              [source-specific evidence required]
MaterialRequirementsPlanning --usesSchedule/usesBOM/usesInventory--> inputs
PlannedOrder --fulfillsRequirement--> NetRequirement --forItem--> Item
PeggingLink --requirement--> NetRequirement; --demandSource--> CustomerOrder/Forecast
```

Decisions about URI identity, versioned BOM and routing scope, assertion
confidence, graph storage, access control, and standards alignment remain
open. No graph, source resolution, or actual MRP run was created here.

## Competency questions

The expected answers below are scoped to the cited documents, not to an
actual factory. “Not established” is an intended answer when source data is
missing. Each CQ can later drive a query and a reviewed test fixture.

| ID | Question | Expected answer or evidence gap | Needed representation |
| --- | --- | --- | --- |
| CQ01 | What information does a BOM specify about components? | Components, sub-assemblies and raw materials, with quantities and units per parent unit; E16. | BOM, BOMLine, item, quantity, unit |
| CQ02 | What materials are required for a particular product? | Not established for a real product; no actual product BOM selected. E16 describes the structure. | Versioned BOM lines and quantities |
| CQ03 | Which work centers perform a particular operation? | Not established for an actual operation; E05 says an operation specifies a work center. | Operation, work-center assignment, effective period |
| CQ04 | Which suppliers provide a particular component? | Not established for an actual component; E30 proposes a supplier-material relationship. | Reviewed supplier-material evidence |
| CQ05 | What inputs does the document identify for MRP? | Master production schedule, BOMs, current inventory; E13. | Planning run and typed inputs |
| CQ06 | How are net requirements characterized? | Uncovered component demand after considering on-hand inventory and scheduled receipts; E17. | Requirements, inventory position, receipts, period |
| CQ07 | Does a planned order prove a purchase has been placed? | No; it is not yet released, E19. | Recommendation vs released order and status |
| CQ08 | What distinguishes a firm planned order? | A planner has reviewed and confirmed it, E20. | Order, review and planner role |
| CQ09 | Which demand source is associated with a requirement? | Pegging is described as tracing to an original source, typically customer order or forecast; no concrete link is given. E25. | Pegging link, requirement and demand source |
| CQ10 | What inventory shortages affect production or a customer order? | Not established; actual inventory, dated requirements and pegging are absent. E17, E25. | Dated availability, requirement, rule and provenance |
| CQ11 | What dependencies exist between operations? | A routing is a sequence, E04; no specific operation dependency instances are supplied. | Versioned routing and explicit ordered steps |
| CQ12 | How do RCCP and CRP differ in scope? | RCCP is a high-level pre-MRP check; CRP computes detailed capacity by work center and period from orders and routings. E26–E27. | Distinct planning-method concepts |
| CQ13 | What are the three factors of OEE? | Availability, Performance and Quality; E28. | KPI definition, component measures and observation period |
| CQ14 | What is the difference between safety stock and safety lead time? | The source describes quantity-based versus time-based buffers; E24. | Distinct policy concepts, units and scope |
| CQ15 | How are detail and standard parts described? | Custom-engineered for a unique assembly versus pre-manufactured and interchangeable; E32–E33. Review source caveat. | Part categories and source-backed definitions |
| CQ16 | Can a BOM path alone calculate required quantities? | No; E16 specifies quantities, but a path alone is reachability. Roll-up needs line quantities, units, version and arithmetic. | BOMLine and explicit calculation logic |

## Unresolved concepts and review queue

| ID | Issue | Status / next review |
| --- | --- | --- |
| U01 | `MRP` vs `Material Requirements Planning`; `MRP II` vs `Manufacturing Resource Planning` | T §3.1 explicitly supplies expansions; confirm sense per mention. Do not equate MRP with MRP II or expand unqualified MRP everywhere automatically. |
| U02 | `Production Order`, `Work Order`, `Job Order`, `Manufacturing Batch`, `traveler` | T §1 says names and lifecycle semantics vary. Determine system-specific meanings; do not merge on labels alone. |
| U03 | `Item`, `Material`, `Component`, `Product`, `Inventory Item`, `Raw Material` | Determine whether each is a type, role or lifecycle state, and their overlap in the user's data. |
| U04 | Detail vs standard part | P's descriptions are sourced but include an AI-error warning. Review exceptions, external standards and whether disjointness is intended. |
| U05 | `Supplier` and `Planner` | Organization/person vs role and role-assignment modeling need review; a supplier may play different roles in different contexts. |
| U06 | `Work Center`, equipment, labor and organizational areas | A work center groups resources in E03; review ISA-95 alignment and avoid equating a group with each machine or department. |
| U07 | BOM line quantity, units, version and effective period | Specify conversion, alternative components, revisions, yield, cycles and arithmetic before any explosion or planning claim. |
| U08 | Lead time, safety lead time, safety stock | Distinguish durations and inventory quantities, units, planned/actual values and item-location applicability. |
| U09 | Gross/net requirements and shortages | Source formula is simplified; determine time-phased netting, receipts, allocations, lot sizing, safety buffers and negative quantities in the target MRP system. |
| U10 | Operation ordering vs actual execution | Routing is a definition, not proof of an execution event; capture version, sequence and actual event separately. |
| U11 | KPI and period | A KPI definition, its observation, formula version, dimensions, and units are distinct; OEE inputs need validated data. |
| U12 | Page references and validation | Obtain an authoritative paginated rendering and independently review source claims and ontology design; no OWL reasoner, SHACL validator, or manufacturing SME has approved this notebook. |

## Next iteration

See the [OWL design notebook](./mrp-owl-design-notebook.md) for proposed
class hierarchies, modeling choices, axioms, and competency-question coverage.

Add reviewed evidence passages and independent mention records as the chapter
progresses. For every new proposed assertion record its evidence ID, modality,
time, classification and review status; keep ambiguous links unresolved.
After agreeing on boundaries, model the candidate schema in OWL and create
small test fixtures for the competency questions before loading operational
data. Validate consistency with a reasoner and data completeness separately
with SHACL; neither is implied by this notebook.
