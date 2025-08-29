WITH customer_activity AS (
  SELECT 
    customer_id,
    from_date,
    to_date,
    -- Get the earliest from_date per customer for created_date
    MIN(from_date) OVER (PARTITION BY customer_id) AS created_date
  FROM `manual.activity`

  WHERE DATE_TRUNC(from_date, YEAR) ="2021-01-01"
),

-- Create a date grid using the minimum from_date uptil max subscription date or today's date
date_range AS (
  SELECT 
    MIN(from_date) AS min_date,
    GREATEST(MAX(to_date),CURRENT_DATE()) AS max_date
  FROM customer_activity
),

dates AS (
  SELECT day AS date
  FROM date_range,
    UNNEST(GENERATE_DATE_ARRAY(min_date, max_date, INTERVAL 1 DAY)) AS day
),

-- Create a flag of whether the customer is active on the given date or not. 
-- As the number of subscription don't matter I have simplified it to be a binary flag
customer_dates AS (
  SELECT 
    d.date,
    ca.customer_id,
    ca.created_date,
    IF(d.date BETWEEN ca.from_date AND ca.to_date, 1, 0) AS is_active
  FROM customer_activity ca
  CROSS JOIN dates d

),

deduped AS (
SELECT 
  date,
  customer_id,
  MAX(is_active) AS is_active,  -- Aggregate in case of overlapping periods
  ANY_VALUE(created_date) AS created_date
FROM customer_dates
GROUP BY date, customer_id
ORDER BY customer_id, date
)

-- Join the various dimension and add default value when dimension missing
SELECT 
deduped.*, 
COALESCE(orders.taxonomy_business_category_group, "Uncategorise") AS category_group
COALESCE(customers.customer_country, "Country Unknown") AS customer_country

FROM deduped

LEFT JOIN `manual.acq_orders`  AS orders USING(customer_id) -- This table is unique on customer_id

LEFT JOIN `manual.customers`  AS customers USING(customer_id) -- This table is unique on customer_id
