# MRP competency-question catalog

The 22 questions from the [acquisition notebook](./mrp-ontology-notebook.md#competency-questions)
and [OWL design notebook](./mrp-owl-design-notebook.md#additional-competency-questions-for-uncovered-design-decisions)
are grouped by primary business concern. Some questions span groups. Evidence
IDs refer to the [source evidence](./mrp-source-evidence.json); its page
numbers are unknown, with source lines and context provided instead.

**Partial** means the [minimal draft vocabulary](./mrp-minimal-owl-profile.md)
contains some useful terms; it does not mean a query has been implemented or
can answer the question. **Gap** means essential concepts or logic are absent.
The documents provide definitions and examples, not current factory data.
“Not established” is therefore a correct answer for instance-specific
questions until reviewed data exists.

## Planning

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ05 | What inputs does the document identify for MRP? | The source describes a master production schedule, BOMs and current inventory; E13. | Partial: input properties exist; source claim-to-model mapping still needs review. |
| CQ09 | Which demand source is associated with a requirement? | Pegging traces requirements to an original source, typically a customer order or forecast; no concrete link is given. E25. | Gap: pegging, demand-source types and specific records are absent. |
| CQ12 | How do RCCP and CRP differ in scope? | RCCP is a high-level pre-MRP check; CRP computes detailed capacity by work center and period; E26–E27. | Gap: capacity methods and measures are excluded. |
| CQ16 | Can a BOM path alone calculate required quantities? | No; a path establishes reachability, not arithmetic, unit conversion or time-phased MRP; E16 supplies quantity context. | Partial: BOM lines and quantities exist; roll-up, versions, units and planning rules require implementation. |
| CQ19 | Which planning method, inputs, forecast and lead-time assumptions were used in a particular run? | Not established for a real run. E13–E14 and E22 describe concepts. | Partial: some MRP input links exist; forecasts, lead times and assumption/version records are absent. |

## Inventory

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ06 | How are net requirements characterized? | Uncovered component demand after considering on-hand inventory and scheduled receipts; E17. | Partial: inventory and net-requirement classes exist; receipts, periods and netting logic are missing. |
| CQ10 | What inventory shortages affect production or a customer order? | Not established; actual inventory, dated requirements and pegging are absent. E17, E25. | Gap: inventory context, availability, demand, pegging and calculation rules are needed. |
| CQ14 | What is the difference between safety stock and safety lead time? | The source distinguishes quantity-based and time-based buffers; E24. | Gap: policy and duration concepts are excluded. |
| CQ20 | When was a particular item or lot work in process? | Not established for an actual item or lot; E10 provides a general definition. | Gap: item/lot state assignments and intervals are excluded. |

## Supply

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ04 | Which suppliers provide a particular component? | Not established for an actual component; E30 describes a supplier-material model pattern. | Partial: supplier role and relation exist; reviewed supply facts, agent and time context are needed. |
| CQ07 | Does a planned order prove a purchase has been placed? | No: E19 describes planned orders as not yet released. | Partial: planned order is separate; actual purchase orders, release events and status history are absent. Missing evidence alone is not proof of non-release. |
| CQ08 | What distinguishes a firm planned order? | A planner has reviewed and confirmed it; E20. | Gap: firm status, review event and planner assignment are excluded. |

## Routing

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ03 | Which work centers perform a particular operation? | Not established for an actual operation; E05 says an operation specifies a work center. | Partial: operation and work-center terms exist; definition vs dated execution/assignment remains unresolved. |
| CQ11 | What dependencies exist between operations? | E04 describes a sequence; no specific operation dependency instances are supplied. | Partial: direct-next relation exists; routing-specific sequencing, branching and revision are missing. |

## Production

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ01 | What information does a BOM specify about components? | Components, subassemblies and raw materials with per-parent quantities and units; E16. | Partial: BOM line, item, unit and quantity terms exist; fixture, source mapping and validation are needed. |
| CQ02 | What materials are required for a particular product? | Not established for a real product; no actual product BOM selected. E16 describes the structure. | Partial: product/BOM/line terms exist; effective version, unit conversion and quantity roll-up are missing. |
| CQ13 | What are the three factors of OEE? | Availability, Performance and Quality; E28. | Gap: metric definition and observation concepts are excluded. |
| CQ15 | How are detail and standard parts described? | Custom-engineered for a unique assembly versus pre-manufactured and interchangeable; E32–E33; review source caveat. | Gap: both classifications are deferred; they are not asserted disjoint. |
| CQ18 | Which resources and processes were actually used for an order? | Not established for an actual order; E01, E03 and E06 are generic. | Gap: execution, resource assignments and events are distinct from routing definitions and are excluded. |

## Governance

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ17 | Who held the supplier, planner or data-architect role, in what context and period? | No actual assignments are identified; E20, E30–E31 describe roles. | Partial: supplier role and `heldBy` exist; planner/architect roles, agent typing and contextual intervals are missing. |
| CQ21 | Which reasoner checked which ontology version, and with what result? | E35 instructs validation; it does not establish a validation run. | Gap: validation activity, ontology version, tool and result are excluded. |

## Provenance

| ID | Competency question | Expected answer / source status | Draft coverage and missing work |
| --- | --- | --- | --- |
| CQ22 | Which source passage and mention support a proposed or reviewed assertion? | The acquisition records associate selected mentions and statements with evidence, but review and canonical resolution are pending. E34 and evidence records. | Partial: passage, mention, assertion and support links exist; reviewed resolution, source version, evidence completeness and status rules require data and validation. |

## Evaluation approach

For each question, create a small synthetic fixture and a query after the
design is approved. Record the expected answer **and** expected unknowns;
check both positive and missing-evidence cases. Separately test citations,
temporal/version boundaries, role context, and whether a suggestion is being
mistaken for an executed order. An OWL reasoner, SPARQL query and SHACL
validator perform different jobs; none substitutes for the others or an SME
review.
