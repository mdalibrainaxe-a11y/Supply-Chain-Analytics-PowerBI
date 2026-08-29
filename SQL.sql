CREATE DATABASE Vendor_Performance_DB ;

CREATE TABLE Regions(
    Region VARCHAR(30) PRIMARY KEY,
    Regional_Manager VARCHAR(100)
);
SELECT * FROM regions ;

CREATE TABLE Warehouses(
    Warehouse_ID VARCHAR(10) PRIMARY KEY,
    Warehouse_Name VARCHAR(100),
    City VARCHAR(50),
    State VARCHAR(50),
    Region VARCHAR(30),

    FOREIGN KEY (Region)
    REFERENCES Regions(Region)
);
SELECT * FROM warehouses ;

CREATE TABLE Vendors(

    Vendor_ID VARCHAR(10) PRIMARY KEY,

    Vendor_Name VARCHAR(100),

    Region VARCHAR(30),

    Vendor_Type VARCHAR(50),

    Contract_Start_Date DATE,

    Payment_Terms_Days INT,

    Vendor_Status VARCHAR(30),

    FOREIGN KEY (Region)
    REFERENCES Regions(Region)

);
SELECT * FROM vendors ;

CREATE TABLE Products(

    Product_ID VARCHAR(10) PRIMARY KEY,

    Product_Name VARCHAR(100),

    Category VARCHAR(50),

    Subcategory VARCHAR(50),

    Unit VARCHAR(30),

    Standard_Cost DECIMAL(10,2)

);
SELECT * FROM products ;

CREATE TABLE Purchase_Orders(

    PO_ID VARCHAR(15) PRIMARY KEY,

    PO_Date DATE,

    Vendor_ID VARCHAR(10),

    Product_ID VARCHAR(10),

    Warehouse_ID VARCHAR(10),

    Ordered_Qty INT,

    Unit_Cost DECIMAL(10,2),

    Expected_Delivery_Date DATE,

    FOREIGN KEY(Vendor_ID)
    REFERENCES Vendors(Vendor_ID),

    FOREIGN KEY(Product_ID)
    REFERENCES Products(Product_ID),

    FOREIGN KEY(Warehouse_ID)
    REFERENCES Warehouses(Warehouse_ID)

);
SELECT * FROM purchase_orders ;

CREATE TABLE Deliveries(

    Delivery_ID VARCHAR(15) PRIMARY KEY,

    PO_ID VARCHAR(15),

    Actual_Delivery_Date DATE,

    Received_Qty INT,

    Delivery_Status VARCHAR(30),

    Delay_Days INT,

    FOREIGN KEY(PO_ID)
    REFERENCES Purchase_Orders(PO_ID)

);
SELECT * FROM deliveries ;

CREATE TABLE Quality_Inspection(

    Inspection_ID VARCHAR(15) PRIMARY KEY,

    Delivery_ID VARCHAR(15),

    Inspected_Qty INT,

    Defective_Qty INT,

    Quality_Status VARCHAR(30),

    Inspection_Date DATE,

    FOREIGN KEY(Delivery_ID)
    REFERENCES Deliveries(Delivery_ID)

);
SELECT * FROM  quality_inspection ;

CREATE TABLE Payments(

    Payment_ID VARCHAR(15) PRIMARY KEY,

    PO_ID VARCHAR(15),

    Invoice_Amount DECIMAL(12,2),

    Invoice_Date DATE,

    Due_Date DATE,

    Payment_Date DATE,

    Payment_Status VARCHAR(30),

    FOREIGN KEY(PO_ID)
    REFERENCES Purchase_Orders(PO_ID)

);
SELECT * FROM payments ;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

SELECT Vendor_ID, COUNT(*)
FROM Vendors
GROUP BY Vendor_ID
HAVING COUNT(*) > 1;

SELECT *
FROM Purchase_Orders
WHERE Vendor_ID NOT IN
(
SELECT Vendor_ID
FROM Vendors
);




SELECT
    v.Vendor_ID,
    v.Vendor_Name,

    COUNT(d.Delivery_ID) AS Total_Deliveries,

    SUM(
        CASE
            WHEN d.Delivery_Status = 'On Time'
            THEN 1
            ELSE 0
        END
    ) AS On_Time_Deliveries,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN d.Delivery_Status = 'On Time'
                THEN 1
                ELSE 0
            END
        ) / COUNT(d.Delivery_ID),
        2
    ) AS On_Time_Delivery_Percentage

FROM Vendors v

JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID

JOIN Deliveries d
    ON po.PO_ID = d.PO_ID

GROUP BY
    v.Vendor_ID,
    v.Vendor_Name

ORDER BY On_Time_Delivery_Percentage DESC;



SELECT
    v.Vendor_Name,
    ROUND(AVG(d.Delay_Days), 2) AS Avg_Delay_Days
FROM Vendors v
JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID
JOIN Deliveries d
    ON po.PO_ID = d.PO_ID
GROUP BY v.Vendor_Name
ORDER BY Avg_Delay_Days DESC;



SELECT
    ROUND(
        100.0 * SUM(Defective_Qty)
        / NULLIF(SUM(Inspected_Qty),0),
        2
    ) AS Overall_Defect_Rate
FROM Quality_Inspection;



SELECT
    v.Vendor_ID,
    v.Vendor_Name,

    SUM(qi.Inspected_Qty) AS Inspected_Qty,

    SUM(qi.Defective_Qty) AS Defective_Qty,

    ROUND(
        100.0 *
        SUM(qi.Defective_Qty)
        / NULLIF(SUM(qi.Inspected_Qty),0),
        2
    ) AS Defect_Rate

FROM Vendors v

JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID

JOIN Deliveries d
    ON po.PO_ID = d.PO_ID

JOIN Quality_Inspection qi
    ON d.Delivery_ID = qi.Delivery_ID

GROUP BY
    v.Vendor_ID,
    v.Vendor_Name

ORDER BY Defect_Rate DESC;



SELECT
    p.Category,

    SUM(po.Ordered_Qty * po.Unit_Cost)
        AS Procurement_Spend

FROM Purchase_Orders po

JOIN Products p
    ON po.Product_ID = p.Product_ID

GROUP BY p.Category

ORDER BY Procurement_Spend DESC;

SELECT
    YEAR(PO_Date) AS Purchase_Year,
    MONTH(PO_Date) AS Purchase_Month,

    SUM(Ordered_Qty * Unit_Cost)
        AS Procurement_Spend

FROM Purchase_Orders

GROUP BY
    YEAR(PO_Date),
    MONTH(PO_Date)

ORDER BY
    Purchase_Year,
    Purchase_Month;


SELECT
    v.Vendor_ID,
    v.Vendor_Name,

    SUM(po.Ordered_Qty * po.Unit_Cost)
        AS Procurement_Spend,

    COUNT(d.Delivery_ID)
        AS Total_Deliveries,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN d.Delivery_Status = 'On Time'
                THEN 1 ELSE 0
            END
        )
        / COUNT(d.Delivery_ID),
        2
    ) AS On_Time_Percentage

FROM Vendors v

JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID

JOIN Deliveries d
    ON po.PO_ID = d.PO_ID

GROUP BY
    v.Vendor_ID,
    v.Vendor_Name

ORDER BY Procurement_Spend DESC
LIMIT 10;




SELECT
    v.Vendor_Name,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN d.Delivery_Status = 'On Time'
                THEN 1 ELSE 0
            END
        )
        / COUNT(d.Delivery_ID),
        2
    ) AS On_Time_Percentage

FROM Vendors v

JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID

JOIN Deliveries d
    ON po.PO_ID = d.PO_ID

GROUP BY v.Vendor_Name

HAVING On_Time_Percentage < 80

ORDER BY On_Time_Percentage;




SELECT
    v.Vendor_Name,

    ROUND(
        100.0 *
        SUM(qi.Defective_Qty)
        / NULLIF(SUM(qi.Inspected_Qty),0),
        2
    ) AS Defect_Rate

FROM Vendors v

JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID

JOIN Deliveries d
    ON po.PO_ID = d.PO_ID

JOIN Quality_Inspection qi
    ON d.Delivery_ID = qi.Delivery_ID

GROUP BY v.Vendor_Name

HAVING Defect_Rate > 5

ORDER BY Defect_Rate DESC;



SELECT 
COUNT(*) AS Partial_deliveries
FROM Purchase_Orders po
JOIN Deliveries d
ON po.PO_ID = d.PO_ID
WHERE d.Received_Qty < po.Ordered_Qty;



CREATE TABLE stg_purchase_orders AS 
SELECT * 
FROM Purchase_orders ;


CREATE TABLE data_quality_issues (
   Issue_ID INT Auto_Increment PRIMARY KEY,
   Table_Name VARCHAR(100),
   Record_ID VARCHAR(50),
   Issue_Type VARCHAR(100),
   Issue_Description VARCHAR(255),
   Severity VARCHAR(20),
   Status VARCHAR(20)
);


SELECT
  PO_ID,
  Ordered_Qty,
  'Invalid Quantity' AS Issue_Type
 FROM stg_purchase_orders
 WHERE Ordered_Qty <= 0 ;

 SELECT 
   PO_ID,
   Vendor_ID,
   'Missing Vendor' AS Issue_Type
 FROM stg_purchase_orders
 WHERE Vendor_ID IS NULL
 OR TRIM(Vendor_ID) = '' ;


SELECT
  PO_ID,
  Unit_Cost,
  'Invalid Unit Cost' AS Issue_Type
 FROM stg_purchase_orders
 WHERE Unit_Cost <= 0 ;

 

 SELECT
   po.PO_ID,
   po.Ordered_Qty,
   d.Received_Qty,
    'Received Quantity Exceeds Orders' AS Issue_Type

FROM stg_purchase_orders po

 JOIN stg_deliveries d
  ON po.PO_ID = d.PO_ID

 WHERE d.Received_Qty > po.Ordered_Qty ;
 


CREATE VIEW vw_vendor_performance AS

SELECT
    v.Vendor_ID,
    v.Vendor_Name,

    COUNT(DISTINCT po.PO_ID) AS Total_PO,

    SUM(po.Ordered_Qty * po.Unit_Cost)
        AS Procurement_Spend,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN d.Actual_Delivery_Date
                     <= po.Expected_Delivery_Date
                THEN 1
                ELSE 0
            END
        )
        / COUNT(d.Delivery_ID),
        2
    ) AS On_Time_Percentage,

    ROUND(
        100.0 *
        SUM(qi.Defective_Qty)
        / NULLIF(SUM(qi.Inspected_Qty),0),
        2
    ) AS Defect_Rate

FROM Vendors v

JOIN Purchase_Orders po
    ON v.Vendor_ID = po.Vendor_ID

JOIN Deliveries d
    ON po.PO_ID = d.PO_ID

JOIN Quality_Inspection qi
    ON d.Delivery_ID = qi.Delivery_ID

GROUP BY
    v.Vendor_ID,
    v.Vendor_Name;






	 



