# Purchase Requisitions Guide

This guide consolidates the purchase requisition help topics in this folder into a single 5-page walkthrough. It is written as a practical reference for entering, managing, and converting requisitions in VISUAL.

<div style="page-break-after: always;"></div>

## Page 1 of 5: What Purchase Requisitions Are For

Purchase requisitions are the starting point for requesting parts, services, or buy/sell activity before the request becomes a purchase order. They support vendor quote workflows, approval routing, and auditability when multiple vendors or contract requirements are involved.

Use requisitions when you need to:

- Capture a request before ordering.
- Route work through an approval process.
- Track vendor RFQs or similar request-for-quote activity.
- Preserve an audit trail for procurement decisions.

Core reference topics:

- [Working with Purchase Requisitions](Working_with_Purchase_Requisitions.md)
- [Preparing to Enter Purchase Requisitions](Preparing_to_Enter_Purchase_Requisitions.md)
- [Document Lifecycle in Purchase Requisition Entry](Document_Lifecycle_in_Purchase_Requisition_Entry.md)

<div style="page-break-after: always;"></div>

## Page 2 of 5: Before You Enter a Requisition

Before creating requisitions, confirm that the user has the right permissions and that the requisition status workflow is configured correctly. The status controls determine who can draft, approve, order, close, or cancel requisitions.

Checklist:

1. Confirm the preparer and requestor are correct for the transaction.
2. Verify the user can change requisition statuses if required.
3. Confirm the site context if your environment uses multiple sites.
4. Make sure the workflow supports the intended end state, such as approval before ordering.

Reference topics:

- [Working with Purchase Requisitions](Working_with_Purchase_Requisitions.md)
- [Preparing to Enter Purchase Requisitions](Preparing_to_Enter_Purchase_Requisitions.md)
- [Starting Purchase Requisition Entry](Starting_Purchase_Requisition_Entry.md)
- [Setting a Purchase Requisition Default Status](Setting_a_Purchase_Requisition_Default_Status_.md)

<div style="page-break-after: always;"></div>

## Page 3 of 5: Entering Header and Line Details

Once you open Purchase Requisition Entry, the header establishes the request context and the line items define the actual demand. Header values control who is requesting, where the requisition belongs, and how it should flow through the system. Lines capture the parts or services being requested.

Typical entry tasks include:

- Start a new requisition in the entry window.
- Set the header information for the request.
- Add line items and quantities.
- Apply part specifications where needed.
- Use source and target controls when the requisition needs to follow a defined routing pattern.

Reference topics:

- [Initiating Purchase Requisitions](VMREQENTfrmPurchaseReq.md)
- [Entering Purchase Requisitions Line Items](Entering_Purchase_Requisitions_Line_Items.md)
- [Passing Part Specs to Purchase Requisition Lines](Passing_Part_Specs_to_Purchase_Requisition_Lines_.md)
- [Source and Target Buttons in Purchase Requisition Entry](Source_and_Target_Buttons_in_Purchase_Requisition_Entry.md)
- [In-context View Panels in Purchase Requisition Entry](In-context_View_Panels_in_Purchase_Requisition_Entry.md)

<div style="page-break-after: always;"></div>

## Page 4 of 5: Reviewing, Editing, and Tracking

Requisitions rarely stay unchanged after they are created. Users may need to modify the request, repeat lines, copy an existing requisition, or review its lifecycle and related documents.

Common maintenance actions:

- Edit the requisition header or line details.
- Copy a requisition when a similar request is needed.
- Repeat lines for recurring or patterned demand.
- Adjust exchange rates for a specific requisition when needed.
- Review the requisition in the document lifecycle viewer.
- Check the requisition line item table when validating line-level detail.

Reference topics:

- [Copying Purchase Requisitions](Copying_Purchase_Requisitions.md)
- [Editing Purchase Requisitions](Editing_Purchase_Requisitions.md)
- [Modifying Purchase Requisition Information](Modifying_Purchase_Requisition_Information.md)
- [Repeating Purchase Requisition Lines](Repeating_Purchase_Requisition_Lines.md)
- [Setting Exchange Rates for Individual Purchase Requisitions](Setting_Exchange_Rates_for_Individual_Purchase_Requisitions.md)
- [Purchase Requisitions Line Item Table](Purchase_Requisitions_Line_Item_Table.md)
- [Document Lifecycle in Purchase Requisition Entry](Document_Lifecycle_in_Purchase_Requisition_Entry.md)

<div style="page-break-after: always;"></div>

## Page 5 of 5: Approval, Conversion, and Exceptions

The final stage is moving the requisition through approval and into downstream purchasing. Only approved requisitions can become purchase orders, and the system also supports related purchasing paths such as internal purchase orders.

Key rules and outcomes:

- Approved requisitions can generate purchase orders.
- Multiple sites must stay within the same site for requisition-to-order conversion.
- If a requisition is no longer needed, deletion or cancellation rules apply.
- Project-linked requisitions may require additional project fields.
- Viewing requisitions by vendor or by order helps confirm downstream usage.

Reference topics:

- [Generating Purchase Orders from Purchase Requisitions](Generating_Purchase_Orders_from_Purchase_Requisitions.md)
- [Generating Internal Purchase Orders from Requisitions](Generating_Internal_Purchase_Orders_from_Requisitions.md)
- [Viewing Purchase Requisitions for Purchase Orders](Viewing_Purchase_Requisitions_for_Purchase_Orders.md)
- [Viewing Purchase Requisitions](Viewing_Purchase_Requisitions_Vendor_Inquiry.md)
- [Linking Purchase Requisitions to Projects](Linking_Purchase_Requisitions_to_Projects.md)
- [Deleting Purchase Requisitions](Deleting_Purchase_Requisitions.md)
- [User-defined Help Files Purchase Requisition Entry](User_defined_Help_Files_Purchase_Requisition_Entry.md)

### Quick Summary

1. Prepare the user, site, and status setup.
2. Enter the header and line items.
3. Review, copy, or modify the requisition as needed.
4. Approve the requisition.
5. Convert it to a purchase order or close it out if it is no longer required.