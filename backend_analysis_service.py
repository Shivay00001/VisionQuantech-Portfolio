"""
Analysis Service - Intelligence & Insights Generation
Combines data profiling, NLP, and advanced analytics
"""
import pandas as pd
import numpy as np
from typing import Dict, List, Any, Optional
from collections import Counter
import re
import logging
from datetime import datetime

from app.services.advanced_analyzer import AdvancedAnalyzer
from app.models.raw_event import RawEvent
from app.models.analysis_result import AnalysisResult
from app.core.db import SessionLocal

logger = logging.getLogger(__name__)

class AnalysisService:
    """Comprehensive analysis and insights generation"""
    
    def __init__(self):
        self.sentiment_keywords = {
            'positive': ['good', 'great', 'excellent', 'amazing', 'love', 'best', 'fantastic', 
                        'wonderful', 'awesome', 'happy', 'perfect', 'brilliant'],
            'negative': ['bad', 'terrible', 'awful', 'hate', 'worst', 'horrible', 'poor', 
                        'disappointing', 'useless', 'angry', 'frustrated', 'sad']
        }
    
    def analyze_dataset(
        self,
        dataset_id: int,
        raw_events: List[RawEvent],
        categories: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Comprehensive dataset analysis
        
        Args:
            dataset_id: Dataset ID
            raw_events: List of raw event records
            categories: Analysis categories to perform
        
        Returns:
            List of analysis results
        """
        logger.info(f"Analyzing dataset {dataset_id} with {len(raw_events)} events")
        
        # Convert raw events to DataFrame
        df = self._events_to_dataframe(raw_events)
        
        if df.empty:
            logger.warning(f"Dataset {dataset_id} is empty")
            return []
        
        results = []
        
        # Default categories if none specified
        if not categories:
            categories = ['profiling', 'sentiment', 'trends', 'engagement', 'psychology']
        
        # Data Profiling
        if 'profiling' in categories:
            profiling_result = self._analyze_profiling(dataset_id, df)
            results.append(profiling_result)
        
        # Sentiment Analysis
        if 'sentiment' in categories:
            sentiment_result = self._analyze_sentiment(dataset_id, df)
            results.append(sentiment_result)
        
        # Trend Analysis
        if 'trends' in categories:
            trends_result = self._analyze_trends(dataset_id, df)
            results.append(trends_result)
        
        # Engagement Analysis
        if 'engagement' in categories:
            engagement_result = self._analyze_engagement(dataset_id, df)
            results.append(engagement_result)
        
        # Psychology/Opinion Analysis
        if 'psychology' in categories:
            psychology_result = self._analyze_psychology(dataset_id, df)
            results.append(psychology_result)
        
        logger.info(f"Analysis completed: {len(results)} results generated")
        return results
    
    def _events_to_dataframe(self, raw_events: List[RawEvent]) -> pd.DataFrame:
        """Convert raw events to pandas DataFrame"""
        data = []
        
        for event in raw_events:
            row = event.raw_json.copy()
            row['source_id'] = event.source_id
            row['platform'] = event.platform
            row['fetched_at'] = event.fetched_at
            data.append(row)
        
        return pd.DataFrame(data)
    
    def _analyze_profiling(self, dataset_id: int, df: pd.DataFrame) -> Dict[str, Any]:
        """Data profiling analysis"""
        analyzer = AdvancedAnalyzer(df)
        profile = analyzer.comprehensive_profiling()
        
        # Auto-clean with conservative strategy
        cleaned_df, cleaning_report = analyzer.auto_clean_data(strategy='auto')
        
        # Generate insights
        insights = {
            'summary': f"Dataset contains {profile['basic_info']['rows']} records across {profile['basic_info']['columns']} fields",
            'quality': f"Overall quality score: {profile['data_quality_score']['overall']:.1%}",
            'missing_data': f"{profile['missing_data']['percentage_missing']:.1f}% missing values",
            'duplicates': f"{profile['duplicates']['duplicate_percentage']:.1f}% duplicate records"
        }
        
        recommendations = []
        
        # Quality-based recommendations
        if profile['data_quality_score']['overall'] < 0.7:
            recommendations.append("Data quality is below acceptable threshold - review data collection process")
        
        if profile['missing_data']['percentage_missing'] > 20:
            recommendations.append("High percentage of missing data - consider imputation strategies")
        
        if profile['duplicates']['duplicate_percentage'] > 5:
            recommendations.append("Significant duplicate records detected - implement deduplication")
        
        return {
            'dataset_id': dataset_id,
            'category': 'profiling',
            'metrics': profile,
            'insights': insights,
            'recommendations': recommendations,
            'quality_score': profile['data_quality_score']['overall'],
            'severity': self._calculate_severity(profile['data_quality_score']['overall'])
        }
    
    def _analyze_sentiment(self, dataset_id: int, df: pd.DataFrame) -> Dict[str, Any]:
        """Sentiment analysis"""
        
        # Extract text fields
        text_fields = []
        for col in df.columns:
            if col in ['text', 'content', 'caption', 'title', 'description']:
                if col in df.columns:
                    text_fields.extend(df[col].dropna().astype(str).tolist())
        
        if not text_fields:
            return self._empty_result(dataset_id, 'sentiment')
        
        # Calculate sentiment
        sentiments = [self._calculate_sentiment(text) for text in text_fields]
        sentiment_counts = Counter(sentiments)
        
        total = len(sentiments)
        sentiment_dist = {
            'positive': sentiment_counts.get('positive', 0) / total * 100,
            'neutral': sentiment_counts.get('neutral', 0) / total * 100,
            'negative': sentiment_counts.get('negative', 0) / total * 100
        }
        
        # Sentiment score (-1 to 1)
        sentiment_score = (
            (sentiment_counts.get('positive', 0) - sentiment_counts.get('negative', 0)) / total
        )
        
        metrics = {
            'sentiment_distribution': sentiment_dist,
            'sentiment_score': round(sentiment_score, 3),
            'total_analyzed': total,
            'dominant_sentiment': max(sentiment_counts, key=sentiment_counts.get)
        }
        
        insights = {
            'summary': f"Sentiment analysis of {total} text items",
            'dominant': f"Dominant sentiment: {metrics['dominant_sentiment']} ({sentiment_dist[metrics['dominant_sentiment']]:.1f}%)",
            'score': f"Overall sentiment score: {sentiment_score:.2f} (scale: -1 to 1)"
        }
        
        recommendations = []
        if sentiment_score < -0.3:
            recommendations.append("Predominantly negative sentiment detected - investigate root causes")
        elif sentiment_score > 0.3:
            recommendations.append("Strong positive sentiment - leverage for marketing and engagement")
        
        return {
            'dataset_id': dataset_id,
            'category': 'sentiment',
            'metrics': metrics,
            'insights': insights,
            'recommendations': recommendations,
            'quality_score': 0.85,  # Heuristic quality
            'severity': 'low' if abs(sentiment_score) < 0.5 else 'medium'
        }
    
    def _analyze_trends(self, dataset_id: int, df: pd.DataFrame) -> Dict[str, Any]:
        """Trend analysis over time"""
        
        # Time-based grouping
        time_col = None
        for col in ['created_at', 'fetched_at', 'published_at', 'timestamp']:
            if col in df.columns:
                time_col = col
                break
        
        if not time_col:
            return self._empty_result(dataset_id, 'trends')
        
        # Convert to datetime
        df[time_col] = pd.to_datetime(df[time_col], errors='coerce')
        df = df.dropna(subset=[time_col])
        
        if df.empty:
            return self._empty_result(dataset_id, 'trends')
        
        # Group by date
        df['date'] = df[time_col].dt.date
        daily_counts = df.groupby('date').size()
        
        # Calculate trend
        trend_direction = 'increasing' if daily_counts.iloc[-1] > daily_counts.iloc[0] else 'decreasing'
        avg_daily = daily_counts.mean()
        peak_day = daily_counts.idxmax()
        peak_count = daily_counts.max()
        
        # Platform breakdown
        platform_dist = df['platform'].value_counts().to_dict() if 'platform' in df.columns else {}
        
        metrics = {
            'total_days': len(daily_counts),
            'average_daily_volume': round(float(avg_daily), 2),
            'trend_direction': trend_direction,
            'peak_day': str(peak_day),
            'peak_volume': int(peak_count),
            'platform_distribution': platform_dist,
            'daily_timeline': {str(k): int(v) for k, v in daily_counts.to_dict().items()}
        }
        
        insights = {
            'summary': f"Analyzed {len(daily_counts)} days of data",
            'trend': f"Volume is {trend_direction} over time",
            'peak': f"Peak activity on {peak_day} with {peak_count} events"
        }
        
        recommendations = []
        if trend_direction == 'increasing':
            recommendations.append("Growing activity detected - monitor for sustained growth patterns")
        else:
            recommendations.append("Declining activity - investigate potential causes")
        
        return {
            'dataset_id': dataset_id,
            'category': 'trend',
            'metrics': metrics,
            'insights': insights,
            'recommendations': recommendations,
            'quality_score': 0.90,
            'severity': 'low'
        }
    
    def _analyze_engagement(self, dataset_id: int, df: pd.DataFrame) -> Dict[str, Any]:
        """Engagement metrics analysis"""
        
        engagement_fields = ['likes', 'retweets', 'comments', 'shares', 'views', 'score', 
                            'upvote_ratio', 'num_comments', 'replies']
        
        found_fields = [f for f in engagement_fields if f in df.columns]
        
        if not found_fields:
            return self._empty_result(dataset_id, 'engagement')
        
        metrics = {}
        
        for field in found_fields:
            if pd.api.types.is_numeric_dtype(df[field]):
                metrics[field] = {
                    'mean': round(float(df[field].mean()), 2),
                    'median': round(float(df[field].median()), 2),
                    'max': round(float(df[field].max()), 2),
                    'total': round(float(df[field].sum()), 2)
                }
        
        # Calculate engagement rate (simplified)
        if 'likes' in df.columns and 'views' in df.columns:
            engagement_rate = (df['likes'].sum() / df['views'].sum() * 100) if df['views'].sum() > 0 else 0
            metrics['engagement_rate'] = round(engagement_rate, 2)
        
        # Top performers
        if 'likes' in df.columns:
            top_posts = df.nlargest(5, 'likes')[['likes'] + [c for c in ['text', 'title'] if c in df.columns]]
            metrics['top_performers'] = top_posts.to_dict('records')
        
        insights = {
            'summary': f"Engagement analysis across {len(found_fields)} metrics",
            'metrics': ', '.join(found_fields)
        }
        
        recommendations = ["Monitor high-performing content for replication strategies"]
        
        return {
            'dataset_id': dataset_id,
            'category': 'engagement',
            'metrics': metrics,
            'insights': insights,
            'recommendations': recommendations,
            'quality_score': 0.88,
            'severity': 'low'
        }
    
    def _analyze_psychology(self, dataset_id: int, df: pd.DataFrame) -> Dict[str, Any]:
        """Psychology and opinion analysis"""
        
        # Extract text content
        text_content = []
        for col in ['text', 'content', 'caption', 'description']:
            if col in df.columns:
                text_content.extend(df[col].dropna().astype(str).tolist())
        
        if not text_content:
            return self._empty_result(dataset_id, 'psychology')
        
        # Extract keywords/topics
        all_words = []
        for text in text_content:
            words = re.findall(r'\b\w+\b', text.lower())
            all_words.extend([w for w in words if len(w) > 3])
        
        keyword_freq = Counter(all_words).most_common(20)
        
        # Detect emotions (simplified)
        emotion_keywords = {
            'joy': ['happy', 'joy', 'excited', 'love', 'wonderful'],
            'anger': ['angry', 'hate', 'frustrated', 'mad', 'annoyed'],
            'fear': ['scared', 'afraid', 'worried', 'anxious', 'fear'],
            'sadness': ['sad', 'depressed', 'unhappy', 'disappointed']
        }
        
        emotion_counts = {}
        for emotion, keywords in emotion_keywords.items():
            count = sum(1 for text in text_content 
                       if any(keyword in text.lower() for keyword in keywords))
            emotion_counts[emotion] = count
        
        metrics = {
            'top_keywords': [{'word': w, 'count': c} for w, c in keyword_freq],
            'emotion_distribution': emotion_counts,
            'total_analyzed': len(text_content),
            'vocabulary_size': len(set(all_words))
        }
        
        insights = {
            'summary': f"Analyzed {len(text_content)} texts for psychological patterns",
            'top_topics': ', '.join([w for w, _ in keyword_freq[:5]]),
            'dominant_emotion': max(emotion_counts, key=emotion_counts.get)
        }
        
        recommendations = [
            "Use top keywords for targeted messaging",
            "Align communication with detected emotional patterns"
        ]
        
        return {
            'dataset_id': dataset_id,
            'category': 'psychology',
            'metrics': metrics,
            'insights': insights,
            'recommendations': recommendations,
            'quality_score': 0.82,
            'severity': 'low'
        }
    
    def _calculate_sentiment(self, text: str) -> str:
        """Simple sentiment calculation"""
        text_lower = text.lower()
        
        pos_count = sum(1 for word in self.sentiment_keywords['positive'] if word in text_lower)
        neg_count = sum(1 for word in self.sentiment_keywords['negative'] if word in text_lower)
        
        if pos_count > neg_count:
            return 'positive'
        elif neg_count > pos_count:
            return 'negative'
        else:
            return 'neutral'
    
    def _calculate_severity(self, quality_score: float) -> str:
        """Calculate severity based on quality score"""
        if quality_score >= 0.9:
            return 'low'
        elif quality_score >= 0.7:
            return 'medium'
        elif quality_score >= 0.5:
            return 'high'
        else:
            return 'critical'
    
    def _empty_result(self, dataset_id: int, category: str) -> Dict[str, Any]:
        """Return empty result structure"""
        return {
            'dataset_id': dataset_id,
            'category': category,
            'metrics': {},
            'insights': {'summary': 'Insufficient data for analysis'},
            'recommendations': [],
            'quality_score': 0.0,
            'severity': 'low'
        }
