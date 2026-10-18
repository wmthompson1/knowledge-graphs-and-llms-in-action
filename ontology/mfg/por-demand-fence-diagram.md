# POR → eligibility → MRP exception table

This diagram models the descriptive semantics: a PlannedOrderReceipt inside the demand fence is not treated as a firm order, but is eligible for exception reasoning. The operational MRP engine decides whether to generate a message and whether to adjust the release date.

```mermaid
flowchart LR
    A[PlannedOrderReceipt\nPOR_123] --> B{Inside demand fence?}
    B -- Yes --> C[isFirm = false]
    C --> D[eligibleForExceptionMessage\nRescheduleOutSuggestion]
    D --> E[MRPExceptionTable]
    B -- No --> F[Normal planned-order behavior]

    G[DemandFence\nleadTime window] --> B
    H[PlannedOrderRelease\nreleaseDate] --> E
    I[releaseDateMayBeAdjustedByMRP\ntrue/false] --> H

    classDef por fill:#e8f1ff,stroke:#4d79ff,color:#111;
    classDef flag fill:#eefaf3,stroke:#3aa76d,color:#111;
    classDef table fill:#fff3db,stroke:#d99a00,color:#111;

    class A,C,D,H,I por;
    class B,F,G flag;
    class E table;
```

## Semantics

- `PlannedOrderReceipt` can be inside a `DemandFence` without being firm.
- If inside the demand fence, it is eligible for a `RescheduleOutSuggestion` via `eligibleForExceptionMessage`.
- The `MRPExceptionTable` is the operational tracking surface; the ontology only describes eligibility, not mandatory generation.
- `releaseDateMayBeAdjustedByMRP` indicates mutability without enforcing a change.
