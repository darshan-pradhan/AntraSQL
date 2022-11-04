USE WideWorldImporters;
 
--11
--List all the cities that were updated after 2015-01-01.

SELECT CityName
FROM Application.Cities
WHERE ValidFrom > '2015-01-01';


--12
--List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, customer name, 
--customer contact person name, customer phone, quantity) for the date of 2014-07-01. Info should be relevant to that date.

SELECT	SI.StockItemName, 
		I.DeliveryInstructions AS DeliveryAddress,
		SP.StateProvinceName AS DeliveryState,
		C.CityName AS City, 
		Cou.CountryName AS Country,
		Cu.CustomerName,
		P.FullName AS CustomerContactPersonName,
		Cu.PhoneNumber AS CustomerPhone,
		OL.Quantity
FROM Sales.Orders O
	LEFT JOIN Sales.Invoices I ON O.OrderID = I.OrderID
	LEFT JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
	LEFT JOIN Warehouse.StockItems SI ON OL.StockItemID = SI.StockItemID
	JOIN Sales.Customers Cu ON I.CustomerID = Cu.CustomerID
	LEFT JOIN Application.Cities C ON Cu.PostalCityID = C.CityID
	LEFT JOIN Application.StateProvinces SP ON C.StateProvinceID = SP.StateProvinceID
	JOIN Application.Countries Cou ON SP.CountryID = Cou.CountryID
	JOIN Application.People P ON Cu.PrimaryContactPersonID = P.PersonID
WHERE O.OrderDate = '2014-07-01';


--13
--List of stock item groups and total quantity purchased, total quantity sold, and the remaining stock quantity (quantity purchased – quantity sold)

WITH cte1 (StockGroupName, TotalQuantityPurchased) AS (
	SELECT	SG.StockGroupName,
			SUM(POL.OrderedOuters) AS TotalQuantityPurchased
	FROM Purchasing.PurchaseOrderLines POL
		JOIN Warehouse.StockItemStockGroups SISG ON POL.StockItemID = SISG.StockItemID
		JOIN Warehouse.StockGroups SG ON SISG.StockGroupID = SG.StockGroupID
	GROUP BY SG.StockGroupName),

cte2 (StockGroupName, TotalQuantitySold) AS (
	SELECT	SG.StockGroupName,
			ABS(SUM(IL.Quantity)) AS TotalQuantitySold
	FROM Sales.InvoiceLines IL 
		JOIN Warehouse.StockItemStockGroups SISG ON SISG.StockItemID = IL.StockItemID
		JOIN Warehouse.StockGroups SG ON SISG.StockGroupID = SG.StockGroupID
	GROUP BY SG.StockGroupName
	)

SELECT	cte1.StockGroupName, 
		cte1.TotalQuantityPurchased, 
		cte2.TotalQuantitySold, 
		(cte1.TotalQuantityPurchased - cte2.TotalQuantitySold) AS RemainingStockQuantity
FROM cte1 
	JOIN cte2 ON cte1.StockGroupName = cte2.StockGroupName;


--14
--List of Cities in the US and the stock item that the city got the most deliveries in 2016. If the city did not purchase any stock items in 2016, print “No Sales”.

WITH cte(CityName, StockItemID, NumberOfDeliverys ) AS (
	SELECT	DISTINCT C.CityName, OL.StockItemID,
			CASE WHEN SUM(OL.Quantity) IS NULL THEN 'No Sales' ELSE SUM(OL.Quantity) END AS NumberOfDeliverys 
	FROM Sales.Orders O 
		JOIN Sales.OrderLines AS OL ON O.OrderID = OL.OrderID
		JOIN Sales.Customers AS Cu ON O.CustomerID = Cu.CustomerID
		JOIN Application.Cities AS C ON Cu.DeliveryCityID = C.CityID
		JOIN Application.StateProvinces AS SP ON SP.StateProvinceID = C.StateProvinceID
		JOIN Application.Countries AS Co ON Co.CountryID = SP.CountryID
	WHERE YEAR(O.OrderDate) = 2016 AND Co.CountryName = 'United States'
	GROUP BY CityName, StockItemID)
SELECT cte.CityName, cte.StockItemID, cte.NumberOfDeliverys
FROM cte 
ORDER BY cte.NumberOfDeliverys DESC;



--15
--List any orders that had more than one delivery attempt (located in invoice table).

SELECT I.OrderID
FROM Sales.Invoices I
WHERE JSON_VALUE(I.ReturnedDeliveryData, '$.Events[1].Status') IS NULL