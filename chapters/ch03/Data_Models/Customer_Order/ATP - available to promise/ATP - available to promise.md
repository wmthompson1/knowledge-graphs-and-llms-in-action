## ATP - available to promise.md
In manufacturing MRP, allocated refers to inventory (raw materials or subassemblies) that has been reserved for a specific, confirmed job order but has not yet been physically issued to the shop floor. This reserved material is officially "spoken for" and cannot be used for any other production run. [1, 2, 3]  
The Calculation Breakdown 

• Quantity On Hand: The total physical amount of an item currently sitting in your stockroom or warehouse. 
• Allocated: The amount of that physical stock specifically reserved for current work orders or sales orders. 
• Available to Promise (ATP): The physical stock free to use for new business. $ATP = \text{Quantity On Hand} - \text{Allocated}$ [1, 3, 4, 5, 6]  

What "Allocated" Means in a Make-To-Order (MTO) Job Shop 
In an MTO environment, MRP logic is driven by specific customer orders rather than forecasts. Here is how the allocated status directly impacts a job shop: 

• Reserved Material: When an engineering release triggers a work order, the MRP system allocates the required Bill of Materials (BOM) components. Even though the materials are still sitting on the warehouse shelf, they are "invisible" to other incoming orders. 
• Material Shortage Prevention: If Job A needs $10$ units of a specific bracket and you have $15$ on hand, the $10$ units become allocated. If Job B comes in and also requires $5$ brackets, the system recognizes the available balance is only $5$ brackets. It will then trigger a planned purchase or work order to cover the shortfall for Job B. 
• Prioritization & Pegging: Allocation lets the job shop know exactly which customer orders are covered and which components are tied to priority projects. 
• Moving to "Issued": Allocated inventory transitions to "WIP" (Work in Process) when the physical components are pulled from the stockroom and sent to the shop floor for actual production. [2, 12, 13]  

Would you like to explore how to set up safety stock or deal with lead times for allocated materials in your specific MRP software? 

AI responses may include mistakes.

[1] https://meshed360.com/knowledge-base-2/understanding-stock-value-available-on-hand-on-order-and-allocated-stock/
[2] https://quizlet.com/336379011/module-3-section-b-flash-cards/
[3] https://www.inventoryops.com/inventoryops-glossary.html
[4] https://docs.oracle.com/cd/A60725_05/html/comnls/us/bom/gls.htm
[5] https://www.scribd.com/document/789741875/Material-Ressource-Planning
[6] https://ascenterp.com/ascent-apps-360-kb/im/products/
[7] https://www.sap.com/resources/what-is-material-resource-planning-mrp
[8] https://acu-connect.com/2024/08/13/understanding-material-requirements-planning-mrp-meaning-and-process/
[9] https://qt9software.com/blog/what-is-mrp-software
[10] https://tractian.com/en/glossary/bill-of-materials-bom
[11] https://www.mrpeasy.com/mrp-system/
[12] https://study.com/academy/lesson/job-order-cost-system-purpose-pros-cons.html
[13] https://community.sap.com/t5/enterprise-resource-planning-q-a/allocating-oh-on-wip/qaq-p/10309042

