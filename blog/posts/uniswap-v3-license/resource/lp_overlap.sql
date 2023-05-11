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
          l.liquidity_provider AS lp
        FROM
          ethereum.uniswapv3.ez_lp_actions AS l
          JOIN dates AS d
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
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
              AND l.block_number >= 25632913 -- first block has pool created event
              AND l.contract_address IN (
                '0x128ce3a3d48f27ce35a3f810cf2cddd2f6879b13',
                '0xdb1d10011ad0ff90774d0c6bb92e5c5c8b4461f7'
              ) -- Uniswap V3: Factory
              AND l.event_name = 'PoolCreated'
          )
        SELECT DISTINCT
          l.origin_from_address AS lp
        FROM
          bsc.core.fact_event_logs AS l
          JOIN pool AS p on p.pool = l.contract_address
          AND l.event_name = 'Mint'
          JOIN dates AS d
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
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
          l.origin_from_address AS lp
        FROM
          ethereum.core.ez_decoded_event_logs AS l
          JOIN pool AS p on p.pool = l.contract_address
          AND l.event_name = 'Mint'
          JOIN dates AS d
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
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
          l.origin_from_address AS lp
        FROM
          bsc.core.fact_event_logs AS l
          JOIN pool AS p on p.pool = l.contract_address
          AND l.event_name = 'Mint'
          JOIN dates AS d
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
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
    when u.lp IS NULL then 'Not Uniswap V3 LP'
    else 'Uniswap V3 LP'
  end AS lp_type,
  count(p.lp) AS lp
FROM
  pancake AS p
  LEFT JOIN uni AS u on u.chain = p.chain
  AND u.lp = p.lp
GROUP BY
  1,
  2