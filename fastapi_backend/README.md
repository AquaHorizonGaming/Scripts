# FastAPI Backend

This backend exposes a basic REST API for the grocery delivery app. It uses
FastAPI with SQLAlchemy models and JWT-based authentication.

## Endpoints
- `POST /auth/signup` – create a new account
- `POST /auth/login` – obtain a JWT token
- `GET /products/` – list available products (filter by `category_id`)
- `GET /products/categories/` – list product categories
- `GET /user/me` – current user profile
- `PUT /user/me` – update profile fields
- `GET /cart/` – view cart
- `POST /cart/add` – add product to cart
- `PUT /cart/update` – update quantity
- `DELETE /cart/remove` – remove product from cart
- `POST /orders/` – create an order from cart
- `GET /orders/` – list orders (admin sees all)
- `GET /admin/users` – list all users (admin)
- `PUT /admin/users/{id}` – update user role/info (admin)
- `DELETE /admin/users/{id}` – deactivate user (admin)
- `POST /admin/products` – add product
- `PUT /admin/products/{id}` – edit product
- `DELETE /admin/products/{id}` – delete product

The database is configured via `sqlite:///./test.db` for demo purposes. In
production, swap the connection string with your PostgreSQL database.

The API is meant to run behind Docker and exposes port **8000** by default with
CORS enabled for localhost testing.

Run the server:

```bash
uvicorn app.main:app --reload
```
