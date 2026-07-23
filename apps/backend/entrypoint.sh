#!/bin/sh
set -e

echo "=========================================="
echo "Starting Medusa v2 Backend Container"
echo "=========================================="

echo "--> Starting Medusa Server..."
exec ./node_modules/.bin/medusa start
