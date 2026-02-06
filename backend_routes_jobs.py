"""
API routes for job management and monitoring
Track background job status and progress
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from app.core.db import get_db
from app.models.job import Job
from app.schemas.jobs import JobResponse, JobCreate

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/", response_model=List[JobResponse])
async def list_jobs(
    skip: int = 0,
    limit: int = 100,
    job_type: Optional[str] = None,
    status: Optional[str] = None,
    since_hours: Optional[int] = Query(default=24, ge=1, le=168),
    db: Session = Depends(get_db)
):
    """List jobs with optional filtering"""
    query = db.query(Job)
    
    # Filter by type
    if job_type:
        query = query.filter(Job.type == job_type)
    
    # Filter by status
    if status:
        query = query.filter(Job.status == status)
    
    # Filter by time
    if since_hours:
        cutoff_time = datetime.utcnow() - timedelta(hours=since_hours)
        query = query.filter(Job.created_at >= cutoff_time)
    
    # Order by most recent
    query = query.order_by(Job.created_at.desc())
    
    jobs = query.offset(skip).limit(limit).all()
    return jobs

@router.get("/{job_id}", response_model=JobResponse)
async def get_job(
    job_id: int,
    db: Session = Depends(get_db)
):
    """Get specific job details"""
    job = db.query(Job).filter(Job.id == job_id).first()
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID {job_id} not found"
        )
    
    return job

@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_job(
    job_id: int,
    db: Session = Depends(get_db)
):
    """Delete a job record"""
    job = db.query(Job).filter(Job.id == job_id).first()
    
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job with ID {job_id} not found"
        )
    
    # Only allow deletion of completed or failed jobs
    if job.status in ['running', 'pending']:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete running or pending jobs"
        )
    
    db.delete(job)
    db.commit()
    
    logger.info(f"Deleted job ID: {job_id}")
    return None

@router.get("/stats/summary")
async def get_job_stats(
    db: Session = Depends(get_db)
):
    """Get job statistics summary"""
    
    # Total jobs by status
    total_jobs = db.query(Job).count()
    pending = db.query(Job).filter(Job.status == 'pending').count()
    running = db.query(Job).filter(Job.status == 'running').count()
    completed = db.query(Job).filter(Job.status == 'completed').count()
    failed = db.query(Job).filter(Job.status == 'failed').count()
    
    # Jobs by type
    jobs_by_type = {}
    for job_type in ['scrape', 'aggregate', 'analyze', 'oracle_signal']:
        count = db.query(Job).filter(Job.type == job_type).count()
        jobs_by_type[job_type] = count
    
    # Recent jobs (last 24 hours)
    cutoff = datetime.utcnow() - timedelta(hours=24)
    recent_jobs = db.query(Job).filter(Job.created_at >= cutoff).count()
    
    # Success rate
    total_finished = completed + failed
    success_rate = (completed / total_finished * 100) if total_finished > 0 else 0
    
    return {
        'total_jobs': total_jobs,
        'by_status': {
            'pending': pending,
            'running': running,
            'completed': completed,
            'failed': failed
        },
        'by_type': jobs_by_type,
        'recent_24h': recent_jobs,
        'success_rate': round(success_rate, 2)
    }

@router.post("/cleanup")
async def cleanup_old_jobs(
    days_old: int = Query(default=7, ge=1, le=90),
    db: Session = Depends(get_db)
):
    """Clean up completed jobs older than specified days"""
    cutoff = datetime.utcnow() - timedelta(days=days_old)
    
    deleted_count = db.query(Job).filter(
        Job.status.in_(['completed', 'failed']),
        Job.created_at < cutoff
    ).delete()
    
    db.commit()
    
    logger.info(f"Cleaned up {deleted_count} old jobs")
    
    return {
        'deleted_count': deleted_count,
        'cutoff_date': cutoff.isoformat()
    }
