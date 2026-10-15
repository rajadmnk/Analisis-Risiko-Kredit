
SELECT * FROM credit.risk
LIMIT 5;

SELECT

  COUNT(*) AS total_rows, -- 32581
  COUNTIF(person_age IS NULL) AS total_age_rows,
  COUNTIF(person_income IS NULL) AS total_income_rows,
  COUNTIF(person_home_ownership IS NULL) AS total_home_rows,
  COUNTIF(person_emp_length IS NULL) AS total_emp_rows, -- 895 null
  COUNTIF(loan_intent IS NULL) AS intent_rows,
  COUNTIF(loan_grade IS NULL) AS grade_rows,
  COUNTIF(loan_amnt IS NULL) AS amnt_rows,
  COUNTIF(loan_int_rate IS NULL) AS rate_rows, -- 3116 null
  COUNTIF(loan_status IS NULL) AS stat_rows,
  COUNTIF(loan_percent_income IS NULL) AS pct_rows,
  COUNTIF(cb_person_cred_hist_length IS NULL) AS hist_rows,
  COUNTIF(cb_person_default_on_file IS NULL) AS def_rows

FROM `credit.risk`;

-- terdapat nilai null pada person_emp_length dan loan_int_rate

SELECT
  
  MIN(person_age) AS min_age, -- 20
  MAX(person_age) AS max_age, -- 144

  MIN(person_income) AS min_income, -- 4000
  MAX(person_income) AS max_income, -- 6000000

  MIN(person_emp_length) AS min_emp, -- 0
  MAX(person_emp_length) AS max_emp, -- 123

  MIN(loan_amnt) AS min_amnt, -- 500
  MAX(loan_amnt) AS max_amnt, -- 35000

  MIN(loan_int_rate) AS min_rate, -- 5.42
  MAX(loan_int_rate) AS max_rate, -- 23.22

  MIN(loan_percent_income) AS min_pct_income, -- 0
  MAX(loan_percent_income) AS max_pct_income, -- 0.83

  MIN(cb_person_cred_hist_length) AS min_hist, -- 2
  MAX(cb_person_cred_hist_length) AS max_hist -- 30

FROM `credit.risk`;

-- terdapat data anomali pada person_age dan person_emp_length 

SELECT
COUNT(person_age), -- 5
FROM `credit.risk`
WHERE person_age > 100;

SELECT
COUNT(*) -- 2
FROM `credit.risk`
WHERE person_emp_length > person_age;

-- terdapat 5 data anomali dengan umur diatas 100 tahun, dan 2 data anomali dengan person_emp_length > person age

CREATE OR REPLACE TABLE `credit.risk_data` AS 
WITH duplikat AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   person_age,
                   CAST(person_income AS STRING),
                   person_home_ownership,
                   CAST(person_emp_length AS STRING),
                   loan_intent,
                   loan_grade,
                   CAST(loan_amnt AS STRING),
                   CAST(loan_int_rate AS STRING),
                   loan_status,
                   CAST(loan_percent_income AS STRING),
                   cb_person_default_on_file,
                   cb_person_cred_hist_length
               ORDER BY (SELECT NULL)
           ) AS rn
     FROM `credit.risk`  
),
clean AS (
    SELECT

        person_age, 
        CAST(person_income AS INT64)  AS annual_income, 
        person_home_ownership AS home_ownership,

        CAST(COALESCE(person_emp_length,0) AS FLOAT64) AS employment_length,

        loan_intent, loan_grade, 
        CAST(loan_amnt AS INT64) AS loan_amount,

        CAST(COALESCE(loan_int_rate,
        PERCENTILE_CONT(loan_int_rate, 0.5) OVER(PARTITION BY loan_intent)
        ) AS FLOAT64) AS interest_rate,

        loan_status,
        CAST(loan_percent_income AS FLOAT64) AS percent_income,
        cb_person_default_on_file AS historical_default,
        cb_person_cred_hist_length AS credit_history_length,

    FROM duplikat
    WHERE person_age <= 100 AND (
    person_emp_length IS NULL OR
    person_emp_length <= person_age)
    AND rn = 1
)
SELECT * FROM clean;

SELECT 
  (SELECT COUNT(*) FROM `credit.risk`) AS count_before, -- 32581
  (SELECT COUNT(*) FROM `credit.risk_data`) AS count_after; -- 32409


-- total raw data 32581
--  (total data anomali = 7)
-- total data after handling anomali 32574
--  (total data dup = 165)
-- total data after delete duplicate 32049


SELECT COUNT(*) FROM `credit.risk_data` -- 0
WHERE interest_rate IS NULL OR employment_length IS NULL

