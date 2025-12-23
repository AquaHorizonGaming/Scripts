from fastapi import FastAPI
from .db import Base, engine
from .api.endpoints import auth, products, orders

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Grocery Delivery API")

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
