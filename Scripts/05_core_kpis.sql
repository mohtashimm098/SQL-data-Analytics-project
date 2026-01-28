/*
PURPOSE:
Calculate core business KPIs used across reports and dashboards.
*/

-- Total products sold
SELECT SUM(quantity) AS total_products_sold
FROM gold.fact_sales;

-- Average selling price
SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

-- Order counts
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales;
SELECT COUNT(DISTINCT order_number) AS unique_orders FROM gold.fact_sales;

-- KPI summary report
SELECT 'Total Sales' AS metric, SUM(sales_amount) AS value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;
