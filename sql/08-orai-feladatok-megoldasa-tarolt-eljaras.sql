--ÖNÁLLÓ FELADAT #20: írjunk egy tárolt eljárást, amely a kapott azonosítójú termék termék-kategóriáját visszaírja
--MEGOLDÁS

drop proc sp_prod_categ
go
create procedure sp_prod_categ @prod_id int as
begin
	declare @categ_name nvarchar(15)
	select @categ_name = c.categoryname
	from products p inner join categories c on p.categoryid=c.categoryid
	where p.ProductID=@prod_id	
	if @categ_name is not null print 'A talált kategória: ' + @categ_name
	else print 'Nem találtuk a kategóriát'
end 
go
--teszt
exec sp_prod_categ 3 --A talált kategória: Condiments

--ÖNÁLLÓ FELADAT #20a: írjunk egy tárolt eljárást, amely egy termékevet vár, 
--és ha pontosan egy termék illeszkedik erre a névre, akkor az illető termék termék-kategóriáját visszaírja. 
--Használjuk hozzá a 20. feladatban elkészített tárolt eljárást OUTPUT paraméterrel!
--MEGOLDÁS
go
create procedure sp_prod_categ_output @prod_id int, @categ_name nvarchar(15) output as
begin
	select @categ_name = c.categoryname
	from products p inner join categories c on p.categoryid=c.categoryid
	where p.ProductID=@prod_id	
end 
go
--drop procedure sp_prod_categ_2
create procedure sp_prod_categ_2 @prod_name nvarchar(40) as
begin
	declare @prod_id int, @categ_name nvarchar(15)
	if (select count(*) from Products where ProductName like @prod_name+'%') = 1
	begin
		select @prod_id=ProductID from Products where ProductName like @prod_name+'%'
		exec sp_prod_categ_output @prod_id, @categ_name output
		if @categ_name is not null print 'A talált kategória: ' + @categ_name
		else print 'Nem találtuk a kategóriát'
	end else print 'Nem találtuk a terméket vagy túl sok a találat.'
end 
go
--teszt
exec sp_prod_categ_2 'chai' --A talált kategória: Beverages
