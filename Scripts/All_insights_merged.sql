/* ============================================================
   COMPLETE BUSINESS SALES ANALYSIS
   Schema: GOLD
   ============================================================ */


/* ============================================================
   01. DATABASE EXPLORATION
   ============================================================ */

SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(day, MIN(order_date), MAX(order_date)) AS date_range_days
FROM gold.fact_sales;


/* ============================================================
   02. DIMENSIONS EXPLORATION
   ============================================================ */

SELECT 
    MIN(birthdate) AS oldest_birthdate,
    CAST(DATEDIFF(year, MIN(birthdate), GETDATE()) AS varchar) + ' years' AS oldest_customer,
    MAX(birthdate) AS youngest_birthdate,
    CAST(DATEDIFF(year, MAX(birthdate), GETDATE()) AS varchar) + ' years' AS youngest_customer
FROM gold.dim_customers;


/* ============================================================
   03. DATE RANGE EXPLORATION
   ============================================================ */

SELECT
    c.customer_key,
    MIN(f.order_date) AS first_order,
    MAX(f.order_date) AS last_order,
    DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) AS customer_lifespan_months
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
WHERE f.order_date IS NOT NULL
GROUP BY c.customer_key;


/* ============================================================
   04. MEASURES EXPLORATION
   ============================================================ */

SELECT SUM(quantity) AS total_products_sold FROM gold.fact_sales;
SELECT AVG(price) AS avg_price FROM gold.fact_sales;

SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales;
SELECT COUNT(DISTINCT order_number) AS unique_orders FROM gold.fact_sales;

SELECT COUNT(DISTINCT product_key) AS total_products FROM gold.dim_products;
SELECT COUNT(DISTINCT customer_id) AS total_customers FROM gold.dim_customers;

SELECT COUNT(DISTINCT customer_key) AS active_customers
FROM gold.fact_sales
WHERE order_number IS NOT NULL;


/* ============================================================
   05. MAGNITUDE ANALYSIS
   ============================================================ */

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


/* ============================================================
   06. GEOGRAPHICAL & DEMOGRAPHIC DISTRIBUTION
   ============================================================ */

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

-- Distribution of sold items across countries
SELECT
    c.country,
    SUM(f.quantity) AS total_quantity
FROM gold.dim_customers c
JOIN gold.fact_sales f
    ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_quantity DESC;


/* ============================================================
   07. CATEGORY & CUSTOMER REVENUE ANALYSIS
   ============================================================ */

-- Average cost per category
SELECT
    category,
    AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

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


/* ============================================================
   08. RANKING ANALYSIS
   ============================================================ */

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


/* ============================================================
   09. CHANGE OVER TIME ANALYSIS
   ============================================================ */

SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_revenue,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity,
    AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY order_year;


/* ============================================================
   10. CUMULATIVE ANALYSIS
   ============================================================ */

SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_date) AS running_total,
    AVG(total_sales) OVER (ORDER BY order_date) AS avg_running_total
FROM (
    SELECT
        DATETRUNC(year, order_date) AS order_date,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(year, order_date)
) t;


/* ============================================================
   11. PERFORMANCE ANALYSIS
   ============================================================ */

WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS prev_year_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_prev_year
FROM yearly_product_sales;


/* ============================================================
   12. PART-TO-WHOLE ANALYSIS
   ============================================================ */

SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales,
    CONCAT(
        CAST(
            ROUND(
                SUM(f.sales_amount) * 100.0 /
                (SELECT SUM(sales_amount) FROM gold.fact_sales),
            2) AS decimal(10,2)
        ),
        '%'
    ) AS total_sales_pct
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_sales DESC;


/* ============================================================
   13. OTHERS / SEGMENTATION ANALYSIS
   ============================================================ */

-- Product cost segmentation
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

-- Customer spending segmentation
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    GROUP BY c.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE
            WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;
