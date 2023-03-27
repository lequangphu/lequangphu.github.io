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
      AND BLOCK_TIMESTAMP < CURRENT_DATE
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
      AND BLOCK_TIMESTAMP < CURRENT_DATE
  ),
  _count_deployed_devs AS (
    SELECT
      blocktime,
      count(FROM_ADDRESS) AS devs,
      sum(devs) over (
        ORDER BY
          blocktime
      ) AS agg_devs
    FROM
      (
        SELECT
          BLOCK_TIMESTAMP::date AS blocktime,
          FROM_ADDRESS,
          rank() over (
            partition by
              FROM_ADDRESS
            order by
              BLOCK_TIMESTAMP
          ) rank
        FROM
          _deployed_txs
      )
    WHERE
      rank = 1
    GROUP BY
      1
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
  _count_adopted_devs AS (
    SELECT
      blocktime,
      count(FROM_ADDRESS) AS devs,
      sum(devs) over (
        ORDER BY
          blocktime
      ) AS agg_devs
    FROM
      (
        SELECT
          BLOCK_TIMESTAMP::date AS blocktime,
          FROM_ADDRESS,
          rank() over (
            partition by
              FROM_ADDRESS
            order by
              BLOCK_TIMESTAMP
          ) rank
        FROM
          _adopted_devs
      )
    WHERE
      rank = 1
    GROUP BY
      1
  )
SELECT
  blocktime,
  'Deployed Developers' AS grp,
  devs,
  agg_devs
FROM
  _count_deployed_devs
union all
SELECT
  blocktime,
  'Adopted Developers' AS grp,
  devs,
  agg_devs
FROM
  _count_adopted_devs