# Invoice Generator Backend

FastAPI backend for the Invoice Generator application with Supabase PostgreSQL integration.

## Features

- **RESTful API** with FastAPI
- **PostgreSQL Database** via Supabase
- **CRUD Operations** for clients, invoices, and recurring items
- **CORS Enabled** for browser access
- **Auto-generated API Docs** with Swagger UI
- **Pydantic Validation** for request/response schemas

## Tech Stack

- **FastAPI** - Modern Python web framework
- **Supabase** - PostgreSQL database and authentication
- **Pydantic** - Data validation
- **Uvicorn** - ASGI server

## Prerequisites

- Python 3.11+
- Supabase account (or local Supabase via Docker)
- pip or poetry for package management

## Installation

### 1. Clone and Navigate

```bash
cd backend
```

### 2. Create Virtual Environment

```bash
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

Copy the example environment file and update with your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
```

To get your Supabase credentials:
1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Go to Settings > API
4. Copy the Project URL and anon/public key

### 5. Set Up Database Schema

The database schema should be created in Supabase. See `/docs/planning/feature-database-migration.md` for the full SQL schema.

Required tables:
- `clients`
- `invoices`
- `line_items`
- `recurring_items`

You can run the schema in the Supabase SQL Editor.

## Running the Server

### Development Mode (with auto-reload)

```bash
uvicorn main:app --reload --port 8002
```

Or using the built-in runner:

```bash
python main.py
```

The API will be available at:
- **API**: http://localhost:8002
- **API Docs (Swagger)**: http://localhost:8002/docs
- **Alternative Docs (ReDoc)**: http://localhost:8002/redoc
- **Health Check**: http://localhost:8002/health

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8002
```

## API Endpoints

### Root & Health

- `GET /` - API information
- `GET /health` - Health check

### Clients

- `GET /api/clients` - List all clients
- `GET /api/clients/{id}` - Get client by ID
- `POST /api/clients` - Create new client
- `PUT /api/clients/{id}` - Update client
- `DELETE /api/clients/{id}` - Delete client

### Invoices

- `GET /api/invoices` - List all invoices
  - Query param: `?status=unpaid|paid|partial` - Filter by payment status
- `GET /api/invoices/{id}` - Get invoice with line items
- `POST /api/invoices` - Create invoice with line items
- `PUT /api/invoices/{id}` - Update invoice
- `DELETE /api/invoices/{id}` - Delete invoice
- `POST /api/invoices/{id}/line-items` - Add line item to invoice
- `DELETE /api/invoices/{id}/line-items/{line_item_id}` - Delete line item

### Recurring Items

- `GET /api/recurring-items` - List all recurring items
- `GET /api/recurring-items/{id}` - Get recurring item by ID
- `POST /api/recurring-items` - Create recurring item
- `PUT /api/recurring-items/{id}` - Update recurring item
- `DELETE /api/recurring-items/{id}` - Delete recurring item
- `POST /api/recurring-items/{id}/use` - Increment usage counter

## API Examples

### Create a Client

```bash
curl -X POST http://localhost:8002/api/clients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "company": "Acme Corp",
    "email": "john@acme.com",
    "phone": "555-1234",
    "address_line1": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94105"
  }'
```

### Create an Invoice

```bash
curl -X POST http://localhost:8002/api/invoices \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_number": "01022026-1",
    "client_id": 1,
    "invoice_for": "January Consulting Services",
    "submitted_date": "2026-01-02",
    "due_date": "2026-01-16",
    "payment_status": "unpaid",
    "line_items": [
      {
        "item_date": "2026-01-02",
        "description": "Consulting Services",
        "qty": 10,
        "unit_price": 150.00,
        "total_price": 1500.00,
        "line_order": 0
      }
    ]
  }'
```

### List Unpaid Invoices

```bash
curl http://localhost:8002/api/invoices?status=unpaid
```

### Get Invoice with Line Items

```bash
curl http://localhost:8002/api/invoices/1
```

## Project Structure

```
backend/
├── main.py                 # FastAPI app entry point
├── database.py             # Supabase client connection
├── schemas.py              # Pydantic models for validation
├── requirements.txt        # Python dependencies
├── .env.example            # Environment variables template
├── .env                    # Your local config (git-ignored)
└── routes/
    ├── __init__.py         # Routes package init
    ├── clients.py          # Client endpoints
    ├── invoices.py         # Invoice endpoints
    └── recurring_items.py  # Recurring items endpoints
```

## Development

### API Documentation

Once the server is running, visit:
- http://localhost:8002/docs - Interactive Swagger UI
- http://localhost:8002/redoc - Alternative documentation

You can test all endpoints directly from the Swagger UI.

### Adding New Endpoints

1. Create a new router in `routes/` directory
2. Import and include it in `main.py`:
   ```python
   from routes import new_router
   app.include_router(new_router.router)
   ```

### Database Changes

When modifying the database schema:
1. Update the Supabase schema via SQL Editor
2. Update the Pydantic models in `schemas.py`
3. Update the route handlers in `routes/`

## CORS Configuration

The API allows requests from:
- `http://localhost:3002` - Frontend dev server
- `http://127.0.0.1:3002` - Alternative localhost
- `http://localhost:8080` - Alternative port
- `http://127.0.0.1:8080` - Alternative localhost

To add more origins, edit the `origins` list in `main.py`.

## Error Handling

The API returns standard HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `404` - Not Found
- `409` - Conflict (duplicate)
- `500` - Internal Server Error

Error responses follow this format:
```json
{
  "detail": "Error message here"
}
```

## Database Schema

See `/docs/planning/feature-database-migration.md` for the complete PostgreSQL schema including:
- Tables (clients, invoices, line_items, recurring_items)
- Indexes
- Triggers for auto-updating totals
- Views for common queries

## Deployment

### Using Docker

```bash
docker build -t invoice-backend .
docker run -p 8002:8002 --env-file .env invoice-backend
```

### Manual Deployment

1. Set up a Python environment on your server
2. Install dependencies: `pip install -r requirements.txt`
3. Set environment variables
4. Run with production server: `uvicorn main:app --host 0.0.0.0 --port 8002`

Popular hosting options:
- **Render.com** - Free tier available
- **Railway.app** - Easy deployment
- **Fly.io** - Global edge deployment
- **AWS/GCP/Azure** - Traditional cloud platforms

## Troubleshooting

### Database Connection Failed

```
Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_KEY in .env file
```

**Solution**: Create a `.env` file with your Supabase credentials (see step 4 above).

### CORS Errors in Browser

```
Access to fetch at 'http://localhost:8002/api/clients' from origin 'http://localhost:3000' has been blocked by CORS policy
```

**Solution**: Add your frontend URL to the `origins` list in `main.py`.

### Import Errors

```
ModuleNotFoundError: No module named 'fastapi'
```

**Solution**: Make sure you've activated your virtual environment and installed dependencies:
```bash
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### Port Already in Use

```
ERROR:    [Errno 48] Address already in use
```

**Solution**: Either:
1. Stop the process using port 8002: `lsof -ti:8002 | xargs kill`
2. Or use a different port: `uvicorn main:app --port 8003`

## Testing

### Manual Testing with curl

Test the health endpoint:
```bash
curl http://localhost:8002/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-02T10:00:00",
  "version": "1.0.0"
}
```

### Using the API Docs

1. Start the server
2. Visit http://localhost:8002/docs
3. Click "Try it out" on any endpoint
4. Fill in the request body
5. Click "Execute"

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_KEY` | Supabase anon key | `eyJ...` |
| `API_PORT` | Port to run the API on | `8002` |
| `ENVIRONMENT` | Environment name | `development` |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:3002` |

## Contributing

When adding new features:
1. Update the Pydantic schemas in `schemas.py`
2. Create/update route handlers in `routes/`
3. Update this README with new endpoints
4. Test thoroughly with the Swagger UI

## License

This project is part of the Invoice Generator application.

## Support

For issues or questions:
1. Check the Swagger API docs: http://localhost:8002/docs
2. Review the planning docs: `/docs/planning/`
3. Check Supabase status: https://status.supabase.com/
