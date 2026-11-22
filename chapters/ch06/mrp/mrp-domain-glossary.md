# MRP domain glossary — candidate definitions

This glossary covers all **45 candidate classes** in the
[OWL design notebook](./mrp-owl-design-notebook.md). It is a draft for domain
review, not an approved taxonomy. Definitions combine source descriptions
with explicitly proposed modeling interpretations; see the cited `E` records
in the [evidence layer](./mrp-ontology-notebook.md#layer-1--source-evidence-only)
and [source-context records](./mrp-source-evidence.json). Source page numbers
are unavailable; the evidence records identify Markdown lines.

Every example and counterexample below is **fictional**. A counterexample
illustrates a distinction, not an OWL disjointness claim; real classification
can depend on process, lifecycle, organization and system context. No actual
factory entities are asserted.

| Candidate class | Business definition / proposed scope | Evidence | Example | Counterexample / contrast |
| --- | --- | --- | --- | --- |
| `Item` | An identifiable thing managed in a product or material structure; item-definition versus physical-unit identity is unresolved. | E01, E16 | A cataloged assembly. | A BOM line describing usage of that assembly, not the item itself. |
| `RawMaterial` | Material used as an unprocessed input in a particular manufacturing context. | E01, E09 | Sheet stock used to fabricate a bracket. | A BOM document describing the sheet stock. |
| `DetailPart` | A component engineered to specifications for a particular assembly; source qualifications require review. | E32 | A bracket made from a custom drawing. | The drawing specifying the bracket. |
| `StandardPart` | A pre-manufactured, generally interchangeable component intended for broad use. | E33 | A catalog bolt conforming to a specified standard. | A purchase order for the bolt. |
| `Product` | A thing offered or produced; definition, variant and physical unit need separate identity decisions. | E01, E06, E08 | A particular cataloged pump model. | An authorization to make ten pumps. |
| `ManufacturingProcess` | A process transforming inputs into finished or intermediate outputs; type versus occurrence remains open. | E01 | A particular assembly process. | A list of components for the assembly. |
| `ProductionPlanning` | The activity of determining production items, quantities and schedules against demand and constraints. | E02 | A planning run balancing a forecast with available resources. | The resulting production order considered separately from the activity. |
| `CapacityPlanning` | The activity of determining capacity needed to meet demand, by resource and period. | E07 | A planning activity comparing machine-hour demand with capacity. | A work center's capacity value alone. |
| `RoughCutCapacityPlanning` | A high-level, pre-MRP check of a master schedule against key resource capacities. | E26 | A rough feasibility check of next month's schedule. | A detailed operation-by-operation load calculation. |
| `CapacityRequirementsPlanning` | A detailed calculation of capacity required by work center and period using orders and routings. | E27 | A run estimating next week's work-center load. | The master production schedule alone. |
| `ManufacturingResourcePlanning` | In this source, MRP II: planning beyond material requirements across broader resources. | E14 | A hypothetical MRP II planning run. | A single BOM line. |
| `MaterialRequirementsPlanning` | A calculation process using a production schedule, BOMs and inventory to determine time-phased component requirements. | E13 | A hypothetical material-planning run. | The resulting planned order, distinct from the run. |
| `ManufacturingResource` | A resource used in manufacturing, potentially a group, machine, tool or labor resource. | E03 | A machine used for a machining operation. | The operation definition assigned to that machine. |
| `WorkCenter` | A grouping of machines, tools or labor resources used for manufacturing operations. | E03, E05 | A machining cell with two machines. | One standalone BOM line. |
| `Routing` | A defined sequence of operations, work centers and time standards for making a product. | E04 | Revision A of an assembly routing. | A component list that omits the process sequence. |
| `Operation` | A defined step in a routing; an actual execution is a different occurrence. | E04, E05 | A drilling step definition. | A timestamped record that drilling was actually performed. |
| `BillOfMaterials` | A structured list of required components, subassemblies and raw materials with per-parent quantities and units. | E16 | A versioned BOM for a pump. | A routing describing assembly operations. |
| `BOMLine` | Proposed model for one component usage within a particular BOM, including its quantity and context. | E16; representation proposed | The line specifying two seals per pump in BOM revision A. | The seal item considered independently of its use in that BOM. |
| `ProductionOrder` | An authorization to manufacture a specified product quantity by a target date. | E06 | An authorization to build ten pumps by a given date. | An unreleased MRP recommendation. |
| `PurchaseOrder` | A purchasing order for goods or services; particular lifecycle rules are system-dependent. | E17, E19 | An issued order for twenty seals. | A not-yet-released suggestion to buy seals. |
| `CustomerOrder` | A customer-originated order that can be a demand source. | E25 | A customer's order for ten pumps. | A forecast of possible future pump sales. |
| `PlannedOrder` | An MRP recommendation to manufacture or purchase a quantity; it is not yet released. | E19 | A suggested order to buy twenty seals. | A supplier delivery that has actually occurred. |
| `FirmPlannedOrder` | A planned order reviewed and confirmed by a planner; status and timing require review. | E20 | A planner-confirmed recommendation for twenty seals. | An untouched planned recommendation awaiting review. |
| `MasterProductionSchedule` | A time-phased plan of end items, quantities and production periods. | E13, E15 | A schedule calling for ten pumps in a particular week. | A single receipt of seals. |
| `Forecast` | A projection of future demand; it is not automatically a confirmed customer order. | E02, E25 | An estimate that twenty pumps will be needed next month. | A confirmed customer purchase order. |
| `Demand` | A need for an item in a context and period; its boundary with requirements and demand sources remains open. | E07, E25; modeling proposed | A dated need for ten pumps. | A work center's available machine-hours. |
| `NetRequirement` | Uncovered component demand after considering on-hand inventory and scheduled receipts. | E17 | A calculated need for six more seals in a specified period. | The gross requirement before considering supply. |
| `ScheduledReceipt` | Expected incoming supply represented in planning; it is not necessarily a completed receipt. | E17 | Ten seals expected from an open order next week. | The physical receipt event after the seals arrive. |
| `InventoryPosition` | Proposed item-location-time context for inventory amounts and policies. | E11, E17; representation proposed | On-hand seals at a particular storeroom and time. | The global catalog definition of a seal alone. |
| `WorkInProcess` | Proposed time-dependent inventory state for partially manufactured goods. | E10 | A pump assembly started but not yet completed. | A time interval before manufacture has started. |
| `Supplier` | Proposed contextual role assignment under which an agent supplies an item. | E09, E30; role modeling proposed | A supplier role held by a vendor for seals during a contract period. | The seal itself; the vendor organization is the role holder, not the assignment. |
| `PlannerRole` | A contextual role assignment involving planning review or decisions. | E20; role modeling proposed | A person acting as planner for a planning cycle. | The planned order that the person reviews. |
| `DataArchitectRole` | A contextual governance role responsible for ontology design and alignment. | E31; role modeling proposed | A data architect's assignment to maintain the model. | The ontology file being maintained. |
| `PurchasingContract` | An agreement governing purchasing arrangements with a supplier; version and parties require context. | E30 | A one-year contract for a vendor's seals. | A single component item listed under the contract. |
| `SafetyStockPolicy` | Proposed policy for a quantity-based inventory buffer in a particular context. | E11, E12, E24 | A policy to maintain a buffer of five seals at a location. | A two-day safety lead-time buffer. |
| `SafetyLeadTimePolicy` | Proposed policy for an additional time-based supply buffer. | E24 | A policy adding two days to the planning lead time. | Five units of safety stock. |
| `LotSizingPolicy` | A rule used to determine a planned order quantity. | E23 | A lot-for-lot ordering policy. | A single planned order generated using that policy. |
| `LeadTime` | The duration between ordering and availability, or a contextual component of that duration. | E22, E24 | A planned supplier delivery duration of five days. | A stock quantity of five units. |
| `CapacityMeasure` | A proposed quantity of capacity for a resource and period, with available and required meanings distinguished. | E07, E27 | Forty available machine-hours for a work center this week. | A routing document alone. |
| `CapacityConstraint` | A condition limiting feasible production capacity; its rule and measurement model remain open. | E02, E07 | A limit of forty machine-hours in a particular week. | A machine-hour measurement without an associated limit. |
| `TimeBucket` | A planning period over which requirements and orders are aggregated. | E21 | The planning week beginning on a specified date. | The quantity planned within that week. |
| `PeggingLink` | A proposed record linking a requirement to its originating demand context. | E25; link representation proposed | A trace from a seal requirement to a particular customer order. | An unqualified list of all suppliers. |
| `KPIObservation` | A measured KPI value for a defined entity, period and calculation context. | E28; observation representation proposed | An OEE value for a particular machine and week. | The general OEE formula without a measured value. |
| `ReasoningTool` | A tool capable of checking or deriving consequences of formal ontology axioms. | E35 | An ontology reasoner used in a hypothetical validation run. | A source paragraph about a work center. |
| `RelationshipAssertion` | A proposed record of a source-backed, candidate or inferred relationship and its provenance/status. | E34; assertion model proposed | A record citing a passage for a proposed mention-to-mention relation. | The source passage itself. |

## Acquisition-layer terms

| Candidate class | Business definition / proposed scope | Evidence | Example | Counterexample / contrast |
| --- | --- | --- | --- | --- |
| `SourceDocument` | A particular source document version used for acquisition. | E34; provenance design proposed | The primary terminology document at a recorded hash. | One sentence extracted from that document. |
| `SourcePassage` | A located passage in a particular document version. | E34; provenance design proposed | A recorded paragraph and line location. | A resolved manufacturing entity. |
| `Mention` | One occurrence of wording in a source passage, before entity resolution. | E34; provenance design proposed | One occurrence of “Work Center” in a paragraph. | A canonical work-center individual to which it might later refer. |

## Review reminders

- The parts source warns that AI-generated text can contain errors. Examples
  and definitions need SME review before use as authoritative vocabulary.
- A supplier is modeled here as a role assignment, which is a proposal; the
  source also uses supplier to denote an organization. Identity and temporal
  scope remain unresolved.
- No counterexample declares classes disjoint. A product can be an input in
  another process, and part categories can be context-dependent.
- Operational identifiers, real suppliers and real BOM instances are absent
  from this glossary. No graph has been populated.
