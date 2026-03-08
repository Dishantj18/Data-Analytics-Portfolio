
DROP DATABASE IF EXISTS upi_analytics;
CREATE DATABASE upi_analytics;
USE upi_analytics;
-- 1. PARENT: Customer Master
CREATE TABLE customer_master (
    customer_id VARCHAR(50) PRIMARY KEY,
    full_name VARCHAR(100),
    mobile_number VARCHAR(20),
    age INT,
    gender VARCHAR(10),
    region VARCHAR(20),
    date_joined DATE,             -- Use DATE (Fixed in Excel)
    is_business_user TINYINT(1),  -- 0/1 logic
    risk_score DECIMAL(3, 2)
);

-- 2. PARENT: Merchant Info
CREATE TABLE merchant_info (
    merchant_id VARCHAR(50) PRIMARY KEY,
    merchant_name VARCHAR(100),
    merchant_type VARCHAR(50),
    region VARCHAR(20),
    onboard_date DATE,            -- Use DATE (Fixed in Excel)
    risk_score DECIMAL(3, 2)
);

-- 3. CHILD: Device Info
CREATE TABLE device_info (
    device_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    device_type VARCHAR(20),
    app_version VARCHAR(20),
    is_rooted TINYINT(1),         -- 0/1 logic
    last_active VARCHAR(50),      -- VARCHAR for MM:SS.f
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- 4. CHILD: UPI Account Details
CREATE TABLE upi_account_details (
    upi_id VARCHAR(100) PRIMARY KEY,
    customer_id VARCHAR(50),
    bank_name VARCHAR(50),
    account_type VARCHAR(50),
    date_added DATE,              -- Use DATE (Fixed in Excel)
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- 5. GRANDCHILD: Transaction History (Matches your 16-column CSV)
CREATE TABLE upi_transaction_history (
    transaction_id VARCHAR(50) PRIMARY KEY,
    upi_id VARCHAR(100),
    customer_id VARCHAR(50),
    timestamp_val VARCHAR(50),    -- VARCHAR for MM:SS.f
    amount DECIMAL(10, 2),
    transaction_type VARCHAR(30),
    merchant_id VARCHAR(50),
    counterparty_upi VARCHAR(100),
    status VARCHAR(20),
    device_id VARCHAR(50),
    device_type VARCHAR(50),      
    channel VARCHAR(20),
    fraud_flag TINYINT(1),        
    reversal_flag TINYINT(1),     
    failure_reason VARCHAR(255),
    customer_check VARCHAR(50),   
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id),
    FOREIGN KEY (upi_id) REFERENCES upi_account_details(upi_id)
);

-- 6. FINAL LINKS: Fraud Alerts & Surveys
CREATE TABLE fraud_alert_history (
    alert_id VARCHAR(50) PRIMARY KEY,
    transaction_id VARCHAR(50),
    alert_type VARCHAR(50),
    alert_date VARCHAR(50),       -- VARCHAR for MM:SS.f
    resolved TINYINT(1),          
    resolution_date VARCHAR(50),  -- VARCHAR for MM:SS.f
    remarks TEXT,
    FOREIGN KEY (transaction_id) REFERENCES upi_transaction_history(transaction_id)
);

CREATE TABLE customer_feedback_surveys (
    feedback_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    date_submitted DATE,          -- Use DATE (Fixed in Excel)
    feedback_text TEXT,
    satisfaction_score INT,
    issue_type VARCHAR(50),
    resolved TINYINT(1),          
    FOREIGN KEY (customer_id) REFERENCES customer_master(customer_id)
);

-- Convert Transaction Timestamps to a usable format
ALTER TABLE upi_transaction_history ADD COLUMN clean_time TIME(1);

UPDATE upi_transaction_history 
SET clean_time = CAST(CONCAT('00:', timestamp_val) AS TIME(1))
WHERE timestamp_val IS NOT NULL;

-- Quick Analysis: Average transaction amount by hour
SELECT HOUR(clean_time) as Hour_of_Day, AVG(amount) as Avg_Spent
FROM upi_transaction_history
GROUP BY 1;

SET SQL_SAFE_UPDATES = 1

SHOW TABLES;

DESCRIBE customer_master;

DESCRIBE upi_transaction_history;

SHOW VARIABLES LIKE 'sql_safe_updates';

SELECT 
    transaction_id, 
    timestamp_val AS original_messy_text, 
    clean_time AS new_formatted_time
FROM upi_transaction_history 
LIMIT 15;

-- when users are most active:
SELECT 
    HOUR(clean_time) AS hour_of_day, 
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_volume
FROM upi_transaction_history
GROUP BY hour_of_day
ORDER BY total_transactions DESC;

-- Exploratory Data Analysis (EDA) Guide
-- Phase 1: Business Performance (Region & Volume)
-- The project asks: "How can business performance by region be monitored?"
-- What to look for: Which region has the highest "Avg Transaction Value"? If one region has many transactions but low volume, they are using UPI for small daily needs (like chai/groceries).
-- Project Goal: Fulfills "Identify patterns of customer behavior."
SELECT 
    cm.region, 
    COUNT(th.transaction_id) AS total_transactions, 
    SUM(th.amount) AS total_volume,
    AVG(th.amount) AS avg_transaction_value
FROM customer_master cm
JOIN upi_transaction_history th ON cm.customer_id = th.customer_id
GROUP BY cm.region
ORDER BY total_volume DESC;

-- Phase 2: Fraud Risk Analysis
-- The project asks: "Are certain segments at higher risk of transaction fraud?"
-- What to look for: Is the fraud rate higher on "Rooted" devices or specific "Device Types" (like Android vs iOS)?
-- Project Goal: Fulfills "Identify patterns of fraud risk."
SELECT 
    device_type, 
    COUNT(*) AS total_txns,
    SUM(fraud_flag) AS fraud_cases,
    ROUND((SUM(fraud_flag) / COUNT(*)) * 100, 2) AS fraud_rate_percentage
FROM upi_transaction_history
GROUP BY device_type
ORDER BY fraud_rate_percentage DESC;

-- Phase 3: Operational Bottlenecks (Failure Analysis)
-- The project asks: "Where do bottlenecks or failures occur?"
-- What to look for: Are most failures due to "System Downtime" or "Incorrect PIN"?
SELECT 
    failure_reason, 
    COUNT(*) AS failure_count,
    channel
FROM upi_transaction_history
WHERE status = 'failed'
GROUP BY failure_reason, channel
ORDER BY failure_count DESC;

-- Phase 4: Time-Based Patterns (Using your Cleaned Data)
-- The project asks: "Identify patterns of payment trends."
-- What to look for: Does fraud spike at night (e.g., 2 AM to 4 AM)?
SELECT 
    HOUR(clean_time) AS hour_of_day, 
    COUNT(*) AS txn_density,
    SUM(fraud_flag) AS fraud_incidents
FROM upi_transaction_history
GROUP BY hour_of_day
ORDER BY hour_of_day;