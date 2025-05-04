
{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('staging', 'trends_table') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['refresh_date', 'region_name', 'term']) }} as term_id,
        region_name,
        score,
        rank,
        country_code,
        region_code,
        term,
        week,
        percent_gain,
        refresh_date,
        country_name,
        format_date('%G%V', refresh_date) as year_week,
        extract(month from refresh_date) as month,
        extract(quarter from refresh_date) as quarter
    from source
)

select * from renamed
