/*
�N�LL� FELADAT: 
K�sz�ts�k el �s t�lts�k fel a Products t�bla rekord-orient�lt v�ltozat�t, 
ha a t�rolt attrib�tumok a Productname, a Unitprice, a CategoryID �s a Discontinued
*/

--MEGOLD�S
insert attributes (attrib_id, attrib_name, attrib_type) values
	(4, 'Productname', 'text'), (5, 'Unitprice', 'money'), (6, 'Categoryid', 'text'), (7, 'Discontinued', 'bit')

create table product_record (
	product_id int not null, 
	attrib_id int not null references attributes (attrib_id), 
	attrib_value nvarchar(500)
	primary key (product_id, attrib_id))

--egy rekordb�l t�bb rekord lesz:
insert product_record (product_id, attrib_id, attrib_value)
select ProductID, 4, ProductName from northwind.dbo.Products where ProductName is not null
union
select ProductID, 5, cast(Unitprice as nvarchar(500)) from northwind.dbo.Products where Unitprice is not null
union
select ProductID, 6, cast(Categoryid as nvarchar(500)) from northwind.dbo.Products where Categoryid is not null
union
select ProductID, 7, cast(Discontinued as nvarchar(500)) from northwind.dbo.Products where Discontinued is not null

select * from product_record

--vissza-alak�t�s:
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

/*  MEGOLD�S V�GE ***/
