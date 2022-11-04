USE WideWorldImporters;
 
--6
--List of stock items that are not sold to the state of Alabama and Georgia in 2014.

SELECT OL.StockItemID
FROM Sales.OrderLines OL
LEFT JOIN Sales.Orders O ON OL.OrderID = O.OrderID
LEFT JOIN Sales.Customers Cu ON O.CustomerID = Cu.CustomerID
LEFT JOIN Application.Cities C ON Cu.DeliveryCityID = C.CityID
LEFT JOIN Application.StateProvinces SP ON C.StateProvinceID = SP.StateProvinceID
WHERE SP.StateProvinceName != 'Alabama' AND SP.StateProvinceName != 'Georgia' AND YEAR(O.OrderDate) = 2014
GROUP BY OL.StockItemID;


--7
--List of States and Avg dates for processing (confirmed delivery date – order date).

SELECT SP.StateProvinceName, AVG(DATEDIFF(day,O.OrderDate,I.ConfirmedDeliveryTime)) AS ProcessingTime
FROM Sales.Invoices I 
JOIN Sales.Orders O ON I.OrderID = O.OrderID
JOIN Sales.Customers Cu ON O.CustomerID = Cu.CustomerID
JOIN Application.Cities C ON Cu.DeliveryCityID = C.CityID
JOIN Application.StateProvinces SP ON C.StateProvinceID = SP.StateProvinceID
GROUP BY SP.StateProvinceName
ORDER BY SP.StateProvinceName;


--8
--List of States and Avg dates for processing (confirmed delivery date – order date) by month.

SELECT SP.StateProvinceName, AVG(DATEDIFF(DAY,O.OrderDate,I.ConfirmedDeliveryTime)) AS ProcessingTime, MONTH(O.OrderDate) AS Month
FROM Sales.Invoices I 
JOIN Sales.Orders O ON I.OrderID = O.OrderID
JOIN Sales.Customers Cu ON O.CustomerID = Cu.CustomerID
JOIN Application.Cities C ON Cu.DeliveryCityID = C.CityID
JOIN Application.StateProvinces SP ON C.StateProvinceID = SP.StateProvinceID
GROUP BY SP.StateProvinceName, MONTH(O.OrderDate)
ORDER BY SP.StateProvinceName, MONTH(O.OrderDate);


--9
--List of StockItems that the company purchased more than sold in the year of 2015.

SELECT SI.StockItemID, SI.StockItemName 
FROM Warehouse.StockItems SI
JOIN Warehouse.StockItemTransactions SIT ON SI.StockItemID = SIT.StockItemID
WHERE YEAR(SIT.TransactionOccurredWhen) = 2015
GROUP BY SI.StockItemID, SI.StockItemName
HAVING  sum(SIT.Quantity) > 0; 


--10
--List of Customers and their phone number, together with the primary contact person’s name, to whom we did not sell more than 10  mugs (search by name) in the year 2016.

SELECT Cu.CustomerID, Cu.PhoneNumber, P.FullName AS PrimaryContactName
FROM Sales.Customers Cu 
JOIN Application.People P ON Cu.PrimaryContactPersonID = P.PersonID
JOIN Sales.Orders O ON P.PersonID = O.ContactPersonID
JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
WHERE OL.Description LIKE '%mug%' AND  YEAR(O.OrderDate) = 2016
GROUP BY Cu.CustomerID,Cu.PhoneNumber, P.FullName
HAVING SUM(OL.Quantity)<=10;