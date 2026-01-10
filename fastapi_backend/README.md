# FastAPI Backend

This backend exposes a basic REST API for the grocery delivery app. It uses
FastAPI with SQLAlchemy models and JWT-based authentication.

## Endpoints
- `POST /auth/signup` – create a new account
- `POST /auth/login` – obtain a JWT token
- `GET /products/` – list available products
- `POST /orders/` – create an order (authenticated)
- `GET /orders/` – list orders for the current user

The database is configured via `sqlite:///./test.db` for demo purposes. In
production, swap the connection string with your PostgreSQL database.

Run the server:

```bash
uvicorn app.main:app --reload
```
