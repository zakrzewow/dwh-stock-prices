USE [AWZS]
GO
/****** Object:  Table [dbo].[FactStockDailyPrice]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactStockDailyPrice](
	[StockKey] [int] NOT NULL,
	[DateKey] [int] NOT NULL,
	[LocalCurrencyKey] [int] NOT NULL,
	[OpenPrice_LocalCurrency] [money] NOT NULL,
	[HighPrice_LocalCurrency] [money] NOT NULL,
	[LowPrice_LocalCurrency] [money] NOT NULL,
	[ClosePrice_LocalCurrency] [money] NOT NULL,
	[OpenPrice_PLN] [money] NOT NULL,
	[HighPrice_PLN] [money] NOT NULL,
	[LowPrice_PLN] [money] NOT NULL,
	[ClosePrice_PLN] [money] NOT NULL,
	[VolumeAmount] [bigint] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[LastVolumeAmountPctChange]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LastVolumeAmountPctChange] AS
WITH date_rn AS (
	SELECT DateKey, ROW_NUMBER() OVER(ORDER BY DateKey DESC) rn FROM [AWZS].[dbo].[FactStockDailyPrice]
	GROUP BY DateKey
),
last_and_previous_price AS (
	SELECT 
		StockKey,
		fsdp.DateKey,
		VolumeAmount,
		LAG(VolumeAmount, 1, NULL) 
			OVER (PARTITION BY StockKey ORDER BY fsdp.DateKey ASC) VolumeAmount__Previous,
		rn
	FROM [AWZS].[dbo].[FactStockDailyPrice] fsdp
	JOIN date_rn ON date_rn.DateKey = fsdp.DateKey AND date_rn.rn <= 2
)
SELECT TOP 100
	StockKey,
	DateKey,
	VolumeAmount,
	ROUND(1. * VolumeAmount / VolumeAmount__Previous - 1, 4) AS PctChange
FROM last_and_previous_price
WHERE rn = 1 AND VolumeAmount__Previous > 0
ORDER BY ABS(1. * VolumeAmount / VolumeAmount__Previous - 1) DESC
GO
/****** Object:  View [dbo].[LastStockPricePctChange]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LastStockPricePctChange] AS
WITH date_rn AS (
	SELECT DateKey, ROW_NUMBER() OVER(ORDER BY DateKey DESC) rn FROM [AWZS].[dbo].[FactStockDailyPrice]
	GROUP BY DateKey
),
last_and_previous_price AS (
	SELECT 
		StockKey,
		fsdp.DateKey,
		ClosePrice_LocalCurrency,
		ClosePrice_PLN,
		LAG(ClosePrice_LocalCurrency, 1, NULL) 
			OVER (PARTITION BY StockKey ORDER BY fsdp.DateKey ASC) ClosePrice_LocalCurrency__Previous,
		rn
	FROM [AWZS].[dbo].[FactStockDailyPrice] fsdp
	JOIN date_rn ON date_rn.DateKey = fsdp.DateKey AND date_rn.rn <= 2
)
SELECT TOP 100
	StockKey,
	DateKey,
	ClosePrice_LocalCurrency,
	ClosePrice_PLN,
	ClosePrice_LocalCurrency / ClosePrice_LocalCurrency__Previous - 1 AS PctChange
FROM last_and_previous_price
WHERE rn = 1 AND ClosePrice_LocalCurrency__Previous > 0
ORDER BY ABS(ClosePrice_LocalCurrency / ClosePrice_LocalCurrency__Previous - 1) DESC;
GO
/****** Object:  Table [dbo].[DimCurrency]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimCurrency](
	[CurrencyKey] [int] IDENTITY(1,1) NOT NULL,
	[CurrencyName] [nvarchar](50) NOT NULL,
	[CurrencyCode] [nvarchar](3) NOT NULL,
 CONSTRAINT [PK_DimLocalCurrency] PRIMARY KEY CLUSTERED 
(
	[CurrencyKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DimDate]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimDate](
	[DateKey] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[DayNumber] [tinyint] NOT NULL,
	[WeekDayNumber] [tinyint] NOT NULL,
	[WeekDayName] [varchar](10) NOT NULL,
	[WeekendFlag] [char](3) NOT NULL,
	[MonthNumber] [tinyint] NOT NULL,
	[MonthName] [varchar](10) NOT NULL,
	[QuarterNumber] [tinyint] NOT NULL,
	[QuarterName] [varchar](6) NOT NULL,
	[YearNumber] [int] NOT NULL,
 CONSTRAINT [PK__DimDate__40DF45E3413A9F84] PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DimStock]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DimStock](
	[StockKey] [int] IDENTITY(1,1) NOT NULL,
	[StockCurrencyKey] [int] NOT NULL,
	[StockSymbol] [nvarchar](50) NOT NULL,
	[BloombergTicker] [nvarchar](50) NOT NULL,
	[YahooTicker] [nvarchar](50) NOT NULL,
	[StockName] [nvarchar](100) NOT NULL,
	[IndustryName] [nvarchar](50) NOT NULL,
	[SectorName] [nvarchar](50) NOT NULL,
	[CountryName] [nvarchar](50) NOT NULL,
	[BusinessSummary] [nvarchar](4000) NOT NULL,
	[ValidFromDate] [datetime] NOT NULL,
	[ValidToDate] [datetime] NOT NULL,
	[ActiveFlag] [bit] NOT NULL,
 CONSTRAINT [PK_DimStock] PRIMARY KEY CLUSTERED 
(
	[StockKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactCurrencyConversion]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactCurrencyConversion](
	[ConversionDateKey] [int] NOT NULL,
	[SourceCurrencyKey] [int] NOT NULL,
	[SourceCurrencyToPLN_ExchangeRate] [decimal](10, 4) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactCurrencyConversionStaging]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactCurrencyConversionStaging](
	[ConversionDateKey] [int] NOT NULL,
	[SourceCurrencyKey] [int] NOT NULL,
	[SourceCurrencyToPLN_ExchangeRate] [decimal](10, 4) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactFinancialIndicator]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactFinancialIndicator](
	[StockKey] [int] NOT NULL,
	[QuarterDateKey] [int] NOT NULL,
	[LocalCurrencyKey] [int] NOT NULL,
	[NetIncome_LocalCurrency] [money] NOT NULL,
	[NetIncome_PLN] [money] NOT NULL,
	[EBITDA_LocalCurrency] [money] NOT NULL,
	[EBITDA_PLN] [money] NOT NULL,
	[Revenue_LocalCurrency] [money] NOT NULL,
	[Revenue_PLN] [money] NOT NULL,
	[ProfitMargin] [decimal](18, 4) NOT NULL,
	[OperatingMargin] [decimal](18, 4) NOT NULL,
	[ReturnOnAsset] [decimal](18, 4) NOT NULL,
	[CurrentRatio] [decimal](18, 4) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactFinancialIndicatorStaging]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactFinancialIndicatorStaging](
	[StockKey] [int] NOT NULL,
	[QuarterDateKey] [int] NOT NULL,
	[LocalCurrencyKey] [int] NOT NULL,
	[NetIncome_LocalCurrency] [money] NOT NULL,
	[NetIncome_PLN] [money] NOT NULL,
	[EBITDA_LocalCurrency] [money] NOT NULL,
	[EBITDA_PLN] [money] NOT NULL,
	[Revenue_LocalCurrency] [money] NOT NULL,
	[Revenue_PLN] [money] NOT NULL,
	[ProfitMargin] [decimal](18, 4) NOT NULL,
	[OperatingMargin] [decimal](18, 4) NOT NULL,
	[ReturnOnAsset] [decimal](18, 4) NOT NULL,
	[CurrentRatio] [decimal](18, 4) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FactStockDailyPriceStaging]    Script Date: 12.06.2023 06:23:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactStockDailyPriceStaging](
	[StockKey] [int] NOT NULL,
	[DateKey] [int] NOT NULL,
	[LocalCurrencyKey] [int] NOT NULL,
	[OpenPrice_LocalCurrency] [money] NOT NULL,
	[HighPrice_LocalCurrency] [money] NOT NULL,
	[LowPrice_LocalCurrency] [money] NOT NULL,
	[ClosePrice_LocalCurrency] [money] NOT NULL,
	[OpenPrice_PLN] [money] NOT NULL,
	[HighPrice_PLN] [money] NOT NULL,
	[LowPrice_PLN] [money] NOT NULL,
	[ClosePrice_PLN] [money] NOT NULL,
	[VolumeAmount] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DimStock]  WITH CHECK ADD  CONSTRAINT [FK_DimStock_DimCurrency] FOREIGN KEY([StockCurrencyKey])
REFERENCES [dbo].[DimCurrency] ([CurrencyKey])
GO
ALTER TABLE [dbo].[DimStock] CHECK CONSTRAINT [FK_DimStock_DimCurrency]
GO
ALTER TABLE [dbo].[FactCurrencyConversion]  WITH CHECK ADD  CONSTRAINT [FK_FactCurrencyConversion_DimDate] FOREIGN KEY([ConversionDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
GO
ALTER TABLE [dbo].[FactCurrencyConversion] CHECK CONSTRAINT [FK_FactCurrencyConversion_DimDate]
GO
ALTER TABLE [dbo].[FactCurrencyConversion]  WITH CHECK ADD  CONSTRAINT [FK_FactCurrencyConversion_DimLocalCurrency] FOREIGN KEY([SourceCurrencyKey])
REFERENCES [dbo].[DimCurrency] ([CurrencyKey])
GO
ALTER TABLE [dbo].[FactCurrencyConversion] CHECK CONSTRAINT [FK_FactCurrencyConversion_DimLocalCurrency]
GO
ALTER TABLE [dbo].[FactFinancialIndicator]  WITH CHECK ADD  CONSTRAINT [FK_FactFinancialIndicator_DimCurrency] FOREIGN KEY([LocalCurrencyKey])
REFERENCES [dbo].[DimCurrency] ([CurrencyKey])
GO
ALTER TABLE [dbo].[FactFinancialIndicator] CHECK CONSTRAINT [FK_FactFinancialIndicator_DimCurrency]
GO
ALTER TABLE [dbo].[FactFinancialIndicator]  WITH CHECK ADD  CONSTRAINT [FK_FactFinancialIndicator_DimDate] FOREIGN KEY([QuarterDateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
GO
ALTER TABLE [dbo].[FactFinancialIndicator] CHECK CONSTRAINT [FK_FactFinancialIndicator_DimDate]
GO
ALTER TABLE [dbo].[FactFinancialIndicator]  WITH CHECK ADD  CONSTRAINT [FK_FactFinancialIndicator_DimStock] FOREIGN KEY([StockKey])
REFERENCES [dbo].[DimStock] ([StockKey])
GO
ALTER TABLE [dbo].[FactFinancialIndicator] CHECK CONSTRAINT [FK_FactFinancialIndicator_DimStock]
GO
ALTER TABLE [dbo].[FactStockDailyPrice]  WITH CHECK ADD  CONSTRAINT [FK_FactOHLC_DimDate] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDate] ([DateKey])
GO
ALTER TABLE [dbo].[FactStockDailyPrice] CHECK CONSTRAINT [FK_FactOHLC_DimDate]
GO
ALTER TABLE [dbo].[FactStockDailyPrice]  WITH CHECK ADD  CONSTRAINT [FK_FactOHLC_DimLocalCurrency] FOREIGN KEY([LocalCurrencyKey])
REFERENCES [dbo].[DimCurrency] ([CurrencyKey])
GO
ALTER TABLE [dbo].[FactStockDailyPrice] CHECK CONSTRAINT [FK_FactOHLC_DimLocalCurrency]
GO
ALTER TABLE [dbo].[FactStockDailyPrice]  WITH CHECK ADD  CONSTRAINT [FK_FactOHLC_DimStock] FOREIGN KEY([StockKey])
REFERENCES [dbo].[DimStock] ([StockKey])
GO
ALTER TABLE [dbo].[FactStockDailyPrice] CHECK CONSTRAINT [FK_FactOHLC_DimStock]
GO
