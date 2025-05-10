--ÖNÁLLÓ FELADAT
/*programozott tranzakció:
paraméterek: termék neve, kategória ID
1. új termék beszúrása
2. annak ellenőrzése, hogy a kapott kategóriában nincs-e már 10-nél több termék
3. ha van, visszagörgetjük a tranzakciót
4. ha nincs, az újonnan felvett termék raktárkészletét beállítjuk 100-ra
5. commit
*/

--MEGOLDÁS
go
declare @prod_id int, @prod_name nvarchar(40)='Rákbefőtt', @cat_id int=1
begin tran
insert Products (ProductName, CategoryID, Discontinued) 
	values (@prod_name, @cat_id, 0)
set @prod_id=@@IDENTITY
--print @prod_id
if (select COUNT(*) from Products where CategoryID=@cat_id) > 10 begin
	rollback tran
	print 'Visszagörgetve'
end else begin
	update Products set UnitsInStock=100 where ProductID=@prod_id
	commit tran
	print 'Végrehajtva'
end 
go

--script futtatása mindkét ágon
select * from Products where ProductName='Rákbefőtt'
delete Products where ProductID=79
select COUNT(*) from products where CategoryID=1 --12

