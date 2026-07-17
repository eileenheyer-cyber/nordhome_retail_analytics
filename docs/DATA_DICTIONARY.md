# NordHome — Data Dictionary

> **Note:** All files are *raw* and intentionally dirty. See `DATA_QUALITY_ISSUES.md` for known problems.

---

## Table 1: `raw_customers`

Stores one record per registered customer (plus intentional duplicates).

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `customer_id` | STRING | Unique identifier: `CUST-XXXXX` | — |
| `first_name` | STRING | Customer first name | Leading/trailing spaces; random casing |
| `last_name` | STRING | Customer last name | Leading/trailing spaces; random casing |
| `email` | STRING | Email address | ~5 % NULL; occasional ALL-CAPS; duplicate casing variants |
| `phone` | STRING | Phone number with country prefix | ~12 % NULL |
| `country` | STRING | Country of residence | Inconsistent: `Germany`, `DE`, `Deutschland` |
| `city` | STRING | City name | Minor spacing noise |
| `registration_date` | DATE | Date customer registered | Mixed formats: ISO / DD/MM/YYYY / MM-DD-YYYY |
| `birth_year` | INTEGER | Year of birth | ~8 % NULL; some impossible values (1800, 2025) |
| `gender` | STRING | Self-identified gender | `Male`, `Female`, `Non-binary`, `Prefer not to say` |
| `marketing_channel` | STRING | First acquisition channel | Clean |
| `loyalty_member` | STRING | Loyalty programme flag | Inconsistent: `Y`, `Yes`, `TRUE`, `1`, `N`, `No`, `FALSE`, `0` |

---

## Table 2: `raw_products`

Catalogue of all products ever sold, including discontinued items.

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `product_id` | STRING | Unique identifier: `PROD-XXXX` | — |
| `product_name` | STRING | Product display name | ~40 duplicate rows with spacing/casing variants |
| `category` | STRING | Top-level category (Home, Kitchen, Beauty, Lifestyle, Gifts) | ~4 % NULL |
| `subcategory` | STRING | Sub-level category | Clean |
| `brand` | STRING | Brand name (10 NordHome brands) | Clean |
| `unit_cost` | DECIMAL | Wholesale cost to NordHome (EUR) | Clean |
| `list_price` | DECIMAL | Retail price before discounts (EUR) | ~0.5 % are 0.00 |
| `launch_date` | DATE | Date product was added to catalogue | ISO format |
| `discontinued_flag` | STRING | `Y` = discontinued, `N` = active | Some discontinued products appear in recent orders |

---

## Table 3: `raw_orders`

One row per order placed. An order may contain multiple items (`raw_order_items`).

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `order_id` | STRING | Unique identifier: `ORD-XXXXXX` | ~1.5 % duplicate rows |
| `customer_id` | STRING | FK → `raw_customers.customer_id` | ~0.8 % reference non-existent customers |
| `order_date` | DATE | Date order was placed | Mixed formats |
| `order_status` | STRING | `Completed`, `Shipped`, `Processing`, `Cancelled`, `Returned`, `Refunded` | May mismatch payment_status |
| `country` | STRING | Nominally "country where order was shipped," but values are assigned independently at random per order — 89.9% mismatch against the same customer's `raw_customers.country`, with distinct-country-count per customer matching the uniform-random-draw expectation exactly. Formatting is clean (canonical country names); the values themselves carry no real geographic signal. Excluded from `mart` fact tables as of 2026-07-17 — see `model_documentation.md` §4.1. | Clean formatting, but not a trustworthy business field |
| `sales_channel` | STRING | `Website`, `Mobile App`, `Marketplace`, `Phone` | Clean |
| `shipping_method` | STRING | `Standard`, `Express`, `Next Day`, `Click & Collect`, `Free Shipping` | Clean |

---

## Table 4: `raw_order_items`

Line-level detail for each order. An order has 1–6+ items.

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `order_item_id` | STRING | Unique identifier: `ITEM-XXXXXXX` | — |
| `order_id` | STRING | FK → `raw_orders.order_id` | Clean within table |
| `product_id` | STRING | FK → `raw_products.product_id` | ~0.6 % reference non-existent products |
| `quantity` | INTEGER | Units ordered | ~0.5 % negative; ~0.3 % extreme (500–2000) |
| `unit_price` | DECIMAL | Price per unit at time of sale (EUR) | ~0.3 % are 0.00 |
| `discount` | DECIMAL | Discount rate (0.0 = none, 0.30 = 30 % off) | ~0.4 % exceed 1.0 (>100 %) |
| `line_total` | DECIMAL | Revenue for this line | ~3 % do not equal `quantity × unit_price × (1 − discount)` |

---

## Table 5: `raw_payments`

One payment record per order (plus duplicates).

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `payment_id` | STRING | Unique identifier: `PAY-XXXXXXX` | ~1.5 % duplicate rows |
| `order_id` | STRING | FK → `raw_orders.order_id` | ~0.7 % reference non-existent orders |
| `payment_method` | STRING | Payment method | ~6 % NULL; many spelling variants (CC, creditcard, card) |
| `payment_status` | STRING | `Paid`, `Pending`, `Failed`, `Refunded`, `Partially Refunded` | May mismatch order_status |
| `payment_date` | DATE | Date payment was processed | Mixed formats; ~1.5 % before order_date |
| `payment_amount` | DECIMAL | Total amount charged (EUR) | Realistic range; not always equal to order total |

---

## Table 6: `raw_returns`

Items returned by customers after delivery.

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `return_id` | STRING | Unique identifier: `RET-XXXXXX` | — |
| `order_id` | STRING | FK → `raw_orders.order_id` | ~60 rows reference non-existent orders |
| `product_id` | STRING | FK → `raw_products.product_id` | May reference ghost products |
| `return_date` | DATE | Date return was received | Mixed formats; ~2 % before order_date |
| `return_reason` | STRING | Customer-stated reason | ~10 % NULL |
| `refund_amount` | DECIMAL | Amount refunded (EUR) | ~0.5 % negative |

---

## Table 7: `raw_marketing_campaigns`

One row per campaign touchpoint (a customer being targeted by a campaign).

| Column | Type | Description | Dirty? |
|--------|------|-------------|--------|
| `campaign_id` | STRING | Unique identifier: `CAMP-XXXXXX` | — |
| `customer_id` | STRING | FK → `raw_customers.customer_id` | Clean |
| `campaign_name` | STRING | Human-readable campaign name | Clean (14 campaigns) |
| `channel` | STRING | Delivery channel (Email, Paid Social, Display, Push, SMS, Influencer, Affiliate) | Clean |
| `campaign_date` | DATE | Date customer was targeted | Mixed formats |
| `clicked` | INTEGER | 1 = clicked through, 0 = no click (~30 % click rate) | Clean |
| `converted` | INTEGER | 1 = placed an order within the campaign window (~20 % of clickers) | Clean |

---

## Value Domain Reference

### Order Status
`Completed` · `Shipped` · `Processing` · `Cancelled` · `Returned` · `Refunded`

### Payment Status
`Paid` · `Pending` · `Failed` · `Refunded` · `Partially Refunded`

### Payment Methods (raw, before cleaning)
Credit Card variants: `Credit Card`, `creditcard`, `CC`, `card`  
Debit variants: `Debit Card`, `debit`, `Debit`  
Digital: `PayPal`, `paypal`, `PAYPAL`, `Apple Pay`, `applepay`  
Bank: `Bank Transfer`, `bank transfer`, `BankTransfer`  
BNPL: `Klarna`, `Buy Now Pay Later`

### Country Name Variants (raw, before cleaning)
| Canonical | Dirty variants |
|-----------|----------------|
| Germany | DE, Deutschland, germany, GERMANY |
| France | FR, france, FRANCE |
| Netherlands | NL, The Netherlands, netherlands |
| Sweden | SE, sweden |
| Denmark | DK, denmark |
| Norway | NO, norway |
| Belgium | BE, belgium |
| Austria | AT, austria |
| Switzerland | CH, Schweiz, switzerland |
| Poland | PL, poland |