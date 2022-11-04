USE WideWorldImporters;

--1
--List of Persons’ full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). 

SELECT P.FullName, P.FaxNumber, P.PhoneNumber, Cu.PhoneNumber AS CompanyPhone, Cu.FaxNumber AS CompanyFax
FROM Application.People P
	JOIN Sales.Customers Cu ON P.PersonID = Cu.PrimaryContactPersonID OR P.PersonID = Cu.AlternateContactPersonID;


--2
--If the customer's primary contact person has the same phone number as the customer’s phone number, list the customer companies. 

SElECT CustomerName
FROM Sales.Customers AS Cu
WHERE Cu.PrimaryContactPersonID IN (
	SELECT p.PersonID
	FROM Application.People as p
	WHERE p.PhoneNumber=Cu.PhoneNumber);


--3
--List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.

SELECT DISTINCT CustomerID
FROM Sales.CustomerTransactions
WHERE TransactionDate < '2016-01-01'
EXCEPT
SELECT DISTINCT CustomerID 
FROM Sales.CustomerTransactions 
WHERE TransactionDate >= '2016-01-01'
GROUP BY CustomerID;


--4
--List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.

SELECT SI.StockItemID, SI.StockItemName, SUM(POL.OrderedOuters) Total_Quantity
FROM Warehouse.StockItems SI 
JOIN Purchasing.PurchaseOrderLines POL ON SI.StockItemID = POL.StockItemID
JOIN Purchasing.PurchaseOrders PO ON POL.PurchaseOrderID = PO.PurchaseOrderID
WHERE YEAR(PO.OrderDate) = 2013
GROUP BY SI.StockItemID, SI.StockItemName;


--5
--List of stock items that have at least 10 characters in description.

SELECT SI.StockItemID, SI.StockItemName
FROM Warehouse.StockItems SI
RIGHT JOIN Sales.InvoiceLines IL ON SI.StockItemID = IL.StockItemID
WHERE LEN(IL.Description)>9;