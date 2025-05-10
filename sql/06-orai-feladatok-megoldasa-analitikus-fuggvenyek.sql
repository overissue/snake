--ÖNÁLLÓ FELADAT #16: módosítsuk a fenti példa lekérdezését úgy, hogy az egymás után következő 
--5 nagy értékű rendelést keressük
--MEGOLDÁS:

select orderdate, cast(sum((1-discount)*unitprice*quantity) as money) as value
into #tmp from orders o inner join [order details] d on o.orderid=d.orderid
where EmployeeID = 2 
group by o.orderid, o.orderdate --96
order by OrderDate 
go
select * from #tmp order by OrderDate

select *
from (
	select orderdate, value, min(value) over ( 
		order by orderdate 
		rows between 4 preceding and current row) as mini, 
	row_number() over (
		order by orderdate) as sorsz 
	from #tmp 
) a where mini > 1000 and sorsz > 4 --1 ilyen van

--ÖNÁLLÓ FELADAT #17: módosítsuk a 16- feladat lekérdezését úgy, hogy az egymás után 
--következő 5 nagy értékű rendelést keressük, de ügynökönként
--MEGOLDÁS:

select o.*, v.value
into #tmp2  --rendelések értékei a value mezőben
from orders o inner join 
	(select orderid, cast(sum((1-discount)*unitprice*quantity) as money) as value
	from [order details] group by orderid ) as v 
on v.orderid = o.orderid

select employeeid, orderdate, sorsz, value
from (
	select employeeid, orderdate, value, 
	min(value) over ( 
		partition by employeeid
		order by orderdate 
		rows between 4 preceding and current row) as mini,
	row_number() over (
		partition by employeeid
		order by orderdate) as sorsz 
	from #tmp2 
) a where mini > 1000 and sorsz > 4 
--16 ilyen van

select * from #tmp2 where EmployeeID=1 order by OrderDate


--megjegyzes:
select *
from #tmp2									--nem működik mert:
where value = min(value) over (partition  by year(orderdate))  --Windowed functions can only appear in the SELECT or ORDER BY clauses.

--megjegyzés:
select (select MAX(birthdate) from employees), * from employees
--annyi mint:
select MAX(birthdate) over (order by birthdate rows between unbounded preceding and unbounded following) , * 
from employees
