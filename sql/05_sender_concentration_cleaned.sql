WITH clean_trades AS (
    SELECT *
    FROM dex.trades
    WHERE project = 'uniswap'
      AND amount_usd IS NOT NULL
      AND NOT (
            blockchain = 'robinhood'
        AND token_pair IN ('AI-WETH', 'COBIE-ETH')
      )
      AND NOT (
            blockchain = 'ethereum'
        AND token_pair = 'MAHC-WETH'
      )
      AND tx_hash NOT IN (
        0x951ad0f7ae53f38d9d983e9e9e720daccbdb674e13e3f7aad68568d0f9fe397a,
        0xa9e4d1329af152e6388433f52afb299489e35ef96f328bbc56fe84fa8f0b5833,
        0xf5872c19325262b25ef74dad347c1cbc81bc92e71d2a2bdbea9e22cc97f82b2c,
        0x818c97aad39b84bd6502bf8fe56559648a0218dce1f2e94d5aff2a16e1691553,
        0x675ee1d70de1437ebb21e68a7d87740b57006ff38e42ba08be50452078690bbf,
        0x82946e71476288c9a8dc58b3d5f03f0ab98280fb9d281bcc7d60ba9f996e5f47,
        0xd4077f3a90015b5c8fe4e1e7195fcb5b25c1ec97c4997d7a21bc726a3d8a7d4d,
        0x093336d4c3cd9ec528494d84fe53cce5e061f8cb86c122d58dde02f3cd94b749
      )
),
daily_sender_volume AS (
    SELECT
        date_trunc('day', block_time) AS day,
        tx_from,
        SUM(amount_usd) AS volume_usd
    FROM clean_trades
    WHERE block_time >= current_timestamp - INTERVAL '30' DAY
      AND block_time < date_trunc('day', current_timestamp)
      AND tx_from IS NOT NULL
    GROUP BY 1, 2
),
ranked AS (
    SELECT
        day,
        tx_from,
        volume_usd,
        ROW_NUMBER() OVER (
            PARTITION BY day
            ORDER BY volume_usd DESC
        ) AS sender_rank,
        SUM(volume_usd) OVER (
            PARTITION BY day
        ) AS total_daily_volume
    FROM daily_sender_volume
)
SELECT
    day,
    ROUND(
        100.0 *
        SUM(CASE WHEN sender_rank <= 10 THEN volume_usd ELSE 0 END)
        / MAX(total_daily_volume),
        2
    ) AS top_10_share_pct
FROM ranked
GROUP BY 1
ORDER BY 1;
