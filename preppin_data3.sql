/*
REQUIREMENTS

For the transactions file:
- Filter the transactions to just look at DSB 
  - These will be transactions that contain DSB in the Transaction Code field
- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values
- Change the date to be the quarter 
- Sum the transaction values for each quarter and for each Type of Transaction (Online or In-Person)

For the targets file:
- Pivot the quarterly targets so we have a row for each Type of Transaction and each Quarter (help)
- Rename the fields
- Remove the 'Q' from the quarter field and make the data type numeric (help)

Join the two datasets together 
- You may need more than one join clause!

Remove unnecessary fields
Calculate the Variance to Target for each row
Output the data


Challenge source: 
https://preppindata.blogspot.com/2023/01/2023-week-3-targets-for-dsb.html
*/

-- Sandbox
SELECT
*
FROM
pd2023_wk03_targets;

SELECT
*
FROM
pd2023_wk01_pt3
Limit 100;

/*
For the transactions file:
- Filter the transactions to just look at DSB 
  - These will be transactions that contain DSB in the Transaction Code field
- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values
- Change the date to be the quarter 
- Sum the transaction values for each quarter and for each Type of Transaction (Online or In-Person)
*/
WITH CTE AS (
SELECT
*,
CASE
	WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
END AS online_or_in_person_text,
STR_TO_DATE(SUBSTRING_INDEX(transaction_date, ' ', 1), '%d/%m/%Y') AS clean_date
FROM
pd2023_wk01_pt3
WHERE SUBSTRING_INDEX(transaction_code, '-', 1) = 'DSB'
)
SELECT
	online_or_in_person_text,
    QUARTER(clean_date) AS Quarter_Date,
    SUM(VALUE) as Total_value
FROM
	CTE
GROUP BY
	Quarter_Date,
    online_or_in_person_text
ORDER BY
	Quarter_date,
    online_or_in_person_text;

/*
For the targets file:
- Pivot the quarterly targets so we have a row for each Type of Transaction and each Quarter (help)
- Rename the fields
- Remove the 'Q' from the quarter field and make the data type numeric (help)
*/

SELECT
online_or_in_person,
1 AS quarter_date,
Q1 AS Target_value
FROM
pd2023_wk03_targets AS T

UNION ALL

SELECT
online_or_in_person,
2 AS quarter_date,
Q2 AS Target_value
FROM
pd2023_wk03_targets AS T

UNION ALL

SELECT
online_or_in_person,
3 AS quarter_date,
Q3 AS Target_value
FROM
pd2023_wk03_targets AS T

UNION ALL

SELECT
online_or_in_person,
4 AS quarter_date,
Q4 AS Target_value
FROM
pd2023_wk03_targets AS T;



-- Join together the data for targets and actual

-- First make the CTE for transactions
WITH transact AS (
SELECT
CASE
	WHEN online_or_in_person = 1 THEN 'Online'
    WHEN online_or_in_person = 2 THEN 'In-Person'
END AS transaction_type,
QUARTER(
	str_to_date(SUBSTRING_INDEX(transaction_date, ' ', 1), '%d/%m/%Y')
) AS quarter_date,
SUM(Value) as total_value
FROM
pd2023_wk01_pt3
WHERE SUBSTRING_INDEX(transaction_code, '-', 1) = 'DSB'
GROUP BY
	quarter_date,
    transaction_type
),
-- THEN make second CTE for the targets
targets AS (
SELECT
online_or_in_person AS transaction_type,
1 AS quarter_date,
Q1 AS Target_value
FROM
pd2023_wk03_targets

UNION ALL

SELECT
online_or_in_person AS transaction_type,
2 AS quarter_date,
Q2 AS Target_value
FROM
pd2023_wk03_targets

UNION ALL

SELECT
online_or_in_person AS transaction_type,
3 AS quarter_date,
Q3 AS Target_value
FROM
pd2023_wk03_targets

UNION ALL

SELECT
online_or_in_person AS transaction_type,
4 AS quarter_date,
Q4 AS Target_value
FROM
pd2023_wk03_targets
)
SELECT
	t.transaction_type,
	t.quarter_date,
    t.total_value,
    g.target_value,
    t.total_value - g.target_value AS target_variance,
    CASE
		WHEN t.total_value < g.target_value THEN 'UNDER TARGET'
        WHEN t.total_value >= g.target_value THEN 'ABOVE TARGET'
	END AS above_or_below
FROM transact as t
INNER JOIN targets as g
	ON t.transaction_type = g.transaction_type
    AND t.quarter_date = g.quarter_date
ORDER BY t.quarter_date, t.transaction_type
