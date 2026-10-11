# Manufacturing Demand Guide

## Page 1. Purpose and scope

This guide explains manufacturing demand as it appears in the Customer_Order documentation set. The focus is not on abstract planning theory alone, but on how demand is represented in customer orders, how it is transformed into supply signals, and how the reporting layer uses those signals to support contract personnel, planners, and shop-floor decision makers.

In this folder, demand is not a single table or a single number. It is a workflow that begins with a customer order, flows through demand-supply links, interacts with work orders, and then appears again in ATP, shipping, and promise-date logic. The most useful way to read the documents is to treat them as a connected model: customer order entry defines the demand, work-order linkage defines the supply response, and reporting documents explain how that relationship is summarized for users.

The guide is organized as a practical tour of the folder contents. It starts with the ATP definition, then moves into customer order master logic, demand and supply linking, shipping behavior, and the analysis questions that the documentation is already asking. By the end, you should be able to trace a line from a customer commitment to its manufacturing response.

---

## Page 2. What manufacturing demand means here

In this folder, manufacturing demand means the quantity and timing pressure created by customer orders that must be satisfied through inventory, allocation, or production. The demand is visible in fields such as desired ship date, promised ship date, quantity due, open quantity, and WODS-derived work-order dates. It becomes operational when the system determines whether the order is already covered by stock or whether it needs a work order or other supply signal.

The customer-order model is important because it shows that demand is not static. A line can start as a customer commitment, then move into an ATP check, then be reconciled against inventory and work-order status, and finally be reflected in shipping or promised-release logic. This is why the documentation repeatedly combines customer order tables with part, work-order, and demand-supply data.

A practical manufacturing demand guide should therefore answer three questions. What does the customer want, when do they want it, and what manufacturing or inventory source will satisfy it? The documents in this folder answer those questions through SQL and narrative explanations rather than a formal data dictionary alone.

---

## Page 3. Core documents in the folder

Several files define the demand story in this folder. [Customer Order Master.sql](Customer%20Order%20Master.sql) describes the main reporting procedure that combines customer order lines with WODS data and stock availability. [ATP - available to promise.md](ATP%20-%20available%20to%20promise/ATP%20-%20available%20to%20promise.md) defines ATP and allocated inventory in practical manufacturing terms. [Demand and Supply 1 explained.md](Demand%20and%20Supply%201%20explained.md) explains how demand-supply linkage works in the SQL patterns used throughout the folder.

The shipping documents add another layer. [KB1.md](Shipping/KB1.md) explains quantity naming differences such as shipped quantity versus stock shipped quantity and order quantity versus stock order quantity. [KB2.md](Shipping/KB2.md) explains why promised ship date can drive MRP release-date behavior. Together, these documents show that customer demand is not just an order line; it is a quantity, a date, a stock conversion, and a planning signal.

There are also question-based documents such as [Questions on CO Master.md](3%20questions/Questions%20on%20CO%20Master.md). Those questions are useful because they reveal what the folder is trying to help users investigate: missed ship dates, ATP mismatches, shortage exposure, weak WODS linkage, and promise-date consistency. A good guide should reflect those concerns rather than ignore them.

---

## Page 4. ATP and allocation

The ATP document defines the most basic planning relationship in the folder. Quantity On Hand is the total physical stock available. Allocated is the portion reserved for specific confirmed orders or jobs. ATP is the free balance that can be promised to new demand, expressed as $ATP = \text{Quantity On Hand} - \text{Allocated}$.

That definition matters because allocated inventory is not available for other jobs even if it still sits on the shelf. In an MTO environment, allocation is how the system protects customer commitments from being stolen by later orders. The folder’s ATP explanation emphasizes that this is a planning and prioritization mechanism, not just an inventory balance.

The practical consequence is that ATP is a bridge between customer demand and manufacturing feasibility. If ATP is positive, the order may be immediately supportable from stock. If ATP is low or negative, the order pushes the organization toward planned supply, work orders, or schedule changes. That is why ATP, open quantity, and allocated stock appear repeatedly in the customer-order reports.

---

## Page 5. Customer order master logic

[Customer Order Master.sql](Customer%20Order%20Master.sql) is the main operational anchor in the folder. It builds a report procedure that refreshes WODS data, creates temporary tables, and combines customer order lines with part availability and work-order signals. The script is intentionally written to support contract personnel who need a single view of order status, due dates, and manufacturing response.

The key idea in the procedure is that open customer-order lines are not evaluated in isolation. They are grouped with part availability, then augmented with a running total of open quantity, then joined to WODS-derived fields such as production status and work-order due date. This means the report is simultaneously a demand report, an allocation report, and a status report.

One important design choice in the procedure is its use of separate date concepts. Desired ship date, promised ship date, WO due date, and WODS desired want date are not treated as interchangeable. The report logic uses them to compare customer commitment against manufacturing reality. That makes the procedure a core reference for anyone trying to understand manufacturing demand in this folder.

---

## Page 6. Open quantity and running totals

The report logic computes open quantity as the remaining amount after shipped quantity has been accounted for. This is important because demand is not just what was ordered; it is what remains unfulfilled. The same report then computes a running total of demand by part and desired ship date, which helps planners see cumulative pressure rather than only line-by-line details.

This running total is a useful way to read demand from a manufacturing perspective. A single customer line may look manageable, but a sequence of lines on the same part can quickly expose a shortage or a backlog risk. The running total shows whether the system is gradually consuming available stock or whether demand is outpacing it.

The presence of part-level planning user filters in the procedure also suggests that demand is not intended to be universally flat. The reporting logic is tuned toward the manufacturing planning group and other user categories that manage production and material flow. In other words, the report is designed to answer operational demand questions, not just accounting questions.

---

## Page 7. Demand and supply linkage

[Demand and Supply 1 explained.md](Demand%20and%20Supply%201%20explained.md) is one of the most important conceptual references in the folder. It explains a common SQL pattern where demand-supply data is joined to work-order data before being merged into the customer order result set. The explanatory note makes clear that the structure is not arbitrary; it is a deliberate way to filter and enrich records before the final customer order join.

The linked SQL pattern uses `DEMAND_SUPPLY_LINK` as the core bridge between supply and demand. It maps a customer order line to a supply record and then joins supply to work order. That structure is helpful because it preserves the demand line while also showing whether a related supply record exists and how it should be interpreted.

This is the heart of manufacturing demand in the folder. Demand does not simply mean a customer asked for something. It means the customer order line can be paired to supply records, work orders, or stock states in a way that tells planners what can be fulfilled now, what needs to be produced, and what still needs explanation.

---

## Page 8. Work orders as the manufacturing response

Work orders appear throughout the customer-order folder as the response to demand. In the SQL examples, work orders are used to identify due dates, allocation alignment, production status, and whether a customer order line has a corresponding manufacturing task. The relationship is particularly visible when a customer order is not in stock and the report must fall back to WODS fields.

The important thing about work orders in this context is that they are not just downstream records. They are part of the demand story because they often determine whether the customer order can actually be fulfilled. If a line is tied to a work order, the order is no longer just a promise; it has become a manufacturing commitment.

This folder also shows that the work-order link is nuanced. Some queries join only on base, lot, and split identifiers. Others include sub identifiers or additional filters to match subordinate work-order behavior. That makes it important to read each document carefully before assuming that every work-order join means the same thing.

---

## Page 9. Shipping and fulfillment quantities

The shipping documents explain how quantities change meaning depending on units of measure. [KB1.md](Shipping/KB1.md) shows the difference between shipped quantity and stock shipped quantity, and between order quantity and stock order quantity. The practical rule is that user-facing quantities may reflect a conversion unit, while stock quantities reflect the stocking unit of measure.

This distinction is critical for demand analysis. A customer order line can look small in user units while representing a larger or smaller stock impact. If you ignore unit conversion, you can misread ATP, shipped quantities, and open balances. The folder’s shipping documentation exists largely to prevent that mistake.

The shipping narrative also reinforces that demand is not complete until the customer order is reconciled with actual shipment. A line that is ordered but not shipped still contributes to demand pressure. A line that ships in user units and stock units differently can distort both operational and financial reporting if the conversion is not understood.

---

## Page 10. Promise ship date and release-date behavior

[KB2.md](Shipping/KB2.md) explains a planning choice that directly affects manufacturing demand: whether MRP uses promised ship date or desired ship date as the release date. That choice is controlled by the `MRPByReleaseDate` preference. If the preference is on, the promise ship date drives demand timing; if it is off, the desired ship date remains the netting basis.

This matters because the same customer order can generate different planning behavior depending on the preference. A line with an aggressive promised ship date may pull supply earlier than the desired date would. That shifts the load on inventory, production, and work-order release.

For a manufacturing demand guide, this means date logic is not a minor detail. Promise-date policy can change which lines appear urgent, how much time is available to produce, and whether the planner sees a more conservative or more aggressive demand picture. The folder’s documentation shows that this is a global planning setting, not a line-by-line exception.

---

## Page 11. Status, variance, and risk

The question set in [Questions on CO Master.md](3%20questions/Questions%20on%20CO%20Master.md) shows how the folder expects demand to be analyzed. It asks about open lines at risk of missing ship date, disagreements between in-stock status and projected inventory, shortage exposure, weak WODS matching, and promise-date behavior by customer group.

Those questions reveal the operational risk model behind the reports. Demand is not just measured by quantity; it is measured by variance. If a line has large due variance or work-order variance, it is more likely to create customer dissatisfaction or schedule pressure. If ATP says one thing and projected on-hand says another, the planner has to decide which signal is more trustworthy.

A good manufacturing demand guide should therefore encourage variance-based reading. The value is not only in knowing that demand exists, but also in understanding where the plan is fragile. That fragility shows up in late orders, weak work-order matches, and mismatches between expected stock and actual available issue quantity.

---

## Page 12. How to read the folder as a process map

The most useful mental model for the folder is a process map. Start with customer order entry. Move to ATP and allocation. Then inspect demand-supply links, work-order status, and WODS fields. Finally, interpret shipping quantities and promise-date logic. Each document contributes a different part of that same flow.

If you read the folder this way, the documents stop looking like separate notes and start behaving like layered evidence. The ATP note explains inventory availability. The demand-supply explanation shows the relational bridge. The master SQL shows the actual report implementation. The shipping KBs show how quantities and dates should be interpreted. The question file tells you what to investigate next.

That process-map view also helps when comparing individual customer order lines. A line with positive ATP may still be risky if its promise date is earlier than the production response. A line with a valid work order may still be fragile if the quantity conversion or shipping logic is unclear. The folder is designed to surface those tensions.

---

## Page 13. Practical review checklist

When reviewing a customer-order demand scenario, start with the dates. Check desired ship date, promised ship date, and WO due date. Then check the quantities: order quantity, shipped quantity, open quantity, ATP, and projected on-hand. Finally, check the linkage: is there a valid demand-supply record, a work order, and a meaningful WODS production status?

Next, ask whether the line is in stock or not. If it is in stock, confirm whether the stock is truly available or already allocated. If it is not in stock, confirm whether the report’s WODS fields are providing a sensible manufacturing recovery path. That is the fastest way to tell whether the demand is simply recorded or actually actionable.

Finally, compare the customer order to the ship method and unit-of-measure context. The shipping KBs show that quantity interpretation depends on the measure being used. If the user-facing quantity and the stock quantity diverge, the demand analysis should note that before making any planning decision.

---

## Page 14. Common failure patterns

The folder documents a few failure patterns that matter in manufacturing demand analysis. One is false confidence from ATP alone. Positive ATP does not guarantee the line is safe if work-order timing, promise date behavior, or conversion units make the demand tighter than it first appears.

Another failure pattern is weak or misleading joins. If demand-supply linkage does not map cleanly to the right work order or if the WODS signal is generic, the report may show status without explaining the real manufacturing constraint. That is why the folder includes explanation docs alongside the SQL.

A third failure pattern is date confusion. Desired ship date, promised ship date, release date, and WODS desired want date can all represent different planning intents. If a reviewer treats them as interchangeable, the resulting demand analysis can be wrong even if the SQL is technically correct.

---

## Page 15. Summary and usage guidance

The Customer_Order folder presents manufacturing demand as a connected planning system. Demand begins with customer commitments, is moderated by ATP and allocation, is translated into work-order and WODS signals, and is finally summarized through shipping and quantity conversion rules. The folder’s SQL and narrative docs together explain how that system behaves.

If you are using this folder as a reference, treat it as a decision-support package rather than a single report. Use [Customer Order Master.sql](Customer%20Order%20Master.sql) for report behavior, [ATP - available to promise.md](ATP%20-%20available%20to%20promise/ATP%20-%20available%20to%20promise.md) for availability logic, [Demand and Supply 1 explained.md](Demand%20and%20Supply%201%20explained.md) for relational structure, and the shipping KBs for quantity and release-date interpretation.

The best next step is to use this guide as the framing document for any deeper analysis of open orders, shortages, or promise-date policy. The folder already contains the clues; the guide simply organizes them into a manufacturing demand story that planners and analysts can apply consistently.

---

## Appendix. Key terms

- ATP: Available to Promise, the portion of stock not allocated to existing demand.
- Allocated: Inventory reserved for specific orders or jobs.
- Demand-supply link: The relational bridge between customer demand and supply records.
- WODS: Work-order daily status information used to enrich customer-order reporting.
- Promise ship date: The date the system may use for MRP release timing when the preference is enabled.
- Desired ship date: The customer-requested target date, often used as the default planning date.
- Open quantity: The remaining quantity still not shipped.
- Running total due: A cumulative view of demand by part and date.
- Stock quantity: Quantity measured in the stocking unit of measure.
- User quantity: Quantity measured in the customer-facing conversion unit.
