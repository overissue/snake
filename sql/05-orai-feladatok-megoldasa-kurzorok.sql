/*************************************************************
ÖNÁLLÓ FELADAT (könnyű)
olyan script, amely az amerikai vásárlók (customers tábla, country mező) rekordjain 
iterál és kiírja minden vásárló nevét, és hogy eddig hány rendelése volt
*/

--MEGOLDÁS
declare @custid nchar(5), @custname nvarchar(40), @orders int
declare c cursor fast_forward for 
	select customerid, companyname
	from customers where country='USA' order by CompanyName
open c
fetch next from c into @custid, @custname
while @@FETCH_STATUS = 0 begin
	select @orders=COUNT(orderid) from orders where CustomerID=@custid
	print @custname + ': ' + cast(@orders as varchar(50)) + ' orders'
	fetch next from c into @custid, @custname	
end
close c deallocate c
-- a fenti ciklus egyenértékű ezzel az sql lekérdezéssel:
select companyname + ': ' + cast(COUNT(orderid) as varchar(50)) + ' orders'
from customers c inner join orders o on c.CustomerID=o.CustomerID
where c.country='USA'
group by c.CustomerID, c.CompanyName
order by CompanyName

--SZORGALMI FELADAT: egy beágyazott kurzorral írassuk ki az illető
--vásárló rendeléseiek a dátumait is 
--(leprogramozzuk az INNER JOIN műveletet)

--MEGOLDÁS
declare @custid nchar(5), @custname nvarchar(40), 
@orders int, @i int, @date date
declare c cursor fast_forward for 
	select customerid, companyname
	from customers where country='USA' order by CompanyName
open c
set @i=1
fetch next from c into @custid, @custname
while @@FETCH_STATUS = 0 begin
	select @orders=COUNT(orderid) from orders where CustomerID=@custid
	print cast(@i as varchar(50))+'. '+@custname + ': ' + 
					cast(@orders as varchar(50)) + ' orders'
	declare co cursor for select orderdate from orders where CustomerID=@custid
	open co
	fetch next from co into @date
	while @@FETCH_STATUS = 0 begin
		print '	'+cast(@date as varchar(50))
		fetch next from co into @date
	end
	set @i=@i+1
	close co deallocate co
	fetch next from c into @custid, @custname	
end
close c deallocate c


/*
ÖNÁLLÓ FELADAT #13
A feladat annak kiderítése, hogy a paraméterként kapott
ügynök

1) milyen átlagos gyakorisággal (napokban mérve) köt nagy értékű rendelést, illetve
2) hányszor fordult elo vele, hogy két kis értékű rendelése közvetlenül követte egymást

nagy értékűnek a 200 dollár feletti rendelések számítanak. Tehát ha pl. egy ügynök
rendeléseinek a dátumai az alábbiak:

2011. jan. 3. (820 $)
2011. jan. 4. (190 $)
2011. jan. 5. (11,200 $)
2011. jan. 10. (100 $)
2011. jan. 11. (140 $)
2011. jan. 20. (540 $)

akkor
1) 2+15=17 nap alatt 3 nagy értéku rendelés, tehát az átlag 5.7 nap
2) egyszer fordult elo, hogy egymás után két kisértéku rendelés jött

A megoldás lépései:

1. kurzor készítése az illetõ ügynök rendelési dátumaira és azok értékére
(korábbi anyagból kiollózható a lekérdezés), rendezés dátum szerint
2. a kurzor végigléptetése, a rendelés típusának mentése két rekord között egy változóba
3. tesztelés az Orders táblán

segítség:
select DATEDIFF(day, '2011-02-23', '2011-03-03') -- az eredmény 11, integer

Továbbfejlesztés (SZORGALMI FELADAT): próbáljuk ugyanezt elvégezni két egymásba ágyazott kurzorral (a külső
az ügynökökön lépked végig, a belső az illető rendelésein)

**************************************************************************/

--MEGOLDÁS
use northwind
go
declare @empid int 
set @empid=2 --debug: neki többször is van két kisértékű egymás után
declare @datum date, @elozo_datum date, @osszeg float, @elozo_osszeg float, @ket_kicsi_egymas_utan int
declare @osszes_nap int, @rendelések_szama int
declare c cursor fast_forward for 
	select o.orderdate, sum((1-discount)*unitprice*quantity)
	from orders o inner join [order details] d on o.orderid=d.orderid
	where EmployeeID = @empid
	group by o.orderid, o.orderdate
	order by o.orderdate

set @ket_kicsi_egymas_utan = 0
set @osszes_nap = 0
set @rendelések_szama = 0
open c
fetch next from c into @datum, @osszeg
while @@FETCH_STATUS = 0 begin
	if @elozo_datum is not null  --nem az elsõ rekord
		set @osszes_nap = @osszes_nap + DATEDIFF(DAY, @elozo_datum, @datum)
	if @osszeg >= 200
		set @rendelések_szama = @rendelések_szama + 1
	if @osszeg < 200 and @elozo_osszeg < 200 begin
		set @ket_kicsi_egymas_utan = @ket_kicsi_egymas_utan + 1
		print 'második kicsi: ' + cast(@osszeg as varchar(50))  --debug
		print @datum
	end
	set @elozo_datum = @datum
	set @elozo_osszeg = @osszeg
	fetch next from c into @datum, @osszeg
end
close c deallocate c
--print @rendelések_szama
--print @osszes_nap
print 'átlagos idõ két nagyértékû rendelés között: ' + 
			cast( @osszes_nap * 1.0 / (@rendelések_szama * 1.0) as varchar(50))
print 'hányszor jött két kis értékű rendelés egymás után: ' + 
			cast(@ket_kicsi_egymas_utan  as varchar(50))
go
--eredmény:
--7.63
--3
--tesztelés:
select o.orderdate, sum((1-discount)*unitprice*quantity)
from orders o inner join [order details] d on o.orderid=d.orderid
where EmployeeID = 2 
group by o.orderid, o.orderdate
having sum((1-discount)*unitprice*quantity) >= 200
--85 nagy értékû rendelés
select min(orderdate), max(orderdate) from Orders where EmployeeID=2
select datediff(day, '1996-07-25 00:00:00.000', '1998-05-05 00:00:00.000') --649
select 649.0/85.0  --7.63: OK
--Ez alapján a @rendelések_szama és a @osszes_nap értéke jó
--A @ket_kicsi_egymas_utan az idõsor végignézésével és a "második kicsi" kiíratásával ellenõrizhetõ