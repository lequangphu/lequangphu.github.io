WITH
swap AS (
SELECT
date_trunc('hour', block_timestamp) AS blocktime,
CASE
WHEN block_timestamp BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-10 18:00:00.000' THEN 'Before Depeg'
WHEN block_timestamp BETWEEN '2023-03-14 20:00:00.000' AND '2023-03-18 20:00:00.000' THEN 'After Depeg'
ELSE 'During Depeg' END AS period,
symbol_out,
symbol_in,
COALESCE(amount_out_usd, amount_in_usd, 0) AS amount_usd
FROM ethereum.core.ez_dex_swaps AS s
WHERE block_timestamp BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-18 20:00:00.000'
),
top AS (
SELECT symbol_out, sum(amount_usd) AS vol
FROM swap
WHERE period = 'During Depeg'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 4
),
swap_from AS (
SELECT
period,
CASE WHEN symbol_in in (SELECT symbol_out FROM top) THEN symbol_in ELSE 'Other Coins' END AS swap_from,
sum(amount_usd) AS vol
FROM swap
GROUP BY 1,2
),
swap_to AS (
SELECT
period,
CASE WHEN symbol_out in (SELECT symbol_out FROM top) THEN symbol_out ELSE 'Other Coins' END AS swap_to,
sum(amount_usd) AS vol
FROM swap
GROUP BY 1,2
)
SELECT t.period, t.swap_to, t.vol, t.vol - f.vol AS net_vol
FROM swap_to AS t
JOIN swap_from AS f ON t.period = f.period AND t.swap_to = f.swap_from