#!/bin/bash
##############################################################################
# Complete GYM-APP Setup Script
# Run after InsForge is fully installed and migrated
##############################################################################

set -e

echo "=== GYM-APP Complete Setup ==="

# 1. Apply our custom schema
echo "1. Applying GYM-APP schema..."
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -f /docker-entrypoint-initdb.d/03-gym-app-schema.sql

# 2. Create current_user_id() function
echo "2. Creating current_user_id() function..."
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -c "CREATE OR REPLACE FUNCTION current_user_id() RETURNS UUID AS \$\$ SELECT id FROM users WHERE email = current_user; \$\$ LANGUAGE sql SECURITY DEFINER;"

# 3. Fix policies
echo "3. Fixing RLS policies..."
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -f /tmp/fix-policies.sql

# 4. Create default admin user
echo "4. Creating default admin user..."
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -c "INSERT INTO users (email, password_hash, first_name, last_name, role) VALUES ('superadmin@gym-app.com', '\$2b\$10\$placeholder_hash', 'Super', 'Admin', 'admin') ON CONFLICT (email) DO NOTHING;"

# 5. Verify setup
echo "5. Verifying setup..."
echo ""
echo "Tables created:"
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -c "\dt" | grep -E "(gyms|users|exercises)" | head -5

echo ""
echo "Admin user:"
docker exec gymapp-postgres-local psql -U gymapp -d gymapp -c "SELECT id, email, role FROM users WHERE email = 'superadmin@gym-app.com';"

echo ""
echo "=== Setup Complete! ==="
echo "API URLs:"
echo "  InsForge: http://localhost:7130"
echo "  PostgREST: http://localhost:5430"
echo ""
echo "Test login:"
echo "  curl -X POST http://localhost:7130/api/auth/sessions?client_type=mobile -H 'Content-Type: application/json' -d '{\"email\":\"superadmin@gym-app.com\",\"password\":\"super123\"}'"
