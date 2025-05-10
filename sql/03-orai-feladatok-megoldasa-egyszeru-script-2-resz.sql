--ÖNÁLLÓ FELADAT: írjunk egy scriptet, amely a kapott nevű termék (csak egyetlen termék)
--UnitsInStock mezőjének értékét növeli a UnitsOnOrder mező értékével, 
--a UnitsOnOrder mezőt pedig 0-ra állítja (mivel beérkezett a rendelés a beszállítótól)
--feladat- kiegészítések gyorsan haladóknak:
--	o	írjuk vissza az új raktárkészletet
--	o	ha a talált terméknek nem is volt függő rendelése, tehát UnitsOnOrder=0, 
--		akkor adjunk figyelmeztetést, és ne csináljunk semmit

--MEGOLDÁS
go
set nocount on
declare @name nvarchar(20), @res_no int, @prod_id int, @categ_name nvarchar(100),
@uj_keszlet int, @product_id int, @rendelve int
set @name='aniseed%'
select @res_no=count(*) from Products where ProductName like @name
if @res_no=0 print 'Nincs találat.'
else if @res_no>1 print 'Több, mint 1 találat.'
else begin  --épp egy találat
--unitsinstock aktualizálása (rendelés beérkezett)
--1. productid?
	select @categ_name=c.categoryname, @product_id=p.productid, 
	 @uj_keszlet = unitsinstock + unitsonorder, @rendelve=unitsonorder
	from products p inner join categories c on p.categoryid=c.categoryid
	where p.productName like @name
	print 'termék azonosítva (id: ' + cast(@product_id as varchar(10)) 
		+ ', kategória: ' + @categ_name + ')'
--2. update
	if @rendelve > 0 begin
		update products set unitsinstock = @uj_keszlet, unitsonorder=0 
			where productid=@product_id
		print 'készlet aktualizálva, új készlet: ' + cast(@uj_keszlet as varchar(10))
	end else print 'a terméknek nem volt függő beszállítói megrendelése '
end
go
--teszt: ProductID:3	ProductName: Aniseed Syrup
--az eredeti helyzet visszaállítása
update Products set UnitsInStock=13, UnitsOnOrder=70 where ProductID=3
--most futtassuk a scriptet, ellenőrizzük az új készletet
select * from Products where ProductID=3
go

--ÖNÁLLÓ FELADAT: írjunk egy scriptet, amely adott sorszámú rendelés tételei 
--alapján aktualizálja a Products.UnitsInStock mezőjének értékét! 
--Egyelőre ne foglalkozzunk azzal az esettel, mikor a rendelés meghaladja a raktárkészletet

--MEGOLDÁS
set nocount on
declare @order_id int = 10248
update Products set UnitsInStock = UnitsInStock - od.Quantity 
from [Order Details] od inner join Products p on p.ProductID=od.ProductID
where od.OrderID=@order_id
go
