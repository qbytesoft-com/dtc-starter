#!/bin/sh
set -e

echo "=========================================="
echo "Starting Medusa v2 Backend Container"
echo "DATABASE_URL: ${DATABASE_URL:-NOT_SET}"
echo "REDIS_URL: ${REDIS_URL:-NOT_SET}"
echo "=========================================="

echo "--> Executing Medusa Database Migrations..."
./node_modules/.bin/medusa db:migrate

echo "--> Database Migrations Completed Successfully!"

echo "--> Starting Medusa Server..."
exec ./node_modules/.bin/medusa start
