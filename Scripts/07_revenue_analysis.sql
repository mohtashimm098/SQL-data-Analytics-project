/*
PURPOSE:
Analyze revenue concentration across categories and customers.
Helps identify key revenue drivers.
*/

-- Revenue by category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.dim_products p
JOIN gold.fact_sales f
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Revenue by customer
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_revenue DESC;
