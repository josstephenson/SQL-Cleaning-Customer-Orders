/*
Joseph Stephenson
04/10/2026
Data cleaning and normalizing for a table of customer orders.
Removal of duplicate data using window functions.
*/

-- CTE 1: Initiate with LOWER and TRIM on the string data
WITH prepped_data AS (
    SELECT *,
        LOWER(TRIM(customer_name)) AS low_name,
        LOWER(TRIM(email)) AS low_email,
        LOWER(TRIM(order_status)) AS low_status,
        LOWER(TRIM(product_name)) AS low_product,
        LOWER(TRIM(country)) AS low_country,
        CEIL(price) AS rounded_price
    FROM customer_orders
),

-- CTE 2: Cleaning
cleaned_data AS (
    SELECT 
        order_id,
        
        -- Use SUBSTRING and REGEXP_SUBSTR to get first and last names, apply uppercase to the first characters
		-- ^ marks the beginning of the string, $ marks the end. ^[^ ]+  -> Find the first ch up to the space. [^ ]+$  -> Finds the last ch after the space.
        CONCAT(
			UPPER(LEFT(low_name, 1)),
			SUBSTRING(REGEXP_SUBSTR(low_name, '^[^ ]+'), 2),
			' ',
			UPPER(LEFT(REGEXP_SUBSTR(low_name, '[^ ]+$'), 1)),
			SUBSTRING(REGEXP_SUBSTR(low_name, '[^ ]+$'), 2)
		) AS clean_customer_name,
        
        -- Fixing email error.
		-- The @{2,} will see if there is 2 or more @ symbols and replace with a single @
        REGEXP_REPLACE(low_email, '@{2,}', '@') AS clean_email,

		-- Standardizing country names
		CASE 
			WHEN low_country REGEXP 'usa|united states' THEN 'USA'
			WHEN low_country REGEXP 'uk|united kingdom|britain'  THEN 'UK'
			ELSE UPPER(low_country)
		END AS clean_country,
                
		-- Standardizing order status
		CASE
			WHEN low_status LIKE '%deliver%' THEN 'Delivered'
			WHEN low_status LIKE '%return%'  THEN 'Returned'
			WHEN low_status LIKE '%refund%'  THEN 'Refunded'
			WHEN low_status LIKE '%pend%'    THEN 'Pending'
			WHEN low_status LIKE '%ship%'    THEN 'Shipped'
			ELSE 'Other'
		END AS clean_order_status,

		-- Standardizing product name
		CASE
			WHEN low_product LIKE '%apple watch%'    THEN 'Apple Watch'
			WHEN low_product LIKE '%samsung galaxy%' THEN 'Samsung Galaxy S22'
			WHEN low_product LIKE '%google pixel%'   THEN 'Google Pixel'
			WHEN low_product LIKE '%iphone 14%'      THEN 'Iphone 14'
			WHEN low_product LIKE '%macbook pro%'    THEN 'Macbook Pro'
			ELSE 'Other'
		END AS clean_product_name,
        
		-- Remove currency symbols/separators, round .99 values up, and CAST to DECIMAL.
		CAST(ROUND(REGEXP_REPLACE(price, '[^0-9.]', ''), 0) AS DECIMAL(10,2)) AS clean_price,
        
        -- Cast quantity string values to SIGNED integer (positive, negative or zero).
        CASE
            WHEN quantity = 'two' THEN 2
            WHEN quantity = 'one' THEN 1
            ELSE CAST(REGEXP_REPLACE(quantity, '[^0-9]', '') AS SIGNED)
        END AS clean_quantity,
        

        -- Normalize date using COALESCE to try multiple date formats (ISO, US, Slash, Dot). If STR_TO_DATE results in NULL, moves to the next format.
        COALESCE(
            STR_TO_DATE(CAST(order_date AS CHAR), '%Y-%m-%d'),
            STR_TO_DATE(CAST(order_date AS CHAR), '%Y/%m/%d'),
            STR_TO_DATE(CAST(order_date AS CHAR), '%m-%d-%Y'),
            STR_TO_DATE(CAST(order_date AS CHAR), '%Y.%m.%d')
        ) AS clean_order_date
    FROM prepped_data
),

-- CTE 3: Remove duplicates by grouping identical orders (same email, product, date). The row_num will list 1 and then increment to 2 and so on, for each duplicate row.
deduplicated_data AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY clean_email, clean_product_name, clean_order_date
            ORDER BY order_id ASC
        ) AS row_num
    FROM cleaned_data
),

-- CTE 4: Filter out the duplicate rows (keep only results with row_num = 1).
clean_customer_orders AS (
	SELECT *
	FROM deduplicated_data
	WHERE row_num = 1
)

-- View all of the cleaned data
SELECT * FROM clean_customer_orders;