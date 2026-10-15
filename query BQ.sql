
--1.
--1.a
SELECT
  COUNT(*) AS total_accounts,
  COUNTIF(loan_status = 1) AS default_accounts,
  ROUND(SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*)) * 100, 2) AS default_rate_by_count_pct,
  SUM(loan_amount) AS total_loan_amount,
  SUM(IF(loan_status = 1, loan_amount, 0)) AS default_loan_amount,
  ROUND(SAFE_DIVIDE(SUM(IF(loan_status = 1, loan_amount, 0)), SUM(loan_amount)) * 100, 2) AS default_rate_by_value_pct
FROM `credit.risk_data`;

--1.b
SELECT
  IF(loan_status = 1, 'Default', 'Non-Default') AS status,
  COUNT(*) AS accounts,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_accounts,
  SUM(loan_amount) AS loan_amount,
  ROUND(SUM(loan_amount) * 100.0 / SUM(SUM(loan_amount)) OVER (), 2) AS pct_loan_amount,
  ROUND(AVG(loan_amount), 0) AS avg_loan_amount
FROM `credit.risk_data`
GROUP BY status
ORDER BY status;

--2.
WITH base AS (
  SELECT
    loan_status,
    CASE WHEN person_age <= 25 THEN '1. <25'
         WHEN person_age <= 35 THEN '2. 26-35'
         WHEN person_age <= 45 THEN '3. 36-45'
         WHEN person_age <= 55 THEN '4. 46-55'
         ELSE '5. 56+' END AS age_band,
    CASE WHEN annual_income < 30000  THEN '1. <30K'
         WHEN annual_income < 50000  THEN '2. 30K-<50K'
         WHEN annual_income < 75000  THEN '3. 50K-<75K'
         WHEN annual_income < 100000 THEN '4. 75K-<100K'
         ELSE '5. >=100K' END AS income_band,
    CAST(home_ownership AS STRING) AS home_ownership,
    CASE WHEN employment_length < 2  THEN '1. 0-1 thn'
         WHEN employment_length < 5  THEN '2. 2-4 thn'
         WHEN employment_length < 10 THEN '3. 5-9 thn'
         ELSE '4. 10+ thn' END AS employment_band,
    CASE WHEN credit_history_length <= 3  THEN '1. <=3 thn'
         WHEN credit_history_length <= 6  THEN '2. 4-6 thn'
         WHEN credit_history_length <= 10 THEN '3. 7-10 thn'
         ELSE '4. >10 thn' END AS credit_history_band,
    CAST(historical_default AS STRING) AS historical_default
  FROM `credit.risk_data`
)
SELECT
  c.characteristic,
  c.bucket,
  COUNT(*) AS total_accounts,
  COUNTIF(loan_status = 1) AS default_accounts,
  ROUND(SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*)) * 100, 2) AS default_rate_pct,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.characteristic), 2) AS pct_portfolio
FROM base,
UNNEST([
  STRUCT('person_age' AS characteristic, age_band AS bucket),
  STRUCT('annual_income' AS characteristic, income_band AS bucket),
  STRUCT('home_ownership' AS characteristic, home_ownership AS bucket),
  STRUCT('employment_length' AS characteristic, employment_band AS bucket),
  STRUCT('credit_history_length' AS characteristic, credit_history_band AS bucket),
  STRUCT('historical_default' AS characteristic, historical_default AS bucket)
]) AS c
GROUP BY c.characteristic, c.bucket
ORDER BY c.characteristic, c.bucket;

--3
--3.a
WITH base AS (
  SELECT
    loan_status,
    CAST(loan_intent AS STRING) AS loan_intent,
    CAST(loan_grade  AS STRING) AS loan_grade,
    CASE WHEN loan_amount < 5000  THEN '1. <5K'
         WHEN loan_amount < 10000 THEN '2. 5K-<10K'
         WHEN loan_amount < 15000 THEN '3. 10K-<15K'
         WHEN loan_amount < 20000 THEN '4. 15K-<20K'
         ELSE '5. >=20K' END AS loan_amount_band,
    CASE WHEN interest_rate < 8  THEN '1. <8%'
         WHEN interest_rate < 11 THEN '2. 8-<11%'
         WHEN interest_rate < 14 THEN '3. 11-<14%'
         ELSE '4. >=14%' END AS interest_rate_band
  FROM `credit.risk_data`
)
SELECT
  c.characteristic,
  c.bucket,
  COUNT(*) AS total_accounts,
  COUNTIF(loan_status = 1) AS default_accounts,
  ROUND(SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*)) * 100, 2) AS default_rate_pct,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.characteristic), 2) AS pct_portfolio
FROM base,
UNNEST([
  STRUCT('loan_intent' AS characteristic, loan_intent AS bucket),
  STRUCT('loan_grade' AS characteristic, loan_grade AS bucket),
  STRUCT('loan_amount' AS characteristic, loan_amount_band AS bucket),
  STRUCT('interest_rate' AS characteristic, interest_rate_band AS bucket)
]) AS c
GROUP BY c.characteristic, c.bucket
ORDER BY c.characteristic, c.bucket;

--3.b
WITH grade_summary AS (
  SELECT
    loan_grade,
    COUNT(*) AS total_accounts,
    COUNTIF(loan_status = 1) AS default_accounts,
    ROUND(AVG(interest_rate), 2) AS avg_interest_rate,
    SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*)) * 100 AS default_rate_pct
  FROM `credit.risk_data`
  GROUP BY loan_grade
),
with_prev AS (
  SELECT *, LAG(default_rate_pct) OVER (ORDER BY loan_grade) AS prev_default_rate_pct
  FROM grade_summary
)
SELECT
  loan_grade,
  total_accounts,
  default_accounts,
  ROUND(default_rate_pct, 2) AS default_rate_pct,
  avg_interest_rate,
  ROUND(default_rate_pct - prev_default_rate_pct, 2) AS delta_vs_prev_grade_pp,
  CASE WHEN prev_default_rate_pct IS NULL THEN 'Baseline'
       WHEN default_rate_pct > prev_default_rate_pct THEN 'Increase'
       ELSE 'Decrease' END AS risk_status
FROM with_prev
ORDER BY loan_grade;

--4.
WITH pti AS (
  SELECT
    CASE WHEN percent_income < 0.10 THEN '1. <10%'
         WHEN percent_income < 0.15 THEN '2. 10-<15%'
         WHEN percent_income < 0.20 THEN '3. 15-<20%'
         WHEN percent_income < 0.25 THEN '4. 20-<25%'
         WHEN percent_income < 0.30 THEN '5. 25-<30%'
         WHEN percent_income < 0.35 THEN '6. 30-<35%'
         ELSE '7. >=35%' END AS percent_income_band,
    COUNT(*) AS total_accounts,
    COUNTIF(loan_status = 1) AS default_accounts,
    SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*)) * 100 AS default_rate_pct
  FROM `credit.risk_data`
  GROUP BY percent_income_band
),
with_delta AS (
  SELECT *, default_rate_pct - LAG(default_rate_pct) OVER (ORDER BY percent_income_band) AS delta_pp
  FROM pti
)
SELECT
  percent_income_band,
  total_accounts,
  default_accounts,
  ROUND(default_rate_pct, 2) AS default_rate_pct,
  ROUND(delta_pp, 2) AS delta_vs_prev_band_pp,
  RANK() OVER (ORDER BY delta_pp DESC NULLS LAST) AS ranks   -- rank 1 = lonjakan terbesar.
FROM with_delta
ORDER BY percent_income_band;

--5.
WITH base AS (
  SELECT
    loan_status,
    loan_amount,
    CAST(home_ownership AS STRING) AS home_ownership,
    CASE WHEN loan_grade = 'A' THEN '1. Grade A'
     WHEN loan_grade IN ('B', 'C') THEN '2. Grade B-C'
     ELSE '3. Grade D-G' END AS grade_group,
    CASE WHEN percent_income < 0.15 THEN '1. <15%'
     WHEN percent_income < 0.30 THEN '2. 15-<30%'
     ELSE '3. >=30%' END AS percent_income_band
  FROM `credit.risk_data`
),
seg AS (
  SELECT
    home_ownership, grade_group, percent_income_band,
    COUNT(*) AS total_accounts,
    COUNTIF(loan_status = 1) AS default_accounts,
    SUM(loan_amount) AS total_loan_amount
  FROM base
  GROUP BY home_ownership, grade_group, percent_income_band
),
final AS (
  SELECT
    *,
    SAFE_DIVIDE(default_accounts, total_accounts) AS default_rate,
    SAFE_DIVIDE(SUM(default_accounts) OVER (), SUM(total_accounts) OVER()) AS overall_default_rate,
    total_accounts * 100.0 / SUM(total_accounts) OVER() AS pct_accounts,
    total_loan_amount * 100.0 / SUM(total_loan_amount) OVER() AS pct_loan_amount
  FROM seg
)
SELECT
  home_ownership,
  grade_group,
  percent_income_band,
  total_accounts,
  default_accounts,
  ROUND(default_rate * 100, 2) AS default_rate_pct,
  ROUND(default_rate / overall_default_rate, 2) AS lift_vs_portfolio,
  ROUND(pct_accounts, 2) AS pct_portfolio_accounts,
  ROUND(pct_loan_amount, 2) AS pct_portfolio_amount
FROM final
WHERE total_accounts >= 100
ORDER BY default_rate DESC
LIMIT 10;

--6.
WITH scored AS (
  SELECT
    loan_status,
    loan_amount,
    (CASE WHEN loan_grade IN ('D', 'E', 'F', 'G') THEN 2
      WHEN loan_grade IN ('B', 'C') THEN 1
      ELSE 0 END)
  + (CASE WHEN percent_income >= 0.30 THEN 2
          WHEN percent_income >= 0.15 THEN 1
          ELSE 0 END)
  + (CASE WHEN home_ownership = 'RENT' THEN 1 ELSE 0 END)
  + (CASE WHEN historical_default = true THEN 1 ELSE 0 END) AS risk_score
  FROM `credit.risk_data`
),
tiered AS (
  SELECT
    *,
    CASE WHEN risk_score >= 4 THEN '3. High Risk'
         WHEN risk_score >= 2 THEN '2. Medium Risk'
         ELSE '1. Low Risk' END AS risk_tier
  FROM scored
)
SELECT
  risk_tier,
  COUNT(*) AS total_accounts,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_portfolio_accounts,
  SUM(loan_amount) AS total_loan_amount,
  ROUND(SUM(loan_amount) * 100.0 / SUM(SUM(loan_amount)) OVER (), 2) AS pct_portfolio_amount,
  COUNTIF(loan_status = 1) AS default_accounts,
  ROUND(SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*)) * 100, 2) AS default_rate_pct,
  ROUND(COUNTIF(loan_status = 1) * 100.0 / SUM(COUNTIF(loan_status = 1)) OVER(), 2) AS pct_of_total_defaults,
  ROUND(SAFE_DIVIDE(COUNTIF(loan_status = 1), COUNT(*))
  / (SUM(COUNTIF(loan_status = 1)) OVER () / SUM(COUNT(*)) OVER ()), 2) AS lift_vs_portfolio
FROM tiered
GROUP BY risk_tier
ORDER BY risk_tier DESC;