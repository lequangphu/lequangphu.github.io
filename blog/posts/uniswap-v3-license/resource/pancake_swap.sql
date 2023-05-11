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
          l.decoded_log:pool AS pool,
          l.decoded_log:fee / 1e4 AS fee_percent
        FROM
          ethereum.core.ez_decoded_event_logs AS l
        WHERE
          1 = 1
          AND l.contract_address = '0x0bfbcf9fa4f9c56b0f40a671ad40e0805a091865' -- PancakeSwap: Factory V3
          AND l.event_name = 'PoolCreated'
      ),
      first_day AS (
        SELECT
          l.decoded_log:recipient AS recipient,
          min(l.block_timestamp::date) AS first_day
        FROM
          ethereum.core.ez_decoded_event_logs AS l
          JOIN pool AS p on p.pool = l.contract_address
          AND l.event_name = 'Swap'
        GROUP BY
          1
      )
    SELECT
      t.block_timestamp::date AS day,
      sum(t.amount_usd) AS vol,
      sum(t.amount_usd * p.fee_percent / 100) AS fee,
      count(DISTINCT l.decoded_log:recipient) AS swapper,
      count(
        DISTINCT CASE
          when t.block_timestamp::date = f.first_day then l.decoded_log:recipient
        end
      ) AS new_swapper,
      sum(new_swapper) over (
        ORDER BY
          t.block_timestamp::date rows BETWEEN unbounded preceding
          AND current row
      ) agg_swapper
    FROM
      ethereum.core.ez_token_transfers AS t
      JOIN dates AS d
      JOIN ethereum.core.ez_decoded_event_logs AS l on l.tx_hash = t.tx_hash
      AND l.contract_address = t.from_address
      AND l.event_name = 'Swap'
      JOIN pool AS p on p.pool = l.contract_address
      JOIN first_day AS f on f.recipient = l.decoded_log:recipient
    WHERE
      1 = 1
      AND t.block_timestamp::date >= d.start_date
      AND t.block_timestamp::date <= d.end_date
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
        WHERE
          l.topics[0] = '0x19b47279256b2a23a1665c810c8d55a1758940ee09377d4f8d26497a3577dc83' -- Swap
        GROUP BY
          1
      )
    SELECT
      t.block_timestamp::date AS day,
      sum(t.amount_usd) AS vol,
      sum(t.amount_usd * p.fee_percent / 100) AS fee,
      count(DISTINCT t.origin_from_address) AS swapper,
      count(
        DISTINCT CASE
          when t.block_timestamp::date = f.first_day then t.origin_from_address
        end
      ) AS new_swapper,
      sum(new_swapper) over (
        ORDER BY
          t.block_timestamp::date rows BETWEEN unbounded preceding
          AND current row
      ) agg_swapper
    FROM
      bsc.core.ez_token_transfers AS t
      JOIN dates AS d
      JOIN bsc.core.fact_event_logs AS l on l.tx_hash = t.tx_hash
      AND l.contract_address = t.from_address
      AND l.topics[0] = '0x19b47279256b2a23a1665c810c8d55a1758940ee09377d4f8d26497a3577dc83' -- Swap
      JOIN pool AS p on p.pool = l.contract_address
      JOIN first_day AS f on f.origin_from_address = t.origin_from_address
    WHERE
      1 = 1
      AND t.block_timestamp::date >= d.start_date
      AND t.block_timestamp::date <= d.end_date
      AND t.symbol != 'BTCBR' -- wrong data
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