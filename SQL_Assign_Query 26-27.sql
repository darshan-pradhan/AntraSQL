USE WideWorldImporters;

--26
--Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.

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
	ORDER BY Years
FOR XML PATH('Order Summary');


--27
--Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . Create a stored procedure, input is a date. The logic would load invoice information (all columns) as well as invoice line information (all columns) and forge them into a JSON string and then insert into the new table just created. Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.

DROP TABLE IF EXISTS ods.ConfirmedDeliveryJson;
CREATE TABLE ods.ConfirmedDeliveryJson (
	id int,
	date datetime2,
	value nvarchar(max)
)

IF OBJECT_ID('ods.uspDeliveryTest','P') IS NOT NULL
	DROP PROCEDURE ods.uspDeliveryTest
GO 

CREATE PROCEDURE ods.uspDeliveryTest 
	@date datetime2
AS
	DECLARE @json2 nvarchar(MAX);
	SET @json2 =(
	SELECT id=I.InvoiceID, date=I.InvoiceDate, value=IL.Quantity*IL.UnitPrice
	FROM Sales.Invoices AS I 
	JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
	AND I.InvoiceDate = @date
	FOR JSON PATH)
	EXEC @json2

INSERT INTO ConfirmedDeliveryJson(id, date, value)

SELECT *
FROM OPENJSON(@json2)
WITH(id INT '$.id',
	 date DATETIME2 '$.date',
	 value nvarchar(MAX) '$.value');



EXECUTE ods.uspDeliveryTest @date='2013-01-01';
