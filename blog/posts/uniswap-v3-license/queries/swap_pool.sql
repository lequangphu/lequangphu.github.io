with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
  eth AS (
    with
      swap AS (
        SELECT
          s.block_timestamp::date AS day,
          concat(s.token0_symbol, '<>', s.token1_symbol) AS pool,
          s.recipient
        FROM
          ethereum.uniswapv3.ez_swaps AS s
          JOIN dates AS d
        WHERE
          1 = 1
          AND s.block_timestamp::date >= d.start_date
          AND s.block_timestamp::date <= d.end_date
      )
    SELECT
      day,
      CASE
        when pool IN (
          'PEPE<>WETH',
          'WETH<>FADE',
          'MEMEME<>WETH',
          'WOJAK<>WETH'
        ) then pool
        else 'Other pools'
      end AS pool,
      count(DISTINCT s.recipient) AS swapper
    FROM
      swap AS s
    GROUP BY
      1,
      2
  ),
  bnb AS (
    with
      pool AS (
        SELECT
          l.event_inputs:pool AS pool,
          a0.symbol AS token0_symbol,
          a1.symbol AS token1_symbol
        FROM
          bsc.core.fact_event_logs AS l
          JOIN crosschain.core.ez_asset_metadata AS a0 on a0.blockchain = 'bsc'
          AND a0.token_address = l.event_inputs:token0
          JOIN crosschain.core.ez_asset_metadata AS a1 on a1.blockchain = 'bsc'
          AND a1.token_address = l.event_inputs:token1
        WHERE
          1 = 1
          AND l.block_number >= 25632913
          AND l.contract_address IN (
            '0x128ce3a3d48f27ce35a3f810cf2cddd2f6879b13',
            '0xdb1d10011ad0ff90774d0c6bb92e5c5c8b4461f7'
          ) -- Uniswap V3: Factory
          AND l.event_name = 'PoolCreated'
      ),
      swap AS (
        SELECT
          t.block_timestamp::date AS day,
          concat(token0_symbol, '<>', token1_symbol) AS pool,
          l.event_inputs:recipient AS swapper
        FROM
          bsc.core.ez_token_transfers AS t
          JOIN dates AS d
          JOIN bsc.core.fact_event_logs AS l on l.tx_hash = t.tx_hash
          AND l.event_name = 'Swap'
          AND l.contract_address = t.from_address -- transfer from pool
          JOIN pool AS p on p.pool = t.from_address
        WHERE
          1 = 1
          AND t.block_timestamp::date >= d.start_date
          AND t.block_timestamp::date <= d.end_date
          AND t.symbol != 'BTCBR' -- wrong price data
      )
    SELECT
      day,
      CASE
        when pool IN ('USDC<>WBNB', 'USDT<>USDC', 'USDT<>WBNB') then pool
        else 'Other Pools'
      end AS pool,
      count(DISTINCT swapper) AS swapper
    FROM
      swap
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