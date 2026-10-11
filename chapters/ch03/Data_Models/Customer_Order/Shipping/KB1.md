KB0738225

https://customerportal.infor.com/csmcore?id=kb_article_view&sys_kb_id=76bd68798359d2148b1a3a547daad386&table=kb_knowledge&searchTerm=shipping%20in%20stock

Difference Between Shipped Quantity, Stock Shipped Quantity, Order Quantity and Stock Order Quantity
Article metadata.This article has 41 views. 41 Views This article has average rating: 0 out of 5 stars• ( )( ) ( ) ( ) ( ) 
Article Information
________________________________________________________________________________________________________________


### Description :###

What is the difference between Shipped Quantity (TOTAL_USR_SHIPPED_QTY) and Stock Shipped Quantity (TOTAL_SHIPPED_QTY) on a customer order line?
What is the difference between Quantity (USER_ORDER_QTY), Order Qty (ORDER_QTY) and Stock Order Qty (ORDER_QTY) on a customer order line?
What is the difference between RECEIVED_QTY and USER_RECEIVED_QTY in purchase order/receiving entry?
What is the difference between Quantity (USER_ORDER_QTY) and Order Qty (ORDER_QTY) on a purchase order line?

 


**Resolution :**
If there is a difference, it is due to a unit of measure conversion on the part.
SHIPPED_QTY, ORDER_QTY, RECEIVED_QTY would all be quantities based on the stocking unit of measure.
Quantities that have USER_ or TOTAL_USR in front of them are the quantities based on the conversion unit of measure.

### Example: ###
Stocking Unit of Measure:  EA
Unit of Measure Conversion:  2 EA = 1 PAIR
Customer Order entered and shipped for 10 PAIR
User Shipped Qty = 10
Shipped Qty = 20