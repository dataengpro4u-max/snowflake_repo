create database healthcare_db;
create schema healthcare_schema;

-- PATIENTS
CREATE TABLE patients (
  patient_id    INT PRIMARY KEY,
  name          VARCHAR(100),
  age           INT,
  gender        CHAR(1),
  city          VARCHAR(50),
  blood_group   VARCHAR(5)
);

-- DOCTORS
CREATE TABLE doctors (
  doctor_id     INT PRIMARY KEY,
  name          VARCHAR(100),
  specialization VARCHAR(50),
  experience_yrs INT,
  city          VARCHAR(50)
);

-- APPOINTMENTS
CREATE TABLE appointments (
  appt_id       INT PRIMARY KEY,
  patient_id    INT REFERENCES patients(patient_id),
  doctor_id     INT REFERENCES doctors(doctor_id),
  appt_date     DATE,
  status        VARCHAR(20),  -- SCHEDULED/COMPLETED/CANCELLED
  fee           DECIMAL(8,2)
);

-- PRESCRIPTIONS
CREATE TABLE prescriptions (
  rx_id         INT PRIMARY KEY,
  appt_id       INT REFERENCES appointments(appt_id),
  medicine      VARCHAR(100),
  dosage        VARCHAR(50),
  days          INT
);


INSERT INTO patients VALUES
(1,'Meera Iyer',45,'F','Chennai','A+'),
(2,'Rohit Das',32,'M','Kolkata','B+'),
(3,'Anjali Roy',60,'F','Pune','O+'),
(4,'Suresh Nair',28,'M','Mumbai','AB+'),
(5,'Lakshmi Devi',55,'F','Hyderabad','A-');

INSERT INTO doctors VALUES
(1,'Dr. Sharma','Cardiology',15,'Mumbai'),
(2,'Dr. Patel','Orthopedics',10,'Pune'),
(3,'Dr. Rao','Neurology',20,'Chennai'),
(4,'Dr. Gupta','General',5,'Delhi');

INSERT INTO appointments VALUES
(1,1,1,'2024-01-10','COMPLETED',1500),
(2,2,2,'2024-01-15','COMPLETED',1200),
(3,3,1,'2024-02-01','COMPLETED',1500),
(4,1,3,'2024-02-10','CANCELLED',0),
(5,4,4,'2024-03-01','COMPLETED',500),
(6,5,1,'2024-03-15','SCHEDULED',1500),
(7,3,3,'2024-03-20','COMPLETED',2000);

INSERT INTO prescriptions VALUES
(1,1,'Amlodipine','5mg OD',30),
(2,1,'Aspirin','75mg OD',30),
(3,2,'Ibuprofen','400mg TDS',7),
(4,3,'Atorvastatin','10mg OD',90),
(5,5,'Paracetamol','500mg BD',5),
(6,7,'Clopidogrel','75mg OD',60);


--Rank doctors by total revenue earned (completed appointments only).
SELECT d.name, d.specialization,
  SUM(a.fee) AS total_revenue,
  DENSE_RANK() OVER (ORDER BY SUM(a.fee) DESC) AS revenue_rank
FROM doctors d
JOIN appointments a ON d.doctor_id = a.doctor_id
WHERE a.status = 'COMPLETED'
GROUP BY d.doctor_id, d.name, d.specialization
ORDER BY revenue_rank;


--Find patients who visited more than one doctor.
WITH patient_doctors AS (
  SELECT patient_id,
    COUNT(DISTINCT doctor_id) AS doctor_count
  FROM appointments
  WHERE status = 'COMPLETED'
  GROUP BY patient_id
  HAVING COUNT(DISTINCT doctor_id) > 1
)
SELECT p.name, p.age, pd.doctor_count
FROM patients p
JOIN patient_doctors pd ON p.patient_id = pd.patient_id;




--Find doctors who have not had any cancelled appointments.

SELECT doctor_id, name, specialization
FROM doctors d
WHERE NOT EXISTS (
  SELECT 1 FROM appointments a
  WHERE a.doctor_id = d.doctor_id
  AND a.status = 'CANCELLED'
);



--Show total appointments per doctor per month with a grand total
SELECT
  d.name AS doctor,
  DATE_TRUNC('month', a.appt_date) AS month,
  COUNT(*) AS appointments
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
GROUP BY ROLLUP(d.name, DATE_TRUNC('month', a.appt_date))
ORDER BY doctor, month;