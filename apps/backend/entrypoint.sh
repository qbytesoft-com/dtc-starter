#!/bin/bash
set -e

echo "=========================================="
echo "Starting Medusa v2 Backend Container"
echo "DATABASE_URL: ${DATABASE_URL:-NOT_SET}"
echo "REDIS_URL: ${REDIS_URL:-NOT_SET}"
echo "=========================================="

echo "--> Step 1: Running Database Migrations..."
./node_modules/.bin/medusa db:migrate
echo "--> Step 1 Complete: Migrations finished successfully!"

echo "--> Step 2: Starting Medusa Server on port ${PORT:-9000}..."
exec ./node_modules/.bin/medusa start
