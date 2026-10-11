-- please scheck date fields for type not date. Use the existing code base to walk schema Documentation\Schema\Data_Models\Customer_Order\Shipping\sp_Shipments_Core_Feed_01.sql
-- Documentation\Schema\Data_Models\Customer_Order\Shipping\sp_Shipments_Core_Feed_02.sql, Documentation\Schema\Data_Models\Customer_Order\Shipping\sp_Shipments_Core_Feed_03.sql
SELECT ADJUSTED_DUE_DATE, date FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT_01
where base_table != 'LIVEARC'
and isdate(ADJUSTED_DUE_DATE) = 0