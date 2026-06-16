/* customer table*/

--  1. quick look at the table
SELECT *
from raw.raw_products
limit 20

/* problems this dataset has:
1. separate first and last names, 
2. nulls in email address  and phone number
3. inconsistent  country names and registration date ,birth _year with a 0 at the end?
4. inconsistent loyalty_member entry and with 0  
*/

--2. count total rows: 8386
SELECT COUNT(*) AS total_rows
FROM raw.raw_customers;

-- 3. check table columns and data types
select 
 column_name,
 data_type,
 is_nullable
 from information_schema.columns
 where table_schema = 'raw' and table_name = 'raw_customers'
 order by ordinal_position 

 -- 4.  check duplicate customer_id: 0
SELECT
customer_id,
count (*) as duplicate_count
from raw.raw_customers
group by customer_id
having count (*) >= 1
order by duplicate_count DESC

 --5. check missing values in important columns
 -- trim () = '' makes sure that empty/spaces also be counted
 SELECT 
   count (*) as total_rows,
   count (*) filter (where customer_id is NULL) as missing_customer_id,
   COUNT(*) FILTER (WHERE first_name IS NULL OR TRIM(first_name) = '') AS missing_first_name, 
   COUNT(*) FILTER (WHERE last_name IS NULL OR TRIM(last_name) = '') AS missing_last_name,
   COUNT(*) FILTER (WHERE email IS NULL OR TRIM(email) = '') AS missing_email, -- 406 missing values
   COUNT(*) FILTER (WHERE country IS NULL OR TRIM(country) = '') AS missing_country,
   COUNT(*) FILTER (WHERE registration_date IS NULL) AS missing_registration_date

FROM raw.raw_customers;

-- 6.check duplicate emails
SELECT
lower(trim(email)) as normalized_email,
count(*) as duplicate_count
from raw.raw_customers
group by lower(trim(email))
having count(*) > 1
order by duplicate_count DESC

--7. check invalid email format : 1757 invalid emails

SELECT
count(*) as total_rows,
count(*) filter (where email is NULL or trim(email) = '') as missing_email_count,
count(*) filter (where email is not null 
                and  trim(email) <> ''
                and email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' 
                ) as invalid_email_format_count,
count(*) filter (where email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$') as valid_email_count
from raw.raw_customers


--8. count country values
select 
country,
count(*) as customer_count
from raw.raw_customers
group by country
order by customer_count desc

-- 9. Check registration date range 
-- notice that because date is stored as text, and postgres read it as text
select 
   min(registration_date) AS earliest_registration_date,
   max(registration_date) AS latest_registration_date
FROM raw.raw_customers;



