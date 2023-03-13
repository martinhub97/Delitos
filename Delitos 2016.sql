-- Se creo una nueva tabla y cambio la columna cantidad registrada para obtener el valor sin cero
--SELECT 
--	d.id 
--	,d.fecha
--	,d.franja_horaria 
--	,d.tipo_delito 
--	,d.subtipo_delito
--	,cast(replace(cantidad_registrada,'0',' ') AS int) as cantidad_registrada		   	  
--	,d.comuna
--	,d.barrio
--	,d.lat
--	,d.long
	
--into t_delitos_2016	
--from delitos_2016 as d

--update t_delitos_2016 
--set barrio = cast(case when barrio = 'NULL' THEN NULL else barrio end as varchar)  

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'Vélez Sársfield', 'Velez Sarsfield')

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'Nuñez', 'Nu�ez')

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'Constitución', 'Constitucion')

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'Villa Pueyrredón', 'Villa Pueyrredon')

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'San Cristóbal', 'San Cristobal')

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'San Nicolás', 'San Nicolas')

--UPDATE t_delitos_2016 
--SET BARRIO = REPLACE(BARRIO,'Agronomía', 'Agronomia')

--Apartir de aca se empiezan a hacer consultas por agrupacion 
--Mayor cantidad de delitos por Barrio
select barrio, sum (cantidad_registrada) as Total_de_Hechos
from t_delitos_2016 
where barrio != ' '
group by barrio, cantidad_registrada
order by sum(cantidad_registrada) desc, barrio;

------------------------------------
--Top 3 Mayor cantidad de Delitos en 2016 
with Lista_Delitos as (select tipo_delito, sum(cantidad_registrada) as Total_de_Hechos
from t_delitos_2016
group by tipo_delito)
select top 3*
from Lista_Delitos
order by Total_de_Hechos desc

----------------------------------------
--Mayor cantidad de delitos por Franja Horaria
select franja_horaria, tipo_delito, sum(cantidad_registrada) as Total_de_Hechos
from t_delitos_2016
group by franja_horaria, tipo_delito
order by SUM(cantidad_registrada) desc;

--------------------------------------------

--Seleccion para ver en que horario se da mayormente los delitos de Robo
select franja_horaria, tipo_delito, sum(cantidad_registrada) as Total_de_Hechos
from t_delitos_2016
where tipo_delito LIKE 'Robo%'
group by franja_horaria, tipo_delito
order by franja_horaria desc;
select distinct franja_horaria
from t_delitos_2016
order by franja_horaria desc
--------------------------------------------
--Seleccion para ver en que horario se da mayormente los Homicidios
select franja_horaria, tipo_delito, sum(cantidad_registrada) as Total_de_Hechos
from t_delitos_2016
where tipo_delito LIKE 'Homicidio'
group by franja_horaria, tipo_delito
order by SUM(cantidad_registrada) desc;
----------------------------------------------------
--Top 3 de Tipos de Delitos por Comuna
with Cantid_Comuna_Delito as (select comuna , sum (cantidad_registrada) as Cant, tipo_delito
from t_delitos_2016
group by comuna, tipo_delito
),
Ranking_Delito_Comuna as (select rank() Over (partition by Comuna order by Cant desc) as ranking, tipo_delito, comuna, Cant
from Cantid_Comuna_Delito
group by comuna, tipo_delito, Cant)
select top 3*
from Ranking_Delito_Comuna
where ranking = 1 and comuna != 0
order by Cant desc
-----------------------------------------------------
--Filtro para ver por subtipo de delitos 
select subtipo_delito, SUM(cantidad_registrada) as Total_de_Hechos
from t_delitos_2016
where subtipo_delito != ''
group by subtipo_delito
order by Total_de_Hechos desc;
------------------------------------------------------
--CTE Para ver donde suceden en porcentaje la mayor cantidad de delitos
	with M as (select barrio, SUM(cantidad_registrada) as txb,(select sum(cantidad_registrada) from t_delitos_2016) as total
	from t_delitos_2016
	group by barrio)
	select barrio, cast(txb as decimal)/cast(total as decimal)*100 AS Porcentaje
	from M
	group by barrio, txb, total
	ORDER BY Porcentaje desc;
-------------------------------------------------------
--Subquery Para ver donde suceden en porcentaje la mayor cantidad de delitos,
--Misma consulta que la anterior pero mediante una subquery
select barrio, cast(txb as decimal)/cast(total as decimal)*100 AS Porcentaje
from(select barrio, SUM(cantidad_registrada) as txb,(select sum(cantidad_registrada) from t_delitos_2016) as total
from t_delitos_2016
group by barrio) as p
order by Porcentaje desc;
-------------------------------------------------------
--CTE Para ver el porcentaje de Robo Automotor en el mes 12
with Mes12 as (select subtipo_delito, (select SUM(cantidad_registrada) from t_delitos_2016 where subtipo_delito = 'Robo Automotor' and MONTH(fecha)= 12 ) as txb,(select sum(cantidad_registrada) from t_delitos_2016 where subtipo_delito = 'Robo Automotor' ) as total
from t_delitos_2016
group by subtipo_delito)
select subtipo_delito, cast(txb as decimal)/cast(total as decimal)*100 AS Porcentaje
from Mes12
where subtipo_delito = 'Robo Automotor'
group by subtipo_delito, txb, total
ORDER BY Porcentaje desc;
----------------------------------------------------------
--Suma de Lesiones ocurridas Por Cada Dia durante el Mes de Enero 
create function Mes_Lesiones (@NumMes int)
returns table 
as 
return (select sum(cantidad_registrada) as CantidadxDia, MONTH(fecha) as Mes
from t_delitos_2016
where MONTH(fecha) = @NumMes
group by MONTH(fecha))
go
select * from Mes_Lesiones(3)  ----Seleccionar el Mes con su numero correspondiente del 1 al 12
----------------------------------------------------------
--Total de Delitos (LESIONES) por mes y su variacion a lo largo del a�o
with Por_Mes as (select MONTH(fecha) as Mes ,YEAR(fecha) as A�o , SUM (cantidad_registrada) as TotalxMes 
from t_delitos_2016
where tipo_delito = 'Lesiones'
group by MONTH(fecha), YEAR(fecha)),
Previo as (select *,
LAG(TotalxMes) OVER(ORDER BY Mes) as Mes_Anterior
from Por_Mes)
select *,((cast(TotalxMes as float)-cast(Mes_Anterior as float))/cast(Mes_Anterior as float))*100 AS Variacion
from Previo;
--------------------------------------------------------
--Promedio Diario de Delitos(Lesiones) y su variacion respectiva Mensual
with tablaparapromedio as (select month(fecha) as Mes,COUNT(distinct DAY(fecha)) as DiasdelMes,
SUM(cantidad_registrada) as CantidadxMes
from t_delitos_2016 
where tipo_delito = 'Lesiones'
group by MONTH(fecha)),
promedio_mensual as (select Mes, (CantidadxMes/DiasdelMes) as Promedio_Mes
from tablaparapromedio),
Tabla_Resagada as (select * , LAG(Promedio_Mes) over(order by Mes) as Resago
from promedio_mensual)
Select * , ((cast(Promedio_Mes as float) - cast(Resago as float))/ cast(Resago as float)) as Variacion
from Tabla_Resagada;
-------------------------------------------------------------
--Suma de Lesiones ocurridas Por Cada Dia durante el Mes de Enero 
with Dias as (select fecha, sum(cantidad_registrada) as CantidadxDia, tipo_delito
from t_delitos_2016
where tipo_delito = 'Lesiones'
group by fecha , tipo_delito),
DiasName as (SELECT *, DATENAME(WEEKDAY, fecha) as Dia
from Dias)
(select sum(CantidadxDia) TotalxDia_Mes1, tipo_delito, Dia
from DiasName
where Dia = 'Monday' and MONTH(fecha) = 1
group by tipo_delito, Dia
union
select sum(CantidadxDia), tipo_delito, Dia
from DiasName
where Dia = 'Tuesday' and MONTH(fecha) = 1
group by tipo_delito, Dia
union
select sum(CantidadxDia), tipo_delito, Dia
from DiasName
where Dia = 'Wednesday' and MONTH(fecha) = 1
group by tipo_delito, Dia
union
select sum(CantidadxDia), tipo_delito, Dia
from DiasName
where Dia = 'Thursday' and MONTH(fecha) = 1
group by tipo_delito, Dia
union
select sum(CantidadxDia), tipo_delito, Dia
from DiasName
where Dia = 'Friday' and MONTH(fecha) = 1
group by tipo_delito, Dia
union
select sum(CantidadxDia), tipo_delito, Dia
from DiasName
where Dia = 'Saturday' and MONTH(fecha) = 1
group by tipo_delito, Dia
union
select sum(CantidadxDia), tipo_delito, Dia
from DiasName
where Dia = 'Sunday' and MONTH(fecha) = 1
group by tipo_delito, Dia
);
--Agregar rank de dias 
-------------------------------------------------------------
--Promedio Anual de Lesiones Ocurridas Los Dias Lunes 
with Dias as (select fecha, sum(cantidad_registrada) as CantidadxDia, tipo_delito
from t_delitos_2016
where tipo_delito = 'Lesiones'
group by fecha , tipo_delito),
DiasName as (SELECT *, DATENAME(WEEKDAY, fecha) as Dia
from Dias),
lunes_anual as (select sum(CantidadxDia) Total_Lunes_Mensual, tipo_delito, Dia 
from DiasName
where Dia = 'Monday' 
group by tipo_delito, Dia, MONTH(fecha))
select (sum(cast(Total_Lunes_Mensual as float))/(select cast(COUNT(Dia) as float)
from DiasName
where Dia = 'Monday')) as PromedioAnual_Dias_Lunes
from lunes_anual;
-----------------------------------------------------------------
--Delitos Ocurridos por Mes cada 100Mil Habitantes
with CantidadxMes as (select sum(cantidad_registrada) as CantidadxDia, fecha, DATENAME(MONTH, fecha) as Mes
from t_delitos_2016
group by fecha),
Suma_Mensual as (select SUM(CantidadxDia) Suma_Mensual_Delitos, Mes
from CantidadxMes
group by Mes)
select *,(Suma_Mensual_Delitos/28.81) as Delitosx100Mil_Habitantes
from Suma_Mensual
group by Mes, Suma_Mensual_Delitos
order by Suma_Mensual_Delitos desc;
-----------------------------------------------------------------


