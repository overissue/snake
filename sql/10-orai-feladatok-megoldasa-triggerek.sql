--ÖNÁLLÓ FELADAT: egy termék rekord módosításakor másoljuk ki 
--egy products_log nevű táblába a
--módosult termék azonosítóját, nevét és raktárkészletét!
drop table products_log
go
create table products_log (prod_id int, 
	prod_name nvarchar(40), stock smallint,
	ts datetime)
go
drop trigger tr_prod_log
go
create trigger tr_prod_log on products after update as
begin
	insert products_log (prod_id, prod_name, stock, ts)
	select ProductID, ProductName, UnitsInStock, getdate() 
	from deleted
end
--teszt
select top 1 ProductID, ProductName, UnitsInStock from Products
update Products set UnitsInStock=39 where ProductID=1
select * from products_log
