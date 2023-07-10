import pandas as pd
from datetime import date


def main() -> pd.DataFrame:
    from xbbg import blp

    FORMAT = "%Y-%m-%d"
    FIELDS = ['NET_INCOME', 'CUR_RATIO', 'EBITDA', 'OPER_MARGIN', 'PROF_MARGIN', 'RETURN_ON_ASSET', 'SALES_REV_TURN']

    last_financial_indicator_fact_date = pd.read_csv("last_financial_indicator_fact_date.csv")
    last_financial_indicator_fact_date["Date"] = pd.to_datetime(last_financial_indicator_fact_date["Date"], format="%Y-%m-%d")
    last_financial_indicator_fact_date["Date"] += pd.Timedelta(days=1)
    last_financial_indicator_fact_date["Date"] = last_financial_indicator_fact_date["Date"].dt.date

    frames = []

    for date_, bloomberg_ticker in last_financial_indicator_fact_date.iloc.itertuples(index=False, name=None):

        start_date_str = date_.strftime(FORMAT)
        end_date_str = date.today().strftime(FORMAT)

        frame = blp.bdh(
            tickers=[bloomberg_ticker],
            flds=FIELDS,
            start_date=start_date_str,
            end_date=end_date_str,
            Per="Q"
        )

        frame = pd.melt(
            frame, 
            ignore_index=False, 
            var_name=["BloombergTicker", "field"]
        ).reset_index().pivot_table(
            index=["index", "BloombergTicker"], 
            columns=["field"], 
            values="value"
        ).reset_index().rename(columns={"index": "date"}).rename_axis(columns=None).dropna()
        
        frames.append(frame)

    if len(frames) > 0:
        data = pd.concat(frames, axis=0).reset_index(drop=True)
        data["QuarterDateKey"] = pd.to_datetime(data["date"]).dt.strftime("%Y%m%d").astype(int)
        data = data.dropna(how="any").rename(columns={
            "EBITDA": "EBITDA_LocalCurrency",
            "NET_INCOME": "NetIncome_LocalCurrency",
            "SALES_REV_TURN": "Revenue_LocalCurrency",
            "PROF_MARGIN": "ProfitMargin",
            "OPER_MARGIN": "OperatingMargin",
            "RETURN_ON_ASSET": "ReturnOnAsset",
            "CUR_RATIO": "CurrentRatio"
        }).drop(columns=["date"]).reset_index(drop=True)
    else:
        data = pd.DataFrame(columns=['BloombergTicker', 'EBITDA_LocalCurrency', 'NetIncome_LocalCurrency', 'OperatingMargin', 'ProfitMargin', 'ReturnOnAsset', 'Revenue_LocalCurrency', 'CurrentRatio', 'QuarterDateKey'])

    return data

if __name__ == "__main__":
    out_df = main()
    out_df.to_csv("financial_indicator_fact_new_load.csv", index=False, decimal=",", sep=";", float_format="%.2f")
