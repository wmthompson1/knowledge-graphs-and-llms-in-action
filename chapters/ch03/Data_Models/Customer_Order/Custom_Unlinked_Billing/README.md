Additional Business Context

Review:
Documentation\Schema\Data_Models\Customer_Order\Custom_Unlinked_Billing\README.md
(or equivalent guide containing the "Custom and Unlinked" process documentation)

Domain Rules

1. Customer X billing is highly customized.
2. RAMAC is not a reliable business key and is only an approximation of an order identifier.
3. The migration objective is to join Customer X billing data to the core shipments/sales flow.
4. The required business grain is:

       Internal OrderID + Line Number

5. Every result row must represent a unique:
       Internal Order ID
       Line Number

6. Existing queries were developed independently and frequently group by Customer X specific fields such as RAMAC instead of enforcing the required order-line grain.

Required Investigation

A. Analyze Query B and determine its current grain.

B. Identify where duplicate rows can occur because the query groups by:
   - RAMAC
   - customer-specific identifiers
   - shipment attributes
   - billing attributes

instead of:

   InternalOrderID + LineNumber

C. Trace lineage for:
   - InternalOrderID
   - LineNumber
   - RAMAC

D. Recommend where InternalOrderID and LineNumber should be added to:
   - derived tables
   - CTEs
   - GROUP BY clauses
   - final result output

E. Evaluate whether the Msg 8114 conversion error is a symptom of:
   - mismatched UNION columns
   - incorrect join lineage
   - aggregation at the wrong grain
   - CASE / COALESCE / ISNULL type precedence issues

F. Produce a migration recommendation showing:
   Current Grain
   Proposed Grain
   Impact on row counts
   Impact on joins to shipments feed

Deliverables

1. Current Query B grain analysis.
2. InternalOrderID lineage.
3. LineNumber lineage.
4. RAMAC lineage.
5. Recommended join to core shipments feed.
6. Corrected Query B.
7. DDL for QueryB_Shape.
8. UNION compatibility report versus QueryA_Shape.
9. Identification of all locations where row enforcement must be changed to:
       InternalOrderID + LineNumber