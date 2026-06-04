@echo off
REM start_langflow.bat — One-click Langflow launcher for Windows
REM Edit the paths below to match your installation

REM Change to your Langflow project directory
cd /d D:\langflow

REM Activate the virtual environment
call venv\Scripts\activate

REM Run Langflow with the async-safe wrapper
python run_langflow_windows.py

pause
