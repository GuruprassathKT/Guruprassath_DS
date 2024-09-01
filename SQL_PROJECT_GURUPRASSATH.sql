USE ORDERS;

/* ---1. Write a query to display customer full name with their title (mr/ms), 
both first name and last name are in upper case with customer email id, customer 
creation date and display customer’s category after applying below categorization rules:
       i. If customer creation date year <2005 then category a
       ii. If customer creation date year >=2005 and <2011 then category b
       iii. If customer creation date year>= 2011 then category c -----*/
       
SELECT 
    CASE 
        WHEN CUSTOMER_GENDER = 'F' THEN CONCAT('MS', ' ', CUSTOMER_FNAME, ' ', CUSTOMER_LNAME) 
        WHEN CUSTOMER_GENDER = 'M' THEN CONCAT('MR', ' ', CUSTOMER_FNAME, ' ', CUSTOMER_LNAME)
        ELSE CUSTOMER_FNAME
    END AS FULL_NAME,
    UPPER(CUSTOMER_FNAME) AS CUSTOMER_FNAME,
    UPPER(CUSTOMER_LNAME) AS CUSTOMER_LNAME,
    CUSTOMER_EMAIL,
    CUSTOMER_CREATION_DATE,
    CASE 
        WHEN CUSTOMER_CREATION_DATE < '2005-01-01' THEN 'A'
        WHEN CUSTOMER_CREATION_DATE >= '2005-01-01' AND CUSTOMER_CREATION_DATE <= '2011-01-01' THEN 'B'
        WHEN CUSTOMER_CREATION_DATE > '2011-01-01' THEN 'C'
        ELSE CUSTOMER_CREATION_DATE
    END AS CUSTOMER_CATEGORY
FROM 
    ONLINE_CUSTOMER;
    
    
/* --- 2. Write a query to display the following information for the products, 
which have not been sold:  product_id, product_desc, product_quantity_avail, 
product_price, inventory values(product_quantity_avail*product_price), 
new_price after applying discount as per the below criteria. Sort the output 
concerning the decreasing value of inventory_value.
   i. If product price > 20,000 then apply 20% discount
   ii. If product price > 10,000 then apply 15% discount
   iii. If product price =< 10,000 then apply 10% discount ---*/
   
SELECT 
    P.PRODUCT_ID,
    P.PRODUCT_DESC,
    P.PRODUCT_QUANTITY_AVAIL,
    P.PRODUCT_PRICE,
    (P.PRODUCT_QUANTITY_AVAIL * P.PRODUCT_PRICE) AS INVENTORY_VALUE,
    CASE 
        WHEN P.PRODUCT_PRICE > 20000 THEN (P.PRODUCT_PRICE - P.PRODUCT_PRICE * 0.20)
        WHEN P.PRODUCT_PRICE > 10000 THEN (P.PRODUCT_PRICE - P.PRODUCT_PRICE * 0.15)
        ELSE (P.PRODUCT_PRICE - P.PRODUCT_PRICE * 0.10)
    END AS NEW_PRICE
FROM 
    PRODUCT AS P
LEFT JOIN 
    ORDER_ITEMS AS OI ON P.PRODUCT_ID = OI.PRODUCT_ID
WHERE 
    OI.PRODUCT_ID IS NULL 
ORDER BY 
    INVENTORY_VALUE DESC;
    

 /* ---3. Write a query to display product_class_code, product_class_description, 
 count of product type in each product class, and inventory value 
 (p.product_quantity_avail*p.product_price). Information should be displayed for 
 only those product_class_code that have more than 1,00,000 inventory value. 
 sort the output concerning the decreasing value of inventory_value. ---*/
    
SELECT 
    PC.PRODUCT_CLASS_CODE,
    PC.PRODUCT_CLASS_DESC,
    COUNT(P.PRODUCT_ID) AS PRODUCT_TYPE_COUNT,
    SUM(P.PRODUCT_QUANTITY_AVAIL * P.PRODUCT_PRICE) AS INVENTORY_VALUE
FROM 
    PRODUCT_CLASS AS PC
INNER JOIN 
    PRODUCT AS P ON PC.PRODUCT_CLASS_CODE = P.PRODUCT_CLASS_CODE
GROUP BY 
    PC.PRODUCT_CLASS_CODE, PC.PRODUCT_CLASS_DESC
HAVING 
    SUM(P.PRODUCT_QUANTITY_AVAIL * P.PRODUCT_PRICE) > 100000
ORDER BY 
    INVENTORY_VALUE DESC;
    
    
/* --- 4. Write a query to display customer_id, full name, customer_email, 
customer_phone and country of customers who have cancelled all the orders 
placed by them(use sub-query)--- */

SELECT 
    OC.CUSTOMER_ID,
    CASE 
        WHEN OC.CUSTOMER_GENDER = 'F' THEN CONCAT('MS', ' ', OC.CUSTOMER_FNAME, ' ', OC.CUSTOMER_LNAME) 
        WHEN OC.CUSTOMER_GENDER = 'M' THEN CONCAT('MR', ' ', OC.CUSTOMER_FNAME, ' ', OC.CUSTOMER_LNAME)
        ELSE OC.CUSTOMER_FNAME
    END AS FULL_NAME, 
    OC.CUSTOMER_EMAIL, 
    OC.CUSTOMER_PHONE, 
    A.COUNTRY
FROM 
    ONLINE_CUSTOMER AS OC 
JOIN 
    ADDRESS AS A ON OC.ADDRESS_ID = A.ADDRESS_ID
WHERE 
    OC.CUSTOMER_ID IN (
        SELECT 
            OH.CUSTOMER_ID
        FROM 
            ORDER_HEADER AS OH
        GROUP BY 
            OH.CUSTOMER_ID
        HAVING 
            COUNT(*) = SUM(CASE WHEN OH.ORDER_STATUS = 'CANCELLED' THEN 1 ELSE 0 END)
    );
    
    
/* ---  5. Write a query to display shipper name, city to which it is catering, 
number of customer catered by the shipper in the city and number of consignments 
delivered to that city for shipper dhl ---*/

SELECT 
    S.SHIPPER_NAME,
    A.CITY,
    COUNT(DISTINCT OC.CUSTOMER_ID) AS CUSTOMERS_CATERED,
    COUNT(DISTINCT OH.ORDER_ID) AS CONSIGNMENTS_DELIVERED
FROM 
    ONLINE_CUSTOMER AS OC
JOIN 
    ADDRESS AS A ON OC.ADDRESS_ID = A.ADDRESS_ID
JOIN 
    ORDER_HEADER AS OH ON OC.CUSTOMER_ID = OH.CUSTOMER_ID
JOIN 
    SHIPPER AS S ON OH.SHIPPER_ID = S.SHIPPER_ID
WHERE 
    OH.ORDER_STATUS = 'SHIPPED' 
    AND S.SHIPPER_NAME = 'DHL'
GROUP BY 
    S.SHIPPER_NAME, A.CITY;
    
    
/* ---  6. Write a query to display customer id, customer full name, 
total quantity and total value (quantity*price) shipped where mode of payment is 
cash and customer last name starts with 'g' --- */

SELECT 
    OC.CUSTOMER_ID, 
    CASE 
        WHEN CUSTOMER_GENDER = 'F' THEN CONCAT('MS', ' ', CUSTOMER_FNAME, ' ', CUSTOMER_LNAME) 
        WHEN CUSTOMER_GENDER = 'M' THEN CONCAT('MR', ' ', CUSTOMER_FNAME, ' ', CUSTOMER_LNAME)
        ELSE CUSTOMER_FNAME
    END AS FULL_NAME, 
    OC.CUSTOMER_LNAME,
    PP.PAYMENT_MODE,
    SUM(PP.PRODUCT_QUANTITY) AS TOTAL_QUANTITY,
    SUM(PP.TOTAL_VALUE) AS TOTAL_VALUE
FROM 
    ONLINE_CUSTOMER AS OC
JOIN (
    SELECT 
        OH.CUSTOMER_ID, 
        OH.PAYMENT_MODE,
        SUM(OI.PRODUCT_QUANTITY * P.PRODUCT_PRICE) AS TOTAL_VALUE,
        SUM(OI.PRODUCT_QUANTITY) AS PRODUCT_QUANTITY
    FROM 
        ORDER_HEADER AS OH
    JOIN 
        ORDER_ITEMS AS OI ON OH.ORDER_ID = OI.ORDER_ID
    JOIN 
        PRODUCT AS P ON OI.PRODUCT_ID = P.PRODUCT_ID
    WHERE 
        OH.ORDER_STATUS = 'SHIPPED' AND OH.PAYMENT_MODE = 'CASH'
    GROUP BY 
        OH.CUSTOMER_ID,OH.PAYMENT_MODE
) AS PP ON OC.CUSTOMER_ID = PP.CUSTOMER_ID
WHERE 
    OC.CUSTOMER_LNAME LIKE 'G%'
GROUP BY 
    OC.CUSTOMER_ID, FULL_NAME, OC.CUSTOMER_LNAME;
    
    
/* ---7. Write a query to display order_id and volume of biggest order 
in terms of volume) that can fit in carton id 10 ---*/

SELECT 
    OI.ORDER_ID,
    P.PRODUCT_ID,
    CART.CARTON_ID,
    CART.CART_VOLUME,
    MAX(P.LEN * P.WIDTH * P.HEIGHT) AS TOTAL_VOLUME
FROM 
    PRODUCT AS P
JOIN 
    ORDER_ITEMS AS OI ON P.PRODUCT_ID = OI.PRODUCT_ID
CROSS JOIN (
    SELECT 
        CARTON_ID,
        SUM(LEN * WIDTH * HEIGHT) AS CART_VOLUME 
    FROM 
        CARTON 
    WHERE 
        CARTON_ID = 10
) AS CART
WHERE 
    (P.LEN * P.WIDTH * P.HEIGHT) <= CART.CART_VOLUME
GROUP BY 
    CART.CART_VOLUME, OI.ORDER_ID, P.PRODUCT_ID,CART.CARTON_ID
ORDER BY 
    TOTAL_VOLUME DESC
LIMIT 5;


/* --- 8. Write a query to display product_id, product_desc, product_quantity_avail, 
 quantity sold, and show inventory status of products as below as per below condition:
a. For electronics and computer categories, 
	i. If sales till date is zero then show 'no sales in past, give discount to reduce inventory',
	ii. If inventory quantity is less than 10% of quantity sold, show 'low inventory, need to add inventory', 
	iii. If inventory quantity is less than 50% of quantity sold, show 'medium inventory, need to 
	add some inventory', 
	iv. If inventory quantity is more or equal to 50% of quantity sold, show 'sufficient inventory'
b. For mobiles and watches categories, 
	i. If sales till date is zero then show 'no sales in past, give discount to reduce inventory', 
	ii. If inventory quantity is less than 20% of quantity sold, show 'low inventory, 
	need to add inventory',  
	iii. If inventory quantity is less than 60% of quantity sold, show 'medium inventory, 
	need to add some inventory', 
	iv. If inventory quantity is more or equal to 60% of quantity sold, show 'sufficient inventory'
c. Rest of the categories, 
	i. If sales till date is zero then show 'no sales in past, give discount to reduce inventory', 
	ii. If inventory quantity is less than 30% of quantity sold, show 'low inventory, need to add inventory',  
	iii. If inventory quantity is less than 70% of quantity sold, show 'medium inventory, 
	need to add some inventory', 
	iv. If inventory quantity is more or equal to 70% of quantity sold, show 'sufficient inventory' ---*/

SELECT 
    P.PRODUCT_ID,
    P.PRODUCT_DESC,
    PC.PRODUCT_CLASS_DESC,
    P.PRODUCT_QUANTITY_AVAIL,
    COALESCE(PS.QUANTITY_SOLD, 0) AS QUANTITY_SOLD,
    CASE 
        WHEN PC.PRODUCT_CLASS_DESC IN ('ELECTRONICS', 'COMPUTER') THEN
            CASE 
                WHEN COALESCE(PS.QUANTITY_SOLD, 0) = 0 THEN 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY'
                WHEN P.PRODUCT_QUANTITY_AVAIL < 0.1 * COALESCE(PS.QUANTITY_SOLD, 0) THEN 'LOW INVENTORY, NEED TO ADD INVENTORY'
                WHEN P.PRODUCT_QUANTITY_AVAIL < 0.5 * COALESCE(PS.QUANTITY_SOLD, 0) THEN 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY'
                ELSE 'SUFFICIENT INVENTORY'
            END
        WHEN PC.PRODUCT_CLASS_DESC IN ('MOBILES', 'WATCHES') THEN
            CASE 
                WHEN COALESCE(PS.QUANTITY_SOLD, 0) = 0 THEN 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY'
                WHEN P.PRODUCT_QUANTITY_AVAIL < 0.2 * COALESCE(PS.QUANTITY_SOLD, 0) THEN 'LOW INVENTORY, NEED TO ADD INVENTORY'
                WHEN P.PRODUCT_QUANTITY_AVAIL < 0.6 * COALESCE(PS.QUANTITY_SOLD, 0) THEN 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY'
                ELSE 'SUFFICIENT INVENTORY'
            END
        ELSE
            CASE 
                WHEN COALESCE(PS.QUANTITY_SOLD, 0) = 0 THEN 'NO SALES IN PAST, GIVE DISCOUNT TO REDUCE INVENTORY'
                WHEN P.PRODUCT_QUANTITY_AVAIL < 0.3 * COALESCE(PS.QUANTITY_SOLD, 0) THEN 'LOW INVENTORY, NEED TO ADD INVENTORY'
                WHEN P.PRODUCT_QUANTITY_AVAIL < 0.7 * COALESCE(PS.QUANTITY_SOLD, 0) THEN 'MEDIUM INVENTORY, NEED TO ADD SOME INVENTORY'
                ELSE 'SUFFICIENT INVENTORY'
            END
    END AS INVENTORY_STATUS
FROM 
    PRODUCT P
JOIN 
    PRODUCT_CLASS PC ON P.PRODUCT_CLASS_CODE = PC.PRODUCT_CLASS_CODE
LEFT JOIN 
    (SELECT 
         PRODUCT_ID, 
         SUM(PRODUCT_QUANTITY) AS QUANTITY_SOLD
     FROM 
         ORDER_ITEMS
     GROUP BY 
         PRODUCT_ID) PS ON P.PRODUCT_ID = PS.PRODUCT_ID
ORDER BY 
    P.PRODUCT_ID;
    
    
/* --- 9. Write a query to display product_id, product_desc and total quantity of 
products which are sold together with product id 201 and are not shipped to city 
bangalore and new delhi. Display the output in descending order concerning tot_qty.(use sub-query)--- */

SELECT 
    P.PRODUCT_ID,
    P.PRODUCT_DESC,
    SUM(OI.PRODUCT_QUANTITY) AS tot_qty
FROM 
    PRODUCT AS P
JOIN 
    ORDER_ITEMS AS OI ON P.PRODUCT_ID = OI.PRODUCT_ID
JOIN 
    ORDER_HEADER AS OH ON OI.ORDER_ID = OH.ORDER_ID
JOIN 
    ONLINE_CUSTOMER AS OC ON OH.CUSTOMER_ID = OC.CUSTOMER_ID
JOIN 
    ADDRESS AS A ON OC.ADDRESS_ID = A.ADDRESS_ID
WHERE 
    
    OH.ORDER_ID IN (
        SELECT DISTINCT OH.ORDER_ID
        FROM ORDER_ITEMS AS OI
        JOIN ORDER_HEADER AS OH ON OI.ORDER_ID = OH.ORDER_ID
        WHERE OI.PRODUCT_ID = 201
    ) AND A.CITY NOT IN ('BANGALORE', 'NEW DELHI')
GROUP BY 
    P.PRODUCT_ID, P.PRODUCT_DESC
ORDER BY 
    tot_qty DESC;


/* --- 10. Write a query to display the order_id,customer_id and 
customer fullname and total quantity of products shipped for order ids 
which are even and shipped to address where pincode is not starting with "5" ---*/

SELECT 
    AC.ORDER_ID, 
    OC.CUSTOMER_ID, 
    CASE 
        WHEN CUSTOMER_GENDER = 'F' THEN CONCAT('MS', ' ', CUSTOMER_FNAME,' ',CUSTOMER_LNAME) 
        WHEN CUSTOMER_GENDER = 'M' THEN CONCAT('MR', ' ', CUSTOMER_FNAME,' ',CUSTOMER_LNAME)
        ELSE CUSTOMER_FNAME
    END AS FULL_NAME, 
    AC.TOTAL_QUANTITY,
    A.PINCODE
FROM 
    ONLINE_CUSTOMER AS OC
JOIN 
    ADDRESS AS A ON OC.ADDRESS_ID = A.ADDRESS_ID
JOIN 
    (
        SELECT 
            OH.ORDER_ID, 
            OH.CUSTOMER_ID, 
            OH.ORDER_STATUS, 
            SUM(DISTINCT OI.PRODUCT_QUANTITY) AS TOTAL_QUANTITY
        FROM 
            ORDER_HEADER AS OH
        JOIN 
            ORDER_ITEMS AS OI ON OH.ORDER_ID = OI.ORDER_ID
        WHERE 
            OH.ORDER_STATUS = 'SHIPPED' 
            AND OH.ORDER_ID % 2 = 0
        GROUP BY 
            OH.ORDER_ID, OH.CUSTOMER_ID, OH.ORDER_STATUS
    ) AS AC ON AC.CUSTOMER_ID = OC.CUSTOMER_ID
WHERE 
    A.PINCODE NOT LIKE '5%';