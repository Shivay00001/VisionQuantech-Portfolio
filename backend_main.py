"""
WorldMind OS - FastAPI Main Application
Production-grade backend for global data intelligence platform
"""
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
from typing import AsyncGenerator

from app.core.config import settings
from app.core.db import engine, Base, get_db
from app.core.logging import setup_logging
from app.api import routes_sources, routes_jobs, routes_analysis, routes_insights, routes_oracle

# Setup logging
logger = setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Startup and shutdown events"""
    logger.info("Starting WorldMind OS API Server...")
    
    # Create database tables
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables initialized")
    
    yield
    
    logger.info("Shutting down WorldMind OS API Server...")

# Initialize FastAPI app
app = FastAPI(
    title="WorldMind OS API",
    description="Global Data Intelligence Platform API",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "service": "worldmind-os-api",
        "version": "1.0.0"
    }

# Root endpoint
@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "message": "WorldMind OS API",
        "docs": "/api/docs",
        "health": "/health"
    }

# Include routers
app.include_router(routes_sources.router, prefix="/api/sources", tags=["Sources"])
app.include_router(routes_jobs.router, prefix="/api/jobs", tags=["Jobs"])
app.include_router(routes_analysis.router, prefix="/api/analysis", tags=["Analysis"])
app.include_router(routes_insights.router, prefix="/api/insights", tags=["Insights"])
app.include_router(routes_oracle.router, prefix="/api/oracle", tags=["Oracle"])

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error occurred"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )
