# Supabase Quick Reference

## Start/Stop Commands

```bash
# Start Supabase
supabase start

# Stop Supabase
supabase stop

# Check status
supabase status

# Reset database (reapply migrations)
supabase db reset
```

## Important URLs

- **Supabase Studio:** http://127.0.0.1:3003
- **REST API:** http://127.0.0.1:8002/rest/v1
- **Database:** postgresql://postgres:postgres@127.0.0.1:5435/postgres

## API Key (for local dev)

```
sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```

## Database Tables

Created by migration `20260102000000_initial_schema.sql`:

- **clients** - Client information
- **invoices** - Invoice headers
- **line_items** - Invoice line items
- **recurring_items** - Recurring item library
- **source_statements** - Uploaded PDF tracking
- **api_keys** - Encrypted API keys
- **settings** - App settings

## Test Connection

```bash
# List tables
psql "postgresql://postgres:postgres@127.0.0.1:5435/postgres" -c "\dt"

# Query test data
psql "postgresql://postgres:postgres@127.0.0.1:5435/postgres" -c "SELECT * FROM invoice_summary;"
```

## Full Documentation

See: [SUPABASE_LOCAL_SETUP.md](./SUPABASE_LOCAL_SETUP.md)
