with
  _txs AS (
    SELECT
      BLOCK_TIMESTAMP,
      FROM_ADDRESS,
      TO_ADDRESS,
      TX_HASH
    FROM
      base.goerli.fact_transactions
    WHERE
      STATUS = 'SUCCESS'
      AND BLOCK_TIMESTAMP < CASE WHEN CURRENT_DATE < '2023-03-27' THEN CURRENT_DATE ELSE '2023-03-27' END
  ),
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
      AND BLOCK_TIMESTAMP < CASE WHEN CURRENT_DATE < '2023-03-27' THEN CURRENT_DATE ELSE '2023-03-27' END
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
      DATEDIFF('day', first_deployed_time, CURRENT_DATE) AS age
    FROM
      _deployed_txs
  ),
  _adopted_devs AS (
    SELECT DISTINCT
      t.BLOCK_TIMESTAMP,
      t.TO_ADDRESS,
      d.FROM_ADDRESS
    FROM
      _txs t
      LEFT JOIN _deployed_txs d USING (TO_ADDRESS)
    WHERE
      d.TO_ADDRESS IS NOT NULL
      AND t.FROM_ADDRESS != d.FROM_ADDRESS
  ),
  _count_dContractPerDev AS (
    SELECT
      FROM_ADDRESS,
      age,
      COUNT(TO_ADDRESS) AS contracts,
      ROUND(contracts / age, 1) AS deploy_freq
    FROM
      _deployed_devs
    GROUP BY
      1,
      2
  )
SELECT
  deploy_freq,
  contracts,
  COUNT(FROM_ADDRESS) AS devs
FROM
  (
    SELECT
      a.FROM_ADDRESS,
      deploy_freq,
      COUNT(DISTINCT TO_ADDRESS) AS contracts
    FROM
      _adopted_devs a
      JOIN _count_dContractPerDev d USING (FROM_ADDRESS)
    GROUP BY
      1,
      2
  )
GROUP BY
  1,
  2