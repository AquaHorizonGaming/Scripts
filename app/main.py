from fastapi import FastAPI
from . import auth, products, orders, admin

app = FastAPI(title='Grocery Delivery API')

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
app.include_router(admin.router)
