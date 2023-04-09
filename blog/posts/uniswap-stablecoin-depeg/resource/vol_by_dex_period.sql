SELECT
  CASE
WHEN s.block_timestamp BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-10 18:00:00.000' THEN 'Before Depeg'
WHEN s.block_timestamp BETWEEN '2023-03-14 20:00:00.000' AND '2023-03-18 20:00:00.000' THEN 'After Depeg'
ELSE 'During Depeg' END AS period,
  CASE
    WHEN s.platform ILIKE '%uniswap%' THEN 'Uniswap'
    WHEN s.platform = 'curve' THEN 'Curve'
    ELSE 'Other Dexs'
  END dex,
  SUM(COALESCE(amount_out_usd, amount_in_usd, 0)) AS vol
FROM
  ethereum.core.ez_dex_swaps AS s
WHERE
  1 = 1
  AND BLOCK_TIMESTAMP BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-18 20:00:00.000'
GROUP BY
  1,
  2