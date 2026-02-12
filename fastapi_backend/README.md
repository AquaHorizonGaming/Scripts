# FastAPI Backend

Production-leaning REST API for the grocery delivery app using FastAPI + SQLAlchemy + JWT.

## Improvements included
- Environment-driven configuration (`DATABASE_URL`, `SECRET_KEY`, CORS, token lifetime).
- Health endpoint (`GET /health`) for liveness checks.
- JWT bearer parsing hardening and inactive-user blocking.
- Safer auth flow with duplicate email prevention and typed login response.
- Input validation with stricter schema fields (password length, positive prices/quantities).
- Basic product pagination (`skip` + `limit`).
- Better admin controls (role update + active flag support).

## Environment variables
- `APP_NAME` (default: `Grocery Delivery API`)
- `ENVIRONMENT` (default: `development`)
- `DATABASE_URL` (default: `sqlite:///./test.db`)
- `SECRET_KEY` (required in production)
- `JWT_ALGORITHM` (default: `HS256`)
- `ACCESS_TOKEN_EXPIRE_MINUTES` (default: `30`)
- `CORS_ORIGINS` (comma-separated)

## Quick start
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Endpoint highlights
- `GET /health` – health check
- `POST /auth/signup` – create account
- `POST /auth/login` – obtain JWT token
- `GET /products/` – list products (`category_id`, `skip`, `limit`)
- `GET /products/categories/` – list categories
- `GET /user/me` – current user profile
- `PUT /user/me` – update profile fields
- `GET /cart/` – view cart
- `POST /cart/add` – add product to cart
- `PUT /cart/update` – update quantity
- `DELETE /cart/remove` – remove product from cart
- `POST /orders/` – create order from cart
- `GET /orders/` – list orders (admins see all)
- `GET /admin/users` – list all users (admin)
- `PUT /admin/users/{id}` – update user role/status/info (admin)
- `DELETE /admin/users/{id}` – deactivate user (admin)
- `POST /admin/products` – add product (admin)
- `PUT /admin/products/{id}` – edit product (admin)
- `DELETE /admin/products/{id}` – delete product (admin)
