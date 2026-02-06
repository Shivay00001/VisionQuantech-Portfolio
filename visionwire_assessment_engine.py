"""
VisionWire EdTech - Assessment Engine
File: backend/app/services/assessment_engine.py

Generates and evaluates quizzes, tests, and assessments
"""

from typing import Dict, Any, List, Optional, Tuple
from sqlalchemy.orm import Session
from datetime import datetime
import json
import logging

from app.models import (
    Question, Assessment, AssessmentAttempt, Topic,
    QuestionType, DifficultyLevel, User
)
from app.utils.llm_client import LLMClient, PromptTemplates
from app.core.exceptions import ValidationError, NotFoundError

logger = logging.getLogger(__name__)


class AssessmentEngine:
    """
    Core assessment engine for generating and evaluating tests
    """
    
    def __init__(self, db: Session):
        self.db = db
        self.llm_client = LLMClient()
    
    # ========================================================================
    # QUESTION GENERATION
    # ========================================================================
    
    async def generate_mcq(
        self,
        topic_id: int,
        difficulty: DifficultyLevel,
        num_questions: int = 5
    ) -> List[Question]:
        """Generate Multiple Choice Questions"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise NotFoundError(f"Topic {topic_id}")
        
        prompt = PromptTemplates.assessment_generation(
            topic=topic.name,
            difficulty=difficulty,
            question_type="multiple choice",
            num_questions=num_questions
        )
        
        try:
            response = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=3000,
                temperature=0.8,
                response_format="json"
            )
            
            questions = []
            question_data = response.get("questions", []) if isinstance(response, dict) else []
            
            for q_data in question_data:
                question = Question(
                    topic_id=topic_id,
                    question_type=QuestionType.MCQ,
                    question_text=q_data.get("question_text"),
                    options=q_data.get("options"),
                    correct_answer=q_data.get("correct_answer"),
                    solution_text=q_data.get("explanation"),
                    difficulty_level=difficulty,
                    marks=1.0,
                    is_ai_generated=True,
                    generation_prompt=prompt
                )
                
                self.db.add(question)
                questions.append(question)
            
            self.db.commit()
            logger.info(f"Generated {len(questions)} MCQs for topic {topic_id}")
            return questions
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"MCQ generation failed: {e}")
            raise ValidationError(f"Failed to generate questions: {str(e)}")
    
    async def generate_true_false(
        self,
        topic_id: int,
        num_questions: int = 10
    ) -> List[Question]:
        """Generate True/False questions"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise NotFoundError(f"Topic {topic_id}")
        
        prompt = f"""Generate {num_questions} True/False questions for:

Topic: {topic.name}
Key Concepts: {', '.join(topic.key_concepts) if topic.key_concepts else 'N/A'}

Requirements:
1. Clear, unambiguous statements
2. Mix of true and false statements
3. Cover different concepts
4. Include explanations

Format as JSON:
{{
  "questions": [
    {{
      "statement": "...",
      "correct_answer": "True" or "False",
      "explanation": "..."
    }}
  ]
}}"""
        
        try:
            response = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=2000,
                response_format="json"
            )
            
            questions = []
            for q_data in response.get("questions", []):
                question = Question(
                    topic_id=topic_id,
                    question_type=QuestionType.TRUE_FALSE,
                    question_text=q_data.get("statement"),
                    correct_answer=q_data.get("correct_answer"),
                    solution_text=q_data.get("explanation"),
                    difficulty_level=DifficultyLevel.EASY,
                    marks=0.5,
                    is_ai_generated=True
                )
                self.db.add(question)
                questions.append(question)
            
            self.db.commit()
            return questions
            
        except Exception as e:
            self.db.rollback()
            raise ValidationError(f"Question generation failed: {str(e)}")
    
    async def generate_short_answer(
        self,
        topic_id: int,
        difficulty: DifficultyLevel,
        num_questions: int = 5
    ) -> List[Question]:
        """Generate Short Answer questions"""
        
        topic = self.db.query(Topic).filter(Topic.id == topic_id).first()
        if not topic:
            raise NotFoundError(f"Topic {topic_id}")
        
        prompt = f"""Generate {num_questions} short answer questions (2-3 sentences):

Topic: {topic.name}
Difficulty: {difficulty}

Format as JSON with:
- question
- model_answer
- key_points (array of must-have points)
- marks

Questions:"""
        
        try:
            response = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=2500,
                response_format="json"
            )
            
            questions = []
            for q_data in response.get("questions", []):
                question = Question(
                    topic_id=topic_id,
                    question_type=QuestionType.SHORT_ANSWER,
                    question_text=q_data.get("question"),
                    solution_text=q_data.get("model_answer"),
                    difficulty_level=difficulty,
                    marks=q_data.get("marks", 2.0),
                    is_ai_generated=True
                )
                self.db.add(question)
                questions.append(question)
            
            self.db.commit()
            return questions
            
        except Exception as e:
            self.db.rollback()
            raise ValidationError(f"Question generation failed: {str(e)}")
    
    # ========================================================================
    # ASSESSMENT CREATION
    # ========================================================================
    
    async def create_assessment(
        self,
        title: str,
        description: str,
        topic_ids: List[int],
        assessment_type: str = "quiz",
        difficulty: DifficultyLevel = DifficultyLevel.MEDIUM,
        duration_minutes: int = 30,
        questions_config: Optional[Dict[str, int]] = None,
        created_by: int = None
    ) -> Assessment:
        """
        Create a complete assessment with auto-generated questions
        
        questions_config example:
        {
            "mcq": 10,
            "true_false": 5,
            "short_answer": 3
        }
        """
        
        if not questions_config:
            questions_config = {"mcq": 10, "true_false": 5}
        
        all_question_ids = []
        total_marks = 0.0
        
        # Generate questions for each topic
        for topic_id in topic_ids:
            # MCQs
            if questions_config.get("mcq", 0) > 0:
                mcqs = await self.generate_mcq(
                    topic_id,
                    difficulty,
                    questions_config["mcq"]
                )
                all_question_ids.extend([q.id for q in mcqs])
                total_marks += len(mcqs) * 1.0
            
            # True/False
            if questions_config.get("true_false", 0) > 0:
                tf_questions = await self.generate_true_false(
                    topic_id,
                    questions_config["true_false"]
                )
                all_question_ids.extend([q.id for q in tf_questions])
                total_marks += len(tf_questions) * 0.5
            
            # Short Answer
            if questions_config.get("short_answer", 0) > 0:
                sa_questions = await self.generate_short_answer(
                    topic_id,
                    difficulty,
                    questions_config["short_answer"]
                )
                all_question_ids.extend([q.id for q in sa_questions])
                total_marks += sum(q.marks for q in sa_questions)
        
        # Create assessment
        assessment = Assessment(
            title=title,
            description=description,
            assessment_type=assessment_type,
            duration_minutes=duration_minutes,
            total_marks=total_marks,
            passing_marks=total_marks * 0.4,  # 40% passing
            question_ids=all_question_ids,
            topics_covered=topic_ids,
            difficulty_level=difficulty,
            randomize_questions=True,
            randomize_options=True,
            created_by=created_by
        )
        
        self.db.add(assessment)
        self.db.commit()
        self.db.refresh(assessment)
        
        logger.info(f"Created assessment '{title}' with {len(all_question_ids)} questions")
        return assessment
    
    def get_assessment(self, assessment_id: int) -> Assessment:
        """Get assessment by ID"""
        assessment = self.db.query(Assessment).filter(
            Assessment.id == assessment_id
        ).first()
        
        if not assessment:
            raise NotFoundError(f"Assessment {assessment_id}")
        
        return assessment
    
    def get_assessment_questions(self, assessment_id: int) -> List[Question]:
        """Get all questions for an assessment"""
        assessment = self.get_assessment(assessment_id)
        
        questions = self.db.query(Question).filter(
            Question.id.in_(assessment.question_ids)
        ).all()
        
        return questions
    
    # ========================================================================
    # ASSESSMENT ATTEMPT & EVALUATION
    # ========================================================================
    
    def start_assessment_attempt(
        self,
        assessment_id: int,
        student_id: int
    ) -> AssessmentAttempt:
        """Start a new assessment attempt"""
        
        assessment = self.get_assessment(assessment_id)
        
        # Check if student has attempts remaining
        existing_attempts = self.db.query(AssessmentAttempt).filter(
            AssessmentAttempt.assessment_id == assessment_id,
            AssessmentAttempt.student_id == student_id
        ).count()
        
        if existing_attempts >= assessment.attempts_allowed:
            raise ValidationError("Maximum attempts reached")
        
        # Create new attempt
        attempt = AssessmentAttempt(
            assessment_id=assessment_id,
            student_id=student_id,
            attempt_number=existing_attempts + 1,
            status="in_progress",
            max_score=assessment.total_marks,
            responses={}
        )
        
        self.db.add(attempt)
        self.db.commit()
        self.db.refresh(attempt)
        
        logger.info(f"Student {student_id} started assessment {assessment_id}")
        return attempt
    
    def submit_answer(
        self,
        attempt_id: int,
        question_id: int,
        answer: Any,
        time_spent: int = 0
    ) -> Dict[str, Any]:
        """Submit answer for a question during attempt"""
        
        attempt = self.db.query(AssessmentAttempt).filter(
            AssessmentAttempt.id == attempt_id
        ).first()
        
        if not attempt:
            raise NotFoundError(f"Attempt {attempt_id}")
        
        if attempt.status != "in_progress":
            raise ValidationError("Attempt is not in progress")
        
        # Store response
        responses = attempt.responses or {}
        responses[str(question_id)] = {
            "answer": answer,
            "time_spent": time_spent,
            "answered_at": datetime.utcnow().isoformat()
        }
        
        attempt.responses = responses
        self.db.commit()
        
        return {"success": True, "question_id": question_id}
    
    async def submit_assessment(
        self,
        attempt_id: int
    ) -> AssessmentAttempt:
        """Submit assessment and calculate score"""
        
        attempt = self.db.query(AssessmentAttempt).filter(
            AssessmentAttempt.id == attempt_id
        ).first()
        
        if not attempt:
            raise NotFoundError(f"Attempt {attempt_id}")
        
        attempt.status = "submitted"
        attempt.submitted_at = datetime.utcnow()
        
        # Calculate time taken
        if attempt.started_at:
            time_taken = (attempt.submitted_at - attempt.started_at).seconds
            attempt.time_taken_seconds = time_taken
        
        # Evaluate answers
        evaluation = await self.evaluate_attempt(attempt_id)
        
        attempt.score = evaluation["score"]
        attempt.percentage = evaluation["percentage"]
        attempt.correct_count = evaluation["correct_count"]
        attempt.incorrect_count = evaluation["incorrect_count"]
        attempt.skipped_count = evaluation["skipped_count"]
        attempt.accuracy = evaluation["accuracy"]
        attempt.status = "evaluated"
        attempt.evaluated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(attempt)
        
        logger.info(f"Evaluated attempt {attempt_id}: Score {attempt.score}/{attempt.max_score}")
        return attempt
    
    async def evaluate_attempt(self, attempt_id: int) -> Dict[str, Any]:
        """
        Evaluate an assessment attempt
        Handles MCQ, True/False automatically
        Uses AI for subjective questions
        """
        
        attempt = self.db.query(AssessmentAttempt).filter(
            AssessmentAttempt.id == attempt_id
        ).first()
        
        if not attempt:
            raise NotFoundError(f"Attempt {attempt_id}")
        
        assessment = self.get_assessment(attempt.assessment_id)
        questions = self.get_assessment_questions(assessment.id)
        
        score = 0.0
        correct_count = 0
        incorrect_count = 0
        skipped_count = 0
        
        responses = attempt.responses or {}
        
        for question in questions:
            q_id = str(question.id)
            
            if q_id not in responses:
                skipped_count += 1
                continue
            
            student_answer = responses[q_id].get("answer")
            
            # Evaluate based on question type
            if question.question_type in [QuestionType.MCQ, QuestionType.TRUE_FALSE]:
                is_correct = self._check_objective_answer(question, student_answer)
                
                if is_correct:
                    score += question.marks
                    correct_count += 1
                else:
                    incorrect_count += 1
                    
            elif question.question_type == QuestionType.MULTIPLE_SELECT:
                is_correct = self._check_multiple_select(question, student_answer)
                
                if is_correct:
                    score += question.marks
                    correct_count += 1
                else:
                    incorrect_count += 1
                    
            elif question.question_type in [QuestionType.SHORT_ANSWER, QuestionType.LONG_ANSWER]:
                # AI-based evaluation
                marks = await self._evaluate_subjective(question, student_answer)
                score += marks
                
                if marks >= question.marks * 0.6:  # 60% threshold
                    correct_count += 1
                else:
                    incorrect_count += 1
        
        total_answered = correct_count + incorrect_count
        accuracy = (correct_count / total_answered * 100) if total_answered > 0 else 0
        percentage = (score / attempt.max_score * 100) if attempt.max_score > 0 else 0
        
        return {
            "score": score,
            "max_score": attempt.max_score,
            "percentage": percentage,
            "correct_count": correct_count,
            "incorrect_count": incorrect_count,
            "skipped_count": skipped_count,
            "accuracy": accuracy
        }
    
    def _check_objective_answer(self, question: Question, student_answer: str) -> bool:
        """Check MCQ or True/False answer"""
        if not student_answer:
            return False
        
        # Normalize answers
        correct = str(question.correct_answer).strip().lower()
        student = str(student_answer).strip().lower()
        
        return correct == student
    
    def _check_multiple_select(self, question: Question, student_answer: List[str]) -> bool:
        """Check multiple select answer"""
        if not student_answer:
            return False
        
        correct_answers = set(question.correct_answers or [])
        student_answers = set(student_answer)
        
        return correct_answers == student_answers
    
    async def _evaluate_subjective(
        self,
        question: Question,
        student_answer: str
    ) -> float:
        """
        Evaluate subjective answer using AI
        Returns marks obtained
        """
        
        if not student_answer:
            return 0.0
        
        prompt = f"""Evaluate this student's answer:

Question: {question.question_text}
Model Answer: {question.solution_text}
Maximum Marks: {question.marks}

Student's Answer:
{student_answer}

Provide evaluation as JSON:
{{
  "marks_obtained": <0 to {question.marks}>,
  "feedback": "Brief feedback on answer quality",
  "key_points_covered": ["point1", "point2"],
  "key_points_missed": ["point1", "point2"]
}}

Be fair and generous in marking. Award partial credit for partially correct answers."""
        
        try:
            evaluation = await self.llm_client.generate(
                prompt=prompt,
                max_tokens=500,
                temperature=0.3,
                response_format="json"
            )
            
            if isinstance(evaluation, dict):
                marks = float(evaluation.get("marks_obtained", 0))
                # Ensure marks don't exceed maximum
                return min(marks, question.marks)
            
            return 0.0
            
        except Exception as e:
            logger.error(f"Subjective evaluation failed: {e}")
            # Fallback: Give 50% marks if answer is substantial
            if len(student_answer) > 50:
                return question.marks * 0.5
            return 0.0
    
    # ========================================================================
    # ANALYTICS & INSIGHTS
    # ========================================================================
    
    def get_student_performance(
        self,
        student_id: int,
        assessment_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """Get student's performance analytics"""
        
        query = self.db.query(AssessmentAttempt).filter(
            AssessmentAttempt.student_id == student_id,
            AssessmentAttempt.status == "evaluated"
        )
        
        if assessment_id:
            query = query.filter(AssessmentAttempt.assessment_id == assessment_id)
        
        attempts = query.all()
        
        if not attempts:
            return {"message": "No completed assessments"}
        
        total_attempts = len(attempts)
        avg_score = sum(a.percentage for a in attempts) / total_attempts
        best_score = max(a.percentage for a in attempts)
        avg_accuracy = sum(a.accuracy for a in attempts) / total_attempts
        
        return {
            "total_attempts": total_attempts,
            "average_score": avg_score,
            "best_score": best_score,
            "average_accuracy": avg_accuracy,
            "recent_attempts": [
                {
                    "assessment_id": a.assessment_id,
                    "score": a.score,
                    "percentage": a.percentage,
                    "submitted_at": a.submitted_at.isoformat() if a.submitted_at else None
                }
                for a in sorted(attempts, key=lambda x: x.submitted_at or datetime.min, reverse=True)[:5]
            ]
        }
    
    def get_question_analytics(self, question_id: int) -> Dict[str, Any]:
        """Get analytics for a specific question"""
        
        question = self.db.query(Question).filter(Question.id == question_id).first()
        if not question:
            raise NotFoundError(f"Question {question_id}")
        
        # Find all attempts that included this question
        attempts = self.db.query(AssessmentAttempt).filter(
            AssessmentAttempt.status == "evaluated"
        ).all()
        
        times_attempted = 0
        times_correct = 0
        
        for attempt in attempts:
            responses = attempt.responses or {}
            q_id = str(question_id)
            
            if q_id in responses:
                times_attempted += 1
                # Check if correct (simplified check)
                if attempt.correct_count > 0:  # This is approximate
                    times_correct += 1
        
        success_rate = (times_correct / times_attempted * 100) if times_attempted > 0 else 0
        
        return {
            "question_id": question_id,
            "times_attempted": times_attempted,
            "times_correct": times_correct,
            "success_rate": success_rate,
            "difficulty_level": question.difficulty_level
        }