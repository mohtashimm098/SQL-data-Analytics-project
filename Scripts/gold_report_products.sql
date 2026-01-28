/*
===============================================================================
Product Report
===============================================================================
What this does:
    - Builds a consolidated product-level report from sales data.

What you get:
    1. Basic product details (name, category, subcategory, cost).
    2. Product segmentation based on total revenue.
    3. Aggregated metrics per product:
       - total orders
       - total sales
       - total quantity sold
       - unique customers
       - product lifespan in months
    4. Useful KPIs:
       - recency (months since last sale)
       - average order revenue
       - average monthly revenue
===============================================================================
*/

-- =============================================================================
-- View: gold.report_products
-- =============================================================================
-- Drops the view if it already exists and recreates it
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*----------------------------------------------------------------------------
Step 1: Base data
Pulls required columns from fact_sales and joins product details.
Only valid sales with a non-null order date are considered.
----------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),

product_aggregations AS (
/*----------------------------------------------------------------------------
Step 2: Product-level aggregation
Calculates sales, customer, order, quantity, lifespan, and pricing metrics
for each product.
----------------------------------------------------------------------------*/
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(
            AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 
            1
        ) AS avg_selling_price
    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

/*----------------------------------------------------------------------------
Step 3: Final output
Adds segmentation, recency, and revenue-based KPIs for reporting and analysis.
----------------------------------------------------------------------------*/
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,

    -- Product performance bucket based on total revenue
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,

    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    -- Average revenue generated per order
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average revenue generated per month over product lifespan
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregations;
