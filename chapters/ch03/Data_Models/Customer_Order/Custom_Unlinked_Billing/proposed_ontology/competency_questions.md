# Competency Questions

## Purpose

These questions define what the proposed ontology must answer. They are inferred
from the billing query family and from enterprise needs for auditability,
repeatability, margin analysis, and prevention of duplicate billing.

## A. Billing scope and eligibility

### CQ-01
Which shipped customer-order lines are eligible for a given custom billing
program during an invoice-date period?

**Required evidence:** customer, invoice date, positive shipped quantity,
billing program, and applicable inclusion rules.

### CQ-02
Why was a part included in or excluded from a billing program?

**Required evidence:** rule identifier, rule type, configured report/program,
part, resource classification, effective period, and decision result.

### CQ-03
Which explicit exception overrides a general rework or resource exclusion?

**Required evidence:** exception rule, overridden rule, affected part or work
order, reason, and effective period.

### CQ-04
Which billing lines were generated from rework work orders or rework parts, and
were they authorized by an exception?

**Required evidence:** work-order and part classification plus the rule chain
that produced the eligibility decision.

## B. Calculation method and rates

### CQ-05
Was a billing line calculated from actual labor hours, fixed standard hours,
minimum-lot pricing, expedite pricing, service-cost conversion, or a hybrid?

**Required evidence:** billing method and the policy/rate schedule used.

### CQ-06
Which rate schedule and effective rate produced the unit price and extended
amount?

**Required evidence:** rate type, amount, currency, effective dates, billing
program, and calculation timestamp.

### CQ-07
How were setup hours, run hours, expedite hours, special fees, and service fees
derived?

**Required evidence:** labor entries or fixed-hour standards, service cost,
formula type, and result values.

### CQ-08
Which billing lines were raised to a minimum charge, and what would their
unadjusted amount have been?

**Required evidence:** minimum-charge rule, calculated amount before adjustment,
minimum amount, and final extended amount.

### CQ-09
For fixed-hour parts, which part-specific setup and run standards were used and
which shipped quantity scaled the run hours?

**Required evidence:** fixed-hour standard, part, setup hours, run hours per
unit, billed quantity, effective period, and resulting billable hours.

## C. Traceability and provenance

### CQ-10
Which source shipment, invoice, customer-order line, work order, labor entries,
resources, and service costs support a billing line?

**Required evidence:** an unbroken provenance path from billing result to every
source fact used in its calculation.

### CQ-11
Which stored procedure or billing program generated a billing line, and when?

**Required evidence:** billing run, program identifier, date parameters, and
generation timestamp.

### CQ-12
Can every monetary result be reproduced from preserved source values, policy
versions, and calculation methods?

**Required evidence:** source facts, rate schedule, rule versions, calculation
method, and pre-adjustment values.

## D. Granularity and duplicate-billing controls

### CQ-13
What is the declared grain of each source fact and each billing output row?

**Required evidence:** grain declaration and the keys that identify one fact at
that grain.

### CQ-14
Does one work order support more than one shipment or invoice billing line in
the same billing population?

**Enterprise need:** detect possible repetition of work-order labor across
split shipments.

### CQ-15
Has the same labor entry contributed to more than one billing line?

**Enterprise need:** identify direct double-use of labor evidence, independently
of whether duplicate monetary amounts happen to match.

### CQ-16
Does `TOTAL_SHIPPED_QTY` represent the current shipper-line quantity, a
customer-order-line cumulative quantity, or another quantity basis?

**Enterprise need:** prevent unit-price distortion caused by mixing quantity
facts at different grains.

### CQ-17
Which billing lines combine a shipment-level trigger with work-order-level
labor, and what allocation method reconciles those grains?

**Required evidence:** shipment grain, labor grain, allocation method, and
allocation factor. An absent allocation method is a control exception.

## E. Financial and operational controls

### CQ-18
Which billing lines have zero or negative billed quantity, null rates, or a
unit-price/extended-amount inconsistency?

### CQ-19
Which service-bearing work orders generated a special fee or converted service
hours, and which did not?

### CQ-20
How do charges and hours differ by billing category (`ASSY`, `5AXIS`, `EME`,
`FINISH`, `MFG`), part, invoice, and period?

### CQ-21
Which local source-field codes have not yet been translated into governed
business concepts?

**Examples:** `SHOP_RESOURCE_SITE.USER_1`, `USER_9`, `USER_10`, `RAMAC`, and
`SERVICE_CHARGE_ID`.

## Minimum acceptance criteria

The proposal is adequate when:

1. Every competency question maps to at least one class/property pattern.
2. Billing policy is modeled separately from billing evidence and result.
3. Output grain and source grain are explicit, not only documented in prose.
4. A labor entry can be traced to every billing line that consumed it.
5. Effective-dated rates and rules allow historical reproduction.
6. Exceptions identify the rule they override.
7. Unknown local codes remain explicit mappings-to-be-governed rather than
   being assigned unsupported enterprise meanings.
