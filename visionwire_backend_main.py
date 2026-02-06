"""
VisionWire EdTech - FastAPI Backend Main Application
File: backend/app/main.py
"""

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from contextlib import asynccontextmanager
import time
import logging
from typing import Dict, Any

from app.config import settings
from app.database import engine, Base
from app.api.v1 import auth, curriculum, content, assessments, classrooms, analytics
from app.core.exceptions import VisionWireException

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# ============================================================================
# LIFESPAN EVENTS
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Handle startup and shutdown events"""
    # Startup
    logger.info("🚀 Starting VisionWire EdTech Platform...")
    
    # Create database tables
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created/verified")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
    
    # Initialize services
    try:
        # Initialize Redis connection
        from app.core.cache import init_redis
        await init_redis()
        logger.info("✅ Redis cache initialized")
        
        # Initialize search engine
        from app.services.search import init_search
        await init_search()
        logger.info("✅ Search engine initialized")
        
        # Load curriculum configurations
        from app.services.curriculum_engine import load_curriculum_configs
        await load_curriculum_configs()
        logger.info("✅ Curriculum configurations loaded")
        
    except Exception as e:
        logger.warning(f"⚠️  Some services failed to initialize: {e}")
    
    logger.info("✨ VisionWire is ready to serve!")
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down VisionWire...")
    
    # Close connections
    try:
        from app.core.cache import close_redis
        await close_redis()
        logger.info("✅ Redis connection closed")
    except Exception as e:
        logger.error(f"❌ Error closing connections: {e}")
    
    logger.info("👋 VisionWire shutdown complete")


# ============================================================================
# CREATE FASTAPI APP
# ============================================================================

app = FastAPI(
    title=settings.APP_NAME,
    description="AI-Powered EdTech Platform - Production API",
    version=settings.APP_VERSION,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan
)


# ============================================================================
# MIDDLEWARE CONFIGURATION
# ============================================================================

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GZIP Compression
app.add_middleware(GZipMiddleware, minimum_size=1000)


# Request Timing Middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    """Add processing time to response headers"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response


# Request Logging Middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests"""
    logger.info(f"📥 {request.method} {request.url.path}")
    
    # Log user agent and IP for analytics
    user_agent = request.headers.get("user-agent", "unknown")
    client_ip = request.client.host if request.client else "unknown"
    
    try:
        response = await call_next(request)
        logger.info(f"📤 {request.method} {request.url.path} - Status: {response.status_code}")
        return response
    except Exception as e:
        logger.error(f"❌ {request.method} {request.url.path} - Error: {str(e)}")
        raise


# ============================================================================
# EXCEPTION HANDLERS
# ============================================================================

@app.exception_handler(VisionWireException)
async def visionwire_exception_handler(request: Request, exc: VisionWireException):
    """Handle custom VisionWire exceptions"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.error_code,
            "message": exc.message,
            "details": exc.details
        }
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle request validation errors"""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "VALIDATION_ERROR",
            "message": "Invalid request data",
            "details": exc.errors()
        }
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all unhandled exceptions"""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "INTERNAL_SERVER_ERROR",
            "message": "An unexpected error occurred",
            "details": str(exc) if settings.DEBUG else None
        }
    )


# ============================================================================
# ROOT ENDPOINTS
# ============================================================================

@app.get("/", tags=["Root"])
async def root() -> Dict[str, Any]:
    """Root endpoint - API health check"""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "operational",
        "message": "VisionWire AI EdTech Platform API",
        "docs": f"{settings.BACKEND_URL}/docs" if settings.DEBUG else None
    }


@app.get("/health", tags=["Root"])
async def health_check() -> Dict[str, Any]:
    """Detailed health check endpoint"""
    
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "services": {}
    }
    
    # Check Database
    try:
        from app.database import SessionLocal
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        health_status["services"]["database"] = "healthy"
    except Exception as e:
        health_status["services"]["database"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # Check Redis
    try:
        from app.core.cache import redis_client
        if redis_client:
            await redis_client.ping()
            health_status["services"]["redis"] = "healthy"
        else:
            health_status["services"]["redis"] = "not initialized"
    except Exception as e:
        health_status["services"]["redis"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # Check AI Service
    try:
        from app.utils.llm_client import test_connection
        if await test_connection():
            health_status["services"]["ai_service"] = "healthy"
        else:
            health_status["services"]["ai_service"] = "unavailable"
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["services"]["ai_service"] = f"error: {str(e)}"
    
    return health_status


@app.get("/metrics", tags=["Root"])
async def metrics() -> Dict[str, Any]:
    """Prometheus-compatible metrics endpoint"""
    # TODO: Implement actual Prometheus metrics
    return {
        "requests_total": 0,
        "requests_success": 0,
        "requests_error": 0,
        "response_time_avg": 0.0
    }


# ============================================================================
# API ROUTES
# ============================================================================

# API v1 Routes
app.include_router(
    auth.router,
    prefix=f"{settings.API_V1_PREFIX}/auth",
    tags=["Authentication"]
)

app.include_router(
    curriculum.router,
    prefix=f"{settings.API_V1_PREFIX}/curriculum",
    tags=["Curriculum"]
)

app.include_router(
    content.router,
    prefix=f"{settings.API_V1_PREFIX}/content",
    tags=["Content"]
)

app.include_router(
    assessments.router,
    prefix=f"{settings.API_V1_PREFIX}/assessments",
    tags=["Assessments"]
)

app.include_router(
    classrooms.router,
    prefix=f"{settings.API_V1_PREFIX}/classrooms",
    tags=["Classrooms"]
)

app.include_router(
    analytics.router,
    prefix=f"{settings.API_V1_PREFIX}/analytics",
    tags=["Analytics"]
)


# ============================================================================
# ADMIN ROUTES (Protected)
# ============================================================================

@app.get("/admin/stats", tags=["Admin"])
async def admin_stats():
    """Get platform statistics (admin only)"""
    # TODO: Add authentication check
    from app.database import SessionLocal
    from app.models import User, Content, Assessment
    
    db = SessionLocal()
    try:
        total_users = db.query(User).count()
        total_content = db.query(Content).count()
        total_assessments = db.query(Assessment).count()
        
        return {
            "total_users": total_users,
            "total_content": total_content,
            "total_assessments": total_assessments,
            "platform_version": settings.APP_VERSION
        }
    finally:
        db.close()


# ============================================================================
# WEBSOCKET SUPPORT (For Real-time Features)
# ============================================================================

from fastapi import WebSocket, WebSocketDisconnect
from typing import List

class ConnectionManager:
    """Manage WebSocket connections"""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                pass

manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            # Handle different message types
            if data.get("type") == "ping":
                await websocket.send_json({"type": "pong"})
            elif data.get("type") == "subscribe":
                # Handle subscription to specific channels
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)


# ============================================================================
# STARTUP MESSAGE
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host=settings.BACKEND_HOST,
        port=settings.BACKEND_PORT,
        reload=settings.DEBUG,
        log_level="info"
    )