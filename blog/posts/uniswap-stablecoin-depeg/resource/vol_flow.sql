WITH
  swap AS (
    SELECT
      date_trunc('hour', block_timestamp) AS blocktime,
      CASE
        WHEN block_timestamp >= '2023-03-07 15:00:00.000'
        AND block_timestamp <= '2023-03-10 15:00:00.000' THEN 'Before Depeg'
        WHEN block_timestamp >= '2023-03-13 17:00:00.000'
        AND block_timestamp <= '2023-03-16 17:00:00.000' THEN 'After Depeg'
        ELSE 'During Depeg'
      END AS period,
      CASE
        WHEN platform ilike 'uniswap%' THEN 'Uniswap'
        WHEN platform = 'curve' then 'Curve'
        ELSE 'Other Dexs'
      END AS platform,
      symbol_out,
      symbol_in,
      COALESCE(amount_out_usd, amount_in_usd, 0) AS amount_usd
    FROM
      ethereum.core.ez_dex_swaps AS s
    WHERE
      BLOCK_TIMESTAMP BETWEEN '2023-03-07 15:00:00.000' AND '2023-03-16 17:00:00.000'
  ),
  top AS (
    SELECT
      platform,
      symbol_out,
      sum(amount_usd) AS vol,
      rank() over (
        partition by
          platform
        order by
          vol desc
      ) AS rank
    FROM
      swap
    WHERE
      period = 'During Depeg'
    GROUP BY
      1,
      2
  )
SELECT
  s.platform,
  period,
  CASE
    WHEN t1.symbol_out IS NOT NULL THEN symbol_in
    ELSE 'Other Coins'
  END AS swap_from,
  CASE
    WHEN t2.symbol_out IS NOT NULL THEN s.symbol_out
    ELSE 'Other Coins'
  END AS swap_to,
  sum(amount_usd) AS vol
FROM
  swap AS s
  LEFT JOIN top AS t1 ON t1.platform = s.platform
  AND t1.symbol_out = s.symbol_in
  AND t1.rank <= 4
  LEFT JOIN top AS t2 ON t2.platform = s.platform
  AND t2.symbol_out = s.symbol_out
  AND t2.rank <= 4
GROUP BY
  1,
  2,
  3,
  4