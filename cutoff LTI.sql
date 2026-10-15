
WITH q AS (
  SELECT APPROX_QUANTILES(percent_income, 100) AS p FROM `credit.risk_data`
)
SELECT
  p[OFFSET(0)] AS min_v,
  p[OFFSET(10)] AS p10,
  p[OFFSET(25)] AS p25,
  p[OFFSET(50)] AS median,
  p[OFFSET(75)] AS p75,
  p[OFFSET(90)] AS p90,
  p[OFFSET(95)] AS p95,
  p[OFFSET(99)] AS p99,
  p[OFFSET(100)] AS max_v
FROM q;

WITH b AS (
  SELECT
    ROUND(FLOOR(percent_income / 0.05) * 0.05, 2) AS band_start,
    COUNT(*) AS n,
    COUNTIF(loan_status = 1) AS d
  FROM `credit.risk_data`
  GROUP BY band_start
)
SELECT
  band_start,
  n,
  d AS default_accounts,
  ROUND(d / n * 100, 2) AS default_rate_pct,
  ROUND(d / n * 100 - LAG(d / n * 100) OVER (ORDER BY band_start), 2) AS delta_vs_prev_pp,
  ROUND(1.96 * SQRT((d / n) * (1 - d / n) / n) * 100, 2) AS margin_95_pp
FROM b
ORDER BY band_start;