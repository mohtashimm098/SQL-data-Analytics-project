/*
PURPOSE:
Identify best and worst performers among products and customers.
*/

-- Top 5 products by revenue
SELECT TOP 5
    p.product_key,
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_key, p.product_name
ORDER BY total_revenue DESC;

-- Bottom 5 products by revenue
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- Customers with fewest orders
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.dim_customers c
JOIN gold.fact_sales f
    ON c.customer_key = f.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_orders;
