#!/bin/bash
##############################################################################
# GYM-APP Local Development Deployment Script
# For testing on Windows with Docker Desktop
#
# Usage:
#   ./deploy-local.sh
##############################################################################

set -e

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  GYM-APP Local Development Deployment"
echo "  Docker Desktop on Windows"
echo "═══════════════════════════════════════════════════════"

# Check Docker Desktop
if ! command -v docker &> /dev/null; then
    echo "  ERROR: Docker is not installed or not running"
    echo "  Please start Docker Desktop"
    exit 1
fi
echo "  ✓ Docker running"

if ! command -v docker compose &> /dev/null; then
    echo "  ERROR: Docker Compose is not installed"
    exit 1
fi
echo "  ✓ Docker Compose available"

# Create local directories
echo ""
echo "Creating local directories..."
mkdir -p storage
mkdir -p logs
echo "  ✓ ./storage"
echo "  ✓ ./logs"

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo ""
    echo "  ERROR: .env.local not found!"
    echo "  Please create .env.local from the template"
    exit 1
fi
echo "  ✓ .env.local found"

# Stop existing containers
echo ""
echo "Stopping existing containers..."
docker compose -f docker-compose.local.yml down 2>/dev/null || true

# Start services
echo ""
echo "Starting services..."
docker compose -f docker-compose.local.yml --env-file .env.local up -d

echo ""
echo "Waiting for PostgreSQL to be ready..."
for i in {1..60}; do
    if docker exec gymapp-postgres-local pg_isready -U gymapp &>/dev/null; then
        echo "  ✓ PostgreSQL ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "  ✗ PostgreSQL timeout after 60s"
        echo "  Check logs: docker logs gymapp-postgres-local"
        exit 1
    fi
    sleep 1
done

# Wait for InsForge to initialize
echo "  ⏳ Waiting for InsForge to initialize (npm install + migrate)..."
sleep 30

# Verify services
echo ""
echo "Verifying services..."
echo ""

services=("gymapp-postgres-local" "gymapp-postgrest-local" "gymapp-insforge-local" "gymapp-deno-local")
all_ok=true
for svc in "${services[@]}"; do
    status=$(docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "not found")
    if [ "$status" = "running" ]; then
        echo "  ✓ $svc: RUNNING"
    else
        echo "  ✗ $svc: $status"
        all_ok=false
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
if [ "$all_ok" = true ]; then
    echo "  ✅ GYM-APP Local Backend Running!"
else
    echo "  ⚠️  Some services may need attention"
fi
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  📡 Local Service URLs:"
echo "  ├─ InsForge API:   http://localhost:7130"
echo "  ├─ PostgREST API:  http://localhost:5430"
echo "  ├─ Deno Runtime:  http://localhost:7133"
echo "  └─ PostgreSQL:     localhost:5432"
echo ""
echo "  👤 Default Admin:  superadmin@gym-app.com"
echo "  🔑 Admin Password: super123"
echo ""
echo "  🧪 Test API:"
echo "  curl http://localhost:7130/api/auth/public-config"
echo ""
echo "  🔧 Commands:"
echo "  ├─ Logs:    docker compose -f docker-compose.local.yml logs -f"
echo "  ├─ Stop:    docker compose -f docker-compose.local.yml down"
echo "  ├─ Restart: docker compose -f docker-compose.local.yml restart"
echo "  └─ Status:  docker ps --filter name=gymapp"
echo ""
echo "  📂 Local Data:"
echo "  ├─ Storage: ./storage/"
echo "  └─ Logs:    ./logs/"
echo "═══════════════════════════════════════════════════════"
