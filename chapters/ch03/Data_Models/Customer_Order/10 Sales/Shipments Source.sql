SELECT * FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
        WHERE FILTER_DATE >= '2025-01-01'

SELECT bus_stream
,year(FILTER_DATE) as year
--,month(FILTER_DATE) as month
, count(*) countof
        FROM LIVESupplemental.dbo.PBI_Customer_Shipments_complement_OT
        WHERE FILTER_DATE >= '2025-01-01'
        group by bus_stream, year(FILTER_DATE) -- ,month(FILTER_DATE) 
        order by  year(FILTER_DATE)
        --, month([FILTER_DATE])
        , bus_stream