import requests
import pandas as pd
from datetime import date, timedelta


def main() -> pd.DataFrame:
    FORMAT = "%Y-%m-%d"

    last_currency_conversion_fact_date = pd.read_csv("last_currency_conversion_fact_date.csv")
    last_currency_conversion_fact_date["Date"] = pd.to_datetime(last_currency_conversion_fact_date["Date"], format="%Y-%m-%d")
    last_currency_conversion_fact_date["Date"] += pd.Timedelta(days=1)
    last_currency_conversion_fact_date["Date"] = last_currency_conversion_fact_date["Date"].dt.date

    frames = []

    for currency_code, date_ in last_currency_conversion_fact_date.itertuples(index=False, name=None):

        start_date = date_

        while start_date < date.today():
            end_date = min(date.today(), start_date + timedelta(days=93)) 

            start_date_str = start_date.strftime(FORMAT)
            end_date_str = end_date.strftime(FORMAT)

            r = requests.get(
                f"http://api.nbp.pl/api/exchangerates/rates/a/{currency_code}/{start_date_str}/{end_date_str}/?format=json"
            )

            json_ = r.json()
            frame = pd.json_normalize(json_, record_path="rates", meta="code")
            frame = frame.loc[:, ["effectiveDate", "mid", "code"]].rename(
                columns={
                    "code": "SourceCurrency",
                    "mid": "SourceCurrencyToPLN_ExchangeRate", 
                    "effectiveDate": "ConversionDateKey"
                }
            )
            frames.append(frame)

            start_date = end_date + timedelta(days=1)

    if len(frames) > 0:
        data = pd.concat(frames, axis=0).reset_index(drop=True)
        data["ConversionDateKey"] = pd.to_datetime(data["ConversionDateKey"], format="%Y-%m-%d")
        data = (
            data.groupby("SourceCurrency", as_index=False)
                .apply(lambda x: x.set_index("ConversionDateKey")
                .asfreq("D", method="ffill"))
                .reset_index(level=1).reset_index(drop=True)
        )

        data["ConversionDateKey"] = data["ConversionDateKey"].dt.strftime("%Y%m%d").astype(int)
    else:
        data = pd.DataFrame(columns=["SourceCurrency", "SourceCurrencyToPLN_ExchangeRate", "ConversionDateKey"])

    return data

if __name__ == "__main__":
    out_df = main()
    out_df.to_csv("currency_conversion_fact_new_load.csv", index=False, decimal=",", sep=";")
