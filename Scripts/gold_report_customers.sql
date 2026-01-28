/*
===============================================================================
Customer Report
===============================================================================
What this does:
    - Creates a customer-level performance and behavior report.

What’s included:
    1. Basic customer details like name and age.
    2. Customer classification by age group and value segment.
    3. Aggregated customer metrics:
       - total orders
       - total sales
       - total quantity purchased
       - distinct products bought
       - customer lifespan in months
    4. Key KPIs:
       - recency (months since last order)
       - average order value
       - average monthly spend
===============================================================================
*/

-- =============================================================================
-- View: gold.report_customers
-- =============================================================================
-- Drop and recreate the view to keep it up to date
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*----------------------------------------------------------------------------
Step 1: Base data
Pulls sales transactions and joins customer details.
Only valid orders with a proper order date are used.
----------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
/*----------------------------------------------------------------------------
Step 2: Customer-level aggregation
Calculates sales, order, product, quantity, lifespan, and recency data
for each customer.
----------------------------------------------------------------------------*/
    SELECT 
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY 
        customer_key,
        customer_number,
        customer_name,
        age
)

/*----------------------------------------------------------------------------
Step 3: Final output
Adds age buckets, customer segmentation, and revenue-based KPIs
for reporting and analysis.
----------------------------------------------------------------------------*/
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,

    -- Group customers by age range
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    -- Customer segmentation based on lifespan and spending
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    -- Average revenue generated per order
    CASE 
        WHEN total_sales = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,

    -- Average monthly spend over the customer lifespan
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend

FROM customer_aggregation;
