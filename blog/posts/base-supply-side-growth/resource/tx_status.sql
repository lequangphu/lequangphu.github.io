SELECT
  BLOCK_TIMESTAMP::date AS blocktime,
  count(*) AS total_txs,
  count(
    CASE
      when STATUS = 'SUCCESS' then TX_HASH
      else NULL
    end
  ) AS success_txs,
  total_txs - success_txs AS fail_txs,
  success_txs / total_txs AS success_pct,
  fail_txs / total_txs AS fail_pct
FROM
  base.goerli.fact_transactions
WHERE BLOCK_TIMESTAMP < CURRENT_DATE
GROUP BY
  1