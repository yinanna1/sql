USE interview_practice;
SELECT DATABASE();
SHOW TABLES;
SELECT * FROM employees LIMIT 100;
CREATE TABLE IF NOT EXISTS employees (
  emp_id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  department VARCHAR(50) NOT NULL,
  salary INT NOT NULL,
  hire_date DATE NOT NULL,
  manager_id INT NULL
);


USE interview_practice;
DESCRIBE employees;
ALTER TABLE employees ADD COLUMN manager_id INT NULL;
DROP TABLE employees;

INSERT INTO employees (first_name,last_name,department,salary,hire_date,manager_id) VALUES
('Ava','Chen','Engineering',140000,'2022-03-15',NULL),
('Liam','Wang','Engineering',125000,'2023-01-10',1),
('Mia','Li','Engineering',118000,'2023-06-05',1),
('Noah','Zhang','Data',132000,'2022-11-01',NULL),
('Emma','Liu','Data',115000,'2023-09-18',4),
('Olivia','Xu','HR',82000,'2021-04-20',NULL),
('Ethan','Zhao','HR',76000,'2023-02-14',6),
('Sophia','Sun','Sales',105000,'2022-07-07',NULL),
('James','Guo','Sales',98000,'2023-08-28',8);

USE interview_practice;

SELECT * 
FROM employees;

#practice#1 manager id = null
SELECT first_name, last_name
FROM employees
WHERE manager_id is NULL;

#practice#2 get their names out
SELECT 
	e.first_name AS employee_first,
    e.last_name AS employee_last,
    m.first_name AS manager_first,
    m.last_name AS manager_last
FROM employees e
LEFT JOIN employees m
	ON e.manager_id = m.emp_id;
