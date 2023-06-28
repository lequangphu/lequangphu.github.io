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
WHERE BLOCK_TIMESTAMP < CASE WHEN CURRENT_DATE < '2023-03-27' THEN CURRENT_DATE ELSE '2023-03-27' END
GROUP BY
  1