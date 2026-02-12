from fastapi import FastAPI
from .db import Base, engine
from .api.endpoints import auth, products, orders, users, cart, admin

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Grocery Delivery API")

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
app.include_router(users.router)
app.include_router(cart.router)
app.include_router(admin.router)
