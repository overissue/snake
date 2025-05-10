/*
ÖNÁLLÓ FELADAT: 
A korábbi scriptet, mely a Products.UnitsInStock mezőjének értékét aktualizálta, 
egészítsük ki hibakezeléssel!  (Az új értéknek nagyobbnak kell lennie 0-nál.)
*/
--MEGOLDÁS
--raktárkészlet beállítása a teszthez:
update Products set UnitsInStock = 100 where ProductID in (11, 42, 72)
select * from [Order Details] where OrderID=10248 --quantity: 4, 40, 40
go
declare @order_id int = 10248, @prod_id int, @prod_name nvarchar(40)
begin try
	--select @prod_id=1/0
	update Products set UnitsInStock=UnitsInStock-od.Quantity 
	from [Order Details] od inner join Products p on p.ProductID=od.ProductID
	where od.OrderID=@order_id
				--check constraint sértés hibaszáma 547
	print cast(@order_id as varchar(20))+' számú rendelés a raktárba átvezetve.'
end try
begin catch
	if ERROR_NUMBER()=547 begin
		select @prod_id=p.ProductID, @prod_name=p.ProductName
		from [Order Details] od inner join Products p on p.ProductID=od.ProductID
			where od.OrderID=@order_id and p.UnitsInStock-od.Quantity<0 
			order by p.ProductID	--több tételnél is lehetett gond, most csak egyet adunk vissza
		print 'RAKTÁRKÉSZLET-HIBA: '+cast(@order_id as varchar(20))+' számú rendelésen a '+
				@prod_name+' ('+cast(@prod_id as varchar(20))+') tétel nem teljesíthető.'		
	end
    else print 'EGYÉB HIBA: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
end catch
go


/*
ÖNÁLLÓ FELADAT: Raktárkészlet-karbantartó script 

Az eljárást a raktáros használja arra, hogy egy
létezo termék raktárkészletét növelje, vagy egy új cikket vegyen fel
a raktárba.

bemenő paraméterek:
set @termeknev = 'Raclette'
set @mennyiseg = 12
set @szallito = 'Formago Company'

A script '%raclette%'-re illŐ terméknevet keres a Products táblában.
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

--MEGOLDÁS
set nocount on
go
declare @nev varchar(50), @mennyiseg int, @szallitonev varchar(50)
set @nev = 'Raclette'
set @mennyiseg = 12
set @szallitonev = 'Formago Company'
declare @talalatok_szama int, @uj_termek_id int, @uj_szallito_id int, @talalat_szallito int
begin try	
	select @talalatok_szama = count(*) from products
			where productName like '%' + @nev + '%'    ;
	if @talalatok_szama = 1
		begin
			update products set unitsinstock = unitsinstock + @mennyiseg
				where productName like '%' + @nev + '%'
			print 'Mennyiség módosítva'
		end
	else if @talalatok_szama = 0 --új termék
		begin
		--a szállító ellenõrzése, felvétele
			select @talalat_szallito=COUNT(*) from suppliers 
				where CompanyName like '%' + @szallitonev + '%'
			if @talalat_szallito = 1
				select @uj_szallito_id=supplierid from suppliers 
					where CompanyName like '%' + @szallitonev + '%'	 
			else if @talalat_szallito = 0 
			begin  --új szállító
				insert suppliers (CompanyName) values (@szallitonev)
				set @uj_szallito_id=@@identity
				print 'Új szállító felvéve: ' + cast(@uj_szallito_id as varchar(50))
			end else begin
				print 'Túl sok találat, kérem pontosítsa a szállító nevét!'
				return
			end
			insert products (productname, unitsinstock, discontinued, SupplierID)
				values(@nev, @mennyiseg, 0, @uj_szallito_id)
			set @uj_termek_id = @@identity
			print 'Új termék felvéve: ' + cast(@uj_termek_id as varchar(50))
		end
		else if @talalatok_szama <= 10 --választás
		begin
			print 'Több találat, kérem, válasszon a listából!'
			select * from products where productName like '%' + @nev + '%'    ;
		end else  --pontosítás
			print 'Túl sok találat, kérem pontosítsa a terméknevet!'
end try
begin catch
    print 'EGYÉB HIBA: '+ ERROR_MESSAGE() + ' (' + cast(ERROR_NUMBER() as varchar(20)) + ')'
end catch
go

