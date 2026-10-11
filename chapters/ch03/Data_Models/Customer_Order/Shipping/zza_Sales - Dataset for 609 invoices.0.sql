select * FROM
[SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] PSF WITH (NOLOCK)
where year = 2026
and busstream in ('CMP-FIN', 'CMP-MFG')