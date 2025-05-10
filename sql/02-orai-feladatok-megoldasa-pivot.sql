/*
ÖNÁLLÓ FELADAT: 
•	Legyenek sorokban a napok, oszlopokban a csapatok */
--MEGOLDÁS
select nap_nev, pt.Lusta, pt.Szorgos
from (select csapat_nev, nap_nev, sum(leadott_lada) as leadott_lada 
		from eredm_pivot group by csapat_nev, nap_nev) as forras 
	pivot (sum(leadott_lada) for csapat_nev in ([Lusta], [Szorgos])) as pt
/*
ÖNÁLLÓ FELADAT: 
•	Legyen most fordítva, és a napok közül hagyjuk ki a szerdát */
--MEGOLDÁS
select csapat_nev, pt.hétfő, pt.kedd
from (select csapat_nev, nap_nev, sum(leadott_lada) as leadott_lada 
		from eredm_pivot group by csapat_nev, nap_nev) as forras 
	pivot (sum(leadott_lada) for nap_nev in ([hétfő], [kedd])) as pt
--tanulság: a mezőnév-listának nem kell teljesnek lennie
/*
•	Legyenek sorokban a napok és a gyümölcsök, oszlopokban a csapatok
*/
--MEGOLDÁS
select pt.nap_nev, pt.gyumolcs_nev, pt.Lusta, pt.Szorgos
from eredm_pivot 
	pivot (sum(leadott_lada) for csapat_nev in ([Lusta], [Szorgos])) as pt
order by  pt.nap_nev, pt.gyumolcs_nev

/*  ÖNÁLLÓ FELADAT
•	készítsünk egy kimutatást: sorokban a beszállítók, oszlopokban a termékkategóriák, az érték az, hogy 
az illető szállítónak az adott kategóriában hány különböző terméke van
*/
--MEGOLDÁS
--a forrás
select CompanyName, isnull(produce, 0) produce, isnull(seafood, 0) seafood, isnull(beverages, 0) beverages
from (
	select c.CategoryName, s.CompanyName, count(*) db from products p inner join Categories c on p.CategoryID=c.CategoryID 
	inner join Suppliers s on s.SupplierID=p.SupplierID
	group by c.CategoryID, c.CategoryName, s.SupplierID, s.CompanyName) forras
pivot ( sum(db) for categoryname in (produce, seafood, beverages) ) p
order by beverages desc, produce desc




/*
ÖNÁLLÓ FELADAT: 
•	visszaalakítás a "sorokban a napok és a gyümölcsök, oszlopokban a csapatok" alakból
*/

--MEGOLDÁS
select pt.nap_nev, pt.gyumolcs_nev, pt.Lusta, pt.Szorgos
into #nap_gyumolcs
from eredm_pivot 
	pivot (sum(leadott_lada) for csapat_nev in ([Lusta], [Szorgos])) as pt
order by  pt.nap_nev, pt.gyumolcs_nev

select pt.nap_nev, pt.gyumolcs_nev, pt.csapat_nev, leadott_lada
from #nap_gyumolcs unpivot (leadott_lada for csapat_nev in ([Lusta], [Szorgos])) as pt

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

