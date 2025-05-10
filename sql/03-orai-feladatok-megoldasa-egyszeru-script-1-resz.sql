--ÖNÁLLÓ FELADAT: az 1000-nél kisebb Fibonacci-számok kiírása
--megoldás:
declare @i int, @j int, @temp int
set @i=1
print @i
set @j=1
print @j
while @i+@j<1000 begin
	set @temp=@j
    set @j=@j+@i
    set @i=@temp
	print @j
end

--ÖNÁLLÓ FELADAT: írjunk egy scriptet, amely a kapott nevű termék termék-kategóriáját visszaírja
--MEGOLDÁS
declare @name nvarchar(20), @categ_name nvarchar(100) = ''
set @name='bq%'
select @categ_name = c.categoryname
from products p inner join categories c on p.categoryid=c.categoryid
where p.productName like @name
if @categ_name is not null print 'A talált kategória: ' + @categ_name
else print 'Nem találtuk a kategóriát'

--ÖNÁLLÓ FELADAT: egészítsük ki az előző termékes scriptet a találati szám ellenőrzésével
--ellenőrizzük, hogy hány termék illeszkedik erre a névre
--MEGOLDÁS
go
set nocount on
declare @name nvarchar(20), @res_no int, @prod_id int, @categ_name nvarchar(100), @product_id int
set @name='Aniseed%'
select @res_no=count(*) from Products where ProductName like @name
if @res_no=0 print 'Nincs találat.'
else if @res_no>1 print 'Több, mint 1 találat.'
else begin  --épp egy találat
	select @categ_name = c.categoryname from products p inner join categories c on p.categoryid=c.categoryid
		where p.productName like @name
	if @categ_name is not null print 'A talált kategória: ' + @categ_name else print 'Ismeretlen kategórianév'
end
go