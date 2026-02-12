from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

from . import admin, auth, models, orders, products
from .cart import router as cart_router
from .checkout import router as checkout_router
from .database import Base, SessionLocal, engine

app = FastAPI(title='Grocery Delivery API')

Base.metadata.create_all(bind=engine)


def seed_products():
    db: Session = SessionLocal()
    try:
        if db.query(models.Product).count() == 0:
            db.add_all(
                [
                    models.Product(name='Bananas', price_customer=1.99, image_url='', store_id=1),
                    models.Product(name='Avocados', price_customer=3.49, image_url='', store_id=1),
                    models.Product(name='Sourdough Bread', price_customer=4.20, image_url='', store_id=1),
                    models.Product(name='Croissants', price_customer=5.50, image_url='', store_id=1),
                    models.Product(name='Whole Milk', price_customer=3.15, image_url='', store_id=1),
                    models.Product(name='Greek Yogurt', price_customer=4.45, image_url='', store_id=1),
                ]
            )
            db.commit()
    finally:
        db.close()


seed_products()

repo_root = Path(__file__).resolve().parents[1]
web_root = repo_root / 'grocery_web'

if web_root.exists():
    app.mount('/static', StaticFiles(directory=web_root), name='store-static')


@app.get('/')
def storefront_home():
    index_path = web_root / 'index.html'
    if index_path.exists():
        return FileResponse(index_path)
    return {'detail': 'Storefront not found'}


@app.get('/app.js')
def storefront_js():
    return FileResponse(web_root / 'app.js')


@app.get('/styles.css')
def storefront_css():
    return FileResponse(web_root / 'styles.css')


app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
app.include_router(admin.router)
app.include_router(cart_router)
app.include_router(checkout_router)
