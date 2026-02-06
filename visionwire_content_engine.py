"""
VisionWire EdTech - AI Content Generation Engine
File: backend/app/services/content_generator.py

Generates educational content using LLMs: notes, summaries, explanations, diagrams, etc.
"""

from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
import logging
from datetime import datetime

from app.models import Content, Topic, ContentType, DifficultyLevel
from app.utils.llm_client import LLMClient
from app.core.exceptions import ContentGenerationError
from app.config import settings

logger = logging.getLogger(__name__)


class ContentGenerator:
    """AI-powered educational content generator"""
    
    def __init__(self, db: Session):
        self.db = db
        self.llm_client = LLMClient()
    
    # ========================================================================
    # NOTES GENERATION
    # ========================================================================
    
    async def generate_notes(
        self,
        topic_id: int,
        style: str = "comprehensive",
        language: str = "en"
    ) -> Content:
        """
        Generate detailed notes for a topic
        
        Args:
            topic_id: Topic ID
            style: comprehensive, concise, bullet_points
            language: Language code (en, hi, etc.)
        """
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise ContentGenerationError(f"Topic {topic_id} not found")
        
        # Build prompt
        prompt = self._build_notes_prompt(topic, style, language)
        
        # Generate content
        try:
            content_text = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=settings.MAX_NOTES_LENGTH,
                temperature=0.7
            )
            
            # Create content record
            content = Content(
                topic_id=topic_id,
                content_type=ContentType.NOTES,
                title=f"Notes: {topic.name}",
                description=f"Comprehensive notes on {topic.name}",
                content_text=content_text,
                language=language,
                is_ai_generated=True,
                generation_prompt=prompt,
                generation_model=settings.LLM_PROVIDER,
                generated_at=datetime.utcnow(),
                difficulty_level=topic.difficulty_level
            )
            
            self.db.add(content)
            self.db.commit()
            self.db.refresh(content)
            
            logger.info(f"Generated notes for topic {topic_id}")
            return content
            
        except Exception as e:
            logger.error(f"Notes generation failed: {e}")
            raise ContentGenerationError(str(e))
    
    def _build_notes_prompt(self, topic: Topic, style: str, language: str) -> str:
        """Build prompt for notes generation"""
        
        style_instructions = {
            "comprehensive": "detailed, in-depth coverage with examples",
            "concise": "brief, to-the-point summary",
            "bullet_points": "organized bullet points with key concepts"
        }
        
        prompt = f"""Generate comprehensive educational notes on the following topic:

Topic: {topic.name}
Description: {topic.description}
Key Concepts: {', '.join(topic.key_concepts) if topic.key_concepts else 'N/A'}
Learning Outcomes: {', '.join(topic.learning_outcomes) if topic.learning_outcomes else 'N/A'}
Difficulty Level: {topic.difficulty_level}

Style: {style_instructions.get(style, 'comprehensive')}
Language: {language}

Instructions:
1. Start with an introduction explaining why this topic is important
2. Break down the topic into clear sections
3. Include real-world examples and applications
4. Use simple language appropriate for students
5. Add practice questions at the end
6. Format in Markdown with proper headings and structure

Generate the notes now:"""
        
        return prompt
    
    # ========================================================================
    # SUMMARY GENERATION
    # ========================================================================
    
    async def generate_summary(
        self,
        topic_id: int,
        max_words: int = 300,
        language: str = "en"
    ) -> Content:
        """Generate concise summary of a topic"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise ContentGenerationError(f"Topic {topic_id} not found")
        
        prompt = f"""Create a concise summary (max {max_words} words) for:

Topic: {topic.name}
Description: {topic.description}
Key Concepts: {', '.join(topic.key_concepts) if topic.key_concepts else 'N/A'}

Requirements:
- Cover all key concepts
- Use simple, clear language
- Perfect for quick revision
- Language: {language}

Summary:"""
        
        try:
            summary_text = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=max_words * 2,  # Roughly 2 tokens per word
                temperature=0.5
            )
            
            content = Content(
                topic_id=topic_id,
                content_type=ContentType.SUMMARY,
                title=f"Summary: {topic.name}",
                content_text=summary_text,
                language=language,
                is_ai_generated=True,
                generation_prompt=prompt,
                generated_at=datetime.utcnow()
            )
            
            self.db.add(content)
            self.db.commit()
            self.db.refresh(content)
            
            return content
            
        except Exception as e:
            raise ContentGenerationError(f"Summary generation failed: {e}")
    
    # ========================================================================
    # EXPLANATION GENERATION
    # ========================================================================
    
    async def generate_explanation(
        self,
        concept: str,
        context: str,
        difficulty: str = "medium",
        language: str = "en"
    ) -> str:
        """
        Generate explanation for a specific concept
        Used by AI tutor for doubt resolution
        """
        
        difficulty_levels = {
            "easy": "Explain as if teaching a beginner. Use very simple language and analogies.",
            "medium": "Explain with moderate detail, suitable for average students.",
            "hard": "Provide in-depth explanation with technical details."
        }
        
        prompt = f"""Explain the following concept clearly:

Concept: {concept}
Context: {context}

{difficulty_levels.get(difficulty, difficulty_levels['medium'])}

Requirements:
- Start with a simple definition
- Use real-world examples or analogies
- Break down complex parts step-by-step
- End with a key takeaway
- Language: {language}

Explanation:"""
        
        try:
            explanation = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=1000,
                temperature=0.7
            )
            return explanation
        except Exception as e:
            raise ContentGenerationError(f"Explanation generation failed: {e}")
    
    # ========================================================================
    # EXAMPLE GENERATION
    # ========================================================================
    
    async def generate_examples(
        self,
        topic_id: int,
        num_examples: int = 5,
        language: str = "en"
    ) -> Content:
        """Generate practical examples for a topic"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise ContentGenerationError(f"Topic {topic_id} not found")
        
        prompt = f"""Generate {num_examples} practical, real-world examples for:

Topic: {topic.name}
Description: {topic.description}

Requirements:
1. Each example should illustrate a key concept
2. Include step-by-step solutions where applicable
3. Use real-world scenarios students can relate to
4. Gradually increase difficulty
5. Format each example clearly with:
   - Example number and title
   - Problem/scenario
   - Solution/explanation
   - Key insight
6. Language: {language}

Examples:"""
        
        try:
            examples_text = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=2000,
                temperature=0.8
            )
            
            content = Content(
                topic_id=topic_id,
                content_type=ContentType.EXAMPLE,
                title=f"Examples: {topic.name}",
                content_text=examples_text,
                language=language,
                is_ai_generated=True,
                generation_prompt=prompt,
                generated_at=datetime.utcnow()
            )
            
            self.db.add(content)
            self.db.commit()
            self.db.refresh(content)
            
            return content
            
        except Exception as e:
            raise ContentGenerationError(f"Example generation failed: {e}")
    
    # ========================================================================
    # DIAGRAM GENERATION
    # ========================================================================
    
    async def generate_diagram(
        self,
        topic_id: int,
        diagram_type: str = "flowchart"
    ) -> Content:
        """
        Generate diagram in Mermaid syntax
        
        Types: flowchart, mindmap, sequence, class, er
        """
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise ContentGenerationError(f"Topic {topic_id} not found")
        
        prompt = f"""Generate a {diagram_type} diagram in Mermaid syntax for:

Topic: {topic.name}
Description: {topic.description}
Key Concepts: {', '.join(topic.key_concepts) if topic.key_concepts else 'N/A'}

Requirements:
1. Use valid Mermaid syntax
2. Make it clear and educational
3. Include all key concepts
4. Add proper labels and connections
5. Keep it clean and not too complex

Mermaid code:"""
        
        try:
            diagram_code = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=1500,
                temperature=0.5
            )
            
            # Clean up the response to ensure it's valid Mermaid
            diagram_code = self._clean_mermaid_code(diagram_code)
            
            content = Content(
                topic_id=topic_id,
                content_type=ContentType.DIAGRAM,
                title=f"{diagram_type.title()}: {topic.name}",
                content_text=diagram_code,
                is_ai_generated=True,
                generation_prompt=prompt,
                generated_at=datetime.utcnow()
            )
            
            self.db.add(content)
            self.db.commit()
            self.db.refresh(content)
            
            return content
            
        except Exception as e:
            raise ContentGenerationError(f"Diagram generation failed: {e}")
    
    def _clean_mermaid_code(self, code: str) -> str:
        """Clean and validate Mermaid code"""
        # Remove markdown code blocks if present
        code = code.replace("```mermaid", "").replace("```", "")
        code = code.strip()
        return code
    
    # ========================================================================
    # FLASHCARD GENERATION
    # ========================================================================
    
    async def generate_flashcards(
        self,
        topic_id: int,
        num_cards: int = 10,
        language: str = "en"
    ) -> Content:
        """Generate flashcards for topic revision"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise ContentGenerationError(f"Topic {topic_id} not found")
        
        prompt = f"""Generate {num_cards} flashcards for revision:

Topic: {topic.name}
Key Concepts: {', '.join(topic.key_concepts) if topic.key_concepts else 'N/A'}

Requirements:
1. Each flashcard should have a front (question/term) and back (answer/definition)
2. Cover all important concepts
3. Keep questions clear and concise
4. Answers should be brief but complete
5. Language: {language}

Format as JSON:
{{
  "flashcards": [
    {{"front": "Question or term", "back": "Answer or definition"}},
    ...
  ]
}}

Flashcards:"""
        
        try:
            flashcards_json = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=2000,
                temperature=0.7,
                response_format="json"
            )
            
            content = Content(
                topic_id=topic_id,
                content_type=ContentType.FLASHCARD,
                title=f"Flashcards: {topic.name}",
                content_json=flashcards_json,
                language=language,
                is_ai_generated=True,
                generation_prompt=prompt,
                generated_at=datetime.utcnow()
            )
            
            self.db.add(content)
            self.db.commit()
            self.db.refresh(content)
            
            return content
            
        except Exception as e:
            raise ContentGenerationError(f"Flashcard generation failed: {e}")
    
    # ========================================================================
    # VIDEO SCRIPT GENERATION
    # ========================================================================
    
    async def generate_video_script(
        self,
        topic_id: int,
        duration_minutes: int = 10,
        language: str = "en"
    ) -> Content:
        """Generate script for video lesson"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise ContentGenerationError(f"Topic {topic_id} not found")
        
        prompt = f"""Create a {duration_minutes}-minute video lesson script for:

Topic: {topic.name}
Description: {topic.description}
Learning Outcomes: {', '.join(topic.learning_outcomes) if topic.learning_outcomes else 'N/A'}

Script Structure:
1. INTRO (0:30) - Hook and topic introduction
2. MAIN CONTENT ({duration_minutes-2} minutes) - Core teaching
3. EXAMPLES (1:00) - Practical examples
4. RECAP (0:30) - Key points summary

Requirements:
- Write natural, conversational narration
- Include [VISUAL: description] cues for animations/graphics
- Mark timing for each section
- Keep language clear and engaging
- Language: {language}

Script:"""
        
        try:
            script_text = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=3000,
                temperature=0.8
            )
            
            content = Content(
                topic_id=topic_id,
                content_type=ContentType.VIDEO,
                title=f"Video Script: {topic.name}",
                content_text=script_text,
                duration_seconds=duration_minutes * 60,
                language=language,
                is_ai_generated=True,
                generation_prompt=prompt,
                generated_at=datetime.utcnow()
            )
            
            self.db.add(content)
            self.db.commit()
            self.db.refresh(content)
            
            return content
            
        except Exception as e:
            raise ContentGenerationError(f"Video script generation failed: {e}")
    
    # ========================================================================
    # BATCH CONTENT GENERATION
    # ========================================================================
    
    async def generate_complete_content_package(
        self,
        topic_id: int,
        language: str = "en"
    ) -> Dict[str, Content]:
        """
        Generate complete content package for a topic:
        - Notes
        - Summary
        - Examples
        - Flashcards
        - Diagram
        """
        
        logger.info(f"Generating complete content package for topic {topic_id}")
        
        package = {}
        
        try:
            # Generate notes
            package["notes"] = await self.generate_notes(topic_id, language=language)
            
            # Generate summary
            package["summary"] = await self.generate_summary(topic_id, language=language)
            
            # Generate examples
            package["examples"] = await self.generate_examples(topic_id, language=language)
            
            # Generate flashcards
            package["flashcards"] = await self.generate_flashcards(topic_id, language=language)
            
            # Generate diagram
            package["diagram"] = await self.generate_diagram(topic_id)
            
            logger.info(f"Successfully generated complete package for topic {topic_id}")
            return package
            
        except Exception as e:
            logger.error(f"Package generation failed: {e}")
            raise ContentGenerationError(f"Failed to generate complete package: {e}")
    
    # ========================================================================
    # CONTENT QUALITY ASSESSMENT
    # ========================================================================
    
    async def assess_content_quality(self, content_id: int) -> Dict[str, Any]:
        """
        Assess quality of generated content
        Returns quality score and feedback
        """
        
        content = self.db.query(Content).filter(Content.id == content_id).first()
        if not content:
            raise ContentGenerationError(f"Content {content_id} not found")
        
        prompt = f"""Assess the quality of this educational content:

Content Type: {content.content_type}
Content:
{content.content_text[:2000]}  # First 2000 chars

Evaluate on:
1. Accuracy - Is the information correct?
2. Clarity - Is it easy to understand?
3. Completeness - Does it cover the topic well?
4. Engagement - Is it interesting for students?
5. Structure - Is it well-organized?

Provide:
- Overall quality score (0-100)
- Scores for each criterion (0-10)
- Brief feedback on strengths and improvements

Format as JSON:
{{
  "overall_score": 85,
  "accuracy": 9,
  "clarity": 8,
  "completeness": 8,
  "engagement": 9,
  "structure": 9,
  "strengths": ["..."],
  "improvements": ["..."]
}}"""
        
        try:
            assessment = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=500,
                temperature=0.3,
                response_format="json"
            )
            
            # Update content quality score
            if isinstance(assessment, dict):
                content.quality_score = assessment.get("overall_score", 0)
                self.db.commit()
            
            return assessment
            
        except Exception as e:
            logger.error(f"Quality assessment failed: {e}")
            return {"error": str(e)}