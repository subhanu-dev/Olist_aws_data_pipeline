use role orgadmin;

use warehouse snowflake_learning_wh;

use database snowflake_learning_db;

SELECT *
FROM
PUBLIC.CUSTOMERS_DATA;

SHOW TABLES;

SELECT *
FROM 
ORDERS;

select current_role();

ALTER WAREHOUSE COMPUTE_WH RESUME;

SHOW WAREHOUSES;

USE WAREHOUSE SNOWFLAKE_LEARNING_WH;
ALTER WAREHOUSE SNOWFLAKE_LEARNING_WH RESUME;
ALTER WAREHOUSE SNOWFLAKE_LEARNING_WH SUSPEND;

ALTER WAREHOUSE SNOWFLAKE_LEARNING_WH
SET AUTO_SUSPEND=NULL; --WAREHOUSE NEVER GETS SUSPENDED

SELECT CURRENT_SCHEMA();

SHOW WAREHOUSES;

SELECT *
FROM
PRODUCTS;

SELECT DISTINCT 
PRODUCT_CATEGORY_NAME
FROM
PRODUCTS;

SELECT DISTINCT PRODUCTS.PRODUCT_CATEGORY_NAME, COUNT(*)
FROM 
PRODUCTS
LEFT JOIN
CATEGORY_NAME_TRANSLATIONS
ON
PRODUCTS.PRODUCT_CATEGORY_NAME=CATEGORY_NAME_TRANSLATIONS.PRODUCT_CATEGORY
WHERE CATEGORY_NAME_TRANSLATIONS.PRODUCT_CATEGORY IS NULL
GROUP BY
PRODUCT_CATEGORY_NAME;

SELECT PRODUCT_CATEGORY_NAME, COUNT(*)
FROM PRODUCTS
GROUP BY PRODUCT_CATEGORY_NAME;

SELECT COUNT(*)
FROM
PRODUCTS WHERE PRODUCT_CATEGORY_NAME IS NULL;


SELECT *
FROM
CATEGORY_NAME_TRANSLATIONS;

INSERT INTO CATEGORY_NAME_TRANSLATIONS(PRODUCT_CATEGORY, PRODUCT_CATEGORY_ENG)
VALUES('portateis_cozinha_e_preparadores_de_alimentos','Portable Kitchen Appliances and Food Preparers'), ('pc_gamer','gaming PC');

SELECT * FROM 
OLIST_ORDER_ITEMS
WHERE PRODUCT_ID NOT IN (
SELECT DISTINCT PRODUCT_ID FROM PRODUCTS
);

SELECT *
FROM 
OLIST_ORDER_ITEMS A
LEFT JOIN PRODUCTS B
ON A.PRODUCT_ID=B.PRODUCT_ID
WHERE B.PRODUCT_ID IS NULL; 

SELECT *
FROM 
PRODUCTS A
LEFT JOIN  OLIST_ORDER_ITEMS B
ON A.PRODUCT_ID=B.PRODUCT_ID
WHERE B.PRODUCT_ID IS NULL; 

-- Conclusion: all product ids are linked to order items. All the products have been included in orders in order items. means- all given products in products table are a list of products that were ordered during the period. not a full list of products in olist that may include products with 0 orders as well. 

-- even the products with no product name and category and description has been ordered.

SELECT * FROM
OLIST_ORDER_ITEMS A
INNER JOIN 
PRODUCTS B
ON A.PRODUCT_ID=B.PRODUCT_ID 
WHERE B.PRODUCT_CATEGORY_NAME IS NULL;

SELECT COUNT(*), PAYMENT_TYPE
FROM ORDER_PAYMENTS
GROUP BY PAYMENT_TYPE;


SELECT AVG(PAYMENT_INSTALLMENTS)
FROM ORDER_PAYMENTS;

SELECT * FROM ORDER_PAYMENTS;

SELECT * FROM ORDERS;


-- product items(order_items) from multiple sellers can be included in the same order. EXAMPLE IS THE FOLLOWING
--ORDER ID 014405982914c2cde2796ddcf0b8703d 

----checking order count in order items and orders ---

SELECT 
COUNT(DISTINCT ORDERS.ORDER_ID), COUNT(DISTINCT OLIST_ORDER_ITEMS.ORDER_ID)
FROM
ORDERS, OLIST_ORDER_ITEMS;


SELECT
  (SELECT COUNT(DISTINCT ORDER_ID) FROM ORDERS)              AS orders_distinct,
  (SELECT COUNT(DISTINCT ORDER_ID) FROM OLIST_ORDER_ITEMS)   AS items_distinct;

-- the count of unique orders in orders table and order_items table do not match. 

SELECT *
FROM ORDERS 
WHERE
NOT EXISTS (
SELECT 1
FROM OLIST_ORDER_ITEMS
WHERE ORDERS.ORDER_ID=OLIST_ORDER_ITEMS.ORDER_ID
);

SELECT * FROM ORDERS;

-- ALL ORDERS ARE NOT THERE IN OLIST_ORDER_ITEMS TABLE. the orders that are not in order items are in states - unavailable, cancelled or created. all 5 created orders are not there in order items table. but there are records in order_items of orders in states unavailable and cancelled also. but those that are in orders but not in items are falling into one of the above mentioned states.

USE WAREHOUSE COMPUTE_WH;

-- EVEN IF THE CUSTOMER HAS ORDERED MULTIPLE OF THE SAME PRODUCT FROM THE SAME SELLER, THEY ARE STILL TREATED AS INDIVIDUAL ITEMS AND FREIGHT VALUE IS STILL DISTRIBUTED BETWEEN THE ITEMS. 

--- total monetary value of the orders vs matching order payments ---

WITH REV AS (
SELECT ORDER_ID, order_item_id, seller_id, sum(price) AS TOTAL_ITEM_PRICE, sum(freight_value) AS TOTAL_FREIGHT_VAL
FROM 
OLIST_ORDER_ITEMS
GROUP BY ORDER_ID, ORDER_ITEM_ID, SELLER_ID
ORDER BY ORDER_ID, ORDER_ITEM_ID
),

TOTALS AS(
SELECT ORDER_ID, SUM(TOTAL_ITEM_PRICE)  AS TOTAL_ITEM_PRICE, SUM(TOTAL_FREIGHT_VAL) AS TOTAL_FREIGHT_VAL,
SUM(TOTAL_ITEM_PRICE+TOTAL_FREIGHT_VAL) AS TOTAL_PRICE
FROM REV
GROUP BY ORDER_ID)

SELECT * 
FROM
ORDER_PAYMENTS INNER JOIN 
TOTALS
ON ORDER_PAYMENTS.ORDER_ID=TOTALS.ORDER_ID WHERE PAYMENT_SEQUENTIAL >1;

SELECT * FROM ORDER_PAYMENTS WHERE
ORDER_ID='5cfd514482e22bc992e7693f0e3e8df7';


-- the order value can be paid with multiple payment methods. we can pay one part of the order value using a credit card and the rest using a voucher etc. payment_sequential column lists the payment methods used. 
-- the payment value of all the payment methods are equal to the sum of total item value + freight in orders table for a specific order. 
--example order_id-'5cfd514482e22bc992e7693f0e3e8df7'

-- FURTHER CHECKS ON THE PRICE, FREIGHT VALUE AGAINST THE VALUE IN ORDER_PAYMENTS TABLE


WITH REV_ITEMS  AS(
SELECT ORDER_ID, SUM(PRICE) AS PRICE, SUM(FREIGHT_VALUE) AS FREIGHT_VALUE
FROM
OLIST_ORDER_ITEMS
GROUP BY ORDER_ID
),

REV_ITEMS_TOTAL AS( 
SELECT ORDER_ID,(PRICE+FREIGHT_VALUE) AS TOTAL_VAL
FROM
REV_ITEMS),

ORDER_PAYMENT AS(
SELECT ORDER_ID,SUM(PAYMENT_VALUE) PAYMENT_SUM
FROM 
ORDER_PAYMENTS
GROUP BY
ORDER_ID)

-- SELECT * FROM ORDER_PAYMENT O
-- INNER JOIN
-- REV_ITEMS_TOTAL R
-- ON O.ORDER_ID=R.ORDER_ID



-- EACH ORDER IS ASSIGNED A SEPARATE CUSTOMER_ID. iF I MAKE 2 ORDERS, 2 OF THOSE ORDERS WILL HAVE 2 DISTINCT CUSTOMER IDS. 

SELECT CUSTOMER_UNIQUE_ID, COUNT(CUSTOMER_ID) CNT FROM
CUSTOMERS_DATA
GROUP BY CUSTOMER_UNIQUE_ID
ORDER BY CNT DESC ; -- THUS GETTING THE NUMBER OF CUSTOMER IDS UNDER CUSTOMER UNIQUE IDS WOULD GIVE US THE NUMBER OF ORDERS MADE BY THIS CUSTOMER.


SELECT COUNT(*) CNT, COUNT (DISTINCT ORDER_ID )
FROM
ORDERS;

SELECT *
FROM 
ORDERS
WHERE ORDER_ID='1b9ecfe83cdc259250e1a8aca174f0ad';

-- THE NEXT FINDING IS THAT, there's only one record per order(order_id) and the recorded order state is the latest state of the order. it doesn't keep records for each of the states in which the order may go through from staritng the order, invoiced, cash paid , cancelled etc. Therefore we can be confident that each record is a distinct order. 
-- in this case, delivered, shipped, unavailable, cancelled, invoiced

WITH ORDERS_CTE AS(
SELECT * FROM 
ORDERS WHERE ORDER_STATE IN ('invoiced','delivered','cancelled')
ORDER BY ORDER_ID
)

SELECT ORDER_ID, COUNT(*) CNT FROM ORDERS_CTE
GROUP BY ORDER_ID
ORDER BY CNT DESC;

SELECT *
FROM
GEOLOCATION;


-- looking into order reviews

SELECT * FROM OLIST_ORDER_REVIEWS;

SELECT COUNT(REVIEW_ID) CNT, ORDER_ID
FROM OLIST_ORDER_REVIEWS
GROUP BY ORDER_ID ORDER BY CNT DESC;

SELECT * FROM OLIST_ORDER_REVIEWS A
INNER JOIN ORDERS B
ON A.ORDER_ID=B.ORDER_ID
JOIN CUSTOMERS_DATA  C ON
B.CUSTOMER_ID= C.CUSTOMER_ID
WHERE A.ORDER_ID='03c939fd7fd3b38f8485a0f95798f1f6';

--THE SAME PRODUCT ORDER CAN HAVE MULTIPLE AS MANY REVIEWS FROM THE CUSTOMERS. example order_id- 03c939fd7fd3b38f8485a0f95798f1f6

SELECT *
FROM 
ORDERS A
LEFT JOIN OLIST_ORDER_REVIEWS B
ON
A.ORDER_ID=B.ORDER_ID
WHERE B.ORDER_ID IS NULL;

-- Not all reviews have reviews. For example a cancelled order may not have a review though it's in the orders table.

SELECT ORDERS.* FROM
ORDERS
NATURAL JOIN
OLIST_ORDER_REVIEWS; -- even cancelled, unavailable and invoiced orders have reviews

SELECT OLIST_ORDER_REVIEWS.* FROM
ORDERS
NATURAL JOIN
OLIST_ORDER_REVIEWS 
WHERE ORDERS.ORDER_STATE ='unavailable';

--one the reviews for unavailable orders Order_id(b07abc8b9acaf00e79b4657419f469f3): When I went to buy the product, it said it was in stock. When I bought it, the order was put on hold because it was no longer in stock. However, it was still charged to my card.
--therefore regardless of the order state, reviews can be left for the products. 

--- the structure of orders table represents how Olist basically handles its own orders. one order review said
-- Um ponto negativo que achei foi a cobrança de 3 taxas de entregas, sendo que comprei os 3 produtos iguais numa só compra.
--E mesmo comprando os produtos juntos, chegaram separados.
-- meaning: “One negative point I noticed was being charged three delivery fees, even though I bought three identical products in a single purchase. And even though I bought the products together, they arrived separately.”

SELECT *
FROM
OLIST_ORDER_ITEMS A
LEFT JOIN 
PRODUCTS B
ON A.PRODUCT_ID=B.PRODUCT_ID
WHERE A.ORDER_ID='03c939fd7fd3b38f8485a0f95798f1f6';

SELECT CURRENT_WAREHOUSE();
ALTER WAREHOUSE SNOWFLAKE_LEARNING_WH RESUME;
ALTER WAREHOUSE SNOWFLAKE_LEARNING_WH 
SET
AUTO_SUSPEND=Null;

SHOW WAREHOUSES;

-- 24th November 2017 (Spike on this day - Black Friday)

-- the dataset is not inclusive of all order transactions in the Olist platform during the period either. The data provenance is done by getting a random sample
--https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/discussion/66466

--- sellers data exploratiion --

SELECT *
FROM
SELLERS
WHERE NOT EXISTS (
SELECT 1 
FROM 
OLIST_ORDER_ITEMS
WHERE
OLIST_ORDER_ITEMS.SELLER_ID=SELLERS.SELLER_ID
);

-- ALL SELLERS ARE  also not included here.meaning this is not a complete dataset of all the sellers that exist in olist platform during that period. what's included in the sellers dataset are only the sellers that correspond to the orders where order items relate to.

-- just like in the products table. because of this, we couldn't do an analysis of sellers who made their sales against who did not during this period. 

