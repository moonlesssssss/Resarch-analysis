-- Data-quality audit queries used before applying targeted exclusions.

-- 1) Largest transaction-level raw volumes over 90 days.
WITH tx_level AS (
    SELECT
        date_trunc('day', block_time) AS day,
        blockchain,
        version,
        token_pair,
        tx_hash,
        COUNT(*) AS trade_legs,
        SUM(amount_usd) AS summed_leg_volume_usd,
        MAX(amount_usd) AS largest_leg_usd
    FROM dex.trades
    WHERE project = 'uniswap'
      AND amount_usd IS NOT NULL
      AND block_time >= current_timestamp - INTERVAL '90' DAY
      AND block_time < date_trunc('day', current_timestamp)
    GROUP BY 1, 2, 3, 4, 5
)
SELECT *
FROM tx_level
ORDER BY summed_leg_volume_usd DESC
LIMIT 100;

-- 2) Pair-level audit template.
-- Run separately when investigating a suspicious chain or market.
-- SELECT
--     version,
--     token_pair,
--     SUM(amount_usd) AS volume_usd,
--     COUNT(*) AS trade_legs,
--     COUNT(DISTINCT tx_hash) AS transactions,
--     COUNT(DISTINCT tx_from) AS active_senders,
--     AVG(amount_usd) AS avg_leg_usd,
--     approx_percentile(amount_usd, 0.5) AS median_leg_usd,
--     approx_percentile(amount_usd, 0.99) AS p99_leg_usd,
--     MAX(amount_usd) AS max_leg_usd
-- FROM dex.trades
-- WHERE project = 'uniswap'
--   AND blockchain = 'robinhood'
--   AND block_time >= current_timestamp - INTERVAL '30' DAY
--   AND block_time < date_trunc('day', current_timestamp)
-- GROUP BY 1, 2
-- ORDER BY volume_usd DESC
-- LIMIT 50;
