"""
VisionWire EdTech - Authentication Service & API Routes
Files: 
- backend/app/core/security.py
- backend/app/api/v1/auth.py
- backend/app/api/v1/curriculum.py
- backend/app/api/v1/content.py
"""

# ============================================================================
# FILE 1: backend/app/core/security.py
# ============================================================================

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from passlib.context import CryptContext
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import User, UserRole
from app.core.exceptions import AuthenticationError

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash password"""
    return pwd_context.hash(password)


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: Dict[str, Any]) -> str:
    """Create JWT refresh token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> Dict[str, Any]:
    """Decode and validate JWT token"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        raise AuthenticationError("Invalid or expired token")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Get current authenticated user from token"""
    token = credentials.credentials
    
    try:
        payload = decode_token(token)
        user_id: int = payload.get("sub")
        
        if user_id is None:
            raise AuthenticationError("Invalid token payload")
        
    except JWTError:
        raise AuthenticationError("Could not validate credentials")
    
    user = db.query(User).filter(User.id == user_id).first()
    
    if user is None:
        raise AuthenticationError("User not found")
    
    if not user.is_active:
        raise AuthenticationError("User account is inactive")
    
    return user


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Ensure user is active"""
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user


def require_role(allowed_roles: list):
    """Dependency to check user role"""
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {allowed_roles}"
            )
        return current_user
    return role_checker


# ============================================================================
# FILE 2: backend/app/api/v1/auth.py
# ============================================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

from app.database import get_db
from app.models import User, UserRole, StudentProfile, TeacherProfile
from app.core.security import (
    verify_password, get_password_hash, create_access_token,
    create_refresh_token, get_current_user
)

router = APIRouter()


# ============================================================================
# PYDANTIC SCHEMAS
# ============================================================================

class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    role: UserRole
    phone: Optional[str] = None
    
    # Student-specific
    grade_level: Optional[int] = None
    preferred_board: Optional[str] = None
    
    # Teacher-specific
    qualification: Optional[str] = None
    specialization: Optional[list] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: dict


class UserResponse(BaseModel):
    id: int
    email: str
    username: Optional[str]
    full_name: Optional[str]
    role: str
    is_active: bool
    is_premium: bool
    
    class Config:
        from_attributes = True


# ============================================================================
# AUTH ENDPOINTS
# ============================================================================

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """Register new user"""
    
    # Check if user exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user
    user = User(
        email=user_data.email,
        username=user_data.email.split('@')[0],  # Generate username from email
        hashed_password=get_password_hash(user_data.password),
        full_name=user_data.full_name,
        phone=user_data.phone,
        role=user_data.role,
        preferred_board=user_data.preferred_board,
        grade_level=user_data.grade_level
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create role-specific profile
    if user_data.role == UserRole.STUDENT:
        profile = StudentProfile(
            user_id=user.id,
            current_grade=user_data.grade_level,
            board=user_data.preferred_board
        )
        db.add(profile)
        
    elif user_data.role == UserRole.TEACHER:
        profile = TeacherProfile(
            user_id=user.id,
            qualification=user_data.qualification,
            specialization=user_data.specialization or []
        )
        db.add(profile)
    
    db.commit()
    
    # Generate tokens
    access_token = create_access_token(data={"sub": user.id, "role": user.role})
    refresh_token = create_refresh_token(data={"sub": user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role
        }
    }


@router.post("/login", response_model=Token)
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    """Login user"""
    
    user = db.query(User).filter(User.email == credentials.email).first()
    
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive"
        )
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Generate tokens
    access_token = create_access_token(data={"sub": user.id, "role": user.role})
    refresh_token = create_refresh_token(data={"sub": user.id})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "is_premium": user.is_premium
        }
    }


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user info"""
    return current_user


@router.post("/refresh")
async def refresh_token(refresh_token: str, db: Session = Depends(get_db)):
    """Refresh access token"""
    try:
        from app.core.security import decode_token
        payload = decode_token(refresh_token)
        
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=400, detail="Invalid token type")
        
        user_id = payload.get("sub")
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Generate new access token
        access_token = create_access_token(data={"sub": user.id, "role": user.role})
        
        return {
            "access_token": access_token,
            "token_type": "bearer"
        }
        
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid refresh token")


# ============================================================================
# FILE 3: backend/app/api/v1/curriculum.py
# ============================================================================

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.services.curriculum_engine import CurriculumEngine
from app.core.security import get_current_user
from app.models import User

router = APIRouter()


@router.get("/boards")
async def get_boards(
    active_only: bool = True,
    db: Session = Depends(get_db)
):
    """Get all available boards"""
    engine = CurriculumEngine(db)
    boards = engine.get_boards(active_only)
    
    return {
        "boards": [
            {
                "id": b.id,
                "code": b.code,
                "name": b.name,
                "description": b.description
            }
            for b in boards
        ]
    }


@router.get("/subjects")
async def get_subjects(
    board_code: str = Query(..., description="Board code (CBSE, ICSE, etc)"),
    grade_level: Optional[int] = Query(None, description="Grade/Class level"),
    db: Session = Depends(get_db)
):
    """Get subjects for a board and grade"""
    engine = CurriculumEngine(db)
    board = engine.get_board_by_code(board_code)
    subjects = engine.get_subjects_by_board(board.id, grade_level)
    
    return {
        "board": board_code,
        "grade_level": grade_level,
        "subjects": [
            {
                "id": s.id,
                "code": s.code,
                "name": s.name,
                "description": s.description,
                "icon_url": s.icon_url,
                "color_code": s.color_code
            }
            for s in subjects
        ]
    }


@router.get("/tree")
async def get_curriculum_tree(
    board_code: str,
    grade_level: int,
    subject_code: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get complete curriculum tree"""
    engine = CurriculumEngine(db)
    tree = await engine.get_curriculum_tree(board_code, grade_level, subject_code)
    return tree


@router.get("/learning-path")
async def get_learning_path(
    subject_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get personalized learning path for student"""
    engine = CurriculumEngine(db)
    path = engine.generate_learning_path(current_user.id, subject_id)
    return path


# ============================================================================
# FILE 4: backend/app/api/v1/content.py
# ============================================================================

from fastapi import APIRouter, Depends, BackgroundTasks
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.content_generator import ContentGenerator
from app.core.security import get_current_user
from app.models import User

router = APIRouter()


@router.post("/generate/notes")
async def generate_notes(
    topic_id: int,
    style: str = "comprehensive",
    language: str = "en",
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate notes for a topic"""
    generator = ContentGenerator(db)
    
    # Generate asynchronously in background
    if background_tasks:
        background_tasks.add_task(generator.generate_notes, topic_id, style, language)
        return {"message": "Notes generation started", "status": "processing"}
    
    # Synchronous generation
    content = await generator.generate_notes(topic_id, style, language)
    return {
        "content_id": content.id,
        "title": content.title,
        "content": content.content_text
    }


@router.post("/generate/summary")
async def generate_summary(
    topic_id: int,
    max_words: int = 300,
    language: str = "en",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate summary for a topic"""
    generator = ContentGenerator(db)
    content = await generator.generate_summary(topic_id, max_words, language)
    
    return {
        "content_id": content.id,
        "summary": content.content_text
    }


@router.post("/generate/package")
async def generate_content_package(
    topic_id: int,
    language: str = "en",
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate complete content package for a topic"""
    generator = ContentGenerator(db)
    
    package = await generator.generate_complete_content_package(topic_id, language)
    
    return {
        "message": "Content package generated successfully",
        "package": {
            "notes_id": package["notes"].id,
            "summary_id": package["summary"].id,
            "examples_id": package["examples"].id,
            "flashcards_id": package["flashcards"].id,
            "diagram_id": package["diagram"].id
        }
    }


@router.get("/topic/{topic_id}")
async def get_topic_content(
    topic_id: int,
    db: Session = Depends(get_db)
):
    """Get all content for a topic"""
    from app.models import Content
    
    contents = db.query(Content).filter(
        Content.topic_id == topic_id,
        Content.is_active == True
    ).all()
    
    return {
        "topic_id": topic_id,
        "contents": [
            {
                "id": c.id,
                "type": c.content_type,
                "title": c.title,
                "description": c.description,
                "content_url": c.content_url,
                "view_count": c.view_count
            }
            for c in contents
        ]
    }