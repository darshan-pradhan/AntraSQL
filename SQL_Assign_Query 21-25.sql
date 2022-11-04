USE WideWorldImporters;

--21
--Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions, that input is a date; 
--when executed, it would find orders of that day, calculate order total, and save the information (order id, order date, order total, customer id)
--into the new table. If a given date is already existing in the new table, throw an error and roll back. 
--Execute the stored procedure 5 times using different dates. 

CREATE SCHEMA ods;
GO

DROP TABLE IF EXISTS ods.Orders;

CREATE TABLE ods.Orders(
	OrderID		int			NOT NULL,
	OrderDate	datetime2	NOT NULL,
	OrderTotal	int			NOT NULL,
	CustomerID	int			NOT NULL
);

DROP PROCEDURE IF EXISTS ods.uspOrdersTest; 

CREATE PROCEDURE ods.uspOrdersTest 
	@date datetime2
AS
	BEGIN TRY
		BEGIN TRANSACTION
		INSERT INTO ods.Orders(
			OrderID,
			OrderDate,
			OrderTotal,
			CustomerID
		)
		SELECT	O.OrderID, 
				O.OrderDate,
				SUM(OL.Quantity*OL.UnitPrice) OrderTotal,
				O.CustomerID
		FROM Sales.Orders O
		LEFT JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
		WHERE O.OrderDate = @Date
		GROUP BY O.OrderDate,O.OrderID, O.CustomerID;
		COMMIT TRANSACTION	
	END TRY  
BEGIN CATCH  
	IF @@TRANCOUNT > 0
		BEGIN
			 PRINT ERROR_MESSAGE()
			 ROLLBACK TRANSACTION
		END
END CATCH;

EXEC ods.uspOrdersTest @date = '2016-01-01';
EXEC ods.uspOrdersTest @date = '2016-02-02';
EXEC ods.uspOrdersTest @date = '2016-02-03';
EXEC ods.uspOrdersTest @date = '2016-02-04';
EXEC ods.uspOrdersTest @date = '2016-02-05';	
	

--22
--Create a new table called ods.StockItem. It has following columns: [StockItemID], [StockItemName] ,[SupplierID] ,
--[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,
--[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments],
--[CountryOfManufacture], [Range], [Shelflife]. Migrate all the data in the original stock item table.

DROP TABLE IF EXISTS ods.StockItem; 

SELECT	[StockItemID],
		[StockItemName] ,
		[SupplierID] ,
		[ColorID] ,
		[UnitPackageID] ,
		[OuterPackageID] ,
		[Brand] ,
		[Size] ,
		[LeadTimeDays] ,
		[QuantityPerOuter] ,
		[IsChillerStock] ,
		[Barcode] ,
		[TaxRate]  ,
		[UnitPrice],
		[RecommendedRetailPrice] ,
		[TypicalWeightPerUnit] ,
		[MarketingComments]  ,
		[InternalComments], 
		JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS [CountryOfManufacture], 
		JSON_VALUE(CustomFields,'$.Range') AS [Range], 
		JSON_VALUE(CustomFields, '$.Shelflife')AS [Shelflife] 
INTO	ods.StockItem
FROM	Warehouse.StockItems;

SELECT	*
FROM ods.StockItem

--23
--Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order data prior to the input date and load the order data that was placed in the next 7 days following the input date.

CREATE SCHEMA ods;
GO

DROP TABLE IF EXISTS ods.Orders;

CREATE TABLE ods.Orders(
	OrderID		int			NOT NULL,
	OrderDate	datetime2	NOT NULL,
	OrderTotal	int			NOT NULL,
	CustomerID	int			NOT NULL
);

DROP PROCEDURE IF EXISTS ods.uspOrdersTest2; 

CREATE PROCEDURE ods.uspOrdersTest2 
	@date datetime2
AS
	BEGIN TRY
		BEGIN TRANSACTION
		DELETE FROM ods.Orders
		WHERE OrderDate < @date
		INSERT INTO ods.Orders(
			OrderID,
			OrderDate,
			OrderTotal,
			CustomerID
		)
		SELECT	O.OrderID, 
				O.OrderDate,
				SUM(OL.Quantity*OL.UnitPrice) OrderTotal,
				O.CustomerID
		FROM Sales.Orders O
		LEFT JOIN Sales.OrderLines OL ON O.OrderID = OL.OrderID
		WHERE O.OrderDate BETWEEN @Date AND DATEADD(DAY,7,@date)
		GROUP BY O.OrderDate,O.OrderID, O.CustomerID;
		COMMIT TRANSACTION	
	END TRY  
BEGIN CATCH  
	IF @@TRANCOUNT > 0
		BEGIN
			 PRINT ERROR_MESSAGE()
			 ROLLBACK TRANSACTION
		END
END CATCH;



--24
--Looks like that it is our missed purchase orders. Migrate these data into Stock Item, Purchase Order and Purchase Order Lines tables. Of course, save the script.

DECLARE @json nvarchar(MAX) 
SET @json = 
	N'[
		{
		   "PurchaseOrders":[
			  {
				 "StockItemName":"Panzer Video Game",
				 "Supplier":"7",
				 "UnitPackageId":"1",
				 "OuterPackageId":[
					6,
					7
				 ],
				 "Brand":"EA Sports",
				 "LeadTimeDays":"5",
				 "QuantityPerOuter":"1",
				 "TaxRate":"6",
				 "UnitPrice":"59.99",
				 "RecommendedRetailPrice":"69.99",
				 "TypicalWeightPerUnit":"0.5",
				 "CountryOfManufacture":"Canada",
				 "Range":"Adult",
				 "OrderDate":"2018-01-01",
				 "DeliveryMethod":"Post",
				 "ExpectedDeliveryDate":"2018-02-02",
				 "SupplierReference":"WWI2308"
			  },
			  {
				 "StockItemName":"Panzer Video Game",
				 "Supplier":"5",
				 "UnitPackageId":"1",
				 "OuterPackageId":"7",
				 "Brand":"EA Sports",
				 "LeadTimeDays":"5",
				 "QuantityPerOuter":"1",
				 "TaxRate":"6",
				 "UnitPrice":"59.99",
				 "RecommendedRetailPrice":"69.99",
				 "TypicalWeightPerUnit":"0.5",
				 "CountryOfManufacture":"Canada",
				 "Range":"Adult",
				 "OrderDate":"2018-01-025",
				 "DeliveryMethod":"Post",
				 "ExpectedDeliveryDate":"2018-02-02",
				 "SupplierReference":"269622390"
			  }
		   ]
		}
	]'
-- insert into StockItems
INSERT INTO Warehouse.StockItems
SELECT *
FROM OPENJSON(@json, '$.PurchaseOrders')
WITH (
	StockItemName			nvarchar(100)	'$.StockItemName',
	SupplierID				int				'$.Supplier',
	UnitPackageId			int				'$.UnitPackageId',
	OuterPackageId			int				'$.OuterPackageId',
	Brand					nvarchar(50)	'$.Brand',
	LeadTimeDays			int				'$.LeadTimeDays',
	QuantityPerOuter		int				'$.QuantityPerOuter',
    TaxRate					decimal(18,3)	'$.TaxRate',
    UnitPrice				decimal(18,2)	'$.UnitPrice',
    RecommendedRetailPrice	decimal(18,2)	'$.RecommendedRetailPrice',
    TypicalWeightPerUnit	decimal(18,3)	'$.TypicalWeightPerUnit',
	CountryOfManufacture	nvarchar(MAX)	'$.CountryOfManufacture',
	Range					nvarchar(MAX)	'$.Range'
)

-- insert into Purchase Order
INSERT INTO Purchasing.PurchaseOrders
SELECT *
FROM OPENJSON(@json, '$.PurchaseOrders')
WITH 
(
	SupplierID				int				'$.Supplier',
    OrderDate				date			'$.OrderDate',
    ExpectedDeliveryDate	date			'$.ExpectedDeliveryDate',
	DeliveryMethodID		int				'$.DeliveryMethodID',
    SupplierReference		nvarchar(20)	'$.SupplierReference'
)


--25
--Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.

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
FOR JSON PATH, ROOT('Order Summary by year 2013-2017');
