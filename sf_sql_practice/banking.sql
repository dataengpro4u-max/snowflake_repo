create database banking_db;
create schema banking_schema;


-- CUSTOMERS
CREATE TABLE customers (
  customer_id   INT PRIMARY KEY,
  name          VARCHAR(100),
  city          VARCHAR(50),
  credit_score  INT,
  join_date     DATE
);

-- ACCOUNTS
CREATE TABLE accounts (
  account_id    INT PRIMARY KEY,
  customer_id   INT REFERENCES customers(customer_id),
  account_type  VARCHAR(20),  -- SAVINGS/CURRENT/FD
  balance       DECIMAL(15,2),
  opened_date   DATE
);

-- TRANSACTIONS
CREATE TABLE transactions (
  txn_id        INT PRIMARY KEY,
  account_id    INT REFERENCES accounts(account_id),
  txn_date      DATE,
  txn_type      VARCHAR(10),  -- CREDIT/DEBIT
  amount        DECIMAL(12,2),
  description   VARCHAR(200)
);

-- LOANS
CREATE TABLE loans (
  loan_id       INT PRIMARY KEY,
  customer_id   INT REFERENCES customers(customer_id),
  loan_type     VARCHAR(20),  -- HOME/PERSONAL/AUTO
  principal     DECIMAL(15,2),
  interest_rate DECIMAL(5,2),
  status        VARCHAR(10)   -- ACTIVE/CLOSED/DEFAULT
);


INSERT INTO customers VALUES
(1,'Rahul Verma','Mumbai',780,'2019-03-10'),
(2,'Sunita Rao','Pune',720,'2020-07-15'),
(3,'Vikram Joshi','Delhi',650,'2021-01-20'),
(4,'Kavya Nair','Chennai',810,'2018-11-05'),
(5,'Deepak Gupta','Bangalore',590,'2022-06-30');

INSERT INTO accounts VALUES
(1001,1,'SAVINGS',150000,'2019-03-10'),
(1002,1,'CURRENT',500000,'2019-03-10'),
(1003,2,'SAVINGS',80000,'2020-07-15'),
(1004,3,'SAVINGS',20000,'2021-01-20'),
(1005,4,'FD',1000000,'2018-11-05'),
(1006,5,'SAVINGS',5000,'2022-06-30');

INSERT INTO transactions VALUES
(1,1001,'2024-01-05','CREDIT',50000,'Salary'),
(2,1001,'2024-01-10','DEBIT',15000,'Rent'),
(3,1002,'2024-01-12','DEBIT',200000,'Business payment'),
(4,1003,'2024-02-01','CREDIT',30000,'Salary'),
(5,1003,'2024-02-15','DEBIT',5000,'Utility'),
(6,1004,'2024-02-20','DEBIT',18000,'EMI'),
(7,1005,'2024-03-01','CREDIT',75000,'Interest'),
(8,1006,'2024-03-05','DEBIT',4500,'ATM');

INSERT INTO loans VALUES
(1,1,'HOME',5000000,7.5,'ACTIVE'),
(2,2,'PERSONAL',200000,12.0,'ACTIVE'),
(3,3,'AUTO',800000,9.0,'DEFAULT'),
(4,4,'HOME',3000000,7.0,'CLOSED'),
(5,5,'PERSONAL',100000,15.0,'ACTIVE');

--For each account, show each transaction amount and the previous transaction amount using LAG.

SELECT account_id, txn_date, txn_type, amount,
  LAG(amount) OVER (
    PARTITION BY account_id
    ORDER BY txn_date
  ) AS prev_txn_amount
FROM transactions
ORDER BY account_id, txn_date;

--Find customers who have both an active loan AND a balance below 10000 (high risk).

WITH low_balance AS (
  SELECT customer_id, SUM(balance) AS total_balance
  FROM accounts
  GROUP BY customer_id
  HAVING SUM(balance) < 10000
),
active_loans AS (
  SELECT DISTINCT customer_id
  FROM loans
  WHERE status = 'ACTIVE'
)
SELECT c.name, c.credit_score, lb.total_balance
FROM customers c
JOIN low_balance lb ON c.customer_id = lb.customer_id
JOIN active_loans al ON c.customer_id = al.customer_id;


--Rank customers into 4 quartiles based on their total account balance.
SELECT c.name,
  SUM(a.balance) AS total_balance,
  NTILE(4) OVER (ORDER BY SUM(a.balance) DESC) AS quartile
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_balance DESC;

--Show total CREDIT and DEBIT amount per account side by side
SELECT account_id,
  SUM(CASE WHEN txn_type = 'CREDIT' THEN amount ELSE 0 END) AS total_credit,
  SUM(CASE WHEN txn_type = 'DEBIT'  THEN amount ELSE 0 END) AS total_debit,
  SUM(CASE WHEN txn_type = 'CREDIT' THEN amount ELSE -amount END) AS net_flow
FROM transactions
GROUP BY account_id
ORDER BY account_id;