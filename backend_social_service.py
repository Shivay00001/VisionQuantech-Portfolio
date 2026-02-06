"""
Social media extraction service
Simulated connectors that can be replaced with real APIs
"""
import hashlib
import random
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import logging

logger = logging.getLogger(__name__)

class SocialService:
    """Social media data extraction service"""
    
    def __init__(self):
        self.platforms = ['twitter', 'reddit', 'youtube', 'instagram']
    
    async def fetch_twitter(
        self,
        query: str,
        count: int = 100,
        since_date: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Fetch tweets (simulated - replace with Twitter API)
        
        Args:
            query: Search query or hashtag
            count: Number of tweets to fetch
            since_date: ISO date string
        
        Returns:
            List of tweet data
        """
        logger.info(f"Fetching Twitter data for query: {query}")
        
        # Simulated data - replace with real Twitter API calls
        tweets = []
        sentiments = ['positive', 'neutral', 'negative']
        
        for i in range(count):
            tweet_text = self._generate_sample_text('twitter', query)
            
            tweet = {
                "id": f"tweet_{random.randint(100000, 999999)}",
                "text": tweet_text,
                "author": f"user_{random.randint(1000, 9999)}",
                "created_at": self._random_timestamp().isoformat(),
                "likes": random.randint(0, 1000),
                "retweets": random.randint(0, 500),
                "replies": random.randint(0, 100),
                "sentiment": random.choice(sentiments),
                "hashtags": [query] if query.startswith('#') else [],
                "platform": "twitter",
                "query": query
            }
            
            tweet['content_hash'] = self._generate_hash(tweet)
            tweets.append(tweet)
        
        return tweets
    
    async def fetch_reddit(
        self,
        subreddit: str,
        limit: int = 100,
        sort: str = "hot"
    ) -> List[Dict[str, Any]]:
        """
        Fetch Reddit posts (simulated - replace with Reddit API)
        
        Args:
            subreddit: Subreddit name
            limit: Number of posts to fetch
            sort: Sorting method (hot, new, top)
        
        Returns:
            List of Reddit post data
        """
        logger.info(f"Fetching Reddit data from r/{subreddit}")
        
        posts = []
        
        for i in range(limit):
            post_text = self._generate_sample_text('reddit', subreddit)
            
            post = {
                "id": f"reddit_{random.randint(100000, 999999)}",
                "title": f"Discussion about {subreddit} - {i+1}",
                "text": post_text,
                "author": f"redditor_{random.randint(1000, 9999)}",
                "subreddit": subreddit,
                "created_at": self._random_timestamp().isoformat(),
                "score": random.randint(-10, 1000),
                "upvote_ratio": random.uniform(0.5, 1.0),
                "num_comments": random.randint(0, 500),
                "platform": "reddit",
                "url": f"https://reddit.com/r/{subreddit}/comments/{random.randint(100000, 999999)}"
            }
            
            post['content_hash'] = self._generate_hash(post)
            posts.append(post)
        
        return posts
    
    async def fetch_youtube(
        self,
        video_id: Optional[str] = None,
        channel_id: Optional[str] = None,
        search_query: Optional[str] = None,
        max_results: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Fetch YouTube data (simulated - replace with YouTube API)
        
        Args:
            video_id: Specific video ID
            channel_id: Channel ID to fetch from
            search_query: Search query
            max_results: Maximum results
        
        Returns:
            List of YouTube video/comment data
        """
        logger.info(f"Fetching YouTube data")
        
        videos = []
        
        for i in range(max_results):
            video = {
                "id": video_id or f"video_{random.randint(100000, 999999)}",
                "title": f"Video about {search_query or 'topic'} - {i+1}",
                "description": self._generate_sample_text('youtube', search_query or ''),
                "channel": channel_id or f"channel_{random.randint(1000, 9999)}",
                "published_at": self._random_timestamp().isoformat(),
                "views": random.randint(100, 1000000),
                "likes": random.randint(10, 50000),
                "comments_count": random.randint(0, 5000),
                "duration": f"{random.randint(1, 60)}:{random.randint(0, 59):02d}",
                "platform": "youtube",
                "url": f"https://youtube.com/watch?v={video_id or random.randint(100000, 999999)}"
            }
            
            video['content_hash'] = self._generate_hash(video)
            videos.append(video)
        
        return videos
    
    async def fetch_instagram(
        self,
        hashtag: Optional[str] = None,
        username: Optional[str] = None,
        count: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Fetch Instagram posts (simulated - replace with Instagram API)
        
        Args:
            hashtag: Hashtag to search
            username: Username to fetch posts from
            count: Number of posts
        
        Returns:
            List of Instagram post data
        """
        logger.info(f"Fetching Instagram data")
        
        posts = []
        
        for i in range(count):
            post = {
                "id": f"ig_{random.randint(100000, 999999)}",
                "caption": self._generate_sample_text('instagram', hashtag or username or ''),
                "username": username or f"user_{random.randint(1000, 9999)}",
                "created_at": self._random_timestamp().isoformat(),
                "likes": random.randint(0, 10000),
                "comments": random.randint(0, 500),
                "hashtags": [hashtag] if hashtag else [],
                "media_type": random.choice(['photo', 'video', 'carousel']),
                "platform": "instagram",
                "url": f"https://instagram.com/p/{random.randint(100000, 999999)}"
            }
            
            post['content_hash'] = self._generate_hash(post)
            posts.append(post)
        
        return posts
    
    def _generate_sample_text(self, platform: str, context: str) -> str:
        """Generate sample text for simulation"""
        templates = {
            'twitter': [
                f"Interesting discussion about {context}! #trending",
                f"Just learned something new about {context}",
                f"What are your thoughts on {context}?",
                f"Breaking: Latest updates on {context}",
            ],
            'reddit': [
                f"I've been researching {context} and here's what I found...",
                f"ELI5: How does {context} actually work?",
                f"Unpopular opinion about {context}",
                f"TIL something fascinating about {context}",
            ],
            'youtube': [
                f"In this video, we explore {context} in depth",
                f"Tutorial: Everything you need to know about {context}",
                f"My honest review of {context}",
                f"The truth about {context} that nobody talks about",
            ],
            'instagram': [
                f"Beautiful day exploring {context} ✨",
                f"Throwback to when I discovered {context} 📸",
                f"Can't get enough of {context} lately 💫",
                f"Sharing my {context} journey with you all 🌟",
            ]
        }
        
        return random.choice(templates.get(platform, ["Sample content"]))
    
    def _random_timestamp(self) -> datetime:
        """Generate random timestamp within last 7 days"""
        days_ago = random.randint(0, 7)
        hours_ago = random.randint(0, 23)
        return datetime.utcnow() - timedelta(days=days_ago, hours=hours_ago)
    
    def _generate_hash(self, data: Dict[str, Any]) -> str:
        """Generate content hash for deduplication"""
        # Use stable fields for hashing
        hash_fields = ['id', 'platform']
        content_str = str({k: data.get(k) for k in hash_fields if k in data})
        return hashlib.sha256(content_str.encode()).hexdigest()
