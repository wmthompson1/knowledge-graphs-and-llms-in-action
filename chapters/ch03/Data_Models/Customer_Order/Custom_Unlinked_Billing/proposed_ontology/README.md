# Proposed Custom and Unlinked Billing Ontology

## Status and boundary

This folder is an isolated proposal for the custom and unlinked billing domain.
It does not import, amend, or depend on the existing knowledge-loop ontologies.
Its namespace is:

`https://skills.inc/mrp/custom-unlinked-billing#`

The proposal is grounded in the SQL and documentation in the parent folder,
including the ASSY, 5AXIS, EME, FINISH, and MFG billing queries. It is intended
for review before any integration with a broader enterprise ontology.

## Design approach

The model begins with [competency_questions.md](competency_questions.md). Those
questions express inferred enterprise needs before prescribing classes or
properties. The ontology then separates:

1. **Commercial facts**: customer orders, order lines, shipments, invoices.
2. **Manufacturing evidence**: work orders, labor entries, resources, services.
3. **Billing policy**: rate schedules, calculation methods, eligibility rules,
   exclusions, exceptions, and effective periods.
4. **Billing results**: billing runs and billing lines with explicit monetary,
   quantity, hour, provenance, and grain semantics.

This separation prevents a calculated billing row from being mistaken for a
source transaction and preserves the distinction between evidence, policy, and
the resulting charge.

## Artifacts

- [competency_questions.md](competency_questions.md): business questions and
  acceptance criteria.
- [custom_unlinked_billing.ttl](custom_unlinked_billing.ttl): proposed OWL/RDF
  vocabulary and representative instances.
- [mapping_and_grain.md](mapping_and_grain.md): source mappings, calculation
  semantics, identity rules, and grain specifications.
- [validation_queries.sparql](validation_queries.sparql): SPARQL checks that
  demonstrate coverage and identify compliance risks.

## Non-goals

- This proposal does not claim that local fields such as `USER_1`, `USER_9`,
  `USER_10`, or `RAMAC` are enterprise-standard terms.
- It does not replace the source SQL procedures.
- It does not infer that a work order maps one-to-one to a shipment. That
  relationship is treated as a testable condition because split shipments can
  duplicate labor evidence across billing lines.
- It does not import ISA-95, IOF, BFO, or the existing engineering-master
  ontology. Alignment may be added later as a separate reviewed module.

## Review sequence

1. Approve or revise the competency questions.
2. Confirm source-key and grain assumptions in the mapping document.
3. Validate the ontology with the supplied SPARQL checks.
4. Decide whether to add optional external alignments in a separate module.

