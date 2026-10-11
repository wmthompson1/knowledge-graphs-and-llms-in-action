-- Staging.[dbo].my_CUSTOMER_ORDER

            update t
            set posting_candidate = 'Y'
            from live.dbo.CUSTOMER_ORDER t
            join staging.dbo.my_CUSTOMER_ORDER s
                on s.id = t.id
              ---  and s.flagged = 0
            where 1=1  
              and t.posting_candidate <> 'Y';
