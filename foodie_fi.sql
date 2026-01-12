-- clean input data for numerical data
USE foodie_fi;

CREATE TABLE IF NOT EXISTS plans (
	plan_id INT PRIMARY KEY,
    plan_name VARCHAR(20),
    price DECIMAL(5,2)
);

INSERT INTO plans (plan_id, plan_name, price)
SELECT
	CAST(plan_id AS UNSIGNED),
    plan_name,
    CAST(price AS DECIMAL(5,2))
FROM
	plans_old;

CREATE TABLE IF NOT EXISTS subscriptions (
	customer_id INT,
    plan_id INT,
    start_date DATE,
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);

INSERT INTO subscriptions(customer_id, plan_id, start_date)
SELECT
	CAST(customer_id AS UNSIGNED),
    CAST(plan_id AS UNSIGNED),
    STR_TO_DATE(start_date, '%Y-%m-%d')
FROM
	subscriptions_old;

-- Data Cleaned

SELECT * FROM plans LIMIT 5;
SELECT * FROM subscriptions LIMIT 5;

-- ONTO SECTION B

/*
B. Data Analysis Questions
How many customers has Foodie-Fi ever had?
What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
What is the number and percentage of customer plans after their initial free trial?
What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
How many customers have upgraded to an annual plan in 2020?
How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
*/

-- How many customers has Foodie-Fi ever had?
SELECT 
	COUNT(DISTINCT customer_id) AS total_customers 
FROM
	subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
	YEAR(start_date) AS join_year,
    MONTH(start_date) AS join_month,
    COUNT(*) AS new_customers_per_month
FROM
	subscriptions
GROUP BY YEAR(start_date), MONTH(start_date)
ORDER BY join_year, join_month;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
	p.plan_name,
	COUNT(s.plan_id) AS total_in_2021
FROM
	subscriptions AS s
INNER JOIN plans as p
	ON s.plan_id = p.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY s.plan_id;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
	'churn' AS plan_name,
    SUM(plan_id = 4) AS churn_count,
	CONCAT(ROUND(SUM(plan_id = 4) * 100 / COUNT(*), 1), '%') AS churn_percent
FROM
	subscriptions;
    
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT
	COUNT(DISTINCT c.customer_id) as trial_churn_count, -- where churn happens with id = 4
    COUNT(DISTINCT t.customer_id) as trial_count, -- where trial happens with id = 0
    CONCAT(ROUND(COUNT(DISTINCT c.customer_id) * 100 / COUNT(DISTINCT t.customer_id), 0), '%') AS percent_trial_churn
FROM
	subscriptions AS t
LEFT JOIN subscriptions as c -- self join to compare dates for same customer_id with different plan changes
	ON t.customer_id = c.customer_id
    AND t.plan_id = 0
    AND c.plan_id = 4
	AND DATEDIFF(c.start_date, t.start_date) = 7;

-- What is the number and percentage of customer plans after their initial free trial?
SELECT
	COUNT(DISTINCT c.customer_id) as no_churn_count, -- where churn happens with id not equal 4
    COUNT(DISTINCT t.customer_id) as trial_count, -- where trial happens with id = 0
    CONCAT(ROUND(COUNT(DISTINCT c.customer_id) * 100 / COUNT(DISTINCT t.customer_id), 0), '%') AS percent_trial_churn
FROM
	subscriptions AS t
LEFT JOIN subscriptions as c -- self join to compare dates for same customer_id with different plan changes
	ON t.customer_id = c.customer_id
    AND t.plan_id = 0
    AND c.plan_id <> 4
	AND DATEDIFF(c.start_date, t.start_date) = 7;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH anti AS (
SELECT
	s1.*
FROM
	subscriptions AS s1
LEFT JOIN subscriptions as s2
	ON s1.customer_id = s2.customer_id
    AND s1.start_date < s2.start_date
    AND s2.start_date <= '2020-12-31'
    WHERE s1.start_date <= '2020-12-31'
    AND s2.customer_id IS NULL -- exclude rows with a matching counterpart to get the latest update for each customer_id
)
SELECT
	p.plan_name,
	COUNT(*) AS total_count,
    CONCAT(ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1), '%') AS percent_of_all
FROM
	anti as a
INNER JOIN plans as p
	ON a.plan_id = p.plan_id
GROUP BY p.plan_name;

-- How many customers have upgraded to an annual plan in 2020?
WITH anti AS (
SELECT
	s1.*
FROM
	subscriptions AS s1
LEFT JOIN subscriptions as s2
	ON s1.customer_id = s2.customer_id
    AND s1.start_date < s2.start_date
    AND s2.start_date <= '2020-12-31'
    WHERE s1.start_date <= '2020-12-31' AND s1.start_date >= '2019-12-31'
    AND s2.customer_id IS NULL -- exclude rows with a matching counterpart to get the latest update for each customer_id
)
SELECT
	'pro annual' AS plan_name,
	COUNT(*) AS total_annual_new
FROM
	anti as a
WHERE plan_id = 3;

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT
    ROUND(AVG(DATEDIFF(s2.start_date, s1.start_date)), 1) AS avg_days_before_annual
FROM
	subscriptions AS s1
LEFT JOIN subscriptions as s2
	ON s1.customer_id = s2.customer_id
	AND s1.start_date < s2.start_date
    AND s1.plan_id = 0
    AND s2.plan_id = 3
WHERE s2.start_date IS NOT NULL;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
SELECT
	CASE
		WHEN days_between BETWEEN 0 AND 30 THEN '0-30'
        WHEN days_between BETWEEN 31 AND 60 THEN '31-60'
		WHEN days_between BETWEEN 61 AND 90 THEN '61-90'
        WHEN days_between BETWEEN 91 AND 120 THEN '91-120'
		WHEN days_between BETWEEN 121 AND 150 THEN '121-150'
        WHEN days_between BETWEEN 151 AND 180 THEN '151-180'
        WHEN days_between BETWEEN 181 AND 210 THEN '181-210'
        WHEN days_between BETWEEN 211 AND 240 THEN '211-240'
        WHEN days_between BETWEEN 241 AND 270 THEN '241-270'
        WHEN days_between BETWEEN 271 AND 300 THEN '271-300'
        ELSE '301+'
	END AS day_bucket,
    COUNT(*) AS customer_count,
    ROUND(AVG(days_between), 1) AS avg_days_before_annual
FROM 
	(SELECT
    DATEDIFF(s2.start_date, s1.start_date) AS days_between
FROM
	subscriptions AS s1
LEFT JOIN subscriptions as s2
	ON s1.customer_id = s2.customer_id
	AND s1.start_date < s2.start_date
    AND s1.plan_id = 0
    AND s2.plan_id = 3
WHERE s2.start_date IS NOT NULL
) t
GROUP BY day_bucket
ORDER BY MIN(days_between);

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT
	s1.*,
    s2.*
FROM
	subscriptions AS s1
LEFT JOIN subscriptions as s2
	ON s1.customer_id = s2.customer_id
    AND s1.start_date < s2.start_date
	AND s2.start_date <= '2020-12-31'
WHERE s1.start_date <= '2020-12-31' AND s1.start_date >= '2019-12-31'
    AND s1.plan_id = 2
    AND s2.plan_id IS NOT NULL
;
 -- While not conventional, I wrote this query to verify that there were 0 customers that switched from pro to basic monthly in 2020
 -- By checking all non null changes in 2020 where the originated value is the pro monthly, I can simply display a 0 with a CTE:

WITH downgrade AS (
SELECT
    s2.*
FROM
	subscriptions AS s1
LEFT JOIN subscriptions as s2
	ON s1.customer_id = s2.customer_id
    AND s1.start_date < s2.start_date
	AND s2.start_date <= '2020-12-31'
WHERE s1.start_date <= '2020-12-31' AND s1.start_date >= '2019-12-31'
    AND s1.plan_id = 2
    AND s2.plan_id IS NOT NULL
)
SELECT
	'basic monthly' AS plan_name,
	CASE
		WHEN COUNT(*) IS NULL THEN 0 ELSE COUNT(*) END AS switches_in_2020
FROM
	downgrade as a
WHERE plan_id = 1; -- ensure that we are checking switches to basic only