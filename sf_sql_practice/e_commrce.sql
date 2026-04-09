
create database e_commerce_db;
create schema e_commerce_schema;

-- CUSTOMERS
CREATE TABLE customers (
  customer_id   INT PRIMARY KEY,
  name          VARCHAR(100),
  email         VARCHAR(150) UNIQUE,
  city          VARCHAR(50),
  signup_date   DATE
);

-- PRODUCTS
CREATE TABLE products (
  product_id    INT PRIMARY KEY,
  product_name  VARCHAR(100),
  category      VARCHAR(50),
  price         DECIMAL(10,2),
  stock_qty     INT
);

-- ORDERS
CREATE TABLE orders (
  order_id      INT PRIMARY KEY,
  customer_id   INT REFERENCES customers(customer_id),
  order_date    DATE,
  status        VARCHAR(20),  -- PENDING/SHIPPED/DELIVERED/CANCELLED
  total_amount  DECIMAL(10,2)
);

-- ORDER_ITEMS
CREATE TABLE order_items (
  item_id       INT PRIMARY KEY,
  order_id      INT REFERENCES orders(order_id),
  product_id    INT REFERENCES products(product_id),
  quantity      INT,
  unit_price    DECIMAL(10,2)
);




INSERT INTO customers VALUES
(1,'Amit Shah','amit@gmail.com','Mumbai','2022-01-15'),
(2,'Priya Mehta','priya@gmail.com','Pune','2022-03-20'),
(3,'Raj Kumar','raj@gmail.com','Delhi','2023-06-10'),
(4,'Neha Singh','neha@gmail.com','Bangalore','2023-09-05'),
(5,'Arjun Patel','arjun@gmail.com','Chennai','2024-01-01');

INSERT INTO products VALUES
(1,'Laptop Pro','Electronics',75000,50),
(2,'Wireless Earbuds','Electronics',3500,200),
(3,'Office Chair','Furniture',12000,30),
(4,'Python Book','Books',800,500),
(5,'Standing Desk','Furniture',25000,20);

INSERT INTO orders VALUES
(101,1,'2024-01-10','DELIVERED',78500),
(102,2,'2024-01-15','SHIPPED',3500),
(103,1,'2024-02-01','DELIVERED',12800),
(104,3,'2024-02-10','CANCELLED',25000),
(105,4,'2024-03-05','PENDING',4300),
(106,2,'2024-03-10','DELIVERED',37000);

INSERT INTO order_items VALUES
(1,101,1,1,75000),(2,101,4,2,800),(3,102,2,1,3500),
(4,103,3,1,12000),(5,103,4,1,800),(6,104,5,1,25000),
(7,105,2,1,3500),(8,105,4,1,800),(9,106,1,0,0),(10,106,3,1,12000);



--Find the top 2 most expensive products in each category.
SELECT * FROM (
  SELECT category, product_name, price,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS rn
  FROM products
) t WHERE rn <= 2;


Using CTEs, find customers who placed more than 1 order and their total spend.

WITH customer_orders AS (
  SELECT customer_id,
    COUNT(order_id) AS order_count,
    SUM(total_amount) AS total_spend
  FROM orders
  WHERE status != 'CANCELLED'
  GROUP BY customer_id
  HAVING COUNT(order_id) > 1
)
SELECT c.name, co.order_count, co.total_spend
FROM customer_orders co
JOIN customers c ON c.customer_id = co.customer_id
ORDER BY total_spend DESC;


--List all customers with their total order amount (include customers with no orders, show 0)
SELECT c.name, c.city,
  COALESCE(SUM(o.total_amount), 0) AS total_spend
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
  AND o.status != 'CANCELLED'
GROUP BY c.customer_id, c.name, c.city
ORDER BY total_spend DESC;


--Calculate running total of revenue by order date
SELECT order_date,
  SUM(total_amount) AS daily_revenue,
  SUM(SUM(total_amount)) OVER (
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total
FROM orders
WHERE status != 'CANCELLED'
GROUP BY order_date;

--Find products that have never been ordered.

SELECT product_id, product_name, category
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM order_items oi
  WHERE oi.product_id = p.product_id
);