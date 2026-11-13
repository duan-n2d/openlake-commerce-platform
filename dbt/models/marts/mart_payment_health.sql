select
    date_trunc('minute', processed_at) as metric_minute,
    count(*) as total_payments,
    sum(case when payment_status = 'captured' then 1 else 0 end) as captured_payments,
    sum(case when payment_status = 'failed' then 1 else 0 end) as failed_payments,
    cast(sum(case when payment_status = 'failed' then 1 else 0 end) as double) / nullif(count(*), 0) as failed_payment_rate
from {{ ref('fact_payment') }}
group by 1
