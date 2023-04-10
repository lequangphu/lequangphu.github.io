with
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
      date_trunc('hour', block_timestamp) AS blocktime,
      CASE
        WHEN platform ILIKE '%uniswap%' THEN 'Uniswap'
        WHEN platform = 'curve' THEN 'Curve'
        ELSE 'Other Dexs'
      END dex,
      CASE
        WHEN block_timestamp >= '2023-03-07 15:00:00.000'
        AND block_timestamp <= '2023-03-10 15:00:00.000' THEN 'Before Depeg'
        WHEN block_timestamp >= '2023-03-13 17:00:00.000'
        AND block_timestamp <= '2023-03-16 17:00:00.000' THEN 'After Depeg'
        ELSE 'During Depeg'
      END AS period,
      symbol_in,
      symbol_out,
      COALESCE(amount_out_usd, amount_in_usd, 0) AS amount_usd
    FROM
      ethereum.core.ez_dex_swaps
    WHERE
      1 = 1
      AND BLOCK_TIMESTAMP BETWEEN '2023-03-07 15:00:00.000' AND '2023-03-16 17:00:00.000'
  ),
  top_target AS (
    SELECT
      symbol_out AS symbol,
      sum(amount_usd) AS vol
    FROM
      swap
    GROUP BY
      1
    ORDER BY
      2 DESC
    LIMIT
      4
  ),
  join_swap_stable AS (
    SELECT
      blocktime,
      dex,
      period,
      amount_usd,
      s1.symbol IS NOT NULL AS from_stable,
      s2.symbol IS NOT NULL AS to_stable,
      CASE
        WHEN from_stable
        and to_stable THEN 'Stable ↔️ Stable'
        WHEN from_stable
        or to_stable THEN 'Stable ↔️ Non-stable'
        ELSE 'Non-stable ↔️ Non-stable'
      END AS pool,
      t1.symbol IS NOT NULL AS from_top_target,
      t2.symbol IS NOT NULL AS to_top_target,
      CASE
        WHEN from_top_target THEN symbol_in
        ELSE 'Other Coins'
      END symbol_in,
      CASE
        WHEN to_top_target THEN symbol_out
        ELSE 'Other Coins'
      END symbol_out
    FROM
      swap AS s
      LEFT JOIN stable AS s1 ON s1.symbol = s.symbol_in
      LEFT JOIN stable AS s2 ON s2.symbol = s.symbol_out
      LEFT JOIN top_target AS t1 ON t1.symbol = s.symbol_in
      LEFT JOIN top_target AS t2 ON t2.symbol = s.symbol_out
  )
SELECT
  blocktime,
  dex,
  period,
  pool,
  from_stable,
  to_stable,
  symbol_in,
  symbol_out,
  sum(amount_usd) AS vol
FROM
  join_swap_stable
GROUP BY
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8