with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
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
      lp_action AS (
        SELECT
          l.block_timestamp::date AS day,
          l.action,
          sum(l.amount0_usd + l.amount1_usd) AS amount_usd,
          count(DISTINCT l.liquidity_provider) AS lp,
          count(
            DISTINCT CASE
              when l.block_timestamp::date = f.first_day then l.liquidity_provider
            end
          ) AS new_lp
        FROM
          ethereum.uniswapv3.ez_lp_actions AS l
          JOIN dates AS d
          JOIN first_day AS f on f.liquidity_provider = l.liquidity_provider
        WHERE
          1 = 1
          AND l.block_timestamp::date >= d.start_date
          AND l.block_timestamp::date <= d.end_date
          AND f.first_day >= d.start_date
        GROUP BY
          1,
          2
      ),
      increase_lp AS (
        SELECT
          day,
          amount_usd,
          new_lp
        FROM
          lp_action
        WHERE
          action = 'INCREASE_LIQUIDITY'
      ),
      decrease_lp AS (
        SELECT
          day,
          amount_usd
        FROM
          lp_action
        WHERE
          action = 'DECREASE_LIQUIDITY'
      ),
      lp AS (
        SELECT
          nvl(i.day, d.day) AS day,
          nvl(i.amount_usd, 0) - nvl(d.amount_usd, 0) AS net_vl,
          i.new_lp
        FROM
          increase_lp AS i
          FULL JOIN decrease_lp AS d on d.day = i.day
      )
    SELECT
      day,
      sum(net_vl) over (
        ORDER BY
          day rows BETWEEN unbounded preceding
          AND current row
      ) AS avl,
      sum(new_lp) over (
        ORDER BY
          day rows BETWEEN unbounded preceding
          AND current row
      ) AS alp
    FROM
      lp
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
          l.event_name AS action,
          sum(t.amount_usd) AS vl,
          count(
            DISTINCT CASE
              when t.block_timestamp::date = f.first_day then t.origin_from_address
            end
          ) AS new_lp
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
          AND t.block_timestamp::date >= d.start_date
          AND t.block_timestamp::date <= d.end_date
          AND nvl(pi.pool, pd.pool) IS NOT NULL
          AND t.symbol != 'BTCBR' -- wrong price
        GROUP BY
          1,
          2
      ),
      increase_lp AS (
        SELECT
          day,
          vl,
          new_lp
        FROM
          r_lp
        WHERE
          action = 'IncreaseLiquidity'
      ),
      decrease_lp AS (
        SELECT
          day,
          vl,
          new_lp
        FROM
          r_lp
        WHERE
          action = 'DecreaseLiquidity'
      ),
      lp AS (
        SELECT
          nvl(i.day, d.day) AS day,
          nvl(i.vl, 0) - nvl(d.vl, 0) AS net_vl,
          i.new_lp
        FROM
          increase_lp AS i
          FULL JOIN decrease_lp AS d on d.day = i.day
      )
    SELECT
      day,
      sum(net_vl) over (
        ORDER BY
          day rows BETWEEN unbounded preceding
          AND current row
      ) AS avl,
      sum(new_lp) over (
        ORDER BY
          day rows BETWEEN unbounded preceding
          AND current row
      ) AS alp
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