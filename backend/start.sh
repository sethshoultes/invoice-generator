#!/bin/bash

# Invoice Generator Backend Start Script

echo "=================================="
echo "Invoice Generator Backend"
echo "=================================="
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
    echo "Virtual environment created!"
    echo ""
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Check if dependencies are installed
if [ ! -f "venv/bin/uvicorn" ]; then
    echo "Dependencies not found. Installing..."
    pip install -r requirements.txt
    echo "Dependencies installed!"
    echo ""
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "WARNING: .env file not found!"
    echo "Copying .env.example to .env..."
    cp .env.example .env
    echo ""
    echo "Please edit .env and add your Supabase credentials:"
    echo "  SUPABASE_URL=https://your-project.supabase.co"
    echo "  SUPABASE_KEY=your-supabase-anon-key"
    echo ""
    read -p "Press Enter to continue after editing .env, or Ctrl+C to exit..."
fi

# Start the server
echo "Starting FastAPI server on port 8002..."
echo ""
echo "API Documentation: http://localhost:8002/docs"
echo "Health Check: http://localhost:8002/health"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

uvicorn main:app --reload --port 8002 --host 0.0.0.0
