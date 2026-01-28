/*
PURPOSE:
Understand the temporal coverage of the dataset.
Helps validate whether analysis spans days, months, or years.
*/

SELECT 
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    DATEDIFF(day, MIN(order_date), MAX(order_date)) AS date_diff
FROM gold.fact_sales;
