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