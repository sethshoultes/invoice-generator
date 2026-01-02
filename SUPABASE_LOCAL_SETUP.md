# Supabase Local Development Setup

## Overview

Supabase is now configured for local Docker development on the `feature/supabase-docker` branch. This provides a PostgreSQL database with a full backend API, authentication, storage, and real-time capabilities.

## Quick Start

```bash
# Start Supabase
cd "/Users/sethshoultes/Local Sites/invoice-generator"
supabase start

# Stop Supabase
supabase stop

# Reset database (applies all migrations)
supabase db reset

# Check status
supabase status
```

## Connection Details

### Development Tools

| Service | URL |
|---------|-----|
| **Supabase Studio** | http://127.0.0.1:3003 |
| **Mailpit** (Email Testing) | http://127.0.0.1:54324 |
| **MCP Server** | http://127.0.0.1:8002/mcp |

### API Endpoints

| Endpoint | URL |
|----------|-----|
| **Project URL** | http://127.0.0.1:8002 |
| **REST API** | http://127.0.0.1:8002/rest/v1 |
| **GraphQL API** | http://127.0.0.1:8002/graphql/v1 |
| **Edge Functions** | http://127.0.0.1:8002/functions/v1 |

### Database Connection

```
URL: postgresql://postgres:postgres@127.0.0.1:5435/postgres

Host: 127.0.0.1
Port: 5435
Database: postgres
Username: postgres
Password: postgres
```

### Authentication Keys

**Publishable Key (anon):**
```
sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```

**Secret Key (service_role):**
```
sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz
```

**IMPORTANT:** These are local development keys only. Never commit production keys.

### Storage (S3-compatible)

| Field | Value |
|-------|-------|
| **URL** | http://127.0.0.1:8002/storage/v1/s3 |
| **Access Key** | 625729a08b95bf1b7ff351a663f3a23c |
| **Secret Key** | 850181e4652dd023b7a98c58ae0d2d34bd487ee0cc3254aed6eda37307425907 |
| **Region** | local |

## Custom Port Configuration

The following custom ports were configured to avoid conflicts with other local services:

| Service | Default Port | Custom Port |
|---------|--------------|-------------|
| **API** | 54321 | **8002** |
| **Studio** | 54323 | **3003** |
| **PostgreSQL** | 54322 | **5435** |

Configuration file: `/Users/sethshoultes/Local Sites/invoice-generator/supabase/config.toml`

## Database Schema

The initial schema includes the following tables:

### Core Tables
- **clients** - Client contact information and billing addresses
- **invoices** - Invoice headers with totals and payment tracking
- **line_items** - Individual line items for each invoice
- **recurring_items** - Library of frequently used line items
- **source_statements** - Tracks which bank statement PDFs were uploaded
- **api_keys** - Encrypted API keys for external services (Anthropic, etc.)
- **settings** - Application settings and configuration

### Views
- **invoice_summary** - Summary view of invoices with client details
- **client_invoice_history** - Aggregate statistics for each client

### Features
- **Auto-updating totals** - Triggers automatically recalculate invoice totals when line items change
- **Timestamp tracking** - All tables have created_at/updated_at fields
- **Foreign key constraints** - Enforces data integrity
- **Row Level Security** - Enabled on all tables (currently allows all access)

## Database Migrations

All migrations are stored in: `/Users/sethshoultes/Local Sites/invoice-generator/supabase/migrations/`

Current migrations:
- `20260102000000_initial_schema.sql` - Initial database schema

### Running Migrations

```bash
# Apply all pending migrations
supabase db reset

# Create a new migration
supabase migration new <migration_name>

# View migration history
psql "postgresql://postgres:postgres@127.0.0.1:5435/postgres" -c "SELECT * FROM schema_migrations;"
```

## Using Supabase Studio

Supabase Studio provides a web interface for managing your database:

1. Open http://127.0.0.1:3003 in your browser
2. Navigate to the **Table Editor** to view/edit data
3. Use the **SQL Editor** to run queries
4. Check the **API Docs** for auto-generated REST endpoints

## Connecting from Code

### JavaScript/TypeScript (Supabase Client)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://127.0.0.1:8002'
const supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Example: Fetch all clients
const { data, error } = await supabase
  .from('clients')
  .select('*')
  .order('name')
```

### Direct PostgreSQL Connection

```bash
# psql
psql "postgresql://postgres:postgres@127.0.0.1:5435/postgres"

# Python (psycopg2)
import psycopg2
conn = psycopg2.connect(
    host="127.0.0.1",
    port=5435,
    database="postgres",
    user="postgres",
    password="postgres"
)

# Node.js (pg)
const { Pool } = require('pg')
const pool = new Pool({
  host: '127.0.0.1',
  port: 5435,
  database: 'postgres',
  user: 'postgres',
  password: 'postgres',
})
```

## REST API Examples

### Fetch all clients

```bash
curl 'http://127.0.0.1:8002/rest/v1/clients' \
  -H "apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH" \
  -H "Authorization: Bearer sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
```

### Create a new client

```bash
curl -X POST 'http://127.0.0.1:8002/rest/v1/clients' \
  -H "apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH" \
  -H "Authorization: Bearer sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "name": "John Doe",
    "company": "Acme Corp",
    "email": "john@acme.com",
    "address_line1": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102"
  }'
```

### Fetch invoice with line items

```bash
curl 'http://127.0.0.1:8002/rest/v1/invoices?select=*,line_items(*),clients(*)' \
  -H "apikey: sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH" \
  -H "Authorization: Bearer sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
```

## Email Testing

Mailpit captures all emails sent from your local Supabase instance:

- **Web UI:** http://127.0.0.1:54324
- **SMTP:** localhost:1025 (for sending from your app)

Use this to test password reset emails, confirmation emails, etc.

## Troubleshooting

### Port Conflicts

If you get "port already in use" errors:

```bash
# Check what's using a port
lsof -i :8002
lsof -i :3003
lsof -i :5435

# Stop Supabase and restart
supabase stop
supabase start
```

### Database Connection Issues

```bash
# Verify Supabase is running
supabase status

# Check Docker containers
docker ps | grep supabase

# View logs
supabase logs
```

### Reset Everything

```bash
# Stop Supabase
supabase stop

# Remove all containers and volumes
docker system prune -a --volumes

# Restart
supabase start
```

## Data Backup & Restore

### Backup Database

```bash
# Dump schema and data
pg_dump "postgresql://postgres:postgres@127.0.0.1:5435/postgres" \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# Schema only
pg_dump --schema-only "postgresql://postgres:postgres@127.0.0.1:5435/postgres" \
  > schema_backup.sql
```

### Restore Database

```bash
# Apply backup
psql "postgresql://postgres:postgres@127.0.0.1:5435/postgres" < backup.sql
```

## Next Steps

1. **Migrate localStorage data** - Create migration script to import existing client/invoice data
2. **Update frontend** - Replace localStorage calls with Supabase client
3. **Add authentication** - Configure Supabase Auth for multi-user support (optional)
4. **Deploy to cloud** - Link to Supabase cloud project when ready

## Resources

- [Supabase Local Development Docs](https://supabase.com/docs/guides/cli/local-development)
- [Supabase JavaScript Client Docs](https://supabase.com/docs/reference/javascript/introduction)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Database Migration Plan](/Users/sethshoultes/Local Sites/invoice-generator/docs/planning/feature-database-migration.md)

## Notes

- This is a **local development setup** - data is stored in Docker volumes
- Docker containers must be running for database access
- All credentials above are for local development only
- The database will persist between restarts (unless you run `supabase db reset`)
- Row Level Security is enabled but policies currently allow all access
