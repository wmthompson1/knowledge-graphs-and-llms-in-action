Entering Purchase Requisitions Line Items




# Entering Purchase Requisitions Line Items

After entering general information in the header section
and tabs, begin adding line items to the purchase requisition.

1. Click the Insert
   Row button on the table toolbar to add a new line to the
   requisition.

VISUAL adds a new row to the table and assigns
it a line number.

The first column you select and the tab
movement between columns depends on your configuration of the line
item table. The procedures described below apply to columns in standard
order. In many cases, order of entry is not important.

2. If you are requisitioning
   an inventory part, double-click the Part ID
   column header.

|  |  |
| --- | --- |
| POSTIT.gif | Purchase Requisition Entry allows you to enter parts that are currently in the PART table of the database. If you enter an unrecognized part, VISUAL displays a warning message (Part id does not exist) and does not allow you to continue. |

A Part Browse dialog box appears.

You have the following browse options:

Part ID - Select
this option button to view a list of all parts in the database by
ID.

Part Description
- Select this option button to view a list of all parts in the database
by description

Parts supplied by current
vendor - Select this option button to display all parts the
selected vendor carries. This selection is not available until you
enter a vendor. The same Part ID can be listed multiple times in the
browse table. A Part ID is listed more than once if multiple Vendor
Part IDs are associated with the same part, or if you have approved
multiple vendor RFQs for the same Part ID.

Vendors supplying Current
Part - Select this option button to view a list of vendors
that carry the part. You cannot use this selection until you specify
a Part ID.

The Vendors Supplying Current Part option
does not select a new Part ID, but instead selects a vendor from among
those that supply the part. When you use this option, the Vendor ID
and all PO vendor information can change. If this happens, VISUAL
requests confirmation. The Vendor Part ID, U/M, and Unit Price on
the line item all set or reset to the new vendors values.

If you enter a Part ID for
a part that has a preferred vendor, and you have not previously entered
a Vendor ID for the purchase order, the Vendor ID and information
for the preferred vendor is automatically used.

The same vendor can be listed multiple times
in the browse table. A vendor is listed more than once if multiple
Vendor Part IDs are associated with the part or if you have approved
multiple vendor RFQs for the part.

3. Where applicable, enter
   information in the following columns.

|  |  |
| --- | --- |
| POSTIT.gif | Due to different line item table configurations, the order or availability of columns may be different in your window. You are not required to supply a value for each column.  Also, this table shares many field with the Purchase Order Entry window. Because the successful outcome of a requisition is a purchase order, VISUAL allows you to supply information based on the eventuality of the requisition becoming a actual purchase order. |

Quantity - The
quantity of the material or service you are requisitioning.

<Service ID>
- The ID of the service you are requisitioning. Double-click the <Service
ID> column header to choose from a list of contracted services.

Total PO Quantity
-

<Vendor ID>
- Double-click the <Vendor ID> column
header to select the vendor from whom you are ordering the material
or service. You can specify a vendor at the header level and a vendor
per line, even though you might want to enforce a limit of one master
Vendor ID per requisition.

Vendor Part ID
- If the vendor maintains a different ID for the part, enter it into
the Vendor Part ID field. VISUAL auto-fills this field if the vendor
specified in the header is the preferred vendor of the part. VISUAL
obtains this information from the part master.

<Warehouse ID>
- By default, VISUAL auto-fills each line with the Warehouse ID specified
in the header. To change warehouses, double-click the <Warehouse
ID> column header.

<WBS Code>
- WBS codes refer to projects, the equivalent of work orders if youre
using the Infor VISUAL Project-Based Edition.

Proj Ref Sub ID
See note below.

<Proj Ref Seq No>
- See note below.

<Dept ID>
- See note below.

<Cost Category ID>
- See note below.

|  |  |
| --- | --- |
| POSTIT.gif | The above four fields apply to the Infor VISUAL Project-Based Edition. |

<Part GL Account>
- For costing purposes, double-click the <Part
GL Account> column header to select a general ledger account
to assign to the part.

Mfg Name - Like
Vendor Part ID, if the preferred vendor is specified in the header,
VISUAL auto-fills this field with the part manufacturers name for
the part. Edit the name if necessary.

Mfg Part ID -
Like Vendor Part ID, if the preferred vendor is specified in the header,
VISUAL auto-fills this field with the part manufacturers ID for the
part. Edit the name if necessary.

U/M - This column
is auto-filled with the default unit of measure from the part master.
Modifying the U/M may result in an error, as a suitable conversion
must exist between the default u/m and any other u/m you may want
to specify. Set up conversion factors in Part Maintenance.

Receive Date -
If you know the date on which you expect to receive the purchase order,
enter it into the Receive Date field.

Unit Price - If
the vendor supplying the part has a price break quantity plan in effect,
VISUAL auto-fills this field with the unit price according to the
quantity of the line. Absent a preferred vendor unit price, VISUAL
uses the price from the part master.

Note: Unit price
modifications may result in the total value of the requisition changing.
If the Preparer is bound by a dollar maximum (for example, $1,000),
VISUAL may disallow the save.

Discount % - If
applicable, enter a discount percent for the part quantity. Discounts
apply per line.

Extension - The
actual value of the line is calculated by multiplying the unit price
by the quantity, plus any fixed/base charge, minus any applied discount
(see above).

Freight - If applicable,
enter a freight charge for the line.

Fixed/Base Charge
- If applicable, enter a fixed/base charge for the line. When you
choose an outside service, VISUAL obtains the default fixed/base charge
from the service record and auto-fills this field.

Minimum Charge
- If the requisition line is for a service linked to a work order,
enter a minimum charge. All outside services have default per unit,
base charge, and minimum charge values. When you choose an outside
service, VISUAL obtains the minimum charge from the service record
and auto-fills this field.

# Pieces - If
the part on the line is a piece-tracked part, enter the appropriate
number of pieces.

Length - For dimensional
inventory, enter the length of the part.

Width - For dimensional
inventory enter the width of the part.

Height - For dimensional
inventory, enter the height of the part.

Dim UM - For dimensional
inventory; select a dimensional unit of measure. If the part is a
piece-tracked part, VISUAL obtains the default Dim UM from the part
master and auto-fills this field.

Line Status -
VISUAL allows you to specify a status per line in addition to a header
status. After all tasks for a requisition are completed and the requisition
is cleared to become a purchase order, the status of lines are adjusted
accordingly. After a requisition is approved (status "Approved"),
VISUAL prevents further status changes, on both the header and line
level.

Material Code
- If the part is an order-management part and a material code is specified
for it, VISUAL displays the material code from the part master.

<HTS Code>
- If the part is an order-management part and an HTS code is specified
for it, VISUAL displays the HTS code from the part master.

<Country of Origin>
- If the part is an order-management part and a country or origin
code is specified for it, VISUAL displays the country of origin code
from the part master.

Duty % - If the
part is an order-management part and a duty % (duty percents are part
of HTS codes) is specified for it, VISUAL displays the duty % from
the part master.

Duty Amount -
If a duty percent applies, VISUAL calculates the duty amount.

<GL Expense Acct ID>
- If appropriate, select a G/L Account ID for the line. You cannot,
however, expense an inventory part, unless the part is designated
a consumable.

<Base ID>
- If you want to link the material or service to a work order or project,
double-click the <Base ID> column
header to choose a work order or project.

Lot ID - After
choosing a work order or project Base ID, VISUAL auto-fills the work
order/project Lot ID.

Split ID - After
choosing a work order or project Base ID, VISUAL auto-fills the work
order/project Split ID.

Sub ID - After
choosing a work order or project Base ID, VISUAL auto-fills the work
order/project Sub ID.

<Seq #>
- If the line is for a service, double-click the <Seq #> column
header to choose a sequence in the work order or project.

|  |  |
| --- | --- |
| POSTIT.gif | The work order/project service operation you choose must be the same as the Service ID specified earlier. |

<Piece #>
-

Link Part ID -
If the part is linked via an allocation to demand of any kind, the
link ID of the part appears here.

Stock U/M Order Quantity
- If the default stock u/m, differs from the u/m specified for the
line, VISUAL calculates the stock quantity based on the conversion
established between the two.

Specs - If the
part on the line has an attached specification, this check box is
selected.

Has Del Sched
- If the line contains a delivery schedule, this check box is selected.

<Ship from ID>
- If applicable, double-click the <Ship from
ID> column header and select a ship from address. Ship from
IDs can be specified per line and at the header level. Left blank,
all lines inherit the Ship from ID specified in the header.

<Ship to ID>
- If applicable, double-click the <Ship to ID>
column header and select a ship to address. Ship to IDs can be specified
per line and at the header level. Left blank, all lines inherit the
Ship to ID specified in the header.

<VAT Category>
- If VAT is activated, double-click the <VAT
Category> column header to choose an appropriate VAT category
for the line.

4. Click Save
   on the main toolbar to commit the requisition to the database.

[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](User_defined_Help_Files_Purchase_Requisition_Entry.md) User-defined Help