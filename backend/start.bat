@echo off
REM Invoice Generator Backend Start Script for Windows

echo ==================================
echo Invoice Generator Backend
echo ==================================
echo.

REM Check if virtual environment exists
if not exist "venv\" (
    echo Virtual environment not found. Creating one...
    python -m venv venv
    echo Virtual environment created!
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Check if dependencies are installed
if not exist "venv\Scripts\uvicorn.exe" (
    echo Dependencies not found. Installing...
    pip install -r requirements.txt
    echo Dependencies installed!
    echo.
)

REM Check if .env file exists
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Copying .env.example to .env...
    copy .env.example .env
    echo.
    echo Please edit .env and add your Supabase credentials:
    echo   SUPABASE_URL=https://your-project.supabase.co
    echo   SUPABASE_KEY=your-supabase-anon-key
    echo.
    pause
)

REM Start the server
echo Starting FastAPI server on port 8002...
echo.
echo API Documentation: http://localhost:8002/docs
echo Health Check: http://localhost:8002/health
echo.
echo Press Ctrl+C to stop the server
echo.

uvicorn main:app --reload --port 8002 --host 0.0.0.0
