
--rekord-orientált modell
select * into employees from northwind.dbo.Employees
select * from employees
--drop table employee_field
select employeeid, lastname, title, city into employee_field from northwind.dbo.Employees
select * from employee_field
create table attributes (
	attrib_id int primary key, 
	attrib_name nvarchar(100), 
	attrib_type nvarchar(100))
go
insert attributes (attrib_id, attrib_name, attrib_type) values
	(1, 'Last name', 'text'), (2, 'Title', 'text'), (3, 'City', 'text')
--drop table employee_record 
create table employee_record (
	emp_id int not null, 
	attrib_id int not null references attributes (attrib_id), 
	attrib_value nvarchar(500)
	primary key (emp_id, attrib_id))

--a feladat az employee_field tartalmának reprodukálása az employee_record táblában
--egy rekordból több rekord lesz:
insert employee_record (emp_id, attrib_id, attrib_value)
select employeeid, 1, lastname from employee_field where lastname is not null
union
select employeeid, 2, title from employee_field where title is not null
union
select employeeid, 3, city from employee_field where city is not null

--ellenőrzés: Lamer NULL rekordjai ugye nincsenek benne
select * from employee_record
--a kliens GUI számára fontosak a mezőnevek, típusok is:
select e.emp_id, a.attrib_name, a.attrib_type, e.attrib_value 
from employee_record e inner join attributes a on e.attrib_id=a.attrib_id

--most alakítsuk vissza: több rekordból lesz egy rekord
select emp_id as employeeid,
min(case --MIN helyén lehetne MAX is, mert csak egy rekordot dolgoz fel
		when attrib_id=1 then attrib_value
		else null
	end)  as lastname,
min(case 
		when attrib_id=2 then attrib_value
		else null
	end)  as title,
min(case 
		when attrib_id=3 then attrib_value
		else null
	end)  as city
from employee_record group by emp_id
--megkaptuk az employee_field tartalmát

/*
ÖNÁLLÓ FELADAT: 
Készítsük el és töltsük fel a Products tábla rekord-orientált változatát, 
ha a tárolt attribútumok a Productname, a Unitprice és a Discontinued
*/

--PIVOT
drop table csapat
CREATE TABLE [dbo].[csapat] (
    [csapat_id] [int] NOT NULL primary key,
    [csapat_nev] [nvarchar] (50) NOT NULL
)
drop table gyumolcs
CREATE TABLE [dbo].[gyumolcs] (
    [gyumolcs_id] [int] NOT NULL primary key,
    [gyumolcs_nev] [nvarchar] (50) NOT NULL
)
drop table nap
CREATE TABLE [dbo].[nap] (
    [nap_id] [int] NOT NULL primary key,
    [nap_nev] [nvarchar] (50) NOT NULL
)
go
drop table eredm
CREATE TABLE [dbo].[eredm] (
	eredm_id int identity (1,1) primary key,
    [csapat_id] [int] NOT NULL references csapat (csapat_id),
    [nap_id] [int] NOT NULL  references nap (nap_id),
	gyumolcs_id int not null  references gyumolcs (gyumolcs_id),
    [leadott_lada] [int] NOT NULL
)
insert csapat (csapat_id, csapat_nev) values (1, 'Szorgos'),(2, 'Lusta')
insert gyumolcs (gyumolcs_id, gyumolcs_nev) values (1, 'alma'),(2, 'szilva')
insert nap (nap_id, nap_nev) values (1, 'hétfő'),(2, 'kedd'),(3, 'szerda')
insert eredm (csapat_id, nap_id, gyumolcs_id, leadott_lada) values
	(1,1,1,50), (1,2,1,60), (1,3,1,70), (1,1,2,100), (1,2,2,120), (1,3,2,140),
	(2,1,1,5), (2,2,1,6), (2,3,1,7), (2,1,2,10), (2,2,2,12), (2,3,2,14)
select * from eredm
--kérdés pl. a csapatok teljesítménye naponta
select cs.csapat_nev, n.nap_nev, sum(leadott_lada) as teljesítmény
from eredm e inner join csapat cs on cs.csapat_id=e.csapat_id
inner join nap n on n.nap_id=e.nap_id
inner join gyumolcs gy on gy.gyumolcs_id=e.gyumolcs_id --elhagyható
group by cs.csapat_id, cs.csapat_nev, n.nap_id, n.nap_nev
order by cs.csapat_nev, n.nap_nev

--csapatok teljesítménye gyümölcsönként
select cs.csapat_nev, gy.gyumolcs_nev, sum(leadott_lada) as teljesítmény
from eredm e inner join csapat cs on cs.csapat_id=e.csapat_id
inner join nap n on n.nap_id=e.nap_id --elhagyható
inner join gyumolcs gy on gy.gyumolcs_id=e.gyumolcs_id 
group by cs.csapat_id, cs.csapat_nev, gy.gyumolcs_id, gy.gyumolcs_nev
order by cs.csapat_nev, gy.gyumolcs_nev

--ládaszám gyümölcsönként
select gy.gyumolcs_nev, sum(leadott_lada) as teljesítmény
from eredm e 
inner join csapat cs on cs.csapat_id=e.csapat_id --elhagyható
inner join nap n on n.nap_id=e.nap_id --elhagyható
inner join gyumolcs gy on gy.gyumolcs_id=e.gyumolcs_id
group by gy.gyumolcs_id, gy.gyumolcs_nev
order by gy.gyumolcs_nev

--Tf. a nevek egyediek (unique) vagy azzá tehetők
--ekkor a PIVOT denormalizált kiinduló táblája:
drop table eredm_pivot
select cs.csapat_nev, n.nap_nev, gy.gyumolcs_nev, e.leadott_lada
into eredm_pivot
from eredm e 
inner join csapat cs on cs.csapat_id=e.csapat_id 
inner join nap n on n.nap_id=e.nap_id
inner join gyumolcs gy on gy.gyumolcs_id=e.gyumolcs_id
go
select * from eredm_pivot where csapat_nev='lusta'
--csapatok teljesítménye gyümölcsönként: sorokban a csapatok, oszlopokban a gyümölcsök
select pt.csapat_nev, pt.alma, pt.szilva
from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
		from eredm_pivot group by csapat_nev, gyumolcs_nev) as forras --az alias szintaktikai okból kell
	pivot (sum(leadott_lada) for gyumolcs_nev in ([alma], [szilva])) as pt

--sorokban a gyümölcsök, oszlopokban a csapatok
select gyumolcs_nev, pt.Lusta, pt.Szorgos
from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
		from eredm_pivot group by csapat_nev, gyumolcs_nev) as forras 
	pivot (sum(leadott_lada) for csapat_nev in ([Lusta], [Szorgos])) as pt

--a sorokban lehet több szintű bontás is: sorokban a csapatok és napok, oszlopokban a gyümölcsök 
select csapat_nev, nap_nev, pt.alma, pt.szilva
from (select csapat_nev, nap_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
		from eredm_pivot group by csapat_nev, nap_nev, gyumolcs_nev) as forras 
	pivot (sum(leadott_lada) for gyumolcs_nev in ([alma], [szilva])) as pt
order by csapat_nev, nap_nev

--vegyük észre, hogy a fenti forras tábla ugyanaz, mint: 
--"select csapat_nev, nap_nev, gyumolcs_nev, leadott_lada from eredm_pivot"
--tehát a teljes kulcs szerint csoportosítunk -> megkapjuk az eredeti táblát
--ezért ugyanaz egyszerűbben:

select csapat_nev, nap_nev, pt.alma, pt.szilva
from eredm_pivot 
	pivot (sum(leadott_lada) for gyumolcs_nev in ([alma], [szilva])) as pt
order by csapat_nev, nap_nev

/*
ÖNÁLLÓ FELADAT: 
•	Legyenek sorokban a napok, oszlopokban a csapatok */

/*
ÖNÁLLÓ FELADAT: 
•	Legyen most fordítva, és a napok közül hagyjuk ki a szerdát */
/*
•	Legyenek sorokban a napok és a gyümölcsök, oszlopokban a csapatok
*/

--UNPIVOT
--visszacsináljuk az előző átalakítást:
select csapat_nev, pt.alma, pt.szilva
into #temp
from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
		from eredm_pivot group by csapat_nev, gyumolcs_nev) as forras 
	pivot (sum(leadott_lada) for gyumolcs_nev in ([alma], [szilva])) as pt

--a megoldás:
select * from #temp
select csapat_nev, gyumolcs_nev, leadott_lada
from (select csapat_nev, alma, szilva from #temp) as forras 
	unpivot (leadott_lada for gyumolcs_nev in (alma, szilva)) as upt
--persze a csoportosítást már nem tudjuk visszacsinálni, ott információ veszett el

--ha nem volt csoportosítás, akkor a tábla teljesen visszaalakítható:
drop table #temp
go
select csapat_nev, nap_nev, pt.alma, pt.szilva
into #temp
from eredm_pivot 
	pivot (sum(leadott_lada) for gyumolcs_nev in ([alma], [szilva])) as pt
order by csapat_nev, nap_nev

select csapat_nev, nap_nev, gyumolcs_nev, leadott_lada
from #temp 
	unpivot (leadott_lada for gyumolcs_nev in (alma, szilva)) as upt
order by csapat_nev, nap_nev, gyumolcs_nev


/*
ÖNÁLLÓ FELADAT: 
•	visszaalakítás a "sorokban a napok és a gyümölcsök, oszlopokban a csapatok" alakból
*/


--a dolgozós rekordorientált modell visszaírása mezőorientáltra PIVOT segítségével
--Mi a mezőnév-készlet?
select distinct a.attrib_name
from employee_record e inner join attributes a on e.attrib_id=a.attrib_id 
--eredmény:
[City]
[Last name]
[Title]
--ezzel a megoldás:
select emp_id, pt.[City], pt.[Last name], pt.[Title]
from (
	select e.emp_id, a.attrib_name, e.attrib_value 
	from employee_record e inner join attributes a on e.attrib_id=a.attrib_id) as forras
pivot (max(attrib_value) for attrib_name in ([City],[Last name],[Title])) as pt
--max helyett lehetne min is

/**************************
SQL utasításkötegek (batch)
***************************/

--demo: kötegtulajdonságok
--drop table pelda
create table pelda (szam int)
insert pelda values (44)
go
--1. kísérlet
update pelda set szam=21
go
selec * from pelda --szintaktikai hiba
go
select * from pelda --eredmeny 21, mert az első batch sikerult
go
--2. kísérlet: ugyanez egy kötegben
update pelda set szam=22
selec * from pelda --szintaktikai hiba
update pelda set szam=23
go
select * from pelda --eredmény: 21
--mert szintaktikai hiba esetén az egész batchból semmi sem hajtódik végre
--3. kísérlet
--ha az objektumnév hibás (nem szintaktikai hiba), akkor a hiba előtti rész végrehajtódik
go
update pelda set szam=22
select * from plda --Invalid object name
update pelda set szam=23 --ez már nem hajtódik végre
go
select * from pelda --eredmény: 22
go
--4. kísérlet: speciális hibák (nullával osztás, külső kulcs kényszer)
update pelda set szam=23
select 1/0 --division by zero
update pelda set szam=24 --végrehajtódik 
go
select * from pelda --eredmény: 24
go
update pelda set szam=25
delete employees --The DELETE statement conflicted with the REFERENCE constraint
update pelda set szam=26 --végrehajtódik
go
select * from pelda --eredmény: 26

/**************************
A T-SQL procedurális elemei
***************************/
--változók használata: SQL nélkül
declare @i int, @eredm int
set @i = 1
--ehelyett működne ez is: declare @i int = 1, @eredm int = 0
set @eredm=0
--azonos eredményt ad: select @eredm=0
while @i < 50 begin
    set @eredm = @eredm + @i
    set @i = @i + 1
end
print 'az 50-nél kisebb számok összege: '+cast(@eredm as varchar(15))
go

--print @eredm --Must declare the scalar variable "@eredm".
--a változó csak a kötegen belül látható


--ÖNÁLLÓ FELADAT: az 1000-nél kisebb Fibonacci-számok kiírása

--változók használata SQL-be ágyazva + feltételes elágazás
--A keresett nevű dolgozó címének kiírása
use northwind
--select * from Employees
declare @name nvarchar(20), @address nvarchar(max)
set @name='Fuller%'
--set @name='King%'
select @address=Country+', '+City+' '+Address
from Employees where LastName like @name
if @address is not null print 'A talált cím: ' + @address
/*megjegyzés: az utolsó sor működik. de jobban olvasható így:
if (@address is not null) begin
	print 'A talált cím:' + @address
end
*/
go

--ÖNÁLLÓ FELADAT: írjunk egy scriptet, amely a kapott nevű termék termék-kategóriáját visszaírja

--Figyelem: ha a fenti példát King paraméterrel futtatjuk, furcsa eredményt kapunk
--ugyanis 2 King van, és a másodikat találjuk meg
select * from Employees where LastName like 'King%'
--PÉLDA: az előző script javítva a találati szám ellenőrzésével
go
declare @name nvarchar(20), @address nvarchar(max), @res_no int
set @name='King%'
select @res_no=count(*) from Employees where LastName like @name
--Figyelem, ebben az esetben üres recordsetre a @res_no értéke nem NULL, hanem 0 lesz! 
if @res_no = 0 print 'Nincs találat.'
else if @res_no > 1 print 'Több, mint 1 találat.'
else begin
	select @address=Country+', '+City+' '+Address from Employees where LastName like @name
	print 'A talált cím: ' + @address
end
go
--megjegyzés: mivel csak 1 rekordot várunk, a 2. select megúszható lett volna így:
declare @name nvarchar(20), @address nvarchar(max), @res_no int
set @name='Buchanan%'
select @res_no=count(*), @address=max(Country+', '+City+' '+Address) 
	from Employees where LastName like @name
if @res_no=0 print 'Nincs találat.'
else if @res_no>1 print 'Több, mint 1 találat.'
else print 'A talált cím: ' + @address
go

--ÖNÁLLÓ FELADAT: egészítsük ki az előző termékes scriptet a találati szám ellenőrzésével
--ellenőrizzük, hogy hány termék illeszkedik erre a névre

--PÉLDA: Ha a változó mindkét oldalon szerepel, akkor alkalmas arra is, hogy minden rekord értékét tárolja.
--Írassuk ki az összes alkalmazott nevét egyetlen listában:
declare @nev_lista nvarchar(max)
set @nev_lista=''
select @nev_lista = @nev_lista + ', '+ LastName from Employees
print 'A nevek listája: ' +  right(@nev_lista, len(@nev_lista)-2) 

--a változók az egyéb DML utasításokba is beépülnek
--PÉLDA: emeljük meg a megtalált dolgozó egyenlegét 10%-kal
--a saját adatbázisunkban dolgozzunk!
set nocount on
declare @name nvarchar(20), @address nvarchar(max), @res_no int, @emp_id int
set @name='Fuller%'
select @res_no=count(*) from Employees where LastName like @name
if @res_no=0 print 'Nincs találat.'
else if @res_no>1 print 'Több, mint 1 találat.'
else begin  --épp egy találat
	select @address=Country+', '+City+' '+Address, @emp_id=EmployeeID 
		from Employees where LastName like @name
	print 'Dolgozó ID: ' + cast(@emp_id as varchar(10)) + ', cím: ' + @address
	update Employees set salary=1.1*salary where EmployeeID=@emp_id
	print 'Egyenleg növelve.'
end
go

--ÖNÁLLÓ FELADAT: írjunk egy scriptet, amely a kapott nevű termék (csak egyetlen termék)
--UnitsInStock mezőjének értékét növeli a UnitsOnOrder mező értékével, 
--a UnitsOnOrder mezőt pedig 0-ra állítja (mivel beérkezett a rendelés a beszállítótól)
--feladat- kiegészítések gyorsan haladóknak:
--	o	írjuk vissza az új raktárkészletet
--	o	ha a talált terméknek nem is volt függő rendelése, tehát UnitsOnOrder=0, 
--		akkor adjunk figyelmeztetést, és ne csináljunk semmit


--ÖNÁLLÓ FELADAT: írjunk egy scriptet, amely adott sorszámú rendelés tételei 
--alapján aktualizálja a Products.UnitsInStock mezőjének értékét! 
--Egyelőre ne foglalkozzunk azzal az esettel, mikor a rendelés meghaladja a raktárkészletet

--hibakezelés
select 1/0
print @@ERROR
go
select 1/0
if @@ERROR=8134 print '0-val osztottunk'
go

--TRY/CATCH
create table #log(time_stamp datetime, err_num int)
go
begin try
    update Products set UnitsInStock=-13 where ProductID=3 --check constraint sértés
	select 1/0 --ide már nem jut el
end try
begin catch
    select
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage
    insert #log (time_stamp, err_num) values (getdate(), ERROR_NUMBER())
end catch
select * from #log
go

/*
ÖNÁLLÓ FELADAT: 
Az alábbi scriptet, mely a Products.UnitsInStock mezőjének értékét aktualizálja, 
egészítsük ki hibakezeléssel!  (Az új értéknek nagyobbnak kell lennie 0-nál.)
*/

select * from [Order Details] where OrderID=10248 --11: 42, 42: 40, 72:40
select ProductID, UnitsInStock from Products where ProductID in (11, 42, 72) --82, 20, 20
--az utolsó 2 tétel miatt az alábbi update hibára fut (nem lehet negatív raktárkészlet)
go
declare @order_id int = 10248
update Products set UnitsInStock=UnitsInStock-od.Quantity 
from [Order Details] od inner join Products p on p.ProductID=od.ProductID
where od.OrderID=@order_id
print cast(@order_id as varchar(20))+' számú rendelés a raktárba átvezetve.'--hibás üzenet
go

--PÉLDA ÜZLETI FOLYAMATRA: egy telefonon kapott Northwind rendelést vigyünk végig!
--a szükséges táblák: products, customers, orders, order details
--ezekről készítsünk másolatot a saját adatbázisunkba

--változók
set nocount on
declare @prod_name varchar(20), @quantity int, @cust_id nchar(5) --a telefonból (a vevő-ID szöveges)
declare @status_message nvarchar(100),  @status int --a folyamat visszatérési értéke
declare @res_no int --találatok száma
declare @prod_id int, @order_id int --azonosítók
declare @stock int --raktárkészlet 
declare @cust_balance money --a vevő egyenlege
declare @unitprice money --a termék egységára

-- paraméterek
set @prod_name = 'boston'
set @quantity = 10
set @cust_id = 'AROUT'

begin try
	select @res_no = count(*) from products where productname like '%' + @prod_name + '%'
	if @res_no <> 1 begin
		set @status = 1
		set @status_message = 'HIBA: a terméknév nem egyértelmű.';
	end else begin
		-- ha egy terméket találunk, megkeressük a kulcsot és a raktárkészletet
		select @prod_id = productID, @stock = unitsInStock from products where productName like '%' + @prod_name + '%'
		-- van-e raktáron? a rendelt mennyiség elérheto-e?
		if @stock < @quantity begin
			set @status = 2
			set @status_message = 'HIBA: a raktárkészlet nem fedezi a megrendelést.'
		end else begin
		-- mennyibe kerül? Van elég pénze a vevönek?
			select @cust_balance = balance from customers where customerid = @cust_id
						--ha nem találjuk a vásárlót, akkor az egyenleg null 
						--mivel kulcsra keresünk, max. 1 találat lehet
			select @unitprice = unitPrice from products where productID = @prod_id --nincs discount
			if @cust_balance < @quantity*@unitprice or @cust_balance is null begin 
				set @status = 3
				set @status_message = 'HIBA: a vásárló nem található vagy az egyenlege túl alacsony.'
			end else begin 
		-- Ellenőrzések vége, elkezdjük a tranzakciót (2 lépés)
		-- 1. vásárló egyenlegének frissítése
    			update customers set balance = balance-(@quantity*@unitprice) where customerid=@cust_id
		-- 2. új bejegyzés az Orders, Order Details táblákba
				insert into orders (customerID, orderdate) values (@cust_id, getdate()) --orderid: identity
				set @order_id = @@identity  --az utolsó identity insert eredménye
				insert [order details] (orderid, productid, quantity, UnitPrice) --itt a hiba
					values(@order_id, @prod_id, @quantity, @unitprice) --itt a hiba
--				insert [order details] (orderid, productid, quantity, UnitPrice, Discount) --ez a jó
--					values(@order_id, @prod_id, @quantity, @unitprice, 0) --ez a jó
				set @status = 0
				set @status_message = cast(@order_id as varchar(20)) + ' sz. rendelés sikeresen felvéve.'
			end
		end
	end
	print @status
	print @status_message	
end try 
begin catch
	print 'EGYÉB HIBA: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
end catch
go

--teszteléshez beállítjuk a paramétereket
set nocount off
update products set unitsInStock = 900 where productid=40
update customers set balance=1000 where CustomerID='AROUT'
delete [Order Details] where OrderID in (select orderid from Orders where CustomerID='AROUT' and EmployeeID is null)
delete Orders where CustomerID='AROUT' and EmployeeID is null
--most futtatjuk a scriptet, utána ellenőrzés:
select * from Customers where CustomerID='AROUT'
select * from Products where productid=40
select top 3 * from Orders where CustomerID='arout' order by OrderDate desc

--tehát elvileg minden rendben. Azonban a discount mező NOT NULL kényszere miatt a futtatás után:
--"EGYÉB HIBA: Cannot insert the value NULL into column 'Discount'"
--DE! a vásárló egyenlegét azért sikerült csökkenteni!

--további hibalehetőség: ha egyszerre több konkurens kérés érkezik, akkor
--érdekes hibák léphetnek fel.

--javítás után teszteljük a másik két ágat is!

/*
ÖNÁLLÓ FELADAT: Raktárkészlet-karbantartó script 

Az eljárást a raktáros használja arra, hogy egy
létezo termék raktárkészletét növelje, vagy egy új cikket vegyen fel
a raktárba.

bemenő paraméterek:
set @termeknev = 'Raclette'
set @mennyiseg = 12
set @szallito = 'Formago Company'

A script '%raclette%'-re illo terméknevet keres a Products táblában.
Ha több, mint 1 találat van, hibaüzenettel kilép.
Ha 1 találat van, akkor annak a raktárkészletét (unitsinstock) növeli
12-vel.
Ha nincs találat, akkor felvesz egy új Raclette nevu terméket, melynek a
szállítóját (supplier) a 3. paraméter alapján próbálja beállítani,
a fentihez hasonló logikával (több találat: hiba, 1 találat: megvan,
0 találat: új supplier felvétele)

1. lépés: olyan lekérdezés, amely visszaadja a mintára illeszkedo rekordok számát
2. lépés: beszúró INSERT illetve módosító UPDATE utasítás összerakása
3. lépés: a lekérdezések beágyazása egy IF feltételt használó script-be
4. lépés: a script tesztelése 
*/


/****************************************************************************/
-- KURZOROK

-- a kurzor fogalma
-- szintaxis és egy egyszerű példa:
go
declare @emp_id int, @emp_name nvarchar(50), @i int, @address nvarchar(60)
declare cursor_emp cursor for
    select employeeid, lastname, address from employees order by lastname
set @i=1
open cursor_emp
fetch next from cursor_emp into @emp_id, @emp_name, @address
while @@fetch_status = 0
begin
    print cast(@i as varchar(5)) + '. ügynök:'
    print 'ID: ' + cast(@emp_id as varchar(5)) + ', Név: ' + @emp_name + ', cím: ' + @address
    set @i=@i+1
    fetch next from cursor_emp into @emp_id, @emp_name, @address
end
close cursor_emp
deallocate cursor_emp
go
--ez egyenértékű egy ilyen SELECT utasítással:
select 'ID: ' + cast(employeeid as varchar(5)) + isnull(', Név: ' + lastname, '') + isnull( ', cím: ' + address, '')
from employees order by lastname
--illetve ha az ügynök sorszámát is szeretnénk:
select cast(row_number() over(order by lastname) as varchar(50))+ 
'. ügynök: ID: ' + cast(employeeid as varchar(5)) + isnull(', Név: ' + lastname, '') + isnull( ', cím: ' + address, '')
from employees 

--tehát ehhez még nem kellett volna kurzor

/*************************************************************
ÖNÁLLÓ FELADAT (könnyű)
olyan script, amely az amerikai vásárlók (customers tábla, country mező) rekordjain 
iterál és kiírja minden vásárló nevét, és hogy eddig hány rendelése volt
*/

--SZORGALMI FELADAT: egy beágyazott kurzorral írassuk ki az illető
--vásárló rendeléseiek a dátumait is 
--(leprogramozzuk az INNER JOIN műveletet)

--Másik példa kurzorra: a korábbi mezõ-orientált -> rekord-orientált átalakítás 
use northwind
select  * from employees
go
declare @emp_id int, @emp_name nvarchar(50), @i int, @address nvarchar(60),
    @city nvarchar(50)
create table #eredm (adatid int, dolg_id int,
        adatnev varchar(50), adatertek nvarchar(100))
declare cursor1 cursor fast_forward
    for
    select employeeid as emp_id, firstname+' '+lastname as emp_name,address, city
    from employees
set @i=0
open cursor1
fetch next from cursor1 into @emp_id, @emp_name, @address, @city
while @@fetch_status = 0
begin
    --print @emp_id print @emp_name print @i
    if @emp_name is not null begin
        insert #eredm values(@i, @emp_id, 'dolgozo_neve', @emp_name)
        set @i=@i+1
    end
    if @address is not null begin
        insert #eredm values(@i, @emp_id, 'dolgozo_cime', @address)
        set @i=@i+1
    end
    if @city is not null  begin
        insert #eredm values(@i, @emp_id, 'dolgozo_varosa', @city)
        set @i=@i+1
    end
    fetch next from cursor1 into @emp_id, @emp_name, @address, @city
    --print @emp_id
end
close cursor1
deallocate cursor1
print 'feldolgozás vége'
select * from #eredm
drop table #eredm
GO
/*
ÖNÁLLÓ FELADAT 
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

Továbbfejlesztés (SZORGALMI FELADAT): legyen ez egy tárolt eljárásban, és hívjuk meg sorban minden ügynökre!
Vagy próbáljuk ugyanezt elvégezni két egymásba ágyazott kurzorral (a külső
az ügynökökön lépked végig, a belső az illető rendelésein)

**************************************************************************/


--kurzor-típusok, érdekességek
--példa dinamikus, mozgatható kurzorra 
go
declare c cursor global dynamic scroll for 
	select LastName from Employees 
print @@cursor_rows --eredm: 0, nincs nyitott kurzor
open c
print @@cursor_rows --eredm: -1, mivel dinamikus, nem megállapítható a sorok száma
--de ha volna egy order by LastName a forráson, a rendezéshez létrehozná a táblát, 
--és a cursor_rows is 10 értéket adna vissza 
declare @name varchar(50)
fetch last from c into @name  --fetch absolute nem lehet dinamikus kurzoron 
print @name --Lamer
close c 
deallocate c
--példa statikus kurzorra
go 
declare c cursor global static scroll for 
	select LastName from Employees 
open c
print @@cursor_rows --10
declare @name varchar(50)
fetch absolute 2 from c into @name
print @name --Fuller (rendezés nélkül)
close c 
deallocate c





/******************************************************************************/
--analitikus függvények

--az balakozó függvények/OVER használatával a két kicsi is meghatározható kurzor nélkül:
go
drop table #tmp --az átláthatóság érdekében használjunk egy ideiglenes táblát
go
select orderdate, cast(sum((1-discount)*unitprice*quantity) as money) as value
into #tmp from orders o inner join [order details] d on o.orderid=d.orderid
where EmployeeID = 2 
group by o.orderid, o.orderdate --96
order by OrderDate 
go
select * from #tmp order by OrderDate

select orderdate, max(value) over 
	(order by orderdate rows between 1 preceding and current row) as maxi-- maxi: a rendelés és az előző rendelés közül a nagyobbik érték
from #tmp 

--ahol ebben a listában 200 alatti érték van, ott 2 kicsi jött egymás után:
select a.OrderDate, a.maxi
from (
	select orderdate, max(value) over 
		(order by orderdate rows between 1 preceding and current row) as maxi
	from #tmp 
) as a where a.maxi < 200  --3

--vigyáznunk kell, mert a lista elején tévesen emelnénk ki a rekordot, ha már az első is kis értékű 
--helyesen:

select a.OrderDate, a.maxi
from (
	select orderdate, max(value) over 
		(order by orderdate rows between 1 preceding and current row) as maxi,
	row_number() over 
		(order by orderdate) as sorsz 
	from #tmp 
) as a where a.maxi < 200  and sorsz > 4 --3


--ÖNÁLLÓ FELADAT #16: módosítsuk a fenti példa lekérdezését úgy, hogy az egymás után következő 5 nagy értékű rendelést keressük

--partíciónként vagy mozgó rekord-környzetben számított értékek
--gördülő összeg, sorszám stb. évente 
select year(orderdate) ev, 
	row_number() over (
		partition by year(orderdate)
		order by orderdate) sorszam,  --éven belüli futó sorszám
	cast(orderdate as date) datum, 
	--utolsó 2 hónapban a rendelések száma
	value osszeg, 
	sum(value) over (
		partition by year(orderdate) 
		order by orderdate 
		rows between unbounded preceding and current row) eves_kumulalt_osszeg, --éven belüli kumulált összeg
	avg(value) over (
		order by orderdate 
		rows between 3 preceding and 3 following) mozgo_atlag_osszeg, --éven belüli kumulált összeg
	sum(value) over (
		partition by year(orderdate) ) eves_total --az év teljes összege
from #tmp

--melyik évben melyik volt a legkisebb/legnagyobb értékű rendelés (al-lekérdezés nélkül, dátummal és értékkel)
drop table #tmp2
go
select o.*, v.value
into #tmp2  --rendelések értékei a value mezőben
from orders o inner join 
	(select orderid, cast(sum((1-discount)*unitprice*quantity) as money) as value
	from [order details] group by orderid ) as v 
on v.orderid = o.orderid

select distinct year(orderdate), --a distinct miatt évente 1 rekord lesz
	first_value(orderdate) over (partition by year(orderdate) order by value asc) as min_datum,	
	first_value(orderid) over (partition by year(orderdate) order by value asc) as min_rend_id,
	first_value(value) over (partition by year(orderdate) order by value asc) as min_ertek,	
	first_value(orderdate) over (partition by year(orderdate) order by value desc) as max_datum,	
	first_value(orderid) over (partition by year(orderdate) order by value desc) as max_rend_id,
	first_value(value) over (partition by year(orderdate) order by value desc) as max_ertek	
from #tmp2

--ÖNÁLLÓ FELADAT #17: módosítsuk a fenti példa lekérdezését úgy, hogy az egymás után következő 5 nagy értékű rendelést keressük, de ügynökönként

--megjegyzes:
select *
from #tmp2									--nem működik mert:
where value = min(value) over (partition  by year(orderdate))  --Windowed functions can only appear in the SELECT or ORDER BY clauses.



/*******************************************************************************/
--TRANZAKCIÓ-KEZELÉS

--implicit tranzakció
create table t1 (id int primary key)
create table t2 (id int primary key, t1_id int references t1(id))
go
insert t1 (id) values (1), (3), (4), (5)
insert t2 (id, t1_id) values (10, 3) -- (3) rekord nem törölhető
go
delete t1 --implicit tr.
--"The DELETE statement conflicted with the REFERENCE constraint ..." etc
select * from t1 --minden rekord megvan


-- xact_abort on
set xact_abort off
delete t2
go
begin tran
	insert t2 (id, t1_id) values (10, 1)
	insert t2 (id, t1_id) values (11, 2) –külső kulcs hiba
	insert t2 (id, t1_id) values (12, 3)
commit tran
go
--"The INSERT statement conflicted with the FOREIGN KEY constraint ..." etc
select * from t2
id	t1_id
10	1
12	3
--az atomicitás sérült
set xact_abort on
delete t2
go
begin tran
	insert t2 (id, t1_id) values (10, 1)
	insert t2 (id, t1_id) values (11, 2) –külső kulcs hiba
	insert t2 (id, t1_id) values (12, 3)
commit tran
go
--"The INSERT statement conflicted with the FOREIGN KEY constraint ..." etc
select * from t2
id	t1_id
-- az atomicitás nem sérült


--PÉLDA
--rendelés-felvétel tranzakció-kezeléssel
declare @prod_name varchar(20), @quantity int, @cust_id nchar(5) --a telefonból (a vevő-ID szöveges)
declare @status_message nvarchar(100),  @status int --a folyamat visszatérési értéke
declare @res_no int --találatok száma
declare @prod_id int, @order_id int --azonosítók
declare @stock int --raktárkészlet 
declare @cust_balance money --a vevő egyenlege
declare @unitprice money --a termék egységára

-- paraméterek
set @prod_name = 'boston'
set @quantity = 10
set @cust_id = 'AROUT'
begin tran
begin try
	select @res_no = count(*) from products where productname like '%' + @prod_name + '%'
	if @res_no <> 1 begin
		set @status = 1
		set @status_message = 'HIBA: a terméknév nem egyértelmű.';
	end else begin
		-- ha egy terméket találunk, megkeressük a kulcsot és a raktárkészletet
		select @prod_id = productID, @stock = unitsInStock from products where productName like '%' + @prod_name + '%'
		-- van-e raktáron? a rendelt mennyiség elérheto-e?
		if @stock < @quantity begin
			set @status = 2
			set @status_message = 'HIBA: a raktárkészlet nem fedezi a megrendelést.'
		end else begin
		-- mennyibe kerül? Van elég pénze a vevönek?
			select @cust_balance = balance from customers where customerid = @cust_id
						--ha nem találjuk a vásárlót, akkor az egyenleg null 
						--mivel kulcsra keresünk, max. 1 találat lehet
			select @unitprice = unitPrice from products where productID = @prod_id --nincs discount
			if @cust_balance < @quantity*@unitprice or @cust_balance is null begin 
				set @status = 3
				set @status_message = 'HIBA: a vásárló nem található vagy az egyenlege túl alacsony.'
			end else begin 
		-- Ellenőrzések vége, elkezdjük a tranzakciót (2 lépés)
		-- 1. vásárló egyenlegének frissítése
    			update customers set balance = balance-(@quantity*@unitprice) where customerid=@cust_id
		-- 2. új bejegyzés az Orders, Order Details táblákba
				insert into orders (customerID, orderdate) values (@cust_id, getdate()) --orderid: identity
				set @order_id = @@identity  --az utolsó identity insert eredménye
				insert [order details] (orderid, productid, quantity, UnitPrice) --itt a hiba
					values(@order_id, @prod_id, @quantity, @unitprice) --itt a hiba
--				insert [order details] (orderid, productid, quantity, UnitPrice, Discount) --ez a jó
--					values(@order_id, @prod_id, @quantity, @unitprice, 0) --ez a jó
				set @status = 0
				set @status_message = cast(@order_id as varchar(20)) + ' sz. rendelés sikeresen felvéve.'
			end
		end
	end
	print 'Status: ' + cast(@status as varchar(50))
	print @status_message	
	if @status = 0 commit tran else begin
		print 'Rolling back transaction'
		rollback tran
	end

end try 
begin catch
	print 'EGYÉB HIBA: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
	rollback tran
end catch
go

--teszteléshez beállítjuk a paramétereket
set nocount off
update customers set balance=1000 where CustomerID='AROUT'
delete [Order Details] where OrderID in (select orderid from Orders where CustomerID='AROUT' and EmployeeID is null)
delete Orders where CustomerID='AROUT' and EmployeeID is null
--most futtatjuk a scriptet, utána ellenőrzés:
select * from Customers where CustomerID='AROUT'
select top 3 * from Orders where CustomerID='arout' order by OrderDate desc
--a programozási hiba korábbi update és insert utasítása visszagördült

--ÖNÁLLÓ FELADAT
/*programozott tranzakció:
paraméterek: termék neve, kategória ID
1. új termék beszúrása
2. annak ellenőrzése, hogy a kapott kategóriában nincs-e már 10-nél több termék
3. ha van, visszagörgetjük a tranzakciót
4. ha nincs, az újonnan felvett termék raktárkészletét beállítjuk 100-ra
5. commit
*/

--adjunk tranzakcionális támogatást a korábbi raktárkészlet-aktualizálós scriptünknek
--teszteljük logikai és egyéb hibára.

--EGYMÁSBA ÁGYAZOTT TRANZAKCIÓK
begin tran
	print @@trancount  --1
	begin tran
		print @@trancount  --2
	commit tran
	print @@trancount  --1
commit tran
print @@trancount  --0
go
begin tran
	print @@trancount  --1
	begin tran
		print @@trancount  --2
rollback tran
print @@trancount  --0



--IZOLÁCIÓS SZINTEK

--blokkolás, várakozás #1
set transaction isolation level serializable --read committed --vagy bármelyik másik
begin tran
update Employees set Salary = 1000 where EmployeeID = 1

select @@SPID --63 (seesion ID)
select distinct resource_type, request_mode, request_type,
	resource_associated_entity_id, request_status, request_session_id 
from sys.dm_tran_locks where request_session_id=@@SPID -- a saját session ID-nk
-- rollback, commit nélkül (egyelőre)

--egy másik editor ablakban:
select * from Employees where EmployeeID=2  --lefut, mert az ID-re van index
select * from Employees where FirstName = 'Andrew'  --várakozik, mert minden rekordot meg kell néznie

--a példa végén ne feledjük:
rollback tran

--blokkolás, várakozás #2
--hogyan oldja meg az update zár az adatmódosító tranzakciók kiéheztetésének elkerülését 
--a folymatosan olvasott táblákon?
--DEMO 3 tranzakcióval
--CSAK ha van rá idő, kedv...

--ebben az editor ablakban:
set transaction isolation level serializable --tehát az S zár marad
begin tran
select * from Employees where FirstName = 'Andrew'  --range S zár marad
select distinct resource_type, request_mode, request_type,
	resource_associated_entity_id, request_status, request_session_id 
from sys.dm_tran_locks where request_session_id=@@SPID --S lock a táblára: GRANT

--másik editorban kérdezzük le a @@SPID-t, legyen most ez 51
--utána a másik editorban futtassuk ezt:
set transaction isolation level serializable --S zár marad
begin tran
update Employees set Salary = 1000 where EmployeeID = 1
--várakozik

--ebben az editorban ellenőrizzük a másik, várakozó tr. zárjait:
select distinct resource_type, request_mode, request_type,
	resource_associated_entity_id, request_status, request_session_id 
from sys.dm_tran_locks where request_session_id=51
--megjelenik a KEY X típusú WAIT állapotú zár

--ezek után egy harmadik editor ablakban:
set transaction isolation level serializable --S zár marad
begin tran
select * from Employees where EmployeeID = 1
--szintén várakozik, mert az X zár mellett az S zárat nem tudja megkapni
--így kerülhető el az adatmódosító tr. kiéheztetése: Ha az 1. tr. lefut, utána
--a 2. megkapja majd az X zárat, aztán jöhet a 3. tr. olvasása:

--ebben az ablakban:
commit tran
--erre a 2. ablakban lefut az update, de a 3. tr. még mindig várakozik

--ekkor a 2. ablakban: 
commit tran

--erre az 1. ablakban is lefut a select
--tehát a később jött select-nek meg kellett várnia az update végét
--ne feledjük a 3. ablakban is:
commit tran

--DEMO deadlock-ra
create table test_product(id int primary key, prod_name varchar(50) not null, sold varchar(50), buyer varchar(50))
insert test_product(id, prod_name, sold) values (1, 'car', 'for sale')
insert test_product(id, prod_name, sold) values (2, 'horse', 'for sale')
go
select * from test_product
update test_product set sold='for sale', buyer=null where id=2
go
set tran isolation level read committed
go
begin tran
declare @sold varchar(50)
select @sold=sold from test_product where id=2 
if @sold='for sale' begin
    waitfor delay '00:00:10' --terheljük a bankszámlát
    update test_product set sold='sold', buyer='My name' where id=2
    print 'sold successfully'
end else print 'product not available'
commit tran
go
--a fenti tranzakciót párhuzamosan két editorban futtatjuk
--a másik script:
set tran isolation level read committed 
go
begin tran
declare @sold varchar(50)
select @sold=sold from test_product where id=2
if @sold='for sale' begin
    waitfor delay '00:00:10' --now we are performing the bank transfer
    update test_product set sold='sold', buyer='Your name' where id=2 –ez a 2. vásárló
    print 'sold successfully'
end else print 'product not available'
commit tran
go
--ez történik:
select * from test_product
id	prod_name	sold		buyer
1	car			for sale	NULL
2	horse		sold		Your name

--megismételni maqgasabb izolációs szinten -> deadlock

--megismételni úgy, hogy minden hallgató a test adatbázisra lép be (tábla már ott van), és beírja a nevét a scriptbe
--az izolációs szint legyen rep. read minden hallgatónál
--egyszerre indítjuk a scripteket
--az összes hallgató közül pontosan egynek sikerülhet a ló megvásárlása

/******************************************************************************/
--TÁROLT ELJÁRÁSOK
--PÉLDA: emeljük meg a paraméterként kapott nevű dolgozó egyenlegét 10%-kal
drop procedure sp_inc_salary

go
create procedure sp_inc_salary @name nvarchar(20) as
begin try
	set nocount on
	declare @address nvarchar(max), @res_no int, @emp_id int
	select @res_no=count(*) from Employees where LastName like @name
	if @res_no=0 print 'Nincs találat.'
	else if @res_no>1 print 'Több, mint 1 találat.'
	else begin  --épp egy találat
		select @address=Country+', '+City+' '+Address, @emp_id=EmployeeID 
			from Employees where LastName like @name
		print 'Dolgozó ID: ' + cast(@emp_id as varchar(10)) + ', cím: ' + @address
		update Employees set salary=1.1*salary where EmployeeID=@emp_id
		print 'Egyenleg növelve.'
	end
end try 
begin catch
	print 'EGYÉB HIBA: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
	rollback tran
end catch
go
--teszt
exec sp_inc_salary 'Fuller'

--ÖNÁLLÓ FELADAT: írjunk egy tárolt eljárást, amely a kapott nevű termék termék-kategóriáját visszaírja

--tárolt eljárások visszatérési értéke (RETURN)
 
drop proc p
go
create proc p as 
return null
go
declare @eredm int
exec @eredm=p
print @eredm --warning

drop proc p
go
create proc p as print 'sikeres futás'
go
declare @eredm int
exec @eredm=p
print @eredm --0

drop proc p
go
create proc p as 
print 'sikeres futás'
return 1
go
declare @eredm int
exec @eredm=p
print @eredm --1

drop proc p
go
create proc p as select 1/0
go
declare @eredm int
exec @eredm=p
print @eredm --		-6 (<0, mert hiba történt)

--PÉLDA
--egyik eljárás hívja a másikat
--a korábbi rendelés-felvételi tranzakciónk most egy tárolt eljárásban 
--egy másik eljárást hív meg, mely a rendelés tételei alapján aktualizálja a raktárkészletet
drop proc  sp_raktárkészlet_aktualizalo
go
create procedure sp_raktárkészlet_aktualizalo 
@orderid int, --a rendelés azonosítója
@result varchar(50) output --visszajelzés
as
begin try
	update products set unitsInStock = unitsInStock - od.quantity 
	from products p inner join [Order Details] od on od.ProductID=p.ProductID 
	where od.OrderID=@orderid
	set @result='OK'
end try
begin catch --hiba akkor lehet, ha valamelyik tétel negatívba vinné a készletet
	print '  Inventory error: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
	set @result='HIBA'
end catch
go

--teszt
insert orders (OrderDate) values (getdate())
select @@identity --12105
select * from Products where ProductID=9 --unitsinstock =29
select * from Products where ProductID=10 --unitsinstock =31
insert [Order Details]  (orderid, productid, quantity, UnitPrice, Discount)
values (12105, 9, 10, 30, 0),(12105, 10, 40, 30, 0)  
--tehát a második tétel hibát ad az sp_raktárkészlet_aktualizalo hívásakor:
go
declare @eredm varchar(50)
exec sp_raktárkészlet_aktualizalo 12105, @eredm output
print @eredm
go
--helyreállítás
delete [Order Details] where OrderID=12105
delete Orders where OrderID=12105
update Products set UnitsInStock=29 where ProductID=9
update Products set UnitsInStock=31 where ProductID=10
select * from Products

--a rendelés-felvételi tranzakció tárolt eljárásban
--a raktárkészlet ellenőrzését most a fenti eljárásra bízzuk
create procedure uj_rendeles 
@prod_name varchar(20), 
@quantity int, 
@cust_id nchar(5) --a három bemeneti paraméter
as
declare @status_message nvarchar(100),  @status int --a folyamat visszatérési értéke
declare @res_no int --találatok száma
declare @prod_id int, @order_id int --azonosítók
declare @stock int --raktárkészlet 
declare @cust_balance money --a vevő egyenlege
declare @unitprice money --a termék egységára

-- paraméterek
begin tran
begin try
	select @res_no = count(*) from products where productname like '%' + @prod_name + '%'
	if @res_no <> 1 begin
		set @status = 1
		set @status_message = 'HIBA: a terméknév nem egyértelmű.'
	end else begin
		-- ha egy terméket találunk, megkeressük a kulcsot
		select @prod_id = productID from products where productName like '%' + @prod_name + '%'
--INNEN KIVETTÜK A RAKTÁR ELLENŐRZÉSÉT		
		-- mennyibe kerül? Van elég pénze a vevönek?		
		select @cust_balance = balance from customers where customerid = @cust_id
					--ha nem találjuk a vásárlót, akkor az egyenleg null 
					--mivel kulcsra keresünk, max. 1 találat lehet
		select @unitprice = unitPrice from products where productID = @prod_id --nincs discount
		if @cust_balance < @quantity*@unitprice or @cust_balance is null begin 
			set @status = 2
			set @status_message = 'HIBA: a vásárló nem található vagy az egyenlege túl alacsony.'
		end else begin 
	-- Ellenőrzések vége, elkezdjük a tranzakciót (3 lépés)
	-- 1. vásárló egyenlegének frissítése
    		update customers set balance = balance-(@quantity*@unitprice) where customerid=@cust_id
	-- 2. új bejegyzés az Orders, Order Details táblákba
			insert into orders (customerID, orderdate) values (@cust_id, getdate()) --orderid: identity
			set @order_id = @@identity  --az utolsó identity insert eredménye
			insert [order details] (orderid, productid, quantity, UnitPrice, Discount) 
				values(@order_id, @prod_id, @quantity, @unitprice, 0) 
--ITT AZ ÚJ RÉSZ:
	-- 3. raktárkészlet aktualizálása
			declare @raktar_eredm varchar(50)
			exec sp_raktárkészlet_aktualizalo @order_id, @raktar_eredm output
			if @raktar_eredm = 'OK' begin
				set @status = 0
				set @status_message = cast(@order_id as varchar(20)) + ' sz. rendelés sikeresen felvéve.'
			end else begin
				set @status = 3
				set @status_message = 'HIBA: a raktárkészlet nem elegendő.'
			end			
		end
	end
	print 'Státusz: ' + cast(@status as varchar(50))
	print @status_message	
	if @status = 0 commit tran else begin
		rollback tran
		print 'A tranzakció visszagörgetve.'
	end
end try 
begin catch
	print 'EGYÉB HIBA: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
	rollback tran
	print 'A tranzakció visszagörgetve.'
end catch
go

--teszt
--beállítjuk a paramétereket
set nocount off
select * from Products where ProductName like 'Boston%'  --id: 40, unitsinstock: 900
update customers set balance=1000 where CustomerID='AROUT'
delete [Order Details] where OrderID in (select orderid from Orders where CustomerID='AROUT' and EmployeeID is null)
delete Orders where CustomerID='AROUT' and EmployeeID is null
--most futtatjuk, kis mennyiségnél nem várunk hibát
exec uj_rendeles 'boston', 10, 'AROUT'  --nincs hiba
--ell.
select * from Customers where CustomerID='AROUT'
select top 3 * from Orders where CustomerID='arout' order by OrderDate desc
select * from Products where ProductName like 'Boston%'  --unitsinstock: 890 (OK)
--helyreállítás:
delete [Order Details] where OrderID in (select orderid from Orders where CustomerID='AROUT' and EmployeeID is null)
delete Orders where CustomerID='AROUT' and EmployeeID is null
update Products set UnitsInStock=9 where ProductID=40 --kis készletet állítuk be
update customers set balance=1000 where CustomerID='AROUT'
--újra futtatjuk, a mennyiség miatt hibát várunk 
exec uj_rendeles 'boston', 10, 'AROUT'  --megjött a hiba
select top 3 * from Orders where CustomerID='arout' order by OrderDate desc --nincs új rendelés
--az eredeti helyzet helyreállítása
delete [Order Details] where OrderID in (select orderid from Orders where CustomerID='AROUT' and EmployeeID is null)
delete Orders where CustomerID='AROUT' and EmployeeID is null
update Products set UnitsInStock=900 where ProductID=40 --kis készletet állítuk be
update customers set balance=1000 where CustomerID='AROUT'


/***********************************************************************/
--FELHASZNÁLÓI FÜGGVÉNYEK
--PÉLDA: dátum formázása
go
drop function fn_ev_honap
go
create function fn_ev_honap (@datum datetime)
returns varchar(50) AS
begin
	declare @eredm varchar(50)
	set @eredm = case
		when month(@datum) < 10 then cast(year(@datum) as varchar(4)) +'_0'+  cast(month(@datum) as varchar(2))
		when month(@datum) >= 10 then cast(year(@datum) as varchar(4)) +'_'+  cast(month(@datum) as varchar(2))
		else 'N.A'
	end
	return @eredm
end
go
--SELECT lekérdezésben felhasználható:
select e.employeeid, lastname, dbo.fn_ev_honap(orderdate) as honap,
count(orderid) as rend_szam
from employees e left outer join orders o on e.employeeid=o.employeeid
group by e.employeeid, lastname, dbo.fn_ev_honap(orderdate)
order by lastname, honap


--ÖNÁLLÓ FELADAT: írjunk függvényt, amely a paraméterül kapott 
--alkalmazott ID (EmployeeID) alapján
--visszaadja az illető eddigi rendeléseinek a számát! 
--Teszteljük a függvényt SELECT lekérdezéssel!
go
drop function fn_rend_szam
go
create function fn_rend_szam (@empid int)
returns int AS
begin
	declare @rsz int
	select @rsz=count(*) from orders where EmployeeID=@empid 		
	return @rsz
end
go
--teszt
select dbo.fn_rend_szam(EmployeeID), * from Employees
select * from Orders where EmployeeID=1  --126 OK

--ÖNÁLLÓ FELADAT: 
--írjunk függvényt, amely két, datetime típusú változó közül
--visszaadja a korábbit, ha valamelyik null, akkor pedig a 'N.A.' stringet!
--tesztelés az orders táblán
--drop function korabbi


--PÉLDA: a függvény visszaadja a paraméterül kapott termékkategória termékeinek 
--a nevét és az illető termékek rendeléseinek a számát.
create function kateg_termekei (@kat_id int) returns table as
return ( 
	select p.ProductName as termeknev, COUNT(*) as rendelesek_szama
	from Products p inner join [Order Details] od on p.ProductID=od.ProductID
	where p.CategoryID=@kat_id
	group by p.ProductID, p.ProductName)
go
select * from dbo.kateg_termekei(2) where rendelesek_szama>30


--ÖNÁLLÓ FELADAT: írjunk függvényt, amely egy táblában 
--visszaadja a paraméterként kapott azonosítójú
--alkalmazotthoz tartozó területek nevét és régióját 
--(RegionDescription és TerritoryDescription mezők)! 


--TRIGGEREK

--PÉLDA: minden új rendelés beszúrásakor emeljük meg az alkalmazott fizetését 2%-kal
drop trigger tr_uj_rend
go
create trigger tr_uj_rend on orders after insert as
begin
	declare @i int
	select @i=COUNT(*) from inserted
	print 'Beszúrt rekordok száma: '+cast(@i as varchar(50))
	update Employees set Salary=Salary*1.02
		where EmployeeID in (select EmployeeID from inserted)
end	--több rekordra is működik
go
--teszt
select salary from Employees where EmployeeID=3 --100
insert Orders (EmployeeID) values (3)
select salary from Employees where EmployeeID=3 --102
delete orders where OrderDate is null

--ÖNÁLLÓ FELADAT: egy termék rekord módosításakor másoljuk ki 
--egy products_log nevű táblába a
--módosult termék azonosítóját, nevét és raktárkészletét!
--raktárkészlet-aktualizálás 


--PÉLDA: Egy mindkét virtuális táblát használó triggerrel a 
--már sokféleképpen megoldott raktárkészlet-aktualizálás is elvégezhető.
drop trigger tr_demo
go
create trigger tr_demo on [order details] after update as
declare @ord_no int
begin try
	select @ord_no = count(*) from inserted 
	print 'updating records: ' + cast(@ord_no as varchar(50))
	update Products set UnitsInStock = UnitsInStock-(i.quantity-d.quantity) 
	from products p inner join inserted i on p.ProductID=i.ProductID
		inner join deleted d on i.ProductID=d.ProductID
end try
begin catch
	print 'Hiba: túl nagy mennyiség a rendelési tételen.'
end catch
go

--teszt
select top 1 * from [Order Details] --quantity 12
update [Order Details] set Quantity=13000 where OrderID=10248 and ProductID=11  --hibát váltunk ki a túl nagy mennyiséggel
select top 1 * from [Order Details] --quantity 12 (az update visszagördül magától)

--ÖNÁLLÓ FELADAT #26: a logika értelemszerű módosításával írjuk át a fenti triggert úgy, hogy új rendelés beszúrásakor, 
--tehát INSERT esetén működjön

