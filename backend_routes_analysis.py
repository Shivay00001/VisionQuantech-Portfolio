"""
API routes for analysis and insights
Combined routes for efficiency
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import logging

from app.core.db import get_db
from app.models.dataset import Dataset
from app.models.analysis_result import AnalysisResult
from app.models.raw_event import RawEvent
from app.models.job import Job
from app.schemas.analysis import AnalysisRequest, AnalysisResponse, DatasetCreate, DatasetResponse
from app.schemas.insights import InsightSummary, DashboardStats
from app.workers.queue import enqueue_analysis_job

logger = logging.getLogger(__name__)
router = APIRouter()

# ============ Dataset Management ============

@router.post("/datasets", response_model=DatasetResponse, status_code=status.HTTP_201_CREATED)
async def create_dataset(
    dataset: DatasetCreate,
    db: Session = Depends(get_db)
):
    """Create a new dataset from sources"""
    
    # Check if dataset name exists
    existing = db.query(Dataset).filter(Dataset.name == dataset.name).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Dataset '{dataset.name}' already exists"
        )
    
    # Count raw events from sources
    row_count = db.query(RawEvent).filter(
        RawEvent.source_id.in_(dataset.source_ids)
    ).count()
    
    db_dataset = Dataset(
        name=dataset.name,
        description=dataset.description,
        source_ids=dataset.source_ids,
        row_count=row_count
    )
    
    db.add(db_dataset)
    db.commit()
    db.refresh(db_dataset)
    
    logger.info(f"Created dataset: {db_dataset.name} with {row_count} rows")
    return db_dataset

@router.get("/datasets", response_model=List[DatasetResponse])
async def list_datasets(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List all datasets"""
    datasets = db.query(Dataset).offset(skip).limit(limit).all()
    return datasets

@router.get("/datasets/{dataset_id}", response_model=DatasetResponse)
async def get_dataset(
    dataset_id: int,
    db: Session = Depends(get_db)
):
    """Get dataset details"""
    dataset = db.query(Dataset).filter(Dataset.id == dataset_id).first()
    
    if not dataset:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Dataset {dataset_id} not found"
        )
    
    return dataset

# ============ Analysis Operations ============

@router.post("/analyze", response_model=dict)
async def trigger_analysis(
    request: AnalysisRequest,
    db: Session = Depends(get_db)
):
    """Trigger analysis for a dataset"""
    
    dataset = db.query(Dataset).filter(Dataset.id == request.dataset_id).first()
    if not dataset:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Dataset {request.dataset_id} not found"
        )
    
    # Create analysis job
    job = Job(
        type='analyze',
        status='pending',
        input_data={
            'dataset_id': request.dataset_id,
            'categories': request.categories
        }
    )
    
    db.add(job)
    db.commit()
    db.refresh(job)
    
    # Enqueue job
    enqueue_analysis_job(job.id, request.dataset_id, request.categories)
    
    logger.info(f"Triggered analysis for dataset {request.dataset_id} (Job: {job.id})")
    
    return {
        'job_id': job.id,
        'dataset_id': request.dataset_id,
        'status': 'pending',
        'message': 'Analysis job enqueued successfully'
    }

@router.get("/results", response_model=List[AnalysisResponse])
async def list_analysis_results(
    dataset_id: Optional[int] = None,
    category: Optional[str] = None,
    severity: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List analysis results with filtering"""
    query = db.query(AnalysisResult)
    
    if dataset_id:
        query = query.filter(AnalysisResult.dataset_id == dataset_id)
    if category:
        query = query.filter(AnalysisResult.category == category)
    if severity:
        query = query.filter(AnalysisResult.severity == severity)
    
    query = query.order_by(AnalysisResult.created_at.desc())
    
    results = query.offset(skip).limit(limit).all()
    return results

@router.get("/results/{result_id}", response_model=AnalysisResponse)
async def get_analysis_result(
    result_id: int,
    db: Session = Depends(get_db)
):
    """Get specific analysis result"""
    result = db.query(AnalysisResult).filter(AnalysisResult.id == result_id).first()
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Analysis result {result_id} not found"
        )
    
    return result

# ============ Insights & Dashboard ============

@router.get("/insights/summary", response_model=List[InsightSummary])
async def get_insights_summary(
    limit: int = Query(default=10, ge=1, le=50),
    severity: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get summarized insights for dashboard"""
    
    query = db.query(
        AnalysisResult.id,
        AnalysisResult.category,
        AnalysisResult.severity,
        AnalysisResult.created_at,
        AnalysisResult.insights,
        Dataset.name.label('dataset_name')
    ).join(Dataset, AnalysisResult.dataset_id == Dataset.id)
    
    if severity:
        query = query.filter(AnalysisResult.severity == severity)
    
    query = query.order_by(AnalysisResult.created_at.desc()).limit(limit)
    
    results = query.all()
    
    summaries = []
    for r in results:
        insight_text = r.insights.get('summary', 'No summary available') if r.insights else 'No insights'
        
        summaries.append(InsightSummary(
            id=r.id,
            title=f"{r.category.title()} Analysis - {r.dataset_name}",
            summary=insight_text,
            category=r.category,
            severity=r.severity,
            timestamp=r.created_at,
            dataset_name=r.dataset_name
        ))
    
    return summaries

@router.get("/dashboard/stats", response_model=DashboardStats)
async def get_dashboard_stats(db: Session = Depends(get_db)):
    """Get comprehensive dashboard statistics"""
    from app.models.source import Source
    from sqlalchemy import func
    
    # Source stats
    total_sources = db.query(Source).count()
    active_sources = db.query(Source).filter(Source.enabled == True).count()
    
    # Event stats
    total_events = db.query(RawEvent).count()
    
    # Dataset stats
    total_datasets = db.query(Dataset).count()
    
    # Analysis stats
    total_analyses = db.query(AnalysisResult).count()
    
    # Sentiment breakdown (from sentiment analysis results)
    sentiment_results = db.query(AnalysisResult).filter(
        AnalysisResult.category == 'sentiment'
    ).order_by(AnalysisResult.created_at.desc()).first()
    
    sentiment_breakdown = {'positive': 0, 'neutral': 0, 'negative': 0}
    if sentiment_results and sentiment_results.metrics:
        dist = sentiment_results.metrics.get('sentiment_distribution', {})
        sentiment_breakdown = {
            'positive': int(dist.get('positive', 0)),
            'neutral': int(dist.get('neutral', 0)),
            'negative': int(dist.get('negative', 0))
        }
    
    # Recent jobs
    recent_jobs = db.query(Job).order_by(Job.created_at.desc()).limit(5).all()
    
    # Top platforms
    platform_counts = db.query(
        RawEvent.platform,
        func.count(RawEvent.id).label('count')
    ).group_by(RawEvent.platform).all()
    
    top_platforms = [{'platform': p, 'count': c} for p, c in platform_counts]
    
    return DashboardStats(
        total_sources=total_sources,
        active_sources=active_sources,
        total_events=total_events,
        total_datasets=total_datasets,
        total_analyses=total_analyses,
        sentiment_breakdown=sentiment_breakdown,
        recent_jobs=recent_jobs,
        top_platforms=top_platforms
    )
