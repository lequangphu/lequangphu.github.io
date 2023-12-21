with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
  eth AS (
    with
      pool AS (
        SELECT
          l.decoded_log:fee / 1e4 AS fee_percent,
          l.decoded_log:pool AS pool,
          l.decoded_log:token0 AS token0,
          l.decoded_log:token1 AS token1
        FROM
          ethereum.core.ez_decoded_event_logs AS l
        WHERE
          1 = 1
          AND l.contract_address = '0x0bfbcf9fa4f9c56b0f40a671ad40e0805a091865' -- PancakeSwap: Factory V3
          AND l.event_name = 'PoolCreated'
      ),
      first_day AS (
        SELECT
          l.origin_from_address,
          min(l.block_timestamp::date) AS first_day
        FROM
          ethereum.core.ez_decoded_event_logs AS l
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
          count(DISTINCT t.origin_from_address) AS lp,
          count(
            DISTINCT CASE
              when t.block_timestamp::date = f.first_day then t.origin_from_address
            end
          ) AS new_lp
        FROM
          ethereum.core.ez_token_transfers AS t
          JOIN dates AS d
          JOIN ethereum.core.ez_decoded_event_logs AS l on l.tx_hash = t.tx_hash
          AND l.contract_address = '0x46a15b0b27311cedf172ab29e4f4766fbe7f4364' -- PancakeSwap:Nonfungible Position Manager V3
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
          lp,
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
          lp
        FROM
          r_lp
        WHERE
          action = 'DecreaseLiquidity'
      ),
      lp AS (
        SELECT
          nvl(i.day, d.day) AS day,
          nvl(i.vl, 0) - nvl(d.vl, 0) AS net_vl,
          i.lp AS increase_lp,
          d.lp AS decrease_lp,
          nvl(i.lp, 0) - nvl(d.lp, 0) AS net_lp,
          i.new_lp
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
      net_lp,
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
          l.event_inputs:pool AS pool,
          l.event_inputs:fee / 1e4 AS fee_percent
        FROM
          bsc.core.fact_event_logs AS l
        WHERE
          1 = 1
          AND l.contract_address = '0x0bfbcf9fa4f9c56b0f40a671ad40e0805a091865' -- PancakeSwap: Factory V3
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
          count(DISTINCT t.origin_from_address) AS lp,
          count(
            DISTINCT CASE
              when t.block_timestamp::date = f.first_day then t.origin_from_address
            end
          ) AS new_lp
        FROM
          bsc.core.ez_token_transfers AS t
          JOIN dates AS d
          JOIN bsc.core.fact_event_logs AS l on l.tx_hash = t.tx_hash
          AND l.contract_address = '0x46a15b0b27311cedf172ab29e4f4766fbe7f4364' -- PancakeSwap:Nonfungible Position Manager V3
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
          lp,
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
          lp
        FROM
          r_lp
        WHERE
          action = 'DecreaseLiquidity'
      ),
      lp AS (
        SELECT
          nvl(i.day, d.day) AS day,
          nvl(i.vl, 0) - nvl(d.vl, 0) AS net_vl,
          i.lp AS increase_lp,
          d.lp AS decrease_lp,
          nvl(i.lp, 0) - nvl(d.lp, 0) AS net_lp,
          i.new_lp
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
      net_lp,
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