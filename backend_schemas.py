"""
Pydantic schemas for request/response validation
"""
from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

# ============ Enums ============

class SourceType(str, Enum):
    WEB = "web"
    SOCIAL = "social"
    CUSTOM = "custom"

class Platform(str, Enum):
    TWITTER = "twitter"
    REDDIT = "reddit"
    YOUTUBE = "youtube"
    INSTAGRAM = "instagram"
    NEWS = "news"
    WEB = "web"

class JobType(str, Enum):
    SCRAPE = "scrape"
    AGGREGATE = "aggregate"
    ANALYZE = "analyze"
    ORACLE_SIGNAL = "oracle_signal"

class JobStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"

class AnalysisCategory(str, Enum):
    SENTIMENT = "sentiment"
    TREND = "trend"
    ENGAGEMENT = "engagement"
    PSYCHOLOGY = "psychology"
    QUALITY = "quality"

class Severity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

# ============ Source Schemas ============

class SourceCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    type: SourceType
    platform: Optional[Platform] = None
    config: Dict[str, Any]
    enabled: bool = True

class SourceUpdate(BaseModel):
    name: Optional[str] = None
    config: Optional[Dict[str, Any]] = None
    enabled: Optional[bool] = None

class SourceResponse(BaseModel):
    id: int
    name: str
    type: str
    platform: Optional[str]
    config: Dict[str, Any]
    enabled: bool
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ============ Job Schemas ============

class JobCreate(BaseModel):
    type: JobType
    input_data: Optional[Dict[str, Any]] = None

class JobResponse(BaseModel):
    id: int
    type: str
    status: str
    input_data: Optional[Dict[str, Any]]
    output_data: Optional[Dict[str, Any]]
    progress: float
    error_message: Optional[str]
    created_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ============ Dataset Schemas ============

class DatasetCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    source_ids: List[int]

class DatasetResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    source_ids: Optional[List[int]]
    row_count: int
    created_at: datetime
    last_refreshed_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ============ Analysis Schemas ============

class AnalysisRequest(BaseModel):
    dataset_id: int
    categories: Optional[List[AnalysisCategory]] = None

class AnalysisResponse(BaseModel):
    id: int
    dataset_id: int
    category: str
    metrics: Dict[str, Any]
    insights: Optional[Dict[str, Any]]
    recommendations: Optional[Dict[str, Any]]
    quality_score: Optional[float]
    severity: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

# ============ Oracle Schemas ============

class OracleSignalResponse(BaseModel):
    id: int
    analysis_result_id: int
    severity: str
    signal_type: Optional[str]
    payload: Optional[Dict[str, Any]]
    status: str
    tx_hash: Optional[str]
    tx_status: Optional[str]
    created_at: datetime
    sent_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# ============ Statistics Schemas ============

class DashboardStats(BaseModel):
    total_sources: int
    active_sources: int
    total_events: int
    total_datasets: int
    total_analyses: int
    sentiment_breakdown: Dict[str, int]
    recent_jobs: List[JobResponse]
    top_platforms: List[Dict[str, Any]]

class InsightSummary(BaseModel):
    id: int
    title: str
    summary: str
    category: str
    severity: str
    timestamp: datetime
    dataset_name: str
