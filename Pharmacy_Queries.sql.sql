-- 1. Create Medicines Table
CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50), 
    unit_price DECIMAL(10, 2),
    stock_quantity INT,
    expiry_date DATE
);

-- 2. Create Suppliers Table
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_number VARCHAR(20),
    city VARCHAR(100)
);

-- 3. Create Purchases Table
CREATE TABLE Purchases (
    purchase_id INT PRIMARY KEY,
    supplier_id INT,
    medicine_id INT,
    quantity INT,
    purchase_date DATE,
    batch_number VARCHAR(50),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id)
);

-- 4. Create Sales Table
CREATE TABLE Sales (
    sale_id INT PRIMARY KEY,
    medicine_id INT,
    quantity INT,
    sale_date DATE,
    total_price DECIMAL(10, 2),
    FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id)
);

-- Insert Sample Medicines
INSERT INTO Medicines (medicine_id, name, type, unit_price, stock_quantity, expiry_date) VALUES
(1, 'Paracetamol', 'Tablet', 5.00, 500, '2025-12-31'),
(2, 'Amoxicillin', 'Capsule', 12.50, 300, '2024-06-01'),
(3, 'Insulin', 'Injection', 450.00, 50, '2024-03-01'), 
(4, 'Vitamin C', 'Tablet', 8.00, 100, '2025-10-20'),
(5, 'Cough Syrup', 'Syrup', 80.00, 150, '2024-05-01'),
(6, 'Ibuprofen', 'Tablet', 10.00, 200, '2025-07-01');

-- Insert Sample Suppliers
INSERT INTO Suppliers (supplier_id, name, contact_number, city) VALUES
(101, 'Health Corp', '9876543210', 'Mumbai'),
(102, 'Swift Supplies', '9998887770', 'Delhi'),
(103, 'Global Pharma', '9000000000', 'Mumbai');

-- Insert Sample Purchases
INSERT INTO Purchases (purchase_id, supplier_id, medicine_id, quantity, purchase_date, batch_number) VALUES
(1, 101, 1, 300, '2024-01-05', 'P100'),
(2, 102, 3, 100, '2024-01-10', 'S200'),
(3, 101, 2, 200, '2024-02-01', 'C300');

-- Insert Sample Sales
INSERT INTO Sales (sale_id, medicine_id, quantity, sale_date, total_price) VALUES
(1001, 1, 10, '2024-01-15', 50.00),
(1002, 1, 20, '2024-02-10', 100.00),
(1003, 3, 5, '2024-02-15', 2250.00),
(1004, 2, 15, '2024-02-20', 187.50),
(1005, 2, 5, '2024-03-25', 62.50),
(1006, 5, 20, '2024-04-01', 1600.00);

-- DDL Practice Questions
-- 1. Add a column ‘manufacturer’ to the Medicines table.
ALTER TABLE Medicines
ADD COLUMN manufacturer VARCHAR(255);

-- 2. Rename the column ‘contact_number’ to ‘phone’ in Suppliers.

ALTER TABLE Suppliers
RENAME COLUMN contact_number TO phone;

-- DML Practice Questions
-- 3. Insert a new medicine 'Amoxicillin'. (Done in sample data, but re-run if needed)
INSERT INTO Medicines (medicine_id, name, type, unit_price, stock_quantity, expiry_date) 
VALUES (8, 'Dolo 650', 'Tablet', 10.00, 400, '2026-10-31');

-- 4. Update all medicine prices by 10%.
UPDATE Medicines
SET unit_price = unit_price * 1.10;
SET SQL_SAFE_UPDATES = 0;

-- 5. Delete medicines that are expired. (Assuming current date is 2024-03-15)
DELETE FROM Medicines
WHERE expiry_date < '2024-03-15';
SET SQL_SAFE_UPDATES = 0;
USE PharmacyDB;
SET SQL_SAFE_UPDATES = 0; -- Ensure Safe Mode is off (as previously needed)

-- 1. Delete dependent records from SALES

DELETE FROM Sales 
WHERE medicine_id IN (SELECT medicine_id FROM Medicines WHERE expiry_date < '2024-03-15');

-- 2. Delete dependent records from PURCHASES

DELETE FROM Purchases 
WHERE medicine_id IN (SELECT medicine_id FROM Medicines WHERE expiry_date < '2024-03-15');

-- 5. Delete medicines that are expired. (Assuming current date is 2024-03-15)
DELETE FROM Medicines
WHERE expiry_date < '2024-03-15';

-- Aggregations Practice Questions
-- 6. Find total sales revenue per medicine.
SELECT M.name, SUM(S.total_price) AS total_revenue
FROM Sales S
JOIN Medicines M ON S.medicine_id = M.medicine_id
GROUP BY M.name;

-- 7. Find the supplier who provided the maximum quantity.
SELECT S.name
FROM Purchases P
JOIN Suppliers S ON P.supplier_id = S.supplier_id
GROUP BY S.name
ORDER BY SUM(P.quantity) DESC
LIMIT 1;

-- 8. Total units sold per medicine type.
SELECT M.type, SUM(S.quantity) AS total_units_sold
FROM Sales S
JOIN Medicines M ON S.medicine_id = M.medicine_id
GROUP BY M.type;

-- Subqueries Practice Questions
-- 9. Medicines with stock below average.
SELECT name, stock_quantity
FROM Medicines
WHERE stock_quantity < (
    SELECT AVG(stock_quantity) FROM Medicines
);

-- 10. Medicines never sold.
SELECT name
FROM Medicines
WHERE medicine_id NOT IN (
    SELECT DISTINCT medicine_id FROM Sales
);

-- 11. Suppliers with total supplied quantity > 500.
SELECT S.name
FROM Purchases P
JOIN Suppliers S ON P.supplier_id = S.supplier_id
GROUP BY S.name
HAVING SUM(P.quantity) > 500;

-- 12. Medicine types where avg. price > ₹100.
SELECT type
FROM Medicines
GROUP BY type
HAVING AVG(unit_price) > 100.00;

-- JOINS Practice Questions
-- 13. List all purchase records along with medicine and supplier names.
SELECT 
    P.purchase_id, 
    M.name AS medicine_name, 
    S.name AS supplier_name, 
    P.quantity, 
    P.purchase_date
FROM Purchases P
JOIN Medicines M ON P.medicine_id = M.medicine_id
JOIN Suppliers S ON P.supplier_id = S.supplier_id;

-- 14. Show all sales with corresponding medicine name and type.
SELECT 
    S.sale_id, 
    M.name AS medicine_name, 
    M.type, 
    S.quantity, 
    S.sale_date, 
    S.total_price
FROM Sales S
JOIN Medicines M ON S.medicine_id = M.medicine_id;

-- DATE FUNCTIONS
-- 15. List medicines that will expire within the next 90 days.

SELECT 
    name, 
    expiry_date 
FROM 
    Medicines 
WHERE 
    expiry_date BETWEEN '2024-03-15' AND DATE_ADD('2024-03-15', INTERVAL 90 DAY);
    
    -- 16. Count number of sales made in the last 30 days.
SELECT COUNT(sale_id) AS sales_in_last_30_days
FROM Sales
WHERE sale_date >= DATE('2024-02-15');

-- STRING FUNCTIONS
-- 17. List supplier names that start with the letter 'S'.
SELECT name
FROM Suppliers
WHERE name LIKE 'S%';

-- 18. Convert all medicine names to uppercase.
SELECT UPPER(name) AS uppercase_name, type
FROM Medicines;

-- COMPLEX QUERIES
-- 19. Show the top 3 best-selling medicines by quantity.
SELECT M.name, SUM(S.quantity) AS total_units_sold
FROM Sales S
JOIN Medicines M ON S.medicine_id = M.medicine_id
GROUP BY M.name
ORDER BY total_units_sold DESC
LIMIT 3;

-- 20. List medicines that were purchased but never sold.
SELECT M.name
FROM Medicines M
JOIN Purchases P ON M.medicine_id = P.medicine_id
LEFT JOIN Sales S ON M.medicine_id = S.medicine_id
WHERE S.sale_id IS NULL
GROUP BY M.name;

