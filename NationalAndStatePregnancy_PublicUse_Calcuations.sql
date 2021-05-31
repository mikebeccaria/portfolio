/****** Exploring the "Pregnancies, Births and Abortions in the United States: National and State Trends by Age" data set found here https://osf.io/ndau2/  ******/
--Question: Which states had higher pregnancy rates for women under the age of 20 than the US average for years 2000-2017?

--loaded the csv data set into SQL

use Pregnancies_Abortions_US

--verify the population of population1544 totals the other columns
alter table [NSPP] add total_population as (populationlt20 + population2024 + population2529 + population3034 + population3539 + population40plus)
select [population1544],[total_population] from NSPP
--population1544	total_population
--945017	945017
--963462	963462
--979413	979413
--970239	970239
--numbers check out checks out - drop the column
ALTER TABLE [dbo].[NSPP] DROP COLUMN [total_population]

--STEP 1: What are the averages for pregnancy rates for those years?
select [year],[state], dbo.NSPP.pregncyratelt20
from NSPP
where [year] in 
	(SELECT DISTINCT n = number 
	FROM master..[spt_values] 
	WHERE number BETWEEN 2000 AND 2017)
order by [year] desc
--year	state	pregncyratelt20
--2017	AL	38.7
--2017	AK	34.5
--2017	AZ	32.6
--2017	AR	44.6
--2017	CA	29.1
--2017	CO	26.5

--This is fine, but it needs to be more like a pivot table rather than a series

--STEP 2 - Set the data with the year as column headers and the state as rows
SELECT [state],[2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012],[2013],[2014],[2015],[2016],[2017]
FROM
(
	select [year],[state], [pregncyratelt20]
	from NSPP
	where [year] in 
		(SELECT DISTINCT n = number 
		FROM master..[spt_values] 
		WHERE number BETWEEN 2005 AND 2017)
) AS Src
PIVOT
	(
		SUM([pregncyratelt20])
		FOR [year] IN ([2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012],[2013],[2014],[2015],[2016],[2017])
	) AS Pvt
order by state
--state	2005	2006	2007	2008	2009	2010	2011	2012	2013	2014	2015	2016	2017
--AK	66.3	67.2	67.8	70.2	68	65.1	59.9	55.7	48.7	45	44.4	40.2	34.5
--AL	72.5	77.1	76.6	74.9	70.8	64.2	60	56.5	49.1	46	43	40.5	38.7
--AR	81.5	85.9	84.8	84.1	80.9	74.2	69.3	62.9	58.9	53.3	50.9	46.6	44.6
--AZ	91.7	92.7	89.8	83.8	72.2	61.4	56.9	53.6	47.4	42.6	38.1	35.1	32.6

--better - on our way

--STEP 3 - Calculate the difference in values between that table and the values for the US - let's start with one column
--I will make a temporary table that includes the US values only so we can run comparisons against that for each state
	drop table if exists us_pregnancy_values_temp
	create table us_pregnancy_values_temp ([state] nvarchar(255), [year] int, [pregncyratelt20] float, [pregncyratelt20diff] decimal(8,2))
	
	--insert the US data
	insert into dbo.us_pregnancy_values_temp ([state],[year],[pregncyratelt20]) 
		select [state],[year],dbo.NSPP.pregncyratelt20  
		from NSPP
		where state = 'US'

	--look at the data
	select * from us_pregnancy_values_temp
--state	year	pregncyratelt20	pregncyratelt20diff
--US	1973	99.3	NULL
--US	1974	101.9	NULL
--US	1975	104.3	NULL
--US	1976	104.4	NULL
--US	1977	107.9	NULL

--STEP 4 - after thinking about this a bit, I need to create some temp table variables to cycle through and add values to our table on the differences. Computed columns won't work because you can't compute differences between rows (AK and US for example). I need to create new column data

--create temp table variables for state and years so I can cycle through them
DECLARE @tmp_states TABLE (RowID int not null primary key identity(1,1), [state] nvarchar(255))
DECLARE @tmp_years TABLE (RowID int not null primary key identity(1,1), [year] int)
	
--populate temp states and years table with values from NSPP
insert into @tmp_states
	select distinct [state] from NSPP
--state
--AK
--AL
--AR
--AZ

insert into @tmp_years
	select distinct [year] from NSPP order by [year] asc
--year
--1973
--1974
--1975
--1976
--1977
	
--create year and state counts
DECLARE @yearcount int = (select COUNT([year]) from @tmp_years)
--45
DECLARE @statecount int = (select COUNT([state]) from @tmp_states)
--52 - not 50 because it includes US and Washington DC

--Set our counts to 1 to allow the loop to cycle through all of the values
DECLARE @year_rowcount int = 1, @state_rowcount int = 1

--Start nested loop
WHILE @year_rowcount <= @yearcount
BEGIN
	WHILE @state_rowcount <= @statecount
	BEGIN
		insert into dbo.us_pregnancy_values_temp
			select [state],[year],[pregncyratelt20],[pregncyratelt20diff] = 

				--calculate the difference between the state value for a given year and the US value for a given year and use the @state_rowcount and @year_rowcount to pull the right values from the tables
					( 
						select [pregncyratelt20] from NSPP where [state] = (select [state] from @tmp_states where RowID = @state_rowcount) and [year] = (select [year] from @tmp_years where RowID = @year_rowcount)
					) - (
						select [pregncyratelt20] from NSPP where [state] = 'US' and [year] = (select [year] from @tmp_years where RowID = @year_rowcount)
					)
			from NSPP
			where
				[state] = (select [state] from @tmp_states where RowID = @state_rowcount)
				and
				[year] = (select [year] from @tmp_years where RowID = @year_rowcount)
		--print('state: ' + CONVERT(VARCHAR,@state_rowcount))
		SET @state_rowcount = @state_rowcount + 1
	END	
	SET @year_rowcount = @year_rowcount + 1
	SET @state_rowcount = 1
	--print('year: ' + CONVERT(VARCHAR, @year_rowcount))
END
--state	year	pregncyratelt20	pregncyratelt20diff
--US	1985	113	0.00
--US	1986	110.5	0.00
--US	1987	110.3	0.00
--AK	1988	108.1	-7.00
--AL	1988	114.3	-0.80
--AR	1988	119.5	4.40

--STEP 5 - Create the pivot table from the new values by year and order the values by the 2017 data
SELECT [state],[2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012],[2013],[2014],[2015],[2016],[2017]
FROM
(
	select [year],[state], [pregncyratelt20diff]
	from us_pregnancy_values_temp
	where [year] in 
		(SELECT DISTINCT n = number 
		FROM master..[spt_values] 
		WHERE number BETWEEN 2005 AND 2017)
	
) AS Src
PIVOT
	(
		SUM([pregncyratelt20diff])
		FOR [year] IN ([2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012],[2013],[2014],[2015],[2016],[2017])
	) AS Pvt
order by [2017]
--2005	2006	2007	2008	2009	2010	2011	2012	2013	2014	2015	2016	2017
---73.00	-76.20	-72.60	-72.00	-70.00	-60.80	-54.60	-48.00	-43.40	-39.40	-34.40	-32.00	-31.00
---47.60	-50.80	-47.80	-52.60	-46.60	-43.80	-41.00	-37.00	-38.60	-35.40	-34.00	-31.00	-29.60
---63.60	-65.40	-63.40	-61.20	-64.40	-53.00	-43.20	-39.00	-31.60	-27.80	-31.20	-26.80	-27.40
---54.60	-53.40	-50.60	-52.60	-50.80	-45.60	-43.20	-38.60	-34.60	-31.20	-29.80	-26.00	-23.00
