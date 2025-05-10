use [pivot_gyumolcs]

--drop table csapat
create table csapat(
    csapat_id int not null primary key,
    csapat_nev nvarchar(50) not null
)

--drop table gyumolcs
create table gyumolcs(
    gyumolcs_id int not null primary key,
    gyumolcs_nev nvarchar(50)
)

--drop table nap
create table nap(
    nap_id int not null primary key,
    nap_nev nvarchar(50)
)

--drop table eredm
create table eredm(
    eredm_id int identity(1,1) primary key,
    csapat_id int not null references csapat(csapat_id),
    nap_id int not null references nap(nap_id),
    gyumolcs_id int not null references gyumolcs(gyumolcs_id),
    leadott_lada int not null
)

insert csapat(csapat_id, csapat_nev) values(1, 'Szorgos'), (2, 'Lusta')
insert gyumolcs(gyumolcs_id, gyumolcs_nev) values(1, 'alma'), (2, 'szilva')
insert nap(nap_id, nap_nev) values(1, 'hétfő'), (2, 'kedd'), (3, 'szerda')
insert eredm(csapat_id, nap_id, gyumolcs_id, leadott_lada)
    values(1,1,1,50), (1,2,1,60), (1,3,1,70), (1,1,2,100), (1,2,2,120), (1,3,2,140),
    (2,1,1,5), (2,2,1,6), (2,3,1,7), (2,1,2,10), (2,2,2,12), (2,3,2,14)

--ellenőrzés
select * from eredm

--
--csoportosító lekérdezések: normál SQL
--

--csapatok napi teljesítménye
select cs.csapat_nev, n.nap_nev, sum(leadott_lada) as teljesitmeny
    from eredm e inner join csapat cs on cs.csapat_id = e.csapat_id
    inner join nap n on n.nap_id = e.nap_id
group by cs.csapat_id, cs.csapat_nev, n.nap_id, n.nap_nev
order by cs.csapat_nev, n.nap_nev

--csapatok teljesítménye gyümölcsönként
select cs.csapat_nev, gy.gyumolcs_nev, sum(leadott_lada) as teljesitmeny
    from eredm e
    inner join csapat cs on cs.csapat_id = e.csapat_id
    inner join gyumolcs gy on gy.gyumolcs_id = e.gyumolcs_id
group by cs.csapat_id, cs.csapat_nev, gy.gyumolcs_id, gy.gyumolcs_nev
order by cs.csapat_nev, gy.gyumolcs_nev

-- ládaszám gyümölcsönként
select gy.gyumolcs_nev, sum(leadott_lada) as teljesitmeny
    from eredm e
    inner join gyumolcs gy on gy.gyumolcs_id = e.gyumolcs_id
    inner join nap n on n.nap_id = e.nap_id
group by gy.gyumolcs_id, gy.gyumolcs_nev
order by gy.gyumolcs_nev

-----PIVOT-----

-- készitsunk egy pivot kiindulo táblát
select cs.csapat_nev, n.nap_nev, gy.gyumolcs_nev, e.leadott_lada
    into eredm_pivot
    from eredm e
    inner join csapat cs on cs.csapat_id = e.csapat_id
    inner join gyumolcs gy on gy.gyumolcs_id = e.gyumolcs_id
    inner join nap n on n.nap_id = e.nap_id
go

select * from eredm_pivot order by csapat_nev

-- a gyümölcsök az oszlopokban jelenjenek meg (pivot)
select csapat_nev, nap_nev, pt.alma, pt.szilva
    from eredm_pivot
        pivot(sum(leadott_lada) for gyumolcs_nev in (alma, szilva)) as pt
order by csapat_nev, nap_nev

--önálló feladat: legyenek sorokban a napok és gyümölcsök és oszlopokban a csapatok
select nap_nev, gyumolcs_nev, pt.Szorgos, pt.Lusta
    from eredm_pivot 
        pivot(sum(leadott_lada) for csapat_nev in (Szorgos, Lusta)) as pt
order by nap_nev, gyumolcs_nev

select * from eredm_pivot where csapat_nev='Lusta'

-- összesítsük napok nélkül: csapatok teljesítménye gyümölcsönként:
-- sorokban a csapatok, oszlopokban a gyümölcsök
select csapat_nev, pt.alma, pt.szilva
    from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
            from eredm_pivot group by csapat_nev, gyumolcs_nev) as forras
    pivot(sum(leadott_lada) for gyumolcs_nev in ([alma],[szilva])) as pt
    
--sorokban a gyümölcsök, oszlopokban a csapatok
-- a belső elect nem változik
select gyumolcs_nev, pt.lusta, pt.szorgos
    from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
            from eredm_pivot
            group by csapat_nev, gyumolcs_nev) as forras
    pivot(sum(leadott_lada) for csapat_nev in ([lusta],[szorgos])) as pt
    
-- hagyjuk ki a keddet !
-- csak a belső select változik
select gyumolcs_nev, pt.lusta, pt.szorgos
    from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada 
            from eredm_pivot
            where nap_nev <> 'kedd'
            group by csapat_nev, gyumolcs_nev) as forras
    pivot(sum(leadott_lada) for csapat_nev in ([lusta],[szorgos])) as pt

-- önálló feladat: legyenek sorokban a napok, oszlopokban a csapatok és hagyjuk ki a szerdát
select nap_nev, pt.lusta, pt.szorgos
    from (select nap_nev, csapat_nev, sum(leadott_lada) as leadott_lada
            from eredm_pivot
            where nap_nev <> 'szerda'
            group by nap_nev, csapat_nev) as forras
    pivot(sum(leadott_lada) for csapat_nev in ([lusta], [szorgos])) as pt

-- többszintű bontás a sorokban: sorokban csapatok és napok, oszlopokban a gyümölcsök
select csapat_nev, nap_nev, pt.alma, pt.szilva
    from eredm_pivot
    pivot(sum(leadott_lada) for gyumolcs_nev in ([alma], [szilva])) as pt
order by csapat_nev, nap_nev

-----UNPIVOT-----

--legyen egy pivotált kiinduló #temp táblázat (ideiglenes)
select csapat_nev, pt.alma, pt.szilva
into #temp
from (select csapat_nev, gyumolcs_nev, sum(leadott_lada) as leadott_lada
        from eredm_pivot group by csapat_nev, gyumolcs_nev) as forras
    pivot(sum(leadott_lada) for gyumolcs_nev in ([alma],[szilva])) as pt

--ellenorzés
select * from #temp

-- unpivot: tegyük vissza a gyümölcsöket a sorokba
-- persze a csoportosítás elveszik
select * from #temp
select csapat_nev, gyumolcs_nev, leadott_lada
    from #temp
        unpivot(leadott_lada for gyumolcs_nev in (alma, szilva)) as upt


