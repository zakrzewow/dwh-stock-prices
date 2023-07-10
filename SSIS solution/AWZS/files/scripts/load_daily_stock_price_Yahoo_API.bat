@echo off
python -m venv env
call .\env\Scripts\activate.bat
pip install -r requirements.txt
python load_daily_stock_price_Yahoo_API.py
rd /s /q env