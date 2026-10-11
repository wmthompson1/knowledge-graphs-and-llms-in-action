KB3612388

MRP (Material Requirement Planning) uses 'Promised Ship Date' value instead of 'Desired Ship Date' for 'Release Date'
Article metadata.This article has 78 views. 78 Views This article has average rating: 0 out of 5 stars• ( )( ) ( ) ( ) ( ) 
Article Information
________________________________________________________________________________________________________________


Description :

How is Release Date determined in Material Planning window?
Material Requirement Planning (MRP) is using 'Promise Ship Date' instead of 'Desired Ship Date' of Customer Order to determine Release Date.


Steps to Reproduce :
1 Sales > Customer Order Entry
  Enter 'Customer ID'
  Enter today's date as 'Desired Ship Date'
  Enter any future date as 'Promised Ship Date'
  Insert a row for order line
  'Part ID' = any
  'Quantity' = any
  Check 'New W/O'
  Save

2 Inventory > Material Planning Window
  Enter 'Part ID' from above step
 <Tab>
  Look for 'Release Date' and compare value to date used in Customer Order created from above step.
'Release Date' uses 'Promised Ship Date' value instead of 'Desired Ship Date'


Resolution :
An Enhancement was added in VISUAL 10 to Material Requirements Planning (MRP) to allow the user to determine which date to use when netting.
A preference for this is located in the Planning Window section of Preference Maintenance (MRPByReleaseDate).

When this preference is set to "Y", MRP will base its netting on the Customer Order Promise Ship Date (Release Date), which is the date promised on the customer order to be shipped.
This becomes the target "Release Date" on the demand side in MRP. If no Promise Ship Date is listed on the customer order, the Desired Ship Date is used. 

If this preference is set to "N", which is the default, MRP will use traditional quantity netting rules, meaning MRP will use the Desired Ship Date on the demand side, not the Release Date/Promise Ship Date from the Customer Order. 

This is a global only preference.

