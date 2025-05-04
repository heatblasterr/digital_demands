{{ config(
    materialized='incremental',
    unique_key=['region_code', 'trend_date']
) }}

with dim_trends_daily as (
    select
        trend_id,  
        region_code,
        trend_date,
        term,
        avg_daily_score as score,
        avg_daily_rank as rank,
        avg_daily_percent_gain as percent_gain
    from {{ ref('dim_trends_daily') }}

    {% if is_incremental() %}
      where trend_date > (select max(trend_date) from {{ this }})
    {% endif %}
)

select
    trend_id,
    region_code,
    trend_date,
    term,

    extract(month from trend_date) as month,
    extract(quarter from trend_date) as quarter,
    extract(year from trend_date) as year,
    extract(day from trend_date) as day,

    score as avg_daily_score,
    rank as avg_daily_rank,
    percent_gain as avg_daily_percent_gain,
    1 as records_per_day  -- 1 row per day per region per trend
from dim_trends_daily
