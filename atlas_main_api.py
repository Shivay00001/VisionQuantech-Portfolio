"""
ShivAI Atlas - Main API Server
FastAPI-based REST API for Atlas frontend
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import uvicorn
import logging

from core.config import config
from core.logger import get_logger, atlas_logger
from core.permissions import permission_manager
from core.memory import memory_agent

from agents.planner_agent import planner_agent
from agents.executor_agent import executor_agent

from automation.pc_actions import pc_actions
from automation.file_actions import file_actions
from automation.android_bridge import android_bridge
from automation.enterchat_connector import enterchat_connector

logger = get_logger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="ShivAI Atlas API",
    description="Local AI Agent OS API",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== Request Models ====================

class CommandRequest(BaseModel):
    command: str
    dry_run: bool = False

class ActionRequest(BaseModel):
    tool: str
    action: str
    params: Dict[str, Any]

class PermissionUpdate(BaseModel):
    permission_type: str
    enabled: bool
    ask_every_time: Optional[bool] = None

class ConfigUpdate(BaseModel):
    section: str
    data: Dict[str, Any]

# ==================== Health & Status ====================

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "agent": "ShivAI Atlas"
    }

@app.get("/api/status")
async def get_status():
    """Get system status"""
    return {
        "success": True,
        "status": {
            "permissions": {
                "files": config.permissions.can_access_files,
                "keyboard_mouse": config.permissions.can_control_keyboard_mouse,
                "screen": config.permissions.can_capture_screen,
                "android": config.permissions.can_control_android,
                "enterchat": config.permissions.can_control_enterchat,
            },
            "services": {
                "android_connected": android_bridge.connected,
                "enterchat_connected": enterchat_connector.connected,
            },
            "config": config.to_dict()
        }
    }

# ==================== Command Execution ====================

@app.post("/api/command")
async def execute_command(request: CommandRequest, background_tasks: BackgroundTasks):
    """Execute a natural language command"""
    try:
        logger.info(f"Received command: {request.command}")
        
        # Parse and plan
        plan = planner_agent.create_plan(request.command)
        plan = planner_agent.optimize_plan(plan)
        
        # Dry run mode
        if request.dry_run:
            result = executor_agent.dry_run(plan)
            return {
                "success": True,
                "mode": "dry_run",
                "plan": {
                    "intent": plan.intent,
                    "confidence": plan.confidence,
                    "steps": len(plan.steps),
                    "requires_confirmation": plan.requires_confirmation
                },
                "result": result
            }
        
        # Check if confirmation required
        if plan.requires_confirmation:
            return {
                "success": False,
                "requires_confirmation": True,
                "plan": {
                    "intent": plan.intent,
                    "confidence": plan.confidence,
                    "steps": [
                        {
                            "tool": s.tool,
                            "action": s.action,
                            "description": s.description
                        } for s in plan.steps
                    ]
                },
                "message": "This action requires user confirmation"
            }
        
        # Execute plan
        execution_result = executor_agent.execute_plan(plan)
        
        # Save conversation
        memory_agent.save_conversation(
            user_input=request.command,
            agent_response=execution_result.message,
            intent=plan.intent,
            confidence=plan.confidence
        )
        
        return {
            "success": execution_result.success,
            "message": execution_result.message,
            "plan": {
                "intent": plan.intent,
                "confidence": plan.confidence,
                "steps": len(plan.steps)
            },
            "execution": {
                "duration_ms": execution_result.total_duration_ms,
                "steps_executed": len(execution_result.step_results),
                "step_results": execution_result.step_results
            }
        }
    
    except Exception as e:
        logger.error(f"Command execution failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/action")
async def execute_action(request: ActionRequest):
    """Execute a direct action"""
    try:
        result = executor_agent.execute_single_action(
            request.tool,
            request.action,
            request.params
        )
        return result
    except Exception as e:
        logger.error(f"Action execution failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ==================== Permissions ====================

@app.get("/api/permissions")
async def get_permissions():
    """Get current permissions"""
    return {
        "success": True,
        "permissions": {
            "files": {
                "enabled": config.permissions.can_access_files,
                "ask_every_time": config.permissions.ask_every_time_files
            },
            "keyboard_mouse": {
                "enabled": config.permissions.can_control_keyboard_mouse,
                "ask_every_time": config.permissions.ask_every_time_keyboard
            },
            "screen_capture": {
                "enabled": config.permissions.can_capture_screen,
                "ask_every_time": config.permissions.ask_every_time_screen
            },
            "android": {
                "enabled": config.permissions.can_control_android,
                "ask_every_time": config.permissions.ask_every_time_android
            },
            "enterchat": {
                "enabled": config.permissions.can_control_enterchat,
                "ask_every_time": config.permissions.ask_every_time_enterchat
            },
            "network": {
                "enabled": config.permissions.can_use_network
            },
            "ai_remote": {
                "enabled": config.permissions.can_use_ai_remote
            }
        }
    }

@app.post("/api/permissions/update")
async def update_permission(update: PermissionUpdate):
    """Update a permission"""
    try:
        perm_type = update.permission_type
        
        if perm_type == "files":
            config.permissions.can_access_files = update.enabled
            if update.ask_every_time is not None:
                config.permissions.ask_every_time_files = update.ask_every_time
        elif perm_type == "keyboard_mouse":
            config.permissions.can_control_keyboard_mouse = update.enabled
            if update.ask_every_time is not None:
                config.permissions.ask_every_time_keyboard = update.ask_every_time
        elif perm_type == "screen_capture":
            config.permissions.can_capture_screen = update.enabled
            if update.ask_every_time is not None:
                config.permissions.ask_every_time_screen = update.ask_every_time
        elif perm_type == "android":
            config.permissions.can_control_android = update.enabled
            if update.ask_every_time is not None:
                config.permissions.ask_every_time_android = update.ask_every_time
        elif perm_type == "enterchat":
            config.permissions.can_control_enterchat = update.enabled
            if update.ask_every_time is not None:
                config.permissions.ask_every_time_enterchat = update.ask_every_time
        elif perm_type == "network":
            config.permissions.can_use_network = update.enabled
        elif perm_type == "ai_remote":
            config.permissions.can_use_ai_remote = update.enabled
        else:
            raise HTTPException(status_code=400, detail="Invalid permission type")
        
        config.save()
        
        atlas_logger.log_security_event(
            "PERMISSION_UPDATE",
            f"Permission {perm_type} set to {update.enabled}",
            "INFO"
        )
        
        return {"success": True, "message": "Permission updated"}
    
    except Exception as e:
        logger.error(f"Failed to update permission: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/permissions/pending")
async def get_pending_requests():
    """Get pending permission requests"""
    requests = permission_manager.get_pending_requests()
    return {"success": True, "requests": requests, "count": len(requests)}

@app.post("/api/permissions/approve/{index}")
async def approve_request(index: int):
    """Approve a pending request"""
    success = permission_manager.approve_request(index)
    if success:
        return {"success": True, "message": "Request approved"}
    raise HTTPException(status_code=400, detail="Invalid request index")

@app.post("/api/permissions/deny/{index}")
async def deny_request(index: int):
    """Deny a pending request"""
    success = permission_manager.deny_request(index)
    if success:
        return {"success": True, "message": "Request denied"}
    raise HTTPException(status_code=400, detail="Invalid request index")

@app.get("/api/audit-log")
async def get_audit_log(limit: int = 100, permission_type: Optional[str] = None):
    """Get audit log"""
    logs = permission_manager.get_audit_log(limit, permission_type)
    return {"success": True, "logs": logs, "count": len(logs)}

# ==================== Memory & History ====================

@app.get("/api/conversations")
async def get_conversations(limit: int = 20):
    """Get conversation history"""
    conversations = memory_agent.get_recent_conversations(limit)
    return {"success": True, "conversations": conversations}

@app.get("/api/workflows")
async def list_workflows(category: Optional[str] = None):
    """List saved workflows"""
    workflows = memory_agent.list_workflows(category)
    return {"success": True, "workflows": workflows, "count": len(workflows)}

@app.get("/api/workflows/suggestions")
async def get_workflow_suggestions():
    """Get workflow suggestions based on usage"""
    suggestions = memory_agent.suggest_workflows(5)
    return {"success": True, "suggestions": suggestions}

# ==================== Android Control ====================

@app.get("/api/android/devices")
async def list_android_devices():
    """List connected Android devices"""
    result = android_bridge.list_devices()
    return result

@app.post("/api/android/connect")
async def connect_android(device_id: Optional[str] = None):
    """Connect to Android device"""
    result = android_bridge.connect_device(device_id)
    return result

@app.get("/api/android/info")
async def get_android_info():
    """Get Android device info"""
    result = android_bridge.get_device_info()
    return result

@app.get("/api/android/battery")
async def get_android_battery():
    """Get Android battery status"""
    result = android_bridge.get_battery_status()
    return result

# ==================== EnterChat Integration ====================

@app.get("/api/enterchat/status")
async def get_enterchat_status():
    """Check EnterChat connection"""
    result = enterchat_connector.check_connection()
    return result

@app.get("/api/enterchat/apps")
async def get_enterchat_apps():
    """Get supported messaging apps"""
    result = enterchat_connector.get_supported_apps()
    return result

@app.get("/api/enterchat/inbox")
async def get_unified_inbox(limit: int = 50):
    """Get unified inbox"""
    result = enterchat_connector.get_unified_inbox(limit)
    return result

@app.get("/api/enterchat/unread")
async def get_unread_count():
    """Get unread message count"""
    result = enterchat_connector.get_unread_count()
    return result

# ==================== Configuration ====================

@app.get("/api/config")
async def get_config():
    """Get full configuration"""
    return {"success": True, "config": config.to_dict()}

@app.post("/api/config/update")
async def update_config(update: ConfigUpdate):
    """Update configuration"""
    try:
        if update.section == "voice":
            for key, value in update.data.items():
                if hasattr(config.voice, key):
                    setattr(config.voice, key, value)
        elif update.section == "android":
            for key, value in update.data.items():
                if hasattr(config.android, key):
                    setattr(config.android, key, value)
        elif update.section == "enterchat":
            for key, value in update.data.items():
                if hasattr(config.enterchat, key):
                    setattr(config.enterchat, key, value)
        
        config.save()
        return {"success": True, "message": "Configuration updated"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==================== Startup & Shutdown ====================

@app.on_event("startup")
async def startup_event():
    """Initialize on startup"""
    logger.info("ShivAI Atlas API starting...")
    logger.info(f"Server running on {config.server_host}:{config.server_port}")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("ShivAI Atlas API shutting down...")
    memory_agent.db.close()

# ==================== Main ====================

def main():
    """Run the API server"""
    uvicorn.run(
        "main:app",
        host=config.server_host,
        port=config.server_port,
        reload=config.debug_mode,
        log_level="info"
    )

if __name__ == "__main__":
    main()
