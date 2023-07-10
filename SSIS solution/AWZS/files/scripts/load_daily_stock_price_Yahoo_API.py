import yfinance as yf
import pandas as pd
from datetime import date


def main() -> pd.DataFrame:
    FORMAT = "%Y-%m-%d"

    last_daily_stock_price_fact_date = pd.read_csv("last_daily_stock_price_fact_date.csv")
    last_daily_stock_price_fact_date["Date"] = pd.to_datetime(last_daily_stock_price_fact_date["Date"], format="%Y-%m-%d")
    last_daily_stock_price_fact_date["Date"] += pd.Timedelta(days=1)
    last_daily_stock_price_fact_date["Date"] = last_daily_stock_price_fact_date["Date"].dt.date

    frames = []

    for yahoo_ticker, date_ in last_daily_stock_price_fact_date.itertuples(index=False, name=None):

        start_date_str = date_.strftime(FORMAT)
        end_date_str = date.today().strftime(FORMAT)

        try:
            frame = yf.download(yahoo_ticker, start=start_date_str, end=end_date_str, interval="1d")
            frame = frame.reset_index().assign(
                YahooTicker=yahoo_ticker,
                DateKey=lambda x: x["Date"].dt.strftime("%Y%m%d")
            ).drop(columns=["Date", "Adj Close"]).rename(
                    columns={
                        "Open": "OpenPrice_LocalCurrency",
                        "High": "HighPrice_LocalCurrency",
                        "Low": "LowPrice_LocalCurrency",
                        "Close": "ClosePrice_LocalCurrency",
                        "Volume": "VolumeAmount",
                    }
                )
        except:
            continue

        frames.append(frame)

    if len(frames) > 0:
        data = pd.concat(frames, axis=0).reset_index(drop=True)
        data["DateKey"] = data["DateKey"].astype(int)
    else:
        data = pd.DataFrame(columns=['OpenPrice_LocalCurrency', 'HighPrice_LocalCurrency',
                'LowPrice_LocalCurrency', 'ClosePrice_LocalCurrency', 'VolumeAmount',
                'YahooTicker', 'DateKey'])

    return data

if __name__ == "__main__":
    out_df = main()
    out_df.to_csv("daily_stock_price_fact_new_load.csv", index=False, decimal=",", sep=";", float_format="%.2f")
