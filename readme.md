## End to End Data Engineering Pipeline using Olist Ecommerce Data

Olist is a major Brazilian Ecommerce marketplace that connects thousands of small businesses to major sales channels. Unlike traditional retailers that sell their own stock, Olist acts as a SaaS (Software as a Service) solution that connects small and medium-sized businesses across Brazil to larger marketplaces like Mercado Livre and Amazon. 

100,000+ records of real commercial data across 9 relational tables of data between 2016-2018 and this is one of the most popular real-world datasets being used for ecommerce analytics.

Kaggle Dataset Link: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Instead of doing a regular analysis using this dataset, I used this real world to create a production scale data pipeline using Amazon Web Services, Snowflake and Power BI.

System architecture is as follows.

![System Architecture](images/architecture.png)

** Tech Used **

![AWS S3](https://img.shields.io/badge/AWS%20S3-569A31?style=for-the-badge&logo=amazons3&logoColor=white)
![AWS Glue](https://img.shields.io/badge/AWS%20Glue-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![AWS Athena](https://img.shields.io/badge/Amazon%20Athena-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![AWS IAM](https://img.shields.io/badge/AWS%20IAM-DD344C?style=for-the-badge&logo=amazonaws&logoColor=white)
![AWS CloudWatch](https://img.shields.io/badge/AWS%20CloudWatch-FF4F8B?style=for-the-badge&logo=amazonaws&logoColor=white)


🔹 **Data Lake (AWS S3):** Served as the primary landing zone for raw Olist CSV files.

🔹 **Data Catalog & Discovery:** Used **AWS Glue Catalog** and **Crawlers** to automate schema detection and maintain a central metadata repository. 

🔹 **Ad-hoc Querying (Amazon Athena):**

🔹 **Snowflake:** Architected the final warehouse in Snowflake, managed preliminary transformations and cleaning. 

🔹 **Power BI:** Developed an interactive dashboard to track critical KPIs like delivery performance, product category trends, and regional sales distribution.


This project also simulates a real time stream of JSON files that land in s3 which are then passed through snowflake. 


![Snowpipe streaming](images/snowpipe_streaming.png)


## Setup Details


All AWS Services are deloyed in ap-south-1 ( Asia Pacific (Mumbai)) region. 

To reduce data transfer fees between locations and for the each on integration, Snowflake is hosted on the same data center location. (ap-south-1)

all Olist Data files are uploaded to 

![](images/aws%20s3.png)



all SQL files and Power BI(.pbix) file is available inside the repo.


### Power BI transformations



## Key Findings on the Dataset

I was able to uncover few things that were not available in most of the analysis done on this dataset. All insights are gathered by studies the data and the background study into real world business operations of Olist.

1. all product ids are linked to order items. All the products have been included in orders in order items. this means all given products in products table are a list of products that were ordered during the period. not a full list of products in olist that may include products with 0 orders as well. 

2. even the products with no product name and category and description has been ordered. This could be because there's products in the Olist platform that are listed and orderde by customers that has no assigned name/ category. But for all the products that has been ordered except a couple, product dimensions(l,h,w and weight) are available

3. product items(order_items) from multiple sellers can be included in the same order. 
EXAMPLE IS THE FOLLOWING ORDER ID - 014405982914c2cde2796ddcf0b8703d 

4. ALL ORDERS ARE NOT THERE IN OLIST_ORDER_ITEMS TABLE. 
the orders that are not in order items are in states - unavailable, cancelled or created. 

all 5 created orders are not there in order items table. but there are records in order_items of orders in states unavailable and cancelled also. but those that are in orders but not in items are falling into one of the above mentioned states(unavailable, cancelled or created).

5. even if the customer has ordered multiple of the same product from the same seller, they are still treated as individual items and freight value is still distributed between the items. 

6. Each order is assigned a separate customer_id. if i make 2 orders, 2 of those orders will have 2 distinct customer ids.


7. The order value can be paid with multiple payment methods. we can pay one part of the order value using a credit card and the rest using a voucher etc. payment_sequential column lists the payment methods used. 
The payment value of all the payment methods are equal to the sum of total item value + freight in orders table for a specific order. 
example order_id-'5cfd514482e22bc992e7693f0e3e8df7'

8. there's only one record per order(order_id) and the recorded order state is the latest state of the order. it doesn't keep records for each of the states in which the order may go through from staritng the order, invoiced, cash paid , cancelled etc. Therefore we can be confident that each record is a distinct order. 
-- in this case, delivered, shipped, unavailable, cancelled, invoiced, created

otherwise, during the creation of the dataset, the creators have decided to only share the latest state for the orders

9. THE SAME PRODUCT ORDER CAN HAVE MULTIPLE AS MANY REVIEWS FROM THE CUSTOMERS. example order_id- 03c939fd7fd3b38f8485a0f95798f1f6, there is no rule as one order to have only one review  by the customer.

also, Not all orders have reviews. For example a cancelled order may not have a review though it's in the orders table. This is the the expected behavior but that doesn't mean customers for cancelled orders cannot leave reviews. even cancelled, unavailable and invoiced orders have reviews

One the reviews for unavailable orders Order_id(b07abc8b9acaf00e79b4657419f469f3): When I went to buy the product, it said it was in stock. When I bought it, the order was put on hold because it was no longer in stock. However, it was still charged to my card.

therefore regardless of the order state, reviews can be left for the products. 

10. The structure of orders and order_items table represents how Olist basically handles its own orders. one order review said,

"Um ponto negativo que achei foi a cobrança de 3 taxas de entregas, sendo que comprei os 3 produtos iguais numa só compra.
--E mesmo comprando os produtos juntos, chegaram separados."
meaning: “One negative point I noticed was being charged three delivery fees, even though I bought three identical products in a single purchase. And even though I bought the products together, they arrived separately.”

11. the dataset is not inclusive of all order transactions in the Olist platform during the period either. The data provenance is done by getting a random sample of the orders during the period covered (2016-2018). But this random sample should be enough to arrive to reach at conclusions regarding all data points of Olist for the duration. 

12. ALL SELLERS ARE also not included in the sellers table. Meaning this is not a complete dataset of all the sellers that exist in olist platform during that period. what's included in the sellers dataset are only the sellers that correspond to the orders where order items relate to.

Same can be said about the products table (as in point 01 above). Because of this, we couldn't do an analysis of sellers who made their sales against who did not during this period. 


# Business Insights based on the Data





---
By [Subhanu](https://github.com/subhanu-dev) 🚀
