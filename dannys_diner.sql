/*
Danny's Diner Case Study
Working file for SQL practice
Written and Executed in MySQL
*/

-- Database Setup
CREATE DATABASE IF NOT EXISTS dannys_diner;
USE dannys_diner;

-- Create Tables
/*
CREATE TABLE sales (
	customer_id VARCHAR(1),
    order_date DATE,
    product_id INT
);
INSERT INTO sales (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
  
  CREATE TABLE menu (
	product_id INT,
    product_name VARCHAR(5),
    price INT
);
INSERT INTO menu(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members (
	customer_id VARCHAR(1),
    join_date DATE
);
INSERT INTO members(customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
*/

-- Questions

/*
Question 1
What is the total amount each customer spent at the restaurant?
*/

-- WRITE QUERY HERE
SELECT customer_id, SUM(price) as total_spend
FROM sales as s
INNER JOIN menu as m on s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_spend DESC;


/*
Question 2
How many days has each customer visited the restaurant?
*/

-- WRITE QUERY HERE
SELECT customer_id, COUNT(DISTINCT order_date) as num_visits
FROM sales
GROUP BY customer_id;


/*
Question 3
What was the first item from the menu purchased by each customer?
*/

-- WRITE QUERY HERE
WITH CTE AS (
	SELECT 
	s.customer_id, 
	s.order_date,
	m.product_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as rnk
	FROM sales as s
	INNER JOIN menu as m on s.product_id = m.product_id
	ORDER BY order_date
	)
SELECT *
FROM CTE
WHERE rnk = 1;

/*
Question 4
What is the most purchased item on the menu and how many times was it purchased by all customers?
*/

-- WRITE QUERY HERE
SELECT COUNT(s.product_id) as total_buy, product_name
FROM sales as s
INNER JOIN menu as m on s.product_id = m.product_id
GROUP BY product_name
ORDER BY total_buy DESC
LIMIT 1;


/*
Question 5
Which item was the most popular for each customer?
*/

-- WRITE QUERY HERE
WITH CTE AS (
	SELECT 
	customer_id,
	product_name, 
	COUNT(s.product_id) as total_buy, 
	RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(s.product_id) DESC) as rnk,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(s.product_id) DESC) as rn
	FROM sales as s
	INNER JOIN menu as m on s.product_id = m.product_id
	GROUP BY product_name, customer_id
	)
SELECT customer_id, product_name
FROM CTE
-- WHERE rnk = 1
WHERE rn = 1;

/*
Question 6
Which item was purchased first by the customer after they became a member?
*/

-- WRITE QUERY HERE
WITH CTE AS (
	SELECT
	s.customer_id,
	order_date,
	join_date,
	product_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as rnk,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as rn
	FROM sales as s
	INNER JOIN members as mb on s.customer_id = mb.customer_id
	INNER JOIN menu as mu on s.product_id = mu.product_id
	WHERE order_date >= join_date
	)
SELECT customer_id, product_name
FROM CTE
WHERE rnk = 1;

/*
Question 7
Which item was purchased just before the customer became a member?
*/

-- WRITE QUERY HERE
WITH CTE AS (
	SELECT
	s.customer_id,
	order_date,
	join_date,
	product_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as rnk,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as rn
	FROM sales as s
	INNER JOIN members as mb on s.customer_id = mb.customer_id
	INNER JOIN menu as mu on s.product_id = mu.product_id
	WHERE order_date < join_date
	)
SELECT customer_id, product_name
FROM CTE
WHERE rnk = 1;



/*
Question 8
What is the total items and amount spent for each member before they became a member?
*/

-- WRITE QUERY HERE
SELECT
s.customer_id,
COUNT(product_name) total_items,
SUM(price) as total_spent
FROM sales as s
INNER JOIN members as mb on s.customer_id = mb.customer_id
INNER JOIN menu as mu on s.product_id = mu.product_id
WHERE order_date < join_date
GROUP BY s.customer_id;


/*
Question 9
If each $1 spent equates to 10 points and sushi has a 2x points multiplier,
how many points would each customer have?
*/

-- WRITE QUERY HERE
SELECT 
customer_id,
SUM(CASE
WHEN product_name = 'sushi' THEN price * 10 * 2
ELSE price * 10
END) AS points
FROM menu as m
INNER JOIN sales as s on m.product_id = s.product_id
GROUP BY customer_id;


/*
Question 10
In the first week after a customer joins the program (including their join date)
they earn 2x points on all items, not just sushi.
How many points do customer A and B have at the end of January?
*/

-- WRITE QUERY HERE
SELECT
s.customer_id,
SUM(CASE
WHEN DATEDIFF(order_date, join_date) BETWEEN 0 AND 6 THEN price *10*2
WHEN product_name = 'sushi' THEN price * 10 * 2
ELSE price * 10
END) as points
FROM menu as m
INNER JOIN sales as s on s.product_id = m.product_id
INNER JOIN members as mem on s.customer_id = mem.customer_id
WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY s.customer_id;


/*
Bonus Question 1
Join All The Things

Recreate the following table output using the available data:

customer_id | order_date | product_name | price | member
*/

-- WRITE QUERY HERE
SELECT
s.customer_id,
s.order_date,
mu.product_name,
mu.price,
CASE
WHEN join_date is null THEN 'N'
WHEN join_date > order_date THEN 'N'
ELSE 'Y'
END as member
FROM sales as s
INNER JOIN menu as mu on s.product_id = mu.product_id
LEFT JOIN members as mb on s.customer_id = mb.customer_id
ORDER BY s.customer_id ASC, order_date ASC, price DESC;



/*
Bonus Question 2
Rank All The Things

Danny also requires further information about the ranking of customer products,
but he purposely does not need the ranking for non-member purchases so he expects
null ranking values for the records when customers are not yet part of the loyalty program.

Recreate the following table output using the available data:

customer_id | order_date | product_name | price | member | ranking
*/

-- WRITE QUERY HERE
CREATE OR REPLACE VIEW ranked_customer_sales AS
WITH CTE AS (
	SELECT
	s.customer_id,
	s.order_date,
	mu.product_name,
	mu.price,
	CASE
	WHEN join_date is null THEN 'N'
	WHEN join_date > order_date THEN 'N'
	ELSE 'Y'
	END as member
	FROM sales as s
	INNER JOIN menu as mu on s.product_id = mu.product_id
	LEFT JOIN members as mb on s.customer_id = mb.customer_id
	ORDER BY s.customer_id ASC, order_date ASC, price DESC
	)
SELECT
*,
CASE
WHEN member = 'N' THEN null
ELSE RANK() OVER(partition by customer_id, member ORDER BY order_date) 
END as rnk
FROM CTE;

SELECT * FROM ranked_customer_sales;

-- BONUS DATASET FOR VISUALIZATION
CREATE OR REPLACE VIEW ranked_customer_sales_with_points AS
WITH base AS (
    SELECT
        s.customer_id,
        s.order_date,
        mu.product_name,
        mu.price,
        mb.join_date,
        CASE
            WHEN mb.join_date IS NULL THEN 'N'
            WHEN mb.join_date > s.order_date THEN 'N'
            ELSE 'Y'
        END AS member
    FROM sales AS s
    INNER JOIN menu AS mu
        ON s.product_id = mu.product_id
    LEFT JOIN members AS mb
        ON s.customer_id = mb.customer_id
)
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,

    -- ranking only applies to member purchases
    CASE
        WHEN member = 'N' THEN NULL
        ELSE RANK() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        )
    END AS rnk,

    -- points earned per purchase
    CASE
        WHEN member = 'Y'
             AND DATEDIFF(order_date, join_date) BETWEEN 0 AND 6
            THEN price * 10 * 2
        WHEN product_name = 'sushi'
            THEN price * 10 * 2
        ELSE price * 10
    END AS points

FROM base;
SELECT * FROM ranked_customer_sales_with_points;