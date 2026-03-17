#!/bin/bash
##############################################################################
# GYM-APP VPS Deployment Script
# VPS: 147.93.191.92 | Ubuntu 24.04
# Path: /root/projects/gym-app/
#
# This script:
#   1. Creates required VPS directories
#   2. Creates .env from template if missing
#   3. Starts all Docker services
#   4. Configures Nginx reverse proxy
#   5. Verifies all services are running
#
# Usage (on VPS):
#   cd /root/projects/gym-app
#   chmod +x deploy.sh
#   ./deploy.sh
##############################################################################

set -e

VPS_IP="147.93.191.92"
PROJECT_DIR="/root/projects/gym-app"
DB_DIR="/root/databases/postgres/gym-app"
LOG_DIR="/root/logs/gym-app"
BACKUP_DIR="/root/backups/gym-app"
NGINX_DIR="/root/nginx"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  GYM-APP Backend Deployment"
echo "  VPS: $VPS_IP"
echo "═══════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────
# 1. Pre-flight checks
# ─────────────────────────────────────────────────────────
echo ""
echo "[1/6] Pre-flight checks..."

if ! command -v docker &> /dev/null; then
    echo "  ERROR: Docker is not installed"
    exit 1
fi
echo "  ✓ Docker installed"

if ! command -v docker compose &> /dev/null; then
    echo "  ERROR: Docker Compose is not installed"
    exit 1
fi
echo "  ✓ Docker Compose installed"

# ─────────────────────────────────────────────────────────
# 2. Create VPS directories
# ─────────────────────────────────────────────────────────
echo ""
echo "[2/6] Creating directories..."

mkdir -p "$DB_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$PROJECT_DIR/storage"
mkdir -p "$NGINX_DIR/conf.d"

echo "  ✓ $DB_DIR"
echo "  ✓ $LOG_DIR"
echo "  ✓ $BACKUP_DIR"
echo "  ✓ $PROJECT_DIR/storage"

# ─────────────────────────────────────────────────────────
# 3. Create .env if missing
# ─────────────────────────────────────────────────────────
echo ""
echo "[3/6] Checking environment..."

if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/backend/.env.gym-app.example" ]; then
        cp "$PROJECT_DIR/backend/.env.gym-app.example" "$PROJECT_DIR/.env"
        echo "  ⚠ Created .env from template"
        echo ""
        echo "  ╔══════════════════════════════════════════════════╗"
        echo "  ║  IMPORTANT: Edit .env before continuing!        ║"
        echo "  ║                                                  ║"
        echo "  ║  nano $PROJECT_DIR/.env                         ║"
        echo "  ║                                                  ║"
        echo "  ║  Change at minimum:                              ║"
        echo "  ║  - POSTGRES_PASSWORD (strong password)           ║"
        echo "  ║  - JWT_SECRET (min 32 random chars)              ║"
        echo "  ║  - ENCRYPTION_KEY (min 32 random chars)          ║"
        echo "  ║  - ADMIN_PASSWORD (for superadmin)               ║"
        echo "  ╚══════════════════════════════════════════════════╝"
        echo ""
        read -p "  Press Enter after editing .env..."
    else
        echo "  ERROR: No .env template found"
        echo "  Expected: $PROJECT_DIR/backend/.env.gym-app.example"
        exit 1
    fi
else
    echo "  ✓ .env exists"
fi

# Source .env for variable access
set -a
source "$PROJECT_DIR/.env" 2>/dev/null || true
set +a

# ─────────────────────────────────────────────────────────
# 4. Stop existing and start services
# ─────────────────────────────────────────────────────────
echo ""
echo "[4/6] Starting Docker services..."

cd "$PROJECT_DIR"
docker compose -f docker-compose.gym-app.yml down 2>/dev/null || true
docker compose -f docker-compose.gym-app.yml up -d

echo "  ✓ Docker Compose started"

# ─────────────────────────────────────────────────────────
# 5. Wait for services to be healthy
# ─────────────────────────────────────────────────────────
echo ""
echo "[5/6] Waiting for services..."

for i in {1..60}; do
    if docker exec gymapp-postgres pg_isready -U ${POSTGRES_USER:-gymapp} &>/dev/null; then
        echo "  ✓ PostgreSQL ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "  ✗ PostgreSQL timeout after 60s"
        echo "  Check logs: docker logs gymapp-postgres"
        exit 1
    fi
    sleep 1
done

# Wait a bit more for InsForge to install deps and start
echo "  ⏳ Waiting for InsForge to initialize (npm install + migrate)..."
sleep 30

# ─────────────────────────────────────────────────────────
# 6. Verify all services
# ─────────────────────────────────────────────────────────
echo ""
echo "[6/6] Verifying services..."
echo ""

services=("gymapp-postgres" "gymapp-postgrest" "gymapp-insforge" "gymapp-deno" "gymapp-vector")
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

# ─────────────────────────────────────────────────────────
# 7. Setup Nginx reverse proxy config
# ─────────────────────────────────────────────────────────
echo ""
echo "  Setting up Nginx config..."

cat > "$NGINX_DIR/conf.d/gym-app.conf" << 'NGINX_EOF'
# GYM-APP Nginx Reverse Proxy
# InsForge API → port 7130
# PostgREST    → port 5430

# InsForge API (Auth, Storage, Functions)
server {
    listen 8030;
    server_name _;

    # Max upload size for images
    client_max_body_size 50M;

    # InsForge API
    location / {
        proxy_pass http://127.0.0.1:7130;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
    }
}

# PostgREST API (Database REST)
server {
    listen 8031;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5430;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

echo "  ✓ Nginx config written to $NGINX_DIR/conf.d/gym-app.conf"

# Reload nginx if running
if command -v nginx &> /dev/null && systemctl is-active --quiet nginx; then
    nginx -t && systemctl reload nginx
    echo "  ✓ Nginx reloaded"
fi

# ─────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
if [ "$all_ok" = true ]; then
    echo "  ✅ GYM-APP Backend Deployed Successfully!"
else
    echo "  ⚠️  Some services may need attention"
fi
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  📡 Service URLs:"
echo "  ├─ InsForge API:   http://$VPS_IP:7130"
echo "  ├─ InsForge Proxy: http://$VPS_IP:8030"
echo "  ├─ PostgREST API:  http://$VPS_IP:5430"
echo "  ├─ PostgREST Proxy:http://$VPS_IP:8031"
echo "  └─ PostgreSQL:     $VPS_IP:5432"
echo ""
echo "  👤 Default Admin:  superadmin@gym-app.com"
echo ""
echo "  📂 Data Locations:"
echo "  ├─ Database:  $DB_DIR"
echo "  ├─ Storage:   $PROJECT_DIR/storage"
echo "  ├─ Logs:      $LOG_DIR"
echo "  └─ Backups:   $BACKUP_DIR"
echo ""
echo "  🔧 Commands:"
echo "  ├─ Logs:    docker compose -f docker-compose.gym-app.yml logs -f"
echo "  ├─ Stop:    docker compose -f docker-compose.gym-app.yml down"
echo "  ├─ Restart: docker compose -f docker-compose.gym-app.yml restart"
echo "  └─ Status:  docker ps --filter name=gymapp"
echo ""
echo "  💾 Backup Database:"
echo "  docker exec gymapp-postgres pg_dump -U gymapp gymapp > $BACKUP_DIR/gymapp_\$(date +%Y%m%d).sql"
echo "═══════════════════════════════════════════════════════"
