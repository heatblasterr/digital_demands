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
    refresh_date,
    format_date('%G%V', refresh_date) as year_week,
    date_trunc(refresh_date, week) as week_start_date,
    extract(month from refresh_date) as month,
    extract(quarter from refresh_date) as quarter,
    extract(year from refresh_date) as year,
    avg(score) as avg_weekly_score,
    avg(rank) as avg_weekly_rank,
    avg(percent_gain) as avg_weekly_percent_gain,
    count(*) as records_per_week
from source
group by
    trend_id, term, region_name, country_code, country_name, region_code,
    refresh_date, year_week, week_start_date, month, quarter, year
