Generating Purchase Orders from Purchase Requisitions




# Generating Purchase Orders from Purchase Requisitions

For information about generating internal buy/sell
orders from purchase requisitions, see [Generating
Internal Purchase Orders from Requisitions](Generating_Internal_Purchase_Orders_from_Requisitions.md)

Purchase requisitions are eligible to become purchase
orders if hey have been approved by the appropriate individual or
team.

Typically, the procurement cycle begins with the initiation of a
requisition for a quantity of parts or services and then moves to
the review stage, when VISUAL users assigned to requisition approval
teams complete tasks that, when completed, qualify a requisition to
become a purchase order.

|  |  |
| --- | --- |
| POSTIT.gif | Only Approved requisitions are eligible to become purchase orders |

If you are licensed to use multiple sites, you can generate a purchase
order from a requisition in the same site only. You cannot use a requisition
created in one site to generate a purchase order in a second site.

To generate orders from requisitions:

1. If you are licensed
   to use multiple sites, click the Site ID arrow and select the
   site to use. If you are licensed to use a single site, this field
   is unavailable.
2. From the Edit menu,
   select Generate Order from Requisition....

The Generate Purchase Order from Requisition
dialog box appears.

3. Click the Requisitions
   button to view a list of all requisitions for the specified Buyer.

The List Requisitions dialog box appears,
listing all requisitions in the database with the specified Buyer
ID.

4. Choose the requisition,
   or group of requisitions by clicking the appropriate IDs.

With the appropriate requisitions selected,
click the Right arrow button to move the
IDs into the Select Requisitions field.

To remove a requisition from the Selected
field, select it and click the Left arrow
button.

A double-click also prompts VISUAL to move
the requisitions into the adjacent field.

5. Click the Ok
   button.

VISUAL returns you to the main dialog box,
displaying the IDs of the requisitions in the adjacent read-only field.

All lines from the selected requisitions
appear in the below table, renumbered in ascending order.

6. Choose a new order status
   for the purchase order by selecting the appropriate New Order
   Status option:

Released - Select
Released to create the purchase order with
a status of Released, or ready for submittal to the vendor.

Firmed - Select
Firmed to create the purchase order with
a status of Firmed, or approved but not ready for release.

7. If appropriate, enter
   an ID for the new order in the New Order ID field. If you use
   VISUAL auto-numbering, leave this field blank for VISUAL to assign
   the next available ID.
8. Click the Vendor
   ID button to choose a vendor the purchase order. This is
   a required field.
9. Select which requisition
   lines you want to add to the purchase order. Hold down the CTRL key to select multiple, non-contiguous
   lines.

Click the Select All button to select all
lines; click the Deselect All button to
deselect all lines.

10. If appropriate, modify
    the Vendor for each line by double-clicking the <Vendor
    ID> column header and choosing a different vendor that
    the one specified earlier. See step 8.

    |  |  |
    | --- | --- |
    | POSTIT.gif | Choosing a different Vendor ID prompts VISUAL to create more than one purchase order, one for each Vendor ID. See the next step. |

11. Click the Ok
    button to create the purchase order, or orders if more than one
    Vendor is specified.

If you specified more than one vendor, a
dialog box appears.

12. Click the Yes
    button to continue.

VISUAL informs you that the creation was
successful and asks you if you want to load the new purchase order.
Click the Yes button.

VISUAL returns you to the Purchase Order
Entry window, displaying the purchase order.

|  |  |
| --- | --- |
| POSTIT.gif | If you did in fact choose to create multiple purchase orders, VISUAL displays only the first it created. To view any other it may have created, manually change Our Order ID to the next available ID, which VISUAL uses for the next vendor. |

[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](User_defined_Help_Files_Purchase_Requisition_Entry.md) User-defined Help