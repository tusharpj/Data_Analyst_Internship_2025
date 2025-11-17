-- task3.sql (part 1) 
DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce;
USE ecommerce;

-- Customers
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150),
  category VARCHAR(50),
  price DECIMAL(10,2),
  stock INT
);

-- Orders (header)
CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  status VARCHAR(20),
  total_amount DECIMAL(10,2),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order items (line items)
CREATE TABLE order_items (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  product_id INT,
  quantity INT,
  unit_price DECIMAL(10,2),
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Payments
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  paid_amount DECIMAL(10,2),
  payment_date DATE,
  payment_method VARCHAR(30),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Insert small sample data
INSERT INTO customers (first_name, last_name, email) VALUES
('Amit','Kumar','amit@example.com'),
('Neha','Sharma','neha@example.com'),
('Raj','Singh','raj@example.com');

INSERT INTO products (name, category, price, stock) VALUES
('Wireless Mouse','Electronics',499.00,150),
('USB-C Cable','Electronics',199.00,500),
('Water Bottle','Home',299.00,200),
('Notebook','Stationery',49.00,1000);

INSERT INTO orders (customer_id, order_date, status, total_amount) VALUES
(1,'2025-11-01','delivered',998.00),
(2,'2025-11-05','shipped',548.00),
(1,'2025-11-10','pending',348.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,1,2,499.00),
(2,2,2,199.00),
(2,4,1,150.00),
(3,3,1,299.00),
(3,4,1,49.00);

INSERT INTO payments (order_id, paid_amount, payment_date, payment_method) VALUES
(1,998.00,'2025-11-02','card'),
(2,548.00,'2025-11-06','netbanking');





-- Get all tables
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM payments;

-- Orders in November 2025 (WHERE, ORDER BY)
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE order_date BETWEEN '2025-11-01' AND '2025-11-30'
ORDER BY order_date DESC;

-- Products in Electronics category sorted by price
SELECT product_id, name, category, price, stock
FROM products
WHERE category = 'Electronics'
ORDER BY price DESC;



-- INNER JOIN: order header with customer
SELECT o.order_id, o.order_date, c.first_name, c.last_name, o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC;

-- Join orders -> order_items -> products (full details)
SELECT o.order_id, o.order_date, c.first_name, p.name AS product_name, oi.quantity, oi.unit_price
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_id, p.name;

-- LEFT JOIN example: show orders and payments (payments may be missing)
SELECT o.order_id, o.total_amount, p.payment_id, p.paid_amount, p.payment_method
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
ORDER BY o.order_id;






-- Total sales per customer
SELECT c.customer_id, c.first_name, c.last_name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- Items sold by product (sum of quantities)
SELECT p.product_id, p.name, SUM(oi.quantity) AS total_units_sold, SUM(oi.quantity * oi.unit_price) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name
ORDER BY revenue DESC;

-- Customers with more than 1 order (HAVING)
SELECT c.customer_id, c.first_name, COUNT(o.order_id) AS orders_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name
HAVING orders_count > 1;





-- Inline subquery: customers who spent more than average customer
SELECT customer_id, first_name, last_name
FROM (
  SELECT c.customer_id, c.first_name, c.last_name, SUM(o.total_amount) AS total_spent
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id
) AS t
WHERE total_spent > (SELECT AVG(total_spent) FROM (SELECT SUM(total_amount) AS total_spent FROM orders GROUP BY customer_id) ss);

-- Correlated subquery: orders where order total > average order for same customer
SELECT o.order_id, o.customer_id, o.total_amount
FROM orders o
WHERE o.total_amount > (
  SELECT AVG(o2.total_amount) FROM orders o2 WHERE o2.customer_id = o.customer_id
);





-- View: customer_total_spent
CREATE OR REPLACE VIEW vw_customer_spending AS
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, customer_name;

-- Use the view
SELECT * FROM vw_customer_spending ORDER BY total_spent DESC;





-- Running total of revenue by order_date
SELECT order_id, order_date, total_amount,
       SUM(total_amount) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM orders
ORDER BY order_date;

-- Rank products by revenue
SELECT product_id, name, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM (
  SELECT p.product_id, p.name, SUM(oi.quantity * oi.unit_price) AS revenue
  FROM products p
  JOIN order_items oi ON p.product_id = oi.product_id
  GROUP BY p.product_id, p.name
) t;





-- Create indexes (example)
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- Use EXPLAIN to inspect a query plan
EXPLAIN SELECT o.order_id, o.order_date, c.first_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date BETWEEN '2025-11-01' AND '2025-11-30';





#Q1: Top 5 customers by revenue
SELECT customer_id, customer_name, total_spent
FROM vw_customer_spending
ORDER BY total_spent DESC
LIMIT 5;


#Q2: Monthly revenue (grouped by month)
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS ym,
    SUM(total_amount) AS revenue
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY DATE_FORMAT(order_date, '%Y-%m');


#Q3: Products low on stock (< 50 units)
SELECT product_id, name, stock
FROM products
WHERE stock < 50
ORDER BY stock ASC;


#Q4: Orders without payment recorded
SELECT o.order_id, o.customer_id, o.total_amount, o.status
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_id IS NULL;


#Q5: Average order value (AOV)
SELECT AVG(total_amount) AS average_order_value
FROM orders;




