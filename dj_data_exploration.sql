-- Data exploration for the DJIA companies' historical records from 2000 - 2020
-- Date: 6/8/2022
-- Author: Handerson Coq


--#############################################################################################

-- The dow_historic dataset has stock records for all 30 companies in the DJIA index.
-- The adjusted closing price will be used instead of the simple closing price
-- Some calculations performed: 
--	Average & Max closing price per year, 
--	Average traded volume per year, 
--	Yearly Volume Price Trend
--	Daily and annualized volatility (21-year history)

--#############################################################################################


-- Average & max closing price per year for each stock

SELECT DATENAME(YEAR, date) AS year, stock,
	AVG(adj_close) AS avgClosingPrice, MAX(adj_close) AS maxClosingPrice
FROM dow_historic
GROUP BY DATENAME(YEAR, date), stock
ORDER BY 1;

-- Average traded volume per year for each stock

SELECT DATENAME(YEAR, date) AS year, stock,
	AVG(CAST(volume AS BIGINT)) AS avgVolume
FROM dow_historic
GROUP BY DATENAME(YEAR, date), stock
ORDER BY 1;

-- Number of times a stock has split since 2000

SELECT stock, COUNT(split) AS number
FROM dow_historic
WHERE split != 1		-- spli is a ratio, 1 means no split
GROUP BY  stock
ORDER BY 2 DESC;

-- The most traded stock by year, based on volume

SELECT year, stock, MAX(avgVolume) AS volumeTraded
FROM 
(
	SELECT DATENAME(YEAR, date) AS year, stock,
	AVG(CAST(volume AS BIGINT)) AS avgVolume,
	RANK() OVER (PARTITION BY DATENAME(YEAR, date) ORDER BY AVG(CAST(volume AS BIGINT)) DESC) AS rank
	FROM dow_historic
	GROUP BY DATENAME(YEAR, date), stock
) average
WHERE rank = 1
GROUP BY year, stock

-- Stock with the highest closing price, by year

SELECT year, stock, MAX(avg_close) AS maxAvg_price
FROM 
(
	SELECT DATENAME(YEAR, date) AS year, stock,
	AVG(adj_close) AS avg_close,
	RANK() OVER (PARTITION BY DATENAME(YEAR, date) ORDER BY AVG(adj_close) DESC) AS rank
	FROM dow_historic
	GROUP BY DATENAME(YEAR, date), stock
) average
WHERE rank = 1
GROUP BY year, stock;

-- Yearly Volume Price Trend (closing price change*volume)

WITH cte_current AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS number, date, stock, adj_close, volume
FROM dow_historic
),
cte_previous AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS number, date, stock, adj_close, volume
FROM dow_historic
WHERE date < (SELECT MAX(date) FROM dow_historic)
),
cte_volumePrice AS
(
SELECT T1.date, T1.stock, ABS(((T1.adj_close/T2.adj_close)-1))*T1.volume AS volumePrice
FROM cte_current T1, cte_previous T2
WHERE T1.number = T2.number AND T1.stock = T2.stock
)
SELECT DATENAME(YEAR, date) AS year, stock, AVG(volumePrice) AS volumePriceTrend
FROM cte_volumePrice
GROUP BY DATENAME(YEAR, date), stock
ORDER BY 1

-- Calculate Daily and annualized volatility for each stock

--###################################################################################################

-- 1. Declare a variable table for "current" records

DECLARE @table1 TABLE 
(number INT, date DATE, stock NVARCHAR(50), closing_price FLOAT);

INSERT INTO @table1
SELECT ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS number, date, stock, adj_close
FROM dow_historic;

-- 2. Declare another variable table for "previous" record

DECLARE @table2 TABLE 
(number INT, date DATE, stock NVARCHAR(50), closing_price FLOAT);

INSERT INTO @table2
SELECT ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS number, date, stock, adj_close
FROM dow_historic
WHERE date < (SELECT MAX(date) FROM dow_historic);

-- 3. Calculate the standard deviation of the log change in closing price by stock

SELECT stock, STDEV(log_table.log_change)*100 AS daily_vol, STDEV(log_table.log_change)*SQRT(252)*100 as annual_vol FROM
(
SELECT stock, LOG(T1.closing_price/(SELECT closing_price FROM @table2 AS T2 WHERE T1.number = T2.number AND T1.stock = T2.stock)) AS log_change
FROM @table1 AS T1
) AS log_table
GROUP BY stock
ORDER BY 3 desc

--###################################################################################################

-- Historical trend of annualized volatility

WITH cte_current AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS number, date, stock, adj_close
FROM dow_historic
),
cte_previous AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS number, date, stock, adj_close
FROM dow_historic
WHERE date < (SELECT MAX(date) FROM dow_historic)
),
cte_volumePrice AS
(
SELECT T1.date, T1.stock, LOG(T1.adj_close/T2.adj_close) AS logChange
FROM cte_current T1, cte_previous T2
WHERE T1.number = T2.number AND T1.stock = T2.stock
)
SELECT DATENAME(YEAR, date) AS year, stock, STDEV(logChange)*SQRT(252)*100 as annualVol
FROM cte_volumePrice
GROUP BY DATENAME(YEAR, date), stock
ORDER BY 1, 3 DESC
