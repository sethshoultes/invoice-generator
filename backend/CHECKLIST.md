# Backend Setup Checklist

Use this checklist to verify your backend is properly set up and running.

## Prerequisites

- [ ] Python 3.11+ installed
- [ ] pip installed
- [ ] Supabase account created (or local Supabase running)
- [ ] Database schema created in Supabase

## Installation

- [ ] Created virtual environment (`python -m venv venv`)
- [ ] Activated virtual environment
- [ ] Installed dependencies (`pip install -r requirements.txt`)
- [ ] Created `.env` file from `.env.example`
- [ ] Added Supabase URL to `.env`
- [ ] Added Supabase anon key to `.env`

## Database Setup

- [ ] Logged into Supabase dashboard
- [ ] Created `clients` table
- [ ] Created `invoices` table
- [ ] Created `line_items` table
- [ ] Created `recurring_items` table
- [ ] Set up foreign key constraints
- [ ] Created indexes
- [ ] Tested database connection

## Server Startup

- [ ] Server starts without errors
- [ ] Server runs on port 8002
- [ ] No import errors
- [ ] No database connection errors

## API Testing

### Health Check
- [ ] `GET /health` returns 200
- [ ] Response includes status: "healthy"

### Clients
- [ ] `GET /api/clients` returns empty array or client list
- [ ] `POST /api/clients` creates a client
- [ ] `GET /api/clients/{id}` returns the created client
- [ ] `PUT /api/clients/{id}` updates the client
- [ ] `DELETE /api/clients/{id}` deletes the client

### Invoices
- [ ] `GET /api/invoices` returns empty array or invoice list
- [ ] `POST /api/invoices` creates an invoice with line items
- [ ] `GET /api/invoices/{id}` returns invoice with line items
- [ ] `GET /api/invoices?status=unpaid` filters by status
- [ ] `PUT /api/invoices/{id}` updates payment status
- [ ] `POST /api/invoices/{id}/line-items` adds a line item
- [ ] Invoice totals are calculated correctly
- [ ] `DELETE /api/invoices/{id}/line-items/{lid}` deletes line item
- [ ] `DELETE /api/invoices/{id}` deletes the invoice

### Recurring Items
- [ ] `GET /api/recurring-items` returns empty array or items
- [ ] `POST /api/recurring-items` creates an item
- [ ] `GET /api/recurring-items/{id}` returns the item
- [ ] `PUT /api/recurring-items/{id}` updates the item
- [ ] `POST /api/recurring-items/{id}/use` increments usage
- [ ] `DELETE /api/recurring-items/{id}` deletes the item

### Documentation
- [ ] Swagger UI accessible at `/docs`
- [ ] ReDoc accessible at `/redoc`
- [ ] All endpoints visible in docs
- [ ] Can test endpoints from Swagger UI

### CORS
- [ ] Frontend can connect from port 3002
- [ ] No CORS errors in browser console

## Common Issues

### Database Connection Failed

**Symptom:** Error: "Missing Supabase credentials"

**Solution:**
1. Check `.env` file exists
2. Verify `SUPABASE_URL` is set
3. Verify `SUPABASE_KEY` is set
4. Restart the server

### Import Errors

**Symptom:** ModuleNotFoundError

**Solution:**
1. Activate virtual environment
2. Reinstall dependencies: `pip install -r requirements.txt`
3. Verify Python version: `python --version` (should be 3.11+)

### Port Already in Use

**Symptom:** Address already in use

**Solution:**
1. Find process: `lsof -ti:8002`
2. Kill process: `lsof -ti:8002 | xargs kill`
3. Or use different port: `uvicorn main:app --port 8003`

### CORS Errors

**Symptom:** Blocked by CORS policy

**Solution:**
1. Add your frontend URL to `origins` in `main.py`
2. Restart the server

### Database Schema Missing

**Symptom:** Table does not exist errors

**Solution:**
1. Go to Supabase Dashboard
2. Open SQL Editor
3. Run schema from `/docs/planning/feature-database-migration.md`

## Quick Test Commands

### Test Health
```bash
curl http://localhost:8002/health
```

### Create Test Client
```bash
curl -X POST http://localhost:8002/api/clients \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Client", "company": "Test Inc"}'
```

### List Clients
```bash
curl http://localhost:8002/api/clients
```

### Create Test Invoice
```bash
curl -X POST http://localhost:8002/api/invoices \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_number": "TEST-001",
    "client_id": 1,
    "submitted_date": "2026-01-02",
    "payment_status": "unpaid",
    "line_items": [{
      "item_date": "2026-01-02",
      "description": "Test Item",
      "qty": 1,
      "unit_price": 100,
      "total_price": 100,
      "line_order": 0
    }]
  }'
```

## Success Criteria

When all items are checked:
- ✅ Backend is fully set up
- ✅ All endpoints are working
- ✅ Database is connected
- ✅ API documentation is accessible
- ✅ Ready for frontend integration

## Next Steps

1. Test all endpoints with Swagger UI
2. Create sample data (clients, invoices)
3. Update frontend to use API
4. Test frontend integration
5. Deploy to production (optional)
