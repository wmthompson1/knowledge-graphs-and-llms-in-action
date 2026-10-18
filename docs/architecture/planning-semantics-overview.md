# Planning Semantics Overview

This document describes the planning semantics used in the manufacturing ontology for planned order receipts, demand fences, and MRP exception eligibility.

## Core intent

The ontology is descriptive, not prescriptive. A planned order receipt inside the demand fence is not automatically treated as a firm order, and the semantic layer does not assert that an exception message must be generated. Instead, the model records the conditions under which MRP may act.

## Key concepts

- PlannedOrderReceipt: a near-term, planning-level receipt candidate.
- DemandFence: a temporal boundary that marks near-term demand.
- LeadTimeOffset: a simple planning offset used to determine whether a receipt falls inside the fence.
- MRPExceptionMessage: a semantic class representing a possible exception recommendation.
- RescheduleOutSuggestion: a typed exception message indicating the order may be suggested for rescheduling out.

## Semantic behavior

If a planned order receipt is inside the demand fence, the ontology indicates:

- `isInsideDemandFence = true`
- `isFirm = false` (for the planning record)
- `eligibleForExceptionMessage = RescheduleOutSuggestion`
- `releaseDateMayBeAdjustedByMRP = true`

The operational system (for example, Visual MRP) decides whether a message is actually generated and whether the planned order release date is changed.

## Why this matters

This distinction keeps the ontology clean and OWL-friendly. It avoids prescriptive assertions in the semantic layer while still capturing the eligibility conditions that downstream planning logic needs.
