CREATE DATABASE IF NOT EXISTS preppin_data;
USE preppin_data;

/*
REQUIREMENTS

- Split the Transaction Code to extract the letters at the start of the transaction code. These identify the bank who processes the transaction
- Rename the new field with the Bank code 'Bank'. 
- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values. 
- Change the date to be the day of the week

Different levels of detail are required in the outputs. 
You will need to sum up the values of the transactions in three ways:
  1. Total Values of Transactions by each bank
  2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
  3. Total Values by Bank and Customer Code

Output each query

Challenge source: 
https://preppindata.blogspot.com/2023/01/2023-week-1-data-source-bank.html
*/

-- Split the Transaction Code to extract the letters at the start of the transaction code. These identify the bank who processes the transaction
-- Rename the new field with the Bank code 'Bank'
-- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values. 
-- Change the date to be the day of the week (NOTE text is varchar and will have issues with date functions)

-- SANDBOX FOR TESTING
SELECT
*
FROM pd2023_wk01
LIMIT 100;

-- USE SUBQUERY TO ACCESS CALCULATED DATA AND CREATE VIEW FOR ANALYSIS
CREATE OR REPLACE VIEW cleaned_data AS
	SELECT
		*,
		DAYNAME(date_real) AS transaction_day,
		CASE
			WHEN online_or_in_person = 1 THEN 'Online'
			WHEN online_or_in_person = 2 THEN 'In-Person'
		END AS online_or_in_person_text
	FROM(
		SELECT
			*,
			SUBSTRING_INDEX(transaction_code, '-', 1) AS bank,
			STR_TO_DATE(substring_index(transaction_date, ' ', 1), '%d/%m/%Y') AS date_real
		FROM pd2023_wk01
	) t
;

/*
Different levels of detail are required in the outputs. 
You will need to sum up the values of the transactions in three ways:
  1. Total Values of Transactions by each bank
  2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
  3. Total Values by Bank and Customer Code
*/

-- 1. Total Values of Transactions by each bank

SELECT
bank,
SUM(value) as total_value
FROM cleaned_data
GROUP BY bank
ORDER BY total_value DESC;

-- 2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)

SELECT
bank,
transaction_day,
online_or_in_person_text,
SUM(value) as total_value
FROM cleaned_data
GROUP BY bank, transaction_day, online_or_in_person_text
ORDER BY total_value DESC;

-- 3. Total Values by Bank and Customer Code

SELECT
bank,
customer_code,
SUM(value) as total_value
FROM cleaned_data
GROUP BY bank, customer_code
ORDER BY total_value DESC;