use [northwind];
select * from northwind.dbo.Employees;

-------------------------------------------------------------------------------- Mező orientáltból -> Rekord orientáltba --------------------------------------------------------------------------------
-- 1. az employee cuccait beletesszük egy új táblába
drop table if exists employee_field
select employeeid, lastname, title, city
    into employee_field from northwind.dbo.Employees

-- ellenőrzés
select * from northwind.dbo.employee_field

-- csinálunk egy attributum táblát

drop table if exists attributes
create table attributes( 
    attrib_id int primary key, 
    attrib_name nvarchar(100), 
    attrib_type nvarchar(100)
) 

-- feltöltjük az attributum kezelő táblát
insert into attributes
    values (1, 'Last name', 'text'), (2, 'Title', 'text'), (3, 'City', 'text')

-- ellenőrzés
select * from attributes

-- csinálunk egy új táblát az employee rekordoknak
drop table if exists employee_record
create table employee_record(
    emp_id int not null,
    attrib_id int not null references attributes (attrib_id),
    attrib_value nvarchar(500),
    primary key (emp_id, attrib_id)
)

--az employee field tartalmát reprodukáljukaaz emplyee_records táblában
insert into employee_record(emp_id, attrib_id, attrib_value)
	select employeeid, 1, lastname from employee_field where lastname is not null
		union
	select employeeid, 2, title from employee_field where title is not null
		union
	select employeeid, 3, city from employee_field where city is not null

-- ellenőrzés: itt nem lesznek már NULL-os mezők :)
select * from employee_record

-- GUI számára pontosabb lekérdezés kellhet
select e.emp_id, a.attrib_name, a.attrib_type, e.attrib_value from employee_record e 
	inner join attributes a on e.attrib_id = a.attrib_id

--------------------------------------------------------------------------------Vissza alakítás! (Rekord orientáltból -> Mező orientáltba) --------------------------------------------------------------------------------
select emp_id as employeeid,
	min(case
		when attrib_id=1 then attrib_value
		 else null
		end) as lastname,
	min(case
		when attrib_id=2 then attrib_value
		 else null
		end) as title,
	min(case
		when attrib_id=3 then attrib_value
		 else null
		end) as city
from employee_record group by emp_id

/*ÖNÁLLÓ FELADAT #1: Készítsük el és töltsük fel a Products tábla rekord-orientált változatát, ha a tárolt
attribútumok a Productname, a Unitprice, és a Discontinued!*/

drop table if exists products_field
select ProductID, ProductName, UnitPrice, Discontinued 
	into products_field from Products

select * from products_field

-- új attributes tábla nem kell, jó ami van, ebbe tesszük bele az újakat is
insert into attributes values 
	(4, 'product_name', 'text'),
	(5, 'unit_price', 'money'),
	(6, 'discontinued', 'bit')

-- új tábla a product rekordoknak
drop table if exists product_record
create table product_record(
	prod_id int not null,
	attrib_id int not null references attributes(attrib_id),
	attrib_value nvarchar(500),
	primary key(prod_id, attrib_id)
)

select * from product_record

-- beletesszük az adatokat
insert into product_record(prod_id, attrib_id, attrib_value)
	select ProductID, 4, ProductName from Products where ProductName is not null
		union
	select ProductID, 5, cast(UnitPrice as nvarchar(500)) from Products where UnitPrice is not null
		union
	select ProductID, 6, cast(Discontinued as nvarchar(500)) from Products where Discontinued is not null

-- visszaalakítás
select prod_id, 
	min(case
		when attrib_id=4 then attrib_value else null end) as productname,
	min(case
		when attrib_id=5 then cast(attrib_value as money) else null end) as unitprice,
	min(case
		when attrib_id=6 then cast(attrib_value as bit) else null end) as discounted
 from product_record group by prod_id


 -------------------------------------------------------------------------------- Kereszttáblás lekérdezés(PIVOT/UNPIVOT) --------------------------------------------------------------------------------
use [northwind];
select * from northwind.dbo.weapons;
drop table if exists weapons

create table weapons(
	id int not null,
	name varchar(50),
	attribute varchar(50),
	value int
)

insert into weapons(id, name, attribute, value) values
	(1, 'Incinerator', 'Damage', 4000),
	(2, 'Twilight', 'Damage', 5000),
	(3, 'Kudzu', 'Damage', 3500),
	(4, 'Eternity', 'Damage', 5200),
	(5, 'Incinerator', 'Defense', 250),
	(6, 'Twilight', 'Defense', 150),
	(7, 'Kudzu', 'Defense', 50),
	(8, 'Eternity', 'Defense', 300)

select * from weapons

-- pivot by attribute (WITH kell hogy megmaradjon az unpivotnak)

select name, Damage, Defense
from (select name, attribute, value from weapons) as Original
pivot(max(value)
	for attribute in (Damage, Defense)
) as PivotTable

-- unpivot -hoz kell itt a pivot is mivel nem létezik ez a tábla
WITH PivotWeapons as (
	select name, Damage, Defense
from (select name, attribute, value from weapons) as Original
pivot(max(value)
	for attribute in (Damage, Defense)
) as PivotTable
)
-- unpivot
select name, attribute, value from PivotWeapons
unpivot (value for attribute in (Damage, Defense)) as UnpivotWeapons

 -------------------------------------------------------------------------------- Minta Zh PIVOT 1.feladat --------------------------------------------------------------------------------
 /*
 1. feladat
1A: Készítsen olyan SQL lekérdezést a Northwind adatbázisban, mely termék-kategóriánként (név) és évenként adja meg a 90 dollárnál drágább egységárú termékek rendelési tételeken
szereplő darabszámai összegét!

Segítség: A rendelési tételek az [order details] táblában találhatók. Egy tételen a rendelt termék darabszámát a tábla quantity nevű mezője mutatja. Az adatbázis sémáját lásd a jegyzet elején.

1B: Az előző lekérdezés eredménytábláját pivotálja az egyik alkalmasan választott mező
szerint.
*/

--1A
select c.CategoryName, year(os.OrderDate) as orderyear, sum(o.Quantity) as orderqty  from [Order Details] as o join Products p on o.ProductID = p.ProductID join Categories c on c.CategoryID = p.CategoryID
	join Orders as os on os.OrderID = o.OrderID
	where p.UnitPrice > 90
	group by c.CategoryName, year(os.OrderDate)
	order by c.CategoryName, orderyear

--1B
select [Beverages], [Meat/Poultry] from
(select c.CategoryName, year(os.OrderDate) as orderyear, sum(o.Quantity) as orderqty  from [Order Details] as o join Products p on o.ProductID = p.ProductID join Categories c on c.CategoryID = p.CategoryID
	join Orders as os on os.OrderID = o.OrderID
	where p.UnitPrice > 90
	group by c.CategoryName, year(os.OrderDate)
	) as originalQuery
pivot (
	max(orderqty) for CategoryName in ([Beverages], [Meat/Poultry])
)as PivotedTable

 -------------------------------------------------------------------------------- Adatbázis-programozás T-SQL nyelven --------------------------------------------------------------------------------

 --példaciklus és változók
 declare @i int, @eredm int
 set @i=1
 set @eredm=0

 while @i < 50 begin
	set @eredm = @eredm +@i
	set @i = @i+1
end

print 'az 50-nél kisebb számok összege: ' + cast(@eredm as varchar(15))
go

/* ÖNÁLLÓ FELADAT #4: írjunk egy scriptet, amely kiírja az 1000-nél kisebb Fibonacci-számokat! Segítség: az
első 5 szám az 1, 1, 2, 3, 5*/

declare @counter_1 int, @counter_2 int, @n int
set @counter_1 = 1
set @counter_2 = 1


print 'Fibonacci 1000 -ig'
print @counter_1
print @counter_2

while 1 = 1
begin
	set @n = @counter_1 + @counter_2
	if @n >= 1000
		break;

	print @n

	set @counter_1 = @counter_2
	set @counter_2 = @n
end

--PÉLDA: változók használata SQL-be ágyazva + feltételes elágazás. A keresett nevű dolgozó címének kiírása
use northwind
select * from Employees

declare @name nvarchar(20), @address nvarchar(max)
set @name = 'Fuller%' --ez egy last name
select @address=Country + ', ' + City + ' ' + Address
	from Employees where LastName like @name
if @address is not null print 'Megtalált cím: ' + @address

/* ÖNÁLLÓ FELADAT #5: írjunk egy scriptet, amely a kapott nevű termék termék-kategóriáját visszaírja */
use northwind
select p.ProductName, c.CategoryName from Products p join Categories c on c.CategoryID = p.CategoryID

declare @prod_name nvarchar(50), @prod_cat nvarchar(max)
set @prod_name = 'Aniseed%'
select @prod_cat=c.CategoryName
	from Categories c join Products p on p.CategoryID=c.CategoryID
	where p.ProductName like @prod_name
if @prod_cat is not null print 'Found category is ' + @prod_cat


-- Írassuk ki az összes alkalmazott nevét egyetlen listában!
declare @nev_lista nvarchar(max) = ''
select @nev_lista = @nev_lista +','+ LastName from Employees order by LastName
select 'A nevek listája: ' + right(@nev_lista, len(@nev_lista)-1) lista

