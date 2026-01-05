/*
Case Study Questions
This case study has LOTS of questions - they are broken up by area of focus including:

Investigate the data, you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

A. Pizza Metrics
How many pizzas were ordered?
How many unique customer orders were made?
How many successful orders were delivered by each runner?
How many of each type of pizza was delivered?
How many Vegetarian and Meatlovers were ordered by each customer?
What was the maximum number of pizzas delivered in a single order?
For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
How many pizzas were delivered that had both exclusions and extras?
What was the total volume of pizzas ordered for each hour of the day?
What was the volume of orders for each day of the week?


B. Runner and Customer Experience
How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
Is there any relationship between the number of pizzas and how long the order takes to prepare?
What was the average distance travelled for each customer?
What was the difference between the longest and shortest delivery times for all orders?
What was the average speed for each runner for each delivery and do you notice any trend for these values?
What is the successful delivery percentage for each runner?


C. Ingredient Optimisation
What are the standard ingredients for each pizza?
What was the most commonly added extra?
What was the most common exclusion?
Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


D. Pricing and Ratings
If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra
The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?


E. Bonus Questions
If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/

-- Investigate Data and Handle Nulls:
SELECT * FROM runners; 			-- no nulls
SELECT * FROM runner_orders; 	-- nulls in pickup, distance, duration, cancellation
SELECT * FROM customer_orders; 	-- nulls in exclusions and extras
SELECT * FROM pizza_names; 		-- no nulls
SELECT * FROM pizza_recipes;	-- no nulls
SELECT * FROM pizza_toppings;	-- no nulls

-- handle nulls in customer_orders
UPDATE customer_orders
SET exclusions = null
	WHERE exclusions IN ('', 'null');
SELECT * FROM customer_orders;

UPDATE customer_orders
SET extras = null
	WHERE extras IN ('', 'null');
SELECT * FROM customer_orders;

-- handle nulls in runner_orders
UPDATE runner_orders
SET pickup_time = null
	WHERE pickup_time = 'null';
SELECT * FROM runner_orders;

UPDATE runner_orders
SET distance = null
	WHERE distance = 'null';
UPDATE runner_orders
SET distance = REPLACE(REPLACE(distance, 'km', ''), ' ', '')
	WHERE distance IS NOT NULL;
SELECT * FROM runner_orders;

UPDATE runner_orders
SET duration = null
	WHERE duration = 'null';
UPDATE runner_orders
SET duration = REGEXP_REPLACE(duration, '[^0-9.]', '')
	WHERE duration IS NOT NULL;
SELECT * FROM runner_orders;

UPDATE runner_orders
SET cancellation = null
	WHERE cancellation IN ('', 'null');
SELECT * FROM runner_orders;

-- Handle Data Types as they come in ABCDE

/*
A. Pizza Metrics
How many pizzas were ordered?
How many unique customer orders were made?
How many successful orders were delivered by each runner?
How many of each type of pizza was delivered?
How many Vegetarian and Meatlovers were ordered by each customer?
What was the maximum number of pizzas delivered in a single order?
For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
How many pizzas were delivered that had both exclusions and extras?
What was the total volume of pizzas ordered for each hour of the day?
What was the volume of orders for each day of the week?
*/

-- How many pizzas were ordered?
SELECT COUNT(order_id) AS pizzas_ordered
FROM customer_orders;

-- How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS pizzas_ordered
FROM customer_orders;

-- How many successful orders were delivered by each runner?
SELECT COUNT(order_id) AS fulfilled_orders
FROM runner_orders
WHERE cancellation IS NULL;

-- How many of each type of pizza was delivered?
SELECT 
p.pizza_name,
COUNT(c.pizza_id) AS pizzas_delivered
FROM customer_orders AS c
LEFT JOIN runner_orders AS r
	ON c.order_id = r.order_id
INNER JOIN pizza_names AS p
	ON c.pizza_id = p.pizza_id
WHERE r.cancellation IS NULL
GROUP BY p.pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
c.customer_id,
p.pizza_name,
COUNT(c.pizza_id) AS pizzas_ordered
FROM customer_orders AS c
INNER JOIN pizza_names AS p
	ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id, COUNT(c.pizza_id) DESC;

-- What was the maximum number of pizzas delivered in a single order?
SELECT
order_id,
count(order_id) AS pizzas_ordered
FROM customer_orders
GROUP BY order_id
ORDER BY COUNT(order_id) DESC
LIMIT 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH changes AS (
	SELECT
		c.customer_id,
		c.order_id,
		CASE 
			WHEN c.exclusions IS NOT NULL THEN 1
			WHEN c.exclusions IS NULL THEN 0
		END AS exclusion_changes_made,
		CASE 
			WHEN c.extras IS NOT NULL THEN 1
			WHEN c.extras IS NULL THEN 0
		END AS extras_changes_made
	FROM customer_orders AS c
		LEFT JOIN runner_orders AS r
			ON c.order_id = r.order_id
	WHERE r.cancellation IS NULL
)
	SELECT 
		customer_id,
		no_changes,
		any_changes,
		ceil((any_changes * 100.0) / (any_changes + no_changes)) AS pct_of_pizza_changes
	-- Subquery for percentage call
    FROM(
		SELECT
			customer_id,
			SUM(CASE
				WHEN exclusion_changes_made = 0 
                AND extras_changes_made = 0 THEN 1 ELSE 0
			END) AS no_changes,
			SUM(CASE
				WHEN exclusion_changes_made = 1 
                OR extras_changes_made = 1 THEN 1 ELSE 0
			END) AS any_changes
	FROM changes
	GROUP BY customer_id
) t;

-- How many pizzas were delivered that had both exclusions and extras?
WITH changes AS (
	SELECT
		c.customer_id,
		c.order_id,
		CASE 
			WHEN c.exclusions IS NOT NULL THEN 1
			WHEN c.exclusions IS NULL THEN 0
		END AS exclusion_changes_made,
		CASE 
			WHEN c.extras IS NOT NULL THEN 1
			WHEN c.extras IS NULL THEN 0
		END AS extras_changes_made
	FROM customer_orders AS c
		LEFT JOIN runner_orders AS r
			ON c.order_id = r.order_id
	WHERE r.cancellation IS NULL
)
SELECT
	COUNT(*) AS pizza_delivered_count,
	SUM(CASE
		WHEN exclusion_changes_made = 1 
		AND extras_changes_made = 1 THEN 1 ELSE 0
	END) AS both_exclusion_extras,
    SUM(CASE
		WHEN exclusion_changes_made = 0 
		OR extras_changes_made = 0 THEN 1 ELSE 0
    END) AS not_both,
    CONCAT(
		CEIL(SUM(
			CASE
				WHEN exclusion_changes_made = 1 
				AND extras_changes_made = 1 THEN 1 ELSE 0
			END) * 100 / COUNT(*))
        , '%') AS pct_both
FROM changes
;

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT
HOUR(order_time) AS hour_of_order,
COUNT(*) as volume_of_orders
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);

-- What was the volume of orders for each day of the week?
SELECT
MONTH(order_time) as month_of_order,
DAY(order_time) AS day_of_order,
COUNT(*) as volume_of_orders
FROM customer_orders
GROUP BY MONTH(order_time), DAY(order_time)
ORDER BY DAY(order_time);




/*
B. Runner and Customer Experience
How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
Is there any relationship between the number of pizzas and how long the order takes to prepare?
What was the average distance travelled for each customer?
What was the difference between the longest and shortest delivery times for all orders?
What was the average speed for each runner for each delivery and do you notice any trend for these values?
What is the successful delivery percentage for each runner?
*/

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT * FROM runners;
SELECT
	date_sub(registration_date,
		INTERVAL (datediff(registration_date, '2021-01-01') % 7) DAY
	) AS week_start,
	COUNT(runner_id) AS new_runners
FROM
	runners
GROUP BY week_start
ORDER BY week_start;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- update data type with update and alter lines:
UPDATE runner_orders 
SET pickup_time = STR_TO_DATE(pickup_time, '%Y-%m-%d %H:%i:%s');
ALTER TABLE runner_orders MODIFY COLUMN pickup_time TIMESTAMP;
-- NOW call the time difference using MySQL's TIMESTAMPDIFF

SELECT
o.runner_id,
CONCAT(ROUND(AVG(TIMESTAMPDIFF(minute, c.order_time, o.pickup_time)), 2), ' minutes') AS order_to_pickup
FROM runner_orders as o
INNER JOIN customer_orders as c
	ON o.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY o.runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_size AS (
SELECT
c.order_id,
COUNT(c.order_id) AS pizzas_in_order,
AVG(TIMESTAMPDIFF(minute, c.order_time, o.pickup_time)) AS order_to_pickup
FROM runner_orders as o
INNER JOIN customer_orders as c
	ON o.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id
)
SELECT 
pizzas_in_order,
COUNT(order_id) AS count_of_orders,
CONCAT(ROUND(AVG(order_to_pickup), 2), ' minutes') AS avg_order_time,
min(order_to_pickup) AS fastest_turnaround,
max(order_to_pickup) AS slowest_turnaround,
stddev(order_to_pickup) AS std_order_time
FROM order_size
GROUP BY pizzas_in_order;
;
-- YES - as seen by table, more pizzas have slower turnaround but need more data for confidence

-- What was the average distance travelled for each customer?
SELECT
CONCAT(ROUND(AVG(o.distance), 2), ' kilometers') AS average_distance,
c.customer_id
FROM
runner_orders AS o
INNER JOIN customer_orders AS c
	ON o.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?
ALTER TABLE runner_orders -- Need type to be int for this calculation, not varchar
MODIFY duration INT;

SELECT
CONCAT(MAX(duration) - MIN(duration), ' minutes') AS largest_time_gap
FROM runner_orders
WHERE cancellation IS NULL;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
runner_id,
COUNT(runner_id) AS delivery_count,
ROUND(AVG(distance),2) AS avg_distance,
ROUND(AVG(duration),2) AS avg_duration
FROM runner_orders
WHERE cancellation is null
GROUP BY runner_id;
-- Yes - runner 2 has longer travel and loger duration, but all seem in line for such a small sample

-- What is the successful delivery percentage for each runner?
WITH cancels AS (
SELECT 
runner_id,
SUM(CASE
	WHEN cancellation IS NOT NULL THEN 1
END) AS cancelled_orders,
SUM(CASE
    WHEN cancellation IS NULL THEN 1
END) AS not_cancelled_orders
FROM runner_orders
GROUP BY runner_id
)
SELECT
runner_id,
CASE
WHEN cancelled_orders IS NULL THEN CONCAT(100, '%')
ELSE CONCAT(not_cancelled_orders * 100 / (not_cancelled_orders + cancelled_orders), '%') 
END AS pct_both
FROM cancels
;

