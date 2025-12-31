USE preppin_data;


/*
REQUIREMENTS

- We want to stack the tables on top of one another, since they have the same fields in each sheet.
- Drag each table into the canvas and use a union step to stack them on top of one another
- Use a wildcard union in the input step of one of the tables
- Some of the fields aren't matching up as we'd expect, due to differences in spelling. Merge these fields together
- Make a Joining Date field based on the Joining Day, Table Names and the year 2023
- Now we want to reshape our data so we have a field for each demographic, for each new customer
- Make sure all the data types are correct for each field
- Remove duplicates 
- If a customer appears multiple times take their earliest joining date

Output the data

Challenge source: 
https://preppindata.blogspot.com/2023/01/2023-week-4-new-customers.html
*/
SELECT * FROM pd2023_wk04_january;

-- MAKE A VIEW OF DATA FOR PROJECT
CREATE OR REPLACE VIEW df AS
SELECT 
*,
SUBSTRING_INDEX('pd2023_wk04_january', '_', -1) AS Month
FROM pd2023_wk04_january
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_february', '_', -1) AS Month
FROM pd2023_wk04_february
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_march', '_', -1) AS Month
FROM pd2023_wk04_march
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_april', '_', -1) AS Month
FROM pd2023_wk04_april
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_may', '_', -1) AS Month
FROM pd2023_wk04_may
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_june', '_', -1) AS Month
FROM pd2023_wk04_june
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_july', '_', -1) AS Month
FROM pd2023_wk04_july
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_august', '_', -1) AS Month
FROM pd2023_wk04_august
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_september', '_', -1) AS Month
FROM pd2023_wk04_september
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_october', '_', -1) AS Month
FROM pd2023_wk04_october
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_november', '_', -1) AS Month
FROM pd2023_wk04_november
UNION ALL
SELECT
*,
SUBSTRING_INDEX('pd2023_wk04_december', '_', -1) AS Month
FROM pd2023_wk04_december
;

-- CHECK VIEW - GOOD
SELECT * FROM df;

-- Make a Joining Date field based on the Joining Day, Table Names and the year 2023. MySQL different than Snowflake
-- Now we want to reshape our data so we have a field for each demographic, for each new customer


WITH joined_parts AS (
SELECT
*,
CASE Month
  WHEN 'january' THEN 1
  WHEN 'february' THEN 2
  WHEN 'march' THEN 3
  WHEN 'april' THEN 4
  WHEN 'may' THEN 5
  WHEN 'june' THEN 6
  WHEN 'july' THEN 7
  WHEN 'august' THEN 8
  WHEN 'september' THEN 9
  WHEN 'october' THEN 10
  WHEN 'november' THEN 11
  WHEN 'december' THEN 12
END AS month_num,
2023 as year_num
FROM
df
),
pivots AS(
SELECT
ID,
makedate(year_num, 1) + interval(month_num - 1) MONTH + interval(joining_day - 1) DAY AS date_joined,
MAX(CASE WHEN Demographic = 'Ethnicity' THEN Value END) AS Ethnicity,
MAX(STR_TO_DATE(CASE WHEN Demographic = 'Date of Birth' THEN Value END, '%m/%d/%Y')) AS Date_of_Birth,
MAX(CASE WHEN Demographic = 'Account Type' THEN Value END) AS Account_Type
FROM
joined_parts
GROUP BY ID, date_joined
),
ranked AS (
SELECT
*,
ROW_NUMBER() OVER(PARTITION BY ID ORDER BY date_joined ASC) as rn
FROM pivots
)
SELECT
ID,
date_joined,
Ethnicity,
Date_of_Birth,
Account_Type
FROM ranked
WHERE rn = 1
ORDER BY date_joined ASC;