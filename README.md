# Scripts Repository

This repository contains multiple sample apps and scripts:

- `GroceryDeliveryApp/`: SwiftUI iOS grocery app skeleton.
- `fastapi_backend/`: FastAPI backend for products, cart, orders, auth, and admin.
- `grocery_web/`: Responsive grocery website storefront (HTML/CSS/JS) with cart drawer and optional API integration.

## Run the integrated grocery website (FastAPI + storefront)

```bash
cd fastapi_backend
uvicorn app.main:app --host 127.0.0.1 --port 9485
```

Then open `http://127.0.0.1:9485/`.

The storefront loads from the FastAPI app and fetches products from the same origin endpoint (`/products/?limit=30`), falling back to built-in sample products when the API has no data or is unavailable.
