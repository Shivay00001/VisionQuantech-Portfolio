"""
Background workers for async job processing
Uses Redis + RQ for job queue management
"""
import redis
from rq import Queue, Worker
from typing import Optional, List
import logging
from datetime import datetime

from app.core.config import settings
from app.core.db import SessionLocal
from app.models.job import Job
from app.models.source import Source
from app.models.raw_event import RawEvent
from app.services.scraping_service import ScrapingService
from app.services.social_service import SocialService
from app.services.analysis_service import AnalysisService
from app.models.analysis_result import AnalysisResult
from app.models.dataset import Dataset
import asyncio

logger = logging.getLogger(__name__)

# Redis connection
redis_conn = redis.from_url(settings.REDIS_URL)

# Create queues
scraping_queue = Queue('scraping', connection=redis_conn)
analysis_queue = Queue('analysis', connection=redis_conn)
oracle_queue = Queue('oracle', connection=redis_conn)

# ============ Queue Helper Functions ============

def enqueue_scraping_job(job_id: int, source_id: int):
    """Enqueue a scraping job"""
    return scraping_queue.enqueue(
        process_scraping_job,
        job_id,
        source_id,
        job_timeout=settings.JOB_TIMEOUT
    )

def enqueue_analysis_job(job_id: int, dataset_id: int, categories: Optional[List[str]] = None):
    """Enqueue an analysis job"""
    return analysis_queue.enqueue(
        process_analysis_job,
        job_id,
        dataset_id,
        categories,
        job_timeout=settings.JOB_TIMEOUT
    )

def enqueue_oracle_job(job_id: int, analysis_result_id: int):
    """Enqueue an oracle signal job"""
    return oracle_queue.enqueue(
        process_oracle_job,
        job_id,
        analysis_result_id,
        job_timeout=settings.JOB_TIMEOUT
    )

# ============ Worker Functions ============

def process_scraping_job(job_id: int, source_id: int):
    """Process a scraping/extraction job"""
    db = SessionLocal()
    
    try:
        # Update job status
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            logger.error(f"Job {job_id} not found")
            return
        
        job.status = 'running'
        job.started_at = datetime.utcnow()
        job.progress = 0.0
        db.commit()
        
        logger.info(f"Starting scraping job {job_id} for source {source_id}")
        
        # Get source
        source = db.query(Source).filter(Source.id == source_id).first()
        if not source:
            raise Exception(f"Source {source_id} not found")
        
        # Execute extraction based on source type
        extracted_data = []
        
        if source.type == 'web':
            extracted_data = asyncio.run(_extract_web_data(source))
        elif source.type == 'social':
            extracted_data = asyncio.run(_extract_social_data(source))
        
        job.progress = 0.5
        db.commit()
        
        # Store raw events
        new_events = 0
        for data in extracted_data:
            # Check for duplicates
            content_hash = data.get('content_hash')
            existing = db.query(RawEvent).filter(
                RawEvent.content_hash == content_hash
            ).first()
            
            if not existing:
                event = RawEvent(
                    source_id=source_id,
                    platform=source.platform or 'web',
                    raw_json=data,
                    content_hash=content_hash
                )
                db.add(event)
                new_events += 1
        
        db.commit()
        job.progress = 1.0
        
        # Update job completion
        job.status = 'completed'
        job.completed_at = datetime.utcnow()
        job.output_data = {
            'events_extracted': len(extracted_data),
            'new_events': new_events,
            'duplicates_filtered': len(extracted_data) - new_events
        }
        db.commit()
        
        logger.info(f"Completed scraping job {job_id}: {new_events} new events")
        
    except Exception as e:
        logger.error(f"Error in scraping job {job_id}: {str(e)}", exc_info=True)
        job.status = 'failed'
        job.error_message = str(e)
        job.completed_at = datetime.utcnow()
        db.commit()
        
    finally:
        db.close()

def process_analysis_job(job_id: int, dataset_id: int, categories: Optional[List[str]] = None):
    """Process an analysis job"""
    db = SessionLocal()
    
    try:
        # Update job status
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            logger.error(f"Job {job_id} not found")
            return
        
        job.status = 'running'
        job.started_at = datetime.utcnow()
        job.progress = 0.0
        db.commit()
        
        logger.info(f"Starting analysis job {job_id} for dataset {dataset_id}")
        
        # Get dataset
        dataset = db.query(Dataset).filter(Dataset.id == dataset_id).first()
        if not dataset:
            raise Exception(f"Dataset {dataset_id} not found")
        
        # Get raw events
        raw_events = db.query(RawEvent).filter(
            RawEvent.source_id.in_(dataset.source_ids or [])
        ).all()
        
        if not raw_events:
            raise Exception(f"No data found for dataset {dataset_id}")
        
        job.progress = 0.2
        db.commit()
        
        # Run analysis
        analysis_service = AnalysisService()
        results = analysis_service.analyze_dataset(dataset_id, raw_events, categories)
        
        job.progress = 0.8
        db.commit()
        
        # Store results
        for result_data in results:
            analysis = AnalysisResult(
                dataset_id=result_data['dataset_id'],
                category=result_data['category'],
                metrics=result_data['metrics'],
                insights=result_data['insights'],
                recommendations=result_data['recommendations'],
                quality_score=result_data['quality_score'],
                severity=result_data['severity']
            )
            db.add(analysis)
        
        # Update dataset
        dataset.last_refreshed_at = datetime.utcnow()
        dataset.row_count = len(raw_events)
        
        db.commit()
        job.progress = 1.0
        
        # Update job completion
        job.status = 'completed'
        job.completed_at = datetime.utcnow()
        job.output_data = {
            'analyses_created': len(results),
            'categories': [r['category'] for r in results]
        }
        db.commit()
        
        logger.info(f"Completed analysis job {job_id}: {len(results)} analyses")
        
    except Exception as e:
        logger.error(f"Error in analysis job {job_id}: {str(e)}", exc_info=True)
        job.status = 'failed'
        job.error_message = str(e)
        job.completed_at = datetime.utcnow()
        db.commit()
        
    finally:
        db.close()

def process_oracle_job(job_id: int, analysis_result_id: int):
    """Process oracle signal job (placeholder for blockchain integration)"""
    db = SessionLocal()
    
    try:
        job = db.query(Job).filter(Job.id == job_id).first()
        if not job:
            return
        
        job.status = 'running'
        job.started_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"Starting oracle job {job_id} for analysis {analysis_result_id}")
        
        # Get analysis result
        analysis = db.query(AnalysisResult).filter(
            AnalysisResult.id == analysis_result_id
        ).first()
        
        if not analysis:
            raise Exception(f"Analysis result {analysis_result_id} not found")
        
        # Oracle signal logic (placeholder - implement actual blockchain integration)
        if settings.ORACLE_ENABLED:
            # TODO: Send to blockchain via Oracle service
            logger.info(f"Oracle signal sent for analysis {analysis_result_id}")
        
        job.status = 'completed'
        job.completed_at = datetime.utcnow()
        job.output_data = {'signal_sent': settings.ORACLE_ENABLED}
        db.commit()
        
    except Exception as e:
        logger.error(f"Error in oracle job {job_id}: {str(e)}", exc_info=True)
        job.status = 'failed'
        job.error_message = str(e)
        job.completed_at = datetime.utcnow()
        db.commit()
        
    finally:
        db.close()

# ============ Helper Functions ============

async def _extract_web_data(source: Source) -> List[dict]:
    """Extract data from web sources"""
    scraper = ScrapingService()
    config = source.config
    
    urls = config.get('urls', [])
    selectors = config.get('selectors')
    
    if not urls:
        return []
    
    try:
        if len(urls) == 1:
            result = await scraper.fetch_web_page(urls[0], selectors)
            return [result]
        else:
            results = await scraper.bulk_fetch(urls)
            return results
    finally:
        await scraper.close()

async def _extract_social_data(source: Source) -> List[dict]:
    """Extract data from social media sources"""
    social_service = SocialService()
    config = source.config
    platform = source.platform
    
    if platform == 'twitter':
        query = config.get('query', '')
        count = config.get('count', 100)
        return await social_service.fetch_twitter(query, count)
    
    elif platform == 'reddit':
        subreddit = config.get('subreddit', '')
        limit = config.get('limit', 100)
        return await social_service.fetch_reddit(subreddit, limit)
    
    elif platform == 'youtube':
        video_id = config.get('video_id')
        channel_id = config.get('channel_id')
        search_query = config.get('search_query')
        max_results = config.get('max_results', 50)
        return await social_service.fetch_youtube(video_id, channel_id, search_query, max_results)
    
    elif platform == 'instagram':
        hashtag = config.get('hashtag')
        username = config.get('username')
        count = config.get('count', 50)
        return await social_service.fetch_instagram(hashtag, username, count)
    
    return []
