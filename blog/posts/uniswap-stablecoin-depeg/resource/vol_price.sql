with
  price AS (
    SELECT
      hour,
      name,
      price
    FROM
      crosschain.core.fact_hourly_prices AS p
      JOIN crosschain.core.dim_asset_metadata AS m USING (provider, token_address)
    WHERE
      1 = 1
      AND blockchain = 'ethereum'
      AND provider = 'coinmarketcap'
      AND name IN ('USD Coin', 'Dai Stablecoin', 'Tether USD')
      AND hour BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-18 20:00:00.000'
    ORDER BY
      hour
  ),
  price_usdc AS (
    SELECT
      hour,
      price
    FROM
      price
    WHERE
      name = 'USD Coin'
  ),
  price_tether AS (
    SELECT
      hour,
      price
    FROM
      price
    WHERE
      name = 'Tether USD'
  ),
  price_dai AS (
    SELECT
      hour,
      price
    FROM
      price
    WHERE
      name = 'Dai Stablecoin'
  ),
  vol AS (
    SELECT
      DATE_TRUNC('HOUR', BLOCK_TIMESTAMP) AS blocktime,
      SUM(COALESCE(amount_out_usd, amount_in_usd, 0)) AS vol
    FROM
      ethereum.core.ez_dex_swaps
    WHERE
      BLOCK_TIMESTAMP BETWEEN '2023-03-06 18:00:00.000' AND '2023-03-18 20:00:00.000'
    GROUP BY
      1
  )
SELECT
  blocktime,
  vol,
  p1.price AS price_usdc,
  p2.price AS price_tether,
  p3.price AS price_dai
FROM
  vol AS v
  JOIN price_usdc AS p1 ON v.blocktime = p1.hour
  JOIN price_tether AS p2 ON v.blocktime = p2.hour
  JOIN price_dai AS p3 ON v.blocktime = p3.hour