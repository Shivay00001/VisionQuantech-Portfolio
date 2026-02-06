"""
AutoBounty OS - Backend Main Application
FastAPI server with complete API routes
"""
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os
from pathlib import Path

from app.core.db import engine, Base, get_db
from app.core.config import settings
from app.api import (
    routes_targets,
    routes_findings,
    routes_reports,
    routes_evidence,
    routes_scheduler,
    routes_config
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    evidence_dir = Path("evidence")
    evidence_dir.mkdir(exist_ok=True)
    yield

app = FastAPI(
    title="AutoBounty OS API",
    description="Production-grade bug bounty automation system",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(routes_targets.router, prefix="/api/targets", tags=["targets"])
app.include_router(routes_findings.router, prefix="/api/findings", tags=["findings"])
app.include_router(routes_reports.router, prefix="/api/reports", tags=["reports"])
app.include_router(routes_evidence.router, prefix="/api/evidence", tags=["evidence"])
app.include_router(routes_scheduler.router, prefix="/api/scheduler", tags=["scheduler"])
app.include_router(routes_config.router, prefix="/api/config", tags=["config"])

if Path("evidence").exists():
    app.mount("/evidence", StaticFiles(directory="evidence"), name="evidence")

@app.get("/")
async def root():
    return {
        "name": "AutoBounty OS API",
        "version": "1.0.0",
        "status": "operational"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "database": "connected"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )