{{ config(materialized='table') }}

with source as (
    select * from {{ ref('staging_trends_table') }}
),

ranked_terms as (
    select
        {{ dbt_utils.generate_surrogate_key(['region_name', 'term', 'refresh_date']) }} as region_term_id,
        region_name,
        country_name,
        country_code,
        region_code,
        term,
        score,
        rank,
        percent_gain,
        refresh_date,
        format_date('%G%V', refresh_date) as year_week,

        row_number() over (
            partition by country_code, region_name, format_date('%G%V', refresh_date)
            order by score desc
        ) as term_rank_in_region

    from source
)

select
    region_term_id,
    region_name,
    region_code,
    country_name,
    country_code,
    term,
    score,
    rank,
    percent_gain,
    refresh_date,
    year_week,
    term_rank_in_region

from ranked_terms
where term_rank_in_region <= 5  -- Top 5 per region per week
