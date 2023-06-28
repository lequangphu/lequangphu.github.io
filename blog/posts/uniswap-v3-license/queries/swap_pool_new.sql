with
  dates AS (
    SELECT
      '2023-04-01' AS start_date,
      '2023-04-30' AS end_date
  ),
  first_day AS (
    SELECT
      s.recipient,
      min(s.block_timestamp::date) AS first_day
    FROM
      ethereum.uniswapv3.ez_swaps AS s
    GROUP BY
      1
  ),
  swap AS (
    SELECT
      s.block_timestamp::date AS day,
      concat(s.token0_symbol, '<>', s.token1_symbol) AS pool,
      s.recipient,
      f.first_day
    FROM
      ethereum.uniswapv3.ez_swaps AS s
      JOIN dates AS d
      JOIN first_day AS f on f.recipient = s.recipient
    WHERE
      1 = 1
      AND s.block_timestamp::date >= d.start_date
      AND s.block_timestamp::date <= d.end_date
  )
SELECT
  day,
  CASE
    when pool IN (
      'PEPE<>WETH',
      'WETH<>FADE',
      'MEMEME<>WETH',
      'WOJAK<>WETH'
    ) then 'Meme Pools'
    else 'Other Pools'
  end AS pool,
  count(
    DISTINCT CASE
      when day = first_day then s.recipient
    end
  ) AS new_swapper,
  count(DISTINCT s.recipient) AS swapper,
  new_swapper / swapper AS new_swapper_percent
FROM
  swap AS s
GROUP BY
  1,
  2