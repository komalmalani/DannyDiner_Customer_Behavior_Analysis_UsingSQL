
CREATE SCHEMA dannys_diner;
USE dannys_diner;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from sales;
select * from menu;
select * from members;
  
-- 1.  What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) As total_spend
FROM sales s JOIN menu m USING (product_id)
GROUP BY s.customer_id;

--2.  How many days has each customer visited the restaurant?
SELECT s.customer_id, COUNT(Distinct s.order_date) as number_of_days
FROM sales s
GROUP BY s.customer_id;

-- 3.	What was the first item from the menu purchased by each customer?
WITH First_order_4_each_customer AS (
SELECT s.customer_id AS customer, m.product_name AS product,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rowid
FROM sales s JOIN menu m USING (product_id) )

SELECT customer,product
FROM First_order_4_each_customer
WHERE rowid=1;

-- 4. What is the most purchased item on the menu and 
-- how many times was it purchased by all customers?
SELECT m.product_name, count(s.product_id) AS purchase_count
FROM sales s JOIN menu m USING (product_id)
GROUP BY m.product_name
ORDER BY purchase_count DESC;

--5. Which item was the most popular for each customer?
WITH most_popular AS (
SELECT s.customer_id, m.product_name,
 count(s.product_id) AS purchase_count,
RANK() OVER(PARTITION BY s.customer_id ORDER BY count(s.product_id) DESC ) AS rank1
FROM sales s JOIN menu m USING (product_id) 
/*SELECT customer_id,product_name,purchase_count FROM  abc*/
GROUP BY s.customer_id, m.product_name) 
SELECT customer_id,product_name,purchase_count
FROM most_popular 
WHERE rank1=1;

--6. Which item was purchased first by the customer after they became a member?
WITH Purchased_first AS 
(SELECT customer_id,product_name,order_date,
dense_rank() OVER (PARTITION BY customer_id ORDER BY order_date ASC ) AS rank1
FROM sales JOIN menu USING (product_id) 
JOIN members USING (customer_id)
WHERE order_date >= join_date
 )
SELECT * from Purchased_first WHERE rank1 =1;

-- 7.Which item was purchased just before the customer became a member?
WITH purchase_bfore_membership AS (
SELECT customer_id,product_name,order_date,
dense_rank() OVER (PARTITION BY customer_id ORDER BY order_date DESC ) AS rank1
FROM sales INNER JOIN menu USING (product_id) 
INNER JOIN members USING (customer_id)
WHERE order_date < join_date )

SELECT * FROM purchase_bfore_membership WHERE rank1=1;


-- 8. What is the total items and amount spent for each member before they became a member?
WITH CTE AS (
SELECT * 
FROM sales INNER JOIN menu USING (product_id) 
INNER JOIN members USING (customer_id)
WHERE order_date < join_date  )

SELECT customer_id,COUNT(product_id) AS total_items ,SUM(price)  AS total_spent
FROM CTE
GROUP BY customer_id
ORDER BY customer_id
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier
-- how many points would each customer have?
WITH CTE AS (
SELECT customer_id,
SUM(CASE WHEN product_name='sushi' THEN price*20 
         ELSE price*10 END)  AS points
FROM sales INNER JOIN menu USING (product_id) 
GROUP BY customer_id )
select * from CTE ORDER BY customer_id;

-- 10. In the first week after a customer joins the program 
--(including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?

WITH Jan_point AS (
	SELECT *,
	join_date + interval '7 days' AS valid_date,
	TO_DATE('2021-01-31','YYYY-MM-DD')as last_day
	FROM MEMBERS)
SELECT s.customer_id,
       SUM( CASE WHEN s.order_date between join_date and valid_date THEN price*20 END) as point_earned
FROM jan_point j inner join sales s
ON j.customer_id = s.customer_id
inner join menu m
ON s.product_id = m.product_id
WHERE s.order_date <= last_day
GROUP BY s.customer_id;
	
	
	
