with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
  eth AS (
    with
      lp_action AS (
        SELECT
          l.block_timestamp::date AS day,
          l.action,
          sum(l.amount0_usd + l.amount1_usd) AS amount_usd,
          count(DISTINCT l.liquidity_provider) AS lp
        FROM
          ethereum.uniswapv3.ez_lp_actions AS l
        GROUP BY
          1,
          2
      ),
      increase_lp AS (
        SELECT
          day,
          amount_usd,
          lp
        FROM
          lp_action
        WHERE
          action = 'INCREASE_LIQUIDITY'
      ),
      decrease_lp AS (
        SELECT
          day,
          amount_usd,
          lp
        FROM
          lp_action
        WHERE
          action = 'DECREASE_LIQUIDITY'
      ),
      lp AS (
        SELECT
          nvl(i.day, d.day) AS day,
          nvl(i.amount_usd, 0) - nvl(d.amount_usd, 0) AS net_vl,
          i.lp AS increase_lp,
          d.lp AS decrease_lp,
          nvl(i.lp, 0) - nvl(d.lp, 0) AS net_lp
        FROM
          increase_lp AS i
          FULL JOIN decrease_lp AS d on d.day = i.day
      )
    SELECT
      day,
      net_vl,
      sum(net_vl) over (
        ORDER BY
          day rows BETWEEN unbounded preceding
          AND current row
      ) AS avl,
      increase_lp,
      decrease_lp,
      net_lp
    FROM
      lp
      JOIN dates AS d
    WHERE
      1 = 1
      AND day >= d.start_date
      AND day <= d.end_date
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
      lp_tx AS (
        SELECT DISTINCT
          l.event_name AS action,
          l.tx_hash
        FROM
          bsc.core.fact_event_logs AS l
          JOIN dates AS d
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
          AND l.contract_address IN (
            '0x71479cf279bc2fcf5b8faa8c9eed2ab59127ab95',
            '0x7b8a01b39d58278b5de7e48c8449c9f4f5170613'
          ) -- Uniswap V3 Positions NFT-V1
          AND l.event_name IN ('IncreaseLiquidity', 'DecreaseLiquidity')
      ),
      increase_lp AS (
        SELECT
          t.block_timestamp::date AS day,
          sum(t.amount_usd) AS vl,
          count(DISTINCT t.origin_from_address) AS lp
        FROM
          bsc.core.ez_token_transfers AS t
          JOIN lp_tx AS l on l.tx_hash = t.tx_hash
          AND l.action = 'IncreaseLiquidity'
          JOIN pool AS p on p.pool = t.to_address
        WHERE
          1 = 1
          AND t.symbol != 'BTCBR' -- wrong data
        GROUP BY
          1
      ),
      decrease_lp AS (
        SELECT
          t.block_timestamp::date AS day,
          sum(t.amount_usd) AS vl,
          count(DISTINCT t.origin_from_address) AS lp
        FROM
          bsc.core.ez_token_transfers AS t
          JOIN lp_tx AS l on l.tx_hash = t.tx_hash
          AND l.action = 'DecreaseLiquidity'
          JOIN pool AS p on p.pool = t.from_address
        WHERE
          1 = 1
          AND t.symbol != 'BTCBR' -- wrong data
        GROUP BY
          1
      ),
      lp AS (
        SELECT
          nvl(i.day, d.day) AS day,
          nvl(i.vl, 0) - nvl(d.vl, 0) AS net_vl,
          i.lp AS increase_lp,
          d.lp AS decrease_lp,
          nvl(i.lp, 0) - nvl(d.lp, 0) AS net_lp
        FROM
          increase_lp AS i
          FULL JOIN decrease_lp AS d on d.day = i.day
      )
    SELECT
      day,
      net_vl,
      sum(net_vl) over (
        ORDER BY
          day rows BETWEEN unbounded preceding
          AND current row
      ) AS avl,
      increase_lp,
      decrease_lp,
      net_lp
    FROM
      lp
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