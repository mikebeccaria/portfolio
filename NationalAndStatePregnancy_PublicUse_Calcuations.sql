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
order by [2017] desc
--state	2005	2006	2007	2008	2009	2010	2011	2012	2013	2014	2015	2016	2017
--DC	44.70	44.50	35.70	46.70	38.20	34.10	28.90	21.90	25.60	19.70	11.80	9.40	17.00
--AR	11.30	14.00	13.30	14.60	16.00	15.40	15.90	13.80	14.80	13.30	14.20	13.00	13.20
--MS	15.00	23.20	26.50	22.40	23.10	19.50	18.00	15.90	15.20	13.20	11.70	11.40	12.00
--LA	-1.20	7.20	10.70	12.60	13.10	12.30	14.00	12.90	11.60	10.90	11.90	11.00	10.60
--NM	24.50	25.50	28.50	25.10	27.00	22.80	19.70	20.60	18.30	14.80	14.00	11.80	10.60
--OK	5.20	7.40	10.40	11.30	15.50	11.70	12.40	15.90	14.60	13.00	10.00	10.70	8.90
--TX	18.60	20.50	20.30	20.90	21.20	18.40	15.50	15.00	14.50	12.50	11.30	9.70	7.80
--KY	-4.60	-0.40	1.00	2.50	3.60	4.50	5.80	6.50	8.60	7.80	6.70	7.80	7.60
--AL	2.30	5.20	5.10	5.40	5.90	5.40	6.60	7.40	5.00	6.00	6.30	6.90	7.30
--WV	-9.70	-9.90	-6.20	-4.10	3.50	6.60	10.90	11.30	10.30	10.40	6.90	7.30	6.00
--TN	8.50	6.50	6.70	7.50	6.10	4.80	5.70	6.40	6.00	7.40	6.60	5.90	5.80
--NV	24.70	23.60	21.30	17.00	13.40	11.40	9.40	8.10	6.10	8.40	9.20	7.00	5.60
--GA	10.60	9.90	10.90	10.40	9.50	6.90	7.40	5.20	4.40	4.60	3.70	3.90	3.60
--WY	-5.20	-3.30	1.50	-1.20	-2.70	-2.20	-0.90	1.10	-1.90	3.60	3.90	3.70	3.60
--AK	-3.90	-4.70	-3.70	0.70	3.10	6.30	6.50	6.60	4.60	5.00	7.70	6.60	3.10
--SC	7.20	9.10	9.30	8.30	8.00	8.30	6.20	6.30	4.60	3.70	3.60	2.70	2.60
--NY	7.20	4.10	2.80	3.90	4.80	6.00	6.30	4.40	2.50	2.90	2.30	2.00	2.20
--MO	-6.80	-5.00	-4.30	-3.90	-4.30	-3.70	-2.20	-1.40	-0.40	-1.10	-0.50	0.50	1.70
--IN	-8.40	-11.20	-9.20	-10.00	-6.10	-5.00	-4.10	-2.80	-1.70	-0.40	0.30	0.10	1.60
--AZ	21.50	20.80	18.30	14.30	7.30	2.60	3.50	4.50	3.30	2.60	1.40	1.50	1.20
--HI	2.40	5.40	6.00	8.70	7.10	7.50	8.60	5.60	1.20	1.00	-0.70	-0.90	1.00
--FL	9.50	8.10	8.50	5.40	4.20	3.30	3.70	3.70	2.40	2.30	1.70	1.60	0.90
--NC	5.10	4.20	4.50	4.30	3.90	1.70	0.50	0.60	1.00	0.80	0.20	-0.30	0.90
--MT	-14.00	-13.60	-16.00	-9.70	-6.60	-5.10	-6.30	-4.40	-2.40	-0.30	1.20	0.90	0.80
--DE	6.80	10.30	15.00	14.70	5.60	10.50	8.00	0.70	2.70	0.70	-0.80	2.70	0.50
--MD	-2.50	-4.60	-3.90	-4.40	-2.10	0.10	3.20	-1.40	-1.20	-1.10	-1.10	0.00	0.20
--US	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
