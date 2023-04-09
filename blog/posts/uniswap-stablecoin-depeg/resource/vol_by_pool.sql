WITH
stable AS (
SELECT s.symbol
FROM external.defillama.dim_stablecoins AS s
WHERE 1=1
AND array_contains('Ethereum'::variant, s.chains)
)
SELECT 
date_trunc('hour', s.block_timestamp) AS blocktime, 
CASE 
WHEN s1.symbol IS NOT NULL AND s2.symbol IS NOT NULL THEN 'Stable <-> Stable'
WHEN coalesce(s1.symbol, s2.symbol) IS NOT NULL THEN 'Stable <-> Non-stable'
ELSE 'Non-stable <-> Non-stable'
END AS pool,
sum(coalesce(s.amount_out_usd, s.amount_in_usd, 0)) AS vol
FROM ethereum.core.ez_dex_swaps AS s
LEFT JOIN stable AS s1 ON s1.symbol = s.symbol_in
LEFT JOIN stable AS s2 ON s2.symbol = s.symbol_out
WHERE s.block_timestamp BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-18 20:00:00.000'
GROUP BY 1,2