-- Data Cleaning for the Dow historical records from 2000 - 2020
-- Date: 6/4/2022
-- Author: Handerson Coq


--------------
-- The dow_jones_companies dataset has the list of all the companies being part of the DJIA.
-- A total of 30 companies

SELECT *
FROM dow_jones_companies;

------------
-- Checking that there are 30 stocks in the dow_historic dataset

SELECT COUNT(DISTINCT(stock))
FROM dow_historic

------------------------
-- Checking for nulls

SELECT *
FROM dow_historic
WHERE "stock" IS NULL OR
	  "date" IS NULL OR
	  "open" IS NULL OR
	  "high" IS NULL OR
	  "low" IS NULL OR
	  "close" IS NULL OR
	  adj_close IS NULL OR
	  volume IS NULL OR
	  dividend IS NULL OR
	  split IS NULL OR
	  company IS NULL

-------------------------------
-- Checking the dates

SELECT DISTINCT(date)
FROM dow_historic
ORDER BY 1

SELECT DISTINCT(DATENAME(YEAR, date)) as year
FROM dow_historic
ORDER BY 1

-- checking for weekends (Satudays and Sundays)

SELECT DISTINCT(FORMAT(date, 'dddd')) as day 
FROM dow_historic
ORDER BY 1

--------------------------------
-- Checking for duplicates

/* 
There're supposed to be 21 years, 5 days a week
for a total of 5*52*21 = 5460 
So 5460 records or less (accounting for holidays) for each company
*/

SELECT COUNT(*)		--> Total number of record for all companies combined: 150503
FROM dow_historic

SELECT stock, COUNT(DISTINCT(date)) as number_of_unique_records,
COUNT(date) as number_of_total_records
FROM dow_historic
GROUP BY stock		--> Checking that total number of records for each company match 
					--  total number of unique records (5284)

-- checking that # of open's  = # of close's

SELECT stock, COUNT("open") as number_of_open,
COUNT("close") as number_of_close
FROM dow_historic
GROUP BY stock
HAVING COUNT("open") <> COUNT("close")		

------------------------------------
-- Checking for missing records			

SELECT stock, company, COUNT(date) as number_of_records
FROM dow_historic							
GROUP BY stock, company						
HAVING COUNT(date) != 5284		--> (Dow Inc: 452, Salesforce: 4162, Visa: 3221)

-- Checking every year records for each of these 3 comapnies

SELECT DISTINCT(DATENAME(YEAR, date)) as year, company
FROM dow_historic
WHERE company = 'Dow Inc.' OR company = 'Salesforce' OR company = 'Visa'
ORDER BY 2

/*
Reason for missing values:
these three companies sarted trading later than the others 
*/

-------------
-- Even though these companies entered the DJIA at a later year,
-- their trading data started at an earlier date

SELECT DISTINCT(DATENAME(YEAR, A.date)) as record_years, A.stock, B.Company, B.[Year Added]
FROM dow_historic A RIGHT JOIN dow_jones_companies B
ON A.stock = B.Symbol
WHERE B.company = 'Dow Inc.' OR B.company = 'Salesforce' OR B.company = 'Visa'
ORDER BY 2

-------------
-- Adding the company names to the dow_historic table

SELECT A.*, B.Company as company
FROM dow_historic A INNER JOIN dow_jones_companies B
ON A.stock = B.Symbol;

ALTER TABLE dow_historic
ADD company NVARCHAR(50);

UPDATE dow_historic
SET company = B.Company
FROM dow_historic A INNER JOIN dow_jones_companies B
ON A.stock = B.Symbol;


----- END OF DATA CLEANING -----

