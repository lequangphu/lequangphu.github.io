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
          s.recipient,
          min(s.block_timestamp::date) AS first_day
        FROM
          ethereum.uniswapv3.ez_swaps AS s
        GROUP BY
          1
      ),
      swap AS (
        SELECT
          s.block_timestamp::date AS day,
          s.pool_address,
          CASE
            when s.amount0_usd < 0 then s.amount0_usd
            else s.amount1_usd
          end AS amount_usd,
          CASE
            when amount_usd < 0 then - amount_usd
            else amount_usd
          end AS amount_usd_adj,
          amount_usd_adj * p.fee_percent / 100 AS fee,
          s.recipient,
          f.first_day
        FROM
          ethereum.uniswapv3.ez_swaps AS s
          JOIN dates AS d
          JOIN ethereum.uniswapv3.ez_pools AS p on p.pool_address = s.pool_address
          JOIN first_day AS f on f.recipient = s.recipient
        WHERE
          1 = 1
          AND s.block_timestamp::date >= d.start_date
          AND s.block_timestamp::date <= d.end_date
          AND f.first_day >= d.start_date
      )
    SELECT
      day,
      sum(amount_usd_adj) AS vol,
      sum(fee) AS fee,
      count(
        DISTINCT CASE
          when day = first_day then s.recipient
        end
      ) AS new_swapper,
      sum(new_swapper) over (
        order by
          day rows BETWEEN unbounded preceding
          AND current row
      ) agg_swapper
    FROM
      swap AS s
    GROUP BY
      1
  ),
  bnb AS (
    with
      pool AS (
        SELECT
          l.event_inputs:pool AS pool,
          l.event_inputs:fee / 1e4 AS fee_percent,
          l.event_inputs:token0 AS token0,
          l.event_inputs:token1 AS token1
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
      ),
      first_day AS (
        SELECT
          l.event_inputs:recipient AS recipient,
          min(l.block_timestamp::date) AS first_day
        FROM
          bsc.core.fact_event_logs AS l
          JOIN pool AS p on p.pool = l.contract_address
          AND l.event_name = 'Swap'
        GROUP BY
          1
      )
    SELECT
      t.block_timestamp::date AS day,
      sum(t.amount_usd) AS vol,
      sum(t.amount_usd * p.fee_percent / 100) AS fee,
      count(
        DISTINCT CASE
          when t.block_timestamp::date = f.first_day then l.event_inputs:recipient
        end
      ) AS new_swapper,
      sum(new_swapper) over (
        order by
          day rows BETWEEN unbounded preceding
          AND current row
      ) agg_swapper
    FROM
      bsc.core.ez_token_transfers AS t
      JOIN dates AS d
      JOIN bsc.core.fact_event_logs AS l on l.tx_hash = t.tx_hash
      AND l.event_name = 'Swap'
      AND l.contract_address = t.from_address -- transfer from pool
      JOIN pool AS p on p.pool = t.from_address
      JOIN first_day AS f on f.recipient = l.event_inputs:recipient
    WHERE
      1 = 1
      AND t.block_timestamp::date >= d.start_date
      AND t.block_timestamp::date <= d.end_date
      AND t.symbol != 'BTCBR' -- wrong price
      AND f.first_day >= d.start_date
    GROUP BY
      1
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