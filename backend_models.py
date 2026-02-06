"""
Database models for WorldMind OS
Complete relational schema
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, JSON, Float, ForeignKey, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
from app.core.db import Base

class Source(Base):
    """Data source configuration"""
    __tablename__ = "sources"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, nullable=False)
    type = Column(String(50), nullable=False)  # 'web', 'social', 'custom'
    platform = Column(String(50))  # 'twitter', 'reddit', 'news', etc.
    config = Column(JSON, nullable=False)  # URLs, queries, selectors, etc.
    enabled = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    raw_events = relationship("RawEvent", back_populates="source", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_source_type', 'type'),
        Index('idx_source_enabled', 'enabled'),
    )

class RawEvent(Base):
    """Raw extracted data events"""
    __tablename__ = "raw_events"
    
    id = Column(Integer, primary_key=True, index=True)
    source_id = Column(Integer, ForeignKey("sources.id"), nullable=False)
    platform = Column(String(50), nullable=False)
    raw_json = Column(JSON, nullable=False)
    content_hash = Column(String(64), index=True)  # For deduplication
    dedup_flag = Column(Boolean, default=False)
    fetched_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    source = relationship("Source", back_populates="raw_events")
    
    __table_args__ = (
        Index('idx_raw_event_source', 'source_id'),
        Index('idx_raw_event_platform', 'platform'),
        Index('idx_raw_event_hash', 'content_hash'),
        Index('idx_raw_event_fetched', 'fetched_at'),
    )

class Dataset(Base):
    """Curated datasets from raw events"""
    __tablename__ = "datasets"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, nullable=False)
    description = Column(Text)
    source_ids = Column(JSON)  # List of source IDs
    row_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_refreshed_at = Column(DateTime(timezone=True))
    
    # Relationships
    analysis_results = relationship("AnalysisResult", back_populates="dataset", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_dataset_name', 'name'),
    )

class AnalysisResult(Base):
    """Analysis results from datasets"""
    __tablename__ = "analysis_results"
    
    id = Column(Integer, primary_key=True, index=True)
    dataset_id = Column(Integer, ForeignKey("datasets.id"), nullable=False)
    category = Column(String(100), nullable=False)  # 'sentiment', 'trend', 'engagement', etc.
    metrics = Column(JSON, nullable=False)
    insights = Column(JSON)
    recommendations = Column(JSON)
    quality_score = Column(Float)
    severity = Column(String(20))  # 'low', 'medium', 'high', 'critical'
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    dataset = relationship("Dataset", back_populates="analysis_results")
    oracle_signals = relationship("OracleSignal", back_populates="analysis_result", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('idx_analysis_dataset', 'dataset_id'),
        Index('idx_analysis_category', 'category'),
        Index('idx_analysis_severity', 'severity'),
        Index('idx_analysis_created', 'created_at'),
    )

class Job(Base):
    """Background job tracking"""
    __tablename__ = "jobs"
    
    id = Column(Integer, primary_key=True, index=True)
    type = Column(String(50), nullable=False)  # 'scrape', 'aggregate', 'analyze', 'oracle_signal'
    status = Column(String(20), default='pending')  # 'pending', 'running', 'completed', 'failed'
    input_data = Column(JSON)
    output_data = Column(JSON)
    progress = Column(Float, default=0.0)
    error_message = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    started_at = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    
    __table_args__ = (
        Index('idx_job_type', 'type'),
        Index('idx_job_status', 'status'),
        Index('idx_job_created', 'created_at'),
    )

class OracleSignal(Base):
    """Oracle signals for blockchain integration"""
    __tablename__ = "oracle_signals"
    
    id = Column(Integer, primary_key=True, index=True)
    analysis_result_id = Column(Integer, ForeignKey("analysis_results.id"), nullable=False)
    severity = Column(String(20), nullable=False)
    signal_type = Column(String(50))  # 'alert', 'metric_update', 'trend_change'
    payload = Column(JSON)
    status = Column(String(20), default='pending')  # 'pending', 'sent', 'failed'
    tx_hash = Column(String(66))
    tx_status = Column(String(20))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    sent_at = Column(DateTime(timezone=True))
    
    # Relationships
    analysis_result = relationship("AnalysisResult", back_populates="oracle_signals")
    
    __table_args__ = (
        Index('idx_oracle_status', 'status'),
        Index('idx_oracle_severity', 'severity'),
        Index('idx_oracle_created', 'created_at'),
    )
