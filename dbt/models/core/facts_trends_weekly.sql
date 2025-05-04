{{ config(materialized='table') }}

with dim_trends_weekly as (
    select
        trend_id,
        region_code,
        refresh_date,
        term,
        avg_weekly_score as score,
        avg_weekly_rank as rank,
        avg_weekly_percent_gain as percent_gain
    from {{ ref('dim_trends_weekly') }}
)

select
    trend_id,
    region_code,
    term,
    refresh_date,
    format_date('%G%V', refresh_date) as year_week,
    date_trunc(refresh_date, week) as week_start_date,
    extract(month from refresh_date) as month,
    extract(quarter from refresh_date) as quarter,
    extract(year from refresh_date) as year,
    score as avg_weekly_score,
    rank as avg_weekly_rank,
    percent_gain as avg_weekly_percent_gain,
    1 as records_per_week
from dim_trends_weekly
