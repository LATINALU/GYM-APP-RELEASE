#!/bin/bash
##############################################################################
# Apply GYM-APP Schema to InsForge Database
# Run this after InsForge is fully started
##############################################################################

set -e

echo "Applying GYM-APP schema to database..."

# Apply our custom schema
docker exec -i gymapp-postgres-local psql -U gymapp -d gymapp < backend/deploy/docker-init/db/gym-app-schema.sql

echo "Schema applied successfully!"

# Verify tables were created
echo ""
echo "Verifying tables..."
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -c "\dt" | grep -E "(gyms|users|exercises)"

echo ""
echo "✅ GYM-APP schema ready!"
