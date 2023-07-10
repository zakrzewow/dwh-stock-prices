--
-- TESTY FUNKCJONALNE OPISANE S¥ NA KOÑCU DOKUMENTACJI!
-- w dokumentacji znajduj¹ siê te¿ zrzuty ekranów potwierdzaj¹ce wykonanie testów


-- TEST 1: zgodnoœæ wielkoœci pobranych danych i danych wstawionych do hurtowni
-- wymiar: waluta
SELECT * FROM [AWZS].[dbo].[DimCurrency]

-- wymiar: spó³ka
SELECT StockKey, YahooTicker, ValidFromDate, ValidToDate, ActiveFlag FROM [AWZS].[dbo].[DimStock] 
WHERE YahooTicker IN ('UBSG.SW', 'NESN.SW', 'NOVN.SW', 'ROG.SW', 'KOMB.PR')
ORDER BY YahooTicker, ValidFromDate

SELECT COUNT(*) AS row_count, COUNT(DISTINCT YahooTicker) AS stock_count FROM [AWZS].[dbo].[DimStock] 

-- fakt: kurs wymiany walut
DELETE FROM [AWZS].[dbo].[FactCurrencyConversion]
WHERE ConversionDateKey >= '20230101'

SELECT COUNT(*) FROM [AWZS].[dbo].[FactCurrencyConversion]

-- fakt: dzienne ceny akcji spó³ki
DELETE FROM [AWZS].[dbo].[FactStockDailyPrice]
WHERE DateKey >= '20230101'

SELECT COUNT(*) FROM [AWZS].[dbo].[FactStockDailyPrice]

-- fakt: odczyt wskaŸników finansowych spó³ki
DELETE FROM [AWZS].[dbo].[FactFinancialIndicator]
WHERE QuarterDateKey >= '20200101'

SELECT COUNT(*) FROM [AWZS].[dbo].[FactFinancialIndicator]


-- TEST 2: Unikalnoœæ rekordów w wymiarze spó³ki
SELECT 
	COUNT(*) AS row_count,
	COUNT(DISTINCT StockKey) AS no_unique_stock_key,
	COUNT(DISTINCT StockName) AS stock_count 
FROM [AWZS].[dbo].[DimStock]


-- TEST 3: Wiarygodnoœæ danych w tabeli faktów z dziennymi cenami akcji spó³ek
-- test, czy ceny akcji i wolumen to liczby nieujemne
SELECT 
	COUNT(*) AS incorrect_records_count
FROM [AWZS].[dbo].[FactStockDailyPrice]
WHERE 
	OpenPrice_LocalCurrency < 0		OR
	HighPrice_LocalCurrency < 0		OR
	LowPrice_LocalCurrency < 0		OR
	ClosePrice_LocalCurrency < 0	OR
	OpenPrice_PLN < 0				OR
	HighPrice_PLN < 0				OR
	LowPrice_PLN < 0				OR
	ClosePrice_PLN < 0				OR
	VolumeAmount < 0

-- test gwa³townych zmian cen akcji
WITH tmp AS (
SELECT 
	StockKey,
	DateKey,
	ClosePrice_LocalCurrency AS ClosePrice,
	LAG(ClosePrice_LocalCurrency, 1, NULL) 
		OVER (PARTITION BY StockKey ORDER BY DateKey DESC) ClosePrice_NextDay
FROM [AWZS].[dbo].[FactStockDailyPrice]
WHERE ClosePrice_LocalCurrency > 0   -- b³êdy zaokr¹gleñ
)
SELECT 
	DimStock.YahooTicker,
	DimDate.Date,
	ClosePrice,
	ClosePrice_NextDay,
	ClosePrice_NextDay / ClosePrice - 1 AS Ratio
FROM tmp
JOIN DimStock ON DimStock.StockKey = tmp.StockKey
JOIN DimDate ON DimDate.DateKey = tmp.DateKey
WHERE ClosePrice_NextDay IS NOT NULL
ORDER BY ClosePrice_NextDay / ClosePrice - 1 DESC


-- TEST 4: Wiarygodna czêstotliwoœæ danych w tabelach faktowych
-- czêstotliwoœæ rekordów w tabeli z dziennymi cenami akcji spó³ek
WITH tmp AS (
SELECT 
	StockKey,
	DATEDIFF(
		DAY,
		dd.Date,
		LAG(dd.Date, 1, NULL) 
			OVER (PARTITION BY StockKey ORDER BY fsdp.DateKey DESC)
	) AS RecordDateDiff
FROM [AWZS].[dbo].[FactStockDailyPrice] fsdp
JOIN [AWZS].[dbo].[DimDate] dd ON fsdp.DateKey = dd.DateKey
)
SELECT
	ds.YahooTicker,
	MAX(RecordDateDiff) RecordDateDiff
FROM tmp
JOIN [AWZS].[dbo].[DimStock] ds ON ds.StockKey = tmp.StockKey
WHERE RecordDateDiff IS NOT NULL
GROUP BY ds.YahooTicker
ORDER BY RecordDateDiff DESC

-- czêstotliwoœæ rekordów w tabeli z kursami wymiany walut
WITH tmp AS (
SELECT 
	SourceCurrencyKey,
	DATEDIFF(
		DAY,
		dd.Date,
		LAG(dd.Date, 1, NULL) 
			OVER (PARTITION BY SourceCurrencyKey ORDER BY DateKey DESC)
	) AS RecordDateDiff
FROM [AWZS].[dbo].[FactCurrencyConversion] fcc
JOIN [AWZS].[dbo].[DimDate] dd ON fcc.ConversionDateKey = dd.DateKey
)
SELECT 
	dc.CurrencyCode,
	MAX(RecordDateDiff) RecordDateDiff
FROM tmp
JOIN [AWZS].[dbo].[DimCurrency] dc ON dc.CurrencyKey = tmp.SourceCurrencyKey
WHERE RecordDateDiff IS NOT NULL
GROUP BY dc.CurrencyCode
ORDER BY RecordDateDiff DESC
