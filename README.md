# Scripts Repository

This repository contains multiple sample apps and scripts:

- `GroceryDeliveryApp/`: SwiftUI iOS grocery app skeleton.
- `fastapi_backend/`: FastAPI backend for products, cart, orders, auth, and admin.
- `grocery_web/`: Responsive grocery website storefront integrated with root FastAPI app.

## Run storefront + API on port 9485

```bash
uvicorn app.main:app --host 127.0.0.1 --port 9485
```

Open `http://127.0.0.1:9485/`.

## Cart API

- `GET /cart`
- `POST /cart/add`
- `PUT /cart/update`
- `POST /cart/remove`
- `POST /checkout`

Use header `X-Session-Id: <your-session-id>` for cart and checkout requests.
