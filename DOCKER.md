# Docker Development Environment

Complete Docker setup for running the Invoice Generator locally with all services.

## Quick Start

### 1. Prerequisites

- Docker Desktop installed and running
- At least 4GB of available RAM
- Ports available: 3002, 3003, 5435, 8002, 54321, 54322

### 2. One-Command Startup

```bash
./start-dev.sh
```

This script will:
- Check if Docker is running
- Create `.env` from `.env.example` if needed
- Build all Docker images
- Start all services
- Wait for services to be ready
- Display access URLs

### 3. Access Your Application

Once started, access:

- **Frontend**: http://localhost:3002
- **Backend API**: http://localhost:8002
- **API Docs**: http://localhost:8002/docs
- **Supabase Studio**: http://localhost:3003
- **Supabase API**: http://localhost:54321

### 4. Stop Services

```bash
./stop-dev.sh
```

Or manually:

```bash
docker-compose down
```

---

## Architecture Overview

### Services Running

The Docker Compose setup includes:

1. **PostgreSQL Database** (port 5435)
   - Supabase-enhanced PostgreSQL 15
   - Persistent data in `db-data` volume
   - Auto-initialized with schema from `supabase/init.sql`

2. **Supabase Studio** (port 3003)
   - Database management UI
   - Visual query builder
   - Schema designer

3. **Kong API Gateway** (port 54321)
   - Routes all Supabase API requests
   - Handles authentication
   - CORS configuration

4. **Supabase Auth** (GoTrue)
   - User authentication service
   - JWT token management
   - Email verification

5. **Supabase REST API** (PostgREST)
   - Auto-generated REST API from PostgreSQL schema
   - Real-time data access

6. **Supabase Realtime**
   - WebSocket connections
   - Live database changes
   - Presence features

7. **Supabase Storage**
   - File uploads and storage
   - Persistent in `storage-data` volume

8. **Supabase Meta**
   - Database introspection
   - Schema management

9. **FastAPI Backend** (port 8002)
   - Custom API endpoints
   - Business logic layer
   - Connects to Supabase

10. **Nginx Frontend** (port 3002)
    - Serves static HTML/JS
    - Proxies `/api` to backend
    - Production-ready configuration

---

## Port Reference

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3002 | Main application UI |
| Backend API | 8002 | FastAPI server |
| Supabase Studio | 3003 | Database management UI |
| PostgreSQL | 5435 | Direct database access |
| Supabase API | 54321 | Kong API gateway |
| Supabase Admin | 54322 | Kong admin API |

---

## Environment Variables

### Required Variables (in `.env`)

```bash
# JWT Secret - MUST be at least 32 characters
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long

# Supabase Keys (demo keys work for local dev)
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Database Password
POSTGRES_PASSWORD=postgres
```

### Generate JWT Secret

```bash
# macOS/Linux
openssl rand -base64 32

# Or use any string with 32+ characters
```

---

## Common Commands

### Start Services

```bash
# Start all services
docker-compose up -d

# Start with rebuild
docker-compose up -d --build

# Start and view logs
docker-compose up
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
```

### Stop Services

```bash
# Stop all services (keep data)
docker-compose down

# Stop and remove volumes (delete all data)
docker-compose down -v
```

### Restart a Service

```bash
docker-compose restart backend
docker-compose restart frontend
```

### Access Container Shell

```bash
# Backend container
docker-compose exec backend /bin/bash

# Database container
docker-compose exec db psql -U postgres

# Frontend container
docker-compose exec frontend /bin/sh
```

### Database Operations

```bash
# Connect to PostgreSQL
docker-compose exec db psql -U postgres

# Run SQL file
docker-compose exec -T db psql -U postgres < schema.sql

# Backup database
docker-compose exec db pg_dump -U postgres > backup.sql

# Restore database
docker-compose exec -T db psql -U postgres < backup.sql
```

---

## Development Workflow

### 1. Making Backend Changes

The backend has **hot reload** enabled, so changes to Python files are automatically detected:

1. Edit files in `backend/`
2. Save the file
3. Backend automatically reloads
4. Check logs: `docker-compose logs -f backend`

### 2. Making Frontend Changes

For frontend development, you have two options:

**Option A: Rebuild the container** (slower)
```bash
docker-compose up -d --build frontend
```

**Option B: Mount the file directly** (faster, for development)

Edit `docker-compose.yml` and add volume mount:
```yaml
frontend:
  volumes:
    - ./invoice-generator.html:/usr/share/nginx/html/index.html:ro
```

Then restart:
```bash
docker-compose restart frontend
```

### 3. Database Schema Changes

1. Edit `supabase/init.sql`
2. Recreate database:
```bash
docker-compose down -v  # WARNING: Deletes all data
docker-compose up -d
```

For production migrations, use proper migration tools.

---

## Troubleshooting

### Services Won't Start

**Check Docker is running:**
```bash
docker info
```

**Check ports are available:**
```bash
# macOS/Linux
lsof -i :3002
lsof -i :8002
lsof -i :5435

# Kill process on port
kill -9 <PID>
```

**View service status:**
```bash
docker-compose ps
```

### Database Connection Issues

**Check database is ready:**
```bash
docker-compose exec db pg_isready -U postgres
```

**View database logs:**
```bash
docker-compose logs -f db
```

**Connect directly:**
```bash
docker-compose exec db psql -U postgres
```

### Backend API Not Responding

**Check backend logs:**
```bash
docker-compose logs -f backend
```

**Check environment variables:**
```bash
docker-compose exec backend env | grep SUPABASE
```

**Restart backend:**
```bash
docker-compose restart backend
```

### Frontend 502 Bad Gateway

This means Nginx can't reach the backend.

**Check backend is running:**
```bash
docker-compose ps backend
curl http://localhost:8002/health
```

**Check network connectivity:**
```bash
docker-compose exec frontend ping backend
```

### Clean Slate Reset

If everything is broken, start fresh:

```bash
# Stop and remove everything
docker-compose down -v

# Remove all images
docker-compose down --rmi all

# Start fresh
./start-dev.sh
```

---

## Performance Optimization

### Reduce Resource Usage

If Docker is using too much RAM:

1. Edit `docker-compose.yml` and add resource limits:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
```

2. Disable unused Supabase services:

Comment out in `docker-compose.yml`:
- `storage` (if not using file uploads)
- `realtime` (if not using real-time features)

### Speed Up Builds

Use BuildKit for faster builds:

```bash
DOCKER_BUILDKIT=1 docker-compose build
```

Add to `~/.docker/config.json`:
```json
{
  "features": {
    "buildkit": true
  }
}
```

---

## Production Deployment

**WARNING:** This Docker setup is for **local development only**.

For production:

1. **Use managed Supabase** (https://supabase.com)
   - Free tier available
   - Automated backups
   - Global CDN

2. **Deploy backend separately**
   - Railway.app
   - Render.com
   - Fly.io

3. **Serve frontend from CDN**
   - Netlify
   - Vercel
   - Cloudflare Pages

4. **Security checklist:**
   - Change all default passwords
   - Generate new JWT secrets
   - Enable HTTPS/TLS
   - Configure proper CORS
   - Set up authentication
   - Enable Row Level Security (RLS)

---

## File Structure

```
.
├── docker-compose.yml          # Main orchestration file
├── .env                        # Environment variables (create from .env.example)
├── .env.example                # Template for environment variables
├── start-dev.sh                # Quick start script
├── stop-dev.sh                 # Stop services script
├── backend/
│   ├── Dockerfile              # Backend container definition
│   ├── .dockerignore           # Files to exclude from build
│   ├── main.py                 # FastAPI application
│   ├── requirements.txt        # Python dependencies
│   └── .env.example            # Backend environment template
├── frontend/
│   ├── Dockerfile              # Frontend container definition
│   ├── .dockerignore           # Files to exclude from build
│   ├── nginx.conf              # Nginx configuration
│   └── index.html              # Main application file
└── supabase/
    ├── init.sql                # Database initialization script
    └── kong.yml                # API Gateway configuration
```

---

## Volumes

Persistent data is stored in Docker volumes:

- `db-data`: PostgreSQL database files
- `storage-data`: Uploaded files

**View volumes:**
```bash
docker volume ls | grep invoice
```

**Inspect volume:**
```bash
docker volume inspect invoice-generator_db-data
```

**Backup volumes:**
```bash
docker run --rm -v invoice-generator_db-data:/data -v $(pwd):/backup ubuntu tar czf /backup/db-backup.tar.gz /data
```

**Restore volumes:**
```bash
docker run --rm -v invoice-generator_db-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/db-backup.tar.gz -C /
```

---

## Networks

All services communicate on the `invoice-network` bridge network.

**View network:**
```bash
docker network inspect invoice-generator_invoice-network
```

**Test connectivity:**
```bash
# From frontend to backend
docker-compose exec frontend wget -O- http://backend:8002/health

# From backend to database
docker-compose exec backend nc -zv db 5432
```

---

## Updating Dependencies

### Backend (Python)

1. Edit `backend/requirements.txt`
2. Rebuild:
```bash
docker-compose up -d --build backend
```

### Frontend (Nginx)

Frontend has no dependencies (static files only).

Just restart after changes:
```bash
docker-compose restart frontend
```

---

## Health Checks

All services have health checks configured.

**View health status:**
```bash
docker-compose ps
```

**Manual health checks:**
```bash
# Backend API
curl http://localhost:8002/health

# Database
docker-compose exec db pg_isready -U postgres

# Frontend
curl -I http://localhost:3002
```

---

## Next Steps

1. **Explore Supabase Studio**: http://localhost:3003
   - View database schema
   - Run SQL queries
   - Manage data

2. **Test API Endpoints**: http://localhost:8002/docs
   - Interactive API documentation
   - Test requests directly

3. **Build Your App**: http://localhost:3002
   - Start coding!

---

## Support

If you encounter issues:

1. Check this documentation
2. View service logs: `docker-compose logs -f [service]`
3. Restart services: `docker-compose restart`
4. Clean slate: `docker-compose down -v && ./start-dev.sh`

---

## License

Same as main project.
