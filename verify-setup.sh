#!/bin/bash

# Docker Setup Verification Script
# Checks that all required files are in place before starting

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================"
echo "Docker Setup Verification"
echo "========================================"
echo ""

ERRORS=0
WARNINGS=0

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        ERRORS=$((ERRORS + 1))
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
    else
        echo -e "${RED}✗${NC} $1/ - MISSING"
        ERRORS=$((ERRORS + 1))
    fi
}

# Check root files
echo "Checking root files..."
check_file "docker-compose.yml"
check_file ".env.example"
check_file "start-dev.sh"
check_file "stop-dev.sh"
check_file "Makefile"
check_file ".dockerignore"
check_file ".gitignore"
echo ""

# Check backend files
echo "Checking backend files..."
check_dir "backend"
check_file "backend/Dockerfile"
check_file "backend/.dockerignore"
check_file "backend/main.py"
check_file "backend/requirements.txt"
check_file "backend/.env.example"
check_file "backend/README.md"
echo ""

# Check frontend files
echo "Checking frontend files..."
check_dir "frontend"
check_file "frontend/Dockerfile"
check_file "frontend/.dockerignore"
check_file "frontend/nginx.conf"
check_file "frontend/index.html"
echo ""

# Check supabase files
echo "Checking supabase files..."
check_dir "supabase"
check_file "supabase/init.sql"
check_file "supabase/kong.yml"
echo ""

# Check if .env exists
echo "Checking environment configuration..."
if [ -f .env ]; then
    echo -e "${GREEN}✓${NC} .env file exists"
else
    echo -e "${YELLOW}⚠${NC} .env file not found (will be created on first run)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check if Docker is installed
echo "Checking Docker installation..."
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed ($(docker --version))"
else
    echo -e "${RED}✗${NC} Docker is not installed"
    ERRORS=$((ERRORS + 1))
fi

if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose is installed ($(docker-compose --version))"
elif docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose is installed ($(docker compose version))"
else
    echo -e "${RED}✗${NC} Docker Compose is not installed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check if Docker is running
echo "Checking Docker daemon..."
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker daemon is running"
else
    echo -e "${RED}✗${NC} Docker daemon is not running"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo "========================================"
echo "Verification Summary"
echo "========================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You're ready to start the development environment:"
    echo "  ./start-dev.sh"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warning(s)${NC}"
    echo ""
    echo "Setup is OK, but review warnings above."
    echo "You can still start with:"
    echo "  ./start-dev.sh"
    echo ""
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} error(s), ${WARNINGS} warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before starting."
    exit 1
fi
