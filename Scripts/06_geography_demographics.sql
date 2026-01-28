/*
PURPOSE:
Analyze customer distribution across geography and demographics.
Useful for market expansion and targeting.
*/

-- Customers by country
SELECT 
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Customers by gender
SELECT 
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Quantity of items sold by country
SELECT
    c.country,
    SUM(f.quantity) AS quantity
FROM gold.dim_customers c
JOIN gold.fact_sales f
    ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY quantity DESC;
