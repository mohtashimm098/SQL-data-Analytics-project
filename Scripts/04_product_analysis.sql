/*
PURPOSE:
Understand product dimension:
- Total products
- Cost distribution by category
*/

-- Total number of products
SELECT 
    COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products;

-- Average cost per category
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;
