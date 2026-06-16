## Data Model Plan

### Goal
Create an analysis-ready model for sales, customer, product, and order analysis.

### Grain
One row in the main fact table represents one product line within one order.

### Fact table
fact_order_items

### Dimension tables
dim_customers  
dim_products  
dim_orders  
dim_stores  
dim_date  
dim_payment  

### Main business questions
- What is total revenue?
- Which products and categories perform best?
- Which customers and countries generate the most sales?
- Which sales channels are strongest?
- How do returns affect revenue?