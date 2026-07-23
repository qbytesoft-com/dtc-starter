#!/bin/sh
set -e

echo "=========================================="
echo "Starting Medusa v2 Backend Container"
echo "DATABASE_URL: ${DATABASE_URL:-NOT_SET}"
echo "=========================================="

echo "--> Executing Medusa Database Migrations..."
npx medusa db:migrate

echo "--> Starting Medusa Server..."
exec npx medusa start
