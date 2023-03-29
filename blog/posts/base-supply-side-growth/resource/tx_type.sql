WITH
  _deployed_txs AS (
    SELECT DISTINCT
      TX_HASH
    FROM
      base.goerli.fact_traces
    WHERE
      TX_STATUS = 'SUCCESS'
      AND TYPE ilike 'create%'
      AND BLOCK_TIMESTAMP < CASE WHEN CURRENT_DATE < '2023-03-27' THEN CURRENT_DATE ELSE '2023-03-27' END
  )
SELECT
  CASE
    when IS_SYSTEM_TX then 'System Transaction'
    when NOT IS_SYSTEM_TX
    AND TX_HASH IN (
      SELECT
        *
      FROM
        _deployed_txs
    ) then 'Deploy Contract Transaction'
    else 'Normal Transaction'
  end AS tx_type,
  count(*) AS txs,
  sum(txs) over () AS total_txs,
  txs / total_txs AS txs_pct
FROM
  base.goerli.fact_transactions
WHERE
  STATUS = 'SUCCESS'
  AND BLOCK_TIMESTAMP < CASE WHEN CURRENT_DATE < '2023-03-27' THEN CURRENT_DATE ELSE '2023-03-27' END
GROUP BY
  1