-- 1.a feladat (simple)
select c.CategoryName, YEAR(o.OrderDate) as OrderYear, SUM(od.Quantity) as Qty from [Order Details] od 
	join Products p on p.ProductID = od.ProductID
	join Categories c on c.CategoryID = p.CategoryID
	join Orders o on o.OrderID = od.OrderID
where p.UnitPrice > 90
group by c.CategoryName, YEAR(o.OrderDate)
order by c.CategoryName, OrderYear

-- 1.b feladat (pivot)
select * from (
	select c.CategoryName, YEAR(o.OrderDate) as OrderYear, od.Quantity as Qty from [Order Details] od 
	join Products p on p.ProductID = od.ProductID
	join Categories c on c.CategoryID = p.CategoryID
	join Orders o on o.OrderID = od.OrderID
where p.UnitPrice > 90
) as source_table
pivot (
	sum(Qty)
	for OrderYear in ([1996],[1997],[1998])
) as pivot_table

-- 2. feladat (function)
select count(*) from EmployeeTerritories where EmployeeID = 5

drop function if exists dbo.countTerritories
go
create function dbo.countTerritories(@user_id int) returns int
as
begin
	declare @result int

	if exists(select 1 from EmployeeTerritories where EmployeeID = @user_id)
		begin
			select @result = count(*) from EmployeeTerritories where EmployeeID = @user_id
		end
	else
		set @result = NULL

return @result
end

go
select dbo.countTerritories(5) as CountResult

-- 3. feladat (procedure)
go
drop procedure if exists assignTerritoryToEmployee
go
create procedure assignTerritoryToEmployee @user_id int
as
begin
	begin try --hibakezelés
		declare @territory_count int;
		declare @new_territory_id nvarchar(20);
		declare @new_territory_desc nvarchar(50);

		---mehívjuk az előző feladat függvényét
		set @territory_count = dbo.countTerritories(@user_id)

		--ha nincs ilyen dolgozó hibát dobunk
		if @territory_count is null
		begin
			raiserror('Nincs ilyen dolgozó!', 16, 1)
			return
		end
		else if @territory_count >= 5
		begin
			raiserror('A dolgozóhoz nem lehet több területet hozzárendelni!',16,1)
		end

		-- ellenőrizzük hogy van-e olyan terület ami még senkihez nem tartozik
		select top 1 @new_territory_id=TerritoryID, @new_territory_desc=TerritoryDescription from Territories T
		where not exists (select 1 from EmployeeTerritories ET where ET.TerritoryID = T.TerritoryID)
		order by T.TerritoryDescription

		-- ha nincs ilyen akkor hibát dobunk
		if @new_territory_id is null
		begin
			raiserror('Nincs szabad terület',16,1)
			return
		end

		-- ha van üres rendeljük hozzá
		insert into EmployeeTerritories (EmployeeID, TerritoryID)
		values (@user_id, @new_territory_id);

		-- fizetés emelés
		update Employees set Salary = Salary * 1.25 where EmployeeID = @user_id

		-- kiírjuk amit hozzárendeltünk
		print 'Hozzárendelt terület: ' + @new_territory_desc;

	end try
	begin catch
		-- hiba kiírása
		print 'Hiba történt: ' + error_message()
	end catch
end

-- tesztelés
select * into #BackupEmployeeTerritories from  EmployeeTerritories --biztonsági mentések tept táblákba
select EmployeeID, Salary into #BackupEmployees from Employees;

-- teszteset: már többb mint 5 területe van
delete from EmployeeTerritories where EmployeeID = 1; --kiuritjuk az 1-es dolgozot
insert into EmployeeTerritories (EmployeeID, TerritoryID) select top 6 1, TerritoryID from Territories; --hozzáadunk 6 területet
exec assignTerritoryToEmployee @user_id = 1; -- futtatjuk az eljárást -> hiba több mint 5

-- teszteset: nincs szabad hely
delete from EmployeeTerritories where EmployeeID = 1; --ürítem az 1 est
-- minden szabad területet lefoglalok
insert into EmployeeTerritories (EmployeeID, TerritoryID) select 1, TerritoryID from Territories; --hozzáadjuk a 1-es dolgozohoz mindet 
exec assignTerritoryToEmployee @user_id = 2; -- futtatjuk az eljárást 2es dolgozóra -> hiba: nincs több szabad hely (mert az 1eshez adtunk mindent)


-- teszteset: kevesebb mint 5 területe van és hely is van
delete from EmployeeTerritories
insert into EmployeeTerritories (EmployeeID, TerritoryID)
	select 1, TerritoryID from Territories
	order by TerritoryDescription offset 0 rows fetch next 2 rows only;

-- megnézzük a dolgozó fizuját
select Salary from Employees where EmployeeID = 1;
exec assignTerritoryToEmployee @user_id = 1; -- futtatjuk az eljárást -> területet kapott és fizetés emelést

-- megnézzük a dolgozó fizuját emelkedett-e
select Salary from Employees where EmployeeID = 1;
-- megnézzük kapott-e terültet
select * from EmployeeTerritories where EmployeeID = 1;

-- visszaállítjuk az eredeti állapotot
delete from EmployeeTerritories; -- uritjuk sz összerendelést

insert into EmployeeTerritories (EmployeeID, TerritoryID)
	select EmployeeID, TerritoryID from #BackupEmployeeTerritories; --visszaállítjuk az eredeti összeredelést

-- visszaállítjuk a fizetéseket
update Employees set Salary = b.Salary from Employees e join #BackupEmployees b on b.EmployeeID = e.EmployeeID;

-- temp táblák törlése
drop table #BackupEmployees
drop table #BackupEmployeeTerritories

-- 4. feladat (trigger)
go
drop trigger if exists update_salary_trigger
go
create trigger update_salary_trigger
on EmployeeTerritories after insert, delete as
begin
	-- ha insert történik (fizu emelés)
	if exists(select * from inserted)
	begin
		update Employees set Salary = Salary * 1.25 where EmployeeID in (select EmployeeID from inserted)
	end
	-- ha delete történik (fizu csökkentés)
	if exists(select * from deleted)
	begin
		update Employees set Salary = Salary* 0.80 where EmployeeID in (select EmployeeID from deleted)
	end
end

-- trigger tesztelése: létrehozunk egy uj területet amit hozzáadunk az 1-eshez -> fizu növekedés
insert into EmployeeTerritories (EmployeeID, TerritoryID)
	select 1, TerritoryID from Territories where TerritoryDescription = 'Denver'

SELECT Salary FROM Employees WHERE EmployeeID = 1; -- fizu ellenorzés

-- majd eltávolítjuk -> fizu csökkenés
delete from EmployeeTerritories where EmployeeID = 1 and TerritoryID = 80202

SELECT Salary FROM Employees WHERE EmployeeID = 1; -- fizu ellenorzés

-- 5. feladat (tranzakció)

-- a 3-as feladatban létrehozott tárolt eljárás tranzakciós változata
go
drop procedure if exists assignTerritoryToEmployee
go
create procedure assignTerritoryToEmployee @user_id int
as
begin
	BEGIN TRANSACTION; -- Tranzakció start

	begin try --hibakezelés
		declare @territory_count int;
		declare @new_territory_id nvarchar(20);
		declare @new_territory_desc nvarchar(50);

		---mehívjuk az előző feladat függvényét
		set @territory_count = dbo.countTerritories(@user_id)

		--ha nincs ilyen dolgozó hibát dobunk
		if @territory_count is null
		begin
			raiserror('Nincs ilyen dolgozó!', 16, 1)
			return
		end
		else if @territory_count >= 5
		begin
			raiserror('A dolgozóhoz nem lehet több területet hozzárendelni!',16,1)
		end

		-- ellenőrizzük hogy van-e olyan terület ami még senkihez nem tartozik
		select top 1 @new_territory_id=TerritoryID, @new_territory_desc=TerritoryDescription from Territories T
		where not exists (select 1 from EmployeeTerritories ET where ET.TerritoryID = T.TerritoryID)
		order by T.TerritoryDescription

		-- ha nincs ilyen akkor hibát dobunk
		if @new_territory_id is null
		begin
			raiserror('Nincs szabad terület',16,1)
			return
		end

		-- ha van üres rendeljük hozzá
		insert into EmployeeTerritories (EmployeeID, TerritoryID)
		values (@user_id, @new_territory_id);

		-- fizetés emelés
		update Employees set Salary = Salary * 1.25 where EmployeeID = @user_id

		-- kiírjuk amit hozzárendeltünk
		print 'Hozzárendelt terület: ' + @new_territory_desc;

	COMMIT -- tranzakció end

	end try
	begin catch
		-- hiba kiírása
		ROLLBACK -- tranzakció visszavonás hiba esetén

		print 'Hiba történt: ' + error_message()
	end catch
end

exec assignTerritoryToEmployee @user_id = 1;

-- 6. feladat (kurzorok)
declare @EmployeeID int, @FullName nvarchar(100), @counter int = 1;

declare employee_cursor cursor for
select EmployeeID, FirstName + ' ' + LastName
from Employees
where Country = 'UK'
order by LastName, FirstName

open employee_cursor
fetch next from employee_cursor into @EmployeeID, @FullName

while @@FETCH_STATUS = 0
begin
    print cast(@counter as varchar) +'. '+ @FullName + ':'

    -- Most lekérdezzük a területeket ehhez az ügynökhöz
    declare @Territory nvarchar(50)
    declare territory_cursor cursor for
    
	select T.TerritoryDescription from Territories T join EmployeeTerritories ET on T.TerritoryID = ET.TerritoryID
		where ET.EmployeeID = @EmployeeID

    open territory_cursor
    fetch next from territory_cursor into @Territory

    while @@FETCH_STATUS = 0
    begin
        print ' - ' + @Territory
        fetch next from territory_cursor into @Territory
    end

    close territory_cursor
    deallocate territory_cursor

	set @counter = @counter + 1
    fetch next from employee_cursor into @EmployeeID, @FullName
end

close employee_cursor
deallocate employee_cursor

-- 7. fealdat (ablakozás)
