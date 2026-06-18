# Docker Development Setup

This document explains how to run the invoice generator locally using Docker with Supabase.

## Architecture

```
┌─────────────────────────────────────────────┐
│  Frontend (React/HTML)                      │
│  http://localhost:3002                      │
│  - Invoice UI                               │
│  - Google OAuth login                       │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  Backend API (FastAPI)                      │
│  http://localhost:8002                      │
│  - REST API for invoices/clients           │
│  - CORS enabled                             │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  Supabase Local (Docker)                    │
│  - PostgreSQL: localhost:5435               │
│  - API: http://localhost:54321              │
│  - Studio: http://localhost:3003            │
└─────────────────────────────────────────────┘
```

## Prerequisites

- Docker installed
- Supabase CLI installed (`brew install supabase/tap/supabase`)
- Node.js 18+ (for Supabase CLI)

## Quick Start

### 1. Start Supabase

```bash
# Initialize (first time only)
supabase init

# Start all Supabase services
supabase start
```

This starts:
- PostgreSQL database
- PostgREST API server
- Auth server (GoTrue)
- Supabase Studio (admin UI)

### 2. Start Backend API

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Run FastAPI server
uvicorn main:app --reload --port 8002
```

### 3. Start Frontend

```bash
# Open in browser or serve with simple HTTP server
python -m http.server 3002
# Then visit: http://localhost:3002/invoice-generator.html
```

### OR: Use Docker Compose (All-in-One)

```bash
# Start everything
docker compose up

# Stop everything
docker compose down
```

## Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend | 3002 | http://localhost:3002 |
| Backend API | 8002 | http://localhost:8002/docs |
| Supabase API | 54321 | http://localhost:54321 |
| Supabase Studio | 3003 | http://localhost:3003 |
| PostgreSQL | 5435 | localhost:5435 |

## Environment Variables

Create `.env` file in project root:

```env
# Supabase
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_KEY=your_service_key_here

# Google OAuth (get from Google Cloud Console)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5435/postgres
```

## Database Migrations

```bash
# Create new migration
supabase migration new migration_name

# Apply migrations
supabase db push

# Reset database (WARNING: deletes all data)
supabase db reset
```

## Accessing Supabase Studio

Visit http://localhost:3003 to:
- View database tables
- Run SQL queries
- Manage authentication
- View API logs

## Troubleshooting

### Port conflicts

If ports are in use, edit `supabase/config.toml`:

```toml
[api]
port = 54321

[db]
port = 5435

[studio]
port = 3003
```

### Docker issues

```bash
# Check running containers
docker ps

# View logs
docker logs <container_id>

# Restart Supabase
supabase stop
supabase start
```

### Database connection issues

```bash
# Check Supabase status
supabase status

# Get connection details
supabase db url
```

## Development Workflow

1. Make code changes
2. Backend auto-reloads (FastAPI `--reload`)
3. Frontend: refresh browser
4. Database: run migrations with `supabase db push`

## Testing

```bash
# Test backend API
curl http://localhost:8002/health

# Test Supabase
curl http://localhost:54321/rest/v1/

# View API docs
# http://localhost:8002/docs
```

## Data Backup/Restore

### Export data

```bash
# Dump database
supabase db dump -f backup.sql

# Or export via Studio UI
# http://localhost:3003 > Database > Backup
```

### Import data

```bash
# Restore from dump
supabase db reset
psql postgresql://postgres:postgres@localhost:5435/postgres < backup.sql
```

## Migration from localStorage

See `docs/planning/feature-database-migration.md` for:
- Migration script
- Data mapping
- Verification steps

## Next Steps

- [ ] Test Google OAuth locally
- [ ] Import existing localStorage data
- [ ] Test all CRUD operations
- [ ] Deploy to GCP (see deployment docs)
