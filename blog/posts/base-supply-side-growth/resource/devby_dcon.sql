with
  _deployed_txs AS (
    SELECT DISTINCT
      BLOCK_TIMESTAMP,
      FROM_ADDRESS,
      TO_ADDRESS,
      TX_HASH
    FROM
      base.goerli.fact_traces
    WHERE
      TX_STATUS = 'SUCCESS'
      AND TYPE ilike 'create%'
      AND BLOCK_TIMESTAMP < CURRENT_DATE
  ),
  _deployed_devs AS (
    SELECT DISTINCT
      FROM_ADDRESS,
      TO_ADDRESS,
      FIRST_VALUE(BLOCK_TIMESTAMP) OVER (
        PARTITION BY
          FROM_ADDRESS
        ORDER BY
          BLOCK_TIMESTAMP
      ) AS first_deployed_time,
      CEIL(DATEDIFF('day', first_deployed_time, CURRENT_DATE) / 7) AS age
    FROM
      _deployed_txs
  )
SELECT
  age,
  contracts,
  COUNT(FROM_ADDRESS) devs
FROM
  (
    SELECT
      FROM_ADDRESS,
      age,
      COUNT(TO_ADDRESS) AS contracts
    FROM
      _deployed_devs
    GROUP BY
      1,
      2
  )
GROUP BY
  1,
  2