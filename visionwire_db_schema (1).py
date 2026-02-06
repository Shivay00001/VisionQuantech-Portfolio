# backend/app/models/__init__.py
"""
VisionWire EdTech - Complete Database Models
File: backend/app/models/__init__.py
"""

from sqlalchemy import (
    Column, Integer, String, Text, Boolean, DateTime, ForeignKey,
    JSON, Enum as SQLEnum, Float, Table, Index, UniqueConstraint
)
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func
from datetime import datetime
import enum

Base = declarative_base()

# ============================================================================
# ENUMS
# ============================================================================

class UserRole(str, enum.Enum):
    STUDENT = "student"
    TEACHER = "teacher"
    PARENT = "parent"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"

class BoardType(str, enum.Enum):
    CBSE = "CBSE"
    ICSE = "ICSE"
    STATE_BOARD = "STATE_BOARD"
    JEE = "JEE"
    NEET = "NEET"
    SAT = "SAT"
    UPSC = "UPSC"

class ContentType(str, enum.Enum):
    NOTES = "notes"
    SUMMARY = "summary"
    EXPLANATION = "explanation"
    EXAMPLE = "example"
    DIAGRAM = "diagram"
    VIDEO = "video"
    QUIZ = "quiz"
    ASSIGNMENT = "assignment"
    FLASHCARD = "flashcard"

class QuestionType(str, enum.Enum):
    MCQ = "mcq"
    MULTIPLE_SELECT = "multiple_select"
    TRUE_FALSE = "true_false"
    SHORT_ANSWER = "short_answer"
    LONG_ANSWER = "long_answer"
    FILL_BLANKS = "fill_blanks"
    MATCH_FOLLOWING = "match_following"

class DifficultyLevel(str, enum.Enum):
    BEGINNER = "beginner"
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXPERT = "expert"

class AssignmentStatus(str, enum.Enum):
    DRAFT = "draft"
    ASSIGNED = "assigned"
    IN_PROGRESS = "in_progress"
    SUBMITTED = "submitted"
    GRADED = "graded"
    RETURNED = "returned"

class SubscriptionTier(str, enum.Enum):
    FREE = "free"
    BASIC = "basic"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"

# ============================================================================
# ASSOCIATION TABLES (Many-to-Many)
# ============================================================================

classroom_students = Table(
    'classroom_students',
    Base.metadata,
    Column('classroom_id', Integer, ForeignKey('classrooms.id', ondelete='CASCADE')),
    Column('student_id', Integer, ForeignKey('users.id', ondelete='CASCADE')),
    Column('enrolled_at', DateTime, default=func.now()),
    UniqueConstraint('classroom_id', 'student_id', name='uix_classroom_student')
)

user_achievements = Table(
    'user_achievements',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id', ondelete='CASCADE')),
    Column('achievement_id', Integer, ForeignKey('achievements.id', ondelete='CASCADE')),
    Column('earned_at', DateTime, default=func.now()),
    UniqueConstraint('user_id', 'achievement_id', name='uix_user_achievement')
)

# ============================================================================
# USER MODELS
# ============================================================================

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    phone = Column(String(20))
    avatar_url = Column(String(500))
    
    role = Column(SQLEnum(UserRole), default=UserRole.STUDENT, nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    is_premium = Column(Boolean, default=False)
    subscription_tier = Column(SQLEnum(SubscriptionTier), default=SubscriptionTier.FREE)
    
    # Relationships
    student = relationship("User", back_populates="doubt_queries")
    resolver = relationship("User", foreign_keys=[resolved_by])

# ============================================================================
# GAMIFICATION & ACHIEVEMENTS
# ============================================================================

class Achievement(Base):
    __tablename__ = "achievements"
    
    id = Column(Integer, primary_key=True)
    
    # Achievement Details
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Visual
    icon_url = Column(String(500))
    badge_url = Column(String(500))
    color = Column(String(7))
    
    # Requirements
    requirement_type = Column(String(50))  # xp_points, courses_completed, streak_days, score_achieved
    requirement_value = Column(Integer)
    requirement_conditions = Column(JSON)
    
    # Rewards
    xp_reward = Column(Integer, default=0)
    badge_tier = Column(String(20))  # bronze, silver, gold, platinum
    
    # Metadata
    category = Column(String(50))  # learning, assessment, streak, social
    rarity = Column(String(20), default='common')  # common, rare, epic, legendary
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    
    # Relationships
    users = relationship("User", secondary=user_achievements, back_populates="achievements")

class Announcement(Base):
    __tablename__ = "announcements"
    
    id = Column(Integer, primary_key=True)
    classroom_id = Column(Integer, ForeignKey('classrooms.id', ondelete='CASCADE'))
    
    # Announcement Details
    title = Column(String(500), nullable=False)
    content = Column(Text, nullable=False)
    
    # Priority & Type
    priority = Column(String(20), default='normal')  # low, normal, high, urgent
    announcement_type = Column(String(50))  # general, assignment, assessment, deadline
    
    # Attachments
    attachments = Column(JSON)
    
    # Scheduling
    scheduled_at = Column(DateTime)
    posted_at = Column(DateTime, default=func.now())
    
    # Metadata
    is_pinned = Column(Boolean, default=False)
    created_by = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    classroom = relationship("Classroom", back_populates="announcements")
    creator = relationship("User", foreign_keys=[created_by])

# ============================================================================
# SUBSCRIPTION & PAYMENTS
# ============================================================================

class Subscription(Base):
    __tablename__ = "subscriptions"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    
    # Plan Details
    tier = Column(SQLEnum(SubscriptionTier), nullable=False)
    plan_name = Column(String(100))
    billing_cycle = Column(String(20))  # monthly, quarterly, yearly
    
    # Pricing
    amount = Column(Float)
    currency = Column(String(3), default='INR')
    discount_code = Column(String(50))
    discount_amount = Column(Float, default=0.0)
    
    # Status
    status = Column(String(20), default='active')  # active, cancelled, expired, suspended
    
    # Dates
    start_date = Column(DateTime, default=func.now())
    end_date = Column(DateTime)
    next_billing_date = Column(DateTime)
    cancelled_at = Column(DateTime)
    
    # Payment Integration
    payment_provider = Column(String(50))  # stripe, razorpay
    external_subscription_id = Column(String(255))
    
    # Metadata
    auto_renew = Column(Boolean, default=True)
    cancellation_reason = Column(Text)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    subscription_id = Column(Integer, ForeignKey('subscriptions.id'), nullable=True)
    
    # Payment Details
    amount = Column(Float, nullable=False)
    currency = Column(String(3), default='INR')
    payment_method = Column(String(50))  # card, upi, netbanking, wallet
    
    # Transaction Info
    transaction_id = Column(String(255), unique=True)
    payment_provider = Column(String(50))  # stripe, razorpay
    provider_transaction_id = Column(String(255))
    
    # Status
    status = Column(String(20), default='pending')  # pending, processing, completed, failed, refunded
    
    # Metadata
    description = Column(Text)
    invoice_url = Column(String(500))
    receipt_url = Column(String(500))
    
    # Error Handling
    error_code = Column(String(50))
    error_message = Column(Text)
    
    # Timestamps
    initiated_at = Column(DateTime, default=func.now())
    completed_at = Column(DateTime)
    refunded_at = Column(DateTime)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    subscription = relationship("Subscription", foreign_keys=[subscription_id])

# ============================================================================
# NOTIFICATION SYSTEM
# ============================================================================

class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    
    # Notification Details
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(String(50))  # assignment, announcement, achievement, reminder, system
    
    # Action
    action_url = Column(String(500))
    action_label = Column(String(100))
    
    # Channels
    sent_via_email = Column(Boolean, default=False)
    sent_via_push = Column(Boolean, default=False)
    sent_via_sms = Column(Boolean, default=False)
    
    # Status
    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime)
    
    # Priority
    priority = Column(String(20), default='normal')  # low, normal, high
    
    # Metadata
    metadata = Column(JSON)
    
    created_at = Column(DateTime, default=func.now())
    expires_at = Column(DateTime)
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])

# ============================================================================
# ANALYTICS & LOGS
# ============================================================================

class ActivityLog(Base):
    __tablename__ = "activity_logs"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), nullable=True)
    
    # Activity Details
    activity_type = Column(String(50), nullable=False)  # login, content_view, assessment_start, etc.
    action = Column(String(100))
    description = Column(Text)
    
    # Context
    resource_type = Column(String(50))  # topic, assessment, assignment
    resource_id = Column(Integer)
    
    # Request Info
    ip_address = Column(String(45))
    user_agent = Column(String(500))
    device_type = Column(String(50))  # mobile, tablet, desktop
    
    # Metadata
    metadata = Column(JSON)
    
    created_at = Column(DateTime, default=func.now(), index=True)
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    
    __table_args__ = (
        Index('ix_activity_logs_user_created', 'user_id', 'created_at'),
        Index('ix_activity_logs_type_created', 'activity_type', 'created_at'),
    )

class SystemConfig(Base):
    __tablename__ = "system_configs"
    
    id = Column(Integer, primary_key=True)
    
    # Config Details
    key = Column(String(255), unique=True, nullable=False, index=True)
    value = Column(JSON)
    description = Column(Text)
    
    # Metadata
    config_type = Column(String(50))  # curriculum, feature_flag, integration, general
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    updated_by = Column(Integer, ForeignKey('users.id'))
    
    # Relationships
    updater = relationship("User", foreign_keys=[updated_by])

# ============================================================================
# INDEXES FOR PERFORMANCE
# ============================================================================

# Additional indexes are created using __table_args__ in models above
# This ensures optimal query performance for common operations Preferences
    preferred_language = Column(String(10), default='en')
    preferred_board = Column(SQLEnum(BoardType), nullable=True)
    grade_level = Column(Integer, nullable=True)  # Class/Grade
    
    # Gamification
    xp_points = Column(Integer, default=0)
    level = Column(Integer, default=1)
    streak_days = Column(Integer, default=0)
    last_activity_date = Column(DateTime)
    
    # Metadata
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    last_login = Column(DateTime)
    
    # Relationships
    student_profile = relationship("StudentProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    teacher_profile = relationship("TeacherProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    parent_profile = relationship("ParentProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    
    # Many-to-many
    classrooms_enrolled = relationship("Classroom", secondary=classroom_students, back_populates="students")
    achievements = relationship("Achievement", secondary=user_achievements, back_populates="users")
    
    # One-to-many
    assignments_submitted = relationship("AssignmentSubmission", back_populates="student", foreign_keys="AssignmentSubmission.student_id")
    progress_records = relationship("LearningProgress", back_populates="student", cascade="all, delete-orphan")
    doubt_queries = relationship("DoubtQuery", back_populates="student", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index('ix_users_role_active', 'role', 'is_active'),
    )

class StudentProfile(Base):
    __tablename__ = "student_profiles"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), unique=True)
    
    # Academic Info
    current_grade = Column(Integer)
    board = Column(SQLEnum(BoardType))
    school_name = Column(String(255))
    roll_number = Column(String(50))
    
    # Learning Preferences
    learning_style = Column(String(50))  # visual, auditory, kinesthetic, reading
    study_hours_per_day = Column(Float, default=2.0)
    preferred_subjects = Column(JSON)  # ["Mathematics", "Physics"]
    weak_subjects = Column(JSON)
    
    # Performance Metrics
    total_courses_completed = Column(Integer, default=0)
    total_assessments_taken = Column(Integer, default=0)
    average_score = Column(Float, default=0.0)
    accuracy_rate = Column(Float, default=0.0)
    
    # Parent Link
    parent_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="student_profile", foreign_keys=[user_id])
    parent = relationship("User", foreign_keys=[parent_id])

class TeacherProfile(Base):
    __tablename__ = "teacher_profiles"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), unique=True)
    
    # Professional Info
    qualification = Column(String(255))
    specialization = Column(JSON)  # ["Mathematics", "Physics"]
    experience_years = Column(Integer)
    institution = Column(String(255))
    employee_id = Column(String(100))
    
    # Teaching Preferences
    preferred_boards = Column(JSON)  # ["CBSE", "ICSE"]
    preferred_grades = Column(JSON)  # [9, 10, 11, 12]
    teaching_style = Column(String(100))
    
    # Statistics
    total_students = Column(Integer, default=0)
    total_courses_created = Column(Integer, default=0)
    total_assignments_created = Column(Integer, default=0)
    average_student_rating = Column(Float, default=0.0)
    
    # Verification
    is_verified = Column(Boolean, default=False)
    verification_documents = Column(JSON)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="teacher_profile")
    classrooms_teaching = relationship("Classroom", back_populates="teacher", cascade="all, delete-orphan")

class ParentProfile(Base):
    __tablename__ = "parent_profiles"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'), unique=True)
    
    # Parent Info
    relation = Column(String(50))  # Father, Mother, Guardian
    occupation = Column(String(255))
    
    # Linked Students (stored as JSON array of user_ids)
    children_ids = Column(JSON)  # [123, 124]
    
    # Notification Preferences
    receive_progress_reports = Column(Boolean, default=True)
    receive_assignment_alerts = Column(Boolean, default=True)
    notification_frequency = Column(String(20), default='daily')  # daily, weekly, monthly
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="parent_profile")

# ============================================================================
# CURRICULUM MODELS
# ============================================================================

class Board(Base):
    __tablename__ = "boards"
    
    id = Column(Integer, primary_key=True)
    code = Column(String(50), unique=True, nullable=False)  # CBSE, ICSE, etc.
    name = Column(String(255), nullable=False)
    description = Column(Text)
    country = Column(String(100), default='India')
    
    # Configuration
    config = Column(JSON)  # Board-specific settings
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    subjects = relationship("Subject", back_populates="board", cascade="all, delete-orphan")

class Subject(Base):
    __tablename__ = "subjects"
    
    id = Column(Integer, primary_key=True)
    board_id = Column(Integer, ForeignKey('boards.id', ondelete='CASCADE'))
    
    code = Column(String(50), nullable=False)  # MATH, PHY, CHEM
    name = Column(String(255), nullable=False)
    description = Column(Text)
    icon_url = Column(String(500))
    color_code = Column(String(7))  # Hex color for UI
    
    # Academic Details
    grade_level = Column(Integer)  # Which class/grade
    is_mandatory = Column(Boolean, default=True)
    credits = Column(Integer, default=0)
    
    # Metadata
    order = Column(Integer, default=0)  # Display order
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    board = relationship("Board", back_populates="subjects")
    chapters = relationship("Chapter", back_populates="subject", cascade="all, delete-orphan")
    
    __table_args__ = (
        UniqueConstraint('board_id', 'code', 'grade_level', name='uix_board_subject_grade'),
    )

class Chapter(Base):
    __tablename__ = "chapters"
    
    id = Column(Integer, primary_key=True)
    subject_id = Column(Integer, ForeignKey('subjects.id', ondelete='CASCADE'))
    
    code = Column(String(50))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Learning Objectives
    objectives = Column(JSON)  # ["Understand concepts", "Apply formulas"]
    prerequisites = Column(JSON)  # IDs of prerequisite chapters
    
    # Content Metadata
    estimated_duration_hours = Column(Float, default=4.0)
    difficulty_level = Column(SQLEnum(DifficultyLevel), default=DifficultyLevel.MEDIUM)
    
    # Organization
    chapter_number = Column(Integer)
    order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    subject = relationship("Subject", back_populates="chapters")
    topics = relationship("Topic", back_populates="chapter", cascade="all, delete-orphan")

class Topic(Base):
    __tablename__ = "topics"
    
    id = Column(Integer, primary_key=True)
    chapter_id = Column(Integer, ForeignKey('chapters.id', ondelete='CASCADE'))
    
    code = Column(String(50))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Learning Details
    key_concepts = Column(JSON)  # ["Concept 1", "Concept 2"]
    prerequisites = Column(JSON)  # IDs of prerequisite topics
    learning_outcomes = Column(JSON)
    
    # Content Properties
    estimated_duration_minutes = Column(Integer, default=30)
    difficulty_level = Column(SQLEnum(DifficultyLevel), default=DifficultyLevel.MEDIUM)
    importance = Column(String(20), default='medium')  # low, medium, high, critical
    
    # Organization
    topic_number = Column(Integer)
    order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    chapter = relationship("Chapter", back_populates="topics")
    content_items = relationship("Content", back_populates="topic", cascade="all, delete-orphan")
    questions = relationship("Question", back_populates="topic", cascade="all, delete-orphan")

# ============================================================================
# CONTENT MODELS
# ============================================================================

class Content(Base):
    __tablename__ = "contents"
    
    id = Column(Integer, primary_key=True)
    topic_id = Column(Integer, ForeignKey('topics.id', ondelete='CASCADE'))
    
    # Content Identification
    content_type = Column(SQLEnum(ContentType), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(Text)
    
    # Content Data
    content_text = Column(Text)  # Markdown/HTML content
    content_json = Column(JSON)  # Structured content data
    content_url = Column(String(1000))  # External URL or storage path
    
    # Media
    thumbnail_url = Column(String(500))
    duration_seconds = Column(Integer)  # For videos/audio
    file_size_bytes = Column(Integer)
    
    # Generation Info
    is_ai_generated = Column(Boolean, default=False)
    generation_prompt = Column(Text)
    generation_model = Column(String(100))
    generated_at = Column(DateTime)
    
    # Quality & Review
    quality_score = Column(Float, default=0.0)
    is_reviewed = Column(Boolean, default=False)
    reviewed_by = Column(Integer, ForeignKey('users.id'), nullable=True)
    reviewed_at = Column(DateTime)
    
    # Usage Stats
    view_count = Column(Integer, default=0)
    like_count = Column(Integer, default=0)
    share_count = Column(Integer, default=0)
    
    # Metadata
    language = Column(String(10), default='en')
    tags = Column(JSON)
    difficulty_level = Column(SQLEnum(DifficultyLevel))
    
    is_active = Column(Boolean, default=True)
    is_public = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    topic = relationship("Topic", back_populates="content_items")
    reviewer = relationship("User", foreign_keys=[reviewed_by])

# ============================================================================
# ASSESSMENT MODELS
# ============================================================================

class Question(Base):
    __tablename__ = "questions"
    
    id = Column(Integer, primary_key=True)
    topic_id = Column(Integer, ForeignKey('topics.id', ondelete='CASCADE'))
    
    # Question Details
    question_type = Column(SQLEnum(QuestionType), nullable=False)
    question_text = Column(Text, nullable=False)
    question_html = Column(Text)  # Formatted version
    
    # Options (for MCQ, Multiple Select)
    options = Column(JSON)  # [{"id": "a", "text": "Option A", "is_correct": false}]
    correct_answer = Column(Text)  # For short answer, fill blanks
    correct_answers = Column(JSON)  # Multiple correct answers
    
    # Solution
    solution_text = Column(Text)
    solution_html = Column(Text)
    hints = Column(JSON)  # ["Hint 1", "Hint 2"]
    
    # Classification
    difficulty_level = Column(SQLEnum(DifficultyLevel), default=DifficultyLevel.MEDIUM)
    bloom_taxonomy_level = Column(String(50))  # Remember, Understand, Apply, Analyze, Evaluate, Create
    cognitive_level = Column(String(50))  # Knowledge, Comprehension, Application, Analysis, Synthesis, Evaluation
    
    # Scoring
    marks = Column(Float, default=1.0)
    negative_marks = Column(Float, default=0.0)
    time_limit_seconds = Column(Integer)
    
    # AI Generation
    is_ai_generated = Column(Boolean, default=False)
    generation_prompt = Column(Text)
    
    # Usage Stats
    times_attempted = Column(Integer, default=0)
    times_correct = Column(Integer, default=0)
    average_time_seconds = Column(Float)
    
    # Metadata
    tags = Column(JSON)
    language = Column(String(10), default='en')
    
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    created_by = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    topic = relationship("Topic", back_populates="questions")
    creator = relationship("User", foreign_keys=[created_by])

class Assessment(Base):
    __tablename__ = "assessments"
    
    id = Column(Integer, primary_key=True)
    
    # Assessment Details
    title = Column(String(500), nullable=False)
    description = Column(Text)
    assessment_type = Column(String(50))  # quiz, test, exam, practice, mock
    
    # Configuration
    instructions = Column(Text)
    duration_minutes = Column(Integer)
    total_marks = Column(Float)
    passing_marks = Column(Float)
    
    # Question Selection
    question_ids = Column(JSON)  # [1, 2, 3, 4, 5]
    randomize_questions = Column(Boolean, default=False)
    randomize_options = Column(Boolean, default=False)
    questions_per_page = Column(Integer, default=1)
    
    # Rules
    allow_back_navigation = Column(Boolean, default=True)
    show_results_immediately = Column(Boolean, default=False)
    show_correct_answers = Column(Boolean, default=True)
    attempts_allowed = Column(Integer, default=1)
    
    # Scheduling
    available_from = Column(DateTime)
    available_until = Column(DateTime)
    
    # Metadata
    difficulty_level = Column(SQLEnum(DifficultyLevel))
    topics_covered = Column(JSON)  # Topic IDs
    tags = Column(JSON)
    
    is_active = Column(Boolean, default=True)
    is_public = Column(Boolean, default=False)
    
    created_by = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    creator = relationship("User", foreign_keys=[created_by])
    attempts = relationship("AssessmentAttempt", back_populates="assessment", cascade="all, delete-orphan")

class AssessmentAttempt(Base):
    __tablename__ = "assessment_attempts"
    
    id = Column(Integer, primary_key=True)
    assessment_id = Column(Integer, ForeignKey('assessments.id', ondelete='CASCADE'))
    student_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    
    # Attempt Info
    attempt_number = Column(Integer, default=1)
    status = Column(String(20), default='in_progress')  # in_progress, completed, submitted, evaluated
    
    # Responses
    responses = Column(JSON)  # {question_id: {answer: "...", time_spent: 30, marked_for_review: false}}
    
    # Scoring
    score = Column(Float, default=0.0)
    max_score = Column(Float)
    percentage = Column(Float, default=0.0)
    
    # Time Tracking
    time_taken_seconds = Column(Integer)
    started_at = Column(DateTime, default=func.now())
    submitted_at = Column(DateTime)
    evaluated_at = Column(DateTime)
    
    # Analysis
    correct_count = Column(Integer, default=0)
    incorrect_count = Column(Integer, default=0)
    skipped_count = Column(Integer, default=0)
    accuracy = Column(Float, default=0.0)
    
    # Feedback
    feedback = Column(Text)
    strengths = Column(JSON)
    improvements_needed = Column(JSON)
    
    # Relationships
    assessment = relationship("Assessment", back_populates="attempts")
    student = relationship("User", foreign_keys=[student_id])

# ============================================================================
# CLASSROOM & ASSIGNMENT MODELS
# ============================================================================

class Classroom(Base):
    __tablename__ = "classrooms"
    
    id = Column(Integer, primary_key=True)
    teacher_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    
    # Classroom Info
    name = Column(String(255), nullable=False)
    description = Column(Text)
    class_code = Column(String(20), unique=True, index=True)  # Join code
    
    # Academic Details
    board = Column(SQLEnum(BoardType))
    grade_level = Column(Integer)
    subject_id = Column(Integer, ForeignKey('subjects.id'))
    
    # Settings
    max_students = Column(Integer, default=100)
    is_active = Column(Boolean, default=True)
    is_public = Column(Boolean, default=False)
    allow_self_enrollment = Column(Boolean, default=True)
    
    # Metadata
    banner_url = Column(String(500))
    tags = Column(JSON)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    teacher = relationship("TeacherProfile", back_populates="classrooms_teaching")
    students = relationship("User", secondary=classroom_students, back_populates="classrooms_enrolled")
    assignments = relationship("Assignment", back_populates="classroom", cascade="all, delete-orphan")
    announcements = relationship("Announcement", back_populates="classroom", cascade="all, delete-orphan")

class Assignment(Base):
    __tablename__ = "assignments"
    
    id = Column(Integer, primary_key=True)
    classroom_id = Column(Integer, ForeignKey('classrooms.id', ondelete='CASCADE'))
    
    # Assignment Details
    title = Column(String(500), nullable=False)
    description = Column(Text)
    instructions = Column(Text)
    
    # Type & Content
    assignment_type = Column(String(50))  # homework, project, quiz, test
    assessment_id = Column(Integer, ForeignKey('assessments.id'), nullable=True)
    attached_files = Column(JSON)  # [{name: "file.pdf", url: "..."}]
    
    # Scoring
    total_marks = Column(Float)
    weightage = Column(Float, default=1.0)
    
    # Deadlines
    assigned_at = Column(DateTime, default=func.now())
    due_date = Column(DateTime)
    late_submission_allowed = Column(Boolean, default=False)
    late_penalty_percent = Column(Float, default=10.0)
    
    # Settings
    allow_resubmission = Column(Boolean, default=False)
    max_attempts = Column(Integer, default=1)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    classroom = relationship("Classroom", back_populates="assignments")
    submissions = relationship("AssignmentSubmission", back_populates="assignment", cascade="all, delete-orphan")

class AssignmentSubmission(Base):
    __tablename__ = "assignment_submissions"
    
    id = Column(Integer, primary_key=True)
    assignment_id = Column(Integer, ForeignKey('assignments.id', ondelete='CASCADE'))
    student_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    
    # Submission Info
    attempt_number = Column(Integer, default=1)
    status = Column(SQLEnum(AssignmentStatus), default=AssignmentStatus.DRAFT)
    
    # Content
    submission_text = Column(Text)
    submitted_files = Column(JSON)  # [{name: "answer.pdf", url: "..."}]
    assessment_attempt_id = Column(Integer, ForeignKey('assessment_attempts.id'), nullable=True)
    
    # Grading
    marks_obtained = Column(Float)
    max_marks = Column(Float)
    percentage = Column(Float)
    
    # Feedback
    feedback = Column(Text)
    graded_by = Column(Integer, ForeignKey('users.id'))
    graded_at = Column(DateTime)
    
    # Time Tracking
    submitted_at = Column(DateTime)
    is_late = Column(Boolean, default=False)
    time_taken_minutes = Column(Integer)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    assignment = relationship("Assignment", back_populates="submissions")
    student = relationship("User", back_populates="assignments_submitted", foreign_keys=[student_id])
    grader = relationship("User", foreign_keys=[graded_by])

# ============================================================================
# LEARNING PROGRESS & ANALYTICS
# ============================================================================

class LearningProgress(Base):
    __tablename__ = "learning_progress"
    
    id = Column(Integer, primary_key=True)
    student_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    topic_id = Column(Integer, ForeignKey('topics.id', ondelete='CASCADE'))
    
    # Progress Metrics
    completion_percentage = Column(Float, default=0.0)
    mastery_level = Column(String(20), default='beginner')  # beginner, intermediate, advanced, expert
    
    # Time Tracking
    time_spent_minutes = Column(Integer, default=0)
    first_accessed = Column(DateTime, default=func.now())
    last_accessed = Column(DateTime, default=func.now())
    
    # Performance
    assessments_taken = Column(Integer, default=0)
    average_score = Column(Float, default=0.0)
    best_score = Column(Float, default=0.0)
    
    # Status
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    
    # Metadata
    notes = Column(Text)
    bookmarked = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    student = relationship("User", back_populates="progress_records")
    
    __table_args__ = (
        UniqueConstraint('student_id', 'topic_id', name='uix_student_topic_progress'),
    )

class DoubtQuery(Base):
    __tablename__ = "doubt_queries"
    
    id = Column(Integer, primary_key=True)
    student_id = Column(Integer, ForeignKey('users.id', ondelete='CASCADE'))
    topic_id = Column(Integer, ForeignKey('topics.id'), nullable=True)
    
    # Query Details
    question = Column(Text, nullable=False)
    context = Column(JSON)  # {chapter_id, topic_id, content_id}
    
    # AI Response
    ai_response = Column(Text)
    ai_confidence = Column(Float)  # 0.0 to 1.0
    
    # Resolution
    is_resolved = Column(Boolean, default=False)
    resolution_type = Column(String(20))  # ai, teacher, peer
    resolved_by = Column(Integer, ForeignKey('users.id'), nullable=True)
    resolved_at = Column(DateTime)
    
    # Feedback
    was_helpful = Column(Boolean)
    rating = Column(Integer)  # 1 to 5
    feedback_text = Column(Text)
    
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    #