{{ config(materialized='table') }}

with source as (
    select * from {{ ref('staging_trends_table') }}
)

select
    trend_id,
    term,
    region_name,
    country_code,
    country_name,
    region_code,
    refresh_date as trend_date,
    avg(score) as avg_daily_score,
    avg(rank) as avg_daily_rank,
    avg(percent_gain) as avg_daily_percent_gain,
    count(*) as records_per_day,
    extract(month from refresh_date) as month,
    extract(quarter from refresh_date) as quarter
from source
group by
    trend_id, term, region_name, country_code, country_name, region_code, trend_date, month, quarter
