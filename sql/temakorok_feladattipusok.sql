/* FŐ TÉMAKÖRÖK ÉS FELADATTÍPUSOK */

-- Adatmodellezés: mező-orientált ↔ rekord-orientált
-- Feladat: átalakítás rekord-orientálttá (pl. employee_record tábla) ami kell LastName, Title, City employees táblából.

select LastName, Title, City from employees

drop table if exists employee_record
create table employee_record(
	id int not null, 
	emp_key varchar(50), 
	emp_value varchar(50)
)

insert into employee_record (id, emp_key, emp_value)
select EmployeeID, 1, LastName from Employees where LastName is not null
	union
select EmployeeID, 2, Title from Employees where Title is not null
	union
select EmployeeID, 3, City from Employees where City is not null

select * from employee_record where emp_key = 1

/* Kereszttáblás lekérdezések – PIVOT / UNPIVOT */


	