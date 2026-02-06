"""
VisionWire EdTech - LLM Client (Multi-Provider)
File: backend/app/utils/llm_client.py

Supports: Anthropic Claude, OpenAI GPT, Ollama (local), Groq
"""

from typing import Optional, Dict, Any, List
import logging
import json
import httpx
from anthropic import AsyncAnthropic
from openai import AsyncOpenAI

from app.config import settings
from app.core.exceptions import ContentGenerationError

logger = logging.getLogger(__name__)


class LLMClient:
    """Unified LLM client supporting multiple providers"""
    
    def __init__(self, provider: Optional[str] = None):
        self.provider = provider or settings.LLM_PROVIDER
        self._init_client()
    
    def _init_client(self):
        """Initialize the appropriate client based on provider"""
        if self.provider == "anthropic":
            if not settings.ANTHROPIC_API_KEY:
                raise ValueError("ANTHROPIC_API_KEY not set")
            self.client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
            self.model = settings.ANTHROPIC_MODEL
            
        elif self.provider == "openai":
            if not settings.OPENAI_API_KEY:
                raise ValueError("OPENAI_API_KEY not set")
            self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
            self.model = settings.OPENAI_MODEL
            
        elif self.provider == "groq":
            if not settings.GROQ_API_KEY:
                raise ValueError("GROQ_API_KEY not set")
            self.client = AsyncOpenAI(
                api_key=settings.GROQ_API_KEY,
                base_url="https://api.groq.com/openai/v1"
            )
            self.model = settings.GROQ_MODEL
            
        elif self.provider == "ollama":
            self.base_url = settings.OLLAMA_BASE_URL
            self.model = settings.OLLAMA_MODEL
            self.client = None  # Use httpx for Ollama
        
        else:
            raise ValueError(f"Unsupported LLM provider: {self.provider}")
    
    # ========================================================================
    # MAIN GENERATION METHOD
    # ========================================================================
    
    async def generate(
        self,
        prompt: str,
        max_tokens: int = 2000,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
        response_format: str = "text"
    ) -> Any:
        """
        Generate content using configured LLM provider
        
        Args:
            prompt: User prompt
            max_tokens: Maximum tokens to generate
            temperature: Creativity (0-1)
            system_prompt: Optional system message
            response_format: 'text' or 'json'
        
        Returns:
            Generated text or parsed JSON
        """
        
        try:
            if self.provider == "anthropic":
                response = await self._generate_anthropic(
                    prompt, max_tokens, temperature, system_prompt
                )
            elif self.provider in ["openai", "groq"]:
                response = await self._generate_openai(
                    prompt, max_tokens, temperature, system_prompt
                )
            elif self.provider == "ollama":
                response = await self._generate_ollama(
                    prompt, max_tokens, temperature, system_prompt
                )
            else:
                raise ContentGenerationError(f"Provider {self.provider} not implemented")
            
            # Parse JSON if requested
            if response_format == "json":
                try:
                    # Extract JSON from response if wrapped in markdown
                    if "```json" in response:
                        response = response.split("```json")[1].split("```")[0].strip()
                    elif "```" in response:
                        response = response.split("```")[1].split("```")[0].strip()
                    
                    return json.loads(response)
                except json.JSONDecodeError as e:
                    logger.warning(f"Failed to parse JSON response: {e}")
                    return response
            
            return response
            
        except Exception as e:
            logger.error(f"LLM generation failed: {e}")
            raise ContentGenerationError(f"Content generation failed: {str(e)}")
    
    # ========================================================================
    # PROVIDER-SPECIFIC IMPLEMENTATIONS
    # ========================================================================
    
    async def _generate_anthropic(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        system_prompt: Optional[str]
    ) -> str:
        """Generate using Anthropic Claude"""
        
        messages = [{"role": "user", "content": prompt}]
        
        kwargs = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": messages
        }
        
        if system_prompt:
            kwargs["system"] = system_prompt
        
        response = await self.client.messages.create(**kwargs)
        return response.content[0].text
    
    async def _generate_openai(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        system_prompt: Optional[str]
    ) -> str:
        """Generate using OpenAI GPT or Groq"""
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature
        )
        
        return response.choices[0].message.content
    
    async def _generate_ollama(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        system_prompt: Optional[str]
    ) -> str:
        """Generate using local Ollama"""
        
        url = f"{self.base_url}/api/generate"
        
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
        
        if system_prompt:
            payload["system"] = system_prompt
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            result = response.json()
            return result.get("response", "")
    
    # ========================================================================
    # STREAMING SUPPORT
    # ========================================================================
    
    async def generate_stream(
        self,
        prompt: str,
        max_tokens: int = 2000,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None
    ):
        """
        Generate content with streaming (for real-time UI updates)
        Yields chunks of text as they're generated
        """
        
        if self.provider == "anthropic":
            async for chunk in self._stream_anthropic(
                prompt, max_tokens, temperature, system_prompt
            ):
                yield chunk
                
        elif self.provider in ["openai", "groq"]:
            async for chunk in self._stream_openai(
                prompt, max_tokens, temperature, system_prompt
            ):
                yield chunk
        
        else:
            # Fallback to non-streaming
            result = await self.generate(prompt, max_tokens, temperature, system_prompt)
            yield result
    
    async def _stream_anthropic(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        system_prompt: Optional[str]
    ):
        """Stream from Anthropic Claude"""
        
        messages = [{"role": "user", "content": prompt}]
        
        kwargs = {
            "model": self.model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": messages,
            "stream": True
        }
        
        if system_prompt:
            kwargs["system"] = system_prompt
        
        async with self.client.messages.stream(**kwargs) as stream:
            async for text in stream.text_stream:
                yield text
    
    async def _stream_openai(
        self,
        prompt: str,
        max_tokens: int,
        temperature: float,
        system_prompt: Optional[str]
    ):
        """Stream from OpenAI/Groq"""
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        stream = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature,
            stream=True
        )
        
        async for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content
    
    # ========================================================================
    # EMBEDDINGS
    # ========================================================================
    
    async def get_embedding(self, text: str) -> List[float]:
        """
        Generate embedding vector for text
        Used for semantic search
        """
        
        try:
            if self.provider == "openai":
                response = await self.client.embeddings.create(
                    model=settings.EMBEDDING_MODEL,
                    input=text
                )
                return response.data[0].embedding
            
            elif self.provider == "ollama":
                url = f"{self.base_url}/api/embeddings"
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        url,
                        json={"model": self.model, "prompt": text}
                    )
                    result = response.json()
                    return result.get("embedding", [])
            
            else:
                logger.warning(f"Embeddings not supported for {self.provider}")
                return []
                
        except Exception as e:
            logger.error(f"Embedding generation failed: {e}")
            return []
    
    async def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for multiple texts"""
        
        if self.provider == "openai":
            try:
                response = await self.client.embeddings.create(
                    model=settings.EMBEDDING_MODEL,
                    input=texts
                )
                return [item.embedding for item in response.data]
            except Exception as e:
                logger.error(f"Batch embedding failed: {e}")
                return []
        
        # Fallback to sequential
        embeddings = []
        for text in texts:
            embedding = await self.get_embedding(text)
            embeddings.append(embedding)
        return embeddings
    
    # ========================================================================
    # UTILITY METHODS
    # ========================================================================
    
    async def count_tokens(self, text: str) -> int:
        """
        Estimate token count for text
        Rough approximation: 1 token ≈ 4 characters
        """
        return len(text) // 4
    
    async def validate_response(self, response: str, expected_format: str = "text") -> bool:
        """Validate that response matches expected format"""
        
        if expected_format == "json":
            try:
                json.loads(response)
                return True
            except:
                return False
        
        elif expected_format == "markdown":
            return "##" in response or "**" in response
        
        elif expected_format == "mermaid":
            return any(keyword in response for keyword in [
                "graph", "flowchart", "sequenceDiagram", "classDiagram"
            ])
        
        return True


async def test_connection() -> bool:
    """Test LLM connection"""
    try:
        client = LLMClient()
        response = await client.generate("Say 'Hello'", max_tokens=10)
        return bool(response)
    except Exception as e:
        logger.error(f"LLM connection test failed: {e}")
        return False


# ========================================================================
# PROMPT TEMPLATES
# ========================================================================

class PromptTemplates:
    """Reusable prompt templates for common tasks"""
    
    @staticmethod
    def educational_content(
        topic: str,
        context: str,
        style: str = "comprehensive"
    ) -> str:
        return f"""You are an expert educational content creator.

Topic: {topic}
Context: {context}
Style: {style}

Create high-quality educational content that:
1. Is accurate and well-researched
2. Uses clear, simple language
3. Includes relevant examples
4. Engages students effectively
5. Follows pedagogical best practices

Content:"""
    
    @staticmethod
    def doubt_resolution(
        question: str,
        student_level: str,
        context: str
    ) -> str:
        return f"""You are a patient, knowledgeable tutor helping a student.

Student's Question: {question}
Student Level: {student_level}
Context: {context}

Provide a clear, helpful explanation that:
1. Directly addresses the question
2. Uses language appropriate for the student's level
3. Includes step-by-step reasoning
4. Gives relevant examples
5. Encourages further learning

Response:"""
    
    @staticmethod
    def assessment_generation(
        topic: str,
        difficulty: str,
        question_type: str,
        num_questions: int
    ) -> str:
        return f"""Generate {num_questions} high-quality {question_type} questions.

Topic: {topic}
Difficulty: {difficulty}

Requirements:
1. Clear, unambiguous questions
2. Appropriate difficulty level
3. Educational value
4. Correct answers provided
5. Explanations for solutions

Format as JSON array with:
- question_text
- options (for MCQ)
- correct_answer
- explanation
- difficulty_level

Questions:"""