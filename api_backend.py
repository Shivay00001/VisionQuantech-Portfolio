"""
YOU.DAO Backend API
FastAPI service for dashboard and governance interface
"""

import os
import json
import sqlite3
from typing import List, Optional, Dict
from datetime import datetime

from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from web3 import Web3
import redis


app = FastAPI(title="YOU.DAO API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ProposalResponse(BaseModel):
    id: int
    title: str
    description: str
    proposer: str
    amount: float
    recipient: str
    category: str
    created_at: int
    voting_ends_at: int
    for_votes: float
    against_votes: float
    executed: bool
    status: str
    ai_approved: bool
    ai_confidence: float


class LicenseResponse(BaseModel):
    id: int
    ip_name: str
    ip_type: str
    licensee: str
    royalty_bps: int
    issued_at: int
    expires_at: int
    active: bool
    total_royalties_paid: float


class DecisionResponse(BaseModel):
    id: int
    proposal_id: int
    approved: bool
    confidence: float
    reasoning: str
    alignment_score: float
    category_score: float
    decision_timestamp: str
    tx_hash: Optional[str]


class MetricsResponse(BaseModel):
    total_proposals: int
    active_proposals: int
    total_licenses: int
    active_licenses: int
    total_decisions: int
    approval_rate: float
    avg_confidence: float
    founder_active: bool
    oracle_balance: float


class CategoryStatsResponse(BaseModel):
    category: str
    total: int
    approved: int
    rejected: int
    approval_rate: float


def get_db():
    """Database dependency"""
    conn = sqlite3.connect(os.getenv('DB_PATH', 'oracle.db'))
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def get_web3():
    """Web3 dependency"""
    rpc_url = os.getenv('ETH_RPC_URL', 'http://localhost:8545')
    w3 = Web3(Web3.HTTPProvider(rpc_url))
    return w3


def get_redis():
    """Redis dependency"""
    r = redis.Redis(
        host=os.getenv('REDIS_HOST', 'localhost'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        db=int(os.getenv('REDIS_DB', 0)),
        decode_responses=True
    )
    return r


def get_dao_contract(w3: Web3):
    """Get DAO contract instance"""
    dao_address = os.getenv('YOU_DAO_ADDRESS')
    
    with open('abis/YOUDAO.json', 'r') as f:
        dao_abi = json.load(f)
    
    return w3.eth.contract(
        address=Web3.to_checksum_address(dao_address),
        abi=dao_abi
    )


@app.get("/")
async def root():
    """Health check"""
    return {"status": "ok", "service": "YOU.DAO API"}


@app.get("/api/proposals", response_model=List[ProposalResponse])
async def get_proposals(
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    category: Optional[str] = None,
    status: Optional[str] = None,
    db: sqlite3.Connection = Depends(get_db)
):
    """Get proposals list"""
    
    query = "SELECT * FROM proposals_cache WHERE 1=1"
    params = []
    
    if category:
        query += " AND category = ?"
        params.append(category)
    
    query += " ORDER BY proposal_id DESC LIMIT ? OFFSET ?"
    params.extend([limit, offset])
    
    cursor = db.cursor()
    cursor.execute(query, params)
    
    proposals = []
    for row in cursor.fetchall():
        proposals.append(ProposalResponse(
            id=row['proposal_id'],
            title=row['title'],
            description=row['description'],
            proposer="",
            amount=row['amount'],
            recipient="",
            category=row['category'],
            created_at=row['created_at'],
            voting_ends_at=row['voting_ends_at'],
            for_votes=0.0,
            against_votes=0.0,
            executed=row['processed'],
            status="Active" if not row['processed'] else "Executed",
            ai_approved=False,
            ai_confidence=0.0
        ))
    
    return proposals


@app.get("/api/proposals/{proposal_id}", response_model=ProposalResponse)
async def get_proposal(
    proposal_id: int,
    db: sqlite3.Connection = Depends(get_db)
):
    """Get single proposal"""
    
    cursor = db.cursor()
    cursor.execute(
        "SELECT * FROM proposals_cache WHERE proposal_id = ?",
        (proposal_id,)
    )
    
    row = cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Proposal not found")
    
    cursor.execute(
        "SELECT * FROM decisions WHERE proposal_id = ?",
        (proposal_id,)
    )
    decision = cursor.fetchone()
    
    return ProposalResponse(
        id=row['proposal_id'],
        title=row['title'],
        description=row['description'],
        proposer="",
        amount=row['amount'],
        recipient="",
        category=row['category'],
        created_at=row['created_at'],
        voting_ends_at=row['voting_ends_at'],
        for_votes=0.0,
        against_votes=0.0,
        executed=row['processed'],
        status="Active" if not row['processed'] else "Executed",
        ai_approved=decision['approved'] if decision else False,
        ai_confidence=decision['confidence'] if decision else 0.0
    )


@app.get("/api/licenses", response_model=List[LicenseResponse])
async def get_licenses(
    limit: int = Query(100, ge=1, le=1000),
    active_only: bool = True
):
    """Get IP licenses"""
    
    w3 = get_web3()
    dao_contract = get_dao_contract(w3)
    
    try:
        license_count = dao_contract.functions.licenseCount().call()
        
        licenses = []
        for i in range(1, min(license_count + 1, limit + 1)):
            license_data = dao_contract.functions.getLicense(i).call()
            
            if active_only and not license_data[7]:
                continue
            
            licenses.append(LicenseResponse(
                id=license_data[0],
                ip_name=license_data[1],
                ip_type=license_data[2],
                licensee=license_data[3],
                royalty_bps=license_data[4],
                issued_at=license_data[5],
                expires_at=license_data[6],
                active=license_data[7],
                total_royalties_paid=float(w3.from_wei(license_data[8], 'ether'))
            ))
        
        return licenses
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/decisions", response_model=List[DecisionResponse])
async def get_decisions(
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: sqlite3.Connection = Depends(get_db)
):
    """Get AI decisions"""
    
    cursor = db.cursor()
    cursor.execute(
        """
        SELECT * FROM decisions 
        ORDER BY decision_timestamp DESC 
        LIMIT ? OFFSET ?
        """,
        (limit, offset)
    )
    
    decisions = []
    for row in cursor.fetchall():
        decisions.append(DecisionResponse(
            id=row['id'],
            proposal_id=row['proposal_id'],
            approved=bool(row['approved']),
            confidence=row['confidence'],
            reasoning=row['reasoning'],
            alignment_score=row['alignment_score'] or 0.0,
            category_score=row['category_score'] or 0.0,
            decision_timestamp=row['decision_timestamp'],
            tx_hash=row['tx_hash']
        ))
    
    return decisions


@app.get("/api/decisions/stats")
async def get_decision_stats(
    db: sqlite3.Connection = Depends(get_db)
):
    """Get decision statistics"""
    
    cursor = db.cursor()
    
    cursor.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN approved = 1 THEN 1 ELSE 0 END) as approved,
            AVG(confidence) as avg_confidence
        FROM decisions
    """)
    
    row = cursor.fetchone()
    
    total = row['total']
    approved = row['approved']
    
    return {
        "total_decisions": total,
        "approved": approved,
        "rejected": total - approved,
        "approval_rate": approved / total if total > 0 else 0,
        "avg_confidence": row['avg_confidence'] or 0
    }


@app.get("/api/decisions/by-category")
async def get_decisions_by_category(
    db: sqlite3.Connection = Depends(get_db)
) -> List[CategoryStatsResponse]:
    """Get decision stats by category"""
    
    cursor = db.cursor()
    cursor.execute("""
        SELECT 
            p.category,
            COUNT(*) as total,
            SUM(CASE WHEN d.approved = 1 THEN 1 ELSE 0 END) as approved
        FROM decisions d
        JOIN proposals_cache p ON d.proposal_id = p.proposal_id
        GROUP BY p.category
        ORDER BY total DESC
    """)
    
    stats = []
    for row in cursor.fetchall():
        total = row['total']
        approved = row['approved']
        rejected = total - approved
        
        stats.append(CategoryStatsResponse(
            category=row['category'],
            total=total,
            approved=approved,
            rejected=rejected,
            approval_rate=approved / total if total > 0 else 0
        ))
    
    return stats


@app.get("/api/metrics", response_model=MetricsResponse)
async def get_metrics(db: sqlite3.Connection = Depends(get_db)):
    """Get overall metrics"""
    
    cursor = db.cursor()
    
    cursor.execute("SELECT COUNT(*) as count FROM proposals_cache")
    total_proposals = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM proposals_cache WHERE processed = 0")
    active_proposals = cursor.fetchone()['count']
    
    cursor.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN approved = 1 THEN 1 ELSE 0 END) as approved,
            AVG(confidence) as avg_confidence
        FROM decisions
    """)
    decision_stats = cursor.fetchone()
    
    total_decisions = decision_stats['total']
    approved = decision_stats['approved']
    
    w3 = get_web3()
    
    try:
        dao_contract = get_dao_contract(w3)
        license_count = dao_contract.functions.licenseCount().call()
        
        oracle_address = os.getenv('ORACLE_ADDRESS', '0x0000000000000000000000000000000000000000')
        oracle_balance = float(w3.from_wei(w3.eth.get_balance(oracle_address), 'ether'))
    except:
        license_count = 0
        oracle_balance = 0.0
    
    r = get_redis()
    founder_active = r.get("founder_active") == "True"
    
    return MetricsResponse(
        total_proposals=total_proposals,
        active_proposals=active_proposals,
        total_licenses=license_count,
        active_licenses=license_count,
        total_decisions=total_decisions,
        approval_rate=approved / total_decisions if total_decisions > 0 else 0,
        avg_confidence=decision_stats['avg_confidence'] or 0,
        founder_active=founder_active,
        oracle_balance=oracle_balance
    )


@app.get("/api/health")
async def health_check():
    """Health check with dependencies"""
    
    health = {
        "api": "ok",
        "timestamp": datetime.now().isoformat()
    }
    
    try:
        w3 = get_web3()
        health["ethereum"] = w3.is_connected()
    except:
        health["ethereum"] = False
    
    try:
        r = get_redis()
        r.ping()
        health["redis"] = True
    except:
        health["redis"] = False
    
    try:
        db = next(get_db())
        cursor = db.cursor()
        cursor.execute("SELECT 1")
        health["database"] = True
        db.close()
    except:
        health["database"] = False
    
    return health


@app.get("/api/revenue/projections")
async def get_revenue_projections():
    """Get revenue projections based on YOU.DAO model"""
    
    projections = {
        "conservative": {
            "year_1": 250000,
            "year_2": 500000,
            "year_3": 1000000,
            "year_4": 1500000,
            "year_5": 2000000
        },
        "moderate": {
            "year_1": 500000,
            "year_2": 1000000,
            "year_3": 2500000,
            "year_4": 4000000,
            "year_5": 6000000
        },
        "aggressive": {
            "year_1": 1000000,
            "year_2": 2500000,
            "year_3": 5000000,
            "year_4": 10000000,
            "year_5": 15000000
        }
    }
    
    streams = {
        "IP Licensing": 0.40,
        "Services": 0.25,
        "Partnerships": 0.20,
        "Treasury Yield": 0.10,
        "Transaction Fees": 0.05
    }
    
    return {
        "projections": projections,
        "revenue_streams": streams,
        "assumptions": {
            "license_growth_rate": 0.3,
            "service_adoption_rate": 0.25,
            "partnership_multiplier": 1.5
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
