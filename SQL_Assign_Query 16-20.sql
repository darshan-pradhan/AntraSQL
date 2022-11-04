USE WideWorldImporters;

--16
--List all stock items that are manufactured in China. (Country of Manufacture)

SELECT	SI.StockItemID,
		SI.StockItemName
FROM Warehouse.StockItems SI 
WHERE JSON_VALUE(SI.CustomFields,'$.CountryOfManufacture')= 'China';


--17
--Total quantity of stock items sold in 2015, group by country of manufacturing.

SELECT	JSON_VALUE(SI.CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
		SUM(OL.Quantity) AS TotalQuantity
FROM Warehouse.StockItems SI 
	JOIN Sales.OrderLines OL ON SI.StockItemID = OL.StockItemID
	JOIN Sales.Orders O ON OL.OrderID = O.OrderID
WHERE YEAR(O.OrderDate) = 2015
GROUP BY JSON_VALUE(SI.CustomFields, '$.CountryOfManufacture');


--18
--Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]

IF OBJECT_ID('Sales.vOrders', 'view') IS NOT NULL
	DROP VIEW Sales.vOrders;
GO

CREATE VIEW Sales.vOrders AS
	WITH vCTE(StockGroupName, Y2013,Y2014, Y2015, Y2016, Y2017) 
	AS(
		SELECT	SG.StockGroupName AS StockGroupName, 
				SUM(CASE WHEN YEAR(O.OrderDate) = 2013 THEN OL.Quantity ELSE 0 END) AS 'Y2013',
				SUM(CASE WHEN YEAR(O.OrderDate) = 2014 THEN OL.Quantity ELSE 0 END) AS 'Y2014',
				SUM(CASE WHEN YEAR(O.OrderDate) = 2015 THEN OL.Quantity ELSE 0 END) AS 'Y2015',
				SUM(CASE WHEN YEAR(O.OrderDate) = 2016 THEN OL.Quantity ELSE 0 END) AS 'Y2016',
				SUM(CASE WHEN YEAR(O.OrderDate) = 2017 THEN OL.Quantity ELSE 0 END) AS 'Y2017'
		FROM Sales.Orders O
			JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
			LEFT JOIN Warehouse.StockItemStockGroups SISG ON OL.StockItemID = SISG.StockItemID
			LEFT JOIN Warehouse.StockGroups SG ON SISG.StockGroupID = SG.StockGroupID
		WHERE YEAR(O.OrderDate) >= 2013 AND YEAR(O.OrderDate) <= 2017
		GROUP BY StockGroupName,YEAR(O.OrderDate)
		)
	SELECT StockGroupName, SUM(Y2013) AS '2013',SUM(Y2014) AS '2014', SUM(Y2015) AS '2015', SUM(Y2016) AS '2016', SUM(Y2017) AS '2017'
	FROM vCTE
	GROUP BY vCTE.StockGroupName;
GO

--19
--Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10] 

IF OBJECT_ID('Sales.vOrders2', 'view') IS NOT NULL
	DROP VIEW Sales.vOrders2;
GO

CREATE VIEW Sales.vOrders2 
	AS
	SELECT *
	FROM(
		SELECT	SG.StockGroupName AS StockGroupName, 
				OL.Quantity AS Quantity,
				YEAR(O.OrderDate) AS Years
		FROM Sales.Orders O
			JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
			LEFT JOIN Warehouse.StockItemStockGroups SISG ON OL.StockItemID = SISG.StockItemID
			LEFT JOIN Warehouse.StockGroups SG ON SISG.StockGroupID = SG.StockGroupID
		WHERE YEAR(O.OrderDate) >= 2013 AND YEAR(O.OrderDate) <= 2017
		) SourceTable
	PIVOT 
		(SUM(Quantity) 
		FOR StockGroupName IN (
								[T-Shirts],
								[USB Novelties],
								[Packaging Materials],
								[Clothing], 
								[Novelty Items], 
								[Furry Footwear], 
								[Mugs], 
								[Computing Novelties], 
								[Toys])) PivotTable
	--ORDER BY Years;
GO
-- Since year 2017 is not shown, therefore total quantity sold in 2017 is 0.

--20
--Create a function, input: order id; return: total of that order. List invoices and use that function to attach the order total to the other fields of invoices. 

IF OBJECT_ID (N'dbo.TotalOfOrder', N'FN') IS NOT NULL
    DROP FUNCTION TotalOfOrder;
GO

CREATE FUNCTION dbo.TotalOfOrders(@OrderID int)
RETURNS int
BEGIN 
	DECLARE @ret int;
	SELECT @ret = SUM(IL.Quantity*IL.UnitPrice)
	FROM Sales.Invoices I 
	JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
	WHERE I.OrderID = @OrderID
	IF (@ret IS NULL)
		SET @ret = 0
	RETURN @ret;
END;

SELECT	I.InvoiceID, 
		I.OrderID, 
		dbo.TotalOfOrders(I.OrderID) AS Total
FROM Sales.Invoices I;

