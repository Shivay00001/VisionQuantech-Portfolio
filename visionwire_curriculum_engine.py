"""
VisionWire EdTech - Curriculum Engine Service
File: backend/app/services/curriculum_engine.py

This service manages curriculum hierarchies, learning paths, and prerequisites
"""

from typing import List, Dict, Any, Optional, Set
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
import json
import logging
from pathlib import Path

from app.models import Board, Subject, Chapter, Topic, LearningProgress
from app.core.exceptions import NotFoundError, ValidationError
from app.core.cache import cache_result, get_cache, set_cache

logger = logging.getLogger(__name__)


class CurriculumEngine:
    """
    Core curriculum management engine
    Handles board/subject/chapter/topic hierarchies and learning path generation
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.curriculum_cache: Dict[str, Any] = {}
    
    # ========================================================================
    # CURRICULUM HIERARCHY QUERIES
    # ========================================================================
    
    def get_boards(self, active_only: bool = True) -> List[Board]:
        """Get all available boards"""
        query = self.db.query(Board)
        if active_only:
            query = query.filter(Board.is_active == True)
        return query.all()
    
    def get_board_by_code(self, board_code: str) -> Board:
        """Get board by code (e.g., 'CBSE', 'ICSE')"""
        board = self.db.query(Board).filter(Board.code == board_code).first()
        if not board:
            raise NotFoundError(f"Board '{board_code}'")
        return board
    
    def get_subjects_by_board(
        self,
        board_id: int,
        grade_level: Optional[int] = None,
        mandatory_only: bool = False
    ) -> List[Subject]:
        """Get subjects for a specific board and grade"""
        query = self.db.query(Subject).filter(Subject.board_id == board_id)
        
        if grade_level:
            query = query.filter(Subject.grade_level == grade_level)
        
        if mandatory_only:
            query = query.filter(Subject.is_mandatory == True)
        
        query = query.filter(Subject.is_active == True).order_by(Subject.order)
        return query.all()
    
    def get_chapters_by_subject(self, subject_id: int) -> List[Chapter]:
        """Get all chapters for a subject"""
        return self.db.query(Chapter).filter(
            Chapter.subject_id == subject_id,
            Chapter.is_active == True
        ).order_by(Chapter.order).all()
    
    def get_topics_by_chapter(self, chapter_id: int) -> List[Topic]:
        """Get all topics for a chapter"""
        return self.db.query(Topic).filter(
            Topic.chapter_id == chapter_id,
            Topic.is_active == True
        ).order_by(Topic.order).all()
    
    def get_topic_by_id(self, topic_id: int) -> Topic:
        """Get topic by ID"""
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise NotFoundError(f"Topic with ID {topic_id}")
        return topic
    
    # ========================================================================
    # CURRICULUM STRUCTURE BUILDING
    # ========================================================================
    
    @cache_result(ttl=3600, key_prefix="curriculum_tree")
    async def get_curriculum_tree(
        self,
        board_code: str,
        grade_level: int,
        subject_code: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Build complete curriculum tree for a board/grade/subject
        Returns hierarchical structure: Board -> Subjects -> Chapters -> Topics
        """
        board = self.get_board_by_code(board_code)
        subjects = self.get_subjects_by_board(board.id, grade_level)
        
        if subject_code:
            subjects = [s for s in subjects if s.code == subject_code]
        
        curriculum_tree = {
            "board": {
                "code": board.code,
                "name": board.name,
                "description": board.description
            },
            "grade_level": grade_level,
            "subjects": []
        }
        
        for subject in subjects:
            chapters = self.get_chapters_by_subject(subject.id)
            
            subject_data = {
                "id": subject.id,
                "code": subject.code,
                "name": subject.name,
                "description": subject.description,
                "icon_url": subject.icon_url,
                "color_code": subject.color_code,
                "is_mandatory": subject.is_mandatory,
                "chapters": []
            }
            
            for chapter in chapters:
                topics = self.get_topics_by_chapter(chapter.id)
                
                chapter_data = {
                    "id": chapter.id,
                    "code": chapter.code,
                    "name": chapter.name,
                    "description": chapter.description,
                    "chapter_number": chapter.chapter_number,
                    "objectives": chapter.objectives,
                    "difficulty_level": chapter.difficulty_level,
                    "estimated_duration_hours": chapter.estimated_duration_hours,
                    "topics": []
                }
                
                for topic in topics:
                    topic_data = {
                        "id": topic.id,
                        "code": topic.code,
                        "name": topic.name,
                        "description": topic.description,
                        "topic_number": topic.topic_number,
                        "key_concepts": topic.key_concepts,
                        "difficulty_level": topic.difficulty_level,
                        "estimated_duration_minutes": topic.estimated_duration_minutes,
                        "importance": topic.importance
                    }
                    chapter_data["topics"].append(topic_data)
                
                subject_data["chapters"].append(chapter_data)
            
            curriculum_tree["subjects"].append(subject_data)
        
        return curriculum_tree
    
    # ========================================================================
    # PREREQUISITE RESOLUTION
    # ========================================================================
    
    def get_topic_prerequisites(self, topic_id: int) -> List[Topic]:
        """Get all prerequisite topics for a given topic"""
        topic = self.get_topic_by_id(topic_id)
        
        if not topic.prerequisites:
            return []
        
        prerequisite_ids = topic.prerequisites
        prerequisites = self.db.query(Topic).filter(
            Topic.id.in_(prerequisite_ids),
            Topic.is_active == True
        ).all()
        
        return prerequisites
    
    def get_prerequisite_chain(self, topic_id: int) -> List[int]:
        """
        Get complete prerequisite chain (recursive)
        Returns list of topic IDs in order: [most basic -> topic_id]
        """
        visited: Set[int] = set()
        chain: List[int] = []
        
        def traverse(tid: int):
            if tid in visited:
                return
            
            visited.add(tid)
            prerequisites = self.get_topic_prerequisites(tid)
            
            for prereq in prerequisites:
                traverse(prereq.id)
            
            chain.append(tid)
        
        traverse(topic_id)
        return chain
    
    def check_prerequisites_completed(
        self,
        topic_id: int,
        student_id: int
    ) -> Dict[str, Any]:
        """
        Check if student has completed all prerequisites for a topic
        """
        prerequisites = self.get_topic_prerequisites(topic_id)
        
        if not prerequisites:
            return {
                "all_completed": True,
                "missing_prerequisites": []
            }
        
        prerequisite_ids = [p.id for p in prerequisites]
        
        # Query student's progress on prerequisites
        completed = self.db.query(LearningProgress).filter(
            LearningProgress.student_id == student_id,
            LearningProgress.topic_id.in_(prerequisite_ids),
            LearningProgress.is_completed == True
        ).all()
        
        completed_ids = {p.topic_id for p in completed}
        missing_ids = set(prerequisite_ids) - completed_ids
        
        missing_prerequisites = [
            {
                "id": p.id,
                "name": p.name,
                "chapter_id": p.chapter_id
            }
            for p in prerequisites if p.id in missing_ids
        ]
        
        return {
            "all_completed": len(missing_ids) == 0,
            "missing_prerequisites": missing_prerequisites,
            "total_prerequisites": len(prerequisites),
            "completed_count": len(completed_ids)
        }
    
    # ========================================================================
    # LEARNING PATH GENERATION
    # ========================================================================
    
    def generate_learning_path(
        self,
        student_id: int,
        subject_id: int,
        target_topics: Optional[List[int]] = None
    ) -> Dict[str, Any]:
        """
        Generate personalized learning path for a student
        
        Args:
            student_id: ID of the student
            subject_id: Subject to create path for
            target_topics: Optional specific topics to focus on
        
        Returns:
            Ordered learning path with recommendations
        """
        
        # Get all chapters and topics for subject
        chapters = self.get_chapters_by_subject(subject_id)
        all_topics = []
        for chapter in chapters:
            all_topics.extend(self.get_topics_by_chapter(chapter.id))
        
        # Get student's progress
        progress_records = self.db.query(LearningProgress).filter(
            LearningProgress.student_id == student_id,
            LearningProgress.topic_id.in_([t.id for t in all_topics])
        ).all()
        
        progress_map = {p.topic_id: p for p in progress_records}
        
        # Build learning path
        learning_path = []
        
        for topic in all_topics:
            # Skip if already completed (unless in target topics)
            if target_topics and topic.id not in target_topics:
                if topic.id in progress_map and progress_map[topic.id].is_completed:
                    continue
            
            # Check prerequisites
            prereq_status = self.check_prerequisites_completed(topic.id, student_id)
            
            # Get current progress
            current_progress = progress_map.get(topic.id)
            
            topic_item = {
                "topic_id": topic.id,
                "topic_name": topic.name,
                "chapter_id": topic.chapter_id,
                "difficulty": topic.difficulty_level,
                "importance": topic.importance,
                "estimated_duration_minutes": topic.estimated_duration_minutes,
                "prerequisites_met": prereq_status["all_completed"],
                "missing_prerequisites": prereq_status.get("missing_prerequisites", []),
                "current_progress": {
                    "completion_percentage": current_progress.completion_percentage if current_progress else 0,
                    "mastery_level": current_progress.mastery_level if current_progress else "beginner",
                    "is_completed": current_progress.is_completed if current_progress else False
                },
                "recommended": False,
                "priority": 0
            }
            
            # Calculate priority
            priority = 0
            
            # Higher priority if prerequisites are met
            if prereq_status["all_completed"]:
                priority += 10
            
            # Higher priority for important topics
            importance_weights = {"low": 1, "medium": 2, "high": 3, "critical": 4}
            priority += importance_weights.get(topic.importance, 1)
            
            # Higher priority if already started
            if current_progress and current_progress.completion_percentage > 0:
                priority += 5
            
            # Lower priority if already completed
            if current_progress and current_progress.is_completed:
                priority -= 20
            
            topic_item["priority"] = priority
            topic_item["recommended"] = prereq_status["all_completed"] and not (
                current_progress and current_progress.is_completed
            )
            
            learning_path.append(topic_item)
        
        # Sort by priority (descending)
        learning_path.sort(key=lambda x: x["priority"], reverse=True)
        
        # Get top recommendations
        recommendations = [t for t in learning_path if t["recommended"]][:10]
        
        return {
            "student_id": student_id,
            "subject_id": subject_id,
            "total_topics": len(all_topics),
            "completed_topics": len([t for t in learning_path if t["current_progress"]["is_completed"]]),
            "recommended_next": recommendations,
            "full_path": learning_path
        }
    
    # ========================================================================
    # ADAPTIVE DIFFICULTY ADJUSTMENT
    # ========================================================================
    
    def get_next_difficulty_level(
        self,
        student_id: int,
        current_topic_id: int
    ) -> str:
        """
        Determine appropriate difficulty level for next topic
        based on student's performance
        """
        # Get student's recent performance
        recent_progress = self.db.query(LearningProgress).filter(
            LearningProgress.student_id == student_id
        ).order_by(LearningProgress.last_accessed.desc()).limit(5).all()
        
        if not recent_progress:
            return "easy"
        
        avg_score = sum(p.average_score for p in recent_progress) / len(recent_progress)
        avg_mastery = [p.mastery_level for p in recent_progress]
        
        # Count mastery levels
        expert_count = avg_mastery.count("expert")
        advanced_count = avg_mastery.count("advanced")
        
        # Determine next difficulty
        if avg_score >= 85 and (expert_count + advanced_count) >= 3:
            return "hard"
        elif avg_score >= 70:
            return "medium"
        elif avg_score >= 50:
            return "easy"
        else:
            return "beginner"
    
    # ========================================================================
    # SKILL GAP ANALYSIS
    # ========================================================================
    
    def analyze_skill_gaps(
        self,
        student_id: int,
        subject_id: int
    ) -> Dict[str, Any]:
        """
        Analyze student's skill gaps and weak areas
        """
        chapters = self.get_chapters_by_subject(subject_id)
        gap_analysis = {
            "weak_chapters": [],
            "weak_topics": [],
            "recommended_revisions": [],
            "overall_mastery": {}
        }
        
        for chapter in chapters:
            topics = self.get_topics_by_chapter(chapter.id)
            topic_ids = [t.id for t in topics]
            
            # Get progress for chapter topics
            progress = self.db.query(LearningProgress).filter(
                LearningProgress.student_id == student_id,
                LearningProgress.topic_id.in_(topic_ids)
            ).all()
            
            if not progress:
                continue
            
            avg_score = sum(p.average_score for p in progress) / len(progress)
            avg_completion = sum(p.completion_percentage for p in progress) / len(progress)
            
            # Identify weak areas
            if avg_score < 60:
                gap_analysis["weak_chapters"].append({
                    "chapter_id": chapter.id,
                    "chapter_name": chapter.name,
                    "average_score": avg_score,
                    "completion_percentage": avg_completion
                })
            
            # Find weak topics
            for p in progress:
                if p.average_score < 60 or p.mastery_level in ["beginner", "intermediate"]:
                    topic = self.get_topic_by_id(p.topic_id)
                    gap_analysis["weak_topics"].append({
                        "topic_id": topic.id,
                        "topic_name": topic.name,
                        "chapter_name": chapter.name,
                        "score": p.average_score,
                        "mastery_level": p.mastery_level
                    })
        
        # Recommend revisions (top 5 weak topics)
        gap_analysis["recommended_revisions"] = sorted(
            gap_analysis["weak_topics"],
            key=lambda x: x["score"]
        )[:5]
        
        return gap_analysis


# ========================================================================
# CURRICULUM CONFIG LOADER
# ========================================================================

async def load_curriculum_configs():
    """
    Load curriculum configurations from JSON files
    This should be called at application startup
    """
    config_dir = Path("shared/curriculum-configs")
    
    if not config_dir.exists():
        logger.warning("Curriculum config directory not found")
        return
    
    configs = {}
    
    for config_file in config_dir.glob("*.json"):
        try:
            with open(config_file, 'r') as f:
                config_data = json.load(f)
                board_code = config_file.stem.upper()
                configs[board_code] = config_data
                logger.info(f"Loaded curriculum config: {board_code}")
        except Exception as e:
            logger.error(f"Failed to load {config_file}: {e}")
    
    # Cache the configs
    await set_cache("curriculum_configs", configs, ttl=None)  # No expiry
    logger.info(f"Cached {len(configs)} curriculum configurations")
    
    return configs


async def get_curriculum_config(board_code: str) -> Optional[Dict]:
    """Get curriculum configuration for a specific board"""
    configs = await get_cache("curriculum_configs")
    if configs:
        return configs.get(board_code.upper())
    return None