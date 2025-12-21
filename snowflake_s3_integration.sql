CREATE STORAGE INTEGRATION snowflake_s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::253432320522:role/snowflake-access'
  STORAGE_ALLOWED_LOCATIONS = ('s3://amazns3bucketsnowflake/') ;

DESCRIBE INTEGRATION SNOWFLAKE_S3_INTEGRATION;

CREATE STAGE s3_stage
STORAGE_INTEGRATION = snowflake_s3_integration
URL = 's3://amazns3bucketsnowflake/'
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT);


-- ALTER WAREHOUSE SNOWFLAKE_LEARNING_WH RESUME;


CREATE OR REPLACE TABLE CUSTOMERS_DATA
(CUSTOMER_ID VARCHAR, CUSTOMER_UNIQUE_ID STRING, CUSTOMER_ZIP_CODE INT,CUSTOMER_CITY STRING,CUSTOMER_STATE STRING);

-- ALTER TABLE CUSTOMERS_DATA
-- ALTER CUSTOMER_ZIP_CODE SET DATA TYPE STRING; -- unsupported operation 

DESC TABLE CUSTOMERS_DATA;

SHOW FILE FORMATS;


COPY INTO CUSTOMERS_DATA
FROM @S3_STAGE
FILE_FORMAT = (TYPE = 'CSV',
 FIELD_DELIMITER = ',',
    SKIP_HEADER = 1,
    ENCODING = 'UTF8',
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' --It specifies that fields may be optionally enclosed by double quotes (").
);

select * from customers_data;

-- DESC INTEGRATION SNOWFLAKE_S3_INTEGRATION;


-- checking the stage
SHOW STAGES;
sHOW FILE FORMATS;

LIST @S3_STAGE;

-------------- LOADING USING AN EXTERNAL TABLE--------------

CREATE OR REPLACE EXTERNAL TABLE olist_order_reviews
WITH LOCATION=  @S3_STAGE/ 
FILE_FORMAT= (FORMAT_NAME= CSV_FORMAT)
PATTERN = '.*olist_order_reviews_dataset\.csv';

SELECT * FROM OLIST_ORDER_REVIEWS;

SELECT VALUE:C1::STRING AS REVIEW_ID FROM OLIST_ORDER_REVIEWS;


CREATE OR REPLACE EXTERNAL TABLE OLIST_ORDER_REVIEWS (
    -- Column 1: Review ID (String)
    review_id VARCHAR AS (VALUE:c1::VARCHAR),

    -- Column 2: Order ID (String)
    order_id VARCHAR AS (VALUE:c2::VARCHAR),

    -- Column 3: Score (Integer)
    review_score NUMBER AS (VALUE:c3::NUMBER),

    -- Column 4: Comment Title (String)
    review_comment_title VARCHAR AS (VALUE:c4::VARCHAR),

    -- Column 5: Comment Message (String)
    review_comment_message VARCHAR AS (VALUE:c5::VARCHAR),

    -- Column 6: Creation Date (Timestamp)
    review_creation_date TIMESTAMP AS (VALUE:c6::TIMESTAMP),

    -- Column 7: Answer Timestamp (Timestamp)
    review_answer_timestamp TIMESTAMP AS (VALUE:c7::TIMESTAMP)
)
WITH LOCATION = @S3_STAGE/ 
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('', 'NULL', 'null'))
PATTERN = '.*olist_order_reviews_dataset\.csv';

ALTER EXTERNAL TABLE olist_order_reviews REFRESH;

SELECT * FROM OLIST_ORDER_REVIEWS;

----------------- LOADING ORDER PAYMENTS Dataset  -------------------------

LIST @S3_STAGE;

-- show file formats;

CREATE TABLE ORDER_PAYMENTS
(
ORDER_ID STRING,
PAYMENT_SEQUENTIAL INT,
PAYMENT_TYPE STRING,
PAYMENT_INSTALLMENTS INT,
PAYMENT_VALUE FLOAT
);

COPY INTO ORDER_PAYMENTS
FROM @S3_STAGE
PATTERN ='.*olist_order_payments_dataset.csv'
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


---------------- Loading Order Items Dataset ---------------------

--- check the structure of a file sitting in your stage without loading it.
SELECT *
FROM TABLE(
INFER_SCHEMA(
LOCATION => '@S3_STAGE/olist_order_items_dataset.csv',
IGNORE_CASE=>TRUE,
FILE_FORMAT=>'csv_format'
));


CREATE TABLE olist_order_items
(
order_id string,
order_item_id int,
product_id string,
seller_id string,
shipping_limit_date timestamp,
price float,
freight_value float
);

copy into olist_order_items
from @s3_stage
pattern ='.*olist_order_items_dataset.csv'
file_format = (format_name=csv_format);

alter file format csv_format
set FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- truncate table olist_order_items;
select * from olist_order_items;

----- LOADING ORDERS DATASET ----------

CREATE TABLE ORDERS(
ORDER_ID VARCHAR,
CUSTOMER_ID VARCHAR,
ORDER_STATE VARCHAR,
URDER_PURCHASE_TIMESTAMP TIMESTAMP,
ORDER_APPROVED TIMESTAMP,
ORDER_DELIVERED_CARRIER_DATE TIMESTAMP,
ORDER_DELIVERED_CUSTOMER_DATE TIMESTAMP,
ORDER_ESTIMATED_DELIVERY_DATE TIMESTAMP);

copy into ORDERS
from @s3_stage
pattern ='.*olist_orders_dataset.csv'
file_format = (format_name=csv_format);

---loading products table ---

CREATE TABLE PRODUCTS
(
PRODUCT_ID STRING,
PRODUCT_CATEGORY_NAME VARCHAR,
PRODUCT_NAME_LENGTH INT,
PRODUCT_DESCRIPTION_LENGTH INT,
PRODUCT_PHOTOS_QTY NUMBER,
PRODUCT_WEIGHT_G INT,
PRODUCT_LENGTH_CM NUMBER,
PRODUCT_HEIGHT_CM INT,
PRODUCT_WIDTH_CM NUMBER(20,0)
);

COPY INTO PRODUCTS
FROM @S3_STAGE
PATTERN ='.*olist_products_dataset.csv'
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


--- loading sellers dataset ---
CREATE TABLE SELLERS
(
SELLER_ID VARCHAR(40),
SELLER_ZIP_CODE_PREFIX INT,
SELLER_CITY STRING,
SELLER_STATE STRING(5)
);


COPY INTO SELLERS
FROM @S3_STAGE
PATTERN ='.*olist_sellers_dataset.csv'
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


-----  loading the product name translations table ---
create or replace table category_name_translations
(
product_category varchar,
product_category_eng string
);

COPY INTO category_name_translations
FROM @S3_STAGE
PATTERN ='.*product_category_name_translation.csv'
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);

------------ loading the geolocation table ------------

CREATE TABLE GEOLOCATION
(
GEOLOCATION_ZIP_CODE_PREFIX INT,
GEOLOCATION_LAT FLOAT,
GEOLOCATION_LONG FLOAT,
GEOLOCATION_CITY STRING,
GEOLOCATION_STATE STRING
);

COPY INTO GEOLOCATION
FROM @S3_STAGE
PATTERN ='.*olist_geolocation_dataset.csv'
FILE_FORMAT=(FORMAT_NAME=CSV_FORMAT);


-----------------------------------------------------------------------------------------------------

-----------------------SNOWPIPE SETUP to continously ingest data to table TBL_STEAM on file arrival to s3--------------------------------

SHOW STAGES;
SHOW FILE FORMATS;

LIST @S3_STAGE;

CREATE TABLE TBL_STREAM(
COL VARIANT
);


CREATE OR REPLACE PIPE S3_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO TBL_STREAM
FROM @S3_STAGE/snowpipe_streaming_folder/
FILE_FORMAT=(FORMAT_NAME=JSON);


SHOW PIPES;
DESC PIPE S3_PIPE;

SELECT SYSTEM$PIPE_STATUS('s3_pipe');

SELECT 
COL:customer_city::string as city
FROM
TBL_STREAM;


SELECT 
*
FROM 
TBL_STREAM;

-- LIST @S3_STAGE;







