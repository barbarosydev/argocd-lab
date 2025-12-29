"""Tests for demo-api application."""

from datetime import datetime

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_check():
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data


def test_ping():
    """Test ping endpoint."""
    response = client.get("/ping")
    assert response.status_code == 200
    assert response.json() == {"message": "pong"}


def test_datetime():
    """Test datetime endpoint."""
    response = client.post("/datetime")
    assert response.status_code == 200
    data = response.json()
    assert "utc_datetime" in data
    # Verify it's a valid ISO format datetime
    datetime.fromisoformat(data["utc_datetime"])


def test_info():
    """Test info endpoint."""
    response = client.get("/info")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "demo-api"
    assert data["version"] == "0.1.0"
    assert "endpoints" in data
    assert len(data["endpoints"]) >= 4
