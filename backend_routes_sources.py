"""
API routes for data source management
CRUD operations for sources and triggering extractions
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import logging

from app.core.db import get_db
from app.models.source import Source
from app.models.job import Job
from app.schemas.source import SourceCreate, SourceUpdate, SourceResponse
from app.schemas.jobs import JobResponse
from app.workers.queue import enqueue_scraping_job

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=List[SourceResponse])
async def list_sources(
    skip: int = 0,
    limit: int = 100,
    enabled_only: bool = False,
    db: Session = Depends(get_db)
):
    """List all data sources"""
    query = db.query(Source)
    
    if enabled_only:
        query = query.filter(Source.enabled == True)
    
    sources = query.offset(skip).limit(limit).all()
    return sources

@router.post("/", response_model=SourceResponse, status_code=status.HTTP_201_CREATED)
async def create_source(
    source: SourceCreate,
    db: Session = Depends(get_db)
):
    """Create a new data source"""
    
    # Check if source name already exists
    existing = db.query(Source).filter(Source.name == source.name).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Source with name '{source.name}' already exists"
        )
    
    db_source = Source(
        name=source.name,
        type=source.type,
        platform=source.platform,
        config=source.config,
        enabled=source.enabled
    )
    
    db.add(db_source)
    db.commit()
    db.refresh(db_source)
    
    logger.info(f"Created source: {db_source.name} (ID: {db_source.id})")
    return db_source

@router.get("/{source_id}", response_model=SourceResponse)
async def get_source(
    source_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific source by ID"""
    source = db.query(Source).filter(Source.id == source_id).first()
    
    if not source:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Source with ID {source_id} not found"
        )
    
    return source

@router.patch("/{source_id}", response_model=SourceResponse)
async def update_source(
    source_id: int,
    source_update: SourceUpdate,
    db: Session = Depends(get_db)
):
    """Update a source"""
    source = db.query(Source).filter(Source.id == source_id).first()
    
    if not source:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Source with ID {source_id} not found"
        )
    
    # Update fields
    if source_update.name is not None:
        source.name = source_update.name
    if source_update.config is not None:
        source.config = source_update.config
    if source_update.enabled is not None:
        source.enabled = source_update.enabled
    
    db.commit()
    db.refresh(source)
    
    logger.info(f"Updated source: {source.name} (ID: {source.id})")
    return source

@router.delete("/{source_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_source(
    source_id: int,
    db: Session = Depends(get_db)
):
    """Delete a source"""
    source = db.query(Source).filter(Source.id == source_id).first()
    
    if not source:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Source with ID {source_id} not found"
        )
    
    db.delete(source)
    db.commit()
    
    logger.info(f"Deleted source: {source.name} (ID: {source_id})")
    return None

@router.post("/{source_id}/extract", response_model=JobResponse)
async def trigger_extraction(
    source_id: int,
    db: Session = Depends(get_db)
):
    """Trigger data extraction for a specific source"""
    source = db.query(Source).filter(Source.id == source_id).first()
    
    if not source:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Source with ID {source_id} not found"
        )
    
    if not source.enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Source '{source.name}' is disabled"
        )
    
    # Create job
    job = Job(
        type='scrape',
        status='pending',
        input_data={'source_id': source_id}
    )
    
    db.add(job)
    db.commit()
    db.refresh(job)
    
    # Enqueue job
    enqueue_scraping_job(job.id, source_id)
    
    logger.info(f"Triggered extraction for source {source.name} (Job ID: {job.id})")
    return job

@router.post("/extract-all", response_model=List[JobResponse])
async def trigger_all_extractions(
    db: Session = Depends(get_db)
):
    """Trigger extraction for all enabled sources"""
    sources = db.query(Source).filter(Source.enabled == True).all()
    
    if not sources:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No enabled sources found"
        )
    
    jobs = []
    
    for source in sources:
        job = Job(
            type='scrape',
            status='pending',
            input_data={'source_id': source.id}
        )
        db.add(job)
        jobs.append(job)
    
    db.commit()
    
    # Enqueue all jobs
    for job in jobs:
        db.refresh(job)
        enqueue_scraping_job(job.id, job.input_data['source_id'])
    
    logger.info(f"Triggered extraction for {len(jobs)} sources")
    return jobs
