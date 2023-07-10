@echo off
python -m venv env
call .\env\Scripts\activate.bat
pip install -r requirements.txt
python load_financial_indicator_Bloomberg_API.py
rd /s /q env