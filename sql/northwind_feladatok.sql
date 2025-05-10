use [northwind]

select employeeid, lastname, title, city
    into employee_field from northwind.dbo.Employees;

select * from employee_field;

create table Attributes(
    attrib_id int primary key,
    attrib_name nvarchar(100), -- nvarchar -> Unicode karaktereket tárol
    attrib_type nvarchar(100) -- akkor ajánlott, ha különböző nyelvek és karakterkészletek támogatására van szükség.
)
GO

insert into attributes(attrib_id, attrib_name, attrib_type) 
    values(1, 'Last name', 'text'), (2, 'Title', 'text'), (3, 'City', 'text')
select * from attributes

create table employee_record(
    emp_id int not null,
    attrib_id int not null references attributes(attrib_id),
    attrib_value nvarchar(500)
    primary key (emp_id, attrib_id)
)

--a feladat az employee_field tartalmának reprodukálása az employee_record táblában
--egy rekordból több rekord lesz:
select * from employee_field

insert into employee_record(emp_id, attrib_id, attrib_value)
    select employeeid, 1, lastname from employee_field where lastname is not null
    union
    select employeeid, 2, title from employee_field where title is not null
    union
    select employeeid, 3, city from employee_field where city is not null

--ellenőrzés: NULL rekord nincsenek benne
select * from employee_record

--a kliens GUI számára fontosak a mezőnevek, típusok is, joinolva kell lekérdezni típusokkal:
select e.emp_id, a.attrib_id, a.attrib_type, e.attrib_value
    from employee_record e inner join attributes a on e.attrib_id=a.attrib_id

--szebb formában való lekérdezés, összegezve employeenként
select emp_id as employeeid, 
    min(case 
    when attrib_id=1 then attrib_value else null 
    end) as lastname,
    
    min(case
    when attrib_id=2 then attrib_value else null 
    end) as title,

    min(case
    when attrib_id=3 then attrib_value else null
    end) as city
from employee_record group by emp_id

-- önálló feladat #1: Készítsük el és töltsük fel a Products tábla rekord-orientált változatát, ha
-- a tárolt attribútumok a Proiductname, a Unitprice és a Discontinued

select ProductID, ProductName, UnitPrice, Discontinued into product_field from northwind.dbo.Products

insert Attributes(attrib_id, attrib_name, attrib_type)
    values(4, 'Product name', 'text'),(5, 'Unit price', 'text'),(6, 'Discontinued', 'boolean')

create table product_record (
    prod_id int  not null,
    attrib_id int not null references attributes (attrib_id),
    attrib_value nvarchar(500),
    primary key (prod_id, attrib_id)
)

insert product_record(prod_id, attrib_id, attrib_value)
    select ProductID, 4, ProductName from product_field where ProductName is not null
    union
    select ProductID, 5, cast(UnitPrice as nvarchar(500)) from product_field where UnitPrice is not null
    union
    select ProductID, 6, cast(Discontinued as nvarchar(500)) from product_field where Discontinued is not null