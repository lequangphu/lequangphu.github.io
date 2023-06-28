with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
  uni AS (
    with
      eth AS (
        SELECT DISTINCT
          s.recipient AS swapper
        FROM
          ethereum.uniswapv3.ez_swaps AS s
          JOIN ethereum.uniswapv3.ez_pools AS p on p.pool_address = s.pool_address
          JOIN dates AS d
        WHERE
          1 = 1
          AND s.block_timestamp::date >= d.start_date
          AND s.block_timestamp::date <= d.end_date
      ),
      bnb AS (
        with
          pool AS (
            SELECT
              l.event_inputs:pool AS pool
            FROM
              bsc.core.fact_event_logs AS l
            WHERE
              1 = 1
              AND l.block_number >= 25632913
              AND l.contract_address IN (
                '0x128ce3a3d48f27ce35a3f810cf2cddd2f6879b13',
                '0xdb1d10011ad0ff90774d0c6bb92e5c5c8b4461f7'
              ) -- Uniswap V3: Factory
              AND l.event_name = 'PoolCreated'
          )
        SELECT DISTINCT
          l.event_inputs:recipient AS swapper
        FROM
          bsc.core.fact_event_logs AS l
          JOIN dates AS d
          JOIN pool AS p on p.pool = l.contract_address
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
          AND l.event_name = 'Swap'
      )
    SELECT
      'ethereum' AS chain,
      *
    FROM
      eth
    UNION all
    SELECT
      'bnb' AS chain,
      *
    FROM
      bnb
  ),
  pancake AS (
    with
      eth AS (
        with
          pool AS (
            SELECT
              l.decoded_log:pool AS pool
            FROM
              ethereum.core.ez_decoded_event_logs AS l
            WHERE
              1 = 1
              AND l.contract_address = '0x0bfbcf9fa4f9c56b0f40a671ad40e0805a091865' -- PancakeSwap: Factory V3
              AND l.event_name = 'PoolCreated'
          )
        SELECT DISTINCT
          l.decoded_log:recipient::varchar AS swapper
        FROM
          ethereum.core.ez_decoded_event_logs AS l
          JOIN dates AS d
          JOIN pool AS p on p.pool = l.contract_address
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
          AND l.event_name = 'Swap'
      ),
      bnb AS (
        with
          pool AS (
            SELECT
              l.event_inputs:pool AS pool
            FROM
              bsc.core.fact_event_logs AS l
            WHERE
              1 = 1
              AND l.contract_address = '0x0bfbcf9fa4f9c56b0f40a671ad40e0805a091865' -- PancakeSwap: Factory V3
              AND l.event_name = 'PoolCreated'
          )
        SELECT DISTINCT
          l.origin_from_address AS swapper
        FROM
          bsc.core.fact_event_logs AS l
          JOIN dates AS d
          JOIN pool AS p on p.pool = l.contract_address
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
          AND l.topics[0] = '0x19b47279256b2a23a1665c810c8d55a1758940ee09377d4f8d26497a3577dc83' -- Swap
      )
    SELECT
      'ethereum' AS chain,
      *
    FROM
      eth
    UNION all
    SELECT
      'bnb' AS chain,
      *
    FROM
      bnb
  )
SELECT
  p.chain,
  CASE
    when u.swapper IS NULL then 'Not Uniswap V3 Swapper'
    else 'Uniswap V3 Swapper'
  end AS swapper_type,
  count(p.swapper) AS swapper
FROM
  pancake AS p
  LEFT JOIN uni AS u on u.chain = p.chain
  AND u.swapper = p.swapper
GROUP BY
  1,
  2