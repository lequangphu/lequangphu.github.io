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
  _count_dc AS (
    SELECT
      blocktime,
      count(TO_ADDRESS) AS contracts,
      sum(contracts) over (
        ORDER BY
          blocktime
      ) AS agg_contracts
    FROM
      (
        SELECT
          BLOCK_TIMESTAMP::date AS blocktime,
          TO_ADDRESS,
          rank() over (
            partition by
              TO_ADDRESS
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
  _interacted_contracts AS (
    SELECT
      BLOCK_TIMESTAMP,
      TO_ADDRESS
    FROM
      _txs
    WHERE
      TO_ADDRESS IN (
        SELECT
          TO_ADDRESS
        FROM
          _deployed_txs
      )
      AND TX_HASH NOT IN (
        SELECT
          TX_HASH
        FROM
          _deployed_txs
      )
  ),
  _count_ic AS (
    SELECT
      blocktime,
      count(TO_ADDRESS) AS contracts,
      sum(contracts) over (
        ORDER BY
          blocktime
      ) AS agg_contracts
    FROM
      (
        SELECT
          BLOCK_TIMESTAMP::date AS blocktime,
          TO_ADDRESS,
          rank() over (
            partition by
              TO_ADDRESS
            order by
              BLOCK_TIMESTAMP
          ) rank
        FROM
          _interacted_contracts
      )
    WHERE
      rank = 1
    GROUP BY
      1
  ),
  _adopted_contracts AS (
    SELECT
      BLOCK_TIMESTAMP,
      TO_ADDRESS
    FROM
      _txs t
      LEFT JOIN _deployed_txs d USING (TO_ADDRESS)
    WHERE
      d.TO_ADDRESS IS NOT NULL
      AND t.FROM_ADDRESS != d.FROM_ADDRESS
  ),
  _count_ac AS (
    SELECT
      blocktime,
      count(TO_ADDRESS) AS contracts,
      sum(contracts) over (
        ORDER BY
          blocktime
      ) AS agg_contracts
    FROM
      (
        SELECT
          BLOCK_TIMESTAMP::date AS blocktime,
          TO_ADDRESS,
          rank() over (
            partition by
              TO_ADDRESS
            order by
              BLOCK_TIMESTAMP
          ) rank
        FROM
          _adopted_contracts
      )
    WHERE
      rank = 1
    GROUP BY
      1
  ),
  _d2i AS (
    SELECT
      d.blocktime,
      COALESCE(i.agg_contracts, 0) / d.agg_contracts AS conversion_rate
    FROM
      _count_dc d
      LEFT JOIN _count_ic i USING (blocktime)
  ),
  _i2a AS (
    SELECT
      i.blocktime,
      COALESCE(a.agg_contracts, 0) / i.agg_contracts AS conversion_rate
    FROM
      _count_ic i
      LEFT JOIN _count_ac a USING (blocktime)
  )
SELECT
  blocktime,
  'Deployed to Interacted' grp,
  conversion_rate
FROM
  _d2i
UNION ALL
SELECT
  blocktime,
  'Interacted to Adopted' grp,
  conversion_rate
FROM
  _i2a