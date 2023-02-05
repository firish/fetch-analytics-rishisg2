-- 1. Which brand saw the most dollars spent in the month of June?
-- Naïve Solution
SELECT B.NAME
FROM brands B JOIN receipt_items Ri ON (B.BARCODE = Ri.BARCODE) JOIN receipts as R ON (Ri.REWARDS_RECEIPT_ID = R.ID)
WHERE MONTH(R.PURCHASE_DATE) = 6
GROUP BY B.NAME
ORDER BY SUM(Ri.TOTAL_FINAL_PRICE) DESC
LIMIT 1;

-- Problem: 
-- This query is sorting by sum of total final price and then limiting the output to 1
-- So, even though we need only result, we are doing the sorting on all the rows, which can be very expensive and inefficient for large databases,

-- A more optimized way would be to first filter the records and then display them, 

SELECT B.NAME
FROM brands B JOIN receipt_items Ri ON B.BARCODE = Ri.BARCODE
WHERE Ri.TOTAL_FINAL_PRICE = (
SELECT MAX(Ri2.TOTAL_FINAL_PRICE)
FROM receipt_items Ri2
JOIN receipts R2 ON Ri2.REWARDS_RECEIPT_ID = R2.ID
WHERE MONTH(R2.PURCHASE_DATE) = 6 AND Ri2.BARCODE = B.BARCODE
)
GROUP BY B.NAME
ORDER BY SUM(Ri.TOTAL_FINAL_PRICE) DESC;

-- This query uses a correlated subquery to find the maximum total final price for each brand, 
-- and then it joins with the original table to get the name of the brand and the total final price. 
-- This eliminates the need to use the LIMIT keyword and can run more efficiently, especially with large data sets.



-- 2. Which user spent the most money in the month of August?

SELECT u.ID
FROM users u JOIN receipts r ON (u.ID=r.USER_ID)
WHERE MONTH(R.PURCHASE_DATE) = 8
GROUP BY u.ID
ORDER BY SUM(r.TOTAL_SPENT) DESC
LIMIT 1;

-- Optimized Version 
SELECT u.ID
FROM users u
WHERE (
SELECT SUM(r2.TOTAL_SPENT)
FROM receipts r2
WHERE r2.USER_ID = u.ID AND MONTH(r2.PURCHASE_DATE) = 8
) = (
SELECT MAX(total_spent)
FROM (
SELECT SUM(r3.TOTAL_SPENT) AS total_spent
FROM receipts r3
WHERE MONTH(r3.PURCHASE_DATE) = 8
GROUP BY r3.USER_ID
) subq
);

-- This query uses a subquery to find the maximum total spent for all users in the month of August 
-- and another subquery to find the user with that total spent, 
-- eliminating the need for the LIMIT keyword and increasing efficiency, especially with large data sets.



-- 3. What user bought the most expensive item?
SELECT u.ID
FROM users u JOIN receipts r ON (u.ID=r.USER_ID) JOIN receipt_items ri ON (r.ID=ri.REWARDS_RECEIPT_ID)
ORDER BY ri.TOTAL_FINAL_PRICE/ri.QUANTITY_PURCHASED DESC
LIMIT 1

-- optimized Version
SELECT u.ID
FROM users u
WHERE (
SELECT MAX(ri2.TOTAL_FINAL_PRICE / ri2.QUANTITY_PURCHASED)
FROM receipts r2
JOIN receipt_items ri2 ON r2.ID = ri2.REWARDS_RECEIPT_ID
WHERE r2.USER_ID = u.ID
) = (
SELECT MAX(total_price_per_item)
FROM (
SELECT SUM(ri3.TOTAL_FINAL_PRICE / ri3.QUANTITY_PURCHASED) AS total_price_per_item
FROM receipts r3
JOIN receipt_items ri3 ON r3.ID = ri3.REWARDS_RECEIPT_ID
GROUP BY r3.USER_ID
) subq_table
);

-- This query uses a subquery to find the maximum price per item for all users and another subquery 
-- to find the user with that price, eliminating the need for the LIMIT keyword 
-- and increasing efficiency, especially with large data sets.



-- 4. What is the name of the most expensive item purchased?
SELECT ri.DESCRIPTION 
FROM receipt_items ri 
ORDER BY ri.TOTAL_FINAL_PRICE/ri.QUANTITY_PURCHASED DESC 
LIMIT 1;

-- optimized version
SELECT ri.DESCRIPTION
FROM receipt_items ri
WHERE (
SELECT MAX(total_price_per_item)
FROM (
SELECT SUM(ri2.TOTAL_FINAL_PRICE / ri2.QUANTITY_PURCHASED) AS total_price_per_item
FROM receipt_items ri2
) subq_table
) = (
SELECT SUM(ri.TOTAL_FINAL_PRICE / ri.QUANTITY_PURCHASED)
);



-- 5. How many users scanned in each month?
SELECT MONTH(r.DATE_SCANNED), COUNT( DISTINCT r.USER_ID) 
FROM receipts r 
GROUP BY MONTH(r.DATE_SCANNED);

-- optimized version
SELECT MONTH(r.DATE_SCANNED) AS month, COUNT(DISTINCT r.USER_ID) AS count
FROM receipts r
GROUP BY MONTH(r.DATE_SCANNED);
-- This query eliminates the need for a subquery and instead directly performs the aggregate function (COUNT) 
-- on the distinct values of the USER_ID column, grouped by the month of the DATE_SCANNED column.



-- some of the optimized querys might not work, but I wanted to try and give alternative efficient versions


-- IMPORTANT
-- Note, another neat trick to use while actually implementing the querys is to determine]
-- the order of the tables in joins
-- if we are doing R outer-join S, then the inner-table-outer-table order makes a big difference to efficiency
-- and we should take that into consideration