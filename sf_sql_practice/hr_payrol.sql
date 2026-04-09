create database hr_payrol_db;
create schema hr_payrol_schema;

-- DEPARTMENTS
CREATE TABLE departments (
  dept_id       INT PRIMARY KEY,
  dept_name     VARCHAR(50),
  location      VARCHAR(50),
  manager_id    INT
);

-- EMPLOYEES
CREATE TABLE employees (
  emp_id        INT PRIMARY KEY,
  name          VARCHAR(100),
  dept_id       INT REFERENCES departments(dept_id),
  role          VARCHAR(50),
  hire_date     DATE,
  manager_id    INT REFERENCES employees(emp_id)
);

-- SALARIES
CREATE TABLE salaries (
  sal_id        INT PRIMARY KEY,
  emp_id        INT REFERENCES employees(emp_id),
  effective_date DATE,
  salary        DECIMAL(12,2),
  salary_type   VARCHAR(10)   -- MONTHLY/ANNUAL
);

-- LEAVE_REQUESTS
CREATE TABLE leave_requests (
  leave_id      INT PRIMARY KEY,
  emp_id        INT REFERENCES employees(emp_id),
  leave_type    VARCHAR(20),  -- SICK/CASUAL/ANNUAL
  start_date    DATE,
  end_date      DATE,
  status        VARCHAR(10)   -- APPROVED/REJECTED/PENDING
);




INSERT INTO departments VALUES
(1,'Engineering','Pune',1),
(2,'Data & Analytics','Bangalore',3),
(3,'HR','Mumbai',5),
(4,'Finance','Mumbai',4);

INSERT INTO employees VALUES
(1,'Anand Mishra',1,'Lead Engineer','2018-04-01',NULL),
(2,'Pooja Tiwari',1,'Senior Engineer','2020-06-15',1),
(3,'Kiran Reddy',2,'Data Architect','2017-01-10',NULL),
(4,'Sanjay Bose',4,'Finance Manager','2019-09-01',NULL),
(5,'Ritu Sharma',3,'HR Manager','2016-03-20',NULL),
(6,'Nikhil Jain',2,'Data Engineer','2021-07-01',3),
(7,'Divya Menon',2,'Data Analyst','2022-02-14',3);

INSERT INTO salaries VALUES
(1,1,'2023-01-01',180000,'MONTHLY'),
(2,2,'2023-01-01',120000,'MONTHLY'),
(3,3,'2023-01-01',200000,'MONTHLY'),
(4,4,'2023-01-01',150000,'MONTHLY'),
(5,5,'2023-01-01',100000,'MONTHLY'),
(6,6,'2023-01-01',110000,'MONTHLY'),
(7,7,'2023-01-01',85000,'MONTHLY');

INSERT INTO leave_requests VALUES
(1,2,'SICK','2024-01-08','2024-01-09','APPROVED'),
(2,6,'CASUAL','2024-02-14','2024-02-14','APPROVED'),
(3,3,'ANNUAL','2024-03-01','2024-03-07','APPROVED'),
(4,7,'SICK','2024-03-10','2024-03-11','PENDING'),
(5,1,'ANNUAL','2024-04-15','2024-04-20','APPROVED');


--Find employees earning above the average salary of their department
SELECT e.name, d.dept_name, s.salary,
  AVG(s.salary) OVER (PARTITION BY e.dept_id) AS dept_avg
FROM employees e
JOIN salaries s ON e.emp_id = s.emp_id
JOIN departments d ON e.dept_id = d.dept_id
WHERE s.salary > (
  SELECT AVG(s2.salary)
  FROM salaries s2
  JOIN employees e2 ON s2.emp_id = e2.emp_id
  WHERE e2.dept_id = e.dept_id
);

--List each employee with their manager's name.
SELECT
  e.name AS employee,
  e.role,
  m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY e.dept_id, e.emp_id;



---Categorize employees by tenure: <2 yrs = Junior, 2-5 yrs = Mid, >5 yrs = Senior.
WITH tenure_calc AS (
  SELECT name, role, hire_date,
    DATEDIFF('year', hire_date, CURRENT_DATE) AS years
  FROM employees
)
SELECT name, role, years,
  CASE
    WHEN years < 2 THEN 'Junior'
    WHEN years BETWEEN 2 AND 5 THEN 'Mid-Level'
    ELSE 'Senior'
  END AS tenure_band
FROM tenure_calc
ORDER BY years DESC;


---Find total approved leave days per employee (end_date - start_date).

SELECT e.name, e.role,
  SUM(DATEDIFF('day', lr.start_date, lr.end_date) + 1) AS total_leave_days,
  COUNT(*) AS leave_requests
FROM employees e
JOIN leave_requests lr ON e.emp_id = lr.emp_id
WHERE lr.status = 'APPROVED'
GROUP BY e.emp_id, e.name, e.role
ORDER BY total_leave_days DESC;