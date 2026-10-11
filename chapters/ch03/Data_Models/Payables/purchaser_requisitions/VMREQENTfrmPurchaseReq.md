Initiating Purchase Requisitions




# Initiating Purchase Requisitions

There are several methods you can use to create purchase
requisitions. The most basic method, and probably the method you will
use most often, is directly through the Purchase Requisition Entry
window. The window itself is made up of a header section and a table
section. The header section allows you to specify general requisition
information such as Vendor ID, Date, and ship to address; the table
section allows you to enter actual lines of material or service. Start
the requisition process by filling in the fields in the header section.
See [the next
section](Entering_Purchase_Requisitions_Line_Items.md) for more information.

## Entering Header Information for Purchase Requisitions

1. If you are licensed
   to use multiple sites, click the Site ID arrow and select the
   site that is requesting the purchase. If you are licensed to use
   a single site, this field is unavailable.
2. Enter an ID for the
   requisition into the Requisition ID field.

If you use auto numbering to number your
VISUAL documents, leave this field blank. VISUAL auto-generates an
ID for the requisition when you save.

The
name of the currently user appears in the Preparer field.

3. If appropriate, click
   the Vendor ID button to choose a vendor.
   This is the vendor
   from whom youll be purchasing the material or service.
4. Click the Warehouse
   ID button to choose the warehouse into which you will receive
   the items on the requisition.
5. Change the Requisition Date if necessary. This
   is the date on which the requisition is being entered. By default,
   VISUAL supplies the current system date.
6. Enter the date by which
   you want to receive the items on this requisition into the Desired
   Recv Date field. By default, VISUAL supplies the current system
   date.

7. From the Requestor list box, select which VISUAL
   user requested this requisition. By default, VISUAL assumes the
   Requestor is the user currently signed into VISUAL.

8. From the Assigned To list box, select which VISUAL
   user is assigned to this requisition. By default, VISUAL assumes
   the Assigned To individual is the user currently signed into VISUAL.
9. Select a Currency ID
   for the requisition from the Currency
   ID list box. The list contains all supported currencies.
10. Click the Purch
    From/Ship To tab.
11. Specify purchase from
    and ship to information as follows:

Status
- Select a status for the requisition: Draft, In Process, Approved,
Ordered, Closed, or Cancelled/Void.

VISUAL offers a status for each stage of
the purchase requisition cycle.

Draft - Draft requisitions
are requisition that have been entered into the database. In the draft
state, they remain as a sort of placeholder until further action is
taken. When entering requisitions in volume, use the Draft status
designation.

You can edit information on a Draft requisition
at any time.

In Process - In process
requisitions have been entered into the database and are currently
being reviewed.

You can edit information on an In Process requisition
at any time.

Approved - Approved
requisitions have been approved and are ready to become actual purchase
orders.

|  |  |
| --- | --- |
| POSTIT.gif | VISUAL disallows changes to Approved requisitions. |

Ordered - Ordered
requisitions have become actual purchase orders. The approval disposition
is complete and the purchase order has been placed.

You cannot edit information on an Ordered requisition.

Closed - Closed requisitions
are complete and therefore closed. The purchase order created from
the requisition has been received and is currently in inventory or
has been allocated to an in-process work order.

You cannot edit information on a Closed requisition.

Cancelled/Void -
Cancelled/Void requisitions are rejected and therefore cancelled.

Buyer
- Click the browse button and select the buyer for this requisition.
A Buyer may be the purchasing agent who initiated the requisition
or the same as the Requestor. Specify buyers in Buyer Maintenance.
You must select an eligible buyer. You cannot specify a buyer who
is excluded from using the vendor in this field. See [Excluded
Buyers and Vendor Documents](Excluded_Buyers_and_Vendor_Documents.md).

FOB
- From the Free on Board combo box, select the appropriate
FOB. To use a FOB code that isnt listed, enter a unique code into
the FOB field.

Ship
Via - From the ship via codes combo box, select a method of
shipment for the requisition. To use a Ship Via code that isnt listed,
enter a unique code into the Ship Via field.

ShipTo
ID - The ShipTo ID of the address to which the vendor will
ship this order. This is a read-only field. If the address has a ShipTo
ID, VISUAL displays it here.

|  |  |
| --- | --- |
| POSTIT.gif | Purchase requisitions support multiple Ship to IDs: one at the header level and one per line. If you dont specify otherwise for the lines in the requisition, they inherit this Ship to ID. |

Category
- Click the Category button to select a
category type code for the requisition. Define category type codes
using the "Category Type Tables" feature available from
the Maintain menu.

12. Click the Contact
    tab and specify the contact for this purchase requisition. By
    default, the primary contact information for the vendor is displayed.
    You can specify a different contact. You can select a contact
    with an ID or enter a standalone contact for this transaction
    only.
13. To select
    a contact with a registered Contact ID, use one of these methods:

Select an alternate contact - Click the Contact browse button and select a contact from
the browse table showing contacts assigned to the vendor. Select the
Use Selected Contact toolbar button.

Select a contact from all contacts - Click
the Contact browse button and then click
the Associate existing contact toolbar button.
Select a contact from the Contacts dialog and click Ok.
In the Contacts for Vendor dialog select the contact and then click
the Use Selected Contact toolbar button.

Specify a new contact in the Contacts for Vendor
dialog - Click the Contact browse button.
Click the Add New Contact button and specify
contact information in the General tab and Address tab fields. Click
the Save toolbar button.

You can also assign contacts to vendors in
the Contact Maintenance window.

* To specify
  a standalone contact, specify the contact information in the fields
  on the Contact tab. If contact information is already displayed
  in the tab, you can edit the existing information to create a
  standalone contact. When you edit the information, the Contact
  ID field is cleared. The edits that you make in the Contact tab
  do not update contact information in your Contact table. Standalone
  contact information is saved with the transaction only and is
  not added to your Contacts table. If you anticipate using this
  standalone contact again, Infor recommends creating a contact
  with a Contact ID.

Specify this information:

Contact ID/Name
Enter the contacts full name and review the ID number. A contact
without an ID number does not display in Contact Maintenance.

Position  Enter
the contacts position. For example, CEO.

Salutation Enter
the salutation to use for this vendor contact. This field has a drop-down
menu populated with some of the most popular salutations.

Phone/Ext Enter
the telephone number, with area code and extension, for the contact.
This may be a direct line to the contact, or a generic company line.

Fax Enter the area
code and Fax number.

Mobile Enter the
contacts area code and mobile phone number.

E-Mail Enter the
vendor's email address.

Standalone contacts are not added to the Email
Documents list for the vendor. Only contacts with IDs can be added
to the Email Documents list.

If you do not want to assign a contact to this
order, click the Use No contact toolbar
button.

13. Click the Approvals
    tab.

The Approvals tab contains the four levels
of approval, which are user-definable through Application Global Maintenance.
If the Approval level is active, an asterisk (\*) appears to the right
of the button label.

To override the default members or to define
a group specific to this requisition, click the browse button. If
you are licensed to use multiple sites, you can only select users
who are allowed to use the site selected in the Site ID field. If
you are licensed to use a single site, you can select any user in
your database.

As task completion is reported for the requisition,
the progress meters are updated appropriately to indicate what percentage
of the overall task load has been completed.

For example, if an approval task involves
four users, and each user is responsible for 25% of the task, the
system increases the completion meter after each user completes the
task. For example, after the first user completes the task, the system
updates the meter to 25%. After the second user completes the task,
the system updates the meter to 50%, and so on.

14. Lastly, specify purchase
    from/ship to address.

    |  |  |
    | --- | --- |
    | POSTIT.gif | Only change the purchase from and ship to addresses if you want to purchase from or ship to an address other than the default addresses. |

Click the Purchase Address
button on the main toolbar or select Purchase Address
from the Edit menu. Choose the vendor address you are purchasing the
parts or service from and click the Use Selected
Address button.

VISUAL updates the Purchase From/Ship To
field with the vendor address.

Click the Ship to Address
button on the main toolbar or select Ship to Address
from the Edit menu. Choose the address you want the vendor to ship
the parts or service to and click the Use selected
ship to address button.

VISUAL updates the Purchase From/Ship To
field with the ship to address. VISUAL also updates the Shipto ID
field if an ID exists for the address.

[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](User_defined_Help_Files_Purchase_Requisition_Entry.md) User-defined Help

[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](Entering_Purchase_Requisitions_Line_Items.md)
Entering Purchase Requisition Line Items

[![btn_mini.gif](btn_mini.gif "btn_mini.gif")](Adding_Task_Specification_Text.md) Adding Task Specification Text