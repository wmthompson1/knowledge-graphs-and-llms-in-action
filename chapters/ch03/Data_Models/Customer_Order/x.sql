SELECT
	 PSF.[Target] AS 'TARGET_GOALS'
     ,PSF.BusStream
     ,PSF.[Date] 
FROM [SQL-Bi-1].[LIVESupplemental].[dbo].[Plant_Shipment_Forecast] PSF
	-- ON PSF.BusStream = A.BUS_STREAM AND PSF.[Date] = DATEADD(DD,-(DAY(A.FILTER_DATE)-1), A.FILTER_DATE)