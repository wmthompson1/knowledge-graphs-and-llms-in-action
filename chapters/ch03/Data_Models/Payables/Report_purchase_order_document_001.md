 # KB1939621

 ## What does the REFERENCE_TYPE in the DOCUMENT table represent?

 Article Information
________________________________________________________________________________________________________________


Description :

What does the REFERENCE_TYPE in the DOCUMENT table represent?


Resolution :
0              API
2              ARI
C              Customer
N              Purchase Contract
Z              Eng Change Notice
Y              Estimating Window
G              General
4              General Journal
O              Operation
R              Purchase Order
P              Part
E              Purchase Requisition
H              Shop Resources
Q              Request for Quote
U              RMA
S              Shipper
A              Trace
V              Vendor
F              Work Flow
W             Work Order

## SQL TO join purchase order to document table

`PURCHASE_ORDER`, `PURC_ORDER_LINE`, and `PART` do not contain a
`DOCUMENT_ID` column. Use `DOCUMENT_REFERENCE` as the bridge between the
referenced entity and `DOCUMENT`.

### Documents attached to parts on purchase-order lines

This is the appropriate path when the query includes `PURC_ORDER_LINE` and
`PART`. `DOCUMENT_REFERENCE.SOURCE_TYPE = 'P'` identifies a part reference.

```sql
SELECT
    PO.ID AS PURCHASE_ORDER_ID,
    POL.LINE_NO,
    P.ID AS PART_ID,
    D.ID AS DOCUMENT_ID,
    D.CATEGORY_ID,
    D.DESCRIPTION,
    D.DOC_FILE_PATH
FROM Live.dbo.PURCHASE_ORDER AS PO
LEFT JOIN Live.dbo.PURC_ORDER_LINE AS POL
    ON POL.PURC_ORDER_ID = PO.ID
LEFT JOIN Live.dbo.PART AS P
    ON P.ID = POL.PART_ID
LEFT JOIN Live.dbo.DOCUMENT_REFERENCE AS DR
    ON DR.ID = P.ID
   AND DR.SOURCE_TYPE = N'P'
LEFT JOIN Live.dbo.DOCUMENT AS D
    ON D.ID = DR.DOCUMENT_ID
   AND D.SITE_ID = PO.SITE_ID;
```

Keep the `SOURCE_TYPE` predicate in the `DOCUMENT_REFERENCE` join and the site
predicate in the `DOCUMENT` join. Placing either predicate in a `WHERE` clause
would remove purchase-order lines that have no document and effectively turn
that part of the query into an inner join.

This relationship is one-to-many: a part can have multiple document
references, so a purchase-order line can return multiple rows.

### Documents attached directly to a purchase-order header

For PO-header documents, lines and parts are not part of the relationship.
`DOCUMENT_REFERENCE.SOURCE_TYPE = 'R'` identifies the purchase-order reference:

```sql
SELECT
    PO.ID AS PURCHASE_ORDER_ID,
    D.ID AS DOCUMENT_ID,
    D.CATEGORY_ID,
    D.DESCRIPTION,
    D.DOC_FILE_PATH
FROM Live.dbo.PURCHASE_ORDER AS PO
LEFT JOIN Live.dbo.DOCUMENT_REFERENCE AS DR
    ON DR.ID = PO.ID
   AND DR.SOURCE_TYPE = N'R'
LEFT JOIN Live.dbo.DOCUMENT AS D
    ON D.ID = DR.DOCUMENT_ID
   AND D.SITE_ID = PO.SITE_ID;
```

Do not use `D.ID = PO.ID`. `DOCUMENT.ID` identifies the document itself;
`DOCUMENT_REFERENCE.ID` identifies the entity to which the document is
attached.

## Validation

Validated against the local manufacturing metadata catalog and read-only
`Live` schema/data:

- `Live.dbo.PURC_ORDER_LINE.PURC_ORDER_ID` joins to
  `Live.dbo.PURCHASE_ORDER.ID`.
- `Live.dbo.PURC_ORDER_LINE.PART_ID` joins to `Live.dbo.PART.ID`.
- `Live.dbo.DOCUMENT_REFERENCE` contains `ID`, `DOCUMENT_ID`, and
  `SOURCE_TYPE`.
- `Live.dbo.DOCUMENT_REFERENCE.DOCUMENT_ID` joins to
  `Live.dbo.DOCUMENT.ID`.
- The part-document path returned 9,669 live matches; applying
  `D.SITE_ID = PO.SITE_ID` preserved all 9,669.