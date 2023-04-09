WITH
  stable AS (
    SELECT
      s.symbol
    FROM
      external.defillama.dim_stablecoins AS s
    WHERE
      1 = 1
      AND array_contains('Ethereum'::variant, s.chains)
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
  )
SELECT
  blocktime,
  CASE
    WHEN symbol_out IN ('USDC', 'DAI', 'USDT') THEN symbol_out
    ELSE 'Other Coins'
  END AS swap_to,
  sum(amount_usd) AS vol,
  sum(vol) over (
    partition by
      blocktime
  ) AS ttl_vol,
  vol / ttl_vol AS pct_vol
FROM
  swap
WHERE
  symbol_out IN (
    SELECT
      *
    FROM
      stable
  )
GROUP BY
  1,
  2