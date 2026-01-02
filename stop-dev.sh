#!/bin/bash

# Invoice Generator - Stop Development Services

set -e

echo "========================================"
echo "Stopping Invoice Generator Services"
echo "========================================"
echo ""

# Detect docker-compose command (v1 or v2)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "Error: Docker Compose is not installed"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo "Error: docker-compose.yml not found"
    exit 1
fi

# Stop services
echo "Stopping all services..."
$DOCKER_COMPOSE down

echo ""
echo "✓ All services stopped"
echo ""
echo "To remove all data volumes, run:"
echo "  $DOCKER_COMPOSE down -v"
echo ""
