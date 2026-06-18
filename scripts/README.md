# Scripts

Utility scripts for the invoice generator.

## backup-localstorage.html

**Purpose:** Export all localStorage data before migration to Supabase/database.

**Usage:**

1. Open in browser:
   ```bash
   open scripts/backup-localstorage.html
   ```

2. Click "💾 Download Backup JSON"

3. Save the JSON file somewhere safe (e.g., `~/Backups/`)

**What it exports:**
- API key (obfuscated)
- All saved clients
- Invoice history
- Recurring items

**When to use:**
- Before migrating to Supabase
- Before major updates
- Regular backups (weekly/monthly)

**Output format:**
```json
{
  "exportVersion": 1,
  "exportDate": "2025-01-02T...",
  "appVersion": "1.0.0-localStorage",
  "data": {
    "apiKey": "...",
    "clients": [...],
    "invoices": [...],
    "recurringItems": [...]
  }
}
```

## Future Scripts

- `migrate-to-supabase.py` - Migrate localStorage JSON to Supabase
- `seed-database.sql` - Seed test data for development
