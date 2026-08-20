/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT",
    "location": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

declare project_name string default 'PROJECT NAME';  -- Change this
declare dataset_name string default 'nameless_analytics';

declare events_debug string default format ("""
CREATE OR REPLACE TABLE FUNCTION `%s.%s.events_debug`(start_date DATE, end_date DATE) AS (
with raw_event_data as (
    select 
      # USER DATA
      user_date,
      client_id,
      first_value(user_data) over (partition by client_id order by event_timestamp desc) as user_data,

      # SESSION DATA
      session_date,
      session_id,
      first_value(session_data) over (partition by session_id order by event_timestamp desc) as session_data,

      # PAGE DATA
      page_date,
      page_id,
      dense_rank() over (partition by session_id order by (select value.int from unnest(page_data) where name = 'page_load_timestamp') asc) as page_view_number,
      page_data, 

      # EVENT DATA
      event_date,
      event_timestamp,
      event_name,
      rank() over (partition by session_id order by event_timestamp asc) as event_number,
      event_origin,
      event_id,
      event_data,

      # OTHER DATA
      ecommerce,
      datalayer,
      consent_data
    from `%s.%s.events_raw`
    where event_date between start_date and end_date
  )

  select
    # USER DATA
    user_date,
    client_id,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(user_data)
    ) as user_data,

    # SESSION DATA
    session_date,
    session_id,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(session_data)
    ) as session_data,

    # PAGE DATA
    page_date,
    page_id,
    page_view_number,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(page_data)
    ) as page_data,

    # EVENT DATA
    event_date,
    timestamp_millis(event_timestamp) as event_datetime,
    event_timestamp,
    event_origin,
    event_name,
    event_id,
    event_number,
    array(
      select as struct
        name,
        struct(
          value.string as string,
          value.int as int,
          value.float as float,
          to_json_string(value.json) as json,
          value.bool as bool
        ) as value
      from unnest(event_data)
    ) as event_data,

    # ECOMMERCE DATA
    json_value(ecommerce, '$.transaction_id') as transaction_id,

    array(
      select as struct
        item_offset + 1 as item_number,

        array(
          select as struct
            item_key as name,

            struct(
              case
                when json_type(item_json[item_key]) = 'string'
                then lax_string(item_json[item_key])
              end as string,

              case
                when json_type(item_json[item_key]) = 'number'
                  and safe_cast(
                    json_value(item_json[item_key]) as int64
                  ) is not null
                then safe_cast(
                  json_value(item_json[item_key]) as int64
                )
              end as int,

              case
                when json_type(item_json[item_key]) = 'number'
                  and safe_cast(
                    json_value(item_json[item_key]) as int64
                  ) is null
                then lax_float64(item_json[item_key])
              end as float,

              case
                when json_type(item_json[item_key]) in ('object', 'array')
                then to_json_string(item_json[item_key])
              end as json,

              case
                when json_type(item_json[item_key]) = 'boolean'
                then lax_bool(item_json[item_key])
              end as bool
            ) as value

          from unnest(
            ifnull(
              json_keys(item_json, 1),
              cast([] as array<string>)
            )
          ) as item_key

          order by item_key
        ) as item_data

      from unnest(
        ifnull(
          json_query_array(ecommerce, '$.items'),
          cast([] as array<json>)
        )
      ) as item_json with offset as item_offset

      order by item_offset
    ) as items,

    array(
      select as struct
        ecommerce_key as name,

        struct(
          case
            when json_type(ecommerce[ecommerce_key]) = 'string'
            then lax_string(ecommerce[ecommerce_key])
          end as string,

          case
            when json_type(ecommerce[ecommerce_key]) = 'number'
              and safe_cast(
                json_value(ecommerce[ecommerce_key]) as int64
              ) is not null
            then safe_cast(
              json_value(ecommerce[ecommerce_key]) as int64
            )
          end as int,

          case
            when json_type(ecommerce[ecommerce_key]) = 'number'
              and safe_cast(
                json_value(ecommerce[ecommerce_key]) as int64
              ) is null
            then lax_float64(ecommerce[ecommerce_key])
          end as float,

          case
            when json_type(ecommerce[ecommerce_key]) in ('object', 'array')
            then to_json_string(ecommerce[ecommerce_key])
          end as json,

          case
            when json_type(ecommerce[ecommerce_key]) = 'boolean'
            then lax_bool(ecommerce[ecommerce_key])
          end as bool
        ) as value

      from unnest(
        ifnull(
          json_keys(ecommerce, 1),
          cast([] as array<string>)
        )
      ) as ecommerce_key

      where ecommerce_key != 'items'
      order by ecommerce_key
    ) as ecommerce_data,

    # OTHER DATA
    array(
      select as struct
        datalayer_key as name,
        struct(
          case
            when json_type(datalayer[datalayer_key]) = 'string'
            then lax_string(datalayer[datalayer_key])
          end as string,

          case
            when json_type(datalayer[datalayer_key]) = 'number'
              and safe_cast(
                json_value(datalayer[datalayer_key]) as int64
              ) is not null
            then safe_cast(
              json_value(datalayer[datalayer_key]) as int64
            )
          end as int,

          case
            when json_type(datalayer[datalayer_key]) = 'number'
              and safe_cast(
                json_value(datalayer[datalayer_key]) as int64
              ) is null
            then lax_float64(datalayer[datalayer_key])
          end as float,

          case
            when json_type(datalayer[datalayer_key]) in ('object', 'array')
            then to_json_string(datalayer[datalayer_key])
          end as json,

          case
            when json_type(datalayer[datalayer_key]) = 'boolean'
            then lax_bool(datalayer[datalayer_key])
          end as bool
        ) as value
      from unnest(
        ifnull(
          json_keys(datalayer, 1),
          cast([] as array<string>)
        )
      ) as datalayer_key
    ) as datalayer_data,

    consent_data

  from raw_event_data
);
""", project_name, dataset_name, project_name, dataset_name);

execute immediate events_debug;
