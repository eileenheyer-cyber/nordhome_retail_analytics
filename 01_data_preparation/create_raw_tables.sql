
/*
Step 1: Create raw tables

This script creates the raw PostgreSQL tables for the NordHome Retail Analytics project.

The raw tables store the original CSV data without cleaning.
All columns are created as TEXT because the raw dataset intentionally contains messy values, mixed date formats, missing values, and invalid numeric values.

Cleaning and data type conversion will be handled later in the staging layer.
*/


CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

CREATE TABLE IF NOT EXISTS raw.raw_customers (
    customer_id TEXT,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    country TEXT,
    city TEXT,
    registration_date TEXT,
    birth_year TEXT,
    gender TEXT,
    marketing_channel TEXT,
    loyalty_member TEXT
);

CREATE TABLE IF NOT EXISTS raw.raw_products (
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    subcategory TEXT,
    brand TEXT,
    unit_cost TEXT,
    list_price TEXT,
    launch_date TEXT,
    discontinued_flag TEXT
);

CREATE TABLE IF NOT EXISTS raw.raw_orders (
    order_id TEXT,
    customer_id TEXT,
    order_date TEXT,
    order_status TEXT,
    country TEXT,
    sales_channel TEXT,
    shipping_method TEXT
);

CREATE TABLE IF NOT EXISTS raw.raw_order_items (
    order_item_id TEXT,
    order_id TEXT,
    product_id TEXT,
    quantity TEXT,
    unit_price TEXT,
    discount TEXT,
    line_total TEXT
);

CREATE TABLE IF NOT EXISTS raw.raw_payments (
    payment_id TEXT,
    order_id TEXT,
    payment_method TEXT,
    payment_status TEXT,
    payment_date TEXT,
    payment_amount TEXT
);

CREATE TABLE IF NOT EXISTS raw.raw_returns (
    return_id TEXT,
    order_id TEXT,
    product_id TEXT,
    return_date TEXT,
    return_reason TEXT,
    refund_amount TEXT
);

CREATE TABLE IF NOT EXISTS raw.raw_marketing_campaigns (
    campaign_id TEXT,
    customer_id TEXT,
    campaign_name TEXT,
    channel TEXT,
    campaign_date TEXT,
    clicked TEXT,
    converted TEXT
);