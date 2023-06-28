with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
  uni AS (
    with
      eth AS (
        with
          first_day AS (
            SELECT
              l.liquidity_provider,
              min(l.block_timestamp::date) AS first_day
            FROM
              ethereum.uniswapv3.ez_lp_actions AS l
            GROUP BY
              1
          ),
          r_lp AS (
            SELECT
              l.block_timestamp::date AS day,
              l.liquidity_provider,
              CASE
                when datediff('day', f.first_day, d.end_date) = 0 then 1
                else datediff('day', f.first_day, d.end_date)
              end AS age,
              sum(
                CASE
                  when l.action = 'INCREASE_LIQUIDITY' then l.amount0_usd + l.amount1_usd
                  else - (l.amount0_usd + l.amount1_usd)
                end
              ) AS net_vl,
              sum(net_vl) over (
                partition BY
                  l.liquidity_provider
                ORDER BY
                  l.block_timestamp::date rows BETWEEN unbounded preceding
                  AND current row
              ) AS tvl
            FROM
              ethereum.uniswapv3.ez_lp_actions AS l
              JOIN dates AS d
              JOIN first_day AS f on f.liquidity_provider = l.liquidity_provider
            WHERE
              1 = 1
              AND l.block_timestamp::date <= d.end_date
              AND f.first_day <= d.end_date
            GROUP BY
              1,
              2,
              3
          ),
          tvl_days AS (
            SELECT
              liquidity_provider AS lp,
              age,
              CASE
                when nvl(tvl, 0) <= 0 then 0
                else tvl
              end tvl,
              count(day) AS days
            FROM
              r_lp
            GROUP BY
              1,
              2,
              3
          )
        SELECT
          lp,
          age,
          round(sum(tvl * days) / age) AS tvl_per_day
        FROM
          tvl_days
        GROUP BY
          1,
          2
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
          ),
          first_day AS (
            SELECT
              l.origin_from_address,
              min(l.block_timestamp::date) AS first_day
            FROM
              bsc.core.fact_event_logs AS l
              JOIN pool AS p on p.pool = l.contract_address
              AND l.event_name = 'Mint'
            GROUP BY
              1
          ),
          r_lp AS (
            SELECT
              t.block_timestamp::date AS day,
              t.origin_from_address AS liquidity_provider,
              CASE
                when datediff('day', f.first_day, d.end_date) = 0 then 1
                else datediff('day', f.first_day, d.end_date)
              end AS age,
              sum(
                CASE
                  when l.event_name = 'IncreaseLiquidity' then t.amount_usd
                  else - t.amount_usd
                end
              ) AS net_vl,
              sum(net_vl) over (
                partition BY
                  t.origin_from_address
                ORDER BY
                  t.block_timestamp::date rows BETWEEN unbounded preceding
                  AND current row
              ) AS tvl
            FROM
              bsc.core.ez_token_transfers AS t
              JOIN dates AS d
              JOIN bsc.core.fact_event_logs AS l on l.tx_hash = t.tx_hash
              AND l.contract_address IN (
                '0x71479cf279bc2fcf5b8faa8c9eed2ab59127ab95',
                '0x7b8a01b39d58278b5de7e48c8449c9f4f5170613'
              ) -- Uniswap V3 Positions NFT-V1
              AND l.event_name IN ('IncreaseLiquidity', 'DecreaseLiquidity')
              JOIN first_day AS f on f.origin_from_address = t.origin_from_address
              AND f.first_day >= d.start_date
              LEFT JOIN pool AS pi on pi.pool = t.to_address
              AND l.event_name = 'IncreaseLiquidity'
              LEFT JOIN pool AS pd on pd.pool = t.from_address
              AND l.event_name = 'DecreaseLiquidity'
            WHERE
              1 = 1
              AND t.block_timestamp::date <= d.end_date
              AND f.first_day <= d.end_date
              AND nvl(pi.pool, pd.pool) IS NOT NULL
              AND t.symbol != 'BTCBR' -- wrong price
            GROUP BY
              1,
              2,
              3
          ),
          tvl_days AS (
            SELECT
              liquidity_provider AS lp,
              age,
              CASE
                when nvl(tvl, 0) <= 0 then 0
                else tvl
              end tvl,
              count(day) AS days
            FROM
              r_lp
            GROUP BY
              1,
              2,
              3
          )
        SELECT
          lp,
          age,
          round(sum(tvl * days) / age) AS tvl_per_day
        FROM
          tvl_days
        GROUP BY
          1,
          2
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
  u.chain,
  CASE
    when p.lp IS NULL then 'Not Overlap LP'
    else 'Overlap LP'
  end AS lp_type,
  age,
  tvl_per_day,
  count(u.lp) AS lp
FROM
  uni AS u
  LEFT JOIN pancake AS p on p.chain = u.chain
  AND p.lp = u.lp
GROUP BY
  1,
  2,
  3,
  4