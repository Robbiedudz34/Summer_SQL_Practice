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
USE pizza_runner;
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


/*
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
*/

-- What are the standard ingredients for each pizza?
SELECT
    t.topping_name AS Toppings_On_All_Pizzas
FROM
	pizza_recipes AS r
INNER JOIN JSON_TABLE(
CONCAT('[', r.toppings, ']'),
'$[*]' COLUMNS (
	topping_id INT PATH '$'
	)
) jt ON TRUE
INNER JOIN pizza_toppings AS t
	ON jt.topping_id = t.topping_id
INNER JOIN pizza_names AS n
	ON r.pizza_id = n.pizza_id
GROUP BY t.topping_name
HAVING COUNT(DISTINCT r.pizza_id) = 2;

-- What was the most commonly added extra?
SELECT
    t.topping_name AS most_added_topping
--    COUNT(*) AS count_of_adds
FROM
	customer_orders as c
INNER JOIN JSON_TABLE(
CONCAT('[', c.extras, ']'),
'$[*]' COLUMNS (
	topping_id INT PATH '$'
	)
) jt ON TRUE
INNER JOIN pizza_toppings AS t
	ON jt.topping_id = t.topping_id
WHERE c.extras IS NOT NULL
GROUP BY t.topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- What was the most common exclusion?
SELECT
    t.topping_name AS most_common_exclusion,
    COUNT(*) AS count_of_removals
FROM
	customer_orders as c
INNER JOIN JSON_TABLE(
CONCAT('[', c.exclusions, ']'),
'$[*]' COLUMNS (
	topping_id INT PATH '$'
	)
) jt ON TRUE
INNER JOIN pizza_toppings AS t
	ON jt.topping_id = t.topping_id
WHERE c.exclusions IS NOT NULL
GROUP BY t.topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;

/*
Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/
WITH included AS (
	SELECT
		c.order_id,
		c.pizza_id,
		group_concat(DISTINCT t.topping_name ORDER BY t.topping_name SEPARATOR ', ') AS toppings_added
	FROM
		customer_orders as c
	INNER JOIN JSON_TABLE(
	CONCAT('[', c.extras, ']'),
	'$[*]' COLUMNS (
		topping_id INT PATH '$'
		)
	) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
	WHERE c.extras IS NOT NULL
	GROUP BY c.order_id, c.pizza_id
), excluded AS (
	SELECT
		c.order_id,
		c.pizza_id,
		group_concat(DISTINCT t.topping_name ORDER BY t.topping_name SEPARATOR ', ') AS toppings_removed
	FROM
		customer_orders as c
	INNER JOIN JSON_TABLE(
	CONCAT('[', c.exclusions, ']'),
	'$[*]' COLUMNS (
		topping_id INT PATH '$'
		)
	) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
	WHERE c.exclusions IS NOT NULL
	GROUP BY c.order_id, c.pizza_id
)
SELECT
	c.order_id,
	CONCAT(CASE WHEN n.pizza_name = 'Meatlovers' THEN 'Meat Lovers' ELSE n.pizza_name END,
		COALESCE(CONCAT(' - Exclude ', toppings_removed), ''),
		COALESCE(CONCAT(' - Extra ', toppings_added), '')) AS Order_Made
FROM
	customer_orders as c
LEFT JOIN included as i on i.order_id = c.order_id and i.pizza_id = c.pizza_id
LEFT JOIN excluded as e on e.order_id = c.order_id and e.pizza_id = c.pizza_id
INNER JOIN pizza_names AS n on n.pizza_id = c.pizza_id;


-- Generate an alphabetically ordered comma separated ingredient list for each pizza order 
-- from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH pizzas AS(
	SELECT
		order_id,
        pizza_id,
        ROW_NUMBER() OVER(PARTITION BY order_id, pizza_id ORDER BY order_id) AS pizza_instance,
        exclusions,
        extras
	FROM
		customer_orders
), standard AS(
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        1 AS delta
	FROM
		pizzas as p
	INNER JOIN pizza_recipes as r
		ON p.pizza_id = r.pizza_id
	INNER JOIN JSON_TABLE(
		CONCAT('[', r.toppings, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) AS jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), included AS (
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        1 AS delta
	FROM
		pizzas as p
	INNER JOIN JSON_TABLE(
		CONCAT('[', p.extras, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), excluded AS (
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        -1 AS delta
	FROM
		pizzas AS p
	INNER JOIN JSON_TABLE(
		CONCAT('[', p.exclusions, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), all_toppings AS (
	SELECT * FROM standard
	UNION ALL
    SELECT * FROM included
    UNION ALL
    SELECT * FROM excluded
), aggregated AS (
	SELECT
		order_id,
        pizza_id,
        pizza_instance,
        topping_name,
        SUM(delta) AS quantity
	FROM
		all_toppings
	GROUP BY
		order_id,
        pizza_id,
        pizza_instance,
        topping_name
	HAVING SUM(delta) > 0
)
SELECT
	a.order_id,
	CONCAT(
		CASE WHEN n.pizza_name = 'Meatlovers' THEN 'Meat Lovers' ELSE n.pizza_name END,
		': ',
        GROUP_CONCAT(
			CASE WHEN quantity = 1 THEN topping_name
				ELSE CONCAT(quantity, 'x', topping_name)
            END
            ORDER BY topping_name
            SEPARATOR ', '
		)
	) AS pizza_description
FROM
	aggregated AS a
INNER JOIN pizza_names as n
		ON n.pizza_id = a.pizza_id
GROUP BY
	a.order_id,
	a.pizza_id,
	a.pizza_instance,
	n.pizza_name
ORDER BY a.order_id;


-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH pizzas AS(
	SELECT
		order_id,
        pizza_id,
        ROW_NUMBER() OVER(PARTITION BY order_id, pizza_id ORDER BY order_id) AS pizza_instance,
        exclusions,
        extras
	FROM
		customer_orders
), standard AS(
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        1 AS delta
	FROM
		pizzas as p
	INNER JOIN pizza_recipes as r
		ON p.pizza_id = r.pizza_id
	INNER JOIN JSON_TABLE(
		CONCAT('[', r.toppings, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) AS jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), included AS (
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        1 AS delta
	FROM
		pizzas as p
	INNER JOIN JSON_TABLE(
		CONCAT('[', p.extras, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), excluded AS (
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        -1 AS delta
	FROM
		pizzas AS p
	INNER JOIN JSON_TABLE(
		CONCAT('[', p.exclusions, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), all_toppings AS (
	SELECT * FROM standard
	UNION ALL
    SELECT * FROM included
    UNION ALL
    SELECT * FROM excluded
), aggregated AS (
	SELECT
		order_id,
        pizza_id,
        pizza_instance,
        topping_name,
        SUM(delta) AS quantity
	FROM
		all_toppings
	GROUP BY
		order_id,
        pizza_id,
        pizza_instance,
        topping_name
	HAVING SUM(delta) > 0
)
SELECT 
	a.topping_name, 
	SUM(a.quantity) AS total 
FROM 
	aggregated AS a
INNER JOIN runner_orders AS r
	ON a.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY a.topping_name
ORDER BY SUM(a.quantity) DESC, topping_name;


/*
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
*/

/*
1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
how much money has Pizza Runner made so far if there are no delivery fees?
*/

WITH costs AS(
	SELECT
		c.order_id,
        c.pizza_id,
		CASE
			WHEN n.pizza_name = 'Meatlovers' THEN 12
			WHEN n.pizza_name = 'Vegetarian' THEN 10
		END AS pizza_cost
	FROM
		customer_orders as c
	INNER JOIN runner_orders AS r
		ON c.order_id = r.order_id
	INNER JOIN pizza_names AS n
		ON c.pizza_id = n.pizza_id
	WHERE r.cancellation IS NULL
)
SELECT
	CONCAT(
		'$',
		SUM(pizza_cost)
        ) AS earnings
FROM costs;


-- 2. What if there was an additional $1 charge for any pizza extras?

 WITH pizzas AS(
	SELECT
		order_id,
        pizza_id,
        ROW_NUMBER() OVER(PARTITION BY order_id, pizza_id ORDER BY order_id) AS pizza_instance,
        exclusions,
        extras
	FROM
		customer_orders
), extra_unpack AS (
	SELECT
		p.order_id,
		p.pizza_id,
        p.pizza_instance,
		t.topping_name,
        1 AS delta
	FROM
		pizzas as p
	INNER JOIN JSON_TABLE(
		CONCAT('[', p.extras, ']'),
		'$[*]' COLUMNS (topping_id INT PATH '$')
		) jt ON TRUE
	INNER JOIN pizza_toppings AS t
		ON jt.topping_id = t.topping_id
), count_extras AS(
	SELECT
		order_id,
        pizza_id,
        pizza_instance,
		SUM(delta) AS extra_quantity
	FROM
		extra_unpack
	GROUP BY order_id, pizza_id, pizza_instance
), costs AS(
	SELECT
		p.order_id,
        p.pizza_id,
        p.pizza_instance,
		CASE
			WHEN n.pizza_name = 'Meatlovers' THEN 12
			WHEN n.pizza_name = 'Vegetarian' THEN 10
		END AS pizza_cost,
        COALESCE(ct.extra_quantity, 0) AS extra_quantity
	FROM
		pizzas AS p
	LEFT JOIN count_extras as ct
		ON p.order_id = ct.order_id
        AND p.pizza_id = ct.pizza_id
        AND p.pizza_instance = ct.pizza_instance
	INNER JOIN runner_orders AS r
		ON p.order_id = r.order_id
	INNER JOIN pizza_names AS n
		ON p.pizza_id = n.pizza_id
	WHERE r.cancellation IS NULL
)
SELECT
	CONCAT(
		'$',
		SUM(pizza_cost + extra_quantity)
        ) AS earnings
FROM costs;
-- verified, only 4 extras delivered

/*
The Pizza Runner team now wants to add an additional 
ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset - 
generate a schema for this new table and insert your own data for 
ratings for each successful customer order between 1 to 5.
*/

-- New table
CREATE TABLE IF NOT EXISTS runner_ratings (
	rating_id INT AUTO_INCREMENT PRIMARY KEY,
	order_id INT NOT NULL,
    runner_id INT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rating_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- random applicable data for new table
INSERT INTO runner_ratings (order_id, runner_id, rating) VALUES
(1, 1, 5),
(2, 1, 4),
(3, 1, 5),
(4, 2, 3),
(5, 3, 4),
(7, 2, 5),
(8, 2, 4),
(10, 1, 5);

/*
Using your newly generated table - can you join all of the 
information together to form a table which has the following
 information for successful deliveries?
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
*/

WITH pizza_counts AS (
	SELECT
		order_id,
        COUNT(*) AS total_pizzas
	FROM customer_orders
    GROUP BY order_id
)
SELECT 
	c.customer_id,
	r.order_id,
    r.runner_id,
    rat.rating,
    c.order_time,
    r.pickup_time,
    
    -- Time diff calculation
   	CONCAT(ROUND(TIMESTAMPDIFF(minute, c.order_time, r.pickup_time)), ' min') AS elapsed_time,
    
    r.duration,
    
    -- Avg speed calc
    ROUND(r.distance / r.duration, 2) as avg_speed,
    
    p.total_pizzas
FROM
	runner_orders as r
JOIN customer_orders as c
	ON r.order_id = c.order_id
JOIN pizza_counts as p
	ON r.order_id = p.order_id
LEFT JOIN runner_ratings as rat
	ON r.order_id = rat.order_id
WHERE r.cancellation IS NULL;


/*
If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices 
with no cost for extras and each runner is paid 
$0.30 per kilometre traveled - how much money 
does Pizza Runner have left over after these deliveries?
*/
WITH costs AS(
	SELECT
		c.order_id,
        c.pizza_id,
        r.distance,
		CASE
			WHEN n.pizza_name = 'Meatlovers' THEN 12
			WHEN n.pizza_name = 'Vegetarian' THEN 10
		END AS pizza_cost
	FROM
		customer_orders as c
	INNER JOIN runner_orders AS r
		ON c.order_id = r.order_id
	INNER JOIN pizza_names AS n
		ON c.pizza_id = n.pizza_id
	WHERE r.cancellation IS NULL
)
SELECT
	CONCAT(
		'$',
		ROUND(SUM(pizza_cost) - SUM(distance * 0.3), 2)
        ) AS company_earnings
FROM costs;
