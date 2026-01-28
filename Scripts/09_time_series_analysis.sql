/*
PURPOSE:
Analyze trends and growth over time.
Includes yearly aggregation and cumulative metrics.
*/

-- Yearly performance
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

-- Running total and average
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
