#!/usr/bin/env python3
"""Demo API application for testing ArgoCD deployments."""

from datetime import datetime, timezone

from fastapi import FastAPI

app = FastAPI(
    title="Demo API",
    description="Simple API for testing Kubernetes and ArgoCD deployments",
    version="0.1.0",
)


@app.get("/health")
async def health_check():
    """Health check endpoint for liveness/readiness probes."""
    return {"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()}


@app.get("/ping")
async def ping():
    """Simple ping endpoint."""
    return {"message": "pong"}


@app.post("/datetime")
async def get_datetime():
    """Return current UTC datetime."""
    return {"utc_datetime": datetime.now(timezone.utc).isoformat()}


@app.get("/info")
async def get_info():
    """Get application information."""
    return {
        "app": "demo-api",
        "version": "0.1.0",
        "environment": "kubernetes",
        "endpoints": [
            {"method": "GET", "path": "/health", "description": "Health check"},
            {"method": "GET", "path": "/ping", "description": "Ping pong"},
            {"method": "POST", "path": "/datetime", "description": "Get UTC datetime"},
            {"method": "GET", "path": "/info", "description": "Application info"},
        ],
    }
