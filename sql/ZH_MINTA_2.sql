--1. feladat
-- a lekérdezés
select p.CategoryID, p.ProductID, p.UnitPrice, p.Discontinued, sum(p.UnitPrice*od.Quantity*(1-od.Discount))as ar from Products p
	join [Order Details] od on p.ProductID = od.ProductID
	join Orders o on o.OrderID = od.OrderID
	where o.CustomerID = 'ALFKI' and o.OrderDate >= '1997-08-25'
	group by p.CategoryID, p.ProductID, p.UnitPrice, p.Discontinued
	order by ar desc

go
create function dbo.legtobbetVasaroltByCustomer(@customerId char(10), @startDate date) returns int as
begin
	declare @catId int

	select top 1 @catId = p.CategoryID from Products p
	join [Order Details] od on p.ProductID = od.ProductID
	join Orders o on o.OrderID = od.OrderID
	where o.CustomerID = @customerId and o.OrderDate >= @startDate
	group by p.CategoryID
	order by sum(p.UnitPrice*od.Quantity*(1-od.Discount)) desc

	return @catId
end

go
--teszt
select dbo.legtobbetVasaroltByCustomer('ALFKI','1997-08-25')
select dbo.legtobbetVasaroltByCustomer('ALFKI','2025-08-25')

--2. feladat
drop procedure if exists employeeHelper
go
create procedure employeeHelper @customerId char(10), @startDate date as
begin
	declare @catId int, @empId int, @empName nvarchar(50), @customerTerritoryId int
	begin try
		begin transaction
		if(select c.CustomerID from Customers c where c.CustomerID=@customerId) is null
		begin	
			print 'Ügyfél nem létezik'
			rollback transaction;
		end
		else
		if (select c.Country from Customers c where c.CustomerID = @customerId) != 'USA'
		begin	
			print 'Nem amerikai!'
			rollback transaction;
		end
		else
		begin
			select @catId = dbo.legtobbetVasaroltByCustomer(@customerId, @startDate);
			print 'catId: '+ cast(@catId as varchar)

			select top 1 @empId = e.EmployeeID, @empName = e.LastName from Employees e
			join Orders o on o.EmployeeID = e.EmployeeID
			join [Order Details] od on od.OrderID = o.OrderID
			join Products p on p.ProductID = od.ProductID
			where p.CategoryID = 1
			group by e.EmployeeID, e.LastName
			order by sum(od.Quantity*p.UnitPrice*(1-od.Discount)) desc

			print concat('Legtöbbet eladott a fenti kategoriában: ', @empId, '/', @empName)
			--select @customerTerritoryId = c.territory_id from Customers c where c.CustomerID = CustomerID   ---hiányzik a databázisból
			set @customerTerritoryId = 02116; -- helyette fixen
			if @customerTerritoryId is null
			begin
				print 'Nincs terület definiálva a customernek!'
				rollback transaction
			end
			else
			begin
				if (select 1 from EmployeeTerritories et where et.EmployeeID = @empId and et.TerritoryID = @customerTerritoryId) = 1
				begin
					print 'Már dolgozik ezen a területen az ügynök!'
					rollback transaction
				end
				else
				begin
					print 'Még nem dolgozik itt az ügynök, adjuk hozzá...'
					insert into EmployeeTerritories(EmployeeID, TerritoryID) values (@empId, @customerTerritoryId)
					commit transaction
					print 'tranzakció sikeres!'
				end
			end
		end
	end try
	begin catch
		rollback transaction
		print 'Error - A tranzakció visszavonva!'
		print error_message()
	end catch
end

exec employeeHelper 'AAAAA','1997-08-25' --nem létezik
exec employeeHelper 'ALFKI','1997-08-25' --nem amerikai
exec employeeHelper 'OLDWO','1997-08-25' --legtobb termeket eladott employee az adott kategoriában

-- feladat 3
go
create trigger TerritoriesTrigger on EmployeeTerritories after insert
as begin
	declare @i int
	begin
		select @i = count(*) from inserted
		print 'beszurt adatok szama: '+ cast(@i as varchar(50))
		update Employees set Salary = Salary + 100 where EmployeeID in (select EmployeeID from inserted)
	end
end

SELECT EmployeeID, Salary FROM Employees
update Employees set Salary = 100 where Salary != 100
INSERT INTO EmployeeTerritories (EmployeeID, TerritoryID)
VALUES 
(1, '001'),
(2, '002'),
(3, '003');

select * from EmployeeTerritories
select salary from Employees where EmployeeID=3    -- 106.1208
insert EmployeeTerritories (EmployeeID, TerritoryID) values (3, 19713)
update Employees set Salary= 106.1208 where EmployeeID=3
delete from EmployeeTerritories where EmployeeID=3 and TerritoryID=19713