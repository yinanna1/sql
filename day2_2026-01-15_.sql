SELECT DATABASE();
SHOW TABLES;
USE interview_practice;

DROP TABLE IF EXISTS products;

CREATE TABLE products (
  product_id INT PRIMARY KEY,
  low_fats CHAR(1),
  recyclable CHAR(1)
);

INSERT INTO products (product_id, low_fats, recyclable) VALUES
(0,'Y','N'),
(1,'Y','Y'),
(2,'N','Y'),
(3,'Y','Y'),
(4,'N','N');

SHOW TABLES;
SELECT * FROM products;

SELECT product_id
FROM products
WHERE low_fats = 'Y'
	AND recyclable = 'Y';
