@echo off
python -m venv env
call .\env\Scripts\activate.bat
pip install -r requirements.txt
python load_currency_conversion_NBP_API.py
rd /s /q env