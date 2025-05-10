/*
ÖNÁLLÓ FELADAT: 
Készítsük el és töltsük fel a Products tábla rekord-orientált változatát, 
ha a tárolt attribútumok a Productname, a Unitprice, a CategoryID és a Discontinued
*/

--MEGOLDÁS
insert attributes (attrib_id, attrib_name, attrib_type) values
	(4, 'Productname', 'text'), (5, 'Unitprice', 'money'), (6, 'Categoryid', 'text'), (7, 'Discontinued', 'bit')

create table product_record (
	product_id int not null, 
	attrib_id int not null references attributes (attrib_id), 
	attrib_value nvarchar(500)
	primary key (product_id, attrib_id))

--egy rekordból több rekord lesz:
insert product_record (product_id, attrib_id, attrib_value)
select ProductID, 4, ProductName from northwind.dbo.Products where ProductName is not null
union
select ProductID, 5, cast(Unitprice as nvarchar(500)) from northwind.dbo.Products where Unitprice is not null
union
select ProductID, 6, cast(Categoryid as nvarchar(500)) from northwind.dbo.Products where Categoryid is not null
union
select ProductID, 7, cast(Discontinued as nvarchar(500)) from northwind.dbo.Products where Discontinued is not null

select * from product_record

--vissza-alakítás:
select product_ID,
	min(case 
		when attrib_id=4 then attrib_value else null end) 
				as productname,
	min(case 
		when attrib_id=5 then cast(attrib_value as money) else null end) 
				as unitprice,
	min(case 
		when attrib_id=6 then cast(attrib_value as int) else null end) 
				as category_id
from product_record group by product_id

/*  MEGOLDÁS VÉGE ***/
