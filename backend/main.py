"""
FastAPI Invoice Generator Backend
Connects to Supabase PostgreSQL database
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from datetime import datetime
import os

from routes import clients, invoices, recurring_items
from schemas import HealthCheck

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="Invoice Generator API",
    description="Backend API for Invoice Generator with Supabase integration",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration
# Allow browser access from port 3002 and localhost variations
origins = [
    "http://localhost:3002",
    "http://127.0.0.1:3002",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    # Add your production domain here
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include routers
app.include_router(clients.router)
app.include_router(invoices.router)
app.include_router(recurring_items.router)


# Root endpoint
@app.get("/", tags=["root"])
async def root():
    """
    Root endpoint - API information
    """
    return {
        "name": "Invoice Generator API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
        "health": "/health"
    }


# Health check endpoint
@app.get("/health", response_model=HealthCheck, tags=["health"])
async def health_check():
    """
    Health check endpoint
    Returns API status and timestamp
    """
    return HealthCheck(
        status="healthy",
        timestamp=datetime.utcnow(),
        version="1.0.0"
    )


# Startup event
@app.on_event("startup")
async def startup_event():
    """
    Run on application startup
    """
    print("=" * 50)
    print("Invoice Generator API Starting...")
    print(f"Supabase URL: {os.getenv('SUPABASE_URL', 'Not configured')}")
    print(f"API Docs: http://localhost:8002/docs")
    print(f"Health Check: http://localhost:8002/health")
    print("=" * 50)


# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """
    Run on application shutdown
    """
    print("Invoice Generator API shutting down...")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8002,
        reload=True,
        log_level="info"
    )
