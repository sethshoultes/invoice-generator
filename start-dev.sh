#!/bin/bash

# Invoice Generator - Development Startup Script
# This script starts all services for local development

set -e

echo "========================================"
echo "Invoice Generator - Development Setup"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect docker-compose command (v1 or v2)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    echo "Please install Docker Compose and try again."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found.${NC}"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓ Created .env file${NC}"
    echo ""
    echo -e "${YELLOW}Please review .env and update if needed, then run this script again.${NC}"
    exit 0
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo -e "${GREEN}✓ .env file exists${NC}"
echo ""

# Stop any existing containers
echo "Stopping existing containers..."
$DOCKER_COMPOSE down

# Build and start services
echo ""
echo "Building and starting services..."
echo "This may take a few minutes on first run..."
echo ""

$DOCKER_COMPOSE up -d --build

echo ""
echo "Waiting for services to be ready..."
echo ""

# Wait for database to be ready
echo -n "Waiting for PostgreSQL..."
until $DOCKER_COMPOSE exec -T db pg_isready -U postgres > /dev/null 2>&1; do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}✓${NC}"

# Wait for backend to be ready
echo -n "Waiting for Backend API..."
for i in {1..30}; do
    if curl -s http://localhost:8002/health > /dev/null 2>&1; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
    if [ $i -eq 30 ]; then
        echo -e " ${YELLOW}⚠ Backend may not be ready${NC}"
    fi
done

echo ""
echo "========================================"
echo -e "${GREEN}✓ All services are running!${NC}"
echo "========================================"
echo ""
echo "Services available at:"
echo ""
echo "  📱 Frontend:        http://localhost:3002"
echo "  🔧 Backend API:     http://localhost:8002"
echo "  🗄️  Database UI:     http://localhost:3003"
echo "  🔑 Supabase API:    http://localhost:54321"
echo "  📊 PostgreSQL:      localhost:5435"
echo ""
echo "To view logs:"
echo "  $DOCKER_COMPOSE logs -f [service]"
echo ""
echo "To stop all services:"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "To stop and remove all data:"
echo "  $DOCKER_COMPOSE down -v"
echo ""
echo "========================================"
