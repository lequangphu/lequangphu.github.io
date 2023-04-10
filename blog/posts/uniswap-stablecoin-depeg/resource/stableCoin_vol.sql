WITH
  stable AS (
    SELECT DISTINCT
      symbol
    FROM
      external.defillama.dim_stablecoins,
      lateral flatten(chains) AS f
    WHERE
      1 = 1
      AND f.value = 'Ethereum'
  ),
  swap AS (
    SELECT
      date_trunc('day', block_timestamp) AS blocktime,
      symbol_in,
      symbol_out,
      coalesce(amount_out_usd, amount_in_usd, 0) amount_usd
    FROM
      ethereum.core.ez_dex_swaps
    WHERE
      block_timestamp BETWEEN '2023-03-01' AND CASE
        WHEN CURRENT_DATE <= '2023-04-12' THEN dateadd('day', -1, CURRENT_DATE)
        ELSE dateadd('day', -1, '2023-04-12')
      END
  ),
  swap_from AS (
    SELECT
      blocktime,
      CASE
        WHEN symbol_in IN ('USDC', 'DAI', 'USDT') THEN symbol_in
        ELSE 'Other Coins'
      END AS symbol,
      sum(amount_usd) AS vol,
      sum(vol) over (
        partition by
          blocktime
      ) AS ttl_vol,
      vol / ttl_vol AS pct_vol
    FROM
      swap AS s
      JOIN stable AS t ON t.symbol = s.symbol_in
    GROUP BY
      1,
      2
  ),
  swap_to AS (
    SELECT
      blocktime,
      CASE
        WHEN symbol_out IN ('USDC', 'DAI', 'USDT') THEN symbol_out
        ELSE 'Other Coins'
      END AS symbol,
      sum(amount_usd) AS vol,
      sum(vol) over (
        partition by
          blocktime
      ) AS ttl_vol,
      vol / ttl_vol AS pct_vol
    FROM
      swap AS s
      JOIN stable AS t ON t.symbol = s.symbol_out
    GROUP BY
      1,
      2
  )
SELECT
  'Swap-from' AS direction,
  *
FROM
  swap_from
UNION ALL
SELECT
  'Swap-to',
  *
FROM
  swap_to