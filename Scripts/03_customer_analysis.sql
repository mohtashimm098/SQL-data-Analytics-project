/*
PURPOSE:
Analyze customer dimension basics:
- Age extremes
- Active vs inactive customers
*/

-- Oldest and youngest customers
SELECT 
    MIN(birthdate) AS oldest_birthdate,
    CAST(DATEDIFF(year, MIN(birthdate), GETDATE()) AS varchar) + ' years' AS oldest_customer,
    MAX(birthdate) AS youngest_birthdate,
    CAST(DATEDIFF(year, MAX(birthdate), GETDATE()) AS varchar) + ' years' AS youngest_customer
FROM gold.dim_customers;

-- Total customers
SELECT 
    COUNT(DISTINCT customer_id) AS total_customers
FROM gold.dim_customers;

-- Customers who have placed at least one order
SELECT 
    COUNT(DISTINCT customer_key) AS active_customers
FROM gold.fact_sales
WHERE order_number IS NOT NULL;
