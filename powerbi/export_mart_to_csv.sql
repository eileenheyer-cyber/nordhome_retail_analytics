-- Export mart tables to CSV for Power BI import.
-- Boolean columns are cast to 'true'/'false' text because Postgres COPY
-- otherwise writes booleans as 't'/'f', which Power BI's auto-detect
-- reads as Text instead of Boolean.
-- Run with: psql -h localhost -U claude_reader -d nordhome_retail -f export_mart_to_csv.sql
-- from inside the target output folder (paths below are relative to the client's cwd).

\copy (SELECT customer_key, customer_id, full_name, email, phone, country, gender, birth_year, age_group, registration_date, registration_year, CASE WHEN loyalty_member THEN 'true' ELSE 'false' END AS loyalty_member, CASE WHEN missing_email_flag THEN 'true' ELSE 'false' END AS missing_email_flag, CASE WHEN missing_phone_flag THEN 'true' ELSE 'false' END AS missing_phone_flag, CASE WHEN missing_registration_date_flag THEN 'true' ELSE 'false' END AS missing_registration_date_flag, CASE WHEN is_unknown_customer THEN 'true' ELSE 'false' END AS is_unknown_customer, created_at, CASE WHEN duplicate_customer_flag THEN 'true' ELSE 'false' END AS duplicate_customer_flag, canonical_customer_key FROM mart.dim_customer) TO 'dim_customer.csv' CSV HEADER;

\copy (SELECT date_key, full_date, year, quarter, month_number, month_name, year_month, day_of_month, day_of_week_number, day_of_week_name, CASE WHEN is_weekend THEN 'true' ELSE 'false' END AS is_weekend FROM mart.dim_date) TO 'dim_date.csv' CSV HEADER;

\copy (SELECT campaign_key, campaign_name, channel FROM mart.dim_marketing_campaigns) TO 'dim_marketing_campaigns.csv' CSV HEADER;

\copy (SELECT payment_key, payment_id, payment_method, payment_status, payment_date, created_at FROM mart.dim_payment) TO 'dim_payment.csv' CSV HEADER;

\copy (SELECT product_key, product_id, product_name, category, subcategory, brand, unit_cost, list_price, launch_date, CASE WHEN discontinued_flag THEN 'true' ELSE 'false' END AS discontinued_flag, CASE WHEN price_issue_flag THEN 'true' ELSE 'false' END AS price_issue_flag, product_quality_status, created_at FROM mart.dim_product) TO 'dim_product.csv' CSV HEADER;

\copy (SELECT return_reason_key, return_reason, reason_category, created_at FROM mart.dim_return_reason) TO 'dim_return_reason.csv' CSV HEADER;

\copy (SELECT fact_touchpoint_key, marketing_touchpoint_id, customer_key, campaign_key, campaign_date_key, clicked, converted, CASE WHEN ghost_customer_flag THEN 'true' ELSE 'false' END AS ghost_customer_flag, CASE WHEN converted_without_click_flag THEN 'true' ELSE 'false' END AS converted_without_click_flag, created_at FROM mart.fact_marketing_touchpoints) TO 'fact_marketing_touchpoints.csv' CSV HEADER;

\copy (SELECT fact_order_item_key, order_item_id, order_id, customer_key, product_key, order_date_key, order_status, sales_channel, shipping_method, quantity, unit_price, discount, line_total, CASE WHEN ghost_product_flag THEN 'true' ELSE 'false' END AS ghost_product_flag, CASE WHEN zero_unit_price_flag THEN 'true' ELSE 'false' END AS zero_unit_price_flag, CASE WHEN line_total_mismatch_flag THEN 'true' ELSE 'false' END AS line_total_mismatch_flag, created_at FROM mart.fact_order_items) TO 'fact_order_items.csv' CSV HEADER;

\copy (SELECT fact_payment_key, payment_id, order_id, customer_key, payment_key, payment_date_key, order_status, sales_channel, payment_amount, CASE WHEN ghost_order_flag THEN 'true' ELSE 'false' END AS ghost_order_flag, created_at FROM mart.fact_payments) TO 'fact_payments.csv' CSV HEADER;

\copy (SELECT fact_return_key, return_id, order_id, customer_key, product_key, return_reason_key, return_date_key, order_status, sales_channel, refund_amount, CASE WHEN ghost_product_flag THEN 'true' ELSE 'false' END AS ghost_product_flag, CASE WHEN ghost_order_flag THEN 'true' ELSE 'false' END AS ghost_order_flag, created_at FROM mart.fact_returns) TO 'fact_returns.csv' CSV HEADER;