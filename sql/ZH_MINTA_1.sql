--######
--# 1. #
--######
--A
SELECT	YEAR(o.OrderDate) as Év, c.CategoryName as Kategória, SUM(od.Quantity) as Mennyiség
FROM Categories c, 
	Products p,
	[Order Details] od
	join Orders o on o.OrderID = od.OrderID
WHERE p.UnitPrice > 90	
GROUP BY YEAR(OrderDate), c.CategoryID, c.CategoryName
ORDER BY Év, Kategória

--B
SELECT *
FROM (SELECT	YEAR(o.OrderDate) as Év, c.CategoryName as Kategória, SUM(od.Quantity) as Mennyiség
FROM Categories c, 
	Products p,
	[Order Details] od
	join Orders o on o.OrderID = od.OrderID
WHERE p.UnitPrice > 90	
GROUP BY YEAR(OrderDate), c.CategoryID, c.CategoryName
) as forrasTabla
PIVOT (
	sum(Mennyiség) for Év in ([1996], [1997], [1998])
) as pivotTabla

--######
--# 2. #
--######
SELECT EmployeeID, COUNT(TerritoryID) AS Teruletszam
  FROM EmployeeTerritories
  GROUP BY EmployeeID

SELECT * 
  FROM EmployeeTerritories et
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
		

--szkript
--drop procedure if exists feladat_2
GO
create procedure feladat_2 @azonosito INT as
begin
	SET NOCOUNT ON
	--DECLARE @azonosito INT --bemenő paraméter
	--SET @azonosito = 1
	declare @empTerrCounter int
	declare @freeTerritoryId int, @freeTerritoryName nvarchar(50)

	begin try
		select @empTerrCounter = count(*) from EmployeeTerritories et where et.EmployeeID = @azonosito
		if (@empTerrCounter >= 5)
		begin
			raiserror ('Az emplyee-hoz már nem rendelhető több terület!',16,1)
			return
		end
		else
		begin
			print 'Szabad terület ellenőrzése'
			select top 1 @freeTerritoryId = t.TerritoryID, @freeTerritoryName = t.TerritoryDescription from Territories t 
				where not exists (select 1 from EmployeeTerritories et where et.TerritoryID = t.TerritoryID) order by t.TerritoryDescription
			if @freeTerritoryId is not null
			begin
				print 'Talált szabad terület: ' + cast(@freeTerritoryId as varchar(50)) + ' ' + @freeTerritoryName
				insert into EmployeeTerritories(EmployeeID, TerritoryID) values (@azonosito, @freeTerritoryId) -- hozzárendelés
				update Employees set Salary = Salary*1.25 where EmployeeID = @azonosito
				print 'A dolgozóhoz hozzárendelt új terület: ' + @freeTerritoryName
			end
			else
			begin
				raiserror ('Nincs szabad terület!',16,1)
				return
			end
		end
	end try
	begin catch
		raiserror('Hiba történt: ',16,1)
		print error_message()
	end catch
end
GO	

--tesztelés feladat_2
exec feladat_2 @azonosito=7 -- nem rendelhető hozzá több
exec feladat_2 @azonosito=1 -- van szabad terület, hozzá is rendeljük
exec feladat_2 @azonosito=4


--tesztelés
--1. teszt eredménye
/*
1/a
Év          Kategória       Mennyiség
----------- --------------- -----------
1996        Beverages       28743
1996        Condiments      28743
1996        Confections     28743
1996        Dairy Products  28743
1996        Grains/Cereals  28743
1996        Meat/Poultry    28743
1996        Produce         28743
1996        Seafood         28743
1997        Beverages       76467
1997        Condiments      76467
1997        Confections     76467
1997        Dairy Products  76467
1997        Grains/Cereals  76467
1997        Meat/Poultry    76467
1997        Produce         76467
1997        Seafood         76467
1998        Beverages       48741
1998        Condiments      48741
1998        Confections     48741
1998        Dairy Products  48741
1998        Grains/Cereals  48741
1998        Meat/Poultry    48741
1998        Produce         48741
1998        Seafood         48741

1/b
Kategória       1996        1997        1998
--------------- ----------- ----------- -----------
Seafood         28743       76467       48741
Meat/Poultry    28743       76467       48741
Condiments      28743       76467       48741
Confections     28743       76467       48741
Produce         28743       76467       48741
Dairy Products  28743       76467       48741
Beverages       28743       76467       48741
Grains/Cereals  28743       76467       48741
*/
--2. teszt eredménye
/*
1. eset:
Hiba történt: 
Az emplyee-hoz már nem rendelhető több terület!

2.eset
Szabad terület ellenorzése
Talált szabad terület: 75234 Dallas                                            
beszurt adatok szama: 1
A dolgozóhoz hozzárendelt új terület: Dallas         

3.eset
Szabad terület ellenorzése
Hiba történt: 
Nincs szabad terület!

*/