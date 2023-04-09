WITH
  swap AS (
    SELECT
      date_trunc('hour', block_timestamp) AS blocktime,
      symbol_out,
      coalesce(amount_out_usd, amount_in_usd, 0) amount_usd
    FROM
      ethereum.core.ez_dex_swaps
    WHERE
      block_timestamp BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-18 20:00:00.000'
  ),
  top AS (
    SELECT
      symbol_out,
      sum(amount_usd) AS vol
    FROM
      swap
    GROUP BY
      1
    ORDER BY
      2 DESC
    LIMIT
      4
  )
SELECT
  blocktime,
  CASE
    WHEN symbol_out in (
      SELECT
        symbol_out
      FROM
        top
    ) THEN symbol_out
    ELSE 'Other Coins'
  END AS swap_to,
  sum(amount_usd) AS vol
FROM
  swap
GROUP BY
  1,
  2