# Docker Quick Start Guide

Get the Invoice Generator running in 3 steps.

## Prerequisites

- Docker Desktop installed and running
- Ports 3002, 3003, 5435, 8002, 54321 available

## Step 1: Start Everything

```bash
./start-dev.sh
```

That's it! The script will:
- Create `.env` if needed
- Build all images
- Start all services
- Wait for everything to be ready

## Step 2: Access the App

Open your browser to:

- **Main App**: http://localhost:3002
- **API Docs**: http://localhost:8002/docs
- **Database UI**: http://localhost:3003

## Step 3: Stop When Done

```bash
./stop-dev.sh
```

---

## Using Makefile Commands

If you prefer `make` commands:

```bash
make start       # Start all services
make stop        # Stop all services
make logs        # View all logs
make restart     # Restart services
make health      # Check service health
make help        # See all commands
```

---

## Troubleshooting

### Services won't start?

```bash
# Check Docker is running
docker info

# Clean slate restart
make clean
make start
```

### Need to see what's happening?

```bash
# View logs
make logs

# Or specific service
make logs-backend
make logs-frontend
```

### Port already in use?

```bash
# Find what's using the port (macOS/Linux)
lsof -i :3002

# Kill the process
kill -9 <PID>
```

---

## Next Steps

1. Read [DOCKER.md](DOCKER.md) for detailed documentation
2. Check [backend/README.md](backend/README.md) for API details
3. Visit http://localhost:3002 and start building!

---

## Common Commands

```bash
# Start services
./start-dev.sh

# View logs
docker-compose logs -f

# Restart backend only
docker-compose restart backend

# Connect to database
docker-compose exec db psql -U postgres

# Stop everything
./stop-dev.sh

# Delete all data and reset
docker-compose down -v
```

---

**Need help?** See [DOCKER.md](DOCKER.md) for comprehensive documentation.
