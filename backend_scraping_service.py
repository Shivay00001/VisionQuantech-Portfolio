"""
Web scraping service for extracting data from websites
Modular, production-ready implementation
"""
import httpx
from bs4 import BeautifulSoup
from typing import Dict, List, Optional, Any
import hashlib
import logging
from datetime import datetime
from urllib.parse import urljoin, urlparse
import asyncio

from app.core.config import settings

logger = logging.getLogger(__name__)

class ScrapingService:
    """Web scraping service with auto-extraction capabilities"""
    
    def __init__(self):
        self.client = httpx.AsyncClient(
            timeout=settings.REQUEST_TIMEOUT,
            headers={"User-Agent": settings.USER_AGENT},
            follow_redirects=True
        )
    
    async def fetch_web_page(
        self,
        url: str,
        selectors: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Fetch and extract data from a web page
        
        Args:
            url: Target URL
            selectors: Optional CSS selectors for targeted extraction
        
        Returns:
            Extracted data dictionary
        """
        try:
            response = await self._make_request(url)
            soup = BeautifulSoup(response.text, 'html.parser')
            
            if selectors:
                extracted = self._extract_with_selectors(soup, selectors, url)
            else:
                extracted = self._auto_extract(soup, url)
            
            extracted['url'] = url
            extracted['fetched_at'] = datetime.utcnow().isoformat()
            extracted['content_hash'] = self._generate_hash(extracted)
            
            return extracted
            
        except Exception as e:
            logger.error(f"Error fetching {url}: {e}")
            raise
    
    async def bulk_fetch(self, urls: List[str]) -> List[Dict[str, Any]]:
        """Fetch multiple URLs concurrently"""
        tasks = [self.fetch_web_page(url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out exceptions
        valid_results = []
        for result in results:
            if isinstance(result, Exception):
                logger.error(f"Bulk fetch error: {result}")
            else:
                valid_results.append(result)
        
        return valid_results
    
    async def extract_tables(self, url: str, table_index: int = 0) -> Dict[str, Any]:
        """Extract table data from a webpage"""
        try:
            response = await self._make_request(url)
            soup = BeautifulSoup(response.text, 'html.parser')
            
            tables = soup.find_all('table')
            if not tables or table_index >= len(tables):
                return {"error": "Table not found", "table_count": len(tables)}
            
            table = tables[table_index]
            headers = [th.get_text(strip=True) for th in table.find_all('th')]
            rows = []
            
            for tr in table.find_all('tr')[1:]:  # Skip header row
                cells = [td.get_text(strip=True) for td in tr.find_all(['td', 'th'])]
                if cells:
                    rows.append(cells)
            
            return {
                "url": url,
                "table_index": table_index,
                "headers": headers,
                "rows": rows,
                "row_count": len(rows),
                "fetched_at": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error extracting table from {url}: {e}")
            raise
    
    async def _make_request(self, url: str, retries: int = 0) -> httpx.Response:
        """Make HTTP request with retry logic"""
        try:
            await asyncio.sleep(settings.RATE_LIMIT_DELAY)
            response = await self.client.get(url)
            response.raise_for_status()
            return response
            
        except httpx.HTTPError as e:
            if retries < settings.MAX_RETRIES:
                logger.warning(f"Retry {retries + 1} for {url}")
                await asyncio.sleep(2 ** retries)  # Exponential backoff
                return await self._make_request(url, retries + 1)
            raise
    
    def _extract_with_selectors(
        self,
        soup: BeautifulSoup,
        selectors: Dict[str, str],
        base_url: str
    ) -> Dict[str, Any]:
        """Extract data using provided CSS selectors"""
        extracted = {}
        
        for field, selector in selectors.items():
            elements = soup.select(selector)
            if elements:
                if len(elements) == 1:
                    extracted[field] = elements[0].get_text(strip=True)
                else:
                    extracted[field] = [el.get_text(strip=True) for el in elements]
            else:
                extracted[field] = None
        
        return extracted
    
    def _auto_extract(self, soup: BeautifulSoup, base_url: str) -> Dict[str, Any]:
        """Automatically extract common elements from webpage"""
        
        # Extract title
        title = soup.find('title')
        title_text = title.get_text(strip=True) if title else None
        
        # Extract headings
        headings = []
        for tag in ['h1', 'h2', 'h3']:
            for heading in soup.find_all(tag):
                headings.append({
                    "level": tag,
                    "text": heading.get_text(strip=True)
                })
        
        # Extract paragraphs
        paragraphs = [p.get_text(strip=True) for p in soup.find_all('p') if p.get_text(strip=True)]
        
        # Extract links
        links = []
        for a in soup.find_all('a', href=True):
            href = urljoin(base_url, a['href'])
            text = a.get_text(strip=True)
            if text:
                links.append({"text": text, "url": href})
        
        # Extract images
        images = []
        for img in soup.find_all('img', src=True):
            src = urljoin(base_url, img['src'])
            alt = img.get('alt', '')
            images.append({"src": src, "alt": alt})
        
        # Extract meta tags
        meta = {}
        for tag in soup.find_all('meta'):
            name = tag.get('name') or tag.get('property')
            content = tag.get('content')
            if name and content:
                meta[name] = content
        
        return {
            "title": title_text,
            "headings": headings[:10],  # Limit to first 10
            "paragraphs": paragraphs[:20],  # Limit to first 20
            "links": links[:50],  # Limit to first 50
            "images": images[:20],  # Limit to first 20
            "meta": meta,
            "text_content": soup.get_text(separator=' ', strip=True)[:5000]  # First 5000 chars
        }
    
    def _generate_hash(self, data: Dict[str, Any]) -> str:
        """Generate content hash for deduplication"""
        content_str = str(sorted(data.items()))
        return hashlib.sha256(content_str.encode()).hexdigest()
    
    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()
