
--ÖNÁLLÓ FELADAT: írjunk függvényt, amely a paraméterül kapott 
--alkalmazott ID (EmployeeID) alapján
--visszaadja az illető eddigi rendeléseinek a számát! 
--Teszteljük a függvényt SELECT lekérdezéssel!
go
drop function fn_rend_szam
go
create function fn_rend_szam (@empid int)
returns int AS
begin
	declare @rsz int
	select @rsz=count(*) from orders where EmployeeID=@empid 		
	return @rsz
end
go
--teszt
select dbo.fn_rend_szam(EmployeeID), * from Employees
select * from Orders where EmployeeID=1  --126 OK

--ÖNÁLLÓ FELADAT: 
--írjunk függvényt, amely két, datetime típusú változó közül
--visszaadja a korábbit, ha valamelyik null, akkor pedig a 'N.A.' stringet!
--tesztelés az orders táblán
--drop function korabbi
go
create function fn_korabbi (@d1 datetime, @d2 datetime) returns varchar(50) as
begin
	declare @eredm varchar(50)
	if @d1<=@d2 set @eredm=@d1 else if @d2<@d1 set @eredm=@d2 else set @eredm='N.A.'
	return @eredm
end
go
--teszt
select dbo.korabbi('1997-02-08','2001-01-30')


--ÖNÁLLÓ FELADAT: írjunk függvényt, amely egy táblában 
--visszaadja a paraméterként kapott azonosítójú
--alkalmazotthoz tartozó területek nevét és régióját 
--(RegionDescription és TerritoryDescription mezők)! 

create function alkalmazott_regioi (@emp_id int) returns table as
return ( 
	select t.TerritoryDescription, r.RegionDescription
	from EmployeeTerritories et inner join Territories t
		on et.TerritoryID=t.TerritoryID
		inner join Region r on r.RegionID=t.RegionID
	where et.EmployeeID = @emp_id)
--teszt
select * from dbo.alkalmazott_regioi (1) 
order by RegionDescription
